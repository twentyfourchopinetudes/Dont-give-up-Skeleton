--!nonstrict
-- CINDER KNIGHT (kind Cinder): knights of Pyralis's buried fortress, burned and never let die. They keep the Maw's
-- halls in ones and twos: plate blackened by the heat, molten seams glowing between the plates, ember eyes in a
-- horned helm, a longsword that never stops burning. They fight like the Errant knights (Hollow.attack: one windup,
-- one strike, a window after), only harder-hitting and harder to stagger.
--
-- EVERYTHING ABOUT THIS CHARACTER IS IN THIS ONE FILE:
--   M.Proportions / M.Colors / M.Look   body shape and how the rig is dressed
--   M.Weapons                            the burning sword
--   M.Def / M.attack                     stats and behaviour (the shared brain in GameServer/Enemies.lua)
local Hollow = require(script.Parent:WaitForChild("Hollow"))

local M = {}
M.Kind = "Cinder"
M.Proportions = { girth = 1.1, arm = 1.0, hunch = 0.06 }
local CHAR, CHAR_DARK, MOLTEN = Color3.fromRGB(40, 34, 32), Color3.fromRGB(24, 20, 20), Color3.fromRGB(255, 90, 20)
M.Colors = { skin = CHAR, torso = CHAR, legs = CHAR_DARK, arms = CHAR }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local plate = CHAR:Lerp(rgb(60, 40, 30), Random.new():NextNumber(0, 0.5)) -- (no two burned alike)
	for _, pn in ipairs({ "Chest", "RUpperArm", "LUpperArm", "RLowerArm", "LLowerArm", "RThigh", "LThigh", "RShin", "LShin", "RFoot", "LFoot" }) do
		parts[pn].Material = MAT.CrackedLava -- (the seams under the plate)
		parts[pn].Color = MOLTEN
	end
	-- THE HELM: a squat bucket, two horns swept back, a glowing slit
	parts.Head.Transparency = 1
	deco("Head", "Helm", V(1.3, 1.35, 1.3), at(0, 0.05, 0), plate, MAT.Basalt)
	deco("Head", "Slit", V(1.0, 0.12, 0.04), at(0, 0.18, -0.66), rgb(20, 6, 4), MAT.SmoothPlastic)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "Horn", V(0.22, 0.9, 0.22), at(sx * 0.7, 0.6, 0.1) * CFrame.Angles(-0.5, 0, -sx * 0.6), CHAR_DARK, MAT.Basalt)
	end
	deco("Head", "Gorget", V(1.1, 0.3, 1.1), at(0, -0.75, 0), CHAR_DARK, MAT.Basalt)
	-- plates over the molten body (slightly smaller than full cover, so the glow shows at the seams)
	deco("Chest", "Breastplate", V(cw * 1.04, ch * 0.75, cd * 1.08), at(0, 0.12, 0), plate, MAT.Basalt)
	deco("Chest", "Rune", V(0.25, 0.5, 0.04), at(0, 0.1, -cd * 0.56), MOLTEN, MAT.Neon)
	deco("Hips", "Faulds", V(hw * 1.1, 0.6, hd * 1.1), at(0, -0.1, 0), CHAR_DARK, MAT.Basalt)
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		deco(n .. "UpperArm", "Pauldron", V(aw * 1.6, ua * 0.45, aw * 1.5), at(sx * 0.08, ua * 0.32, 0) * CFrame.Angles(0, 0, -sx * 0.25), plate, MAT.Basalt)
		deco(n .. "LowerArm", "Gauntlet", V(aw * 1.15, 0.5, aw * 1.15), at(0, -la * 0.38, 0), CHAR_DARK, MAT.Basalt)
		deco(n .. "Shin", "Greave", V(lw * 1.08, 0.9, lw * 1.1), at(0, -0.1, 0), plate, MAT.Basalt)
	end
	-- eyes: direct children named "Eye" (two embers in the slit)
	for _, x in ipairs({ -0.22, 0.22 }) do
		deco("Head", "Eye", V(0.1, 0.06, 0.04), at(x, 0.18, -0.68), MOLTEN, MAT.Neon)
	end
end

M.Weapons = {
	CinderBlade = function(w)
		local handle = w.mk("Grip", Vector3.new(0.22, 1.1, 0.22), Color3.fromRGB(30, 24, 22), Enum.Material.Leather)
		w.add(w.mk("Guard", Vector3.new(1.2, 0.16, 0.22), Color3.fromRGB(24, 20, 20), Enum.Material.Basalt), -0.6)
		local blade = w.mk("Blade", Vector3.new(0.3, 3.6, 0.08), Color3.fromRGB(255, 110, 40), Enum.Material.CrackedLava)
		w.add(blade, -2.5)
		local function setup()
			local fire = Instance.new("Fire")
			fire.Size, fire.Heat = 2, 4
			fire.Color, fire.SecondaryColor = Color3.fromRGB(255, 110, 30), Color3.fromRGB(110, 14, 8)
			fire.Parent = blade
			local light = Instance.new("PointLight")
			light.Color, light.Range, light.Brightness = Color3.fromRGB(255, 90, 30), 10, 1.2
			light.Parent = blade
		end
		return { handle = handle, bladeLen = 4.2, setup = setup }
	end,
}

-- stats (the shared brain in GameServer/Enemies.lua reads these): an Errant knight, burnt harder
M.Def = {
	HP = 180, Speed = 11, Scale = 1.1, Damage = 38, Range = 7, HalfAngle = 60,
	Windup = 0.6, Recover = 0.6, Aggro = 40, Leash = 60, Stagger = 0.4,
	HyperArmor = false, Weapon = "CinderBlade", Radius = 1.35, Lunge = 16,
	Poise = 34, HitLevel = "Medium",
	Skin = CHAR, Cloth = CHAR_DARK,
}

M.attack = Hollow.attack

return M
