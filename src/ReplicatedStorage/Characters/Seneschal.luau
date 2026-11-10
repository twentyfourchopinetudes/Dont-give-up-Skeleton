--!nonstrict
-- THE SENESCHAL (kind Seneschal): the steward of the palace, who runs the house, the staff, the seating, and your removal. Enormous and upright in
-- wine-dark velvet and a bishop's width of gold embroidery, a chain of office over a chest like a wardrobe, a long white beard combed flat.
-- It carries the rod of office: a mace of ceremony as tall as you are. Everything it does is slow and formal, and it never misses a step.
--   Decree       left, right, then straight down. Three blows, with a pause for effect between each
--   You May Not  the butt of the rod knocked once on the floor: a jolt runs out, you stagger, and it's already walking at you
--   Dismissed    a two-handed thrust at the chest that throws you across the room
--   Make Way     the rod drawn back, then swept right round it at knee height: getting behind it is no answer
local K = require(script.Parent.Parent:WaitForChild("GildedKit"))
local M = K.wrap({
	Poses = {
		SNBUpright = { drop = 0, lean = -0.08, head = -0.1, footR = -0.1, footL = 0.12, spread = 0.12, breathe = 0.5, la1 = 0.18, la3 = -0.15, lel = 1.2, freeL = 0 },
		SNBKnock = { drop = 0.2, lean = -0.05, head = 0.1, spread = 0.14, footR = -0.1, footL = 0.14, la1 = 0.18, la3 = -0.15, lel = 1.2, freeL = 0 },
	},
	Grips = {
		SNStaff = { Vector3.new(1.15, 0.3, -0.7), CFrame.Angles(math.rad(178), 0, math.rad(-2)) },
		SNKnockUp = { Vector3.new(1, 1.8, -1), CFrame.Angles(math.rad(180), 0, 0) },
		SNKnock = { Vector3.new(0.9, 0.3, -1.3), CFrame.Angles(math.rad(180), 0, 0) },
	},
})
M.Kind = "Seneschal"
M.Proportions = { girth = 1.3, arm = 1.08, hunch = 0, cadence = 0.42 }
M.IdlePose = "SNBUpright"
M.BodyFor = { SNStaff = "SNBUpright" }
local WINE, WINE_DK, BEARD = Color3.fromRGB(132, 32, 64), Color3.fromRGB(94, 24, 48), Color3.fromRGB(226, 222, 212)
M.Colors = { skin = Color3.fromRGB(182, 158, 136), torso = WINE, legs = WINE_DK, arms = WINE }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local ball = Enum.PartType.Ball
	-- an old, severe face, eyes dark and sunk, a beard to the waist, a tall flat velvet hat of office with a gold band
	parts.Head.Material = MAT.SmoothPlastic
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "Socket", V(0.28, 0.14, 0.05), at(sx * 0.26, 0.14, -0.58), K.INK, MAT.SmoothPlastic)
		deco("Head", "Eye", V(0.1, 0.05, 0.04), at(sx * 0.26, 0.14, -0.6), K.LIGHT, MAT.Neon)
		deco("Head", "Brow", V(0.34, 0.1, 0.1), at(sx * 0.27, 0.27, -0.58) * CFrame.Angles(0, 0, -sx * 0.2), BEARD, MAT.Sand)
	end
	deco("Head", "Nose", V(0.2, 0.4, 0.14), at(0, -0.04, -0.6), rgb(170, 146, 124), MAT.SmoothPlastic)
	deco("Head", "Moustache", V(0.84, 0.14, 0.1), at(0, -0.26, -0.58), BEARD, MAT.Sand)
	deco("Head", "Beard", V(0.98, 0.9, 0.3), at(0, -0.72, -0.42), BEARD, MAT.Sand)
	deco("Chest", "BeardFall", V(0.74, ch * 0.72, 0.14), at(0, ch * 0.08, -cd * 0.74), BEARD, MAT.Sand)
	deco("Chest", "BeardPoint", V(0.44, 0.5, 0.12), at(0, -ch * 0.36, -cd * 0.74), BEARD, MAT.Sand)
	deco("Head", "Hat", V(1.3, 1.1, 1.3), at(0, 1.05, 0.02), WINE, MAT.Fabric)
	deco("Head", "HatBand", V(1.38, 0.22, 1.38), at(0, 0.58, 0.02), K.GOLD, MAT.Metal)
	deco("Head", "HatTop", V(1.46, 0.14, 1.46), at(0, 1.62, 0.02), K.GOLD, MAT.Metal)
	deco("Head", "HatJewel", V(0.26, 0.26, 0.08), at(0, 0.6, -0.72), K.LAPIS, MAT.Glass, ball)
	-- the great gown, wide-shouldered; broad bands of gold embroidery; ermine on the shoulders; its chain of office
	deco("Chest", "Gown", V(cw * 1.08, ch * 1.02, cd * 1.15), at(0, 0, 0), WINE, MAT.Fabric)
	deco("Chest", "Yoke", V(cw * 1.32, 0.62, cd * 1.5), at(0, ch * 0.32, 0), Color3.fromRGB(236, 232, 222), MAT.Fabric)
	for i = 0, 11 do
		deco("Chest", "Ermine", V(0.08, 0.2, 0.06), at(-cw * 0.62 + i * cw * 0.113, ch * 0.32, -cd * 0.76), K.INK, MAT.Fabric)
	end
	for _, sx in ipairs({ -1, 1 }) do
		deco("Chest", "GoldBand", V(0.42, ch * 0.72, 0.05), at(sx * cw * 0.32, -ch * 0.08, -cd * 0.6), K.GOLD, MAT.Fabric)
		deco("Hips", "SkirtBand", V(0.42, 3.05, 0.05), at(sx * hw * 0.34, -1.3, -hd * 0.72), K.GOLD, MAT.Fabric)
		for i = 0, 4 do
			deco("Hips", "Embroider", V(0.26, 0.26, 0.05), at(sx * hw * 0.34, -0.2 - i * 0.56, -hd * 0.74) * CFrame.Angles(0, 0, math.pi / 4), K.ROSE, MAT.Fabric)
		end
	end
	for i = 0, 8 do
		local a = i / 8 * math.pi
		deco("Chest", "ChainLink", V(0.2, 0.2, 0.1), at(math.cos(a) * cw * 0.44, ch * 0.2 - math.sin(a) * ch * 0.5, -cd * 0.88), K.LIGHT, MAT.Metal, ball)
	end
	deco("Chest", "Medal", V(0.08, 0.7, 0.7), at(0, ch * -0.32, -cd * 0.92) * K.FACE, K.GOLD, MAT.Metal, Enum.PartType.Cylinder)
	deco("Chest", "MedalStone", V(0.05, 0.3, 0.3), at(0, ch * -0.32, -cd * 0.97) * K.FACE, K.RUG, MAT.Glass, Enum.PartType.Cylinder)
	deco("Hips", "Skirt", V(hw * 1.4, 3.1, hd * 1.45), at(0, -1.3, 0), WINE_DK, MAT.Fabric)
	deco("Hips", "SkirtHem", V(hw * 1.44, 0.2, hd * 1.5), at(0, -2.72, 0), K.GOLD, MAT.Fabric)
	deco("Hips", "Sash", V(hw * 1.42, 0.3, hd * 1.48), at(0, 0.28, 0), K.GOLD, MAT.Fabric)
	-- keys of every door, on a great ring at its belt
	deco("Hips", "KeyRing", V(0.08, 0.62, 0.62), at(hw * 0.7, -0.05, -hd * 0.4) * K.UP * CFrame.Angles(0, 0, math.pi / 2), K.LIGHT, MAT.Metal, Enum.PartType.Cylinder)
	for i = 0, 4 do
		deco("Hips", "Key", V(0.09, 0.62, 0.17), at(hw * 0.7 + (i - 2) * 0.08, -0.5, -hd * 0.4), K.GOLD, MAT.Metal)
	end
	for _, n in ipairs({ "R", "L" }) do
		deco(n .. "UpperArm", "Sleeve", V(aw * 1.45, ua * 1.02, aw * 1.45), at(0, 0, 0), WINE, MAT.Fabric)
		deco(n .. "LowerArm", "WideSleeve", V(aw * 1.75, la * 1.02, aw * 1.75), at(0, 0.05, 0), WINE_DK, MAT.Fabric)
		deco(n .. "LowerArm", "SleeveBand", V(aw * 1.82, 0.22, aw * 1.82), at(0, -la * 0.42, 0), K.GOLD, MAT.Fabric)
	end
