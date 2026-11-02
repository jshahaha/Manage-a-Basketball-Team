--!nonstrict
-- Sound registry: every sound and commentator line, by name. See docs/AUDIO.md.
--
-- TO ADD A SOUND: put its Roblox asset id in `ids` (a number like 1234567890).
-- A sound with no ids yet is silent, so the game never breaks on a missing sound.
-- Variants: list several ids and one is picked at random each time.

local Sounds = {}

Sounds.Groups = { "Music", "Effects", "Crowd", "Commentator" }

Sounds.List = {}
local function def(name, group, opts)
	opts = opts or {}
	Sounds.List[name] = {
		group = group,
		ids = opts.ids or {},
		volume = opts.volume or 0.7,
		cooldown = opts.cooldown or 0.05,
		pitchJitter = opts.pitchJitter == nil and 0.05 or opts.pitchJitter,
		looped = opts.looped or false,
		positional = opts.positional or false, -- played from the court (3D) instead of the UI
	}
end

-- Ball & court (3D, heard by anyone watching)
for _, n in ipairs({ "Dribble", "ShoeSqueak" }) do
	def(n, "Effects", { positional = true, cooldown = 0.08, volume = 0.5 })
end
for _, n in ipairs({ "PassChest", "PassBounce", "Catch", "ShotRelease", "Swish", "RimIn", "RimOut",
	"BackboardMiss", "Airball", "LayupKiss", "Dunk", "Block", "Steal", "ReboundGrab",
	"WhistleShort", "WhistleLong", "Buzzer", "ShotClockBeep", "FreeThrowBounce" }) do
	def(n, "Effects", { positional = true })
end
def("DunkHeavy", "Effects", { positional = true, volume = 0.9, pitchJitter = 0 })

-- Crowd
def("CrowdBed", "Crowd", { looped = true, volume = 0.35, pitchJitter = 0 })
def("ClutchHeartbeat", "Effects", { looped = true, volume = 0.6, pitchJitter = 0 })
for _, n in ipairs({ "CrowdCheerS", "CrowdCheerM", "CrowdCheerL", "CrowdOoh", "CrowdGroan", "CrowdRoar",
	"CrowdDefenseChant", "CrowdAirballChant", "CrowdBoo", "CrowdHush" }) do
	def(n, "Crowd", { cooldown = 0.5 })
end

-- In-game moments & HUD
for _, n in ipairs({ "TimeoutCall", "CoachsCallPop", "CoachsCallTick", "CoachsCallGood", "CoachsCallBad",
	"HeatUp", "FreezeUp", "MatchupSwap", "ClutchMeterPerfect", "ClutchMeterGood", "ClutchMeterBad",
	"ChallengeReview", "ChallengeOverturned", "ChallengeStands", "BannerSlam", "SlowMoIn", "SlowMoOut",
	"Victory", "Defeat" }) do
	def(n, "Effects")
end

-- Lobby, menus & economy
for _, n in ipairs({ "UIClick", "UIBack", "UIToggle", "UIOpenPanel", "UIClosePanel", "UIError",
	"CoinsGainS", "CoinsGainM", "CoinsGainL", "CoinsSpend", "FansGain", "QuestComplete", "AchievementUnlock",
	"LevelUpTier", "TierDown", "MatchFound", "QueueTick", "CodeRedeemed", "TrainingStart", "TrainingDone",
	"MarketSold", "TradeRequest", "TradeAccepted", "ScoutVanHorn", "ServerAlertLegend" }) do
	def(n, "Effects", { volume = 0.6, pitchJitter = 0.02 })
end

-- Pack opening
for _, n in ipairs({ "PackDrop", "PackShake", "PackRip", "CardWhoosh", "CardFlip", "CardsGather", "RevealCommon", "RevealRare",
	"RevealEpic", "RevealLegendary", "RevealHallOfFame", "FinishShimmer", "QuickSell" }) do
	def(n, "Effects", { volume = 0.8, pitchJitter = 0 })
