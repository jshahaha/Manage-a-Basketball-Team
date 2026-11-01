--!nonstrict
-- Elo rating and tiers. See docs/MAIN_GAME_IDEA.md section 2.

local Config = require(script and script.Parent:FindFirstChild("Config") or "./Config")

local Elo = {}
local E = Config.Elo

-- Chance (0..1) that a club rated `you` beats a club rated `opp`.
function Elo.expected(you: number, opp: number): number
	return 1 / (1 + 10 ^ ((opp - you) / 400))
end

function Elo.kFactor(gamesPlayed: number, isSavedTeamOwner: boolean?): number
	local k = gamesPlayed < E.placementGames and E.kPlacement or E.kNormal
	if isSavedTeamOwner then
		k *= E.ownerKScale
	end
	return k
end

-- Rating change for one game. won is true/false.
function Elo.change(you: number, opp: number, won: boolean, k: number): number
	local result = won and 1 or 0
	return math.floor(k * (result - Elo.expected(you, opp)) + 0.5)
end

function Elo.tierIndex(elo: number): number
	local idx = 1
	for i, t in ipairs(Config.Tiers) do
		if elo >= t.min then
			idx = i
		end
	end
	return idx
end

function Elo.tier(elo: number)
	return Config.Tiers[Elo.tierIndex(elo)]
end

-- state: { elo, games, tier (index), shield (games left) }
-- Returns the new state and the Elo change. Does not modify the input.
function Elo.apply(state, oppElo: number, won: boolean, isSavedTeamOwner: boolean?)
	local k = Elo.kFactor(state.games, isSavedTeamOwner)
	local delta = Elo.change(state.elo, oppElo, won, k)
	local new = {
		elo = math.max(0, state.elo + delta),
		games = state.games + (isSavedTeamOwner and 0 or 1),
		tier = state.tier or Elo.tierIndex(state.elo),
		shield = state.shield or 0,
	}
	local natural = Elo.tierIndex(new.elo)
	if natural > new.tier then
		-- promoted: protect the new tier for a few games
		new.tier = natural
		new.shield = E.shieldGames
	elseif natural < new.tier then
		if new.shield > 0 then
			new.shield -= 1 -- shield absorbs the drop
		else
			new.tier = natural
		end
	elseif not won and new.shield > 0 then
		new.shield -= 1
	end
	return new, delta
end

-- Matchmaking search window after waiting `seconds`.
function Elo.searchRange(seconds: number): number
	return math.min(E.searchMax, E.searchRange + E.searchStep * math.floor(seconds / 3))
end

return Elo
