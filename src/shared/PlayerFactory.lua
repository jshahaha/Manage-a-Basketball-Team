--!nonstrict
-- Creates fictional players with 20 ratings, and works out their OVR, card scores and archetype.

local function load(name)
	return require(script and script.Parent:FindFirstChild(name) or "./" .. name)
end
local Config = load("Config")
local Ratings = load("Ratings")
local Names = load("Names")
local Rng = load("Rng")
local Stats = load("Stats")

local PlayerFactory = {}

-- Rating shape for each position, as offsets from the player's average.
local Shape = {
	PG = { passing = 12, handling = 13, speed = 10, three = 6, mid = 4, steal = 6, perimeterD = 3,
		interiorD = -12, block = -16, oreb = -12, dreb = -8, strength = -10, standingDunk = -14, post = -12 },
	SG = { three = 12, mid = 9, ft = 8, perimeterD = 6, speed = 6, handling = 4, steal = 3,
		interiorD = -10, block = -12, oreb = -10, dreb = -6, strength = -6, standingDunk = -10, post = -10 },
	SF = { drivingDunk = 6, layup = 5, vertical = 5, perimeterD = 4, mid = 3, speed = 3,
		post = -4, block = -4, handling = -2 },
	PF = { closeShot = 7, post = 8, interiorD = 8, dreb = 9, oreb = 6, strength = 9, standingDunk = 6,
		three = -8, handling = -10, speed = -6, passing = -6, steal = -6 },
	C = { standingDunk = 12, block = 13, interiorD = 13, dreb = 13, oreb = 11, strength = 12, post = 6, closeShot = 6,
		three = -16, mid = -8, handling = -16, speed = -12, passing = -8, perimeterD = -10, steal = -10, ft = -8 },
}

-- Height range in inches for each position.
local Height = { PG = { 72, 77 }, SG = { 75, 79 }, SF = { 78, 81 }, PF = { 80, 83 }, C = { 82, 87 } }

local function newId(rng): string
	return string.format("%08x%06x", rng:int(0, 0x7fffffff), rng:int(0, 0xffffff))
end

-- Build ratings around an average, then nudge them until OVR lands on the target.
local function buildRatings(rng, pos: string, target: number)
	local shape = Shape[pos]
	local r = {}
	for _, k in ipairs(Ratings.Keys) do
		r[k] = target + (shape[k] or 0) + rng:normal(0, 4)
	end
	for _ = 1, 6 do
		local diff = target - Ratings.ovr(r, pos)
		if diff == 0 then
			break
		end
		for _, k in ipairs(Ratings.Keys) do
			r[k] += diff
		end
		for _, k in ipairs(Ratings.Keys) do
			r[k] = math.clamp(r[k], Ratings.MIN, Ratings.MAX)
		end
	end
	for _, k in ipairs(Ratings.Keys) do
		r[k] = Ratings.clamp(r[k])
	end
	return r
end

local function rollFinish(rng): string?
	local roll = rng:next()
	-- check rarest first
	for i = #Config.Finishes, 1, -1 do
		local f = Config.Finishes[i]
		if roll < f.chance then
			return f.id
		end
	end
	return nil
end

-- opts: { rarity = "Epic", pos = "PG", ovr = 76, finish = "HotHand" | false, id = "..." }
function PlayerFactory.generate(rng, opts)
	opts = opts or {}
	local rarity = Config.RarityById[opts.rarity or "Common"]
	assert(rarity, "unknown rarity " .. tostring(opts.rarity))
	local pos = opts.pos or rng:pick(Config.Positions)
	local target = opts.ovr or rng:int(rarity.min, rarity.max)
	local ratings = buildRatings(rng, pos, target)
	local h = Height[pos]
	local height = rng:int(h[1], h[2])
	local finish = opts.finish
	if finish == nil then
		finish = rollFinish(rng)
	end
	local id = opts.id or newId(rng)
	local base = Ratings.ovr(ratings, pos)
	local w = Config.Weight[pos]
	local alt = {}
	for _, other in ipairs(Config.SecondaryPositions[pos]) do
		if rng:next() < 0.45 then
			table.insert(alt, other)
		end
	end
	local nations = {}
	for _, n in ipairs(Config.Nations) do
		table.insert(nations, { n[1], n[2] })
	end
	return {
		id = id,
		name = opts.name or Names.player(rng, rarity.id),
		pos = pos,
		altPos = alt, -- other positions they can play with no penalty, e.g. { "SG" }
		positionless = rarity.order >= Config.RarityById.Epic.order and rng:next() < Config.PositionlessChance or nil,
		nation = opts.nation or rng:weighted(nations),
		weight = rng:int(w[1], w[2]),
		club = nil, -- set to the owning club's id when kept; nil shows "Free Agent"
		rarity = rarity.id,
		finish = finish or nil,
		ratings = ratings,
		potential = math.min(Config.MaxOvr, base + rng:int(2, 12)),
		height = height,
		wingspan = height + rng:int(0, 6),
		stars = 1,
		faceSeed = id, -- the icon generator draws the face from this
		career = Stats.newCareer(),
	}
