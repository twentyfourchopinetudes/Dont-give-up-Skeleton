--!nonstrict
-- THE LAST CASTELLAN: the keep's knight, on its battlements. Bulky polished plate, a red
-- tabard and mantle, a crowned great helm; a great gilded flanged mace and a tall
-- rectangular shield up to his chest, its foot always just off the stone.
-- Slow, long strings of blows, each one carried by his whole body - and the mace is too
-- heavy even for him: he heaves it up with his hips, it hangs at the top, it drags him
-- after it on the follow-through, and he hauls it back out of the stone to go again.
-- Very tanky: a deep health bar, heavy poise, hyper armour mid-string, and while he
-- stands guard between strings his shield turns aside anything from the front.
-- Phase 2 at 70%: his oath burns gold, the bar shows his name, and his Judgement runs to
-- five smashes. Tuning: Config.Castellan. Moves and how he picks them: MOVES near the bottom.
-- Killing him enables the prison's bell (Map.Bell; init.server rings it).
--
-- EVERYTHING ABOUT THIS CHARACTER IS IN THIS ONE FILE (same layout as Warden.lua):
--   M.Proportions / M.Poses   body shape and its full-body poses
--   M.Colors / M.Look         how the rig is dressed (the shield is built at spawn: it hangs
--                             off his root on a weld the server tweens, so it never dips
--                             with his body - see SHIELD)
--   M.Weapons / M.Grips       the mace, and the grip poses his swings tween between
--   M.init(Core) and below    behaviour (server only)
-- Grips borrowed from the Warden's file (they're shared through the Roster):
-- BHeft, BSweepGather, BSweepBack, BSweepMid, BSweepEnd.
local M = {}
M.Kind = "Castellan"
M.Proportions = { girth = 1.35, arm = 1.1, hunch = -0.04 }
M.IdlePose = "CIdle"
-- the shield arm: low and forward, the hand just behind the shield's face (SHIELD's
-- positions are set so the arm stays behind it in every pose that uses them)
local GL = { la1 = 0.3, la2 = 0, la3 = 0.05, lel = 0.9 }
local OUT = { la1 = 0.25, la2 = 0, la3 = -0.45, lel = 0.5 } -- swung out with the shield, for balance
local function arm(p, a)
	for k, v in pairs(a or GL) do
		if p[k] == nil then
			p[k] = v
		end
	end
	p.freeL = 0
	return p
end
M.Poses = {
	-- standing guard: weight sunk onto the back leg, leaning off the mace's drag, breathing hard
	CIdle = arm({ drop = 0.32, lean = 0.1, twist = -0.18, side = -0.04, head = 0.05, footR = -0.4, footL = 0.5, spread = 0.2, breathe = 3.5 }),
	-- his vigil before the throne: kneeling, head bowed over the planted mace
	CVigil = arm({ drop = 1.45, lean = 0.3, head = 0.6, footR = 1.0, footL = -1.3, breathe = 2 }, OUT),
	-- halfway up: one knee still bent, pushing off the front foot
	CRise = arm({ drop = 0.85, lean = 0.4, head = 0.25, footR = 0.6, footL = -0.7, breathe = 4 }),
	-- chest out, the mace hoisted upright before his face
	CSalute = arm({ drop = 0.12, lean = -0.18, side = 0.05, head = -0.15, footR = 0.2, footL = -0.25, spread = 0.25, breathe = 3 }),
	-- first beat: the mace heaved up off the stone with a drive of the hips
	CHeave = arm({ drop = 0.8, lean = 0.55, twist = -0.6, side = 0.12, head = 0.2, footR = -0.55, footL = 0.65, spread = 0.26, breathe = 4 }, OUT),
	-- the full draw: reared right back on the rear foot, shield forward as counterweight
	CRear = arm({ drop = 0.38, lean = -0.55, twist = -0.15, side = -0.14, head = -0.3, footR = -0.75, footL = 0.7, spread = 0.16, breathe = 4 }),
	-- follow-through: the mace takes all of him down with it
	CSmash = arm({ drop = 1.05, lean = 0.95, twist = 0.4, side = 0.08, head = 0.35, footR = 1.05, footL = -0.95, spread = 0.22, breathe = 4 }, OUT),
	-- hauling it up out of the stone, stepping through onto the front foot
	CHaul = arm({ drop = 0.9, lean = 0.7, twist = 0.4, side = -0.08, head = 0.2, footR = -0.25, footL = 0.75, spread = 0.24, breathe = 5 }),
	-- sweeps: wound right round, then unwound all the way through
	CCoil = arm({ drop = 0.8, lean = 0.35, twist = -1.3, side = -0.14, head = -0.05, footR = -0.55, footL = 0.75, spread = 0.32, breathe = 4 }),
	CSweepThrough = arm({ drop = 0.75, lean = 0.45, twist = 1.35, side = 0.14, head = 0.05, footR = 0.85, footL = -0.55, spread = 0.35, breathe = 4 }, OUT),
	CSweepReturn = arm({ drop = 0.7, lean = 0.38, twist = -1.2, side = -0.12, footR = -0.5, footL = 0.8, spread = 0.35, breathe = 4 }),
	-- ...and the mace's weight carries on past where he meant to stop
	CStumble = arm({ drop = 0.65, lean = 0.5, twist = 1.5, side = 0.22, head = 0.1, footR = 1.0, footL = -0.3, spread = 0.4, breathe = 5 }, OUT),
	-- shield work: drawn back with the chest turned away, then shoved through on a long step
	CBashSet = arm({ drop = 0.55, lean = 0.1, twist = 0.55, side = -0.06, head = 0.05, footR = 0.5, footL = -0.45, spread = 0.18, la1 = -0.2, lel = 1.3 }),
	CBash = arm({ drop = 0.7, lean = 0.6, twist = -0.65, side = 0.06, head = 0.1, footR = -0.6, footL = 1.0, spread = 0.22, la1 = 1.2, lel = 0.3 }),
	-- the rush: shoulder low behind the shield, then driving forward
	CBrace = arm({ drop = 0.8, lean = 0.6, twist = -0.45, head = -0.15, footR = -0.65, footL = 0.7, spread = 0.18, la1 = 0.9, lel = 0.9 }),
	CRush = arm({ drop = 0.85, lean = 0.7, twist = -0.5, head = -0.2, footR = 1.0, footL = -1.0, la1 = 0.9, lel = 0.9 }),
	-- the oath: straining to hold the mace straight up, then kneeling into the blow
	COath = arm({ drop = 0.25, lean = -0.6, side = 0.05, head = -0.55, footR = -0.35, footL = 0.4, spread = 0.35, breathe = 5 }, OUT),
	CQuake = arm({ drop = 1.35, lean = 0.85, head = 0.35, footR = 0.9, footL = -1.2, spread = 0.18 }, OUT),
}
M.Colors = { skin = Color3.fromRGB(150, 124, 104), torso = Color3.fromRGB(78, 76, 74), legs = Color3.fromRGB(70, 68, 66), arms = Color3.fromRGB(78, 76, 74) }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT, D, s = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT, k.D, k.s
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	-- kept polished: bright steel, gilt edges, the keep's red
	local steel, steelDk, gold, red, mail, fur = rgb(150, 148, 142), rgb(96, 94, 90), rgb(176, 140, 66), rgb(110, 26, 24), rgb(84, 82, 80), rgb(86, 72, 58)
	local shin, th = D.shin / s, D.thigh / s
	for _, pn in ipairs({ "RUpperArm", "LUpperArm", "RLowerArm", "LLowerArm", "RThigh", "LThigh", "RShin", "LShin", "Chest", "Hips" }) do
		parts[pn].Color = mail
		parts[pn].Material = MAT.CorrodedMetal
	end
	-- cuirass under a red tabard with a gold cross, a fur mantle, a long red cloak
	deco("Chest", "Breastplate", V(cw * 1.0, ch * 0.8, 0.32), at(0, 0.1, -cd / 2 - 0.1), steel, MAT.Metal)
	deco("Chest", "Tabard", V(cw * 0.72, ch * 0.74, 0.06), at(0, 0, -cd / 2 - 0.29), red, MAT.Fabric)
	deco("Chest", "TabardCross", V(0.22, ch * 0.55, 0.04), at(0, 0.02, -cd / 2 - 0.33), gold, MAT.Fabric)
	deco("Chest", "TabardCross", V(cw * 0.42, 0.2, 0.04), at(0, 0.22, -cd / 2 - 0.33), gold, MAT.Fabric)
	deco("Chest", "Backplate", V(cw * 0.98, ch * 0.8, 0.24), at(0, 0.1, cd / 2 + 0.08), steelDk, MAT.Metal)
	deco("Chest", "Gorget", V(cw * 0.64, 0.38, cd * 1.15), at(0, ch / 2 - 0.02, 0), steel, MAT.Metal)
	deco("Chest", "GorgetTrim", V(cw * 0.68, 0.1, cd * 1.2), at(0, ch / 2 - 0.22, 0), gold, MAT.Metal)
	deco("Chest", "Mantle", V(cw * 1.15, 0.42, cd * 1.35), at(0, ch / 2 - 0.05, 0.05), fur, MAT.Fabric)
	deco("Chest", "Cloak", V(cw * 1.05, 3.5, 0.14), at(0, -0.95, cd / 2 + 0.26), red, MAT.Fabric)
	deco("Chest", "CloakHem", V(cw * 1.06, 0.18, 0.15), at(0, -2.62, cd / 2 + 0.26), gold, MAT.Fabric)
	-- belt, faulds, and the tabard's skirt front and back
	deco("Hips", "Belt", V(hw + 0.18, 0.26, hd + 0.18), at(0, 0.3, 0), rgb(56, 40, 28), MAT.Fabric)
	deco("Hips", "Buckle", V(0.36, 0.28, 0.06), at(0, 0.3, -hd / 2 - 0.11), gold, MAT.Metal)
	deco("Hips", "Fauld", V(hw + 0.24, 0.3, hd + 0.24), at(0, 0.05, 0), steel, MAT.Metal)
	for _, z in ipairs({ -1, 1 }) do
		deco("Hips", "TabardSkirt", V(hw * 0.78, 1.6, 0.08), at(0, -0.85, z * (hd / 2 + 0.14)), red, MAT.Fabric)
		deco("Hips", "TabardHem", V(hw * 0.8, 0.14, 0.09), at(0, -1.62, z * (hd / 2 + 0.14)), gold, MAT.Fabric)
	end
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		-- great domed pauldrons edged in gold
		deco(n .. "UpperArm", "Pauldron", V(aw * 2.15, 0.7, aw * 2.0), at(sx * 0.08, ua / 2 - 0.1, 0), steel, MAT.Metal)
		deco(n .. "UpperArm", "PauldronTrim", V(aw * 2.2, 0.1, aw * 2.05), at(sx * 0.08, ua / 2 - 0.47, 0), gold, MAT.Metal)
		deco(n .. "UpperArm", "PauldronLame", V(aw * 1.85, 0.22, aw * 1.7), at(sx * 0.08, ua / 2 - 0.62, 0), steelDk, MAT.Metal)
		deco(n .. "UpperArm", "Rerebrace", V(aw * 1.2, ua * 0.45, aw * 1.2), at(0, -ua * 0.15, 0), steel, MAT.Metal)
		deco(n .. "LowerArm", "Couter", V(aw * 1.4, 0.42, aw * 1.4), at(0, la / 2 - 0.12, 0), steel, MAT.Metal)
		deco(n .. "LowerArm", "Vambrace", V(aw * 1.18, la * 0.55, aw * 1.18), at(0, 0, 0), steel, MAT.Metal)
		deco(n .. "LowerArm", "Gauntlet", V(aw * 1.3, 0.48, aw * 1.3), at(0, -la / 2 + 0.2, 0), steelDk, MAT.Metal)
		deco(n .. "Thigh", "Cuisse", V(lw * 1.18, th * 0.72, lw * 1.18), at(0, 0.05, 0), steel, MAT.Metal)
		deco(n .. "Shin", "Poleyn", V(lw * 1.28, 0.44, lw * 1.28), at(0, shin / 2 - 0.08, -0.04), gold, MAT.Metal)
		deco(n .. "Shin", "Greave", V(lw * 1.15, shin * 0.62, lw * 1.15), at(0, -shin * 0.1, 0), steel, MAT.Metal)
		deco(n .. "Foot", "Sabaton", V(D.footSize.X / s * 1.1, 0.26, D.footSize.Z / s * 0.92), at(0, 0.06, -0.05), steelDk, MAT.Metal)
	end
	-- crowned great helm with a red crest
	deco("Head", "Helm", V(1.32, 1.42, 1.32), at(0, 0.04, 0), steel, MAT.Metal)
	deco("Head", "Visor", V(0.98, 0.1, 0.06), at(0, 0.12, -0.68), rgb(8, 8, 8), MAT.SmoothPlastic)
	deco("Head", "Breaths", V(0.5, 0.36, 0.05), at(0, -0.3, -0.675), rgb(20, 20, 20), MAT.Metal)
	deco("Head", "Crown", V(1.4, 0.2, 1.4), at(0, 0.62, 0), gold, MAT.Metal)
	for i = 0, 3 do
		deco("Head", "CrownPoint", V(0.22, 0.4, 0.22), at(0, 0.84, 0) * CFrame.Angles(0, i * math.pi / 2 + math.pi / 4, 0) * CFrame.new(0, 0, 0.62 * s), gold, MAT.Metal)
	end
	deco("Head", "Crest", V(0.22, 0.6, 1.5), at(0, 1.0, 0.1), red, MAT.Fabric)
