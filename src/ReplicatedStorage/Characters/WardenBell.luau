--!nonstrict
-- THE WARDEN, candidate 4: THE BELLHEAD. The prison's bell-ringer for so long that the bell has grown down over its shoulders: a
-- huge robed figure with an old green-iron bell where its head should be, and in both hands the bell's own clapper, as long as
-- it's tall. It keeps the prison's hours, and everything it does is in time. It strikes its own head and the note rolls out
-- across the floor as a wall you have to roll through: beat, beat, beat. Learn the count and you can walk right up to it.
-- Phase 1: the toll (one note, then three), the clapper swung low, the clapper brought down, and the bell itself thrown forward.
-- Phase 2 at half health: the bell cracks. Notes come faster and in pairs, and every toll now calls down a ring under your feet.
-- Fight's plumbing: ReplicatedStorage/WardenFight.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fight = require(ReplicatedStorage:WaitForChild("WardenFight"))
local Garb = require(ReplicatedStorage:WaitForChild("WardenGarb"))

local S = 3.7
local M = {}
M.Kind = "WardenBell"
M.Proportions = { girth = 1.35, arm = 1.25, hunch = 0.2, twoHand = -0.9, walkRef = 2.6, cadence = 0.85 }
M.IdlePose = "BLIdle"
M.Poses = {
	-- at rest: weighed down by its own head, leaning on the clapper
	BLIdle = { drop = 0.35, lean = 0.22, head = 0.3, footR = -0.28, footL = 0.32, spread = 0.26, breathe = 3, freeL = 0 },
	-- the clapper drawn back, rearing the bell away from the blow
	BLDraw = { drop = 0.25, lean = -0.22, twist = -0.55, hip = -0.2, head = -0.2, side = -0.1, footR = -0.55, footL = 0.5, spread = 0.28, breathe = 4, freeL = 0 },
	-- striking its own head, and everything shaken by it
	BLStrike = { drop = 0.7, lean = 0.35, twist = 0.4, head = 0.5, side = 0.14, footR = 0.45, footL = -0.4, spread = 0.34, breathe = 5, freeL = 0 },
	-- reeling from the note
	BLReel = { drop = 0.6, lean = 0.5, side = -0.14, head = 0.55, footR = 0.2, footL = -0.35, spread = 0.36, breathe = 6, freeL = 0 },
	-- the low swing
	BLWind = { drop = 0.75, lean = 0.2, twist = -1.2, hip = -0.55, side = -0.1, look = 0.95, head = 0.05, footR = -0.7, footL = 0.75, spread = 0.4, breathe = 4, freeL = 0 },
	BLThrough = { drop = 0.95, lean = 0.55, twist = 1.1, hip = 0.55, side = 0.12, look = -0.5, head = 0.1, footR = 0.85, footL = -0.6, spread = 0.4, freeL = 0 },
	-- overhead, then folded down after it
	BLHigh = { drop = 0.05, lean = -0.38, head = -0.3, footR = -0.4, footL = 0.42, spread = 0.28, breathe = 4, freeL = 0 },
	BLFold = { drop = 1.3, lean = 1, head = 0.15, footR = 0.8, footL = -0.7, spread = 0.38, freeL = 0 },
	-- THE BELL DROPPED: rocked back, then the whole top of it thrown down forward, mouth first
	BLRock = { drop = 0.2, lean = -0.55, head = -0.5, footR = -0.55, footL = 0.45, spread = 0.3, la1 = 1, la3 = -0.8, lel = 0.5, breathe = 5, freeL = 0 },
	BLHeadlong = { drop = 1.7, lean = 1.4, head = 0.35, footR = 0.9, footL = -1.2, spread = 0.4, la1 = -0.5, la3 = -0.8, lel = 0.1, breathe = 7, freeL = 0 },
	BLDazed = { drop = 1.5, lean = 0.55, side = 0.16, head = 0.6, footR = 0.9, footL = -1.2, spread = 0.36, la1 = -0.2, la3 = -0.5, lel = 0.2, breathe = 7, freeL = 0 },
	BLCracked = { drop = 0.3, lean = -0.3, side = 0.18, head = -0.45, footR = 0.3, footL = -0.45, spread = 0.36, breathe = 6, freeL = 0 },
}
local ROBE, ROBE_DK, BELL, BELL_DK, BELL_LT, ROPE = Color3.fromRGB(84, 76, 66), Color3.fromRGB(52, 46, 40), Color3.fromRGB(88, 116, 100), Color3.fromRGB(56, 76, 66), Color3.fromRGB(128, 156, 136), Color3.fromRGB(128, 112, 82)
M.Colors = { skin = ROBE_DK, torso = ROBE, legs = ROBE_DK, arms = ROBE }
M.FistSkin = true

