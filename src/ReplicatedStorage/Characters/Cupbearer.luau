--!nonstrict
-- THE CUPBEARER (kind Cupbearer): the king's taster, who has tasted everything, and all of it's still in there. Bloated under a tight jade
-- doublet, its veins standing dark green, its head tipped back, a mouth stained black; a gold ewer in its fist, a towel over its arm.
--   A Toast     the ewer swung over and thrown from the shoulder: a long arc of green wine that splashes and pools where it lands
--   The Tasting it drinks. Then it breathes it back out at you, a short green gout
--   Ewer        close to, it just hits you with the jug
local K = require(script.Parent.Parent:WaitForChild("GildedKit"))
local Config = require(script.Parent.Parent:WaitForChild("Config"))
local M = K.wrap({
	Poses = {
		CBBLoll = { drop = 0.2, lean = -0.12, side = 0.05, head = -0.28, spread = 0.2, footR = -0.2, footL = 0.25, breathe = 1.6, la1 = 0.3, la3 = -0.3, lel = 1.2, freeL = 0 },
		CBBDrink = { drop = 0.3, lean = -0.4, head = -0.85, spread = 0.2, footR = -0.3, footL = 0.3, breathe = 4, la1 = 0.3, la3 = -0.3, lel = 1.2, freeL = 0 },
	},
	Grips = {
		CBHold = { Vector3.new(1.3, -0.1, -0.8), CFrame.Angles(math.rad(35), 0, 0) },
		CBDrink = { Vector3.new(0.4, 2.5, -0.9), CFrame.Angles(math.rad(205), 0, 0) },
	},
})
M.Kind = "Cupbearer"
M.Proportions = { girth = 1.28, arm = 0.95, hunch = 0.05 }
M.IdlePose = "CBBLoll"
M.BodyFor = { CBHold = "CBBLoll" }
local DOUBLET, DOUBLET_LT, SKIN, BILE, WINE = K.JADE, Color3.fromRGB(40, 150, 124), Color3.fromRGB(170, 176, 138), Color3.fromRGB(150, 178, 70), Color3.fromRGB(96, 150, 50)
M.Colors = { skin = SKIN, torso = DOUBLET, legs = Color3.fromRGB(26, 70, 62), arms = DOUBLET }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local rng = Random.new()
	local ball = Enum.PartType.Ball
	-- a swollen face, its throat bulging; a black mouth hanging open, running green; a jewelled cap
	deco("Head", "Jowl", V(1.3, 0.72, 1.15), at(0, -0.42, -0.05), SKIN, MAT.SmoothPlastic, ball)
	deco("Head", "Mouth", V(0.5, 0.36, 0.08), at(0, -0.42, -0.6), rgb(8, 10, 6), MAT.SmoothPlastic)
	deco("Head", "MouthGlow", V(0.32, 0.12, 0.04), at(0, -0.49, -0.64), BILE, MAT.Neon)
	deco("Head", "Spill", V(0.14, 0.72, 0.05), at(0.08, -0.82, -0.58), BILE, MAT.Neon)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "Eye", V(0.28, 0.14, 0.06), at(sx * 0.26, 0.12, -0.58), rgb(230, 224, 160), MAT.SmoothPlastic)
		deco("Head", "Pupil", V(0.07, 0.07, 0.04), at(sx * 0.26, 0.11, -0.62), rgb(8, 10, 6), MAT.SmoothPlastic)
		for i = 0, 2 do
			deco("Head", "Vein", V(0.03, 0.34, 0.03), at(sx * (0.34 + i * 0.05), -0.08 - i * 0.14, -0.55) * CFrame.Angles(0, 0, sx * (0.3 + i * 0.3)), rgb(60, 90, 40), MAT.SmoothPlastic)
		end
	end
	deco("Head", "Cap", V(1.26, 0.45, 1.26), at(0, 0.62, 0.06), DOUBLET, MAT.Fabric)
	deco("Head", "CapBand", V(1.32, 0.14, 1.32), at(0, 0.46, 0.06), K.GOLD, MAT.Metal)
	deco("Head", "CapJewel", V(0.22, 0.22, 0.08), at(0, 0.5, -0.64), K.ROSE, MAT.Glass, ball)
	-- THE BELLY, tight in the jade doublet, its buttons straining; a towel over one arm; a chain of tiny tasting spoons
	deco("Chest", "Belly", V(cw * 1.12, ch * 1.2, cd * 1.55), at(0, -0.22, -0.18), DOUBLET, MAT.Fabric, ball)
	for i = 0, 4 do
		deco("Chest", "Button", V(0.14, 0.14, 0.06), at(0, ch * (0.35 - i * 0.22), -cd * 0.93 + math.abs(i - 2) * 0.1), K.GOLD, MAT.Metal, ball)
	end
	for _, sx in ipairs({ -1, 1 }) do
		deco("Chest", "Slash", V(0.16, ch * 0.72, 0.05), at(sx * cw * 0.24, 0.05, -cd * 0.8) * CFrame.Angles(0, sx * 0.3, 0), DOUBLET_LT, MAT.Fabric)
	end
	for i = 0, 5 do
		local a = i / 5 * math.pi
		deco("Chest", "SpoonChain", V(0.08, 0.08, 0.08), at(math.cos(a) * cw * 0.32, ch * 0.42 - math.sin(a) * 0.5, -cd * 0.72), K.GOLD, MAT.Metal, ball)
	end
	deco("Chest", "Spoon", V(0.14, 0.42, 0.06), at(0, ch * 0.42 - 0.72, -cd * 0.95), K.LIGHT, MAT.Metal)
	-- green stains down its front
	for _ = 1, 5 do
		local h = rng:NextNumber(0.3, 0.9)
		deco("Chest", "Stain", V(rng:NextNumber(0.1, 0.24), h, 0.04), at(rng:NextNumber(-0.25, 0.25) * cw, ch * 0.25 - h / 2, -cd * 0.92), BILE, MAT.SmoothPlastic).Transparency = 0.2
	end
	deco("Hips", "Trunks", V(hw * 1.35, 1.25, hd * 1.45), at(0, -0.35, 0), Color3.fromRGB(26, 70, 62), MAT.Fabric, ball)
	deco("Hips", "Belt", V(hw * 1.35, 0.22, hd * 1.4), at(0, 0.32, 0), K.GOLD, MAT.Metal)
	deco("LUpperArm", "Towel", V(aw * 1.45, ua * 0.55, aw * 1.45), at(0, 0, 0), K.PORCELAIN, MAT.Fabric)
	deco("LLowerArm", "TowelFall", V(aw * 1.15, la * 1.05, 0.08), at(0, -la * 0.2, aw * 0.55), K.PORCELAIN, MAT.Fabric)
	for _, n in ipairs({ "R", "L" }) do
		deco(n .. "UpperArm", "Puff", V(aw * 1.5, ua * 0.5, aw * 1.5), at(0, ua * 0.2, 0), DOUBLET_LT, MAT.Fabric, ball)
		deco(n .. "LowerArm", "Bare", V(aw * 1.05, la * 0.7, aw * 1.05), at(0, -la * 0.15, 0), SKIN, MAT.SmoothPlastic)
		deco(n .. "Foot", "Shoe", V(0.68, 0.26, 1.12), at(0, 0, -0.05), K.GOLD, MAT.Metal)
		deco(n .. "Shin", "Hose", V(lw * 1.02, 1.05, lw * 1.02), at(0, 0, 0), SKIN, MAT.SmoothPlastic)
	end
