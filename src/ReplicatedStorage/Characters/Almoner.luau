--!nonstrict
-- THE ALMONER (kind Almoner): the Almonry's keeper, still giving charity to whoever comes, whether they want it or not. A stooped figure in
-- grey wool and a gold-edged hood, a coin-hole for a mouth, begging bowls hung about its belt. It swings a great sack of
-- gold on a rope, and it throws handfuls of coin hard enough to go through you.
--   Largesse   an arm flung out: a fan of hot coins, flat and fast. Between them, or roll
--   Tithe      the sack up and over, down on your head. It'll drop a few coins where it lands
local K = require(script.Parent.Parent:WaitForChild("GildedKit"))
local M = K.wrap({
	Poses = { ALBStoop = { drop = 0.3, lean = 0.3, head = 0.12, footR = -0.25, footL = 0.3, spread = 0.1, breathe = 1.2, la1 = 0.5, la3 = -0.3, lel = 1.4, freeL = 0 } },
	Grips = { ALHang = { Vector3.new(1.35, -0.2, 0.2), CFrame.Angles(math.rad(6), 0, 0) } },
})
M.Kind = "Almoner"
M.Proportions = { girth = 1.02, arm = 1.12, hunch = 0.3 }
M.IdlePose = "ALBStoop"
M.BodyFor = { ALHang = "ALBStoop" }
local WOOL, WOOL_DK = Color3.fromRGB(156, 150, 138), Color3.fromRGB(116, 110, 100)
M.Colors = { skin = K.INK, torso = WOOL, legs = WOOL_DK, arms = WOOL }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local rng = Random.new()
	-- THE HOOD, gold-edged, and in it a mask of plain tin with a slot where a mouth would be, as on an alms box
	deco("Head", "Hood", V(1.5, 1.55, 1.5), at(0, 0.08, 0.14), WOOL, MAT.Fabric)
	deco("Head", "HoodPeak", V(1, 0.5, 1), at(0, 0.88, 0.28) * CFrame.Angles(-0.4, 0, 0), WOOL, MAT.Fabric)
	deco("Head", "HoodEdge", V(1.58, 0.14, 0.14), at(0, 0.72, -0.62), K.GOLD, MAT.Metal)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "HoodEdge", V(0.14, 1.3, 0.14), at(sx * 0.76, 0.08, -0.62), K.GOLD, MAT.Metal)
	end
	deco("Head", "Tin", V(1.08, 1.18, 0.1), at(0, 0.02, -0.56), rgb(150, 142, 118), MAT.Metal)
	deco("Head", "Slot", V(0.52, 0.09, 0.05), at(0, -0.24, -0.62), K.INK, MAT.SmoothPlastic)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "Eye", V(0.12, 0.12, 0.05), at(sx * 0.24, 0.16, -0.62), K.LIGHT, MAT.Neon, Enum.PartType.Ball)
		deco("Head", "Rivet", V(0.08, 0.08, 0.04), at(sx * 0.44, -0.42, -0.62), K.GOLD, MAT.Metal, Enum.PartType.Ball)
	end
	-- the robe, a gold stole, patched at the hem; a rope belt strung with begging bowls and a coin-purse or two
	deco("Chest", "Robe", V(cw * 1.1, ch * 1.02, cd * 1.15), at(0, 0, 0.02), WOOL, MAT.Fabric)
	deco("Chest", "Mantle", V(cw * 1.22, 0.7, cd * 1.3), at(0, ch * 0.34, 0.04), WOOL_DK, MAT.Fabric)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Chest", "Stole", V(0.32, ch * 0.92, 0.05), at(sx * cw * 0.22, 0.02, -cd * 0.62), K.GOLD, MAT.Fabric)
		for i = 0, 1 do
			deco("Hips", "StoleFall", V(0.32, 1.05, 0.05), at(sx * hw * 0.32, -0.45 - i * 1.05, -hd * 0.72), i == 0 and K.GOLD or K.TARNISH, MAT.Fabric)
		end
	end
	k.tatter(rng, "Hips", CFrame.new(0, 0.1, -hd * 0.55), hw * 1.1, 2.4, WOOL, WOOL_DK, 0.3)
	k.tatter(rng, "Hips", CFrame.new(0, 0.1, hd * 0.55), hw * 1.1, 2.5, WOOL, WOOL_DK, 0.4)
	deco("Hips", "Rope", V(hw * 1.28, 0.16, hd * 1.32), at(0, 0.3, 0), rgb(138, 118, 78), MAT.Fabric)
	for _, b in ipairs({ { -0.7, -0.5 }, { 0.75, -0.4 }, { -0.5, 0.55 } }) do
		deco("Hips", "Bowl", V(0.14, 0.72, 0.72), at(b[1] * hw * 0.8, -0.1, b[2] * hd * 1.4) * K.UP, K.TARNISH, MAT.Metal, Enum.PartType.Cylinder)
	end
	deco("Hips", "Purse", V(0.48, 0.62, 0.44), at(hw * 0.55, -0.28, -hd * 0.5), K.LEATHER, MAT.Leather, Enum.PartType.Ball)
	for _, n in ipairs({ "R", "L" }) do
		deco(n .. "UpperArm", "Sleeve", V(aw * 1.3, ua, aw * 1.3), at(0, 0, 0), WOOL, MAT.Fabric)
		deco(n .. "LowerArm", "Sleeve", V(aw * 1.55, la * 0.9, aw * 1.55), at(0, 0.05, 0), WOOL_DK, MAT.Fabric)
		deco(n .. "LowerArm", "Hem", V(aw * 1.6, 0.14, aw * 1.6), at(0, -la * 0.42, 0), K.GOLD, MAT.Metal)
		deco(n .. "Foot", "Sandal", V(0.68, 0.2, 1.1), at(0, -0.02, -0.05), K.LEATHER, MAT.Leather)
	end
	-- coins spilling out of the left hand, always
	for i = 0, 3 do
		deco("LLowerArm", "HeldCoin", V(0.06, 0.34, 0.34), at(rng:NextNumber(-0.15, 0.15), -la / 2 - 0.25 - i * 0.05, rng:NextNumber(-0.15, 0.15)) * CFrame.Angles(rng:NextNumber(0, 3), 0, rng:NextNumber(0, 3)), K.GOLD, MAT.Metal, Enum.PartType.Cylinder)
	end
