--!nonstrict
-- THE HERALD (kind Herald): tall, chest out, announcing guests to a hall with no one in it. A quartered tabard, a long gilded trumpet with
-- a banner hung from it. Where its face should be there's only a brass bell-mouth, and it never stops breathing in.
--   Fanfare     the trumpet lifted, a long indrawn breath, and a blast of sound down the room: you're flung back and flattened.
--               Stand off the line of the bell, or roll it
--   All Rise    aimed at the sky: the sound shakes dust off the walls and everyone close is thrown off their feet
--   Baton       it'll use the thing as a club, if you get in under it
local K = require(script.Parent.Parent:WaitForChild("GildedKit"))
local M = K.wrap({
	Poses = { HRBProud = { drop = 0, lean = -0.12, head = -0.15, footR = -0.12, footL = 0.14, spread = 0.1, breathe = 1.1, la1 = 0.1, la3 = -0.1, lel = 1.2, freeL = 0 } },
	Grips = {
		HRRest = { Vector3.new(1.2, 0.1, -0.9), CFrame.Angles(math.rad(145), 0, 0) },
		HRBlow = { Vector3.new(0.3, 1.9, -1.1), CFrame.Angles(math.rad(95), 0, 0) },
		HRSky = { Vector3.new(0.1, 2.5, -0.6), CFrame.Angles(math.rad(155), 0, 0) },
	},
})
M.Kind = "Herald"
M.Proportions = { girth = 1.0, arm = 1.05, hunch = 0 }
M.IdlePose = "HRBProud"
M.BodyFor = { HRRest = "HRBProud" }
local QUART_A, QUART_B, HOSE = K.RUG, K.LAPIS, Color3.fromRGB(226, 222, 206)
M.Colors = { skin = K.GOLD, torso = QUART_A, legs = HOSE, arms = QUART_B }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local cyl = Enum.PartType.Cylinder
	-- no face: a bell of brass opening out of its collar, a dark throat in it; a feathered bicorne on top
	parts.Head.Transparency = 1
	for i = 0, 4 do
		local d = 0.72 + i * 0.22
		deco("Head", "Bell", V(0.22, d, d), at(0, -0.02, 0.14 - i * 0.2) * K.FACE, K.GOLD, MAT.Metal, cyl)
	end
	deco("Head", "BellLip", V(0.1, 1.72, 1.72), at(0, -0.02, -0.78) * K.FACE, K.LIGHT, MAT.Metal, cyl)
	deco("Head", "Throat", V(0.05, 1.3, 1.3), at(0, -0.02, -0.72) * K.FACE, K.INK, MAT.SmoothPlastic, cyl)
	deco("Head", "ThroatGlow", V(0.05, 0.36, 0.36), at(0, -0.02, -0.75) * K.FACE, K.LIGHT, MAT.Neon, cyl)
	deco("Head", "Bicorne", V(2.1, 0.55, 0.68), at(0, 0.85, 0.1), K.INK, MAT.Fabric)
	deco("Head", "BicorneEdge", V(2.14, 0.1, 0.72), at(0, 0.62, 0.1), K.GOLD, MAT.Metal)
	for i = 0, 3 do
		deco("Head", "Feather", V(0.14, 0.7, 0.32), at(-0.5, 1.18 + i * 0.3, 0.1 + i * i * 0.06) * CFrame.Angles(-0.2 - i * 0.22, 0, 0.1), K.PORCELAIN, MAT.Fabric)
	end
	-- the quartered tabard: red and blue, gold lions' faces, a heavy gold collar of office
	deco("Chest", "Under", V(cw * 1.02, ch * 0.98, cd * 1.05), at(0, 0, 0), HOSE, MAT.Fabric)
	for _, q in ipairs({ { -1, 1, QUART_A }, { 1, 1, QUART_B }, { -1, -1, QUART_B }, { 1, -1, QUART_A } }) do
		deco("Chest", "Quarter", V(cw * 0.42, ch * 0.46, 0.06), at(q[1] * cw * 0.21, q[2] * ch * 0.23, -cd * 0.57), q[3], MAT.Fabric)
		deco("Chest", "Quarter", V(cw * 0.42, ch * 0.46, 0.06), at(q[1] * cw * 0.21, q[2] * ch * 0.23, cd * 0.57), q[3], MAT.Fabric)
		deco("Chest", "Charge", V(0.05, 0.38, 0.38), at(q[1] * cw * 0.21, q[2] * ch * 0.23, -cd * 0.61) * K.FACE, K.GOLD, MAT.Metal, cyl)
	end
	for i = 0, 1 do
		local c = i == 0 and QUART_B or QUART_A
		deco("Hips", "TabardFall", V(hw * 0.5, 1.8, 0.06), at((i * 2 - 1) * hw * 0.25, -0.75, -hd * 0.58), c, MAT.Fabric)
		deco("Hips", "TabardFall", V(hw * 0.5, 1.8, 0.06), at((i * 2 - 1) * hw * 0.25, -0.75, hd * 0.58), c, MAT.Fabric)
	end
	deco("Chest", "Collar", V(cw * 0.72, 0.28, cd * 1.3), at(0, ch * 0.47, 0), K.GOLD, MAT.Metal)
	for i = -2, 2 do
		deco("Chest", "CollarLink", V(0.2, 0.2, 0.08), at(i * 0.24, ch * 0.38 - math.abs(i) * -0.05, -cd * 0.66), K.LIGHT, MAT.Metal, Enum.PartType.Ball)
	end
	deco("Hips", "Belt", V(hw * 1.2, 0.22, hd * 1.24), at(0, 0.3, 0), K.GOLD, MAT.Metal)
	-- a roll of proclamations under its arm, and hanging at its hip, sealed in wax
	deco("Hips", "Scroll", V(1.35, 0.34, 0.34), at(-hw * 0.7, -0.35, 0.05) * K.UP, K.PORCELAIN, MAT.Fabric, cyl)
	deco("Hips", "Seal", V(0.26, 0.26, 0.08), at(-hw * 0.7, -0.95, -0.2), K.RUG, MAT.SmoothPlastic, Enum.PartType.Ball)
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		deco(n .. "UpperArm", "Puff", V(aw * 1.55, ua * 0.6, aw * 1.55), at(0, ua * 0.18, 0), sx > 0 and QUART_A or QUART_B, MAT.Fabric, Enum.PartType.Ball)
		deco(n .. "LowerArm", "Cuff", V(aw * 1.3, 0.5, aw * 1.3), at(0, -la * 0.3, 0), K.GOLD, MAT.Fabric)
		deco(n .. "Thigh", "Trunk", V(lw * 1.35, 0.85, lw * 1.35), at(0, 0.18, 0), sx > 0 and QUART_B or QUART_A, MAT.Fabric, Enum.PartType.Ball)
		deco(n .. "Foot", "Boot", V(0.6, 0.28, 1.15), at(0, 0.02, -0.06), K.INK, MAT.Leather)
		deco(n .. "Shin", "BootTop", V(lw * 1.14, 0.32, lw * 1.14), at(0, -0.3, 0), K.INK, MAT.Leather)
	end
