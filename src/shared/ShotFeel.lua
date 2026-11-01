--!nonstrict
-- The feedback line under a shot ("PERFECT RELEASE", "SLIGHTLY LATE"...). The match engine
-- decides whether a shot goes in; this only picks how the release reads, so the text always
-- agrees with the result and better shooters hit "Perfect" more often.
--
--   local r = ShotFeel.release(rng, made, rating)   -- "Perfect" | "Good" | "Early" | "Late"
--   ShotFeel.Text[r], ShotFeel.Color[r]             -- what to show
--   ShotFeel.rating(player, kind)                   -- the rating that drives it

local ShotFeel = {}

ShotFeel.Text = {
	Perfect = "PERFECT RELEASE",
	Good = "GOOD RELEASE",
	Early = "SLIGHTLY EARLY",
	Late = "SLIGHTLY LATE",
}
-- RGB triples so this loads without Roblox types (tests run in plain Luau).
ShotFeel.Color = {
	Perfect = { 90, 230, 120 },
	Good = { 255, 200, 60 },
	Early = { 255, 140, 70 },
	Late = { 255, 140, 70 },
}

-- Chance a made shot reads "Perfect", from the shooting rating (40-99).
function ShotFeel.perfectChance(rating: number): number
	return math.clamp((rating - 50) / 75, 0.05, 0.6)
end

function ShotFeel.release(rng, made: boolean, rating: number): string
	if made then
		return rng:chance(ShotFeel.perfectChance(rating)) and "Perfect" or "Good"
	end
	-- Misses are mostly mistimed; a good shooter's miss can still be a good look that rims out.
	if rng:chance(math.clamp((rating - 60) / 100, 0.05, 0.3)) then
		return "Good"
	end
	return rng:chance(0.5) and "Early" or "Late"
end

-- The rating behind a shot kind.
function ShotFeel.rating(player, kind: string): number
	local r = player.ratings or {}
	if kind == "three" then
		return r.three or 60
	elseif kind == "dunk" then
		return r.drivingDunk or 60
	end
	return r.mid or 60
end

return ShotFeel
