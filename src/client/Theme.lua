--!nonstrict
-- "Blacktop" UI theme (js picked it 2026-11-02): a street court at sunset.
-- Asphalt panels, cream gaffer-tape labels, stencil-style condensed headings, marker accents,
-- and one loud neon per button. Every screen builds its UI through these helpers so the look
-- stays the same everywhere.

local Theme = {}

Theme.C = {
	-- Softened 2026-11-02 (js: "more friendly to the eye"): lighter slate panels, charcoal
	-- instead of pure black, and slightly calmer accent colours.
	asphalt = Color3.fromHex("3a3f4b"), -- panel background
	slate = Color3.fromHex("2f3440"), -- rows and cards on a panel
	deep = Color3.fromHex("262a33"), -- shade behind popups
	line = Color3.fromHex("4f5666"), -- quiet borders
	ink = Color3.fromHex("f5f2ea"), -- main text on panels (warm white)
	muted = Color3.fromHex("b8bdc6"),
	black = Color3.fromHex("23262e"), -- outlines and text on bright fills (soft charcoal)
	tape = Color3.fromHex("f5f2ea"),
	yellow = Color3.fromHex("ffd45e"), -- court-line yellow: the main action colour
	orange = Color3.fromHex("ff8a5b"),
	sky = Color3.fromHex("62b8ff"),
	lime = Color3.fromHex("8fdc6e"),
	pink = Color3.fromHex("ff8fcf"),
	red = Color3.fromHex("ff6b6b"),
	sunsetTop = Color3.fromHex("ffa27a"),
	sunsetBottom = Color3.fromHex("ffcf8f"),
	white = Color3.new(1, 1, 1),
}
local C = Theme.C

-- Fonts: Oswald (condensed, stencil feel) for headings and buttons, Permanent Marker for the
-- handwritten tape labels, Gotham for small running text so it stays readable on phones.
Theme.HEAD = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold)
Theme.MARK = Font.fromEnum(Enum.Font.PermanentMarker)
Theme.BODY = Font.fromEnum(Enum.Font.GothamBold)
Theme.SMALL = Font.fromEnum(Enum.Font.GothamMedium)

