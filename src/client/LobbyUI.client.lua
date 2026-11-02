--!nonstrict
-- Lobby HUD: coins, gems and Elo along the top, and the Shop, Packs and Club screens.
--   Shop  : every pack with Buy; Buy opens the 1x / 5x / 20x popup.
--   Packs : the packs and bundles you own; Open plays the card reveal.
--   Club  : your roster. Tap two players to swap them, then Save the matchday ten.
-- Look: the Blacktop theme (src/client/Theme.lua).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Badges = require(Shared:WaitForChild("Badges"))
local Config = require(Shared:WaitForChild("Config"))
local Cosmetics = require(Shared:WaitForChild("Cosmetics"))
local Net = require(Shared:WaitForChild("Net"))
local Ratings = require(Shared:WaitForChild("Ratings"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local MatchView = require(script.Parent:WaitForChild("MatchView"))

local player = Players.LocalPlayer

local Theme = require(script.Parent:WaitForChild("Theme"))
local T = Theme.C
-- Old colour names mapped onto the Blacktop palette, so every screen picks up the new look.
local C = {
	bg = T.asphalt,
	panel = T.slate,
	ink = T.ink,
	muted = T.muted,
	blue = T.sky,
	orange = T.orange,
	gold = T.yellow,
	green = T.lime,
	rule = T.line,
	stage = T.deep,
	pink = T.pink,
	white = T.white,
	black = T.black,
	red = T.red,
}
local HEAD = Theme.HEAD
local BODY = Theme.BODY
local MARK = Theme.MARK

local function rarityColor(id)
	local r = Config.RarityById[id]
	return r and Color3.fromHex(r.color:sub(2)) or C.muted
end
local badgeName = {}
for _, b in ipairs(Badges.List) do
	badgeName[b.id] = b.name
end
local function rarityName(id)
	return id == "HallOfFame" and "Hall of Fame" or id or ""
end
local function comma(n)
	local s = tostring(math.floor(n or 0))
	repeat
		local k
		s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
	until k == 0
	return s
end

-- Small UI helpers (from Theme) ----------------------------------------------------------------
local make = Theme.make
local round = Theme.round
local stroke = Theme.stroke
local text = Theme.text
local function button(parent, label, color, sz, pos)
	local b = Theme.button(parent, label, color, sz, pos)
	b.MouseButton1Click:Connect(function()
		Audio.play("UIClick")
	end)
	return b
end

-- Requests: the server allows one call every 0.1 s, so calls queue up here.
local busy = false
local function call(action, payload)
	while busy do
		task.wait()
	end
	busy = true
	local ok, res = pcall(function()
		return Net.request():InvokeServer(action, payload)
	end)
	task.delay(0.12, function()
		busy = false
	end)
	if not ok or type(res) ~= "table" then
		return false, "Can't reach the server."
	end
	if res.ok then
		return true, res.data
	end
	return false, res.err
end

-- Screen ------------------------------------------------------------------------------------
local gui = make("ScreenGui", { Name = "Lobby", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 5 }, player:WaitForChild("PlayerGui"))

-- Toast for errors and confirmations: a strip of yellow tape.
local toast, toastText = Theme.tape(gui, "", { anchor = Vector2.new(0.5, 1), pos = UDim2.new(0.5, 0, 1, -104), sz = UDim2.fromOffset(340, 40), color = T.yellow, rot = -1, z = 50, font = HEAD, size = 18 })
toast.Visible = false
local toastId = 0
local function say(msg)
	toastId += 1
	local id = toastId
	toastText.Text = tostring(msg)
	toast.Visible = true
	task.delay(2.2, function()
		if toastId == id then
			toast.Visible = false
		end
	end)
end

-- Top bar: glossy currency bars, each with a big icon hanging off the left end.
local bar = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 12),
	Size = UDim2.fromOffset(540, 48),
	BackgroundTransparency = 1,
}, gui)
make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 26),
}, bar)
local function pill(tag, color, iconName, order)
	local holder = make("Frame", { Size = UDim2.fromOffset(150, 44), BackgroundTransparency = 1, LayoutOrder = order }, bar)
	local back = Theme.IMG.icon_bar
	local f
	if back then
		f = make("ImageLabel", { BackgroundTransparency = 1, Image = back, ScaleType = Enum.ScaleType.Stretch, Size = UDim2.new(1, 0, 1, 4), ZIndex = 2 }, holder)
	else
		f = make("Frame", { BackgroundColor3 = T.slate, Size = UDim2.fromScale(1, 1), ZIndex = 2 }, holder)
		round(f, 22)
		stroke(f, 3, C.black)
	end
	-- Icon inside the pill's left end, same size and padding on every pill.
	local ic = Theme.icon(holder, iconName, UDim2.fromOffset(38, 38), UDim2.fromOffset(6, 3), 4)
	if not ic then
		local chip = make("Frame", { Size = UDim2.new(0, 42, 1, -10), Position = UDim2.fromOffset(6, 5), BackgroundColor3 = color, ZIndex = 3 }, f)
		round(chip, 8)
		text(chip, { text = tag, font = HEAD, size = 15, color = C.black, z = 4 })
	end
	local v = text(f, { text = "…", font = HEAD, size = 24, color = C.white, sz = UDim2.new(1, -62, 1, -10), pos = UDim2.fromOffset(50, 2), align = Enum.TextXAlignment.Left, z = 3, scaled = true })
	make("UIStroke", { Thickness = 2, Color = C.black, LineJoinMode = Enum.LineJoinMode.Round }, v)
	return v
end
local coinsText = pill("COINS", C.gold, "coin", 1)
local gemsText = pill("GEMS", C.pink, "gem", 2)
local eloText = pill("ELO", C.blue, "trophy", 3)

local profile = {}
local function refreshBar()
	coinsText.Text = comma(profile.coins)
	gemsText.Text = comma(profile.gems)
	eloText.Text = profile.elo and comma(profile.elo) or "…"
end
local function loadProfile()
	local ok, data = call("getProfile")
	if ok then
		profile = data
		refreshBar()
	end
	return ok
end

-- Menu: stencil buttons down the left side, each with its own neon.
local menu = make("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 14, 0.5, -10),
	Size = UDim2.fromOffset(140, 4 * 58),
	BackgroundTransparency = 1,
}, gui)
make("UIListLayout", { Padding = UDim.new(0, 10) }, menu)

