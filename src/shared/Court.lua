--!nonstrict
-- Builds the match court in code, so it lives in the repo instead of only in a place file.
-- Real NBA measurements, scaled so our ~6'7" players (about 5.9 studs) stand at the right size
-- next to a 10 ft rim: 1 ft = 0.9 studs. The court runs along X (side-on camera looks along Z).
--
--   local court = Court.build({ home = Color3, away = Color3, floor = Color3? })
--   court.Parent = workspace
--   Court.rimPosition(court, 1)  -- world position of the right-hand rim (-1 for the left)

local Court = {}

local FT = 0.9
Court.Feet = FT
Court.Length, Court.Width = 94 * FT, 50 * FT
Court.RimHeight = 10 * FT
Court.RimFromBaseline = 5.25 * FT
Court.ThreeRadius, Court.CornerThree = 23.75 * FT, 22 * FT
Court.KeyWidth, Court.KeyLength = 16 * FT, 19 * FT
Court.LINE = 0.18

local WHITE = Color3.fromRGB(245, 245, 245)

local function part(parent, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent
	return p
end

-- A painted line from a to b (both on the floor plane, y ignored).
local function line(parent, top, a: Vector3, b: Vector3, color)
	local mid = (a + b) / 2
	local len = (b - a).Magnitude
	return part(parent, {
		Name = "Line",
		Size = Vector3.new(len + Court.LINE, 0.02, Court.LINE),
		CFrame = CFrame.lookAt(Vector3.new(mid.X, top + 0.01, mid.Z), Vector3.new(b.X, top + 0.01, b.Z)) * CFrame.Angles(0, math.rad(90), 0),
		Color = color or WHITE,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
	})
end

-- Arc of line segments around center, from angle a0 to a1 (radians, 0 = +X).
local function arc(parent, top, center: Vector3, r, a0, a1, segs, color)
	local prev
	for i = 0, segs do
		local a = a0 + (a1 - a0) * i / segs
		local p = center + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		if prev then
			line(parent, top, prev, p, color)
		end
		prev = p
	end
end

local function hoop(parent, top, side: number)
	local m = Instance.new("Model")
	m.Name = side > 0 and "HoopRight" or "HoopLeft"
	local x = side * (Court.Length / 2 - Court.RimFromBaseline)
	local rimY = top + Court.RimHeight
	local boardX = x + side * 0.75 * FT * 1.6 -- rim front to backboard about 15 in plus the rim
	-- Backboard 6 ft x 3.5 ft.
	part(m, {
		Name = "Backboard",
		Size = Vector3.new(0.12, 3.5 * FT, 6 * FT),
		Position = Vector3.new(boardX, rimY + 1.1, 0),
		Color = Color3.fromRGB(220, 235, 255),
		Transparency = 0.35,
		Material = Enum.Material.Glass,
	})
	for _, e in ipairs({ { 0, 0.75 * FT, 1 * FT }, { 0, -0.75 * FT, 1 * FT } }) do
		part(m, { Name = "SquareEdge", Size = Vector3.new(0.14, Court.LINE, 2 * FT), Position = Vector3.new(boardX - side * 0.01, rimY + 0.7 + e[2], 0), Color = WHITE, CanCollide = false })
	end
	for _, z in ipairs({ -1 * FT, 1 * FT }) do
		part(m, { Name = "SquareEdge", Size = Vector3.new(0.14, 1.5 * FT, Court.LINE), Position = Vector3.new(boardX - side * 0.01, rimY + 0.7, z), Color = WHITE, CanCollide = false })
	end
	-- Rim: a ring of short orange segments, 18 in across.
	local r = 0.75 * FT
	local segs = 16
	for i = 1, segs do
		local a0, a1 = (i - 1) / segs * math.pi * 2, i / segs * math.pi * 2
		local p0 = Vector3.new(x + math.cos(a0) * r, rimY, math.sin(a0) * r)
		local p1 = Vector3.new(x + math.cos(a1) * r, rimY, math.sin(a1) * r)
		part(m, {
			Name = "Rim",
			Size = Vector3.new(0.12, 0.12, (p1 - p0).Magnitude + 0.04),
			CFrame = CFrame.lookAt((p0 + p1) / 2, p1),
			Color = Color3.fromRGB(255, 90, 20),
			Material = Enum.Material.Metal,
		})
	end
	part(m, { Name = "RimArm", Size = Vector3.new(math.abs(boardX - x) - r, 0.12, 0.3), Position = Vector3.new((boardX + x + side * r) / 2, rimY, 0), Color = Color3.fromRGB(255, 90, 20), Material = Enum.Material.Metal })
	-- Net: tapered strands.
	for i = 1, 12 do
		local a = i / 12 * math.pi * 2
		local p0 = Vector3.new(x + math.cos(a) * r, rimY, math.sin(a) * r)
		local p1 = Vector3.new(x + math.cos(a) * r * 0.55, rimY - 1.4 * FT, math.sin(a) * r * 0.55)
		part(m, {
			Name = "Net",
			Size = Vector3.new(0.05, 0.05, (p1 - p0).Magnitude),
			CFrame = CFrame.lookAt((p0 + p1) / 2, p1),
			Color = WHITE,
			CanCollide = false,
			Material = Enum.Material.Fabric,
		})
	end
	-- Stanchion behind the baseline.
	local baseX = side * (Court.Length / 2 + 4 * FT)
	part(m, { Name = "Pole", Size = Vector3.new(0.7, rimY + 2 - top, 0.7), Position = Vector3.new(baseX, (top + rimY + 2) / 2, 0), Color = Color3.fromRGB(40, 44, 60), Material = Enum.Material.Metal })
	part(m, { Name = "Arm", Size = Vector3.new(math.abs(baseX - boardX), 0.5, 0.5), Position = Vector3.new((baseX + boardX) / 2, rimY + 2, 0), Color = Color3.fromRGB(40, 44, 60), Material = Enum.Material.Metal })
	part(m, { Name = "Pad", Size = Vector3.new(2.4, 2.4, 3), Position = Vector3.new(baseX, top + 1.2, 0), Color = Color3.fromRGB(27, 33, 64) })
	m.Parent = parent
	return m
end

function Court.build(opts)
	opts = opts or {}
	local home = opts.home or Color3.fromRGB(37, 99, 235)
	local away = opts.away or Color3.fromRGB(232, 69, 107)
	local court = Instance.new("Model")
	court.Name = "Court"
	local L, W = Court.Length, Court.Width
	local top = 0
	-- Floor with a run-off apron, then the playing surface.
	part(court, { Name = "Apron", Size = Vector3.new(L + 24, 1, W + 20), Position = Vector3.new(0, -0.5 - 0.01, 0), Color = Color3.fromRGB(40, 46, 74), Material = Enum.Material.SmoothPlastic })
	part(court, { Name = "Floor", Size = Vector3.new(L, 1, W), Position = Vector3.new(0, -0.5, 0), Color = opts.floor or Color3.fromRGB(214, 160, 100), Material = Enum.Material.WoodPlanks })
	-- Painted keys in the two teams' colors.
	for _, side in ipairs({ -1, 1 }) do
		local base = side * L / 2
		part(court, {
			Name = "Paint",
			Size = Vector3.new(Court.KeyLength, 0.02, Court.KeyWidth),
			Position = Vector3.new(base - side * Court.KeyLength / 2, top + 0.005, 0),
			Color = side > 0 and home or away,
			Material = Enum.Material.SmoothPlastic,
			Transparency = 0.15,
			CanCollide = false,
		})
	end
	local lines = Instance.new("Folder")
	lines.Name = "Lines"
	lines.Parent = court
	local hx, hz = L / 2, W / 2
	-- Boundary and half-court.
	line(lines, top, Vector3.new(-hx, 0, -hz), Vector3.new(hx, 0, -hz))
	line(lines, top, Vector3.new(-hx, 0, hz), Vector3.new(hx, 0, hz))
	line(lines, top, Vector3.new(-hx, 0, -hz), Vector3.new(-hx, 0, hz))
	line(lines, top, Vector3.new(hx, 0, -hz), Vector3.new(hx, 0, hz))
	line(lines, top, Vector3.new(0, 0, -hz), Vector3.new(0, 0, hz))
	arc(lines, top, Vector3.zero, 6 * FT, 0, math.pi * 2, 28)
	for _, side in ipairs({ -1, 1 }) do
		local base = side * hx
		local rimX = side * (hx - Court.RimFromBaseline)
		local ft = base - side * Court.KeyLength
		local kw = Court.KeyWidth / 2
		-- Key outline and free-throw circle.
		line(lines, top, Vector3.new(base, 0, -kw), Vector3.new(ft, 0, -kw))
		line(lines, top, Vector3.new(base, 0, kw), Vector3.new(ft, 0, kw))
		line(lines, top, Vector3.new(ft, 0, -kw), Vector3.new(ft, 0, kw))
		local inward = side > 0 and math.pi or 0
		arc(lines, top, Vector3.new(ft, 0, 0), 6 * FT, inward - math.pi / 2, inward + math.pi / 2, 14)
		-- Three-point line: straight corners 22 ft from the rim, then the 23.75 ft arc.
		local cz = Court.CornerThree
		local dx = math.sqrt(Court.ThreeRadius ^ 2 - cz ^ 2)
		line(lines, top, Vector3.new(base, 0, -cz), Vector3.new(rimX - side * dx, 0, -cz))
		line(lines, top, Vector3.new(base, 0, cz), Vector3.new(rimX - side * dx, 0, cz))
		local a = math.atan2(cz, dx)
		arc(lines, top, Vector3.new(rimX, 0, 0), Court.ThreeRadius, inward - a, inward + a, 30)
		-- Restricted area.
		arc(lines, top, Vector3.new(rimX, 0, 0), 4 * FT, inward - math.pi / 2, inward + math.pi / 2, 12)
		hoop(court, top, side)
	end
	-- Low bleachers on the far side so the side-on camera has a crowd behind the play.
	local stands = Instance.new("Folder")
	stands.Name = "Stands"
	stands.Parent = court
	for row = 0, 5 do
		part(stands, {
			Name = "Row",
			Size = Vector3.new(L + 10, 1.2, 3),
			Position = Vector3.new(0, 0.6 + row * 1.2, -(hz + 8 + row * 3)),
			Color = row % 2 == 0 and Color3.fromRGB(30, 36, 66) or Color3.fromRGB(38, 46, 82),
			Material = Enum.Material.SmoothPlastic,
		})
	end
	court.PrimaryPart = court:FindFirstChild("Floor")
	return court
end

function Court.rimPosition(court, side: number): Vector3
	local x = side * (Court.Length / 2 - Court.RimFromBaseline)
	return court:GetPivot().Position + Vector3.new(x, 0.5 + Court.RimHeight, 0) -- pivot is the floor part's center
end

return Court
