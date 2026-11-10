--!nonstrict
-- STOKER (kind Stoker) - Furnace Brute rework A: the lean one. A stoker worked down to sinew and heat: tall, long in the
-- arm, stooped from years over the firebox, bare to the waist and cracked through with fire where the skin's burnt
-- thin. A tall riveted bucket of a helm, its visor a coal-grate the fire shows through; a firebox strapped to its back,
-- its chimney smoking over one shoulder; a heavy leather apron, gauntlets to the elbow. A long-hafted sledge in each
-- fist. Fights as the Furnace Brute does (Anvilfall, Pistons, Bellows - the breath out through its visor), quicker and
-- lighter on its feet, easier to stagger.
local Base = require(script.Parent:WaitForChild("Furnace"))

local M = table.clone(Base)
M.Kind = "Stoker"
M.Proportions = { girth = 1.0, arm = 1.22, hunch = 0.22 }
local IRON, IRON_DK, RIVET = Color3.fromRGB(40, 36, 34), Color3.fromRGB(22, 20, 20), Color3.fromRGB(96, 80, 64)
local HEAT, EMBER, LEATHER = Color3.fromRGB(255, 120, 30), Color3.fromRGB(255, 80, 20), Color3.fromRGB(64, 42, 28)
local SKIN = Color3.fromRGB(62, 34, 24)
M.Colors = { skin = SKIN, torso = SKIN, legs = LEATHER, arms = SKIN }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local up = CFrame.Angles(0, 0, math.pi / 2)
	local cyl, ball = Enum.PartType.Cylinder, Enum.PartType.Ball
	for _, pn in ipairs({ "Chest", "RUpperArm", "LUpperArm" }) do -- (bare: the skin burnt thin, fire in the cracks)
		parts[pn].Material = MAT.CrackedLava
		parts[pn].Color = SKIN
	end
	-- THE HELM: a tall bucket, riveted bands, the visor a grate with the fire behind it (the breath comes out here)
	parts.Head.Transparency = 1
	deco("Head", "Helm", V(1.7, 1.25, 1.25), at(0, 0.15, 0) * up, IRON, MAT.Metal, cyl)
	deco("Head", "HelmLid", V(1.36, 0.16, 1.36), at(0, 1.0, 0), IRON_DK, MAT.Metal)
	for _, y in ipairs({ 0.75, -0.55 }) do
		deco("Head", "HelmBand", V(0.14, 1.3, 1.3), at(0, y, 0) * up, RIVET, MAT.Metal, cyl)
	end
	deco("Head", "GrateFire", V(0.7, 0.42, 0.05), at(0, 0.05, -0.62), EMBER, MAT.Neon)
	for i = -2, 2 do
		deco("Head", "GrateBar", V(0.07, 0.5, 0.08), at(i * 0.15, 0.05, -0.66), IRON_DK, MAT.Metal)
	end
	local glow = deco("Head", "Grate", V(0.2, 0.2, 0.2), at(0, 0.05, -0.4), EMBER, MAT.Neon)
	glow.Transparency = 1
	local l = Instance.new("PointLight")
	l.Name = "GrateLight"
	l.Color, l.Range, l.Brightness = HEAT, 10, 1.2
	l.Parent = glow
	-- THE FIREBOX on its back, its chimney up over the right shoulder
	deco("Chest", "Firebox", V(cw * 0.7, ch * 0.75, 0.7), at(0, 0.05, cd * 0.5 + 0.35), IRON, MAT.Metal)
	deco("Chest", "FireboxDoor", V(cw * 0.4, ch * 0.3, 0.05), at(0, -0.2, cd * 0.5 + 0.72), EMBER, MAT.Neon)
	deco("Chest", "Strap", V(0.18, ch * 1.05, cd * 1.15), at(-cw * 0.3, 0, 0.05) * CFrame.Angles(0, 0, 0.35), LEATHER, MAT.Leather)
	deco("Chest", "Strap", V(0.18, ch * 1.05, cd * 1.15), at(cw * 0.3, 0, 0.05) * CFrame.Angles(0, 0, -0.35), LEATHER, MAT.Leather)
	local stack = deco("Chest", "Stack", V(1.6, 0.36, 0.36), at(cw * 0.3, ch * 0.75, cd * 0.5 + 0.35) * up, IRON_DK, MAT.Metal, cyl)
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(rgb(40, 34, 30), rgb(20, 18, 18))
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 2.4) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
	smoke.Lifetime, smoke.Rate, smoke.Speed = NumberRange.new(1.5, 2.5), 6, NumberRange.new(2, 4)
	smoke.EmissionDirection = Enum.NormalId.Right -- (the stack's axis is its X: up, stood on end)
	smoke.Acceleration, smoke.SpreadAngle = Vector3.new(0.5, 1, 0), Vector2.new(12, 12)
	smoke.Parent = stack
	-- the apron, the belt; gauntlets to the elbow, leather leggings, iron-toed boots
	deco("Hips", "Apron", V(hw * 1.05, 2.2, 0.08), at(0, -0.8, -hd * 0.66), LEATHER, MAT.Leather)
	deco("Chest", "ApronBib", V(cw * 0.6, ch * 0.5, 0.08), at(0, -ch * 0.25, -cd * 0.55), LEATHER, MAT.Leather)
	deco("Hips", "Belt", V(hw * 1.25, 0.28, hd * 1.3), at(0, 0.3, 0), IRON_DK, MAT.Metal)
	for _, n in ipairs({ "R", "L" }) do
		deco(n .. "LowerArm", "Gauntlet", V(aw * 1.45, la * 0.95, aw * 1.45), at(0, -0.02, 0), LEATHER:Lerp(rgb(0, 0, 0), 0.3), MAT.Leather)
		deco(n .. "LowerArm", "GauntletCuff", V(aw * 1.6, 0.22, aw * 1.6), at(0, la * 0.42, 0), IRON_DK, MAT.Metal)
		deco(n .. "UpperArm", "ArmWrap", V(aw * 1.08, ua * 0.3, aw * 1.08), at(0, -ua * 0.25, 0), LEATHER, MAT.Fabric)
		deco(n .. "Shin", "Greave", V(lw * 1.15, 0.9, lw * 1.15), at(0, -0.15, 0), IRON, MAT.Metal)
		deco(n .. "Foot", "Boot", V(0.75, 0.38, 1.15), at(0, 0.05, -0.05), IRON_DK, MAT.Metal)
	end
end

M.Weapons = {
	-- a stoker's sledge: a long ash haft, a small square head of black iron, its face burnt orange
	StokerSledge = function(w)
		local iron = Color3.fromRGB(36, 32, 30)
		local handle = w.mk("Grip", Vector3.new(0.26, 1.1, 0.26), LEATHER, Enum.Material.Leather)
		w.add(w.mk("Haft", Vector3.new(0.22, 4.0, 0.22), Color3.fromRGB(70, 52, 36), Enum.Material.Wood), -2.0)
		w.add(w.mk("Head", Vector3.new(0.8, 0.8, 1.5), iron, Enum.Material.Metal), -4.2)
		local face = w.mk("Face", Vector3.new(0.84, 0.84, 0.12), HEAT, Enum.Material.CrackedLava)
		w.add(face, -4.2, nil, -0.78)
		w.add(w.mk("HeadBand", Vector3.new(0.86, 0.86, 0.14), RIVET, Enum.Material.Metal), -4.2, nil, 0.4)
		return { handle = handle, bladeLen = 4.2 }
	end,
}

M.Def = table.clone(Base.Def)
for key, v in pairs({
	HP = 420, Speed = 10.5, Scale = 1.3, Damage = 40, Range = 9.5, Radius = 1.5, Lunge = 10,
	Poise = 70, Stagger = 0.5, Windup = 0.95, Recover = 1.1, Weapon = "StokerSledge", Weapon2 = "StokerSledge",
	BreathReach = 12, Skin = SKIN, Cloth = LEATHER,
}) do
	M.Def[key] = v
end

return M
