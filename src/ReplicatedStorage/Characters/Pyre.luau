--!nonstrict
-- PYRE PRIEST (kind Pyre): the sun-cult of Pyralis, still at their rites. Taller than a Cinder Knight and gaunt, in
-- long robes of ash-grey over crimson, gold thread at every hem; a tall mitre; and behind its head, floating, a halo -
-- a ring of fire that never goes out. Its face is a mask of beaten gold, a sun with slits for eyes. It carries a tall
-- staff crowned with a sun-wheel, fire caged in its spokes - and it's a fighter too: a breastplate under the robes,
-- the skirt cut short for footwork, and in its off hand a short sword of black steel cracked through with fire, molten
-- drops running off its edge.
--
-- THE MOVESET (M.attack, which the shared brain calls once it's in range - Def.Engage: it holds you at middle range).
-- Its fire is fire - flames, cracks, things pouring - never a glowing shape:
--   Sunbolts     the staff raised, three flames gathered at the wheel, then loosed in a fan at you, dripping fire as
--                they fly. Roll, or step between them.
--   Pyre         the staff thrust skyward: the floor cracks open round where you stand, glowing, smoking - then fire
--                pours up out of the cracks. Get off the cracks.
--   Brand        close in: the sword - a cut across, then a rising backhand, each leaving the floor seared and
--                burning in its path. Roll each one.
--   Searing Ward close in, the other choice: the staff's foot slammed into the floor, cracks racing out round it with
--                flame bursting along them - and it skips back out of reach. Roll the cracks.
-- It won't cast through a wall: it comes round to see you first.
--
-- EVERYTHING ABOUT THIS CHARACTER IS IN THIS ONE FILE:
--   M.Proportions / M.Colors / M.Look   body shape and how the rig is dressed
--   M.Poses / M.Grips / M.BodyFor       its stance, its body poses and the staff's grips
--   M.Weapons                            the sun-staff
--   M.Def / M.attack                     stats and behaviour (the shared brain in GameServer/Enemies.lua)
local Players = game:GetService("Players")

local M = {}
M.Kind = "Pyre"
M.Proportions = { girth = 0.82, arm = 1.12, hunch = 0.06 }
M.IdlePose = "PBGuard"
local ASH, CRIMSON, GOLD = Color3.fromRGB(70, 64, 60), Color3.fromRGB(96, 18, 16), Color3.fromRGB(176, 132, 58)
local SUN, FLAME = Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 110, 30)
local STEEL, CINDER = Color3.fromRGB(34, 30, 30), Color3.fromRGB(120, 20, 6)
-- fire as particles: hot white-gold at the heart, orange, guttering to dark red
local FIRE_COLS = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 236, 170)), ColorSequenceKeypoint.new(0.3, FLAME), ColorSequenceKeypoint.new(1, CINDER) })
local function fireEmitter(parent, size, life, speed, rate)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture, pe.Color, pe.LightEmission = "rbxasset://textures/particles/fire_main.dds", FIRE_COLS, 1
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, size * 0.2) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	pe.Lifetime, pe.Speed, pe.Rate = NumberRange.new(life * 0.6, life), NumberRange.new(speed * 0.5, speed), rate or 0
	pe.Rotation, pe.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-180, 180)
	pe.Parent = parent
	return pe
end
-- molten drops: falling, burning - fire poured off whatever it's on
local function dripEmitter(parent, rate)
	local pe = Instance.new("ParticleEmitter")
	pe.Color, pe.LightEmission = ColorSequence.new(SUN, FLAME), 1
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.18), NumberSequenceKeypoint.new(1, 0.05) })
	pe.Lifetime, pe.Speed, pe.Rate = NumberRange.new(0.5, 0.9), NumberRange.new(0, 1), rate
	pe.Acceleration, pe.SpreadAngle = Vector3.new(0, -45, 0), Vector2.new(180, 180)
	pe.Parent = parent
	return pe
end
M.Colors = { skin = ASH, torso = ASH, legs = CRIMSON, arms = ASH }

