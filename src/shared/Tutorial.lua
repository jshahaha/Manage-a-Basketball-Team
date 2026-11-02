--!nonstrict
-- First-time tutorial. Assistant coach "Coach Dee" walks a new club through the core loop,
-- one step at a time. Each step finishes on a game event (the same events quests use), so
-- the player learns by doing it for real. It can be skipped at any time; skipping keeps what
-- was already earned but gives up the finish reward.
--
-- State saved on the profile: profile.tutorial = { step, gifted, done, skipped, lessons = { [id] = true }, tips = { [id] = true } }

local Tutorial = {}

-- id, event that finishes it, what to highlight, Coach Dee's line, gift when the step starts,
-- reward when it ends.
Tutorial.Steps = {
	{
		id = "club",
		event = "clubCreated",
		target = "ClubCreator",
		title = "Make your club",
		text = "Welcome, coach! Every team needs a name. Pick one, then your colors and logo.",
	},
	{
		id = "pack",
		event = "packsOpened",
		target = "Inventory",
		title = "Open your first pack",
		text = "Here's a Rookie Pack on the house. Open it from your inventory and see who you got.",
		gift = { packs = { Rookie = 1 } },
	},
	{
		id = "lineup",
		event = "lineupSet",
		target = "Team",
		title = "Set your starting five",
		text = "Drag your new player into the starting five. The top five play the most.",
	},
	{
		id = "badge",
		event = "badgeEquipped",
		target = "BadgeApplier",
		title = "Put on a badge",
		text = "Badges make players better in certain moments. Tap the badge you pulled, then a player. Putting one on is free, but taking it off costs coins, so choose well.",
	},
	{
		id = "minutes",
		event = "minutesSet",
		target = "Rotation",
		title = "Share the minutes",
		text = "You have 240 minutes to split between ten players. Tap Auto Minutes for now. Tired players play worse, so don't leave anyone out there all game.",
	},
	{
		id = "game",
		event = "tutorialGame",
		target = "Play",
		title = "Play your first game",
		text = "Time for tip-off! This warm-up game doesn't count for Elo. I'll pause it whenever there's something new to learn.",
		reward = { coins = 250 },
	},
	{
		id = "train",
		event = "trainingStarted",
		target = "Training",
		title = "Start training",
		text = "Players get better in training, even while you're offline. Put a player in a slot and pick a focus.",
	},
	{
		id = "scout",
		event = "scoutViewed",
		target = "Scouting",
		title = "Meet your scouts",
		text = "Your scouts find players you can sign for coins. You never see their OVR, so read the clues. Better scouts reveal more.",
	},
	{
		id = "quests",
		event = "questsViewed",
		target = "Quests",
		title = "Daily quests",
		text = "Three new quests every day. They pay coins, and clearing all three pays gems too. That's it, coach. Go win some games!",
	},
}

-- Match lessons: taught inside the warm-up game (step "game"). The warm-up is scripted so each
-- moment happens on cue, and the game FREEZES (clock and sim) until the player does the thing.
-- Each lesson dims the screen except `focus` (a box around it), points an arrow at it, shows
-- Coach Dee's line, and waits for `action` on `focus`:
--   "tap"  tap the focus
--   "drag" drag from focus to dropOn
--   "time" stop a meter inside its green zone (any stop is accepted, the result is explained)
--   "ok"   just read and tap Got it
-- cue = when the scripted warm-up triggers it. Order matters: one new idea at a time.
Tutorial.MatchLessons = {
	{
		id = "watch",
		cue = "tipoff",
		focus = "BallTag",
		arrow = "down",
		action = "ok",
		text = "You're the coach, so you don't control players. The tag shows who has the ball. Your job is the calls.",
	},
	{
		id = "coachCall",
		cue = "coachCall",
		focus = "CoachCall",
		arrow = "up",
		action = "tap",
		text = "A Coach's Call! They're doubling your star. Kicking it out finds the open shooter. Normally you get 3 seconds, so be quick.",
		script = { call = "double", answer = "Kick it out" },
	},
	{
		id = "heatCheck",
		cue = "heatCheck",
		focus = "FeedButton",
		arrow = "left",
		action = "tap",
		text = "Three makes in a row: he's on fire! Tap Feed him so he shoots more for a minute.",
		script = { makes = 3 },
	},
	{
		id = "lockHimUp",
		cue = "oppHot",
		focus = "Matchups",
		dropOn = "HotOpponent",
		arrow = "right",
		action = "drag",
		text = "Now THEIR guard is hot. Drag your best defender onto him. The switch happens at the next dead ball.",
		script = { oppMakes = 3 },
	},
	{
		id = "timeout",
		cue = "timeoutPrompt",
		focus = "TimeoutButton",
		arrow = "down",
		action = "tap",
		text = "They're on a run. Call a timeout to stop it! You have 4 a game.",
		script = { oppRun = 8 },
	},
	{
		id = "timeoutScreen",
		cue = "timeoutOpen",
		focus = "TimeoutPanel",
		arrow = "left",
		action = "ok",
		text = "In a timeout you can sub, change your play style, call the next play and give a team talk. Your five also get energy back.",
	},
	{
		id = "tired",
		cue = "quarterBreak",
		focus = "TiredPlayer",
		dropOn = "BenchPlayer",
		arrow = "up",
		action = "drag",
		text = "Quarter break! See the red energy bar? Tired players miss more. Drag a bench player onto him to sub.",
		script = { tiredEnergy = 0.3 },
	},
	{
		id = "clutch",
		cue = "clutchShot",
		focus = "ClutchMeter",
		arrow = "up",
		action = "time",
		text = "Down 1, last shot! Tap when the marker hits the green. Ratings matter most, but good timing helps.",
		script = { margin = -1, secondsLeft = 6 },
	},
}

