--!nonstrict
-- THE WARDEN, candidate 1: THE TURNKEY. The man who locked everyone in and never left. Very tall and very thin, in a long
-- rotted greatcoat that swings behind him, a birdcage of iron over his head with a cold little flame shut inside it, the
-- prison's keys hung all over him - and in both hands the great key itself, as long as he is tall, the only key to the
-- only door he still cares about. A duel, slower and plainer than the Silver Knight's: he walks, he never runs; everything
-- is heaved round with his whole body and given a long look first, and after every blow the key's weight leaves him open.
-- It teaches you to read a wind-up, roll through it, and take your two hits.
-- Phase 1: the two cuts, the thrust that sticks in the floor, the overhead that splits the floor in a line, the turning
-- sweep (for when you're behind him), and the chain and hook that drag you back if you hang off at range.
-- Phase 2 at half health: he breaks the cage's flame out along the key, and adds a third cut and a throw - the key thrown
-- spinning out and back, leaving him empty handed while it's gone. Fight's plumbing: ReplicatedStorage/WardenFight.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fight = require(ReplicatedStorage:WaitForChild("WardenFight"))
local Garb = require(ReplicatedStorage:WaitForChild("WardenGarb"))

local S = 3.3 -- (the Silver Knight is 2.0)
local K = S / 1.95 -- (his reach and his marks were laid out at 1.95: they grow with him)
local M = {}
M.Kind = "WardenTurnkey"
M.Proportions = { girth = 0.82, arm = 1.25, hunch = 0.16, twoHand = -0.75, limbs = true, walkRef = 3, cadence = 0.85 }
M.IdlePose = "TKIdle"
M.Poses = {
	-- at rest: stooped under his own height, the key let down before him in both hands, weight on the back foot
	TKIdle = { drop = 0.22, lean = 0.2, twist = -0.1, head = 0.16, footR = -0.32, footL = 0.42, spread = 0.14, breathe = 2, freeL = 0, rwr = 0.1, toe = 0.05 },
	-- rising up to his full height, the key dragged up over his right shoulder
	TKUp = { drop = 0.02, lean = -0.2, twist = -0.5, hip = -0.25, head = -0.12, look = 0.35, footR = -0.55, footL = 0.45, spread = 0.2, breathe = 3.5, freeL = 0, rwr = -0.6, lwr = -0.4, toe = 0.5 },
	-- the cut: everything falling through it onto the front foot
	TKCutThrough = { drop = 0.72, lean = 0.62, twist = 0.85, hip = 0.45, side = 0.1, head = 0.1, look = -0.4, footR = 0.95, footL = -0.75, spread = 0.28, freeL = 0, rwr = 0.5, lwr = 0.4, toe = 0.35 },
	-- the backhand's coil: already wound the other way, low
	TKBackSet = { drop = 0.55, lean = 0.25, twist = 1.1, hip = 0.6, side = 0.08, head = 0.05, look = -0.8, footR = 0.8, footL = -0.5, spread = 0.3, breathe = 3.5, freeL = 0, rwr = -0.5, lwr = -0.3, toe = 0.4 },
	TKBackThrough = { drop = 0.7, lean = 0.55, twist = -0.9, hip = -0.5, side = -0.1, head = 0.1, look = 0.4, footR = -0.6, footL = 0.95, spread = 0.28, freeL = 0, rwr = 0.5, lwr = 0.4, toe = 0.35 },
	-- the thrust: drawn right back along his own length, the front foot just touching...
	TKThrustSet = { drop = 0.5, lean = -0.22, twist = -0.72, hip = -0.3, head = -0.05, look = 0.65, footR = -1.0, footL = 0.8, spread = 0.1, liftL = 0.15, breathe = 4, freeL = 0, rwr = -0.4, toe = 0.65 },
	-- ...and driven on a long stiff lunge, all of him along the line of it
	TKLunge = { drop = 0.95, lean = 0.88, twist = 0.35, head = -0.15, footR = 1.25, footL = -1.2, spread = 0.1, freeL = 0, rwr = 0.2, lwr = 0.2, toe = 0.4 },
	-- bent over the key where it's stuck in the floor, hauling
	TKHaul = { drop = 1.0, lean = 0.85, head = 0.32, footR = 0.7, footL = -0.9, spread = 0.3, breathe = 5, freeL = 0, rwr = 0.5, lwr = 0.5, toe = 0.25 },
	-- the overhead: up on his toes, arched back, the key straight up over his head and past it
	TKOverhead = { drop = 0, lean = -0.42, twist = 0.05, head = -0.4, footR = -0.45, footL = 0.5, spread = 0.18, breathe = 5, freeL = 0, rwr = -0.7, lwr = -0.7, toe = 0.75 },
	TKFold = { drop = 1.35, lean = 1.05, head = -0.15, footR = 1.0, footL = -0.85, spread = 0.34, freeL = 0, rwr = 0.5, lwr = 0.5, toe = 0.4 },
	-- the turning sweep: sunk wide and wound away
	TKWind = { drop = 0.95, lean = 0.3, twist = -1.3, hip = -0.75, side = -0.12, look = 1.0, footR = -0.7, footL = 0.8, spread = 0.42, breathe = 4.5, freeL = 0, rwr = -0.6, lwr = -0.5, toe = 0.6 },
	TKSpin = { drop = 0.7, lean = 0.2, twist = 0.2, footR = -0.2, footL = 0.25, spread = 0.38, freeL = 0, toe = 0.25 },
	-- the hook: left arm flung out at you, the chain swinging from it
	TKAim = { drop = 0.3, lean = -0.05, twist = -0.55, head = 0, look = 0.55, footR = -0.7, footL = 0.55, spread = 0.2, la1 = 1.55, la2 = 0, la3 = -0.2, lel = 0.1, breathe = 3, freeL = 0, lwr = 0.2 },
	TKCast = { drop = 0.55, lean = 0.45, twist = 0.55, footR = 0.75, footL = -0.65, spread = 0.2, la1 = 1.35, la3 = -0.1, lel = 0, freeL = 0, lwr = 0.4 },
	TKThrowSet = { drop = 0.55, lean = -0.3, twist = -1.2, hip = -0.6, side = -0.18, look = 1, footR = -0.9, footL = 0.8, spread = 0.36, la1 = 1.45, la3 = -0.25, lel = 0.1, breathe = 4, freeL = 0, rwr = -1, toe = 0.55 },
	TKThrow = { drop = 0.55, lean = 0.7, twist = 1, hip = 0.5, head = -0.15, footR = 1.05, footL = -0.9, spread = 0.34, la1 = -0.3, la3 = -0.5, lel = 0.3, freeL = 0, rwr = 0.6, toe = 0.4 },
	-- empty handed, watching it go
	TKEmpty = { drop = 0.25, lean = 0.05, head = 0, footR = -0.2, footL = 0.3, spread = 0.2, la1 = 0.5, la3 = -0.5, lel = 0.6, ra1 = 0.5, ra3 = 0.5, rel = 0.6, breathe = 3, freeL = 0 },
	TKBreak = { drop = 0.1, lean = -0.5, head = -0.55, la1 = 2.3, la3 = -0.8, lel = 0.5, footR = 0.35, footL = -0.4, spread = 0.26, breathe = 6, freeL = 0, rwr = -0.6, lwr = -0.8 },
	-- doubled over, the key's end on the floor, holding himself up on it
	TKReel = { drop = 0.9, lean = 0.75, twist = -0.25, side = 0.18, head = 0.42, footR = 0.3, footL = -0.55, spread = 0.26, breathe = 6, freeL = 0, rwr = 0.3, lwr = 0.4 },
}
local COAT, COAT_DK, IRON, IRON_DK, LEATHER, FLAME = Color3.fromRGB(46, 50, 46), Color3.fromRGB(28, 30, 28), Color3.fromRGB(70, 68, 66), Color3.fromRGB(38, 36, 36), Color3.fromRGB(52, 40, 30), Color3.fromRGB(166, 220, 226)
local SKIN = Color3.fromRGB(96, 92, 80)
M.Colors = { skin = SKIN, torso = COAT, legs = COAT_DK, arms = COAT }
M.FistSkin = true

-- the ring of keys at the hip
function M.LookKeys(k)
	local deco, V, at, MAT, hw = k.deco, k.V, k.at, k.MAT, k.hw
	deco("Hips", "KeyRing", V(0.08, 0.55, 0.55), at(hw * 0.86, -0.05, 0), IRON_DK, MAT.Metal, Enum.PartType.Ball)
	for i = -2, 2 do
		deco("Hips", "HipKey", V(0.07, 0.62, 0.16), at(hw * 0.88, -0.42, i * 0.09) * CFrame.Angles(i * 0.12, 0, 0), IRON, MAT.Metal)
	end
end

-- everything below the head
function M.LookCoat(k)
	local deco, parts, V, at, MAT, D, s = k.deco, k.parts, k.V, k.at, k.MAT, k.D, k.s
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local shin, th = D.shin / s, D.thigh / s
	local rng = Random.new(1955)
	Garb.sink(k, { "Chest", "Hips", "RUpperArm", "LUpperArm", "RLowerArm", "LLowerArm", "RThigh", "LThigh", "RShin", "LShin", "RFoot", "LFoot", "RToe", "LToe", "RHand", "LHand" }, 0.78, COAT_DK)
	-- the greatcoat: rows of worn overlapping cloth, buttoned to the throat, a collar of stiff pieces stood up round the neck
	local ca, cc = cw * 0.68, cd * 0.76
	Garb.shell(k, "Chest", rng, { a = ca, c = cc, top = ch / 2 + 0.05, bottom = -ch / 2 - 0.1, n = 20, tiers = 4, color = COAT, dark = COAT_DK, name = "CoatFold" })
	Garb.shell(k, "Chest", rng, { a = cw * 0.58, c = cd * 0.62, top = ch / 2 + 0.3, bottom = ch / 2 - 0.1, n = 14, tiers = 1, color = COAT, dark = COAT_DK, flare = 0.75, name = "Mantle" })
	Garb.shell(k, "Chest", rng, { a = 0.72, c = 0.66, top = ch / 2 + 0.72, bottom = ch / 2 + 0.12, n = 14, tiers = 1, color = COAT_DK, dark = IRON_DK, flare = -0.32, name = "Collar" })
	-- the placket and its double row of buttons
	local front = -cc * 1.13 - 0.03
	for i = 0, 6 do
		deco("Chest", "Placket", V(0.42, ch / 7 * 1.12, 0.05), at(rng:NextNumber(-0.012, 0.012), ch / 2 - (i + 0.5) * ch / 7, front), COAT_DK, MAT.Fabric)
		for _, x in ipairs({ -0.11, 0.11 }) do
			deco("Chest", "Button", V(0.1, 0.1, 0.06), at(x, ch / 2 - (i + 0.5) * ch / 7, front - 0.05), IRON, MAT.Metal, Enum.PartType.Ball)
		end
	end
	-- a strap across the chest in short riveted lengths, front and back, with more keys on it
	for _, side in ipairs({ -1, 1 }) do
		for i = 0, 8 do
			local t = i / 8
			local x, y = 0.86 - 1.72 * t, ch / 2 - ch * t
			local z = side * cc * 1.16 * math.sqrt(math.max(1 - (x / (ca * 1.16)) ^ 2, 0.05)) + side * 0.03
			deco("Chest", "StrapPiece", V(0.34, 0.2, 0.05), at(x, y, z) * CFrame.Angles(0, 0, 0.82), LEATHER:Lerp(COAT_DK, i % 2 * 0.25), MAT.Leather)
			deco("Chest", "Rivet", V(0.06, 0.06, 0.06), at(x, y, z + side * 0.03), IRON, MAT.Metal, Enum.PartType.Ball)
			if side == -1 and i % 2 == 1 then
				deco("Chest", "StrapKey", V(0.07, 0.36, 0.05), at(x, y - 0.2, z - 0.05) * CFrame.Angles(0, 0, 0.2), IRON, MAT.Metal)
			end
		end
	end
	-- hips, and a belt in short lengths
	local hipY = D.hipsSize.Y / s
	Garb.shell(k, "Hips", rng, { a = hw * 0.72, c = hd * 0.8, top = hipY / 2 + 0.05, bottom = -hipY / 2 - 0.2, n = 14, tiers = 2, color = COAT, dark = COAT_DK, flare = 0.12, name = "CoatFold" })
	Garb.hoop(k, "Hips", 0.25, hw * 0.8, hd * 0.88, 16, 0.26, LEATHER, MAT.Leather, "Belt")
	deco("Hips", "Buckle", V(0.34, 0.3, 0.06), at(0, 0.25, -hd * 0.88 - 0.13), IRON, MAT.Metal)
	-- the ring of keys at his hip
	M.LookKeys(k)
	-- the coat's skirts, slow to swing, to his calves, open down the front
	Garb.skirt(k, "Hips", rng, { a = hw * 0.74, c = hd * 0.84, y = -hipY / 2, n = 11, len = 0.6, color = COAT, dark = COAT_DK, from = -0.4, to = 0.4 })
	for _, n in ipairs({ "R", "L" }) do
		Garb.shell(k, n .. "UpperArm", rng, { a = aw * 0.82, c = aw * 0.82, top = ua / 2 + 0.05, bottom = -ua / 2, n = 8, tiers = 2, color = COAT, dark = COAT_DK, name = "CoatFold" })
		Garb.shell(k, n .. "LowerArm", rng, { a = aw * 0.8, c = aw * 0.8, top = la / 2 + 0.05, bottom = -la / 2 + 0.2, n = 8, tiers = 2, color = COAT, dark = COAT_DK, name = "CoatFold" })
		Garb.hoop(k, n .. "UpperArm", ua / 2 - 0.05, aw * 0.9, aw * 0.9, 9, 0.16, COAT_DK, MAT.Fabric, "Shoulder")
		for i = 0, 1 do
			Garb.hoop(k, n .. "LowerArm", -la / 2 + 0.2 + i * 0.14, aw * 0.88, aw * 0.88, 9, 0.13, LEATHER, MAT.Leather, "Cuff")
		end
		Garb.fist(k, n .. "Hand", 0, aw * 1, LEATHER, COAT_DK)
		Garb.shell(k, n .. "Thigh", rng, { a = lw * 0.76, c = lw * 0.76, top = th / 2, bottom = -th / 2, n = 7, tiers = 2, color = COAT_DK, dark = IRON_DK, name = "Trouser" })
		Garb.wraps(k, n .. "Shin", rng, shin / 2, -shin / 2, lw * 0.5, 8, LEATHER, COAT_DK, MAT.Leather)
		Garb.foot(k, n .. "Foot", D.footSize / s, LEATHER, COAT_DK)
		Garb.foot(k, n .. "Toe", D.toeSize / s, LEATHER, COAT_DK)
	end
end

-- no face: under a birdcage of iron, a shut little lantern-flame where a head would be
local function lookCage(k)
	local deco, parts, V, at, MAT = k.deco, k.parts, k.V, k.at, k.MAT
	parts.Head.Size = V(0.5, 0.5, 0.5)
	parts.Head.Transparency = 1
	local ember = deco("Head", "CageFlame", V(0.46, 0.62, 0.46), at(0, -0.02, 0), FLAME, MAT.Neon, Enum.PartType.Ball)
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness = FLAME, 28, 1.4
	light.Parent = ember
	Garb.disc(k, "Head", -0.55, 0.6, 0.12, IRON_DK, MAT.Metal, "CageFloor")
	Garb.hoop(k, "Head", 0.15, 0.56, 0.56, 12, 0.08, IRON_DK, MAT.Metal, "CageRing")
	Garb.disc(k, "Head", 0.72, 0.52, 0.12, IRON_DK, MAT.Metal, "CageTop")
	Garb.disc(k, "Head", 0.98, 0.1, 0.5, IRON, MAT.Metal, "CageFinial")
	for i = 0, 7 do
		local a = i * math.pi / 4
		deco("Head", "CageBar", V(0.07, 1.3, 0.07), at(math.sin(a) * 0.54, 0.08, math.cos(a) * 0.54), IRON, MAT.Metal)
	end
end

function M.Look(k)
	M.LookCoat(k)
	lookCage(k)
end

-- the shank and bow of a great key, without its bit
function M.keyShank(w)
	local mk, add, s = w.mk, w.add, w.scale
	local iron, dark = Color3.fromRGB(78, 74, 70), Color3.fromRGB(40, 38, 38)
	local function rod(name, y, long, d, color)
		local p = mk(name, Vector3.new(long, d, d), color, Enum.Material.Metal)
		p.Shape = Enum.PartType.Cylinder
		add(p, y, Garb.UP)
	end
	local handle = mk("Shank", Vector3.new(0.2, 3, 0.2), iron, Enum.Material.Metal)
	handle.Transparency = 1
	rod("ShankCore", 0, 3, 0.36, iron)
	rod("Shank2", -3.6, 4.5, 0.32, iron)
	for i = 0, 10 do
		rod("Collar", -0.7 - i * 0.48, i % 3 == 0 and 0.2 or 0.09, i % 3 == 0 and 0.56 or 0.42, dark)
	end
	-- the bow, a ring of forged lengths round the top
	local N, c = 14, 2.05
	for i = 0, N - 1 do
		local a = i / N * 2 * math.pi
		local p = mk("Bow", Vector3.new(0.52, 0.28, 0.28), iron, Enum.Material.Metal)
		p.Shape = Enum.PartType.Cylinder
		add(p, c + math.sin(a) * 0.78, CFrame.new(math.cos(a) * 0.78 * s, 0, 0) * CFrame.Angles(0, 0, a + math.pi / 2))
	end
	return handle
end

M.Weapons = {
	-- the great key: a ring bow at his hands, a long square iron shank, wards like a broken comb at the end of it
	GreatKey = function(w)
		local mk, add, s = w.mk, w.add, w.scale
		local dark, rust = Color3.fromRGB(40, 38, 38), Color3.fromRGB(96, 62, 44)
		local handle = M.keyShank(w)
		-- the bit: a spine and a comb of uneven teeth, a tooth gone, no slab of iron
		add(mk("Bit", Vector3.new(0.34, 1.75, 0.3), rust, Enum.Material.Metal), -5.1, CFrame.new(0.28 * s, 0, 0))
		for i, y in ipairs({ -4.4, -4.72, -5.04, -5.36, -5.72 }) do
			if i ~= 3 then
				local long = 0.85 + (i * 7 % 4) * 0.18
				add(mk("Ward", Vector3.new(long, 0.22, 0.26), i % 2 == 0 and dark or rust, Enum.Material.Metal), y, CFrame.new((0.4 + long / 2) * s, 0, 0))
			end
		end
		add(mk("Tip", Vector3.new(0.42, 0.42, 0.42), dark, Enum.Material.Metal), -5.95)
		return { handle = handle, bladeLen = 5.6, gripC1 = CFrame.new(0, 1.05 * s, 0) }
	end,
}
local R = math.rad
local function out(yaw, tilt)
	return CFrame.Angles(0, R(yaw), 0) * CFrame.Angles(0, 0, R(tilt))
end
M.Grips = {
	TKRest = { Vector3.new(0.3, 0.5, -1.5), CFrame.Angles(R(25), 0, R(4)) }, -- (let down before him, point at the floor)
	TKShoulder = { Vector3.new(1.5, 1.6, 0.6), out(-110, 145) },
	TKCutMid = { Vector3.new(0.7, -0.3, -2.5), out(70, 62) },
	TKCutEnd = { Vector3.new(-1.8, -0.5, -0.7), out(190, 60) },
	TKBackSet = { Vector3.new(-1.7, 0.9, 0.2), out(215, 100) },
	TKBackMid = { Vector3.new(0.3, -0.4, -2.6), out(95, 62) },
	TKBackEnd = { Vector3.new(2.1, -0.5, -0.5), out(-5, 60) },
	TKThrustSet = { Vector3.new(1.3, 1.1, 1.3), CFrame.Angles(R(92), R(-10), 0) },
	TKThrust = { Vector3.new(0.3, -0.2, -2.7), CFrame.Angles(R(75), 0, 0) },
	TKStuck = { Vector3.new(0.3, -0.6, -2.3), CFrame.Angles(R(55), 0, 0) },
	TKOverhead = { Vector3.new(0.5, 3.1, 0.2), CFrame.Angles(R(200), 0, 0) },
	TKDown = { Vector3.new(0.2, -0.4, -2.5), CFrame.Angles(R(58), 0, 0) },
	TKWindLow = { Vector3.new(1.9, 0.1, 1.5), out(-70, 76) },
	TKSweepR = { Vector3.new(2.5, -0.5, -0.5), out(10, 62) },
	TKSweepF = { Vector3.new(0, -0.5, -2.8), out(90, 62) },
	TKSweepL = { Vector3.new(-2.5, -0.5, -0.5), out(170, 62) },
	TKSweepB = { Vector3.new(-1.3, -0.5, 2.1), out(250, 62) },
	TKThrowSet = { Vector3.new(1.8, 2.2, 1.5), out(-80, 100) },
	TKThrown = { Vector3.new(0.9, 1.4, -2.5), out(90, 90) },
	TKPlant = { Vector3.new(0.3, 0.2, -1.8), CFrame.Angles(R(18), 0, 0) },
	TKBroke = { Vector3.new(1.0, 3.0, -0.7), CFrame.Angles(R(170), 0, R(10)) },
}
M.BodyFor = {}

---------------------------------------------------------------------------
-- server: the fight
---------------------------------------------------------------------------
-- every move, written for a body of reach K. opts (for the hybrids): afterHook(b, target) instead of the thrust once the chain
-- has you; stuck(b, target, floorPos) instead of hauling a thrust out; splitEnd(b, pos) where a floor split runs out; onCatch(b)
-- when the thrown key's home
function M.moves(core, K, opts)
	opts = opts or {}
	local F = Fight.init(core)
	local SOUNDS, playSound, burst, pose, bodyPose, setTrail, dustCloud, crackLines, fadeAway, flat, now = core.SOUNDS, core.playSound, core.burst, core.pose, core.bodyPose, core.setTrail, core.dustCloud, core.crackLines, core.fadeAway, core.flat, core.now
	local BLUE = Color3.fromRGB(166, 220, 226)
	local D = { Cut = 18, Thrust = 22, Overhead = 22, Split = 14, Sweep = 20, Hook = 8, Key = 16 }

	local function tipFloor(b)
		local _, tip = F.ends(b)
		local p = tip or (b.root.Position + F.fwd(b) * 12)
		return Vector3.new(p.X, 0.15, p.Z)
	end

	-- a cut, either way, its coil given a long look: he stops following you most of the way through it
	local function cut(b, target, set, mid, finish, bodySet, bodyThrough, tell, step, level)
		F.draw(b, set, bodySet, tell * 0.45 * F.tempo())
		playSound(b.root, SOUNDS.Unsheath, 0.7, 0.5)
		if not F.track(b, target, tell * F.tempo(), 0.6) then
			return false
		end
		setTrail(b, true)
		F.step(b, step * K, 0.25)
		playSound(b.root, SOUNDS.Lunge, 0.8, 0.65)
		bodyPose(b, bodyThrough, 0.16)
		pose(b, mid, 0.09, Enum.EasingStyle.Linear)
		task.delay(0.09, function()
			pose(b, finish, 0.11, Enum.EasingStyle.Quad)
		end)
		F.sweep(b, 0.22, D.Cut, level or "Medium", {}, 1.6 * K)
		setTrail(b, false)
		return F.free(b)
	end

	local function twoCuts(b, target)
		F.halt(b)
		if not cut(b, target, "TKShoulder", "TKCutMid", "TKCutEnd", "TKUp", "TKCutThrough", 0.85, 5) then
			return
		end
		if not F.hold(b, 0.22) then
			return
		end
		if not cut(b, target, "TKBackSet", "TKBackMid", "TKBackEnd", "TKBackSet", "TKBackThrough", 0.62, 4, "Medium") then
			return
		end
		if F.phase2() and math.random() < 0.6 then
			if not F.hold(b, 0.15) then
				return
			end
			if not cut(b, target, "TKShoulder", "TKCutMid", "TKCutEnd", "TKUp", "TKCutThrough", 0.6, 4, "Large") then
				return
			end
		end
		F.recover(b, 1.15, "TKHaul")
	end

	-- THE THRUST: drawn right back, a glint down it, then a long stiff lunge that buries the key in the floor. He has to
	-- haul it out: your longest opening
	local function thrust(b, target)
		F.halt(b)
		if not F.beats(b, target, {
			{ "TKThrustSet", "TKThrustSet", 0.55 },
			{ "TKThrustSet", "TKThrustSet", 0.5, function()
				local _, tip = F.ends(b)
				if tip then
					burst(tip, Color3.fromRGB(240, 240, 230), 16, 0.4, 8)
				end
				playSound(b.root, SOUNDS.Unsheath, 0.8, 1.6)
			end },
		}, 0.75) then
			return
		end
		setTrail(b, true)
		F.draw(b, "TKThrust", "TKLunge", 0.1)
		playSound(b.root, SOUNDS.Lunge, 1, 0.55)
		F.step(b, 13 * K, 0.32)
		F.sweep(b, 0.32, D.Thrust, "Large", {}, 1.7 * K)
		setTrail(b, false)
		if not F.free(b) then
			return
		end
		F.draw(b, "TKStuck", "TKHaul", 0.14)
		local at = tipFloor(b)
		burst(at, Color3.fromRGB(230, 220, 190), 18, 0.3, 14)
		playSound(b.root, SOUNDS.Impact, 0.7, 1.1)
		dustCloud(at, 1.6, 6)
		if opts.stuck then
			opts.stuck(b, target, at)
			return
		end
		if F.hold(b, 1.45 * F.tempo()) then
			playSound(b.root, SOUNDS.Unsheath, 0.6, 0.6)
			F.idle(b)
			F.hold(b, 0.2)
		end
	end

	-- THE OVERHEAD: all the way up on his toes, a strip of floor lit where it's going to fall, then folded down behind it;
	-- the floor splits along the strip a moment later
	local function overhead(b, target)
		F.halt(b)
		if not F.beats(b, target, {
			{ "TKShoulder", "TKUp", 0.4 },
			{ "TKOverhead", "TKOverhead", 0.55 },
		}, 0.7) then
			return
		end
		local from = flat(b.root.Position) + F.fwd(b) * 4 * K
		local to = from + F.fwd(b) * 34 * K
		F.strip(from, to, 7 * K, 0.55)
		playSound(b.root, SOUNDS.Unsheath, 0.8, 0.45)
		if not F.track(b, target, 0.5, 0) then
			return
		end
		setTrail(b, true)
		F.draw(b, "TKDown", "TKFold", 0.1)
		playSound(b.root, SOUNDS.Lunge, 0.95, 0.5)
		F.step(b, 3 * K, 0.15)
		F.sweep(b, 0.14, D.Overhead, "Knockdown", {}, 1.8 * K)
		setTrail(b, false)
		if not F.live(b) then
			return
		end
		F.quake(b, tipFloor(b), 7 * K, 1.3)
		-- the split: running along the strip, away from him
		local seen = {}
		local cracks = crackLines(Vector3.new(to.X, 0.15, to.Z), 4, 4, nil, nil, 0.2)
		fadeAway(cracks, 1.5, 1)
		for i = 1, 6 do
			task.delay(i * 0.07, function()
				if F.live(b) then
					local p = from:Lerp(to, i / 6)
					dustCloud(p, 2.2, 6)
					core.debrisChunks(p + Vector3.new(0, 0.5, 0), 3, 14)
					F.hit(F.radius(p, 3.5 * K, 6), seen, D.Split, p, "Medium")
				end
			end)
		end
		if opts.splitEnd then
			task.delay(0.5, function()
				if F.live(b) then
					opts.splitEnd(b, to)
				end
			end)
		end
		F.recover(b, 1.3, "TKHaul")
	end

	-- THE TURN: sunk wide and wound away, a sound of the key dragging, then a whole turn on his heel with it held out
	local function spin(b, target)
		F.halt(b)
		if not F.beats(b, target, {
			{ "TKWindLow", "TKWind", 0.5 },
			{ "TKWindLow", "TKWind", 0.5, function()
				playSound(b.root, SOUNDS.Unsheath, 0.9, 0.38)
				dustCloud(F.feet(b), 2, 6)
			end },
		}, 0.55) then
			return
		end
		setTrail(b, true)
		local root = b.root
		root.Anchored = true
		local base = root.CFrame
		bodyPose(b, "TKSpin", 0.1)
		playSound(root, SOUNDS.Lunge, 1, 0.5)
		local seen = {}
		task.spawn(F.sweep, b, 0.7, D.Sweep, "Large", seen, 1.8 * K)
		local grips = { "TKSweepR", "TKSweepF", "TKSweepL", "TKSweepB", "TKSweepR" }
		for i, g in ipairs(grips) do
			if not F.live(b) then
				return
			end
			pose(b, g, 0.13, Enum.EasingStyle.Linear)
			local t0 = now()
			while now() - t0 < 0.14 do
				local a = ((i - 1) + (now() - t0) / 0.14) / #grips
				root.CFrame = base * CFrame.Angles(0, -a * math.pi * 1.5, 0)
				task.wait()
			end
		end
		setTrail(b, false)
		root.Anchored = false
		dustCloud(F.feet(b), 2, 6)
		F.recover(b, 1.2, "TKHaul")
	end

	-- THE HOOK: if you hang off at range. His left arm comes out at you; a strip on the floor; the chain goes out dead straight
	-- along it and, if it finds you, drags you most of the way back to him
	local function hook(b, target)
		F.halt(b)
		local chain
		F.setCleanup(function()
			if chain and chain.Parent then
				chain:Destroy()
			end
		end)
		F.draw(b, "TKRest", "TKAim", 0.4 * F.tempo())
		playSound(b.root, SOUNDS.Unsheath, 0.7, 1.2)
		if not F.track(b, target, 0.75 * F.tempo(), 0.7) then
			return
		end
		local start = Vector3.new(b.root.Position.X, 4, b.root.Position.Z) + F.fwd(b) * 3 * K
		local dir = F.fwd(b)
		local LEN = 62
		F.strip(flat(start), flat(start) + dir * LEN, 3, 0.3)
		if not F.track(b, target, 0.3, 0) then
			return
		end
		F.draw(b, "TKRest", "TKCast", 0.12)
		playSound(b.root, SOUNDS.Lunge, 1, 1.1)
		chain = F.part({ Name = "HookChain", Size = Vector3.new(0.8, 0.8, 1), Material = Enum.Material.DiamondPlate, Color = Color3.fromRGB(64, 62, 58) })
		local head = F.part({ Name = "Hook", Size = Vector3.new(2.6, 2.6, 2.6), Material = Enum.Material.Metal, Color = Color3.fromRGB(78, 74, 70) })
		local seen, caught = {}, false
		local t0 = now()
		while now() - t0 < 0.42 and F.live(b) do
			local reach = (now() - t0) / 0.42 * LEN
			local tip = start + dir * reach
			chain.Size = Vector3.new(0.8, 0.8, math.max(reach, 1))
			chain.CFrame = CFrame.lookAt(start + dir * reach / 2, tip)
			head.CFrame = CFrame.new(tip) * CFrame.Angles(reach, reach, 0)
			for _, pl in ipairs(F.radius(tip, 4, 8)) do
				if not seen[pl] then
					-- (from behind you: the blow carries you toward him)
					F.hit({ pl }, seen, D.Hook, tip + dir * 5, "Large", 130)
					caught = caught or seen[pl] == true
				end
			end
			task.wait()
		end
		head:Destroy()
		if chain.Parent then
			F.fade(chain, 0.2)
		end
		if caught and F.free(b) then
			F.hold(b, 0.25);
			(opts.afterHook or thrust)(b, target)
			return
		end
		F.recover(b, 0.75, false)
	end

	-- THE THROW (phase 2): hauled back over his shoulder, flung, spinning flat out across the room and home again. He's
	-- empty handed while it's gone, and that's your chance
	local function throwKey(b, target)
		F.halt(b)
		local key
		F.setCleanup(function()
			if key and key.Parent then
				key:Destroy()
			end
			if b.model.Parent then
				F.hideWeapon(b, false)
			end
		end)
		if not F.beats(b, target, {
			{ "TKThrowSet", "TKThrowSet", 0.5 },
			{ "TKThrowSet", "TKThrowSet", 0.55, function()
				playSound(b.root, SOUNDS.Unsheath, 1, 1.4)
			end },
		}, 0.85) then
			return
		end
		F.draw(b, "TKThrown", "TKThrow", 0.1)
		playSound(b.root, SOUNDS.Lunge, 1, 0.55)
		local handle
		key, handle = F.cloneWeapon(b)
		F.hideWeapon(b, true)
		if not key then
			return
		end
		local start = Vector3.new(b.root.Position.X, 4.5, b.root.Position.Z)
		local dir = F.fwd(b)
		local goal = F.clamp(start + dir * 58, 2)
		goal = Vector3.new(goal.X, 4.5, goal.Z)
		local seen, spinA, t0, whirr = {}, 0, now(), 0
		local OUT, HOME = 0.85, 0.85
		bodyPose(b, "TKEmpty", 0.3)
		while F.live(b) do
			local dt = task.wait()
			local el = now() - t0
			spinA += dt * 16
			local p
			if el < OUT then
				local a = el / OUT
				p = start:Lerp(goal, 1 - (1 - a) * (1 - a))
			else
				if not seen.home then
					seen = { home = true } -- (it can catch you on the way back too)
				end
				local a = math.min((el - OUT) / HOME, 1)
				local back = Vector3.new(b.root.Position.X, 4.5, b.root.Position.Z)
				p = goal:Lerp(back, a * a)
				if a >= 1 then
					break
				end
			end
			handle.CFrame = CFrame.new(p) * CFrame.Angles(0, spinA, 0) * CFrame.Angles(0, 0, math.pi / 2)
			F.hit(F.radius(p, 12, 8), seen, D.Key, p, "Large")
			F.turn(b, p, math.rad(300) * dt)
			if now() > whirr then
				whirr = now() + 0.25
				playSound(handle, SOUNDS.Slash, 0.8, 0.6)
			end
		end
		key:Destroy()
		key = nil
		F.hideWeapon(b, false)
		F.setCleanup(nil)
		if F.live(b) then
			playSound(b.root, SOUNDS.Impact, 0.5, 1.2)
			if opts.onCatch then
				opts.onCatch(b)
			end
			F.draw(b, "TKRest", "TKIdle", 0.2)
			F.hold(b, 0.5)
		end
	end

	local function idle(b)
		pose(b, "TKRest", 0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		bodyPose(b, "TKIdle", 0.55)
	end
	local function onStagger(b)
		pose(b, "TKPlant", 0.2)
		bodyPose(b, "TKReel", 0.15)
	end
	-- the entrance: stood with his back to you at the far end; he turns his head, then all of him, and walks
	local function intro(b)
		pose(b, "TKPlant", 0.2)
		bodyPose(b, "TKReel", 0.3)
		task.wait(0.7)
		playSound(b.root, SOUNDS.Groan, 1, 0.42)
		bodyPose(b, "TKUp", 0.9)
		pose(b, "TKShoulder", 0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		task.wait(1.1)
		playSound(b.root, SOUNDS.Unsheath, 0.9, 0.5)
		pose(b, "TKRest", 0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		bodyPose(b, "TKIdle", 0.7)
		task.wait(0.5)
	end
	-- blue fire along the key
	local function ignite(b)
		local w = b.model:FindFirstChild("Weapon")
		if w then
			for _, n in ipairs({ "Bit", "Shank2" }) do
				local p = w:FindFirstChild(n)
				if p then
					local e = Instance.new("Fire")
					e.Size, e.Heat, e.Color, e.SecondaryColor = 6, 6, BLUE, Color3.fromRGB(40, 70, 90)
					e.Parent = p
				end
			end
			local bit = w:FindFirstChild("Bit")
			if bit then
				local l = Instance.new("PointLight")
				l.Color, l.Range, l.Brightness = BLUE, 18, 1.6
				l.Parent = bit
			end
		end
	end
	-- phase 2: the flame in the cage breaks out along the key
	local function phase2(b)
		F.halt(b)
		F.draw(b, "TKBroke", "TKBreak", 0.5)
		playSound(b.root, SOUNDS.Groan, 1, 0.34)
		core.FxRemote:FireAllClients("Shake", b.root.Position, 0.7)
		task.wait(0.6)
		ignite(b)
		burst(b.root.Position + Vector3.new(0, 5, 0), BLUE, 40, 0.5, 18)
		F.wait(b, 0.8)
		F.idle(b)
	end

	return { cut = cut, tipFloor = tipFloor, twoCuts = twoCuts, thrust = thrust, overhead = overhead, spin = spin, hook = hook, throwKey = throwKey, idle = idle, onStagger = onStagger, intro = intro, ignite = ignite, phase2 = phase2 }
end

function M.init(core)
	local mv = M.moves(core, K)
	Fight.define({
		id = "Turnkey",
		label = "The Turnkey (a slow duel: key and chain)",
		kind = M.Kind,
		scale = S,
		weapon = "GreatKey",
		idleGrip = "TKRest",
		hp = 800,
		poise = 180,
		stagger = 2.6,
		radius = 2.4 * K,
		walk = 10.5,
		turn = 82,
		rest = { 0.55, 1.25 },
		keep = { 15, 25 },
		phase2At = 0.5,
		tempo2 = 0.88,
		restMult2 = 0.75,
		moves = {
			{ name = "TwoCuts", fn = mv.twoCuts, min = 0, max = 26, weight = 5, cd = 1.5, fast = true },
			{ name = "Thrust", fn = mv.thrust, min = 10, max = 40, weight = 3.5, cd = 5 },
			{ name = "Overhead", fn = mv.overhead, min = 0, max = 38, weight = 3, cd = 6 },
			{ name = "Spin", fn = mv.spin, min = 0, max = 22, weight = 2, cd = 7, behind = true },
			{ name = "Hook", fn = mv.hook, min = 38, max = 90, weight = 4, cd = 6 },
			{ name = "ThrowKey", fn = mv.throwKey, min = 20, max = 90, weight = 3, cd = 11, phase2 = true },
		},
		idle = mv.idle,
		onStagger = mv.onStagger,
		intro = mv.intro,
		phase2 = mv.phase2,
	})
end

return M
