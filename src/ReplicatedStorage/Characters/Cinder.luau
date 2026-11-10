--!nonstrict
-- CINDER KNIGHT (kind Cinder): the knights of Pyralis's fortress, burned and never let die. They keep the Maw's halls
-- and the Bulwark's spires in ones and twos: full plate gone black in the heat, molten seams glowing at every joint, a
-- great helm with a cross of ember light in its visor and a crest of fire, a charred crimson tabard with Pyralis's sun
-- on it in tarnished gold, a cape. Each carries a halberd in both hands, long enough to keep you at its length.
--
-- THE MOVESET (M.attack, which the shared brain calls once it's in range - Def.Engage, far, for the charge):
--   Cinderfall  close in: the halberd heaved up overhead, the knight leaning back under it, then brought straight
--               down - a long, narrow line in front of it, ending in the floor in a spray of embers. Step to the side
--               of it, not back: it reaches. Then, a beat later, the follow-up: it wrenches the halberd up out of
--               the floor, draws it back to the hip and thrusts it at you with a step - a slash into a thrust. Roll the
--               thrust too; it's left overreached after: punish it.
--   Brand Charge from further out: it sinks, winds the halberd back and levels it at you, then runs you down
--               spike-first in a straight line, past where you were. It commits to the line once it starts: roll
--               sideways. It won't charge off an edge (it stops short).
--
-- EVERYTHING ABOUT THIS CHARACTER IS IN THIS ONE FILE:
--   M.Proportions / M.Colors / M.Look   body shape and how the rig is dressed
--   M.Poses / M.Grips / M.BodyFor       its stance, its body poses and the halberd's grips
--   M.Weapons                            the halberd
--   M.Def / M.attack                     stats and behaviour (the shared brain in GameServer/Enemies.lua)
local M = {}
M.Kind = "Cinder"
M.Proportions = { girth = 1.15, arm = 1.05, hunch = 0.02, twoHand = 1.0 } -- upright; the left hand a stud down the haft
M.IdlePose = "KGuard"
local STEEL, STEEL_DK, GOLD = Color3.fromRGB(52, 48, 46), Color3.fromRGB(30, 28, 28), Color3.fromRGB(150, 112, 52)
local TABARD, MOLTEN, EMBER = Color3.fromRGB(90, 26, 22), Color3.fromRGB(255, 90, 20), Color3.fromRGB(255, 120, 40)
M.Colors = { skin = MOLTEN, torso = MOLTEN, legs = MOLTEN, arms = MOLTEN }

-- body poses: the knight's guard, and the two attacks' beats
M.Poses = {
	-- guard: square to you, weight settled, the halberd held up across the body
	KGuard = { drop = 0.25, lean = 0.1, twist = -0.25, hip = -0.1, head = 0.05, footR = -0.4, footL = 0.45, spread = 0.15, breathe = 1.5, freeL = 0 },
	-- Cinderfall: rearing back under the raised halberd, the front foot planted; then the whole body down behind it
	KRear = { drop = 0.2, lean = -0.35, twist = 0.25, hip = 0.15, head = -0.15, look = -0.1, footR = -0.55, footL = 0.6, spread = 0.18, breathe = 2.5, freeL = 0 },
	KChop = { drop = 0.8, lean = 0.75, twist = -0.15, hip = -0.1, side = 0.04, head = 0.25, footR = -0.6, footL = 0.95, spread = 0.2, breathe = 3, freeL = 0 },
	-- Brand Charge: sunk and wound back behind the levelled point, eyes on you; then running it home
	KBrace = { drop = 0.7, lean = 0.35, twist = -0.55, hip = -0.35, look = 0.4, head = -0.05, footR = -0.8, footL = 0.7, spread = 0.3, breathe = 3, freeL = 0 },
	KCharge = { drop = 0.55, lean = 0.6, twist = -0.2, hip = -0.1, head = -0.15, footR = 0.9, footL = -0.8, breathe = 3, freeL = 0 },
}
-- the halberd's grips (the right hand; the left rides a stud toward the butt). Its head is along the grip's -Y; the
-- axe blade's edge on its +Z side, so it leads in the overhead chop
local R = math.rad
M.Grips = {
	CKGuard = { Vector3.new(0.4, 0.7, -1.1), CFrame.Angles(R(160), 0, 0) * CFrame.Angles(0, 0, R(-15)) }, -- held up across the body, head high
	CKRaise = { Vector3.new(0.4, 2.2, 0.2), CFrame.Angles(R(235), 0, 0) }, -- heaved up overhead, the head hanging behind
	CKCleave = { Vector3.new(0.3, 0.2, -2.2), CFrame.Angles(R(62), 0, 0) }, -- brought down, the head in the floor far ahead
	CKLevel = { Vector3.new(0.9, -0.2, 0.6), CFrame.Angles(R(92), 0, 0) * CFrame.Angles(0, 0, R(-6)) }, -- levelled at the hip, drawn back
	CKPike = { Vector3.new(0.5, 0, -1.8), CFrame.Angles(R(90), 0, 0) }, -- driven out in front
}
M.BodyFor = { CKGuard = "KGuard" } -- (back to its guard: the body with it)

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local rng = Random.new()
	local steel = STEEL:Lerp(rgb(70, 56, 46), rng:NextNumber(0, 0.35)) -- (no two suits burned alike)
	local tabard = TABARD:Lerp(rgb(50, 22, 20), rng:NextNumber(0, 0.4))
	local up = CFrame.Angles(0, 0, math.pi / 2)
	-- under the plate: the knight itself, molten, showing at every joint
	for _, pn in ipairs({ "Chest", "Hips", "RUpperArm", "LUpperArm", "RLowerArm", "LLowerArm", "RThigh", "LThigh", "RShin", "LShin", "RFoot", "LFoot" }) do
		parts[pn].Material = MAT.CrackedLava
		parts[pn].Color = MOLTEN
	end

	-- THE GREAT HELM: a tall flat-topped bucket, a cross of ember light for its visor, a gold band, a crest of fire
	parts.Head.Transparency = 1
	deco("Head", "Helm", V(1.3, 1.45, 1.3), at(0, 0.08, 0), steel, MAT.Metal)
	deco("Head", "HelmTop", V(1.36, 0.14, 1.36), at(0, 0.82, 0), STEEL_DK, MAT.Metal)
	deco("Head", "HelmBand", V(1.36, 0.14, 1.36), at(0, 0.42, 0), GOLD, MAT.Metal)
	deco("Head", "HelmRidge", V(0.1, 1.4, 0.1), at(0, 0.08, -0.67), STEEL_DK, MAT.Metal)
	deco("Head", "VisorGlow", V(1.0, 0.12, 0.04), at(0, 0.2, -0.655), EMBER, MAT.Neon) -- (the slit, lit from inside)
	deco("Head", "VisorGlow", V(0.12, 0.6, 0.04), at(0, -0.12, -0.655), EMBER, MAT.Neon) -- (and the breath, the cross's stem)
	for i = 0, 3 do -- breaths punched either side of the stem
		for _, sx in ipairs({ -1, 1 }) do
			deco("Head", "Breath", V(0.07, 0.07, 0.04), at(sx * 0.28, -0.05 - i * 0.14, -0.655), rgb(14, 10, 8), MAT.SmoothPlastic)
		end
	end
	local crest = deco("Head", "Crest", V(0.12, 0.4, 1.0), at(0, 1.05, 0.05), GOLD, MAT.Metal)
	local fire = Instance.new("Fire") -- (the plume: fire, not feathers)
	fire.Size, fire.Heat = 2.2, 6
	fire.Color, fire.SecondaryColor = Color3.fromRGB(255, 120, 30), Color3.fromRGB(110, 14, 8)
	fire.Parent = crest
	deco("Head", "Gorget", V(1.25, 0.35, 1.2), at(0, -0.78, 0), STEEL_DK, MAT.Metal)

	-- the cuirass: a breastplate with a ridge down it, the backplate, faulds in three lames
	deco("Chest", "Breastplate", V(cw * 1.06, ch * 0.82, cd * 1.12), at(0, 0.08, 0), steel, MAT.Metal)
	deco("Chest", "PlateRidge", V(0.12, ch * 0.78, 0.08), at(0, 0.08, -cd * 0.57), STEEL_DK, MAT.Metal)
	for i = 0, 2 do
		deco("Hips", "Fauld", V(hw * (1.12 + i * 0.04), 0.24, hd * (1.14 + i * 0.04)), at(0, 0.25 - i * 0.22, 0), i % 2 == 0 and steel or STEEL_DK, MAT.Metal)
	end
	deco("Hips", "Belt", V(hw * 1.2, 0.18, hd * 1.2), at(0, 0.36, 0), rgb(40, 28, 22), MAT.Leather)
	deco("Hips", "Buckle", V(0.3, 0.24, 0.06), at(0, 0.36, -hd * 0.62), GOLD, MAT.Metal)

	-- the tabard over it, front and back, Pyralis's sun on the front in tarnished gold; the hem burned ragged
	deco("Chest", "Tabard", V(cw * 0.72, ch * 1.1, 0.06), at(0, -0.2, -cd * 0.6), tabard, MAT.Fabric)
	deco("Chest", "TabardB", V(cw * 0.72, ch * 1.1, 0.06), at(0, -0.2, cd * 0.6), tabard:Lerp(rgb(0, 0, 0), 0.2), MAT.Fabric)
	deco("Chest", "Sun", V(0.08, 0.5, 0.5), at(0, 0.05, -cd * 0.64) * up, GOLD, MAT.Metal, Enum.PartType.Cylinder)
	for i = 0, 7 do -- its rays
		deco("Chest", "SunRay", V(0.06, 0.32, 0.03), at(0, 0.05, -cd * 0.64) * CFrame.Angles(0, 0, i * math.pi / 4) * CFrame.new(0, 0.38, 0), GOLD, MAT.Metal)
	end
	for _, z in ipairs({ -1, 1 }) do
		for sx = -1, 1, 2 do
			k.tatter(rng, "Hips", CFrame.new(sx * cw * 0.18, -0.15, z * hd * 0.62), cw * 0.36, 1.1, tabard, tabard:Lerp(rgb(20, 8, 6), 0.6), 0.6)
		end
	end
	-- the cape, from the shoulders down the back, singed at the hem
	deco("Chest", "Cape", V(cw * 1.0, ch * 1.3, 0.08), at(0, -0.15, cd * 0.7) * CFrame.Angles(0.08, 0, 0), tabard:Lerp(rgb(20, 10, 10), 0.35), MAT.Fabric)
	for sx = -1, 1 do
		k.tatter(rng, "Chest", CFrame.new(sx * cw * 0.33, -ch * 0.95, cd * 0.76), cw * 0.36, 1.3, tabard:Lerp(rgb(20, 10, 10), 0.35), rgb(20, 8, 6), 0.7)
	end

	-- arms: layered pauldrons trimmed in gold, couters, vambraces, gauntlets
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		local tilt = CFrame.Angles(0, 0, -sx * 0.28)
		deco(n .. "UpperArm", "Pauldron", V(aw * 1.75, ua * 0.42, aw * 1.65), at(sx * 0.1, ua * 0.36, 0) * tilt, steel, MAT.Metal)
		deco(n .. "UpperArm", "PauldronTrim", V(aw * 1.8, 0.08, aw * 1.7), at(sx * 0.1, ua * 0.2, 0) * tilt, GOLD, MAT.Metal)
		deco(n .. "UpperArm", "Pauldron", V(aw * 1.55, ua * 0.3, aw * 1.5), at(sx * 0.12, ua * 0.08, 0) * tilt, STEEL_DK, MAT.Metal)
		deco(n .. "UpperArm", "Rerebrace", V(aw * 1.12, ua * 0.5, aw * 1.12), at(0, -ua * 0.22, 0), steel, MAT.Metal)
		deco(n .. "LowerArm", "Couter", V(aw * 1.25, 0.32, aw * 1.25), at(0, la * 0.42, 0.05), STEEL_DK, MAT.Metal, Enum.PartType.Ball)
		deco(n .. "LowerArm", "Vambrace", V(aw * 1.1, la * 0.55, aw * 1.1), at(0, 0, 0), steel, MAT.Metal)
		deco(n .. "LowerArm", "Gauntlet", V(aw * 1.18, 0.45, aw * 1.18), at(0, -la * 0.4, 0), STEEL_DK, MAT.Metal)
		-- legs: cuisses, fanned poleyns, greaves, pointed sabatons
		deco(n .. "Thigh", "Cuisse", V(lw * 1.1, 0.95, lw * 1.12), at(0, 0.05, 0), steel, MAT.Metal)
		deco(n .. "Shin", "Poleyn", V(lw * 1.22, 0.32, lw * 1.25), at(0, 0.55, -0.05), STEEL_DK, MAT.Metal)
		deco(n .. "Shin", "PoleynFan", V(lw * 0.9, 0.4, 0.06), at(0, 0.52, -lw * 0.66), GOLD, MAT.Metal)
		deco(n .. "Shin", "Greave", V(lw * 1.1, 0.95, lw * 1.12), at(0, -0.12, 0), steel, MAT.Metal)
		deco(n .. "Foot", "Sabaton", V(0.68, 0.3, 1.15), at(0, 0.02, -0.05), STEEL_DK, MAT.Metal)
		deco(n .. "Foot", "SabatonTip", V(0.4, 0.2, 0.4), at(0, -0.02, -0.68), STEEL_DK, MAT.Metal)
	end
	-- eyes: direct children named "Eye" (two embers deep in the slit)
	for _, x in ipairs({ -0.22, 0.22 }) do
		deco("Head", "Eye", V(0.1, 0.06, 0.04), at(x, 0.2, -0.68), Color3.fromRGB(255, 200, 120), MAT.Neon)
	end
end

M.Weapons = {
	-- a long halberd: a charred haft bound in iron, a broad axe blade, a hooked beak behind it, a spike on top; the
	-- blade's edge glows, and embers come off the head
	CinderHalberd = function(w)
		local haftC, iron = Color3.fromRGB(40, 30, 24), Color3.fromRGB(34, 32, 30)
		local handle = w.mk("Grip", Vector3.new(0.26, 1.0, 0.26), Color3.fromRGB(40, 28, 22), Enum.Material.Leather)
		w.add(w.mk("Haft", Vector3.new(0.22, 7.2, 0.22), haftC, Enum.Material.Wood), -1.2)
		w.add(w.mk("Wrap", Vector3.new(0.26, 0.9, 0.26), Color3.fromRGB(40, 28, 22), Enum.Material.Leather), 1.0) -- (the left hand's)
		w.add(w.mk("Butt", Vector3.new(0.3, 0.5, 0.3), iron, Enum.Material.Metal), 2.55)
		for _, y in ipairs({ -2.2, -3.6 }) do
			w.add(w.mk("Band", Vector3.new(0.27, 0.14, 0.27), Color3.fromRGB(150, 112, 52), Enum.Material.Metal), y)
		end
		w.add(w.mk("Langet", Vector3.new(0.26, 1.2, 0.08), iron, Enum.Material.Metal), -4.3)
		w.add(w.mk("Socket", Vector3.new(0.34, 0.6, 0.34), iron, Enum.Material.Metal), -4.95)
		w.add(w.mk("Axe", Vector3.new(0.12, 1.7, 1.25), Color3.fromRGB(60, 54, 50), Enum.Material.Metal), -5.4, nil, 0.75)
		local edge = w.mk("AxeEdge", Vector3.new(0.13, 1.6, 0.16), Color3.fromRGB(255, 110, 40), Enum.Material.Neon)
		w.add(edge, -5.4, nil, 1.42)
		w.add(w.mk("Beak", Vector3.new(0.1, 0.32, 0.9), iron, Enum.Material.Metal), -5.3, CFrame.Angles(0.25, 0, 0), -0.6)
		local spike = w.mk("Spike", Vector3.new(0.16, 1.4, 0.16), Color3.fromRGB(60, 54, 50), Enum.Material.Metal)
		w.add(spike, -6.4)
		local function setup()
			local light = Instance.new("PointLight")
			light.Color, light.Range, light.Brightness = EMBER, 10, 1.1
			light.Parent = edge
			local embers = Instance.new("ParticleEmitter")
			embers.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			embers.Color = ColorSequence.new(Color3.fromRGB(255, 170, 70), Color3.fromRGB(255, 70, 20))
			embers.Size = NumberSequence.new(0.18, 0)
			embers.Lifetime, embers.Rate, embers.Speed = NumberRange.new(0.5, 1.2), 14, NumberRange.new(0.5, 2)
			embers.LightEmission, embers.Acceleration, embers.SpreadAngle = 1, Vector3.new(0, 3, 0), Vector2.new(40, 40)
			embers.Parent = edge
		end
		return { handle = handle, bladeLen = 6, setup = setup }
	end,
}

-- stats (the shared brain in GameServer/Enemies.lua reads these). Engage is the charge's reach: inside Close it cleaves
M.Def = {
	HP = 200, Speed = 10.5, Scale = 1.15, Damage = 40, Range = 11, HalfAngle = 22,
	Windup = 0.75, Recover = 0.9, Aggro = 40, Leash = 60, Stagger = 0.4,
	HyperArmor = false, Weapon = "CinderHalberd", Radius = 1.4, Lunge = 10,
	Poise = 38, HitLevel = "Large", Engage = 16, Close = 9, IdleGrip = "CKGuard",
	ThrustDamage = 30, ThrustWindup = 0.75, -- (Cinderfall's follow-up: long enough that the slash's stagger (0.75) is over and you can roll it)
	ChargeDamage = 30, ChargeSpeed = 30, ChargeTime = 0.45, ChargeWindup = 0.6, ChargeRecover = 1.0,
	Skin = MOLTEN, Cloth = TABARD,
}

---------------------------------------------------------------------------
-- server: how it fights
---------------------------------------------------------------------------
local pose, bodyPose, playSound, SOUNDS, now, faceTowards, setTrail, flat, playersInSector, damagePlayer, burst, dustCloud, EnemiesFolder

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

local function headPos(e) -- where the halberd's head is (the trail's tip), else in front of it
	local handle = e.weld and e.weld.Parent and e.weld.Part1
	local tip = handle and handle:FindFirstChild("BladeTip")
	return tip and tip.WorldPosition or e.root.Position + e.root.CFrame.LookVector * e.def.Range
end

-- CINDERFALL: heaved up overhead, then straight down along a long narrow line, into the floor
local function cinderfall(e, tRoot)
	local def, root = e.def, e.root
	pose(e, "CKRaise", def.Windup * 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	bodyPose(e, "KRear", def.Windup * 0.8)
	playSound(root, SOUNDS.Unsheath, 0.4, 0.55)
	if not hold(e, def.Windup, tRoot) then
		return false
	end
	setTrail(e, true)
	playSound(root, SOUNDS.Slash, 0.6, 0.6)
	pose(e, "CKCleave", 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	bodyPose(e, "KChop", 0.12)
	local v = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = flat(root.CFrame.LookVector) * def.Lunge + Vector3.new(0, v.Y, 0)
	task.wait(0.12)
	if not e.alive then
		return false
	end
	for _, pl in ipairs(playersInSector(root.CFrame, def.Range, def.HalfAngle, 6 * def.Scale)) do
		damagePlayer(pl, def.Damage, root.Position, def.HitLevel)
	end
	local p = headPos(e)
	local ground = Vector3.new(p.X, root.Position.Y - 3 * def.Scale + 0.2, p.Z)
	burst(ground, EMBER, 16, 0.4, 16)
	dustCloud(ground, 1.6, 5)
	playSound(root, SOUNDS.Impact, 0.6, 0.7)
	setTrail(e, false)
	return true
end

-- THE FOLLOW-UP THRUST: out of Cinderfall, the halberd wrenched up and drawn back to the hip, then driven at you
-- with a step
local function followThrust(e, tRoot)
	local def, root = e.def, e.root
	pose(e, "CKLevel", def.ThrustWindup * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	bodyPose(e, "KBrace", def.ThrustWindup * 0.7)
	playSound(root, SOUNDS.Unsheath, 0.4, 0.6)
	if not hold(e, def.ThrustWindup, tRoot) then
		return false
	end
	setTrail(e, true)
	playSound(root, SOUNDS.Lunge, 0.7, 0.6)
	pose(e, "CKPike", 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	bodyPose(e, "KCharge", 0.1)
	local v = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = flat(root.CFrame.LookVector) * def.Lunge * 1.6 + Vector3.new(0, v.Y, 0)
	task.wait(0.1)
	if not e.alive then
		return false
	end
	for _, pl in ipairs(playersInSector(root.CFrame, def.Range + 1, 14, 6 * def.Scale)) do
		damagePlayer(pl, def.ThrustDamage, root.Position, def.HitLevel)
	end
	setTrail(e, false)
	return true
end

-- BRAND CHARGE: sunk behind the levelled halberd, then a straight run at you, spike first. Stops short of an edge.
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
local function brandCharge(e, tRoot)
	local def, root, hum = e.def, e.root, e.hum
	pose(e, "CKLevel", def.ChargeWindup * 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	bodyPose(e, "KBrace", def.ChargeWindup * 0.8)
	playSound(root, SOUNDS.Unsheath, 0.4, 0.45)
	if not hold(e, def.ChargeWindup, tRoot) then
		return false
	end
	local dir = flat(root.CFrame.LookVector)
	if dir.Magnitude < 0.1 then
		return false
	end
	dir = dir.Unit
	setTrail(e, true)
	playSound(root, SOUNDS.Lunge, 0.7, 0.55)
	pose(e, "CKPike", 0.1)
	bodyPose(e, "KCharge", 0.15)
	hum.WalkSpeed = def.ChargeSpeed
	hum:MoveTo(root.Position + dir * def.ChargeSpeed * def.ChargeTime * 1.5)
	local ignore = { EnemiesFolder }
	for _, pl in ipairs(game:GetService("Players"):GetPlayers()) do
		if pl.Character then
			table.insert(ignore, pl.Character)
		end
	end
	groundParams.FilterDescendantsInstances = ignore
	local seen, t0, lastDust = {}, now(), 0
	while now() - t0 < def.ChargeTime and e.alive and now() >= e.staggerUntil do
		-- the floor ahead: none (a ledge, the lava) and it stops where it is
		local ahead = root.Position + dir * 4 + Vector3.new(0, 2, 0)
		if not workspace:Raycast(ahead, Vector3.new(0, -(3 * def.Scale + 8), 0), groundParams) then
			break
		end
		for _, pl in ipairs(playersInSector(root.CFrame, 6, 40, 6 * def.Scale)) do
			if not seen[pl] and damagePlayer(pl, def.ChargeDamage, root.Position, "Large") then
				seen[pl] = true
			end
		end
		if now() - lastDust > 0.1 then
			lastDust = now()
			dustCloud(root.Position - Vector3.new(0, 3 * def.Scale - 0.4, 0), 1.2, 2)
		end
		task.wait()
	end
	hum.WalkSpeed = def.Speed
	hum:MoveTo(root.Position)
	setTrail(e, false)
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
	if d > def.Close or math.random() < 0.15 then -- (now and then it charges from close too)
		ok, rest = brandCharge(e, tRoot), def.ChargeRecover
	else
		ok, rest = cinderfall(e, tRoot) and followThrust(e, tRoot), def.Recover -- (a slash into a thrust)
	end
	if ok then
		hold(e, rest) -- (recovery: your window to punish)
	end
	setTrail(e, false)
	if e.alive then
		pose(e, "Idle", 0.35)
	end
	hum.AutoRotate = true
	e.attacking = false
end

function M.init(core)
	pose, bodyPose, playSound, SOUNDS, now, faceTowards, setTrail, flat = core.pose, core.bodyPose, core.playSound, core.SOUNDS, core.now, core.faceTowards, core.setTrail, core.flat
	playersInSector, damagePlayer, burst, dustCloud, EnemiesFolder = core.playersInSector, core.damagePlayer, core.burst, core.dustCloud, core.EnemiesFolder
end

return M
