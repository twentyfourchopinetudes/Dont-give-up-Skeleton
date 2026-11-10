--!nonstrict
-- THE ARRAS (kind Arras): a tapestry that's come down off its wall with someone still behind it. A long hanging of crimson and gold thread,
-- faded hunting scenes on it, hung from a bar across shoulders you can't see, drifting a little above the floor. A shape pushes against
-- the cloth from inside: a face, two hands, gone when you look. It doesn't walk. It doesn't quite touch the ground.
--   Lash        a corner of it flung out at you, further than it should reach
--   Smother     it comes over you: everything goes dark red, it holds you, and it squeezes. Roll out as it falls
--   Dust        shaken like a rug: three hundred years of it in a choking cloud
local K = require(script.Parent.Parent:WaitForChild("GildedKit"))
local M = K.wrap({
	Poses = {
		ARBDrift = { drop = -0.3, lean = 0.05, head = 0.2, footR = 0, footL = 0, spread = 0, breathe = 2.5, la1 = 0.1, la3 = -0.1, lel = 0.1, freeL = 0 },
		ARBRear = { drop = -0.55, lean = -0.4, head = -0.4, footR = 0, footL = 0, la1 = 2.2, la3 = -1, lel = 0.4, freeL = 0 },
		ARBFold = { drop = 0.7, lean = 0.9, head = 0.3, footR = 0, footL = 0, la1 = 0.9, la3 = -0.15, lel = 1, freeL = 0 },
		ARBShake = { drop = -0.1, lean = 0.1, side = 0.25, head = -0.2, footR = 0, footL = 0, la1 = 1, la3 = -1, lel = 0.2, freeL = 0 },
	},
	Grips = { ARRest = { Vector3.new(1.1, -0.2, -0.3), CFrame.Angles(math.rad(10), 0, 0) } },
})
M.Kind = "Arras"
M.Proportions = { girth = 0.96, arm = 1.15, hunch = 0.06 }
M.IdlePose = "ARBDrift"
M.BodyFor = { ARRest = "ARBDrift" }
local RED, RED_DK, THREAD, WOVEN = K.RUG, Color3.fromRGB(78, 18, 30), K.GOLD, Color3.fromRGB(136, 118, 80)
M.Colors = { skin = K.INK, torso = RED, legs = RED_DK, arms = RED }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local rng = Random.new()
	-- the head's a push in the cloth: a face-shaped bulge, two dim gold holes
	deco("Head", "HeadCloth", V(1.3, 1.42, 1.3), at(0, 0, 0), RED, MAT.Fabric, Enum.PartType.Ball)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "Eye", V(0.14, 0.08, 0.05), at(sx * 0.26, 0.1, -0.64), K.LIGHT, MAT.Neon)
		deco("Head", "Brow", V(0.3, 0.12, 0.14), at(sx * 0.26, 0.22, -0.58) * CFrame.Angles(0, 0, -sx * 0.3), RED_DK, MAT.Fabric)
	end
	deco("Head", "Mouth", V(0.3, 0.26, 0.1), at(0, -0.32, -0.6), RED_DK, MAT.Fabric, Enum.PartType.Ball)
	-- THE BAR across its shoulders, gold finials, the rings the cloth hangs on
	deco("Chest", "Bar", V(cw * 2.4, 0.22, 0.22), at(0, ch * 0.54, 0), K.TARNISH, MAT.Metal)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Chest", "Finial", V(0.44, 0.44, 0.44), at(sx * cw * 1.24, ch * 0.54, 0), K.GOLD, MAT.Metal, Enum.PartType.Ball)
		deco("Chest", "FinialSpike", V(0.14, 0.14, 0.5), at(sx * cw * 1.46, ch * 0.54, 0) * CFrame.Angles(0, math.pi / 2, 0), K.GOLD, MAT.Metal)
	end
	for i = 0, 7 do
		deco("Chest", "Ring", V(0.24, 0.3, 0.1), at((i - 3.5) * cw * 0.3, ch * 0.45, 0), K.GOLD, MAT.Metal)
	end
	-- THE TAPESTRY front and back: broad panels, woven hunting scene, gold bands, fringe at the foot, ragged at one corner
	local W, TOP = cw * 2.25, ch * 0.42
	for _, z in ipairs({ -1, 1 }) do
		deco("Chest", "Hanging", V(W, ch * 1.05, 0.08), at(0, ch * -0.1, z * cd * 0.56), RED, MAT.Fabric)
		deco("Chest", "Band", V(W, 0.18, 0.1), at(0, TOP - 0.04, z * cd * 0.58), THREAD, MAT.Fabric)
		deco("Hips", "HangingLow", V(W, 3, 0.08), at(0, -1.2, z * hd * 0.72), RED, MAT.Fabric)
		deco("Hips", "BandLow", V(W, 0.18, 0.1), at(0, -2.55, z * hd * 0.74), THREAD, MAT.Fabric)
		for i = 0, 15 do
			deco("Hips", "Fringe", V(0.1, rng:NextNumber(0.2, 0.35), 0.06), at(-W / 2 + (i + 0.5) * W / 16, -2.78, z * hd * 0.72), THREAD, MAT.Fabric)
		end
	end
	-- what's woven on it: a stag among trees, faded, a mounted hunter, stars; and its woven border
	local z = -cd * 0.62
	for _, t in ipairs({ { -0.75, -0.15 }, { 0.72, 0.05 }, { -0.95, 0.2 } }) do
		deco("Chest", "Trunk", V(0.14, 0.9, 0.04), at(t[1] * cw, t[2] - 0.2, z), WOVEN, MAT.Fabric)
		deco("Chest", "Crown", V(0.72, 0.72, 0.04), at(t[1] * cw, t[2] + 0.35, z), K.JADE, MAT.Fabric, Enum.PartType.Ball)
	end
	deco("Chest", "Stag", V(0.72, 0.32, 0.04), at(0.05, -0.08, z), WOVEN, MAT.Fabric)
	deco("Chest", "StagNeck", V(0.14, 0.38, 0.04), at(0.42, 0.14, z) * CFrame.Angles(0, 0, -0.5), WOVEN, MAT.Fabric)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Chest", "Antler", V(0.04, 0.3, 0.04), at(0.5 + sx * 0.08, 0.42, z) * CFrame.Angles(0, 0, -sx * 0.5), THREAD, MAT.Fabric)
		deco("Chest", "StagLeg", V(0.06, 0.3, 0.04), at(0.05 + sx * 0.24, -0.34, z), WOVEN, MAT.Fabric)
	end
	for _ = 1, 8 do
		deco("Chest", "Star", V(0.09, 0.09, 0.04), at(rng:NextNumber(-1.1, 1.1) * cw * 0.85, rng:NextNumber(0.1, 0.6), z), K.LIGHT, MAT.Fabric, Enum.PartType.Ball)
	end
	deco("Hips", "Hound", V(0.8, 0.24, 0.04), at(-0.55, -1, -hd * 0.78), WOVEN, MAT.Fabric)
	deco("Hips", "HoundHead", V(0.28, 0.2, 0.04), at(-0.1, -0.9, -hd * 0.78), WOVEN, MAT.Fabric)
	for i = 0, 1 do
		deco("Hips", "HoundLeg", V(0.06, 0.28, 0.04), at(-0.85 + i * 0.6, -1.2, -hd * 0.78), WOVEN, MAT.Fabric)
	end
	deco("Hips", "Water", V(cw * 1.8, 0.14, 0.04), at(0, -2.2, -hd * 0.78), K.LAPIS, MAT.Fabric)
	for _, n in ipairs({ "R", "L" }) do
		deco(n .. "LowerArm", "Bulge", V(aw * 1.15, 0.6, aw * 1.15), at(0, -la / 2, 0), RED_DK, MAT.Fabric, Enum.PartType.Ball)
		for _, pn in ipairs({ "Thigh", "Shin", "Foot" }) do
			parts[n .. pn].Transparency = 1
		end
	end
