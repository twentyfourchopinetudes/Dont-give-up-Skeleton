--!nonstrict
-- FURNACE BRUTE (kind Furnace): the palace's stokers, grown into their work. Half again a Cinder Knight's size and
-- twice its breadth, sealed in black riveted iron: a squat pot of a helm with one eye-slit and a chimney stack off its
-- back that never stops smoking, a cuirass built round a furnace - a grate in its belly glowing through the bars - huge
-- ball pauldrons hung with chains, a scorched leather apron. A war hammer in each fist.
--
-- THE MOVESET (M.attack, which the shared brain calls once it's in range - Def.Engage):
--   Anvilfall    both hammers heaved up overhead, the whole bulk rearing back under them; then slammed into the floor
--                together in front of it - the blow, and a shockwave out round it. Get out of the ring, or roll it.
--   Pistons      it rocks onto one foot and swings: right, left, right - three blows, each a step on, each across the
--                body. It's slow to start each one; roll each one.
--   Bellows      from a little further out: it plants, throws its hammers wide and DRAWS a breath - the grate flares
--                white-hot - then the furnace breathes out a cone of fire at you. Get behind it, or out of reach.
--
-- EVERYTHING ABOUT THIS CHARACTER IS IN THIS ONE FILE:
--   M.Proportions / M.Colors / M.Look   body shape and how the rig is dressed
--   M.Poses / M.Grips / M.BodyFor       its stance, its body poses and the hammers' grips ("L..." the left hammer's)
--   M.Weapons                            the hammer (one in each hand: Def.Weapon2)
--   M.Def / M.attack                     stats and behaviour (the shared brain in GameServer/Enemies.lua)
local M = {}
M.Kind = "Furnace"
M.Proportions = { girth = 1.55, arm = 1.15, hunch = 0.16 }
M.IdlePose = "FBGuard"
local IRON, IRON_DK, RIVET = Color3.fromRGB(38, 34, 32), Color3.fromRGB(22, 20, 20), Color3.fromRGB(96, 80, 64)
local HEAT, EMBER, LEATHER = Color3.fromRGB(255, 120, 30), Color3.fromRGB(255, 80, 20), Color3.fromRGB(58, 38, 26)
M.Colors = { skin = IRON_DK, torso = IRON, legs = IRON_DK, arms = IRON }

