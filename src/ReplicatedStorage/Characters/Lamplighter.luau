--!nonstrict
-- THE LAMPLIGHTER (kind Lamplighter): the thin man who went round the Heights at dusk, still going round. Absurdly tall and stooped, a
-- stovepipe hat, a long black coat, hands gone to wax and running down its own pole. On the pole's end hangs a lantern with
-- something living in it: the light's the wrong colour, and it pulls toward you.
--   Trim the Wick   the lantern lifted high, brightening, and then all that light let go in a burst around it. Get clear
--   The Hook        the long pole lashed at you, a jab from further than you'd think
--   Moth            flung out at you, a mote of the light, drifting after you until it finds you or gutters
local K = require(script.Parent.Parent:WaitForChild("GildedKit"))
local M = K.wrap({
	Poses = { LLBStoop = { drop = 0.08, lean = 0.28, head = 0.28, footR = -0.2, footL = 0.25, breathe = 0.8, la1 = 0.35, la3 = -0.4, lel = 1.2, freeL = 0 } },
	Grips = { LLCarry = { Vector3.new(1.1, 0.3, -0.5), CFrame.Angles(math.rad(150), 0, 0) } },
})
M.Kind = "Lamplighter"
M.Proportions = { girth = 0.78, arm = 1.3, hunch = 0.26 }
M.IdlePose = "LLBStoop"
M.BodyFor = { LLCarry = "LLBStoop" }
local COAT, COAT_LT, WAX, FLAME = Color3.fromRGB(28, 26, 34), Color3.fromRGB(46, 44, 56), Color3.fromRGB(226, 214, 180), Color3.fromRGB(180, 240, 210)
M.Colors = { skin = WAX, torso = COAT, legs = COAT, arms = COAT }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local rng = Random.new()
	-- a long melted face under a tall stovepipe hat
	parts.Head.Material = MAT.SmoothPlastic
	deco("Head", "Jaw", V(0.8, 1.2, 0.8), at(0, -0.55, -0.12), WAX, MAT.SmoothPlastic)
	for i = 0, 3 do
		deco("Head", "Drip", V(0.12, rng:NextNumber(0.35, 0.95), 0.12), at(-0.34 + i * 0.22, -0.92, -0.42), WAX, MAT.SmoothPlastic)
	end
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "Eye", V(0.17, 0.26, 0.05), at(sx * 0.25, 0.08, -0.6), K.INK, MAT.SmoothPlastic)
		deco("Head", "Pupil", V(0.05, 0.05, 0.04), at(sx * 0.25, 0.06, -0.63), FLAME, MAT.Neon)
	end
	deco("Head", "Brim", V(0.12, 2.1, 2.1), at(0, 0.62, 0) * K.UP, COAT, MAT.Fabric, Enum.PartType.Cylinder)
	deco("Head", "Crown", V(1.95, 1.32, 1.32), at(0, 1.58, 0.05) * K.UP * CFrame.Angles(0.04, 0, 0), COAT, MAT.Fabric, Enum.PartType.Cylinder)
	deco("Head", "HatBand", V(0.24, 1.36, 1.36), at(0, 0.82, 0.02) * K.UP, K.TARNISH, MAT.Fabric, Enum.PartType.Cylinder)
	-- the long coat, its tails almost to the floor; brass buttons; a rack of spare wicks across its chest
	deco("Chest", "Coat", V(cw * 1.1, ch * 1.02, cd * 1.15), at(0, 0, 0.02), COAT, MAT.Fabric)
	deco("Chest", "Lapel", V(0.36, ch * 0.75, 0.05), at(-cw * 0.2, 0.12, -cd * 0.6) * CFrame.Angles(0, 0, -0.18), COAT_LT, MAT.Fabric)
	deco("Chest", "Lapel", V(0.36, ch * 0.75, 0.05), at(cw * 0.2, 0.12, -cd * 0.6) * CFrame.Angles(0, 0, 0.18), COAT_LT, MAT.Fabric)
	for i = 0, 3 do
		deco("Chest", "Button", V(0.1, 0.1, 0.05), at(0, ch * (0.2 - i * 0.2), -cd * 0.6), K.GOLD, MAT.Metal, Enum.PartType.Ball)
	end
	for i = 0, 5 do
		deco("Chest", "Wick", V(0.08, 0.5, 0.08), at(-cw * 0.32 + i * cw * 0.13, -ch * 0.3, -cd * 0.62), WAX, MAT.SmoothPlastic)
	end
	k.tatter(rng, "Hips", CFrame.new(-hw * 0.3, 0.1, hd * 0.6), hw * 0.55, 3.1, COAT, COAT_LT, 0.3)
	k.tatter(rng, "Hips", CFrame.new(hw * 0.3, 0.1, hd * 0.6), hw * 0.55, 3.2, COAT, COAT_LT, 0.3)
	deco("Hips", "CoatSkirt", V(hw * 1.15, 1.2, hd * 1.2), at(0, -0.3, 0), COAT, MAT.Fabric)
	deco("Hips", "OilTin", V(0.42, 0.62, 0.42), at(-hw * 0.72, -0.4, 0), K.TARNISH, MAT.Metal, Enum.PartType.Cylinder)
	for _, n in ipairs({ "R", "L" }) do
		deco(n .. "LowerArm", "WaxHand", V(aw * 0.95, 0.6, aw * 0.95), at(0, -la / 2 - 0.1, 0), WAX, MAT.SmoothPlastic)
		deco(n .. "LowerArm", "Drip", V(0.12, 0.7, 0.12), at(aw * 0.3, -la / 2 - 0.55, 0), WAX, MAT.SmoothPlastic)
		deco(n .. "Foot", "Boot", V(0.56, 0.3, 1.2), at(0, 0.02, -0.08), K.INK, MAT.Leather)
	end
