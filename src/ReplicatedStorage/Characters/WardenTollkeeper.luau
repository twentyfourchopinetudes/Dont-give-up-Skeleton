--!nonstrict
-- THE BELL WARDEN (id "Tollkeeper"). The tall gaunt jailer in his greatcoat, stooped under a bronze bell, and in both hands the great maul
-- he rings it with: a timber haft as thick as a man and an iron-bound head wider than you are tall. The first boss of the game, so
-- everything is heavy and given a long look first. Up close he heaves it side to side and brings it down; he lunges with it, off
-- balance, and needs a moment to recover; hang back and he comes dragging it at a run, or tolls you back in with a note you roll through.
-- Phase 2 is another fight: he strikes the bell once too hard, it cracks, and the maul falls out of his numbed hands and stays where
-- it lands. Bare handed, he's fast and wants you close, and his only weapon is the bell on his shoulders: he throws it into the floor
-- face first, walks a line of those at you, and leaps the room to do it on top of you. Each one leaves him bent over and open.
-- His maul never goes through the floor: its head stops just above it. Every grip here keeps it so (hands are relative to his root,
-- which stands 3 units up; the head's centre is 4.6 units from the hands, and it's 1.05 in radius and 1.6 either side of the haft).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Fight = require(ReplicatedStorage:WaitForChild("WardenFight"))
local Garb = require(ReplicatedStorage:WaitForChild("WardenGarb"))
local Turnkey = require(script.Parent:WaitForChild("WardenTurnkey"))
local Bell = require(script.Parent:WaitForChild("WardenBell"))

local S = 3.4
local K = S / 1.95
local M = {}
M.Kind = "WardenTollkeeper"
M.Proportions = table.clone(Turnkey.Proportions)
M.IdlePose = "TKIdle"
M.Poses = {
	-- phase 2, the maul gone: bowed under the bell, long arms hanging and swinging
	TP2Stalk = { drop = 0.4, lean = 0.55, head = 0.35, footR = -0.3, footL = 0.35, spread = 0.24, la1 = 0.25, la3 = -0.25, lel = 0.5, ra1 = 0.25, ra3 = 0.25, rel = 0.5, breathe = 5 },
	-- reared right back, arms flung out behind the bell's weight
	TP2Rear = { drop = 0.1, lean = -0.6, head = -0.55, footR = -0.6, footL = 0.5, spread = 0.3, la1 = 1.2, la3 = -0.8, lel = 0.5, ra1 = 1.2, ra3 = 0.8, rel = 0.5, breathe = 6, freeL = 0 },
	-- the whole top of him thrown down, mouth of the bell first
	TP2Slam = { drop = 1.7, lean = 1.4, head = 0.35, footR = 0.9, footL = -1.2, spread = 0.4, la1 = -0.5, la3 = -0.8, lel = 0.1, ra1 = -0.5, ra3 = 0.8, rel = 0.1, breathe = 7, freeL = 0 },
	-- still down there, propped on his hands, ears full of it
	TP2Stuck = { drop = 1.5, lean = 1.15, side = 0.1, head = 0.45, footR = 0.9, footL = -1.1, spread = 0.38, la1 = 0.9, la3 = -0.3, lel = 0.3, ra1 = 0.9, ra3 = 0.3, rel = 0.3, breathe = 7, freeL = 0 },
	-- both hands up on the bell, wrenching at it
	TP2Clutch = { drop = 0.55, lean = 0.3, side = -0.1, head = 0.3, footR = 0.3, footL = -0.4, spread = 0.32, la1 = 2.2, la3 = -0.35, lel = 1.3, ra1 = 2.2, ra3 = 0.35, rel = 1.3, breathe = 7, freeL = 0 },
	-- sunk deep to leap, then knees up in the air
	TP2Crouch = { drop = 1.25, lean = 0.6, head = -0.2, footR = 0.5, footL = -0.5, spread = 0.36, la1 = -0.6, la3 = -0.5, lel = 0.3, ra1 = -0.6, ra3 = 0.5, rel = 0.3, breathe = 6, freeL = 0 },
	TP2Air = { drop = 0.2, lean = -0.2, head = -0.3, tuck = 0.7, la1 = 1.5, la3 = -0.9, lel = 0.4, ra1 = 1.5, ra3 = 0.9, rel = 0.4, freeL = 0 },
}
M.Colors = Turnkey.Colors
M.FistSkin = true