-- Modal panel shared by every screen: asphalt with a sunset strip and a tape title.
local shade = make("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.deep, BackgroundTransparency = 0.5, Visible = false, ZIndex = 10 }, gui)
if Theme.IMG.backdrop then
	-- Soft court backdrop with a vignette behind open screens.
	make("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = Theme.IMG.backdrop, ScaleType = Enum.ScaleType.Crop, ImageTransparency = 0.25, ZIndex = 10 }, shade)
end
local panel = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.53),
	Size = UDim2.fromScale(0.92, 0.82),
	BackgroundColor3 = C.bg,
	ZIndex = 11,
}, shade)
make("UISizeConstraint", { MaxSize = Vector2.new(720, 480) }, panel)
if not Theme.panelArt(panel, 11) then
	round(panel, 8)
	stroke(panel, 4, T.black)
	Theme.asphalt(panel)
end
local strip = make("Frame", { Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 0, 56), BackgroundColor3 = T.sunsetTop, ZIndex = 11, BorderSizePixel = 0 }, panel)
round(strip, 14)
Theme.sunset(strip)
-- Chain-link over the sunset (drawn tile, or thin lines as a fallback).
for i = 0, (Theme.chainlink(strip, 11) and -1 or 30) do
	for _, rot in ipairs({ 45, -45 }) do
		make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, i * 26, 0.5, 0), Size = UDim2.fromOffset(2, 84), Rotation = rot, BackgroundColor3 = T.black, BackgroundTransparency = 0.82, BorderSizePixel = 0, ZIndex = 11 }, strip)
	end
end
strip.ClipsDescendants = true
local titleTape, title = Theme.tape(panel, "", { pos = UDim2.fromOffset(16, 10), sz = UDim2.fromOffset(260, 40), rot = -2, z = 12, size = 24 })
local close = button(panel, "X", C.red, UDim2.fromOffset(42, 42), UDim2.new(1, -54, 0, 8))
close.ZIndex = 12
close.Label.FontFace = HEAD
close.Label.TextSize = 24
local body = make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -24, 1, -76), Position = UDim2.fromOffset(12, 66), ZIndex = 12 }, panel)
local panelScale = make("UIScale", {}, panel)

local function clearBody()
	for _, c in ipairs(body:GetChildren()) do
		c:Destroy()
	end
end
local function openPanel(name)
	title.Text = name
	titleTape.Size = UDim2.fromOffset(math.clamp(#name * 17 + 40, 160, 420), 40)
	clearBody()
	text(body, { text = "Loading...", font = HEAD, size = 20, color = C.muted, z = 12 }).Name = "Loading"
	if not shade.Visible then
		Audio.play("UIOpenPanel")
	end
	shade.Visible = true
	panelScale.Scale = 0.85
	TweenService:Create(panelScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end
local function closePanel()
	Audio.play("UIClosePanel")
	shade.Visible = false
	clearBody()
end
close.MouseButton1Click:Connect(closePanel)

local function scroller(parent)
	local s = make("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.XY,
		CanvasSize = UDim2.new(),
		BorderSizePixel = 0,
		ZIndex = 12,
	}, parent)
	return s
end

-- Shop ---------------------------------------------------------------------------------------
local openShop, openPacks, openClub
local refreshBoard

local KIND_TEXT = { players = "Players, badges, item", badges = "Badges only", coach = "One coach" }

-- The shop has three tabs, like the bigger games: PACKS (coins), ROBUX and CODES.
local SHOP_TABS = { { "PACKS", T.yellow }, { "ROBUX", T.lime }, { "CODES", T.sky } }

local function packArt(card, pack, i)
	-- The pack itself: a rendered foil wrapper when we have one.
	local art = Theme.IMG["pack_" .. pack.id]
	-- Square bundle art (x1/x5/x20) when we have it; it already has the stack and the badge.
	local square = Theme.IMG["packq_" .. pack.id .. "_x1"]
	if art or square then
		local img = make("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 14),
			Size = square and UDim2.fromOffset(152, 172) or UDim2.fromOffset(110, 165),
			BackgroundTransparency = 1,
			Image = square or art,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 13,
		}, card)
		-- Gentle bob so the shelf feels alive, a shine across the foil, and sparkles on the top packs.
		TweenService:Create(img, TweenInfo.new(1.6 + (i % 3) * 0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = UDim2.new(0.5, 0, 0, 19) }):Play()
		if not square then
			Theme.shine(img, 3.5, 14, 0.45) -- a shine band would show across the square art's empty corners
		end
		local fancy = { AllStar = C.gold, HallOfFame = C.pink, EliteCoach = C.gold }
		if fancy[pack.id] then
			Theme.glow(img, fancy[pack.id], 18, 0.5)
			Theme.sparkles(img, Color3.new(1, 1, 1), 0.45, 15, 20)
		end
		return img
	else
		local best
		for id in pairs(pack.odds or {}) do
			if not best or Config.RarityById[id].order > Config.RarityById[best].order then
				best = id
			end
		end
		local box = make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 4), Size = UDim2.fromOffset(116, 176), BackgroundColor3 = best and rarityColor(best) or C.pink, ZIndex = 13 }, card)
		round(box, 6)
		stroke(box, 3, C.black)
		make("UIGradient", { Rotation = 70, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.25), NumberSequenceKeypoint.new(1, 0) }) }, box)
		local tag = text(box, { text = pack.name:gsub(" Pack", ""), font = MARK, size = 24, color = C.white, z = 14, scaled = true, rot = -6, sz = UDim2.new(1, -10, 0, 60), pos = UDim2.new(0, 5, 0.5, -30) })
		tag.TextStrokeTransparency = 0
		tag.TextStrokeColor3 = C.black
		return box
	end
end

-- Buy one bundle size of a pack (1x, 5x or 20x); a bundle is one item in My Packs.
local buyingPack = false
local function buyPackSize(pack, pr)
	if buyingPack then
		return
	end
	buyingPack = true
	local ok, res = call("buyPack", { pack = pack.id, size = pr.size })
	buyingPack = false
	if ok then
		profile.coins = res.coins
		refreshBar()
		pcall(Audio.play, "CoinsSpend")
		say(pr.size > 1 and string.format("%dx %s added to Packs", pr.size, pack.name) or pack.name .. " added to Packs")
	else
		say(res)
	end
end

