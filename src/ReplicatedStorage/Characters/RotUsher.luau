--!nonstrict
-- ROTTED (kind RotUsher): the things that wander the far township over the Crossing.
-- Tall, starved-thin, grey and wet, a long skull with a mouth that hangs open and no
-- eyes. The rot has swollen the right arm into a long knotted club of flesh with
-- grasping fingers, and little grey rot-arms twitch out of it (anchors tagged "RotLimb"
-- with Follow set; the clients grow them, Carrier.growths).
--   Slam  the arm brought down overhead (the hollow's windup-and-strike, Hollow.attack)
--   Grab  coils low, the arm shoots out; caught, you're hoisted, squeezed, and smashed
--         into the floor. Roll through the reach. Tuning: M.Def.Grab.
--   Leap  from well out of reach: a crouch, a sprint at you, then a long leap that comes
--         down arm-first where you stood. Tuning: M.Def.Leap.
-- The rig's boxes are all hidden: what you see is rounded flesh laid over them.
--
-- EVERYTHING ABOUT THIS CHARACTER IS IN THIS ONE FILE:
--   M.Proportions / M.Poses   body shape and its full-body poses (the client animator uses these too)
--   M.Colors / M.Look         how the rig is dressed (RigBuilder calls Look with a kit of helpers:
--                             deco(part, name, size, offset, color, material?, shape?), V(x,y,z), at(x,y,z) ...)
--   M.Weapons / M.Grips       the arm's model (held in the hand like a weapon), and its grab grips
--   M.Def / M.attack          stats and behaviour (the shared brain in GameServer/Enemies.lua)
local CollectionService = game:GetService("CollectionService")
local Hollow = require(script.Parent:WaitForChild("Hollow"))

local M = {}
M.Kind = "RotUsher"
M.Proportions = { girth = 0.5, arm = 1.35, hunch = 0.4 } -- starved thin, arms past the knee
M.IdlePose = "RIdle"
M.Poses = {
	-- hunched, head pushed forward and cocked, swaying
	RIdle = { drop = 0.35, lean = 0.45, head = -0.35, side = 0.12, footR = -0.3, footL = 0.35, spread = 0.15, la1 = 0.2, lel = 0.2, freeL = 0.3, breathe = 2.5 },
	-- coiled low before the grab, the arm drawn back
	RCrouch = { drop = 0.75, lean = 0.55, twist = 0.5, head = -0.25, footR = -0.55, footL = 0.6, spread = 0.2, freeL = 0 },
	-- holding you up and squeezing: reared back, head lolled
	RSqueeze = { drop = 0.3, lean = -0.12, head = -0.6, twist = -0.15, side = -0.1, breathe = 4, freeL = 0 },
	RSqueeze2 = { drop = 0.4, lean = 0.05, head = -0.3, twist = 0.1, side = 0.12, breathe = 4, freeL = 0 },
}
local SKIN, SHADE, ROT, ROT_DARK = Color3.fromRGB(132, 134, 122), Color3.fromRGB(84, 86, 78), Color3.fromRGB(112, 70, 74), Color3.fromRGB(70, 44, 48)
local CLAW = Color3.fromRGB(34, 30, 26)
M.Colors = { skin = SKIN, torso = SKIN, legs = SKIN, arms = SKIN }
M.FistSkin = true

local CYL, BALL = Enum.PartType.Cylinder, Enum.PartType.Ball
local UP = CFrame.Angles(0, 0, math.pi / 2) -- (a cylinder's length runs along X: stand it up)

-- a rot-arm anchor: invisible, its LookVector the way the arm sprouts
local function rotAnchor(p, seed, scale)
	p.Transparency = 1
	p:SetAttribute("Seed", seed)
	p:SetAttribute("Scale", scale)
	p:SetAttribute("Follow", true)
	CollectionService:AddTag(p, "RotLimb")
end

function M.Look(k)
	local deco, parts, V, at, MAT, s = k.deco, k.parts, k.V, k.at, k.MAT, k.s
	local cw, ch, cd, hw = k.cw, k.ch, k.cd, k.hw
	local function wet(p)
		p.Reflectance = 0.07
		return p
	end
	local function flesh(on, name, size, cf, col, shape)
		return wet(deco(on, name, size, cf, col or SKIN, MAT.SmoothPlastic, shape))
	end
	for _, p in pairs(parts) do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
			p.Transparency = 1
		end
	end
	-- limbs: a rounded bone of flesh along each, a knob at its top joint
	local function limb(pn, dia, col)
		local L = parts[pn].Size.Y / s
		flesh(pn, "Flesh", V(L, dia, dia), at(0, 0, 0) * UP, col, CYL)
		flesh(pn, "Joint", V(dia * 1.2, dia * 1.2, dia * 1.2), at(0, L / 2, 0), SHADE, BALL)
	end
	for _, n in ipairs({ "R", "L" }) do
		limb(n .. "Thigh", 0.36)
		limb(n .. "Shin", 0.28)
		-- long splayed feet, three toes
		flesh(n .. "Foot", "Foot", V(1.0, 0.24, 0.24), at(0, -0.02, -0.1) * CFrame.Angles(0, math.pi / 2, 0), SHADE, CYL)
		for i = -1, 1 do
			flesh(n .. "Foot", "Toe", V(0.55, 0.09, 0.09), at(i * 0.12, -0.08, -0.75) * CFrame.Angles(0, math.pi / 2 + i * 0.3, 0), CLAW, CYL)
		end
	end
	limb("LUpperArm", 0.3)
	limb("LLowerArm", 0.24)
	-- the left hand: long thin fingers hanging past it, curled
	local la = parts.LLowerArm.Size.Y / s
	for i = 0, 3 do
		local x = (i - 1.5) * 0.08
		flesh("LLowerArm", "Finger", V(0.75, 0.07, 0.07), at(x, -la / 2 - 0.4, -0.05) * CFrame.Angles(0.25, 0, 0) * UP, SHADE, CYL)
		flesh("LLowerArm", "Claw", V(0.3, 0.05, 0.05), at(x, -la / 2 - 0.85, -0.2) * CFrame.Angles(0.8, 0, 0) * UP, CLAW, CYL)
	end
	-- the right arm: swollen, knotted, the rot breaking out of it
	limb("RUpperArm", 0.62, SKIN:Lerp(ROT, 0.3))
	limb("RLowerArm", 0.78, SKIN:Lerp(ROT, 0.5))
	for i, b in ipairs({ { "RUpperArm", 0.22, 0.25, -0.12, 0.45 }, { "RUpperArm", -0.18, -0.3, 0.2, 0.38 }, { "RLowerArm", 0.3, 0.3, 0.05, 0.55 }, { "RLowerArm", -0.25, -0.1, -0.3, 0.42 }, { "RLowerArm", 0.1, -0.5, 0.28, 0.36 } }) do
		flesh(b[1], "Lump", V(b[5], b[5], b[5]), at(b[2], b[3], b[4]), ROT:Lerp(ROT_DARK, (i % 3) / 2), BALL)
	end
	rotAnchor(deco("RUpperArm", "RotLimbRoot", V(0.3, 0.3, 0.3), CFrame.lookAt(at(0.35, 0.2, 0).Position, at(2, 0.8, 0.4).Position), ROT, MAT.SmoothPlastic), 7101, 0.3)
	rotAnchor(deco("RLowerArm", "RotLimbRoot", V(0.3, 0.3, 0.3), CFrame.lookAt(at(0.3, 0, 0.4).Position, at(1, 0.3, 2).Position), ROT, MAT.SmoothPlastic), 7102, 0.26)
	-- the body: a thin trunk, the ribs standing out of it, a knobbled spine, bony shoulders
	flesh("Chest", "Trunk", V(ch, cd * 0.85, cd * 0.85), at(0, 0, 0.05) * UP, SKIN, CYL)
	flesh("Chest", "Shoulders", V(cw * 0.95, 0.3, 0.3), at(0, ch / 2 - 0.15, 0.05), SHADE, CYL)
	for i = 0, 4 do
		local y = ch * 0.32 - i * ch * 0.14
		flesh("Chest", "Rib", V(cw * (0.62 - i * 0.05), 0.1, 0.1), at(0, y, -cd * 0.38) * CFrame.Angles(0, 0, (i % 2 == 0) and 0.06 or -0.06), SKIN:Lerp(Color3.new(1, 1, 1), 0.12), CYL)
		flesh("Chest", "Vertebra", V(0.17, 0.17, 0.17), at(0, y + 0.05, cd * 0.45), SHADE, BALL)
	end
	flesh("Chest", "Gut", V(0.5, cd * 0.6, cd * 0.6), at(0, -ch / 2 + 0.15, 0.1) * UP, SHADE, CYL) -- sunk in under the ribs
	local hH = parts.Hips.Size.Y / s
	flesh("Hips", "Pelvis", V(hw * 0.85, 0.42, 0.42), at(0, 0, 0), SHADE, CYL)
	flesh("Hips", "Waist", V(hH * 0.6, 0.3, 0.3), at(0, hH / 2, 0.05) * UP, SHADE, CYL)
	deco("Hips", "Rag", V(hw * 0.5, 0.9, 0.05), at(0.05, -0.45, -0.24) * CFrame.Angles(-0.05, 0, 0.08), Color3.fromRGB(46, 40, 34), MAT.Fabric)
	-- neck and head: a long skull pushed forward, the jaw hanging open, no eyes at all
	flesh("Chest", "Neck", V(0.75, 0.22, 0.22), at(0, ch / 2 + 0.3, -0.05) * CFrame.Angles(0.35, 0, 0) * UP, SHADE, CYL)
	flesh("Head", "Skull", V(1.0, 1.0, 1.0), at(0, 0.15, 0.05), SKIN, BALL)
	flesh("Head", "SkullBack", V(0.85, 0.85, 0.85), at(0, 0.42, 0.38), SKIN, BALL)
	flesh("Head", "Jaw", V(0.62, 0.62, 0.62), at(0, -0.35, -0.12), SHADE, BALL)
	deco("Head", "Mouth", V(0.06, 0.5, 0.5), at(0, -0.3, -0.42) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(16, 8, 8), MAT.SmoothPlastic, CYL)
	for i = -2, 2 do
		for _, row in ipairs({ { -0.1, -1 }, { -0.5, 1 } }) do
			deco("Head", "Tooth", V(0.16, 0.04, 0.04), at(i * 0.08, row[1] + row[2] * 0.02, -0.46) * UP, Color3.fromRGB(168, 158, 128), MAT.SmoothPlastic, CYL)
		end
	end
	for _, x in ipairs({ -0.2, 0.2 }) do -- where the eyes should be: deep pits
		deco("Head", "Socket", V(0.26, 0.26, 0.26), at(x, 0.2, -0.4), Color3.fromRGB(14, 10, 10), MAT.SmoothPlastic, BALL)
	end
end

M.Weapons = {
	-- the arm's end, held like a club: a knotted chain of swelling flesh, lumps bulging
	-- off it, a hand of five long jointed fingers; more rot-arms writhing out of it
	RotArm = function(w)
		local mk, add, sc = w.mk, w.add, w.scale
		local mat = Enum.Material.SmoothPlastic
		-- (add() only offsets along Y/Z: an X offset rides in the rotation, scaled by hand)
		local function place(p, cf, col, shape)
			p.Color = col
			p.Reflectance = 0.07
			if shape then
				p.Shape = shape
			end
			add(p, cf.Y, CFrame.new(cf.X * sc, 0, 0) * cf.Rotation, cf.Z)
			return p
		end
		local handle = mk("Wrist", Vector3.new(0.7, 0.7, 0.7), ROT_DARK, mat)
		handle.Shape = BALL
		handle.Reflectance = 0.07
		-- the chain: each segment bends a little off the last (pointing down the grip's -Y)
		local F = CFrame.new()
		local lumps = {}
		for i, sg in ipairs({ { 0.6, 0.55, 0.15, 0.1 }, { 0.8, 0.78, -0.12, 0.14 }, { 0.9, 1.0, 0.14, -0.1 }, { 0.8, 1.12, -0.16, 0.06 }, { 0.7, 0.92, 0.2, 0.12 }, { 0.5, 0.7, 0.12, -0.12 } }) do
			F = F * CFrame.Angles(sg[3], 0, sg[4])
			local a = F.Position
			local b = a - F.UpVector * sg[1]
			local col = SKIN:Lerp(ROT, 0.35 + (i % 3) * 0.15)
			place(mk("Flesh", Vector3.new(sg[1] + 0.1, sg[2], sg[2]), col, mat), CFrame.new((a + b) / 2) * F.Rotation * UP, col, CYL)
			place(mk("Knot", Vector3.one * sg[2] * 1.12, col, mat), CFrame.new(b), col:Lerp(ROT_DARK, 0.3), BALL)
			table.insert(lumps, { b, sg[2] })
			F = CFrame.new(b) * F.Rotation
		end
		-- lumps and boils bulging off it, every which side
		for i, l in ipairs(lumps) do
			local ang = i * 2.3
			local r = l[2] * 0.45
			local p = l[1] + Vector3.new(math.cos(ang) * r, 0.1, math.sin(ang) * r)
			place(mk("Lump", Vector3.one * l[2] * 0.6, ROT, mat), CFrame.new(p), ROT:Lerp(ROT_DARK, (i % 2) * 0.5), BALL)
		end
		-- the hand: a fat palm and five long fingers, each three joints, curled to grasp
		local palm = F * CFrame.new(0, -0.3, 0)
		place(mk("Palm", Vector3.new(0.9, 0.9, 0.9), ROT_DARK, mat), palm, SKIN:Lerp(ROT, 0.5), BALL)
		for f = 1, 5 do
			local G = palm * CFrame.Angles(0, (f - 3) * 0.55, 0) * CFrame.Angles(0.25, 0, 0) * CFrame.new(0, 0, -0.3)
			for j, len in ipairs({ 0.75, 0.6, 0.45 }) do
				G = G * CFrame.Angles(j == 1 and -0.3 or -0.45, 0, 0)
				local a = G.Position
				local b = a - G.UpVector * len
				local th = 0.16 - j * 0.03
				place(mk("Finger", Vector3.new(len + 0.05, th, th), SHADE, mat), CFrame.new((a + b) / 2) * G.Rotation * UP, SHADE, CYL)
				if j == 3 then
					place(mk("Claw", Vector3.new(0.35, 0.07, 0.07), CLAW, mat), CFrame.new(b - G.UpVector * 0.15) * G.Rotation * UP, CLAW, CYL)
				else
					place(mk("Knuckle", Vector3.one * th * 1.3, SHADE, mat), CFrame.new(b), SHADE, BALL)
				end
				G = CFrame.new(b) * G.Rotation
			end
		end
		-- rot-arms out of the swollen middle of it
		for i, l in ipairs({ lumps[2], lumps[3], lumps[5] }) do
			local anchor = mk("RotLimbRoot", Vector3.new(0.3, 0.3, 0.3), ROT, mat)
			rotAnchor(anchor, 7110 + i, 0.3)
			local ang = i * 2.1
			place(anchor, CFrame.lookAt(l[1], l[1] + Vector3.new(math.cos(ang), 0.3, math.sin(ang))), ROT)
		end
		return { handle = handle, bladeLen = 4.8 }
	end,
}
-- the grab's grips (the arm points down the grip's -Y)
local R = math.rad
M.Grips = {
	RGrabBack = { Vector3.new(1.2, 0.2, 0.9), CFrame.Angles(R(-40), 0, 0) }, -- drawn back, low
	RGrabReach = { Vector3.new(0.8, 0.9, -1.6), CFrame.Angles(R(90), 0, 0) }, -- straight out at you
	RGrabHold = { Vector3.new(0.8, 1.6, -1.4), CFrame.Angles(R(120), 0, 0) }, -- holding you up
}
M.BodyFor = { RGrabBack = "RCrouch", RGrabReach = "Strike", RGrabHold = "RSqueeze" }

-- stats (the shared brain in GameServer/Enemies.lua reads these)
M.Def = {
	HP = 150, Speed = 13, Scale = 1.2, Damage = 45, Range = 7.5, HalfAngle = 70, -- Damage: the slam
	Windup = 0.7, Recover = 0.25, Aggro = 64, Leash = 80, Stagger = 0.6, -- (Aggro was 32; Recover, and every pause below, cut to a quarter)
	HyperArmor = false, Weapon = "RotArm", Radius = 1.2, Lunge = 15,
	Poise = 30, HitLevel = "Knockdown",
	Skin = SKIN, Cloth = SHADE,
	-- the grab: within Engage, at most once per Cooldown, Chance of the time. Caught: lifted,
	-- squeezed (SqueezeDamage each), then slammed (SlamDamage, a knockdown). 3x10 + 40 = 70.
	Grab = { Engage = 6.5, Chance = 0.6, Cooldown = 3.5, Windup = 0.75, Lunge = 20, Range = 6.5, HalfAngle = 40,
		Lift = 0.35, Squeezes = 3, SqueezeTime = 0.55, SqueezeDamage = 10, SlamDamage = 40 },
	-- the running leap: from Min..Notice studs off, at most once per Cooldown. Sprints at
	-- Sprint speed for up to SprintTime (or until within Max), then leaps (at most Max
	-- studs, Air seconds, Height high) and lands arm-first: Damage to all within Radius.
	Leap = { Notice = 34, Min = 12, Max = 24, Cooldown = 4, Tell = 0.4, Sprint = 30, SprintTime = 0.8, Air = 0.6, Height = 8, Radius = 6.5, Damage = 40 },
}
-- (Enemies.lua hands attack() the target from NoticeRange out while e.noticed is unset:
-- the leap keeps it unset only while the leap is ready)
M.Def.NoticeRange = M.Def.Leap.Notice

---------------------------------------------------------------------------
-- server: the grab (the slam is the hollow's)
---------------------------------------------------------------------------
local now, flat, faceTowards, pose, bodyPose, playSound, SOUNDS, damagePlayer, playersInSector, aliveChar, states, setAction, cancelSwing, FxRemote, burst
local playersInRadius

local function playerPose(char, name, blend)
	char:SetAttribute("BP", name)
	char:SetAttribute("BPT", blend)
	char:SetAttribute("BPN", (char:GetAttribute("BPN") or 0) + 1)
end

local function free(e)
	if e.alive then
		pose(e, "Idle", 0.35)
	end
	e.hum.AutoRotate = true
	e.attacking = false
end

-- caught: hoisted up on the arm, squeezed, smashed into the floor. Both of you are
-- pinned (anchored) throughout; it lets go if it dies or is staggered, or you die.
local function hold(e, player)
	local char, phum, hrp = aliveChar(player)
	local st = states[player]
	if not (char and st) then
		return
	end
	local G, s, root = e.def.Grab, e.def.Scale, e.root
	local total = G.Lift + G.Squeezes * G.SqueezeTime + 0.3
	setAction(st, now(), total, total, total) -- no rolling, swinging or drinking your way out
	st.healing = false
	cancelSwing(st)
	FxRemote:FireClient(player, "Grabbed", total)
	root.Anchored = true
	hrp.Anchored = true
	local function held()
		local c, h = aliveChar(player)
		return c == char and h == phum and e.alive and now() >= e.staggerUntil
	end
	local function release()
		if hrp.Parent then
			hrp.Anchored = false
			pcall(function()
				hrp:SetNetworkOwner(player)
			end)
		end
		if root.Parent then
			root.Anchored = false
			pcall(function()
				root:SetNetworkOwner(nil)
			end)
		end
	end
	local face = Vector3.new(root.Position.X, root.Position.Y + 2 * s, root.Position.Z)
	local up = CFrame.lookAt((root.CFrame * CFrame.new(1 * s, 2.6 * s, -4.4 * s)).Position, face)
	-- 1) hoisted off your feet
	pose(e, "RGrabHold", 0.3)
	playerPose(char, "Stagger", 0.1)
	playSound(root, SOUNDS.Impact, 0.6, 0.4)
	local from = hrp.CFrame
	for i = 1, 8 do
		hrp.CFrame = from:Lerp(up, i / 8)
		task.wait(G.Lift / 8)
	end
	-- 2) squeezed
	for i = 1, G.Squeezes do
		if not held() then
			return release()
		end
		bodyPose(e, i % 2 == 0 and "RSqueeze" or "RSqueeze2", 0.1)
		playerPose(char, i % 2 == 0 and "Stagger" or "Flinch", 0.1)
		hrp.CFrame = up * CFrame.new(math.random(-10, 10) / 40, math.random(-10, 10) / 40, 0)
		playSound(root, SOUNDS.Impact, 0.8, 0.3 + i * 0.05)
		burst(up.Position, Color3.fromRGB(110, 14, 16), 12, 0.3, 8)
		damagePlayer(player, G.SqueezeDamage, root.Position, "Small")
		-- (a hit's stun would free your inputs early: pin them again)
		local left = (G.Squeezes - i) * G.SqueezeTime + 0.3
		setAction(st, now(), left, left, left)
		FxRemote:FireClient(player, "Grabbed", left)
		task.wait(G.SqueezeTime)
	end
	if not held() then
		return release()
	end
	-- 3) smashed down into the floor in front of it
	pose(e, "Strike", 0.12)
	local floorY = root.Position.Y - 3 * s
	local down = Vector3.new(up.Position.X, floorY + 3, up.Position.Z)
	for i = 1, 4 do
		hrp.CFrame = up:Lerp(CFrame.lookAt(down, Vector3.new(face.X, floorY + 3, face.Z)), i / 4)
		task.wait(0.03)
	end
	release()
	playSound(root, SOUNDS.Impact, 1, 0.35)
	FxRemote:FireAllClients("Shake", down, 1.1)
	burst(Vector3.new(down.X, floorY + 0.5, down.Z), Color3.fromRGB(70, 64, 58), 20, 0.5, 14)
	local c, h = aliveChar(player)
	if c == char and h == phum then
		damagePlayer(player, G.SlamDamage, root.Position, "Knockdown")
	end
	task.wait(0.225) -- spent: your window
end

local function grab(e, targetChar)
	local G, hum, root = e.def.Grab, e.hum, e.root
	local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
	if not tRoot then
		return
	end
	e.attacking = true
	hum:MoveTo(root.Position)
	hum.AutoRotate = false
	pose(e, "RGrabBack", G.Windup * 0.6)
	playSound(root, SOUNDS.Unsheath, 0.3, 0.3)
	local t0 = now()
	while now() - t0 < G.Windup do
		if not e.alive or now() < e.staggerUntil then
			return free(e)
		end
		if now() - t0 < G.Windup * 0.7 and tRoot.Parent then
			faceTowards(root, tRoot.Position)
		end
		task.wait()
	end
	-- the arm shoots out; anyone in its reach who isn't rolling is caught
	pose(e, "RGrabReach", 0.08)
	playSound(root, SOUNDS.Lunge, 0.8, 0.5)
	local v = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = flat(root.CFrame.LookVector) * G.Lunge + Vector3.new(0, v.Y, 0)
	local caught
	local s0 = now()
	while not caught and e.alive and now() - s0 < 0.3 do
		local t = now()
		for _, pl in ipairs(playersInSector(root.CFrame, G.Range * e.def.Scale, G.HalfAngle, 6 * e.def.Scale)) do
			local st = states[pl]
			if st and not (t >= st.iStart and t <= st.iEnd) and aliveChar(pl) then
				caught = pl
				break
			end
		end
		task.wait()
	end
	if caught and e.alive then
		hold(e, caught)
	else
		task.wait(0.2) -- grasped at nothing: overreached, open
	end
	free(e)
end

-- the running leap: crouch, sprint at you, then up and down arm-first where you are
local function leap(e, tRoot)
	local L, hum, root, s = e.def.Leap, e.hum, e.root, e.def.Scale
	e.attacking = true
	hum:MoveTo(root.Position)
	hum.AutoRotate = false
	-- 1) the tell: drops into a crouch facing you, the arm drawn back
	pose(e, "RGrabBack", L.Tell)
	playSound(root, SOUNDS.Unsheath, 0.3, 0.25)
	local t0 = now()
	while now() - t0 < L.Tell do
		if not e.alive or now() < e.staggerUntil or not tRoot.Parent then
			return free(e)
		end
		faceTowards(root, tRoot.Position)
		task.wait()
	end
	-- 2) the sprint
	hum.AutoRotate = true
	hum.WalkSpeed = L.Sprint
	t0 = now()
	while now() - t0 < L.SprintTime and e.alive and now() >= e.staggerUntil and tRoot.Parent do
		if flat(tRoot.Position - root.Position).Magnitude <= L.Max * s then
			break
		end
		hum:MoveTo(tRoot.Position)
		task.wait()
	end
	hum.WalkSpeed = e.def.Speed
	if not e.alive or now() < e.staggerUntil or not tRoot.Parent then
		return free(e)
	end
	-- 3) the leap: committed to where you are at takeoff (as far as it can reach)
	hum:MoveTo(root.Position)
	hum.AutoRotate = false
	local start = root.Position
	local to = flat(tRoot.Position - start)
	if to.Magnitude > L.Max * s then
		to = to.Unit * L.Max * s
	end
	local landing = start + to
	faceTowards(root, landing)
	local rot = root.CFrame.Rotation
	pose(e, "Raise", 0.15)
	bodyPose(e, "Air", 0.15)
	playSound(root, SOUNDS.Lunge, 0.9, 0.45)
	root.Anchored = true
	t0 = now()
	while e.alive do
		local a = math.min((now() - t0) / L.Air, 1)
		root.CFrame = CFrame.new(start:Lerp(landing, a) + Vector3.new(0, math.sin(a * math.pi) * L.Height * s, 0)) * rot
		if a >= 1 then
			break
		end
		task.wait()
	end
	if root.Parent then
		root.Anchored = false
		pcall(function()
			root:SetNetworkOwner(nil)
		end)
	end
	if not e.alive then
		return free(e)
	end
	-- 4) down arm-first
	pose(e, "Strike", 0.06)
	bodyPose(e, "Strike", 0.06)
	local ground = landing - Vector3.new(0, 3 * s - 0.5, 0)
	playSound(root, SOUNDS.Impact, 1, 0.4)
	FxRemote:FireAllClients("Shake", ground, 1)
	burst(ground, Color3.fromRGB(70, 64, 58), 22, 0.6, 16)
	for _, pl in ipairs(playersInRadius(landing, L.Radius * s, 6 * s)) do
		damagePlayer(pl, L.Damage, landing, "Knockdown")
	end
	task.wait(0.275) -- landed, winded: your window
	free(e)
