--!nonstrict
-- The lobby: a central plaza with a jumbotron landmark and a fountain, six storefronts around
-- it (each opens one screen), and 8 Home Court plots in two rows (north and south) behind
-- them, set in grass terrain with hills, trees and a pond. Each manager gets a plot when they
-- join; it takes their colours and name, and their PLAY matches are acted out on it.
--
-- Layout follows what popular hub games do: spawn on a clear plaza facing one big landmark
-- you can see from anywhere, shops with their own colours along the main paths, courts down
-- wide walkways, and layered hills and trees as the edge of the world.
--
-- Courts stay aligned with the X axis because the match view and the side-on camera work in
-- world X/Z (see CourtView).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Court = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Court"))
local ServerStorage = game:GetService("ServerStorage")
local LobbyDecor = require(script.Parent:WaitForChild("LobbyDecor"))

local LobbyWorld = {}

local ROW_Z = { north = -150, south = 150 }
LobbyWorld.PlotCenters = {
	Vector3.new(-195, 0, ROW_Z.north), Vector3.new(-65, 0, ROW_Z.north), Vector3.new(65, 0, ROW_Z.north), Vector3.new(195, 0, ROW_Z.north),
	Vector3.new(-195, 0, ROW_Z.south), Vector3.new(-65, 0, ROW_Z.south), Vector3.new(65, 0, ROW_Z.south), Vector3.new(195, 0, ROW_Z.south),
}

-- Station id, sign, prompt text, colour. The client opens the screen named by `id`.
-- angle: where the storefront sits around the plaza (degrees from +X).
LobbyWorld.Stations = {
	{ id = "Shop", name = "PACK SHOP", action = "Open Shop", color = Color3.fromHex("e8650c"), angle = -28 },
	{ id = "Quests", name = "QUEST BOARD", action = "View Quests", color = Color3.fromHex("1f9e3f"), angle = 0 },
	{ id = "Club", name = "LOCKER ROOM", action = "Manage Club", color = Color3.fromHex("2e6fd8"), angle = 28 },
	{ id = "Scout", name = "SCOUT OFFICE", action = "Scouting", color = Color3.fromHex("7a4fd8"), angle = 152 },
	{ id = "Trade", name = "TRADE BOARD", action = "Trading", color = Color3.fromHex("e8456b"), angle = 180 },
	{ id = "HallOfFame", name = "HALL OF FAME", action = "Leaderboards", color = Color3.fromHex("b98a00"), angle = 208 },
}

local PLAZA_R = 58 -- paved plaza radius
local SHOP_R = 78 -- storefront centres

-- Club colours until club creation exists: picked from the user id so they stay the same.
local PALETTE = {
	Color3.fromRGB(37, 99, 235), Color3.fromRGB(232, 69, 107), Color3.fromRGB(31, 158, 63), Color3.fromRGB(232, 101, 12),
	Color3.fromRGB(130, 70, 220), Color3.fromRGB(0, 150, 160), Color3.fromRGB(200, 160, 0), Color3.fromRGB(20, 24, 48),
}
local NEUTRAL = Color3.fromRGB(150, 156, 170)
local INK = Color3.fromHex("1b2140")
local WHITE = Color3.new(1, 1, 1)

local part = LobbyDecor.part

-- Where the walkway runs along each row: on the open side of the courts (the stands are
-- always on the -Z side of a court).
local function rowWalkZ(z)
	return z < 0 and z + 40 or z - 54
end


local function signText(parent, face, text, color, size)
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 40
	g.LightInfluence = 0
	g.Parent = parent
	local l = Instance.new("TextLabel")
	l.Name = "Text"
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.TextColor3 = color or WHITE
	l.Text = text
	l.Parent = g
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0.05, 0), UDim.new(0.05, 0)
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0.12, 0), UDim.new(0.12, 0)
	pad.Parent = l
	if size then
		local c = Instance.new("UITextSizeConstraint")
		c.MaxTextSize = size
		c.Parent = l
	end
	return l
end

local function cylinder(parent, name, h, r, cf, color, material)
	return part(parent, { Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, r * 2, r * 2), CFrame = cf * CFrame.Angles(0, 0, math.rad(90)), Color = color, Material = material or Enum.Material.SmoothPlastic })
end

