--!nonstrict
-- THE KING OF PYRALIS stood up: the pieces for blends of proposal B (KingArmored, the Sun-Forged Warlord) and
-- proposal C (KingPontiff, the Sun-Pontiff). Of the five blends made, the one chosen is KingInquisitor (blackened
-- plate shaped to a man, an orphreyed tabard, a steel tiara-helm, a sun-wheel glaive); KingGilded.spawnStanding stands
-- him in the palace's forecourt and spawnStatues makes every statue in the palace of him. (Some pieces here - the
-- alb, bell sleeves, chasuble, morse, sword, censer, sunburst - were the other four's, kept for now.)
-- This file is no character itself (no Kind: the Roster passes it over): it holds the standing pose and the pieces
-- he is built from - each a part of B or C, reworked to hang right on a king stood up (a cope and alb to the
-- floor, a staff and a sword that reach it). Every measure is in the rig's unscaled units, like k.V / k.at.
local Base = require(script.Parent:WaitForChild("KingGilded"))
local H = {}

local rgb = Color3.fromRGB
local cyl, ball, FACE = Base.cyl, Base.ball, Base.FACE
local UP = CFrame.Angles(0, 0, math.pi / 2) -- (a cylinder stood on end: a disc lying flat)

H.Scale = Base.Scale * 1.6 -- (the chosen king, 2/3 the blends' first size)
H.Poses = {
	-- stood tall, a touch back on his heels, both forearms out before him (a staff upright in one fist, a sword's
	-- pommel or a censer's chains in the other)
	KingStand = { drop = 0.05, lean = -0.04, head = 0.1, footR = 0, footL = 0, spread = 0.12, la1 = 0.15, la3 = -0.1, lel = 1.42, ra1 = 0.15, ra3 = 0.1, rel = 1.42, freeL = 0, breathe = 0.5 },
	-- the same, the left arm down at his side
	KingStandR = { drop = 0.05, lean = -0.04, head = 0.1, footR = 0, footL = 0, spread = 0.12, la1 = 0.04, la3 = -0.1, lel = 0.15, ra1 = 0.15, ra3 = 0.1, rel = 1.42, freeL = 0, breathe = 0.5 },
}

-- the palettes the two proposals were made in
H.B = { metal = rgb(42, 38, 38), metalDk = rgb(22, 20, 20), gold = rgb(196, 148, 62), goldDk = rgb(130, 92, 38), cloth = rgb(120, 20, 18), clothDk = rgb(72, 10, 10), fur = rgb(92, 76, 62), furDk = rgb(58, 46, 38), ember = rgb(255, 120, 30), leather = rgb(44, 30, 22) }
H.C = { ivory = rgb(226, 214, 190), ivoryDk = rgb(176, 162, 136), cloth = rgb(118, 20, 24), clothDk = rgb(66, 10, 14), gold = rgb(200, 154, 68), goldDk = rgb(136, 96, 40), sun = rgb(255, 200, 90), flame = rgb(255, 110, 30), panel = { rgb(30, 54, 120), rgb(150, 24, 30), rgb(36, 86, 50) } }

-- a new kind on the shared base: standing, at H.Scale
function H.new(kind, proportions, colors, pose, look)
	local M = table.clone(Base)
	M.Kind, M.Proportions, M.Colors = kind, proportions, colors
	M.Scale, M.IdlePose, M.Poses = H.Scale, pose, H.Poses
	M.Look = look
	return M
end

local function light(k, on, cf, col, range, bright)
	local g = k.deco(on, "Glow", k.V(0.1, 0.1, 0.1), cf, col, k.MAT.Neon)
	g.Transparency = 1
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = col, range * k.s / Base.Scale, bright -- (reach grown with him)
	l.Parent = g
	return g
end
local function fire(k, part, size, heat, col, col2)
	local f = Instance.new("Fire")
	f.Size, f.Heat = size * k.s / Base.Scale, heat
	f.Color, f.SecondaryColor = col, col2 or rgb(120, 20, 6)
	f.Parent = part
end

-- gold chevrons etched down an edge (B's)
function H.chevrons(k, on, x, y1, y2, z, n, w, gold)
	for i = 0, n - 1 do
		local y = y1 + (y2 - y1) * i / math.max(n - 1, 1)
		for _, sx in ipairs({ -1, 1 }) do
			k.deco(on, "Etch", k.V(w, 0.035, 0.02), k.at(x + sx * w * 0.35, y, z) * CFrame.Angles(0, 0, sx * 0.6), gold, k.MAT.Metal)
		end
	end
end

---------------------------------------------------------------------------
-- HEADS
---------------------------------------------------------------------------
-- B's closed helm: a comb (unless crowned over it), cheek-plates riveted, breaths; the sun-mask is its visor
function H.helm(k, c, comb)
	local deco, V, at, MAT = k.deco, k.V, k.at, k.MAT
	k.parts.Head.Color = c.metalDk
	deco("Head", "Helm", V(1.3, 1.4, 1.32), at(0, 0.05, 0.03), c.metal, MAT.Metal)
	if comb then
		deco("Head", "HelmComb", V(0.14, 0.32, 1.38), at(0, 0.84, 0.03), c.metalDk, MAT.Metal)
		deco("Head", "HelmCombEdge", V(0.16, 0.05, 1.4), at(0, 1.0, 0.03), c.gold, MAT.Metal)
	end
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "CheekPlate", V(0.08, 0.9, 1.0), at(sx * 0.68, -0.15, 0.0), c.metalDk, MAT.Metal)
		for j = 0, 2 do
			deco("Head", "CheekRivet", V(0.07, 0.07, 0.07), at(sx * 0.73, 0.15 - j * 0.3, -0.38), c.gold, MAT.Metal, ball)
		end
		deco("Head", "BreathHoles", V(0.04, 0.35, 0.04), at(sx * 0.73, -0.35, -0.1), c.metalDk, MAT.SmoothPlastic)
	end
	Base.Mask(k, c.gold, c.goldDk, rgb(255, 170, 60))
end
-- B's circlet of flame-points round the brow, at height y
function H.circlet(k, c, y, r)
	r = r or 0.72
	k.deco("Head", "Circlet", k.V(r * 2 - 0.02, 0.16, r * 2 - 0.02), k.at(0, y, 0.03), c.gold, k.MAT.Metal)
	for i = 0, 13 do
		local a = i / 14 * math.pi * 2
		local h = i % 2 == 0 and 0.55 or 0.32
		local p = k.at(math.sin(a) * r, y + 0.08 + h / 2, 0.03 - math.cos(a) * r)
		k.deco("Head", "FlamePoint", k.V(0.1, h, 0.05), p * CFrame.Angles(0, -a, 0) * CFrame.Angles(-0.25, 0, 0), i % 2 == 0 and c.gold or c.goldDk, k.MAT.Metal)
	end
end
-- C's triple tiara from y0 up: a drum narrowing in tiers (drum: its colour), three coronets of gold - band, gems,
-- points (flames: B's flame-points instead of C's little ones) - an orb and a sun on top
function H.tiara(k, c, y0, drum, gems, flames)
	local deco, V, at, MAT = k.deco, k.V, k.at, k.MAT
	for i = 0, 6 do
		local d = 1.3 - i * 0.1
		deco("Head", "Tiara", V(0.32, d, d), at(0, y0 + i * 0.3, 0.06) * UP, drum, i % 2 == 0 and MAT.Fabric or MAT.Metal, cyl)
	end
	for t = 0, 2 do
		local y, d = y0 - 0.02 + t * 0.66, 1.36 - t * 0.2
		deco("Head", "Coronet", V(0.2, d, d), at(0, y, 0.06) * UP, c.gold, MAT.Metal, cyl)
		deco("Head", "CoronetRim", V(0.05, d + 0.04, d + 0.04), at(0, y + 0.1, 0.06) * UP, c.goldDk, MAT.Metal, cyl)
		local n = 10 - t * 2
		for i = 0, n - 1 do
			local a = i / n * math.pi * 2
			local r = d / 2
			deco("Head", "CoronetGem", V(0.1, 0.1, 0.06), at(math.sin(a) * r, y, 0.06 - math.cos(a) * r) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, math.pi / 4), gems[i % #gems + 1], MAT.Glass)
			local h = flames and (i % 2 == 0 and 0.36 or 0.24) or 0.22
			deco("Head", "CoronetPoint", V(0.09, h, 0.04), at(math.sin(a) * r, y + 0.1 + h / 2, 0.06 - math.cos(a) * r) * CFrame.Angles(0, -a, 0) * (flames and CFrame.Angles(-0.25, 0, 0) or CFrame.Angles(0, 0, math.pi / 4)), c.gold, MAT.Metal)
		end
	end
	deco("Head", "TiaraOrb", V(0.28, 0.28, 0.28), at(0, y0 + 2.03, 0.06), c.gold, MAT.Metal, ball)
	Base.sun(k, "Head", at(0, y0 + 2.33, 0.06), 0.18, c.gold, c.flame or c.ember)
end
-- C's lappets down the back of the head to the shoulders, a sun on each, gold fringe at the foot
function H.lappets(k, col, gold, sunCol, z)
	for _, sx in ipairs({ -1, 1 }) do
		k.deco("Head", "Lappet", k.V(0.26, 1.3, 0.05), k.at(sx * 0.3, -0.35, z), col, k.MAT.Fabric)
		k.deco("Head", "LappetBand", k.V(0.28, 0.06, 0.06), k.at(sx * 0.3, -0.92, z), gold, k.MAT.Metal)
		Base.sun(k, "Head", k.at(sx * 0.3, -0.6, z + 0.03) * CFrame.Angles(0, math.pi, 0), 0.08, sunCol)
		for i = 0, 4 do
			k.deco("Head", "LappetFringe", k.V(0.04, 0.14, 0.03), k.at(sx * 0.3 - 0.1 + i * 0.05, -1.05, z), gold, k.MAT.Metal)
		end
	end
end
-- C's halo: a ring of fire behind the head (r its radius; blades: B's flame-points, leaning out, for its pieces)
function H.halo(k, c, r, y, z, blades)
	for i = 0, 23 do
		local a = i / 24 * math.pi * 2
		local h = blades and (i % 2 == 0 and 0.7 or 0.42) or 0.4
		local p = k.deco("Head", "Halo", k.V(0.18, h, 0.18), k.at(math.cos(a) * r, y + math.sin(a) * r, z) * CFrame.Angles(0, 0, a - (blades and math.pi / 2 or 0)), c.sun or c.ember, k.MAT.Neon)
		if i % 4 == 0 then
			fire(k, p, 1.6, 4, c.flame or c.ember)
		end
	end
	light(k, "Head", k.at(0, y, z), c.flame or c.ember, 14, 1.5)
end
-- a sunburst crest: gold rays fanned up and out behind the helm, long and short, a burning boss at their root
function H.sunburst(k, c, y, z)
	for i = 0, 12 do
		local a = math.pi * (0.1 + i / 12 * 0.8)
		local len = i % 2 == 0 and 1.5 or 1.0
		local cf = k.at(math.cos(a) * (0.55 + len / 2), y + math.sin(a) * (0.55 + len / 2), z) * CFrame.Angles(0, 0, a - math.pi / 2)
		k.deco("Head", "Ray", k.V(0.16, len, 0.06), cf, i % 2 == 0 and c.gold or c.goldDk, k.MAT.Metal)
	end
	k.deco("Head", "BurstBoss", k.V(0.12, 0.6, 0.6), k.at(0, y, z) * FACE, c.gold, k.MAT.Metal, cyl)
	k.deco("Head", "BurstHeart", k.V(0.14, 0.32, 0.32), k.at(0, y, z - 0.02) * FACE, c.ember, k.MAT.Neon, cyl)
end

---------------------------------------------------------------------------
-- BODIES
---------------------------------------------------------------------------
-- B's gorget: three rings stepping out
function H.gorget(k, c)
	for i = 0, 2 do
		local w = 1.5 + i * 0.22
		k.deco("Head", "Gorget", k.V(w, 0.2, w * 0.92), k.at(0, -0.7 - i * 0.15, 0.03), i == 1 and c.metal or c.metalDk, k.MAT.Metal)
		k.deco("Head", "GorgetEdge", k.V(w + 0.02, 0.04, w * 0.92 + 0.02), k.at(0, -0.62 - i * 0.15, 0.03), c.gold, k.MAT.Metal)
	end
end
-- B's breastplate: a ridge, chevroned edges, a burning sun-boss, the plackart
function H.breastplate(k, c)
	local deco, V, at, MAT = k.deco, k.V, k.at, k.MAT
	local cw, ch, cd = k.cw, k.ch, k.cd
	local fz = -cd * 0.6
	deco("Chest", "Breastplate", V(cw * 1.08, ch * 1.02, cd * 1.18), at(0, 0, 0), c.metal, MAT.Metal)
	deco("Chest", "Ridge", V(0.1, ch * 0.95, 0.1), at(0, 0, fz - 0.02), c.metalDk, MAT.Metal)
	for _, sx in ipairs({ -1, 1 }) do
		H.chevrons(k, "Chest", sx * cw * 0.46, -ch * 0.42, ch * 0.42, fz - 0.01, 8, 0.12, c.gold)
		deco("Chest", "BreastEdge", V(0.05, ch * 0.98, 0.04), at(sx * cw * 0.53, 0, fz), c.gold, MAT.Metal)
		for j = 0, 4 do
			deco("Chest", "Rivet", V(0.07, 0.07, 0.07), at(sx * cw * 0.5, -ch * 0.4 + j * ch * 0.2, fz - 0.02), c.goldDk, MAT.Metal, ball)
		end
	end
	deco("Chest", "SunBossRim", V(0.12, 0.72, 0.72), at(0, 0.18, fz - 0.03) * FACE, c.goldDk, MAT.Metal, cyl)
	Base.sun(k, "Chest", at(0, 0.18, fz - 0.1), 0.34, c.gold, c.ember)
	light(k, "Chest", at(0, 0.18, fz + 0.1), c.ember, 9, 1.1)
	for i = 0, 2 do
		local y = -ch * 0.3 - i * 0.16
		deco("Chest", "Plackart", V(cw * (0.9 - i * 0.06), 0.18, 0.06), at(0, y, fz - 0.04), c.metalDk, MAT.Metal)
		deco("Chest", "PlackartEdge", V(cw * (0.9 - i * 0.06), 0.035, 0.07), at(0, y + 0.09, fz - 0.04), c.gold, MAT.Metal)
	end
end
-- B's arms in plate: pauldrons of five lames (big: wider again), rerebraces, couters, vambraces, gauntlets
function H.armsPlate(k, c, big, noVambrace)
	local deco, V, at, MAT = k.deco, k.V, k.at, k.MAT
	local aw, la, ua = k.aw, k.la, k.ua
	local g = big or 1
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		for j = 0, 4 do
			local y = ua * (0.5 - j * 0.13)
			local w = aw * (2.2 - j * 0.12) * g
			deco(n .. "UpperArm", "Pauldron", V(w, 0.24, w * 0.95), at(sx * 0.12, y, 0) * CFrame.Angles(0, 0, -sx * 0.32), j == 0 and c.metalDk or c.metal, MAT.Metal)
			deco(n .. "UpperArm", "PauldronEdge", V(w + 0.02, 0.04, w * 0.95 + 0.02), at(sx * 0.12, y - 0.1, 0) * CFrame.Angles(0, 0, -sx * 0.32), c.gold, MAT.Metal)
			deco(n .. "UpperArm", "PauldronRivet", V(0.06, 0.06, 0.06), at(sx * 0.12, y, -w * 0.48), c.goldDk, MAT.Metal, ball)
		end
		Base.sun(k, n .. "UpperArm", at(sx * 0.2, ua * 0.38, -aw * 1.12 * g), 0.14, c.gold)
		if not noVambrace then
			deco(n .. "UpperArm", "Rerebrace", V(aw * 1.25, ua * 0.6, aw * 1.25), at(0, -ua * 0.15, 0), c.metal, MAT.Metal)
			for _, y in ipairs({ -ua * 0.05, -ua * 0.4 }) do
				deco(n .. "UpperArm", "ArmBand", V(aw * 1.3, 0.05, aw * 1.3), at(0, y, 0), c.gold, MAT.Metal)
			end
			deco(n .. "LowerArm", "Couter", V(aw * 1.15, aw * 1.15, aw * 1.15), at(0, la * 0.45, 0.06), c.metalDk, MAT.Metal, ball)
			deco(n .. "LowerArm", "CouterFan", V(0.06, aw * 1.3, aw * 1.3), at(sx * aw * 0.62, la * 0.45, 0.06), c.metal, MAT.Metal, cyl)
			deco(n .. "LowerArm", "Vambrace", V(aw * 1.3, la * 0.62, aw * 1.3), at(0, 0, 0), c.metal, MAT.Metal)
			for _, y in ipairs({ la * 0.28, 0, -la * 0.28 }) do
				deco(n .. "LowerArm", "VambraceBand", V(aw * 1.35, 0.05, aw * 1.35), at(0, y, 0), c.gold, MAT.Metal)
			end
		end
		deco(n .. "LowerArm", "Gauntlet", V(aw * 1.45, 0.5, aw * 1.4), at(0, -la * 0.45, 0), c.metalDk, MAT.Metal)
		deco(n .. "LowerArm", "GauntletCuff", V(aw * 1.55, 0.06, aw * 1.5), at(0, -la * 0.32, 0), c.gold, MAT.Metal)
		Base.studs(k, n .. "LowerArm", 4, -aw * 0.45, aw * 0.45, -la / 2 - 0.2, -aw * 0.72, 0.07, c.goldDk)
	end
end
-- B's legs in plate (stood up, a thigh's -Z is its front again: the tassets lap down it as tassets should)
function H.legsPlate(k, c)
	local deco, V, at, MAT = k.deco, k.V, k.at, k.MAT
	local hw, hd, lw = k.hw, k.hd, k.lw
	local fx = k.D.footSize.X / k.s
	for i = 0, 2 do
		deco("Hips", "Fauld", V(hw * (1.2 + i * 0.04), 0.2, hd * (1.25 + i * 0.04)), at(0, 0.28 - i * 0.18, 0), i % 2 == 0 and c.metal or c.metalDk, MAT.Metal)
		deco("Hips", "FauldEdge", V(hw * (1.22 + i * 0.04), 0.04, hd * (1.27 + i * 0.04)), at(0, 0.19 - i * 0.18, 0), c.gold, MAT.Metal)
	end
	deco("Hips", "SwordBelt", V(hw * 1.32, 0.12, hd * 1.38), at(0, 0.42, 0), c.leather or rgb(44, 30, 22), MAT.Leather)
	Base.studs(k, "Hips", 7, -hw * 0.5, hw * 0.5, 0.42, -hd * 0.7, 0.07, c.gold)
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		deco(n .. "Thigh", "Cuisse", V(lw * 1.25, 1.1, lw * 1.25), at(0, 0, 0), c.metal, MAT.Metal)
		for j = 0, 2 do
			local y = 0.42 - j * 0.24
			deco(n .. "Thigh", "Tasset", V(lw * 1.5, 0.3, 0.07), at(0, y, -lw * 0.68 - j * 0.02), c.metalDk, MAT.Metal)
			deco(n .. "Thigh", "TassetEdge", V(lw * 1.52, 0.04, 0.08), at(0, y - 0.14, -lw * 0.69 - j * 0.02), c.gold, MAT.Metal)
		end
		deco(n .. "Shin", "Poleyn", V(lw * 1.2, lw * 1.2, lw * 1.2), at(0, 0.55, -0.05), c.metalDk, MAT.Metal, ball)
		Base.sun(k, n .. "Shin", at(0, 0.55, -lw * 0.64), 0.16, c.gold)
		deco(n .. "Shin", "PoleynFan", V(0.06, lw * 1.25, lw * 1.25), at(sx * lw * 0.62, 0.55, -0.05), c.metal, MAT.Metal, cyl)
		deco(n .. "Shin", "Greave", V(lw * 1.22, 0.95, lw * 1.22), at(0, -0.1, 0), c.metal, MAT.Metal)
		deco(n .. "Shin", "GreaveRidge", V(0.08, 0.9, 0.08), at(0, -0.1, -lw * 0.62) * CFrame.Angles(0, math.pi / 4, 0), c.metalDk, MAT.Metal)
		for _, y in ipairs({ 0.25, -0.45 }) do
			deco(n .. "Shin", "GreaveBand", V(lw * 1.26, 0.05, lw * 1.26), at(0, y, 0), c.gold, MAT.Metal)
		end
		H.chevrons(k, n .. "Shin", lw * 0.4, -0.38, 0.18, -lw * 0.62, 3, 0.08, c.gold)
		H.chevrons(k, n .. "Shin", -lw * 0.4, -0.38, 0.18, -lw * 0.62, 3, 0.08, c.gold)
		for j = 0, 2 do
			deco(n .. "Foot", "Sabaton", V(fx * 1.15, 0.2, 0.42), at(0, 0.08 + j * 0.02, 0.3 - j * 0.34), j % 2 == 0 and c.metal or c.metalDk, MAT.Metal)
			deco(n .. "Foot", "SabatonEdge", V(fx * 1.18, 0.04, 0.05), at(0, 0.16 + j * 0.02, 0.1 - j * 0.34), c.gold, MAT.Metal)
		end
	end
end
-- B's fur collar round the neck and the two sun-brooches at the breast
function H.furCollar(k, c)
	local cw, ch, cd = k.cw, k.ch, k.cd
	for i = 0, 15 do
		local a = (i / 15 - 0.5) * math.pi * 1.5
		k.deco("Chest", "Fur", k.V(0.36, 0.3, 0.36), k.at(math.sin(a) * 0.72, ch / 2 + 0.12 + (i % 2) * 0.06, math.cos(a) * 0.45 + 0.12), i % 2 == 0 and c.fur or c.furDk, k.MAT.Fabric, ball)
	end
	for _, sx in ipairs({ -1, 1 }) do
		Base.sun(k, "Chest", k.at(sx * cw * 0.42, ch / 2 - 0.12, -cd * 0.72), 0.18, c.gold, c.ember)
	end
end
-- a cope (or cloak) stood up: over the shoulders and arms, down the back and the sides to the floor, open in front;
-- its front edges banded down their whole length (orphreys: C's coloured panels in gold frames, else plain gold);
-- sideX: how far out its sides hang; front: how far forward they come (behind plate arms; or round the front of
-- arms in sleeves, which they then hang outside of)
function H.copeStanding(k, col, colDk, gold, sideX, orphreys, front)
	local deco, V, at, MAT = k.deco, k.V, k.at, k.MAT
	local ch, cd = k.ch, k.cd
	front = front or -cd * 0.46
	local sz, sd = (front + cd * 0.7) / 2, cd * 0.7 - front
	local top = ch / 2 - 0.1
	local L = top + 3.82 -- (from the shoulders to just over the floor: the chest's middle stands 3.95 up)
	local yc = top - L / 2
	deco("Chest", "CopeShoulders", V(sideX * 2 + 0.1, 0.4, cd * 1.45), at(0, ch / 2 - 0.14, 0.06), col, MAT.Fabric)
	deco("Chest", "CopeBack", V(sideX * 2 + 0.1, L, 0.12), at(0, yc, cd * 0.7), col, MAT.Fabric)
	deco("Chest", "CopeHemBack", V(sideX * 2 + 0.16, 0.14, 0.16), at(0, yc - L / 2 + 0.07, cd * 0.7), gold, MAT.Metal)
	for _, sx in ipairs({ -1, 1 }) do
		local x = sx * sideX
		deco("Chest", "CopeSide", V(0.12, L, sd), at(x, yc, sz), colDk, MAT.Fabric)
		deco("Chest", "CopeHemSide", V(0.16, 0.14, sd + 0.02), at(x, yc - L / 2 + 0.07, sz), gold, MAT.Metal)
		-- its front edge, banded to the floor
		local ez = front
		deco("Chest", "Orphrey", V(0.18, L, 0.34), at(x, yc, ez), gold, MAT.Metal)
		if orphreys then
			local n = 7
			for j = 0, n - 1 do
				local y = top - 0.35 - j * (L - 0.6) / (n - 1)
				deco("Chest", "OrphreyPanel", V(0.2, 0.3, 0.24), at(x, y, ez), orphreys[(j + (sx > 0 and 1 or 0)) % #orphreys + 1], MAT.Fabric)
				Base.sun(k, "Chest", at(x - sx * 0.11, y, ez) * CFrame.Angles(0, -sx * math.pi / 2, 0), 0.07, gold)
			end
		end
	end
end
-- a cope of CLOTH: over the shoulders a solid yoke; from under it, strips of cloth hung to the floor that every client
-- swings (anchors tagged "ClothChain": Carrier.cloth) - a broad outer layer across the back in n strips, overlapping,
-- each with its own heft so they part and ripple; a lining of another colour under it; a fall down each side. Its
-- strips follow him - every turn, stride and swing of his throws them out behind. (A statue's are hung still, in stone:
-- KingGilded.statue)
local CollectionService = game:GetService("CollectionService")
function H.copeCloth(k, col, colDk, lining, sideX, n)
	local deco, V, at, MAT, s = k.deco, k.V, k.at, k.MAT, k.s
	local ch, cd = k.ch, k.cd
	local top = ch / 2 - 0.12
	local L = top + 3.82 -- (shoulders to the floor, in the rig's units: the chest's middle stands 3.95 up)
	deco("Chest", "CopeShoulders", V(sideX * 2 + 0.1, 0.4, cd * 1.45), at(0, ch / 2 - 0.14, 0.06), col, MAT.Fabric)
	local function strip(name, x, z, rot, width, len, segs, color, drag, grav, out)
		local a = deco("Chest", name, V(0.2, 0.2, 0.2), at(x, top, z) * rot, color, MAT.Fabric)
		a.Transparency = 1
		a:SetAttribute("Segs", segs)
		a:SetAttribute("Len", len * s / segs)
		a:SetAttribute("Width", width * s)
		a:SetAttribute("Color", color)
		a:SetAttribute("Drag", drag)
		a:SetAttribute("Gravity", grav)
		a:SetAttribute("Out", out * s)
		CollectionService:AddTag(a, "ClothChain")
	end
	local BACK = CFrame.Angles(0, math.pi, 0) -- (its LookVector behind him: the side it hangs out on)
	local w = sideX * 2 / n
	for i = 0, n - 1 do -- the outer layer, every strip a little different in length and heft
		local x = -sideX + (i + 0.5) * w
		local edge = (i == 0 or i == n - 1)
		strip("CapeAnchor", x, cd * 0.64, BACK, w * 1.35, L * (edge and 0.97 or (1 - (i % 3) * 0.025)), 9, i % 2 == 0 and col or colDk, 0.93 + (i % 3) * 0.015, 1 + (i % 2) * 0.12, 0.08)
	end
	for i = 0, n - 2 do -- the lining, under it, a touch shorter
		strip("CapeLiningAnchor", -sideX + (i + 1) * w, cd * 0.56, BACK, w * 1.2, L * 0.94, 8, lining, 0.9, 1.1, 0.02)
	end
	for _, sx in ipairs({ -1, 1 }) do -- the falls down his sides
		strip("CapeSideAnchor", sx * sideX, cd * 0.15, CFrame.Angles(0, -sx * math.pi / 2, 0), cd * 0.95, L * 0.96, 8, colDk, 0.94, 1, 0.05)
	end
end
-- a tabard of CLOTH, before and behind: from the belt a short stiff yoke (before: a gold-framed panel on it, a burning
-- sun in it), and from that its fall to below the knee in strips the clients swing like the cope's - gold-edged, the
-- edges strips of their own - so it kicks out with every stride and trails every turn
function H.tabardCloth(k, col, gold, goldDk, ember, panel)
	local deco, V, at, MAT, s = k.deco, k.V, k.at, k.MAT, k.s
	local hw, hd = k.hw, k.hd
	local w, yTop, yoke, L = hw * 0.62, 0.35, 0.45, 2.25
	local function strip(on, x, y, z, rot, width, len, segs, color, drag)
		local a = deco(on, "TabardAnchor", V(0.2, 0.2, 0.2), at(x, y, z) * rot, color, MAT.Fabric)
		a.Transparency = 1
		a:SetAttribute("Segs", segs)
		a:SetAttribute("Len", len * s / segs)
		a:SetAttribute("Width", width * s)
		a:SetAttribute("Color", color)
		a:SetAttribute("Drag", drag)
		a:SetAttribute("Gravity", 1.15)
		a:SetAttribute("Out", 0.03 * s)
		CollectionService:AddTag(a, "ClothChain")
	end
	for _, zs in ipairs({ -1, 1 }) do
		local z = zs * hd * 0.72
		local rot = zs < 0 and CFrame.new() or CFrame.Angles(0, math.pi, 0) -- (hanging out before him, or behind)
		deco("Hips", "TabardYoke", V(w, yoke, 0.08), at(0, yTop - yoke / 2, z), col, MAT.Fabric)
		deco("Hips", "TabardYokeEdge", V(w + 0.06, 0.06, 0.09), at(0, yTop, z), gold, MAT.Metal)
		if zs < 0 then
			deco("Hips", "TabardPanelFrame", V(w * 0.6, yoke * 0.8, 0.03), at(0, yTop - yoke / 2, z - 0.05), gold, MAT.Metal)
			deco("Hips", "TabardPanel", V(w * 0.5, yoke * 0.62, 0.03), at(0, yTop - yoke / 2, z - 0.07), panel[1], MAT.Fabric)
			Base.sun(k, "Hips", at(0, yTop - yoke / 2, z - 0.09), 0.13, gold, ember)
		end
		local y = yTop - yoke
		for i = 0, 2 do -- the fall, in three, and an edge of gold down each side
			strip("Hips", -w / 3 + i * w / 3, y, z, rot, w / 3 * 1.2, L * (1 - (i % 2) * 0.04), 6, col, 0.92 + i * 0.015)
		end
		for _, ex in ipairs({ -w / 2, w / 2 }) do
			strip("Hips", ex, y, z + zs * 0.01, rot, 0.12, L * 1.02, 6, goldDk, 0.93)
		end
	end
end
-- C's chasuble on the breast: ivory, trellised in gold, a gem in its lozenges, the pallium down it with its suns
function H.chasuble(k, c, gold)
	local deco, V, at, MAT = k.deco, k.V, k.at, k.MAT
	local cw, ch, cd = k.cw, k.ch, k.cd
	local fz = -cd * 0.56 - 0.02
	deco("Chest", "Chasuble", V(cw * 1.08, ch * 1.02, cd * 1.12), at(0, 0, 0), c.ivory, MAT.Fabric)
	Base.lattice(k, "Chest", cw * 0.5, ch * 0.9, 0, -0.02, fz, 0.24, gold)
	Base.brocade(k, "Chest", 0, -0.02, fz - 0.01, 4, 7, 0.24, 0.06, c.cloth, c.panel[1])
	deco("Chest", "Pallium", V(0.26, ch * 0.92, 0.05), at(0, -0.04, fz - 0.03), c.ivory, MAT.Fabric)
	deco("Chest", "PalliumEdge", V(0.3, ch * 0.92, 0.04), at(0, -0.04, fz - 0.015), gold, MAT.Metal)
	for j = 0, 2 do
		Base.sun(k, "Chest", at(0, 0.45 - j * 0.42, fz - 0.07), 0.1, c.cloth)
	end
end
-- C's morse: the great clasp at the breast, four lobes, a stone, two burning studs
function H.morse(k, c, y, z)
	local deco, V, at, MAT = k.deco, k.V, k.at, k.MAT
	deco("Chest", "Morse", V(0.42, 0.42, 0.08), at(0, y, z) * CFrame.Angles(0, 0, math.pi / 4), c.gold, MAT.Metal)
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2
		deco("Chest", "MorseLobe", V(0.2, 0.2, 0.2), at(math.cos(a) * 0.28, y + math.sin(a) * 0.28, z), c.goldDk, MAT.Metal, ball)
	end
	deco("Chest", "MorseStone", V(0.08, 0.2, 0.2), at(0, y, z - 0.06) * FACE, c.panel and c.panel[2] or c.ember, MAT.Glass, cyl)
end
-- C's sleeves: the cope's bell sleeves over the alb's, lace at the wrist
function H.bellSleeves(k, c)
	local deco, V, at, MAT = k.deco, k.V, k.at, k.MAT
	local aw, la, ua = k.aw, k.la, k.ua
	for _, n in ipairs({ "R", "L" }) do
		deco(n .. "UpperArm", "BellSleeve", V(aw * 1.6, ua * 0.95, aw * 1.6), at(0, 0, 0), c.cloth, MAT.Fabric)
		deco(n .. "UpperArm", "SleeveBand", V(aw * 1.65, 0.1, aw * 1.65), at(0, -ua * 0.35, 0), c.gold, MAT.Metal)
		Base.brocade(k, n .. "UpperArm", 0, 0.05, -aw * 0.81, 2, 3, 0.2, 0.06, c.gold, c.goldDk)
		deco(n .. "LowerArm", "Bell", V(aw * 1.9, la * 0.55, aw * 1.9), at(0, la * 0.18, 0), c.cloth, MAT.Fabric)
		deco(n .. "LowerArm", "BellHem", V(aw * 1.95, 0.1, aw * 1.95), at(0, -la * 0.08, 0), c.gold, MAT.Metal)
		deco(n .. "LowerArm", "Alb", V(aw * 1.2, la * 0.4, aw * 1.2), at(0, -la * 0.25, 0), c.ivory, MAT.Fabric)
		for f = 0, 3 do
			local face = CFrame.Angles(0, f * math.pi / 2, 0)
			for i = 0, 3 do
				deco(n .. "LowerArm", "Lace", V(0.05, 0.12, 0.03), face * at(-aw * 0.45 + i * aw * 0.3, -la * 0.45, -aw * 0.62), c.ivory, MAT.Fabric)
			end
		end
	end
end
-- C's alb stood up: to the feet, the two legs' falls meeting between them, widening down, a band down the front of
-- each, a gold hem and lace under it; slippers
function H.albStanding(k, col, hem, band, lace, slipper)
	local deco, V, at, MAT = k.deco, k.V, k.at, k.MAT
	local hw, hd, lw = k.hw, k.hd, k.lw
	local fx = k.D.footSize.X / k.s
	local th, sh = k.D.thigh / k.s, k.D.shin / k.s
	deco("Hips", "Robe", V(hw * 1.14, 0.85, hd * 1.16), at(0, -0.02, 0), col, MAT.Fabric)
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		deco(n .. "Thigh", "Skirt", V(lw * 1.8, th + 0.1, lw * 1.7), at(-sx * 0.06, 0, 0), col, MAT.Fabric)
		deco(n .. "Thigh", "SkirtBand", V(lw * 0.42, th + 0.1, 0.03), at(-sx * 0.06, 0, -lw * 0.86), band, MAT.Fabric)
		deco(n .. "Shin", "Skirt", V(lw * 2.0, sh + 0.05, lw * 1.9), at(sx * 0.0, -0.02, 0), col, MAT.Fabric)
		deco(n .. "Shin", "SkirtBand", V(lw * 0.42, sh + 0.05, 0.03), at(-sx * 0.06, -0.02, -lw * 0.96), band, MAT.Fabric)
		deco(n .. "Shin", "Hem", V(lw * 2.06, 0.14, lw * 1.96), at(0, -sh / 2 + 0.05, 0), hem, MAT.Metal)
		Base.sun(k, n .. "Shin", at(-sx * 0.06, 0.05, -lw * 0.98), 0.12, hem)
		if lace then
			for i = 0, 7 do
				deco(n .. "Shin", "Lace", V(0.05, i % 2 == 0 and 0.16 or 0.1, 0.03), at(-lw + i * lw * 2 / 7, -sh / 2 + 0.02, -lw * 0.99), lace, MAT.Fabric)
			end
		end
		deco(n .. "Foot", "Slipper", V(fx * 1.08, 0.32, 1.1), at(0, 0.02, -0.02), slipper or col, MAT.Fabric)
		deco(n .. "Foot", "SlipperToe", V(fx * 0.5, 0.1, 0.3), at(0, 0.14, -0.42), hem, MAT.Metal)
	end
end
-- a tabard stood up: front and back panels hung from the belt to below the knee, gold-bordered, fringed
-- (panels: a column of C's coloured panels in gold frames down its front, else the sun on it)
function H.tabardStanding(k, col, gold, goldDk, ember, panels)
	local deco, V, at, MAT = k.deco, k.V, k.at, k.MAT
	local hw, hd = k.hw, k.hd
	local L, w = 2.7, hw * 0.62
	local yc = 0.35 - L / 2
	for _, zs in ipairs({ -1, 1 }) do
		local z = zs * hd * 0.72
		deco("Hips", "Tabard", V(w, L, 0.06), at(0, yc, z), col, MAT.Fabric)
		deco("Hips", "TabardBorder", V(w + 0.06, 0.06, 0.07), at(0, yc - L / 2, z), gold, MAT.Metal)
		for _, ex in ipairs({ -w / 2, w / 2 }) do
			deco("Hips", "TabardBorder", V(0.06, L, 0.07), at(ex, yc, z), gold, MAT.Metal)
		end
		for i = 0, 9 do
			deco("Hips", "TabardFringe", V(0.05, 0.16, 0.03), at(-w * 0.45 + i * w * 0.1, yc - L / 2 - 0.1, z), goldDk, MAT.Fabric)
		end
		if zs < 0 then
			if panels then
				for j = 0, 3 do
					local y = yc + L * 0.36 - j * L * 0.24
					deco("Hips", "TabardPanelFrame", V(w * 0.6, L * 0.2, 0.03), at(0, y, z - 0.04), gold, MAT.Metal)
					deco("Hips", "TabardPanel", V(w * 0.5, L * 0.16, 0.03), at(0, y, z - 0.06), panels[j % #panels + 1], MAT.Fabric)
					Base.sun(k, "Hips", at(0, y, z - 0.08), 0.12, gold, j == 0 and ember or nil)
				end
			else
				Base.sun(k, "Hips", at(0, yc + 0.3, z - 0.05), 0.3, gold, ember)
			end
		end
	end
end

---------------------------------------------------------------------------
-- WHAT THEY HOLD (on a forearm laid forward: Base.held's frame, +Y up, -Z forward; the grip at elbow height,
-- 3.36 over the floor, so a staff's foot or a sword's point goes 3.4 under it to reach the ground)
---------------------------------------------------------------------------
-- C's sun-wheel staff, stood on the floor (blade: a crescent blade off the wheel's top, B's steel: a glaive)
function H.staff(k, c, arm, blade)
	local deco, V, at, MAT = k.deco, k.V, k.at, k.MAT
	local on = arm .. "LowerArm"
	local G = Base.held(k)
	deco(on, "StaffShaft", V(0.16, 7.0, 0.16), G * at(0, 0.1, 0), c.goldDk, MAT.Metal)
	deco(on, "StaffFerrule", V(0.22, 0.3, 0.22), G * at(0, -3.25, 0), c.gold, MAT.Metal)
	for _, y in ipairs({ -2.6, -1.4, 0.9, 1.9, 2.9 }) do
		deco(on, "StaffRing", V(0.26, 0.1, 0.26), G * at(0, y, 0), c.gold, MAT.Metal)
	end
	local W = G * at(0, 4.2, 0)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		deco(on, "Wheel", V(0.14, 0.32, 0.14), W * at(math.cos(a) * 0.6, math.sin(a) * 0.6, 0) * CFrame.Angles(0, 0, a), c.gold, MAT.Metal)
		deco(on, "WheelRay", V(0.08, 0.2, 0.06), W * at(math.cos(a) * 0.82, math.sin(a) * 0.82, 0) * CFrame.Angles(0, 0, a - math.pi / 2), c.goldDk, MAT.Metal)
	end
	for i = 0, 2 do
		deco(on, "Spoke", V(0.06, 1.2, 0.06), W * CFrame.Angles(0, 0, i * math.pi / 3), c.goldDk, MAT.Metal)
	end
	local core = deco(on, "WheelFire", V(0.4, 0.4, 0.4), W, c.sun or c.ember, MAT.Neon, ball)
	fire(k, core, 2.2, 5, c.flame or c.ember)
	light(k, on, W, c.flame or c.ember, 12, 1.4)
	if blade then -- a crescent of steel off the wheel's crown, its horns out either side, an edge of fire along it
		for i = 0, 6 do
			local a = math.pi * (0.15 + i / 6 * 0.7)
			local cf = W * at(math.cos(a) * 1.1, 0.55 + math.sin(a) * 1.1, 0) * CFrame.Angles(0, 0, a - math.pi / 2)
			deco(on, "GlaiveBlade", V(0.5, 0.36, 0.06), cf, blade, MAT.Metal)
			deco(on, "GlaiveEdge", V(0.5, 0.06, 0.07), cf * at(0, 0.18, 0), c.ember or c.flame, MAT.Neon)
		end
		deco(on, "GlaiveSpike", V(0.12, 1.0, 0.06), W * at(0, 1.95, 0), blade, MAT.Metal)
	end
end
-- B's sword, point-down on the floor before him, his fist on the grip
function H.sword(k, c, arm)
	local deco, V, at, MAT = k.deco, k.V, k.at, k.MAT
	local on = arm .. "LowerArm"
	local G = Base.held(k)
	local STEELB = rgb(150, 146, 140)
	deco(on, "Pommel", V(0.26, 0.26, 0.26), G * at(0, 0.42, 0), c.gold, MAT.Metal, ball)
	deco(on, "PommelStone", V(0.12, 0.12, 0.12), G * at(0, 0.42, -0.12), c.ember, MAT.Neon, ball)
	deco(on, "Grip", V(0.13, 0.55, 0.13), G * at(0, 0.03, 0), c.leather or rgb(44, 30, 22), MAT.Leather)
	deco(on, "Crossguard", V(1.0, 0.14, 0.14), G * at(0, -0.32, 0), c.gold, MAT.Metal)
	for _, e in ipairs({ -0.5, 0.5 }) do
		deco(on, "QuillonEnd", V(0.16, 0.16, 0.16), G * at(e, -0.32, 0), c.goldDk, MAT.Metal, ball)
	end
	deco(on, "Blade", V(0.3, 2.85, 0.07), G * at(0, -1.82, 0), STEELB, MAT.Metal)
	deco(on, "BladeFuller", V(0.06, 2.5, 0.08), G * at(0, -1.7, 0), c.ember, MAT.Neon)
	for i = 0, 5 do
		deco(on, "BladeRune", V(0.12, 0.08, 0.09), G * at(0, -0.7 - i * 0.38, 0), c.gold, MAT.Metal)
	end
	deco(on, "BladeTip", V(0.22, 0.22, 0.07), G * at(0, -3.25, 0) * CFrame.Angles(0, 0, math.pi / 4), STEELB, MAT.Metal)
end
-- a censer on three chains from the fist: a pierced gold bowl and lid, fire and smoke in it
function H.censer(k, c, arm)
	local deco, V, at, MAT = k.deco, k.V, k.at, k.MAT
	local on = arm .. "LowerArm"
	local G = Base.held(k)
	deco(on, "CenserRing", V(0.04, 0.3, 0.3), G * at(0, -0.15, 0) * UP, c.gold, MAT.Metal, cyl)
	local bowl = G * at(0, -1.6, 0)
	for i = 0, 2 do
		local a = i / 3 * math.pi * 2
		local p0, p1 = (G * at(0, -0.15, 0)).Position, (bowl * at(math.cos(a) * 0.3, 0.2, math.sin(a) * 0.3)).Position
		deco(on, "CenserChain", (p1 - p0).Magnitude * Vector3.new(0, 0, 1) + k.V(0.04, 0.04, 0), CFrame.lookAt((p0 + p1) / 2, p1), c.goldDk, MAT.Metal)
	end
	deco(on, "CenserBowl", V(0.62, 0.62, 0.62), bowl, c.gold, MAT.Metal, ball)
	deco(on, "CenserLid", V(0.3, 0.5, 0.5), bowl * at(0, 0.3, 0) * UP, c.goldDk, MAT.Metal, cyl)
	deco(on, "CenserFinial", V(0.14, 0.14, 0.14), bowl * at(0, 0.5, 0), c.gold, MAT.Metal, ball)
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		deco(on, "CenserVent", V(0.06, 0.12, 0.06), bowl * at(math.cos(a) * 0.3, 0.05, math.sin(a) * 0.3), c.ember, MAT.Neon)
	end
	local core = deco(on, "CenserFire", V(0.3, 0.3, 0.3), bowl, c.ember, MAT.Neon, ball)
	core.Transparency = 0.6
	local smoke = Instance.new("Smoke")
	smoke.Color, smoke.Opacity, smoke.RiseVelocity, smoke.Size = rgb(120, 110, 100), 0.15, 2, 0.6 * k.s / Base.Scale
	smoke.Parent = core
	light(k, on, bowl, c.ember, 8, 1)
end

return H
