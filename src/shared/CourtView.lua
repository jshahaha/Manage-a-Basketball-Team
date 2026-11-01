--!nonstrict
-- Plays a Possession plan on the 3D court: poses the 10 player bodies and moves the ball.
-- Everything is computed from (plan, t), so the match view can scrub, skip or replay, and the
-- same code renders edit-mode Studio previews.
--
--   local view = CourtView.new({ court = courtModel, bodies = { home1..5, away1..5 }, ball = ballPart })
--   view:render(plan, t, true)          -- one frame; true = home team has the ball
--   view:play(plan, true, onEvent)      -- real time; yields until the possession ends
--
-- Dunks are lined up at render time: the dunker's hand meets the real rim and their jump is
-- raised to rim height, whatever the player's size.

local Shared = script and script.Parent
local function import(name)
	return require(Shared and Shared:FindFirstChild(name) or "./" .. name)
end
local AnimClips = import("AnimClips")
local Court = import("Court")
local Possession = import("Possession")
local PoseSolver = import("PoseSolver")

local CourtView = {}
CourtView.__index = CourtView

local function smooth(u)
	u = math.clamp(u, 0, 1)
	return u * u * (3 - 2 * u)
end

function CourtView.new(opts)
	local self = setmetatable({}, CourtView)
	self.court = opts.court
	self.ball = opts.ball
	self.bodies = opts.bodies
	local floor = self.court:FindFirstChild("Floor")
	self.floorY = floor.Position.Y + floor.Size.Y / 2
	self.center = floor.Position
	self.rims = { [1] = Court.rimPosition(self.court, 1), [-1] = Court.rimPosition(self.court, -1) }
	self.S = {}
	for i, body in ipairs(self.bodies) do
		self.S[i] = PoseSolver.setup(body)
	end
	self.dunks = setmetatable({}, { __mode = "k" })
	return self
end

-- Body index (1-10) for plan slot i (offense 1-5, defense 6-10).
local function bodyFor(i, homeHasBall)
	if homeHasBall then
		return i
	end
	return i <= 5 and i + 5 or i - 5
end

-- Dunk alignment for this plan: horizontal shift so the hand meets the rim at the clip's hoopAt
-- moment, and how much higher the jump has to go.
function CourtView:dunkFit(plan, S, clip, rim)
	local fit = self.dunks[plan]
	if fit then
		return fit
	end
	local h = clip.hoopAt[1]
	local at = Possession.frame(plan, plan.tShot + h).players[plan.shooter]
	local place = PoseSolver.place(S, clip, self.center.X + at.x, self.center.Z + at.z, self.floorY, at.face)
	local cf = PoseSolver.solve(S, clip, h, place)
	local hand = cf[clip.hoopAt[2] == "L" and S.lh or S.rh].Position
	fit = {
		shift = Vector3.new(rim.X - hand.X, 0, rim.Z - hand.Z),
		lift = math.max(0, rim.Y + 0.35 - hand.Y),
		hoopAt = h,
	}
	self.dunks[plan] = fit
	return fit
end

-- Pose everyone and place the ball for time t. Returns the ball position (or nil).
function CourtView:render(plan, t: number, homeHasBall: boolean)
	local f = Possession.frame(plan, t)
	local rim = self.rims[plan.dir]
	local ballPos
	for i = 1, 10 do
		local p = f.players[i]
		local S = self.S[bodyFor(i, homeHasBall)]
		local clip = AnimClips.Clips[p.clip]
		local ct = math.min(p.t, clip.length)
		local place = PoseSolver.place(S, clip, self.center.X + p.x, self.center.Z + p.z, self.floorY, p.face)
		if i == plan.shooter and p.clip == plan.shotClip and clip.hoopAt then
			local fit = self:dunkFit(plan, S, clip, rim)
			-- Ease the shift in over the run-up; raise the jump into the rim and back down to land.
			local up = ct < fit.hoopAt and smooth((ct - 0.55) / (fit.hoopAt - 0.55)) or 1 - smooth((ct - fit.hoopAt - 0.3) / 0.4)
			place = place + fit.shift * smooth(ct / 0.6) + Vector3.yAxis * (fit.lift * up)
		end
		PoseSolver.pose(S, p.clip, ct, place)
		if f.ball.owner == i then
			ballPos = PoseSolver.ball(S, clip, ct, place, rim)
			if not ballPos and not clip.ball then
				ballPos = S.rh.Position + Vector3.yAxis * 0.7 -- clips without a ball track: carry it
			end
		end
	end
	if f.ball.free then
		ballPos = Vector3.new(self.center.X + f.ball.x, self.floorY + f.ball.y, self.center.Z + f.ball.z)
	end
	if self.ball then
		self.ball.Transparency = ballPos and 0 or 1
		if ballPos then
			self.ball.Position = ballPos
		end
	end
	return ballPos, f
end

-- Play in real time. onEvent(soundName) gets the ball handler's clip events (bounces, swish...).
function CourtView:play(plan, homeHasBall: boolean, onEvent)
	local RunService = game:GetService("RunService")
	local t, lastClip, lastT = 0, nil, -1
	while t <= plan.length do
		self:render(plan, t, homeHasBall)
		if onEvent then
			local f = Possession.frame(plan, t)
			local owner = f.ball.owner and f.players[f.ball.owner]
			if owner then
				local clip = AnimClips.Clips[owner.clip]
				local ct = math.min(owner.t, clip.length)
				if owner.clip ~= lastClip or ct < lastT then
					lastT = -1
				end
				for _, ev in ipairs(AnimClips.eventsBetween(clip, lastT, ct)) do
					onEvent(ev)
				end
				lastClip, lastT = owner.clip, ct
			end
		end
		t += RunService.RenderStepped:Wait()
	end
end

return CourtView
