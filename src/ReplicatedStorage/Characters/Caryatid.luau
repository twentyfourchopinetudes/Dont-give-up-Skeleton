--!nonstrict
-- THE CARYATID (kind Caryatid): a carved woman who held up a portico for a thousand years and has finally stepped out from under it. Solid
-- pale limestone, robes in long carved folds, gilt in the deep of them; a block of the old cornice still on her head. She carries a
-- snapped column under one arm. She is the largest thing in the Heights that walks, and she's very slow, and nothing you do
-- will make her flinch until you've cracked her.
--   Felled    the column up and down, in a line in front of her. Roll aside
--   Foundation  a foot lifted, stamped: the floor bucks around her
--   Topple    with no warning but a creak, she simply falls on you
--   Cornice Stone  from further off: a block wrenched up and heaved in a high arc onto where you stand. You can't just keep away
local K = require(script.Parent.Parent:WaitForChild("GildedKit"))
local M = K.wrap({
	Poses = {
		CABStand = { drop = 0, lean = 0, head = 0.02, spread = 0.05, footR = -0.05, footL = 0.1, breathe = 0.1, la1 = 2.5, la3 = -0.25, lel = 2, freeL = 0 },
		CABStampSet = { drop = 0.05, lean = -0.15, head = 0.1, spread = 0.1, footR = -0.05, footL = 1.4, la1 = 2.5, la3 = -0.25, lel = 2, freeL = 0 },
		CABStamp = { drop = 0.6, lean = 0.2, head = 0.25, spread = 0.2, footR = -0.4, footL = 0.5, la1 = 2.5, la3 = -0.25, lel = 2, freeL = 0 },
		CABTopple = { drop = 1.4, lean = 1.5, head = 0.4, spread = 0.12, footR = -0.3, footL = 0.1, la1 = 0.5, la3 = -0.4, freeL = 0 },
	},
	Grips = { CACarry = { Vector3.new(1.5, -0.1, -0.4), CFrame.Angles(math.rad(20), 0, 0) } },
})
M.Kind = "Caryatid"
M.Proportions = { girth = 1.3, arm = 1.05, hunch = 0, cadence = 0.4 }
M.IdlePose = "CABStand"
M.BodyFor = { CACarry = "CABStand" }
local STONE, STONE_DK, FOLD = Color3.fromRGB(204, 200, 188), Color3.fromRGB(166, 160, 146), Color3.fromRGB(140, 134, 120)
M.Colors = { skin = STONE, torso = STONE, legs = STONE, arms = STONE }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local rng = Random.new()
	for name, p in pairs(parts) do
		if name ~= "HumanoidRootPart" then
			p.Material = MAT.Limestone
		end
	end
	-- a calm carved face, shut eyes; hair in stone braids; the cornice block on her head, crushed down into it
	deco("Head", "Nose", V(0.14, 0.4, 0.14), at(0, -0.02, -0.6), STONE, MAT.Limestone)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "Lid", V(0.3, 0.05, 0.05), at(sx * 0.27, 0.12, -0.59) * CFrame.Angles(0, 0, sx * 0.08), FOLD, MAT.Limestone)
		for i = 0, 2 do
			deco("Head", "Braid", V(0.28, 0.42, 0.28), at(sx * 0.62, 0.18 - i * 0.38, 0.1), STONE_DK, MAT.Limestone, Enum.PartType.Ball)
		end
	end
	deco("Head", "Lips", V(0.3, 0.05, 0.05), at(0, -0.36, -0.59), FOLD, MAT.Limestone)
	deco("Head", "Capital", V(1.3, 0.3, 1.3), at(0, 0.75, 0), STONE_DK, MAT.Limestone)
	deco("Head", "Capital", V(1.75, 0.3, 1.75), at(0, 1.02, 0), STONE, MAT.Limestone)
	deco("Head", "Cornice", V(3, 0.75, 2.4), at(0.1, 1.5, 0) * CFrame.Angles(0.06, 0, 0.05), STONE, MAT.Limestone)
	deco("Head", "CorniceGilt", V(3.05, 0.14, 2.45), at(0.1, 1.2, 0) * CFrame.Angles(0.06, 0, 0.05), K.GOLD, MAT.Metal)
	deco("Head", "CorniceBreak", V(0.5, 0.55, 2.2), at(-1.45, 1.42, 0) * CFrame.Angles(0, 0, 0.4), STONE_DK, MAT.Limestone)
	-- THE ROBE: long folds cut down from the shoulder to the plinth, gilt still in the deep of them
	for i = -3, 3 do
		deco("Chest", "Fold", V(0.2, ch * 0.92, 0.14), at(i * cw * 0.13, 0, -cd * 0.53) * CFrame.Angles(0, 0, i * 0.04), i % 2 == 0 and FOLD or STONE, MAT.Limestone)
		deco("Hips", "SkirtFold", V(0.34, 3, 0.16), at(i * hw * 0.17, -1.2, -hd * 0.62), i % 2 == 0 and FOLD or STONE, MAT.Limestone)
		deco("Hips", "SkirtFold", V(0.34, 3, 0.16), at(i * hw * 0.17, -1.2, hd * 0.62), i % 2 == 0 and STONE or FOLD, MAT.Limestone)
		if i % 2 ~= 0 then
			deco("Hips", "SkirtGilt", V(0.06, 2.8, 0.06), at(i * hw * 0.17, -1.2, -hd * 0.72), K.GOLD, MAT.Metal)
		end
	end
	deco("Hips", "Skirt", V(hw * 1.25, 3, hd * 1.25), at(0, -1.2, 0), STONE_DK, MAT.Limestone)
	deco("Chest", "Girdle", V(cw * 1, 0.28, cd * 1.1), at(0, -ch * 0.4, 0), K.GOLD, MAT.Metal)
	deco("Chest", "Drape", V(cw * 0.5, ch * 0.92, 0.14), at(-cw * 0.26, 0, -cd * 0.56) * CFrame.Angles(0, 0, -0.32), STONE_DK, MAT.Limestone)
	-- a big crack across her, hairline gold, and chips gone from her
	for i = 0, 4 do
		deco("Chest", "Crack", V(0.05, 0.42, 0.05), at(cw * (0.3 - i * 0.14), ch * (0.3 - i * 0.14), -cd * 0.62) * CFrame.Angles(0, 0, (i % 2 == 0 and 0.6 or -0.3)), K.LIGHT, MAT.Neon)
	end
	for _ = 1, 4 do
		deco("Chest", "Chip", V(0.3, 0.2, 0.2), at(rng:NextNumber(-0.5, 0.5) * cw, rng:NextNumber(-0.4, 0.4) * ch, cd * 0.52), FOLD, MAT.Limestone)
	end
	-- a stone plinth still round her feet (it comes with her)
	for _, n in ipairs({ "R", "L" }) do
		deco(n .. "Foot", "Plinth", V(1.1, 0.55, 1.55), at(0, -0.02, -0.08), STONE_DK, MAT.Limestone)
		deco(n .. "UpperArm", "Armlet", V(aw * 1.2, 0.14, aw * 1.2), at(0, ua * 0.1, 0), K.GOLD, MAT.Metal)
	end
