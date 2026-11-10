--!nonstrict
-- THE GILDER (kind Gilder): who put the gold on everything. Bent and burned, working from a little brazier on a yoke across its shoulders, a crucible hung
-- from it either side, gold leaf sticking all over it in flakes. It's gilded its own hands and its own face without noticing, and
-- it's been meaning to do you. A long iron ladle.
--   A Coat of Gold  it fills its mouth from the ladle and blows: a fan of molten gold, spitting
--   The Pour        the ladle up and tipped: it falls in a sheet and pools hot on the floor where it lands
--   Burnisher       a hot iron across the face if you crowd it
local K = require(script.Parent.Parent:WaitForChild("GildedKit"))
local M = K.wrap({
	Poses = { GDBBent = { drop = 0.45, lean = 0.42, head = -0.05, spread = 0.24, footR = -0.35, footL = 0.4, breathe = 1.8, la1 = 0.5, la3 = -0.3, lel = 1.3, freeL = 0 } },
	Grips = { GDLadle = { Vector3.new(1.2, -0.1, -1), CFrame.Angles(math.rad(70), 0, 0) } },
})
M.Kind = "Gilder"
M.Proportions = { girth = 1.05, arm = 1.15, hunch = 0.3 }
M.IdlePose = "GDBBent"
M.BodyFor = { GDLadle = "GDBBent" }
local CHAR, LEATHER, MOLTEN, HOT = Color3.fromRGB(54, 44, 38), Color3.fromRGB(82, 56, 36), Color3.fromRGB(255, 196, 60), Color3.fromRGB(255, 130, 30)
M.Colors = { skin = CHAR, torso = LEATHER, legs = LEATHER, arms = CHAR }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local rng = Random.new()
	local ball, cyl = Enum.PartType.Ball, Enum.PartType.Cylinder
	-- half of the face has gold running down it, one eye gilded shut; the mouth a hot gap; a leather skullcap
	parts.Head.Material = MAT.SmoothPlastic
	deco("Head", "GiltHalf", V(0.62, 1.28, 1.2), at(0.28, 0, 0), K.GOLD, MAT.Metal)
	deco("Head", "GiltDrip", V(0.14, 0.7, 0.08), at(0.42, -0.72, -0.5), K.LIGHT, MAT.Metal)
	deco("Head", "GiltLid", V(0.32, 0.08, 0.05), at(0.28, 0.1, -0.61), K.TARNISH, MAT.Metal)
	deco("Head", "Eye", V(0.12, 0.12, 0.05), at(-0.27, 0.1, -0.59), rgb(250, 240, 200), MAT.Neon, ball)
	deco("Head", "GrateFire", V(0.46, 0.24, 0.05), at(0, -0.34, -0.61), MOLTEN, MAT.Neon)
	deco("Head", "Skullcap", V(1.24, 0.42, 1.24), at(0, 0.54, 0.02), LEATHER, MAT.Leather)
	-- THE YOKE, across the shoulders: the brazier behind its neck, a crucible hung each side
	deco("Chest", "Yoke", V(cw * 2.2, 0.24, 0.34), at(0, ch * 0.54, 0.25), LEATHER:Lerp(rgb(0, 0, 0), 0.35), MAT.Wood)
	deco("Chest", "Brazier", V(0.8, 1.05, 1.05), at(0, ch * 0.54 + 0.56, 0.48) * K.UP, K.INK, MAT.Metal, cyl)
	local coals = deco("Chest", "Coals", V(0.08, 0.88, 0.88), at(0, ch * 0.54 + 0.98, 0.48) * K.UP, HOT, MAT.Neon, cyl)
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = HOT, 12, 1.5
	l.Parent = coals
	local fume = Instance.new("ParticleEmitter")
	fume.Texture = "rbxasset://textures/particles/smoke_main.dds"
	fume.Color = ColorSequence.new(Color3.fromRGB(70, 60, 50), Color3.fromRGB(26, 22, 20))
	fume.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 2.4) })
	fume.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) })
	fume.Lifetime, fume.Rate, fume.Speed = NumberRange.new(1.2, 2), 5, NumberRange.new(2, 3)
	fume.EmissionDirection = Enum.NormalId.Right
	fume.Parent = coals
	for _, sx in ipairs({ -1, 1 }) do
		local x = sx * cw * 1.04
		deco("Chest", "HangChain", V(0.1, 0.8, 0.1), at(x, ch * 0.22, 0.25), K.TARNISH, MAT.Metal)
		deco("Chest", "Crucible", V(0.78, 0.82, 0.78), at(x, ch * -0.2, 0.25) * K.UP, K.INK, MAT.Metal, cyl)
		deco("Chest", "Melt", V(0.05, 0.64, 0.64), at(x, ch * 0.03, 0.25) * K.UP, MOLTEN, MAT.Neon, cyl)
	end
	-- a burned leather apron stuck with gold leaf; flakes all over it; books of leaf at the belt
	deco("Chest", "Bib", V(cw * 0.92, ch * 0.92, 0.1), at(0, -0.05, -cd * 0.56), LEATHER, MAT.Leather)
	deco("Hips", "Apron", V(hw * 1.15, 2.4, 0.08), at(0, -0.95, -hd * 0.64), LEATHER, MAT.Leather)
	for _ = 1, 26 do
		local pn = rng:NextNumber() < 0.5 and "Chest" or "Hips"
		local cf = pn == "Chest" and at(rng:NextNumber(-0.45, 0.45) * cw, rng:NextNumber(-0.45, 0.45) * ch, -cd * 0.62) or at(rng:NextNumber(-0.5, 0.5) * hw, rng:NextNumber(-2, 0), -hd * 0.7)
		deco(pn, "Leaf", V(rng:NextNumber(0.12, 0.32), rng:NextNumber(0.12, 0.3), 0.03), cf * CFrame.Angles(0, 0, rng:NextNumber(0, 3)), K.LIGHT, MAT.Metal)
	end
	deco("Hips", "Belt", V(hw * 1.25, 0.26, hd * 1.3), at(0, 0.3, 0), K.INK, MAT.Leather)
	for i = -1, 1 do
		deco("Hips", "LeafBook", V(0.42, 0.56, 0.12), at(i * hw * 0.42, 0, hd * 0.68), K.RUG, MAT.Leather)
	end
	deco("Hips", "Burnisher", V(0.14, 1.15, 0.14), at(-hw * 0.74, -0.45, 0.05), K.LIGHT, MAT.Metal)
	for _, n in ipairs({ "R", "L" }) do
		-- gilded hands, gold to the elbow, and running
		deco(n .. "LowerArm", "GiltArm", V(aw * 1.08, la * 1.02, aw * 1.08), at(0, 0, 0), K.GOLD, MAT.Metal)
		deco(n .. "LowerArm", "GiltHand", V(aw * 1.02, 0.48, aw * 1.04), at(0, -la / 2 - 0.08, 0), K.LIGHT, MAT.Metal)
		deco(n .. "UpperArm", "Burn", V(aw * 1.04, ua * 0.6, aw * 1.04), at(0, -ua * 0.15, 0), HOT:Lerp(CHAR, 0.75), MAT.CrackedLava)
		deco(n .. "Shin", "Boot", V(lw * 1.16, 1.05, lw * 1.16), at(0, 0, 0), K.INK, MAT.Leather)
		deco(n .. "Foot", "Sole", V(0.72, 0.3, 1.15), at(0, 0.02, -0.05), K.INK, MAT.Leather)
		deco(n .. "Foot", "Splash", V(0.3, 0.1, 0.5), at(0.1, 0.16, -0.25), K.GOLD, MAT.Metal)
	end
