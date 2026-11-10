--!nonstrict
-- THE DOWAGER (kind Dowager): a very old lady in a very large gown, who has not missed a ball in three hundred years and sees no reason
-- to start. Tier on tier of lapis silk over a hooped skirt, a standing lace collar, a black veil over no face at all, a tower
-- of hair stuck through with gold. She glides; you never see her feet. A long hatpin in each hand.
--   The Waltz   arms out, spinning, gown belling out, coming at you in sweeping curves. She gets dizzy after: your opening
--   Pins        one, then the other, down from over her shoulder
--   Curtsey     she sinks right down... and comes up under you, both pins upward. Don't stand and watch her bow
--   Hatpins     from further off: a pin drawn out of her hair and thrown, then another, and they bend after you
local K = require(script.Parent.Parent:WaitForChild("GildedKit"))
local M = K.wrap({
	Poses = {
		DWBGlide = { drop = 0.05, lean = 0.05, head = 0.1, footR = -0.1, footL = 0.1, spread = 0.04, breathe = 0.4, freeL = 0 },
		DWBCurtsey = { drop = 1.5, lean = 0.3, head = 0.45, footR = 0.5, footL = -0.9, spread = 0.2, freeL = 0, breathe = 0.5 },
		DWBRise = { drop = -0.05, lean = -0.3, head = -0.4, footR = -0.1, footL = 0.1, freeL = 0 },
	},
	Grips = {
		DWRest = { Vector3.new(1.2, 0.1, -0.7), CFrame.Angles(math.rad(35), 0, 0) },
		DWUp = { Vector3.new(0.8, 2.5, -1.1), CFrame.Angles(math.rad(165), 0, 0) },
		DWOut = { Vector3.new(2.3, 0.9, 0), CFrame.Angles(0, 0, math.rad(82)) },
		DWDown = { Vector3.new(0.9, 0.3, -1.3), CFrame.Angles(math.rad(45), 0, 0) },
	},
})
M.Kind = "Dowager"
M.Proportions = { girth = 0.86, arm = 1.05, hunch = 0.14 }
M.IdlePose = "DWBGlide"
M.BodyFor = { DWRest = "DWBGlide" }
local SILK, SILK_DK, LACE, BLACK = Color3.fromRGB(64, 104, 196), Color3.fromRGB(40, 72, 150), Color3.fromRGB(226, 220, 204), Color3.fromRGB(16, 14, 22)
M.Colors = { skin = BLACK, torso = SILK, legs = SILK, arms = SILK }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	-- THE GOWN: stacked hoops getting wider down to the floor, a gold band on each, hiding her legs altogether
	for i = 0, 5 do
		local d = 2.2 + i * 0.62
		deco("Hips", "Gown", V(0.58, d, d), at(0, 0.05 - i * 0.48, 0.04) * K.UP, i % 2 == 0 and SILK or SILK_DK, MAT.Fabric, Enum.PartType.Cylinder)
		deco("Hips", "GownBand", V(0.08, d + 0.06, d + 0.06), at(0, -0.2 - i * 0.48, 0.04) * K.UP, K.GOLD, MAT.Metal, Enum.PartType.Cylinder)
	end
	for i = 0, 7 do
		local a = i * math.pi / 4
		deco("Hips", "Bow", V(0.3, 0.26, 0.14), at(math.cos(a) * 2.45, -2.38, math.sin(a) * 2.45 + 0.04) * CFrame.Angles(0, -a + math.pi / 2, 0), K.GOLD, MAT.Fabric)
	end
	for _, n in ipairs({ "R", "L" }) do
		for _, pn in ipairs({ "Thigh", "Shin", "Foot" }) do
			parts[n .. pn].Transparency = 1
		end
	end
	-- the bodice, corseted, a lace stomacher; lace standing up behind her head
	deco("Chest", "Bodice", V(cw * 0.96, ch * 0.98, cd * 1.04), at(0, 0, 0), SILK, MAT.Fabric)
	deco("Chest", "Stomacher", V(cw * 0.42, ch * 0.86, 0.06), at(0, -0.04, -cd * 0.54), LACE, MAT.Fabric)
	for i = 0, 4 do
		deco("Chest", "Lacing", V(cw * 0.3, 0.05, 0.04), at(0, ch * (0.3 - i * 0.15), -cd * 0.58), K.GOLD, MAT.Metal)
	end
	for i = -3, 3 do
		deco("Chest", "CollarFan", V(0.26, 1.2 - math.abs(i) * 0.08, 0.05), at(i * 0.26, ch * 0.5 + 0.55, cd * 0.34) * CFrame.Angles(-0.25, 0, -i * 0.18), LACE, MAT.Fabric)
	end
	deco("Chest", "Necklace", V(0.08, 0.72, 0.72), at(0, ch * 0.42, -cd * 0.3) * CFrame.Angles(0.4, math.pi / 2, 0), K.LIGHT, MAT.Neon, Enum.PartType.Cylinder)
	-- THE VEIL over no face, a tower of grey hair over it, gold pins stuck through
	parts.Head.Color = BLACK
	local veil = deco("Head", "Veil", V(1.32, 1.55, 1.32), at(0, -0.08, 0), BLACK, MAT.Fabric)
	veil.Transparency = 0.12
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "Eye", V(0.1, 0.05, 0.03), at(sx * 0.24, 0.1, -0.67), K.LIGHT, MAT.Neon)
	end
	for i = 0, 4 do
		local d = 1.28 - i * 0.2
		deco("Head", "Hair", V(d, 0.46, d), at(0, 0.82 + i * 0.36, 0.04 + i * 0.03) * CFrame.Angles(0, i * 0.6, 0), rgb(164, 160, 158), MAT.Sand, Enum.PartType.Ball)
	end
	deco("Head", "HairPin", V(0.06, 0.06, 1.6), at(0, 1.25, 0.05) * CFrame.Angles(0, 0.8, 0.2), K.GOLD, MAT.Metal)
	deco("Head", "HairPin", V(0.06, 0.06, 1.3), at(0, 1.7, 0.05) * CFrame.Angles(0, -0.7, -0.2), K.GOLD, MAT.Metal)
	deco("Head", "Tiara", V(0.2, 1.1, 1.1), at(0, 0.72, 0) * K.UP, K.GOLD, MAT.Metal, Enum.PartType.Cylinder)
	-- long gloves
	for _, n in ipairs({ "R", "L" }) do
		deco(n .. "LowerArm", "Glove", V(aw * 1.02, la * 1.1, aw * 1.02), at(0, -0.05, 0), LACE, MAT.Fabric)
		deco(n .. "UpperArm", "Puff", V(aw * 1.7, ua * 0.6, aw * 1.7), at(0, ua * 0.18, 0), SILK_DK, MAT.Fabric, Enum.PartType.Ball)
		deco(n .. "UpperArm", "PuffBand", V(aw * 1.4, 0.12, aw * 1.4), at(0, -ua * 0.15, 0), K.GOLD, MAT.Metal)
	end
