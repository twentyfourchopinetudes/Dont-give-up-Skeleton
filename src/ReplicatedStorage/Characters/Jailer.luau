--!nonstrict
-- JAILER: the hooded jailer in an iron mask. Big, slow, a cleaver, hyper-armor mid-swing.
-- Guards the fog in the yard. Don't trade hits with it.
--
-- EVERYTHING ABOUT THIS CHARACTER IS IN THIS ONE FILE:
--   M.Proportions / M.Poses   body shape and its full-body poses (the client animator uses these too)
--   M.Colors / M.Look         how the rig is dressed (RigBuilder calls Look with a kit of helpers:
--                             deco(part, name, size, offset, color, material?, shape?), V(x,y,z), at(x,y,z) ...)
--   M.Weapons / M.Grips       the weapon's model, and the grip poses its swings tween between
--   M.init(Core) and below    behaviour (server only)
-- SHARED TOOLKIT: server code here gets the shared helpers through M.init(Core)
-- (see the list at the top of ServerScriptService/GameServer/Core.lua). Body
-- poses not defined here (Idle, Windup, Strike, SweepWindup, SweepEnd, Recover,
-- Flinch, Stagger, Crouch, Air, Roar, Kneel) are shared ones from PuppetMath.
local M = {}
M.Kind = "Jailer"
M.Proportions = { girth = 1.25, arm = 1.1, hunch = 0.3, twoHand = 0.45 }
M.Colors = { skin = Color3.fromRGB(84, 78, 70), torso = Color3.fromRGB(54, 46, 38), legs = Color3.fromRGB(44, 38, 32), arms = Color3.fromRGB(84, 78, 70) }
M.FistSkin = false

