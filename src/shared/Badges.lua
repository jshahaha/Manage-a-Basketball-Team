--!nonstrict
-- Badges: extra boosts you put on a player. A badge comes from a pack as an item at
-- a tier (Bronze to Hall of Fame). To put it on a player you need a free badge slot,
-- the coin cost for that tier, and the player's ratings must meet the tier's bar.
-- See docs/PLAYERS_AND_COACHING.md section 4c.

local function load(name)
	return require(script and script.Parent:FindFirstChild(name) or ("./" .. name))
end
local Config = load("Config")

local Badges = {}

-- Tiers, lowest first. need = the rating the badge's main stat needs (its second stat,
-- if any, needs 8 less). cost = coins to put it on. boost = rating points added to the
-- badge's stats in the situations the badge covers.
Badges.Tiers = {
	{ id = "Bronze", need = 60, cost = 250, boost = 2, color = "#B87333" },
	{ id = "Silver", need = 68, cost = 1000, boost = 4, color = "#A9B4C2" },
	{ id = "Gold", need = 76, cost = 3500, boost = 6, color = "#E0A800" },
	{ id = "Diamond", need = 84, cost = 10000, boost = 8, color = "#5FD3F3" },
	{ id = "HallOfFame", need = 90, cost = 30000, boost = 10, color = "#B14BFF" },
}
Badges.TierById = {}
for i, t in ipairs(Badges.Tiers) do
	t.order = i
	Badges.TierById[t.id] = t
end

-- Badge Upgrade item: the next tier up, or nil when the badge is already at the cap.
function Badges.nextTier(tierId: string, maxTier: string?): string?
	local t = Badges.TierById[tierId]
	local cap = Badges.TierById[maxTier or "Diamond"]
	if not t or not cap or t.order >= cap.order then
		return nil
	end
	return Badges.Tiers[t.order + 1].id
end

-- Badge slots by player rarity.
Badges.Slots = { Common = 1, Rare = 2, Epic = 3, Legendary = 4, HallOfFame = 5 }

-- stats[1] is the main stat, stats[2] (optional) the second.
Badges.List = {
	-- Shooting
	{ id = "Laser", group = "SHO", name = "Laser", stats = { "three" }, text = "Catch-and-shoot threes go in more." },
	{ id = "DeepRange", group = "SHO", name = "Deep Range", stats = { "three", "strength" }, text = "No penalty on threes from way past the line." },
	{ id = "PullUpPro", group = "SHO", name = "Pull-Up Pro", stats = { "mid", "handling" }, text = "Better pull-up jumpers off the dribble." },
	{ id = "IceWater", group = "SHO", name = "Ice Water", stats = { "ft" }, text = "Free throws and clutch shots ignore crowd noise and pressure." },
	-- Finishing
	{ id = "RimRattler", group = "FIN", name = "Rim Rattler", stats = { "drivingDunk", "vertical" }, text = "More dunks in traffic and more and-ones." },
	{ id = "SoftTouch", group = "FIN", name = "Soft Touch", stats = { "layup", "closeShot" }, text = "Better layups and floaters around the rim." },
	{ id = "BullyBall", group = "FIN", name = "Bully Ball", stats = { "post", "strength" }, text = "Wins post-ups against smaller defenders." },
	{ id = "Glide", group = "FIN", name = "Glide", stats = { "layup", "speed" }, text = "Finishes through contact on drives." },
	-- Playmaking
	{ id = "DimeDropper", group = "PLY", name = "Dime Dropper", stats = { "passing" }, text = "Passes lead to better shots for teammates." },
	{ id = "TightHandles", group = "PLY", name = "Tight Handles", stats = { "handling" }, text = "Fewer turnovers against pressure and the press." },
	{ id = "LobCity", group = "PLY", name = "Lob Thrower", stats = { "passing", "vertical" }, text = "Lob plays succeed more often." },
	-- Defense
	{ id = "Lockdown", group = "DEF", name = "Lockdown", stats = { "perimeterD" }, text = "The player you guard shoots worse." },
	{ id = "PaintWall", group = "DEF", name = "Paint Wall", stats = { "interiorD", "strength" }, text = "Shots at the rim get harder near this player." },
	{ id = "BallHawk", group = "DEF", name = "Ball Hawk", stats = { "steal" }, text = "More steals in passing lanes." },
	{ id = "Swat", group = "DEF", name = "Swat", stats = { "block", "vertical" }, text = "More blocks, and blocks stay in play more." },
	-- Rebounding
	{ id = "GlassEater", group = "REB", name = "Glass Eater", stats = { "dreb", "strength" }, text = "Wins more defensive rebounds." },
	{ id = "Putback", group = "REB", name = "Putback", stats = { "oreb", "vertical" }, text = "More offensive rebounds and putbacks." },
	-- Athleticism
	{ id = "Motor", group = "ATH", name = "Motor", stats = { "stamina" }, text = "Energy drains slower." },
	{ id = "Jets", group = "ATH", name = "Jets", stats = { "speed" }, text = "More fast-break points." },
	{ id = "Anchor", group = "ATH", name = "Anchor", stats = { "strength" }, text = "Holds position on screens and box-outs." },
}
Badges.ById = {}
for _, b in ipairs(Badges.List) do
	Badges.ById[b.id] = b
