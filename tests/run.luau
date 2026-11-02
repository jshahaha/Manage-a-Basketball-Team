-- Tests for the pure shared modules. Run from the repo root:
--   luau tests/run.luau
-- Exits with code 1 if anything fails.

local Config = require("../src/shared/Config")
local Rng = require("../src/shared/Rng")
local Ratings = require("../src/shared/Ratings")
local PlayerFactory = require("../src/shared/PlayerFactory")
local Badges = require("../src/shared/Badges")
local Inventory = require("../src/shared/Inventory")
local Ratings2 = require("../src/shared/Ratings")
local AnimClips = require("../src/shared/AnimClips")
local PlayerModel = require("../src/shared/PlayerModel")
local AnimSets = require("../src/shared/AnimSets")
local Possession = require("../src/shared/Possession")
local ShotFeel = require("../src/shared/ShotFeel")
local Store = require("../src/shared/Store")
local Scouting = require("../src/shared/Scouting")
local Cosmetics = require("../src/shared/Cosmetics")
local Facilities = require("../src/shared/Facilities")
local Tutorial = require("../src/shared/Tutorial")
local Catalog2 = require("../src/shared/Catalog")
local Elo = require("../src/shared/Elo")
local CodeRules = require("../src/shared/CodeRules")
local Quests = require("../src/shared/Quests")
local Achievements = require("../src/shared/Achievements")
local Projection = require("../src/shared/Projection")
local Stats = require("../src/shared/Stats")
local Sounds = require("../src/shared/Sounds")
local MatchSim = require("../src/shared/MatchSim")

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
		for _, odds in ipairs({ pack.kind ~= "badges" and pack.odds or nil, pack.badgeOdds }) do
			local s = 0
			for _, p in pairs(odds) do
				s += p
			end
			ok(math.abs(s - 1) < 1e-9, id .. " odds sum " .. s)
		end
	end
end)

test("packs: ladder, each rarity in at most 3 packs, Hall of Fame only in the top 2", function()
	local where = {}
	for id, pack in pairs(Config.Packs) do
		if pack.kind == "players" then
			for r in pairs(pack.odds) do
				where[r] = (where[r] or 0) + 1
			end
		end
	end
	for r, n in pairs(where) do
		ok(n <= 3, r .. " is in " .. n .. " packs")
	end
	eq(where.HallOfFame, 2)
	ok(Config.Packs.AllStar.odds.HallOfFame and Config.Packs.HallOfFame.odds.HallOfFame, "HoF in top 2")
	ok(Config.Packs.Coach.kind == "coach" and Config.Packs.EliteCoach.kind == "coach", "two coach packs")
end)

