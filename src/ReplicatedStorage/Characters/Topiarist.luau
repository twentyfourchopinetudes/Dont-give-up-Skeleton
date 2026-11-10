--!nonstrict
-- THE TOPIARIST (kind Topiarist): the terraces' gardener, who has been kept on so long the garden's begun to keep it. A broad straw hat,
-- a green baize apron, and out of its collar and its back the hedge it never finished trimming: clipped leaf, blossom in its
-- shoulders, roots for boots. Great gold-handled shears as long as you are.
--   The Cut      the shears wide open, and SNIP: a wide bite right in front of it, and they're heavy to get open again
--   Dead-Head    three short snips, walking at you
--   Blossom      it shakes itself: a cloud of petals hangs there, and it's sweet, and it's poison
--   Hedge Run    from further off: the shears thrown wide, a charge across the lawn, and SNAP at the end of it
local K = require(script.Parent.Parent:WaitForChild("GildedKit"))
local Config = require(script.Parent.Parent:WaitForChild("Config"))
local M = K.wrap({
	Poses = { TOBWork = { drop = 0.4, lean = 0.32, head = 0.06, spread = 0.22, footR = -0.3, footL = 0.35, breathe = 1, la1 = 0.7, la3 = -0.2, lel = 1.4, freeL = 0 } },
	Grips = { TOHold = { Vector3.new(0.5, 0.2, -1.5), CFrame.Angles(math.rad(105), 0, 0) } },
})
M.Kind = "Topiarist"
M.Proportions = { girth = 1.18, arm = 1.1, hunch = 0.16 }
M.IdlePose = "TOBWork"
M.BodyFor = { TOHold = "TOBWork" }
local BAIZE, HEDGE, HEDGE_DK, STRAW, BARK = Color3.fromRGB(46, 78, 50), K.LEAF, Color3.fromRGB(56, 98, 52), Color3.fromRGB(190, 164, 104), Color3.fromRGB(70, 54, 40)
M.Colors = { skin = BARK, torso = BAIZE, legs = BARK, arms = BARK }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local rng = Random.new()
	local ball = Enum.PartType.Ball
	-- a knot of wood for a face, moss on it; a wide straw hat, its brim gone at one edge
	parts.Head.Material, parts.Head.Color = MAT.Wood, BARK
	deco("Head", "Brim", V(0.14, 3, 3), at(0, 0.58, 0) * K.UP, STRAW, MAT.Sand, Enum.PartType.Cylinder)
	deco("Head", "HatCrown", V(0.9, 1.35, 1.35), at(0, 0.98, 0) * K.UP, STRAW, MAT.Sand, Enum.PartType.Cylinder)
	deco("Head", "HatBand", V(0.22, 1.4, 1.4), at(0, 0.72, 0) * K.UP, K.RUG, MAT.Fabric, Enum.PartType.Cylinder)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "EyeKnot", V(0.3, 0.3, 0.1), at(sx * 0.26, 0.1, -0.56), K.INK, MAT.Wood, ball)
		deco("Head", "Eye", V(0.09, 0.09, 0.05), at(sx * 0.26, 0.1, -0.62), K.LIGHT, MAT.Neon, ball)
	end
	deco("Head", "Moss", V(0.9, 0.42, 0.14), at(0, -0.5, -0.5), HEDGE_DK, MAT.Grass)
	-- THE HEDGE: round clipped masses out of its shoulders and its back, blossom through them
	for _, q in ipairs({ { 0, 0.8, 0.8, 1.9 }, { -0.95, 0.55, 0.65, 1.5 }, { 0.95, 0.55, 0.65, 1.5 }, { 0, -0.2, 0.95, 1.7 }, { -0.75, -0.55, 0.7, 1.1 }, { 0.75, -0.55, 0.7, 1.15 } }) do
		deco("Chest", "Hedge", V(q[4], q[4], q[4]), at(q[1] * cw * 0.5, q[2], q[3]), rng:NextNumber() < 0.5 and HEDGE or HEDGE_DK, MAT.Grass, ball)
	end
	for _ = 1, 9 do
		local a, b = rng:NextNumber(-1, 1), rng:NextNumber(-0.5, 1.1)
		deco("Chest", "Bloom", V(0.36, 0.36, 0.36), at(a * cw * 0.6, b, cd * 0.5 + rng:NextNumber(0.5, 1.45)), K.BLOSSOM, MAT.SmoothPlastic, ball)
	end
	for _, sx in ipairs({ -1, 1 }) do
		deco("Chest", "ShoulderLeaf", V(0.95, 0.95, 0.95), at(sx * cw * 0.5, ch * 0.5, 0), HEDGE, MAT.Grass, ball)
		deco("Chest", "ShoulderBloom", V(0.3, 0.3, 0.3), at(sx * cw * 0.6, ch * 0.72, -0.2), K.BLOSSOM, MAT.SmoothPlastic, ball)
	end
	-- the baize apron, its pockets, trowel and twine
	deco("Chest", "ApronBib", V(cw * 0.76, ch * 0.78, 0.08), at(0, -0.1, -cd * 0.56), BAIZE, MAT.Fabric)
	deco("Hips", "Apron", V(hw * 1.1, 2.2, 0.08), at(0, -0.9, -hd * 0.62), BAIZE, MAT.Fabric)
	deco("Hips", "Pocket", V(hw * 0.7, 0.55, 0.06), at(0, -0.65, -hd * 0.68), K.TARNISH, MAT.Fabric)
	deco("Hips", "Trowel", V(0.26, 0.6, 0.04), at(-hw * 0.2, -0.45, -hd * 0.73), rgb(160, 156, 140), MAT.Metal)
	deco("Hips", "Twine", V(0.36, 0.3, 0.3), at(hw * 0.68, 0.05, -0.1), STRAW, MAT.Fabric, ball)
	deco("Hips", "Belt", V(hw * 1.25, 0.22, hd * 1.3), at(0, 0.3, 0), K.LEATHER, MAT.Leather)
	-- roots for boots, ivy up its arms
	for _, n in ipairs({ "R", "L" }) do
		for i = 0, 3 do
			local a = i * math.pi / 2 + 0.5
			deco(n .. "Foot", "Root", V(0.22, 0.2, 0.75), at(math.cos(a) * 0.28, -0.04, math.sin(a) * 0.4 - 0.1) * CFrame.Angles(0, -a + math.pi / 2, 0), BARK, MAT.Wood)
		end
		deco(n .. "Shin", "Gaiter", V(lw * 1.14, 1, lw * 1.14), at(0, -0.05, 0), BAIZE:Lerp(rgb(0, 0, 0), 0.25), MAT.Fabric)
		for i = 0, 2 do
			deco(n .. "UpperArm", "Ivy", V(0.34, 0.14, 0.34), at(aw * 0.45, ua * (0.35 - i * 0.3), aw * 0.2), HEDGE_DK, MAT.Grass, ball)
			deco(n .. "LowerArm", "Ivy", V(0.34, 0.14, 0.34), at(-aw * 0.45, la * (0.35 - i * 0.3), -aw * 0.2), HEDGE, MAT.Grass, ball)
		end
		deco(n .. "LowerArm", "Glove", V(aw * 1.2, la * 0.5, aw * 1.2), at(0, -la * 0.25, 0), K.LEATHER, MAT.Leather)
	end