end

-- no blade. The corner of the cloth, wrapped round its fist: what the "weapon" is, a strip it flicks
M.Weapons = {
	ArrasCorner = function(w)
		local handle = w.mk("Grip", Vector3.new(0.5, 0.6, 0.5), RED_DK, Enum.Material.Fabric)
		for i = 0, 4 do
			local width = 0.9 - i * 0.12
			w.add(w.mk("Lash", Vector3.new(width, 1.25, 0.06), i % 2 == 0 and RED or RED_DK, Enum.Material.Fabric), -0.65 - i * 1.15)
			w.add(w.mk("LashEdge", Vector3.new(0.05, 1.25, 0.08), THREAD, Enum.Material.Fabric), -0.65 - i * 1.15, CFrame.new(width / 2 * w.scale, 0, 0))
		end
		return { handle = handle, bladeLen = 6 }
	end,
}

M.Def = K.def({
	HP = 390, Speed = 9, Scale = 1.3, Damage = 30, Range = 12, HalfAngle = 26, Lunge = 5, Poise = 48, Stagger = 0.7, StaggerPush = 16,
	Windup = 0.6, Recover = 0.9, Engage = 13, Close = 7.5, Weapon = "ArrasCorner", IdleGrip = "ARRest", Radius = 2, Skin = RED, Cloth = RED,
})

-- SMOTHER: rearing up and coming down on you. Under it, you're held a moment (a Knockdown from above) and squeezed three times
local function smother(e, tRoot)
	return K.strike(e, tRoot, {
		setBody = "ARBRear", tell = 1, swingBody = "ARBFold", time = 0.22, range = 8, half = 75, damage = 26, level = "Knockdown", lunge = 3, speed = 0.45,
		after = function(_, hit)
			if hit then
				for _ = 1, 2 do
					task.wait(0.32)
					if e.alive then
						K.area(K.feet(e), 8, 5, 12, "Small")
						K.sound(e, "Impact", 0.4, 0.5)
					end
				end
			end
		end,
	})
end
local function dust(e, tRoot)
	K.setBody(e, "ARBShake", 0.3)
	K.sound(e, "Unsheath", 0.3, 0.45)
	if not K.hold(e, 0.7, tRoot) then
		return false
	end
	K.cloud(K.feet(e) + (tRoot.Position - e.root.Position) * Vector3.new(1, 0, 1) * 0.4, { radius = 8.5, life = 4, color = Color3.fromRGB(150, 130, 100), rate = 40, damage = 7, tick = 0.5 })
	return true
end

M.attack = K.brain(function(e, tRoot, d)
	local roll = math.random()
	if d <= e.def.Close and roll < 0.45 then
		return smother(e, tRoot), 1.2
	elseif roll < 0.25 then
		return dust(e, tRoot), 0.6
	end
	return K.strike(e, tRoot, { set = "GBack", setBody = "GBWind", tell = 0.62, swing = "GThrust", swingBody = "GBLunge", time = 0.12, range = 13, half = 24, damage = 32, level = "Medium", lunge = 0.6, speed = 1 }), 0.8
end)

return M
