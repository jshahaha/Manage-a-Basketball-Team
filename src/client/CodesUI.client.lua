--!nonstrict
-- CODES button and redeem panel, plus pop-up notices (admin replies, quest done).
-- Built in code for now; the full HUD will replace the button placement later.

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

-- Button ----------------------------------------------------------------------
local T = Theme.C
local open = Theme.button(gui, "CODES", T.slate, UDim2.fromOffset(120, 50), UDim2.new(0, 16, 1, -66))
open.Name = "OpenCodes"
open.Label.TextColor3 = T.yellow
open.Label.TextSize = 22

-- Panel: asphalt with a sunset header, like the lobby panels -------------------
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(440, 250)
panel.BackgroundColor3 = T.asphalt
panel.Visible = false
panel.Parent = gui
if not Theme.panelArt(panel) then
	round(panel, 8)
	stroke(panel, 4)
end

local header = Instance.new("Frame")
header.Position = UDim2.fromOffset(5, 5)
header.Size = UDim2.new(1, -10, 0, 56)
header.BackgroundColor3 = T.sunsetTop
header.Parent = panel
round(header, 8)
Theme.sunset(header)
Theme.chainlink(header)
Theme.tape(header, "REDEEM A CODE", { pos = UDim2.fromOffset(12, 8), sz = UDim2.fromOffset(230, 40), rot = -2, size = 22 })

local close = Theme.button(header, "X", T.red, UDim2.fromOffset(44, 44), UDim2.new(1, -52, 0, 6))

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -36, 0, 48)
box.Position = UDim2.fromOffset(18, 76)
box.BackgroundColor3 = T.slate
box.PlaceholderText = "Type a code..."
box.PlaceholderColor3 = T.muted
box.Text = ""
box.TextSize = 22
box.FontFace = Theme.HEAD
box.TextColor3 = T.ink
box.ClearTextOnFocus = false
box.Parent = panel
round(box, 6)
stroke(box, 3)
box:FindFirstChildOfClass("UIStroke").Color = T.line

local redeem = Theme.button(panel, "REDEEM", T.lime, UDim2.new(1, -36, 0, 54), UDim2.fromOffset(18, 134))
redeem.Label.TextSize = 26

local result = label(panel, "", 15, Enum.Font.GothamBold, T.ink)
result.Size = UDim2.new(1, -36, 0, 40)
result.Position = UDim2.fromOffset(18, 196)

local busy = false
local function submit()
	if busy then
		return
	end
	busy = true
	redeem.Label.Text = "..."
	local ok, res = pcall(function()
		return Net.request():InvokeServer("redeemCode", box.Text)
	end)
	if ok and res and res.ok then
		Audio.play("CodeRedeemed")
		result.TextColor3 = Theme.C.lime
		result.Text = res.data.message
		box.Text = ""
	else
		Audio.play("UIError")
		result.TextColor3 = Theme.C.red
		result.Text = (ok and res and res.err) or "Couldn't reach the server."
	end
	redeem.Label.Text = "REDEEM"
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