end

M.Weapons = {
	-- a long pole, a hook at its top, the lantern swinging from it, and whatever it's got in there
	LamplighterPole = function(w)
		local brass = K.TARNISH
		local handle = w.mk("Grip", Vector3.new(0.2, 1, 0.2), Color3.fromRGB(56, 44, 34), Enum.Material.Wood)
		w.add(w.mk("Pole", Vector3.new(0.17, 6.8, 0.17), Color3.fromRGB(56, 44, 34), Enum.Material.Wood), -2.4)
		w.add(w.mk("Foot", Vector3.new(0.26, 0.5, 0.26), brass, Enum.Material.Metal), 1.1)
		w.add(w.mk("Hook", Vector3.new(0.14, 0.14, 1.1), brass, Enum.Material.Metal), -5.7, nil, -0.5)
		w.add(w.mk("HookTip", Vector3.new(0.14, 0.7, 0.14), brass, Enum.Material.Metal), -5.5, nil, -1)
		w.add(w.mk("LanternCap", Vector3.new(1, 0.3, 1), brass, Enum.Material.Metal), -4.75, nil, -0.95)
		w.add(w.mk("LanternBase", Vector3.new(1, 0.2, 1), brass, Enum.Material.Metal), -3.55, nil, -0.95)
		local glass = w.mk("LanternGlass", Vector3.new(0.82, 1, 0.82), FLAME, Enum.Material.Neon)
		w.add(glass, -4.15, nil, -0.95)
		for _, s in ipairs({ { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }) do
			local bar = w.mk("LanternBar", Vector3.new(0.09, 1, 0.09), brass, Enum.Material.Metal)
			w.add(bar, -4.15, CFrame.new(s[1] * 0.42 * w.scale, 0, s[2] * 0.42 * w.scale), -0.95)
		end
		local function setup()
			local l = Instance.new("PointLight")
			l.Name = "WickLight"
			l.Color, l.Range, l.Brightness = FLAME, 13, 1.1
			l.Parent = glass
		end
		return { handle = handle, bladeLen = 6.2, setup = setup }
	end,
}

M.Def = K.def({
	HP = 370, Speed = 9.5, Scale = 1.35, Damage = 34, Range = 12, HalfAngle = 22, Lunge = 6, Poise = 50, Stagger = 0.5, StaggerPush = 10,
	Windup = 0.75, Recover = 1, Engage = 20, Close = 11, Weapon = "LamplighterPole", IdleGrip = "LLCarry", Radius = 1.4, Skin = WAX, Cloth = COAT,
})

local function trim(e, tRoot)
	local glass, light = K.partOf(e, "LanternGlass"), K.partOf(e, "WickLight")
	K.sound(e, "FireHit", 0.3, 0.8)
	K.setBody(e, "GBCast", 0.4)
	K.setGrip(e, "GHigh", 0.4)
	local t0, T = os.clock(), 1.15
	while os.clock() - t0 < T do
		if not K.hold(e, 0.05) then
			if light then
				light.Brightness, light.Range = 1.1, 13
			end
			return false
		end
		local g = (os.clock() - t0) / T
		if light then
			light.Brightness, light.Range = 1.1 + 7 * g, 13 + 24 * g
		end
	end
	if light then
		light.Brightness, light.Range = 1.1, 13
	end
	local at = K.feet(e)
	K.area(at, 10, 6, 34, "Large")
	K.flash(glass and glass.Position or e.root.Position, FLAME, 12)
	K.sound(e, "WatchdogBlast", 0.65, 1.3)
	K.shake(at, 0.35)
	return e.alive
end

M.attack = K.brain(function(e, tRoot, d)
	local roll = math.random()
	if d > e.def.Close then
		K.setGrip(e, "GToss", 0.4)
		K.setBody(e, "GBSet", 0.4)
		if not K.hold(e, 0.7, tRoot) then
			return false
		end
		K.setGrip(e, "GTossed", 0.14)
		local from = (K.partOf(e, "LanternGlass") or e.root).Position
		K.shot(e, { from = from, vel = K.aim(from, tRoot, 20, 0), damage = 22, level = "Medium", radius = 1.8, life = 5, size = Vector3.new(0.8, 0.8, 0.8), color = FLAME, material = Enum.Material.Neon, trail = FLAME, home = 2.2, homeOn = tRoot })
		K.sound(e, "Lunge", 0.6, 1.6)
		return true, 1
	elseif roll < 0.45 then
		return trim(e, tRoot), 1.3
	end
	return K.strike(e, tRoot, { set = "GDraw", setBody = "GBDraw", tell = 0.72, swing = "GThrust", swingBody = "GBLunge", time = 0.12, range = 13, half = 18, lunge = 1.4, damage = 36, speed = 0.9 }), 1
end)

return M
