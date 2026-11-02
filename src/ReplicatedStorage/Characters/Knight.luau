--!nonstrict
-- KNIGHT: you. A skeleton that won't stay down, sword in hand. (The kind is still
-- called "Knight" everywhere in code.)
-- Your moveset is here too: the light chain, heavy, running attack, roll/backstep
-- and drinking from the flask. Attack numbers live in Config.Attacks / Config.Player.
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
M.Kind = "Knight"
M.Proportions = { girth = 0.7, arm = 1.05, hunch = 0.04 } -- bones: lean, but standing straight
M.IdlePose = "Guard" -- stands ready, shield-arm up
M.Poses = {
	-- the at-rest stance (init.server's rest loop): half a second of doing nothing and he straightens up -
	-- hips up, legs near straight, back upright (lean cancels his built-in stoop), arms hanging easy
	Rest = { drop = 0, lean = -0.04, head = 0, footR = 0, footL = 0, spread = 0.04, la1 = 0.1, la2 = 0.06, la3 = 0.08, lel = 0.3, freeL = 1, breathe = 1.5 },
	Guard = { drop = 0.25, lean = 0.12, la1 = 1.0, la2 = 0.35, la3 = 0.55, lel = 1.4, freeL = 0.3, footR = -0.35, footL = 0.4, spread = 0.1 },
	Drink = { drop = 0.05, lean = -0.1, head = -0.5, la1 = 2.3, la2 = 0, la3 = 0.8, lel = 2.3, freeL = 0 },
	-- running attack: low and driving forward, then the big unwinding sweep
	RunWindup = { drop = 0.35, lean = 0.45, twist = -0.75, head = -0.05, la1 = 0.7, la3 = -0.7, lel = 0.6, freeL = 0 },
	RunSlash = { drop = 0.45, lean = 0.4, twist = 1.05, head = 0.05, la1 = -0.5, la3 = -0.9, lel = 0.3, freeL = 0 },
	Deflect = { drop = 0.25, lean = -0.05, twist = 0.18, head = 0.05, footR = 0.35, footL = -0.3, spread = 0.25, freeL = 0, la1 = 0.85, la3 = -0.4, lel = 0.9 },
	-- on a ladder, hand over hand: one knee up and the free arm reaching, then the other
	Climb = { drop = 0.2, lean = 0.12, head = -0.25, footR = 0.15, footL = -0.1, lift = 0.6, la1 = 2.5, la2 = 0.1, la3 = -0.2, lel = 0.5, freeL = 0 },
	Climb2 = { drop = 0.35, lean = 0.1, head = -0.15, footR = -0.1, footL = 0.15, tuck = 0.25, la1 = 1.7, la2 = 0.1, la3 = -0.2, lel = 1.0, freeL = 0 },
	-- scythe deflect windup: upright, chin up, spinning the haft overhead
	Twirl = { drop = 0.15, lean = -0.12, head = -0.2, footR = 0.25, footL = -0.25, spread = 0.2, freeL = 0 },
	-- the Gozen Tachi's draw stance: sunk low, turned away, hand on the hilt at the hip
	Read = { drop = 0.2, lean = 0.1, head = 0.45, footR = -0.25, footL = 0.3, spread = 0.12, freeL = 0 },
	Iai = { drop = 1.0, lean = 0.4, twist = 0.5, head = -0.2, footR = 0.75, footL = -0.75, spread = 0.55, la1 = 0.5, la3 = 0.3, lel = 0.8, freeL = 0 }, -- (sunk right down, feet wide: the edgelord crouch)
}
-- you're a skeleton: the same bones as the prison's own (Characters/Skeleton.lua dresses
-- you), but upright, in a ragged blue cloak, with cold blue light in your sockets
local Skeleton = require(script.Parent:WaitForChild("Skeleton"))
M.Colors = Skeleton.Colors
M.FistSkin = true

function M.Look(k)
	k.NoTabard = true
	Skeleton.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, cd = k.cw, k.cd
	local model = parts.Chest.Parent
	for _, d in ipairs(model:GetChildren()) do
		if d.Name == "Eye" then
			d.Color = rgb(120, 190, 255)
		end
	end
	local cloak = rgb(34, 44, 70)
	deco("Chest", "Cloak", V(cw * 1.1, 2.6, 0.08), at(0, -0.55, cd / 2 + 0.2), cloak, MAT.Fabric)
	deco("Chest", "CloakHem", V(cw * 0.75, 0.45, 0.07), at(-0.2, -1.95, cd / 2 + 0.21), cloak:Lerp(rgb(0, 0, 0), 0.3), MAT.Fabric)
	deco("Chest", "Hood", V(cw * 0.9, 0.15, cd * 1.25), at(0, k.ch / 2 - 0.02, 0.1), cloak, MAT.Fabric) -- (low: clear of the jaw)
end

-- a jagged bolt of lightning from one point to another, n kinks, gone in a flash
local function lightningArc(from, to, n, width, jitter)
	local last = from
	for i = 1, n do
		local p = from:Lerp(to, i / n)
		if i < n then
			p += Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * jitter
		end
		local seg = Instance.new("Part")
		seg.Anchored, seg.CanCollide, seg.CanQuery, seg.CanTouch = true, false, false, false
		seg.Material = Enum.Material.Neon
		seg.Color = Color3.fromRGB(190, 225, 255)
		seg.Size = Vector3.new(width, width, (p - last).Magnitude)
		seg.CFrame = CFrame.lookAt((p + last) / 2, p)
		seg.Parent = workspace
		game:GetService("Debris"):AddItem(seg, 0.07)
		last = p
	end
end

M.Weapons = {
	Sword = function(w)
		local handle = w.mk("Grip", Vector3.new(0.25, 1, 0.25), w.wood, Enum.Material.Wood)
		w.add(w.mk("Guard", Vector3.new(1.1, 0.18, 0.3), w.iron, Enum.Material.Metal), -0.55)
		local steel = Color3.fromRGB(150, 146, 136)
		w.add(w.mk("Blade", Vector3.new(0.32, 3.2, 0.1), steel, Enum.Material.Metal), -2.25)
		-- the tip: a right triangle, its point on the back edge (a wedge turned so its slope
		-- runs across the blade's flat)
		local tip = w.mk("Blade", Vector3.new(0.1, 0.4, 0.32), steel, Enum.Material.Metal)
		tip.Shape = Enum.PartType.Wedge
		w.add(tip, -4.05, CFrame.fromMatrix(Vector3.zero, Vector3.zAxis, -Vector3.yAxis))
		return { handle = handle, bladeLen = 4.2 }
	end,
	-- a long blade with a gentle curve (built in segments, each turned a little further
	-- back) over a round guard; lightning crawls on it the whole time it exists
	GozenTachi = function(w)
		local handle = w.mk("Grip", Vector3.new(0.22, 1.5, 0.22), Color3.fromRGB(28, 24, 30), Enum.Material.Fabric)
		w.add(w.mk("Tsuba", Vector3.new(0.7, 0.08, 0.7), Color3.fromRGB(150, 120, 60), Enum.Material.Metal), -0.8)
		local N, L, BEND = 6, 0.88, math.rad(16) -- segments, each one's length, the whole curve
		local y, z, segs = -0.85, 0, {}
		for i = 1, N do
			local ang = BEND * (i - 0.5) / N
			local dy, dz = -math.cos(ang) * L, -math.sin(ang) * L
			-- (wide along Z, the plane it curves in: the edge on the outside of the curve, the
			-- spine inside - so the edge faces forward in its grips, not the flat)
			local bw = 0.21 - i * 0.015
			local seg = w.mk("Blade", Vector3.new(0.07, L + 0.03, bw), Color3.fromRGB(196, 204, 216), Enum.Material.Metal)
			w.add(seg, y + dy / 2, CFrame.Angles(ang, 0, 0), z + dz / 2)
			w.add(w.mk("Edge", Vector3.new(0.08, L + 0.03, 0.04), Color3.fromRGB(150, 200, 255), Enum.Material.Neon), y + dy / 2 - math.sin(ang) * bw / 2, CFrame.Angles(ang, 0, 0), z + dz / 2 + math.cos(ang) * bw / 2)
			y, z = y + dy, z + dz
			table.insert(segs, seg)
		end
		local function setup(h, a0, a1)
			for _, seg in ipairs(segs) do
				local spark = Instance.new("ParticleEmitter")
				spark.Texture = "rbxasset://textures/particles/sparkles_main.dds"
				spark.Color = ColorSequence.new(Color3.fromRGB(170, 215, 255))
				spark.LightEmission = 1
				spark.Size = NumberSequence.new(0.25, 0)
				spark.Lifetime = NumberRange.new(0.05, 0.14)
				spark.Speed = NumberRange.new(0, 3)
				spark.SpreadAngle = Vector2.new(180, 180)
				spark.Rate = 6
				spark.Parent = seg
			end
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(150, 200, 255)
			light.Range = 9
			light.Parent = segs[3]
			-- the flicker, and now and then a jagged arc jumping along the blade
			task.spawn(function()
				while h.Parent do
					light.Brightness = math.random() < 0.3 and 2.4 or 0.4 + math.random() * 0.6
					if math.random() < 0.35 then
						local from = a0.WorldPosition:Lerp(a1.WorldPosition, math.random() * 0.6)
						lightningArc(from, from:Lerp(a1.WorldPosition, 0.4), 3, 0.05, 0.5)
					end
					task.wait(0.06 + math.random() * 0.12)
				end
			end)
		end
		return { handle = handle, bladeLen = 5.6, setup = setup }
	end,
	-- a thick old tome, held open: two boards splayed in a shallow V with their pages up
	-- (the pages face the handle's +Y; BRead tilts them up toward your face)
	OldBook = function(w)
		local handle = w.mk("Spine", Vector3.new(0.14, 0.1, 1.4), Color3.fromRGB(60, 30, 22), Enum.Material.Leather)
		for _, side in ipairs({ -1, 1 }) do
			local tilt = CFrame.Angles(0, 0, side * math.rad(-12))
			w.add(w.mk("Board", Vector3.new(0.85, 0.06, 1.45), Color3.fromRGB(70, 36, 26), Enum.Material.Leather), 0, CFrame.new(side * 0.45, 0, 0) * tilt)
			w.add(w.mk("Pages", Vector3.new(0.78, 0.12, 1.32), Color3.fromRGB(200, 184, 150), Enum.Material.Sand), 0, CFrame.new(side * 0.43, 0.08, 0) * tilt)
		end
		w.add(w.mk("Ribbon", Vector3.new(0.06, 0.02, 0.9), Color3.fromRGB(120, 24, 22), Enum.Material.Fabric), 0.15, CFrame.new(0.1, 0, 0.5))
		return { handle = handle, bladeLen = 0.4 }
	end,
	-- the Pyralis Fang: a wand of the Malformed Watchdog's fang, bound to a charred bone haft in gold wire, a coal of the
	-- True one's dark-red fire caught in its hollow tip (it points along the handle's -Y, like a blade)
	PyralisFang = function(w)
		local handle = w.mk("Haft", Vector3.new(0.22, 1.0, 0.22), Color3.fromRGB(46, 30, 24), Enum.Material.Slate)
		w.add(w.mk("Pommel", Vector3.new(0.3, 0.22, 0.3), Color3.fromRGB(150, 112, 52), Enum.Material.Metal), 0.55)
		for i = 0, 2 do
			w.add(w.mk("Wire", Vector3.new(0.26, 0.05, 0.26), Color3.fromRGB(176, 140, 66), Enum.Material.Metal), 0.3 - i * 0.3)
		end
		w.add(w.mk("Fang", Vector3.new(0.2, 1.1, 0.24), Color3.fromRGB(206, 192, 160), Enum.Material.SmoothPlastic), -1.0, CFrame.Angles(0.12, 0, 0))
		w.add(w.mk("FangTip", Vector3.new(0.12, 0.5, 0.15), Color3.fromRGB(226, 214, 186), Enum.Material.SmoothPlastic), -1.75, CFrame.Angles(0.3, 0, 0), -0.12)
		for _, sx in ipairs({ -1, 1 }) do -- (two lesser teeth flaring off its root)
			w.add(w.mk("Tooth", Vector3.new(0.08, 0.45, 0.1), Color3.fromRGB(196, 180, 150), Enum.Material.SmoothPlastic), -0.55, CFrame.new(sx * 0.14, 0, 0) * CFrame.Angles(0, 0, sx * 0.5))
		end
		local coal = w.mk("Coal", Vector3.new(0.2, 0.2, 0.2), Color3.fromRGB(185, 25, 15), Enum.Material.Neon)
		w.add(coal, -1.45, nil, -0.05)
		local function setup(h)
			local light = Instance.new("PointLight")
			light.Color, light.Range, light.Brightness = Color3.fromRGB(200, 40, 20), 8, 1.4
			light.Parent = coal
			local fire = Instance.new("ParticleEmitter")
			fire.Texture = "rbxasset://textures/particles/fire_main.dds"
			fire.Color = ColorSequence.new(Color3.fromRGB(230, 50, 30), Color3.fromRGB(60, 6, 4))
			fire.Size = NumberSequence.new(0.35, 0)
			fire.Transparency = NumberSequence.new(0.3, 1)
			fire.Lifetime, fire.Rate, fire.Speed = NumberRange.new(0.3, 0.6), 22, NumberRange.new(0.5, 1.5)
			fire.LightEmission, fire.Acceleration = 0.4, Vector3.new(0, 4, 0)
			fire.Parent = coal
		end
		return { handle = handle, bladeLen = 1.8, setup = setup }
	end,
	-- the Old Book's dark twin: near-black boards, violet runes glowing on its pages
	DarkBook = function(w)
		local handle = w.mk("Spine", Vector3.new(0.14, 0.1, 1.4), Color3.fromRGB(22, 14, 30), Enum.Material.Leather)
		for _, side in ipairs({ -1, 1 }) do
			local tilt = CFrame.Angles(0, 0, side * math.rad(-12))
			w.add(w.mk("Board", Vector3.new(0.85, 0.06, 1.45), Color3.fromRGB(28, 18, 38), Enum.Material.Leather), 0, CFrame.new(side * 0.45, 0, 0) * tilt)
			w.add(w.mk("Pages", Vector3.new(0.78, 0.12, 1.32), Color3.fromRGB(52, 40, 70), Enum.Material.Sand), 0, CFrame.new(side * 0.43, 0.08, 0) * tilt)
			w.add(w.mk("Rune", Vector3.new(0.4, 0.02, 0.7), Color3.fromRGB(130, 80, 195), Enum.Material.Neon), 0, CFrame.new(side * 0.43, 0.15, 0) * tilt)
		end
		local function setup(h)
			local light = Instance.new("PointLight")
			light.Color, light.Range, light.Brightness = Color3.fromRGB(130, 80, 195), 8, 1.2
			light.Parent = h
			local smoke = Instance.new("ParticleEmitter")
			smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
			smoke.Color = ColorSequence.new(Color3.fromRGB(62, 20, 125))
			smoke.Size = NumberSequence.new(0.3, 0.9)
			smoke.Transparency = NumberSequence.new(0.5, 1)
			smoke.Lifetime = NumberRange.new(0.6, 1.1)
			smoke.Rate = 8
			smoke.Speed = NumberRange.new(0.3, 1)
			smoke.Parent = h
		end
		return { handle = handle, bladeLen = 0.4, setup = setup }
	end,
	-- short, black and pitted, a dull green tint along its edge (no glow)
	FoulDagger = function(w)
		local handle = w.mk("Grip", Vector3.new(0.22, 0.8, 0.22), Color3.fromRGB(30, 26, 22), Enum.Material.Fabric)
		w.add(w.mk("Guard", Vector3.new(0.8, 0.14, 0.26), Color3.fromRGB(46, 42, 38), Enum.Material.Metal), -0.45)
		w.add(w.mk("Blade", Vector3.new(0.26, 1.7, 0.08), Color3.fromRGB(34, 36, 30), Enum.Material.Slate), -1.35)
		w.add(w.mk("Edge", Vector3.new(0.05, 1.6, 0.1), Color3.fromRGB(62, 72, 44), Enum.Material.Metal), -1.35, CFrame.new(0.13, 0, 0))
		local tip = w.mk("Blade", Vector3.new(0.08, 0.35, 0.26), Color3.fromRGB(34, 36, 30), Enum.Material.Slate)
		tip.Shape = Enum.PartType.Wedge
		w.add(tip, -2.35, CFrame.fromMatrix(Vector3.zero, Vector3.zAxis, -Vector3.yAxis))
		return { handle = handle, bladeLen = 2.4 }
	end,
}
M.Grips = {
	-- the sword at rest (and on guard): two hands on it out in front of the belly, blade up
	-- and a little forward, turned on its own axis so the edge faces the enemy, not the flat
	SwordUp = { Vector3.new(0.3, -0.1, -1.3), CFrame.Angles(math.rad(155), 0, 0) * CFrame.Angles(0, math.rad(90), 0) },
	-- the Tachi at rest: two hands on it in front of the hip, blade rising 30 degrees forward
	-- of upright and leaning 8 degrees to the left
	TIdle = { Vector3.new(0.2, -0.2, -1.0), CFrame.Angles(0, 0, math.rad(8)) * CFrame.Angles(math.rad(150), 0, 0) },
	-- the Tachi sheathed for the draw: hand on the hilt at the left hip, blade back and down
	TSheathed = { Vector3.new(-0.5, -0.7, -0.7), CFrame.Angles(math.rad(-80), 0, 0) },
	-- the Old Book held open before your chest, its pages tipped up toward your face
	BRead = { Vector3.new(0.25, 0.75, -1.2), CFrame.Angles(math.rad(53), 0, 0) },
	-- casting: thrust out at arm's length, pages to the target
	BCast = { Vector3.new(0.4, 1.0, -2.0), CFrame.Angles(math.rad(-90), 0, 0) },
	-- the wand, held low at your side and angled ahead (no body pose of its own: you stand up straight), and drawn up
	-- and back over the shoulder before a cast
	WHold = { Vector3.new(1.0, -0.2, -0.9), CFrame.Angles(math.rad(-55), 0, 0) },
	WDraw = { Vector3.new(1.1, 1.3, 0.2), CFrame.Angles(math.rad(-150), 0, 0) },
}
M.BodyFor = { BRead = "Read" } -- reading: head bowed over it

---------------------------------------------------------------------------
-- server: your actions (the client predicts them; this is the authority)
---------------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local P, states, aliveChar, spend, setAction, cancelSwing, pose, bodyPose, setTrail, hitStopActor, playSound, SOUNDS, burst, damageEnemy, enemiesInSector, EnemiesFolder, now

local C = Config.Combat
local LATENCY = 0.12 -- the client predicts its own actions; give it this much slack

local function canStart(st, kind)
	local t = now()
	if kind == "Dodge" then
		return t >= st.dodgeAt - LATENCY
	end
	return t >= st.attackAt - LATENCY
end

-- which light attack in the chain comes next (server is the authority)
local function nextComboStep(st, kind, attacks)
	if kind ~= "Light" then
		return 1
	end
	if st.lastKind == "Light" and now() <= st.comboUntil then
		return st.lastStep % #attacks.Light + 1
	end
	return 1
end

local hitParams = OverlapParams.new()
hitParams.FilterType = Enum.RaycastFilterType.Include
hitParams.CollisionGroup = "HitQuery"

local function enemyModelOf(part)
	local m = part
	while m and m.Parent ~= EnemiesFolder do
		m = m.Parent
	end
	return m
end

local function bladeEnds(actor, weld) -- (weld: a dual-wielder's left sword's, else the main one)
	weld = weld or actor.weld
	local handle = weld and weld.Parent and weld.Part1
	if not handle or not handle.Parent then
		return nil
	end
	-- a scythe cuts from mid-haft out to its tip, not just along the blade
	local base = handle:FindFirstChild("HaftMid") or handle:FindFirstChild("BladeBase")
	local tip = handle:FindFirstChild("BladeTip")
	if not base or not tip then
		return nil
	end
	return base.WorldPosition, tip.WorldPosition
end

-- Hits land when the blade itself reaches the target: every frame of the swing
-- the blade's path since last frame is swept with small spheres along its length.
-- The weapon's Reach (Config.Weapons) stretches the swept blade outward from you (the
-- hit reaches this many times as far as the visible tip); the weapon itself looks the same.
local function runBladeSweep(player, st, a, id)
	local def = Config.weaponOf(player)
	local reach = a.Reach or def.Reach
	local _, _, me0 = aliveChar(player)
	local pathFrom = a.PathRadius and me0 and me0.Position -- (a dash's cut: the line you ran along)
	local damage = math.floor(a.Damage * Config.scaling(player, def) + 0.5) -- stats (def.Scaling)
	local hitSet = {}
	local hitCount = 0
	local t0 = now()
	local openAt, closeAt = a.Windup - 0.03, a.Windup + a.Swing + 0.05
	local prevBase, prevTip = {}, {}
	local usedFallback = false
	local conn

	local function land(m)
		if hitSet[m] then
			return
		end
		local h = m:FindFirstChildOfClass("Humanoid")
		if not h or h.Health <= 0 then
			return
		end
		hitSet[m] = true
		hitCount += 1
		damageEnemy(m, damage, player, a.Poise, a.HitStop)
		hitStopActor(st, a.HitStop, false)
		closeAt += a.HitStop or 0 -- the frozen blade gets that time back
	end

	conn = RunService.Heartbeat:Connect(function()
		local el = now() - t0
		if st.attackId ~= id or el > closeAt or not aliveChar(player) then
			conn:Disconnect()
			if Config.Debug then
				print(string.format("[Combat] %s %s hit %d enemy(s)%s", player.Name, a.Name or "attack", hitCount, usedFallback and " (fallback arc - no sword found)" or ""))
			end
			return
		end
		if el < openAt then
			return
		end
		local base, tip = bladeEnds(st)
		if not base then
			-- no sword (shouldn't happen): one simple arc check mid-swing
			if not usedFallback and el >= a.Windup + a.Swing * 0.5 then
				usedFallback = true
				local _, _, root = aliveChar(player)
				if root then
					for _, m in ipairs(enemiesInSector(root.CFrame, a.Range, a.HalfAngle)) do
						land(m)
					end
				end
			end
			return
		end
		local _, _, me = aliveChar(player)
		if me and pathFrom then
			for k = 0, 6 do
				for _, part in ipairs(workspace:GetPartBoundsInRadius(pathFrom:Lerp(me.Position, k / 6), a.PathRadius, hitParams)) do
					local m = enemyModelOf(part)
					if m then
						land(m)
					end
				end
			end
		end
		-- every blade you hold: the main one, and a dual-wielder's second
		for k, weld in ipairs(st.weld2 and { st.weld, st.weld2 } or { st.weld }) do
			local bs, ts = bladeEnds(st, weld)
			if bs then
				if me then
					ts = me.Position + (ts - me.Position) * reach
				end
				prevBase[k], prevTip[k] = prevBase[k] or bs, prevTip[k] or ts
				for i = 0, 3 do
					local f = i / 3
					local b, tp = prevBase[k]:Lerp(bs, f), prevTip[k]:Lerp(ts, f)
					for j = 0, 5 do
						local p = b:Lerp(tp, j / 5)
						for _, part in ipairs(workspace:GetPartBoundsInRadius(p, C.BladeRadius, hitParams)) do
							local m = enemyModelOf(part)
							if m then
								land(m)
							end
						end
					end
				end
				prevBase[k], prevTip[k] = bs, ts
			end
		end
	end)
end

local swing -- (below playerAttack)
local castFireball -- (below swing)
local castLaser -- (below castFireball)
local function playerAttack(player, kind, requestedStep, aim)
	local st = states[player]
	local attacks = Config.weaponOf(player).Attacks
	local list = attacks[kind]
	local char, _, hrp = aliveChar(player)
	if not (st and list and char) then
		return
	end
	if not canStart(st, "Attack") then
		return
	end
	local step = nextComboStep(st, kind, attacks)
	local a = list[math.min(step, #list)]
	if Config.Debug and requestedStep and requestedStep ~= step then
		print(string.format("[Combat] combo desync: client step %s, server step %d", tostring(requestedStep), step))
	end
	if not spend(st, a.Cost) then
		return
	end
	a.Name = a.Name or (kind .. step)
	local t = now()
	if a.Laser then
		st.laserStop, st.laserAim = false, aim and aim.Magnitude > 0.5 and aim.Unit or nil -- (castLaser, the client's hold)
	end
	st.healing = false
	st.lastKind, st.lastStep = kind, step
	if kind == "Running" then
		st.lastKind, st.lastStep = "Light", 2 -- a quick light after it comes out as the backhand
	end
	local total = a.Windup + a.Swing + a.Recover
	setAction(st, t, total, a.Windup + a.Swing + a.Recover * C.DodgeCancel, a.Windup + a.Swing + a.Recover * C.AttackCancel)
	st.comboUntil = t + total + C.ComboGrace
	st.attackId += 1
	local id = st.attackId

	swing(player, st, a, id, hrp, kind == "Heavy", aim)
end

-- one swing, from its windup: the blade's hits, and its poses back round to guard
function swing(player, st, a, id, hrp, heavy, aim)
	-- 1) GAMEPLAY: the swept-blade hit check (or, from a book, a fireball at the swing)
	if a.Fireball or a.Laser then
		task.delay(a.Windup, function()
			if st.attackId == id and aliveChar(player) then
				if a.Laser then
					castLaser(player, st, a, aim, id)
				else
					castFireball(player, st, a, aim)
				end
			end
		end)
	else
		runBladeSweep(player, st, a, id)
	end

	-- 2) VISUALS: windup -> swing -> follow-through -> back to guard
	local p1, p2, p3 = a.Poses[1], a.Poses[2], a.Poses[3]
	pose(st, p1, a.Windup)
	if a.Body then
		bodyPose(st, a.Body[1], a.Windup)
	end
	task.delay(a.Windup, function()
		if st.attackId ~= id or not aliveChar(player) then
			return
		end
		local def = Config.weaponOf(player)
		if not (a.Fireball or a.Laser) then -- (the books have their own sounds)
			playSound(hrp, def.SlashSound or (heavy and SOUNDS.Lunge or SOUNDS.Slash), 0.6, 0.9 + math.random() * 0.2)
			setTrail(st, true)
		end
		if def.Iai and not a.Draw then -- the Tachi's every cut crackles (the draw has its own)
			playSound(hrp, SOUNDS.Lightning[math.random(2, 3)], 0.7, 0.95 + math.random() * 0.1)
		end
		pose(st, p2, a.Swing * 0.45, Enum.EasingStyle.Linear)
		task.wait(a.Swing * 0.45)
		if st.attackId ~= id then
			return
		end
		pose(st, p3, a.Swing * 0.55)
		if a.Body then
			bodyPose(st, a.Body[2], a.Swing * 0.6)
		end
		task.wait(a.Swing * 0.55 + a.Recover * 0.3)
		if st.attackId ~= id then
			return
		end
		setTrail(st, false)
		pose(st, "Idle", a.Recover * 0.5)
	end)
end

-- a fireball (a.Fireball) from the book in your hand along aim (else straight ahead): flies
-- until it hits an enemy (damage x the weapon's Scaling), a wall, or runs out of Range
function castFireball(player, st, a, aim)
	local char, _, hrp = aliveChar(player)
	local F = a.Fireball
	local def = Config.weaponOf(player)
	local damage = math.floor(a.Damage * Config.scaling(player, def) + 0.5)
	local handle = st.weld and st.weld.Parent and st.weld.Part1
	local from = handle and handle.Position or hrp.Position + hrp.CFrame.LookVector * 2
	local dir = (aim and aim.Magnitude > 0.5) and aim.Unit or hrp.CFrame.LookVector
	-- a white-hot core inside a layered blaze, licking flames streaming off behind it,
	-- smoke and embers in its wake (Fire and emitters on an invisible carrier)
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.one * F.Size * 0.55
	ball.Material = Enum.Material.Neon
	ball.Color = Color3.fromRGB(255, 220, 140)
	ball.Transparency = 0.15
	ball.Anchored, ball.CanCollide, ball.CanQuery, ball.CanTouch = true, false, false, false
	ball.CFrame = CFrame.new(from)
	local function emitter(texture, colors, size, life, rate, speed, extra)
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = texture
		pe.Color = ColorSequence.new(colors)
		pe.Size = size
		pe.Lifetime = life
		pe.Rate = rate
		pe.Speed = speed
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.LockedToPart = false -- (so they trail behind it)
		for k, v in pairs(extra or {}) do
			pe[k] = v
		end
		pe.Parent = ball
	end
	local FIRE, SMOKE, SPARK = "rbxasset://textures/particles/fire_main.dds", "rbxasset://textures/particles/smoke_main.dds", "rbxasset://textures/particles/sparkles_main.dds"
	local sz = F.Size
	emitter(FIRE, { ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 170)), ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 140, 40)), ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 30, 10)) },
		NumberSequence.new({ NumberSequenceKeypoint.new(0, sz * 1.6), NumberSequenceKeypoint.new(1, sz * 0.4) }), NumberRange.new(0.15, 0.35), 90, NumberRange.new(0.5, 2),
		{ LightEmission = 0.9, Transparency = NumberSequence.new(0.1, 1), RotSpeed = NumberRange.new(-200, 200), Rotation = NumberRange.new(0, 360) })
	emitter(SMOKE, Color3.fromRGB(60, 44, 36), NumberSequence.new(sz * 0.8, sz * 2.2), NumberRange.new(0.4, 0.8), 25, NumberRange.new(0.5, 1.5),
		{ Transparency = NumberSequence.new(0.5, 1), RotSpeed = NumberRange.new(-60, 60) })
	emitter(SPARK, Color3.fromRGB(255, 190, 90), NumberSequence.new(0.15, 0), NumberRange.new(0.3, 0.7), 30, NumberRange.new(2, 6),
		{ LightEmission = 1, Acceleration = Vector3.new(0, -8, 0) })
	local fire = Instance.new("Fire")
	fire.Size, fire.Heat = sz * 3, 6
	fire.Color, fire.SecondaryColor = Color3.fromRGB(255, 120, 30), Color3.fromRGB(255, 220, 120)
	fire.Parent = ball
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness = Color3.fromRGB(255, 150, 60), 14, 2.5
	light.Parent = ball
	ball.Parent = workspace
	playSound(ball, SOUNDS.FireCast, 0.7, 0.9 + math.random() * 0.2)
	local wallParams = RaycastParams.new()
	wallParams.FilterDescendantsInstances = { char, EnemiesFolder, ball }
	wallParams.RespectCanCollide = true
	local pos, travelled, conn = from, 0, nil
	local function boom(at)
		conn:Disconnect()
		-- the carrier stops and goes dark while its flames and smoke burn out
		ball.Transparency = 1
		for _, d in ipairs(ball:GetChildren()) do
			if d:IsA("ParticleEmitter") or d:IsA("Fire") then
				d.Enabled = false
			end
		end
		light.Range = 18
		task.delay(0.15, light.Destroy, light)
		game:GetService("Debris"):AddItem(ball, 3)
		burst(at, Color3.fromRGB(255, 150, 50), 26, 0.45, 18)
		burst(at, Color3.fromRGB(255, 230, 150), 10, 0.25, 10)
		playSound(ball, SOUNDS.FireHit, 0.8, 0.9 + math.random() * 0.2)
	end
	conn = RunService.Heartbeat:Connect(function(dt)
		local step = math.min(F.Speed * dt, F.Range - travelled)
		local wall = workspace:Raycast(pos, dir * step, wallParams)
		local nextPos = wall and wall.Position or pos + dir * step
		-- swept in a few spheres so a fast ball can't skip over a thin enemy
		for i = 1, 3 do
			for _, part in ipairs(workspace:GetPartBoundsInRadius(pos:Lerp(nextPos, i / 3), F.Radius, hitParams)) do
				local m = enemyModelOf(part)
				local h = m and m:FindFirstChildOfClass("Humanoid")
				if h and h.Health > 0 then
					damageEnemy(m, damage, player, a.Poise, a.HitStop)
					boom(pos:Lerp(nextPos, i / 3))
					return
				end
			end
		end
		travelled += step
		pos = nextPos
		ball.CFrame = CFrame.new(pos)
		if wall or travelled >= F.Range then
			local burnable = wall and wall.Instance.Parent
			if burnable and burnable:GetAttribute("Burnable") then
				burnable:SetAttribute("Lit", true) -- (init.server burns it away: Map.Brushwood)
			end
			boom(pos)
		end
	end)