end

M.Weapons = {
	-- a rope, a great canvas sack bulging with coin, gold showing at a split in it
	AlmsSack = function(w)
		local rope, sack = Color3.fromRGB(138, 118, 78), Color3.fromRGB(150, 134, 96)
		local handle = w.mk("Grip", Vector3.new(0.2, 0.9, 0.2), rope, Enum.Material.Fabric)
		w.add(w.mk("Rope", Vector3.new(0.14, 1.9, 0.14), rope, Enum.Material.Fabric), -1.3)
		w.add(w.mk("Neck", Vector3.new(0.5, 0.36, 0.5), K.GOLD, Enum.Material.Metal), -2.3)
		local b = w.mk("Sack", Vector3.new(2.1, 2.5, 2.1), sack, Enum.Material.Fabric)
		b.Shape = Enum.PartType.Ball
		w.add(b, -3.5)
		w.add(w.mk("Split", Vector3.new(0.9, 0.22, 0.4), K.LIGHT, Enum.Material.Metal), -3.7, nil, -0.95)
		for i = -1, 1 do
			local c = w.mk("Coin", Vector3.new(0.08, 0.42, 0.42), K.GOLD, Enum.Material.Metal)
			c.Shape = Enum.PartType.Cylinder
			w.add(c, -3.55 + i * 0.12, CFrame.Angles(0.4 * i, 0.5, 1), -1.05)
		end
		return { handle = handle, bladeLen = 4.5 }
	end,
}

M.Def = K.def({
	HP = 450, Speed = 8.5, Scale = 1.3, Damage = 40, Range = 9, HalfAngle = 55, Lunge = 7, Poise = 70, Stagger = 0.55, StaggerPush = 8,
	Windup = 0.9, Recover = 1.1, Engage = 22, Close = 9, Weapon = "AlmsSack", IdleGrip = "ALHang", Radius = 1.7, Skin = K.TARNISH, Cloth = K.GOLD,
})

local function coin(e, from, vel, damage)
	K.shot(e, { from = from, vel = vel, damage = damage or 16, level = "Small", radius = 1.3, life = 1.6, gravity = 8,
		size = Vector3.new(0.14, 0.75, 0.75), shape = Enum.PartType.Cylinder, color = K.LIGHT, trail = K.GOLD, spin = 16 })
end
-- LARGESSE: the left hand flung out, five coins in a flat fan at you
local function largesse(e, tRoot)
	local root = e.root
	K.sound(e, "Unsheath", 0.4, 1.5)
	K.setBody(e, "GBCast", 0.5)
	if not K.hold(e, 0.7, tRoot) then
		return false
	end
	K.setBody(e, "GBFling", 0.12)
	task.wait(0.1)
	if not e.alive then
		return false
	end
	local from = root.Position + root.CFrame.LookVector * 1.8 * e.scale + Vector3.new(0, 0.9 * e.scale, 0)
	local base = K.aim(from, tRoot, 48, 0.2)
	for i = -2, 2 do
		coin(e, from, CFrame.Angles(0, math.rad(i * 11), 0):VectorToWorldSpace(base))
	end
	K.sound(e, "Lunge", 0.7, 1.5)
	return true
end
local function tithe(e, tRoot)
	return K.slam(e, tRoot, {
		set = "GRaise", setBody = "GBSet", tell = 0.95, swing = "GSlam", swingBody = "GBStrike", time = 0.2, range = 9.5, half = 60, level = "Knockdown",
		area = 6, areaDamage = 18, color = K.GOLD, boom = 0.9, lunge = 1.2,
		after = function(at)
			for i = 1, 6 do
				local a = i * math.pi / 3
				coin(e, at + Vector3.new(0, 1.5, 0), Vector3.new(math.cos(a) * 16, 15, math.sin(a) * 16), 12)
			end
		end,
	})
end

M.attack = K.brain(function(e, tRoot, d)
	if d > e.def.Close or math.random() < 0.3 then
		return largesse(e, tRoot), 0.9
	end
	return tithe(e, tRoot), 1.2
end)

return M
