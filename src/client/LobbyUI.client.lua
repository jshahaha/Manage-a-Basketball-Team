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

-- Top bar: coins, gems and Elo written on strips of tape.
local bar = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 10),
	Size = UDim2.fromOffset(480, 44),
	BackgroundTransparency = 1,
}, gui)
make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 10),
}, bar)
local function pill(tag, color, rot, order)
	local holder = make("Frame", { Size = UDim2.fromOffset(150, 44), BackgroundTransparency = 1, LayoutOrder = order }, bar)
	local f = Theme.tape(holder, "", { sz = UDim2.fromScale(1, 1), rot = rot })
	f:FindFirstChildOfClass("TextLabel"):Destroy()
	-- Neon stencil tag on the left, the number in marker on the right.
	local chip = make("Frame", { Size = UDim2.new(0, 42, 1, -10), Position = UDim2.fromOffset(6, 5), BackgroundColor3 = color, ZIndex = 3 }, f)
	round(chip, 3)
	text(chip, { text = tag, font = HEAD, size = 15, color = C.black, z = 4 })
	return text(f, { text = "…", font = MARK, size = 20, color = C.black, sz = UDim2.new(1, -58, 1, 0), pos = UDim2.fromOffset(52, 0), align = Enum.TextXAlignment.Left, z = 3, scaled = true })
end
local coinsText = pill("COINS", C.gold, -2, 1)
local gemsText = pill("GEMS", C.pink, 1.5, 2)
local eloText = pill("ELO", C.blue, -1, 3)

local profile = {}
local function refreshBar()
	coinsText.Text = comma(profile.coins)
	gemsText.Text = comma(profile.gems)
	eloText.Text = profile.elo and (comma(profile.elo) .. " " .. (profile.tier or "")) or "…"
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
local shade = make("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.deep, BackgroundTransparency = 0.35, Visible = false, ZIndex = 10 }, gui)
local panel = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.53),
	Size = UDim2.fromScale(0.92, 0.82),
	BackgroundColor3 = C.bg,
	ZIndex = 11,
}, shade)
make("UISizeConstraint", { MaxSize = Vector2.new(720, 480) }, panel)
round(panel, 8)
stroke(panel, 4, T.black)
Theme.asphalt(panel)
local strip = make("Frame", { Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = T.sunsetTop, ZIndex = 11, BorderSizePixel = 0 }, panel)
round(strip, 8)
Theme.sunset(strip)
-- Chain-link: thin diagonal lines over the sunset.
for i = 0, 30 do
	for _, rot in ipairs({ 45, -45 }) do
		make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, i * 26, 0.5, 0), Size = UDim2.fromOffset(2, 84), Rotation = rot, BackgroundColor3 = T.black, BackgroundTransparency = 0.82, BorderSizePixel = 0, ZIndex = 11 }, strip)
	end
end
strip.ClipsDescendants = true
local titleTape, title = Theme.tape(panel, "", { pos = UDim2.fromOffset(16, 10), sz = UDim2.fromOffset(260, 40), rot = -2, z = 12, size = 24 })
local close = button(panel, "X", C.red, UDim2.fromOffset(42, 42), UDim2.new(1, -54, 0, 8))
close.ZIndex = 12
close.FontFace = HEAD
close.TextSize = 24
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

local function bundlePopup(pack)
	local pop = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(330, 250), BackgroundColor3 = C.panel, ZIndex = 20 }, body)
	round(pop, 14)
	stroke(pop, 3)
	text(pop, { text = "Buy " .. pack.name, font = HEAD, size = 22, sz = UDim2.new(1, -20, 0, 36), pos = UDim2.fromOffset(10, 8), z = 21 })
	for i, pr in ipairs(pack.prices) do
		local label = string.format("%dx   %s coins", pr.size, comma(pr.coins))
		if pr.discount > 0 then
			label ..= string.format("   -%d%%", math.floor(pr.discount * 100 + 0.5))
		end
		local b = button(pop, label, i == 1 and C.blue or C.green, UDim2.new(1, -30, 0, 42), UDim2.fromOffset(15, 6 + i * 48))
		b.ZIndex = 21
		b.TextSize = 18
		b.MouseButton1Click:Connect(function()
			local ok, res = call("buyPack", { pack = pack.id, size = pr.size })
			if ok then
				profile.coins = res.coins
				refreshBar()
				Audio.play("CoinsSpend")
				say(pr.size > 1 and string.format("%dx %s added to Packs", pr.size, pack.name) or pack.name .. " added to Packs")
				pop:Destroy()
			else
				say(res)
			end
		end)
	end
	local cancel = button(pop, "Cancel", C.muted, UDim2.new(1, -30, 0, 34), UDim2.new(0, 15, 1, -44))
	cancel.ZIndex = 21
	cancel.MouseButton1Click:Connect(function()
		pop:Destroy()
	end)
