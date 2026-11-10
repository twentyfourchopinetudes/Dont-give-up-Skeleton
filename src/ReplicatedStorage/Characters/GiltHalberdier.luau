--!nonstrict
-- GILT HALBERDIER (kind GiltHalberdier): the palace guard, long after there was anyone inside the armour. A suit of gilded plate with
-- nothing in it but a little dust, a tall crimson plume, a crimson tabard with the sun on it, and an eight-foot halberd held
-- at exact regulation. Nothing about it hurries.
--   Sweep    the whole length of it swung flat, a wide arc: roll inside it
--   Thrust   drawn back, then a long straight lunge: step off the line
--   Bash     up close, the butt of the haft into your teeth
local K = require(script.Parent.Parent:WaitForChild("GildedKit"))
local M = K.wrap({
	Poses = { GHBStand = { drop = 0.05, lean = -0.02, head = 0.05, footR = -0.1, footL = 0.1, spread = 0.05, breathe = 0.3, la1 = 0.1, la3 = -0.15, lel = 0.2, freeL = 0 } },
	Grips = { GHAttention = { Vector3.new(1.05, 0.5, -0.5), CFrame.Angles(math.rad(176), 0, math.rad(-3)) } },
})
M.Kind = "GiltHalberdier"
M.Proportions = { girth = 1.08, arm = 1.05, hunch = 0 }
M.IdlePose = "GHBStand"
M.BodyFor = { GHAttention = "GHBStand" }
local GOLD, DARK, CAPE = K.GOLD, K.TARNISH, K.RUG
M.Colors = { skin = K.INK, torso = GOLD, legs = DARK, arms = GOLD }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	-- THE HELM: a tall closed sallet, a barred visor with nothing behind it, the plume standing high
	parts.Head.Transparency = 1
	deco("Head", "Helm", V(1.25, 1.35, 1.35), at(0, 0.1, 0.02), GOLD, MAT.Metal)
	deco("Head", "HelmPeak", V(0.2, 0.55, 1.15), at(0, 0.95, 0), DARK, MAT.Metal)
	deco("Head", "Visor", V(0.95, 0.45, 0.06), at(0, 0.12, -0.7), K.INK, MAT.SmoothPlastic)
	for i = -2, 2 do
		deco("Head", "VisorBar", V(0.07, 0.5, 0.07), at(i * 0.18, 0.12, -0.74), GOLD, MAT.Metal)
	end
	for i = 0, 5 do
		deco("Head", "Plume", V(0.3, 0.55 - i * 0.04, 0.42), at(0, 1.3 + i * 0.3, 0.05 + i * i * 0.05) * CFrame.Angles(-0.2 - i * 0.14, 0, 0), CAPE, MAT.Fabric)
	end
	-- the breastplate, its gorget and the tabard over it, sun and all
	deco("Chest", "Breast", V(cw * 1.04, ch * 0.9, cd * 1.1), at(0, 0.05, 0), GOLD, MAT.Metal)
	deco("Chest", "Gorget", V(cw * 0.6, 0.34, cd * 1.15), at(0, ch / 2, 0), DARK, MAT.Metal)
	deco("Chest", "Tabard", V(cw * 0.56, ch * 0.92, 0.07), at(0, -0.02, -cd * 0.58), CAPE, MAT.Fabric)
	deco("Chest", "TabardSun", V(0.06, 0.62, 0.62), at(0, 0.18, -cd * 0.62) * K.FACE, K.LIGHT, MAT.Metal, Enum.PartType.Cylinder)
	deco("Hips", "TabardLow", V(hw * 0.62, 2.1, 0.07), at(0, -0.85, -hd * 0.62), CAPE, MAT.Fabric)
	deco("Hips", "TabardBack", V(hw * 0.62, 2.1, 0.07), at(0, -0.85, hd * 0.62), CAPE, MAT.Fabric)
	deco("Hips", "Fauld", V(hw * 1.15, 0.75, hd * 1.2), at(0, -0.1, 0), DARK, MAT.Metal)
	deco("Hips", "Belt", V(hw * 1.22, 0.2, hd * 1.26), at(0, 0.28, 0), GOLD, MAT.Metal)
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		deco(n .. "UpperArm", "Pauldron", V(aw * 1.9, 0.55, aw * 1.8), at(sx * 0.1, ua / 2 - 0.1, 0) * CFrame.Angles(0, 0, -sx * 0.3), GOLD, MAT.Metal)
		deco(n .. "UpperArm", "PauldronLame", V(aw * 1.7, 0.18, aw * 1.6), at(sx * 0.08, ua / 2 - 0.45, 0) * CFrame.Angles(0, 0, -sx * 0.2), DARK, MAT.Metal)
		deco(n .. "LowerArm", "Vambrace", V(aw * 1.18, la * 0.72, aw * 1.18), at(0, -0.05, 0), GOLD, MAT.Metal)
		deco(n .. "Thigh", "Cuisse", V(lw * 1.16, 0.85, lw * 1.16), at(0, 0.05, 0), GOLD, MAT.Metal)
		deco(n .. "Shin", "Greave", V(lw * 1.14, 0.8, lw * 1.14), at(0, -0.1, 0), GOLD, MAT.Metal)
		deco(n .. "Shin", "Poleyn", V(lw * 1.25, 0.34, lw * 1.3), at(0, 0.5, -0.05), DARK, MAT.Metal)
		deco(n .. "Foot", "Sabaton", V(0.7, 0.3, 1.15), at(0, 0.02, -0.05), DARK, MAT.Metal)
	end
