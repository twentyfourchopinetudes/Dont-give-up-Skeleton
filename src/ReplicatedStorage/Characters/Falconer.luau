--!nonstrict
-- THE FALCONER (kind Falconer): the royal mews' master, in green and gold with a feathered hat, a gauntlet up to its shoulder and a hunting-horn at
-- its hip. On its fist sits a falcon of clockwork gold, jessed and hooded, and it never takes its eyes off you. The falconer's old
-- and a little stiff. The falcon isn't.
--   Stoop       the hood whipped off, the bird flung: it climbs, turns, and comes for you, following as it comes. Roll at the last
--   Lure        a weighted lure swung on its line, in a wide flat circle
--   Gauntlet    a backhand with all that iron, and a short hunting sword when you're inside it
local K = require(script.Parent.Parent:WaitForChild("GildedKit"))
local M = K.wrap({
	Poses = {
		FCBFist = { drop = 0.1, lean = 0.08, head = 0.02, footR = -0.18, footL = 0.22, spread = 0.1, breathe = 0.7, la1 = 1.15, la2 = 0.1, la3 = -0.35, lel = 1.7, freeL = 0 },
		FCBCast = { drop = 0.35, lean = 0.45, head = -0.2, footR = 0.6, footL = -0.5, la1 = 2.2, la2 = 0, la3 = -0.2, lel = 0.1, freeL = 0 },
	},
	Grips = { FCSide = { Vector3.new(1.2, -0.3, -0.5), CFrame.Angles(math.rad(50), 0, 0) } },
})
M.Kind = "Falconer"
M.Proportions = { girth = 0.98, arm = 1.02, hunch = 0.06 }
M.IdlePose = "FCBFist"
M.BodyFor = { FCSide = "FCBFist" }
local GREEN, GREEN_DK, BUFF, BIRD = Color3.fromRGB(58, 90, 54), Color3.fromRGB(36, 58, 36), Color3.fromRGB(170, 140, 96), K.GOLD
M.Colors = { skin = Color3.fromRGB(150, 118, 96), torso = GREEN, legs = BUFF, arms = GREEN }
-- the bird itself, on any body: its breast, head, wings, tail
local function falcon(deco, on, F, V, MAT, hooded)
	deco(on, "BirdBody", V(0.6, 0.95, 0.72), F * CFrame.new(0, 0.5, 0), BIRD, MAT.Metal, Enum.PartType.Ball)
	deco(on, "BirdHead", V(0.44, 0.44, 0.44), F * CFrame.new(0, 1.05, -0.1), K.LIGHT, MAT.Metal, Enum.PartType.Ball)
	deco(on, "BirdBeak", V(0.12, 0.14, 0.24), F * CFrame.new(0, 1, -0.36), K.TARNISH, MAT.Metal)
	if hooded then
		deco(on, "BirdHood", V(0.48, 0.34, 0.48), F * CFrame.new(0, 1.15, -0.1), K.RUG, MAT.Leather, Enum.PartType.Ball)
		deco(on, "HoodPlume", V(0.05, 0.3, 0.05), F * CFrame.new(0, 1.42, -0.1), K.LIGHT, MAT.Metal)
	end
	for _, sx in ipairs({ -1, 1 }) do
		deco(on, "BirdWing", V(0.1, 0.95, 0.42), F * CFrame.new(sx * 0.34, 0.4, 0.14) * CFrame.Angles(-0.25, 0, sx * 0.12), K.TARNISH, MAT.Metal)
	end
	deco(on, "BirdTail", V(0.3, 0.7, 0.07), F * CFrame.new(0, -0.1, 0.32) * CFrame.Angles(0.4, 0, 0), K.TARNISH, MAT.Metal)
