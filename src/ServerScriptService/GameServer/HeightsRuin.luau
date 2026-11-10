--!nonstrict
-- THE FALL OF THE GILDED HEIGHTS: Ossaria's slash, near the end of her meeting (Ossaria.luau; saved with "OssariaFled").
-- The kingdom on the colosseum's crown torn down: its halls (Map.Heights.Folder), the court still at its posts (their
-- spawns with them), the old king and his dancers, and the funnel of rock it all stood on (Map.HeightsRock: every rock
-- fill that made the funnel and the Heights' cliffs, logged by M.record as they were built). What's left is the
-- colosseum, gone to rot, in a ring of pale rubble heaps; the Gilded Gate's bonfire comes down onto the road; and
-- the land goes to night.
--   M.record(terrain, list): a stand-in for terrain that logs its non-Air fills into list (MapBuilder, GildedHeights)
--   M.fall(Core, quick): once; quick = no dust (a save's replay)
local M = {}
local V3, C3 = Vector3.new, Color3.fromRGB
local MAT = Enum.Material

function M.record(terrain, into)
	return setmetatable({}, {
		__index = function(_, name)
			return function(_, ...)
				local args = table.pack(...)
				if args[args.n] ~= Enum.Material.Air then
					table.insert(into, { name, table.unpack(args, 1, args.n - 1) })
				end
				return terrain[name](terrain, ...)
			end
		end,
	})
end

local ROT, ROT_DK, MOSS = C3(78, 52, 86), C3(34, 26, 38), C3(62, 70, 46)
local IVORY, CREAM, GOLD, TARNISH = C3(218, 216, 208), C3(202, 198, 188), C3(201, 160, 74), C3(112, 88, 48)
local GEMS = { C3(30, 70, 150), C3(150, 40, 90), C3(24, 120, 100), C3(170, 100, 30) }
-- the colosseum's own parts (MapBuilder, THE CROWNED COLOSSEUM); its Champion's seal is left be
local COLOSSEUM = { ColosseumFloor = true, ArenaRing = true, ArenaSand = true, ColumnBase = true, Column = true, Capital = true, Architrave = true, ColonnadeRoof = true, Parapet = true, Attic = true, AtticBand = true, Cornice = true, BrazierStand = true, Brazier = true, Paving = true }
local ROAD = math.rad(24) -- (either side of due east, the way in: kept clear)

local fallen = false
-- when each part of the Heights starts to go, seconds into the collapse (dur, below): by how far out it is from the
-- hole - the bridge and the inner halls first, into it, then out ring by ring - and the Ballroom's island last. The
-- clients' falling halls (SoulsClient's "HeightsFall") and the rock carved away under them here keep to the same.
M.BANDS = { { 58, 0.3 }, { 90, 1.2 }, { 125, 2.6 }, { math.huge, 4.2 } } -- { out to, starts at }
M.BALL_R, M.BALL_AT = 70, 7.6 -- (round the Ballroom's middle: it goes at BALL_AT)

-- 0. the land goes to night with them (for good: the Lighting init.server set at startup). Interiors live on Ambient,
-- so it only dims a little; outdoors and the sky take the dark. quick: at once; else over secs (default 1.2)
function M.night(quick, secs)
	local Lighting = game:GetService("Lighting")
	local atm, sky = Lighting:FindFirstChildOfClass("Atmosphere"), Lighting:FindFirstChildOfClass("Sky")
	local function to(inst, props)
		if quick then
			for k, v in pairs(props) do
				inst[k] = v
			end
		else
			game:GetService("TweenService"):Create(inst, TweenInfo.new(secs or 1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), props):Play()
		end
	end
	-- (moonlit, not black: under the land's grey grading anything darker is unplayable)
	to(Lighting, { ClockTime = 0, Brightness = 2.6, Ambient = C3(50, 48, 64), OutdoorAmbient = C3(112, 120, 164) })
	if atm then
		to(atm, { Color = C3(66, 72, 110), Decay = C3(30, 32, 58), Density = 0.3, Haze = 1 })
	end
	if sky then
		sky.StarCount, sky.CelestialBodiesShown = 3000, true
	end
end

-- slow (dur given): the halls brought down over dur seconds (Ossaria's strings), and then it waits for M.settle - the
-- moment the camera's off the colosseum - before it puts the ruin in: the heaps, the colosseum gone to rot, the
-- bonfire on the road. Its night is the caller's too (M.night). nil dur = all of it at once.
local settleNow = false
function M.settle()
	settleNow = true
end

function M.fall(Core, quick, dur)
	local Map = Core.Map
	local H, W = Map.Heights, Map.Wilds
	if fallen or not (H and H.Folder and W and W.Funnel) then
		return
	end
	fallen = true
	local slow = not quick and dur ~= nil
	if not slow then
		M.night(quick)
	end

	local Fn = W.Funnel
	local C = V3(Fn.Centre.X, W.Y, Fn.Centre.Z)
	local map = H.Folder.Parent
	local terrain = workspace.Terrain
	local rng = Random.new(5150)
	local function R(a, b)
		return rng:NextNumber(a, b)
	end
	local function bearing(p) -- (from the colosseum's middle, 0 = east)
		return math.atan2(p.Z - C.Z, p.X - C.X)
	end

	-- 1. the court and the king go with their halls (anything up in the Heights' or the Ballroom's box)
	local boxes = {}
	for _, z in ipairs(Map.Zones) do
		if z.Name == "The Gilded Heights" or z.Name == "The Gilded Ballroom" then
			table.insert(boxes, z)
		end
	end
	local function up(p)
		for _, z in ipairs(boxes) do
			if p.X >= z.MinX and p.X <= z.MaxX and p.Z >= z.MinZ and p.Z <= z.MaxZ and p.Y >= (z.MinY or -math.huge) then
				return true
			end
		end
		return false
	end
	require(script.Parent:WaitForChild("Enemies")).cull(up)
	local npcs = workspace:FindFirstChild("NPCs")
	for _, m in ipairs(npcs and npcs:GetChildren() or {}) do
		if m:IsA("Model") and up(m:GetPivot().Position) then
			m:Destroy()
		end
	end
	local dancers = workspace:FindFirstChild("BallroomDancers")

	-- 2. the rock it stood on: every fill that made it, emptied (a little wider, so no skin of it's left). Slow: the
	-- clients bring the halls down meanwhile, and each fill goes as the halls over it start to fall, in a puff of dust
	local AIR = Enum.Material.Air
	local function carve(r)
		if r[1] == "FillBall" then
			terrain:FillBall(r[2], r[3] + 2, AIR)
		elseif r[1] == "FillBlock" then
			terrain:FillBlock(r[2], r[3] + V3(4, 4, 4), AIR)
		elseif r[1] == "FillCylinder" then
			terrain:FillCylinder(r[2], r[3] + 4, r[4] + 2, AIR)
		end
	end
	if slow then
		local BC = H.Ballroom and H.Ballroom.Centre
		Core.FxRemote:FireAllClients("HeightsFall", { H.Folder, dancers }, {
			Centre = C, Top = Fn.Top, Dur = dur, Bands = M.BANDS, BallR = M.BALL_R, BallAt = M.BALL_AT, Ballroom = BC,
		})
		local order = {}
		for _, r in ipairs(Map.HeightsRock or {}) do
			local p = typeof(r[2]) == "CFrame" and r[2].Position or r[2]
			local at = M.BANDS[#M.BANDS][2]
			if BC and (V3(p.X, 0, p.Z) - V3(BC.X, 0, BC.Z)).Magnitude < M.BALL_R + 10 then
				at = M.BALL_AT
			else
				local d = (V3(p.X, 0, p.Z) - V3(C.X, 0, C.Z)).Magnitude
				for _, b in ipairs(M.BANDS) do
					if d < b[1] then
						at = b[2]
						break
					end
				end
			end
			table.insert(order, { at + 0.6 + R(0, 1.4), r, p })
		end
		table.sort(order, function(a, b)
			return a[1] < b[1]
		end)
		-- (each piece of the rock is eaten away from its top down over half a second, in dust all the way: terrain
		-- can't be moved, but it must never be there one frame and gone the next with the camera on it)
		local function erode(r, p)
			local h = r[1] == "FillBall" and r[3] * 2 or r[1] == "FillBlock" and r[3].Y or r[3]
			for k = 1, 4 do
				carve({ r[1], r[2] + V3(0, h * (1 - k / 4), 0), r[3], r[4] })
				Core.dustCloud(p + V3(0, h * (0.5 - k / 4), 0), math.clamp(h * 0.3, 8, 22), 10)
				task.wait(0.14)
			end
		end
		local t0, i = os.clock(), 1
		while os.clock() - t0 < dur do
			local t = os.clock() - t0
			while order[i] and order[i][1] <= t do
				task.spawn(erode, order[i][2], order[i][3])
				i += 1
			end
			task.wait()
		end
		task.wait(0.6) -- (the last of them, done)
		for j = i, #order do
			carve(order[j][2])
		end
	else
		for _, r in ipairs(Map.HeightsRock or {}) do
			carve(r)
		end
	end
	local folder = Instance.new("Folder")
	folder.Name = "HeightsRubble"
	local tp = RaycastParams.new()
	tp.FilterType = Enum.RaycastFilterType.Include
	tp.FilterDescendantsInstances = { terrain }
	local function ground(x, z)
		local hit = workspace:Raycast(V3(x, 400, z), V3(0, -500, 0), tp)
		return hit and hit.Position, hit and hit.Normal
	end
	-- (terrain's collision catches up with the fills a frame or more later: till then rays still find the old top)
	for _ = 1, 120 do
		local g = ground(C.X + 90, C.Z + 30)
		if not g or g.Y < Fn.Base then
			break
		end
		task.wait()
	end
	-- (slow: nothing more till the camera's away from the colosseum; from here on it's all in one frame)
	while slow and not settleNow do
		task.wait()
	end
	if dancers then
		dancers:Destroy()
	end
	H.Folder:Destroy()

	-- the woods round it, under the heaps: gone too (the way in, east, left be)
	local WOOD = { Leaves = true, Bough = true, Trunk = true, Log = true, Stone = true, MushroomCap = true, MushroomGills = true, MushroomSpot = true, MushroomFoot = true, MushroomStem = true }
	for _, p in ipairs(map:GetChildren()) do
		if WOOD[p.Name] and p:IsA("BasePart") then
			local d = (V3(p.Position.X, 0, p.Position.Z) - V3(C.X, 0, C.Z)).Magnitude
			if d > 64 and d < 130 then
				p:Destroy()
			end
		end
	end
	local function piece(props)
		local p = Instance.new(props.Class or "Part")
		props.Class = nil
		p.Anchored, p.TopSurface, p.BottomSurface = true, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		for k, v in pairs(props) do
			p[k] = v
		end
		p.Parent = folder
		return p
	end
	local function rotted(col, k)
		return col:Lerp(ROT_DK, k):Lerp(rng:NextNumber() < 0.3 and ROT or MOSS, R(0, 0.25))
	end

	-- 3. the heaps: a ring of them round the colosseum, the road left clear, nothing heaped onto a building. Each a low
	-- mound with broken masonry piled up it (tilted blocks of stone: terrain, so it's ground to climb)
	local heaps = {}
	local MATS = { MAT.Limestone, MAT.Limestone, MAT.Limestone, MAT.Sandstone, MAT.Slate }
	local all = RaycastParams.new()
	all.FilterType = Enum.RaycastFilterType.Exclude
	all.FilterDescendantsInstances = { folder, workspace:FindFirstChild("Enemies") or folder }
	local function heap(r1, r2, big)
		for _ = 1, 30 do -- (a few tries for a spot off the road and clear of buildings)
			local a = R(-math.pi, math.pi)
			if math.abs(a) > ROAD then
				local rr = R(r1, r2)
				local x, z = C.X + math.cos(a) * rr, C.Z + math.sin(a) * rr
				local top = workspace:Raycast(V3(x, 400, z), V3(0, -500, 0), all)
				if top and top.Instance == terrain then
					local g = top.Position
					local hr = R(big * 0.6, big)
					terrain:FillBall(g - V3(0, hr * 0.55, 0), hr, MATS[1])
					for _ = 1, rng:NextInteger(9, 15) do
						local b, k = R(0, math.pi * 2), R(0, 1)
						local at = g + V3(math.cos(b), 0, math.sin(b)) * hr * 0.85 * k + V3(0, hr * 0.45 * (1 - k) ^ 1.5 - 1, 0)
						local s = V3(R(6, 13), R(5, 9), R(6, 13)) * (1.2 - k * 0.4) -- (no thinner than a voxel or two: thin terrain shows as sheets)
						terrain:FillBlock(CFrame.new(at) * CFrame.Angles(R(-0.35, 0.35), R(0, 6.3), R(-0.35, 0.35)), s, MATS[rng:NextInteger(1, #MATS)])
					end
					table.insert(heaps, { g, hr })
					return
				end
			end
		end
	end
	for _ = 1, 34 do
		heap(70, 124, 24)
	end

	-- the Heights in pieces on the heaps: drums of its columns, slabs of its walls, gilt off its roofs, its coloured glass
	for i = 1, #heaps > 0 and 420 or 0 do
		local h = heaps[(i - 1) % #heaps + 1]
		local b = R(0, math.pi * 2)
		local g, n = ground(h[1].X + math.cos(b) * h[2] * R(0, 1.1), h[1].Z + math.sin(b) * h[2] * R(0, 1.1))
		if g then
			local kind = rng:NextNumber()
			local props
			if kind < 0.3 then
				local d = R(2.6, 4)
				props = { Name = "FallenDrum", Shape = Enum.PartType.Cylinder, Size = V3(R(2, 5), d, d), Material = MAT.Limestone, Color = rotted(IVORY, R(0.15, 0.5)) }
			elseif kind < 0.65 then
				props = { Name = "FallenSlab", Size = V3(R(4, 11), R(1, 2.4), R(3, 7)), Material = MAT.Limestone, Color = rotted(CREAM, R(0.15, 0.5)) }
			elseif kind < 0.85 then
				local d = R(4, 10)
				props = { Name = "FallenGilt", Shape = Enum.PartType.Cylinder, Size = V3(R(0.6, 1.4), d, d), Material = MAT.Metal, Color = GOLD:Lerp(TARNISH, R(0.3, 0.8)):Lerp(ROT_DK, R(0.1, 0.35)) }
			elseif kind < 0.95 then
				props = { Name = "FallenBeam", Size = V3(1.4, 1.4, R(8, 16)), Material = MAT.Metal, Color = GOLD:Lerp(TARNISH, R(0.4, 0.9)) }
			else
				props = { Name = "FallenGlass", Size = V3(R(1.5, 3), R(2, 4), 0.3), Material = MAT.Glass, Color = GEMS[rng:NextInteger(1, #GEMS)], Transparency = 0.3 }
			end
			local big = props.Size.Magnitude > 6
			props.CanCollide, props.CastShadow = big, big
			props.CFrame = CFrame.new(g - n * props.Size.Y * 0.2) * CFrame.Angles(R(-1.2, 1.2), R(0, 6.3), R(-1.2, 1.2))
			piece(props)
		end
	end
	-- what stood longest: the stumps of towers out of the heaps, and the palace's dome, come down whole on the west side
	for _ = 1, #heaps > 0 and 5 or 0 do
		local h = heaps[rng:NextInteger(1, math.min(30, #heaps))]
		local d, ht = R(9, 15), R(14, 28)
		local base = h[1] - V3(0, 4, 0)
		local tilt = CFrame.Angles(R(-0.15, 0.15), R(0, 6.3), R(-0.15, 0.15))
		local col = rotted(IVORY, R(0.2, 0.45))
		piece({ Name = "TowerStump", Shape = Enum.PartType.Cylinder, Size = V3(ht, d, d), CFrame = CFrame.new(base) * tilt * CFrame.new(0, ht / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Limestone, Color = col })
		for _ = 1, 3 do -- (its broken top: a few uneven bits of wall still up)
			local a = R(0, math.pi * 2)
			piece({ Name = "TowerStump", Size = V3(R(2.5, 4.5), R(4, 9), 1.6), CFrame = CFrame.new(base) * tilt * CFrame.new(math.cos(a) * d * 0.4, ht + 1.5, math.sin(a) * d * 0.4) * CFrame.Angles(0, -a + math.pi / 2, 0), Material = MAT.Limestone, Color = col })
		end
	end
	do
		local g = ground(C.X - 104, C.Z + 18)
		if g then
			piece({ Name = "FallenDome", Shape = Enum.PartType.Ball, Size = Vector3.one * 34, CFrame = CFrame.new(g + V3(0, 2, 0)), Material = MAT.Metal, Color = GOLD:Lerp(TARNISH, 0.7):Lerp(ROT_DK, 0.3) })
			terrain:FillBall(g + V3(0, -2, 0), 16, MAT.Limestone) -- (half under its own rubble)
		end
	end

	-- 4. the colosseum gone to rot: stained and cracked, columns snapped, its roof and attic broken, its fires out
	local capitals, columns, archs = {}, {}, {}
	local function key(p)
		return math.floor(p.X + 0.5) .. "," .. math.floor(p.Z + 0.5)
	end
	local parts = {}
	for _, p in ipairs(map:GetChildren()) do
		if p:IsA("BasePart") and COLOSSEUM[p.Name] and (V3(p.Position.X, 0, p.Position.Z) - V3(C.X, 0, C.Z)).Magnitude < 85 then
			table.insert(parts, p)
		end
	end
	for _, p in ipairs(parts) do
		local q = p.Position
		local n = math.noise(q.X / 18, q.Z / 18, 3.1) -- (rot in patches, not evenly)
		if p.Material == MAT.Marble then
			p.Material = MAT.Slate
		end
		p.Color = p.Name == "ArenaSand" and C3(118, 102, 84) or p.Color:Lerp(ROT_DK, math.clamp(0.45 + n * 0.6 + R(-0.15, 0.15), 0.25, 0.85)):Lerp(rng:NextNumber() < 0.35 and ROT or MOSS, R(0.1, 0.35))
		for _, c in ipairs(p:GetChildren()) do
			if c:IsA("Fire") or c:IsA("Light") then
				c.Enabled = false
			end
		end
		if p.Name == "Capital" then
			capitals[key(q)] = p
		elseif p.Name == "Column" then
			table.insert(columns, p)
		elseif p.Name == "Architrave" then
			table.insert(archs, p)
		end
	end
	local function road(q) -- (just the way in through the colonnade)
		return math.abs(bearing(q)) < 0.14
	end
	local FT = W.Y + 0.8
	local snapped = {}
	for _, c in ipairs(columns) do
		local q = c.Position
		if not road(q) and rng:NextNumber() < 0.3 then
			local left = R(4, 12) -- (what's still standing)
			local was = c.Size.X
			c.Size = V3(left, c.Size.Y, c.Size.Z)
			c.CFrame = CFrame.new(q.X, FT + 1 + left / 2, q.Z) * CFrame.Angles(0, 0, math.pi / 2)
			local cap = capitals[key(q)]
			if cap then
				cap:Destroy()
			end
			-- the rest of it, fallen outward across the floor
			local out = V3(q.X - C.X, 0, q.Z - C.Z).Unit
			local side = V3(-out.Z, 0, out.X) * R(-0.6, 0.6)
			local len = was - left - 1
			local at = q + (out + side).Unit * (len / 2 + 1)
			piece({ Name = "FallenColumn", Shape = Enum.PartType.Cylinder, Size = V3(len, c.Size.Y, c.Size.Z), CFrame = CFrame.lookAt(V3(at.X, FT + c.Size.Y / 2, at.Z), V3(q.X, FT + c.Size.Y / 2, q.Z)) * CFrame.Angles(0, math.pi / 2, 0), Material = MAT.Slate, Color = c.Color })
			table.insert(snapped, q)
		elseif rng:NextNumber() < 0.55 then -- (a stain down it, from the top)
			local inw = V3(C.X - q.X, 0, C.Z - q.Z).Unit
			local len = R(6, 16)
			local m = V3(q.X, FT + 21 - len / 2, q.Z) + inw * 1.42
			piece({ Name = "RotStreak", Size = V3(R(0.5, 1), len, 0.1), CFrame = CFrame.lookAt(m, m + inw), Material = MAT.SmoothPlastic, Color = ROT_DK:Lerp(ROT, R(0, 0.5)), Transparency = R(0.2, 0.5), CanCollide = false, CastShadow = false })
		end
	end
	for _, a in ipairs(archs) do -- (a lintel with nothing left under one end comes down)
		local q = a.Position
		for _, s in ipairs(snapped) do
			if (V3(q.X, 0, q.Z) - V3(s.X, 0, s.Z)).Magnitude < 5 then
				local cf = CFrame.new(q.X + R(-1.5, 1.5), FT + 1.2, q.Z + R(-1.5, 1.5)) * CFrame.Angles(R(-0.3, 0.3), R(0, 6.3), R(-0.2, 0.2))
				piece({ Name = "FallenLintel", Size = a.Size, CFrame = cf, Material = MAT.Slate, Color = a.Color })
				a:Destroy()
				break
			end
		end
	end
	for _, p in ipairs(parts) do -- the roof and the attic broken through in places
		if p.Parent and not road(p.Position) then
			local n = math.noise(bearing(p.Position) * 2.4, 7.7)
			if (p.Name == "ColonnadeRoof" and n > 0.3) or ((p.Name == "Attic" or p.Name == "AtticBand" or p.Name == "Cornice") and n > 0.15) then
				p:Destroy()
			end
		end
	end
	for _ = 1, 60 do -- rot pooled on the sand and the floor
		local a, rr = R(0, math.pi * 2), R(4, 60)
		local d = R(4, 12)
		local y = rr < 43 and FT + 0.32 or FT + 0.02
		piece({ Name = "RotPool", Shape = Enum.PartType.Cylinder, Size = V3(0.06, d, d * R(0.6, 1)), CFrame = CFrame.new(C.X + math.cos(a) * rr, y, C.Z + math.sin(a) * rr) * CFrame.Angles(0, R(0, 6.3), math.pi / 2), Material = MAT.SmoothPlastic, Color = ROT_DK:Lerp(ROT, R(0, 0.4)), Transparency = R(0.25, 0.55), CanCollide = false, CastShadow = false })
	end
	folder.Parent = map

	-- 5. the Gilded Gate's bonfire, down onto the road
	for _, bf in ipairs(Map.Bonfires) do
		if bf.Name == "The Gilded Gate" then
			local g = ground(C.X + 86, C.Z - 9)
			local ash = bf.Model:FindFirstChild("Ash")
			if g and ash then
				local delta = g - (ash.Position - V3(0, 0.4, 0))
				bf.Model:PivotTo(bf.Model:GetPivot() + delta)
				bf.CF += delta
				bf.Name = "The Fallen Heights"
				Map.HeightsDev = bf.CF
			end
		end
	end

	if not quick then
		for i, h in ipairs(heaps) do
			if i % 2 == 0 then
				Core.dustCloud(h[1] + V3(0, 4, 0), 14, 14)
			end
		end
		Core.dustCloud(C + V3(0, 30, 0), 20, 24)
	end
end

return M
