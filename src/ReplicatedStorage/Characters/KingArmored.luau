--!nonstrict
-- THE KING OF PYRALIS - proposal B of five (kind KingArmored): THE SUN-FORGED WARLORD. The king as the general who
-- built the Bulwark: plate of blackened steel etched all over in gold - chevrons down every edge, rivets on every
-- lame - a closed helm the sun-mask is his visor on, a circlet of flame-points round its brow; a gorget of rings,
-- pauldrons of five lames, a breastplate ridged with a burning sun-boss; a crimson tabard over the knees with the sun
-- on it; a crimson cloak with a collar of fur clasped by sun-brooches; his sword laid across his knees.
-- (Shared pose, mask and spawn: Characters/KingGilded.)
local Base = require(script.Parent:WaitForChild("KingGilded"))

local M = table.clone(Base)
M.Kind = "KingArmored"
M.Proportions = { girth = 1.15, arm = 1.05, hunch = 0 }
local rgb = Color3.fromRGB
local STEEL, STEEL_DK, GOLD, GOLD_DK = rgb(42, 38, 38), rgb(22, 20, 20), rgb(196, 148, 62), rgb(130, 92, 38)
local CRIM, CRIM_DK, FUR, FUR_DK, EMBER, LEATHER = rgb(120, 20, 18), rgb(72, 10, 10), rgb(92, 76, 62), rgb(58, 46, 38), rgb(255, 120, 30), rgb(44, 30, 22)
M.Colors = { skin = STEEL_DK, torso = STEEL, legs = STEEL, arms = STEEL }

local cyl, ball, FACE = Base.cyl, Base.ball, Base.FACE

-- gold chevrons etched down an edge: a column of little V's from y1 to y2 at x, on a face at depth z
local function chevrons(k, on, x, y1, y2, z, n, w)
	for i = 0, n - 1 do
		local y = y1 + (y2 - y1) * i / math.max(n - 1, 1)
		for _, sx in ipairs({ -1, 1 }) do
			k.deco(on, "Etch", k.V(w, 0.035, 0.02), k.at(x + sx * w * 0.35, y, z) * CFrame.Angles(0, 0, sx * 0.6), GOLD, k.MAT.Metal)
		end
	end
end