M.Poses = {
	-- guard: sunk wide on its feet, hammers hanging, its breath heaving
	FBGuard = { drop = 0.4, lean = 0.18, spread = 0.32, footR = -0.3, footL = 0.4, head = 0.1, breathe = 2.2, freeL = 0 },
	-- Anvilfall: reared back under both hammers, then the whole bulk down behind them
	FBRear = { drop = 0.3, lean = -0.45, head = -0.25, footR = -0.55, footL = 0.6, spread = 0.34, breathe = 3, freeL = 0 },
	FBSlam = { drop = 1.15, lean = 0.9, head = 0.3, footR = -0.6, footL = 0.95, spread = 0.38, breathe = 4, freeL = 0 },
	-- Pistons: wound to one side, then swung through to the other
	FBCockR = { drop = 0.4, lean = -0.1, twist = 0.65, hip = 0.3, footR = -0.55, footL = 0.45, spread = 0.3, freeL = 0 },
	FBSwingR = { drop = 0.6, lean = 0.45, twist = -0.75, hip = -0.35, footR = 0.35, footL = -0.2, spread = 0.3, freeL = 0 },
	FBCockL = { drop = 0.4, lean = -0.1, twist = -0.65, hip = -0.3, footR = 0.45, footL = -0.55, spread = 0.3, freeL = 0 },
	FBSwingL = { drop = 0.6, lean = 0.45, twist = 0.75, hip = 0.35, footR = -0.2, footL = 0.35, spread = 0.3, freeL = 0 },
	-- Bellows: chest thrown open drawing the breath, then hunched over the cone of fire
	FBDraw = { drop = 0.5, lean = -0.3, head = -0.35, spread = 0.48, footR = -0.4, footL = 0.4, breathe = 7, freeL = 0 },
	FBBreathe = { drop = 0.55, lean = 0.35, head = 0.1, spread = 0.48, footR = -0.4, footL = 0.5, breathe = 1, freeL = 0 },
}
-- the hammers' grips: the right hand's; "L<name>" the left's where it isn't just the right's mirrored. The head is
-- along the grip's -Y
local R = math.rad
M.Grips = {
	FGuard = { Vector3.new(1.3, -0.6, -0.4), CFrame.Angles(R(18), 0, 0) }, -- hanging at its sides, heads down
	FRaise = { Vector3.new(0.7, 2.6, 0.5), CFrame.Angles(R(215), 0, 0) }, -- both up overhead, heads behind
	FSlam = { Vector3.new(0.6, -0.8, -2.0), CFrame.Angles(R(55), 0, 0) }, -- both down into the floor in front
	FCockR = { Vector3.new(1.4, 1.9, 0.2), CFrame.Angles(R(210), 0, R(30)) }, -- the right drawn up and back
	LFCockR = { Vector3.new(-1.2, -0.3, -0.8), CFrame.Angles(R(30), 0, 0) }, -- (the left held low before it)
	FSwingR = { Vector3.new(-0.4, 0.2, -1.8), CFrame.Angles(R(68), 0, R(-37)) }, -- the right swung through, across to the left
	LFSwingR = { Vector3.new(-1.3, -0.4, -0.3), CFrame.Angles(R(20), 0, 0) },
	FCockL = { Vector3.new(1.3, -0.4, -0.3), CFrame.Angles(R(20), 0, 0) }, -- (the right resting)
	LFCockL = { Vector3.new(-1.4, 1.9, 0.2), CFrame.Angles(R(210), 0, R(-30)) }, -- the left drawn up and back
	FSwingL = { Vector3.new(1.2, -0.3, -0.8), CFrame.Angles(R(30), 0, 0) },
	LFSwingL = { Vector3.new(0.4, 0.2, -1.8), CFrame.Angles(R(68), 0, R(37)) }, -- the left swung through, across to the right
	FSpread = { Vector3.new(1.9, 0.1, 0.1), CFrame.Angles(R(10), 0, R(70)) }, -- thrown out wide, heads outward
}
M.BodyFor = { FGuard = "FBGuard" }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local rng = Random.new()
	local iron = IRON:Lerp(rgb(60, 44, 34), rng:NextNumber(0, 0.3)) -- (scorched differently, each)
	local up = CFrame.Angles(0, 0, math.pi / 2)
	local cyl, ball = Enum.PartType.Cylinder, Enum.PartType.Ball
	for _, pn in ipairs({ "Chest", "Hips", "RUpperArm", "LUpperArm", "RLowerArm", "LLowerArm", "RThigh", "LThigh", "RShin", "LShin" }) do
		parts[pn].Material = MAT.CrackedLava -- (what's inside the iron, where it shows)
		parts[pn].Color = rgb(70, 30, 16)
	end
	-- THE HELM: a squat pot, flat-topped, one slit of fire across it, rivets round; a chimney stack off its back
	parts.Head.Transparency = 1
	deco("Head", "Helm", V(1.5, 1.35, 1.5), at(0, 0.05, 0) * up, iron, MAT.Metal, cyl)
	deco("Head", "HelmLid", V(1.62, 0.18, 1.62), at(0, 0.72, 0), IRON_DK, MAT.Metal)
	deco("Head", "HelmBrow", V(1.6, 0.22, 0.3), at(0, 0.3, -0.68), IRON_DK, MAT.Metal)
	deco("Head", "Slit", V(1.0, 0.1, 0.05), at(0, 0.12, -0.76), HEAT, MAT.Neon)
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		deco("Head", "Rivet", V(0.12, 0.12, 0.12), at(math.sin(a) * 0.76, 0.5, math.cos(a) * 0.76), RIVET, MAT.Metal, ball)
	end
	local stack = deco("Head", "Stack", V(1.3, 0.42, 0.42), at(0.25, 1.0, 0.55) * up, IRON_DK, MAT.Metal, cyl)
	deco("Head", "StackCap", V(0.14, 0.6, 0.6), at(0.25, 1.68, 0.55) * up, iron, MAT.Metal, cyl)
	if stack then
		local smoke = Instance.new("ParticleEmitter")
		smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
		smoke.Color = ColorSequence.new(rgb(40, 34, 30), rgb(20, 18, 18))
		smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 3) })
		smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
		smoke.Lifetime, smoke.Rate, smoke.Speed = NumberRange.new(1.5, 2.5), 8, NumberRange.new(2, 4)
		smoke.EmissionDirection = Enum.NormalId.Right -- (the stack's axis is its X: up, stood on end)
		smoke.Acceleration, smoke.SpreadAngle = Vector3.new(0.5, 1, 0), Vector2.new(12, 12)
		smoke.Parent = stack
		local sparks = Instance.new("ParticleEmitter")
		sparks.Color, sparks.LightEmission = ColorSequence.new(HEAT, EMBER), 1
		sparks.Size = NumberSequence.new(0.12, 0)
		sparks.Lifetime, sparks.Rate, sparks.Speed = NumberRange.new(0.5, 1.1), 5, NumberRange.new(3, 6)
		sparks.EmissionDirection, sparks.SpreadAngle = Enum.NormalId.Right, Vector2.new(20, 20)
		sparks.Parent = stack
	end
	deco("Head", "Gorget", V(1.55, 0.4, 1.5), at(0, -0.72, 0), IRON_DK, MAT.Metal)
	-- THE FURNACE: a barrel of a cuirass, banded, a grate in its belly with the fire behind the bars
	deco("Chest", "Furnace", V(ch * 1.05, cw * 1.2, cw * 1.2), at(0, -0.05, 0) * up, iron, MAT.Metal, cyl)
	for _, y in ipairs({ ch * 0.36, -ch * 0.4 }) do
		deco("Chest", "FurnaceBand", V(0.22, cw * 1.24, cw * 1.24), at(0, y, 0) * up, IRON_DK, MAT.Metal, cyl)
	end
	local fz = -cw * 0.62 -- (the barrel's front)
	deco("Chest", "GrateFire", V(cw * 0.6, ch * 0.42, 0.06), at(0, -0.12, fz - 0.02), EMBER, MAT.Neon)
	for i = -2, 2 do
		deco("Chest", "GrateBar", V(0.08, ch * 0.46, 0.1), at(i * cw * 0.12, -0.12, fz - 0.07), IRON_DK, MAT.Metal)
	end
	deco("Chest", "GrateFrame", V(cw * 0.68, 0.1, 0.12), at(0, ch * 0.11, fz - 0.06), IRON_DK, MAT.Metal)
	deco("Chest", "GrateFrame", V(cw * 0.68, 0.1, 0.12), at(0, -ch * 0.35, fz - 0.06), IRON_DK, MAT.Metal)
	local glow = deco("Chest", "Grate", V(0.2, 0.2, 0.2), at(0, -0.12, fz + 0.1), EMBER, MAT.Neon)
	if glow then
		glow.Transparency = 1
		local l = Instance.new("PointLight")
		l.Name = "GrateLight"
		l.Color, l.Range, l.Brightness = HEAT, 12, 1.4
		l.Parent = glow
	end
	for i = 0, 9 do -- rivets down its front, either side of the grate
		for _, sx in ipairs({ -1, 1 }) do
			deco("Chest", "Rivet", V(0.1, 0.1, 0.1), at(sx * cw * 0.42, ch * 0.42 - i * ch * 0.09, -cw * 0.45), RIVET, MAT.Metal, ball)
		end
	end
	-- the apron: scorched leather, front and back, down past the knees
	deco("Hips", "Apron", V(hw * 1.1, 2.0, 0.08), at(0, -0.7, -hd * 0.68), LEATHER, MAT.Leather)
	deco("Hips", "ApronB", V(hw * 1.1, 1.6, 0.08), at(0, -0.5, hd * 0.68), LEATHER:Lerp(rgb(0, 0, 0), 0.3), MAT.Leather)
	deco("Hips", "Belt", V(hw * 1.3, 0.3, hd * 1.35), at(0, 0.3, 0), IRON_DK, MAT.Metal)
	-- arms: ball pauldrons, chains off them, cuffs; legs: heavy greaves, flat iron boots
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		deco(n .. "UpperArm", "Pauldron", V(aw * 2.6, aw * 2.6, aw * 2.6), at(sx * 0.15, ua * 0.32, 0), iron, MAT.Metal, ball)
		deco(n .. "UpperArm", "PauldronBand", V(0.16, aw * 2.66, aw * 2.66), at(sx * 0.15, ua * 0.32, 0), IRON_DK, MAT.Metal, cyl)
		for i = 0, 3 do -- a broken chain hanging off it
			deco(n .. "UpperArm", "Chain", V(0.1, 0.32, 0.22), at(sx * aw * 1.2, ua * 0.05 - i * 0.28, 0.1) * CFrame.Angles(0, i % 2 * math.pi / 2, 0), IRON_DK, MAT.Metal)
		end
		deco(n .. "UpperArm", "Rerebrace", V(aw * 1.2, ua * 0.5, aw * 1.2), at(0, -ua * 0.22, 0), IRON_DK, MAT.Metal)
		deco(n .. "LowerArm", "Cuff", V(aw * 1.5, la * 0.7, aw * 1.5), at(0, -0.05, 0), iron, MAT.Metal)
		deco(n .. "LowerArm", "CuffBand", V(aw * 1.56, 0.14, aw * 1.56), at(0, la * 0.2, 0), RIVET, MAT.Metal)
		deco(n .. "LowerArm", "Fist", V(aw * 1.4, 0.55, aw * 1.4), at(0, -la * 0.45, 0), IRON_DK, MAT.Metal)
		deco(n .. "Thigh", "Tasset", V(lw * 1.25, 1.0, lw * 1.25), at(0, 0.05, 0), iron, MAT.Metal)
		deco(n .. "Shin", "Greave", V(lw * 1.3, 1.1, lw * 1.3), at(0, -0.1, 0), iron, MAT.Metal)
		deco(n .. "Shin", "Knee", V(lw * 1.2, lw * 1.2, lw * 1.2), at(0, 0.55, -0.1), IRON_DK, MAT.Metal, ball)
		deco(n .. "Foot", "Boot", V(0.85, 0.42, 1.25), at(0, 0.05, -0.05), IRON_DK, MAT.Metal)
	end
	for _, x in ipairs({ -0.25, 0.25 }) do -- eyes: in the slit
		deco("Head", "Eye", V(0.12, 0.07, 0.04), at(x, 0.12, -0.79), rgb(255, 220, 140), MAT.Neon)
	end
end

M.Weapons = {
	-- a war hammer: a short iron-shod haft, a great square head of black iron cracked through with fire, a spike behind
	FurnaceHammer = function(w)
		local iron = Color3.fromRGB(36, 32, 30)
		local handle = w.mk("Grip", Vector3.new(0.3, 1.1, 0.3), LEATHER, Enum.Material.Leather)
		w.add(w.mk("Haft", Vector3.new(0.26, 3.2, 0.26), Color3.fromRGB(44, 32, 26), Enum.Material.Wood), -1.6)
		w.add(w.mk("Pommel", Vector3.new(0.4, 0.4, 0.4), iron, Enum.Material.Metal), 0.7)
		w.add(w.mk("Langet", Vector3.new(0.3, 0.9, 0.3), iron, Enum.Material.Metal), -2.8)
		w.add(w.mk("Head", Vector3.new(1.15, 1.15, 2.1), iron, Enum.Material.Metal), -3.6)
		w.add(w.mk("HeadBand", Vector3.new(1.2, 1.2, 0.2), RIVET, Enum.Material.Metal), -3.6, nil, 0.55)
		w.add(w.mk("HeadBand", Vector3.new(1.2, 1.2, 0.2), RIVET, Enum.Material.Metal), -3.6, nil, -0.55)
		local crack = w.mk("Crack", Vector3.new(1.17, 0.14, 2.12), HEAT, Enum.Material.Neon)
		w.add(crack, -3.6)
		w.add(w.mk("Face", Vector3.new(1.3, 1.3, 0.25), Color3.fromRGB(54, 48, 44), Enum.Material.Metal), -3.6, nil, -1.1)
		w.add(w.mk("Spike", Vector3.new(0.3, 0.3, 0.9), iron, Enum.Material.Metal), -3.6, nil, 1.45)
		local function setup()
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness = HEAT, 8, 0.9
			l.Parent = crack
		end
		return { handle = handle, bladeLen = 3.6, setup = setup }
	end,
}

-- stats (the shared brain in GameServer/Enemies.lua reads these). Inside Close it hammers; out to Engage it breathes
M.Def = {
	HP = 560, Speed = 8.5, Scale = 1.6, Damage = 46, Range = 9, HalfAngle = 45,
	Windup = 1.05, Recover = 1.3, Aggro = 36, Leash = 55, Stagger = 0.6, StaggerPush = 6,
	HyperArmor = true, Weapon = "FurnaceHammer", Weapon2 = "FurnaceHammer", Radius = 2.2, Lunge = 9,
	Poise = 95, HitLevel = "Knockdown", Engage = 13, Close = 8, IdleGrip = "FGuard",
	ShockRadius = 10, ShockDamage = 26, PistonDamage = 30, PistonWindup = 0.5,
	BreathDamage = 11, BreathTick = 0.3, BreathTime = 1.3, BreathReach = 13, DrawTime = 1.1,
	Skin = IRON_DK, Cloth = LEATHER,
}

---------------------------------------------------------------------------
-- server: how it fights
---------------------------------------------------------------------------
local pose, bodyPose, playSound, SOUNDS, now, faceTowards, setTrail, flat, playersInSector, playersInRadius, damagePlayer, burst, dustCloud, FxRemote

local function hold(e, duration, target) -- (false if it's staggered or slain in the meantime)
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
local function feet(e)
	return e.root.Position - Vector3.new(0, 3 * e.def.Scale - 0.2, 0)
end
local function step(e, k)
	local root = e.root
	local v = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = flat(root.CFrame.LookVector) * e.def.Lunge * (k or 1) + Vector3.new(0, v.Y, 0)
end

-- ANVILFALL: both up, both down - the blow before it, a shockwave round it
local function anvilfall(e, tRoot)
	local def, root = e.def, e.root
	pose(e, "FRaise", def.Windup * 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	bodyPose(e, "FBRear", def.Windup * 0.8)
	playSound(root, SOUNDS.Unsheath, 0.5, 0.4)
	if not hold(e, def.Windup, tRoot) then
		return false
	end
	setTrail(e, true)
	playSound(root, SOUNDS.Slash, 0.7, 0.45)
	pose(e, "FSlam", 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	bodyPose(e, "FBSlam", 0.14)
	step(e, 0.6)
	task.wait(0.14)
	if not e.alive then
		return false
	end
	local hit = {}
	for _, pl in ipairs(playersInSector(root.CFrame, def.Range, def.HalfAngle, 6 * def.Scale)) do
		hit[pl] = damagePlayer(pl, def.Damage, root.Position, def.HitLevel)
	end
	local at = feet(e) + flat(root.CFrame.LookVector) * 4.5
	for _, pl in ipairs(playersInRadius(at, def.ShockRadius, 3.5)) do -- (the ring: only what's on the floor)
		if not hit[pl] then
			damagePlayer(pl, def.ShockDamage, at, "Large")
		end
	end
	burst(at, EMBER, 30, 0.7, 24)
	dustCloud(at, def.ShockRadius * 0.6, 14)
	playSound(root, SOUNDS.WatchdogSmash, 0.9, 0.8)
	FxRemote:FireAllClients("Shake", at, 0.6)
	setTrail(e, false)
	return true
end

-- PISTONS: right, left, right - each wound up, each swung through with a step
local function pistons(e, tRoot)
	local def, root = e.def, e.root
	for i, side in ipairs({ "R", "L", "R" }) do
		pose(e, "FCock" .. side, def.PistonWindup * 0.85, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		bodyPose(e, "FBCock" .. side, def.PistonWindup * 0.85)
		if i == 1 then
			playSound(root, SOUNDS.Unsheath, 0.4, 0.5)
		end
		if not hold(e, i == 1 and def.PistonWindup * 1.4 or def.PistonWindup, tRoot) then
			return false
		end
		setTrail(e, true)
		playSound(root, SOUNDS.Slash, 0.6, 0.5 + i * 0.04)
		pose(e, "FSwing" .. side, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		bodyPose(e, "FBSwing" .. side, 0.16)
		step(e, 0.8)
		task.wait(0.12)
		if not e.alive then
			return false
		end
		for _, pl in ipairs(playersInSector(root.CFrame, def.Range - 0.5, 70, 6 * def.Scale)) do
			damagePlayer(pl, def.PistonDamage, root.Position, i == 3 and "Large" or "Medium")
		end
		task.wait(0.1)
		setTrail(e, false)
	end
	return true
end

-- BELLOWS: hammers thrown wide, a long drawn breath (the grate white-hot), then a cone of fire out of the furnace
local function bellows(e, tRoot)
	local def, root, model = e.def, e.root, e.model
	pose(e, "FSpread", 0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	bodyPose(e, "FBDraw", def.DrawTime * 0.8)
	local fires, lights = {}, {}
	for _, d in ipairs(model:GetDescendants()) do
		if d.Name == "GrateFire" then
			table.insert(fires, d)
		elseif d.Name == "GrateLight" then
			table.insert(lights, d)
		end
	end
	playSound(root, SOUNDS.FireHit, 0.3, 0.35)
	local t0 = now()
	while now() - t0 < def.DrawTime do -- (drawing it in: white-hot, brighter and brighter)
		if not e.alive or now() < e.staggerUntil then
			break
		end
		local g = (now() - t0) / def.DrawTime
		for _, f in ipairs(fires) do
			f.Color = EMBER:Lerp(Color3.fromRGB(255, 240, 200), g)
		end
		for _, l in ipairs(lights) do
			l.Brightness, l.Range = 1.4 + 4 * g, 12 + 10 * g
		end
		if tRoot.Parent then
			faceTowards(root, tRoot.Position)
		end
		task.wait()
	end
	local function cool()
		for _, f in ipairs(fires) do
			f.Color = EMBER
		end
		for _, l in ipairs(lights) do
			l.Brightness, l.Range = 1.4, 12
		end
	end
	if not e.alive or now() < e.staggerUntil then
		cool()
		return false
	end
	-- the breath: a cone of fire off the grate, hurting all in it a tick at a time
	bodyPose(e, "FBBreathe", 0.15)
	local src = fires[1]
	local emitter
	if src then
		emitter = Instance.new("ParticleEmitter")
		emitter.Texture = "rbxasset://textures/particles/fire_main.dds"
		emitter.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 160)), ColorSequenceKeypoint.new(0.35, HEAT), ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 20, 6)) })
		emitter.LightEmission = 1
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 5) })
		emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
		emitter.Lifetime, emitter.Rate, emitter.Speed = NumberRange.new(0.35, 0.5), 140, NumberRange.new(26, 34)
		emitter.EmissionDirection, emitter.SpreadAngle = Enum.NormalId.Front, Vector2.new(16, 16)
		emitter.Rotation, emitter.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-200, 200)
		emitter.Parent = src
	end
	playSound(root, SOUNDS.FireHit, 0.8, 0.5)
	local tb, lastTick = now(), -1
	while now() - tb < def.BreathTime and e.alive and now() >= e.staggerUntil do
		if now() - lastTick >= def.BreathTick then
			lastTick = now()
			for _, pl in ipairs(playersInSector(root.CFrame, def.BreathReach, 24, 6 * def.Scale)) do
				damagePlayer(pl, def.BreathDamage, root.Position, "Small")
			end
		end
		task.wait()
	end
	if emitter then
		emitter.Enabled = false
		game:GetService("Debris"):AddItem(emitter, 0.6)
	end
	cool()
	return e.alive
