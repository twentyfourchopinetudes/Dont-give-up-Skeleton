--!nonstrict
-- THE WARDEN, candidate 3: THE BONE COLOSSUS. The hall's a charnel house with shelves of the dead up every wall, and the Warden
-- is what they made of themselves: a skeleton four times the size of a man, built of thousands of smaller bones, a great
-- thighbone for a club. It's a warden still, and it keeps doing the only thing it knows: it locks people up. Cages of
-- bone burst out of the floor around you, spears run along the ground, and all you have to do is keep moving and get under it.
-- Phase 1: the club swing, the overhead, the stomp, the running spears, the cage.
-- Phase 2 at half health: it tears out its own ribs and throws them; two cages at once, and three lines of spears.
-- Fight's plumbing: ReplicatedStorage/WardenFight.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fight = require(ReplicatedStorage:WaitForChild("WardenFight"))

local S = 4.1
local M = {}
M.Kind = "WardenBones"
M.Proportions = { girth = 0.85, arm = 1.32, hunch = 0.28, twoHand = -0.7, walkRef = 2.5, cadence = 0.9 }
M.IdlePose = "BNIdle"
M.Poses = {
	BNIdle = { drop = 0.3, lean = 0.2, head = 0.05, footR = -0.35, footL = 0.42, spread = 0.26, breathe = 1.2, freeL = 0 },
	-- wound right round for the swing, skull still on you
	BNWind = { drop = 0.7, lean = 0.2, twist = -1.25, hip = -0.6, side = -0.1, look = 1, footR = -0.7, footL = 0.8, spread = 0.38, breathe = 2, freeL = 0 },
	BNThrough = { drop = 0.95, lean = 0.55, twist = 1.15, hip = 0.55, side = 0.12, look = -0.5, footR = 0.9, footL = -0.65, spread = 0.38, freeL = 0 },
	-- the overhead: rattling up to its full height
	BNHigh = { drop = 0.02, lean = -0.4, head = -0.4, footR = -0.4, footL = 0.45, spread = 0.26, breathe = 2, freeL = 0 },
	BNDown = { drop = 1.3, lean = 1, head = -0.15, footR = 0.85, footL = -0.7, spread = 0.38, freeL = 0 },
	BNKnee = { drop = 0.25, lean = 0.12, side = 0.18, lift = 1.5, head = 0.1, footL = -0.05, footR = 0.2, spread = 0.2, freeL = 0 },
	BNStomp = { drop = 0.95, lean = 0.45, side = -0.08, head = 0.25, footR = 0.55, footL = -0.3, spread = 0.36, freeL = 0 },
	-- calling something up out of the floor: free hand driven down at it, skull bent
	BNCall = { drop = 1.0, lean = 0.75, twist = 0.2, head = 0.35, footR = -0.2, footL = 0.55, spread = 0.38, la1 = -0.75, la3 = -0.5, lel = 0.1, breathe = 2, freeL = 0 },
	BNClose = { drop = 0.3, lean = -0.2, head = -0.4, footR = -0.2, footL = 0.3, spread = 0.3, la1 = 1.9, la3 = -0.4, lel = 0.8, freeL = 0 },
	-- the spears: the club driven into the floor, end down
	BNDrive = { drop = 1.2, lean = 0.9, twist = -0.2, head = -0.2, footR = 0.7, footL = -0.55, spread = 0.36, freeL = 0 },
	-- tearing out its own ribs (phase 2's throw): free hand at its chest, then the arm flung out
	BNTear = { drop = 0.45, lean = 0.12, twist = -0.7, head = 0.25, look = 0.5, footR = -0.45, footL = 0.45, spread = 0.3, la1 = 0.85, la2 = 1, la3 = 0.3, lel = 1.9, breathe = 3, freeL = 0 },
	BNThrow = { drop = 0.55, lean = 0.55, twist = 0.75, head = 0, footR = 0.6, footL = -0.55, spread = 0.3, la1 = 1.45, la3 = -0.6, lel = 0.1, freeL = 0 },
	BNCollapse = { drop = 1.6, lean = 0.75, side = 0.15, head = 0.6, footR = 0.8, footL = -1.1, spread = 0.38, la1 = -0.3, la3 = -0.5, lel = 0.1, freeL = 0 },
	BNHowl = { drop = 0.12, lean = -0.55, head = -0.75, footR = 0.35, footL = -0.4, spread = 0.3, la1 = 2.4, la3 = -0.9, lel = 0.4, breathe = 3, freeL = 0 },
}
local BONE, BONE_DK, BONE_LT, EYE = Color3.fromRGB(198, 190, 166), Color3.fromRGB(142, 134, 112), Color3.fromRGB(226, 220, 198), Color3.fromRGB(190, 222, 226)
M.Colors = { skin = BONE, torso = BONE_DK, legs = BONE, arms = BONE }
M.FistSkin = true

function M.Look(k)
	local deco, parts, V, at, MAT, s = k.deco, k.parts, k.V, k.at, k.MAT, k.s
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local tl, sl = k.D.thigh / s, k.D.shin / s
	local BALL = Enum.PartType.Ball
	local rng = Random.new(19)
	-- no flesh: the trunk's just a spine and a cage of ribs, with air between
	parts.Chest.Transparency, parts.Hips.Transparency = 1, 1
	parts.Head.Transparency = 1
	for i = 0, 5 do
		deco("Chest", "Spine", V(0.34, 0.26, 0.34), at(0, -ch / 2 + 0.14 + i * ch / 5.8, cd * 0.3), BONE_DK, MAT.Pebble)
	end
	for row = 0, 4 do -- five pairs of ribs (named: phase 2 tears them out)
		local y = ch * 0.34 - row * ch * 0.16
		local wide = cw * (0.5 - row * 0.022)
		for _, sx in ipairs({ -1, 1 }) do
			deco("Chest", "Rib", V(0.16, 0.16, cd * 0.86), at(sx * wide, y, 0), BONE, MAT.Pebble)
			deco("Chest", "Rib", V(wide * 0.82, 0.16, 0.16), at(sx * wide * 0.56, y, -cd * 0.43) * CFrame.Angles(0, 0, sx * -0.08), BONE, MAT.Pebble)
			deco("Chest", "Rib", V(wide * 0.92, 0.16, 0.16), at(sx * wide * 0.5, y + 0.05, cd * 0.3), BONE_DK, MAT.Pebble)
		end
	end
	deco("Chest", "Breastbone", V(0.24, ch * 0.62, 0.14), at(0, ch * 0.1, -cd * 0.46), BONE_LT, MAT.Pebble)
	deco("Chest", "Collar", V(cw * 1.1, 0.2, 0.2), at(0, ch / 2 - 0.08, -cd * 0.2), BONE, MAT.Pebble)
	deco("Chest", "Shoulderblades", V(cw * 0.9, ch * 0.3, 0.1), at(0, ch * 0.3, cd * 0.42), BONE_DK, MAT.Pebble)
	-- a pale light caught in the ribs, so it's seen across the dark hall
	local ember = deco("Chest", "HeartLight", V(0.55, 0.55, 0.55), at(0, 0, -0.05), EYE, MAT.Neon, BALL)
	local glow = Instance.new("PointLight")
	glow.Color, glow.Range, glow.Brightness, glow.Shadows = EYE, 36, 1.1, false
	glow.Parent = ember
	-- pelvis
	deco("Hips", "Pelvis", V(hw * 0.92, 0.46, hd * 0.75), at(0, 0.1, 0), BONE_DK, MAT.Pebble)
	deco("Hips", "PelvisWing", V(hw * 1.05, 0.2, hd * 0.3), at(0, 0.34, 0.1), BONE, MAT.Pebble)
	-- the limbs: thin bones, knobbed at the joints, smaller bones stuck all over them
	for _, n in ipairs({ "R", "L" }) do
		parts[n .. "UpperArm"].Size *= Vector3.new(0.5, 1, 0.5)
		parts[n .. "LowerArm"].Size *= Vector3.new(0.42, 1, 0.42)
		parts[n .. "Thigh"].Size *= Vector3.new(0.48, 1, 0.48)
		parts[n .. "Shin"].Size *= Vector3.new(0.42, 1, 0.42)
		for _, p in ipairs({ { "UpperArm", ua, aw }, { "LowerArm", la, aw }, { "Thigh", tl, lw }, { "Shin", sl, lw } }) do
			local on, len, w = n .. p[1], p[2], p[3]
			deco(on, "Knob", V(w * 0.72, w * 0.72, w * 0.72), at(0, len / 2 - 0.05, 0), BONE_LT, MAT.Pebble, BALL)
			deco(on, "Knob", V(w * 0.62, w * 0.62, w * 0.62), at(0, -len / 2 + 0.05, 0), BONE_LT, MAT.Pebble, BALL)
			for _ = 1, 3 do
				local y = rng:NextNumber(-len * 0.35, len * 0.35)
				deco(on, "SmallBone", V(0.1, rng:NextNumber(0.4, 0.8), 0.1), at(rng:NextNumber(-w * 0.26, w * 0.26), y, rng:NextNumber(-w * 0.26, w * 0.26)) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), 0, rng:NextNumber(-0.5, 0.5)), BONE_DK, MAT.Pebble)
			end
		end
		deco(n .. "LowerArm", "HandBones", V(aw * 0.72, 0.42, aw * 0.72), at(0, -la / 2 - 0.2, 0), BONE, MAT.Pebble)
		for i = -1, 1 do
			deco(n .. "LowerArm", "Finger", V(0.09, 0.55, 0.09), at(i * aw * 0.22, -la / 2 - 0.62, 0), BONE_LT, MAT.Pebble)
		end
		deco(n .. "Foot", "FootBones", k.V(k.D.footSize.X / s * 0.8, 0.2, k.D.footSize.Z / s), at(0, -0.02, 0), BONE, MAT.Pebble)
	end
	parts.RFoot.Transparency, parts.LFoot.Transparency = 1, 1
	-- the skull: huge, a jaw hung from it on nothing, two cold points in the sockets, and more small skulls round its neck
	deco("Head", "Skull", V(1.35, 1.35, 1.35), at(0, 0.18, 0), BONE_LT, MAT.Pebble, BALL)
	deco("Head", "Jaw", V(0.84, 0.32, 0.82), at(0, -0.56, -0.16), BONE, MAT.Pebble)
	for i = -2, 2 do
		deco("Head", "Tooth", V(0.11, 0.17, 0.07), at(i * 0.15, -0.34, -0.57), BONE_DK, MAT.Pebble)
	end
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "Socket", V(0.42, 0.42, 0.2), at(sx * 0.28, 0.14, -0.54), Color3.fromRGB(8, 8, 10), MAT.SmoothPlastic, BALL)
		deco("Head", "Eye", V(0.15, 0.15, 0.1), at(sx * 0.28, 0.14, -0.64), EYE, MAT.Neon, BALL)
	end
	deco("Head", "Nose", V(0.16, 0.24, 0.08), at(0, -0.1, -0.64), Color3.fromRGB(8, 8, 10), MAT.SmoothPlastic)
	for i = 0, 6 do
		local a = i / 7 * math.pi * 2
		deco("Chest", "SmallSkull", V(0.42, 0.42, 0.42), at(math.cos(a) * 0.72, ch / 2 + 0.1, math.sin(a) * 0.56), BONE, MAT.Pebble, BALL)
	end