-- A flat ring built from many short blocks. Big cylinder parts render with only a few sides
-- from a distance, so painted rings made this way stay round.
local function smoothRing(parent, name, radius, width, y, color, material)
	local n = math.max(48, math.floor(radius * 3))
	local len = 2 * math.pi * radius / n + 0.15
	for k = 0, n - 1 do
		local a = k / n * math.pi * 2
		part(parent, { Name = name, Size = Vector3.new(width, 1, len), CFrame = CFrame.new(math.cos(a) * radius, y, math.sin(a) * radius) * CFrame.Angles(0, -a, 0), Color = color, Material = material or Enum.Material.SmoothPlastic })
	end
end

-- A storefront facing the plaza centre: glass front, striped awning, lit sign, planters.
local function storefront(parent, info, pos)
	local m = Instance.new("Model")
	m.Name = info.id
	local look = CFrame.lookAt(pos, Vector3.new(0, pos.Y, 0)) -- -Z faces the plaza
	local function at(x, y, z)
		return look * CFrame.new(x, y, z)
	end
	local wall = Color3.fromRGB(242, 238, 230)
	local trim = Color3.fromRGB(60, 64, 84)
	local W, D, H = 22, 16, 13
	part(m, { Name = "Floor", Size = Vector3.new(W, 0.6, D), CFrame = at(0, 0.3, 0), Color = Color3.fromRGB(200, 196, 188), Material = Enum.Material.Marble })
	part(m, { Name = "BackWall", Size = Vector3.new(W, H, 1), CFrame = at(0, H / 2, D / 2 - 0.5), Color = wall, Material = Enum.Material.Plaster })
	for _, x in ipairs({ -1, 1 }) do
		part(m, { Name = "SideWall", Size = Vector3.new(1, H, D), CFrame = at(x * (W / 2 - 0.5), H / 2, 0), Color = wall, Material = Enum.Material.Plaster })
		-- Front: a brick pillar on each corner, then glass up to the door.
		part(m, { Name = "Pillar", Size = Vector3.new(2.4, H, 1.4), CFrame = at(x * (W / 2 - 1.2), H / 2, -D / 2 + 0.7), Color = info.color, Material = Enum.Material.Brick })
		part(m, { Name = "Window", Size = Vector3.new(5.6, 7, 0.3), CFrame = at(x * 6.3, 4.3, -D / 2 + 0.6), Color = Color3.fromRGB(170, 210, 235), Material = Enum.Material.Glass, Transparency = 0.45 })
		part(m, { Name = "Sill", Size = Vector3.new(5.8, 0.8, 1.2), CFrame = at(x * 6.3, 0.4, -D / 2 + 0.6), Color = trim, Material = Enum.Material.Concrete })
		part(m, { Name = "Mullion", Size = Vector3.new(0.4, 7.4, 0.5), CFrame = at(x * 3.4, 4.5, -D / 2 + 0.6), Color = trim, Material = Enum.Material.Metal })
	end
	part(m, { Name = "Header", Size = Vector3.new(W, H - 8, 1.2), CFrame = at(0, 8 + (H - 8) / 2, -D / 2 + 0.6), Color = wall, Material = Enum.Material.Plaster })
	part(m, { Name = "Roof", Size = Vector3.new(W + 1, 0.8, D + 1), CFrame = at(0, H + 0.4, 0), Color = trim, Material = Enum.Material.Concrete })
	part(m, { Name = "Parapet", Size = Vector3.new(W + 1, 1.4, 0.8), CFrame = at(0, H + 1.5, -D / 2 - 0.1), Color = info.color, Material = Enum.Material.SmoothPlastic })
	-- A big themed prop on the roof (giant pack, trophy, clipboard...), from LobbyAssets.Roof<id>.
	local roofProp = LobbyDecor.prop(m, "Roof" .. info.id, at(0, H + 2.2, 1) * CFrame.Angles(0, math.pi, 0))
	if roofProp then
		roofProp.Name = "RoofProp"
	end
	-- Sign over the door, with a neon frame.
	local sign = part(m, { Name = "Sign", Size = Vector3.new(15, 3.2, 0.5), CFrame = at(0, 10.6, -D / 2 - 0.15), Color = INK })
	signText(sign, Enum.NormalId.Front, info.name)
	for _, y in ipairs({ -1.75, 1.75 }) do
		part(m, { Name = "SignNeon", Size = Vector3.new(15.4, 0.25, 0.3), CFrame = at(0, 10.6 + y, -D / 2 - 0.3), Color = info.color, Material = Enum.Material.Neon })
	end
	-- Striped awning over the windows.
	local stripes = 8
	for k = 1, stripes do
		local x = -W / 2 + (k - 0.5) * W / stripes
		part(m, { Name = "Awning", Size = Vector3.new(W / stripes, 0.3, 4.2), CFrame = at(x, 8.1, -D / 2 - 1.9) * CFrame.Angles(math.rad(-18), 0, 0), Color = k % 2 == 0 and WHITE or info.color })
	end
	-- Inside: a counter in the club colour and a warm light.
	part(m, { Name = "Counter", Size = Vector3.new(10, 3.4, 2.4), CFrame = at(0, 2.3, 3.5), Color = info.color, Material = Enum.Material.SmoothPlastic })
	part(m, { Name = "CounterTop", Size = Vector3.new(10.4, 0.3, 2.8), CFrame = at(0, 4.15, 3.5), Color = WHITE, Material = Enum.Material.Marble })
	local glow = part(m, { Name = "CeilingLight", Size = Vector3.new(8, 0.3, 3), CFrame = at(0, H - 0.4, 1), Color = Color3.fromRGB(255, 244, 220), Material = Enum.Material.Neon })
	local light = Instance.new("PointLight")
	light.Range = 18
	light.Brightness = 1.4
	light.Color = Color3.fromRGB(255, 232, 196)
	light.Parent = glow
	-- Entrance: the walk-up prompt sits in the doorway.
	local door = part(m, { Name = "Entrance", Size = Vector3.new(6, 6, 2), CFrame = at(0, 3.6, -D / 2 - 1), Transparency = 1, CanCollide = false, CanQuery = false })
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = info.action
	prompt.ObjectText = info.name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 16
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Station", info.id)
	prompt.Parent = door
	for _, x in ipairs({ -1, 1 }) do
		LobbyDecor.planter(m, (at(x * (W / 2 + 2.6), 0, -D / 2 + 1)).Position)
	end
	m.PrimaryPart = m:FindFirstChild("Floor")
	m.Parent = parent
	return m
