--!nonstrict
-- THE LOOKING-GLASS KNIGHT (kind MirrorGuard): the queen's own guard, in plate polished so bright it's forgotten what it looks like, behind a
-- tower-shield that's a whole dressing-mirror in a gold frame. Slim, patient, faceless: its visor's one more mirror, and what looks
-- back from it's you. It waits for you to swing.
--   Reflection  it plants the mirror and stands behind it, unbudgeable; hit it there, and the blade's answered from behind the glass
--   Glare       the mirror turned to the light: a flash, and a thin line of it flung at you
--   Shield Wall the frame driven forward in a shove, then a cut over the top
local K = require(script.Parent.Parent:WaitForChild("GildedKit"))
local M = K.wrap({
	Poses = {
		MGBGuard = { drop = 0.45, lean = 0.12, twist = 0.14, head = 0.05, spread = 0.2, footR = -0.45, footL = 0.5, breathe = 0.5, la1 = 1.1, la2 = 0.4, la3 = -0.1, lel = 1.5, freeL = 0 },
		MGBPlant = { drop = 0.9, lean = 0.2, twist = 0.1, head = 0.1, spread = 0.3, footR = -0.8, footL = 0.85, la1 = 1.05, la2 = 0.45, la3 = -0.1, lel = 1.5, freeL = 0 },
	},
	Grips = { MGLow = { Vector3.new(1.15, 0.1, -0.5), CFrame.Angles(math.rad(70), 0, 0) } },
})
M.Kind = "MirrorGuard"
M.Proportions = { girth = 0.98, arm = 1.05, hunch = 0 }
M.IdlePose = "MGBGuard"
M.BodyFor = { MGLow = "MGBGuard" }
local PLATE, PLATE_DK, GLASS = Color3.fromRGB(216, 222, 230), Color3.fromRGB(150, 156, 170), Color3.fromRGB(224, 236, 244)
M.Colors = { skin = PLATE_DK, torso = PLATE, legs = PLATE_DK, arms = PLATE }
local function mirror(p)
	p.Reflectance = 0.65
	return p