M.Poses = {
	-- guard: tall and still, the staff planted, the free hand open before it
	PBGuard = { drop = 0.05, lean = 0.02, head = 0.08, footR = -0.15, footL = 0.2, breathe = 0.8, la1 = 0.7, la3 = -0.3, lel = 1.0 },
	-- Sunbolts: drawn up, the free hand cupped toward you; then thrust out
	PBGather = { drop = 0.1, lean = -0.2, head = -0.15, footR = -0.35, footL = 0.35, la1 = 1.2, la3 = -0.2, lel = 0.9, freeL = 0 },
	PBLoose = { drop = 0.25, lean = 0.3, head = 0.05, footR = 0.4, footL = -0.3, la1 = 1.6, la3 = -0.05, lel = 0.1, freeL = 0 },
	-- Pyre: up on its toes, both arms skyward
	PBInvoke = { drop = -0.05, lean = -0.35, head = -0.5, footR = -0.1, footL = 0.15, la1 = 2.8, la3 = -0.3, lel = 0.2, freeL = 0 },
	-- Searing Ward: crouched over the slammed staff
	PBSlam = { drop = 0.8, lean = 0.55, head = 0.25, footR = -0.4, footL = 0.6, spread = 0.2, la1 = 0.3, la3 = -0.9, lel = 0.5, freeL = 0 },
	-- Brand: wound to its left, the sword up and back; then the cut through, across to the right
	PBCock = { drop = 0.3, lean = -0.1, twist = -0.6, hip = -0.25, footR = 0.4, footL = -0.5, freeL = 0 },
	PBCut = { drop = 0.5, lean = 0.4, twist = 0.7, hip = 0.3, footR = -0.25, footL = 0.45, freeL = 0 },
}
-- the staff's grips. Unlike a blade (along the grip's -Y), the staff is built with its sun-wheel up the handle's +Y
-- side (Weapons below), so these hold it upright
local R = math.rad
M.Grips = {
	PGuard = { Vector3.new(1.0, -0.3, -0.5), CFrame.Angles(R(-4), 0, 0) }, -- planted upright beside it
	PRaise = { Vector3.new(0.8, 1.2, -0.6), CFrame.Angles(R(-25), 0, 0) }, -- raised before it, the wheel high
	PLoose = { Vector3.new(0.6, 0.6, -1.6), CFrame.Angles(R(-70), 0, 0) }, -- thrust out at you
	PSky = { Vector3.new(0.5, 2.6, -0.2), CFrame.Angles(R(-5), 0, 0) }, -- held up to the sky
	PSlam = { Vector3.new(0.4, -0.2, -1.3), CFrame.Angles(R(-12), 0, 0) }, -- foot driven into the floor before it
	-- the sword's (the left hand's: "L<name>"; its blade along the grip's -Y, as any blade's)
	LPGuard = { Vector3.new(-1.1, -0.5, -0.5), CFrame.Angles(R(25), 0, 0) }, -- low at its side, point forward
	LPRaise = { Vector3.new(-1.2, -0.3, 0.1), CFrame.Angles(R(30), 0, 0) }, -- held back, out of the cast
	LPLoose = { Vector3.new(-1.2, -0.4, -0.2), CFrame.Angles(R(25), 0, 0) },
	LPSky = { Vector3.new(-1.0, 2.4, -0.2), CFrame.Angles(R(180), 0, 0) }, -- raised with the staff, point to the sky
	LPSlam = { Vector3.new(-1.0, -0.4, -1.0), CFrame.Angles(R(55), 0, 0) },
	-- Brand: the staff kept low out of the way; the sword's cut and its backhand
	PCock = { Vector3.new(1.1, -0.3, 0.3), CFrame.Angles(R(-4), 0, 0) },
	LPCock = { Vector3.new(-1.4, 1.9, 0.2), CFrame.Angles(R(210), 0, R(-30)) }, -- up and back over the left shoulder
	PCut = { Vector3.new(1.1, -0.3, -0.3), CFrame.Angles(R(-4), 0, 0) },
	LPCut = { Vector3.new(0.4, 0.2, -1.8), CFrame.Angles(R(68), 0, R(37)) }, -- cut through, across to the right
	PRise = { Vector3.new(1.1, -0.3, 0.3), CFrame.Angles(R(-4), 0, 0) },
	LPRise = { Vector3.new(-1.5, 1.4, -1.0), CFrame.Angles(R(150), 0, R(-40)) }, -- the backhand, rising to the left
}
M.BodyFor = { PGuard = "PBGuard" }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local up = CFrame.Angles(0, 0, math.pi / 2)
	local cyl, ball = Enum.PartType.Cylinder, Enum.PartType.Ball
	-- THE MASK: a disc of beaten gold, rays round it, slits for eyes; the mitre over it
	parts.Head.Color = rgb(30, 24, 22)
	deco("Head", "Cowl", V(1.3, 1.35, 1.3), at(0, 0, 0.08), ASH, MAT.Fabric)
	deco("Head", "Mask", V(0.12, 1.15, 1.15), at(0, 0, -0.64) * CFrame.Angles(0, math.pi / 2, 0), GOLD, MAT.Metal, cyl)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		deco("Head", "MaskRay", V(0.12, 0.34, 0.05), at(math.cos(a) * 0.68, math.sin(a) * 0.68, -0.66) * CFrame.Angles(0, 0, a - math.pi / 2), GOLD, MAT.Metal)
	end
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "EyeSlit", V(0.3, 0.06, 0.04), at(sx * 0.22, 0.1, -0.71), rgb(6, 4, 2), MAT.SmoothPlastic)
		deco("Head", "Eye", V(0.12, 0.05, 0.03), at(sx * 0.22, 0.1, -0.72), SUN, MAT.Neon)
	end
	deco("Head", "MaskMouth", V(0.2, 0.05, 0.04), at(0, -0.28, -0.71), rgb(6, 4, 2), MAT.SmoothPlastic)
	for i = 0, 2 do -- the mitre, cut down for a fighter: narrowing, crimson banded in gold
		local w = 1.05 - i * 0.14
		deco("Head", "Mitre", V(w, 0.42, w * 0.8), at(0, 0.85 + i * 0.4, 0.05), i % 2 == 0 and CRIMSON or GOLD, i % 2 == 0 and MAT.Fabric or MAT.Metal)
	end
	-- THE HALO: a ring of fire behind its head, floating
	for i = 0, 15 do
		local a = i / 16 * math.pi * 2
		local p = deco("Head", "Halo", V(0.16, 0.36, 0.16), at(math.cos(a) * 1.05, 0.3 + math.sin(a) * 1.05, 0.75) * CFrame.Angles(0, 0, a), SUN, MAT.Neon)
		if i % 4 == 0 then
			local f = Instance.new("Fire")
			f.Size, f.Heat = 1.2, 3
			f.Color, f.SecondaryColor = FLAME, Color3.fromRGB(120, 20, 6)
			f.Parent = p
		end
	end
	local hl = deco("Head", "HaloLight", V(0.2, 0.2, 0.2), at(0, 0.3, 0.75), SUN, MAT.Neon)
	hl.Transparency = 1
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = FLAME, 12, 1.4
	l.Parent = hl
	-- the robes: ash-grey over crimson, a gold-edged stole down the front, a sun on the breast; the skirt to the floor
	deco("Chest", "Robe", V(cw * 1.1, ch * 1.05, cd * 1.15), at(0, 0, 0), ASH, MAT.Fabric)
	deco("Chest", "Mantle", V(cw * 1.35, 0.5, cd * 1.45), at(0, ch / 2 - 0.12, 0), CRIMSON, MAT.Fabric)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Chest", "Stole", V(0.32, ch * 1.6, 0.06), at(sx * cw * 0.2, -0.4, -cd * 0.6), CRIMSON, MAT.Fabric)
		deco("Chest", "StoleEdge", V(0.06, ch * 1.6, 0.07), at(sx * cw * 0.2 + sx * 0.16, -0.4, -cd * 0.6), GOLD, MAT.Metal)
	end
	deco("Chest", "BreastSun", V(0.06, 0.5, 0.5), at(0, 0.2, -cd * 0.62) * CFrame.Angles(0, math.pi / 2, 0), GOLD, MAT.Metal, cyl)
	-- a fighter under the robes: a breastplate of blackened steel, gold-rimmed; the skirt cut short, tabards in front
	deco("Chest", "Breastplate", V(cw * 0.9, ch * 0.62, 0.14), at(0, 0.12, -cd * 0.66), STEEL, MAT.Metal)
	deco("Chest", "BreastplateRim", V(cw * 0.94, 0.1, 0.16), at(0, 0.12 + ch * 0.31, -cd * 0.66), GOLD, MAT.Metal)
	deco("Hips", "Cincture", V(hw * 1.2, 0.22, hd * 1.25), at(0, 0.3, 0), GOLD, MAT.Metal)
	deco("Hips", "SwordBelt", V(hw * 1.25, 0.16, hd * 1.3), at(0, 0.05, 0) * CFrame.Angles(0, 0, 0.18), rgb(40, 28, 22), MAT.Leather)
	deco("Hips", "Scabbard", V(0.24, 2.0, 0.34), at(-hw * 0.62, -0.7, 0.1) * CFrame.Angles(0, 0, -0.25), rgb(30, 22, 18), MAT.Leather)
	for i = 0, 3 do
		deco("Hips", "Skirt", V(0.6, hw * 1.2 + i * 0.25, hw * 1.2 + i * 0.25), at(0, 0.05 - i * 0.5, 0) * up, i == 3 and GOLD or (i % 2 == 0 and ASH or CRIMSON), i == 3 and MAT.Metal or MAT.Fabric, cyl)
	end
	for _, sx in ipairs({ -1, 1 }) do
		deco("Hips", "Tabard", V(0.5, 1.6, 0.06), at(sx * 0.32, -0.9, -hd * 0.7), CRIMSON, MAT.Fabric)
	end
	-- the sword arm's pauldron
	deco("LUpperArm", "Pauldron", V(aw * 2.2, aw * 1.3, aw * 2.2), at(-0.1, ua * 0.34, 0), STEEL, MAT.Metal, ball)
	deco("LUpperArm", "PauldronRim", V(0.12, aw * 2.26, aw * 2.26), at(-0.1, ua * 0.3, 0) * up, GOLD, MAT.Metal, cyl)
	for _, n in ipairs({ "R", "L" }) do
		deco(n .. "UpperArm", "Sleeve", V(aw * 1.5, ua * 0.95, aw * 1.5), at(0, 0, 0), ASH, MAT.Fabric)
		deco(n .. "LowerArm", "Cuff", V(aw * 2.0, la * 0.75, aw * 2.0), at(0, 0.12, 0), CRIMSON, MAT.Fabric)
		deco(n .. "LowerArm", "CuffHem", V(aw * 2.04, 0.1, aw * 2.04), at(0, -la * 0.25, 0), GOLD, MAT.Metal)
		deco(n .. "LowerArm", "Bracer", V(aw * 1.35, la * 0.45, aw * 1.35), at(0, -la * 0.12, 0), rgb(40, 28, 22), MAT.Leather)
		parts[n .. "Foot"].Color = rgb(30, 24, 22)
	end
