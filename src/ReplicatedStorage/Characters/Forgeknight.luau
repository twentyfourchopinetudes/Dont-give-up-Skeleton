--!nonstrict
-- FORGE KNIGHT (kind Forgeknight) - Furnace Brute rework B: the soldier. A knight of the palace's forge-guard, built
-- like a man and armoured like a door: square shoulders, a waist, plate of blackened steel trimmed in brass. A great
-- helm whose face is a furnace grille, the fire behind it; at the heart of its breastplate a round grate, the furnace
-- it wears burning there (the breath comes out of it); layered flat pauldrons, a scorched tabard to the knee, a short
-- mail skirt. A warhammer in each fist. Fights as the Furnace Brute does (Anvilfall, Pistons, Bellows): as heavy a
-- hitter, near as hard to stagger, a head shorter and half the width.
local Base = require(script.Parent:WaitForChild("Furnace"))

local M = table.clone(Base)
M.Kind = "Forgeknight"
M.Proportions = { girth = 1.15, arm = 1.1, hunch = 0.08 }
local STEEL, STEEL_DK, BRASS = Color3.fromRGB(44, 40, 40), Color3.fromRGB(24, 22, 22), Color3.fromRGB(150, 112, 56)
local HEAT, EMBER, CLOTH = Color3.fromRGB(255, 120, 30), Color3.fromRGB(255, 80, 20), Color3.fromRGB(90, 20, 14)
M.Colors = { skin = STEEL_DK, torso = STEEL, legs = STEEL_DK, arms = STEEL }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local up = CFrame.Angles(0, 0, math.pi / 2)
	local cyl, ball = Enum.PartType.Cylinder, Enum.PartType.Ball
	-- THE GREAT HELM: a flat-topped box, a brass crest ridge, its face a grille of bars with the fire behind
	parts.Head.Transparency = 1
	deco("Head", "Helm", V(1.3, 1.45, 1.35), at(0, 0.1, 0), STEEL, MAT.Metal)
	deco("Head", "HelmCrest", V(0.16, 0.3, 1.4), at(0, 0.92, 0), BRASS, MAT.Metal)
	deco("Head", "HelmBrow", V(1.36, 0.16, 0.12), at(0, 0.42, -0.7), BRASS, MAT.Metal)
	deco("Head", "Grille", V(1.0, 0.75, 0.04), at(0, -0.02, -0.69), EMBER, MAT.Neon)
	for i = -3, 3 do
		deco("Head", "GrilleBar", V(0.08, 0.8, 0.08), at(i * 0.14, -0.02, -0.72), STEEL_DK, MAT.Metal)
	end
	deco("Head", "Gorget", V(1.5, 0.35, 1.45), at(0, -0.78, 0), STEEL_DK, MAT.Metal)
	-- THE BREASTPLATE, the furnace at its heart: a round grate, brass-rimmed (the breath comes out of it)
	deco("Chest", "Breastplate", V(cw * 1.08, ch * 1.02, cd * 1.15), at(0, 0, 0), STEEL, MAT.Metal)
	deco("Chest", "Fauld", V(cw * 1.0, 0.3, cd * 1.1), at(0, -ch * 0.5, 0), STEEL_DK, MAT.Metal)
	deco("Chest", "GrateRim", V(0.12, 1.0, 1.0), at(0, 0.1, -cd * 0.6) * CFrame.Angles(0, math.pi / 2, 0), BRASS, MAT.Metal, cyl)
	deco("Chest", "GrateFire", V(0.75, 0.75, 0.05), at(0, 0.1, -cd * 0.63), EMBER, MAT.Neon)
	for i = -1, 1 do
		deco("Chest", "GrateBar", V(0.07, 0.8, 0.08), at(i * 0.2, 0.1, -cd * 0.66), STEEL_DK, MAT.Metal)
	end
	local glow = deco("Chest", "Grate", V(0.2, 0.2, 0.2), at(0, 0.1, -cd * 0.4), EMBER, MAT.Neon)
	glow.Transparency = 1
	local l = Instance.new("PointLight")
	l.Name = "GrateLight"
	l.Color, l.Range, l.Brightness = HEAT, 12, 1.4
	l.Parent = glow
	-- the tabard, the mail skirt under it, the belt
	deco("Chest", "Tabard", V(cw * 0.55, ch * 0.4, 0.06), at(0, -ch * 0.3, -cd * 0.6), CLOTH, MAT.Fabric)
	deco("Hips", "TabardLow", V(hw * 0.6, 2.0, 0.06), at(0, -0.8, -hd * 0.62), CLOTH, MAT.Fabric)
	deco("Hips", "TabardBack", V(hw * 0.6, 1.8, 0.06), at(0, -0.7, hd * 0.62), CLOTH:Lerp(rgb(0, 0, 0), 0.3), MAT.Fabric)
	deco("Hips", "MailSkirt", V(hw * 1.2, 0.9, hd * 1.2), at(0, -0.35, 0), STEEL_DK, MAT.DiamondPlate)
	deco("Hips", "Belt", V(hw * 1.28, 0.24, hd * 1.3), at(0, 0.3, 0), BRASS, MAT.Metal)
	-- arms: layered flat pauldrons, couters, gauntlets; legs: cuisses, poleyns, greaves, sabatons
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		for j = 0, 2 do
			deco(n .. "UpperArm", "Pauldron", V(aw * (2.0 - j * 0.15), 0.28, aw * 1.9), at(sx * 0.12, ua * (0.42 - j * 0.16), 0) * CFrame.Angles(0, 0, -sx * 0.3), j == 0 and BRASS or STEEL, MAT.Metal)
		end
		deco(n .. "UpperArm", "Rerebrace", V(aw * 1.2, ua * 0.6, aw * 1.2), at(0, -ua * 0.15, 0), STEEL, MAT.Metal)
		deco(n .. "LowerArm", "Couter", V(aw * 1.1, aw * 1.1, aw * 1.1), at(0, la * 0.45, 0.1), STEEL_DK, MAT.Metal, ball)
		deco(n .. "LowerArm", "Vambrace", V(aw * 1.3, la * 0.75, aw * 1.3), at(0, -0.05, 0), STEEL, MAT.Metal)
		deco(n .. "LowerArm", "Fist", V(aw * 1.3, 0.5, aw * 1.3), at(0, -la * 0.45, 0), STEEL_DK, MAT.Metal)
		deco(n .. "Thigh", "Cuisse", V(lw * 1.2, 1.0, lw * 1.2), at(0, 0.05, 0), STEEL, MAT.Metal)
		deco(n .. "Shin", "Greave", V(lw * 1.2, 1.05, lw * 1.2), at(0, -0.1, 0), STEEL, MAT.Metal)
		deco(n .. "Shin", "Poleyn", V(lw * 1.1, lw * 1.0, lw * 0.6), at(0, 0.55, -lw * 0.4), BRASS, MAT.Metal)
		deco(n .. "Foot", "Sabaton", V(0.75, 0.38, 1.2), at(0, 0.05, -0.05), STEEL_DK, MAT.Metal)
	end
end

M.Def = table.clone(Base.Def)
for key, v in pairs({
	HP = 500, Speed = 9.5, Scale = 1.4, Radius = 1.8, Lunge = 9, Poise = 90,
	Skin = STEEL_DK, Cloth = CLOTH,
}) do
	M.Def[key] = v
end

return M
