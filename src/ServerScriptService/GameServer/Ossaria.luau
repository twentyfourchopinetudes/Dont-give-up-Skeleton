--!nonstrict
-- OSSARIA, EXILED HEIR: waiting in the Rotted Court under the Decayed Palace (Map.OssariaPit), in its middle, her back to
-- the pit you came down. A tall shape in tattered, overlapping shrouds of dark cloth, each a shade off the next, a
-- shawl over her shoulders, her face lost in a hood behind a veil; the darkness the pit breathes out heaped at her feet
-- and rising off her. Not a fight yet: her bar shows while you're in her court (init.server) and she never strikes.
-- Walk up to her and the meeting plays, once (Save "OssariaFled"): she turns, she speaks (Config.Ossaria.Lines), wings
-- split out from under her shawl, and she goes - past you and straight up the pit, out of the court - round the Gilded
-- Heights and up over them, and with one slash brings them down (HeightsRuin), then drops into the middle of the
-- ruined colosseum's sand (the Silver Knight gone from it: Champion.vanish) and waits there (Map.OssariaPit.Arena:
-- init.server shows her bar on that sand); back below, her bonfire is where she stood (Map.OssariaPit.Bonfire).
-- THE FIGHT, on that sand, is three phases. Challenge her (challenge) and 1: she raises Caelen's husk on her strings
-- and hangs over it (Champion.luau's husk). It beaten, 2: she sheds her shrouds (reveal) and comes down as what was
-- under them, and 3: at half her health, the great hands (both Characters/OssariaHeir: Heir.begin). Lose at any
-- point and she's back on her scar under her shrouds, to be challenged again; the reveal and her third phase's
-- coming are cutscenes the first time only. Beaten, she's gone for good (Save "Ossaria").
--   M.init(Core): call before Save.replay
-- The model is one anchored root with everything welded to it (one CFrame to move her); each wing is two sections on
-- Motor6Ds (their C0s spread and beat them).
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local HeightsRuin = require(script.Parent:WaitForChild("HeightsRuin"))

local M = {}
local V3, C3 = Vector3.new, Color3.fromRGB
local MAT = Enum.Material
local MEET = 20 -- (how near you come before she speaks)

local function smooth(k)
	k = math.clamp(k, 0, 1)
	return k * k * (3 - 2 * k)
end
local function rnd(a, b)
	return a + math.random() * (b - a)
end
local function flat(v)
	return V3(v.X, 0, v.Z)
end

-- her body, at `at` (her feet, facing its look); returns { model, root, hood, wings, aura }
local function build(at)
	local rng = Random.new(4471)
	local function R(a, b)
		return rng:NextNumber(a, b)
	end
	local model = Instance.new("Model")
	model.Name = "Ossaria"
	local root = Instance.new("Part")
	root.Name = "OssariaRoot"
	root.Size, root.CFrame, root.Transparency = V3(1, 1, 1), at, 1
	root.Anchored, root.CanCollide, root.CanQuery, root.CanTouch = true, false, false, false
	root.Parent = model
	model.PrimaryPart = root
	local function make(class, props, cf, to)
		local p = Instance.new(class)
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, false, true
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		for k, v in pairs(props) do
			p[k] = v
		end
		p.CFrame = cf
		p.Parent = model
		if to then
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = to, p
			w.Parent = p
		end
		return p
	end
	local function add(props, lcf, class)
		return make(class or "Part", props, at * lcf, root)
	end
	local function shade() -- each scrap a shade off the next: near black, plum, a little moss (it all reads black in the dark)
		return C3(26, 22, 30):Lerp(C3(74, 58, 80), R(0, 1)):Lerp(C3(44, 54, 40), R(0, 0.35))
	end

	-- the shrouds: rings of tattered panels hung round her, flaring out to their hems, some with a tatter off the hem
	local function layer(yt, len, r, n, flare, thick)
		for i = 1, n do
			local a = (i + R(-0.3, 0.3)) / n * math.pi * 2
			local h = len * R(0.78, 1.12)
			local w = 2 * math.pi * r / n * R(1.3, 1.7)
			local fl = flare * R(0.8, 1.2)
			add({ Name = "Shroud", Size = V3(w, h, thick), Material = MAT.Fabric, Color = shade() }, CFrame.Angles(0, a, 0) * CFrame.new(0, yt - h / 2, -r) * CFrame.Angles(fl, 0, R(-0.06, 0.06)))
			if rng:NextNumber() < 0.55 then
				local tl = R(0.8, 2.2)
				add({ Name = "Tatter", Size = V3(R(0.2, 0.5), tl, thick * 0.8), Material = MAT.Fabric, Color = shade() }, CFrame.Angles(0, a + R(-0.15, 0.15), 0) * CFrame.new(R(-w / 3, w / 3), yt - h - tl / 2 + 0.3, -r - h * math.sin(fl) * 0.9) * CFrame.Angles(fl * 1.2, 0, R(-0.15, 0.15)))
			end
		end
	end
	add({ Name = "Core", Size = V3(1.7, 5.6, 1.3), Material = MAT.Fabric, Color = C3(10, 9, 12) }, CFrame.new(0, 4.3, 0))
	add({ Name = "Shoulders", Size = V3(2.6, 0.9, 1.4), Material = MAT.Fabric, Color = C3(14, 12, 16) }, CFrame.new(0, 7.3, 0))
	layer(4.8, 5.0, 1.05, 13, 0.16, 0.14) -- (the skirts, to the floor)
	layer(5.6, 3.6, 1.2, 11, 0.24, 0.12)
	layer(7.7, 3.2, 1.15, 12, 0.36, 0.12) -- (the shawl: it stays on, wings and all)
	layer(7.95, 1.6, 0.85, 9, 0.6, 0.1)
	-- the hood: the dark of her face, the hood round it, tall and rounded, its sides down onto the shawl; a veil across,
	-- two faint glints behind it (ovals: block parts with a sphere mesh)
	local function oval(props, lcf)
		local p = add(props, lcf)
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.Sphere
		m.Parent = p
		return p
	end
	local hood = oval({ Name = "Face", Size = V3(1.35, 1.75, 1.35), Material = MAT.SmoothPlastic, Color = C3(3, 3, 4) }, CFrame.new(0, 8.75, -0.3))
	oval({ Name = "Hood", Size = V3(2, 2.7, 2.15), Material = MAT.Fabric, Color = shade() }, CFrame.new(0, 9, 0.2))
	for _, sx in ipairs({ -1, 1 }) do
		add({ Name = "HoodSide", Size = V3(0.15, 1.9, 1.4), Material = MAT.Fabric, Color = shade() }, CFrame.new(sx * 0.95, 8.1, 0.05) * CFrame.Angles(0, 0, sx * 0.15))
		-- HER EYES, behind the veil: not a light apiece but an eye - a ring of her light in a dark rim, a slit of a
		-- pupil down it, a bright point in that (the "Glint": it pulses, and burns when she pulls the Heights down)
		local e = CFrame.new(sx * 0.27, 8.86, -0.955) * CFrame.Angles(0, sx * 0.25, 0)
		local side = CFrame.Angles(0, math.pi / 2, 0) -- (a cylinder lies along its X: turned to face out of her face)
		add({ Name = "IrisRim", Shape = Enum.PartType.Cylinder, Size = V3(0.04, 0.34, 0.34), Material = MAT.SmoothPlastic, Color = C3(24, 14, 34) }, e * CFrame.new(0, 0, 0.012) * side)
		add({ Name = "Iris", Shape = Enum.PartType.Cylinder, Size = V3(0.05, 0.26, 0.26), Material = MAT.Neon, Color = C3(150, 110, 200), Transparency = 0.1 }, e * side)
		add({ Name = "Pupil", Size = V3(0.04, 0.22, 0.03), Material = MAT.SmoothPlastic, Color = C3(6, 4, 8) }, e * CFrame.new(0, 0, -0.03) * CFrame.Angles(0, 0, sx * 0.08))
		local point = add({ Name = "Glint", Shape = Enum.PartType.Ball, Size = Vector3.one * 0.06, Material = MAT.Neon, Color = C3(232, 214, 255), Transparency = 0.1 }, e * CFrame.new(sx * 0.05, 0.05, -0.045))
		TweenService:Create(point, TweenInfo.new(1.6 + sx * 0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Size = Vector3.one * 0.095 }):Play()
		-- (nothing over the top of it, no lid or brow: wide open. Only a line under it)
		add({ Name = "Lid", Size = V3(0.34, 0.05, 0.07), Material = MAT.SmoothPlastic, Color = C3(6, 5, 8) }, e * CFrame.new(0, -0.15, -0.015) * CFrame.Angles(0, 0, -sx * 0.14))
	end
	-- ...and four more, small, open in the dark of her face round those two, no two a size: six lights in all (as
	-- there'll be six wicks, when the shrouds come off)
	for _, q in ipairs({ { -0.47, 9.0, 0.09 }, { 0.45, 9.04, 0.07 }, { -0.4, 8.56, 0.06 }, { 0.34, 8.5, 0.08 } }) do
		local z = -0.3 - 0.675 * math.sqrt(math.max(0, 1 - (q[1] / 0.675) ^ 2 - ((q[2] - 8.75) / 0.875) ^ 2)) - 0.015 -- (on the dark's own face)
		add({ Name = "Eyelet", Shape = Enum.PartType.Ball, Size = Vector3.one * q[3], Material = MAT.Neon, Color = C3(150, 110, 200), Transparency = 0.25 }, CFrame.new(q[1], q[2], z))
		add({ Name = "EyeletPupil", Size = V3(q[3] * 0.25, q[3] * 0.8, 0.02), Material = MAT.SmoothPlastic, Color = C3(6, 4, 8) }, CFrame.new(q[1], q[2], z - q[3] * 0.5))
	end
	oval({ Name = "Veil", Size = V3(1.3, 2, 0.14), Material = MAT.Fabric, Color = C3(8, 6, 10), Transparency = 0.5 }, CFrame.new(0, 8.3, -1.02))
	-- a faint cold light before her, so her rags show their shades
	local lamp = Instance.new("Attachment")
	lamp.Position = V3(0, 6, -3)
	lamp.Parent = root
	local lt = Instance.new("PointLight")
	lt.Color, lt.Range, lt.Brightness = C3(170, 160, 200), 12, 1.2
	lt.Parent = lamp
	-- her arms: sleeves hanging, ragged at their ends, thin pale fingers out of them
	for _, sx in ipairs({ -1, 1 }) do
		add({ Name = "Sleeve", Size = V3(0.8, 3, 0.8), Material = MAT.Fabric, Color = shade() }, CFrame.new(sx * 1.45, 5.9, -0.1) * CFrame.Angles(0, 0, sx * 0.12))
		for _ = 1, 3 do
			add({ Name = "Tatter", Size = V3(R(0.2, 0.4), R(0.8, 1.6), 0.08), Material = MAT.Fabric, Color = shade() }, CFrame.new(sx * 1.62 + R(-0.3, 0.3), 4.1, -0.1 + R(-0.3, 0.3)) * CFrame.Angles(R(-0.2, 0.2), R(0, 3), R(-0.2, 0.2)))
		end
		add({ Name = "Hand", Size = V3(0.35, 0.6, 0.25), Material = MAT.SmoothPlastic, Color = C3(190, 182, 166) }, CFrame.new(sx * 1.62, 4.15, -0.2))
		for f = 1, 4 do -- long fingers of two bones each, hooked in at the knuckle, a dark nail on the end
			local l1, l2 = 0.5 + (f == 2 and 0.12 or f == 3 and 0.08 or 0), 0.42
			local k = CFrame.new(sx * 1.62 + (f - 2.5) * 0.09, 3.9, -0.2) * CFrame.Angles(0.12, 0, (f - 2.5) * 0.09)
			local k2 = k * CFrame.new(0, -l1, 0) * CFrame.Angles(0.5, 0, 0)
			add({ Name = "Finger", Size = V3(0.07, l1, 0.07), Material = MAT.SmoothPlastic, Color = C3(190, 182, 166) }, k * CFrame.new(0, -l1 / 2, 0))
			add({ Name = "Knuckle", Shape = Enum.PartType.Ball, Size = Vector3.one * 0.1, Material = MAT.SmoothPlastic, Color = C3(190, 182, 166) }, k2)
			add({ Name = "Finger", Size = V3(0.06, l2, 0.06), Material = MAT.SmoothPlastic, Color = C3(190, 182, 166) }, k2 * CFrame.new(0, -l2 / 2, 0))
			add({ Name = "Nail", Size = V3(0.045, 0.2, 0.045), Material = MAT.SmoothPlastic, Color = C3(14, 10, 18) }, k2 * CFrame.new(0, -l2 - 0.07, 0) * CFrame.Angles(0.5, 0, 0))
		end
	end
	-- a mantle of dark points over the shawl, round her shoulders
	for i = 1, 14 do
		local a = (i + R(-0.2, 0.2)) / 14 * math.pi * 2
		add({ Name = "Mantle", Size = V3(1.05, 1.05, 0.08), Material = MAT.Fabric, Color = shade() }, CFrame.Angles(0, a, 0) * CFrame.new(0, 7.75 + R(-0.1, 0.1), -1.3) * CFrame.Angles(0.55, 0, 0) * CFrame.Angles(0, 0, math.pi / 4))
	end
	-- what's left of her crown, its gilt gone to tarnish, sunk a little askew into the hood: a point over every other
	-- piece of it, the tallest at her brow, one snapped short and one gone
	local crown = CFrame.new(0, 9.6, 0.15) * CFrame.Angles(0.12, 0, 0.06)
	for i = 0, 11 do
		local at = crown * CFrame.Angles(0, i / 12 * math.pi * 2, 0) * CFrame.new(0, 0, -0.98)
		local gilt = C3(120, 96, 52):Lerp(C3(40, 34, 30), R(0, 0.5))
		add({ Name = "Crown", Size = V3(0.54, 0.16, 0.07), Material = MAT.Metal, Color = gilt }, at)
		if i % 2 == 0 and i ~= 8 then
			local h = (i == 0 and 0.75 or 0.5) * (i == 4 and 0.5 or 1)
			add({ Name = "CrownPoint", Size = V3(0.1, h, 0.06), Material = MAT.Metal, Color = gilt }, at * CFrame.new(0, h / 2, 0))
		end
	end
	-- a little of her own light under the hood
	local hoodLight = Instance.new("PointLight")
	hoodLight.Color, hoodLight.Range, hoodLight.Brightness = C3(170, 120, 230), 7, 0.8
	hoodLight.Parent = hood
	-- CLOTH (every client swings it: Carrier.cloth): strips hung off her that trail and whip behind her as she moves -
	-- a train down her back, a tail off her hood, her sleeves' ends, tatters round her hem. lcf looks the way each hangs out
	local function chain(lcf, segs, len, width, phys, to)
		local p = make("Part", { Name = "ClothAnchor", Size = V3(0.2, 0.2, 0.2), Transparency = 1 }, lcf, to or root)
		for k, v in pairs(phys) do
			p:SetAttribute(k, v)
		end
		p:SetAttribute("Segs", segs)
		p:SetAttribute("Len", len)
		p:SetAttribute("Width", width)
		p:SetAttribute("Color", shade())
		return p
	end
	local heavy, light = { Drag = 0.93, Gravity = 1.2, Out = 0.1 }, { Drag = 0.97, Gravity = 0.8, Out = 0.05 }
	local back = CFrame.Angles(0, math.pi, 0)
	local cloth = {}
	for _, x in ipairs({ -0.7, 0, 0.7 }) do
		table.insert(cloth, chain(at * CFrame.new(x, 7.3, 0.95) * back, 6, R(1.05, 1.2), R(0.95, 1.2), heavy))
	end
	table.insert(cloth, chain(at * CFrame.new(0, 9.6, 1.2) * back, 4, 0.8, 1.5, light))
	for _, sx in ipairs({ -1, 1 }) do
		table.insert(cloth, chain(at * CFrame.new(sx * 1.62, 4.5, 0) * CFrame.Angles(0, -sx * math.pi / 2, 0), 3, 0.75, 0.5, light))
	end
	for i = 1, 6 do
		table.insert(cloth, chain(at * CFrame.Angles(0, (i + R(-0.3, 0.3)) / 6 * math.pi * 2, 0) * CFrame.new(0, 2.6, -1.5), 2, R(0.9, 1.2), R(0.6, 0.9), light))
	end
	for _, a in ipairs(cloth) do
		CollectionService:AddTag(a, "ClothChain")
	end
	-- the dark rising off her
	local auraVol = add({ Name = "Aura", Size = V3(3.5, 8, 3.5), Transparency = 1 }, CFrame.new(0, 4.5, 0))
	local aura = Instance.new("ParticleEmitter")
	aura.Texture = "rbxasset://textures/particles/smoke_main.dds"
	aura.Color = ColorSequence.new(C3(10, 8, 14), C3(30, 18, 40))
	aura.LightEmission, aura.LightInfluence = 0, 0
	aura.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(0.5, 3.5), NumberSequenceKeypoint.new(1, 5.5) })
	aura.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.72), NumberSequenceKeypoint.new(0.6, 0.82), NumberSequenceKeypoint.new(1, 1) }) -- (thin: it mustn't hide her)
	aura.Lifetime, aura.Speed = NumberRange.new(2, 3.5), NumberRange.new(0.8, 2)
	aura.Rotation, aura.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-40, 40)
	aura.Acceleration, aura.Drag = V3(0, 1.5, 0), 0.5
	aura.EmissionDirection = Enum.NormalId.Top
	aura.Rate = 7
	aura.Shape, aura.ShapeStyle = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume
	aura.Parent = auraVol

	-- THE WINGS, folded away under the shawl (unseen) till they split out: a bony arm out from the shoulder blade (A), a
	-- hand of four long fingers off its end (B), torn membrane between, rags hanging off it
	local wings, wingParts, shed = {}, {}, {}
	local BONE = C3(58, 50, 56)
	local WS = 1.7 -- (their size: every length and thickness below is times this, so they keep their shape)
	local cur -- (the section being built: its pivot, what its parts weld to)
	local function wingPart(props, cf, _, final, class)
		props.Transparency = 1
		local p = make(class or "Part", props, cf, cur)
		table.insert(wingParts, { p, final })
		return p
	end
	local function bone(name, piv, a, b, th)
		local d = b - a
		wingPart({ Name = name, Size = V3(th * WS, th * WS, d.Magnitude), Material = MAT.SmoothPlastic, Color = BONE }, piv * CFrame.lookAt((a + b) / 2, b), nil, 0)
	end
	local function membrane(piv, a, b, c)
		-- a triangle out of two wedges (after EgoMoose)
		local ab, ac, bc = b - a, c - a, c - b
		local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
		if abd > acd and abd > bcd then
			c, a = a, c
		elseif acd > bcd and acd > abd then
			a, b = b, a
		end
		ab, ac, bc = b - a, c - a, c - b
		local right = ac:Cross(ab).Unit
		local up = bc:Cross(right).Unit
		local back = bc.Unit
		local height = math.abs(ab:Dot(up))
		local col = C3(20, 13, 24):Lerp(C3(36, 22, 32), R(0, 1))
		local tr = R(0.08, 0.25)
		wingPart({ Name = "Membrane", Size = V3(0.06 * WS, height, math.abs(ab:Dot(back))), Material = MAT.SmoothPlastic, Color = col }, piv * CFrame.fromMatrix((a + b) / 2, right, up, back), nil, tr, "WedgePart")
		wingPart({ Name = "Membrane", Size = V3(0.06 * WS, height, math.abs(ac:Dot(back))), Material = MAT.SmoothPlastic, Color = col }, piv * CFrame.fromMatrix((a + c) / 2, -right, up, -back), nil, tr, "WedgePart")
	end
	local wingCloth = {} -- (the rags off the wings: cloth too, but not hung till the wings are out - wingShow)
	local function rag(piv, p)
		table.insert(wingCloth, chain(piv * CFrame.new(p) * back, 3, R(0.4, 0.85) * WS, R(0.3, 0.5) * WS, { Drag = 0.96, Gravity = 0.7 }, cur))
	end
	for _, s in ipairs({ -1, 1 }) do
		local pivA = at * CFrame.new(s * 0.55, 7.0, 0.75) * CFrame.Angles(0, -s * 0.35, 0) -- (swept back)
		local E = V3(s * 3.8, 2.4, 0.5) * WS
		local low = V3(s * 0.9, -2.6, 0.3) * WS
		local trail = V3(s * 3.3, -1.6, 0.45) * WS
		local pa = make("Part", { Name = "WingA", Size = V3(0.2, 0.2, 0.2), Transparency = 1 }, pivA)
		cur = pa
		bone("WingBone", pivA, V3(), E, 0.38)
		membrane(pivA, V3(), E, low)
		membrane(pivA, E, trail * R(0.8, 0.95), low)
		rag(pivA, low:Lerp(trail, 0.3))
		rag(pivA, low:Lerp(trail, 0.75))
		local pivB = pivA * CFrame.new(E)
		local pb = make("Part", { Name = "WingB", Size = V3(0.2, 0.2, 0.2), Transparency = 1 }, pivB)
		cur = pb
		-- (long bony fingers, the membrane torn well short of their tips so they jut out of it, each hooked at the end)
		local tips = { V3(s * 3.4, 3.6, 0.3) * WS, V3(s * 5.6, 1.4, 0.4) * WS, V3(s * 5.2, -1.8, 0.45) * WS, V3(s * 3.0, -3.8, 0.4) * WS }
		for i, tp in ipairs(tips) do
			bone("WingFinger", pivB, V3(), tp, 0.26 - i * 0.03)
			bone("WingTalon", pivB, tp, tp + V3(s * 0.35, -0.7, 0) * WS, 0.12)
			if i < #tips then
				local f1, f2 = R(0.55, 0.85), R(0.55, 0.85)
				membrane(pivB, V3(), tp * f1, tips[i + 1] * f2)
				for _, k in ipairs({ 0.3, 0.7 }) do
					rag(pivB, (tp * f1):Lerp(tips[i + 1] * f2, k))
				end
			end
		end
		membrane(pivB, V3(), tips[4] * 0.7, trail - E)
		bone("WingClaw", pivB, V3(), V3(s * 0.3, 1.1, 0.1) * WS, 0.18)
		-- the two sections' pivots on motors
		local mA = Instance.new("Motor6D")
		mA.Part0, mA.Part1, mA.C0 = root, pa, at:ToObjectSpace(pivA)
		mA.Parent = root
		local mB = Instance.new("Motor6D")
		mB.Part0, mB.Part1, mB.C0 = pa, pb, CFrame.new(E)
		mB.Parent = pa
		table.insert(wings, { s = s, mA = mA, mB = mB, baseA = mA.C0, baseB = mB.C0 })
		-- (in flight: the dark shed off each wing's hand - meet turns it on)
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
		pe.Color = ColorSequence.new(C3(12, 8, 16), C3(46, 26, 60))
		pe.LightEmission, pe.LightInfluence = 0, 0
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 4) })
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
		pe.Lifetime, pe.Speed, pe.Rate = NumberRange.new(0.5, 0.9), NumberRange.new(0, 2), 18
		pe.Rotation, pe.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-60, 60)
		pe.LockedToPart = true -- (carried with the wing: at her speed, left in the air it's a row of puffs far behind her)
		pe.Enabled = false
		pe.Parent = pb
		table.insert(shed, pe)
	end
	-- motes of her light adrift in the dark round her
	local motes = Instance.new("ParticleEmitter")
	motes.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	motes.Color = ColorSequence.new(C3(170, 130, 220))
	motes.LightEmission = 0.8
	motes.Size = NumberSequence.new(0.14, 0)
	motes.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.2), NumberSequenceKeypoint.new(1, 1) })
	motes.Lifetime, motes.Speed, motes.Rate = NumberRange.new(2, 4), NumberRange.new(0.3, 1), 4
	motes.SpreadAngle = Vector2.new(180, 180)
	motes.Shape, motes.ShapeStyle = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume
	motes.Parent = auraVol
	return { model = model, root = root, hood = hood, wings = wings, wingParts = wingParts, wingCloth = wingCloth, shed = shed, aura = aura }
