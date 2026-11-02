--!nonstrict
-- Pure rules for redeem codes: cleaning up what players type, checking a code
-- can be used, reading admin chat commands, and describing rewards.
-- No Roblox services here, so it is covered by tests/run.luau.
--
-- A code definition ("def") looks like:
-- {
--   coins = 5000, fans = 100,
--   packs = { Pro = 1 },
--   boost = { kind = "DoubleCoins", minutes = 30 },
--   expires = 1798675199,      -- epoch seconds (UTC), optional
--   maxUses = 500,             -- total redemptions across all players, optional
--   newPlayersOnly = true,     -- only clubs made in the last 3 days, optional
--   disabled = true,           -- optional
-- }

local Config = require(script and script.Parent:FindFirstChild("Config") or "./Config")

local CodeRules = {}

CodeRules.NEW_PLAYER_SECONDS = 3 * 24 * 3600

CodeRules.Messages = {
	empty = "Type a code first.",
	invalid = "That code doesn't exist.",
	disabled = "That code has been turned off.",
	expired = "That code has expired.",
	already = "You already used that code.",
	newOnly = "That code is only for new clubs.",
	soldOut = "That code has run out of uses.",
	slowDown = "Too many tries. Wait a minute and try again.",
	busy = "Couldn't reach the code server. Try again in a moment.",
}

-- "  tip off! " -> "TIPOFF". Returns nil if nothing usable is left.
function CodeRules.normalize(raw: any): string?
	if type(raw) ~= "string" then
		return nil
	end
	local s = string.upper(raw):gsub("[^%w_%-]", "")
	if #s < 3 or #s > 24 then
		return nil
	end
	return s
end

