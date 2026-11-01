--!nonstrict
-- RigBuilder: builds every character as a classic Motor6D rig (see PuppetMath).
-- These rigs are fully animated by the client Puppeteer. Each character's dress,
-- colours and proportions come from its file in ReplicatedStorage/Characters.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PM = require(ReplicatedStorage:WaitForChild("PuppetMath"))

local RigBuilder = {}

local MAT = Enum.Material
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local Roster = require(ReplicatedStorage:WaitForChild("Roster"))
local Armor = require(script.Parent:WaitForChild("Armor"))
local DEFAULT_COLORS = { skin = rgb(150, 128, 108), torso = rgb(66, 58, 50), legs = rgb(58, 52, 46), arms = rgb(66, 58, 50) }

local ORDER = { "Root", "Waist", "Neck", "RShoulder", "RElbow", "LShoulder", "LElbow", "RHip", "RKnee", "RAnkle", "LHip", "LKnee", "LAnkle", "RWrist", "LWrist", "RToe", "LToe" }

function RigBuilder.build(kind, s)
	s = s or 1
	local D = PM.dims(kind, s)
	local J = PM.joints(D)
	local char = Roster.byKind[kind]
	local look = (char and char.Colors) or DEFAULT_COLORS

	local model = Instance.new("Model")
	model.Name = kind
	local parts = {}

	local function mk(name, size, color, mat)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = mat or MAT.SmoothPlastic
		p.CanCollide = false
		p.Massless = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		parts[name] = p
		return p
	end

	local root = mk("HumanoidRootPart", D.rootSize, rgb(255, 255, 255))
	root.Transparency = 1
	root.CanCollide = true
	root.Massless = false
	mk("Hips", D.hipsSize, look.legs, MAT.Fabric)
	mk("Chest", D.chestSize, look.torso, MAT.Fabric)
	mk("Head", D.headSize, look.skin)
	for _, n in ipairs({ "R", "L" }) do
		mk(n .. "UpperArm", Vector3.new(D.armW, D.upperArm, D.armW), look.arms, MAT.Fabric)
		mk(n .. "LowerArm", Vector3.new(D.armW * 0.9, D.lowerArm, D.armW * 0.9), look.arms, MAT.Fabric)
		mk(n .. "Thigh", Vector3.new(D.legW, D.thigh, D.legW), look.legs, MAT.Fabric)
		mk(n .. "Shin", Vector3.new(D.legW * 0.9, D.shin, D.legW * 0.9), look.legs, MAT.Fabric)
		mk(n .. "Foot", D.footSize, rgb(40, 32, 26), MAT.Fabric)
		if J[n .. "Wrist"] then -- (limbs rigs: the fist and the toes on joints of their own)
			mk(n .. "Hand", D.handSize, (char and char.FistSkin) and look.skin or rgb(46, 36, 28), MAT.Fabric)
			mk(n .. "Toe", D.toeSize, rgb(40, 32, 26), MAT.Fabric)
		end
	end

	-- rest pose + joints
	root.CFrame = CFrame.new(0, D.rootY, 0)
	for _, jn in ipairs(ORDER) do
		local j = J[jn]
		if not j then
			continue -- (the limbs-only joints)
		end
		local p0, p1 = parts[j.p0], parts[j.p1]
		p1.CFrame = p0.CFrame * j.C0 * j.C1:Inverse()
		local m = Instance.new("Motor6D")
		m.Name = jn
		m.Part0 = p0
		m.Part1 = p1
		m.C0 = j.C0
		m.C1 = j.C1
		m.Parent = p0
	end

	-- decoration welded onto a body part. offset is in the part's local space.
	local function deco(onPart, name, size, offset, color, mat, shape)
		local base = parts[onPart]
		local d = Instance.new("Part")
		d.Name = name
		if shape then
			d.Shape = shape
		end
		d.Size = size
		d.Color = color
		d.Material = mat or MAT.SmoothPlastic
		d.CanCollide = false
		d.Massless = true
		d.CastShadow = true
		d.TopSurface = Enum.SurfaceType.Smooth
		d.BottomSurface = Enum.SurfaceType.Smooth
		d.CFrame = base.CFrame * offset
		local w = Instance.new("WeldConstraint")
		w.Part0 = base
		w.Part1 = d
		w.Parent = d
		d.Parent = model
		return d
	end
	local V = function(x, y, z)
		return Vector3.new(x, y, z) * s
	end
	local at = function(x, y, z)
		return CFrame.new(x * s, y * s, z * s)
	end
	local cw, ch, cd = D.chestSize.X / s, D.chestSize.Y / s, D.chestSize.Z / s
	local hw, hd = D.hipsSize.X / s, D.hipsSize.Z / s
	local aw, lw = D.armW / s, D.legW / s
	local la, ua = D.lowerArm / s, D.upperArm / s

	-- hands shared by everyone
	for _, n in ipairs(parts.RHand and {} or { "R", "L" }) do
		deco(n .. "LowerArm", "Fist", V(aw * 0.95, 0.42, aw * 1.0), at(0, -la / 2 - 0.08, 0), (char and char.FistSkin) and look.skin or rgb(46, 36, 28), MAT.Fabric)
	end

	-- the character's own look (its file in ReplicatedStorage/Characters, M.Look)
	if char and char.Look then
		char.Look({
			deco = deco, parts = parts, V = V, at = at, rgb = rgb, MAT = MAT, D = D, s = s, look = look,
			-- Armor.tatter, given unscaled like V/at and scaled up to this rig
			tatter = function(rng, onPart, top, w, l, color, hem, rough)
				Armor.tatter(function(on, name, size, cf, ...)
					return deco(on, name, size * s, cf.Rotation + cf.Position * s, ...)
				end, rng, onPart, top, w, l, color, hem, rough)
			end,
			cw = cw, ch = ch, cd = cd, hw = hw, hd = hd, aw = aw, lw = lw, la = la, ua = ua,
		})
	end

	local hum = Instance.new("Humanoid")
	-- turn auto-scaling off FIRST: R15 auto-scaling recomputes HipHeight from
	-- leg parts it expects by name, which this rig doesn't have (-> sinking)
	pcall(function()
		hum.AutomaticScalingEnabled = false
	end)
	hum.RigType = Enum.HumanoidRigType.R15
	hum.HipHeight = D.hipHeight
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	local animator = Instance.new("Animator")
	animator.Parent = hum
	hum.Parent = model

	model.PrimaryPart = root
	model:SetAttribute("PrisonRig", kind)
	model:SetAttribute("RigScale", s)
	model:SetAttribute("HipHeight", D.hipHeight) -- the server re-asserts this (see rig guard)
	model:SetAttribute("StandHeight", D.rootY) -- root-part centre above the floor when standing
	return model, hum, D
end

return RigBuilder
