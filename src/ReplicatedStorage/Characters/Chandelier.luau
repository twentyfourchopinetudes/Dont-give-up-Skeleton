--!nonstrict
-- THE CHANDLER (kind Chandelier): the great hall's lamp-keeper, huge in the shoulders from hauling the chandeliers up and down. It wears a
-- leather hood and a wax-stiffened smock, and over one fist it wraps the chain of a whole gilt chandelier, still lit, which it
-- swings as you'd swing a flail. Fire dripping off it the whole time.
--   Dressing the Hall   round its head and round, faster, walking at you with it. Candles flying off
--   Let It Down         the whole chandelier up, and down on you: gold, wax and glass all over the floor
--   Back-swing          flat across, close in
local K = require(script.Parent.Parent:WaitForChild("GildedKit"))
local M = K.wrap({
	Poses = { CHBHaul = { drop = 0.3, lean = 0.2, spread = 0.26, head = 0.12, footR = -0.3, footL = 0.35, breathe = 1.8, la1 = 0.3, la3 = -0.4, lel = 0.8, freeL = 0 } },
	Grips = {
		CHHang = { Vector3.new(1.5, 0.3, -0.5), CFrame.Angles(math.rad(10), 0, 0) },
		CHOver = { Vector3.new(0.3, 3.4, -0.2), CFrame.Angles(0, 0, math.rad(95)) },
	},
})
M.Kind = "Chandelier"
M.Proportions = { girth = 1.32, arm = 1.18, hunch = 0.18 }
M.IdlePose = "CHBHaul"
M.BodyFor = { CHHang = "CHBHaul" }
local SMOCK, SMOCK_DK, WAX, FLAME = Color3.fromRGB(206, 192, 156), Color3.fromRGB(160, 146, 112), Color3.fromRGB(232, 222, 190), Color3.fromRGB(255, 190, 90)
M.Colors = { skin = Color3.fromRGB(104, 80, 62), torso = SMOCK, legs = K.LEATHER, arms = Color3.fromRGB(104, 80, 62) }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local rng = Random.new()
	-- the hood, buckled shut, one round glass eye; candle stubs burnt down on its shoulders
	deco("Head", "Hood", V(1.4, 1.42, 1.42), at(0, 0.02, 0.03), K.LEATHER, MAT.Leather)
	for _, y in ipairs({ -0.35, 0.18 }) do
		deco("Head", "Strap", V(1.46, 0.12, 1.46), at(0, y, 0.03), K.TARNISH, MAT.Metal)
	end
	deco("Head", "Goggle", V(0.1, 0.6, 0.6), at(0.22, 0.1, -0.74) * K.FACE, K.GOLD, MAT.Metal, Enum.PartType.Cylinder)
	deco("Head", "Lens", V(0.05, 0.42, 0.42), at(0.22, 0.1, -0.8) * K.FACE, FLAME, MAT.Neon, Enum.PartType.Cylinder)
	deco("Head", "Stitch", V(0.5, 0.05, 0.04), at(0, -0.42, -0.74), K.INK, MAT.SmoothPlastic)
	for _, sx in ipairs({ -1, 1 }) do
		for i = 0, 2 do
			local x = sx * (cw * 0.34 + i * 0.32)
			local h = 0.5 + rng:NextNumber(0, 0.5)
			deco("Chest", "Stub", V(0.26, h, 0.26), at(x, ch * 0.5 + h / 2, -0.15 + i * 0.1), WAX, MAT.SmoothPlastic)
			deco("Chest", "StubFlame", V(0.14, 0.26, 0.14), at(x, ch * 0.5 + h + 0.12, -0.15 + i * 0.1), FLAME, MAT.Neon, Enum.PartType.Ball)
		end
	end
	-- the smock, stiff with years of wax; run down its front in long pale drips
	deco("Chest", "Smock", V(cw * 1.06, ch * 1.02, cd * 1.1), at(0, 0, 0), SMOCK, MAT.Fabric)
	for _ = 1, 9 do
		local h = rng:NextNumber(0.4, 1.3)
		deco("Chest", "WaxRun", V(rng:NextNumber(0.1, 0.22), h, 0.06), at(rng:NextNumber(-0.42, 0.42) * cw, ch * 0.46 - h / 2, -cd * 0.57), WAX, MAT.SmoothPlastic)
	end
	k.tatter(rng, "Hips", CFrame.new(0, 0.1, -hd * 0.55), hw * 1.15, 2, SMOCK, SMOCK_DK, 0.35)
	k.tatter(rng, "Hips", CFrame.new(0, 0.1, hd * 0.55), hw * 1.15, 2.1, SMOCK, SMOCK_DK, 0.35)
	deco("Hips", "Belt", V(hw * 1.26, 0.34, hd * 1.3), at(0, 0.3, 0), K.LEATHER, MAT.Leather)
	deco("Hips", "Buckle", V(0.42, 0.3, 0.06), at(0, 0.3, -hd * 0.68), K.GOLD, MAT.Metal)
	-- spare candles in a quiver on its hip, a snuffer on the other
	deco("Hips", "Quiver", V(0.5, 1, 0.5), at(hw * 0.72, -0.4, 0), K.LEATHER, MAT.Leather)
	for i = -1, 1 do
		deco("Hips", "Candle", V(0.13, 0.9, 0.13), at(hw * 0.72 + i * 0.13, 0.25, i * 0.08), WAX, MAT.SmoothPlastic)
	end
	deco("Hips", "Snuffer", V(0.1, 1.3, 0.1), at(-hw * 0.74, -0.4, 0.05), K.GOLD, MAT.Metal)
	deco("Hips", "SnufferCup", V(0.34, 0.3, 0.34), at(-hw * 0.74, -1.15, 0.05), K.GOLD, MAT.Metal, Enum.PartType.Ball)
	for _, n in ipairs({ "R", "L" }) do
		for i = 0, 3 do
			deco(n .. "LowerArm", "ChainWrap", V(aw * 1.28, 0.12, aw * 1.28), at(0, la * 0.28 - i * la * 0.17, 0) * CFrame.Angles(0, 0, (i % 2 == 0 and 0.18 or -0.18)), K.TARNISH, MAT.Metal)
		end
		deco(n .. "Shin", "Boot", V(lw * 1.2, 1, lw * 1.2), at(0, -0.05, 0), K.LEATHER, MAT.Leather)
		deco(n .. "Foot", "Sole", V(0.82, 0.32, 1.2), at(0, 0.02, -0.05), K.INK, MAT.Leather)
	end