function M.Look(k)
	local deco, V, at, rgb, MAT = k.deco, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la
	-- hooded jailer in a faceted iron mask, everything he wears gone to rags; built from many
	-- small pieces so nothing reads as one slab. rng keeps him the same every time.
	local rng = Random.new(23)
	local hood, hem, apron, iron, ironDark, leather = rgb(30, 26, 24), rgb(16, 14, 13), rgb(58, 44, 32), rgb(70, 66, 60), rgb(40, 38, 35), rgb(36, 28, 22)
	local function rag()
		return hood:Lerp(hem, rng:NextNumber(0, 0.5))
	end
	-- the cowl: rings of narrow cloth strips round the head, leaning in to a peak, the front open.
	-- Angles(0, a, 0) turns a strip's +Z outward; tipping it about X by -t pulls its top in.
	for _, ring in ipairs({ { y = 0.0, r = 0.68, n = 16, tip = -0.12, open = 2.25, h = 1.35 }, { y = 0.62, r = 0.5, n = 12, tip = -0.6, h = 0.55 }, { y = 0.9, r = 0.24, n = 7, tip = -1.0, h = 0.4 } }) do
		for i = 0, ring.n - 1 do
			local a = (i + 0.5) / ring.n * math.pi * 2
			if not ring.open or math.abs(a - math.pi) > math.pi - ring.open then
				local h = ring.h * rng:NextNumber(0.9, 1.15)
				local w = 2 * math.pi * ring.r / ring.n * 1.35
				deco("Head", "Hood", V(w, h, 0.1), at(math.sin(a) * ring.r, ring.y - (h - ring.h) / 2, math.cos(a) * ring.r) * CFrame.Angles(0, a, 0) * CFrame.Angles(ring.tip + rng:NextNumber(-0.06, 0.06), 0, rng:NextNumber(-0.05, 0.05)), rag(), MAT.Fabric)
			end
		end
	end
	-- the cowl's tail, drooping off the back of the peak
	local cf = at(0, 1.0, 0.2) * CFrame.Angles(-1.6, 0, 0) -- starts pointing straight back...
	for i = 1, 5 do
		cf = cf * CFrame.Angles(0.3, rng:NextNumber(-0.1, 0.1), 0) -- ...and sags a little more each piece
		deco("Head", "HoodTail", V(0.3 - i * 0.04, 0.32, 0.1), cf * at(0, -0.16, 0), rag(), MAT.Fabric)
		cf = cf * at(0, -0.3, 0)
	end
	-- the mask: a centre plate and two cheek plates swept back, a brow band, rivets, breathing holes
	deco("Head", "Mask", V(0.56, 1.0, 0.1), at(0, -0.02, -0.63), iron, MAT.Metal)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "MaskCheek", V(0.32, 0.92, 0.1), at(sx * 0.4, -0.04, -0.55) * CFrame.Angles(0, -sx * 0.45, 0), ironDark, MAT.Metal)
		for _, y in ipairs({ 0.36, -0.42 }) do
			deco("Head", "Rivet", V(0.07, 0.07, 0.04), at(sx * 0.21, y, -0.69), ironDark, MAT.Metal)
		end
	end
	deco("Head", "MaskBrow", V(0.62, 0.1, 0.06), at(0, 0.3, -0.69), ironDark, MAT.Metal)
	deco("Head", "MaskSlit", V(0.5, 0.08, 0.05), at(0, 0.16, -0.685), rgb(5, 5, 5), MAT.SmoothPlastic)
	for r = 0, 1 do
		for c = -1, 1 do
			deco("Head", "Breath", V(0.06, 0.06, 0.03), at(c * 0.12, -0.26 - r * 0.12, -0.685), rgb(5, 5, 5), MAT.SmoothPlastic)
		end
	end
	-- a ragged mantle round the shoulders
	local rx, rz = cw / 2 + 0.08, cd / 2 + 0.08
	local n = 14
	local w = 2 * math.pi * math.sqrt((rx * rx + rz * rz) / 2) / n * 1.4
	for i = 0, n - 1 do
		local a = (i + 0.5) / n * math.pi * 2
		local top = CFrame.new(math.sin(a) * rx, ch / 2 + 0.05, math.cos(a) * rz) * CFrame.Angles(0, a, 0) * CFrame.Angles(-0.3, 0, 0)
		k.tatter(rng, "Chest", top, w, rng:NextNumber(0.7, 1.3), rag(), hem, 0.8)
	end
	-- the leather apron in torn strips: a bib on the chest, a skirt off the belt
	local hemA = apron:Lerp(rgb(20, 14, 10), 0.6)
	for i = 1, 4 do
		local x = (-0.5 + (i - 0.5) / 4) * cw * 0.8
		k.tatter(rng, "Chest", CFrame.new(x, ch * 0.3, -cd / 2 - 0.06 - (i % 2) * 0.012), cw * 0.8 / 4 * 1.3, ch * 0.75, apron:Lerp(hemA, rng:NextNumber(0, 0.3)), hemA, 0.6)
		k.tatter(rng, "Hips", CFrame.new(x * hw / cw, 0.15, -hd / 2 - 0.06 - (i % 2) * 0.012), hw * 0.8 / 4 * 1.3, rng:NextNumber(1.0, 1.4), apron:Lerp(hemA, rng:NextNumber(0, 0.3)), hemA, 0.6)
	end
	-- belt of a few overlapping straps, keys on a ring, chain hanging off the other hip
	for i = 0, 2 do
		deco("Hips", "Belt", V(hw + 0.15 + i * 0.02, 0.12, hd + 0.15 + i * 0.02), at(0, 0.36 - i * 0.1, 0) * CFrame.Angles(0, 0, (i - 1) * 0.04), leather, MAT.Fabric)
	end
	deco("Hips", "Buckle", V(0.26, 0.24, 0.06), at(0, 0.27, -hd / 2 - 0.12), iron, MAT.Metal)
	deco("Hips", "KeyRing", V(0.08, 0.5, 0.5), at(hw / 2 + 0.05, 0.05, 0), iron, MAT.Metal, Enum.PartType.Cylinder)
	for i = 0, 2 do
		deco("Hips", "Key", V(0.06, 0.4, 0.12), at(hw / 2 + 0.1, -0.2 - i * 0.05, -0.1 + i * 0.1) * CFrame.Angles(0, 0, 0.2 * i), iron, MAT.Metal)
	end
	for i = 0, 5 do
		deco("Hips", "Chain", V(0.05, 0.2, 0.12), at(-hw / 2 - 0.08, 0.15 - i * 0.17, 0.1) * CFrame.Angles(0, (i % 2) * math.pi / 2, 0), ironDark, MAT.Metal)
	end
	-- arms and shins bound in leather wraps, each band a little askew
	for _, nm in ipairs({ "R", "L" }) do
		for i = 0, 3 do
			deco(nm .. "LowerArm", "Wrap", V(aw * 1.15, 0.16, aw * 1.15), at(0, -la / 2 + 0.15 + i * 0.17, 0) * CFrame.Angles(rng:NextNumber(-0.12, 0.12), 0, rng:NextNumber(-0.12, 0.12)), leather:Lerp(hem, rng:NextNumber(0, 0.4)), MAT.Fabric)
			deco(nm .. "Shin", "Wrap", V(lw * 1.12, 0.16, lw * 1.12), at(0, -0.3 + i * 0.2, 0) * CFrame.Angles(rng:NextNumber(-0.12, 0.12), 0, rng:NextNumber(-0.12, 0.12)), leather:Lerp(hem, rng:NextNumber(0, 0.4)), MAT.Fabric)
		end
	end
	-- eyes: direct children named "Eye"
	for _, x in ipairs({ -0.16, 0.16 }) do
		deco("Head", "Eye", V(0.18, 0.07, 0.05), at(x, 0.16, -0.69), rgb(120, 90, 50), MAT.Neon)
	end