end

function M.attack(e, targetChar)
	local def, hum, root = e.def, e.hum, e.root
	local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
	if not tRoot then
		return
	end
	e.attacking = true
	hum:MoveTo(root.Position)
	hum.AutoRotate = false
	local d = flat(tRoot.Position - root.Position).Magnitude
	local ok, rest
	if d > def.Close then
		ok, rest = bellows(e, tRoot), def.Recover
	elseif math.random() < 0.5 then
		ok, rest = anvilfall(e, tRoot), def.Recover * 1.2 -- (the slam leaves it longest open)
	else
		ok, rest = pistons(e, tRoot), def.Recover
	end
	if ok then
		hold(e, rest)
	end
	setTrail(e, false)
	if e.alive then
		pose(e, "Idle", 0.45)
	end
	hum.AutoRotate = true
	e.attacking = false
end

function M.init(core)
	pose, bodyPose, playSound, SOUNDS, now, faceTowards, setTrail, flat = core.pose, core.bodyPose, core.playSound, core.SOUNDS, core.now, core.faceTowards, core.setTrail, core.flat
	playersInSector, playersInRadius, damagePlayer, burst, dustCloud, FxRemote = core.playersInSector, core.playersInRadius, core.damagePlayer, core.burst, core.dustCloud, core.FxRemote
end

return M