function Theme.make(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do
		o[k] = v
	end
	o.Parent = parent
	return o
end
local make = Theme.make

function Theme.round(o, r)
	make("UICorner", { CornerRadius = UDim.new(0, r) }, o)
end
-- Outlines are drawn a third thinner than asked so the whole UI stays soft on the eye.
function Theme.stroke(o, t, color, transparency)
	return make("UIStroke", { Thickness = math.max(1, math.floor(t * 0.67 + 0.5)), Color = color or C.black, Transparency = transparency or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
end

-- Dark text on bright fills, cream text on dark ones.
function Theme.textOn(color)
	local l = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
	return l > 0.55 and C.black or C.ink
end

function Theme.text(parent, p)
	local l = make("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = p.font or Theme.BODY,
		TextSize = p.size or 16,
		TextColor3 = p.color or C.ink,
		Text = p.text or "",
		TextWrapped = true,
		TextScaled = p.scaled or false,
		TextXAlignment = p.align or Enum.TextXAlignment.Center,
		TextYAlignment = p.valign or Enum.TextYAlignment.Center,
		Size = p.sz or UDim2.fromScale(1, 1),
		Position = p.pos or UDim2.new(),
		AnchorPoint = p.anchor or Vector2.zero,
		Rotation = p.rot or 0,
		ZIndex = p.z or 1,
	}, parent)
	if p.scaled then
		make("UITextSizeConstraint", { MaxTextSize = p.size or 16 }, l)
	end
	return l
end

-- A hard offset shadow behind a frame, like a sticker lifted off the asphalt.
function Theme.shadow(o, dx, dy, color)
	local s = make("Frame", {
		Name = "Shadow",
		AnchorPoint = o.AnchorPoint,
		Position = o.Position + UDim2.fromOffset(dx or 5, dy or 5),
		Size = o.Size,
		Rotation = o.Rotation,
		BackgroundColor3 = color or C.black,
		ZIndex = math.max(o.ZIndex - 1, 0),
		LayoutOrder = o.LayoutOrder,
	}, o.Parent)
	local corner = o:FindFirstChildOfClass("UICorner")
	if corner then
		Theme.round(s, corner.CornerRadius.Offset)
	end
	return s
end

-- Drawn art (tools/ui/make_ui_art.py), uploaded to Roblox. Ids live in UIAssets; when one is
-- missing the helpers fall back to plain frames so nothing breaks.
local okAssets, IMG = pcall(require, script.Parent:WaitForChild("UIAssets", 2))
if not okAssets or type(IMG) ~= "table" then
	IMG = {}
end
Theme.IMG = IMG

local BUTTON_ART = {
	[C.yellow:ToHex()] = "yellow",
	[C.orange:ToHex()] = "orange",
	[C.lime:ToHex()] = "lime",
	[C.sky:ToHex()] = "sky",
	[C.pink:ToHex()] = "pink",
	[C.red:ToHex()] = "red",
	[C.slate:ToHex()] = "slate",
	[C.deep:ToHex()] = "slate",
	[C.muted:ToHex()] = "slate",
	[C.asphalt:ToHex()] = "slate",
}
local BUTTON_TEXT = { yellow = C.white, orange = C.white, lime = C.white, sky = C.white, pink = C.white, red = C.white, slate = C.ink, purple = C.white }
Theme.BUTTON_SLICE = Rect.new(28, 24, 132, 68) -- for the 160x96 button images

-- Buttons: a chunky sticker slab drawn as a 9-slice image (outline, lip, gloss), with the label
-- as a child TextLabel named "Label". Pressing swaps to the pressed art and nudges the label.
function Theme.button(parent, label, color, sz, pos, onClick)
	local art = BUTTON_ART[color:ToHex()] or "slate"
	local up, down = IMG["btn_" .. art], IMG["btn_" .. art .. "_down"]
	local b = make("ImageButton", {
		Size = sz,
		Position = pos or UDim2.new(),
		BackgroundTransparency = 1,
		Image = up or "",
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Theme.BUTTON_SLICE,
		SliceScale = 0.5,
		AutoButtonColor = false,
	}, parent)
	if not up then
		b.BackgroundTransparency = 0
		b.BackgroundColor3 = color
		Theme.round(b, 6)
		Theme.stroke(b, 3)
	end
	-- Smaller buttons get thinner borders so the slices fit.
	local function fit()
		local h = b.AbsoluteSize.Y
		if h > 0 then
			b.SliceScale = math.clamp(h / 110, 0.32, 0.9)
		end
	end
	b:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	task.defer(fit)
	local t = make("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0.82, -2),
		Position = UDim2.fromOffset(4, 1),
		Text = label,
		FontFace = Theme.HEAD,
		TextSize = 20,
		TextScaled = false,
		TextWrapped = true,
		TextColor3 = BUTTON_TEXT[art] or Theme.textOn(color),
		ZIndex = b.ZIndex,
	}, b)
	-- Charcoal outline around the label so white text pops on bright buttons.
	make("UIStroke", { Thickness = 2.5, Color = C.black, LineJoinMode = Enum.LineJoinMode.Round, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, t)
	b:GetPropertyChangedSignal("ZIndex"):Connect(function()
		t.ZIndex = b.ZIndex
	end)
	local pressed = false
	local function set(p)
		pressed = p
		if up then
			b.Image = p and (down or up) or up
		end
		t.Position = p and UDim2.fromOffset(4, 4) or UDim2.fromOffset(4, 1)
	end
	-- Bounce: grow a touch on hover, squash on press, spring back on release.
	local bounce = make("UIScale", { Name = "Bounce" }, b)
	local function scaleTo(v, t, style)
		game:GetService("TweenService"):Create(bounce, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = v }):Play()
	end
	b.MouseButton1Down:Connect(function()
		set(true)
		scaleTo(0.92, 0.08)
	end)
	b.MouseButton1Up:Connect(function()
		set(false)
		scaleTo(1, 0.35, Enum.EasingStyle.Back)
	end)
	b.MouseEnter:Connect(function()
		scaleTo(1.05, 0.15)
	end)
	b.MouseLeave:Connect(function()
		if pressed then
			set(false)
		end
		scaleTo(1, 0.2)
	end)
	if onClick then
		b.MouseButton1Click:Connect(onClick)
	end
	return b, t
end

-- A drawn icon (tools/ui/make_icons.py): coin, gem, trophy, shop, pack, club, quests, ball, codes.
function Theme.icon(parent, name, sz, pos, z)
	local id = IMG["icon_" .. name]
	if not id then
		return nil
	end
	return make("ImageLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		Image = id,
		Size = sz,
		Position = pos or UDim2.new(),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = z or 1,
	}, parent)
