--!nonstrict
-- THE WIND-UP FOOTMAN (kind WindupFootman): a footman in powder-blue livery who's clockwork all the way through, a great brass key turning
-- in its back. Its joints tick. It serves one tray of knives, over and over. It winds up to run, runs far too fast, and then,
-- all at once, it runs down and stands there ticking, head on one side, while the key slowly turns itself back.
--   Service!    a wound-up sprint straight at you, tray out, knives flat. It can't turn once it's going
--   Clatter     the tray swung left, right, left, each a little too quick
--   Run Down    it stops dead after a long rush. Hit it
local K = require(script.Parent.Parent:WaitForChild("GildedKit"))
local M = K.wrap({
	Poses = {
		WFBStand = { drop = 0, lean = 0, head = 0.06, footR = 0.02, footL = -0.02, breathe = 0, la1 = 0.05, la3 = -0.05, lel = 1.55, freeL = 0 },
		WFBWinding = { drop = 0.5, lean = 0.45, head = -0.25, spread = 0.14, footR = -0.55, footL = 0.7, la1 = -0.4, la3 = -0.2, lel = 1.2, freeL = 0 },
		WFBRun = { drop = 0.7, lean = 0.95, head = -0.4, footR = 0.9, footL = -0.8, la1 = -0.7, la3 = -0.3, lel = 0.5, freeL = 0 },
		WFBSpent = { drop = 0.3, lean = 0.28, side = 0.22, head = 0.55, footR = -0.1, footL = 0.1, la1 = -0.1, la3 = -0.05, lel = 0.1, freeL = 0 },
	},
	Grips = { WFTray = { Vector3.new(1, 0.5, -1.3), CFrame.Angles(math.rad(90), 0, 0) } },
})
M.Kind = "WindupFootman"
M.Proportions = { girth = 0.92, arm = 1.02, hunch = 0, cadence = 1 }
M.IdlePose = "WFBStand"
M.BodyFor = { WFTray = "WFBStand" }
local LIVERY, CUFF, BRASS, ENAMEL = Color3.fromRGB(116, 150, 184), Color3.fromRGB(232, 228, 212), Color3.fromRGB(190, 150, 70), Color3.fromRGB(240, 236, 226)
M.Colors = { skin = ENAMEL, torso = LIVERY, legs = CUFF, arms = LIVERY }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local cyl = Enum.PartType.Cylinder
	-- a doll's enamel face with a hinged jaw; round rouge cheeks; two clock-hands for a moustache; a powdered wig
	parts.Head.Material, parts.Head.Color = MAT.SmoothPlastic, ENAMEL
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "EyeRing", V(0.07, 0.38, 0.38), at(sx * 0.25, 0.12, -0.59) * K.FACE, BRASS, MAT.Metal, cyl)
		deco("Head", "Eye", V(0.04, 0.26, 0.26), at(sx * 0.25, 0.12, -0.62) * K.FACE, rgb(10, 10, 14), MAT.SmoothPlastic, cyl)
		deco("Head", "Rouge", V(0.03, 0.22, 0.22), at(sx * 0.38, -0.17, -0.58) * K.FACE, rgb(214, 110, 110), MAT.SmoothPlastic, cyl)
		deco("Head", "Hinge", V(0.1, 0.1, 0.1), at(sx * 0.42, -0.42, -0.52), BRASS, MAT.Metal, Enum.PartType.Ball)
		deco("Head", "Moustache", V(0.3, 0.035, 0.03), at(sx * 0.16, -0.14, -0.61) * CFrame.Angles(0, 0, sx * 0.3), K.INK, MAT.Metal)
	end
	deco("Head", "Jaw", V(0.72, 0.28, 0.08), at(0, -0.43, -0.57), rgb(226, 222, 212), MAT.SmoothPlastic)
	deco("Head", "Wig", V(1.22, 0.62, 1.25), at(0, 0.48, 0.12), rgb(236, 234, 226), MAT.Sand)
	deco("Head", "Tricorn", V(1.65, 0.28, 1.45), at(0, 0.82, 0.02), rgb(40, 50, 70), MAT.Fabric)
	deco("Head", "TricornTrim", V(1.7, 0.08, 1.5), at(0, 0.68, 0.02), BRASS, MAT.Metal)
	-- the livery; a window in the chest with the gears going round behind glass
	deco("Chest", "Livery", V(cw * 1.04, ch * 1, cd * 1.08), at(0, 0, 0), LIVERY, MAT.Fabric)
	deco("Chest", "Waistcoat", V(cw * 0.5, ch * 0.92, 0.05), at(0, 0, -cd * 0.56), CUFF, MAT.Fabric)
	deco("Chest", "Dial", V(0.1, 0.92, 0.92), at(0, 0.18, -cd * 0.58) * K.FACE, BRASS, MAT.Metal, cyl)
	deco("Chest", "DialFace", V(0.05, 0.75, 0.75), at(0, 0.18, -cd * 0.62) * K.FACE, ENAMEL, MAT.SmoothPlastic, cyl)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		deco("Chest", "Tick", V(0.03, 0.1, 0.03), at(math.cos(a) * 0.3, 0.18 + math.sin(a) * 0.3, -cd * 0.65) * CFrame.Angles(0, 0, a - math.pi / 2), K.INK, MAT.SmoothPlastic)
	end
	deco("Chest", "DialHand", V(0.04, 0.34, 0.03), at(0.08, 0.28, -cd * 0.66) * CFrame.Angles(0, 0, -0.8), K.INK, MAT.Metal)
	deco("Chest", "DialHand", V(0.04, 0.22, 0.03), at(-0.07, 0.24, -cd * 0.66) * CFrame.Angles(0, 0, 0.7), K.INK, MAT.Metal)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Chest", "Epaulette", V(0.72, 0.16, 0.62), at(sx * cw * 0.5, ch * 0.5, 0), BRASS, MAT.Metal)
		for i = -1, 1 do
			deco("Chest", "Fringe", V(0.08, 0.34, 0.08), at(sx * cw * 0.72, ch * 0.33, i * 0.2), BRASS, MAT.Metal)
		end
	end
	-- THE KEY in its back, a big butterfly of brass
	deco("Chest", "KeyShaft", V(0.2, 0.2, 1.05), at(0, 0.15, cd * 0.5 + 0.5), BRASS, MAT.Metal)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Chest", "KeyWing", V(0.1, 0.92, 0.68), at(sx * 0.42, 0.15, cd * 0.5 + 1) * CFrame.Angles(0, math.pi / 2, sx * 1.1), BRASS, MAT.Metal, cyl)
	end
	-- coat-tails, white breeches and stockings, and brass ball-joints showing at every limb
	deco("Hips", "CoatTail", V(hw * 0.9, 1.9, 0.08), at(0, -0.65, hd * 0.6), LIVERY, MAT.Fabric)
	deco("Hips", "Waist", V(hw * 1.2, 0.22, hd * 1.24), at(0, 0.3, 0), BRASS, MAT.Metal)
	for _, n in ipairs({ "R", "L" }) do
		deco(n .. "UpperArm", "Joint", V(aw * 1.1, aw * 1.1, aw * 1.1), at(0, -ua / 2, 0), BRASS, MAT.Metal, Enum.PartType.Ball)
		deco(n .. "UpperArm", "ShoulderJoint", V(aw * 1.2, aw * 1.2, aw * 1.2), at(0, ua / 2, 0), BRASS, MAT.Metal, Enum.PartType.Ball)
		deco(n .. "LowerArm", "Cuff", V(aw * 1.34, 0.46, aw * 1.34), at(0, -la * 0.32, 0), CUFF, MAT.Fabric)
		deco(n .. "LowerArm", "Glove", V(aw * 0.98, 0.45, aw * 1), at(0, -la / 2 - 0.1, 0), CUFF, MAT.Fabric)
		deco(n .. "Thigh", "Joint", V(lw * 1.05, lw * 1.05, lw * 1.05), at(0, -0.6, 0), BRASS, MAT.Metal, Enum.PartType.Ball)
		deco(n .. "Foot", "Shoe", V(0.56, 0.24, 1.02), at(0, 0, -0.05), K.INK, MAT.SmoothPlastic)
		deco(n .. "Foot", "Buckle", V(0.28, 0.14, 0.05), at(0, 0.1, -0.38), BRASS, MAT.Metal)
	end
