--[[
  Who can use admin chat commands (!makecode, !delcode, !codes).

  The game's owner is always an admin: the user who owns the place, or, for a
  group game, anyone at rank 254 or above in that group. Add extra Roblox
  user IDs below. Find an ID in the number in a profile URL:
  roblox.com/users/12345678/profile
]]

local RunService = game:GetService("RunService")

local EXTRA_ADMINS = {
	-- 12345678, -- example
}

local Admins = {}

function Admins.isAdmin(player: Player): boolean
	if table.find(EXTRA_ADMINS, player.UserId) then
		return true
	end
	-- An unpublished place in Studio has no owner yet, so anyone testing it counts as an admin.
	if RunService:IsStudio() and game.CreatorId == 0 then
		return true
	end
	if game.CreatorType == Enum.CreatorType.User then
		return player.UserId == game.CreatorId
	end
	if game.CreatorType == Enum.CreatorType.Group then
		local ok, rank = pcall(function()
			return player:GetRankInGroup(game.CreatorId)
		end)
		return ok and rank >= 254
	end
	return false
end

return Admins