end

M.Weapons = {
	-- a long straight trumpet, its bell wide, a square banner hung from its middle
	LongTrumpet = function(w)
		local gold = K.GOLD
		local handle = w.mk("Grip", Vector3.new(0.18, 0.8, 0.18), gold, Enum.Material.Metal)
		w.add(w.mk("Tube", Vector3.new(0.17, 5, 0.17), gold, Enum.Material.Metal), -2.6)
		w.add(w.mk("Knop", Vector3.new(0.34, 0.26, 0.34), K.LIGHT, Enum.Material.Metal), -1.2)
		w.add(w.mk("Knop", Vector3.new(0.34, 0.26, 0.34), K.LIGHT, Enum.Material.Metal), -3.2)
		for i = 0, 3 do
			local d = 0.42 + i * 0.26
			local b = w.mk("TrumpetBell", Vector3.new(0.3, d, d), gold, Enum.Material.Metal)
			b.Shape = Enum.PartType.Cylinder
			w.add(b, -5.1 - i * 0.28, CFrame.Angles(0, 0, math.pi / 2))
		end
		w.add(w.mk("Banner", Vector3.new(0.05, 1.8, 1.5), QUART_A, Enum.Material.Fabric), -2.6, nil, 0.85)
		w.add(w.mk("BannerSun", Vector3.new(0.07, 0.8, 0.8), gold, Enum.Material.Metal), -2.6, nil, 0.85)
		w.add(w.mk("BannerFringe", Vector3.new(0.07, 1.84, 0.1), gold, Enum.Material.Metal), -2.6, nil, 1.62)
		return { handle = handle, bladeLen = 6 }
	end,
}