end

M.Weapons = {
	-- a long iron ladle, its bowl brimming and glowing
	GildersLadle = function(w)
		local iron = Color3.fromRGB(46, 42, 40)
		local handle = w.mk("Grip", Vector3.new(0.22, 1, 0.22), K.LEATHER, Enum.Material.Leather)
		w.add(w.mk("Shaft", Vector3.new(0.17, 3.9, 0.17), iron, Enum.Material.Metal), -2.4)
		local bowl = w.mk("Bowl", Vector3.new(1.35, 0.8, 1.35), iron, Enum.Material.Metal)
		bowl.Shape = Enum.PartType.Ball
		w.add(bowl, -4.65)
		local melt = w.mk("LadleMelt", Vector3.new(1.1, 0.24, 1.1), MOLTEN, Enum.Material.Neon)
		melt.Shape = Enum.PartType.Ball
		w.add(melt, -4.65)
		local function setup()
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness = MOLTEN, 9, 1.2
			l.Parent = melt
		end
		return { handle = handle, bladeLen = 5.2, setup = setup }
	end,
}

M.Def = K.def({
	HP = 460, Speed = 8.5, Scale = 1.3, Damage = 40, Range = 9, HalfAngle = 55, Lunge = 7, Poise = 70, Stagger = 0.55, StaggerPush = 9,
	Windup = 0.85, Recover = 1.1, Engage = 15, Close = 8, Weapon = "GildersLadle", IdleGrip = "GDLadle", Radius = 1.7, Skin = K.GOLD, Cloth = LEATHER,
})

