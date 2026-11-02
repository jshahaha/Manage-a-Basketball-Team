--!nonstrict
-- "Blacktop" UI theme (js picked it 2026-11-02): a street court at sunset.
-- Asphalt panels, cream gaffer-tape labels, stencil-style condensed headings, marker accents,
-- and one loud neon per button. Every screen builds its UI through these helpers so the look
-- stays the same everywhere.

local Theme = {}

Theme.C = {
	asphalt = Color3.fromHex("2b2d31"), -- panel background
	slate = Color3.fromHex("1c1d21"), -- rows and cards on a panel
	deep = Color3.fromHex("141518"), -- shade behind popups
	line = Color3.fromHex("3d4047"), -- quiet borders
	ink = Color3.fromHex("f3efe2"), -- main text on asphalt (cream)
	muted = Color3.fromHex("a3a8ae"),
	black = Color3.fromHex("111111"), -- outlines and text on tape
	tape = Color3.fromHex("f3efe2"),
	yellow = Color3.fromHex("f5d33a"), -- court-line yellow: the main action colour
	orange = Color3.fromHex("ff6a3d"),
	sky = Color3.fromHex("4fd0ff"),
	lime = Color3.fromHex("b7f36b"),
	pink = Color3.fromHex("ff7ad9"),
	red = Color3.fromHex("ff4d4d"),
	sunsetTop = Color3.fromHex("ff8f5a"),
	sunsetBottom = Color3.fromHex("ffc36b"),
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
function Theme.stroke(o, t, color, transparency)
	return make("UIStroke", { Thickness = t, Color = color or C.black, Transparency = transparency or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
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

-- Buttons: a solid neon slab with a black outline. `color` picks the neon; text colour follows.
function Theme.button(parent, label, color, sz, pos, onClick)
	local b = make("TextButton", {
		Text = label,
		FontFace = Theme.HEAD,
		TextSize = 20,
		TextColor3 = Theme.textOn(color),
		BackgroundColor3 = color,
		Size = sz,
		Position = pos or UDim2.new(),
		AutoButtonColor = true,
	}, parent)
	Theme.round(b, 6)
	Theme.stroke(b, 3)
	if onClick then
		b.MouseButton1Click:Connect(onClick)
	end
	return b
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
	Theme.round(f, 2)
	-- Torn ends: two thin darker strips.
	for _, x in ipairs({ 0, 1 }) do
		make("Frame", { AnchorPoint = Vector2.new(x, 0), Position = UDim2.fromScale(x, 0), Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = C.black, BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = (p.z or 1) + 1 }, f)
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
