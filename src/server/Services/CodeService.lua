--!nonstrict
-- Redeem codes. Two sources:
--   1. src/server/Codes.lua: edit it and publish.
--   2. Live codes: admins type !makecode in chat. They're stored in a DataStore and
--      reach every server within seconds through MessagingService, with no publish needed.
-- A live code with the same name replaces the one in Codes.lua.

local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local CodeRules = require(Shared.CodeRules)

local ServerRoot = script.Parent.Parent
local StaticCodes = require(ServerRoot.Codes)
local Admins = require(ServerRoot.Admins)
local DataService = require(script.Parent.DataService)

local CodeService = {}

local TOPIC = "CodesChanged"
local INDEX_KEY = "index"

local static = {} -- [CODE] = def
local live = {} -- [CODE] = def
local tries = {} -- [Player] = { times }

local store
pcall(function()
	store = DataStoreService:GetDataStore("LiveCodes_v1")
end)

-- Load Codes.lua once. A bad entry is skipped with a warning instead of breaking the game.
for name, entry in pairs(StaticCodes) do
	local code = CodeRules.normalize(name)
	local def, err = CodeRules.fromStatic(entry)
	if code ~= name then
		warn("[Codes] skipped '" .. tostring(name) .. "': names must be CAPITALS, letters/numbers/_/-")
	elseif not def then
		warn("[Codes] skipped " .. name .. ": " .. err)
	else
		static[code] = def
	end
end

local function refreshLive()
	if not store then
		return
	end
	local ok, data = pcall(function()
		return store:GetAsync(INDEX_KEY)
	end)
	if ok then
		live = data or {}
	end
end

local function find(code: string)
	return live[code] or static[code]
end

local function tooManyTries(player: Player): boolean
	local now = os.clock()
	local list = tries[player] or {}
	local fresh = {}
	for _, t in ipairs(list) do
		if now - t < 60 then
			table.insert(fresh, t)
		end
	end
	if #fresh >= Config.Codes.triesPerMinute then
		tries[player] = fresh
		return true
	end
	table.insert(fresh, now)
	tries[player] = fresh
	return false
end

-- Atomically take one of a code's limited uses. Returns true if one was free.
local function claimUse(code: string, maxUses: number): (boolean, string?)
	if not store then
		return true -- Studio without API access: no global limit
	end
	local got = false
	local ok = pcall(function()
		store:UpdateAsync("uses_" .. code, function(n)
			n = n or 0
			if n >= maxUses then
				got = false
				return nil
			end
			got = true
			return n + 1
		end)
	end)
	if not ok then
		return false, "busy"
	end
	return got, got and nil or "soldOut"
end

-- Route handler: payload is the text the player typed.
function CodeService.redeem(player: Player, profile, raw)
	if tooManyTries(player) then
		return false, CodeRules.Messages.slowDown
	end
	local code = CodeRules.normalize(raw)
	if not code then
		return false, CodeRules.Messages[raw == nil or raw == "" and "empty" or "invalid"]
	end
	local def = find(code)
	local ok, reason = CodeRules.check(def, {
		now = os.time(),
		alreadyRedeemed = profile.redeemedCodes[code] ~= nil,
		clubCreatedAt = profile.createdAt,
	})
	if not ok then
		return false, CodeRules.Messages[reason]
	end
	if def.maxUses then
		local got, why = claimUse(code, def.maxUses)
		if not got then
			return false, CodeRules.Messages[why]
		end
	end
	profile.redeemedCodes[code] = os.time()
	DataService.grant(profile, def)
	task.spawn(DataService.save, player)
	return true, { code = code, message = "Redeemed! You got " .. CodeRules.describe(def) .. "." }
end

-- Admin chat commands ----------------------------------------------------------

local function reply(player: Player, text: string)
	local push = require(Shared.Net).push()
	push:FireClient(player, "notice", { text = text })
end

local function saveLive(mutator): (boolean, string?)
	if not store then
		mutator(live)
		return true -- Studio without API access: live codes work in this server only
	end
	local ok, err = pcall(function()
		store:UpdateAsync(INDEX_KEY, function(index)
			index = index or {}
			mutator(index)
			live = index
			return index
		end)
	end)
	if not ok then
		return false, tostring(err)
	end
	pcall(function()
		MessagingService:PublishAsync(TOPIC, os.time())
	end)
	return true
end

local HELP = table.concat({
	"!makecode NAME coins=5000 fans=100 pack=Pro:2 boost=DoubleCoins:30",
	"   options: uses=500  days=7  hours=12  until=2026-12-31  new=yes",
	"!delcode NAME   !codes   !codehelp",
	"Packs: Rookie, Blacktop, Pro, AllStar, HallOfFame, Coach, EliteCoach",
}, "\n")

local function onChat(player: Player, text: string)
	local cmd = CodeRules.parseCommand(text, os.time())
	if not cmd then
		return
	end
	if not Admins.isAdmin(player) then
		return -- non-admins typing !codes just chat normally
	end
	if cmd.cmd == "error" then
		reply(player, "⚠ " .. cmd.err)
	elseif cmd.cmd == "help" then
		reply(player, HELP)
	elseif cmd.cmd == "list" then
		refreshLive()
		local lines = {}
		for code, def in pairs(live) do
			table.insert(lines, code .. " (live): " .. CodeRules.describe(def))
		end
		for code, def in pairs(static) do
			if not live[code] then
				table.insert(lines, code .. ": " .. CodeRules.describe(def))
			end
		end
		table.sort(lines)
		reply(player, #lines > 0 and table.concat(lines, "\n") or "No codes yet.")
	elseif cmd.cmd == "make" then
		cmd.def.createdBy = player.UserId
		cmd.def.createdAt = os.time()
		local ok, err = saveLive(function(index)
			index[cmd.code] = cmd.def
		end)
		reply(player, ok and ("✓ Code " .. cmd.code .. " is live: " .. CodeRules.describe(cmd.def)) or ("⚠ Couldn't save: " .. err))
	elseif cmd.cmd == "delete" then
		if not live[cmd.code] and static[cmd.code] then
			reply(player, cmd.code .. " is in Codes.lua. To turn it off, remove it there or add disabled = true, then publish.")
			return
		end
		local ok, err = saveLive(function(index)
			index[cmd.code] = nil
		end)
		reply(player, ok and ("✓ Deleted " .. cmd.code) or ("⚠ Couldn't save: " .. err))
	end
end

function CodeService.start()
	refreshLive()
	pcall(function()
		MessagingService:SubscribeAsync(TOPIC, refreshLive)
	end)
	task.spawn(function()
		while true do
			task.wait(Config.Codes.refreshSeconds)
			refreshLive()
		end
	end)
	local function hook(player: Player)
		player.Chatted:Connect(function(msg)
			onChat(player, msg)
		end)
	end
	Players.PlayerAdded:Connect(hook)
	for _, p in ipairs(Players:GetPlayers()) do
		hook(p)
	end
	Players.PlayerRemoving:Connect(function(player)
		tries[player] = nil
	end)
end

return CodeService