end

M.Weapons = {
	-- the sun-staff: a tall dark shaft, gold-banded; at its top a wheel of eight gold spokes round a caged fire. Built
	-- with its head up the handle's +Y side (so its grips hold it upright)
	SunStaff = function(w)
		local handle = w.mk("Grip", Vector3.new(0.22, 1.2, 0.22), Color3.fromRGB(40, 28, 22), Enum.Material.Wood)
		w.add(w.mk("Shaft", Vector3.new(0.2, 6.4, 0.2), Color3.fromRGB(36, 26, 22), Enum.Material.Wood), 1.6)
		w.add(w.mk("Foot", Vector3.new(0.28, 0.5, 0.28), GOLD, Enum.Material.Metal), -1.6)
		for _, y in ipairs({ 0.9, 2.6, 4.1 }) do
			w.add(w.mk("Band", Vector3.new(0.24, 0.14, 0.24), GOLD, Enum.Material.Metal), y)
		end
		local core = w.mk("SunCore", Vector3.new(0.75, 0.75, 0.75), SUN, Enum.Material.Neon)
		core.Shape = Enum.PartType.Ball
		w.add(core, 5.6)
		local s = w.scale
		for i = 0, 7 do
			local a = i / 8 * math.pi * 2
			w.add(w.mk("Spoke", Vector3.new(0.1, 0.8, 0.1), GOLD, Enum.Material.Metal), 5.6, CFrame.new(math.cos(a) * 0.6 * s, math.sin(a) * 0.6 * s, 0) * CFrame.Angles(0, 0, a - math.pi / 2))
			w.add(w.mk("Rim", Vector3.new(0.12, 0.5, 0.12), GOLD, Enum.Material.Metal), 5.6, CFrame.new(math.cos(a + 0.39) * 1.0 * s, math.sin(a + 0.39) * 1.0 * s, 0) * CFrame.Angles(0, 0, a + 0.39))
		end
		local function setup()
			local f = Instance.new("Fire")
			f.Size, f.Heat = 2, 4
			f.Color, f.SecondaryColor = FLAME, Color3.fromRGB(120, 20, 6)
			f.Parent = core
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness = SUN, 14, 1.6
			l.Parent = core
		end
		return { handle = handle, bladeLen = 1, setup = setup }
	end,
-- the ember blade: short, broad, black steel, a crack of fire down its length; molten drops run off it
EmberBlade = function(w)
	local handle = w.mk("Grip", Vector3.new(0.2, 0.8, 0.2), Color3.fromRGB(40, 28, 22), Enum.Material.Leather)
	w.add(w.mk("Pommel", Vector3.new(0.3, 0.3, 0.3), GOLD, Enum.Material.Metal), 0.5)
	w.add(w.mk("Guard", Vector3.new(0.18, 0.18, 1.1), GOLD, Enum.Material.Metal), -0.45)
	local blade = w.mk("Blade", Vector3.new(0.12, 2.8, 0.42), STEEL, Enum.Material.Metal)
	w.add(blade, -1.95)
	w.add(w.mk("Crack", Vector3.new(0.13, 2.3, 0.06), FLAME, Enum.Material.Neon), -1.85, nil, 0.04)
	w.add(w.mk("Tip", Vector3.new(0.12, 0.3, 0.3), STEEL, Enum.Material.Metal), -3.4, CFrame.Angles(math.pi / 4, 0, 0))
	local function setup()
		dripEmitter(blade, 6)
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = FLAME, 7, 0.9
		l.Parent = blade
	end
	return { handle = handle, bladeLen = 3.4, setup = setup }
end,
}

