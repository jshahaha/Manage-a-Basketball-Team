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
-- odds are per player and must add up to 1.
Config.Packs = {
	Blacktop = {
		name = "Blacktop Pack",
		kind = "players",
		count = 3,
		coins = 5000,
		odds = { Common = 0.70, Rare = 0.24, Epic = 0.05, Legendary = 0.009, HallOfFame = 0.001 },
	},
	Pro = {
		name = "Pro Pack",
		kind = "players",
		count = 3,
		coins = 40000,
		odds = { Common = 0.35, Rare = 0.40, Epic = 0.19, Legendary = 0.055, HallOfFame = 0.005 },
	},
	AllStar = {
		name = "All-Star Pack",
		kind = "players",
		count = 3,
		coins = 250000,
		odds = { Common = 0, Rare = 0.40, Epic = 0.42, Legendary = 0.16, HallOfFame = 0.02 },
	},
	Coach = {
		name = "Coach Pack",
		kind = "coach",
		count = 1,
		coins = 60000,
		odds = { Common = 0.55, Rare = 0.30, Epic = 0.12, Legendary = 0.027, HallOfFame = 0.003 },
	},
}

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