end

-- Music
for _, n in ipairs({ "MusicLobby", "MusicMenu", "MusicTimeout", "MusicPackOpen" }) do
	def(n, "Music", { looped = true, volume = 0.4, pitchJitter = 0 })
end
for _, n in ipairs({ "MusicMatchIntro", "MusicVictory", "MusicDefeat" }) do
	def(n, "Music", { volume = 0.5, pitchJitter = 0 })
end

-- Commentator ---------------------------------------------------------------
-- Each event has lines; one is picked at random. `text` doubles as the subtitle.
-- Put the recorded line's asset id in `id`. priority: higher lines cut the queue.
Sounds.Lines = {}
local function lines(event, priority, texts)
	local list = {}
	for _, t in ipairs(texts) do
		table.insert(list, { text = t, id = 0 })
	end
	Sounds.Lines[event] = { priority = priority, lines = list }
end

lines("TipOff", 3, { "Here we go! Tip-off!", "Welcome in, folks. Big one today." })
lines("EndQ1", 1, { "End of the first quarter." })
lines("Halftime", 1, { "That's halftime." })
lines("EndQ3", 1, { "End of three. Twelve minutes to decide it." })
lines("FinalMinute", 3, { "Final minute. Every possession counts now." })
lines("Three", 2, { "From downtown!", "Bang! From deep!", "He hits the three!" })
lines("Dunk", 2, { "Throws it down!", "Oh, what a slam!", "Posterized!" })
lines("Jumper", 1, { "Smooth jumper.", "Pull-up, good!", "Off the glass!" })
lines("Layup", 1, { "Easy two.", "Finishes at the rim." })
lines("AndOne", 2, { "And one!", "And he gets the foul!" })
lines("Swish", 1, { "Swish.", "Nothing but net." })
lines("BackToBackThrees", 2, { "Back-to-back threes!" })
lines("HeatingUp", 2, { "He's heating up!" })
lines("OnFire", 3, { "He is ON FIRE!" })
lines("Block", 2, { "Rejected!", "Get that outta here!" })
lines("Steal", 1, { "Picked off!", "Stolen!" })
lines("Miss", 0, { "Off the rim.", "Rattles out." })
lines("Airball", 1, { "Air ball!" })
lines("Rebound", 0, { "Big rebound.", "Second chance!" })
lines("Turnover", 0, { "Turnover.", "Travel." })
lines("ShotClock", 1, { "Shot clock violation!" })
lines("LeadChange", 2, { "Lead change!" })
lines("TieGame", 2, { "Tie game!" })
lines("Run", 1, { "They're on a run here." })
lines("DoubleDigits", 1, { "That's a double-digit lead." })
lines("Timeout", 3, { "Timeout on the floor." })
lines("Challenge", 3, { "Here comes a challenge... let's look at the replay." })
lines("ChallengeStands", 2, { "Call stands." })
lines("ChallengeOverturned", 2, { "And it's overturned!" })
lines("DefenseChange", 1, { "Big change on defense." })
lines("LastShot", 4, { "Down to the last shot..." })
lines("BuzzerBeater", 5, { "Buzzer beater! Unbelievable!" })
lines("ClutchMake", 4, { "Ice in his veins!" })
lines("GameOver", 4, { "And that's the ballgame!", "What a finish!", "A statement win." })
lines("PackRare", 1, { "Rare!" })
lines("PackEpic", 2, { "Epic!" })
lines("PackLegendary", 3, { "LEGENDARY!" })
lines("PackHallOfFame", 5, { "A HALL OF FAMER! No way!" })
lines("PackFinish", 2, { "Ooh, that's a Finish!" })

-- Pick a random asset id for a sound, or nil if none is set yet.
function Sounds.pickId(name: string, roll: number): number?
	local s = Sounds.List[name]
	if not s or #s.ids == 0 then
		return nil
	end
	return s.ids[math.clamp(math.floor(roll * #s.ids) + 1, 1, #s.ids)]
end

return Sounds
