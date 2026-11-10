--!nonstrict
-- Puppeteer: procedurally animates every Prison rig (player knight, hollows,
-- Jailer, Warden) on this client, every frame.
--
--   * walk cycle from real velocity (strafing works, stride scales with speed)
--   * body poses blended from the server's "BP"/"BPT"/"BPN" attributes
--   * weapon hand(s) locked to the weapon grip with two-bone IK
--   * feet planted with leg IK when crouching / kneeling
--   * your own roll (tucked somersault) and knockdown, set by SoulsClient
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PM = require(ReplicatedStorage:WaitForChild("PuppetMath"))
local Roster = require(ReplicatedStorage:WaitForChild("Roster"))
local player = Players.LocalPlayer
local EnemiesFolder = workspace:WaitForChild("Enemies")

-- Held strongly, and pruned when a model is gone (below). (It was a weak-keyed table: but
-- Roblox can collect the Lua handle of an Instance that still exists, which silently dropped
-- a rig's entry - its pose then restarted from Idle, over and over: a kneeling boss "bounced"
-- through the start of its kneel until something else happened to hold a handle to it.)
local rigs = {}

local function smoothstep(a)
	return a * a * (3 - 2 * a)
end

local function scanJoints(model, J)
	local joints, n = {}, 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") and J[d.Name] then
			joints[d.Name] = d
			n += 1
		end
	end
	return joints, n
end

local function getRig(model)
	local st = rigs[model]
	if st then
		return st
	end
	local kind = model:GetAttribute("PrisonRig")
	if not kind then
		return nil
	end
	local s = model:GetAttribute("RigScale") or 1
	local D = PM.dims(kind, s)
	local J = PM.joints(D)
	local joints, count = scanJoints(model, J)
	local need = 0
	for _ in pairs(J) do
		need += 1
	end
	st = {
		kind = kind,
		s = s,
		D = D,
		J = J,
		joints = joints,
		count = count,
		need = need,
		nextScan = 0,
		behind = model:GetAttribute("ArmBehind") and 1 or 0,
		phase = math.random() * 6,
		walk = 0,
		cur = PM.pose("Idle", kind),
		from = nil,
		to = nil,
		t0 = 0,
		dur = 0.2,
		bpn = nil,
	}
	rigs[model] = st
	return st
end