-- Days since 1970-01-01 for a civil date (Howard Hinnant's algorithm).
local function daysFromCivil(y: number, m: number, d: number): number
	if m <= 2 then
		y -= 1
	end
	local era = (y >= 0 and y or y - 399) // 400
	local yoe = y - era * 400
	local mp = (m + 9) % 12
	local doy = (153 * mp + 2) // 5 + d - 1
	local doe = yoe * 365 + yoe // 4 - yoe // 100 + doy
	return era * 146097 + doe - 719468
end

-- "2026-12-31" -> epoch seconds for the END of that day (23:59:59 UTC).
function CodeRules.parseDate(s: any): number?
	if type(s) ~= "string" then
		return nil
	end
	local y, m, d = s:match("^(%d%d%d%d)%-(%d%d?)%-(%d%d?)$")
	y, m, d = tonumber(y), tonumber(m), tonumber(d)
	if not y or m < 1 or m > 12 or d < 1 or d > 31 then
		return nil
	end
	return daysFromCivil(y, m, d) * 86400 + 86399
end

-- Turn an entry from src/server/Codes.lua into a def. Returns def or nil, error.
function CodeRules.fromStatic(entry)
	if type(entry) ~= "table" then
		return nil, "entry must be a table"
	end
	local def = table.clone(entry)
	if type(entry.expires) == "string" then
		def.expires = CodeRules.parseDate(entry.expires)
		if not def.expires then
			return nil, "expires must look like 2026-12-31"
		end
	end
	local ok, err = CodeRules.validate(def)
	if not ok then
		return nil, err
	end
	return def
end

local function isWhole(n)
	return type(n) == "number" and n == math.floor(n) and n > 0
end

-- Make sure a def gives something real and nothing absurd.
function CodeRules.validate(def): (boolean, string?)
	local C = Config.Codes
	local gives = false
	if def.coins ~= nil then
		if not isWhole(def.coins) or def.coins > C.maxCoins then
			return false, "coins must be a whole number from 1 to " .. C.maxCoins
		end
		gives = true
	end
	if def.fans ~= nil then
		if not isWhole(def.fans) or def.fans > C.maxFans then
			return false, "fans must be a whole number from 1 to " .. C.maxFans
		end
		gives = true
	end
	if def.packs ~= nil then
		if type(def.packs) ~= "table" then
			return false, "packs must be a table like { Pro = 1 }"
		end
		for id, n in pairs(def.packs) do
			if not Config.Packs[id] then
				return false, "unknown pack '" .. tostring(id) .. "'"
			end
			if not isWhole(n) or n > C.maxPacksEach then
				return false, "pack amounts must be 1 to " .. C.maxPacksEach
			end
			gives = true
		end
	end
	if def.boost ~= nil then
		local b = def.boost
		if type(b) ~= "table" or not C.boostKinds[b.kind] then
			return false, "boost kind must be DoubleCoins or DoubleFans"
		end
		if not isWhole(b.minutes) or b.minutes > C.maxBoostMinutes then
			return false, "boost minutes must be 1 to " .. C.maxBoostMinutes
		end
		gives = true
	end
	if not gives then
		return false, "a code must give coins, fans, packs or a boost"
	end
	if def.maxUses ~= nil and not isWhole(def.maxUses) then
		return false, "maxUses must be a whole number"
	end
	if def.expires ~= nil and type(def.expires) ~= "number" then
		return false, "bad expiry"
	end
	return true
end

-- Can this player use this code right now? (Total-use limits are checked by the server.)
-- ctx: { now = number, alreadyRedeemed = bool, clubCreatedAt = number? }
function CodeRules.check(def, ctx): (boolean, string?)
	if def == nil then
		return false, "invalid"
	end
	if def.disabled then
		return false, "disabled"
	end
	if def.expires and ctx.now > def.expires then
		return false, "expired"
	end
	if ctx.alreadyRedeemed then
		return false, "already"
	end
	if def.newPlayersOnly then
		local created = ctx.clubCreatedAt or 0
		if ctx.now - created > CodeRules.NEW_PLAYER_SECONDS then
			return false, "newOnly"
		end
	end
	return true
end

local function commas(n: number): string
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end
CodeRules.commas = commas

-- "5,000 coins + 1 Pro Pack + 30 min Double Coins"
function CodeRules.describe(def): string
	local parts = {}
	if def.coins then
		table.insert(parts, commas(def.coins) .. " coins")
	end
	if def.fans then
		table.insert(parts, commas(def.fans) .. " fans")
	end
	if def.packs then
		local ids = {}
		for id in pairs(def.packs) do
			table.insert(ids, id)
		end
		table.sort(ids)
		for _, id in ipairs(ids) do
			local n = def.packs[id]
			local name = Config.Packs[id] and Config.Packs[id].name or id
			table.insert(parts, n .. " " .. name .. (n > 1 and "s" or ""))
		end
	end
	if def.boost then
		local label = def.boost.kind == "DoubleCoins" and "Double Coins" or "Double Fans"
		table.insert(parts, def.boost.minutes .. " min " .. label)
	end
	return table.concat(parts, " + ")
end

local function splitWords(text: string)
	local words = {}
	for w in text:gmatch("%S+") do
		table.insert(words, w)
	end
	return words
end

-- Admin chat commands. Returns nil if the text isn't a code command.
--   !makecode NAME coins=5000 fans=100 pack=Pro:2 boost=DoubleCoins:30 uses=500 days=7 until=2026-12-31 new=yes
--   !delcode NAME
--   !codes
--   !codehelp
-- Result: { cmd = "make"|"delete"|"list"|"help", code = "NAME", def = {...} } or { cmd = "error", err = "..." }
function CodeRules.parseCommand(text: string, now: number)
	if type(text) ~= "string" then
		return nil
	end
	local words = splitWords(text)
	local head = words[1] and string.lower(words[1])
	if head == "!codes" then
		return { cmd = "list" }
	elseif head == "!codehelp" then
		return { cmd = "help" }
	elseif head == "!delcode" then
		local code = CodeRules.normalize(words[2])
		if not code then
			return { cmd = "error", err = "Usage: !delcode NAME" }
		end
		return { cmd = "delete", code = code }
	elseif head ~= "!makecode" then
		return nil
	end

	local code = CodeRules.normalize(words[2])
	if not code or (words[2] and words[2]:find("=")) then
		return { cmd = "error", err = "Usage: !makecode NAME coins=5000 pack=Pro:1 days=7" }
	end
	local def = {}
	for i = 3, #words do
		local key, value = words[i]:match("^(%a+)=(.+)$")
		key = key and string.lower(key)
		if not key then
			return { cmd = "error", err = "Can't read '" .. words[i] .. "'. Use key=value." }
		end
		if key == "coins" or key == "fans" or key == "uses" or key == "days" or key == "hours" then
			local n = tonumber(value)
			if not n then
				return { cmd = "error", err = key .. " needs a number" }
			end
			if key == "coins" then
				def.coins = n
			elseif key == "fans" then
				def.fans = n
			elseif key == "uses" then
				def.maxUses = n
			elseif key == "days" then
				def.expires = now + math.floor(n * 86400)
			else
				def.expires = now + math.floor(n * 3600)
			end
		elseif key == "pack" then
			local id, n = value:match("^(%w+):?(%d*)$")
			if not id then
				return { cmd = "error", err = "pack looks like pack=Pro or pack=Pro:2" }
			end
			-- accept any capitalisation: allstar -> AllStar
			local found
			for packId in pairs(Config.Packs) do
				if string.lower(packId) == string.lower(id) then
					found = packId
				end
			end
			if not found then
				return { cmd = "error", err = "Unknown pack '" .. id .. "'" }
			end
			def.packs = def.packs or {}
			def.packs[found] = (def.packs[found] or 0) + (tonumber(n) or 1)
		elseif key == "boost" then
			local kind, mins = value:match("^(%a+):(%d+)$")
			local kinds = { doublecoins = "DoubleCoins", doublefans = "DoubleFans" }
			kind = kind and kinds[string.lower(kind)]
			if not kind then
				return { cmd = "error", err = "boost looks like boost=DoubleCoins:30" }
			end
			def.boost = { kind = kind, minutes = tonumber(mins) }
		elseif key == "until" then
			def.expires = CodeRules.parseDate(value)
			if not def.expires then
				return { cmd = "error", err = "until looks like until=2026-12-31" }
			end
		elseif key == "new" then
			def.newPlayersOnly = (string.lower(value) == "yes" or string.lower(value) == "true")
		else
			return { cmd = "error", err = "Unknown option '" .. key .. "'" }
		end
	end
	local ok, err = CodeRules.validate(def)
	if not ok then
		return { cmd = "error", err = err }
	end
	return { cmd = "make", code = code, def = def }
end

return CodeRules