-- First-time tips in real games: a smaller box and arrow, shown once each, the first time the
-- moment happens. The game doesn't freeze; the tip fades after `seconds` or on tap.
Tutorial.Tips = {
	{ id = "playStyle", cue = "quarterBreak", focus = "PlayStyle", seconds = 5, text = "Styles counter each other. If theirs is beating yours, switch here." },
	{ id = "cold", cue = "coldPlayer", focus = "SitButton", seconds = 5, text = "Missed 4 in a row: he's cold. Tap Sit him to rest him." },
	{ id = "challenge", cue = "badCall", focus = "ChallengeButton", seconds = 6, text = "Think the ref got it wrong? Challenge once a game. If you lose, it costs a timeout." },
	{ id = "clutchTimeout", cue = "clutchTimeout", focus = "FinalPlay", seconds = 6, text = "Clutch Timeout: you pick the last play yourself." },
	{ id = "homeCourt", cue = "awayFreeThrow", focus = "Crowd", seconds = 4, text = "Your home crowd makes away free throws harder." },
	{ id = "badgeApplier", cue = "firstBadgeCard", focus = "BadgesButton", seconds = 6, text = "You got a badge card! Put it on a player in the Badge Applier." },
	{ id = "newPlayer", cue = "firstNewPlayer", focus = "TeamButton", seconds = 6, text = "New players start on the bench. Add them to your lineup in Team." },
}

Tutorial.LessonById, Tutorial.TipById = {}, {}
for _, l in ipairs(Tutorial.MatchLessons) do
	Tutorial.LessonById[l.id] = l
end
for _, t in ipairs(Tutorial.Tips) do
	Tutorial.TipById[t.id] = t
end

-- The lesson to show for a warm-up cue (nil if none or already seen). Marks it seen.
function Tutorial.lessonFor(state, cue: string)
	state.lessons = state.lessons or {}
	for _, l in ipairs(Tutorial.MatchLessons) do
		if l.cue == cue and not state.lessons[l.id] then
			state.lessons[l.id] = true
			return l
		end
	end
	return nil
end

-- The first-time tip for a real-game cue (nil if seen). Marks it seen. Works after the
-- tutorial is done or skipped, since that's when these moments first come up.
function Tutorial.tipFor(state, cue: string)
	state.tips = state.tips or {}
	for _, t in ipairs(Tutorial.Tips) do
		if t.cue == cue and not state.tips[t.id] then
			state.tips[t.id] = true
			return t
		end
	end
	return nil
end

-- "How to play" button: replay the lessons in the next warm-up.
function Tutorial.resetLessons(state)
	state.lessons = {}
end

-- Paid once when the last step is done (not when skipped). 20 gems + the 10 you start with
-- is exactly one Common cosmetic, so the gem shop makes sense from day one.
Tutorial.FinishReward = { coins = 250, gems = 20, packs = { Blacktop = 1 } }

Tutorial.ById = {}
for i, s in ipairs(Tutorial.Steps) do
	s.index = i
	Tutorial.ById[s.id] = s
end

function Tutorial.newState()
	return { step = 1, gifted = {}, done = false, skipped = false }
end

-- The step the player is on, or nil when finished or skipped.
function Tutorial.current(state)
	if not state or state.done or state.skipped then
		return nil
	end
	return Tutorial.Steps[state.step]
end

-- Gift for the current step, once. Call when the step is shown. Returns a reward table or nil.
function Tutorial.takeGift(state)
	local s = Tutorial.current(state)
	if not s or not s.gift or state.gifted[s.id] then
		return nil
	end
	state.gifted[s.id] = true
	return s.gift
end

local function merge(into, add)
	if not add then
		return
	end
	for k, v in pairs(add) do
		if k == "packs" then
			into.packs = into.packs or {}
			for id, n in pairs(v) do
				into.packs[id] = (into.packs[id] or 0) + n
			end
		else
			into[k] = (into[k] or 0) + v
		end
	end
end

-- Report a game event. Only the current step's event counts.
-- Returns rewards to grant (or nil), and the finished step.
function Tutorial.record(state, event: string)
	local s = Tutorial.current(state)
	if not s or s.event ~= event then
		return nil
	end
	local rewards = {}
	merge(rewards, s.reward)
	state.step += 1
	if state.step > #Tutorial.Steps then
		state.done = true
		merge(rewards, Tutorial.FinishReward)
	end
	return next(rewards) and rewards or nil, s
end

function Tutorial.skip(state)
	if not state.done then
		state.skipped = true
	end
end

-- For the UI: "Step 3 of 9"
function Tutorial.progress(state)
	return math.min(state.step, #Tutorial.Steps), #Tutorial.Steps
end

return Tutorial