end

-- a dark beam (a.Laser) from the book in your hand along aim, for Duration s: every Tick it hurts each
-- enemy in it for Pct % of its MAX health (x the weapon's Scaling, so Darkness). Stops at the first wall;
-- a roll or a hit (which bump attackId) cuts it off.
local PURPLE, PURPLE_CORE = Color3.fromRGB(62, 20, 125), Color3.fromRGB(130, 80, 195)
local VIOLET, ABYSS = Color3.fromRGB(150, 40, 190), Color3.fromRGB(30, 14, 70) -- (the beam's colour drifts between these)
local SPARKLE, SMOKE_TEX = "rbxasset://textures/particles/sparkles_main.dds", "rbxasset://textures/particles/smoke_main.dds"
-- what keeps the beam from being a plain bar (made once a cast, moved every frame by laserFxStep): tendrils writhing
-- round it, a smoky sheath crawling along it, a sigil turning at the book (two rings, shards wheeling round them),
-- motes drifting off its whole length, and dark smoke and sparks pouring off the pages
local function laserFx(part, outer, L)
	local w = L.Width
	local fx = { tendrils = {}, shards = {}, rings = {} }
	local function ends()
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Parent, a1.Parent = outer, outer
		return a0, a1
	end
	for i = 1, 3 do -- (three, a third of a turn apart, each on its own pair of attachments so it can twist)
		local a0, a1 = ends()
		local b = Instance.new("Beam")
		b.Attachment0, b.Attachment1 = a0, a1
		b.Texture, b.TextureMode, b.TextureLength, b.TextureSpeed = SPARKLE, Enum.TextureMode.Wrap, 4, 2 + i
		b.Color = ColorSequence.new(PURPLE_CORE, VIOLET)
		b.LightEmission, b.LightInfluence, b.Segments, b.FaceCamera = 1, 0, 24, true
		b.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.7, 0.35), NumberSequenceKeypoint.new(1, 1) })
		b.Parent = outer
		fx.tendrils[i] = { a0 = a0, a1 = a1, beam = b }
	end
	local haze = Instance.new("Beam")
	fx.h0, fx.h1 = ends()
	haze.Attachment0, haze.Attachment1 = fx.h0, fx.h1
	haze.Texture, haze.TextureMode, haze.TextureLength, haze.TextureSpeed = SMOKE_TEX, Enum.TextureMode.Wrap, 6, -1.5
	haze.Color, haze.LightEmission, haze.LightInfluence, haze.FaceCamera = ColorSequence.new(ABYSS, PURPLE), 0.4, 0, true
	haze.Transparency = NumberSequence.new(0.55, 1)
	haze.Parent = outer
	fx.haze = haze
	for i = 1, 2 do
		fx.rings[i] = part(Enum.PartType.Cylinder, i == 1 and PURPLE_CORE or VIOLET, 0.25)
	end
	for i = 1, 6 do
		local s = part(Enum.PartType.Block, i % 2 == 0 and PURPLE_CORE or VIOLET, 0.1)
		s.Size = Vector3.new(0.08, 0.08, 0.45) * w
		fx.shards[i] = s
	end
	-- motes off the beam's whole length (its outer box is the emitter's volume)
	local motes = Instance.new("ParticleEmitter")
	motes.Texture, motes.Shape, motes.ShapeStyle = SPARKLE, Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume
	motes.Color = ColorSequence.new(PURPLE_CORE, VIOLET)
	motes.Size = NumberSequence.new(0.35 * w, 0)
	motes.Transparency = NumberSequence.new(0, 1)
	motes.Lifetime, motes.Speed, motes.SpreadAngle = NumberRange.new(0.35, 0.8), NumberRange.new(1, 4), Vector2.new(180, 180)
	motes.LightEmission, motes.Rate, motes.RotSpeed = 1, 60, NumberRange.new(-200, 200)
	motes.Parent = outer
	fx.motes = motes
	-- smoke and sparks off the pages, from the sigil's hub at the book
	local hub = part(Enum.PartType.Ball, PURPLE, 1)
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture, smoke.Color = SMOKE_TEX, ColorSequence.new(PURPLE, ABYSS)
	smoke.Size = NumberSequence.new(0.4 * w, 2 * w)
	smoke.Transparency = NumberSequence.new(0.4, 1)
	smoke.Lifetime, smoke.Speed, smoke.SpreadAngle = NumberRange.new(0.5, 1), NumberRange.new(1.5, 3), Vector2.new(60, 60)
	smoke.Rate, smoke.RotSpeed, smoke.Acceleration = 30, NumberRange.new(-60, 60), Vector3.new(0, 2, 0)
	smoke.Parent = hub
	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture, sparks.Color, sparks.LightEmission = SPARKLE, ColorSequence.new(PURPLE_CORE), 1
	sparks.Size = NumberSequence.new(0.25, 0)
	sparks.Lifetime, sparks.Speed, sparks.SpreadAngle, sparks.Rate = NumberRange.new(0.2, 0.45), NumberRange.new(6, 12), Vector2.new(70, 70), 40
	sparks.Parent = hub
	fx.emitters = { motes, smoke, sparks }
	fx.beams = { haze, fx.tendrils[1].beam, fx.tendrils[2].beam, fx.tendrils[3].beam }
	fx.parts = { hub, fx.rings[1], fx.rings[2], table.unpack(fx.shards) }
	fx.hub = hub
	return fx
