--!nonstrict
-- THE WARDEN'S FIGHT: everything the candidate Wardens (Characters/WardenTurnkey, WardenPlate, WardenBones, WardenBell, and the hybrids) share and
-- nothing of who they are: the states, the brain that picks moves, stagger and death, the fog and the exit door, and a kit of
-- helpers for writing moves. Characters/Warden.luau's M.spawn/start/reset/... forward here, so the rest of the game still
-- just talks to Roster.byKind.Warden. The one that stands in the arena is Config.Boss.Trial's.
--
-- A candidate calls F = Fight.init(core) in its M.init, then Fight.define({ ... }):
--   id, label, kind, scale, weapon, idleGrip, hp, poise, stagger, radius
--   walk, turn (deg/s), rest = { lo, hi } (seconds between moves), keep = { near, far } (how close it circles)
--   phase2At (0..1 of its health), tempo2 (multiplies its wind-ups in phase 2), restMult2, walk2 and keep2 (its phase 2 gait and range)
--   moves = { { name, fn(b, target), min, max, weight, cd, phase1?, phase2?, behind?, ground? } ... }
--   onSpawn(b), intro(b), phase2(b), idle(b), onStagger(b), onStaggerEnd(b), stalk(b, tr, rel), approach(b, tr), damageMult(b, player)
local Fight = { specs = {}, order = {} }

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local F = {} -- the kit
local C -- Core
local boss: any = { state = "none", gen = 0 }
local EASE, INOUT = Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
local X1, X2, Z1, Z2 = -43, 43, 217, 303 -- the arena's floor
local FLOOR_Y = 0.12

---------------------------------------------------------------------------
-- the kit: state
---------------------------------------------------------------------------
function F.live(b)
	return boss.gen == b.gen and boss.state == "fight" and b.hum.Parent ~= nil and b.hum.Health > 0
end
function F.free(b)
	return F.live(b) and C.now() >= (boss.staggerUntil or 0)
end
function F.phase2()
	return boss.phase2 == true
end
function F.tempo()
	return boss.phase2 and (boss.spec.tempo2 or 1) or 1
end
function F.gait()
	return boss.phase2 and boss.spec.walk2 or boss.spec.walk
end
-- anything a move has to put right if it's cut short (a thrown weapon, a chain out)
function F.setCleanup(fn)
	boss.cleanup = fn
end
function F.wait(b, t) -- false once the fight's over
	local t0 = C.now()
	while C.now() - t0 < t do
		if not F.live(b) then
			return false
		end
		task.wait()
	end
	return F.live(b)
end
function F.hold(b, t) -- false once it's over or it's been staggered out of the move
	local t0 = C.now()
	while C.now() - t0 < t do
		if not F.free(b) then
			return false
		end
		task.wait()
	end
	return F.free(b)
end
function F.wrap(b, fn) -- a loop of its own: fn(), every frame, while this life lasts and it returns true
	task.spawn(function()
		while boss.gen == b.gen and boss.state ~= "dead" and fn() do
			task.wait()
		end
	end)
end

---------------------------------------------------------------------------
-- the kit: moving
---------------------------------------------------------------------------
function F.clamp(p, margin)
	margin = margin or 0
	return Vector3.new(math.clamp(p.X, X1 + margin, X2 - margin), p.Y, math.clamp(p.Z, Z1 + margin, Z2 - margin))
end
function F.feet(b)
	return b.root.Position - Vector3.new(0, b.model:GetAttribute("StandHeight") or 3, 0)
end
function F.stand(b) -- root height, stood on the arena floor
	return b.model:GetAttribute("StandHeight") or 3
end
function F.fwd(b)
	local v = C.flat(b.root.CFrame.LookVector)
	return v.Magnitude > 0.01 and v.Unit or Vector3.new(0, 0, 1)
end
function F.turn(b, pos, maxRad)
	local root = b.root
	if not root.Anchored then
		C.turnTowards(root, pos, maxRad)
		return
	end
	local want = C.flat(pos - root.Position)
	if want.Magnitude < 0.1 then
		return
	end
	local look = C.flat(root.CFrame.LookVector)
	local yaw, goal = math.atan2(-look.X, -look.Z), math.atan2(-want.X, -want.Z)
	local d = (goal - yaw + math.pi) % (2 * math.pi) - math.pi
	root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, yaw + math.clamp(d, -maxRad, maxRad), 0)