end

local POS_INDEX = { PG = 1, SG = 2, SF = 3, PF = 4, C = 5 }

-- OVR lost when this player plays `slot`. 0 for their main, listed or any position if Positionless.
function PlayerFactory.positionPenalty(player, slot: string): number
	if slot == player.pos or player.positionless or table.find(player.altPos or {}, slot) then
		return 0
	end
	local steps = math.abs(POS_INDEX[slot] - POS_INDEX[player.pos])
	return Config.OutOfPositionPenalty[steps] or 0
end

-- OVR when playing `slot`: rated with that position's weights, minus the penalty.
function PlayerFactory.overallAt(player, slot: string): number
	local ovr = Ratings.ovr(player.ratings, slot) + PlayerFactory.finishBonus(player) - PlayerFactory.positionPenalty(player, slot)
	return math.max(1, math.min(Config.MaxOvr, ovr))
end

function PlayerFactory.finishBonus(player): number
	for _, f in ipairs(Config.Finishes) do
		if f.id == player.finish then
			return f.bonus
		end
	end
	return 0
end

function PlayerFactory.overall(player): number
	return math.min(Config.MaxOvr, Ratings.ovr(player.ratings, player.pos) + PlayerFactory.finishBonus(player))
end

function PlayerFactory.groupScores(player)
	return Ratings.groupScores(player.ratings)
end

function PlayerFactory.archetype(player): string
	return Ratings.archetype(player.ratings)
end

-- Pick a rarity from a pack's odds table.
function PlayerFactory.rollRarity(rng, odds): string
	local entries = {}
	for _, r in ipairs(Config.Rarities) do
		local p = odds[r.id] or 0
		if p > 0 and not r.locked then
			table.insert(entries, { r.id, p })
		end
	end
	return rng:weighted(entries)
end

-- Open a pack: returns the rolled cards' rarities, best last (so the reveal builds
-- up). The server turns each into an owned card with Catalog.draw (Catalog requires
-- this module, so it is passed in to avoid a require loop).
function PlayerFactory.rollPack(rng, packId: string)
	local pack = Config.Packs[packId]
	assert(pack, "unknown pack " .. tostring(packId))
	local rarities = {}
	local n = pack.count
	if pack.extraPlayerChance and rng:chance(pack.extraPlayerChance) then
		n += 1
	end
	for i = 1, n do
		rarities[i] = PlayerFactory.rollRarity(rng, pack.odds)
	end
	table.sort(rarities, function(a, b)
		return Config.RarityById[a].order < Config.RarityById[b].order
	end)
	return rarities
end

-- Returns cards (players or a coach, best last), badges and extra items.
function PlayerFactory.openPack(rng, packId: string, Catalog, Badges)
	local pack = Config.Packs[packId]
	local cards, badges, items = {}, {}, {}
	for i, r in ipairs(PlayerFactory.rollPack(rng, packId)) do
		cards[i] = Catalog.draw(rng, pack.kind == "coach" and "coach" or "player", r)
	end
	if pack.badges then
		for i = 1, rng:int(pack.badges[1], pack.badges[2]) do
			badges[i] = Badges.roll(rng, pack.badgeOdds)
		end
	end
	for i = 1, pack.items or 0 do
		local entries = {}
		for _, it in ipairs(Config.PackItems) do
			table.insert(entries, { it, it.weight })
		end
		local it = rng:weighted(entries)
		items[i] = { kind = "item", id = it.id }
		if it.id == "CoinPouch" then
			items[i].coins = math.floor(pack.coins * rng:range(0.10, 0.30) / 100 + 0.5) * 100
		end
	end
	return cards, badges, items
end

-- Price of a bundle of `size` packs, in coins or robux ("coins" | "robux").
function PlayerFactory.bundlePrice(packId: string, size: number, currency: string): number
	local pack = Config.Packs[packId]
	for _, b in ipairs(Config.Bundles) do
		if b.size == size then
			return math.floor(pack[currency] * size * (1 - b.discount) + 0.5)
		end
	end
	error("no bundle of size " .. tostring(size))
end

-- The free starting roster for a new club: a full matchday ten, one starter
-- per position, all Common so packs and training matter.
function PlayerFactory.starterRoster(seed: number)
	local rng = Rng.new(seed)
	local roster = {}
	local order = { "PG", "SG", "SF", "PF", "C", "PG", "SG", "SF", "PF", "C" }
	for i, pos in ipairs(order) do
		local ovr = i <= 5 and rng:int(58, 63) or rng:int(52, 58)
		table.insert(roster, PlayerFactory.generate(rng, { rarity = "Common", pos = pos, ovr = ovr, finish = false }))
	end
	return roster
end

return PlayerFactory