end

M.Weapons = {
	-- a long ash haft, gold-bound; a broad axe blade, a hook behind it, a spike along the top
	GiltHalberd = function(w)
		local gold, steel = K.GOLD, Color3.fromRGB(176, 170, 150)
		local handle = w.mk("Grip", Vector3.new(0.24, 1.1, 0.24), K.RUG, Enum.Material.Fabric)
		w.add(w.mk("Haft", Vector3.new(0.2, 7.2, 0.2), Color3.fromRGB(80, 58, 38), Enum.Material.Wood), -2.2)
		w.add(w.mk("Butt", Vector3.new(0.3, 0.8, 0.3), gold, Enum.Material.Metal), 1.5)
		w.add(w.mk("Band", Vector3.new(0.28, 0.2, 0.28), gold, Enum.Material.Metal), -1)
		w.add(w.mk("Socket", Vector3.new(0.34, 1.3, 0.34), gold, Enum.Material.Metal), -5.5)
		w.add(w.mk("Blade", Vector3.new(0.12, 1.9, 1.5), steel, Enum.Material.Metal), -5.6, nil, -0.75)
		w.add(w.mk("BladeEdge", Vector3.new(0.14, 2.1, 0.22), gold, Enum.Material.Metal), -5.6, nil, -1.55)
		w.add(w.mk("Hook", Vector3.new(0.12, 0.5, 0.95), steel, Enum.Material.Metal), -5.6, nil, 0.6)
		w.add(w.mk("Spike", Vector3.new(0.18, 1.6, 0.18), steel, Enum.Material.Metal), -6.9)
		return { handle = handle, bladeLen = 6.8 }
	end,
}

M.Def = K.def({
	HP = 480, Speed = 9.5, Scale = 1.3, Damage = 42, Range = 12, HalfAngle = 75, Lunge = 7, Poise = 80, Stagger = 0.45,
	Engage = 13, Close = 6, Weapon = "GiltHalberd", IdleGrip = "GHAttention", Radius = 1.6, Skin = K.GOLD, Cloth = K.RUG,
})

M.attack = K.brain(function(e, tRoot, d)
	if d < e.def.Close then
		return K.strike(e, tRoot, { set = "GCock", setBody = "GBSet", tell = 0.5, swing = "GSlam", swingBody = "GBStrike", range = 7, half = 60, damage = 28, level = "Medium", speed = 0.9 }), 0.7
	elseif math.random() < 0.5 then
		return K.strike(e, tRoot, { set = "GBack", setBody = "GBWind", tell = 0.95, swing = "GSweep", swingBody = "GBSweep", time = 0.22, range = 12.5, half = 85, lunge = 0.8, speed = 0.6 }), 1.1
	end
	return K.strike(e, tRoot, { set = "GDraw", setBody = "GBDraw", tell = 0.85, swing = "GThrust", swingBody = "GBLunge", time = 0.14, range = 14, half = 16, lunge = 2.4, speed = 0.8 }), 1
end)

return M
