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
	return {
		id = id,
		name = opts.name or Names.player(rng, rarity.id),
		pos = pos,
		rarity = rarity.id,
		finish = finish or nil,
		ratings = ratings,
		potential = math.min(Ratings.MAX, base + rng:int(2, 12)),
		height = height,
		wingspan = height + rng:int(0, 6),
		stars = 1,
		faceSeed = id, -- the icon generator draws the face from this
		career = Stats.newCareer(),
	}
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
	return math.min(Ratings.MAX, Ratings.ovr(player.ratings, player.pos) + PlayerFactory.finishBonus(player))
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
		if p > 0 then
			table.insert(entries, { r.id, p })
		end
	end
	return rng:weighted(entries)
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
