--!nonstrict
-- MIMIC: a chest that isn't. It waits in the far corner of the Prison Ramparts' yard walk
-- looking like any other chest (same prompt, same planks). Open it and it bites; then it
-- fights - hopping after you, snapping its lid, leaping on you from range.
--
-- Not a rig: a chest model (body + a lid hinged on a weld) around an anchored root, with
-- a Humanoid for health so blades and lock-on treat it like any enemy once it's awake.
-- While it's pretending it lives outside the EnemiesFolder, so nothing can target it.
-- Killed, it stays dead. If it loses you, it goes back to its corner, shuts, heals, waits.
-- Numbers: Config.Mimic. Where it sits and how far it may hop: Map.Mimic (MapBuilder).
local Mimic = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local W, H, DP = 4, 2, 2.6 -- the same box as the Usher's chest

function Mimic.init(core)
	local Config, where = core.Config, core.Map.Mimic -- { CFrame = its corner, Min/Max = how far it may hop }
	if not where then
		return
	end
	local spot = where.CFrame
	local CFG = Config.Mimic
	local now, flat, playSound, SOUNDS = core.now, core.flat, core.playSound, core.SOUNDS
	local burst, dustCloud, damagePlayer = core.burst, core.dustCloud, core.damagePlayer
	local playersInSector, playersInRadius, aliveChar = core.playersInSector, core.playersInRadius, core.aliveChar

	---------------------------------------------------------------------------
	-- the chest
	---------------------------------------------------------------------------
	local model = Instance.new("Model")
	model.Name = "Mimic"
	local rng = Random.new(7)
	local rust = Color3.fromRGB(78, 52, 36)
	local function plankColor()
		return Color3.fromRGB(72, 52, 36):Lerp(Color3.fromRGB(58, 56, 50), rng:NextNumber(0.2, 0.75))
	end
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(W, H, DP)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = true
	root.Parent = model
	model.PrimaryPart = root

	local function piece(name, size, cf, color, mat, attachTo)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = color or plankColor()
		p.Material = mat or Enum.Material.WoodPlanks
		p.CanCollide = false
		p.Massless = true
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = model
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = attachTo, p
		w.Parent = p
		return p
	end
	-- everything is built at the spot, then welded; the root's CFrame moves the lot
	root.CFrame = spot * CFrame.new(0, H / 2, 0)
	local base = spot
	-- body: four plank walls, a dark inside, straps, corner caps, lock plate
	piece("Inside", Vector3.new(W - 0.4, H - 0.3, DP - 0.4), base * CFrame.new(0, H / 2 - 0.1, 0), Color3.fromRGB(28, 18, 16), Enum.Material.SmoothPlastic, root)
	for _, s in ipairs({ { 0, -(DP - 0.22) / 2, W, 0.22 }, { 0, (DP - 0.22) / 2, W, 0.22 }, { -(W - 0.22) / 2, 0, 0.22, DP - 0.44 }, { (W - 0.22) / 2, 0, 0.22, DP - 0.44 } }) do
		for k = 0, 1 do
			piece("ChestPlank", Vector3.new(s[3], H / 2 - 0.05, s[4]), base * CFrame.new(s[1], H / 4 + k * H / 2, s[2]), nil, nil, root)
		end
	end
	for _, bx in ipairs({ -1.3, 1.3 }) do
		for _, sz in ipairs({ -1, 1 }) do
			piece("ChestStrap", Vector3.new(0.3, H + 0.04, 0.06), base * CFrame.new(bx, H / 2, sz * (DP / 2 + 0.03)), rust, Enum.Material.CorrodedMetal, root)
		end
	end
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			piece("ChestCorner", Vector3.new(0.3, H + 0.04, 0.3), base * CFrame.new(sx * (W / 2 - 0.1), H / 2, sz * (DP / 2 - 0.1)), Color3.fromRGB(46, 42, 38), Enum.Material.CorrodedMetal, root)
		end
	end
	piece("ChestLock", Vector3.new(0.55, 0.6, 0.08), base * CFrame.new(0, H - 0.35, -(DP / 2 + 0.05)), rust, Enum.Material.CorrodedMetal, root)
	-- the lid hangs off a hinge at the back top edge; its weld's C0 opens it
	local hinge = Instance.new("Part")
	hinge.Name = "Hinge"
	hinge.Size = Vector3.new(0.2, 0.2, 0.2)
	hinge.Transparency = 1
	hinge.CanCollide, hinge.CanQuery, hinge.Massless = false, false, true
	hinge.CFrame = base * CFrame.new(0, H, DP / 2)
	hinge.Parent = model
	local lidWeld = Instance.new("Weld")
	lidWeld.Part0, lidWeld.Part1 = root, hinge
	lidWeld.C0 = CFrame.new(0, H / 2, DP / 2)
	lidWeld.Parent = hinge
	local LD = DP + 0.1
	for k = 0, 2 do
		piece("LidPlank", Vector3.new(W + 0.1, 0.18, LD / 3 - 0.04), base * CFrame.new(0, H + 0.33, -LD / 2 + LD / 3 * (k + 0.5)), nil, nil, hinge)
	end
	piece("LidRim", Vector3.new(W + 0.1, 0.24, 0.22), base * CFrame.new(0, H + 0.12, -(LD - 0.22) / 2), nil, nil, hinge)
	for _, bx in ipairs({ -1.3, 1.3 }) do
		piece("LidStrap", Vector3.new(0.3, 0.05, LD + 0.04), base * CFrame.new(bx, H + 0.44, 0), rust, Enum.Material.CorrodedMetal, hinge)
	end
	piece("LidHasp", Vector3.new(0.4, 0.5, 0.06), base * CFrame.new(0, H + 0.05, -(LD / 2 + 0.04)), rust, Enum.Material.CorrodedMetal, hinge)
	-- what's inside: teeth along both front edges, a tongue, a glint deep in the dark
	local hidden = {}
	local function mouth(p)
		p.Transparency = 1
		table.insert(hidden, p)
		return p
	end
	for i = -4, 4 do
		local x = i * 0.42
		mouth(piece("Tooth", Vector3.new(0.18, 0.45, 0.18), base * CFrame.new(x, H + 0.05, -DP / 2 + 0.32) * CFrame.Angles(0, 0, rng:NextNumber(-0.2, 0.2)), Color3.fromRGB(214, 204, 176), Enum.Material.SmoothPlastic, root))
		mouth(piece("Tooth", Vector3.new(0.18, 0.4, 0.18), base * CFrame.new(x + 0.2, H + 0.05, -LD / 2 + 0.34) * CFrame.Angles(0, 0, rng:NextNumber(-0.2, 0.2)), Color3.fromRGB(214, 204, 176), Enum.Material.SmoothPlastic, hinge))
	end
	mouth(piece("Tongue", Vector3.new(1.0, 0.25, DP * 0.9), base * CFrame.new(0.2, H - 0.2, -0.3) * CFrame.Angles(0.25, 0.15, 0), Color3.fromRGB(120, 30, 34), Enum.Material.SmoothPlastic, root))
	for _, x in ipairs({ -0.5, 0.5 }) do
		mouth(piece("Eye", Vector3.new(0.22, 0.22, 0.22), base * CFrame.new(x, H - 0.55, 0.4), Color3.fromRGB(255, 200, 90), Enum.Material.Neon, root))
	end

	local hum = Instance.new("Humanoid")
	hum.RequiresNeck = false -- no head on a chest
	hum.BreakJointsOnDeath = false
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.MaxHealth, hum.Health = CFG.HP, CFG.HP
	hum.Parent = model
	model:SetAttribute("Radius", 2)
	model.Parent = workspace

	local promptAt = Instance.new("Attachment")
	promptAt.Position = Vector3.new(0, 0, -0.5)
	promptAt.Parent = root
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText, pp.ObjectText = "Open", "Chest" -- (just like the real one)
	pp.HoldDuration, pp.MaxActivationDistance, pp.RequiresLineOfSight = 0.5, 7, false
	pp.Parent = promptAt

	---------------------------------------------------------------------------
	-- state + small helpers
	---------------------------------------------------------------------------
	local M = { awake = false, alive = true, poise = nil, staggerUntil = 0, gen = 0 }
	local actor = { root = root } -- (for hit-stop: there's no tween to pause, and its root stays anchored)

	local function setLid(angle, t, style)
		TweenService:Create(lidWeld, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { C0 = CFrame.new(0, H / 2, DP / 2) * CFrame.Angles(angle, 0, 0) }):Play()
	end
	local function showMouth(on)
		for _, p in ipairs(hidden) do
			p.Transparency = on and 0 or 1
		end
	end
	local function free()
		return M.alive and M.awake and now() >= M.staggerUntil
	end
	local function hold(d) -- false if it was staggered, killed or put to sleep meanwhile
		local g, t0 = M.gen, now()
		while now() - t0 < d do
			if not free() or M.gen ~= g then
				return false
			end
			task.wait()
		end
		return true
	end
	local function ground(p) -- keep it on the walk
		return Vector3.new(math.clamp(p.X, where.Min.X, where.Max.X), root.Position.Y, math.clamp(p.Z, where.Min.Z, where.Max.Z))
	end
	local function face(pos)
		local d = flat(pos - root.Position)
		if d.Magnitude > 0.1 then
			root.CFrame = CFrame.lookAt(root.Position, root.Position + d)
		end
	end
	local function target()
		local best, bestD
		for _, pl in ipairs(Players:GetPlayers()) do
			local char, _, hrp = aliveChar(pl)
			if char then
				local d = (hrp.Position - root.Position).Magnitude
				if d < CFG.Aggro and (not bestD or d < bestD) then
					best, bestD = hrp, d
				end
			end
		end
		return best, bestD
	end
	-- an arcing hop from where it is to `to` (clamped onto the walk)
	local function hop(to, dur, height)
		local a, b = root.Position, ground(to)
		local rot = root.CFrame.Rotation
		local t0 = now()
		while true do
			local k = math.min((now() - t0) / dur, 1)
			root.CFrame = CFrame.new(a:Lerp(b, k) + Vector3.new(0, math.sin(k * math.pi) * height, 0)) * rot
			if k >= 1 or not M.alive then
				break
			end
			RunService.Heartbeat:Wait()
		end
		dustCloud(Vector3.new(root.Position.X, root.Position.Y - H / 2 + 0.3, root.Position.Z), 0.8, 4)
	end

	---------------------------------------------------------------------------
	-- its moves
	---------------------------------------------------------------------------
	-- CHOMP: gapes wide (slowly - the tell), then lunges a few studs and snaps shut
	local function chomp(tr)
		face(tr.Position)
		setLid(1.7, 0.45)
		playSound(root, SOUNDS.Unsheath, 0.5, 0.5)
		if not hold(0.5) then
			return
		end
		local fwd = flat(root.CFrame.LookVector)
		setLid(0.05, 0.08, Enum.EasingStyle.Linear)
		playSound(root, SOUNDS.Impact, 0.9, 0.7)
		hop(root.Position + fwd * 3, 0.14, 0.4)
		for _, pl in ipairs(playersInSector(root.CFrame, 4.5, 55, 5)) do
			damagePlayer(pl, CFG.ChompDamage, root.Position, "Large")
		end
		setLid(0.5, 0.3) -- left hanging open: the punish window
		hold(0.8)
	end

	-- POUNCE: from range, crouches (rattling), leaps high onto you and slams down
	local function pounce(tr)
		face(tr.Position)
		setLid(0.3, 0.2)
		playSound(root, SOUNDS.Unsheath, 0.45, 0.35)
		root.CFrame *= CFrame.new(0, -0.25, 0) -- squats
		if not hold(0.55) then
			return
		end
		root.CFrame *= CFrame.new(0, 0.25, 0)
		local land = tr.Position
		setLid(1.2, 0.15)
		hop(land, 0.5, 6)
		setLid(0.05, 0.06, Enum.EasingStyle.Linear)
		playSound(root, SOUNDS.Impact, 1, 0.5)
		core.FxRemote:FireAllClients("Shake", root.Position, 0.5)
		for _, pl in ipairs(playersInRadius(root.Position, 4.5, 6)) do
			damagePlayer(pl, CFG.PounceDamage, root.Position, "Knockdown")
		end
		hold(0.9)
	end

	---------------------------------------------------------------------------
	-- waking, sleeping, the fight
	---------------------------------------------------------------------------
	local function sleep()
		-- lost you: back to its corner, shut, healed, pretending again
		M.awake = false
		M.gen += 1
		model.Parent = workspace
		hop(spot.Position, 0.6, 1.5)
		root.CFrame = spot * CFrame.new(0, H / 2, 0)
		setLid(0, 0.3)
		showMouth(false)
		hum.Health = hum.MaxHealth
		M.poise = nil
		pp.Enabled = true
	end

	local function brain()
		local g = M.gen
		local lostSince
		while M.alive and M.awake and M.gen == g do
			if now() < M.staggerUntil then
				task.wait(0.1)
				continue
			end
			local tr, d = target()
			if not tr then
				lostSince = lostSince or now()
				if now() - lostSince > 6 then
					sleep()
					return
				end
				task.wait(0.2)
				continue
			end
			lostSince = nil
			if d <= 5 then
				chomp(tr)
			elseif d <= 13 and math.random() < 0.45 then
				pounce(tr)
			else
				-- hops after you, a few studs at a time, snapping
				face(tr.Position)
				setLid(0.4, 0.1)
				local step = flat(tr.Position - root.Position)
				hop(root.Position + step.Unit * math.min(step.Magnitude - 3, CFG.HopLength), 0.32, 1.6)
				setLid(0, 0.1)
				playSound(root, SOUNDS.Impact, 0.4, 1.3)
				hold(0.25)
			end
			task.wait()
		end
	end

	-- the opener's body pose (the client's animator reads these, as for every rig)
	local function playerPose(char, name, blend)
		char:SetAttribute("BP", name)
		char:SetAttribute("BPT", blend)
		char:SetAttribute("BPN", (char:GetAttribute("BPN") or 0) + 1)
	end

	-- THE GRAB: you crouch and lift the lid... it creaks open a crack, a glint... then it
	-- gapes, yanks you in head-first (legs kicking out of the top), chews you a few times
	-- and spits you out across the walk. Your character is pinned (anchored) throughout.
	local function grab(player)
		local char, phum, hrp = aliveChar(player)
		local st = core.states[player]
		if not (char and st) or (hrp.Position - root.Position).Magnitude > 8 then
			return
		end
		local G = CFG.Grab
		local total = 0.8 + 0.35 + 0.3 + G.Chews * G.ChewTime + 0.4
		local t = now()
		core.setAction(st, t, total, total, total) -- no rolling, swinging or drinking your way out
		st.healing = false
		core.cancelSwing(st)
		core.FxRemote:FireClient(player, "Grabbed", total)
		M.grabbing = true
		local floorY = spot.Position.Y
		local front = flat(root.CFrame.LookVector).Unit
		local stand = Vector3.new(root.Position.X, floorY + 3, root.Position.Z) + front * 3.3
		local lookAt = Vector3.new(root.Position.X, floorY + 3, root.Position.Z)
		hrp.Anchored = true
		hrp.CFrame = CFrame.lookAt(stand, lookAt)
		local function held()
			local c, h = aliveChar(player)
			return c == char and h == phum and M.alive
		end
		local function release()
			M.grabbing = false
			if hrp.Parent then
				hrp.Anchored = false
				pcall(function()
					hrp:SetNetworkOwner(player)
				end)
			end
		end

		-- 1) you crouch and lift the lid a crack. something glints inside
		playerPose(char, "Crouch", 0.3)
		task.wait(0.35)
		setLid(0.35, 0.45, Enum.EasingStyle.Sine)
		playSound(root, SOUNDS.Unsheath, 0.5, 0.35) -- the creak
		for _, p in ipairs(hidden) do
			if p.Name == "Eye" then
				p.Transparency = 0
			end
		end
		task.wait(0.45)
		if not held() then
			return release()
		end

		-- 2) it gapes: teeth, tongue, the lid flung back
		showMouth(true)
		setLid(1.9, 0.1, Enum.EasingStyle.Back)
		playSound(root, SOUNDS.Unsheath, 1, 0.4)
		playSound(root, SOUNDS.Impact, 1, 0.45)
		burst(root.Position + Vector3.new(0, 1.2, 0), Color3.fromRGB(70, 20, 22), 18, 0.35, 12)
		core.FxRemote:FireClient(player, "Message", "It's a mimic!")
		playerPose(char, "Flinch", 0.08)
		task.wait(0.35)
		if not held() then
			return release()
		end

		-- 3) yanked in head-first, legs out of the top; the lid clamps down on you
		local mouth = root.Position + Vector3.new(0, H / 2 + 1.3, 0) + front * 0.2
		local dive = CFrame.new(mouth) * CFrame.lookAt(stand, lookAt).Rotation * CFrame.Angles(math.rad(-160), 0, 0)
		local from = hrp.CFrame
		playerPose(char, "Stagger", 0.1)
		for i = 1, 8 do
			hrp.CFrame = from:Lerp(dive, i / 8)
			task.wait(1 / 30)
		end
		setLid(0.75, 0.08, Enum.EasingStyle.Linear)
		playSound(root, SOUNDS.Impact, 1, 0.6)
		core.FxRemote:FireAllClients("Shake", root.Position, 0.7)
		task.wait(0.3 - 8 / 30 + 0.1)

		-- 4) chewed: the box heaves, the lid works up and down, you kick
		local rest = root.CFrame
		for i = 1, G.Chews do
			if not held() then
				break
			end
			setLid(1.15, G.ChewTime * 0.4)
			root.CFrame = rest * CFrame.new(0, 0.35, 0) * CFrame.Angles(math.rad(math.random(-6, 6)), 0, math.rad(math.random(-6, 6)))
			playerPose(char, i % 2 == 0 and "Stagger" or "Flinch", 0.1)
			task.wait(G.ChewTime * 0.45)
			setLid(0.7, G.ChewTime * 0.12, Enum.EasingStyle.Linear)
			root.CFrame = rest
			playSound(root, SOUNDS.Impact, 0.9, 0.5 + i * 0.08)
			burst(mouth, Color3.fromRGB(110, 14, 16), 14, 0.3, 10)
			core.FxRemote:FireAllClients("Shake", root.Position, 0.45)
			damagePlayer(player, G.ChewDamage, root.Position, "Small")
			-- (a hit's stun would free your inputs early: pin them again)
			local left = (G.Chews - i + 0.55) * G.ChewTime + 0.4
			core.setAction(st, now(), left, left, left)
			core.FxRemote:FireClient(player, "Grabbed", left)
			task.wait(G.ChewTime * 0.55)
		end
		root.CFrame = rest

		-- 5) spat out across the walk (or, if it finished you, what's left of you)
		setLid(1.9, 0.1, Enum.EasingStyle.Back)
		playSound(root, SOUNDS.Lunge, 1, 0.6)
		if hrp.Parent then
			hrp.CFrame = CFrame.lookAt(stand + front * 0.5, lookAt)
		end
		release()
		if held() then
			damagePlayer(player, G.SpitDamage, root.Position, "Knockdown")
		end
		task.wait(0.3)
		setLid(0.4, 0.3)
	end

	local function wake(player)
		if M.awake or not M.alive then
			return
		end
		M.awake = true
		M.gen += 1
		pp.Enabled = false
		model.Parent = core.EnemiesFolder -- now blades and lock-on find it
		local ok, err = pcall(grab, player)
		if not ok then
			warn("[DGUS] Mimic grab error: " .. tostring(err))
			local _, _, hrp = aliveChar(player)
			if hrp then
				hrp.Anchored = false -- never leave anyone pinned
			end
			M.grabbing = false
			showMouth(true)
			setLid(1.2, 0.2)
		end
		task.wait(0.8)
		task.spawn(brain)
	end
	pp.Triggered:Connect(wake)

	-- hits: poise, and when it breaks it tips over gasping, lid flopped open
	core.registerTarget(function(m)
		if m ~= model then
			return nil
		end
		return {
			owner = M,
			actor = actor,
			maxPoise = CFG.Poise,
			freeze = false,
			onBreak = function()
				if M.grabbing then
					return -- (mid-meal: it doesn't let go for anyone)
				end
				M.staggerUntil = now() + CFG.Stagger
				setLid(2.2, 0.2)
				local cf = root.CFrame
				root.CFrame = cf * CFrame.Angles(0, 0, 0.35) + Vector3.new(0, 0.3, 0)
				playSound(root, SOUNDS.Impact, 0.7, 0.9)
				task.delay(CFG.Stagger, function()
					if M.alive and root.Parent then
						root.CFrame = CFrame.new(root.Position.X, cf.Position.Y, root.Position.Z) * cf.Rotation
						setLid(0, 0.2)
					end
				end)
			end,
		}
	end)

	hum.Died:Connect(function()
		M.alive = false
		M.awake = false
		model.Parent = workspace -- (out of the enemies: no locking onto a corpse)
		setLid(2.4, 0.4, Enum.EasingStyle.Bounce)
		playSound(root, SOUNDS.Impact, 0.8, 0.4)
		burst(root.Position + Vector3.new(0, 1, 0), Color3.fromRGB(70, 66, 60), 24, 0.5, 8)
		task.delay(1.5, function()
			for _, p in ipairs(hidden) do
				TweenService:Create(p, TweenInfo.new(1.5), { Transparency = 1 }):Play()
			end
		end)
	end)
end

return Mimic
