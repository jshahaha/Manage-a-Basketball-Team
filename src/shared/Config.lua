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
Config.CoachRarity = {
	Common = { styleBoost = 1.00, styles = 1 },
	Rare = { styleBoost = 1.10, styles = 1 },
	Epic = { styleBoost = 1.20, styles = 2 },
	Legendary = { styleBoost = 1.30, styles = 2 },
	HallOfFame = { styleBoost = 1.40, styles = 3 },
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
-- odds are per card and must add up to 1. count = cards in the pack.
-- guarantee = the best card is at least this rarity (that card is re-rolled with
-- only the rarities at or above it, keeping their relative odds).
-- Hall of Famers only drop from the All-Star Pack and event packs.
Config.Packs = {
	Blacktop = {
		name = "Blacktop Pack",
		kind = "players",
		count = 3,
		coins = 5000,
		robux = 29,
		odds = { Common = 0.74, Rare = 0.22, Epic = 0.04 },
	},
	Pro = {
		name = "Pro Pack",
		kind = "players",
		count = 4,
		coins = 40000,
		robux = 99,
		guarantee = "Rare",
		odds = { Common = 0.36, Rare = 0.41, Epic = 0.19, Legendary = 0.04 },
	},
	AllStar = {
		name = "All-Star Pack",
		kind = "players",
		count = 5,
		coins = 250000,
		robux = 399,
		guarantee = "Epic",
		odds = { Rare = 0.42, Epic = 0.42, Legendary = 0.145, HallOfFame = 0.015 },
	},
	Coach = {
		name = "Coach Pack",
		kind = "coach",
		count = 1,
		coins = 60000,
		robux = 149,
		odds = { Common = 0.55, Rare = 0.30, Epic = 0.12, Legendary = 0.03 },
	},
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
