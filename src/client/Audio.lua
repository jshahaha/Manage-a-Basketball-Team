--!nonstrict
-- Client audio player. Plays sounds from Shared/Sounds.lua by name, with volume
-- groups, random variants and pitch, cooldowns, and a commentator queue that never
-- talks over itself.
--
--   local Audio = require(script.Parent.Audio)
--   Audio.play("Swish")
--   Audio.play("Dunk", courtPart)          -- 3D, from a part on the court
--   Audio.say("Three")                     -- commentator; returns the subtitle text
--   Audio.setGroupVolume("Music", 0.5)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Sounds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Sounds"))

local Audio = {}

local groups = {}
for _, name in ipairs(Sounds.Groups) do
	local g = Instance.new("SoundGroup")
	g.Name = name
	g.Volume = 1
	g.Parent = SoundService
	groups[name] = g
end

local lastPlayed = {}
local loops = {}

local function make(name: string, parent: Instance?)
	local s = Sounds.List[name]
	if not s then
		warn("[Audio] unknown sound " .. name)
		return nil
	end
	local id = Sounds.pickId(name, math.random())
	if not id then
		return nil -- not filled in yet
	end
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. id
	sound.Volume = s.volume
	sound.Looped = s.looped
	sound.PlaybackSpeed = 1 + (math.random() * 2 - 1) * s.pitchJitter
	sound.SoundGroup = groups[s.group]
	sound.Parent = parent or SoundService
	return sound, s
end

-- One-shot sound. parent: a BasePart/Attachment for 3D sound, or nil for UI sound.
function Audio.play(name: string, parent: Instance?)
	local now = os.clock()
	local s = Sounds.List[name]
	if s and lastPlayed[name] and now - lastPlayed[name] < s.cooldown then
		return
	end
	lastPlayed[name] = now
	local sound = make(name, parent)
	if not sound then
		return
	end
	if sound.Looped then
		Audio.startLoop(name, parent)
		sound:Destroy()
		return
	end
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
end

function Audio.startLoop(name: string, parent: Instance?)
	if loops[name] then
		return loops[name]
	end
	local sound = make(name, parent)
	if sound then
		sound.Looped = true
		sound:Play()
		loops[name] = sound
	end
	return sound
end

function Audio.stopLoop(name: string)
	local sound = loops[name]
	if sound then
		sound:Stop()
		sound:Destroy()
		loops[name] = nil
	end
end

function Audio.setLoopVolume(name: string, volume: number)
	if loops[name] then
		loops[name].Volume = volume
	end
end

function Audio.setGroupVolume(group: string, volume: number)
	if groups[group] then
		groups[group].Volume = math.clamp(volume, 0, 1)
	end
end

-- Commentator ---------------------------------------------------------------
local speaking = nil -- { priority, sound }
local queue = {} -- { event, at, priority }
local MAX_AGE = 2 -- seconds; stale lines are dropped

local function playLine(event: string)
	local entry = Sounds.Lines[event]
	local line = entry.lines[math.random(1, #entry.lines)]
	if line.id == 0 then
		return line.text -- not recorded yet: subtitle only
	end
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. line.id
	sound.SoundGroup = groups.Commentator
	sound.Volume = 1
	sound.Parent = SoundService
	speaking = { priority = entry.priority, sound = sound }
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
		speaking = nil
		-- play the next fresh line
		while #queue > 0 do
			local nextLine = table.remove(queue, 1)
			if os.clock() - nextLine.at <= MAX_AGE then
				playLine(nextLine.event)
				break
			end
		end
	end)
	return line.text
end

-- Say a commentator line for an event. Returns the subtitle text (or nil if queued/dropped).
function Audio.say(event: string): string?
	local entry = Sounds.Lines[event]
	if not entry then
		warn("[Audio] unknown commentator event " .. event)
		return nil
	end
	if speaking then
		if entry.priority > speaking.priority then
			speaking.sound:Stop() -- big moment cuts in
			speaking.sound:Destroy()
			speaking = nil
		else
			table.insert(queue, { event = event, at = os.clock(), priority = entry.priority })
			table.sort(queue, function(a, b)
				return a.priority > b.priority
			end)
			return nil
		end
	end
	return playLine(event)
end

return Audio
