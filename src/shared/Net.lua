--!nonstrict
-- Networking: one RemoteFunction ("Request") for client -> server calls, and
-- one RemoteEvent ("Push") for server -> client messages.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

local FOLDER_NAME = "CourtNet"

local function getFolder()
	if RunService:IsServer() then
		local f = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		if not f then
			f = Instance.new("Folder")
			f.Name = FOLDER_NAME
			local rf = Instance.new("RemoteFunction")
			rf.Name = "Request"
			rf.Parent = f
			local re = Instance.new("RemoteEvent")
			re.Name = "Push"
			re.Parent = f
			f.Parent = ReplicatedStorage
		end
		return f
	end
	return ReplicatedStorage:WaitForChild(FOLDER_NAME)
end

function Net.request(): RemoteFunction
	return getFolder():WaitForChild("Request")
end

function Net.push(): RemoteEvent
	return getFolder():WaitForChild("Push")
end

return Net