end

M.Weapons = {
	Hatpin = function(w)
		local handle = w.mk("Grip", Vector3.new(0.14, 0.5, 0.14), K.GOLD, Enum.Material.Metal)
		local bead = w.mk("Pearl", Vector3.new(0.42, 0.42, 0.42), K.PORCELAIN, Enum.Material.SmoothPlastic)
		bead.Shape = Enum.PartType.Ball
		w.add(bead, 0.38)
		w.add(w.mk("Pin", Vector3.new(0.06, 3.6, 0.06), Color3.fromRGB(224, 200, 130), Enum.Material.Metal), -2)
		return { handle = handle, bladeLen = 3.8 }
	end,
}

M.Def = K.def({
	HP = 440, Speed = 11.5, Scale = 1.2, Damage = 30, Range = 8, HalfAngle = 45, Lunge = 9, Poise = 55, Stagger = 0.45, StaggerPush = 8,
	Windup = 0.6, Recover = 0.8, Engage = 18, Close = 7, Weapon = "Hatpin", Weapon2 = "Hatpin", IdleGrip = "DWRest", Radius = 1.9, Skin = K.LAPIS, Cloth = K.LAPIS,
})

local function curtsey(e, tRoot)
	K.strike(e, tRoot, {
		set = "DWRest", setBody = "DWBCurtsey", tell = 1.05, swing = "DWUp", swingBody = "DWBRise", time = 0.12,
		range = 9, half = 100, damage = 46, level = "Knockdown", lunge = 2, speed = 0.9,
	})
	return e.alive
end

local function hatpins(e, tRoot)
	K.setGrip(e, "DWUp", 0.4)
	K.setBody(e, "GBSet", 0.4)
	if not K.hold(e, 0.55, tRoot) then
		return false
	end
	for i = 1, 2 do
		if not (e.alive and tRoot.Parent) then
			return false
		end
		K.setGrip(e, "DWDown", 0.1)
		K.setBody(e, "GBFling", 0.1)
		K.sound(e, "Lunge", 0.5, 1.5)
		local from = K.hand(e)
		K.shot(e, {
			from = from, vel = K.aim(from, tRoot, 95, 0.2), damage = 22, level = "Small", radius = 1.2, life = 1.4,
			size = Vector3.new(0.1, 0.1, 1.6), shape = Enum.PartType.Block, color = K.GOLD, trail = K.LIGHT, home = 1.2, homeOn = tRoot,
		})
		if i == 1 then
			K.setGrip(e, "DWUp", 0.2)
			if not K.hold(e, 0.32, tRoot) then
				return false
			end
		end
	end
	return K.hold(e, 0.35, tRoot)
end

M.attack = K.brain(function(e, tRoot, d)
	local roll = math.random()
	if d > e.def.Close and roll < 0.45 then
		return hatpins(e, tRoot), 1
	elseif d > e.def.Close or roll < 0.4 then
		return K.whirl(e, tRoot, { grip = "DWOut", body = "GBSpin", wind = 0.65, time = 2.3, radius = 6.5, damage = 20, every = 0.5, speed = 10, turn = 15 }), 1.5
	elseif roll < 0.72 then
		return K.combo(e, tRoot, {
			{ set = "DWUp", setBody = "GBSet", tell = 0.55, swing = "DWDown", swingBody = "GBStrike", time = 0.12, damage = 26, level = "Medium", speed = 1.1 },
			{ set = "DWUp", setBody = "GBSet", tell = 0.32, swing = "DWDown", swingBody = "GBStrike", time = 0.12, damage = 32, level = "Large", speed = 0.95, quiet = true },
		}), 0.9
	end
	return curtsey(e, tRoot), 1.2
end)

return M