end

function Badges.slots(player): number
	return Badges.Slots[player.rarity] or 1
end

-- Ratings needed for a badge at a tier: { {stat, need}, ... }
function Badges.requirements(badgeId: string, tierId: string)
	local b, t = Badges.ById[badgeId], Badges.TierById[tierId]
	assert(b and t, "unknown badge or tier")
	local out = { { b.stats[1], t.need } }
	if b.stats[2] then
		table.insert(out, { b.stats[2], t.need - 8 })
	end
	return out
end

-- Can this badge item go on the player? Returns ok, reason, cost.
-- coins = how many coins the owner has.
function Badges.check(player, badgeId: string, tierId: string, coins: number)
	local t = Badges.TierById[tierId]
	if not Badges.ById[badgeId] or not t then
		return false, "Unknown badge.", 0
	end
	local equipped = player.badges or {}
	local current = equipped[badgeId]
	if current and Badges.TierById[current].order >= t.order then
		return false, "Already has this badge at " .. current .. " or better.", 0
	end
	if not current then
		local used = 0
		for _ in pairs(equipped) do
			used += 1
		end
		if used >= Badges.slots(player) then
			return false, "No free badge slots (" .. player.rarity .. " players have " .. Badges.slots(player) .. ").", 0
		end
	end
	for _, req in ipairs(Badges.requirements(badgeId, tierId)) do
		local have = player.ratings[req[1]] or 0
		if have < req[2] then
			return false, string.format("Needs %d %s (has %d).", req[2], req[1], have), t.cost
		end
	end
	if coins < t.cost then
		return false, "Needs " .. t.cost .. " coins.", t.cost
	end
	return true, nil, t.cost
end

-- Put a badge on (or upgrade it). Returns ok, reason, cost. Caller takes the coins and
-- removes the badge item from the inventory when ok.
function Badges.equip(player, badgeId: string, tierId: string, coins: number)
	local ok, reason, cost = Badges.check(player, badgeId, tierId, coins)
	if ok then
		player.badges = player.badges or {}
		player.badges[badgeId] = tierId
	end
	return ok, reason, cost
end

-- Rating points a player's badges add to `stat` (used by the sim in the badge's situations).
function Badges.boost(player, stat: string): number
	local total = 0
	for badgeId, tierId in pairs(player.badges or {}) do
		local b = Badges.ById[badgeId]
		if b and table.find(b.stats, stat) then
			total += Badges.TierById[tierId].boost
		end
	end
	return total
end

-- Roll a badge item from a tier odds table, e.g. { Bronze = 0.8, Silver = 0.2 }.
function Badges.roll(rng, tierOdds)
	local entries = {}
	for _, t in ipairs(Badges.Tiers) do
		local p = tierOdds[t.id]
		if p and p > 0 then
			table.insert(entries, { t.id, p })
		end
	end
	return { kind = "badge", badge = rng:pick(Badges.List).id, tier = rng:weighted(entries) }
end

return Badges
