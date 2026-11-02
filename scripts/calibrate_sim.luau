-- Match engine calibration: average score, shooting splits and win rates over many games.
-- Run from the repo root: luau scripts/calibrate_sim.luau
local MatchSim = require("../src/shared/MatchSim")
local PlayerFactory = require("../src/shared/PlayerFactory")
local Rng = require("../src/shared/Rng")
local Stats = require("../src/shared/Stats")
local rng = Rng.new(7)
local function team(seed, lo, hi)
	local rr = Rng.new(seed)
	local order = { "PG", "SG", "SF", "PF", "C", "PG", "SG", "SF", "PF", "C" }
	local t = {}
	for i, pos in ipairs(order) do
		t[i] = PlayerFactory.generate(rr, { rarity = "Common", pos = pos, ovr = i <= 5 and rr:int(lo, hi) or rr:int(lo - 6, hi - 6), finish = false })
	end
	return { players = t }
end
local N = 400
local hp, ap, hw, ot, poss = 0, 0, 0, 0, 0
local tot = Stats.newLine()
for g = 1, N do
	local res = MatchSim.play(rng, team(g, 60, 66), team(g + 1000, 60, 66))
	hp += res.score[1]; ap += res.score[2]
	if res.winner == 1 then hw += 1 end
	if #res.quarters > 4 then ot += 1 end
	poss += #res.events
	for _, l in pairs(res.box.home) do Stats.addLine(tot, l) end
end
print(string.format("even: home %.1f away %.1f homeWin %.2f OT %.2f events/game %.0f", hp / N, ap / N, hw / N, ot / N, poss / N))
print(string.format("FG%% %.1f 3P%% %.1f 3PA %.1f FT%% %.1f FTA %.1f TOV %.1f AST %.1f OREB %.1f DREB %.1f BLK %.1f STL %.1f",
	tot.fgm / tot.fga * 100, tot.tpm / tot.tpa * 100, tot.tpa / N, tot.ftm / tot.fta * 100, tot.fta / N, tot.tov / N, tot.ast / N, tot.oreb / N, tot.dreb / N, tot.blk / N, tot.stl / N))
local sw = 0
for g = 1, N do
	local res = MatchSim.play(rng, team(g, 74, 80), team(g + 1000, 60, 66))
	if res.winner == 1 then sw += 1 end
end
print(string.format("strong (+14 OVR) home win %.2f", sw / N))
sw = 0
for g = 1, N do
	local res = MatchSim.play(rng, team(g, 64, 70), team(g + 1000, 60, 66))
	if res.winner == 1 then sw += 1 end
end
print(string.format("+4 OVR home win %.2f", sw / N))
