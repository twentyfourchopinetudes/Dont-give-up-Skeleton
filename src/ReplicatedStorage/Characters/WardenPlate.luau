--!nonstrict
-- THE WARDEN, candidate 2: THE HOLLOW PLATE. A huge suit of grey armor with nobody in it. There's a pale wisp where a neck
-- should be, a helm drifting a little above it, and dark chain holding the plates loosely together. Because it's empty it
-- can do what no man in armor can: its fist comes off and flies at you on a chain, and it can fall apart with a crash,
-- slither across the floor as a heap of plates and stand up again under your feet.
-- Phase 1: the haymaker, the two-handed hammer blow, the flying fist, falling apart.
-- Phase 2 at half health: the wisp blazes up. Everything above the hips spins round on a pin, and when it reassembles it
-- throws out a wave. Fight's plumbing: ReplicatedStorage/WardenFight.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fight = require(ReplicatedStorage:WaitForChild("WardenFight"))

local S = 3.9
local M = {}
M.Kind = "WardenPlate"
M.Proportions = { girth = 1.4, arm = 1.25, hunch = 0.1, walkRef = 2.6, cadence = 0.95, elbowOut = 0.35 }
M.IdlePose = "PLIdle"
M.Poses = {
	-- at rest: square and upright, arms hanging heavy and a little out, swaying as if on its chains
	PLIdle = { drop = 0.25, lean = 0.1, head = 0.05, footR = -0.25, footL = 0.3, spread = 0.3, breathe = 1.5, la1 = 0.1, la3 = -0.28, lel = 0.3, freeL = 0.5 },
	-- the haymaker: the whole trunk wound back, the fist drawn behind it
	PLWind = { drop = 0.65, lean = -0.05, twist = -1.15, hip = -0.5, side = -0.1, look = 0.9, footR = -0.8, footL = 0.8, spread = 0.38, breathe = 2, la1 = 0.9, la3 = -0.7, lel = 0.6, freeL = 0 },
	PLThrough = { drop = 1.15, lean = 0.65, twist = 1.05, hip = 0.5, side = 0.14, look = -0.5, footR = 1.0, footL = -0.75, spread = 0.38, la1 = -0.5, la3 = -0.5, lel = 0.5, freeL = 0 },
	-- the hammer: both arms straight up, up on its feet...
	PLOver = { drop = 0, lean = -0.32, head = -0.4, footR = -0.3, footL = 0.35, spread = 0.3, breathe = 2, la1 = 2.9, la3 = -0.15, lel = 0.3, freeL = 0 },
	-- ...and everything down on the blow
	PLHammer = { drop = 1.4, lean = 0.95, head = -0.1, footR = 0.8, footL = -0.65, spread = 0.42, la1 = 1.25, la3 = 0.1, lel = 0.1, freeL = 0 },
	-- sighting along the arm before the fist goes
	PLAim = { drop = 0.45, lean = 0.1, twist = 0.35, look = -0.25, footR = 0.55, footL = -0.65, spread = 0.26, breathe = 2, la1 = -0.2, la3 = -0.6, lel = 0.9, freeL = 0 },
	PLFired = { drop = 0.6, lean = -0.12, twist = -0.3, footR = 0.3, footL = -0.75, spread = 0.26, breathe = 2, la1 = 0.3, la3 = -0.5, lel = 0.5, freeL = 0 },
	-- losing its shape, before it drops: knees going, everything sagging out of true
	PLSag = { drop = 1.3, lean = 0.45, side = 0.22, twist = 0.3, head = 0.55, footR = 0.4, footL = -0.4, spread = 0.45, la1 = -0.1, la3 = -0.6, lel = 0.1, freeL = 0, breathe = 3 },
	-- come together again and straightening up out of the floor
	PLRising = { drop = 1.5, lean = 0.75, head = -0.4, footR = 0.35, footL = -0.4, spread = 0.46, la1 = 0.5, la3 = -1.2, lel = 0.5, freeL = 0 },
	PLSpinSet = { drop = 0.7, twist = -1.45, hip = 0, look = 0.8, footR = -0.25, footL = 0.3, spread = 0.46, la1 = 0.3, la3 = -1.45, lel = 0, breathe = 2, freeL = 0 },
	PLSpin = { drop = 0.7, footR = -0.2, footL = 0.25, spread = 0.46, la1 = 0.1, la3 = -1.5, lel = 0, freeL = 0 },
	-- staggered: slumped forward, chains slack
	PLSlump = { drop = 1.35, lean = 1, side = 0.15, head = 0.6, footR = 0.55, footL = -0.65, spread = 0.42, la1 = -0.25, la3 = -0.3, lel = 0.1, freeL = 0 },
	PLBlaze = { drop = 0.15, lean = -0.4, head = -0.6, footR = 0.4, footL = -0.4, spread = 0.34, la1 = 2.3, la3 = -0.9, lel = 0.4, breathe = 3, freeL = 0 },
}
local STEEL, STEEL_DK, STEEL_LT, VOID, CHAIN, WISP = Color3.fromRGB(116, 120, 126), Color3.fromRGB(76, 80, 86), Color3.fromRGB(150, 154, 160), Color3.fromRGB(10, 10, 14), Color3.fromRGB(36, 36, 40), Color3.fromRGB(196, 226, 232)
M.Colors = { skin = VOID, torso = VOID, legs = VOID, arms = VOID }
M.FistSkin = true

