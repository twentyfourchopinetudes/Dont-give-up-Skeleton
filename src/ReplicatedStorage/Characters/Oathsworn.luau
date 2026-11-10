--!nonstrict
-- THE OATHSWORN (kind Oathsworn): a knight of the Silver Oath, one of the many the Silver Knight never mentions. The same fluted steel and crimson
-- as Caelen, made plainer for the rank and file and gone dull, half the height of his sword; a white surcoat with the sun on it, torn off
-- at the waist, a crimson half-cape. It fights as he was taught them all to fight. If you've beaten him, you've seen this.
--   The Spring   down on its haunches, then a flat leap through you, the blade out in front
--   Oathbreaker  a falling cut, then a rising one, then a straight thrust: never rushed
--   Judgement    from further off: up high over you, and the blade brought down two-handed where you stood
--   Sworn        when it's hurt it plants the sword and kneels for a moment, with its hands on the hilt. It gets a little back
local K = require(script.Parent.Parent:WaitForChild("GildedKit"))
local M = K.wrap({
	Poses = {
		OSBGuard = { drop = 0.4, lean = 0.1, twist = 0.2, head = -0.05, spread = 0.18, footR = -0.5, footL = 0.55, breathe = 0.8, la1 = 0.6, la3 = -0.4, lel = 1, freeL = 0 },
		OSBKneel = { drop = 1.45, lean = 0.3, head = 0.42, footR = 1, footL = -1.3, la1 = 0.9, la3 = -0.15, lel = 0.15, freeL = 0 },
	},
	Grips = {
		OSReady = { Vector3.new(0.9, 0.3, -1.1), CFrame.Angles(math.rad(135), 0, math.rad(-8)) },
		OSPlant = { Vector3.new(0.1, -0.4, -1.3), CFrame.Angles(0, 0, 0) },
	},
})
M.Kind = "Oathsworn"
M.Proportions = { girth = 0.95, arm = 1.08, hunch = 0.05 }
M.IdlePose = "OSBGuard"
M.BodyFor = { OSReady = "OSBGuard" }
local STEEL, STEEL_DK, SURCOAT, CAPE = Color3.fromRGB(162, 166, 174), Color3.fromRGB(110, 114, 124), Color3.fromRGB(212, 208, 196), Color3.fromRGB(112, 22, 22)
M.Colors = { skin = STEEL, torso = STEEL, legs = STEEL_DK, arms = STEEL }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local rng = Random.new()
	-- the helm, Caelen's shape without the crown: the same T of a slit, a short crest
	deco("Head", "Helm", V(1.15, 1.15, 1.2), at(0, 0.255, 0), STEEL, MAT.Metal)
	deco("Head", "HelmJaw", V(0.75, 0.35, 1.2), at(0, -0.495, 0), STEEL, MAT.Metal)
	deco("Head", "HelmCrest", V(0.14, 0.42, 1.2), at(0, 0.9, 0), STEEL_DK, MAT.Metal)
	deco("Head", "Slit", V(0.9, 0.09, 0.05), at(0, 0.2, -0.62), rgb(6, 6, 8), MAT.SmoothPlastic)
	deco("Head", "SlitDown", V(0.12, 0.6, 0.05), at(0, -0.12, -0.62), rgb(6, 6, 8), MAT.SmoothPlastic)
	deco("Head", "HelmBand", V(1.19, 0.1, 1.24), at(0, 0.62, 0), K.GOLD, MAT.Metal)
	-- the breastplate under a white surcoat cut short, the sun on it; the steel showing at the shoulders
	deco("Chest", "Breastplate", V(cw * 1.02, ch * 0.82, 0.3), at(0, 0.08, -cd / 2 - 0.1), STEEL, MAT.Metal)
	deco("Chest", "Backplate", V(cw, ch * 0.82, 0.24), at(0, 0.08, cd / 2 + 0.08), STEEL, MAT.Metal)
	deco("Chest", "Gorget", V(cw * 0.6, 0.36, cd * 1.15), at(0, ch / 2 - 0.02, 0), STEEL, MAT.Metal)
	deco("Chest", "Surcoat", V(cw * 0.64, ch * 0.88, 0.06), at(0, 0, -cd / 2 - 0.28), SURCOAT, MAT.Fabric)
	deco("Chest", "Sun", V(0.06, 0.56, 0.56), at(0, 0.2, -cd / 2 - 0.33) * K.FACE, K.GOLD, MAT.Metal, Enum.PartType.Cylinder)
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		deco("Chest", "SunRay", V(0.07, 0.22, 0.04), at(math.cos(a) * 0.42, 0.2 + math.sin(a) * 0.42, -cd / 2 - 0.33) * CFrame.Angles(0, 0, a - math.pi / 2), K.GOLD, MAT.Metal)
	end
	k.tatter(rng, "Hips", CFrame.new(0, 0.05, -hd * 0.66), hw * 0.72, 1.75, SURCOAT, SURCOAT:Lerp(rgb(60, 50, 40), 0.5), 0.55)
	k.tatter(rng, "Hips", CFrame.new(0, 0.05, hd * 0.66), hw * 0.72, 1.6, SURCOAT, SURCOAT:Lerp(rgb(60, 50, 40), 0.5), 0.55)
	deco("Hips", "Belt", V(hw + 0.16, 0.24, hd + 0.16), at(0, 0.3, 0), rgb(40, 30, 24), MAT.Leather)
	deco("Hips", "Buckle", V(0.32, 0.26, 0.06), at(0, 0.3, -hd / 2 - 0.1), K.GOLD, MAT.Metal)
	-- a torn half-cape off the right shoulder
	K.cloth(deco("Chest", "CapeAnchor", V(0.2, 0.2, 0.2), at(cw * 0.25, ch / 2 - 0.15, cd / 2 + 0.25) * K.BACK, CAPE, MAT.SmoothPlastic), 5, 0.9 * k.s, cw * 0.75 * k.s, CAPE)
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		deco(n .. "UpperArm", "Pauldron", V(aw * 1.75, 0.5, aw * 1.65), at(sx * 0.1, ua / 2 - 0.1, 0) * CFrame.Angles(0, 0, -sx * 0.3), STEEL, MAT.Metal)
		deco(n .. "UpperArm", "PauldronLame", V(aw * 1.55, 0.2, aw * 1.45), at(sx * 0.08, ua / 2 - 0.42, 0) * CFrame.Angles(0, 0, -sx * 0.2), STEEL_DK, MAT.Metal)
		deco(n .. "LowerArm", "Vambrace", V(aw * 1.15, la * 0.65, aw * 1.15), at(0, -0.05, 0), STEEL, MAT.Metal)
		deco(n .. "LowerArm", "Gauntlet", V(aw * 1.25, 0.46, aw * 1.25), at(0, -la / 2 + 0.2, 0), STEEL_DK, MAT.Metal)
		deco(n .. "Thigh", "Cuisse", V(lw * 1.15, 0.86, lw * 1.15), at(0, 0.05, 0), STEEL, MAT.Metal)
		deco(n .. "Shin", "Greave", V(lw * 1.12, 0.74, lw * 1.12), at(0, -0.1, 0), STEEL, MAT.Metal)
		deco(n .. "Shin", "Poleyn", V(lw * 1.25, 0.38, lw * 1.3), at(0, 0.47, -0.05), K.TARNISH, MAT.Metal)
		deco(n .. "Foot", "Sabaton", V(0.66, 0.26, 1.12), at(0, 0.02, -0.05), STEEL_DK, MAT.Metal)
	end