end

M.Weapons = {
	-- a silver salver, its edge sharpened, a row of carving knives standing on it
	ServiceTray = function(w)
		local silver = Color3.fromRGB(210, 212, 216)
		local handle = w.mk("Grip", Vector3.new(0.2, 0.7, 0.2), silver, Enum.Material.Metal)
		local tray = w.mk("Tray", Vector3.new(0.12, 3, 3), silver, Enum.Material.Metal)
		tray.Shape = Enum.PartType.Cylinder
		w.add(tray, -1.8, CFrame.Angles(0, 0, 0), 0)
		local rim = w.mk("Rim", Vector3.new(0.2, 3.1, 3.1), BRASS, Enum.Material.Metal)
		rim.Shape = Enum.PartType.Cylinder
		w.add(rim, -1.8)
		for i = -2, 2 do
			w.add(w.mk("Knife", Vector3.new(0.5, 0.05, 0.1), silver, Enum.Material.Metal), -1.8 + i * 0.5, CFrame.new(-0.5 * w.scale, 0, 1 * w.scale))
		end
		return { handle = handle, bladeLen = 3.2 }
	end,
}

M.Def = K.def({
	HP = 340, Speed = 11, Scale = 1.15, Damage = 34, Range = 8, HalfAngle = 60, Lunge = 9, Poise = 45, Stagger = 0.5, StaggerPush = 12,
	Windup = 0.55, Recover = 0.8, Engage = 16, Close = 7, Weapon = "ServiceTray", IdleGrip = "WFTray", Radius = 1.3, Skin = BRASS, Cloth = LIVERY,
})

M.attack = K.brain(function(e, tRoot, d)
	if d > e.def.Close then
		K.sound(e, "Unsheath", 0.4, 2)
		local ok = K.rush(e, tRoot, { set = "GLevel", setBody = "WFBWinding", tell = 0.85, driveBody = "WFBRun", speed = 44, time = 0.8, damage = 42, level = "Knockdown", reach = 4.5, pitch = 1.3 })
		if not ok then
			return false
		end
		K.setBody(e, "WFBSpent", 0.15)
		K.setGrip(e, "GGuard", 0.15)
		K.sound(e, "Impact", 0.4, 1.8)
		return true, 2.1 -- (run down: stood ticking)
	end
	return K.combo(e, tRoot, {
		{ set = "GBack", setBody = "GBWind", tell = 0.5, swing = "GSweep", swingBody = "GBSweep", time = 0.1, damage = 22, level = "Small", range = 8.5, half = 70, speed = 1.2 },
		{ set = "GWide", setBody = "GBWind", tell = 0.16, swing = "GCut", swingBody = "GBStrike", time = 0.1, damage = 22, level = "Small", range = 8.5, half = 70, speed = 1.35, quiet = true },
		{ set = "GBack", setBody = "GBWind", tell = 0.2, swing = "GSweep", swingBody = "GBSweep", time = 0.12, damage = 30, level = "Medium", range = 9, half = 70, speed = 1.1, quiet = true, lunge = 1.3 },
	}), 0.9
end)

return M
