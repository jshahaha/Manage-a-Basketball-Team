--!nonstrict
-- The lobby: a central plaza with stations, and 8 Home Court plots in two rows (north and
-- south). Each manager gets a plot when they join; it takes their colors and name, and their
-- PLAY matches are acted out on it. Everything is built in code so it lives in the repo.
--
-- Courts stay aligned with the X axis because the match view and the side-on camera work in
-- world X/Z (see CourtView).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Court = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Court"))

local LobbyWorld = {}

LobbyWorld.PlotCenters = {
	Vector3.new(-180, 0, -100), Vector3.new(-60, 0, -100), Vector3.new(60, 0, -100), Vector3.new(180, 0, -100),
	Vector3.new(-180, 0, 100), Vector3.new(-60, 0, 100), Vector3.new(60, 0, 100), Vector3.new(180, 0, 100),
}

-- Station id, sign, prompt text, awning colour. The client opens the screen named by `id`.
LobbyWorld.Stations = {
	{ id = "Shop", name = "PACK SHOP", action = "Open Shop", color = Color3.fromHex("e8650c") },
	{ id = "Quests", name = "QUEST BOARD", action = "View Quests", color = Color3.fromHex("1f9e3f") },
	{ id = "Club", name = "LOCKER ROOM", action = "Manage Club", color = Color3.fromHex("2e6fd8") },
	{ id = "Scout", name = "SCOUT OFFICE", action = "Scouting", color = Color3.fromHex("7a4fd8") },
	{ id = "Trade", name = "TRADE BOARD", action = "Trading", color = Color3.fromHex("e8456b") },
	{ id = "HallOfFame", name = "HALL OF FAME", action = "Leaderboards", color = Color3.fromHex("b98a00") },
}

-- Club colours until club creation exists: picked from the user id so they stay the same.
local PALETTE = {
	Color3.fromRGB(37, 99, 235), Color3.fromRGB(232, 69, 107), Color3.fromRGB(31, 158, 63), Color3.fromRGB(232, 101, 12),
	Color3.fromRGB(130, 70, 220), Color3.fromRGB(0, 150, 160), Color3.fromRGB(200, 160, 0), Color3.fromRGB(20, 24, 48),
}
local NEUTRAL = Color3.fromRGB(150, 156, 170)

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
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.Text = text
	l.Parent = g
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0.05, 0), UDim.new(0.05, 0)
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0.1, 0), UDim.new(0.1, 0)
	pad.Parent = l
	if size then
		local c = Instance.new("UITextSizeConstraint")
		c.MaxTextSize = size
		c.Parent = l
	end
	return l
end

-- A booth facing the plaza centre.
local function station(parent, info, pos)
	local m = Instance.new("Model")
	m.Name = info.id
	local look = CFrame.lookAt(pos, Vector3.new(0, pos.Y, 0)) -- -Z of this frame faces the centre
	local function at(x, y, z)
		return look * CFrame.new(x, y, z)
	end
	part(m, { Name = "Base", Size = Vector3.new(14, 0.6, 9), CFrame = at(0, 0.3, 0), Color = Color3.fromRGB(235, 238, 245) })
	part(m, { Name = "Counter", Size = Vector3.new(11, 3.4, 2), CFrame = at(0, 2.3, -2.5), Color = Color3.new(1, 1, 1) })
	part(m, { Name = "CounterStripe", Size = Vector3.new(11.05, 0.8, 2.05), CFrame = at(0, 3.2, -2.5), Color = info.color })
	part(m, { Name = "Back", Size = Vector3.new(13, 9, 0.6), CFrame = at(0, 5.1, 3.6), Color = Color3.fromRGB(245, 246, 250) })
	for _, x in ipairs({ -6.3, 6.3 }) do
		part(m, { Name = "Post", Size = Vector3.new(0.6, 9, 0.6), CFrame = at(x, 5.1, -3.8), Color = Color3.fromRGB(60, 66, 90) })
	end
	local awning = part(m, { Name = "Awning", Size = Vector3.new(14.5, 0.5, 9.5), CFrame = at(0, 9.8, -0.2) * CFrame.Angles(math.rad(-8), 0, 0), Color = info.color })
	local sign = part(m, { Name = "Sign", Size = Vector3.new(12, 2.6, 0.4), CFrame = at(0, 11.6, -4.2), Color = Color3.fromHex("1b2140") })
	signText(sign, Enum.NormalId.Front, info.name)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = info.action
	prompt.ObjectText = info.name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Station", info.id)
	prompt.Parent = m:FindFirstChild("Counter")
	m.PrimaryPart = m:FindFirstChild("Base")
	m.Parent = parent
	return m, awning