end

M.Weapons = {
	Cleaver = function(w)
		local handle = w.mk("Grip", Vector3.new(0.28, 1.2, 0.28), w.wood, Enum.Material.Wood)
		-- wide along Z, hung off the spine toward +Z: his overhead chop (Raise -> Strike turns the
		-- grip about X) leads with +Z, so the edge comes down first, not the flat
		w.add(w.mk("Blade", Vector3.new(0.16, 3.2, 1.3), Color3.fromRGB(70, 60, 52), Enum.Material.CorrodedMetal), -2.2, nil, 0.45)
		return { handle = handle, bladeLen = 3.8 }
	end,
}

-- stats (the shared brain in GameServer/Enemies.lua reads these)
M.Def = {
	HP = 220, Speed = 8.5, Scale = 1.45, Damage = 36, Range = 7.5, HalfAngle = 60,
	Windup = 1.05, Recover = 1.2, Aggro = 34, Leash = 60, Stagger = 0.35,
	HyperArmor = true, Weapon = "Cleaver", Radius = 1.8, Lunge = 12,
	Poise = 45, HitLevel = "Large", -- ~4 lights or 2 heavies to stagger
	Skin = Color3.fromRGB(80, 76, 70), Cloth = Color3.fromRGB(35, 32, 30),
}

---------------------------------------------------------------------------
-- server: how it fights
---------------------------------------------------------------------------
local pose, playSound, SOUNDS, now, faceTowards, setTrail, flat, playersInSector, damagePlayer

function M.attack(e, targetChar)
	local def = e.def
	local hum, root = e.hum, e.root
	local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
	if not tRoot then
		return
	end
	e.attacking = true
	hum:MoveTo(root.Position)
	hum.AutoRotate = false
	pose(e, "Raise", def.Windup * 0.8)
	playSound(root, SOUNDS.Unsheath, 0.35, 0.6)

	local t0 = now()
	local interrupted = false
	while now() - t0 < def.Windup do
		if not e.alive or now() < e.staggerUntil then
			interrupted = true
			break
		end
		-- track the target during the first part of the windup, then commit
		if now() - t0 < def.Windup * 0.75 and tRoot.Parent then
			faceTowards(root, tRoot.Position)
		end
		task.wait()
	end

	if not interrupted then
		playSound(root, SOUNDS.Slash, 0.5, 0.7)
		setTrail(e, true)
		pose(e, "Mid", 0.06, Enum.EasingStyle.Linear)
		task.delay(0.06, function()
			pose(e, "Strike", 0.08)
		end)
		local v = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = flat(root.CFrame.LookVector) * def.Lunge + Vector3.new(0, v.Y, 0)
		task.wait(0.08)
		if e.alive then
			for _, pl in ipairs(playersInSector(root.CFrame, def.Range, def.HalfAngle, 6 * def.Scale)) do
				damagePlayer(pl, def.Damage, root.Position, def.HitLevel)
			end
		end
		setTrail(e, false)
		-- recovery: this is your window to punish
		local r0 = now()
		while now() - r0 < def.Recover and e.alive do
			task.wait()
		end
	end
	setTrail(e, false)
	if e.alive then
		pose(e, "Idle", 0.3)
	end
	hum.AutoRotate = true
	e.attacking = false
end

function M.init(core)
	pose, playSound, SOUNDS, now, faceTowards, setTrail, flat, playersInSector, damagePlayer = core.pose, core.playSound, core.SOUNDS, core.now, core.faceTowards, core.setTrail, core.flat, core.playersInSector, core.damagePlayer
end

return M