-- stats (the shared brain in GameServer/Enemies.lua reads these). Engage: it casts from range
M.Def = {
	HP = 250, Speed = 11, Scale = 1.3, Damage = 22, Range = 30, HalfAngle = 60,
	Windup = 0.9, Recover = 0.8, Aggro = 46, Leash = 60, Stagger = 0.35,
	HyperArmor = false, Weapon = "SunStaff", Weapon2 = "EmberBlade", Radius = 1.3, Lunge = 12,
	Poise = 40, HitLevel = "Medium", Engage = 20, IdleGrip = "PGuard",
	CutRange = 8.5, CutDamage = 24, CutWindup = 0.45,
	BoltSpeed = 36, BoltSpread = 13, PillarRadius = 4.5, PillarDamage = 38, PillarWarn = 1.1,
	WardRadius = 9, WardDamage = 24, WardRange = 7, Backstep = 34,
	Skin = ASH, Cloth = CRIMSON,
}

---------------------------------------------------------------------------
-- server: how it fights
---------------------------------------------------------------------------
local pose, bodyPose, playSound, SOUNDS, now, faceTowards, flat, playersInRadius, playersInSector, damagePlayer, burst, dustCloud, EnemiesFolder
local crackLines, fadeAway, setTrail
local Debris = game:GetService("Debris")

