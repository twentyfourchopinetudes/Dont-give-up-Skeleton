--!nonstrict
-- THE TALLYMAN (kind Tallyman): the Exchequer's clerk, bent to a question mark, still adding it up, and you're on the list. Ink-black robes,
-- ink to the elbows, spectacles over no eyes, a wig of rolled parchment; a ledger chained to its belt, and quills stuck everywhere.
-- It carries a great gold abacus on a pole.
--   Audit       a volley of quills, one after another, each thrown where you're going
--   Foreclosure the abacus up and down, beads roaring along its rods. A lot heavier than it looks
--   Settled     and it hits you with the ledger on the way past
local K = require(script.Parent.Parent:WaitForChild("GildedKit"))
local M = K.wrap({
	Poses = { TMBStoop = { drop = 0.3, lean = 0.48, head = -0.12, spread = 0.12, footR = -0.25, footL = 0.3, breathe = 0.6, la1 = 0.9, la3 = -0.1, lel = 1.8, freeL = 0 } },
	Grips = { TMPole = { Vector3.new(1.2, 0, -0.8), CFrame.Angles(math.rad(165), 0, 0) } },
})
M.Kind = "Tallyman"
M.Proportions = { girth = 0.88, arm = 1.18, hunch = 0.42 }
M.IdlePose = "TMBStoop"
M.BodyFor = { TMPole = "TMBStoop" }
local INK, INK_LT, PARCH, QUILL = Color3.fromRGB(20, 20, 28), Color3.fromRGB(44, 44, 58), Color3.fromRGB(226, 214, 180), Color3.fromRGB(236, 232, 222)
M.Colors = { skin = Color3.fromRGB(200, 186, 150), torso = INK, legs = INK, arms = INK }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local rng = Random.new()
	local cyl = Enum.PartType.Cylinder
	-- a dried face, long-nosed; gold spectacles over empty dark, one lens cracked; a wig of curled parchment rolls
	deco("Head", "Nose", V(0.17, 0.56, 0.2), at(0, -0.1, -0.62), Color3.fromRGB(190, 176, 140), MAT.SmoothPlastic)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "Socket", V(0.05, 0.36, 0.36), at(sx * 0.26, 0.12, -0.58) * K.FACE, K.INK, MAT.SmoothPlastic, cyl)
		deco("Head", "Lens", V(0.05, 0.42, 0.42), at(sx * 0.26, 0.12, -0.62) * K.FACE, K.LIGHT, MAT.Glass, cyl).Transparency = 0.35
		deco("Head", "Rim", V(0.04, 0.5, 0.5), at(sx * 0.26, 0.12, -0.6) * K.FACE, K.GOLD, MAT.Metal, cyl)
		for i = 0, 3 do
			deco("Head", "Roll", V(0.42, 0.55, 0.42), at(sx * 0.66, 0.46 - i * 0.34, 0.14), PARCH, MAT.Fabric, cyl)
		end
	end
	deco("Head", "Bridge", V(0.16, 0.04, 0.04), at(0, 0.14, -0.62), K.GOLD, MAT.Metal)
	deco("Head", "WigTop", V(1.3, 0.55, 1.35), at(0, 0.62, 0.1), PARCH, MAT.Fabric)
	-- quills behind its ears and through its wig
	for _, q in ipairs({ { 0.5, 0.86, 0.1, 0.3 }, { -0.42, 0.9, 0.1, -0.36 }, { 0.68, 0.45, 0.3, 0.9 }, { 0.08, 0.98, 0.34, 0.08 } }) do
		deco("Head", "Quill", V(0.1, 1.05, 0.22), at(q[1], q[2] + 0.2, q[3]) * CFrame.Angles(-0.25, 0, -q[4]), QUILL, MAT.Fabric)
	end
	-- the robe, ink staining down its front; a chain of keys and a ledger at the belt, tally-sticks over its back
	deco("Chest", "Robe", V(cw * 1.08, ch * 1.02, cd * 1.12), at(0, 0, 0.02), INK, MAT.Fabric)
	deco("Chest", "Collar", V(cw * 0.72, 0.34, cd * 1.2), at(0, ch * 0.46, 0), INK_LT, MAT.Fabric)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Chest", "Lappet", V(0.18, 0.95, 0.05), at(sx * 0.14, ch * 0.2, -cd * 0.6), K.PORCELAIN, MAT.Fabric)
	end
	for i = 0, 6 do
		deco("Chest", "TallyStick", V(0.1, 2, 0.1), at(-0.6 + i * 0.2, 0.75, cd * 0.56 + 0.1) * CFrame.Angles(0.18, 0, (i - 3) * 0.03), rgb(150, 124, 84), MAT.Wood)
		deco("Chest", "Quill", V(0.08, 1.2, 0.18), at(-0.54 + i * 0.18, 1.6, cd * 0.56 + 0.08) * CFrame.Angles(0.22, 0, (i - 3) * 0.1), QUILL, MAT.Fabric)
	end
	deco("Chest", "Quiver", V(1.5, 1.2, 0.3), at(0, 0.3, cd * 0.56 + 0.1), K.LEATHER, MAT.Leather)
	k.tatter(rng, "Hips", CFrame.new(0, 0.1, -hd * 0.55), hw * 1.1, 2.5, INK, INK_LT, 0.3)
	k.tatter(rng, "Hips", CFrame.new(0, 0.1, hd * 0.55), hw * 1.1, 2.5, INK, INK_LT, 0.3)
	deco("Hips", "Belt", V(hw * 1.25, 0.18, hd * 1.28), at(0, 0.3, 0), K.GOLD, MAT.Metal)
	deco("Hips", "Ledger", V(1.05, 1.35, 0.42), at(-hw * 0.82, -0.3, 0), K.RUG, MAT.Leather)
	deco("Hips", "LedgerPages", V(0.96, 1.26, 0.45), at(-hw * 0.82, -0.3, 0), PARCH, MAT.Fabric)
	deco("Hips", "LedgerClasp", V(1.08, 0.12, 0.47), at(-hw * 0.82, -0.3, 0), K.GOLD, MAT.Metal)
	for i = 0, 3 do
		deco("Hips", "LedgerChain", V(0.1, 0.2, 0.14), at(-hw * 0.62, 0.22 - i * 0.14, 0.04) * CFrame.Angles(0, i % 2 * math.pi / 2, 0), K.GOLD, MAT.Metal)
	end
	for _, n in ipairs({ "R", "L" }) do
		deco(n .. "UpperArm", "Sleeve", V(aw * 1.25, ua, aw * 1.25), at(0, 0, 0), INK_LT, MAT.Fabric)
		deco(n .. "LowerArm", "InkStain", V(aw * 1.06, la * 0.9, aw * 1.06), at(0, -0.1, 0), K.INK, MAT.SmoothPlastic)
		deco(n .. "LowerArm", "Bandcuff", V(aw * 1.3, 0.14, aw * 1.3), at(0, la * 0.32, 0), K.PORCELAIN, MAT.Fabric)
		deco(n .. "Foot", "Shoe", V(0.56, 0.24, 1.02), at(0, -0.02, -0.04), K.INK, MAT.Leather)
	end
