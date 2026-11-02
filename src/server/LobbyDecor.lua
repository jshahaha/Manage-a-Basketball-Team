--!nonstrict
-- Lobby scenery: terrain (grass, rolling hills around the edge, a pond), trees, lamp posts,
-- benches and the lighting setup. Kept apart from LobbyWorld so the gameplay pieces (stations,
-- plots) stay easy to read. Detailed meshes in ServerStorage.LobbyAssets (Tree, Lamp, Bench, Planter;
-- pivot at the base centre) replace the procedural versions here.

local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")

local LobbyDecor = {}

local function part(parent, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent
	return p
end
LobbyDecor.part = part

-- An imported model from ServerStorage.LobbyAssets, if there is one.
local function asset(name)
	local lib = ServerStorage:FindFirstChild("LobbyAssets")
	local m = lib and lib:FindFirstChild(name)
	return m and m:Clone() or nil
end

-- A simple deterministic random so the map looks the same every server.
local seed = 1234567
local function rnd(a, b)
	seed = (seed * 1103515245 + 12345) % 2147483648
	local u = seed / 2147483648
	return a + (b - a) * u
end

function LobbyDecor.terrain(bounds)
	local T = workspace.Terrain
	T:Clear()
	local hx, hz = bounds.X, bounds.Z
	-- Ground: grass with the top at y = 0.
	T:FillBlock(CFrame.new(0, -9, 0), Vector3.new(hx * 2 + 200, 12, hz * 2 + 200), Enum.Material.Grass) -- top a little under y = 0 so floors and paving sit on it
	-- Rolling hills around the edge, in two rings so they overlap into a soft wall.
	for ring = 1, 2 do
		local n = ring == 1 and 34 or 26
		for i = 1, n do
			local a = (i + rnd(-0.3, 0.3)) / n * math.pi * 2
			local rx = hx + 40 + ring * 45 + rnd(-15, 15)
			local rz = hz + 40 + ring * 45 + rnd(-15, 15)
			local c = Vector3.new(math.cos(a) * rx, -18 + ring * 6, math.sin(a) * rz)
			T:FillBall(c, rnd(38, 62) + ring * 8, ring == 1 and Enum.Material.Grass or Enum.Material.LeafyGrass)
		end
	end
	-- A pond beside the plaza, ringed with sand.
	local pond = bounds.pond
	if pond then
		-- Smooth terrain renders cylinder tops about 3 studs higher than asked, hence the low numbers.
		T:FillCylinder(CFrame.new(pond + Vector3.new(0, -10.5, 0)), 12, 30, Enum.Material.Sand)
		T:FillCylinder(CFrame.new(pond + Vector3.new(0, -1, 0)), 8, 24, Enum.Material.Air)
		T:FillCylinder(CFrame.new(pond + Vector3.new(0, -8, 0)), 6, 24, Enum.Material.Water)
	end
	T.WaterColor = Color3.fromRGB(40, 140, 170)
	T.WaterTransparency = 0.6
	T.WaterWaveSize = 0.1
	T.WaterWaveSpeed = 6
end

-- Swap the grass under built areas for plain ground, so grass blades don't poke through
-- paving, courts and floors.
function LobbyDecor.clearGrassBlock(center, size)
	workspace.Terrain:FillBlock(CFrame.new(center.X, -9, center.Z), Vector3.new(size.X, 12, size.Z), Enum.Material.LeafyGrass) -- no grass blades on this one
end
function LobbyDecor.clearGrassDisc(center, radius)
	LobbyDecor.clearGrassBlock(center, Vector3.new(radius * 2, 0, radius * 2)) -- FillCylinder rounds the top up a whole voxel
end

-- A stylised tree: trunk and three stacked leaf balls in slightly different greens.
function LobbyDecor.tree(parent, pos, size)
	local m = asset("Tree")
	if m then
		m:PivotTo(CFrame.new(pos) * CFrame.Angles(0, rnd(0, math.pi * 2), 0))
		m:ScaleTo(size or rnd(0.85, 1.25))
		m.Parent = parent
		return m
	end
	size = size or rnd(0.85, 1.25)
	pos -= Vector3.new(0, 1.5, 0) -- root it into the ground, which sits a little under y = 0
	m = Instance.new("Model")
	m.Name = "Tree"
	local h = 9 * size
	part(m, { Name = "Trunk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 1.6 * size, 1.6 * size), CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(110, 76, 50), Material = Enum.Material.Wood })
	local greens = { Color3.fromRGB(72, 150, 62), Color3.fromRGB(88, 170, 72), Color3.fromRGB(104, 186, 84) }
	for k = 1, 3 do
		local r = (8.5 - k * 1.8) * size
		part(m, {
			Name = "Leaves",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * r,
			Position = pos + Vector3.new(rnd(-0.6, 0.6), h + (k - 1) * 2.6 * size, rnd(-0.6, 0.6)),
			Color = greens[k],
			Material = Enum.Material.Grass,
			CastShadow = true,
		})
	end
	m.Parent = parent
	return m
end

function LobbyDecor.lamp(parent, pos)
	local m = asset("Lamp")
	if m then
		m:PivotTo(CFrame.new(pos))
		m.Parent = parent
		return m
	end
	m = Instance.new("Model")
	m.Name = "Lamp"
	local dark = Color3.fromRGB(40, 44, 60)
	part(m, { Name = "Base", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 2, 2), CFrame = CFrame.new(pos + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = dark, Material = Enum.Material.Metal })
	part(m, { Name = "Pole", Shape = Enum.PartType.Cylinder, Size = Vector3.new(12, 0.6, 0.6), CFrame = CFrame.new(pos + Vector3.new(0, 6.4, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = dark, Material = Enum.Material.Metal })
	local bulb = part(m, { Name = "Bulb", Shape = Enum.PartType.Ball, Size = Vector3.one * 1.8, Position = pos + Vector3.new(0, 13, 0), Color = Color3.fromRGB(255, 236, 190), Material = Enum.Material.Neon })
	part(m, { Name = "Cap", Size = Vector3.new(2.2, 0.3, 2.2), Position = pos + Vector3.new(0, 14, 0), Color = dark, Material = Enum.Material.Metal })
	local light = Instance.new("PointLight")
	light.Range = 22
	light.Brightness = 1.2
	light.Color = Color3.fromRGB(255, 226, 170)
	light.Shadows = false
	light.Parent = bulb
	m.Parent = parent
	return m
end

function LobbyDecor.bench(parent, cf)
	local m = asset("Bench")
	if m then
		m:PivotTo(cf)
		m.Parent = parent
		return m
	end
	m = Instance.new("Model")
	m.Name = "Bench"
	local wood = Color3.fromRGB(176, 120, 72)
	local metal = Color3.fromRGB(46, 50, 66)
	for k = 0, 2 do
		part(m, { Name = "Slat", Size = Vector3.new(6, 0.25, 0.55), CFrame = cf * CFrame.new(0, 1.7, -0.6 + k * 0.6), Color = wood, Material = Enum.Material.WoodPlanks })
	end
	for k = 0, 1 do
		part(m, { Name = "Back", Size = Vector3.new(6, 0.5, 0.2), CFrame = cf * CFrame.new(0, 2.4 + k * 0.7, 0.85) * CFrame.Angles(math.rad(-12), 0, 0), Color = wood, Material = Enum.Material.WoodPlanks })
	end
	for _, x in ipairs({ -2.6, 2.6 }) do
		part(m, { Name = "Leg", Size = Vector3.new(0.3, 1.7, 1.6), CFrame = cf * CFrame.new(x, 0.85, 0), Color = metal, Material = Enum.Material.Metal })
	end
	m.Parent = parent
	return m
end

function LobbyDecor.planter(parent, pos)
	local m = asset("Planter")
	if m then
		m:PivotTo(CFrame.new(pos) * CFrame.Angles(0, math.floor(rnd(0, 4)) * math.pi / 2, 0))
		m.Parent = parent
		return m
	end
	m = Instance.new("Model")
	m.Name = "Planter"
	part(m, { Name = "Box", Size = Vector3.new(4, 2, 4), Position = pos + Vector3.new(0, 1, 0), Color = Color3.fromRGB(205, 200, 190), Material = Enum.Material.Concrete })
	part(m, { Name = "Soil", Size = Vector3.new(3.4, 0.3, 3.4), Position = pos + Vector3.new(0, 2.05, 0), Color = Color3.fromRGB(80, 56, 40), Material = Enum.Material.Ground })
	part(m, { Name = "Bush", Shape = Enum.PartType.Ball, Size = Vector3.one * 3.8, Position = pos + Vector3.new(0, 3.4, 0), Color = Color3.fromRGB(80, 160, 70), Material = Enum.Material.Grass })
	m.Parent = parent
	return m
end

function LobbyDecor.lighting()
	Lighting.ClockTime = 14.2
	Lighting.Brightness = 2.6
	Lighting.Ambient = Color3.fromRGB(70, 70, 80)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 160)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.25
	local function ensure(class, props)
		local x = Lighting:FindFirstChildOfClass(class) or Instance.new(class)
		for k, v in pairs(props) do
			x[k] = v
		end
		x.Parent = Lighting
		return x
	end
	ensure("Atmosphere", { Density = 0.28, Offset = 0.15, Color = Color3.fromRGB(205, 225, 245), Decay = Color3.fromRGB(120, 150, 190), Glare = 0.2, Haze = 1.2 })
	ensure("BloomEffect", { Intensity = 0.35, Size = 28, Threshold = 1.4 })
	ensure("ColorCorrectionEffect", { Saturation = 0.12, Contrast = 0.06, Brightness = 0.02 })
	ensure("SunRaysEffect", { Intensity = 0.06, Spread = 0.6 })
end

LobbyDecor.rnd = rnd

return LobbyDecor