-- everything below the head, in its own colours or these
function M.LookRobe(k, robe, dark)
	local D, MAT, s = k.D, k.MAT, k.s
	local cw, ch, cd, hw, hd, aw, la, ua, lw = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.la, k.ua, k.lw
	local ROBE, ROBE_DK = robe or ROBE, dark or ROBE_DK
	local rng = Random.new(414)
	Garb.sink(k, { "Chest", "Hips", "RUpperArm", "LUpperArm", "RLowerArm", "LLowerArm", "RThigh", "LThigh", "RShin", "LShin", "RFoot", "LFoot" }, 0.8, ROBE_DK)
	Garb.hideRigFists(k)
	-- the robe: three overlapping tiers of folds round the chest, more round the hips, a mantle of them over the shoulders
	Garb.shell(k, "Chest", rng, { a = cw * 0.68, c = cd * 0.76, top = ch / 2 + 0.05, bottom = -ch / 2 - 0.1, n = 20, tiers = 3, color = ROBE, dark = ROBE_DK })
	Garb.shell(k, "Chest", rng, { a = cw * 0.58, c = cd * 0.62, top = ch / 2 + 0.34, bottom = ch / 2 - 0.1, n = 16, tiers = 1, color = ROBE, dark = ROBE_DK, flare = 0.75, name = "Mantle" })
	local hipY = D.hipsSize.Y / s
	Garb.shell(k, "Hips", rng, { a = hw * 0.72, c = hd * 0.8, top = hipY / 2 + 0.05, bottom = -hipY / 2 - 0.25, n = 16, tiers = 2, color = ROBE, dark = ROBE_DK, flare = 0.14 })
	Garb.skirt(k, "Hips", rng, { a = hw * 0.74, c = hd * 0.84, y = -hipY / 2, n = 14, len = 0.56, color = ROBE, dark = ROBE_DK })
	-- a bell-rope wound round the waist
	for i = 0, 2 do
		Garb.hoop(k, "Hips", 0.34 - i * 0.14, hw * 0.78 + i * 0.015, hd * 0.86 + i * 0.015, 18, 0.14, ROPE:Lerp(ROBE_DK, i * 0.12), MAT.Fabric, "Rope")
	end
	for _, n in ipairs({ "R", "L" }) do
		Garb.shell(k, n .. "UpperArm", rng, { a = aw * 0.82, c = aw * 0.82, top = ua / 2 + 0.05, bottom = -ua / 2, n = 9, tiers = 2, color = ROBE, dark = ROBE_DK })
		Garb.shell(k, n .. "LowerArm", rng, { a = aw * 0.84, c = aw * 0.84, top = la / 2 + 0.05, bottom = -la / 2 + 0.05, n = 9, tiers = 2, color = ROBE, dark = ROBE_DK, flare = 0.2 })
		Garb.hoop(k, n .. "LowerArm", -la / 2 + 0.1, aw * 0.92, aw * 0.92, 10, 0.1, ROPE, MAT.Fabric, "Cuff")
		Garb.fist(k, n .. "LowerArm", -la / 2 - 0.12, aw * 1.05, ROPE, ROBE_DK)
		Garb.wraps(k, n .. "Thigh", rng, D.thigh / s / 2, -D.thigh / s / 2, lw * 0.56, 6, ROBE_DK, ROBE, MAT.Fabric)
		Garb.wraps(k, n .. "Shin", rng, D.shin / s / 2, -D.shin / s / 2, lw * 0.5, 7, ROPE:Lerp(ROBE_DK, 0.6), ROBE_DK, MAT.Fabric)
		Garb.foot(k, n .. "Foot", D.footSize / s, ROBE_DK, ROPE:Lerp(ROBE_DK, 0.5))
	end