local function hold(e, duration, target)
	local t0 = now()
	while now() - t0 < duration do
		if not e.alive or now() < e.staggerUntil then
			return false
		end
		if target and target.Parent then
			faceTowards(e.root, target.Position)
		end
		task.wait()
	end
	return true
end
local function blockers(e)
	local ex = { e.model, EnemiesFolder }
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl.Character then
			table.insert(ex, pl.Character)
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ex
	params.RespectCanCollide = true
	return params
end
local function wheel(e) -- where the staff's sun-wheel is, else over its head
	local handle = e.weld and e.weld.Parent and e.weld.Part1
	local core = handle and handle.Parent:FindFirstChild("SunCore")
	return core and core.Position or e.root.Position + Vector3.new(0, 4 * e.scale, 0)
end
-- an unseen carrier for fire (its fire, smoke, light are what show), size its emitting volume
local function carrier(pos, size)
	local p = Instance.new("Part")
	p.Size, p.CFrame, p.Transparency = size or Vector3.one * 0.4, CFrame.new(pos), 1
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Parent = workspace
	return p
end
local function light(parent, range, bright)
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = FLAME, range, bright
	l.Parent = parent
	return l
end
-- flames standing on the floor at pos a while, then guttering out
local function flamesAt(pos, size, life)
	local c = carrier(pos)
	local f = Instance.new("Fire")
	f.Size, f.Heat, f.Color, f.SecondaryColor = size, size * 1.6, FLAME, CINDER
	f.Parent = c
	light(c, size * 3, 1.2)
	task.delay(life, function()
		f.Enabled = false
	end)
	Debris:AddItem(c, life + 1.5)
	return c
end
-- glowing cracks opening across the floor round pos (reveal: seconds to spread out), fading after linger
local function heatCracks(pos, radius, n, reveal, linger)
	local list = crackLines(pos + Vector3.new(0, 0.04, 0), radius, n, FLAME, Enum.Material.Neon, reveal)
	fadeAway(list, linger, 1.2)
	return list
