--!nonstrict
-- Scouting Report: your scouts bring back 5 players. You never see their OVR. What you do see depends
-- on your scout team level, and every player costs the same to sign, so the price gives nothing away.
--
--   Level 0  best stat
--   Level 1  + position
--   Level 2  + 2nd best stat
--   Level 3  + archetype and nationality
--   Level 4  + 3rd best stat
--   Level 5  + rarity
--
-- State saved on the profile: profile.scouting = { level, report = { players = {ids}, signed = {bool}, expires } }

local function load(name)
	return require(script and script.Parent:FindFirstChild(name) or "./" .. name)
end
local Config = load("Config")
local Ratings = load("Ratings")
local PlayerFactory = load("PlayerFactory")

local Scouting = {}

Scouting.ReportSize = 5
Scouting.SignCost = 25000 -- coins, same for every player
Scouting.RefreshCost = 5000 -- coins, to refresh before the timer runs out
-- Same odds at every level: upgrades buy information, not better players.
Scouting.Odds = { Common = 50, Rare = 32, Epic = 13, Legendary = 4.5, HallOfFame = 0.5 }

-- gems = cost to reach this level from the one before. hours = time until a free new report.
Scouting.Levels = {
	[0] = { stats = 1, hours = 6 },
	[1] = { stats = 1, position = true, hours = 5.5, gems = 50 },
	[2] = { stats = 2, position = true, hours = 5, gems = 100 },
	[3] = { stats = 2, position = true, archetype = true, nation = true, hours = 4.5, gems = 200 },
	[4] = { stats = 3, position = true, archetype = true, nation = true, hours = 4, gems = 400 },
	[5] = { stats = 3, position = true, archetype = true, nation = true, rarity = true, hours = 3, gems = 800 },
}
Scouting.MaxLevel = 5

function Scouting.newState()
	return { level = 0, report = nil }
end

-- The player's top `n` ratings, best first: { { key, name, value }, ... }
function Scouting.topStats(player, n: number)
	local list = {}
	for key, value in pairs(player.ratings) do
		table.insert(list, { key, Ratings.Names[key] or key, value })
	end
	table.sort(list, function(a, b)
		if a[3] ~= b[3] then
			return a[3] > b[3]
		end
		return a[1] < b[1]
	end)
	local out = {}
	for i = 1, math.min(n, #list) do
		out[i] = list[i]
	end
	return out
end

-- What the UI may show for one scouted player at this level. Never includes OVR.
function Scouting.view(player, level: number)
	local L = Scouting.Levels[math.clamp(level, 0, Scouting.MaxLevel)]
	return {
		stats = Scouting.topStats(player, L.stats),
		position = L.position and player.pos or nil,
		archetype = L.archetype and Ratings.archetypeName(PlayerFactory.archetype(player)) or nil,
		nation = L.nation and player.nation or nil,
		rarity = L.rarity and player.rarity or nil,
	}
end

-- Roll a new report. drawFn(rng, rarity) returns a catalog player (Catalog.draw with kind "player").
function Scouting.roll(rng, state, now: number, drawFn)
	local entries = {}
	for _, r in ipairs(Config.Rarities) do
		local p = Scouting.Odds[r.id] or 0
		if p > 0 then
			table.insert(entries, { r.id, p })
		end
	end
	local players, seen = {}, {}
	while #players < Scouting.ReportSize do
		local card = drawFn(rng, rng:weighted(entries))
		if not seen[card.id] then
			seen[card.id] = true
			table.insert(players, card.id)
		end
	end
	local hours = Scouting.Levels[state.level].hours
	state.report = { players = players, signed = {}, expires = now + math.floor(hours * 3600) }
	return state.report
end

-- Get a new report. how: "free" (the timer ran out), "ticket" (uses a Scout Ticket) or "coins".
-- Returns ok, reason, cost table ({ coins = n } or { tickets = 1 } or {}).
function Scouting.canRefresh(state, now: number, how: string, coins: number, tickets: number)
	if how == "free" then
		if state.report and now < state.report.expires then
			return false, "not yet"
		end
		return true, nil, {}
	elseif how == "ticket" then
		if (tickets or 0) < 1 then
			return false, "no tickets"
		end
		return true, nil, { tickets = 1 }
	elseif how == "coins" then
		if coins < Scouting.RefreshCost then
			return false, "not enough coins"
		end
		return true, nil, { coins = Scouting.RefreshCost }
	end
	return false, "bad option"
end

function Scouting.canSign(state, index: number, coins: number)
	local report = state.report
	if not report or not report.players[index] then
		return false, "no player"
	end
	if report.signed[index] then
		return false, "already signed"
	end
	if coins < Scouting.SignCost then
		return false, "not enough coins"
	end
	return true
end

function Scouting.upgradeCost(level: number): number?
	local nextL = Scouting.Levels[level + 1]
	return nextL and nextL.gems or nil
end

return Scouting
