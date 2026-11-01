--!nonstrict
-- Game-wide tuning values. Pure data, so it works in Roblox and in the luau CLI tests.
-- Design reference: docs/MAIN_GAME_IDEA.md and docs/PLAYERS_AND_COACHING.md

local Config = {}

Config.DataStoreName = "Profiles_v1"
Config.DataVersion = 1

-- Economy -----------------------------------------------------------------
Config.StartingCoins = 2500
Config.StartingFans = 0
Config.MaxCoins = 1e12

-- Gems: the premium currency. Earned slowly by playing, or bought with Robux.
-- They buy scout team upgrades, cosmetics, the Gem Pack and skipping training timers.
-- They never buy players or badges directly, so the market stays coin-based.
Config.StartingGems = 25
Config.Gems = {
	dailySweep = 5, -- claim all 3 daily quests
	achievementTier = 5, -- every achievement tier
	eloTier = { [2] = 20, [3] = 40, [4] = 80, [5] = 150, [6] = 300 }, -- first time reaching each Elo tier
	skipTrainingPerHour = 10, -- finish a training session early (rounded up to the hour)
}

-- Collection --------------------------------------------------------------
Config.ClubCapacity = 50
Config.MatchdaySize = 10 -- 5 starters + 5 bench
Config.StartersCount = 5
Config.GameMinutes = 48
Config.TeamMinutes = 240 -- 5 players x 48 minutes

Config.Positions = { "PG", "SG", "SF", "PF", "C" }
-- Positions a player can also play (besides their main one), by main position.
Config.SecondaryPositions = {
	PG = { "SG" },
	SG = { "PG", "SF" },
	SF = { "SG", "PF" },
	PF = { "SF", "C" },
	C = { "PF" },
}
-- Playing out of position: anyone can play anywhere. Listed positions (main + altPos)
-- have no penalty. Otherwise OVR drops by steps away on the PG-SG-SF-PF-C line.
Config.OutOfPositionPenalty = { 3, 6, 10, 15 }
-- Chance an Epic or better player is Positionless (no penalty at any position).
Config.PositionlessChance = 0.05

-- Coaches have no rating, only rarity. Rarity makes their play style hit harder
-- (multiplier on the style edge) and decides how many styles they know.
-- plays = how many plays from their styles' playbook they know; playBonus = extra
-- success chance when one of their plays is called.
Config.CoachRarity = {
	Common = { styleBoost = 1.00, styles = 1, plays = 2, playBonus = 0.00 },
	Rare = { styleBoost = 1.10, styles = 1, plays = 3, playBonus = 0.02 },
	Epic = { styleBoost = 1.20, styles = 2, plays = 4, playBonus = 0.04 },
	Legendary = { styleBoost = 1.30, styles = 2, plays = 5, playBonus = 0.06 },
	HallOfFame = { styleBoost = 1.40, styles = 3, plays = 6, playBonus = 0.08 },
}

-- Playbook: plays each offensive style unlocks, in the order a coach learns them.
-- Diagrams for each play are on the UI page (Playbook section).
Config.Playbook = {
	FiveOut = { "DriveAndKick", "Floppy", "SpainPickAndRoll" },
	PaceAndSpace = { "EarlyDragThree", "DriveAndKick", "Lob" },
	InsideOut = { "PostUp", "HornsFlare", "BackdoorCut" },
	PickAndRoll = { "PickAndRoll", "Lob", "SpainPickAndRoll" },
	Motion = { "BackdoorCut", "HornsFlare", "Floppy" },
	IsoStar = { "Isolation", "PickAndRoll", "PostUp" },
}

-- Weight range in lb by position.
Config.Weight = { PG = { 170, 205 }, SG = { 180, 215 }, SF = { 200, 235 }, PF = { 220, 255 }, C = { 235, 280 } }
-- Nationalities for generated players: ISO code and how common it is.
Config.Nations = {
	{ "US", 50 }, { "CA", 6 }, { "FR", 5 }, { "AU", 4 }, { "DE", 3 }, { "ES", 3 }, { "RS", 3 },
	{ "NG", 3 }, { "GR", 2 }, { "SI", 2 }, { "LT", 2 }, { "BR", 2 }, { "AR", 2 }, { "JP", 2 },
	{ "PH", 2 }, { "CN", 2 }, { "TR", 2 }, { "SN", 2 }, { "GB", 2 }, { "IT", 1 }, { "CM", 1 },
}

