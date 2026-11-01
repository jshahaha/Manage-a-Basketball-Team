--!nonstrict
-- The fixed card list: every player and coach that exists in the game right now.
-- Packs draw from this list, so the shop can show exactly what a pack can give.
-- It is generated from a fixed seed, so every server builds the same list.
-- To add a hand-made card later (for example a Hall of Fame legend), append it to
-- Catalog.Extra with a new id.

local function load(name)
	return require(script and script.Parent:FindFirstChild(name) or ("./" .. name))
end
local Config = load("Config")
local Rng = load("Rng")
local Names = load("Names")
local PlayerFactory = load("PlayerFactory")

local Catalog = {}

Catalog.Seed = 20261101
-- How many different cards of each rarity exist.
Catalog.PlayerCounts = { Common = 80, Rare = 60, Epic = 40, Legendary = 24, HallOfFame = 12 }
Catalog.CoachCounts = { Common = 8, Rare = 8, Epic = 6, Legendary = 4, HallOfFame = 2 }
Catalog.Extra = {}

local players, coaches, byId = nil, nil, {}

local function build()
	local rng = Rng.new(Catalog.Seed)
	players, coaches = {}, {}
	local used = {}
	local function uniqueName(make)
		for _ = 1, 50 do
			local n = make()
			if not used[n] then
				used[n] = true
				return n
			end
		end
		error("ran out of unique names")
	end
	for _, r in ipairs(Config.Rarities) do
		for i = 1, Catalog.PlayerCounts[r.id] or 0 do
			local pos = Config.Positions[(i - 1) % #Config.Positions + 1]
			local p = PlayerFactory.generate(rng, {
				rarity = r.id,
				pos = pos,
				finish = false,
				id = string.format("P%s%03d", r.id:sub(1, 2):upper(), i),
				name = uniqueName(function()
					return Names.player(rng, r.id)
				end),
			})
			p.career = nil -- a catalog entry is a template, not an owned card
			table.insert(players, p)
			byId[p.id] = p
		end
	end
	local offense, defense = Config.OffenseStyles, Config.DefenseStyles
	for _, r in ipairs(Config.Rarities) do
		local info = Config.CoachRarity[r.id]
		for i = 1, Catalog.CoachCounts[r.id] or 0 do
			local side = i % 2 == 1 and "Offense" or "Defense"
			local pool = side == "Offense" and offense or defense
			local styles = {}
			local start = rng:int(1, #pool)
			for k = 0, math.min(info.styles, #pool) - 1 do
				table.insert(styles, pool[(start + k - 1) % #pool + 1])
			end
			local c = {
				id = string.format("C%s%02d", r.id:sub(1, 2):upper(), i),
				kind = "coach",
				side = side,
				rarity = r.id,
				name = uniqueName(function()
					return Names.coach(rng)
				end),
				styles = styles,
			}
			table.insert(coaches, c)
			byId[c.id] = c
		end
	end
	for _, e in ipairs(Catalog.Extra) do
		table.insert(e.kind == "coach" and coaches or players, e)
		byId[e.id] = e
	end
end

function Catalog.players()
	if not players then
		build()
	end
	return players
end

function Catalog.coaches()
	if not coaches then
		build()
	end
	return coaches
end

function Catalog.get(id: string)
	if not players then
		build()
	end
	return byId[id]
end

-- Every card a pack can give, best first, with the chance of each per card slot.
function Catalog.packContents(packId: string)
	local pack = Config.Packs[packId]
	assert(pack, "unknown pack " .. tostring(packId))
	local list = pack.kind == "coach" and Catalog.coaches() or Catalog.players()
	local count = {}
	for _, c in ipairs(list) do
		count[c.rarity] = (count[c.rarity] or 0) + 1
	end
	local out = {}
	for _, c in ipairs(list) do
		local p = pack.odds[c.rarity]
		if p and p > 0 then
			table.insert(out, { card = c, chance = p / count[c.rarity] })
		end
	end
	table.sort(out, function(a, b)
		local ra, rb = Config.RarityById[a.card.rarity].order, Config.RarityById[b.card.rarity].order
		if ra ~= rb then
			return ra > rb
		end
		return a.card.id < b.card.id
	end)
	return out
end

-- Pick one card of a rarity from the list (uniform within the rarity).
function Catalog.draw(rng, kind: string, rarity: string)
	local list = kind == "coach" and Catalog.coaches() or Catalog.players()
	local pool = {}
	for _, c in ipairs(list) do
		if c.rarity == rarity then
			table.insert(pool, c)
		end
	end
	assert(#pool > 0, "no " .. rarity .. " " .. kind .. " cards")
	return rng:pick(pool)
end

return Catalog