M.Def = K.def({
	HP = 400, Speed = 9.5, Scale = 1.3, Damage = 36, Range = 8.5, HalfAngle = 60, Lunge = 7, Poise = 60, Stagger = 0.5, StaggerPush = 10,
	Windup = 0.8, Recover = 1, Engage = 22, Close = 7, Weapon = "LongTrumpet", IdleGrip = "HRRest", Radius = 1.5, Skin = K.GOLD, Cloth = QUART_A,
})

-- FANFARE: drawn breath, and then a blast down a long narrow line that flings you
local function fanfare(e, tRoot)
	local def, root = e.def, e.root
	K.setGrip(e, "HRBlow", 0.5)
	K.setBody(e, "GBDraught", 0.9)
	K.sound(e, "Unsheath", 0.35, 0.3)
	if not K.hold(e, 1.05, tRoot) then
		return false
	end
	K.setBody(e, "GBBlow", 0.1)
	K.sound(e, "WatchdogBlast", 0.95, 0.75)
	K.shake(root.Position, 0.4)
	local bell = K.partOf(e, "TrumpetBell")
	if bell then
		local dir = (root.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
		for i = 1, 3 do
			K.shot(e, {
				from = bell.Position, vel = dir * 70, visual = true, life = 0.42, color = K.LIGHT, material = Enum.Material.Neon,
				size = Vector3.new(0.16, 2 + i * 1.3, 2 + i * 1.3), shape = Enum.PartType.Cylinder,
				make = function(p)
					p.Transparency = 0.45 + i * 0.1
				end,
			})
			task.wait(0.05)
		end
	end
	for _, pl in ipairs(K.line(root.CFrame, 26, 6, 6 * def.Scale)) do
		K.hurt(pl, 34, root.Position, "Knockdown", 42)
	end
	return K.hold(e, 0.5)
end
local function allRise(e, tRoot)
	K.setGrip(e, "HRSky", 0.5)
	K.setBody(e, "GBCast", 0.5)
	if not K.hold(e, 0.85, tRoot) then
		return false
	end
	local at = K.feet(e)
	K.sound(e, "WatchdogBlast", 0.9, 1.05)
	K.flash(e.root.Position + Vector3.new(0, 4, 0), K.LIGHT, 8)
	K.shake(at, 0.6)
	K.area(at, 12, 6, 28, "Knockdown")
	return true
end

M.attack = K.brain(function(e, tRoot, d)
	if d > e.def.Close then
		return fanfare(e, tRoot), 1.2
	elseif math.random() < 0.5 then
		return allRise(e, tRoot), 1.2
	end
	return K.strike(e, tRoot, { set = "GCock", setBody = "GBSet", tell = 0.65, swing = "GCut", swingBody = "GBStrike", time = 0.16, range = 9, half = 65, damage = 36, speed = 1 }), 0.9
end)

return M