-- Game length (real seconds per quarter; the game clock always shows 12:00).
Config.QuarterSeconds = { queued = 45, challenge = 75 }
Config.TimeoutsPerGame = 4
Config.TimeoutSeconds = 15
Config.QuarterBreakSeconds = 12

-- Home court edge. Small on purpose: home teams should win about 54% of even games.
Config.HomeCourt = {
	pointsEdge = 1, -- projection bonus
	awayFreeThrowPenalty = 0.03, -- crowd noise: away FT% minus 3 points
	awayClutchFreeThrowPenalty = 0.06, -- in the last 2 game-minutes of a close game
	homeEnergyRecovery = 1.05, -- home players recover energy on the bench 5% faster
	homeCoachsCallSeconds = 1, -- home coach gets 1 extra second on Coach's Calls
}

-- Highest OVR any card can have right now, Finishes and training included.
-- Raise this (and the ranges below) in a future update to add stronger cards.
Config.MaxOvr = 93

-- Rarity: OVR range each rarity generates in, and its UI color.
Config.Rarities = {
	{ id = "Common", min = 50, max = 64, color = "#9AA3AE" },
	{ id = "Rare", min = 65, max = 72, color = "#3B8BFF" },
	{ id = "Epic", min = 73, max = 79, color = "#A24BFF" },
	{ id = "Legendary", min = 80, max = 86, color = "#FF8A1F" },
	{ id = "HallOfFame", min = 87, max = 91, color = "#E0A800" },
}
Config.RarityById = {}
for i, r in ipairs(Config.Rarities) do
	r.order = i
	Config.RarityById[r.id] = r
end

-- Finishes: rare cosmetic variants that also add OVR.
Config.Finishes = {
	{ id = "HotHand", chance = 0.04, bonus = 3 },
	{ id = "IceVeins", chance = 0.01, bonus = 5 },
	{ id = "Prism", chance = 0.002, bonus = 8 },
}

-- Packs -------------------------------------------------------------------
-- A ladder: each rarity drops from at most 3 neighbouring packs, and Hall of Famers
-- only from the top 2. Badge tiers climb the same way. odds are per player card and
-- add up to 1. count = players per pack, badges = badge items per pack.
-- Cards come from the fixed card list in Catalog.lua, so players can see every card
-- a pack can give. order = position in the shop.
-- Player packs: `count` players (plus one more with `extraPlayerChance`), a random number of
-- badges in the `badges` range, and `items` extra items rolled from Config.PackItems.
Config.Packs = {
	Rookie = {
		name = "Rookie Pack", kind = "players", order = 1, count = 1, badges = { 1, 2 }, items = 1, coins = 2500, robux = 19,
		odds = { Common = 0.85, Rare = 0.15 },
		badgeOdds = { Bronze = 0.80, Silver = 0.20 },
	},
	Blacktop = {
		name = "Blacktop Pack", kind = "players", order = 2, count = 1, badges = { 1, 2 }, items = 1, coins = 10000, robux = 49,
		odds = { Common = 0.60, Rare = 0.33, Epic = 0.07 },
		badgeOdds = { Bronze = 0.55, Silver = 0.38, Gold = 0.07 },
	},
	Pro = {
		name = "Pro Pack", kind = "players", order = 3, count = 1, extraPlayerChance = 0.35, badges = { 1, 2 }, items = 1, coins = 40000, robux = 99,
		odds = { Rare = 0.60, Epic = 0.33, Legendary = 0.07 },
		badgeOdds = { Silver = 0.55, Gold = 0.38, Diamond = 0.07 },
	},
	AllStar = {
		name = "All-Star Pack", kind = "players", order = 4, count = 1, extraPlayerChance = 0.5, badges = { 2, 3 }, items = 1, coins = 150000, robux = 249,
		odds = { Epic = 0.70, Legendary = 0.27, HallOfFame = 0.03 },
		badgeOdds = { Gold = 0.70, Diamond = 0.27, HallOfFame = 0.03 },
	},
	HallOfFame = {
		name = "Hall of Fame Pack", kind = "players", order = 5, count = 2, badges = { 2, 3 }, items = 1, coins = 500000, robux = 599,
		odds = { Legendary = 0.88, HallOfFame = 0.12 },
		badgeOdds = { Diamond = 0.88, HallOfFame = 0.12 },
	},
	Badge = {
		name = "Badge Pack", kind = "badges", order = 6, count = 0, badges = { 3, 4 }, coins = 20000, robux = 59,
		odds = {},
		badgeOdds = { Bronze = 0.50, Silver = 0.35, Gold = 0.13, Diamond = 0.02 },
	},
	Coach = {
		name = "Coach Pack", kind = "coach", order = 7, count = 1, coins = 60000, robux = 149,
		odds = { Common = 0.60, Rare = 0.30, Epic = 0.09, Legendary = 0.01 },
	},
	EliteCoach = {
		name = "Elite Coach Pack", kind = "coach", order = 8, count = 1, coins = 250000, robux = 399,
		odds = { Rare = 0.45, Epic = 0.40, Legendary = 0.13, HallOfFame = 0.02 },
	},
}