end

M.Weapons = {
	-- Caelen's blade for those who aren't Caelen: straight, broad, plain, as long as its bearer is tall
	OathBlade = function(w)
		local steel, dark, gold = Color3.fromRGB(170, 172, 178), Color3.fromRGB(46, 44, 46), Color3.fromRGB(176, 140, 66)
		local handle = w.mk("Grip", Vector3.new(0.26, 1.3, 0.26), dark, Enum.Material.Leather)
		w.add(w.mk("Pommel", Vector3.new(0.5, 0.5, 0.18), gold, Enum.Material.Metal), 0.78)
		w.add(w.mk("Guard", Vector3.new(2, 0.22, 0.3), gold, Enum.Material.Metal), -0.72)
		w.add(w.mk("Blade", Vector3.new(0.85, 5.2, 0.12), steel, Enum.Material.Metal), -3.4)
		w.add(w.mk("Fuller", Vector3.new(0.24, 4.4, 0.14), Color3.fromRGB(116, 118, 124), Enum.Material.Metal), -3.15)
		w.add(w.mk("Point", Vector3.new(0.6, 0.6, 0.12), steel, Enum.Material.Metal), -6, CFrame.Angles(0, 0, math.pi / 4))
		return { handle = handle, bladeLen = 6, gripC1 = CFrame.Angles(0, math.pi / 2, 0) }
	end,
}

