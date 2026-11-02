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
	b.MouseButton1Down:Connect(function()
		set(true)
	end)
	b.MouseButton1Up:Connect(function()
		set(false)
	end)
	b.MouseLeave:Connect(function()
		if pressed then
			set(false)
		end
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

-- Put an icon on the left of a Theme.button and move its label over to make room.
function Theme.withIcon(b, name, scale, height)
	local h = height or (b.Size.Y.Offset > 0 and b.Size.Y.Offset) or 50
	local size = math.floor(h * (scale or 1.05))
	local ic = Theme.icon(b, name, UDim2.fromOffset(size, size), UDim2.new(0, -math.floor(size * 0.18), 0.5, -math.floor(size * 0.55)), b.ZIndex + 1)
	if ic then
		b.Label.Position = UDim2.fromOffset(math.floor(size * 0.7), 1)
		b.Label.Size = UDim2.new(1, -math.floor(size * 0.7) - 6, 0.82, -2)
		b:GetPropertyChangedSignal("ZIndex"):Connect(function()
			ic.ZIndex = b.ZIndex + 1
		end)
	end
	return ic
end

-- The asphalt panel image behind a frame (9-slice). Returns true when the art is used.
function Theme.panelArt(frame, z)
	if not IMG.panel then
		return false
	end
	frame.BackgroundTransparency = 1
	make("ImageLabel", {
		Name = "PanelArt",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Image = IMG.panel,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(36, 36, 220, 220),
		SliceScale = 0.6,
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

return Theme
