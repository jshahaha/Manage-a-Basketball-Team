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
		{ 1, 100 }, { 10, 500 }, { 50, 1500 }, { 250, 5000, "Pro" }, { 1000, 15000, "AllStar" } } },
	{ id = "Downtown", name = "From Downtown", text = "Make %s threes", stat = "threesMade", tiers = {
		{ 100, 300 }, { 1000, 1500 }, { 10000, 6000, "Pro" } } },
	{ id = "Posterizer", name = "Posterizer", text = "Throw down %s dunks", stat = "dunks", tiers = {
		{ 50, 300 }, { 500, 1500 }, { 5000, 6000, "Pro" } } },
	{ id = "PackRat", name = "Pack Rat", text = "Open %s packs", stat = "packsOpened", tiers = {
		{ 1, 50 }, { 25, 500 }, { 100, 2000 }, { 500, 7500, "AllStar" } } },
	{ id = "Collector", name = "Collector", text = "Own %s different players", stat = "collection", max = true, tiers = {
		{ 15, 300 }, { 40, 1200 }, { 100, 4000, "Pro" } } },
	{ id = "Climber", name = "Climber", text = "Reach tier %s", stat = "bestTier", max = true, tierNames = {
		[2] = "Varsity", [3] = "College", [4] = "Pro", [5] = "All-League", [6] = "Hall of Fame" }, tiers = {
		{ 2, 500 }, { 3, 1000 }, { 4, 2500, "Pro" }, { 5, 6000, "AllStar" }, { 6, 15000, "AllStar" } } },
	{ id = "HotStreak", name = "Hot Streak", text = "Win %s games in a row", stat = "bestStreak", max = true, tiers = {
		{ 3, 300 }, { 5, 800 }, { 10, 3000, "Pro" } } },
	{ id = "Timeout", name = "Clipboard Coach", text = "Call %s timeouts", stat = "timeoutsCalled", tiers = {
		{ 10, 200 }, { 100, 1000 }, { 1000, 4000 } } },
	{ id = "Challenger", name = "Challenger", text = "Play %s server challenges", stat = "challengesPlayed", tiers = {
		{ 1, 100 }, { 10, 600 }, { 50, 2500 } } },
	{ id = "Legend", name = "Legend Hunter", text = "Pull %s Hall of Fame players", stat = "hofPulled", tiers = {
		{ 1, 2500 }, { 5, 10000, "AllStar" } } },
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