local BRONZE = {
	main = Color3.fromRGB(150, 106, 58),
	dark = Color3.fromRGB(94, 64, 36),
	light = Color3.fromRGB(204, 166, 98),
	streak = Color3.fromRGB(218, 184, 118),
	glow = Color3.fromRGB(240, 206, 150),
}

function M.Look(k)
	Turnkey.LookCoat(k)
	Bell.LookBell(k, BRONZE)
end

M.Weapons = {
	-- the great maul: timber staves bound in iron, a leather grip, and a barrel of an iron head with bronze hoops to match the bell
	TollMaul = function(w)
		local mk, add, s = w.mk, w.add, w.scale
		local iron, dark = Color3.fromRGB(74, 70, 66), Color3.fromRGB(38, 36, 36)
		local timber, timberDk, leather = Color3.fromRGB(78, 56, 38), Color3.fromRGB(50, 36, 26), Color3.fromRGB(58, 42, 30)
		local rng = Random.new(1612)
		local function rod(name, y, long, d, color, mat)
			local p = mk(name, Vector3.new(long, d, d), color, mat or Enum.Material.Metal)
			p.Shape = Enum.PartType.Cylinder
			add(p, y, Garb.UP)
		end
		local handle = mk("Haft", Vector3.new(0.2, 3, 0.2), timber, Enum.Material.Wood)
		handle.Transparency = 1
		-- the haft: a dark core, staves round it, iron bands
		rod("HaftCore", -1.05, 5.5, 0.58, timberDk, Enum.Material.Wood)
		for i = 0, 7 do
			local a = i / 8 * 2 * math.pi
			local stave = mk("Stave", Vector3.new(0.2, 5.4, 0.12), timber:Lerp(timberDk, rng:NextNumber() * 0.6), Enum.Material.Wood)
			add(stave, -1.05, CFrame.new(math.sin(a) * 0.27 * s, 0, math.cos(a) * 0.27 * s) * CFrame.Angles(0, a, 0))
		end
		for _, y in ipairs({ -0.75, -1.5, -2.25 }) do
			rod("HaftBand", y, 0.16, 0.72, dark)
		end
		-- the leather where the hands go, in turns
		for i = 0, 9 do
			rod("GripWrap", 1.25 - i * 0.17, 0.15, 0.68 + (i % 2) * 0.03, leather:Lerp(timberDk, (i % 3) * 0.2), Enum.Material.Leather)
		end
		-- the pommel
		rod("Pommel", 1.68, 0.2, 0.92, iron)
		rod("Pommel", 1.82, 0.14, 0.7, dark)
		-- iron straps running up the haft from the head
		for i = 0, 3 do
			local a = (i + 0.5) / 4 * 2 * math.pi
			add(mk("Langet", Vector3.new(0.2, 0.9, 0.08), iron, Enum.Material.Metal), -2.65, CFrame.new(math.sin(a) * 0.35 * s, 0, math.cos(a) * 0.35 * s) * CFrame.Angles(0, a, 0))
		end
		-- the head, across the haft along x, in thin slices: flared faces, a drawn-in waist
		local function headR(x)
			local t = math.abs(x)
			return t > 1.42 and 1.05 or t > 1.28 and 0.97 or 0.88 + 0.06 * (t / 1.28) ^ 2
		end
		local main
		local x = -1.54
		while x <= 1.55 do
			local p = mk("HeadSlice", Vector3.new(0.14, headR(x) * 2, headR(x) * 2), iron:Lerp(dark, rng:NextNumber() ^ 1.2), Enum.Material.Metal)
			p.Shape = Enum.PartType.Cylinder
			add(p, -3.8, CFrame.new(x * s, 0, 0))
			main = main or p
			x += 0.11
		end
		main.Name = "MaulHead"
		-- bronze hoops, and a boss on each striking face
		for _, hx in ipairs({ -1.3, -0.62, 0.62, 1.3 }) do
			local p = mk("HeadHoop", Vector3.new(0.1, (headR(hx) + 0.05) * 2, (headR(hx) + 0.05) * 2), BRONZE.main, Enum.Material.Metal)
			p.Shape = Enum.PartType.Cylinder
			add(p, -3.8, CFrame.new(hx * s, 0, 0))
		end
		for _, side in ipairs({ -1, 1 }) do
			local p = mk("FaceBoss", Vector3.new(0.12, 1.1, 1.1), dark, Enum.Material.Metal)
			p.Shape = Enum.PartType.Cylinder
			add(p, -3.8, CFrame.new(side * 1.62 * s, 0, 0))
			-- and a ring of rivets round it, so the face isn't one flat disc
			for i = 0, 9 do
				local a = i / 10 * 2 * math.pi
				local r = mk("HeadRivet", Vector3.new(0.16, 0.16, 0.16), BRONZE.light, Enum.Material.Metal)
				r.Shape = Enum.PartType.Ball
				add(r, -3.8, CFrame.new(side * 1.61 * s, math.sin(a) * 0.82 * s, math.cos(a) * 0.82 * s))
			end
		end
		-- rivets round the barrel, two rows either side
		for _, hx in ipairs({ -0.95, 0.95 }) do
			for i = 0, 9 do
				local a = i / 10 * 2 * math.pi
				local p = mk("HeadRivet", Vector3.new(0.14, 0.14, 0.14), BRONZE.light, Enum.Material.Metal)
				p.Shape = Enum.PartType.Ball
				add(p, -3.8, CFrame.new(hx * s, math.sin(a) * headR(hx) * s, math.cos(a) * headR(hx) * s))
			end
		end
		return { handle = handle, bladeLen = 3.2, gripC1 = CFrame.new(0, 0.8 * s, 0) }
	end,
}

