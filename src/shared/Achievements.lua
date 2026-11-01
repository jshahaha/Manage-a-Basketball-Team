--!nonstrict
-- Achievements: lifetime goals with tiers (bronze, silver, gold...).
-- Each tier pays once. Progress comes from the profile's lifetime stats.

local function load(name)
	return require(script and script.Parent:FindFirstChild(name) or "./" .. name)
end
local Config = load("Config")

local Achievements = {}

-- stat: key in profile.stats. "max" stats keep the best value instead of adding.
-- tiers: { target, coins, pack? }
Achievements.List = {
	{ id = "Winner", name = "Winner", text = "Win %s games", stat = "gamesWon", tiers = {
		{ 1, 1000 }, { 10, 5000 }, { 50, 15000 }, { 250, 50000, "Pro" }, { 1000, 150000, "AllStar" } } },
	{ id = "Downtown", name = "From Downtown", text = "Make %s threes", stat = "threesMade", tiers = {
		{ 100, 3000 }, { 1000, 15000 }, { 10000, 60000, "Pro" } } },
	{ id = "Posterizer", name = "Posterizer", text = "Throw down %s dunks", stat = "dunks", tiers = {
		{ 50, 3000 }, { 500, 15000 }, { 5000, 60000, "Pro" } } },
	{ id = "PackRat", name = "Pack Rat", text = "Open %s packs", stat = "packsOpened", tiers = {
		{ 1, 500 }, { 25, 5000 }, { 100, 20000 }, { 500, 75000, "AllStar" } } },
	{ id = "Collector", name = "Collector", text = "Own %s different players", stat = "collection", max = true, tiers = {
		{ 15, 3000 }, { 40, 12000 }, { 100, 40000, "Pro" } } },
	{ id = "Climber", name = "Climber", text = "Reach tier %s", stat = "bestTier", max = true, tierNames = {
		[2] = "Varsity", [3] = "College", [4] = "Pro", [5] = "All-League", [6] = "Hall of Fame" }, tiers = {
		{ 2, 5000 }, { 3, 10000 }, { 4, 25000, "Pro" }, { 5, 60000, "AllStar" }, { 6, 150000, "AllStar" } } },
	{ id = "HotStreak", name = "Hot Streak", text = "Win %s games in a row", stat = "bestStreak", max = true, tiers = {
		{ 3, 3000 }, { 5, 8000 }, { 10, 30000, "Pro" } } },
	{ id = "Timeout", name = "Clipboard Coach", text = "Call %s timeouts", stat = "timeoutsCalled", tiers = {
		{ 10, 2000 }, { 100, 10000 }, { 1000, 40000 } } },
	{ id = "Challenger", name = "Challenger", text = "Play %s server challenges", stat = "challengesPlayed", tiers = {
		{ 1, 1000 }, { 10, 6000 }, { 50, 25000 } } },
	{ id = "Legend", name = "Legend Hunter", text = "Pull %s Hall of Fame players", stat = "hofPulled", tiers = {
		{ 1, 25000 }, { 5, 100000, "AllStar" } } },
}

Achievements.ById = {}
for _, a in ipairs(Achievements.List) do
	Achievements.ById[a.id] = a
end

-- Update lifetime stats. Use for counters (adds) and "max" stats (keeps the best).
function Achievements.recordStat(stats, stat: string, value: number)
	for _, a in ipairs(Achievements.List) do
		if a.stat == stat and a.max then
			stats[stat] = math.max(stats[stat] or 0, value)
			return
		end
	end
	stats[stat] = (stats[stat] or 0) + value
end

-- Summary for the UI: { id, name, text, progress, target, tier, tiersTotal, claimable, done }
function Achievements.view(stats, claimed)
	local out = {}
	for _, a in ipairs(Achievements.List) do
		local got = claimed[a.id] or 0 -- tiers already paid
		local value = stats[a.stat] or 0
		local nextTier = a.tiers[got + 1]
		local target = nextTier and nextTier[1] or a.tiers[#a.tiers][1]
		local shown = a.tierNames and a.tierNames[target] or tostring(target)
		table.insert(out, {
			id = a.id,
			name = a.name,
			text = string.format(a.text, shown),
			progress = math.min(value, target),
			target = target,
			tier = got,
			tiersTotal = #a.tiers,
			claimable = nextTier ~= nil and value >= nextTier[1],
			done = nextTier == nil,
			coins = nextTier and nextTier[2] or 0,
			pack = nextTier and nextTier[3] or nil,
		})
	end
	return out
end

-- Pay the next tier if it's reached. Returns { coins, pack? } or nil, reason.
function Achievements.claim(stats, claimed, id: string)
	local a = Achievements.ById[id]
	if not a then
		return nil, "No such achievement."
	end
	local got = claimed[id] or 0
	local nextTier = a.tiers[got + 1]
	if not nextTier then
		return nil, "Already complete."
	end
	if (stats[a.stat] or 0) < nextTier[1] then
		return nil, "Not reached yet."
	end
	claimed[id] = got + 1
	return { coins = nextTier[2], pack = nextTier[3], gems = Config.Gems.achievementTier }
end

return Achievements