end

M.Weapons = {
	-- a length of chain, and hung from it a whole little chandelier: gold rings, arms, lit candles and glass drops
	ChandelierFlail = function(w)
		local gold, glass = K.GOLD, Color3.fromRGB(226, 236, 240)
		local handle = w.mk("Grip", Vector3.new(0.3, 0.8, 0.3), K.TARNISH, Enum.Material.Metal)
		for i = 1, 5 do
			w.add(w.mk("Link", Vector3.new(0.12, 0.42, 0.28), K.TARNISH, Enum.Material.Metal), -0.5 - i * 0.36, CFrame.Angles(0, (i % 2) * math.pi / 2, 0))
		end
		local Y = -3
		w.add(w.mk("Stem", Vector3.new(0.3, 1.8, 0.3), gold, Enum.Material.Metal), Y)
		local bottom = w.mk("Finial", Vector3.new(0.6, 0.6, 0.6), gold, Enum.Material.Metal)
		bottom.Shape = Enum.PartType.Ball
		w.add(bottom, Y - 1)
		local flames = {}
		for r, ring in ipairs({ { 1.45, Y - 0.35, 8 }, { 0.85, Y + 0.45, 6 } }) do
			local hoop = w.mk("Hoop", Vector3.new(0.12, ring[1] * 2, ring[1] * 2), gold, Enum.Material.Metal)
			hoop.Shape = Enum.PartType.Cylinder
			w.add(hoop, ring[2], CFrame.Angles(0, 0, math.pi / 2))
			for i = 1, ring[3] do
				local a = i / ring[3] * math.pi * 2
				local ox, oz = math.cos(a) * ring[1] * w.scale, math.sin(a) * ring[1] * w.scale
				w.add(w.mk("Candle", Vector3.new(0.14, 0.5, 0.14), Color3.fromRGB(232, 222, 190), Enum.Material.SmoothPlastic), ring[2] + 0.28, CFrame.new(ox, 0, oz))
				local f = w.mk("CandleFlame", Vector3.new(0.14, 0.26, 0.14), FLAME, Enum.Material.Neon)
				w.add(f, ring[2] + 0.62, CFrame.new(ox, 0, oz))
				table.insert(flames, f)
				if r == 1 then
					w.add(w.mk("Drop", Vector3.new(0.14, 0.34, 0.14), glass, Enum.Material.Glass), ring[2] - 0.32, CFrame.new(ox, 0, oz))
				end
			end
		end
		local function setup()
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness = FLAME, 13, 1.2
			l.Parent = flames[1]
		end
		return { handle = handle, bladeLen = 4.2, setup = setup }
	end,
}

M.Def = K.def({
	HP = 620, Speed = 8.5, Scale = 1.45, Damage = 48, Range = 10.5, HalfAngle = 70, Lunge = 6, Poise = 95, Stagger = 0.55, StaggerPush = 6,
	Windup = 1, Recover = 1.2, Engage = 12, Close = 8, Weapon = "ChandelierFlail", IdleGrip = "CHHang", Radius = 2, Skin = K.TARNISH, Cloth = SMOCK,
})

M.attack = K.brain(function(e, tRoot, d)
	local roll = math.random()
	if d >= e.def.Close or roll < 0.3 then
		return K.slam(e, tRoot, {
			set = "GRaise", setBody = "GBCast", tell = 1.05, swing = "GSlam", swingBody = "GBStrike", time = 0.2, range = 11, half = 50, level = "Knockdown",
			area = 7, areaDamage = 26, color = FLAME, lunge = 0.8, boom = 1.2, shake = 0.6,
		}), 1.5
	elseif roll < 0.68 then
		return K.whirl(e, tRoot, { grip = "CHOver", wind = 0.8, time = 2.4, radius = 8, damage = 24, every = 0.6, speed = 7, turn = 9 }), 1.5
	end
	return K.strike(e, tRoot, { set = "GBack", setBody = "GBWind", tell = 0.7, swing = "GSweep", swingBody = "GBSweep", time = 0.2, range = 9.5, half = 90, damage = 40, speed = 0.65 }), 1.1
end)

return M
