--!nonstrict
-- Small deterministic RNG (Park-Miller). Pure Luau so the sim can be tested
-- outside Roblox, and so generated players and matches can be replayed from a seed.

local Rng = {}
Rng.__index = Rng

local MOD = 2147483647
local MULT = 16807

function Rng.new(seed: number?)
	local s = math.floor(seed or (os.time() + os.clock() * 1e6)) % MOD
	if s <= 0 then
		s = s + MOD - 1
	end
	local self = setmetatable({ state = s }, Rng)
	-- warm up
	for _ = 1, 4 do
		self:next()
	end
	return self
end

function Rng:next(): number
	self.state = (self.state * MULT) % MOD
	return self.state / MOD
end

-- Float in [a, b)
function Rng:range(a: number, b: number): number
	return a + (b - a) * self:next()
end

-- Integer in [a, b]
function Rng:int(a: number, b: number): number
	return a + math.floor(self:next() * (b - a + 1))
end

function Rng:chance(p: number): boolean
	return self:next() < p
end

function Rng:pick<T>(list: { T }): T
	return list[self:int(1, #list)]
end

-- weights: { {item, weight}, ... }  or map item -> weight with keys list
function Rng:weighted(entries: { { any } }): any
	local total = 0
	for _, e in ipairs(entries) do
		total += e[2]
	end
	local roll = self:next() * total
	for _, e in ipairs(entries) do
		roll -= e[2]
		if roll <= 0 then
			return e[1]
		end
	end
	return entries[#entries][1]
end

-- Approximate normal distribution (sum of uniforms)
function Rng:normal(mean: number, sd: number): number
	local s = 0
	for _ = 1, 6 do
		s += self:next()
	end
	return mean + (s - 3) * sd / 0.7071
end

function Rng.hash(str: string): number
	local h = 5381
	for i = 1, #str do
		h = (h * 33 + string.byte(str, i)) % MOD
	end
	return h
end

return Rng