end
function F.halt(b)
	if not b.root.Anchored then
		b.hum:MoveTo(b.root.Position)
	end
end
-- a burst of its own walk toward where it faces
function F.step(b, dist, dur)
	if b.root.Anchored then
		return
	end
	b.hum.WalkSpeed = dist / dur
	b.hum:MoveTo(F.clamp(b.root.Position + F.fwd(b) * dist, 4))
	task.delay(dur, function()
		if boss.gen == b.gen and b.hum.Parent and not b.root.Anchored then
			b.hum.WalkSpeed = F.gait()
			b.hum:MoveTo(b.root.Position)
		end
	end)
end
-- carried bodily along a jump, a to z (root positions), rising height at the top. each(t) every frame. Lands it again unless it
-- hovers. keepYaw: it keeps facing as it was (each can turn it). A newer arc takes over from one still running.
function F.arc(b, a, z, dur, height, each, keepYaw)
	local root = b.root
	root.Anchored = true
	local token = {}
	b.arc = token
	local dir = C.flat(z - a)
	local along = not keepYaw and dir.Magnitude > 0.1
	local t0 = C.now()
	while true do
		local t = math.min((C.now() - t0) / dur, 1)
		local p = a:Lerp(z, t) + Vector3.new(0, 4 * height * t * (1 - t), 0)
		root.CFrame = along and CFrame.lookAt(p, p + dir) or (CFrame.new(p) * root.CFrame.Rotation)
		if each then
			each(t)
		end
		if t >= 1 or boss.gen ~= b.gen or boss.state == "dead" or b.arc ~= token then
			break
		end
		RunService.Heartbeat:Wait()
	end
	if b.arc ~= token then
		return false
	end
	b.arc = nil
	if boss.gen ~= b.gen then
		return false
	end
	root.AssemblyLinearVelocity = Vector3.zero
	if boss.state == "fight" then
		root.Anchored = false
		pcall(function()
			root:SetNetworkOwner(nil)
			b.hum:ChangeState(Enum.HumanoidStateType.Running)
		end)
	end
	return boss.state ~= "dead"
end