end

-- one bolt of fire: a flame flying straight on, dripping fire, to the first player or wall it meets
local function bolt(e, from, dir, params)
	local def = e.def
	local orb = carrier(from, Vector3.one * 0.8)
	local f = Instance.new("Fire")
	f.Size, f.Heat, f.Color, f.SecondaryColor = 2.6, 6, FLAME, CINDER
	f.Parent = orb
	fireEmitter(orb, 1.6, 0.35, 1, 70).SpreadAngle = Vector2.new(180, 180) -- (its flame, streaming out behind it as it goes)
	dripEmitter(orb, 18)
	light(orb, 10, 1.6)
	task.spawn(function()
		local pos, last, left = from, now(), 2.6
		while left > 0 and orb.Parent do
			task.wait()
			local t = now()
			local stepV = dir * def.BoltSpeed * (t - last)
			left -= t - last
			last = t
			local wall = workspace:Raycast(pos, stepV, params)
			local nextPos = wall and wall.Position or pos + stepV
			local struck
			for _, pl in ipairs(playersInRadius(nextPos, 2.2, 4)) do
				damagePlayer(pl, def.Damage, pos, def.HitLevel)
				struck = true
			end
			pos = nextPos
			orb.Position = pos
			if wall or struck then
				burst(pos, FLAME, 18, 0.5, 14)
				local floor = workspace:Raycast(pos, Vector3.new(0, -8, 0), params)
				if floor then -- (it splashes: fire left burning where it fell)
					flamesAt(floor.Position + Vector3.new(0, 0.5, 0), 2.5, 1.4)
				end
				break
			end
		end
		for _, d in ipairs(orb:GetChildren()) do -- (its flame let die out, not snuffed)
			if d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("PointLight") then
				d.Enabled = false
			end
		end
		Debris:AddItem(orb, 1)
	end)
end

