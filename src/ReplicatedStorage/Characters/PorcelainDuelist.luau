--!nonstrict
-- PORCELAIN DUELIST (kind PorcelainDuelist): a courtier fired and glazed, cracked long ago and mended in gold seams. A smooth white face
-- with no features but a painted smile; rose velvet doublet, lace at the throat and wrists, a rapier held out at the end of a
-- very straight arm. Light, quick, and it breaks up fast if you can catch it.
--   Flurry   three quick stabs, walking you back
--   Fleche   a flat dash, the whole body behind the point, straight through you
--   It keeps its distance: once it's stabbed it steps away (M.steer holds it off a little)
local K = require(script.Parent.Parent:WaitForChild("GildedKit"))
local M = K.wrap({
	Poses = { PDBStance = { drop = 0.45, lean = 0.1, twist = 0.5, head = -0.1, footR = -0.65, footL = 0.7, spread = 0.2, breathe = 1, la1 = 1.2, la3 = -0.9, lel = 1.6, freeL = 0 } },
	Grips = { PDEnGarde = { Vector3.new(0.9, 0.4, -1.5), CFrame.Angles(math.rad(98), 0, 0) } },
})
M.Kind = "PorcelainDuelist"
M.Proportions = { girth = 0.82, arm = 1.08, hunch = 0, cadence = 0.7 }
M.IdlePose = "PDBStance"
M.BodyFor = { PDEnGarde = "PDBStance" }
local WHITE, VELVET, LACE, SEAM = K.PORCELAIN, K.ROSE, Color3.fromRGB(240, 232, 216), K.LIGHT
M.Colors = { skin = WHITE, torso = VELVET, legs = Color3.fromRGB(60, 20, 44), arms = VELVET }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local rng = Random.new()
	-- THE FACE: glazed, oval, a painted mouth and two painted brows; gold seams across it
	parts.Head.Material, parts.Head.Reflectance = MAT.Glass, 0.12
	deco("Head", "Face", V(1.1, 1.4, 1.1), at(0, -0.02, -0.08), WHITE, MAT.SmoothPlastic, Enum.PartType.Ball).Reflectance = 0.2
	deco("Head", "Smile", V(0.5, 0.05, 0.04), at(0, -0.34, -0.63) * CFrame.Angles(0, 0, 0), K.RUG, MAT.SmoothPlastic)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "SmileEnd", V(0.14, 0.05, 0.04), at(sx * 0.3, -0.29, -0.61) * CFrame.Angles(0, 0, sx * 0.6), K.RUG, MAT.SmoothPlastic)
		deco("Head", "Brow", V(0.3, 0.035, 0.04), at(sx * 0.25, 0.22, -0.6) * CFrame.Angles(0, 0, -sx * 0.25), K.INK, MAT.SmoothPlastic)
		deco("Head", "EyeHole", V(0.2, 0.09, 0.04), at(sx * 0.25, 0.08, -0.61), K.INK, MAT.SmoothPlastic)
	end
	for _ = 1, 4 do
		deco("Head", "Seam", V(0.03, rng:NextNumber(0.3, 0.6), 0.03), at(rng:NextNumber(-0.42, 0.42), rng:NextNumber(-0.3, 0.45), -0.58) * CFrame.Angles(0, 0, rng:NextNumber(-1.2, 1.2)), SEAM, MAT.Neon)
	end
	-- a powdered wig, tied back with a bow
	deco("Head", "Wig", V(1.25, 0.8, 1.3), at(0, 0.42, 0.18), rgb(226, 222, 210), MAT.Sand)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "Curl", V(0.42, 0.42, 0.7), at(sx * 0.62, 0.05, 0.22), rgb(220, 216, 204), MAT.Sand, Enum.PartType.Ball)
	end
	deco("Head", "Queue", V(0.28, 0.9, 0.28), at(0, -0.1, 0.72), rgb(220, 216, 204), MAT.Sand)
	deco("Head", "Bow", V(0.8, 0.26, 0.14), at(0, 0.3, 0.72), K.INK, MAT.Fabric)
	-- the doublet, gold frogging down it; lace at the throat and the wrist
	deco("Chest", "Doublet", V(cw * 1.04, ch * 0.98, cd * 1.08), at(0, 0, 0), VELVET, MAT.Fabric)
	for i = 0, 4 do
		deco("Chest", "Frog", V(cw * 0.42, 0.06, 0.05), at(0, ch * (0.32 - i * 0.16), -cd * 0.57), K.GOLD, MAT.Metal)
	end
	for i = 0, 2 do
		deco("Chest", "Jabot", V(0.62 - i * 0.12, 0.2, 0.14), at(0, ch * 0.44 - i * 0.18, -cd * 0.62), LACE, MAT.Fabric)
	end
	deco("Chest", "Collar", V(cw * 0.5, 0.2, cd * 1.05), at(0, ch * 0.52, 0), LACE, MAT.Fabric)
	deco("Hips", "Coatskirt", V(hw * 1.2, 1.4, hd * 1.2), at(0, -0.5, 0.05), VELVET, MAT.Fabric)
	deco("Hips", "Sash", V(hw * 1.24, 0.2, hd * 1.26), at(0, 0.28, 0), K.GOLD, MAT.Fabric)
	for _, n in ipairs({ "R", "L" }) do
		deco(n .. "LowerArm", "Cuff", V(aw * 1.45, 0.42, aw * 1.45), at(0, -la * 0.3, 0), K.GOLD, MAT.Fabric)
		deco(n .. "LowerArm", "Lace", V(aw * 1.3, 0.2, aw * 1.3), at(0, -la * 0.5, 0), LACE, MAT.Fabric)
		deco(n .. "LowerArm", "Hand", V(aw * 0.9, 0.46, aw * 0.9), at(0, -la / 2 - 0.1, 0), WHITE, MAT.SmoothPlastic)
		deco(n .. "Shin", "Stocking", V(lw * 1.02, 1.02, lw * 1.02), at(0, 0, 0), LACE, MAT.Fabric)
		deco(n .. "Thigh", "Breeches", V(lw * 1.14, 1, lw * 1.14), at(0, 0.05, 0), Color3.fromRGB(70, 26, 54), MAT.Fabric)
		deco(n .. "Foot", "Shoe", V(0.56, 0.24, 1), at(0, 0, -0.05), K.INK, MAT.SmoothPlastic)
		deco(n .. "Foot", "Buckle", V(0.26, 0.12, 0.06), at(0, 0.1, -0.36), K.GOLD, MAT.Metal)
	end
	-- a small gold-seamed crack across its chest too
	deco("Chest", "Seam", V(0.04, ch * 0.5, 0.04), at(-cw * 0.3, 0, -cd * 0.56) * CFrame.Angles(0, 0, 0.5), SEAM, MAT.Neon)
