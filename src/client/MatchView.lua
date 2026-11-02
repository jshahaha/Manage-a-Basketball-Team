--!nonstrict
-- Plays a finished PLAY match on the 3D court. The server already decided every possession
-- (MatchSim); this acts the game out in about the queued length: each quarter shows its key plays
-- in full on the court, and the rest tick by on the scoreboard and the play-by-play line.
--
--   MatchView.run(data)  -- data from the playMatch route; yields until the player taps Continue

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AnimClips = require(Shared.AnimClips)
local AnimSets = require(Shared.AnimSets)
local Court = require(Shared.Court)
local CourtView = require(Shared.CourtView)
local MatchSim = require(Shared.MatchSim)
local PlayerModel = require(Shared.PlayerModel)
local PoseSolver = require(Shared.PoseSolver)
local Possession = require(Shared.Possession)
local Rng = require(Shared.Rng)
local ShotFeel = require(Shared.ShotFeel)
local Audio = require(script.Parent:WaitForChild("Audio"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local T = Theme.C

local MatchView = {}

local ORIGIN = Vector3.new(0, 0, 400)
local HOME_KIT = Color3.fromRGB(37, 99, 235)
local NUMBERS = { 1, 3, 23, 8, 34, 0, 5, 21, 4, 12 }
local INK = Theme.C.slate
local WHITE = Color3.new(1, 1, 1)

local function shortName(name)
	name = tostring(name or "")
	local first = name:match("^(%S+)") or name
	local last = name:match("(%S+)$") or name
	if first == last then
		return name
	end
	return first:sub(1, 1) .. ". " .. last
end

local function releaseTime(clipName)
	local keys = AnimClips.Clips[clipName].ball or {}
	for i = 2, #keys do
		if keys[i][2] == "rim" then
			return keys[i - 1][1]
		end
	end
	return 0.7
end

local function darker(c, k)
	return Color3.new(c.R * k, c.G * k, c.B * k)
end

-- Text for the play-by-play line.
local function describe(ev, names)
	local who = names[ev.team][ev.onCourt[ev.team][ev.slot]] or "?"
	local other = 3 - ev.team
	if ev.kind == "turnover" then
		if ev.stealer then
			return string.format("%s steals it from %s", names[other][ev.onCourt[other][ev.stealer - 5]], who)
		end
		return who .. " turns it over"
	elseif ev.kind == "freeThrows" then
		return string.format("%s makes %d of 2 at the line", who, ev.ftm or 0)
	end
	local what = ({ three = "three", jumper = "jumper", dunk = ev.slam and "dunk" or "drive" })[ev.kind]
	local s
	if ev.made then
		s = string.format("%s hits the %s", who, what)
		if ev.assist then
			s ..= string.format(" (%s assist)", names[ev.team][ev.onCourt[ev.team][ev.assist]])
		end
	elseif ev.blocker then
		s = string.format("%s blocks %s", names[other][ev.onCourt[other][ev.blocker - 5]], who)
	else
		s = string.format("%s misses the %s", who, what)
		if ev.rebounder then
			local side = ev.rebounder <= 5 and ev.team or other
			local slot = ev.rebounder <= 5 and ev.rebounder or ev.rebounder - 5
			s ..= string.format(", %s rebound", names[side][ev.onCourt[side][slot]])
		end
	end
	return s
end

-- How much a play is worth showing in full.
local function interest(ev)
	if not MatchSim.planResult(ev) then
		return 0
	end
	local v = 1
	if ev.kind == "dunk" and ev.made then
		v += 3
	end
	if ev.blocker then
		v += 3
	end
	if ev.kind == "three" and ev.made then
		v += 2
	end
	if ev.assist then
		v += 0.5
	end
	return v
end

function MatchView.run(data)
	local player = Players.LocalPlayer
	local rng = Rng.new(os.time())
	local folder = Instance.new("Folder")
	folder.Name = "Match"
	folder.Parent = workspace

	local awayKit = data.away.kit and Color3.fromRGB(table.unpack(data.away.kit)) or Color3.fromRGB(232, 69, 107)
	if (Vector3.new(awayKit.R, awayKit.G, awayKit.B) - Vector3.new(HOME_KIT.R, HOME_KIT.G, HOME_KIT.B)).Magnitude < 0.25 then
		awayKit = Color3.fromRGB(232, 69, 107)
	end
	local kits = { HOME_KIT, awayKit }

	-- Your Home Court in the lobby when you have one; otherwise a court of our own off to the side.
	local lobbyPlot = data.plot and workspace:FindFirstChild("Lobby") and workspace.Lobby.Plots:FindFirstChild("Plot" .. data.plot)
	local court
	local paintBefore = {}
	if lobbyPlot then
		court = lobbyPlot.Court
		for _, p in ipairs(court:GetChildren()) do
			if p.Name == "Paint" then
				paintBefore[p] = p.Color
				p.Color = p.Position.X > court.Floor.Position.X and HOME_KIT or awayKit
			end
		end
	else
		court = Court.build({ home = HOME_KIT, away = awayKit })
		court:PivotTo(CFrame.new(Vector3.new(0, 0, 400) + Vector3.new(0, 0.5, 0)))
		court.Parent = folder
	end
	local floor = court:FindFirstChild("Floor")
	ORIGIN = Vector3.new(floor.Position.X, 0, floor.Position.Z)
	-- Stand your avatar courtside, on the camera side.
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		local spot = Vector3.new(ORIGIN.X + 6, floor.Position.Y + 4, ORIGIN.Z + Court.Width / 2 + 6)
		char:PivotTo(CFrame.lookAt(spot, Vector3.new(ORIGIN.X, spot.Y, ORIGIN.Z)))
	end
	local floorY = floor.Position.Y + floor.Size.Y / 2

	-- All twenty players. Whoever isn't on the floor waits on the bench across the court.
	local bodies, S, names, sets = { {}, {} }, { {}, {} }, { {}, {} }, { {}, {} }
	for side, team in ipairs({ data.home, data.away }) do
		for i, card in ipairs(team.players) do
			local kit = kits[side]
			local body = PlayerModel.build(card, { jersey = kit, shorts = darker(kit, 0.85), trim = WHITE, number = NUMBERS[i] })
			body.Name = (side == 1 and "Home" or "Away") .. i
			local hum = body:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			end
			body.Parent = folder
			bodies[side][i] = body
			S[side][i] = PoseSolver.setup(body)
			names[side][i] = shortName(card.name)
			sets[side][i] = AnimSets.clips(card.anims or AnimSets.roll(rng, card.rarity or "Common", card.archetype))
		end
	end
	local function bench(side, i)
		local x = (side == 1 and -1 or 1) * (6 + i * 3)
		local place = PoseSolver.place(S[side][i], AnimClips.Clips.Idle, ORIGIN.X + x, ORIGIN.Z - Court.Width / 2 - 5, floorY, 0)
		PoseSolver.pose(S[side][i], "Idle", 0, place)
	end

	local ball = Instance.new("Part")
	ball.Name = "Ball"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.one * 1.28
	ball.Color = Color3.fromRGB(230, 110, 30)
	ball.Material = Enum.Material.SmoothPlastic
	ball.Anchored, ball.CanCollide = true, false
	ball.Parent = folder

	-- The view for one lineup (rebuilt when the five on the floor change).
	local view, viewKey
	local function viewFor(ev)
		local key = table.concat(ev.onCourt[1], ",") .. "|" .. table.concat(ev.onCourt[2], ",")
		if key ~= viewKey then
			local list, solvers, on = {}, {}, { {}, {} }
			for side = 1, 2 do
				for s = 1, 5 do
					local i = ev.onCourt[side][s]
					table.insert(list, bodies[side][i])
					table.insert(solvers, S[side][i])
					on[side][i] = true
				end
				for i = 1, #bodies[side] do
					if not on[side][i] then
						bench(side, i)
					end
				end
			end
			view = CourtView.new({ court = court, bodies = list, ball = ball, S = solvers })
			viewKey = key
		end
		return view
	end

	-- Tip-off: the first five of each side stand around the centre circle.
	if data.events[1] then
		viewFor(data.events[1])
		for side = 1, 2 do
			for s = 1, 5 do
				local i = data.events[1].onCourt[side][s]
				local x = (side == 1 and -1 or 1) * (2 + (s - 1) * 4)
				local z = (s % 2 == 0 and 1 or -1) * (s - 1) * 2
				local place = PoseSolver.place(S[side][i], AnimClips.Clips.Idle, ORIGIN.X + x, ORIGIN.Z + z, floorY, side == 1 and 90 or -90)
				PoseSolver.pose(S[side][i], "Idle", 0, place)
			end
		end
		ball.Position = Vector3.new(ORIGIN.X, floorY + 6, ORIGIN.Z)
	end

	-- HUD -------------------------------------------------------------------------------------
	-- Hide the lobby screens (Lobby, Codes...) for the match and bring them back after.
	local hidden = {}
	for _, g in ipairs(player:WaitForChild("PlayerGui"):GetChildren()) do
		if g:IsA("ScreenGui") and g.Enabled then
			g.Enabled = false
			table.insert(hidden, g)
		end
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "MatchUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 10
	gui.Parent = player:WaitForChild("PlayerGui")

	local bug = Instance.new("Frame")
	bug.AnchorPoint = Vector2.new(0.5, 0)
	bug.Position = UDim2.new(0.5, 0, 0, 48)
	bug.Size = UDim2.fromOffset(440, 44)
	bug.BackgroundColor3 = INK
	bug.BackgroundTransparency = 0.05
	bug.Parent = gui
	Instance.new("UICorner", bug).CornerRadius = UDim.new(0, 4)
	Theme.stroke(bug, 3, T.black)
	local function cell(x, w, color)
		local l = Instance.new("TextLabel")
		l.BackgroundColor3 = color or INK
		l.BackgroundTransparency = color and 0 or 1
		l.Position = UDim2.fromOffset(x, 0)
		l.Size = UDim2.fromOffset(w, 44)
		l.FontFace = Theme.HEAD
		l.TextColor3 = color and Theme.textOn(color) or T.ink
		l.TextSize = 22
		l.TextScaled = false
		l.TextTruncate = Enum.TextTruncate.AtEnd
		l.Parent = bug
		return l
	end
	local function teamTag(name)
		return string.upper(name)
	end
	local homeName = cell(0, 130, kits[1])
	homeName.Text = teamTag(data.home.name)
	homeName.TextScaled = true
	local homePts = cell(130, 50)
	local clockL = cell(180, 80)
	clockL.TextSize = 17
	clockL.TextColor3 = T.black
	clockL.BackgroundColor3 = T.yellow -- clock on a strip of yellow tape
	clockL.BackgroundTransparency = 0
	clockL.Size = UDim2.fromOffset(80, 34)
	clockL.Position = UDim2.fromOffset(180, 5)
	clockL.Rotation = -2
	local awayPts = cell(260, 50)
	local awayName = cell(310, 130, kits[2])
	awayName.Text = teamTag(data.away.name)
	awayName.TextScaled = true
	for _, l in ipairs({ homeName, awayName }) do
		Instance.new("UITextSizeConstraint", l).MaxTextSize = 18
		local pad = Instance.new("UIPadding", l)
		pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 6), UDim.new(0, 6)
	end
	Instance.new("UICorner", homeName).CornerRadius = UDim.new(0, 4)
	Instance.new("UICorner", awayName).CornerRadius = UDim.new(0, 4)

	local ticker = Instance.new("TextLabel")
	ticker.AnchorPoint = Vector2.new(0.5, 1)
	ticker.Position = UDim2.new(0.5, 0, 1, -20)
	ticker.Size = UDim2.new(0.9, 0, 0, 36)
	ticker.BackgroundColor3 = INK
	ticker.BackgroundTransparency = 0.1
	ticker.TextColor3 = T.ink
	ticker.FontFace = Theme.HEAD
	ticker.TextSize = 19
	ticker.Text = ""
	ticker.Parent = gui
	Instance.new("UICorner", ticker).CornerRadius = UDim.new(0, 4)
	Theme.stroke(ticker, 3, T.yellow)
	Instance.new("UISizeConstraint", ticker).MaxSize = Vector2.new(620, 36)

	local callout = Instance.new("TextLabel")
	callout.AnchorPoint = Vector2.new(0.5, 0.5)
	callout.Position = UDim2.fromScale(0.5, 0.3)
	callout.Size = UDim2.fromOffset(460, 60)
	callout.BackgroundTransparency = 1
	callout.FontFace = Theme.MARK
	callout.TextSize = 48
	callout.TextStrokeColor3 = T.black
	callout.Rotation = -4
	callout.TextTransparency, callout.TextStrokeTransparency = 1, 1
	callout.Parent = gui
	local popScale = Instance.new("UIScale", callout)
	local function pop(text, color)
		callout.Text = text
		callout.TextColor3 = color
		callout.TextTransparency, callout.TextStrokeTransparency = 0, 0
		popScale.Scale = 0.6
		TweenService:Create(popScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		task.delay(1.1, function()
			TweenService:Create(callout, TweenInfo.new(0.35), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end)
	end

	local skipping = false
	local skip = Theme.button(gui, "SKIP", T.slate, UDim2.fromOffset(110, 46))
	skip.AnchorPoint = Vector2.new(1, 0)
	skip.Position = UDim2.new(1, -12, 0, 48)
	skip.Label.TextColor3 = T.yellow
	skip.MouseButton1Click:Connect(function()
		skipping = true
		skip.Visible = false
	end)

	local shown = { 0, 0 }
	local function drawScore(score, q, clock)
		shown = score
		homePts.Text = tostring(score[1])
		awayPts.Text = tostring(score[2])
		local qText = q <= 4 and ("Q" .. q) or (q == 5 and "OT" or ("OT" .. (q - 4)))
		clockL.Text = string.format("%s %d:%02d", qText, math.floor(clock / 60), math.floor(clock % 60))
	end
	drawScore({ 0, 0 }, 1, MatchSim.QuarterSeconds)

	local function flashRim(dir)
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

	-- Camera: side-on, following the ball.
	local camera = workspace.CurrentCamera
	local camX = ORIGIN.X
	RunService:BindToRenderStep("MatchCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
		local target = ORIGIN.X + math.clamp(ball.Position.X - ORIGIN.X, -24, 24) * 0.8
		camX += (target - camX) * math.min(1, dt * 2.5)
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.lookAt(Vector3.new(camX, 15, ORIGIN.Z + 46), Vector3.new(camX, 4, ORIGIN.Z))
	end)

	local function wait(sec)
		local t = 0
		while t < sec and not skipping do
			t += task.wait()
		end
	end

	-- One possession in full on the court.
	local function act(ev)
		local r = MatchSim.planResult(ev)
		local secondHalf = ev.q >= 3
		local dir = ((ev.team == 1) ~= secondHalf) and 1 or -1
		local v = viewFor(ev)
		local offense = {}
		for s = 1, 5 do
			offense[s] = sets[ev.team][ev.onCourt[ev.team][s]]
		end
		local plan = Possession.plan({ offense = offense, dir = dir, result = r })
		local clip = AnimClips.Clips[plan.shotClip]
		local shooterCard = (ev.team == 1 and data.home or data.away).players[ev.onCourt[ev.team][ev.slot]]
		if r.kind == "dunk" and not r.made then
			task.delay(plan.block.tBlock, function()
				pop(rng:pick({ "REJECTED!", "GET THAT OUT!", "DENIED!" }), Color3.fromRGB(150, 200, 255))
			end)
		elseif r.kind == "dunk" then
			task.delay(plan.tShot + clip.hoopAt[1], function()
				flashRim(dir)
				pop(ev.slam and rng:pick({ "SLAM!", "POSTER!", "BOOM!" }) or "AT THE RIM!", Color3.fromRGB(255, 120, 60))
			end)
		else
			local rating = shooterCard and shooterCard.ovr or 70
			local feel = ShotFeel.release(rng, r.made, rating)
			task.delay(plan.tShot + releaseTime(plan.shotClip), function()
				pop(ShotFeel.Text[feel], Color3.fromRGB(table.unpack(ShotFeel.Color[feel])))
			end)
		end
		v:play(plan, ev.team == 1, function(name)
			Audio.play(name, ball)
		end)
	end

	-- Quarters -------------------------------------------------------------------------------
	local byQuarter = {}
	for _, ev in ipairs(data.events) do
		byQuarter[ev.q] = byQuarter[ev.q] or {}
		table.insert(byQuarter[ev.q], ev)
	end
	local qSeconds = data.quarterSeconds or 45
	for q = 1, #byQuarter do
		local list = byQuarter[q]
		-- Pick the key plays: the most interesting ones, about one every 6.5 seconds of real time.
		local want = math.max(2, math.floor(qSeconds / 6.5))
		local ranked = {}
		for i, ev in ipairs(list) do
			if interest(ev) > 0 then
				table.insert(ranked, { i = i, v = interest(ev) + rng:next() })
			end
		end
		table.sort(ranked, function(a, b)
			return a.v > b.v
		end)
		local key = {}
		for k = 1, math.min(want, #ranked) do
			key[ranked[k].i] = true
		end
		local shownCount = 0
		for _ in pairs(key) do
			shownCount += 1
		end
		local tick = math.max(0.05, (qSeconds - shownCount * 6) / math.max(1, #list - shownCount))
		if not skipping then
			pop(q <= 4 and ("QUARTER " .. q) or "OVERTIME", WHITE)
			Audio.play("WhistleShort")
			wait(1.2)
		end
		for i, ev in ipairs(list) do
			if skipping then
				break
			end
			if key[i] then
				drawScore(shown, q, ev.clock + 14)
				ticker.Text = (ev.team == 1 and data.home.name or data.away.name) .. " ball"
				act(ev)
			else
				wait(tick)
			end
			drawScore(ev.score, q, ev.clock)
			ticker.Text = describe(ev, names)
			if ev.pts and ev.pts >= 2 and not key[i] then
				Audio.play("CrowdCheerS")
			end
		end
		if not skipping then
			local qs = data.quarters[q]
			pop(string.format("END OF %s  %d-%d", q <= 4 and ("Q" .. q) or "OT", qs[1], qs[2]), Color3.fromRGB(255, 200, 60))
			Audio.play("Buzzer")
			wait(q == 2 and 4 or 2.5)
		end
	end
	drawScore(data.score, #byQuarter, 0)
	skip.Visible = false

	-- Final screen ---------------------------------------------------------------------------
	local rw = data.rewards
	Audio.play(rw.won and "Victory" or "Defeat")
	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.55)
	card.Size = UDim2.fromOffset(440, 330)
	card.BackgroundColor3 = T.asphalt
	card.Parent = gui
	if not Theme.panelArt(card) then
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
		Theme.stroke(card, 4, T.black)
		Theme.asphalt(card)
	end
	local function line(text, y, size, color, font)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromOffset(16, y)
		l.Size = UDim2.new(1, -32, 0, size + 8)
		l.FontFace = font or Theme.HEAD
		l.TextSize = size
		l.TextColor3 = color or T.ink
		l.Text = text
		l.TextWrapped = true
		l.Parent = card
		return l
	end
	-- WIN / LOSS sprayed across a strip of tape.
	local tape, tapeText = Theme.tape(card, rw.won and "WIN!" or "LOSS", { anchor = Vector2.new(0.5, 0), pos = UDim2.new(0.5, 0, 0, -18), sz = UDim2.fromOffset(200, 56), rot = -3, color = rw.won and T.yellow or T.tape, size = 40, z = 3 })
	tapeText.TextColor3 = rw.won and T.black or T.red
	line(string.format("%s %d  -  %d %s", data.home.name, data.score[1], data.score[2], data.away.name), 56, 24)
	local mvpTeam = data.mvp.side == 1 and data.home or data.away
	local mvpBox = mvpTeam.box[data.mvp.index]
	line(string.format("MVP  %s  %d PTS  %d REB  %d AST", mvpTeam.players[data.mvp.index].name, mvpBox.pts, mvpBox.oreb + mvpBox.dreb, mvpBox.ast), 100, 16, T.yellow, Theme.BODY)
	-- Your top three scorers.
	local order = {}
	for i = 1, #data.home.players do
		table.insert(order, i)
	end
	table.sort(order, function(a, b)
		return data.home.box[a].pts > data.home.box[b].pts
	end)
	for k = 1, 3 do
		local i = order[k]
		local b = data.home.box[i]
		line(string.format("%s   %d pts, %d reb, %d ast", names[1][i], b.pts, b.oreb + b.dreb, b.ast), 128 + k * 24, 15, T.muted, Theme.BODY)
	end
	local sign = rw.eloDelta >= 0 and "+" or ""
	line(string.format("+%d coins    +%d fans    Elo %s%d (%d)", rw.coins, rw.fans, sign, rw.eloDelta, rw.elo), 232, 18, T.lime)
	local done = Theme.button(card, "CONTINUE", T.yellow, UDim2.fromOffset(200, 56))
	done.AnchorPoint = Vector2.new(0.5, 1)
	done.Position = UDim2.new(0.5, 0, 1, -10)
	done.Label.TextSize = 26
	done.MouseButton1Click:Wait()
	Audio.play("UIClick")

	RunService:UnbindFromRenderStep("MatchCamera")
	camera.CameraType = Enum.CameraType.Custom
	gui:Destroy()
	folder:Destroy()
	for p, c in pairs(paintBefore) do
		p.Color = c
	end
	for _, g in ipairs(hidden) do
		g.Enabled = true
	end
end

return MatchView
