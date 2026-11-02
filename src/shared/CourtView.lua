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
		self.S[i] = opts.S and opts.S[i] or PoseSolver.setup(body) -- reuse solver state when given
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

-- A missed jumper: aimed at the front of the rim, then it kicks out and bounces away.
local function rimKey(clip)
	for _, k in ipairs(clip.ball or {}) do
		if k[2] == "rim" then
			return k[1]
		end
	end
	return nil
end

function CourtView:missBall(plan, S, clip, ct, place, rim)
	local back = Vector3.new(place.Position.X - rim.X, 0, place.Position.Z - rim.Z)
	back = back.Magnitude > 0.01 and back.Unit or Vector3.xAxis
	local front = rim + back * 0.55 -- front of the rim
	local tr = rimKey(clip)
	if not tr or ct <= tr then
		return PoseSolver.ball(S, clip, ct, place, front)
	end
	return front + Vector3.yAxis * 0.6 -- after the rim the plan's rebound takes over
end

-- A block: where the dunker has the ball when the swat lands, and how far the blocker has to
-- shift and rise so their hand gets there.
function CourtView:blockFit(plan, homeHasBall)
	local fit = self.dunks[plan.block]
	if fit then
		return fit
	end
	local blk = plan.block
	local rim = self.rims[plan.dir]
	-- The dunker at the moment of the block, with the dunk fit applied.
	local dp = Possession.frame(plan, blk.tBlock).players[plan.shooter]
	local dS = self.S[bodyFor(plan.shooter, homeHasBall)]
	local dclip = AnimClips.Clips[dp.clip]
	local dfit = self:dunkFit(plan, dS, dclip, rim)
	local ct = dp.t
	local up = ct < dfit.hoopAt and smooth((ct - 0.55) / (dfit.hoopAt - 0.55)) or 1 - smooth((ct - dfit.hoopAt - 0.3) / 0.4)
	local dplace = PoseSolver.place(dS, dclip, self.center.X + dp.x, self.center.Z + dp.z, self.floorY, dp.face)
		+ dfit.shift * smooth(ct / 0.6) + Vector3.yAxis * (dfit.lift * up)
	local ballAt = PoseSolver.ball(dS, dclip, ct, dplace, rim) or rim
	-- The blocker's hand at the hit.
	local bp = Possession.frame(plan, blk.tBlock).players[blk.who]
	local bS = self.S[bodyFor(blk.who, homeHasBall)]
	local bclip = AnimClips.Clips.Block
	local bplace = PoseSolver.place(bS, bclip, self.center.X + bp.x, self.center.Z + bp.z, self.floorY, bp.face)
	local cf = PoseSolver.solve(bS, bclip, bp.t, bplace)
	local hand = cf[bS.rh].Position + Vector3.yAxis * (PoseSolver.BallRadius + 0.02)
	fit = {
		ball = ballAt,
		shift = Vector3.new(ballAt.X - hand.X, 0, ballAt.Z - hand.Z),
		lift = math.max(0, ballAt.Y - hand.Y),
		land = Vector3.new(self.center.X + blk.land.x, self.floorY + PoseSolver.BallRadius, self.center.Z + blk.land.z),
	}
	self.dunks[plan.block] = fit
	return fit
end

-- Where the rebounder's hands are at the top of their jump, so the ball lands right in them.
function CourtView:reboundHands(plan, homeHasBall)
	local fit = self.dunks[plan.rebound]
	if fit then
		return fit
	end
	local reb = plan.rebound
	local p = Possession.frame(plan, reb.tCatch).players[reb.who]
	local S = self.S[bodyFor(reb.who, homeHasBall)]
	local clip = AnimClips.Clips.Rebound
	local place = PoseSolver.place(S, clip, self.center.X + p.x, self.center.Z + p.z, self.floorY, p.face)
	fit = PoseSolver.ball(S, clip, p.t, place)
	self.dunks[plan.rebound] = fit
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
		if plan.block and i == plan.block.who and p.clip == "Block" then
			local fit = self:blockFit(plan, homeHasBall)
			local up = ct < 0.76 and smooth((ct - 0.4) / 0.36) or 1 - smooth((ct - 1.0) / 0.25)
			place = place + fit.shift * smooth(ct / 0.5) + Vector3.yAxis * (fit.lift * up)
		end
		PoseSolver.pose(S, p.clip, ct, place)
		if f.ball.owner == i then
			local miss = i == plan.shooter and p.clip == plan.shotClip and plan.result.made == false and not clip.hoopAt
			ballPos = miss and self:missBall(plan, S, clip, p.t, place, rim) or PoseSolver.ball(S, clip, ct, place, rim)
			if not ballPos and not clip.ball then
				ballPos = S.rh.Position + Vector3.yAxis * 0.7 -- clips without a ball track: carry it
			end
		end
	end
	if f.ball.free and f.ball.swat then
		local fit = self:blockFit(plan, homeHasBall)
		local u = f.ball.swat
		ballPos = fit.ball:Lerp(fit.land, u) + Vector3.yAxis * (3 * 4 * u * (1 - u))
	elseif f.ball.free and f.ball.rebound then
		local reb = plan.rebound
		local a = Vector3.new(self.center.X + reb.front.x, rim.Y + 0.6, self.center.Z + reb.front.z)
		local b = self:reboundHands(plan, homeHasBall)
		local u = f.ball.rebound
		ballPos = a:Lerp(b, u) + Vector3.yAxis * (1.6 * 4 * u * (1 - u))
	elseif f.ball.free then
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
	local blocked = false
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
				local missed = plan.result.made == false and owner.clip == plan.shotClip
				for _, ev in ipairs(AnimClips.eventsBetween(clip, lastT, ct)) do
					if missed and ev == "Swish" then
						ev = "RimOut"
					elseif missed and ev:find("^CrowdCheer") then
						ev = "CrowdOoh"
					end
					onEvent(ev)
				end
				lastClip, lastT = owner.clip, ct
			end
			if plan.block and not blocked and t >= plan.block.tBlock then
				blocked = true
				onEvent("Block")
				onEvent("CrowdOoh")
			end
		end
		t += RunService.RenderStepped:Wait()
	end
end

return CourtView