end

-- the wings: unfold 0 (folded down under the shawl) .. 1 (spread), flap the beat's angle (flapB: the outer half's, if
-- it isn't just following; twist: the wing turned about its own length)
local function wingPose(b, unfold, flap, flapB, twist)
	flapB, twist = flapB or flap * 0.6, twist or 0
	for _, w in ipairs(b.wings) do
		local s = w.s
		w.mA.C0 = w.baseA * CFrame.Angles(0, 0, (1 - unfold) * -s * math.rad(115) + s * flap) * CFrame.Angles((1 - unfold) * 0.6 + twist, 0, 0)
		w.mB.C0 = w.baseB * CFrame.Angles(0, 0, (1 - unfold) * -s * math.rad(160) + s * flapB) * CFrame.Angles(twist * 0.6, 0, 0)
	end
end
local function wingShow(b, k)
	for _, w in ipairs(b.wingParts) do
		w[1].Transparency = 1 - (1 - w[2]) * k
	end
	if k > 0 and not b.clothOn then -- (their rags, hung now they're out)
		b.clothOn = true
		for _, a in ipairs(b.wingCloth) do
			CollectionService:AddTag(a, "ClothChain")
		end
	end
end

function M.init(Core)
	local Map, Config, Save, FxRemote = Core.Map, Core.Config, Core.Save, Core.FxRemote
	local O = Map.OssariaPit
	if not (O and O.Spot and O.Bonfire) then
		return
	end
	local C = Config.Ossaria
	local S = O.Spot
	local F0 = V3(-1, 0, 0) -- (her back to the pit: facing down the court, west)
	local b = build(CFrame.lookAt(S, S + F0))
	b.model.Parent = workspace
	wingPose(b, 0, 0)

	-- the darkness heaped at her feet, swelling and fading
	local gloom = {}
	local grng = Random.new(77)
	for _ = 1, 14 do
		local a, r = grng:NextNumber(0, 6.3), grng:NextNumber(1.2, 3.6)
		local q = S + V3(math.cos(a) * r, grng:NextNumber(0, 2.5), math.sin(a) * r)
		local s = grng:NextNumber(2, 4.5)
		local tr = grng:NextNumber(0.5, 0.75)
		local p = Instance.new("Part")
		p.Name, p.Shape, p.Size, p.CFrame = "OssariaGloom", Enum.PartType.Ball, Vector3.one * s, CFrame.new(q)
		p.Material, p.Color, p.Transparency = MAT.SmoothPlastic, C3(4, 4, 6):Lerp(C3(24, 12, 30), grng:NextNumber(0, 0.5)), tr
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Parent = b.model.Parent
		TweenService:Create(p, TweenInfo.new(grng:NextNumber(3, 7), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, grng:NextNumber(0, 3)), { Size = Vector3.one * s * 1.3, Transparency = math.min(0.95, tr + 0.15) }):Play()
		table.insert(gloom, p)
	end

	-- her bonfire, hidden under her till she goes
	local bf = O.Bonfire
	local shown = {}
	for _, d in ipairs(bf.Model:GetDescendants()) do
		if d:IsA("BasePart") then
			shown[d] = { d.Transparency, d.CanCollide }
			d.Transparency, d.CanCollide = 1, false
		end
	end
	bf.Glow.Enabled, bf.Prompt.Enabled = false, false
	local function revealBonfire(quick)
		for d, v in pairs(shown) do
			d.CanCollide = v[2]
			if quick then
				d.Transparency = v[1]
			else
				TweenService:Create(d, TweenInfo.new(1.6), { Transparency = v[1] }):Play()
			end
		end
		bf.Glow.Enabled = not bf.Lit
		bf.Prompt.Enabled = true
		if not quick then
			bf.Sparks:Emit(40)
		end
	end

	-- where she comes down at the end, and waits: the middle of the Silver Knight's sand (Map.Champion), her back to the
	-- way in (the road comes from the east). He's gone from it the moment she starts to speak.
	local Champion = Core.Roster.byKind.Champion
	local AR = Map.Champion.Centre
	local FA = V3(-1, 0, 0)
	local function scar() -- (rot burnt into the sand where she hit)
		local p = Instance.new("Part")
		p.Name, p.Shape, p.Size = "OssariaScar", Enum.PartType.Cylinder, V3(0.08, 22, 22)
		p.CFrame = CFrame.new(AR + V3(0, 0.05, 0)) * CFrame.Angles(0, 0, math.pi / 2)
		p.Material, p.Color, p.Transparency = MAT.SmoothPlastic, C3(22, 14, 28), 0.2
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Parent = workspace
	end

	-- "waiting" | "meeting" | "arena" (come down on the sand, waiting there) | "challenge" | "challenged" (her husk's
	-- fight) | "reveal" | "heir" (her own fight: Characters/OssariaHeir) | "dead"
	local state = "waiting"
	-- on the sand, walk up to her and challenge her (the challenge itself: challenge, below). On her body: made again
	-- with it (recloak)
	local prompt, challenge
	local function addPrompt()
		local promptAt = Instance.new("Attachment")
		promptAt.Position = V3(0, 5, 0)
		promptAt.Parent = b.root
		prompt = Instance.new("ProximityPrompt")
		prompt.ActionText, prompt.ObjectText = "Challenge", C.Name
		prompt.HoldDuration, prompt.MaxActivationDistance, prompt.RequiresLineOfSight = 0.6, 16, false
		prompt.Enabled = false
		prompt.Parent = promptAt
		prompt.Triggered:Connect(function(pl)
			local char, _, hrp = Core.aliveChar(pl)
			if state == "arena" and char and Core.states[pl] then
				challenge(pl, Core.states[pl], char, hrp)
			end
		end)
	end
	addPrompt()

	local fell = false -- (the Heights are down, on this server: there's no putting them back up)
	local function gone() -- (a save she's left the court in: she's already waiting in the ruined colosseum)
		fell = true
		prompt.Enabled = true
		pcall(Champion.vanish)
		for _, g in ipairs(gloom) do
			g:Destroy()
		end
		revealBonfire(true)
		HeightsRuin.fall(Core, true) -- (her slash, as it left the Heights)
		wingShow(b, 1)
		scar()
		O.Arena = AR
		state = "arena"
	end
	Save.on("OssariaFled", gone)

	-- the meeting: S her spot, P0 where you stood when she spoke; d from her to you
	local function meet(player, st, char, hrp)
		state = "meeting"
		pcall(Champion.vanish) -- (nothing of his in the way of what's coming)
		local now = Core.now
		local V, look = Vector3.new, CFrame.lookAt
		local P0 = hrp.Position
		local d = flat(P0 - S)
		d = d.Magnitude > 0.1 and d.Unit or V(1, 0, 0)
		local side = V(-d.Z, 0, d.X)
		local Hh = S + V(0, 8.6, 0)
		local L = O.Landing.Position
		local H0 = S + d * 1.5 + V(0, 4.6, 0) -- (where she hangs, wings out)
		local Q = P0 + side * 5 + V(0, 3, 0) -- (by you, low over your shoulder)
		local Fp = V(L.X, S.Y + 12, L.Z) -- (the pit's foot, over the landing)
		local U = V(L.X, O.Top + 25, L.Z) -- (up it and gone)
		local ctrl = Q * 2 - (H0 + Fp) / 2 -- (a curve from H0 through Q to Fp)
		local hood = b.hood
		-- then out over the colosseum's mountain: round the Gilded Heights (a ring RC out, 100 over its paving), up over the
		-- hole (Hv), and the slash that brings it all down (HeightsRuin); Cg the colosseum's middle on its floor
		local Fn = Map.Wilds.Funnel
		local Cc = V(Fn.Centre.X, Fn.Top, Fn.Centre.Z)
		local Cg = V(Fn.Centre.X, Map.Wilds.Y, Fn.Centre.Z)
		local RC, TH0, SWEEP = 175, math.rad(45), math.rad(300)
		-- (the Ballroom stands on its own island right on that ring, its spires to ~160 over the paving: she climbs up over
		-- them as she comes round to it, and back down after)
		local BB = Map.Heights and Map.Heights.Ballroom and Map.Heights.Ballroom.Centre
		local thBall = BB and math.atan2(BB.Z - Cc.Z, BB.X - Cc.X)
		local HB = BB and BB.Y - Cc.Y + 108 or 100 -- (the floor + 83 to its spire's tip, + 25 clear)
		local function ring(th)
			local lift = 0
			if BB then
				local dd = math.deg(math.abs((th - thBall + math.pi) % (2 * math.pi) - math.pi))
				lift = dd < 22 and 1 or dd < 75 and smooth((75 - dd) / 53) or 0
			end
			return Cc + V(math.cos(th) * RC, 100 + (HB - 100) * lift, math.sin(th) * RC)
		end
		local function tang(th)
			return V(-math.sin(th), 0, math.cos(th))
		end
		local function outw(th)
			return V(math.cos(th), 0, math.sin(th))
		end
		local function bez(a, c, e, u)
			return a * (1 - u) ^ 2 + c * (2 * u * (1 - u)) + e * u * u
		end
		local thA, thB = TH0 + SWEEP * 2.5 / 10.5, TH0 + SWEEP -- (where she is round the ring as the chase shot starts, ends)
		local R0 = ring(TH0)
		local ctrlA = R0 - tang(TH0) * 120
		local E0 = ctrlA - tang(TH0) * 140 + V(0, -40, 0)
		local Hv = Cc + V(0, 120, 0) -- (over the hole, high)
		local Ks = Cc + V(230, 30, -200) -- (the slash, seen from far off)
		local fwd = flat(Ks - Hv).Unit
		local fside = V(-fwd.Z, 0, fwd.X)
		local DROP = Hv + V(0, 10, 0) - fwd * 10 -- (where the yank throws her back to, and she hangs, before she drops onto the sand)
		-- the attack, slow: she casts her strings onto the Heights (G0), pulls them taut (SL0), yanks (IMP), and the Heights
		-- come down over FALL_DUR (HeightsRuin, slow) while she hangs there; D0 a close look at her face as the night comes
		-- down (and the ruin's put in, off camera), CU long; DD she drops for the sand
		local G0, SL0, IMP, FALL_DUR, CU = 68, 74, 77.5, 12, 3.5
		local D0 = IMP + FALL_DUR
		local DD = D0 + CU
		local threads = {} -- (her strings: { beam, anchor, at })
		local ballShot = { -fwd * 6 + fside * 5 + V(0, 2, 0), -fwd * 9 + fside * 6 + V(0, 5, 0), 2, hood, V(0, -8, 0), true } -- (no Ballroom: her, longer)
		if BB then -- the Ballroom going, its island and all: from off its side
			local ob = V(math.cos(thBall), 0, math.sin(thBall))
			local sb = V(-ob.Z, 0, ob.X)
			ballShot = { look(BB + ob * 95 + sb * 40 + V(0, 12, 0), BB + V(0, 28, 0)), look(BB + ob * 90 + sb * 30 + V(0, 8, 0), BB + V(0, 10, 0)), 2 }
		end
		local shots = {
			{ look(P0 + d * 8 + side * 4 + V(0, 4.5, 0), S + V(0, 5, 0)), look(P0 + d * 6.5 + side * 3.5 + V(0, 4, 0), S + V(0, 5.5, 0)), 4.5 }, -- behind you: her back
			{ look(S + side * 12 + d * 3 + V(0, 5, 0), S + V(0, 6, 0)), look(S + side * 10 + d * 5 + V(0, 5.5, 0), S + V(0, 6.5, 0)), 5 }, -- side on, as she turns
			{ look(S + d * 5 + side * 1.2 + V(0, 8.2, 0), Hh), look(S + d * 4 + side * 0.6 + V(0, 8.4, 0), Hh), 6 }, -- her hood, close
			{ look(S - d * 3 + side * 2.5 + V(0, 9.5, 0), P0 + V(0, 1.5, 0)), look(S - d * 3.5 + side * 1.5 + V(0, 9.8, 0), P0 + V(0, 1.5, 0)), 6 }, -- over her shoulder, down at you
			{ look(S + d * 14 - side * 7 + V(0, 1.5, 0), S + V(0, 6, 0)), look(S + d * 12 - side * 5 + V(0, 1.2, 0), S + V(0, 6.5, 0)), 6 }, -- low and wide, as she drifts nearer
			{ look(S + d * 5.5 - side * 1 + V(0, 5.5, 0), Hh + d * 1.5), look(S + d * 5 + V(0, 5.8, 0), Hh + d * 1.5), 5 }, -- up at her hood
			{ look(S + d * 12 + side * 3 + V(0, 4, 0), S + V(0, 6, 0)), look(S + d * 13 + side * 3.5 + V(0, 4.5, 0), S + V(0, 6, 0)), 2.5 }, -- wide: "convenient"
			{ look(S - d * 19 + side * 6 + V(0, 8, 0), S + V(0, 9, 0)), look(S - d * 22 + side * 7 + V(0, 10, 0), S + V(0, 11, 0)), 5 }, -- behind her: the wings split out
			{ P0 + d * 3 - side * 2.5 + V(0, 3.5, 0), P0 + d * 2 - side * 3.5 + V(0, 3, 0), 3.5, hood }, -- by you, as she comes past
			{ V(L.X - 12.5, S.Y + 5, L.Z - 12), V(L.X - 11.5, S.Y + 4.5, L.Z - 11), 3.5, hood }, -- the pit's foot: up and gone
			{ look(Cc + V(250, 40, -260), Cc + V(0, 50, 0)), look(Cc + V(225, 48, -235), Cc + V(0, 55, 0)), 6 }, -- the Heights, far off: she comes in over them
			{ -tang(thA) * 22 + outw(thA) * 10 + V(0, 7, 0), tang(thB) * 17 + outw(thB) * 17 + V(0, 3, 0), 8, hood, V(0, -1, 0), true }, -- after her, round them
			{ look(Cc + V(150, 70, -130), Hv + V(0, 5, 0)), look(Cc + V(130, 82, -110), Hv + V(0, 6, 0)), 2.5 }, -- up, over the hole
			{ fwd * 4.6 + fside * 1 + V(0, 0.4, 0), fwd * 3.3 + V(0, 0.15, 0), 4.5, hood, V(0, -0.2, 0), true }, -- her hood: a beat
			{ look(Cg + V(14, 4, 10), Hv + V(0, 4, 0)), look(Cg + V(11, 3.5, 8), Hv + V(0, 9, 0)), 3.2 }, -- from the sand, far under her: up through the hole, her strings flying out
			{ fside * 7 + fwd * 2.5 + V(0, 1, 0), fside * 5.5 + fwd * 2 + V(0, 2.5, 0), 2.8, hood, V(0, -1, 0), true }, -- close, side on: still casting
			{ look(Ks, Cc + V(0, 55, 0)), look(Ks + V(-14, -6, 14), Cc + V(0, 52, 0)), 3.5 }, -- far off: all of it strung, the strings drawn taut - the yank
			{ look(Cg + V(-22, 3, -18), Cc + V(0, 10, 0)), look(Cg + V(-26, 2.5, -21), Cc + V(0, 28, 0)), 4 }, -- from the sand: the bridge and the hole's rim coming down
			{ look(Ks + V(30, 25, -25), Cc + V(0, 20, 0)), look(Ks + V(15, 15, -12), Cc + V(0, 5, 0)), 4 }, -- far off: ring after ring of it going
			ballShot,
			{ -fwd * 9 + fside * 3 + V(0, 4, 0), -fwd * 13 + fside * 4 + V(0, 7, 0), 2, hood, V(0, -8, 0), true }, -- behind her, down past her into the dust
			{ fwd * 2.8 + fside * 0.7 + V(0, -0.9, 0), fwd * 2.2 + fside * 0.3 + V(0, -0.6, 0), CU, hood, V(0, 0.1, 0), true }, -- her face, close, a little from under: the sky going dark behind her
			{ look(AR + V(62, 58, -46), AR + V(0, 4, 0)), look(AR + V(50, 48, -37), AR + V(0, 2, 0)), 2.6 }, -- down into the colosseum, over its wall
			{ look(AR + V(-24, 5, 14), AR + V(0, 8, 0)), look(AR + V(-19, 6, 11), AR + V(0, 9, 0)), 4.4 }, -- up off the sand, wings wide
			{ look(S + d * 11 + side * 5 + V(0, 6, 0), S + V(0, 1.5, 0)), look(S + d * 9 + side * 4 + V(0, 5, 0), S + V(0, 1.5, 0)), 5 }, -- what she left
		}
		local total = 0
		for _, sh in ipairs(shots) do
			total += sh[3]
		end
		-- you, held where you stood, turned to her
		local function alive()
			return hrp.Parent and player.Character == char
		end
		Core.setAction(st, now(), total, total, total)
		st.iStart, st.iEnd = now(), now() + total + 0.5
		st.healing = false
		Core.cancelSwing(st)
		hrp.AssemblyLinearVelocity = V()
		hrp.Anchored = true
		char:PivotTo(look(P0, V(S.X, P0.Y, S.Z)))
		FxRemote:FireClient(player, "Grabbed", total)
		FxRemote:FireClient(player, "Cutscene", shots)
		local function bp(name, blend)
			if alive() then
				char:SetAttribute("BP", name)
				char:SetAttribute("BPT", blend)
				char:SetAttribute("BPN", (char:GetAttribute("BPN") or 0) + 1)
			end
		end
		local function say(line)
			FxRemote:FireClient(player, "Say", C.Name, line)
		end
		local events = {
			{ 1.5, function() say(C.Lines[1]) end },
			{ 5.5, function() say(C.Lines[2]) end },
			{ 10, function() say(C.Lines[3]) end },
			{ 16, function() say(C.Lines[4]) end },
			{ 22, function() say(C.Lines[5]) end },
			{ 28, function() say(C.Lines[6]) end },
			{ 33, function() say(C.Lines[7]) end },
			{ 35.2, function() -- the wings split out: a crack, dark bursting off her
				Core.playSound(b.root, Core.SOUNDS.WatchdogSmash, 0.9, 0.45)
				Core.playSound(b.root, Core.SOUNDS.Lunge, 1, 0.5)
				Core.burst(S + V(0, 7, 0), C3(20, 12, 26), 40, 0.6, 18)
				Core.dustCloud(S + V(0, 6, 0), 5, 18)
				b.aura.Rate = 40
				FxRemote:FireClient(player, "Shake", S, 0.8)
			end },
			{ 35.4, function() bp("Flinch", 0.15) end },
			{ 37, function() bp("Idle", 0.8) end },
			{ 37.5, function() -- the dark at her feet lets her go
				for _, g in ipairs(gloom) do
					TweenService:Create(g, TweenInfo.new(1.8), { Transparency = 1 }):Play()
				end
			end },
			{ 40, function() Core.playSound(b.root, Core.SOUNDS.Lunge, 1, 0.35) end },
			{ 41, function() say(C.Parting) end },
			{ 43.5, function() Core.playSound(b.root, Core.SOUNDS.Lunge, 1, 0.3) end },
			{ 47, function() -- out under the sky: a dark wake behind her, so she reads against it
				local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
				a0.Position, a1.Position = V(0, 9.5, 0.5), V(0, 2, 0.5)
				a0.Parent, a1.Parent = b.root, b.root
				local tr = Instance.new("Trail")
				tr.Attachment0, tr.Attachment1 = a0, a1
				tr.Color = ColorSequence.new(C3(40, 22, 52), C3(8, 6, 10))
				tr.Transparency = NumberSequence.new(0.35, 1)
				tr.Lifetime, tr.LightEmission, tr.FaceCamera = 0.4, 0, true -- (short: a wake off her, not a streak a hundred studs back)
				tr.Enabled = false -- (not till she's out there: no streak from the pit's top to it)
				tr.Parent = b.root
				b.trail = tr
				task.delay(0.2, function()
					tr.Enabled = true
				end)
				b.aura.Rate = 30
			end },
			{ 50.5, function() Core.playSound(b.root, Core.SOUNDS.Lunge, 1, 0.3) end },
			{ 56, function() Core.playSound(b.root, Core.SOUNDS.Lunge, 1, 0.28) end },
			{ 61.2, function() Core.playSound(b.root, Core.SOUNDS.Lunge, 1, 0.35) end },
			{ 65.6, function() -- the glints behind her veil, burning
				for _, g in ipairs(b.model:GetDescendants()) do
					if g.Name == "Glint" then
						g.Transparency, g.Color = 0, C3(210, 160, 255)
						TweenService:Create(g, TweenInfo.new(1.2), { Size = Vector3.one * 0.22 }):Play()
					end
				end
			end },
			{ G0, function() -- she casts her strings: one after another out of her hands, down onto every spire and roof of the Heights
				b.aura.Rate = 70
				Core.playSound(b.root, Core.SOUNDS.Impact, 1, 0.3)
				local hands = {}
				for _, p in ipairs(b.model:GetChildren()) do
					if p.Name == "Hand" then
						local a = p:FindFirstChild("StringFrom") or Instance.new("Attachment")
						a.Name, a.Position = "StringFrom", V3(0, -0.9, 0)
						a.Parent = p
						table.insert(hands, a)
					end
				end
				-- what they catch on: the highest thing in each slice of the Heights, near ring and far
				local tops = {}
				for _, p in ipairs(Map.Heights.Folder:GetDescendants()) do
					if p:IsA("BasePart") and p.Transparency < 1 then
						local o = V(p.Position.X - Cc.X, 0, p.Position.Z - Cc.Z)
						local r = o.Magnitude
						if r > 40 then
							local key = math.floor((math.atan2(o.Z, o.X) + math.pi) / (2 * math.pi) * 24) + (r > 125 and 100 or 0)
							local top = p.Position + V(0, p.Size.Y / 2, 0)
							if not tops[key] or top.Y > tops[key].Y then
								tops[key] = top
							end
						end
					end
				end
				local list = {}
				for _, t in pairs(tops) do
					table.insert(list, t)
				end
				local srng = Random.new(91)
				for i = #list, 2, -1 do
					local j = srng:NextInteger(1, i)
					list[i], list[j] = list[j], list[i]
				end
				local CAST = (SL0 - G0) - 0.6
				for i, target in ipairs(list) do
					task.delay((i - 1) / #list * CAST, function()
						local from = hands[i % #hands + 1]
						if not from then
							return
						end
						local anchor = Instance.new("Attachment")
						anchor.Position = from.WorldPosition
						anchor.Parent = workspace.Terrain
						local beam = Instance.new("Beam")
						beam.Attachment0, beam.Attachment1 = from, anchor
						beam.Width0, beam.Width1, beam.Segments, beam.FaceCamera = 0.1, 1.1, 1, true
						beam.Color = ColorSequence.new(C3(150, 120, 190))
						beam.LightEmission, beam.Transparency = 0.6, NumberSequence.new(0.25)
						beam.Parent = workspace.Terrain
						TweenService:Create(anchor, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = target }):Play()
						task.delay(0.35, function()
							Core.burst(target, C3(150, 120, 190), 8, 0.4, 8)
						end)
						if i % 6 == 1 then
							Core.playSound(b.root, Core.SOUNDS.Lunge, 0.5, 0.9 + srng:NextNumber(0, 0.3))
						end
						table.insert(threads, { beam = beam, anchor = anchor, at = target })
					end)
				end
			end },
			{ G0 + 2, function()
				Core.playSound(b.root, Core.SOUNDS.Impact, 1, 0.25)
				FxRemote:FireClient(player, "Shake", hrp.Position, 0.4)
			end },
			{ G0 + 4, function()
				Core.playSound(b.root, Core.SOUNDS.WatchdogSmash, 0.6, 0.3)
				FxRemote:FireClient(player, "Shake", hrp.Position, 0.7)
			end },
			{ SL0, function() -- she pulls: every string drawn taut and thrumming, and the whole of the Heights groaning on them
				Core.playSound(b.root, Core.SOUNDS.Lunge, 1, 0.4)
				for _, th in ipairs(threads) do
					th.beam.Color = ColorSequence.new(C3(200, 160, 245))
					TweenService:Create(th.beam, TweenInfo.new(IMP - SL0, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Width1 = 1.8, Width0 = 0.16 }):Play()
				end
				local stopAt, jr = os.clock() + (IMP - SL0), Random.new(17)
				task.spawn(function()
					while os.clock() < stopAt do
						local k = 1 - (stopAt - os.clock()) / (IMP - SL0)
						for _, th in ipairs(threads) do
							th.anchor.Position = th.at + V(jr:NextNumber(-1, 1), jr:NextNumber(-1, 1), jr:NextNumber(-1, 1)) * (0.15 + 0.5 * k)
						end
						task.wait(0.05)
					end
				end)
			end },
			{ SL0 + 1.7, function()
				Core.playSound(b.root, Core.SOUNDS.WatchdogSmash, 0.7, 0.3)
				FxRemote:FireClient(player, "Shake", hrp.Position, 0.6)
			end },
			{ IMP, function() -- the yank: the strings flare, and snap, and it all comes down after them
				FxRemote:FireClient(player, "Flash", C3(220, 200, 255), 1.4, 0.12)
				FxRemote:FireClient(player, "Shake", hrp.Position, 1.6)
				Core.playSound(b.root, Core.SOUNDS.WatchdogSmash, 1, 0.35)
				Core.playSound(b.root, Core.SOUNDS.Impact, 1, 0.4)
				Core.playSound(b.root, Core.SOUNDS.Lunge, 1, 0.6)
				b.aura.Rate = 30
				fell = true
				Save.mark("OssariaFled")
				local snap = threads
				threads = {}
				for _, th in ipairs(snap) do
					th.beam.Color = ColorSequence.new(C3(240, 225, 255))
					th.beam.Width0, th.beam.Width1 = 0.3, 2.6
				end
				task.spawn(function()
					task.wait(0.15)
					for k = 1, 10 do
						for _, th in ipairs(snap) do
							th.beam.Transparency = NumberSequence.new(0.25 + 0.075 * k)
							th.beam.Width0 = th.beam.Width0 * 0.85
						end
						task.wait(0.05)
					end
					for _, th in ipairs(snap) do
						th.beam:Destroy()
						th.anchor:Destroy()
					end
				end)
				task.spawn(function() -- (it waits on the terrain: not in her motion's thread)
					local ok, err = pcall(HeightsRuin.fall, Core, false, FALL_DUR)
					if not ok then
						warn("[DGUS] HeightsRuin.fall: " .. tostring(err))
					end
				end)
			end },
			{ IMP + 2.5, function()
				Core.playSound(b.root, Core.SOUNDS.WatchdogSmash, 0.8, 0.3)
				FxRemote:FireClient(player, "Shake", hrp.Position, 0.9)
			end },
			{ IMP + 5.5, function()
				Core.playSound(b.root, Core.SOUNDS.Impact, 1, 0.3)
				FxRemote:FireClient(player, "Shake", hrp.Position, 0.8)
			end },
			{ IMP + 8, function()
				Core.playSound(b.root, Core.SOUNDS.WatchdogSmash, 1, 0.25)
				FxRemote:FireClient(player, "Shake", hrp.Position, 1)
			end },
			{ D0 - 1.5, function() HeightsRuin.night(false, 7) end }, -- (half dark by her close-up)
			{ D0 + 0.4, function() HeightsRuin.settle() end }, -- (the ruin put in while the camera's on her face, not the colosseum)
			{ DD, function() Core.playSound(b.root, Core.SOUNDS.Lunge, 1, 0.3) end },
			{ DD + 2.2, function() -- down into the middle of the colosseum's sand
				Core.playSound(b.root, Core.SOUNDS.WatchdogSmash, 1, 0.4)
				Core.playSound(b.root, Core.SOUNDS.Impact, 1, 0.5)
				Core.shockwave(AR, 26)
				Core.dustCloud(AR + V(0, 2, 0), 16, 30)
				Core.burst(AR + V(0, 4, 0), C3(20, 12, 26), 50, 0.8, 24)
				FxRemote:FireClient(player, "Shake", hrp.Position, 1.2)
				scar()
				if b.trail then
					b.trail.Enabled = false
				end
				b.aura.Rate = 12
				O.Arena = AR
			end },
			{ DD + 7.05, function() -- and where she stood below, a bonfire
				for _, g in ipairs(gloom) do
					g:Destroy()
				end
				revealBonfire(false)
			end },
		}
		-- THE SHOW OF IT, over the beats above: the court's floor veined with her light and thrown up as the wings split
		-- out, the dark at her feet blown off her; dust dragged up the pit after her; the dark shed off her wings in
		-- flight, and the air shaken as she tears past; the sand veined where she comes down - and her name
		local function shakeYou(k)
			FxRemote:FireClient(player, "Shake", hrp.Position, k)
		end
		for _, e in ipairs({
			{ 35.21, function()
				Core.fadeAway(Core.crackLines(S + V(0, 0.15, 0), 16, 9, C3(150, 110, 200), MAT.Neon, 0.6), 6, 2)
				Core.debrisChunks(S, 10, 22)
				FxRemote:FireClient(player, "Flash", C3(0, 0, 0), 0.4, 0.06)
				for _, g in ipairs(gloom) do
					local out = flat(g.Position - S)
					TweenService:Create(g, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = g.Position + (out.Magnitude > 0.1 and out.Unit or d) * 7 + V(0, 2, 0) }):Play()
				end
			end },
			{ 37.6, function()
				for i = 1, 8 do
					Core.dustCloud(S + V(math.cos(i * 0.785) * 6, 0.5, math.sin(i * 0.785) * 6), 3, 5)
				end
			end },
			{ 40.05, function()
				Core.burst(H0 + V(0, 4, 0), C3(20, 12, 26), 40, 0.8, 26)
				Core.dustCloud(S + V(0, 1, 0), 8, 24)
				shakeYou(0.9)
			end },
			{ 43.6, function()
				Core.dustCloud(Fp - V(0, 9, 0), 10, 30)
				shakeYou(0.7)
			end },
			{ 46.9, function() O.Away = true end }, -- (the camera's out under the sky from here: init.server lifts her court's air off you)
			{ 47.05, function()
				b.aura.LockedToPart = true -- (the dark off her goes with her now, not left hanging where she was)
				for _, pe in ipairs(b.shed) do
					pe.Enabled = true
				end
			end },
			{ DD + 6.95, function() O.Away = nil end }, -- (and back down in her court, for the last look at it)
			{ 52, function() shakeYou(0.35) end },
			{ 55, function() shakeYou(0.35) end },
			{ 58.4, function() shakeYou(0.4) end },
			{ 63.6, function()
				Core.burst(Hv + V(0, 6, 0), C3(20, 12, 26), 50, 0.9, 30)
				shakeYou(0.5)
			end },
			-- THE HEIGHTS COMING DOWN, and the size of it: a ring of the blast out over the land from the yank; the sky lit
			-- by it again and again; the ground never still under you for the whole of the fall; pieces of the Heights
			-- coming down onto the colosseum's own sand round the camera while it's on that sand; and then, seen from
			-- far off, plumes of dust the size of halls going up all round where it stood
			{ IMP + 0.03, function()
				local ring = Instance.new("Part")
				ring.Name, ring.Shape = "HeightsBlast", Enum.PartType.Cylinder
				ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch, ring.CastShadow = true, false, false, false, false
				ring.Material, ring.Color, ring.Transparency = MAT.Neon, C3(206, 186, 240), 0.55
				ring.Size, ring.CFrame = V(3, 30, 30), CFrame.new(Cc + V(0, 6, 0)) * CFrame.Angles(0, 0, math.pi / 2)
				ring.Parent = workspace
				TweenService:Create(ring, TweenInfo.new(4.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = V(0.5, 1000, 1000), Transparency = 1 }):Play()
				game:GetService("Debris"):AddItem(ring, 4.6)
				for i = 1, 16 do -- (the ground, all the way through it)
					task.delay(i * 0.7, function()
						FxRemote:FireClient(player, "Shake", hrp.Position, 0.45)
					end)
				end
				for _, at in ipairs({ 2.5, 5.5, 8 }) do -- (the sky)
					task.delay(at, function()
						FxRemote:FireClient(player, "Flash", C3(200, 170, 255), 0.6, 0.04)
					end)
				end
			end },
			{ IMP + 0.6, function()
				local camAt = Cg + V(-22, 3, -18) -- (that shot's camera: nothing lands on it)
				for i = 1, 14 do
					task.delay(i * 0.26, function()
						local p
						repeat
							p = Cg + V(rnd(-48, 48), 0, rnd(-48, 48))
						until flat(p - camAt).Magnitude > 13
						local sz = rnd(5, 12)
						local rock = Instance.new("Part")
						rock.Name, rock.Size = "HeightsPiece", V(sz, sz * rnd(0.4, 0.9), sz * rnd(0.6, 1))
						rock.Material, rock.Color = MAT.Limestone, C3(200, 188, 160):Lerp(C3(150, 124, 66), rnd(0, 0.5))
						rock.Anchored, rock.CanCollide, rock.CanQuery, rock.CanTouch = true, false, false, false
						rock.CFrame = CFrame.new(p + V(rnd(-20, 20), 150, rnd(-20, 20))) * CFrame.Angles(rnd(0, 6), rnd(0, 6), 0)
						rock.Parent = workspace
						TweenService:Create(rock, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.new(p + V(0, sz * 0.2, 0)) * CFrame.Angles(rnd(0, 6), rnd(0, 6), rnd(-0.3, 0.3)) }):Play()
						task.wait(1.1)
						Core.shockwave(p, sz * 0.8)
						Core.playSound(rock, Core.SOUNDS.WatchdogSmash, 1, rnd(0.4, 0.7))
						FxRemote:FireClient(player, "Shake", hrp.Position, rnd(0.5, 1))
						game:GetService("Debris"):AddItem(rock, 9) -- (gone, with the camera away, before it's back on this sand for her landing)
					end)
				end
			end },
			{ IMP + 4.1, function()
				for i = 0, 9 do
					task.delay(i * 0.38, function()
						local a = i / 10 * math.pi * 2 + 0.3
						Core.dustCloud(Cc + V(math.cos(a) * rnd(90, 190), -8, math.sin(a) * rnd(90, 190)), 42, 26)
					end)
				end
			end },
			{ DD + 2.21, function()
				Core.fadeAway(Core.crackLines(AR + V(0, 0.15, 0), 30, 11, C3(150, 110, 200), MAT.Neon, 1.2), 10, 3)
				Core.debrisChunks(AR, 16, 34)
				FxRemote:FireClient(player, "Flash", C3(225, 205, 255), 0.9, 0.05)
				b.aura.LockedToPart = false
				for _, pe in ipairs(b.shed) do
					pe.Enabled = false
				end
			end },
			{ DD + 3.9, function()
				FxRemote:FireClient(player, "Banner", "OSSARIA\nExiled Heir", "Area")
			end },
		}) do
			table.insert(events, e)
		end
		table.sort(events, function(x, y)
			return x[1] < y[1]
		end)
		task.spawn(function()
			local t0, ev = os.clock(), 1
			local a0, a1 = math.atan2(F0.Z, F0.X), math.atan2(d.Z, d.X)
			local da = (a1 - a0 + math.pi) % (2 * math.pi) - math.pi
			local lastDir = d
			local fly = { t = 0, flap = 0, flapB = 0, lean = 0, bank = 0, dir = d }
			while true do
				local t = os.clock() - t0
				while events[ev] and t >= events[ev][1] do
					pcall(events[ev][2])
					ev += 1
				end
				if t >= total then
					break
				end
				if b.model.Parent then
					local pos, dir = S, F0
					local unfold, flap, roll = 0, 0, 0
					local bob = math.sin(t * 0.9) * 0.12
					if t < 4.5 then
						pos = S + V(0, bob, 0)
					elseif t < 9 then
						local a = a0 + da * smooth((t - 4.5) / 4.5)
						pos, dir = S + V(0, bob, 0), V(math.cos(a), 0, math.sin(a))
					elseif t < 35.2 then
						local k = smooth((t - 21.5) / 6) -- (she drifts a little nearer as she speaks)
						pos, dir = S + d * 1.5 * k + V(0, 0.6 * k + bob, 0), d
					elseif t < 40 then
						unfold = smooth((t - 35.2) / 2.8)
						wingShow(b, math.clamp((t - 35.2) / 1.3, 0, 1))
						local beat = math.clamp((t - 37) / 1, 0, 1)
						flap = beat * math.rad(28) * math.sin((t - 37) * 5)
						pos, dir = S + d * 1.5 + V(0, 0.6 + 4 * smooth((t - 37.5) / 2.5), 0), d
					elseif t < 43.5 then
						unfold = 1
						local u = smooth((t - 40) / 3.5)
						pos = H0 * (1 - u) ^ 2 + ctrl * (2 * u * (1 - u)) + Fp * u * u
						local nxt = H0 * (1 - u - 0.01) ^ 2 + ctrl * (2 * (u + 0.01) * (1 - u - 0.01)) + Fp * (u + 0.01) ^ 2
						local fd = flat(nxt - pos)
						if fd.Magnitude > 0.001 then
							lastDir = fd.Unit
						end
						dir = lastDir
						flap = math.rad(32) * math.sin(t * 9)
					elseif t < 47 then -- up the shaft, wings half drawn in (it's narrower than they are)
						unfold = 1 - 0.55 * smooth((t - 43.5) / 0.7)
						local u = math.clamp((t - 43.5) / 3.3, 0, 1)
						pos, dir = Fp + (U - Fp) * u * u, lastDir
						flap = math.rad(36) * math.sin(t * 12)
					elseif t < 50.5 then -- in over the Heights, onto the ring
						unfold = 1
						local u = (t - 47) / 3.5
						pos = bez(E0, ctrlA, R0, u)
						dir = flat(bez(E0, ctrlA, R0, math.min(u + 0.01, 1)) - pos)
						dir = (u >= 0.99 or dir.Magnitude < 0.001) and tang(TH0) or dir.Unit
						flap = math.rad(34) * math.sin(t * 8)
					elseif t < 61 then -- round them, banked in (and up over the Ballroom: ring)
						unfold = 1
						local th = TH0 + SWEEP * (t - 50.5) / 10.5
						pos, roll = ring(th), -0.4
						dir = (ring(th + 0.01) - pos).Unit
						flap = math.rad(30) * math.sin(t * 7)
					elseif t < 63.5 then -- up over the hole, turning to face out
						unfold = 1
						local u = smooth((t - 61) / 2.5)
						local r1 = ring(TH0 + SWEEP)
						pos = bez(r1, r1 + tang(TH0 + SWEEP) * 70 + V(0, 20, 0), Hv, u)
						dir = tang(TH0 + SWEEP):Lerp(fwd, u).Unit
						roll = -0.4 * (1 - u)
						flap = math.rad(38) * math.sin(t * 9)
					elseif t < G0 then -- hanging there; a beat
						unfold = 1
						pos, dir = Hv + V(0, math.sin(t * 1.6) * 0.5, 0), fwd
						flap = math.rad(22) * math.sin(t * 3.2)
					elseif t < SL0 then -- casting: rising slowly, wings spread, the strings going out of her hands
						unfold = 1
						local k = smooth((t - G0) / (SL0 - G0))
						pos, dir = Hv + V(0, 6 * k + math.sin(t * 1.6) * 0.5 * (1 - k), 0), fwd
						flap = math.rad(14) * math.sin(t * 2.4) * (1 - k) + math.rad(18) * k
					elseif t < IMP then -- pulling: leaning back against all of it, wings drawn back, straining, shaking
						unfold = 1
						local k = smooth((t - SL0) / (IMP - SL0))
						pos = Hv + V(0, 6 + 2 * k, 0) - fwd * 3 * k + V(math.sin(t * 31), math.sin(t * 27), math.cos(t * 29)) * 0.12 * k
						dir = fwd
						flap, roll = math.rad(18) - math.rad(60) * k + math.rad(3) * math.sin(t * 23) * k, 0
					elseif t < DD then -- the yank throws her back; then hanging there, watching it all come down
						unfold = 1
						local j = smooth(math.min((t - IMP) / 0.35, 1))
						local k = smooth((t - IMP) / 1.6)
						pos = (Hv + V(0, 8, 0) - fwd * 3):Lerp(DROP, j) + V(0, math.sin(t * 1.3) * 0.6 * k, 0)
						dir = fwd
						flap = math.rad(55) * (1 - k) + math.rad(20) * k * math.cos(t * 2.6)
					elseif t < DD + 2.2 then -- dropping, faster and faster, wings half in, down onto the sand
						local u = ((t - DD) / 2.2) ^ 2
						unfold = 1 - 0.5 * smooth((t - DD) / 0.6)
						pos = bez(DROP, AR + V(0, 90, 0), AR, u)
						dir = fwd:Lerp(FA, smooth((t - DD) / 2.2)).Unit
						flap = -math.rad(20)
					elseif t < DD + 3.6 then -- crouched in the dust of it, then rising, wings thrown wide
						local k = smooth((t - DD - 2.2) / 1.4)
						unfold = 0.5 + 0.5 * k
						pos, dir = AR + V(0, -1.4 * (1 - k), 0), FA
						flap = math.rad(40) * (1 - k) * math.sin(t * 6)
					else -- standing there; waiting
						local k = smooth((t - DD - 3.6) / 2)
						unfold = 1 - 0.3 * k
						pos, dir = AR + V(0, math.sin(t * 0.9) * 0.12, 0), FA
						flap = math.rad(6) * math.sin(t * 1.4)
					end
					-- HOW SHE FLIES, whichever leg of it that was: the outer half of each wing lags its inner half (a whip
					-- along it) and the wing twists against its own stroke; each downstroke lifts her; she leans into her
					-- flight by how fast she's going over the ground, and banks into her turns
					local dt = math.max(t - fly.t, 1 / 240)
					local rate = (flap - fly.flap) / dt
					fly.flapB += (flap * 1.15 - fly.flapB) * (1 - math.exp(-dt * 16))
					local vel = fly.pos and (pos - fly.pos) / dt or V()
					local turn = ((math.atan2(dir.Z, dir.X) - math.atan2(fly.dir.Z, fly.dir.X) + math.pi) % (2 * math.pi) - math.pi) / dt
					fly.lean += (math.clamp(flat(vel).Magnitude / 70, 0, 1) - fly.lean) * (1 - math.exp(-dt * 3))
					fly.bank += (math.clamp(-turn * 0.45, -0.5, 0.5) - fly.bank) * (1 - math.exp(-dt * 3))
					fly.t, fly.flap, fly.pos, fly.dir = t, flap, pos, dir
					pos -= V(0, flap * 0.9 * unfold, 0)
					b.root.CFrame = look(pos, pos + dir) * CFrame.Angles(-fly.lean, 0, roll + fly.bank)
					wingPose(b, unfold, flap, fly.flapB, math.clamp(-rate * 0.035, -0.45, 0.45) * unfold)
				end
				RunService.Heartbeat:Wait()
			end
			state = "arena"
			prompt.Enabled = true
			if alive() then
				bp("Idle", 0.3)
				hrp.Anchored = false
				pcall(function()
					hrp:SetNetworkOwner(player)
				end)
			end
		end)
	end

	-- THE LAST KNIGHT: Caelen, as she has him now - the Silver Knight's rig gone to rot, the steel corroded, swollen
	-- with growths, and his free arm rotted away below the pauldron (so no arm behind his back: he's his first phase,
	-- one sword). His body and his fight are the Silver Knight's own (Champion.huskSpawn / huskStart); this dresses it.
	local KS = Config.Champion.Scale
	local function dress(model)
		local ROT, FLESH = C3(54, 48, 44), C3(78, 62, 60)
		for _, p in ipairs(model:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				p.Color = p.Color:Lerp(ROT, 0.5)
				if p.Material == MAT.Metal then
					p.Material = MAT.CorrodedMetal
				end
			end
			if typeof(p:GetAttribute("Color")) == "Color3" then -- (his cape and plume: Carrier.cloth)
				p:SetAttribute("Color", p:GetAttribute("Color"):Lerp(C3(20, 14, 16), 0.55))
			end
		end
		-- the free arm: nothing left of it under the pauldron
		local gone = {}
		for _, n in ipairs({ "LUpperArm", "LLowerArm", "LHand" }) do
			gone[model[n]] = true
		end
		for _, w in ipairs(model:GetDescendants()) do
			if w:IsA("WeldConstraint") and gone[w.Part0] and not w.Part1.Name:find("^Pauldron") then
				w.Part1.Transparency = 1
			end
		end
		for p in pairs(gone) do
			p.Transparency = 1
		end
		-- the growths (balls of rot welded on), the stump, and her light behind his visor
		local function lump(on, size, off, color, mat, shape)
			local base = model[on]
			local p = Instance.new("Part")
			p.Name, p.Shape, p.Size = "Rot", shape or Enum.PartType.Ball, size
			p.Color, p.Material = color or FLESH, mat or MAT.Slate
			p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, true
			p.CFrame = base.CFrame * CFrame.new(off)
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = base, p
			w.Parent = p
			p.Parent = model
			return p
		end
		local ua, ch, hp, hd = model.LUpperArm.Size, model.Chest.Size, model.Hips.Size, model.Head.Size
		lump("LUpperArm", Vector3.one * ua.X * 1.35, V3(0, ua.Y * 0.28, 0))
		for i = 1, 3 do
			lump("LUpperArm", V3(ua.X * 0.25, ua.Y * (0.25 + i * 0.12), ua.X * 0.08), V3((i - 2) * ua.X * 0.3, ua.Y * (0.1 - i * 0.06), 0), C3(40, 30, 30), MAT.Fabric, Enum.PartType.Block)
		end
		lump("Chest", Vector3.one * ch.X * 0.34, V3(ch.X * 0.28, -ch.Y * 0.12, -ch.Z * 0.5))
		lump("Chest", Vector3.one * ch.X * 0.5, V3(-ch.X * 0.18, ch.Y * 0.28, ch.Z * 0.55), ROT)
		lump("RUpperArm", Vector3.one * ua.X * 1.1, V3(ua.X * 0.45, -ua.Y * 0.1, 0))
		lump("Hips", Vector3.one * hp.X * 0.3, V3(-hp.X * 0.32, 0, -hp.Z * 0.45))
		lump("Head", Vector3.one * hd.X * 0.55, V3(hd.X * 0.5, hd.Y * 0.4, 0.1 * KS), ROT) -- (the helm caved in on one side)
		for _, sx in ipairs({ -1, 1 }) do
			lump("Head", Vector3.one * 0.12 * KS, V3(sx * 0.2 * KS, 0.2 * KS, -0.66 * KS), C3(170, 120, 230), MAT.Neon)
		end
	end

	-- her strings: from her fingers down to his head, his shoulders, his sword hand and his knees (they go with him)
	local function strings(k)
		local hands = {}
		for _, p in ipairs(b.model:GetChildren()) do
			if p.Name == "Hand" then
				local a = p:FindFirstChild("StringFrom") or Instance.new("Attachment")
				a.Name, a.Position = "StringFrom", V3(0, -0.9, 0)
				a.Parent = p
				table.insert(hands, a)
			end
		end
		for i, on in ipairs({ "Head", "Chest", "RHand", "LUpperArm", "RShin", "LShin" }) do
			local part = k.model[on]
			local a = Instance.new("Attachment")
			a.Position = V3(0, part.Size.Y / 2, 0)
			a.Parent = part
			local beam = Instance.new("Beam")
			beam.Attachment0, beam.Attachment1 = hands[i % #hands + 1], a
			beam.Width0, beam.Width1, beam.Segments, beam.FaceCamera = 0.05, 0.05, 1, true
			beam.Color = ColorSequence.new(C3(150, 120, 190))
			beam.LightEmission, beam.Transparency = 0.6, NumberSequence.new(0.35)
			beam.Parent = part
		end
	end

	-- THE CHALLENGE: she peers round at you over her shoulder, speaks (C.Challenge), and draws back up into the air;
	-- the sand breaks over her scar and Caelen comes up out of it on her strings, his back to you, and turns round to
	-- face you, wrenching his sword out of the sand. Then the fight (Champion.huskStart). Nothing of it is saved yet.
	local hover -- { where she hangs over him, which way she faces }
	local knight -- (his actor, while he's up)
	local reveal -- (below: what she does when he falls)
	local hooks = {
		onReset = function() -- (everyone on the sand died: he's gone, and she's back on her scar, waiting)
			knight, O.ArenaBar = nil, nil
			state = "arena"
			prompt.Enabled = true
		end,
		onDied = function(at) -- (beaten: her strings cut, and she sheds the cloak: reveal)
			knight, O.ArenaBar = nil, nil
			reveal(at)
		end,
	}
	challenge = function(player, st, char, hrp)
		state = "challenge"
		prompt.Enabled = false
		local now = Core.now
		local V, look = V3, CFrame.lookAt
		local toYou = flat(hrp.Position - AR)
		toYou = toYou.Magnitude > 0.1 and toYou.Unit or -FA
		local side = V(-toYou.Z, 0, toYou.X)
		local P0 = V(AR.X, hrp.Position.Y, AR.Z) + toYou * 20 -- (you, set back from what's coming up between you)
		local Hh = AR + V(0, 8.6, 0)
		local HV = AR - toYou * 7 + V(0, 7, 0)
		local KP = AR + V(0, 3 * KS, 0) -- (his root, standing)
		local shots = {
			{ look(P0 + toYou * 6 + side * 3 + V(0, 5, 0), AR + V(0, 6, 0)), look(P0 + toYou * 4.5 + side * 2.5 + V(0, 4.5, 0), AR + V(0, 6.5, 0)), 3.5 }, -- behind you: her back, as she peers round
			{ look(AR + toYou * 5 + side * 1.2 + V(0, 8.4, 0), Hh), look(AR + toYou * 4 + side * 0.6 + V(0, 8.6, 0), Hh), 7 }, -- her hood, close, as she speaks
			{ look(AR + side * 20 + toYou * 6 + V(0, 3, 0), AR + V(0, 4, 0)), look(AR + side * 17 + toYou * 5 + V(0, 2.5, 0), AR + V(0, 6, 0)), 4.5 }, -- wide and low: she draws up, the sand breaks
			{ look(AR + toYou * 13 - side * 4 + V(0, 2, 0), AR + V(0, 7, 0)), look(AR + toYou * 11 - side * 3 + V(0, 2.5, 0), AR + V(0, 7.5, 0)), 3.5 }, -- low on him as he turns
			{ look(P0 + toYou * 4 + side * 5 + V(0, 6, 0), AR + V(0, 8, 0)), look(P0 + toYou * 6 + side * 6 + V(0, 8, 0), HV), 3.5 }, -- wide: him, and her over him on her strings
		}
		local total = 0
		for _, sh in ipairs(shots) do
			total += sh[3]
		end
		-- everyone on the sand held still; you set back where the shots expect you, turned to her
		local held = {}
		for _, pl in ipairs(Players:GetPlayers()) do
			local c, _, r = Core.aliveChar(pl)
			local s = Core.states[pl]
			if c and s and (pl == player or Champion.inArena(r.Position)) then
				held[pl] = r
				Core.setAction(s, now(), total, total, total)
				s.iStart, s.iEnd = now(), now() + total + 0.5
				s.healing = false
				Core.cancelSwing(s)
				r.AssemblyLinearVelocity = V()
				r.Anchored = true
				if pl == player then
					char:PivotTo(look(P0, V(AR.X, P0.Y, AR.Z)))
				end
				FxRemote:FireClient(pl, "Grabbed", total)
				FxRemote:FireClient(pl, "Cutscene", shots)
			end
		end
		ReplicatedStorage:SetAttribute("BossActive", false) -- (her bar off: his comes up at the end)
		local k -- the knight, once he's built (under the sand)
		local function kpose(grip, body, t)
			if grip then
				Core.pose(k, grip, t)
			end
			if body then
				Core.bodyPose(k, body, t)
			end
		end
		local TURN = { { 16.9, 1.0, 0.35 }, { 17.25, 2.0, 0.35 }, { 17.6, math.pi, 0.4 } } -- (start, his yaw off facing her, time)
		local events = {
			{ 4, function()
				for pl in pairs(held) do
					FxRemote:FireClient(pl, "Say", C.Name, C.Challenge)
				end
			end },
			{ 10.5, function() -- he's under the sand, kneeling, his hand on his planted sword
				k = Champion.huskSpawn(look(KP - V(0, 11, 0), KP - V(0, 11, 0) - toYou), dress, hooks)
				knight = k
				kpose("GPlant", "Kneel", 0.01)
			end },
			{ 10.8, function() -- the rumble
				Core.playSound(b.root, Core.SOUNDS.WatchdogSmash, 0.6, 0.3)
				for pl in pairs(held) do
					FxRemote:FireClient(pl, "Shake", AR, 0.6)
				end
			end },
			{ 12, function() -- the sand breaks
				Core.playSound(b.root, Core.SOUNDS.WatchdogSmash, 1, 0.4)
				Core.playSound(b.root, Core.SOUNDS.Impact, 1, 0.45)
				Core.debrisChunks(AR, 14, 30)
				Core.dustCloud(AR + V(0, 1, 0), 10, 26)
				Core.burst(AR + V(0, 2, 0), C3(20, 12, 26), 40, 0.7, 20)
				for pl in pairs(held) do
					FxRemote:FireClient(pl, "Shake", AR, 1.3)
				end
				strings(k)
			end },
			{ 12.8, function()
				for pl in pairs(held) do
					FxRemote:FireClient(pl, "Say", C.Name, C.Risen)
				end
			end },
			{ 13.6, function() kpose(nil, "CProud", 1.2) end }, -- hauled up off his knees as he comes
			{ 15.3, function() kpose(nil, "CPeer", 0.9) end }, -- his head round first
			{ 16.2, function() -- then his waist, wrenching the sword out of the sand
				kpose("GLow", "CPivot", 0.7)
				Core.playSound(k.root, Core.SOUNDS.Unsheath, 0.7, 0.3)
			end },
			{ 16.9, function() kpose(nil, "CStep1", 0.35) end },
			{ 17.25, function() kpose(nil, "CStep2", 0.35) end },
			{ 17.6, function() kpose(nil, "CGlare", 0.4) end },
		}
		local a0, a1 = math.atan2(FA.Z, FA.X), math.atan2(toYou.Z, toYou.X)
		local da = (a1 - a0 + math.pi) % (2 * math.pi) - math.pi
		hover = { HV, toYou }
		task.spawn(function()
			local t0, ev = os.clock(), 1
			while true do
				local t = os.clock() - t0
				while events[ev] and t >= events[ev][1] do
					local ok, err = pcall(events[ev][2])
					if not ok then
						warn("[DGUS] Ossaria's challenge: " .. tostring(err))
					end
					ev += 1
				end
				if t >= total then
					break
				end
				-- her: turned round to peer at you, leaning in; then drawn back and up over him, wings out
				local bob = math.sin(t * 0.9) * 0.12
				local u = smooth((t - 0.4) / 2.8)
				local a = a0 + da * u
				local dir = V(math.cos(a), 0, math.sin(a))
				local m = smooth((t - 10.8) / 2.2)
				local pos = AR:Lerp(HV, m) + V(0, bob, 0)
				b.root.CFrame = look(pos, pos + dir) * CFrame.Angles(-0.1 * u * (1 - m), 0, 0)
				wingPose(b, 0.7 + 0.3 * m, math.rad(6 + 18 * m) * math.sin(t * (1.4 + m * 2)))
				-- him: up out of the sand in jerks, as if hauled, then turned round to face you
				if k and k.root.Parent then
					local r = math.clamp((t - 12.3) / 2.7, 0, 1)
					local off = -11 * (1 - smooth(r)) + 0.35 * math.sin(r * 22) * (1 - r)
					local yaw = 0
					for _, s in ipairs(TURN) do
						if t >= s[1] then
							yaw += (s[2] - yaw) * smooth((t - s[1]) / s[3])
						end
					end
					local p = KP + V(0, off, 0)
					k.root.CFrame = look(p, p - toYou) * CFrame.Angles(0, yaw, 0)
				end
				RunService.Heartbeat:Wait()
			end
			state = "challenged"
			for pl, r in pairs(held) do
				if r.Parent then
					r.Anchored = false
					pcall(function()
						r:SetNetworkOwner(pl)
					end)
				end
			end
			-- the fight: his bar (and the one init.server shows on this sand while he's up), his moves, the holes
			O.ArenaBar = C.Knight
			Champion.huskStart()
		end)
	end
	-- THE REVEAL (the husk beaten, about 21 seconds): him going to dust (Champion.luau crumbles him); her up there, her
	-- strings gone slack; then she tears the cloak open - and what's under it is her true body (Characters/OssariaHeir),
	-- spindly and wrong, the cloak in rags off every limb. She speaks (C.Unveiled), and leaps down onto the sand in front
	-- of you - and her own fight starts (Heir.begin: phases 2 and 3 of the three). That cutscene is the first time's
	-- only (Save "OssariaUnveiled"): after it she tears the cloak off and is down on the sand in a few seconds, nobody
	-- held, with a word for you (C.Again).
	local HS = 2.3 -- (her true body's scale: half again as tall as the husk)
	local Heir = Core.Roster.byKind.OssariaHeir
	local heir -- { model, root } once she's shed it
	local function makeHeir(cf) -- her true body, at cf (her root's), anchored: an NPC (never hittable) till Heir.begin
		local model = Core.RigBuilder.build("OssariaHeir", HS)
		model.Name = "OssariaHeir"
		pcall(function()
			model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		end)
		Core.applyLimbGroup(model)
		local root = model:FindFirstChild("HumanoidRootPart")
		root.Anchored = true
		model:PivotTo(cf)
		local NPCs = workspace:FindFirstChild("NPCs") or Instance.new("Folder") -- (shared: one folder only)
		NPCs.Name = "NPCs"
		NPCs.Parent = workspace
		model.Parent = NPCs
		model:FindFirstChildOfClass("Humanoid").HipHeight = model:GetAttribute("HipHeight")
		return { model = model, root = root, scale = HS }
	end
	local heirHooks = {
		-- everyone on the sand died to her (Heir has taken her body and everything of hers off it): she's back on her
		-- scar under her shrouds - a new body, the reveal threw the first away - waiting to be challenged again
		onReset = function()
			heir = nil
			b = build(CFrame.lookAt(AR, AR + FA))
			b.model.Parent = workspace
			wingShow(b, 1)
			addPrompt()
			prompt.Enabled = true
			state = "arena"
		end,
		onDied = function() -- beaten, for good ("Ossaria": Heir marks it)
			heir, O.Arena = nil, nil -- (no bar of hers on this sand again: init.server)
			state = "dead"
		end,
	}
	Save.on("Ossaria", function() -- (a save she's dead in: nothing of her on the sand)
		b.model:Destroy()
		O.Arena = nil
		state = "dead"
	end)
	reveal = function(kAt)
		state = "reveal"
		local now = Core.now
		local V, look = V3, CFrame.lookAt
		local first = not Save.done("OssariaUnveiled")
		Save.mark("OssariaUnveiled")
		local held, near = {}, nil
		for _, pl in ipairs(Players:GetPlayers()) do
			local c, _, r = Core.aliveChar(pl)
			if c and Core.states[pl] and Champion.inArena(r.Position) then
				if first then
					held[pl] = r
				end
				near = near or r
			end
		end
		local Hp = b.root.Position -- (where she hangs: her feet)
		local youP = near and near.Position or AR + V(20, 3, 0)
		local toYou = flat(youP - Hp)
		toYou = toYou.Magnitude > 0.1 and toYou.Unit or V(1, 0, 0)
		local side = V(-toYou.Z, 0, toYou.X)
		local dk = flat(youP - kAt)
		dk = dk.Magnitude > 0.1 and dk.Unit or toYou
		-- where she lands: on the sand, 16 short of you, kept inside the colonnade
		local L = V(youP.X, AR.Y, youP.Z) - toYou * 16
		local rel, RAD = flat(L - AR), Map.Champion.Radius - 4
		if rel.Magnitude > RAD then
			L = AR + rel.Unit * RAD
		end
		local face = flat(youP - L)
		face = face.Magnitude > 0.1 and face.Unit or toYou
		local up = V(0, 3 * HS, 0) -- (her root, over her feet)
		local mid = (Hp + L) / 2
		local shots = {
			{ look(kAt + dk * 14 + side * 4 + V(0, 1, 0), kAt + V(0, 3, 0)), look(kAt + dk * 12 + side * 3 + V(0, 0.5, 0), kAt + V(0, 1.5, 0)), 3.4 }, -- him, going to dust
			{ look(Hp + toYou * 14 + V(0, -5, 0), Hp + V(0, 6, 0)), look(Hp + toYou * 12 + side * 2 + V(0, -5, 0), Hp + V(0, 7, 0)), 3 }, -- up at her: the strings slack
			{ look(Hp + toYou * 16 + side * 5 + V(0, 2, 0), Hp + V(0, 7, 0)), look(Hp + toYou * 20 + side * 7 + V(0, 3, 0), Hp + V(0, 8, 0)), 4 }, -- the cloak torn open: wide
			{ look(Hp + toYou * 7 + side * 1.5 + V(0, 12, 0), Hp + V(0, 13, 0)), look(Hp + toYou * 5.5 + side * 0.5 + V(0, 12.5, 0), Hp + V(0, 13, 0)), 5 }, -- her face, as she speaks
			{ look(mid + side * 26 + V(0, 4, 0), mid + V(0, 6, 0)), look(mid + side * 24 + V(0, 3, 0), L + V(0, 5, 0)), 2.4 }, -- side on: the leap
			{ look(youP + toYou * 6 + side * 2.5 + V(0, 3, 0), L + V(0, 9, 0)), look(youP + toYou * 4.5 + side * 2 + V(0, 2.5, 0), L + V(0, 10, 0)), 3.6 }, -- behind you: her, before you
		}
		-- when each beat of it comes (the first time: as the shots above are cut); leap0..leap1 off the air, onto the sand
		local T = first and { tear = 6.6, hang = 8.6, say = 10.2, crouch = 14.3, leap0 = 14.8, leap1 = 16, up = 17.4, tilt = 19.2 }
			or { tear = 0.9, say = 1.1, crouch = 1.5, leap0 = 2.0, leap1 = 3.0, up = 3.5, done = 4.4 }
		local total = T.done or 0
		for _, sh in ipairs(first and shots or {}) do
			total += sh[3]
		end
		for pl, r in pairs(held) do
			local s = Core.states[pl]
			Core.setAction(s, now(), total, total, total)
			s.iStart, s.iEnd = now(), now() + total + 0.5
			s.healing = false
			Core.cancelSwing(s)
			r.AssemblyLinearVelocity = V()
			r.Anchored = true
			FxRemote:FireClient(pl, "Grabbed", total)
			FxRemote:FireClient(pl, "Cutscene", shots)
		end
		local function all(...)
			for pl in pairs(first and held or Core.states) do
				FxRemote:FireClient(pl, ...)
			end
		end
		local function hpose(name, t)
			Core.bodyPose(heir, name, t)
		end
		local LEAP0, LEAP1 = T.leap0, T.leap1
		local events = {
			{ T.tear, function() -- the cloak torn open: her shrouds flung off into the dark, and her true body under them
				Core.playSound(b.root, Core.SOUNDS.WatchdogSmash, 0.9, 0.35)
				Core.playSound(b.root, Core.SOUNDS.Lunge, 1, 0.4)
				Core.burst(Hp + V(0, 6, 0), C3(20, 12, 26), 60, 0.9, 26)
				if first then -- (not over you while you're free to move)
					all("Flash", C3(0, 0, 0), 0.5, 0.08)
				end
				all("Shake", Hp, 1)
				for _, p in ipairs(b.model:GetDescendants()) do
					if p:IsA("BasePart") then
						p.Anchored = true
						local away = flat(p.Position - Hp)
						away = (away.Magnitude > 0.1 and away.Unit or side) * rnd(6, 14) + V(0, rnd(-4, 6), 0)
						TweenService:Create(p, TweenInfo.new(rnd(0.8, 1.4), Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = (p.CFrame + away) * CFrame.Angles(rnd(-1, 1), rnd(-1, 1), rnd(-1, 1)), Transparency = 1 }):Play()
					end
				end
				game:GetService("Debris"):AddItem(b.model, 1.6)
				heir = makeHeir(look(Hp + up, Hp + up + toYou))
				hpose("OHUnfurl", 0.01)
			end },
			{ T.hang, function() hpose("OHHang", 1.6) end }, -- the arms come slowly down, the rags swinging off them
			{ T.say, function() all("Say", C.Name, first and C.Unveiled or C.Again) end },
			{ T.crouch, function() hpose("Crouch", 0.4) end }, -- gathered up, in the air
			{ LEAP0, function()
				hpose("Air", 0.2)
				Core.playSound(heir.root, Core.SOUNDS.Lunge, 1, 0.45)
			end },
			{ LEAP1, function() -- onto the sand
				hpose("OHLand", 0.08)
				Core.playSound(heir.root, Core.SOUNDS.WatchdogSmash, 1, 0.45)
				Core.playSound(heir.root, Core.SOUNDS.Impact, 1, 0.5)
				Core.shockwave(L, 18)
				Core.burst(L + V(0, 2, 0), C3(20, 12, 26), 30, 0.7, 16)
				all("Shake", L, 1.4)
			end },
			{ T.up, function() hpose("OHIdle", first and 1.2 or 0.7) end }, -- unfolding up off her haunches
			{ T.tilt, function() hpose("OHTilt", 0.9) end }, -- and her head tipped over, looking at you
		}
		for i = #events, 1, -1 do -- (the beats only the cutscene has)
			if not events[i][1] then
				table.remove(events, i)
			end
		end
		task.spawn(function()
			local t0, ev = os.clock(), 1
			while true do
				local t = os.clock() - t0
				while events[ev] and t >= events[ev][1] do
					local ok, err = pcall(events[ev][2])
					if not ok then
						warn("[DGUS] Ossaria's reveal: " .. tostring(err))
					end
					ev += 1
				end
				if t >= total then
					break
				end
				if heir and heir.root.Parent then -- (anchored all along: carried through the leap)
					local p, dir
					if t < LEAP0 then
						p, dir = Hp + up + V(0, math.sin(t * 0.9) * 0.25, 0), toYou
					elseif t < LEAP1 then
						local u = (t - LEAP0) / (LEAP1 - LEAP0)
						p = (Hp + up):Lerp(L + up, u) + V(0, 7 * math.sin(math.pi * u), 0)
						dir = toYou:Lerp(face, u).Unit
					else
						p, dir = L + up, face
					end
					heir.root.CFrame = look(p, p + dir)
				elseif b.model.Parent then -- (before she sheds it: hanging there, slack, looking down where he fell)
					b.root.CFrame = look(Hp + V(0, math.sin(t * 0.9) * 0.25, 0), Hp + toYou) * CFrame.Angles(-0.25 * smooth(t / 3), 0, 0)
					wingPose(b, 1, math.rad(10) * math.sin(t * 1.6))
				end
				RunService.Heartbeat:Wait()
			end
			state = "heir"
			for pl, r in pairs(held) do
				if r.Parent then
					r.Anchored = false
					pcall(function()
						r:SetNetworkOwner(pl)
					end)
				end
			end
			-- her own fight: her bar, the seal, her moves (Characters/OssariaHeir)
			if heir and heir.root.Parent then
				Heir.begin(heir, heirHooks)
			else
				heirHooks.onReset() -- (her body never came: back under her shrouds, not left with nothing on the sand)
			end
		end)
	end

	-- HER DEV MENU (the client's Ossaria menu, off the dev menu; init.server's "DevOss", a dev's only): any cutscene of
	-- hers, or any phase, from anywhere and whatever's happened so far. Everything of her fight is taken off the sand
	-- first and she's put back under her shrouds on her scar (toArena); then the one asked for is set up from there.
	--   fall | meet        the fall into her court; the meeting (the Heights can only come down once: not again)
	--   challenge | p1     phase 1, the husk: with its cutscene | straight into it
	--   reveal | p2        phase 2, her true body: with its cutscene (as the first time) | straight into it
	--   rise | p3          phase 3, the great hands: with its cutscene (as the first time) | the few seconds' version
	--   death | wound      her end, now | one hit from the next bar (or from death)
	--   arena | flags      just the reset, and you on the sand | both first-time cutscenes forgotten
	M.dev = function(player, what)
		local char, _, hrp = Core.aliveChar(player)
		local st = Core.states[player]
		if not (char and st) then
			return
		end
		local function tell(msg)
			FxRemote:FireClient(player, "Message", msg)
		end
		if state == "meeting" or state == "challenge" or state == "reveal" or Heir.busy() then
			return tell("Ossaria: one of her cutscenes is playing. Wait for it to end.")
		end
		local function forget(name)
			player:SetAttribute("W_" .. name, nil)
		end
		-- THE ATTACK LAB's own (she's up, and waiting: lab2 | lab3, below): fire:<move> once, loop:<move> over and over,
		-- stop, passive:on|off (off: she fights as herself), mark:<move>:<keep|cut|tweak> (kept on you as "Lab_<move>",
		-- and printed)
		local cmd, rest = what:match("^(%a+):(.+)$")
		if cmd == "fire" or cmd == "loop" or cmd == "passive" or what == "stop" then
			if state ~= "heir" then
				return tell("Ossaria: start the lab first (phase 2 or phase 3).")
			elseif what == "stop" then
				Heir.lab.stop()
			elseif cmd == "passive" then
				Heir.lab.stop()
				Heir.lab.passive(rest == "on")
			else
				Heir.lab.fire(rest, cmd == "loop")
			end
			return
		elseif cmd == "mark" then
			local name, verdict = rest:match("^(%w+):(%a+)$")
			if name then
				player:SetAttribute("Lab_" .. name, verdict)
				print("[Lab] " .. name .. " = " .. verdict)
			end
			return
		end
		if what == "wound" or what == "death" then
			local hers = state == "heir" and Heir or state == "challenged" and Champion
			if hers then
				local fn = what == "wound" and hers.devWound or hers.devKill
				fn()
			else
				tell("Ossaria: nothing of hers is fighting. Start a phase first.")
			end
			return
		elseif what == "flags" then
			forget("OssariaUnveiled")
			forget("OssariaHand")
			return tell("Ossaria: her phase 2 and phase 3 cutscenes will play as the first time.")
		end
		local function toArena()
			if state == "challenged" then
				Champion.reset()
			elseif state == "heir" then
				Heir.reset()
			elseif state == "dead" then
				forget("Ossaria")
				heirHooks.onReset()
			elseif state == "waiting" then
				Save.mark("OssariaFled")
				gone()
			end
			O.Arena, O.ArenaBar = AR, nil
			state = "arena"
			prompt.Enabled = true
		end
		-- (her court's two, with her still in it and the Heights still standing - a save that's never met her: nothing
		-- to put back, and above all no toArena, which brings the Heights down and the night with them before she's
		-- so much as turned round)
		local untouched = (what == "fall" or what == "meet") and state == "waiting" and not fell
		if not untouched then
			toArena()
		end
		if (what == "fall" or what == "meet") and fell then
			tell("Ossaria: the Heights are already down on this server, so they can't fall again in this cutscene. Her save flag is cleared: rejoin and pick this again to see it whole.")
		end
		local toYou = V3(1, 0, 0) -- (you: on the sand, in from the road, east of her)
		local up = V3(0, 3 * HS, 0)
		local function onSand()
			hrp.AssemblyLinearVelocity = Vector3.zero
			char:PivotTo(CFrame.lookAt(AR + toYou * 24 + V3(0, 3, 0), AR + V3(0, 3, 0)))
		end
		local function heirNow() -- her true body on the sand and her own fight begun, none of its cutscene
			prompt.Enabled = false
			b.model:Destroy()
			heir = makeHeir(CFrame.lookAt(AR + up, AR + up + toYou))
			Core.bodyPose(heir, "OHIdle", 0.01)
			state = "heir"
			Heir.begin(heir, heirHooks)
		end
		if what == "fall" or what == "meet" then -- back in her court, as she was before you ever met her
			state = "waiting"
			prompt.Enabled = false
			O.Arena = nil
			wingShow(b, 0)
			wingPose(b, 0, 0)
			forget("OssariaFled")
			st.ossariaAt = 0
			hrp.AssemblyLinearVelocity = Vector3.zero
			local L = O.Landing.Position
			if what == "fall" then -- (init.server sees you in the pit's mouth, unseen: its descent plays)
				st.ossariaSeen = false
				forget("OssariaPit")
				char:PivotTo(CFrame.new(L.X, O.Top - 4, L.Z))
			else -- (twelve short of where she speaks: walk up to her)
				local from = flat(L - S)
				from = from.Magnitude > 0.1 and from.Unit or V3(1, 0, 0)
				char:PivotTo(CFrame.lookAt(S + from * (MEET + 12) + V3(0, 3, 0), S + V3(0, 3, 0)))
			end
		elseif what == "arena" then
			onSand()
		elseif what == "challenge" then
			onSand()
			task.wait(0.2)
			challenge(player, st, char, hrp)
		elseif what == "p1" then -- the husk up and fighting, her hung over it on its strings
			onSand()
			prompt.Enabled = false
			local KP = AR + V3(0, 3 * KS, 0)
			knight = Champion.huskSpawn(CFrame.lookAt(KP, KP + toYou), dress, hooks)
			Core.pose(knight, "GLow", 0.01)
			Core.bodyPose(knight, "CGlare", 0.01)
			strings(knight)
			hover = { AR - toYou * 7 + V3(0, 7, 0), toYou }
			state = "challenged"
			O.ArenaBar = C.Knight
			Champion.huskStart()
		elseif what == "reveal" then -- hung where she hangs over her husk, it just fallen under her
			onSand()
			forget("OssariaUnveiled")
			prompt.Enabled = false
			local at = AR - toYou * 7 + V3(0, 7, 0)
			b.root.CFrame = CFrame.lookAt(at, at + toYou)
			wingPose(b, 1, 0)
			task.wait(0.2)
			reveal(AR)
		elseif what == "lab2" or what == "lab3" then -- the attack lab: her own fight, but she only waits; nothing hurts you
			onSand()
			st.devGod = true
			if what == "lab3" then
				Save.mark("OssariaHand")
			end
			heirNow()
			Heir.lab.passive(true)
			if what == "lab3" then
				task.delay(0.6, Heir.devWound)
			end
		elseif what == "p2" then
			onSand()
			heirNow()
		elseif what == "rise" or what == "p3" then -- her first bar emptied the moment her fight starts
			onSand()
			if what == "rise" then
				forget("OssariaHand")
			else
				Save.mark("OssariaHand")
			end
			heirNow()
			task.delay(0.6, Heir.devWound)
		end
	end

	-- waiting: a slow rise and fall; and whoever walks up to her (not mid-fall into her court) meets her
	RunService.Heartbeat:Connect(function()
		if state == "arena" then -- (on the colosseum's sand, her back to the way in, wings half drawn)
			local t = os.clock()
			b.root.CFrame = CFrame.lookAt(AR, AR + FA) + V3(0, math.sin(t * 0.9) * 0.12, 0)
			wingPose(b, 0.7, math.rad(6) * math.sin(t * 1.4))
			return
		elseif state == "challenged" then -- (hung over him, holding his strings: drifting after him, slow, as he fights)
			local t = os.clock()
			local kr = knight and knight.root
			if kr and kr.Parent then
				local fwd = flat(kr.CFrame.LookVector)
				if fwd.Magnitude > 0.1 then
					hover[2] = hover[2]:Lerp(fwd.Unit, 0.03).Unit
				end
				hover[1] = hover[1]:Lerp(V3(kr.Position.X, AR.Y + 9, kr.Position.Z) - hover[2] * 7, 0.025)
			end
			b.root.CFrame = CFrame.lookAt(hover[1], hover[1] + hover[2]) + V3(0, math.sin(t * 0.9) * 0.25, 0)
			wingPose(b, 1, math.rad(14) * math.sin(t * 2.2))
			return
		elseif state ~= "waiting" then
			return
		end
		b.root.CFrame = CFrame.lookAt(S, S + F0) + V3(0, math.sin(os.clock() * 0.9) * 0.12, 0)
		for player, st in pairs(Core.states) do
			local char, _, hrp = Core.aliveChar(player)
			if char and st.zone == O.Zone and Core.now() >= (st.ossariaAt or 0) and flat(hrp.Position - S).Magnitude < MEET then
				meet(player, st, char, hrp)
				return
			end
		end
	end)
end

return M
