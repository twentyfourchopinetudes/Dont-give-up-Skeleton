--!nonstrict
-- SKELETON: a jailer's remains that never stopped walking. Twitchy, brittle.
-- Up close: a slow, rattling, telegraphed swipe - or the same rattle cut short into
-- a quick stab (the feint) - or two quick cuts, there and back; and as often as not a
-- skip sideways first, so it doesn't come from where it stood. From a little off: a
-- coiled lunging thrust, or a leap and a chop down. From further: one of its own ribs
-- pulled out and thrown, or a scuttle in and the lunge off the end of it. Then a hop back.
--
-- EVERYTHING ABOUT THIS CHARACTER IS IN THIS ONE FILE:
--   M.Proportions / M.Poses   body shape and its full-body poses (the client animator uses these too)
--   M.Colors / M.Look         how the rig is dressed (RigBuilder calls Look with a kit of helpers:
--                             deco(part, name, size, offset, color, material?, shape?), V(x,y,z), at(x,y,z) ...)
--   M.Weapons / M.Grips       the weapon's model, and the grip poses its swings tween between
--   M.init(Core) and below    behaviour (server only)
-- SHARED TOOLKIT: server code here gets the shared helpers through M.init(Core)
-- (see the list at the top of ServerScriptService/GameServer/Core.lua). Body
-- poses not defined here (Idle, Windup, Strike, SweepWindup, SweepEnd, Recover,
-- Flinch, Stagger, Crouch, Air, Roar, Kneel) are shared ones from PuppetMath.
local M = {}
M.Kind = "Skeleton"
M.Proportions = { girth = 0.62, arm = 1.1, hunch = 0.16 } -- rattling bones: thin, long-armed
M.Poses = {
	-- a low sidelong coil before a lunge, the lunge itself, and a skittering hop back
	SkelCoil = { drop = 0.55, lean = 0.1, twist = 0.55, side = 0.06, head = -0.1, footR = -0.6, footL = 0.55, spread = 0.15, la1 = 0.6, la3 = -0.8, lel = 0.9, freeL = 0 },
	SkelLunge = { drop = 0.7, lean = 0.75, twist = -0.35, head = -0.2, footR = 1.0, footL = -1.0, la1 = -0.4, la3 = -0.5, lel = 0.2, freeL = 0 },
	SkelHop = { drop = 0.35, lean = -0.3, head = 0.1, tuck = 0.25, footR = -0.4, footL = 0.3, la1 = 0.7, la3 = -0.9, lel = 0.6, freeL = 0 },
	-- reared back for the slow swipe: up on its toes, chest open, head cocked, free arm thrown out
	SkelReach = { drop = 0.05, lean = -0.35, twist = 0.6, side = -0.1, head = -0.25, footR = -0.5, footL = 0.6, spread = 0.2, la1 = 1.3, la3 = -1.1, lel = 0.3, freeL = 0 },
}
M.Colors = { skin = Color3.fromRGB(178, 168, 142), torso = Color3.fromRGB(22, 20, 18), legs = Color3.fromRGB(168, 158, 132), arms = Color3.fromRGB(172, 162, 136) }
M.FistSkin = true

