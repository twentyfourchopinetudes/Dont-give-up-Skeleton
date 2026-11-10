--!nonstrict
-- THE COURT FOOL (kind GildedFool): the king's fool, who stopped being funny about two hundred years ago and hasn't noticed. Thin, double-jointed,
-- gold and rose motley, a three-horned cap with its bells cracked and a grin sewn on. A marotte in its hand: a little head on a stick,
-- with the fool's own face on it, and a blade sticking out of its mouth. It won't stand still and it never stops chuckling.
--   Cartwheel   over and over, sideways then at you, the blade whipping round: wait for it to land
--   Knives      a juggle, then three of them thrown in a spread. Keep moving
--   Punchline   it bows, holds out the marotte for you to kiss... and lunges
local K = require(script.Parent.Parent:WaitForChild("GildedKit"))
local M = K.wrap({
	Poses = {
		GFBCaper = { drop = 0.5, lean = 0.25, side = 0.14, head = 0.25, spread = 0.26, footR = -0.45, footL = 0.5, breathe = 2.2, la1 = 1.1, la3 = -1.2, lel = 1.5, freeL = 0 },
		GFBBow = { drop = 0.65, lean = 1.05, head = 0.3, footR = -0.6, footL = 0.7, spread = 0.16, la1 = 0.5, la3 = -1.3, lel = 0.2, freeL = 0 },
		GFBWheel = { drop = 0.4, lean = 0.5, tuck = 0.8, spread = 0.4, head = 0.1, la1 = 2.2, la3 = -1.3, lel = 0.2, freeL = 0 },
	},
	Grips = { GFStick = { Vector3.new(1, 0.6, -1), CFrame.Angles(math.rad(150), 0, math.rad(-12)) } },
})
M.Kind = "GildedFool"
M.Proportions = { girth = 0.78, arm = 1.14, hunch = 0.12, cadence = 1 }
M.IdlePose = "GFBCaper"
M.BodyFor = { GFStick = "GFBCaper" }
local LOZ_A, LOZ_B, FACE = K.GOLD, K.ROSE, K.PORCELAIN
M.Colors = { skin = FACE, torso = LOZ_A, legs = LOZ_B, arms = LOZ_B }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local ball = Enum.PartType.Ball
	-- a chalk-white face, a sewn-up grin ear to ear, painted diamonds on the eyes
	parts.Head.Material = MAT.SmoothPlastic
	deco("Head", "Grin", V(0.86, 0.05, 0.04), at(0, -0.3, -0.59), K.INK, MAT.SmoothPlastic)
	for i = -4, 4 do
		deco("Head", "Stitch", V(0.03, 0.17, 0.04), at(i * 0.09, -0.3, -0.6), K.INK, MAT.SmoothPlastic)
	end
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "GrinEnd", V(0.16, 0.05, 0.04), at(sx * 0.46, -0.24, -0.57) * CFrame.Angles(0, 0, sx * 0.6), K.INK, MAT.SmoothPlastic)
		deco("Head", "Diamond", V(0.28, 0.28, 0.04), at(sx * 0.27, 0.13, -0.585) * CFrame.Angles(0, 0, math.pi / 4), LOZ_B, MAT.SmoothPlastic)
		deco("Head", "Eye", V(0.09, 0.09, 0.04), at(sx * 0.27, 0.13, -0.6), K.LIGHT, MAT.Neon, ball)
	end
	-- THE CAP: three long floppy horns, a split colour each, a cracked bell on each tip
	deco("Head", "Cap", V(1.28, 0.58, 1.3), at(0, 0.5, 0.02), LOZ_A, MAT.Fabric)
	deco("Head", "CapBand", V(1.32, 0.16, 1.34), at(0, 0.28, 0.02), LOZ_B, MAT.Fabric)
	for _, h in ipairs({ { -1, 0 }, { 1, 0 }, { 0, 1 } }) do
		local sx, back = h[1], h[2]
		local x, y, z = sx * 0.45, 0.74, back * 0.3
		for i = 0, 3 do
			local bend = i * 0.42
			local nx, ny, nz = x + sx * 0.3, y + math.cos(bend) * 0.36, z + back * 0.3
			local sz = 0.42 - i * 0.07
			deco("Head", "Horn", V(sz, 0.46, sz), at(x, y, z) * CFrame.Angles(back * bend, 0, -sx * bend), (i + sx) % 2 == 0 and LOZ_A or LOZ_B, MAT.Fabric)
			x, y, z = nx, ny, nz
		end
		deco("Head", "Bell", V(0.26, 0.26, 0.26), at(x, y - 0.06, z), K.LIGHT, MAT.Metal, ball)
	end
	-- the motley: gold and rose lozenges, a jagged collar with bells on each point
	deco("Chest", "Under", V(cw * 1.02, ch, cd * 1.04), at(0, 0, 0), LOZ_A, MAT.Fabric)
	for ix = -1, 1 do
		for iy = -1, 1 do
			if (ix + iy) % 2 == 0 then
				deco("Chest", "Lozenge", V(0.42, 0.42, 0.04), at(ix * cw * 0.28, iy * ch * 0.28, -cd * 0.55) * CFrame.Angles(0, 0, math.pi / 4), LOZ_B, MAT.Fabric)
				deco("Chest", "Lozenge", V(0.42, 0.42, 0.04), at(ix * cw * 0.28, iy * ch * 0.28, cd * 0.55) * CFrame.Angles(0, 0, math.pi / 4), LOZ_B, MAT.Fabric)
			end
		end
	end
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		local px, pz = math.cos(a) * cw * 0.56, math.sin(a) * cd * 0.8
		deco("Chest", "CollarPoint", V(0.46, 0.14, 0.7), at(px, ch * 0.46, pz) * CFrame.Angles(0, -a + math.pi / 2, 0) * CFrame.Angles(0.5, 0, 0), i % 2 == 0 and LOZ_B or LOZ_A, MAT.Fabric)
		deco("Chest", "CollarBell", V(0.15, 0.15, 0.15), at(px * 1.45, ch * 0.32, pz * 1.45), K.LIGHT, MAT.Metal, ball)
	end
	for i = 0, 5 do
		local x = (i - 2.5) * hw * 0.2
		deco("Hips", "Dag", V(hw * 0.2, 0.7, 0.06), at(x, -0.3, -hd * 0.6) * CFrame.Angles(0, 0, 0.3 * ((i % 2) * 2 - 1)), i % 2 == 0 and LOZ_B or LOZ_A, MAT.Fabric)
		deco("Hips", "Dag", V(hw * 0.2, 0.7, 0.06), at(x, -0.3, hd * 0.6) * CFrame.Angles(0, 0, 0.3 * ((i % 2) * 2 - 1)), i % 2 == 0 and LOZ_A or LOZ_B, MAT.Fabric)
	end
	for _, n in ipairs({ "R", "L" }) do
		local odd = n == "R"
		deco(n .. "Thigh", "Leg", V(lw * 1.05, 1.05, lw * 1.05), at(0, 0, 0), odd and LOZ_A or LOZ_B, MAT.Fabric)
		deco(n .. "Shin", "Leg", V(lw * 1, 1, lw * 1), at(0, 0, 0), odd and LOZ_B or LOZ_A, MAT.Fabric)
		deco(n .. "UpperArm", "Sleeve", V(aw * 1.1, ua, aw * 1.1), at(0, 0, 0), odd and LOZ_A or LOZ_B, MAT.Fabric)
		deco(n .. "LowerArm", "Sleeve", V(aw * 1.04, la, aw * 1.04), at(0, 0, 0), odd and LOZ_B or LOZ_A, MAT.Fabric)
		-- curled shoes with a bell on the toe
		deco(n .. "Foot", "Shoe", V(0.54, 0.24, 1.1), at(0, 0, -0.1), odd and LOZ_B or LOZ_A, MAT.Fabric)
		deco(n .. "Foot", "ShoeCurl", V(0.3, 0.34, 0.3), at(0, 0.14, -0.7) * CFrame.Angles(-0.8, 0, 0), odd and LOZ_A or LOZ_B, MAT.Fabric)
		deco(n .. "Foot", "ToeBell", V(0.18, 0.18, 0.18), at(0, 0.34, -0.84), K.LIGHT, MAT.Metal, ball)
	end