test("catalog: fixed card list, packs draw from it", function()
	local Catalog = require("../src/shared/Catalog")
	local ps, cs = Catalog.players(), Catalog.coaches()
	eq(#ps, 216)
	eq(#cs, 28)
	local names = {}
	for _, p in ipairs(ps) do
		ok(not names[p.name], "duplicate name " .. p.name)
		names[p.name] = true
		ok(PlayerFactory.overall(p) <= Config.MaxOvr, "cap")
	end
	eq(Catalog.get(ps[1].id), ps[1])
	local rng = Rng.new(4)
	for _ = 1, 200 do
		local cards, badges, items = PlayerFactory.openPack(rng, "AllStar", Catalog, Badges)
		ok(#cards >= 1 and #cards <= 2, "1-2 players")
		ok(#badges >= 2 and #badges <= 3, "2-3 badges")
		eq(#items, 1)
		if items[1].id == "BadgeUpgrade" then
			ok(Badges.nextTier(items[1].from, "HallOfFame") == items[1].to and items[1].to ~= nil, "upgrade tiers")
		end
		local _, _, coachItems = PlayerFactory.openPack(rng, "Coach", Catalog, Badges)
		eq(#coachItems, 0)
		for _, b in ipairs(badges) do
			ok(Config.Packs.AllStar.badgeOdds[b.tier] ~= nil, "badge tier not in pack")
		end
		for i, c in ipairs(cards) do
			ok(Config.Packs.AllStar.odds[c.rarity] ~= nil, "rarity not in pack")
			eq(Catalog.get(c.id), c)
			if i > 1 then
				ok(Config.RarityById[c.rarity].order >= Config.RarityById[cards[i - 1].rarity].order, "best last")
			end
		end
		local coach = PlayerFactory.openPack(rng, "EliteCoach", Catalog, Badges)[1]
		eq(coach.kind, "coach")
	end
	-- contents add up to 1 per card slot
	local total = 0
	for _, e in ipairs(Catalog.packContents("Pro")) do
		total += e.chance
	end
	ok(math.abs(total - 1) < 1e-9, "contents sum " .. total)
end)

test("badges: tiers, slots, stat bars, coins, boosts", function()
	eq(Badges.nextTier("Silver"), "Gold")
	eq(Badges.nextTier("Diamond"), nil)
	eq(Badges.nextTier("Gold", "Gold"), nil)
	eq(Badges.nextTier("Silver", "Gold"), "Gold")
	eq(#Badges.Tiers, 5)
	eq(Badges.slots({ rarity = "Common" }), 1)
	eq(Badges.slots({ rarity = "HallOfFame" }), 5)
	local p = { rarity = "Rare", ratings = { three = 80, strength = 70, stamina = 50, ft = 90 } }
	local ok1, why = Badges.check(p, "Laser", "Gold", 1e9)
	ok(ok1, why)
	local ok2, why2 = Badges.check(p, "Laser", "Diamond", 1e9)
	ok(not ok2 and why2:find("84"), "Diamond needs 84")
	ok(Badges.check(p, "Laser", "Gold", 0), "equipping is free")
	ok(Badges.equip(p, "Laser", "Gold", 1e9))
	ok(Badges.equip(p, "IceWater", "Silver", 1e9))
	local ok4, why4 = Badges.check(p, "Motor", "Bronze", 1e9)
	ok(not ok4 and why4:find("slots"), "Rare has 2 slots")
	ok(not Badges.equip(p, "IceWater", "Diamond"), "no upgrading an equipped badge")
	ok(Badges.unequip(p, "IceWater", 1e9) and Badges.equip(p, "IceWater", "Diamond"), "take off, then put on the better one")
	eq(Badges.boost(p, "three"), 6)
	eq(Badges.boost(p, "ft"), 8)
	-- second stat needs 8 less
	local r = Badges.requirements("DeepRange", "Gold")
	eq(r[2][2], 68)
	-- every pack's badge tiers sit in at most 3 neighbouring packs
	local where = {}
	for _, pack in pairs(Config.Packs) do
		if pack.kind == "players" then
			for t in pairs(pack.badgeOdds) do
				where[t] = (where[t] or 0) + 1
			end
		end
	end
	for t, n in pairs(where) do
		ok(n <= 3, t .. " badges in " .. n .. " packs")
	end
	eq(where.HallOfFame, 2)
end)

test("bundles are cheaper per pack", function()
	eq(PlayerFactory.bundlePrice("Pro", 1, "coins"), 4000)
	eq(PlayerFactory.bundlePrice("Pro", 5, "coins"), 18000)
	eq(PlayerFactory.bundlePrice("Pro", 20, "coins"), 64000)
	eq(PlayerFactory.bundlePrice("Pro", 5, "robux"), 446)
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
		local r = PlayerFactory.rollRarity(rng, Config.Packs.Blacktop.odds)
		counts[r] = (counts[r] or 0) + 1
	end
	ok(math.abs(counts.Rare / N - 0.33) < 0.02, "Rare ~33%")
	ok(math.abs(counts.Common / N - 0.60) < 0.02, "Common ~60%")
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
	local st = { day = 1, list = { { id = "win", event = "gamesWon", text = "", target = 2, coins = 250, progress = 0, claimed = false } } }
	eq(#Quests.record(st, "gamesPlayed", 1), 0)
	eq(select(2, Quests.claim(st, 1)), "Not finished yet.")
	Quests.record(st, "gamesWon")
	local done = Quests.record(st, "gamesWon", 5)
	eq(#done, 1)
	eq(st.list[1].progress, 2, "capped at target")
	eq(Quests.claim(st, 1), 250)
	eq(select(2, Quests.claim(st, 1)), "Already claimed.")
	eq(#Quests.record(st, "gamesWon"), 0, "no double completion")
end)

-- Achievements ----------------------------------------------------------------
test("achievement tiers pay once each", function()
	local stats, claimed = {}, {}
	Achievements.recordStat(stats, "gamesWon", 12)
	local r = assert(Achievements.claim(stats, claimed, "Winner"))
	eq(r.coins, 100)
	r = assert(Achievements.claim(stats, claimed, "Winner"))
	eq(r.coins, 500)
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

test("bundles stay one inventory item", function()
	local prof = { packs = { Pro = 1 } }
	eq(Inventory.add(prof, "Pro", 5), "Pro x5")
	Inventory.add(prof, "Pro", 1)
	eq(prof.packs.Pro, 2)
	eq(prof.packs["Pro x5"], 1)
	local id, size = Inventory.take(prof, "Pro x5")
	eq(id, "Pro")
	eq(size, 5)
	eq(prof.packs["Pro x5"], nil)
	eq(Inventory.list(prof)[1].kind, "pack")
	Inventory.addBadge(prof, "Laser", "Gold")
	ok(Inventory.takeBadge(prof, "Laser", "Gold"), "badge taken")
	ok(not Inventory.takeBadge(prof, "Laser", "Gold"), "only once")
end)

test("archetype names have spaces", function()
	eq(Ratings2.archetypeName("RimProtector"), "Rim Protector")
	eq(Ratings2.archetypeName("FloorGeneral"), "Floor General")
	for id in pairs(Ratings2.ArchetypeNames) do
		ok(Ratings2.ArchetypeNames[id] ~= id or not id:find("%l%u"), id)
	end
end)

test("animation clips: sorted keys, sounds exist, walkout move for every archetype", function()
	for name, clip in pairs(AnimClips.Clips) do
		ok(clip.length > 0, name)
		for joint, keys in pairs(clip.joints) do
			for i = 2, #keys do
				ok(keys[i][1] >= keys[i - 1][1], name .. "." .. joint .. " keys out of order")
			end
			ok(keys[#keys][1] <= clip.length + 1e-6, name .. "." .. joint .. " key past the end")
		end
		for _, e in ipairs(clip.events or {}) do
			ok(Sounds.List[e[2]] ~= nil, name .. " event sound " .. e[2] .. " not in Sounds.lua")
		end
	end
	for _, rule in ipairs(Ratings2.ArchetypeRules) do
		ok(AnimClips.WalkoutMove[rule.id] ~= nil, "no walkout move for " .. rule.id)
	end
	ok(AnimClips.WalkoutMove.AllAround ~= nil, "AllAround")
	for play, clip in pairs(AnimClips.ForPlay) do
		ok(AnimClips.Clips[clip] ~= nil, "play " .. play .. " uses missing clip " .. clip)
	end
	-- feet: flat when standing in a crouch, toes pointed in the air (Roblox space is mirrored)
	eq(AnimClips.footAngle(0, 40, -60, -0.9), -20)
	eq(AnimClips.footAngle(0, 0, 0, 2), -30)
	for _, n in ipairs({ "Idle", "Jog", "DefSlide" }) do
		ok(AnimClips.Clips[n].loop == true, n .. " should loop")
	end
	-- sampling hits the keys exactly
	local k = AnimClips.Clips.Shoot.joints.RightShoulder
	eq(math.floor(AnimClips.sample(k, k[3][1], 3)[1] + 0.5), k[3][2])
	local evs = AnimClips.eventsBetween(AnimClips.Clips.Dribble, 0, 0.25)
	eq(evs[1], "Dribble")
end)

test("scouting: reveal ladder, never OVR, overlapping prices, refresh rules", function()
	local rng = Rng.new(7)
	local st = Scouting.newState()
	local report = Scouting.roll(rng, st, 1000, function(r, rarity)
		return Catalog2.draw(r, "player", rarity)
	end)
	eq(#report.players, 3)
	eq(report.expires, 1000 + 6 * 3600)
	local p = Catalog2.get(report.players[1])
	local v0 = Scouting.view(p, 0)
	eq(#v0.stats, 1)
	ok(v0.position == nil and v0.rarity == nil and v0.archetype == nil, "level 0 hides everything else")
	ok(v0.ovr == nil, "never OVR")
	eq(Scouting.view(p, 1).position, p.pos)
	eq(#Scouting.view(p, 2).stats, 2)
	ok(Scouting.view(p, 3).archetype ~= nil and Scouting.view(p, 3).nation ~= nil, "level 3")
	eq(#Scouting.view(p, 4).stats, 3)
	ok(Scouting.view(p, 4).rarity == nil, "rarity only at 5")
	eq(Scouting.view(p, 5).rarity, p.rarity)
	local top = Scouting.view(p, 5).stats
	ok(top[1][3] >= top[2][3] and top[2][3] >= top[3][3], "best first")
	ok(not Scouting.canRefresh(st, 2000, "free", 0, 0), "timer")
	ok(Scouting.canRefresh(st, 1000 + 6 * 3600, "free", 0, 0), "timer done")
	local okT, _, cost = Scouting.canRefresh(st, 2000, "ticket", 0, 1)
	ok(okT and cost.tickets == 1, "ticket")
	ok(not Scouting.canRefresh(st, 2000, "ticket", 0, 0), "no ticket")
	local okS, _, cost = Scouting.canSign(st, 1, 1e9)
	ok(okS and cost == Scouting.price(report.prices[1], 0), "sign")
	ok(not Scouting.canSign(st, 1, cost - 1), "too poor")
	ok(Scouting.price(100000, 5) == 80000, "level 5 is 20% off")
	-- prices scale with OVR and overlap between neighbours
	for ovr = 55, 90 do
		local _, hiA = Scouting.priceRange(ovr)
		local loB = Scouting.priceRange(ovr + 2)
		ok(loB < hiA, "prices 2 OVR apart still overlap at " .. ovr)
	end
	local lo65 = Scouting.priceRange(65)
	local _, hi64 = Scouting.priceRange(64)
	ok(lo65 < hi64, "Common and Rare prices overlap")
	ok(Scouting.priceRange(80) > Scouting.priceRange(70), "better players cost more")
	eq(Scouting.upgradeCost(0), 50)
	eq(Scouting.upgradeCost(5), nil)
end)

test("cosmetics: slots, roll, equip, pack item", function()
	for _, c in ipairs(Cosmetics.List) do
		ok(Cosmetics.RarityById[c.rarity] ~= nil, c.id .. " rarity")
		local found = false
		for _, s in ipairs(Cosmetics.Slots) do
			found = found or s.id == c.slot
		end
		ok(found, c.id .. " slot")
	end
	local rng = Rng.new(3)
	local owned, equipped = {}, {}
	local c = Cosmetics.roll(rng)
	ok(not Cosmetics.equip(owned, equipped, c.id), "must own")
	owned[c.id] = true
	ok(Cosmetics.equip(owned, equipped, c.id), "equip")
	eq(equipped[c.slot], c.id)
	for _ = 1, 300 do
		local _, _, items = PlayerFactory.openPack(rng, "Pro", Catalog2, Badges)
		if items[1].id == "Cosmetic" then
			ok(Cosmetics.ById[items[1].cosmetic] ~= nil, "cosmetic id")
		end
	end
end)

test("facilities: arena and training upgrades with build timers", function()
	local st = Facilities.newState()
	eq(Facilities.nextCost("Arena", 0).coins, 2000)
	eq(Facilities.nextCost("Arena", 0).hours, 2)
	ok(Facilities.nextCost("Arena", 10) == nil, "max")
	ok(not Facilities.startUpgrade("Arena", st.Arena, 100, 0), "too poor")
	ok(Facilities.startUpgrade("Arena", st.Arena, 1e9, 0), "start")
	ok(not Facilities.startUpgrade("Arena", st.Arena, 1e9, 0), "one build at a time")
	eq(Facilities.skipCost(st.Arena, 3600, Config.Gems.skipBuildPerHour), 15)
	eq(Facilities.skipCost(st.Arena, 3599, Config.Gems.skipBuildPerHour), 30)
	ok(not Facilities.tick(st.Arena, 7199), "not done")
	ok(Facilities.tick(st.Arena, 7200), "done")
	eq(st.Arena.level, 1)
	local e = Facilities.effect("Arena", 10)
	ok(math.abs(e.coinBonus - 0.4) < 1e-9 and math.abs(e.homeOvr - 2) < 1e-9, "arena level 10")
end)

test("gem slots: scout report 3 to 6, training 3 to 5, rising prices", function()
	eq(Config.slotCost("Scout", 3), 100)
	eq(Config.slotCost("Scout", 4), 250)
	eq(Config.slotCost("Scout", 5), 650)
	eq(Config.slotCost("Scout", 6), nil)
	eq(Config.slotCost("Training", 3), 150)
	eq(Config.slotCost("Training", 4), 400)
	eq(Config.slotCost("Training", 5), nil)
	local st = Scouting.newState()
	eq(#Scouting.roll(Rng.new(3), st, 0, function(r, rarity)
		return Catalog2.draw(r, "player", rarity)
	end).players, 3)
	ok(not Scouting.buySlot(st, 99), "too poor")
	local okB, _, spent = Scouting.buySlot(st, 1000)
	ok(okB and spent == 100 and Scouting.size(st) == 4, "bought slot")
	eq(#Scouting.roll(Rng.new(4), st, 0, function(r, rarity)
		return Catalog2.draw(r, "player", rarity)
	end).players, 4)
	st.slots = 6
	ok(not Scouting.buySlot(st, 1e9), "max")
end)

test("tutorial: steps in order, gifts once, finish reward, skip", function()
	local st = Tutorial.newState()
	eq(Tutorial.current(st).id, "club")
	eq(Tutorial.takeGift(st), nil)
	eq(Tutorial.record(st, "packsOpened"), nil, "wrong step does nothing")
	eq(Tutorial.current(st).id, "club")
	Tutorial.record(st, "clubCreated")
	local gift = Tutorial.takeGift(st)
	eq(gift.packs.Rookie, 1)
	eq(Tutorial.takeGift(st), nil, "gift only once")
	local last
	for _, step in ipairs(Tutorial.Steps) do
		if step.index >= 2 then
			local r = Tutorial.record(st, step.event)
			if step.id == "game" then
				eq(r.coins, 250)
			end
			last = r
		end
	end
	ok(st.done and Tutorial.current(st) == nil, "done")
	eq(last.gems, 20)
	eq(last.packs.Blacktop, 1)
	eq(Config.StartingGems + last.gems, Cosmetics.RarityById.Common.gems, "enough for one Common cosmetic")
	local sk = Tutorial.newState()
	Tutorial.skip(sk)
	eq(Tutorial.current(sk), nil)
	eq(Tutorial.record(sk, "clubCreated"), nil)
end)

test("tutorial: match lessons and first-time tips show once", function()
	local st = Tutorial.newState()
	local seenFocus = {}
	for _, l in ipairs(Tutorial.MatchLessons) do
		ok(l.text and l.focus and l.cue and l.action, l.id .. " complete")
		ok(l.action ~= "drag" or l.dropOn, l.id .. " drag has a drop target")
		ok(#l.text <= 160, l.id .. " text fits the bubble")
		seenFocus[l.focus] = true
	end
	eq(Tutorial.lessonFor(st, "coachCall").id, "coachCall")
	eq(Tutorial.lessonFor(st, "coachCall"), nil, "once")
	eq(Tutorial.lessonFor(st, "timeoutPrompt").id, "timeout")
	eq(Tutorial.tipFor(st, "coldPlayer").id, "cold")
	eq(Tutorial.tipFor(st, "coldPlayer"), nil, "tip once")
	Tutorial.resetLessons(st)
	eq(Tutorial.lessonFor(st, "coachCall").id, "coachCall", "How to play replays lessons")
	for _, t in ipairs(Tutorial.Tips) do
		ok(#t.text <= 110, t.id .. " tip fits")
	end
end)

test("badges: equipping is free, taking off costs the tier's coins", function()
	local p = { rarity = "Epic", ratings = { three = 99, ft = 99 }, badges = {} }
	ok(Badges.equip(p, "Laser", "Gold"))
	local t0, why = Badges.unequip(p, "Laser", 100)
	ok(t0 == nil and why:find("2500"), "too poor to take off")
	local t1, _, cost = Badges.unequip(p, "Laser", 1e9)
	ok(t1 == "Gold" and cost == 2500, "took off for 2,500")
	eq(p.badges.Laser, nil)
	eq((Badges.unequip(p, "Laser", 1e9)), nil)
end)

test("player bodies scale with height and weight", function()
	local guard = PlayerModel.scales({ height = 72, weight = 175, wingspan = 72 })
	local center = PlayerModel.scales({ height = 87, weight = 275, wingspan = 93 })
	assert(math.abs(guard.height - 0.9) < 1e-6 and math.abs(center.height - 1.2) < 1e-6, "height range")
	assert(center.width > guard.width, "heavier is wider")
	assert(center.proportion > guard.proportion, "long wingspan, longer limbs")
end)

test("every player gets a shot, dunk and dribble moves that exist as clips", function()
	local rng = Rng.new(77)
	local seen = {}
	for _, r in ipairs({ "Common", "Rare", "Epic", "Legendary", "HallOfFame" }) do
		for _ = 1, 40 do
			local p = PlayerFactory.generate(rng, { rarity = r })
			local a = p.anims
			assert(a and a.shot and a.dunk and #a.moves == AnimSets.MoveCount[r], "anims for " .. r)
			local c = AnimSets.clips(a)
			assert(AnimClips.Clips[c.shot] and AnimClips.Clips[c.dunk], "clip missing")
			for _, m in ipairs(c.moves) do
				assert(AnimClips.Clips[m], "move clip missing " .. m)
			end
			if r == "Common" then
				assert(a.dunk ~= "Windmill" and a.dunk ~= "Spin360", "commons can't windmill")
			end
			seen[a.dunk] = true
		end
	end
	assert(seen.Spin360 and seen.TwoHand, "all dunks show up")
	local old = AnimSets.clips(nil)
	assert(old.shot == "Shoot" and old.dunk == "Dunk", "old saves get defaults")
end)

test("a possession plan puts the shooter at the spot and plays real clips", function()
	local sets = {}
	for i = 1, 5 do
		sets[i] = AnimSets.clips({ shot = "Fade", dunk = "Windmill", moves = { "Spin" } })
	end
	for _, kind in ipairs({ "jumper", "three", "dunk" }) do
		local plan = Possession.plan({ offense = sets, dir = 1, result = { kind = kind, shooter = 3, assist = 1, made = true } })
		assert(plan.passer == 1 and plan.length > plan.tShot, "beats")
		for t = 0, plan.length, 0.1 do
			local f = Possession.frame(plan, t)
			assert(#f.players == 10 and f.ball, "frame")
			for _, p in ipairs(f.players) do
				assert(AnimClips.Clips[p.clip], "clip " .. tostring(p.clip))
				assert(math.abs(p.x) < 47 * 0.9 and math.abs(p.z) < 25 * 0.9, "on the court")
			end
		end
		local last = Possession.frame(plan, plan.tShot + 0.5).players[3]
		assert(last.clip == (kind == "dunk" and "DunkWindmill" or "ShootFade"), "signature clip")
		local rimDist = math.sqrt((37.575 - last.x) ^ 2 + last.z ^ 2)
		assert(kind ~= "three" or rimDist > 23.75 * 0.9, "three is behind the line")
		assert(kind ~= "dunk" or rimDist < 8 * 0.9, "dunker drives to the rim")
	end
	-- Unassisted: the shooter brings it up, keeps the ball, and shoots.
	local solo = Possession.plan({ offense = sets, dir = 1, result = { kind = "dunk", shooter = 2, made = true } })
	assert(solo.handler == 2 and not solo.passer, "solo handler")
	local f = Possession.frame(solo, solo.tShot + 0.3)
	assert(f.ball.owner == 2 and f.players[2].clip == "DunkWindmill", "solo dunk")
end)

test("shot feedback agrees with the result and rewards good shooters", function()
	local rng = Rng.new(7)
	local function perfects(rating)
		local n = 0
		for _ = 1, 2000 do
			local r = ShotFeel.release(rng, true, rating)
			assert(r == "Perfect" or r == "Good", "made shots read well")
			if r == "Perfect" then
				n += 1
			end
		end
		return n
	end
	assert(perfects(92) > perfects(60) * 2, "better shooters hit Perfect more")
	for _ = 1, 500 do
		assert(ShotFeel.release(rng, false, 75) ~= "Perfect", "a miss is never Perfect")
	end
	for _, k in ipairs({ "Perfect", "Good", "Early", "Late" }) do
		assert(ShotFeel.Text[k] and #ShotFeel.Color[k] == 3, "text and color")
	end
	local plan = Possession.plan({ offense = { AnimSets.clips(nil), AnimSets.clips(nil), AnimSets.clips(nil), AnimSets.clips(nil), AnimSets.clips(nil) }, dir = -1, result = { kind = "jumper", shooter = 4, made = false } })
	assert(plan.result.made == false and plan.handler == 4, "miss plan")
end)

test("a miss ends in a rebound grabbed at the top of the jump", function()
	local sets = {}
	for i = 1, 5 do
		sets[i] = AnimSets.clips({ shot = "High", dunk = "OneHand", moves = { "Crossover" } })
	end
	for _, who in ipairs({ 10, 4 }) do
		local plan = Possession.plan({ offense = sets, dir = 1, result = { kind = "three", shooter = 2, assist = 1, made = false, rebounder = who } })
		local reb = plan.rebound
		assert(reb and reb.who == who and reb.tCatch > reb.tRim and reb.tRim > plan.tShot, "rebound beats")
		assert(plan.length > reb.tCatch, "plays past the catch")
		assert(Possession.frame(plan, reb.tRim - 0.05).ball.owner == 2, "shooter's ball until the rim")
		local mid = Possession.frame(plan, (reb.tRim + reb.tCatch) / 2)
		assert(mid.ball.free and mid.ball.rebound and mid.ball.y > 6, "ball in the air off the rim")
		local after = Possession.frame(plan, reb.tCatch + 0.2)
		assert(after.ball.owner == who and after.players[who].clip == "Rebound", "rebounder has it")
		local p = after.players[who]
		local d = math.sqrt((p.x - reb.spot.x) ^ 2 + (p.z - reb.spot.z) ^ 2)
		assert(d < 0.01, "rebounder at the spot")
		for t = 0, plan.length, 0.1 do
			for _, q in ipairs(Possession.frame(plan, t).players) do
				assert(AnimClips.Clips[q.clip], "clip " .. tostring(q.clip))
			end
		end
	end
	local made = Possession.plan({ offense = sets, dir = 1, result = { kind = "jumper", shooter = 2, made = true } })
	assert(made.rebound == nil, "makes have no rebound")
end)

test("a missed dunk is a block by the help big", function()
	local sets = {}
	for i = 1, 5 do
		sets[i] = AnimSets.clips({ shot = "Textbook", dunk = "Tomahawk", moves = { "Crossover" } })
	end
	for _, dir in ipairs({ 1, -1 }) do
		local plan = Possession.plan({ offense = sets, dir = dir, result = { kind = "dunk", shooter = 3, assist = 1, made = false } })
		local blk = plan.block
		assert(blk and blk.who == 10 and plan.rebound == nil, "help big blocks")
		assert(blk.tJump > plan.tCatch and blk.tBlock > plan.tShot and plan.length > blk.tBlock, "block beats")
		assert(Possession.frame(plan, blk.tBlock - 0.05).ball.owner == 3, "dunker has it until the swat")
		local f = Possession.frame(plan, blk.tBlock + 0.3)
		assert(f.ball.free and f.ball.swat and f.players[10].clip == "Block", "swatted away")
		local rimDist = math.sqrt((dir * 37.575 - f.players[10].x) ^ 2 + f.players[10].z ^ 2)
		assert(rimDist < 3, "blocker at the rim")
		for t = 0, plan.length, 0.1 do
			for _, q in ipairs(Possession.frame(plan, t).players) do
				assert(AnimClips.Clips[q.clip] and math.abs(q.x) < 47 * 0.9 and math.abs(q.z) < 25 * 0.9, "valid frame")
			end
		end
	end
end)

test("buying and opening packs", function()
	local profile = { coins = 300, players = {}, packs = {}, coaches = {} }
	local ok, err = Store.buy(profile, "Pro", 1)
	assert(not ok and err == "Not enough coins." and profile.coins == 300, "can't afford")
	assert(not Store.buy(profile, "Nope", 1) and not Store.buy(profile, "Rookie", 3), "bad pack or size")
	profile.coins = 1e6
	local before = profile.coins
	assert(Store.buy(profile, "Pro", 5), "buy bundle")
	assert(profile.coins == before - Store.price("Pro", 5) and profile.packs["Pro x5"] == 1, "bundle kept as one item")
	assert(Store.price("Pro", 5) < Store.price("Pro", 1) * 5, "bundles are cheaper per pack")
	local rng = Rng.new(11)
	local ok2, res = Store.open(profile, "Pro x5", rng)
	assert(ok2 and #res.packs == 5 and profile.packs["Pro x5"] == nil, "opens all five")
	local n = 0
	for _, pk in ipairs(res.packs) do
		assert(#pk.cards >= 1 and #pk.cards <= 2 and #pk.badges >= 1 and #pk.items == 1, "pack contents")
		for _, c in ipairs(pk.cards) do
			n += 1
			assert(c.templateId and c.id ~= c.templateId and c.anims and c.career, "owned copy")
			local v = Store.cardView(c)
			assert(v.ovr and v.ovr <= Config.MaxOvr and v.pos and not v.career, "card view")
		end
	end
	assert(#profile.players == n, "players added")
	local ids = {}
	for _, p in ipairs(profile.players) do
		assert(not ids[p.id], "unique ids")
		ids[p.id] = true
	end
	assert(not Store.open(profile, "Pro x5", rng), "can't open twice")
end)

test("match engine: box scores add up", function()
	local rng = Rng.new(11)
	for g = 1, 30 do
		local res = MatchSim.play(rng, { players = PlayerFactory.starterRoster(g) }, { players = PlayerFactory.starterRoster(g + 500) })
		assert(res.score[1] ~= res.score[2], "no ties")
		local extra = (#res.quarters - 4) * 25
		for side, key in ipairs({ "home", "away" }) do
			local pts, mins = 0, 0
			for _, l in pairs(res.box[key]) do
				assert(Stats.isConsistent(l), "box line inconsistent")
				pts += l.pts
				mins += l.min
			end
			assert(pts == res.score[side], "points match the score")
			assert(mins == 240 + extra, "minutes add up: " .. mins)
			local q = 0
			for _, qs in ipairs(res.quarters) do
				q += qs[side]
			end
			assert(q == res.score[side], "quarters add up")
		end
		local last = { 0, 0 }
		for _, ev in ipairs(res.events) do
			assert(ev.score[1] >= last[1] and ev.score[2] >= last[2], "score only goes up")
			last = ev.score
			assert(#ev.onCourt[1] == 5 and #ev.onCourt[2] == 5, "five a side")
			local pr = MatchSim.planResult(ev)
			if pr then
				local sets = { AnimSets.clips(nil), AnimSets.clips(nil), AnimSets.clips(nil), AnimSets.clips(nil), AnimSets.clips(nil) }
				local plan = Possession.plan({ offense = sets, dir = 1, result = pr })
				assert(plan.length > 0)
			end
		end
		assert(last[1] == res.score[1] and last[2] == res.score[2], "last event has the final score")
		assert(res.mvp ~= nil)
	end
end)

test("match engine: better teams win more, scores look real", function()
	local rng = Rng.new(5)
	local function team(seed, ovr)
		local rr = Rng.new(seed)
		local t = {}
		for i, pos in ipairs({ "PG", "SG", "SF", "PF", "C", "PG", "SG", "SF", "PF", "C" }) do
			t[i] = PlayerFactory.generate(rr, { rarity = "Common", pos = pos, ovr = i <= 5 and ovr or ovr - 6, finish = false })
		end
		return { players = t }
	end
	local wins, pts = 0, 0
	for g = 1, 120 do
		local res = MatchSim.play(rng, team(g, 72), team(g + 999, 63))
		if res.winner == 1 then
			wins += 1
		end
		pts += res.score[1] + res.score[2]
	end
	assert(wins > 95, "stronger team wins most: " .. wins)
	assert(pts / 120 > 170 and pts / 120 < 240, "total points per game: " .. pts / 120)
end)

print(string.format("%d passed, %d failed", passed, failed))
if failed > 0 then
	error("tests failed")
end