end

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	-- THE HELM: tall and slim, and in its front a single oval mirror where a face would be
	deco("Head", "Helm", V(1.24, 1.4, 1.28), at(0, 0.08, 0.02), PLATE, MAT.Metal).Reflectance = 0.2
	deco("Head", "HelmCrest", V(0.1, 0.8, 1.3), at(0, 0.88, 0.02), K.GOLD, MAT.Metal)
	mirror(deco("Head", "FaceGlass", V(0.05, 0.98, 0.72), at(0, 0.05, -0.66) * K.FACE, GLASS, MAT.Glass, Enum.PartType.Cylinder))
	deco("Head", "FaceFrame", V(0.04, 1.08, 0.82), at(0, 0.05, -0.64) * K.FACE, K.GOLD, MAT.Metal, Enum.PartType.Cylinder)
	-- the cuirass, its plates each their own small mirror
	deco("Chest", "Cuirass", V(cw * 1.04, ch * 0.96, cd * 1.1), at(0, 0.02, 0), PLATE, MAT.Metal).Reflectance = 0.15
	for ix = -1, 1 do
		for iy = 0, 2 do
			mirror(deco("Chest", "Pane", V(cw * 0.26, ch * 0.24, 0.05), at(ix * cw * 0.3, ch * (0.28 - iy * 0.28), -cd * 0.58), GLASS, MAT.Glass))
			deco("Chest", "Leading", V(cw * 0.3, 0.04, 0.05), at(ix * cw * 0.3, ch * (0.14 - iy * 0.28), -cd * 0.57), K.GOLD, MAT.Metal)
		end
	end
	deco("Chest", "Gorget", V(cw * 0.6, 0.32, cd * 1.15), at(0, ch * 0.5, 0), K.GOLD, MAT.Metal)
	deco("Hips", "Fauld", V(hw * 1.2, 0.85, hd * 1.2), at(0, -0.12, 0), PLATE_DK, MAT.Metal)
	for i = 0, 3 do
		deco("Hips", "Tasset", V(hw * 0.4, 1.1, 0.08), at((i - 1.5) * hw * 0.42, -0.95, -hd * 0.6), PLATE, MAT.Metal).Reflectance = 0.2
	end
	deco("Hips", "Belt", V(hw * 1.26, 0.18, hd * 1.28), at(0, 0.3, 0), K.GOLD, MAT.Metal)
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		deco(n .. "UpperArm", "Pauldron", V(aw * 1.8, 0.48, aw * 1.7), at(sx * 0.08, ua / 2 - 0.08, 0) * CFrame.Angles(0, 0, -sx * 0.28), PLATE, MAT.Metal).Reflectance = 0.2
		deco(n .. "UpperArm", "PauldronTrim", V(aw * 1.85, 0.07, aw * 1.75), at(sx * 0.08, ua / 2 - 0.3, 0) * CFrame.Angles(0, 0, -sx * 0.28), K.GOLD, MAT.Metal)
		deco(n .. "LowerArm", "Vambrace", V(aw * 1.18, la * 0.75, aw * 1.18), at(0, -0.05, 0), PLATE, MAT.Metal).Reflectance = 0.15
		deco(n .. "Thigh", "Cuisse", V(lw * 1.15, 0.9, lw * 1.15), at(0, 0.05, 0), PLATE, MAT.Metal)
		deco(n .. "Shin", "Greave", V(lw * 1.12, 0.85, lw * 1.12), at(0, -0.08, 0), PLATE, MAT.Metal).Reflectance = 0.15
		deco(n .. "Shin", "Knee", V(lw * 1.22, 0.3, lw * 1.25), at(0, 0.5, -0.05), K.GOLD, MAT.Metal)
		deco(n .. "Foot", "Sabaton", V(0.66, 0.26, 1.12), at(0, 0.02, -0.05), PLATE_DK, MAT.Metal)
	end
	-- THE MIRROR on its left arm: a tall oval glass in a gold frame, a little cherub at its crown (it covers it knee to chin)
	local F = at(-0.06, -0.15, -0.55) * CFrame.Angles(0, 0, 0)
	mirror(deco("LLowerArm", "ShieldGlass", V(2.5, 4.6, 0.1), F, GLASS, MAT.Glass))
	deco("LLowerArm", "ShieldBack", V(2.64, 4.74, 0.14), F * CFrame.new(0, 0, 0.1), K.TARNISH, MAT.Metal)
	deco("LLowerArm", "ShieldCrown", V(1.5, 0.34, 0.2), F * CFrame.new(0, 2.3, -0.02), K.GOLD, MAT.Metal)
	deco("LLowerArm", "ShieldFoot", V(1.1, 0.3, 0.2), F * CFrame.new(0, -2.3, -0.02), K.GOLD, MAT.Metal)
	deco("LLowerArm", "ShieldBoss", V(0.42, 0.42, 0.2), F * CFrame.new(0, 2.56, -0.02), K.LIGHT, MAT.Metal, Enum.PartType.Ball)
	for _, sx in ipairs({ -1, 1 }) do
		deco("LLowerArm", "ShieldSide", V(0.18, 2.4, 0.2), F * CFrame.new(sx * 1.24, 0, -0.02), K.GOLD, MAT.Metal)
	end
end

