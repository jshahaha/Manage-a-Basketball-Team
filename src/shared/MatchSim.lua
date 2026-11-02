--!nonstrict
-- The match engine: plays a full game between two matchday tens and returns every possession,
-- the score by quarter and both box scores. Pure Luau, so the server runs it and the tests check
-- it without Roblox. The client plays the possessions on the 3D court with Possession.plan, so
-- each event carries the plan's slots (1-5 offense, 6-10 defense).
--
--   local game = MatchSim.play(rng, home, away)
--   home / away = { players = { 10 players, starters first }, minutes = { 10 numbers }? , name = "..." }
--   game.score = { home, away }, game.quarters = { {h, a}, ... }, game.events = { ... },
--   game.box = { home = { [playerId] = line }, away = { ... } }, game.mvp = playerId
--
-- Each event: { q, clock (seconds left in the quarter), team (1 home, 2 away), kind, slot, made,
--   pts, assist, rebounder, blocker, stealer, fta, ftm, onCourt = { home ids[5], away ids[5] }, score }
-- kind is "three", "jumper", "dunk" (drives, layups and dunks), "freeThrows" or "turnover".

local function import(name)
	return require(script and script.Parent:FindFirstChild(name) or "./" .. name)
end
local Config = import("Config")
local Stats = import("Stats")

local MatchSim = {}

MatchSim.QuarterSeconds = 12 * 60
MatchSim.OvertimeSeconds = 5 * 60
MatchSim.DefaultMinutes = { 34, 34, 34, 34, 34, 14, 14, 14, 14, 14 }

-- Tuning: league-average rates before ratings move them.
MatchSim.Base = {
	possessionSeconds = 14.7, -- about 98 possessions a team
	turnover = 0.13,
	stealShare = 0.55, -- share of turnovers that are steals
	shootingFoul = 0.11,
	homeMake = 0.012, -- home court: a touch more comfortable shooting
	make = { three = 0.36, jumper = 0.44, dunk = 0.62 },
	assisted = { three = 0.8, jumper = 0.5, dunk = 0.62 },
	offensiveBoard = 0.25,
	blockShare = 0.45, -- share of missed drives that are blocked (the rest rim out)
}

local function r(p, key)
	return (p.ratings and p.ratings[key]) or 60
end

-- Who is on the floor in plan slot s at game minute m (0-48) of quarter q. A starter and the
-- bench player in the same slot share the slot's 48 minutes: the bench player takes a stretch
-- late in Q1 and Q3 and early in Q2, and the starters close the game.
local function slotPlayer(team, s, q, minuteInQuarter)
	local benchMin = math.clamp(48 - team.minutes[s], 0, 48)
	local per = benchMin / 4
	local onBench
	if q == 1 or q == 3 then
		onBench = minuteInQuarter >= 12 - per
	elseif q == 2 then
		onBench = minuteInQuarter < per
	elseif q == 4 then
		onBench = minuteInQuarter >= 12 - per * 2 and minuteInQuarter < 12 - per -- before crunch time
	else
		onBench = false
	end
	return onBench and team.players[s + 5] or team.players[s]
end

local function lineup(team, q, minuteInQuarter)
	local five = {}
	for s = 1, 5 do
		five[s] = slotPlayer(team, s, q, minuteInQuarter)
	end
	return five
end

-- Weighted pick of a slot from a five by a score function.
local function pickSlot(rng, five, score, exclude)
	local entries = {}
	for s, p in ipairs(five) do
		if s ~= exclude then
			table.insert(entries, { s, math.max(1, score(p)) })
		end
	end
	return rng:weighted(entries)
end

local function avg(five, key)
	local t = 0
	for _, p in ipairs(five) do
		t += r(p, key)
	end
	return t / #five
end

-- Shot kind for a shooter, from their ratings and the team's tendency.
local function shotKind(rng, p, bias)
	local w3 = math.max(1, r(p, "three") - 40) ^ 1.5 * 1.35 * (bias.three or 1)
	local wj = math.max(1, r(p, "mid") - 40) ^ 1.5 * (bias.jumper or 1)
	local fin = math.max(r(p, "drivingDunk"), r(p, "layup"), r(p, "closeShot"))
	local wd = math.max(1, fin - 40) ^ 1.5 * 1.15 * (bias.dunk or 1)
	return rng:weighted({ { "three", w3 }, { "jumper", wj }, { "dunk", wd } })