M.Def = K.def({
	HP = 460, Speed = 10.5, Scale = 1.3, Damage = 44, Range = 10, HalfAngle = 55, Lunge = 9, Poise = 75, Stagger = 0.45, StaggerPush = 9,
	Windup = 0.7, Recover = 0.9, Engage = 22, Close = 9, Weapon = "OathBlade", IdleGrip = "OSReady", Radius = 1.6, Skin = STEEL, Cloth = CAPE,
})

local function sworn(e)
	e.swornAt = os.clock()
	K.setGrip(e, "OSPlant", 0.35)
	K.setBody(e, "OSBKneel", 0.35)
	K.sound(e, "Impact", 0.6, 0.6)
	if not K.hold(e, 1.5) then
		return false
	end
	e.hum.Health = math.min(e.hum.MaxHealth, e.hum.Health + e.hum.MaxHealth * 0.12)
	K.flash(e.root.Position, K.LIGHT, 4)
	return true
end

M.attack = K.brain(function(e, tRoot, d)
	if e.hum.Health < e.hum.MaxHealth * 0.45 and (not e.swornAt or os.clock() - e.swornAt > 18) and d > 6 then
		return sworn(e), 0.2
	elseif d > e.def.Close and math.random() < 0.45 then
		return K.leap(e, tRoot, {
			set = "GRaise", setBody = "GBLow", tell = 0.7, air = "GRaise", airBody = "GBAir", land = "GSlam", landBody = "GBLand",
			time = 0.65, height = 14, damage = 46, area = 5.5, level = "Knockdown", color = K.SILVER, boom = 1.05,
		}), 1.2
	elseif d > e.def.Close then
		return K.rush(e, tRoot, { set = "GDraw", setBody = "GBLow", tell = 0.75, drive = "GThrust", driveBody = "GBLunge", speed = 52, time = 0.42, damage = 48, level = "Knockdown", reach = 5, pitch = 0.85 }), 1.15
	end
	return K.combo(e, tRoot, {
		{ set = "GCock", setBody = "GBSet", tell = 0.62, swing = "GCut", swingBody = "GBStrike", time = 0.16, damage = 34, level = "Medium", speed = 0.9 },
		{ set = "GWide", setBody = "GBWind", tell = 0.34, swing = "GRaise", swingBody = "GBCast", time = 0.15, damage = 32, level = "Medium", speed = 1, quiet = true },
		{ set = "GDraw", setBody = "GBDraw", tell = 0.5, swing = "GThrust", swingBody = "GBLunge", time = 0.12, range = 12, half = 20, damage = 44, lunge = 1.7, speed = 0.92, quiet = true },
	}), 1.15
end)

return M