end

local KIND_TEXT = { players = "Players, badges, item", badges = "Badges only", coach = "One coach" }

function openShop()
	openPanel("SHOP")
	local ok, data = call("getShop")
	local loading = body:FindFirstChild("Loading")
	if loading then
		loading:Destroy()
	end
	if not ok then
		text(body, { text = tostring(data), font = HEAD, size = 20, color = C.muted, z = 12 })
		return
	end
	local s = scroller(body)
	make("UIGridLayout", { CellSize = UDim2.fromOffset(160, 196), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }, s)
	for i, pack in ipairs(data.packs) do
		local card = make("Frame", { BackgroundColor3 = C.panel, LayoutOrder = i, ZIndex = 12 }, s)
		round(card, 12)
		stroke(card, 2)
		-- Pack art: a coloured box in the colour of the best rarity it can drop.
		local best
		for id in pairs(pack.odds or {}) do
			if not best or Config.RarityById[id].order > Config.RarityById[best].order then
				best = id
			end
		end
		local art = make("Frame", { Size = UDim2.new(1, -16, 0, 74), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = best and rarityColor(best) or C.pink, ZIndex = 13 }, card)
		round(art, 10)
		make("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0, 0.35) }, art)
		text(art, { text = pack.name:gsub(" Pack", ""):upper(), font = HEAD, size = 20, color = C.white, z = 14, scaled = true })
		text(card, { text = pack.name, font = HEAD, size = 17, sz = UDim2.new(1, -12, 0, 22), pos = UDim2.fromOffset(6, 86), z = 13, scaled = true })
		text(card, { text = KIND_TEXT[pack.kind] or "", size = 12, color = C.muted, sz = UDim2.new(1, -12, 0, 16), pos = UDim2.fromOffset(6, 108), z = 13 })
		text(card, { text = comma(pack.prices[1].coins) .. " coins", font = HEAD, size = 18, color = C.gold, sz = UDim2.new(1, -12, 0, 22), pos = UDim2.fromOffset(6, 126), z = 13 })
		local buy = button(card, "BUY", C.orange, UDim2.new(1, -16, 0, 34), UDim2.new(0, 8, 1, -42))
		buy.ZIndex = 13
		buy.MouseButton1Click:Connect(function()
			bundlePopup(pack)
		end)
	end
end

-- Card reveal -------------------------------------------------------------------------------
local function drawCard(parent, c, z)
	local f = make("Frame", { Size = UDim2.fromOffset(150, 210), BackgroundColor3 = C.panel, ZIndex = z }, parent)
	round(f, 12)
	stroke(f, 4, rarityColor(c.rarity))
	local band = make("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = rarityColor(c.rarity), ZIndex = z + 1 }, f)
	round(band, 10)
	text(band, { text = rarityName(c.rarity):upper(), font = HEAD, size = 15, color = C.white, z = z + 2 })
	if c.kind == "coach" then
		text(f, { text = (c.side or "") .. " COACH", font = HEAD, size = 16, color = C.muted, sz = UDim2.new(1, 0, 0, 24), pos = UDim2.fromOffset(0, 40), z = z + 1 })
		text(f, { text = c.name, font = HEAD, size = 20, sz = UDim2.new(1, -12, 0, 52), pos = UDim2.fromOffset(6, 74), z = z + 1, scaled = true })
		local styles = {}
		for _, st in ipairs(c.styles or {}) do
			table.insert(styles, type(st) == "table" and (st.name or st.id) or tostring(st))
		end
		text(f, { text = table.concat(styles, ", "), size = 12, color = C.muted, sz = UDim2.new(1, -12, 0, 60), pos = UDim2.fromOffset(6, 132), z = z + 1 })
		return f
	end
	text(f, { text = tostring(c.ovr), font = HEAD, size = 44, sz = UDim2.fromOffset(70, 50), pos = UDim2.fromOffset(6, 34), z = z + 1, align = Enum.TextXAlignment.Left })
	text(f, { text = c.pos or "", font = HEAD, size = 22, color = C.blue, sz = UDim2.fromOffset(60, 30), pos = UDim2.new(1, -66, 0, 42), z = z + 1, align = Enum.TextXAlignment.Right })
	text(f, { text = c.name, font = HEAD, size = 19, sz = UDim2.new(1, -12, 0, 48), pos = UDim2.fromOffset(6, 90), z = z + 1, scaled = true })
	text(f, { text = c.archetype and Ratings.archetypeName(c.archetype) or "", size = 13, color = C.muted, sz = UDim2.new(1, -12, 0, 18), pos = UDim2.fromOffset(6, 140), z = z + 1 })
	local ft = c.height and string.format("%d'%d\"", math.floor(c.height / 12), c.height % 12) or ""
	text(f, { text = ft .. (c.nation and ("  ·  " .. c.nation) or ""), size = 12, color = C.muted, sz = UDim2.new(1, -12, 0, 18), pos = UDim2.fromOffset(6, 162), z = z + 1 })
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
	local stage = make("Frame", { Size = UDim2.new(1, 0, 1, -50), BackgroundColor3 = C.stage, ZIndex = 12 }, body)
	round(stage, 12)
	local count = text(body, { font = HEAD, size = 18, color = C.muted, sz = UDim2.new(0.5, 0, 0, 40), pos = UDim2.new(0, 4, 1, -42), align = Enum.TextXAlignment.Left, z = 12 })
	local nextB = button(body, "NEXT", C.orange, UDim2.fromOffset(140, 40), UDim2.new(1, -140, 1, -42))
	nextB.ZIndex = 12
	local i = 0
	local function step()
		for _, c in ipairs(stage:GetChildren()) do
			if not c:IsA("UICorner") then
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
			if order >= 3 then
				local glow = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(230, 290), BackgroundColor3 = rarityColor(c.rarity), BackgroundTransparency = 0.55, ZIndex = 12 }, stage)
				round(glow, 30)
				TweenService:Create(glow, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = 0.85 }):Play()
			end
			Audio.play("CardFlip")
			Audio.play("Reveal" .. (c.rarity or "Common"))
			TweenService:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(150, 210), Position = UDim2.new() }):Play()
			TweenService:Create(sc, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			nextB.Text = (i == #cards and #extras == 0) and "DONE" or "NEXT"
		elseif i == #cards + 1 and #extras > 0 then
			count.Text = "Also in the pack"
			local list = make("Frame", { Size = UDim2.new(1, -24, 1, -24), Position = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, ZIndex = 13 }, stage)
			make("UIListLayout", { Padding = UDim.new(0, 6) }, list)
			for _, line in ipairs(extras) do
				local row = make("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.panel, ZIndex = 13 }, list)
				round(row, 8)
				text(row, { text = line, size = 16, sz = UDim2.new(1, -16, 1, 0), pos = UDim2.fromOffset(10, 0), align = Enum.TextXAlignment.Left, z = 14 })
			end
			nextB.Text = "DONE"
		else
			openPacks()
		end
	end
	nextB.MouseButton1Click:Connect(step)
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
	local s = scroller(body)
	make("UIListLayout", { Padding = UDim.new(0, 8) }, s)
	for _, it in ipairs(data.items) do
		local row = make("Frame", { Size = UDim2.new(1, -10, 0, 56), BackgroundColor3 = C.panel, ZIndex = 12 }, s)
		round(row, 10)
		stroke(row, 2, C.rule)
		local name = it.size > 1 and string.format("%dx %s Bundle", it.size, it.name:gsub(" Pack", "")) or it.name
		text(row, { text = name, font = HEAD, size = 20, sz = UDim2.new(1, -170, 1, 0), pos = UDim2.fromOffset(14, 0), align = Enum.TextXAlignment.Left, z = 13 })
		text(row, { text = "x" .. it.count, font = HEAD, size = 20, color = C.muted, sz = UDim2.fromOffset(40, 56), pos = UDim2.new(1, -160, 0, 0), z = 13 })
		local b = button(row, "OPEN", C.green, UDim2.fromOffset(100, 40), UDim2.new(1, -110, 0, 8))
		b.ZIndex = 13
		b.MouseButton1Click:Connect(function()
			b.Active = false
			local ok2, res = call("openPack", it.key)
			if ok2 then
				profile.coins = res.coins
				refreshBar()
				reveal(res)
			else
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
	make("UIListLayout", { Padding = UDim.new(0, 8) }, list)
	for i, q in ipairs(data.list) do
		local row = make("Frame", { Size = UDim2.new(1, 0, 0, 62), BackgroundColor3 = C.panel, ZIndex = 12 }, list)
		round(row, 10)
		stroke(row, 2, C.rule)
		text(row, { text = q.text, font = HEAD, size = 18, sz = UDim2.new(1, -170, 0, 32), pos = UDim2.fromOffset(14, 4), align = Enum.TextXAlignment.Left, z = 13 })
		text(row, { text = string.format("%d / %d   ·   %s coins", q.progress, q.target, comma(q.coins)), size = 14, color = C.muted, sz = UDim2.new(1, -170, 0, 20), pos = UDim2.fromOffset(14, 36), align = Enum.TextXAlignment.Left, z = 13 })
		local done = q.progress >= q.target
		local b = button(row, q.claimed and "CLAIMED" or (done and "CLAIM" or "IN PROGRESS"), q.claimed and C.muted or (done and C.green or C.stage), UDim2.fromOffset(140, 42), UDim2.new(1, -150, 0, 10))
		b.ZIndex = 13
		b.TextSize = 16
		if not done or q.claimed then
			b.TextColor3 = q.claimed and C.white or C.muted
			b.AutoButtonColor = false
		else
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
-- Stencil slabs: dark fill, neon outline and neon lettering, each tilted a touch.
for i, m in ipairs({ { "SHOP", C.orange, openShop }, { "PACKS", C.green, openPacks }, { "CLUB", C.blue, openClub }, { "QUESTS", C.pink, openQuests } }) do
	local holder = make("Frame", { Size = UDim2.fromOffset(140, 48), BackgroundTransparency = 1, LayoutOrder = i }, menu)
	local b = make("TextButton", {
		Text = m[1],
		FontFace = HEAD,
		TextSize = 24,
		TextColor3 = m[2],
		BackgroundColor3 = T.slate,
		BackgroundTransparency = 0.1,
		Size = UDim2.fromScale(1, 1),
		Rotation = i % 2 == 0 and 1.5 or -1.5,
		AutoButtonColor = true,
		ZIndex = 2,
	}, holder)
	round(b, 4)
	stroke(b, 3, m[2])
	b.MouseButton1Click:Connect(function()
		Audio.play("UIClick")
		m[3]()
	end)
end

-- Quest board on the right: today's runs, written up like a court-side chalkboard.
local board = make("TextButton", {
	Text = "",
	AutoButtonColor = false,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -16, 0, 74),
	Size = UDim2.fromOffset(240, 150),
	BackgroundColor3 = T.slate,
	BackgroundTransparency = 0.08,
	Rotation = 1,
}, gui)
round(board, 4)
stroke(board, 3, T.tape)
text(board, { text = "today's runs", font = MARK, size = 22, color = T.yellow, sz = UDim2.new(1, -20, 0, 32), pos = UDim2.fromOffset(12, 6), align = Enum.TextXAlignment.Left, z = 2 })
local boardRows = make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -24, 1, -46), Position = UDim2.fromOffset(12, 40), ZIndex = 2 }, board)
make("UIListLayout", { Padding = UDim.new(0, 4) }, boardRows)
board.MouseButton1Click:Connect(function()
	Audio.play("UIClick")
	openQuests()
end)
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
	for i, q in ipairs(data.list) do
		if i > 3 then
			break
		end
		local done = q.progress >= q.target
		local row = make("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, ZIndex = 2 }, boardRows)
		local name = text(row, { text = q.text, font = BODY, size = 14, color = (done or q.claimed) and C.muted or C.ink, sz = UDim2.new(1, -56, 1, 0), align = Enum.TextXAlignment.Left, z = 3, scaled = true })
		if q.claimed then
			-- Crossed out once claimed.
			make("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(0.8, 0, 0, 2), BackgroundColor3 = C.muted, BorderSizePixel = 0, ZIndex = 4 }, name)
		end
		text(row, { text = q.claimed and "done" or (done and "CLAIM!" or string.format("%d/%d", q.progress, q.target)), font = done and not q.claimed and HEAD or MARK, size = 16, color = done and not q.claimed and C.green or C.muted, sz = UDim2.new(0, 54, 1, 0), pos = UDim2.new(1, -54, 0, 0), align = Enum.TextXAlignment.Right, z = 3 })
	end
end

-- PLAY: big court-yellow slab in the bottom right, where the thumb is.
local playHolder = make("Frame", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -24), Size = UDim2.fromOffset(220, 74), BackgroundTransparency = 1 }, gui)
local playShadow = make("Frame", { Position = UDim2.fromOffset(7, 7), Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.orange, Rotation = -3 }, playHolder)
round(playShadow, 6)
local playB = make("TextButton", {
	Text = "PLAY",
	FontFace = HEAD,
	TextSize = 44,
	TextColor3 = C.black,
	BackgroundColor3 = C.gold,
	Size = UDim2.fromScale(1, 1),
	Rotation = -3,
	AutoButtonColor = true,
	ZIndex = 2,
}, playHolder)
round(playB, 6)
stroke(playB, 4, C.black)
playB.MouseButton1Click:Connect(function()
	Audio.play("UIClick")
end)
local playing = false
playB.MouseButton1Click:Connect(function()
	if playing then
		return
	end
	playing = true
	playB.Text = "FINDING GAME..."
	playB.TextSize = 24
	local ok, data = call("playMatch")
	playB.Text = "PLAY"
	playB.TextSize = 44
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