end

M.Weapons = {
	-- a snapped length of fluted column, its capital still on it
	StoneColumn = function(w)
		local st = Color3.fromRGB(204, 200, 188)
		local handle = w.mk("Grip", Vector3.new(0.7, 1.3, 0.7), st, Enum.Material.Limestone)
		local shaft = w.mk("Shaft", Vector3.new(5.4, 1.4, 1.4), st, Enum.Material.Limestone)
		shaft.Shape = Enum.PartType.Cylinder
		w.add(shaft, -3, CFrame.Angles(0, 0, math.pi / 2))
		for i = 0, 7 do
			local a = i * math.pi / 4
			w.add(w.mk("Flute", Vector3.new(0.14, 5.2, 0.14), Color3.fromRGB(150, 146, 132), Enum.Material.Limestone), -3, CFrame.new(math.cos(a) * 0.66 * w.scale, 0, math.sin(a) * 0.66 * w.scale))
		end
		w.add(w.mk("Capital", Vector3.new(2.3, 0.75, 2.3), st, Enum.Material.Limestone), -5.9)
		w.add(w.mk("CapitalGilt", Vector3.new(2.36, 0.14, 2.36), K.GOLD, Enum.Material.Metal), -5.5)
		w.add(w.mk("Break", Vector3.new(1.1, 0.5, 1.1), Color3.fromRGB(166, 160, 146), Enum.Material.Limestone), 0.6, CFrame.Angles(0.4, 0.6, 0.2))
		return { handle = handle, bladeLen = 6.3 }
	end,
}