end

M.Weapons = {
	-- a gold ewer: a tall belly, a long spout, a handle; a green slop in its neck
	GoldEwer = function(w)
		local gold = K.GOLD
		local handle = w.mk("Grip", Vector3.new(0.24, 0.8, 0.24), gold, Enum.Material.Metal)
		w.add(w.mk("Neck", Vector3.new(0.46, 0.6, 0.46), gold, Enum.Material.Metal), -0.75)
		local b = w.mk("Belly", Vector3.new(1.3, 1.65, 1.3), gold, Enum.Material.Metal)
		b.Shape = Enum.PartType.Ball
		w.add(b, -1.6)
		w.add(w.mk("Band", Vector3.new(1.34, 0.14, 1.34), K.ROSE, Enum.Material.Metal), -1.6)
		w.add(w.mk("Foot", Vector3.new(0.84, 0.18, 0.84), K.TARNISH, Enum.Material.Metal), -2.5)
		local mouth = w.mk("EwerMouth", Vector3.new(0.3, 0.3, 0.3), BILE, Enum.Material.Neon)
		w.add(mouth, -0.45, nil, -0.22)
		w.add(w.mk("Spout", Vector3.new(0.2, 1.3, 0.2), gold, Enum.Material.Metal), -1.1, CFrame.Angles(math.rad(-30), 0, 0), -0.72)
		return { handle = handle, bladeLen = 2.5 }
	end,
}