-- Amount picker on the pack itself (js 2026-11-02): arrows either side flip between 1x, 5x
-- and 20x; the art shows a stack of that many packs with an "x5" badge, and the price follows.
local function qtyArrow(card, dir, onClick)
	local art = Theme.IMG[dir < 0 and "icon_arrow_left" or "icon_arrow_right"]
	local b = make("ImageButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(dir < 0 and 0 or 1, dir < 0 and 15 or -15, 0, 96),
		Size = UDim2.fromOffset(30, 30),
		BackgroundTransparency = art and 1 or 0,
		BackgroundColor3 = C.white,
		Image = art or "",
		AutoButtonColor = false,
		ZIndex = 17,
	}, card)
	if not art then
		round(b, 15)
		stroke(b, 2.5, C.black)
		text(b, { text = dir < 0 and "<" or ">", font = HEAD, size = 22, color = C.black, z = 18 })
	end
	local sc = make("UIScale", {}, b)
	b.MouseButton1Down:Connect(function()
		TweenService:Create(sc, TweenInfo.new(0.07), { Scale = 0.85 }):Play()
	end)
	b.MouseButton1Up:Connect(function()
		TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(sc, TweenInfo.new(0.15), { Scale = 1 }):Play()
	end)
	b.MouseButton1Click:Connect(onClick)
	return b
end

local function packGrid(parent, packs, currency)
	local s = scroller(parent)
	make("UIGridLayout", { CellSize = UDim2.fromOffset(160, 262), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }, s)
	for i, pack in ipairs(packs) do
		local card = make("Frame", { BackgroundTransparency = 1, LayoutOrder = i, ZIndex = 12 }, s)
		local img = packArt(card, pack, i)
		local robux = (Config.Packs[pack.id] or {}).robux
		local priceLabel = currency == "robux" and ("R$ " .. comma(robux or 0)) or ""
		-- Price on a strip of tape under the pack, then the buy button.
		local tape, priceText = Theme.tape(card, priceLabel, { anchor = Vector2.new(0.5, 0), pos = UDim2.new(0.5, 0, 0, 190), sz = UDim2.fromOffset(132, 28), rot = (i % 2 == 0) and 2 or -2, z = 14, font = HEAD, size = 17 })
		priceText.TextColor3 = C.black
		local buy = button(card, currency == "robux" and "BUY  R$" or "BUY", currency == "robux" and T.lime or C.orange, UDim2.new(1, -16, 0, 40), UDim2.new(0, 8, 1, -42))
		buy.ZIndex = 13
		if currency == "robux" then
			buy.MouseButton1Click:Connect(function()
				-- Robux products aren't set up on Roblox yet, so nothing is charged.
				Audio.play("UIError")
				say("Robux buying opens at launch")
			end)
			continue
		end
		local q = 1
		local priceRow, stack, badge, off
		local baseArt = img and img:IsA("ImageLabel") and img.Image or nil
		local function show(animate)
			local pr = pack.prices[q]
			if priceRow then
				priceRow:Destroy()
			end
			-- Coin sticker and the number, no "coins" word.
			priceRow = Theme.row(tape, { { icon = "coin", iconSize = 26 }, { text = comma(pr.coins) } }, { size = 18, z = 15, color = C.black, outline = false, gap = 3 })
			-- Pack art for this amount: a drawn stack when we have it, else copies fanned behind.
			local qtyArt = Theme.IMG["packq_" .. pack.id .. "_x" .. pr.size]
			if stack then
				stack:Destroy()
				stack = nil
			end
			if img and img:IsA("ImageLabel") then
				img.Image = qtyArt or baseArt
				if not qtyArt and pr.size > 1 then
					stack = make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 12 }, card)
					local n = pr.size >= 20 and 3 or 2
					for k = n, 1, -1 do
						local ghost = make("ImageLabel", {
							AnchorPoint = Vector2.new(0.5, 0),
							Position = UDim2.new(0.5, k * 7, 0, 14 + k * 2),
							Size = UDim2.fromOffset(110, 165),
							Rotation = k * 5,
							BackgroundTransparency = 1,
							Image = baseArt,
							ImageColor3 = Color3.new(1, 1, 1):Lerp(C.black, 0.12 * k),
							ScaleType = Enum.ScaleType.Fit,
							ZIndex = 12,
						}, stack)
						if animate then
							local from = ghost.Position
							ghost.Position = UDim2.new(0.5, 0, 0, 14)
							ghost.Rotation = 0
							TweenService:Create(ghost, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = from, Rotation = k * 5 }):Play()
						end
					end
				end
			end
			-- "x5" badge on the pack, and the saving on a red sticker.
			if badge then
				badge:Destroy()
				badge = nil
			end
			if pr.size > 1 and not qtyArt then
				badge = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -40, 0, 158), Size = UDim2.fromOffset(46, 46), BackgroundColor3 = C.gold, ZIndex = 16 }, card)
				round(badge, 25)
				stroke(badge, 3, C.black)
				local bt = text(badge, { text = "x" .. pr.size, font = HEAD, size = 22, color = C.white, z = 17 })
				make("UIStroke", { Thickness = 2, Color = C.black }, bt)
				if animate then
					local bs = make("UIScale", { Scale = 0.3 }, badge)
					TweenService:Create(bs, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
				end
			end
			if off then
				off:Destroy()
				off = nil
			end
			if pr.discount > 0 then
				off = Theme.tape(card, string.format("-%d%%", math.floor(pr.discount * 100 + 0.5)), { anchor = Vector2.new(0.5, 0.5), pos = UDim2.new(0, 36, 0, 40), sz = UDim2.fromOffset(62, 26), rot = -10, z = 16, font = HEAD, size = 17, color = C.red })
			end
			buy.Label.Text = pr.size > 1 and ("BUY x" .. pr.size) or "BUY"
			if animate and img then
				local ps = img:FindFirstChild("Pop") or make("UIScale", { Name = "Pop" }, img)
				ps.Scale = 0.9
				TweenService:Create(ps, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			end
		end
		local function step(d)
			q = (q - 1 + d) % #pack.prices + 1
			pcall(Audio.play, "UIClick")
			show(true)
		end
		if #pack.prices > 1 then
			qtyArrow(card, -1, function()
				step(-1)
			end)
			qtyArrow(card, 1, function()
				step(1)
			end)
		end
		show(false)
		buy.MouseButton1Click:Connect(function()
			buyPackSize(pack, pack.prices[q])
		end)
		-- Same as tapping the arrows; also lets playtests set the amount directly.
		card:GetAttributeChangedSignal("Qty"):Connect(function()
			local want = card:GetAttribute("Qty")
			for k, pr in ipairs(pack.prices) do
				if pr.size == want and k ~= q then
					q = k
					show(true)
				end
			end
		end)
	end
end

local function codesTab(parent)
	local card = make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.new(1, -40, 0, 250), BackgroundColor3 = T.slate, ZIndex = 12 }, parent)
	make("UISizeConstraint", { MaxSize = Vector2.new(460, 250) }, card)
	round(card, 16)
	stroke(card, 3, T.line)
	text(card, { text = "Got a code?", font = HEAD, size = 30, color = T.yellow, sz = UDim2.new(1, 0, 0, 40), pos = UDim2.fromOffset(0, 14), z = 13 })
	text(card, { text = "New codes drop with updates and milestones.", size = 15, color = C.muted, sz = UDim2.new(1, -20, 0, 20), pos = UDim2.fromOffset(10, 54), z = 13 })
	local box = make("TextBox", {
		Size = UDim2.new(1, -40, 0, 50),
		Position = UDim2.fromOffset(20, 88),
		BackgroundColor3 = T.deep,
		PlaceholderText = "Type code here...",
		PlaceholderColor3 = C.muted,
		Text = "",
		TextSize = 24,
		FontFace = HEAD,
		TextColor3 = T.ink,
		ClearTextOnFocus = false,
		ZIndex = 13,
	}, card)
	round(box, 12)
	stroke(box, 2, T.line)
	local claim = button(card, "CLAIM", T.lime, UDim2.new(1, -40, 0, 54), UDim2.fromOffset(20, 148))
	claim.ZIndex = 13
	claim.Label.TextSize = 26
	local result = text(card, { text = "", size = 15, sz = UDim2.new(1, -20, 0, 36), pos = UDim2.fromOffset(10, 206), z = 13 })
	local busyClaim = false
	local function submit()
		if busyClaim or box.Text == "" then
			return
		end
		busyClaim = true
		claim.Label.Text = "..."
		local ok, res = call("redeemCode", box.Text)
		if ok then
			pcall(Audio.play, "CodeRedeemed")
			result.TextColor3 = T.lime
			result.Text = (type(res) == "table" and res.message) or "Code claimed!"
			box.Text = ""
			loadProfile()
		else
			pcall(Audio.play, "UIError")
			result.TextColor3 = T.red
			result.Text = tostring(res)
		end
		claim.Label.Text = "CLAIM"
		busyClaim = false
	end
	claim.MouseButton1Click:Connect(submit)
	box.FocusLost:Connect(function(enter)
		if enter then
			submit()
		end
	end)
