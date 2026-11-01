-- Tests for the pure shared modules. Run from the repo root:
--   luau tests/run.luau
-- Exits with code 1 if anything fails.

local Config = require("../src/shared/Config")
local Rng = require("../src/shared/Rng")
local Ratings = require("../src/shared/Ratings")
local PlayerFactory = require("../src/shared/PlayerFactory")
local Elo = require("../src/shared/Elo")
local CodeRules = require("../src/shared/CodeRules")
local Quests = require("../src/shared/Quests")
local Achievements = require("../src/shared/Achievements")
local Projection = require("../src/shared/Projection")
local Stats = require("../src/shared/Stats")
local Sounds = require("../src/shared/Sounds")

local passed, failed = 0, 0
local function test(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		passed += 1
	else
		failed += 1
		print("FAIL  " .. name .. "\n      " .. tostring(err))
	end
end
local function eq(a, b, msg: string?)
	if a ~= b then
		error(string.format("%s: expected %s, got %s", msg or "eq", tostring(b), tostring(a)), 2)
	end
end
local function ok(cond, msg: string?)
	if not cond then
		error(msg or "expected true", 2)
	end
end

-- Ratings & players ---------------------------------------------------------
test("20 ratings in 6 groups", function()
	eq(#Ratings.Keys, 20, "keys")
	eq(#Ratings.Groups, 6, "groups")
end)

test("generated players hit their target OVR", function()
	local rng = Rng.new(42)
	for _, pos in ipairs(Config.Positions) do
		for _, target in ipairs({ 52, 64, 72, 79, 86, 93 }) do
			local p = PlayerFactory.generate(rng, { rarity = "Common", pos = pos, ovr = target, finish = false })
			local diff = math.abs(PlayerFactory.overall(p) - target)
			ok(diff <= 1, string.format("%s target %d got %d", pos, target, PlayerFactory.overall(p)))
			for _, k in ipairs(Ratings.Keys) do
				local v = p.ratings[k]
				ok(v >= Ratings.MIN and v <= Ratings.MAX, k .. " out of range")
			end
		end
	end
end)

test("rarity ranges hold", function()
	local rng = Rng.new(7)
	for _, r in ipairs(Config.Rarities) do
		for _ = 1, (r.locked and 0 or 40) do
			local p = PlayerFactory.generate(rng, { rarity = r.id, finish = false })
			local o = PlayerFactory.overall(p)
			ok(o >= r.min - 1 and o <= r.max + 1, r.id .. " got " .. o)
		end
	end
end)

test("positions have the right shape", function()
	local rng = Rng.new(9)
	local c = PlayerFactory.generate(rng, { pos = "C", ovr = 75, finish = false })
	local pg = PlayerFactory.generate(rng, { pos = "PG", ovr = 75, finish = false })
	ok(c.ratings.block > pg.ratings.block, "C blocks more")
	ok(pg.ratings.handling > c.ratings.handling, "PG handles better")
	ok(c.height > pg.height, "C is taller")
end)

test("same seed gives same player", function()
	local a = PlayerFactory.generate(Rng.new(123), { rarity = "Epic" })
	local b = PlayerFactory.generate(Rng.new(123), { rarity = "Epic" })
	eq(a.id, b.id)
	eq(a.name, b.name)
	eq(a.ratings.three, b.ratings.three)
end)

test("starter roster is ten Commons, one starter per position", function()
	local roster = PlayerFactory.starterRoster(555)
	eq(#roster, Config.MatchdaySize)
	for i = 1, 5 do
		eq(roster[i].pos, Config.Positions[i])
		eq(roster[i].rarity, "Common")
	end
end)

test("pack odds add up to 1", function()
	for id, pack in pairs(Config.Packs) do
		local s = 0
		for _, p in pairs(pack.odds) do
			s += p
		end
		ok(math.abs(s - 1) < 1e-9, id .. " odds sum " .. s)
	end
end)

test("packs: card counts, guarantees, Hall of Famers only in top packs", function()
	local rng = Rng.new(21)
	eq(Config.Packs.Blacktop.count, 3)
	eq(Config.Packs.Pro.count, 4)
	eq(Config.Packs.AllStar.count, 5)
	ok(not Config.Packs.Blacktop.odds.HallOfFame and not Config.Packs.Pro.odds.HallOfFame, "HoF only in top packs")
	for _ = 1, 300 do
		local cards = PlayerFactory.openPack(rng, "AllStar")
		eq(#cards, 5)
		local best = Config.RarityById[cards[#cards].rarity].order
		ok(best >= Config.RarityById.Epic.order, "All-Star guarantees Epic+")
		for i = 2, #cards do
			ok(Config.RarityById[cards[i].rarity].order >= Config.RarityById[cards[i - 1].rarity].order, "best card last")
		end
		local pro = PlayerFactory.openPack(rng, "Pro")
		ok(Config.RarityById[pro[4].rarity].order >= Config.RarityById.Rare.order, "Pro guarantees Rare+")
		for _, c in ipairs(PlayerFactory.openPack(rng, "Blacktop")) do
			ok(c.rarity ~= "HallOfFame" and c.rarity ~= "Legendary", "Blacktop tops out at Epic")
		end
	end
end)

test("player info: nationality, weight, positions, no club yet", function()
	local rng = Rng.new(5)
	for _ = 1, 100 do
		local p = PlayerFactory.generate(rng, { rarity = "Rare" })
		ok(type(p.nation) == "string" and #p.nation == 2, "nation code")
		local w = Config.Weight[p.pos]
		ok(p.weight >= w[1] and p.weight <= w[2], "weight in range")
		for _, a in ipairs(p.altPos) do
			ok(table.find(Config.SecondaryPositions[p.pos], a) ~= nil, "alt position allowed")
		end
		eq(p.club, nil)
	end
end)

test("out of position costs OVR unless listed or Positionless", function()
	local rng = Rng.new(8)
	local p = PlayerFactory.generate(rng, { rarity = "Epic", pos = "PG", ovr = 78, finish = false })
	p.altPos, p.positionless = { "SG" }, nil
	eq(PlayerFactory.positionPenalty(p, "PG"), 0)
	eq(PlayerFactory.positionPenalty(p, "SG"), 0)
	eq(PlayerFactory.positionPenalty(p, "SF"), 6)
	eq(PlayerFactory.positionPenalty(p, "C"), 15)
	ok(PlayerFactory.overallAt(p, "C") < PlayerFactory.overall(p), "C is worse")
	p.positionless = true
	eq(PlayerFactory.positionPenalty(p, "C"), 0)
end)

test("nobody goes above the OVR cap", function()
	ok(Config.MaxOvr <= 93, "cap is 93 for now")
	for _, r in ipairs(Config.Rarities) do
		ok(r.max <= Config.MaxOvr, r.id .. " range above cap")
	end
	local rng = Rng.new(11)
	for _ = 1, 200 do
		local p = PlayerFactory.generate(rng, { rarity = "HallOfFame", ovr = 91, finish = "Prism" })
		ok(PlayerFactory.overall(p) <= Config.MaxOvr, "over cap " .. PlayerFactory.overall(p))
		ok(p.potential <= Config.MaxOvr, "potential over cap")
	end
end)

test("rollRarity follows the odds", function()
	local rng = Rng.new(1)
	local counts = {}
	local N = 20000
	for _ = 1, N do
		local r = PlayerFactory.rollRarity(rng, Config.Packs.Pro.odds)
		counts[r] = (counts[r] or 0) + 1
	end
	ok(math.abs(counts.Rare / N - 0.41) < 0.02, "Rare ~41%")
	ok(math.abs(counts.Common / N - 0.36) < 0.02, "Common ~36%")
	eq(PlayerFactory.rollRarity(rng, { Epic = 1 }), "Epic")
end)

-- Elo -------------------------------------------------------------------------
test("even clubs trade 12 with K 24", function()
	eq(Elo.change(1000, 1000, true, 24), 12)
	eq(Elo.change(1000, 1000, false, 24), -12)
end)

test("upsets pay more", function()
	ok(Elo.change(1000, 1300, true, 24) > Elo.change(1300, 1000, true, 24), "underdog win pays more")
end)

test("placement K and saved-team owner K", function()
	eq(Elo.kFactor(0), 40)
	eq(Elo.kFactor(10), 24)
	eq(Elo.kFactor(10, true), 12)
end)

test("tiers", function()
	eq(Elo.tier(1000).id, "Blacktop")
	eq(Elo.tier(1100).id, "Varsity")
	eq(Elo.tier(1950).id, "HallOfFame")
end)

test("promotion gives a shield that absorbs drops", function()
	local s = { elo = 1095, games = 20, tier = 1, shield = 0 }
	s = Elo.apply(s, 1095, true) -- +12 -> 1107, Varsity
	eq(s.tier, 2, "promoted")
	eq(s.shield, 3, "shield")
	s = Elo.apply(s, 1107, false) -- 1095: below Varsity but shielded
	eq(s.tier, 2, "still Varsity")
	eq(s.shield, 2)
	s = Elo.apply(s, 1095, false)
	s = Elo.apply(s, 1083, false)
	eq(s.shield, 0)
	s = Elo.apply(s, 1071, false)
	eq(s.tier, 1, "dropped after shield ran out")
end)

test("saved-team owner doesn't gain a game played", function()
	local s = Elo.apply({ elo = 1200, games = 30 }, 1200, false, true)
	eq(s.games, 30)
	eq(s.elo, 1194)
end)

test("search range widens", function()
	eq(Elo.searchRange(0), 100)
	eq(Elo.searchRange(6), 200)
	eq(Elo.searchRange(600), 400)
end)

-- Codes -----------------------------------------------------------------------
test("normalize", function()
	eq(CodeRules.normalize("  tip off! "), "TIPOFF")
	eq(CodeRules.normalize("ab"), nil)
	eq(CodeRules.normalize(5), nil)
	eq(CodeRules.normalize("fast_break-2"), "FAST_BREAK-2")
end)

test("parseDate is end of day UTC", function()
	eq(CodeRules.parseDate("1970-01-01"), 86399)
	eq(CodeRules.parseDate("2026-12-31"), 1798761599)
	eq(CodeRules.parseDate("2026-13-01"), nil)
	eq(CodeRules.parseDate("tomorrow"), nil)
end)

test("static entries", function()
	local def = assert(CodeRules.fromStatic({ coins = 5000, packs = { Pro = 1 }, expires = "2026-12-31" }))
	eq(def.expires, 1798761599)
	local bad, err = CodeRules.fromStatic({ packs = { Mystery = 1 } })
	eq(bad, nil)
	ok(err:find("unknown pack"), err)
	eq((CodeRules.fromStatic({ coins = 1e12 })), nil, "over cap")
	eq((CodeRules.fromStatic({ expires = "2026-12-31" })), nil, "gives nothing")
end)

test("check: expiry, repeats, new players", function()
	local now = 1_800_000_000
	eq(CodeRules.check({ coins = 1 }, { now = now }), true)
	eq(select(2, CodeRules.check(nil, { now = now })), "invalid")
	eq(select(2, CodeRules.check({ coins = 1, expires = now - 1 }, { now = now })), "expired")
	eq(select(2, CodeRules.check({ coins = 1 }, { now = now, alreadyRedeemed = true })), "already")
	eq(select(2, CodeRules.check({ coins = 1, disabled = true }, { now = now })), "disabled")
	local newOnly = { coins = 1, newPlayersOnly = true }
	eq(CodeRules.check(newOnly, { now = now, clubCreatedAt = now - 3600 }), true)
	eq(select(2, CodeRules.check(newOnly, { now = now, clubCreatedAt = now - 10 * 86400 })), "newOnly")
end)

test("describe", function()
	eq(CodeRules.describe({ coins = 5000, packs = { Pro = 2 }, boost = { kind = "DoubleCoins", minutes = 30 } }),
		"5,000 coins + 2 Pro Packs + 30 min Double Coins")
	eq(CodeRules.describe({ coins = 1234567 }), "1,234,567 coins")
	eq(CodeRules.describe({ packs = { Blacktop = 1 } }), "1 Blacktop Pack")
end)

test("parse !makecode", function()
	local now = 1_800_000_000
	local r = CodeRules.parseCommand("!makecode tipoff coins=5000 pack=pro:2 pack=allstar boost=doublecoins:30 uses=500 days=7 new=yes", now)
	eq(r.cmd, "make")
	eq(r.code, "TIPOFF")
	eq(r.def.coins, 5000)
	eq(r.def.packs.Pro, 2)
	eq(r.def.packs.AllStar, 1)
	eq(r.def.boost.kind, "DoubleCoins")
	eq(r.def.maxUses, 500)
	eq(r.def.expires, now + 7 * 86400)
	eq(r.def.newPlayersOnly, true)
	r = CodeRules.parseCommand("!makecode HOLIDAY fans=50 until=2026-12-31", now)
	eq(r.def.expires, 1798761599)
end)

test("parse command errors and other commands", function()
	local now = 0
	eq(CodeRules.parseCommand("hello everyone", now), nil)
	eq(CodeRules.parseCommand("!makecode", now).cmd, "error")
	eq(CodeRules.parseCommand("!makecode X1Y coins=abc", now).cmd, "error")
	eq(CodeRules.parseCommand("!makecode X1Y pack=Mystery", now).cmd, "error")
	eq(CodeRules.parseCommand("!makecode X1Y days=3", now).cmd, "error") -- gives nothing
	eq(CodeRules.parseCommand("!makecode coins=5 coins=5", now).cmd, "error")
	eq(CodeRules.parseCommand("!delcode tipoff", now).code, "TIPOFF")
	eq(CodeRules.parseCommand("!codes", now).cmd, "list")
	eq(CodeRules.parseCommand("!CodeHelp", now).cmd, "help")
end)

-- The real codes list must be valid, so a typo can't break the live game.
test("src/server/Codes.lua entries are valid", function()
	local Codes = require("../src/server/Codes")
	for name, entry in pairs(Codes) do
		eq(CodeRules.normalize(name), name, "code names must be CAPITALS, letters/numbers/_/-")
		local def, err = CodeRules.fromStatic(entry)
		ok(def ~= nil, name .. ": " .. tostring(err))
	end
end)

-- Quests ----------------------------------------------------------------------
test("3 different quests a day, same all day, new tomorrow", function()
	local now = 1_800_000_000
	local a = Quests.ensureDay(nil, 99, now)
	eq(#a.list, 3)
	ok(a.list[1].id ~= a.list[2].id and a.list[2].id ~= a.list[3].id, "no repeats")
	local b = Quests.ensureDay(nil, 99, now + 60)
	eq(a.list[1].text, b.list[1].text, "same day same quests")
	eq(Quests.ensureDay(a, 99, now + 60), a, "kept")
	local c = Quests.ensureDay(a, 99, now + 86400)
	ok(c ~= a and c.day == a.day + 1, "new day")
end)

test("quest progress and claiming", function()
	local st = { day = 1, list = { { id = "win", event = "gamesWon", text = "", target = 2, coins = 2500, progress = 0, claimed = false } } }
	eq(#Quests.record(st, "gamesPlayed", 1), 0)
	eq(select(2, Quests.claim(st, 1)), "Not finished yet.")
	Quests.record(st, "gamesWon")
	local done = Quests.record(st, "gamesWon", 5)
	eq(#done, 1)
	eq(st.list[1].progress, 2, "capped at target")
	eq(Quests.claim(st, 1), 2500)
	eq(select(2, Quests.claim(st, 1)), "Already claimed.")
	eq(#Quests.record(st, "gamesWon"), 0, "no double completion")
end)

-- Achievements ----------------------------------------------------------------
test("achievement tiers pay once each", function()
	local stats, claimed = {}, {}
	Achievements.recordStat(stats, "gamesWon", 12)
	local r = assert(Achievements.claim(stats, claimed, "Winner"))
	eq(r.coins, 1000)
	r = assert(Achievements.claim(stats, claimed, "Winner"))
	eq(r.coins, 5000)
	eq(select(2, Achievements.claim(stats, claimed, "Winner")), "Not reached yet.")
	local v
	for _, x in ipairs(Achievements.view(stats, claimed)) do
		if x.id == "Winner" then
			v = x
		end
	end
	eq(v.target, 50)
	eq(v.tier, 2)
	eq(v.claimable, false)
end)

test("max stats keep the best value", function()
	local stats = {}
	Achievements.recordStat(stats, "bestStreak", 4)
	Achievements.recordStat(stats, "bestStreak", 2)
	eq(stats.bestStreak, 4)
	Achievements.recordStat(stats, "dunks", 3)
	Achievements.recordStat(stats, "dunks", 3)
	eq(stats.dunks, 6)
end)

test("Climber shows tier names", function()
	local v = Achievements.view({}, {})
	for _, x in ipairs(v) do
		if x.id == "Climber" then
			eq(x.text, "Reach tier Varsity")
		end
	end
end)

-- Projection --------------------------------------------------------------------
local function rotationAt(ovr: number, seed: number)
	local rng = Rng.new(seed)
	local mins = { 34, 33, 34, 32, 31, 20, 18, 16, 14, 8 }
	local rot = {}
	for i = 1, 10 do
		local p = PlayerFactory.generate(rng, { pos = Config.Positions[(i - 1) % 5 + 1], ovr = ovr, finish = false })
		table.insert(rot, { player = p, minutes = mins[i] })
	end
	return rot
end

test("even teams project a close, realistic score", function()
	local r = Projection.project({ rotation = rotationAt(75, 1), offense = "Motion", defense = "ManToMan" },
		{ rotation = rotationAt(75, 2), offense = "Motion", defense = "ManToMan" })
	ok(r.home >= 90 and r.home <= 120, "home " .. r.home)
	ok(math.abs(r.home - r.away) <= 6, r.home .. "-" .. r.away)
	ok(r.homeWin > 0.35 and r.homeWin < 0.75, "win% " .. r.homeWin)
	ok(r.home ~= r.away, "no ties")
end)

test("better team is projected to win", function()
	local r = Projection.project({ rotation = rotationAt(85, 3), offense = "Motion", defense = "ManToMan" },
		{ rotation = rotationAt(68, 4), offense = "Motion", defense = "ManToMan" })
	ok(r.home > r.away + 8, r.home .. "-" .. r.away)
	ok(r.homeWin > 0.85, "win% " .. r.homeWin)
end)

test("pace styles mean more points", function()
	local slow = Projection.project({ rotation = rotationAt(75, 5), offense = "InsideOut", defense = "TwoThreeZone" },
		{ rotation = rotationAt(75, 6), offense = "IsoStar", defense = "ManToMan" })
	local fast = Projection.project({ rotation = rotationAt(75, 5), offense = "PaceAndSpace", defense = "FullCourtPress" },
		{ rotation = rotationAt(75, 6), offense = "PaceAndSpace", defense = "ManToMan" })
	ok(fast.home + fast.away > slow.home + slow.away + 10, "fast " .. (fast.home + fast.away) .. " slow " .. (slow.home + slow.away))
end)

-- Stats -------------------------------------------------------------------------
local function line(t)
	local l = Stats.newLine()
	for k, v in pairs(t) do
		l[k] = v
	end
	return l
end

test("box line consistency", function()
	ok(Stats.isConsistent(line({ pts = 25, fgm = 9, fga = 18, tpm = 3, tpa = 7, ftm = 4, fta = 5 })))
	ok(not Stats.isConsistent(line({ pts = 30, fgm = 9, fga = 18, tpm = 3, tpa = 7, ftm = 4, fta = 5 })))
end)

test("team and player averages after two games", function()
	local team = Stats.newTeam()
	local p1 = { id = "a" }
	local p2 = { id = "b" }
	local players = { a = p1, b = p2 }
	Stats.recordGame(team, players, {
		a = line({ min = 36, pts = 30, fgm = 11, fga = 20, tpm = 4, tpa = 9, ftm = 4, fta = 4, dreb = 5, ast = 6, dunks = 2 }),
		b = line({ min = 30, pts = 10, fgm = 4, fga = 10, tpm = 0, tpa = 1, ftm = 2, fta = 4, oreb = 3, dreb = 7, blk = 3 }),
	}, 35, "a")
	Stats.recordGame(team, players, {
		a = line({ min = 34, pts = 20, fgm = 8, fga = 20, tpm = 2, tpa = 8, ftm = 2, fta = 2, dreb = 3, ast = 4 }),
		b = line({ min = 0 }),
	}, 30)
	local s = Stats.teamSummary(team)
	eq(s.games, 2)
	eq(s.wins, 1)
	eq(s.losses, 1)
	eq(s.ppg, 30)
	eq(s.oppPpg, 32.5)
	eq(s.fgPct, 46) -- 23/50
	eq(s.threePct, 33.3) -- 6/18
	eq(s.ftPct, 80) -- 8/10
	eq(s.rpg, 9)
	eq(p1.career.games, 2)
	eq(p2.career.games, 1, "0 minutes doesn't count as a game")
	eq(p1.career.mvps, 1)
	eq(Stats.summary(p1.career, p1.career.games).ppg, 25)
end)

test("mvp picks the best line", function()
	eq(Stats.mvp({ a = line({ pts = 30, fgm = 12, fga = 20, ast = 5 }), b = line({ pts = 8, fgm = 3, fga = 12, tov = 4 }) }), "a")
end)

-- Sounds ------------------------------------------------------------------------
test("every sound has a real group and sane settings", function()
	local groups = {}
	for _, g in ipairs(Sounds.Groups) do
		groups[g] = true
	end
	local n = 0
	for name, s in pairs(Sounds.List) do
		n += 1
		ok(groups[s.group], name .. " has unknown group " .. tostring(s.group))
		ok(s.volume > 0 and s.volume <= 1, name .. " volume")
		for _, id in ipairs(s.ids) do
			ok(type(id) == "number" and id > 0, name .. " has a bad asset id")
		end
	end
	ok(n > 80, "expected the full sound list, got " .. n)
end)

test("unfilled sounds are silent, variants pick in range", function()
	eq(Sounds.pickId("Swish", 0.5), nil)
	eq(Sounds.pickId("NoSuchSound", 0.5), nil)
	Sounds.List.Swish.ids = { 11, 22, 33 }
	eq(Sounds.pickId("Swish", 0), 11)
	eq(Sounds.pickId("Swish", 0.999), 33)
	Sounds.List.Swish.ids = {}
end)

test("every commentator event has lines with text", function()
	for event, e in pairs(Sounds.Lines) do
		ok(#e.lines > 0, event .. " has no lines")
		for _, l in ipairs(e.lines) do
			ok(#l.text > 0, event .. " empty line")
		end
	end
	ok(Sounds.Lines.PackHallOfFame.priority > Sounds.Lines.Miss.priority, "big moments outrank small ones")
end)

print(string.format("%d passed, %d failed", passed, failed))
if failed > 0 then
	error("tests failed")
end