end

local function buildPlaza(folder)
	local plaza = Instance.new("Model")
	plaza.Name = "Plaza"
	part(plaza, { Name = "Ground", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 104, 104), CFrame = CFrame.new(0, -0.45, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(226, 230, 238), Material = Enum.Material.Concrete })
	part(plaza, { Name = "Ring", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 40, 40), CFrame = CFrame.new(0, -0.4, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromHex("2e6fd8"), Material = Enum.Material.SmoothPlastic })
	part(plaza, { Name = "Center", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 34, 34), CFrame = CFrame.new(0, -0.35, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(214, 160, 100), Material = Enum.Material.WoodPlanks })
	-- Centrepiece: a giant ball on a plinth.
	part(plaza, { Name = "Plinth", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 10, 10), CFrame = CFrame.new(0, 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromHex("1b2140") })
	part(plaza, { Name = "BigBall", Shape = Enum.PartType.Ball, Size = Vector3.one * 8, Position = Vector3.new(0, 7, 0), Color = Color3.fromRGB(230, 110, 30), Material = Enum.Material.SmoothPlastic })
	-- Walkways out to the two rows of courts.
	for _, z in ipairs({ -1, 1 }) do
		part(plaza, { Name = "Walk", Size = Vector3.new(420, 0.9, 10), Position = Vector3.new(0, -0.38, z * 40), Color = Color3.fromRGB(200, 205, 216), Material = Enum.Material.Concrete })
	end
	plaza.Parent = folder
	local stations = Instance.new("Folder")
	stations.Name = "Stations"
	stations.Parent = folder
	local n = #LobbyWorld.Stations
	for i, info in ipairs(LobbyWorld.Stations) do
		-- Spread around the plaza, leaving gaps toward the north and south walkways.
		local angles = { -35, 0, 35, 145, 180, 215 }
		local a = math.rad(angles[i] or (i / n * 360))
		station(stations, info, Vector3.new(math.cos(a) * 40, 0, math.sin(a) * 40))
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 0.4, 8)
	spawn.Position = Vector3.new(0, 0.2, 18)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = folder
end

local function buildPlot(folder, i, center)
	local plot = Instance.new("Model")
	plot.Name = "Plot" .. i
	local court = Court.build({ home = NEUTRAL, away = NEUTRAL })
	court:PivotTo(CFrame.new(center + Vector3.new(0, 0.5, 0)))
	court.Parent = plot
	-- Name board up behind the stands, so it reads in the background of the match camera and
	-- from the plaza. Text on both faces.
	local signPos = center + Vector3.new(0, 14, -(Court.Width / 2 + 26))
	local board = part(plot, { Name = "NameBoard", Size = Vector3.new(30, 6, 0.6), Position = signPos, Color = Color3.fromHex("1b2140") })
	for _, x in ipairs({ -13, 13 }) do
		local h = signPos.Y - center.Y
		part(plot, { Name = "Post", Size = Vector3.new(0.6, h, 0.6), Position = Vector3.new(signPos.X + x, center.Y + h / 2, signPos.Z), Color = Color3.fromRGB(60, 66, 90) })
	end
	signText(board, Enum.NormalId.Back, "OPEN COURT").Name = "OwnerText"
	local label = signText(board, Enum.NormalId.Front, "OPEN COURT")
	label.Name = "OwnerText"
	plot:SetAttribute("Index", i)
	plot:SetAttribute("Owner", 0)
	plot.Parent = folder
	return plot
end

function LobbyWorld.build()
	local old = workspace:FindFirstChild("Lobby")
	if old then
		old:Destroy()
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
	folder.Parent = workspace
	LobbyWorld.folder = folder
	-- The template baseplate and the old floating court only get in the way now.
	for _, name in ipairs({ "Court" }) do
		local x = workspace:FindFirstChild(name)
		if x and x:IsA("Model") then
			x:Destroy()
		end
	end
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