end

M.Weapons = {
	-- a pair of hedge shears the size of a door, its blades a little apart
	GreatShears = function(w)
		local steel, gold = Color3.fromRGB(190, 192, 188), K.GOLD
		local handle = w.mk("Grip", Vector3.new(0.3, 1.5, 0.3), gold, Enum.Material.Metal)
		w.add(w.mk("Pivot", Vector3.new(0.5, 0.42, 0.5), K.TARNISH, Enum.Material.Metal), -0.9)
		for _, s in ipairs({ -1, 1 }) do
			w.add(w.mk("ShearBlade", Vector3.new(0.34, 5.2, 0.1), steel, Enum.Material.Metal), -3.4, CFrame.Angles(0, 0, s * 0.085) * CFrame.new(s * 0.18 * w.scale, 0, s * 0.05 * w.scale))
			w.add(w.mk("ShearEdge", Vector3.new(0.05, 5.1, 0.12), gold, Enum.Material.Metal), -3.4, CFrame.Angles(0, 0, s * 0.085) * CFrame.new(s * 0.02 * w.scale, 0, s * 0.05 * w.scale))
			w.add(w.mk("Bow", Vector3.new(0.14, 0.2, 1.1), gold, Enum.Material.Metal), 0.9, CFrame.new(s * 0.45 * w.scale, 0, 0))
		end
		return { handle = handle, bladeLen = 6 }
	end,
}

