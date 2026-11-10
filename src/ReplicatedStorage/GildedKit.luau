--!nonstrict
-- GildedKit: what the Gilded Heights' twenty minor enemies share (Characters/Gilt*.luau and friends): their palette, a set of
-- weapon grips and body poses, and the pieces their fights are made of. Each enemy's own file holds its look, its weapon, its
-- stats and which of these it strings together, and how. The shared brain's still GameServer/Enemies.
-- No ground markings anywhere in here: every attack's read off the body, as the Pyralis brutes' are.
local K = {}

local R = math.rad
local rgb = Color3.fromRGB
K.IVORY, K.CREAM, K.PORCELAIN = rgb(218, 216, 208), rgb(202, 198, 188), rgb(236, 234, 228)
K.GOLD, K.LIGHT, K.TARNISH = rgb(201, 160, 74), rgb(235, 200, 120), rgb(112, 88, 48)
K.RUG, K.LAPIS, K.ROSE, K.JADE, K.AMBER = rgb(120, 24, 44), rgb(30, 70, 150), rgb(150, 40, 90), rgb(24, 120, 100), rgb(170, 100, 30)
K.SILVER, K.SILVER_DK, K.INK, K.LEATHER = rgb(190, 194, 202), rgb(138, 142, 152), rgb(26, 24, 30), rgb(70, 46, 30)
K.BLOSSOM, K.LEAF = rgb(206, 150, 170), rgb(86, 140, 74)

