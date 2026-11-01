--!nonstrict
-- ERRANT KNIGHT (kind Errant): knights who came to the Crowned Colosseum to fight and never
-- left the woods round it. They keep the track through the Weald in ones and twos: full
-- plate gone dull, a tabard faded to nothing, a great helm with a dark slit, a longsword.
-- They fight like the hollows (Hollow.attack: one windup, one strike, a window after),
-- only harder, quicker to swing, slower to stagger.
--
-- EVERYTHING ABOUT THIS CHARACTER IS IN THIS ONE FILE:
--   M.Proportions / M.Colors / M.Look   body shape and how the rig is dressed
--   M.Weapons                            the longsword
--   M.Def / M.attack                     stats and behaviour (the shared brain in GameServer/Enemies.lua)
-- Body poses (Idle, Raise, Mid, Strike, ...) are shared ones from PuppetMath.
local Hollow = require(script.Parent:WaitForChild("Hollow"))

local M = {}
M.Kind = "Errant"
M.Proportions = { girth = 1.05, arm = 1.0, hunch = 0.08 } -- broad in the plate, upright
local STEEL, STEEL_DARK, TABARD, LEATHER = Color3.fromRGB(122, 124, 126), Color3.fromRGB(78, 80, 84), Color3.fromRGB(96, 40, 36), Color3.fromRGB(58, 44, 32)
M.Colors = { skin = STEEL, torso = STEEL, legs = STEEL_DARK, arms = STEEL }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local rnd = Random.new()
	local steel = STEEL:Lerp(rgb(96, 90, 80), rnd:NextNumber(0, 0.4)) -- (no two suits dulled alike)
	local tabard = TABARD:Lerp(rgb(70, 64, 56), rnd:NextNumber(0.2, 0.7))
	for _, pn in ipairs({ "Chest", "RUpperArm", "LUpperArm", "RLowerArm", "LLowerArm", "RThigh", "LThigh", "RShin", "LShin", "RFoot", "LFoot" }) do
		parts[pn].Material = MAT.Metal
		parts[pn].Color = (pn:find("Thigh") or pn:find("Foot")) and STEEL_DARK or steel
	end
	-- THE GREAT HELM: a flat-topped bucket of steel, a dark eye-slit, breaths below it
	parts.Head.Transparency = 1
	deco("Head", "Helm", V(1.3, 1.4, 1.3), at(0, 0.05, 0), steel, MAT.Metal)
	deco("Head", "HelmTop", V(1.36, 0.14, 1.36), at(0, 0.78, 0), STEEL_DARK, MAT.Metal)
	deco("Head", "Slit", V(1.0, 0.1, 0.04), at(0, 0.18, -0.66), rgb(10, 10, 12), MAT.SmoothPlastic)
	deco("Head", "Ridge", V(0.1, 1.3, 0.08), at(0, 0.05, -0.67), STEEL_DARK, MAT.Metal)
	for i = 0, 2 do
		deco("Head", "Breath", V(0.06, 0.06, 0.04), at(0.2, -0.2 - i * 0.14, -0.66), rgb(10, 10, 12), MAT.SmoothPlastic)
	end
	deco("Head", "Gorget", V(1.1, 0.3, 1.1), at(0, -0.75, 0), STEEL_DARK, MAT.Metal)
	-- breastplate, the tabard over it, a sword belt
	deco("Chest", "Breastplate", V(cw * 1.08, ch * 0.8, cd * 1.12), at(0, 0.1, 0), steel, MAT.Metal)
	deco("Chest", "Tabard", V(cw * 0.7, ch * 1.25, 0.06), at(0, -0.4, -cd * 0.6), tabard, MAT.Fabric)
	deco("Chest", "TabardB", V(cw * 0.7, ch * 1.2, 0.06), at(0, -0.4, cd * 0.6), tabard:Lerp(rgb(0, 0, 0), 0.15), MAT.Fabric)
	deco("Hips", "Belt", V(hw * 1.08, 0.22, hd * 1.08), at(0, 0.3, 0), LEATHER, MAT.Leather)
	deco("Hips", "Faulds", V(hw * 1.1, 0.6, hd * 1.1), at(0, -0.1, 0), STEEL_DARK, MAT.Metal)
	-- pauldrons, couters, gauntlets; poleyns and greaves
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		deco(n .. "UpperArm", "Pauldron", V(aw * 1.6, ua * 0.45, aw * 1.5), at(sx * 0.08, ua * 0.32, 0) * CFrame.Angles(0, 0, -sx * 0.25), steel, MAT.Metal)
		deco(n .. "LowerArm", "Couter", V(aw * 1.2, 0.3, aw * 1.2), at(0, la * 0.42, 0), STEEL_DARK, MAT.Metal)
		deco(n .. "LowerArm", "Gauntlet", V(aw * 1.15, 0.5, aw * 1.15), at(0, -la * 0.38, 0), STEEL_DARK, MAT.Metal)
		deco(n .. "Shin", "Poleyn", V(lw * 1.2, 0.35, lw * 1.25), at(0, 0.55, -0.05), steel, MAT.Metal)
		deco(n .. "Shin", "Greave", V(lw * 1.1, 1.0, lw * 1.12), at(0, -0.1, 0), steel, MAT.Metal)
	end
	-- eyes: direct children named "Eye" (two pale points in the slit)
	for _, x in ipairs({ -0.22, 0.22 }) do
		deco("Head", "Eye", V(0.08, 0.05, 0.04), at(x, 0.18, -0.68), rgb(200, 190, 160), MAT.Neon)
	end
end

M.Weapons = {
	Longsword = function(w)
		local handle = w.mk("Grip", Vector3.new(0.22, 1.1, 0.22), Color3.fromRGB(58, 44, 32), Enum.Material.Leather)
		w.add(w.mk("Guard", Vector3.new(1.2, 0.16, 0.22), Color3.fromRGB(78, 80, 84), Enum.Material.Metal), -0.6)
		w.add(w.mk("Blade", Vector3.new(0.3, 3.6, 0.08), Color3.fromRGB(176, 178, 182), Enum.Material.Metal), -2.5)
		return { handle = handle, bladeLen = 4.2 }
	end,
}

-- stats (the shared brain in GameServer/Enemies.lua reads these)
M.Def = {
	HP = 140, Speed = 11, Scale = 1.05, Damage = 32, Range = 7, HalfAngle = 60,
	Windup = 0.6, Recover = 0.6, Aggro = 40, Leash = 70, Stagger = 0.45,
	HyperArmor = false, Weapon = "Longsword", Radius = 1.3, Lunge = 16,
	Poise = 28, HitLevel = "Medium", -- (plate: it takes a few hits to stagger one)
	Skin = STEEL, Cloth = TABARD,
}

-- the hollow's one heavy swing, with this knight's numbers (M.Def)
M.attack = Hollow.attack

return M
