--!nonstrict
-- THE GILT SERAPH (kind GiltSeraph): off the cathedral's roof. A statue of beaten gold, hollow as a bell, on six huge sheet-gold wings it
-- holds folded round itself when it's waiting. Its face is a smooth blank, a halo fixed behind its head on a rod. Somebody stole
-- its hands long ago and fitted a long gold spear in the stumps.
--   Descent     its wings snap open, it goes up, hangs, and comes down spear-first where you stood
--   Wing Cut    a wing swept right round it, the leading edge sharp
--   Lance       the spear, thrown from the wrist on a short run
--   Featherfall three of its sheet-gold feathers torn loose and flung at you in a fan
local K = require(script.Parent.Parent:WaitForChild("GildedKit"))
local M = K.wrap({
	Poses = {
		GSBHover = { drop = -0.1, lean = 0.1, head = 0.15, footR = -0.25, footL = -0.1, spread = 0.02, breathe = 0.4, la1 = 0.5, la3 = -0.3, lel = 1.2, freeL = 0 },
		GSBDive = { drop = 0.2, lean = 1, head = -0.4, footR = -1, footL = -0.85, spread = 0.03, la1 = -0.5, la3 = -0.1, freeL = 0 },
	},
	Grips = { GSSpear = { Vector3.new(1, 0.1, -0.8), CFrame.Angles(math.rad(165), 0, 0) } },
})
M.Kind = "GiltSeraph"
M.Proportions = { girth = 0.88, arm = 1, hunch = 0 }
M.IdlePose = "GSBHover"
M.BodyFor = { GSSpear = "GSBHover" }
local AU, AU_DK, AU_LT = K.GOLD, K.TARNISH, K.LIGHT
M.Colors = { skin = AU, torso = AU, legs = AU, arms = AU }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	for name, p in pairs(parts) do
		if name ~= "HumanoidRootPart" then
			p.Material = MAT.Metal
		end
	end
	-- a smooth blank mask of a face; a halo behind it on a rod, its rim toothed with little rays
	deco("Head", "Blank", V(1.08, 1.32, 1.05), at(0, 0, -0.06), AU_LT, MAT.Metal, Enum.PartType.Ball)
	deco("Head", "HaloRod", V(0.1, 0.1, 0.72), at(0, 0.1, 0.72), AU_DK, MAT.Metal)
	local rays = 14
	for i = 0, rays - 1 do
		local a = i / rays * math.pi * 2
		deco("Head", "Halo", V(0.2, 0.62, 0.07), at(math.cos(a) * 1.25, 0.1 + math.sin(a) * 1.25, 1.05) * CFrame.Angles(0, 0, a + math.pi / 2), AU_LT, MAT.Metal)
		deco("Head", "HaloRay", V(0.1, 0.38, 0.05), at(math.cos(a + 0.22) * 1.68, 0.1 + math.sin(a + 0.22) * 1.68, 1.05) * CFrame.Angles(0, 0, a + 0.22 - math.pi / 2), AU, MAT.Neon)
	end
	-- a long pleated robe of sheet metal, open to the ankles, hanging clear of the floor
	deco("Chest", "Robe", V(cw * 1.04, ch * 1, cd * 1.08), at(0, 0, 0), AU, MAT.Metal)
	for i = -2, 2 do
		deco("Chest", "Pleat", V(0.14, ch * 0.92, 0.1), at(i * cw * 0.17, 0, -cd * 0.56), AU_LT, MAT.Metal)
		deco("Hips", "RobePleat", V(0.28, 3.1, 0.14), at(i * hw * 0.2, -1.25, -hd * 0.58), i % 2 == 0 and AU or AU_LT, MAT.Metal)
		deco("Hips", "RobePleat", V(0.28, 3.1, 0.14), at(i * hw * 0.2, -1.25, hd * 0.58), i % 2 == 0 and AU_LT or AU, MAT.Metal)
	end
	deco("Chest", "Girdle", V(cw * 0.92, 0.2, cd * 1.15), at(0, -ch * 0.28, 0), K.RUG, MAT.Fabric)
	deco("Chest", "Stole", V(0.32, ch * 1, 0.05), at(0, 0, -cd * 0.62), K.RUG, MAT.Fabric)
	-- THE WINGS: three pairs of long sheet-gold feathers, fanned out from between the shoulders
	for _, sx in ipairs({ -1, 1 }) do
		for pair, wing in ipairs({ { 0.9, 0.62, 1.05 }, { 0.2, 0.36, 0.86 }, { -0.5, 0.18, 0.62 } }) do
			local up, tilt, size = wing[1], wing[2], wing[3]
			for f = 0, 4 do
				local len = (3.7 - f * 0.45) * size
				local a = tilt + f * 0.2 * sx * sx
				deco("Chest", "Feather", V(0.34 - f * 0.02, len, 0.06),
					at(sx * (0.5 + len * 0.4 * math.sin(a + 0.25)), up + ch * 0.1 + len * 0.42 * math.cos(a + 0.25) - f * 0.14, cd * 0.56 + pair * 0.1 + f * 0.03) * CFrame.Angles(0.1, 0, -sx * (a + 0.25)),
					f % 2 == 0 and AU or AU_LT, MAT.Metal)
			end
		end
	end
	for _, n in ipairs({ "R", "L" }) do
		deco(n .. "UpperArm", "Sleeve", V(aw * 1.28, ua * 0.95, aw * 1.28), at(0, 0, 0), AU_LT, MAT.Metal)
		deco(n .. "LowerArm", "Stump", V(aw * 1.1, 0.26, aw * 1.1), at(0, -la / 2 - 0.05, 0), AU_DK, MAT.Metal)
		parts[n .. "Foot"].Transparency = 1
	end