end

M.Weapons = {
	-- a great gold abacus on a pole: rods of beads that clatter along, a heavy frame
	GrandAbacus = function(w)
		local gold = K.GOLD
		local handle = w.mk("Grip", Vector3.new(0.22, 1.1, 0.22), K.INK, Enum.Material.Wood)
		w.add(w.mk("Pole", Vector3.new(0.18, 3, 0.18), K.INK, Enum.Material.Wood), -1.9)
		for _, y in ipairs({ -3.3, -6.1 }) do
			w.add(w.mk("FrameBar", Vector3.new(3, 0.26, 0.3), gold, Enum.Material.Metal), y)
		end
		for _, x in ipairs({ -1.5, 1.5 }) do
			w.add(w.mk("FrameSide", Vector3.new(0.26, 3, 0.3), gold, Enum.Material.Metal), -4.7, CFrame.new(x * w.scale, 0, 0))
		end
		for r = 0, 3 do
			local y = -3.85 - r * 0.58
			w.add(w.mk("Rod", Vector3.new(2.9, 0.06, 0.06), Color3.fromRGB(150, 146, 136), Enum.Material.Metal), y)
			for b = 0, 3 do
				local bead = w.mk("Bead", Vector3.new(0.34, 0.34, 0.34), b % 2 == 0 and K.ROSE or K.LAPIS, Enum.Material.Glass)
				bead.Shape = Enum.PartType.Ball
				w.add(bead, y, CFrame.new((-1.1 + r * 0.14 + b * 0.5) * w.scale, 0, 0))
			end
		end
		return { handle = handle, bladeLen = 6 }
	end,
}

M.Def = K.def({
	HP = 360, Speed = 9.5, Scale = 1.25, Damage = 42, Range = 10, HalfAngle = 42, Lunge = 6, Poise = 50, Stagger = 0.55, StaggerPush = 12,
	Windup = 0.8, Recover = 1, Engage = 24, Close = 9, Weapon = "GrandAbacus", IdleGrip = "TMPole", Radius = 1.4, Skin = K.INK, Cloth = INK,
})

local function audit(e, tRoot)
	K.setBody(e, "GBCast", 0.4)
	K.sound(e, "Unsheath", 0.3, 1.8)
	if not K.hold(e, 0.65, tRoot) then
		return false
	end
	for i = 1, 5 do
		K.setBody(e, i % 2 == 0 and "GBCast" or "GBFling", 0.08)
		if not K.hold(e, 0.16, tRoot) then
			return false
		end
		local from = e.root.Position + e.root.CFrame.LookVector * 1.6 * e.scale + Vector3.new(0, 1.3 * e.scale, 0)
		K.shot(e, {
			from = from, vel = K.aim(from, tRoot, 62, 0.28), damage = 14, level = "Small", radius = 1.1, life = 1.4, gravity = 6,
			size = Vector3.new(0.14, 0.14, 1.5), shape = Enum.PartType.Block, color = QUILL, material = Enum.Material.Fabric, trail = INK_LT,
		})
		K.sound(e, "Lunge", 0.45, 1.8)
	end
	return true
end

M.attack = K.brain(function(e, tRoot, d)
	if d > e.def.Close then
		return audit(e, tRoot), 0.9
	elseif math.random() < 0.6 then
		return K.slam(e, tRoot, {
			set = "GRaise", setBody = "GBSet", tell = 0.95, swing = "GSlam", swingBody = "GBStrike", time = 0.18, range = 10.5, half = 38, level = "Knockdown",
			area = 4.5, areaDamage = 18, color = K.GOLD, boom = 1.4, shake = 0.3, speed = 0.8,
		}), 1.1
	end
	return K.strike(e, tRoot, { set = "GBack", setBody = "GBWind", tell = 0.55, swing = "GSweep", swingBody = "GBSweep", time = 0.18, range = 8.5, half = 80, damage = 30, level = "Medium", speed = 1.1 }), 0.8
end)

return M