end

local function showShopTab(tab)
	clearBody()
	-- Tab bar along the top of the panel; the open tab is lit up.
	local bar = make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), ZIndex = 12 }, body)
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, bar)
	for i, t in ipairs(SHOP_TABS) do
		local active = t[1] == tab
		local b = button(bar, t[1], active and t[2] or T.slate, UDim2.fromOffset(120, 42))
		b.LayoutOrder = i
		b.ZIndex = 12
		b.Label.TextSize = 20
		if not active then
			b.Label.TextColor3 = C.muted
		end
		b.MouseButton1Click:Connect(function()
			if not active then
				showShopTab(t[1])
			end
		end)
	end
	local content = make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -52), Position = UDim2.fromOffset(0, 52), ZIndex = 12 }, body)
	if tab == "CODES" then
		codesTab(content)
		return
	end
	local loading = text(content, { text = "Loading...", font = HEAD, size = 20, color = C.muted, z = 12 })
	local ok, data = call("getShop")
	loading:Destroy()
	if not ok then
		text(content, { text = tostring(data), font = HEAD, size = 20, color = C.muted, z = 12 })
		return
	end
	packGrid(content, data.packs, tab == "ROBUX" and "robux" or "coins")
end

function openShop(tab)
	openPanel("SHOP")
	showShopTab(tab or "PACKS")
end

-- Card reveal -------------------------------------------------------------------------------
local function drawCard(parent, c, z)
	local f = make("Frame", { Size = UDim2.fromOffset(150, 210), BackgroundColor3 = T.tape, ZIndex = z }, parent)
	round(f, 6)
	stroke(f, 4, C.black)
	-- Inner frame in the rarity colour, like the border of a street card.
	local inner = make("Frame", { Size = UDim2.new(1, -10, 1, -10), Position = UDim2.fromOffset(5, 5), BackgroundTransparency = 1, ZIndex = z }, f)
	round(inner, 4)
	stroke(inner, 3, rarityColor(c.rarity))
	local band = make("Frame", { Size = UDim2.new(1, -20, 0, 26), Position = UDim2.fromOffset(10, 8), Rotation = -2, BackgroundColor3 = rarityColor(c.rarity), ZIndex = z + 1 }, f)
	round(band, 2)
	stroke(band, 2, C.black)
	text(band, { text = rarityName(c.rarity):upper(), font = HEAD, size = 15, color = Theme.textOn(rarityColor(c.rarity)), z = z + 2 })
	if c.kind == "coach" then
		text(f, { text = (c.side or "") .. " COACH", font = HEAD, size = 16, color = Color3.fromHex("5a5650"), sz = UDim2.new(1, 0, 0, 24), pos = UDim2.fromOffset(0, 40), z = z + 1 })
		text(f, { color = C.black, text = c.name, font = HEAD, size = 20, sz = UDim2.new(1, -12, 0, 52), pos = UDim2.fromOffset(6, 74), z = z + 1, scaled = true })
		local styles = {}
		for _, st in ipairs(c.styles or {}) do
			table.insert(styles, type(st) == "table" and (st.name or st.id) or tostring(st))
		end
		text(f, { text = table.concat(styles, ", "), size = 12, color = Color3.fromHex("5a5650"), sz = UDim2.new(1, -12, 0, 60), pos = UDim2.fromOffset(6, 132), z = z + 1 })
		return f
	end
	text(f, { color = C.black, text = tostring(c.ovr), font = HEAD, size = 44, sz = UDim2.fromOffset(70, 50), pos = UDim2.fromOffset(14, 36), z = z + 1, align = Enum.TextXAlignment.Left })
	text(f, { text = c.pos or "", font = HEAD, size = 22, color = C.black, sz = UDim2.fromOffset(60, 30), pos = UDim2.new(1, -74, 0, 44), z = z + 1, align = Enum.TextXAlignment.Right })
	text(f, { color = C.black, text = c.name, font = MARK, size = 20, sz = UDim2.new(1, -12, 0, 48), pos = UDim2.fromOffset(6, 90), z = z + 1, scaled = true })
	text(f, { text = c.archetype and Ratings.archetypeName(c.archetype) or "", size = 13, color = Color3.fromHex("5a5650"), sz = UDim2.new(1, -12, 0, 18), pos = UDim2.fromOffset(6, 140), z = z + 1 })
	local ft = c.height and string.format("%d'%d\"", math.floor(c.height / 12), c.height % 12) or ""
	text(f, { text = ft .. (c.nation and ("  ·  " .. c.nation) or ""), size = 12, color = Color3.fromHex("5a5650"), sz = UDim2.new(1, -12, 0, 18), pos = UDim2.fromOffset(6, 162), z = z + 1 })
	return f
