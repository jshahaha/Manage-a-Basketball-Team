--!nonstrict
-- Facilities: club buildings upgraded with coins over a build timer. Gems can skip the timer
-- (Config.Gems.skipBuildPerHour), but gems can't buy the upgrade itself.
--
-- Arena: more coins from every game (win or loss) and a small boost to your players at home.
-- Training Facility: shorter training sessions and bigger gains per session.

local Facilities = {}

Facilities.MaxLevel = 10

Facilities.List = {
	Arena = {
		name = "Arena",
		baseCost = 20000, -- coins for level 1; each level costs 1.8x the one before
		costGrowth = 1.8,
		hoursPerLevel = 2, -- build time for level n is n * 2 hours
		perLevel = { coinBonus = 0.04, homeOvr = 0.2 }, -- level 10: +40% game coins, +2 OVR at home
	},
	Training = {
		name = "Training Facility",
		baseCost = 15000,
		costGrowth = 1.8,
		hoursPerLevel = 1.5,
		perLevel = { sessionTime = -0.05, gain = 0.03 }, -- level 10: sessions 50% shorter, +30% gains
	},
}

function Facilities.newState()
	return { Arena = { level = 0 }, Training = { level = 0 } }
end

-- Coins and build hours to go from `level` to level + 1 (nil at max).
function Facilities.nextCost(id: string, level: number)
	local f = Facilities.List[id]
	if level >= Facilities.MaxLevel then
		return nil
	end
	local n = level + 1
	local coins = math.floor(f.baseCost * f.costGrowth ^ level / 1000 + 0.5) * 1000
	return { coins = coins, hours = n * f.hoursPerLevel }
end

-- Effect values at a level, e.g. Facilities.effect("Arena", 5).coinBonus == 0.2
function Facilities.effect(id: string, level: number)
	local out = {}
	for k, v in pairs(Facilities.List[id].perLevel) do
		out[k] = v * level
	end
	return out
end

-- Start an upgrade. state = profile.facilities[id]. Returns ok, reason, cost.
function Facilities.startUpgrade(id: string, state, coins: number, now: number)
	if state.buildingUntil then
		return false, "Already building."
	end
	local cost = Facilities.nextCost(id, state.level)
	if not cost then
		return false, "Max level."
	end
	if coins < cost.coins then
		return false, "Not enough coins."
	end
	state.buildingUntil = now + math.floor(cost.hours * 3600)
	return true, nil, cost
end

-- Finish a build if its timer is done. Returns true when the level went up.
function Facilities.tick(state, now: number): boolean
	if state.buildingUntil and now >= state.buildingUntil then
		state.buildingUntil = nil
		state.level += 1
		return true
	end
	return false
end

-- Gems to finish a build now: rounded up to the hour.
function Facilities.skipCost(state, now: number, gemsPerHour: number): number
	if not state.buildingUntil then
		return 0
	end
	return math.ceil(math.max(0, state.buildingUntil - now) / 3600) * gemsPerHour
end

return Facilities
