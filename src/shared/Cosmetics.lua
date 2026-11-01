--!nonstrict
-- Cosmetics: looks only, never stats. They come from the Cosmetic pack item, the gem shop,
-- achievements and events. Each one goes in a slot; a club equips one per slot (profile.equipped).

local Cosmetics = {}

-- Slot, who sees it, and where it shows.
Cosmetics.Slots = {
	{ id = "Jersey", name = "Jersey", where = "Your whole team's kit in matches and on cards" },
	{ id = "Shoes", name = "Shoes", where = "Team sneakers (colorway)" },
	{ id = "Accessory", name = "Accessory", where = "Headbands, sleeves and goggles on one player" },
	{ id = "Court", name = "Court", where = "Your home court floor (opponents see it when they play you)" },
	{ id = "Net", name = "Net", where = "The nets on your home court" },
	{ id = "Ball", name = "Ball", where = "The game ball at your home court" },
	{ id = "ShotTrail", name = "Shot Trail", where = "A trail behind your made threes" },
	{ id = "DunkFX", name = "Dunk Effect", where = "A burst on the rim when your team dunks" },
	{ id = "Celebration", name = "Celebration", where = "After a big play or a win" },
	{ id = "Walkout", name = "Walkout Effect", where = "Your Legendary and Hall of Fame pack walkouts" },
	{ id = "CardFrame", name = "Card Frame", where = "The border on your player cards" },
	{ id = "Banner", name = "Club Banner", where = "Behind your club name in the lobby, PLAY screen and leaderboards" },
	{ id = "CoachFit", name = "Coach Outfit", where = "Your avatar on the bench" },
	{ id = "Mascot", name = "Mascot", where = "Dances courtside at your home games" },
	{ id = "WalkInMusic", name = "Walk-in Music", where = "Plays as your team runs out" },
}

-- Rarity of cosmetics (separate from player rarity). weight = chance inside the Cosmetic pack item.
Cosmetics.Rarities = {
	{ id = "Common", weight = 60, gems = 30 },
	{ id = "Rare", weight = 28, gems = 80 },
	{ id = "Epic", weight = 10, gems = 200 },
	{ id = "Legendary", weight = 2, gems = 500 },
}

