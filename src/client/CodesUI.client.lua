--!nonstrict
-- CODES button and redeem panel, plus pop-up notices (admin replies, quest done).
-- Built in code for now; the full HUD will replace the button placement later.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local Audio = require(script.Parent:WaitForChild("Audio"))

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

-- Button ----------------------------------------------------------------------
local open = Instance.new("TextButton")
open.Name = "OpenCodes"
open.Size = UDim2.fromOffset(110, 46)
open.Position = UDim2.new(0, 16, 1, -62)
open.BackgroundColor3 = Color3.fromHex("1c1d21")
open.Text = "CODES"
open.TextSize = 22
open.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold)
open.TextColor3 = Color3.fromHex("f5d33a")
open.Parent = gui
round(open, 4)
stroke(open, 3)
open:FindFirstChildOfClass("UIStroke").Color = Color3.fromHex("f5d33a")

-- Panel -----------------------------------------------------------------------
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(420, 240)
panel.BackgroundColor3 = WHITE
panel.Visible = false
panel.Parent = gui
round(panel, 20)
stroke(panel, 4)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 56)
header.BackgroundColor3 = ORANGE
header.Parent = panel
round(header, 20)
local title = label(header, "REDEEM A CODE", 26, Enum.Font.FredokaOne, WHITE)
title.Size = UDim2.new(1, -70, 1, 0)
title.Position = UDim2.fromOffset(18, 0)
title.TextXAlignment = Enum.TextXAlignment.Left

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(40, 40)
close.Position = UDim2.new(1, -50, 0, 8)
close.BackgroundColor3 = RED
close.Text = "X"
close.TextSize = 20
close.Font = Enum.Font.FredokaOne
close.TextColor3 = WHITE
close.Parent = header
round(close, 10)
stroke(close, 3)

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -36, 0, 48)
box.Position = UDim2.fromOffset(18, 74)
box.BackgroundColor3 = Color3.fromRGB(246, 248, 252)
box.PlaceholderText = "Type a code..."
box.Text = ""
box.TextSize = 20
box.Font = Enum.Font.GothamBold
box.TextColor3 = INK
box.ClearTextOnFocus = false
box.Parent = panel
round(box, 12)
stroke(box, 3)

local redeem = Instance.new("TextButton")
redeem.Size = UDim2.new(1, -36, 0, 48)
redeem.Position = UDim2.fromOffset(18, 134)
redeem.BackgroundColor3 = GREEN
redeem.Text = "REDEEM"
redeem.TextSize = 24
redeem.Font = Enum.Font.FredokaOne
redeem.TextColor3 = WHITE
redeem.Parent = panel
round(redeem, 12)
stroke(redeem, 3)

local result = label(panel, "", 15, Enum.Font.GothamBold)
result.Size = UDim2.new(1, -36, 0, 40)
result.Position = UDim2.fromOffset(18, 190)

local busy = false
local function submit()
	if busy then
		return
	end
	busy = true
	redeem.Text = "..."
	local ok, res = pcall(function()
		return Net.request():InvokeServer("redeemCode", box.Text)
	end)
	if ok and res and res.ok then
		Audio.play("CodeRedeemed")
		result.TextColor3 = GREEN
		result.Text = res.data.message
		box.Text = ""
	else
		Audio.play("UIError")
		result.TextColor3 = RED
		result.Text = (ok and res and res.err) or "Couldn't reach the server."
	end
	redeem.Text = "REDEEM"
	busy = false
end

open.Activated:Connect(function()
	Audio.play(panel.Visible and "UIClosePanel" or "UIOpenPanel")
	panel.Visible = not panel.Visible
	result.Text = ""
end)
close.Activated:Connect(function()
	panel.Visible = false
end)
redeem.Activated:Connect(submit)
box.FocusLost:Connect(function(enter)
	if enter then
		submit()
	end
end)

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
	f.BackgroundColor3 = color or INK
	f.TextColor3 = WHITE
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
		toast(data.text, INK, 10)
	elseif kind == "questDone" then
		Audio.play("QuestComplete")
		toast("Quest complete: " .. data.text .. "  (+" .. data.coins .. " coins to claim)", GREEN)
	end
end)
