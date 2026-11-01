--!nonstrict
-- Server entry point: starts services and routes client requests.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Elo = require(Shared.Elo)

local Services = script.Parent:WaitForChild("Services")
local DataService = require(Services.DataService)
local CodeService = require(Services.CodeService)
local ProgressService = require(Services.ProgressService)

-- Route table: action -> handler(player, profile, payload) -> ok, data | error message
local routes = {}

function routes.getProfile(player, profile)
	local tier = Elo.tier(profile.elo.elo)
	return true, {
		coins = profile.coins,
		fans = profile.fans,
		elo = profile.elo.elo,
		tier = tier.id,
		packs = profile.packs,
		boosts = profile.boosts,
		playerCount = #profile.players,
	}
end

routes.redeemCode = CodeService.redeem

for name, fn in pairs(ProgressService.handlers) do
	assert(routes[name] == nil, "duplicate route " .. name)
	routes[name] = fn
end

local lastCall = {}
local MIN_INTERVAL = 0.1

Net.request().OnServerInvoke = function(player, action, payload)
	if type(action) ~= "string" or not routes[action] then
		return { ok = false, err = "Unknown action." }
	end
	local now = os.clock()
	if lastCall[player] and now - lastCall[player] < MIN_INTERVAL then
		return { ok = false, err = "Slow down!" }
	end
	lastCall[player] = now

	local profile = DataService.get(player)
	if not profile then
		return { ok = false, err = "Still loading your club..." }
	end
	local ran, success, data = pcall(routes[action], player, profile, payload)
	if not ran then
		warn("[Court] handler error", action, success)
		return { ok = false, err = "Something went wrong." }
	end
	if success then
		return { ok = true, data = data }
	end
	return { ok = false, err = data }
end

DataService.start()
CodeService.start()

local function onPlayer(player)
	DataService.load(player)
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayer, p)
end
Players.PlayerRemoving:Connect(function(player)
	lastCall[player] = nil
end)