M.Def = K.def({
	HP = 1050, Speed = 6, Scale = 1.8, Damage = 60, Range = 12, HalfAngle = 26, Lunge = 3, Poise = 220, Stagger = 0.9, StaggerPush = 2,
	Windup = 1.35, Recover = 1.6, HyperArmor = true, Engage = 26, Close = 8, Weapon = "StoneColumn", IdleGrip = "CACarry", Radius = 2.7, Aggro = 34, Skin = STONE, Cloth = STONE_DK,
})

local function stamp(e, tRoot)
	K.setBody(e, "CABStampSet", 0.7)
	K.sound(e, "Unsheath", 0.5, 0.35)
	if not K.hold(e, 0.95, tRoot) then
		return false
	end
	K.setBody(e, "CABStamp", 0.12)
	task.wait(0.12)
	if not e.alive then
		return false
	end
	local at = K.feet(e)
	K.area(at, 11, 3.5, 38, "Knockdown")
	K.flash(at, K.IVORY, 8)
	K.sound(e, "WatchdogSmash", 0.95, 0.65)
	K.shake(at, 0.8)
	return true
end
local function topple(e, tRoot)
	K.sound(e, "Impact", 0.7, 0.3)
	if not K.hold(e, 0.55, tRoot) then
		return false
	end
	K.setBody(e, "CABTopple", 0.45)
	K.step(e, 3.2)
	task.wait(0.46)
	if not e.alive then
		return false
	end
	local at = K.ahead(e, 7)
	K.area(at, 8, 4, 72, "Knockdown")
	K.flash(at, K.IVORY, 10)
	K.sound(e, "WatchdogSmash", 1, 0.55)
	K.shake(at, 1)
	return K.hold(e, 1.6) -- (getting back up: as long an opening as there is)
end

local function corniceStone(e, tRoot)
	K.setGrip(e, "GRaise", 0.8)
	K.setBody(e, "GBCast", 0.8)
	K.sound(e, "Impact", 0.6, 0.4)
	if not K.hold(e, 1.1, tRoot) or not tRoot.Parent then
		return false
	end
	K.setGrip(e, "GSlam", 0.18)
	K.setBody(e, "GBFling", 0.18)
	K.sound(e, "Lunge", 0.9, 0.5)
	local from = e.root.Position + Vector3.new(0, 4.5, 0)
	local at = tRoot.Position - Vector3.new(0, 2.5, 0)
	local T, g = 1.15, 70 -- (in the air this long: a high, slow arc you can see coming)
	K.shot(e, {
		from = from, vel = (at - from) / T + Vector3.new(0, 0.5 * g * T, 0), gravity = g, life = 3, damage = 40, level = "Knockdown",
		radius = 1.8, size = Vector3.new(2.4, 1.8, 2.2), shape = Enum.PartType.Block, color = STONE, material = Enum.Material.Limestone, spin = 4,
		onLand = function(pos)
			K.area(pos, 7, 4, 40, "Knockdown")
			K.flash(pos, K.IVORY, 8)
			K.sound(e, "WatchdogSmash", 0.9, 0.7)
			K.shake(pos, 0.6)
		end,
	})
	return K.hold(e, 0.4, tRoot)
end

M.attack = K.brain(function(e, tRoot, d)
	local roll = math.random()
	if d > 13 then
		return corniceStone(e, tRoot), 2
	elseif d < e.def.Close and roll < 0.35 then
		return stamp(e, tRoot), 1.3
	elseif d < 9 and roll < 0.55 then
		return topple(e, tRoot), 0.6
	end
	return K.slam(e, tRoot, {
		set = "GRaise", setBody = "GBSet", tell = 1.3, swing = "GSlam", swingBody = "GBStrike", time = 0.24, range = 13, half = 22, level = "Knockdown",
		area = 5, areaDamage = 30, lunge = 1, boom = 0.65, shake = 0.7, speed = 0.45,
	}), 1.6
end)

return M