-- a grip by what it looks like: hands at pos, the head out along u, its striking faces along v
local function G(x, y, z, u, v)
	u = u.Unit
	local across = (v - u * v:Dot(u)).Unit
	local down = -u
	return { Vector3.new(x, y, z), CFrame.fromMatrix(Vector3.zero, across, down, across:Cross(down)) }
end
local V3 = Vector3.new
M.Grips = {
	TLRest = G(0.7, 0.75, -2.1, V3(0.12, -0.4, -0.9), V3(1, 0, 0.15)), -- (held out before him, the head low and off the floor)
	TLPlant = G(0.3, 0.1, -1.9, V3(0, -0.35, -0.94), V3(1, 0, 0)), -- (held out low, leaning on it)
	TLBroke = G(1.2, 3.2, -0.9, V3(0.1, 0.95, 0.3), V3(1, 0, 0)),
	-- the heave, and back
	TLHeaveSet = G(2.1, 1.0, 0.8, V3(0.75, 0.35, 0.55), V3(0.6, 0, -0.8)),
	TLHeaveMid = G(0.6, -0.1, -2.4, V3(0.05, -0.16, -1), V3(-1, 0, 0)),
	TLHeaveEnd = G(-1.9, 0, -0.7, V3(-1, -0.12, -0.1), V3(0, 0, 1)),
	TLBackSet = G(-1.8, 0.9, 0.2, V3(-0.95, 0.25, 0.25), V3(0, 0, 1)),
	TLBackMid = G(0.3, -0.1, -2.5, V3(-0.05, -0.16, -1), V3(-1, 0, 0)),
	TLBackEnd = G(2.0, 0, -0.6, V3(1, -0.12, -0.1), V3(0, 0, -1)),
	-- the lunge
	TLThrustSet = G(1.3, 1.1, 1.6, V3(0, -0.05, -1), V3(1, 0, 0)),
	TLThrust = G(0.3, -0.2, -2.7, V3(0, -0.16, -1), V3(1, 0, 0)),
	TLStuck = G(0.3, -0.5, -2.2, V3(0, -0.25, -1), V3(1, 0, 0)), -- (dragged down after it, the head just off the floor)
	-- brought down
	TLHigh = G(0.6, 3.4, -1.3, V3(0, 0.95, 0.3), V3(0, 0.3, -0.95)),
	TLDown = G(0.2, 0.05, -2.4, V3(0, -0.22, -0.97), V3(0, -0.97, 0.22)),
	-- the turn
	TLWind = G(1.9, 0.2, 1.5, V3(0.7, -0.1, 0.7), V3(0.7, 0, -0.7)),
	TLSweepR = G(2.5, -0.1, -0.5, V3(1, -0.1, -0.2), V3(0, 0, -1)),
	TLSweepF = G(0, -0.1, -2.8, V3(0, -0.1, -1), V3(-1, 0, 0)),
	TLSweepL = G(-2.5, -0.1, -0.5, V3(-1, -0.1, -0.2), V3(0, 0, 1)),
	TLSweepB = G(-1.3, -0.1, 2.1, V3(-0.4, -0.1, 1), V3(1, 0, 0)),
	-- dragged behind him at a run, then swung up
	TLDrag = G(1.7, -0.1, 1.4, V3(0.35, -0.22, 0.9), V3(0.93, 0, -0.36)),
	TLUpSide = G(2.2, -0.1, -0.4, V3(1, -0.12, -0.1), V3(0, 0, -1)),
	TLUpMid = G(0.7, 0.3, -2.4, V3(0, -0.1, -1), V3(-1, 0, 0)),
	TLUpEnd = G(0.4, 2.7, -1.2, V3(0, 0.85, -0.5), V3(-1, 0, 0)),
	-- his own bell, rung with the head's face
	TLBellSet = G(1.2, 1.2, -2.0, V3(-0.6, 0.5, -0.75), V3(0.75, 0.1, -0.6)),
	TLBellHit = G(1.4, 0.9, -2.7, V3(-4.1, 1.3, 1.7), V3(1, 0, 0)),
}
M.BodyFor = {}

