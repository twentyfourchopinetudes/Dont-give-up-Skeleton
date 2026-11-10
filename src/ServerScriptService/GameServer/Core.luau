--!nonstrict
-- Core: the shared toolkit every character uses. Nothing in here belongs to one
-- character; each character's own behaviour lives in ReplicatedStorage/Characters.
--
-- WHAT A CHARACTER CAN USE (Core.<name>)
--   world      Config, P (Config.Player), Map, EnemiesFolder, FxRemote, ActionRemote, states (per-player state),
--              Save (the save: Save.done(name) / Save.mark(name) for a one-time event, Save.on(name, fn) to replay it)
--   time/math  now(), flat(v), rand(lo, hi), turnTowards(root, pos, maxRad)
--   sound      SOUNDS (Slash, Lunge, Unsheath, Groan, Breath, Impact), playSound(parent, id, volume, speed)
--   effects    burst(pos, color, count, size, speed), fxAnchor(pos), dustCloud(pos, size, count),
--              debrisChunks(pos, n, power), crackLines(center, radius, n, color?, material?, reveal?),
--              fadeAway(parts, delay, time), crater(pos, radius), shockwave(pos, radius), flash(model),
--              groundHeave(pos, radius, lead)
--   poses      POSES (weapon grip poses), pose(actor, gripName, time, style?, direction?) (also sets the
--              matching body pose), bodyPose(actor, bodyPoseName, blend), setTrail(actor, on),
--              hitStopActor(actor, duration, freezeRoot), faceTowards(root, pos), poseCF(name, scale),
--              steerYaw(root, yaw) (turn a rig without teleporting it: see the note above faceTowards)
--   rigs       makeRig(name, kind, scale, weaponName) -> model, humanoid, gripWeld
--              giveWeapon(char, weaponName, scale) -> gripWeld, makeCorpse(model), ragdoll(model), applyLimbGroup(model)
--   players    aliveChar(player) -> char, hum, hrp, damagePlayer(player, amount, fromPos, level)
--              (level = "Small" | "Medium" | "Large" | "Knockdown" | "Launch"; returns true if it landed),
--              playersInSector(cf, range, halfAngle, height), playersInRadius(pos, radius, height),
--              spend(st, amount), setAction(st, t, total, dodgeAfter, attackAfter), cancelSwing(st),
--              syncStamina(player, st), equipWeapon(player, weaponName) (one of Config.Weapons)
--   enemies    enemiesInSector(cf, range, halfAngle), damageEnemy(model, amount, player, poise, hitStop),
--              registerTarget(fn): fn(model) -> nil or { owner, actor, maxPoise, freeze, armor,
--              onHit(player), onBreak(player, t, hitStop) }  (how hits find a character's poise)
--   status     poisonPlayer(player, opts), clearPoison(player), clearAllPoison()  (see POISON below)
--
-- An "actor" is { model, weld (the GripWeld), scale, root, ... }: anything pose() can animate.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local PhysicsService = game:GetService("PhysicsService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

-- Only the HumanoidRootPart touches the world; limbs/torsos/weapons don't.
-- This keeps the procedural roll from shoving the character into the floor.
pcall(function()
	PhysicsService:RegisterCollisionGroup("Limbs")
end)
PhysicsService:CollisionGroupSetCollidable("Limbs", "Default", false)
PhysicsService:CollisionGroupSetCollidable("Limbs", "Limbs", false)

-- Character root parts: players and enemies never physically touch each other.
-- That is what stops you climbing onto (or getting stuck on top of) enemies.
-- Spacing between them is handled by a soft push-apart on the client instead.
for _, g in ipairs({ "PlayerRoot", "EnemyRoot", "HitQuery" }) do
	pcall(function()
		PhysicsService:RegisterCollisionGroup(g)
	end)
end
PhysicsService:CollisionGroupSetCollidable("PlayerRoot", "EnemyRoot", false)
PhysicsService:CollisionGroupSetCollidable("PlayerRoot", "PlayerRoot", false)
PhysicsService:CollisionGroupSetCollidable("PlayerRoot", "Limbs", false)
PhysicsService:CollisionGroupSetCollidable("EnemyRoot", "Limbs", false)
-- HitQuery is only used by the sword's hit detection; it "sees" every group.
pcall(function()
	PhysicsService:RegisterCollisionGroup("Debris")
end)
for _, g in ipairs({ "PlayerRoot", "EnemyRoot", "Limbs", "Debris" }) do
	PhysicsService:CollisionGroupSetCollidable("Debris", g, false) -- rubble only bounces off the level
end
-- the dead are immaterial: corpses lie on the level, and the living walk straight through them
pcall(function()
	PhysicsService:RegisterCollisionGroup("Corpse")
end)
-- (nor each other: a ragdoll's own limbs and armour would otherwise fight it)
for _, g in ipairs({ "PlayerRoot", "EnemyRoot", "Limbs", "Debris", "Corpse" }) do
	PhysicsService:CollisionGroupSetCollidable("Corpse", g, false)
end
-- invisible walls only enemies bump into (the Consul's landing: nothing follows you up to him)
pcall(function()
	PhysicsService:RegisterCollisionGroup("EnemyWard")
end)
for _, g in ipairs(PhysicsService:GetRegisteredCollisionGroups()) do
	PhysicsService:CollisionGroupSetCollidable("EnemyWard", g.name, g.name == "EnemyRoot")
end

local function setLimbGroup(part)
	if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
		part.CollisionGroup = "Limbs"
	end
end

local function applyLimbGroup(model)
	for _, d in ipairs(model:GetDescendants()) do
		setLimbGroup(d)
	end
	model.DescendantAdded:Connect(setLimbGroup)
end
local MapBuilder = require((script.Parent :: any):WaitForChild("MapBuilder"))
local RigBuilder = require((script.Parent :: any):WaitForChild("RigBuilder"))
local Roster = require(ReplicatedStorage:WaitForChild("Roster"))

local P = Config.Player

---------------------------------------------------------------------------
-- remotes, folders, map
---------------------------------------------------------------------------
local Remotes = Instance.new("Folder")
Remotes.Name = "Remotes"
local ActionRemote = Instance.new("RemoteEvent")
ActionRemote.Name = "Action" -- client -> server
ActionRemote.Parent = Remotes
local FxRemote = Instance.new("RemoteEvent")
FxRemote.Name = "Fx" -- server -> client
FxRemote.Parent = Remotes
Remotes.Parent = ReplicatedStorage

local EnemiesFolder = Instance.new("Folder")
EnemiesFolder.Name = "Enemies"
EnemiesFolder.Parent = workspace

local Map = MapBuilder.build()
if workspace.StreamingEnabled then
	warn("[DGUS] Workspace.StreamingEnabled is ON. Turn it off (Workspace properties): streamed custom rigs sink into the floor on clients.")
end

ReplicatedStorage:SetAttribute("BossActive", false)
ReplicatedStorage:SetAttribute("BossName", Config.Boss.Name)
ReplicatedStorage:SetAttribute("Music", "none") -- none | boss | boss2 | victory (played by the Music client script)
---------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------
local function now()
	return os.clock()
end

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

-- Built-in Roblox sounds (swap these for your own asset ids for better audio).
local SOUNDS = {
	Slash = "rbxasset://sounds/swordslash.wav",
	Lunge = "rbxasset://sounds/swordlunge.wav",
	Unsheath = "rbxasset://sounds/unsheath.wav",
	-- (was Roblox's "uuhhh" injury groan - removed everywhere: deaths, boss growls,
	-- Oculast's hisses. Paste a growl/hiss asset id here to give them a voice again.)
	Groan = "",
	-- Oculast's breathing while she lies fallen. "" = a built-in wind sample shaped
	-- into breaths; paste a breathing asset id here for a real one.
	Breath = "",
	Impact = "rbxasset://sounds/collide.wav",
	WatchdogSmash = "rbxassetid://74149238738530", -- the Malformed Watchdog's twisting leap landing
	WatchdogBlast = "rbxassetid://94138990589559", -- its tail slash letting go
	Deflect = "rbxassetid://8820780818", -- crisp parry / deflect clash
	-- the Old Book's fireball: its cast (a whoosh; "" = silent - paste a fire-whoosh asset id
	-- here) and its burst (Roblox's built-in explosion)
	FireCast = "",
	FireHit = "rbxasset://sounds/impact_explosion_03.mp3",
	-- the Gozen Tachi's crackles: [1] on its draw, [2] and [3] by turns on its other cuts
	Lightning = { "rbxassetid://132801826635544", "rbxassetid://118075222341359", "rbxassetid://118156993756758" },
}

local Save = require(script.Parent:WaitForChild("Save"))
local function playSound(parent, id, volume, speed)
	if not parent or not parent.Parent or not id or id == "" or Save.quiet then -- (quiet: a save's events replaying)
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 0.6
	s.PlaybackSpeed = speed or 1
	s.RollOffMaxDistance = 160
	s.Parent = parent
	s:Play()
	Debris:AddItem(s, 6)
end

local function burst(pos, color, count, size, speed)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.Position = pos
	p.Parent = workspace
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 0
	pe.Lifetime = NumberRange.new(0.3, 0.7)
	pe.Speed = NumberRange.new((speed or 12) * 0.6, speed or 12)
	pe.SpreadAngle = Vector2.new(80, 80)
	pe.Acceleration = Vector3.new(0, -35, 0)
	pe.Color = ColorSequence.new(color)
	pe.Size = NumberSequence.new(size or 0.25, 0)
	pe.LightInfluence = 1
	pe.Parent = p
	pe:Emit(count or 12)
	Debris:AddItem(p, 1.5)
end

local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local function fxAnchor(pos)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.Position = pos
	p.Parent = workspace
	return p
end

-- a billowing cloud of dust
local function dustCloud(pos, size, count)
	local a = fxAnchor(pos)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = SMOKE
	pe.Rate = 0
	pe.Lifetime = NumberRange.new(1.4, 2.6)
	pe.Speed = NumberRange.new(size * 0.8, size * 2)
	pe.EmissionDirection = Enum.NormalId.Top
	pe.SpreadAngle = Vector2.new(85, 85)
	pe.Drag = 4
	pe.Acceleration = Vector3.new(0, 1.5, 0)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size * 0.35), NumberSequenceKeypoint.new(1, size * 1.1) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(0.6, 0.65), NumberSequenceKeypoint.new(1, 1) })
	pe.Color = ColorSequence.new(Color3.fromRGB(105, 98, 88))
	pe.Rotation = NumberRange.new(0, 360)
	pe.RotSpeed = NumberRange.new(-30, 30)
	pe.LightInfluence = 1
	pe.Parent = a
	pe:Emit(math.floor(count))
	Debris:AddItem(a, 3.2)
end

-- chunks of floor thrown into the air (they bounce off the level, never players)
local function debrisChunks(pos, n, power)
	for _ = 1, n do
		local c = Instance.new("Part")
		local sz = 0.35 + math.random() * 0.8
		c.Size = Vector3.new(sz, sz * (0.5 + math.random() * 0.6), sz * (0.6 + math.random() * 0.6))
		c.Material = Enum.Material.Slate
		c.Color = Color3.fromRGB(70, 66, 60):Lerp(Color3.fromRGB(30, 28, 26), math.random())
		c.CanQuery = false
		c.CanTouch = false
		c.CollisionGroup = "Debris"
		c.CFrame = CFrame.new(pos + Vector3.new(math.random() - 0.5, 0.4, math.random() - 0.5) * 2) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
		c.Parent = workspace
		local dir = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5)
		dir = dir.Magnitude > 0.01 and dir.Unit or Vector3.new(1, 0, 0)
		c.AssemblyLinearVelocity = dir * power * (0.3 + math.random() * 0.5) + Vector3.new(0, power * (0.5 + math.random() * 0.5), 0)
		c.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 20
		task.delay(1.8, function()
			if c.Parent then
				TweenService:Create(c, TweenInfo.new(0.7), { Transparency = 1 }):Play()
			end
		end)
		Debris:AddItem(c, 2.6)
	end
end

-- zigzag cracks radiating along the floor. reveal = seconds to spread out (0 = at once)
local function crackLines(center, radius, n, color, material, reveal)
	local list = {}
	for _ = 1, n do
		local ang = math.random() * math.pi * 2
		local prev = center + Vector3.new(math.cos(ang), 0, math.sin(ang)) * radius * 0.08
		local segs = math.random(3, 5)
		for k = 1, segs do
			local len = radius / segs * (0.8 + math.random() * 0.4)
			ang += (math.random() - 0.5) * 1.0
			local nxt = prev + Vector3.new(math.cos(ang), 0, math.sin(ang)) * len
			local seg = Instance.new("Part")
			seg.Name = "Crack"
			seg.Anchored = true
			seg.CanCollide = false
			seg.CanQuery = false
			seg.CanTouch = false
			seg.CastShadow = false
			seg.Material = material or Enum.Material.Slate
			seg.Color = color or Color3.fromRGB(20, 19, 18)
			seg.Size = Vector3.new(len + 0.1, 0.05, math.max(0.08, 0.3 * (1 - k / (segs + 1))))
			seg.CFrame = CFrame.new((prev + nxt) / 2) * CFrame.Angles(0, -ang, 0)
			if reveal and reveal > 0 then
				seg.Transparency = 1
				task.delay(reveal * (k - 1) / segs, function()
					seg.Transparency = 0
				end)
			end
			seg.Parent = workspace
			table.insert(list, seg)
			prev = nxt
		end
	end
	return list
end

local function fadeAway(list, delay, time)
	task.delay(delay, function()
		for _, p in ipairs(list) do
			if p.Parent then
				TweenService:Create(p, TweenInfo.new(time), { Transparency = 1 }):Play()
			end
		end
		task.wait(time + 0.1)
		for _, p in ipairs(list) do
			p:Destroy()
		end
	end)
end

-- the aftermath of a heavy blow: a cracked, dark dent in the stone
local function crater(pos, radius)
	local stain = Instance.new("Part")
	stain.Name = "Crater"
	stain.Anchored = true
	stain.CanCollide = false
	stain.CanQuery = false
	stain.CanTouch = false
	stain.CastShadow = false
	stain.Shape = Enum.PartType.Cylinder
	stain.Material = Enum.Material.Slate
	stain.Color = Color3.fromRGB(30, 28, 26)
	stain.Transparency = 0.35
	stain.Size = Vector3.new(0.05, radius * 1.4, radius * 1.4)
	stain.CFrame = CFrame.new(pos.X, pos.Y - 0.15, pos.Z) * CFrame.Angles(0, 0, math.pi / 2)
	stain.Parent = workspace
	local list = crackLines(Vector3.new(pos.X, pos.Y - 0.14, pos.Z), radius, 7)
	table.insert(list, stain)
	fadeAway(list, 5, 2)
end

-- physical impact: dust cloud, thrown rubble, cracked crater (no rings)
local function shockwave(pos, radius)
	dustCloud(pos + Vector3.new(0, 0.6, 0), radius * 0.55, 14 + radius * 1.5)
	debrisChunks(pos + Vector3.new(0, 0.5, 0), math.clamp(math.floor(radius * 0.7), 3, 12), 25 + radius * 1.5)
	crater(pos, radius * 0.6)
end

local function flash(model)
	local h = Instance.new("Highlight")
	h.FillColor = Color3.new(1, 1, 1)
	h.FillTransparency = 0.55
	h.OutlineTransparency = 1
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = model
	Debris:AddItem(h, 0.08)
end
---------------------------------------------------------------------------
-- weapons + attack poses
--
-- Weapons are welded to the HumanoidRootPart and every attack is animated by
-- tweening that ONE weld. This works identically on R6, R15 and Roblox's newer
-- AnimationConstraint-based avatar joints (which have no Motor6D.C0 to animate).
-- The arm is posed too, but only best-effort: if the rig uses the new joints
-- the arm simply stays put and the weapon still swings.
---------------------------------------------------------------------------
local bodyPose -- defined below with pose()
local R = math.rad
local SIDE = CFrame.Angles(0, 0, R(90)) -- blade pointing out to the right

-- Grip position (studs, relative to the root at scale 1) + grip orientation.
-- The blade extends along the grip's -Y axis.
local POSES = {
	-- shared grips (every one-handed weapon swings through these)
	Idle = { Vector3.new(1.3, -0.4, -0.5), CFrame.Angles(R(60), 0, 0) },
	Raise = { Vector3.new(1.0, 2.4, 0.4), CFrame.Angles(R(233), 0, R(8)) },
	Mid = { Vector3.new(0.6, 2.2, -1.4), CFrame.Angles(R(135), 0, 0) },
	Strike = { Vector3.new(0.2, -0.2, -1.8), CFrame.Angles(0, R(15), 0) * CFrame.Angles(R(50), 0, 0) },
	SweepBack = { Vector3.new(1.6, 0.8, 0.8), CFrame.Angles(0, R(-40), 0) * SIDE },
	SweepMid = { Vector3.new(0, 0.8, -1.8), CFrame.Angles(0, R(90), 0) * SIDE },
	SweepEnd = { Vector3.new(-1.0, 0.8, -0.8), CFrame.Angles(0, R(200), 0) * SIDE },
	Flinch = { Vector3.new(1.4, 0.3, 0.3), CFrame.Angles(R(100), 0, R(25)) },
	Drink = { Vector3.new(1.5, -0.6, 0.6), CFrame.Angles(R(20), 0, 0) },
}
-- each character adds its own grips (see Characters/*.lua, M.Grips)
for name, g in pairs(Roster.grips) do
	POSES[name] = g
end

local function poseCF(name, scale)
	local p = POSES[name]
	return CFrame.new(p[1] * scale) * p[2]
end
-- a dual-wielder's left sword: its own grip "L<name>" if the pose has one, else the right's mirrored
local function poseCFLeft(name, scale)
	if POSES["L" .. name] then
		return poseCF("L" .. name, scale)
	end
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = poseCF(name, scale):GetComponents()
	return CFrame.new(-x, y, z, r00, -r01, -r02, -r10, r11, r12, -r20, r21, r22)
end

-- Only classic, enabled Motor6Ds can be posed this way; anything else is skipped.
local function findShoulder(char)
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("Motor6D") and d.Enabled and d.Part1 and (d.Part1.Name == "RightUpperArm" or d.Part1.Name == "Right Arm") then
			return d
		end
	end
	return nil
end

local BODY_FOR = {
	Idle = "Idle", Raise = "Windup", Strike = "Strike", SweepBack = "SweepWindup", SweepEnd = "SweepEnd",
	Flinch = "Flinch", Drink = "Drink",
}
for name, b in pairs(Roster.bodyFor) do
	BODY_FOR[name] = b
end

bodyPose = function(actor, name, blend)
	local m = actor and (actor.model or (actor.root and actor.root.Parent))
	if not m or not m.Parent then
		return
	end
	m:SetAttribute("BP", name)
	m:SetAttribute("BPT", blend or 0.2)
	m:SetAttribute("BPN", (m:GetAttribute("BPN") or 0) + 1)
end

local function pose(actor, name, t, style, direction)
	if not actor then
		return
	end
	local toIdle = name == "Idle"
	if toIdle and actor.idleGrip then
		name = actor.idleGrip -- each weapon rests in its own grip (Config.Weapons)
	end
	local info = TweenInfo.new(math.max(t, 0.01), style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
	local weld = actor.weld
	if weld and weld.Parent then
		pcall(function()
			local tw = TweenService:Create(weld, info, { C0 = poseCF(name, actor.scale or 1) })
			actor.tween = tw
			tw:Play()
		end)
	end
	local weld2 = actor.weld2
	if weld2 and weld2.Parent then
		pcall(function()
			TweenService:Create(weld2, info, { C0 = poseCFLeft(name, actor.scale or 1) }):Play()
		end)
	end
	-- the body follows: each weapon pose has a matching full-body pose
	local body = BODY_FOR[name] or (toIdle and "Idle") -- (back to guard: the body too, not just the weapon)
	if body then
		bodyPose(actor, body, t)
	end
end

local function setTrail(actor, on)
	for _, weld in ipairs({ actor and actor.weld or false, actor and actor.weld2 or false }) do
		local weapon = weld and weld.Parent and weld.Parent.Parent
		if weapon then
			local trail = weapon:FindFirstChildWhichIsA("Trail", true)
			if trail then
				trail.Enabled = on
			end
		end
	end
end

-- Hit-stop: freeze an actor's swing (and, for regular enemies, their body) for an instant.
local function hitStopActor(actor, duration, freezeRoot)
	if not actor or not duration or duration <= 0 then
		return
	end
	local tw = actor.tween
	if tw and tw.PlaybackState == Enum.PlaybackState.Playing then
		tw:Pause()
		task.delay(duration, function()
			if actor.tween == tw and tw.PlaybackState == Enum.PlaybackState.Paused then
				tw:Play()
			end
		end)
	end
	local root = freezeRoot and actor.root
	if root and root.Parent and not root.Anchored then
		root.Anchored = true
		task.delay(duration, function()
			if root.Parent then
				root.Anchored = false
				pcall(function()
					root:SetNetworkOwner(nil)
				end)
			end
		end)
	end
end

-- Turning a standing (unanchored) rig by writing its root's CFrame teleports it, and a
-- Humanoid teleported every frame keeps losing its footing: it dips into the floor and
-- the rig guard pops it back up, several times a second (the long-running flicker). So
-- unanchored roots are turned by an AlignOrientation - a physical twist, no teleport -
-- and only anchored roots (mid-leap, mid-charge) are still set directly. The aligner lets
-- go a moment after nothing steers it, so the Humanoid's own AutoRotate takes over again.
local aligners = {} -- [root] = { ao = AlignOrientation, hold = time it lets go }
local function steerYaw(root, yaw)
	if root.Anchored then
		root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, yaw, 0)
		return
	end
	local a = aligners[root]
	if not (a and a.ao.Parent) then
		local att = Instance.new("Attachment")
		att.Name = "SteerAttachment"
		att.Parent = root
		local ao = Instance.new("AlignOrientation")
		ao.Name = "Steer"
		ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
		ao.Attachment0 = att
		ao.MaxTorque = math.huge
		ao.Responsiveness = 60
		ao.Parent = root
		a = { ao = ao }
		aligners[root] = a
	end
	a.ao.CFrame = CFrame.Angles(0, yaw, 0)
	a.ao.Enabled = true
	a.hold = now() + 0.25
end
game:GetService("RunService").Heartbeat:Connect(function()
	local t = now()
	for root, a in pairs(aligners) do
		if not root.Parent or not a.ao.Parent then
			aligners[root] = nil
		elseif a.ao.Enabled and t > a.hold then
			a.ao.Enabled = false
		end
	end
end)
local function yawOf(v)
	return math.atan2(-v.X, -v.Z)
end

local function faceTowards(root, pos)
	local want = flat(pos - root.Position)
	if want.Magnitude > 0.1 then
		steerYaw(root, yawOf(want))
	end
end
-- Builds a weapon welded to the root. Returns the animated Weld (or nil).
-- The weapon's shape comes from the character file that defines it (M.Weapons).
local function giveWeapon(char, kind, scale, second)
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	scale = scale or 1
	local modelName = second and "Weapon2" or "Weapon" -- (a dual-wielder's left sword)
	local old = char:FindFirstChild(modelName)
	if old then
		old:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = modelName

	local function mk(name, size, color, material)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size * scale
		p.Color = color
		p.Material = material
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CastShadow = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end

	local parts = {} -- { part, offsetY, rotation?, offsetZ? } relative to the handle
	local build = Roster.weapons[kind]
	assert(build, "[DGUS] no character file defines the weapon '" .. tostring(kind) .. "'")
	local spec = build({
		mk = mk,
		add = function(p, offsetY, rot, offsetZ)
			table.insert(parts, { p, offsetY, rot, offsetZ })
		end,
		R = R,
		scale = scale,
		wood = Color3.fromRGB(52, 38, 28),
		iron = Color3.fromRGB(46, 42, 38),
	})
	local handle, bladeLen = spec.handle, spec.bladeLen or 3

	-- the one weld that animates everything
	local grip = Instance.new("Weld")
	grip.Name = "GripWeld"
	grip.Part0 = root
	grip.Part1 = handle
	grip.C0 = second and poseCFLeft("Idle", scale) or poseCF("Idle", scale)
	if spec.gripC1 then
		grip.C1 = spec.gripC1 -- where along the handle the hand holds it
	end
	grip.Parent = handle
	handle.CFrame = root.CFrame * grip.C0 * grip.C1:Inverse()

	for _, entry in ipairs(parts) do
		local p, offsetY = entry[1], entry[2]
		local w = Instance.new("Weld")
		w.Part0 = handle
		w.Part1 = p
		w.C0 = CFrame.new(0, offsetY * scale, (entry[4] or 0) * scale) * (entry[3] or CFrame.new())
		w.Parent = p
		p.CFrame = handle.CFrame * w.C0
	end

	-- swing trail along the blade (enabled only during strikes)
	local a0 = Instance.new("Attachment")
	a0.Name = "BladeBase"
	a0.Position = Vector3.new(0, -0.6 * scale, 0)
	a0.Parent = handle
	local a1 = Instance.new("Attachment")
	a1.Name = "BladeTip"
	a1.Position = Vector3.new(0, -(0.6 + bladeLen) * scale, 0)
	a1.Parent = handle
	if spec.setup then
		spec.setup(handle, a0, a1) -- extra attachments, emitters...
	end
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.16
	trail.MinLength = 0
	trail.FaceCamera = true
	trail.LightEmission = 0.3
	trail.Color = ColorSequence.new(Color3.fromRGB(235, 225, 205))
	trail.Transparency = NumberSequence.new(0.35, 1)
	trail.Enabled = false
	trail.Parent = handle

	model.Parent = char
	return grip
end

---------------------------------------------------------------------------
-- player state
---------------------------------------------------------------------------
local states = {}

local function aliveChar(player)
	local char = player.Character
	if not char then
		return nil
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hum and hrp and hum.Health > 0 then
		return char, hum, hrp
	end
	return nil
end

local function syncStamina(player, st)
	local v = math.floor(st.stamina + 0.5)
	if player:GetAttribute("Stamina") ~= v then
		player:SetAttribute("Stamina", v)
	end
end

local function spend(st, amount)
	-- like the souls games: any stamina above zero lets you act
	if st.stamina <= 0 then
		return false
	end
	st.stamina = math.max(0, st.stamina - amount)
	st.lastSpend = now()
	return true
end

-- What the player is doing right now, as three timestamps:
--   dodgeAt  - from when a roll may cancel it
--   attackAt - from when an attack (or flask) may cancel it
--   busyUntil- when it is fully over (stamina regen waits for this)
local function setAction(st, t, total, dodgeAfter, attackAfter)
	st.busyUntil = t + total
	st.dodgeAt = t + (dodgeAfter or total)
	st.attackAt = t + (attackAfter or total)
end

local function cancelSwing(st)
	st.attackId = (st.attackId or 0) + 1 -- stops the swing's visuals and its hit sweep
	setTrail(st, false)
	pose(st, "Idle", 0.15)
end

local targets = {}
local function registerTarget(fn)
	table.insert(targets, fn)
end

local REACT = Config.HitReactions

local damageEnemy -- defined below; the scythe deflect hits back with it

---------------------------------------------------------------------------
-- STATUS BADGES: a status's name over a bar, on the player's screen (Poison's, Break's)
---------------------------------------------------------------------------
-- built into gui at pos; col = its bar and outline. Returns the bar's fill (and its label).
local function statusBadge(gui, text, pos, col, textCol, backCol, bgCol)
	local badge = Instance.new("Frame")
	badge.Name = "Badge"
	badge.Size = UDim2.fromOffset(200, 44)
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = pos
	badge.BackgroundColor3 = bgCol
	badge.BackgroundTransparency = 0.2
	badge.BorderSizePixel = 0
	badge.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = badge
	local stroke = Instance.new("UIStroke")
	stroke.Color = col
	stroke.Thickness = 1.5
	stroke.Transparency = 0.2
	stroke.Parent = badge
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -20, 0, 20)
	label.Position = UDim2.fromOffset(10, 4)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = textCol
	label.Font = Enum.Font.Garamond
	label.TextSize = 20
	label.Parent = badge
	local back = Instance.new("Frame")
	back.Name = "BarBack"
	back.Size = UDim2.new(1, -20, 0, 8)
	back.Position = UDim2.fromOffset(10, 28)
	back.BackgroundColor3 = backCol
	back.BorderSizePixel = 0
	back.Parent = badge
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = col
	fill.BorderSizePixel = 0
	fill.Parent = back
	return fill, label
end

---------------------------------------------------------------------------
-- BREAK (Config.Break): breakPlayer(player, amount) builds it (the dogs' bites). The meter
-- shows on a badge above Poison's while it's up; full, you're BROKEN and every hit on you
-- does DamageMult times as much (damagePlayer), the badge counting it down.
---------------------------------------------------------------------------
local BREAK = {} -- [player] = { value, last, brokenUntil, char, gui, fill, label }
local BCOL = Color3.fromRGB(196, 92, 64) -- a raw, bruised orange-red
local function clearBreak(pl)
	local b = BREAK[pl]
	BREAK[pl] = nil
	pl:SetAttribute("Broken", nil) -- (the client lets you walk again)
	if b and b.gui and b.gui.Parent then
		b.gui:Destroy()
	end
end
local function breakMult(pl)
	local b = BREAK[pl]
	return (b and now() < b.brokenUntil) and Config.Break.DamageMult or 1
end
local function breakPlayer(pl, amount)
	local char, _, hrp = aliveChar(pl)
	if not char then
		return
	end
	local CFG = Config.Break
	local b = BREAK[pl]
	if not b or b.char ~= char then
		clearBreak(pl)
		local pg = pl:FindFirstChildOfClass("PlayerGui")
		if not pg then
			return
		end
		local gui = Instance.new("ScreenGui")
		gui.Name = "Break"
		gui.ResetOnSpawn = true
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = 5
		local fill, label = statusBadge(gui, "BREAK", CFG.HudPosition, BCOL, Color3.fromRGB(240, 196, 170), Color3.fromRGB(44, 24, 20), Color3.fromRGB(22, 12, 10))
		gui.Parent = pg
		b = { value = 0, last = now(), brokenUntil = 0, char = char, gui = gui, fill = fill, label = label }
		BREAK[pl] = b
	end
	b.last = now()
	if now() < b.brokenUntil then
		return -- (broken already: it can't fill any further)
	end
	b.value = math.min(CFG.Max, b.value + amount)
	if b.value >= CFG.Max then
		b.brokenUntil = now() + CFG.Duration
		b.label.Text = "BROKEN"
		pl:SetAttribute("Broken", true) -- (the client roots you while it's set)
		burst(hrp.Position + Vector3.new(0, 1, 0), BCOL, 30, 0.45, 18)
		playSound(hrp, SOUNDS.Impact, 0.9, 0.6)
	end
end
-- the meter drains when it's left alone; broken, the badge counts down, then it's gone
game:GetService("RunService").Heartbeat:Connect(function(dt)
	local CFG = Config.Break
	for pl, b in pairs(BREAK) do
		if not pl.Parent or aliveChar(pl) ~= b.char then
			clearBreak(pl)
		elseif now() < b.brokenUntil then
			b.fill.Size = UDim2.fromScale((b.brokenUntil - now()) / CFG.Duration, 1)
		elseif b.brokenUntil > 0 then
			clearBreak(pl) -- (it's run its course)
		else
			if now() - b.last > CFG.DrainDelay then
				b.value -= CFG.DrainPerSec * dt
			end
			if b.value <= 0 then
				clearBreak(pl)
			else
				b.fill.Size = UDim2.fromScale(b.value / CFG.Max, 1)
			end
		end
	end
end)

-- level: "Small" | "Medium" | "Large" | "Knockdown" | "Launch" (Config.HitReactions); push: optional speed overriding its Push
local function damagePlayer(player, amount, fromPos, level, push)
	local st = states[player]
	local char, hum, hrp = aliveChar(player)
	if not st or not char then
		return false
	end
	level = REACT[level] and level or "Medium"
	local t = now()
	if st.devGod or (t >= st.iStart and t <= st.iEnd) then -- (devGod: the dev menu's infinite i-frames)
		if Config.Debug then
			print(string.format("[Deflect] hit absorbed by i-frames (%.2fs left)", st.iEnd - t))
		end
		return false -- rolled through it (or still down from a knockdown, or deflect i-frames)
	end
	if t < st.hurtImmuneUntil then
		if Config.Debug then
			print("[Deflect] hit absorbed: just hurt (0.4s grace)")
		end
		return false
	end
	if Config.Debug and (st.deflectEnd or 0) > 0 then
		print(string.format("[Deflect] hit at %+.2fs from the window opening", t - (st.deflectStart or 0)))
	end

	-- LIES OF P STYLE DEFLECT (SCYTHE EXCLUSIVE):
	-- If the player hit deflect and then a few frames later they WOULD have taken an instance of damage,
	-- deflect the hit completely: 0 damage, crisp deflect sound instantly, and i-frames for 2/3rds of a dodgeroll
	-- without moving like a dodge.
	local isScythe = player:GetAttribute("Weapon") == "Scythe"
	if isScythe and st.deflectEnd and (st.deflectEnd > 0) and t >= (st.deflectStart or 0) and t <= st.deflectEnd then
		st.deflectEnd = 0 -- consume deflect window
		local CFG = Config.ScytheDeflect
		local iDur = CFG.IFrameDuration -- 2/3rds of dodgeroll (~0.26s)
		st.iStart = t
		st.iEnd = t + iDur

		-- Sound: crisp deflect sound instantly on hrp
		playSound(hrp, SOUNDS.Deflect, 1.0, 1.0)
		playSound(hrp, CFG.Sound2, 0.9, 1.3)
		playSound(hrp, SOUNDS.Unsheath, 0.7, 1.8)

		-- Sparks burst towards the incoming attack
		local dir = flat(fromPos - hrp.Position)
		dir = dir.Magnitude > 0.01 and dir.Unit or hrp.CFrame.LookVector
		local sparkPos = hrp.Position + dir * 1.5 + Vector3.new(0, 1.2, 0)
		burst(sparkPos, Color3.fromRGB(255, 235, 140), 25, 0.35, 18)
		burst(sparkPos, Color3.fromRGB(255, 255, 255), 15, 0.2, 12)

		-- Client feedback: screen shake & instant confirm
		FxRemote:FireClient(player, "DeflectConfirm", sparkPos)
		FxRemote:FireAllClients("Shake", sparkPos, 0.45)

		-- Deflect parry pose hold, then return to Idle
		pose(st, "UDeflect", 0.04)
		task.delay(iDur, function()
			pose(st, "Idle", 0.15)
		end)

		-- the deflect cuts back: damage + 1.5x posture to every enemy within a scythe's length
		for _, enemy in ipairs(EnemiesFolder:GetChildren()) do
			local eroot = enemy:FindFirstChild("HumanoidRootPart")
			if eroot and flat(eroot.Position - hrp.Position).Magnitude <= CFG.Radius + (enemy:GetAttribute("Radius") or 0) then
				damageEnemy(enemy, CFG.Damage, player, CFG.Poise, 0.12)
			end
		end

		return false
	end

	local r = REACT[level]
	st.hurtImmuneUntil = t + 0.4
	hum:TakeDamage(amount * breakMult(player)) -- (broken: Config.Break)
	st.healing = false
	st.lastKind = nil
	st.deflectEnd = 0 -- hit mid-twirl: that deflect is lost
	cancelSwing(st)
	setAction(st, t, r.Stun, r.RollOut or r.Stun, r.Stun)
	if r.Down then
		st.iStart, st.iEnd = t + r.IFrom, t + r.ITo
	end
	local dir = flat(hrp.Position - fromPos)
	dir = dir.Magnitude > 0.01 and dir.Unit or -flat(hrp.CFrame.LookVector).Unit
	FxRemote:FireClient(player, "Hurt", dir, level, push)
	burst(hrp.Position + Vector3.new(0, 1, 0), Color3.fromRGB(110, 10, 10), 16, 0.3, 14)
	playSound(hrp, SOUNDS.Impact, 0.35, 1.4)
	return true
end

local function playersInSector(cf, range, halfAngle, height)
	local out = {}
	local look = flat(cf.LookVector).Unit
	for _, pl in ipairs(Players:GetPlayers()) do
		local char, _, hrp = aliveChar(pl)
		if char then
			local rel = hrp.Position - cf.Position
			local fl = flat(rel)
			if fl.Magnitude <= range + 1 and math.abs(rel.Y) <= height then
				if fl.Magnitude < 2 or math.deg(math.acos(math.clamp(fl.Unit:Dot(look), -1, 1))) <= halfAngle then
					table.insert(out, pl)
				end
			end
		end
	end
	return out
end

local function playersInRadius(pos, radius, height)
	local out = {}
	for _, pl in ipairs(Players:GetPlayers()) do
		local char, _, hrp = aliveChar(pl)
		if char then
			local rel = hrp.Position - pos
			if flat(rel).Magnitude <= radius + 1 and math.abs(rel.Y) <= height then
				table.insert(out, pl)
			end
		end
	end
	return out
end

local function enemiesInSector(cf, range, halfAngle)
	local out = {}
	local look = flat(cf.LookVector).Unit
	for _, m in ipairs(EnemiesFolder:GetChildren()) do
		local hum = m:FindFirstChildOfClass("Humanoid")
		local root = m:FindFirstChild("HumanoidRootPart")
		if hum and root and hum.Health > 0 then
			local rel = root.Position - cf.Position
			local fl = flat(rel)
			local radius = m:GetAttribute("Radius") or 1.2
			if fl.Magnitude - radius <= range and math.abs(rel.Y) <= 14 then
				if fl.Magnitude <= radius + 1.5 or math.deg(math.acos(math.clamp(fl.Unit:Dot(look), -1, 1))) <= halfAngle then
					table.insert(out, m)
				end
			end
		end
	end
	return out
end
local function makeRig(name, kind, scale, weaponKind)
	local model, hum = RigBuilder.build(kind, scale)
	model.Name = name
	pcall(function()
		-- never streamed in piece by piece (that is what sinks custom rigs on clients)
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	local weld = weaponKind and giveWeapon(model, weaponKind, scale) or nil -- (a dog has no weapon)
	applyLimbGroup(model)
	model.Parent = EnemiesFolder
	hum.HipHeight = model:GetAttribute("HipHeight") -- again, after parenting
	return model, hum, weld
end

-- RIG GUARD: keeps every rig standing at its true height. Re-asserts HipHeight
-- (Roblox can recompute it) and lifts any unanchored, server-owned rig whose
-- root has sunk toward the floor back onto it.
local guardParams = RaycastParams.new()
guardParams.FilterType = Enum.RaycastFilterType.Exclude
guardParams.RespectCanCollide = true -- (else a rig walking under a hanging chain or banner is lifted onto it)
local function guardRig(model, serverOwned)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	local want = model:GetAttribute("HipHeight")
	local stand = model:GetAttribute("StandHeight")
	if not (hum and root and want and stand) or hum.Health <= 0 then
		return
	end
	if math.abs(hum.HipHeight - want) > 0.01 then
		hum.HipHeight = want
	end
	if serverOwned and not root.Anchored then
		-- a player's client must never simulate a rig (its posed legs and HipHeight differ there)
		local okOwner, owner = pcall(function()
			return root:GetNetworkOwner()
		end)
		if okOwner and owner ~= nil then
			pcall(function()
				root:SetNetworkOwner(nil)
			end)
		end
		guardParams.FilterDescendantsInstances = { EnemiesFolder }
		guardParams.CollisionGroup = root.CollisionGroup -- (the Castellan walks through props: don't stand him on them)
		local res = workspace:Raycast(root.Position + Vector3.new(0, stand, 0), Vector3.new(0, -stand * 3, 0), guardParams)
		if res and root.Position.Y - res.Position.Y < stand - 0.6 then
			-- it has stopped holding itself up: lift it, and put its Humanoid back into its
			-- standing state (a waiting rig that isn't "Running" just sinks, again and again)
			local state = hum:GetState()
			root.CFrame = root.CFrame + Vector3.new(0, res.Position.Y + stand - root.Position.Y, 0)
			root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
			pcall(function()
				hum:ChangeState(Enum.HumanoidStateType.Running)
			end)
			if Config.Debug and os.clock() - (model:GetAttribute("GuardLog") or 0) > 2 then
				model:SetAttribute("GuardLog", os.clock())
				print(string.format("[RigGuard] lifted %s out of the floor (state %s, owner %s, HipHeight %.2f)", model.Name, state.Name, okOwner and tostring(owner) or "?", hum.HipHeight))
			end
		end
	end
end
task.spawn(function()
	while true do
		for _, m in ipairs(EnemiesFolder:GetChildren()) do
			guardRig(m, true)
		end
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl.Character then
				guardRig(pl.Character, false)
			end
		end
		task.wait(0.1)
	end
end)
-- BOSS FOOTING: a boss's height is held on the floor under it every frame. (The rig guard
-- above only steps in once a rig has sunk well into the floor and then pops it back up;
-- for the heavy bosses that dip-and-pop read as bouncing.) Skipped while the root is
-- anchored (leaps, charges, her floating moves: those carry it themselves) or while the
-- model is flagged "Airborne" (a move that throws it into the air, e.g. the Warden's stomp).
local footParams = RaycastParams.new()
footParams.FilterType = Enum.RaycastFilterType.Exclude
footParams.RespectCanCollide = true
game:GetService("RunService").Heartbeat:Connect(function()
	local ignore
	for _, m in ipairs(EnemiesFolder:GetChildren()) do
		local root, hum, stand = m:FindFirstChild("HumanoidRootPart"), m:FindFirstChildOfClass("Humanoid"), m:GetAttribute("StandHeight")
		if m:GetAttribute("Boss") and not m:GetAttribute("Airborne") and root and hum and stand and hum.Health > 0 and not root.Anchored then
			if not ignore then
				ignore = { EnemiesFolder }
				for _, pl in ipairs(Players:GetPlayers()) do
					if pl.Character then
						table.insert(ignore, pl.Character)
					end
				end
				footParams.FilterDescendantsInstances = ignore
			end
			footParams.CollisionGroup = root.CollisionGroup
			local res = workspace:Raycast(root.Position, Vector3.new(0, -stand * 2, 0), footParams)
			if res then
				local dy = res.Position.Y + stand - root.Position.Y
				if math.abs(dy) > 0.03 and math.abs(dy) < stand then
					root.CFrame += Vector3.new(0, dy, 0)
					local v = root.AssemblyLinearVelocity
					root.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
				end
			end
		end
	end
end)

local function makeCorpse(model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CollisionGroup = "Corpse"
			d.CanCollide = d.Name ~= "HumanoidRootPart"
			d.Massless = false
		end
	end
end
-- Go limp (call after makeCorpse; the rig needs BreakJointsOnDeath = false): every body
-- joint becomes a loose ball socket, the root rides along with the hips, and the weapon
-- drops out of the hand, so the body crumples to the floor.
local function ragdoll(model)
	local root = model:FindFirstChild("HumanoidRootPart")
	for _, m in ipairs(model:GetDescendants()) do
		if m:IsA("Motor6D") and m.Part0 and m.Part1 then
			if m.Part0 == root then
				local w = Instance.new("WeldConstraint")
				w.Part0, w.Part1 = root, m.Part1
				w.Parent = root
			else
				local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
				a0.CFrame, a1.CFrame = m.C0, m.C1
				a0.Parent, a1.Parent = m.Part0, m.Part1
				local bs = Instance.new("BallSocketConstraint")
				bs.Attachment0, bs.Attachment1 = a0, a1
				bs.LimitsEnabled = true
				bs.UpperAngle = 60
				bs.TwistLimitsEnabled = true
				bs.TwistLowerAngle, bs.TwistUpperAngle = -40, 40
				bs.Parent = m.Part1
			end
			m.Enabled = false
		end
	end
	local grip = model:FindFirstChild("GripWeld", true)
	if grip then
		grip:Destroy()
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("AlignOrientation") then
			d:Destroy() -- (the steering twist: a corpse falls however it falls)
		end
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			pcall(function()
				d:SetNetworkOwner(nil) -- the server drops them, so every client sees the same fall
			end)
		end
	end
end
-- turn at most maxRad toward pos (no instant snapping)
local function turnTowards(root, pos, maxRad)
	local p = root.Position
	local want = flat(pos - p)
	if want.Magnitude < 0.1 then
		return
	end
	-- step from where it's already being steered (the aligner lags the real facing a touch)
	local a = aligners[root]
	local curYaw = (a and a.ao.Enabled and not root.Anchored) and select(2, a.ao.CFrame:ToOrientation()) or yawOf(flat(root.CFrame.LookVector))
	local d = (yawOf(want) - curYaw + math.pi) % (2 * math.pi) - math.pi
	steerYaw(root, curYaw + math.clamp(d, -maxRad, maxRad))
end
local function rand(lo, hi)
	return lo + math.random() * (hi - lo)
end
-- The floor heaves before something bursts out of it: spreading cracks,
-- puffs of dust, hopping pebbles and a low rumble. No markers.
local function groundHeave(pos, radius, lead)
	local cracks = crackLines(Vector3.new(pos.X, pos.Y + 0.03, pos.Z), radius, 5, nil, nil, lead * 0.8)
	fadeAway(cracks, lead + 2, 1.5)
	local rumble = fxAnchor(pos + Vector3.new(0, 1, 0))
	playSound(rumble, SOUNDS.Impact, 0.35, 0.25)
	Debris:AddItem(rumble, lead + 1)
	for i = 0, 1 do
		task.delay(lead * i * 0.5, function()
			dustCloud(pos + Vector3.new(0, 0.3, 0), radius * 0.22, 4)
			for _ = 1, 4 do
				local pb = Instance.new("Part")
				pb.Size = Vector3.new(0.25, 0.2, 0.25)
				pb.Material = Enum.Material.Slate
				pb.Color = Color3.fromRGB(80, 76, 70)
				pb.CanQuery = false
				pb.CanTouch = false
				pb.CollisionGroup = "Debris"
				pb.Position = pos + Vector3.new((math.random() - 0.5) * radius, 0.3, (math.random() - 0.5) * radius)
				pb.Parent = workspace
				pb.AssemblyLinearVelocity = Vector3.new(0, 10 + math.random() * 8, 0)
				Debris:AddItem(pb, 1.2)
			end
		end)
	end
end

-- BONE SPLINTER: every boss leaves one on the floor where it fell (ignore = its model).
-- Taken once, by whoever gets there first ("Splinters" attribute); each one raises a stat
-- by 1 at a bonfire (the "LevelUp" action, init.server).
local function dropSplinter(pos, ignore)
	task.delay(3, function()
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = { ignore }
		local hit = workspace:Raycast(pos, Vector3.new(0, -60, 0), params)
		local at = (hit and hit.Position or pos) + Vector3.new(0, 0.8, 0)
		local p = Instance.new("Part")
		p.Name = "BoneSplinter"
		p.Size = Vector3.new(0.3, 1.3, 0.3)
		p.Color = Color3.fromRGB(226, 214, 186)
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored, p.CanCollide, p.CanTouch = true, false, false
		p.CFrame = CFrame.new(at) * CFrame.Angles(0.5, math.random() * 6, 0.3)
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 226, 170), 8, 1.2
		l.Parent = p
		local pp = Instance.new("ProximityPrompt")
		pp.ActionText = "Take"
		pp.ObjectText = "Bone Splinter"
		pp.HoldDuration = 0.3
		pp.MaxActivationDistance = 10
		pp.RequiresLineOfSight = false
		pp.Parent = p
		p.Parent = workspace
		burst(at, Color3.fromRGB(255, 226, 170), 16, 0.3, 8)
		pp.Triggered:Connect(function(pl)
			if not pp.Enabled then
				return
			end
			pp.Enabled = false
			p:Destroy()
			pl:SetAttribute("Splinters", (pl:GetAttribute("Splinters") or 0) + 1)
			FxRemote:FireClient(pl, "Message", "Bone Splinter. Rest at a bonfire to grow stronger.")
		end)
	end)
end

---------------------------------------------------------------------------
-- hits on enemies: every character registers how to find its poise/actor
---------------------------------------------------------------------------
-- (targets and registerTarget declared above)

function damageEnemy(model, amount, player, poiseDamage, hitStop)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health <= 0 then
		return
	end
	local info
	for _, fn in ipairs(targets) do
		info = fn(model)
		if info then
			break
		end
	end
	if info and info.evade and info.evade(player) then
		return -- slipped the blow (e.g. Oculast's counter stance)
	end
	if info and info.damageMult then
		amount *= info.damageMult(player)
	end
	hum:TakeDamage(amount)
	flash(model)
	burst(root.Position + Vector3.new(0, (model:GetAttribute("Radius") or 1) * 0.5, 0), Color3.fromRGB(90, 12, 10), 14, 0.3, 14)
	playSound(root, SOUNDS.Impact, 0.5, 1.6 + math.random() * 0.3)
	FxRemote:FireClient(player, "HitConfirm", hitStop or 0)
	if hum.Health <= 0 then
		player:SetAttribute("Kills", (player:GetAttribute("Kills") or 0) + 1) -- (Giles counts them: Config.Taylor)
		-- a kill with the Usher's harvest-blade may leave a Bone Splinter (Config.ScytheSplinter)
		local S = Config.ScytheSplinter
		if player:GetAttribute("Weapon") == "Scythe" and math.random() < S.Chance + S.PerDarkness * Config.statOf(player, "Darkness") then
			dropSplinter(root.Position, model)
		end
		return
	end
	if not info then
		return
	end
	if info.onHit then
		info.onHit(player)
	end
	-- hit-stop: the target's swing freezes too (regular enemies freeze in place)
	hitStopActor(info.actor, hitStop, info.freeze == true)
	-- poise: chip it down; when it breaks, the target staggers
	local owner = info.owner
	local t = now()
	if not owner.poise or t - (owner.lastPoiseHit or 0) > 5 then
		owner.poise = info.maxPoise -- poise recovers if left alone for a few seconds
	end
	owner.lastPoiseHit = t
	local dmg = poiseDamage or 10
	if info.armor then
		dmg *= 0.5 -- hyper armor: tougher to interrupt mid-swing
	end
	owner.poise -= dmg
	if owner.poise > 0 then
		return
	end
	owner.poise = info.maxPoise
	if info.onBreak then
		info.onBreak(player, t, hitStop)
	end
end

-- STATS (Config.Stats): each a "Stat_<name>" player attribute, 0 until levelled at a bonfire
local function stat(pl, name)
	return pl:GetAttribute("Stat_" .. name) or 0
end

-- put one of Config.Weapons in a player's hands. The "Weapon" attribute keeps it
-- across deaths (onCharacter re-arms from it); with no character it waits for one.
-- false (and nothing changes) if they lack the weapon's Strength (armor's counts)
local function equipWeapon(pl, kind)
	local st, def = states[pl], Config.Weapons[kind]
	if not (st and def) or Config.statOf(pl, "Strength") < (def.Strength or 0) or Config.statOf(pl, "Fire") < (def.FireReq or 0) then
		return false
	end
	pl:SetAttribute("Weapon", kind)
	local char = pl.Character
	if not (char and char:FindFirstChild("HumanoidRootPart")) then
		return
	end
	st.attackId = (st.attackId or 0) + 1 -- drop any swing in progress
	local g = char:GetAttribute("Grow") or 1 -- (armor that makes you bigger: so does your weapon)
	st.scale = g ~= 1 and g or nil -- (the grips are measured from your root)
	st.weld = giveWeapon(char, kind, def.Scale * g)
	if def.Dual then
		st.weld2 = giveWeapon(char, kind, def.Scale * g, true)
	else
		st.weld2 = nil
		local old = char:FindFirstChild("Weapon2")
		if old then
			old:Destroy()
		end
	end
	st.idleGrip = def.Idle
	char:SetAttribute("TwoHand", def.TwoHand) -- read by the Puppeteer (left hand on the haft)
	pose(st, "Idle", 0.2)
	return true
end

---------------------------------------------------------------------------
-- POISON: a status anything can inflict (Oculast's breath, the township fog).
-- poisonPlayer(player, opts) with opts = { Total, DPS, TickTime?, Label?, HudPosition? }:
-- it eats away opts.Total health over time, no matter what you do; poisoning someone
-- already poisoned tops it back up (it doesn't stack). A badge with a draining bar
-- shows on their HUD (centred, low on the screen), the screen goes faintly sickly, and green wisps rise off them so
-- other players can see it too. It ends when it has done all its damage, when they die,
-- or on clearPoison(player) / clearAllPoison(). Built on the server: no client changes.
---------------------------------------------------------------------------
local POISON = {} -- [player] = { left, opts, char, gui, fill, tint, wisps, hl }
local PCOL = Color3.fromRGB(150, 178, 70)

local function poisonHud(pl, opts)
	local pg = pl:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return nil
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "Poison"
	gui.ResetOnSpawn = true
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 5
	-- a faint sick tint over the whole screen, pulsing with each tick
	local tint = Instance.new("Frame")
	tint.Name = "Tint"
	tint.Size = UDim2.fromScale(1, 1)
	tint.BackgroundColor3 = PCOL
	tint.BackgroundTransparency = 0.93
	tint.BorderSizePixel = 0
	tint.Active = false
	tint.Parent = gui
	local fill = statusBadge(gui, opts.Label or "POISONED", opts.HudPosition or UDim2.fromScale(0.5, 0.8), PCOL, Color3.fromRGB(205, 220, 150), Color3.fromRGB(36, 40, 24), Color3.fromRGB(18, 20, 12))
	gui.Parent = pg
	return gui, fill, tint
end

local function clearPoison(pl)
	local p = POISON[pl]
	if not p then
		return
	end
	POISON[pl] = nil
	for _, x in ipairs({ p.gui, p.wisps, p.hl }) do
		if x and x.Parent then
			x:Destroy()
		end
	end
end

local function clearAllPoison()
	for pl in pairs(POISON) do
		clearPoison(pl)
	end
end

local function poisonPlayer(pl, opts)
	if not opts or (opts.Total or 0) <= 0 then
		return
	end
	local char, _, hrp = aliveChar(pl)
	if not char then
		return
	end
	local cur = POISON[pl]
	if cur and cur.char == char then
		cur.left = math.max(cur.left, opts.Total) -- poisoned again: topped back up
		cur.opts = opts
		return
	end
	clearPoison(pl)
	local gui, fill, tint = poisonHud(pl, opts)
	local wisps = Instance.new("ParticleEmitter")
	wisps.Name = "PoisonWisps"
	wisps.Texture = "rbxasset://textures/particles/smoke_main.dds"
	wisps.Rate = 7
	wisps.Lifetime = NumberRange.new(0.8, 1.4)
	wisps.Speed = NumberRange.new(1, 2.5)
	wisps.SpreadAngle = Vector2.new(30, 30)
	wisps.EmissionDirection = Enum.NormalId.Top
	wisps.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1.4) })
	wisps.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
	wisps.Color = ColorSequence.new(PCOL)
	wisps.LightEmission = 0.3
	wisps.Parent = hrp
	local hl = Instance.new("Highlight")
	hl.Name = "PoisonTint"
	hl.FillColor = PCOL
	hl.FillTransparency = 0.82
	hl.OutlineTransparency = 1
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Parent = char
	POISON[pl] = { left = opts.Total, opts = opts, char = char, gui = gui, fill = fill, tint = tint, wisps = wisps, hl = hl }
	playSound(hrp, SOUNDS.Groan, 0.45, 1.7)
end

task.spawn(function()
	local pulse = false
	local STEP = 0.5
	while true do
		task.wait(STEP)
		pulse = not pulse
		for pl, p in pairs(POISON) do
			local hum = p.char and p.char:FindFirstChildOfClass("Humanoid")
			if not pl.Parent or pl.Character ~= p.char or not hum or hum.Health <= 0 then
				clearPoison(pl)
			else
				local d = math.min(p.opts.DPS * STEP, p.left)
				if states[pl] and states[pl].devGod then
					d = 0
				end
				hum.Health = math.max(0, hum.Health - d)
				p.left -= d
				if p.fill and p.fill.Parent then
					p.fill.Size = UDim2.fromScale(math.clamp(p.left / p.opts.Total, 0, 1), 1)
				end
				if p.tint and p.tint.Parent then
					p.tint.BackgroundTransparency = pulse and 0.9 or 0.94
				end
				if p.left <= 0.001 then
					clearPoison(pl)
				end
			end
		end
	end
end)

return {
	Config = Config, P = P, Map = Map, EnemiesFolder = EnemiesFolder, FxRemote = FxRemote, ActionRemote = ActionRemote, Save = Save,
	states = states, REACT = REACT, Roster = Roster, RigBuilder = RigBuilder,
	now = now, flat = flat, rand = rand, turnTowards = turnTowards,
	SOUNDS = SOUNDS, playSound = playSound,
	burst = burst, fxAnchor = fxAnchor, dustCloud = dustCloud, debrisChunks = debrisChunks, crackLines = crackLines,
	fadeAway = fadeAway, crater = crater, shockwave = shockwave, flash = flash, groundHeave = groundHeave,
	SMOKE = SMOKE, SPARK = SPARK, R = R, SIDE = SIDE,
	POSES = POSES, poseCF = poseCF, pose = pose, bodyPose = bodyPose, setTrail = setTrail, hitStopActor = hitStopActor,
	faceTowards = faceTowards, steerYaw = steerYaw, findShoulder = findShoulder,
	makeRig = makeRig, giveWeapon = giveWeapon, makeCorpse = makeCorpse, ragdoll = ragdoll, applyLimbGroup = applyLimbGroup, guardRig = guardRig,
	aliveChar = aliveChar, damagePlayer = damagePlayer, playersInSector = playersInSector, playersInRadius = playersInRadius,
	spend = spend, setAction = setAction, cancelSwing = cancelSwing, syncStamina = syncStamina, equipWeapon = equipWeapon, stat = stat, dropSplinter = dropSplinter,
	enemiesInSector = enemiesInSector, damageEnemy = damageEnemy, registerTarget = registerTarget,
	poisonPlayer = poisonPlayer, clearPoison = clearPoison, clearAllPoison = clearAllPoison, breakPlayer = breakPlayer,
}
