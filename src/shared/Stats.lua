--!nonstrict
-- Box scores, and team and player stat totals: PPG, FG%, 3P%, FT%, RPG, APG, and so on.
-- A match produces one box line per player. Stats.recordGame adds a finished game
-- to the club's team totals and each player's career.

local Stats = {}

-- One player's line for one game (or a running total of many).
Stats.LineKeys = { "min", "pts", "fgm", "fga", "tpm", "tpa", "ftm", "fta", "oreb", "dreb", "ast", "stl", "blk", "tov", "pf", "dunks" }

function Stats.newLine()
	local l = {}
	for _, k in ipairs(Stats.LineKeys) do
		l[k] = 0
	end
	return l
end

function Stats.addLine(into, line)
	for _, k in ipairs(Stats.LineKeys) do
		into[k] = (into[k] or 0) + (line[k] or 0)
	end
	return into
end

-- Points must match the shots: 2s + 3s + free throws.
function Stats.isConsistent(line): boolean
	local twos = line.fgm - line.tpm
	return line.pts == twos * 2 + line.tpm * 3 + line.ftm
		and line.fgm <= line.fga and line.tpm <= line.tpa and line.ftm <= line.fta and line.tpm <= line.fgm
end

function Stats.newTeam()
	return { games = 0, wins = 0, losses = 0, ptsAgainst = 0, totals = Stats.newLine() }
end

function Stats.newCareer()
	local c = Stats.newLine()
	c.games = 0
	c.mvps = 0
	return c
end

local function pct(made: number, att: number): number
	if att == 0 then
		return 0
	end
	return math.floor(made / att * 1000 + 0.5) / 10 -- one decimal, e.g. 47.3
end

local function per(total: number, games: number): number
	if games == 0 then
		return 0
	end
	return math.floor(total / games * 10 + 0.5) / 10
end

Stats.pct, Stats.per = pct, per

-- Averages for a team or a player: totals table plus number of games.
function Stats.summary(t, games: number)
	return {
		ppg = per(t.pts, games),
		fgPct = pct(t.fgm, t.fga),
		threePct = pct(t.tpm, t.tpa),
		ftPct = pct(t.ftm, t.fta),
		rpg = per(t.oreb + t.dreb, games),
		orpg = per(t.oreb, games),
		apg = per(t.ast, games),
		spg = per(t.stl, games),
		bpg = per(t.blk, games),
		topg = per(t.tov, games),
		mpg = per(t.min, games),
		dunks = t.dunks,
	}
end

function Stats.teamSummary(team)
	local s = Stats.summary(team.totals, team.games)
	s.games, s.wins, s.losses = team.games, team.wins, team.losses
	s.oppPpg = per(team.ptsAgainst, team.games)
	s.diff = math.floor((s.ppg - s.oppPpg) * 10 + 0.5) / 10
	return s
end

-- Add a finished game.
--   team: the club's team stats (Stats.newTeam())
--   players: { [playerId] = player } so careers can be updated (players may be missing)
--   lines: { [playerId] = box line }
--   oppPts: opponent's final score
--   mvpId: player id of the game MVP, or nil
-- Returns totals for the game, useful for quests (pts, tpm, dunks).
function Stats.recordGame(team, players, lines, oppPts: number, mvpId: string?)
	local game = Stats.newLine()
	for id, line in pairs(lines) do
		Stats.addLine(game, line)
		local p = players[id]
		if p then
			p.career = p.career or Stats.newCareer()
			Stats.addLine(p.career, line)
			if (line.min or 0) > 0 then
				p.career.games += 1
			end
			if id == mvpId then
				p.career.mvps += 1
			end
		end
	end
	Stats.addLine(team.totals, game)
	team.games += 1
	team.ptsAgainst += oppPts
	if game.pts > oppPts then
		team.wins += 1
	else
		team.losses += 1
	end
	return game
end

-- Game MVP: a simple impact score from the box line.
function Stats.gameScore(l): number
	return l.pts + 0.4 * l.fgm - 0.7 * l.fga - 0.4 * (l.fta - l.ftm) + 0.7 * l.oreb + 0.3 * l.dreb
		+ l.stl + 0.7 * l.ast + 0.7 * l.blk - 0.4 * l.pf - l.tov
end

function Stats.mvp(lines): string?
	local best, bestId = -math.huge, nil
	for id, l in pairs(lines) do
		local s = Stats.gameScore(l)
		if s > best then
			best, bestId = s, id
		end
	end
	return bestId
end

return Stats