M.Def = K.def({
	HP = 500, Speed = 9, Scale = 1.3, Damage = 46, Range = 9, HalfAngle = 45, Lunge = 8, Poise = 80, Stagger = 0.5, StaggerPush = 8,
	Windup = 0.9, Recover = 1.15, Engage = 20, Close = 8, Weapon = "GreatShears", IdleGrip = "TOHold", Radius = 1.8, Skin = BARK, Cloth = BAIZE,
})

local function cut(e, tRoot)
	return K.strike(e, tRoot, { set = "GWide", setBody = "GBDraught", tell = 0.95, swing = "GThrust", swingBody = "GBLunge", time = 0.12, range = 9.5, half = 50, damage = 54, level = "Knockdown", lunge = 1.6, speed = 0.55 })
end
local function snips(e, tRoot)
	return K.combo(e, tRoot, {
		{ set = "GDraw", setBody = "GBDraw", tell = 0.6, swing = "GThrust", swingBody = "GBLunge", time = 0.1, range = 8.5, half = 36, damage = 24, level = "Medium", speed = 1.15 },
		{ set = "GDraw", setBody = "GBDraw", tell = 0.28, swing = "GThrust", swingBody = "GBLunge", time = 0.1, range = 8.5, half = 36, damage = 24, level = "Medium", speed = 1.2, quiet = true },
		{ set = "GDraw", setBody = "GBDraw", tell = 0.36, swing = "GThrust", swingBody = "GBLunge", time = 0.1, range = 9, half = 36, damage = 30, speed = 1.05, quiet = true, lunge = 1.3 },
	})
end
-- BLOSSOM: it shudders; petals go up off its back and hang where they fall
local function blossom(e, tRoot)
	K.setBody(e, "GBLow", 0.4)
	K.sound(e, "Unsheath", 0.3, 1.8)
	if not K.hold(e, 0.8, tRoot) then
		return false
	end
	K.setBody(e, "GBDraught", 0.14)
	local at = K.feet(e) + (tRoot.Parent and (tRoot.Position - e.root.Position) * Vector3.new(1, 0, 1) * 0.45 or Vector3.zero)
	K.cloud(at, { radius = 9, life = 6, color = K.BLOSSOM, rate = 45, poison = Config.Usher.Poison })
	K.flash(e.root.Position + Vector3.new(0, 2, 0), K.BLOSSOM, 6)
	return K.hold(e, 0.35, tRoot)
end

local function hedgeRun(e, tRoot)
	if not K.rush(e, tRoot, { set = "GWide", setBody = "GBLow", tell = 0.8, drive = "GWide", driveBody = "GBLunge", speed = 38, time = 0.55, damage = 30, level = "Medium", reach = 4.5, pitch = 0.8 }) then
		return false
	end
	return K.strike(e, tRoot, { set = "GWide", tell = 0.12, swing = "GThrust", swingBody = "GBLunge", time = 0.1, range = 9, half = 60, damage = 40, level = "Knockdown", lunge = 1.2, speed = 0.8, quiet = true })
end

M.attack = K.brain(function(e, tRoot, d)
	local roll = math.random()
	if roll < 0.25 then
		return blossom(e, tRoot), 0.6
	elseif d > e.def.Close + 1 then
		return hedgeRun(e, tRoot), 1.3
	elseif d < e.def.Close and roll < 0.65 then
		return snips(e, tRoot), 1
	end
	return cut(e, tRoot), 1.3
end)

return M