end

-- The landmark: a fountain with a tall pillar carrying a four-sided jumbotron.
local function landmark(parent)
	local m = Instance.new("Model")
	m.Name = "Jumbotron"
	local stone = Color3.fromRGB(214, 210, 200)
	cylinder(m, "BasinWall", 2.4, 15, CFrame.new(0, 1.2, 0), stone, Enum.Material.Marble)
	cylinder(m, "Water", 0.4, 14, CFrame.new(0, 2.0, 0), Color3.fromRGB(70, 170, 210), Enum.Material.Glass).Transparency = 0.25
	-- Centrepiece: the detailed basketball monument from ServerStorage.LobbyAssets when it's there,
	-- otherwise the old pillar with a title screen.
	local lib = ServerStorage:FindFirstChild("LobbyAssets")
	local monument = lib and lib:FindFirstChild("Monument")
	if monument then
		monument = monument:Clone()
		monument:PivotTo(CFrame.new(0, 2.2, 0))
		monument.Parent = m
	else
		cylinder(m, "Plinth", 4, 5, CFrame.new(0, 2, 0), stone, Enum.Material.Marble)
		cylinder(m, "Pillar", 26, 2, CFrame.new(0, 17, 0), Color3.fromRGB(46, 50, 70), Enum.Material.Metal)
		local screen = part(m, { Name = "Screen", Size = Vector3.new(18, 10, 18), Position = Vector3.new(0, 34, 0), Color = INK, Material = Enum.Material.SmoothPlastic })
		for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }) do
			local l = signText(screen, face, "MANAGE A\nBASKETBALL TEAM", Color3.fromRGB(255, 200, 60))
			l.Font = Enum.Font.GothamBlack
		end
		for _, y in ipairs({ -5.2, 5.2 }) do
			part(m, { Name = "ScreenTrim", Size = Vector3.new(18.6, 0.5, 18.6), Position = Vector3.new(0, 34 + y, 0), Color = Color3.fromRGB(255, 140, 40), Material = Enum.Material.Neon })
		end
		part(m, { Name = "BigBall", Shape = Enum.PartType.Ball, Size = Vector3.one * 7, Position = Vector3.new(0, 43, 0), Color = Color3.fromRGB(230, 110, 30), Material = Enum.Material.SmoothPlastic })
	end
	-- Fountain jets.
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		local nozzle = part(m, { Name = "Jet", Size = Vector3.new(0.6, 0.6, 0.6), Position = Vector3.new(math.cos(a) * 9, 2.4, math.sin(a) * 9), Transparency = 1, CanCollide = false })
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(Color3.fromRGB(200, 235, 255))
		e.Size = NumberSequence.new(0.5, 0.2)
		e.Transparency = NumberSequence.new(0.2, 1)
		e.Lifetime = NumberRange.new(0.9, 1.2)
		e.Rate = 30
		e.Speed = NumberRange.new(14, 16)
		e.SpreadAngle = Vector2.new(6, 6)
		e.Acceleration = Vector3.new(0, -30, 0)
		e.EmissionDirection = Enum.NormalId.Top
		e.Parent = nozzle
	end
	m.Parent = parent
