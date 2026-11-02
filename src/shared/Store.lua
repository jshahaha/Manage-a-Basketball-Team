--!nonstrict
-- Buying and opening packs. Pure functions on a profile table, so the server runs them and the
-- tests check them without Roblox.
--
--   local ok, err = Store.buy(profile, "Pro", 5)          -- 5x bundle for coins, kept as one item
--   local ok, result = Store.open(profile, "Pro x5", rng) -- opens every pack in the item
--   result.packs[i] = { pack, cards, badges, items }; everything is already added to the profile

local function import(name)
	return require(script and script.Parent:FindFirstChild(name) or "./" .. name)
end
local Config = import("Config")
local Inventory = import("Inventory")
local PlayerFactory = import("PlayerFactory")
local Catalog = import("Catalog")
local Badges = import("Badges")
local AnimSets = import("AnimSets")
local Ratings = import("Ratings")
local Stats = import("Stats")

local Store = {}

Store.MaxPlayers = 60 -- squad cap; packs still open, extra cards can be released later

function Store.price(packId: string, size: number): number
	return PlayerFactory.bundlePrice(packId, size, "coins")
end

-- Buy `size` packs (1, 5 or 20) with coins. Returns ok, error text.
function Store.buy(profile, packId: string, size: number?)
	size = size or 1
	local pack = Config.Packs[packId]
	if not pack then
		return false, "That pack isn't in the shop."
	end
	local okSize = false
	for _, b in ipairs(Config.Bundles) do
		if b.size == size then
			okSize = true
		end
	end
	if not okSize then
		return false, "That bundle size isn't sold."
	end
	local cost = Store.price(packId, size)
	if (profile.coins or 0) < cost then
		return false, "Not enough coins."
	end
	profile.coins -= cost
	local key = Inventory.add(profile, packId, size)
	return true, { key = key, cost = cost }
end

-- A catalog card becomes a player the club owns: a copy with its own id, a fresh career and
-- the club's name on it. Signature moves come with the card (rolled again for old templates).
local function own(profile, card, rng)
	local p = table.clone(card)
	p.ratings = table.clone(card.ratings)
	p.altPos = table.clone(card.altPos or {})
	p.id = string.format("%s-%08x", card.id, rng:int(0, 0x7fffffff))
	p.templateId = card.id
	p.career = Stats.newCareer()
	p.club = profile.club and profile.club.name or nil
	p.anims = card.anims and table.clone(card.anims) or AnimSets.roll(rng, card.rarity, Ratings.archetype(card.ratings))
	return p
end

local function applyItem(profile, it)
	if it.id == "CoinPouch" then
		profile.coins = math.min(Config.MaxCoins or math.huge, profile.coins + (it.coins or 0))
	elseif it.id == "Cosmetic" and it.cosmetic then
		profile.cosmetics = profile.cosmetics or {}
		it.duplicate = profile.cosmetics[it.cosmetic] == true or nil
		profile.cosmetics[it.cosmetic] = true
	elseif it.id == "ScoutTicket" then
		profile.scoutTickets = (profile.scoutTickets or 0) + 1
	elseif it.id == "BadgeUpgrade" then
		profile.items = profile.items or {}
		local k = "BadgeUpgrade/" .. tostring(it.from)
		profile.items[k] = (profile.items[k] or 0) + 1
	end
end

-- Open one inventory item (a pack or a whole bundle). Returns ok, result | error text.
function Store.open(profile, key: string, rng)
	local packId, count = Inventory.take(profile, key)
	if not packId then
		return false, "You don't have that pack."
	end
	if not Config.Packs[packId] then
		return false, "Unknown pack."
	end
	local result = { key = key, pack = packId, packs = {} }
	for _ = 1, count do
		local cards, badges, items = PlayerFactory.openPack(rng, packId, Catalog, Badges)
		local owned = {}
		for i, card in ipairs(cards) do
			if card.kind == "coach" then
				profile.coaches = profile.coaches or {}
				local c = table.clone(card)
				c.templateId = card.id
				c.id = string.format("%s-%08x", card.id, rng:int(0, 0x7fffffff))
				table.insert(profile.coaches, c)
				owned[i] = c
			else
				local p = own(profile, card, rng)
				table.insert(profile.players, p)
				owned[i] = p
			end
		end
		for _, b in ipairs(badges) do
			Inventory.addBadge(profile, b.badge or b.id, b.tier)
		end
		for _, it in ipairs(items) do
			applyItem(profile, it)
		end
		table.insert(result.packs, { pack = packId, cards = owned, badges = badges, items = items })
	end
	return true, result
end

-- What the client needs to draw a card (no career history, no hidden data).
function Store.cardView(p)
	if p.kind == "coach" then
		return { id = p.id, kind = "coach", name = p.name, rarity = p.rarity, side = p.side, styles = p.styles }
	end
	return {
		id = p.id,
		kind = "player",
		name = p.name,
		pos = p.pos,
		altPos = p.altPos,
		rarity = p.rarity,
		ovr = PlayerFactory.overall(p),
		height = p.height,
		wingspan = p.wingspan,
		weight = p.weight,
		nation = p.nation,
		archetype = PlayerFactory.archetype(p),
		faceSeed = p.faceSeed,
		anims = p.anims,
	}
end

return Store