M.Weapons = {
	-- a long clean sword with a gold ribbon of a guard
	GlassSword = function(w)
		local handle = w.mk("Grip", Vector3.new(0.22, 1, 0.22), K.INK, Enum.Material.Leather)
		w.add(w.mk("Guard", Vector3.new(1.5, 0.16, 0.24), K.GOLD, Enum.Material.Metal), -0.55)
		local blade = w.mk("Blade", Vector3.new(0.36, 4.3, 0.09), PLATE, Enum.Material.Metal)
		blade.Reflectance = 0.3
		w.add(blade, -2.85)
		w.add(w.mk("Fuller", Vector3.new(0.08, 3.8, 0.1), K.GOLD, Enum.Material.Metal), -2.7)
		w.add(w.mk("Pommel", Vector3.new(0.26, 0.26, 0.26), K.GOLD, Enum.Material.Metal), 0.58)
		return { handle = handle, bladeLen = 5 }
	end,
}

M.Def = K.def({
	HP = 500, Speed = 9, Scale = 1.3, Damage = 38, Range = 9, HalfAngle = 55, Lunge = 8, Poise = 85, Stagger = 0.4, StaggerPush = 6,
	Windup = 0.75, Recover = 1, Engage = 20, Close = 9, Weapon = "GlassSword", IdleGrip = "MGLow", Radius = 1.7, Skin = PLATE, Cloth = PLATE_DK,
})

-- REFLECTION: planted. Anything that lands on it in that time is paid back as a cut, at once. Nothing gets paid back if you wait it out
local function reflection(e, tRoot)
	K.setBody(e, "MGBPlant", 0.25)
	K.setGrip(e, "GDraw", 0.3)
	K.sound(e, "Unsheath", 0.35, 1.3)
	local hum = e.hum
	local hp0, t0 = hum.Health, os.clock()
	e.def = table.clone(e.def)
	e.def.HyperArmor = true
	local answered = false
	while os.clock() - t0 < 1.8 do
		task.wait()
		if not e.alive then
			return false
		end
		if tRoot.Parent then
			K.face(e, tRoot.Position)
		end
		if hum.Health < hp0 - 0.5 then
			answered = true
			break
		end
	end
	e.def.HyperArmor = false
	if not answered then
		return true
	end
	K.flash(e.root.Position + Vector3.new(0, 2, 0), GLASS, 7)
	return K.strike(e, tRoot, { set = "GDraw", tell = 0.08, swing = "GThrust", swingBody = "GBLunge", time = 0.08, range = 9.5, half = 40, damage = 44, level = "Large", lunge = 1.8, speed = 1.2, quiet = true })
end
-- GLARE: the mirror turned up, then a line of light across the room
local function glare(e, tRoot)
	K.setBody(e, "GBCast", 0.4)
	K.sound(e, "Unsheath", 0.3, 2)
	if not K.hold(e, 0.75, tRoot) then
		return false
	end
	K.setBody(e, "MGBGuard", 0.12)
	local gl = K.partOf(e, "ShieldGlass")
	local from = (gl and gl.Position or e.root.Position) + e.root.CFrame.LookVector * 1.5
	K.flash(from, GLASS, 5)
	K.shot(e, {
		from = from, vel = K.aim(from, tRoot, 90, 0.05), damage = 28, level = "Medium", radius = 1.5, life = 0.7,
		size = Vector3.new(0.25, 0.25, 6), shape = Enum.PartType.Block, color = GLASS, material = Enum.Material.Neon, trail = GLASS,
	})
	K.sound(e, "WatchdogBlast", 0.5, 1.8)
	return true
end

M.attack = K.brain(function(e, tRoot, d)
	local roll = math.random()
	if d > e.def.Close then
		return glare(e, tRoot), 1
	elseif roll < 0.45 then
		return reflection(e, tRoot), 0.9
	end
	return K.combo(e, tRoot, {
		{ setBody = "MGBPlant", tell = 0.55, swingBody = "GBLunge", time = 0.14, range = 6.5, half = 70, damage = 22, level = "Medium", lunge = 2.2, speed = 0.6 },
		{ set = "GCock", setBody = "GBSet", tell = 0.28, swing = "GCut", swingBody = "GBStrike", time = 0.13, range = 9, half = 55, damage = 38, speed = 1, quiet = true },
	}), 1
end)

return M
