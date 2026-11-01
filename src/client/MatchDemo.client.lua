--!nonstrict
-- Match demo: two generated teams playing possessions on the 3D court, side-on camera, a score
-- bug, shot feedback text and the rim flash on dunks. It is the playtest bed for the match view.
-- Runs only in Studio playtests, or when workspace has the attribute MatchDemo = true.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

if not (RunService:IsStudio() or workspace:GetAttribute("MatchDemo")) then
	return
end

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AnimClips = require(Shared.AnimClips)
local AnimSets = require(Shared.AnimSets)
local Court = require(Shared.Court)
local CourtView = require(Shared.CourtView)
local PlayerFactory = require(Shared.PlayerFactory)
local PlayerModel = require(Shared.PlayerModel)
local Possession = require(Shared.Possession)
local Rng = require(Shared.Rng)
local ShotFeel = require(Shared.ShotFeel)
local Audio = require(script.Parent:WaitForChild("Audio"))

local ORIGIN = Vector3.new(0, 0, 400) -- away from the lobby
local HOME = { jersey = Color3.fromRGB(37, 99, 235), shorts = Color3.fromRGB(30, 80, 200), trim = Color3.new(1, 1, 1), name = "HOME" }
local AWAY = { jersey = Color3.fromRGB(232, 69, 107), shorts = Color3.fromRGB(190, 50, 90), trim = Color3.new(1, 1, 1), name = "AWAY" }
local NUMBERS = { { 1, 3, 23, 8, 34 }, { 0, 5, 21, 4, 12 } }

local rng = Rng.new(os.time())
local folder = Instance.new("Folder")
folder.Name = "MatchDemo"
folder.Parent = workspace

local court = Court.build({ home = HOME.jersey, away = AWAY.jersey })
court:PivotTo(CFrame.new(ORIGIN + Vector3.new(0, 0.5, 0)))
court.Parent = folder

-- Teams: starter-level players, with flashier signature sets so the demo shows every package.
local teams, bodies = {}, {}
for side, kit in ipairs({ HOME, AWAY }) do
	local roster = PlayerFactory.starterRoster(rng:int(1, 1e6))
	teams[side] = {}
	for i = 1, 5 do
		local p = roster[i]
		p.anims = AnimSets.roll(rng, "Legendary", PlayerFactory.archetype(p))
		teams[side][i] = p
		local body = PlayerModel.build(p, { jersey = kit.jersey, shorts = kit.shorts, trim = kit.trim, number = NUMBERS[side][i] })
		body.Name = kit.name .. i
		body:PivotTo(CFrame.new(ORIGIN + Vector3.new(0, 6, 0)))
		body.Parent = folder
		table.insert(bodies, body)
	end
end

local ball = Instance.new("Part")
ball.Name = "Ball"
ball.Shape = Enum.PartType.Ball
ball.Size = Vector3.one * 1.28
ball.Color = Color3.fromRGB(230, 110, 30)
ball.Material = Enum.Material.SmoothPlastic
ball.Anchored, ball.CanCollide = true, false
ball.Parent = folder

local view = CourtView.new({ court = court, bodies = bodies, ball = ball })

-- UI: score bug and the shot feedback line.
local gui = Instance.new("ScreenGui")
gui.Name = "MatchDemoUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local bug = Instance.new("TextLabel")
bug.AnchorPoint = Vector2.new(0.5, 0)
bug.Position = UDim2.new(0.5, 0, 0, 52)
bug.Size = UDim2.fromOffset(240, 40)
bug.BackgroundColor3 = Color3.fromRGB(20, 24, 48)
bug.BackgroundTransparency = 0.15
bug.TextColor3 = Color3.new(1, 1, 1)
bug.Font = Enum.Font.GothamBlack
bug.TextSize = 22
bug.Parent = gui
Instance.new("UICorner", bug).CornerRadius = UDim.new(0, 10)

local callout = Instance.new("TextLabel")
callout.AnchorPoint = Vector2.new(0.5, 0.5)
callout.Position = UDim2.fromScale(0.5, 0.3)
callout.Size = UDim2.fromOffset(420, 60)
callout.BackgroundTransparency = 1
callout.TextColor3 = Color3.fromRGB(255, 200, 60)
callout.TextStrokeTransparency = 0.3
callout.Font = Enum.Font.GothamBlack
callout.TextSize = 40
callout.TextTransparency = 1
callout.TextStrokeTransparency = 1
callout.Parent = gui
local scale = Instance.new("UIScale", callout)

local score = { 0, 0 }
local function drawScore()
	bug.Text = string.format("HOME  %d   –   %d  AWAY", score[1], score[2])
end
drawScore()

