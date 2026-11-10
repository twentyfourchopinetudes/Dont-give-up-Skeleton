--!nonstrict
-- ASHSMITH (kind Ashsmith) - Furnace Brute rework C: the hunched one. The palace's last smith, bent nearly double
-- under the bellows it carries strapped to its back - leather ribbed with boards, wheezing smoke at every step.
-- Long-armed, gaunt, wrapped in soot-black cloth and chain; no face under its deep hood, only the glow of a forge-mouth
-- where one would be (the breath comes out of it). A smith's cross-peen hammer in each fist, swung from those long arms
-- further than it looks. Fights as the Furnace Brute does (Anvilfall, Pistons, Bellows): longer reach, a longer breath,
-- a lighter frame.
local Base = require(script.Parent:WaitForChild("Furnace"))

local M = table.clone(Base)
M.Kind = "Ashsmith"
M.Proportions = { girth = 0.95, arm = 1.38, hunch = 0.38 }
local SOOT, SOOT_LT, IRON = Color3.fromRGB(26, 24, 24), Color3.fromRGB(48, 44, 42), Color3.fromRGB(38, 34, 32)
local HEAT, EMBER, LEATHER, WOOD = Color3.fromRGB(255, 120, 30), Color3.fromRGB(255, 80, 20), Color3.fromRGB(70, 46, 30), Color3.fromRGB(60, 44, 32)
M.Colors = { skin = SOOT, torso = SOOT, legs = SOOT_LT, arms = SOOT }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local up = CFrame.Angles(0, 0, math.pi / 2)
	local cyl = Enum.PartType.Cylinder
	-- THE HOOD: deep, peaked, and in it no face: a forge-mouth's glow
	parts.Head.Color = rgb(8, 6, 6)
	deco("Head", "Hood", V(1.45, 1.5, 1.5), at(0, 0.05, 0.12), SOOT, MAT.Fabric)
	deco("Head", "HoodPeak", V(1.1, 0.5, 1.1), at(0, 0.82, 0.22) * CFrame.Angles(-0.35, 0, 0), SOOT, MAT.Fabric)
	deco("Head", "HoodBrim", V(1.5, 0.3, 0.5), at(0, 0.62, -0.62) * CFrame.Angles(0.4, 0, 0), SOOT_LT, MAT.Fabric)
	deco("Head", "GrateFire", V(0.6, 0.5, 0.04), at(0, -0.05, -0.6), EMBER, MAT.Neon)
	local glow = deco("Head", "Grate", V(0.2, 0.2, 0.2), at(0, -0.05, -0.35), EMBER, MAT.Neon)
	glow.Transparency = 1
	local l = Instance.new("PointLight")
	l.Name = "GrateLight"
	l.Color, l.Range, l.Brightness = HEAT, 10, 1.3
	l.Parent = glow
	-- THE BELLOWS on its back: two boards, the ribbed leather between, an iron nozzle up over its shoulder, smoking
	deco("Chest", "Robe", V(cw * 1.08, ch * 1.02, cd * 1.12), at(0, 0, 0), SOOT, MAT.Fabric)
	local bz = cd * 0.5 + 0.5
	for _, dz in ipairs({ -0.35, 0.35 }) do
		deco("Chest", "BellowsBoard", V(cw * 0.9, ch * 1.1, 0.12), at(0, 0.15, bz + dz), WOOD, MAT.WoodPlanks)
	end
	for i = 0, 3 do
		deco("Chest", "BellowsLeather", V(cw * (0.82 - i * 0.03), ch * (1.0 - i * 0.04), 0.14), at(0, 0.15, bz - 0.25 + i * 0.17), i % 2 == 0 and LEATHER or LEATHER:Lerp(rgb(0, 0, 0), 0.35), MAT.Leather)
	end
	local nozzle = deco("Chest", "Nozzle", V(1.2, 0.3, 0.3), at(-cw * 0.25, ch * 0.75, bz) * up, IRON, MAT.Metal, cyl)
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(rgb(46, 38, 34), rgb(20, 18, 18))
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 2) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
	smoke.Lifetime, smoke.Rate, smoke.Speed = NumberRange.new(1, 2), 5, NumberRange.new(2, 3)
	smoke.EmissionDirection = Enum.NormalId.Right
	smoke.SpreadAngle = Vector2.new(15, 15)
	smoke.Parent = nozzle
	for _, sx in ipairs({ -1, 1 }) do -- (its straps)
		deco("Chest", "Strap", V(0.2, ch * 1.05, cd * 1.2), at(sx * cw * 0.32, 0, 0.1), LEATHER, MAT.Leather)
	end
	-- a smith's apron over the robe, ragged at its hem; a rope belt, tools on it
	deco("Chest", "Apron", V(cw * 0.75, ch * 0.7, 0.07), at(0, -ch * 0.2, -cd * 0.6), LEATHER, MAT.Leather)
	deco("Hips", "ApronLow", V(hw * 1.0, 2.2, 0.07), at(0, -0.9, -hd * 0.64), LEATHER, MAT.Leather)
	deco("Hips", "Belt", V(hw * 1.22, 0.2, hd * 1.25), at(0, 0.3, 0), rgb(90, 76, 56), MAT.Fabric)
	deco("Hips", "Tongs", V(0.12, 1.6, 0.12), at(hw * 0.6, -0.5, 0) * CFrame.Angles(0, 0, 0.15), IRON, MAT.Metal)
	deco("Hips", "RobeSkirt", V(hw * 1.15, 1.6, hd * 1.2), at(0, -0.7, 0.05), SOOT, MAT.Fabric)
	-- arms: chain wound round the forearms, wrapped hands; legs: cloth bindings, bare iron-shod feet
	for _, n in ipairs({ "R", "L" }) do
		deco(n .. "UpperArm", "Sleeve", V(aw * 1.35, ua * 0.95, aw * 1.35), at(0, 0, 0), SOOT, MAT.Fabric)
		for i = 0, 3 do
			deco(n .. "LowerArm", "Chain", V(aw * 1.25, 0.12, aw * 1.25), at(0, la * 0.3 - i * la * 0.2, 0) * CFrame.Angles(0, 0, (i % 2 == 0 and 0.2 or -0.2)), IRON, MAT.Metal)
		end
		deco(n .. "LowerArm", "Wrap", V(aw * 1.15, la * 0.4, aw * 1.15), at(0, -la * 0.28, 0), SOOT_LT, MAT.Fabric)
		deco(n .. "Shin", "Binding", V(lw * 1.1, 0.9, lw * 1.1), at(0, -0.1, 0), SOOT_LT, MAT.Fabric)
		deco(n .. "Foot", "Sole", V(0.7, 0.3, 1.1), at(0, 0.0, -0.05), IRON, MAT.Metal)
	end