end

local function shotRating(p, kind)
	if kind == "three" then
		return r(p, "three")
	elseif kind == "jumper" then
		return r(p, "mid")
	end
	return math.max(r(p, "drivingDunk"), r(p, "layup"), r(p, "closeShot"))
end

local function defenseRating(d, kind)
	if kind == "dunk" then
		return (r(d, "interiorD") + r(d, "block")) / 2
	end
	return r(d, "perimeterD")
end

local function usage(p)
	local best = math.max(r(p, "three"), r(p, "mid"), r(p, "drivingDunk"), r(p, "layup"))
	return math.max(1, best - 45) ^ 2
end

-- Play one game. opts: { homeEdge = true, bias = { home = {three=..}, away = {...} },
--   goTo = { home = slot, away = slot } } (Go-To player takes more shots).
function MatchSim.play(rng, home, away, opts)
	opts = opts or {}
	local B = MatchSim.Base
	local teams = { home, away }
	for _, t in ipairs(teams) do
		t.minutes = t.minutes or MatchSim.DefaultMinutes
	end
	local box = { {}, {} }
	for side, t in ipairs(teams) do
		for _, p in ipairs(t.players) do
			box[side][p.id] = Stats.newLine()
		end
	end
	local score = { 0, 0 }
	local quarters = {}
	local events = {}
	local poss = rng:chance(0.5) and 1 or 2 -- tip-off

	local function line(side, p)
		return box[side][p.id]
	end

	local q = 0
	while q < 4 or score[1] == score[2] do
		q += 1
		local length = q <= 4 and MatchSim.QuarterSeconds or MatchSim.OvertimeSeconds
		local clock = length
		local qScore = { 0, 0 }
		if q > 1 and q <= 4 then
			poss = (q % 2 == 0) and 2 or 1 -- alternate quarter starts
		end
		while clock > 0 do
			local minute = (length - clock) / 60
			local fives = { lineup(teams[1], q, minute), lineup(teams[2], q, minute) }
			local dur = math.min(clock, math.clamp(rng:normal(B.possessionSeconds, 4), 5, 24))
			-- Minutes for everyone on the floor.
			for side = 1, 2 do
				for _, p in ipairs(fives[side]) do
					line(side, p).min += dur / 60
				end
			end
			clock -= dur
			local off, def = poss, 3 - poss
			local O, D = fives[off], fives[def]
			local ev = { q = q, clock = math.max(0, clock), team = off, onCourt = { {}, {} } }
			for side = 1, 2 do
				for s, p in ipairs(fives[side]) do
					ev.onCourt[side][s] = p.id
				end
			end
			local bias = (opts.bias and opts.bias[off == 1 and "home" or "away"]) or {}
			local goTo = opts.goTo and opts.goTo[off == 1 and "home" or "away"]
			local keep = false
			-- Turnover?
			local toChance = B.turnover + (avg(D, "steal") - avg(O, "handling")) * 0.002
			if rng:chance(math.clamp(toChance, 0.06, 0.22)) then
				local s = pickSlot(rng, O, function(p)
					return 160 - r(p, "handling")
				end)
				ev.kind, ev.slot = "turnover", s
				line(off, O[s]).tov += 1
				if rng:chance(B.stealShare) then
					local d = pickSlot(rng, D, function(p)
						return r(p, "steal") - 30
					end)
					ev.stealer = d + 5
					line(def, D[d]).stl += 1
				end
			else
				local s = pickSlot(rng, O, function(p)
					return usage(p)
				end)
				if goTo and rng:chance(0.25) then
					s = goTo
				end
				local shooter, defender = O[s], D[s]
				ev.slot = s
				if rng:chance(B.shootingFoul) then
					-- Two free throws (away teams lose a little to crowd noise).
					ev.kind = "freeThrows"
					local ft = math.clamp(0.55 + (r(shooter, "ft") - 40) * 0.0075, 0.45, 0.95)
					if off == 2 and opts.homeEdge ~= false then
						local clutch = q >= 4 and clock < 120 and math.abs(score[1] - score[2]) <= 5
						ft -= clutch and Config.HomeCourt.awayClutchFreeThrowPenalty or Config.HomeCourt.awayFreeThrowPenalty
					end
					local made = 0
					for _ = 1, 2 do
						if rng:chance(ft) then
							made += 1
						end
					end
					local l = line(off, shooter)
					l.fta += 2
					l.ftm += made
					l.pts += made
					line(def, defender).pf += 1
					ev.fta, ev.ftm, ev.pts, ev.made = 2, made, made, made > 0
				else
					local kind = shotKind(rng, shooter, bias)
					local rating = shotRating(shooter, kind)
					local chance = B.make[kind] + (rating - defenseRating(defender, kind)) * 0.0045 + (rating - 70) * 0.002
						+ ((off == 1 and opts.homeEdge ~= false) and B.homeMake or 0)
					local made = rng:chance(math.clamp(chance, 0.15, 0.85))
					local pts = kind == "three" and 3 or 2
					local l = line(off, shooter)
					ev.kind, ev.made = kind, made
					l.fga += 1
					if kind == "three" then
						l.tpa += 1
					end
					if made then
						l.fgm += 1
						l.pts += pts
						if kind == "three" then
							l.tpm += 1
						elseif kind == "dunk" and r(shooter, "drivingDunk") >= 70 and rng:chance(0.55) then
							l.dunks += 1
							ev.slam = true
						end
						ev.pts = pts
						if rng:chance(B.assisted[kind]) then
							local a = pickSlot(rng, O, function(p)
								return r(p, "passing") - 30
							end, s)
							ev.assist = a
							line(off, O[a]).ast += 1
						end
					else
						ev.pts = 0
						if kind == "dunk" and rng:chance(B.blockShare * math.clamp(r(defender, "block") / 70, 0.5, 1.4)) then
							-- Blocked at the rim: the defense recovers it.
							ev.blocker = s + 5
							line(def, defender).blk += 1
						else
							local oChance = B.offensiveBoard + (avg(O, "oreb") - avg(D, "dreb")) * 0.004
							if rng:chance(math.clamp(oChance, 0.12, 0.4)) then
								local reb = pickSlot(rng, O, function(p)
									return r(p, "oreb") - 30
								end)
								ev.rebounder = reb
								line(off, O[reb]).oreb += 1
								keep = true
							else
								local reb = pickSlot(rng, D, function(p)
									return r(p, "dreb") - 30
								end)
								ev.rebounder = reb + 5
								line(def, D[reb]).dreb += 1
							end
						end
					end
				end
			end
			if ev.pts and ev.pts > 0 then
				score[off] += ev.pts
				qScore[off] += ev.pts
			end
			ev.score = { score[1], score[2] }
			table.insert(events, ev)
			if not keep then
				poss = def
			end
		end
		table.insert(quarters, qScore)
	end

	-- Whole minutes in the box score, rounded so each team adds up to its game length.
	for side = 1, 2 do
		local total = 0
		for _, l in pairs(box[side]) do
			l.min = math.floor(l.min + 0.5)
			total += l.min
		end
		local want = 240 + (#quarters - 4) * 25
		local top
		for _, l in pairs(box[side]) do
			if not top or l.min > top.min then
				top = l
			end
		end
		top.min += want - total
	end
	local lines = {}
	for side = 1, 2 do
		for id, l in pairs(box[side]) do
			lines[id] = l
		end
	end
	-- MVP from the winning side.
	local winner = score[1] > score[2] and 1 or 2
	local mvp = Stats.mvp(box[winner])
	return {
		score = score,
		quarters = quarters,
		events = events,
		box = { home = box[1], away = box[2] },
		winner = winner,
		mvp = mvp,
	}
end

-- What Possession.plan needs to draw one event: { kind, shooter, assist, made, rebounder }.
-- Turnovers and free throws have no court animation yet; they return nil.
function MatchSim.planResult(ev)
	if ev.kind ~= "three" and ev.kind ~= "jumper" and ev.kind ~= "dunk" then
		return nil
	end
	local kind = ev.kind
	if kind == "dunk" and not ev.made and not ev.blocker then
		kind = "jumper" -- a drive that rims out is drawn as a short pull-up miss and a rebound
	end
	return { kind = kind, shooter = ev.slot, assist = ev.assist, made = ev.made, rebounder = ev.rebounder, blocker = ev.blocker }
end

return MatchSim
