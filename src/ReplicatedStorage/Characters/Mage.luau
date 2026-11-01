--!nonstrict
-- MAGE (kind Mage): a dark-robed spellcaster of the Highlands' mushroom forest, in a tall
-- cone hat and a cone of purple robes down to the moss. Tanky, but it doesn't hit hard:
-- it throws slow dark bolts from range, and when you get close (or hurt it) it blinks
-- away in a poof of violet smoke, on an 8 second cooldown.
--
-- EVERYTHING ABOUT THIS CHARACTER IS IN THIS ONE FILE:
--   M.Proportions / M.Colors / M.Look   body shape and how the rig is dressed
--   M.Weapons                            the staff
--   M.Def / M.attack / M.onStagger       stats and behaviour (the shared brain in GameServer/Enemies.lua)
local Players = game:GetService("Players")

local M = {}
M.Kind = "Mage"
M.Proportions = { girth = 0.82, arm = 1.0, hunch = 0.12 }
local ROBE, ROBE_DARK, TRIM, GLOW = Color3.fromRGB(46, 24, 64), Color3.fromRGB(28, 14, 40), Color3.fromRGB(96, 56, 132), Color3.fromRGB(190, 110, 255)
M.Colors = { skin = ROBE_DARK, torso = ROBE, legs = ROBE_DARK, arms = ROBE }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.la, k.ua
	local up = CFrame.Angles(0, 0, math.pi / 2) -- (a cylinder's axis is X: stand it on end)
	local cyl = Enum.PartType.Cylinder
	-- the cone hat: stacked discs narrowing to a tip, over a wide brim
	parts.Head.Color = ROBE_DARK
	deco("Head", "Brim", V(0.1, 2.3, 2.3), at(0, 0.5, 0) * up, ROBE_DARK, MAT.Fabric, cyl)
	for i = 0, 7 do
		deco("Head", "Cone", V(0.44, 1.9 - i * 0.24, 1.9 - i * 0.24), at(0, 0.7 + i * 0.4, 0) * up, i % 3 == 0 and TRIM or ROBE, MAT.Fabric, cyl)
	end
	-- a face lost in the hood's shadow, two violet points in it
	deco("Head", "Shade", V(1.0, 0.9, 0.1), at(0, -0.02, -0.6), rgb(5, 3, 9), MAT.SmoothPlastic)
	for _, x in ipairs({ -0.2, 0.2 }) do
		deco("Head", "Eye", V(0.12, 0.07, 0.05), at(x, 0.08, -0.67), GLOW, MAT.Neon)
	end
	-- the robe: a heavy mantle, a belt, a skirt flaring in rings to the ground (a cone)
	deco("Chest", "Robe", V(cw * 1.12, ch * 1.05, cd * 1.2), at(0, 0, 0), ROBE, MAT.Fabric)
	deco("Chest", "Mantle", V(cw * 1.45, 0.55, cd * 1.6), at(0, ch / 2 - 0.1, 0), TRIM, MAT.Fabric)
	deco("Hips", "Sash", V(hw + 0.12, 0.2, hd + 0.12), at(0, 0.3, 0), TRIM, MAT.Fabric)
	for i = 0, 5 do
		deco("Hips", "Skirt", V(0.55, hw * 1.25 + i * 0.42, hw * 1.25 + i * 0.42), at(0, 0.1 - i * 0.5, 0) * up, i == 5 and TRIM or ROBE, MAT.Fabric, cyl)
	end
	-- wide sleeves, a glowing rune on the chest
	for _, n in ipairs({ "R", "L" }) do
		deco(n .. "UpperArm", "Sleeve", V(aw * 1.5, ua * 0.95, aw * 1.5), at(0, 0, 0), ROBE, MAT.Fabric)
		deco(n .. "LowerArm", "Cuff", V(aw * 1.9, la * 0.8, aw * 1.9), at(0, 0.1, 0), ROBE, MAT.Fabric)
		parts[n .. "Foot"].Color = ROBE_DARK
	end
	deco("Chest", "Rune", V(0.34, 0.34, 0.04), at(0, 0.15, -cd * 0.6 - 0.02) * CFrame.Angles(0, 0, math.pi / 4), GLOW, MAT.Neon)
end

M.Weapons = {
	Staff = function(w)
		local handle = w.mk("Grip", Vector3.new(0.2, 1.2, 0.2), w.wood, Enum.Material.Wood)
		w.add(w.mk("Shaft", Vector3.new(0.17, 3.6, 0.17), w.wood, Enum.Material.Wood), -2.2)
		local orb = w.mk("Orb", Vector3.new(0.9, 0.9, 0.9), GLOW, Enum.Material.Neon)
		orb.Shape = Enum.PartType.Ball
		w.add(orb, -4.3)
		return { handle = handle, bladeLen = 4.5 }
	end,
}

-- stats (the shared brain in GameServer/Enemies.lua reads these). Engage: it casts from range.
M.Def = {
	HP = 260, Speed = 12, Scale = 1.1, Damage = 11, Range = 26, Engage = 28, HalfAngle = 60,
	Windup = 0.9, Recover = 0.5, Aggro = 46, Leash = 70, Stagger = 0.3,
	HyperArmor = false, Weapon = "Staff", Radius = 1.2, Lunge = 0,
	Poise = 70, HitLevel = "Small", -- (shrugs off most hits; the bolt barely hurts)
	Skin = ROBE_DARK, Cloth = ROBE,
	BlinkCooldown = 8, BoltSpeed = 38,
}

---------------------------------------------------------------------------
-- server: how it fights
---------------------------------------------------------------------------
local pose, playSound, SOUNDS, now, faceTowards, flat, playersInRadius, damagePlayer, burst, dustCloud, EnemiesFolder, Map

-- the mushroom huts are no place for a mage (Map.Huts: { x, z, radius })
local function inHut(p)
	for _, h in ipairs(Map.Huts or {}) do
		if (p.X - h[1]) ^ 2 + (p.Z - h[2]) ^ 2 < h[3] ^ 2 then
			return true
		end
	end
	return false
end

local rnd = Random.new()

-- vanish in a poof and reappear 16-24 studs from the target, on ground like the ground it left
local function blink(e, tRoot)
	local root = e.root
	local ex = { EnemiesFolder }
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl.Character then
			table.insert(ex, pl.Character)
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ex
	params.RespectCanCollide = true
	local floorY = root.Position.Y - 3 * e.scale
	for _ = 1, 14 do
		local a, d = rnd:NextNumber(0, math.pi * 2), rnd:NextNumber(16, 24)
		local c = tRoot.Position + Vector3.new(math.cos(a), 0, math.sin(a)) * d
		if flat(c - e.home.Position).Magnitude < 45 and not inHut(c) then
			local hit = workspace:Raycast(Vector3.new(c.X, floorY + 8, c.Z), Vector3.new(0, -16, 0), params)
			if hit and hit.Normal.Y > 0.8 and math.abs(hit.Position.Y - floorY) < 4 then
				burst(root.Position + Vector3.new(0, 2, 0), Color3.fromRGB(120, 60, 170), 50, 1.1, 18)
				dustCloud(root.Position, 7, 14)
				e.model:PivotTo(CFrame.lookAt(hit.Position + Vector3.new(0, 3 * e.scale + 0.2, 0), Vector3.new(tRoot.Position.X, hit.Position.Y + 3 * e.scale + 0.2, tRoot.Position.Z)))
				root.AssemblyLinearVelocity = Vector3.zero
				burst(root.Position + Vector3.new(0, 2, 0), Color3.fromRGB(120, 60, 170), 50, 1.1, 18)
				dustCloud(root.Position, 7, 14)
				e.blinkReady = now() + e.def.BlinkCooldown
				return true
			end
		end
	end
	return false
end

-- a slow dark bolt: flies straight at where you were, hurts the first player it touches
local function bolt(e, from, dir)
	local def = e.def
	local orb = Instance.new("Part")
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(1.7, 1.7, 1.7)
	orb.Material = Enum.Material.Neon
	orb.Color = GLOW
	orb.Anchored, orb.CanCollide, orb.CanQuery, orb.CanTouch = true, false, false, false
	orb.Position = from
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness = GLOW, 12, 2
	light.Parent = orb
	orb.Parent = workspace
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { e.model, EnemiesFolder }
	params.RespectCanCollide = true
	task.spawn(function()
		local pos, last, left = from, now(), 3
		while left > 0 and orb.Parent do
			task.wait()
			local t = now()
			local step = dir * def.BoltSpeed * (t - last)
			left -= t - last
			last = t
			local wall = workspace:Raycast(pos, step, params)
			local nextPos = wall and wall.Position or pos + step
			local struck
			for _, pl in ipairs(playersInRadius(nextPos, 2.4, 4)) do
				damagePlayer(pl, def.Damage, pos, def.HitLevel)
				struck = true
			end
			pos = nextPos
			orb.Position = pos
			if wall or struck then
				burst(pos, GLOW, 22, 0.6, 14)
				break
			end
		end
		orb:Destroy()
	end)
end

function M.attack(e, targetChar)
	local def = e.def
	local hum, root = e.hum, e.root
	local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
	if not tRoot then
		return
	end
	local t = now()
	local hurt = hum.Health < (e.lastHP or hum.MaxHealth)
	e.lastHP = hum.Health
	local ready = t >= (e.blinkReady or 0)
	-- too close, or just hurt: it isn't staying
	if ready and (hurt or flat(tRoot.Position - root.Position).Magnitude < 10) and blink(e, tRoot) then
		e.attacking = true
		task.wait(0.35)
		e.attacking = false
		return
	end

	e.attacking = true
	hum:MoveTo(root.Position)
	hum.AutoRotate = false
	pose(e, "Raise", def.Windup * 0.8)
	local orb = Instance.new("Part") -- the spell gathering over its head
	orb.Shape = Enum.PartType.Ball
	orb.Material, orb.Color, orb.Transparency = Enum.Material.Neon, GLOW, 0.2
	orb.Anchored, orb.CanCollide, orb.CanQuery, orb.CanTouch = true, false, false, false
	orb.Parent = workspace
	local t0, interrupted = now(), false
	while now() - t0 < def.Windup do
		if not e.alive or now() < e.staggerUntil then
			interrupted = true
			break
		end
		if tRoot.Parent then
			faceTowards(root, tRoot.Position)
		end
		local g = (now() - t0) / def.Windup
		orb.Size = Vector3.one * (0.4 + 1.4 * g)
		orb.Position = root.Position + Vector3.new(0, 4.2 * e.scale, 0) + root.CFrame.LookVector * 1.6
		task.wait()
	end
	orb:Destroy()

	if not interrupted and e.alive then
		pose(e, "Strike", 0.08)
		local from = root.Position + Vector3.new(0, 3.2 * e.scale, 0) + root.CFrame.LookVector * 1.8
		bolt(e, from, (tRoot.Position + Vector3.new(0, 1, 0) - from).Unit)
		local r0 = now()
		while now() - r0 < def.Recover and e.alive do
			task.wait()
		end
		if e.alive and now() >= (e.blinkReady or 0) and rnd:NextNumber() < 0.5 then
			blink(e, tRoot) -- cast and gone
		end
	end
	if e.alive then
		pose(e, "Idle", 0.3)
	end
	hum.AutoRotate = true
	e.attacking = false
end

-- knocked off balance: vanish before it can be followed up
function M.onStagger(e)
	if now() < (e.blinkReady or 0) then
		return
	end
	task.delay(0.15, function()
		local best, bestD
		for _, pl in ipairs(Players:GetPlayers()) do
			local r = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
			if r and e.root.Parent then
				local d = (r.Position - e.root.Position).Magnitude
				if not bestD or d < bestD then
					best, bestD = r, d
				end
			end
		end
		if best and e.alive then
			blink(e, best)
		end
	end)
end

function M.init(core)
	pose, playSound, SOUNDS, now, faceTowards, flat, playersInRadius, damagePlayer, burst, dustCloud, EnemiesFolder = core.pose, core.playSound, core.SOUNDS, core.now, core.faceTowards, core.flat, core.playersInRadius, core.damagePlayer, core.burst, core.dustCloud, core.EnemiesFolder
	Map = core.Map
end

return M