end

local ITEM_TEXT = {
	CoinPouch = function(it)
		return string.format("Coin Pouch: +%s coins", comma(it.coins))
	end,
	Cosmetic = function(it)
		return "Cosmetic: " .. tostring((Cosmetics.ById[it.cosmetic] or {}).name or it.cosmetic) .. (it.duplicate and " (duplicate)" or "")
	end,
	ScoutTicket = function()
		return "Scout Ticket"
	end,
	BadgeUpgrade = function(it)
		return tostring(it.from) .. " Badge Upgrade"
	end,
}

local function reveal(result)
	openPanel("PACK OPENED")
	-- One page per card, then a summary of badges and items.
	local cards, extras = {}, {}
	for _, pk in ipairs(result.packs) do
		for _, c in ipairs(pk.cards) do
			table.insert(cards, c)
		end
		for _, b in ipairs(pk.badges or {}) do
			table.insert(extras, string.format("%s badge: %s", tostring(b.tier), badgeName[b.badge] or tostring(b.badge)))
		end
		for _, it in ipairs(pk.items or {}) do
			local f = ITEM_TEXT[it.id]
			table.insert(extras, f and f(it) or tostring(it.name or it.id))
		end
	end
	-- A CanvasGroup so the spinning rays are clipped to the stage.
	local stage = make("CanvasGroup", { Size = UDim2.new(1, 0, 1, -50), BackgroundColor3 = C.stage, ZIndex = 12 }, body)
	round(stage, 12)
	Theme.stageArt(stage, 12)
	local count = text(body, { font = HEAD, size = 18, color = C.muted, sz = UDim2.new(0.5, 0, 0, 40), pos = UDim2.new(0, 4, 1, -42), align = Enum.TextXAlignment.Left, z = 12 })
	local nextB = button(body, "NEXT", C.orange, UDim2.fromOffset(140, 40), UDim2.new(1, -140, 1, -42))
	nextB.ZIndex = 12
	local i = 0
	local function step()
		for _, c in ipairs(stage:GetChildren()) do
			if not c:IsA("UICorner") and c.Name ~= "StageArt" then
				c:Destroy()
			end
		end
		i += 1
		if i <= #cards then
			local c = cards[i]
			count.Text = string.format("Card %d of %d", i, #cards)
			local holder = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(150, 210), BackgroundTransparency = 1, ZIndex = 13 }, stage)
			local f = drawCard(holder, c, 13)
			-- Flip in: start edge-on, then grow; rarer cards get a glow and a longer beat.
			local sc = make("UIScale", { Scale = 1.15 }, holder)
			f.Size = UDim2.fromOffset(0, 210)
			f.Position = UDim2.fromOffset(75, 0)
			local order = (Config.RarityById[c.rarity] or { order = 1 }).order
			-- Light behind the card, more of it the rarer the card.
			local rc = rarityColor(c.rarity)
			local rays = Theme.rays(stage, rc, 300 + order * 60, 12, math.max(0.25, 0.75 - order * 0.1))
			if rays then
				local rs = make("UIScale", { Scale = 0.2 }, rays)
				TweenService:Create(rs, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			end
			Theme.glow(holder, rc, 50, 0.45 + order * 0.08)
			if order >= 3 then
				Theme.sparkles(stage, order >= 4 and rc or C.white, 0.5 - order * 0.07, 16, 18 + order * 3)
			end
			if order >= 4 then
				Theme.wisps(stage, rc, 0.35, 13)
			end
			task.delay(0.4, function()
				if f.Parent then
					Theme.shine(f, 3, 20, 0.6)
				end
			end)
			Audio.play("CardFlip")
			Audio.play("Reveal" .. (c.rarity or "Common"))
			TweenService:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(150, 210), Position = UDim2.new() }):Play()
			TweenService:Create(sc, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			nextB.Label.Text = (i == #cards and #extras == 0) and "DONE" or "NEXT"
		elseif i == #cards + 1 and #extras > 0 then
			count.Text = "Also in the pack"
			local list = make("Frame", { Size = UDim2.new(1, -24, 1, -24), Position = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, ZIndex = 13 }, stage)
			make("UIListLayout", { Padding = UDim.new(0, 6) }, list)
			for _, line in ipairs(extras) do
				local row = make("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.panel, ZIndex = 13 }, list)
				round(row, 8)
				text(row, { text = line, size = 16, sz = UDim2.new(1, -16, 1, 0), pos = UDim2.fromOffset(10, 0), align = Enum.TextXAlignment.Left, z = 14 })
			end
			nextB.Label.Text = "DONE"
		else
			openPacks()
		end
	end
	nextB.MouseButton1Click:Connect(step)
	-- The pack first: it shakes, flashes and bursts, then the cards come out.
	local art = Theme.IMG["pack_" .. tostring(result.pack)]
	if art then
		nextB.Visible = false
		count.Text = ""
		local packRays = Theme.rays(stage, C.gold, 520, 13, 0.55)
		-- Wisps only while the pack is on screen: they live in a layer removed with it.
		local packFx = make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 13 }, stage)
		Theme.wisps(packFx, C.gold, 0.25, 13)
		local p = make("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(170, 255), BackgroundTransparency = 1, Image = art, ZIndex = 14 }, stage)
		local sc = make("UIScale", { Scale = 0.6 }, p)
		TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		task.wait(0.4)
		for k = 1, 6 do
			Audio.play("UIClick")
			TweenService:Create(p, TweenInfo.new(0.07), { Rotation = (k % 2 == 0) and 7 or -7 }):Play()
			task.wait(0.09 + k * 0.01)
		end
		local flash = make("Frame", { Size = UDim2.new(1, 0, 1, -50), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, ZIndex = 20 }, body)
		round(flash, 12)
		TweenService:Create(flash, TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play()
		TweenService:Create(sc, TweenInfo.new(0.2), { Scale = 1.5 }):Play()
		task.wait(0.18)
		p:Destroy()
		if packRays then
			packRays:Destroy()
		end
		packFx:Destroy()
		TweenService:Create(flash, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
		task.delay(0.4, function()
			flash:Destroy()
		end)
		nextB.Visible = true
	end
	step()
end

-- Packs (inventory) --------------------------------------------------------------------------
function openPacks()
	openPanel("MY PACKS")
	local ok, data = call("getInventory")
	local loading = body:FindFirstChild("Loading")
	if loading then
		loading:Destroy()
	end
	if not ok then
		text(body, { text = tostring(data), font = HEAD, size = 20, color = C.muted, z = 12 })
		return
	end
	if #data.items == 0 then
		text(body, { text = "No packs yet. Buy some in the Shop!", font = HEAD, size = 20, color = C.muted, z = 12 })
		local go = button(body, "GO TO SHOP", C.orange, UDim2.fromOffset(180, 44), UDim2.new(0.5, -90, 0.5, 30))
		go.ZIndex = 12
		go.MouseButton1Click:Connect(openShop)
		return
	end
	-- A shelf of your packs: the wrapper, how many you have, and OPEN.
	local s = scroller(body)
	make("UIGridLayout", { CellSize = UDim2.fromOffset(150, 258), CellPadding = UDim2.fromOffset(12, 10), SortOrder = Enum.SortOrder.LayoutOrder }, s)
	for i, it in ipairs(data.items) do
		local cell = make("Frame", { BackgroundTransparency = 1, LayoutOrder = i, ZIndex = 12 }, s)
		local art = Theme.IMG["pack_" .. tostring(it.pack)]
		local copies = it.size > 1 and 3 or (it.count > 1 and 2 or 1)
		for k = copies, 1, -1 do
			-- Bundles and stacks show a few wrappers fanned behind the front one.
			local off = (k - 1) * 9
			if art then
				make("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, off, 0, 4 - off * 0.4), Size = UDim2.fromOffset(118, 177), Rotation = (k - 1) * 5, BackgroundTransparency = 1, Image = art, ImageColor3 = k > 1 and Color3.fromRGB(150, 150, 150) or Color3.new(1, 1, 1), ZIndex = 13 + copies - k }, cell)
			else
				local box = make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, off, 0, 4), Size = UDim2.fromOffset(110, 170), BackgroundColor3 = C.orange, ZIndex = 13 + copies - k }, cell)
				round(box, 6)
				stroke(box, 3, C.black)
			end
		end
		local label = it.size > 1 and string.format("%dx BUNDLE", it.size) or ("x" .. it.count)
		Theme.tape(cell, label, { anchor = Vector2.new(0.5, 0), pos = UDim2.new(0.5, 0, 0, 184), sz = UDim2.fromOffset(110, 28), rot = (i % 2 == 0) and 2 or -2, z = 18, font = HEAD, size = 17 })
		local b = button(cell, "OPEN", C.green, UDim2.new(1, -12, 0, 42), UDim2.new(0, 6, 1, -44))
		b.ZIndex = 18
		b.MouseButton1Click:Connect(function()
			if not b.Active then
				return
			end
			b.Active = false
			local ok2, res = call("openPack", it.key)
			if ok2 then
				profile.coins = res.coins
				refreshBar()
				task.spawn(refreshBoard)
				reveal(res)
			else
				b.Active = true
				say(res)
			end
		end)
	end
end

-- Club (roster and matchday) -----------------------------------------------------------------
function openClub()
	openPanel("MY CLUB")
	local ok, data = call("getRoster")
	local loading = body:FindFirstChild("Loading")
	if loading then
		loading:Destroy()
	end
	if not ok then
		text(body, { text = tostring(data), font = HEAD, size = 20, color = C.muted, z = 12 })
		return
	end
	-- order: the matchday ten first (5 starters, 5 bench), then the rest by OVR.
	local order = data.players
	local picked
	local s = scroller(body)
	s.Size = UDim2.new(1, 0, 1, -50)
	local hint = text(body, { text = "Tap two players to swap them.", size = 14, color = C.muted, sz = UDim2.new(1, -160, 0, 40), pos = UDim2.new(0, 4, 1, -42), align = Enum.TextXAlignment.Left, z = 12 })
	local save = button(body, "SAVE LINEUP", C.blue, UDim2.fromOffset(150, 40), UDim2.new(1, -150, 1, -42))
	save.ZIndex = 12
	local draw
	function draw()
		for _, c in ipairs(s:GetChildren()) do
			c:Destroy()
		end
		make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, s)
		local function header(t, n)
			local h = text(s, { text = t, font = HEAD, size = 16, color = C.muted, sz = UDim2.new(1, -10, 0, 24), align = Enum.TextXAlignment.Left, z = 12 })
			h.LayoutOrder = n
		end
		header("STARTERS", 0)
		header("BENCH", 55)
		if #order > 10 then
			header("RESERVES", 105)
		end
		for i, p in ipairs(order) do
			local row = make("TextButton", {
				Text = "",
				AutoButtonColor = true,
				Size = UDim2.new(1, -10, 0, 40),
				BackgroundColor3 = picked == i and Color3.fromHex("4a4228") or C.panel,
				LayoutOrder = i <= 5 and i or (i <= 10 and 50 + i or 100 + i),
				ZIndex = 12,
			}, s)
			round(row, 8)
			stroke(row, picked == i and 3 or 1, picked == i and C.gold or C.rule)
			local chip = make("Frame", { Size = UDim2.fromOffset(6, 28), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = rarityColor(p.rarity), ZIndex = 13 }, row)
			round(chip, 3)
			text(row, { text = tostring(p.ovr), font = HEAD, size = 20, sz = UDim2.fromOffset(40, 40), pos = UDim2.fromOffset(16, 0), z = 13 })
			text(row, { text = p.pos or "", font = HEAD, size = 16, color = C.blue, sz = UDim2.fromOffset(40, 40), pos = UDim2.fromOffset(56, 0), z = 13 })
			text(row, { text = p.name, font = BODY, size = 16, sz = UDim2.new(1, -230, 1, 0), pos = UDim2.fromOffset(100, 0), align = Enum.TextXAlignment.Left, z = 13 })
			text(row, { text = p.archetype and Ratings.archetypeName(p.archetype) or "", size = 13, color = C.muted, sz = UDim2.fromOffset(120, 40), pos = UDim2.new(1, -126, 0, 0), align = Enum.TextXAlignment.Right, z = 13 })
			row.MouseButton1Click:Connect(function()
				Audio.play("UIClick")
				if not picked then
					picked = i
				elseif picked == i then
					picked = nil
				else
					order[picked], order[i] = order[i], order[picked]
					picked = nil
					hint.Text = "Lineup changed. Save it to use it in matches."
				end
				draw()
			end)
		end
	end
	draw()
	save.MouseButton1Click:Connect(function()
		if #order < 10 then
			say("You need 10 players.")
			return
		end
		local ids = {}
		for i = 1, 10 do
			ids[i] = order[i].id
		end
		local ok2, res = call("setMatchday", ids)
		if ok2 then
			hint.Text = "Lineup saved."
			Audio.play("UIToggle")
		else
			say(res)
		end
	end)
end

-- Quests -------------------------------------------------------------------------------------
local function openQuests()
	openPanel("DAILY QUESTS")
	local ok, data = call("getQuests")
	local loading = body:FindFirstChild("Loading")
	if loading then
		loading:Destroy()
	end
	if not ok then
		text(body, { text = tostring(data), font = HEAD, size = 20, color = C.muted, z = 12 })
		return
	end
	local list = make("Frame", { Size = UDim2.new(1, 0, 1, -40), BackgroundTransparency = 1, ZIndex = 12 }, body)
	make("UIListLayout", { Padding = UDim.new(0, 10) }, list)
	local tints = { C.gold, C.blue, C.pink, C.green, C.orange }
	for i, q in ipairs(data.list) do
		local done = q.progress >= q.target
		-- A soft card per quest: sticker icon, title, a chunky progress bar and the reward.
		-- White base: the UIGradient colours below multiply it, so they are the real colours.
		local row = make("Frame", { Size = UDim2.new(1, 0, 0, 78), BackgroundColor3 = C.white, ZIndex = 12 }, list)
		round(row, 16)
		stroke(row, 2.5, C.black)
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromHex("4b5160"), Color3.fromHex("3a3f4b")) }, row)
		local chip = make("Frame", { Size = UDim2.fromOffset(58, 58), Position = UDim2.fromOffset(10, 10), BackgroundColor3 = tints[(i - 1) % #tints + 1], ZIndex = 13 }, row)
		round(chip, 14)
		stroke(chip, 2.5, C.black)
		Theme.icon(chip, q.claimed and "trophy" or "quests", UDim2.fromOffset(50, 50), UDim2.fromOffset(4, 4), 14)
		local title = text(row, { text = q.text, font = HEAD, size = 19, sz = UDim2.new(1, -240, 0, 28), pos = UDim2.fromOffset(80, 6), align = Enum.TextXAlignment.Left, z = 13 })
		make("UIStroke", { Thickness = 1.5, Color = C.black }, title)
		-- Progress bar.
		local track = make("Frame", { Size = UDim2.new(1, -240, 0, 22), Position = UDim2.fromOffset(80, 40), BackgroundColor3 = C.stage, ZIndex = 13 }, row)
		round(track, 11)
		stroke(track, 2, C.black)
		local frac = math.clamp(q.progress / math.max(1, q.target), 0, 1)
		local fill = make("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = done and C.green or C.gold, ZIndex = 14 }, track)
		round(fill, 11)
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHex("d8d8d8")) }, fill)
		if frac > 0 then
			TweenService:Create(fill, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(math.max(frac, 0.08), 0, 1, 0) }):Play()
		end
		local pt = text(track, { text = string.format("%d / %d", math.min(q.progress, q.target), q.target), font = HEAD, size = 15, z = 15 })
		make("UIStroke", { Thickness = 1.5, Color = C.black }, pt)
		-- Reward: coin sticker and amount.
		Theme.icon(row, "coin", UDim2.fromOffset(30, 30), UDim2.new(1, -152, 0, 6), 13)
		local rw = text(row, { text = comma(q.coins), font = HEAD, size = 18, color = C.gold, sz = UDim2.fromOffset(60, 30), pos = UDim2.new(1, -120, 0, 6), align = Enum.TextXAlignment.Left, z = 13 })
		make("UIStroke", { Thickness = 1.5, Color = C.black }, rw)
		local b = button(row, q.claimed and "DONE" or (done and "CLAIM" or "GO"), q.claimed and T.slate or (done and C.green or C.blue), UDim2.fromOffset(110, 40), UDim2.new(1, -120, 0, 32))
		b.ZIndex = 13
		b.Label.TextSize = 18
		if done and not q.claimed then
			-- Claimable: glow, shine and sparkles so it gets noticed.
			Theme.glow(b, C.green, 16, 0.8)
			Theme.shine(b, 2.5)
			Theme.sparkles(row, C.gold, 0.4, 16, 20)
			b.MouseButton1Click:Connect(function()
				local ok2, res = call("claimQuest", i)
				if ok2 then
					profile.coins = (profile.coins or 0) + res.coins
					refreshBar()
					Audio.play("CoinsGainM")
					openQuests()
					task.spawn(refreshBoard)
				else
					say(res)
				end
			end)
		else
			b.AutoButtonColor = false
			b.Label.TextColor3 = q.claimed and C.muted or C.white
			if not q.claimed then
				b.MouseButton1Click:Connect(function()
					say("Play matches to finish this one.")
				end)
			end
		end
	end
	local h = math.floor((data.resetsIn or 0) / 3600)
	local m = math.floor((data.resetsIn or 0) % 3600 / 60)
	text(body, { text = string.format("New quests in %dh %02dm", h, m), size = 14, color = C.muted, sz = UDim2.new(1, 0, 0, 30), pos = UDim2.new(0, 0, 1, -30), z = 12 })
