--!nonstrict
-- Signature animations. Every player has one shot style, one dunk package and a set of
-- dribble moves, so two players never look the same on court. The clips live in AnimClips
-- (authored in docs/prototypes/walkout3d.js, see the Animation lab on the UI page).
--
-- Picked once when a player is generated and saved on the card (player.anims), so a player
-- keeps their moves. Flashier dunks and more moves come with rarer players.

local function import(name)
	return require(script and script.Parent:FindFirstChild(name) or "./" .. name)
end
local Config = import("Config")

local AnimSets = {}

-- minRarity: the lowest rarity that can roll it. weight: how common it is among the allowed ones.
AnimSets.Shots = {
	{ id = "Textbook", clip = "Shoot", name = "Textbook", weight = 40, text = "Dip, rise, release on the way up." },
	{ id = "Quick", clip = "ShootQuick", name = "Quick Release", weight = 20, text = "Low set point, gets it off fast." },
	{ id = "High", clip = "ShootHigh", name = "High Release", weight = 20, text = "Set point high above the head, big jump." },
	{ id = "Fade", clip = "ShootFade", name = "Fadeaway", weight = 12, minRarity = "Rare", text = "Drifts back and leans away." },
	{ id = "Set", clip = "ShootSet", name = "Set Shot", weight = 8, text = "Barely leaves the floor." },
}

AnimSets.Dunks = {
	{ id = "OneHand", clip = "Dunk", name = "One-Hand", weight = 40, text = "Takes it up with the strong hand." },
	{ id = "TwoHand", clip = "DunkTwoHand", name = "Two-Hand", weight = 35, text = "Both hands, all power." },
	{ id = "Tomahawk", clip = "DunkTomahawk", name = "Tomahawk", weight = 20, minRarity = "Rare", text = "Cocked behind the head, hammered down." },
	{ id = "Windmill", clip = "DunkWindmill", name = "Windmill", weight = 12, minRarity = "Epic", text = "The ball swings all the way round." },
	{ id = "Spin360", clip = "Dunk360", name = "360", weight = 8, minRarity = "Legendary", text = "A full turn in the air." },
}

AnimSets.Moves = {
	{ id = "Crossover", clip = "Crossover", name = "Crossover", weight = 30 },
	{ id = "InAndOut", clip = "InAndOut", name = "In-and-Out", weight = 20 },
	{ id = "Hesitation", clip = "Hesitation", name = "Hesitation", weight = 20 },
	{ id = "BetweenLegs", clip = "BetweenLegs", name = "Between the Legs", weight = 15, minRarity = "Rare" },
	{ id = "BehindBack", clip = "BehindBack", name = "Behind the Back", weight = 12, minRarity = "Rare" },
	{ id = "Spin", clip = "Spin", name = "Spin Move", weight = 10, minRarity = "Epic" },
	{ id = "Stepback", clip = "Stepback", name = "Step-Back", weight = 10, minRarity = "Epic" },
}

-- How many dribble moves a player knows, by rarity.
AnimSets.MoveCount = { Common = 1, Rare = 2, Epic = 3, Legendary = 3, HallOfFame = 4 }

local function byId(list)
	local t = {}
	for _, e in ipairs(list) do
		t[e.id] = e
	end
	return t
end
AnimSets.ShotById, AnimSets.DunkById, AnimSets.MoveById = byId(AnimSets.Shots), byId(AnimSets.Dunks), byId(AnimSets.Moves)

local function allowed(list, rarity: string)
	local order = Config.RarityById[rarity].order
	local out = {}
	for _, e in ipairs(list) do
		if not e.minRarity or Config.RarityById[e.minRarity].order <= order then
			table.insert(out, { e, e.weight })
		end
	end
	return out
end

-- Roll a player's set. rng is a Rng instance (rng:weighted({ {value, weight}, ... })).
-- Shooters lean to quick/high releases, slashers to flashier dunks.
function AnimSets.roll(rng, rarity: string, archetype: string?)
	local shots = allowed(AnimSets.Shots, rarity)
	local dunks = allowed(AnimSets.Dunks, rarity)
	for _, s in ipairs(shots) do
		if archetype == "Sniper" and (s[1].id == "Quick" or s[1].id == "High") then
			s[2] *= 2
		end
	end
	for _, d in ipairs(dunks) do
		if (archetype == "Slasher" or archetype == "PostScorer") and d[1].id ~= "OneHand" then
			d[2] *= 2
		end
	end
	local pool = allowed(AnimSets.Moves, rarity)
	local moves = {}
	for _ = 1, math.min(AnimSets.MoveCount[rarity] or 1, #pool) do
		local m = rng:weighted(pool)
		table.insert(moves, m.id)
		for i, e in ipairs(pool) do
			if e[1] == m then
				table.remove(pool, i)
				break
			end
		end
	end
	return { shot = rng:weighted(shots).id, dunk = rng:weighted(dunks).id, moves = moves }
end

-- Clip names for a player's set, with safe defaults for old saves that have no anims.
function AnimSets.clips(anims)
	anims = anims or {}
	local moves = {}
	for _, id in ipairs(anims.moves or { "Crossover" }) do
		table.insert(moves, (AnimSets.MoveById[id] or AnimSets.MoveById.Crossover).clip)
	end
	return {
		shot = (AnimSets.ShotById[anims.shot] or AnimSets.ShotById.Textbook).clip,
		dunk = (AnimSets.DunkById[anims.dunk] or AnimSets.DunkById.OneHand).clip,
		moves = moves,
	}
end

return AnimSets
