--!nonstrict
-- HOLLOW: a withered prisoner, weathered to leather, with a rusted blade.
-- Slow, simple: one windup and one strike, but any hit staggers it.
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
M.Kind = "Hollow"
M.Proportions = { girth = 0.74, arm = 1.08, hunch = 0.24 } -- wasted, but still fleshier than a skeleton (0.62)
M.Colors = { skin = Color3.fromRGB(118, 108, 90), torso = Color3.fromRGB(118, 108, 90), legs = Color3.fromRGB(110, 100, 84), arms = Color3.fromRGB(118, 108, 90) }
M.FistSkin = true

function M.Look(k)
	local deco, parts, V, at, rgb, MAT, s, look = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT, k.s, k.look
	local cw, ch, cd, hw, hd, aw, lw, la = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la
	-- withered, half-naked prisoner, weathered to leather: blotched, grainy skin
	-- stretched over the ribs, sunken sockets, sores, filthy torn rags, old
	-- bandages, and on some a shackle they never got out of. Every one differs.
	local rnd = Random.new()
	local skin = look.skin
	local rag = rgb(70, 60, 48):Lerp(rgb(48, 42, 34), rnd:NextNumber() * 0.6)
	local grime, sore, bandage = rgb(52, 46, 38), rgb(74, 40, 34), rgb(122, 112, 90)
	for _, pn in ipairs({ "Head", "Chest", "RUpperArm", "LUpperArm", "RLowerArm", "LLowerArm", "RThigh", "LThigh", "RShin", "LShin" }) do
		local tint = rnd:NextNumber() < 0.5 and rgb(84, 80, 62) or rgb(118, 104, 86)
		parts[pn].Color = skin:Lerp(tint, rnd:NextNumber(0.05, 0.35))
		parts[pn].Material = MAT.Sand -- dry, grainy skin
	end
	parts.RFoot.Color, parts.LFoot.Color = rgb(44, 38, 32), rgb(44, 38, 32)
	parts.RFoot.Material, parts.LFoot.Material = MAT.Sand, MAT.Sand
	-- grime and blotches smeared over the body
	local function blotch(on, w, h, x, y, z, color)
		deco(on, "Grime", V(w, h, 0.03), at(x, y, z) * CFrame.Angles(0, 0, rnd:NextNumber(-0.6, 0.6)), color, MAT.Sand)
	end
	for _ = 1, 4 do
		blotch("Chest", rnd:NextNumber(0.3, 0.8), rnd:NextNumber(0.2, 0.6), rnd:NextNumber(-cw * 0.35, cw * 0.35), rnd:NextNumber(-0.6, 0.6), -cd / 2 - 0.015, grime)
	end
	for _ = 1, 2 do
		blotch("Chest", rnd:NextNumber(0.3, 0.7), rnd:NextNumber(0.2, 0.5), rnd:NextNumber(-cw * 0.35, cw * 0.35), rnd:NextNumber(-0.6, 0.6), cd / 2 + 0.015, grime)
	end
	-- sores
	for _ = 1, rnd:NextInteger(2, 4) do
		local on = ({ "Chest", "RUpperArm", "LUpperArm", "RThigh", "LThigh" })[rnd:NextInteger(1, 5)]
		local p = parts[on]
		deco(on, "Sore", V(0.16, 0.14, 0.03), at(rnd:NextNumber(-0.15, 0.15), rnd:NextNumber(-0.35, 0.35) * p.Size.Y / s, -p.Size.Z / s / 2 - 0.012), sore, MAT.SmoothPlastic)
	end
	-- ribs standing out like bare bone, the shadows between them
	local bone = rgb(170, 158, 132)
	for i = 0, 3 do
		local y = 0.42 - i * 0.24
		deco("Chest", "Rib", V(cw * 0.44, 0.1, 0.06), at(-cw * 0.2, y, -cd / 2 - 0.03) * CFrame.Angles(0, 0, -0.12), skin:Lerp(bone, 0.7), MAT.Sand)
		deco("Chest", "Rib", V(cw * 0.44, 0.1, 0.06), at(cw * 0.2, y, -cd / 2 - 0.03) * CFrame.Angles(0, 0, 0.12), skin:Lerp(bone, 0.7), MAT.Sand)
		deco("Chest", "RibShadow", V(cw * 0.8, 0.08, 0.03), at(0, y - 0.12, -cd / 2 - 0.015), skin:Lerp(rgb(0, 0, 0), 0.6), MAT.Sand)
	end
	deco("Chest", "Sternum", V(0.12, 0.85, 0.05), at(0, 0.1, -cd / 2 - 0.035), skin:Lerp(bone, 0.6), MAT.Sand)
	-- where the leather has split: bone showing at the knuckled joints (elbows, knees)
	for _, pn in ipairs({ "RLowerArm", "LLowerArm", "RShin", "LShin" }) do
		if rnd:NextNumber() < 0.6 then
			local p = parts[pn]
			local y = p.Size.Y / s / 2 - 0.12
			deco(pn, "SplitSkin", V(0.3, 0.26, 0.03), at(0, y, -p.Size.Z / s / 2 - 0.012), skin:Lerp(rgb(0, 0, 0), 0.55), MAT.Sand)
			deco(pn, "BareBone", V(0.2, 0.18, 0.05), at(0, y, -p.Size.Z / s / 2 - 0.03), bone, MAT.Sand)
		end
	end
	-- a knobbled spine and jutting shoulder blades behind
	for i = 0, 4 do
		deco("Chest", "Vertebra", V(0.14, 0.1, 0.06), at(0, 0.6 - i * 0.3, cd / 2 + 0.03), skin:Lerp(rgb(140, 128, 108), 0.35), MAT.Sand)
	end
	for _, sx in ipairs({ -1, 1 }) do
		deco("Chest", "Blade", V(0.45, 0.5, 0.05), at(sx * cw * 0.25, 0.35, cd / 2 + 0.025) * CFrame.Angles(0, 0, sx * 0.25), skin:Lerp(rgb(140, 128, 108), 0.2), MAT.Sand)
	end
	-- loincloth with ragged strips, a frayed rope belt
	deco("Hips", "Loincloth", V(hw * 0.7, 0.95, 0.08), at(0, -0.55, -hd / 2 - 0.05), rag, MAT.Fabric)
	deco("Hips", "LoinclothB", V(hw * 0.75, 0.8, 0.08), at(0.05, -0.5, hd / 2 + 0.05), rag:Lerp(rgb(0, 0, 0), 0.15), MAT.Fabric)
	for i = 0, 2 do
		local l = rnd:NextNumber(0.3, 0.7)
		deco("Hips", "RagStrip", V(hw * 0.18, l, 0.07), at(-hw * 0.24 + i * hw * 0.24, -1.02 - l / 2, -hd / 2 - 0.05) * CFrame.Angles(0, 0, rnd:NextNumber(-0.2, 0.2)), rag:Lerp(rgb(0, 0, 0), rnd:NextNumber(0, 0.3)), MAT.Fabric)
	end
	deco("Hips", "Rope", V(hw + 0.08, 0.14, hd + 0.08), at(0, 0.25, 0), rgb(96, 84, 52), MAT.Fabric)
	deco("Hips", "RopeEnd", V(0.08, 0.5, 0.08), at(hw * 0.3, 0.0, -hd / 2 - 0.08) * CFrame.Angles(0, 0, 0.3), rgb(96, 84, 52), MAT.Fabric)
	-- what's left of a shirt, hanging off one shoulder, holed
	if rnd:NextNumber() < 0.75 then
		local sx = rnd:NextNumber() < 0.5 and -1 or 1
		deco("Chest", "RagShirt", V(cw * 0.55, ch * 0.62, cd + 0.06), at(sx * cw * 0.2, -0.25, 0) * CFrame.Angles(0, 0, sx * 0.08), rag, MAT.Fabric)
		deco("Chest", "RagStrap", V(0.22, ch * 0.5, cd + 0.08), at(sx * cw * 0.32, 0.45, 0) * CFrame.Angles(0, 0, -sx * 0.3), rag, MAT.Fabric)
		for _ = 1, 2 do
			deco("Chest", "Hole", V(0.18, 0.14, 0.02), at(sx * cw * rnd:NextNumber(0.05, 0.4), rnd:NextNumber(-0.6, 0.1), -cd / 2 - 0.045), skin:Lerp(rgb(0, 0, 0), 0.3), MAT.Sand)
		end
	end
	-- old bandages on a forearm and a shin
	local arm = rnd:NextNumber() < 0.5 and "R" or "L"
	for i = 0, 2 do
		deco(arm .. "LowerArm", "Bandage", V(aw * 0.98, 0.16, aw * 0.98), at(0, la * 0.25 - i * 0.22, 0) * CFrame.Angles(0, 0, (i % 2 == 0) and 0.18 or -0.12), bandage:Lerp(grime, rnd:NextNumber(0.1, 0.5)), MAT.Fabric)
	end
	local leg = rnd:NextNumber() < 0.5 and "R" or "L"
	for i = 0, 1 do
		deco(leg .. "Shin", "Bandage", V(lw * 0.97, 0.18, lw * 0.97), at(0, 0.1 - i * 0.24, 0) * CFrame.Angles(0, 0, (i % 2 == 0) and -0.15 or 0.1), bandage:Lerp(grime, rnd:NextNumber(0.2, 0.6)), MAT.Fabric)
	end
	-- a shackle they never got out of, a few links still hanging from it
	if rnd:NextNumber() < 0.55 then
		local wrist = arm == "R" and "L" or "R"
		deco(wrist .. "LowerArm", "Shackle", V(aw * 1.05, 0.22, aw * 1.05), at(0, -la / 2 + 0.25, 0), rgb(58, 50, 44), MAT.CorrodedMetal)
		for i = 0, 2 do
			deco(wrist .. "LowerArm", "Link", V(0.07, 0.22, 0.14), at(aw * 0.5, -la / 2 + 0.1 - i * 0.2, 0) * CFrame.Angles(0, (i % 2) * math.pi / 2, 0), rgb(70, 52, 40), MAT.CorrodedMetal)
		end
	end
	-- face: heavy brow, sunken sockets, cheekbones, a slack mouth
	deco("Head", "Brow", V(1.0, 0.18, 0.12), at(0, 0.22, -0.56), skin:Lerp(rgb(0, 0, 0), 0.25), MAT.Sand)
	for _, x in ipairs({ -0.22, 0.22 }) do
		deco("Head", "Socket", V(0.36, 0.32, 0.03), at(x, 0.1, -0.578), skin:Lerp(rgb(0, 0, 0), 0.75), MAT.Sand)
		deco("Head", "Cheekbone", V(0.3, 0.1, 0.06), at(x * 1.1, -0.1, -0.58), skin:Lerp(bone, 0.6), MAT.Sand)
	end
	-- the nose rotted back to a hole, the lips drawn off the teeth
	deco("Head", "NoseHole", V(0.14, 0.16, 0.03), at(0, -0.1, -0.578), rgb(20, 14, 12), MAT.SmoothPlastic)
	deco("Head", "Mouth", V(0.48, 0.16, 0.04), at(0, -0.33, -0.585), rgb(20, 14, 12), MAT.SmoothPlastic)
	for i = -2, 2 do
		deco("Head", "Tooth", V(0.07, 0.1, 0.03), at(i * 0.085, -0.31, -0.6), rgb(150, 136, 104), MAT.SmoothPlastic)
	end
	-- eyes: direct children named "Eye"
	for _, x in ipairs({ -0.22, 0.22 }) do
		deco("Head", "Eye", V(0.2, 0.16, 0.05), at(x, 0.12, -0.585), rgb(8, 6, 6), MAT.SmoothPlastic)
	end
end

M.Weapons = {
	Rusted = function(w)
		local handle = w.mk("Grip", Vector3.new(0.22, 0.9, 0.22), w.wood, Enum.Material.Wood)
		w.add(w.mk("Blade", Vector3.new(0.3, 2.4, 0.1), Color3.fromRGB(92, 62, 44), Enum.Material.CorrodedMetal), -1.6)
		return { handle = handle, bladeLen = 2.8 }
	end,
}

-- stats (the shared brain in GameServer/Enemies.lua reads these)
M.Def = {
	HP = 60, Speed = 10, Scale = 1, Damage = 20, Range = 5.5, HalfAngle = 55,
	Windup = 0.7, Recover = 0.9, Aggro = 30, Leash = 55, Stagger = 0.5,
	HyperArmor = false, Weapon = "Rusted", Radius = 1.2, Lunge = 14,
	Poise = 1, HitLevel = "Medium", -- any hit staggers a hollow
	Skin = Color3.fromRGB(118, 108, 90), Cloth = Color3.fromRGB(58, 50, 42),
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