-- SUNBOLTS: three gathered at the wheel, loosed in a fan
local function sunbolts(e, tRoot, params)
	local def, root = e.def, e.root
	pose(e, "PRaise", def.Windup * 0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	bodyPose(e, "PBGather", def.Windup * 0.7)
	playSound(root, SOUNDS.FireCast ~= "" and SOUNDS.FireCast or SOUNDS.Unsheath, 0.4, 0.6)
	local glows, fires = {}, {}
	for i = 1, 3 do -- three flames kindled at the wheel, growing as they circle it
		glows[i] = carrier(wheel(e))
		fires[i] = Instance.new("Fire")
		fires[i].Size, fires[i].Heat, fires[i].Color, fires[i].SecondaryColor = 2, 3, FLAME, CINDER
		fires[i].Parent = glows[i]
	end
	light(glows[1], 12, 1.4)
	local t0, ok = now(), true
	while now() - t0 < def.Windup do
		if not e.alive or now() < e.staggerUntil then
			ok = false
			break
		end
		if tRoot.Parent then
			faceTowards(root, tRoot.Position)
		end
		local g = (now() - t0) / def.Windup
		local c = wheel(e)
		for i, p in ipairs(glows) do
			local a = now() * 6 + i * math.pi * 2 / 3
			fires[i].Size = 2 + 1.6 * g -- (a Fire is never smaller than 2)
			p.Position = c + (root.CFrame.RightVector * math.cos(a) + Vector3.new(0, math.sin(a), 0)) * 1.2
		end
		task.wait()
	end
	for _, p in ipairs(glows) do
		p:Destroy()
	end
	if not ok then
		return false
	end
	pose(e, "PLoose", 0.1)
	bodyPose(e, "PBLoose", 0.1)
	playSound(root, SOUNDS.FireHit, 0.5, 1.2)
	local from = wheel(e)
	local aim = (tRoot.Position + Vector3.new(0, 0.5, 0) - from).Unit
	for _, k in ipairs({ -1, 0, 1 }) do
		bolt(e, from, (CFrame.fromAxisAngle(Vector3.yAxis, math.rad(def.BoltSpread * k)) * aim), params)
	end
	return true
end

-- PYRE: the floor cracks open round where you stand, glowing and smoking - then fire pours up out of the cracks
local function pyre(e, tRoot, params)
	local def, root = e.def, e.root
	pose(e, "PSky", 0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	bodyPose(e, "PBInvoke", 0.35)
	local floor = workspace:Raycast(tRoot.Position, Vector3.new(0, -12, 0), params)
	local at = floor and floor.Position or tRoot.Position - Vector3.new(0, 3, 0)
	local R2 = def.PillarRadius * 2
	heatCracks(at, def.PillarRadius * 1.15, 7, def.PillarWarn * 0.7, def.PillarWarn + 1.2)
	local vent = carrier(at + Vector3.new(0, 0.3, 0), Vector3.new(R2, 0.4, R2)) -- (the cracks' breath: smoke and sparks seeping up)
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(Color3.fromRGB(70, 50, 40), Color3.fromRGB(24, 20, 20))
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 3.5) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
	smoke.Lifetime, smoke.Speed, smoke.Rate = NumberRange.new(0.8, 1.4), NumberRange.new(3, 6), 30
	smoke.Shape, smoke.EmissionDirection = Enum.ParticleEmitterShape.Box, Enum.NormalId.Top
	smoke.Parent = vent
	local sparks = dripEmitter(vent, 25)
	sparks.Acceleration, sparks.Speed = Vector3.new(0, 6, 0), NumberRange.new(2, 5)
	sparks.Shape = Enum.ParticleEmitterShape.Box
	light(vent, 16, 0.6)
	Debris:AddItem(vent, def.PillarWarn + 3)
	playSound(root, SOUNDS.Unsheath, 0.4, 0.4)
	local t0, ok = now(), true
	while now() - t0 < def.PillarWarn do
		if not e.alive or now() < e.staggerUntil then
			ok = false
			break
		end
		if tRoot.Parent then
			faceTowards(root, tRoot.Position)
		end
		task.wait()
	end
	smoke.Enabled, sparks.Enabled = false, false
	if not ok then
		return false
	end
	-- the eruption: fire pouring up out of the floor, roaring, then sinking back into the cracks
	local gout = fireEmitter(vent, 3.2, 0.8, 42)
	gout.Shape, gout.EmissionDirection, gout.SpreadAngle = Enum.ParticleEmitterShape.Box, Enum.NormalId.Top, Vector2.new(8, 8)
	gout.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.5), NumberSequenceKeypoint.new(0.4, 4.5), NumberSequenceKeypoint.new(1, 1.5) })
	gout.Acceleration = Vector3.new(0, 10, 0)
	gout:Emit(90)
	gout.Rate = 160
	for k = 0, 4 do -- standing flames in the cracks after it
		local a = k / 5 * math.pi * 2
		flamesAt(at + Vector3.new(math.cos(a), 0, math.sin(a)) * (k == 0 and 0 or def.PillarRadius * 0.55) + Vector3.new(0, 0.4, 0), 5, 1.2)
	end
	light(vent, 30, 3)
	playSound(vent, SOUNDS.FireHit, 1, 0.8)
	for _, pl in ipairs(playersInRadius(at + Vector3.new(0, 3, 0), def.PillarRadius, 8)) do
		damagePlayer(pl, def.PillarDamage, at, "Large")
	end
	burst(at + Vector3.new(0, 1, 0), FLAME, 30, 0.8, 22)
	task.delay(0.45, function()
		gout.Rate = 0
	end)
	return true
end