end

M.Weapons = {
	-- a great flanged mace, far too heavy to swing one-handed: a steel haft wrapped in red
	-- leather, a gilt pommel, eight flanges between gilt bands (Z: all of it, 1.5x a knight's)
	CastellanMace = function(w)
		local mk, add, s = w.mk, w.add, w.scale
		local Z = 1.5
		local steel, steelDk, gold = Color3.fromRGB(150, 148, 142), Color3.fromRGB(80, 78, 74), Color3.fromRGB(176, 140, 66)
		local handle = mk("Haft", Vector3.new(0.34, 3.0, 0.34) * Z, steelDk, Enum.Material.Metal)
		for i = 0, 3 do
			add(mk("Wrap", Vector3.new(0.4, 0.18, 0.4) * Z, Color3.fromRGB(110, 26, 24), Enum.Material.Fabric), (0.55 + i * 0.24) * Z, CFrame.Angles(0, i * 0.5, 0))
		end
		add(mk("Pommel", Vector3.new(0.52, 0.34, 0.52) * Z, gold, Enum.Material.Metal), 1.6 * Z)
		add(mk("Collar", Vector3.new(0.56, 0.22, 0.56) * Z, gold, Enum.Material.Metal), -0.85 * Z)
		add(mk("Head", Vector3.new(0.8, 1.3, 0.8) * Z, steelDk, Enum.Material.Metal), -1.6 * Z)
		for f = 0, 7 do
			add(mk("Flange", Vector3.new(0.12, 1.15, 0.55) * Z, steel, Enum.Material.Metal), -1.6 * Z, CFrame.Angles(0, f * math.pi / 4, 0) * CFrame.new(0, 0, 0.5 * Z * s))
		end
		for _, y in ipairs({ -0.98, -2.22 }) do
			add(mk("HeadBand", Vector3.new(0.98, 0.14, 0.98) * Z, gold, Enum.Material.Metal), y * Z)
		end
		add(mk("Finial", Vector3.new(0.4, 0.4, 0.4) * Z, gold, Enum.Material.Metal), -2.45 * Z)
		-- held a hand's breadth under the pommel; the head hangs at the far end
		return { handle = handle, bladeLen = 2.45 * Z - 0.6, gripC1 = CFrame.new(0, 0.9 * Z * s, 0) }
	end,
}
local R = math.rad
M.Grips = {
	-- leaning forward, its head down on the stone in front of him (his vigil)
	CPlant = { Vector3.new(0.5, 0.1, -1.2), CFrame.Angles(R(52), 0, 0) },
	-- held upright before his face
	CSalute = { Vector3.new(0.45, 1.0, -1.3), CFrame.Angles(R(180), 0, 0) },
	-- straight up overhead (the oath)
	CHigh = { Vector3.new(0.5, 3.3, -0.2), CFrame.Angles(R(195), 0, 0) },
	-- (in a player's hands) at rest, dragged behind: hand low at the right hip, head on the stone
	MDrag = { Vector3.new(1.1, -0.5, 0.3), CFrame.Angles(R(-63), 0, 0) },
	-- phase 2 sweeps: the B ones held dead level (90 deg, not 66), at a player's chest, and wound wider
	CSweepBack = { Vector3.new(2.1, -1.3, 1.7), CFrame.Angles(0, R(-65), 0) * CFrame.Angles(0, 0, R(90)) },
	CSweepMid = { Vector3.new(0, -1.3, -2.6), CFrame.Angles(0, R(90), 0) * CFrame.Angles(0, 0, R(90)) },
	CSweepEnd = { Vector3.new(-2.2, -1.3, 0.3), CFrame.Angles(0, R(225), 0) * CFrame.Angles(0, 0, R(90)) },
}

---------------------------------------------------------------------------
-- server: the fight
---------------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local C = Config.Castellan
local S = C.Scale
local Core, Map, FxRemote, states, now, flat, rand, turnTowards, SOUNDS, playSound, burst, dustCloud, crackLines, fadeAway, shockwave, groundHeave, debrisChunks, pose, bodyPose, setTrail, aliveChar, damagePlayer, playersInRadius, playersInSector

local boss: any = { state = "none", gen = 0, phase2 = false, seen = false } -- state: none | dormant | intro | fight | dead
local EASE, INOUT, LINEAR = Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, Enum.EasingStyle.Linear

local function dmg(x)
	return math.max(1, math.floor(x * (C.DamageScale or 1) + 0.5))
end

-- the battlements (the turret over the stair stands in the middle of them)
local function inTurret(pos)
	return pos.X > -17 and pos.X < 17 and pos.Z > 207 and pos.Z < 239
end
local function onRoof(pos)
	local y = Map.CastellanArena.Center.Y
	return pos.Y > y - 3 and pos.X > -55 and pos.X < 46 and pos.Z > 201 and pos.Z < 275
end
local function inBounds(pos) -- where he may be carried (rush)
	return pos.X > -52 and pos.X < 42 and pos.Z > 205 and pos.Z < 271 and not (pos.X > -21 and pos.X < 21 and pos.Z > 203 and pos.Z < 243)
end

local function live(b)
	return boss.gen == b.gen and boss.state == "fight" and b.hum.Parent ~= nil and b.hum.Health > 0
end
local function free(b)
	return live(b) and now() >= (boss.staggerUntil or 0)
end
local function waitLive(b, d)
	local t0 = now()
	while now() - t0 < d do
		if not live(b) then
			return false
		end
		task.wait()
	end
	return true
end
local function tempo()
	return boss.phase2 and 0.88 or 1
end
local function turnRate()
	return math.rad(boss.phase2 and 110 or 80)
end
local function walkSpeed()
	return boss.phase2 and 9 or 7
end
local function feet(b)
	return b.root.Position.Y - 3 * S
end

---------------------------------------------------------------------------
-- SHIELD: a tall rectangular shield up to his chest, hung off his root on a Weld (so it
-- stays upright with its foot just off the stone however low he sinks). Its poses are
-- root-relative offsets at scale 1, tweened alongside his body; each sits far enough out
-- that the arm reaching for it stays behind its face.
---------------------------------------------------------------------------
local SHIELD = {
	Guard = CFrame.new(-1.45, -0.95, -2.2) * CFrame.Angles(0, R(8), 0),
	Out = CFrame.new(-2.8, -0.95, -2.0) * CFrame.Angles(0, R(30), 0), -- swung out to balance a swing
	Set = CFrame.new(-1.9, -0.95, -1.2) * CFrame.Angles(0, R(25), 0), -- drawn back to bash
	Bash = CFrame.new(-0.3, -0.85, -3.4) * CFrame.Angles(R(-6), R(-5), 0),
	Brace = CFrame.new(-0.4, -0.95, -3.0),
	Vigil = CFrame.new(-2.8, -0.95, -1.2) * CFrame.Angles(0, R(55), 0), -- stood beside him
}
local function shieldTo(b, name, t)
	local w = b.shieldWeld
	if w and w.Parent then
		local cf = SHIELD[name]
		TweenService:Create(w, TweenInfo.new(math.max(t, 0.01), EASE, INOUT), { C0 = CFrame.new(cf.Position * S) * cf.Rotation }):Play()
	end
end
local function buildShield(model, root)
	local red, gold = Color3.fromRGB(110, 26, 24), Color3.fromRGB(176, 140, 66)
	local function piece(name, size, rel, color, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size * S
		p.Color = color
		p.Material = Enum.Material.Metal
		p.CanCollide, p.CanTouch, p.Massless = false, false, true
		if shape then
			p.Shape = shape
		end
		p:SetAttribute("Rel", rel) -- (placed once the main plate is)
		return p
	end
	-- the face: a tall plain rectangle, rimmed all round, a gold cross and boss on it
	local main = piece("Shield", Vector3.new(2.4, 3.6, 0.25), CFrame.new(), red)
	local list = {
		piece("ShieldRim", Vector3.new(2.55, 0.18, 0.34), CFrame.new(0, 1.8, 0), gold),
		piece("ShieldRim", Vector3.new(2.55, 0.18, 0.34), CFrame.new(0, -1.8, 0), gold),
		piece("ShieldRim", Vector3.new(0.18, 3.6, 0.34), CFrame.new(-1.2, 0, 0), gold),
		piece("ShieldRim", Vector3.new(0.18, 3.6, 0.34), CFrame.new(1.2, 0, 0), gold),
		piece("ShieldCross", Vector3.new(0.28, 3.2, 0.06), CFrame.new(0, 0, -0.16), gold),
		piece("ShieldCross", Vector3.new(2.0, 0.28, 0.06), CFrame.new(0, 0.5, -0.16), gold),
		piece("ShieldBoss", Vector3.new(0.6, 0.6, 0.6), CFrame.new(0, 0.5, -0.2), gold, Enum.PartType.Ball),
	}
	local cf = SHIELD.Vigil
	main.CFrame = root.CFrame * CFrame.new(cf.Position * S) * cf.Rotation
	for _, p in ipairs(list) do
		local rel = p:GetAttribute("Rel")
		p.CFrame = main.CFrame * CFrame.new(rel.Position * S) * rel.Rotation
		local wc = Instance.new("WeldConstraint")
		wc.Part0, wc.Part1 = main, p
		wc.Parent = p
		p.Parent = model
	end
	local w = Instance.new("Weld")
	w.Name = "ShieldWeld"
	w.Part0, w.Part1 = root, main
	w.C0 = CFrame.new(cf.Position * S) * cf.Rotation
	w.Parent = main
	main.Parent = model
	return main, w
end

-- wind up, turning toward the target for the first trackFrac of it
local function windupTrack(b, duration, trackFrac, target, turnMul)
	local t0 = now()
	while now() - t0 < duration do
		if not free(b) then
			return false
		end
		local tr = target and target:FindFirstChild("HumanoidRootPart")
		local dt = task.wait()
		if tr and now() - t0 < duration * trackFrac then
			turnTowards(b.root, tr.Position, turnRate() * dt * (turnMul or 1.4))
		end
	end
	return true
end
-- grip, body and shield move together (shield optional)
local function draw(b, grip, body, t, shield)
	pose(b, grip, t, EASE, INOUT)
	if body then
		bodyPose(b, body, t)
	end
	if shield then
		shieldTo(b, shield, t)
	end
end
-- two beats: gather the weight, then the full draw ({ grip, body, seconds, shield? } each)
local function windup2(b, target, gather, full, track)
	draw(b, gather[1], gather[2], gather[3], gather[4])
	if not windupTrack(b, gather[3], math.min(track / gather[3], 1), target) then
		return false
	end
	draw(b, full[1], full[2], full[3], full[4])
	return windupTrack(b, full[3], math.max(track - gather[3], 0) / full[3], target)
end

local function hitOnce(list, seen, amount, fromPos, level)
	for _, pl in ipairs(list) do
		if not seen[pl] and damagePlayer(pl, dmg(amount), fromPos, level) then
			seen[pl] = true
		end
	end
end

-- the mace's real path hurts: sampled every frame between last frame's and this frame's
local maceParams = OverlapParams.new()
maceParams.FilterType = Enum.RaycastFilterType.Include
maceParams.CollisionGroup = "HitQuery"
local function maceEnds(b)
	local handle = b.weld and b.weld.Parent and b.weld.Part1
	local base, tip = handle and handle:FindFirstChild("BladeBase"), handle and handle:FindFirstChild("BladeTip")
	if base and tip then
		return base.WorldPosition, tip.WorldPosition
	end
end
local function maceSweep(b, duration, amount, level, seen, radius)
	local chars = {}
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl.Character then
			table.insert(chars, pl.Character)
		end
	end
	maceParams.FilterDescendantsInstances = chars
	local t0, pb, pt = now(), nil, nil
	while now() - t0 < duration and live(b) do
		local base, tip = maceEnds(b)
		if base then
			pb, pt = pb or base, pt or tip
			for i = 0, 3 do
				local bb, tt = pb:Lerp(base, i / 3), pt:Lerp(tip, i / 3)
				for j = 0, 5 do
					for _, part in ipairs(workspace:GetPartBoundsInRadius(bb:Lerp(tt, j / 5), radius, maceParams)) do
						local pl = Players:GetPlayerFromCharacter(part:FindFirstAncestorOfClass("Model"))
						if pl and not seen[pl] and damagePlayer(pl, dmg(amount), b.root.Position, level) then
							seen[pl] = true
						end
					end
				end
			end
			pb, pt = base, tip
		end
		RunService.Heartbeat:Wait()
	end
end

local function footDust(b, side, amount)
	dustCloud(b.root.CFrame * Vector3.new(side * 0.8 * S, -3 * S + 0.4, 0.5 * S), 1.6, amount or 6)
end
local function tell(b, pitch)
	playSound(b.root, SOUNDS.Unsheath, 0.8, pitch or 0.4) -- plate grinding as he sets himself
	footDust(b, -1, 3)
end
-- a heavy step into the blow: a burst of his own walk, the foot coming down hard
local function stepInto(b, dist, dur)
	local hum, root = b.hum, b.root
	local fwd = flat(root.CFrame.LookVector)
	if root.Anchored or fwd.Magnitude < 0.1 then
		return
	end
	hum.WalkSpeed = dist / dur
	hum:MoveTo(root.Position + fwd.Unit * dist)
	task.delay(dur, function()
		if boss.gen == b.gen and hum.Parent then
			hum.WalkSpeed = walkSpeed()
			hum:MoveTo(root.Position)
			footDust(b, 1, 5)
			playSound(root, SOUNDS.Impact, 0.35, 0.35)
			FxRemote:FireAllClients("Shake", root.Position, 0.25)
		end
	end)
end
local function stopAndFace(b)
	b.hum:MoveTo(b.root.Position)
	b.hum.AutoRotate = false
end
local function clang(b, loud)
	local sh = b.shield
	if sh and sh.Parent then
		playSound(sh, SOUNDS.Deflect, loud and 1 or 0.7, 0.55 + math.random() * 0.1)
		burst(sh.Position, Color3.fromRGB(255, 220, 150), 10, 0.25, 18)
	end
end
local function idle(b)
	setTrail(b, false)
	pose(b, "Idle", 0.9, EASE, INOUT)
	shieldTo(b, "Guard", 0.9)
end
local function recover(b, t)
	bodyPose(b, "Recover", 0.6) -- spent, bent over the mace, heaving: the window to punish him
	if waitLive(b, t) then
		idle(b)
	end
end

---------------------------------------------------------------------------
-- the beats his strings are built from
---------------------------------------------------------------------------
-- one overhead blow: the mace heaved up with his hips, reared back, a beat where its
-- weight hangs at the top, then a step in and down through all of him.
-- big = the last of a string: a wider blast that knocks you down. false if interrupted.
local function overhead(b, target, gatherT, fullT, track, amount, step, big)
	if not windup2(b, target, { "BHeft", "CHeave", gatherT, "Out" }, { "Raise", "CRear", fullT, "Guard" }, track) then
		return false
	end
	playSound(b.root, SOUNDS.Unsheath, 0.5, 0.3) -- the haft creaks at the top
	if not windupTrack(b, 0.14, 0, nil) then
		return false
	end
	setTrail(b, true)
	stepInto(b, step, 0.34)
	pose(b, "Mid", 0.09, LINEAR)
	task.delay(0.09, function()
		pose(b, "Strike", 0.11)
		bodyPose(b, "CSmash", 0.18)
		shieldTo(b, "Out", 0.25)
	end)
	playSound(b.root, SOUNDS.Lunge, 0.9, 0.45)
	local seen = {}
	task.spawn(maceSweep, b, 0.26, amount, "Knockdown", seen, 2.2)
	task.wait(0.19)
	if not live(b) then
		return false
	end
	local _, tip = maceEnds(b)
	local at = tip or (b.root.Position + flat(b.root.CFrame.LookVector).Unit * 5 * S)
	at = Vector3.new(at.X, feet(b) + 0.2, at.Z)
	local radius = (big and 11 or 8) + (boss.phase2 and 2 or 0)
	shockwave(at, radius)
	dustCloud(at, 2.4, big and 14 or 8)
	if big then
		debrisChunks(at + Vector3.new(0, 1, 0), 8, 22)
	end
	playSound(b.root, SOUNDS.Impact, 1, big and 0.4 or 0.55)
	FxRemote:FireAllClients("Shake", at, big and 1.4 or 1)
	hitOnce(playersInRadius(at, radius * 0.7, 10), seen, amount * 0.7, at, big and "Knockdown" or "Large")
	setTrail(b, false)
	return true
end

-- the mace stuck in the stone: he leans on it and drags it back up, stepping through
local function haul(b, target, t)
	draw(b, "BSweepGather", "CHaul", t * 0.6, "Guard")
	playSound(b.root, SOUNDS.Unsheath, 0.6, 0.32)
	return windupTrack(b, t, 1, target)
end

-- the shield: drawn back, then shoved through on a long step
local function shieldBash(b, target, windT, step)
	draw(b, "BSweepGather", "CBashSet", windT, "Set")
	if not windupTrack(b, windT, 0.8, target) then
		return false
	end
	stepInto(b, step, 0.26)
	bodyPose(b, "CBash", 0.16)
	shieldTo(b, "Bash", 0.16)
	playSound(b.root, SOUNDS.Lunge, 0.8, 0.4)
	task.wait(0.15)
	if not live(b) then
		return false
	end
	clang(b, true)
	FxRemote:FireAllClients("Shake", b.root.Position, 0.6)
	hitOnce(playersInSector(b.root.CFrame, 3.8 * S, 55, 12), {}, 26, b.root.Position, "Large")
	shieldTo(b, "Guard", 0.6)
	return true
end

-- a wide sweep at hip height (back = the backhand, unwinding the other way); the mace's
-- weight carries him on past the end of it. Phase 2: level, wider and heavier (C grips).
local function sweep(b, back, amount)
	local p2 = boss.phase2
	local half = p2 and 0.32 or 0.24
	setTrail(b, true)
	stepInto(b, back and 4 or 5, 0.45)
	pose(b, p2 and "CSweepMid" or "BSweepMid", half, LINEAR)
	bodyPose(b, back and "CSweepReturn" or "CSweepThrough", half * 2)
	shieldTo(b, back and "Guard" or "Out", half * 2)
	task.delay(half, function()
		if back then
			pose(b, p2 and "CSweepBack" or "BSweepBack", half + 0.02)
		else
			pose(b, p2 and "CSweepEnd" or "BSweepEnd", half + 0.02)
		end
	end)
	playSound(b.root, SOUNDS.Slash, 1, 0.38)
	maceSweep(b, half * 2 + 0.02, amount, "Large", {}, p2 and 2.6 or 2.4)
	setTrail(b, false)
	FxRemote:FireAllClients("Shake", b.root.Position, 0.35)
	if not back and live(b) then
		bodyPose(b, "CStumble", 0.3)
		footDust(b, 1, 5)
	end
end

-- phase 2, before a sweep: he holds the coil a beat, the mace's head glinting gold
-- (true at once in phase 1; false if interrupted)
local function sweepTell(b, target, t)
	if not boss.phase2 then
		return true
	end
	local _, tip = maceEnds(b)
	if tip then
		burst(tip, Color3.fromRGB(255, 200, 110), 14, 0.35, 8)
	end
	playSound(b.root, SOUNDS.Unsheath, 0.9, 0.34)
	return windupTrack(b, t, 0.5, target)
end

---------------------------------------------------------------------------
-- his strings
---------------------------------------------------------------------------
-- Judgement: overhead, haul it out of the stone, overhead again... In phase 2 he won't
-- stop: five smashes, each hauled up slower than the last, the fifth the biggest, and
-- the shield driven in behind it. (Phase 1: two, and half the time the shield.)
local function judgement(b, target)
	-- phase 2: the whole string 10% quicker, and every smash hits 15% harder
	local m = tempo() * (boss.phase2 and 0.9 or 1)
	local hurt = boss.phase2 and 1.15 or 1
	local hits = boss.phase2 and 5 or 2
	stopAndFace(b)
	tell(b)
	if not overhead(b, target, 0.65 * m, 1.2 * m, 1.4 * m, 40 * hurt, 5, hits == 1) then
		return
	end
	for i = 2, hits do
		if not haul(b, target, (0.55 + i * 0.05) * m) then
			return
		end
		if not overhead(b, target, 0.35 * m, 0.8 * m, 0.9 * m, 42 * hurt, 5, i == hits) then
			return
		end
	end
	if (boss.phase2 or math.random() < 0.5) and not shieldBash(b, target, 0.6 * m, 4) then
		return
	end
	recover(b, (boss.phase2 and 2.2 or 1.6) * m)
end

-- Reaping Arc: a long coil and a sweep that drags him round, the backhand, then (phase
-- 2, or most of the time) he heaves it up for an overhead to finish
local function reap(b, target)
	local m = tempo()
	stopAndFace(b)
	tell(b, 0.36)
	local coil = boss.phase2 and "CSweepBack" or "BSweepBack"
	if not windup2(b, target, { "BSweepGather", "CHeave", 0.6 * m, "Out" }, { coil, "CCoil", 1.1 * m, "Guard" }, 1.3 * m) then
		return
	end
	if not sweepTell(b, target, 0.45) then
		return
	end
	sweep(b, false, 34)
	if not live(b) then
		return
	end
	-- plants, lets the weight swing him, drags the mace back round
	if not windupTrack(b, 0.75 * m, 0.7, target) or not sweepTell(b, target, 0.35) then
		return
	end
	sweep(b, true, 30)
	if (boss.phase2 or math.random() < 0.65) and not overhead(b, target, 0.45 * m, 0.9 * m, 1.0 * m, 44, 4, true) then
		return
	end
	recover(b, 1.7 * m)
end

-- Shield Bash into a slam: the shove, then the mace heaved all the way up and held
-- (a different beat every time) before it falls
local function bashSmash(b, target)
	local m = tempo()
	stopAndFace(b)
	tell(b, 0.45)
	if not shieldBash(b, target, 0.85 * m, 3) then
		return
	end
	if not overhead(b, target, 0.45 * m, (1.0 + rand(0, 0.5)) * m, 1.0 * m, 40, 4, true) then
		return
	end
	recover(b, 1.4 * m)
end

-- Shield Rush: braces low behind the shield, scrapes a foot, and drives across the
-- battlements; then the mace comes down on whoever he ran over. A wall stops him dead.
local function rush(b, target)
	local tr = target:FindFirstChild("HumanoidRootPart")
	if not tr then
		return
	end
	local m = tempo()
	stopAndFace(b)
	tell(b, 0.32)
	for _, d in ipairs({ 0.5, 1.0 }) do
		task.delay(d * m, function()
			if live(b) then
				footDust(b, 1, 6)
				playSound(b.root, SOUNDS.Impact, 0.4, 0.35)
			end
		end)
	end
	if not windup2(b, target, { "BSweepGather", "CHeave", 0.5 * m, "Guard" }, { "BSweepGather", "CBrace", 1.0 * m, "Brace" }, 1.25 * m) then
		return
	end
	bodyPose(b, "CRush", 0.2)
	local root = b.root
	local dir = flat(root.CFrame.LookVector).Unit
	local dist = math.clamp(flat(tr.Position - root.Position).Magnitude + 6, 10, 36)
	-- he runs straight through braziers and statues: only the arena's edge stops him
	local hitWall = false
	while dist > 0 and not inBounds(root.Position + dir * dist) do
		dist -= 1
		hitWall = true
	end
	root.Anchored = true
	local start, rot, seen = root.Position, root.CFrame.Rotation, {}
	local dur = math.max(dist / 26, 0.2)
	local t0, nextStep = now(), 0
	while live(b) do
		local a = math.min((now() - t0) / dur, 1)
		local pos = start + dir * dist * (a * 0.5 + (1 - math.cos(a * math.pi)) / 4)
		root.CFrame = CFrame.new(pos) * rot
		hitOnce(playersInRadius(pos + dir * 2.5, 6, 12), seen, 30, pos - dir * 3, "Large")
		if now() > nextStep then -- every footfall shakes the stone
			nextStep = now() + 0.22
			dustCloud(Vector3.new(pos.X, feet(b) + 0.6, pos.Z), 1.4, 4)
			playSound(root, SOUNDS.Impact, 0.4, 0.4)
			FxRemote:FireAllClients("Shake", pos, 0.3)
		end
		if a >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end
	if not live(b) then
		return
	end
	root.Anchored = false
	root.AssemblyLinearVelocity = Vector3.zero
	pcall(function()
		root:SetNetworkOwner(nil)
		b.hum:ChangeState(Enum.HumanoidStateType.Running)
	end)
	if hitWall then
		-- shield-first into the stone: rattled, wide open
		clang(b, true)
		shockwave(Vector3.new(root.Position.X, feet(b) + 0.2, root.Position.Z) + dir * 4, 6)
		playSound(root, SOUNDS.Impact, 1, 0.4)
		FxRemote:FireAllClients("Shake", root.Position, 1.1)
		boss.staggerUntil = now() + 2
		pose(b, "Flinch", 0.15)
		bodyPose(b, "Stagger", 0.15)
		shieldTo(b, "Out", 0.3)
		task.delay(2, function()
			if live(b) then
				idle(b)
			end
		end)
		return
	end
	if not overhead(b, target, 0.35 * m, 0.7 * m, 0.8 * m, 40, 3) then
		return
	end
	recover(b, 1.5 * m)
end

-- The Oath: he strains to hold the mace straight up while the stone cracks out to the
-- blast's edge, then kneels into one enormous blow. Aftershocks roll outward in rings
-- (two in phase 2): run, then roll the ring as it reaches you.
local function oath(b, target)
	local m = tempo()
	stopAndFace(b)
	tell(b, 0.3)
	draw(b, "BHeft", "CHeave", 0.6 * m, "Out")
	if not windupTrack(b, 0.6 * m, 1, target) then
		return
	end
	draw(b, "CHigh", "COath", 1.0 * m)
	playSound(b.root, SOUNDS.Unsheath, 1, 0.28)
	local center = b.root.Position + flat(b.root.CFrame.LookVector).Unit * 1.5 * S
	center = Vector3.new(center.X, feet(b) + 0.2, center.Z)
	local WIND, RADIUS = 2.0 * m, 13
	local cracks = crackLines(center + Vector3.new(0, 0.04, 0), RADIUS, 10, Color3.fromRGB(24, 22, 20), Enum.Material.Slate, WIND * 0.7)
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		groundHeave(center + Vector3.new(math.cos(a), 0, math.sin(a)) * RADIUS * 0.92, 2.4, WIND)
	end
	local ok = windupTrack(b, WIND, 0.3, target)
	fadeAway(cracks, 3, 1.5)
	if not ok then
		return
	end
	setTrail(b, true)
	pose(b, "Strike", 0.14)
	bodyPose(b, "CQuake", 0.18)
	task.wait(0.16)
	if not live(b) then
		return
	end
	shockwave(center, RADIUS)
	debrisChunks(center + Vector3.new(0, 1, 0), 10, 28)
	playSound(b.root, SOUNDS.Impact, 1, 0.35)
	FxRemote:FireAllClients("Shake", center, 1.5)
	hitOnce(playersInRadius(center, RADIUS, 12), {}, 46, center, "Knockdown")
	setTrail(b, false)
	for i = 1, boss.phase2 and 2 or 1 do
		if not waitLive(b, 0.55) then
			return
		end
		local outer = RADIUS + i * 7
		shockwave(center, outer)
		dustCloud(center, outer * 0.4, 10)
		playSound(b.root, SOUNDS.Impact, 0.8, 0.3)
		FxRemote:FireAllClients("Shake", center, 0.8)
		local ring = {}
		for _, pl in ipairs(playersInRadius(center, outer, 10)) do
			local _, _, hrp = aliveChar(pl)
			if hrp and flat(hrp.Position - center).Magnitude > outer - 7 then
				table.insert(ring, pl)
			end
		end
		hitOnce(ring, {}, 28, center, "Large")
	end
	recover(b, 2.2 * m)
end

-- you got behind him: he turns on his heel with the mace wound round, and sweeps
local function pivot(b, target)
	local m = tempo()
	stopAndFace(b)
	tell(b, 0.5)
	draw(b, boss.phase2 and "CSweepBack" or "BSweepBack", "CCoil", 0.7 * m, "Guard")
	if not windupTrack(b, 0.75 * m, 1, target, 2.5) or not sweepTell(b, target, 0.4) then
		return
	end
	sweep(b, false, 32)
	recover(b, 1.3 * m)
end

local function phase2(b)
	boss.phase2 = true
	boss.p2Count, boss.p2Judged = 0, false -- (his five-smash Judgement is forced by his 2nd attack)
	ReplicatedStorage:SetAttribute("BossName", C.Name2)
	ReplicatedStorage:SetAttribute("Music", C.Music ~= "" and "castellan2" or "boss2") -- (no Music2: phase 1's piece plays on)
	stopAndFace(b)
	draw(b, "CHigh", "COath", 0.8, "Out")
	playSound(b.root, SOUNDS.Unsheath, 1, 0.3)
	FxRemote:FireAllClients("Shake", b.root.Position, 0.9)
	-- the oath burns: the gilt on his shield and mace takes light
	for _, d in ipairs(b.model:GetDescendants()) do
		if d:IsA("BasePart") and (d.Name == "ShieldCross" or d.Name == "ShieldRim" or d.Name == "ShieldBoss" or d.Name == "HeadBand" or d.Name == "Crown") then
			d.Material = Enum.Material.Neon
			d.Color = Color3.fromRGB(255, 196, 96)
		elseif d:IsA("Trail") then
			d.Color = ColorSequence.new(Color3.fromRGB(255, 200, 110))
		end
	end
	if b.shield then
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(255, 190, 100)
		l.Range = 18
		l.Brightness = 1.6
		l.Parent = b.shield
	end
	b.hum.WalkSpeed = walkSpeed()
	if not waitLive(b, 0.9) then
		return
	end
	-- he brings it down once, to clear the ground around him
	pose(b, "Strike", 0.12)
	bodyPose(b, "CQuake", 0.16)
	task.wait(0.14)
	local center = Vector3.new(b.root.Position.X, feet(b) + 0.2, b.root.Position.Z)
	shockwave(center, 11)
	playSound(b.root, SOUNDS.Impact, 1, 0.4)
	hitOnce(playersInRadius(center, 10, 12), {}, 18, center, "Large")
	recover(b, 1.6)
end

---------------------------------------------------------------------------
-- brain
---------------------------------------------------------------------------
-- min/max = distance band (studs). behind = an answer to you being behind him.
-- fast = used to punish you drinking a flask.
local MOVES = {
	{ name = "Judgement", min = 6, max = 19, weight = 3, cd = 0, fn = judgement },
	{ name = "Reap", min = 5, max = 18, weight = 3, cd = 0, fast = true, fn = reap },
	{ name = "BashSmash", min = 0, max = 10, weight = 3, cd = 3, fast = true, fn = bashSmash },
	{ name = "Rush", min = 16, max = 45, weight = 3, cd = 7, fast = true, fn = rush },
	{ name = "Oath", min = 0, max = 13, weight = 2, cd = 14, behind = true, fn = oath },
	{ name = "Pivot", min = 0, max = 12, weight = 2, cd = 5, behind = true, fn = pivot },
}

local function pickMove(dist, behind, healing)
	local list, total, t = {}, 0, now()
	for _, mv in ipairs(MOVES) do
		if dist >= mv.min and dist <= mv.max and t >= (boss.cd[mv.name] or 0) then
			local w = mv.weight
			if behind then
				w *= mv.behind and 4 or 0.3
			end
			if healing and mv.fast then
				w *= 4
			end
			if mv.name == boss.lastMove then
				w *= 0.25
			end
			total += w
			table.insert(list, { mv, w })
		end
	end
	local r = math.random() * total
	for _, e in ipairs(list) do
		r -= e[2]
		if r <= 0 then
			return e[1]
		end
	end
	return nil
end

local function target(b)
	local best, bestD, bestPl
	for _, pl in ipairs(Players:GetPlayers()) do
		local char, _, hrp = aliveChar(pl)
		if char and onRoof(hrp.Position) and not inTurret(hrp.Position) then
			local d = flat(hrp.Position - b.root.Position).Magnitude
			if not bestD or d < bestD then
				best, bestD, bestPl = char, d, pl
			end
		end
	end
	return best, bestPl
end

local function brain(b)
	boss.cd, boss.stalkUntil, boss.stalkSide, boss.faceAt = {}, 0, 1, nil
	local turner = RunService.Heartbeat:Connect(function(dt)
		local tr = boss.faceAt
		if tr and tr.Parent and live(b) and now() >= (boss.staggerUntil or 0) and not b.root.Anchored then
			turnTowards(b.root, tr.Position, turnRate() * dt)
		end
	end)
	while live(b) do
		task.wait(0.1)
		if not live(b) or now() < (boss.staggerUntil or 0) then
			continue
		end
		b.hum.AutoRotate = false
		boss.guarding = true
		local tchar, tpl = target(b)
		local tr = tchar and tchar:FindFirstChild("HumanoidRootPart")
		if not tr then
			b.hum:MoveTo(b.root.Position)
			continue
		end
		if not boss.phase2 and b.hum.Health <= b.hum.MaxHealth * 0.7 then
			boss.guarding, boss.attacking, boss.faceAt = false, true, nil
			phase2(b)
			boss.attacking = false
			continue
		end
		local rel = flat(tr.Position - b.root.Position)
		local dist = rel.Magnitude
		local behind = dist > 0.1 and flat(b.root.CFrame.LookVector).Unit:Dot(rel.Unit) < -0.15
		local st = states[tpl]
		local healing = st and st.healing
		if now() < boss.stalkUntil and not healing and not behind then
			-- between strings: shield up, a slow heavy circling step, always facing you
			local keep = math.clamp(dist, 10, 18)
			b.hum.WalkSpeed = walkSpeed() * 0.55
			b.hum:MoveTo(tr.Position + CFrame.Angles(0, boss.stalkSide * 0.4, 0):VectorToWorldSpace(-rel.Unit) * keep)
			boss.faceAt = tr
			continue
		end
		local mv
		if boss.phase2 and not boss.p2Judged and boss.p2Count >= 1 then
			-- phase 2's second attack is always the long Judgement (he walks in till he's in reach)
			mv = dist <= MOVES[1].max and MOVES[1] or nil
		else
			mv = pickMove(dist, behind, healing)
		end
		if mv then
			boss.faceAt, boss.guarding, boss.attacking = nil, false, true
			b.hum.WalkSpeed = walkSpeed()
			boss.lastMove = mv.name
			if boss.phase2 then
				boss.p2Count += 1
				boss.p2Judged = boss.p2Judged or mv.name == "Judgement"
			end
			boss.cd[mv.name] = now() + mv.cd
			local ok, err = pcall(mv.fn, b, tchar)
			if not ok then
				warn("[DGUS] Castellan move " .. mv.name .. " error: " .. tostring(err))
			end
			boss.attacking = false
			boss.stalkSide = math.random() < 0.5 and -1 or 1
			boss.stalkUntil = now() + rand(0.5, 1.2) * tempo() + (C.IdleExtra or 0)
		else
			-- nothing in reach: he walks you down, shield up
			b.hum.WalkSpeed = walkSpeed()
			b.hum:MoveTo(dist < 7 and b.root.Position - rel.Unit * 8 or tr.Position)
			boss.faceAt = tr
		end
	end
	boss.faceAt = nil
	turner:Disconnect()
end

---------------------------------------------------------------------------
-- spawn, the cutscene, death, reset
---------------------------------------------------------------------------
local function seal(on)
	local f = Map.CastellanArena.Seal
	f.CanCollide = on
	TweenService:Create(f, TweenInfo.new(on and 0.6 or 2), { Transparency = on and 0.05 or 1 }):Play()
end

-- his mace falls with him and stays where it lands, to be taken (then picked in the weapon menu)
local function dropMace(b)
	local weapon = b.model:FindFirstChild("Weapon")
	local grip = weapon and weapon:FindFirstChild("GripWeld", true)
	if not grip then
		return
	end
	local haft = grip.Part1
	grip:Destroy()
	weapon.Parent = workspace
	for _, d in ipairs(weapon:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
		elseif d:IsA("Trail") then
			d.Enabled = false
		end
	end
	weapon.PrimaryPart = haft
	local at = b.root.Position + flat(b.root.CFrame.RightVector) * 2 * S
	weapon:PivotTo(CFrame.new(at.X, feet(b) + 0.55 * S, at.Z) * CFrame.Angles(0, math.random() * 6, 0) * CFrame.Angles(0, 0, math.pi / 2))
	playSound(haft, SOUNDS.Impact, 1, 0.45)
	dustCloud(Vector3.new(at.X, feet(b) + 0.5, at.Z), 2.5, 10)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "Take"
	pp.ObjectText = Config.Weapons.CastellanMace.Name
	pp.HoldDuration = 0.5
	pp.MaxActivationDistance = 12
	pp.RequiresLineOfSight = false
	pp.Parent = haft
	pp.Triggered:Connect(function(player)
		if not pp.Enabled then
			return
		end
		pp.Enabled = false
		weapon:Destroy()
		player:SetAttribute("Has_CastellanMace", true)
		if Core.equipWeapon(player, "CastellanMace") then
			FxRemote:FireClient(player, "Message", "Castellan's Mace. Too heavy for anyone sensible. Press T to choose weapons and armor.")
		else
			FxRemote:FireClient(player, "Message", "Castellan's Mace. Too heavy for you yet: it needs 1 Strength. Press T to choose weapons and armor.")
		end
	end)
end

-- From the end of the cutscene he stands on his own invisible floor (nothing else touches
-- his root), so he walks through braziers, statues and the dais at one height instead of
-- climbing onto them; his height is pinned to it, and the arena's edge and the turret
-- are his only walls (inBounds).
local function confine(b)
	b.root.CollisionGroup = "CastellanRoot"
	local standY = Map.CastellanArena.Center.Y + 3 * S
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if boss.gen ~= b.gen or boss.state ~= "fight" or not b.root.Parent then
			conn:Disconnect()
			return
		end
		if b.root.Anchored then
			return -- (the rush carries him itself)
		end
		local p = b.root.Position
		local x, z = p.X, p.Z
		if inBounds(p) then
			boss.lastSafe = p
		elseif boss.lastSafe then
			x, z = boss.lastSafe.X, boss.lastSafe.Z
		end
		if x ~= p.X or z ~= p.Z or math.abs(p.Y - standY) > 0.05 then
			b.root.CFrame = CFrame.new(x, standY, z) * b.root.CFrame.Rotation
			local v = b.root.AssemblyLinearVelocity
			b.root.AssemblyLinearVelocity = (x ~= p.X or z ~= p.Z) and Vector3.zero or Vector3.new(v.X, 0, v.Z)
		end
	end)
end

local function onDied(b)
	if boss.gen ~= b.gen or boss.state == "dead" then
		return
	end
	boss.state = "dead"
	Core.Save.mark("Castellan")
	ReplicatedStorage:SetAttribute("BossActive", false)
	ReplicatedStorage:SetAttribute("Music", "victory")
	FxRemote:FireAllClients("Banner", "CASTELLAN FELLED", "Victory")
	-- his last words stay up until you leave his battlements (or die)
	for _, pl in ipairs(Players:GetPlayers()) do
		local char, _, hrp = aliveChar(pl)
		if char and onRoof(hrp.Position) then
			FxRemote:FireClient(pl, "Say", C.Name2, C.Dying, true)
			task.spawn(function()
				while pl.Parent and aliveChar(pl) == char and onRoof(hrp.Position) do
					task.wait(0.3)
				end
				FxRemote:FireClient(pl, "SayClear")
			end)
		end
	end
	for _, d in ipairs(b.model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	task.spawn(function()
		task.wait(3)
		for _, d in ipairs(b.model:GetDescendants()) do
			if d:IsA("BasePart") then
				TweenService:Create(d, TweenInfo.new(2.5), { Transparency = 1 }):Play()
			end
		end
		task.wait(2.7)
		b.model:Destroy()
	end)
	dropMace(b)
	Core.dropSplinter(b.root.Position, b.model)
	seal(false)
	Map.Bell.Prompt.Enabled = true
	task.delay(4, function()
		FxRemote:FireAllClients("Message", "The way to the bell lies open.")
	end)
end

local function spawn()
	boss.gen += 1
	local model, hum, weld = Core.makeRig("Castellan", "Castellan", S, "CastellanMace")
	if not model then
		return
	end
	hum.MaxHealth, hum.Health = C.HP, C.HP
	hum.WalkSpeed = walkSpeed()
	hum.BreakJointsOnDeath = false
	model:SetAttribute("Radius", 3.2)
	model:SetAttribute("Boss", true)
	local root = model:FindFirstChild("HumanoidRootPart")
	model:PivotTo(Map.CastellanArena.Spawn + Vector3.new(0, 3 * S - 3, 0))
	local shield, shieldWeld = buildShield(model, root)
	-- pinned (anchored) at his standing height through his vigil and the cutscene: left to
	-- physics, a rig that isn't moving slowly sinks, and that jittered on the client. Let go
	-- when the fight starts (start).
	root.Anchored = true
	root.AssemblyLinearVelocity = Vector3.zero
	root.CollisionGroup = "EnemyRoot"
	hum.AutoRotate = false
	hum:MoveTo(root.Position)
	pcall(function()
		root:SetNetworkOwner(nil)
		hum:ChangeState(Enum.HumanoidStateType.Running)
	end)
	boss.model, boss.hum, boss.root = model, hum, root
	boss.phase2, boss.staggerUntil, boss.poise, boss.lastMove = false, 0, nil, nil
	boss.guarding, boss.attacking = false, false
	boss.state = "dormant"
	local b = { model = model, hum = hum, root = root, weld = weld, scale = S, gen = boss.gen, shield = shield, shieldWeld = shieldWeld }
	boss.current = b
	-- keeping his vigil before the throne
	pose(b, "CPlant", 0.01)
	bodyPose(b, "CVigil", 0.01)
	hum.HealthChanged:Connect(function(h)
		if boss.gen == b.gen and boss.state == "fight" then
			ReplicatedStorage:SetAttribute("BossHP", math.max(0, h))
		end
	end)
	hum.Died:Connect(function()
		onDied(b)
	end)
end

-- the first time: the camera taken over for his few words (SoulsClient's "Cutscene"),
-- everyone on the battlements held still. After that: he rises with a word.
local function cutscene(b)
	local y = Map.CastellanArena.Center.Y
	local V, look = Vector3.new, CFrame.lookAt
	local shots = {
		{ look(V(-12, y + 7, 252), V(-46, y + 9, 238)), look(V(-22, y + 8, 247), V(-46, y + 9, 238)), 3 },
		{ look(V(-33, y + 6, 244), V(-46, y + 14, 238)), look(V(-31, y + 5, 241), V(-46, y + 16, 238)), 3 },
		{ look(V(-6, y + 10, 254), V(-46, y + 9, 238)), look(V(-2, y + 12, 257), V(-46, y + 10, 238)), 2.6 },
	}
	local total = 8.6
	local held = {}
	for _, pl in ipairs(Players:GetPlayers()) do
		local char, _, hrp = aliveChar(pl)
		local st = states[pl]
		if char and st and onRoof(hrp.Position) then
			Core.setAction(st, now(), total, total, total)
			st.healing = false
			Core.cancelSwing(st)
			hrp.Anchored = true
			held[pl] = hrp
			FxRemote:FireClient(pl, "Grabbed", total)
			FxRemote:FireClient(pl, "Cutscene", shots)
		end
	end
	local t0 = now()
	local function at(t) -- wait until t seconds in; false if he was reset meanwhile
		task.wait(math.max(t - (now() - t0), 0))
		return boss.gen == b.gen and boss.state == "intro"
	end
	local function say(line)
		for pl in pairs(held) do
			FxRemote:FireClient(pl, "Say", C.Name, line)
		end
	end
	local steps = {
		{ 0.5, function() say(C.Lines[1]) end },
		{ 1.4, function() draw(b, "Idle", "CRise", 1.0, "Guard") end },
		{ 2.4, function() bodyPose(b, "CIdle", 0.8) end },
		{ 3.2, function() say(C.Lines[2]) end },
		{ 3.5, function() draw(b, "CSalute", "CSalute", 1.1) end },
		{ 6.1, function() say(C.Lines[3]) end },
		-- he beats the mace on his shield, twice
		{ 6.3, function() draw(b, "Raise", "CRear", 0.45) end },
		{ 6.8, function() draw(b, "Mid", "CHeave", 0.14); clang(b, true) end },
		{ 7.2, function() draw(b, "Raise", "CRear", 0.35) end },
		{ 7.6, function() draw(b, "Mid", "CHeave", 0.14); clang(b, true); FxRemote:FireAllClients("Shake", b.root.Position, 0.5) end },
		{ 8.0, function() idle(b) end },
		{ total, function() end },
	}
	local ok = true
	for _, s in ipairs(steps) do
		ok = at(s[1])
		if not ok then
			break
		end
		s[2]()
	end
	for pl, hrp in pairs(held) do
		if hrp.Parent then
			hrp.Anchored = false
			pcall(function()
				hrp:SetNetworkOwner(pl)
			end)
		end
	end
	return ok
end

local function start()
	if boss.state ~= "dormant" then
		return
	end
	boss.state = "intro"
	local b = boss.current
	seal(true)
	task.spawn(function()
		if not boss.seen then
			boss.seen = true
			Core.Save.mark("CastellanSeen")
			if not cutscene(b) then
				return
			end
		else
			FxRemote:FireAllClients("Say", C.Name, C.Again)
			draw(b, "Idle", "CRise", 1.0, "Guard")
			task.wait(1.0)
			bodyPose(b, "CIdle", 0.7)
			task.wait(0.7)
			if boss.gen ~= b.gen or boss.state ~= "intro" then
				return
			end
		end
		ReplicatedStorage:SetAttribute("BossName", C.Name)
		ReplicatedStorage:SetAttribute("BossMaxHP", b.hum.MaxHealth)
		ReplicatedStorage:SetAttribute("BossHP", b.hum.Health)
		ReplicatedStorage:SetAttribute("BossActive", true)
		ReplicatedStorage:SetAttribute("Music", C.Music ~= "" and "castellan" or "boss")
		b.root.Anchored = false
		pcall(function()
			b.root:SetNetworkOwner(nil)
			b.hum:ChangeState(Enum.HumanoidStateType.Running)
		end)
		boss.state = "fight"
		boss.lastSafe = nil
		confine(b)
		brain(b)
	end)
end

local function anyoneOnRoof()
	for _, pl in ipairs(Players:GetPlayers()) do
		local char, _, hrp = aliveChar(pl)
		if char and onRoof(hrp.Position) then
			return true
		end
	end
	return false
end

local function reset()
	if boss.state == "dead" or boss.state == "dormant" then
		return
	end
	if boss.model then
		boss.model:Destroy()
	end
	ReplicatedStorage:SetAttribute("BossActive", false)
	ReplicatedStorage:SetAttribute("Music", "none")
	seal(false)
	spawn()
end

function M.init(core)
	Core = core
	-- his own floor: one invisible slab over the battlements, the only thing his root touches
	-- (hits still find him: HitQuery sees every group)
	for _, g in ipairs({ "CastellanRoot", "CastellanFloor" }) do
		pcall(function()
			PhysicsService:RegisterCollisionGroup(g)
		end)
	end
	for _, g in ipairs(PhysicsService:GetRegisteredCollisionGroups()) do
		PhysicsService:CollisionGroupSetCollidable("CastellanRoot", g.name, false)
		PhysicsService:CollisionGroupSetCollidable("CastellanFloor", g.name, false)
	end
	PhysicsService:CollisionGroupSetCollidable("CastellanRoot", "CastellanFloor", true)
	PhysicsService:CollisionGroupSetCollidable("CastellanRoot", "HitQuery", true)
	local c = core.Map.CastellanArena.Center
	local floor = Instance.new("Part")
	floor.Name = "CastellanFloor"
	floor.Anchored = true
	floor.Transparency = 1
	floor.CanTouch = false
	floor.CastShadow = false
	floor.Size = Vector3.new(104, 1, 76)
	floor.CFrame = CFrame.new(-5, c.Y - 0.5, 238)
	floor.CollisionGroup = "CastellanFloor"
	floor.Parent = workspace
	Map, FxRemote, states, now, flat, rand, turnTowards, SOUNDS, playSound, burst, dustCloud, crackLines, fadeAway, shockwave, groundHeave, debrisChunks, pose, bodyPose, setTrail, aliveChar, damagePlayer, playersInRadius, playersInSector = core.Map, core.FxRemote, core.states, core.now, core.flat, core.rand, core.turnTowards, core.SOUNDS, core.playSound, core.burst, core.dustCloud, core.crackLines, core.fadeAway, core.shockwave, core.groundHeave, core.debrisChunks, core.pose, core.bodyPose, core.setTrail, core.aliveChar, core.damagePlayer, core.playersInRadius, core.playersInSector
	core.registerTarget(function(model)
		if not boss.model or boss.model ~= model then
			return nil
		end
		return {
			owner = boss,
			actor = boss.current,
			maxPoise = C.Poise,
			freeze = false,
			armor = boss.attacking, -- mid-string he shrugs off half of every poise hit
			-- standing guard, he turns aside anything from the front on the shield
			evade = function(player)
				local _, _, hrp = aliveChar(player)
				local root = boss.root
				if not (hrp and boss.guarding and boss.state == "fight" and now() >= (boss.staggerUntil or 0)) then
					return false
				end
				local to = flat(hrp.Position - root.Position)
				if to.Magnitude < 0.1 or flat(root.CFrame.LookVector).Unit:Dot(to.Unit) < 0.3 then
					return false
				end
				clang(boss.current)
				FxRemote:FireClient(player, "HitConfirm", 0.06)
				return true
			end,
			onBreak = function(_, t)
				if boss.state ~= "fight" then
					return
				end
				local actor = boss.current
				boss.staggerUntil = t + C.Stagger
				setTrail(actor, false)
				pose(actor, "Flinch", 0.15)
				bodyPose(actor, "Stagger", 0.12)
				shieldTo(actor, "Out", 0.2)
				boss.hum:MoveTo(boss.root.Position)
				playSound(boss.root, SOUNDS.Impact, 0.9, 0.5)
				FxRemote:FireAllClients("Shake", boss.root.Position, 0.5)
				local gen = boss.gen
				task.delay(C.Stagger, function()
					if boss.gen == gen and boss.state == "fight" then
						idle(actor)
					end
				end)
			end,
		}
	end)
	-- he wakes when someone steps out onto the battlements
	task.spawn(function()
		while true do
			task.wait(0.25)
			if boss.state == "dormant" then
				for _, pl in ipairs(Players:GetPlayers()) do
					local char, _, hrp = aliveChar(pl)
					if char and onRoof(hrp.Position) and not inTurret(hrp.Position) then
						start()
						break
					end
				end
			end
		end
	end)
end

M.spawn = function()
	boss.seen = boss.seen or Core.Save.done("CastellanSeen") -- (his cutscene: only ever the first time)
	if not Core.Save.done("Castellan") then
		return spawn()
	end
	-- felled in this save: gone, the bell's rope to hand
	boss.state = "dead"
	Map.Bell.Prompt.Enabled = true
	local pl = Core.Save.player
	if pl and not pl:GetAttribute("Has_CastellanMace") then -- shortcut: a mace left lying on his roof isn't put back there; it's simply yours
		pl:SetAttribute("Has_CastellanMace", true)
	end
end
M.reset = reset
M.devWound = function() -- (dev menu) one hit from death
	if boss.hum and boss.hum.Health > 0 then
		boss.hum.Health = 1
	end
end
M.state = function()
	return boss.state
end
M.anyoneInArena = anyoneOnRoof
M.onRoof = onRoof

return M
