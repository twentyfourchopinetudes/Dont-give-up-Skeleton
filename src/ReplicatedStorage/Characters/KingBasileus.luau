--!nonstrict
-- THE KING OF PYRALIS - proposal E of five (kind KingBasileus): THE BASILEUS. An emperor of the old east: purple
-- brocade trellised in gold and set with stones; the loros - a long jewelled band - crossed over his breast and hung
-- down his front to his feet, gold squares and gems in turn all down it; a wide jewelled collar; a domed crown, its
-- band of enamel plaques between rows of pearls, strings of pearls hanging at his temples; jewelled cuffs; rings.
-- He holds up an orb of gold in his left hand, banded and jewelled, a sun on top. (Shared pose, mask and spawn:
-- Characters/KingGilded; his pose is KingSitOrb.)
local Base = require(script.Parent:WaitForChild("KingGilded"))

local M = table.clone(Base)
M.Kind = "KingBasileus"
M.Proportions = { girth = 1.0, arm = 1.0, hunch = 0 }
local rgb = Color3.fromRGB
local PURPLE, PURPLE_DK, GOLD, GOLD_DK, PEARL = rgb(78, 22, 64), rgb(44, 10, 36), rgb(204, 160, 72), rgb(140, 102, 44), rgb(236, 230, 214)
local GEMS = { rgb(170, 18, 30), rgb(24, 110, 60), rgb(30, 64, 160) } -- ruby, emerald, sapphire
local EMBER = rgb(255, 120, 30)
M.Colors = { skin = PURPLE_DK, torso = PURPLE, legs = PURPLE, arms = PURPLE }

local cyl, ball, FACE = Base.cyl, Base.ball, Base.FACE

