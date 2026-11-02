--!nonstrict
-- Forward kinematics for our R15 players: given a clip and a time, where is every body part and
-- where is the ball. Pure CFrame math, so the same code poses players in the live match view and
-- in edit-mode Studio previews (no physics, no Humanoid animation, no frame of lag on the ball).
--
--   local S = PoseSolver.setup(body)                 -- once per body
--   PoseSolver.pose(S, "Dunk", 1.1, placeCFrame)     -- moves the parts
--   local p = PoseSolver.ball(S, clip, t, placeCFrame, rimWorld)  -- ball position or nil
--
-- placeCFrame is where the HumanoidRootPart goes. rimWorld (optional) is the real rim: shots and
-- dunks aim the ball there instead of at the clip's built-in hoop.

local AnimClips = require(script and script.Parent:FindFirstChild("AnimClips") or "./AnimClips")

local rad = math.rad
local BALL_R = 0.64

local PoseSolver = {}
PoseSolver.BallRadius = BALL_R

local function jointsOf(rig)
	local js = {}
	for _, d in ipairs(rig:GetDescendants()) do
		if d:IsA("Motor6D") then
			js[#js + 1] = { name = d.Name, p0 = d.Part0, p1 = d.Part1, c0 = d.C0, c1 = d.C1 }
		elseif d:IsA("AnimationConstraint") and d.Attachment0 and d.Attachment1 then
			js[#js + 1] = { name = d.Name, p0 = d.Attachment0.Parent, p1 = d.Attachment1.Parent, c0 = d.Attachment0.CFrame, c1 = d.Attachment1.CFrame }
		end
	end
	return js
end

-- Anchor the body and record its joints. Call once, with the body standing upright.
function PoseSolver.setup(rig: Model)
	for _, p in ipairs(rig:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
		elseif p:IsA("BallSocketConstraint") then
			p.Enabled = false
		end
	end
	local hrp = rig:FindFirstChild("HumanoidRootPart")
	local hum = rig:FindFirstChildOfClass("Humanoid")
	local welds = {}
	for _, w in ipairs(rig:GetDescendants()) do
		if w:IsA("Weld") and w.Part0 and w.Part1 then
			table.insert(welds, w) -- finger pieces and other welded extras follow their parent part
		end
	end
	return {
		rig = rig,
		hrp = hrp,
		joints = jointsOf(rig),
		welds = welds,
		hipHeight = hum.HipHeight + hrp.Size.Y / 2, -- HRP centre above the floor
		rh = rig:FindFirstChild("RightHand"),
		lh = rig:FindFirstChild("LeftHand"),
		lt = rig:FindFirstChild("LowerTorso"),
	}
end

-- Joint transforms for clip at t (same math as AnimPlayer:apply).
local function transforms(clip, t)
	local root = clip.root and AnimClips.sample(clip.root, t, 5) or { 0, 0, 0, 0, 0 }
	local T = {}
	for name, keys in pairs(clip.joints) do
		local v = AnimClips.sample(keys, t, 3)
		T[name] = CFrame.fromEulerAnglesYXZ(rad(v[1]), rad(v[2]), rad(v[3]))
	end
	for _, side in ipairs({ "Left", "Right" }) do
		if not clip.joints[side .. "Ankle"] then
			local hip = clip.joints[side .. "Hip"] and AnimClips.sample(clip.joints[side .. "Hip"], t, 1)[1] or 0
			local knee = clip.joints[side .. "Knee"] and AnimClips.sample(clip.joints[side .. "Knee"], t, 1)[1] or 0
			T[side .. "Ankle"] = CFrame.fromEulerAnglesYXZ(rad(AnimClips.footAngle(root[5], hip, knee, root[2])), 0, 0)
		end
	end
	T.Root = CFrame.new(root[1], root[2], root[3]) * CFrame.fromEulerAnglesYXZ(rad(root[5]), rad(root[4]), 0)
	return T, root
end

-- World CFrames of every jointed part for clip at t, with the root part at place.
function PoseSolver.solve(S, clip, t: number, place: CFrame)
	local T, root = transforms(clip, t)
	local cf = { [S.hrp] = place }
	local left = table.clone(S.joints)
	for _ = 1, 50 do
		if #left == 0 then
			break
		end
		for i = #left, 1, -1 do
			local j = left[i]
			if cf[j.p0] then
				cf[j.p1] = cf[j.p0] * j.c0 * (T[j.name] or CFrame.identity) * j.c1:Inverse()
				table.remove(left, i)
			end
		end
	end
	return cf, root
end

-- The clip's starting yaw (degrees). The body faces -Z at yaw 0.
function PoseSolver.baseYaw(clip): number
	return clip.root and clip.root[1][5] or 0
end

-- Where the root part goes so the body stands on floorY at (x, z), facing world yaw face
-- (0 = +Z, 90 = +X) at the start of the clip. Spins inside the clip still play out.
function PoseSolver.place(S, clip, x: number, z: number, floorY: number, face: number): CFrame
	return CFrame.new(x, floorY + S.hipHeight, z) * CFrame.Angles(0, rad(face - 180 - PoseSolver.baseYaw(clip)), 0)
end

-- Move the parts.
function PoseSolver.pose(S, clipName: string, t: number, place: CFrame)
	local clip = AnimClips.Clips[clipName]
	local cf = PoseSolver.solve(S, clip, t, place)
	for part, c in pairs(cf) do
		part.CFrame = c
	end
	for _, w in ipairs(S.welds) do
		w.Part1.CFrame = w.Part0.CFrame * w.C0 * w.C1:Inverse()
	end
	return cf
end

-- The clip's own hoop, in the clip's frame (for clips authored against a hoop).
local function clipHoop(S, clip, place)
	if clip.hoopAt then
		local cf = PoseSolver.solve(S, clip, clip.hoopAt[1], place)
		local hand = clip.hoopAt[2] == "L" and S.lh or S.rh
		local o = clip.hoopOffset or { -0.25, -0.15 }
		local h = place:PointToObjectSpace(cf[hand].Position)
		return place:PointToWorldSpace(Vector3.new(h.X + o[1], h.Y + o[2], h.Z))
	end
	return place:PointToWorldSpace(Vector3.new(-7.5, 7.8 - S.hipHeight, 0))
end

local FLOOR = {
	floorR = { -1.2, 1.1 },
	floorL = { 1.2, 1.1 },
	floorMid = { 0, 1.25 },
	floorBetween = { 0, 0.1 },
	floorBehind = { 0, -1.1 },
	floorRFar = { -1.7, 1.6 },
	floorBounce = { 0, 5.5 },
}
local HELD = { R = true, L = true, both = true, RTip = true, LTip = true }

-- Ball position for one named spot at time t.
local function spot(S, clip, where, t, place, rim)
	local cf, root = PoseSolver.solve(S, clip, t, place)
	local rh, lh = cf[S.rh].Position, cf[S.lh].Position
	local up = Vector3.yAxis
	if where == "R" then
		return rh - up * (BALL_R - 0.05)
	elseif where == "L" then
		return lh - up * (BALL_R - 0.05)
	elseif where == "RTip" then
		return rh + up * (BALL_R + 0.02)
	elseif where == "LTip" then
		return lh + up * (BALL_R + 0.02)
	elseif where == "both" then
		return (rh + lh) / 2 + cf[S.lt].LookVector * 0.35
	end
	local floorY = place.Position.Y - S.hipHeight
	-- Floor spots sit around the body's current spot, turned with its yaw.
	local body = place * CFrame.new(root[1], 0, root[3]) * CFrame.Angles(0, rad(root[4]), 0)
	local function L(x, y, z)
		local p = body:PointToWorldSpace(Vector3.new(-x, 0, -z))
		return Vector3.new(p.X, floorY + y, p.Z)
	end
	if FLOOR[where] then
		return L(FLOOR[where][1], BALL_R, FLOOR[where][2])
	elseif where == "passTarget" then
		return L(0, 3.4, 11)
	elseif where == "shotStart" then
		return L(9, 5.5, 1)
	elseif where == "reboundIn" then
		return L(6, 11, -2)
	elseif where == "swatAway" then
		return L(-9, 9.5, 3)
	end
	local h = rim or clipHoop(S, clip, place)
	if where == "rim" then
		return h + up * 0.6
	elseif where == "net" then
		return h - up * 1.3
	end
	local away = Vector3.new(h.X - place.Position.X, 0, h.Z - place.Position.Z)
	away = away.Magnitude > 0.01 and away.Unit or Vector3.xAxis
	local under = { floorUnderRim = { 0.6, BALL_R }, bounceUnderRim = { 1.6, 2.4 }, floorUnderRim2 = { 2.5, BALL_R } }
	if under[where] then
		local u = under[where]
		local p = h + away * u[1]
		return Vector3.new(p.X, floorY + u[2], p.Z)
	end
	return nil
end

-- Ball position at time t, or nil when the clip doesn't have it.
function PoseSolver.ball(S, clip, t: number, place: CFrame, rim: Vector3?)
	local ks = clip.ball
	if not ks then
		return nil
	end
	local i = 1
	while i < #ks and ks[i + 1][1] <= t do
		i += 1
	end
	local k0, k1 = ks[i], ks[math.min(i + 1, #ks)]
	if k0[2] == "gone" then
		return nil
	end
	if k0 == k1 or (k0[2] == k1[2] and HELD[k0[2]]) then
		return spot(S, clip, k0[2], t, place, rim)
	end
	if k1[2] == "gone" then
		return spot(S, clip, k0[2], k0[1], place, rim)
	end
	local a, b = spot(S, clip, k0[2], k0[1], place, rim), spot(S, clip, k1[2], k1[1], place, rim)
	if not a or not b then
		return a or b
	end
	local u = (t - k0[1]) / (k1[1] - k0[1])
	if k1[3] == 2 then
		u = u * u
	elseif k1[3] == 1 then
		u = 1 - (1 - u) * (1 - u)
	end
	local arc = k1[4] or 0
	if k1[2] == "rim" and rim then
		-- Real shots travel further than the clip's built-in hoop: arc grows with distance.
		arc = math.max(arc, (b - a).Magnitude * 0.22)
	end
	return a:Lerp(b, u) + Vector3.yAxis * (arc * 4 * u * (1 - u))
end

return PoseSolver