end

M.Weapons = {
	-- a marotte: a stick with a little fool's head on it, its tongue a long thin blade
	Marotte = function(w)
		local handle = w.mk("Grip", Vector3.new(0.16, 0.9, 0.16), K.ROSE, Enum.Material.Fabric)
		w.add(w.mk("Stick", Vector3.new(0.14, 1.5, 0.14), K.GOLD, Enum.Material.Metal), -1.1)
		local head = w.mk("TinyHead", Vector3.new(0.72, 0.8, 0.72), K.PORCELAIN, Enum.Material.SmoothPlastic)
		head.Shape = Enum.PartType.Ball
		w.add(head, -2.2)
		w.add(w.mk("TinyCap", Vector3.new(0.8, 0.28, 0.8), K.ROSE, Enum.Material.Fabric), -1.86)
		for _, s in ipairs({ -1, 1 }) do
			w.add(w.mk("TinyHorn", Vector3.new(0.2, 0.46, 0.2), K.GOLD, Enum.Material.Fabric), -1.68, CFrame.new(s * 0.42 * w.scale, 0, 0) * CFrame.Angles(0, 0, -s * 0.8))
		end
		w.add(w.mk("Blade", Vector3.new(0.3, 3, 0.07), Color3.fromRGB(214, 214, 220), Enum.Material.Metal), -4)
		w.add(w.mk("Edge", Vector3.new(0.05, 3, 0.09), K.LIGHT, Enum.Material.Metal), -4)
		return { handle = handle, bladeLen = 5.4 }
	end,
}