end

M.Weapons = {
	PorcelainRapier = function(w)
		local steel, gold = Color3.fromRGB(210, 212, 220), K.GOLD
		local handle = w.mk("Grip", Vector3.new(0.18, 0.7, 0.18), K.INK, Enum.Material.Leather)
		w.add(w.mk("Pommel", Vector3.new(0.26, 0.26, 0.26), gold, Enum.Material.Metal), 0.42)
		local cup = w.mk("Cup", Vector3.new(0.2, 0.74, 0.74), gold, Enum.Material.Metal)
		cup.Shape = Enum.PartType.Cylinder
		w.add(cup, -0.46, CFrame.Angles(0, 0, math.pi / 2))
		w.add(w.mk("Quillon", Vector3.new(1.05, 0.08, 0.08), gold, Enum.Material.Metal), -0.42)
		w.add(w.mk("Blade", Vector3.new(0.07, 4.8, 0.1), steel, Enum.Material.Metal), -2.95)
		return { handle = handle, bladeLen = 5.3 }
	end,
}

M.Def = K.def({
	HP = 290, Speed = 12.5, Scale = 1.1, Damage = 26, Range = 8, HalfAngle = 30, Lunge = 11, Poise = 35, Stagger = 0.6, StaggerPush = 16,
	Windup = 0.45, Recover = 0.7, Engage = 14, Close = 7.5, Weapon = "PorcelainRapier", IdleGrip = "PDEnGarde", Radius = 1.2, Skin = K.PORCELAIN, Cloth = K.ROSE,
})

M.attack = K.brain(function(e, tRoot, d)
	if d > e.def.Close then
		return K.rush(e, tRoot, { set = "GDraw", setBody = "GBDraw", tell = 0.65, drive = "GThrust", driveBody = "GBLunge", speed = 46, time = 0.4, damage = 34, level = "Large", pitch = 1.1 }), 1.05
	end
	local ok = K.combo(e, tRoot, {
		{ set = "GDraw", setBody = "GBDraw", tell = 0.42, swing = "GThrust", swingBody = "GBLunge", time = 0.09, level = "Small", damage = 16, range = 8.5, half = 26, speed = 1.3 },
		{ set = "GDraw", setBody = "GBDraw", tell = 0.2, swing = "GThrust", swingBody = "GBLunge", time = 0.09, level = "Small", damage = 16, range = 8.5, half = 26, speed = 1.4, quiet = true },
		{ set = "GDraw", setBody = "GBDraw", tell = 0.28, swing = "GThrust", swingBody = "GBLunge", time = 0.1, level = "Medium", damage = 24, range = 9, half = 22, speed = 1.2, lunge = 1.4, quiet = true },
	})
	if ok then -- (a neat step back, out of your reach: on guard again)
		e.root.AssemblyLinearVelocity = -e.root.CFrame.LookVector * 22
	end
	return ok, 0.8
end)

return M