end

M.Weapons = {
	-- a thighbone as long as a tree, from something else again, cracked and bound with old iron
	Femur = function(w)
		local mk, add, s = w.mk, w.add, w.scale
		local bone, dark, iron = Color3.fromRGB(198, 190, 166), Color3.fromRGB(142, 134, 112), Color3.fromRGB(58, 56, 54)
		local handle = mk("Shaft", Vector3.new(0.48, 2.4, 0.48), bone, Enum.Material.Pebble)
		add(mk("Shaft2", Vector3.new(0.56, 3.3, 0.56), bone, Enum.Material.Pebble), -2.8)
		local function ball(name, size, y, x)
			local p = mk(name, Vector3.new(size, size, size), dark, Enum.Material.Pebble)
			p.Shape = Enum.PartType.Ball
			add(p, y, CFrame.new((x or 0) * s, 0, 0))
		end
		ball("HandEnd", 0.9, 1.3)
		ball("Head", 1.4, -4.6, 0.25)
		ball("Head", 1.25, -4.85, -0.32)
		for _, y in ipairs({ -1.2, -2.4 }) do
			add(mk("Band", Vector3.new(0.68, 0.22, 0.68), iron, Enum.Material.Metal), y)
		end
		return { handle = handle, bladeLen = 4.8, gripC1 = CFrame.new(0, 0.6 * s, 0) }
	end,
}
local R = math.rad
local function out(yaw, tilt)
	return CFrame.Angles(0, R(yaw), 0) * CFrame.Angles(0, 0, R(tilt))