end

M.Weapons = {
	-- the rod of office: gold and ebony, an orb-and-flange head, weighted at its foot too
	RodOfOffice = function(w)
		local handle = w.mk("Grip", Vector3.new(0.3, 1.2, 0.3), K.INK, Enum.Material.Wood)
		w.add(w.mk("Rod", Vector3.new(0.26, 5.6, 0.26), K.INK, Enum.Material.Wood), -2)
		for _, y in ipairs({ -0.8, -2, -3.2 }) do
			w.add(w.mk("RodBand", Vector3.new(0.36, 0.2, 0.36), K.GOLD, Enum.Material.Metal), y)
		end
		w.add(w.mk("Ferrule", Vector3.new(0.46, 1, 0.46), K.GOLD, Enum.Material.Metal), 1.2)
		local orb = w.mk("Orb", Vector3.new(1.45, 1.45, 1.45), K.GOLD, Enum.Material.Metal)
		orb.Shape = Enum.PartType.Ball
		w.add(orb, -5.3)
		for i = 0, 5 do
			local a = i * math.pi / 3
			w.add(w.mk("Flange", Vector3.new(0.14, 1.1, 0.55), K.LIGHT, Enum.Material.Metal), -5.3, CFrame.Angles(0, a, 0) * CFrame.new(0, 0, 0.82 * w.scale))
		end
		w.add(w.mk("Cross", Vector3.new(0.18, 0.95, 0.18), K.LIGHT, Enum.Material.Metal), -6.5)
		w.add(w.mk("Cross", Vector3.new(0.6, 0.18, 0.18), K.LIGHT, Enum.Material.Metal), -6.6)
		return { handle = handle, bladeLen = 6.2 }
	end,
}