end

local function buildPlaza(folder)
	local plaza = Instance.new("Model")
	plaza.Name = "Plaza"
	-- Paving in rings: stone edge, warm tiles, a wood centre like a half court.
	cylinder(plaza, "Edge", 1, PLAZA_R + 2, CFrame.new(0, -0.45, 0), Color3.fromRGB(170, 168, 160), Enum.Material.Concrete)
	cylinder(plaza, "Paving", 1, PLAZA_R, CFrame.new(0, -0.4, 0), Color3.fromRGB(58, 60, 64), Enum.Material.Asphalt) -- blacktop
	smoothRing(plaza, "Ring", 28.5, 2.6, -0.36, Color3.fromHex("ffd45e")) -- painted court-yellow ring
	smoothRing(plaza, "EdgeTrim", PLAZA_R + 0.6, 2.4, -0.38, Color3.fromRGB(170, 168, 160), Enum.Material.Concrete)
	plaza.Parent = folder
	landmark(folder)
	-- Wide walkways: north and south to the court rows, plus a path along each row.
	local walks = Instance.new("Folder")
	walks.Name = "Walkways"
	walks.Parent = folder
	local pave = Color3.fromRGB(78, 80, 84)
	for _, rowZ in ipairs({ ROW_Z.north, ROW_Z.south }) do
		local wz = rowWalkZ(rowZ)
		local s = wz < 0 and -1 or 1
		local len = math.abs(wz) - PLAZA_R + 4
		part(walks, { Name = "Walk", Size = Vector3.new(16, 1, len), Position = Vector3.new(0, -0.42, s * (PLAZA_R - 2 + len / 2)), Color = pave, Material = Enum.Material.Asphalt })
		part(walks, { Name = "RowWalk", Size = Vector3.new(500, 1, 12), Position = Vector3.new(0, -0.42, wz), Color = pave, Material = Enum.Material.Asphalt })
	end
	-- Storefronts, lamps between them, benches facing the fountain.
	local stations = Instance.new("Folder")
	stations.Name = "Stations"
	stations.Parent = folder
	for _, info in ipairs(LobbyWorld.Stations) do
		local a = math.rad(info.angle)
		storefront(stations, info, Vector3.new(math.cos(a) * SHOP_R, 0, math.sin(a) * SHOP_R))
	end
	local props = Instance.new("Folder")
	props.Name = "Props"
	props.Parent = folder
	for k = 0, 11 do
		local a = (k + 0.5) / 12 * math.pi * 2
		LobbyDecor.lamp(props, Vector3.new(math.cos(a) * (PLAZA_R - 4), 0, math.sin(a) * (PLAZA_R - 4)))
	end
	for k = 0, 7 do
		local a = (k + 0.25) / 8 * math.pi * 2
		local p = Vector3.new(math.cos(a) * 21, 0, math.sin(a) * 21)
		local cf = CFrame.lookAt(p, Vector3.new(0, 0, 0)) * CFrame.Angles(0, math.pi, 0)
		LobbyDecor.bench(props, cf)
		if k % 2 == 0 then
			-- A bin at the end of every other bench.
			LobbyDecor.prop(props, "Bin", cf * CFrame.new(4.2, 0, 0))
		end
	end
	-- Ball racks either side of the spawn, so the first thing you see says basketball.
	for _, x in ipairs({ -9, 9 }) do
		LobbyDecor.prop(props, "BallRack", CFrame.lookAt(Vector3.new(x, 0, 47), Vector3.new(0, 0, 40)))
	end
	-- Spawn on the south side of the plaza, facing the jumbotron.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 0.4, 10)
	spawn.CFrame = CFrame.lookAt(Vector3.new(0, 0.2, 40), Vector3.new(0, 0.2, 0))
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = folder
end