end

-- Put an icon on the left of a Theme.button. The label stays centred on the whole button
-- (js 2026-11-02: "make sure buttons are centred"), and only slides right as far as it must
-- to clear the icon.
function Theme.withIcon(b, name, scale, height)
	-- js (2026-11-02): icons must sit inside their frame, the same way on every button. So the
	-- icon is a fixed share of the button face (the face ends above the 3D lip), with equal
	-- padding left, top and bottom. `scale` is kept for old callers but no longer pokes out.
	local h = height or (b.Size.Y.Offset > 0 and b.Size.Y.Offset) or 50
	local face = math.floor(h * 0.84)
	local size = math.floor(face * 0.86)
	local pad = math.floor((face - size) / 2)
	local left = pad + 4
	local ic = Theme.icon(b, name, UDim2.fromOffset(size, size), UDim2.fromOffset(left, pad + 1), b.ZIndex + 1)
	if ic then
		local label = b.Label
		local iconRight = left + size
		local function fit()
			local w = b.AbsoluteSize.X
			if w <= 0 then
				return
			end
			local tw = label.TextBounds.X
			local shift = math.max(0, iconRight + 4 - (w - tw) / 2)
			label.Position = UDim2.fromOffset(4 + shift, label.Position.Y.Offset)
		end
		label:GetPropertyChangedSignal("TextBounds"):Connect(fit)
		b:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
		label:GetPropertyChangedSignal("Position"):Connect(function()
			-- The press nudge resets X; put the shift back.
			if label.Position.X.Offset == 4 then
				fit()
			end
		end)
		task.defer(fit)
		b:GetPropertyChangedSignal("ZIndex"):Connect(function()
			ic.ZIndex = b.ZIndex + 1
		end)
	end
	return ic
end

-- A centred row of text and icons, e.g. { {icon="coin"}, {text="1,000"} }, used for prices so
-- they show the coin sticker instead of the word "coins".
function Theme.row(parent, parts, p)
	p = p or {}
	local z = p.z or parent.ZIndex + 1
	local f = make("Frame", { Name = "Row", BackgroundTransparency = 1, Size = p.sz or UDim2.fromScale(1, 1), Position = p.pos or UDim2.new(), ZIndex = z }, parent)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, p.gap or 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, f)
	local size = p.size or 18
	for i, part in ipairs(parts) do
		if part.icon then
			local isz = part.iconSize or math.floor(size * 1.35)
			local ic = Theme.icon(f, part.icon, UDim2.fromOffset(isz, isz), nil, z)
			if ic then
				ic.LayoutOrder = i
			end
		else
			local t = make("TextLabel", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.new(0, 0, 1, 0),
				Text = part.text,
				FontFace = p.font or Theme.HEAD,
				TextSize = part.size or size,
				TextColor3 = part.color or p.color or C.white,
				LayoutOrder = i,
				ZIndex = z,
			}, f)
			if p.outline ~= false then
				make("UIStroke", { Thickness = p.outline or 2, Color = C.black, LineJoinMode = Enum.LineJoinMode.Round }, t)
			end
		end
	end
	return f
end

-- The panel image behind a frame (9-slice). Returns true when the art is used. The HD panel
-- (512px, 72px margins) is preferred; it keeps corners smooth on big phone screens.
function Theme.panelArt(frame, z)
	local hd = IMG.panel_hd
	if not hd and not IMG.panel then
		return false
	end
	frame.BackgroundTransparency = 1
	make("ImageLabel", {
		Name = "PanelArt",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Image = hd or IMG.panel,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = hd and Rect.new(72, 72, 440, 440) or Rect.new(36, 36, 220, 220),
		SliceScale = hd and 0.3 or 0.6,
		ZIndex = z or frame.ZIndex,
	}, frame)
	return true
end

-- The darker inner "stage" (pack opening, lists) with a soft vignette, when the art exists.
function Theme.stageArt(frame, z)
	if not IMG.stage_hd then
		return false
	end
	frame.BackgroundTransparency = 1
	make("ImageLabel", {
		Name = "StageArt",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Image = IMG.stage_hd,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(72, 72, 440, 440),
		SliceScale = 0.3,
		ZIndex = z or frame.ZIndex,
	}, frame)
	return true
end

