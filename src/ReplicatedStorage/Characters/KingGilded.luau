--!nonstrict
-- THE KING OF PYRALIS - proposal A of five (kind KingGilded): THE GILDED SOVEREIGN. A king out of a coronation
-- portrait: crimson velvet sewn with a diaper of gold, an ermine mantle and collar, a chain of office in gold and
-- rubies with the sun hung from it, a closed crown of fleurons and arches with a sun on top, ermine cuffs, and in his
-- right hand a gold sceptre with a sun for its head. The sun-mask of the Pyre priests over his face, made bigger.
--
-- THE FIVE PROPOSALS (no longer shown: the chosen king is a blend of B and C, Characters/KingInquisitor):
--   KingGilded (this file), KingArmored, KingPontiff, KingMolten, KingBasileus.
-- This file also holds what the five share (each of the others is a table.clone of it): the seated pose, the mask,
-- the robe over the lap, a few trim helpers and the spawn. Every one is built at M.Scale, the throne's size.
local M = {}
M.Kind = "KingGilded"
M.Proportions = { girth = 1.05, arm = 1.0, hunch = 0 }
M.IdlePose = "KingSit"
M.Scale = 1.9 -- (the thrones are built to this: a seat 2 high, 3.5 deep, 5.6 between the arms)
M.Poses = {
	-- sat back on the throne, upright, forearms along its arms, feet planted before him, looking down at you
	KingSit = { drop = 1.28, lean = -0.05, head = 0.12, footR = 1.55, footL = 1.55, spread = 0.08, la1 = 0.15, la3 = -0.22, lel = 1.42, ra1 = 0.15, ra3 = 0.22, rel = 1.42, freeL = 0, breathe = 0.5 },
	-- the same, the left forearm raised off the arm of the throne to hold something up (an orb)
	KingSitOrb = { drop = 1.28, lean = -0.05, head = 0.12, footR = 1.55, footL = 1.55, spread = 0.08, la1 = 0.3, la3 = -0.12, lel = 1.8, ra1 = 0.15, ra3 = 0.22, rel = 1.42, freeL = 0, breathe = 0.5 },
}

