--!nonstrict
-- Turns one simulated possession into a timeline the court view can play:
-- where each of the 10 players stands, which way they face, which clip they play and how far
-- into it, and where the ball is. Pure math on plain {x, z} tables, so it runs in tests and
-- on the client the same way.
--
--   local plan = Possession.plan({
--     offense = { anims1, ..., anims5 },   -- each player's AnimSets.clips(...) result
--     dir = 1,                              -- attacking +X (1) or -X (-1)
--     result = { kind = "jumper" | "three" | "dunk", shooter = 2, assist = 1, made = true },
--   })
--   local f = Possession.frame(plan, t)     -- f.players[i] = { x, z, face, clip, t }, f.ball = {...}
--
-- Positions are in court studs (1 ft = 0.9), rim at x = dir * 37.575.

local AnimClips = require(script and script.Parent:FindFirstChild("AnimClips") or "./AnimClips")

local Possession = {}

local FT = 0.9
local RIM_X = 47 * FT - 5.25 * FT

-- Half-court spots (feet from the rim along the floor, z across): PG top, wings, corner, post.
local SPOTS = {
	{ 25, 0 }, -- 1 top of the key
	{ 19, -16 }, -- 2 left wing (from the camera's side)
	{ 15, 19 }, -- 3 right wing
	{ 8, -9 }, -- 4 left block
	{ 5, 7 }, -- 5 right block
}
local SHOT_SPOT = { jumper = 15, three = 24.5, dunk = 5 }
-- Dunks: the shooter catches at their spot, drives for DRIVE seconds, then the dunk clip's own
-- root motion carries them the last RUNUP studs to the rim (the clips start 2.6 behind their origin).
local DRIVE, RUNUP = 0.9, 2.6

local function lerp(a, b, u)
	return a + (b - a) * u
end
local function clamp01(u)
	return math.max(0, math.min(1, u))
end
local function smooth(u)
	u = clamp01(u)
	return u * u * (3 - 2 * u)
end

-- Court position of a spot: feet from the rim -> studs, for attacking direction dir.
local function spot(dir, s)
	return { x = dir * (RIM_X - s[1] * FT), z = s[2] * FT }
end

-- Build the plan. Times in seconds.
function Possession.plan(opts)
	local dir = opts.dir or 1
	local r = opts.result
	local offense = opts.offense
	local plan = { dir = dir, result = r, segments = {}, ball = {} }
	local handler = 1
	local shooter = r.shooter or 1
	local passer = r.assist
	-- Beats: bring it up (0-2.2), signature move (2.2-3.2), optional pass (0.5 s), then the shot.
	local tMove = 2.2
	local moveLen = 1.0
	local tPass = tMove + moveLen
	if passer and passer ~= shooter then
		handler = passer
	else
		handler = shooter -- unassisted: the shooter brings it up and creates their own shot
	end
	local moveClip = offense[handler].moves[1] or "Crossover"
	local tShot = tPass + ((passer and passer ~= shooter) and 0.6 or 0)
	local shotClip = r.kind == "dunk" and offense[shooter].dunk or offense[shooter].shot
	local tCatch = tShot
	if r.kind == "dunk" then
		tShot = tShot + DRIVE
	end
	plan.shotClip, plan.moveClip, plan.tMove, plan.tPass, plan.tShot, plan.tCatch = shotClip, moveClip, tMove, tPass, tShot, tCatch
	plan.length = tShot + 2.6
	-- Where everyone ends up: the shooter at their shot spot, the rest at their spots.
	local finals = {}
	for i = 1, 5 do
		finals[i] = spot(dir, SPOTS[i])
	end
	local shotFeet = SHOT_SPOT[r.kind] or 15
	-- Same angle from the rim as their spot, at the shot's distance.
	local s = SPOTS[shooter]
	local k = shotFeet / math.sqrt(s[1] ^ 2 + s[2] ^ 2)
	finals[shooter] = { x = dir * (RIM_X - s[1] * k * FT), z = s[2] * k * FT }
	plan.finals = finals
	if r.kind == "dunk" then
		-- Drive from the spot to where the dunk clip picks up, on the line to the rim.
		local d = shotFeet * FT + RUNUP
		local len = math.sqrt(s[1] ^ 2 + s[2] ^ 2)
		plan.driveFrom = spot(dir, s)
		plan.driveTo = { x = dir * (RIM_X - s[1] / len * d), z = s[2] / len * d }
		finals[shooter] = plan.driveFrom -- catch at their own spot, then attack
	end
	plan.handler, plan.shooter, plan.passer = handler, shooter, (passer and passer ~= shooter) and passer or nil
	if r.made == false and r.kind ~= "dunk" then
		Possession.addRebound(plan, r.rebounder or (shooter == 5 and 9 or 10))
	end
	return plan
end

-- When the shot clip's ball reaches the rim.
local function rimTime(clipName)
	local clip = AnimClips.Clips[clipName]
	for _, k in ipairs(clip and clip.ball or {}) do
		if k[2] == "rim" then
			return k[1]
		end
	end
	return 1.75
end

-- A miss: the ball comes off the front of the rim and slot `who` (1-5 offense, 6-10 defense)
-- goes up and grabs it at the top of their jump, then chins it.
local REB_LEAD = 0.75 -- the Rebound clip's hands meet the ball this far in
function Possession.addRebound(plan, who: number)
	local dir = plan.dir
	local rim = { x = dir * RIM_X, z = 0 }
	local sp = plan.finals[plan.shooter]
	local bx, bz = sp.x - rim.x, sp.z - rim.z
	local len = math.sqrt(bx * bx + bz * bz)
	bx, bz = bx / len, bz / len
	local side = (plan.shooter % 2 == 0) and 1 or -1
	local sx, sz = -bz * side, bx * side
	local reb = {
		who = who,
		tRim = plan.tShot + rimTime(plan.shotClip),
		front = { x = rim.x + bx * 0.55, z = rim.z + bz * 0.55, y = 9.6 },
		spot = { x = rim.x + bx * 4 + sx * 2.5, z = rim.z + bz * 4 + sz * 2.5 },
	}
	reb.tCatch = reb.tRim + 0.55
	reb.tJump = reb.tCatch - REB_LEAD
	reb.from = Possession.frame(plan, plan.tShot).players[who]
	plan.rebound = reb
	plan.length = reb.tCatch + 1.3
end

-- Where player i (offense 1-5, defense 6-10) is at time t, and what they're doing.
-- face: world yaw in degrees, 0 = toward the camera (+Z), 90 = toward +X.
function Possession.frame(plan, t)
	local dir = plan.dir
	local out = { players = {}, ball = nil }
	local handlerStart = { x = dir * 2, z = 0 }
	for i = 1, 5 do
		local fin = plan.finals[i]
		-- Everyone starts spread near half court and jogs into their spot by tMove.
		local start = i == plan.handler and handlerStart or { x = dir * (3 + i * 2), z = fin.z * 0.6 }
		local u = smooth(t / plan.tMove)
		local p = { x = lerp(start.x, fin.x, u), z = lerp(start.z, fin.z, u), face = dir > 0 and 90 or -90 }
		local moving = t < plan.tMove * 0.95
		if i == plan.shooter and plan.driveTo and t >= plan.tCatch then
			-- Dunk: drive to the rim, facing it, then the dunk clip.
			local u = smooth((t - plan.tCatch) / DRIVE)
			p.x, p.z = lerp(plan.driveFrom.x, plan.driveTo.x, u), lerp(plan.driveFrom.z, plan.driveTo.z, u)
			p.face = math.deg(math.atan2(dir * RIM_X - p.x, -p.z))
			if t < plan.tShot then
				p.clip, p.t = "DribbleLive", (t - plan.tCatch) % 0.9
			else
				p.clip, p.t = plan.shotClip, t - plan.tShot
			end
		elseif i == plan.shooter and t >= plan.tShot then
			p.clip, p.t = plan.shotClip, t - plan.tShot
		elseif i == plan.handler then
			if t < plan.tMove then
				p.clip, p.t = "DribbleLive", t % 0.9
			elseif t < plan.tPass then
				p.clip, p.t = plan.moveClip, t - plan.tMove
				p.face = 0 -- show the move to the camera, like a broadcast angle
			elseif plan.passer and t < plan.tCatch then
				p.clip, p.t = "ChestPass", (t - plan.tPass) * 2
			else
				p.clip, p.t = "Idle", t % 2
			end
		else
			p.clip, p.t = moving and "Jog" or "Idle", moving and (t % 0.7) or (t % 2)
			if plan.driveTo and t >= plan.tCatch and SPOTS[i][1] < 10 then
				-- Bigs clear the lane for the driver: slide out to the short corner.
				local u2 = smooth((t - plan.tCatch) / 0.6)
				local cz = (fin.z >= 0 and 1 or -1) * 17 * FT
				p.x, p.z = lerp(fin.x, dir * (RIM_X - 4 * FT), u2), lerp(fin.z, cz, u2)
				if u2 < 1 then
					p.clip, p.t = "Jog", t % 0.7
				end
			end
		end
		out.players[i] = p
	end
	-- Defenders: between their man and the rim, about 5 ft off, sliding when the man moves.
	for i = 1, 5 do
		local o = out.players[i]
		local rim = { x = dir * RIM_X, z = 0 }
		local dx, dz = rim.x - o.x, rim.z - o.z
		local len = math.sqrt(dx * dx + dz * dz)
		local d = 5 * FT
		local p = { x = o.x + dx / len * d, z = o.z + dz / len * d, face = dir > 0 and -90 or 90 }
		if i == plan.shooter and plan.driveTo and t >= plan.tCatch then
			-- Beaten off the dribble: trailing on the hip, a step behind and to the side.
			local side = o.z > 0 and -1 or 1
			p.x, p.z = o.x - dx / len * 1.5 * FT + (-dz / len) * side * 2.5 * FT, o.z - dz / len * 1.5 * FT + (dx / len) * side * 2.5 * FT
			p.face = o.face
		end
		p.clip = (o.clip == "Jog" or o.clip == "DribbleLive" or o.clip == plan.moveClip) and "DefSlide" or "Idle"
		p.t = p.clip == "DefSlide" and (t % 0.9) or ((t + i * 0.37) % 2)
		if i == plan.shooter and t >= plan.tShot then
			p.clip, p.t = "Block", math.max(0, t - plan.tShot - 0.1) -- contest the shot
		end
		out.players[5 + i] = p
	end
	local reb = plan.rebound
	if reb and t >= plan.tShot + 0.2 then
		-- The rebounder reads the miss, gets to the spot, and goes up for it.
		local p = out.players[reb.who]
		local u = smooth((t - plan.tShot - 0.2) / math.max(0.1, reb.tJump - plan.tShot - 0.2))
		p.x, p.z = lerp(reb.from.x, reb.spot.x, u), lerp(reb.from.z, reb.spot.z, u)
		p.face = math.deg(math.atan2(dir * RIM_X - p.x, -p.z))
		if t < reb.tJump then
			p.clip, p.t = "Jog", t % 0.7
		else
			p.clip, p.t = "Rebound", t - reb.tJump
		end
	end
	-- Ball: with the handler until the pass, in the air during the pass, then the shot clip owns it.
	if reb and t >= reb.tCatch then
		out.ball = { owner = reb.who }
	elseif reb and t >= reb.tRim then
		local u = clamp01((t - reb.tRim) / (reb.tCatch - reb.tRim))
		out.ball = {
			free = true,
			rebound = u, -- CourtView aims this at the rebounder's hands
			x = lerp(reb.front.x, reb.spot.x, u),
			z = lerp(reb.front.z, reb.spot.z, u),
			y = lerp(reb.front.y, 8, u) + 1.6 * 4 * u * (1 - u),
		}
	elseif plan.passer and t >= plan.tPass and t < plan.tCatch then
		local a, b = out.players[plan.passer], out.players[plan.shooter]
		local u = clamp01((t - plan.tPass - 0.15) / 0.4)
		out.ball = { x = lerp(a.x, b.x, u), z = lerp(a.z, b.z, u), y = 4.2 + math.sin(u * math.pi) * 0.6, free = true }
	elseif t < plan.tPass or (not plan.passer and t < plan.tShot) then
		out.ball = { owner = plan.handler }
	else
		out.ball = { owner = plan.shooter }
	end
	return out
end

return Possession