local function fence(parent, center)
	-- Low rail around the plot so it reads as a court you own, with a gap toward the walkway.
	local hw = 56
	local z0, z1 = center.Z - 48, center.Z + 36
	local zc, hd = (z0 + z1) / 2, (z1 - z0) / 2
	local rail = Color3.fromRGB(46, 50, 66)
	local openZ = center.Z < 0 and z1 or z0
	local closedZ = center.Z < 0 and z0 or z1
	for _, s in ipairs({ -1, 1 }) do
		part(parent, { Name = "Rail", Size = Vector3.new(0.4, 3.2, hd * 2), Position = Vector3.new(center.X + s * hw, 1.6, zc), Color = rail, Material = Enum.Material.Metal })
		part(parent, { Name = "Rail", Size = Vector3.new(hw - 10, 3.2, 0.4), Position = Vector3.new(center.X + s * (hw + 10) / 2, 1.6, openZ), Color = rail, Material = Enum.Material.Metal })
	end
	part(parent, { Name = "Rail", Size = Vector3.new(hw * 2, 3.2, 0.4), Position = Vector3.new(center.X, 1.6, closedZ), Color = rail, Material = Enum.Material.Metal })
	-- Court lights on the corners.
	for _, sx in ipairs({ -1, 1 }) do
		for _, z in ipairs({ z0 + 2, z1 - 2 }) do
			local p = Vector3.new(center.X + sx * (hw - 2), 0, z)
			part(parent, { Name = "LightPole", Size = Vector3.new(0.8, 26, 0.8), Position = p + Vector3.new(0, 13, 0), Color = rail, Material = Enum.Material.Metal })
			local head = part(parent, { Name = "LightHead", Size = Vector3.new(4, 1.6, 1), CFrame = CFrame.lookAt(p + Vector3.new(0, 26, 0), center), Color = Color3.fromRGB(255, 250, 235), Material = Enum.Material.Neon })
			local l = Instance.new("SpotLight")
			l.Range = 60
			l.Angle = 70
			l.Brightness = 1.2
			l.Face = Enum.NormalId.Front
			l.Parent = head
		end
	end
end

local function buildPlot(folder, i, center)
	local plot = Instance.new("Model")
	plot.Name = "Plot" .. i
	local court = Court.build({ home = NEUTRAL, away = NEUTRAL })
	court:PivotTo(CFrame.new(center + Vector3.new(0, 0.5, 0)))
	court.Parent = plot
	fence(plot, center)
	-- Name board up behind the stands, so it reads in the background of the match camera and
	-- from the walkway. Text on both faces.
	local signPos = center + Vector3.new(0, 14, -47)
	local board = part(plot, { Name = "NameBoard", Size = Vector3.new(30, 6, 0.6), Position = signPos, Color = INK })
	for _, x in ipairs({ -13, 13 }) do
		local h = signPos.Y - center.Y
		part(plot, { Name = "Post", Size = Vector3.new(0.6, h, 0.6), Position = Vector3.new(signPos.X + x, center.Y + h / 2, signPos.Z), Color = Color3.fromRGB(60, 66, 90) })
	end
	signText(board, Enum.NormalId.Back, "OPEN COURT").Name = "OwnerText"
	signText(board, Enum.NormalId.Front, "OPEN COURT").Name = "OwnerText"
	plot:SetAttribute("Index", i)
	plot:SetAttribute("Owner", 0)
	plot.Parent = folder
	return plot
end

