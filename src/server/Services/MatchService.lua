--!nonstrict
-- PLAY: finds an opponent, runs the match engine on the server and pays out. The client gets
-- the whole game up front and acts it out on the court; the result can't be changed from there.
--
-- Opponents: saved offline teams are the plan (MAIN_GAME_IDEA, matchmaking within +-100 Elo).
-- Until that store exists, the opponent is a generated club built close to your own strength.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Elo = require(Shared.Elo)
local MatchSim = require(Shared.MatchSim)
local Names = require(Shared.Names)
local PlayerFactory = require(Shared.PlayerFactory)
local Rng = require(Shared.Rng)
local Store = require(Shared.Store)

local ProgressService = require(script.Parent.ProgressService)

local MatchService = {}
MatchService.handlers = {}
local H = MatchService.handlers

local rng = Rng.new(os.time() + 17)
local lastMatch = {} -- [player] = os.clock() of the last match start

local CLUB_FIRST = { "Harbor", "Northside", "Cedar", "Ironwood", "Bayview", "Summit", "Riverside", "Copper", "Lakeshore", "Granite", "Midtown", "Westgate" }
local CLUB_LAST = { "Hawks", "Owls", "Comets", "Foxes", "Wolves", "Pilots", "Bison", "Rockets", "Herons", "Lynx", "Mustangs", "Tides" }
local KITS = {
	{ 37, 99, 235 }, { 232, 69, 107 }, { 31, 158, 63 }, { 232, 101, 12 }, { 130, 70, 220 }, { 20, 24, 48 }, { 0, 150, 160 }, { 200, 160, 0 },
}

local function rarityFor(ovr)
	for _, r in ipairs(Config.Rarities) do
		if ovr >= r.min and ovr <= r.max then
			return r.id
		end
	end
	return ovr < Config.Rarities[1].min and "Common" or "HallOfFame"
end

-- Your matchday ten (starters first), falling back to your best players if it's out of date.
local function matchdayTen(profile)
	local byId = {}
	for _, p in ipairs(profile.players) do
		byId[p.id] = p
	end
	local ten, used = {}, {}
	for _, id in ipairs(profile.matchday or {}) do
		local p = byId[id]
		if p and not used[id] then
			table.insert(ten, p)
			used[id] = true
		end
	end
	if #ten < 10 then
		local rest = {}
		for _, p in ipairs(profile.players) do
			if not used[p.id] then
				table.insert(rest, p)
			end
		end
		table.sort(rest, function(a, b)
			return PlayerFactory.overall(a) > PlayerFactory.overall(b)
		end)
		for _, p in ipairs(rest) do
			if #ten >= 10 then
				break
			end
			table.insert(ten, p)
		end
	end
	return ten
end

local function minutesFor(profile, ten)
	local m = {}
	for i, p in ipairs(ten) do
		m[i] = (profile.minutes and profile.minutes[p.id]) or MatchSim.DefaultMinutes[i]
	end
	-- Each slot's starter and bench player share 48 minutes.
	for s = 1, 5 do
		m[s] = math.clamp(m[s], 0, 48)
		m[s + 5] = 48 - m[s]
	end
	return m
end

-- A generated opponent near your starters' average OVR.
local function cpuTeam(avgOvr)
	local players = {}
	for i, pos in ipairs({ "PG", "SG", "SF", "PF", "C", "PG", "SG", "SF", "PF", "C" }) do
		local ovr = math.clamp(math.floor(avgOvr + rng:normal(0, 2.5) - (i > 5 and 6 or 0) + 0.5), 45, Config.MaxOvr)
		local p = PlayerFactory.generate(rng, { rarity = rarityFor(ovr), pos = pos, ovr = ovr, finish = false })
		p.id = string.format("cpu%d-%08x", i, rng:int(0, 0x7fffffff))
		table.insert(players, p)
	end
	return {
		name = rng:pick(CLUB_FIRST) .. " " .. rng:pick(CLUB_LAST),
		players = players,
		kit = rng:pick(KITS),
	}
end

local function compactEvents(events, homeIndex, awayIndex)
	local out = {}
	for i, ev in ipairs(events) do
		local e = table.clone(ev)
		local on = { {}, {} }
		for s = 1, 5 do
			on[1][s] = homeIndex[ev.onCourt[1][s]]
			on[2][s] = awayIndex[ev.onCourt[2][s]]
		end
		e.onCourt = on -- indexes into home.players / away.players (1-10)
		out[i] = e
	end
	return out
end

function H.playMatch(player, profile)
	local now = os.clock()
	if lastMatch[player] and now - lastMatch[player] < Config.MatchCooldownSeconds then
		return false, string.format("Your team is still in a game. Try again in %d s.", math.ceil(Config.MatchCooldownSeconds - (now - lastMatch[player])))
	end
	local ten = matchdayTen(profile)
	if #ten < 10 then
		return false, "You need 10 players to play."
	end
	lastMatch[player] = now
	local avg = 0
	for i = 1, 5 do
		avg += PlayerFactory.overall(ten[i])
	end
	avg /= 5
	local opp = cpuTeam(avg)
	local home = { players = ten, minutes = minutesFor(profile, ten) }
	local result = MatchSim.play(rng, home, { players = opp.players })

	local won = result.winner == 1
	local oppElo = profile.elo.elo
	local newElo, delta = Elo.apply(profile.elo, oppElo, won)
	profile.elo = newElo
	local tier = Elo.tier(newElo.elo)
	local R = Config.MatchRewards
	local coins = math.floor((won and R.winCoins or R.lossCoins) * (tier.coinMult or 1) + 0.5)
	if (profile.boosts.DoubleCoins or 0) > os.time() then
		coins *= 2
	end
	local fans = won and R.winFans or R.lossFans
	if (profile.boosts.DoubleFans or 0) > os.time() then
		fans *= 2
	end
	profile.coins = math.min(Config.MaxCoins, profile.coins + coins)
	profile.fans = (profile.fans or 0) + fans
	ProgressService.recordGame(player, result.box.home, result.score[2])

	local homeIndex, awayIndex = {}, {}
	local homeCards, awayCards = {}, {}
	for i, p in ipairs(ten) do
		homeIndex[p.id] = i
		homeCards[i] = Store.cardView(p)
	end
	for i, p in ipairs(opp.players) do
		awayIndex[p.id] = i
		awayCards[i] = Store.cardView(p)
	end
	local function boxList(box, list)
		local out = {}
		for i, p in ipairs(list) do
			out[i] = box[p.id]
		end
		return out
	end
	return true, {
		home = { name = profile.club and profile.club.name or player.DisplayName .. "'s Club", players = homeCards, box = boxList(result.box.home, ten) },
		away = { name = opp.name, players = awayCards, kit = opp.kit, box = boxList(result.box.away, opp.players) },
		events = compactEvents(result.events, homeIndex, awayIndex),
		quarters = result.quarters,
		score = result.score,
		mvp = homeIndex[result.mvp] and { side = 1, index = homeIndex[result.mvp] } or { side = 2, index = awayIndex[result.mvp] },
		rewards = { won = won, coins = coins, fans = fans, elo = newElo.elo, eloDelta = delta, tier = tier.id },
		quarterSeconds = Config.QuarterSeconds.queued,
		plot = player:GetAttribute("Plot"), -- played on your Home Court in the lobby
	}
end

return MatchService
