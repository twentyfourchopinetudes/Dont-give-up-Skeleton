--!nonstrict
-- WARDER (kind Warder): the prison's elite guard, still walking its rounds in the winding passage under the wing's south
-- side. A brimmed iron kettle helm with a barred visor, a mail hauberk under a rust-red livery tabard stamped with a
-- key, an iron collar, manacles and keys at the belt, and a long glaive. Disciplined where the hollows are wild: it
-- fights in strings - a lunging thrust down the corridor, and if you're still in reach a wide sweep after it - and
-- sometimes opens with the sweep. Don't sidestep the thrust into the sweep.
--
-- EVERYTHING ABOUT THIS CHARACTER IS IN THIS ONE FILE:
--   M.Proportions / M.Colors / M.Look   body shape and how the rig is dressed
--   M.Weapons                            the glaive
--   M.Def / M.attack                     stats and behaviour (the shared brain in GameServer/Enemies.lua)
-- Grips used: ThrustBack / ThrustOut (Skeleton's), SweepBack / SweepMid / SweepEnd, Raise / Mid / Strike (Core's).
local M = {}
M.Kind = "Warder"
M.Proportions = { girth = 1.12, arm = 1.05, hunch = 0.05, twoHand = 0.4 } -- broad, upright, both hands on the pole
local MAIL, MAIL_DARK, LIVERY, LEATHER = Color3.fromRGB(92, 92, 94), Color3.fromRGB(58, 58, 62), Color3.fromRGB(112, 36, 26), Color3.fromRGB(52, 38, 28)
local IRON, IRON_DARK, BRASS = Color3.fromRGB(70, 68, 66), Color3.fromRGB(38, 36, 36), Color3.fromRGB(150, 118, 60)
M.Colors = { skin = MAIL, torso = MAIL, legs = MAIL_DARK, arms = MAIL }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local rng = Random.new(91)
	local livery = LIVERY:Lerp(rgb(60, 30, 24), rng:NextNumber(0, 0.3))
	for _, pn in ipairs({ "Chest", "RUpperArm", "LUpperArm", "RLowerArm", "LLowerArm", "RThigh", "LThigh", "RShin", "LShin" }) do
		parts[pn].Material = MAT.DiamondPlate -- (mail: the plate's grain reads as rings)
		parts[pn].Color = pn:find("Thigh") and MAIL_DARK or MAIL
	end
	-- THE KETTLE HELM: a rounded bowl, a wide brim pulled low, a barred visor where the face should be
	parts.Head.Transparency = 1
	deco("Head", "Helm", V(1.25, 1.25, 1.25), at(0, 0.12, 0), IRON, MAT.Metal, Enum.PartType.Ball)
	deco("Head", "HelmBrim", V(0.14, 2.0, 2.0), at(0, 0.32, 0) * CFrame.Angles(0, 0, math.pi / 2), IRON_DARK, MAT.Metal, Enum.PartType.Cylinder)
	deco("Head", "HelmCrest", V(0.12, 0.3, 1.3), at(0, 0.78, 0), IRON_DARK, MAT.Metal)
	deco("Head", "Visor", V(1.0, 0.9, 0.12), at(0, -0.15, -0.6), rgb(10, 10, 12), MAT.SmoothPlastic)
	for x = -0.36, 0.37, 0.18 do
		deco("Head", "VisorBar", V(0.06, 0.9, 0.06), at(x, -0.15, -0.68), IRON_DARK, MAT.Metal)
	end
	deco("Head", "VisorBand", V(1.05, 0.08, 0.08), at(0, 0.1, -0.68), IRON, MAT.Metal)
	deco("Head", "Aventail", V(1.3, 0.55, 1.3), at(0, -0.7, 0.05), MAIL_DARK, MAT.DiamondPlate) -- (mail hanging off the helm)
	-- the hauberk's skirt, the livery tabard over it (front and back), stamped with a brass key
	deco("Hips", "Hauberk", V(hw * 1.12, 1.2, hd * 1.12), at(0, -0.35, 0), MAIL_DARK, MAT.DiamondPlate)
	deco("Chest", "Tabard", V(cw * 0.78, ch * 1.4, 0.06), at(0, -0.45, -cd * 0.58), livery, MAT.Fabric)
	deco("Chest", "TabardB", V(cw * 0.78, ch * 1.35, 0.06), at(0, -0.45, cd * 0.58), livery:Lerp(rgb(0, 0, 0), 0.2), MAT.Fabric)
	deco("Chest", "KeyBow", V(0.32, 0.32, 0.04), at(0, ch * 0.18, -cd * 0.62), BRASS, MAT.Metal, Enum.PartType.Cylinder)
	deco("Chest", "KeyShank", V(0.08, 0.6, 0.04), at(0, -ch * 0.08, -cd * 0.62), BRASS, MAT.Metal)
	deco("Chest", "KeyBit", V(0.2, 0.1, 0.04), at(0.08, -ch * 0.32, -cd * 0.62), BRASS, MAT.Metal)
	for _, sx in ipairs({ -1, 1 }) do -- (the tabard's hem, torn)
		k.tatter(rng, "Chest", CFrame.new(sx * cw * 0.2, -ch * 1.1, -cd * 0.6), cw * 0.38, 0.5, livery, livery:Lerp(rgb(0, 0, 0), 0.5), 0.6)
	end
	-- an iron collar at the throat, a studded leather pauldron on the glaive arm, a plain one on the other
	deco("Chest", "Collar", V(cw * 0.9, 0.3, cd * 1.15), at(0, ch / 2 + 0.05, 0), IRON_DARK, MAT.Metal)
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		deco(n .. "UpperArm", "Pauldron", V(aw * 1.7, ua * 0.5, aw * 1.6), at(sx * 0.1, ua * 0.3, 0) * CFrame.Angles(0, 0, -sx * 0.3), n == "R" and LEATHER or IRON, n == "R" and MAT.Leather or MAT.Metal)
		if n == "R" then
			for i = -1, 1 do
				deco(n .. "UpperArm", "Stud", V(0.1, 0.1, 0.1), at(0.15 + i * 0.05, ua * 0.48, i * 0.25), BRASS, MAT.Metal, Enum.PartType.Ball)
			end
		end
		deco(n .. "LowerArm", "Bracer", V(aw * 1.18, la * 0.55, aw * 1.18), at(0, -la * 0.15, 0), LEATHER, MAT.Leather)
		deco(n .. "Shin", "Greave", V(lw * 1.12, 1.0, lw * 1.15), at(0, -0.05, -0.02), IRON, MAT.Metal)
		deco(n .. "Shin", "Knee", V(lw * 1.2, 0.3, lw * 1.25), at(0, 0.55, -0.05), IRON_DARK, MAT.Metal)
	end
	-- the belt: keys on a ring one side, a pair of manacles on a chain the other
	deco("Hips", "Belt", V(hw * 1.15, 0.22, hd * 1.15), at(0, 0.3, 0), LEATHER, MAT.Leather)
	deco("Hips", "Buckle", V(0.26, 0.24, 0.06), at(0, 0.3, -hd / 2 - 0.14), BRASS, MAT.Metal)
	deco("Hips", "KeyRing", V(0.08, 0.45, 0.45), at(hw / 2 + 0.1, 0.05, 0), IRON, MAT.Metal, Enum.PartType.Cylinder)
	for i = 0, 3 do
		deco("Hips", "Key", V(0.06, 0.4, 0.12), at(hw / 2 + 0.14, -0.2 - i * 0.04, -0.12 + i * 0.08) * CFrame.Angles(0, 0, 0.15 * i), IRON_DARK, MAT.Metal)
	end
	for i = 0, 3 do
		deco("Hips", "Chain", V(0.05, 0.18, 0.12), at(-hw / 2 - 0.1, 0.1 - i * 0.16, 0.1) * CFrame.Angles(0, (i % 2) * math.pi / 2, 0), IRON_DARK, MAT.Metal)
	end
	for i = 0, 1 do
		deco("Hips", "Manacle", V(0.08, 0.36, 0.36), at(-hw / 2 - 0.12, -0.6 - i * 0.12, 0.02 + i * 0.16) * CFrame.Angles(0, i * 0.6, 0), IRON, MAT.Metal, Enum.PartType.Cylinder)
	end
	-- eyes: direct children named "Eye" (two cold points behind the bars)
	for _, x in ipairs({ -0.2, 0.2 }) do
		deco("Head", "Eye", V(0.09, 0.05, 0.04), at(x, 0.0, -0.62), rgb(210, 180, 120), MAT.Neon)
	end
end

M.Weapons = {
	Glaive = function(w)
		local handle = w.mk("Grip", Vector3.new(0.24, 1.2, 0.24), LEATHER, Enum.Material.Leather)
		w.add(w.mk("Shaft", Vector3.new(0.2, 5.4, 0.2), w.wood, Enum.Material.Wood), -2.4)
		w.add(w.mk("Butt", Vector3.new(0.28, 0.5, 0.28), IRON_DARK, Enum.Material.Metal), 1.4)
		w.add(w.mk("Socket", Vector3.new(0.32, 0.6, 0.32), IRON_DARK, Enum.Material.Metal), -5.1)
		-- a long single-edged blade, its edge leading toward +Z like the jailer's cleaver, a back spike
		w.add(w.mk("Blade", Vector3.new(0.12, 2.2, 0.75), Color3.fromRGB(150, 150, 154), Enum.Material.Metal), -6.4, nil, 0.15)
		w.add(w.mk("Spike", Vector3.new(0.1, 0.18, 0.6), IRON_DARK, Enum.Material.Metal), -5.6, nil, -0.45)
		return { handle = handle, bladeLen = 7.4 }
	end,
}

-- stats (the shared brain in GameServer/Enemies.lua reads these)
M.Def = {
	HP = 170, Speed = 11.5, Scale = 1.12, Damage = 26, Range = 8.5, HalfAngle = 30,
	Windup = 0.55, Recover = 0.85, Aggro = 34, Leash = 60, Stagger = 0.4,
	HyperArmor = false, Weapon = "Glaive", Radius = 1.4, Lunge = 20,
	Poise = 34, HitLevel = "Medium", Engage = 8.5,
	SweepDamage = 22, SweepRange = 7.5, SweepHalf = 85, SweepWindup = 0.45, -- (the follow-up: wide, a bit shorter)
	Skin = MAIL, Cloth = LIVERY,
}

---------------------------------------------------------------------------
-- server: how it fights
---------------------------------------------------------------------------
local pose, bodyPose, playSound, SOUNDS, now, faceTowards, setTrail, flat, playersInSector, damagePlayer

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

local function hit(e, range, half, dmg, level)
	if e.alive then
		for _, pl in ipairs(playersInSector(e.root.CFrame, range, half, 6 * e.def.Scale)) do
			damagePlayer(pl, dmg, e.root.Position, level)
		end
	end
end

-- the thrust: drawn back to the hip, then driven down the corridor with a long lunge
local function thrust(e, tRoot)
	local def, root = e.def, e.root
	pose(e, "ThrustBack", def.Windup * 0.8)
	bodyPose(e, "Windup", def.Windup * 0.8)
	playSound(root, SOUNDS.Unsheath, 0.35, 0.75)
	if not hold(e, def.Windup, tRoot) then
		return false
	end
	playSound(root, SOUNDS.Slash, 0.5, 0.85)
	setTrail(e, true)
	pose(e, "ThrustOut", 0.08)
	bodyPose(e, "Strike", 0.08)
	local v = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = flat(root.CFrame.LookVector) * def.Lunge + Vector3.new(0, v.Y, 0)
	task.wait(0.09)
	hit(e, def.Range, def.HalfAngle, def.Damage, def.HitLevel)
	setTrail(e, false)
	return true
end

-- the sweep: the glaive wound back over the shoulder, then a wide flat cut across
local function sweep(e, tRoot, windup)
	local def, root = e.def, e.root
	pose(e, "SweepBack", windup * 0.8)
	playSound(root, SOUNDS.Unsheath, 0.3, 0.6)
	if not hold(e, windup, tRoot) then
		return false
	end
	playSound(root, SOUNDS.Slash, 0.55, 0.7)
	setTrail(e, true)
	pose(e, "SweepMid", 0.07, Enum.EasingStyle.Linear)
	task.delay(0.07, function()
		pose(e, "SweepEnd", 0.08)
	end)
	local v = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = flat(root.CFrame.LookVector) * def.Lunge * 0.4 + Vector3.new(0, v.Y, 0)
	task.wait(0.1)
	hit(e, def.SweepRange, def.SweepHalf, def.SweepDamage, "Large")
	setTrail(e, false)
	return true
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
	local close = (tRoot.Position - root.Position).Magnitude < def.SweepRange * 0.7
	local ok
	if close and math.random() < 0.4 then -- (up close it sometimes opens with the sweep, held a beat longer)
		ok = sweep(e, tRoot, def.SweepWindup * 1.6)
	else
		ok = thrust(e, tRoot)
		-- the string: if you're still in reach (or stepped round the point), the sweep comes straight after
		if ok and tRoot.Parent and (tRoot.Position - root.Position).Magnitude < def.SweepRange + 1 and math.random() < 0.65 then
			ok = hold(e, 0.12) and sweep(e, tRoot, def.SweepWindup)
		end
	end
	if ok then
		hold(e, def.Recover) -- (recovery: your window to punish)
	end
	setTrail(e, false)
	if e.alive then
		pose(e, "Idle", 0.3)
	end
	hum.AutoRotate = true
	e.attacking = false
end

function M.init(core)
	pose, bodyPose, playSound, SOUNDS, now, faceTowards, setTrail, flat, playersInSector, damagePlayer = core.pose, core.bodyPose, core.playSound, core.SOUNDS, core.now, core.faceTowards, core.setTrail, core.flat, core.playersInSector, core.damagePlayer
end

return M
