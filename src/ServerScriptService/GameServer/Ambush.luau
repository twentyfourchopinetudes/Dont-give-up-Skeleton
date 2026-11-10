--!nonstrict
-- AMBUSHES AND TRAPS: four of them, at points everyone passes (SITES, below). Each is told beforehand by something
-- that's there to be seen - heaps of bones along a wall, coals still glowing in a road, loose stone overhead, iron
-- grates in a floor - and each is sprung by walking into it:
--   rise      the heaps pull themselves together behind you (or figures step up out of the coals' fire): enemies of
--             its kind, up out of the floor after a heave of it, already after you
--   rockfall  stone comes down off the wall over a narrow walk, piece after piece, each where you're headed: dust
--             trickles and a shadow spreads first
--   vents     grates in the floor light, one after another down the line, and then burn
-- An ambush's dead are the shared brain's (Enemies.spawn): gone, and the ambush set again, whenever the world's
-- enemies come back (a rest, a death). The rockfall is once a life too; the vents never stop.
--   M.init(Core, Enemies): once the whole map's built
-- Every spot is checked against the map as built (a floor under it, at about its height, nothing between it and the
-- site): one that isn't there is left out, and a site with none left does nothing.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local M = {}
local V3, C3 = Vector3.new, Color3.fromRGB
local MAT = Enum.Material

function M.init(Core, Enemies)
	local Map, FxRemote = Core.Map, Core.FxRemote
	local SITES = {
		-- the Prison Ramparts' first tier: as you go out along it at its dead, more of them get up at the head of it, behind you
		{ id = "Rampart", kind = "rise", trigger = V3(70, 20.2, 319), radius = 6, from = V3(80, 20.2, 314), enemy = "Skeleton", count = 3 },
		-- the Yard Walk, the narrow walk south from it along the Ashen Yard's wall, under the keep
		{ id = "YardWalk", kind = "rockfall", trigger = V3(46.5, 30.2, 168), radius = 6 },
		-- the Palace of Pyralis: out of its gatehouse's hall and across the forecourt
		{ id = "PalaceGate", kind = "vents", trigger = V3(444, 100.2, 242), radius = 6, dir = V3(1, 0, 0), count = 5, gap = 6 },
	}
	local B = Map.Bulwark and Map.Bulwark.Dev
	if B then -- Pyralis Bulwark, where its road comes in: twelve on along it, and they're up out of the coals round where you came in
		local at = B.Position - V3(0, 3, 0)
		table.insert(SITES, { id = "Bulwark", kind = "rise", trigger = at + B.LookVector * 14, radius = 6, from = at, enemy = "Stoker", count = 2, fire = true })
	end

	local folder = Instance.new("Folder")
	folder.Name = "Ambush"
	folder.Parent = workspace
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local function refilter()
		local list = { Core.EnemiesFolder, folder }
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl.Character then
				table.insert(list, pl.Character)
			end
		end
		params.FilterDescendantsInstances = list
	end
	local function floorAt(p) -- the floor under p, if there's one within a few studs of its height
		local hit = workspace:Raycast(p + V3(0, 4, 0), V3(0, -8, 0), params)
		return hit and hit.Normal.Y > 0.8 and hit.Position or nil
	end
	local function open(a, to) -- (nothing standing between two spots: chest high)
		return workspace:Raycast(a + V3(0, 3, 0), to - a, params) == nil
	end
	local function spotsRound(c, n) -- up to n spots of floor round c, spread about it
		local found = {}
		for i = 0, 15 do
			local a = i / 16 * math.pi * 2
			local p = floorAt(c + V3(math.cos(a), 0, math.sin(a)) * (i % 2 == 0 and 5 or 3))
			if p and math.abs(p.Y - c.Y) < 2 and open(c, p) then
				table.insert(found, p)
			end
		end
		local out = {}
		n = math.min(n, #found)
		for i = 1, n do
			out[i] = found[math.floor((i - 0.5) / n * #found) + 1]
		end
		return out
	end
	local function piece(props, cf)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		for k, v in pairs(props) do
			p[k] = v
		end
		p.CFrame = cf
		p.Parent = folder
		return p
	end
	local function rand(a, b)
		return a + math.random() * (b - a)
	end
	local function everyone(c, radius) -- players alive within radius of c (and about its height)
		local out = {}
		for _, pl in ipairs(Players:GetPlayers()) do
			local char, _, hrp = Core.aliveChar(pl)
			if char and math.abs(hrp.Position.Y - 3 - c.Y) < 6 and Core.flat(hrp.Position - c).Magnitude < radius then
				table.insert(out, pl)
			end
		end
		return out
	end

	-- THE TELLS, there beforehand. A heap of bones; a bed of coals
	local function heap(site, spot)
		local parts = {}
		if site.fire then
			for _ = 1, 7 do
				table.insert(parts, piece({ Name = "Coal", Size = V3(rand(0.5, 1), rand(0.3, 0.5), rand(0.5, 1)), Material = MAT.Slate, Color = C3(28, 24, 22) }, CFrame.new(spot + V3(rand(-1.2, 1.2), 0.2, rand(-1.2, 1.2))) * CFrame.Angles(0, rand(0, 6), rand(-0.3, 0.3))))
			end
			local glow = piece({ Name = "CoalGlow", Shape = Enum.PartType.Cylinder, Size = V3(0.1, 2.6, 2.6), Material = MAT.Neon, Color = C3(210, 90, 30), Transparency = 0.35 }, CFrame.new(spot + V3(0, 0.08, 0)) * CFrame.Angles(0, 0, math.pi / 2))
			local light = Instance.new("PointLight")
			light.Color, light.Range, light.Brightness = C3(255, 130, 50), 9, 1.2
			light.Parent = glow
			table.insert(parts, glow)
		else
			for _ = 1, 8 do
				table.insert(parts, piece({ Name = "Bone", Size = V3(0.22, 0.22, rand(0.9, 1.7)), Material = MAT.SmoothPlastic, Color = C3(178, 168, 142):Lerp(C3(140, 124, 92), math.random()) }, CFrame.new(spot + V3(rand(-1, 1), 0.15 + rand(0, 0.25), rand(-1, 1))) * CFrame.Angles(rand(-0.25, 0.25), rand(0, 6), 0)))
			end
			table.insert(parts, piece({ Name = "Skull", Shape = Enum.PartType.Ball, Size = Vector3.one * 0.9, Material = MAT.SmoothPlastic, Color = C3(178, 168, 142) }, CFrame.new(spot + V3(rand(-0.5, 0.5), 0.45, rand(-0.5, 0.5)))))
		end
		return parts
	end

	-- RISE: each heap heaves, and what was in it is up and after you
	local function rise(site, pl)
		for i, spot in ipairs(site.spots) do
			task.delay((i - 1) * 0.3, function()
				if site.fire then
					Core.burst(spot + V3(0, 1, 0), C3(255, 140, 50), 40, 0.6, 16)
					Core.dustCloud(spot, 3, 10)
				else
					Core.groundHeave(spot, 3, 0.8)
				end
				task.wait(0.8)
				if not site.sprung then
					return -- (the world's been set again meanwhile)
				end
				for _, p in ipairs(site.heaps[i] or {}) do
					p:Destroy()
				end
				local _, _, hrp = Core.aliveChar(pl)
				local face = hrp and V3(hrp.Position.X, spot.Y + 3, hrp.Position.Z) or spot + V3(0, 3, 1)
				local e = Enemies.spawn({ Type = site.enemy, CFrame = CFrame.lookAt(spot + V3(0, 3, 0), face) })
				if e then
					e.aggro = true
					Core.bodyPose(e, "Kneel", 0.01)
					task.delay(0.15, function()
						Core.bodyPose(e, "Idle", 0.7)
					end)
					Core.dustCloud(spot + V3(0, 1, 0), 3, 12)
					Core.playSound(e.root, Core.SOUNDS.Unsheath, 0.6, 0.7)
				end
			end)
		end
		FxRemote:FireClient(pl, "Shake", site.from, 0.6)
	end

	-- ROCKFALL: four pieces of the wall, one after another, each onto where you're headed
	local function rockfall(site, pl)
		for i = 0, 3 do
			task.delay(i * 0.6, function()
				local _, _, hrp = Core.aliveChar(pl)
				local p = hrp and floorAt(hrp.Position - V3(0, 3, 0) + Core.flat(hrp.AssemblyLinearVelocity) * 0.5)
				if not p then
					return
				end
				Core.dustCloud(p + V3(0, 12, 0), 2, 6)
				local shadow = piece({ Name = "Shadow", Shape = Enum.PartType.Cylinder, Size = V3(0.08, 1, 1), Material = MAT.SmoothPlastic, Color = C3(8, 8, 8), Transparency = 0.35, CastShadow = false }, CFrame.new(p + V3(0, 0.06, 0)) * CFrame.Angles(0, 0, math.pi / 2))
				TweenService:Create(shadow, TweenInfo.new(0.8), { Size = V3(0.08, 9, 9) }):Play()
				local rock = piece({ Name = "FallenStone", Size = V3(rand(3, 4), rand(2, 3), rand(3, 4)), Material = MAT.Slate, Color = C3(84, 80, 76):Lerp(C3(50, 48, 46), math.random()) }, CFrame.new(p + V3(0, 26, 0)) * CFrame.Angles(rand(0, 6), rand(0, 6), 0))
				TweenService:Create(rock, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.45), { CFrame = CFrame.new(p + V3(0, 1.1, 0)) * CFrame.Angles(rand(-0.2, 0.2), rand(0, 6), rand(-0.2, 0.2)) }):Play()
				task.wait(0.85)
				shadow:Destroy()
				for _, hit in ipairs(everyone(p, 4.5)) do
					Core.damagePlayer(hit, 26, p, "Knockdown")
				end
				Core.shockwave(p, 4)
				Core.playSound(rock, Core.SOUNDS.WatchdogSmash, 0.9, 0.7)
				FxRemote:FireClient(pl, "Shake", p, 0.9)
				task.delay(5, function()
					TweenService:Create(rock, TweenInfo.new(1.5), { Transparency = 1 }):Play()
					Debris:AddItem(rock, 1.6)
				end)
			end)
		end
	end

	-- VENTS: the grates light, one after another down the line (that's the warning: 0.8s), and then burn for a second
	local function vents(site)
		for round = 1, 2 do
			for i, v in ipairs(site.vents) do
				task.delay((round - 1) * 2.6 + (i - 1) * 0.3, function()
					local glow = piece({ Name = "VentGlow", Shape = Enum.PartType.Cylinder, Size = V3(0.1, 1, 1), Material = MAT.Neon, Color = C3(255, 120, 40), Transparency = 0.3, CastShadow = false }, CFrame.new(v + V3(0, 0.16, 0)) * CFrame.Angles(0, 0, math.pi / 2))
					TweenService:Create(glow, TweenInfo.new(0.8), { Size = V3(0.1, 5.4, 5.4) }):Play()
					Core.playSound(glow, Core.SOUNDS.Unsheath, 0.5, 0.5)
					task.wait(0.8)
					local fire = Instance.new("ParticleEmitter")
					fire.Texture = "rbxasset://textures/particles/fire_main.dds"
					fire.Color = ColorSequence.new(C3(255, 190, 90), C3(200, 50, 20))
					fire.LightEmission = 0.8
					fire.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.6), NumberSequenceKeypoint.new(1, 0.6) })
					fire.Transparency = NumberSequence.new(0.1, 1)
					fire.Lifetime, fire.Speed, fire.Rate = NumberRange.new(0.4, 0.7), NumberRange.new(16, 24), 90
					fire.SpreadAngle = Vector2.new(8, 8)
					fire.EmissionDirection = Enum.NormalId.Right -- (the disc lies on its side: its X is up)
					fire.Parent = glow
					local light = Instance.new("PointLight")
					light.Color, light.Range, light.Brightness = C3(255, 150, 60), 16, 3
					light.Parent = glow
					Core.playSound(glow, Core.SOUNDS.Lunge, 0.8, 0.5)
					for _ = 1, 4 do
						for _, hit in ipairs(everyone(v, 3)) do
							Core.damagePlayer(hit, 12, v, "Medium")
						end
						task.wait(0.25)
					end
					fire.Enabled = false
					TweenService:Create(glow, TweenInfo.new(0.5), { Transparency = 1 }):Play()
					Debris:AddItem(glow, 0.9)
				end)
			end
		end
		task.delay(2.6 * 2 + 5, function()
			site.sprung = false -- (they never stop: set again a few seconds after the last of it)
		end)
	end

	-- set: every site's spots found on the map as built, its tells put out
	local function set()
		refilter()
		for _, site in ipairs(SITES) do
			site.sprung = false
			for _, parts in ipairs(site.heaps or {}) do
				for _, p in ipairs(parts) do
					p:Destroy()
				end
			end
			site.heaps = {}
			if site.kind == "rise" then
				site.spots = floorAt(site.from) and spotsRound(site.from, site.count) or {}
				for i, spot in ipairs(site.spots) do
					site.heaps[i] = heap(site, spot)
				end
			elseif site.kind == "vents" and not site.vents then
				site.vents = {}
				for i = 0, site.count - 1 do
					local v = floorAt(site.trigger + site.dir * (4 + i * site.gap))
					if v and math.abs(v.Y - site.trigger.Y) < 2 then
						table.insert(site.vents, v)
						piece({ Name = "VentGrate", Shape = Enum.PartType.Cylinder, Size = V3(0.12, 5, 5), Material = MAT.DiamondPlate, Color = C3(34, 30, 28) }, CFrame.new(v + V3(0, 0.07, 0)) * CFrame.Angles(0, 0, math.pi / 2))
						piece({ Name = "VentThroat", Shape = Enum.PartType.Cylinder, Size = V3(0.13, 3.4, 3.4), Material = MAT.SmoothPlastic, Color = C3(8, 6, 6) }, CFrame.new(v + V3(0, 0.08, 0)) * CFrame.Angles(0, 0, math.pi / 2))
					end
				end
			end
		end
	end
	set()
	Enemies.onRespawn(set)

	task.spawn(function()
		while true do
			task.wait(0.2)
			for _, site in ipairs(SITES) do
				if not site.sprung then
					local near = everyone(site.trigger, site.radius)
					if near[1] then
						site.sprung = true
						refilter()
						local ok, err = pcall(function()
							if site.kind == "rise" and #site.spots > 0 then
								rise(site, near[1])
							elseif site.kind == "rockfall" then
								rockfall(site, near[1])
							elseif site.kind == "vents" and #site.vents > 0 then
								vents(site)
							end
						end)
						if not ok then
							warn("[DGUS] ambush " .. site.id .. ": " .. tostring(err))
						end
					end
				end
			end
		end
	end)
end

return M