M.Def = K.def({
	HP = 700, Speed = 7.5, Scale = 1.5, Damage = 52, Range = 11, HalfAngle = 55, Lunge = 6, Poise = 130, Stagger = 0.65, StaggerPush = 5,
	Windup = 1, Recover = 1.25, HyperArmor = true, Engage = 12, Close = 8, Weapon = "RodOfOffice", IdleGrip = "SNStaff", Radius = 2.1, Skin = WINE, Cloth = WINE,
})

local function decree(e, tRoot)
	return K.combo(e, tRoot, {
		{ set = "GCock", setBody = "GBSet", tell = 0.8, swing = "GCut", swingBody = "GBStrike", time = 0.18, damage = 38, speed = 0.8 },
		{ set = "GBack", setBody = "GBWind", tell = 0.7, swing = "GSweep", swingBody = "GBSweep", time = 0.18, damage = 38, speed = 0.78, quiet = true },
		{ set = "GRaise", setBody = "GBCast", tell = 0.9, swing = "GSlam", swingBody = "GBStrike", time = 0.2, damage = 54, level = "Knockdown", speed = 0.7, quiet = true, lunge = 1.3 },
	})
end
local function youMayNot(e, tRoot)
	K.setGrip(e, "SNKnockUp", 0.5)
	K.setBody(e, "SNBUpright", 0.5)
	if not K.hold(e, 0.8, tRoot) then
		return false
	end
	K.setGrip(e, "SNKnock", 0.09, Enum.EasingStyle.Quad)
	K.setBody(e, "SNBKnock", 0.09)
	task.wait(0.09)
	if not e.alive then
		return false
	end
	local at = K.feet(e)
	K.area(at, 13, 3.5, 24, "Large")
	K.flash(at, K.LIGHT, 6)
	K.sound(e, "WatchdogSmash", 0.8, 1.3)
	K.shake(at, 0.5)
	return true
end
local function dismissed(e, tRoot)
	local ok, hit = K.strike(e, tRoot, { set = "GDraw", setBody = "GBDraw", tell = 0.95, swing = "GThrust", swingBody = "GBLunge", time = 0.13, range = 12, half = 20, damage = 48, level = "Knockdown", lunge = 1.8, speed = 0.7 })
	return ok, hit
end

local function makeWay(e, tRoot)
	return K.whirl(e, tRoot, { grip = "GBack", body = "GBSpin", wind = 1, time = 0.55, radius = 10.5, damage = 40, every = 1, speed = 0.1, turn = 16 })
end

M.attack = K.brain(function(e, tRoot, d)
	local roll = math.random()
	if d > e.def.Close and roll < 0.55 then
		return dismissed(e, tRoot), 1.2
	elseif roll < 0.25 then
		return youMayNot(e, tRoot), 0.7
	elseif d > e.def.Close then
		return youMayNot(e, tRoot), 0.5
	elseif roll < 0.5 then
		return makeWay(e, tRoot), 1.4
	end
	return decree(e, tRoot), 1.5
end)

return M
