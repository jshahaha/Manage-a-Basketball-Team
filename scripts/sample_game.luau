-- Plays one game with the match engine and prints it as JSON (for previews).
-- Run from the repo root: luau scripts/sample_game.luau
local MatchSim = require("../src/shared/MatchSim")
local PlayerFactory = require("../src/shared/PlayerFactory")
local Rng = require("../src/shared/Rng")

local function json(v)
	local t = type(v)
	if t == "table" then
		if #v > 0 or next(v) == nil then
			local out = {}
			for i, x in ipairs(v) do
				out[i] = json(x)
			end
			return "[" .. table.concat(out, ",") .. "]"
		end
		local out = {}
		for k, x in pairs(v) do
			table.insert(out, string.format("%q:%s", tostring(k), json(x)))
		end
		return "{" .. table.concat(out, ",") .. "}"
	elseif t == "string" then
		return string.format("%q", v)
	elseif t == "boolean" or t == "number" then
		return tostring(v)
	end
	return "null"
end

local rng = Rng.new(tonumber((...)) or 42)
local function team(seed, ovr)
	local rr = Rng.new(seed)
	local t = {}
	for i, pos in ipairs({ "PG", "SG", "SF", "PF", "C", "PG", "SG", "SF", "PF", "C" }) do
		t[i] = PlayerFactory.generate(rr, { rarity = "Common", pos = pos, ovr = i <= 5 and ovr + rr:int(-2, 2) or ovr - 6, finish = false })
	end
	return { players = t }
end
local home, away = team(3, 64), team(9, 63)
local res = MatchSim.play(rng, home, away)
local function roster(t, box)
	local out = {}
	for i, p in ipairs(t.players) do
		out[i] = { name = p.name, pos = p.pos, ovr = PlayerFactory.overall(p), box = box[p.id], id = p.id }
	end
	return out
end
print(json({ home = roster(home, res.box.home), away = roster(away, res.box.away), quarters = res.quarters, score = res.score, events = res.events, mvp = res.mvp }))