M.Def = K.def({
	HP = 300, Speed = 13, Scale = 1.1, Damage = 28, Range = 7.5, HalfAngle = 50, Lunge = 10, Poise = 30, Stagger = 0.65, StaggerPush = 18,
	Windup = 0.5, Recover = 0.7, Engage = 22, Close = 8, Weapon = "Marotte", IdleGrip = "GFStick", Radius = 1.2, Skin = FACE, Cloth = LOZ_B,
})

local function knives(e, tRoot)
	K.setBody(e, "GBCast", 0.35)
	K.setGrip(e, "GToss", 0.35)
	K.sound(e, "Unsheath", 0.3, 2)
	if not K.hold(e, 0.55, tRoot) then
		return false
	end
	K.setBody(e, "GBFling", 0.1)
	K.setGrip(e, "GTossed", 0.1)
	local from = K.hand(e) + Vector3.new(0, 0.4, 0)
	local base = K.aim(from, tRoot, 55, 0.2)
	for i = -1, 1 do
		K.shot(e, {
			from = from, vel = CFrame.Angles(0, math.rad(i * 14), 0):VectorToWorldSpace(base), damage = 16, level = "Small", radius = 1.2, life = 1.3, gravity = 5,
			size = Vector3.new(0.14, 0.14, 1.2), shape = Enum.PartType.Block, color = Color3.fromRGB(214, 214, 220), trail = K.LIGHT, spin = 24,
		})
	end
	K.sound(e, "Lunge", 0.6, 1.7)
	return true
end

M.attack = K.brain(function(e, tRoot, d)
	local roll = math.random()
	if d > e.def.Close then
		if roll < 0.55 then
			return K.leap(e, tRoot, { set = "GHigh", setBody = "GBLow", tell = 0.55, air = "GRaise", airBody = "GFBWheel", land = "GSlam", landBody = "GBLand", time = 0.6, height = 13, damage = 30, area = 5.5, level = "Large", color = K.LIGHT, boom = 1.5, shake = 0.2, pitch = 1.1 }), 0.8
		end
		return knives(e, tRoot), 0.5
	elseif roll < 0.35 then
		return K.strike(e, tRoot, { setBody = "GFBBow", set = "GGuard", tell = 1, swing = "GThrust", swingBody = "GBLunge", time = 0.08, range = 10, half = 26, damage = 44, level = "Large", lunge = 2.4, speed = 1.3 }), 0.9
	elseif roll < 0.65 then
		return K.whirl(e, tRoot, { grip = "GWide", body = "GFBWheel", wind = 0.35, time = 1.3, radius = 5.5, damage = 18, every = 0.45, speed = 13, turn = 18 }), 0.8
	end
	return K.combo(e, tRoot, {
		{ set = "GCock", setBody = "GBSet", tell = 0.4, swing = "GCut", swingBody = "GBStrike", time = 0.1, damage = 22, level = "Small", speed = 1.35 },
		{ set = "GBack", setBody = "GBWind", tell = 0.18, swing = "GSweep", swingBody = "GBSweep", time = 0.1, damage = 26, level = "Medium", speed = 1.2, quiet = true },
	}), 0.6
end)

return M