function M.init(core)
	local F = Fight.init(core)
	local bl = Bell.moves(core)
	local SOUNDS, playSound, burst, pose, bodyPose, setTrail, dustCloud, crackLines, fadeAway, debrisChunks, flat, now, FxRemote = core.SOUNDS, core.playSound, core.burst, core.pose, core.bodyPose, core.setTrail, core.dustCloud, core.crackLines, core.fadeAway, core.debrisChunks, core.flat, core.now, core.FxRemote
	local D = { Heave = 18, Lunge = 22, Slam = 22, Blast = 12, Wheel = 20, Charge = 18, Note = 12, Face = 24, Line = 18, Leap = 26, Rattle = 14 }
	local NOTE = Color3.fromRGB(112, 92, 68) -- (old bronze shaken loose)
	local WALK = 10.5
	local REACH = 8 -- (how far ahead of him the bell's mouth comes down when he throws himself headlong)
	local HIT = 4.5 -- (how wide the head's path hurts, either side of the haft)
	local SLAM_AT = 7 * S -- (how far ahead of him the head comes down)

	-- The floor guard. A tween between two grips can swing the head down through the floor even when both grips clear it, so poses
	-- drive a stand-in weld and the real one copies it each frame, lifted by however much the maul would otherwise go under
	local function keepAboveFloor(b)
		local real = b.weld
		local wanted = Instance.new("Weld")
		wanted.Name, wanted.Enabled, wanted.C0, wanted.C1, wanted.Part1 = "GripPose", false, real.C0, real.C1, real.Part1
		wanted.Parent = real.Parent
		b.weld = wanted
		F.wrap(b, function()
			local c = wanted.C0
			local rootCF = b.root.CFrame
			local w = rootCF * c -- (in the world: his root can tilt as he moves, and at this reach a few degrees is over a stud)
			local up, across = w.UpVector.Y, w.RightVector.Y
			local head = up * -4.6 - math.abs(across) * 1.68 - math.sqrt(math.max(1 - across * across, 0)) * 1.1
			local pommel = up * 1.12 - math.sqrt(math.max(1 - up * up, 0)) * 0.46
			local low = w.Y + math.min(head, pommel) * S
			real.C0 = low < 0.3 and c + rootCF:VectorToObjectSpace(Vector3.new(0, 0.3 - low, 0)) or c
			return real.Parent ~= nil
		end)
	end

	local function under(b, dist)
		return flat(b.root.Position) + F.fwd(b) * dist
	end
	local function headFloor(b)
		local _, tip = F.ends(b)
		local p = tip or under(b, SLAM_AT)
		return Vector3.new(p.X, 0.15, p.Z)
	end

	-- one heave of it, side to side, the coil given a long look
	local function heaveOnce(b, target, set, mid, finish, bodySet, bodyThrough, tell, step, level)
		F.draw(b, set, bodySet, tell * 0.5 * F.tempo())
		playSound(b.root, SOUNDS.Unsheath, 0.7, 0.45)
		if not F.track(b, target, tell * F.tempo(), 0.6) then
			return false
		end
		setTrail(b, true)
		F.step(b, step * K, 0.3)
		playSound(b.root, SOUNDS.Lunge, 0.9, 0.5)
		bodyPose(b, bodyThrough, 0.2)
		pose(b, mid, 0.14, Enum.EasingStyle.Linear)
		task.delay(0.14, function()
			pose(b, finish, 0.16, Enum.EasingStyle.Quad)
		end)
		F.sweep(b, 0.3, D.Heave, level or "Medium", {}, HIT)
		setTrail(b, false)
		return F.free(b)
	end

	-- THE MAUL BROUGHT DOWN: up over his head, a held moment at the top, then folded down behind it. It stops a hand above the
	-- floor and the shock goes on without it
	local function slam(b, target)
		F.halt(b)
		if not F.beats(b, target, {
			{ "TLHeaveSet", "TKUp", 0.35 },
			{ "TLHigh", "TKOverhead", 0.6 },
		}, 0.7) then
			return
		end
		playSound(b.root, SOUNDS.Unsheath, 0.9, 0.42)
		if not F.track(b, target, 0.5, 0) then
			return
		end
		setTrail(b, true)
		F.draw(b, "TLDown", "TKFold", 0.12)
		playSound(b.root, SOUNDS.Lunge, 1, 0.42)
		F.sweep(b, 0.14, D.Slam, "Knockdown", {}, HIT)
		setTrail(b, false)
		if not F.live(b) then
			return
		end
		local at = headFloor(b)
		F.quake(b, at, 9, 1.3)
		debrisChunks(at + Vector3.new(0, 0.5, 0), 5, 18)
		dustCloud(at, 2.5, 7)
		fadeAway(crackLines(at, 4, 4, nil, nil, 0.2), 1.5, 1)
		F.hit(F.radius(at, 9, 8), {}, D.Blast, at, "Large")
		if F.free(b) then
			F.recover(b, 1.3, "TKHaul")
		end
	end

	-- THE HEAVE: right across him and back
	local function heave(b, target)
		F.halt(b)
		if not heaveOnce(b, target, "TLHeaveSet", "TLHeaveMid", "TLHeaveEnd", "TKUp", "TKCutThrough", 0.95, 5) or not F.hold(b, 0.25) then
			return
		end
		if not heaveOnce(b, target, "TLBackSet", "TLBackMid", "TLBackEnd", "TKBackSet", "TKBackThrough", 0.7, 4) then
			return
		end
		F.recover(b, 1.25, "TKHaul")
	end

	-- THE LUNGE: drawn right back, a glint down it, then all of him thrown after it, off balance, onto his front foot. He drags it back
	-- and gathers himself: your longest opening
	local function lunge(b, target)
		F.halt(b)
		if not F.beats(b, target, {
			{ "TLThrustSet", "TKThrustSet", 0.55 },
			{ "TLThrustSet", "TKThrustSet", 0.5, function()
				local _, tip = F.ends(b)
				if tip then
					burst(tip, Color3.fromRGB(240, 240, 230), 16, 0.4, 8)
				end
				playSound(b.root, SOUNDS.Unsheath, 0.8, 1.6)
			end },
		}, 0.75) then
			return
		end
		setTrail(b, true)
		F.draw(b, "TLThrust", "TKLunge", 0.1)
		playSound(b.root, SOUNDS.Lunge, 1, 0.55)
		F.step(b, 13 * K, 0.32)
		F.sweep(b, 0.32, D.Lunge, "Large", {}, HIT)
		setTrail(b, false)
		if not F.free(b) then
			return
		end
		F.draw(b, "TLStuck", "TKHaul", 0.14)
		local at = headFloor(b)
		playSound(b.root, SOUNDS.Impact, 0.7, 1.1)
		dustCloud(at, 1.6, 6)
		if F.hold(b, 1.45 * F.tempo()) then
			playSound(b.root, SOUNDS.Unsheath, 0.6, 0.6)
			F.idle(b)
			F.hold(b, 0.2)
		end
	end

	-- THE WHEEL: for when you're behind him. Sunk wide and wound away, then a whole turn on his heel with the maul held out, and he
	-- staggers out of it
	local function wheel(b, target)
		F.halt(b)
		if not F.beats(b, target, {
			{ "TLWind", "TKWind", 0.55 },
			{ "TLWind", "TKWind", 0.5, function()
				playSound(b.root, SOUNDS.Unsheath, 0.9, 0.38)
				dustCloud(F.feet(b), 2, 6)
			end },
		}, 0.55) then
			return
		end
		setTrail(b, true)
		local root = b.root
		root.Anchored = true
		local base = root.CFrame
		bodyPose(b, "TKSpin", 0.1)
		playSound(root, SOUNDS.Lunge, 1, 0.45)
		task.spawn(F.sweep, b, 0.8, D.Wheel, "Large", {}, HIT)
		local grips = { "TLSweepR", "TLSweepF", "TLSweepL", "TLSweepB", "TLSweepR" }
		for i, g in ipairs(grips) do
			if not F.live(b) then
				return
			end
			pose(b, g, 0.15, Enum.EasingStyle.Linear)
			local t0 = now()
			while now() - t0 < 0.16 do
				local a = ((i - 1) + (now() - t0) / 0.16) / #grips
				root.CFrame = base * CFrame.Angles(0, -a * math.pi * 1.5, 0)
				task.wait()
			end
		end
		setTrail(b, false)
		root.Anchored = false
		dustCloud(F.feet(b), 2, 6)
		F.recover(b, 1.3, "TKHaul")
	end

	-- THE DRAG: if you hang off. He hauls it behind him and comes at a run, sparks off the floor under it, and swings it up from
	-- the side when he gets to you. It's slow to turn: step aside as it comes
	local function charge(b, target)
		F.halt(b)
		if not F.beats(b, target, { { "TLDrag", "TKWind", 0.7, function()
			playSound(b.root, SOUNDS.Groan, 0.8, 0.5)
		end } }, 0.7) then
			return
		end
		bodyPose(b, "TKThrustSet", 0.3)
		b.hum.WalkSpeed = 26
		local t0, spark = now(), 0
		while now() - t0 < 1.7 do
			local tr = target:FindFirstChild("HumanoidRootPart")
			if not tr or not F.free(b) then
				b.hum.WalkSpeed = WALK
				return
			end
			if flat(tr.Position - b.root.Position).Magnitude < 19 then
				break
			end
			local dt = task.wait()
			F.turn(b, tr.Position, math.rad(55) * dt)
			b.hum:MoveTo(F.clamp(b.root.Position + F.fwd(b) * 12, 4))
			if now() > spark then
				spark = now() + 0.15
				local at = headFloor(b)
				burst(at + Vector3.new(0, 1, 0), Color3.fromRGB(255, 190, 110), 10, 0.25, 14)
				playSound(b.root, SOUNDS.Unsheath, 0.5, 0.5)
			end
		end
		b.hum.WalkSpeed = WALK
		F.halt(b)
		setTrail(b, true)
		playSound(b.root, SOUNDS.Lunge, 1, 0.5)
		F.step(b, 4 * K, 0.3)
		bodyPose(b, "TKCutThrough", 0.2)
		pose(b, "TLUpSide", 0.1, Enum.EasingStyle.Linear)
		task.delay(0.1, function()
			pose(b, "TLUpMid", 0.1, Enum.EasingStyle.Linear)
		end)
		task.delay(0.2, function()
			pose(b, "TLUpEnd", 0.14, Enum.EasingStyle.Quad)
			bodyPose(b, "TKOverhead", 0.2)
		end)
		F.sweep(b, 0.24, D.Charge, "Large", {}, HIT)
		setTrail(b, false)
		F.recover(b, 1.5, "TKHaul")
	end

	-- THE TOLL: the maul swung into his own bell; the note goes through the floor and you roll through it. It rattles him
	local function toll(b, target)
		F.halt(b)
		F.draw(b, "TLBellSet", "BLDraw", 0.66)
		playSound(b.root, SOUNDS.Unsheath, 0.5, 0.55)
		if not F.track(b, target, 0.95, 0.7) then
			return
		end
		F.draw(b, "TLBellHit", "BLStrike", 0.12)
		if not F.wait(b, 0.12) then
			return
		end
		bl.bellSound(b)
		FxRemote:FireAllClients("Shake", flat(b.root.Position), 0.55)
		burst(b.root.Position + Vector3.new(0, 14, 0), NOTE, 26, 0.45, 20)
		F.wave(b, flat(b.root.Position), 22, 72, D.Note, "Medium")
		F.recover(b, 1.4, "BLReel")
	end

	---------------------------------------------------------------------------
	-- phase 2: the maul's gone, and there's only the bell
	---------------------------------------------------------------------------
	-- it hits the floor where he's facing: the blast there and, if it's a big one, a ripple on out through the stone
	local function bellDown(b, radius, damage, level, ripple)
		local at = under(b, REACH)
		bl.bellSound(b, 1)
		F.quake(b, at, radius, 1.6)
		F.hit(F.radius(at, radius, 8), {}, damage, at, level)
		if ripple then
			F.wave(b, at, 20, ripple, D.Note, "Medium")
		end
	end
	local function throwBell(b, target, tell, step, radius, damage, level, ripple)
		if not F.beats(b, target, { { nil, "TP2Rear", tell, function()
			playSound(b.root, SOUNDS.Groan, 0.8, 0.45)
		end } }, tell * 0.7) then
			return false
		end
		F.draw(b, nil, "TP2Slam", 0.2)
		playSound(b.root, SOUNDS.Lunge, 1, 0.38)
		F.step(b, step, 0.2)
		if not F.wait(b, 0.2) then
			return false
		end
		bellDown(b, radius, damage, level, ripple)
		return F.free(b)
	end

	-- THE FACE SLAM: rocked right back, then the whole top of him thrown down onto you. He stays down a while
	local function faceSlam(b, target)
		F.halt(b)
		if throwBell(b, target, 0.85, 9, 9, D.Face, "Knockdown") then
			F.recover(b, 1.7, "TP2Stuck")
		end
	end

	-- THE PROCESSION: three of them, each from where the last one left him, coming down the room at you. The last rings through the
	-- floor, and then he's spent: your longest opening
	local function procession(b, target)
		F.halt(b)
		if not throwBell(b, target, 0.8, 12, 8, D.Line, "Large") or not throwBell(b, target, 0.5, 12, 8, D.Line, "Large") or not throwBell(b, target, 0.5, 12, 9.5, D.Face, "Knockdown", 34) then
			return
		end
		F.recover(b, 2.5, "TP2Stuck")
	end

	-- THE LEAP: if you run. Sunk right down, then the length of the room in the air, to come down bell first on where you stood
	local function leap(b, target)
		F.halt(b)
		if not F.beats(b, target, { { nil, "TP2Crouch", 0.8, function()
			playSound(b.root, SOUNDS.Groan, 1, 0.4)
			dustCloud(F.feet(b), 2, 6)
		end } }, 0.8) then
			return
		end
		local tr = target:FindFirstChild("HumanoidRootPart")
		if not tr then
			return
		end
		local from = b.root.Position
		local rel = flat(tr.Position - from)
		local to = F.clamp(flat(tr.Position) - (rel.Magnitude > 0.1 and rel.Unit or F.fwd(b)) * REACH, 8)
		playSound(b.root, SOUNDS.Lunge, 1, 0.34)
		dustCloud(F.feet(b), 3, 8)
		bodyPose(b, "TP2Air", 0.15)
		local diving = false
		if not F.arc(b, from, Vector3.new(to.X, from.Y, to.Z), 1, 24, function(t)
			if t > 0.65 and not diving then
				diving = true
				bodyPose(b, "TP2Slam", 0.3)
			end
		end) or not F.live(b) then
			return
		end
		bellDown(b, 10, D.Leap, "Knockdown", 44)
		F.recover(b, 2, "TP2Stuck")
	end

	-- THE RATTLE: get under him or behind him and he seizes the bell in both hands and wrenches it: no reach, little warning
	local function rattle(b, target)
		F.halt(b)
		if not F.beats(b, target, { { nil, "TP2Clutch", 0.55, function()
			playSound(b.root, SOUNDS.Unsheath, 0.9, 0.5)
		end } }, 0.2) then
			return
		end
		bodyPose(b, "BLReel", 0.08)
		local c = flat(b.root.Position)
		bl.bellSound(b, 1)
		FxRemote:FireAllClients("Shake", c, 0.7)
		burst(b.root.Position + Vector3.new(0, 14, 0), NOTE, 26, 0.45, 20)
		dustCloud(c, 3, 8)
		F.hit(F.radius(c, 14, 10), {}, D.Rattle, c, "Large")
		F.recover(b, 1.1, "BLReel")
	end

	local function idle(b)
		if F.phase2() then
			bodyPose(b, "TP2Stalk", 0.5)
			return
		end
		pose(b, "TLRest", 0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		bodyPose(b, "TKIdle", 0.55)
	end
	local function onStagger(b)
		if F.phase2() then
			bodyPose(b, "TP2Clutch", 0.15)
		else
			pose(b, "TLPlant", 0.2)
			bodyPose(b, "TKReel", 0.15)
		end
		bl.bellSound(b, 0.7)
	end
	-- the real weapon goes (his arms are their own again: the Puppeteer only poses hands onto a weapon he has) and a copy falls where
	-- he stood, lying on its haft and head, for the rest of the fight
	local function dropMaul(b)
		local copy, handle = F.cloneWeapon(b)
		local held = b.model:FindFirstChild("Weapon")
		if held then
			held:Destroy()
		end
		b.weld = nil
		if not copy then
			return
		end
		local trail = copy:FindFirstChildWhichIsA("Trail", true)
		if trail then
			trail:Destroy()
		end
		local along = flat(b.root.CFrame.RightVector).Unit -- (from the hands toward the head)
		local up = -(along * math.cos(0.113) + Vector3.yAxis * math.sin(0.113)) -- (the head's fatter than the pommel: lying, it's tilted so)
		local right = along:Cross(Vector3.yAxis)
		local at = F.clamp(flat(b.root.Position) + along * 4, 20)
		TweenService:Create(handle, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.fromMatrix(at + Vector3.new(0, 2.35, 0), right, up, right:Cross(up)) }):Play()
		task.delay(0.5, function()
			if F.live(b) then
				F.quake(b, at + along * 3.8 * S, 5, 0.9)
			end
		end)
	end
	-- the entrance: bowed over his maul at the far end. He raises it and rings the fight in
	local function intro(b)
		pose(b, "TLPlant", 0.2)
		bodyPose(b, "TKReel", 0.2)
		task.wait(0.8)
		playSound(b.root, SOUNDS.Groan, 1, 0.4)
		bodyPose(b, "BLDraw", 1.1)
		pose(b, "TLBellSet", 1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		task.wait(1.15)
		pose(b, "TLBellHit", 0.1)
		bodyPose(b, "BLStrike", 0.1)
		task.wait(0.1)
		bl.bellSound(b, 1)
		FxRemote:FireAllClients("Shake", b.root.Position, 0.7)
		task.wait(0.8)
		idle(b)
		task.wait(0.4)
	end
	-- phase 2: he strikes it once too hard. The bell cracks, and the maul falls out of his hands
	local function phase2(b)
		F.halt(b)
		F.draw(b, "TLBellSet", "BLDraw", 0.5)
		if not F.wait(b, 0.65) then
			return
		end
		F.draw(b, "TLBellHit", "BLCracked", 0.1)
		if not F.wait(b, 0.1) then
			return
		end
		bl.bellSound(b, 1)
		FxRemote:FireAllClients("Shake", b.root.Position, 1)
		for _, c in ipairs(b.model:GetChildren()) do
			if c:IsA("BasePart") and c.Name == "BellCrack" then
				c.Transparency = 0
				burst(c.Position, NOTE, 22, 0.45, 18)
			end
		end
		F.wave(b, flat(b.root.Position), 22, 72, D.Note, "Medium")
		if not F.wait(b, 0.5) then
			return
		end
		dropMaul(b)
		bodyPose(b, "TP2Clutch", 0.25)
		playSound(b.root, SOUNDS.Groan, 1, 0.34)
		F.wait(b, 1.3)
		F.idle(b)
	end

	Fight.define({
		id = "Tollkeeper",
		label = "Bell Warden",
		kind = M.Kind,
		scale = S,
		weapon = "TollMaul",
		idleGrip = "TLRest",
		hp = 1200,
		poise = 180,
		stagger = 2.6,
		radius = 2.4 * K,
		walk = WALK,
		walk2 = 16.5,
		turn = 82,
		rest = { 0.55, 1.25 },
		keep = { 15, 25 },
		keep2 = { 7, 11 },
		phase2At = 0.5,
		tempo2 = 0.88,
		restMult2 = 0.5,
		moves = {
			{ name = "Heave", fn = heave, min = 0, max = 26, weight = 5, cd = 1.5, fast = true, phase1 = true },
			{ name = "Slam", fn = slam, min = 0, max = 34, weight = 3.5, cd = 6, phase1 = true },
			{ name = "Lunge", fn = lunge, min = 10, max = 40, weight = 4, cd = 5, phase1 = true },
			{ name = "Wheel", fn = wheel, min = 0, max = 22, weight = 2, cd = 7, behind = true, phase1 = true },
			{ name = "Drag", fn = charge, min = 28, max = 80, weight = 4, cd = 7, phase1 = true },
			{ name = "Toll", fn = toll, min = 18, max = 95, weight = 3.5, cd = 8, phase1 = true },
			{ name = "FaceSlam", fn = faceSlam, min = 0, max = 26, weight = 6, cd = 2.5, fast = true, phase2 = true },
			{ name = "Procession", fn = procession, min = 8, max = 38, weight = 4, cd = 9, phase2 = true },
			{ name = "Leap", fn = leap, min = 26, max = 95, weight = 6, cd = 7, phase2 = true },
			{ name = "Rattle", fn = rattle, min = 0, max = 13, weight = 2, cd = 5, behind = true, phase2 = true },
		},
		onSpawn = keepAboveFloor,
		idle = idle,
		onStagger = onStagger,
		intro = intro,
		phase2 = phase2,
	})
end

return M