-- Tiled chain-link over a frame.
function Theme.chainlink(frame, z)
	if not IMG.chainlink then
		return false
	end
	make("ImageLabel", {
		Name = "Chainlink",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Image = IMG.chainlink,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(36, 36),
		ImageTransparency = 0.6, -- a faint hint of fence, not a busy pattern
		ZIndex = z or frame.ZIndex,
	}, frame)
	return true
end

-- A strip of cream gaffer tape with marker writing, tilted a little.
function Theme.tape(parent, label, p)
	p = p or {}
	local f = make("Frame", {
		Size = p.sz or UDim2.fromOffset(150, 38),
		Position = p.pos or UDim2.new(),
		AnchorPoint = p.anchor or Vector2.zero,
		Rotation = p.rot or -2,
		BackgroundColor3 = p.color or C.tape,
		ZIndex = p.z or 1,
	}, parent)
	local art = (p.color == C.yellow) and IMG.tape_yellow or IMG.tape_cream
	if art and (p.color == nil or p.color == C.tape or p.color == C.yellow) then
		-- Drawn tape: fibres, sheen and torn ends.
		f.BackgroundTransparency = 1
		make("ImageLabel", { Name = "TapeArt", BackgroundTransparency = 1, Size = UDim2.new(1, 10, 1, 6), Position = UDim2.fromOffset(-5, -3), Image = art, ZIndex = p.z or 1 }, f)
	else
		Theme.round(f, 2)
		-- Torn ends: two thin darker strips.
		for _, x in ipairs({ 0, 1 }) do
			make("Frame", { AnchorPoint = Vector2.new(x, 0), Position = UDim2.fromScale(x, 0), Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = C.black, BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = (p.z or 1) + 1 }, f)
		end
	end
	local t = Theme.text(f, { text = label, font = p.font or Theme.MARK, size = p.size or 20, color = C.black, z = (p.z or 1) + 1, sz = UDim2.new(1, -12, 1, 0), pos = UDim2.fromOffset(6, 0), scaled = true })
	return f, t
end

-- Asphalt panel with a fine speckle and a sunset strip along the top.
function Theme.asphalt(o)
	make("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 205, 210)), -- multiplies the fill: lighter top, darker bottom
	}, o)
end

function Theme.sunset(o)
	make("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(C.sunsetTop, C.sunsetBottom),
	}, o)
end

-- Effects ------------------------------------------------------------------------------------
-- js (2026-11-02): the UI felt flat because nothing moved or glowed. These layer light on top of
-- the art, like the big Roblox games do. Sprites come from tools/ui/make_fx.py and are white, so
-- ImageColor3 tints them. Every looping effect stops by itself once its frame is destroyed.
local TweenService = game:GetService("TweenService")

-- Fetch the effect sprites up front so the first pack opening already has its rays.
task.spawn(function()
	local list = {}
	for _, k in ipairs({ "fx_glow", "fx_sparkle", "fx_wisp", "fx_shine", "fx_rays" }) do
		if IMG[k] then
			table.insert(list, IMG[k])
		end
	end
	pcall(function()
		game:GetService("ContentProvider"):PreloadAsync(list)
	end)
end)

local function alive(o)
	return o and o.Parent ~= nil and o:IsDescendantOf(game)
end

-- Soft glow behind a frame or button (placed as a sibling just below it), breathing slowly.
function Theme.glow(target, color, pad, strength)
	if not IMG.fx_glow or not target.Parent then
		return nil
	end
	pad = pad or 30
	local a = target.AnchorPoint
	local g = make("ImageLabel", {
		Name = "Glow",
		BackgroundTransparency = 1,
		Image = IMG.fx_glow,
		ImageColor3 = color or C.yellow,
		ImageTransparency = 1 - (strength or 0.7),
		AnchorPoint = a,
		Size = target.Size + UDim2.fromOffset(pad * 2, pad * 2),
		Position = target.Position + UDim2.fromOffset(pad * (2 * a.X - 1), pad * (2 * a.Y - 1)),
		ZIndex = math.max(0, target.ZIndex - 1),
		LayoutOrder = target.LayoutOrder,
	}, target.Parent)
	TweenService:Create(g, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { ImageTransparency = math.min(1, 1 - (strength or 0.7) + 0.3) }):Play()
	target:GetPropertyChangedSignal("Visible"):Connect(function()
		g.Visible = target.Visible
	end)
	target.Destroying:Connect(function()
		g:Destroy()
	end)
	return g
end