---------------------------------------------------------------------------
-- your sword stays in your hand while you roll / lie on the floor
---------------------------------------------------------------------------
local held = nil -- { model, parts = {{copy, offset}}, rel }
local function startHeld(model, st)
	if held or not st.handleRel then
		return
	end
	local weapon = model:FindFirstChild("Weapon")
	local grip = weapon and weapon:FindFirstChild("GripWeld", true)
	local handle = grip and grip.Part1
	if not handle then
		return
	end
	local copy = {}
	-- (a dual-wielder's second sword too, kept in its own hand: e[3] = "L")
	for _, w in ipairs({ { weapon, handle, nil }, { model:FindFirstChild("Weapon2"), nil, "L" } }) do
		local wm, h, hand = w[1], w[2], w[3]
		local g2 = wm and wm:FindFirstChild("GripWeld", true)
		h = h or (g2 and g2.Part1)
		if wm and h and (hand == nil or st.handleRel2) then
			for _, p in ipairs(wm:GetDescendants()) do
				if p:IsA("BasePart") then
					local c = p:Clone()
					for _, ch in ipairs(c:GetChildren()) do
						if not ch:IsA("DataModelMesh") then
							ch:Destroy()
						end
					end
					c.Anchored = true
					c.CanCollide = false
					c.CanQuery = false
					c.CanTouch = false
					c.Parent = workspace
					table.insert(copy, { c, h.CFrame:Inverse() * p.CFrame, hand })
				end
			end
		end
	end
	held = { model = model, parts = copy, rel = st.handleRel, rel2 = st.handleRel2 }
	model:SetAttribute("HideWeapon", true)
end

local function stopHeld()
	if not held then
		return
	end
	for _, e in ipairs(held.parts) do
		e[1]:Destroy()
	end
	if held.model then
		held.model:SetAttribute("HideWeapon", false)
	end
	held = nil
end

---------------------------------------------------------------------------
-- per character
---------------------------------------------------------------------------
local function update(model, dt, now, isLocal)
	local st = getRig(model)
	if st and st.s ~= (model:GetAttribute("RigScale") or 1) then
		rigs[model] = nil -- (grown or shrunk, e.g. by armor: measured afresh)
		st = getRig(model)
	end
	if not st then
		return
	end
	local root = model:FindFirstChild("HumanoidRootPart")
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then
		return
	end
	-- The client can compute its own HipHeight for these custom rigs (0 if the root
	-- arrived before the legs), which draws them sunk into the floor. Hold it true.
	local wantHip = model:GetAttribute("HipHeight")
	if wantHip and math.abs(hum.HipHeight - wantHip) > 0.01 then
		hum.HipHeight = wantHip
	end
	if st.count < st.need and now > st.nextScan then
		st.joints, st.count = scanJoints(model, st.J)
		st.nextScan = now + 1
	end
	-- a keyframed animation playing ("Anim", set by the server): it has the rig. Every joint held at the rest it was
	-- made on (the animation's keyframes add to that), and the character's own extra joints too (its M.AnimRest)
	if model:GetAttribute("Anim") then
		for name, m in pairs(st.joints) do
			if m.Parent then
				m.C0 = st.J[name].C0
			end
		end
		local own = Roster.byKind[st.kind]
		if own and own.AnimRest then
			own.AnimRest(model, st, now)
		end
		return
	end
	local D = st.D
	local s = D.s

	-- body pose blending
	local bpn = model:GetAttribute("BPN")
	if bpn ~= nil and bpn ~= st.bpn then
		st.bpn = bpn
		st.from = table.clone(st.cur)
		st.to = PM.pose(model:GetAttribute("BP") or "Idle", st.kind)
		st.t0 = now
		st.dur = math.max(model:GetAttribute("BPT") or 0.2, 0.05)
	end
	if st.to then
		st.cur = PM.lerpPose(st.from, st.to, smoothstep(math.clamp((now - st.t0) / st.dur, 0, 1)))
	end

	-- locomotion
	local v = root.AssemblyLinearVelocity
	local flatV = Vector3.new(v.X, 0, v.Z)
	local speed = flatV.Magnitude / s
	local target = math.clamp(speed / (D.walkRef or 11), 0, 1) -- (a giant moving slowly for his size still walks: D.walkRef)
	st.walk += (target - st.walk) * (1 - math.exp(-dt * 8))
	st.phase += dt * speed * (D.cadence or 0.55)
	local ctx = {
		phase = st.phase,
		walk = st.walk,
		stride = st.walk * 0.85 * s,
		lift = st.walk * 0.45 * s,
		moveDir = speed > 0.6 and flatV.Unit or nil,
		t = now,
		groundY = root.Position.Y - D.rootY,
	}
	-- bending into turns (D.turnBend, e.g. the dogs): from how fast it's actually turning,
	-- smoothed; turning left curls the waist and the neck left, turning right, right
	if D.turnBend then
		local look = root.CFrame.LookVector
		local yaw = math.atan2(-look.X, -look.Z)
		local rate = st.lastYaw and ((yaw - st.lastYaw + math.pi) % (2 * math.pi) - math.pi) / math.max(dt, 1e-3) or 0
		st.lastYaw = yaw
		local want = math.clamp(rate * D.turnBend, -1, 1) -- (up to ~57 degrees at the waist)
		st.bend = (st.bend or 0) + (want - (st.bend or 0)) * (1 - math.exp(-dt * 10))
		ctx.bend = st.bend
	end

	-- the off arm folded behind the back (server's "ArmBehind", e.g. the Silver Knight's first phase)
	st.behind += ((model:GetAttribute("ArmBehind") and 1 or 0) - st.behind) * (1 - math.exp(-dt * 5))
	ctx.armBehind = st.behind

	-- hands on the weapon
	local weapon = model:FindFirstChild("Weapon")
	local grip = weapon and weapon:FindFirstChild("GripWeld", true)
	local gripCF
	if grip and grip.Parent then
		gripCF = root.CFrame * grip.C0
		ctx.rightTarget = gripCF.Position
		-- two hands on a long haft: the body type's own, or the weapon's (Config.Weapons TwoHand)
		local twoHand = D.twoHand or model:GetAttribute("TwoHand")
		if twoHand and model:GetAttribute("BP") ~= "Drink" then
			ctx.leftTarget = (gripCF * CFrame.new(0, twoHand, 0)).Position
		end
	end
	-- a second weapon of its own in the left hand (the Silver Knight's phase 2)
	local weapon2 = model:FindFirstChild("Weapon2")
	local grip2 = weapon2 and weapon2:FindFirstChild("GripWeld", true)
	if grip2 and grip2.Enabled then
		ctx.leftTarget = (root.CFrame * grip2.C0).Position
	end

	-- your own roll and knockdown (local attributes set by SoulsClient)
	local special = false
	if isLocal then
		local r0, rd = model:GetAttribute("RollT0"), model:GetAttribute("RollDur")
		if r0 and rd and now >= r0 and now <= r0 + rd then
			special = true
			local a = (now - r0) / rd
			local k = math.sin(a * math.pi)
			if model:GetAttribute("RollBack") then
				ctx.bodyRot = CFrame.Angles(k * 0.45, 0, 0)
				ctx.bodyDrop = -k * 0.4 * s
				ctx.tuck = k * 0.3
			else
				local axis = model:GetAttribute("RollAxis") or Vector3.new(-1, 0, 0)
				local eased = a < 0.5 and 2 * a * a or 1 - ((-2 * a + 2) ^ 2) / 2
				ctx.bodyRot = CFrame.fromAxisAngle(axis, eased * math.pi * 2)
				ctx.bodyDrop = k * 1.25 * s
				ctx.tuck = math.min(1, k * 1.8)
				ctx.noIK = true
				ctx.armOverride = { 1.3, 0, 0.3, 2.0 }
			end
		end
		local d0, dd, du = model:GetAttribute("DownT0"), model:GetAttribute("DownDur"), model:GetAttribute("DownGetUp")
		if not special and d0 and dd and now >= d0 and now <= d0 + dd then
			special = true
			local t = now - d0
			local k
			if t < 0.25 then
				k = smoothstep(t / 0.25) -- thrown down
			elseif t < du then
				k = 1
			else
				k = 1 - smoothstep(math.clamp((t - du) / (dd - du), 0, 1)) -- getting up
			end
			ctx.bodyRot = CFrame.Angles(k * math.rad(85), 0, 0)
			ctx.bodyDrop = 2.3 * k * s
			ctx.limp = k
			ctx.noIK = k > 0.3
			ctx.armOverride = k > 0.3 and { 0.5, 0, 0.9, 0.3 } or nil
		end
	end

	local C0, W = PM.solve(D, st.J, root.CFrame, st.cur, ctx)
	for name, cf in pairs(C0) do
		local m = st.joints[name]
		if m and m.Parent then
			m.C0 = cf
		end
	end
	-- a character's own way of moving, layered over the pose (its file's M.Gait, e.g. the Consul's roll)
	local own = Roster.byKind[st.kind]
	if own and own.Gait then
		own.Gait(model, st, dt, now)
	end

	-- remember how the sword sits in the hand, so it can follow the hand mid-roll
	if isLocal then
		local hand = W.RLowerArm
		if not special and gripCF and hand and grip and grip.Part1 then
			st.handleRel = hand:Inverse() * grip.Part1.CFrame
			if grip2 and grip2.Enabled and grip2.Part1 and W.LLowerArm then
				st.handleRel2 = W.LLowerArm:Inverse() * grip2.Part1.CFrame
			else
				st.handleRel2 = nil
			end
			stopHeld()
		elseif special then
			startHeld(model, st)
			if held and hand then
				local handleCF = hand * held.rel
				local handleCF2 = W.LLowerArm and held.rel2 and W.LLowerArm * held.rel2
				for _, e in ipairs(held.parts) do
					local cf = e[3] and handleCF2 or handleCF
					if cf then
						e[1].CFrame = cf * e[2]
					end
				end
			end
		end
		-- camera fade + hidden real weapon while the copy is shown
		local fade = model:GetAttribute("CamFade") or 0
		local hideW = model:GetAttribute("HideWeapon") == true
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				d.LocalTransparencyModifier = (hideW and ((weapon and d:IsDescendantOf(weapon)) or (weapon2 and d:IsDescendantOf(weapon2)))) and 1 or fade
			end
		end
		if held then
			for _, e in ipairs(held.parts) do
				e[1].LocalTransparencyModifier = fade
			end
		end
	end
end

local nextPrune = 0
RunService:BindToRenderStep("PrisonPuppeteer", Enum.RenderPriority.Character.Value + 1, function(dt)
	local now = os.clock()
	if now > nextPrune then
		nextPrune = now + 2
		for m in pairs(rigs) do
			if not m.Parent then
				rigs[m] = nil
			end
		end
	end
	for _, m in ipairs(EnemiesFolder:GetChildren()) do
		update(m, dt, now, false)
	end
	local npcs = workspace:FindFirstChild("NPCs") -- Wick
	if npcs then
		for _, m in ipairs(npcs:GetChildren()) do
			update(m, dt, now, false)
		end
	end
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl.Character then
			update(pl.Character, dt, now, pl == player)
		end
	end
end)

player.CharacterRemoving:Connect(function()
	stopHeld()
end)