end

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local ball = Enum.PartType.Ball
	-- a dry, grey-bearded face; a green hat with a long pheasant feather
	parts.Head.Material = MAT.SmoothPlastic
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "Eye", V(0.18, 0.08, 0.04), at(sx * 0.25, 0.12, -0.59), K.INK, MAT.SmoothPlastic)
		deco("Head", "Brow", V(0.3, 0.08, 0.06), at(sx * 0.25, 0.25, -0.58) * CFrame.Angles(0, 0, sx * 0.2), rgb(190, 186, 176), MAT.Sand)
	end
	deco("Head", "Beard", V(0.92, 0.72, 0.42), at(0, -0.58, -0.32), rgb(186, 182, 172), MAT.Sand)
	deco("Head", "BeardPoint", V(0.5, 0.5, 0.3), at(0, -1, -0.38), rgb(176, 172, 162), MAT.Sand)
	deco("Head", "Moustache", V(0.8, 0.12, 0.1), at(0, -0.16, -0.59), rgb(196, 192, 182), MAT.Sand)
	deco("Head", "Brim", V(1.85, 0.12, 1.75), at(0, 0.56, 0), GREEN_DK, MAT.Fabric)
	deco("Head", "HatCrown", V(1.25, 0.72, 1.2), at(0, 0.92, 0.05) * CFrame.Angles(0.05, 0, 0.04), GREEN, MAT.Fabric)
	deco("Head", "HatBand", V(1.3, 0.14, 1.25), at(0, 0.66, 0.05), K.GOLD, MAT.Metal)
	for i = 0, 3 do
		deco("Head", "Feather", V(0.08, 0.72, 0.2), at(0.62, 0.95 + i * 0.32, 0.3 + i * i * 0.1) * CFrame.Angles(-0.35 - i * 0.2, 0, -0.1), i % 2 == 0 and rgb(160, 110, 60) or K.PORCELAIN, MAT.Fabric)
	end
	-- the hunting coat, its belt of hoods and bells, the horn on its hip
	deco("Chest", "Coat", V(cw * 1.04, ch, cd * 1.08), at(0, 0, 0), GREEN, MAT.Fabric)
	deco("Chest", "Baldric", V(0.3, ch * 1.3, 0.06), at(0, 0, -cd * 0.56) * CFrame.Angles(0, 0, 0.62), K.LEATHER, MAT.Leather)
	deco("Chest", "Baldric", V(0.3, ch * 1.3, 0.06), at(0, 0, cd * 0.56) * CFrame.Angles(0, 0, -0.62), K.LEATHER, MAT.Leather)
	deco("Chest", "Badge", V(0.05, 0.42, 0.42), at(0.1, 0.14, -cd * 0.6) * K.FACE, K.GOLD, MAT.Metal, Enum.PartType.Cylinder)
	for _, x in ipairs({ -1, 1 }) do
		deco("Hips", "CoatSkirt", V(hw * 0.52, 1.7, hd * 1.2), at(x * hw * 0.28, -0.6, 0), GREEN_DK, MAT.Fabric)
	end
	deco("Hips", "Belt", V(hw * 1.24, 0.24, hd * 1.28), at(0, 0.3, 0), K.LEATHER, MAT.Leather)
	for i = -1, 1 do
		deco("Hips", "SpareHood", V(0.26, 0.28, 0.26), at(hw * 0.7 + i * 0.08, 0, -hd * 0.4 + i * 0.3), K.RUG, MAT.Leather, ball)
	end
	for i = 0, 3 do
		deco("Hips", "Horn", V(0.44 - i * 0.08, 0.44 - i * 0.08, 0.42), at(-hw * 0.82, -0.3 + i * 0.16, 0.5 - i * 0.34) * CFrame.Angles(0.5, 0, 0), K.GOLD, MAT.Metal, ball)
	end
	for _, n in ipairs({ "R", "L" }) do
		deco(n .. "Thigh", "Breeches", V(lw * 1.14, 1, lw * 1.14), at(0, 0.03, 0), BUFF, MAT.Leather)
		deco(n .. "Shin", "Boot", V(lw * 1.18, 1.08, lw * 1.18), at(0, 0, 0), K.LEATHER, MAT.Leather)
		deco(n .. "Foot", "BootFoot", V(0.68, 0.3, 1.15), at(0, 0.02, -0.05), K.LEATHER, MAT.Leather)
	end
	deco("RLowerArm", "Cuff", V(aw * 1.25, 0.4, aw * 1.25), at(0, -la * 0.34, 0), K.LEATHER, MAT.Leather)
	-- THE GAUNTLET to the shoulder on its left arm, iron-scaled, and the falcon on the fist
	deco("LUpperArm", "Vambrace", V(aw * 1.45, ua * 1.05, aw * 1.45), at(0, 0, 0), K.LEATHER, MAT.Leather)
	deco("LLowerArm", "GauntletBig", V(aw * 1.55, la * 1.08, aw * 1.55), at(0, -0.04, 0), K.LEATHER, MAT.Leather)
	for i = 0, 3 do
		deco("LLowerArm", "Scale", V(aw * 1.65, 0.14, aw * 1.65), at(0, la * 0.36 - i * la * 0.24, 0), K.TARNISH, MAT.Metal)
	end
	falcon(deco, "LLowerArm", at(0, -la / 2 - 0.15, 0) * CFrame.Angles(math.pi, 0, 0), V, MAT, true) -- (turned over: the bird stands out of the fist, along the forearm)
	for i = 0, 2 do
		deco("LLowerArm", "Jess", V(0.05, 0.3, 0.05), at(0.1, -la / 2 + 0.1 - i * 0.22, -0.16), K.RUG, MAT.Leather)
	end
end