-- SEARING WARD: the staff slammed down, a wave of fire out round it - and a skip back out of reach
local function ward(e, tRoot)
	local def, root = e.def, e.root
	pose(e, "PSky", 0.25)
	bodyPose(e, "PBInvoke", 0.25)
	if not hold(e, 0.45, tRoot) then
		return false
	end
	pose(e, "PSlam", 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	bodyPose(e, "PBSlam", 0.1)
	task.wait(0.1)
	if not e.alive then
		return false
	end
	local at = root.Position - Vector3.new(0, 3 * def.Scale - 0.15, 0)
	-- cracks racing out from the staff's foot, flame bursting up along each as it goes
	local segs = heatCracks(at, def.WardRadius, 8, 0.25, 1.2)
	for i, seg in ipairs(segs) do
		if i % 2 == 0 then
			local d = flat(seg.Position - at).Magnitude / def.WardRadius
			task.delay(0.25 * d, function()
				local c = carrier(seg.Position + Vector3.new(0, 0.3, 0), Vector3.new(seg.Size.X, 0.2, 0.6))
				local pe = fireEmitter(c, 1.8, 0.5, 14)
				pe.Shape, pe.EmissionDirection, pe.SpreadAngle = Enum.ParticleEmitterShape.Box, Enum.NormalId.Top, Vector2.new(15, 15)
				pe:Emit(10)
				Debris:AddItem(c, 1)
			end)
		end
	end
	Debris:AddItem(light(carrier(at + Vector3.new(0, 1, 0)), 22, 2).Parent, 0.6)
	playSound(root, SOUNDS.FireHit, 0.9, 0.7)
	for _, pl in ipairs(playersInRadius(root.Position, def.WardRadius, 6)) do
		damagePlayer(pl, def.WardDamage, root.Position, "Large")
	end
	task.wait(0.15)
	if e.alive and tRoot.Parent then -- the skip back
		local back = flat(root.Position - tRoot.Position)
		back = back.Magnitude > 0.1 and back.Unit or -root.CFrame.LookVector
		root.AssemblyLinearVelocity = back * def.Backstep + Vector3.new(0, 14, 0)
	end
	return true
end

-- BRAND: the sword - a cut across, a rising backhand - each searing the floor in its path, flames left on it
local function brand(e, tRoot)
	local def, root = e.def, e.root
	for i, cut in ipairs({ { "PCock", "PBCock", "PCut", "PBCut" }, { "PCut", "PBCut", "PRise", "PBCock" } }) do
		pose(e, cut[1], def.CutWindup * 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		bodyPose(e, cut[2], def.CutWindup * 0.8)
		if not hold(e, i == 1 and def.CutWindup * 1.3 or def.CutWindup, tRoot) then
			return false
		end
		setTrail(e, true)
		playSound(root, SOUNDS.Slash, 0.6, 0.9 + i * 0.08)
		pose(e, cut[3], 0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		bodyPose(e, cut[4], 0.13)
		local v = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = flat(root.CFrame.LookVector) * def.Lunge + Vector3.new(0, v.Y, 0)
		task.wait(0.1)
		if not e.alive then
			return false
		end
		for _, pl in ipairs(playersInSector(root.CFrame, def.CutRange, 70, 6 * def.Scale)) do
			damagePlayer(pl, def.CutDamage, root.Position, i == 2 and "Large" or "Medium")
		end
		-- the seared arc: fire flung off the edge onto the floor across its path, left burning a moment
		local foot = root.Position - Vector3.new(0, 3 * def.Scale - 0.15, 0)
		local cf = root.CFrame
		for k = -2, 2 do
			local p = foot + (cf.LookVector * (4.5 - math.abs(k) * 0.6) + cf.RightVector * k * 1.6) * Vector3.new(1, 0, 1)
			heatCracks(p, 1.6, 1, 0, 1.2)
			if k % 2 == 0 then
				flamesAt(p + Vector3.new(0, 0.4, 0), 1.8, 0.9)
			end
		end
		task.wait(0.12)
		setTrail(e, false)
	end
	return true
end

function M.attack(e, targetChar)
	local def, hum, root = e.def, e.hum, e.root
	local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
	if not tRoot then
		return
	end
	local d = flat(tRoot.Position - root.Position).Magnitude
	local params = blockers(e)
	local c = wheel(e)
	if d > def.CutRange and workspace:Raycast(c, tRoot.Position - c, params) then
		hum:MoveTo(tRoot.Position) -- (can't see you: comes round till it can)
		task.wait(0.6)
		return
	end
	e.attacking = true
	hum:MoveTo(root.Position)
	hum.AutoRotate = false
	local ok
	if d <= def.CutRange then
		if math.random() < 0.6 then
			ok = brand(e, tRoot)
		else
			ok = ward(e, tRoot)
		end
	elseif math.random() < 0.55 then
		ok = sunbolts(e, tRoot, params)
	else
		ok = pyre(e, tRoot, params)
	end
	if ok then
		hold(e, def.Recover, tRoot)
	end
	if e.alive then
		pose(e, "Idle", 0.35)
	end
	hum.AutoRotate = true
	e.attacking = false
end

function M.init(core)
	pose, bodyPose, playSound, SOUNDS, now, faceTowards, flat = core.pose, core.bodyPose, core.playSound, core.SOUNDS, core.now, core.faceTowards, core.flat
	playersInRadius, damagePlayer, burst, dustCloud, EnemiesFolder = core.playersInRadius, core.damagePlayer, core.burst, core.dustCloud, core.EnemiesFolder
	playersInSector, crackLines, fadeAway, setTrail = core.playersInSector, core.crackLines, core.fadeAway, core.setTrail
end

return M
