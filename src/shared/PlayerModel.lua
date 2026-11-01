--!nonstrict
-- Builds the 3D body for one of our sim players (never a Roblox user's avatar).
-- Height, weight and wingspan from the card set the body scales, so a 6'0" guard and a
-- 7'1" center look different on court. Kit colors and the jersey number come from the club.
--
--   local model = PlayerModel.build(player, { jersey = Color3, shorts = Color3, trim = Color3, number = 23 })
--
-- Bodies built this way use AnimationConstraint joints; AnimPlayer drives those.

local PlayerModel = {}

-- Slim, athletic look (js wants it close to Practical Basketball). Numbers tuned in Studio.
local SLIM = { body = 0.3, proportion = 0.15 }

-- RGB triples (not Color3) so the pure math above loads in plain Luau tests.
local SKINS = {
	{ 94, 60, 40 }, { 122, 80, 52 }, { 141, 95, 63 },
	{ 176, 124, 86 }, { 204, 150, 110 }, { 234, 192, 158 },
}

local function hash(s: string): number
	local h = 5381
	for i = 1, #s do
		h = (h * 33 + string.byte(s, i)) % 2147483647
	end
	return h
end

-- Pure numbers, testable outside Roblox. Heights in inches, weight in pounds.
function PlayerModel.scales(player)
	local inches = player.height or 78
	local height = 0.9 + (inches - 72) / 15 * 0.3 -- 6'0" -> 0.90, 7'3" -> 1.20
	-- Pounds per inch: ~2.4 is a slim guard, ~3.2 a heavy center.
	local build = math.clamp(((player.weight or 210) / inches - 2.4) / 0.8, 0, 1)
	local width = 0.74 + build * 0.16
	local reach = (player.wingspan or inches) - inches -- 0..6 inches of extra wingspan
	return {
		height = height,
		width = width,
		depth = width + 0.05,
		head = 0.95,
		bodyType = SLIM.body,
		proportion = SLIM.proportion + reach * 0.02, -- longer limbs for long wingspans
	}
end

function PlayerModel.skin(player): Color3
	local c = SKINS[hash(player.faceSeed or player.id or "x") % #SKINS + 1]
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- Palm, four fingers and a thumb, welded to the R15 hand (which is hidden). Sizes are the
-- walkout3d.js hand scaled to this body. side = 1 for the right hand, -1 for the left.
-- Rest pose: arm down, palm facing the body, fingers slightly curled.
local FINGERS = { { z = 0.15, len = 0.25 }, { z = 0.05, len = 0.29 }, { z = -0.05, len = 0.28 }, { z = -0.15, len = 0.23 } }
local function addHand(hand: BasePart, side: number, skin: Color3)
	local k = hand.Size.Y * 4.05
	local wristY = 0.137 * k / 1.33
	local function piece(name, size, pos, rot)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size * k
		p.Color = skin
		p.Material = Enum.Material.SmoothPlastic
		p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, true
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		local w = Instance.new("Weld")
		w.Part0, w.Part1 = hand, p
		w.C0 = CFrame.new(pos.X * k, wristY + pos.Y * k, pos.Z * k) * (rot or CFrame.identity)
		w.Parent = p
		p.CFrame = hand.CFrame * w.C0
		p.Parent = hand
	end
	piece("Palm", Vector3.new(0.2, 0.32, 0.42), Vector3.new(0, -0.17, 0))
	for i, f in ipairs(FINGERS) do
		piece("Finger" .. i, Vector3.new(0.12, f.len, 0.09), Vector3.new(-side * 0.02, -0.31 - f.len / 2, f.z), CFrame.Angles(0, 0, math.rad(-side * 12)))
	end
	piece("Thumb", Vector3.new(0.12, 0.24, 0.11), Vector3.new(-side * 0.06, -0.2, -0.25), CFrame.Angles(math.rad(28), 0, math.rad(-side * 18)))
	hand.Transparency = 1
end

function PlayerModel.build(player, kit)
	local Players = game:GetService("Players")
	local s = PlayerModel.scales(player)
	local d = Instance.new("HumanoidDescription")
	d.HeightScale, d.WidthScale, d.DepthScale = s.height, s.width, s.depth
	d.HeadScale, d.BodyTypeScale, d.ProportionScale = s.head, s.bodyType, s.proportion
	local skin = PlayerModel.skin(player)
	d.HeadColor, d.LeftArmColor, d.RightArmColor = skin, skin, skin
	d.TorsoColor = kit.jersey
	d.LeftLegColor, d.RightLegColor = kit.shorts, kit.shorts
	local model = Players:CreateHumanoidModelFromDescription(d, Enum.HumanoidRigType.R15)
	model.Name = player.name or "Player"
	-- Lower legs are skin, feet are shoes; the description colors whole limbs.
	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") then
			-- Slimmer limbs than the default blocky body (attachments stay put, they're centered).
			if part.Name:find("Arm") or part.Name:find("Hand") then
				part.Size = Vector3.new(part.Size.X * 0.72, part.Size.Y, part.Size.Z * 0.8)
			elseif part.Name:find("Leg") then
				part.Size = Vector3.new(part.Size.X * 0.85, part.Size.Y, part.Size.Z * 0.85)
			end
			if part.Name:find("LowerLeg") then
				part.Color = skin
			elseif part.Name:find("Foot") then
				part.Color = kit.trim or Color3.new(1, 1, 1)
			end
		end
	end
	addHand(model:FindFirstChild("RightHand"), 1, skin)
	addHand(model:FindFirstChild("LeftHand"), -1, skin)
	if kit.number then
		for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
			local gui = Instance.new("SurfaceGui")
			gui.Face = face
			gui.CanvasSize = Vector2.new(120, 120)
			gui.Parent = model:FindFirstChild("UpperTorso")
			local t = Instance.new("TextLabel")
			t.BackgroundTransparency = 1
			t.Size = UDim2.fromScale(1, 1)
			t.Font = Enum.Font.GothamBlack
			t.TextScaled = true
			t.TextColor3 = kit.trim or Color3.new(1, 1, 1)
			t.Text = tostring(kit.number)
			t.Parent = gui
		end
	end
	return model
end

return PlayerModel
