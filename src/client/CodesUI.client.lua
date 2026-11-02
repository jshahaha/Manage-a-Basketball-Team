--!nonstrict
-- Pop-up notices (admin replies, quest done). Code redeeming lives in the shop's CODES tab.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local Theme = require(script.Parent:WaitForChild("Theme"))

local player = Players.LocalPlayer
local INK = Color3.fromRGB(27, 33, 64)
local WHITE = Color3.new(1, 1, 1)
local GREEN = Color3.fromRGB(47, 191, 79)
local RED = Color3.fromRGB(232, 69, 107)
local ORANGE = Color3.fromRGB(255, 122, 26)

local function round(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = inst
end
local function stroke(inst, t)
	local s = Instance.new("UIStroke")
	s.Thickness = t
	s.Color = INK
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
end
local function label(parent, text, size, font, color)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size
	l.Font = font or Enum.Font.GothamBlack
	l.TextColor3 = color or INK
	l.TextWrapped = true
	l.Parent = parent
	return l
end

local gui = Instance.new("ScreenGui")
gui.Name = "Codes"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- Codes are redeemed in the shop's CODES tab now (LobbyUI); this script keeps the notices.
local T = Theme.C

-- Notices (admin replies, "Quest complete!") ------------------------------------
local toastHolder = Instance.new("Frame")
toastHolder.BackgroundTransparency = 1
toastHolder.AnchorPoint = Vector2.new(0.5, 0)
toastHolder.Position = UDim2.new(0.5, 0, 0, 70)
toastHolder.Size = UDim2.fromOffset(560, 400)
toastHolder.Parent = gui
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = toastHolder

local function toast(text: string, color: Color3?, seconds: number?)
	local f = Instance.new("TextLabel")
	f.AutomaticSize = Enum.AutomaticSize.Y
	f.Size = UDim2.fromOffset(540, 0)
	f.BackgroundColor3 = color or Theme.C.slate
	f.TextColor3 = Theme.textOn(color or Theme.C.slate)
	f.Font = Enum.Font.GothamBold
	f.TextSize = 16
	f.TextWrapped = true
	f.TextXAlignment = Enum.TextXAlignment.Left
	f.Text = text
	f.Parent = toastHolder
	round(f, 12)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 14), UDim.new(0, 14)
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 10), UDim.new(0, 10)
	pad.Parent = f
	task.delay(seconds or 6, function()
		local t = TweenService:Create(f, TweenInfo.new(0.4), { BackgroundTransparency = 1, TextTransparency = 1 })
		t:Play()
		t.Completed:Wait()
		f:Destroy()
	end)
end

Net.push().OnClientEvent:Connect(function(kind, data)
	if kind == "notice" then
		toast(data.text, Theme.C.slate, 10)
	elseif kind == "questDone" then
		Audio.play("QuestComplete")
		toast("Quest complete: " .. data.text .. "  (+" .. data.coins .. " coins to claim)", Theme.C.yellow)
	end
end)