end
M.Grips = {
	BNRest = { Vector3.new(1.4, -0.4, -0.8), CFrame.Angles(R(15), 0, 0) },
	BNWind = { Vector3.new(2.2, -0.2, 1.8), out(-65, 66) },
	BNMid = { Vector3.new(0.4, -0.6, -2.7), out(90, 58) },
	BNEnd = { Vector3.new(-2.2, -0.6, -0.5), out(190, 58) },
	BNHigh = { Vector3.new(0.5, 2.9, 0.5), CFrame.Angles(R(215), 0, 0) },
	BNDown = { Vector3.new(0.3, -0.5, -2.5), CFrame.Angles(R(55), 0, 0) },
	BNDrive = { Vector3.new(0.4, -0.4, -2.2), CFrame.Angles(R(15), 0, 0) },
	BNCall = { Vector3.new(2.2, 0.4, 0.8), out(-20, 50) },
	BNSlump = { Vector3.new(1.2, -1.2, -1.2), CFrame.Angles(R(15), 0, 0) },
	BNHowl = { Vector3.new(1.3, 3, -0.3), CFrame.Angles(R(160), 0, R(12)) },
}
M.BodyFor = {}

---------------------------------------------------------------------------
-- server: the fight
---------------------------------------------------------------------------
function M.init(core)
	local F = Fight.init(core)
	local SOUNDS, playSound, burst, pose, bodyPose, setTrail, dustCloud, flat, debrisChunks, FxRemote = core.SOUNDS, core.playSound, core.burst, core.pose, core.bodyPose, core.setTrail, core.dustCloud, core.flat, core.debrisChunks, core.FxRemote
	local TweenService = game:GetService("TweenService")
	local D = { Swing = 22, Over = 24, Blast = 14, Stomp = 14, Spear = 14, Cage = 20, Rib = 12 }
	local BONE_C = Color3.fromRGB(198, 190, 166)

	local function ahead(b, dist)
		return flat(b.root.Position) + F.fwd(b) * dist
	end
	-- a spike of bone bursting out of the floor at p, then sinking back
	local function spike(p, h, w)
		local tilt = CFrame.Angles((math.random() - 0.5) * 0.3, math.random() * 6, (math.random() - 0.5) * 0.3)
		local down = CFrame.new(p.X, -h / 2, p.Z) * tilt
		local up = CFrame.new(p.X, h * 0.4, p.Z) * tilt
		local part = F.part({ Name = "BoneSpike", Size = Vector3.new(w, h, w), Material = Enum.Material.Pebble, Color = BONE_C, CFrame = down })
		TweenService:Create(part, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = up }):Play()
		task.delay(0.7, function()
			if part.Parent then
				TweenService:Create(part, TweenInfo.new(0.4), { CFrame = down }):Play()
				task.delay(0.42, function()
					if part.Parent then
						part:Destroy()
					end
				end)
			end
		end)
		dustCloud(p, 1.4, 3)
	end

	-- THE CLUB: wound right round with the skull still on you, the bone rattling; then all the way across
	local function swing(b, target)
		F.halt(b)
		if not F.beats(b, target, {
			{ "BNWind", "BNWind", 0.6 },
			{ "BNWind", "BNWind", 0.5, function()
				playSound(b.root, SOUNDS.Unsheath, 0.9, 0.45)
			end },
		}, 0.7) then
			return
		end
		setTrail(b, true)
		F.step(b, 9, 0.3)
		bodyPose(b, "BNThrough", 0.2)
		pose(b, "BNMid", 0.15, Enum.EasingStyle.Linear)
		task.delay(0.15, function()
			pose(b, "BNEnd", 0.17)
		end)
		playSound(b.root, SOUNDS.Lunge, 1, 0.5)
		F.sweep(b, 0.33, D.Swing, "Large", {}, 3.5)
		setTrail(b, false)
		F.recover(b, 1.2, "Recover")
	end

	local function over(b, target)
		F.halt(b)
		if not F.beats(b, target, { { "BNHigh", "BNHigh", 0.8 } }, 0.65) then
			return
		end
		local at = ahead(b, 20)
		F.ring(at, 10, 0.65)
		playSound(b.root, SOUNDS.Unsheath, 0.9, 0.42)
		if not F.track(b, target, 0.65, 0) then
			return
		end
		setTrail(b, true)
		F.draw(b, "BNDown", "BNDown", 0.14)
		playSound(b.root, SOUNDS.Lunge, 1, 0.45)
		F.sweep(b, 0.15, D.Over, "Knockdown", {}, 3.5)
		setTrail(b, false)
		if not F.live(b) then
			return
		end
		F.quake(b, at, 10, 1.4)
		debrisChunks(at + Vector3.new(0, 0.5, 0), 6, 20)
		F.hit(F.radius(at, 10, 8), {}, D.Blast, at, "Large")
		for i = 1, 6 do
			local a = i / 6 * math.pi * 2
			spike(at + Vector3.new(math.cos(a) * 8, 0, math.sin(a) * 8), 10, 2)
		end
		F.recover(b, 1.4, false)
	end

	local function stomp(b, target)
		F.halt(b)
		local at = flat(b.root.Position)
		F.draw(b, "BNRest", "BNKnee", 0.55 * F.tempo())
		F.ring(at, 13, 0.9 * F.tempo())
		playSound(b.root, SOUNDS.Groan, 0.8, 0.5)
		if not F.track(b, target, 0.9 * F.tempo(), 0) then
			return
		end
		bodyPose(b, "BNStomp", 0.1)
		playSound(b.root, SOUNDS.Lunge, 0.9, 0.55)
		if not F.hold(b, 0.09) then
			return
		end
		F.quake(b, at, 13, 1.1)
		F.hit(F.radius(at, 13, 8), {}, D.Stomp, at, "Large")
		F.recover(b, 1, false)
	end

	-- one line of spears along the floor, from a to z, each coming up after the last
	local function spears(b, a, z, wid, lead)
		F.strip(a, z, wid, lead)
		local n = math.max(math.floor((z - a).Magnitude / 6), 2)
		local seen = {}
		for i = 1, n do
			task.delay(lead + i * 0.07, function()
				if F.live(b) then
					local p = a:Lerp(z, i / n)
					spike(p + Vector3.new((math.random() - 0.5) * 3, 0, (math.random() - 0.5) * 3), 13, 2.4)
					playSound(b.root, SOUNDS.Impact, 0.3, 1.4)
					F.hit(F.radius(p, wid / 2 + 1, 8), seen, D.Spear, p, "Large")
				end
			end)
		end
		return lead + n * 0.07
	end

	-- THE SPEARS: the club driven into the floor; a strip lights, then it comes up in spears along it, away from him
	local function spearLine(b, target)
		F.halt(b)
		if not F.beats(b, target, { { "BNDrive", "BNDrive", 0.75 } }, 0.65) then
			return
		end
		playSound(b.root, SOUNDS.Impact, 0.8, 0.6)
		dustCloud(ahead(b, 14), 3, 8)
		local a = ahead(b, 10)
		local dir = F.fwd(b)
		local time = 0
		for _, yaw in ipairs(F.phase2() and { -0.42, 0, 0.42 } or { 0 }) do
			local d = CFrame.Angles(0, yaw, 0):VectorToWorldSpace(dir)
			time = math.max(time, spears(b, a, F.clamp(a + d * 56, 3), 7, 0.6))
		end
		F.hold(b, time)
		F.recover(b, 1.1, "Recover")
	end

	-- one cage round p: a circle lit on the floor, bars of rib coming up round it as it closes, then it snaps shut on whatever's inside
	local function cage(b, at, r, lead)
		F.ring(at, r, lead)
		local bars = {}
		local N = 14
		for i = 1, N do
			local a = i / N * 2 * math.pi
			local p = at + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			local out = CFrame.lookAt(p, at)
			local bar = F.part({ Name = "CageBar", Size = Vector3.new(1.3, 18, 1.3), Material = Enum.Material.Pebble, Color = BONE_C, CFrame = CFrame.new(p.X, -10, p.Z) * out.Rotation })
			table.insert(bars, bar)
			TweenService:Create(bar, TweenInfo.new(lead * 0.8, Enum.EasingStyle.Sine), { CFrame = (CFrame.new(p.X, 8.5, p.Z) * out.Rotation) * CFrame.Angles(-0.12, 0, 0) }):Play()
		end
		playSound(b.root, SOUNDS.Unsheath, 0.9, 0.3)
		task.delay(lead, function()
			if not F.live(b) then
				return
			end
			-- shut: every bar's top slammed in to the middle
			for i, bar in ipairs(bars) do
				if bar.Parent then
					local a = i / N * 2 * math.pi
					local p = at + Vector3.new(math.cos(a) * r * 0.72, 0, math.sin(a) * r * 0.72)
					TweenService:Create(bar, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.lookAt(p + Vector3.new(0, 8.5, 0), at) * CFrame.Angles(-0.65, 0, 0) }):Play()
				end
			end
			task.delay(0.1, function()
				if F.live(b) then
					F.quake(b, at, r * 0.7, 1)
					burst(at, BONE_C, 26, 0.45, 16)
					F.hit(F.radius(at, r - 0.5, 9), {}, D.Cage, at, "Knockdown")
				end
				task.delay(0.9, function()
					for _, bar in ipairs(bars) do
						if bar.Parent then
							F.fade(bar, 0.6)
						end
					end
				end)
			end)
		end)
	end

	-- THE CAGE: it drives its free hand at the floor, and a ring of bones comes up round you. Plenty of time to walk out of it.
	local function lockUp(b, target)
		F.halt(b)
		local tr = target:FindFirstChild("HumanoidRootPart")
		if not tr then
			return
		end
		if not F.beats(b, target, { { "BNCall", "BNCall", 0.55, function()
			playSound(b.root, SOUNDS.Groan, 0.9, 0.5)
		end } }, 0.5) then
			return
		end
		local LEAD = 1.5
		cage(b, F.clamp(flat(tr.Position), 12), 11, LEAD)
		if F.phase2() then
			local v = flat(tr.Position - b.root.Position)
			local side = v.Magnitude > 1 and Vector3.new(-v.Unit.Z, 0, v.Unit.X) or Vector3.new(1, 0, 0)
			cage(b, F.clamp(flat(tr.Position) + side * (math.random() < 0.5 and 20 or -20), 12), 11, LEAD + 0.5)
		end
		F.draw(b, "BNRest", "BNClose", 0.4)
		F.hold(b, LEAD)
		F.recover(b, 1.3, "BNIdle")
	end

	-- RIBS (phase 2): it tears them out of itself and throws them, slow long arcs down on rings
	local function ribs(b, target)
		F.halt(b)
		if not F.beats(b, target, { { "BNRest", "BNTear", 0.8, function()
			playSound(b.root, SOUNDS.Unsheath, 1, 0.6)
		end } }, 0.6) then
			return
		end
		F.draw(b, "BNRest", "BNThrow", 0.14)
		playSound(b.root, SOUNDS.Lunge, 1, 0.65)
		local tr = target:FindFirstChild("HumanoidRootPart")
		if not tr then
			return
		end
		local from = b.root.Position + Vector3.new(0, 8, 0)
		for i = 1, 5 do
			local spread = i == 1 and Vector3.zero or Vector3.new(math.random(-15, 15), 0, math.random(-15, 15))
			local to = F.clamp(flat(tr.Position) + spread, 3)
			local dur = 1.05 + i * 0.07
			F.ring(to, 5.5, dur)
			local rib = F.part({ Name = "ThrownRib", Size = Vector3.new(1, 11, 1), Material = Enum.Material.Pebble, Color = BONE_C, CFrame = CFrame.new(from) })
			F.lob(b, rib, from, Vector3.new(to.X, 1, to.Z), dur, 18, function(z)
				debrisChunks(z, 3, 14)
				dustCloud(z, 2, 5)
				spike(z, 10, 1.8)
				playSound(b.root, SOUNDS.Impact, 0.5, 1.1)
				F.hit(F.radius(z, 5.5, 8), {}, D.Rib, z, "Medium")
			end)
		end
		F.recover(b, 1.2, "BNIdle")
	end

	Fight.define({
		id = "Bones",
		label = "The Bone Colossus",
		kind = M.Kind,
		scale = S,
		weapon = "Femur",
		idleGrip = "BNRest",
		hp = 780,
		poise = 160,
		stagger = 2.8,
		radius = 4.2,
		walk = 10.5,
		turn = 78,
		rest = { 0.6, 1.3 },
		keep = { 16, 26 },
		phase2At = 0.5,
		tempo2 = 0.9,
		restMult2 = 0.75,
		moves = {
			{ name = "Swing", fn = swing, min = 0, max = 30, weight = 5, cd = 2.5, fast = true },
			{ name = "Over", fn = over, min = 8, max = 32, weight = 4, cd = 4 },
			{ name = "Stomp", fn = stomp, min = 0, max = 11, weight = 6, cd = 3.5, behind = true },
			{ name = "Spears", fn = spearLine, min = 14, max = 90, weight = 4, cd = 5 },
			{ name = "Cage", fn = lockUp, min = 12, max = 95, weight = 5, cd = 7 },
			{ name = "Ribs", fn = ribs, min = 20, max = 95, weight = 4, cd = 9, phase2 = true },
		},
		idle = function(b)
			pose(b, "BNRest", 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			bodyPose(b, "BNIdle", 0.6)
		end,
		onStagger = function(b)
			pose(b, "BNSlump", 0.2)
			bodyPose(b, "BNCollapse", 0.2)
			debrisChunks(b.root.Position, 5, 16)
			playSound(b.root, SOUNDS.Impact, 0.8, 0.9)
		end,
		-- the entrance: slumped in a heap at the far end; it pulls itself up, howls without any breath, and comes
		intro = function(b)
			pose(b, "BNSlump", 0.2)
			bodyPose(b, "BNCollapse", 0.2)
			task.wait(0.9)
			playSound(b.root, SOUNDS.Unsheath, 1, 0.4)
			bodyPose(b, "BNHigh", 1.3)
			task.wait(1.1)
			F.draw(b, "BNHowl", "BNHowl", 0.45)
			playSound(b.root, SOUNDS.Groan, 1, 0.38)
			FxRemote:FireAllClients("Shake", b.root.Position, 0.6)
			task.wait(1.1)
			pose(b, "BNRest", 0.5)
			bodyPose(b, "BNIdle", 0.5)
			task.wait(0.3)
		end,
		-- phase 2: the howl again, and spears all round it. Half the ribs go: it's going to throw them
		phase2 = function(b)
			F.halt(b)
			F.draw(b, "BNHowl", "BNHowl", 0.5)
			playSound(b.root, SOUNDS.Groan, 1, 0.3)
			FxRemote:FireAllClients("Shake", b.root.Position, 0.9)
			local n = 0
			for _, p in ipairs(b.model:GetChildren()) do
				if p:IsA("BasePart") and p.Name == "Rib" then
					n += 1
					if n % 2 == 0 then
						p.Transparency = 1
					end
				end
			end
			F.wait(b, 0.5)
			local c = flat(b.root.Position)
			F.ring(c, 16, 0.6)
			F.wait(b, 0.6)
			for i = 1, 10 do
				local a = i / 10 * math.pi * 2
				spike(c + Vector3.new(math.cos(a) * 12, 0, math.sin(a) * 12), 14, 2.4)
			end
			F.hit(F.radius(c, 16, 8), {}, D.Spear, c, "Large")
			F.wait(b, 0.8)
			F.idle(b)
		end,
	})
end

return M
