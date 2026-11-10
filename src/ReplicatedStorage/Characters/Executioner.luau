--!nonstrict
-- PYRE EXECUTIONER (kind Executioner): the palace's headsman, kept on long after there was anyone left to judge. Tall,
-- broad-shouldered, bare to the waist - and what shows is cracked through with fire - under a tall black hood with two
-- holes cut for eyes that burn; an iron collar, a harness of chains crossed over its chest, manacles on both wrists
-- with their chains snapped off, a long split skirt of scorched leather, a ring of keys. In one fist a flail: a short
-- haft, a long chain, a spiked iron ball that glows at its heart. The other hand is empty, and it uses it.
--
-- THE MOVESET (M.attack, which the shared brain calls once it's in range - Def.Engage):
--   Whirl        close in: the flail up over its head and round, faster and faster - then it walks at you with it
--                going, the ball scything round it. Get away from it, or roll through the gap after each pass.
--   Sentence     a little further out: the flail swung up behind, round over its head and DOWN, the ball smashed into
--                the floor well out in front of it - a burst where it lands. Out of the way sideways.
--   The Drag     the flail lashed flat round in front of it, a wide arc - and the chain catches you and DRAGS you in,
--                into the backhand of its empty fist that follows. Roll the lash and there's nothing to drag.
--
-- EVERYTHING ABOUT THIS CHARACTER IS IN THIS ONE FILE:
--   M.Proportions / M.Colors / M.Look   body shape and how the rig is dressed
--   M.Poses / M.Grips / M.BodyFor       its stance, its body poses and the flail's grips
--   M.Weapons                            the flail
--   M.Def / M.attack                     stats and behaviour (the shared brain in GameServer/Enemies.lua)
local M = {}
M.Kind = "Executioner"
M.Proportions = { girth = 1.12, arm = 1.22, hunch = 0.1 }
M.IdlePose = "XBGuard"
local HOOD, SKIN, LEATHER = Color3.fromRGB(16, 12, 12), Color3.fromRGB(62, 28, 18), Color3.fromRGB(52, 34, 24)
local IRON, FIRE = Color3.fromRGB(40, 36, 34), Color3.fromRGB(255, 110, 30)
M.Colors = { skin = SKIN, torso = SKIN, legs = LEATHER, arms = SKIN }

M.Poses = {
	-- guard: upright, the flail hanging from its fist, the free hand open at its side
	XBGuard = { drop = 0.15, lean = 0.08, twist = 0.15, head = 0.12, footR = -0.25, footL = 0.3, breathe = 1.4, la1 = 0.25, la3 = -0.35, lel = 0.5 },
	-- Whirl: the flail up over its head, the free arm out for balance
	XBWhirl = { drop = 0.35, lean = -0.05, head = -0.1, spread = 0.25, footR = -0.3, footL = 0.35, breathe = 3, la1 = 0.4, la3 = -1.3, lel = 0.3, freeL = 0 },
	-- Sentence: wound back and up, then thrown over and down, bent after it
	XBWind = { drop = 0.25, lean = -0.4, twist = 0.45, hip = 0.2, head = -0.2, footR = -0.55, footL = 0.55, la1 = 0.9, la3 = -0.4, lel = 0.6, freeL = 0 },
	XBSentence = { drop = 0.85, lean = 0.75, twist = -0.2, head = 0.3, footR = -0.55, footL = 0.9, la1 = -0.2, la3 = -0.6, lel = 0.3, freeL = 0 },
	-- the Drag: wound round to the right, lashed through to the left; then the backhand
	XBLashBack = { drop = 0.35, lean = 0.05, twist = 0.8, hip = 0.35, footR = -0.4, footL = 0.45, la1 = 0.3, la3 = -0.8, lel = 0.4, freeL = 0 },
	XBLash = { drop = 0.45, lean = 0.3, twist = -0.8, hip = -0.35, footR = 0.3, footL = -0.1, la1 = 0.5, la3 = -0.4, lel = 0.2, freeL = 0 },
	XBFist = { drop = 0.4, lean = 0.2, twist = -0.3, footR = -0.2, footL = 0.4, la1 = 1.5, la2 = 0.6, la3 = -0.2, lel = 0.6, freeL = 0 },
	XBBackhand = { drop = 0.45, lean = 0.35, twist = 0.7, hip = 0.3, footR = -0.3, footL = 0.5, la1 = 1.4, la2 = -0.9, la3 = -1.4, lel = 0.1, freeL = 0 },
}
-- the flail's grips: the chain and ball along the grip's -Y (hanging from the fist, at rest)
local R = math.rad
M.Grips = {
	XGuard = { Vector3.new(1.2, -0.7, -0.3), CFrame.Angles(R(8), 0, R(6)) }, -- hanging at its side
	XUp = { Vector3.new(0.3, 2.9, -0.2), CFrame.Angles(R(95), 0, 0) }, -- (overhead: Whirl turns it round from here)
	XWind = { Vector3.new(1.0, 2.6, 0.9), CFrame.Angles(R(215), 0, R(15)) }, -- up and behind
	XSentence = { Vector3.new(0.5, 0.0, -2.2), CFrame.Angles(R(78), 0, 0) }, -- thrown out and down in front
	XLashBack = { Vector3.new(1.6, 0.9, 0.6), CFrame.Angles(0, R(-120), 0) * CFrame.Angles(R(90), 0, 0) }, -- round behind to the right, flat
	XLash = { Vector3.new(-0.9, 0.7, -1.6), CFrame.Angles(0, R(60), 0) * CFrame.Angles(R(90), 0, 0) }, -- lashed through to the left, flat
}
M.BodyFor = { XGuard = "XBGuard" }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local rng = Random.new()
	local up = CFrame.Angles(0, 0, math.pi / 2)
	local cyl, ball = Enum.PartType.Cylinder, Enum.PartType.Ball
	-- the body: bare, cracked through with fire
	for _, pn in ipairs({ "Chest", "RUpperArm", "LUpperArm", "RLowerArm", "LLowerArm" }) do
		parts[pn].Material = MAT.CrackedLava
		parts[pn].Color = SKIN
	end
	-- THE HOOD: tall, peaked, falling over the shoulders; two eye-holes, fire in them
	parts.Head.Color = HOOD
	deco("Head", "Hood", V(1.35, 1.5, 1.35), at(0, 0.1, 0.02), HOOD, MAT.Fabric)
	for i = 0, 4 do -- the peak, stepping in and leaning back
		local w = 1.1 - i * 0.2
		deco("Head", "HoodPeak", V(w, 0.4, w), at(0, 0.95 + i * 0.36, 0.06 + i * 0.07) * CFrame.Angles(-0.12 * i, 0, 0), HOOD, MAT.Fabric)
	end
	deco("Head", "HoodDrape", V(2.3, 0.9, 1.6), at(0, -0.85, 0.1), HOOD, MAT.Fabric)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "EyeHole", V(0.28, 0.2, 0.05), at(sx * 0.26, 0.15, -0.69), rgb(4, 2, 2), MAT.SmoothPlastic)
		deco("Head", "Eye", V(0.13, 0.08, 0.04), at(sx * 0.26, 0.15, -0.7), FIRE, MAT.Neon)
	end
	-- the collar, the chains crossed over the chest, the harness rings
	deco("Chest", "Collar", V(0.35, cw * 0.62, cw * 0.62), at(0, ch * 0.48, 0) * up, IRON, MAT.Metal, cyl)
	for _, sx in ipairs({ -1, 1 }) do
		for i = 0, 7 do
			local f = i / 7
			deco("Chest", "HarnessChain", V(0.14, 0.34, 0.22), at(sx * cw * (0.38 - f * 0.76), ch * (0.4 - f * 0.8), -cd * 0.56) * CFrame.Angles(0, i % 2 * math.pi / 2, sx * 0.7), IRON, MAT.Metal)
		end
	end
	deco("Chest", "HarnessRing", V(0.12, 0.5, 0.5), at(0, 0, -cd * 0.6) * CFrame.Angles(0, math.pi / 2, 0), IRON, MAT.Metal, cyl)
	for i = 0, 4 do -- burned seams on its back
		deco("Chest", "Scar", V(cw * 0.5, 0.06, 0.04), at(0, ch * (0.3 - i * 0.14), cd * 0.52) * CFrame.Angles(0, 0, rng:NextNumber(-0.4, 0.4)), FIRE, MAT.Neon)
	end
	-- the belt, the keys, the long split skirt of leather
	deco("Hips", "Belt", V(hw * 1.25, 0.35, hd * 1.3), at(0, 0.3, 0), LEATHER:Lerp(rgb(0, 0, 0), 0.4), MAT.Leather)
	deco("Hips", "Buckle", V(0.4, 0.3, 0.08), at(0, 0.3, -hd * 0.66), IRON, MAT.Metal)
	deco("Hips", "KeyRing", V(0.08, 0.45, 0.45), at(-hw * 0.55, 0.05, -hd * 0.3) * CFrame.Angles(0, math.pi / 2, 0), IRON, MAT.Metal, cyl)
	for i = 0, 3 do
		deco("Hips", "Key", V(0.08, 0.5, 0.14), at(-hw * 0.55 + (i - 1.5) * 0.09, -0.3, -hd * 0.3), rgb(120, 96, 60), MAT.Metal)
	end
	for _, sx in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -1, 1 }) do
			k.tatter(rng, "Hips", CFrame.new(sx * hw * 0.26, 0.1, z * hd * 0.6), hw * 0.5, 2.1, LEATHER, LEATHER:Lerp(rgb(10, 6, 4), 0.6), 0.5)
		end
	end
	-- arms: manacles with snapped chains, a leather bracer on the flail arm; legs: wrapped, iron-shod
	for _, n in ipairs({ "R", "L" }) do
		deco(n .. "LowerArm", "Manacle", V(aw * 1.5, 0.38, aw * 1.5), at(0, -la * 0.3, 0), IRON, MAT.Metal)
		for i = 0, 2 do
			deco(n .. "LowerArm", "Chain", V(0.1, 0.28, 0.2), at(0, -la * 0.3 - 0.3 - i * 0.24, aw * 0.75) * CFrame.Angles(0, i % 2 * math.pi / 2, 0), IRON, MAT.Metal)
		end
		deco(n .. "UpperArm", "Shoulder", V(aw * 1.3, ua * 0.3, aw * 1.3), at(0, ua * 0.35, 0), SKIN, MAT.CrackedLava)
		deco(n .. "Shin", "Wraps", V(lw * 1.15, 1.0, lw * 1.15), at(0, -0.1, 0), LEATHER:Lerp(rgb(0, 0, 0), 0.25), MAT.Fabric)
		deco(n .. "Foot", "Boot", V(0.72, 0.36, 1.15), at(0, 0.02, -0.05), IRON, MAT.Metal)
	end
	deco("RLowerArm", "Bracer", V(aw * 1.35, la * 0.45, aw * 1.35), at(0, la * 0.1, 0), LEATHER, MAT.Leather)