end

local function comingSoon(name, line)
	openPanel(name)
	local loading = body:FindFirstChild("Loading")
	if loading then
		loading:Destroy()
	end
	text(body, { text = "Coming soon", font = HEAD, size = 30, sz = UDim2.new(1, 0, 0, 50), pos = UDim2.fromScale(0, 0.3), z = 12 })
	text(body, { text = line, size = 16, color = C.muted, sz = UDim2.new(1, -40, 0, 60), pos = UDim2.new(0, 20, 0.3, 56), z = 12 })
end

-- Walk-up stations in the plaza.
local STATION = {
	Shop = function()
		openShop()
	end,
	Club = function()
		openClub()
	end,
	Quests = function()
		openQuests()
	end,
	Scout = function()
		comingSoon("SCOUT OFFICE", "Send scouts out to find players. Each report shows 5 players with their OVR hidden.")
	end,
	Trade = function()
		comingSoon("TRADE BOARD", "Buy and sell players with other managers.")
	end,
	HallOfFame = function()
		comingSoon("HALL OF FAME", "Leaderboards for Elo, fans and collection value.")
	end,
}
game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt)
	local f = STATION[prompt:GetAttribute("Station") or ""]
	if f and gui.Enabled then
		f()
	end
end)

-- Menu ---------------------------------------------------------------------------------------
-- Drawn sticker buttons, one neon each, tilted a touch.
for i, m in ipairs({ { "SHOP", C.orange, openShop, "shop" }, { "PACKS", C.green, openPacks, "pack" }, { "CLUB", C.blue, openClub, "club" }, { "QUESTS", C.pink, openQuests, "quests" } }) do
	local holder = make("Frame", { Size = UDim2.fromOffset(170, 50), BackgroundTransparency = 1, LayoutOrder = i }, menu)
	local b = button(holder, m[1], m[2], UDim2.new(1, 0, 0, 50))
	b.Rotation = 0
	b.Label.TextSize = 24
	Theme.withIcon(b, m[4], 1.15)
	Theme.shine(b, 5 + i * 0.7)
	b.MouseButton1Click:Connect(m[3])
