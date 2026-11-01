--!nonstrict
-- Daily quests, achievements and lifetime stats.
-- Other services call ProgressService.record(player, event, amount) when
-- something happens (a win, a three, a pack opened...).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Quests = require(Shared.Quests)
local Achievements = require(Shared.Achievements)
local Stats = require(Shared.Stats)
local Net = require(Shared.Net)

local DataService = require(script.Parent.DataService)

local ProgressService = {}

local function today(player: Player, profile)
	profile.quests = Quests.ensureDay(profile.quests, player.UserId, os.time())
	return profile.quests
end

-- Record an event for quests and achievements. Tells the client about finished quests.
function ProgressService.record(player: Player, event: string, amount: number?)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	amount = amount or 1
	Achievements.recordStat(profile.stats, event, amount)
	local done = Quests.record(today(player, profile), event, amount)
	for _, q in ipairs(done) do
		Net.push():FireClient(player, "questDone", { text = q.text, coins = q.coins })
	end
end

-- Record a finished game: team and player stats, plus quest and achievement events.
-- lines: { [playerId] = box line }. challenge: true for server challenges.
function ProgressService.recordGame(player: Player, lines, oppPts: number, challenge: boolean?)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	local byId = {}
	for _, p in ipairs(profile.players) do
		byId[p.id] = p
	end
	local mvp = Stats.mvp(lines)
	local game = Stats.recordGame(profile.teamStats, byId, lines, oppPts, mvp)
	local won = game.pts > oppPts
	profile.streak = won and profile.streak + 1 or 0
	ProgressService.record(player, "gamesPlayed")
	if won then
		ProgressService.record(player, "gamesWon")
		if game.pts - oppPts >= 15 then
			ProgressService.record(player, "blowoutWins")
		end
	end
	ProgressService.record(player, "pointsScored", game.pts)
	ProgressService.record(player, "threesMade", game.tpm)
	ProgressService.record(player, "dunks", game.dunks)
	ProgressService.record(player, "bestStreak", profile.streak)
	if challenge then
		ProgressService.record(player, "challengesPlayed")
	end
	return game, mvp
end

ProgressService.handlers = {}

function ProgressService.handlers.getQuests(player, profile)
	local q = today(player, profile)
	return true, { list = q.list, resetsIn = Quests.secondsUntilReset(os.time()) }
end

function ProgressService.handlers.claimQuest(player, profile, index)
	if type(index) ~= "number" then
		return false, "Bad request."
	end
	local coins, err = Quests.claim(today(player, profile), index)
	if not coins then
		return false, err
	end
	DataService.grant(profile, { coins = coins })
	return true, { coins = coins }
end

function ProgressService.handlers.getAchievements(player, profile)
	profile.stats.collection = #profile.players
	return true, Achievements.view(profile.stats, profile.achievements)
end

function ProgressService.handlers.claimAchievement(player, profile, id)
	if type(id) ~= "string" then
		return false, "Bad request."
	end
	local reward, err = Achievements.claim(profile.stats, profile.achievements, id)
	if not reward then
		return false, err
	end
	DataService.grant(profile, reward)
	return true, reward
end

function ProgressService.handlers.getTeamStats(player, profile)
	return true, Stats.teamSummary(profile.teamStats)
end

return ProgressService