function M.Look(k)
	local deco, parts, V, at, MAT, D, s = k.deco, k.parts, k.V, k.at, k.MAT, k.D, k.s
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local tl, sl = D.thigh / s, D.shin / s
	local BALL = Enum.PartType.Ball
	-- the plates stand a little off the dark body, gaps showing the nothing inside
	deco("Chest", "Breast", V(cw * 1.04, ch * 0.62, 0.3), at(0, ch * 0.16, -cd / 2 - 0.08), STEEL, MAT.Metal)
	deco("Chest", "BreastRidge", V(0.2, ch * 0.62, 0.12), at(0, ch * 0.16, -cd / 2 - 0.27), STEEL_LT, MAT.Metal)
	deco("Chest", "Plackart", V(cw * 0.86, ch * 0.28, 0.24), at(0, -ch * 0.32, -cd / 2 - 0.05), STEEL_DK, MAT.Metal)
	deco("Chest", "Back", V(cw * 1.02, ch * 0.72, 0.26), at(0, ch * 0.08, cd / 2 + 0.08), STEEL_DK, MAT.Metal)
	deco("Chest", "NeckRing", V(cw * 0.5, 0.26, cd * 0.92), at(0, ch / 2 + 0.05, 0), STEEL_DK, MAT.Metal)
	for i = -1, 1 do -- (loose chain, sewn between the plates)
		deco("Chest", "Stitch", V(0.1, 0.46, 0.1), at(i * 0.5, -ch * 0.12, -cd / 2 - 0.22), CHAIN, MAT.DiamondPlate)
		deco("Hips", "Stitch", V(0.1, 0.5, 0.1), at(i * 0.5, 0.48, -hd / 2 - 0.14), CHAIN, MAT.DiamondPlate)
	end
	-- a skirt of steel lames
	for i = 0, 2 do
		deco("Hips", "Lame", V(hw * (1.1 + i * 0.05), 0.3, hd * (1.15 + i * 0.06)), at(0, 0.18 - i * 0.34, 0), i % 2 == 0 and STEEL or STEEL_DK, MAT.Metal)
	end
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		deco(n .. "UpperArm", "Pauldron", V(aw * 1.75, 0.62, aw * 1.75), at(sx * 0.1, ua / 2 - 0.02, 0) * CFrame.Angles(0, 0, -sx * 0.25), STEEL, MAT.Metal)
		deco(n .. "UpperArm", "PauldronLow", V(aw * 1.55, 0.34, aw * 1.55), at(sx * 0.06, ua / 2 - 0.5, 0) * CFrame.Angles(0, 0, -sx * 0.15), STEEL_DK, MAT.Metal)
		deco(n .. "UpperArm", "Rerebrace", V(aw * 1.12, ua * 0.42, aw * 1.12), at(0, -ua * 0.2, 0), STEEL_DK, MAT.Metal)
		deco(n .. "LowerArm", "Couter", V(aw * 1.15, aw * 1.15, aw * 1.15), at(0, la / 2, 0), STEEL, MAT.Metal, BALL)
		deco(n .. "LowerArm", "Vambrace", V(aw * 1.12, la * 0.56, aw * 1.12), at(0, -la * 0.1, 0), STEEL, MAT.Metal)
		deco(n .. "Thigh", "Cuisse", V(lw * 1.14, tl * 0.62, lw * 1.14), at(0, tl * 0.1, 0), STEEL, MAT.Metal)
		deco(n .. "Thigh", "Poleyn", V(lw * 1.1, lw * 1.1, lw * 1.1), at(0, -tl / 2, -0.08), STEEL_LT, MAT.Metal, BALL)
		deco(n .. "Shin", "Greave", V(lw * 1.1, sl * 0.72, lw * 1.1), at(0, -sl * 0.06, 0), STEEL_DK, MAT.Metal)
		deco(n .. "Foot", "Sabaton", V(D.footSize.X / s * 1.12, D.footSize.Y / s * 1.25, D.footSize.Z / s * 1.08), at(0, 0.03, -0.03), STEEL, MAT.Metal)
	end
	deco("LLowerArm", "LeftGauntlet", V(aw * 1.45, 0.95, aw * 1.45), at(0, -la / 2 - 0.25, 0), STEEL, MAT.Metal)
	for _, c in ipairs(parts.Chest.Parent:GetChildren()) do
		if c.Name == "Fist" then -- (the rig's own: the gauntlets stand in for them)
			c.Transparency = 1
		end
	end
	-- no head: a wisp over the neck hole, and a closed helm hanging in the air above it, on nothing
	parts.Head.Transparency = 1
	local wisp = deco("Chest", "Wisp", V(0.72, 0.72, 0.72), at(0, ch / 2 + 0.25, 0), WISP, MAT.Neon, BALL)
	local glow = Instance.new("PointLight")
	glow.Color, glow.Range, glow.Brightness, glow.Shadows = WISP, 34, 1.3, false
	glow.Parent = wisp
	deco("Head", "Helm", V(1.18, 1.0, 1.25), at(0, 0.42, 0), STEEL, MAT.Metal)
	deco("Head", "HelmCrest", V(0.14, 0.42, 1.25), at(0, 1.02, 0), STEEL_LT, MAT.Metal)
	deco("Head", "Visor", V(1.05, 0.34, 0.14), at(0, 0.3, -0.62), STEEL_DK, MAT.Metal)
	deco("Head", "VisorSlit", V(0.86, 0.07, 0.05), at(0, 0.38, -0.7), VOID, MAT.SmoothPlastic)
end

M.Weapons = {
	-- its right fist, the size of a barrel: it's the one thing it swings, and it comes off
	PlateFist = function(w)
		local mk, add = w.mk, w.add
		local steel, dark, chain = Color3.fromRGB(116, 120, 126), Color3.fromRGB(76, 80, 86), Color3.fromRGB(36, 36, 40)
		local handle = mk("Fist", Vector3.new(1.35, 1.4, 1.35), steel, Enum.Material.Metal)
		add(mk("Cuff", Vector3.new(1.6, 0.55, 1.6), dark, Enum.Material.Metal), 0.85)
		for i = -1, 1, 2 do
			add(mk("Knuckle", Vector3.new(0.55, 0.42, 1.55), dark, Enum.Material.Metal), -0.68, CFrame.new(i * 0.32 * w.scale, 0, 0))
		end
		add(mk("Link", Vector3.new(0.3, 0.7, 0.3), chain, Enum.Material.DiamondPlate), 1.3)
		return { handle = handle, bladeLen = 0.8 }
	end,
}
local R = math.rad
M.Grips = {
	PLRest = { Vector3.new(1.9, -0.75, -0.3), CFrame.Angles(R(6), 0, 0) },
	PLBack = { Vector3.new(2.3, 0.2, 2.1), CFrame.Angles(R(-40), 0, R(20)) },
	PLMid = { Vector3.new(0.9, -1.6, -3.0), CFrame.Angles(R(70), 0, 0) },
	PLEnd = { Vector3.new(-2.2, -1.6, -1.2), CFrame.Angles(R(60), R(70), 0) },
	PLHigh = { Vector3.new(0.5, 3.6, -0.1), CFrame.Angles(R(175), 0, 0) },
	PLLow = { Vector3.new(0.3, -2.1, -3.0), CFrame.Angles(R(40), 0, 0) },
	PLAim = { Vector3.new(1.4, 0.9, -3.0), CFrame.Angles(R(90), 0, 0) },
	PLWide = { Vector3.new(3.3, -0.8, 0), CFrame.Angles(0, 0, R(80)) },
	PLSlump = { Vector3.new(1.3, -1.9, -1.2), CFrame.Angles(R(10), 0, 0) },
}
M.BodyFor = {}

---------------------------------------------------------------------------
-- server: the fight
---------------------------------------------------------------------------
function M.init(core)
	local F = Fight.init(core)
	local SOUNDS, playSound, burst, pose, bodyPose, setTrail, dustCloud, flat, now, debrisChunks, FxRemote = core.SOUNDS, core.playSound, core.burst, core.pose, core.bodyPose, core.setTrail, core.dustCloud, core.flat, core.now, core.debrisChunks, core.FxRemote
	local D = { Hay = 22, Hammer = 26, Blast = 14, Fist = 18, Rise = 22, Spin = 20, Wave = 12 }
	local PLATE = Color3.fromRGB(116, 120, 126)
	local WISP = Color3.fromRGB(196, 226, 232)
	local STAND = 3 * S

	local function ahead(b, dist)
		return flat(b.root.Position) + F.fwd(b) * dist
	end

	-- THE HAYMAKER: wound right round, the fist behind it, a long look; then the whole of it behind one blow
	local function haymaker(b, target)
		F.halt(b)
		if not F.beats(b, target, {
			{ "PLBack", "PLWind", 0.6 },
			{ "PLBack", "PLWind", 0.5, function()
				playSound(b.root, SOUNDS.Unsheath, 0.9, 0.42)
			end },
		}, 0.7) then
			return
		end
		setTrail(b, true)
		F.step(b, 10, 0.3)
		bodyPose(b, "PLThrough", 0.2)
		pose(b, "PLMid", 0.15, Enum.EasingStyle.Linear)
		task.delay(0.15, function()
			pose(b, "PLEnd", 0.16)
		end)
		playSound(b.root, SOUNDS.Lunge, 1, 0.45)
		F.sweep(b, 0.32, D.Hay, "Large", {}, 7)
		setTrail(b, false)
		F.recover(b, 1.25, "PLSlump")
	end

	-- THE HAMMER: fist straight up; a ring where it'll land; down it comes, and it's a moment getting it back out of the floor
	local function hammer(b, target)
		F.halt(b)
		if not F.beats(b, target, { { "PLHigh", "PLOver", 0.7 } }, 0.55) then
			return
		end
		local at = ahead(b, 16)
		F.ring(at, 11, 0.8)
		playSound(b.root, SOUNDS.Unsheath, 0.9, 0.4)
		if not F.track(b, target, 0.8, 0) then
			return
		end
		setTrail(b, true)
		F.draw(b, "PLLow", "PLHammer", 0.14)
		playSound(b.root, SOUNDS.Lunge, 1, 0.42)
		if not F.wait(b, 0.14) then
			return
		end
		setTrail(b, false)
		F.quake(b, at, 11, 1.5)
		debrisChunks(at + Vector3.new(0, 0.5, 0), 7, 20)
		F.hit(F.radius(at, 11, 8), {}, D.Hammer, at, "Knockdown")
		F.recover(b, 1.5, false)
	end

	-- THE FIST: sighted along its arm, a strip down the floor, and off it goes on its chain, there and back. It's one-handed
	-- while it's gone: walk in
	local function fist(b, target)
		F.halt(b)
		local copy
		F.setCleanup(function()
			if copy and copy.Parent then
				copy:Destroy()
			end
			if b.model.Parent then
				F.hideWeapon(b, false)
			end
		end)
		if not F.beats(b, target, { { "PLAim", "PLAim", 0.75, function()
			playSound(b.root, SOUNDS.Unsheath, 0.9, 1.1)
		end } }, 0.6) then
			return
		end
		local dir = F.fwd(b)
		local start = Vector3.new(b.root.Position.X, 3.5, b.root.Position.Z) + dir * 8
		local goal = F.clamp(start + dir * 68, 3)
		F.strip(start, goal, 9, 0.55)
		if not F.track(b, target, 0.55, 0) then
			return
		end
		local handle
		copy, handle = F.cloneWeapon(b)
		F.hideWeapon(b, true)
		if not copy then
			return
		end
		bodyPose(b, "PLFired", 0.1)
		playSound(b.root, SOUNDS.Lunge, 1, 0.5)
		FxRemote:FireAllClients("Shake", start, 0.4)
		local chain = F.part({ Name = "FistChain", Size = Vector3.new(0.9, 0.9, 1), Material = Enum.Material.DiamondPlate, Color = Color3.fromRGB(36, 36, 40) })
		local seen, t0 = {}, now()
		local OUT, HOME, WAIT = (goal - start).Magnitude / 62, (goal - start).Magnitude / 44, 0.4
		while F.free(b) do
			task.wait()
			local el, p = now() - t0, nil
			if el < OUT then
				p = start:Lerp(goal, el / OUT)
			elseif el < OUT + WAIT then
				p = goal
				if not seen.stuck then
					seen.stuck = true
					burst(goal, Color3.fromRGB(230, 225, 205), 18, 0.35, 16)
					playSound(handle, SOUNDS.Impact, 0.8, 0.8)
				end
			else
				local a = math.min((el - OUT - WAIT) / HOME, 1)
				p = goal:Lerp(start, a)
				if not seen.back then
					seen = { back = true, stuck = true } -- (it can catch you coming home too)
				end
				if a >= 1 then
					break
				end
			end
			handle.CFrame = CFrame.lookAt(p, p + dir) * CFrame.Angles(math.rad(90), 0, 0)
			chain.Size = Vector3.new(0.9, 0.9, math.max((p - start).Magnitude, 1))
			chain.CFrame = CFrame.lookAt(start:Lerp(p, 0.5), p)
			F.hit(F.radius(p, 5.5, 9), seen, D.Fist, p, "Large")
		end
		if copy.Parent then
			copy:Destroy()
		end
		chain:Destroy()
		F.hideWeapon(b, false)
		F.setCleanup(nil)
		if F.live(b) then
			playSound(b.root, SOUNDS.Impact, 0.6, 1.1)
			F.recover(b, 0.75, "PLIdle")
		end
	end

	-- FALLING APART: everything sags out of true, a shudder; then it collapses with a crash into a heap of loose plates, and the
	-- heap slides at you along the floor. A ring opens where it's going to stand back up. Get out from under it. It takes a
	-- moment to find its feet again, stood right there in the open
	local function scatter(b, target)
		F.halt(b)
		local plates = {}
		F.setCleanup(function()
			for _, p in ipairs(plates) do
				if p.Parent then
					p:Destroy()
				end
			end
			if b.model.Parent then
				F.hideBody(b, false)
			end
		end)
		F.draw(b, "PLSlump", "PLSag", 0.7 * F.tempo())
		playSound(b.root, SOUNDS.Groan, 0.8, 0.55)
		if not F.hold(b, 0.8 * F.tempo()) then
			return
		end
		local root = b.root
		root.Anchored = true
		local c = flat(root.Position)
		F.hideBody(b, true)
		playSound(root, SOUNDS.Impact, 1, 0.7)
		FxRemote:FireAllClients("Shake", c, 0.9)
		dustCloud(c, 4, 12)
		for i = 1, 16 do
			local size = math.random(3, 7)
			local p = F.part({
				Name = "LoosePlate", Size = Vector3.new(size, 0.9, size * 0.8), Material = Enum.Material.Metal, Color = i % 2 == 0 and PLATE or Color3.fromRGB(76, 80, 86),
				CFrame = CFrame.new(c + Vector3.new(math.random(-9, 9), 0.5, math.random(-9, 9))) * CFrame.Angles(math.random() * 0.5, math.random() * 6, math.random() * 0.5),
			})
			table.insert(plates, p)
		end
		if not F.wait(b, 0.5) then
			return
		end
		local tr = target:FindFirstChild("HumanoidRootPart")
		local to = F.clamp(tr and flat(tr.Position) or c, 12)
		F.ring(to, 12, 1.5)
		playSound(root, SOUNDS.Unsheath, 0.9, 0.35)
		local from = {}
		for i, p in ipairs(plates) do
			from[i] = p.Position
		end
		local t0 = now()
		while F.live(b) do
			local t = math.min((now() - t0) / 1.5, 1)
			local e = t * t * (3 - 2 * t)
			for i, p in ipairs(plates) do
				local g = to + (from[i] - c) * 0.6 * (1 - e)
				p.CFrame = CFrame.new(from[i]:Lerp(g, e) + Vector3.new(0, 0.4 + math.abs(math.sin(t * 16 + i)) * 0.9, 0)) * p.CFrame.Rotation
			end
			if t >= 1 then
				break
			end
			task.wait()
		end
		if not F.live(b) then
			return
		end
		for _, p in ipairs(plates) do
			p:Destroy()
		end
		plates = {}
		root.CFrame = CFrame.new(to.X, STAND, to.Z) * root.CFrame.Rotation
		bodyPose(b, "PLRising", 0.05)
		F.hideBody(b, false)
		F.setCleanup(nil)
		F.quake(b, to, 12, 1.5)
		debrisChunks(to + Vector3.new(0, 0.5, 0), 7, 22)
		F.hit(F.radius(to, 12, 8), {}, D.Rise, to, "Knockdown")
		if F.phase2() then
			F.wave(b, to, 24, 56, D.Wave, "Medium")
		end
		root.Anchored = false
		F.recover(b, 1.7, false)
	end

	-- THE PIN (phase 2): nobody's inside, so nothing stops it: fist flung out wide, then it all goes round and round at the hips
	local function spin(b, target)
		F.halt(b)
		if not F.beats(b, target, { { "PLWide", "PLSpinSet", 0.95, function()
			playSound(b.root, SOUNDS.Unsheath, 0.9, 0.38)
		end } }, 0.5) then
			return
		end
		F.ring(flat(b.root.Position), 22, 0.45)
		if not F.track(b, target, 0.45, 0) then
			return
		end
		local root = b.root
		root.Anchored = true
		setTrail(b, true)
		bodyPose(b, "PLSpin", 0.12)
		playSound(root, SOUNDS.Lunge, 1, 0.42)
		local base, seen, t0 = root.CFrame, {}, now()
		local DUR, TURNS = 1.15, 2
		while F.free(b) do
			local t = math.min((now() - t0) / DUR, 1)
			root.CFrame = base * CFrame.Angles(0, -t * TURNS * 2 * math.pi, 0)
			if math.floor(t * TURNS * 2) ~= (seen.half or 0) then
				seen = { half = math.floor(t * TURNS * 2) } -- (once per half turn, at most)
				playSound(root, SOUNDS.Lunge, 0.7, 0.5)
			end
			F.hit(F.radius(flat(root.Position), 20, 8), seen, D.Spin, root.Position, "Large")
			if t >= 1 then
				break
			end
			task.wait()
		end
		setTrail(b, false)
		root.Anchored = false
		F.recover(b, 1.6, "PLSlump")
	end

	Fight.define({
		id = "Plate",
		label = "The Hollow Plate",
		kind = M.Kind,
		scale = S,
		weapon = "PlateFist",
		idleGrip = "PLRest",
		hp = 820,
		poise = 170,
		stagger = 2.8,
		radius = 4.8,
		walk = 10,
		turn = 75,
		rest = { 0.6, 1.3 },
		keep = { 16, 26 },
		phase2At = 0.5,
		tempo2 = 0.9,
		restMult2 = 0.75,
		moves = {
			{ name = "Haymaker", fn = haymaker, min = 0, max = 27, weight = 5, cd = 2.5, fast = true },
			{ name = "Hammer", fn = hammer, min = 5, max = 28, weight = 5, cd = 4 },
			{ name = "Fist", fn = fist, min = 22, max = 95, weight = 5, cd = 5 },
			{ name = "Scatter", fn = scatter, min = 0, max = 95, weight = 2.5, cd = 13, behind = true },
			{ name = "Spin", fn = spin, min = 0, max = 22, weight = 5, cd = 8, phase2 = true, behind = true },
		},
		idle = function(b)
			pose(b, "PLRest", 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			bodyPose(b, "PLIdle", 0.6)
		end,
		onStagger = function(b)
			pose(b, "PLSlump", 0.2)
			bodyPose(b, "PLSlump", 0.2)
			playSound(b.root, SOUNDS.Impact, 0.7, 0.9)
		end,
		-- the entrance: a heap of plates at the far end. It rattles, stands up, and the wisp lights
		intro = function(b)
			local root = b.root
			F.hideBody(b, true)
			local c = flat(root.Position)
			local heap = {}
			for i = 1, 16 do
				local size = math.random(3, 7)
				table.insert(heap, F.part({ Name = "LoosePlate", Size = Vector3.new(size, 0.9, size * 0.8), Material = Enum.Material.Metal, Color = i % 2 == 0 and PLATE or Color3.fromRGB(76, 80, 86), CFrame = CFrame.new(c + Vector3.new(math.random(-8, 8), 0.6, math.random(-8, 8))) * CFrame.Angles(math.random() * 0.5, math.random() * 6, math.random() * 0.5) }))
			end
			task.wait(0.7)
			playSound(root, SOUNDS.Unsheath, 1, 0.4)
			FxRemote:FireAllClients("Shake", c, 0.5)
			task.wait(0.9)
			for _, p in ipairs(heap) do
				p:Destroy()
			end
			pose(b, "PLSlump", 0.05)
			bodyPose(b, "PLRising", 0.05)
			F.hideBody(b, false)
			dustCloud(c, 4, 12)
			playSound(root, SOUNDS.Impact, 1, 0.7)
			task.wait(0.35)
			bodyPose(b, "PLBlaze", 0.9)
			playSound(root, SOUNDS.Groan, 1, 0.5)
			task.wait(1)
			bodyPose(b, "PLIdle", 0.5)
			task.wait(0.3)
		end,
		-- phase 2: the wisp blazes up
		phase2 = function(b)
			F.halt(b)
			F.draw(b, "PLHigh", "PLBlaze", 0.5)
			playSound(b.root, SOUNDS.Groan, 1, 0.42)
			FxRemote:FireAllClients("Shake", b.root.Position, 0.8)
			local wisp = b.model:FindFirstChild("Wisp")
			if wisp then
				wisp.Size *= 1.7
				local light = wisp:FindFirstChildOfClass("PointLight")
				if light then
					light.Brightness = 2.4
				end
				local f = Instance.new("Fire")
				f.Size, f.Heat, f.Color, f.SecondaryColor = 14, 12, WISP, Color3.fromRGB(70, 96, 110)
				f.Parent = wisp
				burst(wisp.Position, WISP, 40, 0.6, 22)
			end
			F.wait(b, 1)
			F.wave(b, flat(b.root.Position), 24, 56, D.Wave, "Medium")
			F.wait(b, 0.5)
			F.idle(b)
		end,
	})
end

return M