function M.Look(k)
	local deco, parts, V, at, rgb, MAT, D, s, look = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT, k.D, k.s, k.look
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local thigh, shin = D.thigh / s, D.shin / s
	local head = parts.Head.Size / s
	local foot = parts.RFoot.Size / s
	local BALL, CYL = Enum.PartType.Ball, Enum.PartType.Cylinder
	-- a jailer's remains that never stopped walking: round, knobbled bones (each one a
	-- slightly different age), a hollow cage of ribs, scraps of old uniform, embers deep
	-- in the sockets. The rig's boxes stay as the joints; the bones hide them.
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
	local rng = Random.new()
	local bone0, old, dark = look.skin, rgb(140, 124, 92), rgb(10, 8, 8)
	local function boneCol()
		return bone0:Lerp(old, rng:NextNumber(0, 0.55))
	end
	local rag, leather, rust = rgb(52, 44, 36), rgb(46, 32, 24), rgb(96, 62, 40)
	local function ball(on, d, x, y, z, color, mat, name)
		return deco(on, name or "Bone", V(d, d, d), at(x, y, z), color or boneCol(), mat or MAT.SmoothPlastic, BALL)
	end
	-- a round bone from a to b (points in the part's own space)
	local function bar(on, a, b, d, color, mat)
		local dir = b - a
		local up = math.abs(dir.Unit.Y) > 0.9 and Vector3.zAxis or Vector3.yAxis
		local cf = CFrame.lookAt((a + b) / 2 * s, b * s, up) * CFrame.Angles(0, math.pi / 2, 0) -- cylinders run along X
		return deco(on, "Bone", V(dir.Magnitude, d, d), cf, color or boneCol(), mat or MAT.SmoothPlastic, CYL)
	end
	local function P(x, y, z)
		return Vector3.new(x, y, z)
	end

	-- skull: a round cranium, a narrower face, deep sockets, a slack jaw
	local hy, hz = head.Y, head.Z
	local skull = boneCol()
	ball("Head", hz * 0.92, 0, 0.14, 0.06, skull, MAT.Limestone)
	deco("Head", "Bone", V(head.X * 0.72, hy * 0.42, 0.5), at(0, -0.12, -hz * 0.28), skull, MAT.Limestone)
	for _, x in ipairs({ -0.24, 0.24 }) do
		ball("Head", 0.34, x, 0.06, -hz * 0.42, dark, MAT.SmoothPlastic, "Socket")
		ball("Head", 0.2, x * 1.35, -0.12, -hz * 0.36, skull) -- cheekbone
		deco("Head", "Eye", V(0.1, 0.1, 0.1), at(x * 0.95, 0.06, -hz * 0.47), rgb(190, 96, 40), MAT.Neon, BALL)
	end
	deco("Head", "Socket", V(0.12, 0.2, 0.06), at(0, -0.14, -hz * 0.535), dark) -- nose hole
	deco("Head", "Bone", V(0.56, 0.08, 0.06), at(0, -0.32, -hz * 0.535), rgb(196, 188, 160)) -- upper teeth
	local jaw = deco("Head", "Bone", V(0.64, 0.16, 0.5), at(0, -0.52, -hz * 0.22) * CFrame.Angles(-0.22, 0, 0), skull:Lerp(old, 0.3))
	deco("Head", "Bone", V(0.5, 0.07, 0.06), at(0, -0.45, -hz * 0.47) * CFrame.Angles(-0.22, 0, 0), rgb(186, 176, 146)) -- lower teeth
	for _, x in ipairs({ -0.3, 0.3 }) do
		bar("Head", P(x, -0.5, -0.05), P(x * 1.05, -0.2, 0.12), 0.12, jaw.Color) -- the jaw's hinge
	end

	-- spine: a column of knobs up the back, into the neck
	local spineZ = cd * 0.3
	for i = 0, 6 do
		local y = -ch / 2 + 0.08 + i * (ch - 0.1) / 6
		ball("Chest", 0.24, 0, y, spineZ)
	end
	for i = 0, 1 do
		ball("Chest", 0.2, 0, ch / 2 + 0.12 + i * 0.16, spineZ * 0.6)
	end
	-- ribcage: five pairs of ribs curving out from the spine round to a breastbone
	local front = -cd / 2
	bar("Chest", P(0, ch / 2 - 0.2, front), P(0, ch / 2 - 1.15, front + 0.02), 0.16) -- breastbone
	for i = 0, 4 do
		local w = cw * (0.78 + 0.26 * math.sin((i + 1) / 6 * math.pi)) / 2
		local y = ch / 2 - 0.3 - i * 0.27
		local d = 0.11
		for _, sx in ipairs({ -1, 1 }) do
			local a, b, c, e = P(sx * 0.1, y, spineZ), P(sx * w, y - 0.06, cd * 0.05), P(sx * w * 0.86, y - 0.14, front * 0.7), P(sx * (i < 4 and 0.08 or w * 0.45), y - 0.24, front)
			bar("Chest", a, b, d)
			ball("Chest", d, b.X, b.Y, b.Z)
			bar("Chest", b, c, d)
			ball("Chest", d, c.X, c.Y, c.Z)
			bar("Chest", c, e, d * 0.9)
		end
	end
	-- collarbones and shoulder blades
	for _, sx in ipairs({ -1, 1 }) do
		bar("Chest", P(sx * 0.08, ch / 2 - 0.12, front), P(sx * cw * 0.5, ch / 2 - 0.02, 0), 0.13)
		deco("Chest", "Bone", V(0.42, 0.55, 0.08), at(sx * cw * 0.28, ch / 2 - 0.45, spineZ + 0.02) * CFrame.Angles(0, 0, sx * 0.25), boneCol())
	end

	-- pelvis: two flaring wings, a sacrum, the lower spine
	ball("Hips", 0.22, 0, 0.35, spineZ * 0.9)
	ball("Hips", 0.26, 0, 0.05, hd * 0.25)
	local pel = boneCol()
	for _, sx in ipairs({ -1, 1 }) do
		deco("Hips", "Bone", V(0.16, 0.48, 0.5), at(sx * hw * 0.32, 0.12, 0.02) * CFrame.Angles(0, sx * 0.3, sx * 0.45), pel, MAT.Limestone)
		bar("Hips", P(sx * hw * 0.4, -0.05, 0), P(sx * 0.08, -0.25, -hd * 0.4), 0.12, pel)
	end
	-- a belt and the rag of a jailer's tabard (not on you: k.NoTabard, Characters/Knight)
	if not k.NoTabard then
		deco("Hips", "Belt", V(hw * 0.95, 0.12, hd * 0.95), at(0, 0.2, 0), leather, MAT.Fabric)
		deco("Hips", "Belt", V(0.2, 0.18, 0.08), at(-0.1, 0.2, -hd * 0.49), rust, MAT.CorrodedMetal)
		deco("Hips", "Rag", V(hw * 0.42, 1.0, 0.05), at(0.08, -0.4, -hd * 0.5) * CFrame.Angles(0.06, 0, 0.07), rag, MAT.Fabric)
		deco("Hips", "Rag", V(hw * 0.3, 0.7, 0.05), at(-hw * 0.3, -0.25, hd * 0.5) * CFrame.Angles(-0.05, 0, -0.12), rag:Lerp(dark, 0.3), MAT.Fabric)
	end

	-- arms: a round upper bone, two thin forearm bones, bony fingers; a dented pauldron
	-- and a rag wound round one forearm
	for _, n in ipairs({ "R", "L" }) do
		local u, l = n .. "UpperArm", n .. "LowerArm"
		ball(u, aw * 0.8, 0, ua / 2 - 0.05, 0)
		bar(u, P(0, ua / 2 - 0.1, 0), P(0, -ua / 2 + 0.05, 0), aw * 0.42)
		ball(u, aw * 0.62, 0, -ua / 2, 0)
		bar(l, P(-aw * 0.16, la / 2, 0), P(-aw * 0.16, -la / 2 + 0.05, 0.02), aw * 0.3)
		bar(l, P(aw * 0.18, la / 2 - 0.05, 0), P(aw * 0.16, -la / 2 + 0.05, -0.02), aw * 0.24)
		ball(l, aw * 0.42, 0, -la / 2, 0) -- the wrist
		for f = -1, 1 do
			bar(l, P(f * aw * 0.22, -la / 2 - 0.05, 0), P(f * aw * 0.28, -la / 2 - 0.4 + math.abs(f) * 0.06, -0.06), 0.07)
		end
	end
	deco("RUpperArm", "Pauldron", V(aw * 1.9, 0.22, aw * 1.8), at(0.05, ua / 2 - 0.02, 0) * CFrame.Angles(0, 0, -0.35), rust, MAT.CorrodedMetal)
	deco("RUpperArm", "Pauldron", V(aw * 1.6, 0.18, aw * 1.5), at(0.12, ua / 2 - 0.22, 0) * CFrame.Angles(0, 0, -0.5), rust:Lerp(dark, 0.25), MAT.CorrodedMetal)
	deco("LLowerArm", "Rag", V(aw * 0.75, 0.35, aw * 0.75), at(0, la * 0.1, 0) * CFrame.Angles(0, 0.4, 0.1), rag, MAT.Fabric)

	-- legs: a round thigh bone, a knee cap, shin bones, a long bony foot
	for _, n in ipairs({ "R", "L" }) do
		local t, sh, ft = n .. "Thigh", n .. "Shin", n .. "Foot"
		ball(t, lw * 0.8, 0, thigh / 2 - 0.05, 0)
		bar(t, P(0, thigh / 2 - 0.1, 0), P(0, -thigh / 2 + 0.05, 0), lw * 0.44)
		ball(t, lw * 0.66, 0, -thigh / 2, 0)
		ball(sh, lw * 0.42, 0, shin / 2 - 0.05, -lw * 0.32) -- knee cap
		bar(sh, P(0, shin / 2, 0), P(0, -shin / 2 + 0.05, 0), lw * 0.36)
		bar(sh, P(lw * 0.24, shin / 2 - 0.08, 0.04), P(lw * 0.2, -shin / 2 + 0.1, 0.04), lw * 0.18)
		ball(ft, foot.X * 0.62, 0, 0.04, foot.Z * 0.32) -- heel
		for f = -1, 1 do
			bar(ft, P(f * foot.X * 0.22, 0.02, foot.Z * 0.22), P(f * foot.X * 0.3, -0.08, -foot.Z * 0.5), 0.1)
		end
	end
end

M.Weapons = {
	Scimitar = function(w)
		-- a notched, curved prison sabre gone brown with age
		local steel = Color3.fromRGB(110, 96, 80)
		local handle = w.mk("Grip", Vector3.new(0.2, 0.9, 0.2), Color3.fromRGB(40, 30, 22), Enum.Material.Wood)
		w.add(w.mk("Guard", Vector3.new(0.7, 0.12, 0.22), w.iron, Enum.Material.Metal), -0.5)
		w.add(w.mk("Blade", Vector3.new(0.34, 2.1, 0.08), steel, Enum.Material.CorrodedMetal), -1.6)
		w.add(w.mk("Blade", Vector3.new(0.3, 1.1, 0.08), steel, Enum.Material.CorrodedMetal), -3.0, CFrame.Angles(w.R(-14), 0, 0), -0.12)
		return { handle = handle, bladeLen = 3.2 }
	end,
}
M.Grips = {
	-- the lunge: blade drawn back at the hip, then driven straight ahead
	ThrustBack = { Vector3.new(1.3, 0.1, 1.0), CFrame.Angles(math.rad(95), math.rad(-10), 0) },
	ThrustOut = { Vector3.new(0.3, 0.7, -2.3), CFrame.Angles(math.rad(90), 0, 0) },
	-- the slow swipe's windup: hand high over the right shoulder, blade up and back
	SkelHigh = { Vector3.new(1.3, 2.7, 0.5), CFrame.Angles(0, 0, math.rad(-25)) * CFrame.Angles(math.rad(215), 0, 0) },
}

-- stats (the shared brain in GameServer/Enemies.lua reads these)
M.Def = {
-- Skeleton: twitchy (a slow telegraphed swipe or its feint up close, a long lunging
-- thrust from mid range, skittering hops back), but fragile: any hit staggers it for
-- a long time and knocks it well back. Engage = distance it starts attacking at.
	HP = 48, Speed = 12.5, Scale = 1, Damage = 13, Range = 5.2, HalfAngle = 70,
	Windup = 0.4, Recover = 0.75, Aggro = 30, Leash = 55, Stagger = 0.95,
	HyperArmor = false, Weapon = "Scimitar", Radius = 1.1, Lunge = 10,
	Poise = 1, HitLevel = "Small", StaggerPush = 26, Engage = 17, -- (from 17 off: the thrown bone, or the scuttle in)
	LungeDamage = 22, Moves = "Skeleton",
	SwipeDamage = 28, SwipeWindup = 0.95, -- the slow swipe: raised and held this long, then a wide heavy cut
	ComboDamage = 12, -- each of the two quick cuts
	LeapDamage = 24, -- the leap's chop
	ThrowDamage = 12, ThrowEvery = 5, ThrowSpeed = 55, -- a thrown rib: no more often than this, each of them
}

---------------------------------------------------------------------------
-- server: how it fights
---------------------------------------------------------------------------
local pose, playSound, SOUNDS, now, faceTowards, setTrail, flat, playersInSector, damagePlayer, burst, bodyPose, playersInRadius
local RunService = game:GetService("RunService")

-- SKELETON moveset. Each step checks for a stagger: they break out of anything.
local function skelHold(e, duration, faceTarget)
	local t0 = now()
	while now() - t0 < duration do
		if not e.alive or now() < e.staggerUntil then
			return false
		end
		if faceTarget and faceTarget.Parent then
			faceTowards(e.root, faceTarget.Position)
		end
		task.wait()
	end
	return true
end

local function skelHit(e, range, halfAngle, damage, level)
	if not e.alive then
		return
	end
	local root = e.root
	for _, pl in ipairs(playersInSector(root.CFrame, range, halfAngle, 6)) do
		damagePlayer(pl, damage, root.Position, level)
	end
end

-- a burst of its own walk (dist studs over dur seconds). Setting the root's velocity
-- instead fought the humanoid's controller and read as a snap forward.
local function skelStep(e, dir, dist, dur)
	local hum, root = e.hum, e.root
	if not root.Parent or root.Anchored or dir.Magnitude < 0.1 then
		return
	end
	local gen = {}
	e.stepGen = gen
	hum.WalkSpeed = dist / dur
	hum:MoveTo(root.Position + dir.Unit * dist)
	task.delay(dur, function()
		if e.stepGen == gen and hum.Parent then
			hum.WalkSpeed = e.def.Speed
			hum:MoveTo(root.Position)
		end
	end)
end

-- the embers in its sockets flare (the tell for the big swipe and its feint)
local function skelEyes(e, on)
	for _, d in ipairs(e.root.Parent:GetDescendants()) do
		if d.Name == "Eye" and d:IsA("BasePart") then
			d.Color = on and Color3.fromRGB(255, 220, 120) or Color3.fromRGB(190, 96, 40)
			d.Size = Vector3.one * (on and 0.18 or 0.1)
		end
	end
end

-- the rattle: the blade dragged up high over its shoulder, slow, every bone clattering
local function skelRaise(e, tRoot, duration)
	local root = e.root
	pose(e, "SkelHigh", duration * 0.8)
	bodyPose(e, "SkelReach", duration * 0.8)
	skelEyes(e, true)
	for i = 0, 2 do
		task.delay(i * duration / 3, function()
			if e.alive and now() >= e.staggerUntil then
				playSound(root, SOUNDS.Unsheath, 0.3, 0.7 + i * 0.15)
			end
		end)
	end
	local ok = skelHold(e, duration, tRoot)
	if not ok then
		skelEyes(e, false)
	end
	return ok
end

-- SLOW SWIPE: the big telegraphed cut. Raised high and held, then one wide, heavy
-- diagonal swipe that steps in - and leaves it wide open after.
local function skelSwipe(e, tRoot)
	local def, root = e.def, e.root
	if not skelRaise(e, tRoot, def.SwipeWindup) then
		return false
	end
	skelEyes(e, false)
	setTrail(e, true)
	playSound(root, SOUNDS.Slash, 0.7, 0.75)
	pose(e, "SweepMid", 0.08, Enum.EasingStyle.Linear)
	bodyPose(e, "SweepEnd", 0.16)
	task.delay(0.08, function()
		if e.alive then
			pose(e, "SweepEnd", 0.1)
		end
	end)
	skelStep(e, flat(root.CFrame.LookVector), 3, 0.16)
	task.wait(0.07)
	skelHit(e, def.Range + 1.5, 110, def.SwipeDamage, "Large")
	task.wait(0.1)
	setTrail(e, false)
	e.hum:MoveTo(root.Position)
	return true, def.Recover * 1.4 -- (a long recovery: this is the opening)
end

-- FEINT: starts the same slow rattle, then cuts it short and snaps out a quick
-- stab - punishes rolling on the first sound of the swipe
local function skelFeint(e, tRoot)
	local def, root = e.def, e.root
	if not skelRaise(e, tRoot, def.SwipeWindup * 0.45) then
		return false
	end
	skelEyes(e, false)
	pose(e, "ThrustBack", 0.07)
	bodyPose(e, "SkelCoil", 0.07)
	if not skelHold(e, 0.1, tRoot) then
		return false
	end
	setTrail(e, true)
	playSound(root, SOUNDS.Lunge, 0.5, 1.4)
	pose(e, "ThrustOut", 0.06)
	bodyPose(e, "SkelLunge", 0.06)
	skelStep(e, flat(root.CFrame.LookVector), 4, 0.14)
	task.wait(0.06)
	skelHit(e, def.Range + 0.8, 35, def.Damage, "Medium")
	setTrail(e, false)
	e.hum:MoveTo(root.Position)
	return true
end

-- coils low and sidelong, then lunges in with a long straight thrust
local function skelLunge(e, tRoot)
	local def, root = e.def, e.root
	pose(e, "ThrustBack", 0.35)
	bodyPose(e, "SkelCoil", 0.35)
	playSound(root, SOUNDS.Unsheath, 0.4, 0.85)
	if not skelHold(e, 0.6, tRoot) then
		return false
	end
	local dir = flat(root.CFrame.LookVector)
	dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.new(0, 0, -1)
	setTrail(e, true)
	playSound(root, SOUNDS.Lunge, 0.5, 1.2)
	pose(e, "ThrustOut", 0.08)
	bodyPose(e, "SkelLunge", 0.08)
	skelStep(e, dir, 7, 0.24)
	local seen = {}
	local t0 = now()
	while now() - t0 < 0.24 do
		if not e.alive or now() < e.staggerUntil then
			setTrail(e, false)
			return false
		end
		for _, pl in ipairs(playersInSector(root.CFrame, 4.6, 35, 6)) do
			if not seen[pl] then
				seen[pl] = true
				damagePlayer(pl, def.LungeDamage, root.Position, "Medium")
			end
		end
		task.wait()
	end
	e.hum:MoveTo(root.Position) -- don't walk back to where the lunge started
	setTrail(e, false)
	return true
end

-- TWO QUICK CUTS: across, and straight back the way it came, a step into each
local function skelCombo(e, tRoot)
	local def, root = e.def, e.root
	pose(e, "SweepBack", 0.22)
	bodyPose(e, "SweepWindup", 0.22)
	playSound(root, SOUNDS.Unsheath, 0.35, 1.1)
	if not skelHold(e, 0.34, tRoot) then
		return false
	end
	for i = 1, 2 do
		setTrail(e, true)
		playSound(root, SOUNDS.Slash, 0.55, 1.1 + i * 0.15)
		pose(e, i == 1 and "SweepEnd" or "SweepBack", 0.1)
		bodyPose(e, i == 1 and "SweepEnd" or "SweepWindup", 0.12)
		skelStep(e, flat(root.CFrame.LookVector), 2.5, 0.14)
		task.wait(0.07)
		skelHit(e, def.Range + 0.8, 80, def.ComboDamage, "Small")
		setTrail(e, false)
		if i == 1 and not skelHold(e, 0.26, tRoot) then -- (the beat between them: it turns with you)
			return false
		end
	end
	e.hum:MoveTo(root.Position)
	return true
end

-- THE LEAP: sunk on its haunches, the blade up over its head, then up and at you and the blade down
local function skelLeap(e, tRoot)
	local def, root = e.def, e.root
	pose(e, "Raise", 0.3)
	bodyPose(e, "Crouch", 0.3)
	playSound(root, SOUNDS.Unsheath, 0.4, 0.7)
	if not skelHold(e, 0.5, tRoot) then
		return false
	end
	local d = flat(tRoot.Position - root.Position)
	bodyPose(e, "Air", 0.1)
	playSound(root, SOUNDS.Lunge, 0.5, 1.0)
	skelStep(e, d, math.clamp(d.Magnitude - 2.5, 2, 9), 0.3)
	if not skelHold(e, 0.24, nil) then
		return false
	end
	setTrail(e, true)
	pose(e, "Strike", 0.07)
	bodyPose(e, "Strike", 0.08)
	task.wait(0.07)
	skelHit(e, def.Range + 1.2, 45, def.LeapDamage, "Large")
	burst(root.Position + flat(root.CFrame.LookVector) * 3 - Vector3.new(0, 2.5, 0), Color3.fromRGB(105, 98, 88), 10, 0.3, 10)
	task.wait(0.1)
	setTrail(e, false)
	e.hum:MoveTo(root.Position)
	return true, def.Recover * 1.3
end

-- A RIB, THROWN: reared right back, a rattle, and it comes spinning straight at where you were
local function skelThrow(e, tRoot)
	local def, root = e.def, e.root
	pose(e, "SkelHigh", 0.3)
	bodyPose(e, "SkelReach", 0.3)
	skelEyes(e, true)
	playSound(root, SOUNDS.Unsheath, 0.35, 1.5)
	local ok = skelHold(e, 0.6, tRoot)
	skelEyes(e, false)
	if not ok then
		return false
	end
	pose(e, "SweepEnd", 0.08)
	bodyPose(e, "SweepEnd", 0.1)
	playSound(root, SOUNDS.Slash, 0.5, 1.5)
	local from = root.Position + Vector3.new(0, 1.5, 0)
	local dir = tRoot.Position - from
	dir = dir.Magnitude > 0.1 and dir.Unit or root.CFrame.LookVector
	local rib = Instance.new("Part")
	rib.Name = "ThrownRib"
	rib.Size, rib.Color, rib.Material = Vector3.new(0.3, 0.3, 1.7), Color3.fromRGB(178, 168, 142), Enum.Material.SmoothPlastic
	rib.Anchored, rib.CanCollide, rib.CanQuery, rib.CanTouch = true, false, false, false
	rib.CFrame = CFrame.lookAt(from, from + dir)
	rib.Parent = workspace
	task.spawn(function()
		local t0, at = now(), from
		while now() - t0 < 0.65 do
			local dt = RunService.Heartbeat:Wait()
			at += dir * def.ThrowSpeed * dt
			rib.CFrame = CFrame.lookAt(at, at + dir) * CFrame.Angles((now() - t0) * 22, 0, 0)
			local hit = playersInRadius(at, 1.4, 3)[1]
			if hit then
				damagePlayer(hit, def.ThrowDamage, from, "Small")
				burst(at, Color3.fromRGB(178, 168, 142), 8, 0.25, 10)
				break
			end
		end
		rib:Destroy()
	end)
	return true, def.Recover * 0.6
end

-- a skip to one side of where it stood, its face still on you (before the close ones, as often as not)
local function skelSkip(e, tRoot)
	local root = e.root
	local to = flat(tRoot.Position - root.Position)
	if to.Magnitude < 0.1 then
		return true
	end
	local side = Vector3.new(-to.Z, 0, to.X).Unit * (math.random() < 0.5 and 1 or -1)
	bodyPose(e, "SkelHop", 0.08)
	playSound(root, SOUNDS.Unsheath, 0.25, 1.7)
	skelStep(e, side + to.Unit * 0.3, 4, 0.2)
	return skelHold(e, 0.22, tRoot)
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
	faceTowards(root, tRoot.Position)
	local d = flat(tRoot.Position - root.Position).Magnitude
	local ok, recover
	if d > 10.5 then -- well off: a rib thrown, or a scuttle in to lunge off the end of
		if now() >= (e.throwAt or 0) and math.random() < 0.6 then
			e.throwAt = now() + def.ThrowEvery
			ok, recover = skelThrow(e, tRoot)
		else
			bodyPose(e, "SkelCoil", 0.15)
			skelStep(e, flat(tRoot.Position - root.Position), d - 8, (d - 8) / 22)
			ok = skelHold(e, (d - 8) / 22, tRoot) and skelLunge(e, tRoot)
		end
	elseif d > def.Range + 1.5 then -- a little off: the coiled lunge, or the leap
		if math.random() < 0.4 then
			ok, recover = skelLeap(e, tRoot)
		else
			ok = skelLunge(e, tRoot)
		end
	else -- up close: as often as not a skip to one side first; then the swipe, its feint, or the two quick cuts
		ok = math.random() >= 0.4 or skelSkip(e, tRoot)
		if ok then
			local r = math.random()
			if r < 0.3 then
				ok = skelFeint(e, tRoot)
			elseif r < 0.6 then
				ok = skelCombo(e, tRoot)
			else
				ok, recover = skelSwipe(e, tRoot)
			end
		end
	end
	if ok and e.alive then
		-- recovery (punish it), then often a skittering hop back out of reach
		bodyPose(e, "Recover", 0.25)
		pose(e, "Idle", 0.35)
		if skelHold(e, recover or def.Recover, nil) and e.alive and math.random() < 0.55 then
			bodyPose(e, "SkelHop", 0.1)
			local back = -flat(root.CFrame.LookVector)
			if back.Magnitude > 0.1 then
				skelStep(e, back, 5, 0.25)
			end
			playSound(root, SOUNDS.Unsheath, 0.25, 1.6) -- bones rattling
			skelHold(e, 0.3, nil)
			hum:MoveTo(root.Position)
		end
	end
	setTrail(e, false)
	e.stepGen = nil
	hum.WalkSpeed = def.Speed
	if e.alive and now() >= e.staggerUntil then
		pose(e, "Idle", 0.3)
	end
	hum.AutoRotate = true
	e.attacking = false
end
-- any hit that breaks its (tiny) poise: the whole frame reels, bones clattering
function M.onStagger(e)
	bodyPose(e, "Stagger", 0.08)
	burst(e.root.Position + Vector3.new(0, 1, 0), Color3.fromRGB(170, 160, 135), 10, 0.25, 10)
	playSound(e.root, SOUNDS.Unsheath, 0.35, 1.8)
end

function M.init(core)
	pose, playSound, SOUNDS, now, faceTowards, setTrail, flat, playersInSector, damagePlayer, burst, bodyPose = core.pose, core.playSound, core.SOUNDS, core.now, core.faceTowards, core.setTrail, core.flat, core.playersInSector, core.damagePlayer, core.burst, core.bodyPose
	playersInRadius = core.playersInRadius
end

return M
