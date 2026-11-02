--!nonstrict
-- Tutorial overlay: spotlight, box, arrow and Coach Dee's bubble on top of any screen.
--
--   Screens register the parts a lesson can point at:
--     TutorialOverlay.register("TimeoutButton", button)
--   A lesson (see Tutorial.MatchLessons) freezes the game, dims everything except the focus,
--   draws a pulsing box around it with a bobbing arrow, and waits until the player does the action:
--     TutorialOverlay.lesson(lesson, { freeze = fn, resume = fn })  -- yields until done
--   A tip (Tutorial.Tips) is the light version: box + arrow + bubble, no dim, no freeze.
--     TutorialOverlay.tip(tip)
--
-- The dim is four frames around the focus rect (not one frame with a hole), so the focus stays
-- clickable and everything else is blocked.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local TutorialOverlay = {}

local INK = Color3.fromRGB(27, 33, 64)
local YELLOW = Color3.fromRGB(255, 226, 122)
local ORANGE = Color3.fromRGB(255, 122, 26)
local GREEN = Color3.fromRGB(47, 191, 79)
local DIM = 0.45 -- background transparency of the dim (0 = black)
local PAD = 8 -- box padding around the focus, in pixels

local targets = {} -- [name] = GuiObject
local gui

local function ensureGui()
	if gui then
		return gui
	end
	gui = Instance.new("ScreenGui")
	gui.Name = "TutorialOverlay"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 100
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return gui
end

function TutorialOverlay.register(name: string, obj: GuiObject)
	targets[name] = obj
end

-- Padded rect around one object, or around two (a drag's from and to).
local function rectOf(obj: GuiObject, other: GuiObject?)
	local p, s = obj.AbsolutePosition, obj.AbsoluteSize
	local x0, y0, x1, y1 = p.X, p.Y, p.X + s.X, p.Y + s.Y
	if other then
		local q, t = other.AbsolutePosition, other.AbsoluteSize
		x0, y0 = math.min(x0, q.X), math.min(y0, q.Y)
		x1, y1 = math.max(x1, q.X + t.X), math.max(y1, q.Y + t.Y)
	end
	return x0 - PAD, y0 - PAD, x1 - x0 + PAD * 2, y1 - y0 + PAD * 2
end

local function corner(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = inst
end

-- Builds the pieces for one focus. Returns a table with :place() to follow the target and :destroy().
local function build(focus: GuiObject, text: string, arrowDir: string, dim: boolean, button: string?, other: GuiObject?)
	local root = Instance.new("Frame")
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = ensureGui()

	local shades = {}
	if dim then
		for i = 1, 4 do
			local f = Instance.new("TextButton") -- a button so taps outside the focus are eaten
			f.AutoButtonColor = false
			f.Text = ""
			f.BackgroundColor3 = Color3.new(0, 0, 0)
			f.BackgroundTransparency = 1
			f.BorderSizePixel = 0
			f.Parent = root
			shades[i] = f
			TweenService:Create(f, TweenInfo.new(0.25), { BackgroundTransparency = DIM }):Play()
		end
	end

	local box = Instance.new("Frame")
	box.BackgroundTransparency = 1
	box.Parent = root
	corner(box, 14)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = YELLOW
	stroke.Parent = box
	TweenService:Create(stroke, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Color = ORANGE }):Play()

	-- Arrow: a chunky triangle glyph that bobs toward the focus.
	local arrow = Instance.new("TextLabel")
	arrow.BackgroundTransparency = 1
	arrow.Size = UDim2.fromOffset(48, 48)
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.Font = Enum.Font.GothamBlack
	arrow.TextSize = 44
	arrow.TextColor3 = YELLOW
	arrow.TextStrokeColor3 = INK
	arrow.TextStrokeTransparency = 0
	arrow.Text = ({ down = "▼", up = "▲", left = "◀", right = "▶" })[arrowDir] or "▼"
	arrow.Parent = root

	local bubble = Instance.new("Frame")
	bubble.Size = UDim2.fromOffset(320, 0)
	bubble.AutomaticSize = Enum.AutomaticSize.Y
	bubble.BackgroundColor3 = Color3.new(1, 1, 1)
	bubble.Parent = root
	corner(bubble, 14)
	local bs = Instance.new("UIStroke")
	bs.Thickness = 3
	bs.Color = INK
	bs.Parent = bubble
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 10), UDim.new(0, 10)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 12), UDim.new(0, 12)
	pad.Parent = bubble
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 6)
	list.Parent = bubble
	local who = Instance.new("TextLabel")
	who.BackgroundTransparency = 1
	who.Size = UDim2.new(1, 0, 0, 16)
	who.Font = Enum.Font.GothamBlack
	who.TextSize = 13
	who.TextColor3 = Color3.fromRGB(91, 99, 128)
	who.TextXAlignment = Enum.TextXAlignment.Left
	who.Text = "COACH DEE"
	who.Parent = bubble
	local body = Instance.new("TextLabel")
	body.BackgroundTransparency = 1
	body.Size = UDim2.new(1, 0, 0, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.Font = Enum.Font.GothamBold
	body.TextSize = 16
	body.TextWrapped = true
	body.TextColor3 = INK
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.Text = text
	body.Parent = bubble
	local okButton
	if button then
		okButton = Instance.new("TextButton")
		okButton.Size = UDim2.fromOffset(110, 36)
		okButton.BackgroundColor3 = GREEN
		okButton.Font = Enum.Font.FredokaOne
		okButton.TextSize = 18
		okButton.TextColor3 = Color3.new(1, 1, 1)
		okButton.Text = button
		okButton.Parent = bubble
		corner(okButton, 10)
	end

	local t0 = os.clock()
	local self = { root = root, ok = okButton }
	function self.place()
		local x, y, w, h = rectOf(focus, other)
		local vw, vh = root.AbsoluteSize.X, root.AbsoluteSize.Y
		if dim then
			shades[1].Position, shades[1].Size = UDim2.fromOffset(0, 0), UDim2.fromOffset(vw, math.max(0, y)) -- top
			shades[2].Position, shades[2].Size = UDim2.fromOffset(0, y + h), UDim2.fromOffset(vw, math.max(0, vh - y - h)) -- bottom
			shades[3].Position, shades[3].Size = UDim2.fromOffset(0, y), UDim2.fromOffset(math.max(0, x), h) -- left
			shades[4].Position, shades[4].Size = UDim2.fromOffset(x + w, y), UDim2.fromOffset(math.max(0, vw - x - w), h) -- right
		end
		box.Position, box.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(w, h)
		local bob = math.sin((os.clock() - t0) * 6) * 6
		local cx, cy = x + w / 2, y + h / 2
		-- The arrow sits on the side it points FROM, so "down" is above the focus.
		local ax, ay
		if arrowDir == "up" then
			ax, ay = cx, y + h + 30 + bob
		elseif arrowDir == "left" then
			ax, ay = x + w + 30 + bob, cy
		elseif arrowDir == "right" then
			ax, ay = x - 30 - bob, cy
		else
			ax, ay = cx, y - 30 - bob
		end
		arrow.Position = UDim2.fromOffset(ax, ay)
		-- Bubble goes on the roomier side, past the arrow, clamped to the screen.
		local bw, bh = 320, bubble.AbsoluteSize.Y
		local bx = math.clamp(cx - bw / 2, 12, vw - bw - 12)
		local by = (y + h / 2 < vh / 2) and (y + h + 64) or (y - bh - 64)
		bubble.Position = UDim2.fromOffset(bx, math.clamp(by, 12, vh - bh - 12))
	end
	function self.destroy()
		root:Destroy()
	end
	return self
end

-- Wait for the lesson's action. Returns when done.
local function waitAction(lesson, focus: GuiObject, pieces)
	local done = Instance.new("BindableEvent")
	local conns = {}
	local function finish()
		done:Fire()
	end
	if lesson.action == "ok" then
		table.insert(conns, pieces.ok.Activated:Connect(finish))
	elseif lesson.action == "tap" or lesson.action == "time" then
		-- The screen's own button still works; we just listen for it too.
		if focus:IsA("GuiButton") then
			table.insert(conns, focus.Activated:Connect(finish))
		else
			table.insert(conns, focus.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					finish()
				end
			end))
		end
	elseif lesson.action == "drag" then
		-- The screen does the drag and fires its own "dropped" signal through TutorialOverlay.dropped().
		TutorialOverlay._onDrop = function(from: string, to: string)
			if from == lesson.focus and to == lesson.dropOn then
				finish()
			end
		end
	end
	done.Event:Wait()
	for _, c in ipairs(conns) do
		c:Disconnect()
	end
	TutorialOverlay._onDrop = nil
	done:Destroy()
