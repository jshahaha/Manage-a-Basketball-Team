--!nonstrict
-- Projected scoreline shown on the Match Found screen, like "104 – 99, 62% to win".
-- Built from each team's minutes-weighted ratings and both play styles.
-- The match sim will be tuned so real games land around these numbers.

local function load(name)
	return require(script and script.Parent:FindFirstChild(name) or "./" .. name)
end
local Ratings = load("Ratings")
local PlayerFactory = load("PlayerFactory")

local Projection = {}

Projection.BasePossessions = 98
Projection.PaceBonus = {
	PaceAndSpace = 6,
	FullCourtPress = 4,
	FiveOut = 1,
	InsideOut = -4,
	IsoStar = -3,
}

-- rotation: { { player = <player>, minutes = 34 }, ... } (minutes add up to 240)
-- Returns { offense, defense, ovr } on a 25..99 scale.
function Projection.strength(rotation)
	local off, def, ovr, total = 0, 0, 0, 0
	for _, slot in ipairs(rotation) do
		local m = slot.minutes or 0
		if m > 0 then
			local g = Ratings.groupScores(slot.player.ratings)
			local bonus = PlayerFactory.finishBonus(slot.player)
			off += ((g.SHO * 0.4 + g.FIN * 0.35 + g.PLY * 0.25) + bonus) * m
			def += ((g.DEF * 0.65 + g.REB * 0.35) + bonus) * m
			ovr += PlayerFactory.overall(slot.player) * m
			total += m
		end
	end
	if total == 0 then
		return { offense = 0, defense = 0, ovr = 0 }
	end
	return { offense = off / total, defense = def / total, ovr = ovr / total }
end

local function ppp(off: number, oppDef: number): number
	return math.clamp(1.08 + (off - oppDef) * 0.012, 0.85, 1.35)
end

-- home / away: { rotation = {...}, offense = "FiveOut", defense = "TwoThreeZone" }
-- Returns { home = 104, away = 99, homeWin = 0.62 }
function Projection.project(home, away)
	local h, a = Projection.strength(home.rotation), Projection.strength(away.rotation)
	local poss = Projection.BasePossessions
	for _, style in ipairs({ home.offense, home.defense, away.offense, away.defense }) do
		poss += (Projection.PaceBonus[style] or 0) / 2
	end
	local hs = math.floor(poss * ppp(h.offense, a.defense) + 1.5) -- +1 home court edge
	local as = math.floor(poss * ppp(a.offense, h.defense) + 0.5)
	if hs == as then
		hs += 1 -- a projection never shows a tie
	end
	local diff = (poss * ppp(h.offense, a.defense) + 1) - poss * ppp(a.offense, h.defense)
	return { home = hs, away = as, homeWin = 1 / (1 + math.exp(-diff / 6)) }
end

return Projection