-- the weapon's head along the grip's -Y (Core's convention): 0 hangs it, 90 levels it forward, 180 stands it up
K.Grips = {
	GGuard = { Vector3.new(1.3, -0.6, -0.4), CFrame.Angles(R(18), 0, 0) }, -- hanging at the side
	GReady = { Vector3.new(1.0, 0.1, -1.2), CFrame.Angles(R(120), 0, R(-8)) }, -- held up in front, en garde
	GLevel = { Vector3.new(1.0, 0.3, -0.9), CFrame.Angles(R(88), 0, 0) }, -- levelled at you
	GPort = { Vector3.new(1.0, 0.2, -0.7), CFrame.Angles(R(172), 0, R(-6)) }, -- stood upright before it
	GRaise = { Vector3.new(0.7, 2.6, 0.5), CFrame.Angles(R(215), 0, 0) }, -- overhead, the head behind
	GSlam = { Vector3.new(0.6, -0.8, -2.0), CFrame.Angles(R(55), 0, 0) }, -- brought down into the floor in front
	GDraw = { Vector3.new(1.3, 0.6, 1.1), CFrame.Angles(R(90), 0, 0) }, -- drawn back to thrust
	GThrust = { Vector3.new(0.4, 0.5, -2.7), CFrame.Angles(R(90), 0, 0) }, -- driven through
	GCock = { Vector3.new(1.4, 1.9, 0.2), CFrame.Angles(R(210), 0, R(30)) }, -- up and back over the right shoulder
	GCut = { Vector3.new(-0.4, 0.2, -1.8), CFrame.Angles(R(68), 0, R(-37)) }, -- cut through, across to the left
	GBack = { Vector3.new(2.0, 0.7, 0.5), CFrame.Angles(0, R(-120), 0) * CFrame.Angles(R(90), 0, 0) }, -- flat, round behind to the right
	GSweep = { Vector3.new(-1.1, 0.5, -1.4), CFrame.Angles(0, R(60), 0) * CFrame.Angles(R(90), 0, 0) }, -- flat, swept through to the left
	GWide = { Vector3.new(1.9, 0.3, 0.1), CFrame.Angles(R(10), 0, R(70)) }, -- thrown out wide
	GHigh = { Vector3.new(0.9, 3.1, -0.6), CFrame.Angles(R(170), 0, 0) }, -- held up high in the air
	GToss = { Vector3.new(1.3, 1.5, 0.9), CFrame.Angles(R(150), 0, R(10)) }, -- wound back at the ear, to throw
	GTossed = { Vector3.new(0.7, 1.1, -2.0), CFrame.Angles(R(95), 0, 0) }, -- the arm thrown out after it
}
K.Poses = {
	GBSet = { drop = 0.25, lean = -0.32, twist = 0.3, head = -0.15, footR = -0.45, footL = 0.5, la1 = 0.5, la3 = -0.5, lel = 0.6, freeL = 0 },
	GBStrike = { drop = 0.7, lean = 0.6, twist = -0.25, head = 0.2, footR = 0.75, footL = -0.6, la1 = -0.3, la3 = -0.3, lel = 0.3, freeL = 0 },
	GBDraw = { drop = 0.55, lean = 0.1, twist = 0.6, head = -0.05, footR = -0.7, footL = 0.7, spread = 0.2, la1 = 0.8, la3 = -0.6, lel = 0.6, freeL = 0 },
	GBLunge = { drop = 0.75, lean = 0.75, twist = -0.4, head = -0.15, footR = 1.1, footL = -1.0, spread = 0.18, la1 = -0.6, la3 = -0.5, lel = 0.2, freeL = 0 },
	GBWind = { drop = 0.4, lean = 0.12, twist = 0.95, hip = 0.35, footR = -0.45, footL = 0.45, la1 = 0.6, la3 = -0.9, lel = 0.5, freeL = 0 },
	GBSweep = { drop = 0.5, lean = 0.32, twist = -0.95, hip = -0.35, footR = 0.5, footL = -0.3, la1 = -0.4, la3 = -0.6, lel = 0.3, freeL = 0 },
	GBLow = { drop = 1.1, lean = 0.55, head = -0.2, spread = 0.3, footR = 0.45, footL = -0.45, la1 = 0.3, la3 = -0.5, freeL = 0, breathe = 3 },
	GBAir = { drop = 0.2, lean = 0.4, tuck = 0.7, la1 = 0.6, la3 = -0.7, freeL = 0 },
	GBLand = { drop = 1.3, lean = 0.75, head = -0.2, spread = 0.4, footR = 0.9, footL = -1.0, la1 = -0.6, la3 = -1.0, lel = 0.3, freeL = 0, breathe = 4 },
	GBCast = { drop = 0.2, lean = -0.22, head = -0.3, footR = -0.35, footL = 0.4, la1 = 2.0, la3 = -0.6, lel = 0.5, freeL = 0, breathe = 3 },
	GBFling = { drop = 0.5, lean = 0.55, twist = -0.5, head = 0.05, footR = 0.75, footL = -0.6, la1 = 1.3, la2 = 0.3, la3 = -0.2, lel = 0.2, freeL = 0 },
	GBSpin = { drop = 0.45, lean = -0.05, head = -0.08, spread = 0.36, footR = -0.25, footL = 0.25, la1 = 1.2, la3 = -1.1, lel = 0.3, freeL = 0 },
	GBDraught = { drop = 0.45, lean = -0.32, head = -0.4, spread = 0.4, footR = -0.4, footL = 0.4, breathe = 7, freeL = 0 },
	GBBlow = { drop = 0.55, lean = 0.38, head = 0.12, spread = 0.42, footR = -0.45, footL = 0.5, freeL = 0, breathe = 1 },
	GBBrace = { drop = 0.6, lean = 0.18, head = 0.05, spread = 0.32, footR = -0.6, footL = 0.65, la1 = 1.1, la2 = 0.4, la3 = -0.1, lel = 1.4, freeL = 0 },
}

-- every enemy's Def starts from these; a file's own table goes over the top
function K.def(over)
	local d = {
		HP = 420, Speed = 10.5, Scale = 1.25, Damage = 38, Range = 9.5, HalfAngle = 55,
		Windup = 0.85, Recover = 1, Aggro = 38, Leash = 55, Stagger = 0.5, StaggerPush = 10,
		HyperArmor = false, Radius = 1.6, Lunge = 9, Poise = 65, HitLevel = "Large", Engage = 12, Close = 8,
		IdleGrip = "GGuard", Skin = K.IVORY, Cloth = K.RUG,
	}
	for key, v in pairs(over) do
		d[key] = v
	end
	return d
end
-- fills in a character file: the shared poses and grips under its own, the kit's init
function K.wrap(M)
	local function merged(base, own)
		local t = table.clone(base)
		for key, v in pairs(own or {}) do
			t[key] = v
		end
		return t
	end
	M.Poses, M.Grips = merged(K.Poses, M.Poses), merged(K.Grips, M.Grips)
	M.init = K.init
	return M
end
-- a strip of cloth hung off an anchor (Carrier.cloth, on every client), as the Silver Knight's cape is
function K.cloth(p, segs, len, width, color, phys)
	p.Transparency = 1
	for key, v in pairs(phys or {}) do
		p:SetAttribute(key, v)
	end
	p:SetAttribute("Segs", segs)
	p:SetAttribute("Len", len)
	p:SetAttribute("Width", width)
	p:SetAttribute("Color", color)
	game:GetService("CollectionService"):AddTag(p, "ClothChain")
	return p
end
K.BACK = CFrame.Angles(0, math.pi, 0) -- (a cape anchor's turn: hanging out behind)
K.UP = CFrame.Angles(0, 0, math.pi / 2) -- (a cylinder stood on end)
K.FACE = CFrame.Angles(0, math.pi / 2, 0) -- (a cylinder's end turned to the front: a disc)

---------------------------------------------------------------------------
-- server: the pieces of a fight
---------------------------------------------------------------------------
local core
local pose, bodyPose, playSound, SOUNDS, now, faceTowards, setTrail, flat, playersInSector, playersInRadius, damagePlayer, burst, dustCloud, FxRemote
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

function K.init(c)
	if core then
		return
	end
	core = c
	pose, bodyPose, playSound, SOUNDS, now, faceTowards, setTrail, flat = c.pose, c.bodyPose, c.playSound, c.SOUNDS, c.now, c.faceTowards, c.setTrail, c.flat
	playersInSector, playersInRadius, damagePlayer, burst, dustCloud, FxRemote = c.playersInSector, c.playersInRadius, c.damagePlayer, c.burst, c.dustCloud, c.FxRemote
end

local function hold(e, duration, target) -- (false if it's staggered or slain in the meantime)
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
K.hold = hold
local function feet(e)
	return e.root.Position - Vector3.new(0, 3 * e.def.Scale - 0.2, 0)
end
K.feet = feet
local function step(e, k)
	local v = e.root.AssemblyLinearVelocity
	e.root.AssemblyLinearVelocity = flat(e.root.CFrame.LookVector) * e.def.Lunge * (k or 1) + Vector3.new(0, v.Y, 0)
end
K.step = step
local function ahead(e, d) -- on the floor, d out in front
	return feet(e) + flat(e.root.CFrame.LookVector) * d
end
K.ahead = ahead
function K.partOf(e, name)
	return e.model:FindFirstChild(name, true)
end
function K.shake(pos, amount)
	FxRemote:FireAllClients("Shake", pos, amount)
end
function K.sound(e, name, vol, speed)
	playSound(e.root, SOUNDS[name] or name, vol or 0.6, speed or 1)
end
function K.face(e, pos)
	faceTowards(e.root, pos)
end
function K.setGrip(e, name, t, style)
	pose(e, name, t or 0.3, style or Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
end
function K.setBody(e, name, t)
	bodyPose(e, name, t or 0.3)
end
-- everyone on the floor round a point
function K.area(at, radius, height, damage, level)
	for _, pl in ipairs(playersInRadius(at, radius, height or 4)) do
		damagePlayer(pl, damage, at, level or "Medium")
	end
end
-- everyone in a straight line out in front of a frame, length long and width to each side
function K.line(cf, length, width, height)
	local out = {}
	for _, pl in ipairs(playersInSector(cf, length, 90, height)) do
		local hrp = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local rel = cf:PointToObjectSpace(hrp.Position)
			if math.abs(rel.X) <= width and rel.Z <= 1 then
				table.insert(out, pl)
			end
		end
	end
	return out
end
function K.hurt(pl, damage, from, level, push)
	return damagePlayer(pl, damage, from, level, push)
end
-- sparks and a dying light at a point: what a burst of something looks like
function K.flash(pos, color, size)
	burst(pos, color, 30, 0.6, (size or 10) * 2)
	local p = Instance.new("Part")
	p.Name = "GildedFlash"
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Transparency, p.Size, p.CFrame = 1, Vector3.one, CFrame.new(pos)
	p.Parent = workspace
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = color, (size or 10) * 3, 6
	l.Parent = p
	game:GetService("TweenService"):Create(l, TweenInfo.new(0.5), { Brightness = 0 }):Play()
	Debris:AddItem(p, 0.6)
end

-- wound up, then a blow in front of it. o: set, setBody, tell, swing, swingBody, time, range, half, damage, level, lunge, speed
function K.strike(e, tRoot, o)
	local def, root = e.def, e.root
	local tell = o.tell or def.Windup
	if o.set then
		pose(e, o.set, tell * 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	end
	if o.setBody then
		bodyPose(e, o.setBody, tell * 0.8)
	end
	if not o.quiet then
		playSound(root, SOUNDS.Unsheath, 0.4, o.speed or 0.7)
	end
	if not hold(e, tell, tRoot) then
		return false
	end
	setTrail(e, true)
	playSound(root, SOUNDS.Slash, 0.65, o.speed or 0.7)
	local t = o.time or 0.16
	if o.swing then
		pose(e, o.swing, t, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end
	if o.swingBody then
		bodyPose(e, o.swingBody, t)
	end
	step(e, o.lunge or 1)
	task.wait(t * 0.8)
	if not e.alive then
		return false
	end
	local hit = false
	for _, pl in ipairs(playersInSector(root.CFrame, o.range or def.Range, o.half or def.HalfAngle, 6 * def.Scale)) do
		if damagePlayer(pl, o.damage or def.Damage, root.Position, o.level or def.HitLevel) then
			hit = true
		end
	end
	if o.after then
		o.after(ahead(e, (o.range or def.Range) * 0.55), hit)
	end
	task.wait(0.08)
	setTrail(e, false)
	return e.alive, hit
end
-- a blow into the floor, and the stone jumping round it (a shudder and dust: no ring, no marking)
function K.slam(e, tRoot, o)
	local after = o.after
	o = table.clone(o)
	o.after = function(at, hit)
		for _, pl in ipairs(playersInRadius(at, o.area or 6, 3.5)) do
			damagePlayer(pl, o.areaDamage or (o.damage or e.def.Damage) * 0.6, at, "Medium")
		end
		burst(at, o.color or K.IVORY, 26, 0.6, 20)
		dustCloud(at, o.area or 6, 12)
		playSound(e.root, SOUNDS.WatchdogSmash, 0.75, o.boom or 0.9)
		K.shake(at, o.shake or 0.45)
		if after then
			after(at, hit)
		end
	end
	return K.strike(e, tRoot, o)
end
function K.combo(e, tRoot, list)
	for _, o in ipairs(list) do
		if not K.strike(e, tRoot, o) then
			return false
		end
	end
	return true
end

-- a straight rush at where you stood when the tell ended, stopping at any wall. Hits once. o: set, setBody, tell, drive, driveBody,
-- speed, time, reach, damage, level, onDone(hit)
function K.rush(e, tRoot, o)
	local def, root, hum = e.def, e.root, e.hum
	local tell = o.tell or def.Windup
	if o.set then
		pose(e, o.set, tell * 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	end
	if o.setBody then
		bodyPose(e, o.setBody, tell * 0.8)
	end
	if not hold(e, tell, tRoot) then
		return false
	end
	if o.drive then
		pose(e, o.drive, 0.1)
	end
	if o.driveBody then
		bodyPose(e, o.driveBody, 0.1)
	end
	setTrail(e, true)
	playSound(root, SOUNDS.Lunge, 0.8, o.pitch or 0.7)
	local dir = flat(root.CFrame.LookVector)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { e.model, core.EnemiesFolder }
	rp.RespectCanCollide = true
	local hits, any, t0 = {}, false, now()
	while now() - t0 < (o.time or 0.5) do
		if not e.alive or now() < e.staggerUntil then
			break
		end
		if workspace:Raycast(root.Position, dir * (def.Radius + 2), rp) then
			break
		end
		root.AssemblyLinearVelocity = dir * (o.speed or 40) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
		for _, pl in ipairs(playersInRadius(root.Position + dir * 2, o.reach or 4.5, 6 * def.Scale)) do
			if not hits[pl] then
				hits[pl] = true
				if damagePlayer(pl, o.damage or def.Damage, root.Position, o.level or def.HitLevel) then
					any = true
				end
			end
		end
		RunService.Heartbeat:Wait()
	end
	root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
	hum:MoveTo(root.Position)
	setTrail(e, false)
	if o.onDone then
		o.onDone(any)
	end
	return e.alive, any
end

-- up and over, coming down where you stood when it left the floor. Short of any wall, and it won't go if there's no floor there.
-- o: set, setBody, tell, air, airBody, land, landBody, time, height, damage, area, level, color, onLand(at)
function K.leap(e, tRoot, o)
	local def, root = e.def, e.root
	local tell = o.tell or def.Windup
	if o.set then
		pose(e, o.set, tell * 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	end
	bodyPose(e, o.setBody or "GBLow", tell * 0.8)
	if not hold(e, tell, tRoot) or not tRoot.Parent then
		return false
	end
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { e.model, tRoot.Parent, core.EnemiesFolder }
	rp.RespectCanCollide = true
	local from = root.Position
	local goal = Vector3.new(tRoot.Position.X, from.Y, tRoot.Position.Z)
	local wall = workspace:Raycast(from, goal - from, rp)
	if wall then
		goal = wall.Position - (goal - from).Unit * (def.Radius + 1.5)
	end
	local below = workspace:Raycast(goal + Vector3.new(0, 4, 0), Vector3.new(0, -16, 0), rp)
	if not below then -- (nothing to come down on: it stays where it is)
		return true
	end
	goal = below.Position + Vector3.new(0, 3 * def.Scale + 0.1, 0)
	local top = workspace:Raycast(from, Vector3.new(0, o.height or 12, 0), rp)
	local rise = top and math.max(top.Distance - 5 * def.Scale, 0) or (o.height or 12)
	if o.air then
		pose(e, o.air, 0.14)
	end
	bodyPose(e, o.airBody or "GBAir", 0.14)
	setTrail(e, true)
	playSound(root, SOUNDS.Lunge, 0.9, o.pitch or 0.55)
	root.Anchored = true
	local T, t0, look = o.time or 0.7, now(), flat(goal - from)
	look = look.Magnitude > 0.5 and look.Unit or flat(root.CFrame.LookVector)
	while true do
		local u = math.min((now() - t0) / T, 1)
		if not e.alive then
			break
		end
		local p = from:Lerp(goal, u) + Vector3.new(0, rise * 4 * u * (1 - u), 0)
		root.CFrame = CFrame.lookAt(p, p + look)
		if u >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end
	root.Anchored = false
	if not e.alive then
		return false
	end
	if o.land then
		pose(e, o.land, 0.08)
	end
	bodyPose(e, o.landBody or "GBLand", 0.08)
	local at = feet(e)
	for _, pl in ipairs(playersInRadius(at, o.area or 7, 4)) do
		damagePlayer(pl, o.damage or def.Damage, at, o.level or "Knockdown")
	end
	burst(at, o.color or K.IVORY, 28, 0.6, 22)
	dustCloud(at, o.area or 7, 12)
	playSound(root, SOUNDS.WatchdogSmash, 0.85, o.boom or 0.9)
	K.shake(at, o.shake or 0.5)
	if o.onLand then
		o.onLand(at)
	end
	setTrail(e, false)
	return true
end

-- spins on the spot, then comes at you still going. o: grip, body, wind, time, radius, damage, every, speed, turn
function K.whirl(e, tRoot, o)
	local def, root, hum = e.def, e.root, e.hum
	if o.grip then
		pose(e, o.grip, 0.25)
	end
	bodyPose(e, o.body or "GBSpin", 0.25)
	playSound(root, SOUNDS.Unsheath, 0.5, 0.7)
	if not hold(e, o.wind or 0.55, tRoot) then
		return false
	end
	setTrail(e, true)
	local hits, t0, last, yaw, lastWhoosh, ok = {}, now(), now(), 0, 0, true
	while now() - t0 < (o.time or 2) do
		local t = now()
		local dt = t - last
		last = t
		if not e.alive or t < e.staggerUntil then
			ok = false
			break
		end
		local turn = (o.turn or 13) * math.min((t - t0) / 0.5 + 0.2, 1)
		yaw = turn * dt
		root.CFrame *= CFrame.Angles(0, yaw, 0)
		if tRoot.Parent then
			hum.WalkSpeed = o.speed or 7
			hum:MoveTo(tRoot.Position)
		end
		if t - lastWhoosh > 0.45 then
			lastWhoosh = t
			playSound(root, SOUNDS.Lunge, 0.5, 0.65)
		end
		for _, pl in ipairs(playersInRadius(root.Position, o.radius or 7, 6 * def.Scale)) do
			if t - (hits[pl] or -99) > (o.every or 0.6) then
				hits[pl] = t
				damagePlayer(pl, o.damage or def.Damage * 0.5, root.Position, "Medium")
			end
		end
		RunService.Heartbeat:Wait()
	end
	hum.WalkSpeed = def.Speed
	hum:MoveTo(root.Position)
	setTrail(e, false)
	return ok
end

-- something flung. o: from (a Vector3), vel, damage, level, radius, life, gravity, size, color, material, shape, make(part),
-- home (radians a second it can turn towards homeOn), homeOn, trail (Color3), onLand(pos), spin
function K.shot(e, o)
	local p = Instance.new("Part")
	p.Name = "GildedShot"
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Size = o.size or Vector3.new(0.7, 0.7, 0.7)
	p.Shape = o.shape or Enum.PartType.Ball
	p.Color, p.Material = o.color or K.GOLD, o.material or Enum.Material.Metal
	p.CFrame = CFrame.new(o.from)
	if o.make then
		o.make(p)
	end
	p.Parent = workspace
	Debris:AddItem(p, (o.life or 3) + 1)
	if o.trail then
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Position, a1.Position = Vector3.new(0, 0.3, 0), Vector3.new(0, -0.3, 0)
		a0.Parent, a1.Parent = p, p
		local tr = Instance.new("Trail")
		tr.Attachment0, tr.Attachment1 = a0, a1
		tr.Color = ColorSequence.new(o.trail)
		tr.LightEmission, tr.Lifetime = 0.6, 0.3
		tr.Transparency = NumberSequence.new(0.2, 1)
		tr.Parent = p
	end
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { e.model, core.EnemiesFolder }
	rp.RespectCanCollide = true
	task.spawn(function()
		local vel, t0, last, spin = o.vel, now(), now(), 0
		local g = Vector3.new(0, -(o.gravity or 0), 0)
		while p.Parent and now() - t0 < (o.life or 3) do
			RunService.Heartbeat:Wait()
			local t = now()
			local dt = t - last
			last = t
			if o.home and o.homeOn and o.homeOn.Parent then
				local want = (o.homeOn.Position - p.Position).Unit
				local sp = vel.Magnitude
				local turn = math.min(o.home * dt, 1)
				vel = vel.Unit:Lerp(want, turn).Unit * sp
			end
			vel += g * dt
			local from, to = p.Position, p.Position + vel * dt
			for _, pl in ipairs(o.visual and {} or playersInRadius(to, o.radius or 1.5, (o.radius or 1.5) + 3)) do
				if damagePlayer(pl, o.damage or 18, from, o.level or "Small") then
					burst(to, p.Color, 10, 0.3, 12)
					p:Destroy()
					return
				end
			end
			local hit = workspace:Raycast(from, to - from, rp)
			if hit then
				burst(hit.Position, p.Color, 8, 0.3, 10)
				if o.onLand then
					o.onLand(hit.Position)
				end
				p:Destroy()
				return
			end
			spin += (o.spin or 0) * dt
			p.CFrame = CFrame.lookAt(to, to + vel) * CFrame.Angles(0, 0, spin)
		end
		if p.Parent then
			p:Destroy()
		end
	end)
	return p
end

-- whatever's held out on a part breathing out a cone. o: part, set, setBody, draw, blowBody, time, reach, half, damage, tick, c0, c1, c2,
-- poison (standing in it, Config's poison)
function K.breath(e, tRoot, o)
	local def, root = e.def, e.root
	if o.set then
		pose(e, o.set, 0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	end
	bodyPose(e, o.setBody or "GBDraught", (o.draw or 1) * 0.8)
	playSound(root, SOUNDS.FireHit, 0.3, 0.4)
	if not hold(e, o.draw or 1, tRoot) then
		return false
	end
	bodyPose(e, o.blowBody or "GBBlow", 0.15)
	local src = o.part or root
	local em = Instance.new("ParticleEmitter")
	em.Texture = o.texture or "rbxasset://textures/particles/smoke_main.dds"
	em.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, o.c0), ColorSequenceKeypoint.new(0.4, o.c1), ColorSequenceKeypoint.new(1, o.c2) })
	em.LightEmission = o.glow or 0.6
	em.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, o.spread or 5) })
	em.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	em.Lifetime, em.Rate, em.Speed = NumberRange.new(0.35, 0.55), 120, NumberRange.new((o.reach or 13) * 1.8, (o.reach or 13) * 2.4)
	em.EmissionDirection, em.SpreadAngle = Enum.NormalId.Front, Vector2.new(o.half or 20, o.half or 20)
	em.Rotation, em.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-200, 200)
	em.Parent = src
	playSound(root, SOUNDS.FireHit, 0.7, o.pitch or 0.6)
	local t0, lastTick = now(), -1
	while now() - t0 < (o.time or 1.2) and e.alive and now() >= e.staggerUntil do
		if now() - lastTick >= (o.tick or 0.3) then
			lastTick = now()
			for _, pl in ipairs(playersInSector(root.CFrame, o.reach or 13, o.half or 24, 6 * def.Scale)) do
				damagePlayer(pl, o.damage or 11, root.Position, "Small")
				if o.poison then
					core.poisonPlayer(pl, o.poison)
				end
			end
		end
		task.wait()
	end
	em.Enabled = false
	Debris:AddItem(em, 0.7)
	return e.alive
end

-- a cloud hanging where it's put, for a while. o: radius, life, color, tick, damage, poison
function K.cloud(pos, o)
	local p = Instance.new("Part")
	p.Name = "GildedCloud"
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = Vector3.new(o.radius * 1.6, 2, o.radius * 1.6)
	p.CFrame = CFrame.new(pos + Vector3.new(0, 2, 0))
	p.Parent = workspace
	local em = Instance.new("ParticleEmitter")
	em.Texture = o.texture or "rbxasset://textures/particles/smoke_main.dds"
	em.Color = ColorSequence.new(o.color)
	em.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 5) })
	em.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.45), NumberSequenceKeypoint.new(1, 1) })
	em.Lifetime, em.Rate, em.Speed = NumberRange.new(1, 1.8), o.rate or 30, NumberRange.new(0.5, 1.5)
	em.SpreadAngle = Vector2.new(180, 180)
	em.Rotation, em.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-40, 40)
	em.Parent = p
	Debris:AddItem(p, o.life + 2)
	task.spawn(function()
		local t0 = now()
		while now() - t0 < o.life do
			task.wait(o.tick or 0.5)
			for _, pl in ipairs(playersInRadius(pos, o.radius, 6)) do
				if o.damage then
					damagePlayer(pl, o.damage, pos, "Small")
				end
				if o.poison then
					core.poisonPlayer(pl, o.poison)
				end
			end
		end
		em.Enabled = false
	end)
	return p
end

-- where a thing thrown from from, at speed, must go to land on the target about now (a little lead)
function K.aim(from, tRoot, speed, lead)
	local at = tRoot.Position + tRoot.AssemblyLinearVelocity * Vector3.new(1, 0, 1) * (lead or 0.15)
	return (at - from).Unit * speed
end
function K.hand(e)
	local h = e.weld and e.weld.Part1
	return h and h.Position or e.root.Position + Vector3.new(0, 1, 0)
end
-- M.attack from a picker: pick(e, tRoot, distance) runs its moves and returns (carried on?, rest after)
function K.brain(pick)
	return function(e, targetChar)
		local def, hum, root = e.def, e.hum, e.root
		local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
		if not tRoot then
			return
		end
		e.attacking = true
		hum:MoveTo(root.Position)
		hum.AutoRotate = false
		local ok, rest = pick(e, tRoot, flat(tRoot.Position - root.Position).Magnitude)
		if ok then
			hold(e, rest or def.Recover)
		end
		setTrail(e, false)
		if root.Anchored then
			root.Anchored = false
		end
		if e.alive then
			pose(e, "Idle", 0.4)
		end
		hum.WalkSpeed = def.Speed
		hum.AutoRotate = true
		e.attacking = false
	end
end

return K