local function pour(e, tRoot)
	K.setGrip(e, "GHigh", 0.5)
	K.setBody(e, "GBCast", 0.5)
	K.sound(e, "FireHit", 0.3, 0.6)
	if not K.hold(e, 0.85, tRoot) then
		return false
	end
	K.setGrip(e, "GSlam", 0.2)
	K.setBody(e, "GBStrike", 0.2)
	local from = K.hand(e) + Vector3.new(0, 3, 0) + e.root.CFrame.LookVector * 2
	for i = -1, 1 do
		local to = K.ahead(e, 8) + e.root.CFrame.RightVector * i * 2.8
		local T, G = 0.5, 90
		K.shot(e, {
			from = from, vel = (to - from) / T + Vector3.new(0, 0.5 * G * T, 0), gravity = G, damage = 20, level = "Medium", radius = 1.8, life = 2,
			size = Vector3.new(1, 1, 1), color = MOLTEN, material = Enum.Material.Neon, trail = HOT,
			onLand = function(pos)
				K.cloud(pos, { radius = 3.6, life = 3.5, color = MOLTEN, rate = 16, damage = 9, tick = 0.5, texture = "rbxasset://textures/particles/fire_main.dds" })
			end,
		})
	end
	K.sound(e, "FireHit", 0.7, 0.8)
	return K.hold(e, 0.3)
end

M.attack = K.brain(function(e, tRoot, d)
	local roll = math.random()
	if d > e.def.Close or roll < 0.32 then
		K.setGrip(e, "GWide", 0.4)
		return K.breath(e, tRoot, {
			part = K.partOf(e, "GrateFire"), setBody = "GBDraught", draw = 1.05, time = 1.3, reach = 14, half = 24, damage = 12, tick = 0.3,
			c0 = Color3.fromRGB(255, 240, 180), c1 = MOLTEN, c2 = K.TARNISH, glow = 1, spread = 4.5, pitch = 0.75,
			texture = "rbxasset://textures/particles/fire_main.dds",
		}), 1.2
	elseif roll < 0.68 then
		return pour(e, tRoot), 1.1
	end
	return K.strike(e, tRoot, { set = "GBack", setBody = "GBWind", tell = 0.6, swing = "GSweep", swingBody = "GBSweep", time = 0.15, range = 8.5, half = 75, damage = 38, speed = 0.95 }), 0.9
end)

return M