M.Def = K.def({
	HP = 410, Speed = 8.5, Scale = 1.3, Damage = 34, Range = 7.5, HalfAngle = 60, Lunge = 6, Poise = 55, Stagger = 0.55, StaggerPush = 12,
	Windup = 0.8, Recover = 1.1, Engage = 24, Close = 7, Weapon = "GoldEwer", IdleGrip = "CBHold", Radius = 1.9, Skin = SKIN, Cloth = DOUBLET,
})

local function pool(pos)
	K.cloud(pos, { radius = 6.5, life = 5, color = WINE, rate = 32, poison = Config.Usher.Poison })
end
local function toast(e, tRoot)
	K.setGrip(e, "GToss", 0.5)
	K.setBody(e, "GBSet", 0.5)
	if not K.hold(e, 0.8, tRoot) then
		return false
	end
	K.setGrip(e, "GTossed", 0.14)
	K.setBody(e, "GBFling", 0.14)
	task.wait(0.1)
	if not e.alive then
		return false
	end
	local from = K.hand(e) + Vector3.new(0, 1, 0)
	-- thrown up in an arc to land about where you are: flight time from how far
	local to = tRoot.Position - Vector3.new(0, 2.6, 0)
	local T = math.clamp((to - from).Magnitude / 34, 0.45, 1.1)
	local G = 70
	local vel = (to - from) / T + Vector3.new(0, 0.5 * G * T, 0)
	K.shot(e, { from = from, vel = vel, gravity = G, damage = 18, level = "Medium", radius = 2, life = 3, size = Vector3.new(1.4, 1.4, 1.4), color = BILE, material = Enum.Material.Neon, trail = WINE, onLand = pool })
	K.sound(e, "Lunge", 0.7, 1.2)
	return true
end
local function tasting(e, tRoot)
	K.setGrip(e, "CBDrink", 0.4)
	return K.breath(e, tRoot, {
		part = K.partOf(e, "MouthGlow"), setBody = "CBBDrink", draw = 1.15, time = 1.25, reach = 12, half = 22, damage = 9, tick = 0.3, poison = Config.Usher.Poison,
		c0 = Color3.fromRGB(200, 220, 110), c1 = BILE, c2 = Color3.fromRGB(44, 64, 20), glow = 0.3, spread = 5, pitch = 0.7,
	})
end

M.attack = K.brain(function(e, tRoot, d)
	if d > 9 then
		return toast(e, tRoot), 1
	elseif d > 7 or math.random() < 0.45 then
		return tasting(e, tRoot), 1.2
	end
	return K.strike(e, tRoot, { set = "GCock", setBody = "GBSet", tell = 0.7, swing = "GCut", swingBody = "GBStrike", time = 0.14, range = 7.5, half = 60, damage = 36, speed = 0.8 }), 1
end)

return M