local rgb = Color3.fromRGB
local cyl, ball = Enum.PartType.Cylinder, Enum.PartType.Ball
local FACE = CFrame.Angles(0, math.pi / 2, 0) -- (a cylinder's axis turned to face forward: a disc on a face)
M.FACE, M.cyl, M.ball = FACE, cyl, ball

---------------------------------------------------------------------------
-- shared pieces (k = RigBuilder's Look kit; every measure below in the rig's unscaled units, like V/at)
---------------------------------------------------------------------------
-- THE MASK: the Pyre priests' (Characters/Pyre: a disc of beaten gold, rays round it, slits for eyes with fire behind
-- them, a slit of a mouth) half again as big - and worked richer for a king: its rim beaten up into bosses, an
-- engraved ring inside it, short rays between the long, a stern brow, a ridge of nose, tear-lines down the cheeks
M.MaskScale = 1.5
function M.Mask(k, gold, goldDk, eye, noTears) -- (noTears: no tear-lines down its cheeks)
	local deco, V, at, MAT = k.deco, k.V, k.at, k.MAT
	local m, z, cy = M.MaskScale, -0.66, 0.04
	eye = eye or rgb(255, 200, 90)
	deco("Head", "Mask", V(0.12, 1.15 * m, 1.15 * m), at(0, cy, z) * FACE, gold, MAT.Metal, cyl)
	deco("Head", "MaskRing", V(0.02, 0.92 * m, 0.92 * m), at(0, cy, z - 0.065) * FACE, goldDk, MAT.Metal, cyl)
	deco("Head", "MaskFace", V(0.02, 0.86 * m, 0.86 * m), at(0, cy, z - 0.075) * FACE, gold, MAT.Metal, cyl)
	for i = 0, 23 do
		local a = i / 24 * math.pi * 2
		deco("Head", "MaskBoss", V(0.07, 0.07, 0.07), at(math.cos(a) * 0.53 * m, cy + math.sin(a) * 0.53 * m, z - 0.07), goldDk, MAT.Metal, ball)
	end
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		deco("Head", "MaskRay", V(0.12, 0.34 * m, 0.05), at(math.cos(a) * 0.68 * m, cy + math.sin(a) * 0.68 * m, z - 0.02) * CFrame.Angles(0, 0, a - math.pi / 2), gold, MAT.Metal)
		local b = a + math.pi / 12
		deco("Head", "MaskRayShort", V(0.08, 0.2 * m, 0.04), at(math.cos(b) * 0.64 * m, cy + math.sin(b) * 0.64 * m, z + 0.01) * CFrame.Angles(0, 0, b - math.pi / 2), goldDk, MAT.Metal)
	end
	local fz = z - 0.09
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "EyeSlit", V(0.3 * m, 0.06 * m, 0.04), at(sx * 0.22 * m, cy + 0.1 * m, fz), rgb(6, 4, 2), MAT.SmoothPlastic)
		deco("Head", "Eye", V(0.12 * m, 0.05 * m, 0.03), at(sx * 0.22 * m, cy + 0.1 * m, fz - 0.01), eye, MAT.Neon)
		deco("Head", "MaskBrow", V(0.34 * m, 0.05 * m, 0.04), at(sx * 0.23 * m, cy + 0.21 * m, fz) * CFrame.Angles(0, 0, -sx * 0.16), goldDk, MAT.Metal)
		for j = 0, noTears and -1 or 2 do
			deco("Head", "MaskTear", V(0.025, 0.14 * m, 0.03), at(sx * (0.14 + j * 0.07) * m, cy - (0.06 + j * 0.02) * m, fz), goldDk, MAT.Metal)
		end
	end
	deco("Head", "MaskNose", V(0.07 * m, 0.3 * m, 0.04), at(0, cy - 0.04 * m, fz), goldDk, MAT.Metal)
	deco("Head", "MaskMouth", V(0.22 * m, 0.05 * m, 0.04), at(0, cy - 0.28 * m, fz), rgb(6, 4, 2), MAT.SmoothPlastic)
	local g = deco("Head", "EyeGlow", V(0.1, 0.1, 0.1), at(0, cy + 0.1 * m, z + 0.05), eye, MAT.Neon)
	g.Transparency = 1
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = rgb(255, 120, 40), 8, 1.2
	l.Parent = g
end