end

M.Weapons = {
	SeraphSpear = function(w)
		local gold = K.GOLD
		local handle = w.mk("Grip", Vector3.new(0.18, 1, 0.18), K.RUG, Enum.Material.Fabric)
		w.add(w.mk("Shaft", Vector3.new(0.14, 7.4, 0.14), gold, Enum.Material.Metal), -2.2)
		w.add(w.mk("Foot", Vector3.new(0.24, 0.5, 0.24), K.TARNISH, Enum.Material.Metal), 1.7)
		w.add(w.mk("Head", Vector3.new(0.5, 2, 0.12), K.LIGHT, Enum.Material.Metal), -6.6)
		w.add(w.mk("Tip", Vector3.new(0.36, 0.36, 0.1), K.LIGHT, Enum.Material.Metal), -7.65, CFrame.Angles(0, 0, math.pi / 4))
		w.add(w.mk("Lug", Vector3.new(1.1, 0.14, 0.14), gold, Enum.Material.Metal), -5.5)
		return { handle = handle, bladeLen = 7.8 }
	end,
}

M.Def = K.def({
	HP = 410, Speed = 11, Scale = 1.3, Damage = 44, Range = 11, HalfAngle = 25, Lunge = 9, Poise = 60, Stagger = 0.5, StaggerPush = 12,
	Windup = 0.75, Recover = 1.05, Engage = 28, Close = 9, Weapon = "SeraphSpear", IdleGrip = "GSSpear", Radius = 1.5, Skin = AU, Cloth = AU,
})

local function featherfall(e, tRoot)
	K.setBody(e, "GBCast", 0.5)
	K.sound(e, "Unsheath", 0.5, 1.3)
	if not K.hold(e, 0.7, tRoot) or not tRoot.Parent then
		return false
	end
	K.setBody(e, "GBFling", 0.12)
	K.sound(e, "Lunge", 0.7, 1.2)
	local from = e.root.Position + Vector3.new(0, 2.2, 0)
	local base = K.aim(from, tRoot, 85, 0.2)
	for i = -1, 1 do
		K.shot(e, {
			from = from + e.root.CFrame.RightVector * i * 1.2, vel = CFrame.Angles(0, math.rad(i * 9), 0):VectorToWorldSpace(base),
			damage = 24, level = "Medium", radius = 1.4, life = 1.6, size = Vector3.new(0.25, 0.08, 1.8), shape = Enum.PartType.Block,
			color = AU_LT, trail = AU_LT,
		})
	end
	return K.hold(e, 0.3, tRoot)
end

M.attack = K.brain(function(e, tRoot, d)
	local roll = math.random()
	if d > e.def.Close and roll < 0.25 then
		return featherfall(e, tRoot), 0.9
	elseif d > e.def.Close and roll < 0.75 then
		return K.leap(e, tRoot, {
			set = "GHigh", setBody = "GBCast", tell = 0.8, air = "GLevel", airBody = "GSBDive", land = "GSlam", landBody = "GBLand",
			time = 0.8, height = 22, damage = 52, area = 6.5, level = "Knockdown", color = AU_LT, boom = 1,
		}), 1.3
	elseif d > e.def.Close then
		return K.rush(e, tRoot, { set = "GDraw", setBody = "GBDraw", tell = 0.7, drive = "GThrust", driveBody = "GSBDive", speed = 48, time = 0.48, damage = 42, level = "Large", pitch = 0.95 }), 1
	end
	if roll < 0.55 then
		return K.strike(e, tRoot, { set = "GBack", setBody = "GBWind", tell = 0.7, swing = "GSweep", swingBody = "GBSweep", time = 0.18, range = 9, half = 120, damage = 38, speed = 0.9 }), 0.9
	end
	return K.strike(e, tRoot, { set = "GDraw", setBody = "GBDraw", tell = 0.68, swing = "GThrust", swingBody = "GBLunge", time = 0.13, range = 12, half = 20, damage = 44, lunge = 1.6, speed = 0.9 }), 1
end)

return M