end
-- one frame of it: o the book, tip where it burns, len between, t seconds since the cast
local function laserFxStep(fx, outer, core, flare, L, o, tip, len, t)
	local w = L.Width
	local pulse = 1 + 0.18 * math.sin(t * 14) + 0.08 * math.sin(t * 31)
	local shift = (math.sin(t * 2.6) + 1) / 2
	outer.Size = Vector3.new(w * pulse, w * pulse, len)
	core.Size = Vector3.new(w * 0.4 * (1 + 0.3 * math.sin(t * 22)), w * 0.4 * (1 + 0.3 * math.sin(t * 19 + 1)), len)
	outer.Color = PURPLE:Lerp(VIOLET, shift * 0.7):Lerp(ABYSS, (1 - shift) * 0.3)
	core.Color = PURPLE_CORE:Lerp(Color3.new(1, 1, 1), 0.15 + 0.15 * math.sin(t * 9))
	flare.Size = Vector3.one * w * (1.6 + 0.5 * math.sin(t * 11))
	-- (in the outer box's own space its +Z end is the book, -Z the tip)
	local curve = math.min(len * 0.1, 3.5) * w
	for i, td in ipairs(fx.tendrils) do
		local a = math.deg(t * (4 + i * 0.7)) + i * 120
		td.a0.Position, td.a1.Position = Vector3.new(0, 0, len / 2), Vector3.new(0, 0, -len / 2)
		td.a0.Orientation = Vector3.new(0, 0, a)
		td.a1.Orientation = Vector3.new(0, 0, a + 140 + 60 * math.sin(t * 3 + i))
		td.beam.CurveSize0 = curve * (0.6 + 0.4 * math.sin(t * 5 + i * 2))
		td.beam.CurveSize1 = -curve * (0.6 + 0.4 * math.cos(t * 4 + i))
		local tw = w * (0.35 + 0.15 * math.sin(t * 13 + i * 2))
		td.beam.Width0, td.beam.Width1 = tw * 1.4, tw * 0.5
	end
	fx.h0.Position, fx.h1.Position = Vector3.new(0, 0, len / 2), Vector3.new(0, 0, -len / 2)
	fx.haze.Width0, fx.haze.Width1 = w * (2.6 + 0.6 * math.sin(t * 6)), w * (1.4 + 0.4 * math.sin(t * 7 + 2))
	fx.motes.Rate = math.clamp(len * 2.5, 10, 150)
	-- the sigil at the book: two rings breathing out of step, shards wheeling round them, tumbling
	local face = CFrame.lookAt(o, tip)
	fx.hub.CFrame = face
	for i, r in ipairs(fx.rings) do
		local d = w * (i == 1 and 2.2 or 3.2) * (1 + 0.15 * math.sin(t * 6 + i * 2))
		r.Size = Vector3.new(0.06, d, d)
		r.Transparency = 0.2 + 0.3 * (math.sin(t * 8 + i * 3) + 1) / 2
		r.CFrame = face * CFrame.new(0, 0, -0.4 * i * w) * CFrame.Angles(0, math.pi / 2, 0) -- (a cylinder's axis is its X: turned down the beam)
	end
	local rad = w * (1.6 + 0.35 * math.sin(t * 4))
	for i, s in ipairs(fx.shards) do
		local a = t * (i % 2 == 0 and 5 or -4) + i / #fx.shards * math.pi * 2
		s.CFrame = face * CFrame.new(math.cos(a) * rad, math.sin(a) * rad, -0.6 * w + 0.2 * math.sin(t * 7 + i)) * CFrame.Angles(t * 6 + i, t * 4, a)
	end
end
function castLaser(player, st, a, aim, id)
	local char, _, hrp = aliveChar(player)
	local L = a.Laser
	local def = Config.weaponOf(player)
	local mult = Config.scaling(player, def)
	local dir = (aim and aim.Magnitude > 0.5) and aim.Unit or hrp.CFrame.LookVector
	local function part(shape, color, tr)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Material, p.Color, p.Transparency, p.Shape, p.Size = Enum.Material.Neon, color, tr, shape, Vector3.one
		p.Parent = workspace
		return p
	end
	local outer = part(Enum.PartType.Block, PURPLE, 0.2)
	local core = part(Enum.PartType.Block, PURPLE_CORE, 0.1)
	local flare = part(Enum.PartType.Ball, PURPLE, 0.3)
	flare.Size = Vector3.one * L.Width * 1.8
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness = PURPLE_CORE, 14, 2
	light.Parent = flare
	local fx = laserFx(part, outer, L)
	playSound(hrp, SOUNDS.FireCast, 0.7, 0.6)
	local wallParams = RaycastParams.new()
	wallParams.FilterDescendantsInstances = { char, EnemiesFolder, outer, core, flare }
	wallParams.RespectCanCollide = true
	local nextTick, t0, lastBurst = now(), now(), 0
	local conn
	local function stop()
		conn:Disconnect()
		if L.Hold and now() - t0 > L.Duration and st.attackId == id then -- (a held beam: a brief recovery)
			st.busyUntil, st.attackAt = now() + 0.3, now() + 0.25
			pose(st, "Idle", 0.2)
		end
		for _, e in ipairs(fx.emitters) do
			e.Enabled = false
		end
		for _, bm in ipairs(fx.beams) do
			bm.Enabled = false
		end
		for _, p in ipairs({ outer, core, flare, table.unpack(fx.parts) }) do
			game:GetService("TweenService"):Create(p, TweenInfo.new(0.12), { Transparency = 1 }):Play()
			Debris:AddItem(p, 0.2)
		end
	end
	conn = RunService.Heartbeat:Connect(function(dt)
		local t = now()
		local held = L.Hold and not st.laserStop and st.stamina > 0
		if st.attackId ~= id or (t - t0 > L.Duration and not held) or not aliveChar(player) then
			stop()
			return
		end
		local dir = (L.Hold and st.laserAim) or dir
		if L.Hold and t - t0 > L.Duration then -- held past the tap: it costs stamina, and you stay busy
			st.stamina = math.max(0, st.stamina - L.Drain * dt)
			st.lastSpend = t
			st.busyUntil, st.attackAt = math.max(st.busyUntil, t + 0.1), math.max(st.attackAt, t + 0.1)
		end
		local handle = st.weld and st.weld.Parent and st.weld.Part1
		local o = handle and handle.Position or hrp.Position + hrp.CFrame.LookVector * 2
		local wall = workspace:Raycast(o, dir * L.Range, wallParams)
		local len = wall and wall.Distance or L.Range
		local tip = o + dir * len
		local cf = CFrame.lookAt(o + dir * len / 2, tip)
		outer.CFrame, core.CFrame, flare.CFrame = cf, cf, CFrame.new(tip)
		laserFxStep(fx, outer, core, flare, L, o, tip, len, t - t0)
		if t - lastBurst > 0.2 then -- (sparks where it burns)
			lastBurst = t
			burst(tip, PURPLE, 6, 0.3, 8)
		end
		if t >= nextTick then
			nextTick = t + Config.DarkBookTick
			local hitThisTick = {}
			for _, p in ipairs(workspace:GetPartBoundsInBox(cf, Vector3.new(L.Width + 0.5, L.Width + 0.5, len), hitParams)) do
				local m = enemyModelOf(p)
				local h = m and m:FindFirstChildOfClass("Humanoid")
				if h and h.Health > 0 and not hitThisTick[m] then
					hitThisTick[m] = true -- (once a tick, however many of its parts are in the beam)
					damageEnemy(m, h.MaxHealth * L.Pct / 100 * mult, player, L.Poise, 0)
				end
			end
		end
	end)
end

local function playerRoll(player, back)
	local st = states[player]
	if not st or not aliveChar(player) then
		return
	end
	if not canStart(st, "Dodge") or player:GetAttribute("Broken") then -- (BROKEN: no rolling, Config.Break)
		return
	end
	if not spend(st, back and P.BackstepCost or P.RollCost) then
		return
	end
	local t = now()
	st.healing = false
	st.lastKind = nil -- a roll breaks the light chain
	cancelSwing(st)
	local dur = back and P.BackstepDuration or P.RollDuration
	-- the client rolled LATENCY ago by the time this arrives: start the window where the player saw it
	if t >= (st.phaseUntil or 0) then -- (a roll mustn't cut a Foul Dagger phase short)
		st.iStart = t + P.IFrameStart - LATENCY
		st.iEnd = t + (back and P.BackstepIFrameEnd or P.IFrameEnd) - LATENCY
	end
	setAction(st, t, dur - 0.03, dur * 0.8, dur * 0.8)
end

-- THE FOUL DAGGER'S Q (Config.FoulPhase): for Duration s you're half-transparent, armor and weapon
-- too, and nothing can hurt you (the same i-frames a roll gives: Core.damagePlayer). It doesn't stop
-- you acting. The cooldown counts from the press.
local function playerPhase(player)
	local st = states[player]
	local char, _, hrp = aliveChar(player)
	local D = Config.FoulPhase
	local t = now()
	if not (st and char) or not canStart(st, "Dodge") or t < (st.phaseReadyAt or 0) - LATENCY then
		return
	end
	st.phaseReadyAt = t + D.Cooldown
	st.phaseUntil = t + D.Duration
	st.iStart, st.iEnd = t, t + D.Duration
	local was = {}
	for _, d in ipairs(char:GetDescendants()) do
		if (d:IsA("BasePart") or d:IsA("Decal")) and d.Transparency < 0.5 then
			was[d] = d.Transparency
			d.Transparency = 0.5
		end
	end
	local GREEN = Color3.fromRGB(150, 190, 70)
	local glow = Instance.new("Highlight")
	glow.Adornee, glow.FillColor, glow.FillTransparency = char, GREEN, 0.75
	glow.OutlineColor, glow.OutlineTransparency, glow.DepthMode = GREEN, 0.2, Enum.HighlightDepthMode.Occluded
	glow.Parent = char
	local rot = Instance.new("ParticleEmitter")
	rot.Texture = "rbxasset://textures/particles/smoke_main.dds"
	rot.Color = ColorSequence.new(Color3.fromRGB(110, 150, 50), Color3.fromRGB(40, 60, 20))
	rot.LightEmission = 0.4
	rot.Size = NumberSequence.new(1.2, 2.4)
	rot.Transparency = NumberSequence.new(0.5, 1)
	rot.Lifetime = NumberRange.new(0.6, 1.1)
	rot.Rate = 30
	rot.Speed = NumberRange.new(1, 3)
	rot.Acceleration = Vector3.new(0, 4, 0)
	rot.SpreadAngle = Vector2.new(180, 180)
	rot.Parent = hrp
	burst(hrp.Position, GREEN, 20, 0.4, 14)
	playSound(hrp, SOUNDS.Unsheath, 0.7, 0.5)
	task.delay(D.Duration, function()
		for d, v in pairs(was) do
			if d.Parent then
				d.Transparency = v
			end
		end
		glow:Destroy()
		rot:Destroy()
		if hrp.Parent then
			burst(hrp.Position, GREEN, 20, 0.4, 14)
			playSound(hrp, SOUNDS.Deflect, 0.5, 0.6)
		end
	end)
end

local function playerDeflect(player)
	local st = states[player]
	if not st or not aliveChar(player) then
		return
	end
	if player:GetAttribute("Weapon") ~= "Scythe" then
		return
	end
	if not canStart(st, "Dodge") then
		if Config.Debug then
			print(string.format("[Deflect] refused: still busy for %.2fs", st.dodgeAt - LATENCY - now()))
		end
		return
	end
	local CFG = Config.ScytheDeflect
	if not spend(st, CFG.Cost) then
		if Config.Debug then
			print("[Deflect] refused: no stamina")
		end
		return
	end
	local t = now()
	st.healing = false
	st.lastKind = nil
	cancelSwing(st)
	local dur = CFG.Duration
	local win = CFG.Window
	local twirl = CFG.Twirl
	-- the deflect frames only open once the twirl clicks into guard
	st.deflectStart = t + twirl - LATENCY
	st.deflectEnd = t + twirl + win
	setAction(st, t, twirl + dur, twirl + dur * 0.7, twirl + dur * 0.75)
	local id = st.attackId -- (cancelSwing above bumped it; a hit mid-twirl bumps it again)
	task.spawn(function()
		-- snap up overhead, then one full turn in quarters
		local snap = twirl * 0.2
		local quarter = (twirl - snap) / 4
		pose(st, "UTwirlA", snap)
		task.wait(snap)
		for _, g in ipairs({ "UTwirlB", "UTwirlC", "UTwirlD", "UTwirlA" }) do
			if st.attackId ~= id then
				return
			end
			pose(st, g, quarter, Enum.EasingStyle.Linear)
			task.wait(quarter)
		end
		if st.attackId ~= id then
			return
		end
		pose(st, "UDeflect", 0.04, Enum.EasingStyle.Back) -- the click into guard
		task.wait(dur * 0.65)
		if st.attackId == id and (st.deflectEnd or 0) > 0 and now() >= st.deflectEnd then
			pose(st, "Idle", 0.2)
		end
	end)
end

-- THE DRAW (Gozen Tachi, Q; Config.TachiDraw). Standing still: sheathe it and settle.
-- Settled ("IaiReady"): Q draws it in one cut, invulnerable for its first few frames
-- (dash = W was held: the client runs you forward, and the cut is the wide DashAttack).
-- A draw a touch early (the client queued it) still counts. Anything else you do, walking
-- off (the client's "IaiCancel", from CancelAfter on), or a hit - each bumps attackId -
-- breaks the stance.
local function playerIai(player, dash)
	local st = states[player]
	local char, _, hrp = aliveChar(player)
	if not (st and char) or not Config.weaponOf(player).Iai then
		return
	end
	local D = Config.TachiDraw
	local t = now()
	if st.iaiId == st.attackId and t >= st.iaiReadyAt - LATENCY then
		if not spend(st, D.Cost) then
			return
		end
		st.iaiId = nil
		player:SetAttribute("IaiReady", false)
		local a = dash and D.DashAttack or D.Attack
		st.healing = false
		st.lastKind = nil
		st.iStart, st.iEnd = t, t + D.IFrames
		local total = a.Windup + a.Swing + a.Recover
		setAction(st, t, total, a.Windup + a.Swing + a.Recover * C.DodgeCancel, a.Windup + a.Swing + a.Recover * C.AttackCancel)
		st.attackId += 1
		-- you vanish for exactly the i-frames, then come back in a lightning strike as the
		-- cut lands (its Windup is the i-frames, Config.TachiDraw)
		local hidden = {}
		for _, d in ipairs(char:GetDescendants()) do
			if (d:IsA("BasePart") or d:IsA("Decal")) and d.Transparency < 1 then
				hidden[d] = d.Transparency
				d.Transparency = 1
			elseif d:IsA("ParticleEmitter") and d.Enabled then
				hidden[d] = true
				d.Enabled = false
			end
		end
		burst(hrp.Position, Color3.fromRGB(170, 215, 255), 14, 0.3, 10)
		task.delay(D.IFrames, function()
			for d, v in pairs(hidden) do
				if d.Parent then
					if v == true then
						d.Enabled = true
					else
						d.Transparency = v
					end
				end
			end
			if not hrp.Parent then
				return
			end
			local at = hrp.Position
			lightningArc(at + Vector3.new(math.random() * 2 - 1, 14, math.random() * 2 - 1), at, 6, 0.18, 1.6)
			for _ = 1, 4 do
				local off = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 5
				lightningArc(at, at + off, 3, 0.07, 0.6)
			end
			burst(at, Color3.fromRGB(190, 225, 255), 24, 0.35, 16)
			playSound(hrp, SOUNDS.Lightning[1], 1, 1)
		end)
		swing(player, st, a, st.attackId, hrp, true)
		return
	end
	if not canStart(st, "Attack") then
		return
	end
	st.healing = false
	st.lastKind = nil
	cancelSwing(st)
	local id = st.attackId
	st.iaiId, st.iaiReadyAt = id, t + D.SheatheTime
	setAction(st, t, D.SheatheTime, 0, D.SheatheTime)
	pose(st, "TSheathed", D.SheatheTime * 0.6)
	bodyPose(st, "Iai", D.SheatheTime)
	playSound(hrp, SOUNDS.Unsheath, 0.6, 0.8)
	task.spawn(function()
		while st.attackId == id and aliveChar(player) == char do
			if not player:GetAttribute("IaiReady") and now() >= t + D.SheatheTime then
				player:SetAttribute("IaiReady", true) -- settled: the blade clicks home
				playSound(hrp, SOUNDS.Deflect, 0.4, 1.6)
			end
			RunService.Heartbeat:Wait()
		end
		player:SetAttribute("IaiReady", false) -- (the draw has already cleared it)
	end)
end

-- CAELEN'S SPIN (the twin blades, Q; Config.CaelenSpin): both swords flung out, you spin with
-- them for Duration seconds and steer by walking as normal (the client turns you round; this
-- is the damage, every Tick, to everything within Radius). A roll (or a hit) ends it.
local function playerSpin(player)
	local st = states[player]
	local char, _, hrp = aliveChar(player)
	if not (st and char) or not Config.weaponOf(player).Spin or not canStart(st, "Attack") then
		return
	end
	local D = Config.CaelenSpin
	if now() < (st.spinReadyAt or 0) - LATENCY or not spend(st, D.Cost) then
		return
	end
	local t = now()
	st.spinReadyAt = t + D.Duration + D.Cooldown -- (Cooldown counts from when the spin ends)
	st.healing = false
	st.lastKind = nil
	cancelSwing(st)
	setAction(st, t, D.Duration, D.Duration * 0.3, D.Duration)
	local id = st.attackId
	pose(st, "GWhirl", 0.15)
	bodyPose(st, "CWhirl", 0.15)
	setTrail(st, true)
	playSound(hrp, SOUNDS.Slash, 0.8, 0.5)
	task.spawn(function()
		local def = Config.weaponOf(player)
		local damage = math.floor(D.Damage * Config.scaling(player, def) + 0.5)
		local el = 0
		while el < D.Duration and st.attackId == id and aliveChar(player) == char do
			task.wait(D.Tick)
			el += D.Tick
			if st.attackId ~= id then
				break
			end
			playSound(hrp, def.SlashSound or SOUNDS.Slash, 0.5, 0.8 + math.random() * 0.2)
			for _, m in ipairs(enemiesInSector(hrp.CFrame, D.Radius, 180)) do
				local h = m:FindFirstChildOfClass("Humanoid")
				if h and h.Health > 0 then
					damageEnemy(m, damage, player, D.Poise, 0)
				end
			end
		end
		setTrail(st, false)
		if st.attackId == id then
			pose(st, "Idle", 0.3)
		end
	end)
end

local function playerHeal(player)
	local st = states[player]
	local char, _, hrp = aliveChar(player)
	if not (st and char) then
		return
	end
	if not canStart(st, "Attack") or st.flasks <= 0 then
		return
	end
	local t = now()
	st.flasks -= 1
	player:SetAttribute("Flasks", st.flasks)
	st.lastKind = nil
	cancelSwing(st)
	setAction(st, t, P.FlaskTime, P.FlaskTime, P.FlaskTime)
	st.healing = true
	pose(st, "Drink", 0.3)
	local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 160, 70)
	glow.Range = 8
	glow.Brightness = 2
	glow.Parent = hand or hrp
	Debris:AddItem(glow, P.FlaskTime)
	task.delay(P.FlaskTime * 0.45, function()
		local c, h, root = aliveChar(player)
		if st.healing and c then
			h.Health = math.min(h.MaxHealth, h.Health + P.FlaskHeal)
			burst(root.Position, Color3.fromRGB(255, 160, 70), 18, 0.3, 6)
		end
		st.healing = false
		task.wait(P.FlaskTime * 0.3)
		pose(st, "Idle", 0.3)
	end)
end

function M.init(core)
	P, states, aliveChar, spend, setAction, cancelSwing, pose, bodyPose, setTrail, hitStopActor, playSound, SOUNDS, burst, damageEnemy, enemiesInSector, EnemiesFolder, now = core.P, core.states, core.aliveChar, core.spend, core.setAction, core.cancelSwing, core.pose, core.bodyPose, core.setTrail, core.hitStopActor, core.playSound, core.SOUNDS, core.burst, core.damageEnemy, core.enemiesInSector, core.EnemiesFolder, core.now
	hitParams.FilterDescendantsInstances = { EnemiesFolder }
end

M.attack = function(player, kind, step, aim)
	playerAttack(player, kind, step, aim)
end
M.roll = function(player, back)
	playerRoll(player, back)
end
M.deflect = function(player)
	if Config.weaponOf(player).Phase then
		return playerPhase(player)
	end
	playerDeflect(player)
end
M.iai = function(player, dash)
	playerIai(player, dash)
end
M.iaiCancel = function(player)
	local st = states[player]
	if st and st.iaiId and st.iaiId == st.attackId then
		st.iaiId = nil
		cancelSwing(st) -- (stands up; the stance's loop sees the bump and clears IaiReady)
	end
end
M.spin = function(player)
	playerSpin(player)
end
M.heal = function(player)
	playerHeal(player)
end

return M