function M.Look(k)
	local deco, parts, V, at, MAT = k.deco, k.parts, k.V, k.at, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local fx = k.D.footSize.X / k.s
	-- THE HELM: closed, a gold-edged comb down its crown, cheek-plates, the mask its visor; a circlet of flame-points
	parts.Head.Color = STEEL_DK
	deco("Head", "Helm", V(1.3, 1.4, 1.32), at(0, 0.05, 0.03), STEEL, MAT.Metal)
	deco("Head", "HelmComb", V(0.14, 0.32, 1.38), at(0, 0.84, 0.03), STEEL_DK, MAT.Metal)
	deco("Head", "HelmCombEdge", V(0.16, 0.05, 1.4), at(0, 1.0, 0.03), GOLD, MAT.Metal)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "CheekPlate", V(0.08, 0.9, 1.0), at(sx * 0.68, -0.15, 0.0), STEEL_DK, MAT.Metal)
		for j = 0, 2 do
			deco("Head", "CheekRivet", V(0.07, 0.07, 0.07), at(sx * 0.73, 0.15 - j * 0.3, -0.38), GOLD, MAT.Metal, ball)
		end
		deco("Head", "BreathHoles", V(0.04, 0.35, 0.04), at(sx * 0.73, -0.35, -0.1), STEEL_DK, MAT.SmoothPlastic)
	end
	Base.Mask(k, GOLD, GOLD_DK, rgb(255, 170, 60))
	deco("Head", "Circlet", V(1.42, 0.16, 1.42), at(0, 0.62, 0.03), GOLD, MAT.Metal)
	for i = 0, 13 do -- the flame-points: blade-shapes leaning out, long and short
		local a = i / 14 * math.pi * 2
		local h = i % 2 == 0 and 0.55 or 0.32
		local p = at(math.sin(a) * 0.72, 0.62 + 0.08 + h / 2, 0.03 - math.cos(a) * 0.72)
		deco("Head", "FlamePoint", V(0.1, h, 0.05), p * CFrame.Angles(0, -a, 0) * CFrame.Angles(-0.25, 0, 0), i % 2 == 0 and GOLD or GOLD_DK, MAT.Metal)
	end
	-- THE GORGET: three rings stepping out, gold-edged
	for i = 0, 2 do
		local w = 1.5 + i * 0.22
		deco("Head", "Gorget", V(w, 0.2, w * 0.92), at(0, -0.7 - i * 0.15, 0.03), i == 1 and STEEL or STEEL_DK, MAT.Metal)
		deco("Head", "GorgetEdge", V(w + 0.02, 0.04, w * 0.92 + 0.02), at(0, -0.62 - i * 0.15, 0.03), GOLD, MAT.Metal)
	end
	-- THE BREASTPLATE: a ridge down it, its edges etched in chevrons, the sun-boss burning at its heart; plackart below
	local fz = -cd * 0.6
	deco("Chest", "Breastplate", V(cw * 1.08, ch * 1.02, cd * 1.18), at(0, 0, 0), STEEL, MAT.Metal)
	deco("Chest", "Ridge", V(0.1, ch * 0.95, 0.1), at(0, 0, fz - 0.02), STEEL_DK, MAT.Metal)
	for _, sx in ipairs({ -1, 1 }) do
		chevrons(k, "Chest", sx * cw * 0.46, -ch * 0.42, ch * 0.42, fz - 0.01, 8, 0.12)
		chevrons(k, "Chest", sx * 0.16, -ch * 0.42, -0.25, fz - 0.03, 4, 0.1)
		deco("Chest", "BreastEdge", V(0.05, ch * 0.98, 0.04), at(sx * cw * 0.53, 0, fz), GOLD, MAT.Metal)
	end
	for _, sx in ipairs({ -1, 1 }) do
		for j = 0, 4 do
			deco("Chest", "Rivet", V(0.07, 0.07, 0.07), at(sx * cw * 0.5, -ch * 0.4 + j * ch * 0.2, fz - 0.02), GOLD_DK, MAT.Metal, ball)
		end
	end
	deco("Chest", "NeckEdge", V(cw * 0.6, 0.08, 0.05), at(0, ch / 2 - 0.04, fz), GOLD, MAT.Metal)
	deco("Chest", "SunBossRim", V(0.12, 0.72, 0.72), at(0, 0.18, fz - 0.03) * FACE, GOLD_DK, MAT.Metal, cyl)
	Base.sun(k, "Chest", at(0, 0.18, fz - 0.1), 0.34, GOLD, EMBER)
	local b = deco("Chest", "SunBossGlow", V(0.2, 0.2, 0.2), at(0, 0.18, fz + 0.1), EMBER, MAT.Neon)
	b.Transparency = 1
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = EMBER, 9, 1.1
	l.Parent = b
	for i = 0, 2 do -- the plackart: lames lapping up the belly, each gold-edged
		local y = -ch * 0.3 - i * 0.16
		deco("Chest", "Plackart", V(cw * (0.9 - i * 0.06), 0.18, 0.06), at(0, y, fz - 0.04), STEEL_DK, MAT.Metal)
		deco("Chest", "PlackartEdge", V(cw * (0.9 - i * 0.06), 0.035, 0.07), at(0, y + 0.09, fz - 0.04), GOLD, MAT.Metal)
	end
	-- THE CLOAK: crimson, gold-bordered, over the back and the shoulders, a collar of fur, two sun-brooches clasping it
	deco("Chest", "CloakShoulders", V(cw * 1.28, 0.3, cd * 1.4), at(0, ch / 2 - 0.05, 0.12), CRIM, MAT.Fabric)
	deco("Chest", "CloakBack", V(cw * 1.25, ch * 1.2, 0.12), at(0, -0.15, cd * 0.66), CRIM, MAT.Fabric)
	for i = 0, 15 do -- the fur collar: clumps round the neck, two shades
		local a = (i / 15 - 0.5) * math.pi * 1.5
		deco("Chest", "Fur", V(0.36, 0.3, 0.36), at(math.sin(a) * 0.72, ch / 2 + 0.12 + (i % 2) * 0.06, math.cos(a) * 0.45 + 0.12), i % 2 == 0 and FUR or FUR_DK, MAT.Fabric, ball)
	end
	for _, sx in ipairs({ -1, 1 }) do
		Base.sun(k, "Chest", at(sx * cw * 0.42, ch / 2 - 0.12, -cd * 0.72), 0.18, GOLD, EMBER)
		deco("Chest", "CloakFront", V(0.24, ch * 0.9, 0.06), at(sx * cw * 0.62, -0.05, -cd * 0.3), CRIM, MAT.Fabric)
		deco("Chest", "CloakBorder", V(0.06, ch * 0.9, 0.07), at(sx * cw * 0.62 - sx * 0.12, -0.05, -cd * 0.3), GOLD, MAT.Metal)
	end
	-- THE ARMS: pauldrons of five lames, each gold-edged and riveted; rerebraces, couters with a fan, vambraces
	-- banded in gold, gauntlets with knuckle-studs, a signet over one
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		for j = 0, 4 do
			local y = ua * (0.5 - j * 0.13)
			local w = aw * (2.2 - j * 0.12)
			deco(n .. "UpperArm", "Pauldron", V(w, 0.24, w * 0.95), at(sx * 0.12, y, 0) * CFrame.Angles(0, 0, -sx * 0.32), j == 0 and STEEL_DK or STEEL, MAT.Metal)
			deco(n .. "UpperArm", "PauldronEdge", V(w + 0.02, 0.04, w * 0.95 + 0.02), at(sx * 0.12, y - 0.1, 0) * CFrame.Angles(0, 0, -sx * 0.32), GOLD, MAT.Metal)
			deco(n .. "UpperArm", "PauldronRivet", V(0.06, 0.06, 0.06), at(sx * 0.12, y, -w * 0.48), GOLD_DK, MAT.Metal, ball)
		end
		Base.sun(k, n .. "UpperArm", at(sx * 0.2, ua * 0.38, -aw * 1.12), 0.14, GOLD)
		deco(n .. "UpperArm", "Rerebrace", V(aw * 1.25, ua * 0.6, aw * 1.25), at(0, -ua * 0.15, 0), STEEL, MAT.Metal)
		for _, y in ipairs({ -ua * 0.05, -ua * 0.4 }) do
			deco(n .. "UpperArm", "ArmBand", V(aw * 1.3, 0.05, aw * 1.3), at(0, y, 0), GOLD, MAT.Metal)
		end
		deco(n .. "LowerArm", "Couter", V(aw * 1.15, aw * 1.15, aw * 1.15), at(0, la * 0.45, 0.06), STEEL_DK, MAT.Metal, ball)
		deco(n .. "LowerArm", "CouterFan", V(0.06, aw * 1.3, aw * 1.3), at(sx * aw * 0.62, la * 0.45, 0.06), STEEL, MAT.Metal, cyl)
		deco(n .. "LowerArm", "CouterStud", V(0.09, 0.09, 0.09), at(sx * aw * 0.67, la * 0.45, 0.06), GOLD, MAT.Metal, ball)
		deco(n .. "LowerArm", "Vambrace", V(aw * 1.3, la * 0.62, aw * 1.3), at(0, 0, 0), STEEL, MAT.Metal)
		for _, y in ipairs({ la * 0.28, 0, -la * 0.28 }) do
			deco(n .. "LowerArm", "VambraceBand", V(aw * 1.35, 0.05, aw * 1.35), at(0, y, 0), GOLD, MAT.Metal)
		end
		deco(n .. "LowerArm", "Gauntlet", V(aw * 1.45, 0.5, aw * 1.4), at(0, -la * 0.45, 0), STEEL_DK, MAT.Metal)
		deco(n .. "LowerArm", "GauntletCuff", V(aw * 1.55, 0.06, aw * 1.5), at(0, -la * 0.32, 0), GOLD, MAT.Metal)
		Base.studs(k, n .. "LowerArm", 4, -aw * 0.45, aw * 0.45, -la / 2 - 0.2, -aw * 0.72, 0.07, GOLD_DK)
	end
	deco("RLowerArm", "Signet", V(0.16, 0.12, 0.16), at(aw * 0.3, -la / 2 - 0.08, -aw * 0.72), GOLD, MAT.Metal)
	-- THE LEGS: faulds round the hips; tassets lapping down each thigh; cuisses, poleyns with a sun-rosette and a fan,
	-- greaves ridged and gold-banded, sabatons of lames
	for i = 0, 2 do
		deco("Hips", "Fauld", V(hw * (1.2 + i * 0.04), 0.2, hd * (1.25 + i * 0.04)), at(0, 0.28 - i * 0.18, 0), i % 2 == 0 and STEEL or STEEL_DK, MAT.Metal)
		deco("Hips", "FauldEdge", V(hw * (1.22 + i * 0.04), 0.04, hd * (1.27 + i * 0.04)), at(0, 0.19 - i * 0.18, 0), GOLD, MAT.Metal)
	end
	deco("Hips", "SwordBelt", V(hw * 1.32, 0.12, hd * 1.38), at(0, 0.42, 0), LEATHER, MAT.Leather)
	Base.studs(k, "Hips", 7, -hw * 0.5, hw * 0.5, 0.42, -hd * 0.7, 0.07, GOLD)
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		deco(n .. "Thigh", "Cuisse", V(lw * 1.25, 1.1, lw * 1.25), at(0, 0, 0), STEEL, MAT.Metal)
		for j = 0, 2 do -- the tassets (on top of the thigh: its -Z, now he's sat)
			local y = 0.42 - j * 0.24
			deco(n .. "Thigh", "Tasset", V(lw * 1.5, 0.3, 0.07), at(0, y, -lw * 0.68 - j * 0.02), STEEL_DK, MAT.Metal)
			deco(n .. "Thigh", "TassetEdge", V(lw * 1.52, 0.04, 0.08), at(0, y - 0.14, -lw * 0.69 - j * 0.02), GOLD, MAT.Metal)
			Base.studs(k, n .. "Thigh", 3, -lw * 0.55, lw * 0.55, y + 0.05, -lw * 0.73 - j * 0.02, 0.06, GOLD_DK)
		end
		deco(n .. "Thigh", "CuisseBand", V(lw * 1.3, 0.05, lw * 1.3), at(0, -0.3, 0), GOLD, MAT.Metal)
		deco(n .. "Shin", "Poleyn", V(lw * 1.2, lw * 1.2, lw * 1.2), at(0, 0.55, -0.05), STEEL_DK, MAT.Metal, ball)
		Base.sun(k, n .. "Shin", at(0, 0.55, -lw * 0.64), 0.16, GOLD)
		deco(n .. "Shin", "PoleynFan", V(0.06, lw * 1.25, lw * 1.25), at(sx * lw * 0.62, 0.55, -0.05), STEEL, MAT.Metal, cyl)
		deco(n .. "Shin", "Greave", V(lw * 1.22, 0.95, lw * 1.22), at(0, -0.1, 0), STEEL, MAT.Metal)
		deco(n .. "Shin", "GreaveRidge", V(0.08, 0.9, 0.08), at(0, -0.1, -lw * 0.62) * CFrame.Angles(0, math.pi / 4, 0), STEEL_DK, MAT.Metal)
		for _, y in ipairs({ 0.25, -0.45 }) do
			deco(n .. "Shin", "GreaveBand", V(lw * 1.26, 0.05, lw * 1.26), at(0, y, 0), GOLD, MAT.Metal)
		end
		chevrons(k, n .. "Shin", lw * 0.4, -0.38, 0.18, -lw * 0.62, 3, 0.08)
		chevrons(k, n .. "Shin", -lw * 0.4, -0.38, 0.18, -lw * 0.62, 3, 0.08)
		for j = 0, 2 do
			deco(n .. "Foot", "Sabaton", V(fx * 1.15, 0.2, 0.42), at(0, 0.08 + j * 0.02, 0.3 - j * 0.34), j % 2 == 0 and STEEL or STEEL_DK, MAT.Metal)
			deco(n .. "Foot", "SabatonEdge", V(fx * 1.18, 0.04, 0.05), at(0, 0.16 + j * 0.02, 0.1 - j * 0.34), GOLD, MAT.Metal)
		end
	end
	-- THE TABARD: crimson, hung from the belt over his knees to his shins, gold-bordered, the sun on it
	local tx = -k.D.hipX / k.s -- (from the right shin, over to between the knees)
	deco("RShin", "Tabard", V(1.25, 0.95, 0.06), at(tx, 0.0, -lw * 0.75), CRIM, MAT.Fabric)
	deco("RShin", "TabardBorder", V(1.31, 0.06, 0.07), at(tx, -0.48, -lw * 0.75), GOLD, MAT.Metal)
	for _, ex in ipairs({ -0.64, 0.64 }) do
		deco("RShin", "TabardBorder", V(0.06, 0.95, 0.07), at(tx + ex, 0, -lw * 0.75), GOLD, MAT.Metal)
	end
	for i = 0, 9 do
		deco("RShin", "TabardFringe", V(0.05, 0.16, 0.03), at(tx - 0.56 + i * 0.125, -0.58, -lw * 0.75), GOLD_DK, MAT.Fabric)
	end
	Base.sun(k, "RShin", at(tx, 0.06, -lw * 0.8), 0.3, GOLD, EMBER)
	deco("Hips", "TabardTop", V(1.25, 0.06, 1.1), at(0, -0.02 + 0.33, -0.7), CRIM, MAT.Fabric)
	-- THE SWORD across his knees (on the hips: they don't tilt as he sits), its hilt by his right hand
	local sy, sz = -0.15 + lw * 0.62 + 0.14, -0.78
	deco("Hips", "Blade", V(2.5, 0.07, 0.3), at(-0.55, sy, sz), rgb(150, 146, 140), MAT.Metal)
	deco("Hips", "BladeFuller", V(2.2, 0.08, 0.06), at(-0.45, sy, sz), EMBER, MAT.Neon)
	for i = 0, 5 do
		deco("Hips", "BladeRune", V(0.08, 0.09, 0.12), at(-1.4 + i * 0.34, sy, sz + 0.06), GOLD, MAT.Metal)
	end
	deco("Hips", "BladeTip", V(0.22, 0.07, 0.22), at(-1.82, sy, sz) * CFrame.Angles(0, math.pi / 4, 0), rgb(150, 146, 140), MAT.Metal)
	deco("Hips", "Crossguard", V(0.14, 0.14, 1.0), at(0.75, sy, sz), GOLD, MAT.Metal)
	for _, e in ipairs({ -0.5, 0.5 }) do
		deco("Hips", "QuillonEnd", V(0.16, 0.16, 0.16), at(0.75, sy, sz + e), GOLD_DK, MAT.Metal, ball)
	end
	deco("Hips", "Grip", V(0.55, 0.13, 0.13), at(1.1, sy, sz), LEATHER, MAT.Leather)
	for i = 0, 3 do
		deco("Hips", "GripWire", V(0.03, 0.15, 0.15), at(0.9 + i * 0.13, sy, sz), GOLD_DK, MAT.Metal)
	end
	deco("Hips", "Pommel", V(0.06, 0.26, 0.26), at(1.42, sy, sz), GOLD, MAT.Metal, cyl)
	deco("Hips", "PommelStone", V(0.07, 0.12, 0.12), at(1.45, sy, sz), EMBER, MAT.Neon, cyl)
end

return M