local function scenery(folder)
	local trees = Instance.new("Folder")
	trees.Name = "Trees"
	trees.Parent = folder
	local rnd = LobbyDecor.rnd
	-- Between the court plots and at the row ends.
	for _, z in ipairs({ ROW_Z.north, ROW_Z.south }) do
		for _, x in ipairs({ -260, -130, 0, 130, 260 }) do
			for k = -1, 1 do
				LobbyDecor.tree(trees, Vector3.new(x + rnd(-4, 4), 0, z + k * 26 + rnd(-4, 4)))
			end
		end
	end
	-- A loose ring around the plaza, leaving the walkways and storefronts clear.
	for k = 0, 23 do
		local a = (k + 0.5) / 24 * math.pi * 2
		local deg = math.deg(a) % 360
		local nearShop = false
		for _, s in ipairs(LobbyWorld.Stations) do
			local d = math.abs(((deg - s.angle) + 180) % 360 - 180)
			if d < 14 then
				nearShop = true
			end
		end
		local nearWalk = math.abs(math.cos(a)) < 0.16
		if not nearShop and not nearWalk then
			local r = SHOP_R + rnd(-6, 10)
			LobbyDecor.tree(trees, Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
		end
	end
	-- The outer edge, in front of the hills.
	for x = -300, 300, 24 do
		for _, z in ipairs({ -232, 232 }) do
			-- Every other tree on the outer edge is a pine, when the pine model exists.
			local pos = Vector3.new(x + rnd(-6, 6), 0, z + rnd(-8, 8))
			if (x // 24) % 2 == 0 or not LobbyDecor.prop(trees, "Pine", CFrame.new(pos) * CFrame.Angles(0, rnd(0, 6.28), 0), rnd(1.0, 1.4)) then
				LobbyDecor.tree(trees, pos, rnd(1.1, 1.6))
			end
		end
	end
	for z = -208, 208, 24 do
		for _, x in ipairs({ -300, 300 }) do
			LobbyDecor.tree(trees, Vector3.new(x + rnd(-8, 8), 0, z + rnd(-6, 6)), rnd(1.1, 1.6))
		end
	end
end

function LobbyWorld.build()
	local old = workspace:FindFirstChild("Lobby")
	if old then
		old:Destroy()
	end
	for _, name in ipairs({ "Court", "Baseplate", "SpawnLocation" }) do
		local x = workspace:FindFirstChild(name)
		if x then
			x:Destroy()
		end
	end
	LobbyDecor.terrain({ X = 340, Z = 260, pond = Vector3.new(-135, 0, 45) })
	LobbyDecor.lighting()
	-- No grass under the plaza, storefronts, walkways and courts.
	LobbyDecor.clearGrassDisc(Vector3.zero, SHOP_R + 16)
	for _, rowZ in ipairs({ ROW_Z.north, ROW_Z.south }) do
		local wz = rowWalkZ(rowZ)
		LobbyDecor.clearGrassBlock(Vector3.new(0, 0, wz), Vector3.new(504, 0, 16))
		LobbyDecor.clearGrassBlock(Vector3.new(0, 0, wz / 2), Vector3.new(20, 0, math.abs(wz)))
	end
	for _, c in ipairs(LobbyWorld.PlotCenters) do
		LobbyDecor.clearGrassBlock(Vector3.new(c.X, 0, c.Z - 6), Vector3.new(116, 0, 88))
	end
	local folder = Instance.new("Folder")
	folder.Name = "Lobby"
	buildPlaza(folder)
	local plots = Instance.new("Folder")
	plots.Name = "Plots"
	plots.Parent = folder
	for i, c in ipairs(LobbyWorld.PlotCenters) do
		buildPlot(plots, i, c)
	end
	scenery(folder)
	folder.Parent = workspace
	LobbyWorld.folder = folder
	return folder
end

local function plotOf(i)
	return LobbyWorld.folder.Plots:FindFirstChild("Plot" .. i)
end

local function paint(plot, color, text)
	for _, p in ipairs(plot.Court:GetChildren()) do
		if p.Name == "Paint" then
			p.Color = color
		end
	end
	local board = plot:FindFirstChild("NameBoard")
	for _, g in ipairs(board and board:GetChildren() or {}) do
		local label = g:IsA("SurfaceGui") and g:FindFirstChild("OwnerText")
		if label then
			label.Text = text
		end
	end
end

function LobbyWorld.colorFor(player)
	return PALETTE[player.UserId % #PALETTE + 1]
end

-- Give a player the first free plot. Returns the plot index (or nil when all 8 are taken).
function LobbyWorld.claim(player, clubName)
	for i = 1, #LobbyWorld.PlotCenters do
		local plot = plotOf(i)
		if plot and plot:GetAttribute("Owner") == 0 then
			plot:SetAttribute("Owner", player.UserId)
			player:SetAttribute("Plot", i)
			paint(plot, LobbyWorld.colorFor(player), string.upper(clubName or (player.DisplayName .. "'s Club")) .. "  HOME COURT")
			return i
		end
	end
	return nil
end

function LobbyWorld.release(player)
	local i = player:GetAttribute("Plot")
	local plot = i and plotOf(i)
	if plot and plot:GetAttribute("Owner") == player.UserId then
		plot:SetAttribute("Owner", 0)
		paint(plot, NEUTRAL, "OPEN COURT")
	end
end

function LobbyWorld.start(getClubName)
	LobbyWorld.build()
	local function join(player)
		LobbyWorld.claim(player, getClubName and getClubName(player))
	end
	Players.PlayerAdded:Connect(join)
	for _, p in ipairs(Players:GetPlayers()) do
		join(p)
	end
	Players.PlayerRemoving:Connect(LobbyWorld.release)
end

return LobbyWorld
