--!nonstrict
-- Daily quests: 3 a day, picked from a pool, reset at 00:00 UTC, paid in coins.
-- Pure logic; the server calls Quests.record() when something happens.

local Rng = require(script and script.Parent:FindFirstChild("Rng") or "./Rng")

local Quests = {}

Quests.PerDay = 3

-- event: what the game reports. targets: possible amounts. coins: reward per target.
Quests.Pool = {
	{ id = "play", event = "gamesPlayed", text = "Play %d games", targets = { 3, 5 }, coins = { 1500, 2500 } },
	{ id = "win", event = "gamesWon", text = "Win %d games", targets = { 2, 3 }, coins = { 2500, 4000 } },
	{ id = "threes", event = "threesMade", text = "Make %d threes", targets = { 15, 30 }, coins = { 2000, 3500 } },
	{ id = "dunks", event = "dunks", text = "Throw down %d dunks", targets = { 8, 15 }, coins = { 2000, 3500 } },
	{ id = "points", event = "pointsScored", text = "Score %d points", targets = { 250, 500 }, coins = { 2000, 3500 } },
	{ id = "blowout", event = "blowoutWins", text = "Win %d game by 15 or more", targets = { 1 }, coins = { 3000 } },
	{ id = "packs", event = "packsOpened", text = "Open %d packs", targets = { 1, 2 }, coins = { 1500, 2500 } },
	{ id = "train", event = "trainingStarted", text = "Start %d training sessions", targets = { 2, 3 }, coins = { 1500, 2000 } },
	{ id = "timeouts", event = "timeoutsCalled", text = "Call %d timeouts", targets = { 3, 6 }, coins = { 1000, 1800 } },
	{ id = "challenge", event = "challengesPlayed", text = "Play %d server challenge", targets = { 1 }, coins = { 2500 } },
}

function Quests.dayNumber(now: number): number
	return now // 86400
end

function Quests.secondsUntilReset(now: number): number
	return 86400 - now % 86400
end

-- The same player gets the same quests all day, on any server.
function Quests.rollDay(userId: number, day: number)
	local rng = Rng.new((userId * 7919 + day * 104729) % 2147483646 + 1)
	local pool = table.clone(Quests.Pool)
	local list = {}
	for _ = 1, Quests.PerDay do
		local q = table.remove(pool, rng:int(1, #pool))
		local t = rng:int(1, #q.targets)
		table.insert(list, {
			id = q.id,
			event = q.event,
			text = string.format(q.text, q.targets[t]),
			target = q.targets[t],
			coins = q.coins[t],
			progress = 0,
			claimed = false,
		})
	end
	return { day = day, list = list }
end

-- Returns state for today, rolling new quests if the day changed.
function Quests.ensureDay(state, userId: number, now: number)
	local day = Quests.dayNumber(now)
	if not state or state.day ~= day then
		return Quests.rollDay(userId, day)
	end
	return state
end

-- Add progress. Returns the quests this call completed (for a "Quest complete!" toast).
function Quests.record(state, event: string, amount: number?)
	local done = {}
	for _, q in ipairs(state.list) do
		if q.event == event and q.progress < q.target then
			q.progress = math.min(q.target, q.progress + (amount or 1))
			if q.progress >= q.target then
				table.insert(done, q)
			end
		end
	end
	return done
end

-- Claim a finished quest. Returns coins, or nil and a reason.
function Quests.claim(state, index: number): (number?, string?)
	local q = state.list[index]
	if not q then
		return nil, "No such quest."
	end
	if q.claimed then
		return nil, "Already claimed."
	end
	if q.progress < q.target then
		return nil, "Not finished yet."
	end
	q.claimed = true
	return q.coins
end

-- True once all of today's quests are claimed: the server then pays Config.Gems.dailySweep once.
function Quests.swept(state): boolean
	for _, q in ipairs(state.list) do
		if not q.claimed then
			return false
		end
	end
	return #state.list > 0
end

return Quests
