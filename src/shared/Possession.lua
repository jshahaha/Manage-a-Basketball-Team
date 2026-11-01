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
local SHOT_SPOT = { jumper = 15, three = 24.5, dunk = 1.5 }

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
	local moveClip = offense[handler].moves[1] or "Crossover"
	local moveLen = 1.0
	local tPass = tMove + moveLen
	if passer and passer ~= shooter then
		handler = passer
	end
	local tShot = tPass + ((passer and passer ~= shooter) and 0.6 or 0)
	local shotClip = r.kind == "dunk" and offense[shooter].dunk or offense[shooter].shot
	plan.shotClip, plan.moveClip, plan.tMove, plan.tPass, plan.tShot = shotClip, moveClip, tMove, tPass, tShot
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
	finals[shooter] = r.kind == "dunk" and { x = dir * (RIM_X - shotFeet * FT), z = 0 }
		or { x = dir * (RIM_X - s[1] * k * FT), z = s[2] * k * FT }
	plan.finals = finals
	plan.handler, plan.shooter, plan.passer = handler, shooter, (passer and passer ~= shooter) and passer or nil
	return plan
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
		if i == plan.handler then
			if t < plan.tMove then
				p.clip, p.t = "DribbleLive", t % 0.9
			elseif t < plan.tPass then
				p.clip, p.t = plan.moveClip, t - plan.tMove
				p.face = 0 -- show the move to the camera, like a broadcast angle
			elseif plan.passer and t < plan.tShot then
				p.clip, p.t = "ChestPass", (t - plan.tPass) * 2
			else
				p.clip, p.t = "Idle", t % 2
			end
		elseif i == plan.shooter and t >= plan.tShot then
			p.clip, p.t = plan.shotClip, t - plan.tShot
		else
			p.clip, p.t = moving and "Jog" or "Idle", moving and (t % 0.7) or (t % 2)
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
		p.clip = (o.clip == "Jog" or o.clip == "DribbleLive" or o.clip == plan.moveClip) and "DefSlide" or "Idle"
		p.t = p.clip == "DefSlide" and (t % 0.9) or ((t + i * 0.37) % 2)
		if i == plan.shooter and t >= plan.tShot then
			p.clip, p.t = "Block", math.max(0, t - plan.tShot - 0.1) -- contest the shot
		end
		out.players[5 + i] = p
	end
	-- Ball: with the handler until the pass, in the air during the pass, then the shot clip owns it.
	if plan.passer and t >= plan.tPass and t < plan.tShot then
		local a, b = out.players[plan.passer], out.players[plan.shooter]
		local u = clamp01((t - plan.tPass - 0.15) / 0.4)
		out.ball = { x = lerp(a.x, b.x, u), z = lerp(a.z, b.z, u), y = 4.2 + math.sin(u * math.pi) * 0.6, free = true }
	elseif t < plan.tShot then
		out.ball = { owner = plan.handler }
	else
		out.ball = { owner = plan.shooter }
	end
	return out
end

return Possession