end

-- A BELL, as a founder casts one (height above its middle, radius). The lip flares out thick and the waist draws in, then the
-- shoulder rounds over to a flat crown
local PROFILE = { { -1.08, 1.8 }, { -1.0, 1.78 }, { -0.92, 1.66 }, { -0.8, 1.48 }, { -0.62, 1.28 }, { -0.38, 1.13 }, { -0.1, 1.04 }, { 0.25, 0.99 }, { 0.58, 0.98 }, { 0.78, 0.93 }, { 0.92, 0.8 }, { 1.03, 0.58 }, { 1.09, 0.3 } }
function M.bellRadius(y)
	for i = 1, #PROFILE - 1 do
		local a, z = PROFILE[i], PROFILE[i + 1]
		if y <= z[1] then
			return a[2] + (z[2] - a[2]) * math.clamp((y - a[1]) / (z[1] - a[1]), 0, 1)
		end
	end
	return PROFILE[#PROFILE][2]
end

-- what a bell hangs by: cast loops on the crown, and the timber headstock through them
function M.bellHanger(k, iron, dark)
	local deco, V, at, MAT = k.deco, k.V, k.at, k.MAT
	for i = 0, 5 do
		local a = i / 6 * 2 * math.pi
		deco("Head", "Canon", V(0.34, 0.15, 0.15), at(math.sin(a) * 0.17, 1.22, math.cos(a) * 0.17) * CFrame.Angles(0, a, 0) * CFrame.Angles(0, 0, 1.25), iron, MAT.Metal, Enum.PartType.Cylinder)
	end
	deco("Head", "Headstock", V(1.7, 0.3, 0.3), at(0, 1.42, 0), Color3.fromRGB(70, 52, 38), MAT.WoodPlanks, Enum.PartType.Cylinder)
	for _, x in ipairs({ -0.62, -0.3, 0.3, 0.62 }) do
		deco("Head", "HeadstockBand", V(0.08, 0.34, 0.34), at(x, 1.42, 0), dark, MAT.Metal, Enum.PartType.Cylinder)
	end
end

-- THE BELL, where its head would be, its mouth down over its shoulders. pal (optional) recasts it: main, dark, light, streak, glow
function M.LookBell(k, pal)
	pal = pal or {}
	local BELL, BELL_DK, BELL_LT = pal.main or BELL, pal.dark or BELL_DK, pal.light or BELL_LT
	local deco, parts, V, at, MAT = k.deco, k.parts, k.V, k.at, k.MAT
	local rng = Random.new(1612)
	local radius = M.bellRadius
	parts.Head.Transparency = 1
	local function cast()
		return BELL:Lerp(BELL_DK, rng:NextNumber() ^ 1.3)
	end
	-- the flare is left hollow (from below, where you're standing, you look up into it): a ring of curved plates, row on row
	local rows = { -1.08, -0.98, -0.88, -0.76, -0.62 }
	local N = 26
	for r = 1, #rows - 1 do
		local y0, y1 = rows[r], rows[r + 1]
		local r0, r1 = radius(y0), radius(y1)
		local rm, ym = (r0 + r1) / 2, (y0 + y1) / 2
		local slope = math.atan2(r0 - r1, y1 - y0)
		local long = math.sqrt((r0 - r1) ^ 2 + (y1 - y0) ^ 2)
		for i = 0, N - 1 do
			local a = (i + (r % 2) * 0.5) / N * 2 * math.pi
			deco("Head", "BellLip", V(2 * math.pi * rm / N * 1.16, long * 1.1, 0.14), at(math.sin(a) * rm, ym, math.cos(a) * rm) * CFrame.Angles(0, a, 0) * CFrame.Angles(-slope, 0, 0), cast(), MAT.Metal)
		end
	end
	Garb.hoop(k, "Head", -1.07, radius(-1.07) + 0.03, radius(-1.07) + 0.03, 26, 0.13, BELL_LT, MAT.Metal, "BellRim")
	-- the dark up inside it
	Garb.disc(k, "Head", -0.66, radius(-0.66) - 0.04, 0.06, Color3.fromRGB(6, 8, 8), MAT.SmoothPlastic, "BellMouth")
	-- the rest of it, cast solid: thin slices following the profile
	local y = -0.62
	while y < 1.09 do
		Garb.disc(k, "Head", y, radius(y), 0.075, cast(), MAT.Metal, "BellBody")
		y += 0.058
	end
	-- the founder's raised bands, and a line of worn lettering between the pair of them up by the shoulder
	for _, by in ipairs({ -0.5, -0.43, 0.38, 0.62 }) do
		Garb.disc(k, "Head", by, radius(by) + 0.035, 0.045, BELL_LT, MAT.Metal, "BellBand")
	end
	for i = 0, 21 do
		local a = i / 22 * 2 * math.pi
		local r = radius(0.5) + 0.012
		deco("Head", "BellLetter", V(0.07 + (i % 3) * 0.03, 0.09 + (i % 2) * 0.04, 0.03), at(math.sin(a) * r, 0.5, math.cos(a) * r) * CFrame.Angles(0, a, 0), BELL_DK, MAT.Metal)
	end
	-- verdigris run down from the bands
	for i = 0, 15 do
		local a = rng:NextNumber() * 2 * math.pi
		local top = rng:NextNumber() < 0.5 and 0.34 or -0.54
		local long = rng:NextNumber(0.12, 0.3)
		local my = top - long / 2
		local r = radius(my) + 0.012
		deco("Head", "Verdigris", V(rng:NextNumber(0.05, 0.11), long, 0.02), at(math.sin(a) * r, my, math.cos(a) * r) * CFrame.Angles(0, a, 0) * CFrame.Angles(-math.atan2(radius(my - 0.05) - radius(my + 0.05), 0.1), 0, 0), pal.streak or BELL_LT:Lerp(Color3.fromRGB(150, 196, 174), 0.5), MAT.SmoothPlastic)
	end
	M.bellHanger(k, BELL_LT, BELL_DK)
	-- cold light in there
	local pall = Instance.new("PointLight")
	pall.Color, pall.Range, pall.Brightness, pall.Shadows = pal.glow or Color3.fromRGB(190, 220, 200), 34, 1.1, false
	pall.Parent = parts.Chest
	-- the crack (hidden till phase 2), running up its front
	for i, q in ipairs({ { 0.2, 0.55, 0.12 }, { 0.32, 0.15, -0.35 }, { 0.5, -0.25, 0.3 }, { 0.42, -0.62, -0.2 } }) do
		local r = radius(q[2])
		local c = deco("Head", "BellCrack", V(0.1, 0.5, 0.06), at(q[1], q[2], -math.sqrt(r * r - q[1] * q[1]) - 0.02) * CFrame.Angles(0, 0, q[3]), Color3.fromRGB(210, 236, 224), MAT.Neon)
		c.Transparency = 1
		c:SetAttribute("Order", i)
	end
end

function M.Look(k)
	M.LookRobe(k)
	M.LookBell(k)
end

M.Weapons = {
	-- the bell's clapper: a long forged iron rod, its leather strap at the hands, a great iron ball at the end
	Clapper = function(w)
		local mk, add = w.mk, w.add
		local iron, dark, strap = Color3.fromRGB(76, 88, 80), Color3.fromRGB(44, 52, 48), Color3.fromRGB(84, 60, 40)
		local function rod(name, y, long, d, color, mat)
			local p = mk(name, Vector3.new(long, d, d), color, mat or Enum.Material.Metal)
			p.Shape = Enum.PartType.Cylinder
			add(p, y, Garb.UP)
		end
		local handle = mk("Rod", Vector3.new(0.2, 3, 0.2), iron, Enum.Material.Metal)
		handle.Transparency = 1
		rod("RodCore", 0, 3, 0.36, iron)
		rod("Rod2", -2.6, 2.6, 0.4, iron)
		for i = 0, 6 do
			rod("Forged", -1.1 - i * 0.48, 0.14, 0.52 + (i % 2) * 0.05, dark)
		end
		for i = 0, 5 do
			rod("Strap", 0.95 - i * 0.24, 0.2, 0.46 + (i % 2) * 0.04, strap, Enum.Material.Leather)
		end
		rod("Loop", 1.5, 0.3, 0.72, dark)
		local ball = mk("Ball", Vector3.new(1.75, 1.75, 1.75), dark, Enum.Material.Metal)
		ball.Shape = Enum.PartType.Ball
		add(ball, -4.45)
		rod("BallBand", -4.45, 0.16, 1.82, iron)
		rod("BallNeck", -3.6, 0.3, 0.72, iron)
		for i = 0, 7 do
			local a = i / 8 * 2 * math.pi
			local stud = mk("BallStud", Vector3.new(0.22, 0.22, 0.22), iron, Enum.Material.Metal)
			stud.Shape = Enum.PartType.Ball
			add(stud, -4.45, CFrame.new(math.cos(a) * 0.9 * w.scale, 0, math.sin(a) * 0.9 * w.scale))
		end
		return { handle = handle, bladeLen = 4.6, gripC1 = CFrame.new(0, 0.5 * w.scale, 0) }
	end,
}
local R = math.rad
local function out(yaw, tilt)
	return CFrame.Angles(0, R(yaw), 0) * CFrame.Angles(0, 0, R(tilt))
end
M.Grips = {
	BLRest = { Vector3.new(1.1, -0.2, -1.3), CFrame.Angles(R(10), 0, 0) },
	-- drawn back beside the bell, ball behind it
	BLDraw = { Vector3.new(2.2, 2.5, 0.9), out(-25, 110) },
	-- ...and into the side of its own head
	BLStrike = { Vector3.new(2.6, 2.0, -1.5), out(165, 88) },
	BLWind = { Vector3.new(2.1, -0.2, 1.8), out(-65, 64) },
	BLMid = { Vector3.new(0.3, -0.5, -2.7), out(90, 60) },
	BLEnd = { Vector3.new(-2.1, -0.5, -0.6), out(190, 60) },
	BLHigh = { Vector3.new(0.5, 3.1, 0.3), CFrame.Angles(R(205), 0, 0) },
	BLDown = { Vector3.new(0.2, -0.4, -2.5), CFrame.Angles(R(58), 0, 0) },
	BLDragged = { Vector3.new(1.8, -1, 0.5), out(-30, 38) },
}
M.BodyFor = {}

---------------------------------------------------------------------------
-- server: the fight
---------------------------------------------------------------------------
-- every move, for the hybrids to borrow too
function M.moves(core)
	local F = Fight.init(core)
	local SOUNDS, playSound, burst, pose, bodyPose, setTrail, dustCloud, flat, debrisChunks, FxRemote = core.SOUNDS, core.playSound, core.burst, core.pose, core.bodyPose, core.setTrail, core.dustCloud, core.flat, core.debrisChunks, core.FxRemote
	local D = { Note = 12, Swing = 22, Down = 24, Blast = 14, Bell = 26, Echo = 12 }
	local NOTE = Color3.fromRGB(150, 196, 174)
	local BEAT = 1.35 -- seconds between notes (its count: learn this and the fight's easy)

	local function ahead(b, dist)
		return flat(b.root.Position) + F.fwd(b) * dist
	end
	local function bellSound(b, loud)
		playSound(b.root, SOUNDS.Impact, loud or 1, 0.32)
		playSound(b.root, SOUNDS.Deflect or SOUNDS.Unsheath, 0.8, 0.42)
		playSound(b.root, SOUNDS.Unsheath, 0.6, 0.3)
	end
	-- one strike on its own head: the note rolls out, and (phase 2) a ring comes under whoever's nearest
	local function note(b, target)
		F.draw(b, "BLStrike", "BLStrike", 0.1)
		if not F.wait(b, 0.1) then
			return false
		end
		bellSound(b)
		local c = flat(b.root.Position)
		FxRemote:FireAllClients("Shake", c, 0.55)
		burst(b.root.Position + Vector3.new(0, 14, 0), NOTE, 26, 0.45, 20)
		F.wave(b, c, 22, 72, D.Note, "Medium")
		if F.phase2() then
			local tr = target:FindFirstChild("HumanoidRootPart")
			if tr then
				local at = flat(tr.Position)
				F.ring(at, 5, 1.1)
				task.delay(1.1, function()
					if F.live(b) then
						burst(at, NOTE, 18, 0.35, 16)
						dustCloud(at, 2, 5)
						F.hit(F.radius(at, 5, 8), {}, D.Echo, at, "Medium")
					end
				end)
			end
		end
		return true
	end

	-- THE TOLL: drawn back, a long look, and it strikes itself: count them. It's rattled afterwards, right to the end of the last one
	local function toll(b, target, count)
		F.halt(b)
		count = count or 1
		if F.phase2() then
			count += 1
		end
		for i = 1, count do
			local tell = i == 1 and 0.95 or (BEAT - 0.1) * (F.phase2() and 0.8 or 1)
			F.draw(b, "BLDraw", "BLDraw", tell * 0.7)
			playSound(b.root, SOUNDS.Unsheath, 0.5, 0.55)
			if not F.track(b, target, tell, 0.7) then
				return
			end
			if not note(b, target) then
				return
			end
			bodyPose(b, "BLReel", 0.2)
			if not F.hold(b, 0.12) then
				return
			end
		end
		F.recover(b, 1.5, "BLReel")
	end
	local function tollThree(b, target)
		toll(b, target, 3)
	end

	local function swing(b, target)
		F.halt(b)
		if not F.beats(b, target, {
			{ "BLWind", "BLWind", 0.6 },
			{ "BLWind", "BLWind", 0.5, function()
				playSound(b.root, SOUNDS.Unsheath, 0.9, 0.42)
			end },
		}, 0.7) then
			return
		end
		setTrail(b, true)
		F.step(b, 8, 0.3)
		bodyPose(b, "BLThrough", 0.2)
		pose(b, "BLMid", 0.15, Enum.EasingStyle.Linear)
		task.delay(0.15, function()
			pose(b, "BLEnd", 0.17)
		end)
		playSound(b.root, SOUNDS.Lunge, 1, 0.45)
		F.sweep(b, 0.33, D.Swing, "Large", {}, 3.8)
		setTrail(b, false)
		F.recover(b, 1.2, "BLReel")
	end

	local function down(b, target)
		F.halt(b)
		if not F.beats(b, target, { { "BLHigh", "BLHigh", 0.8 } }, 0.65) then
			return
		end
		local at = ahead(b, 19)
		F.ring(at, 10, 0.65)
		playSound(b.root, SOUNDS.Unsheath, 0.9, 0.4)
		if not F.track(b, target, 0.65, 0) then
			return
		end
		setTrail(b, true)
		F.draw(b, "BLDown", "BLFold", 0.14)
		playSound(b.root, SOUNDS.Lunge, 1, 0.42)
		F.sweep(b, 0.15, D.Down, "Knockdown", {}, 3.8)
		setTrail(b, false)
		if not F.live(b) then
			return
		end
		F.quake(b, at, 10, 1.4)
		debrisChunks(at + Vector3.new(0, 0.5, 0), 6, 20)
		F.hit(F.radius(at, 10, 8), {}, D.Blast, at, "Large")
		F.recover(b, 1.3, false)
	end

	-- THE BELL THROWN DOWN: it rocks right back, a strip lights ahead of it, and it throws its whole top half forward onto the
	-- floor. It rings itself senseless doing it, kneeling there, ears full of it: go and take as much as you like
	local function headlong(b, target)
		F.halt(b)
		if not F.beats(b, target, { { "BLDragged", "BLRock", 0.8, function()
			playSound(b.root, SOUNDS.Groan, 1, 0.34)
		end } }, 0.7) then
			return
		end
		local from, to = ahead(b, 3), ahead(b, 28)
		F.strip(from, to, 17, 0.6)
		if not F.track(b, target, 0.6, 0) then
			return
		end
		F.draw(b, "BLDragged", "BLHeadlong", 0.26)
		playSound(b.root, SOUNDS.Lunge, 1, 0.36)
		F.step(b, 6, 0.26)
		if not F.wait(b, 0.25) then
			return
		end
		bellSound(b, 1)
		local seen = {}
		for i = 0, 3 do
			local p = from:Lerp(to, i / 3)
			F.hit(F.radius(p, 8.5, 8), seen, D.Bell, p, "Knockdown")
			dustCloud(p, 3.5, 7)
			debrisChunks(p + Vector3.new(0, 0.5, 0), 3, 18)
		end
		F.quake(b, to, 12, 1.8)
		F.wave(b, to, 22, 44, D.Note, "Medium")
		bodyPose(b, "BLDazed", 0.45)
		if F.hold(b, 2.1) then
			F.idle(b)
		end
	end

	local function idle(b)
		pose(b, "BLRest", 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		bodyPose(b, "BLIdle", 0.6)
	end
	local function onStagger(b)
		pose(b, "BLDragged", 0.2)
		bodyPose(b, "BLDazed", 0.2)
		bellSound(b, 0.7)
	end
	-- the entrance: stood at the far end with its bell hung low. It raises its weapon and rings the fight in
	local function intro(b)
		pose(b, b.idleGrip, 0.2)
		bodyPose(b, "BLDazed", 0.2)
		task.wait(0.8)
		playSound(b.root, SOUNDS.Groan, 1, 0.4)
		bodyPose(b, "BLDraw", 1.1)
		pose(b, "BLDraw", 1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		task.wait(1.15)
		pose(b, "BLStrike", 0.1)
		bodyPose(b, "BLStrike", 0.1)
		task.wait(0.1)
		bellSound(b, 1)
		FxRemote:FireAllClients("Shake", b.root.Position, 0.7)
		task.wait(0.8)
		pose(b, b.idleGrip, 0.5)
		bodyPose(b, "BLIdle", 0.5)
		task.wait(0.3)
	end
	-- phase 2: it strikes itself once too hard, and the bell cracks
	local function phase2(b)
		F.halt(b)
		F.draw(b, "BLDraw", "BLDraw", 0.5)
		F.wait(b, 0.65)
		F.draw(b, "BLStrike", "BLCracked", 0.1)
		F.wait(b, 0.1)
		bellSound(b, 1)
		FxRemote:FireAllClients("Shake", b.root.Position, 1)
		for _, c in ipairs(b.model:GetChildren()) do
			if c:IsA("BasePart") and c.Name == "BellCrack" then
				c.Transparency = 0
				burst(c.Position, NOTE, 22, 0.45, 18)
			end
		end
		F.wave(b, flat(b.root.Position), 22, 72, D.Note, "Medium")
		F.wait(b, 1.1)
		F.idle(b)
	end

	return { NOTE = NOTE, NoteDamage = D.Note, bellSound = bellSound, toll = toll, tollThree = tollThree, swing = swing, down = down, headlong = headlong, idle = idle, onStagger = onStagger, intro = intro, phase2 = phase2 }
end

function M.init(core)
	local mv = M.moves(core)
	Fight.define({
		id = "Bell",
		label = "The Bellhead",
		kind = M.Kind,
		scale = S,
		weapon = "Clapper",
		idleGrip = "BLRest",
		hp = 780,
		poise = 170,
		stagger = 2.8,
		radius = 4.6,
		walk = 9.5,
		turn = 72,
		rest = { 0.65, 1.3 },
		keep = { 15, 24 },
		phase2At = 0.5,
		tempo2 = 0.88,
		restMult2 = 0.75,
		moves = {
			{ name = "Toll", fn = mv.toll, min = 0, max = 95, weight = 4, cd = 5 },
			{ name = "TollThree", fn = mv.tollThree, min = 14, max = 95, weight = 5, cd = 9 },
			{ name = "Swing", fn = mv.swing, min = 0, max = 27, weight = 6, cd = 2.5, fast = true, behind = true },
			{ name = "Down", fn = mv.down, min = 8, max = 30, weight = 4, cd = 4 },
			{ name = "Headlong", fn = mv.headlong, min = 3, max = 30, weight = 3, cd = 10 },
		},
		idle = mv.idle,
		onStagger = mv.onStagger,
		intro = mv.intro,
		phase2 = mv.phase2,
	})
end

return M
