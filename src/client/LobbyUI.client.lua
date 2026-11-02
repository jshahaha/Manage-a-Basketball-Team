--!nonstrict
-- Lobby HUD: coins, gems and Elo along the top, and the Shop, Packs and Club screens.
--   Shop  : every pack with Buy; Buy opens the 1x / 5x / 20x popup.
--   Packs : the packs and bundles you own; Open plays the card reveal.
--   Club  : your roster. Tap two players to swap them, then Save the matchday ten.
-- Colours follow the UI mockups (light theme).

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

local C = {
	bg = Color3.fromHex("f3f6fb"),
	panel = Color3.new(1, 1, 1),
	ink = Color3.fromHex("1b2140"),
	muted = Color3.fromHex("5b6380"),
	blue = Color3.fromHex("2e6fd8"),
	orange = Color3.fromHex("e8650c"),
	gold = Color3.fromHex("b98a00"),
	green = Color3.fromHex("1f9e3f"),
	rule = Color3.fromHex("d9dfeb"),
	stage = Color3.fromHex("dfe6f1"),
	pink = Color3.fromHex("e8456b"),
	white = Color3.new(1, 1, 1),
}
local HEAD = Enum.Font.FredokaOne
local BODY = Enum.Font.GothamBold

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

-- Small UI helpers --------------------------------------------------------------------------
local function make(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do
		o[k] = v
	end
	o.Parent = parent
	return o
end
local function round(o, r)
	make("UICorner", { CornerRadius = UDim.new(0, r) }, o)
end
local function stroke(o, t, color)
	make("UIStroke", { Thickness = t, Color = color or C.ink, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
end
local function text(parent, props)
	local l = make("TextLabel", {
		BackgroundTransparency = 1,
		Font = props.font or BODY,
		TextSize = props.size or 16,
		TextColor3 = props.color or C.ink,
		Text = props.text or "",
		TextWrapped = true,
		TextScaled = props.scaled or false,
		TextXAlignment = props.align or Enum.TextXAlignment.Center,
		Size = props.sz or UDim2.fromScale(1, 1),
		Position = props.pos or UDim2.new(),
		AnchorPoint = props.anchor or Vector2.zero,
		ZIndex = props.z or 1,
	}, parent)
	if props.scaled then
		make("UITextSizeConstraint", { MaxTextSize = props.size or 16 }, l)
	end
	return l
end
local function button(parent, label, color, sz, pos)
	local b = make("TextButton", {
		Text = label,
		Font = HEAD,
		TextSize = 20,
		TextColor3 = C.white,
		BackgroundColor3 = color,
		Size = sz,
		Position = pos or UDim2.new(),
		AutoButtonColor = true,
	}, parent)
	round(b, 12)
	stroke(b, 2)
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

-- Toast for errors and confirmations.
local toast = make("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -90),
	Size = UDim2.fromOffset(320, 42),
	BackgroundColor3 = C.ink,
	TextColor3 = C.white,
	Font = BODY,
	TextSize = 16,
	Visible = false,
	ZIndex = 50,
}, gui)
round(toast, 10)
local toastId = 0
local function say(msg)
	toastId += 1
	local id = toastId
	toast.Text = msg
	toast.Visible = true
	task.delay(2.2, function()
		if toastId == id then
			toast.Visible = false
		end
	end)
end

-- Top bar: coins, gems, Elo.
local bar = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.fromOffset(420, 44),
	BackgroundTransparency = 1,
}, gui)
make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Padding = UDim.new(0, 8),
}, bar)
local function pill(icon, color)
	local f = make("Frame", { Size = UDim2.fromOffset(132, 40), BackgroundColor3 = C.panel }, bar)
	round(f, 20)
	stroke(f, 2)
	local dot = make("TextLabel", {
		Size = UDim2.fromOffset(30, 30),
		Position = UDim2.fromOffset(5, 5),
		BackgroundColor3 = color,
		Text = icon,
		Font = HEAD,
		TextSize = 16,
		TextColor3 = C.white,
	}, f)
	round(dot, 15)
	return text(f, { text = "…", font = HEAD, size = 20, sz = UDim2.new(1, -44, 1, 0), pos = UDim2.fromOffset(40, 0), align = Enum.TextXAlignment.Left })
end
local coinsText = pill("C", C.gold)
local gemsText = pill("G", C.pink)
local eloText = pill("E", C.blue)

local profile = {}
local function refreshBar()
	coinsText.Text = comma(profile.coins)
	gemsText.Text = comma(profile.gems)
	eloText.Text = profile.elo and (comma(profile.elo) .. "  " .. (profile.tier or "")) or "…"
end
local function loadProfile()
	local ok, data = call("getProfile")
	if ok then
		profile = data
		refreshBar()
	end
	return ok
end

-- Menu buttons down the right side.
local menu = make("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -12, 0.5, 0),
	Size = UDim2.fromOffset(120, 4 * 54),
	BackgroundTransparency = 1,
}, gui)
make("UIListLayout", { Padding = UDim.new(0, 8) }, menu)

-- Modal panel shared by every screen.
local shade = make("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Visible = false, ZIndex = 10 }, gui)
local panel = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.53),
	Size = UDim2.fromScale(0.92, 0.82),
	BackgroundColor3 = C.bg,
	ZIndex = 11,
}, shade)
make("UISizeConstraint", { MaxSize = Vector2.new(720, 480) }, panel)
round(panel, 16)
stroke(panel, 3)
local title = text(panel, { font = HEAD, size = 26, sz = UDim2.new(1, -120, 0, 44), pos = UDim2.fromOffset(18, 6), align = Enum.TextXAlignment.Left, z = 12 })
local close = button(panel, "X", C.pink, UDim2.fromOffset(40, 40), UDim2.new(1, -50, 0, 8))
close.ZIndex = 12
local body = make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -24, 1, -64), Position = UDim2.fromOffset(12, 54), ZIndex = 12 }, panel)
local panelScale = make("UIScale", {}, panel)

local function clearBody()
	for _, c in ipairs(body:GetChildren()) do
		c:Destroy()
	end
end
local function openPanel(name)
	title.Text = name
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
				BackgroundColor3 = picked == i and Color3.fromHex("fff1c4") or C.panel,
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
for _, m in ipairs({ { "SHOP", C.orange, openShop }, { "PACKS", C.green, openPacks }, { "CLUB", C.blue, openClub }, { "QUESTS", C.pink, openQuests } }) do
	local b = button(menu, m[1], m[2], UDim2.fromOffset(120, 46))
	b.TextSize = 22
	b.MouseButton1Click:Connect(m[3])
end

-- PLAY: the big button at the bottom. The server plays the game; the match screen acts it out.
local playB = button(gui, "PLAY", C.green, UDim2.fromOffset(200, 60), UDim2.new(0.5, -100, 1, -84))
playB.TextSize = 32
local playing = false
playB.MouseButton1Click:Connect(function()
	if playing then
		return
	end
	playing = true
	playB.Text = "FINDING GAME..."
	playB.TextSize = 20
	local ok, data = call("playMatch")
	playB.Text = "PLAY"
	playB.TextSize = 32
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
	while gui.Parent do
		task.wait(20)
		if not shade.Visible then
			loadProfile()
		end
	end
end)