-- THE ROBE OVER THE LAP, for a king sat down: the thighs lie forward (a thigh's -Z is then up, its +Z down), the
-- shins stand. A fall over each thigh and down each shin to the ankle, hemmed; falls off the thighs' outer edges to
-- the floor; a band down the front of each; embroidered slippers. Returns nothing; the caller adds its own pattern
function M.lapRobe(k, col, hem, band, slipper)
	local deco, V, at, MAT = k.deco, k.V, k.at, k.MAT
	local lw, hw, hd = k.lw, k.hw, k.hd
	local fx = k.D.footSize.X / k.s
	deco("Hips", "Robe", V(hw * 1.14, 0.85, hd * 1.16), at(0, -0.02, 0), col, MAT.Fabric)
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		local ox = -sx * 0.07 -- (in toward its fellow: the two falls meet between the knees)
		local ex = ox + sx * lw * 0.875 -- (the thigh fall's outer edge)
		deco(n .. "Thigh", "Lap", V(lw * 1.75, 1.3, lw * 1.25), at(ox, 0, 0), col, MAT.Fabric)
		deco(n .. "Thigh", "LapBand", V(lw * 0.42, 1.3, 0.03), at(ox, 0, -lw * 0.64), band, MAT.Fabric)
		deco(n .. "Thigh", "SideFall", V(0.08, 1.3, 1.2), at(ex, 0, 0.5), col, MAT.Fabric)
		deco(n .. "Thigh", "SideHem", V(0.1, 1.34, 0.12), at(ex, 0, 1.08), hem, MAT.Metal)
		deco(n .. "Shin", "KneeDrape", V(lw * 1.8, 0.3, lw * 1.3), at(ox, 0.5, 0), col, MAT.Fabric)
		deco(n .. "Shin", "Fall", V(lw * 1.8, 1.12, lw * 1.2), at(ox, -0.02, 0), col, MAT.Fabric)
		deco(n .. "Shin", "FallBand", V(lw * 0.42, 1.12, 0.03), at(ox, -0.02, -lw * 0.61), band, MAT.Fabric)
		deco(n .. "Shin", "Hem", V(lw * 1.86, 0.12, lw * 1.26), at(ox, -0.53, 0), hem, MAT.Metal)
		deco(n .. "Foot", "Slipper", V(fx * 1.08, 0.32, 1.1), at(0, 0.02, -0.02), slipper or col, MAT.Fabric)
		deco(n .. "Foot", "SlipperToe", V(fx * 0.5, 0.1, 0.3), at(0, 0.14, -0.42), hem, MAT.Metal)
		deco(n .. "Foot", "SlipperStone", V(0.1, 0.1, 0.1), at(0, 0.2, -0.3), hem, MAT.Metal, ball)
	end
end

-- a little sun on a face: a disc, eight rays long and short, a burning heart if given (cf: its centre, from at())
function M.sun(k, on, cf, r, col, heart)
	local deco, V, at, MAT = k.deco, k.V, k.at, k.MAT
	deco(on, "Sun", V(0.05, r * 1.1, r * 1.1), cf * FACE, col, MAT.Metal, cyl)
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		deco(on, "SunRay", V(r * 0.2, r * (i % 2 == 0 and 0.75 or 0.45), 0.04), cf * at(math.cos(a) * r * 0.85, math.sin(a) * r * 0.85, 0) * CFrame.Angles(0, 0, a - math.pi / 2), col, MAT.Metal)
	end
	if heart then
		deco(on, "SunHeart", V(0.06, r * 0.5, r * 0.5), cf * at(0, 0, -0.02) * FACE, heart, MAT.Neon, cyl)
	end
end

-- a diaper: a grid of small lozenges on a face at depth z, centred on cx, cy, two colours in turn
function M.brocade(k, on, cx, cy, z, nx, ny, step, size, colA, colB, mat)
	for i = 0, nx - 1 do
		for j = 0, ny - 1 do
			local x, y = cx + (i - (nx - 1) / 2) * step, cy + (j - (ny - 1) / 2) * step
			k.deco(on, "Brocade", k.V(size, size, 0.03), k.at(x, y, z) * CFrame.Angles(0, 0, math.pi / 4), (i + j) % 2 == 0 and colA or colB, mat or k.MAT.Metal)
		end
	end
end

-- a lattice: thin bars both ways at 45 degrees across a W x H panel on a face (centre cx, cy, depth z), clipped to it
function M.lattice(k, on, W, H, cx, cy, z, step, col, mat, th)
	th = th or 0.035
	local n = math.ceil((W + H) / 2 / step)
	for _, dir in ipairs({ 1, -1 }) do
		for i = -n, n do
			local c = i * step
			local x1, x2 = math.max(-W / 2, c - H / 2), math.min(W / 2, c + H / 2)
			if x2 - x1 > 0.06 then
				local xm = (x1 + x2) / 2
				k.deco(on, "Lattice", k.V((x2 - x1) * math.sqrt(2), th, 0.025), k.at(cx + xm, cy + dir * (xm - c), z) * CFrame.Angles(0, 0, dir * math.pi / 4), col, mat or k.MAT.Metal)
			end
		end
	end
end

-- a row of studs (or stones) from x1 to x2 at height y, depth z
function M.studs(k, on, n, x1, x2, y, z, d, col, mat, shape)
	for i = 0, n - 1 do
		local x = n == 1 and (x1 + x2) / 2 or x1 + (x2 - x1) * i / (n - 1)
		k.deco(on, "Stud", k.V(d, d, d), k.at(x, y, z), col, mat or k.MAT.Metal, shape or ball)
	end
end

-- the frame of something held upright in the fist, when the forearm lies forward along the throne's arm (as in
-- KingSit): +Y up, -Z forward, origin in the grip. (A forearm laid forward has its -Y forward and its -Z up)
function M.held(k)
	return k.at(0, -k.la / 2 - 0.12, 0) * CFrame.Angles(-math.pi / 2, 0, 0)
end

---------------------------------------------------------------------------
-- THE GILDED SOVEREIGN's look
---------------------------------------------------------------------------
local CRIM, CRIM_DK, GOLD, GOLD_DK = rgb(118, 18, 22), rgb(70, 10, 14), rgb(198, 152, 66), rgb(138, 98, 40)
local ERMINE, SPOT, RUBY, SAPPH, EMBER = rgb(236, 230, 218), rgb(18, 16, 16), rgb(170, 16, 24), rgb(30, 60, 150), rgb(255, 120, 30)
M.Colors = { skin = CRIM_DK, torso = CRIM, legs = CRIM, arms = CRIM }

-- ermine spots: a black tail and its little cross, in a staggered grid over a face
local function ermineSpots(k, on, cx, cy, z, nx, ny, sx, sy)
	for i = 0, nx - 1 do
		for j = 0, ny - 1 do
			local x, y = cx + (i - (nx - 1) / 2 + (j % 2) * 0.5) * sx, cy + (j - (ny - 1) / 2) * sy
			k.deco(on, "ErmineTail", k.V(0.05, 0.13, 0.03), k.at(x, y - 0.02, z), SPOT, k.MAT.Fabric)
			k.deco(on, "ErmineCross", k.V(0.11, 0.035, 0.03), k.at(x, y + 0.04, z), SPOT, k.MAT.Fabric)
		end
	end
end

function M.Look(k)
	local deco, V, at, MAT = k.deco, k.V, k.at, k.MAT
	local cw, ch, cd, hw, aw, la, ua = k.cw, k.ch, k.cd, k.hw, k.aw, k.la, k.ua
	local fz = -cd * 0.56 - 0.02 -- (the robe's front, where its work is sewn on)
	-- THE HEAD: a coif of crimson under the crown, the mask before it
	deco("Head", "Coif", V(1.25, 1.3, 1.25), at(0, 0.02, 0.04), CRIM_DK, MAT.Fabric)
	M.Mask(k, GOLD, GOLD_DK)
	-- THE CROWN: a band of gold, ridged top and bottom and set with stones; round it fleurons and sun-points; inside it
	-- a cap of velvet, two arches over that, pearled; on top an orb and a little sun
	local CY = 0.86
	deco("Head", "CrownBand", V(1.36, 0.34, 1.36), at(0, CY, 0.02), GOLD, MAT.Metal)
	for _, y in ipairs({ CY - 0.16, CY + 0.16 }) do
		deco("Head", "CrownRidge", V(1.42, 0.06, 1.42), at(0, y, 0.02), GOLD_DK, MAT.Metal)
	end
	for f = 0, 3 do
		local face = at(0, 0, 0.02) * CFrame.Angles(0, f * math.pi / 2, 0)
		for i = -1, 1 do
			deco("Head", "CrownStone", V(0.14, 0.14, 0.08), face * at(i * 0.42, CY, -0.7) * CFrame.Angles(0, 0, math.pi / 4), i == 0 and RUBY or SAPPH, MAT.Glass)
			local h = i == 0 and 0.62 or 0.4
			for t = 0, 2 do -- a point of three shrinking blocks, a pearl on its tip
				local w = 0.16 - t * 0.045
				deco("Head", "CrownPoint", V(w, h / 3, w), face * at(i * 0.42, CY + 0.17 + h / 6 + t * h / 3, -0.66), GOLD, MAT.Metal)
			end
			deco("Head", "CrownPearl", V(0.09, 0.09, 0.09), face * at(i * 0.42, CY + 0.2 + h, -0.66), ERMINE, MAT.SmoothPlastic, ball)
		end
		deco("Head", "CrownLeaf", V(0.1, 0.22, 0.06), face * at(-0.66, CY + 0.28, -0.66) * CFrame.Angles(0, math.pi / 4, 0), GOLD, MAT.Metal)
	end
	deco("Head", "CrownCap", V(1.18, 0.55, 1.18), at(0, CY + 0.3, 0.02), CRIM, MAT.Fabric)
	for f = 0, 1 do
		local face = at(0, 0, 0.02) * CFrame.Angles(0, f * math.pi / 2, 0)
		for _, sx in ipairs({ -1, 1 }) do
			deco("Head", "CrownArch", V(0.1, 0.5, 0.12), face * at(sx * 0.5, CY + 0.42, 0) * CFrame.Angles(0, 0, sx * 0.55), GOLD, MAT.Metal)
			deco("Head", "ArchPearl", V(0.07, 0.07, 0.07), face * at(sx * 0.42, CY + 0.52, -0.08), ERMINE, MAT.SmoothPlastic, ball)
		end
		deco("Head", "CrownArch", V(0.5, 0.1, 0.12), face * at(0, CY + 0.66, 0), GOLD, MAT.Metal)
	end
	deco("Head", "CrownOrb", V(0.26, 0.26, 0.26), at(0, CY + 0.82, 0.02), GOLD, MAT.Metal, ball)
	M.sun(k, "Head", at(0, CY + 1.12, 0.02), 0.16, GOLD, EMBER)
	-- THE ROBE: crimson velvet, a diaper of gold over it either side of the front, the opening edged in ermine
	deco("Chest", "Robe", V(cw * 1.08, ch * 1.02, cd * 1.12), at(0, 0, 0), CRIM, MAT.Fabric)
	for _, sx in ipairs({ -1, 1 }) do
		M.brocade(k, "Chest", sx * cw * 0.3, -0.12, fz, 4, 5, 0.22, 0.07, GOLD, GOLD_DK)
		deco("Chest", "ErmineEdge", V(0.2, ch * 0.95, 0.07), at(sx * 0.17, -0.04, fz - 0.01), ERMINE, MAT.Fabric)
		ermineSpots(k, "Chest", sx * 0.17, -0.1, fz - 0.05, 1, 5, 0.1, 0.28)
		deco("Chest", "SideSeam", V(0.04, ch * 0.95, 0.04), at(sx * cw * 0.52, -0.04, fz), GOLD, MAT.Metal)
	end
	deco("Chest", "Placket", V(0.14, ch * 0.95, 0.05), at(0, -0.04, fz), CRIM_DK, MAT.Fabric)
	for j = 0, 5 do
		deco("Chest", "Button", V(0.08, 0.08, 0.08), at(0, ch * 0.38 - j * 0.26, fz - 0.04), GOLD, MAT.Metal, ball)
	end
	-- the girdle: gold plaques on a band, a sun for the buckle
	deco("Chest", "Girdle", V(cw * 1.12, 0.2, cd * 1.18), at(0, -ch / 2 + 0.12, 0), GOLD_DK, MAT.Metal)
	for i = -4, 4 do
		deco("Chest", "GirdlePlaque", V(0.14, 0.14, 0.04), at(i * 0.22, -ch / 2 + 0.12, -cd * 0.6 - 0.02), i % 2 == 0 and GOLD or RUBY, i % 2 == 0 and MAT.Metal or MAT.Glass)
	end
	M.sun(k, "Chest", at(0, -ch / 2 + 0.12, -cd * 0.6 - 0.05), 0.16, GOLD, EMBER)
	-- THE ERMINE MANTLE over his shoulders, a roll of it for a collar; spotted all over
	deco("Chest", "Mantle", V(cw * 1.3, 0.6, cd * 1.5), at(0, ch / 2 - 0.22, 0), ERMINE, MAT.Fabric)
	deco("Chest", "MantleHem", V(cw * 1.32, 0.06, cd * 1.52), at(0, ch / 2 - 0.5, 0), GOLD, MAT.Metal)
	ermineSpots(k, "Chest", 0, ch / 2 - 0.22, -cd * 0.75 - 0.01, 9, 2, 0.28, 0.24)
	deco("Chest", "Collar", V(1.15, 0.32, 1.0), at(0, ch / 2 + 0.1, 0.02), ERMINE, MAT.Fabric)
	ermineSpots(k, "Chest", 0, ch / 2 + 0.1, -0.51, 4, 1, 0.26, 0.2)
	-- THE CHAIN OF OFFICE: gold links and rubies hung from shoulder to shoulder, the sun at its lowest
	for i = 0, 16 do
		local t = i / 16 * 2 - 1
		local x, y = t * 0.66, -0.12 + (ch / 2 - 0.42) * t * t
		if i % 2 == 0 then
			deco("Chest", "ChainLink", V(0.13, 0.13, 0.05), at(x, y, fz - 0.07) * CFrame.Angles(0, 0, math.pi / 4), GOLD, MAT.Metal)
		else
			deco("Chest", "ChainStone", V(0.08, 0.08, 0.08), at(x, y, fz - 0.08), RUBY, MAT.Glass, ball)
		end
	end
	M.sun(k, "Chest", at(0, -0.38, fz - 0.09), 0.24, GOLD, EMBER)
	-- THE SLEEVES: puffed above, slashed to show gold; fitted below; ermine cuffs; a ring on each hand
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		deco(n .. "UpperArm", "Puff", V(aw * 1.55, ua * 0.9, aw * 1.55), at(0, 0, 0), CRIM, MAT.Fabric)
		deco(n .. "UpperArm", "ShoulderRoll", V(aw * 1.65, 0.16, aw * 1.65), at(0, ua * 0.42, 0), GOLD, MAT.Metal)
		deco(n .. "UpperArm", "ArmBand", V(aw * 1.6, 0.1, aw * 1.6), at(0, -ua * 0.4, 0), GOLD, MAT.Metal)
		for f = 0, 3 do
			local face = CFrame.Angles(0, f * math.pi / 2, 0)
			deco(n .. "UpperArm", "Slash", V(0.07, ua * 0.6, 0.03), face * at(0, 0, -aw * 0.78), GOLD, MAT.Metal)
			deco(n .. "UpperArm", "SlashStud", V(0.06, 0.06, 0.06), face * at(0, ua * 0.32, -aw * 0.79), RUBY, MAT.Glass, ball)
		end
		deco(n .. "LowerArm", "Sleeve", V(aw * 1.3, la * 0.7, aw * 1.3), at(0, 0.12, 0), CRIM, MAT.Fabric)
		deco(n .. "LowerArm", "Cuff", V(aw * 1.6, la * 0.3, aw * 1.6), at(0, -la * 0.28, 0), ERMINE, MAT.Fabric)
		deco(n .. "LowerArm", "CuffBand", V(aw * 1.64, 0.07, aw * 1.64), at(0, -la * 0.12, 0), GOLD, MAT.Metal)
		for f = 0, 3 do
			local face = CFrame.Angles(0, f * math.pi / 2, 0)
			deco(n .. "LowerArm", "ErmineTail", V(0.05, 0.12, 0.03), face * at(0, -la * 0.3, -aw * 0.81), SPOT, MAT.Fabric)
		end
		deco(n .. "LowerArm", "Ring", V(0.1, 0.1, 0.1), at(sx * aw * 0.3, -la / 2 - 0.2, -aw * 0.5), GOLD, MAT.Metal, ball)
	end
	-- THE LAP: the velvet falls to his ankles, ermine-hemmed, a band of gold down each knee, the diaper over the lap
	M.lapRobe(k, CRIM, GOLD, GOLD_DK, CRIM_DK)
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		M.brocade(k, n .. "Thigh", -sx * 0.07, 0, -k.lw * 0.66, 3, 5, 0.22, 0.07, GOLD, GOLD_DK)
		M.brocade(k, n .. "Shin", -sx * 0.07, 0.05, -k.lw * 0.63, 3, 4, 0.22, 0.07, GOLD, GOLD_DK)
		deco(n .. "Shin", "ErmineHem", V(k.lw * 1.9, 0.2, k.lw * 1.3), at(-sx * 0.07, -0.42, 0), ERMINE, MAT.Fabric)
		ermineSpots(k, n .. "Shin", -sx * 0.07, -0.42, -k.lw * 0.66, 3, 1, 0.25, 0.2)
	end
	-- THE SCEPTRE, upright in his right fist: a rod of gold ringed with knops, a sun for its head
	local G = M.held(k)
	deco("RLowerArm", "SceptreRod", V(0.12, 3.6, 0.12), G * at(0, 0.6, 0), GOLD, MAT.Metal)
	for _, y in ipairs({ -1.1, -0.3, 0.6, 1.5, 2.1 }) do
		deco("RLowerArm", "SceptreKnop", V(0.22, 0.12, 0.22), G * at(0, y, 0), GOLD_DK, MAT.Metal)
	end
	deco("RLowerArm", "SceptreFoot", V(0.18, 0.18, 0.18), G * at(0, -1.2, 0), GOLD, MAT.Metal, ball)
	deco("RLowerArm", "SceptreCup", V(0.3, 0.18, 0.3), G * at(0, 2.4, 0), GOLD, MAT.Metal)
	M.sun(k, "RLowerArm", G * at(0, 2.85, -0.04), 0.3, GOLD, EMBER)
	M.sun(k, "RLowerArm", G * at(0, 2.85, 0.04) * CFrame.Angles(0, math.pi, 0), 0.3, GOLD, EMBER)
end

---------------------------------------------------------------------------
-- server: the chosen king's statues (he himself is an enemy now: Characters/KingInquisitor, spawned in the Sunken Court)
---------------------------------------------------------------------------
local Map, RigBuilder, giveWeapon, poseCF

-- A STATUE of a character: its rig built, posed on the server (PuppetMath solves the pose the Puppeteer would), every
-- part set where that pose puts it and anchored there, the joints, welds, lights, fire and smoke taken out, and all of
-- it turned to stone - its own colours kept only as light and dark - its weapon (if it has one: Def.Weapon) in its
-- hands as it holds it at rest (Def.IdleGrip). foot: where it stands, facing; scale: its size; poseName: its own idle
local PM
local ORDER = { "Root", "Waist", "Neck", "RShoulder", "RElbow", "LShoulder", "LElbow", "RHip", "RKnee", "RAnkle", "LHip", "LKnee", "LAnkle", "RWrist", "LWrist", "RToe", "LToe" }
local STONE, STONE_LT = rgb(84, 78, 74), rgb(178, 170, 158)
local GONE = { "JointInstance", "WeldConstraint", "Light", "Fire", "ParticleEmitter", "Smoke", "Sparkles", "Humanoid", "Trail" }
function M.statue(kind, foot, scale, poseName)
	PM = PM or require(script.Parent.Parent:WaitForChild("PuppetMath"))
	local model = RigBuilder.build(kind, scale)
	local root = model.PrimaryPart
	local def = require(script.Parent.Parent:WaitForChild("Roster")).byKind[kind]
	poseName = poseName or def.IdlePose
	local wd = def.Def
	local grip = wd and wd.Weapon and giveWeapon(model, wd.Weapon, scale)
	local gripC0 = grip and poseCF(wd.IdleGrip or "Idle", scale)
	local wofs = {} -- the weapon's parts on its handle
	for _, w in ipairs(model:GetDescendants()) do
		if w:IsA("Weld") and w ~= grip and w.Part0 and w.Part1 then
			wofs[w.Part1] = { w.Part0, w.C0 * w.C1:Inverse() }
		end
	end
	local D = PM.dims(kind, scale)
	local J = PM.joints(D)
	local offs = {} -- every decoration's place on the body part it's welded to, at rest
	for _, p in ipairs(model:GetDescendants()) do
		local w = p:IsA("BasePart") and p:FindFirstChildOfClass("WeldConstraint")
		if w and w.Part0 then
			offs[p] = { w.Part0, w.Part0.CFrame:ToObjectSpace(p.CFrame) }
		end
	end
	local rootCF = foot * CFrame.new(0, D.rootY, 0)
	local ctx = { t = 0 }
	if grip then -- (the hands on the haft, as the Puppeteer puts them)
		local g = rootCF * gripC0
		ctx.rightTarget = g.Position
		if D.twoHand then
			ctx.leftTarget = (g * CFrame.new(0, D.twoHand, 0)).Position
		end
	end
	local C0 = PM.solve(D, J, rootCF, PM.pose(poseName, kind), ctx)
	local place = { [root] = rootCF }
	if grip then
		place[grip.Part1] = rootCF * gripC0 * grip.C1:Inverse()
		for p, o in pairs(wofs) do
			if o[1] == grip.Part1 then
				place[p] = place[grip.Part1] * o[2]
			end
		end
	end
	for _, jn in ipairs(ORDER) do -- (out from the root, each body part off the one it hangs from)
		local j = J[jn]
		local p0, p1 = j and model:FindFirstChild(j.p0), j and model:FindFirstChild(j.p1)
		if p0 and p1 and place[p0] then
			place[p1] = place[p0] * (C0[jn] or j.C0) * j.C1:Inverse()
		end
	end
	for _, d in ipairs(model:GetDescendants()) do
		for _, c in ipairs(GONE) do
			if d:IsA(c) then
				d:Destroy()
				break
			end
		end
	end
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			if place[p] then
				p.CFrame = place[p]
			elseif offs[p] and place[offs[p][1]] then
				p.CFrame = place[offs[p][1]] * offs[p][2]
			end
			if p.Transparency < 1 then
				local c = p.Color
				p.Color = STONE:Lerp(STONE_LT, 0.299 * c.R + 0.587 * c.G + 0.114 * c.B)
				p.Material, p.Reflectance = Enum.Material.Slate, 0
			end
			p.CanCollide = place[p] ~= nil and not wofs[p] and not (grip and p == grip.Part1) -- (the body's own blocks, unseen, stop you; the carving and the weapon don't)
			p.CanQuery, p.CanTouch = false, false
		end
	end
	-- its cloth (strips the clients swing: Carrier.cloth) hung still in stone instead, straight down off each anchor
	local CS = game:GetService("CollectionService")
	for _, anchor in ipairs(model:GetDescendants()) do
		if anchor:IsA("BasePart") and CS:HasTag(anchor, "ClothChain") then
			CS:RemoveTag(anchor, "ClothChain")
			local h = (anchor:GetAttribute("Segs") or 5) * (anchor:GetAttribute("Len") or 1)
			local look = anchor.CFrame.LookVector * Vector3.new(1, 0, 1)
			local pos = anchor.Position + (look.Magnitude > 1e-3 and look.Unit or Vector3.zAxis) * ((anchor:GetAttribute("Out") or 0) + 0.06 * h)
			local slab = Instance.new("Part")
			slab.Name = "StoneCloth"
			slab.Size = Vector3.new(anchor:GetAttribute("Width") or 1, h, 0.15 * scale)
			slab.CFrame = CFrame.lookAt(pos, pos + (look.Magnitude > 1e-3 and look.Unit or Vector3.zAxis)) * CFrame.new(0, -h / 2, 0) * CFrame.Angles(0.06, 0, 0)
			local c = anchor:GetAttribute("Color") or Color3.new(0.2, 0.2, 0.2)
			slab.Color = STONE:Lerp(STONE_LT, 0.299 * c.R + 0.587 * c.G + 0.114 * c.B)
			slab.Material, slab.Anchored = Enum.Material.Slate, true
			slab.CanCollide, slab.CanQuery, slab.CanTouch = false, false, false
			slab.Parent = model
		end
	end
	root:Destroy()
	pcall(function()
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	return model
end

-- every statue in the Palace of Pyralis is of the chosen king: PyralisBulwark marks their places (info.KingStatues:
-- { Foot = CFrame, Scale = n }), stood here in stone in his own pose
function M.spawnStatues()
	local list = Map and Map.KingStatues
	if not list then
		return
	end
	local folder = Instance.new("Model")
	folder.Name = "KingStatues"
	folder.Parent = workspace
	for _, s in ipairs(list) do
		local ok, m = pcall(M.statue, "KingInquisitor", s.Foot, s.Scale)
		if ok then
			m.Name = "KingStatue"
			m.Parent = folder
		else
			warn("[DGUS] king statue failed: " .. tostring(m))
		end
	end
end

function M.init(core)
	Map, RigBuilder, giveWeapon, poseCF = core.Map, core.RigBuilder, core.giveWeapon, core.poseCF
end

return M