-- A streak of light that sweeps across a frame every few seconds.
function Theme.shine(target, every, z, strength)
	if not IMG.fx_shine then
		return nil
	end
	local clip = make("Frame", { Name = "Shine", BackgroundTransparency = 1, Size = UDim2.new(1, -6, 1, -8), Position = UDim2.fromOffset(3, 2), ClipsDescendants = true, ZIndex = z or target.ZIndex + 1 }, target)
	Theme.round(clip, 14)
	local s = make("ImageLabel", { BackgroundTransparency = 1, Image = IMG.fx_shine, ImageTransparency = 1 - (strength or 0.55), Size = UDim2.new(0, 0, 1, 0), Position = UDim2.fromScale(-0.6, 0), ZIndex = clip.ZIndex }, clip)
	make("UIAspectRatioConstraint", { AspectRatio = 2, DominantAxis = Enum.DominantAxis.Height }, s)
	task.spawn(function()
		task.wait(math.random() * (every or 4))
		while alive(clip) do
			s.Position = UDim2.new(-0.6, 0, 0, 0)
			TweenService:Create(s, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { Position = UDim2.new(1.1, 0, 0, 0) }):Play()
			task.wait((every or 4) + math.random())
		end
	end)
	return clip
end

-- Twinkling sparkles popping up at random spots over a frame.
function Theme.sparkles(parent, color, rate, z, maxSize)
	if not IMG.fx_sparkle then
		return
	end
	task.spawn(function()
		while alive(parent) do
			if parent.Visible ~= false then
				local sz = math.random(10, maxSize or 26)
				local s = make("ImageLabel", {
					BackgroundTransparency = 1,
					Image = IMG.fx_sparkle,
					ImageColor3 = color or C.white,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(math.random(), math.random()),
					Size = UDim2.fromOffset(0, 0),
					Rotation = math.random(0, 45),
					ZIndex = z or parent.ZIndex + 2,
				}, parent)
				local t = math.random(45, 80) / 100
				TweenService:Create(s, TweenInfo.new(t, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(sz, sz), Rotation = s.Rotation + 45 }):Play()
				task.delay(t, function()
					TweenService:Create(s, TweenInfo.new(0.35), { Size = UDim2.fromOffset(0, 0), ImageTransparency = 1 }):Play()
					task.delay(0.4, function()
						s:Destroy()
					end)
				end)
			end
			task.wait((rate or 0.35) * (0.6 + math.random() * 0.8))
		end
	end)
end

-- Soft wisps of light drifting upwards from the bottom of a frame.
function Theme.wisps(parent, color, rate, z)
	if not IMG.fx_wisp then
		return
	end
	task.spawn(function()
		while alive(parent) do
			if parent.Visible ~= false then
				local sz = math.random(26, 60)
				local x = math.random()
				local w = make("ImageLabel", {
					BackgroundTransparency = 1,
					Image = IMG.fx_wisp,
					ImageColor3 = color or C.white,
					ImageTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(x, 0.95),
					Size = UDim2.fromOffset(sz, sz),
					ZIndex = z or parent.ZIndex + 1,
				}, parent)
				local life = 1.8 + math.random() * 1.4
				TweenService:Create(w, TweenInfo.new(life, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Position = UDim2.fromScale(x + (math.random() - 0.5) * 0.25, 0.1 + math.random() * 0.3) }):Play()
				TweenService:Create(w, TweenInfo.new(life * 0.35), { ImageTransparency = 0.45 }):Play()
				task.delay(life * 0.55, function()
					TweenService:Create(w, TweenInfo.new(life * 0.45), { ImageTransparency = 1 }):Play()
				end)
				task.delay(life + 0.1, function()
					w:Destroy()
				end)
			end
			task.wait((rate or 0.5) * (0.6 + math.random() * 0.8))
		end
	end)
end

-- Light rays spinning slowly behind something, centred in the parent.
function Theme.rays(parent, color, size, z, transparency)
	if not IMG.fx_rays then
		return nil
	end
	local r = make("ImageLabel", {
		Name = "Rays",
		BackgroundTransparency = 1,
		Image = IMG.fx_rays,
		ImageColor3 = color or C.yellow,
		ImageTransparency = transparency or 0.45,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size or 420, size or 420),
		ZIndex = z or parent.ZIndex,
	}, parent)
	TweenService:Create(r, TweenInfo.new(14, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 360 }):Play()
	return r
end

return Theme