M.Weapons = {
	HuntingSword = function(w)
		local handle = w.mk("Grip", Vector3.new(0.2, 0.8, 0.2), K.LEATHER, Enum.Material.Leather)
		w.add(w.mk("Guard", Vector3.new(0.95, 0.14, 0.2), K.GOLD, Enum.Material.Metal), -0.46)
		w.add(w.mk("Blade", Vector3.new(0.34, 2.9, 0.08), Color3.fromRGB(190, 192, 188), Enum.Material.Metal), -2)
		w.add(w.mk("Tip", Vector3.new(0.24, 0.24, 0.08), Color3.fromRGB(190, 192, 188), Enum.Material.Metal), -3.45, CFrame.Angles(0, 0, math.pi / 4))
		w.add(w.mk("Lure", Vector3.new(0.6, 0.6, 0.6), K.GOLD, Enum.Material.Metal), 0.65)
		return { handle = handle, bladeLen = 3.8 }
	end,
}

M.Def = K.def({
	HP = 380, Speed = 10, Scale = 1.2, Damage = 32, Range = 8, HalfAngle = 60, Lunge = 8, Poise = 55, Stagger = 0.55, StaggerPush = 10,
	Windup = 0.7, Recover = 0.95, Engage = 28, Close = 8, Weapon = "HuntingSword", IdleGrip = "FCSide", Radius = 1.4, Skin = BUFF, Cloth = GREEN,
})

-- THE STOOP: it casts the bird; a gold falcon's body flies up, turns over, and homes in, wings out
local function stoop(e, tRoot)
	K.setBody(e, "GBCast", 0.5)
	K.sound(e, "Unsheath", 0.35, 1.5)
	if not K.hold(e, 0.75, tRoot) then
		return false
	end
	K.setBody(e, "FCBCast", 0.12)
	K.sound(e, "WatchdogBlast", 0.4, 2)
	local body = K.partOf(e, "BirdBody")
	local from = body and body.Position or e.root.Position + Vector3.new(0, 3, 0)
	for _, n in ipairs({ "BirdBody", "BirdHead", "BirdBeak", "BirdHood", "HoodPlume" }) do
		local p = K.partOf(e, n)
		if p then
			p.Transparency = 1
		end
	end
	for _, c in ipairs(e.model:GetDescendants()) do
		if c.Name == "BirdWing" or c.Name == "BirdTail" then
			c.Transparency = 1
		end
	end
	local look = e.root.CFrame.LookVector
	K.shot(e, {
		from = from, vel = look * 22 + Vector3.new(0, 34, 0), damage = 32, level = "Large", radius = 2, life = 4.5, gravity = 0, home = 3.2, homeOn = tRoot,
		size = Vector3.new(0.8, 0.5, 1.5), shape = Enum.PartType.Ball, color = BIRD, trail = K.LIGHT, spin = 0,
		make = function(p)
			for _, s in ipairs({ -1, 1 }) do
				local wing = Instance.new("Part")
				wing.Name = "Wing"
				wing.Anchored, wing.CanCollide, wing.CanQuery, wing.CanTouch, wing.Massless = false, false, false, false, true
				wing.Size, wing.Color, wing.Material = Vector3.new(2.1, 0.08, 0.8), K.TARNISH, Enum.Material.Metal
				wing.CFrame = p.CFrame * CFrame.new(s * 1.2, 0, 0) * CFrame.Angles(0, 0, s * 0.2)
				local wd = Instance.new("WeldConstraint")
				wd.Part0, wd.Part1 = p, wing
				wd.Parent = wing
				wing.Parent = p
			end
		end,
	})
	-- (it's back on the fist a while later: the bird comes home)
	task.delay(5, function()
		if e.alive and e.model.Parent then
			for _, c in ipairs(e.model:GetDescendants()) do
				if c.Name:sub(1, 4) == "Bird" or c.Name == "HoodPlume" then
					c.Transparency = 0
				end
			end
		end
	end)
	return K.hold(e, 0.6, tRoot)
end

M.attack = K.brain(function(e, tRoot, d)
	local roll = math.random()
	if d > e.def.Close or roll < 0.2 then
		return stoop(e, tRoot), 1.1
	elseif roll < 0.55 then
		return K.combo(e, tRoot, {
			{ set = "GCock", setBody = "GBSet", tell = 0.55, swing = "GCut", swingBody = "GBStrike", time = 0.13, damage = 26, level = "Medium", speed = 1.05 },
			{ set = "GBack", setBody = "GBWind", tell = 0.25, swing = "GSweep", swingBody = "GBSweep", time = 0.13, damage = 30, speed = 1, quiet = true },
		}), 0.9
	end
	return K.strike(e, tRoot, { setBody = "GBSpin", set = "GGuard", tell = 0.6, swingBody = "GBFling", time = 0.15, range = 9.5, half = 75, damage = 34, level = "Knockdown", speed = 0.75, lunge = 1.2 }), 1
end)

return M
