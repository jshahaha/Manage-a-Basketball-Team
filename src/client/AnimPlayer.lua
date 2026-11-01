--!nonstrict
-- Plays AnimClips keyframes on an R15 character by writing Motor6D.Transform every frame.
-- Used for the pack walkout and the in-game signature moves. Because sounds are fired from
-- the clip's own events on the same clock, a dribble sound always lands on the bounce.
--
-- local player = AnimPlayer.new(characterModel, { onEvent = function(name) Audio.play(name) end })
-- player:play("Dunk"):await()  -- yields until the clip ends (or use player.Finished)

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimClips = require(ReplicatedStorage.Shared.AnimClips)

local MOTORS = { "Root", "Waist", "Neck", "RightShoulder", "RightElbow", "LeftShoulder", "LeftElbow", "RightHip", "RightKnee", "LeftHip", "LeftKnee" }
local rad = math.rad

local AnimPlayer = {}
AnimPlayer.__index = AnimPlayer

function AnimPlayer.new(character: Model, opts)
	local self = setmetatable({}, AnimPlayer)
	self.character = character
	self.motors = {}
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("Motor6D") and table.find(MOTORS, d.Name) then
			self.motors[d.Name] = d
		end
	end
	self.onEvent = opts and opts.onEvent or function() end
	self.Finished = Instance.new("BindableEvent")
	return self
end

-- Stop default animations so they don't fight the clip.
local function pauseAnimator(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			track:Stop(0.1)
		end
	end
end

function AnimPlayer:apply(clip, t: number)
	for name, motor in pairs(self.motors) do
		local keys = clip.joints[name]
		if keys then
			local v = AnimClips.sample(keys, t, 3)
			motor.Transform = CFrame.fromEulerAnglesYXZ(rad(v[1]), rad(v[2]), rad(v[3]))
		elseif name ~= "Root" then
			motor.Transform = CFrame.identity
		end
	end
	local root = self.motors.Root
	if root then
		if clip.root then
			local r = AnimClips.sample(clip.root, t, 5)
			root.Transform = CFrame.new(r[1], r[2], r[3]) * CFrame.fromEulerAnglesYXZ(rad(r[5]), rad(r[4]), 0)
		else
			root.Transform = CFrame.identity
		end
	end
end

function AnimPlayer:play(name: string, speed: number?)
	local clip = AnimClips.Clips[name]
	assert(clip, "no clip " .. tostring(name))
	self:stop()
	pauseAnimator(self.character)
	local t, last = 0, -1
	speed = speed or 1
	self.conn = RunService.Stepped:Connect(function(_, dt)
		t += dt * speed
		local tt = t
		if clip.loop then
			tt = t % clip.length
			if tt < last then
				last = -1 -- wrapped: fire events from the top again
			end
		else
			tt = math.min(t, clip.length)
		end
		for _, ev in ipairs(AnimClips.eventsBetween(clip, last, tt)) do
			self.onEvent(ev)
		end
		last = tt
		self:apply(clip, tt)
		if not clip.loop and t >= clip.length and not clip.hold then
			self:stop()
			self.Finished:Fire(name)
		elseif clip.hold and t >= clip.length and not self.held then
			self.held = true
			self.Finished:Fire(name)
		end
	end)
	return {
		await = function()
			self.Finished.Event:Wait()
		end,
	}
end

function AnimPlayer:stop()
	if self.conn then
		self.conn:Disconnect()
		self.conn = nil
	end
	self.held = false
end

function AnimPlayer:reset()
	self:stop()
	for _, motor in pairs(self.motors) do
		motor.Transform = CFrame.identity
	end
end

return AnimPlayer
