--!nonstrict
-- Shop, pack inventory and the club's roster: the routes behind the lobby screens.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Inventory = require(Shared.Inventory)
local Rng = require(Shared.Rng)
local Store = require(Shared.Store)

local DataService = require(script.Parent.DataService)
local ProgressService = require(script.Parent.ProgressService)

local ClubService = {}
ClubService.handlers = {}
local H = ClubService.handlers

local rng = Rng.new(os.time())

-- Shop shelf: every pack with its 1x / 5x / 20x coin prices.
function H.getShop(player, profile)
	local packs = {}
	for id, p in pairs(Config.Packs) do
		local prices = {}
		for _, b in ipairs(Config.Bundles) do
			table.insert(prices, { size = b.size, coins = Store.price(id, b.size), discount = b.discount })
		end
		table.insert(packs, { id = id, name = p.name, kind = p.kind, order = p.order, odds = p.odds, prices = prices })
	end
	table.sort(packs, function(a, b)
		return a.order < b.order
	end)
	return true, { packs = packs, coins = profile.coins }
end

function H.buyPack(player, profile, payload)
	if type(payload) ~= "table" or type(payload.pack) ~= "string" then
		return false, "Pick a pack."
	end
	local size = tonumber(payload.size) or 1
	local ok, res = Store.buy(profile, payload.pack, size)
	if not ok then
		return false, res
	end
	return true, { key = res.key, coins = profile.coins }
end

function H.getInventory(player, profile)
	local list = Inventory.list(profile)
	for _, it in ipairs(list) do
		local p = Config.Packs[it.pack]
		it.name = p and p.name or it.pack
	end
	return true, { items = list }
end

function H.openPack(player, profile, key)
	if type(key) ~= "string" then
		return false, "Pick a pack to open."
	end
	local ok, res = Store.open(profile, key, rng)
	if not ok then
		return false, res
	end
	local view = { pack = res.pack, packs = {} }
	for _, pk in ipairs(res.packs) do
		local cards = {}
		for i, c in ipairs(pk.cards) do
			cards[i] = Store.cardView(c)
		end
		table.insert(view.packs, { cards = cards, badges = pk.badges, items = pk.items })
		ProgressService.record(player, "packsOpened", 1)
	end
	view.coins = profile.coins
	return true, view
end

-- Roster: every player with the matchday ten marked (first five start).
function H.getRoster(player, profile)
	local slot = {}
	for i, id in ipairs(profile.matchday or {}) do
		slot[id] = i
	end
	local players = {}
	for _, p in ipairs(profile.players) do
		local v = Store.cardView(p)
		v.slot = slot[p.id]
		table.insert(players, v)
	end
	table.sort(players, function(a, b)
		if (a.slot or 99) ~= (b.slot or 99) then
			return (a.slot or 99) < (b.slot or 99)
		end
		return a.ovr > b.ovr
	end)
	return true, { players = players }
end

-- Set the matchday ten: an array of 10 distinct owned player ids, starters first.
function H.setMatchday(player, profile, ids)
	if type(ids) ~= "table" or #ids ~= 10 then
		return false, "Pick 10 players."
	end
	local owned, seen = {}, {}
	for _, p in ipairs(profile.players) do
		owned[p.id] = true
	end
	for _, id in ipairs(ids) do
		if type(id) ~= "string" or not owned[id] or seen[id] then
			return false, "That lineup isn't valid."
		end
		seen[id] = true
	end
	profile.matchday = table.clone(ids)
	return true, { matchday = profile.matchday }
end

return ClubService