end

-- Screens call this after a drag-and-drop between registered parts.
function TutorialOverlay.dropped(from: string, to: string)
	if TutorialOverlay._onDrop then
		TutorialOverlay._onDrop(from, to)
	end
end

-- Show a match lesson. opts.freeze / opts.resume pause and resume the match playback.
function TutorialOverlay.lesson(lesson, opts)
	local focus = targets[lesson.focus]
	if not focus then
		warn("TutorialOverlay: nothing registered as " .. lesson.focus)
		return
	end
	opts = opts or {}
	if opts.freeze then
		opts.freeze()
	end
	-- For a drag, the hole covers both the thing you drag and where it goes.
	local other = lesson.dropOn and targets[lesson.dropOn] or nil
	local pieces = build(focus, lesson.text, lesson.arrow, true, lesson.action == "ok" and "Got it" or nil, other)
	local follow = RunService.RenderStepped:Connect(pieces.place)
	pieces.place()
	waitAction(lesson, focus, pieces)
	follow:Disconnect()
	pieces.destroy()
	if opts.resume then
		opts.resume()
	end
end

-- Show a first-time tip: no dim, no freeze, fades out.
function TutorialOverlay.tip(tip)
	local focus = targets[tip.focus]
	if not focus then
		return
	end
	local pieces = build(focus, tip.text, "down", false, nil)
	local follow = RunService.RenderStepped:Connect(pieces.place)
	pieces.place()
	local closed = false
	local function close()
		if closed then
			return
		end
		closed = true
		follow:Disconnect()
		pieces.destroy()
	end
	local tap = UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			close()
		end
	end)
	task.delay(tip.seconds or 5, function()
		tap:Disconnect()
		close()
	end)
end

return TutorialOverlay