end

-- Quest board on the right: today's quests on a soft panel, each with a little progress bar.
local board = make("TextButton", {
	Text = "",
	AutoButtonColor = false,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -16, 0, 74),
	Size = UDim2.fromOffset(250, 170),
	BackgroundColor3 = T.asphalt,
	Rotation = 0,
}, gui)
round(board, 18)
if not Theme.panelArt(board, 1) then
	stroke(board, 3, C.black)
end
Theme.icon(board, "quests", UDim2.fromOffset(30, 30), UDim2.fromOffset(12, 8), 3)
local boardTitle = text(board, { text = "DAILY QUESTS", font = HEAD, size = 21, color = T.yellow, sz = UDim2.new(1, -60, 0, 30), pos = UDim2.fromOffset(48, 8), align = Enum.TextXAlignment.Left, z = 3 })
make("UIStroke", { Thickness = 2, Color = C.black }, boardTitle)
local boardRows = make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -28, 1, -50), Position = UDim2.fromOffset(14, 42), ZIndex = 2 }, board)
make("UIListLayout", { Padding = UDim.new(0, 6) }, boardRows)
local boardScale = make("UIScale", {}, board)
board.MouseEnter:Connect(function()
	TweenService:Create(boardScale, TweenInfo.new(0.15), { Scale = 1.03 }):Play()
end)
board.MouseLeave:Connect(function()
	TweenService:Create(boardScale, TweenInfo.new(0.2), { Scale = 1 }):Play()
end)
board.MouseButton1Click:Connect(function()
	Audio.play("UIClick")
	openQuests()
end)
local boardFx = nil
function refreshBoard()
	local ok, data = call("getQuests")
	if not ok then
		return
	end
	for _, c in ipairs(boardRows:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local claimable = false
	for i, q in ipairs(data.list) do
		if i > 3 then
			break
		end
		local done = q.progress >= q.target
		claimable = claimable or (done and not q.claimed)
		local row = make("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, ZIndex = 2 }, boardRows)
		local name = text(row, { text = q.text, font = BODY, size = 13, color = q.claimed and C.muted or C.ink, sz = UDim2.new(1, -60, 0, 16), align = Enum.TextXAlignment.Left, z = 3, scaled = true })
		if q.claimed then
			-- Crossed out once claimed.
			make("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(0.8, 0, 0, 2), BackgroundColor3 = C.muted, BorderSizePixel = 0, ZIndex = 4 }, name)
		end
		local track = make("Frame", { Size = UDim2.new(1, -60, 0, 10), Position = UDim2.fromOffset(0, 20), BackgroundColor3 = C.stage, ZIndex = 3 }, row)
		round(track, 5)
		stroke(track, 1.5, C.black)
		local fill = make("Frame", { Size = UDim2.new(math.clamp(q.progress / math.max(1, q.target), 0, 1), 0, 1, 0), BackgroundColor3 = done and C.green or C.gold, ZIndex = 4 }, track)
		round(fill, 5)
		local tag = text(row, { text = q.claimed and "done" or (done and "CLAIM!" or string.format("%d/%d", q.progress, q.target)), font = HEAD, size = 16, color = done and not q.claimed and C.green or C.muted, sz = UDim2.new(0, 56, 0, 20), pos = UDim2.new(1, -56, 0, 15), align = Enum.TextXAlignment.Right, z = 3 })
		make("UIStroke", { Thickness = 1.5, Color = C.black }, tag)
	end
	-- Something to claim: the board lights up.
	if claimable and not boardFx then
		boardFx = make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5 }, board)
		Theme.sparkles(boardFx, C.gold, 0.45, 5, 18)
	elseif not claimable and boardFx then
		boardFx:Destroy()
		boardFx = nil
	end
end

-- PLAY: big court-yellow sticker slab in the bottom right, where the thumb is.
local playHolder = make("Frame", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -20), Size = UDim2.fromOffset(230, 92), BackgroundTransparency = 1 }, gui)
local playB = button(playHolder, "PLAY", C.gold, UDim2.fromScale(1, 1))
playB.Rotation = 0 -- level, so the shine stays clipped inside it
playB.Label.TextSize = 44
Theme.withIcon(playB, "ball", 0.82, 92)
Theme.glow(playB, C.gold, 44, 0.95)
Theme.shine(playB, 3)
Theme.sparkles(playB, Color3.new(1, 1, 1), 0.6, 4, 18)
local playing = false
playB.MouseButton1Click:Connect(function()
	if playing then
		return
	end
	playing = true
	playB.Label.Text = "FINDING GAME..."
	playB.Label.TextSize = 24
	local ok, data = call("playMatch")
	playB.Label.Text = "PLAY"
	playB.Label.TextSize = 44
	if ok then
		closePanel()
		local ran, err = pcall(MatchView.run, data, gui)
		if not ran then
			warn("[Lobby] match view failed: " .. tostring(err))
			game:GetService("RunService"):UnbindFromRenderStep("MatchCamera")
			workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
			for _, x in ipairs({ workspace:FindFirstChild("Match") or false, player.PlayerGui:FindFirstChild("MatchUI") or false }) do
				if x then
					x:Destroy()
				end
			end
			gui.Enabled = true
			say(data.rewards.won and "You won! Rewards added." or "Game over. Rewards added.")
		end
		loadProfile()
		refreshBoard()
	else
		say(data)
	end
	playing = false
end)

-- Keep the bar fresh: load once the server has the profile, then every 20 s.
task.spawn(function()
	for _ = 1, 30 do
		if loadProfile() then
			break
		end
		task.wait(1)
	end
	refreshBoard()
	while gui.Parent do
		task.wait(20)
		if not shade.Visible then
			loadProfile()
			refreshBoard()
		end
	end
end)