-- a jewelled band: from p1 to p2 (x, y) on a face at depth z, w wide, gold squares and stones in turn down it
local function jewelBand(k, on, x1, y1, x2, y2, z, w, n)
	local dx, dy = x2 - x1, y2 - y1
	local len, rot = math.sqrt(dx * dx + dy * dy), CFrame.Angles(0, 0, math.atan2(dy, dx))
	k.deco(on, "Loros", k.V(len, w, 0.04), k.at((x1 + x2) / 2, (y1 + y2) / 2, z) * rot, GOLD_DK, k.MAT.Metal)
	for _, e in ipairs({ -1, 1 }) do
		k.deco(on, "LorosEdge", k.V(len, 0.04, 0.05), k.at((x1 + x2) / 2, (y1 + y2) / 2, z) * rot * k.at(0, e * w * 0.45, 0), PEARL, k.MAT.SmoothPlastic)
	end
	for i = 0, n - 1 do
		local t = (i + 0.5) / n
		local c = k.at(x1 + dx * t, y1 + dy * t, z - 0.02) * rot
		if i % 2 == 0 then
			k.deco(on, "LorosPlaque", k.V(w * 0.6, w * 0.6, 0.03), c, GOLD, k.MAT.Metal)
			k.deco(on, "LorosStone", k.V(w * 0.25, w * 0.25, 0.04), c * k.at(0, 0, -0.02) * CFrame.Angles(0, 0, math.pi / 4), GEMS[(i // 2) % 3 + 1], k.MAT.Glass)
		else
			for _, e in ipairs({ -1, 1 }) do
				k.deco(on, "LorosPearl", k.V(0.06, 0.06, 0.06), c * k.at(0, e * w * 0.18, 0), PEARL, k.MAT.SmoothPlastic, ball)
			end
		end
	end
end

function M.Look(k)
	local deco, parts, V, at, MAT = k.deco, k.parts, k.V, k.at, k.MAT
	local cw, ch, cd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.aw, k.lw, k.la, k.ua
	-- THE HEAD: a coif of purple, the mask before it
	parts.Head.Color = PURPLE_DK
	deco("Head", "Coif", V(1.26, 1.3, 1.26), at(0, 0.02, 0.05), PURPLE_DK, MAT.Fabric)
	Base.Mask(k, GOLD, GOLD_DK)
	-- THE CROWN: a band of enamel plaques framed in gold between rows of pearls; a dome of purple over it, crossed by
	-- two straps of pearled gold; a sun for its finial; the pendilia - strings of pearls - at his temples
	local CY = 0.8
	deco("Head", "CrownBand", V(1.38, 0.44, 1.38), at(0, CY, 0.05), GOLD, MAT.Metal)
	for f = 0, 3 do
		local face = at(0, 0, 0.05) * CFrame.Angles(0, f * math.pi / 2, 0)
		for i = -1, 1 do
			deco("Head", "Plaque", V(0.3, 0.26, 0.04), face * at(i * 0.42, CY, -0.7), GEMS[(i + f) % 3 + 1], MAT.Glass)
			deco("Head", "PlaqueFrame", V(0.34, 0.3, 0.03), face * at(i * 0.42, CY, -0.69), GOLD_DK, MAT.Metal)
			deco("Head", "PlaqueStone", V(0.09, 0.09, 0.09), face * at(i * 0.42, CY, -0.74), PEARL, MAT.SmoothPlastic, ball)
		end
		for _, y in ipairs({ CY - 0.24, CY + 0.24 }) do
			for i = 0, 6 do
				deco("Head", "CrownPearl", V(0.07, 0.07, 0.07), face * at(-0.63 + i * 0.21, y, -0.71), PEARL, MAT.SmoothPlastic, ball)
			end
		end
	end
	deco("Head", "Dome", V(1.3, 1.3, 1.3), at(0, CY + 0.25, 0.05), PURPLE, MAT.Fabric, ball)
	for f = 0, 1 do
		local face = at(0, 0, 0.05) * CFrame.Angles(0, f * math.pi / 2, 0)
		for i = 0, 4 do
			local a = (i / 4 - 0.5) * math.pi * 0.9
			local p = face * at(math.sin(a) * 0.66, CY + 0.25 + math.cos(a) * 0.66, 0)
			deco("Head", "DomeStrap", V(0.3, 0.12, 0.16), p * CFrame.Angles(0, 0, -a), GOLD, MAT.Metal)
			deco("Head", "StrapPearl", V(0.07, 0.07, 0.07), p * at(0, 0.07, -0.05), PEARL, MAT.SmoothPlastic, ball)
		end
	end
	deco("Head", "Finial", V(0.2, 0.2, 0.2), at(0, CY + 0.96, 0.05), GOLD, MAT.Metal, ball)
	Base.sun(k, "Head", at(0, CY + 1.22, 0.05), 0.15, GOLD, EMBER)
	for _, sx in ipairs({ -1, 1 }) do
		for s = 0, 2 do
			local x, z = sx * 0.74, -0.25 + s * 0.22
			for i = 0, 5 do
				deco("Head", "Pendilia", V(0.07, 0.07, 0.07), at(x, CY - 0.28 - i * 0.12, z), PEARL, MAT.SmoothPlastic, ball)
			end
			deco("Head", "PendiliaDrop", V(0.09, 0.14, 0.09), at(x, CY - 1.06, z), GEMS[s + 1], MAT.Glass, ball)
		end
	end
	-- THE TUNIC: purple, a gold trellis over it, a stone in every other lozenge
	local fz = -cd * 0.56 - 0.02
	deco("Chest", "Tunic", V(cw * 1.08, ch * 1.02, cd * 1.12), at(0, 0, 0), PURPLE, MAT.Fabric)
	Base.lattice(k, "Chest", cw * 1.0, ch * 0.92, 0, -0.03, fz, 0.28, GOLD)
	Base.brocade(k, "Chest", 0, -0.03, fz - 0.01, 6, 5, 0.28, 0.06, GEMS[1], GEMS[2], MAT.Glass)
	-- THE LOROS: crossed over his breast, shoulder to hip, gathered under a jewelled boss at the waist
	jewelBand(k, "Chest", -cw * 0.4, ch * 0.44, cw * 0.36, -ch * 0.46, fz - 0.04, 0.36, 9)
	jewelBand(k, "Chest", cw * 0.4, ch * 0.44, -cw * 0.36, -ch * 0.46, fz - 0.07, 0.36, 9)
	deco("Chest", "LorosBoss", V(0.1, 0.36, 0.36), at(0, -ch * 0.3, fz - 0.12) * FACE, GOLD, MAT.Metal, cyl)
	deco("Chest", "LorosBossStone", V(0.06, 0.18, 0.18), at(0, -ch * 0.3, fz - 0.17) * FACE, GEMS[1], MAT.Glass, cyl)
	deco("Chest", "Girdle", V(cw * 1.12, 0.2, cd * 1.18), at(0, -ch / 2 + 0.11, 0), GOLD, MAT.Metal)
	Base.studs(k, "Chest", 9, -cw * 0.5, cw * 0.5, -ch / 2 + 0.11, -cd * 0.6 - 0.02, 0.07, PEARL, MAT.SmoothPlastic)
	-- THE COLLAR: a wide disc of gold round his neck over the shoulders, two rings of stones on it, pearls round its edge
	deco("Chest", "Collar", V(0.14, 1.85, 1.85), at(0, ch / 2 + 0.02, 0.02) * CFrame.Angles(0, 0, math.pi / 2), GOLD, MAT.Metal, cyl)
	deco("Chest", "CollarInner", V(0.15, 1.2, 1.1), at(0, ch / 2 + 0.03, 0.02) * CFrame.Angles(0, 0, math.pi / 2), PURPLE_DK, MAT.Fabric, cyl)
	for ring, r in ipairs({ { 0.72, 0.64, 12 }, { 0.94, 0.84, 18 } }) do
		for i = 0, r[3] - 1 do
			local a = i / r[3] * math.pi * 2
			deco("Chest", ring == 1 and "CollarStone" or "CollarPearl", V(0.09, 0.09, 0.09), at(math.sin(a) * r[1], ch / 2 + 0.1, 0.02 - math.cos(a) * r[2]), ring == 1 and GEMS[i % 3 + 1] or PEARL, ring == 1 and MAT.Glass or MAT.SmoothPlastic, ball)
		end
	end
	-- THE SLEEVES: close purple, the gold tablion on each upper arm, broad jewelled cuffs, rings
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		deco(n .. "UpperArm", "Sleeve", V(aw * 1.35, ua * 0.95, aw * 1.35), at(0, 0, 0), PURPLE, MAT.Fabric)
		deco(n .. "UpperArm", "Tablion", V(0.34, 0.34, 0.04), at(sx * aw * 0.2, ua * 0.1, -aw * 0.7), GOLD, MAT.Metal)
		deco(n .. "UpperArm", "TablionStone", V(0.12, 0.12, 0.05), at(sx * aw * 0.2, ua * 0.1, -aw * 0.72) * CFrame.Angles(0, 0, math.pi / 4), GEMS[3], MAT.Glass)
		for _, y in ipairs({ ua * 0.38, -ua * 0.38 }) do
			deco(n .. "UpperArm", "ArmBand", V(aw * 1.4, 0.1, aw * 1.4), at(0, y, 0), GOLD, MAT.Metal)
		end
		deco(n .. "LowerArm", "Sleeve", V(aw * 1.28, la * 0.8, aw * 1.28), at(0, 0.08, 0), PURPLE, MAT.Fabric)
		deco(n .. "LowerArm", "Cuff", V(aw * 1.5, la * 0.32, aw * 1.5), at(0, -la * 0.3, 0), GOLD, MAT.Metal)
		for f = 0, 3 do
			local face = CFrame.Angles(0, f * math.pi / 2, 0)
			deco(n .. "LowerArm", "CuffStone", V(0.11, 0.11, 0.05), face * at(0, -la * 0.3, -aw * 0.77) * CFrame.Angles(0, 0, math.pi / 4), GEMS[f % 3 + 1], MAT.Glass)
			for i = -1, 1 do
				deco(n .. "LowerArm", "CuffPearl", V(0.05, 0.05, 0.05), face * at(i * aw * 0.5, -la * 0.16, -aw * 0.76), PEARL, MAT.SmoothPlastic, ball)
			end
		end
		deco(n .. "LowerArm", "Ring", V(0.13, 0.13, 0.13), at(sx * aw * 0.3, -la / 2 - 0.2, -aw * 0.5), GEMS[n == "R" and 1 or 2], MAT.Glass, ball)
	end
	-- THE LAP: purple to the floor, gold-hemmed, the diaper of stones over it, the loros hung down between his knees
	Base.lapRobe(k, PURPLE, GOLD, GOLD_DK, PURPLE_DK)
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		Base.lattice(k, n .. "Thigh", lw * 1.6, 1.2, -sx * 0.07, 0, -lw * 0.66, 0.28, GOLD)
		Base.lattice(k, n .. "Shin", lw * 1.6, 1.0, -sx * 0.07, 0.02, -lw * 0.63, 0.28, GOLD)
	end
	local tx = -k.D.hipX / k.s -- (from the right shin, over to between the knees)
	jewelBand(k, "RShin", tx, 0.55, tx, -0.55, -lw * 0.72, 0.4, 7)
	jewelBand(k, "Hips", 0, 0.3, 0, -0.1, -k.hd * 0.62, 0.4, 2)
	-- THE ORB, held up in his left hand: gold, banded round and over, jewelled, a sun on top (KingSitOrb)
	local G = at(0, -la / 2 - 0.15, -0.36) * CFrame.Angles(-math.pi / 2, 0, 0) -- (+Y up off the raised forearm)
	deco("LLowerArm", "Orb", V(0.62, 0.62, 0.62), G, GOLD, MAT.Metal, ball)
	deco("LLowerArm", "OrbBand", V(0.1, 0.66, 0.66), G * CFrame.Angles(0, 0, math.pi / 2), GOLD_DK, MAT.Metal, cyl)
	deco("LLowerArm", "OrbBand", V(0.1, 0.66, 0.66), G * FACE, GOLD_DK, MAT.Metal, cyl)
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		deco("LLowerArm", "OrbStone", V(0.08, 0.08, 0.08), G * at(math.cos(a) * 0.33, 0, math.sin(a) * 0.33), GEMS[i % 3 + 1], MAT.Glass, ball)
	end
	deco("LLowerArm", "OrbNeck", V(0.12, 0.12, 0.12), G * at(0, 0.36, 0), GOLD_DK, MAT.Metal)
	Base.sun(k, "LLowerArm", G * at(0, 0.6, 0), 0.18, GOLD, EMBER)
end

return M