-- Bundles: buy several of the same pack at once for less per pack. A bundle is its own
-- item in your inventory (one "5x Pro Bundle" box), not 5 loose packs.
-- The extra item in every player pack. weight = chance out of the total.
Config.PackItems = {
	{ id = "Cosmetic", name = "Cosmetic", weight = 35, text = "A jersey, court floor, ball or celebration." },
	{ id = "CoinPouch", name = "Coin Pouch", weight = 30, text = "Gives back 10 to 30% of the pack's coin price." },
	-- Badge Upgrades have their own rarity: the rarer the upgrade, the higher the tier it works on.
	-- A Bronze Upgrade turns a Bronze badge into Silver, and so on. The player still needs the stats.
	{ id = "BadgeUpgrade", name = "Badge Upgrade", weight = 20,
		text = "Moves one badge up a tier. Its rarity decides which tier it works on.",
		rarities = {
			{ from = "Bronze", weight = 60 },
			{ from = "Silver", weight = 28 },
			{ from = "Gold", weight = 10 },
			{ from = "Diamond", weight = 2 }, -- Diamond -> Hall of Fame
		} },
	{ id = "ScoutTicket", name = "Scout Ticket", weight = 15, text = "One free Scouting Report refresh." },
}

Config.Bundles = {
	{ size = 1, discount = 0 },
	{ size = 5, discount = 0.10 },
	{ size = 20, discount = 0.20 },
}

-- Walkout cutscene plays for cards of this rarity or better.
Config.WalkoutRarity = "Legendary"

-- Play styles (known by coaches) -------------------------------------------
Config.OffenseStyles = { "FiveOut", "PaceAndSpace", "InsideOut", "PickAndRoll", "Motion", "IsoStar" }
Config.DefenseStyles = { "ManToMan", "TwoThreeZone", "SwitchEverything", "DropCoverage", "FullCourtPress" }

-- Elo ---------------------------------------------------------------------
Config.Elo = {
	start = 1000,
	kPlacement = 40,
	kNormal = 24,
	placementGames = 10,
	ownerKScale = 0.5, -- a saved team's owner is offline, so their Elo moves at half K
	shieldGames = 3, -- games of demotion protection after reaching a new tier
	searchRange = 100,
	searchStep = 50,
	searchMax = 400,
}
Config.Tiers = {
	{ id = "Blacktop", min = -math.huge, coinMult = 1.0 },
	{ id = "Varsity", min = 1100, coinMult = 1.2 },
	{ id = "College", min = 1300, coinMult = 1.4 },
	{ id = "Pro", min = 1500, coinMult = 1.7 },
	{ id = "AllLeague", min = 1700, coinMult = 2.0 },
	{ id = "HallOfFame", min = 1900, coinMult = 2.5 },
}

-- Codes -------------------------------------------------------------------
Config.Codes = {
	maxCoins = 10000000, -- safety cap per code, catches typos like coins=50000000000
	maxFans = 1000000,
	maxPacksEach = 10,
	maxBoostMinutes = 24 * 60,
	boostKinds = { DoubleCoins = true, DoubleFans = true },
	triesPerMinute = 6,
	refreshSeconds = 60,
}

return Config