---------------------------------------------------------------------------
-- the kit: posing
---------------------------------------------------------------------------
function F.draw(b, grip, body, t)
	boss.idleTok = nil -- (a move has begun: a pending return to stance mustn't land on top of it)
	if grip and b.weld then
		C.pose(b, grip, t, EASE, INOUT)
	end
	if body then
		C.bodyPose(b, body, t)
	end
end
-- wind up, turning toward the target for the first frac of it (then it's committed). false if interrupted
function F.track(b, target, dur, frac, rate)
	local t0 = C.now()
	rate = math.rad(rate or (boss.spec.turn * 1.5))
	while C.now() - t0 < dur do
		if not F.free(b) then
			return false
		end
		local tr = target and target:FindFirstChild("HumanoidRootPart")
		local dt = task.wait()
		if tr and C.now() - t0 < dur * frac then
			F.turn(b, tr.Position, rate * dt)
		end
	end
	return F.free(b)
end
-- a wind-up in beats: { grip, body, seconds, onStart? } each, tracking for the first `track` seconds in all
function F.beats(b, target, list, track)
	local m = F.tempo()
	track = (track or 0) * m
	for _, bt in ipairs(list) do
		local t = bt[3] * m
		F.draw(b, bt[1], bt[2], t)
		if bt[4] then
			bt[4]()
		end
		if not F.track(b, target, t, math.clamp(track / t, 0, 1)) then
			return false
		end
		track -= t
	end
	return true
end
function F.idle(b)
	C.setTrail(b, false)
	if boss.spec.idle then
		boss.spec.idle(b)
	else
		if b.weld then
			C.pose(b, "Idle", 0.5, EASE, INOUT)
		end
		C.bodyPose(b, "Idle", 0.5)
	end
end
function F.recover(b, t, body)
	C.setTrail(b, false)
	if body ~= false then
		C.bodyPose(b, body or "Recover", 0.3)
	end
	if F.hold(b, t * F.tempo()) then
		F.idle(b)
		return true
	end
	return false
end
function F.hideWeapon(b, hidden)
	local w = b.model:FindFirstChild("Weapon")
	if w then
		for _, p in ipairs(w:GetDescendants()) do
			if p:IsA("BasePart") then
				if hidden then
					p:SetAttribute("Was", p:GetAttribute("Was") or p.Transparency)
					p.Transparency = 1
				else
					p.Transparency = p:GetAttribute("Was") or 0
				end
			end
		end
	end
end
-- a loose copy of the weapon in the world (the handle's what to move: everything's welded to it)
function F.cloneWeapon(b)
	local w = b.model:FindFirstChild("Weapon")
	if not w then
		return nil
	end
	local copy = w:Clone()
	local grip = copy:FindFirstChild("GripWeld", true)
	local handle = grip and grip.Part1
	if not handle then
		copy:Destroy()
		return nil
	end
	grip:Destroy()
	for _, p in ipairs(copy:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = p == handle
		elseif p:IsA("Trail") then
			p.Enabled = true
		end
	end
	copy.Parent = boss.fx
	return copy, handle
end

---------------------------------------------------------------------------
-- the kit: hurting
---------------------------------------------------------------------------
function F.dmg(x)
	return math.max(1, math.floor(x * (Config.Boss.DamageScale or 1) + 0.5))
end
function F.hit(list, seen, damage, from, level, push)
	for _, pl in ipairs(list) do
		if not seen[pl] and C.damagePlayer(pl, F.dmg(damage), from, level, push) then
			seen[pl] = true
		end
	end
end
function F.radius(pos, r, height)
	return C.playersInRadius(pos, r, height or 12)
end
function F.ends(b)
	local handle = b.weld and b.weld.Parent and b.weld.Part1
	if not handle or not handle.Parent then
		return nil
	end
	local base, tip = handle:FindFirstChild("BladeBase"), handle:FindFirstChild("BladeTip")
	if base and tip then
		return base.WorldPosition, tip.WorldPosition
	end
	return nil
end
local function toSegment(p, a, z)
	local ab = z - a
	local t = ab:Dot(ab) > 1e-4 and math.clamp((p - a):Dot(ab) / ab:Dot(ab), 0, 1) or 0
	return (a + ab * t - p).Magnitude
end
-- the weapon's real path hurts: sampled every frame, between frames too. Judged from above, as long as it's down at your level:
-- on these giants a blow that visibly reaches you would otherwise pass over a head a quarter of their height
function F.sweep(b, dur, damage, level, seen, radius)
	local t0, pb, pt = C.now(), nil, nil
	while C.now() - t0 < dur and F.live(b) do
		local base, tip = F.ends(b)
		if base then
			pb, pt = pb or base, pt or tip
			for _, pl in ipairs(Players:GetPlayers()) do
				local char, _, hrp = C.aliveChar(pl)
				if char and not seen[pl] then
					local at = Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
					for i = 0, 4 do
						local x, y = pb:Lerp(base, i / 4), pt:Lerp(tip, i / 4)
						if math.min(x.Y, y.Y) < hrp.Position.Y + 9 and toSegment(at, C.flat(x), C.flat(y)) <= radius + 2 then
							F.hit({ pl }, seen, damage, b.root.Position, level)
							break
						end
					end
				end
			end
			pb, pt = base, tip
		end
		RunService.Heartbeat:Wait()
	end
end
function F.toSegment(p, a, z)
	return toSegment(p, a, z)
end

---------------------------------------------------------------------------
-- the kit: things in the world (all in one folder per life, gone when it's reset)
---------------------------------------------------------------------------
function F.part(props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = boss.fx
	return p
end
local function fade(p, t, goal)
	TweenService:Create(p, TweenInfo.new(t, EASE, Enum.EasingDirection.Out), goal or { Transparency = 1 }):Play()
	task.delay(t + 0.05, function()
		if p.Parent then
			p:Destroy()
		end
	end)
end
F.fade = fade
-- the floor gives something away before it lands here: hairline cracks spreading, grit hopping, a rumble
function F.ring(pos, radius, lead)
	C.groundHeave(Vector3.new(pos.X, FLOOR_Y, pos.Z), radius, lead)
end
-- the same, along a line: something's coming along it
function F.strip(a, z, width, lead)
	local n = math.clamp(math.ceil((z - a).Magnitude / width), 1, 5)
	for i = 0, n do
		F.ring(a:Lerp(z, i / n), width / 2, lead)
	end
end
-- a blow travelling through the floor: a low heave of stone rolling out from center, dust thrown off its crest. You can't outrun
-- it, you roll through it as it reaches you
function F.wave(b, center, speed, maxR, damage, level)
	task.spawn(function()
		local N, segs, seen = 44, {}, {}
		for i = 1, N do
			segs[i] = F.part({ Name = "Wave", Size = Vector3.new(1, 1, 1), Material = Enum.Material.Slate, Color = Color3.fromRGB(82, 78, 72):Lerp(Color3.fromRGB(44, 42, 38), math.random()) })
		end
		local t0, dust = C.now(), 0
		while F.live(b) do
			local r = (C.now() - t0) * speed
			if r > maxR then
				break
			end
			local width = 2 * math.pi * math.max(r, 1) / N * 1.15
			local rise = 2 - r / maxR
			for i, s in ipairs(segs) do
				local a = i / N * 2 * math.pi
				local h = rise * (0.75 + 0.25 * math.sin(i * 2.4))
				local p = Vector3.new(center.X + math.cos(a) * r, FLOOR_Y + h * 0.3, center.Z + math.sin(a) * r)
				s.Transparency = F.clamp(p) == p and 0 or 1 -- (it dies at the walls)
				s.Size = Vector3.new(width, h, 1.7)
				s.CFrame = CFrame.lookAt(p, Vector3.new(center.X, p.Y, center.Z)) * CFrame.Angles(0.4, 0, 0)
			end
			if C.now() > dust then
				dust = C.now() + 0.14
				for _ = 1, 4 do
					local a = math.random() * 2 * math.pi
					local p = Vector3.new(center.X + math.cos(a) * r, FLOOR_Y, center.Z + math.sin(a) * r)
					if F.clamp(p) == p then
						C.dustCloud(p, 1.6, 3)
					end
				end
			end
			for _, pl in ipairs(Players:GetPlayers()) do
				local char, _, hrp = C.aliveChar(pl)
				if char and not seen[pl] and math.abs(C.flat(hrp.Position - center).Magnitude - r) < 2.2 and hrp.Position.Y < 9 then
					F.hit({ pl }, seen, damage, center, level)
				end
			end
			task.wait()
		end
		for _, s in ipairs(segs) do
			s:Destroy()
		end
	end)
end
-- all of it gone (the weapon too) or back
function F.hideBody(b, hidden)
	for _, p in ipairs(b.model:GetDescendants()) do
		if p:IsA("BasePart") and p ~= b.root then
			if hidden then
				p:SetAttribute("Was", p:GetAttribute("Was") or p.Transparency)
				p.Transparency = 1
			else
				p.Transparency = p:GetAttribute("Was") or 0
				p:SetAttribute("Was", nil)
			end
		end
	end
end
-- a part thrown in an arc, a to z; onLand(z) when it's down (if the fight's still on)
function F.lob(b, part, a, z, dur, height, onLand)
	task.spawn(function()
		local t0 = C.now()
		while part.Parent and boss.gen == b.gen do
			local t = math.min((C.now() - t0) / dur, 1)
			part.CFrame = CFrame.new(a:Lerp(z, t) + Vector3.new(0, 4 * height * t * (1 - t), 0)) * CFrame.Angles(t * 7, t * 5, 0)
			if t >= 1 then
				break
			end
			RunService.Heartbeat:Wait()
		end
		if part.Parent then
			part:Destroy()
		end
		if boss.gen == b.gen and F.live(b) then
			onLand(z)
		end
	end)
end
function F.quake(b, pos, r, shake)
	C.shockwave(Vector3.new(pos.X, FLOOR_Y, pos.Z), r)
	C.playSound(b.root, C.SOUNDS.Impact, 1, 0.55)
	C.FxRemote:FireAllClients("Shake", pos, shake or 1)
end

---------------------------------------------------------------------------
-- the brain
---------------------------------------------------------------------------
local function nearest(b)
	local best, bestD, bestPl
	for _, pl in ipairs(Players:GetPlayers()) do
		local char, _, hrp = C.aliveChar(pl)
		if char and hrp.Position.Z > 214 then
			local d = C.flat(hrp.Position - b.root.Position).Magnitude
			if not bestD or d < bestD then
				best, bestD, bestPl = char, d, pl
			end
		end
	end
	return best, bestPl
end
F.nearest = nearest

local function pick(dist, behind, healing)
	local list, total = {}, 0
	local t = C.now()
	for _, mv in ipairs(boss.spec.moves) do
		local allowed = (not mv.phase2 or boss.phase2) and not (mv.phase1 and boss.phase2)
		if allowed and dist >= mv.min and dist <= mv.max and t >= (boss.cd[mv.name] or 0) then
			local w = mv.weight
			if behind then
				w *= mv.behind and 4 or 0.3
			end
			if healing and mv.fast then
				w *= 3
			end
			if mv.name == boss.lastMove then
				w *= 0.2
			end
			total += w
			table.insert(list, { mv, w })
		end
	end
	if total <= 0 then
		return nil
	end
	local r = math.random() * total
	for _, e in ipairs(list) do
		r -= e[2]
		if r <= 0 then
			return e[1]
		end
	end
	return list[#list][1]
end

local function brain(b)
	local spec = boss.spec
	boss.cd, boss.stalkUntil, boss.stalkSide, boss.faceAt = {}, 0, 1, nil
	local turner = RunService.Heartbeat:Connect(function(dt)
		local tr = boss.faceAt
		if tr and tr.Parent and F.free(b) then
			F.turn(b, tr.Position, math.rad(spec.turn) * dt)
		end
	end)
	while F.live(b) do
		task.wait(0.1)
		if not F.live(b) then
			break
		end
		if C.now() < (boss.staggerUntil or 0) then
			continue
		end
		b.hum.AutoRotate = false
		local target, pl = nearest(b)
		if not target then
			F.halt(b)
			continue
		end
		if spec.phase2At and not boss.phase2 and b.hum.Health <= b.hum.MaxHealth * spec.phase2At then
			boss.phase2 = true
			boss.faceAt = nil
			ReplicatedStorage:SetAttribute("Music", "boss2")
			local ok, err = pcall(spec.phase2, b)
			if not ok then
				warn("[DGUS] Warden phase 2 error: " .. tostring(err))
			end
			boss.stalkUntil = C.now() + 0.4
			continue
		end
		local tr = target:FindFirstChild("HumanoidRootPart")
		if not tr then
			continue
		end
		local rel = C.flat(tr.Position - b.root.Position)
		local dist = rel.Magnitude
		local behind = dist > 0.1 and F.fwd(b):Dot(rel.Unit) < -0.15
		local st = C.states[pl]
		local healing = st and st.healing
		local band = boss.phase2 and spec.keep2 or spec.keep
		if C.now() < boss.stalkUntil and not healing then
			boss.faceAt = tr
			if spec.stalk then
				spec.stalk(b, tr, rel)
			elseif dist > 0.1 then
				local keep = math.clamp(dist, band[1], band[2])
				b.hum.WalkSpeed = F.gait() * 0.7
				b.hum:MoveTo(tr.Position + CFrame.Angles(0, boss.stalkSide * 0.55, 0):VectorToWorldSpace(-rel.Unit) * keep)
			end
			continue
		end
		local mv = pick(dist, behind, healing)
		if mv then
			boss.faceAt = nil
			b.hum.WalkSpeed = F.gait()
			boss.lastMove = mv.name
			boss.cd[mv.name] = C.now() + mv.cd
			if Config.Debug then
				print("[Warden] " .. spec.id .. ": " .. mv.name)
			end
			local ok, err = pcall(mv.fn, b, target)
			if not ok then
				warn("[DGUS] Warden move " .. mv.name .. " error: " .. tostring(err))
			end
			if boss.cleanup then
				boss.cleanup()
				boss.cleanup = nil
			end
			if boss.gen == b.gen and b.root.Anchored and boss.state == "fight" then
				b.root.Anchored = false
			end
			boss.stalkSide = math.random() < 0.5 and -1 or 1
			local rest = spec.rest[1] + math.random() * (spec.rest[2] - spec.rest[1])
			boss.stalkUntil = C.now() + rest * (boss.phase2 and (spec.restMult2 or 0.7) or 1)
		else
			boss.faceAt = tr
			if spec.approach then
				spec.approach(b, tr, dist)
			elseif dist < band[1] * 0.6 then
				b.hum.WalkSpeed = F.gait() * 0.8
				b.hum:MoveTo(b.root.Position - rel.Unit * band[1])
			else
				b.hum.WalkSpeed = F.gait()
				b.hum:MoveTo(tr.Position)
			end
		end
	end
	boss.faceAt = nil
	turner:Disconnect()
end

---------------------------------------------------------------------------
-- life and death, and the door
---------------------------------------------------------------------------
local doorHome
local function openWay()
	TweenService:Create(C.Map.Fog, TweenInfo.new(2), { Transparency = 1 }):Play()
	C.Map.Fog.CanCollide = false
	C.Map.FogPrompt.Enabled = false
	local pe = C.Map.Fog:FindFirstChildOfClass("ParticleEmitter")
	if pe then
		pe.Enabled = false
	end
	doorHome = doorHome or C.Map.ExitDoor.CFrame
	TweenService:Create(C.Map.ExitDoor, TweenInfo.new(4, EASE), { CFrame = doorHome + Vector3.new(0, 15.5, 0) }):Play()
	local glow = C.Map.ExitLight:FindFirstChildOfClass("PointLight")
	if glow then
		glow.Enabled = true
	end
	local gen = boss.gen
	task.delay(3.5, function() -- the veil of light behind the door thins away: the Ruined Township lies beyond
		if boss.gen == gen then
			TweenService:Create(C.Map.ExitLight, TweenInfo.new(2.5), { Transparency = 1 }):Play()
			C.Map.ExitLight.CanCollide = false
			C.Map.ExitLight.CanQuery = false
		end
	end)
end
local function onDied(b)
	if boss.gen ~= b.gen or boss.state == "dead" then
		return
	end
	boss.state = "dead"
	C.Save.mark("Warden")
	if boss.cleanup then
		boss.cleanup()
		boss.cleanup = nil
	end
	ReplicatedStorage:SetAttribute("BossActive", false)
	ReplicatedStorage:SetAttribute("Music", "victory")
	C.FxRemote:FireAllClients("Banner", "WARDEN FELLED", "Victory")
	C.dropSplinter(b.root.Position, b.model)
	C.playSound(b.root, C.SOUNDS.Groan, 1, 0.22)
	for _, d in ipairs(b.model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	task.spawn(function()
		if boss.spec.onDied then
			boss.spec.onDied(b)
		end
		for _ = 1, 6 do
			if b.root.Parent then
				C.burst(b.root.Position + Vector3.new(math.random(-4, 4), math.random(-4, 6), math.random(-4, 4)), Color3.fromRGB(70, 66, 60), 40, 1, 10)
			end
			task.wait(0.35)
		end
		for _, d in ipairs(b.model:GetDescendants()) do
			if d:IsA("BasePart") then
				TweenService:Create(d, TweenInfo.new(2), { Transparency = 1 }):Play()
			end
		end
		task.wait(2.2)
		b.model:Destroy()
	end)
	openWay()
end

local function clearLife()
	boss.gen += 1
	boss.cleanup = nil
	if boss.fx then
		boss.fx:Destroy()
	end
	boss.fx = Instance.new("Folder")
	boss.fx.Name = "WardenFx"
	boss.fx.Parent = workspace
	if boss.model then
		boss.model:Destroy()
		boss.model = nil
	end
end

local function spawnBoss()
	clearLife()
	local spec = Fight.specs[boss.id]
	boss.spec = spec
	local model, hum, weld = C.makeRig("Warden", spec.kind, spec.scale, spec.weapon)
	if not model then
		return
	end
	hum.MaxHealth, hum.Health = spec.hp, spec.hp
	hum.WalkSpeed = spec.walk
	hum.BreakJointsOnDeath = false
	hum.AutoRotate = false
	model:SetAttribute("Radius", spec.radius)
	model:SetAttribute("Boss", true)
	local root = model:FindFirstChild("HumanoidRootPart")
	model:PivotTo(C.Map.BossHome + Vector3.new(0, 3 * spec.scale - 3, 0))
	root.Anchored = true -- (pinned at its exact height until its entrance lets it go)
	root.AssemblyLinearVelocity = Vector3.zero
	root.CollisionGroup = "EnemyRoot"
	pcall(function()
		root:SetNetworkOwner(nil)
		hum:ChangeState(Enum.HumanoidStateType.Running)
	end)
	boss.model = model
	boss.phase2, boss.poise, boss.staggerUntil, boss.lastMove = false, nil, 0, nil
	boss.state = "dormant"
	local b = { model = model, hum = hum, root = root, weld = weld, scale = spec.scale, gen = boss.gen, idleGrip = spec.idleGrip }
	boss.current = b
	if weld and spec.idleGrip then
		weld.C0 = C.poseCF(spec.idleGrip, spec.scale)
	end
	ReplicatedStorage:SetAttribute("BossMaxHP", spec.hp)
	ReplicatedStorage:SetAttribute("BossHP", spec.hp)
	hum.HealthChanged:Connect(function(h)
		if boss.gen == b.gen then
			ReplicatedStorage:SetAttribute("BossHP", math.max(0, h))
		end
	end)
	hum.Died:Connect(function()
		onDied(b)
	end)
	if spec.onSpawn then
		spec.onSpawn(b)
	end
end

function Fight.start()
	if boss.state ~= "dormant" then
		return
	end
	boss.state = "intro"
	local b = boss.current
	ReplicatedStorage:SetAttribute("BossName", Config.Boss.Name)
	ReplicatedStorage:SetAttribute("BossMaxHP", b.hum.MaxHealth)
	ReplicatedStorage:SetAttribute("BossHP", b.hum.Health)
	ReplicatedStorage:SetAttribute("BossActive", true)
	ReplicatedStorage:SetAttribute("Music", "boss")
	task.spawn(function()
		local ok, err = pcall(boss.spec.intro, b)
		if not ok then
			warn("[DGUS] Warden intro error: " .. tostring(err))
		end
		if boss.gen ~= b.gen or boss.state ~= "intro" then
			return
		end
		boss.state = "fight"
		b.root.Anchored = false
		pcall(function()
			b.root:SetNetworkOwner(nil)
			b.hum:ChangeState(Enum.HumanoidStateType.Running)
		end)
		F.idle(b)
		task.wait(0.6)
		brain(b)
	end)
end
function Fight.spawn()
	boss.id = boss.id or Fight.specs[Config.Boss.Trial] and Config.Boss.Trial or Fight.order[1]
	if C.Save.done("Warden") then -- (felled in this save: gone, the way on open)
		boss.state = "dead"
		openWay()
		return
	end
	spawnBoss()
end
function Fight.reset()
	if boss.state == "dead" or boss.state == "dormant" then
		return
	end
	ReplicatedStorage:SetAttribute("BossActive", false)
	ReplicatedStorage:SetAttribute("Music", "none")
	spawnBoss()
end
function Fight.state()
	return boss.state
end
function Fight.isDead()
	return boss.state == "dead"
end
function Fight.model()
	return boss.model
end
function Fight.anyoneInArena()
	for _, pl in ipairs(Players:GetPlayers()) do
		local char, _, hrp = C.aliveChar(pl)
		if char and hrp.Position.Z > 214 then
			return true
		end
	end
	return false
end
function Fight.define(spec)
	if not Fight.specs[spec.id] then
		table.insert(Fight.order, spec.id)
	end
	Fight.specs[spec.id] = spec
end

function Fight.init(core)
	if C then
		return F
	end
	C = core
	for _, name in ipairs({ "now", "flat", "SOUNDS", "playSound", "burst", "dustCloud", "shockwave", "debrisChunks", "crackLines", "fadeAway", "pose", "bodyPose", "setTrail", "aliveChar", "states", "FxRemote", "Map" }) do
		F[name] = core[name]
	end
	core.registerTarget(function(model)
		if not boss.model or boss.model ~= model then
			return nil
		end
		return {
			owner = boss,
			actor = boss.current,
			maxPoise = boss.spec.poise,
			freeze = false,
			damageMult = boss.spec.damageMult and function(player)
				return boss.spec.damageMult(boss.current, player)
			end or nil,
			onBreak = function()
				if boss.state ~= "fight" then
					return
				end
				local b, t = boss.current, C.now()
				local dur = boss.spec.stagger
				boss.staggerUntil = t + dur
				if Config.Debug then
					print("[Warden] " .. boss.spec.id .. ": staggered")
				end
				boss.idleTok = nil
				C.setTrail(b, false)
				F.halt(b)
				C.playSound(b.root, C.SOUNDS.Groan, 0.9, 0.5)
				C.FxRemote:FireAllClients("Shake", b.root.Position, 0.5)
				if boss.spec.onStagger then
					boss.spec.onStagger(b, dur)
				else
					if b.weld then
						C.pose(b, "Flinch", 0.15)
					end
					C.bodyPose(b, "Stagger", 0.12)
				end
				local gen = boss.gen
				task.delay(dur, function()
					if boss.gen == gen and boss.state == "fight" then
						if boss.spec.onStaggerEnd then
							boss.spec.onStaggerEnd(b)
						end
						F.idle(b)
					end
				end)
			end,
		}
	end)
	return F
end

return Fight
