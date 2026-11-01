--!nonstrict
-- Unopened packs and loose badge cards in a profile.
-- A kept 5x or 20x bundle stays ONE item ("Pro x5"), like a bundle box in 2K,
-- not 5 loose packs. Single packs keep the plain pack id ("Pro"), so codes and
-- rewards that grant { Pro = 1 } still work.

local Inventory = {}

function Inventory.key(packId: string, size: number?): string
	if not size or size <= 1 then
		return packId
	end
	return packId .. " x" .. size
end

-- "Pro x5" -> "Pro", 5 ; "Pro" -> "Pro", 1
function Inventory.parse(key: string): (string, number)
	local id, n = key:match("^(.-) x(%d+)$")
	if id then
		return id, tonumber(n)
	end
	return key, 1
end

function Inventory.add(profile, packId: string, size: number?, count: number?)
	local k = Inventory.key(packId, size)
	profile.packs[k] = (profile.packs[k] or 0) + (count or 1)
	return k
end

-- Removes one item. Returns packId and how many packs are inside, or nil.
function Inventory.take(profile, key: string): (string?, number?)
	local n = profile.packs[key]
	if not n or n <= 0 then
		return nil, nil
	end
	profile.packs[key] = n > 1 and n - 1 or nil
	return Inventory.parse(key)
end

-- Items for the inventory screen, bundles first then by pack.
function Inventory.list(profile)
	local out = {}
	for key, n in pairs(profile.packs) do
		local id, size = Inventory.parse(key)
		table.insert(out, { key = key, pack = id, size = size, count = n, kind = size > 1 and "bundle" or "pack" })
	end
	table.sort(out, function(a, b)
		if a.size ~= b.size then
			return a.size > b.size
		end
		return a.pack < b.pack
	end)
	return out
end

-- Loose badge cards waiting to be equipped: [badgeId/tier] = count.
function Inventory.addBadge(profile, badgeId: string, tierId: string)
	profile.badgeCards = profile.badgeCards or {}
	local k = badgeId .. "/" .. tierId
	profile.badgeCards[k] = (profile.badgeCards[k] or 0) + 1
end

function Inventory.takeBadge(profile, badgeId: string, tierId: string): boolean
	local k = badgeId .. "/" .. tierId
	local n = profile.badgeCards and profile.badgeCards[k]
	if not n or n <= 0 then
		return false
	end
	profile.badgeCards[k] = n > 1 and n - 1 or nil
	return true
end

return Inventory
