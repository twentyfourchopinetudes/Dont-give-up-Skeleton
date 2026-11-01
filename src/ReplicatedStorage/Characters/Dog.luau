--!nonstrict
-- DOG: the prison's hounds, gone feral in the Ruined Township: big, lean, black-and-rust
-- Dobermans, and never where you want them. They hunt in packs and won't stand and
-- trade: they dart round you, fake a lunge and spring away, vault right over you, and
-- come straight back in.
-- Built on the shared skeleton down on all fours: the torso pitched flat, the arms
-- as forelegs (pointed straight down; the walk cycle swings them against the legs),
-- the neck bent back up so it looks ahead. The skeleton's boxes are hidden under the
-- body built in M.Look. No weapon: the jaws are the weapon.
--
-- THE MOVESET (M.attack, which the shared brain calls once it's in range): a short
-- chain of 1-3 beats, then it circles you for a moment before the next one:
--   Side dash  a quick dash round to your side
--   Feint      a crouch, a snarl, half a lunge... then it springs away
--   Vault      a long, low leap past you to land behind you, then a bite
--   Bite       dashes in, a short crouch, a nip (a short stagger), then springs away
--   Leap       from well out: a crouch, then a long, flat leap straight at you
--   Grab       dashes in low and lunges; if the jaws close on you it hauls you off your
--              feet and holds you up, then shakes you side to side and flings you down
--              (roll the lunge; a stagger on it drops you)
-- Every bite builds BREAK on you (Config.Break: full, every hit does more).
--   Notice     the first time it sees you (from as far as it can see): it slowly turns
--              its head your way, freezes, and comes for you with the Leap
-- Not much health, but it takes two light hits (or a heavy) to stagger it, and it barely
-- pauses between attacks. It barks and growls through the fight (Def.Sounds, at random).
-- Dogs keep clear of each other (their roots run the length of the body, and their
-- dashes steer round each other).
--
-- EVERYTHING ABOUT THIS CHARACTER IS IN THIS ONE FILE (see Hollow.lua for the layout).
local M = {}
M.Kind = "Dog"
-- (turnBend: it curls into its turns, waist and neck, this much per radian a second of turning)
M.Proportions = { girth = 0.78, arm = 1.18, hunch = 0, torso = 1.485, turnBend = 0.25 } -- the lean Doberman: a long body, long legs
M.IdlePose = "DProwl"
-- every pose keeps the forelegs straight down under the pitched torso: la1 = ra1 ~ lean
M.Poses = {
	DProwl = { drop = 0.7, lean = 1.5, head = -0.85, la1 = 1.5, ra1 = 1.5, la3 = 0, ra3 = 0, lel = 0.25, rel = 0.25, freeL = 1, footR = -0.3, footL = -0.1, breathe = 2.5 },
	DCrouch = { drop = 1.0, lean = 1.62, head = -0.6, la1 = 1.95, ra1 = 1.95, la3 = 0, ra3 = 0, lel = 0.65, rel = 0.65, freeL = 0, footR = -0.6, footL = -0.4, breathe = 4 },
	DBite = { drop = 0.5, lean = 1.35, head = -1.2, la1 = 1.05, ra1 = 1.05, la3 = 0, ra3 = 0, lel = 0.15, rel = 0.15, freeL = 0, footR = -0.9, footL = -0.7 },
	DLeap = { drop = 0.35, lean = 1.4, head = -1.05, tuck = 0.4, la1 = 2.3, ra1 = 2.3, la3 = 0, ra3 = 0, lel = 0.1, rel = 0.1, freeL = 0 },
	DHowl = { drop = 1.05, lean = 0.75, head = -1.6, la1 = 0.75, ra1 = 0.75, la3 = 0, ra3 = 0, lel = 0.1, rel = 0.1, freeL = 0, footR = 0.2, footL = 0.2, breathe = 3 },
	DYelp = { drop = 0.85, lean = 1.25, side = 0.25, twist = 0.4, head = -0.45, la1 = 1.35, ra1 = 1.35, la3 = 0, ra3 = 0, lel = 0.4, rel = 0.4, freeL = 0 },
	DDash = { drop = 0.85, lean = 1.55, side = 0.1, head = -0.8, la1 = 1.6, ra1 = 1.6, la3 = 0, ra3 = 0, lel = 0.3, rel = 0.3, freeL = 1, footR = -0.5, footL = -0.2 },
}
M.Colors = { skin = Color3.fromRGB(92, 80, 66), torso = Color3.fromRGB(92, 80, 66), legs = Color3.fromRGB(86, 74, 62), arms = Color3.fromRGB(86, 74, 62) }
M.FistSkin = true

function M.Look(k)
	-- the lean Doberman: black and rust, a deep chest tapering to a tucked waist, a long
	-- neck and narrow head, tall ears, long legs, a docked tail, faint ribs under the chest
	local deco, parts, at, rgb, D, s = k.deco, k.parts, k.at, k.rgb, k.D, k.s
	local ch, hd, la, ua = k.ch, k.hd, k.la, k.ua
	local thigh, shin = D.thigh / s, D.shin / s
	local FUR = Enum.Material.Fabric
	local BALL, CYL = Enum.PartType.Ball, Enum.PartType.Cylinder
	local ALONG = CFrame.Angles(0, 0, math.pi / 2) -- a cylinder along its part's Y (a limb, the spine)
	local FACE = CFrame.Angles(0, math.pi / 2, 0) -- a cylinder along its part's Z (the head's -Z is its face)
	local coat, rust = rgb(34, 30, 30), rgb(140, 82, 42)

	-- the skeleton's boxes (and the shared fists) stay as the joints; the body hides them.
	-- The root runs the length of the body, so dogs can't stand inside each other.
	for _, p in pairs(parts) do
		if p.Name ~= "HumanoidRootPart" then
			p.Transparency = 1
		end
	end
	for _, d in ipairs(parts.Chest.Parent:GetChildren()) do
		if d.Name == "Fist" then
			d.Transparency = 1
		end
	end
	parts.HumanoidRootPart.Size = Vector3.new(2, 2, 4.8) * s

	local function ball(on, d, x, y, z, color, mat)
		return deco(on, "Body", Vector3.new(d, d, d) * s, at(x, y, z), color, mat or FUR, BALL)
	end
	local function cyl(on, len, d, cf, color, mat) -- runs along cf's X
		return deco(on, "Body", Vector3.new(len, d, d) * s, cf, color, mat or FUR, CYL)
	end
	local function box(on, sx, sy, sz, cf, color)
		return deco(on, "Body", Vector3.new(sx, sy, sz) * s, cf, color, FUR)
	end
	local function capsule(on, len, d, x, y, z, color) -- down the part's Y, rounded ends
		cyl(on, len, d, at(x, y, z) * ALONG, color)
		ball(on, d, x, y + len / 2, z, color)
		ball(on, d, x, y - len / 2, z, color)
	end

	-- the body (the chest lies along the spine when it's down on all fours: its +Y runs
	-- forward, its +Z faces up, so its -Z is the underside)
	local chest, waist = 1.2, 0.78
	ball("Chest", chest + 0.15, 0, ch * 0.3, -0.08, coat)
	cyl("Chest", ch * 0.45, chest, at(0, ch * 0.05, 0.05) * ALONG, coat)
	cyl("Chest", ch * 0.45, waist, at(0, -ch * 0.35, 0.22) * ALONG, coat)
	ball("Chest", waist + 0.02, 0, -ch * 0.55, 0.22, coat)
	ball("Chest", 0.8, 0, ch * 0.45, -0.45, rust) -- rust on the chest
	for _, sx in ipairs({ -1, 1 }) do
		ball("Chest", 0.74, sx * 0.57, ch * 0.33, -0.05, coat)
	end
	-- ribs: low ridges curving under the chest (a dog's ribs face the ground), a shade off the coat
	local ridge = coat:Lerp(rgb(150, 140, 130), 0.12)
	local r = chest / 2
	for i = 0, 4 do
		local y = ch * 0.22 - i * ch * 0.1
		for _, sx in ipairs({ -1, 1 }) do
			for j = 0, 2 do
				local a = 0.35 + j * 0.45 -- measured from straight down
				cyl("Chest", 0.34, 0.11, at(sx * math.sin(a) * r, y, 0.05 - math.cos(a) * r) * CFrame.Angles(0, -sx * a, 0), ridge)
			end
		end
	end
	ball("Hips", 1.0, 0, 0.1, 0.12, coat)
	cyl("Chest", 1.0, 0.75, at(0, ch * 0.66, 0.35) * CFrame.Angles(math.rad(50), 0, 0) * ALONG, coat) -- long neck

	-- a long, narrow head, rust muzzle, tall pointed ears, eyes set into the skull
	ball("Head", 0.95, 0, 0.12, 0.08, coat)
	cyl("Head", 0.9, 0.66, at(0, -0.02, -0.6) * FACE, coat)
	cyl("Head", 0.5, 0.5, at(0, -0.06, -1.15) * FACE, rust)
	for _, sx in ipairs({ -1, 1 }) do
		box("Head", 0.1, 0.75, 0.3, at(sx * 0.28, 0.72, 0.1) * CFrame.Angles(-0.1, 0, sx * 0.12), coat)
		local ex, ey, ez = sx * 0.3, 0.2, -0.3
		local eye = ball("Head", 0.22, ex, ey, ez, rgb(46, 30, 20), Enum.Material.SmoothPlastic)
		eye.Reflectance = 0.25
		box("Head", 0.3, 0.12, 0.3, at(ex * 0.95, ey + 0.13, ez - 0.02) * CFrame.Angles(0, 0, -sx * 0.25), coat) -- brow
		cyl("Head", 0.04, 0.3, at(ex * 1.02, ey, ez) * CFrame.Angles(0, sx * 0.9, 0), rust) -- rust ring round the eye
		ball("Head", 0.18, sx * 0.22, 0.36, -0.36, rust) -- the rust spot above it
	end

	-- long legs: black above, rust below
	for _, n in ipairs({ "R", "L" }) do
		capsule(n .. "UpperArm", ua * 0.8, 0.66, 0, 0, 0, coat)
		capsule(n .. "LowerArm", la * 0.85, 0.52, 0, 0, 0, rust)
		ball(n .. "LowerArm", 0.6, 0, -la / 2 - 0.05, -0.12, rust)
		capsule(n .. "Thigh", thigh * 0.75, 0.85, 0, 0, 0.05, coat)
		capsule(n .. "Shin", shin * 0.85, 0.52, 0, 0, 0, rust)
		ball(n .. "Foot", 0.6, 0, 0, -0.12, rust)
	end
	ball("Hips", 0.34, 0, 0.45, hd / 2 + 0.3, coat) -- docked tail
end

-- stats (the shared brain in GameServer/Enemies.lua reads these). Engage = how close
-- before it starts on you (circling counts as attacking, so this is wide).
M.Def = {
	HP = 77, Speed = 24, Scale = 1.7, Damage = 7, Range = 6.5, HalfAngle = 65,
	Windup = 0.2, Recover = 0.15, Aggro = 38, Leash = 75, Stagger = 0.3, Engage = 20,
	NoticeRange = 38, -- (the shared brain hands it over this far out, the first time, to notice you)
	HyperArmor = false, Weapon = nil, Radius = 2.6, StaggerPush = 26,
	Poise = 22, HitLevel = "Stagger", -- (a sword's light chips 12: two of them stagger it)
	PounceDamage = 11, PounceLevel = "Stagger",
	LeapFrom = { 11, 20 }, -- how far out it leaps at you from
	LeapSpeed = 46, -- studs per second across the ground: long and flat, not high
	DashSpeed = 36, -- darting in, round to your side, springing away
	Beats = { 1, 4 }, -- moves strung together before it circles for a breath
	Rest = { 0.35, 0.8 }, -- that breath (seconds of circling)
	-- the grab: each bite while it has you, how often; how long it holds you up (GrabLift
	-- studs off the floor), how long it shakes you, then the throw (a knockdown)
	GrabDamage = 4, GrabEvery = 0.42, GrabHold = 1.3, GrabShake = 0.9, GrabLift = 3, ThrowDamage = 9,
	-- Break built on you (Config.Break): per bite, per bite of the grab
	BreakBite = 40, BreakGrab = 5, -- (a whole grab: ~30, about a third of the meter)
	-- its barks and growls, one picked at random every time it gives voice
	Sounds = {
		"rbxassetid://123024926216748", "rbxassetid://18782585213", "rbxassetid://135945662287888",
		"rbxassetid://135016436724006", "rbxassetid://82717166507256", "rbxassetid://18768461312",
	},
	Spacing = 7, -- studs it keeps from other dogs when it picks where to dash
	TurnRate = 600, -- degrees a second it can turn: quick, but never a snap
	SpringAway = { 14, 18 }, -- how far it springs back off you after a move
}

---------------------------------------------------------------------------
-- server: how it fights
---------------------------------------------------------------------------
local bodyPose, playSound, SOUNDS, now, faceTowards, turnTowards, flat, playersInSector, playersInRadius, damagePlayer, dustCloud, EnemiesFolder, breakPlayer
local rng = Random.new()

-- nudge a destination away from the other dogs, so the pack spreads round you
local function clearOfPack(e, dest)
	local push = Vector3.zero
	for _, m in ipairs(EnemiesFolder:GetChildren()) do
		if m ~= e.model and m:GetAttribute("PrisonRig") == "Dog" then
			local r = m:FindFirstChild("HumanoidRootPart")
			if r then
				local rel = flat(dest - r.Position)
				if rel.Magnitude < e.def.Spacing then
					push += (rel.Magnitude > 0.1 and rel.Unit or Vector3.xAxis) * (e.def.Spacing - rel.Magnitude)
				end
			end
		end
	end
	return dest + push
end

-- turn quick, never snap: at most Def.TurnRate degrees a second toward pos
local function turnTo(e, pos, dt)
	turnTowards(e.root, pos, math.rad(e.def.TurnRate) * dt)
end

-- a burst of speed toward dest, turning into it as it goes
local function dash(e, dest, dur, hop)
	local hum, root = e.hum, e.root
	dest = clearOfPack(e, dest)
	hum.AutoRotate = false
	hum.WalkSpeed = e.def.DashSpeed
	hum:MoveTo(dest)
	if hop then
		local dir = flat(dest - root.Position)
		dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.zero
		root.AssemblyLinearVelocity = dir * e.def.DashSpeed + Vector3.new(0, hop, 0)
	end
	local t0 = now()
	while now() - t0 < dur and e.alive and now() >= e.staggerUntil do
		if flat(dest - root.Position).Magnitude < 1.5 then
			break
		end
		turnTo(e, dest, task.wait())
	end
	hum.WalkSpeed = e.def.Speed
end

-- spring away from the target (a little sideways, a little air)
local function springAway(e, tRoot)
	local away = flat(e.root.Position - tRoot.Position)
	away = away.Magnitude > 0.1 and away.Unit or -flat(e.root.CFrame.LookVector).Unit
	away = CFrame.Angles(0, rng:NextNumber(-0.7, 0.7), 0):VectorToWorldSpace(away)
	bodyPose(e, "DLeap", 0.12)
	dash(e, e.root.Position + away * rng:NextNumber(e.def.SpringAway[1], e.def.SpringAway[2]), 0.5, 14)
	bodyPose(e, "DDash", 0.15)
end

-- dash round to one side of the target, at a few strides
local function sideDash(e, tRoot)
	local rel = flat(e.root.Position - tRoot.Position)
	if rel.Magnitude < 0.1 then
		rel = Vector3.xAxis
	end
	local r = math.clamp(rel.Magnitude, 8, 12)
	local turn = (rng:NextNumber() < 0.5 and 1 or -1) * rng:NextNumber(0.7, 1.2)
	bodyPose(e, "DDash", 0.15)
	dash(e, tRoot.Position + CFrame.Angles(0, turn, 0):VectorToWorldSpace(rel.Unit) * r, 0.4)
end

-- a bark or a growl, one of Def.Sounds at random (pitch varies it a little more)
local function snarl(e, pitch)
	local list = e.def.Sounds
	if list and #list > 0 then
		playSound(e.root, list[rng:NextInteger(1, #list)], 0.7, (pitch or 1) * rng:NextNumber(0.92, 1.08))
	end
end

function M.attack(e, targetChar)
	local def = e.def
	local hum, root = e.hum, e.root
	local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
	if not tRoot then
		return
	end
	e.attacking = true
	local function ok()
		return e.alive and now() >= e.staggerUntil and tRoot.Parent ~= nil
	end
	local function finish()
		hum.AutoRotate = true
		hum.WalkSpeed = def.Speed
		if e.alive then
			bodyPose(e, "Idle", 0.25)
		end
		e.attacking = false
	end
	-- stand still and face it for t seconds (wind-ups)
	local function hold(t)
		hum:MoveTo(root.Position)
		hum.AutoRotate = false
		local t0 = now()
		while now() - t0 < t do
			if not ok() then
				return false
			end
			turnTo(e, tRoot.Position, task.wait())
		end
		return true
	end

	-- between chains: circle round you at a run, watching, for a moment
	if now() < (e.restUntil or 0) then
		local dir = e.circleDir or 1
		while now() < e.restUntil and ok() do
			local rel = flat(root.Position - tRoot.Position)
			if rel.Magnitude < 0.1 then
				rel = Vector3.xAxis
			end
			local r = math.clamp(rel.Magnitude, 9, 13)
			hum.AutoRotate = false
			local goal = clearOfPack(e, tRoot.Position + CFrame.Angles(0, dir * 0.6, 0):VectorToWorldSpace(rel.Unit) * r)
			hum:MoveTo(goal)
			if rng:NextNumber() < 0.05 then
				snarl(e) -- (barking at you as it circles)
			end
			local t0 = now()
			while now() - t0 < 0.15 and ok() do -- (turning into its run, a frame at a time)
				turnTo(e, goal, task.wait())
			end
		end
		return finish()
	end

	-- dash in close, a short crouch, the nip, then spring away
	local function bite()
		local d = flat(tRoot.Position - root.Position).Magnitude
		if d > def.Range - 1.5 then
			local dir = flat(tRoot.Position - root.Position).Unit
			bodyPose(e, "DDash", 0.12)
			dash(e, tRoot.Position - dir * (def.Range - 3), 0.55)
		end
		if not ok() then
			return
		end
		bodyPose(e, "DCrouch", 0.12)
		snarl(e)
		if not hold(def.Windup) then
			return
		end
		bodyPose(e, "DBite", 0.08)
		playSound(root, SOUNDS.Impact, 0.4, 1.8)
		root.AssemblyLinearVelocity = flat(root.CFrame.LookVector) * def.DashSpeed * 0.7 + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
		task.wait(0.1)
		if not e.alive then
			return
		end
		for _, pl in ipairs(playersInSector(root.CFrame, def.Range, def.HalfAngle, 6)) do
			if damagePlayer(pl, def.Damage, root.Position, def.HitLevel) then
				breakPlayer(pl, def.BreakBite)
			end
		end
		task.wait(def.Recover)
		if ok() then
			springAway(e, tRoot)
		end
	end

	-- the grab: in low, a lunge, and if the jaws close on you it rears its head and hauls
	-- you right off your feet, holds you up there, then shakes you side to side and flings
	-- you down (a knockdown). You're held the whole time (anchored where its jaws are, the
	-- "Grabbed" hit reaction keeping you stunned: each bite before the last one's wears off).
	-- A stagger on it drops you.
	local function grab()
		local d = flat(tRoot.Position - root.Position).Magnitude
		if d > def.Range - 1.5 then
			local dir = flat(tRoot.Position - root.Position).Unit
			bodyPose(e, "DDash", 0.12)
			dash(e, tRoot.Position - dir * (def.Range - 3), 0.55)
		end
		if not ok() then
			return
		end
		bodyPose(e, "DCrouch", 0.12)
		snarl(e, 0.9)
		if not hold(def.Windup + 0.12) then
			return
		end
		bodyPose(e, "DBite", 0.08)
		root.AssemblyLinearVelocity = flat(root.CFrame.LookVector) * def.DashSpeed * 0.8 + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
		task.wait(0.1)
		if not e.alive then
			return
		end
		local caught
		for _, pl in ipairs(playersInSector(root.CFrame, def.Range, 45, 6)) do
			if damagePlayer(pl, def.GrabDamage, root.Position, "Grabbed") then
				caught = pl
				break
			end
		end
		local hrp = caught and caught.Character and caught.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			task.wait(def.Recover)
			if ok() then
				springAway(e, tRoot)
			end
			return
		end
		breakPlayer(caught, def.BreakGrab)
		-- latched: the dog plants, and you go where its jaws go
		local look = flat(hrp.Position - root.Position)
		look = look.Magnitude > 0.1 and look.Unit or flat(root.CFrame.LookVector).Unit
		local base = CFrame.lookAt(root.Position, root.Position + look)
		local floorY = hrp.Position.Y
		root.Anchored, hrp.Anchored = true, true
		bodyPose(e, "DHowl", 0.18) -- head thrown up, you hanging off it
		local lastBite = now()
		local function bite()
			if now() - lastBite >= def.GrabEvery then
				lastBite = now()
				damagePlayer(caught, def.GrabDamage, root.Position, "Grabbed")
				breakPlayer(caught, def.BreakGrab)
				if rng:NextNumber() < 0.5 then
					snarl(e, 0.9)
				end
			end
		end
		-- where you hang: out in front of its jaws, lifted (k = how far up yet), swung by yaw
		local function hang(yaw, k)
			local at = (base * CFrame.Angles(0, yaw, 0) * CFrame.new(0, 0, -(def.Radius + 1.1))).Position
			local p = Vector3.new(at.X, floorY + def.GrabLift * k, at.Z)
			hrp.CFrame = CFrame.lookAt(p, Vector3.new(root.Position.X, p.Y, root.Position.Z)) * CFrame.Angles(0.3 * k, 0, math.sin(now() * 9) * 0.08 * k) -- (dangling, kicking)
		end
		local held = pcall(function()
			local t0 = now()
			while ok() and hrp.Parent and now() - t0 < def.GrabHold do -- hauled up, and held there
				hang(0, math.min(1, (now() - t0) / 0.25))
				bite()
				task.wait()
			end
			local t1 = now()
			while ok() and hrp.Parent and now() - t1 < def.GrabShake do -- then shaken, side to side
				local yaw = math.sin((now() - t1) * math.pi * 2 * 2.5) * 0.55
				root.CFrame = base * CFrame.Angles(0, yaw * 0.7, 0)
				hang(yaw, 1)
				bite()
				task.wait()
			end
		end)
		-- (whatever happened, nobody stays stuck in the air)
		if hrp.Parent then
			hrp.Anchored = false
		end
		root.Anchored = false
		if not held or not ok() then
			return -- (staggered off you, or it died)
		end
		-- flung down: wait out the last bite's grace so the throw lands, then the knockdown
		task.wait(math.max(0, def.GrabEvery - (now() - lastBite)))
		if ok() and hrp.Parent then
			damagePlayer(caught, def.ThrowDamage, root.Position, "Knockdown")
			snarl(e)
			springAway(e, tRoot)
		end
	end

	-- the crouch and the snarl, half a lunge... and it springs away instead
	local function feint()
		bodyPose(e, "DCrouch", 0.12)
		snarl(e)
		if not hold(def.Windup) then
			return
		end
		bodyPose(e, "DBite", 0.08)
		local dir = flat(tRoot.Position - root.Position)
		root.AssemblyLinearVelocity = (dir.Magnitude > 0.1 and dir.Unit or Vector3.zero) * def.DashSpeed * 0.5
		task.wait(0.12)
		if ok() then
			springAway(e, tRoot)
		end
	end

	-- a long, low arc to `land`: fast across the ground, only a few studs high. Hits anyone
	-- it passes through if `damage` is set. Returns false if it was stopped.
	local function arcTo(land, damage)
		local horiz = flat(land - root.Position)
		local T = math.clamp(horiz.Magnitude / def.LeapSpeed, 0.28, 0.6)
		bodyPose(e, "DLeap", 0.08)
		playSound(root, SOUNDS.Lunge, 0.55, 1.35)
		hum.AutoRotate = false
		hum:MoveTo(land)
		root.AssemblyLinearVelocity = horiz / T + Vector3.new(0, workspace.Gravity * T / 2, 0)
		local hit, t0 = {}, now()
		while now() - t0 < T + 0.08 and e.alive do
			if damage then
				for _, pl in ipairs(playersInRadius(root.Position, 2.4 * def.Scale, 6)) do
					if not hit[pl] then
						hit[pl] = true
						if damagePlayer(pl, damage, root.Position, def.PounceLevel) then
							breakPlayer(pl, def.BreakBite)
						end
					end
				end
			end
			turnTo(e, land, task.wait())
		end
		if e.alive then
			dustCloud(root.Position - Vector3.new(0, 2.5, 0), 2, 4)
		end
		return ok()
	end

	-- a long, low leap past you (over your shoulder), landing behind you; then a bite
	local function vault()
		bodyPose(e, "DCrouch", 0.12)
		snarl(e)
		if not hold(0.22) then
			return
		end
		local across = flat(tRoot.Position - root.Position)
		across = across.Magnitude > 0.1 and across.Unit or flat(root.CFrame.LookVector).Unit
		local side = Vector3.new(-across.Z, 0, across.X) * (rng:NextNumber() < 0.5 and -1 or 1) * rng:NextNumber(2.5, 4)
		if arcTo(clearOfPack(e, tRoot.Position + across * rng:NextNumber(6, 9) + side)) then
			bite() -- turns on you where you stand
		end
	end

	-- from well out: a crouch, then a long, flat leap straight at you
	local function leap()
		bodyPose(e, "DCrouch", 0.15)
		snarl(e)
		if not hold(0.35) then
			return
		end
		local toward = flat(tRoot.Position - root.Position)
		toward = toward.Magnitude > 0.1 and toward.Unit or flat(root.CFrame.LookVector).Unit
		if arcTo(tRoot.Position - toward * 1.5, def.PounceDamage) then
			bodyPose(e, "DCrouch", 0.12)
			task.wait(0.2)
			if ok() then
				springAway(e, tRoot)
			end
		end
	end

	-- the first time it sees you: it slowly turns your way, head up, freezes as it
	-- notices you, then closes to leaping range and comes for you with the Leap
	if not e.noticed then
		e.noticed = true
		hum:MoveTo(root.Position)
		hum.AutoRotate = false
		bodyPose(e, "DHowl", 0.8) -- head up, listening
		local t0 = now()
		while now() - t0 < 1.3 and ok() do
			local dt = task.wait()
			turnTowards(root, tRoot.Position, 2.2 * dt)
		end
		if not ok() then
			return finish()
		end
		bodyPose(e, "DCrouch", 0.15) -- it has seen you
		snarl(e, 0.95)
		task.wait(0.35)
		local far = def.LeapFrom[2]
		local dist = flat(tRoot.Position - root.Position).Magnitude
		if dist > far and ok() then
			bodyPose(e, "DDash", 0.12)
			local dir = flat(tRoot.Position - root.Position).Unit
			dash(e, tRoot.Position - dir * (far - 2), (dist - far + 2) / def.DashSpeed + 0.3)
		end
		if ok() then
			leap()
		end
		e.restUntil = now() + rng:NextNumber(def.Rest[1], def.Rest[2])
		e.circleDir = rng:NextNumber() < 0.5 and -1 or 1
		return finish()
	end

	-- a short string of moves, always ending in a real attack
	local beats = rng:NextInteger(def.Beats[1], def.Beats[2])
	for i = 1, beats do
		if not ok() then
			break
		end
		local last = i == beats
		local d = flat(tRoot.Position - root.Position).Magnitude
		local r = rng:NextNumber()
		if not last and r < 0.35 then
			sideDash(e, tRoot)
		elseif not last and r < 0.6 then
			feint()
		elseif d >= def.LeapFrom[1] and d <= def.LeapFrom[2] and r < 0.85 then
			leap()
		elseif r < 0.62 then
			vault()
		elseif r < 0.92 then
			grab()
		else
			bite()
		end
	end

	e.restUntil = now() + rng:NextNumber(def.Rest[1], def.Rest[2])
	e.circleDir = rng:NextNumber() < 0.5 and -1 or 1
	finish()
end

-- a hit makes it yelp (the shared brain has already staggered it and knocked it back)
function M.onStagger(e)
	bodyPose(e, "DYelp", 0.08)
	e.root.Anchored = false -- (a stagger knocks it off you mid-grab)
	snarl(e, 1.25) -- (pitched up: a yelp)
end

function M.init(core)
	bodyPose, playSound, SOUNDS, now, faceTowards, turnTowards, flat = core.bodyPose, core.playSound, core.SOUNDS, core.now, core.faceTowards, core.turnTowards, core.flat
	playersInSector, playersInRadius, damagePlayer, dustCloud, EnemiesFolder = core.playersInSector, core.playersInRadius, core.damagePlayer, core.dustCloud, core.EnemiesFolder
	breakPlayer = core.breakPlayer
end

return M