-- id, slot, name, rarity, note. Names are original; nothing uses real team or league branding.
Cosmetics.List = {
	-- Jerseys
	{ "JerseyClassic", "Jersey", "Classic", "Common", "Plain kit in your club colors" },
	{ "JerseyPinstripe", "Jersey", "Pinstripe", "Common" },
	{ "JerseyRetro", "Jersey", "Retro '70s", "Rare", "Short shorts, thick collar stripes" },
	{ "JerseyScript", "Jersey", "Throwback Script", "Rare", "Club name in old-school script" },
	{ "JerseyCamo", "Jersey", "Court Camo", "Rare" },
	{ "JerseySunset", "Jersey", "Sunset Fade", "Epic", "Gradient from orange to purple" },
	{ "JerseyNeon", "Jersey", "Neon City", "Epic", "Glows on night courts" },
	{ "JerseyGalaxy", "Jersey", "Galaxy", "Legendary", "Animated stars" },
	-- Shoes
	{ "ShoesWhite", "Shoes", "Clean Whites", "Common" },
	{ "ShoesTeam", "Shoes", "Team Colorway", "Common" },
	{ "ShoesHighTop", "Shoes", "Retro High-Tops", "Rare" },
	{ "ShoesLava", "Shoes", "Lava Soles", "Epic" },
	{ "ShoesGold", "Shoes", "Gold Laces", "Legendary" },
	-- Accessories
	{ "Headband", "Accessory", "Headband", "Common" },
	{ "Wristbands", "Accessory", "Wristbands", "Common" },
	{ "ArmSleeve", "Accessory", "Shooting Sleeve", "Common" },
	{ "LegSleeve", "Accessory", "Leg Sleeve", "Rare" },
	{ "Goggles", "Accessory", "Sport Goggles", "Rare" },
	{ "FacePaint", "Accessory", "Game-Day Face Paint", "Epic" },
	-- Courts
	{ "CourtHardwood", "Court", "Hardwood", "Common" },
	{ "CourtBlacktop", "Court", "Park Blacktop", "Common", "Chain-link fence and painted lines" },
	{ "CourtRooftop", "Court", "Rooftop", "Rare", "City skyline behind the hoop" },
	{ "CourtBeach", "Court", "Boardwalk", "Rare", "Sand at the sidelines, ocean behind" },
	{ "CourtGym", "Court", "Old School Gym", "Rare", "Wood bleachers and a hanging scoreboard" },
	{ "CourtNeon", "Court", "Neon Night", "Epic", "Glowing lines" },
	{ "CourtIce", "Court", "Frozen Lake", "Epic" },
	{ "CourtSpace", "Court", "Zero-G Arena", "Legendary", "Stars under a glass floor" },
	-- Nets
	{ "NetWhite", "Net", "White Nylon", "Common" },
	{ "NetChain", "Net", "Chain Net", "Rare", "Jingles on a swish" },
	{ "NetNeon", "Net", "Neon Net", "Epic" },
	-- Balls
	{ "BallClassic", "Ball", "Classic Orange", "Common" },
	{ "BallTricolor", "Ball", "Tricolor", "Rare", "Red, white and blue panels" },
	{ "BallStreet", "Ball", "Street Black", "Rare" },
	{ "BallGlow", "Ball", "Glow Ball", "Epic" },
	{ "BallChrome", "Ball", "Chrome", "Legendary" },
	-- Shot trails
	{ "TrailSpark", "ShotTrail", "Sparks", "Rare" },
	{ "TrailFire", "ShotTrail", "Fire", "Epic" },
	{ "TrailIce", "ShotTrail", "Frost", "Epic" },
	{ "TrailRainbow", "ShotTrail", "Rainbow", "Legendary" },
	-- Dunk effects
	{ "DunkShake", "DunkFX", "Rim Shake", "Common" },
	{ "DunkSparks", "DunkFX", "Rim Sparks", "Rare" },
	{ "DunkLightning", "DunkFX", "Lightning", "Epic" },
	{ "DunkShatter", "DunkFX", "Glass Shatter", "Legendary", "The backboard cracks (and fixes itself)" },
	-- Celebrations
	{ "CelebFist", "Celebration", "Fist Pump", "Common" },
	{ "CelebChestBump", "Celebration", "Chest Bump", "Common" },
	{ "CelebGoggles", "Celebration", "Three Goggles", "Rare" },
	{ "CelebShimmy", "Celebration", "Shoulder Shimmy", "Rare" },
	{ "CelebFlex", "Celebration", "Muscle Flex", "Rare" },
	{ "CelebBow", "Celebration", "Take a Bow", "Epic" },
	{ "CelebRobot", "Celebration", "The Robot", "Epic" },
	{ "CelebBench", "Celebration", "Bench Mob", "Legendary", "The whole bench storms out to celebrate" },
	-- Walkout effects
	{ "WalkSmoke", "Walkout", "Smoke Tunnel", "Common" },
	{ "WalkConfetti", "Walkout", "Confetti", "Rare" },
	{ "WalkFireworks", "Walkout", "Fireworks", "Epic" },
	{ "WalkLightning", "Walkout", "Lightning Strike", "Legendary" },
	-- Card frames
	{ "FrameClean", "CardFrame", "Clean", "Common" },
	{ "FrameHolo", "CardFrame", "Holo Edge", "Rare" },
	{ "FrameFlame", "CardFrame", "Flame Edge", "Epic" },
	{ "FrameDiamond", "CardFrame", "Diamond Cut", "Legendary" },
	-- Club banners
	{ "BannerStripes", "Banner", "Stripes", "Common" },
	{ "BannerCity", "Banner", "City Lights", "Rare" },
	{ "BannerTrophy", "Banner", "Trophy Case", "Epic" },
	-- Coach outfits
	{ "CoachPolo", "CoachFit", "Team Polo", "Common" },
	{ "CoachTracksuit", "CoachFit", "Tracksuit", "Common" },
	{ "CoachSuit", "CoachFit", "Sideline Suit", "Rare" },
	{ "CoachSweater", "CoachFit", "Sweater Vest", "Rare" },
	{ "CoachGold", "CoachFit", "Gold Blazer", "Legendary" },
	-- Mascots
	{ "MascotBird", "Mascot", "Hoops Hawk", "Rare" },
	{ "MascotBear", "Mascot", "Dancing Bear", "Epic" },
	{ "MascotRobot", "Mascot", "Hoop Bot", "Legendary" },
	-- Walk-in music
	{ "MusicHype", "WalkInMusic", "Hype Drums", "Common" },
	{ "MusicBrass", "WalkInMusic", "Brass Band", "Rare" },
	{ "MusicSynth", "WalkInMusic", "Synthwave", "Epic" },
}

Cosmetics.ById = {}
Cosmetics.BySlot = {}
for i, c in ipairs(Cosmetics.List) do
	local item = { id = c[1], slot = c[2], name = c[3], rarity = c[4], note = c[5] }
	Cosmetics.List[i] = item
	Cosmetics.ById[item.id] = item
	Cosmetics.BySlot[item.slot] = Cosmetics.BySlot[item.slot] or {}
	table.insert(Cosmetics.BySlot[item.slot], item)
end
Cosmetics.RarityById = {}
for _, r in ipairs(Cosmetics.Rarities) do
	Cosmetics.RarityById[r.id] = r
end

-- Roll a cosmetic for the pack item: rarity first, then any cosmetic of that rarity.
function Cosmetics.roll(rng)
	local entries = {}
	for _, r in ipairs(Cosmetics.Rarities) do
		table.insert(entries, { r.id, r.weight })
	end
	local rarity = rng:weighted(entries)
	local pool = {}
	for _, c in ipairs(Cosmetics.List) do
		if c.rarity == rarity then
			table.insert(pool, c)
		end
	end
	return rng:pick(pool)
end

-- Equip if owned and the slot matches. Returns ok, reason.
function Cosmetics.equip(owned, equipped, id: string)
	local c = Cosmetics.ById[id]
	if not c then
		return false, "No such cosmetic."
	end
	if not owned[id] then
		return false, "You don't own it."
	end
	equipped[c.slot] = id
	return true
end

return Cosmetics
