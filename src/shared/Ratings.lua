--!nonstrict
-- The 20 player ratings, their 6 groups, OVR by position, and archetypes.
-- See docs/PLAYERS_AND_COACHING.md section 1.

local Ratings = {}

-- Order matters: it is the order the Player screen lists them in.
Ratings.Groups = {
	{ id = "SHO", name = "Shooting", keys = { "mid", "three", "ft" } },
	{ id = "FIN", name = "Finishing", keys = { "layup", "drivingDunk", "standingDunk", "closeShot", "post" } },
	{ id = "PLY", name = "Playmaking", keys = { "passing", "handling" } },
	{ id = "DEF", name = "Defense", keys = { "interiorD", "perimeterD", "steal", "block" } },
	{ id = "REB", name = "Rebounding", keys = { "oreb", "dreb" } },
	{ id = "ATH", name = "Athleticism", keys = { "speed", "strength", "vertical", "stamina" } },
}

Ratings.Names = {
	mid = "Mid-Range",
	three = "Three-Point",
	ft = "Free Throw",
	layup = "Layup",
	drivingDunk = "Driving Dunk",
	standingDunk = "Standing Dunk",
	closeShot = "Close Shot",
	post = "Post Moves",
	passing = "Passing",
	handling = "Ball Handling",
	interiorD = "Interior Defense",
	perimeterD = "Perimeter Defense",
	steal = "Steal",
	block = "Block",
	oreb = "Offensive Rebound",
	dreb = "Defensive Rebound",
	speed = "Speed",
	strength = "Strength",
	vertical = "Vertical",
	stamina = "Stamina",
}

Ratings.Keys = {}
Ratings.GroupOf = {}
for _, g in ipairs(Ratings.Groups) do
	for _, k in ipairs(g.keys) do
		table.insert(Ratings.Keys, k)
		Ratings.GroupOf[k] = g.id
	end
end

Ratings.MIN, Ratings.MAX = 25, 99

-- How much each rating counts toward OVR for each position. Unlisted ratings count 1.
Ratings.PositionWeights = {
	PG = { passing = 4, handling = 4, three = 3, speed = 3, mid = 2, perimeterD = 2, steal = 2, layup = 2 },
	SG = { three = 4, mid = 3, perimeterD = 3, speed = 2, handling = 2, layup = 2, ft = 2, steal = 2 },
	SF = { mid = 2, three = 2, layup = 2, drivingDunk = 2, perimeterD = 2, speed = 2, vertical = 2, closeShot = 2 },
	PF = { closeShot = 3, post = 3, interiorD = 3, dreb = 3, strength = 3, oreb = 2, standingDunk = 2, block = 2 },
	C = { standingDunk = 3, block = 4, interiorD = 4, dreb = 4, oreb = 3, strength = 3, post = 2, closeShot = 2 },
}

local function clamp(x: number): number
	return math.clamp(math.floor(x + 0.5), Ratings.MIN, Ratings.MAX)
end
Ratings.clamp = clamp

-- OVR for a ratings table at a position (before Finish bonus).
function Ratings.ovr(r: { [string]: number }, pos: string): number
	local w = Ratings.PositionWeights[pos] or {}
	local sum, total = 0, 0
	for _, k in ipairs(Ratings.Keys) do
		local weight = w[k] or 1
		sum += (r[k] or 0) * weight
		total += weight
	end
	return clamp(sum / total)
end

-- Group scores shown on the front of a card: { SHO = 85, FIN = 75, ... }
function Ratings.groupScores(r: { [string]: number }): { [string]: number }
	local out = {}
	for _, g in ipairs(Ratings.Groups) do
		local s = 0
		for _, k in ipairs(g.keys) do
			s += r[k] or 0
		end
		out[g.id] = math.floor(s / #g.keys + 0.5)
	end
	return out
end

-- Archetype from ratings. The first rule that matches wins.
Ratings.ArchetypeRules = {
	{ id = "FloorGeneral", test = function(r) return r.passing >= 80 and r.handling >= 78 end },
	{ id = "Sniper", test = function(r) return r.three >= 82 end },
	{ id = "RimProtector", test = function(r) return r.block >= 80 and r.interiorD >= 78 end },
	{ id = "Slasher", test = function(r) return r.drivingDunk >= 80 and r.speed >= 78 end },
	{ id = "GlassCleaner", test = function(r) return (r.oreb + r.dreb) / 2 >= 80 end },
	{ id = "Lockdown", test = function(r) return r.perimeterD >= 80 and r.steal >= 74 end },
	{ id = "PostScorer", test = function(r) return r.post >= 78 and r.closeShot >= 76 end },
}

function Ratings.archetype(r: { [string]: number }): string
	for _, rule in ipairs(Ratings.ArchetypeRules) do
		if rule.test(r) then
			return rule.id
		end
	end
	return "AllAround"
end

return Ratings