local function pop(text: string, color: Color3)
	callout.Text = text
	callout.TextColor3 = color
	callout.TextTransparency, callout.TextStrokeTransparency = 0, 0.3
	scale.Scale = 0.6
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(1.1, function()
		TweenService:Create(callout, TweenInfo.new(0.35), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end)
end

-- Dunk rim flash: the rim glows white-hot for a moment.
local function flashRim(dir: number)
	local hoop = court:FindFirstChild(dir > 0 and "HoopRight" or "HoopLeft")
	for _, part in ipairs(hoop:GetChildren()) do
		if part.Name == "Rim" then
			local base = part.Color
			part.Color = Color3.fromRGB(255, 245, 210)
			part.Material = Enum.Material.Neon
			task.delay(0.25, function()
				part.Material = Enum.Material.Metal
				TweenService:Create(part, TweenInfo.new(0.4), { Color = base }):Play()
			end)
		end
	end
end

-- When the ball leaves the hand in a shot clip (the key before it reaches the rim).
local function releaseTime(clipName: string): number
	local keys = AnimClips.Clips[clipName].ball or {}
	for i = 2, #keys do
		if keys[i][2] == "rim" then
			return keys[i - 1][1]
		end
	end
	return 0.7
end

-- Side-on camera that follows the ball along the court.
local camera = workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Scriptable
local camX = ORIGIN.X
RunService:BindToRenderStep("MatchDemoCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local target = ORIGIN.X + math.clamp(ball.Position.X - ORIGIN.X, -24, 24) * 0.8
	camX += (target - camX) * math.min(1, dt * 2.5)
	camera.CameraType = Enum.CameraType.Scriptable -- the default camera script resets it on spawn
	camera.CFrame = CFrame.lookAt(Vector3.new(camX, 15, ORIGIN.Z + 46), Vector3.new(camX, 4, ORIGIN.Z))
end)

local function play(homeBall: boolean)
	local side = homeBall and 1 or 2
	local team = teams[side]
	local offense = {}
	for i = 1, 5 do
		offense[i] = AnimSets.clips(team[i].anims)
	end
	local kind = rng:weighted({ { "jumper", 40 }, { "three", 35 }, { "dunk", 25 } })
	local shooter = kind == "dunk" and rng:int(2, 5) or rng:int(1, 5)
	local assist = rng:chance(0.65) and rng:int(1, 5) or nil
	if assist == shooter then
		assist = nil
	end
	local rating = ShotFeel.rating(team[shooter], kind)
	local base = ({ jumper = 0.45, three = 0.37, dunk = 0.8 })[kind]
	local made = rng:chance(math.clamp(base + (rating - 70) * 0.006, 0.05, 0.98))
	-- Misses get a rebound: about one in four is an offensive board by a big.
	local rebounder = nil
	if not made and kind ~= "dunk" then
		rebounder = rng:chance(0.25) and rng:int(4, 5) or rng:int(9, 10)
		if rebounder == shooter or rebounder == shooter + 5 then
			rebounder = rebounder == 10 and 9 or (rebounder == 5 and 4 or rebounder)
		end
	end
	local plan = Possession.plan({ offense = offense, dir = homeBall and 1 or -1, result = { kind = kind, shooter = shooter, assist = assist, made = made, rebounder = rebounder } })
	local clip = AnimClips.Clips[plan.shotClip]
	if kind == "dunk" and not made then
		task.delay(plan.block.tBlock, function()
			pop(rng:pick({ "REJECTED!", "GET THAT OUT!", "DENIED!" }), Color3.fromRGB(150, 200, 255))
		end)
	elseif kind == "dunk" then
		task.delay(plan.tShot + clip.hoopAt[1], function()
			flashRim(plan.dir)
			pop(rng:pick({ "SLAM!", "POSTER!", "BOOM!" }), Color3.fromRGB(255, 120, 60))
			score[side] += 2
			drawScore()
		end)
	else
		local feel = ShotFeel.release(rng, made, rating)
		task.delay(plan.tShot + releaseTime(plan.shotClip), function()
			pop(ShotFeel.Text[feel], Color3.fromRGB(table.unpack(ShotFeel.Color[feel])))
		end)
		if made then
			task.delay(plan.tShot + 1.8, function()
				score[side] += kind == "three" and 3 or 2
				drawScore()
			end)
		end
	end
	if plan.rebound then
		task.delay(plan.rebound.tCatch, function()
			pop(plan.rebound.who <= 5 and "OFFENSIVE BOARD" or "REBOUND", Color3.fromRGB(150, 200, 255))
		end)
	end
	view:play(plan, homeBall, function(ev)
		Audio.play(ev, ball)
	end)
	return plan.rebound ~= nil and plan.rebound.who <= 5
end

task.wait(1)
local homeBall = true
while folder.Parent do
	local keep = play(homeBall)
	if not keep then
		homeBall = not homeBall
	end
	task.wait(0.6)
end
