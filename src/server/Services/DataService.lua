--!nonstrict
-- Loads, caches and saves player profiles. Autosaves every 2 minutes, and saves
-- when a player leaves or the server shuts down. A session lock stops two
-- servers from writing the same profile at once.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local PlayerFactory = require(Shared.PlayerFactory)
local Stats = require(Shared.Stats)

local DataService = {}
DataService.profiles = {} -- [Player] = profile
DataService.Loaded = Instance.new("BindableEvent") -- (player, profile)

local LOCK_TIMEOUT = 15 * 60 -- a lock older than this is from a crashed server

local store
do
	local ok = pcall(function()
		store = DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if not ok then
		store = nil
		warn("[Court] DataStore unavailable. Turn on 'Enable Studio Access to API Services' to save in Studio.")
	end
end

local function deepCopy(t)
	if type(t) ~= "table" then
		return t
	end
	local c = {}
	for k, v in pairs(t) do
		c[k] = deepCopy(v)
	end
	return c
end
DataService.deepCopy = deepCopy

function DataService.newProfile(userId: number)
	local roster = PlayerFactory.starterRoster(userId)
	local matchday = {}
	for _, p in ipairs(roster) do
		table.insert(matchday, p.id)
	end
	return {
		version = Config.DataVersion,
		createdAt = os.time(),
		club = nil, -- set by club creation: { name, badge, colors }
		coins = Config.StartingCoins,
		fans = Config.StartingFans,
		elo = { elo = Config.Elo.start, games = 0, tier = 1, shield = 0 },
		players = roster,
		matchday = matchday, -- 10 player ids, first 5 start
		minutes = {}, -- [playerId] = minutes
		coaches = {},
		packs = {}, -- unopened: [packId] = count
		boosts = {}, -- [kind] = expires (epoch)
		redeemedCodes = {}, -- [CODE] = epoch
		quests = nil, -- see Quests.lua
		stats = {}, -- lifetime stats for achievements
		achievements = {}, -- [id] = tiers claimed
		teamStats = Stats.newTeam(),
		streak = 0,
	}
end

-- Fill in fields added after a profile was first saved.
local function reconcile(data, userId)
	local def = DataService.newProfile(userId)
	for k, v in pairs(def) do
		if data[k] == nil then
			data[k] = v
		end
	end
	return data
end

local function retry(fn)
	local lastErr
	for attempt = 1, 4 do
		local ok, res = pcall(fn)
		if ok then
			return true, res
		end
		lastErr = res
		task.wait(attempt)
	end
	return false, lastErr
end

local function key(player: Player): string
	return "u_" .. player.UserId
end

function DataService.load(player: Player)
	local data
	if store then
		local lockedElsewhere = false
		local ok, err = retry(function()
			store:UpdateAsync(key(player), function(old)
				old = old or {}
				local lock = old.lock
				if lock and lock.job ~= game.JobId and os.time() - lock.at < LOCK_TIMEOUT then
					lockedElsewhere = true
					return nil -- don't write
				end
				old.lock = { job = game.JobId, at = os.time() }
				data = old.profile
				return old
			end)
		end)
		if not ok then
			warn("[Court] load failed", player.Name, err)
			player:Kick("Couldn't load your club. Please rejoin.")
			return nil
		end
		if lockedElsewhere then
			player:Kick("Your club is still open in another server. Wait a moment and rejoin.")
			return nil
		end
	end
	data = reconcile(data or DataService.newProfile(player.UserId), player.UserId)
	if player.Parent ~= Players then
		DataService.save(player, true, data)
		return nil
	end
	DataService.profiles[player] = data
	DataService.Loaded:Fire(player, data)
	return data
end

-- release = true also removes the session lock.
function DataService.save(player: Player, release: boolean?, dataOverride)
	local data = dataOverride or DataService.profiles[player]
	if not data or not store then
		return
	end
	data.savedAt = os.time()
	local ok, err = retry(function()
		store:UpdateAsync(key(player), function(old)
			old = old or {}
			if old.lock and old.lock.job ~= game.JobId then
				return nil -- another server owns it now; don't overwrite
			end
			old.profile = data
			old.lock = (not release) and { job = game.JobId, at = os.time() } or nil
			return old
		end)
	end)
	if not ok then
		warn("[Court] save failed", player.Name, err)
	end
end

function DataService.get(player: Player)
	return DataService.profiles[player]
end

-- Give rewards (from codes, quests, achievements). Never takes away.
-- rewards: { coins, fans, packs = { Pro = 1 }, pack = "Pro", boost = { kind, minutes } }
function DataService.grant(profile, rewards)
	if rewards.coins then
		profile.coins = math.min(Config.MaxCoins, profile.coins + rewards.coins)
	end
	if rewards.fans then
		profile.fans += rewards.fans
	end
	local packs = rewards.packs or {}
	if rewards.pack then
		packs = table.clone(packs)
		packs[rewards.pack] = (packs[rewards.pack] or 0) + 1
	end
	for id, n in pairs(packs) do
		profile.packs[id] = (profile.packs[id] or 0) + n
	end
	if rewards.boost then
		local now = os.time()
		local current = math.max(profile.boosts[rewards.boost.kind] or 0, now)
		profile.boosts[rewards.boost.kind] = current + rewards.boost.minutes * 60
	end
end

function DataService.start()
	Players.PlayerRemoving:Connect(function(player)
		DataService.save(player, true)
		DataService.profiles[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(120)
			for player in pairs(DataService.profiles) do
				task.spawn(DataService.save, player)
			end
		end
	end)
	game:BindToClose(function()
		if not store then
			return
		end
		local pending = 0
		for player in pairs(DataService.profiles) do
			pending += 1
			task.spawn(function()
				DataService.save(player, true)
				pending -= 1
			end)
		end
		local t = os.clock()
		while pending > 0 and os.clock() - t < 25 do
			task.wait(0.2)
		end
	end)
end

return DataService