end

function M.attack(e, target)
	local G, L = e.def.Grab, e.def.Leap
	local tRoot = target:FindFirstChild("HumanoidRootPart")
	if not tRoot then
		return
	end
	local d = flat(tRoot.Position - e.root.Position).Magnitude
	if d > e.def.Range - 0.5 then
		-- out of arm's reach: the leap if it's ready and you're far enough off, else close in
		if not e.noticed and d >= L.Min and d <= L.Notice then
			e.noticed = true -- (back to closing in by pathfinding until the leap is ready again)
			task.delay(L.Cooldown, function()
				e.noticed = nil
			end)
			return leap(e, tRoot)
		end
		e.hum:MoveTo(tRoot.Position)
		return
	end
	if d < G.Engage * e.def.Scale and now() >= (e.nextGrab or 0) and math.random() < G.Chance then
		e.nextGrab = now() + G.Cooldown
		return grab(e, target)
	end
	return Hollow.attack(e, target) -- the slam
end

function M.init(core)
	now, flat, faceTowards, pose, bodyPose, playSound, SOUNDS = core.now, core.flat, core.faceTowards, core.pose, core.bodyPose, core.playSound, core.SOUNDS
	damagePlayer, playersInSector, aliveChar, states, setAction, cancelSwing, FxRemote, burst = core.damagePlayer, core.playersInSector, core.aliveChar, core.states, core.setAction, core.cancelSwing, core.FxRemote, core.burst
	playersInRadius = core.playersInRadius
end

return M