end

M.Weapons = {
	-- a flail: a short iron-bound haft, a long chain, a spiked ball, its heart glowing through the cracks. The chain is
	-- real: its links hung one from the next on ball joints, the ball on the end, so it swings, trails, drags and
	-- falls as iron does - the attacks only throw the ball, the chain follows it
	PyreFlail = function(w)
		local iron = Color3.fromRGB(38, 34, 32)
		local s = w.scale
		local handle = w.mk("Grip", Vector3.new(0.3, 1.3, 0.3), LEATHER, Enum.Material.Leather)
		w.add(w.mk("Pommel", Vector3.new(0.42, 0.42, 0.42), iron, Enum.Material.Metal), 0.75)
		w.add(w.mk("Haft", Vector3.new(0.34, 0.6, 0.34), iron, Enum.Material.Metal), -0.9)
		local LINKS, TOP, STEP, BALL_Y = 12, -1.15, 0.36, -6.0 -- (along the handle's Y, unscaled)
		local chain = {}
		for i = 1, LINKS do
			chain[i] = w.mk("Link", Vector3.new(0.12, 0.42, 0.3), iron, Enum.Material.Metal)
			w.add(chain[i], TOP - i * STEP, CFrame.Angles(0, (i % 2) * math.pi / 2, 0))
		end
		local orb = w.mk("Ball", Vector3.new(1.7, 1.7, 1.7), Color3.fromRGB(44, 38, 34), Enum.Material.Metal)
		orb.Shape = Enum.PartType.Ball
		w.add(orb, BALL_Y)
		local studs = { w.mk("BallCore", Vector3.new(1.74, 0.16, 1.74), FIRE, Enum.Material.Neon) } -- (fixed to the ball, not the haft)
		w.add(studs[1], BALL_Y, CFrame.Angles(0, 0, 0.5))
		for _, d in ipairs({ { 1, 0, 0 }, { -1, 0, 0 }, { 0, 0, 1 }, { 0, 0, -1 }, { 0.7, 0, 0.7 }, { -0.7, 0, -0.7 } }) do
			local dir = Vector3.new(d[1], d[2], d[3]).Unit
			local sp = w.mk("Spike", Vector3.new(0.26, 0.26, 0.8), iron, Enum.Material.Metal)
			table.insert(studs, sp)
			w.add(sp, BALL_Y, CFrame.new(dir * 0.95 * s) * CFrame.lookAt(Vector3.zero, dir))
		end
		local tip = w.mk("Spike", Vector3.new(0.26, 0.8, 0.26), iron, Enum.Material.Metal)
		table.insert(studs, tip)
		w.add(tip, BALL_Y - 0.95)
		local function setup(h)
			-- (built welded to the haft like any weapon's parts: unweld the chain and hang it on joints instead)
			local function at(part, y)
				local a = Instance.new("Attachment")
				a.CFrame = part.CFrame:ToObjectSpace(h.CFrame * CFrame.new(0, y * s, 0))
				a.Parent = part
				return a
			end
			local prev, prevY = h, TOP
			local LIGHT = PhysicalProperties.new(0.2, 0.3, 0.1) -- (light links: they don't haul it about)
			for i, p in ipairs(chain) do
				p:FindFirstChildOfClass("Weld"):Destroy()
				p.Massless, p.CustomPhysicalProperties = false, LIGHT
				local y = TOP - i * STEP
				local j = Instance.new("BallSocketConstraint")
				j.Attachment0, j.Attachment1 = at(prev, (prevY + y) / 2), at(p, (prevY + y) / 2)
				j.Parent = p
				prev, prevY = p, y
			end
			orb:FindFirstChildOfClass("Weld"):Destroy()
			orb.Massless, orb.CanCollide, orb.CollisionGroup = false, true, "Debris" -- (it lands on the floor; never on anyone)
			orb.CustomPhysicalProperties = PhysicalProperties.new(0.6, 0.3, 0.1)
			for _, sp in ipairs(studs) do
				local wd = sp:FindFirstChildOfClass("Weld")
				wd.Part0, wd.C0 = orb, orb.CFrame:ToObjectSpace(sp.CFrame)
			end
			local j = Instance.new("BallSocketConstraint")
			j.Attachment0, j.Attachment1 = at(prev, (prevY + BALL_Y) / 2), at(orb, (prevY + BALL_Y) / 2)
			j.Parent = orb
			local rope = Instance.new("RopeConstraint") -- (a stop: light links stretch under a hard throw)
			rope.Attachment0, rope.Attachment1 = at(h, TOP), at(orb, BALL_Y)
			rope.Length = (TOP - BALL_Y) * s
			rope.Parent = orb
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness = FIRE, 9, 1
			l.Parent = studs[1]
		end
		return { handle = handle, bladeLen = 1.2, setup = setup }
	end,
}

-- stats (the shared brain in GameServer/Enemies.lua reads these). Inside Close it whirls or drags; further, Sentence
M.Def = {
	HP = 380, Speed = 10.5, Scale = 1.35, Damage = 40, Range = 11, HalfAngle = 70,
	Windup = 0.85, Recover = 1.0, Aggro = 40, Leash = 55, Stagger = 0.45, StaggerPush = 10,
	HyperArmor = false, Weapon = "PyreFlail", Radius = 1.6, Lunge = 8,
	Poise = 55, HitLevel = "Large", Engage = 15, Close = 8, IdleGrip = "XGuard",
	WhirlSpin = 1.2, WhirlTime = 2.0, WhirlRadius = 7, WhirlDamage = 20, WhirlEvery = 0.55, WhirlSpeed = 7,
	SentenceReach = 11, SentenceRadius = 4.5, DragDamage = 16, FistDamage = 32,
	Skin = SKIN, Cloth = LEATHER,
}

---------------------------------------------------------------------------
-- server: how it fights
---------------------------------------------------------------------------
local pose, bodyPose, playSound, SOUNDS, now, faceTowards, setTrail, flat, playersInSector, playersInRadius, damagePlayer, burst, dustCloud, FxRemote, poseCF
local RunService = game:GetService("RunService")

-- the flail's ball (its own body on the end of the chain), taken under the server's simulation to be thrown
local function ballOf(e)
	local weapon = e.model:FindFirstChild("Weapon")
	local b = weapon and weapon:FindFirstChild("Ball")
	if b then
		pcall(b.SetNetworkOwner, b, nil)
	end
	return b
end
local function handPos(e)
	local h = e.weld and e.weld.Part1
	return h and h.Position or e.root.Position
end
local function throwBall(e, v)
	local b = ballOf(e)
	if b then
		b.AssemblyLinearVelocity = v
	end
end

local function hold(e, duration, target)
	local t0 = now()
	while now() - t0 < duration do
		if not e.alive or now() < e.staggerUntil then
			return false
		end
		if target and target.Parent then
			faceTowards(e.root, target.Position)
		end
		task.wait()
	end
	return true
end

-- WHIRL: the flail held up overhead and the ball swung round it on its chain, faster and faster; then walked at you
local function whirl(e, tRoot)
	local def, root, hum = e.def, e.root, e.hum
	pose(e, "XUp", 0.3)
	bodyPose(e, "XBWhirl", 0.3)
	if not hold(e, 0.3, tRoot) then
		return false
	end
	local ball = ballOf(e)
	local L = 4.85 * e.scale -- (the chain's reach)
	local last, t0 = now(), now()
	local hits, ok = {}, true
	local lastWhoosh = 0
	setTrail(e, true)
	while true do
		local t = now()
		local dt = t - last
		last = t
		local el = t - t0
		if not e.alive or t < e.staggerUntil then
			ok = false
			break
		end
		if el > def.WhirlSpin + def.WhirlTime then
			break
		end
		local speed = math.min(1, el / def.WhirlSpin) * 13 + 3 -- (radians a second: winding up to full)
		if ball and ball.Parent then -- (driven round the hand, held out by the chain: the links follow it)
			local c = handPos(e)
			local r = (ball.Position - c) * Vector3.new(1, 0, 1)
			r = r.Magnitude > 0.2 and r.Unit or root.CFrame.RightVector
			local tangent = Vector3.yAxis:Cross(r)
			ball.AssemblyLinearVelocity = tangent * speed * L * 0.9 + r * 6 + Vector3.new(0, (c.Y - 0.6 - ball.Position.Y) * 8, 0)
		end
		if t - lastWhoosh > math.pi * 2 / speed then
			lastWhoosh = t
			playSound(root, SOUNDS.Lunge, 0.5, 0.45)
		end
		if el > def.WhirlSpin then -- (at full speed: walking at you, the ball scything round)
			hum.WalkSpeed = def.WhirlSpeed
			if tRoot.Parent then
				hum:MoveTo(tRoot.Position)
			end
			for _, pl in ipairs(playersInRadius(root.Position, def.WhirlRadius, 6 * def.Scale)) do
				if t - (hits[pl] or -99) > def.WhirlEvery then
					hits[pl] = t
					damagePlayer(pl, def.WhirlDamage, root.Position, "Medium")
				end
			end
		elseif tRoot.Parent then
			faceTowards(root, tRoot.Position)
		end
		RunService.Heartbeat:Wait()
	end
	hum.WalkSpeed = def.Speed
	hum:MoveTo(root.Position)
	setTrail(e, false)
	return ok
end

-- SENTENCE: up behind, over and down - the ball into the floor well out in front, a burst where it lands
local function sentence(e, tRoot)
	local def, root = e.def, e.root
	pose(e, "XWind", def.Windup * 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	bodyPose(e, "XBWind", def.Windup * 0.8)
	playSound(root, SOUNDS.Unsheath, 0.4, 0.5)
	if not hold(e, def.Windup * 1.15, tRoot) then
		return false
	end
	setTrail(e, true)
	playSound(root, SOUNDS.Lunge, 0.8, 0.5)
	pose(e, "XSentence", 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	bodyPose(e, "XBSentence", 0.2)
	local at = root.Position - Vector3.new(0, 3 * def.Scale - 0.2, 0) + flat(root.CFrame.LookVector) * def.SentenceReach * 0.75
	throwBall(e, flat(root.CFrame.LookVector) * 30 + Vector3.new(0, 38, 0)) -- (up and over...)
	task.wait(0.12)
	local b = ballOf(e)
	if b then -- (...and down: the ball driven into the floor where it lands, the chain whipping after it)
		b.AssemblyLinearVelocity = (at - b.Position).Unit * 75
	end
	task.wait(0.08)
	if not e.alive then
		return false
	end
	for _, pl in ipairs(playersInRadius(at, def.SentenceRadius, 5)) do
		damagePlayer(pl, def.Damage, at, def.HitLevel)
	end
	burst(at, FIRE, 26, 0.6, 20)
	dustCloud(at, 4, 10)
	playSound(root, SOUNDS.WatchdogSmash, 0.7, 1.0)
	FxRemote:FireAllClients("Shake", at, 0.4)
	setTrail(e, false)
	return true
end

-- THE DRAG: the flail lashed flat round in front; whoever it catches is dragged in, and the backhand follows
local function drag(e, tRoot)
	local def, root = e.def, e.root
	pose(e, "XLashBack", def.Windup * 0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	bodyPose(e, "XBLashBack", def.Windup * 0.7)
	playSound(root, SOUNDS.Unsheath, 0.4, 0.6)
	if not hold(e, def.Windup, tRoot) then
		return false
	end
	setTrail(e, true)
	playSound(root, SOUNDS.Lunge, 0.8, 0.55)
	pose(e, "XLash", 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	bodyPose(e, "XBLash", 0.18)
	throwBall(e, (root.CFrame.LookVector * 0.7 - root.CFrame.RightVector) * 55 + Vector3.new(0, 6, 0)) -- (the ball flung flat round across its front)
	task.wait(0.14)
	if not e.alive then
		return false
	end
	local caught = false
	for _, pl in ipairs(playersInSector(root.CFrame, def.Range, def.HalfAngle, 6 * def.Scale)) do
		local hrp = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			-- pushed away from a point beyond them: so toward it, dragged in
			local away = flat(hrp.Position - root.Position)
			local from = hrp.Position + (away.Magnitude > 0.1 and away.Unit or root.CFrame.LookVector) * 6
			if damagePlayer(pl, def.DragDamage, from, "Medium") then
				caught = true
			end
		end
	end
	setTrail(e, false)
	if not caught then
		return true
	end
	local b = ballOf(e)
	if b then -- (the chain hauled back in with whoever it caught)
		b.AssemblyLinearVelocity = (handPos(e) - b.Position).Unit * 40
	end
	-- the backhand: the free fist, round from the left, into whoever's been dragged up close
	pose(e, "XGuard", 0.25)
	bodyPose(e, "XBFist", 0.2)
	if not hold(e, 0.32, tRoot) then
		return false
	end
	playSound(root, SOUNDS.Slash, 0.6, 0.7)
	bodyPose(e, "XBBackhand", 0.14)
	task.wait(0.12)
	for _, pl in ipairs(playersInSector(root.CFrame, 6, 70, 6 * def.Scale)) do
		damagePlayer(pl, def.FistDamage, root.Position, "Large")
	end
	return e.alive
end

function M.attack(e, targetChar)
	local def, hum, root = e.def, e.hum, e.root
	local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
	if not tRoot then
		return
	end
	e.attacking = true
	hum:MoveTo(root.Position)
	hum.AutoRotate = false
	local d = flat(tRoot.Position - root.Position).Magnitude
	local ok, rest
	if d > def.Close then
		ok, rest = sentence(e, tRoot), def.Recover
	elseif math.random() < 0.45 then
		ok, rest = whirl(e, tRoot), def.Recover * 1.3 -- (dizzy after: your opening)
	else
		ok, rest = drag(e, tRoot), def.Recover
	end
	if ok then
		hold(e, rest)
	end
	setTrail(e, false)
	if e.alive then
		pose(e, "Idle", 0.4)
	end
	hum.AutoRotate = true
	e.attacking = false
end

function M.init(core)
	pose, bodyPose, playSound, SOUNDS, now, faceTowards, setTrail, flat = core.pose, core.bodyPose, core.playSound, core.SOUNDS, core.now, core.faceTowards, core.setTrail, core.flat
	playersInSector, playersInRadius, damagePlayer, burst, dustCloud, FxRemote, poseCF = core.playersInSector, core.playersInRadius, core.damagePlayer, core.burst, core.dustCloud, core.FxRemote, core.poseCF
end

return M