end

M.Weapons = {
	-- a smith's cross-peen: a plain haft, a long narrow head, one end a flat face, the other a wedge - glowing from the forge
	SmithHammer = function(w)
		local iron = Color3.fromRGB(40, 36, 34)
		local handle = w.mk("Grip", Vector3.new(0.24, 1.0, 0.24), LEATHER, Enum.Material.Leather)
		w.add(w.mk("Haft", Vector3.new(0.2, 2.6, 0.2), WOOD, Enum.Material.Wood), -1.4)
		w.add(w.mk("Head", Vector3.new(0.6, 0.6, 1.9), iron, Enum.Material.Metal), -2.9)
		w.add(w.mk("Peen", Vector3.new(0.5, 0.18, 0.5), iron, Enum.Material.Metal), -2.9, nil, 1.1)
		local face = w.mk("Face", Vector3.new(0.66, 0.66, 0.14), HEAT, Enum.Material.CrackedLava)
		w.add(face, -2.9, nil, -0.95)
		return { handle = handle, bladeLen = 3.0 }
	end,
}

M.Def = table.clone(Base.Def)
for key, v in pairs({
	HP = 440, Speed = 10, Scale = 1.35, Radius = 1.6, Range = 10.5, Lunge = 10, Poise = 75, Stagger = 0.55,
	Weapon = "SmithHammer", Weapon2 = "SmithHammer", BreathTime = 1.7, BreathReach = 15, Engage = 15,
	Skin = SOOT, Cloth = LEATHER,
}) do
	M.Def[key] = v
end

return M
