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
