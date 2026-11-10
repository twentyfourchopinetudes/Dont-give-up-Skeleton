--!nonstrict
-- MapBuilder: constructs the Don'tGiveUpSkeleton out of plain parts at runtime.
--
-- Layout (top view, +Z is "north"):
--
--   [Boss Arena]                    z 215..305
--        |  fog wall (z 211)
--   [Dim Yard courtyard] -----+     z 120..200
--        |  shortcut gate     |  drowned tunnel
--   [Cell block corridor] ----+     z 0..120
--        start cell (SW), bonfire cell (E), broken cell -> tunnel (E)
--
-- The loop: corridor -> broken cell -> drowned tunnel -> courtyard -> lever
-- opens the gate back into the corridor (shortcut to the bonfire) -> fog -> boss.

local CollectionService = game:GetService("CollectionService")
local Detail = require(script.Parent:WaitForChild("MapDetail"))
local DecayedPalace = require(script.Parent:WaitForChild("DecayedPalace"))
local GildedHeights = require(script.Parent:WaitForChild("GildedHeights"))
local HeightsRuin = require(script.Parent:WaitForChild("HeightsRuin"))

local MapBuilder = {}

local MAT = Enum.Material
local COL = {
	Wall = Color3.fromRGB(70, 67, 61),
	WallDark = Color3.fromRGB(46, 44, 41),
	Floor = Color3.fromRGB(54, 52, 48),
	Ceiling = Color3.fromRGB(33, 32, 30),
	Iron = Color3.fromRGB(42, 39, 36),
	Rust = Color3.fromRGB(84, 54, 36),
	Wood = Color3.fromRGB(58, 43, 31),
	Bone = Color3.fromRGB(184, 176, 152),
	Moss = Color3.fromRGB(50, 58, 40),
	Water = Color3.fromRGB(18, 24, 26),
	Straw = Color3.fromRGB(96, 84, 52),
	Fog = Color3.fromRGB(235, 235, 240),
}

local rng = Random.new(1337)
local map: Folder
local bars: Folder
local messages = {}
local notes = {} -- examinable lore pages
local avoidSpots = {} -- things on walls that decoration must not cover

---------------------------------------------------------------------------
-- primitives
---------------------------------------------------------------------------
local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props.Shape then
		p.Shape = props.Shape
	end
	for k, v in pairs(props) do
		if k ~= "Parent" and k ~= "Shape" then
			p[k] = v
		end
	end
	p.Parent = props.Parent or map
	return p
end

local function box(x1, y1, z1, x2, y2, z2, material, color, name, parent)
	return part({
		Name = name or "Block",
		Size = Vector3.new(math.abs(x2 - x1), math.abs(y2 - y1), math.abs(z2 - z1)),
		CFrame = CFrame.new((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2),
		Material = material or MAT.Cobblestone,
		Color = color or COL.Wall,
		Parent = parent,
	})
end

-- four walls round cf (their centre), size outside, t thick: a box with no top or bottom
local function ring(cf, size, t, mat, color, name, parent, solid)
	local w, h, d = size.X, size.Y, size.Z
	for _, q in ipairs({ { 0, -(d - t) / 2, w, t }, { 0, (d - t) / 2, w, t }, { -(w - t) / 2, 0, t, d - 2 * t }, { (w - t) / 2, 0, t, d - 2 * t } }) do
		part({ Name = name, Size = Vector3.new(q[3], h, q[4]), CFrame = cf * CFrame.new(q[1], 0, q[2]), Material = mat, Color = color, CanCollide = solid ~= false, Parent = parent })
	end
end
-- a chest's body, hollow (a dark floor inside four walls), so an open lid shows into it. cf: on the ground, lock to -Z.
-- straps: thin bands down its front and back at each x (not slabs through it)
local function chestBody(cf, size, mat, color, name, parent, straps, strapMat, strapColor)
	local t = 0.25
	ring(cf * CFrame.new(0, size.Y / 2, 0), size, t, mat, color, name, parent)
	part({ Name = name .. "Floor", Size = Vector3.new(size.X - 2 * t, 0.2, size.Z - 2 * t), CFrame = cf * CFrame.new(0, 0.1, 0), Material = mat, Color = color:Lerp(Color3.new(0, 0, 0), 0.6), Parent = parent })
	for _, x in ipairs(straps or {}) do
		for _, z in ipairs({ -1, 1 }) do
			part({ Name = name .. "Band", Size = Vector3.new(0.3, size.Y + 0.1, 0.06), CFrame = cf * CFrame.new(x, size.Y / 2, z * (size.Z / 2 + 0.03)), Material = strapMat, Color = strapColor, CanCollide = false, Parent = parent })
		end
	end
end

local function stoneColor()
	return COL.Wall:Lerp(COL.WallDark, rng:NextNumber() * 0.6)
end

-- wall running along X at a given z (2 studs thick)
local function wallX(z, x1, x2, h, mat)
	return box(x1, 0, z - 1, x2, h, z + 1, mat or MAT.Cobblestone, stoneColor(), "Wall")
end

-- wall running along Z at a given x (2 studs thick)
local function wallZ(x, z1, z2, h, mat)
	return box(x - 1, 0, z1, x + 1, h, z2, mat or MAT.Cobblestone, stoneColor(), "Wall")
end

local function floor(x1, z1, x2, z2, mat, color)
	return box(x1, -2, z1, x2, 0, z2, mat or MAT.Slate, color or COL.Floor, "Floor")
end

local function ceiling(x1, z1, x2, z2, h)
	return box(x1, h, z1, x2, h + 2, z2, MAT.Slate, COL.Ceiling, "Ceiling")
end

local function prompt(parent, action, object, hold, dist)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = action
	pp.ObjectText = object or ""
	pp.HoldDuration = hold or 0
	pp.MaxActivationDistance = dist or 8
	pp.RequiresLineOfSight = false
	pp.Parent = parent
	return pp
end

local function addFlicker(light)
	light:SetAttribute("Base", light.Brightness)
	CollectionService:AddTag(light, "Flicker")
end

---------------------------------------------------------------------------
-- props
---------------------------------------------------------------------------
local function torch(pos, facing)
	facing = facing.Unit
	table.insert(avoidSpots, pos + facing * 1.4)
	local cf = CFrame.lookAt(pos, pos + facing)
	part({ Name = "TorchBracket", Size = Vector3.new(0.25, 0.25, 1.4), CFrame = cf * CFrame.new(0, 0, -0.7), Material = MAT.Metal, Color = COL.Iron })
	part({ Name = "Torch", Size = Vector3.new(0.35, 1.6, 0.35), CFrame = cf * CFrame.new(0, 0.5, -1.4), Material = MAT.Wood, Color = COL.Wood })
	local flame = part({
		Name = "TorchFlame",
		Size = Vector3.new(0.4, 0.4, 0.4),
		CFrame = cf * CFrame.new(0, 1.5, -1.4),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
	})
	local fire = Instance.new("Fire")
	fire.Size = 2.2
	fire.Heat = 5
	fire.Color = Color3.fromRGB(255, 120, 40)
	fire.SecondaryColor = Color3.fromRGB(120, 30, 10)
	fire.Parent = flame
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 146, 70)
	light.Range = 25
	light.Brightness = 2.3
	light.Shadows = true
	light.Parent = flame
	addFlicker(light)
	return flame
end

local function brazier(pos)
	part({ Name = "BrazierStand", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3.5, 0.8, 0.8), CFrame = CFrame.new(pos + Vector3.new(0, 1.75, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Metal, Color = COL.Iron })
	part({ Name = "BrazierBowl", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 3.4, 3.4), CFrame = CFrame.new(pos + Vector3.new(0, 3.9, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Metal, Color = COL.Iron })
	local flame = part({ Name = "BrazierFlame", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(pos + Vector3.new(0, 4.8, 0)), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	local fire = Instance.new("Fire")
	fire.Size = 5
	fire.Heat = 9
	fire.Color = Color3.fromRGB(255, 110, 35)
	fire.SecondaryColor = Color3.fromRGB(110, 25, 10)
	fire.Parent = flame
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 140, 60)
	light.Range = 34
	light.Brightness = 2.2
	light.Shadows = true
	light.Parent = flame
	addFlicker(light)
end

local function barRow(x, z1, z2, h, gaps)
	local z = z1 + 0.55
	while z < z2 - 0.3 do
		local skip = false
		for _, g in ipairs(gaps or {}) do
			if z > g[1] and z < g[2] then
				skip = true
			end
		end
		if not skip then
			part({
				Name = "Bar",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(h, 0.32, 0.32),
				CFrame = CFrame.new(x, h / 2, z) * CFrame.Angles(0, 0, math.pi / 2),
				Material = MAT.Metal,
				Color = COL.Iron,
				Parent = bars,
			})
		end
		z += 1.1
	end
	part({ Name = "BarRail", Size = Vector3.new(0.35, 0.35, z2 - z1), CFrame = CFrame.new(x, h - 0.6, (z1 + z2) / 2), Material = MAT.Metal, Color = COL.Iron, Parent = bars })
	part({ Name = "BarRail", Size = Vector3.new(0.3, 0.3, z2 - z1), CFrame = CFrame.new(x, 7.6, (z1 + z2) / 2), Material = MAT.Metal, Color = COL.Rust, Parent = bars })
	for _, g in ipairs(gaps or {}) do
		-- an open cell: hinged door frame + lock box on the doorway
		for _, gz in ipairs({ g[1], g[2] }) do
			part({ Name = "DoorPost", Size = Vector3.new(0.45, h, 0.45), CFrame = CFrame.new(x, h / 2, gz), Material = MAT.Metal, Color = COL.Rust, Parent = bars })
		end
		part({ Name = "LockBox", Size = Vector3.new(0.6, 0.9, 0.5), CFrame = CFrame.new(x, 3.6, g[2] + 0.3), Material = MAT.Metal, Color = COL.Iron, CanCollide = false, Parent = bars })
	end
end

local function remains(pos)
	part({ Name = "Skull", Shape = Enum.PartType.Ball, Size = Vector3.new(0.9, 0.9, 0.9), CFrame = CFrame.new(pos + Vector3.new(0, 0.45, 0)), Material = MAT.SmoothPlastic, Color = COL.Bone, CanCollide = false })
	for _ = 1, 5 do
		part({
			Name = "Bone",
			Size = Vector3.new(0.18, 0.18, rng:NextNumber(0.8, 1.6)),
			CFrame = CFrame.new(pos + Vector3.new(rng:NextNumber(-1.2, 1.2), 0.1, rng:NextNumber(-1.2, 1.2))) * CFrame.Angles(0, rng:NextNumber() * 6, 0),
			Material = MAT.SmoothPlastic,
			Color = COL.Bone,
			CanCollide = false,
		})
	end
end

local function chain(top, links)
	for i = 0, links - 1 do
		part({
			Name = "Chain",
			Size = Vector3.new(0.18, 0.5, 0.18),
			CFrame = CFrame.new(top - Vector3.new(0, i * 0.52, 0)) * CFrame.Angles(0, (i % 2) * math.pi / 2, 0),
			Material = MAT.Metal,
			Color = COL.Iron,
			CanCollide = false,
		})
	end
end

local function cage(top)
	local h = 4.5
	part({ Name = "CageTop", Size = Vector3.new(3.4, 0.3, 3.4), CFrame = CFrame.new(top), Material = MAT.Metal, Color = COL.Iron })
	part({ Name = "CageBottom", Size = Vector3.new(3.4, 0.3, 3.4), CFrame = CFrame.new(top - Vector3.new(0, h, 0)), Material = MAT.Metal, Color = COL.Iron })
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		part({
			Name = "CageBar",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(h, 0.18, 0.18),
			CFrame = CFrame.new(top + Vector3.new(math.cos(a) * 1.55, -h / 2, math.sin(a) * 1.55)) * CFrame.Angles(0, 0, math.pi / 2),
			Material = MAT.Metal,
			Color = COL.Iron,
		})
	end
	part({ Name = "Skull", Shape = Enum.PartType.Ball, Size = Vector3.new(0.8, 0.8, 0.8), CFrame = CFrame.new(top - Vector3.new(0.4, h - 0.55, 0.3)), Material = MAT.SmoothPlastic, Color = COL.Bone, CanCollide = false })
end

local function message(pos, text)
	local p = part({
		Name = "Message",
		Size = Vector3.new(2.4, 0.06, 1.2),
		CFrame = CFrame.new(pos.X, pos.Y + 0.04, pos.Z) * CFrame.Angles(0, rng:NextNumber() * math.pi, 0),
		Material = MAT.Neon,
		Color = Color3.fromRGB(255, 120, 40),
		Transparency = 0.45,
		CanCollide = false,
	})
	local pp = prompt(p, "Read", "Message", 0, 7)
	pp:SetAttribute("Text", text)
	table.insert(messages, pp)
end

local function cellDecor(z1, z2, side)
	local cz = (z1 + z2) / 2
	local back = side * 17.2
	if rng:NextNumber() < 0.55 then
		local bz = cz + rng:NextNumber(-2, 2)
		part({ Name = "Bed", Size = Vector3.new(2.6, 0.4, 5.5), CFrame = CFrame.new(back - side * 0.8, 1.4, bz), Material = MAT.WoodPlanks, Color = COL.Wood })
		part({ Name = "BedLeg", Size = Vector3.new(2.4, 1.2, 0.4), CFrame = CFrame.new(back - side * 0.8, 0.6, bz - 2.4), Material = MAT.Wood, Color = COL.Wood })
		part({ Name = "BedLeg", Size = Vector3.new(2.4, 1.2, 0.4), CFrame = CFrame.new(back - side * 0.8, 0.6, bz + 2.4), Material = MAT.Wood, Color = COL.Wood })
	end
	if rng:NextNumber() < 0.6 then
		chain(Vector3.new(back + side * 0.4, 9, cz + rng:NextNumber(-4, 4)), rng:NextInteger(4, 9))
	end
	if rng:NextNumber() < 0.45 then
		remains(Vector3.new(side * rng:NextNumber(10, 15), 0, cz + rng:NextNumber(-3, 3)))
	end
	part({
		Name = "Straw",
		Size = Vector3.new(rng:NextNumber(2, 4), 0.25, rng:NextNumber(2, 4)),
		CFrame = CFrame.new(side * rng:NextNumber(10, 16), 0.12, cz + rng:NextNumber(-3, 3)) * CFrame.Angles(0, rng:NextNumber() * 3, 0),
		Material = MAT.Fabric,
		Color = COL.Straw,
		CanCollide = false,
	})
end

local function rubble(center, spread, count)
	for _ = 1, count do
		local s = rng:NextNumber(0.6, 2.2)
		part({
			Name = "Rubble",
			Size = Vector3.new(s, s * rng:NextNumber(0.5, 1), s * rng:NextNumber(0.6, 1.2)),
			CFrame = CFrame.new(center + Vector3.new(rng:NextNumber(-spread, spread), s * 0.3, rng:NextNumber(-spread, spread)))
				* CFrame.Angles(rng:NextNumber() * 0.6, rng:NextNumber() * 6, rng:NextNumber() * 0.6),
			Material = MAT.Cobblestone,
			Color = stoneColor(),
		})
	end
end

local function pillar(x, z, h, w, broken)
	local height = broken and h * rng:NextNumber(0.25, 0.5) or h
	box(x - w / 2, 0, z - w / 2, x + w / 2, height, z + w / 2, MAT.Cobblestone, stoneColor(), "Pillar")
	if broken then
		rubble(Vector3.new(x + 3, 0, z + 2), 3, 5)
	end
end

local function crenellate(x1, z1, x2, z2, y)
	if x1 == x2 then
		for z = z1, z2 - 2, 4 do
			box(x1 - 1, y, z, x1 + 1, y + 2, z + 2, MAT.Cobblestone, stoneColor(), "Merlon")
		end
	else
		for x = x1, x2 - 2, 4 do
			box(x, y, z1 - 1, x + 2, y + 2, z1 + 1, MAT.Cobblestone, stoneColor(), "Merlon")
		end
	end
end

local function ashEmitter(cf, size, rate)
	local p = part({ Name = "AshFall", Size = size, CFrame = cf, Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = rate
	pe.Lifetime = NumberRange.new(6, 10)
	pe.Speed = NumberRange.new(1, 3)
	pe.EmissionDirection = Enum.NormalId.Bottom
	pe.SpreadAngle = Vector2.new(25, 25)
	pe.Size = NumberSequence.new(0.12)
	pe.Color = ColorSequence.new(Color3.fromRGB(150, 145, 140))
	pe.Transparency = NumberSequence.new(0.3)
	pe.LightInfluence = 1
	pe.Acceleration = Vector3.new(0.6, -0.4, 0.2)
	pe.Parent = p
end

---------------------------------------------------------------------------
-- the drowned sewer: described as rooms, everything else is generated
---------------------------------------------------------------------------
-- Rooms are interior rectangles on a 1-stud grid (x1..x2, z1..z2).
-- floor/ceil are heights; ramp rooms slope along z from ramp[1] (at z1) to ramp[2] (at z2).
-- Walls, corners, floors, ceilings and the fill between different ceiling
-- heights are all derived from this list, so openings can't be misplaced.
local SEWER_ROOMS = {
	{ name = "UpperDrain", x1 = 19, z1 = 85, x2 = 34, z2 = 95, floor = 0, ceil = 11 },
	{ name = "RampDown", x1 = 23, z1 = 67, x2 = 33, z2 = 85, ramp = { -6, 0 }, ceil = 11 },
	{ name = "SouthRun", x1 = 23, z1 = 20, x2 = 33, z2 = 67, floor = -6, ceil = 6 },
	{ name = "EastRun", x1 = 23, z1 = 8, x2 = 69, z2 = 20, floor = -6, ceil = 6 },
	{ name = "NorthRun", x1 = 57, z1 = 20, x2 = 69, z2 = 110, floor = -6, ceil = 6 },
	{ name = "Cistern", x1 = 45, z1 = 45, x2 = 81, z2 = 75, floor = -6, ceil = 10 },
	{ name = "RampUp", x1 = 57, z1 = 110, x2 = 69, z2 = 128, ramp = { -6, 0 }, ceil = 11 },
	{ name = "Outflow", x1 = 57, z1 = 128, x2 = 69, z2 = 161, floor = 0, ceil = 11 },
	{ name = "Mouth", x1 = 41, z1 = 150, x2 = 57, z2 = 161, floor = 0, ceil = 11 },
}
-- areas the sewer opens into (no wall is generated against them)
local SEWER_FOREIGN = {
	{ 7, 85, 19, 95 }, -- the collapsed cell (cell 7)
	{ 28, 150, 41, 161 }, -- the courtyard, through the tunnel mouth
}

local function gkey(x, z)
	return (x + 200) * 1000 + (z + 200)
end

-- greedy-merge a cell map (key -> value) into rectangles of equal value
local function mergeCells(cells, minX, maxX, minZ, maxZ)
	local out, open = {}, {}
	for x = minX, maxX do
		local z = minZ
		while z <= maxZ do
			local v = cells[gkey(x, z)]
			if v ~= nil then
				local z1 = z
				while z + 1 <= maxZ and cells[gkey(x, z + 1)] == v do
					z += 1
				end
				local rk = z1 .. ":" .. z .. ":" .. tostring(v)
				local b = open[rk]
				if b and b.x2 == x then
					b.x2 = x + 1
				else
					b = { x1 = x, x2 = x + 1, z1 = z1, z2 = z + 1, v = v }
					open[rk] = b
					table.insert(out, b)
				end
			end
			z += 1
		end
	end
	return out
end

local function roomFloorAt(r, z)
	if r.ramp then
		local a = (z - r.z1) / (r.z2 - r.z1)
		return r.ramp[1] + (r.ramp[2] - r.ramp[1]) * a
	end
	return r.floor
end

-- builds the sewer geometry; returns the wall runs to dress later
local function buildSewer()
	local grid, foreign = {}, {}
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for _, r in ipairs(SEWER_ROOMS) do
		for x = r.x1, r.x2 - 1 do
			for z = r.z1, r.z2 - 1 do
				grid[gkey(x, z)] = r
			end
		end
		minX, maxX = math.min(minX, r.x1), math.max(maxX, r.x2)
		minZ, maxZ = math.min(minZ, r.z1), math.max(maxZ, r.z2)
	end
	for _, f in ipairs(SEWER_FOREIGN) do
		for x = f[1], f[3] - 1 do
			for z = f[2], f[4] - 1 do
				foreign[gkey(x, z)] = true
			end
		end
	end
	local function solid(x, z)
		local k = gkey(x, z)
		return grid[k] == nil and not foreign[k]
	end

	local rockColor = Color3.fromRGB(46, 50, 46)

	-- 1) walls: every non-interior cell within 2 studs of the sewer becomes rock
	local shell = {}
	for x = minX - 2, maxX + 1 do
		for z = minZ - 2, maxZ + 1 do
			if solid(x, z) then
				local top
				for dx = -2, 2 do
					for dz = -2, 2 do
						local r = grid[gkey(x + dx, z + dz)]
						if r then
							top = math.max(top or -math.huge, r.ceil + 2)
						end
					end
				end
				if top then
					shell[gkey(x, z)] = top
				end
			end
		end
	end
	for _, b in ipairs(mergeCells(shell, minX - 2, maxX + 1, minZ - 2, maxZ + 1)) do
		box(b.x1, -8, b.z1, b.x2, b.v, b.z2, MAT.Rock, rockColor:Lerp(COL.WallDark, rng:NextNumber() * 0.4), "SewerWall")
	end

	-- 2) flat floors and ceilings
	local floors, ceils = {}, {}
	for x = minX, maxX - 1 do
		for z = minZ, maxZ - 1 do
			local r = grid[gkey(x, z)]
			if r then
				ceils[gkey(x, z)] = r.ceil
				if not r.ramp then
					floors[gkey(x, z)] = r.floor
				end
			end
		end
	end
	for _, b in ipairs(mergeCells(floors, minX, maxX, minZ, maxZ)) do
		box(b.x1, b.v - 2, b.z1, b.x2, b.v, b.z2, MAT.Slate, Color3.fromRGB(40, 42, 40), "SewerFloor")
	end
	for _, b in ipairs(mergeCells(ceils, minX, maxX, minZ, maxZ)) do
		box(b.x1, b.v, b.z1, b.x2, b.v + 2, b.z2, MAT.Rock, Color3.fromRGB(34, 36, 34), "SewerCeiling")
	end

	-- 3) ramps: a sloped slab plus step lips for footing
	for _, r in ipairs(SEWER_ROOMS) do
		if r.ramp then
			local a = Vector3.new((r.x1 + r.x2) / 2, r.ramp[1], r.z1)
			local b2 = Vector3.new((r.x1 + r.x2) / 2, r.ramp[2], r.z2)
			local mid = (a + b2) / 2
			local cf = CFrame.lookAt(mid, b2) * CFrame.new(0, -1, 0)
			part({ Name = "SewerRamp", Size = Vector3.new(r.x2 - r.x1, 2, (b2 - a).Magnitude + 0.4), CFrame = cf, Material = MAT.Slate, Color = Color3.fromRGB(44, 46, 42) })
			for z = r.z1 + 1.5, r.z2 - 1, 1.5 do
				local y = roomFloorAt(r, z)
				part({ Name = "StepLip", Size = Vector3.new(r.x2 - r.x1 - 1, 0.12, 0.3), CFrame = CFrame.new((r.x1 + r.x2) / 2, y + 0.04, z), Material = MAT.Slate, Color = COL.WallDark, CanCollide = false, CanQuery = false, CastShadow = false })
			end
		end
	end

	-- 4) seal the step between rooms with different ceiling heights
	local fills = {}
	local function addFill(line, axis, along, lo, hi)
		local k = axis .. "|" .. line .. "|" .. lo .. "|" .. hi
		fills[k] = fills[k] or { axis = axis, line = line, lo = lo, hi = hi, list = {} }
		table.insert(fills[k].list, along)
	end
	for x = minX, maxX - 1 do
		for z = minZ, maxZ - 1 do
			local r = grid[gkey(x, z)]
			if r then
				local rx = grid[gkey(x + 1, z)]
				if rx and rx.ceil ~= r.ceil then
					addFill(x + 1, "x", z, math.min(r.ceil, rx.ceil), math.max(r.ceil, rx.ceil) + 2)
				end
				local rz = grid[gkey(x, z + 1)]
				if rz and rz.ceil ~= r.ceil then
					addFill(z + 1, "z", x, math.min(r.ceil, rz.ceil), math.max(r.ceil, rz.ceil) + 2)
				end
			end
		end
	end
	for _, f in pairs(fills) do
		table.sort(f.list)
		local s0, prev = f.list[1], f.list[1]
		local function flush(a, b)
			if f.axis == "x" then
				box(f.line - 0.5, f.lo, a, f.line + 0.5, f.hi, b + 1, MAT.Rock, rockColor, "CeilingStep")
			else
				box(a, f.lo, f.line - 0.5, b + 1, f.hi, f.line + 0.5, MAT.Rock, rockColor, "CeilingStep")
			end
		end
		for i = 2, #f.list do
			if f.list[i] ~= prev + 1 then
				flush(s0, prev)
				s0 = f.list[i]
			end
			prev = f.list[i]
		end
		flush(s0, prev)
	end

	-- 5) wall faces (for dressing + torches): merged runs per room and direction
	local runs = {}
	local groups = {}
	local dirs = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
	for x = minX, maxX - 1 do
		for z = minZ, maxZ - 1 do
			local r = grid[gkey(x, z)]
			if r then
				for _, dv in ipairs(dirs) do
					if solid(x + dv[1], z + dv[2]) then
						local line, along
						if dv[1] ~= 0 then
							line, along = (dv[1] > 0) and (x + 1) or x, z
						else
							line, along = (dv[2] > 0) and (z + 1) or z, x
						end
						local k = r.name .. "|" .. dv[1] .. "," .. dv[2] .. "|" .. line
						groups[k] = groups[k] or { room = r, dv = dv, line = line, list = {} }
						table.insert(groups[k].list, along)
					end
				end
			end
		end
	end
	for _, g in pairs(groups) do
		table.sort(g.list)
		local s0, prev = g.list[1], g.list[1]
		local function flush(a, b)
			local len = b + 1 - a
			local mid = (a + b + 1) / 2
			local px, pz
			if g.dv[1] ~= 0 then
				px, pz = g.line, mid
			else
				px, pz = mid, g.line
			end
			table.insert(runs, { room = g.room, px = px, pz = pz, nx = -g.dv[1], nz = -g.dv[2], len = len })
		end
		for i = 2, #g.list do
			if g.list[i] ~= prev + 1 then
				flush(s0, prev)
				s0 = g.list[i]
			end
			prev = g.list[i]
		end
		flush(s0, prev)
	end
	table.sort(runs, function(a, b)
		return a.len > b.len
	end)

	-- 6) torches on the longer runs (not on ramps), dim enough to stay a sewer
	local placed = 0
	for i, run in ipairs(runs) do
		if not run.room.ramp and run.len >= 16 and i % 2 == 1 then
			local base = run.room.floor
			torch(Vector3.new(run.px + run.nx * 0.1, base + 6.2, run.pz + run.nz * 0.1), Vector3.new(run.nx, 0, run.nz))
			placed += 1
		end
	end

	-- 7) water: a channel down the lower runs and a pool in the cistern.
	-- Built from overlapping, slightly turned slabs and flat discs so the edges
	-- wander and round off instead of reading as rectangles. (Own random stream,
	-- so nothing else in the level shifts.)
	local wrng = Random.new(2718)
	-- murky grey-green: halfway between the pale it used to render as and the scum.
	-- (Glass + reflectance mirrored the sky and read as white; this is matte with a faint sheen.)
	local WATER = Color3.fromRGB(96, 104, 86)
	local layer = 0
	local function wslab(cf, size, name, disc)
		layer = (layer + 1) % 4
		part({ Name = name or "SewerWater", Shape = disc and Enum.PartType.Cylinder or nil, Size = size,
			CFrame = cf + Vector3.new(0, layer * 0.012, 0), Material = MAT.SmoothPlastic,
			Color = WATER:Lerp(Color3.fromRGB(70, 78, 58), wrng:NextNumber() * 0.4), Transparency = 0.15, Reflectance = 0.06,
			CanCollide = false, CanQuery = false, CastShadow = false })
	end
	local function disc(x, y, z, d, name)
		wslab(CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(0.1, d, d * wrng:NextNumber(0.8, 1)), name, true)
	end
	local function scum(x, y, z)
		local sz = wrng:NextNumber(0.5, 1.6)
		part({ Name = "Scum", Size = Vector3.new(sz, 0.04, sz * wrng:NextNumber(0.4, 1)), CFrame = CFrame.new(x, y + 0.08, z) * CFrame.Angles(0, wrng:NextNumber(0, 6), 0),
			Material = MAT.Grass, Color = Color3.fromRGB(46, 54, 34):Lerp(Color3.fromRGB(30, 34, 24), wrng:NextNumber()), Transparency = 0.2,
			CanCollide = false, CanQuery = false, CastShadow = false })
	end
	-- a channel along its long axis: wandering width, a little drift, rounded banks
	local function channel(x1, z1, x2, z2, y)
		local alongZ = (z2 - z1) >= (x2 - x1)
		local len = alongZ and (z2 - z1) or (x2 - x1)
		local w = alongZ and (x2 - x1) or (z2 - z1)
		local cx, cz = (x1 + x2) / 2, (z1 + z2) / 2
		local t = 0
		while t < len - 0.2 do
			local seg = math.min(wrng:NextNumber(3, 5.5), len - t)
			local ww = w + wrng:NextNumber(-1.1, 0.5)
			local off = wrng:NextNumber(-0.45, 0.45)
			local mid = t + seg / 2
			local pos = alongZ and Vector3.new(cx + off, y, z1 + mid) or Vector3.new(x1 + mid, y, cz + off)
			local size = alongZ and Vector3.new(ww, 0.1, seg + 0.9) or Vector3.new(seg + 0.9, 0.1, ww)
			wslab(CFrame.new(pos) * CFrame.Angles(0, wrng:NextNumber(-0.05, 0.05), 0), size)
			-- soft, rounded spills over the banks on alternating sides
			for _ = 1, (wrng:NextNumber() < 0.5 and 2 or 1) do
				local side = wrng:NextNumber() < 0.5 and -1 or 1
				local d = w * wrng:NextNumber(0.6, 1.1)
				local along = t + wrng:NextNumber(0, seg)
				if alongZ then
					disc(cx + side * w * 0.4, y, z1 + along, d)
				else
					disc(x1 + along, y, cz + side * w * 0.4, d)
				end
			end
			if wrng:NextNumber() < 0.35 then
				local along = t + wrng:NextNumber(0, seg)
				local across = wrng:NextNumber(-w * 0.35, w * 0.35)
				if alongZ then
					scum(cx + across, y, z1 + along)
				else
					scum(x1 + along, y, cz + across)
				end
			end
			t += seg
		end
	end
	channel(26, 20, 30, 67, -5.94)
	channel(23, 12, 69, 16, -5.94)
	channel(61, 20, 65, 110, -5.94)
	-- the cistern pool: an uneven core with overlapping discs eating its corners round
	for gx = -2, 2 do
		for gz = -1, 1 do
			-- fewer, smaller discs toward the corners so the outline rounds off
			local edge = math.abs(gx) == 2 and math.abs(gz) == 1
			if not edge or wrng:NextNumber() < 0.5 then
				disc(63 + gx * 4.2 + wrng:NextNumber(-0.8, 0.8), -5.9, 60 + gz * 4.4 + wrng:NextNumber(-0.8, 0.8), edge and wrng:NextNumber(5, 6.5) or wrng:NextNumber(7, 9), "CisternPool")
			end
		end
	end
	for _ = 1, 8 do
		scum(63 + wrng:NextNumber(-8, 8), -5.9, 60 + wrng:NextNumber(-6, 6))
	end

	-- 8) cistern pillars
	for _, pp in ipairs({ { 51, 51 }, { 75, 51 }, { 51, 60 }, { 75, 60 }, { 51, 69 }, { 75, 69 } }) do
		box(pp[1] - 1.5, -6, pp[2] - 1.5, pp[1] + 1.5, 10, pp[2] + 1.5, MAT.Cobblestone, COL.Wall:Lerp(COL.WallDark, 0.3), "CisternPillar")
		box(pp[1] - 2, -6, pp[2] - 2, pp[1] + 2, -5, pp[2] + 2, MAT.Slate, COL.WallDark, "PillarFoot")
	end

	-- 9) light shafts falling through ceiling grates
	for _, g in ipairs({ { 28, 40, 6 }, { 46, 14, 6 }, { 63, 32, 6 }, { 63, 96, 6 }, { 63, 60, 10 } }) do
		local x, z, ceilY = g[1], g[2], g[3]
		local grate = part({ Name = "CeilingGrate", Size = Vector3.new(3.2, 0.2, 3.2), CFrame = CFrame.new(x, ceilY - 0.05, z), Material = MAT.Metal, Color = Color3.fromRGB(150, 160, 175), Transparency = 0.2 })
		for i = -1, 1 do
			part({ Name = "GrateBar", Size = Vector3.new(3.2, 0.25, 0.25), CFrame = CFrame.new(x, ceilY - 0.2, z + i), Material = MAT.Metal, Color = COL.Iron, CanCollide = false, CanQuery = false })
		end
		local spot = Instance.new("SpotLight")
		spot.Face = Enum.NormalId.Bottom
		spot.Color = Color3.fromRGB(170, 185, 210)
		spot.Brightness = 2.6
		spot.Range = ceilY + 10
		spot.Angle = 45
		spot.Shadows = true
		spot.Parent = grate
		local h = ceilY + 6
		part({ Name = "LightShaft", Size = Vector3.new(2.6, h, 2.6), CFrame = CFrame.new(x, -6 + h / 2, z), Material = MAT.Neon, Color = Color3.fromRGB(180, 195, 220), Transparency = 0.93, CanCollide = false, CanQuery = false, CastShadow = false })
	end

	-- 10) glowing moss
	for _, mp in ipairs({ Vector3.new(30, 9.5, 87), Vector3.new(24, 4.6, 30), Vector3.new(66, 4.6, 88), Vector3.new(78, 8.6, 72), Vector3.new(60, 9.5, 158) }) do
		local m = part({ Name = "GlowMoss", Size = Vector3.new(3, 0.3, 3), CFrame = CFrame.new(mp), Material = MAT.Neon, Color = Color3.fromRGB(70, 110, 80), Transparency = 0.6, CanCollide = false })
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(90, 140, 110)
		l.Range = 12
		l.Brightness = 0.8
		l.Parent = m
	end

	-- rubble from the collapsed wall, heaped to either side of the breach
	rubble(Vector3.new(18.5, 0, 85.2), 0.8, 4)
	rubble(Vector3.new(18.5, 0, 94.8), 0.8, 4)
	return runs
end

---------------------------------------------------------------------------
-- corners: overlapping blocks whose faces share a plane (two walls meeting in a
-- corner, a ceiling sunk into its walls, trim strips meeting) z-fight - the renderer
-- can't tell which face is in front, so the corner flickers as the camera moves.
-- For each such face pair, pull the smaller block's face in a hair so the bigger
-- one cleanly wins. Only square-on blocks (any right-angle turn); bottom faces sit
-- on floors and are left alone. Run once, after everything is built.
---------------------------------------------------------------------------
local function separateCoplanar(root)
	local EPS, NUDGE, CELL = 0.005, 0.04, 8
	local AX = { "X", "Y", "Z" }
	local boxes = {}
	for _, p in ipairs(root:GetDescendants()) do
		if p:IsA("Part") and p.Shape == Enum.PartType.Block and p.Transparency < 1 then
			local cf = p.CFrame
			local axisOf, ok = {}, true -- world axis -> which of the part's own size axes lies along it
			for i, v in ipairs({ cf.RightVector, cf.UpVector, cf.LookVector }) do
				local ax = math.abs(v.X) > 0.999 and "X" or math.abs(v.Y) > 0.999 and "Y" or math.abs(v.Z) > 0.999 and "Z" or nil
				if not ax then
					ok = false
					break
				end
				axisOf[ax] = i
			end
			if ok then
				local size = { p.Size.X, p.Size.Y, p.Size.Z }
				local b = { p = p, axisOf = axisOf, min = {}, max = {}, done = {}, id = #boxes + 1 }
				for _, ax in ipairs(AX) do
					local half = size[axisOf[ax]] / 2
					b.min[ax], b.max[ax] = cf.Position[ax] - half, cf.Position[ax] + half
				end
				b.vol = p.Size.X * p.Size.Y * p.Size.Z
				table.insert(boxes, b)
			end
		end
	end
	-- spatial hash on X/Z so only neighbours are compared
	local cells = {}
	for _, b in ipairs(boxes) do
		for cx = math.floor(b.min.X / CELL), math.floor(b.max.X / CELL) do
			for cz = math.floor(b.min.Z / CELL), math.floor(b.max.Z / CELL) do
				local key = cx .. "," .. cz
				cells[key] = cells[key] or {}
				table.insert(cells[key], b)
			end
		end
	end
	local seen, moved = {}, {}
	local faces = 0
	for _, list in pairs(cells) do
		for i = 1, #list do
			for j = i + 1, #list do
				local a, b = list[i], list[j]
				local key = math.min(a.id, b.id) * 1e6 + math.max(a.id, b.id)
				if not seen[key] then
					seen[key] = true
					local overlap = true
					for _, ax in ipairs(AX) do
						if math.min(a.max[ax], b.max[ax]) - math.max(a.min[ax], b.min[ax]) <= EPS then
							overlap = false
							break
						end
					end
					if overlap then
						local small = a.vol <= b.vol and a or b
						for _, ax in ipairs(AX) do
							for _, side in ipairs({ "min", "max" }) do
								local face = ax .. side
								if not (ax == "Y" and side == "min") and not small.done[face] and math.abs(a[side][ax] - b[side][ax]) < EPS then
									small.done[face] = true
									small[side][ax] += side == "min" and NUDGE or -NUDGE
									moved[small] = true
									faces += 1
								end
							end
						end
					end
				end
			end
		end
	end
	for b in pairs(moved) do
		local p, cf = b.p, b.p.CFrame
		local size, center = { p.Size.X, p.Size.Y, p.Size.Z }, {}
		for _, ax in ipairs(AX) do
			size[b.axisOf[ax]] = math.max(b.max[ax] - b.min[ax], 0.05)
			center[ax] = (b.min[ax] + b.max[ax]) / 2
		end
		p.Size = Vector3.new(size[1], size[2], size[3])
		p.CFrame = CFrame.new(center.X, center.Y, center.Z) * cf.Rotation
	end
	return faces
end

---------------------------------------------------------------------------
-- the Castellan's Helm: a crowned steel great helm with a red horsehair crest.
-- Built around cf (a head's centre, facing its -Z), anchored, in a new Model. Used for
-- the one on its stand in the keep, and (init.server) for wearing it.
---------------------------------------------------------------------------
function MapBuilder.helm(cf)
	local m = Instance.new("Model")
	local function hp(name, size, rel, color, mat, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf * rel
		p.Color = color
		p.Material = mat
		p.Anchored = true
		p.CanCollide = false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if shape then
			p.Shape = shape
		end
		p.Parent = m
		return p
	end
	local steel, dark = Color3.fromRGB(150, 150, 156), Color3.fromRGB(38, 38, 42)
	local gold, red = Color3.fromRGB(196, 156, 72), Color3.fromRGB(140, 22, 24)
	local bowl = steel:Lerp(dark, 0.35)
	hp("HelmBowl", Vector3.new(1.4, 1.45, 1.4), CFrame.new(0, 0.05, 0), bowl, MAT.Metal)
	hp("HelmDome", Vector3.new(1.42, 0.8, 1.42), CFrame.new(0, 0.72, 0), bowl, MAT.Metal, Enum.PartType.Ball)
	hp("HelmRidge", Vector3.new(0.16, 0.5, 1.5), CFrame.new(0, 1.0, 0), gold, MAT.Metal)
	hp("Circlet", Vector3.new(1.48, 0.2, 1.48), CFrame.new(0, 0.42, 0), gold, MAT.Metal)
	for i = -2, 2 do -- crown points round the front
		hp("CrownPoint", Vector3.new(0.16, 0.42, 0.12), CFrame.Angles(0, i * 0.45, 0) * CFrame.new(0, 0.7, -0.74), gold, MAT.Metal)
	end
	hp("Faceplate", Vector3.new(1.2, 1.1, 0.12), CFrame.new(0, -0.08, -0.72), steel, MAT.Metal)
	hp("EyeSlit", Vector3.new(1.0, 0.1, 0.06), CFrame.new(0, 0.18, -0.79), Color3.fromRGB(6, 6, 8), MAT.SmoothPlastic)
	hp("NoseSlit", Vector3.new(0.12, 0.55, 0.06), CFrame.new(0, -0.12, -0.79), dark, MAT.SmoothPlastic)
	for _, x in ipairs({ -0.25, 0.25 }) do
		hp("EyeGlow", Vector3.new(0.12, 0.06, 0.04), CFrame.new(x, 0.18, -0.76), Color3.fromRGB(255, 150, 60), MAT.Neon)
	end
	for _, x in ipairs({ -1, 1 }) do
		hp("Cheek", Vector3.new(0.12, 0.9, 0.9), CFrame.new(x * 0.72, -0.2, -0.3), steel, MAT.Metal)
	end
	for i = 0, 6 do -- the crest, swept back off the crown
		local t = i / 6
		hp("Plume", Vector3.new(0.22, 0.32, 0.4), CFrame.new(0, 1.15 - t * t * 1.4, -0.2 + t * 1.3) * CFrame.Angles(-0.4 - t * 0.9, 0, 0), red:Lerp(Color3.fromRGB(90, 10, 12), t), MAT.Fabric)
	end
	m.PrimaryPart = m:FindFirstChild("HelmBowl")
	return m
end

---------------------------------------------------------------------------
-- build
---------------------------------------------------------------------------
function MapBuilder.build()
	local old = workspace:FindFirstChild("DGUS")
	if old then
		old:Destroy()
	end
	map = Instance.new("Folder")
	map.Name = "DGUS"
	map.Parent = workspace
	bars = Instance.new("Folder")
	bars.Name = "Bars"
	bars.Parent = map
	table.clear(messages)
	table.clear(notes)

	local info = {}
	info.ChestBody = chestBody -- (init.server's armor chests are built with it too)

	-----------------------------------------------------------------------
	-- 1. CELL BLOCK  (x -19..19, z 0..120, ceiling 16)
	-----------------------------------------------------------------------
	floor(-20, -1, 20, 120)
	ceiling(-20, -1, 20, 121, 16)
	wallX(0, -20, 20, 16) -- south end
	wallZ(-19, 0, 120, 16) -- west outer
	wallZ(19, 0, 84, 16) -- east outer (gap 84..96 = collapsed wall into the tunnel)
	wallZ(19, 96, 120, 16)
	box(18, 11, 84, 20, 16, 96, MAT.Cobblestone, stoneColor(), "Wall")

	-- cells: 10 per side, 12 studs deep
	local openCells = {
		West = { [0] = { 3, 9.5 }, [4] = { 51, 57 }, [6] = { 75, 81 } }, -- start cell, the Fallen Cellblock's door cell, ambush cell
		East = { [4] = { 51, 57 }, [7] = { 87, 93 } }, -- bonfire cell, broken-wall cell
	}
	for i = 0, 9 do
		local z1, z2 = i * 12, i * 12 + 12
		if i > 0 then
			wallX(z1, 7, 18, 16)
			wallX(z1, -18, -7, 16)
		end
		pillar(7, z1, 16, 1.6)
		pillar(-7, z1, 16, 1.6)
		local eGap = openCells.East[i]
		local wGap = openCells.West[i]
		barRow(7, z1 + 0.8, z2 - 0.8, 16, eGap and { eGap } or nil)
		barRow(-7, z1 + 0.8, z2 - 0.8, 16, wGap and { wGap } or nil)
		if i ~= 4 and i ~= 7 then -- bonfire cell and the collapsed cell stay clear
			cellDecor(z1, z2, 1)
		end
		if i ~= 0 then
			cellDecor(z1, z2, -1)
		end

	end
	pillar(7, 120, 16, 1.6)
	pillar(-7, 120, 16, 1.6)

	-- broken bars lying in the start cell gap
	part({ Name = "BrokenBar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(7, 0.32, 0.32), CFrame = CFrame.new(-9, 0.2, 6) * CFrame.Angles(0, 0.7, 0), Material = MAT.Metal, Color = COL.Iron, CanCollide = false })
	part({ Name = "BrokenBar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(5, 0.32, 0.32), CFrame = CFrame.new(-4, 0.2, 7) * CFrame.Angles(0, -0.4, 0), Material = MAT.Metal, Color = COL.Iron, CanCollide = false })

	-- cold light falling into the start cell
	local shaft = part({ Name = "StartLight", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(-13, 14, 6), Transparency = 1, CanCollide = false, CanQuery = false })
	local cold = Instance.new("PointLight")
	cold.Color = Color3.fromRGB(150, 165, 200)
	cold.Range = 17
	cold.Brightness = 1.35
	cold.Parent = shaft
	torch(Vector3.new(-17.9, 8, 6), Vector3.new(1, 0, 0)) -- torch on the cell's back wall
	-- warm glow spilling through the broken bars: the way out
	local exitGlow = part({ Name = "ExitGlow", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(-4, 5, 6.25), Transparency = 1, CanCollide = false, CanQuery = false })
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 170, 100)
	glow.Range = 13
	glow.Brightness = 1.1
	glow.Parent = exitGlow

	-- corridor torches on alternating pillars
	for idx, z in ipairs({ 12, 36, 60, 84, 108 }) do
		local side = (idx % 2 == 0) and 1 or -1
		torch(Vector3.new(side * 6.1, 9, z), Vector3.new(-side, 0, 0))
	end
	torch(Vector3.new(0, 9, 1.1), Vector3.new(0, 0, 1))
	for idx, z in ipairs({ 24, 48, 72, 96 }) do
		local side = (idx % 2 == 0) and -1 or 1
		torch(Vector3.new(side * 6.1, 9, z), Vector3.new(-side, 0, 0))
	end

	-- spawn
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "StartCellSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(4, 1, 4)
	spawn.CFrame = CFrame.new(-13, 0.5, 6)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = map
	info.Spawn = CFrame.lookAt(Vector3.new(-13, 3.2, 6), Vector3.new(0, 3.2, 6))

	-----------------------------------------------------------------------
	-- 2. BONFIRES: ash, logs, the coiled sword; lit (and rested at) by init.server.
	--    rest = where you wake after resting there. Every bonfire: info.Bonfires.
	-----------------------------------------------------------------------
	info.Bonfires = {}
	local function makeBonfire(pos, rest, title)
		local model = Instance.new("Model")
		model.Name = "Bonfire"
		model.Parent = map
		local ash = part({
			Name = "Ash",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.8, 4.5, 4.5),
			CFrame = CFrame.new(pos + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.pi / 2),
			Material = MAT.Slate,
			Color = Color3.fromRGB(40, 38, 36),
			Parent = model,
		})
		for i = 1, 7 do
			local a = i / 7 * math.pi * 2
			local base = pos + Vector3.new(math.cos(a) * 1.6, 0.6, math.sin(a) * 1.6)
			local top = pos + Vector3.new(0, 2.0, 0)
			part({ Name = "Log", Size = Vector3.new(0.35, 0.35, (top - base).Magnitude), CFrame = CFrame.lookAt((base + top) / 2, top), Material = MAT.Wood, Color = Color3.fromRGB(28, 22, 18), CanCollide = false, Parent = model })
		end
		-- the coiled sword
		local swordCF = CFrame.new(pos + Vector3.new(0, 2.2, 0)) * CFrame.Angles(0.12, 0.5, 0.08)
		part({ Name = "CoiledBlade", Size = Vector3.new(0.34, 3.6, 0.12), CFrame = swordCF, Material = MAT.Metal, Color = Color3.fromRGB(70, 58, 48), CanCollide = false, Parent = model })
		part({ Name = "CoiledGuard", Size = Vector3.new(1.2, 0.2, 0.3), CFrame = swordCF * CFrame.new(0, 1.9, 0), Material = MAT.Metal, Color = COL.Iron, CanCollide = false, Parent = model })
		part({ Name = "CoiledGrip", Size = Vector3.new(0.25, 1.1, 0.25), CFrame = swordCF * CFrame.new(0, 2.55, 0), Material = MAT.Wood, Color = COL.Wood, CanCollide = false, Parent = model })

		local flame = part({ Name = "BonfireFlame", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(pos + Vector3.new(0, 1.4, 0)), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = model })
		local fire = Instance.new("Fire")
		fire.Size = 6
		fire.Heat = 9
		fire.Color = Color3.fromRGB(255, 125, 40)
		fire.SecondaryColor = Color3.fromRGB(140, 35, 10)
		fire.Enabled = false
		fire.Parent = flame
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 150, 70)
		light.Range = 24
		light.Brightness = 2.4
		light.Shadows = true
		light.Enabled = false
		light.Parent = flame
		addFlicker(light)
		local ashGlow = Instance.new("PointLight")
		ashGlow.Color = Color3.fromRGB(255, 110, 40)
		ashGlow.Range = 7
		ashGlow.Brightness = 0.6
		ashGlow.Parent = ash
		local sparks = Instance.new("ParticleEmitter")
		sparks.Rate = 0
		sparks.Lifetime = NumberRange.new(1, 2)
		sparks.Speed = NumberRange.new(2, 5)
		sparks.SpreadAngle = Vector2.new(20, 20)
		sparks.Size = NumberSequence.new(0.15, 0)
		sparks.Color = ColorSequence.new(Color3.fromRGB(255, 160, 60))
		sparks.LightEmission = 1
		sparks.Acceleration = Vector3.new(0, 2, 0)
		sparks.Parent = flame

		local b = {
			Model = model,
			Prompt = prompt(ash, "Light bonfire", "Bonfire", 0.4, 9),
			Fire = fire,
			Light = light,
			Glow = ashGlow,
			Sparks = sparks,
			CF = rest,
			Name = title or "Bonfire", -- (the travel menu's name for it)
		}
		table.insert(info.Bonfires, b)
		return b
	end
	-- the first, in the cell block's east cell 4 (z 48..60)
	info.Bonfire = makeBonfire(Vector3.new(14, 0, 54), CFrame.lookAt(Vector3.new(9.5, 3.2, 54), Vector3.new(14, 3.2, 54)), "The Prison Cell")
	info.BonfireCF = info.Bonfire.CF

	-----------------------------------------------------------------------
	-- 3. THE DROWNED SEWER (cell 7 -> down -> around the cistern -> up -> courtyard)
	-----------------------------------------------------------------------
	local sewerRuns = buildSewer()
	-- a doorway north out of the Upper Drain into Wick's passage (x 29..33, 9 high).
	-- Cut out of the generated rock after the fact, so the random stream is untouched.
	do
		local d1, d2 = Vector3.new(29, 0, 94.9), Vector3.new(33, 9, 97.1)
		for _, w in ipairs(map:GetChildren()) do
			if w.Name == "SewerWall" and w:IsA("BasePart") then
				local c, s = w.CFrame.Position, w.Size
				local a1, a2 = c - s / 2, c + s / 2
				if a1.X < d2.X and a2.X > d1.X and a1.Z < d2.Z and a2.Z > d1.Z and a1.Y < d2.Y and a2.Y > d1.Y then
					local col, mat = w.Color, w.Material
					local pieces = {}
					local function add(x1, y1, z1, x2, y2, z2)
						if x2 - x1 > 0.01 and y2 - y1 > 0.01 and z2 - z1 > 0.01 then
							table.insert(pieces, { x1, y1, z1, x2, y2, z2 })
						end
					end
					local mx1, mx2 = math.max(a1.X, d1.X), math.min(a2.X, d2.X)
					local mz1, mz2 = math.max(a1.Z, d1.Z), math.min(a2.Z, d2.Z)
					add(a1.X, a1.Y, a1.Z, mx1, a2.Y, a2.Z)
					add(mx2, a1.Y, a1.Z, a2.X, a2.Y, a2.Z)
					add(mx1, a1.Y, a1.Z, mx2, a2.Y, mz1)
					add(mx1, a1.Y, mz2, mx2, a2.Y, a2.Z)
					add(mx1, a1.Y, mz1, mx2, d1.Y, mz2) -- under the doorway: still floor
					add(mx1, d2.Y, mz1, mx2, a2.Y, mz2) -- above the doorway
					for i, pc in ipairs(pieces) do
						local size = Vector3.new(pc[4] - pc[1], pc[5] - pc[2], pc[6] - pc[3])
						local cf = CFrame.new((pc[1] + pc[4]) / 2, (pc[2] + pc[5]) / 2, (pc[3] + pc[6]) / 2)
						if i == 1 then
							w.Size, w.CFrame = size, cf
						else
							part({ Name = "SewerWall", Size = size, CFrame = cf, Material = mat, Color = col })
						end
					end
				end
			end
		end
	end

	-----------------------------------------------------------------------
	-- 4. ASHEN YARD courtyard (x -40..40, z 120..200, open sky)
	-----------------------------------------------------------------------
	floor(-41, 120, 41, 200, MAT.Cobblestone, Color3.fromRGB(58, 56, 52))
	wallX(120, -41, -7, 30)
	wallX(120, 7, 41, 30)
	box(-7, 14, 119, 7, 30, 121, MAT.Cobblestone, stoneColor(), "Wall") -- above the gate
	wallZ(40, 120, 150, 30)
	wallZ(40, 162, 200, 30)
	box(39, 11, 150, 41, 30, 162, MAT.Cobblestone, stoneColor(), "Wall") -- above tunnel mouth
	-- the drain grate across the tunnel mouth, rusted fast. Wick (Mabel) knows the trick of it; once she's told
	-- you (player attribute GrateUp, set at its prompt) it lifts for you alone (SoulsClient, tag "DrainGrate")
	do
		local g = Instance.new("Model")
		g.Name = "DrainGrate"
		g.Parent = map
		pcall(function()
			g.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		end)
		local iron, rust = Color3.fromRGB(42, 39, 36), Color3.fromRGB(84, 54, 36)
		local block = part({ Name = "GrateBlock", Size = Vector3.new(0.6, 11, 12), CFrame = CFrame.new(41.5, 5.5, 156), Transparency = 1, Parent = g })
		g.PrimaryPart = block
		for z = 150.5, 161.6, 0.85 do
			part({ Name = "GrateBar", Size = Vector3.new(0.3, 11, 0.3), CFrame = CFrame.new(41.5, 5.5, z), Material = MAT.CorrodedMetal, Color = iron:Lerp(rust, (z * 7) % 1 * 0.6), CanCollide = false, Parent = g })
		end
		for _, y in ipairs({ 0.4, 4, 7.6, 10.6 }) do
			part({ Name = "GrateRail", Size = Vector3.new(0.45, 0.45, 12), CFrame = CFrame.new(41.5, y, 156), Material = MAT.CorrodedMetal, Color = rust, CanCollide = false, Parent = g })
		end
		CollectionService:AddTag(g, "DrainGrate")
		info.DrainGrate = { Model = g, Prompt = prompt(block, "Lift", "Grate", 0, 9) }
	end
	do
		-- west wall, with the doorway into the Usher's Walk (z 156..164, 12 high).
		-- One colour for all three pieces keeps the random stream as it was.
		local c = stoneColor()
		box(-41, 0, 120, -39, 30, 156, MAT.Cobblestone, c, "Wall")
		box(-41, 0, 164, -39, 30, 200, MAT.Cobblestone, c, "Wall")
		box(-41, 12, 156, -39, 30, 164, MAT.Cobblestone, c, "Wall") -- above the doorway
	end
	wallX(200, -41, -8, 30)
	wallX(200, 8, 41, 30)
	box(-8, 14, 199, 8, 30, 201, MAT.Cobblestone, stoneColor(), "Wall") -- above passage
	crenellate(-41, 120, 41, 120, 30)
	crenellate(-41, 200, 41, 200, 30)
	crenellate(40, 120, 40, 200, 30)
	crenellate(-40, 120, -40, 200, 30)

	-- courtyard dressing
	local treeBase = Vector3.new(-26, 0, 176)
	part({ Name = "DeadTree", Shape = Enum.PartType.Cylinder, Size = Vector3.new(14, 1.8, 1.8), CFrame = CFrame.new(treeBase + Vector3.new(0, 7, 0)) * CFrame.Angles(0, 0, math.pi / 2 + 0.08), Material = MAT.Wood, Color = Color3.fromRGB(40, 34, 30) })
	for i, b in ipairs({ { 9, 0.9, 0.5 }, { 11, -0.8, 2.2 }, { 12.5, 0.7, 3.8 }, { 7, -1.0, 4.9 } }) do
		local y, tilt, yawA = b[1], b[2], b[3]
		part({
			Name = "Branch" .. i,
			Size = Vector3.new(0.5, 6 - i * 0.6, 0.5),
			CFrame = CFrame.new(treeBase + Vector3.new(0, y, 0)) * CFrame.Angles(0, yawA, tilt) * CFrame.new(0, 2.5, 0),
			Material = MAT.Wood,
			Color = Color3.fromRGB(40, 34, 30),
			CanCollide = false,
		})
	end
	-- gallows
	box(-34, 0, 134, -23, 3, 146, MAT.WoodPlanks, COL.Wood, "Gallows")
	box(-33, 3, 139.5, -32, 13, 140.5, MAT.Wood, COL.Wood, "GallowsPost")
	box(-33, 12, 139.5, -26, 13, 140.5, MAT.Wood, COL.Wood, "GallowsBeam")
	part({ Name = "Noose", Size = Vector3.new(0.15, 4, 0.15), CFrame = CFrame.new(-27, 10, 140), Material = MAT.Fabric, Color = COL.Straw, CanCollide = false })
	-- steps up to the gallows
	box(-23, 0, 138, -21, 1, 142, MAT.WoodPlanks, COL.Wood, "GallowsStep")
	box(-23, 1, 138, -22, 2, 142, MAT.WoodPlanks, COL.Wood, "GallowsStep")
	-- crates & broken cart
	for _, c in ipairs({ Vector3.new(32, 0, 190), Vector3.new(34.5, 0, 186), Vector3.new(30, 0, 186.5) }) do
		local s = rng:NextNumber(2.5, 3.5)
		part({ Name = "Crate", Size = Vector3.new(s, s, s), CFrame = CFrame.new(c + Vector3.new(0, s / 2, 0)) * CFrame.Angles(0, rng:NextNumber() * 1.5, 0), Material = MAT.WoodPlanks, Color = COL.Wood })
	end
	part({ Name = "Cart", Size = Vector3.new(5, 1.5, 3), CFrame = CFrame.new(22, 1.2, 132) * CFrame.Angles(0.2, 0.4, 0.15), Material = MAT.WoodPlanks, Color = COL.Wood })
	part({ Name = "Wheel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 2.6, 2.6), CFrame = CFrame.new(24, 0.3, 135) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Wood, Color = COL.Wood })
	pillar(-30, 128, 14, 3, true)
	pillar(28, 158, 14, 3, true)
	remains(Vector3.new(-12, 0, 160))
	remains(Vector3.new(15, 0, 146))
	rubble(Vector3.new(-5, 0, 170), 6, 6)
	-- beam across the yard with hanging cages
	box(-40, 26, 159, 40, 27.5, 161, MAT.Wood, COL.Wood, "YardBeam")
	for _, x in ipairs({ -18, 6, 22 }) do
		chain(Vector3.new(x, 25.8, 160), 6)
		cage(Vector3.new(x, 22.6, 160))
	end
	-- yard torches
	torch(Vector3.new(-38.9, 10, 142), Vector3.new(1, 0, 0))
	torch(Vector3.new(-38.9, 10, 184), Vector3.new(1, 0, 0))
	torch(Vector3.new(38.9, 10, 134), Vector3.new(-1, 0, 0))
	torch(Vector3.new(38.9, 10, 184), Vector3.new(-1, 0, 0))
	torch(Vector3.new(-14, 10, 121.1), Vector3.new(0, 0, 1))
	torch(Vector3.new(14, 10, 121.1), Vector3.new(0, 0, 1))
	torch(Vector3.new(-11, 10, 198.9), Vector3.new(0, 0, -1))
	torch(Vector3.new(11, 10, 198.9), Vector3.new(0, 0, -1))
	ashEmitter(CFrame.new(0, 38, 160), Vector3.new(80, 1, 80), 30)

	-----------------------------------------------------------------------
	-- 5. SHORTCUT GATE between corridor and yard (opens from the yard side)
	-----------------------------------------------------------------------
	do
		local gate = Instance.new("Model")
		gate.Name = "ShortcutGate"
		gate.Parent = map
		local collider = part({ Name = "GateCollider", Size = Vector3.new(14, 14, 0.6), CFrame = CFrame.new(0, 7, 120), Transparency = 1, Parent = gate })
		for x = -6.5, 6.5, 1.0 do
			part({ Name = "GateBar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(14, 0.38, 0.38), CFrame = CFrame.new(x, 7, 120) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Metal, Color = COL.Iron, CanCollide = false, Parent = gate })
		end
		for _, y in ipairs({ 1, 5, 9.5, 13.5 }) do
			part({ Name = "GateRail", Size = Vector3.new(14, 0.4, 0.45), CFrame = CFrame.new(0, y, 120), Material = MAT.Metal, Color = COL.Rust, CanCollide = false, Parent = gate })
		end
		gate.PrimaryPart = collider
		info.Gate = gate

		-- lever on the yard side
		part({ Name = "LeverBase", Size = Vector3.new(1.2, 3, 1.2), CFrame = CFrame.new(9, 1.5, 123.5), Material = MAT.Metal, Color = COL.Iron })
		local pivot = CFrame.new(9, 3, 123.5)
		local handle = part({ Name = "LeverHandle", Size = Vector3.new(0.3, 2.4, 0.3), CFrame = pivot * CFrame.Angles(0, 0, 0.7) * CFrame.new(0, 1.1, 0), Material = MAT.Metal, Color = COL.Rust })
		info.LeverHandle = handle
		info.LeverPivot = pivot
		info.LeverPrompt = prompt(handle, "Pull lever", "Lever", 0.3, 7)

		-- prompt on the corridor side that just says it is locked
		local lockedPart = part({ Name = "GateLockedSide", Size = Vector3.new(4, 4, 0.5), CFrame = CFrame.new(0, 3, 118.8), Transparency = 1, CanCollide = false, CanQuery = false })
		info.LockedPrompt = prompt(lockedPart, "Open", "Iron Gate", 0, 7)
	end

	-----------------------------------------------------------------------
	-- 6. PASSAGE + FOG WALL (z 200..215)
	-----------------------------------------------------------------------
	floor(-8, 200, 8, 216)
	box(8, 0, 200, 10, 14, 215, MAT.Cobblestone, stoneColor(), "Wall")
	box(-10, 0, 200, -8, 14, 215, MAT.Cobblestone, stoneColor(), "Wall")
	ceiling(-10, 200, 10, 215, 14)
	do
		local fog = part({ Name = "FogWall", Size = Vector3.new(16, 14, 0.6), CFrame = CFrame.new(0, 7, 211), Material = MAT.ForceField, Color = COL.Fog, Transparency = 0.05 })
		local pe = Instance.new("ParticleEmitter")
		pe.Rate = 25
		pe.Lifetime = NumberRange.new(2, 3.5)
		pe.Speed = NumberRange.new(0.3, 1.2)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.Size = NumberSequence.new(2.5, 4)
		pe.Transparency = NumberSequence.new(0.75, 1)
		pe.LightEmission = 0.5
		pe.Color = ColorSequence.new(Color3.fromRGB(240, 240, 245))
		pe.Parent = fog
		info.Fog = fog
		info.FogPrompt = prompt(fog, "Traverse the white fog", "Fog Wall", 0.6, 10)
	end

	-----------------------------------------------------------------------
	-- 7. BOSS ARENA (x -45..45, z 215..305)
	-----------------------------------------------------------------------
	floor(-46, 215, 46, 306, MAT.Slate, Color3.fromRGB(50, 48, 45))
	wallX(215, -46, -8, 40)
	wallX(215, 8, 46, 40)
	box(-8, 14, 214, 8, 40, 216, MAT.Cobblestone, stoneColor(), "Wall")
	wallZ(45, 215, 254, 40)
	wallZ(45, 266, 306, 40)
	box(44, 16, 254, 46, 40, 266, MAT.Cobblestone, stoneColor(), "Wall") -- above exit door
	wallZ(-45, 215, 306, 40)
	wallX(305, -46, 46, 40)
	-- roof with a skylight hole in the middle
	box(-46, 40, 215, 46, 42, 245, MAT.Slate, COL.Ceiling, "Roof")
	box(-46, 40, 275, 46, 42, 306, MAT.Slate, COL.Ceiling, "Roof")
	box(-46, 40, 245, -15, 42, 275, MAT.Slate, COL.Ceiling, "Roof")
	box(15, 40, 245, 46, 42, 275, MAT.Slate, COL.Ceiling, "Roof")
	ashEmitter(CFrame.new(0, 39, 260), Vector3.new(28, 1, 28), 18)
	for _, z in ipairs({ 235, 260, 285 }) do
		pillar(-31, z, 40, 4, z == 260)
		pillar(31, z, 40, 4, z == 235)
	end
	brazier(Vector3.new(-20, 0, 228))
	brazier(Vector3.new(20, 0, 228))
	brazier(Vector3.new(-20, 0, 292))
	brazier(Vector3.new(20, 0, 292))
	-- throne dais
	box(-12, 0, 292, 12, 1.5, 304, MAT.Slate, Color3.fromRGB(44, 42, 40), "Dais")
	box(-8, 1.5, 296, 8, 3, 304, MAT.Slate, Color3.fromRGB(40, 38, 36), "Dais")
	box(-4, 3, 298, 4, 6, 302, MAT.Slate, Color3.fromRGB(30, 29, 28), "Throne")
	box(-4, 3, 302, 4, 16, 304, MAT.Slate, Color3.fromRGB(30, 29, 28), "ThroneBack")
	remains(Vector3.new(-6, 1.5, 294))
	remains(Vector3.new(9, 1.5, 295))
	remains(Vector3.new(-25, 0, 270))
	for _, x in ipairs({ -36, -12, 12, 36 }) do
		chain(Vector3.new(x, 39.5, 300), 14)
	end
	-- exit door in the east wall + light beyond it
	floor(46, 253, 52, 267)
	box(46, 0, 252, 52, 16, 253, MAT.Cobblestone, stoneColor(), "Wall")
	box(46, 0, 267, 52, 16, 268, MAT.Cobblestone, stoneColor(), "Wall")
	box(46, 16, 252, 52, 18, 268, MAT.Slate, COL.Ceiling, "Ceiling")
	info.ExitDoor = box(44.2, 0, 254, 45.8, 16, 266, MAT.Metal, Color3.fromRGB(36, 33, 30), "ExitDoor")
	local exitLight = box(50.5, 0, 253, 52, 16, 267, MAT.Neon, Color3.fromRGB(235, 230, 210), "ExitLight")
	local beyond = Instance.new("PointLight")
	beyond.Color = Color3.fromRGB(255, 240, 210)
	beyond.Range = 40
	beyond.Brightness = 3
	beyond.Enabled = false
	beyond.Parent = exitLight
	info.ExitLight = exitLight -- a veil of light; it lifts when the Warden falls (the township lies beyond)

	info.ArenaEntry = CFrame.lookAt(Vector3.new(0, 3.5, 222), Vector3.new(0, 3.5, 262))
	info.BossHome = CFrame.lookAt(Vector3.new(0, 3, 284), Vector3.new(0, 3, 240))

	-----------------------------------------------------------------------
	-- messages from other (absent) players
	-----------------------------------------------------------------------
	message(Vector3.new(-2, 0, 9), "Space to roll. A roll is a moment of invincibility. Roll through the blow, not away from it.")
	message(Vector3.new(2, 0, 38), "Q to lock on. Hold Shift to run. Mind your stamina.")
	message(Vector3.new(24, 0, 90), "Darkness ahead. Ambush ahead.")
	message(Vector3.new(63, -6, 46), "Many hollows ahead. Be wary of being surrounded.")
	message(Vector3.new(0, 0, 205), "Be patient. Strike only after the slam.")

	-----------------------------------------------------------------------
	-- 8. DETAIL PASS: dress every interior wall, the floors and the props
	-----------------------------------------------------------------------
	local detailFolder = Instance.new("Folder")
	detailFolder.Name = "Detail"
	detailFolder.Parent = map
	Detail.init(detailFolder)
	table.insert(avoidSpots, Vector3.new(9, 3, 123.5)) -- lever
	Detail.setAvoid(avoidSpots)
	local face, dress = Detail.face, Detail.dressWall

	-- cell block: south end wall, cell back walls, cell dividers
	dress(face(0, 1, 0, 1), 36, 16, "corridor")
	for i = 0, 9 do
		local cz = i * 12 + 6
		if i ~= 7 then
			dress(face(18, cz, -1, 0), 10.5, 16, "cell") -- east cell back wall (cell 7 is the collapsed one)
		end
		dress(face(-18, cz, 1, 0), 10.5, 16, "cell") -- west cell back wall
	end
	for k = 1, 9 do
		local z = k * 12
		for _, side in ipairs({ 1, -1 }) do
			local cx = side * 12.5
			dress(face(cx, z + 1, 0, 1), 10, 16, "cell")
			dress(face(cx, z - 1, 0, -1), 10, 16, "cell")
		end
	end
	-- corridor: stone arch ribs over each pair of pillars, flagstones and a drain
	for k = 0, 10 do
		Detail.archRib(CFrame.new(0, 0, k * 12), 0, 11, 7, 4.3, 0.9, 1.3, 0, 11, MAT.Cobblestone, COL.Wall, false)
	end
	Detail.floorSeams(-7, 0, 7, 120, 3)
	Detail.floorTiles(-7, 0, 7, 120, 3, 0.22, COL.Floor)
	Detail.gutter(0, 1, 119)
	-- corridor & cell clutter
	Detail.slumpedSkeleton(Vector3.new(-16.6, 0, 66), Vector3.new(1, 0, 0))
	Detail.slumpedSkeleton(Vector3.new(16.6, 0, 102), Vector3.new(-1, 0, 0))
	Detail.bucket(Vector3.new(-16, 0, 2.5))
	Detail.stool(Vector3.new(-10.5, 0, 10.2), true)
	Detail.bucket(Vector3.new(16, 0, 26))
	Detail.stool(Vector3.new(11, 0, 44), false)
	Detail.stool(Vector3.new(-12, 0, 92), true)
	Detail.bucket(Vector3.new(-15.5, 0, 113))
	Detail.bonePile(Vector3.new(-13, 0, 33), 8)
	Detail.bonePile(Vector3.new(13, 0, 75), 6)

	-- drowned sewer: rough rock on every generated wall, cistern in stone
	Detail.setCutouts({ { axis = "X", min = Vector3.new(29, -1, 93), max = Vector3.new(33, 9.4, 96) } })
	for _, run in ipairs(sewerRuns) do
		local r = run.room
		local y = r.ramp and math.min(r.ramp[1], r.ramp[2]) or r.floor
		dress(face(run.px, run.pz, run.nx, run.nz, y), run.len, r.ceil - y, r.name == "Cistern" and "corridor" or "tunnel")
	end
	Detail.setCutouts(nil)
	for _, r in ipairs(SEWER_ROOMS) do
		if not r.ramp and r.name ~= "Cistern" then
			local h = r.ceil - r.floor - 0.4
			local alongZ = (r.z2 - r.z1) >= (r.x2 - r.x1)
			if alongZ then
				for z = r.z1 + 7, r.z2 - 4, 14 do
					Detail.timberFrame(Vector3.new(r.x1 + 0.6, r.floor, z), Vector3.new(r.x2 - 0.6, r.floor, z), h)
				end
			else
				for x = r.x1 + 7, r.x2 - 4, 14 do
					Detail.timberFrame(Vector3.new(x, r.floor, r.z1 + 0.6), Vector3.new(x, r.floor, r.z2 - 0.6), h)
				end
			end
		end
		Detail.stalactites(r.x1 + 1, r.z1 + 1, r.x2 - 1, r.z2 - 1, r.ceil, math.floor((r.x2 - r.x1) * (r.z2 - r.z1) / 40))
	end
	Detail.pipe(Vector3.new(68.2, 3.6, 21), Vector3.new(68.2, 3.6, 44))
	Detail.pipe(Vector3.new(68.2, 3.6, 76), Vector3.new(68.2, 3.6, 109))
	Detail.pipe(Vector3.new(24, 3.6, 8.8), Vector3.new(56, 3.6, 8.8))
	Detail.bonePile(Vector3.new(31, -6, 24), 7)
	Detail.bonePile(Vector3.new(79, -6, 47), 9)
	Detail.bonePile(Vector3.new(47, -6, 73), 6)
	Detail.slumpedSkeleton(Vector3.new(67.6, -6, 100), Vector3.new(-1, 0, 0))

	-- LORE: a dead jailer in the cistern's far corner, a torn page by his hand
	do
		local corner = Vector3.new(80.2, -6, 72.6)
		Detail.slumpedSkeleton(corner, Vector3.new(-1, 0, -0.3).Unit)
		local page = part({
			Name = "TornPage",
			Size = Vector3.new(0.9, 0.04, 1.2),
			CFrame = CFrame.new(78.6, -5.96, 71.8) * CFrame.Angles(0, 0.5, 0.04),
			Material = MAT.Fabric,
			Color = Color3.fromRGB(196, 182, 148),
			CanCollide = false,
		})
		part({ Name = "PageTear", Size = Vector3.new(0.5, 0.045, 0.4), CFrame = CFrame.new(78.95, -5.955, 71.2) * CFrame.Angles(0, 1.1, 0), Material = MAT.Fabric, Color = Color3.fromRGB(170, 156, 120), CanCollide = false, CanQuery = false })
		part({ Name = "CandleStub", Size = Vector3.new(0.3, 0.45, 0.3), CFrame = CFrame.new(79.5, -5.78, 70.9), Material = MAT.SmoothPlastic, Color = Color3.fromRGB(214, 204, 176), CanCollide = false })
		local flame = part({ Name = "CandleFlame", Size = Vector3.new(0.1, 0.2, 0.1), CFrame = CFrame.new(79.5, -5.45, 70.9), Material = MAT.Neon, Color = Color3.fromRGB(255, 170, 80), CanCollide = false, CanQuery = false })
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(255, 170, 90)
		l.Range = 9
		l.Brightness = 1.1
		l.Parent = flame
		addFlicker(l)
		local pp = prompt(page, "Examine", "Torn Page", 0, 7)
		pp:SetAttribute("Title", "Torn Journal Page")
		pp:SetAttribute("Text", table.concat({
			"Fourth night since the bells fell silent.",
			"",
			"She came up through the drowned passage wearing her father's colours - the banner of the Rotten Vanguard, black with mould and weeping at the hem. The Rotten Vanguard's wretched daughter. The Warden barred the ossuary door himself.",
			"",
			"She did not fight him. She only wept. Where her tears struck the stone, the stone grew soft, and where she touched the bones in the niches, they turned to look at her.",
			"",
			"He held the door three days. On the fourth his mace grew too heavy to lift, and he knelt to rest, and she kissed his brow as a daughter would a father.",
			"",
			"He rose again before dawn. He guards the ossuary still. But it is not the dead he keeps in now - it is us he keeps out.",
			"",
			"If you are reading this, do not pity him. Free him.",
		}, "\n"))
		table.insert(notes, pp)
	end
	Detail.bonePile(Vector3.new(67, 0, 158), 6)

	-- ashen yard: buttressed brick walls, windows, banners, ivy
	dress(face(-23.5, 121, 0, 1), 33, 30, "yard")
	dress(face(23.5, 121, 0, 1), 33, 30, "yard")
	dress(face(-24, 199, 0, -1), 32, 30, "yard")
	dress(face(24, 199, 0, -1), 32, 30, "yard")
	-- (the doorway to the Usher's Walk is cut out of this wall's dressing)
	Detail.setCutouts({ { min = Vector3.new(-41, -1, 156), max = Vector3.new(-34, 12.4, 164) } })
	dress(face(-39, 160, 1, 0), 80, 30, "yard")
	Detail.setCutouts(nil)
	dress(face(39, 135, -1, 0), 30, 30, "yard")
	dress(face(39, 181, -1, 0), 38, 30, "yard")
	-- arches framing the gate and the passage to the fog
	Detail.archRib(Detail.face(0, 121, 0, 1), 0, 10.5, 7.6, 3.6, 1.2, 1.4, 0.7, 11, MAT.Cobblestone, COL.Wall, false)
	Detail.archRib(Detail.face(0, 199, 0, -1), 0, 10.5, 8.6, 3.6, 1.2, 1.4, 0.7, 11, MAT.Cobblestone, COL.Wall, false)
	Detail.archRib(Detail.face(39, 156, -1, 0), 0, 7.5, 6.6, 3.2, 1.0, 1.2, 0.6, 9, MAT.Cobblestone, COL.Wall, false)
	-- a paved path from the gate to the fog, weeds pushing through
	Detail.floorSeams(-5, 121, 5, 199, 2.5, Color3.fromRGB(34, 32, 30))
	Detail.floorTiles(-5, 121, 5, 199, 2.5, 0.6, Color3.fromRGB(78, 74, 68))
	for _ = 1, 26 do
		local side = rng:NextNumber() < 0.5 and -1 or 1
		Detail.weeds(Vector3.new(side * rng:NextNumber(5.2, 7), 0, rng:NextNumber(123, 197)), rng:NextInteger(2, 5))
	end
	for _ = 1, 18 do
		Detail.weeds(Vector3.new(rng:NextNumber(-37, 37), 0, rng:NextNumber(123, 197)), rng:NextInteger(2, 4))
	end
	-- graveyard corner, a well, barrels
	for gx = 0, 2 do
		for gz = 0, 1 do
			Detail.gravestone(Vector3.new(27 + gx * 3.6, 0, 172 + gz * 6.5), math.pi + rng:NextNumber(-0.15, 0.15))
		end
	end
	Detail.well(Vector3.new(-17, 0, 189))
	Detail.barrel(Vector3.new(36, 0, 194), false)
	Detail.barrel(Vector3.new(33.3, 0, 195.5), false)
	Detail.barrel(Vector3.new(31, 0, 182), true)
	Detail.bonePile(Vector3.new(-28, 0, 128), 9)
	Detail.bonePile(Vector3.new(12, 0, 192), 6)

	-- passage to the fog: stones and a pair of ribs
	dress(face(8, 207.5, -1, 0), 15, 14, "corridor")
	dress(face(-8, 207.5, 1, 0), 15, 14, "corridor")

	-- the ossuary: skull niches, pilasters, gothic windows
	dress(face(-26.5, 216, 0, 1), 37, 40, "ossuary")
	dress(face(26.5, 216, 0, 1), 37, 40, "ossuary")
	dress(face(0, 304, 0, -1), 88, 40, "ossuary")
	dress(face(-44, 260, 1, 0), 88, 40, "ossuary")
	dress(face(44, 235, -1, 0), 38, 40, "ossuary")
	dress(face(44, 285, -1, 0), 38, 40, "ossuary")
	Detail.archRib(Detail.face(44, 260, -1, 0), 0, 12, 6.6, 4, 1.2, 1.4, 0.7, 11, MAT.Limestone, Detail.Colors.Ossuary, false)
	Detail.floorSeams(-44, 216, 44, 304, 4)
	Detail.floorTiles(-44, 216, 44, 304, 4, 0.16, Color3.fromRGB(62, 60, 56))
	Detail.ritualCircle(Vector3.new(0, 0, 260), 12)
	Detail.chandelier(Vector3.new(0, 30, 232), 40)
	Detail.chandelier(Vector3.new(0, 30, 290), 40)
	for _, bp in ipairs({ Vector3.new(-40, 0, 222), Vector3.new(40, 0, 222), Vector3.new(-40, 0, 300), Vector3.new(40, 0, 300), Vector3.new(-41, 0, 250), Vector3.new(-41, 0, 276), Vector3.new(41, 0, 276) }) do
		Detail.bonePile(bp, 10)
	end

	-----------------------------------------------------------------------
	-- 9. THE USHER'S WALK + THE BLIND CHAPEL (through the yard's west wall)
	--    hallway x -86..-41, z 156..164 (ceiling 12), lectern alcove on the north side
	--    chapel  x -136..-86, z 134..186 (ceiling 28), altar at the west end
	--    The rot spreads from the altar, over the floor where she kneels, and
	--    thins out down the hallway until a few tendrils reach the yard.
	-----------------------------------------------------------------------
	do
		local oldRng = rng
		rng = Random.new(9061) -- own random streams: nothing built above shifts
		local oldDetailRng = Detail.useRng(Random.new(5150))
		local Rot = Detail.Rot

		-- hallway shell
		floor(-86, 155, -41, 165, MAT.Slate, Color3.fromRGB(46, 46, 42))
		box(-84, 0, 154, -39, 14, 156, MAT.Cobblestone, stoneColor(), "Wall")
		box(-84, 0, 164, -66, 14, 166, MAT.Cobblestone, stoneColor(), "Wall")
		box(-60, 0, 164, -39, 14, 166, MAT.Cobblestone, stoneColor(), "Wall")
		box(-68, 0, 166, -66, 14, 171, MAT.Cobblestone, stoneColor(), "Wall") -- alcove
		box(-60, 0, 166, -58, 14, 171, MAT.Cobblestone, stoneColor(), "Wall")
		box(-68, 0, 171, -58, 14, 173, MAT.Cobblestone, stoneColor(), "Wall")
		floor(-66, 165, -60, 171, MAT.Slate, Color3.fromRGB(46, 46, 42))
		ceiling(-84, 154, -39, 166, 12)
		ceiling(-68, 165, -58, 173, 12)

		-- chapel shell
		local chapelStone = Color3.fromRGB(58, 57, 52)
		floor(-137, 133, -86, 187, MAT.Slate, Color3.fromRGB(42, 43, 39))
		box(-138, 0, 132, -84, 28, 134, MAT.Cobblestone, chapelStone:Lerp(COL.WallDark, rng:NextNumber() * 0.4), "Wall") -- south
		-- north, around the sealed door to the Usher's Reliquary (x -116..-108, 12 high);
		-- one colour draw for all three pieces so the random stream below is unchanged
		local northStone = chapelStone:Lerp(COL.WallDark, rng:NextNumber() * 0.4)
		box(-138, 0, 186, -116, 28, 188, MAT.Cobblestone, northStone, "Wall")
		box(-108, 0, 186, -84, 28, 188, MAT.Cobblestone, northStone, "Wall")
		box(-116, 12, 186, -108, 28, 188, MAT.Cobblestone, northStone, "Wall")
		box(-138, 0, 134, -136, 28, 186, MAT.Cobblestone, chapelStone:Lerp(COL.WallDark, rng:NextNumber() * 0.4), "Wall") -- west
		box(-86, 0, 134, -84, 28, 156, MAT.Cobblestone, chapelStone, "Wall") -- east, around the door
		box(-86, 0, 164, -84, 28, 186, MAT.Cobblestone, chapelStone, "Wall")
		box(-86, 12, 156, -84, 28, 164, MAT.Cobblestone, chapelStone, "Wall")
		-- roof, broken open above the altar
		box(-138, 28, 132, -84, 30, 155, MAT.Slate, COL.Ceiling, "Roof")
		box(-138, 28, 165, -84, 30, 188, MAT.Slate, COL.Ceiling, "Roof")
		box(-138, 28, 155, -135, 30, 165, MAT.Slate, COL.Ceiling, "Roof")
		box(-127, 28, 155, -84, 30, 165, MAT.Slate, COL.Ceiling, "Roof")
		for _, bz in ipairs({ 142, 178 }) do
			box(-136, 24.5, bz - 0.6, -86, 25.7, bz + 0.6, MAT.Wood, COL.Wood, "Rafter")
		end
		part({ Name = "FallenRafter", Size = Vector3.new(1.2, 1.2, 15), CFrame = CFrame.new(-104, 0.7, 150) * CFrame.Angles(0.04, 0.5, 0.06), Material = MAT.Wood, Color = COL.Wood, CanCollide = false })
		pillar(-126, 144, 28, 3)
		pillar(-126, 176, 28, 3)
		pillar(-98, 144, 28, 3)
		pillar(-98, 176, 28, 3, true)

		-- the altar, swallowed by the growth it fed
		box(-136, 0, 148, -127, 1, 172, MAT.Slate, Color3.fromRGB(48, 47, 43), "Dais")
		box(-136, 1, 152, -130, 2, 168, MAT.Slate, Color3.fromRGB(44, 43, 40), "Dais")
		box(-135, 2, 156, -131, 5, 164, MAT.Slate, Color3.fromRGB(38, 37, 34), "Altar")
		for _ = 1, 16 do
			local s = rng:NextNumber(1.6, 4.6)
			part({
				Name = "RotMass",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(s, s * rng:NextNumber(0.75, 1), s),
				CFrame = CFrame.new(-133 + rng:NextNumber(-2.2, 2.2), rng:NextNumber(2.5, 8.5), 160 + rng:NextNumber(-4.5, 4.5)),
				Material = rng:NextNumber() < 0.5 and MAT.CrackedLava or MAT.SmoothPlastic,
				Color = Rot.Flesh:Lerp(Rot.FleshDark, rng:NextNumber()),
				Reflectance = 0.1,
				CanCollide = false,
			})
		end
		local heart = part({ Name = "RotHeart", Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 3, 2.6), CFrame = CFrame.new(-132, 6.2, 160), Material = MAT.Neon, Color = Rot.Glow, Transparency = 0.3, CanCollide = false })
		local heartLight = Instance.new("PointLight")
		heartLight.Color = Color3.fromRGB(190, 180, 100)
		heartLight.Range = 26
		heartLight.Brightness = 1.6
		heartLight.Parent = heart
		CollectionService:AddTag(heartLight, "Pulse")
		heartLight:SetAttribute("Base", heartLight.Brightness)
		info.UsherHeart = heartLight
		-- candles the rot has not reached yet
		for _, cp in ipairs({ Vector3.new(-129.5, 2, 153.5), Vector3.new(-129.5, 2, 166.5), Vector3.new(-128, 1, 150), Vector3.new(-128, 1, 170) }) do
			part({ Name = "Candle", Size = Vector3.new(0.35, 1.1, 0.35), CFrame = CFrame.new(cp + Vector3.new(0, 0.55, 0)), Material = MAT.SmoothPlastic, Color = Color3.fromRGB(200, 190, 160), CanCollide = false })
			local f = part({ Name = "CandleFlame", Size = Vector3.new(0.12, 0.25, 0.12), CFrame = CFrame.new(cp + Vector3.new(0, 1.25, 0)), Material = MAT.Neon, Color = Color3.fromRGB(255, 170, 80), CanCollide = false, CanQuery = false })
			local l = Instance.new("PointLight")
			l.Color = Color3.fromRGB(255, 170, 90)
			l.Range = 10
			l.Brightness = 1.1
			l.Parent = f
			addFlicker(l)
		end
		-- pale light falling through the broken roof onto the altar
		local hole = part({ Name = "RoofHoleLight", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(-131, 27.5, 160), Transparency = 1, CanCollide = false, CanQuery = false })
		local spot = Instance.new("SpotLight")
		spot.Face = Enum.NormalId.Bottom
		spot.Color = Color3.fromRGB(175, 185, 195)
		spot.Brightness = 2.2
		spot.Range = 34
		spot.Angle = 50
		spot.Shadows = true
		spot.Parent = hole
		part({ Name = "LightShaft", Size = Vector3.new(6, 28, 7), CFrame = CFrame.new(-131, 14, 160), Material = MAT.Neon, Color = Color3.fromRGB(180, 190, 200), Transparency = 0.95, CanCollide = false, CanQuery = false, CastShadow = false })
		ashEmitter(CFrame.new(-131, 27, 160), Vector3.new(7, 1, 8), 6)
		-- a sickly wash over the whole chapel so the fight stays readable
		local fill = part({ Name = "ChapelFill", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(-110, 20, 160), Transparency = 1, CanCollide = false, CanQuery = false })
		local fl = Instance.new("PointLight")
		fl.Color = Color3.fromRGB(150, 156, 122)
		fl.Range = 48
		fl.Brightness = 0.7
		fl.Parent = fill
		-- torches by the door, guttering
		torch(Vector3.new(-86.9, 8, 148), Vector3.new(-1, 0, 0))
		torch(Vector3.new(-86.9, 8, 172), Vector3.new(-1, 0, 0))
		-- the hallway: one torch still lit near the yard, one long drowned in mould
		torch(Vector3.new(-48, 7.5, 156.9), Vector3.new(0, 0, 1))
		part({ Name = "TorchBracket", Size = Vector3.new(0.25, 0.25, 1.4), CFrame = CFrame.new(-70, 7.5, 163.3), Material = MAT.Metal, Color = COL.Iron })
		part({ Name = "DeadTorch", Size = Vector3.new(0.35, 1.4, 0.35), CFrame = CFrame.new(-70, 8, 162.6) * CFrame.Angles(0.3, 0, 0), Material = MAT.Wood, Color = Color3.fromRGB(26, 22, 18), CanCollide = false })
		-- spores drifting in the stale air
		local function spores(cf, size, rate)
			local p = part({ Name = "Spores", Size = size, CFrame = cf, Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
			local pe = Instance.new("ParticleEmitter")
			pe.Rate = rate
			pe.Lifetime = NumberRange.new(7, 12)
			pe.Speed = NumberRange.new(0.1, 0.5)
			pe.SpreadAngle = Vector2.new(180, 180)
			pe.Size = NumberSequence.new(0.14)
			pe.Color = ColorSequence.new(Color3.fromRGB(196, 190, 128))
			pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.35), NumberSequenceKeypoint.new(0.8, 0.45), NumberSequenceKeypoint.new(1, 1) })
			pe.LightEmission = 0.35
			pe.LightInfluence = 0.6
			pe.Acceleration = Vector3.new(0, 0.08, 0)
			pe.RotSpeed = NumberRange.new(-20, 20)
			pcall(function()
				pe.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
			end)
			pe.Parent = p
		end
		spores(CFrame.new(-111, 10, 160), Vector3.new(48, 18, 50), 22)
		spores(CFrame.new(-70, 5, 160), Vector3.new(30, 8, 7), 5)

		-- glowing growths that breathe light (client pulses anything tagged "Pulse")
		for _, gp in ipairs({ Vector3.new(-135, 3, 140), Vector3.new(-135, 4, 180), Vector3.new(-110, 2, 135), Vector3.new(-116, 3, 185), Vector3.new(-88, 2.5, 139), Vector3.new(-120, 0.5, 160), Vector3.new(-80, 1, 157), Vector3.new(-94, 2, 184) }) do
			local g = part({ Name = "GlowGrowth", Shape = Enum.PartType.Ball, Size = Vector3.new(1.3, 1.3, 1.3), CFrame = CFrame.new(gp), Material = MAT.Neon, Color = Rot.Glow, Transparency = 0.35, CanCollide = false })
			local l = Instance.new("PointLight")
			l.Color = Color3.fromRGB(176, 172, 96)
			l.Range = 16
			l.Brightness = 1
			l.Parent = g
			l:SetAttribute("Base", l.Brightness)
			CollectionService:AddTag(l, "Pulse")
			Detail.boils(Vector3.new(gp.X, math.max(0, gp.Y - 1.2), gp.Z), 6, 1.6, 0.2)
		end

		-- lore: the chapel register, open on its lectern in the hallway alcove
		do
			local book = Detail.lectern(Vector3.new(-63, 0, 168.5), Vector3.new(0, 0, -1))
			local pp = prompt(book, "Examine", "Chapel Register", 0, 7)
			pp:SetAttribute("Title", "The Usher's Register")
			pp:SetAttribute("Text", table.concat({
				"Oculast kept the chapel door. She walked the condemned in to their last rites, a lamp in one hand and the harvest-blade in the other, and she had a kind word for every one of them.",
				"",
				"When the Rotten Vanguard's wretched daughter came weeping up from the yard, the Usher barred the aisle and would not let her pass to the altar.",
				"",
				"So the daughter took her eyes instead. Gently, with her thumbs, the way one closes the eyes of the dead. Where her tears fell, the stone grew soft, and something took root in the empty sockets.",
				"",
				"Oculast kneels there still, facing the altar, waiting for someone to tell her who has come.",
				"",
				"Do not run in the chapel. She hears what she cannot see.",
			}, "\n"))
			table.insert(notes, pp)
		end
		message(Vector3.new(-50, 0, 160.5), "Walk, don't run. She hears what she cannot see.")

		-- dressing: the chapel walls are thick with it, the hallway less so toward the yard
		Detail.dressWall(Detail.face(-111, 134, 0, 1), 50, 28, "rot", 1)
		Detail.setCutouts({ { axis = "X", min = Vector3.new(-116, -1, 184), max = Vector3.new(-108, 12.4, 189) } })
		Detail.dressWall(Detail.face(-111, 186, 0, -1), 50, 28, "rot", 1)
		Detail.setCutouts(nil)
		Detail.dressWall(Detail.face(-136, 143, 1, 0), 10, 28, "rot", 1)
		Detail.dressWall(Detail.face(-136, 177, 1, 0), 10, 28, "rot", 1)
		Detail.dressWall(Detail.face(-86, 145, -1, 0), 22, 28, "rot", 0.9)
		Detail.dressWall(Detail.face(-86, 175, -1, 0), 22, 28, "rot", 0.9)
		Detail.window(Detail.face(-136, 160, 1, 0), 0, 13, 5, 8, true)
		Detail.archRib(Detail.face(-86, 160, -1, 0), 0, 8.8, 4.6, 3, 1.1, 1.3, 0.6, 9, MAT.Cobblestone, chapelStone, false)
		Detail.archRib(Detail.face(-84, 160, 1, 0), 0, 8.8, 4.6, 3, 1.1, 1.3, 0.6, 9, MAT.Cobblestone, chapelStone, false)
		Detail.archRib(Detail.face(-39, 160, 1, 0), 0, 8.8, 4.6, 3, 1.2, 1.4, 0.7, 9, MAT.Cobblestone, COL.Wall, false)
		Detail.floorSeams(-136, 134, -86, 186, 4, Color3.fromRGB(26, 26, 22))
		Detail.floorTiles(-136, 134, -86, 186, 4, 0.14, Color3.fromRGB(56, 56, 50))
		for i, seg in ipairs({ { -78.5, 15 }, { -63.5, 15 }, { -48.5, 15 } }) do
			local k = ({ 1, 0.55, 0.2 })[i]
			Detail.dressWall(Detail.face(seg[1], 156, 0, 1), seg[2], 12, "rot", k)
		end
		Detail.dressWall(Detail.face(-75, 164, 0, -1), 18, 12, "rot", 0.85)
		Detail.dressWall(Detail.face(-50.5, 164, 0, -1), 19, 12, "rot", 0.25)
		Detail.dressWall(Detail.face(-63, 171, 0, -1), 6, 12, "rot", 0.5)

		-- the rot itself: thick trunks from the altar, out over the chapel floor,
		-- under where she kneels, through the door and down the hallway
		local chapel = { -135.5, 134.5, -86.5, 185.5 }
		for i = 0, 9 do
			local a = (i / 10) * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
			Detail.rotVein(Vector3.new(-128.5 + math.cos(a) * 1.5, 1, 160 + math.sin(a) * 4), a, rng:NextNumber(4, 7), 0.85, 0, chapel)
		end
		for i = 0, 11 do
			local a = (i / 12) * math.pi * 1.6 - math.pi * 0.8 + rng:NextNumber(-0.15, 0.15)
			Detail.rotVein(Vector3.new(-126.5, 0, 160 + math.sin(a) * 9), a, rng:NextNumber(18, 38), rng:NextNumber(0.6, 0.9), 3, chapel)
		end
		-- the trunk that runs to the door and on down the hallway
		Detail.rotVein(Vector3.new(-126.5, 0, 159), 0, 42, 0.95, 3, chapel)
		local hall = { -86, 156.6, -41.5, 163.4 }
		Detail.rotVein(Vector3.new(-87, 0, 158), 0.05, 44, 0.85, 2, hall)
		Detail.rotVein(Vector3.new(-87, 0, 162.5), -0.05, 36, 0.7, 2, hall)
		Detail.rotVein(Vector3.new(-86, 12, 160), 0, 30, 0.6, 2, hall, true)
		-- the first thin tendrils reaching out into the yard
		local yard = { -40.5, 153, -33, 167 }
		for _, z in ipairs({ 157.5, 160.5, 163 }) do
			Detail.rotVein(Vector3.new(-41.5, 0, z), rng:NextNumber(-0.4, 0.4), rng:NextNumber(3, 6), 0.22, 1, yard)
		end
		-- thickest where she kneels
		for i = 0, 7 do
			local a = i / 8 * math.pi * 2
			Detail.rotVein(Vector3.new(-114 + math.cos(a) * 1.2, 0, 160 + math.sin(a) * 1.2), a, rng:NextNumber(5, 9), 0.55, 1, chapel)
		end
		Detail.rotPatches(-118, 157, -110, 163, 6)
		Detail.rotPatches(-136, 135, -98, 185, 40)
		Detail.rotPatches(-98, 140, -86, 180, 12)
		Detail.rotPatches(-86, 156.5, -66, 163.5, 12)
		Detail.rotPatches(-66, 156.5, -50, 163.5, 4)
		Detail.strands(-135, 135, -87, 185, 28, 40)
		Detail.strands(-84, 156.5, -55, 163.5, 12, 24)
		Detail.boils(Vector3.new(-84, 0, 157.2), 9, 1.4, 0.15)
		Detail.boils(Vector3.new(-84, 0, 163), 7, 1.2, 0.1)
		Detail.boils(Vector3.new(-74, 0, 157.2), 5, 1.0, 0)
		for _, pz in ipairs({ { -123, 147, 7, 1.2 }, { -118, 172, 6, 0.5 }, { -104, 165, 5, 0.3 }, { -95, 152, 4, 2.1 }, { -77, 160, 3, 0.2 } }) do
			Detail.puddle(Vector3.new(pz[1], 0, pz[2]), pz[3], pz[3] * 0.6, pz[4])
		end
		-- pews, mostly broken and pushed to the walls
		Detail.pew(Vector3.new(-104, 0, 139.5), math.pi / 2, 8, false)
		Detail.pew(Vector3.new(-96, 0, 139.5), math.pi / 2, 8, true)
		Detail.pew(Vector3.new(-104, 0, 180.5), math.pi / 2, 8, true)
		Detail.pew(Vector3.new(-96, 0, 180.5), math.pi / 2, 8, false)
		Detail.pew(Vector3.new(-117, 0, 138.5), math.pi / 2 + 0.3, 7, true)
		-- those who came before, half swallowed
		Detail.overgrownCorpse(Vector3.new(-134.6, 0, 139), Vector3.new(1, 0, 0.2).Unit)
		Detail.overgrownCorpse(Vector3.new(-130, 0, 185), Vector3.new(0, 0, -1)) -- clear of the reliquary door
		Detail.overgrownCorpse(Vector3.new(-88, 0, 181), Vector3.new(-1, 0, -0.3).Unit)
		Detail.overgrownCorpse(Vector3.new(-79, 0, 163.3), Vector3.new(0, 0, -1))
		Detail.bonePile(Vector3.new(-121, 0, 182), 8)
		Detail.bonePile(Vector3.new(-90, 0, 136), 6)

		rng = oldRng
		Detail.useRng(oldDetailRng)
	end
	info.Usher = {
		Home = CFrame.lookAt(Vector3.new(-114, 3, 160), Vector3.new(-140, 3, 160)), -- kneeling, her back to the door
		Min = Vector3.new(-135, 0, 135),
		Max = Vector3.new(-87, 0, 185),
	}

	-----------------------------------------------------------------------
	-- 9b. THE USHER'S RELIQUARY (north out of the chapel, sealed until she falls)
	--     gate at z 187, hallway x -116..-108, z 188..206 (ceiling 12), then a
	--     room x -124..-100, z 206..222 (ceiling 14) with her chest at the far end.
	--     The gate rises when she dies (Oculast.lua, onDied).
	-----------------------------------------------------------------------
	do
		local oldRng = rng
		rng = Random.new(7127)
		local oldDetailRng = Detail.useRng(Random.new(7128))

		-- hallway
		floor(-117, 188, -107, 206, MAT.Slate, Color3.fromRGB(44, 44, 40))
		box(-118, 0, 188, -116, 14, 206, MAT.Cobblestone, stoneColor(), "Wall")
		box(-108, 0, 188, -106, 14, 206, MAT.Cobblestone, stoneColor(), "Wall")
		ceiling(-118, 188, -106, 206, 12)
		-- room
		floor(-125, 205, -99, 223, MAT.Slate, Color3.fromRGB(44, 44, 40))
		box(-126, 0, 204, -116, 16, 206, MAT.Cobblestone, stoneColor(), "Wall")
		box(-108, 0, 204, -98, 16, 206, MAT.Cobblestone, stoneColor(), "Wall")
		box(-126, 0, 222, -98, 16, 224, MAT.Cobblestone, stoneColor(), "Wall")
		box(-126, 0, 206, -124, 16, 222, MAT.Cobblestone, stoneColor(), "Wall")
		box(-100, 0, 206, -98, 16, 222, MAT.Cobblestone, stoneColor(), "Wall")
		ceiling(-126, 204, -98, 224, 14)

		-- the gate (same build as the shortcut gate)
		local gate = Instance.new("Model")
		gate.Name = "ReliquaryGate"
		gate.Parent = map
		local collider = part({ Name = "GateCollider", Size = Vector3.new(8, 12, 0.6), CFrame = CFrame.new(-112, 6, 187), Transparency = 1, Parent = gate })
		for x = -115.5, -108.5, 1.0 do
			part({ Name = "GateBar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(12, 0.38, 0.38), CFrame = CFrame.new(x, 6, 187) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Metal, Color = COL.Iron, CanCollide = false, Parent = gate })
		end
		for _, y in ipairs({ 1, 5, 9.5, 11.5 }) do
			part({ Name = "GateRail", Size = Vector3.new(8, 0.4, 0.45), CFrame = CFrame.new(-112, y, 187), Material = MAT.Metal, Color = COL.Rust, CanCollide = false, Parent = gate })
		end
		gate.PrimaryPart = collider
		info.UsherGate = gate

		-- the chest, against the north wall, facing the way in: a hollow box of warped,
		-- greyed planks (gaps between them), rusted straps and corner caps, moss on the lid.
		-- The lid is its own model hinged at the back edge (init.server swings it open).
		local cx, cz = -112, 218.5
		local W, H, DP, T = 4, 2, 2.6, 0.22 -- outer width, height, depth; plank thickness
		local base = CFrame.new(cx, 0, cz)
		local rust = Color3.fromRGB(78, 52, 36)
		local function plankColor()
			return Color3.fromRGB(72, 52, 36):Lerp(Color3.fromRGB(58, 56, 50), rng:NextNumber(0.2, 0.75)) -- greyed with age
		end
		local function warp()
			return CFrame.Angles(rng:NextNumber(-0.025, 0.025), 0, rng:NextNumber(-0.02, 0.02))
		end
		local function slab(name, size, cf, color, mat, parent, solid)
			return part({ Name = name, Size = size, CFrame = cf, Material = mat or MAT.WoodPlanks, Color = color or plankColor(), CanCollide = solid ~= false, Parent = parent })
		end
		-- body: a dark floor and four walls, each two planks high
		slab("ChestFloor", Vector3.new(W - 2 * T, T, DP - 2 * T), base * CFrame.new(0, T / 2, 0), Color3.fromRGB(28, 23, 18))
		slab("ChestDust", Vector3.new(W * 0.5, 0.06, DP * 0.4), base * CFrame.new(-0.4, T + 0.03, 0.2) * CFrame.Angles(0, 0.3, 0), Color3.fromRGB(64, 60, 52), MAT.Sand, nil, false)
		for _, side in ipairs({ { 0, -(DP - T) / 2, W, false }, { 0, (DP - T) / 2, W, false }, { -(W - T) / 2, 0, DP - 2 * T, true }, { (W - T) / 2, 0, DP - 2 * T, true } }) do
			local x, z, len, alongZ = side[1], side[2], side[3], side[4]
			local h = H / 2
			for k = 0, 1 do
				local size = alongZ and Vector3.new(T, h - 0.05, len) or Vector3.new(len, h - 0.05, T)
				slab("ChestPlank", size, base * CFrame.new(x, h * k + h / 2, z) * warp())
			end
		end
		-- rusted straps over the front and back, iron caps on the four corners, the lock plate
		for _, bx in ipairs({ -1.3, 1.3 }) do
			for _, sz in ipairs({ -1, 1 }) do
				slab("ChestStrap", Vector3.new(0.3, H + 0.04, 0.06), base * CFrame.new(bx, H / 2, sz * (DP / 2 + 0.03)), rust, MAT.CorrodedMetal, nil, false)
			end
		end
		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				slab("ChestCorner", Vector3.new(0.3, H + 0.04, 0.3), base * CFrame.new(sx * (W / 2 - 0.1), H / 2, sz * (DP / 2 - 0.1)), COL.Iron, MAT.CorrodedMetal, nil, false)
			end
		end
		slab("ChestLock", Vector3.new(0.55, 0.6, 0.08), base * CFrame.new(0, H - 0.35, -(DP / 2 + 0.05)), rust, MAT.CorrodedMetal, nil, false)

		-- lid: three warped planks over a shallow rim, straps, a hasp, and moss
		local lid = Instance.new("Model")
		lid.Name = "ChestLid"
		lid.Parent = map
		local LW, LD, LT, RIM = W + 0.1, DP + 0.1, 0.18, 0.24
		local top = H + RIM + LT
		for k = 0, 2 do
			local pw = LD / 3
			slab("LidPlank", Vector3.new(LW, LT, pw - 0.04), base * CFrame.new(0, top - LT / 2, -LD / 2 + pw * (k + 0.5)) * warp(), nil, nil, lid, false)
		end
		for _, r in ipairs({ { 0, -(LD - T) / 2, LW, T }, { 0, (LD - T) / 2, LW, T }, { -(LW - T) / 2, 0, T, LD - 2 * T }, { (LW - T) / 2, 0, T, LD - 2 * T } }) do
			slab("LidRim", Vector3.new(r[3], RIM, r[4]), base * CFrame.new(r[1], H + RIM / 2, r[2]), nil, nil, lid, false)
		end
		for _, bx in ipairs({ -1.3, 1.3 }) do
			slab("LidStrap", Vector3.new(0.3, 0.05, LD + 0.04), base * CFrame.new(bx, top + 0.02, 0), rust, MAT.CorrodedMetal, lid, false)
		end
		slab("LidHasp", Vector3.new(0.4, 0.5, 0.06), base * CFrame.new(0, H + 0.05, -(LD / 2 + 0.04)), rust, MAT.CorrodedMetal, lid, false)
		for _, m in ipairs({ { 1.5, -0.6, 0.9 }, { -1.1, 0.7, 0.6 } }) do
			slab("LidMoss", Vector3.new(m[3], 0.05, m[3] * 0.7), base * CFrame.new(m[1], top + 0.02, m[2]) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0), Color3.fromRGB(62, 70, 46), MAT.Grass, lid, false)
		end
		lid.PrimaryPart = lid:FindFirstChild("LidPlank")
		local hinge = base * CFrame.new(0, H, LD / 2)
		local promptAt = part({ Name = "ChestPrompt", Size = Vector3.new(1, 1, 1), CFrame = base * CFrame.new(0, 1, 0), Transparency = 1, CanCollide = false, CanQuery = false })
		info.UsherChest = { Lid = lid, Hinge = hinge, Prompt = prompt(promptAt, "Open", "Chest", 0.5, 7) }

		torch(Vector3.new(-123.1, 8, 214), Vector3.new(1, 0, 0))
		torch(Vector3.new(-100.9, 8, 214), Vector3.new(-1, 0, 0))
		Detail.dressWall(Detail.face(-116, 197, 1, 0), 18, 12, "rot", 0.5)
		Detail.dressWall(Detail.face(-108, 197, -1, 0), 18, 12, "rot", 0.5)
		Detail.dressWall(Detail.face(-112, 222, 0, -1), 24, 14, "rot", 0.25)
		Detail.floorSeams(-124, 206, -100, 222, 4, Color3.fromRGB(26, 26, 22))

		rng = oldRng
		Detail.useRng(oldDetailRng)
	end

	-----------------------------------------------------------------------
	-- 10. WICK'S NOOK (north out of the Upper Drain)
	--     passage x 29..33, z 95..104 (ceiling 9), then a little room x 29..47,
	--     z 104..117 (ceiling 10): candles, a worn rug, chalk on the wall, and
	--     Wick, sitting on a crate as if she'd been expecting you.
	-----------------------------------------------------------------------
	do
		local oldRng = rng
		rng = Random.new(31337)
		local oldDetailRng = Detail.useRng(Random.new(8128))
		local stone = Color3.fromRGB(62, 60, 55)
		local function wall(x1, z1, x2, z2, h)
			box(x1, 0, z1, x2, h, z2, MAT.Cobblestone, stone:Lerp(COL.WallDark, rng:NextNumber() * 0.4), "Wall")
		end
		-- passage
		floor(29, 96.9, 33, 104, MAT.Slate, Color3.fromRGB(46, 46, 42))
		wall(27, 96.9, 29, 104, 11)
		wall(33, 96.9, 35, 104, 11)
		ceiling(27, 96.9, 35, 104, 9)
		-- room
		floor(29, 104, 47, 117, MAT.Slate, Color3.fromRGB(48, 47, 43))
		wall(27, 104, 29, 119, 12)
		wall(33, 102, 49, 104, 12)
		wall(47, 104, 49, 119, 12)
		wall(29, 117, 47, 119, 12)
		ceiling(27, 102, 49, 119, 10)
		-- light: candlelight only, warm and low
		local function candle(pos, lit)
			local h = rng:NextNumber(0.35, 1.0)
			part({ Name = "Candle", Size = Vector3.new(0.28, h, 0.28), CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)), Material = MAT.SmoothPlastic, Color = Color3.fromRGB(214, 202, 172), CanCollide = false })
			part({ Name = "CandleDrip", Size = Vector3.new(0.5, 0.05, 0.5), CFrame = CFrame.new(pos + Vector3.new(0, 0.025, 0)), Material = MAT.SmoothPlastic, Color = Color3.fromRGB(200, 188, 158), CanCollide = false, CanQuery = false })
			local f = part({ Name = "CandleFlame", Size = Vector3.new(0.12, 0.24, 0.12), CFrame = CFrame.new(pos + Vector3.new(0, h + 0.14, 0)), Material = MAT.Neon, Color = Color3.fromRGB(255, 172, 84), CanCollide = false, CanQuery = false })
			if lit then
				local l = Instance.new("PointLight")
				l.Color = Color3.fromRGB(255, 168, 92)
				l.Range = 13
				l.Brightness = 1.2
				l.Parent = f
				addFlicker(l)
			end
		end
		-- crates (one is her seat), a low shelf, a worn rug
		local seat = Vector3.new(43, 0, 112)
		box(seat.X - 1.2, 0, seat.Z - 1.2, seat.X + 1.2, 1.4, seat.Z + 1.2, MAT.WoodPlanks, COL.Wood, "Crate")
		box(45.2, 0, 114.4, 46.9, 1.7, 116.9, MAT.WoodPlanks, COL.Wood:Lerp(Color3.new(0, 0, 0), 0.2), "Crate")
		box(44.6, 1.7, 115, 46.4, 2.9, 116.7, MAT.WoodPlanks, COL.Wood, "Crate")
		box(29, 2.4, 108, 30.2, 2.7, 115, MAT.Wood, COL.Wood, "Shelf")
		part({ Name = "Rug", Size = Vector3.new(7, 0.06, 5), CFrame = CFrame.new(39, 0.03, 111) * CFrame.Angles(0, 0.12, 0), Material = MAT.Fabric, Color = Color3.fromRGB(78, 34, 28), CanCollide = false })
		part({ Name = "RugBorder", Size = Vector3.new(7.4, 0.05, 5.4), CFrame = CFrame.new(39, 0.02, 111) * CFrame.Angles(0, 0.12, 0), Material = MAT.Fabric, Color = Color3.fromRGB(56, 46, 30), CanCollide = false })
		for _, cp in ipairs({ { 41.5, 0, 110.2, true }, { 44.6, 0, 110.4, false }, { 41.2, 0, 113.8, false }, { 45.8, 2.9, 115.8, true }, { 29.6, 2.7, 109, false }, { 29.6, 2.7, 111.5, true },
			{ 29.6, 2.7, 114, false }, { 34, 0, 116, false }, { 35.2, 0, 116.2, false }, { 37, 0, 105.3, true }, { 31.5, 0, 103.5, false }, { 30, 0, 98, true }, { 32.4, 0, 93.6, true } }) do
			candle(Vector3.new(cp[1], cp[2], cp[3]), cp[4])
		end
		-- a row of small skulls on the shelf, each with its own stub of candle
		for i = 0, 2 do
			part({ Name = "Skull", Shape = Enum.PartType.Ball, Size = Vector3.new(0.7, 0.7, 0.7), CFrame = CFrame.new(29.6, 3.05, 110.3 + i * 1.2), Material = MAT.SmoothPlastic, Color = COL.Bone, CanCollide = false })
		end
		-- chalk on the north wall: a faceless giant, a kneeling hooded figure with a
		-- long blade, and a very small figure holding a light. Drawn by a child. Or not.
		do
			local chalk = Color3.fromRGB(196, 190, 174)
			local function line(x1, y1, x2, y2)
				local a, b = Vector3.new(x1, y1, 116.94), Vector3.new(x2, y2, 116.94)
				part({ Name = "Chalk", Size = Vector3.new((b - a).Magnitude + 0.1, 0.09, 0.03), CFrame = CFrame.new((a + b) / 2) * CFrame.Angles(0, 0, math.atan2(y2 - y1, x2 - x1)), Material = MAT.SmoothPlastic, Color = chalk, Transparency = 0.2, CanCollide = false, CanQuery = false })
			end
			-- the Warden: big body, a mace
			line(31.5, 1.2, 33, 4.6); line(36, 1.2, 34.5, 4.6); line(33, 4.6, 34.5, 4.6); line(32.5, 4.6, 32.5, 6); line(35, 4.6, 35, 6); line(32.5, 6, 35, 6)
			line(35, 4.4, 37, 5.6); line(37, 5.6, 37.2, 6.4)
			-- Oculast: kneeling, hooded, the scythe over her head
			line(39, 1.2, 40.6, 1.2); line(40.6, 1.2, 40.2, 3); line(40.2, 3, 39.6, 3.8); line(39.6, 3.8, 40.4, 4.2); line(40.4, 4.2, 40.9, 3.4)
			line(41.3, 1.1, 41.3, 5.2); line(41.3, 5.2, 39.9, 5.6)
			-- and the little one with her candle, smiling, a bit apart from the others
			line(43.6, 1.1, 43.6, 2.2); line(43.6, 2.2, 43.2, 2.6); line(43.6, 2.2, 44, 2.6); line(43.35, 2.9, 43.85, 2.9); line(44.3, 2.2, 44.3, 2.7)
		end
		-- dressing
		Detail.dressWall(Detail.face(29, 100.5, 1, 0, 0), 7, 9, "tunnel") -- passage walls: rough rock like the drain
		Detail.dressWall(Detail.face(33, 100.5, -1, 0, 0), 7, 9, "tunnel")
		Detail.dressWall(Detail.face(40, 104, 0, 1, 0), 14, 10, "corridor")
		Detail.dressWall(Detail.face(29, 110.5, 1, 0, 0), 13, 10, "cell")
		Detail.dressWall(Detail.face(47, 110.5, -1, 0, 0), 13, 10, "cell")
		Detail.floorSeams(29, 104, 47, 117, 3)
		Detail.bonePile(Vector3.new(30.5, 0, 105.5), 5)
		Detail.stalactites(30, 105, 46, 116, 10, 5)
		Detail.puddle(Vector3.new(31, 0, 101), 2.2, 1.4, 0.4)
		rng = oldRng
		Detail.useRng(oldDetailRng)
	end
	-- Wick sits on the crate, facing the passage you come in by
	info.Wick = CFrame.lookAt(Vector3.new(43, 1.4, 112), Vector3.new(31, 1.4, 104))
	info.WickDoor = Vector3.new(31, 0, 92) -- (out in the Upper Drain: she calls to you from here)

	-----------------------------------------------------------------------
	-- 11. THE RUINED TOWNSHIP (east through the arena's exit, once the Warden falls)
	--     The veil of light at x 50.5..52 lifts when he dies; the passage runs on
	--     through the prison's outer wall into three open-sky parts, with two turns:
	--       Gallows Square x 60..160, z 225..295  (the prison's walls on its west and south)
	--       the Lane       x 100..160, z 295..390 (north; a ruined church closes its end)
	--       Upper Town     x 160..280, z 330..420 (east, to the one house still standing,
	--                      its door hanging open, an old brick inside: Map.OldBrick)
	--     Every other edge is a row of houses, a collapsed lot, or debris, with an
	--     invisible wall behind it so nobody slips out through a gap. Wrought-iron fences
	--     wind the one way through it (the street follows), and the last one has a locked
	--     gate whose key lies in the one house you can go into, back in the Lane.
	-----------------------------------------------------------------------
	do
		local oldRng = rng
		rng = Random.new(3301)
		local oldDetailRng = Detail.useRng(Random.new(3302))
		local MUD, STREET = Color3.fromRGB(56, 50, 42), Color3.fromRGB(62, 60, 56)
		local TIMBER, DOOR, BOARD = Color3.fromRGB(38, 30, 24), Color3.fromRGB(48, 37, 28), Color3.fromRGB(72, 58, 44)
		local VOID, SOOT = Color3.fromRGB(14, 12, 11), Color3.fromRGB(34, 30, 27)
		local PLASTER = { Color3.fromRGB(118, 108, 92), Color3.fromRGB(102, 96, 86), Color3.fromRGB(92, 84, 72), Color3.fromRGB(110, 100, 82), Color3.fromRGB(96, 92, 86) }
		local SLATES = { Color3.fromRGB(50, 48, 52), Color3.fromRGB(58, 46, 40), Color3.fromRGB(44, 44, 42) }
		local SH, D = 6.5, 14 -- storey height, house depth (behind the facade)

		-- part() in a local frame (props.CFrame is relative to cf); decoration unless CanCollide is set
		local function rel(cf, props)
			props.CFrame = cf * props.CFrame
			if props.CanCollide == nil then
				props.CanCollide = false
			end
			return part(props)
		end
		local function lbox(cf, name, x1, y1, z1, x2, y2, z2, mat, color, solid)
			return rel(cf, {
				Name = name,
				Size = Vector3.new(math.abs(x2 - x1), math.abs(y2 - y1), math.abs(z2 - z1)),
				CFrame = CFrame.new((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2),
				Material = mat,
				Color = color,
				CanCollide = solid == true,
			})
		end

		-- a heap of fallen stone and beams, in a local frame (cx, cz = its middle)
		local function debrisPile(cf, cx, cz, w, d, h)
			for _ = 1, math.floor(w * d / 5) do
				local s = rng:NextNumber(1, 3)
				local ox, oz = rng:NextNumber(-0.5, 0.5), rng:NextNumber(-0.5, 0.5)
				local y = h * (1 - math.max(math.abs(ox), math.abs(oz)) * 2) * rng:NextNumber(0.3, 1)
				rel(cf, {
					Name = "Debris",
					Size = Vector3.new(s * rng:NextNumber(0.8, 1.6), s * rng:NextNumber(0.5, 1), s),
					CFrame = CFrame.new(cx + ox * w, y + s * 0.25, cz + oz * d) * CFrame.Angles(rng:NextNumber(-0.6, 0.6), rng:NextNumber(0, 6.3), rng:NextNumber(-0.6, 0.6)),
					Material = rng:NextNumber() < 0.7 and MAT.Cobblestone or MAT.Brick,
					Color = stoneColor(),
					CanCollide = true,
				})
			end
			for _ = 1, math.max(1, math.floor(w / 3)) do
				rel(cf, {
					Name = "FallenBeam",
					Size = Vector3.new(0.6, 0.6, rng:NextNumber(5, 10)),
					CFrame = CFrame.new(cx + rng:NextNumber(-w / 2, w / 2), rng:NextNumber(0.5, h), cz + rng:NextNumber(-d / 2, d / 2)) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 6.3), rng:NextNumber(-0.3, 0.3)),
					Material = MAT.Wood,
					Color = TIMBER,
					CanCollide = true,
				})
			end
		end

		local function crate(pos, s, yaw)
			part({ Name = "Crate", Size = Vector3.new(s, s, s), CFrame = CFrame.new(pos + Vector3.new(0, s / 2, 0)) * CFrame.Angles(0, yaw, 0), Material = MAT.WoodPlanks, Color = BOARD:Lerp(TIMBER, rng:NextNumber(0, 0.5)) })
		end

		local function charredRafters(cf, w, H, n)
			for _ = 1, n do
				rel(cf, {
					Name = "CharredRafter",
					Size = Vector3.new(0.5, 0.5, D * rng:NextNumber(0.6, 1)),
					CFrame = CFrame.new(rng:NextNumber(-w / 2 + 1, w / 2 - 1), H + rng:NextNumber(0.3, 2), D / 2) * CFrame.Angles(rng:NextNumber(-0.35, 0.35), rng:NextNumber(-0.3, 0.3), rng:NextNumber(-0.2, 0.2)),
					Material = MAT.Wood,
					Color = Color3.fromRGB(26, 22, 19),
				})
			end
		end

		-- A town house. cf sits at the middle of its facade's foot, looking out into the
		-- street; the house runs D studs back from there. Half-timbered plaster over a stone
		-- footing, a door, windows (dark, shuttered or boarded), and either a slate roof with
		-- its eaves to the street or a stepped gable facing it. A ruined one is roofless,
		-- smoke-blackened and broken off along the top. Returns its door and wall height.
		-- opt.back: one of the raised back rows (nothing left out in front of it).
		local function house(cf, w, opt)
			opt = opt or {}
			local stories = opt.stories or rng:NextInteger(2, 3)
			local ruined = opt.ruined
			if ruined == nil then
				ruined = rng:NextNumber() < 0.3
			end
			local H = stories * SH + 0.6
			if ruined then
				H = rng:NextNumber(SH * 1.2, H - 1)
			end
			local plaster = PLASTER[rng:NextInteger(1, #PLASTER)]
			if ruined then
				plaster = plaster:Lerp(SOOT, 0.5)
			end
			local function L(name, x1, y1, z1, x2, y2, z2, mat, color, solid)
				return lbox(cf, name, x1, y1, z1, x2, y2, z2, mat, color, solid)
			end
			L("House", -w / 2, 0, 0, w / 2, H, D, MAT.Plaster, plaster, true)

			-- the door, its lintel and step; the stone footing either side of it
			local dw, dh = opt.doorW or 3, opt.doorH or 6.2
			local dx = opt.doorX or rng:NextNumber(-w / 4, w / 4)
			local door = L("Door", dx - dw / 2, 0, -0.26, dx + dw / 2, dh, 0.1, MAT.WoodPlanks, DOOR, opt.solidDoor)
			L("DoorLintel", dx - dw / 2 - 0.3, dh, -0.36, dx + dw / 2 + 0.3, dh + 0.5, 0.1, MAT.Wood, TIMBER)
			if not opt.back then
				L("DoorStep", dx - dw / 2 - 0.4, 0, -1.3, dx + dw / 2 + 0.4, 0.45, -0.26, MAT.Slate, stoneColor(), true)
			end
			L("HouseFooting", -w / 2, 0, -0.3, dx - dw / 2 - 0.3, 3.6, 0.6, MAT.Cobblestone, stoneColor())
			L("HouseFooting", dx + dw / 2 + 0.3, 0, -0.3, w / 2, 3.6, 0.6, MAT.Cobblestone, stoneColor())
			if opt.boarded ~= false and rng:NextNumber() < 0.45 then
				for _, a in ipairs({ 0.5, -0.45 }) do
					rel(cf, { Name = "Board", Size = Vector3.new(dw + 1.2, 0.45, 0.12), CFrame = CFrame.new(dx, rng:NextNumber(2, dh - 1.5), -0.36) * CFrame.Angles(0, 0, a), Material = MAT.WoodPlanks, Color = BOARD })
				end
			end

			-- the timber frame: a beam along each floor, posts between the bays
			for k = 1, stories do
				local y = k * SH
				if y < H - 0.4 then
					L("Beam", -w / 2, y - 0.25, -0.2, w / 2, y + 0.25, 0.1, MAT.Wood, TIMBER)
				end
			end
			local posts = math.max(2, math.floor(w / 4.5) + 1)
			local px = {}
			for i = 1, posts do
				px[i] = -w / 2 + 0.3 + (w - 0.6) * (i - 1) / (posts - 1)
				L("Post", px[i] - 0.22, 3.6, -0.16, px[i] + 0.22, H - 0.05, 0.1, MAT.Wood, TIMBER)
			end
			-- each upper bay: a window (sometimes shuttered or boarded) or a diagonal brace
			for k = 1, stories - 1 do
				local y = k * SH
				for i = 1, posts - 1 do
					local x, bw = (px[i] + px[i + 1]) / 2, px[i + 1] - px[i]
					if bw > 3 and y + 4.6 < H then
						if rng:NextNumber() < 0.78 then
							L("WindowVoid", x - 1.1, y + 1.4, -0.06, x + 1.1, y + 4.4, 0.02, MAT.Slate, VOID)
							L("Sill", x - 1.45, y + 1.1, -0.42, x + 1.45, y + 1.4, 0.1, MAT.Wood, TIMBER)
							local s = rng:NextNumber()
							if s < 0.3 then
								rel(cf, { Name = "Board", Size = Vector3.new(2.9, 0.4, 0.12), CFrame = CFrame.new(x, y + 2.9, -0.16) * CFrame.Angles(0, 0, rng:NextNumber(-0.5, 0.5)), Material = MAT.WoodPlanks, Color = BOARD })
							elseif s < 0.6 then
								local side = rng:NextNumber() < 0.5 and -1 or 1
								rel(cf, { Name = "Shutter", Size = Vector3.new(1.1, 3, 0.12), CFrame = CFrame.new(x + side * 1.75, y + 2.8, -0.22) * CFrame.Angles(0, 0, side * rng:NextNumber(0.05, 0.4)), Material = MAT.WoodPlanks, Color = BOARD })
							end
							if ruined then
								rel(cf, { Name = "Soot", Size = Vector3.new(2.4, 2.2, 0.04), CFrame = CFrame.new(x, y + 5.5, -0.03), Material = MAT.SmoothPlastic, Color = SOOT, Transparency = 0.35 })
							end
						else
							local len = math.sqrt(bw * bw + SH * SH) - 0.6
							rel(cf, { Name = "Brace", Size = Vector3.new(0.36, len, 0.14), CFrame = CFrame.new(x, y + SH / 2, -0.13) * CFrame.Angles(0, 0, math.atan2(bw, SH) * (rng:NextNumber() < 0.5 and 1 or -1)), Material = MAT.Wood, Color = TIMBER })
						end
					end
				end
			end

			if not ruined then
				local R = rng:NextNumber(4.5, 7)
				local roofCol = SLATES[rng:NextInteger(1, #SLATES)]
				local gable = opt.gable
				if gable == nil then
					gable = rng:NextNumber() < 0.5
				end
				if gable then
					-- stepped gable to the street, the roof running back from it
					local run = w / 2 + 0.6
					local len, th = math.sqrt(run * run + R * R) + 0.2, math.atan2(R, run)
					for _, s in ipairs({ -1, 1 }) do
						rel(cf, { Name = "Roof", Size = Vector3.new(len, 0.5, D + 0.6), CFrame = CFrame.new(s * run / 2, H + R / 2, D / 2 + 0.5) * CFrame.Angles(0, 0, -s * th), Material = MAT.RoofShingles, Color = roofCol, CanCollide = true })
					end
					for i = 1, 4 do
						local hw, y0, y1 = run * (1 - i / 4) + 0.5, H + (i - 1) * R / 4, H + i * R / 4 + 0.5
						L("Gable", -hw, y0, 0, hw, y1, 1.4, MAT.Plaster, plaster, true)
						L("Coping", -hw - 0.15, y1, -0.15, hw + 0.15, y1 + 0.3, 1.55, MAT.Slate, stoneColor())
						if i < 4 then
							local aw = run * (1 - i / 4) - 0.25
							L("Attic", -aw, y0, 1.4, aw, H + i * R / 4, D, MAT.Plaster, plaster, true)
						end
					end
				else
					-- eaves to the street; the gable ends hide between the neighbours
					local run = D / 2 + 0.9
					local len, th = math.sqrt(run * run + R * R) + 0.2, math.atan2(R, run)
					rel(cf, { Name = "Roof", Size = Vector3.new(w + 0.8, 0.5, len), CFrame = CFrame.new(0, H + R / 2, (D / 2 - 0.9) / 2) * CFrame.Angles(-th, 0, 0), Material = MAT.RoofShingles, Color = roofCol, CanCollide = true })
					rel(cf, { Name = "Roof", Size = Vector3.new(w + 0.8, 0.5, len), CFrame = CFrame.new(0, H + R / 2, (D / 2 + D + 0.9) / 2) * CFrame.Angles(th, 0, 0), Material = MAT.RoofShingles, Color = roofCol, CanCollide = true })
					for i = 1, 3 do
						local hz = run * (1 - i / 4) - 0.25
						L("Attic", -w / 2, H + (i - 1) * R / 4, D / 2 - hz, w / 2, H + i * R / 4, D / 2 + hz, MAT.Plaster, plaster, true)
					end
				end
				if rng:NextNumber() < 0.6 then
					local cx = rng:NextNumber(-w / 3, w / 3)
					L("Chimney", cx - 0.9, H, D * 0.6, cx + 0.9, H + R + 2, D * 0.6 + 1.8, MAT.Brick, stoneColor(), true)
					L("ChimneyCap", cx - 1.1, H + R + 2, D * 0.6 - 0.2, cx + 1.1, H + R + 2.4, D * 0.6 + 2, MAT.Slate, stoneColor())
				end
			else
				-- broken off along the top, the roof burned away to a few charred rafters
				local x = -w / 2
				while x < w / 2 - 0.01 do
					local seg = math.min(rng:NextNumber(1.5, 3.5), w / 2 - x)
					local up = rng:NextNumber(0, 3.5)
					if up > 0.6 then
						L("Broken", x, H, 0, x + seg, H + up, rng:NextNumber(0.8, 1.6), MAT.Plaster, plaster, true)
					end
					x += seg
				end
				charredRafters(cf, w, H, rng:NextInteger(2, 4))
				if not opt.back then
					rubble(cf * Vector3.new(rng:NextNumber(-w / 3, w / 3), 0, -2.5), 2, 5)
				end
			end
			if opt.back then
				return door, H
			end

			-- what's left out front
			local r = rng:NextNumber()
			local fx = rng:NextNumber(-w / 2 + 1.5, w / 2 - 1.5)
			if math.abs(fx - dx) > dw / 2 + 1.5 then
				if r < 0.25 then
					Detail.barrel(cf * Vector3.new(fx, 0, -1.4), rng:NextNumber() < 0.3)
				elseif r < 0.4 then
					crate(cf * Vector3.new(fx, 0, -1.5), rng:NextNumber(1.6, 2.4), rng:NextNumber(0, 1.5))
				end
			end
			if opt.torch or (opt.torch == nil and rng:NextNumber() < 0.2) then
				torch(cf * Vector3.new(dx + dw / 2 + 1.2, 8, -0.9), cf.LookVector)
			end
			return door, H
		end

		-- a house that fell in: a burned stub of back wall, side stumps, and the heap
		local function collapsedLot(cf, w)
			local col = PLASTER[rng:NextInteger(1, #PLASTER)]:Lerp(SOOT, 0.55)
			local x, top = -w / 2, 0
			while x < w / 2 - 0.01 do
				local seg = math.min(rng:NextNumber(1.5, 3.5), w / 2 - x)
				local h = rng:NextNumber(3, 10)
				top = math.max(top, h)
				lbox(cf, "Wall", x, 0, D - 1.2, x + seg, h, D, MAT.Plaster, col, true)
				x += seg
			end
			for _, s in ipairs({ -1, 1 }) do
				lbox(cf, "Wall", s * w / 2 - 0.6, 0, 0, s * w / 2 + 0.6, rng:NextNumber(2, 7), D - 1.2, MAT.Cobblestone, stoneColor(), true)
			end
			debrisPile(cf, 0, D * 0.45, w - 1.5, D * 0.8, 4)
			charredRafters(cf, w, 1, 3)
			return top
		end

		-- every front house: where a back-row house would stand behind it, and how tall it is
		local fronts = {}
		local function noteFront(cf, H)
			table.insert(fronts, { at = cf * Vector3.new(0, 0, D), H = H })
		end

		-- a row of houses along a town edge, a -> b (world points on the line), facing inward
		local function houseRow(a, b, inward)
			local dir, len = (b - a).Unit, (b - a).Magnitude
			local t = 0
			while t < len - 0.01 do
				local left = len - t
				local w = math.min(rng:NextNumber(10, 16), left)
				if left - w < 7 then
					w = left -- no slivers at the end
				end
				local mid = a + dir * (t + w / 2)
				local cf = CFrame.lookAt(mid, mid + inward)
				if w >= 8 and rng:NextNumber() > 0.15 then
					local _, H = house(cf, w)
					noteFront(cf, H)
				else
					noteFront(cf, collapsedLot(cf, w))
				end
				t += w
			end
			local mid = (a + b) / 2 - inward + Vector3.new(0, 30, 0)
			part({ Name = "TownEdge", Size = Vector3.new(len, 60, 1), CFrame = CFrame.lookAt(mid, mid + inward), Transparency = 1, CanQuery = false })
		end

		-- A second row behind the first, the same procedure on rising ground: each house
		-- stands on a stone terrace so its foot is 20-50% of the way up the front house
		-- before it, and the skyline over the street is houses all the way back.
		-- a -> b runs along the back line (the front houses' back walls), facing inward.
		local function backRow(a, b, inward)
			local dir, len = (b - a).Unit, (b - a).Magnitude
			local t = 0
			while t < len - 0.01 do
				local left = len - t
				local w = math.min(rng:NextNumber(10, 16), left)
				if left - w < 7 then
					w = left
				end
				local mid = a + dir * (t + w / 2)
				local frontH, best = SH * 2, nil
				for _, f in ipairs(fronts) do
					local dist = (f.at - mid).Magnitude -- (both on the ground: y = 0)
					if not best or dist < best then
						best, frontH = dist, f.H
					end
				end
				local base = frontH * rng:NextNumber(0.2, 0.5)
				local cf = CFrame.lookAt(mid, mid + inward) + Vector3.new(0, base, 0)
				lbox(cf, "Terrace", -w / 2, -base, 0, w / 2, 0, D, MAT.Cobblestone, stoneColor(), true)
				house(cf, w, { back = true, ruined = rng:NextNumber() < 0.15 })
				t += w
			end
		end

		local function well(cx, cz)
			for _, w in ipairs({ { -2, -3, 2, -2 }, { -2, 2, 2, 3 }, { -3, -3, -2, 3 }, { 2, -3, 3, 3 } }) do
				box(cx + w[1], 0, cz + w[2], cx + w[3], 2.4, cz + w[4], MAT.Cobblestone, stoneColor(), "Well")
			end
			box(cx - 2, 0, cz - 2, cx + 2, 0.5, cz + 2, MAT.Slate, Color3.fromRGB(16, 18, 20), "WellDark")
			for _, sx in ipairs({ -2.5, 2.5 }) do
				part({ Name = "WellPost", Size = Vector3.new(0.4, 5, 0.4), CFrame = CFrame.new(cx + sx, 4.9, cz), Material = MAT.Wood, Color = COL.Wood })
			end
			part({ Name = "WellBeam", Size = Vector3.new(5.4, 0.35, 0.35), CFrame = CFrame.new(cx, 7.3, cz), Material = MAT.Wood, Color = COL.Wood })
		end

		local function deadTree(pos, s)
			local bark = Color3.fromRGB(40, 34, 28)
			part({ Name = "DeadTree", Size = Vector3.new(1.3, 12, 1.3) * s, CFrame = CFrame.new(pos + Vector3.new(0, 6 * s, 0)) * CFrame.Angles(0.06, rng:NextNumber(0, 6), -0.08), Material = MAT.Wood, Color = bark })
			for _ = 1, rng:NextInteger(3, 5) do
				local len = rng:NextNumber(2.5, 4.5) * s
				part({ Name = "DeadBranch", Size = Vector3.new(0.45 * s, len, 0.45 * s), CFrame = CFrame.new(pos + Vector3.new(0, rng:NextNumber(6, 11) * s, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6.3), rng:NextNumber(0.5, 1.1)) * CFrame.new(0, len / 2, 0), Material = MAT.Wood, Color = bark })
			end
		end

		local function cart(pos, yaw)
			local cf = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
			local tipped = cf * CFrame.new(1.2, 0, 0) * CFrame.Angles(0, 0, 0.32) * CFrame.new(-1.2, 0, 0) -- down on its broken side
			rel(tipped, { Name = "CartBed", Size = Vector3.new(4, 0.4, 7), CFrame = CFrame.new(0, 1.7, 0), Material = MAT.WoodPlanks, Color = COL.Wood, CanCollide = true })
			for _, s in ipairs({ -1, 1 }) do
				rel(tipped, { Name = "CartSide", Size = Vector3.new(0.25, 1.1, 7), CFrame = CFrame.new(s * 1.9, 2.4, 0), Material = MAT.WoodPlanks, Color = COL.Wood })
			end
			rel(tipped, { Name = "CartShaft", Size = Vector3.new(0.3, 0.3, 4.5), CFrame = CFrame.new(-0.8, 1.6, -5.2) * CFrame.Angles(-0.25, 0, 0), Material = MAT.Wood, Color = TIMBER })
			rel(cf, { Name = "Wheel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.35, 3.2, 3.2), CFrame = CFrame.new(-2.3, 1.6, 1.2), Material = MAT.Wood, Color = TIMBER, CanCollide = true })
			rel(cf, { Name = "Wheel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.35, 3.2, 3.2), CFrame = CFrame.new(3.4, 0.2, 2.8) * CFrame.Angles(0, 0.4, math.pi / 2), Material = MAT.Wood, Color = TIMBER })
		end

		local function stall(pos, yaw)
			local cf = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
			for _, c in ipairs({ { -2.3, -1.4, 5.6 }, { 2.3, -1.4, 5.6 }, { -2.3, 1.4, 6.6 }, { 2.3, 1.4, 6.6 } }) do
				rel(cf, { Name = "StallPost", Size = Vector3.new(0.35, c[3], 0.35), CFrame = CFrame.new(c[1], c[3] / 2, c[2]), Material = MAT.Wood, Color = TIMBER, CanCollide = true })
			end
			rel(cf, { Name = "StallCounter", Size = Vector3.new(5, 0.3, 1.4), CFrame = CFrame.new(0, 2.6, -1.2), Material = MAT.WoodPlanks, Color = BOARD, CanCollide = true })
			rel(cf, { Name = "StallFront", Size = Vector3.new(5, 2.4, 0.2), CFrame = CFrame.new(0, 1.3, -1.85), Material = MAT.WoodPlanks, Color = BOARD:Lerp(TIMBER, 0.3), CanCollide = true })
			local cloth = Color3.fromRGB(86, 40, 34):Lerp(Color3.fromRGB(70, 66, 50), rng:NextNumber())
			rel(cf, { Name = "StallCloth", Size = Vector3.new(5.4, 0.08, 3.4), CFrame = CFrame.new(0, 6.2, 0) * CFrame.Angles(-0.3, 0, rng:NextNumber(-0.12, 0.12)), Material = MAT.Fabric, Color = cloth })
			rel(cf, { Name = "StallCloth", Size = Vector3.new(1.6, 1.8, 0.06), CFrame = CFrame.new(rng:NextNumber(-1.8, 1.8), 4.8, -1.62) * CFrame.Angles(0.1, 0, rng:NextNumber(-0.2, 0.2)), Material = MAT.Fabric, Color = cloth })
			for _ = 1, rng:NextInteger(1, 3) do
				local s = rng:NextNumber(0.4, 0.9)
				rel(cf, { Name = "Junk", Size = Vector3.new(s, s * 0.7, s), CFrame = CFrame.new(rng:NextNumber(-2, 2), 2.75 + s * 0.35, -1.2) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), Material = MAT.Wood, Color = BOARD })
			end
		end

		-- AN OPEN HOUSE: a door you can go through, into a bare, worn room: sagging floor
		-- planks (some gone), plaster fallen to the lath, a broken table, a toppled chair, a
		-- cot, a cold hearth, junk, a skeleton by the door, pale light falling through a hole
		-- in the ceiling. Facade like house(). loot = what's in it (init.server picks it up):
		--   "key"    the rusted key to the gate, on the mantel (the house in the Lane): Map.GateKey
		--   "brick"  an old brick on the floor in the light (the standing house): Map.OldBrick
		-- entry = "window": no way in by the door (it's boarded shut); instead a big, low shop
		-- window of old glass you can smash with the old brick and climb through: Map.TownWindow.
		-- Inside, stairs climb the left wall through a hatch onto its flat, walled rooftop.
		local function keyHouse(cf, w, loot, entry)
			local H, T = 11, 0.8 -- wall height, wall thickness
			local plaster, inner = Color3.fromRGB(104, 96, 84), Color3.fromRGB(84, 76, 66)
			local dw, dh = 3.2, 6.6 -- the doorway
			local sill = 0
			if entry == "window" then
				dw, dh, sill = 3.4, 4.8, 0.7 -- the shop window instead (a low sill you can step over)
			end
			local function L(name, x1, y1, z1, x2, y2, z2, mat, color, solid)
				return lbox(cf, name, x1, y1, z1, x2, y2, z2, mat, color, solid)
			end
			local function world(x, y, z)
				return cf * Vector3.new(x, y, z)
			end
			-- floor: a dark subfloor, worn planks over it with gaps and a few missing
			L("Subfloor", -w / 2, -1.5, 0, w / 2, 0.1, D, MAT.Slate, Color3.fromRGB(22, 19, 16), true)
			local z = T
			while z < D - T - 0.01 do
				local pw = math.min(rng:NextNumber(0.9, 1.3), D - T - z)
				if rng:NextNumber() > 0.12 then
					L("Plank", -w / 2 + T, 0.1, z + 0.03, w / 2 - T, 0.22, z + pw - 0.03, MAT.WoodPlanks, Color3.fromRGB(70, 54, 40):Lerp(Color3.fromRGB(44, 38, 32), rng:NextNumber()), true)
				end
				z += pw
			end
			-- walls, the front one round the doorway
			L("Wall", -w / 2, 0, 0, -dw / 2, H, T, MAT.Plaster, plaster, true)
			L("Wall", dw / 2, 0, 0, w / 2, H, T, MAT.Plaster, plaster, true)
			L("Wall", -dw / 2, dh, 0, dw / 2, H, T, MAT.Plaster, plaster, true)
			if sill > 0 then
				L("Wall", -dw / 2, 0, 0, dw / 2, sill, T, MAT.Plaster, plaster, true)
			end
			L("Wall", -w / 2, 0, D - T, w / 2, H, D, MAT.Plaster, inner, true)
			L("Wall", -w / 2, 0, T, -w / 2 + T, H, D - T, MAT.Plaster, inner, true)
			L("Wall", w / 2 - T, 0, T, w / 2, H, D - T, MAT.Plaster, inner, true)
			-- a ceiling with a hole broken through it, and the roof over all
			local hx1, hx2, hz1, hz2 = 1, 4, 6, 9.5
			local ceil = Color3.fromRGB(46, 38, 30)
			local stairs = entry == "window" -- (stairs up through a hatch onto a flat roof)
			local sx1, sx2 = -w / 2 + T, -w / 2 + T + 2.4 -- the stairs' run, up the left wall
			local holes = { { hx1, hz1, hx2, hz2 } }
			if stairs then
				table.insert(holes, { sx1, 7.5, sx2, D - T }) -- the hatch over the top of the stairs
			end
			-- the ceiling, holes cut out of it: bands between the holes' edges, gaps where they are
			local zs = { 0, D }
			for _, hole in ipairs(holes) do
				table.insert(zs, hole[2])
				table.insert(zs, hole[4])
			end
			table.sort(zs)
			for i = 1, #zs - 1 do
				local z1, z2 = zs[i], zs[i + 1]
				if z2 - z1 > 0.01 then
					local cuts = {}
					for _, hole in ipairs(holes) do
						if hole[2] <= z1 + 0.01 and hole[4] >= z2 - 0.01 then
							table.insert(cuts, hole)
						end
					end
					table.sort(cuts, function(p, q)
						return p[1] < q[1]
					end)
					local x = -w / 2
					for _, c in ipairs(cuts) do
						if c[1] > x + 0.01 then
							L("Ceiling", x, H, z1, c[1], H + 0.4, z2, MAT.WoodPlanks, ceil, true)
						end
						x = c[3]
					end
					if w / 2 > x + 0.01 then
						L("Ceiling", x, H, z1, w / 2, H + 0.4, z2, MAT.WoodPlanks, ceil, true)
					end
				end
			end
			if stairs then
				-- a flat roof you can walk out onto, walled by a low parapet, looking over the square
				for _, p in ipairs({ { -w / 2, 0, w / 2, 0.6 }, { -w / 2, D - 0.6, w / 2, D }, { -w / 2, 0.6, -w / 2 + 0.6, D - 0.6 }, { w / 2 - 0.6, 0.6, w / 2, D - 0.6 } }) do
					L("Parapet", p[1], H + 0.4, p[2], p[3], H + 2.6, p[4], MAT.Cobblestone, stoneColor(), true)
				end
				for _, x in ipairs({ -w / 2, w / 2 - 0.9 }) do
					L("ParapetCap", x - 0.05, H + 2.6, -0.05, x + 0.95, H + 2.9, D + 0.05, MAT.Slate, stoneColor())
				end
				-- worn wooden stairs up the left wall: 20 steps to a landing under the hatch
				local steps, z0, tread = 20, 2.5, 0.5
				local rise = H / steps
				for i = 0, steps - 1 do
					L("Stair", sx1, 0.1, z0 + i * tread, sx2, (i + 1) * rise, z0 + (i + 1) * tread, MAT.WoodPlanks, Color3.fromRGB(66, 50, 38):Lerp(Color3.fromRGB(44, 38, 32), rng:NextNumber(0, 0.5)), true)
				end
				L("Landing", sx1, 0.1, z0 + steps * tread, sx2, H, D - T, MAT.WoodPlanks, Color3.fromRGB(60, 46, 34), true)
				-- a rickety rail on the open side
				for i = 0, steps, 4 do
					local z = z0 + i * tread
					L("RailPost", sx2 - 0.12, i * rise, z - 0.12, sx2 + 0.12, i * rise + 3, z + 0.12, MAT.Wood, TIMBER)
				end
				local runLen = steps * tread
				rel(cf, { Name = "Rail", Size = Vector3.new(0.14, 0.14, math.sqrt(runLen * runLen + H * H)), CFrame = CFrame.new(sx2, H / 2 + 2.8, z0 + runLen / 2) * CFrame.Angles(-math.atan2(H, runLen), 0, 0), Material = MAT.Wood, Color = TIMBER })
				L("HatchFrame", sx1, H + 0.4, 7.3, sx2, H + 0.6, 7.5, MAT.Wood, TIMBER)
			else
				local R, run = 5, D / 2 + 0.9
				local len, th = math.sqrt(run * run + R * R) + 0.2, math.atan2(R, run)
				local roofCol = SLATES[rng:NextInteger(1, #SLATES)]
				rel(cf, { Name = "Roof", Size = Vector3.new(w + 0.8, 0.5, len), CFrame = CFrame.new(0, H + 0.4 + R / 2, (D / 2 - 0.9) / 2) * CFrame.Angles(-th, 0, 0), Material = MAT.RoofShingles, Color = roofCol, CanCollide = true })
				rel(cf, { Name = "Roof", Size = Vector3.new(w + 0.8, 0.5, len), CFrame = CFrame.new(0, H + 0.4 + R / 2, (D / 2 + D + 0.9) / 2) * CFrame.Angles(th, 0, 0), Material = MAT.RoofShingles, Color = roofCol, CanCollide = true })
			end

			-- the facade, like its neighbours: timber frame over a stone footing
			for _, x in ipairs({ -w / 2 + 0.3, -dw / 2 - 0.3, dw / 2 + 0.3, w / 2 - 0.3 }) do
				L("Post", x - 0.22, 3.6, -0.16, x + 0.22, H - 0.05, 0.05, MAT.Wood, TIMBER)
			end
			L("Beam", -w / 2, 6.6, -0.2, w / 2, 7.1, 0.05, MAT.Wood, TIMBER)
			L("HouseFooting", -w / 2, 0, -0.3, -dw / 2 - 0.3, 3.6, 0.3, MAT.Cobblestone, stoneColor())
			L("HouseFooting", dw / 2 + 0.3, 0, -0.3, w / 2, 3.6, 0.3, MAT.Cobblestone, stoneColor())
			L("DoorLintel", -dw / 2 - 0.3, dh, -0.36, dw / 2 + 0.3, dh + 0.5, 0.1, MAT.Wood, TIMBER)
			for _, x in ipairs({ -w / 4 - 0.6, w / 4 + 0.6 }) do
				L("WindowVoid", x - 1.1, 7.9, -0.06, x + 1.1, 10.3, 0.02, MAT.Slate, VOID)
				L("Sill", x - 1.45, 7.6, -0.42, x + 1.45, 7.9, 0.1, MAT.Wood, TIMBER)
			end
			rel(cf, { Name = "Board", Size = Vector3.new(2.9, 0.4, 0.12), CFrame = CFrame.new(w / 4 + 0.6, 9.1, -0.16) * CFrame.Angles(0, 0, 0.4), Material = MAT.WoodPlanks, Color = BOARD })
			if entry == "window" then
				-- the shop window: old, grimy glass in a wooden frame
				local glass = L("WindowGlass", -dw / 2, sill, T * 0.4, dw / 2, dh, T * 0.6, MAT.Glass, Color3.fromRGB(70, 82, 80), true)
				glass.Transparency, glass.Reflectance = 0.5, 0.12
				local panes = { glass }
				for _, x in ipairs({ -dw / 6, dw / 6 }) do
					table.insert(panes, L("Muntin", x - 0.06, sill, T * 0.3, x + 0.06, dh, T * 0.7, MAT.Wood, TIMBER))
				end
				table.insert(panes, L("Muntin", -dw / 2, (sill + dh) / 2 - 0.06, T * 0.3, dw / 2, (sill + dh) / 2 + 0.06, T * 0.7, MAT.Wood, TIMBER))
				local grime = L("Grime", -dw / 2, sill, T * 0.37, dw / 2, sill + 1.3, T * 0.39, MAT.SmoothPlastic, Color3.fromRGB(50, 46, 38))
				grime.Transparency = 0.55
				table.insert(panes, grime)
				L("Sill", -dw / 2 - 0.3, sill - 0.2, -0.45, dw / 2 + 0.3, sill, 0.2, MAT.Wood, TIMBER, true)
				-- the real door, boarded fast from outside
				local bx = w / 2 - 2.6
				L("Door", bx - 1.5, 0, -0.42, bx + 1.5, 6.2, -0.3, MAT.WoodPlanks, DOOR, true)
				for _, a in ipairs({ 0.5, -0.45, 0.08 }) do
					rel(cf, { Name = "Board", Size = Vector3.new(4.2, 0.45, 0.12), CFrame = CFrame.new(bx, rng:NextNumber(1.5, 5), -0.5) * CFrame.Angles(0, 0, a), Material = MAT.WoodPlanks, Color = BOARD })
				end
				info.TownWindow = { Panes = panes, Prompt = prompt(glass, "Smash", "Window", 1, 7) }
			else
				-- the door, off its top hinge and hanging open into the room
				rel(cf, { Name = "Door", Size = Vector3.new(dw - 0.2, dh - 0.4, 0.15), CFrame = CFrame.new(-dw / 2 + 0.1, dh / 2 - 0.2, T + 0.1) * CFrame.Angles(0, -1.9, 0.07) * CFrame.new((dw - 0.2) / 2, 0, 0), Material = MAT.WoodPlanks, Color = DOOR })
			end

			-- inside: plaster fallen away to the lath in patches, and old stains
			for _, p in ipairs({ { -1, 2.5, 4, 6 }, { -1, 6, 9, 4 }, { 1, 1.5, 3, 8 }, { 1, 5, 7, 2.5 } }) do
				local sx, y, zc, h = p[1], p[2], p[3], p[4]
				local x0 = sx * (w / 2 - T)
				local face = x0 - sx * 0.04
				L("Lath", math.min(x0, face), y, zc - 1.4, math.max(x0, face), y + h * 0.4, zc + 1.4, MAT.Wood, Color3.fromRGB(36, 28, 22))
				for i = 0, math.floor(h * 0.4 / 0.32) do
					local ly = y + 0.12 + i * 0.32
					L("Lath", face - sx * 0.04, ly, zc - 1.35, face, ly + 0.14, zc + 1.35, MAT.Wood, Color3.fromRGB(92, 72, 50))
				end
			end
			for _ = 1, 5 do
				local sx = rng:NextNumber() < 0.5 and -1 or 1
				rel(cf, { Name = "Stain", Size = Vector3.new(0.04, rng:NextNumber(1.5, 4), rng:NextNumber(1, 2.5)), CFrame = CFrame.new(sx * (w / 2 - T - 0.03), rng:NextNumber(3, 8), rng:NextNumber(2, D - 3)), Material = MAT.SmoothPlastic, Color = Color3.fromRGB(40, 34, 28), Transparency = 0.45 })
			end
			-- a broken table (one leg gone, the top slumped onto the floor at that corner)
			local tableCF = CFrame.new(stairs and 0.6 or -2.6, 0, 4.8) * CFrame.Angles(0, 0.35, 0)
			rel(cf, { Name = "TableTop", Size = Vector3.new(3.2, 0.2, 1.9), CFrame = tableCF * CFrame.new(0, 1.65, 0) * CFrame.Angles(0, 0, 0.42), Material = MAT.WoodPlanks, Color = BOARD, CanCollide = true })
			for _, l in ipairs({ { 1.4, -0.75 }, { 1.4, 0.75 }, { -1.4, 0.75 } }) do
				local h = l[1] > 0 and 2.6 or 1.3
				rel(cf, { Name = "TableLeg", Size = Vector3.new(0.22, h, 0.22), CFrame = tableCF * CFrame.new(l[1], h / 2, l[2]), Material = MAT.Wood, Color = TIMBER, CanCollide = true })
			end
			rel(cf, { Name = "TableLeg", Size = Vector3.new(0.22, 2.4, 0.22), CFrame = tableCF * CFrame.new(-1.9, 0.12, -1.4) * CFrame.Angles(0, 0.8, math.pi / 2), Material = MAT.Wood, Color = TIMBER })
			-- a chair on its back
			local chairCF = CFrame.new(-0.6, 0, 6.6) * CFrame.Angles(0, -0.6, 0)
			rel(cf, { Name = "ChairSeat", Size = Vector3.new(1.3, 0.16, 1.3), CFrame = chairCF * CFrame.new(0, 0.7, 0) * CFrame.Angles(1.45, 0, 0), Material = MAT.WoodPlanks, Color = BOARD })
			rel(cf, { Name = "ChairBack", Size = Vector3.new(1.3, 1.5, 0.14), CFrame = chairCF * CFrame.new(0, 0.12, 0.8) * CFrame.Angles(math.pi / 2, 0, 0), Material = MAT.WoodPlanks, Color = BOARD })
			-- a cot against the left wall, its mattress split and its blanket half off it
			if not stairs then -- (the stairs take that wall)
				local cotX = -w / 2 + T + 1.1
				L("CotFrame", cotX - 1, 0.2, D - T - 6.2, cotX + 1, 1.1, D - T - 0.4, MAT.Wood, TIMBER, true)
				L("Mattress", cotX - 0.9, 1.1, D - T - 6.1, cotX + 0.9, 1.45, D - T - 0.5, MAT.Fabric, Color3.fromRGB(96, 86, 64))
				rel(cf, { Name = "Blanket", Size = Vector3.new(2.2, 0.08, 2.6), CFrame = CFrame.new(cotX + 0.9, 0.95, D - T - 3) * CFrame.Angles(0, 0.2, 1.1), Material = MAT.Fabric, Color = Color3.fromRGB(70, 46, 38) })
			end
			-- a cold hearth on the back wall, a mantel over it, a chimney breast up to the ceiling
			local hx = 3.2
			L("Hearth", hx - 2, 0.2, D - T - 1.4, hx + 2, 4.2, D - T, MAT.Cobblestone, stoneColor(), true)
			L("HearthMouth", hx - 1.1, 0.3, D - T - 1.42, hx + 1.1, 2.6, D - T - 1.38, MAT.Slate, VOID)
			L("Mantel", hx - 2.4, 4.2, D - T - 1.75, hx + 2.4, 4.5, D - T, MAT.Wood, TIMBER, true)
			L("ChimneyBreast", hx - 1.4, 4.5, D - T - 0.9, hx + 1.4, H, D - T, MAT.Cobblestone, stoneColor(), true)
			L("Ash", hx - 0.9, 0.22, D - T - 2.2, hx + 0.9, 0.36, D - T - 1.4, MAT.Sand, Color3.fromRGB(58, 54, 50))
			-- a shelf of old jars on the right wall
			local shelfX = w / 2 - T - 0.45
			L("Shelf", shelfX - 0.45, 4.6, 2.2, shelfX + 0.45, 4.8, 5.4, MAT.Wood, TIMBER, true)
			for i = 0, 3 do
				if rng:NextNumber() < 0.8 then
					local jh = rng:NextNumber(0.4, 0.75)
					rel(cf, { Name = "Jar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(jh, 0.42, 0.42), CFrame = CFrame.new(shelfX, 4.8 + jh / 2, 2.6 + i * 0.75) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Glass, Color = Color3.fromRGB(80, 90, 70), Transparency = 0.3 })
				end
			end
			rel(cf, { Name = "Jar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 0.42, 0.42), CFrame = CFrame.new(shelfX - 1, 0.45, 3.4) * CFrame.Angles(0.3, 0.6, 0), Material = MAT.Glass, Color = Color3.fromRGB(80, 90, 70), Transparency = 0.3 })
			-- a fallen roof beam leaning in a corner, a heap of rubble, scattered pages
			rel(cf, { Name = "FallenBeam", Size = Vector3.new(0.7, 0.7, 8.5), CFrame = CFrame.new(w / 2 - T - 1.2, 3.2, D - T - 3.5) * CFrame.Angles(0.75, 0.1, 0.1), Material = MAT.Wood, Color = Color3.fromRGB(32, 26, 21), CanCollide = true })
			debrisPile(cf, w / 2 - T - 1.6, D - T - 1.6, 2.4, 2.4, 1.4)
			for _ = 1, 6 do
				rel(cf, { Name = "Page", Size = Vector3.new(0.6, 0.02, 0.8), CFrame = CFrame.new(rng:NextNumber(-w / 2 + 1.5, w / 2 - 1.5), 0.24, rng:NextNumber(1.5, D - 2)) * CFrame.Angles(0, rng:NextNumber(0, 6.3), 0), Material = MAT.SmoothPlastic, Color = Color3.fromRGB(150, 138, 110) })
			end
			-- whoever lived here never left
			local sk = stairs and 1 or -1 -- (by the door's corner, or the other one when the stairs are there)
			Detail.slumpedSkeleton(world(sk * (w / 2 - T - 0.6), 0.2, 1.8), (cf:VectorToWorldSpace(Vector3.new(-sk, 0, 0.3))).Unit)
			-- pale light through the hole in the ceiling, a dim wash so the room reads, and
			-- a guttering candle stub on the mantel beside the key
			local holeLight = rel(cf, { Name = "HoleLight", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new((hx1 + hx2) / 2, H + 1.5, (hz1 + hz2) / 2), Transparency = 1, CanQuery = false })
			local spot = Instance.new("SpotLight")
			spot.Face = Enum.NormalId.Bottom
			spot.Color, spot.Brightness, spot.Range, spot.Angle, spot.Shadows = Color3.fromRGB(170, 180, 190), 1.4, 18, 55, true
			spot.Parent = holeLight
			rel(cf, { Name = "LightShaft", Size = Vector3.new(3, H, 3.5), CFrame = CFrame.new((hx1 + hx2) / 2, H / 2, (hz1 + hz2) / 2), Material = MAT.Neon, Color = Color3.fromRGB(180, 188, 196), Transparency = 0.95, CastShadow = false, CanQuery = false })
			local wash = rel(cf, { Name = "RoomWash", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(0, 6, D / 2), Transparency = 1, CanQuery = false })
			local wl = Instance.new("PointLight")
			wl.Color, wl.Range, wl.Brightness = Color3.fromRGB(150, 140, 120), 16, 0.45
			wl.Parent = wash
			local candle = rel(cf, { Name = "Candle", Size = Vector3.new(0.3, 0.45, 0.3), CFrame = CFrame.new(hx - 1.6, 4.72, D - T - 1.2), Material = MAT.SmoothPlastic, Color = Color3.fromRGB(196, 186, 156) })
			local flame = rel(cf, { Name = "CandleFlame", Size = Vector3.new(0.1, 0.22, 0.1), CFrame = CFrame.new(hx - 1.6, 5.06, D - T - 1.2), Material = MAT.Neon, Color = Color3.fromRGB(255, 170, 80), CanQuery = false })
			local cl = Instance.new("PointLight")
			cl.Color, cl.Range, cl.Brightness = Color3.fromRGB(255, 170, 90), 9, 1
			cl.Parent = flame
			addFlicker(cl)
			-- something left behind, catching the light
			local function glinting(p)
				local glint = Instance.new("ParticleEmitter")
				glint.Texture = "rbxasset://textures/particles/sparkles_main.dds"
				glint.Rate, glint.Lifetime, glint.Speed = 2, NumberRange.new(0.6, 1), NumberRange.new(0, 0.2)
				glint.Size = NumberSequence.new(0.25, 0)
				glint.Color = ColorSequence.new(Color3.fromRGB(255, 220, 160))
				glint.LightEmission = 1
				glint.Parent = p
			end
			if loot ~= "key" and loot ~= "brick" then
				noteFront(cf, H + 5) -- (nothing left in this one)
				return
			end
			if loot == "brick" then
				-- an old brick, lying on the boards in the light from the hole above
				local brick = rel(cf, { Name = "OldBrick", Size = Vector3.new(0.95, 0.42, 0.46), CFrame = CFrame.new((hx1 + hx2) / 2, 0.43, (hz1 + hz2) / 2) * CFrame.Angles(0, 0.6, 0.06), Material = MAT.Brick, Color = Color3.fromRGB(122, 64, 46) })
				glinting(brick)
				info.OldBrick = { Prompt = prompt(brick, "Take", "Old Brick", 0, 7), Parts = { brick } }
				noteFront(cf, H + 5)
				return
			end
			-- the key: a rusted iron key lying on the mantel, catching the candlelight
			local rustKey = Color3.fromRGB(110, 70, 44)
			local keyCF = CFrame.new(hx + 0.4, 4.56, D - T - 1.15) * CFrame.Angles(0, 0.5, 0)
			local shaft = rel(cf, { Name = "GateKey", Size = Vector3.new(0.09, 0.09, 0.8), CFrame = keyCF, Material = MAT.CorrodedMetal, Color = rustKey })
			local bow = rel(cf, { Name = "GateKey", Shape = Enum.PartType.Ball, Size = Vector3.new(0.32, 0.32, 0.32), CFrame = keyCF * CFrame.new(0, 0, 0.5), Material = MAT.CorrodedMetal, Color = rustKey })
			local bit = rel(cf, { Name = "GateKey", Size = Vector3.new(0.09, 0.09, 0.22), CFrame = keyCF * CFrame.new(0, 0, -0.32) * CFrame.Angles(math.pi / 2, 0, 0), Material = MAT.CorrodedMetal, Color = rustKey })
			glinting(shaft)
			local pp = prompt(shaft, "Take", "Rusted Key", 0, 7)
			info.GateKey = { Prompt = pp, Parts = { shaft, bow, bit } }
			noteFront(cf, H + 5)
		end

		-- Bloodborne-style wrought-iron fences, a -> b: tall spear-topped bars (a few bent,
		-- a few broken off short, a few gone), two rails, a jagged row of spikes leaning out
		-- between the bars near the top, and stone posts every few strides. An invisible wall
		-- keeps everyone (dogs too) to its side. gateAt = distance along it of a 10-stud gate
		-- (locked: init.server opens it with the key); farSide = which way its leaves swing.
		local FIRON, FRUST = Color3.fromRGB(30, 28, 28), Color3.fromRGB(70, 46, 32)
		local function fence(a, b, gateAt, farSide)
			local dir, len = (b - a).Unit, (b - a).Magnitude
			local FH = 9
			local ROT = CFrame.lookAt(Vector3.zero, dir) -- local Z along the fence
			local function at(t, y)
				return a + dir * t + Vector3.new(0, y, 0)
			end
			local g1, g2 = gateAt and gateAt - 5, gateAt and gateAt + 5
			local function inGate(t)
				return gateAt and t > g1 - 1.1 and t < g2 + 1.1
			end
			local spans = gateAt and { { 0, g1 - 1 }, { g2 + 1, len } } or { { 0, len } }
			for _, sp in ipairs(spans) do
				if sp[2] - sp[1] > 0.1 then
					local mid = at((sp[1] + sp[2]) / 2, 7)
					part({ Name = "FenceWall", Size = Vector3.new(0.8, 14, sp[2] - sp[1]), CFrame = CFrame.lookAt(mid, mid + dir), Transparency = 1, CanQuery = false })
					for _, y in ipairs({ 1.3, FH - 1.8 }) do
						local m = at((sp[1] + sp[2]) / 2, y)
						part({ Name = "FenceRail", Size = Vector3.new(0.16, 0.3, sp[2] - sp[1]), CFrame = CFrame.lookAt(m, m + dir), Material = MAT.Metal, Color = FIRON, CanCollide = false })
					end
				end
			end
			local t = 0.55
			while t < len - 0.3 do
				if not inGate(t) then
					local roll = rng:NextNumber()
					if roll > 0.05 then
						local h = roll < 0.12 and FH * rng:NextNumber(0.35, 0.7) or FH + rng:NextNumber(-0.5, 0.9)
						local lean = roll < 0.25 and CFrame.Angles(rng:NextNumber(-0.18, 0.18), 0, rng:NextNumber(-0.12, 0.12)) or CFrame.new()
						local base = CFrame.new(at(t, 0)) * ROT * lean
						part({ Name = "FenceBar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 0.22, 0.22), CFrame = base * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Metal, Color = FIRON:Lerp(FRUST, rng:NextNumber(0, 0.5)), CanCollide = false })
						if h > FH * 0.8 then
							part({ Name = "Spear", Size = Vector3.new(0.3, 0.3, 0.3), CFrame = base * CFrame.new(0, h + 0.1, 0) * CFrame.Angles(math.pi / 4, 0, math.pi / 4), Material = MAT.Metal, Color = FIRON, CanCollide = false })
							part({ Name = "Spear", Size = Vector3.new(0.06, 0.75, 0.24), CFrame = base * CFrame.new(0, h + 0.6, 0), Material = MAT.Metal, Color = FIRON, CanCollide = false })
						end
					end
					if rng:NextNumber() < 0.7 then
						local jag = CFrame.new(at(t + 0.55, FH - 1.6)) * ROT * CFrame.Angles(rng:NextNumber(-0.45, 0.45), 0, 0)
						part({ Name = "Jag", Size = Vector3.new(0.08, 1.1, 0.14), CFrame = jag * CFrame.new(0, 0.5, 0), Material = MAT.Metal, Color = FIRON, CanCollide = false })
					end
				end
				t += 1.1
			end
			local posts = {}
			local p = 0
			while p < len - 4 do
				table.insert(posts, p)
				p += 9
			end
			table.insert(posts, len)
			for _, q in ipairs(posts) do
				if not inGate(q) then
					local c = at(q, 0)
					box(c.X - 0.6, 0, c.Z - 0.6, c.X + 0.6, FH + 0.6, c.Z + 0.6, MAT.Cobblestone, stoneColor(), "FencePost")
					part({ Name = "PostCap", Size = Vector3.new(1.4, 0.4, 1.4), CFrame = CFrame.new(c + Vector3.new(0, FH + 0.8, 0)), Material = MAT.Slate, Color = stoneColor() })
					part({ Name = "Spear", Size = Vector3.new(0.12, 1.2, 0.3), CFrame = CFrame.new(c + Vector3.new(0, FH + 1.6, 0)) * ROT, Material = MAT.Metal, Color = FIRON, CanCollide = false })
				end
			end
			if not gateAt then
				return nil
			end
			-- the gate: two stone pillars, two iron leaves meeting in the middle, chained and padlocked
			local leaves = {}
			for _, g in ipairs({ { g1, 1 }, { g2, -1 } }) do
				local pillar = at(g[1], 0)
				box(pillar.X - 1, 0, pillar.Z - 1, pillar.X + 1, FH + 2, pillar.Z + 1, MAT.Cobblestone, stoneColor(), "GatePillar")
				part({ Name = "GatePillarCap", Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.6, 1.6), CFrame = CFrame.new(pillar + Vector3.new(0, FH + 2.8, 0)), Material = MAT.Metal, Color = FIRON })
				local along = dir * g[2] -- from this pillar toward the middle
				local hingePos = pillar + along * 1
				local hinge = CFrame.lookAt(hingePos, hingePos + along) -- its -Z runs out along the leaf
				local leaf = Instance.new("Model")
				leaf.Name = "GateLeaf"
				leaf.Parent = map
				local LW = 4 -- (pillar edge to the middle)
				for i = 0, 8 do
					local d = 0.25 + i * (LW - 0.4) / 8
					local h = FH + 0.4 + math.sin(i / 8 * math.pi) * 0.9 -- the top rises in an arch to the middle
					part({ Name = "GateBar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 0.24, 0.24), CFrame = hinge * CFrame.new(0, h / 2, -d) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Metal, Color = FIRON, CanCollide = false, Parent = leaf })
					part({ Name = "Spear", Size = Vector3.new(0.06, 0.8, 0.24), CFrame = hinge * CFrame.new(0, h + 0.4, -d), Material = MAT.Metal, Color = FIRON, CanCollide = false, Parent = leaf })
				end
				for _, y in ipairs({ 1.0, 4.6, FH - 1.2 }) do
					part({ Name = "GateRail", Size = Vector3.new(0.18, 0.32, LW), CFrame = hinge * CFrame.new(0, y, -LW / 2), Material = MAT.Metal, Color = FIRON, CanCollide = false, Parent = leaf })
				end
				-- a ring of curls between the middle rails
				part({ Name = "GateCurl", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, 1.6, 1.6), CFrame = hinge * CFrame.new(0, 2.8, -LW / 2), Material = MAT.Metal, Color = FIRON, CanCollide = false, Parent = leaf })
				leaf.PrimaryPart = leaf:FindFirstChild("GateRail")
				-- which way it swings: away from the near side, toward farSide
				local swing = (along.Z * farSide.X - along.X * farSide.Z) > 0 and 1 or -1
				table.insert(leaves, { Model = leaf, Hinge = hinge, Swing = swing })
			end
			local mid = at(gateAt, 7)
			local wall = part({ Name = "GateWall", Size = Vector3.new(0.8, 14, 10), CFrame = CFrame.lookAt(mid, mid + dir), Transparency = 1, CanQuery = false })
			-- the chain and padlock where the leaves meet
			local lockAt = at(gateAt, 4.2)
			local lockParts = {}
			for i = -2, 2 do
				table.insert(lockParts, part({ Name = "GateChain", Size = Vector3.new(0.3, 0.12, 0.45), CFrame = CFrame.new(lockAt + Vector3.new(0, i * 0.32, 0)) * ROT * CFrame.Angles(0, (i % 2) * math.pi / 2, 0.3), Material = MAT.CorrodedMetal, Color = FRUST, CanCollide = false }))
			end
			local lock = part({ Name = "Padlock", Size = Vector3.new(0.7, 0.8, 0.35), CFrame = CFrame.new(lockAt - Vector3.new(0, 1, 0)) * ROT * CFrame.Angles(0, math.pi / 2, 0), Material = MAT.CorrodedMetal, Color = FRUST, CanCollide = false })
			table.insert(lockParts, lock)
			return { Leaves = leaves, Wall = wall, Lock = lockParts, Prompt = prompt(lock, "Open", "Iron Gate", 0, 8) }
		end

		-- the ground and the streets (east, then north, then east again)
		floor(60, 225, 160, 295, MAT.Mud, MUD)
		floor(100, 295, 160, 390, MAT.Mud, MUD)
		floor(160, 330, 280, 420, MAT.Mud, MUD)
		-- (the street follows the one way through, round the ends of the fences: in from the
		-- passage, south round the first fence, north past the gallows, a zigzag up the Lane
		-- past the key house, round the fence in the upper town and on to the gate)
		for _, r in ipairs({
			{ 60, 255, 96, 265 }, { 86, 234, 96, 255 }, { 96, 234, 135, 244 }, { 125, 244, 135, 335 },
			{ 135, 325, 156, 335 }, { 146, 335, 156, 355 }, { 104, 345, 146, 355 }, { 104, 355, 114, 380 },
			{ 114, 370, 190, 380 }, { 180, 336, 190, 370 }, { 190, 336, 221, 346 }, { 211, 346, 221, 370 },
			{ 211, 370, 280, 380 },
		}) do
			box(r[1], 0, r[2], r[3], 0.06, r[4], MAT.Cobblestone, STREET, "Street")
		end

		-- the rest of the passage out of the arena, through the prison's outer wall
		floor(52, 253, 60, 267)
		box(52, 0, 252, 56, 16, 253, MAT.Cobblestone, stoneColor(), "Wall")
		box(52, 0, 267, 56, 16, 268, MAT.Cobblestone, stoneColor(), "Wall")
		ceiling(52, 252, 56, 268, 16)

		-----------------------------------------------------------------------
		-- the prison's outer walls: west and south of the square. Crenellated, with a
		-- tower at each end of the south wall, the "yard" dressing (buttresses, barred
		-- windows, banners, ivy, grime), torches, and gibbet cages off the parapet.
		-----------------------------------------------------------------------
		local PW = 30
		box(56, 0, 231, 60, PW, 253, MAT.Cobblestone, stoneColor(), "PrisonWall")
		box(56, 0, 267, 60, PW, 295, MAT.Cobblestone, stoneColor(), "PrisonWall")
		box(56, 16, 253, 60, PW, 267, MAT.Cobblestone, stoneColor(), "PrisonWall") -- over the way in
		box(66, 0, 221, 152, PW, 225, MAT.Cobblestone, stoneColor(), "PrisonWall")
		crenellate(58, 231, 58, 295, PW)
		crenellate(66, 223, 152, 223, PW)
		local function tower(x1, z1, x2, z2, h, slits)
			box(x1, 0, z1, x2, h, z2, MAT.Cobblestone, stoneColor(), "Tower")
			box(x1 - 0.6, h - 2.2, z1 - 0.6, x2 + 0.6, h - 0.6, z2 + 0.6, MAT.Slate, COL.Wall, "TowerCourse")
			crenellate(x1, z1, x2, z1, h)
			crenellate(x1, z2, x2, z2, h)
			crenellate(x1, z1, x1, z2, h)
			crenellate(x2, z1, x2, z2, h)
			for _, y in ipairs({ 13, 22, 31 }) do
				for _, s in ipairs(slits) do
					box(s[1], y, s[2], s[3], y + 3.2, s[4], MAT.Slate, VOID, "ArrowSlit")
				end
			end
		end
		tower(52, 217, 66, 231, 42, { { 66, 223.5, 66.1, 224.5 }, { 58.5, 231, 59.5, 231.1 } })
		tower(152, 217, 166, 231, 38, { { 151.9, 223.5, 152, 224.5 }, { 158.5, 231, 159.5, 231.1 } })
		-- gibbet cages hung off iron arms (registered first so the dressing leaves them room)
		for _, g in ipairs({ { 95, 225, 0, 1 }, { 125, 225, 0, 1 }, { 60, 283, 1, 0 } }) do
			local base, out = Vector3.new(g[1], 0, g[2]), Vector3.new(g[3], 0, g[4])
			part({ Name = "GibbetArm", Size = Vector3.new(0.5, 0.5, 3.2), CFrame = CFrame.lookAt(base + Vector3.new(0, 26, 0) + out * 1.6, base + Vector3.new(0, 26, 0) + out * 3), Material = MAT.Metal, Color = COL.Iron })
			chain(base + Vector3.new(0, 25.7, 0) + out * 2.9, 9)
			cage(base + Vector3.new(0, 20.8, 0) + out * 2.9)
			table.insert(avoidSpots, base + Vector3.new(0, 20, 0))
		end
		for _, z in ipairs({ 243, 276 }) do
			torch(Vector3.new(60.9, 9, z), Vector3.new(1, 0, 0))
		end
		for _, x in ipairs({ 80, 110, 140 }) do
			torch(Vector3.new(x, 9, 225.9), Vector3.new(0, 0, 1))
		end
		Detail.dressWall(Detail.face(60, 242, 1, 0), 22, PW, "yard")
		Detail.dressWall(Detail.face(60, 281, 1, 0), 28, PW, "yard")
		Detail.dressWall(Detail.face(109, 225, 0, 1), 86, PW, "yard")
		Detail.archRib(Detail.face(60, 260, 1, 0), 0, 12, 7.2, 4, 1.2, 1.4, 0.7, 9, MAT.Cobblestone, COL.Wall, false)
		Detail.slumpedSkeleton(Vector3.new(61.2, 0, 236), Vector3.new(1, 0, 0))
		Detail.slumpedSkeleton(Vector3.new(132, 0, 226.2), Vector3.new(0, 0, 1))
		rubble(Vector3.new(64, 0, 290), 2.5, 6)
		rubble(Vector3.new(148, 0, 229), 2.5, 5)

		-----------------------------------------------------------------------
		-- the town's other edges: rows of houses, a collapsed lot here and there
		-----------------------------------------------------------------------
		local IN_W, IN_E, IN_N, IN_S = Vector3.new(-1, 0, 0), Vector3.new(1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1)
		houseRow(Vector3.new(160, 0, 231), Vector3.new(160, 0, 330), IN_W) -- east side of the square and the lane
		houseRow(Vector3.new(60, 0, 295), Vector3.new(72, 0, 295), IN_S) -- north side of the square,
		keyHouse(CFrame.lookAt(Vector3.new(79, 0, 295), Vector3.new(79, 0, 294)), 14, nil, "window") -- (smash the window to get in)
		houseRow(Vector3.new(86, 0, 295), Vector3.new(100, 0, 295), IN_S) -- either side of the shop window
		houseRow(Vector3.new(100, 0, 309), Vector3.new(100, 0, 344), IN_E) -- west side of the lane,
		keyHouse(CFrame.lookAt(Vector3.new(100, 0, 351), Vector3.new(101, 0, 351)), 14, "key") -- (the gate key is in here)
		houseRow(Vector3.new(100, 0, 358), Vector3.new(100, 0, 390), IN_E) -- either side of the key house

		-- the fences that wind the way through town, and the locked gate before the standing house
		local E = Vector3.new(1, 0, 0)
		fence(Vector3.new(100, 0, 248), Vector3.new(100, 0, 295)) -- the square: round its south end
		fence(Vector3.new(100, 0, 340), Vector3.new(142, 0, 340)) -- the Lane: round its east end...
		fence(Vector3.new(118, 0, 360), Vector3.new(160, 0, 360)) -- ...then its west end
		fence(Vector3.new(160, 0, 330), Vector3.new(160, 0, 368)) -- into the upper town only at the top
		fence(Vector3.new(206, 0, 352), Vector3.new(206, 0, 420)) -- the upper town: round its south end
		info.TownGate = fence(Vector3.new(240, 0, 330), Vector3.new(240, 0, 420), 45, E) -- the gate (z 370..380)
		houseRow(Vector3.new(174, 0, 330), Vector3.new(280, 0, 330), IN_N) -- south side of the upper town
		houseRow(Vector3.new(160, 0, 420), Vector3.new(280, 0, 420), IN_S) -- north side
		houseRow(Vector3.new(160, 0, 390), Vector3.new(160, 0, 420), IN_E) -- its west end
		houseRow(Vector3.new(280, 0, 330), Vector3.new(280, 0, 362), IN_W) -- east end, either side of
		houseRow(Vector3.new(280, 0, 388), Vector3.new(280, 0, 420), IN_W) -- the house still standing

		-- the lane ends at a burned church: its front and bell-tower stump, choked with rubble
		do
			box(108, 0, 390, 146, 22, 395, MAT.Cobblestone, stoneColor(), "ChurchFront")
			box(100, 0, 386, 108, 27, 395, MAT.Cobblestone, stoneColor(), "BellTower")
			local x = 108
			while x < 145.99 do
				local seg = math.min(rng:NextNumber(2, 4), 146 - x)
				local up = rng:NextNumber(0, 6)
				if up > 0.8 then
					box(x, 22, 390, x + seg, 22 + up, 395, MAT.Cobblestone, stoneColor(), "ChurchFront")
				end
				x += seg
			end
			local face = Detail.face(127, 390, 0, -1)
			Detail.setCutouts({ { axis = "X", min = Vector3.new(124, -1, 385), max = Vector3.new(130, 9.5, 391) } })
			Detail.dressWall(face, 38, 22, "corridor")
			Detail.setCutouts(nil)
			box(124, 0, 389.9, 130, 6, 390, MAT.Slate, VOID, "ChurchDoorway")
			Detail.archRib(face, 0, 6, 3.6, 3, 1, 1.2, 0.6, 9, MAT.Cobblestone, COL.Wall, false)
			Detail.window(face, 0, 11, 5, 6, false)
			part({ Name = "FallenBell", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3.2, 3.6, 3.6), CFrame = CFrame.new(112, 1.8, 383) * CFrame.Angles(0, 0.7, 0.2), Material = MAT.Metal, Color = Color3.fromRGB(78, 64, 40) })
			debrisPile(CFrame.new(), 127, 386, 30, 6, 4.5)
			charredRafters(CFrame.new(127, 0, 375), 20, 0.5, 4)
			for _, x in ipairs({ 104, 118, 132 }) do
				table.insert(fronts, { at = Vector3.new(x, 0, 395), H = 22 })
			end
		end


		-----------------------------------------------------------------------
		-- the house still standing, at the end of the upper town's street
		-----------------------------------------------------------------------
		do
			local cf = CFrame.lookAt(Vector3.new(280, 0, 375), Vector3.new(279, 0, 375))
			keyHouse(cf, 26, "brick") -- its door hangs open; an old brick lies inside
			for _, s in ipairs({ -1, 1 }) do
				torch(cf * Vector3.new(s * 4.2, 7.5, -0.9), cf.LookVector)
			end
			brazier(Vector3.new(266, 0, 365))
			brazier(Vector3.new(266, 0, 385))
		end

		-- the back rows, behind every row of houses (and behind the church), each run
		-- lengthened or cut short at the corners so neighbouring rows meet without overlapping
		backRow(Vector3.new(174, 0, 219), Vector3.new(174, 0, 316), IN_W) -- behind the square's east side and the lane
		backRow(Vector3.new(188, 0, 316), Vector3.new(294, 0, 316), IN_N) -- behind the upper town's south side
		backRow(Vector3.new(294, 0, 316), Vector3.new(294, 0, 434), IN_W) -- behind its east end and the standing house
		backRow(Vector3.new(132, 0, 434), Vector3.new(294, 0, 434), IN_S) -- behind its north side
		backRow(Vector3.new(146, 0, 395), Vector3.new(146, 0, 434), IN_E) -- behind its west end
		backRow(Vector3.new(86, 0, 395), Vector3.new(132, 0, 395), IN_S) -- behind the church
		backRow(Vector3.new(86, 0, 336), Vector3.new(86, 0, 409), IN_E) -- behind the lane's west side (south of it: the rampart)

		-- The wall runs on north past the square and turns east behind the shop window's
		-- roof (a round tower on the turn, a square one where it ends against the houses),
		-- so nothing past the town shows from up there. Inside the turn: the Prison Ramparts,
		-- a stretch of fortified roof at y 20, reached up a fallen beam from that roof deck.
		local RT = 20 -- the rampart's walk
		-- (the wall's stretch beside the rampart is broken down to the walk: the rampart runs on west over it)
		box(56, 0, 295, 60, PW, 309, MAT.Cobblestone, stoneColor(), "PrisonWall")
		box(56, 0, 309, 60, RT, 329, MAT.Cobblestone, stoneColor(), "PrisonWall")
		box(56, 0, 329, 60, PW, 333, MAT.Cobblestone, stoneColor(), "PrisonWall")
		box(60, 0, 329, 78, PW, 333, MAT.Cobblestone, stoneColor(), "PrisonWall")
		crenellate(58, 297, 58, 307, PW)
		crenellate(64, 331, 76, 331, PW)
		part({ Name = "Tower", Shape = Enum.PartType.Cylinder, Size = Vector3.new(40, 15, 15), CFrame = CFrame.new(58, 20, 331) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Cobblestone, Color = stoneColor() })
		part({ Name = "TowerCourse", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 16.2, 16.2), CFrame = CFrame.new(58, 38.4, 331) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Slate, Color = COL.Wall })
		for i = 0, 9 do
			local a = i / 10 * math.pi * 2
			part({ Name = "Merlon", Size = Vector3.new(2, 2, 2.4), CFrame = CFrame.new(58 + math.cos(a) * 6.5, 41, 331 + math.sin(a) * 6.5) * CFrame.Angles(0, -a, 0), Material = MAT.Cobblestone, Color = stoneColor() })
		end
		tower(78, 326, 86, 336, 36, {})
		box(60, 0, 309, 86, RT, 329, MAT.Cobblestone, stoneColor(), "Rampart")
		box(60, RT, 309, 86, RT + 0.15, 329, MAT.Slate, Color3.fromRGB(62, 60, 58), "RampartWalk")
		-- a parapet along the open edges (broken where the beam came down on it)
		box(84.6, RT, 310.4, 86, RT + 1.4, 326, MAT.Cobblestone, stoneColor(), "Parapet")
		box(60, RT, 309, 78, RT + 1.4, 310.4, MAT.Cobblestone, stoneColor(), "Parapet")
		crenellate(85, 312, 85, 326, RT + 1.4)
		crenellate(60, 310, 76, 310, RT + 1.4)
		part({ Name = "RampartEdge", Size = Vector3.new(0.6, 20, 17), CFrame = CFrame.new(85.7, RT + 10, 317.5), Transparency = 1, CanQuery = false }) -- (no hopping the parapet onto the lane's roofs)
		part({ Name = "Merlon", Size = Vector3.new(2.2, 1.4, 1.6), CFrame = CFrame.new(76.5, RT + 0.85, 313) * CFrame.Angles(0.3, 0.7, 0.2), Material = MAT.Cobblestone, Color = stoneColor() }) -- knocked off
		rubble(Vector3.new(80, RT + 0.15, 311.5), 1.2, 3)
		rubble(Vector3.new(63, RT + 0.15, 326), 2, 4)
		brazier(Vector3.new(64, RT + 0.15, 314))
		brazier(Vector3.new(80, RT + 0.15, 323))
		for _, x in ipairs({ 66, 74 }) do
			torch(Vector3.new(x, RT + 7, 328.9), Vector3.new(0, 0, -1))
		end
		-- the rampart's west reach (x 46..60): over the broken wall, out to where the
		-- old stair climbs to the prison's roof
		box(46, 0, 309, 56, RT, 329, MAT.Cobblestone, stoneColor(), "Rampart")
		box(46, RT, 309, 60, RT + 0.15, 329, MAT.Slate, Color3.fromRGB(62, 60, 58), "RampartWalk")
		-- an invisible wall behind every parapet out here: a hop over it is a long fall
		local function edge(x1, z1, x2, z2, y)
			local e = box(x1, y, z1, x2, y + 9, z2, MAT.SmoothPlastic, COL.Wall, "RampartEdge")
			e.Transparency, e.CanQuery = 1, false
		end
		edge(46, 309, 46.6, 311.2, RT) -- (beside the stair's foot)
		box(46, RT, 309, 60, RT + 1.4, 310.4, MAT.Cobblestone, stoneColor(), "Parapet") -- south
		crenellate(46, 310, 58, 310, RT + 1.4)
		edge(46, 309, 60, 309.6, RT)
		box(46, RT, 327.6, 51, RT + 1.4, 329, MAT.Cobblestone, stoneColor(), "Parapet") -- north (to the round tower)
		edge(46, 328.4, 51, 329, RT)
		box(46, RT, 317.4, 47.4, RT + 1.4, 327.6, MAT.Cobblestone, stoneColor(), "Parapet") -- west, north of the stair
		crenellate(46.7, 318, 46.7, 326, RT + 1.4)
		edge(46, 317.4, 46.6, 329, RT)
		torch(Vector3.new(50.5, RT + 6, 323.6), Vector3.new(0, 0, -1)) -- on the round tower's flank
		brazier(Vector3.new(52, RT + 0.15, 325))
		rubble(Vector3.new(57, RT + 0.15, 312), 1.5, 3)

		-- THE OLD STAIR: a stone ramp off the rampart's west end, climbing along outside
		-- the prison's north wall, then curving south up onto its roof (y 42)
		do
			local ROOF = 42
			local W = 6 -- the ramp's width
			local Z = 314.2 -- its centre line while it runs west
			local X0, X1 = 54, 20 -- the straight run: from the rampart to where it turns
			local R = 8 -- the turn's radius (centre at X1, Z - R)
			local turnLen = math.pi / 2 * R
			local total = (X0 - X1) + turnLen
			local function heightAt(d) -- d = distance along the stair from its foot
				return RT + 0.15 + (ROOF - RT - 0.15) * d / total
			end
			local stoneA, stoneB = Color3.fromRGB(74, 70, 66), Color3.fromRGB(62, 60, 58)
			-- one tilted slab of ramp from point a to b (with its parapets and edges)
			local function slab(a, b, extra)
				local mid, len = (a + b) / 2, (b - a).Magnitude + (extra or 0)
				local cf = CFrame.lookAt(mid, b)
				part({ Name = "Stair", Size = Vector3.new(W, 1.2, len), CFrame = cf * CFrame.new(0, -0.6, 0), Material = MAT.Slate, Color = stoneA })
				for _, s in ipairs({ -1, 1 }) do
					part({ Name = "Parapet", Size = Vector3.new(0.9, 1.6, len), CFrame = cf * CFrame.new(s * (W / 2 + 0.45), 0.2, 0), Material = MAT.Cobblestone, Color = stoneB })
					part({ Name = "RampartEdge", Size = Vector3.new(0.6, 9, len), CFrame = cf * CFrame.new(s * (W / 2 + 0.6), 4.5, 0), Transparency = 1, CanQuery = false })
				end
			end
			-- the straight run, in a few slabs (piers under each joint)
			local steps = 4
			for i = 0, steps - 1 do
				local xa, xb = X0 - (X0 - X1) * i / steps, X0 - (X0 - X1) * (i + 1) / steps
				local a = Vector3.new(xa, heightAt(X0 - xa), Z)
				local b = Vector3.new(xb, heightAt(X0 - xb), Z)
				slab(a, b, 0.3)
				if xb < 46 then
					box(xb - 1.6, 0, Z - 1.6, xb + 1.6, b.Y - 1, Z + 1.6, MAT.Cobblestone, stoneColor(), "StairPier")
				end
			end
			-- the curve: from heading west to heading south, landing on the roof's north edge
			local cx, cz = X1, Z - R
			local segs = 8
			local prev = Vector3.new(X1, heightAt(X0 - X1), Z)
			for i = 1, segs do
				local th = i / segs * math.pi / 2
				local p = Vector3.new(cx - math.sin(th) * R, heightAt(X0 - X1 + turnLen * i / segs), cz + math.cos(th) * R)
				slab(prev, p, 1.0) -- (extra length closes the gaps on the outside of the curve)
				prev = p
			end
			box(cx - R - 1.6, 0, cz + R * 0.7 - 1.6, cx - R * 0.7 + 1.6, heightAt(X0 - X1 + turnLen * 0.5) - 1, cz + R * 0.7 + 1.6, MAT.Cobblestone, stoneColor(), "StairPier")

			-- the roof (x -46..46, z 215..306): walled all round, open only where the stair lands
			local landA, landB = cx - R - W / 2 - 1, cx - R + W / 2 + 1
			local function roofWall(x1, z1, x2, z2)
				box(x1, ROOF, z1, x2, ROOF + 1.6, z2, MAT.Cobblestone, stoneColor(), "Parapet")
				edge(x1, z1, x2, z2, ROOF)
			end
			-- the gap between the hall and the prison's outer wall (x 46..56) built up solid to the
			-- roof, so the roof runs right across to it (the way out to the town stays hollow)
			box(46, 0, 214, 56, 40, 252, MAT.Cobblestone, stoneColor(), "PrisonMass")
			box(46, 18, 252, 56, 40, 268, MAT.Cobblestone, stoneColor(), "PrisonMass")
			box(46, 0, 268, 56, 40, 306, MAT.Cobblestone, stoneColor(), "PrisonMass")
			box(46, 40, 214, 56, 42, 306, MAT.Slate, COL.Ceiling, "Roof")
			box(46, 0, 306, 56, RT, 309, MAT.Cobblestone, stoneColor(), "PrisonMass") -- (and the slot under the rampart's edge)
			roofWall(-46, 304.6, landA, 306)
			roofWall(landB, 304.6, 56, 306)
			-- (the south edge is the curtain wall, below)
			roofWall(-46, 275, -44.6, 304.6) -- (south of z 275 is the keep)
			roofWall(54.6, 218, 56, 304.6)
			crenellate(-44, 305.3, landA - 2, 305.3, ROOF + 1.6)
			crenellate(landB + 1, 305.3, 54, 305.3, ROOF + 1.6)
			crenellate(-45.3, 277, -45.3, 303, ROOF + 1.6) -- (south of z 275 is the keep's wall)
			crenellate(55.3, 220, 55.3, 303, ROOF + 1.6)
			-- the skylight over the Warden's hall (x -15..15, z 245..275): railed off
			for _, r in ipairs({ { -16, 244, 16, 245 }, { -16, 275, 16, 276 }, { -16, 245, -15, 275 }, { 15, 245, 16, 275 } }) do
				box(r[1], ROOF, r[2], r[3], ROOF + 1.2, r[4], MAT.Metal, Color3.fromRGB(46, 42, 38), "SkylightRail")
				edge(r[1], r[2], r[3], r[4], ROOF)
			end
			brazier(Vector3.new(3, ROOF, 300))
			brazier(Vector3.new(30, ROOF, 290))
			rubble(Vector3.new(-25, ROOF, 295), 2.5, 5)

			-- THE CURTAIN: tall walls on rock closing in the roof, the stair and the rampart's
			-- west reach (north, west and south), so nothing up here looks out past the edge
			-- of the world. East stays open: that's the view over the town.
			local TOP = 62
			local crag = Color3.fromRGB(70, 66, 60)
			box(-56, -1, 306, 56, 0, 341, MAT.Rock, crag, "Crag") -- rock floor under the stair
			box(-56, -1, 205, -45, 0, 306, MAT.Rock, crag, "Crag") -- and down the west side
			box(-56, 0, 337, 52, TOP, 341, MAT.Cobblestone, stoneColor(), "CurtainWall") -- north
			box(-56, 0, 205, -52, TOP, 337, MAT.Cobblestone, stoneColor(), "CurtainWall") -- west
			-- (the south side is the Castellan's keep, built further on)
			crenellate(-54, 339, 50, 339, TOP)
			crenellate(-54, 209, -54, 335, TOP)
			for _, y in ipairs({ 30, 50 }) do -- string courses, so the faces read as built, not blank
				box(-52, y, 336.4, 52, y + 1, 337, MAT.Slate, COL.Wall, "Course")
				box(-52, y, 275, -51.4, y + 1, 336.4, MAT.Slate, COL.Wall, "Course") -- (from the keep's north wall on)
			end
			-- round towers at the corners and where the south wall ends over the roof
			for _, c in ipairs({ { -54, 339 }, { 52, 339 } }) do -- (the south-west corner is the keep's tower)
				local base = 0
				local h = TOP + 8 - base
				part({ Name = "CurtainTower", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 11, 11), CFrame = CFrame.new(c[1], base + h / 2, c[2]) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Cobblestone, Color = stoneColor() })
				part({ Name = "TowerCourse", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 12, 12), CFrame = CFrame.new(c[1], TOP + 7.3, c[2]) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Slate, Color = COL.Wall })
				for i = 0, 7 do
					local ang = i / 8 * math.pi * 2
					part({ Name = "Merlon", Size = Vector3.new(1.8, 2, 2.2), CFrame = CFrame.new(c[1] + math.cos(ang) * 5, TOP + 9, c[2] + math.sin(ang) * 5) * CFrame.Angles(0, -ang, 0), Material = MAT.Cobblestone, Color = stoneColor() })
				end
			end
			-- crags heaped against the walls' feet, and breaking through the rock floor
			local function boulder(x, z, size)
				part({ Name = "Crag", Size = Vector3.new(size, size * rng:NextNumber(0.6, 1.1), size * rng:NextNumber(0.8, 1.3)), CFrame = CFrame.new(x, size * 0.25, z) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 6.28), rng:NextNumber(-0.5, 0.5)), Material = MAT.Rock, Color = crag:Lerp(COL.WallDark, rng:NextNumber(0, 0.5)) })
			end
			for x = -48, 44, 7 do
				boulder(x + rng:NextNumber(-2, 2), rng:NextNumber(331, 335), rng:NextNumber(5, 10))
			end
			for z = 222, 330, 8 do
				boulder(rng:NextNumber(-50.5, -48), z + rng:NextNumber(-2, 2), rng:NextNumber(3.5, 6))
			end
			for _, p in ipairs({ { 40, 324 }, { 26, 326 }, { 4, 322 }, { -14, 318 }, { -32, 324 } }) do
				boulder(p[1], p[2], rng:NextNumber(4, 7))
			end

			-- THE YARD WALK: the rampart carries on south along the top of the Ashen Yard's east
			-- side (x 41..52, y 30), the yard's own battlements its inner parapet, a tall outer wall
			-- on the east and across its south end. A stair at the north end climbs to the roof.
			local YW = 30
			box(41, 0, 120, 52, YW, 148, MAT.Cobblestone, stoneColor(), "YardWalk")
			box(41, 13, 148, 52, YW, 163, MAT.Cobblestone, stoneColor(), "YardWalk") -- (over the sewer's mouth)
			box(41, 0, 163, 52, YW, 214, MAT.Cobblestone, stoneColor(), "YardWalk")
			box(41, YW, 120, 52, YW + 0.15, 214, MAT.Slate, Color3.fromRGB(62, 60, 58), "RampartWalk")
			-- (no invisible wall on the yard side: you can hop the battlements and drop into the
			-- yard from any of its walks - there's no fall damage)
			-- the slot between the yard's north wall and the Warden's hall filled, so the walk
			-- looks across the yard at stone, not off the world (the circuit's outer walls,
			-- below, close in its far sides)
			box(-46, 0, 201, -10, YW, 214, MAT.Cobblestone, stoneColor(), "PrisonMass")
			box(10, 0, 201, 41, YW, 214, MAT.Cobblestone, stoneColor(), "PrisonMass")
			box(-10, 16, 201, 10, YW, 214, MAT.Cobblestone, stoneColor(), "PrisonMass") -- (over the fog passage)

			-- THE LADDER: two rails and rungs, lying flat on the walk beside a gap in the
			-- battlements, its foot at the gap. Kicked (only from up here: init.server) it's
			-- stood up, swung round, heaved over the gap and dropped down against the yard's
			-- wall, for good - a way both ways. What you climb is an invisible truss inside it.
			do
				local LZ, LEN = 179, 32
				local truss = Instance.new("TrussPart")
				truss.Name = "YardLadder"
				truss.Size = Vector3.new(2, LEN, 2)
				truss.Anchored = true
				truss.Transparency = 1
				truss.CanCollide, truss.CanQuery = false, false -- (lying down it's just a prop; it climbs once it's down)
				-- built standing where it ends up (rungs across the wall, along z), then laid down
				local down = CFrame.new(38, LEN / 2, LZ) * CFrame.Angles(0, math.pi / 2, 0)
				truss.CFrame = down
				truss.Parent = map
				local wood, dark = Color3.fromRGB(84, 62, 42), Color3.fromRGB(62, 46, 32)
				local function bit(size, offset, color)
					local p = part({ Name = "LadderWood", Size = size, CFrame = down * offset, Material = MAT.Wood, Color = color, CanCollide = false, CanQuery = false, CanTouch = false, Massless = true })
					p.Anchored = false
					local w = Instance.new("WeldConstraint")
					w.Part0, w.Part1 = truss, p
					w.Parent = p
				end
				for _, x in ipairs({ -0.8, 0.8 }) do
					bit(Vector3.new(0.28, LEN, 0.32), CFrame.new(x, 0, 0), wood)
				end
				local lr = Random.new(179) -- (its own stream: the map's doesn't shift)
				for y = -LEN / 2 + 0.6, LEN / 2 - 0.4, 1 do
					bit(Vector3.new(1.65, 0.16, 0.18), CFrame.new(0, y, 0) * CFrame.Angles(0, 0, lr:NextNumber(-0.04, 0.04)), dark)
				end
				for _, y in ipairs({ -LEN / 2 + 3, LEN / 2 - 3 }) do -- rope lashings near each end
					for _, x in ipairs({ -0.8, 0.8 }) do
						bit(Vector3.new(0.36, 0.3, 0.4), CFrame.new(x, y, 0), Color3.fromRGB(120, 104, 74))
					end
				end
				-- laid flat on the walk (rails and rungs on the deck), its foot at the gap, running north
				truss.CFrame = CFrame.new(44, YW + 0.3, LZ + LEN / 2) * CFrame.Angles(math.pi / 2, 0, 0)
				info.Ladder = truss
				info.LadderDown = down
				-- (the gap stays shut until it's down)
				info.LadderBlock = part({ Name = "RampartEdge", Size = Vector3.new(0.6, 9, 2), CFrame = CFrame.new(40.7, YW + 4.5, LZ), Transparency = 1, CanQuery = false })
				local spot = part({ Name = "LadderPrompt", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(42.5, YW + 1.5, LZ + 1), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
				info.LadderPrompt = prompt(spot, "Kick down", "Ladder", 0, 7)
				-- once it's down: "Climb" at its foot and at its top (players can't climb freely:
				-- Climbing is off for every rig, so init.server carries you up and down it)
				info.LadderClimb = {
					foot = Vector3.new(36.4, 3, LZ), -- standing at its foot in the yard, facing the wall
					top = Vector3.new(36.4, YW + 3.15, LZ), -- at its top, still on the rungs
					off = Vector3.new(43, YW + 3.15, LZ), -- stepped off onto the walk
				}
				local function climbPrompt(pos)
					local p = part({ Name = "LadderClimbPrompt", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(pos), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
					local pp = prompt(p, "Climb", "Ladder", 0, 6)
					pp.Enabled = false
					return pp
				end
				info.LadderUpPrompt = climbPrompt(Vector3.new(36.4, 2.5, LZ))
				info.LadderDownPrompt = climbPrompt(Vector3.new(41.8, YW + 2, LZ))
				-- the two merlons either side of the gap come down (they boxed the ladder's top in)
				for _, m in ipairs(map:GetChildren()) do
					local c = m:IsA("BasePart") and m.Name == "Merlon" and m.Position
					if c and math.abs(c.X - 40) < 0.1 and math.abs(c.Y - (YW + 1)) < 0.1 and (math.abs(c.Z - (LZ - 2)) < 0.1 or math.abs(c.Z - (LZ + 2)) < 0.1) then
						m:Destroy()
					end
				end
				-- clear the yard wall's dressing (buttresses etc.) out of where it will stand
				local lo, hi = Vector3.new(36, 0, LZ - 1.6), Vector3.new(39, LEN, LZ + 1.6)
				for _, p in ipairs(detailFolder:GetDescendants()) do
					if p:IsA("BasePart") then
						local c, h, cf = p.Position, p.Size / 2, p.CFrame
						local ex = Vector3.new(
							math.abs(cf.XVector.X) * h.X + math.abs(cf.YVector.X) * h.Y + math.abs(cf.ZVector.X) * h.Z,
							math.abs(cf.XVector.Y) * h.X + math.abs(cf.YVector.Y) * h.Y + math.abs(cf.ZVector.Y) * h.Z,
							math.abs(cf.XVector.Z) * h.X + math.abs(cf.YVector.Z) * h.Y + math.abs(cf.ZVector.Z) * h.Z
						)
						if c.X - ex.X < hi.X and c.X + ex.X > lo.X and c.Y - ex.Y < hi.Y and c.Y + ex.Y > lo.Y and c.Z - ex.Z < hi.Z and c.Z + ex.Z > lo.Z then
							p:Destroy()
						end
					end
				end
			end
			-- the chest in the walk's far corner, facing up the walk (GameServer/Mimic.lua: it isn't one).
			-- It may hop about the walk south of the stair, never off it.
			info.Mimic = {
				CFrame = CFrame.lookAt(Vector3.new(49.5, YW + 0.15, 123), Vector3.new(49.1, YW + 0.15, 124)),
				Min = Vector3.new(42.6, 0, 121.5),
				Max = Vector3.new(50.4, 0, 188),
			}

			-- THE CIRCUIT: from the mimic's corner the rampart turns west down a walled
			-- corridor along the yard's south side (y 30), climbs a stair round the south-west
			-- corner onto a higher walk behind the yard's west wall (y 38), and at its north end
			-- climbs again through a gateway onto the hall's roof. Open to the sky, but walled
			-- in on every side. (All of it sits above the cell block, Wick's nook and the
			-- Usher's Walk, whose ceilings top out at y 18.)
			local WW = 38 -- the west walk
			local deck = Color3.fromRGB(62, 60, 58)
			-- (toward the yard the circuit only has low stone - the yard's own battlements, a
			-- parapet - and nothing behind it: hop it and you drop into the yard)
			-- south corridor (x -52..52, z 109..119)
			box(-52, 18, 109, 52, YW, 119, MAT.Cobblestone, stoneColor(), "YardWalk")
			box(-52, YW, 109, 52, YW + 0.15, 119, MAT.Slate, deck, "RampartWalk")
			box(41, YW, 119, 46, YW + 0.15, 120, MAT.Slate, deck, "RampartWalk") -- (the doorway from the east walk)
			box(52, 18, 109, 56, 44, 117, MAT.Cobblestone, stoneColor(), "CurtainWall") -- its east end

			-- THE OUTER WALLS, with barred cells let into them (old overflow cells for the
			-- prison, roofed, the dead still in them), arrow slits, and a stretch fallen in
			local cellRng = Random.new(109) -- (its own stream: the map's doesn't shift)
			local VOIDC = Color3.fromRGB(8, 8, 10)
			-- a cell behind an opening in an outer wall. frame: at the opening's centre on the
			-- wall's inner face, floor level, looking OUT through the wall (-Z = deeper)
			local function cell(frame, wallT, broken)
				local function rel(name, size, cf, color, mat, solid)
					return part({ Name = name, Size = size, CFrame = frame * cf, Material = mat or MAT.Cobblestone, Color = color or stoneColor(), CanCollide = solid ~= false })
				end
				local D = wallT + 6 -- the cell runs 6 deep past the wall
				rel("CellWall", Vector3.new(1, 10, D), CFrame.new(-3.5, 5, -D / 2)) -- sides
				rel("CellWall", Vector3.new(1, 10, D), CFrame.new(3.5, 5, -D / 2))
				rel("CellWall", Vector3.new(8, 10, 1), CFrame.new(0, 5, -D - 0.5)) -- back
				rel("CellRoof", Vector3.new(8, 2, D + 1), CFrame.new(0, 9, -(D + 1) / 2)) -- (8 high inside)
				rel("CellFloor", Vector3.new(6, 0.15, D), CFrame.new(0, 0.075, -D / 2), Color3.fromRGB(54, 50, 46), MAT.Slate)
				rel("Straw", Vector3.new(3.2, 0.12, 2.4), CFrame.new(cellRng:NextNumber(-1, 1), 0.2, -D + 1.6) * CFrame.Angles(0, cellRng:NextNumber(0, 3), 0), COL.Straw, MAT.Grass, false)
				-- the bars, across the opening at the wall's inner face (one cell's are broken out)
				for k = 0, 8 do
					local x = -2.8 + k * 0.7
					if not (broken and (k == 3 or k == 4 or k == 5)) then
						rel("CellBar", Vector3.new(0.14, 8, 0.14), CFrame.new(x, 4, -0.3), COL.Iron, MAT.Metal)
					end
				end
				rel("CellBar", Vector3.new(6, 0.18, 0.18), CFrame.new(0, 7.6, -0.3), COL.Iron, MAT.Metal)
				if broken then
					rel("CellBar", Vector3.new(0.14, 6.5, 0.14), CFrame.new(0.3, 0.2, 0.9) * CFrame.Angles(math.pi / 2, 0.4, 0), COL.Iron, MAT.Metal) -- one lies on the walk
				end
				local back = frame * Vector3.new(cellRng:NextNumber(-1.5, 1.5), 0, -D + 0.8)
				Detail.slumpedSkeleton(back, frame:VectorToWorldSpace(Vector3.new(0, 0, 1)))
				Detail.bucket(frame * Vector3.new(2.3, 0, -D + 1.2))
			end
			local oldDetailRng = Detail.useRng(Random.new(110))

			-- south wall (x -56..56, inner face z 109): cells at x -30, 0 (broken bars), 30;
			-- the stretch x 3..27 has fallen in (a jagged top, its stones on the walk)
			local SC = { -30, 0, 30 }
			local edgesX = { -56 }
			for _, c in ipairs(SC) do
				table.insert(edgesX, c - 3)
				table.insert(edgesX, c + 3)
			end
			table.insert(edgesX, 56)
			for i = 1, #edgesX, 2 do
				local x1, x2 = edgesX[i], edgesX[i + 1]
				if x1 == 3 then
					-- the fallen stretch: down to y 40-42 in ragged steps
					box(x1, 18, 105, x2, 40, 109, MAT.Cobblestone, stoneColor(), "CurtainWall")
					local x = x1
					while x < x2 do
						local w = math.min(cellRng:NextNumber(2, 4.5), x2 - x)
						box(x, 40, 105, x + w, 40 + cellRng:NextNumber(0, 2.5), 109, MAT.Cobblestone, stoneColor(), "CurtainWall")
						x += w
					end
					rubble(Vector3.new(14, YW + 0.15, 112), 3, 7)
					part({ Name = "Merlon", Size = Vector3.new(2, 2, 2), CFrame = CFrame.new(10, YW + 1, 113) * CFrame.Angles(0.4, 0.8, 0.3), Material = MAT.Cobblestone, Color = stoneColor() })
				else
					local wallColor = stoneColor() -- (one colour, whether it is one piece or four: the random stream stays as it was)
					if x1 == 33 then -- the prison wing's gate: a doorway x 44..52, y 30..41 (the portcullis is in section 10)
						box(33, 18, 105, 44, 44, 109, MAT.Cobblestone, wallColor, "CurtainWall")
						box(52, 18, 105, 56, 44, 109, MAT.Cobblestone, wallColor, "CurtainWall")
						box(44, 18, 105, 52, 30, 109, MAT.Cobblestone, wallColor, "CurtainWall")
						box(44, 41, 105, 52, 44, 109, MAT.Cobblestone, wallColor, "CurtainWall")
					else
						box(x1, 18, 105, x2, 44, 109, MAT.Cobblestone, wallColor, "CurtainWall")
					end
					crenellate(x1 + 1, 107, x2 - 1, 107, 44)
					-- arrow slits along it
					for x = x1 + 6, x2 - 4, 10 do
						if not (x1 == 33 and x > 43 and x < 53) then -- (none in the doorway)
							box(x - 0.35, YW + 3, 108.95, x + 0.35, YW + 7, 109.05, MAT.Slate, VOIDC, "ArrowSlit")
						end
					end
				end
			end
			for _, c in ipairs(SC) do
				box(c - 3, YW + 8, 105, c + 3, 44, 109, MAT.Cobblestone, stoneColor(), "CurtainWall") -- over the cell's mouth
				box(c - 3, 18, 105, c + 3, YW, 109, MAT.Cobblestone, stoneColor(), "CurtainWall") -- under it
				box(c - 4, 18, 98, c + 4, YW, 105, MAT.Cobblestone, stoneColor(), "CellBase")
				cell(CFrame.lookAt(Vector3.new(c, YW + 0.15, 109), Vector3.new(c, YW + 0.15, 108)), 4, c == 0)
			end

			-- the west side: outer wall all the way up to the hall (inner face x -52), with
			-- cells at z 150 and 185
			local WC = { 150, 185 }
			local edgesZ = { 105, 147, 153, 182, 188, 215 }
			for i = 1, #edgesZ, 2 do
				local z1, z2 = edgesZ[i], edgesZ[i + 1]
				box(-56, 14, z1, -52, WW + 14, z2, MAT.Cobblestone, stoneColor(), "CurtainWall")
				crenellate(-54, z1 + 1, -54, z2 - 1, WW + 14)
				if z1 >= 147 then
					for z = z1 + 6, z2 - 4, 10 do
						box(-52.05, WW + 3, z - 0.35, -51.95, WW + 7, z + 0.35, MAT.Slate, VOIDC, "ArrowSlit")
					end
				end
			end
			for _, c in ipairs(WC) do
				box(-56, WW + 8, c - 3, -52, WW + 14, c + 3, MAT.Cobblestone, stoneColor(), "CurtainWall")
				box(-56, 14, c - 3, -52, WW, c + 3, MAT.Cobblestone, stoneColor(), "CurtainWall")
				box(-63, 14, c - 4, -56, WW, c + 4, MAT.Cobblestone, stoneColor(), "CellBase")
				cell(CFrame.lookAt(Vector3.new(-52, WW + 0.15, c), Vector3.new(-53, WW + 0.15, c)), 4, false)
			end
			Detail.useRng(oldDetailRng)

			-- stair round the south-west corner: north from z 119 (y 30) to z 135 (y 38)
			do
				local a, b = Vector3.new(-46.5, YW + 0.15, 119), Vector3.new(-46.5, WW + 0.15, 135)
				local cf = CFrame.lookAt((a + b) / 2, b)
				local len = (b - a).Magnitude + 0.4
				box(-52, 14, 119, -41, YW, 135, MAT.Cobblestone, stoneColor(), "YardWalk")
				part({ Name = "Stair", Size = Vector3.new(11, 1.2, len), CFrame = cf * CFrame.new(0, -0.6, 0), Material = MAT.Slate, Color = Color3.fromRGB(74, 70, 66) })
				for i = 1, 7 do
					box(-52, YW, 119 + i * 2, -41, YW + i, 121 + i * 2, MAT.Cobblestone, stoneColor(), "StairFill")
				end
				-- a low rail on its yard side (facing north, -X is east)
				part({ Name = "Parapet", Size = Vector3.new(0.9, 1.4, len), CFrame = cf * CFrame.new(-5.05, 0.1, 0), Material = MAT.Cobblestone, Color = stoneColor() })
				part({ Name = "RampartEdge", Size = Vector3.new(0.6, 9, len), CFrame = cf * CFrame.new(-5.2, 4.5, 0), Transparency = 1, CanQuery = false })
			end
			-- the west walk (x -52..-41, z 135..201), above and behind the yard's west wall;
			-- it ends at the Castellan's keep's gate (below)
			box(-52, 14, 135, -41, WW, 201, MAT.Cobblestone, stoneColor(), "YardWalk")
			box(-52, WW, 135, -41, WW + 0.15, 201, MAT.Slate, deck, "RampartWalk")
			box(-42, WW, 135, -41, WW + 1.2, 201, MAT.Cobblestone, stoneColor(), "Parapet") -- low, along its yard side
			for _, x in ipairs({ -42, -15, 42 }) do -- (between the cells; none over the fallen stretch)
				torch(Vector3.new(x, YW + 6, 109.1), Vector3.new(0, 0, 1))
			end
			for _, z in ipairs({ 140, 168, 200 }) do
				torch(Vector3.new(-51.9, WW + 6, z), Vector3.new(1, 0, 0))
			end
			brazier(Vector3.new(-44, YW + 0.15, 113))

			-------------------------------------------------------------------
			-- THE CASTELLAN'S KEEP: the prison's clearance post, raised over the hall's roof up to
			-- the far side of its skylight and out over the slot behind the yard (x -56..46,
			-- z 201..275). The skylight is its light well: open down through both floors to the
			-- Warden's hall, grated over at the top. In by its gate at the end of the west walk;
			-- out to the hall's roof by a portcullis whose chain only pulls from inside. The
			-- spiral stair climbs on to a turret on the roof - the battlements, where the
			-- Castellan waits - behind a door only the strongroom's key opens (init.server).
			--   floor 1 (y 42): checkpoint | stair hall | armory     (north) great hall | well | chapel
			--   floor 2 (y 54): records    | landing    | barracks   (north) quarters   | well | strongroom
			--   roof   (y 68): the battlements (the boss arena)
			-------------------------------------------------------------------
			do
				local F1, F2, KTOP = ROOF, 54, 68 -- floor 1, floor 2, the roof's walking surface
				local X1, X2, Z1, Z2 = -52, 44, 204, 272 -- inside the outer walls
				local DIV = 241 -- the wall (z 241..242) between the south rooms and the north ones
				local PW, PE = -24, 23 -- the partitions (x -24..-23 and 23..24) in the south range
				local SX, SZ = 0, 222 -- the spiral stair's centre
				local H1, H2 = F2 - 1.2 - F1, KTOP - 1 - F2 -- clear height of each floor
				local keepRng = Random.new(245) -- (its own streams: the map's don't shift)
				local oldRng = Detail.useRng(Random.new(246))
				local brick = Color3.fromRGB(96, 84, 74)
				local woodDark, woodLight = Color3.fromRGB(58, 42, 30), Color3.fromRGB(96, 70, 48)
				local iron = COL.Iron
				local red, navy, gold = Color3.fromRGB(110, 26, 24), Color3.fromRGB(46, 40, 60), Color3.fromRGB(176, 140, 66)
				local stairStone, pale = Color3.fromRGB(74, 70, 66), Color3.fromRGB(96, 92, 86)
				local function blk(x1, y1, z1, x2, y2, z2, name, color, mat)
					return box(x1, y1, z1, x2, y2, z2, mat or MAT.Cobblestone, color or stoneColor(), name or "KeepWall")
				end
				local function prop(name, size, cf, color, mat, solid)
					return part({ Name = name, Size = size, CFrame = cf, Material = mat or MAT.Wood, Color = color or woodDark, CanCollide = solid ~= false })
				end
				-- a locked chest (the key on the throne's dais opens them all; init.server): a body,
				-- and a lid hinged on its back edge. cf = the middle of its foot on the floor; its
				-- lock faces cf's -Z. loot = a Config.Weapons key, or nil (nothing in it)
				info.KeepChests = {}
				local function keepChest(name, size, cf, loot)
					local bodyH, lidH = size.Y - 0.4, 0.4
					prop(name, Vector3.new(size.X, bodyH, size.Z), cf * CFrame.new(0, bodyH / 2, 0), woodLight, MAT.WoodPlanks)
					prop(name .. "Band", Vector3.new(size.X + 0.05, 0.25, size.Z + 0.05), cf * CFrame.new(0, bodyH * 0.7, 0), iron, MAT.Metal, false)
					prop(name .. "Lock", Vector3.new(0.4, 0.45, 0.1), cf * CFrame.new(0, bodyH - 0.25, -size.Z / 2 - 0.05), gold, MAT.Metal, false)
					local lid = prop(name .. "Lid", Vector3.new(size.X + 0.05, lidH, size.Z + 0.05), cf * CFrame.new(0, bodyH + lidH / 2, 0), woodLight, MAT.WoodPlanks)
					table.insert(info.KeepChests, { Lid = lid, Hinge = cf * CFrame.new(0, size.Y, size.Z / 2), Loot = loot, Prompt = prompt(lid, "Open", "Locked Chest", 0.5, 7) })
				end
				local function cyl(name, len, dia, cf, color, mat, solid) -- a cylinder along cf's X
					return part({ Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(len, dia, dia), CFrame = cf, Material = mat or MAT.Metal, Color = color or iron, CanCollide = solid == true })
				end
				local function bar(a, b, thick, color, name) -- a straight run of iron from a to b
					local d = b - a
					cyl(name or "Handrail", d.Magnitude + 0.1, thick, CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0), color or iron, MAT.Metal)
				end
				local function invisible(p)
					p.Transparency, p.CanQuery, p.CastShadow = 1, false, false
					return p
				end
				local function fire(pos, size, range)
					local f = part({ Name = "Flame", Size = Vector3.new(0.5, 0.5, 0.5), CFrame = CFrame.new(pos), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
					local fx = Instance.new("Fire")
					fx.Size, fx.Heat = size, size * 1.5
					fx.Color, fx.SecondaryColor = Color3.fromRGB(255, 120, 40), Color3.fromRGB(255, 200, 90)
					fx.Parent = f
					local l = Instance.new("PointLight")
					l.Color, l.Range, l.Brightness, l.Shadows = Color3.fromRGB(255, 160, 80), range, 1.6, true
					l.Parent = f
					addFlicker(l)
					return f
				end

				-- walls. wallRun("z", x, ...) is a wall x..x+1 running along z; wallRun("x", z, ...)
				-- one z..z+1 running along x. gaps: { a1, a2, from, to, kind } openings (from/to
				-- above the floor f); kind "door" gets an iron-bound wooden frame, "bars" iron bars,
				-- "open" nothing (the great door brings its own)
				local function wallRun(axis, c, f, top, a1, a2, gaps, color, mat)
					local function seg(b1, y1, b2, y2)
						if b2 - b1 > 0.01 and y2 - y1 > 0.01 then
							if axis == "z" then
								blk(c, y1, b1, c + 1, y2, b2, "KeepWall", color or brick, mat or MAT.Brick)
							else
								blk(b1, y1, c, b2, y2, c + 1, "KeepWall", color or brick, mat or MAT.Brick)
							end
						end
					end
					local function at(b, y, out) -- a point on the wall's centre plane
						return axis == "z" and Vector3.new(c + 0.5 + out, y, b) or Vector3.new(b, y, c + 0.5 + out)
					end
					local a = a1
					for _, g in ipairs(gaps or {}) do
						seg(a, f, g[1], top)
						seg(g[1], f, g[2], f + g[3])
						seg(g[1], f + g[4], g[2], top)
						if g[5] == "door" then
							for _, b in ipairs({ g[1], g[2] }) do
								local p = at(b, f + g[4] / 2, 0)
								prop("DoorFrame", axis == "z" and Vector3.new(1.3, g[4], 0.6) or Vector3.new(0.6, g[4], 1.3), CFrame.new(p), woodDark, MAT.Wood)
							end
							local m = at((g[1] + g[2]) / 2, f + g[4] - 0.1, 0)
							prop("DoorFrame", axis == "z" and Vector3.new(1.3, 0.6, g[2] - g[1] + 0.6) or Vector3.new(g[2] - g[1] + 0.6, 0.6, 1.3), CFrame.new(m), woodDark, MAT.Wood)
						elseif g[5] == "bars" then
							for b = g[1] + 0.35, g[2] - 0.3, 0.55 do
								prop("WindowBar", Vector3.new(0.16, g[4] - g[3], 0.16), CFrame.new(at(b, f + (g[3] + g[4]) / 2, 0)), iron, MAT.Metal)
							end
							local sill = at((g[1] + g[2]) / 2, f + g[3] - 0.1, 0)
							prop("Sill", axis == "z" and Vector3.new(1.6, 0.3, g[2] - g[1] + 0.6) or Vector3.new(g[2] - g[1] + 0.6, 0.3, 1.6), CFrame.new(sill), pale, MAT.Slate)
						end
						a = g[2]
					end
					seg(a, f, a2, top)
				end
				-- a wall face dressed (brick, plinth, cornice) only between its openings, so no
				-- skirting ever runs across a doorway
				local function dress(axis, c, sign, f, h, a1, a2, gaps)
					local spans, a = {}, a1
					for _, g in ipairs(gaps or {}) do
						table.insert(spans, { a, g[1] })
						a = g[2]
					end
					table.insert(spans, { a, a2 })
					for _, s in ipairs(spans) do
						local w = s[2] - s[1]
						if w >= 3 then
							local m = (s[1] + s[2]) / 2
							local cf = axis == "x" and Detail.face(m, c, 0, sign, f) or Detail.face(c, m, sign, 0, f)
							Detail.dressWall(cf, w, h, "keep")
						end
					end
				end

				-- FOUNDATION: solid up to floor 1 wherever the hall's roof isn't (the way in from the
				-- west walk stays down at y 38; the fog passage below and the well stay hollow)
				blk(-52, 0, 215, -46, F1, 275, "KeepBase")
				blk(-52, 0, 201, -50, F1, 215, "KeepBase")
				blk(-43, 0, 201, -10, F1, 215, "KeepBase")
				blk(-10, 16, 201, 10, F1, 215, "KeepBase")
				blk(10, 0, 201, 46, F1, 215, "KeepBase")
				blk(-50, 0, 212, -43, F1, 215, "KeepBase")
				blk(-50, 0, 201, -43, WW, 212, "KeepBase")
				blk(-15, 40, 272, 15, F1, 275, "KeepBase") -- (the skylight's far end, under the north wall)

				-- OUTER SHELL
				blk(-56, F1, 201, -52, KTOP, 275) -- west (the old curtain carries on below it)
				blk(44, 30, 201, 46, KTOP, 275) -- east
				blk(-52, 30, 201, -50, KTOP, 204) -- south, west of the gate
				blk(-43, 30, 201, 46, KTOP, 204) -- south, east of it (the yard looks up at this)
				blk(-50, WW + 9, 201, -43, KTOP, 204) -- over the gate
				blk(-52, F1, 272, -22, KTOP, 275) -- north, west of the portcullis
				blk(-16, F1, 272, 46, KTOP, 275) -- north, east of it
				blk(-22, F1 + 8, 272, -16, KTOP, 275) -- over it (the portcullis rises into here)
				-- floors: floor 2's slab round the stairwell (x -9..9, z 213..231, a tongue meeting
				-- the stair at z 229..231) and the well (x -15..15, z 245..272)
				for _, s in ipairs({ { X1, Z1, X2, 213 }, { X1, 213, -9, 231 }, { 9, 213, X2, 231 }, { X1, 231, X2, 245 }, { X1, 245, -15, Z2 }, { 15, 245, X2, Z2 }, { -9, 229, 9, 231 } }) do
					blk(s[1], F2 - 1.2, s[2], s[3], F2, s[4], "KeepFloor", Color3.fromRGB(60, 56, 52), MAT.Slate)
				end
				for _, s in ipairs({ { X1, Z1, -50, Z2 }, { -50, 212, -43, Z2 }, { -43, Z1, X2, 245 }, { -43, 245, -15, Z2 }, { 15, 245, X2, Z2 } }) do
					blk(s[1], F1, s[2], s[3], F1 + 0.12, s[4], "KeepFloor", Color3.fromRGB(58, 55, 52), MAT.Slate)
				end
				-- the roof: round the stair's hole (a tongue at its top), the grate over the well below
				for _, s in ipairs({ { -56, 201, 46, 213 }, { -56, 213, -9, 231 }, { 9, 213, 46, 231 }, { -56, 231, 46, 245 }, { -56, 245, -15, 275 }, { 15, 245, 46, 275 }, { -15, 272, 15, 275 }, { -9, 213, -1, 217 } }) do
					blk(s[1], KTOP - 1, s[2], s[3], KTOP, s[4], "KeepRoof", Color3.fromRGB(56, 54, 52), MAT.Slate)
				end
				invisible(blk(-15, KTOP - 0.45, 245, 15, KTOP - 0.1, 272, "GrateFloor")) -- (what you actually stand on)
				for x = -14.25, 14.25, 1.5 do
					prop("GrateBar", Vector3.new(0.28, 0.35, 27), CFrame.new(x, KTOP - 0.2, 258.5), iron, MAT.Metal, false)
				end
				for z = 246, 271, 1.5 do
					prop("GrateBar", Vector3.new(30, 0.3, 0.22), CFrame.new(0, KTOP - 0.22, z), iron, MAT.Metal, false)
				end
				-- embers drifting up the well, out through the grate
				do
					local e = part({ Name = "WellEmbers", Size = Vector3.new(28, 1, 25), CFrame = CFrame.new(0, 26, 258.5), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
					local pe = Instance.new("ParticleEmitter")
					pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
					pe.Rate = 16
					pe.Lifetime = NumberRange.new(6, 9)
					pe.Speed = NumberRange.new(6, 10)
					pe.EmissionDirection = Enum.NormalId.Top
					pe.SpreadAngle = Vector2.new(12, 12)
					pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.22), NumberSequenceKeypoint.new(1, 0) })
					pe.Color = ColorSequence.new(Color3.fromRGB(255, 150, 60), Color3.fromRGB(255, 80, 30))
					pe.LightEmission = 1
					pe.Parent = e
				end

				-- outside: square towers on the west corners, bartizans on the east, arrow slits,
				-- machicolation corbels under the parapets, an arch over the portcullis
				for _, z in ipairs({ 197, 267 }) do
					blk(-60, 14, z, -52, KTOP + 7, z + 8)
					blk(-60.6, KTOP + 4.8, z - 0.6, -51.4, KTOP + 5.4, z + 8.6, "TowerCourse", COL.Wall, MAT.Slate)
					crenellate(-60, z, -52, z, KTOP + 7)
					crenellate(-60, z + 8, -52, z + 8, KTOP + 7)
					crenellate(-60, z, -60, z + 8, KTOP + 7)
					crenellate(-52, z, -52, z + 8, KTOP + 7)
				end
				for _, z in ipairs({ 272 }) do -- (the south-east corner opens onto the bridge east)
					part({ Name = "Bartizan", Shape = Enum.PartType.Cylinder, Size = Vector3.new(12, 6, 6), CFrame = CFrame.new(46.5, KTOP, z) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Cobblestone, Color = stoneColor() })
					part({ Name = "BartizanCorbel", Size = Vector3.new(3, 3, 3), CFrame = CFrame.new(46, KTOP - 7.2, z) * CFrame.Angles(0, math.pi / 4, 0), Material = MAT.Cobblestone, Color = stoneColor() })
				end
				for x = -46, 40, 8 do
					for _, y in ipairs({ F1 + 4, F2 + 4 }) do
						if math.abs(x + 19) > 5 and math.abs(x) > 16 then
							blk(x - 0.35, y, 274.95, x + 0.35, y + 4, 275.05, "ArrowSlit", VOIDC, MAT.Slate)
						end
						if x > -42 then
							blk(x - 0.35, y, 200.95, x + 0.35, y + 4, 201.05, "ArrowSlit", VOIDC, MAT.Slate)
						end
					end
				end
				for x = -55, 45, 2 do
					blk(x - 0.4, KTOP - 3, 275, x + 0.4, KTOP - 1.6, 275.8, "Corbel", COL.Wall, MAT.Slate)
					blk(x - 0.4, KTOP - 3, 200.2, x + 0.4, KTOP - 1.6, 201, "Corbel", COL.Wall, MAT.Slate)
				end
				blk(-56, KTOP - 1.6, 275, 46, KTOP - 1, 276, "Machicolation", COL.Wall, MAT.Slate)
				blk(-56, KTOP - 1.6, 200, 46, KTOP - 1, 201, "Machicolation", COL.Wall, MAT.Slate)
				Detail.archRib(Detail.face(-19, 275, 0, 1, F1), 0, 8, 3.6, 2.4, 0.9, 1.1, 0.5, 7, MAT.Cobblestone, COL.Wall, false)

				-- THE WAY IN: an arched gate in the south wall where the west walk ends (x -50..-43),
				-- its studded doors folded back flat, then a broad stair up to floor 1
				blk(-50, WW, 201, -43, WW + 0.15, 204, "RampartWalk", Color3.fromRGB(62, 60, 58), MAT.Slate)
				Detail.archRib(Detail.face(-46.5, 201, 0, -1, WW), 0, 9, 3.5, 2.2, 1, 1.2, 0.5, 7, MAT.Cobblestone, COL.Wall, false)
				do
					local a, b = Vector3.new(-46.5, WW + 0.15, 204), Vector3.new(-46.5, F1, 212.2)
					local cf = CFrame.lookAt((a + b) / 2, b)
					local len = (b - a).Magnitude + 0.4
					part({ Name = "Stair", Size = Vector3.new(7, 1.2, len), CFrame = cf * CFrame.new(0, -0.6, 0), Material = MAT.Slate, Color = stairStone })
					part({ Name = "StairRunner", Size = Vector3.new(3, 0.06, len), CFrame = cf * CFrame.new(0, 0.03, 0), Material = MAT.Fabric, Color = red, CanCollide = false })
					for i = 1, 4 do
						blk(-50, WW, 204 + i * 2, -43, WW + i, 206 + i * 2, "StairFill")
					end
				end
				blk(-43, F1, 204.6, -42.4, F1 + 1.4, 212, "Parapet") -- (along the drop beside the stair)
				for _, s in ipairs({ -1, 1 }) do
					-- the leaves stand folded back against the gate's sides, inside the wall's depth
					local x = s < 0 and -49.8 or -43.2
					local leaf = prop("KeepDoor", Vector3.new(0.4, 9, 2.8), CFrame.new(x, WW + 4.5, 202.6), woodDark, MAT.WoodPlanks, false)
					for _, y in ipairs({ -3.2, 0, 3.2 }) do
						prop("DoorBand", Vector3.new(0.5, 0.35, 2.8), leaf.CFrame * CFrame.new(0, y, 0), iron, MAT.Metal, false)
					end
				end
				blk(-50, WW, 201, -49.6, WW + 9, 204, "KeepWall") -- (the leaves' recesses: no gap at the jambs)
				blk(-43.4, WW, 201, -43, WW + 9, 204, "KeepWall")

				-- INNER WALLS (both floors): the partitions in the south range, the wall between
				-- south and north rooms, and the well's barred walls
				local WELLWIN = { { 247, 251, 2.5, 7.5, "bars" }, { 255, 259, 2.5, 7.5, "bars" }, { 263, 267, 2.5, 7.5, "bars" } }
				for fi, f in ipairs({ F1, F2 }) do
					local top = fi == 1 and F2 - 1.2 or KTOP - 1
					wallRun("z", PW, f, top, Z1, DIV, { { 220, 226, 0, 9, "door" } })
					wallRun("z", PE, f, top, Z1, DIV, { { 220, 226, 0, 9, "door" } })
					wallRun("x", DIV, f, top, X1, -15, { { -34, -28, 0, 9, "door" }, { -22, -17, 0, 9, "door" } })
					if fi == 1 then
						wallRun("x", DIV, f, top, 15, X2, { { 17, 22, 0, 9, "door" }, { 30, 36, 0, 9, "door" } })
					else
						wallRun("x", DIV, f, top, 15, X2, { { 16.5, 22.5, 0, 10, "open" } }) -- (the strongroom's great door)
					end
					wallRun("z", -16, f, top, 242, Z2, WELLWIN, Color3.fromRGB(84, 80, 74), MAT.Cobblestone)
					wallRun("z", 15, f, top, 242, Z2, WELLWIN, Color3.fromRGB(84, 80, 74), MAT.Cobblestone)
				end
				-- railings where the floors meet the well
				for _, f in ipairs({ F1, F2 }) do
					blk(-15, f, 244.6, 15, f + 1.2, 245, "WellRail", iron, MAT.Metal)
					for x = -14, 14, 2 do
						prop("WellPost", Vector3.new(0.3, 3.2, 0.3), CFrame.new(x, f + 1.6, 244.8), iron, MAT.Metal, false)
					end
					blk(-15, f + 3, 244.6, 15, f + 3.3, 245, "WellRail", iron, MAT.Metal)
					invisible(blk(-15, f, 244.4, 15, f + 9, 244.6, "RampartEdge"))
				end

				-- every wall face dressed, between its openings
				for fi, f in ipairs({ F1, F2 }) do
					local h = (fi == 1 and H1 or H2) - 0.4
					dress("x", Z1, 1, f, h, X1, X2, fi == 1 and { { -50, -43 } } or nil) -- south (the gate)
					dress("x", DIV, -1, f, h, X1, X2, fi == 1 and { { -34, -28 }, { -22, -17 }, { -16, 16 }, { 17, 22 }, { 30, 36 } } or { { -34, -28 }, { -22, -17 }, { -16, 16 }, { 16.5, 22.5 } })
					dress("x", DIV + 1, 1, f, h, X1, -16, { { -34, -28 }, { -22, -17 } })
					dress("x", DIV + 1, 1, f, h, 16, X2, fi == 1 and { { 17, 22 }, { 30, 36 } } or { { 16.5, 22.5 } })
					dress("x", Z2, -1, f, h, X1, -16, fi == 1 and { { -22, -16 } } or nil) -- north (the portcullis)
					dress("x", Z2, -1, f, h, 16, X2, nil)
				end

				-- light, all through
				for _, t in ipairs({
					{ -46, F1, Z1, 1 }, { -30, F1, DIV, -1 }, { -12, F1, Z1, 1 }, { 12, F1, Z1, 1 }, { 41, F1, Z1, 1 }, { 27, F1, DIV, -1 },
					{ -46, F1, Z2, -1 }, { -34, F1, Z2, -1 }, { -46, F1, DIV + 1, 1 }, { 22, F1, Z2, -1 }, { 38, F1, Z2, -1 }, { 26, F1, DIV + 1, 1 }, { 40, F1, DIV + 1, 1 },
					{ -46, F2, Z1, 1 }, { -30, F2, DIV, -1 }, { -12, F2, Z1, 1 }, { 12, F2, Z1, 1 }, { 41, F2, Z1, 1 }, { 27, F2, DIV, -1 },
					{ -46, F2, Z2, -1 }, { -24, F2, Z2, -1 }, { 22, F2, Z2, -1 }, { 38, F2, Z2, -1 }, { 40, F2, DIV + 1, 1 },
				}) do
					torch(Vector3.new(t[1], t[2] + 6.5, t[3] + t[4] * 0.1), Vector3.new(0, 0, t[4]))
				end
				for _, c in ipairs({ { -40, F1, 257 }, { -28, F1, 257 }, { 30, F1, 257 }, { -38, F2, 222 }, { -36, F2, 257 }, { 30, F2, 257 }, { 34, F2, 222 } }) do
					Detail.chandelier(Vector3.new(c[1], c[2] + 7.5, c[3]), c[2] == F1 and F2 - 1.2 or KTOP - 1)
				end
				-- banners in the prison's colours
				for _, b in ipairs({
					{ -36, Z1, 1, F1 }, { -16, Z1, 1, F1 }, { 16, Z1, 1, F1 }, { 32, Z1, 1, F1 },
					{ -46, Z2, -1, F1 }, { -36, Z2, -1, F1 }, { -28, Z2, -1, F1 },
					{ -36, Z1, 1, F2 }, { -16, Z1, 1, F2 }, { 16, Z1, 1, F2 }, { 32, Z1, 1, F2 },
					{ -32, Z2, -1, F2 }, { 30, Z2, -1, F2 },
				}) do
					Detail.banner(Detail.face(b[1], b[2], 0, b[3], b[4]), 0, (b[4] == F1 and H1 or H2) - 1.5, 7, 2.8, keepRng:NextNumber() < 0.6 and red or navy)
				end
				-- a pew (plain: these were kept) - faces -Z of its frame
				local function pew(cf, len)
					prop("PewSeat", Vector3.new(len, 0.3, 1.5), cf * CFrame.new(0, 1.5, 0), woodDark, MAT.WoodPlanks)
					prop("PewBack", Vector3.new(len, 1.6, 0.25), cf * CFrame.new(0, 2.5, 0.7) * CFrame.Angles(-0.1, 0, 0), woodDark, MAT.WoodPlanks)
					for _, x in ipairs({ -len / 2 + 0.3, len / 2 - 0.3 }) do
						prop("PewEnd", Vector3.new(0.3, 1.5, 1.5), cf * CFrame.new(x, 0.75, 0), woodDark, MAT.Wood)
					end
				end
				local function tableAt(cx, cz, w, l, f) -- a trestle table, l along z
					prop("Table", Vector3.new(w, 0.4, l), CFrame.new(cx, f + 3, cz), woodLight, MAT.WoodPlanks)
					for _, dz in ipairs({ -l / 2 + 0.8, l / 2 - 0.8 }) do
						prop("Trestle", Vector3.new(w - 0.4, 2.8, 0.4), CFrame.new(cx, f + 1.4, cz + dz), woodDark)
					end
				end
				local function hearth(z, f) -- a fireplace in the west wall
					blk(-52, f, z - 5, -49.4, f + 0.2, z + 5, "HearthStone", pale, MAT.Slate)
					blk(-52, f, z - 5, -50, f + 5, z - 3, "Hearth", COL.Wall)
					blk(-52, f, z + 3, -50, f + 5, z + 5, "Hearth", COL.Wall)
					blk(-52, f, z - 3, -51.6, f + 4.5, z + 3, "Firebox", VOIDC, MAT.Slate)
					blk(-52.2, f + 5, z - 5.5, -49.6, f + 5.8, z + 5.5, "Mantel", pale, MAT.Slate)
					blk(-52, f + 5.8, z - 4, -50.8, (f == F1 and F2 - 1.2 or KTOP - 1), z + 4, "Chimney", COL.Wall)
					for k = -1, 1 do
						prop("Log", Vector3.new(0.5, 0.5, 2.6), CFrame.new(-51, f + 0.5, z + k * 0.5) * CFrame.Angles(0, 0.3 * k, 0), Color3.fromRGB(50, 34, 24), MAT.Wood, false)
					end
					fire(Vector3.new(-51, f + 0.9, z), 4, 24)
				end

				-- FLOOR 1 ---------------------------------------------------------
				-- 1) CHECKPOINT (x -52..-24, south): up the stair from the gate; an iron grille
				-- across the room, its gate swung open; the guard's desk; the waiting bench
				for z = Z1 + 0.4, DIV - 0.4, 0.8 do
					if z < 220 or z > 226 then
						prop("GrilleBar", Vector3.new(0.16, 9, 0.16), CFrame.new(-38, F1 + 4.5, z), iron, MAT.Metal)
					end
				end
				for _, r in ipairs({ { Z1, 220 }, { 226, DIV } }) do -- (the bottom rail stops at the gate)
					prop("GrilleRail", Vector3.new(0.2, 0.3, r[2] - r[1]), CFrame.new(-38, F1 + 1, (r[1] + r[2]) / 2), iron, MAT.Metal)
				end
				prop("GrilleRail", Vector3.new(0.2, 0.3, DIV - Z1), CFrame.new(-38, F1 + 8.6, (Z1 + DIV) / 2), iron, MAT.Metal)
				prop("GrilleGate", Vector3.new(0.12, 8, 6), CFrame.new(-38, F1 + 4.1, 220) * CFrame.Angles(0, -1.3, 0) * CFrame.new(0, 0, 3), iron, MAT.Metal, false).Transparency = 0.55
				prop("GuardDesk", Vector3.new(7, 0.4, 2.8), CFrame.new(-31, F1 + 3, 209), woodLight, MAT.WoodPlanks)
				for _, sx in ipairs({ -1, 1 }) do
					prop("DeskSide", Vector3.new(0.3, 2.8, 2.6), CFrame.new(-31 + sx * 3.3, F1 + 1.4, 209), woodDark)
				end
				prop("Ledger", Vector3.new(1.5, 0.15, 1.1), CFrame.new(-32, F1 + 3.27, 209) * CFrame.Angles(0, 0.2, 0), Color3.fromRGB(110, 40, 30), MAT.Fabric, false)
				prop("Inkpot", Vector3.new(0.3, 0.35, 0.3), CFrame.new(-29.7, F1 + 3.38, 208.6), Color3.fromRGB(20, 20, 24), MAT.Glass, false)
				Detail.stool(Vector3.new(-31, F1, 211.4), false)
				prop("Bench", Vector3.new(1.4, 0.35, 8), CFrame.new(-50.6, F1 + 1.6, 228), woodLight, MAT.WoodPlanks)
				for _, dz in ipairs({ -3.4, 3.4 }) do
					prop("BenchLeg", Vector3.new(1.2, 1.5, 0.3), CFrame.new(-50.6, F1 + 0.75, 228 + dz), woodDark)
				end
				Detail.barrel(Vector3.new(-26.5, F1, 238.5), false)
				Detail.barrel(Vector3.new(-28.2, F1, 239.4), false)

				-- 2) STAIR HALL (x -23..23, south, open to the well): the grand spiral - broad
				-- stone steps with a red runner round a thick newel, an iron balustrade and rail,
				-- climbing through floor 2 and on up to the turret on the roof
				do
					local N1, N2 = 24, 28 -- steps to floor 2, then on to the roof
					local N = N1 + N2
					local STEP = math.rad(18.75)
					local RISE = (F2 - F1) / N1
					local R0, R1 = 1.8, 8.2 -- inner / outer radius
					local capY = KTOP + 9
					info.KeepStair = CFrame.lookAt(Vector3.new(SX - 10, F1 + 3, SZ - 4), Vector3.new(SX, F1 + 3, SZ)) -- (the dev menu's teleport: by its foot)
					cyl("Newel", capY - F1, R0 * 2, CFrame.new(SX, (F1 + capY) / 2, SZ) * CFrame.Angles(0, 0, math.pi / 2), COL.Wall, MAT.Cobblestone, true)
					cyl("NewelBase", 1, R0 * 2 + 1, CFrame.new(SX, F1 + 0.5, SZ) * CFrame.Angles(0, 0, math.pi / 2), COL.Wall, MAT.Slate, true)
					cyl("NewelBand", 0.6, R0 * 2 + 0.6, CFrame.new(SX, F2 + 1.2, SZ) * CFrame.Angles(0, 0, math.pi / 2), gold, MAT.Metal, true)
					local mid, len = (R0 + R1) / 2, R1 - R0 + 0.3
					-- at floor 2 the stair pauses: a flat landing three steps' worth of turn long,
					-- open to the floor on the north, before the upper flight climbs on from its end
					local LAND = 3
					for k = 1, LAND do
						local cf = CFrame.new(SX, F2, SZ) * CFrame.Angles(0, math.pi + (N1 - 1 + k) * STEP, 0)
						part({ Name = "SpiralLanding", Size = Vector3.new(len, 0.7, 3), CFrame = cf * CFrame.new(mid, -0.35, 0), Material = MAT.Slate, Color = stairStone })
						part({ Name = "StepRunner", Size = Vector3.new(len - 2.4, 0.06, 1.7), CFrame = cf * CFrame.new(mid + 0.3, 0.03, 0), Material = MAT.Fabric, Color = red, CanCollide = false })
					end
					local prevTop
					for i = 1, N do
						local th = math.pi + (i - 1 + (i > N1 and LAND or 0)) * STEP
						local top = F1 + i * RISE
						local cf = CFrame.new(SX, top, SZ) * CFrame.Angles(0, th, 0)
						part({ Name = "SpiralStep", Size = Vector3.new(len, 0.7, 2.9), CFrame = cf * CFrame.new(mid, -0.35, 0), Material = MAT.Slate, Color = (i % 2 == 0) and stairStone or Color3.fromRGB(66, 62, 58) })
						part({ Name = "StepRunner", Size = Vector3.new(len - 2.4, 0.06, 1.6), CFrame = cf * CFrame.new(mid + 0.3, 0.03, 0), Material = MAT.Fabric, Color = red, CanCollide = false })
						part({ Name = "StepNosing", Size = Vector3.new(len, 0.16, 0.22), CFrame = cf * CFrame.new(mid, -0.08, -1.4), Material = MAT.Slate, Color = pale, CanCollide = false })
						part({ Name = "Baluster", Size = Vector3.new(0.22, 3.2, 0.22), CFrame = cf * CFrame.new(R1 - 0.25, 1.6, 0), Material = MAT.Metal, Color = iron, CanCollide = false })
						-- an invisible guard on the outer edge (not where you step off at each floor)
						if not (i >= N1 - 2 and i <= N1 + 1) and i < N - 1 then
							part({ Name = "RampartEdge", Size = Vector3.new(0.3, 5, 3.1), CFrame = cf * CFrame.new(R1 + 0.1, 2.5, 0), Transparency = 1, CanQuery = false })
						end
						local railTop = (cf * CFrame.new(R1 - 0.25, 3.2, 0)).Position
						if prevTop then
							bar(prevTop, railTop, 0.22)
						end
						prevTop = railTop
						if i == N1 then
							prevTop = nil -- (no rail across the landing)
						end
					end
					-- rails round the well upstairs, open along the north where the landing meets the floor
					for _, r in ipairs({ { -9, 213, 9, 213.4 }, { -9, 213, -8.6, 229 }, { 8.6, 213, 9, 229 } }) do
						blk(r[1], F2, r[2], r[3], F2 + 3.2, r[4], "StairRail", iron, MAT.Metal)
					end
				end
				blk(-23, F1 + 0.12, 220, -12, F1 + 0.18, 226, "Runner", red, MAT.Fabric)

				-- 3) ARMORY (x 24..44, south): racks of pikes, armour on stands, a table, kegs
				for i = 0, 6 do
					local rz = 208 + i * 5
					prop("RackBack", Vector3.new(0.3, 5, 4), CFrame.new(43.6, F1 + 2.6, rz), woodDark)
					for k = -1, 1 do
						prop("Pike", Vector3.new(0.14, 8.5, 0.14), CFrame.new(43.1, F1 + 4.25, rz + k * 1.2) * CFrame.Angles(0, 0, keepRng:NextNumber(-0.06, 0.06)), woodLight, MAT.Wood, false)
						prop("PikeHead", Vector3.new(0.3, 0.9, 0.1), CFrame.new(43.1, F1 + 8.9, rz + k * 1.2), iron, MAT.Metal, false)
					end
				end
				for _, x in ipairs({ 28, 33, 38 }) do
					prop("StandPost", Vector3.new(0.3, 4.6, 0.3), CFrame.new(x, F1 + 2.3, 206.5), woodDark)
					prop("StandArm", Vector3.new(2.4, 0.25, 0.25), CFrame.new(x, F1 + 4, 206.5), woodDark)
					prop("Breastplate", Vector3.new(1.9, 2.1, 0.9), CFrame.new(x, F1 + 3.3, 206.8), Color3.fromRGB(100, 98, 94), MAT.Metal)
					prop("Helm", Vector3.new(1.0, 1.1, 1.0), CFrame.new(x, F1 + 5, 206.5), Color3.fromRGB(88, 86, 82), MAT.Metal).Shape = Enum.PartType.Ball
				end
				tableAt(33, 223, 3, 8, F1)
				prop("Sword", Vector3.new(0.25, 0.08, 3.2), CFrame.new(32.6, F1 + 3.25, 222) * CFrame.Angles(0, 0.1, 0), iron, MAT.Metal, false)
				cyl("Shield", 0.25, 2.2, CFrame.new(33.4, F1 + 3.3, 225) * CFrame.Angles(0, 0, 1.3), red, MAT.Wood)
				do -- a spare flask, left on the armory table (init.server: one more draught)
					local fx, fz, top = 33.6, 220, F1 + 3.2
					local up = CFrame.Angles(0, 0, math.pi / 2) -- (cylinders run along X)
					local parts = {
						cyl("FlaskBody", 0.9, 0.8, CFrame.new(fx, top + 0.45, fz) * up, Color3.fromRGB(255, 150, 60), MAT.Glass),
						cyl("FlaskNeck", 0.4, 0.3, CFrame.new(fx, top + 1.1, fz) * up, Color3.fromRGB(255, 170, 90), MAT.Glass),
						cyl("FlaskCork", 0.2, 0.32, CFrame.new(fx, top + 1.4, fz) * up, woodLight, MAT.Wood),
					}
					local glow = part({ Name = "PickupGlow", Size = Vector3.new(0.4, 0.4, 0.4), CFrame = CFrame.new(fx, top + 0.8, fz), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
					table.insert(parts, glow)
					info.Pickups = info.Pickups or {}
					info.Pickups.Flask = { Prompt = prompt(glow, "Take", "Spare Flask", 0.3, 7), Parts = parts, Glow = glow }
				end
				for _, p in ipairs({ { 26, 214 }, { 27.6, 215.6 }, { 26, 217.4 } }) do
					Detail.barrel(Vector3.new(p[1], F1, p[2]), false)
				end

				-- 4) GREAT HALL (x -52..-16, north): a roaring hearth, long tables, the portcullis
				-- out to the roof with its chain, barred windows onto the well
				hearth(257, F1)
				for _, x in ipairs({ -42, -30 }) do
					tableAt(x, 257, 2.6, 16, F1)
					for _, sx in ipairs({ -1, 1 }) do
						prop("Bench", Vector3.new(1, 0.35, 14), CFrame.new(x + sx * 2.3, F1 + 1.6, 257), woodLight, MAT.WoodPlanks)
						for _, dz in ipairs({ -6, 6 }) do
							prop("BenchLeg", Vector3.new(0.8, 1.5, 0.3), CFrame.new(x + sx * 2.3, F1 + 0.75, 257 + dz), woodDark)
						end
					end
					for k = -2, 2 do
						prop(k % 2 == 0 and "Tankard" or "Plate", k % 2 == 0 and Vector3.new(0.4, 0.55, 0.4) or Vector3.new(0.8, 0.08, 0.8), CFrame.new(x + keepRng:NextNumber(-0.6, 0.6), F1 + 3.3, 257 + k * 3), Color3.fromRGB(110, 106, 98), MAT.Metal, false)
					end
				end
				do
					local gate = Instance.new("Model")
					gate.Name = "KeepGate"
					gate.Parent = map
					local collider = part({ Name = "GateCollider", Size = Vector3.new(6, 8, 2.4), CFrame = CFrame.new(-19, F1 + 4, 273.5), Transparency = 1, Parent = gate }) -- (deep: thin, a fast enough body goes through it)
					for x = -21.6, -16.4, 0.8 do
						part({ Name = "GateBar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(8, 0.36, 0.36), CFrame = CFrame.new(x, F1 + 4, 273.5) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Metal, Color = iron, CanCollide = false, Parent = gate })
					end
					for _, y in ipairs({ 0.6, 4, 7.4 }) do
						part({ Name = "GateRail", Size = Vector3.new(6, 0.4, 0.45), CFrame = CFrame.new(-19, F1 + y, 273.5), Material = MAT.Metal, Color = COL.Rust, CanCollide = false, Parent = gate })
					end
					gate.PrimaryPart = collider
					info.KeepGate = gate
					cyl("Pulley", 0.6, 1.4, CFrame.new(-24.5, F2 - 2.2, 271.2) * CFrame.Angles(0, math.pi / 2, 0), iron, MAT.Metal)
					for y = F1 + 4.6, F2 - 2.8, 0.55 do
						prop("Chain", Vector3.new(0.18, 0.5, 0.18), CFrame.new(-24.5, y, 271.2) * CFrame.Angles(0, (y * 2) % 2 < 1 and 0 or math.pi / 2, 0), iron, MAT.Metal, false)
					end
					local ring = cyl("ChainRing", 0.2, 1.2, CFrame.new(-24.5, F1 + 4, 271.2) * CFrame.Angles(0, math.pi / 2, 0), iron, MAT.Metal)
					info.KeepChain = ring
					info.KeepChainPrompt = prompt(ring, "Pull chain", "Gate Chain", 0.4, 7)
					local outside = part({ Name = "KeepGateOutside", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(-19, F1 + 3, 276), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
					info.KeepGateLocked = prompt(outside, "Open", "Portcullis", 0, 7)
				end

				-- 5) CHAPEL (x 16..44, north): an altar under a lit window, candles, rows of pews
				blk(39, F1, 250, 44, F1 + 0.8, 264, "AltarDais", pale, MAT.Slate)
				blk(40.5, F1 + 0.8, 254.5, 43, F1 + 3.6, 259.5, "Altar", Color3.fromRGB(150, 144, 132), MAT.Marble)
				blk(40.3, F1 + 3.6, 254, 43.2, F1 + 3.75, 260, "AltarCloth", red, MAT.Fabric)
				blk(40.25, F1 + 1.6, 254, 40.4, F1 + 3.75, 260, "AltarCloth", red, MAT.Fabric)
				Detail.window(Detail.face(44, 257, -1, 0, F1), 0, 4.5, 3.2, 5.5, true)
				Detail.window(Detail.face(30, Z2, 0, -1, F1), 0, 3.5, 3, 5, true)
				for _, z in ipairs({ 255, 257, 259 }) do
					prop("Candle", Vector3.new(0.25, 0.8, 0.25), CFrame.new(42.2, F1 + 4.15, z), Color3.fromRGB(220, 210, 180), MAT.SmoothPlastic, false)
					local fl = prop("CandleFlame", Vector3.new(0.14, 0.3, 0.14), CFrame.new(42.2, F1 + 4.7, z), Color3.fromRGB(255, 190, 90), MAT.Neon, false)
					if z == 257 then
						local cl = Instance.new("PointLight")
						cl.Color, cl.Range, cl.Brightness = Color3.fromRGB(255, 180, 100), 14, 1.6
						cl.Parent = fl
						addFlicker(cl)
					end
				end
				for _, z in ipairs({ 251.5, 262.5 }) do -- tall iron candle-stands either side
					prop("CandleStand", Vector3.new(0.3, 5, 0.3), CFrame.new(39.5, F1 + 2.5, z), iron, MAT.Metal)
					fire(Vector3.new(39.5, F1 + 5.3, z), 1, 12)
				end
				for row = 0, 3 do
					for _, z in ipairs({ 251.5, 262.5 }) do
						pew(CFrame.new(22 + row * 4, F1, z) * CFrame.Angles(0, -math.pi / 2, 0), 7)
					end
				end

				-- FLOOR 2 ---------------------------------------------------------
				-- 6) RECORDS (x -52..-24, south): the clerk's desk, shelves of rolls, the last entry
				tableAt(-38, 209, 3, 7, F2)
				Detail.stool(Vector3.new(-35.2, F2, 209), true)
				prop("Candle", Vector3.new(0.25, 0.7, 0.25), CFrame.new(-38.6, F2 + 3.55, 211.6), Color3.fromRGB(220, 210, 180), MAT.SmoothPlastic, false)
				local flame = prop("CandleFlame", Vector3.new(0.14, 0.3, 0.14), CFrame.new(-38.6, F2 + 4.05, 211.6), Color3.fromRGB(255, 190, 90), MAT.Neon, false)
				local cl = Instance.new("PointLight")
				cl.Color, cl.Range, cl.Brightness = Color3.fromRGB(255, 180, 100), 10, 1.4
				cl.Parent = flame
				addFlicker(cl)
				local page = prop("CastellanRoll", Vector3.new(1.2, 0.06, 1.6), CFrame.new(-38, F2 + 3.23, 208.5) * CFrame.Angles(0, -0.15, 0), Color3.fromRGB(214, 200, 166), MAT.Fabric, false)
				local pp = prompt(page, "Examine", "Roll of the Keep", 0, 7)
				pp:SetAttribute("Title", "Roll of the Keep - last entry")
				pp:SetAttribute("Text", table.concat({
					"The bell went unanswered again tonight. I rang the muster three times and called the roll into an empty yard.",
					"",
					"The turnkeys are gone. The jailers are gone. The Warden keeps his hall below, but he no longer knows us, and he no longer sleeps.",
					"",
					"Of all the souls this old prison ever held, warden and prisoner alike, one alone still lives as a man should: the noble Castellan. He has gone up onto the battlements to keep the watch for the rest of us, as he swore he would, and bid me lock the stair door behind him.",
					"",
					"The key is in the strongroom, where it belongs. There is no one left to use it but him, and he will not come down.",
					"",
					"If you are not he: do not climb.",
				}, "\n"))
				table.insert(notes, pp)
				for i = 0, 4 do
					local sx, sz = -51.4, 214 + i * 5
					prop("Shelf", Vector3.new(1.2, 8, 4.4), CFrame.new(sx + 0.3, F2 + 4, sz), woodDark, MAT.WoodPlanks)
					for _, y in ipairs({ 1.2, 3.2, 5.2, 7.2 }) do
						prop("ShelfBoard", Vector3.new(1.3, 0.15, 4.4), CFrame.new(sx + 0.9, F2 + y, sz), woodLight, MAT.WoodPlanks)
						for k = 0, 3 do
							cyl("Scroll", 1, 0.35, CFrame.new(sx + 0.9, F2 + y + 0.25, sz - 1.5 + k * 1.0 + keepRng:NextNumber(-0.1, 0.1)) * CFrame.Angles(0, keepRng:NextNumber(-0.3, 0.3), 0), Color3.fromRGB(196, 180, 140):Lerp(Color3.fromRGB(140, 120, 90), keepRng:NextNumber()), MAT.Fabric)
						end
					end
				end
				Detail.window(Detail.face(-44, Z1, 0, 1, F2), 0, 3, 2.6, 5, false)

				-- 7) the LANDING (x -23..23, south, over the well's gallery): the stair goes on up
				-- 8) BARRACKS (x 24..44, south): two rows of bunks, footlockers, the mess table
				for _, row in ipairs({ { 236, 231.5 }, { 209, 213.5 } }) do
					for i = 0, 3 do
						local bx = 27 + i * 5
						prop("BunkFrame", Vector3.new(2.6, 0.5, 6), CFrame.new(bx, F2 + 1.2, row[1]), woodDark, MAT.WoodPlanks)
						prop("Mattress", Vector3.new(2.2, 0.35, 5.4), CFrame.new(bx, F2 + 1.6, row[1]), COL.Straw, MAT.Fabric)
						if keepRng:NextNumber() < 0.6 then
							prop("Blanket", Vector3.new(2.3, 0.12, 2.6), CFrame.new(bx, F2 + 1.82, row[1] + (row[1] > 220 and -1.2 or 1.2)) * CFrame.Angles(0, keepRng:NextNumber(-0.15, 0.15), 0), Color3.fromRGB(70, 44, 40), MAT.Fabric, false)
						end
						for _, dz in ipairs({ -2.7, 2.7 }) do
							prop("BunkLeg", Vector3.new(0.3, 1.2, 0.3), CFrame.new(bx, F2 + 0.6, row[1] + dz), woodDark)
						end
						prop("Footlocker", Vector3.new(2, 1.2, 1.1), CFrame.new(bx, F2 + 0.6, row[2]), woodLight, MAT.WoodPlanks)
						prop("LockerBand", Vector3.new(2.05, 0.2, 1.15), CFrame.new(bx, F2 + 0.9, row[2]), iron, MAT.Metal, false)
					end
				end
				tableAt(34, 222.5, 3, 8, F2)
				prop("Tankard", Vector3.new(0.4, 0.55, 0.4), CFrame.new(34, F2 + 3.48, 221), Color3.fromRGB(90, 88, 84), MAT.Metal, false)

				-- 9) THE CASTELLAN'S QUARTERS (x -52..-16, north): his hearth, his bed, his desk -
				-- and his spare helm on its stand (a pickup)
				hearth(257, F2)
				blk(-46, F2 + 0.12, 246, -28, F2 + 0.18, 268, "Rug", red, MAT.Fabric)
				blk(-46.4, F2 + 0.12, 245.6, -27.6, F2 + 0.16, 268.4, "RugHem", gold, MAT.Fabric)
				do -- a canopy bed against the north wall
					local bx, bz = -38, 266
					prop("BedFrame", Vector3.new(5, 1, 7.4), CFrame.new(bx, F2 + 0.8, bz), woodDark, MAT.WoodPlanks)
					prop("Mattress", Vector3.new(4.6, 0.6, 7), CFrame.new(bx, F2 + 1.6, bz), red, MAT.Fabric)
					prop("Pillow", Vector3.new(3.6, 0.5, 1.2), CFrame.new(bx, F2 + 2.1, bz + 2.8), Color3.fromRGB(214, 200, 166), MAT.Fabric)
					for _, sx in ipairs({ -2.3, 2.3 }) do
						for _, sz in ipairs({ -3.5, 3.5 }) do
							prop("BedPost", Vector3.new(0.4, 8, 0.4), CFrame.new(bx + sx, F2 + 4, bz + sz), woodDark)
						end
					end
					prop("Canopy", Vector3.new(5.2, 0.3, 7.6), CFrame.new(bx, F2 + 8, bz), red, MAT.Fabric)
					for _, sx in ipairs({ -2.5, 2.5 }) do
						prop("Drape", Vector3.new(0.12, 6, 1.2), CFrame.new(bx + sx, F2 + 5, bz - 3.3), red, MAT.Fabric, false)
					end
					keepChest("BedChest", Vector3.new(4, 1.6, 1.6), CFrame.new(bx, F2, bz - 4.8)) -- (empty now: the Old Book is the hag's gift, Characters/Hag)
				end
				prop("Wardrobe", Vector3.new(4.5, 8, 2), CFrame.new(-28, F2 + 4, 270.8), woodDark, MAT.WoodPlanks)
				prop("WardrobeSeam", Vector3.new(0.1, 7.6, 0.1), CFrame.new(-28, F2 + 4, 269.75), woodLight, MAT.Wood, false)
				tableAt(-24, 249, 3, 5, F2)
				prop("Inkpot", Vector3.new(0.3, 0.35, 0.3), CFrame.new(-23.6, F2 + 3.38, 248.4), Color3.fromRGB(20, 20, 24), MAT.Glass, false)
				do -- the helm on its stand, by the well windows
					local hx, hz = -21, 258
					blk(hx - 1.2, F2, hz - 1.2, hx + 1.2, F2 + 1.2, hz + 1.2, "HelmPlinth", pale, MAT.Marble)
					prop("HelmPost", Vector3.new(0.4, 3.4, 0.4), CFrame.new(hx, F2 + 2.9, hz), woodDark)
					prop("HelmShoulders", Vector3.new(0.6, 0.5, 2.6), CFrame.new(hx, F2 + 4.4, hz), woodDark)
					local helm = MapBuilder.helm(CFrame.new(hx, F2 + 5.3, hz) * CFrame.Angles(0, math.pi / 2, 0))
					helm.Name = "CastellanHelmDisplay"
					helm.Parent = map
					local parts = helm:GetChildren()
					info.Pickups = info.Pickups or {}
					local glow = part({ Name = "PickupGlow", Size = Vector3.new(0.4, 0.4, 0.4), CFrame = CFrame.new(hx, F2 + 5.3, hz), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
					table.insert(parts, glow)
					info.Pickups.Helmet = { Prompt = prompt(glow, "Take", "Castellan's Helm", 0.3, 7), Parts = parts, Glow = glow }
				end

				-- 10) THE STRONGROOM (x 16..44, north): behind the barred great door - coffers,
				-- a rack of fine blades, and the key to the battlements on its cushion (a pickup)
				Detail.archRib(Detail.face(19.5, DIV, 0, -1, F2), 0, 10, 3.2, 1.6, 0.9, 1.0, 0.45, 7, MAT.Cobblestone, COL.Wall, false)
				do
					local leaves, hinges = {}, {}
					for k, x0 in ipairs({ 16.5, 22.5 }) do
						local s = k == 1 and 1 or -1 -- each leaf runs from its hinge toward the middle
						local leaf = Instance.new("Model")
						leaf.Name = "GreatDoorLeaf"
						leaf.Parent = map
						local main = part({ Name = "GreatDoor", Size = Vector3.new(3, 10, 0.5), CFrame = CFrame.new(x0 + s * 1.5, F2 + 5, DIV + 0.5), Material = MAT.WoodPlanks, Color = woodDark, Parent = leaf })
						for _, y in ipairs({ -3.5, 0, 3.5 }) do
							part({ Name = "DoorBand", Size = Vector3.new(3, 0.4, 0.62), CFrame = main.CFrame * CFrame.new(0, y, 0), Material = MAT.Metal, Color = iron, CanCollide = false, Parent = leaf })
						end
						part({ Name = "DoorRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, 0.9, 0.9), CFrame = main.CFrame * CFrame.new(-s * 1, -0.4, -0.34) * CFrame.Angles(0, math.pi / 2, 0), Material = MAT.Metal, Color = iron, CanCollide = false, Parent = leaf })
						leaf.PrimaryPart = main
						leaves[k] = leaf
						hinges[k] = Vector3.new(x0, F2 + 5, DIV + 0.5)
					end
					local barPart = prop("DoorBar", Vector3.new(0.5, 0.5, 6.6), CFrame.new(19.5, F2 + 4.6, DIV - 0.25) * CFrame.Angles(0, -math.pi / 2, 0), Color3.fromRGB(70, 50, 36), MAT.Wood)
					for _, x in ipairs({ 16.1, 22.9 }) do
						prop("BarBracket", Vector3.new(0.4, 0.9, 0.6), CFrame.new(x, F2 + 4.6, DIV - 0.25), iron, MAT.Metal)
					end
					local spot = part({ Name = "GreatDoorPrompt", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(19.5, F2 + 3, DIV - 1.2), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
					-- (leaf 1 swings with -90 degrees, leaf 2 with +90: both into the strongroom)
					info.GreatDoor = { Leaves = leaves, Hinges = hinges, Signs = { -1, 1 }, Bar = barPart, Prompt = prompt(spot, "Open", "Great Door", 0.6, 8) }
				end
				-- iron-bound coffers, locked: all empty but one (the Gozen Tachi)
				for _, c in ipairs({ { 26, 270.5 }, { 31, 270.5 }, { 42.5, 252, "GozenTachi" }, { 42.5, 246.5 } }) do
					keepChest("Coffer", Vector3.new(3, 1.8, 1.8), CFrame.new(c[1], F2, c[2]) * CFrame.Angles(0, c[1] > 40 and math.pi / 2 or 0, 0), c[3])
				end
				for _, c in ipairs({ { 21, 268.5 }, { 22.4, 269.6 }, { 36, 270.4 } }) do -- spilled coin
					prop("Coins", Vector3.new(1.2, 0.25, 1), CFrame.new(c[1], F2 + 0.12, c[2]) * CFrame.Angles(0, keepRng:NextNumber(0, 3), 0), Color3.fromRGB(214, 172, 70), MAT.Metal, false)
				end
				prop("BladeRack", Vector3.new(0.3, 4, 8), CFrame.new(43.6, F2 + 3, 264), woodDark)
				for k = -3, 3 do
					prop("Blade", Vector3.new(0.1, 4.4, 0.3), CFrame.new(43.3, F2 + 3.2, 264 + k * 1.1), Color3.fromRGB(176, 176, 182), MAT.Metal, false)
				end
				do -- the key on its cushion
					local kx, kz = 32, 257
					blk(kx - 1, F2, kz - 1, kx + 1, F2 + 3, kz + 1, "KeyPlinth", Color3.fromRGB(150, 144, 132), MAT.Marble)
					blk(kx - 1.2, F2 + 3, kz - 1.2, kx + 1.2, F2 + 3.2, kz + 1.2, "KeyPlinthCap", gold, MAT.Metal)
					local parts = {}
					table.insert(parts, prop("Cushion", Vector3.new(1.8, 0.35, 1.8), CFrame.new(kx, F2 + 3.38, kz), red, MAT.Fabric, false))
					table.insert(parts, prop("KeyShaft", Vector3.new(0.2, 0.2, 2), CFrame.new(kx, F2 + 3.7, kz + 0.2), iron, MAT.Metal, false))
					table.insert(parts, cyl("KeyBow", 0.18, 0.9, CFrame.new(kx, F2 + 3.7, kz - 1.1) * CFrame.Angles(0, 0, math.pi / 2), gold, MAT.Metal))
					table.insert(parts, prop("KeyBit", Vector3.new(0.15, 0.2, 0.55), CFrame.new(kx, F2 + 3.7, kz + 1.25) * CFrame.new(0.25, 0, 0) * CFrame.Angles(0, math.pi / 2, 0), iron, MAT.Metal, false))
					table.insert(parts, prop("KeyBit", Vector3.new(0.15, 0.2, 0.4), CFrame.new(kx, F2 + 3.7, kz + 0.85) * CFrame.new(0.2, 0, 0) * CFrame.Angles(0, math.pi / 2, 0), iron, MAT.Metal, false))
					local glow = part({ Name = "PickupGlow", Size = Vector3.new(0.4, 0.4, 0.4), CFrame = CFrame.new(kx, F2 + 3.8, kz), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
					table.insert(parts, glow)
					info.Pickups = info.Pickups or {}
					info.Pickups.KeepKey = { Prompt = prompt(glow, "Take", "Key to the Battlements", 0.3, 7), Parts = parts, Glow = glow }
				end
				do -- the chest key, on the dais at the throne's right hand (the battlements)
					local kx, kz, ky = -50.5, 243, KTOP + 1.5
					local parts = {}
					table.insert(parts, prop("ChestKeyShaft", Vector3.new(1.4, 0.15, 0.15), CFrame.new(kx, ky + 0.08, kz) * CFrame.Angles(0, 0.4, 0), iron, MAT.Metal, false))
					table.insert(parts, cyl("ChestKeyBow", 0.12, 0.6, CFrame.new(kx, ky + 0.08, kz) * CFrame.Angles(0, 0.4, 0) * CFrame.new(-0.95, 0, 0) * CFrame.Angles(0, 0, math.pi / 2), gold, MAT.Metal))
					table.insert(parts, prop("ChestKeyBit", Vector3.new(0.12, 0.15, 0.35), CFrame.new(kx, ky + 0.08, kz) * CFrame.Angles(0, 0.4, 0) * CFrame.new(0.6, 0, 0.2), iron, MAT.Metal, false))
					local glow = part({ Name = "PickupGlow", Size = Vector3.new(0.4, 0.4, 0.4), CFrame = CFrame.new(kx, ky + 0.4, kz), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
					table.insert(parts, glow)
					info.Pickups.ChestKey = { Prompt = prompt(glow, "Take", "Castellan's Chest Key", 0.3, 7), Parts = parts, Glow = glow }
				end
				-- pickups glimmer
				for _, pk in pairs(info.Pickups) do
					local l = Instance.new("PointLight")
					l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 220, 150), 9, 1.2
					l.Parent = pk.Glow
					local pe = Instance.new("ParticleEmitter")
					pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
					pe.Rate = 6
					pe.Lifetime = NumberRange.new(0.8, 1.4)
					pe.Speed = NumberRange.new(0.3, 0.8)
					pe.SpreadAngle = Vector2.new(180, 180)
					pe.Size = NumberSequence.new(0.18, 0)
					pe.Color = ColorSequence.new(Color3.fromRGB(255, 230, 170))
					pe.LightEmission = 1
					pe.Parent = pk.Glow
				end

				-- THE ROOF: THE BATTLEMENTS (the Castellan's arena) --------------------
				-- the stair comes up inside a turret; its door opens with the strongroom's key
				do
					local T1, T2 = KTOP, KTOP + 9
					-- (roomy inside: 7 studs of floor round the stair's hole, 5 on the south)
					blk(-17, T1, 207, 17, T2, 208, "Turret") -- south
					blk(-17, T1, 208, -16, T2, 238, "Turret") -- west
					blk(16, T1, 208, 17, T2, 238, "Turret") -- east
					blk(-17, T1, 238, -3, T2, 239, "Turret") -- north, west of the door
					blk(3, T1, 238, 17, T2, 239, "Turret") -- east of it
					blk(-3, T1 + 8, 238, 3, T2, 239, "Turret") -- over it
					blk(-17.4, T2, 206.6, 17.4, T2 + 1, 239.4, "TurretRoof", Color3.fromRGB(56, 54, 52), MAT.Slate)
					crenellate(-17, 207, 17, 207, T2 + 1)
					crenellate(-17, 239, 17, 239, T2 + 1)
					crenellate(-17, 207, -17, 239, T2 + 1)
					crenellate(17, 207, 17, 239, T2 + 1)
					-- rails round the stair's hole up here (not across the tongue it lands on, south-west)
					for _, r in ipairs({ { -1, 213, 9, 213.4 }, { -9, 217, -8.6, 231 }, { 8.6, 213, 9, 231 }, { -9, 230.6, 9, 231 } }) do
						blk(r[1], T1, r[2], r[3], T1 + 3.2, r[4], "StairRail", iron, MAT.Metal)
					end
					-- the door (init.server swings it out onto the battlements)
					local door = Instance.new("Model")
					door.Name = "BattlementDoor"
					door.Parent = map
					local main = part({ Name = "Door", Size = Vector3.new(6, 8, 0.5), CFrame = CFrame.new(0, T1 + 4, 238.5), Material = MAT.WoodPlanks, Color = woodDark, Parent = door })
					for _, y in ipairs({ -2.8, 0, 2.8 }) do
						part({ Name = "DoorBand", Size = Vector3.new(6, 0.4, 0.62), CFrame = main.CFrame * CFrame.new(0, y, 0), Material = MAT.Metal, Color = iron, CanCollide = false, Parent = door })
					end
					part({ Name = "LockPlate", Size = Vector3.new(0.9, 1.2, 0.7), CFrame = main.CFrame * CFrame.new(2.2, -0.3, 0), Material = MAT.Metal, Color = gold, CanCollide = false, Parent = door })
					door.PrimaryPart = main
					local spot = part({ Name = "BattlementDoorPrompt", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(0, T1 + 3, 237), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
					info.RoofDoor = { Leaf = door, Hinge = Vector3.new(-3, T1 + 4, 238.5), Sign = -1, Prompt = prompt(spot, "Open", "Battlement Door", 0.5, 7) }
					-- a great red flag over it all
					cyl("Flagpole", 16, 0.4, CFrame.new(0, T2 + 9, 222) * CFrame.Angles(0, 0, math.pi / 2), woodDark, MAT.Wood)
					prop("Flag", Vector3.new(0.12, 5, 8), CFrame.new(0, T2 + 14, 226.2), red, MAT.Fabric, false)
					prop("FlagHem", Vector3.new(0.14, 0.4, 8), CFrame.new(0, T2 + 11.3, 226.2), gold, MAT.Fabric, false)
				end
				-- the battlements' edge, all the way round (the keep, the bridge east, the east wing and
				-- its north arm): breast-high stone - above the eye, so nothing below the horizon shows
				-- past it - with merlons on top, and an invisible wall behind
				local PH = 4.6
				local function rampart(x1, z1, x2, z2)
					blk(x1, KTOP, z1, x2, KTOP + PH, z2, "Parapet")
					blk(x1 - 0.2, KTOP + PH - 0.3, z1 - 0.2, x2 + 0.2, KTOP + PH, z2 + 0.2, "ParapetCap", COL.Wall, MAT.Slate)
					invisible(blk(x1, KTOP, z1, x2, KTOP + 10, z2, "RampartEdge"))
					if x2 - x1 > z2 - z1 then
						crenellate(x1 + 1, (z1 + z2) / 2, x2 - 1, (z1 + z2) / 2, KTOP + PH)
					else
						crenellate((x1 + x2) / 2, z1 + 1, (x1 + x2) / 2, z2 - 1, KTOP + PH)
					end
				end
				for _, r in ipairs({
					{ -56, 201, 60, 202.4 }, { -56, 273.6, 46, 275 }, { -56, 202.4, -54.6, 273.6 }, { 44.6, 221, 46, 273.6 }, -- the keep (open east onto the bridge)
					{ 46, 219.6, 176, 221 }, { 60, 181, 61.4, 201 }, { 60, 181, 196, 182.4 }, -- the bridge and the east wing
					{ 194.6, 182.4, 196, 290 }, { 176, 288.6, 196, 290 }, { 176, 221, 177.4, 288.6 }, -- its north arm
				}) do
					rampart(r[1], r[2], r[3], r[4])
				end
				-- his throne on a dais at the west end, banners behind, fires either side
				blk(-54.6, KTOP, 229, -44, KTOP + 1.5, 247, "Dais", Color3.fromRGB(70, 66, 62), MAT.Slate)
				blk(-44, KTOP, 232, -42, KTOP + 0.75, 244, "DaisStep", Color3.fromRGB(70, 66, 62), MAT.Slate)
				blk(-44.2, KTOP + 1.5, 229, -43.8, KTOP + 1.56, 247, "DaisTrim", gold, MAT.Metal)
				blk(-52, KTOP + 1.5, 236, -48.6, KTOP + 3.2, 240, "ThroneSeat", Color3.fromRGB(46, 44, 42), MAT.Slate)
				blk(-48.8, KTOP + 3.1, 236.4, -48.4, KTOP + 3.3, 239.6, "ThroneTrim", gold, MAT.Metal)
				blk(-53.8, KTOP + 1.5, 235.4, -52, KTOP + 11, 240.6, "ThroneBack", Color3.fromRGB(40, 38, 36), MAT.Slate)
				for _, z in ipairs({ 235.6, 240.4 }) do
					blk(-52, KTOP + 3.2, z - 0.4, -48.6, KTOP + 4.6, z + 0.4, "ThroneArm", Color3.fromRGB(46, 44, 42), MAT.Slate)
				end
				for k = -2, 2 do
					prop("ThroneSpike", Vector3.new(0.5, 1.6 - math.abs(k) * 0.3, 0.5), CFrame.new(-52.9, KTOP + 11.7 - math.abs(k) * 0.15, 238 + k * 1.1), gold, MAT.Metal)
				end
				blk(-51.95, KTOP + 5, 236.6, -51.85, KTOP + 10, 239.4, "ThroneCloth", red, MAT.Fabric)
				for _, z in ipairs({ 231, 245 }) do
					cyl("BannerPole", 13, 0.35, CFrame.new(-53.5, KTOP + 6.5 + 1.5, z) * CFrame.Angles(0, 0, math.pi / 2), woodDark, MAT.Wood)
					prop("BannerArm", Vector3.new(0.25, 0.25, 3), CFrame.new(-53.3, KTOP + 13.6, z), iron, MAT.Metal, false)
					prop("Banner", Vector3.new(0.1, 8, 2.8), CFrame.new(-53.2, KTOP + 9.4, z), red, MAT.Fabric, false)
					prop("BannerEmblem", Vector3.new(0.12, 1.4, 1.4), CFrame.new(-53.15, KTOP + 10.6, z) * CFrame.Angles(math.pi / 4, 0, 0), gold, MAT.Fabric, false)
				end
				-- fog across the bridge east while he fights (Characters/Castellan raises and lifts it)
				local seal = part({ Name = "CastellanFog", Size = Vector3.new(0.6, 12, 18.6), CFrame = CFrame.new(45.3, KTOP + 6, 211.7), Material = MAT.ForceField, Color = COL.Fog, Transparency = 1, CanCollide = false, CanQuery = false })
				info.CastellanArena = {
					Spawn = CFrame.lookAt(Vector3.new(-46, KTOP + 1.5 + 3, 238), Vector3.new(0, KTOP + 4.5, 238)),
					Center = Vector3.new(-5, KTOP, 238),
					Seal = seal,
				}
				-- the sigil set in the floor before him
				do
					local cx, cz = -30, 238
					local function disc(r, color, mat, lift)
						part({ Name = "Sigil", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.04, r * 2, r * 2), CFrame = CFrame.new(cx, KTOP + lift, cz) * CFrame.Angles(0, 0, math.pi / 2), Material = mat, Color = color, CanCollide = false, CanQuery = false, CastShadow = false })
					end
					disc(10, gold, MAT.Metal, 0.01)
					disc(9.4, Color3.fromRGB(44, 42, 40), MAT.Slate, 0.02)
					disc(7, red, MAT.Fabric, 0.03)
					disc(6.4, Color3.fromRGB(44, 42, 40), MAT.Slate, 0.04)
					disc(2.2, gold, MAT.Metal, 0.05)
					for k = 0, 7 do
						local a = k / 8 * math.pi * 2
						part({ Name = "Sigil", Size = Vector3.new(7.2, 0.05, 0.25), CFrame = CFrame.new(cx, KTOP + 0.06, cz) * CFrame.Angles(0, a, 0) * CFrame.new(5.8, 0, 0), Material = MAT.Metal, Color = gold, CanCollide = false, CanQuery = false, CastShadow = false })
					end
				end
				-- great braziers at the corners and either side of the dais
				for _, p in ipairs({ { -48, 207 }, { -48, 269 }, { 39, 207 }, { 39, 269 }, { -45, 227 }, { -45, 249 } }) do
					local base = Vector3.new(p[1], KTOP, p[2])
					cyl("BrazierBase", 3, 2.2, CFrame.new(base + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(70, 66, 62), MAT.Slate, true)
					cyl("BrazierBowl", 1.2, 4, CFrame.new(base + Vector3.new(0, 3.6, 0)) * CFrame.Angles(0, 0, math.pi / 2), iron, MAT.Metal, true)
					cyl("BrazierCoals", 0.2, 3.4, CFrame.new(base + Vector3.new(0, 4.2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(255, 110, 40), MAT.Neon)
					fire(base + Vector3.new(0, 4.6, 0), 8, 34)
				end
				-- colossal stone knights, greatswords point-down, watching the floor
				local function statue(pos, look)
					local cf = CFrame.lookAt(pos, pos + look)
					local stone, dk = Color3.fromRGB(112, 108, 100), Color3.fromRGB(86, 82, 76)
					local function s(name, size, rel, color, shape)
						local p = prop(name, size, cf * rel, color or stone, MAT.Slate)
						if shape then
							p.Shape = shape
						end
					end
					s("StatuePlinth", Vector3.new(4, 1.6, 4), CFrame.new(0, 0.8, 0), dk)
					for _, x in ipairs({ -0.7, 0.7 }) do
						s("StatueLeg", Vector3.new(1.1, 4.2, 1.2), CFrame.new(x, 3.7, 0.2))
					end
					s("StatueTabard", Vector3.new(2.6, 2.6, 1.5), CFrame.new(0, 5.2, 0.1), dk)
					s("StatueTorso", Vector3.new(3, 3.2, 1.8), CFrame.new(0, 7.6, 0.1))
					for _, x in ipairs({ -1.8, 1.8 }) do
						s("StatuePauldron", Vector3.new(1.7, 1.7, 1.7), CFrame.new(x, 8.8, 0.1), dk, Enum.PartType.Ball)
						s("StatueArm", Vector3.new(0.9, 3, 0.9), CFrame.new(x * 0.62, 7.4, -0.9) * CFrame.Angles(0.55, 0, -x * 0.12))
					end
					s("StatueHead", Vector3.new(1.4, 1.6, 1.4), CFrame.new(0, 10, 0.1))
					s("StatueCrest", Vector3.new(0.3, 0.9, 1.6), CFrame.new(0, 11, 0.2), dk)
					s("StatueVisor", Vector3.new(1, 0.15, 0.05), CFrame.new(0, 10.15, -0.62), Color3.fromRGB(20, 20, 20))
					s("StatueBlade", Vector3.new(0.6, 6.4, 0.18), CFrame.new(0, 4.8, -1.7), Color3.fromRGB(128, 126, 120))
					s("StatueGuard", Vector3.new(2.6, 0.35, 0.35), CFrame.new(0, 8.1, -1.7), dk)
					s("StatueGrip", Vector3.new(0.35, 1.4, 0.35), CFrame.new(0, 8.9, -1.7), dk)
					s("StatuePommel", Vector3.new(0.6, 0.6, 0.6), CFrame.new(0, 9.7, -1.7), dk, Enum.PartType.Ball)
				end
				statue(Vector3.new(38, KTOP, 216), Vector3.new(-1, 0, 0))
				statue(Vector3.new(38, KTOP, 260), Vector3.new(-1, 0, 0))
				statue(Vector3.new(-30, KTOP, 206), Vector3.new(0, 0, 1))
				statue(Vector3.new(30, KTOP, 206), Vector3.new(0, 0, 1))
				-- red flags on tall poles along the long sides
				for _, f in ipairs({ { -40, 272.6, -1 }, { -28, 272.6, -1 }, { 24, 272.6, -1 }, { 36, 272.6, -1 }, { -36, 203.4, 1 }, { 36, 203.4, 1 } }) do
					cyl("FlagPole", 14, 0.35, CFrame.new(f[1], KTOP + 7, f[2]) * CFrame.Angles(0, 0, math.pi / 2), woodDark, MAT.Wood)
					prop("Flag", Vector3.new(2.6, 7, 0.1), CFrame.new(f[1], KTOP + 9.8, f[2] + f[3] * 0.2), keepRng:NextNumber() < 0.7 and red or navy, MAT.Fabric, false)
					prop("FlagHem", Vector3.new(2.6, 0.35, 0.12), CFrame.new(f[1], KTOP + 6.2, f[2] + f[3] * 0.2), gold, MAT.Fabric, false)
				end
				-- heavy chains slung from the turret to the west towers
				for _, c in ipairs({ { Vector3.new(-17, KTOP + 11, 208), Vector3.new(-55, KTOP + 8, 201) }, { Vector3.new(-17, KTOP + 11, 238), Vector3.new(-55, KTOP + 8, 275) } }) do
					local a, b = c[1], c[2]
					local n = 26
					local prev = a
					for k = 1, n do
						local t = k / n
						local p = a:Lerp(b, t) - Vector3.new(0, 2 * 4 * t * (1 - t), 0) -- (a shallow sag: well over head height)
						local mid = (prev + p) / 2
						prop("ChainLink", Vector3.new(0.35, 0.6, (p - prev).Magnitude + 0.25), CFrame.lookAt(mid, p) * CFrame.Angles(0, 0, (k % 2) * math.pi / 2), iron, MAT.Metal, false)
						prev = p
					end
				end
				ashEmitter(CFrame.new(-5, KTOP + 18, 238), Vector3.new(100, 1, 74), 22)

				-- THE EAST WING: the battlements run on east over a bridge (across the strip below,
				-- where the yard walk's stair comes up), along a great bastion south of the town,
				-- then turn north up its far side, past the east row of houses. Solid castle
				-- beneath: banded, slitted, machicolated walls (the town-facing ones dressed like the
				-- prison's yard walls), towers on the corners. A red runner leads to the prison's bell.
				do
					local W1, W2, WZ1, WZ2 = 60, 196, 181, 221 -- the wing
					local NX1, NZ2 = 176, 290 -- the north arm (x 176..196, z 221..290)
					local deck = Color3.fromRGB(56, 54, 52)
					-- the bridge: a deck on a pier, an arch over the strip either side
					blk(46, KTOP - 3, 201, W1, KTOP - 1, 221, "BridgeDeck", Color3.fromRGB(70, 66, 62))
					blk(56, 0, 201, W1, KTOP - 3, 217, "Bastion")
					for _, z in ipairs({ 201, 221 }) do
						Detail.archRib(Detail.face(51, z, 0, z == 201 and -1 or 1, F1), 0, 19, 5, 4, 1.2, 1.2, 0.5, 9, MAT.Cobblestone, COL.Wall, false)
					end
					-- the masses, and their decks
					blk(W1, 0, WZ1, W2, KTOP - 1, WZ2, "Bastion")
					blk(NX1, 0, WZ2, W2, KTOP - 1, NZ2, "Bastion")
					for _, s in ipairs({ { 46, 201, W1, 221 }, { W1, WZ1, W2, WZ2 }, { NX1, WZ2, W2, NZ2 } }) do
						blk(s[1], KTOP - 1, s[2], s[3], KTOP, s[4], "KeepRoof", deck, MAT.Slate)
					end
					-- the faces the town sees: buttresses, windows, banners (above the square's own wall)
					Detail.dressWall(Detail.face((W1 + NX1) / 2, WZ2, 0, 1, 30), NX1 - W1, KTOP - 1 - 30, "yard")
					Detail.dressWall(Detail.face(NX1, (WZ2 + NZ2) / 2, -1, 0, 22), NZ2 - WZ2, KTOP - 1 - 22, "yard")
					-- every outer face: a machicolation under the parapet; the plain ones string courses and
					-- arrow slits too (from: nothing below this height). axis "z" = a face at z = c spanning x a1..a2
					local function outerFace(axis, c, a1, a2, sign, from)
						local function fix(b1, y1, b2, y2, d1, d2, name, color, mat) -- (keeps min < max)
							local lo, hi = math.min(d1 * sign, d2 * sign), math.max(d1 * sign, d2 * sign)
							if axis == "z" then
								blk(b1, y1, c + lo, b2, y2, c + hi, name, color, mat)
							else
								blk(c + lo, y1, b1, c + hi, y2, b2, name, color, mat)
							end
						end
						for _, y in ipairs({ 24, 46 }) do
							if y > from then
								fix(a1, y, a2, y + 1, 0, 0.6, "Course", COL.Wall, MAT.Slate)
							end
						end
						for b = a1 + 8, a2 - 6, 12 do
							for _, y in ipairs({ 34, 54 }) do
								if y > from then
									fix(b - 0.35, y, b + 0.35, y + 4, -0.05, 0.05, "ArrowSlit", VOIDC, MAT.Slate)
								end
							end
						end
						fix(a1, KTOP - 1.6, a2, KTOP - 1, 0, 1, "Machicolation", COL.Wall, MAT.Slate)
						for b = a1 + 1, a2 - 1, 2 do
							fix(b - 0.4, KTOP - 3, b + 0.4, KTOP - 1.6, 0, 0.8, "Corbel", COL.Wall, MAT.Slate)
						end
					end
					outerFace("z", WZ1, W1, W2, -1, 0) -- the wing's south face (out over nothing)
					outerFace("x", W2, WZ1, NZ2, 1, 0) -- the east face
					outerFace("z", NZ2, NX1, W2, 1, 0) -- the arm's north end
					outerFace("z", WZ2, W1, NX1, 1, math.huge) -- the town faces: dressed above, so only the machicolation
					outerFace("x", NX1, WZ2, NZ2, -1, math.huge)
					-- towers: corners, the middle of the south face, the inner corner (clear of the houses)
					local function bastionTower(x1, z1, x2, z2)
						local top = KTOP + 9
						blk(x1, 0, z1, x2, top, z2, "Tower")
						blk(x1 - 0.6, top - 3.2, z1 - 0.6, x2 + 0.6, top - 2.6, z2 + 0.6, "TowerCourse", COL.Wall, MAT.Slate)
						crenellate(x1, z1, x2, z1, top)
						crenellate(x1, z2, x2, z2, top)
						crenellate(x1, z1, x1, z2, top)
						crenellate(x2, z1, x2, z2, top)
						for _, y in ipairs({ 28, 48, KTOP + 3 }) do
							blk((x1 + x2) / 2 - 0.35, y, z1 - 0.05, (x1 + x2) / 2 + 0.35, y + 4, z1 + 0.05, "ArrowSlit", VOIDC, MAT.Slate)
							blk((x1 + x2) / 2 - 0.35, y, z2 - 0.05, (x1 + x2) / 2 + 0.35, y + 4, z2 + 0.05, "ArrowSlit", VOIDC, MAT.Slate)
							blk(x1 - 0.05, y, (z1 + z2) / 2 - 0.35, x1 + 0.05, y + 4, (z1 + z2) / 2 + 0.35, "ArrowSlit", VOIDC, MAT.Slate)
							blk(x2 - 0.05, y, (z1 + z2) / 2 - 0.35, x2 + 0.05, y + 4, (z1 + z2) / 2 + 0.35, "ArrowSlit", VOIDC, MAT.Slate)
						end
					end
					bastionTower(56, 177, 66, 187)
					bastionTower(110, 175, 120, 185)
					bastionTower(190, 175, 200, 185)
					bastionTower(190, 286, 200, 296)
					bastionTower(176, 286, 186, 296)
					bastionTower(176, 211, 186, 221)

					-- on top: a red runner from the keep to the bell, great fires, flags on the long
					-- sides, stone knights lining the north arm, and the bell itself at its end
					blk(46, KTOP, 209.5, 187.5, KTOP + 0.06, 212.5, "Runner", red, MAT.Fabric)
					blk(184.5, KTOP, 212.5, 187.5, KTOP + 0.06, 279, "Runner", red, MAT.Fabric)
					for _, h in ipairs({ { 46, 209.1, 187.9, 209.5 }, { 46, 212.5, 184.5, 212.9 }, { 184.1, 212.5, 184.5, 279 }, { 187.5, 209.5, 187.9, 279 } }) do
						blk(h[1], KTOP, h[2], h[3], KTOP + 0.07, h[4], "RunnerHem", gold, MAT.Fabric)
					end
					for _, p in ipairs({ { 82, 187 }, { 82, 215 }, { 140, 187 }, { 140, 215 }, { 181, 232 }, { 191, 232 }, { 181, 272 }, { 191, 272 } }) do
						local base = Vector3.new(p[1], KTOP, p[2])
						cyl("BrazierBase", 3, 2.2, CFrame.new(base + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(70, 66, 62), MAT.Slate, true)
						cyl("BrazierBowl", 1.2, 4, CFrame.new(base + Vector3.new(0, 3.6, 0)) * CFrame.Angles(0, 0, math.pi / 2), iron, MAT.Metal, true)
						cyl("BrazierCoals", 0.2, 3.4, CFrame.new(base + Vector3.new(0, 4.2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(255, 110, 40), MAT.Neon)
						fire(base + Vector3.new(0, 4.6, 0), 8, 34)
					end
					for _, f in ipairs({ { 74, 183.4, 1 }, { 96, 183.4, 1 }, { 152, 183.4, 1 }, { 172, 183.4, 1 }, { 74, 218.6, -1 }, { 96, 218.6, -1 }, { 124, 218.6, -1 }, { 152, 218.6, -1 } }) do
						cyl("FlagPole", 14, 0.35, CFrame.new(f[1], KTOP + 7, f[2]) * CFrame.Angles(0, 0, math.pi / 2), woodDark, MAT.Wood)
						prop("Flag", Vector3.new(2.6, 7, 0.1), CFrame.new(f[1], KTOP + 9.8, f[2] + f[3] * 0.2), keepRng:NextNumber() < 0.7 and red or navy, MAT.Fabric, false)
						prop("FlagHem", Vector3.new(2.6, 0.35, 0.12), CFrame.new(f[1], KTOP + 6.2, f[2] + f[3] * 0.2), gold, MAT.Fabric, false)
					end
					for _, z in ipairs({ 244, 260 }) do
						statue(Vector3.new(180, KTOP, z), Vector3.new(1, 0, 0))
						statue(Vector3.new(192, KTOP, z), Vector3.new(-1, 0, 0))
					end
					do -- the prison's bell, that nobody answers any more, in a stone frame
						local bx, bz = 186, 282.5
						local bronze = Color3.fromRGB(122, 92, 50)
						for _, sx in ipairs({ -6, 6 }) do
							blk(bx + sx - 1, KTOP, bz - 1.5, bx + sx + 1, KTOP + 14, bz + 1.5, "BellPillar", Color3.fromRGB(84, 80, 74))
						end
						blk(bx - 7.2, KTOP + 14, bz - 1.2, bx + 7.2, KTOP + 15.4, bz + 1.2, "BellBeam", woodDark, MAT.Wood)
						blk(bx - 7.6, KTOP + 15.4, bz - 1.6, bx + 7.6, KTOP + 16, bz + 1.6, "BellCap", COL.Wall, MAT.Slate)
						cyl("BellYoke", 1, 1.2, CFrame.new(bx, KTOP + 13.4, bz) * CFrame.Angles(0, 0, math.pi / 2), iron, MAT.Metal)
						local swing = {
							part({ Name = "Bell", Shape = Enum.PartType.Ball, Size = Vector3.new(4.6, 4.6, 4.6), CFrame = CFrame.new(bx, KTOP + 11, bz), Material = MAT.Metal, Color = bronze }),
							cyl("BellLip", 1.2, 5.6, CFrame.new(bx, KTOP + 8.9, bz) * CFrame.Angles(0, 0, math.pi / 2), bronze:Lerp(Color3.new(0, 0, 0), 0.15), MAT.Metal, true),
							part({ Name = "BellClapper", Shape = Enum.PartType.Ball, Size = Vector3.new(0.9, 0.9, 0.9), CFrame = CFrame.new(bx, KTOP + 8.1, bz), Material = MAT.Metal, Color = iron, CanCollide = false }),
						}
						local rope = prop("BellRope", Vector3.new(0.2, 7.5, 0.2), CFrame.new(bx + 1.2, KTOP + 4.4, bz), Color3.fromRGB(140, 120, 84), MAT.Fabric, false)
						table.insert(swing, rope)
						-- rung from the rope: init.server enables it once the Castellan falls
						local pp = prompt(rope, "Ring", "The Prison's Bell", 0.6, 8)
						pp.Enabled = false
						info.Bell = { Parts = swing, Pivot = CFrame.new(bx, KTOP + 13.4, bz), Prompt = pp }
					end
					ashEmitter(CFrame.new((W1 + W2) / 2, KTOP + 18, (WZ1 + WZ2) / 2), Vector3.new(W2 - W1, 1, WZ2 - WZ1), 16)
					ashEmitter(CFrame.new((NX1 + W2) / 2, KTOP + 18, (WZ2 + NZ2) / 2), Vector3.new(W2 - NX1, 1, NZ2 - WZ2), 8)
				end

				Detail.useRng(oldRng)
			end
			box(52, 13, 117, 56, 44, 218, MAT.Cobblestone, stoneColor(), "CurtainWall") -- east
			-- south end: the mimic's corner (x 46..52) is walled; x 41..46 is the way round into
			-- the south corridor (THE CIRCUIT, below)
			box(46, 13, 116, 52, 44, 120, MAT.Cobblestone, stoneColor(), "CurtainWall")
			box(39, 13, 116, 46, YW, 120, MAT.Cobblestone, stoneColor(), "YardWalk")
			edge(39, 119, 41, 121, YW) -- (the yard's corner: no stepping onto its wall top)
			crenellate(54, 118, 54, 216, 44)
			for _, y in ipairs({ 36, 41 }) do
				box(51.4, y, 120, 52, y + 0.8, 214, MAT.Slate, COL.Wall, "Course")
			end
			part({ Name = "CurtainTower", Shape = Enum.PartType.Cylinder, Size = Vector3.new(39, 11, 11), CFrame = CFrame.new(54, 13 + 39 / 2, 118) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Cobblestone, Color = stoneColor() })
			for i = 0, 7 do
				local ang = i / 8 * math.pi * 2
				part({ Name = "Merlon", Size = Vector3.new(1.8, 2, 2.2), CFrame = CFrame.new(54 + math.cos(ang) * 5, 53, 118 + math.sin(ang) * 5) * CFrame.Angles(0, -ang, 0), Material = MAT.Cobblestone, Color = stoneColor() })
			end
			-- the stair up to the roof: x 46..52, from z 190 (y 30) to z 214 (y 42), solid underneath
			do
				local a, b = Vector3.new(49, YW + 0.15, 190), Vector3.new(49, ROOF, 214)
				local cf = CFrame.lookAt((a + b) / 2, b)
				local len = (b - a).Magnitude + 0.4
				part({ Name = "Stair", Size = Vector3.new(6, 1.2, len), CFrame = cf * CFrame.new(0, -0.6, 0), Material = MAT.Slate, Color = Color3.fromRGB(74, 70, 66) })
				for i = 1, 11 do
					box(46, YW, 190 + i * 2, 52, YW + i, 192 + i * 2, MAT.Cobblestone, stoneColor(), "StairFill")
				end
				-- (facing north, the slab's +X is west: the open side, over the walk)
				part({ Name = "Parapet", Size = Vector3.new(0.9, 1.6, len), CFrame = cf * CFrame.new(3.45, 0.2, 0), Material = MAT.Cobblestone, Color = stoneColor() })
				part({ Name = "RampartEdge", Size = Vector3.new(0.6, 9, len), CFrame = cf * CFrame.new(3.6, 4.5, 0), Transparency = 1, CanQuery = false })
			end
			for _, z in ipairs({ 135, 165, 195 }) do
				torch(Vector3.new(51.9, YW + 6, z), Vector3.new(-1, 0, 0))
			end
			brazier(Vector3.new(44, YW + 0.15, 170))
			rubble(Vector3.new(47, YW + 0.15, 150), 2, 4)
		end
		-- the fallen beam: from the shop roof's deck (y 11.4) up over its parapet onto
		-- the rampart, footholds nailed across it
		do
			local a, b = Vector3.new(83.5, 11.4, 296.4), Vector3.new(83.5, RT + 0.1, 309)
			local beamCF = CFrame.lookAt((a + b) / 2, b)
			local len = (b - a).Magnitude
			part({ Name = "FallenBeam", Size = Vector3.new(2.8, 0.6, len + 0.4), CFrame = beamCF * CFrame.new(0, -0.3, 0), Material = MAT.Wood, Color = Color3.fromRGB(64, 48, 34) })
			for t = 0.8, len - 0.6, 1.7 do
				part({ Name = "Foothold", Size = Vector3.new(3.1, 0.2, 0.35), CFrame = beamCF * CFrame.new(rng:NextNumber(-0.15, 0.15), 0.08, len / 2 - t) * CFrame.Angles(0, rng:NextNumber(-0.08, 0.08), 0), Material = MAT.WoodPlanks, Color = Color3.fromRGB(78, 60, 42) })
			end
			part({ Name = "BeamSplinter", Size = Vector3.new(0.5, 0.4, 2.2), CFrame = beamCF * CFrame.new(1.1, 0.1, -len / 2 + 0.6) * CFrame.Angles(0.4, 0.3, 0), Material = MAT.Wood, Color = Color3.fromRGB(64, 48, 34), CanCollide = false })
		end

		-- the world past the walls: a ring of dark mountains far out in the haze, and nearer,
		-- the stumps of ruined spires, so the roofs and the rampart look out on something
		-- other than empty sky. Silhouettes only: no collision, no shadows.
		do
			local bg = Random.new(1609) -- (its own seed: the town's layout doesn't shift)
			local centre = Vector3.new(80, 0, 220)
			local crag = Random.new(1610) -- (its own too: bg's draws, and so where everything stands, don't change)
			local function silhouette(name, size, cf, color)
				-- (none where the encampment, its crossing and the far side, or the Weald and its
				-- colosseum now stand: they'd show through them, visible but not solid)
				local c = cf.Position
				for _, q in ipairs({ { 150, 420, 300, 690 }, { -201, 429, 113, 611 }, { -340, -240, -60, 245 }, { 140, -70, 330, 215 }, { 290, 140, 650, 520 } }) do -- (the last two: Pyralis Bulwark and its branch west)
					local dx = c.X - math.clamp(c.X, q[1], q[3])
					local dz = c.Z - math.clamp(c.Z, q[2], q[4])
					if math.sqrt(dx * dx + dz * dz) < math.max(size.X, size.Y, size.Z) * 0.75 then
						return
					end
				end
				local function piece(s, at, tint, mat)
					part({ Name = name, Size = s, CFrame = cf * at, Material = mat, Color = tint, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
				end
				if name ~= "Mountain" then
					piece(size, CFrame.new(), color, MAT.Slate)
					return
				end
				-- a mountain: tilted slabs of rock in place of the one block, each shrunk until it's wholly inside that block, so
				-- its outline breaks up but never leaves the space the block took; a core so nothing shows through; its tip kept
				local function rockTint()
					return color:Lerp(Color3.fromRGB(118, 118, 120), crag:NextNumber(0.3, 0.8))
				end
				piece(size * Vector3.new(0.76, 0.76, 0.5), CFrame.new(), color:Lerp(Color3.fromRGB(118, 118, 120), 0.3), MAT.Rock)
				local tip = size.X * 0.1
				piece(Vector3.new(tip, tip, size.Z * 0.5), CFrame.new((size.X - tip) / 2, (size.Y - tip) / 2, 0), rockTint(), MAT.Rock)
				local GRID = 9
				for i = 1, GRID do
					for j = 1, GRID do
						local s = size * Vector3.new(crag:NextNumber(0.13, 0.24), crag:NextNumber(0.13, 0.24), crag:NextNumber(0.5, 0.9))
						local at = CFrame.new((i - crag:NextNumber(0.2, 0.8)) / GRID * size.X - size.X / 2, (j - crag:NextNumber(0.2, 0.8)) / GRID * size.Y - size.Y / 2, crag:NextNumber(-0.2, 0.2) * size.Z)
							* CFrame.Angles(crag:NextNumber(-0.5, 0.5), crag:NextNumber(-0.5, 0.5), crag:NextNumber(-0.8, 0.8))
						-- (none for what's buried, nor out in the block's two side corners, where they'd float off on their own)
						local keep = (cf * at).Y > -20 and math.abs(at.X - at.Y) < 0.62 * size.X
						for _ = 1, keep and 12 or 0 do
							local inside = true
							for _, sx in ipairs({ -0.5, 0.5 }) do
								for _, sy in ipairs({ -0.5, 0.5 }) do
									for _, sz in ipairs({ -0.5, 0.5 }) do
										local p = at * Vector3.new(sx * s.X, sy * s.Y, sz * s.Z)
										inside = inside and math.abs(p.X) <= size.X / 2 and math.abs(p.Y) <= size.Y / 2 and math.abs(p.Z) <= size.Z / 2
									end
								end
							end
							if inside then
								piece(s, at, rockTint(), crag:NextNumber() < 0.6 and MAT.Rock or MAT.Slate)
								break
							end
							s *= 0.86
						end
					end
				end
			end
			for i = 1, 44 do
				local a = (i + bg:NextNumber(-0.3, 0.3)) / 44 * math.pi * 2
				local pos = centre + Vector3.new(math.cos(a), 0, math.sin(a)) * bg:NextNumber(440, 540)
				local L = bg:NextNumber(170, 330)
				-- a block on its corner, half sunk: a peak; a second, smaller one on its shoulder
				silhouette("Mountain", Vector3.new(L, L, L * 0.4), CFrame.lookAt(pos, centre) * CFrame.Angles(0, 0, math.pi / 4 + bg:NextNumber(-0.2, 0.2)), Color3.fromRGB(40, 42, 50))
				local l2 = L * bg:NextNumber(0.4, 0.65)
				silhouette("Mountain", Vector3.new(l2, l2, l2 * 0.4), CFrame.lookAt(pos, centre) * CFrame.new(L * bg:NextNumber(-0.45, 0.45), L * 0.15, -L * 0.25) * CFrame.Angles(0, 0, math.pi / 4), Color3.fromRGB(46, 48, 56))
			end
			for i = 1, 16 do
				local a = (i + bg:NextNumber(-0.35, 0.35)) / 16 * math.pi * 2
				local pos = centre + Vector3.new(math.cos(a), 0, math.sin(a)) * bg:NextNumber(350, 400)
				local h, w = bg:NextNumber(80, 170), bg:NextNumber(12, 22)
				local cf = CFrame.lookAt(pos, centre) * CFrame.Angles(bg:NextNumber(-0.04, 0.04), 0, bg:NextNumber(-0.05, 0.05))
				local col = Color3.fromRGB(32, 33, 40)
				silhouette("Spire", Vector3.new(w, h, w), cf * CFrame.new(0, h / 2, 0), col)
				if bg:NextNumber() < 0.5 then -- still capped
					silhouette("Spire", Vector3.new(w * 0.7, w * 0.7, w * 0.7), cf * CFrame.new(0, h + w * 0.1, 0) * CFrame.Angles(math.pi / 4, 0, math.pi / 4), col)
				else -- broken off, a jagged stub of wall left standing
					silhouette("Spire", Vector3.new(w * 0.4, w * bg:NextNumber(0.8, 1.6), w * 0.5), cf * CFrame.new(w * 0.3, h + w * 0.4, 0) * CFrame.Angles(0, 0, -0.15), col)
				end
			end
		end

		-----------------------------------------------------------------------
		-- what's in the open
		-----------------------------------------------------------------------
		-- Gallows Square: the gallows, the market that was, a cart on its side
		do
			local gx, gz = 116, 266 -- (beside the way north)
			box(gx - 5, 0, gz - 4, gx + 5, 3.2, gz + 4, MAT.WoodPlanks, Color3.fromRGB(58, 44, 32), "Gallows")
			for k = 1, 3 do
				box(gx - 1.5, 0, gz + 4 + (k - 1) * 1.2, gx + 1.5, 3.2 - k * 0.8, gz + 4 + k * 1.2, MAT.WoodPlanks, Color3.fromRGB(58, 44, 32), "GallowsStep")
			end
			box(gx - 1.4, 3.2, gz - 1.4, gx + 1.4, 3.26, gz + 1.4, MAT.Wood, VOID, "Trapdoor")
			box(gx + 3.4, 3.2, gz - 0.4, gx + 4.2, 13.5, gz + 0.4, MAT.Wood, TIMBER, "GallowsPost")
			box(gx - 1, 12.7, gz - 0.4, gx + 4.2, 13.5, gz + 0.4, MAT.Wood, TIMBER, "GallowsBeam")
			part({ Name = "GallowsBrace", Size = Vector3.new(0.4, 3.4, 0.4), CFrame = CFrame.new(gx + 2.6, 11.4, gz) * CFrame.Angles(0, 0, math.rad(45)), Material = MAT.Wood, Color = TIMBER })
			part({ Name = "Rope", Size = Vector3.new(0.14, 3.2, 0.14), CFrame = CFrame.new(gx, 11.1, gz), Material = MAT.Fabric, Color = Color3.fromRGB(120, 104, 80), CanCollide = false })
			part({ Name = "Noose", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.14, 1, 1), CFrame = CFrame.new(gx, 9.1, gz) * CFrame.Angles(0, math.pi / 2, 0), Material = MAT.Fabric, Color = Color3.fromRGB(120, 104, 80), CanCollide = false })
			Detail.bonePile(Vector3.new(gx - 3, 3.2, gz - 2), 4)
		end
		stall(Vector3.new(72, 0, 284), 0)
		stall(Vector3.new(84, 0, 286), 0.1)
		stall(Vector3.new(146, 0, 280), math.pi / 2)
		crate(Vector3.new(77.5, 0, 287), 2, 0.3)
		crate(Vector3.new(78.2, 0, 289.2), 1.6, 1.1)
		cart(Vector3.new(70, 0, 236), 0.6)
		deadTree(Vector3.new(74, 0, 242), 1)
		brazier(Vector3.new(92, 0, 272))
		Detail.puddle(Vector3.new(90, 0, 262), 6, 3.5, 0.3)
		Detail.puddle(Vector3.new(128, 0, 250), 5, 3, 1.1)
		Detail.barrel(Vector3.new(142, 0, 236), false)
		Detail.barrel(Vector3.new(143.5, 0, 237.4), true)
		ashEmitter(CFrame.new(110, 30, 260), Vector3.new(100, 1, 70), 12)

		-- the Lane: a spill of rubble from a fallen house, another cart, a well
		debrisPile(CFrame.new(), 108, 335, 10, 7, 3)
		cart(Vector3.new(150, 0, 316), 2.6)
		well(114, 305)
		deadTree(Vector3.new(148, 0, 306), 0.85)
		brazier(Vector3.new(118, 0, 368))
		Detail.puddle(Vector3.new(131, 0, 318), 5, 3, 0.2)
		Detail.slumpedSkeleton(Vector3.new(101.2, 0, 326), Vector3.new(1, 0, 0))
		ashEmitter(CFrame.new(130, 30, 342), Vector3.new(60, 1, 95), 8)

		-- the Upper Town: a churchyard gone to weeds, a well, the street to the standing house
		do
			for row = 0, 2 do
				for c = 0, 5 do
					if rng:NextNumber() < 0.8 then
						Detail.gravestone(Vector3.new(170 + c * 5 + rng:NextNumber(-0.6, 0.6), 0, 399 + row * 6), math.pi + rng:NextNumber(-0.25, 0.25))
					end
				end
			end
			-- a low iron fence on its open sides
			for _, f in ipairs({ { 166, 395, 202, 395 }, { 202, 395, 202, 419 } }) do
				local a, b = Vector3.new(f[1], 0, f[2]), Vector3.new(f[3], 0, f[4])
				local n = math.floor((b - a).Magnitude / 1.6)
				for i = 0, n do
					if rng:NextNumber() < 0.88 then
						local p = a:Lerp(b, i / n)
						part({ Name = "FencePost", Size = Vector3.new(0.18, 2.6, 0.18), CFrame = CFrame.new(p + Vector3.new(0, 1.3, 0)) * CFrame.Angles(rng:NextNumber(-0.12, 0.12), 0, rng:NextNumber(-0.12, 0.12)), Material = MAT.Metal, Color = COL.Iron })
					end
				end
				for _, y in ipairs({ 0.8, 2.2 }) do
					local mid = (a + b) / 2 + Vector3.new(0, y, 0)
					part({ Name = "FenceRail", Size = Vector3.new(0.12, 0.12, (b - a).Magnitude), CFrame = CFrame.lookAt(mid, mid + (b - a)), Material = MAT.Metal, Color = COL.Rust, CanCollide = false })
				end
			end
		end
		well(225, 402)
		deadTree(Vector3.new(192, 0, 352), 1.1)
		deadTree(Vector3.new(252, 0, 404), 0.9)
		cart(Vector3.new(262, 0, 402), -0.4)
		debrisPile(CFrame.new(), 262, 340, 9, 5, 3)
		brazier(Vector3.new(230, 0, 366))
		Detail.puddle(Vector3.new(214, 0, 386), 6, 3, 0.4)
		Detail.puddle(Vector3.new(256, 0, 362), 4, 2.5, 1.2)
		Detail.bonePile(Vector3.new(186, 0, 386), 6)
		ashEmitter(CFrame.new(220, 30, 375), Vector3.new(120, 1, 90), 12)

		-- the fog lying over the whole town (Config.TownFog: poison builds while you're in
		-- it): low, slow banks of it drifting through the streets
		local fogColor = Color3.fromRGB(150, 158, 128)
		local function fogBank(x1, z1, x2, z2)
			local p = part({ Name = "TownFog", Size = Vector3.new(x2 - x1, 5, z2 - z1), CFrame = CFrame.new((x1 + x2) / 2, 3, (z1 + z2) / 2), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
			local pe = Instance.new("ParticleEmitter")
			pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
			pe.Rate = (x2 - x1) * (z2 - z1) / 700
			pe.Lifetime = NumberRange.new(10, 16)
			pe.Speed = NumberRange.new(0.2, 0.7)
			pe.SpreadAngle = Vector2.new(180, 10)
			pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 10), NumberSequenceKeypoint.new(1, 18) })
			pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.832), NumberSequenceKeypoint.new(0.7, 0.856), NumberSequenceKeypoint.new(1, 1) })
			pe.Color = ColorSequence.new(fogColor)
			pe.LightInfluence = 1
			pe.RotSpeed = NumberRange.new(-6, 6)
			pe.Rotation = NumberRange.new(0, 360)
			pe.Acceleration = Vector3.new(0.15, 0.02, 0.1)
			pcall(function()
				pe.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
			end)
			pe.Parent = p
		end
		fogBank(60, 225, 160, 295) -- Gallows Square
		fogBank(100, 295, 160, 390) -- the Lane
		fogBank(160, 330, 280, 420) -- the Upper Town

		-----------------------------------------------------------------------
		-- THE MESA TOWN: the Highlands' hill over the Blind Chapel (x -192..-96, z 108..236, grass at
		-- y 60; the terrain pass, the ramp, the hole and the invisible walls are in the Weald's section).
		-- The township's houses, rotted, round the sinkhole that drops into the Oculast arena: every
		-- side of every house dressed (no blank walls), burned-out shells and collapsed lots among them,
		-- a hall with a belfry facing the hole. Nothing lives in it. (Last in this stream, so nothing
		-- above shifts.)
		-----------------------------------------------------------------------
		do
			local MY = 60
			local function at(x, z)
				return Vector3.new(x, MY, z)
			end
			local SLATE_ROOF = Color3.fromRGB(46, 44, 46)

			-- one face of a house, dressed like its front: footing, a beam along each floor, posts,
			-- a window (or a brace) in each bay. cf looks out of the face; the face is w wide and h tall
			-- (rows of windows begin 3.9 up, over the footing); depth d is how far it stands out
			local function dressFace(cf, w, h)
				local function L(name, x1, y1, z1, x2, y2, z2, mat, color)
					return lbox(cf, name, x1, y1, z1, x2, y2, z2, mat, color, false)
				end
				L("Footing", -w / 2, 0, 0, w / 2, 3.6, 0.5, MAT.Cobblestone, stoneColor())
				local n = math.max(1, math.floor((h - 0.6) / SH + 0.01))
				for k = 1, n do
					if k * SH < h - 0.4 then
						L("Beam", -w / 2, k * SH - 0.25, 0, w / 2, k * SH + 0.25, 0.35, MAT.Wood, TIMBER)
					end
				end
				local posts = math.max(2, math.floor(w / 4.5) + 1)
				local px = {}
				for i = 1, posts do
					px[i] = -w / 2 + 0.3 + (w - 0.6) * (i - 1) / (posts - 1)
					L("Post", px[i] - 0.22, 3.6, 0, px[i] + 0.22, h - 0.05, 0.3, MAT.Wood, TIMBER)
				end
				for k = 0, n - 1 do
					local base = k == 0 and 3.9 or k * SH + 1.4
					for i = 1, posts - 1 do
						local x, bw = (px[i] + px[i + 1]) / 2, px[i + 1] - px[i]
						if bw > 3 and base + 3 < h - 0.3 then
							if rng:NextNumber() < 0.75 then
								L("WindowVoid", x - 1.1, base, 0, x + 1.1, base + 3, 0.08, MAT.Slate, VOID)
								L("Sill", x - 1.45, base - 0.3, 0, x + 1.45, base, 0.45, MAT.Wood, TIMBER)
								local s = rng:NextNumber()
								if s < 0.3 then
									rel(cf, { Name = "Board", Size = Vector3.new(2.9, 0.4, 0.12), CFrame = CFrame.new(x, base + 1.5, 0.2) * CFrame.Angles(0, 0, rng:NextNumber(-0.5, 0.5)), Material = MAT.WoodPlanks, Color = BOARD })
								elseif s < 0.6 then
									local side = rng:NextNumber() < 0.5 and -1 or 1
									rel(cf, { Name = "Shutter", Size = Vector3.new(1.1, 3, 0.12), CFrame = CFrame.new(x + side * 1.75, base + 1.4, 0.2) * CFrame.Angles(0, 0, side * rng:NextNumber(0.05, 0.4)), Material = MAT.WoodPlanks, Color = BOARD })
								end
							else
								local len = math.sqrt(bw * bw + SH * SH) - 0.6
								rel(cf, { Name = "Brace", Size = Vector3.new(0.36, len, 0.14), CFrame = CFrame.new(x, base + 1.5, 0.15) * CFrame.Angles(0, 0, math.atan2(bw, SH) * (rng:NextNumber() < 0.5 and 1 or -1)), Material = MAT.Wood, Color = TIMBER })
							end
						end
					end
				end
			end
			-- all of a house's other faces: the back (z = D, looking +z) and, at a row's ends, a side
			local function dressOut(cf, w, h, sides)
				dressFace(cf * CFrame.new(0, 0, D), w, h)
				if sides then
					for _, s in ipairs({ -1, 1 }) do
						dressFace(cf * CFrame.new(s * w / 2, 0, D / 2) * CFrame.Angles(0, s * math.pi / 2, 0), D, h)
					end
				end
			end

			-- a row of them, a -> b facing inward: about half burned-out shells, a lot or two fallen in
			local function mesaRow(a, b, inward)
				local dir, len = (b - a).Unit, (b - a).Magnitude
				local t = 0
				while t < len - 0.01 do
					local left = len - t
					local w = math.min(rng:NextNumber(10, 16), left)
					if left - w < 7 then
						w = left
					end
					local mid = a + dir * (t + w / 2)
					local cf = CFrame.lookAt(mid, mid + inward)
					local ends = t < 0.01 or t + w > len - 0.01
					if w >= 8 and rng:NextNumber() > 0.2 then
						local _, H = house(cf, w, { ruined = rng:NextNumber() < 0.5 })
						dressOut(cf, w, H, ends)
					else
						collapsedLot(cf, w)
					end
					t += w
				end
			end
			mesaRow(at(-162, 200), at(-162, 230), IN_W) -- east side of the ramp's street
			mesaRow(at(-144, 196), at(-114, 196), IN_S) -- north of the sinkhole
			mesaRow(at(-167, 140), at(-167, 186), IN_E) -- west
			mesaRow(at(-167, 134), at(-154, 134), IN_N) -- south, either side of the gate to the citadel (x -152..-124)
			mesaRow(at(-122, 134), at(-110, 134), IN_N)
			mesaRow(at(-114, 178), at(-114, 192), IN_W) -- east, north of the hall

			-- the hall, facing the hole across the square: three storeys, a wide door, a belfry on
			-- the south end of it (stone, narrow windows, a pointed slate roof)
			do
				local cf = CFrame.lookAt(at(-114, 164), at(-114, 164) + IN_W)
				local _, H = house(cf, 28, { stories = 3, ruined = false, gable = true, doorW = 5, doorH = 8, doorX = 0, torch = true })
				dressOut(cf, 28, H, true)
				local TH = H + 10
				local stone = Color3.fromRGB(86, 82, 76)
				lbox(cf, "Belfry", 15, 0, 3, 25, TH, 13, MAT.Cobblestone, stone, true)
				for y = 8, TH - 6, 9 do
					lbox(cf, "BelfryCourse", 14.7, y, 2.7, 25.3, y + 0.4, 13.3, MAT.Slate, stone:Lerp(COL.WallDark, 0.4))
				end
				for _, f in ipairs({ { 20, 2.9, 0 }, { 20, 13.1, 0 }, { 14.9, 8, 1 }, { 25.1, 8, 1 } }) do -- a slit on each face, high up
					local x, z, side = f[1], f[2], f[3] == 1
					lbox(cf, "BelfrySlit", side and x - 0.1 or x - 0.5, TH - 5, side and z - 0.5 or z - 0.1, side and x + 0.1 or x + 0.5, TH - 1.5, side and z + 0.5 or z + 0.1, MAT.Slate, VOID)
				end
				for i = 0, 4 do -- the roof, stepping in to a point
					local inset = 0.4 + i * 1.0
					lbox(cf, "BelfryRoof", 15 + inset, TH + i * 1.8, 3 + inset, 25 - inset, TH + (i + 1) * 1.8, 13 - inset, MAT.Slate, SLATE_ROOF, i < 2)
				end
			end

			local plaza = { -165, 139, -115, 193 }
			local function offHole(x, z) -- (the stone-lined hole: x -141..-121, z 150..170)
				return not (x > -145 and x < -117 and z > 146 and z < 174)
			end
			for _, r in ipairs({ { -165, 139, -145, 193 }, { -145, 139, -117, 146 }, { -145, 174, -117, 193 } }) do
				Detail.rotPatches(r[1], r[2], r[3], r[4], 12, MY)
			end
			for k = 0, 7 do -- the rot creeping out of the hole across the square
				local a = k / 8 * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
				Detail.rotVein(at(-131 + math.cos(a) * 15, 160 + math.sin(a) * 15), a, rng:NextNumber(8, 20), rng:NextNumber(0.5, 0.8), 1, plaza)
			end
			for _ = 1, 30 do
				local x, z = rng:NextNumber(plaza[1], plaza[3]), rng:NextNumber(plaza[2], plaza[4])
				if offHole(x, z) then
					Detail.weeds(at(x, z), rng:NextInteger(2, 4))
				end
			end
			Detail.bonePile(at(-152, 168), 7)
			Detail.bonePile(at(-120, 140), 6)
			Detail.slumpedSkeleton(at(-150, 188), Vector3.new(0, 0, -1))
			Detail.slumpedSkeleton(at(-118, 184), Vector3.new(-1, 0, 0))
			Detail.overgrownCorpse(at(-153, 148), Vector3.new(1, 0, 0.3).Unit)
			Detail.overgrownCorpse(at(-126, 180), Vector3.new(-0.4, 0, -1).Unit)
			Detail.barrel(at(-158, 191), false)
			Detail.barrel(at(-120, 142), true)
			crate(at(-162, 144), 2, 0.4)
			crate(at(-118, 190), 2.2, 1.1)
			rubble(at(-148, 142), 2, 5)
			rubble(at(-150, 205), 2, 5)

			---------------------------------------------------------------------
			-- THE CITADEL: past the town's south gate, the plateau runs on into a walled district
			-- (x -332..-94, z -232..108): rotted houses along the inside of its walls and, filling the
			-- middle of it, the Hollow Mansion, a gargantuan decayed gothic pile. Only its outside is built
			-- for now (solid), a boss is to live in it later. Nothing lives out here either.
			---------------------------------------------------------------------
			local WH = 26 -- the curtain wall's height above the grass
			local STONE, TRIM, SLATE, MOSS = Color3.fromRGB(62, 58, 56), Color3.fromRGB(94, 90, 84), Color3.fromRGB(40, 40, 46), Color3.fromRGB(50, 58, 40)
			-- a box in plateau terms: x, z absolute, y above the grass
			local function B(x1, y1, z1, x2, y2, z2, name, color, mat, solid)
				local p = box(x1, MY + y1, z1, x2, MY + y2, z2, mat or MAT.Cobblestone, color or STONE:Lerp(COL.WallDark, rng:NextNumber() * 0.5), name)
				if solid == false then
					p.CanCollide = false
				end
				return p
			end
			-- an invisible wall, tall, that stops nobody walking off the top of a wall or roof
			local function ward(x1, z1, x2, z2)
				local w = box(x1, MY - 20, z1, x2, MY + 400, z2, MAT.SmoothPlastic, COL.Wall, "CitadelEdge")
				w.Transparency, w.CanQuery, w.CastShadow = 1, false, false
			end

			-- THE WALLS: 4 thick, crenellated, a tower at every corner and every so often, a gatehouse in the
			-- north wall (x -150..-126), the way back to the town
			B(-332, 0, -232, -328, WH, 108, "CitadelWall")
			B(-332, 0, -232, -94, WH, -228, "CitadelWall")
			-- (the east wall has the drawbridge's gateway, z 79..91, y 0..14; one colour for its three pieces keeps the random stream as it was)
			local eastCol = STONE:Lerp(COL.WallDark, rng:NextNumber() * 0.5)
			B(-98, 0, -232, -94, WH, 79, "CitadelWall", eastCol)
			B(-98, 0, 91, -94, WH, 108, "CitadelWall", eastCol)
			B(-98, 14, 79, -94, WH, 91, "CitadelWall", eastCol)
			B(-332, 0, 104, -150, WH, 108, "CitadelWall")
			B(-126, 0, 104, -94, WH, 108, "CitadelWall")
			B(-150, 15, 104, -126, WH, 108, "GateLintel")
			-- the gate: an iron portcullis, down. It goes up when both Tillers are (Characters/TillerShared). The
			-- invisible blocker behind its bars keeps anyone squeezing between them.
			local gateBars = {}
			local IRON = Color3.fromRGB(42, 38, 34)
			for i = 0, 10 do
				table.insert(gateBars, B(-149.5 + i * 2.4, 0, 105, -149 + i * 2.4, 16, 106, "GateBar", IRON, MAT.Metal))
			end
			for _, y in ipairs({ 3, 9, 14.5 }) do
				table.insert(gateBars, B(-150, y, 105.2, -126, y + 0.6, 105.8, "GateRail", IRON, MAT.Metal))
			end
			local blocker = box(-150, MY, 104, -126, MY + WH, 108, MAT.SmoothPlastic, COL.Wall, "GateBlocker")
			blocker.Transparency, blocker.CanQuery, blocker.CastShadow = 1, false, false
			info.CitadelGate = { Bars = gateBars, Blocker = blocker }
			crenellate(-330, -230, -330, 106, MY + WH)
			crenellate(-330, -230, -96, -230, MY + WH)
			crenellate(-96, -230, -96, 106, MY + WH)
			crenellate(-330, 106, -150, 106, MY + WH)
			crenellate(-126, 106, -96, 106, MY + WH)
			local function citTower(cx, cz, s, h)
				B(cx - s, -MY, cz - s, cx + s, h, cz + s, "CitadelTower") -- (down to the prison's ground level: the cliff edge is inside the towers on the east and north, and their feet showed from below)
				B(cx - s - 0.8, h - 2.4, cz - s - 0.8, cx + s + 0.8, h - 0.6, cz + s + 0.8, "TowerCourse", TRIM, MAT.Slate)
				crenellate(cx - s, cz - s, cx + s, cz - s, MY + h)
				crenellate(cx - s, cz + s, cx + s, cz + s, MY + h)
				crenellate(cx - s, cz - s, cx - s, cz + s, MY + h)
				crenellate(cx + s, cz - s, cx + s, cz + s, MY + h)
				for _, y in ipairs({ 14, 26 }) do
					B(cx - 0.4, y, cz - s - 0.1, cx + 0.4, y + 3.4, cz - s + 0.1, "ArrowSlit", VOID, MAT.Slate, false)
					B(cx - 0.4, y, cz + s - 0.1, cx + 0.4, y + 3.4, cz + s + 0.1, "ArrowSlit", VOID, MAT.Slate, false)
					B(cx - s - 0.1, y, cz - 0.4, cx - s + 0.1, y + 3.4, cz + 0.4, "ArrowSlit", VOID, MAT.Slate, false)
					B(cx + s - 0.1, y, cz - 0.4, cx + s + 0.1, y + 3.4, cz + 0.4, "ArrowSlit", VOID, MAT.Slate, false)
				end
			end
			for _, t in ipairs({ { -330, -230 }, { -330, 106 }, { -96, -230 }, { -96, 106 }, { -330, 40 }, { -330, -60 }, { -330, -150 }, { -96, 40 }, { -96, -60 }, { -96, -150 }, { -270, -230 }, { -210, -230 }, { -150, -230 }, { -260, 106 } }) do
				citTower(t[1], t[2], 7, 38)
			end
			citTower(-157, 106, 7, 46) -- the gatehouse
			citTower(-119, 106, 7, 46)
			ward(-336, -236, -332, 112) -- no walking off the top of any of it
			ward(-336, -236, -90, -232)
			ward(-94, -236, -90, 79) -- (open at the gateway)
			ward(-94, 91, -90, 112)
			ward(-336, 108, -150, 112)
			ward(-126, 108, -90, 112)
			-- (the plateau's grass under the gate and the avenue: flagged)
			B(-152, -0.1, 14, -124, 0.12, 120, "Avenue", Color3.fromRGB(70, 66, 62), MAT.Cobblestone)
			B(-225, -0.1, 40, -124, 0.12, 60, "Avenue", Color3.fromRGB(70, 66, 62), MAT.Cobblestone)
			B(-225, -0.1, 14, -205, 0.12, 60, "Avenue", Color3.fromRGB(70, 66, 62), MAT.Cobblestone)

			-- THE HOUSES: along the inside of the walls, backs to them, facing the mansion
			mesaRow(at(-322, 88), at(-176, 88), IN_S)
			mesaRow(at(-316, 66), at(-316, -204), IN_E)
			mesaRow(at(-114, 66), at(-114, -204), IN_W)
			mesaRow(at(-306, -214), at(-124, -214), IN_N)

			-- THE HOLLOW MANSION -------------------------------------------------
			-- (a lancet window: frame, dark glass, a diamond for its pointed head. fx, fz = its middle on the
			-- wall; onZ = the face looks along z, dir = ±1 which way; y = its sill; w, h = the glass)
			local function glassFor(k) -- old stained glass gone dull under the grime: faded wine, slate, smoke; now and then a dim warm one
				local n = math.floor(math.abs(k) * 3) % 9
				if n == 0 then
					return Color3.fromRGB(96, 78, 60), MAT.Glass
				elseif n <= 3 then
					return Color3.fromRGB(54, 36, 38), MAT.Glass
				elseif n <= 6 then
					return Color3.fromRGB(38, 42, 46), MAT.Glass
				end
				return Color3.fromRGB(32, 32, 30), MAT.Glass
			end
			local function lancet(fx, fz, onZ, dir, y, w, h)
				local function slab(name, hw, y1, y2, o1, o2, color, mat)
					if onZ then
						return B(fx - hw, y1, fz + dir * o1, fx + hw, y2, fz + dir * o2, name, color, mat, false)
					end
					return B(fx + dir * o1, y1, fz - hw, fx + dir * o2, y2, fz + hw, name, color, mat, false)
				end
				slab("WinFrame", w / 2 + 0.8, y - 0.5, y + h + 1.2, 0, 0.5, TRIM, MAT.Slate)
				local pane, paneMat = glassFor(fx + fz + y)
				local wear = math.floor(math.abs(fx * 7.3 + fz * 3.1 + y * 1.7)) % 13 -- (hashed, not rolled: the map's stream must not shift)
				if wear <= 2 then -- the glass gone: dark behind
					pane, paneMat = VOID, MAT.Slate
				end
				slab("WinGlass", w / 2, y, y + h, 0.4, 0.7, pane, paneMat)
				if wear == 0 then -- boarded over
					slab("WinBoard", w / 2 + 0.6, y + h * 0.3 - 0.5, y + h * 0.3 + 0.5, 0.7, 1, Color3.fromRGB(56, 46, 38), MAT.WoodPlanks)
					slab("WinBoard", w / 2 + 0.6, y + h * 0.7 - 0.5, y + h * 0.7 + 0.5, 0.7, 1, Color3.fromRGB(50, 42, 34), MAT.WoodPlanks)
				end
				if wear % 3 == 1 and y > 3 then -- grime run down from the sill
					slab("WinGrime", 0.7, y - 5, y - 0.5, 0, 0.55, SOOT, MAT.SmoothPlastic).Transparency = 0.5
				end
				local s = w / math.sqrt(2)
				local c = onZ and Vector3.new(fx, MY + y + h, fz + dir * 0.55) or Vector3.new(fx + dir * 0.55, MY + y + h, fz)
				part({ Name = "WinHead", Size = onZ and Vector3.new(s, s, 0.3) or Vector3.new(0.3, s, s), CFrame = CFrame.new(c) * (onZ and CFrame.Angles(0, 0, math.pi / 4) or CFrame.Angles(math.pi / 4, 0, 0)), Material = paneMat, Color = pane, CanCollide = false })
			end
			-- every face of a block: piers, a string course under each row, rows of windows
			-- (c = the face's fixed coordinate, a1..a2 = its run, rows = window sills, top = wall height)
			local function facade(onZ, dir, c, a1, a2, top, rows, spacing)
				local n = math.max(math.floor((a2 - a1) / spacing), 1)
				local start = a1 + ((a2 - a1) - n * spacing) / 2
				for i = 0, n do
					local a = start + i * spacing
					if onZ then
						if not (c == -10 and dir == 1 and a > -233 and a < -197) then -- (not in the vestibule)
							B(a - 1.2, 0, c, a + 1.2, top - 3, c + dir * 1.4, "Pier", TRIM)
						end
					else
						B(c, 0, a - 1.2, c + dir * 1.4, top - 3, a + 1.2, "Pier", TRIM)
					end
					if i < n then
						local m = a + spacing / 2
						for _, y in ipairs(rows) do
							if y + 11 < top - 2 and rng:NextNumber() < 0.9 then
								if onZ then
									lancet(m, c, true, dir, y, 3.2, 9)
								else
									lancet(c, m, false, dir, y, 3.2, 9)
								end
							end
						end
					end
				end
				for _, y in ipairs(rows) do
					if onZ then
						for _, k in ipairs((c == -10 and dir == 1) and { { a1, -224 }, { -206, a2 } } or { { a1, a2 } }) do -- (a gap for the vestibule)
							B(k[1], y - 2, c, k[2], y - 1.2, c + dir * 0.9, "Course", TRIM)
						end
					else
						B(c, y - 2, a1, c + dir * 0.9, y - 1.2, a2, "Course", TRIM)
					end
				end
			end
			local function gargoyle(x, y, z, dx, dz)
				local cf = CFrame.lookAt(Vector3.new(x, MY + y, z), Vector3.new(x + dx, MY + y - 0.4, z + dz))
				rel(cf, { Name = "Gargoyle", Size = Vector3.new(1.8, 1.8, 4), CFrame = CFrame.new(0, 0, -2), Material = MAT.Slate, Color = SLATE:Lerp(TRIM, 0.3) })
				rel(cf, { Name = "GargoyleHead", Shape = Enum.PartType.Ball, Size = Vector3.new(2.2, 2.2, 2.2), CFrame = CFrame.new(0, 0.3, -4.3), Material = MAT.Slate, Color = SLATE:Lerp(TRIM, 0.3) })
				for _, s in ipairs({ -1, 1 }) do
					rel(cf, { Name = "GargoyleWing", Size = Vector3.new(0.3, 2.6, 2.4), CFrame = CFrame.new(s * 1.3, 1.1, -0.6) * CFrame.Angles(0, 0, s * -0.5), Material = MAT.Slate, Color = SLATE })
				end
			end
			-- a spire: a stack of boxes narrowing to a point, a finial on its tip
			local function spire(cx, cz, hx, hz, y0, h, n)
				local dh = h / n
				for i = 0, n - 1 do
					local k = 1 - i / n
					B(cx - hx * k, y0 + i * dh, cz - hz * k, cx + hx * k, y0 + (i + 1) * dh + 0.1, cz + hz * k, "Spire", SLATE:Lerp(TRIM, rng:NextNumber() * 0.2), MAT.Slate)
				end
				B(cx - 0.3, y0 + h, cz - 0.3, cx + 0.3, y0 + h + 7, cz + 0.3, "Finial", Color3.fromRGB(30, 28, 28), MAT.Metal, false)
				B(cx - 1.4, y0 + h + 3.5, cz - 0.15, cx + 1.4, y0 + h + 4, cz + 0.15, "Finial", Color3.fromRGB(30, 28, 28), MAT.Metal, false)
			end
			-- a tower, any rectangle: courses, a window in every face on every floor, a corbelled top,
			-- gargoyles on the corners, a spire
			local function mTower(x1, z1, x2, z2, h, spireH, noLow, hollow)
				local cx, cz, hx, hz = (x1 + x2) / 2, (z1 + z2) / 2, (x2 - x1) / 2, (z2 - z1) / 2
				if hollow then -- (the entrance tower's body is the mansion's vestibule, built with the hall; burn the colour roll the solid body took)
					rng:NextNumber()
				else
					B(x1, 0, z1, x2, h, z2, "MansionTower")
				end
				for y = 14, h - 12, 18 do
					if not (noLow and y < 40) then -- (the great door fills the entrance tower's face)
						lancet(cx, z2, true, 1, y, 3.2, 9)
					end
					lancet(cx, z1, true, -1, y, 3.2, 9)
					lancet(x2, cz, false, 1, y, 3.2, 9)
					lancet(x1, cz, false, -1, y, 3.2, 9)
					if hollow then -- (a ring round the outside only, not a slab through the vestibule, and no band across the great door)
						local ya, yb = y - 2, y - 1.2
						if yb > 30 then -- (the back is open into the hall up to the vestibule's ceiling)
							B(x1 - 0.4, ya, z1 - 0.4, x2 + 0.4, yb, z1 + 0.8, "Course", TRIM, MAT.Slate)
						end
						B(x1 - 0.4, ya, z1 + 0.8, x1 + 0.8, yb, z2 + 0.4, "Course", TRIM, MAT.Slate)
						B(x2 - 0.8, ya, z1 + 0.8, x2 + 0.4, yb, z2 + 0.4, "Course", TRIM, MAT.Slate)
						if yb > 26 then
							B(x1 + 0.8, ya, z2 - 0.8, x2 - 0.8, yb, z2 + 0.4, "Course", TRIM, MAT.Slate)
						else
							B(x1 + 0.8, ya, z2 - 0.8, -222, yb, z2 + 0.4, "Course", TRIM, MAT.Slate)
							B(-208, ya, z2 - 0.8, x2 - 0.8, yb, z2 + 0.4, "Course", TRIM, MAT.Slate)
						end
					else
						B(x1 - 0.4, y - 2, z1 - 0.4, x2 + 0.4, y - 1.2, z2 + 0.4, "Course", TRIM, MAT.Slate)
					end
				end
				B(x1 - 2, h - 3, z1 - 2, x2 + 2, h, z2 + 2, "Corbel", TRIM)
				B(x1 - 1.2, h, z1 - 1.2, x2 + 1.2, h + 10, z2 + 1.2, "Belfry")
				lancet(cx, z2 + 1.2, true, 1, h + 2, 2.6, 6)
				lancet(cx, z1 - 1.2, true, -1, h + 2, 2.6, 6)
				lancet(x2 + 1.2, cz, false, 1, h + 2, 2.6, 6)
				lancet(x1 - 1.2, cz, false, -1, h + 2, 2.6, 6)
				spire(cx, cz, hx + 1.8, hz + 1.8, h + 10, spireH, 12)
				for _, c in ipairs({ { x1 - 2, z1 - 2, -1, -1 }, { x2 + 2, z1 - 2, 1, -1 }, { x1 - 2, z2 + 2, -1, 1 }, { x2 + 2, z2 + 2, 1, 1 } }) do
					gargoyle(c[1], h - 2, c[2], c[3], c[4])
				end
			end

			-- the great hall, and its wings
			local HT = 70
			local OCX, OCZ, OQ = -215, -80, 16 -- the attic's oculus: a square shaft (half-width OQ) up through the ridge over the arena, a round window at its head
			local mansionClear = {} -- boxes { x1, y1, z1, x2, y2, z2 } (plateau terms) no decoration may stand in: doorways, stairs (filled with the hall)
			do
			-- THE HALL, HOLLOWED: the great hall was a solid block; now it is a two-storey ruin with a way through it.
			--   ground: foyer | nave | rear hall down the middle, library + servants' hall (west), dining hall + kitchens (east)
			--   upper:  the same plan, the nave open to the roof with a gallery round it
			-- THE WAY THROUGH, front door to attic. Every barred door is a step in it or a shortcut it pays for, and the
			-- shortcuts open only from the far side, after a long way round, onto something much earlier:
			--   1. the foyer's only open door is the library's; the dining hall's door and the nave's arch are barred from the foyer
			--   2. library -> servants' hall -> up the servants' stair into the dormitory (a flask in the reading gallery off it)
			--   3. dormitory -> rear gallery -> upper kitchens. Two ways on from here:
			--        down the kitchens' stair: kitchens -> dining hall (open the barred door: SHORTCUT to the foyer),
			--        or kitchens -> rear hall -> open its door into the nave (and the nave's arch: SHORTCUT to the foyer)
			--      and along the banquet gallery, through the door that opens only from it, onto the nave's gallery:
			--        mages over the nave, a door back into the reading gallery (SHORTCUT to the dormitory), the LADDER to kick
			--        down (SHORTCUT to the nave), and the landing: the last flask, and the stair up to the ATTIC arena
			-- (its own random streams: nothing built after it shifts)
			rng:NextNumber() -- (the hall's old solid block took one, so the map's stream stays where it was)
			local oldRng = rng
			rng = Random.new(8801)
			local oldDetailRng = Detail.useRng(Random.new(8802))
			local IN_STONE, IN_FLOOR, IN_WOOD = Color3.fromRGB(46, 43, 41), Color3.fromRGB(34, 32, 31), Color3.fromRGB(54, 40, 30)
			local G0, FL, CEIL, AF, ATOP, DH = 0.5, 24.5, 44.5, 46.5, 70, 12 -- floor tops (ground, upper, attic), upper ceiling, attic ceiling, doorway height
			local PLAN_DOORS = { {}, {} }
			info.MansionSpawns, info.MansionDoors = {}, {}
			local function at3(x, y, z)
				return Vector3.new(x, MY + y, z)
			end

			-- a wall 2 thick on one level. alongX: it runs along x at z = c (else along z at x = c) from a1 to a2.
			-- doors: { { centre, width = 7, oneWay = true? } ... } (the opening's lintel is built; oneWay doors get their leaf below)
			local function wall(alongX, c, a1, a2, lvl, doors)
				local y1, y2 = lvl == 1 and 0 or FL, lvl == 1 and FL - 2 or CEIL
				local function seg(s1, s2, ya)
					if s2 - s1 < 0.05 then
						return
					end
					if alongX then
						B(s1, ya, c - 1, s2, y2, c + 1, "MansionWall", IN_STONE)
					else
						B(c - 1, ya, s1, c + 1, y2, s2, "MansionWall", IN_STONE)
					end
				end
				table.sort(doors, function(a, b)
					return a[1] < b[1]
				end)
				local cur = a1
				for _, d in ipairs(doors) do
					local w = d[2] or 7
					seg(cur, d[1] - w / 2, y1)
					seg(d[1] - w / 2, d[1] + w / 2, y1 + DH)
					table.insert(PLAN_DOORS[lvl], { alongX, c, d[1], w, d.oneWay })
					cur = d[1] + w / 2
				end
				seg(cur, a2, y1)
			end

			-- a floor slab over the whole interior, with rectangular holes { x1, z1, x2, z2 } cut out of it
			local function slab(y1, y2, holes)
				local zs = { -146, -14 }
				for _, h in ipairs(holes) do
					table.insert(zs, h[2])
					table.insert(zs, h[4])
				end
				table.sort(zs)
				for i = 1, #zs - 1 do
					local za, zb = zs[i], zs[i + 1]
					if zb - za > 0.05 then
						local cuts = {}
						for _, h in ipairs(holes) do
							if h[2] <= za + 0.01 and h[4] >= zb - 0.01 then
								table.insert(cuts, h)
							end
						end
						table.sort(cuts, function(a, b)
							return a[1] < b[1]
						end)
						local cur = -266
						for _, h in ipairs(cuts) do
							if h[1] > cur then
								B(cur, y1, za, h[1], y2, zb, "MansionFloor", IN_FLOOR, MAT.Slate)
							end
							cur = h[3]
						end
						if cur < -164 then
							B(cur, y1, za, -164, y2, zb, "MansionFloor", IN_FLOOR, MAT.Slate)
						end
					end
				end
			end

			-- 24 steps of 1 stud up, climbing toward +z from z0
			local function stair(x1, x2, z0)
				for i = 0, 23 do
					B(x1, 0, z0 + i * 1.1, x2, G0 + i + 1, z0 + (i + 1) * 1.1, "MansionStep", IN_FLOOR, MAT.Slate)
				end
			end

			local function lamp(x, y, z)
				B(x - 0.5, y - 0.5, z - 0.5, x + 0.5, y + 0.5, z + 0.5, "Lantern", COL.Iron, MAT.Metal, false)
				local glow = part({ Name = "LanternFlame", Shape = Enum.PartType.Ball, Size = Vector3.new(0.7, 0.7, 0.7), CFrame = CFrame.new(x, MY + y, z), Material = MAT.Neon, Color = Color3.fromRGB(255, 170, 90), CanCollide = false, CanQuery = false, CanTouch = false })
				local light = Instance.new("PointLight")
				light.Color, light.Range, light.Brightness = Color3.fromRGB(255, 150, 80), 30, 1.6
				light.Parent = glow
				addFlicker(light)
			end

			-- the shell: 4 thick all round, the floors, and the roof's block over the top
			B(-270, 0, -150, -266, ATOP, -10, "MansionWall", IN_STONE)
			B(-164, 0, -150, -160, ATOP, -10, "MansionWall", IN_STONE)
			B(-266, 0, -150, -164, ATOP, -146, "MansionWall", IN_STONE)
			B(-266, 0, -14, -222, ATOP, -10, "MansionWall", IN_STONE) -- the front, open where the vestibule joins it
			B(-208, 0, -14, -164, ATOP, -10, "MansionWall", IN_STONE)
			B(-222, 14, -14, -208, ATOP, -10, "MansionWall", IN_STONE)
			-- the roof over the attic, hollowed: a stepped shell under the shingles (the old fill was solid) with the gable ends
			-- walled, so the attic opens up under the ridge (HT + 84) and the whole arena shows from any floor of it
			local RZC, RHW, RRISE = -80, 71, 84
			local dark = Color3.fromRGB(26, 24, 24)
			local function shell(x1, ya, z1, x2, yb, z2) -- a box of the shell, less the oculus' shaft
				local hx1, hz1, hx2, hz2 = OCX - OQ, OCZ - OQ, OCX + OQ, OCZ + OQ
				for _, r in ipairs({
					{ x1, z1, x2, math.min(z2, hz1) }, { x1, math.max(z1, hz2), x2, z2 },
					{ x1, math.max(z1, hz1), math.min(x2, hx1), math.min(z2, hz2) }, { math.max(x1, hx2), math.max(z1, hz1), x2, math.min(z2, hz2) },
				}) do
					if r[3] - r[1] > 0.05 and r[4] - r[2] > 0.05 then
						B(r[1], ya, r[2], r[3], yb, r[4], "RoofShell", dark, MAT.Slate)
					end
				end
			end
			for i = 0, 9 do
				local ya, yb = HT + RRISE * i / 10, HT + RRISE * (i + 1) / 10 + 0.1
				local hPrev, h = RHW * (1 - i / 10), RHW * (1 - (i + 1) / 10)
				shell(-270, ya, RZC - hPrev, -160, yb, RZC - h + 4)
				shell(-270, ya, RZC + h - 4, -160, yb, RZC + hPrev)
				B(-270, ya, RZC - hPrev, -266, yb, RZC + hPrev, "RoofShell", dark, MAT.Slate)
				B(-164, ya, RZC - hPrev, -160, yb, RZC + hPrev, "RoofShell", dark, MAT.Slate)
			end
			-- THE OCULUS: the shaft's walls from under the roof to above the ridge, capped by a ring of stone round a great
			-- disc of old grey glass in iron tracery (the roof's panels stop short of it, so nothing hides it)
			do
				local W, R = OQ + 2, OQ - 1
				local y1, y2 = HT + 56, HT + RRISE + 8
				local SH = Color3.fromRGB(52, 48, 46)
				B(OCX - W, y1, OCZ - W, OCX + W, y2, OCZ - OQ, "OculusShaft", SH)
				B(OCX - W, y1, OCZ + OQ, OCX + W, y2, OCZ + W, "OculusShaft", SH)
				B(OCX - W, y1, OCZ - OQ, OCX - OQ, y2, OCZ + OQ, "OculusShaft", SH)
				B(OCX + OQ, y1, OCZ - OQ, OCX + W, y2, OCZ + OQ, "OculusShaft", SH)
				B(OCX - W - 0.8, y2 - 2.4, OCZ - W - 0.8, OCX + W + 0.8, y2 - 1.2, OCZ + W + 0.8, "Course", TRIM, MAT.Slate)
				for z = -W, W - 1 do -- the cap, in strips, a round hole through it
					local zm = z + 0.5
					if math.abs(zm) >= R then
						B(OCX - W, y2, OCZ + z, OCX + W, y2 + 1.5, OCZ + z + 1, "OculusCap", TRIM, MAT.Slate)
					else
						local xh = math.sqrt(R * R - zm * zm)
						B(OCX - W, y2, OCZ + z, OCX - xh, y2 + 1.5, OCZ + z + 1, "OculusCap", TRIM, MAT.Slate)
						B(OCX + xh, y2, OCZ + z, OCX + W, y2 + 1.5, OCZ + z + 1, "OculusCap", TRIM, MAT.Slate)
					end
				end
				local mid = at3(OCX, y2 + 0.75, OCZ)
				for k = 0, 31 do -- an iron rim over the strips' steps
					local a = k / 32 * math.pi * 2
					local p = mid + Vector3.new(math.cos(a), 0, math.sin(a)) * (R + 0.2)
					part({ Name = "OculusRim", Size = Vector3.new(1.4, 1.9, 2 * math.pi * R / 32 + 0.3), CFrame = CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0, math.cos(a))), Material = MAT.Metal, Color = COL.Iron, CanCollide = false })
					if k % 2 == 0 then -- and a ring of tracery halfway in
						local q = mid + Vector3.new(math.cos(a), 0, math.sin(a)) * R * 0.5
						part({ Name = "OculusTracery", Size = Vector3.new(0.4, 0.5, math.pi * R / 16 + 0.3), CFrame = CFrame.lookAt(q, q + Vector3.new(-math.sin(a), 0, math.cos(a))), Material = MAT.Metal, Color = COL.Iron, CanCollide = false })
					end
				end
				for k = 0, 3 do
					part({ Name = "OculusSpoke", Size = Vector3.new(0.45, 0.5, R * 2), CFrame = CFrame.new(mid) * CFrame.Angles(0, k * math.pi / 4, 0), Material = MAT.Metal, Color = COL.Iron, CanCollide = false })
				end
				part({ Name = "OculusHub", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.7, 2.6, 2.6), CFrame = CFrame.new(mid) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Metal, Color = COL.Iron, CanCollide = false })
				part({ Name = "OculusGlass", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.25, R * 2 + 0.6, R * 2 + 0.6), CFrame = CFrame.new(mid) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Glass, Color = Color3.fromRGB(118, 126, 134), Transparency = 0.6, CanCollide = false, CanQuery = false })
				for _, c in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
					spire(OCX + c[1] * (W - 1), OCZ + c[2] * (W - 1), 1.2, 1.2, y2 + 1.5, 9, 4)
				end
				-- the moon down through it: a pale shaft of light to the arena floor
				part({ Name = "MoonShaft", Shape = Enum.PartType.Cylinder, Size = Vector3.new(y2 - AF, R * 2 - 2, R * 2 - 2), CFrame = CFrame.new(at3(OCX, (y2 + AF) / 2, OCZ)) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Neon, Color = Color3.fromRGB(170, 184, 210), Transparency = 0.97, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
				local moon = part({ Name = "MoonLight", Size = Vector3.new(0.5, 0.5, 0.5), CFrame = CFrame.new(at3(OCX, AF + 34, OCZ)), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
				local l = Instance.new("PointLight")
				l.Color, l.Range, l.Brightness = Color3.fromRGB(160, 178, 220), 48, 1
				l.Parent = moon
			end
			local function ceilingAt(dz) -- height (above the plateau) of the roof's underside, dz from the ridge
				for i = 0, 9 do
					if RHW * (1 - (i + 1) / 10) - 4 <= dz then
						return HT + RRISE * i / 10
					end
				end
				return HT + RRISE
			end
			slab(-4, G0, {}) -- (thick: the plateau's grass and its mounds stay under the floor; the terrain pass also clears the hall's footprint)
			local NAVE = { -233, -95, -197, -41 } -- the nave's well: open from the ground to the roof, a gallery round it
			local STAIR_W, STAIR_E = { -260, -254 }, { -176, -170 } -- (x spans; both climb toward +z from z -144)
			slab(FL - 2, FL, {
				NAVE,
				{ STAIR_W[1] - 1, -131, STAIR_W[2] + 1, -117.6 },
				{ STAIR_E[1] - 1, -131, STAIR_E[2] + 1, -117.6 },
			})
			stair(STAIR_W[1], STAIR_W[2], -144)
			stair(STAIR_E[1], STAIR_E[2], -144)
			-- the landing's stair to the attic: 22 steps from the arch's line, climbing west; the attic floor is open above its head
			-- (the hole: from the top step's edge, x -239.2, flush with the attic floor, east to where the steps are low enough
			-- that a head clears the slab under it with room to spare)
			slab(CEIL, AF, { { -239.2, -30.5, -226, -23.5 } })
			for i = 0, 21 do
				B(-215 - (i + 1) * 1.1, FL - 1, -30, -215 - i * 1.1, FL + i + 1, -24, "MansionStep", IN_FLOOR, MAT.Slate)
			end
			B(-239.2, AF, -31, -226, AF + 3, -30.4, "Parapet", IN_STONE)
			B(-239.2, AF, -23.6, -226, AF + 3, -23, "Parapet", IN_STONE)
			B(-226.6, AF, -30.4, -226, AF + 3, -23.6, "Parapet", IN_STONE) -- (across the low end: no dropping down the hole)

			-- the entrance tower is the vestibule: the great door at its front, steps down into the foyer
			B(-235, 0, -10, -231, 30, 14, "MansionTower", IN_STONE)
			B(-199, 0, -10, -195, 30, 14, "MansionTower", IN_STONE)
			B(-231, 0, 10, -222, 30, 14, "MansionTower", IN_STONE)
			B(-208, 0, 10, -199, 30, 14, "MansionTower", IN_STONE)
			B(-222, 26, 10, -208, 30, 14, "MansionTower", IN_STONE)
			B(-235, 30, -10, -195, 120, 14, "MansionTower")
			B(-231, 0, -10, -199, G0, 2, "MansionFloor", IN_FLOOR, MAT.Slate)
			B(-231, 0, 2, -199, 5.4, 14, "MansionFloor", IN_FLOOR, MAT.Slate)
			B(-229, 0, 14, -201, 5.4, 15.5, "Step", TRIM, MAT.Slate) -- (closes the gap between the outside steps and the door)
			for i = 1, 4 do
				B(-231, 0, 2 - i * 2.4, -199, 5.4 - i, 2 - (i - 1) * 2.4, "MansionStep", IN_FLOOR, MAT.Slate)
			end
			B(-222, -4, -14, -208, G0, -10, "MansionFloor", IN_FLOOR, MAT.Slate) -- the threshold through the hall's front wall
			-- the vestibule kept to the door's width all the way through (x -222..-208), so its sides hide the hall's front windows
			B(-231, 0, -10, -222, 30, 10, "MansionTower", IN_STONE)
			B(-208, 0, -10, -199, 30, 10, "MansionTower", IN_STONE)

			-- ground floor: the library's door is the only open one off the foyer
			wall(false, -242, -146, -14, 1, { { -24 } })
			wall(false, -188, -146, -14, 1, { { -24, 7, oneWay = true }, { -120 } })
			wall(true, -34, -241, -189, 1, { { -215, 7, oneWay = true } })
			wall(true, -102, -241, -189, 1, { { -215, 7, oneWay = true } })
			wall(true, -82, -266, -243, 1, { { -254 } })
			wall(true, -92, -187, -164, 1, { { -176 } })
			-- upper floor: the nave's gallery is entered only through the banquet gallery's one-way door
			wall(false, -242, -146, -14, 2, { { -124 }, { -60, 7, oneWay = true } })
			wall(false, -188, -146, -14, 2, { { -60, 7, oneWay = true }, { -120 } })
			wall(true, -34, -241, -189, 2, { { -215, 14 } })
			wall(true, -102, -241, -189, 2, {})
			wall(true, -82, -266, -243, 2, { { -254 } })
			wall(true, -92, -187, -164, 2, { { -176 } })

			-- a door that opens from one side only: from the other it will not budge (init.server swings it)
			local function oneWayDoor(alongX, c, centre, y0, side)
				local w = 7
				local leaf = Instance.new("Model")
				leaf.Name = "MansionDoor"
				leaf.Parent = map
				local mid = Vector3.new(alongX and centre or c, MY + y0 + DH / 2, alongX and c or centre)
				local size = alongX and Vector3.new(w - 0.2, DH, 0.7) or Vector3.new(0.7, DH, w - 0.2)
				local main = part({ Name = "Door", Size = size, CFrame = CFrame.new(mid), Material = MAT.WoodPlanks, Color = IN_WOOD, Parent = leaf })
				for _, dy in ipairs({ -3.5, 0, 3.5 }) do
					part({ Name = "DoorBand", Size = alongX and Vector3.new(w - 0.2, 0.4, 0.9) or Vector3.new(0.9, 0.4, w - 0.2), CFrame = main.CFrame * CFrame.new(0, dy, 0), Material = MAT.Metal, Color = COL.Iron, CanCollide = false, Parent = leaf })
				end
				leaf.PrimaryPart = main
				local function spot(s)
					local off = s * 2.5
					return part({ Name = "DoorPrompt", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(alongX and Vector3.new(centre, mid.Y - 3, c + off) or Vector3.new(c + off, mid.Y - 3, centre)), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
				end
				table.insert(info.MansionDoors, {
					Leaf = leaf,
					Hinge = alongX and Vector3.new(centre - w / 2, mid.Y, c) or Vector3.new(c, mid.Y, centre - w / 2),
					Sign = alongX and side or -side, -- (swings away from whoever opens it)
					Normal = (alongX and Vector3.zAxis or Vector3.xAxis) * side, -- points to the side it opens from
					Prompt = prompt(spot(side), "Open", "Door", 0.4, 7),
					Blocked = prompt(spot(-side), "Open", "Door", 0, 7),
				})
			end
			oneWayDoor(false, -188, -24, G0, 1) -- foyer <-> dining hall: opens from the dining hall (a shortcut home)
			oneWayDoor(true, -34, -215, G0, -1) -- foyer <-> nave: opens from the nave (a shortcut home)
			oneWayDoor(true, -102, -215, G0, -1) -- rear hall -> nave: opens from the rear hall (the way into the nave)
			oneWayDoor(false, -188, -60, FL, 1) -- banquet gallery -> nave gallery: opens from the banquet gallery (the way on)
			oneWayDoor(false, -242, -60, FL, 1) -- nave gallery -> reading gallery: opens from the gallery (a shortcut to the dormitory)

			-- the nave's gallery: a parapet round the well, open where the ladder will come down
			local LZ, LEN = -80, 26
			for _, r in ipairs({
				{ -233.6, -95, -233, -41 }, { -233, -95.6, -197, -95 }, { -233, -41, -197, -40.4 },
				{ -197, -95, -196.4, LZ - 3 }, { -197, LZ + 3, -196.4, -41 },
			}) do
				B(r[1], FL, r[2], r[3], FL + 3, r[4], "Parapet", IN_STONE)
			end
			local gap = B(-197.6, FL, LZ - 3, -196.4, FL + 6, LZ + 3, "LadderGap", IN_STONE)
			gap.Transparency, gap.CanQuery = 1, false
			-- columns under the gallery's edge on all four sides, each wholly under the walkway's floor (the well is
			-- x -233..-197, z -95..-41), a capital spreading under the slab so they're seen to carry it
			local function column(x, z)
				B(x - 1.3, G0, z - 1.3, x + 1.3, FL - 2, z + 1.3, "Column", TRIM, MAT.Slate)
				B(x - 1.7, G0, z - 1.7, x + 1.7, G0 + 1, z + 1.7, "Column", TRIM, MAT.Slate)
				B(x - 2, FL - 3.2, z - 2, x + 2, FL - 2, z + 2, "Column", TRIM, MAT.Slate)
			end
			for _, z in ipairs({ -90, -68, -46 }) do
				column(-234.4, z)
				column(-195.6, z)
			end
			for _, x in ipairs({ -224, -206 }) do
				column(x, -96.6)
				column(x, -39.4)
			end
			info.AtticStairDev = CFrame.lookAt(at3(-211, FL + 3.2, -27), at3(-230, FL + 3.2, -27)) -- (dev teleport: the attic stair's foot)

			-- THE LADDER: lying on the gallery, its foot at the parapet's gap. Kicked, it's stood up, heaved over the gap and
			-- dropped to the nave floor against the well's wall - a way up and down (init.server, as for the yard's)
			do
				local truss = Instance.new("TrussPart")
				truss.Name = "MansionLadder"
				truss.Size = Vector3.new(2, LEN, 2)
				truss.Anchored, truss.Transparency = true, 1
				truss.CanCollide, truss.CanQuery = false, false
				local down = CFrame.new(-198.2, MY + G0 + LEN / 2, LZ) * CFrame.Angles(0, math.pi / 2, 0)
				truss.CFrame = down
				truss.Parent = map
				local wood, dark = Color3.fromRGB(84, 62, 42), Color3.fromRGB(62, 46, 32)
				local function bit(size, offset, color)
					local p = part({ Name = "LadderWood", Size = size, CFrame = down * offset, Material = MAT.Wood, Color = color, CanCollide = false, CanQuery = false, CanTouch = false, Massless = true })
					p.Anchored = false
					local w = Instance.new("WeldConstraint")
					w.Part0, w.Part1 = truss, p
					w.Parent = p
				end
				for _, x in ipairs({ -0.8, 0.8 }) do
					bit(Vector3.new(0.28, LEN, 0.32), CFrame.new(x, 0, 0), wood)
				end
				local lr = Random.new(180)
				for y = -LEN / 2 + 0.6, LEN / 2 - 0.4, 1 do
					bit(Vector3.new(1.65, 0.16, 0.18), CFrame.new(0, y, 0) * CFrame.Angles(0, 0, lr:NextNumber(-0.04, 0.04)), dark)
				end
				truss.CFrame = CFrame.new(-193, MY + FL + 0.3, LZ + LEN / 2) * CFrame.Angles(math.pi / 2, 0, 0)
				local spot = part({ Name = "LadderPrompt", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(-194.5, MY + FL + 1.5, LZ + 1.5), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
				local function climbPrompt(pos)
					local p = part({ Name = "LadderClimbPrompt", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(pos), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
					local pp = prompt(p, "Climb", "Ladder", 0, 6)
					pp.Enabled = false
					return pp
				end
				info.MansionLadder = {
					Ladder = truss,
					Down = down,
					Block = gap,
					Prompt = prompt(spot, "Kick down", "Ladder", 0, 7),
					UpPrompt = climbPrompt(Vector3.new(-199.8, MY + G0 + 2.5, LZ)),
					DownPrompt = climbPrompt(Vector3.new(-195.5, MY + FL + 2, LZ)),
					Climb = {
						foot = Vector3.new(-199.8, MY + G0 + 3, LZ),
						top = Vector3.new(-199.8, MY + FL + 3.15, LZ),
						off = Vector3.new(-194, MY + FL + 3.15, LZ),
					},
				}
			end


			-- furniture and light -------------------------------------------------------
			local function prop(x1, y1, z1, x2, y2, z2, name, color)
				return B(x1, y1, z1, x2, y2, z2, name, color or IN_WOOD:Lerp(IN_STONE, rng:NextNumber() * 0.4), MAT.Wood)
			end
			local CARPET = Color3.fromRGB(70, 22, 22)
			local function carpet(x1, z1, x2, z2, y)
				B(x1, y, z1, x2, y + 0.08, z2, "Carpet", CARPET:Lerp(IN_FLOOR, rng:NextNumber() * 0.4), MAT.Fabric, false)
			end
			local function stools(list, y)
				for _, s in ipairs(list) do
					Detail.stool(at3(s[1], y, s[2]), s[3])
				end
			end
			local function barrels(list, y)
				for _, s in ipairs(list) do
					Detail.barrel(at3(s[1], y, s[2]), s[3] or false)
				end
			end

			-- ground floor
			carpet(-216, -33, -214, -14, G0) -- the foyer's runner
			Detail.chandelier(at3(-215, 17, -24), MY + 22.5)
			Detail.slumpedSkeleton(at3(-239.5, G0, -19), Vector3.new(1, 0, 0.3))
			Detail.bonePile(at3(-192, G0, -18), 3)
			barrels({ { -239, -30 }, { -237, -31.5 } }, G0)
			carpet(-216, -146, -214, -103, G0) -- the rear hall's runner
			Detail.chandelier(at3(-215, 17, -124), MY + 22.5)
			Detail.slumpedSkeleton(at3(-239.5, G0, -135), Vector3.new(1, 0, 0))
			for _, z in ipairs({ -132, -114 }) do -- statues' plinths down the rear hall
				B(-228, G0, z - 1.5, -225, G0 + 2, z + 1.5, "Plinth", TRIM, MAT.Slate)
				B(-205, G0, z - 1.5, -202, G0 + 2, z + 1.5, "Plinth", TRIM, MAT.Slate)
			end
			Detail.chandelier(at3(-215, 36, -68), MY + CEIL) -- over the nave's sigil
			Detail.chandelier(at3(-215, 36, -88), MY + CEIL)
			Detail.bonePile(at3(-228, G0, -92), 4)
			Detail.bonePile(at3(-202, G0, -44), 3)
			Detail.slumpedSkeleton(at3(-239.5, G0, -50), Vector3.new(1, 0, 0))
			prop(-181, G0, -84, -175, G0 + 3, -26, "BanquetTable") -- the dining hall's laid table
			prop(-185, G0, -84, -183, G0 + 1.6, -26, "Bench")
			prop(-173, G0, -84, -171, G0 + 1.6, -26, "Bench")
			Detail.chandelier(at3(-178, 17, -55), MY + 22.5)
			Detail.slumpedSkeleton(at3(-178, G0, -86), Vector3.new(0, 0, 1)) -- the head of the table
			carpet(-186, -30, -166, -28, G0)
			for z = -78, -38, 8 do -- the library's shelves
				prop(-266, G0, z, -264, G0 + 11, z + 5, "Bookshelf")
			end
			prop(-258, G0, -60, -252, G0 + 3, -52, "ReadingTable")
			stools({ { -256, -64 }, { -256, -49, true }, { -250, -56 } }, G0)
			Detail.chandelier(at3(-254, 17, -55), MY + 22.5)
			do -- the ledger on its lectern: why the house is dead
				local book = Detail.lectern(at3(-250, G0, -34), Vector3.new(1, 0, 0))
				local pp = prompt(book, "Examine", "Steward's Ledger", 0, 7)
				pp:SetAttribute("Title", "The Steward's Ledger")
				pp:SetAttribute("Text", table.concat({
					"The house was never meant to keep anyone in. The Master had the stairs to the dormitory walled with a door that opens only from the upper rooms, so the servants could never come down at night. Then the Master stopped coming down himself.",
					"",
					"The nave was sealed after the second winter. We carried the Master's chair in through the rear hall and shut the door behind us. It opens from the rear hall; nothing was meant to go the other way.",
					"",
					"The bonfire in the nave went out the winter it was sealed. Nobody has lit one inside since.",
					"",
					"What the Master kept on the landing, above the entrance, I never learned. The way there is through the banquet gallery, and the gallery door opens only from the banquet side. I stopped asking.",
				}, "\n"))
				table.insert(notes, pp)
			end
			prop(-262, G0, -140, -246, G0 + 3, -134, "ServantsTable") -- the servants' hall
			stools({ { -258, -131 }, { -250, -131 }, { -254, -143 } }, G0)
			barrels({ { -264, -90 }, { -262, -91.5 }, { -264, -94, true } }, G0)
			Detail.bonePile(at3(-250, G0, -100), 3)
			Detail.chandelier(at3(-254, 17, -100), MY + 22.5)
			prop(-186, G0, -144, -176, G0 + 3.2, -138, "KitchenTable") -- the kitchens
			prop(-168, G0, -90, -164, G0 + 9, -94, "Hearth")
			barrels({ { -184, -108 }, { -184, -111 }, { -166, -140 }, { -168, -142, true } }, G0)
			stools({ { -180, -132 }, { -175, -128, true } }, G0)
			Detail.chandelier(at3(-182, 15, -108), MY + 22.5) -- (clear of the kitchens' stair)
			-- upper floor
			for z = -142, -96, 9 do -- the dormitory's beds
				prop(-266, FL, z, -262, FL + 1.6, z + 6, "Bed")
			end
			Detail.slumpedSkeleton(at3(-246, FL, -110), Vector3.new(-1, 0, 0))
			for z = -78, -30, 8 do -- the reading gallery's shelves
				prop(-266, FL, z, -264, FL + 11, z + 5, "Bookshelf")
			end
			prop(-258, FL, -52, -252, FL + 3, -44, "ReadingTable")
			carpet(-216, -146, -214, -103, FL)
			Detail.chandelier(at3(-215, FL + 13, -124), MY + CEIL)
			barrels({ { -184, -142 }, { -184, -139 }, { -166, -96 } }, FL)
			Detail.bonePile(at3(-184, FL, -130), 3)
			prop(-181, FL, -84, -175, FL + 3, -30, "BanquetTable") -- the banquet gallery's table, laid for guests
			prop(-185, FL, -84, -183, FL + 1.6, -30, "Bench")
			prop(-173, FL, -84, -171, FL + 1.6, -30, "Bench")
			Detail.slumpedSkeleton(at3(-178, FL, -86), Vector3.new(0, 0, 1))
			Detail.chandelier(at3(-178, FL + 13, -55), MY + CEIL)
			Detail.chandelier(at3(-200, FL + 13, -22), MY + CEIL)
			B(-218, FL, -22, -212, FL + 3, -16, "Pedestal", TRIM, MAT.Slate) -- the landing's altar, and what lies on it

			-- BLOODBORNE: gas lamps up the avenue, lanterns and a rose window on the great door, stained glass (the lancets),
			-- chequered marble, crimson drapes, candelabras, coffins, blood, a sigil in the nave, fog
			local function glow(part_, color, range, brightness, flicker)
				local l = Instance.new("PointLight")
				l.Color, l.Range, l.Brightness = color, range, brightness
				l.Parent = part_
				if flicker then
					addFlicker(l)
				end
			end
			local GAS = Color3.fromRGB(255, 176, 100)
			local function gasLamp(x, z)
				B(x - 0.7, 0, z - 0.7, x + 0.7, 1.4, z + 0.7, "GasLampBase", COL.Iron, MAT.Metal)
				B(x - 0.25, 0, z - 0.25, x + 0.25, 15, z + 0.25, "GasLampPost", COL.Iron, MAT.Metal)
				B(x - 1.3, 15, z - 1.3, x + 1.3, 15.5, z + 1.3, "GasLampCage", COL.Iron, MAT.Metal, false)
				local lantern = B(x - 0.9, 15.5, z - 0.9, x + 0.9, 17.3, z + 0.9, "GasLampLantern", GAS, MAT.Neon, false)
				B(x - 1.3, 17.3, z - 1.3, x + 1.3, 17.9, z + 1.3, "GasLampCap", COL.Iron, MAT.Metal, false)
				glow(lantern, GAS, 46, 2.2, true)
			end
			for _, z in ipairs({ 36, 52, 68 }) do
				gasLamp(-228, z)
				gasLamp(-202, z)
			end
			for _, x in ipairs({ -231, -199 }) do -- on the plinths either side of the steps
				local l = B(x - 0.6, 7, 17.4, x + 0.6, 8.4, 18.6, "DoorLantern", GAS, MAT.Neon, false)
				glow(l, GAS, 30, 1.8, true)
			end
			do -- a rose window over the great door: crimson glass in an iron wheel
				local face = CFrame.new(-215, MY + 44.5, 14.7) * CFrame.Angles(0, math.pi / 2, 0)
				local function ring(name, r, thick, dz, color, mat, tr)
					return part({ Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(thick, r * 2, r * 2), CFrame = face * CFrame.new(0, 0, dz), Material = mat, Color = color, Transparency = tr or 0, CanCollide = false })
				end
				ring("RoseRim", 5.2, 0.5, 0, COL.Iron, MAT.Metal)
				local pane = ring("RoseGlass", 4.8, 0.4, -0.2, Color3.fromRGB(84, 46, 50), MAT.Glass, 0.1)
				for k = 0, 3 do
					part({ Name = "RoseSpoke", Size = Vector3.new(0.4, 9.6, 0.4), CFrame = CFrame.new(-215, MY + 44.5, 15) * CFrame.Angles(0, 0, k * math.pi / 4), Material = MAT.Metal, Color = COL.Iron, CanCollide = false })
				end
				ring("RoseHub", 1.1, 0.7, -0.4, COL.Iron, MAT.Metal)
				glow(pane, Color3.fromRGB(190, 110, 100), 28, 0.6, false)
			end
			-- chequered marble on the grand floors
			local function checker(x1, z1, x2, z2, y, cell)
				local nx, nz = math.floor((x2 - x1) / cell), math.floor((z2 - z1) / cell)
				for i = 0, nx - 1 do
					for j = 0, nz - 1 do
						if (i + j) % 2 == 0 then
							B(x1 + i * cell, y, z1 + j * cell, x1 + (i + 1) * cell, y + 0.05, z1 + (j + 1) * cell, "Marble", Color3.fromRGB(78, 72, 74), MAT.Marble, false)
						end
					end
				end
			end
			checker(-241, -34, -189, -14, G0, 4)
			checker(-241, -101, -189, -35, G0, 4)
			checker(-241, -145, -189, -103, G0, 4)
			-- crimson drapes down the long walls, between the windows
			local function drape(x, y1, z, depth, along, len)
				if along then
					B(x, y1, z, x + depth, y1 + 14, z + len, "Drape", Color3.fromRGB(96, 18, 24):Lerp(IN_STONE, rng:NextNumber() * 0.3), MAT.Fabric, false)
				else
					B(x, y1, z, x + len, y1 + 14, z + depth, "Drape", Color3.fromRGB(96, 18, 24):Lerp(IN_STONE, rng:NextNumber() * 0.3), MAT.Fabric, false)
				end
			end
			for z = -96, -40, 12 do
				drape(-241, G0 + 6, z, 0.4, true, 3.2)
				drape(-189.4, G0 + 6, z, 0.4, true, 3.2)
				drape(-241, FL + 6, z, 0.4, true, 3.2)
				drape(-189.4, FL + 6, z, 0.4, true, 3.2)
			end
			for z = -140, -110, 10 do
				drape(-241, G0 + 6, z, 0.4, true, 3.2)
				drape(-189.4, G0 + 6, z, 0.4, true, 3.2)
			end
			for z = -84, -28, 14 do
				drape(-164.4, G0 + 6, z, 0.4, true, 3.2)
				drape(-164.4, FL + 6, z, 0.4, true, 3.2)
			end
			-- candelabras: an iron stem, three candles, their flames
			local function candelabra(x, y, z)
				B(x - 0.2, y, z - 0.2, x + 0.2, y + 3.4, z + 0.2, "Candelabra", COL.Iron, MAT.Metal, false)
				B(x - 0.7, y, z - 0.7, x + 0.7, y + 0.3, z + 0.7, "Candelabra", COL.Iron, MAT.Metal, false)
				B(x - 1.1, y + 3.3, z - 0.15, x + 1.1, y + 3.5, z + 0.15, "Candelabra", COL.Iron, MAT.Metal, false)
				for d = -1, 1 do
					B(x + d * 0.9 - 0.15, y + 3.5, z - 0.15, x + d * 0.9 + 0.15, y + 4.4, z + 0.15, "Candle", Color3.fromRGB(210, 200, 170), MAT.SmoothPlastic, false)
					B(x + d * 0.9 - 0.1, y + 4.4, z - 0.1, x + d * 0.9 + 0.1, y + 4.75, z + 0.1, "CandleFlame", Color3.fromRGB(255, 170, 80), MAT.Neon, false)
				end
			end
			for _, c in ipairs({
				{ -238, -30 }, { -192, -30 }, { -262, -22 }, { -262, -76 }, { -168, -22 }, { -168, -80 }, { -238, -108 }, { -192, -108 },
				{ -238, -142 }, { -192, -142 }, { -228, -50 }, { -202, -84 }, { -262, -86 }, { -184, -96 },
			}) do
				candelabra(c[1], G0, c[2])
			end
			for _, c in ipairs({ { -262, -86 }, { -262, -22 }, { -168, -22 }, { -168, -80 }, { -236, -20 }, { -192, -20 } }) do
				candelabra(c[1], FL, c[2])
			end
			-- coffins along the rear hall's walls (a house that buried its own)
			for _, z in ipairs({ -122, -112 }) do
				B(-240, G0, z - 3.2, -237.6, G0 + 1.8, z + 3.2, "Coffin", Color3.fromRGB(34, 24, 20), MAT.Wood)
				B(-239.8, G0 + 1.8, z - 3, -237.8, G0 + 2.1, z + 3, "CoffinLid", Color3.fromRGB(44, 32, 26), MAT.Wood, false)
				B(-190.4, G0, z - 3.2, -188.2, G0 + 1.8, z + 3.2, "Coffin", Color3.fromRGB(34, 24, 20), MAT.Wood)
				B(-190.2, G0 + 1.8, z - 3, -188.4, G0 + 2.1, z + 3, "CoffinLid", Color3.fromRGB(44, 32, 26), MAT.Wood, false)
			end
			-- the rot's ichor, dried dark green on the stone (no blood in the house: a colour blood never is)
			local POOLS = {
				{ -241, -34, -189, -14, G0 }, { -241, -101, -189, -35, G0 }, { -241, -145, -189, -103, G0 }, { -265, -81, -243, -15, G0 },
				{ -265, -145, -243, -84, G0 }, { -187, -91, -165, -15, G0 }, { -187, -145, -165, -94, G0 },
				{ -265, -145, -243, -84, FL }, { -265, -81, -243, -15, FL }, { -241, -145, -189, -103, FL }, { -187, -91, -165, -15, FL },
			}
			for _ = 1, 34 do
				local r = POOLS[rng:NextInteger(1, #POOLS)]
				local x, z, rad = rng:NextNumber(r[1] + 3, r[3] - 3), rng:NextNumber(r[2] + 3, r[4] - 3), rng:NextNumber(0.8, 2.6)
				part({ Name = "Ichor", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.06, rad * 2, rad * 2 * rng:NextNumber(0.6, 1)), CFrame = CFrame.new(x, MY + r[5] + 0.07, z) * CFrame.Angles(0, rng:NextNumber(0, 6), math.pi / 2), Material = MAT.SmoothPlastic, Color = Color3.fromRGB(38, 56, 30):Lerp(Color3.fromRGB(16, 24, 12), rng:NextNumber()), Reflectance = 0.15, CanCollide = false })
			end
			Detail.ritualCircle(at3(-215, G0, -66), 9) -- in the nave, where its bonfire burned
			local function fogBank(x1, z1, x2, z2, y, h, rate)
				local p = part({ Name = "MansionFog", Size = Vector3.new(x2 - x1, h, z2 - z1), CFrame = CFrame.new((x1 + x2) / 2, MY + y, (z1 + z2) / 2), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
				local pe = Instance.new("ParticleEmitter")
				pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
				pe.Rate = rate
				pe.Lifetime = NumberRange.new(8, 12)
				pe.Speed = NumberRange.new(0.2, 0.6)
				pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 8), NumberSequenceKeypoint.new(1, 14) })
				pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.86), NumberSequenceKeypoint.new(0.7, 0.88), NumberSequenceKeypoint.new(1, 1) })
				pe.Color = ColorSequence.new(Color3.fromRGB(120, 100, 104))
				pe.LightInfluence = 1
				pe.RotSpeed = NumberRange.new(-4, 4)
				pe.Rotation = NumberRange.new(0, 360)
				pcall(function()
					pe.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
				end)
				pe.Parent = p
			end
			fogBank(-240, -100, -190, -36, G0 + 2, 3, 10) -- the nave
			fogBank(-240, -144, -190, -104, G0 + 2, 3, 8) -- the rear hall


			-- flasks, left where they were put down (init.server: one more draught each)
			local function flask(key, x, y, z)
				local up = CFrame.Angles(0, 0, math.pi / 2)
				local function cyl(name, w, d, offset, color, mat)
					return part({ Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(w, d, d), CFrame = CFrame.new(x, MY + y, z) * offset * up, Material = mat, Color = color, CanCollide = false })
				end
				local parts = {
					cyl("FlaskBody", 0.9, 0.8, CFrame.new(0, 0.45, 0), Color3.fromRGB(255, 150, 60), MAT.Glass),
					cyl("FlaskNeck", 0.4, 0.3, CFrame.new(0, 1.1, 0), Color3.fromRGB(255, 170, 90), MAT.Glass),
					cyl("FlaskCork", 0.2, 0.32, CFrame.new(0, 1.4, 0), Color3.fromRGB(120, 90, 60), MAT.Wood),
				}
				local glow = part({ Name = "PickupGlow", Size = Vector3.new(0.4, 0.4, 0.4), CFrame = CFrame.new(x, MY + y + 0.8, z), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
				table.insert(parts, glow)
				local l = Instance.new("PointLight")
				l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 220, 150), 9, 1.2
				l.Parent = glow
				info.Pickups = info.Pickups or {}
				info.Pickups[key] = { Prompt = prompt(glow, "Take", "Spare Flask", 0.3, 7), Parts = parts, Glow = glow }
			end
			flask("MansionFlaskA", -256, FL + 3.2, -48) -- on the reading gallery's table
			flask("MansionFlaskB", -215, FL + 3.1, -19) -- on the landing's altar

			-- soapstone messages, where the level asks something of you
			message(at3(-193, G0, -29), "Barred. It must open from the other side.")
			message(at3(-208, G0, -31), "The nave is sealed. Look for another way in.")
			message(at3(-250, G0, -90), "Stairs ahead. Try going up.")
			message(at3(-184, G0, -30), "This door opens from here. A shortcut to the foyer.")
			message(at3(-210, G0, -106), "The nave beyond this door. A shortcut to the foyer.")
			message(at3(-184, FL, -64), "Door opens from here. The nave's gallery lies beyond. Kick the ladder down.")
			message(at3(-215, FL, -27), "A flask, left for whoever made it this far.")
			message(at3(-194, G0, -80), "Ladder ahead. A way back up.")
			message(at3(-238, FL, -64), "This door opens from here. A shortcut to the dormitory.")
			for _, l in ipairs({
				{ -239, 12, -24 }, { -191, 12, -24 }, { -239, 12, -125 }, { -191, 12, -125 },
				{ -264, 12, -48 }, { -264, 12, -110 }, { -166, 12, -50 }, { -166, 12, -118 }, { -221.5, 10, 0 }, { -208.5, 10, 0 },
				{ -239, 36.5, -24 }, { -239, 36.5, -80 }, { -191, 36.5, -80 }, { -239, 36.5, -125 }, { -191, 36.5, -125 },
				{ -264, 36.5, -50 }, { -264, 36.5, -110 }, { -166, 36.5, -50 }, { -166, 36.5, -118 },
			}) do
				lamp(l[1], l[2], l[3])
			end

			-- the dead who keep it: decayed soldiers (Characters/Errant) and dark mages (Characters/Mage), thicker the further on
			local function spawn(kind, x, z, lx, lz, fy)
				local y = MY + (fy or G0) + 3.2
				table.insert(info.MansionSpawns, { Type = kind, CFrame = CFrame.lookAt(Vector3.new(x, y, z), Vector3.new(lx, y, lz)) })
			end
			spawn("Errant", -200, -22, -215, -10) -- foyer: one, by the door
			spawn("Mage", -254, -44, -230, -44) -- library
			spawn("Errant", -254, -110, -254, -90, FL) -- dormitory
			spawn("Errant", -222, -128, -215, -105, FL) -- rear gallery
			spawn("Errant", -184, -126, -176, -100, FL) -- upper kitchens
			spawn("Errant", -169, -60, -200, -60, FL) -- banquet gallery
			spawn("Mage", -215, -98, -215, -60, FL) -- the nave's gallery
			-- (none on the landing: it's the Consul's antechamber, and its arch is warded against the dead, below)
			part({ Name = "EnemyWard", Size = Vector3.new(14, CEIL - FL, 2), CFrame = CFrame.new(-215, MY + (FL + CEIL) / 2, -34), Transparency = 1, CanQuery = false, CanTouch = false, CollisionGroup = "EnemyWard" })
			spawn("Errant", -183, -130, -176, -100) -- kitchens
			spawn("Errant", -169, -55, -200, -55) -- dining hall
			spawn("Errant", -208, -126, -215, -105) -- rear hall: the nave's guards
			spawn("Mage", -215, -140, -215, -110)
			spawn("Errant", -230, -78, -215, -66) -- the nave

			-- THE ATTIC: the whole top of the hall as one grand arena, open up under the ridge (a hundred studs of air above the
			-- floor): a rose-and-slate ring on the floor, a dais at its heart, twelve tall columns joined by a ring of vaulting,
			-- chandeliers on long chains, banks of candles, moonlit windows and rose windows in both gables, and a clock
			-- the size of a house front; a red runner from the stair to the dais. (Nothing lives in it yet.)
			do
				local cx, cz = -215, -80
				local RED, SLATEF = Color3.fromRGB(70, 20, 22), Color3.fromRGB(36, 34, 36)
				local gold = Color3.fromRGB(176, 140, 60)
				local function disc(name, r, thick, y, color, mat, solid)
					return part({ Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(thick, r * 2, r * 2), CFrame = CFrame.new(cx, MY + y, cz) * CFrame.Angles(0, 0, math.pi / 2), Material = mat or MAT.Slate, Color = color, CanCollide = solid or false })
				end
				disc("ArenaRing", 46, 0.08, AF + 0.05, RED, MAT.Fabric)
				disc("ArenaFloor", 41, 0.08, AF + 0.1, SLATEF, MAT.Slate)
				disc("ArenaInlay", 24, 0.08, AF + 0.14, RED, MAT.Fabric)
				disc("ArenaInlay", 22, 0.08, AF + 0.18, SLATEF, MAT.Slate)
				disc("DaisStep", 17, 0.6, AF + 0.3, TRIM, MAT.Slate, true)
				disc("Dais", 14, 1.2, AF + 0.6, Color3.fromRGB(44, 42, 46), MAT.Slate, true)
				disc("DaisRim", 14.3, 0.3, AF + 1.3, gold, MAT.Metal)
				B(-226, AF + 0.2, -29, -214, AF + 0.26, -25, "Runner", RED, MAT.Fabric, false) -- (from the stair's head, not over it)
				B(-217, AF + 0.2, -64, -213, AF + 0.26, -25, "Runner", RED, MAT.Fabric, false)
				-- THE CONSUL OF DECAY's (Characters/Consul): his dais, the attic's floor, and the fog laid flat over the
				-- stair's head while he's awake (flush with the floor: walked over from above, a ceiling from below)
				local seal = part({ Name = "ConsulFog", Size = Vector3.new(13.2, 1, 7), CFrame = CFrame.new(-232.6, MY + AF - 0.5, -27), Material = MAT.ForceField, Color = COL.Fog, Transparency = 1, CanCollide = false, CanQuery = false })
				info.Consul = {
					Dais = Vector3.new(cx, MY + AF + 1.2, cz), -- (its top)
					Floor = MY + AF,
					Bounds = { -266, -146, -164, -14 }, -- x1, z1, x2, z2: the attic
					Hole = { -239.2, -30.5, -226, -23.5 }, -- the stair's head
					Seal = seal,
				}
				-- twelve columns on a ring, a ring of vaulting joining their capitals
				local COLH = 50
				local tops = {}
				for k = 0, 11 do
					local a = k / 12 * math.pi * 2
					local x, z = cx + math.cos(a) * 34, cz + math.sin(a) * 34
					B(x - 2.4, AF, z - 2.4, x + 2.4, AF + 2, z + 2.4, "AtticColumn", TRIM, MAT.Slate)
					B(x - 1.5, AF, z - 1.5, x + 1.5, AF + COLH, z + 1.5, "AtticColumn", TRIM, MAT.Slate)
					B(x - 2.4, AF + COLH - 2.5, z - 2.4, x + 2.4, AF + COLH, z + 2.4, "AtticColumn", TRIM, MAT.Slate)
					tops[k] = Vector3.new(x, MY + AF + COLH + 1, z)
					local l = part({ Name = "ColumnLight", Size = Vector3.new(0.5, 0.5, 0.5), CFrame = CFrame.new(cx + math.cos(a) * 31.5, MY + AF + 9, cz + math.sin(a) * 31.5), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
					glow(l, Color3.fromRGB(255, 160, 90), 34, 0.4, true) -- (dim: the first phase is lit by his head)
				end
				for k = 0, 11 do
					local a, b = tops[k], tops[(k + 1) % 12]
					part({ Name = "Vault", Size = Vector3.new(1.6, 1.6, (b - a).Magnitude), CFrame = CFrame.lookAt((a + b) / 2, b), Material = MAT.Slate, Color = TRIM, CanCollide = false })
				end
				-- chandeliers on chains up to the roof's underside, four round the dais (its middle is open to the oculus)
				for _, o in ipairs({ { 22, 0 }, { -22, 0 }, { 0, 22 }, { 0, -22 } }) do
					Detail.chandelier(Vector3.new(cx + o[1], MY + AF + 40, cz + o[2]), MY + ceilingAt(math.abs(o[2])) + 1, 0.2)
				end
				-- the floor lit by what hangs and stands in it (the chandeliers are far overhead)
				for _, o in ipairs({ { 24, 0 }, { -24, 0 }, { 0, 24 }, { 0, -24 } }) do
					local p = part({ Name = "ArenaLight", Size = Vector3.new(0.5, 0.5, 0.5), CFrame = CFrame.new(cx + o[1], MY + AF + 26, cz + o[2]), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
					glow(p, Color3.fromRGB(255, 170, 110), 60, 0.3, false) -- (none in the middle)
				end
				-- candles in banks on the floor
				for k = 0, 23 do
					local a = (k + 0.5) / 24 * math.pi * 2
					local x, z = cx + math.cos(a) * 29, cz + math.sin(a) * 29
					for d = -1, 1 do
						local h = 1.2 + rng:NextNumber() * 1.2
						B(x + d * 0.7 - 0.2, AF, z - 0.2, x + d * 0.7 + 0.2, AF + h, z + 0.2, "Candle", Color3.fromRGB(210, 200, 170), MAT.SmoothPlastic, false)
						B(x + d * 0.7 - 0.1, AF + h, z - 0.1, x + d * 0.7 + 0.1, AF + h + 0.3, z + 0.1, "CandleFlame", Color3.fromRGB(255, 170, 80), MAT.Neon, false)
					end
				end
				-- moonlit windows, glowing pale on the long walls (the glass outside is dark), banners between them
				local pale = Color3.fromRGB(150, 180, 235)
				for _, wx in ipairs({ { -266, 1 }, { -164, -1 } }) do
					for _, z in ipairs({ -130, -105, -80, -55, -30 }) do
						B(wx[1], AF + 4, z - 1.6, wx[1] + wx[2] * 0.2, AF + 20, z + 1.6, "MoonWindow", Color3.fromRGB(84, 92, 104), MAT.Glass, false).Transparency = 0.2
						local p = part({ Name = "MoonLight", Size = Vector3.new(0.5, 0.5, 0.5), CFrame = CFrame.new(wx[1] + wx[2] * 4, MY + AF + 12, z), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
						glow(p, pale, 24, 0.25, false)
					end
					for _, z in ipairs({ -117.5, -92.5, -67.5, -42.5 }) do
						B(wx[1] + wx[2] * 0.15, AF + 6, z - 1.2, wx[1] + wx[2] * 0.45, AF + 22, z + 1.2, "Banner", Color3.fromRGB(110, 22, 24), MAT.Fabric, false)
					end
					-- the gable's rose window, high in the wall facing the dais
					local rose = CFrame.new(wx[1] + wx[2] * 0.4, MY + AF + 56, cz)
					local function rpart(name, r, thick, dx, color, mat, tr)
						return part({ Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(thick, r * 2, r * 2), CFrame = rose * CFrame.new(dx * wx[2], 0, 0), Material = mat, Color = color, Transparency = tr or 0, CanCollide = false })
					end
					rpart("RoseRim", 13.5, 0.5, 0, COL.Iron, MAT.Metal)
					local pane = rpart("RoseGlass", 12.5, 0.4, 0.2, Color3.fromRGB(78, 52, 62), MAT.Glass, 0.15)
					for k = 0, 3 do
						part({ Name = "RoseSpoke", Size = Vector3.new(0.5, 25, 0.5), CFrame = rose * CFrame.new(wx[2] * 0.3, 0, 0) * CFrame.Angles(k * math.pi / 4, 0, 0), Material = MAT.Metal, Color = COL.Iron, CanCollide = false })
					end
					rpart("RoseHub", 2.2, 0.8, 0.5, COL.Iron, MAT.Metal)
					glow(pane, Color3.fromRGB(170, 120, 150), 50, 0.3, false)
				end
				-- the round window on the north wall, low enough (top at AF + 23.5, the roof's overhang starts at HT) that none of
				-- it is hidden: old grey-violet glass in iron tracery, the chapel's stone behind it, a dim light through it
				local RW, WY = 11, AF + 12.5
				local function wpart(name, size, cf, color, mat)
					return part({ Name = name, Size = size, CFrame = cf, Material = mat, Color = color, CanCollide = false })
				end
				local function wdisc(name, r, thick, z, color, mat)
					return part({ Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(thick, r * 2, r * 2), CFrame = CFrame.new(cx, MY + WY, z) * CFrame.Angles(0, math.pi / 2, 0), Material = mat, Color = color, CanCollide = false })
				end
				wdisc("RoundWindowRim", RW + 0.7, 0.5, -145.75, COL.Iron, MAT.Metal)
				local pane = wdisc("RoundWindowGlass", RW, 0.3, -145.4, Color3.fromRGB(72, 64, 76), MAT.Glass)
				pane.Transparency = 0.1
				for k = 0, 3 do
					wpart("RoundWindowSpoke", Vector3.new(0.5, RW * 2, 0.4), CFrame.new(cx, MY + WY, -145.1) * CFrame.Angles(0, 0, k * math.pi / 4), COL.Iron, MAT.Metal)
				end
				for k = 0, 15 do
					local a = k / 16 * math.pi * 2
					wpart("RoundWindowTracery", Vector3.new(math.pi * RW / 16 + 0.2, 0.45, 0.4), CFrame.new(cx + math.cos(a) * RW * 0.5, MY + WY + math.sin(a) * RW * 0.5, -145.1) * CFrame.Angles(0, 0, a + math.pi / 2), COL.Iron, MAT.Metal)
				end
				wdisc("RoundWindowHub", 1.3, 0.6, -145, COL.Iron, MAT.Metal)
				glow(pane, Color3.fromRGB(170, 160, 190), 40, 0.6, false)
				fogBank(cx - 44, cz - 60, cx + 44, cz + 52, AF + 3, 5, 24) -- low fog across the arena floor
			end

			-- FURNISHED, AND LEFT TO ROT: what the house was (sheeted chairs, portraits gone dark, wardrobes, hearths, hooded
			-- statues, pews, cages over the nave, empty hooks in the kitchens, the last meal still laid) and what the years did
			-- to it (paper peeling off the damp, bare brick, cracks, fallen plaster, a film of dust over everything, cobwebs,
			-- dust and haze hanging in the air). Solid pieces stand against walls, clear of every door and stair.
			do
				local dr = Random.new(8803) -- (its own stream: nothing else shifts)
				local GILT, CANVAS, VELVET, SHEET = Color3.fromRGB(104, 84, 50), Color3.fromRGB(30, 25, 22), Color3.fromRGB(66, 24, 26), Color3.fromRGB(132, 126, 116)
				local DUST, PLASTER, DARKWOOD, BONE = Color3.fromRGB(116, 110, 100), Color3.fromRGB(104, 98, 88), Color3.fromRGB(40, 30, 24), Color3.fromRGB(170, 162, 140)
				local function P(cf, name, size, color, mat, solid, tr)
					return part({ Name = name, Size = size, CFrame = cf, Color = color, Material = mat, CanCollide = solid == true, CanQuery = solid == true, Transparency = tr or 0 })
				end
				local function disc(cf, name, d, thick, color, mat) -- a cylinder standing up (its flat faces up/down)
					return part({ Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(thick, d, d), CFrame = cf * CFrame.Angles(0, 0, math.pi / 2), Material = mat, Color = color, CanCollide = false, CanQuery = false })
				end
				-- a wall's face at floor height y, looking into the room: x along the wall, y up, -z out of it
				local function wallCF(px, y, pz, nx, nz)
					return CFrame.lookAt(at3(px, y, pz), at3(px + nx, y, pz + nz))
				end
				local function out(cf, x, y, d)
					return cf * CFrame.new(x, y, -d)
				end
				local function floorCF(x, y, z, yaw) -- facing -z, turned by yaw
					return CFrame.new(at3(x, y, z)) * CFrame.Angles(0, yaw or 0, 0)
				end

				-- the pieces -------------------------------------------------------------
				local function portrait(cf, y, w, h, tilt, slashed)
					local c = out(cf, 0, y + h / 2, 0.25) * CFrame.Angles(0, 0, tilt or 0)
					P(c, "PortraitFrame", Vector3.new(w + 1.2, h + 1.2, 0.5), GILT:Lerp(SOOT, dr:NextNumber(0.3, 0.7)), MAT.Wood)
					P(c * CFrame.new(0, 0, -0.27), "Portrait", Vector3.new(w, h, 0.06), CANVAS:Lerp(Color3.fromRGB(58, 44, 36), dr:NextNumber()), MAT.Fabric)
					-- the sitter, barely: dark shoulders, a face gone brown under the varnish
					P(c * CFrame.new(0, -h * 0.26, -0.31), "PortraitSitter", Vector3.new(w * 0.7, h * 0.4, 0.04), Color3.fromRGB(20, 17, 17), MAT.Fabric)
					P(c * CFrame.new(0, h * 0.1, -0.31), "PortraitSitter", Vector3.new(w * 0.26, h * 0.24, 0.04), Color3.fromRGB(92, 76, 62):Lerp(CANVAS, dr:NextNumber(0.2, 0.6)), MAT.Fabric)
					if slashed then
						for _, a in ipairs({ 0.85, 1.1 }) do
							P(c * CFrame.new(dr:NextNumber(-0.5, 0.5), 0, -0.34) * CFrame.Angles(0, 0, a), "PortraitSlash", Vector3.new(0.2, math.min(w, h) * 0.9, 0.04), VOID, MAT.Slate)
						end
					end
				end
				local function wardrobe(cf, ajar)
					local c = out(cf, 0, 0, 1.25)
					P(c * CFrame.new(0, 4.6, 0), "Wardrobe", Vector3.new(4.6, 9.2, 2.5), DARKWOOD, MAT.Wood, true)
					P(c * CFrame.new(0, 9.45, 0), "WardrobeCrown", Vector3.new(5.2, 0.5, 2.9), DARKWOOD:Lerp(SOOT, 0.4), MAT.Wood)
					if ajar then
						P(c * CFrame.new(1.1, 4.8, -1.27), "WardrobeDark", Vector3.new(2.1, 8, 0.05), VOID, MAT.Slate)
					end
					for _, s in ipairs({ -1, 1 }) do
						local door = c * CFrame.new(s * 1.15, 4.8, -1.32)
						if ajar and s == 1 then -- hanging open on its hinge
							door = c * CFrame.new(2.3, 4.8, -1.32) * CFrame.Angles(0, -0.9, 0) * CFrame.new(-1.1, 0, 0)
						end
						P(door, "WardrobeDoor", Vector3.new(2.2, 8.2, 0.15), DARKWOOD:Lerp(IN_WOOD, 0.35), MAT.WoodPlanks)
					end
				end
				local function armchair(cf, sheeted)
					local fab = VELVET:Lerp(SOOT, dr:NextNumber(0.1, 0.5))
					P(cf * CFrame.new(0, 0.8, 0), "Armchair", Vector3.new(2.8, 1.6, 2.6), fab, MAT.Fabric, true)
					P(cf * CFrame.new(0, 2.7, 1.05), "ArmchairBack", Vector3.new(2.8, 3.8, 0.6), fab, MAT.Fabric)
					for _, s in ipairs({ -1, 1 }) do
						P(cf * CFrame.new(s * 1.25, 1.95, 0.1), "ArmchairArm", Vector3.new(0.5, 0.8, 2.4), fab, MAT.Fabric)
					end
					if sheeted then -- under a dust sheet, slumped over its shape
						local col = SHEET:Lerp(DUST, dr:NextNumber())
						P(cf * CFrame.new(0, 1.3, 0), "DustSheet", Vector3.new(3.3, 2.7, 3.1), col, MAT.Fabric)
						P(cf * CFrame.new(0, 3, 1.05), "DustSheet", Vector3.new(3.1, 3.9, 0.9), col, MAT.Fabric)
						P(cf * CFrame.new(0, 0.6, -1.6) * CFrame.Angles(0.2, 0, 0), "DustSheet", Vector3.new(3.4, 1.3, 0.08), col:Lerp(SOOT, 0.2), MAT.Fabric)
					end
				end
				local function fireplace(cf)
					for _, s in ipairs({ -1, 1 }) do
						P(out(cf, s * 3.6, 3, 0.8), "Hearth", Vector3.new(1.4, 6, 1.6), TRIM, MAT.Marble, true)
					end
					P(out(cf, 0, 6.3, 1), "Mantel", Vector3.new(9.4, 0.6, 2), TRIM:Lerp(SOOT, 0.3), MAT.Marble, true)
					P(out(cf, 0, 7.6, 0.4), "Mantel", Vector3.new(8, 2, 0.8), TRIM, MAT.Marble)
					P(out(cf, 0, 2.8, 0.15), "Firebox", Vector3.new(5.8, 5.6, 0.3), VOID, MAT.Slate)
					P(out(cf, 0, 0.1, 1.6), "HearthStone", Vector3.new(8, 0.2, 2.4), SOOT, MAT.Slate)
					P(out(cf, 0, 0.35, 0.9), "Ash", Vector3.new(3.4, 0.3, 1.2), Color3.fromRGB(60, 56, 52), MAT.Sand)
					glow(P(out(cf, 0, 0.5, 0.9), "Embers", Vector3.new(1.6, 0.1, 0.6), Color3.fromRGB(150, 56, 30), MAT.Neon), Color3.fromRGB(255, 110, 50), 12, 0.6, true)
					for _, x in ipairs({ -3, -2.4, 2.8 }) do -- candle stubs on the mantel, long out
						P(out(cf, x, 7.05 + 0.3, 1.2), "Candle", Vector3.new(0.35, dr:NextNumber(0.4, 1), 0.35), Color3.fromRGB(196, 186, 160), MAT.SmoothPlastic)
					end
				end
				local function tallClock(cf) -- a long-case clock, stopped
					local c = out(cf, 0, 0, 0.8)
					P(c * CFrame.new(0, 3.5, 0), "ClockCase", Vector3.new(2.2, 7, 1.5), DARKWOOD, MAT.Wood, true)
					P(c * CFrame.new(0, 8.2, 0), "ClockHood", Vector3.new(2.6, 2.6, 1.7), DARKWOOD, MAT.Wood, true)
					P(c * CFrame.new(0, 9.7, 0), "ClockHood", Vector3.new(2.9, 0.4, 1.9), DARKWOOD:Lerp(SOOT, 0.4), MAT.Wood)
					disc(c * CFrame.new(0, 8.2, -0.86) * CFrame.Angles(math.pi / 2, 0, 0), "ClockDial", 1.9, 0.05, Color3.fromRGB(150, 140, 116), MAT.SmoothPlastic)
					P(c * CFrame.new(0.25, 8.4, -0.9) * CFrame.Angles(0, 0, -0.9), "ClockHand", Vector3.new(0.08, 0.7, 0.04), VOID, MAT.Metal)
					P(c * CFrame.new(-0.15, 8.05, -0.9) * CFrame.Angles(0, 0, 2.2), "ClockHand", Vector3.new(0.08, 0.5, 0.04), VOID, MAT.Metal)
					P(c * CFrame.new(0, 3.8, -0.76), "ClockWindow", Vector3.new(1.1, 4, 0.05), Color3.fromRGB(30, 28, 26), MAT.Glass)
				end
				local function statue(cf) -- a hooded figure, hands clasped, head bowed
					local st = Color3.fromRGB(118, 114, 106):Lerp(SOOT, dr:NextNumber(0.1, 0.35))
					P(cf * CFrame.new(0, 0.5, 0), "Statue", Vector3.new(2.8, 1, 2.2), st, MAT.Limestone, true)
					P(cf * CFrame.new(0, 3.2, 0), "Statue", Vector3.new(2.4, 4.6, 1.8), st, MAT.Limestone, true)
					P(cf * CFrame.new(0, 6, 0.1), "Statue", Vector3.new(2, 1.4, 1.6), st, MAT.Limestone)
					part({ Name = "StatueHood", Shape = Enum.PartType.Ball, Size = Vector3.new(1.9, 1.9, 1.9), CFrame = cf * CFrame.new(0, 7.2, 0.15), Material = MAT.Limestone, Color = st, CanCollide = false })
					P(cf * CFrame.new(0, 6.95, -0.72) * CFrame.Angles(0.35, 0, 0), "StatueFace", Vector3.new(0.9, 1, 0.2), VOID, MAT.Slate)
					P(cf * CFrame.new(0, 4.6, -1.05), "StatueHands", Vector3.new(0.9, 1, 0.6), st, MAT.Limestone)
					P(cf * CFrame.new(0.4, 4, -0.92), "Moss", Vector3.new(0.9, 3.6, 0.1), MOSS:Lerp(SOOT, 0.4), MAT.Grass)
				end
				local function pew(cf, len, broken)
					if broken then
						cf = cf * CFrame.new(0, -0.4, 0) * CFrame.Angles(dr:NextNumber(-0.1, 0.1), 0, dr:NextNumber(0.12, 0.25))
					end
					P(cf * CFrame.new(0, 1.5, 0), "PewSeat", Vector3.new(len, 0.3, 1.6), DARKWOOD, MAT.WoodPlanks, not broken)
					P(cf * CFrame.new(0, 2.6, 0.75) * CFrame.Angles(-0.1, 0, 0), "PewBack", Vector3.new(len, 1.8, 0.25), DARKWOOD, MAT.WoodPlanks, not broken)
					for _, x in ipairs({ -len / 2 + 0.2, len / 2 - 0.2 }) do
						P(cf * CFrame.new(x, 0.9, 0.2), "PewEnd", Vector3.new(0.4, 1.8, 2), DARKWOOD:Lerp(SOOT, 0.2), MAT.Wood, not broken)
					end
				end
				local function cage(x, y, z, topY) -- a gibbet cage on its chain, y = its floor; what's left of whoever was in it
					P(CFrame.new(at3(x, (y + 5.2 + topY) / 2, z)), "CageChain", Vector3.new(0.25, topY - y - 5.2, 0.25), COL.Iron, MAT.Metal)
					for k = 0, 9 do
						local a = k / 10 * math.pi * 2
						P(CFrame.new(at3(x + math.cos(a) * 1.6, y + 2.6, z + math.sin(a) * 1.6)), "CageBar", Vector3.new(0.18, 5.2, 0.18), COL.Iron, MAT.Metal)
					end
					disc(CFrame.new(at3(x, y, z)), "CageFloor", 3.6, 0.3, COL.Iron, MAT.Metal)
					disc(CFrame.new(at3(x, y + 5.2, z)), "CageTop", 3.6, 0.3, COL.Iron, MAT.Metal)
					part({ Name = "Skull", Shape = Enum.PartType.Ball, Size = Vector3.new(0.8, 0.8, 0.8), CFrame = CFrame.new(at3(x + 0.5, y + 0.55, z - 0.3)), Material = MAT.SmoothPlastic, Color = BONE, CanCollide = false })
					for _ = 1, 3 do
						P(CFrame.new(at3(x + dr:NextNumber(-0.9, 0.9), y + 0.3, z + dr:NextNumber(-0.9, 0.9))) * CFrame.Angles(0, dr:NextNumber(0, 3), 0.1), "Bone", Vector3.new(1.5, 0.2, 0.2), BONE, MAT.SmoothPlastic)
					end
				end
				local function carcass(x, z, topY, len) -- a butcher's hook on its chain, empty
					local hookY = topY - len
					P(CFrame.new(at3(x, (topY + hookY) / 2, z)), "HookChain", Vector3.new(0.2, len, 0.2), COL.Iron, MAT.Metal)
					P(CFrame.new(at3(x, hookY - 0.4, z)), "Hook", Vector3.new(0.2, 0.9, 0.2), COL.Iron, MAT.Metal)
					for _ = 1, 3 do -- (the meat that hung here is gone; its draws stay, so the house's random stream doesn't shift)
						dr:NextNumber()
					end
				end
				local function wheelchair(cf)
					P(cf * CFrame.new(0, 1.8, 0), "Wheelchair", Vector3.new(2, 0.3, 2), DARKWOOD, MAT.Wood, true)
					P(cf * CFrame.new(0, 3.3, 0.95) * CFrame.Angles(-0.15, 0, 0), "WheelchairBack", Vector3.new(2, 2.8, 0.25), DARKWOOD, MAT.WoodPlanks)
					P(cf * CFrame.new(0, 1.95, 0.1), "Blanket", Vector3.new(1.9, 0.12, 1.9), VELVET:Lerp(SOOT, 0.3), MAT.Fabric)
					for _, s in ipairs({ -1, 1 }) do
						part({ Name = "WheelchairWheel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 3, 3), CFrame = cf * CFrame.new(s * 1.2, 1.5, 0.3), Material = MAT.Metal, Color = COL.Iron, CanCollide = false })
						part({ Name = "WheelchairWheel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 0.9, 0.9), CFrame = cf * CFrame.new(s * 0.9, 0.45, -1), Material = MAT.Metal, Color = COL.Iron, CanCollide = false })
						P(cf * CFrame.new(s * 1.05, 2.6, 0.1), "WheelchairArm", Vector3.new(0.2, 0.2, 2), COL.Iron, MAT.Metal)
					end
				end
				local function feast(x1, x2, z1, z2, y) -- the last meal, still laid: a cloth, plates, goblets, candle stubs, what's left of the food
					local cloth = Color3.fromRGB(150, 142, 124):Lerp(DUST, 0.5)
					P(CFrame.new(at3((x1 + x2) / 2, y + 0.03, (z1 + z2) / 2)), "Tablecloth", Vector3.new(x2 - x1 + 0.4, 0.06, z2 - z1 + 0.4), cloth, MAT.Fabric)
					for _, x in ipairs({ x1 - 0.18, x2 + 0.18 }) do
						P(CFrame.new(at3(x, y - 0.7, (z1 + z2) / 2)), "Tablecloth", Vector3.new(0.05, 1.4, z2 - z1 + 0.4), cloth:Lerp(SOOT, 0.15), MAT.Fabric)
					end
					local mx = (x1 + x2) / 2
					for z = z1 + 2, z2 - 2, 3.4 do
						for _, x in ipairs({ x1 + 1, x2 - 1 }) do
							disc(CFrame.new(at3(x, y + 0.1, z)), "Plate", 1.3, 0.08, Color3.fromRGB(150, 146, 136), MAT.SmoothPlastic)
							if dr:NextNumber() < 0.6 then -- gone black and furred
								part({ Name = "Rotten", Shape = Enum.PartType.Ball, Size = Vector3.new(0.7, 0.7, 0.7), CFrame = CFrame.new(at3(x, y + 0.35, z)), Material = MAT.Grass, Color = Color3.fromRGB(46, 44, 30):Lerp(Color3.fromRGB(60, 24, 22), dr:NextNumber()), CanCollide = false })
							end
							local gx = x + (x < mx and 0.9 or -0.9)
							if dr:NextNumber() < 0.6 then
								disc(CFrame.new(at3(gx, y + 0.45, z + 0.6)), "Goblet", 0.4, 0.9, Color3.fromRGB(96, 84, 60), MAT.Metal)
							else -- knocked over, long since dry (no spill: a dark red puddle reads as blood)
								part({ Name = "Goblet", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.9, 0.4, 0.4), CFrame = CFrame.new(at3(gx, y + 0.25, z + 0.6)) * CFrame.Angles(0, dr:NextNumber(0, 3), 0), Material = MAT.Metal, Color = Color3.fromRGB(96, 84, 60), CanCollide = false })
							end
						end
						if dr:NextNumber() < 0.5 then
							local h = dr:NextNumber(0.4, 1.4)
							P(CFrame.new(at3(mx, y + h / 2, z + 1.7)), "Candle", Vector3.new(0.35, h, 0.35), Color3.fromRGB(196, 186, 160), MAT.SmoothPlastic)
							P(CFrame.new(at3(mx, y + 0.06, z + 1.7)), "Wax", Vector3.new(1, 0.08, 0.9), Color3.fromRGB(190, 180, 156), MAT.SmoothPlastic)
						end
					end
				end
				local function books(x, y, z, n) -- a heap of fallen books
					for i = 1, n do
						P(CFrame.new(at3(x + dr:NextNumber(-1.2, 1.2), y + 0.2 + (i % 3) * 0.3, z + dr:NextNumber(-1.2, 1.2))) * CFrame.Angles(dr:NextNumber(-0.3, 0.3), dr:NextNumber(0, 3), dr:NextNumber(-0.3, 0.3)), "Book", Vector3.new(1, 0.3, 1.4), Color3.fromRGB(dr:NextInteger(40, 80), dr:NextInteger(24, 40), dr:NextInteger(20, 34)), MAT.Fabric)
					end
				end

				-- where they stand ---------------------------------------------------------
				-- foyer
				tallClock(wallCF(-204, G0, -33, 0, 1))
				portrait(wallCF(-196, G0, -33, 0, 1), 7, 4, 6, 0.04)
				portrait(wallCF(-234, G0, -14, 0, -1), 7, 5, 7, -0.05, true)
				portrait(wallCF(-196, G0, -14, 0, -1), 7, 5, 7, 0.02)
				armchair(floorCF(-233, G0, -17.5, 2.2), true)
				-- the nave: pews round the sigil (the middle aisle clear), cages hung over the well
				for _, p in ipairs({
					{ -224, -93, math.pi, true }, { -206, -93, math.pi }, { -224, -88.5, math.pi }, { -206, -88.5, math.pi, true },
					{ -224, -47.5 }, { -206, -47.5, 0, true }, { -224, -43, 0, true }, { -206, -43, 0, true },
				}) do
					pew(floorCF(p[1], G0, p[2], p[3]), 9, p[4])
				end
				for _, c in ipairs({ { -223, -56, 28 }, { -207, -80, 30 }, { -222, -86, 27 }, { -208, -48, 31 } }) do
					cage(c[1], c[3], c[2], CEIL)
				end
				-- the rear hall: hooded statues on the plinths, the Master over the far end
				for _, z in ipairs({ -132, -114 }) do
					statue(floorCF(-226.5, G0 + 2, z, -math.pi / 2))
					statue(floorCF(-203.5, G0 + 2, z, math.pi / 2))
				end
				portrait(wallCF(-215, G0, -146, 0, 1), 6, 8, 11, 0, true)
				-- the library: a hearth, two chairs drawn up to it, a shelf come down, books everywhere
				fireplace(wallCF(-254, G0, -14, 0, -1))
				armchair(floorCF(-257, G0, -21, math.pi + 0.3))
				armchair(floorCF(-251, G0, -21, math.pi - 0.3), true)
				P(floorCF(-249, G0, -70, 0.15) * CFrame.new(0, 1.1, 0), "FallenShelf", Vector3.new(5, 2.2, 11), IN_WOOD:Lerp(SOOT, 0.3), MAT.Wood, true)
				books(-246, G0, -64, 9)
				books(-262, G0, -44, 6)
				books(-258, G0, -28, 5)
				portrait(wallCF(-243, G0, -45, -1, 0), 7, 4, 5, 0.06)
				-- the servants' hall
				wardrobe(wallCF(-243, G0, -100, -1, 0), true)
				wardrobe(wallCF(-243, G0, -108, -1, 0))
				for _ = 1, 4 do -- a heap of old linen
					P(floorCF(-262 + dr:NextNumber(-1, 1), G0, -112 + dr:NextNumber(-1.5, 1.5), dr:NextNumber(0, 3)) * CFrame.new(0, 0.4, 0) * CFrame.Angles(dr:NextNumber(-0.2, 0.2), 0, dr:NextNumber(-0.2, 0.2)), "Linen", Vector3.new(2.6, 0.6, 2), SHEET:Lerp(SOOT, dr:NextNumber(0.2, 0.5)), MAT.Fabric)
				end
				-- the dining hall: the meal, a sideboard, the family on the wall
				feast(-181, -175, -84, -26, G0 + 3)
				P(wallCF(-164, G0, -61, -1, 0) * CFrame.new(0, 2, -1.2), "Sideboard", Vector3.new(7, 4, 2.4), DARKWOOD, MAT.Wood, true)
				candelabra(-165.6, G0 + 4, -61)
				portrait(wallCF(-187, G0, -50, 1, 0), 7, 5, 6, -0.03)
				portrait(wallCF(-187, G0, -75, 1, 0), 7, 4, 6, 0.08, true)
				armchair(floorCF(-178, G0, -22.5, 0), true)
				-- the kitchens: the hooks, empty, pots on the table
				for _, z in ipairs({ -126, -121, -116 }) do
					carcass(-184, z, FL - 2, dr:NextNumber(8, 10))
				end
				for _, x in ipairs({ -184.5, -181, -178 }) do
					disc(CFrame.new(at3(x, G0 + 3.2 + 0.6, -141)), "Pot", 1.6, 1.2, Color3.fromRGB(44, 40, 36), MAT.Metal)
				end
				-- the landing: the Master again, larger, cut; a chair to wait in; a clock
				portrait(wallCF(-215, FL, -14, 0, -1), 4, 9, 12, 0, true)
				armchair(floorCF(-237, FL, -17, 2.6), true)
				tallClock(wallCF(-192, FL, -33, 0, 1))
				-- the rear gallery
				wheelchair(floorCF(-234, FL, -140, 0.4))
				portrait(wallCF(-230, FL, -146, 0, 1), 6, 5, 7, -0.04)
				portrait(wallCF(-200, FL, -146, 0, 1), 6, 5, 7, 0.03, true)
				-- the reading gallery: a desk under papers
				P(wallCF(-243, FL, -32, -1, 0) * CFrame.new(0, 1.4, -1.5), "Desk", Vector3.new(5, 2.8, 3), DARKWOOD, MAT.Wood, true)
				for _ = 1, 6 do
					P(wallCF(-243, FL, -32, -1, 0) * CFrame.new(dr:NextNumber(-2, 2), 2.83, -dr:NextNumber(0.6, 2.4)) * CFrame.Angles(0, dr:NextNumber(-0.6, 0.6), 0), "Page", Vector3.new(0.8, 0.02, 1.1), Color3.fromRGB(150, 140, 116):Lerp(DUST, dr:NextNumber()), MAT.SmoothPlastic)
				end
				books(-258, FL, -66, 7)
				portrait(wallCF(-254, FL, -14, 0, -1), 6, 5, 6, 0.05)
				-- the dormitory: what's left of the bedding, wardrobes
				for z = -142, -96, 9 do
					local sheet = SHEET:Lerp(SOOT, dr:NextNumber(0.2, 0.55))
					P(CFrame.new(at3(-264, FL + 1.75, z + 3.2)) * CFrame.Angles(dr:NextNumber(-0.05, 0.05), dr:NextNumber(-0.06, 0.06), 0), "Bedding", Vector3.new(3.8, 0.3, 4.6), sheet, MAT.Fabric)
					P(CFrame.new(at3(-264, FL + 1.95, z + 0.8)), "Pillow", Vector3.new(2.6, 0.5, 1.1), sheet:Lerp(DUST, 0.3), MAT.Fabric)
				end
				wardrobe(wallCF(-243, FL, -140, -1, 0))
				wardrobe(wallCF(-243, FL, -100, -1, 0), true)
				-- the banquet gallery: the guests' meal, laid out the same
				feast(-181, -175, -84, -30, FL + 3)
				portrait(wallCF(-187, FL, -45, 1, 0), 7, 5, 6, 0.04)
				portrait(wallCF(-187, FL, -78, 1, 0), 7, 5, 6, -0.06, true)
				-- the upper kitchens' hooks
				for _, z in ipairs({ -112, -106, -100 }) do
					carcass(-184, z, CEIL, dr:NextNumber(9, 12))
				end
				-- out front: coffins stood against the hall's face, chained shut
				for _, x in ipairs({ -252, -246, -184, -178 }) do
					local c = CFrame.new(at3(x, 3.5, -7.4)) * CFrame.Angles(-0.16, dr:NextNumber(-0.1, 0.1), 0)
					P(c, "Coffin", Vector3.new(2.4, 7, 1.2), Color3.fromRGB(34, 24, 20), MAT.Wood, true)
					for _, y in ipairs({ -1.6, 1.4 }) do
						P(c * CFrame.new(0, y, 0), "CoffinChain", Vector3.new(2.6, 0.25, 1.4), COL.Iron, MAT.Metal)
					end
				end

				-- the rot of it, room by room --------------------------------------------------
				-- (room interiors at the walls' faces: x1, z1, x2, z2)
				local ROOMS_IN = {
					{ -241, -33, -189, -14 }, { -241, -101, -189, -35 }, { -241, -146, -189, -103 },
					{ -266, -81, -243, -14 }, { -266, -146, -243, -83 }, { -187, -91, -164, -14 }, { -187, -146, -164, -93 },
				}
				local PAPER = { Color3.fromRGB(76, 40, 40), Color3.fromRGB(70, 62, 44), Color3.fromRGB(46, 54, 46), Color3.fromRGB(62, 50, 58) }
				local function nearDoor(lvl, x, z, pad)
					for _, d in ipairs(PLAN_DOORS[lvl]) do
						local off, along = d[1] and z or x, d[1] and x or z
						if math.abs(off - d[2]) < 3 and math.abs(along - d[3]) < d[4] / 2 + pad then
							return true
						end
					end
					return lvl == 1 and z > -17 and math.abs(x + 215) < 7 + pad -- (the great door)
				end
				local function inHole(lvl, x, z)
					local holes = { { STAIR_W[1] - 1, -145, STAIR_W[2] + 1, -117 }, { STAIR_E[1] - 1, -145, STAIR_E[2] + 1, -117 } }
					if lvl == 2 then
						table.insert(holes, NAVE)
						table.insert(holes, { -240, -31, -214, -23 }) -- (the attic stair)
					end
					for _, h in ipairs(holes) do
						if x > h[1] - 1 and x < h[3] + 1 and z > h[2] - 1 and z < h[4] + 1 then
							return true
						end
					end
					return false
				end
				local function motes(x1, z1, x2, z2, y, h)
					local p = part({ Name = "DustMotes", Size = Vector3.new(x2 - x1, h, z2 - z1), CFrame = CFrame.new((x1 + x2) / 2, MY + y + h / 2, (z1 + z2) / 2), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
					local pe = Instance.new("ParticleEmitter")
					pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
					pe.Rate = math.clamp((x2 - x1) * (z2 - z1) / 80, 4, 40)
					pe.Lifetime = NumberRange.new(8, 14)
					pe.Speed = NumberRange.new(0.05, 0.3)
					pe.SpreadAngle = Vector2.new(180, 180)
					pe.Size = NumberSequence.new(0.1)
					pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.45), NumberSequenceKeypoint.new(0.7, 0.55), NumberSequenceKeypoint.new(1, 1) })
					pe.Color = ColorSequence.new(Color3.fromRGB(220, 206, 180))
					pe.LightInfluence = 1
					pe.LightEmission = 0.3
					pe.Acceleration = Vector3.new(0, -0.03, 0)
					pcall(function()
						pe.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
					end)
					pe.Parent = p
				end
				local function cobweb(x, y, z, sx, sz) -- across a ceiling's corner; (sx, sz) = into the room
					local s = dr:NextNumber(2.5, 5)
					local c = at3(x + sx * s * 0.3, y - s * 0.3, z + sz * s * 0.3)
					P(CFrame.lookAt(c, c + Vector3.new(sx, 0.7, sz)), "Cobweb", Vector3.new(s * 1.4, s, 0.02), Color3.fromRGB(196, 192, 182), MAT.SmoothPlastic, false, 0.8)
					for _ = 1, 3 do -- strands sagging from wall to wall
						local a = at3(x + sx * dr:NextNumber(0.5, s), y - dr:NextNumber(0, s * 0.6), z)
						local b = at3(x, y - dr:NextNumber(0, s * 0.6), z + sz * dr:NextNumber(0.5, s))
						P(CFrame.lookAt((a + b) / 2, b), "CobwebStrand", Vector3.new(0.03, 0.03, (b - a).Magnitude), Color3.fromRGB(200, 196, 186), MAT.SmoothPlastic, false, 0.5)
					end
				end
				local function rot(r, lvl)
					local y0, top = lvl == 1 and G0 or FL, lvl == 1 and FL - 2 or CEIL
					local x1, z1, x2, z2 = r[1], r[2], r[3], r[4]
					local sides = { { x1, z1, x1, z2, 1, 0 }, { x2, z1, x2, z2, -1, 0 }, { x1, z1, x2, z1, 0, 1 }, { x1, z2, x2, z2, 0, -1 } }
					-- the walls: paper peeling off the damp, damp run down from the ceiling, bare brick, cracks
					for _ = 1, math.floor(((x2 - x1) + (z2 - z1)) / 4) do
						local s = sides[dr:NextInteger(1, 4)]
						local t = dr:NextNumber(0.08, 0.92)
						local px, pz = s[1] + (s[3] - s[1]) * t, s[2] + (s[4] - s[2]) * t
						local w, h = dr:NextNumber(1.5, 4.5), dr:NextNumber(2, 6)
						local kind = dr:NextNumber()
						if not nearDoor(lvl, px, pz, w / 2 + 1) then
							local cf = wallCF(px, y0, pz, s[5], s[6])
							local y = dr:NextNumber(2.5, top - y0 - h / 2 - 1)
							if kind < 0.45 then
								local col = PAPER[dr:NextInteger(1, #PAPER)]:Lerp(SOOT, dr:NextNumber(0.1, 0.4))
								P(out(cf, 0, y, 0.05), "Wallpaper", Vector3.new(w, h, 0.06), col, MAT.Fabric)
								if dr:NextNumber() < 0.6 then -- its top come away and curling
									P(out(cf, dr:NextNumber(-w / 4, w / 4), y + h / 2, 0.1) * CFrame.Angles(0.5, 0, 0) * CFrame.new(0, -0.9, 0), "WallpaperCurl", Vector3.new(w * 0.5, 1.8, 0.05), col:Lerp(DUST, 0.25), MAT.Fabric)
								end
							elseif kind < 0.65 then
								local len = dr:NextNumber(4, top - y0 - 2)
								P(out(cf, 0, top - y0 - len / 2, 0.04), "Damp", Vector3.new(dr:NextNumber(1, 3), len, 0.04), Color3.fromRGB(26, 28, 22), MAT.SmoothPlastic, false, 0.55)
							elseif kind < 0.82 then
								P(out(cf, 0, y, 0.08), "BareBrick", Vector3.new(w, h * 0.7, 0.12), Color3.fromRGB(70, 46, 38):Lerp(SOOT, dr:NextNumber(0.2, 0.5)), MAT.Brick)
							else
								local cx, cy, ang = 0, y + h / 2, dr:NextNumber(-2.2, -0.9)
								for _ = 1, dr:NextInteger(3, 7) do
									local len = dr:NextNumber(0.8, 1.8)
									local nx, ny = cx + math.cos(ang) * len, cy + math.sin(ang) * len
									if ny < 0.5 then
										break
									end
									P(out(cf, (cx + nx) / 2, (cy + ny) / 2, 0.03) * CFrame.Angles(0, 0, ang), "Crack", Vector3.new(len + 0.08, 0.14, 0.06), VOID, MAT.Slate)
									cx, cy = nx, ny
									ang += dr:NextNumber(-0.7, 0.7)
								end
							end
						end
					end
					-- the floor: a film of dust, fallen plaster, broken boards, loose pages
					for _ = 1, math.floor((x2 - x1) * (z2 - z1) / 55) do
						local x, z = dr:NextNumber(x1 + 0.8, x2 - 0.8), dr:NextNumber(z1 + 0.8, z2 - 0.8)
						local k = dr:NextNumber()
						if not inHole(lvl, x, z) then
							if k < 0.45 then
								P(floorCF(x, y0 + 0.11 + dr:NextNumber(0, 0.02), z, dr:NextNumber(0, 3)), "Dust", Vector3.new(dr:NextNumber(3, 8), 0.02, dr:NextNumber(2, 6)), DUST, MAT.Sand, false, 0.6)
							elseif k < 0.75 then
								for _ = 1, dr:NextInteger(2, 5) do
									local s = dr:NextNumber(0.3, 1.2)
									P(CFrame.new(at3(x + dr:NextNumber(-1.5, 1.5), y0 + s * 0.25, z + dr:NextNumber(-1.5, 1.5))) * CFrame.Angles(dr:NextNumber(-0.4, 0.4), dr:NextNumber(0, 3), dr:NextNumber(-0.4, 0.4)), "Plaster", Vector3.new(s, s * 0.4, s * 0.8), PLASTER:Lerp(SOOT, dr:NextNumber(0, 0.4)), MAT.Concrete)
								end
							elseif k < 0.9 then
								P(floorCF(x, y0 + 0.1, z, dr:NextNumber(0, 3)), "FloorHole", Vector3.new(dr:NextNumber(1, 2.5), 0.02, dr:NextNumber(1, 2.5)), VOID, MAT.Slate)
							else
								for _ = 1, dr:NextInteger(3, 6) do
									P(floorCF(x + dr:NextNumber(-1.5, 1.5), y0 + 0.12, z + dr:NextNumber(-1.5, 1.5), dr:NextNumber(0, 3)), "Page", Vector3.new(0.8, 0.02, 1.1), Color3.fromRGB(150, 140, 116):Lerp(DUST, dr:NextNumber()), MAT.SmoothPlastic)
								end
							end
						end
					end
					-- cobwebs in the ceiling's corners, dust in the air, a grey haze over it all
					for _, c in ipairs({ { x1, z1, 1, 1 }, { x2, z1, -1, 1 }, { x1, z2, 1, -1 }, { x2, z2, -1, -1 } }) do
						if dr:NextNumber() < 0.75 then
							cobweb(c[1], top, c[2], c[3], c[4])
						end
					end
					motes(x1, z1, x2, z2, y0 + 1, top - y0 - 2)
					fogBank(x1, z1, x2, z2, y0 + 10, 8, 2)
				end
				for lvl = 1, 2 do
					for _, r in ipairs(ROOMS_IN) do
						rot(r, lvl)
					end
				end
				-- what must be kept clear (the township's end clears it, once everything is built)
				for lvl = 1, 2 do
					local y = lvl == 1 and G0 or FL
					for _, d in ipairs(PLAN_DOORS[lvl]) do
						local a1, a2 = d[3] - d[4] / 2, d[3] + d[4] / 2
						if d[1] then
							table.insert(mansionClear, { a1, y + 0.3, d[2] - 3, a2, y + DH, d[2] + 3 })
						else
							table.insert(mansionClear, { d[2] - 3, y + 0.3, a1, d[2] + 3, y + DH, a2 })
						end
					end
				end
				for _, st in ipairs({ STAIR_W, STAIR_E }) do -- the climb, and the way off its head on the upper floor
					table.insert(mansionClear, { st[1], G0 + 0.3, -144, st[2], FL + DH, -112 })
				end
				table.insert(mansionClear, { -240, FL + 0.3, -30, -213, AF + DH, -24 }) -- the attic stair
				table.insert(mansionClear, { -221, 0.6, -14, -209, 26, 30 }) -- the great door, the vestibule and the steps (the lamps on its walls stay)

				-- the attic: dust thick in the air, thickest down the oculus' moonlight
				motes(-262, -142, -168, -18, AF + 1, 40)
				motes(OCX - 13, OCZ - 13, OCX + 13, OCZ + 13, AF + 40, 60)
				for _, c in ipairs({ { -266, -146, 1, 1 }, { -164, -146, -1, 1 }, { -266, -14, 1, -1 }, { -164, -14, -1, -1 } }) do
					cobweb(c[1], AF + 22, c[2], c[3], c[4])
				end

				-- DRESSED AS IT WAS, AND KEPT AS IT IS: the finish a great house had (dark panelling round every room under a
				-- chair rail, a cornice under every ceiling) and what still lives in it - candles someone keeps lit, the
				-- Consul's rot creeping up from the floors (worse upstairs, nearer him), and the things his household left:
				-- eyes in a wardrobe, a mirror that shows someone behind you, dolls on the beds, a
				-- cradle still rocking, jars in the kitchens, a wall of his pages about her, and her shrine on the landing.
				-- Nothing here is solid but the shrine's table; doorways and stairs are cleared afterwards (mansionClear).
				-- (a function of its own, not a do-block: this builder is near Luau's limit of locals in one function)
				;(function()
					local cr = Random.new(8804) -- (its own stream: nothing else shifts)
					local function R(a, b)
						return cr:NextNumber(a, b)
					end
					local PANEL, PANEL_LT, RAIL = Color3.fromRGB(36, 26, 20), Color3.fromRGB(50, 36, 27), Color3.fromRGB(60, 45, 32)
					local ICHOR, INK = Color3.fromRGB(34, 50, 26), Color3.fromRGB(58, 84, 40) -- (the rot's, dark green: nothing here is blood)
					local FLAME, WARM, WAX = Color3.fromRGB(255, 186, 96), Color3.fromRGB(255, 150, 70), Color3.fromRGB(206, 196, 168)
					local ROT_G, ROT_D = Color3.fromRGB(150, 180, 70), Color3.fromRGB(46, 54, 28)
					local PORCELAIN = Color3.fromRGB(214, 204, 188)
					local function ball(cf, name, d, color, mat, tr)
						return part({ Name = name, Shape = Enum.PartType.Ball, Size = Vector3.one * d, CFrame = cf, Material = mat or MAT.SmoothPlastic, Color = color, CanCollide = false, CanQuery = false, Transparency = tr or 0 })
					end
					local function sides(r)
						local x1, z1, x2, z2 = r[1], r[2], r[3], r[4]
						return { { x1, z1, x1, z2, 1, 0 }, { x2, z1, x2, z2, -1, 0 }, { x1, z1, x2, z1, 0, 1 }, { x1, z2, x2, z2, 0, -1 } }
					end

					-- the pieces ------------------------------------------------------------
					-- a cluster of candles burnt down at different heights, wax pooled under them; one flickering light for the lot
					local function candles(base, n, bright)
						local tallest
						for _ = 1, n do
							local h = R(0.4, 1.8)
							local c = base * CFrame.new(R(-0.8, 0.8), 0, R(-0.6, 0.6))
							disc(c * CFrame.new(0, h / 2, 0), "Candle", R(0.28, 0.42), h, WAX:Lerp(SOOT, R(0, 0.25)), MAT.SmoothPlastic)
							disc(c * CFrame.new(0, 0.03, 0), "Wax", R(0.6, 1.1), 0.06, WAX, MAT.SmoothPlastic)
							local f = ball(c * CFrame.new(0, h + 0.14, 0), "CandleFlame", 0.24, FLAME, MAT.Neon)
							f.CastShadow = false
							if not tallest or h > tallest[1] then
								tallest = { h, f }
							end
						end
						glow(tallest[2], WARM, 16, bright or 0.9, true)
					end
					-- words on a wall, in the rot's ichor: a SurfaceGui on an invisible card just off the wall, drips run down from it
					local function scrawl(cf, y, text, w, h, x, lvl)
						x = x or 0
						local wp = out(cf, x, 0, 0).Position
						if y - h / 2 < DH + 1 and nearDoor(lvl or 1, wp.X, wp.Z, w / 2 + 1) then
							return -- (it would hang over a doorway)
						end
						local card = P(out(cf, x, y, 0.09), "Scrawl", Vector3.new(w, h, 0.02), ICHOR, MAT.SmoothPlastic, false, 1)
						local g = Instance.new("SurfaceGui")
						g.Face, g.LightInfluence = Enum.NormalId.Front, 1
						g.SizingMode, g.PixelsPerStud = Enum.SurfaceGuiSizingMode.PixelsPerStud, 40
						g.Parent = card
						local t = Instance.new("TextLabel")
						t.Size, t.BackgroundTransparency, t.TextScaled = UDim2.fromScale(1, 1), 1, true
						t.TextColor3, t.TextTransparency, t.Rotation = INK, 0.08, R(-3, 3)
						t.Font = Enum.Font.Fantasy
						pcall(function()
							t.Font = Enum.Font.Creepster
						end)
						t.Text = text
						t.Parent = g
						for _ = 1, math.floor(w * 1.2) do
							local len = R(0.4, 2.2)
							P(out(cf, x + R(-w / 2, w / 2) * 0.9, y - h * 0.3 - len / 2, 0.08), "IchorDrip", Vector3.new(R(0.05, 0.1), len, 0.03), ICHOR, MAT.SmoothPlastic)
						end
					end
					-- two pale points in a dark gap
					local function eyes(cf, color)
						for _, x in ipairs({ -0.15, 0.15 }) do
							local e = P(cf * CFrame.new(x, 0, 0), "Eye", Vector3.new(0.12, 0.06, 0.02), color or Color3.fromRGB(230, 220, 170), MAT.Neon)
							e.CastShadow = false
						end
					end
					-- the Consul's rot: a clump of pale-stalked fungus, glowing under the caps, shedding spores
					local function fungus(x, z, y, n, lit)
						local hub
						for _ = 1, n do
							local d, h = R(0.5, 1.7), R(0.3, 1.5)
							local c = CFrame.new(at3(x + R(-1.3, 1.3), y, z + R(-1.3, 1.3))) * CFrame.Angles(R(-0.25, 0.25), 0, R(-0.25, 0.25))
							disc(c * CFrame.new(0, h / 2, 0), "Stalk", d * 0.22, h, Color3.fromRGB(150, 146, 112), MAT.SmoothPlastic)
							disc(c * CFrame.new(0, h + 0.08, 0), "FungusCap", d, d * 0.2, ROT_D:Lerp(SOOT, R(0, 0.4)), MAT.Slate)
							hub = disc(c * CFrame.new(0, h - 0.04, 0), "FungusGills", d * 0.85, 0.06, ROT_G, MAT.Neon)
						end
						local sp = Instance.new("ParticleEmitter")
						sp.Texture, sp.Color, sp.LightEmission = "rbxasset://textures/particles/sparkles_main.dds", ColorSequence.new(ROT_G), 0.6
						sp.Size, sp.Transparency = NumberSequence.new(0.12, 0), NumberSequence.new(0.2, 1)
						sp.Lifetime, sp.Speed, sp.SpreadAngle, sp.Rate = NumberRange.new(3, 6), NumberRange.new(0.2, 0.6), Vector2.new(50, 50), 4
						sp.Acceleration = Vector3.new(0, 0.25, 0)
						sp.Parent = hub
						if lit then
							glow(hub, ROT_G, 11, 0.55)
						end
					end
					-- its veins, branching up the wall behind a clump
					local function veins(cf, h)
						for _ = 1, cr:NextInteger(2, 4) do
							local cx, cy, ang = R(-1.5, 1.5), 0.2, math.pi / 2 + R(-0.5, 0.5)
							for _ = 1, cr:NextInteger(4, 8) do
								local len = R(0.6, 1.4)
								local nx, ny = cx + math.cos(ang) * len, cy + math.sin(ang) * len
								if ny > h then
									break
								end
								P(out(cf, (cx + nx) / 2, (cy + ny) / 2, 0.04) * CFrame.Angles(0, 0, ang), "RotVein", Vector3.new(len + 0.06, R(0.08, 0.2), 0.06), ROT_D:Lerp(ROT_G, R(0, 0.25)), MAT.Grass)
								if cr:NextNumber() < 0.3 then
									ball(out(cf, nx, ny, 0.06), "Pustule", R(0.15, 0.32), ROT_G, MAT.Neon)
								end
								cx, cy = nx, ny
								ang += R(-0.6, 0.6)
							end
						end
					end
					local function doll(cf, turned) -- sat up, facing -z; turned: its head screwed round toward you
						local dress = ({ Color3.fromRGB(96, 70, 80), Color3.fromRGB(70, 76, 96), Color3.fromRGB(110, 100, 84) })[cr:NextInteger(1, 3)]:Lerp(SOOT, R(0.2, 0.5))
						P(cf * CFrame.new(0, 0.45, 0), "DollBody", Vector3.new(0.7, 0.8, 0.45), dress, MAT.Fabric)
						for _, s in ipairs({ -1, 1 }) do
							P(cf * CFrame.new(s * 0.17, 0.12, -0.35), "DollLeg", Vector3.new(0.2, 0.2, 0.7), PORCELAIN:Lerp(SOOT, 0.3), MAT.SmoothPlastic)
							P(cf * CFrame.new(s * 0.45, 0.45, -0.05) * CFrame.Angles(0.3, 0, s * 0.15), "DollArm", Vector3.new(0.16, 0.65, 0.16), PORCELAIN:Lerp(SOOT, 0.3), MAT.SmoothPlastic)
						end
						local head = cf * CFrame.new(0, 1.15, 0) * CFrame.Angles(turned and 0.25 or 0, turned and 1.4 or R(-0.2, 0.2), 0)
						ball(head, "DollHead", 0.62, PORCELAIN:Lerp(SOOT, R(0.05, 0.25)))
						P(head * CFrame.new(0, 0.16, 0.08), "DollHair", Vector3.new(0.66, 0.46, 0.58), Color3.fromRGB(34, 24, 20), MAT.Fabric)
						for _, x in ipairs({ -0.12, 0.12 }) do
							P(head * CFrame.new(x, 0.02, -0.29), "DollEye", Vector3.new(0.1, 0.12, 0.03), VOID, MAT.SmoothPlastic)
						end
						P(head * CFrame.new(0.13, 0.12, -0.28) * CFrame.Angles(0, 0, 0.7), "DollCrack", Vector3.new(0.03, 0.34, 0.02), VOID, MAT.SmoothPlastic)
					end
					local function cradle(x, z, y, topY) -- caught mid-rock; a mobile of small bones over it
						local c = CFrame.new(at3(x, y, z)) * CFrame.Angles(0, 0.4, 0) * CFrame.Angles(0, 0, 0.08)
						P(c * CFrame.new(0, 1.1, 0), "Cradle", Vector3.new(2.2, 0.15, 3.4), DARKWOOD, MAT.Wood)
						for _, s in ipairs({ -1, 1 }) do
							P(c * CFrame.new(s * 1.05, 1.6, 0), "Cradle", Vector3.new(0.15, 1.0, 3.4), DARKWOOD, MAT.WoodPlanks)
							P(c * CFrame.new(0, 1.8, s * 1.65), "Cradle", Vector3.new(2.2, 1.4, 0.15), DARKWOOD, MAT.WoodPlanks)
							for k = -1, 1 do -- the rocker, in three
								P(c * CFrame.new(s * 0.9, 0.25 + math.abs(k) * 0.12, k * 1.2) * CFrame.Angles(-k * 0.3, 0, 0), "CradleRocker", Vector3.new(0.15, 0.2, 1.3), DARKWOOD:Lerp(SOOT, 0.3), MAT.Wood)
							end
							for _, zz in ipairs({ -1.2, 1.2 }) do
								P(c * CFrame.new(s * 0.9, 0.7, zz), "CradleLeg", Vector3.new(0.15, 0.9, 0.15), DARKWOOD, MAT.Wood)
							end
						end
						P(c * CFrame.new(0, 2.6, 1.3) * CFrame.Angles(-0.5, 0, 0), "CradleHood", Vector3.new(2.3, 0.12, 1.4), VELVET:Lerp(SOOT, 0.4), MAT.Fabric)
						P(c * CFrame.new(0, 1.4, 0.2), "Blanket", Vector3.new(1.8, 0.5, 2.4), VELVET:Lerp(SOOT, 0.5), MAT.Fabric)
						P(c * CFrame.new(0.4, 1.62, -0.95) * CFrame.Angles(0.2, 0.3, 0), "TinyHand", Vector3.new(0.12, 0.1, 0.5), BONE, MAT.SmoothPlastic)
						local hang = y + 7
						P(CFrame.new(at3(x, (topY + hang) / 2, z)), "MobileChain", Vector3.new(0.08, topY - hang, 0.08), COL.Iron, MAT.Metal)
						P(CFrame.new(at3(x, hang, z)) * CFrame.Angles(0, 0.6, 0), "Mobile", Vector3.new(2.4, 0.08, 0.08), COL.Iron, MAT.Metal)
						P(CFrame.new(at3(x, hang, z)) * CFrame.Angles(0, 2.17, 0), "Mobile", Vector3.new(2.4, 0.08, 0.08), COL.Iron, MAT.Metal)
						for i = 0, 3 do
							local a = 0.6 + i * math.pi / 2
							local px, pz = x + math.cos(a) * 1.15, z - math.sin(a) * 1.15
							local len = R(0.8, 1.6)
							P(CFrame.new(at3(px, hang - len / 2, pz)), "MobileString", Vector3.new(0.03, len, 0.03), DUST, MAT.Fabric)
							if i % 2 == 0 then
								ball(CFrame.new(at3(px, hang - len - 0.2, pz)), "TinySkull", 0.4, BONE)
							else
								P(CFrame.new(at3(px, hang - len - 0.25, pz)) * CFrame.Angles(0, 0, 0.3), "Bone", Vector3.new(0.12, 0.6, 0.12), BONE, MAT.SmoothPlastic)
							end
						end
					end
					local function mirror(cf) -- half under a dust sheet; in the half that shows, someone standing behind you
						local c = out(cf, 0, 6.4, 0.2)
						P(c, "MirrorFrame", Vector3.new(4, 7, 0.4), GILT:Lerp(SOOT, 0.5), MAT.Wood)
						P(c * CFrame.new(0, 0, -0.22), "Mirror", Vector3.new(3.2, 6.2, 0.05), Color3.fromRGB(40, 44, 48), MAT.Glass).Reflectance = 0.35
						P(c * CFrame.new(0.75, -0.8, -0.25), "MirrorFigure", Vector3.new(1.1, 2.8, 0.02), Color3.fromRGB(16, 16, 18), MAT.SmoothPlastic, false, 0.25)
						P(c * CFrame.new(0.75, 1.05, -0.26), "MirrorFace", Vector3.new(0.65, 0.85, 0.02), Color3.fromRGB(150, 146, 136), MAT.SmoothPlastic, false, 0.5)
						eyes(c * CFrame.new(0.75, 1.15, -0.27), Color3.fromRGB(200, 60, 40))
						P(c * CFrame.new(-0.85, 0.3, -0.35) * CFrame.Angles(0, 0, 0.04), "MirrorSheet", Vector3.new(2.6, 7.4, 0.08), SHEET:Lerp(DUST, 0.4), MAT.Fabric)
						P(out(cf, -1.2, 0.15, 0.9) * CFrame.Angles(0, 0.3, 0), "MirrorSheet", Vector3.new(2.4, 0.25, 1.6), SHEET:Lerp(DUST, 0.5), MAT.Fabric)
					end
					local function jars(cf) -- two shelves of specimens in cloudy green, a light behind them
						local lightJar
						for _, sy in ipairs({ 3.6, 6.3 }) do
							P(out(cf, 0, sy, 0.6), "Shelf", Vector3.new(7.4, 0.2, 1.2), DARKWOOD, MAT.Wood)
							for _, x in ipairs({ -3.2, 3.2 }) do
								P(out(cf, x, sy - 0.4, 0.3), "ShelfBracket", Vector3.new(0.2, 0.7, 0.6), COL.Iron, MAT.Metal)
							end
							for i = 1, 4 do
								local x, h, d = -2.6 + (i - 1) * 1.75 + R(-0.2, 0.2), R(1.1, 1.8), R(0.8, 1.05)
								local c = out(cf, x, sy + 0.1, 0.6)
								local jar = disc(c * CFrame.new(0, h / 2, 0), "Jar", d, h, ROT_G:Lerp(Color3.fromRGB(110, 100, 60), R(0, 0.6)), MAT.Glass)
								jar.Transparency = 0.45
								disc(c * CFrame.new(0, h + 0.08, 0), "JarLid", d * 0.9, 0.16, COL.Iron, MAT.Metal)
								local what = cr:NextNumber()
								if what < 0.35 then -- an eye, staring out
									local e = ball(c * CFrame.new(0, h * 0.5, 0), "Specimen", d * 0.45, Color3.fromRGB(210, 200, 180))
									ball(e.CFrame * CFrame.new(0, 0, -d * 0.18), "SpecimenPupil", d * 0.16, Color3.fromRGB(30, 60, 40))
								elseif what < 0.7 then -- a curled shape, too small to be anything you'd name
									ball(c * CFrame.new(0, h * 0.45, 0), "Specimen", d * 0.6, Color3.fromRGB(140, 104, 96):Lerp(SOOT, R(0, 0.3)))
									ball(c * CFrame.new(0.1, h * 0.7, 0), "Specimen", d * 0.35, Color3.fromRGB(150, 116, 106))
								else -- a hand
									P(c * CFrame.new(0, h * 0.45, 0) * CFrame.Angles(0.2, 0.5, 0.1), "Specimen", Vector3.new(d * 0.35, d * 0.7, 0.15), Color3.fromRGB(150, 120, 104), MAT.SmoothPlastic)
								end
								lightJar = lightJar or jar
							end
						end
						glow(lightJar, ROT_G, 12, 0.6)
					end
					local function tally(cf, x0, y0t, groups) -- days counted, scratched into the plaster
						for g = 0, groups - 1 do
							local gx, gy = x0 + (g % 6) * 1.2, y0t - math.floor(g / 6) * 1.1
							for k = 0, 3 do
								P(out(cf, gx + k * 0.17, gy, 0.04), "Tally", Vector3.new(0.06, 0.75, 0.03), Color3.fromRGB(122, 114, 102), MAT.Concrete)
							end
							P(out(cf, gx + 0.26, gy, 0.05) * CFrame.Angles(0, 0, 1.0), "Tally", Vector3.new(0.06, 0.95, 0.03), Color3.fromRGB(122, 114, 102), MAT.Concrete)
						end
					end
					-- room by room: panelling and cornice, candles, rot ----------------------
					for lvl = 1, 2 do
						for _, r in ipairs(ROOMS_IN) do
							local y0, top = lvl == 1 and G0 or FL, lvl == 1 and FL - 2 or CEIL
							for _, s in ipairs(sides(r)) do
								local len = math.abs(s[3] - s[1]) + math.abs(s[4] - s[2])
								local n = math.max(1, math.floor(len / 6))
								local w = len / n
								for i = 0, n - 1 do -- (in short lengths, so a doorway only loses the one it's in)
									local t = (i + 0.5) / n
									local px, pz = s[1] + (s[3] - s[1]) * t, s[2] + (s[4] - s[2]) * t
									if not nearDoor(lvl, px, pz, w / 2 + 0.5) then
										local cf = wallCF(px, y0, pz, s[5], s[6])
										P(out(cf, 0, 2.1, 0.07), "Wainscot", Vector3.new(w, 4.2, 0.14), PANEL:Lerp(SOOT, R(0, 0.3)), MAT.Wood)
										P(out(cf, 0, 2.3, 0.17), "WainscotPanel", Vector3.new(w - 1, 2.8, 0.06), PANEL_LT:Lerp(SOOT, R(0, 0.35)), MAT.WoodPlanks)
										P(out(cf, 0, 4.3, 0.16), "ChairRail", Vector3.new(w, 0.3, 0.32), RAIL, MAT.Wood)
									end
								end
								local mid = wallCF((s[1] + s[3]) / 2, y0, (s[2] + s[4]) / 2, s[5], s[6])
								P(out(mid, 0, top - y0 - 0.35, 0.2), "Cornice", Vector3.new(len, 0.7, 0.4), TRIM:Lerp(SOOT, 0.3), MAT.Slate)
								P(out(mid, 0, top - y0 - 0.95, 0.1), "Cornice", Vector3.new(len, 0.5, 0.2), TRIM:Lerp(SOOT, 0.5), MAT.Slate)
							end
							-- candles along the walls, and the rot: a clump or two (more upstairs), its veins up the wall
							local ss = sides(r)
							local placed, tries = 0, 0
							local want = lvl == 1 and { 2, 1 } or { 2, 2 } -- (candle clusters, rot clumps)
							while placed < want[1] + want[2] and tries < 30 do
								tries += 1
								local s = ss[cr:NextInteger(1, 4)]
								local t = R(0.12, 0.88)
								local px, pz = s[1] + (s[3] - s[1]) * t, s[2] + (s[4] - s[2]) * t
								local ix, iz = px + s[5] * 1.4, pz + s[6] * 1.4
								if not nearDoor(lvl, px, pz, 3) and not inHole(lvl, ix, iz) then
									local cf = wallCF(px, y0, pz, s[5], s[6])
									if placed < want[1] then
										candles(out(cf, 0, 0, 1.1), cr:NextInteger(3, 6))
									else
										fungus(ix, iz, y0, cr:NextInteger(4, 7), placed % 2 == 0)
										veins(cf, lvl == 1 and 7 or 11)
									end
									placed += 1
								end
							end
						end
					end

					-- set pieces -------------------------------------------------------------
					-- the ajar wardrobes (servants' hall, dormitory): something in the dark of each, watching
					for _, y in ipairs({ G0, FL }) do
						eyes(out(wallCF(-243, y, -100, -1, 0), 0, 0, 1.25) * CFrame.new(0.95, 6.5, -1.3))
					end
					-- the foyer: a mirror on the back wall
					if not nearDoor(1, -228, -33, 3) then
						mirror(wallCF(-228, G0, -33, 0, 1))
					end
					-- the rear hall: votive candles under the Master's portrait, and what's been written beside it
					candles(floorCF(-219.5, G0, -144.6), 6, 1.1)
					candles(floorCF(-210.5, G0, -144.6), 5, 0.7)
					scrawl(wallCF(-230, G0, -146, 0, 1), 9, "HE NEVER CAME DOWN", 9, 1.6)
					-- the dormitory: dolls sat up on the beds (one has turned its head), a cradle, and the wall
					local beds = 0
					for z = -142, -96, 9 do
						beds += 1
						if beds ~= 3 then
							doll(CFrame.new(at3(-264.4, FL + 1.6, z + 2.4)) * CFrame.Angles(0, -math.pi / 2, 0), beds == 4)
						end
					end
					cradle(-250, -88, FL, CEIL)
					scrawl(wallCF(-243, FL, -122, -1, 0), 8, "IT ONLY OPENS FROM HERE", 8, 1.5, 0, 2)
					-- the servants' hall: the days, counted
					tally(wallCF(-266, G0, -112, 1, 0), -3.5, 7, 22)
					-- the kitchens: jars on the wall, a message on the back wall
					jars(wallCF(-164, G0, -118, -1, 0))
					scrawl(wallCF(-171, G0, -146, 0, 1), 9, "KEEP THEM FRESH FOR HER", 9, 1.5)
					-- the library: his pages pinned up over the wall, string run between them, and her face in the middle of it
					do
						local cf = wallCF(-243, G0, -60, -1, 0)
						local pins = {}
						for _ = 1, 16 do
							local x, y = R(-5, 5), R(5, 11)
							P(out(cf, x, y, 0.06) * CFrame.Angles(0, 0, R(-0.25, 0.25)), "Page", Vector3.new(0.9, 1.2, 0.02), Color3.fromRGB(150, 140, 116):Lerp(DUST, R(0, 0.6)), MAT.SmoothPlastic)
							P(out(cf, x, y + 0.45, 0.08), "Pin", Vector3.new(0.08, 0.08, 0.06), Color3.fromRGB(150, 30, 30), MAT.Metal)
							table.insert(pins, Vector2.new(x, y + 0.45))
						end
						P(out(cf, 0, 8, 0.07), "Sketch", Vector3.new(2, 2.6, 0.02), Color3.fromRGB(170, 160, 136), MAT.SmoothPlastic)
						P(out(cf, 0, 8.2, 0.09), "SketchFace", Vector3.new(0.9, 1.2, 0.01), Color3.fromRGB(60, 50, 44), MAT.SmoothPlastic)
						for i = 1, 8 do -- red string, each from a page to her
							local p = pins[i]
							local mid, d = (p + Vector2.new(0, 8)) / 2, Vector2.new(0, 8) - p
							P(out(cf, mid.X, mid.Y, 0.1) * CFrame.Angles(0, 0, math.atan2(d.Y, d.X)), "String", Vector3.new(d.Magnitude, 0.04, 0.02), Color3.fromRGB(150, 24, 24), MAT.Fabric)
						end
						candles(floorCF(-246, G0, -60), 3, 0.6)
					end
					-- the feast tables: their candles still lit
					for _, y in ipairs({ G0, FL }) do
						for _, z in ipairs({ -72, -56, -40 }) do
							candles(CFrame.new(at3(-178, y + 3.06, z)), 3, 0.7)
						end
					end
					-- the landing: HER SHRINE, against its east wall - Ossaria, "my star", kept in candles and dead roses
					do
						local sz
						for _, z in ipairs({ -24, -19, -29 }) do
							if not nearDoor(2, -189, z, 3) then
								sz = z
								break
							end
						end
						if sz then
							local cf = wallCF(-189, FL, sz, -1, 0)
							P(out(cf, 0, 1.5, 1.0), "ShrineTable", Vector3.new(4.4, 3, 2), DARKWOOD, MAT.Wood, true)
							P(out(cf, 0, 3.04, 1.0), "ShrineCloth", Vector3.new(4.6, 0.06, 2.2), VELVET:Lerp(SOOT, 0.2), MAT.Fabric)
							P(out(cf, 0, 2.3, 2.02), "ShrineCloth", Vector3.new(4.6, 1.5, 0.05), VELVET:Lerp(SOOT, 0.3), MAT.Fabric)
							local c = out(cf, 0, 7.6, 0.25)
							P(c, "PortraitFrame", Vector3.new(4.8, 5.8, 0.5), GILT, MAT.Wood)
							P(c * CFrame.new(0, 0, -0.27), "Portrait", Vector3.new(3.8, 4.8, 0.06), Color3.fromRGB(40, 30, 40), MAT.Fabric)
							P(c * CFrame.new(0, -1.2, -0.31), "PortraitSitter", Vector3.new(2.8, 2.2, 0.04), Color3.fromRGB(70, 20, 30), MAT.Fabric)
							P(c * CFrame.new(0, 0.5, -0.31), "PortraitSitter", Vector3.new(1.4, 1.9, 0.04), Color3.fromRGB(26, 20, 18), MAT.Fabric)
							P(c * CFrame.new(0, 0.4, -0.33), "PortraitSitter", Vector3.new(0.9, 1.1, 0.04), Color3.fromRGB(196, 184, 168), MAT.Fabric)
							for _, a in ipairs({ 0, math.pi / 4 }) do -- her star, over her head
								P(c * CFrame.new(0, 1.85, -0.34) * CFrame.Angles(0, 0, a), "Star", Vector3.new(0.4, 0.4, 0.03), Color3.fromRGB(255, 214, 120), MAT.Neon)
							end
							candles(out(cf, -1.2, 3.07, 1.0), 5, 1.3)
							candles(out(cf, 1.4, 3.07, 0.8), 3, 0.5)
							disc(out(cf, 0.2, 3.07 + 0.45, 1.3), "Vase", 0.5, 0.9, TRIM, MAT.Marble)
							for _ = 1, 5 do -- roses, long dead
								local s = out(cf, 0.2 + R(-0.15, 0.15), 3.9 + 0.3, 1.3) * CFrame.Angles(R(-0.35, 0.35), 0, R(-0.45, 0.45))
								P(s, "RoseStem", Vector3.new(0.06, 1.1, 0.06), Color3.fromRGB(46, 40, 26), MAT.Wood)
								ball(s * CFrame.new(0, 0.6, 0), "Rose", 0.3, Color3.fromRGB(70, 14, 22), MAT.Fabric)
							end
							for _ = 1, 4 do -- his letters to her
								P(out(cf, R(-1.8, 1.8), 3.09, R(0.4, 1.7)) * CFrame.Angles(0, R(-0.6, 0.6), 0), "Letter", Vector3.new(0.8, 0.02, 1.1), Color3.fromRGB(160, 150, 124), MAT.SmoothPlastic)
							end
						end
					end
				end)()
			end
			Detail.useRng(oldDetailRng)
			rng = oldRng
			end
			B(-160, 0, -130, -130, 52, -30, "MansionWing")
			B(-300, 0, -130, -270, 52, -30, "MansionWing")
			facade(true, 1, -10, -270, -160, HT, { 4, 17, 30, 43, 56 }, 12)
			facade(true, -1, -150, -270, -160, HT, { 4, 17, 30, 43, 56 }, 12)
			facade(false, -1, -270, -150, -130, HT, { 4, 17, 30, 43, 56 }, 10)
			facade(false, -1, -270, -30, -10, HT, { 4, 17, 30, 43, 56 }, 10)
			facade(false, 1, -160, -150, -130, HT, { 4, 17, 30, 43, 56 }, 10)
			facade(false, 1, -160, -30, -10, HT, { 4, 17, 30, 43, 56 }, 10)
			facade(true, 1, -30, -148, -130, 52, { 4, 17, 30 }, 9)
			facade(true, -1, -130, -160, -130, 52, { 4, 17, 30 }, 9)
			facade(false, 1, -130, -130, -30, 52, { 4, 17, 30 }, 12)
			facade(true, 1, -30, -300, -282, 52, { 4, 17, 30 }, 9)
			facade(true, -1, -130, -300, -270, 52, { 4, 17, 30 }, 9)
			facade(false, -1, -300, -130, -30, 52, { 4, 17, 30 }, 12)
			-- a chapel behind it, and its apse
			B(-240, 0, -180, -190, 78, -150, "MansionChapel")
			facade(false, -1, -240, -180, -150, 78, { 8, 28, 48 }, 10)
			facade(false, 1, -190, -180, -150, 78, { 8, 28, 48 }, 10)
			part({ Name = "Apse", Shape = Enum.PartType.Cylinder, Size = Vector3.new(78, 40, 40), CFrame = CFrame.new(-215, MY + 39, -180) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Cobblestone, Color = STONE })
			for a = 0.35, math.pi - 0.3, 0.6 do
				local dir = Vector3.new(math.cos(a + math.pi), 0, math.sin(a + math.pi))
				local cf = CFrame.lookAt(Vector3.new(-215, MY, -180) + dir * 20, Vector3.new(-215, MY, -180) + dir * 21)
				for _, y in ipairs({ 8, 28, 48 }) do
					rel(cf, { Name = "WinGlass", Size = Vector3.new(3.2, 9, 0.5), CFrame = CFrame.new(0, y + 4.5, -0.3), Material = MAT.Slate, Color = VOID })
				end
			end
			for i = 0, 9 do -- the apse's cone
				local r = 20.5 * (1 - i / 10)
				part({ Name = "ApseRoof", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, r * 2, r * 2), CFrame = CFrame.new(-215, MY + 78 + i * 3.6 + 2, -180) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Slate, Color = SLATE:Lerp(TRIM, rng:NextNumber() * 0.2) })
			end
			-- towers: the entrance, four at the hall's corners
			mTower(-235, -10, -195, 14, 120, 70, true, true)
			mTower(-282, -32, -262, -10, 108, 60)
			mTower(-168, -32, -148, -10, 108, 60)
			mTower(-282, -150, -262, -128, 96, 52)
			mTower(-168, -150, -148, -128, 96, 52)

			-- the roofs: slate panels over a dark filling (a fallen panel shows the dark, not the sky),
			-- steep, here and there missing, sagged or slipped
			local function gableFill(x1, x2, zc, hw, y0, rise, axisX) -- steps of a gable's triangle, along one axis
				for i = 0, 9 do
					local h = hw * (1 - (i + 1) / 10)
					local ya, yb = y0 + rise * i / 10, y0 + rise * (i + 1) / 10
					if axisX then
						B(x1, ya, zc - h, x2, yb, zc + h, "RoofFill", Color3.fromRGB(26, 24, 24), MAT.Slate)
					else
						B(zc - h, ya, x1, zc + h, yb, x2, "RoofFill", Color3.fromRGB(26, 24, 24), MAT.Slate)
					end
				end
			end
			local function panels(a1, a2, eaveA, eaveB, ridgeA, ridgeB, y0, rise, axisX, pw, cut)
				-- panels of width pw along the run a1..a2; (eaveA, eaveB) on the two sides, (ridge) the middle;
				-- cut = { a1, a2, k }: panels over that run stop k of the way up (short of the oculus)
				for _, side in ipairs({ eaveA, eaveB }) do
					for a = a1, a2 - pw * 0.5, pw do
						local w = math.min(pw, a2 - a)
						local r = rng:NextNumber()
						if r > 0.1 then
							local am = a + w / 2
							local from = axisX and Vector3.new(am, MY + y0, side) or Vector3.new(side, MY + y0, am)
							local to = axisX and Vector3.new(am, MY + y0 + rise, ridgeA) or Vector3.new(ridgeA, MY + y0 + rise, am)
							if cut and a + w > cut[1] and a < cut[2] then
								to = from:Lerp(to, cut[3])
							end
							local len = (to - from).Magnitude + 3
							local cf = CFrame.lookAt((from + to) / 2, to) * CFrame.new(0, r < 0.25 and -rng:NextNumber(0.5, 2.5) or 0, 0) * CFrame.Angles(0, 0, r < 0.25 and rng:NextNumber(-0.06, 0.06) or 0)
							part({ Name = "RoofPanel", Size = axisX and Vector3.new(w, 1.4, len) or Vector3.new(w, 1.4, len), CFrame = axisX and cf or (cf * CFrame.Angles(0, 0, 0)), Material = MAT.RoofShingles, Color = SLATE:Lerp(Color3.fromRGB(70, 56, 46), rng:NextNumber() * 0.5), CanCollide = false })
						end
					end
				end
			end
			-- the hall's roof: ridge along x at z -80, eaves at z -152 / -8, 60 up
			-- (the hall's roof fill is the hollow shell built with its interior)
			panels(-270, -160, -152, -8, -80, -80, HT, 84, true, 11, { OCX - OQ - 2, OCX + OQ + 2, (72 - OQ - 2) / 72 })
			B(-272, HT + 83, -81.5, OCX - OQ - 2, HT + 85, -78.5, "RidgeCap", TRIM, MAT.Slate, false)
			B(OCX + OQ + 2, HT + 83, -81.5, -158, HT + 85, -78.5, "RidgeCap", TRIM, MAT.Slate, false)
			for x = -266, -164, 6 do -- crockets along the ridge
				if math.abs(x - OCX) > OQ + 3 then
					part({ Name = "Crocket", Size = Vector3.new(1.6, 1.6, 0.5), CFrame = CFrame.new(x, MY + HT + 86, -80) * CFrame.Angles(0, 0, math.pi / 4), Material = MAT.Slate, Color = TRIM, CanCollide = false })
				end
			end
			-- the gable ends, and the wings' roofs (ridges along z)
			gableFill(-130, -30, -145, 17, 52, 30, false)
			panels(-130, -30, -162, -128, -145, -145, 52, 30, false, 11)
			gableFill(-130, -30, -285, 17, 52, 30, false)
			panels(-130, -30, -302, -268, -285, -285, 52, 30, false, 11)
			for _, x in ipairs({ -255, -235, -195, -175 }) do -- chimneys on the ridge
				B(x - 2.2, HT + 70, -82.2, x + 2.2, HT + 112, -77.8, "Chimney", Color3.fromRGB(70, 56, 50), MAT.Brick)
				B(x - 2.8, HT + 112, -82.8, x + 2.8, HT + 114, -77.2, "ChimneyCap", TRIM, MAT.Slate)
			end
			-- the chapel's roof, a spire over the crossing
			gableFill(-180, -150, -215, 25, 78, 40, false)
			panels(-180, -150, -241, -189, -215, -215, 78, 40, false, 10)

			-- the great door, in the entrance tower's face: a stepped frame round the opening (x -222..-208, 26 high), its
			-- rotted leaves flung open flat against it, out of the way
			local DZ = 14
			for i, o in ipairs({ { 22, 38, 1.2 }, { 19, 34, 0.8 }, { 16.4, 30.5, 0.4 } }) do
				local col = TRIM:Lerp(STONE, i * 0.15)
				B(-215 - o[1] / 2, 0, DZ, -222, o[2], DZ + o[3], "Archivolt", col, MAT.Slate, false)
				B(-208, 0, DZ, -215 + o[1] / 2, o[2], DZ + o[3], "Archivolt", col, MAT.Slate, false)
				B(-222, 26, DZ, -208, o[2], DZ + o[3], "Archivolt", col, MAT.Slate, false)
			end
			for _, s in ipairs({ -1, 1 }) do
				B(-215 + s * 7.3 - 0.25, 1, DZ + 1.3, -215 + s * 7.3 + 0.25, 25, DZ + 7.6, "GreatDoor", Color3.fromRGB(52, 38, 28), MAT.WoodPlanks, false)
				for y = 5, 23, 6 do
					B(-215 + s * 7.6 - 0.1, y, DZ + 1.3, -215 + s * 7.6 + 0.1, y + 0.5, DZ + 7.6, "DoorStrap", Color3.fromRGB(34, 30, 28), MAT.Metal, false)
				end
			end
			for i = 0, 5 do -- the steps up to it
				B(-229, 0, DZ + 1.5 + (5 - i) * 1.6, -201, (i + 1) * 0.9, DZ + 3.1 + (5 - i) * 1.6, "Step", TRIM, MAT.Slate)
			end
			-- the bonfire before the great door, at the steps' foot: the mansion's only one
			local doorFire = at(-215, 42) + Vector3.new(0, 2, 0) -- (on the grass, 2 above the plateau)
			makeBonfire(doorFire, CFrame.lookAt(doorFire + Vector3.new(0, 3.2, 4.5), doorFire + Vector3.new(0, 3.2, 0)), "The Hollow Mansion")
			B(-232, 0, DZ + 1.2, -230, 7, DZ + 14, "Cheek", TRIM) -- low walls either side of the steps, ending in a plinth
			B(-200, 0, DZ + 1.2, -198, 7, DZ + 14, "Cheek", TRIM)

			-- THE FENCE: a Yharnam-style wrought-iron fence (tall spear-topped bars, three rails, a finial on every
			-- post) shuts the forecourt in: from the gate's avenue to the great door is all you can walk. Its
			-- sides and the mansion's flanks are fenced off, and an invisible blocker runs behind each line (the
			-- bars alone are far enough apart to squeeze through). No rng here: the map's stream mustn't shift.
			do
				local FH = 11
				local FIRON = Color3.fromRGB(24, 22, 22)
				local function fence(x1, z1, x2, z2) -- axis-aligned runs only
					local alongX = math.abs(x2 - x1) > math.abs(z2 - z1)
					local a, b = alongX and math.min(x1, x2) or math.min(z1, z2), alongX and math.max(x1, x2) or math.max(z1, z2)
					local c = alongX and z1 or x1
					local function slab(u1, u2, y1, y2, hw, name, color, mat) -- along the run from u1 to u2, hw either side of its line
						if alongX then
							return B(u1, y1, c - hw, u2, y2, c + hw, name, color, mat)
						end
						return B(c - hw, y1, u1, c + hw, y2, u2, name, color, mat)
					end
					local function ball(u, y, size)
						local p = alongX and Vector3.new(u, MY + y, c) or Vector3.new(c, MY + y, u)
						part({ Name = "FenceFinial", Shape = Enum.PartType.Ball, Size = size, CFrame = CFrame.new(p), Material = MAT.Metal, Color = FIRON, CanCollide = false })
					end
					local block = slab(a, b, 0, 22, 0.4, "FenceBlock", COL.Wall, MAT.SmoothPlastic)
					block.Transparency, block.CanQuery, block.CastShadow = 1, false, false
					for _, y in ipairs({ 1.2, 5.2, FH - 1.4 }) do
						slab(a, b, y, y + 0.35, 0.15, "FenceRail", FIRON, MAT.Metal).CanCollide = false
					end
					local n = math.max(1, math.floor((b - a) / 1.2))
					for i = 0, n do
						local u = a + (b - a) * i / n
						local tall = i % 3 == 1 and 1.6 or 0
						slab(u - 0.17, u + 0.17, 0, FH + tall, 0.17, "FenceBar", FIRON, MAT.Metal).CanCollide = false
						ball(u, FH + tall + 0.1, Vector3.one * 0.7) -- the bar's head (a Ball is a sphere whatever its Size says: centred just over the bar's top so it sits on it)
					end
					local posts = math.max(1, math.floor((b - a) / 10))
					for i = 0, posts do
						local u = a + (b - a) * i / posts
						slab(u - 0.5, u + 0.5, 0, FH + 2.6, 0.5, "FencePost", FIRON, MAT.Metal).CanCollide = false
						ball(u, FH + 3.2, Vector3.one * 1.5)
					end
				end
				fence(-244, 14, -244, 66) -- the west flank, up beside the great door's steps
				fence(-244, 66, -153, 66) -- ...turning east along the houses' feet
				fence(-153, 66, -153, 104) -- ...and up to the wall beside the avenue under the gate
				fence(-123, 14, -123, 79) -- the east side, gate wall to the mansion, with a gap (z 79..91) onto the bridge's landing
				fence(-123, 91, -123, 104)
				fence(-123, 68, -98, 68) -- (the landing, between the fence and the citadel wall, is shut in to the south)
				fence(-244, 14, -235, 14) -- the mansion's front either side of its entrance tower
				fence(-195, 14, -123, 14)
			end

			-- THE DRAWBRIDGE: a gateway in the citadel's east wall (x -98..-94, z 79..91, y 0..14) onto the chasm
			-- between the citadel and the prison wing. Raised, a timber leaf stands against it (and a hidden block
			-- fills the doorway); init.server brings it down in a cutscene once the Consul has fallen and someone
			-- walks out of the mansion: it swings down on its axle and lands on the wing's roof (x -50, y 44), its
			-- two chains paid out from posts on the wall top. Built at the raised pose; Set(theta) poses it.
			do
				local HZ, W, L = 85, 12, 46.83
				local UP, DOWN = math.rad(80), math.rad(-20)
				local hinge = CFrame.new(-94, MY, HZ)
				local base = hinge * CFrame.Angles(0, 0, UP)
				local model = Instance.new("Model")
				model.Name = "Drawbridge"
				model.Parent = map
				local wood, timber, iron = Color3.fromRGB(78, 58, 40), Color3.fromRGB(56, 42, 30), Color3.fromRGB(38, 35, 33)
				local function lp(name, size, cf, color, mat, shape)
					return part({ Name = name, Size = size, CFrame = base * cf, Material = mat, Color = color, Shape = shape, Parent = model })
				end
				local hingePart = lp("BridgeHinge", Vector3.one, CFrame.new(), wood, MAT.Wood)
				hingePart.Transparency, hingePart.CanCollide, hingePart.CanQuery = 1, false, false
				model.PrimaryPart = hingePart
				lp("BridgeDeck", Vector3.new(L, 1.2, W), CFrame.new(L / 2, -0.6, 0), wood, MAT.WoodPlanks)
				for _, s in ipairs({ -1, 1 }) do
					lp("BridgeBeam", Vector3.new(L, 1.4, 0.9), CFrame.new(L / 2, 0.7, s * 5.55), timber, MAT.Wood)
					for x = 4, L - 2, 9.4 do
						lp("BridgePost", Vector3.new(0.7, 2.8, 0.7), CFrame.new(x, 1.4, s * 5.55), timber, MAT.Wood)
					end
				end
				for x = 3, L - 1, 6 do
					lp("BridgeStrap", Vector3.new(0.5, 0.25, W), CFrame.new(x, 0.12, 0), iron, MAT.Metal).CanCollide = false
				end
				lp("BridgeTip", Vector3.new(0.8, 1.4, W), CFrame.new(L - 0.4, -0.6, 0), iron, MAT.Metal)
				lp("BridgeAxle", Vector3.new(W + 1.5, 1.6, 1.6), CFrame.new(0, -0.4, 0) * CFrame.Angles(0, math.pi / 2, 0), timber, MAT.Wood, Enum.PartType.Cylinder)
				local attach = { Vector3.new(L * 0.85, 1.4, -5.55), Vector3.new(L * 0.85, 1.4, 5.55) }
				local anchors, chains = {}, {}
				for i, z in ipairs({ HZ - 5.55, HZ + 5.55 }) do
					B(-97.5, WH, z - 1, -95.5, WH + 6, z + 1, "ChainPost", IRON, MAT.Metal)
					anchors[i] = Vector3.new(-96.5, MY + WH + 6, z)
					chains[i] = part({ Name = "BridgeChain", Size = Vector3.new(0.35, 0.35, 1), Material = MAT.Metal, Color = Color3.fromRGB(60, 56, 52), CanCollide = false, CanQuery = false })
				end
				local block = part({ Name = "BridgeBlock", Size = Vector3.new(4, 14, W), CFrame = CFrame.new(-96, MY + 7, HZ), Transparency = 1, CanQuery = false })
				local function set(theta)
					local cf = hinge * CFrame.Angles(0, 0, theta)
					model:PivotTo(cf)
					for i, ch in ipairs(chains) do
						local p = cf * attach[i]
						ch.Size = Vector3.new(0.35, 0.35, (p - anchors[i]).Magnitude)
						ch.CFrame = CFrame.lookAt((p + anchors[i]) / 2, p)
					end
				end
				set(UP)
				info.DrawBridge = { Model = model, Block = block, Up = UP, Down = DOWN, Set = set, Tip = hinge * CFrame.Angles(0, 0, DOWN) * Vector3.new(L, 0, 0) }
			end

			-- the buttresses on the hall's front, a pinnacle on each; moss and rubble and vines
			for x = -266, -164, 12 do
				if x < -240 or x > -190 then
					spire(x, -8.6, 1.3, 1.3, HT - 3, 12, 4)
				end
			end
			for _ = 1, 60 do -- patches of moss and rot on the walls
				local onZ = rng:NextNumber() < 0.5
				local u = rng:NextNumber(-266, -164)
				local y = rng:NextNumber(2, 66)
				if onZ then
					B(u, y, -10, u + rng:NextNumber(3, 9), y + rng:NextNumber(2, 6), -9.7, "Moss", MOSS:Lerp(SOOT, rng:NextNumber()), MAT.Grass, false)
				else
					B(u, y, -150.3, u + rng:NextNumber(3, 9), y + rng:NextNumber(2, 6), -150, "Moss", MOSS:Lerp(SOOT, rng:NextNumber()), MAT.Grass, false)
				end
			end
			for x = -300, -130, 9 do
				if rng:NextNumber() < 0.7 then
					rubble(at(x, 0) + Vector3.new(0, 0, rng:NextNumber(18, 20)), 3, 3)
				end
			end
			for _ = 1, 5 do -- panels slid off the roof to the grass
				local p = at(rng:NextNumber(-300, -130), rng:NextNumber(18, 22))
				part({ Name = "FallenPanel", Size = Vector3.new(11, 1.2, 40), CFrame = CFrame.new(p + Vector3.new(0, 4, 0)) * CFrame.Angles(rng:NextNumber(0.3, 0.6), rng:NextNumber(0, 6.3), rng:NextNumber(-0.2, 0.2)), Material = MAT.RoofShingles, Color = SLATE, CanCollide = true })
			end
			-- (the great door must be walkable whatever else is built near it: nothing solid stands in its lane,
			-- the doorway's width from the steps' foot to the foyer, but the floors, steps and walls themselves)
			do
				local KEEP = { Step = true, MansionStep = true, MansionFloor = true, Avenue = true, MansionWall = true, MansionTower = true }
				for _, p in ipairs(map:GetDescendants()) do
					if p:IsA("BasePart") and p.CanCollide and not KEEP[p.Name] then
						local c, s = p.CFrame, p.Size / 2
						local r, u, l = c.RightVector, c.UpVector, c.LookVector
						local hx = math.abs(r.X) * s.X + math.abs(u.X) * s.Y + math.abs(l.X) * s.Z
						local hy = math.abs(r.Y) * s.X + math.abs(u.Y) * s.Y + math.abs(l.Y) * s.Z
						local hz = math.abs(r.Z) * s.X + math.abs(u.Z) * s.Y + math.abs(l.Z) * s.Z
						local q = c.Position
						if q.X + hx > -221.5 and q.X - hx < -208.5 and q.Y + hy > MY + 0.6 and q.Y - hy < MY + 14 and q.Z + hz > -14 and q.Z - hz < 60 then
							p.CanCollide = false
						end
					end
				end
			end

			-- the iron fence before it, spiked, with a gap for the path
			for x = -296, -134, 5 do
				if x < -228 or x > -202 then
					B(x - 0.2, 0, 26, x + 0.2, 9, 26.4, "FencePost", Color3.fromRGB(34, 30, 28), MAT.Metal, true)
					B(x - 0.5, 9, 25.9, x + 0.5, 11, 26.5, "FenceSpike", Color3.fromRGB(34, 30, 28), MAT.Metal, false)
				end
			end
			B(-296, 2, 26, -228, 2.4, 26.4, "FenceRail", Color3.fromRGB(34, 30, 28), MAT.Metal, false)
			B(-296, 7, 26, -228, 7.4, 26.4, "FenceRail", Color3.fromRGB(34, 30, 28), MAT.Metal, false)
			B(-202, 2, 26, -134, 2.4, 26.4, "FenceRail", Color3.fromRGB(34, 30, 28), MAT.Metal, false)
			B(-202, 7, 26, -134, 7.4, 26.4, "FenceRail", Color3.fromRGB(34, 30, 28), MAT.Metal, false)

			-- ROT AND OBSCURING: flesh clinging to the walls, grey arms growing out of it (the clients
			-- twitch anything tagged RotLimb), curtains of vine over the windows, clumps of overgrowth,
			-- and mist banked about the foot of it and wreathing its towers
			local Rot = Detail.Rot
			-- the faces to grow on: { onZ, dir, c, a1, a2, top, lowest y }
			local FACES = {
				{ true, 1, -10, -270, -160, 70, 0 }, { true, -1, -150, -270, -160, 70, 0 },
				{ false, 1, -130, -130, -30, 52, 0 }, { false, -1, -300, -130, -30, 52, 0 },
				{ true, 1, -30, -148, -130, 52, 0 }, { true, -1, -130, -160, -130, 52, 0 },
				{ true, 1, 14, -235, -195, 120, 40 }, { false, 1, -195, -10, 14, 120, 0 }, { false, -1, -235, -10, 14, 120, 0 },
				{ false, -1, -240, -180, -150, 78, 0 }, { false, 1, -190, -180, -150, 78, 0 },
				{ true, 1, -10, -282, -262, 108, 0 }, { true, 1, -10, -168, -148, 108, 0 },
			}
			local function onFace(f, u, y)
				if f[1] then
					return Vector3.new(u, MY + y, f[3] + f[2] * 0.3), Vector3.new(0, 0, f[2])
				end
				return Vector3.new(f[3] + f[2] * 0.3, MY + y, u), Vector3.new(f[2], 0, 0)
			end
			for _ = 1, 170 do
				local f = FACES[rng:NextInteger(1, #FACES)]
				local u = rng:NextNumber(f[4], f[5])
				local y = rng:NextNumber(f[7] + 1, f[6] - 4)
				local p, out = onFace(f, u, y)
				if rng:NextNumber() < 0.4 then -- an arm's root
					local root = part({ Name = "RotLimbRoot", Size = Vector3.new(0.4, 0.4, 0.4), CFrame = CFrame.lookAt(p, p + (out + Vector3.new(0, rng:NextNumber(-0.2, 0.8), 0)).Unit), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
					root:SetAttribute("Scale", rng:NextNumber(0.7, 1.6))
					root:SetAttribute("Seed", rng:NextInteger(1, 1000000))
					CollectionService:AddTag(root, "RotLimb")
				end
				local s = rng:NextNumber(2, 7)
				part({ Name = "RotMass", Shape = Enum.PartType.Ball, Size = Vector3.new(s, s * rng:NextNumber(0.7, 1), s), CFrame = CFrame.new(p + out * s * 0.25), Material = rng:NextNumber() < 0.5 and MAT.CrackedLava or MAT.SmoothPlastic, Color = Rot.Flesh:Lerp(Rot.FleshDark, rng:NextNumber()), Reflectance = 0.08, CanCollide = false })
			end
			for _ = 1, 110 do -- vines hanging from the eaves, some down over the windows
				local f = FACES[rng:NextInteger(1, #FACES)]
				local u = rng:NextNumber(f[4], f[5])
				local len = rng:NextNumber(6, math.min(f[6] - 4, 34))
				local col = MOSS:Lerp(Color3.fromRGB(14, 18, 12), rng:NextNumber() * 0.7)
				local top = f[6] - rng:NextNumber(0, 2)
				if f[1] then
					B(u, top - len, f[3] + f[2] * 0.5, u + 0.5, top, f[3] + f[2] * 0.7, "Vine", col, MAT.Fabric, false)
				else
					B(f[3] + f[2] * 0.5, top - len, u, f[3] + f[2] * 0.7, top, u + 0.5, "Vine", col, MAT.Fabric, false)
				end
			end
			for _ = 1, 70 do -- clumps of overgrowth smothering the stone (and the windows)
				local f = FACES[rng:NextInteger(1, #FACES)]
				local u = rng:NextNumber(f[4], f[5])
				local p, out = onFace(f, u, rng:NextNumber(f[7] + 2, f[6] - 6))
				local s = rng:NextNumber(4, 10)
				part({ Name = "Overgrowth", Shape = Enum.PartType.Ball, Size = Vector3.new(s, s * 0.8, s), CFrame = CFrame.new(p + out * s * 0.2), Material = MAT.Grass, Color = MOSS:Lerp(Color3.fromRGB(14, 18, 12), rng:NextNumber() * 0.8), CanCollide = false })
			end
			local function mist(x1, z1, x2, z2, y, h, rate)
				local p = part({ Name = "MansionMist", Size = Vector3.new(x2 - x1, h, z2 - z1), CFrame = CFrame.new((x1 + x2) / 2, MY + y, (z1 + z2) / 2), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
				local pe = Instance.new("ParticleEmitter")
				pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
				pe.Rate = rate
				pe.Lifetime = NumberRange.new(10, 16)
				pe.Speed = NumberRange.new(0.3, 1)
				pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 14), NumberSequenceKeypoint.new(1, 24) })
				pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.78), NumberSequenceKeypoint.new(0.7, 0.82), NumberSequenceKeypoint.new(1, 1) })
				pe.Color = ColorSequence.new(Color3.fromRGB(118, 124, 110))
				pe.LightInfluence = 1
				pe.RotSpeed = NumberRange.new(-6, 6)
				pe.Rotation = NumberRange.new(0, 360)
				pe.Acceleration = Vector3.new(0.15, 0.02, 0.1)
				pcall(function()
					pe.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
				end)
				pe.Parent = p
			end
			mist(-318, -210, -112, 30, 6, 12, 90) -- thick about its foot
			mist(-320, 30, -104, 100, 4, 8, 40) -- thinner over the courtyard
			mist(-292, -160, -140, 8, 46, 14, 40) -- wreathing the walls halfway up
			mist(-282, -150, -150, -10, 92, 16, 28) -- and its towers' middles, so the spires rise out of cloud

			-- the courtyard: a graveyard east of the path, dead trees, bones, rot
			for gx = 0, 5 do
				for gz = 0, 5 do
					if rng:NextNumber() < 0.8 then
						Detail.gravestone(at(-188 + gx * 9, 36 + gz * 8), math.pi + rng:NextNumber(-0.2, 0.2))
					end
				end
			end
			local function deadTree(p, h)
				part({ Name = "DeadTrunk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 1.6, 1.6), CFrame = CFrame.new(p + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Wood, Color = Color3.fromRGB(34, 28, 24) })
				for _ = 1, 6 do
					local from = p + Vector3.new(0, h * rng:NextNumber(0.4, 0.95), 0)
					local to = from + Vector3.new(rng:NextNumber(-6, 6), rng:NextNumber(2, 6), rng:NextNumber(-6, 6))
					part({ Name = "DeadBranch", Size = Vector3.new(0.5, 0.5, (to - from).Magnitude), CFrame = CFrame.lookAt((from + to) / 2, to), Material = MAT.Wood, Color = Color3.fromRGB(34, 28, 24), CanCollide = false })
				end
			end
			for _ = 1, 16 do
				local x, z = rng:NextNumber(-318, -104), rng:NextNumber(30, 84)
				if not (x > -232 and x < -120) then
					deadTree(at(x, z), rng:NextNumber(14, 26))
				end
			end
			for _ = 1, 40 do
				Detail.weeds(at(rng:NextNumber(-318, -104), rng:NextNumber(-208, 84)), rng:NextInteger(2, 4))
			end
			Detail.rotPatches(-320, 20, -106, 84, 40, MY)
			Detail.rotPatches(-310, -208, -120, -196, 20, MY)
			for _ = 1, 8 do
				Detail.bonePile(at(rng:NextNumber(-300, -110), rng:NextNumber(28, 84)), rng:NextInteger(4, 7))
			end
			for _ = 1, 4 do
				Detail.overgrownCorpse(at(rng:NextNumber(-300, -110), rng:NextNumber(30, 84)), Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)).Unit)
			end

			-- THE HOLLOW MANSION KEPT PASSABLE: every doorway, both stairs and their heads, the attic stair and the great door
			-- cleared of anything put there for show (the building itself, the doors' leaves and anything invisible stay)
			do
				local KEEP = {
					MansionWall = true, MansionFloor = true, MansionStep = true, MansionTower = true, Step = true, Parapet = true,
					Door = true, DoorBand = true, Column = true, Avenue = true, Archivolt = true, GreatDoor = true, DoorStrap = true,
					Cheek = true, LadderWood = true, Carpet = true, Marble = true, Runner = true,
				}
				for _, p in ipairs(map:GetDescendants()) do
					if p:IsA("BasePart") and not KEEP[p.Name] and p.Transparency < 1 and not p:FindFirstChildWhichIsA("ProximityPrompt") then
						local c, s = p.CFrame, p.Size / 2
						local r, u, l = c.RightVector, c.UpVector, c.LookVector
						local h = Vector3.new(
							math.abs(r.X) * s.X + math.abs(u.X) * s.Y + math.abs(l.X) * s.Z,
							math.abs(r.Y) * s.X + math.abs(u.Y) * s.Y + math.abs(l.Y) * s.Z,
							math.abs(r.Z) * s.X + math.abs(u.Z) * s.Y + math.abs(l.Z) * s.Z
						)
						local lo, hi = c.Position - h, c.Position + h
						for _, b in ipairs(mansionClear) do
							if hi.X > b[1] and lo.X < b[4] and hi.Y > MY + b[2] and lo.Y < MY + b[5] and hi.Z > b[3] and lo.Z < b[6] then
								p:Destroy()
								break
							end
						end
					end
				end
			end
		end

		rng = oldRng
		Detail.useRng(oldDetailRng)
	end

	info.Messages = messages
	info.Notes = notes
	info.Bars = bars

	-----------------------------------------------------------------------
	-- enemies (CFrames are at standing height y = 3)
	-----------------------------------------------------------------------
	local function at(x, z, lx, lz)
		return CFrame.lookAt(Vector3.new(x, 3, z), Vector3.new(lx, 3, lz))
	end
	info.EnemySpawns = {
		{ Type = "Hollow", CFrame = at(-13, 78, 0, 78) }, -- waiting in the open west cell
		{ Type = "Hollow", CFrame = at(1, 106, 0, 130) }, -- staring at the locked gate
		{ Type = "Skeleton", CFrame = CFrame.lookAt(Vector3.new(28, -3, 50), Vector3.new(28, -3, 80)) }, -- foot of the ramp
		{ Type = "Skeleton", CFrame = CFrame.lookAt(Vector3.new(50, -3, 14), Vector3.new(23, -3, 14)) }, -- east run
		{ Type = "Skeleton", CFrame = CFrame.lookAt(Vector3.new(56, -3, 56), Vector3.new(63, -3, 40)) }, -- cistern
		{ Type = "Hollow", CFrame = CFrame.lookAt(Vector3.new(72, -3, 66), Vector3.new(63, -3, 80)) }, -- cistern
		{ Type = "Hollow", CFrame = at(63, 145, 63, 120) }, -- top of the ramp up
		{ Type = "Hollow", CFrame = at(-18, 150, 0, 120) },
		{ Type = "Jailer", CFrame = at(0, 188, 0, 150) }, -- guards the fog
		-- the Ruined Township: the prison's hounds, gone feral, in packs (Characters/Dog.lua)
		-- (each at least 10 studs from any other: a dog is long, and they mustn't start inside each other)
		{ Type = "Dog", CFrame = at(124, 252, 112, 240) }, -- the square: worrying at the gallows
		{ Type = "Dog", CFrame = at(126, 322, 130, 300) }, -- the lane
		{ Type = "Dog", CFrame = at(116, 372, 130, 360) }, -- at the church's rubble
		{ Type = "Dog", CFrame = at(192, 368, 170, 375) }, -- the upper town's street
		{ Type = "Dog", CFrame = at(180, 404, 186, 390) }, -- among the graves
		{ Type = "Dog", CFrame = at(196, 410, 186, 390) },
		{ Type = "Dog", CFrame = at(244, 360, 230, 375) }, -- guarding the last stretch
		{ Type = "Dog", CFrame = at(250, 388, 230, 375) },
		-- the Prison Ramparts (y 20): what's left of the watch, rattling about the walk
		{ Type = "Skeleton", CFrame = CFrame.lookAt(Vector3.new(66, 23.2, 316), Vector3.new(82, 23.2, 310)) },
		{ Type = "Skeleton", CFrame = CFrame.lookAt(Vector3.new(76, 23.2, 324), Vector3.new(82, 23.2, 310)) },
		{ Type = "Skeleton", CFrame = CFrame.lookAt(Vector3.new(64, 23.2, 325), Vector3.new(82, 23.2, 310)) },
		{ Type = "Skeleton", CFrame = CFrame.lookAt(Vector3.new(51, 23.2, 320), Vector3.new(60, 23.2, 316)) }, -- the west reach
		-- and on the prison's roof (y 42), where the old stair comes up
		{ Type = "Skeleton", CFrame = CFrame.lookAt(Vector3.new(8, 45.2, 292), Vector3.new(12, 45.2, 306)) },
		{ Type = "Skeleton", CFrame = CFrame.lookAt(Vector3.new(-20, 45.2, 285), Vector3.new(12, 45.2, 306)) },
		{ Type = "Skeleton", CFrame = CFrame.lookAt(Vector3.new(30, 45.2, 290), Vector3.new(0, 45.2, 296)) },
		-- along the yard walk (y 30), above the Ashen Yard
		{ Type = "Skeleton", CFrame = CFrame.lookAt(Vector3.new(46, 33.2, 182), Vector3.new(46, 33.2, 200)) },
		{ Type = "Skeleton", CFrame = CFrame.lookAt(Vector3.new(47, 33.2, 140), Vector3.new(47, 33.2, 160)) },
		-- the south corridor (y 30) and the west walk (y 38)
		{ Type = "Skeleton", CFrame = CFrame.lookAt(Vector3.new(0, 33.2, 114), Vector3.new(20, 33.2, 114)) },
		{ Type = "Skeleton", CFrame = CFrame.lookAt(Vector3.new(-46, 41.2, 175), Vector3.new(-46, 41.2, 150)) },
		-- the ravine over the Crossing (y 26): the Rotted (Characters/RotUsher.lua), one in the first stretch
		{ Type = "RotUsher", CFrame = CFrame.lookAt(Vector3.new(236, 29.2, 660), Vector3.new(236, 29.2, 620)) },
		{ Type = "RotUsher", CFrame = CFrame.lookAt(Vector3.new(288, 29.2, 684), Vector3.new(255, 29.2, 668)) }, -- round the first turn
		{ Type = "RotUsher", CFrame = CFrame.lookAt(Vector3.new(312, 29.2, 735), Vector3.new(312, 29.2, 700)) }, -- up the last stretch
		{ Type = "RotUsher", CFrame = CFrame.lookAt(Vector3.new(308, 29.2, 762), Vector3.new(312, 29.2, 700)) },
	}
	for _, sp in ipairs(info.MansionSpawns) do -- the Hollow Mansion's dead (built with the hall)
		table.insert(info.EnemySpawns, sp)
	end

	info.Zones = {
		{ Name = "Fallen Cellblock", MaxY = 12, MinX = -52, MaxX = -20, MinZ = 27, MaxZ = 97 }, -- (the lower hallway under the wing)
		{ Name = "Fallen Cellblock", MaxY = 12, MinX = -52, MaxX = 90, MinZ = -42, MaxZ = 30 }, -- (and its winding way out east)
		-- (first: everything up on the walls and roofs, above the areas underneath; MinY = feet-ish height)
		{ Name = "The Keep's Battlements", MinY = 66, MinX = -56, MaxX = 46, MinZ = 201, MaxZ = 275 },
		{ Name = "The Keep's Battlements", MinY = 66, MinX = 46, MaxX = 196, MinZ = 181, MaxZ = 221 }, -- the east wing
		{ Name = "The Keep's Battlements", MinY = 66, MinX = 176, MaxX = 196, MinZ = 221, MaxZ = 290 }, -- its north arm
		{ Name = "The Castellan's Keep", MinY = 40, MinX = -52, MaxX = 46, MinZ = 201, MaxZ = 275 },
		{ Name = "Prison Ramparts", MinY = 18, MinX = -56, MaxX = 86, MinZ = 105, MaxZ = 341 },
		{ Name = "Fallen Cellblock", MaxY = 12, MinX = -20, MaxX = 19, MinZ = -1, MaxZ = 119 },
		{ Name = "Drowned Passage", MaxY = 9, MinX = 19, MaxX = 35, MinZ = 83, MaxZ = 97 },
		{ Name = "Drowned Passage", MaxY = 9, MinX = 21, MaxX = 35, MinZ = 6, MaxZ = 85 },
		{ Name = "Drowned Passage", MaxY = 9, MinX = 21, MaxX = 71, MinZ = 6, MaxZ = 22 },
		{ Name = "Drowned Passage", MaxY = 9, MinX = 44, MaxX = 82, MinZ = 44, MaxZ = 76 }, -- the cistern: no banner of its own
		{ Name = "Drowned Passage", MaxY = 9, MinX = 55, MaxX = 71, MinZ = 18, MaxZ = 163 },
		{ Name = "Drowned Passage", MaxY = 9, MinX = 41, MaxX = 71, MinZ = 148, MaxZ = 163 },
		{ Name = "Drowned Passage", MaxY = 9, MinX = 27, MaxX = 49, MinZ = 95, MaxZ = 119 }, -- Wick's nook: no banner of its own
		{ Name = "Dim Yard", MinX = -41, MaxX = 40, MinZ = 121, MaxZ = 200 },
		{ Name = "The Blind Chapel", MinX = -137, MaxX = -86, MinZ = 133, MaxZ = 187 },
		{ Name = "The Blind Chapel", MinX = -125, MaxX = -99, MinZ = 187, MaxZ = 223 }, -- the reliquary: no banner of its own
		{ Name = "Ruined Township", MinX = 59, MaxX = 161, MinZ = 224, MaxZ = 296 }, -- Gallows Square
		{ Name = "Ruined Township", MinX = 99, MaxX = 161, MinZ = 295, MaxZ = 391 }, -- the Lane
		{ Name = "Ruined Township", MinX = 159, MaxX = 281, MinZ = 329, MaxZ = 421 }, -- the Upper Town
	}

	-- THE BLIND CHAPEL, FORTIFIED (seen from the walls it was a bare box): a crenellated
	-- parapet round its roof, four corner towers standing clear of the nave, stepped
	-- buttresses down its long walls, a squat belfry over the east door, and battlements
	-- on the Usher's walk and the reliquary. All outside the rooms (the fight is untouched).
	do
		local oldRng = rng
		rng = Random.new(7741) -- (its own stream: nothing else shifts)
		local X1, X2, Z1, Z2, H, ROOFTOP = -138, -84, 132, 188, 28, 30
		-- the roof's parapet, and merlons along it
		box(X1, ROOFTOP, Z1, X2, ROOFTOP + 3, Z1 + 1.2, MAT.Cobblestone, stoneColor(), "Parapet")
		box(X1, ROOFTOP, Z2 - 1.2, X2, ROOFTOP + 3, Z2, MAT.Cobblestone, stoneColor(), "Parapet")
		box(X1, ROOFTOP, Z1, X1 + 1.2, ROOFTOP + 3, Z2, MAT.Cobblestone, stoneColor(), "Parapet")
		box(X2 - 1.2, ROOFTOP, Z1, X2, ROOFTOP + 3, Z2, MAT.Cobblestone, stoneColor(), "Parapet")
		crenellate(X1 + 6, Z1 + 0.6, X2 - 6, Z1 + 0.6, ROOFTOP + 3)
		crenellate(X1 + 6, Z2 - 0.6, X2 - 6, Z2 - 0.6, ROOFTOP + 3)
		crenellate(X1 + 0.6, Z1 + 6, X1 + 0.6, Z2 - 6, ROOFTOP + 3)
		crenellate(X2 - 0.6, Z1 + 6, X2 - 0.6, Z2 - 6, ROOFTOP + 3)
		-- corner towers, each overlapping the corner from outside
		local TOP = 42
		for _, t in ipairs({ { X1 - 8, Z1 - 8 }, { X2 - 2, Z1 - 8 }, { X1 - 8, Z2 - 2 }, { X2 - 2, Z2 - 2 } }) do
			local x1, z1, x2, z2 = t[1], t[2], t[1] + 10, t[2] + 10
			box(x1, 0, z1, x2, TOP, z2, MAT.Cobblestone, stoneColor(), "ChapelTower")
			box(x1 - 0.6, 0, z1 - 0.6, x2 + 0.6, 1.4, z2 + 0.6, MAT.Slate, COL.WallDark, "TowerPlinth")
			box(x1 - 0.5, TOP - 6, z1 - 0.5, x2 + 0.5, TOP - 5.3, z2 + 0.5, MAT.Slate, COL.Wall, "TowerCourse")
			box(x1 - 0.7, TOP - 1, z1 - 0.7, x2 + 0.7, TOP, z2 + 0.7, MAT.Slate, COL.Wall, "TowerCap")
			crenellate(x1, z1, x2, z1, TOP)
			crenellate(x1, z2, x2, z2, TOP)
			crenellate(x1, z1, x1, z2, TOP)
			crenellate(x2, z1, x2, z2, TOP)
			for _, y in ipairs({ 12, 24 }) do -- arrow slits on the outward faces
				box((x1 + x2) / 2 - 0.3, y, z1 - 0.05, (x1 + x2) / 2 + 0.3, y + 3.5, z1 + 0.05, MAT.Slate, Color3.fromRGB(8, 8, 10), "ArrowSlit")
				box((x1 + x2) / 2 - 0.3, y, z2 - 0.05, (x1 + x2) / 2 + 0.3, y + 3.5, z2 + 0.05, MAT.Slate, Color3.fromRGB(8, 8, 10), "ArrowSlit")
			end
		end
		-- stepped buttresses (clear of the reliquary's corridor on the north)
		local function buttress(x1, z1, x2, z2, nx, nz) -- footprint against the wall, n = outward
			box(x1, 0, z1, x2, H - 6, z2, MAT.Cobblestone, stoneColor(), "Buttress")
			-- the upper step: only the half against the wall
			local ux1, uz1, ux2, uz2 = x1, z1, x2, z2
			if nx < 0 then
				ux1 = x1 + 1.2
			elseif nx > 0 then
				ux2 = x2 - 1.2
			end
			if nz < 0 then
				uz1 = z1 + 1.2
			elseif nz > 0 then
				uz2 = z2 - 1.2
			end
			box(ux1, H - 6, uz1, ux2, H - 2, uz2, MAT.Cobblestone, stoneColor(), "Buttress")
			box(x1 - 0.2, H - 6.4, z1 - 0.2, x2 + 0.2, H - 6, z2 + 0.2, MAT.Slate, COL.Wall, "ButtressCap")
		end
		for _, x in ipairs({ -128, -116, -104, -94 }) do
			buttress(x - 1.2, Z1 - 3, x + 1.2, Z1, 0, -1)
		end
		for _, x in ipairs({ -128, -98, -92 }) do
			buttress(x - 1.2, Z2, x + 1.2, Z2 + 3, 0, 1)
		end
		for _, z in ipairs({ 144, 156, 168, 178 }) do
			buttress(X1 - 3, z - 1.2, X1, z + 1.2, -1, 0)
		end
		-- the belfry over the east door: a squat block on the roof, crenellated
		box(-100, ROOFTOP, 150, -86, ROOFTOP + 13, 170, MAT.Cobblestone, stoneColor(), "Belfry")
		box(-100.5, ROOFTOP + 9, 149.5, -85.5, ROOFTOP + 9.6, 170.5, MAT.Slate, COL.Wall, "BelfryCourse")
		crenellate(-100, 150, -86, 150, ROOFTOP + 13)
		crenellate(-100, 170, -86, 170, ROOFTOP + 13)
		crenellate(-100, 150, -100, 170, ROOFTOP + 13)
		box(-93.6, ROOFTOP + 4, 149.9, -92.4, ROOFTOP + 8.5, 150.1, MAT.Slate, Color3.fromRGB(8, 8, 10), "ArrowSlit")
		box(-93.6, ROOFTOP + 4, 169.9, -92.4, ROOFTOP + 8.5, 170.1, MAT.Slate, Color3.fromRGB(8, 8, 10), "ArrowSlit")
		-- battlements on the Usher's walk (14 high) and on the reliquary (16 high)
		crenellate(-82, 155, -42, 155, 14)
		crenellate(-82, 165, -42, 165, 14)
		crenellate(-124, 205, -100, 205, 16)
		crenellate(-124, 223, -100, 223, 16)
		crenellate(-125, 207, -125, 221, 16)
		crenellate(-99, 207, -99, 221, 16)
		rng = oldRng
	end

	-- beyond the Upper Town's north edge, walled off from it by cliffs: a rotted encampment
	-- sunk in a pit, where the thing that answers the bell sets you down. Shacks gone soft and
	-- crooked on their stilts, timber towers and scaffolds, pools of slime - and out of nearly everything,
	-- the same spindly grey arms the thing had (anchors tagged "RotLimb"; the clients grow and
	-- twitch them, ReplicatedStorage/Carrier.growths). The only way out of the pit is up the
	-- rotten walkway on stilts: three stairs and three turns to the ledge along its north side.
	do
		local X1, Z1, X2, Z2 = 170, 452, 280, 540
		local LEDGE_Z, LEDGE_Y = 520, 26
		local er = Random.new(4040) -- (its own streams: nothing else shifts)
		local oldDetailRng = Detail.useRng(Random.new(4041))
		local function n(a, b)
			return er:NextNumber(a, b)
		end
		local Rot = Detail.Rot
		local WOOD, WOOD_DARK = Color3.fromRGB(58, 46, 34), Color3.fromRGB(38, 31, 24)
		local function wood()
			return WOOD:Lerp(WOOD_DARK, n(0, 1)):Lerp(Rot.Mold, n(0, 0.35))
		end
		local function plank(size, cf, color)
			return part({ Name = "RotPlank", Size = size, CFrame = cf, Material = MAT.WoodPlanks, Color = color or wood() })
		end
		local function beam(a, b, thick, color) -- a timber from a to b, no collision
			local d = b - a
			return part({ Name = "RotBeam", Size = Vector3.new(thick, thick, d.Magnitude), CFrame = CFrame.lookAt((a + b) / 2, b), Material = MAT.Wood, Color = color or wood(), CanCollide = false })
		end
		local function limb(pos, dir, scale) -- where one of the arms grows from
			local p = part({ Name = "RotLimbRoot", Size = Vector3.new(0.4, 0.4, 0.4), CFrame = CFrame.lookAt(pos, pos + dir), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
			p:SetAttribute("Scale", scale or 1)
			p:SetAttribute("Seed", er:NextInteger(1, 1e6))
			CollectionService:AddTag(p, "RotLimb")
			part({ Name = "RotKnot", Shape = Enum.PartType.Ball, Size = Vector3.one * n(0.8, 1.6) * (scale or 1), CFrame = CFrame.new(pos), Material = MAT.SmoothPlastic, Color = Rot.Flesh:Lerp(Rot.FleshDark, n(0, 1)), Reflectance = 0.12, CanCollide = false })
		end
		local function randDir(bias)
			local d = Vector3.new(n(-1, 1), n(-1, 1), n(-1, 1)) + (bias or Vector3.zero)
			return d.Magnitude > 0.01 and d.Unit or Vector3.new(0, 1, 0)
		end
		local function stilt(x, z, top, bottom)
			bottom = bottom or 0
			local tilt = CFrame.Angles(n(-0.05, 0.05), 0, n(-0.05, 0.05))
			part({ Name = "Stilt", Size = Vector3.new(0.7, top - bottom + 0.4, 0.7), CFrame = CFrame.new(x, (top + bottom) / 2, z) * tilt, Material = MAT.Wood, Color = wood() })
			if er:NextNumber() < 0.25 then
				Detail.boils(Vector3.new(x, bottom, z), 3, 1.2, 0.2)
			end
		end
		-- a run of posts and a top rail along a line; some of it rotted away
		local function rail(a, b, y)
			local d = b - a
			local steps = math.max(1, math.floor(d.Magnitude / 3))
			for i = 0, steps do
				local p = a:Lerp(b, i / steps)
				if er:NextNumber() > 0.15 then
					part({ Name = "RailPost", Size = Vector3.new(0.35, 3, 0.35), CFrame = CFrame.new(p.X, y + 1.5, p.Z) * CFrame.Angles(n(-0.1, 0.1), 0, n(-0.1, 0.1)), Material = MAT.Wood, Color = wood() })
				end
				if i < steps and er:NextNumber() > 0.2 then
					local q = a:Lerp(b, (i + 1) / steps)
					beam(Vector3.new(p.X, y + 2.8 + n(-0.2, 0.1), p.Z), Vector3.new(q.X, y + 2.8 + n(-0.2, 0.1), q.Z), 0.3)
				end
			end
		end
		-- a stilted deck: top at y, posts down to the ground, rails on the closed sides
		local function platform(x1, z1, x2, z2, y, rails)
			for x = x1, x2 - 1, 1.2 do -- loose planks, crosswise
				plank(Vector3.new(1.1, 0.5, z2 - z1 + n(-0.4, 0.3)), CFrame.new(x + 0.6, y - 0.25 + n(-0.06, 0.04), (z1 + z2) / 2 + n(-0.2, 0.2)) * CFrame.Angles(0, n(-0.03, 0.03), n(-0.03, 0.03)))
			end
			box(x1, y - 1.1, z1, x2, y - 0.5, z2, MAT.Wood, WOOD_DARK, "Joist")
			for _, c in ipairs({ { x1 + 0.5, z1 + 0.5 }, { x2 - 0.5, z1 + 0.5 }, { x1 + 0.5, z2 - 0.5 }, { x2 - 0.5, z2 - 0.5 }, { (x1 + x2) / 2, (z1 + z2) / 2 } }) do
				stilt(c[1], c[2], y - 1)
			end
			beam(Vector3.new(x1 + 0.5, 1, z1 + 0.5), Vector3.new(x2 - 0.5, y - 1.5, z2 - 0.5), 0.4) -- a cross-brace
			for _, r in ipairs(rails or {}) do
				local a = ({ S = Vector3.new(x1, 0, z1), N = Vector3.new(x1, 0, z2), W = Vector3.new(x1, 0, z1), E = Vector3.new(x2, 0, z1) })[r]
				local b = ({ S = Vector3.new(x2, 0, z1), N = Vector3.new(x2, 0, z2), W = Vector3.new(x1, 0, z2), E = Vector3.new(x2, 0, z2) })[r]
				rail(a, b, y)
			end
		end
		-- a walkway along z (x centred on cx), top at y, from za to zb
		local function walkway(cx, za, zb, y)
			for z = za, zb - 1, 1.1 do
				plank(Vector3.new(4 + n(-0.3, 0.4), 0.5, 1.0), CFrame.new(cx + n(-0.2, 0.2), y - 0.25 + n(-0.08, 0.03), z + 0.55) * CFrame.Angles(n(-0.04, 0.04), n(-0.08, 0.08), n(-0.03, 0.03)))
			end
			for _, sx in ipairs({ -2.2, 2.2 }) do
				box(cx + sx - 0.3, y - 1.1, za, cx + sx + 0.3, y - 0.5, zb, MAT.Wood, WOOD_DARK, "Stringer")
				for z = za + 1, zb - 1, 5 do
					stilt(cx + sx, z, y - 1)
				end
				rail(Vector3.new(cx + sx, 0, za), Vector3.new(cx + sx, 0, zb), y)
			end
		end
		-- a stilted stair: n steps of rise 1 along dir from base (the floor it starts from)
		local function stair(base, dir, steps, run)
			local side = Vector3.new(-dir.Z, 0, dir.X)
			for i = 1, steps do
				local c = base + dir * (i - 0.5) * run + Vector3.new(0, i, 0)
				local look = CFrame.lookAt(c, c + dir) * CFrame.Angles(n(-0.03, 0.03), n(-0.05, 0.05), n(-0.04, 0.04))
				plank(Vector3.new(4.2, 0.5, run + 0.3), look * CFrame.new(0, -0.25, 0))
				if i % 2 == 0 then
					for _, s in ipairs({ -2, 2 }) do
						local p = c + side * s
						stilt(p.X, p.Z, c.Y - 0.6, base.Y > 0 and 0 or nil)
					end
				end
			end
			local top = base + dir * steps * run + Vector3.new(0, steps, 0)
			for _, s in ipairs({ -2.2, 2.2 }) do -- the stringers each side, and a handrail up the slope
				local a, b = base + side * s, top + side * s
				beam(a + Vector3.new(0, 0.2, 0), b - Vector3.new(0, 0.6, 0), 0.5)
				for k = 0, steps, 3 do
					if er:NextNumber() > 0.2 then
						local p = a:Lerp(b, k / steps)
						part({ Name = "RailPost", Size = Vector3.new(0.35, 3, 0.35), CFrame = CFrame.new(p + Vector3.new(0, 1.5, 0)) * CFrame.Angles(n(-0.1, 0.1), 0, n(-0.1, 0.1)), Material = MAT.Wood, Color = wood() })
					end
				end
				if er:NextNumber() > 0.25 then
					beam(a + Vector3.new(0, 2.9, 0), b + Vector3.new(0, 2.9, 0), 0.3)
				end
			end
		end

		-- the pit's floor, and the cliffs that close it in (rock on rot: unclimbable)
		box(X1, -4, Z1, X2, 0, Z2, MAT.Ground, Color3.fromRGB(46, 42, 36), "Ground")
		Detail.rotPatches(X1 + 2, Z1 + 2, X2 - 2, LEDGE_Z - 2, 18, 0)
		local function cliff(ax, az, bx, bz, ox, oz) -- along a side, o = outward
			local d = Vector3.new(bx - ax, 0, bz - az)
			local len = d.Magnitude
			local u = d.Unit
			local s = 0
			while s < len do
				local w = math.min(n(6, 11), len - s)
				local p = Vector3.new(ax, 0, az) + u * (s + w / 2)
				local h, t = n(38, 52), n(4, 7)
				local c = p + Vector3.new(ox, 0, oz) * (t / 2)
				part({ Name = "Cliff", Size = Vector3.new(math.abs(u.X) * (w + 1) + math.abs(ox) * t, h, math.abs(u.Z) * (w + 1) + math.abs(oz) * t), CFrame = CFrame.new(c.X, h / 2 - 2, c.Z) * CFrame.Angles(0, n(-0.04, 0.04), 0), Material = MAT.Rock, Color = Color3.fromRGB(50, 46, 42):Lerp(Rot.Stone, n(0, 1)):Lerp(Rot.FleshDark, n(0, 0.3)) })
				if er:NextNumber() < 0.5 then -- a bulge of rock at its foot (too tall to step onto)
					local bh = n(7, 14)
					local bc = p - Vector3.new(ox, 0, oz) * 1.2
					part({ Name = "CliffFoot", Size = Vector3.new(math.abs(u.X) * w * 0.6 + math.abs(ox) * 3, bh, math.abs(u.Z) * w * 0.6 + math.abs(oz) * 3), CFrame = CFrame.new(bc.X, bh / 2, bc.Z) * CFrame.Angles(0, n(-0.2, 0.2), 0), Material = MAT.Rock, Color = Color3.fromRGB(44, 40, 36):Lerp(Rot.Mold, n(0, 0.4)) })
				end
				if er:NextNumber() < 0.35 then
					limb(p - Vector3.new(ox, 0, oz) * 0.5 + Vector3.new(0, n(4, 22), 0), randDir(-Vector3.new(ox, 0, oz) * 1.5), n(0.9, 1.5))
				end
				s += w
			end
		end
		cliff(X1, Z1, X2, Z1, 0, -1)
		cliff(X1, Z2, 228, Z2, 0, 1) -- (the gap between is where the crossing starts)
		cliff(240, Z2, X2, Z2, 0, 1)
		cliff(X1, Z1, X1, Z2, -1, 0)
		cliff(X2, Z1, X2, Z2, 1, 0)
		-- the ledge along the north: its face sheer and lumpy, its top the camp's upper floor
		box(X1, 0, LEDGE_Z, X2, LEDGE_Y, Z2, MAT.Ground, Color3.fromRGB(48, 44, 38), "Ledge")
		for x = X1, X2 - 6, 6 do
			local h = n(10, LEDGE_Y + 2)
			if not (x > 226 and x < 242) then -- (clear of where the stair lands)
				part({ Name = "LedgeFace", Size = Vector3.new(n(5, 8), h, n(1.5, 3)), CFrame = CFrame.new(x + 3, h / 2, LEDGE_Z - 0.6) * CFrame.Angles(0, n(-0.15, 0.15), 0), Material = MAT.Rock, Color = Color3.fromRGB(46, 42, 38):Lerp(Rot.Flesh, n(0, 0.3)) })
			end
			if er:NextNumber() < 0.4 then
				limb(Vector3.new(x + n(0, 6), n(5, 22), LEDGE_Z - 1.2), randDir(Vector3.new(0, 0, -1.5)), n(0.8, 1.3))
			end
		end

		-- THE WAY UP: east up the first stair, north along the walkway, west up the second
		-- stair, north along the next walkway, up the third onto the ledge
		stair(Vector3.new(240, 0, 470), Vector3.new(1, 0, 0), 10, 1.6) -- to y 10
		platform(256, 466, 264, 474, 10, { "S", "E" })
		walkway(260, 474, 494, 10)
		platform(255, 494, 265, 502, 10, { "N", "E" })
		stair(Vector3.new(255, 10, 498), Vector3.new(-1, 0, 0), 10, 1.6) -- to y 20
		platform(229, 494, 239, 502, 20, { "S", "W" })
		walkway(234, 502, 514, 20)
		stair(Vector3.new(234, 20, 514), Vector3.new(0, 0, 1), 6, 1.0) -- onto the ledge (y 26)
		-- arms reaching from under the walk, clawing at whoever crosses
		for _, p in ipairs({ { 258, 3, 480 }, { 262, 5, 488 }, { 252, 6, 497 }, { 244, 9, 500 }, { 236, 12, 496 }, { 232, 14, 506 }, { 237, 15, 510 }, { 262, 2, 468 } }) do
			limb(Vector3.new(p[1], p[2], p[3]), randDir(Vector3.new(0, 1.4, 0)), n(0.9, 1.3))
		end

		-- crooked shacks: on short stilts, walls leaning, roofs sagging, gone to rot
		local function shack(cx, cz, floorY, w, d, h, yaw, door)
			local cf = CFrame.new(cx, floorY, cz) * CFrame.Angles(0, yaw, 0)
			local lean = CFrame.Angles(n(-0.08, 0.08), 0, n(-0.1, 0.1))
			if floorY > 0 then
				for _, c in ipairs({ { -w / 2, -d / 2 }, { w / 2, -d / 2 }, { -w / 2, d / 2 }, { w / 2, d / 2 } }) do
					local p = cf * Vector3.new(c[1], 0, c[2])
					stilt(p.X, p.Z, floorY)
				end
			end
			plank(Vector3.new(w, 0.5, d), cf * CFrame.new(0, 0.25, 0))
			local body = cf * lean
			for i, side in ipairs({ { 0, -d / 2, w, 0 }, { 0, d / 2, w, 0 }, { -w / 2, 0, d, math.pi / 2 }, { w / 2, 0, d, math.pi / 2 } }) do
				-- each wall: boards, a few missing
				local wallCf = body * CFrame.new(side[1], h / 2 + 0.5, side[2]) * CFrame.Angles(0, side[4], 0)
				for b = -side[3] / 2 + 0.6, side[3] / 2 - 0.6, 1.2 do
					if er:NextNumber() > 0.18 then
						local p = plank(Vector3.new(1.1, h * n(0.75, 1.05), 0.3), wallCf * CFrame.new(b, n(-0.3, 0), 0) * CFrame.Angles(0, 0, n(-0.06, 0.06)))
						if door and i == 1 and math.abs(b) < 1.6 then
							p:Destroy() -- a doorway in the front (built then pulled, so the camp's random stream doesn't shift)
						end
					end
				end
			end
			if door then
				-- a crate to step up to the door on (fixed colour: draws nothing from the stream)
				plank(Vector3.new(2.6, 1.3, 1.6), cf * CFrame.new(-0.3, -1.4, -d / 2 - 1.1), WOOD_DARK) -- (top 0.75 below the floor)
			end
			-- the roof: two slabs, sagging in the middle and torn
			for _, sx in ipairs({ -1, 1 }) do
				plank(Vector3.new(w / 2 + 1, 0.4, d + 1.2), body * CFrame.new(sx * w / 4, h + 1.4 - n(0, 0.6), 0) * CFrame.Angles(n(-0.05, 0.05), 0, -sx * n(0.3, 0.5)), WOOD_DARK:Lerp(Rot.Mold, n(0.2, 0.6)))
			end
			-- rot coming through it, and arms out of the rot
			Detail.boils((cf * CFrame.new(n(-w / 3, w / 3), 0.5, n(-d / 3, d / 3))).Position, er:NextInteger(3, 7), 1.6, 0.3)
			for _ = 1, er:NextInteger(2, 4) do
				local fx = er:NextNumber() < 0.5 and -1 or 1
				local at = body * Vector3.new(fx * w / 2, n(1.5, h), n(-d / 2.5, d / 2.5))
				limb(at, randDir((body:VectorToWorldSpace(Vector3.new(fx, 0, 0))) * 1.5), n(0.8, 1.2))
			end
			if er:NextNumber() < 0.6 then
				limb(body * Vector3.new(n(-w / 3, w / 3), h + 1.6, n(-d / 3, d / 3)), randDir(Vector3.new(0, 1.5, 0)), n(1, 1.4))
			end
		end
		for _, s in ipairs({
			{ 184, 462, 3, 8, 7, 7, 0.2 }, { 200, 478, 2, 7, 6, 6, -0.3 }, { 183, 500, 4, 9, 7, 8, 0.1 },
			{ 208, 504, 0, 7, 6, 6, 0.5 }, { 206, 462, 2.5, 6, 6, 6, -0.1 }, { 272, 463, 3, 7, 7, 7, 1.4 },
			{ 273, 488, 2, 6, 8, 6, 1.6 }, { 274, 510, 3.5, 6, 6, 7, 1.2 }, { 219, 498, 1.5, 6, 5, 5, 0.9 },
		}) do
			shack(s[1], s[2], s[3], s[4], s[5], s[6], s[7])
		end
		-- up on the ledge: the camp proper, bigger and worse
		for _, s in ipairs({
			{ 186, 530, LEDGE_Y + 2, 10, 8, 8, 0.1 }, { 204, 531, LEDGE_Y + 3, 8, 8, 7, -0.2 }, { 256, 530, LEDGE_Y + 2, 9, 8, 8, 0.25, true }, { 272, 532, LEDGE_Y + 1, 7, 7, 6, -0.4 },
		}) do
			shack(s[1], s[2], s[3], s[4], s[5], s[6], s[7], s[8])
		end
		-- Wretch Giles (Characters/Taylor) sits just inside the doored shack's doorway, framed in it, looking out at the walkway
		local gilesShack = CFrame.new(256, LEDGE_Y + 2.5, 530) * CFrame.Angles(0, 0.25, 0)
		info.Taylor = CFrame.lookAt(gilesShack * Vector3.new(0, 0, -1.6), gilesShack * Vector3.new(0, 0, -10))

		-- MALFORMED WOODWORK: everything else here is timber gone wrong. None of it can be
		-- reached: decks stand well over head height, nothing climbs to them, and all of it
		-- keeps clear of the walkway. (Braces and rails have no collision; posts and decks do.)
		local function timber(a, b, thick, solid, color)
			local d = b - a
			return part({ Name = "RotTimber", Size = Vector3.new(thick, thick, d.Magnitude), CFrame = CFrame.lookAt((a + b) / 2, b), Material = MAT.Wood, Color = color or wood(), CanCollide = solid == true })
		end
		local function deck(cx, cz, y, w, d, yaw, coverage) -- loose planks over a frame, some missing
			local cf = CFrame.new(cx, y, cz) * CFrame.Angles(0, yaw or 0, 0)
			for x = -w / 2 + 0.6, w / 2 - 0.6, 1.2 do
				if er:NextNumber() < (coverage or 0.85) then
					plank(Vector3.new(1.1, 0.45, d + n(-0.6, 0.3)), cf * CFrame.new(x, -0.22 + n(-0.08, 0.05), n(-0.3, 0.3)) * CFrame.Angles(n(-0.04, 0.04), n(-0.05, 0.05), n(-0.05, 0.05)))
				elseif er:NextNumber() < 0.5 then -- a broken one, hanging off
					plank(Vector3.new(1.1, 0.45, d * 0.6), cf * CFrame.new(x, -1.4, d / 2) * CFrame.Angles(n(0.8, 1.3), 0, n(-0.2, 0.2))).CanCollide = false
				end
			end
		end
		-- a crooked tower of timber: four posts leaning in to a point off-centre, bound with
		-- crossbeams, a scrap of deck here and there, a torn roof, things hanging off it
		local function woodSpire(x, z, h, baseY)
			baseY = baseY or 0
			local base = Vector3.new(x, baseY, z)
			local topC = base + Vector3.new(n(-2.5, 2.5), h, n(-2.5, 2.5))
			local corners = {}
			for i = 1, 4 do
				local a = i / 4 * math.pi * 2 + n(-0.3, 0.3)
				local foot = base + Vector3.new(math.cos(a), 0, math.sin(a)) * n(2.6, 3.4)
				local head = topC + Vector3.new(math.cos(a), 0, math.sin(a)) * n(0.4, 0.9)
				timber(foot, head, n(0.6, 0.9)) -- (not solid: no walking up a leaning post)
				corners[i] = { foot, head }
			end
			local level = n(4, 5.5)
			while level < h - 2 do
				local k = level / h
				for i = 1, 4 do
					local a, b = corners[i], corners[i % 4 + 1]
					if er:NextNumber() > 0.15 then
						timber(a[1]:Lerp(a[2], k) + Vector3.new(0, n(-0.4, 0.4), 0), b[1]:Lerp(b[2], k) + Vector3.new(0, n(-0.4, 0.4), 0), 0.4)
					end
					if er:NextNumber() < 0.35 then -- a diagonal brace up to the next level
						timber(a[1]:Lerp(a[2], k), b[1]:Lerp(b[2], math.min(k + 0.2, 1)), 0.3)
					end
				end
				if level > 6 and er:NextNumber() < 0.45 then
					local c = base:Lerp(topC, k)
					deck(c.X, c.Z, c.Y, 3.6 * (1 - k * 0.6), 3.6 * (1 - k * 0.6), n(0, 6), 0.6)
				end
				if er:NextNumber() < 0.45 then
					local c = corners[er:NextInteger(1, 4)]
					limb(c[1]:Lerp(c[2], k), randDir(), n(0.9, 1.4))
				end
				level += n(3.5, 5.5)
			end
			-- the roof: two planks propped on the top, one slipped
			for _, sx in ipairs({ -1, 1 }) do
				plank(Vector3.new(3.4, 0.35, 4.4), CFrame.new(topC + Vector3.new(sx * 1.1, 0.8, 0)) * CFrame.Angles(n(-0.2, 0.2), n(0, 6), -sx * n(0.4, 0.9)), WOOD_DARK:Lerp(Rot.Mold, n(0.2, 0.5))).CanCollide = false
			end
			-- something hanging from it on a rope: a bundle, or a cage
			local hangFrom = base:Lerp(topC, n(0.5, 0.8)) + Vector3.new(n(-1, 1), 0, n(-1, 1))
			local drop = n(3, 6)
			timber(hangFrom, hangFrom - Vector3.new(0, drop, 0), 0.12, false, Color3.fromRGB(110, 96, 70))
			if er:NextNumber() < 0.5 then
				local cc = hangFrom - Vector3.new(0, drop + 1.2, 0)
				for i = 1, 6 do
					local a = i / 6 * math.pi * 2
					timber(cc + Vector3.new(math.cos(a), -1.2, math.sin(a)), cc + Vector3.new(math.cos(a) * 0.7, 1.2, math.sin(a) * 0.7), 0.12, false, Color3.fromRGB(46, 40, 34))
				end
			else
				part({ Name = "Bundle", Size = Vector3.new(1.2, 2, 1), CFrame = CFrame.new(hangFrom - Vector3.new(0, drop + 1, 0)) * CFrame.Angles(0, n(0, 6), n(-0.2, 0.2)), Material = MAT.Fabric, Color = Color3.fromRGB(58, 50, 40), CanCollide = false })
			end
			limb(topC, randDir(Vector3.new(0, 1.2, 0)), n(1.1, 1.6))
		end
		-- a watchtower: four splayed legs, X-braced, a crow's nest with a rail and a slanted roof
		local function watchtower(x, z, h, baseY)
			baseY = baseY or 0
			local lean = Vector3.new(n(-1.5, 1.5), 0, n(-1.5, 1.5))
			local feet, tops = {}, {}
			for i, c in ipairs({ { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }) do
				feet[i] = Vector3.new(x + c[1] * 3.2, baseY, z + c[2] * 3.2)
				tops[i] = Vector3.new(x + c[1] * 2.2, baseY + h, z + c[2] * 2.2) + lean
				timber(feet[i], tops[i] + Vector3.new(0, 5, 0), 0.7, true)
			end
			for y = 5, h - 2, 5 do
				local k = y / h
				for i = 1, 4 do
					local j = i % 4 + 1
					if er:NextNumber() > 0.2 then
						timber(feet[i]:Lerp(tops[i], k), feet[j]:Lerp(tops[j], math.min(k + 5 / h, 1)), 0.3)
						timber(feet[j]:Lerp(tops[j], k), feet[i]:Lerp(tops[i], math.min(k + 5 / h, 1)), 0.3)
					end
				end
			end
			local c = Vector3.new(x, baseY + h, z) + lean
			deck(c.X, c.Z, c.Y, 6, 6, 0, 0.9)
			for i = 1, 4 do -- its rail, half gone
				if er:NextNumber() > 0.3 then
					local j = i % 4 + 1
					timber(tops[i] + Vector3.new(0, 2.6, 0), tops[j] + Vector3.new(0, 2.6 + n(-0.4, 0.2), 0), 0.25)
				end
			end
			plank(Vector3.new(7.5, 0.35, 7.5), CFrame.new(c + Vector3.new(0, 5.6, 0)) * CFrame.Angles(n(-0.35, -0.15), n(0, 6), n(-0.2, 0.2)), WOOD_DARK:Lerp(Rot.Mold, n(0.2, 0.6))).CanCollide = false
			-- a ladder that rotted off well short of the ground
			local lf = (feet[1] + feet[2]) / 2
			local lt = (tops[1] + tops[2]) / 2
			for _, s in ipairs({ -0.6, 0.6 }) do
				timber(lf:Lerp(lt, 0.45) + Vector3.new(s, 0, 0), lt + Vector3.new(s, 0, 0), 0.2)
			end
			for k = 0.5, 0.95, 0.07 do
				if er:NextNumber() > 0.25 then
					local p = lf:Lerp(lt, k)
					timber(p - Vector3.new(0.6, 0, 0), p + Vector3.new(0.6, 0, 0), 0.15)
				end
			end
			for _ = 1, 2 do
				limb(feet[er:NextInteger(1, 4)]:Lerp(tops[1], n(0.2, 0.8)), randDir(), n(0.9, 1.3))
			end
		end
		-- a hut up on tall braced stilts (a shack, raised out of reach, X-braces between its legs)
		local function stiltHut(cx, cz, floorY, w, d, h, yaw, baseY)
			shack(cx, cz, floorY, w, d, h, yaw)
			baseY = baseY or 0
			local cf = CFrame.new(cx, 0, cz) * CFrame.Angles(0, yaw, 0)
			local c = {}
			for i, o in ipairs({ { -w / 2, -d / 2 }, { w / 2, -d / 2 }, { w / 2, d / 2 }, { -w / 2, d / 2 } }) do
				c[i] = cf * Vector3.new(o[1], 0, o[2])
			end
			for i = 1, 4 do
				local j = i % 4 + 1
				if er:NextNumber() > 0.25 then
					timber(Vector3.new(c[i].X, baseY + 1, c[i].Z), Vector3.new(c[j].X, floorY - 1, c[j].Z), 0.35)
				end
				if er:NextNumber() > 0.4 then
					timber(Vector3.new(c[j].X, baseY + 1, c[j].Z), Vector3.new(c[i].X, floorY - 1, c[i].Z), 0.35)
				end
			end
		end
		-- scaffolding: a cage of posts and beams with scraps of deck at each level
		local function scaffold(x1, z1, x2, z2, levels)
			local top = levels[#levels]
			local posts = {}
			for x = x1, x2, (x2 - x1) / math.max(1, math.floor((x2 - x1) / 5)) do
				for _, z in ipairs({ z1, z2 }) do
					local foot = Vector3.new(x + n(-0.3, 0.3), 0, z)
					timber(foot, foot + Vector3.new(n(-0.6, 0.6), top + 3, n(-0.4, 0.4)), 0.55, true)
					table.insert(posts, foot)
				end
			end
			for _, y in ipairs(levels) do
				timber(Vector3.new(x1, y - 0.8, z1), Vector3.new(x2, y - 0.8 + n(-0.5, 0.5), z1), 0.45)
				timber(Vector3.new(x1, y - 0.8, z2), Vector3.new(x2, y - 0.8 + n(-0.5, 0.5), z2), 0.45)
				deck((x1 + x2) / 2, (z1 + z2) / 2, y, x2 - x1, z2 - z1 - 0.4, 0, 0.6)
			end
			for _ = 1, 3 do
				local p = posts[er:NextInteger(1, #posts)]
				limb(p + Vector3.new(0, n(3, top), 0), randDir(), n(0.9, 1.3))
			end
		end
		-- a line of sharpened stakes leaning every which way, some fallen
		local function palisade(a, b)
			local d = b - a
			for s = 0, d.Magnitude, 1.4 do
				if er:NextNumber() > 0.12 then
					local p = a + d.Unit * s
					local hgt = n(6, 12)
					local cf = CFrame.new(p) * CFrame.Angles(n(-0.18, 0.18), n(0, 6), n(-0.18, 0.18))
					part({ Name = "Stake", Size = Vector3.new(0.7, hgt, 0.7), CFrame = cf * CFrame.new(0, hgt / 2, 0), Material = MAT.Wood, Color = wood() })
					part({ Name = "StakePoint", Size = Vector3.new(0.5, 0.9, 0.5), CFrame = cf * CFrame.new(0, hgt + 0.3, 0) * CFrame.Angles(math.pi / 4, 0, math.pi / 4), Material = MAT.Wood, Color = WOOD_DARK, CanCollide = false })
					if er:NextNumber() < 0.08 then
						limb(p + Vector3.new(0, hgt * 0.7, 0), randDir(Vector3.new(0, 1, 0)), n(0.8, 1.1))
					end
				end
			end
		end

		-- the old rot spires, as crooked timber towers
		woodSpire(194, 489, 22)
		woodSpire(214, 470, 16)
		woodSpire(271, 499, 18)
		woodSpire(190, 474, 14)
		woodSpire(222, 533, 20, LEDGE_Y)
		woodSpire(246, 533, 16, LEDGE_Y)
		-- in the pit
		watchtower(176, 513, 16)
		watchtower(276, 456, 14)
		watchtower(226, 456, 12)
		stiltHut(247, 484, 16, 7, 7, 6, 0.3) -- in the loop of the walkway, out of reach of it
		stiltHut(246, 457, 11, 8, 6, 6, -0.15)
		stiltHut(197, 511, 14, 7, 6, 6, 0.4)
		scaffold(206, 513, 222, 519, { 8, 16, 24 }) -- up the ledge's face
		scaffold(176, 470, 186, 482, { 7, 14 })
		-- a bridge off the high hut to nowhere, sagging, its end snapped off
		do
			local a, b = Vector3.new(193, 14, 511), Vector3.new(180, 12, 506)
			for k = 0, 1, 0.08 do
				if k < 0.85 or er:NextNumber() < 0.4 then
					local p = a:Lerp(b, k) - Vector3.new(0, math.sin(k * math.pi) * 1.2, 0)
					plank(Vector3.new(1.0, 0.4, 3.4), CFrame.lookAt(p, p + (b - a)) * CFrame.Angles(0, math.pi / 2, n(-0.08, 0.08)))
				end
			end
			timber(b - Vector3.new(0, 0.5, 0), Vector3.new(b.X - 0.5, 0, b.Z), 0.6, true)
		end
		palisade(Vector3.new(172, 0, 454.6), Vector3.new(222, 0, 454.6))
		palisade(Vector3.new(252, 0, 454.6), Vector3.new(270, 0, 454.6))
		palisade(Vector3.new(172.6, 0, 486), Vector3.new(172.6, 0, 496))
		palisade(Vector3.new(278.4, 0, 468), Vector3.new(278.4, 0, 482))
		palisade(Vector3.new(278.4, 0, 494), Vector3.new(278.4, 0, 504))
		-- on the ledge
		watchtower(214, 534, 12, LEDGE_Y)
		stiltHut(176, 534, LEDGE_Y + 12, 7, 6, 6, -0.2, LEDGE_Y)
		palisade(Vector3.new(172, LEDGE_Y, 538.6), Vector3.new(228, LEDGE_Y, 538.6))
		palisade(Vector3.new(240, LEDGE_Y, 538.6), Vector3.new(278, LEDGE_Y, 538.6))

		-- THE CROSSING: through the gap in the north cliff, a bridge thrown together out of
		-- whatever was lying about zig-zags over the chasm from one rotten stilt tower to the
		-- next, to the far side. Loose, sagging, planks missing, the posts along it half gone.
		-- (Fall, and the chasm kills you: Map.Chasm, init.server.)
		do
			local DEEP = -16 -- (below the chasm's floor, where the towers stand)
			local pts = {
				Vector3.new(234, LEDGE_Y, 540), -- the ledge's lip
				Vector3.new(225, LEDGE_Y - 0.5, 556),
				Vector3.new(244, LEDGE_Y + 1, 573),
				Vector3.new(227, LEDGE_Y - 1.5, 590),
				Vector3.new(243, LEDGE_Y, 606),
				Vector3.new(236, LEDGE_Y, 619), -- the far side
			}
			-- a tower: a deck up on tall leaning stilts from the chasm floor, braced every which
			-- way, a rotted lean-to on one corner, junk and arms hanging off it
			local function tower(c, yaw, deep) -- (deep: where its legs stand; the chasm floor if left out)
				deep = deep or DEEP
				local cf = CFrame.new(c) * CFrame.Angles(0, yaw, 0)
				box(c.X - 3.4, c.Y - 1.1, c.Z - 3.4, c.X + 3.4, c.Y - 0.5, c.Z + 3.4, MAT.Wood, WOOD_DARK, "Joist")
				deck(c.X, c.Z, c.Y, 7, 7, yaw, 1)
				local feet = {}
				for i, o in ipairs({ { -3, -3 }, { 3, -3 }, { 3, 3 }, { -3, 3 } }) do
					local top = (cf * CFrame.new(o[1], -1, o[2])).Position
					local foot = top + Vector3.new(o[1] * n(0.2, 0.5), 0, o[2] * n(0.2, 0.5))
					foot = Vector3.new(foot.X, deep, foot.Z)
					timber(foot, top, 0.8, true)
					feet[i] = { foot, top }
				end
				for y = deep + 8, c.Y - 4, n(6, 9) do -- braces, some snapped
					for i = 1, 4 do
						local a, b = feet[i], feet[i % 4 + 1]
						local ka, kb = (y - deep) / (c.Y - deep), (y + n(3, 6) - deep) / (c.Y - deep)
						if er:NextNumber() > 0.25 then
							timber(a[1]:Lerp(a[2], ka), b[1]:Lerp(b[2], math.min(kb, 1)), 0.35)
						end
					end
				end
				-- a lean-to of rotten boards on the corner away from the path
				local lc = cf * CFrame.new(n(-1, 1) > 0 and 2.2 or -2.2, 0, 2.2)
				for b = -1.2, 1.2, 1.2 do
					if er:NextNumber() > 0.25 then
						plank(Vector3.new(1.1, n(3, 4.5), 0.3), lc * CFrame.new(b, 2, 0.9) * CFrame.Angles(n(-0.15, 0.05), 0, n(-0.12, 0.12))).CanCollide = false -- (never in the way)
					end
				end
				plank(Vector3.new(3.4, 0.3, 2.6), lc * CFrame.new(0, 3.6, 0) * CFrame.Angles(n(0.3, 0.5), 0, n(-0.15, 0.15)), WOOD_DARK:Lerp(Rot.Mold, n(0.2, 0.6))).CanCollide = false
				-- junk on a rope under it, and arms out of its legs
				local hang = c + Vector3.new(n(-2, 2), -1, n(-2, 2))
				local drop = n(3, 7)
				timber(hang, hang - Vector3.new(0, drop, 0), 0.12, false, Color3.fromRGB(110, 96, 70))
				part({ Name = "Bundle", Size = Vector3.new(1.1, 1.8, 1), CFrame = CFrame.new(hang - Vector3.new(0, drop + 0.9, 0)) * CFrame.Angles(0, n(0, 6), n(-0.2, 0.2)), Material = MAT.Fabric, Color = Color3.fromRGB(58, 50, 40), CanCollide = false })
				for _ = 1, 3 do
					local f = feet[er:NextInteger(1, 4)]
					limb(f[1]:Lerp(f[2], n(0.3, 0.9)), randDir(), n(1, 1.5))
				end
			end
			-- a span from a to b (deck tops): crosswise planks, sagging, a few missing (never two
			-- in a row), posts down both sides with a rope rail strung between them
			local function span(a, b)
				local d = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
				local len, dir = d.Magnitude, d.Unit
				local side = Vector3.new(-dir.Z, 0, dir.X)
				local gap = false
				for s = 0, len, 1.1 do
					local k = s / len
					local p = a:Lerp(b, k) - Vector3.new(0, math.sin(k * math.pi) * 1.3, 0)
					if gap or er:NextNumber() > 0.08 or s < 2 or s > len - 2 then
						gap = false
						plank(Vector3.new(3.6 + n(-0.4, 0.5), 0.4, 1.0), CFrame.lookAt(p, p + dir) * CFrame.new(n(-0.25, 0.25), -0.2 + n(-0.08, 0.04), 0) * CFrame.Angles(n(-0.05, 0.05), n(-0.1, 0.1), n(-0.06, 0.06)))
					else
						gap = true
					end
				end
				for _, sx in ipairs({ -2, 2 }) do
					local last
					for s = 1, len - 1, 2.6 do
						local k = s / len
						local p = a:Lerp(b, k) - Vector3.new(0, math.sin(k * math.pi) * 1.3, 0) + side * sx
						if er:NextNumber() > 0.2 then
							part({ Name = "RailPost", Size = Vector3.new(0.3, 2.8, 0.3), CFrame = CFrame.new(p + Vector3.new(0, 1.2, 0)) * CFrame.Angles(n(-0.15, 0.15), 0, n(-0.15, 0.15)), Material = MAT.Wood, Color = wood() })
							local top = p + Vector3.new(0, 2.4, 0)
							if last and er:NextNumber() > 0.15 then
								timber(last, top - Vector3.new(0, 0.3, 0), 0.1, false, Color3.fromRGB(110, 96, 70)) -- rope
							end
							last = top
						else
							last = nil
						end
					end
				end
				-- the stringers under it
				for _, sx in ipairs({ -1.4, 1.4 }) do
					timber(a + side * sx - Vector3.new(0, 0.6, 0), (a + b) / 2 + side * sx - Vector3.new(0, 1.9, 0), 0.35)
					timber((a + b) / 2 + side * sx - Vector3.new(0, 1.9, 0), b + side * sx - Vector3.new(0, 0.6, 0), 0.35)
				end
			end
			for i = 2, #pts - 1 do
				tower(pts[i], n(-0.3, 0.3))
			end
			for i = 1, #pts - 1 do
				local a, b = pts[i], pts[i + 1]
				local d = Vector3.new(b.X - a.X, 0, b.Z - a.Z).Unit
				-- from deck edge to deck edge (onto the ledge and the far side by a stud)
				span(a + d * (i == 1 and -1 or 3.3), b - d * (i == #pts - 1 and -1 or 3.3))
			end
			-- THE MATRIX: limbs grown across the gorge like a web - arches high over the bridge
			-- from wall to wall, struts criss-crossing between them, and webbing from the walls
			-- to the towers' legs, under the decks. None of it is solid, and none of it comes
			-- down near the walk: the arches clear the decks by at least 9 studs.
			local FLESH, FLESH_DARK = Color3.fromRGB(150, 138, 116), Color3.fromRGB(86, 74, 60)
			local WEST, EAST = 208, 260 -- (the gorge's walls; the bridge keeps to x 216..254)
			local function strut(a, b, arc, thick)
				local steps = math.max(3, math.floor((b - a).Magnitude / 6))
				local last = a
				for k = 1, steps do
					local t = k / steps
					local p = a:Lerp(b, t) + Vector3.new(0, math.sin(t * math.pi) * arc, 0)
					if k < steps then
						p += Vector3.new(n(-0.8, 0.8), n(-0.8, 0.8), n(-0.8, 0.8))
					end
					local th = thick * (1 - math.abs(t - 0.5) * 0.5) * n(0.8, 1.15)
					part({ Name = "Sinew", Shape = Enum.PartType.Cylinder, Size = Vector3.new((p - last).Magnitude + th * 0.4, th, th), CFrame = CFrame.lookAt((last + p) / 2, p) * CFrame.Angles(0, math.pi / 2, 0), Material = MAT.SmoothPlastic, Color = FLESH:Lerp(FLESH_DARK, n(0, 1)):Lerp(Rot.FleshDark, n(0, 0.3)), Reflectance = 0.06, CanCollide = false, CanQuery = false, CastShadow = false })
					if k < steps then
						part({ Name = "Knuckle", Shape = Enum.PartType.Ball, Size = Vector3.one * th * n(1.4, 2.2), CFrame = CFrame.new(p), Material = MAT.SmoothPlastic, Color = FLESH_DARK:Lerp(Rot.FleshDark, n(0, 0.6)), CanCollide = false, CanQuery = false, CastShadow = false })
					end
					last = p
				end
			end
			local function arch(z)
				local a = Vector3.new(WEST, n(28, 38), z + n(-3, 3))
				local b = Vector3.new(EAST, n(28, 38), z + n(-3, 3))
				local arc = n(14, 22)
				strut(a, b, arc, n(0.6, 1.1))
				return a, b, arc
			end
			local arches = {}
			for z = 547, 613, n(6, 8) do
				local a, b, arc = arch(z)
				table.insert(arches, { a = a, b = b, arc = arc })
			end
			local function onArch(r, t) -- a point along an arch
				return r.a:Lerp(r.b, t) + Vector3.new(0, math.sin(t * math.pi) * r.arc, 0)
			end
			for i = 1, #arches - 1 do -- struts criss-crossing between neighbouring arches, all high
				for _ = 1, 2 do
					strut(onArch(arches[i], n(0.15, 0.85)), onArch(arches[i + 1], n(0.15, 0.85)), n(-2, 3), n(0.3, 0.6))
				end
				if er:NextNumber() < 0.5 then
					local p = onArch(arches[i], n(0.2, 0.8))
					limb(p, randDir(Vector3.new(0, 1, 0)), n(1, 1.5))
				end
			end
			-- webbing down the walls to the towers' legs, below their decks
			for i = 2, #pts - 1 do
				local c = pts[i]
				for _, side in ipairs({ WEST, EAST }) do
					for _ = 1, 2 do
						local leg = Vector3.new(c.X + (side < c.X and -3.2 or 3.2), n(-6, c.Y - 9), c.Z + n(-3, 3))
						strut(Vector3.new(side, n(-8, c.Y - 9), c.Z + n(-8, 8)), leg, n(-3, 1), n(0.35, 0.7))
					end
				end
			end
			-- and long strands from the arches down the walls into the dark
			for _, r in ipairs(arches) do
				for _, e in ipairs({ r.a, r.b }) do
					strut(e, Vector3.new(e.X + (e.X < 230 and -4 or 4), n(-14, 0), e.Z + n(-6, 6)), n(-2, 2), n(0.4, 0.8))
				end
			end

			-- the far side: a ravine winding away from the bridge - north, east, then north
			-- again - three overlapping stretches of floor. Under the terrain's ground (laid
			-- with the land, below) a hidden slab per stretch, so the land pass counts it as
			-- built; ravine walls of dark rock heaped round its outline (also below), and an
			-- invisible rim along that outline keeps you in.
			local RAVINE = { { 205, 618, 265, 675 }, { 245, 660, 325, 705 }, { 290, 695, 335, 775 } } -- x1, z1, x2, z2
			-- its outline, round the outside (each edge axis-aligned; the bridge comes in on the first)
			local OUTLINE = { { 205, 618 }, { 265, 618 }, { 265, 660 }, { 325, 660 }, { 325, 695 }, { 335, 695 }, { 335, 775 }, { 290, 775 }, { 290, 705 }, { 245, 705 }, { 245, 675 }, { 205, 675 } }
			for _, q in ipairs(RAVINE) do
				local slab = box(q[1], -20, q[2], q[3], LEDGE_Y - 0.5, q[4], MAT.Ground, Color3.fromRGB(48, 44, 38), "FarGround")
				slab.Transparency, slab.CastShadow = 1, false
			end
			for i, a in ipairs(OUTLINE) do
				local b = OUTLINE[i % #OUTLINE + 1]
				local pieces = (i == 1) and { { a[1], 228 }, { 244, b[1] } } or { {} } -- (the gap the bridge lands in)
				local d = Vector3.new(b[1] - a[1], 0, b[2] - a[2]).Unit
				local out = Vector3.new(d.Z, 0, -d.X) -- (outward: the floor is always on the other side)
				for _, pc in ipairs(pieces) do
					local x1, z1, x2, z2 = a[1], a[2], b[1], b[2]
					if pc[1] then
						x1, x2 = pc[1], pc[2]
					end
					local wall = box(math.min(x1, x2) + math.min(out.X, 0), LEDGE_Y - 1, math.min(z1, z2) + math.min(out.Z, 0), math.max(x1, x2) + math.max(out.X, 0), LEDGE_Y + 30, math.max(z1, z2) + math.max(out.Z, 0), MAT.SmoothPlastic, COL.Wall, "Edge")
					wall.Transparency, wall.CanQuery, wall.CastShadow = 1, false, false
				end
			end
			info.Chasm = { MinX = 150, MaxX = 320, MinZ = 541, MaxZ = 617, MaxY = 12 }
			info.FarSide = { Y = LEDGE_Y, Rects = RAVINE, Outline = OUTLINE, Bridge = { 216, 256 }, Carve = {} } -- (Carve: boxes the terrain pass clears)

			-- THE HIGH BRIDGE: off the ledge's other side, back south over the pit, the same
			-- thrown-together bridge on the same rotten towers (these stand on the pit floor, one
			-- right over the bonfire), forking at its first tower:
			--   east, over the way up, into a tunnel through the east cliff. A locked door shuts
			--     it (Map.TunnelDoor), its key in the doored shack at the far ravine's dead end
			--     (Map.Pickups.TunnelKey); when it opens, the old hag behind it falls out
			--     (Characters/Hag, at Map.Hag).
			--   west, to a tunnel through the west cliff, choked with dry brushwood that only
			--     burns away (Map.Brushwood: a fireball sets it Lit, init.server burns it).
			-- Its own stream, so nothing else shifts.
			do
				local crossEr = er
				er = Random.new(4343)
				local fork = Vector3.new(198, LEDGE_Y - 0.5, 507)
				local EX, EZ = X2, 480 -- the east tunnel's mouth, in the east cliff's face
				local WX, WZ = X1, 500 -- the west one's
				local hpts = {
					Vector3.new(196, LEDGE_Y, LEDGE_Z), -- the ledge's south lip (west of the scaffold up its face)
					fork,
					Vector3.new(219, LEDGE_Y + 1, 486), -- over the bonfire
					Vector3.new(236, LEDGE_Y + 1.5, 478), -- (high enough to clear the stilt hut's roof)
					Vector3.new(270, LEDGE_Y + 1, 472), -- past the walkway
					Vector3.new(EX, LEDGE_Y, EZ),
				}
				for i = 2, #hpts - 1 do
					tower(hpts[i], n(-0.3, 0.3), 0)
				end
				for i = 1, #hpts - 1 do
					local a, b = hpts[i], hpts[i + 1]
					local d = Vector3.new(b.X - a.X, 0, b.Z - a.Z).Unit
					span(a + d * (i == 1 and -1 or 3.3), b - d * (i == #hpts - 1 and -1 or 3.3))
				end
				do -- the west fork: one long span, high over the shacks on that side
					local b = Vector3.new(WX, LEDGE_Y, WZ)
					local d = Vector3.new(b.X - fork.X, 0, b.Z - fork.Z).Unit
					span(fork + d * 3.3, b + d)
				end
				-- no ledge-face rock jutting up where the bridge leaves the lip
				for _, p in ipairs(map:GetChildren()) do
					if p.Name == "LedgeFace" and math.abs(p.Position.X - 196) < 7 and p.Position.Y + p.Size.Y / 2 > LEDGE_Y - 0.5 then
						p:Destroy()
					end
				end
				local function split(p, lo, hi, y1, y2) -- removes p's local z lo..hi, world y y1..y2
					local s = p.Size
					local ly1, ly2 = y1 - p.Position.Y, y2 - p.Position.Y
					for _, r in ipairs({ { -s.Z / 2, lo, -s.Y / 2, s.Y / 2 }, { hi, s.Z / 2, -s.Y / 2, s.Y / 2 }, { lo, hi, -s.Y / 2, ly1 }, { lo, hi, ly2, s.Y / 2 } }) do
						if r[2] - r[1] > 0.05 and r[4] - r[3] > 0.05 then
							local q = p:Clone()
							q.Size = Vector3.new(s.X, r[4] - r[3], r[2] - r[1])
							q.CFrame = p.CFrame * CFrame.new(0, (r[3] + r[4]) / 2, (r[1] + r[2]) / 2)
							q.Parent = p.Parent
						end
					end
					p:Destroy()
				end
				-- a tunnel through the cliff at x TX (an east or west side; dir = +1 east, -1 west),
				-- centred on z TZ, len long: the doorway cut through the cliff's slabs, hewn rock
				-- propped with timber, running into the dark to a rockfall (or, open, on out the far
				-- side), buried in the hills behind the cliff (the terrain pass heaps F.Fill over
				-- it, then clears F.Carve out of it)
				local ROCK = Color3.fromRGB(46, 42, 38)
				info.FarSide.Fill = {}
				local function tunnel(TX, TZ, dir, len, open)
					for _, p in ipairs(map:GetChildren()) do
						if p.Name == "Cliff" and math.abs(p.Position.X - (TX + dir * 3)) < 4 and p.Position.Y + p.Size.Y / 2 > LEDGE_Y then
							local a = p.CFrame:PointToObjectSpace(Vector3.new(p.Position.X, p.Position.Y, TZ - 3)).Z
							local b = p.CFrame:PointToObjectSpace(Vector3.new(p.Position.X, p.Position.Y, TZ + 3)).Z
							local lo, hi = math.max(math.min(a, b), -p.Size.Z / 2), math.min(math.max(a, b), p.Size.Z / 2)
							if lo < hi then
								split(p, lo, hi, LEDGE_Y - 2, LEDGE_Y + 9)
							end
						end
					end
					local TEND = TX + dir * len
					local x1, x2 = math.min(TX, TEND), math.max(TX, TEND)
					box(math.min(TX - dir * 1.5, TEND), LEDGE_Y - 2, TZ - 4, math.max(TX - dir * 1.5, TEND), LEDGE_Y, TZ + 4, MAT.Rock, ROCK, "TunnelFloor") -- (a lip out past the face for the bridge)
					box(x1, LEDGE_Y - 2, TZ - 5, x2, LEDGE_Y + 10, TZ - 3, MAT.Rock, ROCK, "TunnelWall")
					box(x1, LEDGE_Y - 2, TZ + 3, x2, LEDGE_Y + 10, TZ + 5, MAT.Rock, ROCK, "TunnelWall")
					box(x1, LEDGE_Y + 9, TZ - 5, x2, LEDGE_Y + 11, TZ + 5, MAT.Rock, ROCK, "TunnelRoof")
					if not open then
						box(TEND, LEDGE_Y - 2, TZ - 5, TEND + dir * 2, LEDGE_Y + 11, TZ + 5, MAT.Rock, ROCK, "TunnelEnd")
					end
					for k = 6, len - 6, 6 do
						local x = TX + dir * k
						timber(Vector3.new(x, LEDGE_Y, TZ - 2.7), Vector3.new(x + n(-0.2, 0.2), LEDGE_Y + 8.7, TZ - 2.7), 0.6)
						timber(Vector3.new(x, LEDGE_Y, TZ + 2.7), Vector3.new(x + n(-0.2, 0.2), LEDGE_Y + 8.7, TZ + 2.7), 0.6)
						timber(Vector3.new(x, LEDGE_Y + 8.6, TZ - 3), Vector3.new(x, LEDGE_Y + 8.6 + n(-0.3, 0.1), TZ + 3), 0.5)
					end
					for _ = 1, open and 0 or 9 do
						local s = n(1, 3)
						part({ Name = "Rubble", Size = Vector3.new(s, s * n(0.6, 1), s * n(0.8, 1.5)), CFrame = CFrame.new(TEND - dir * n(0.5, 5), LEDGE_Y + s * 0.3, TZ + n(-2.5, 2.5)) * CFrame.Angles(n(-0.5, 0.5), n(0, 6.3), n(-0.5, 0.5)), Material = MAT.Rock, Color = ROCK:Lerp(Rot.Stone, n(0, 0.6)) })
					end
					for k = 16, open and len - 14 or len + 6, 6 do -- (clear of the faces: none of it pokes into the pit, or the far side)
						table.insert(info.FarSide.Fill, { Vector3.new(TX + dir * k, LEDGE_Y + n(3, 7), TZ + n(-2, 2)), n(10, 13) })
					end
					-- (terrain is in 4-stud voxels, and a carve that covers only part of one leaves a skin of
					-- rock across the way: this one runs on out past the cliff's face, and is snapped out to
					-- whole voxels - the floor, walls and roof parts hide what it takes beyond them)
					local c1, c2 = math.floor(math.min(TX - dir * 4, TEND) / 4) * 4, math.ceil(math.max(TX - dir * 4, TEND) / 4) * 4
					local z1, z2 = math.floor((TZ - 4) / 4) * 4, math.ceil((TZ + 4) / 4) * 4
					local y1, y2 = math.floor((LEDGE_Y - 2) / 4) * 4, math.ceil((LEDGE_Y + 10) / 4) * 4
					table.insert(info.FarSide.Carve, { CFrame.new((c1 + c2) / 2, (y1 + y2) / 2, (z1 + z2) / 2), Vector3.new(c2 - c1, y2 - y1, z2 - z1) })
				end
				tunnel(EX, EZ, 1, 26)
				tunnel(WX, WZ, -1, WX - 112, true) -- (on through to the Weald: its east edge is x 112)

				-- the east door, just inside the mouth (init.server swings it in, on its south hinge)
				local DX = EX + 2
				local door = Instance.new("Model")
				door.Name = "TunnelDoor"
				door.Parent = map
				local main = part({ Name = "Door", Size = Vector3.new(0.5, 9, 6), CFrame = CFrame.new(DX, LEDGE_Y + 4.5, EZ), Material = MAT.WoodPlanks, Color = WOOD_DARK, Parent = door })
				for _, y in ipairs({ -3.2, 0, 3.2 }) do
					part({ Name = "DoorBand", Size = Vector3.new(0.62, 0.4, 6), CFrame = main.CFrame * CFrame.new(0, y, 0), Material = MAT.Metal, Color = Color3.fromRGB(60, 56, 52), CanCollide = false, Parent = door })
				end
				part({ Name = "LockPlate", Size = Vector3.new(0.7, 1.2, 0.9), CFrame = main.CFrame * CFrame.new(0, -0.5, 2.2), Material = MAT.CorrodedMetal, Color = Color3.fromRGB(110, 70, 44), CanCollide = false, Parent = door })
				door.PrimaryPart = main
				local spot = part({ Name = "TunnelDoorPrompt", Size = Vector3.one, CFrame = CFrame.new(DX - 1.5, LEDGE_Y + 3, EZ), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
				info.TunnelDoor = { Leaf = door, Hinge = Vector3.new(DX, LEDGE_Y + 4.5, EZ - 3), Sign = 1, Prompt = prompt(spot, "Open", "Tunnel Door", 0.5, 7) }
				-- the hag: shut in behind it (clear of the door's swing), and where she falls to, at the mouth
				local outward = Vector3.new(EX - 10, LEDGE_Y, EZ)
				info.Hag = { Inside = CFrame.lookAt(Vector3.new(DX + 6.5, LEDGE_Y, EZ), outward), Out = CFrame.lookAt(Vector3.new(EX + 3.5, LEDGE_Y, EZ), outward) }
				local lantern = part({ Name = "Lantern", Size = Vector3.new(0.7, 1, 0.7), CFrame = CFrame.new(EX - 0.8, LEDGE_Y + 6, EZ - 3.6), Material = MAT.Neon, Color = Color3.fromRGB(255, 150, 70), CanCollide = false })
				local l = Instance.new("PointLight")
				l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 160, 90), 16, 1.2
				l.Parent = lantern
				addFlicker(l)

				-- the west tunnel's brushwood: a dead tangle jammed in the mouth - bone-dry thorn
				-- branches and bundled kindling, an invisible wall behind so nothing slips through.
				-- Nothing cuts it; it wants burning.
				local brush = Instance.new("Model")
				brush.Name = "Brushwood"
				brush:SetAttribute("Burnable", true)
				info.Brushwood = brush
				brush.Parent = map
				local DRY, DRY_DARK = Color3.fromRGB(150, 128, 92), Color3.fromRGB(96, 78, 56)
				local function dry()
					return DRY:Lerp(DRY_DARK, n(0, 1))
				end
				local bx = WX - 0.5
				local blocker = box(bx - 0.6, LEDGE_Y, WZ - 3, bx + 0.6, LEDGE_Y + 9, WZ + 3, MAT.SmoothPlastic, DRY, "BrushWall", brush)
				blocker.Transparency = 1
				for _ = 1, 14 do -- branches jammed across it every which way
					local a = Vector3.new(bx + n(-1.2, 1.4), LEDGE_Y + n(0, 9), WZ + n(-3.2, 3.2))
					local b = Vector3.new(bx + n(-1.2, 1.4), LEDGE_Y + n(0, 9), WZ + n(-3.2, 3.2))
					if (b - a).Magnitude > 3 then
						part({ Name = "Branch", Size = Vector3.new(n(0.25, 0.7), n(0.25, 0.7), (b - a).Magnitude + 1), CFrame = CFrame.lookAt((a + b) / 2, b), Material = MAT.Wood, Color = dry(), CanCollide = false, Parent = brush })
					end
				end
				for _ = 1, 30 do -- twigs and thorns bristling out of it
					local c = Vector3.new(bx + n(-1, 2), LEDGE_Y + n(0.3, 8.7), WZ + n(-3, 3))
					part({ Name = "Twig", Size = Vector3.new(0.12, 0.12, n(1, 2.6)), CFrame = CFrame.new(c) * CFrame.Angles(n(-1.5, 1.5), n(0, 6.3), n(-1.5, 1.5)), Material = MAT.Wood, Color = dry(), CanCollide = false, Parent = brush })
				end
				for _ = 1, 6 do -- bundles of kindling, tied up and stuffed in
					local c = Vector3.new(bx + n(0, 1.5), LEDGE_Y + n(0.6, 4), WZ + n(-2.5, 2.5))
					part({ Name = "Kindling", Size = Vector3.new(n(1.2, 2), n(0.8, 1.2), n(0.8, 1.2)), CFrame = CFrame.new(c) * CFrame.Angles(n(-0.4, 0.4), n(0, 6.3), n(-0.4, 0.4)), Material = MAT.Grass, Color = DRY:Lerp(Color3.fromRGB(170, 150, 100), n(0, 1)), CanCollide = false, Parent = brush })
				end
				er = crossEr
			end

			-- THE WEALD (its banner: the Vale of Errants): out of the west tunnel (once the brushwood's burnt) into a wooded valley
			-- walled in by mountains, a dirt track winding west through the trees (a good fifteen
			-- seconds' walk) to THE COLOSSEUM (no banner of its own): a grand, well-kept arena of pale stone,
			-- ringed by three staggered rows of columns (from inside you can't see out, from
			-- outside you can't see in, until you've threaded through them), its roofed
			-- colonnade carrying a mountain - a great funnel of rock flaring up off its top, open
			-- to the sky in the middle, about as tall as the keep (laid in the terrain pass:
			-- info.Wilds.Funnel). You're kept to it by the mountains, thick woods along every
			-- edge, a broken fence along the track and an invisible rim behind it all.
			-- Its own streams, so nothing else shifts.
			do
				local wr = Random.new(7070)
				local function wn(a, b)
					return wr:NextNumber(a, b)
				end
				local Y = LEDGE_Y
				local RECTS = { { 40, 470, 112, 535 }, { -40, 485, 60, 560 }, { -200, 430, -20, 610 } } -- the glade, the woods, the arena's clearing
				-- the Highlands: the mountain-walled land the arena's clearing opens south into, round the
				-- north and west of the prison, down to the Blind Chapel's reliquary (LAND is floor only:
				-- the tree and stone passes below keep to RECTS, so the Weald itself doesn't shift)
				local LAND = table.clone(RECTS)
				for _, q in ipairs({ { -20, 430, 40, 485 }, { 40, 425, 112, 470 }, { -90, 366, 64, 430 }, { -200, 254, -90, 430 }, { -188, 236, -164, 254 } }) do -- (the last: the ramp's mouth, only to keep the mountain walls off it)
					table.insert(LAND, q)
				end
				local OUTLINE = { { -200, 254 }, { -90, 254 }, { -90, 366 }, { 64, 366 }, { 64, 425 }, { 112, 425 }, { 112, 535 }, { 60, 535 }, { 60, 560 }, { -20, 560 }, { -20, 610 }, { -200, 610 }, { -200, 430 } }
				local GAP = { 6, 494, 506 } -- (edge 6, x 112: where the tunnel comes out)
				local RAMPGAP = { 1, -192, -160 } -- (edge 1, z 254: where the ramp up the hill leaves the basin)
				-- the hill over the Blind Chapel: a ramp up out of the basin onto a mesa (floating clear of the
				-- chapel's towers). Its one other way down is straight down the chapel's broken roof (Roof y 30)
				local HL = {
					Ramp = { A = Vector3.new(-176, Y, 342), B = Vector3.new(-176, 60, 236), W = 24 },
					Plateau = { X1 = -192, Z1 = 108, X2 = -72, Z2 = 236, Top = 60, Thick = 12 }, -- (X2: out over the chapel, so the keep's roof sees only the mesa's rim)
					Citadel = { X1 = -332, Z1 = -232, X2 = -92, Z2 = 108 }, -- (the walled district south of it; the wall's in the township's section)
					Hole = { X1 = -135, Z1 = 155, X2 = -127, Z2 = 165, Roof = 30 },
				}
				local C = Vector3.new(-110, Y, 520) -- the colosseum's middle
				local PATH = { Vector3.new(112, Y, 500), Vector3.new(90, Y, 505), Vector3.new(60, Y, 518), Vector3.new(30, Y, 525), Vector3.new(0, Y, 514), Vector3.new(-30, Y, 520), Vector3.new(-48, Y, 520) }
				for _, q in ipairs(LAND) do -- hidden slabs under the terrain's ground (so the land pass counts it built)
					local slab = box(q[1], -20, q[2], q[3], Y - 0.5, q[4], MAT.Ground, Color3.fromRGB(48, 44, 38), "WealdGround")
					slab.Transparency, slab.CastShadow = 1, false
				end
				for i, a in ipairs(OUTLINE) do -- the invisible rim, behind the mountains' feet
					local b = OUTLINE[i % #OUTLINE + 1]
					local d = Vector3.new(b[1] - a[1], 0, b[2] - a[2]).Unit
					local out = Vector3.new(d.Z, 0, -d.X)
					local pieces = { { a[1], a[2], b[1], b[2] } }
					local g = (i == GAP[1] and GAP) or (i == RAMPGAP[1] and RAMPGAP)
					if g and a[2] == b[2] then
						pieces = { { a[1], a[2], g[2], a[2] }, { g[3], a[2], b[1], b[2] } }
					elseif g then
						pieces = { { a[1], a[2], a[1], g[2] }, { a[1], g[3], b[1], b[2] } }
					end
					for _, pc in ipairs(pieces) do
						local wall = box(math.min(pc[1], pc[3]) + math.min(out.X, 0), Y - 1, math.min(pc[2], pc[4]) + math.min(out.Z, 0), math.max(pc[1], pc[3]) + math.max(out.X, 0), Y + 30, math.max(pc[2], pc[4]) + math.max(out.Z, 0), MAT.SmoothPlastic, COL.Wall, "Edge")
						wall.Transparency, wall.CanQuery, wall.CastShadow = 1, false, false
					end
				end
				info.Wilds = {
					Y = Y, Rects = LAND, Outline = OUTLINE, Gap = GAP, Path = PATH, Low = true, -- (Low: its walls kept under the colosseum's height)
						High = { [13] = true }, -- (...bar the Highlands' far west wall, edge 13: real mountains)
						Gaps = { RAMPGAP }, Highland = HL,
					Avoid = { { C.X, C.Z, 66 } }, -- (no lumps or stones on the colosseum's ground)
					Mats = { Enum.Material.LeafyGrass, Enum.Material.Grass, Enum.Material.Ground, Enum.Material.Mud },
					Funnel = { Centre = C, Base = Y + 27.2, Radius = 54, Height = 86.8, Top = 140, Rim = 128 }, -- (Top, Rim: the flat land on it, GildedHeights; Top a whole voxel)
				}
				table.insert(info.Zones, { Name = "Vale of Errants", MinX = -201, MaxX = 113, MinZ = 429, MaxZ = 611 }) -- (the colosseum in it has no name of its own)

				local function toPath(p) -- how far p is from the track
					local best = math.huge
					for i = 1, #PATH - 1 do
						local a, b = PATH[i], PATH[i + 1]
						local ab = b - a
						local t = math.clamp((p - a):Dot(ab) / ab:Dot(ab), 0, 1)
						best = math.min(best, (p - (a + ab * t)).Magnitude)
					end
					return best
				end
				local function inRects(x, z, m)
					for _, q in ipairs(RECTS) do
						if x > q[1] + m and x < q[3] - m and z > q[2] + m and z < q[4] - m then
							return true
						end
					end
					return false
				end

				-- the woods: old broadleaf trees, crowding thickest toward the edges
				local BARK, LEAF = Color3.fromRGB(56, 46, 36), { Color3.fromRGB(46, 60, 36), Color3.fromRGB(38, 50, 30), Color3.fromRGB(58, 66, 40), Color3.fromRGB(50, 56, 34) }
				local function tree(pos, s)
					local h = wn(11, 18) * s
					local top = pos + Vector3.new(wn(-1.2, 1.2), h, wn(-1.2, 1.2))
					local d = top - pos
					part({ Name = "Trunk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(d.Magnitude + 1, 1.6 * s, 1.6 * s), CFrame = CFrame.lookAt(pos + d / 2 - Vector3.new(0, 0.5, 0), top) * CFrame.Angles(0, math.pi / 2, 0), Material = MAT.Wood, Color = BARK:Lerp(Color3.fromRGB(30, 26, 22), wn(0, 0.6)) })
					for _ = 1, wr:NextInteger(1, 2) do -- a bough off the trunk
						local from = pos:Lerp(top, wn(0.5, 0.8))
						local to = from + Vector3.new(wn(-5, 5), wn(1, 4), wn(-5, 5)) * s
						part({ Name = "Bough", Size = Vector3.new(0.6 * s, 0.6 * s, (to - from).Magnitude), CFrame = CFrame.lookAt((from + to) / 2, to), Material = MAT.Wood, Color = BARK, CanCollide = false })
						part({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.one * wn(5, 8) * s, CFrame = CFrame.new(to), Material = MAT.Grass, Color = LEAF[wr:NextInteger(1, #LEAF)], CanCollide = false })
					end
					for _ = 1, wr:NextInteger(3, 4) do
						part({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.one * wn(7, 11) * s, CFrame = CFrame.new(top + Vector3.new(wn(-3, 3), wn(-1, 3), wn(-3, 3)) * s), Material = MAT.Grass, Color = LEAF[wr:NextInteger(1, #LEAF)], CanCollide = false })
					end
				end
				for x = -198, 110, 8 do
					for z = 432, 608, 8 do
						local p = Vector3.new(x + wn(-3, 3), Y, z + wn(-3, 3))
						local edge = not inRects(p.X, p.Z, 14)
						if inRects(p.X, p.Z, 1.5) and toPath(p) > 7 and (p - C).Magnitude > 72 and (p - PATH[1]).Magnitude > 12 and wr:NextNumber() < (edge and 0.9 or 0.45) then
							tree(p, wn(0.8, 1.25))
						end
					end
				end
				-- a broken old fence along the first stretch of the track, both sides
				for i = 1, 4 do
					local a, b = PATH[i], PATH[i + 1]
					local side = Vector3.new(-(b - a).Unit.Z, 0, (b - a).Unit.X) * 5.5
					for _, sgn in ipairs({ -1, 1 }) do
						if wr:NextNumber() < 0.75 then
							rail(a + side * sgn, b + side * sgn, Y)
						end
					end
				end
				-- mossy stones and fallen logs in the undergrowth
				for _ = 1, 40 do
					local p = Vector3.new(wn(-196, 108), Y, wn(434, 606))
					if inRects(p.X, p.Z, 3) and toPath(p) > 5 and (p - C).Magnitude > 68 then
						if wr:NextNumber() < 0.5 then
							local s = wn(1.5, 3.5)
							part({ Name = "Stone", Size = Vector3.new(s * wn(1, 1.6), s * wn(0.5, 0.9), s), CFrame = CFrame.new(p + Vector3.new(0, s * 0.25, 0)) * CFrame.Angles(wn(-0.3, 0.3), wn(0, 6.3), wn(-0.3, 0.3)), Material = MAT.Rock, Color = Color3.fromRGB(78, 80, 70):Lerp(Color3.fromRGB(60, 74, 48), wn(0, 0.6)) })
						else
							local len = wn(6, 12)
							part({ Name = "Log", Shape = Enum.PartType.Cylinder, Size = Vector3.new(len, 1.4, 1.4), CFrame = CFrame.new(p + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, wn(0, 6.3), 0), Material = MAT.Wood, Color = BARK:Lerp(Color3.fromRGB(60, 74, 48), wn(0, 0.4)) })
						end
					end
				end

				-- THE HIGHLANDS' FOREST: the old broadleaf trees mixed with huge mushrooms, from tree height up
				-- to the Warden's (stems are solid, caps are not: they hang out of reach, so nothing snags)
				do
					local saved = wr
					wr = Random.new(7171) -- (its own stream: the Weald's trees and stones don't shift)
					local NEW = { { -20, 430, 40, 485 }, { 40, 425, 112, 470 }, { -90, 366, 64, 430 }, { -200, 254, -90, 430 } } -- (LAND past RECTS)
					local function inNew(x, z, m)
						for _, q in ipairs(NEW) do
							if x > q[1] + m and x < q[3] - m and z > q[2] + m and z < q[4] - m then
								return true
							end
						end
						return false
					end
					local CAPS = { Color3.fromRGB(96, 38, 40), Color3.fromRGB(78, 56, 92), Color3.fromRGB(112, 92, 64), Color3.fromRGB(150, 140, 120), Color3.fromRGB(60, 74, 66) }
					-- a mushroom's top, not a ball: discs stacked up from a lip, rounding in to a crown, a pale gill
					-- disc under them, a few spots. base = the middle of its underside; rad = how wide; thick = how tall
					local PROFILE = { 0.96, 1.0, 0.94, 0.84, 0.68, 0.46, 0.2 }
					local UP = CFrame.Angles(0, 0, math.pi / 2) -- (a cylinder's axis is X: stand it on end)
					local function mushCap(base, rad, thick, color, glow)
						local lt = thick / #PROFILE
						local function disc(name, y, r, h, c, mat)
							part({ Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, r * 2, r * 2), CFrame = base * CFrame.new(0, y, 0) * UP, Material = mat, Color = c, CanCollide = false })
						end
						disc("MushroomGills", lt * 0.3, rad * 0.9, lt * 0.6, Color3.fromRGB(196, 186, 160), MAT.Fabric)
						for i, f in ipairs(PROFILE) do
							disc("MushroomCap", lt * (i - 0.5) + lt * 0.3, rad * f, lt + 0.05, color:Lerp(Color3.fromRGB(20, 14, 24), (1 - f) * 0.25), MAT.Fabric)
						end
						for _ = 1, wr:NextInteger(4, 8) do -- spots, each on the step of a disc
							local j = wr:NextInteger(3, #PROFILE - 1)
							local a, r, sz = wn(0, 6.3), rad * (PROFILE[j] + PROFILE[j + 1]) / 2, rad * wn(0.08, 0.14)
							part({ Name = "MushroomSpot", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, sz, sz), CFrame = base * CFrame.new(math.cos(a) * r, lt * j + lt * 0.3, math.sin(a) * r) * UP, Material = glow and MAT.Neon or MAT.SmoothPlastic, Color = glow and Color3.fromRGB(120, 200, 170) or Color3.fromRGB(214, 206, 188), CanCollide = false })
						end
					end
					local function mushroom(pos)
						local h = wn(10, 24)
						local top = pos + Vector3.new(wn(-1, 1), 0, wn(-1, 1)) * h * 0.08 + Vector3.new(0, h, 0)
						local d = top - pos
						local sr, cw = h * wn(0.07, 0.11), h * wn(0.9, 1.5)
						local ch = cw * wn(0.3, 0.42)
						local cap = CAPS[wr:NextInteger(1, #CAPS)]
						part({ Name = "MushroomStem", Shape = Enum.PartType.Cylinder, Size = Vector3.new(d.Magnitude + 1, sr * 2, sr * 2), CFrame = CFrame.lookAt(pos + d / 2 - Vector3.new(0, 0.5, 0), top) * CFrame.Angles(0, math.pi / 2, 0), Material = MAT.SmoothPlastic, Color = Color3.fromRGB(176, 168, 148):Lerp(cap, wn(0, 0.25)) })
						part({ Name = "MushroomFoot", Shape = Enum.PartType.Ball, Size = Vector3.new(sr * 4, sr * 2.4, sr * 4), CFrame = CFrame.new(pos + Vector3.new(0, sr * 0.5, 0)), Material = MAT.SmoothPlastic, Color = Color3.fromRGB(150, 142, 122) })
						mushCap(CFrame.new(top - Vector3.new(0, ch * 0.5, 0)) * CFrame.Angles(wn(-0.1, 0.1), wn(0, 6.3), wn(-0.1, 0.1)), cw / 2, ch, cap, wr:NextNumber() < 0.25)
					end
					-- the mages (Characters/Mage) who keep it, clear of the stems. Several guard each hut's approach
					local MAGES = { { -175, 395 }, { -135, 415 }, { -135, 350 }, { -100, 312 }, { -142, 262 }, { -50, 395 }, { 0, 400 }, { 45, 392 }, { 10, 455 }, { 98, 438 } }
					for _, m in ipairs(MAGES) do
						table.insert(info.EnemySpawns, { Type = "Mage", CFrame = CFrame.lookAt(Vector3.new(m[1], Y + 3.2, m[2]), Vector3.new(m[1], Y + 3.2, m[2] + 10)) })
					end

					-- THE MUSHROOM HUTS: three extra-wide mushrooms, hollow, a doorway in the stem and a chest inside
					-- (no mages in them; info.Huts keeps their blink out too). The chests' loot: init.server
					local HUT_R, HUT_T, HUT_H, CAP_R, CAP_H = 8.5, 1.6, 15, 20, 11
					info.MushroomChests, info.Huts = {}, {}
					local function hut(cx, cz, doorA, capColor, item)
						local N = 14
						local stem = Color3.fromRGB(176, 168, 148):Lerp(Color3.fromRGB(110, 90, 70), wn(0, 0.25))
						local mid = HUT_R + HUT_T / 2
						local segW = 2 * (HUT_R + HUT_T) * math.tan(math.pi / N) + 0.15
						local u = Vector3.new(math.cos(doorA), 0, math.sin(doorA))
						local tan = Vector3.new(-u.Z, 0, u.X)
						for k = 0, N - 1 do
							local a = doorA + k * 2 * math.pi / N
							local pos = Vector3.new(cx + math.cos(a) * mid, Y + HUT_H / 2, cz + math.sin(a) * mid)
							local look = CFrame.lookAt(pos, Vector3.new(cx, pos.Y, cz)) -- (its Z runs outward, its X along the wall)
							if k == 0 then -- the doorway: a lintel over it, and the door standing open beside it
								part({ Name = "HutLintel", Size = Vector3.new(segW, HUT_H - 8.5, HUT_T), CFrame = look * CFrame.new(0, 4.25, 0), Material = MAT.SmoothPlastic, Color = stem })
								local hinge = Vector3.new(cx, Y, cz) + u * mid - tan * (segW / 2 - 0.4)
								local centre = hinge + u * 1.7 + Vector3.new(0, 4, 0)
								part({ Name = "HutDoor", Size = Vector3.new(0.4, 8, 3.4), CFrame = CFrame.lookAt(centre, centre + u), Material = MAT.WoodPlanks, Color = Color3.fromRGB(70, 50, 36) })
							else
								part({ Name = "HutWall", Size = Vector3.new(segW, HUT_H, HUT_T), CFrame = look, Material = MAT.SmoothPlastic, Color = stem:Lerp(Color3.fromRGB(150, 140, 120), (k % 3) * 0.08) })
							end
						end
						local r2 = 2 * (HUT_R + HUT_T)
						part({ Name = "HutFloor", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, r2, r2), CFrame = CFrame.new(cx, Y - 0.35, cz) * UP, Material = MAT.WoodPlanks, Color = Color3.fromRGB(74, 58, 44) })
						part({ Name = "HutCeiling", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.5, r2 + 0.8, r2 + 0.8), CFrame = CFrame.new(cx, Y + HUT_H + 0.75, cz) * UP, Material = MAT.SmoothPlastic, Color = stem })
						mushCap(CFrame.new(cx, Y + HUT_H + 1.5, cz), CAP_R, CAP_H, capColor, true)
						local lamp = part({ Name = "HutLight", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(cx, Y + 9, cz), Transparency = 1, CanCollide = false, CanQuery = false })
						local pl = Instance.new("PointLight")
						pl.Color, pl.Range, pl.Brightness = Color3.fromRGB(130, 200, 180), 26, 1.5
						pl.Parent = lamp
						-- the chest, against the far wall, its lock toward the door
						local cpos = Vector3.new(cx, Y + 0.9, cz) - u * (HUT_R - 2.4)
						local cf = CFrame.lookAt(cpos, cpos + u)
						part({ Name = "HutPlinth", Size = Vector3.new(5, 0.9, 3.6), CFrame = cf * CFrame.new(0, -0.45, 0), Material = MAT.Slate, Color = Color3.fromRGB(58, 56, 52) })
						local wood, iron = Color3.fromRGB(96, 70, 48), Color3.fromRGB(46, 42, 38)
						chestBody(cf, Vector3.new(3.6, 2.0, 2.2), MAT.WoodPlanks, wood, "HutChest")
						ring(cf * CFrame.new(0, 1.4, 0), Vector3.new(3.65, 0.25, 2.25), 0.27, MAT.Metal, iron, "HutChestBand", nil, false)
						part({ Name = "HutChestLock", Size = Vector3.new(0.4, 0.45, 0.1), CFrame = cf * CFrame.new(0, 1.7, -1.15), Material = MAT.Metal, Color = Color3.fromRGB(196, 160, 80), CanCollide = false })
						local lid = part({ Name = "HutChestLid", Size = Vector3.new(3.65, 0.4, 2.25), CFrame = cf * CFrame.new(0, 2.2, 0), Material = MAT.WoodPlanks, Color = wood })
						table.insert(info.MushroomChests, { Lid = lid, Hinge = cf * CFrame.new(0, 2.4, 1.1), Item = item, Prompt = prompt(lid, "Open", "Chest", 0.5, 7) })
						table.insert(info.Huts, { cx, cz, HUT_R + HUT_T + 4 })
						table.insert(info.Wilds.Avoid, { cx, cz, 14 })
					end
					local HUTS = {
						{ -122, 292, math.pi / 2, Color3.fromRGB(110, 40, 46), { Attr = "BleakManorKey", Text = "Key to Bleak Manor. Black iron, heavy, cold in the hand." } },
						{ -25, 405, 0, Color3.fromRGB(84, 58, 110), { Text = "Empty. Only a book's outline, pressed into the rotten cloth at the bottom." } },
						{ 72, 449, math.pi, Color3.fromRGB(140, 104, 60), { Attr = "Has_FoulDagger", Text = "Foul Dagger. A short black blade, slick with something that should not be wet." } },
					}
					for _, h in ipairs(HUTS) do
						hut(h[1], h[2], h[3], h[4], h[5])
					end

					-- (the walls stand well inside the crags that ring the mesa and the banks along the ramp, never
					-- among them: nobody can climb up a crag, or a house wall onto one, and get pinched between
					-- rock and wall. They're tall enough that no roof reaches their top, and CanQuery is off so
					-- the camera never sees them)
					local HP, HR, HH = HL.Plateau, HL.Ramp, HL.Hole
					local INS = 12
					local FX1, FX2, FZ1, FZ2 = HP.X1 + INS, HP.X2 - INS, HP.Z1 + INS, HP.Z2 - INS
					local function fence(x1, z1, x2, z2)
						local w = box(x1, 40, z1, x2, 400, z2, MAT.SmoothPlastic, COL.Wall, "HighlandEdge")
						w.Transparency, w.CanQuery, w.CastShadow = 1, false, false
					end
					local RX1, RX2 = HR.A.X - HR.W / 2 + 1.2, HR.A.X + HR.W / 2 - 1.2 -- (the ramp's walls, just inside its edges)
					fence(FX1 - 1, FZ1 - 1, FX1 + 1, FZ2 + 1) -- west
					fence(FX1 - 1, FZ1 - 1, -152, FZ1 + 1) -- south, either side of the gate
					fence(-124, FZ1 - 1, FX2 + 1, FZ1 + 1)
					fence(FX2 - 1, FZ1 - 1, FX2 + 1, FZ2 + 1) -- east
					fence(RX2 - 0.75, FZ2 - 1, FX2 + 1, FZ2 + 1) -- north, east of the ramp's mouth
					fence(RX1 - 0.75, FZ2 - 1, FX1 + 1, FZ2 + 1) -- ...and west of it
					fence(RX1 - 0.75, FZ2, RX1 + 0.75, HP.Z2 + 1) -- the lane the ramp comes up into, to the mesa's edge
					fence(RX2 - 0.75, FZ2, RX2 + 0.75, HP.Z2 + 1)
					for _, x in ipairs({ RX1, RX2 }) do -- and down the ramp itself
						local a, b = Vector3.new(x, HR.A.Y + 16, HR.A.Z), Vector3.new(x, HR.B.Y + 16, HR.B.Z)
						part({ Name = "HighlandEdge", Size = Vector3.new(1.5, 40, (b - a).Magnitude + 4), CFrame = CFrame.lookAt((a + b) / 2, b), Transparency = 1, CanQuery = false, CastShadow = false })
					end
					info.CitadelDev = CFrame.lookAt(Vector3.new(-138, HP.Top + 3.5, 90), Vector3.new(-215, HP.Top + 3.5, 10))
					info.MesaDev = CFrame.lookAt(Vector3.new(-150, HP.Top + 3.5, 183), Vector3.new(-131, HP.Top + 3.5, 160))
					-- the hole: a stone-lined shaft from the mesa's grass down to the chapel's roof, exactly the
					-- roof's own opening (MapBuilder section 9: x -135..-127, z 155..165 above the altar)
					local lining = Color3.fromRGB(70, 66, 60)
					for _, q in ipairs({
						{ HH.X1 - 6, HH.Z2, HH.X2 + 6, HH.Z2 + 5 }, { HH.X1 - 6, HH.Z1 - 5, HH.X2 + 6, HH.Z1 },
						{ HH.X1 - 6, HH.Z1, HH.X1, HH.Z2 }, { HH.X2, HH.Z1, HH.X2 + 6, HH.Z2 },
					}) do
						box(q[1], HH.Roof, q[2], q[3], HP.Top + 0.05, q[4], MAT.Slate, lining, "HoleLining")
					end
					-- an iron grate over the hole, so nobody tumbles in by accident: a prompt beside it slides it aside
					do
						local gy, gparts = HP.Top + 0.1, {}
						local iron = Color3.fromRGB(40, 36, 32)
						for z = HH.Z1 + 0.6, HH.Z2 - 0.3, 1.2 do
							table.insert(gparts, box(HH.X1 - 0.6, gy, z - 0.2, HH.X2 + 0.6, gy + 0.3, z + 0.2, MAT.Metal, iron, "GrateBar"))
						end
						for x = HH.X1 + 0.5, HH.X2, 2.7 do
							table.insert(gparts, box(x - 0.2, gy + 0.3, HH.Z1 - 0.6, x + 0.2, gy + 0.6, HH.Z2 + 0.6, MAT.Metal, iron, "GrateBar"))
						end
						local plate = box(HH.X1 - 0.6, gy - 0.4, HH.Z1 - 0.6, HH.X2 + 0.6, gy, HH.Z2 + 0.6, MAT.Metal, iron, "GratePlate")
						plate.Transparency, plate.CanQuery = 1, false -- (the bars alone have gaps a foot could find)
						table.insert(gparts, plate)
						local gp = part({ Name = "GratePrompt", Size = Vector3.new(2, 1, 2), CFrame = CFrame.new((HH.X1 + HH.X2) / 2, gy + 1, HH.Z1 - 2.5), Transparency = 1, CanCollide = false, CanQuery = false })
						info.HoleGrate = { Parts = gparts, Prompt = prompt(gp, "Slide aside", "Grate", 1.0, 9) }
					end
					-- the winch for the Citadel's gate, on the town's side of it: its crank is gone (the Steel Crank, from the
					-- Usher's chest, fits it)
					do
						local wx, wz = -129, 114.5
						local stone, iron = Color3.fromRGB(70, 66, 60), Color3.fromRGB(40, 36, 32)
						box(wx - 1.6, HP.Top, wz - 1.6, wx + 1.6, HP.Top + 3, wz + 1.6, MAT.Cobblestone, stone, "WinchBase")
						part({ Name = "WinchDrum", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3.2, 2.2, 2.2), CFrame = CFrame.new(wx, HP.Top + 4.4, wz), Material = MAT.Metal, Color = iron })
						part({ Name = "WinchSocket", Size = Vector3.new(0.6, 0.6, 0.6), CFrame = CFrame.new(wx + 1.9, HP.Top + 4.4, wz), Material = MAT.Metal, Color = Color3.fromRGB(20, 18, 16), CanCollide = false })
						part({ Name = "WinchChain", Size = Vector3.new(0.3, 8, 0.3), CFrame = CFrame.new(wx - 1.2, HP.Top + 7, wz - 0.4), Material = MAT.Metal, Color = iron, CanCollide = false })
						-- the crank itself, there once it's fitted: a handle on a long arm, spun on the drum's axis
						local crank = part({ Name = "SteelCrank", Size = Vector3.new(0.4, 0.4, 3.4), CFrame = CFrame.new(wx + 2.6, HP.Top + 4.4, wz), Material = MAT.Metal, Color = Color3.fromRGB(150, 154, 160), Transparency = 1, CanCollide = false })
						local knob = part({ Name = "SteelCrankKnob", Size = Vector3.new(0.4, 1.4, 0.4), CFrame = CFrame.new(wx + 2.8, HP.Top + 4.4, wz - 1.6), Material = MAT.Metal, Color = Color3.fromRGB(150, 154, 160), Transparency = 1, CanCollide = false })
						local pp = part({ Name = "WinchPrompt", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(wx, HP.Top + 4.5, wz), Transparency = 1, CanCollide = false, CanQuery = false })
						info.CitadelWinch = { Crank = { crank, knob }, Prompt = prompt(pp, "Fit the crank", "Gate Winch", 0.6, 8) }
					end

					for x = -198, 110, 12 do
						for z = 256, 483, 12 do
							local p = Vector3.new(x + wn(-4, 4), Y, z + wn(-4, 4))
							local clear = not (p.X > -200 and p.X < -144 and p.Z > 232 and p.Z < 352) -- (the ramp's way up)
							for _, m in ipairs(MAGES) do
								clear = clear and (p.X - m[1]) ^ 2 + (p.Z - m[2]) ^ 2 > 64
							end
							for _, h in ipairs(HUTS) do
								clear = clear and (p.X - h[1]) ^ 2 + (p.Z - h[2]) ^ 2 > (CAP_R + 6) ^ 2
							end
							if clear and inNew(p.X, p.Z, 4) and (p - C).Magnitude > 72 and wr:NextNumber() < (inNew(p.X, p.Z, 14) and 0.65 or 0.9) then
								if wr:NextNumber() < 0.55 then
									mushroom(p)
								else
									tree(p, wn(0.8, 1.25))
								end
							end
						end
					end
					wr = saved
				end

				-- errant knights (Characters/Errant) keeping the way to the colosseum, in ones and twos
				for _, k in ipairs({ { 82, 511, 1 }, { 50, 527, 2 }, { 18, 524, 3 }, { -10, 512, 4 }, { -36, 525, 5 } }) do
					local pathAt = PATH[k[3] + 1]
					table.insert(info.EnemySpawns, { Type = "Errant", CFrame = CFrame.lookAt(Vector3.new(k[1], Y + 3.2, k[2]), Vector3.new(pathAt.X, Y + 3.2, pathAt.Z)) })
				end

				-- THE CROWNED COLOSSEUM
				local MARBLE, MARBLE_DARK, SAND, GOLD = Color3.fromRGB(206, 198, 182), Color3.fromRGB(170, 162, 148), Color3.fromRGB(196, 176, 138), Color3.fromRGB(196, 160, 80)
				local FT = Y + 0.8 -- the floor's top
				local SHAFT, N = 20, 44 -- column height, columns per row
				local ROWS = { 46, 53, 60 }
				-- (a thick slab, and the terrain cleared out of its circle - info.Wilds.Clear - so no
				-- ground or grass shows up through it)
				part({ Name = "ColosseumFloor", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3.2, 126, 126), CFrame = CFrame.new(C.X, Y - 0.8, C.Z) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Slate, Color = MARBLE_DARK })
				info.Wilds.Clear = { Centre = C, Radius = 63, Bottom = Y - 2, Top = Y + 14 }
				-- the gilded ring, then the sand on it, each stepped clearly up off the one below (any two
				-- tops within a hair of each other flicker against each other)
				part({ Name = "ArenaRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 88, 88), CFrame = CFrame.new(C.X, FT - 0.15, C.Z) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Marble, Color = GOLD })
				part({ Name = "ArenaSand", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 86, 86), CFrame = CFrame.new(C.X, FT, C.Z) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Sand, Color = SAND })
				local function around(r, a, y)
					return Vector3.new(C.X + math.cos(a) * r, y, C.Z + math.sin(a) * r)
				end
				local step = math.pi * 2 / N
				for row, r in ipairs(ROWS) do -- each row a third of a step on from the last: together they close every line of sight
					for k = 0, N - 1 do
						local a = (k + (row - 1) / 3) * step
						local p = around(r, a, FT)
						local face = CFrame.Angles(0, -a, 0)
						part({ Name = "ColumnBase", Size = Vector3.new(3.8, 1, 3.8), CFrame = CFrame.new(p + Vector3.new(0, 0.5, 0)) * face, Material = MAT.Marble, Color = MARBLE_DARK })
						part({ Name = "Column", Shape = Enum.PartType.Cylinder, Size = Vector3.new(SHAFT, 2.8, 2.8), CFrame = CFrame.new(p + Vector3.new(0, 1 + SHAFT / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Marble, Color = MARBLE })
						part({ Name = "Capital", Size = Vector3.new(3.8, 1.2, 3.8), CFrame = CFrame.new(p + Vector3.new(0, 1.6 + SHAFT, 0)) * face, Material = MAT.Marble, Color = MARBLE_DARK })
						-- the architrave, column to column
						local m = around(r, a + step / 2, FT + 2.2 + SHAFT + 1.1)
						local tangent = Vector3.new(-math.sin(a + step / 2), 0, math.cos(a + step / 2))
						part({ Name = "Architrave", Size = Vector3.new(3.4, 2.2, 2 * r * math.sin(step / 2) + 1), CFrame = CFrame.lookAt(m, m + tangent), Material = MAT.Marble, Color = MARBLE })
					end
				end
				-- the colonnade's roof (r 44..62), a parapet round its inner edge, and the high attic
				-- wall round its outer one, gold-banded, that the funnel of rock rises off
				local ROOF = FT + 2.2 + SHAFT + 2.2 -- (the architraves' tops)
				local M = 88
				for k = 0, M - 1 do
					local a = (k + 0.5) / M * math.pi * 2
					local radial = Vector3.new(math.cos(a), 0, math.sin(a))
					local function seg(name, r1, r2, y1, y2, color, mat)
						local c = around((r1 + r2) / 2, a, (y1 + y2) / 2)
						part({ Name = name, Size = Vector3.new(2 * r2 * math.sin(math.pi / M) + 0.5, y2 - y1, r2 - r1), CFrame = CFrame.lookAt(c, c + radial), Material = mat or MAT.Marble, Color = color })
					end
					seg("ColonnadeRoof", 44, 62, ROOF, ROOF + 2, MARBLE_DARK)
					seg("Parapet", 44, 45.5, ROOF + 2, ROOF + 4, MARBLE)
					seg("Attic", 60.5, 62, ROOF + 2, ROOF + 9, MARBLE)
					seg("AtticBand", 60.3, 62.2, ROOF + 5, ROOF + 5.8, GOLD, MAT.Metal)
					seg("Cornice", 59.8, 62.8, ROOF + 9, ROOF + 10, MARBLE_DARK)
				end
				info.Wilds.Funnel.Base = ROOF + 2
				-- braziers along the approach, and round the sand
				local function brazier(p, h)
					part({ Name = "BrazierStand", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 0.6, 0.6), CFrame = CFrame.new(p + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Metal, Color = Color3.fromRGB(60, 54, 46) })
					local bowl = part({ Name = "Brazier", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 2.6, 2.6), CFrame = CFrame.new(p + Vector3.new(0, h + 0.3, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Metal, Color = GOLD })
					local f = Instance.new("Fire")
					f.Size, f.Heat = 4, 8
					f.Parent = bowl
					local l = Instance.new("PointLight")
					l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 170, 90), 20, 1.4
					l.Parent = bowl
					addFlicker(l)
				end
				for _, z in ipairs({ -6, 6 }) do
					brazier(Vector3.new(C.X + 68, FT - 0.8, C.Z + z), 4)
					brazier(Vector3.new(C.X + 82, FT - 0.8, C.Z + z), 4)
				end
				for k = 0, 5 do
					brazier(around(41, k / 6 * math.pi * 2 + 0.3, FT), 4.5)
				end
				-- the Crowned Champion's arena (Characters/Champion): he waits crouched on the parapet
				-- at the far side from the way in, and while he fights a shimmering wall rings the
				-- sand inside the columns (the seal: no collision, unseen, until then)
				local sandTop = FT + 0.3
				local seal = {}
				for k = 0, N - 1 do
					local a = (k + 0.5) / N * math.pi * 2
					local c = around(43.8, a, sandTop + 11)
					local p = part({ Name = "ChampionSeal", Size = Vector3.new(2 * 43.8 * math.sin(math.pi / N) + 0.3, 22, 0.6), CFrame = CFrame.lookAt(c, c + Vector3.new(math.cos(a), 0, math.sin(a))), Material = MAT.ForceField, Color = Color3.fromRGB(255, 210, 140), Transparency = 1, CanCollide = false, CanQuery = false, CastShadow = false })
					table.insert(seal, p)
				end
				local perch = around(44.75, math.pi, ROOF + 4)
				info.Champion = { Centre = Vector3.new(C.X, sandTop, C.Z), Radius = 40, Seal = seal, Perch = CFrame.lookAt(perch, Vector3.new(C.X, perch.Y, C.Z)) }
				-- (dev menu) out on the north side of the colonnade: past the woods, and well over 40
				-- studs from every errant knight, so none of them comes for you
				info.ColosseumDev = CFrame.lookAt(Vector3.new(C.X, Y + 3.5, C.Z + 68), Vector3.new(C.X, Y + 3.5, C.Z))
				-- paving out to meet the track
				for x = C.X + 63, C.X + 76, 3.2 do
					part({ Name = "Paving", Size = Vector3.new(3.1, 0.6, 9), CFrame = CFrame.new(x, Y + 0.3, C.Z + wn(-0.3, 0.3)) * CFrame.Angles(0, wn(-0.03, 0.03), 0), Material = MAT.Slate, Color = MARBLE_DARK:Lerp(Color3.fromRGB(90, 96, 80), wn(0, 0.4)) })
				end
				-- the grand gate in the north wall, just out of the tunnel, and the decayed land past it (DecayedPalace):
				-- its ground and outline now, for the terrain pass; the rest is built last
				local ok, err = pcall(DecayedPalace.plan, { part = part, box = box, info = info, map = map })
				if not ok then
					warn("[DGUS] DecayedPalace.plan: " .. tostring(err))
				end
			end

			-- THE FAR TOWNSHIP: what the rot left of a hamlet over the gorge - the camp's crooked
			-- shacks again, slime, bones and arms out of the ground, round an open patch where the
			-- Rotted Ushers wander (spawns in info.EnemySpawns). Its own random streams, so
			-- nothing built after it shifts.
			local campEr = er
			er = Random.new(5050)
			local oldFarRng = Detail.useRng(Random.new(5051))
			for _, s in ipairs({
				{ 212, 630, LEDGE_Y + 1.5, 7, 6, 6, 0.3 }, { 214, 652, LEDGE_Y + 2, 8, 7, 7, -0.2 }, { 234, 660, LEDGE_Y + 1, 9, 7, 7, 0.1 },
				{ 256, 655, LEDGE_Y + 2.5, 7, 7, 6, -0.4 }, { 258, 632, LEDGE_Y + 1, 6, 6, 6, 0.6 },
				-- the turn east
				{ 300, 667, LEDGE_Y + 1, 7, 6, 6, -0.3 }, { 272, 699, LEDGE_Y + 2, 8, 6, 7, 0.4 }, { 318, 681, LEDGE_Y + 1.5, 6, 6, 6, 1.2 },
				-- and north again, to the ravine's dead end
				{ 298, 730, LEDGE_Y + 2, 7, 7, 6, 0.1 }, { 327, 750, LEDGE_Y + 1.5, 6, 6, 6, -0.5 }, { 305, 766, LEDGE_Y + 2.5, 8, 7, 7, 0.3, true },
			}) do
				shack(s[1], s[2], s[3], s[4], s[5], s[6], s[7], s[8])
			end
			-- the tunnel's key, on the floor of the doored shack at the dead end (Map.Pickups.TunnelKey)
			do
				local kcf = CFrame.new(305, LEDGE_Y + 3.1, 766) * CFrame.Angles(0, 0.3, 0) * CFrame.new(2.4, 0, 2.2) * CFrame.Angles(0, 0.7, 0)
				local RUST = Color3.fromRGB(110, 70, 44)
				local parts = {
					part({ Name = "TunnelKey", Size = Vector3.new(0.15, 0.15, 1.6), CFrame = kcf, Material = MAT.CorrodedMetal, Color = RUST, CanCollide = false }),
					part({ Name = "TunnelKey", Shape = Enum.PartType.Ball, Size = Vector3.one * 0.6, CFrame = kcf * CFrame.new(0, 0, 0.9), Material = MAT.CorrodedMetal, Color = RUST, CanCollide = false }),
					part({ Name = "TunnelKey", Size = Vector3.new(0.12, 0.15, 0.45), CFrame = kcf * CFrame.new(0.22, 0, -0.6), Material = MAT.CorrodedMetal, Color = RUST, CanCollide = false }),
				}
				local glow = part({ Name = "PickupGlow", Size = Vector3.new(0.4, 0.4, 0.4), CFrame = kcf * CFrame.new(0, 0.3, 0), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
				table.insert(parts, glow)
				local l = Instance.new("PointLight")
				l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 220, 150), 9, 1.2
				l.Parent = glow
				info.Pickups.TunnelKey = { Prompt = prompt(glow, "Take", "Tunnel Key", 0.3, 7), Parts = parts, Glow = glow }
			end
			for _, pl in ipairs({ { 236, 642, 5 }, { 222, 662, 3 }, { 290, 685, 5 }, { 315, 742, 4 } }) do
				part({ Name = "Slime", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.1, pl[3] * 2, pl[3] * 2), CFrame = CFrame.new(pl[1], LEDGE_Y + 0.04, pl[2]) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Glass, Color = Rot.Slime, Transparency = 0.15, CanCollide = false })
				Detail.boils(Vector3.new(pl[1], LEDGE_Y, pl[2]), 6, pl[3] * 0.8, 0.35)
			end
			for _, b in ipairs({ { 224, 640 }, { 249, 646 }, { 244, 664 }, { 260, 690 }, { 310, 697 }, { 320, 725 }, { 300, 750 } }) do
				Detail.bonePile(Vector3.new(b[1], LEDGE_Y, b[2]), 6)
			end
			Detail.slumpedSkeleton(Vector3.new(246, LEDGE_Y, 626), Vector3.new(-1, 0, 0))
			Detail.slumpedSkeleton(Vector3.new(330, LEDGE_Y, 730), Vector3.new(-1, 0, 0))
			for _, p in ipairs({ { 220, 646 }, { 252, 640 }, { 240, 652 }, { 228, 632 }, { 285, 675 }, { 305, 690 }, { 312, 710 }, { 295, 760 }, { 325, 768 } }) do
				limb(Vector3.new(p[1], LEDGE_Y, p[2]), randDir(Vector3.new(0, 1.5, 0)), n(0.8, 1.2))
			end

			-- BUILT UP INTO THE MOUNTAINS: more shacks crowding the ravine's edges, and up its
			-- walls on every side huts on tall stilts in two tiers, notched into the rock (the
			-- terrain pass clears F.Carve), strung together by sagging plank bridges. All of it
			-- outside the rim, out of reach. Its own streams again, so nothing above shifts.
			er = Random.new(5052)
			Detail.useRng(Random.new(5053))
			for _, s in ipairs({
				{ 211, 641, 1.5, 6, 6, 6, -0.3 }, { 210, 666, 2, 7, 6, 6, 0.25 }, { 222, 670, 1, 7, 6, 7, -0.1 }, { 261, 644, 1.5, 6, 7, 6, 0.5 },
				{ 278, 665, 1, 7, 6, 6, 0.2 }, { 288, 664, 2, 6, 6, 7, -0.35 }, { 252, 699, 1.5, 7, 6, 6, 0.3 }, { 284, 700, 2, 7, 6, 6, -0.2 },
				{ 294, 712, 1, 6, 6, 6, 0.6 }, { 330, 712, 1.5, 6, 7, 6, 0.4 }, { 330, 728, 2, 6, 6, 6, -0.3 }, { 294, 748, 1.5, 6, 7, 6, 0.2 },
				{ 322, 770, 2, 7, 6, 7, -0.4 },
			}) do
				shack(s[1], s[2], LEDGE_Y + s[3], s[4], s[5], s[6], s[7])
			end
			stiltHut(270, 683, LEDGE_Y + 13, 8, 7, 6, 0.25, LEDGE_Y) -- high over the turn east (walk under it)
			watchtower(318, 718, 14, LEDGE_Y)
			woodSpire(226, 646, 18, LEDGE_Y)
			woodSpire(322, 700, 16, LEDGE_Y)
			local carve = info.FarSide.Carve
			local function toFloor(x, z) -- how far (x, z) is from the nearest bit of ravine floor
				local best = math.huge
				for _, q in ipairs(RAVINE) do
					local dx, dz = math.max(q[1] - x, 0, x - q[3]), math.max(q[2] - z, 0, z - q[4])
					best = math.min(best, math.sqrt(dx * dx + dz * dz))
				end
				return best
			end
			local function sagBridge(a, b)
				local mid = (a + b) / 2 + Vector3.new(0, 1.5, 0)
				table.insert(carve, { CFrame.lookAt(mid, mid + (b - a)), Vector3.new(4, 5, (b - a).Magnitude) })
				local steps = math.max(2, math.floor((b - a).Magnitude / 1.1))
				for k = 0, steps do
					if er:NextNumber() < 0.85 then
						local p = a:Lerp(b, k / steps) - Vector3.new(0, math.sin(k / steps * math.pi) * 1.5, 0)
						plank(Vector3.new(1.0, 0.4, 3.2), CFrame.lookAt(p, p + (b - a)) * CFrame.Angles(0, math.pi / 2, n(-0.08, 0.08)))
					end
				end
			end
			for i, a in ipairs(OUTLINE) do
				local b = OUTLINE[i % #OUTLINE + 1]
				local A, B = Vector3.new(a[1], 0, a[2]), Vector3.new(b[1], 0, b[2])
				local d = (B - A).Unit
				local out = Vector3.new(d.Z, 0, -d.X)
				local yaw = math.atan2(out.X, out.Z) -- (a shack's front, local -Z, faces back into the ravine)
				for _, tier in ipairs({ { 9, 16, 3.5, 5, 0.9 }, { 24, 36, 5, 8, 0.55 } }) do -- rise min/max, set-back min/max, chance
					local prev
					for s = 8, (B - A).Magnitude - 8, 15 do
						local p = A + d * (s + n(-2, 2))
						local H = n(tier[1], tier[2])
						local c = p + out * (H / 3 + n(tier[3], tier[4])) -- (the rock leans back about a stud per three up)
						local w, dd, h = er:NextInteger(6, 8), er:NextInteger(6, 7), er:NextInteger(6, 7)
						if er:NextNumber() < tier[5] and toFloor(c.X, c.Z) > dd / 2 + 2.5 and not (i == 1 and p.X > 220 and p.X < 252) then
							local hy, floorY = yaw + n(-0.25, 0.25), LEDGE_Y + H
							stiltHut(c.X, c.Z, floorY, w, dd, h, hy, LEDGE_Y)
							local hcf = CFrame.new(c.X, floorY, c.Z) * CFrame.Angles(0, hy, 0)
							local zBack, zFront = dd / 2 + 1.5, -((c - p).Magnitude - 1) -- the notch runs out to the rim
							table.insert(carve, { hcf * CFrame.new(0, h / 2 + 1.5, (zBack + zFront) / 2), Vector3.new(w + 3, h + 4.5, zBack - zFront) })
							local door = hcf * Vector3.new(0, 0.2, -dd / 2 - 0.6)
							if prev then
								sagBridge(prev, door)
							end
							prev = door
						else
							prev = nil
						end
					end
				end
			end
			Detail.useRng(oldFarRng)
			er = campEr
		end

		-- slime pools, bones, the dead, the odd lantern
		for _, pl in ipairs({ { 196, 466, 7 }, { 222, 512, 5 }, { 250, 458, 6 }, { 270, 476, 4 } }) do
			part({ Name = "Slime", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.1, pl[3] * 2, pl[3] * 2), CFrame = CFrame.new(pl[1], 0.04, pl[2]) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Glass, Color = Rot.Slime, Transparency = 0.15, CanCollide = false })
			Detail.boils(Vector3.new(pl[1], 0, pl[2]), 6, pl[3] * 0.8, 0.35)
		end
		for _, b in ipairs({ { 188, 488 }, { 215, 485 }, { 247, 462 }, { 265, 492 }, { 200, 515 } }) do
			Detail.bonePile(Vector3.new(b[1], 0, b[2]), 6)
		end
		Detail.slumpedSkeleton(Vector3.new(230, 0, 462), Vector3.new(0, 0, 1))
		Detail.slumpedSkeleton(Vector3.new(178, 0, 486), Vector3.new(1, 0, 0))
		Detail.overgrownCorpse(Vector3.new(248, 0, 512), Vector3.new(-1, 0, 0))
		for _, lp in ipairs({ { 226, 9, 468 }, { 262, 13.5, 470 }, { 236, 23.5, 498 }, { 198, LEDGE_Y + 6, 524 } }) do
			local lantern = part({ Name = "Lantern", Size = Vector3.new(0.7, 1, 0.7), CFrame = CFrame.new(lp[1], lp[2], lp[3]), Material = MAT.Neon, Color = Color3.fromRGB(255, 150, 70), CanCollide = false })
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 160, 90), 18, 1.3
			l.Parent = lantern
			addFlicker(l)
		end
		-- spores hanging in the air of the pit
		local air = part({ Name = "SporeAir", Size = Vector3.new(X2 - X1, 1, Z2 - Z1), CFrame = CFrame.new((X1 + X2) / 2, 18, (Z1 + Z2) / 2), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
		pe.Rate = 18
		pe.Lifetime = NumberRange.new(5, 9)
		pe.Speed = NumberRange.new(0.3, 1)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.Size = NumberSequence.new(2, 6)
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.8), NumberSequenceKeypoint.new(1, 1) })
		pe.Color = ColorSequence.new(Rot.Glow:Lerp(Color3.fromRGB(120, 120, 100), 0.5))
		pe.Parent = air

		-- a bonfire in the pit, a few steps from where the thing sets you down
		makeBonfire(Vector3.new(219, 0, 486), CFrame.lookAt(Vector3.new(214.5, 3.2, 486), Vector3.new(219, 3.2, 486)), "The Rot Below")
		Detail.useRng(oldDetailRng)
		info.NewArea = { Landing = CFrame.lookAt(Vector3.new(225, 3, 480), Vector3.new(240, 3, 470)) }
	end

	-- the land below and between: real terrain over every patch of void out to the mountains,
	-- so nothing looks down on empty sky. A cell counts as built (and is left alone) if any of
	-- five rays down through it touch the map. Next to the built it's a low, lumpy chasm floor
	-- well under every floor (and kept inside its own cell); further out it swells into
	-- rolling hills broken by tilted outcrops of rock. Nobody can reach it. (The place has no
	-- terrain of its own: this owns workspace.Terrain, and clears it on a rebuild.)
	do
		local terrain = workspace.Terrain
		terrain:Clear()
		terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(62, 58, 54))
		terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(54, 49, 42))
		terrain:SetMaterialColor(Enum.Material.Slate, Color3.fromRGB(52, 50, 48))
		terrain:SetMaterialColor(Enum.Material.Mud, Color3.fromRGB(44, 40, 34))
		local lr = Random.new(2718) -- (its own seed)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { map }
		local CELL, REACH, FLOOR = 32, 560, -14
		local centre = Vector3.new(80, 0, 220)
		local n = math.ceil(REACH / CELL)
		local function hits(x, z)
			return workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -400, 0), params) ~= nil
		end
		local built = {}
		for i = -n, n do
			built[i] = {}
			for j = -n, n do
				local x, z, h = centre.X + i * CELL, centre.Z + j * CELL, CELL / 2 - 1
				built[i][j] = hits(x, z) or hits(x - h, z - h) or hits(x + h, z - h) or hits(x - h, z + h) or hits(x + h, z + h)
			end
		end
		local function nearBuilt(i, j, r)
			for di = -r, r do
				for dj = -r, r do
					if built[i + di] and built[i + di][j + dj] then
						return true
					end
				end
			end
			return false
		end
		-- the bedrock: one low floor under everything (below the deepest of the map, the sewer at -8)
		local span = REACH * 2 + 200
		for _, q in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
			terrain:FillBlock(CFrame.new(centre.X + q[1] * span / 4, FLOOR - 13, centre.Z + q[2] * span / 4), Vector3.new(span / 2, 26, span / 2), Enum.Material.Slate)
		end
		local MATS = { Enum.Material.Ground, Enum.Material.Ground, Enum.Material.Slate, Enum.Material.Mud }
		for i = -n, n do
			for j = -n, n do
				local d = Vector2.new(i, j).Magnitude * CELL
				if not built[i][j] and d <= REACH then
					local x, z = centre.X + i * CELL, centre.Z + j * CELL
					if nearBuilt(i, j, 2) then
						-- the chasm floor: a few low lumps, each well inside its own cell
						for _ = 1, 2 do
							local r = lr:NextNumber(7, 12)
							terrain:FillBall(Vector3.new(x + lr:NextNumber(-3, 3), FLOOR - r + lr:NextNumber(2, 7), z + lr:NextNumber(-3, 3)), r, MATS[lr:NextInteger(1, #MATS)])
						end
					else
						-- out in the open: a hill (it may spill into its neighbours: they're all open too)
						local t = math.clamp((d - 120) / 380, 0, 1)
						local top = lr:NextNumber(-10, 6 + 70 * t * t)
						local r = lr:NextNumber(20, 34) + t * 10
						terrain:FillBall(Vector3.new(x + lr:NextNumber(-8, 8), top - r, z + lr:NextNumber(-8, 8)), r, MATS[lr:NextInteger(1, #MATS)])
						if top > FLOOR + 6 then -- fill the hill's skirt down to the bedrock
							terrain:FillBlock(CFrame.new(x, (FLOOR + top - r * 0.5) / 2, z), Vector3.new(CELL * 0.9, math.max(top - r * 0.5 - FLOOR, 4), CELL * 0.9), Enum.Material.Ground)
						end
						if lr:NextNumber() < 0.3 then -- an outcrop: a tilted slab of rock breaking through
							local h = lr:NextNumber(10, 28) + t * 20
							terrain:FillBlock(CFrame.new(x + lr:NextNumber(-8, 8), top + h * 0.2, z + lr:NextNumber(-8, 8)) * CFrame.Angles(lr:NextNumber(-0.5, 0.5), lr:NextNumber(0, 6), lr:NextNumber(-0.5, 0.5)), Vector3.new(lr:NextNumber(8, 16), h, lr:NextNumber(6, 12)), Enum.Material.Rock)
						end
					end
				end
			end
		end
		-- the encampment's cliffs: heaps of rock over and behind their tops, so they read as a
		-- rim of broken ground rather than four walls (all of it outside the pit, out of reach)
		local E = { X1 = 170, Z1 = 452, X2 = 280, Z2 = 540 }
		for _, side in ipairs({
			{ Vector3.new(E.X1, 0, E.Z1), Vector3.new(E.X2, 0, E.Z1), Vector3.new(0, 0, -1) },
			{ Vector3.new(E.X1, 0, E.Z2), Vector3.new(E.X2, 0, E.Z2), Vector3.new(0, 0, 1) },
			{ Vector3.new(E.X1, 0, E.Z1), Vector3.new(E.X1, 0, E.Z2), Vector3.new(-1, 0, 0) },
			{ Vector3.new(E.X2, 0, E.Z1), Vector3.new(E.X2, 0, E.Z2), Vector3.new(1, 0, 0) },
		}) do
			local a, b, out = side[1], side[2], side[3]
			local len = (b - a).Magnitude
			local south = out.Z < 0 -- (the Upper Town is just past that side: small rocks only there)
			for s = 0, len, south and 8 or 11 do
				local r = south and lr:NextNumber(7, 10) or lr:NextNumber(10, 17)
				local p = a + (b - a).Unit * s + out * (r * 0.95 + 2)
				local crossing = out.Z > 0 and p.X > 200 and p.X < 270 -- (keep the chasm clear for the bridge)
				if not crossing then
					terrain:FillBall(p + Vector3.new(0, lr:NextNumber(32, 46), 0), r, Enum.Material.Rock)
				end
				if not south and not crossing then
					terrain:FillBall(p + out * lr:NextNumber(6, 14) + Vector3.new(0, lr:NextNumber(18, 32), 0), r * 1.2, Enum.Material.Ground)
				end
			end
		end
		-- the gorge the crossing spans: rock walls heaped up either side (clear of the bridge's
		-- corridor, x 216..254), crags breaking out of them, and a lumpy floor far below
		for z = 542, 618, 7 do
			for _, side in ipairs({ -1, 1 }) do
				local edge = side < 0 and 208 or 262 -- (the wall's inner face)
				for _, y in ipairs({ -10, 4, 16 }) do
					local r = lr:NextNumber(11, 17)
					local x = edge + side * (r + lr:NextNumber(0, 4))
					terrain:FillBall(Vector3.new(x, y + lr:NextNumber(-3, 3), z + lr:NextNumber(-3, 3)), r, lr:NextNumber() < 0.6 and Enum.Material.Rock or Enum.Material.Slate)
				end
				local top = lr:NextNumber(18, 30)
				local r = lr:NextNumber(8, 12)
				terrain:FillBall(Vector3.new(edge + side * (r + lr:NextNumber(2, 8)), top - r * 0.4, z + lr:NextNumber(-3, 3)), r, Enum.Material.Ground)
				if lr:NextNumber() < 0.35 then -- a crag of rock jutting from the wall's top, leaning out
					local h = lr:NextNumber(10, 20)
					local x = edge + side * (8 + lr:NextNumber(0, 6))
					terrain:FillBlock(CFrame.new(x, top + h * 0.3, z) * CFrame.Angles(lr:NextNumber(-0.3, 0.3), lr:NextNumber(0, 6), side * lr:NextNumber(0.1, 0.4)), Vector3.new(lr:NextNumber(5, 9), h, lr:NextNumber(4, 7)), Enum.Material.Rock)
				end
			end
			for _ = 1, 2 do -- the floor
				local r = lr:NextNumber(6, 10)
				terrain:FillBall(Vector3.new(lr:NextNumber(214, 256), -14 - r + lr:NextNumber(2, 5), z + lr:NextNumber(-3, 3)), r, lr:NextNumber() < 0.5 and Enum.Material.Mud or Enum.Material.Slate)
			end
		end
		-- THE VALLEYS walled in by mountains - the ravine over the Crossing (info.FarSide) and
		-- the Weald past the west tunnel (info.Wilds): natural ground laid over their slabs, and
		-- walls of dark rock heaped up round their outlines into broken crags. Every lump is kept
		-- clear of the floor: one that would reach in over it is shrunk to touch. (F.Gap: a stretch
		-- of one edge left open; F.Avoid: circles kept clear of lumps and stones; F.Mats: floor,
		-- then the three the mounds are made of; F.Low: walls of foothills, not mountains.)
		terrain:SetMaterialColor(Enum.Material.Basalt, Color3.fromRGB(34, 32, 32))
		terrain:SetMaterialColor(Enum.Material.LeafyGrass, Color3.fromRGB(58, 66, 42))
		terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(62, 70, 46))
		local function valley(F, seed)
			local fr = Random.new(seed) -- (its own stream)
			local function toFloor(x, z) -- how far (x, z) is from the nearest bit of valley floor (or of F.Keep: others' floors)
				local best = math.huge
				for _, list in ipairs({ F.Rects, F.Keep or {} }) do
					for _, q in ipairs(list) do
						local dx = math.max(q[1] - x, 0, x - q[3])
						local dz = math.max(q[2] - z, 0, z - q[4])
						best = math.min(best, math.sqrt(dx * dx + dz * dz))
					end
				end
				return best
			end
			local function lump(pos, r, mat)
				r = math.min(r, toFloor(pos.X, pos.Z) - 0.5)
				if r >= 3 then
					terrain:FillBall(pos, r, mat)
				end
			end
			local function avoided(x, z, pad)
				for _, c in ipairs(F.Avoid or {}) do
					if (x - c[1]) ^ 2 + (z - c[2]) ^ 2 < (c[3] + pad) ^ 2 then
						return true
					end
				end
				return false
			end
			local M = F.Mats or { Enum.Material.Ground, Enum.Material.Ground, Enum.Material.Mud, Enum.Material.Slate }
			-- the floor, with low mounds and patches, and stones
			for _, q in ipairs(F.Rects) do
				terrain:FillBlock(CFrame.new((q[1] + q[3]) / 2, F.Y - 4, (q[2] + q[4]) / 2), Vector3.new(q[3] - q[1], 8, q[4] - q[2]), M[1])
				local area = (q[3] - q[1]) * (q[4] - q[2])
				for _ = 1, math.floor(area / 70) do
					local x, z = fr:NextNumber(q[1] + 2, q[3] - 2), fr:NextNumber(q[2] + 2, q[4] - 2)
					local rr = fr:NextNumber(3, 7)
					local pick = fr:NextNumber()
					local mat = pick < 0.5 and M[2] or pick < 0.75 and M[3] or M[4]
					local y = F.Y - rr + fr:NextNumber(0.1, 0.7)
					if not avoided(x, z, rr) then
						terrain:FillBall(Vector3.new(x, y, z), rr, mat)
					end
				end
				for _ = 1, math.floor(area / 400) do
					local rr = fr:NextNumber(0.8, 1.8)
					local x, z = fr:NextNumber(q[1] + 3, q[3] - 3), fr:NextNumber(q[2] + 3, q[4] - 3)
					if not avoided(x, z, rr) then
						terrain:FillBall(Vector3.new(x, F.Y + rr * 0.2, z), rr, Enum.Material.Rock)
					end
				end
			end
			-- the walls, edge by edge round the outline: a foot of rock against the floor, a
			-- heavier mass above it leaning back, a mountain's shoulder above that, the odd crag
			local O = F.Outline
			local mats = { Enum.Material.Basalt, Enum.Material.Basalt, Enum.Material.Rock, Enum.Material.Slate }
			for i, a in ipairs(O) do
				local b = O[i % #O + 1]
				local A, B = Vector3.new(a[1], 0, a[2]), Vector3.new(b[1], 0, b[2])
				local d = (B - A).Unit
				local out = Vector3.new(d.Z, 0, -d.X)
				for s = -6, (B - A).Magnitude + 6, 7 do
					local p = A + d * s
					local g = F.Gap
					local along = (a[2] == b[2]) and p.X or p.Z
					local gapped = g and i == g[1] and along > g[2] and along < g[3]
					for _, h in ipairs(F.Gaps or {}) do
						gapped = gapped or (i == h[1] and along > h[2] and along < h[3])
					end
					if not gapped then
						local low = F.Low and not (F.High and F.High[i])
						local foot = F.Y + fr:NextNumber(-3, 3)
						local lays = low and { { foot, 8, 13, 0 }, { F.Y + 10, 8, 12, 3 }, { F.Y + 18, 6, 9, 8 } } or { { foot, 8, 13, 0 }, { F.Y + 16, 10, 16, 3 }, { F.Y + 34, 12, 19, 9 }, { F.Y + 52, 10, 16, 17 } }
						for k, lay in ipairs(lays) do
							local rr = fr:NextNumber(lay[2], lay[3])
							local c = p + out * (rr + 1 + lay[4] + fr:NextNumber(0, 3)) + d * fr:NextNumber(-3, 3)
							lump(Vector3.new(c.X, lay[1] + fr:NextNumber(-3, 3), c.Z), rr, mats[(k + i) % #mats + 1])
						end
						if fr:NextNumber() < 0.3 then -- a crag of rock jutting from the top, leaning out
							local h = low and fr:NextNumber(8, 12) or fr:NextNumber(14, 26)
							local c = p + out * fr:NextNumber(14, 22)
							if toFloor(c.X, c.Z) > 9 then
								terrain:FillBlock(CFrame.new(c.X, F.Y + (low and 18 or 50) + h * 0.3, c.Z) * CFrame.Angles(fr:NextNumber(-0.3, 0.3), fr:NextNumber(0, 6), fr:NextNumber(-0.3, 0.3)), Vector3.new(fr:NextNumber(5, 9), h, fr:NextNumber(4, 7)), Enum.Material.Basalt)
							end
						end
					end
				end
			end
		end
		local F = info.FarSide
		info.FarSide.Gap = { 1, F.Bridge[1], F.Bridge[2] } -- (the gap the bridge lands in)
		valley(F, 6060)
		local W = info.Wilds
		valley(W, 6070)
		if info.Decayed then -- (the dead wood, town and palace past the grand gate: DecayedPalace)
			valley(info.Decayed, 6100)
		end
		-- nothing of the ground under the colosseum's paving (snapped out to whole voxels)
		do
			local K = W.Clear
			local y1, y2 = math.floor(K.Bottom / 4) * 4, math.ceil(K.Top / 4) * 4
			terrain:FillCylinder(CFrame.new(K.Centre.X, (y1 + y2) / 2, K.Centre.Z), y2 - y1, K.Radius, Enum.Material.Air)
		end
		-- the Weald's track: trodden mud, flat, through whatever the mounds put there
		for i = 1, #W.Path - 1 do
			local a, b = W.Path[i], W.Path[i + 1]
			local mid, len = (a + b) / 2, (b - a).Magnitude + 5
			terrain:FillBlock(CFrame.lookAt(mid + Vector3.new(0, 2, 0), b + Vector3.new(0, 2, 0)), Vector3.new(6, 4, len), Enum.Material.Air)
			terrain:FillBlock(CFrame.lookAt(mid - Vector3.new(0, 1, 0), b - Vector3.new(0, 1, 0)), Vector3.new(6, 2, len), Enum.Material.Mud)
		end
		-- the colosseum's crown: a funnel of rock rising off its colonnade's roof, flaring out
		-- as it climbs, open to the sky in the middle, jagged round its lip
		do
			local Fn = W.Funnel
			info.HeightsRock = info.HeightsRock or {}
			local terrain = HeightsRuin.record(terrain, info.HeightsRock) -- (its rock, logged: Ossaria's slash empties it)
			local fr = Random.new(6080)
			local rings = 14
			for i = 0, rings do
				local t = i / rings
				local br = 8 + 4 * t
				local rc = Fn.Radius + 56 * t ^ 2 -- (steep, flaring near the lip out to the land on its top; its biggest rocks stay behind the rim skirt)
				local y = Fn.Base + br * 0.7 + t * (Fn.Height - br * 1.4)
				local count = math.ceil(math.pi * 2 * rc / (br * 0.9))
				for k = 1, count do
					local a = (k + fr:NextNumber(-0.3, 0.3)) / count * math.pi * 2
					local r = br * fr:NextNumber(0.85, 1.15)
					local mat = fr:NextNumber() < 0.6 and Enum.Material.Rock or Enum.Material.Basalt
					terrain:FillBall(Vector3.new(Fn.Centre.X + math.cos(a) * rc, y + fr:NextNumber(-1.5, 1.5), Fn.Centre.Z + math.sin(a) * rc), r, mat)
				end
			end
			for k = 1, 22 do -- crags hanging under the lip, leaning out
				local a = k / 22 * math.pi * 2 + fr:NextNumber(-0.1, 0.1)
				local rc = Fn.Radius + 52 + fr:NextNumber(-4, 4)
				local h = fr:NextNumber(10, 24)
				terrain:FillBlock(CFrame.new(Fn.Centre.X + math.cos(a) * rc, Fn.Top - 16 - h * 0.3, Fn.Centre.Z + math.sin(a) * rc) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, fr:NextNumber(-0.5, -0.2)), Vector3.new(fr:NextNumber(5, 9), h, fr:NextNumber(5, 8)), Enum.Material.Basalt)
			end
			-- the flat land on top (GildedHeights paves it, a voxel up: smoothed terrain's surface would show through at Top), and
			-- nothing of any mountain above it
			terrain:FillCylinder(CFrame.new(Fn.Centre.X, Fn.Top - 12, Fn.Centre.Z), 16, Fn.Rim - 4, Enum.Material.Rock)
			terrain:FillCylinder(CFrame.new(Fn.Centre.X, Fn.Top + 56, Fn.Centre.Z), 120, Fn.Rim + 6, Enum.Material.Air)
			-- its lowest rocks hang below the roof into the colonnade, and over the parapet the
			-- Champion perches on: none under the roof, and none inside the parapet's walk
			local K = W.Clear
			local under = Fn.Base - 1 - K.Top
			terrain:FillCylinder(CFrame.new(Fn.Centre.X, K.Top + under / 2, Fn.Centre.Z), under, 63, Enum.Material.Air)
			terrain:FillCylinder(CFrame.new(Fn.Centre.X, Fn.Base + Fn.Height / 2, Fn.Centre.Z), Fn.Height + 30, 48, Enum.Material.Air)
		end
		-- the hill heaped over the high bridge's tunnel, then the hollows cut out of the rock:
		-- the tunnel, and the notches the stilt huts up the ravine's walls sit in
		for _, b in ipairs(F.Fill) do
			terrain:FillBall(b[1], b[2], Enum.Material.Rock)
		end
		for _, c in ipairs(F.Carve) do
			terrain:FillBlock(c[1], c[2], Enum.Material.Air)
		end
		-- THE HILL OVER THE BLIND CHAPEL (info.Wilds.Highland): a ramp climbing out of the Highlands'
		-- basin onto a mesa that floats clear over the chapel's towers, a rim of crags round it, and a
		-- hole in it straight down the chapel's broken roof (the stone lining is MapBuilder's)
		do
			local H = W.Highland
			local P, Rp, Hh = H.Plateau, H.Ramp, H.Hole
			local hr = Random.new(6090)
			local ROCK, BASALT = Enum.Material.Rock, Enum.Material.Basalt
			local cx, cz = (P.X1 + P.X2) / 2, (P.Z1 + P.Z2) / 2
			-- the rolling hills the land pass left out here (and their tilted outcrops of rock) are cleared above
			-- the grass, over the citadel and the mesa, so nothing built up here is buried in a mountain
			terrain:FillBlock(CFrame.new(-204, 180, -69), Vector3.new(288, 240, 358), Enum.Material.Air)
			terrain:FillBlock(CFrame.new(-128, 180, 175), Vector3.new(136, 240, 134), Enum.Material.Air)
			for _, h in ipairs(info.Huts or {}) do -- the huts' floors: bare mud, so no blades of terrain grass poke up through them
				terrain:FillCylinder(CFrame.new(h[1], W.Y - 3, h[2]), 6, 13, Enum.Material.Mud)
			end
			local under = P.Top - P.Thick -- (the mesa's underside: a whole voxel, 4 studs, tall)
			-- the mesa, a grassy skin on rock; solid down to the bedrock along its west, south and north (the
			-- chapel's side stays open air under it)
			terrain:FillBlock(CFrame.new(cx, under + (P.Thick - 4) / 2, cz), Vector3.new(P.X2 - P.X1, P.Thick - 4, P.Z2 - P.Z1), ROCK)
			terrain:FillBlock(CFrame.new(cx, P.Top - 2, cz), Vector3.new(P.X2 - P.X1, 4, P.Z2 - P.Z1), Enum.Material.Grass)
			local lo = FLOOR - 13
			local function solid(x1, z1, x2, z2)
				terrain:FillBlock(CFrame.new((x1 + x2) / 2, (lo + under) / 2, (z1 + z2) / 2), Vector3.new(x2 - x1, under - lo, z2 - z1), ROCK)
			end
			solid(P.X1, P.Z1, -152, P.Z2)
			solid(-80, P.Z1, P.X2, P.Z2) -- the east cliff, closing the chapel's side from the keep
			solid(-92, 88, P.X2, P.Z1) -- and its corner
			solid(P.X1, P.Z2 - 8, P.X2, P.Z2)
			-- the ramp: rock below, a trodden skin on top, ending flush with the mesa and running a little
			-- out past its foot, into the basin floor
			local A, B = Rp.A, Rp.B
			local len = (B - A).Magnitude
			local cf0 = CFrame.lookAt((A + B) / 2 - (B - A).Unit * 2, B)
			terrain:FillBlock(cf0 * CFrame.new(0, -7, 0), Vector3.new(Rp.W, 14, len + 4), ROCK)
			terrain:FillBlock(cf0 * CFrame.new(0, -1, 0), Vector3.new(Rp.W, 2, len + 4), Enum.Material.Ground)
			for s = 0, len, 7 do -- banks of crag along both sides
				local p = A + (B - A) * (s / len)
				for _, side in ipairs({ -1, 1 }) do
					local rr = hr:NextNumber(5, 8)
					terrain:FillBall(Vector3.new(p.X + side * (Rp.W / 2 + rr * 0.9), p.Y + rr * 0.2 + 1, p.Z), rr, hr:NextNumber() < 0.6 and ROCK or BASALT)
				end
			end
			-- the rim of crags round the mesa (not across the ramp's mouth, nor over the chapel's side)
			local mouth = { Rp.A.X - Rp.W / 2 - 4, Rp.A.X + Rp.W / 2 + 4 }
			local function rim(x1, z1, x2, z2, alongX)
				local n = math.max(math.floor(math.max(math.abs(x2 - x1), math.abs(z2 - z1)) / 8), 1)
				for k = 0, n do
					local x, z = x1 + (x2 - x1) * k / n, z1 + (z2 - z1) * k / n
					if not (z > P.Z2 - 24 and x > mouth[1] - 8 and x < mouth[2] + 8) then -- (the ramp's lane stays clear of crags)
						local rr = hr:NextNumber(5, 8)
						terrain:FillBall(Vector3.new(x, P.Top + rr * 0.35, z), rr, hr:NextNumber() < 0.6 and BASALT or ROCK)
					end
				end
			end
			rim(P.X1 + 3, P.Z1 + 3, P.X1 + 3, P.Z2 - 3)
			rim(-100, P.Z1 + 3, P.X2 - 3, P.Z1 + 3)
			rim(P.X2 - 3, P.Z1 + 3, P.X2 - 3, P.Z2 - 3)
			rim(P.X1 + 3, P.Z2 - 3, P.X2 - 3, P.Z2 - 3, true)
			-- three pillars of rock at the corners (the fourth is the ramp's), each capped by a giant
			-- mushroom: red, brown, red
			local PROFILE = { 0.96, 1.0, 0.94, 0.84, 0.68, 0.46, 0.2 }
			local UP = CFrame.Angles(0, 0, math.pi / 2)
			local function pillar(x, z, color)
				local top = P.Top + 38
				terrain:FillCylinder(CFrame.new(x, P.Top + 19, z), 38, 8, ROCK)
				for k = 1, 4 do
					terrain:FillBall(Vector3.new(x + hr:NextNumber(-2, 2), P.Top + k * 9, z + hr:NextNumber(-2, 2)), 8.5 + hr:NextNumber(0, 1.5), k % 2 == 0 and BASALT or ROCK)
				end
				part({ Name = "PillarStem", Shape = Enum.PartType.Cylinder, Size = Vector3.new(9, 17, 17), CFrame = CFrame.new(x, top + 4, z) * UP, Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(176, 168, 148), CanCollide = false })
				local base, rad, lt = CFrame.new(x, top + 8, z), 22, 1.5
				local function disc(name, y, r, h, c, mat)
					part({ Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, r * 2, r * 2), CFrame = base * CFrame.new(0, y, 0) * UP, Material = mat, Color = c, CanCollide = false })
				end
				disc("PillarGills", lt * 0.3, rad * 0.9, lt * 0.6, Color3.fromRGB(196, 186, 160), Enum.Material.Fabric)
				for i, f in ipairs(PROFILE) do
					disc("PillarCap", lt * (i - 0.5) + lt * 0.3, rad * f, lt + 0.05, color:Lerp(Color3.fromRGB(20, 14, 24), (1 - f) * 0.25), Enum.Material.Fabric)
				end
				for _ = 1, 7 do
					local j = hr:NextInteger(3, #PROFILE - 1)
					local a, r, sz = hr:NextNumber(0, 6.3), rad * (PROFILE[j] + PROFILE[j + 1]) / 2, rad * hr:NextNumber(0.08, 0.14)
					part({ Name = "PillarSpot", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, sz, sz), CFrame = base * CFrame.new(math.cos(a) * r, lt * j + lt * 0.3, math.sin(a) * r) * UP, Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(226, 218, 200), CanCollide = false })
				end
			end
			local RED, BROWN = Color3.fromRGB(150, 36, 34), Color3.fromRGB(112, 76, 44)
			pillar(P.X1 + 4, P.Z1 + 4, RED) -- (out past the walls, among the crags)
			pillar(P.X2 - 4, P.Z1 + 4, BROWN)
			pillar(P.X2 - 4, P.Z2 - 4, RED)
			-- low mounds and stones on the grass, well clear of the hole and the ramp's mouth
			for _ = 1, 36 do
				local x, z = hr:NextNumber(P.X1 + 14, P.X2 - 14), hr:NextNumber(P.Z1 + 14, P.Z2 - 14)
				local rr = hr:NextNumber(3, 6)
				local nearHole = (x - (Hh.X1 + Hh.X2) / 2) ^ 2 + (z - (Hh.Z1 + Hh.Z2) / 2) ^ 2 < 22 ^ 2
				local nearMouth = z > P.Z2 - 30 and x > mouth[1] - 6 and x < mouth[2] + 6
				if not nearHole and not nearMouth then
					local pick = hr:NextNumber()
					terrain:FillBall(Vector3.new(x, P.Top - rr + hr:NextNumber(0.2, 0.9), z), rr, pick < 0.5 and Enum.Material.LeafyGrass or pick < 0.8 and Enum.Material.Ground or ROCK)
				end
			end
			-- the hole, last: straight through the mesa (whole voxels, wider than the roof's opening, which
			-- the lining closes back down to)
			terrain:FillBlock(CFrame.new((Hh.X1 + Hh.X2) / 2 - 1, under + 8, (Hh.Z1 + Hh.Z2) / 2), Vector3.new(16, 16, 16), Enum.Material.Air)
			-- the Usher's walk tunnels through the east cliff to the chapel's door (whole voxels)
			terrain:FillBlock(CFrame.new(-76, 6, 160), Vector3.new(8, 20, 16), Enum.Material.Air)
			-- THE CITADEL's ground, past the town's gate: solid to the bedrock, grassed, its cliffs
			-- roughened with crags (the walls, houses and the mansion are the township section's)
			local Ct = H.Citadel
			local cw, cd = Ct.X2 - Ct.X1, Ct.Z2 - Ct.Z1
			terrain:FillBlock(CFrame.new((Ct.X1 + Ct.X2) / 2, (lo + P.Top - 4) / 2, (Ct.Z1 + Ct.Z2) / 2), Vector3.new(cw, P.Top - 4 - lo, cd), ROCK)
			terrain:FillBlock(CFrame.new((Ct.X1 + Ct.X2) / 2, P.Top - 2, (Ct.Z1 + Ct.Z2) / 2), Vector3.new(cw, 4, cd), Enum.Material.Grass)
			local function crags(x1, z1, x2, z2, ox, oz, rmax) -- along a cliff, o = outward
				local n = math.max(math.floor(math.max(math.abs(x2 - x1), math.abs(z2 - z1)) / 9), 1)
				for k = 0, n do
					local x, z = x1 + (x2 - x1) * k / n, z1 + (z2 - z1) * k / n
					for _ = 1, 3 do
						local rr = hr:NextNumber(7, rmax or 13)
						terrain:FillBall(Vector3.new(x + ox * rr * 0.5, hr:NextNumber(-14, P.Top - 14), z + oz * rr * 0.5), rr, hr:NextNumber() < 0.5 and ROCK or BASALT)
					end
				end
			end
			crags(Ct.X1, Ct.Z1, Ct.X1, Ct.Z2, -1, 0)
			crags(Ct.X1, Ct.Z1, Ct.X2, Ct.Z1, 0, -1)
			crags(Ct.X2, Ct.Z1, Ct.X2, Ct.Z2, 1, 0)
			crags(P.X2 - 8, P.Z1, P.X2 - 8, P.Z2, 1, 0, 9)
			crags(P.X1, P.Z1, P.X1, P.Z2, -1, 0)
			for _ = 1, 70 do -- low mounds on the grass
				local rr = hr:NextNumber(3, 6)
				local pick = hr:NextNumber()
				terrain:FillBall(Vector3.new(hr:NextNumber(Ct.X1 + 12, Ct.X2 - 12), P.Top - rr + hr:NextNumber(0.2, 0.9), hr:NextNumber(Ct.Z1 + 12, Ct.Z2 - 12)), rr, pick < 0.5 and Enum.Material.LeafyGrass or pick < 0.8 and Enum.Material.Ground or ROCK)
			end
			-- and the Usher's walk through the east cliff, cut once more now that every crag is down: the whole
			-- walk from the chapel's door to the yard (x -86..-56) is clear to the sky-side of its wall
			terrain:FillBlock(CFrame.new(-71, 6, 160), Vector3.new(30, 20, 16), Enum.Material.Air)
			-- and the Hollow Mansion's footprint, hall and vestibule: none of the plateau's grass mounds poking up through its floors
			terrain:FillBlock(CFrame.new(-216, P.Top + 6, -68), Vector3.new(112, 12, 168), Enum.Material.Air) -- (whole voxels: a part-cut one leaves a skin)
			-- and down to a whole voxel under the hall's floor, inside its walls and the vestibule: the grass' top voxel was
			-- only part-cut above, and left a skin of grass standing over the ground floor
			local gy = math.floor((P.Top - 4) / 4) * 4
			terrain:FillBlock(CFrame.new(-216, (gy + P.Top + 12) / 2, -80), Vector3.new(104, P.Top + 12 - gy, 136), Enum.Material.Air) -- x -268..-164, z -148..-12
			terrain:FillBlock(CFrame.new(-214, (gy + P.Top + 12) / 2, -4), Vector3.new(36, P.Top + 12 - gy, 16), Enum.Material.Air) -- x -232..-196, z -12..4
			terrain:FillBlock(CFrame.new(-216, P.Top + 20, 40), Vector3.new(48, 40, 64), Enum.Material.Air) -- and the great door's approach
		end
		-- THE FAR RANGE: plain grey mountains, snow on top, round the whole map and outside everything in it. A height field
		-- (ridged noise), written only as a shell over each column: nothing inside INNER is touched but void outside the
		-- bedrock, which gets a floor at the bedrock's level. Materials none of the map's terrain uses, so their colours are free.
		-- (FX, FZ, INNER: the furthest of the map is the Pyralis peaks' north-east corner, ~807 out; the Decayed walls ~789.)
		do
			terrain:SetMaterialColor(Enum.Material.Limestone, Color3.fromRGB(124, 126, 130))
			terrain:SetMaterialColor(Enum.Material.Sandstone, Color3.fromRGB(114, 116, 120))
			terrain:SetMaterialColor(Enum.Material.Snow, Color3.fromRGB(232, 234, 240))
			local FX, FZ, INNER, OUTER, CHUNK = 175, 225, 830, 1900, 128
			local function smooth(t)
				t = math.clamp(t, 0, 1)
				return t * t * (3 - 2 * t)
			end
			-- terrain can't opt out of shadows, and the sun's low (ClockTime 6.9): measured in play, a block 680 from the camera
			-- casts none on it, but the ring's slopes nearer than that put the whole east of the map in the dark. So on the sun's
			-- side the peaks start past that reach of anywhere you can stand (~720 from FX, FZ), with low hills up to them.
			local SUN_REACH = 1400 - INNER
			local SUN_X, SUN_Z = 0.947, 0.321 -- (Lighting:GetSunDirection() at 6.9, flat)
			-- THE FOOTHILLS: medium mountains filling the moat between the map's own mountains and the far ring, their peaks climbing
			-- outward until they're nearly the ring's height. They start just past the map's edge on each bearing:
			-- shortcut: KEEP was measured from the built map (the outermost terrain or part in each 15 degree slice from 7.5), so re-measure it if the map grows outward.
			local KEEP = { 684, 713, 732, 655, 588, 602, 660, 708, 699, 652, 652, 684, 684, 758, 690, 724, 588, 590, 593, 568, 543, 579, 693, 698 }
			local keep = {}
			for i = 1, 24 do -- (the largest of it and its neighbours, plus a margin: interpolating between slices never cuts into the map)
				keep[i] = math.max(KEEP[i], KEEP[i % 24 + 1], KEEP[(i - 2) % 24 + 1]) + 20
			end
			local SUN_SLOPE, STAND = 0.2, 760 -- (the low sun's fall per stud, a little under its true 0.227; how far out from FX, FZ anything's stood on)
			local function foothill(x, z, dx, dz, r, shift)
				local b = ((math.deg(math.atan2(dz, dx)) - 7.5) % 360) / 15
				local i = math.floor(b)
				local from = keep[i + 1] + (keep[(i + 1) % 24 + 1] - keep[i + 1]) * (b - i)
				if r <= from then
					return nil
				end
				local f, amp, sum, weight = 1 / 330, 1, 0, 1
				for o = 1, 5 do
					local n = math.max(0, 1 - 2 * math.abs(math.noise(x * f + 41.7, z * f + 23.9, o * 6.1)))
					local signal = n * n * weight
					sum += signal * amp
					weight = math.clamp(signal * 2, 0, 1)
					f, amp = f * 2, amp * 0.5
				end
				local peak = (170 + 600 * math.clamp((r - from) / (INNER + shift + 490 - from), 0, 1)) * smooth((r - from) / 70) * smooth((INNER + shift + 890 - r) / 300)
				-- on the sun's side nothing may shadow the map's floors: under a line a little below the sun's rays through the map's middle (its outer flanks can shade), until
				-- it's past the reach of the shadow pass (see SUN_REACH), and then free to climb
				local along, across = dx * SUN_X + dz * SUN_Z, math.abs(dz * SUN_X - dx * SUN_Z)
				if along > 0 and across < STAND then
					local past = along - math.sqrt(STAND * STAND - across * across)
					peak = math.min(peak, along * SUN_SLOPE + smooth((past - 660) / 150) * peak + smooth((across - 620) / 140) * peak)
				end
				return FLOOR + peak * (0.4 + 0.25 * math.noise(x / 150 + 9.2, z / 150 + 4.4, 1.5) + 0.6 * (sum / 1.94) ^ 1.4) -- (0.4: the valleys between ridges climb too, or the moat's still there; 1.94: the most sum can be, so only the ridge lines come near the peak height and nothing's flat-topped)
			end
			local function farHeight(x, z) -- (nil: leave this column alone)
				local dx, dz = x - FX, z - FZ
				local r = math.sqrt(dx * dx + dz * dz)
				local sunward = smooth((dx * SUN_X + dz * SUN_Z) / 200) * smooth((920 - math.abs(dz * SUN_X - dx * SUN_Z)) / 200)
				local shift = SUN_REACH * sunward
				local outer = OUTER + shift
				if r >= outer then
					return nil
				end
				local hill = foothill(x, z, dx, dz, r, shift)
				if r < INNER then
					local onBedrock = x > centre.X - span / 2 and x < centre.X + span / 2 and z > centre.Z - span / 2 and z < centre.Z + span / 2
					return hill or (not onBedrock and FLOOR or nil)
				end
				local t = (r - INNER - shift) / (OUTER - INNER)
				local env = smooth(t / 0.45) * smooth((1 - t) / 0.3)
				local f, amp, sum, weight = 1 / 700, 1, 0, 1
				for o = 1, 6 do
					local n = math.max(0, 1 - 2 * math.abs(math.noise(x * f + 17.3, z * f - 5.1, o * 9.7)))
					local signal = n * n * weight
					sum += signal * amp
					weight = math.clamp(signal * 2, 0, 1)
					f, amp = f * 2, amp * 0.5
				end
				local mass = 0.55 + 0.45 * math.noise(x / 1100 + 3.1, z / 1100 + 8.7, 0.5)
				local hills = 0.11 * math.min(r - INNER, SUN_REACH) * sunward * sum * smooth((outer - r) / 300)
				return math.max(hill or FLOOR, FLOOR + hills + env * (140 + mass * sum * (620 + 380 * sunward))) -- (taller where they stand further off)
			end
			local function farMaterial(x, z, h, slope)
				if h > 400 + 90 * math.noise(x / 240 + 0.3, z / 240 + 0.7, 2.5) and slope < 2.5 then
					return Enum.Material.Snow
				elseif h < 90 and slope < 0.8 then
					return Enum.Material.Grass
				end
				return math.noise(x / 300 + 0.1, h / 30 + 0.2, z / 300 + 0.4) > 0 and Enum.Material.Limestone or Enum.Material.Sandstone -- (strata)
			end
			task.spawn(function() -- (well outside the map, so nothing waits on it)
				local far = OUTER + SUN_REACH
				local x1, z1 = math.floor((FX - far) / CHUNK) * CHUNK, math.floor((FZ - far) / CHUNK) * CHUNK
				local n = CHUNK / 4
				for x0 = x1, FX + far, CHUNK do
					for z0 = z1, FZ + far, CHUNK do
						local hs, lo, hi = {}, math.huge, -math.huge
						for i = 0, n + 1 do -- (a column's neighbours too: the shell goes down to the lowest of them)
							hs[i] = {}
							for k = 0, n + 1 do
								hs[i][k] = farHeight(x0 + 4 * i - 2, z0 + 4 * k - 2)
							end
						end
						local function drop(i, k) -- (the shell's bottom, and how far the steepest side falls)
							local h = hs[i][k]
							local low = math.min(h, hs[i - 1][k] or h, hs[i + 1][k] or h, hs[i][k - 1] or h, hs[i][k + 1] or h)
							return low - 8, h - low
						end
						for i = 1, n do
							for k = 1, n do
								if hs[i][k] then
									lo, hi = math.min(lo, (drop(i, k))), math.max(hi, hs[i][k])
								end
							end
						end
						if hi > -math.huge then
							local y0, y1 = math.floor(lo / 4) * 4, math.ceil(hi / 4) * 4 + 4
							local reg = Region3.new(Vector3.new(x0, y0, z0), Vector3.new(x0 + CHUNK, y1, z0 + CHUNK))
							local mats, occ = terrain:ReadVoxels(reg, 4) -- (read first: whatever's here already stays)
							for i = 1, n do
								for k = 1, n do
									local h = hs[i][k]
									if h then
										local bottom, fall = drop(i, k)
										local mat = h == FLOOR and Enum.Material.Slate or farMaterial(x0 + 4 * i - 2, z0 + 4 * k - 2, h, fall / 4)
										for j = 1, (y1 - y0) / 4 do
											local y = y0 + 4 * (j - 1)
											if y < h and y + 4 > bottom then
												mats[i][j][k], occ[i][j][k] = mat, math.clamp((h - y) / 4, 0, 1)
											end
										end
									end
								end
							end
							terrain:WriteVoxels(reg, 4, mats, occ)
							task.wait()
						end
					end
				end
			end)
		end
	end

	-----------------------------------------------------------------------
	-- 10. THE PRISON WING: the rest of the prison, over the cell block and the sewer. A walled block
	--     (x -56..92, z -44..105, floors at y 30, roof at y 44) closes the rampart's south curtain wall,
	--     the west outer wall and the sewer's rock in; an east block (x 56..92, z 105..181) runs north
	--     along the yard walk and ends against the township bastion's south face (x 60..196, z 181..221)
	--     and its corner tower (x 56..66, z 177..187), which it meets instead of cutting into. Its gate (a portcullis in the curtain wall, x 44..52) lifts when the
	--     Consul's spell breaks; the drawbridge from the citadel lands on its roof (west wall, z 79..91).
	--     THE ROOF is a castle's: walled courts and streets between pitched-roof masses, with a lit
	--     flagstone road winding from the bridge through them all to the wing over the yard walk,
	--     where a ladder hangs over the curtain wall to the walk beside the yard ladder's top.
	--     Its own random stream, so the map's doesn't shift.
	-----------------------------------------------------------------------
	do
		local FY, CY, RY = 30, 42, 44 -- floor top, ceiling underside, roof top
		local wr = Random.new(2606)
		local wing = Instance.new("Folder")
		wing.Name = "PrisonWing"
		wing.Parent = map
		local TRIM = Color3.fromRGB(94, 90, 84)
		local IRON = Color3.fromRGB(42, 38, 34)
		local VOIDC = Color3.fromRGB(8, 8, 10)
		local function sc()
			return COL.Wall:Lerp(COL.WallDark, wr:NextNumber() * 0.6)
		end
		local function B(x1, y1, z1, x2, y2, z2, name, color, mat)
			return box(x1, y1, z1, x2, y2, z2, mat or MAT.Cobblestone, color or sc(), name or "WingWall", wing)
		end

		-- the outer walls, down to the ground and up to the curtain wall's height
		B(-56, -8, -44, 92, RY, -40, "WingOuter") -- south
		B(-56, -8, -40, -52, RY, 28, "WingOuter") -- west (carries on the line of the west outer wall; z 28..42 is filled in section 11)
		B(-56, -8, 42, -52, RY, 105, "WingOuter")
		B(88, -8, -40, 92, RY, -39, "WingOuter") -- east (ending on the bastion's face; z -39..-25 is the blown-out hole, section 11)
		B(88, -8, -25, 92, RY, 181, "WingOuter")
		-- the east block's west side: it jogs out round the curtain wall's round tower (x 48.5..59.5, z 112.5..123.5),
		-- which stays whole outside it, and leaves the sewer's mouth (z 149.5..161.5, y 0..12) open
		-- (these stand on the sewer's ceiling - y 6 over the North Run, 11 over the ramp and outflow - not down through it)
		B(56, 6, 105, 58, RY, 108, "WingOuter")
		B(56, 6, 108, 61.5, RY, 110, "WingOuter")
		B(59.5, 11, 110, 61.5, RY, 126, "WingOuter")
		B(56, 11, 126, 61.5, RY, 128, "WingOuter")
		B(56, 11, 128, 58, RY, 149.5, "WingOuter")
		B(56, -8, 149.5, 58, 0, 161.5, "WingOuter")
		B(56, 12, 149.5, 58, RY, 161.5, "WingOuter")
		B(56, -8, 161.5, 58, RY, 181, "WingOuter")
		-- the north side: a back wall and a fill against the curtain wall (the old cells stay in their
		-- openings), with the gate's doorway (x 44..52) and the east block's (x 70..78) left open
		for _, s in ipairs({ { -56, 44 }, { 52, 70 }, { 78, 92 } }) do
			B(s[1], 18, 97, s[2], RY, 99, "WingWall")
		end
		for _, s in ipairs({ { -56, -34 }, { -26, -4 }, { 4, 26 }, { 34, 44 }, { 52, 70 }, { 78, 92 } }) do
			B(s[1], 18, 99, s[2], RY, 105, "WingWall")
		end
		B(44, 41, 97, 52, RY, 105, "WingWall") -- over the gate
		B(70, 40, 97, 78, RY, 105, "WingWall") -- over the east block's door

		-- floors and roofs (the roof stair's hole left in the east block's)
		local function slab(x1, z1, x2, z2)
			B(x1, 28, z1, x2, FY, z2, "WingFloor", Color3.fromRGB(54, 52, 48), MAT.Slate)
		end
		slab(-56, -44, -44, 105) -- (the floor, with the stair's hole at x -44..-30, z 72..96: section 11)
		slab(-44, -44, -30, 72)
		slab(-44, 96, -30, 105)
		slab(-30, -44, 92, 105)
		slab(56, 105, 92, 181)
		local function roof(x1, z1, x2, z2)
			B(x1, CY, z1, x2, RY, z2, "WingRoof", COL.Ceiling, MAT.Slate)
		end
		roof(-52, -40, 88, 97)
		roof(58, 105, 80, 181)
		roof(86, 105, 88, 181)
		roof(80, 105, 86, 145)
		roof(80, 160.8, 86, 181)

		-- the inside: walls (2 thick) along the grid's lines, with doors 8 wide and 10 high. The doors are a tree:
		-- gate hall -> E -> S -> S -> W -> S -> W -> N -> N into the middle hall (and the east block's halls off the
		-- stair). Nothing in them yet but light and stone.
		local function wallAlong(axis, c, a, b, doors)
			table.sort(doors, function(p, q)
				return p[1] < q[1]
			end)
			local function seg(u1, u2, y1, y2)
				if u2 - u1 > 0.01 then
					if axis == "z" then
						B(c - 1, y1, u1, c + 1, y2, u2)
					else
						B(u1, y1, c - 1, u2, y2, c + 1)
					end
				end
			end
			local cur = a
			for _, d in ipairs(doors) do
				seg(cur, d[1], FY, CY)
				seg(d[1], d[2], FY + 10, CY)
				cur = d[2]
			end
			seg(cur, b, FY, CY)
		end
		wallAlong("z", -17, -40, 97, { { 4, 12 } })
		wallAlong("z", 18, -40, 97, { { -26, -18 }, { 78, 86 } })
		wallAlong("z", 53, -40, 97, { { 78, 86 }, { 4, 12 }, { 46, 54 } })
		wallAlong("x", -6, -52, 88, { { 24, 32 }, { -12, -4 }, { 66, 74 }, { -40, -32 } })
		wallAlong("x", 28, -52, 88, { { 9, 17 }, { 78, 86 }, { -40, -32 } })
		wallAlong("x", 68, -52, 88, { { 74, 82 }, { -40, -32 } })
		wallAlong("x", 134, 58, 88, { { 66, 74 } }) -- the east block's halls: E1 | E2 | E3 | E4
		wallAlong("x", 165, 58, 88, { { 66, 74 } })
		B(58, FY, 176, 88, CY, 181, "WingWall") -- (E3's end: the bastion's face is just beyond)

		-- rooms: pillars, a torch on each long wall, a little rubble. The stair's hall stays clear.
		local X = { -52, -17, 18, 53, 88 }
		local Z = { -40, -6, 28, 68, 97 }
		local rooms = {}
		for i = 1, 4 do
			for j = 1, 4 do
				table.insert(rooms, { X[i] + (i == 1 and 0 or 1), Z[j] + (j == 1 and 0 or 1), X[i + 1] - (i == 4 and 0 or 1), Z[j + 1] - (j == 4 and 0 or 1), i == 1 and j == 4 }) -- (the far west room has the stair down in it)
			end
		end
		-- its wardens: the prison's elite guard (Characters/Warder), one in the middle of most rooms of the grid (clear of the
		-- pillars at 30/70%), the last beside the stair's hole - all turned toward the far west room, the way down
		for _, g in ipairs({ { 4, 4 }, { 3, 4 }, { 2, 4 }, { 4, 3 }, { 3, 3 }, { 2, 3 }, { 1, 3 }, { 2, 2 }, { 1, 2 } }) do
			local x, z = (X[g[1]] + X[g[1] + 1]) / 2, (Z[g[2]] + Z[g[2] + 1]) / 2
			table.insert(info.EnemySpawns, { Type = "Warder", CFrame = CFrame.lookAt(Vector3.new(x, FY + 3.2, z), Vector3.new(-34, FY + 3.2, 82)) })
		end
		table.insert(info.EnemySpawns, { Type = "Warder", CFrame = CFrame.lookAt(Vector3.new(-24, FY + 3.2, 76), Vector3.new(-17, FY + 3.2, 82)) })
		table.insert(rooms, { 62, 105, 88, 133, false })
		table.insert(rooms, { 58, 135, 88, 163, true })
		table.insert(rooms, { 58, 166, 88, 175, false })
		for _, r in ipairs(rooms) do
			local xl, zl, xr, zr, bare = r[1], r[2], r[3], r[4], r[5]
			local w, d = xr - xl, zr - zl
			if not bare then
				for _, fx in ipairs({ 0.3, 0.7 }) do
					for _, fz in ipairs({ 0.3, 0.7 }) do
						local px, pz = xl + w * fx, zl + d * fz
						B(px - 1.5, FY, pz - 1.5, px + 1.5, CY, pz + 1.5, "WingPillar")
						B(px - 2, FY, pz - 2, px + 2, FY + 1, pz + 2, "WingPillar", TRIM, MAT.Slate)
					end
				end
			end
			for _ = 1, bare and 0 or 3 do
				local s = wr:NextNumber(0.8, 2)
				local px, pz = wr:NextNumber(xl + 3, xr - 3), wr:NextNumber(zl + 3, zr - 3)
				B(px - s / 2, FY, pz - s / 2, px + s / 2, FY + s * 0.6, pz + s / 2, "WingRubble")
			end
			torch(Vector3.new(xl + 0.1, 36, zl + 4), Vector3.new(1, 0, 0))
			torch(Vector3.new(xr - 0.1, 36, zr - 4), Vector3.new(-1, 0, 0))
		end

		-- the roof stair in the east block's second hall (x 80..86, z 137..161), up to the roof
		for i = 0, 13 do
			B(80, 28, 137 + 1.7 * i, 86, 31 + i, 137 + 1.7 * (i + 1), "WingStep", TRIM, MAT.Slate)
		end
		-- rails round the stair's hole on its south and sides: the roof's way down is from its north end
		B(79, RY, 144.5, 87, RY + 3, 145.5, "WingParapet")
		B(79, RY, 145.5, 80, RY + 3, 157, "WingParapet")
		B(86, RY, 145.5, 87, RY + 3, 157, "WingParapet")

		-- the gate: a portcullis in the curtain wall's doorway (x 44..52, over y 30..41), down until the spell breaks
		local gateBars = {}
		for x = 44.5, 51.6, 1 do
			table.insert(gateBars, B(x - 0.2, FY, 106.4, x + 0.2, 41, 107.2, "WingGateBar", IRON, MAT.Metal))
		end
		for _, y in ipairs({ 33, 37, 40.4 }) do
			table.insert(gateBars, B(44, y, 106.5, 52, y + 0.6, 107.1, "WingGateRail", IRON, MAT.Metal))
		end
		local gateBlock = part({ Name = "WingGateBlock", Size = Vector3.new(8, 11, 1), CFrame = CFrame.new(48, FY + 5.5, 106.8), Transparency = 1, CanQuery = false, Parent = wing })
		local gateSpot = part({ Name = "WingGateSpot", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(48, FY + 3, 109.5), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = wing })
		info.PrisonGate = { Bars = gateBars, Blocker = gateBlock }
		info.PrisonGatePrompt = prompt(gateSpot, "Inspect", "Portcullis", 0, 8)

		-- the outside: string courses, buttresses and arrow slits on each face
		local function facade(axis, c, a, b, dir, gap) -- c: the wall's outer face, dir: which way is out; gap: { u1, u2 } kept clear above the roof
			local function clear(u1, u2)
				return not gap or u2 <= gap[1] or u1 >= gap[2]
			end
			local function put(u1, u2, y1, y2, d1, d2, name, color, mat)
				local lo, hi = math.min(c + dir * d1, c + dir * d2), math.max(c + dir * d1, c + dir * d2)
				if axis == "x" then
					return B(u1, y1, lo, u2, y2, hi, name, color, mat)
				end
				return B(lo, y1, u1, hi, y2, u2, name, color, mat)
			end
			put(a, b, 29.2, 30.6, 0, 1.2, "WingCourse", TRIM, MAT.Slate)
			put(a, b, 41, 42.6, 0, 1.2, "WingCourse", TRIM, MAT.Slate)
			for _, r in ipairs(gap and { { a, gap[1] }, { gap[2], b } } or { { a, b } }) do
				put(r[1], r[2], 55, 56.6, 0, 1.2, "WingCourse", TRIM, MAT.Slate)
			end
			for u = a + 8, b - 8, 16 do
				if clear(u - 1.5, u + 1.5) then
					put(u - 1.5, u + 1.5, -8, 55, 0, 2.2, "WingButtress")
				else
					wr:NextNumber() -- (its colour's draw, so the wing's stream stays where it was)
				end
			end
			for u = a + 16, b - 8, 16 do
				put(u - 0.35, u + 0.35, 33, 38, 0, 0.15, "ArrowSlit", VOIDC, MAT.Slate)
				if clear(u - 0.35, u + 0.35) then
					put(u - 0.35, u + 0.35, 47, 52, 0, 0.15, "ArrowSlit", VOIDC, MAT.Slate)
				end
			end
		end
		facade("x", -44, -56, 92, -1)
		facade("z", -56, -44, 105, -1, { 79, 91 }) -- (the gap: where the drawbridge comes down onto the roof)
		facade("z", 92, -44, 181, 1)

		-------------------------------------------------------------------
		-- THE ROOF. Perimeter walls 12 high with merlons (nobody looks or walks off); inside, the grid's lines
		-- are 9-high walls with gates, the unused cells are pitched-roof masses, and the used ones courts joined by a
		-- lit flagstone road: bridge -> west ward -> gallows yard -> cistern court -> armoury -> guard court ->
		-- parade ground -> gate court -> bell yard -> stair-well court -> ladder terrace.
		-------------------------------------------------------------------
		local Y0 = RY
		local function R(x1, z1, x2, z2, h, name, color, mat)
			return B(x1, Y0, z1, x2, Y0 + h, z2, name, color, mat)
		end
		-- perimeter, 12 high, the bridge's gap (z 79..91) and the ladder's (z 177..181) left open
		R(-56, -44, 92, -40, 12, "RoofWall")
		R(-56, -40, -52, 79, 12, "RoofWall")
		R(-56, 91, -52, 109, 12, "RoofWall")
		R(-56, 105, 56, 109, 12, "RoofWall")
		R(88, -40, 92, 181, 12, "RoofWall")
		R(56, 97, 58, 108, 12, "RoofWall")
		R(56, 108, 61.5, 110, 12, "RoofWall") -- (the bay round the round tower)
		R(59.5, 110, 61.5, 126, 12, "RoofWall")
		R(56, 126, 61.5, 128, 12, "RoofWall")
		R(56, 128, 58, 171, 12, "RoofWall")
		R(56, 175, 58, 181, 12, "RoofWall") -- (the gap, z 171..175, is the ladder's)
		-- (the merlons stand on the walls' tops: y 56..58.5)
		local function crown(axis, c, a, b, skipA, skipB)
			for u = a, b - 2, 4 do
				if not (skipA and u + 2 > skipA and u < skipB) then
					if axis == "x" then
						B(u, Y0 + 12, c - 1, u + 2, Y0 + 14.5, c + 1, "WingMerlon")
					else
						B(c - 1, Y0 + 12, u, c + 1, Y0 + 14.5, u + 2, "WingMerlon")
					end
				end
			end
		end
		crown("x", -42, -56, 92)
		crown("z", -54, -40, 105, 79, 91)
		crown("x", 107, -56, 56)
		crown("z", 90, -40, 181)
		crown("z", 57, 97, 108)
		crown("z", 60.5, 110, 126)
		crown("z", 57, 128, 171)
		crown("z", 57, 175, 181)
		-- corner towers (solid), taller than the wall
		local function tower(x1, z1, h)
			B(x1, Y0, z1, x1 + 10, Y0 + h, z1 + 10, "WingTower")
			B(x1 - 0.8, Y0 + h - 2.4, z1 - 0.8, x1 + 10.8, Y0 + h - 1.4, z1 + 10.8, "WingCourse", TRIM, MAT.Slate)
			for u = 0, 8, 4 do
				B(x1 + u, Y0 + h, z1 - 0.5, x1 + u + 2, Y0 + h + 2.5, z1 + 1.5, "WingMerlon")
				B(x1 + u, Y0 + h, z1 + 8.5, x1 + u + 2, Y0 + h + 2.5, z1 + 10.5, "WingMerlon")
				B(x1 - 0.5, Y0 + h, z1 + u, x1 + 1.5, Y0 + h + 2.5, z1 + u + 2, "WingMerlon")
				B(x1 + 8.5, Y0 + h, z1 + u, x1 + 10.5, Y0 + h + 2.5, z1 + u + 2, "WingMerlon")
			end
		end
		tower(-56, -44, 24)
		tower(82, -44, 24)
		tower(-56, 99, 22)

		-- the rooftop's props ------------------------------------------------
		local WOOD, DARKWOOD = Color3.fromRGB(78, 58, 40), Color3.fromRGB(52, 40, 30)
		local function crate(x, z, s)
			s = s or wr:NextNumber(2, 3)
			B(x - s / 2, Y0, z - s / 2, x + s / 2, Y0 + s, z + s / 2, "WingCrate", WOOD:Lerp(DARKWOOD, wr:NextNumber()), MAT.WoodPlanks)
		end
		local function barrel(x, z)
			part({ Name = "WingBarrel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.6, 2, 2), CFrame = CFrame.new(x, Y0 + 1.3, z) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Wood, Color = WOOD, Parent = wing })
			part({ Name = "WingBarrelBand", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 2.1, 2.1), CFrame = CFrame.new(x, Y0 + 0.5, z) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Metal, Color = IRON, CanCollide = false, Parent = wing })
			part({ Name = "WingBarrelBand", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 2.1, 2.1), CFrame = CFrame.new(x, Y0 + 2.1, z) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Metal, Color = IRON, CanCollide = false, Parent = wing })
		end
		local function cage(x, z) -- an iron gibbet on a stone plinth
			B(x - 2, Y0, z - 2, x + 2, Y0 + 1, z + 2, "WingPlinth", TRIM, MAT.Slate)
			for _, dx in ipairs({ -1.6, 1.6 }) do
				for _, dz in ipairs({ -1.6, 1.6 }) do
					B(x + dx - 0.15, Y0 + 1, z + dz - 0.15, x + dx + 0.15, Y0 + 5.2, z + dz + 0.15, "WingCage", IRON, MAT.Metal)
				end
			end
			for _, y in ipairs({ 1.1, 5 }) do
				B(x - 1.8, Y0 + y, z - 1.8, x + 1.8, Y0 + y + 0.2, z + 1.8, "WingCage", IRON, MAT.Metal).CanCollide = false
			end
			for k = -1, 1 do
				for _, s in ipairs({ -1.6, 1.6 }) do
					B(x + k - 0.06, Y0 + 1.2, z + s - 0.06, x + k + 0.06, Y0 + 5, z + s + 0.06, "WingCage", IRON, MAT.Metal).CanCollide = false
					B(x + s - 0.06, Y0 + 1.2, z + k - 0.06, x + s + 0.06, Y0 + 5, z + k + 0.06, "WingCage", IRON, MAT.Metal).CanCollide = false
				end
			end
		end
		local function gallows(x, z) -- a platform, a post, a beam and a noose
			B(x - 5, Y0, z - 4, x + 5, Y0 + 2.5, z + 4, "WingGallows", WOOD, MAT.WoodPlanks)
			B(x + 5, Y0, z - 1.5, x + 7, Y0 + 1.2, z + 1.5, "WingGallows", WOOD, MAT.WoodPlanks)
			B(x - 4.4, Y0 + 2.5, z - 0.4, x - 3.6, Y0 + 12, z + 0.4, "WingGallows", DARKWOOD, MAT.Wood)
			B(x - 4.4, Y0 + 11.2, z - 0.4, x + 1.5, Y0 + 12, z + 0.4, "WingGallows", DARKWOOD, MAT.Wood)
			part({ Name = "WingNoose", Size = Vector3.new(0.15, 4, 0.15), CFrame = CFrame.new(x + 1, Y0 + 9.2, z), Material = MAT.Fabric, Color = COL.Straw, CanCollide = false, Parent = wing })
		end
		local function stocks(x, z)
			for _, s in ipairs({ -1.6, 1.6 }) do
				B(x + s - 0.25, Y0, z - 0.3, x + s + 0.25, Y0 + 3.4, z + 0.3, "WingStocks", DARKWOOD, MAT.Wood)
			end
			B(x - 1.9, Y0 + 1.8, z - 0.2, x + 1.9, Y0 + 2.2, z + 0.2, "WingStocks", WOOD, MAT.WoodPlanks)
			B(x - 1.9, Y0 + 2.8, z - 0.2, x + 1.9, Y0 + 3.2, z + 0.2, "WingStocks", WOOD, MAT.WoodPlanks)
		end
		local function rack(x, z, alongX) -- weapon rack: a frame and leaning spears
			local function bx(a1, y1, c1, a2, y2, c2, name, col, m)
				if alongX then
					return B(x + a1, Y0 + y1, z + c1, x + a2, Y0 + y2, z + c2, name, col, m)
				end
				return B(x + c1, Y0 + y1, z + a1, x + c2, Y0 + y2, z + a2, name, col, m)
			end
			bx(-3, 0, -0.4, -2.6, 4, 0.4, "WingRack", DARKWOOD, MAT.Wood)
			bx(2.6, 0, -0.4, 3, 4, 0.4, "WingRack", DARKWOOD, MAT.Wood)
			bx(-3, 3.2, -0.4, 3, 3.6, 0.4, "WingRack", DARKWOOD, MAT.Wood)
			bx(-3, 1.2, -0.4, 3, 1.5, 0.4, "WingRack", DARKWOOD, MAT.Wood)
			for k = -2, 2 do
				bx(k * 1.1 - 0.06, 0.5, -0.1, k * 1.1 + 0.06, 6.2, 0.1, "WingSpear", IRON, MAT.Metal).CanCollide = false
			end
		end
		local BANNER_COLS = { Color3.fromRGB(104, 26, 26), Color3.fromRGB(30, 32, 40) }
		local bannerN = 0
		local function banner(x, z, onZ) -- hung on a wall face: onZ = the wall runs along z (the banner faces ±x)
			bannerN += 1
			local col = BANNER_COLS[bannerN % 2 + 1]
			local sx, sz = 0.15, 2.2
			if not onZ then
				sx, sz = 2.2, 0.15
			end
			B(x - sx / 2, Y0 + 2.5, z - sz / 2, x + sx / 2, Y0 + 7.5, z + sz / 2, "WingBanner", col, MAT.Fabric).CanCollide = false
			B(x - sx / 2 - (onZ and 0.05 or 0.3), Y0 + 7.5, z - sz / 2 - (onZ and 0.3 or 0.05), x + sx / 2 + (onZ and 0.05 or 0.3), Y0 + 7.8, z + sz / 2 + (onZ and 0.3 or 0.05), "WingBannerRod", IRON, MAT.Metal).CanCollide = false
		end
		local function arcade(x1, z1, x2, z2) -- a row of pillars under a beam, along x or z
			local alongX = math.abs(x2 - x1) > math.abs(z2 - z1)
			local n = math.max(1, math.floor((alongX and (x2 - x1) or (z2 - z1)) / 8))
			for i = 0, n do
				local x, z = x1 + (x2 - x1) * i / n, z1 + (z2 - z1) * i / n
				B(x - 1, Y0, z - 1, x + 1, Y0 + 9, z + 1, "WingColumn", TRIM, MAT.Slate)
				B(x - 1.5, Y0, z - 1.5, x + 1.5, Y0 + 1, z + 1.5, "WingColumn", TRIM, MAT.Slate)
				B(x - 1.5, Y0 + 8, z - 1.5, x + 1.5, Y0 + 9, z + 1.5, "WingColumn", TRIM, MAT.Slate)
			end
			if alongX then
				B(x1 - 1.5, Y0 + 9, z1 - 1, x2 + 1.5, Y0 + 10.4, z1 + 1, "WingBeam", TRIM, MAT.Slate)
			else
				B(x1 - 1, Y0 + 9, z1 - 1.5, x1 + 1, Y0 + 10.4, z2 + 1.5, "WingBeam", TRIM, MAT.Slate)
			end
		end
		-- a pitched roof (slabs) over a rectangle whose walls top out at y, its ridge along the longer side. The eaves
		-- overhang the walls by ov and sit a little above their tops, so the roof's edges and corners never meet the walls'
		-- (or their courses') faces; the gable ends are stepped fills inside the walls' own footprint.
		local function gable(x1, z1, x2, z2, y, color, ov)
			ov = ov or 1.4
			local lift = 0.5
			local w, d = x2 - x1, z2 - z1
			local alongZ = d >= w
			local half = (alongZ and w or d) / 2
			local rise = half * 0.55
			local th = math.atan2(rise, half)
			local cs = math.cos(th)
			local len = (half + ov + 0.35) / cs
			local ridgeLen = (alongZ and d or w) + 2 * ov
			local xm, zm = (x1 + x2) / 2, (z1 + z2) / 2
			color = color or Color3.fromRGB(46, 48, 52)
			for _, s in ipairs({ -1, 1 }) do
				local rel = s * (half + ov - 0.35) / 2 -- the slab's centre along the slope's run, from the ridge
				local cy = y + lift + rise * (1 - math.abs(rel) / half) + 0.5 / cs
				local cx = alongZ and xm + rel or xm
				local cz = alongZ and zm or zm + rel
				local size = alongZ and Vector3.new(len, 1, ridgeLen) or Vector3.new(ridgeLen, 1, len)
				local rot = alongZ and CFrame.Angles(0, 0, -s * th) or CFrame.Angles(s * th, 0, 0)
				part({ Name = "WingSlate", Size = size, CFrame = CFrame.new(cx, cy, cz) * rot, Material = MAT.Slate, Color = color, Parent = wing })
			end
			for k = 0, 3 do -- the gable ends, stepped, up to the underside of the slabs
				local bw = (alongZ and w or d) * (1 - k / 4 - 0.12)
				local y1, y2 = y + (k == 0 and 0 or lift + rise * k / 4), y + lift + rise * (k + 1) / 4
				if alongZ then
					B(xm - bw / 2, y1, z1, xm + bw / 2, y2, z1 + 1, "WingGable")
					B(xm - bw / 2, y1, z2 - 1, xm + bw / 2, y2, z2, "WingGable")
				else
					B(x1, y1, zm - bw / 2, x1 + 1, y2, zm + bw / 2, "WingGable")
					B(x2 - 1, y1, zm - bw / 2, x2, y2, zm + bw / 2, "WingGable")
				end
			end
			-- a ridge cap and a chimney (inside the footprint)
			if alongZ then
				B(xm - 0.5, y + lift + rise + 0.45, z1 - ov, xm + 0.5, y + lift + rise + 1.2, z2 + ov, "WingRidge", TRIM, MAT.Slate)
				B(xm + half * 0.3, y, z1 + d * 0.3, xm + half * 0.3 + 2, y + lift + rise + 4, z1 + d * 0.3 + 2, "WingChimney")
			else
				B(x1 - ov, y + lift + rise + 0.45, zm - 0.5, x2 + ov, y + lift + rise + 1.2, zm + 0.5, "WingRidge", TRIM, MAT.Slate)
				B(x1 + w * 0.3, y, zm + half * 0.3, x1 + w * 0.3 + 2, y + lift + rise + 4, zm + half * 0.3 + 2, "WingChimney")
			end
		end
		local function hut(x1, z1, x2, z2, h, barred) -- a solid little building with a pitched roof, barred windows if a cell-house
			B(x1, Y0, z1, x2, Y0 + h, z2, "WingHut")
			B(x1 - 0.4, Y0 + h - 1.2, z1 - 0.4, x2 + 0.4, Y0 + h, z2 + 0.4, "WingCourse", TRIM, MAT.Slate)
			gable(x1, z1, x2, z2, Y0 + h)
			local xm, zm = (x1 + x2) / 2, (z1 + z2) / 2
			for _, face in ipairs({ { xm, z1, true }, { xm, z2, true }, { x1, zm, false }, { x2, zm, false } }) do
				local fx, fz, onX = face[1], face[2], face[3]
				local out = (onX and (fz == z1 and -1 or 1)) or (fx == x1 and -1 or 1)
				local function slabAt(w1, y1, w2, y2, name, col, m)
					if onX then
						return B(fx + w1, Y0 + y1, fz + (out > 0 and 0 or -0.15), fx + w2, Y0 + y2, fz + (out > 0 and 0.15 or 0), name, col, m)
					end
					return B(fx + (out > 0 and 0 or -0.15), Y0 + y1, fz + w1, fx + (out > 0 and 0.15 or 0), Y0 + y2, fz + w2, name, col, m)
				end
				slabAt(-1.2, 1, 1.2, 4.6, "WingWindow", VOIDC, MAT.Slate).CanCollide = false
				if barred then
					for k = -1, 1 do
						slabAt(k * 0.7 - 0.07, 1, k * 0.7 + 0.07, 4.6, "WingBar", IRON, MAT.Metal).CanCollide = false
					end
				end
			end
		end
		-- (a cell-filling mass: solid, with a pitched roof over it, wall-high so nobody climbs it)
		local function mass(x1, z1, x2, z2)
			B(x1, Y0, z1, x2, Y0 + 9, z2, "WingMass")
			gable(x1, z1, x2, z2, Y0 + 9, nil, 0.8) -- (the walls between cells are 2 thick: eaves of two neighbours must not meet)
		end
		local function keep(x1, z1, x2, z2, h) -- a solid tower block
			B(x1, Y0, z1, x2, Y0 + h, z2, "WingKeep")
			B(x1 - 0.7, Y0 + h - 2.4, z1 - 0.7, x2 + 0.7, Y0 + h - 1.4, z2 + 0.7, "WingCourse", TRIM, MAT.Slate)
			for u = x1, x2 - 2, 4 do
				B(u, Y0 + h, z1 - 0.4, u + 2, Y0 + h + 2.4, z1 + 1.2, "WingMerlon")
				B(u, Y0 + h, z2 - 1.2, u + 2, Y0 + h + 2.4, z2 + 0.4, "WingMerlon")
			end
			for u = z1, z2 - 2, 4 do
				B(x1 - 0.4, Y0 + h, u, x1 + 1.2, Y0 + h + 2.4, u + 2, "WingMerlon")
				B(x2 - 1.2, Y0 + h, u, x2 + 0.4, Y0 + h + 2.4, u + 2, "WingMerlon")
			end
		end

		-- the grid's walls, 9 high, with the road's gates (7-high arches)
		local doorsList = {}
		local function rwall(axis, c, a, b, doors)
			table.sort(doors, function(p, q)
				return p[1] < q[1]
			end)
			local function seg(u1, u2, yb, yt)
				if u2 - u1 > 0.01 then
					if axis == "z" then
						B(c - 1, Y0 + yb, u1, c + 1, Y0 + yt, u2, "RoofWall")
					else
						B(u1, Y0 + yb, c - 1, u2, Y0 + yt, c + 1, "RoofWall")
					end
				end
			end
			local cur = a
			for _, d in ipairs(doors) do
				seg(cur, d[1], 0, 9)
				seg(d[1], d[2], 7, 9)
				table.insert(doorsList, { axis, c, d[1], d[2] })
				cur = d[2]
			end
			seg(cur, b, 0, 9)
		end
		rwall("z", -17, -40, 97, { { 4, 12 } })
		rwall("z", 18, -40, 97, { { 14, 22 } })
		rwall("z", 53, -40, 97, { { 78, 86 } })
		rwall("x", -6, -52, 88, {})
		rwall("x", 28, -52, 88, { { -30, -22 }, { 36, 44 } })
		rwall("x", 68, -52, 88, { { -42, -34 }, { 24, 32 } })
		rwall("x", 98, -52, 66, {}) -- the back of the north cells (behind it, a pocket under a long pitched roof)
		rwall("x", 98, 78, 88, {})
		-- (the gate court's north gate, x 66..78, is open to the sky: a gap with a lintel arch over it)
		B(66, Y0 + 7, 97, 78, Y0 + 9, 99, "RoofWall")
		rwall("z", 57, 99, 105, {}) -- (the pocket's east end)
		rwall("x", 141, 58, 88, { { 60, 68 } }) -- the east block's two courts
		-- the pocket behind the north cells: a cap and a long roof over it
		B(-52, Y0, 99, 56, Y0 + 2, 105, "WingCap")
		gable(-52, 99, 56, 105, Y0 + 2, nil, 0.8)
		-- ... and the alcove at the ladder: side walls over the curtain wall's top
		R(52, 170, 56, 171, 12, "RoofWall")
		R(52, 175, 56, 176, 12, "RoofWall")

		-- gate dressing: a banner and a torch each side of every gate
		for _, d in ipairs(doorsList) do
			local axis, c, d1, d2 = d[1], d[2], d[3], d[4]
			for _, s in ipairs({ -1, 1 }) do
				if axis == "z" then
					banner(c + s * 1.15, d1 - 1.6, true)
					banner(c + s * 1.15, d2 + 1.6, true)
					torch(Vector3.new(c + s * 1.0, Y0 + 5.5, d1 - 0.6), Vector3.new(s, 0, 0))
				else
					banner(d1 - 1.6, c + s * 1.15, false)
					banner(d2 + 1.6, c + s * 1.15, false)
					torch(Vector3.new(d1 - 0.6, Y0 + 5.5, c + s * 1.0), Vector3.new(0, 0, s))
				end
			end
		end

		-- the unused cells: masses under pitched roofs
		for _, m in ipairs({
			{ -52, -40, -18, -7 }, { -16, -40, 17, -7 }, { 19, -40, 52, -7 }, { 54, -40, 88, -7 },
			{ -16, 29, 17, 67 }, { -16, 69, 17, 97 }, { 54, -5, 88, 27 }, { 54, 29, 88, 67 },
		}) do
			mass(m[1], m[2], m[3], m[4])
		end

		-- the road: a lit flagstone way, door to door, with a dark edge, laid over the courts' tiled floors
		local path = {
			{ -52, 85 }, { -38, 85 }, { -38, 48 }, { -26, 48 }, { -26, 8 }, { -4, 8 }, { -4, 18 }, { 40, 18 }, { 40, 48 },
			{ 28, 48 }, { 28, 82 }, { 72, 82 }, { 72, 120 }, { 64, 120 }, { 64, 173 }, { 56, 173 },
		}
		local function tiles(x1, z1, x2, z2) -- a court's floor: bands of two slates
			local i = 0
			for z = z1, z2 - 0.1, 5 do
				i += 1
				B(x1, Y0, z, x2, Y0 + 0.12, math.min(z + 5, z2), "WingTile", i % 2 == 0 and Color3.fromRGB(50, 49, 47) or Color3.fromRGB(42, 41, 40), i % 2 == 0 and MAT.Slate or MAT.Cobblestone)
			end
		end
		for _, c in ipairs({
			{ -51, 69, -18, 96 }, { -51, 29, -18, 67 }, { -51, -5, -18, 27 }, { -16, -5, 17, 27 }, { 19, -5, 52, 27 }, { 19, 29, 52, 67 },
			{ 19, 69, 52, 96 }, { 55, 69, 87, 96 }, { 62, 99, 87, 140 }, { 59, 142, 79, 176 }, { 79, 161, 87, 180 }, { 79, 142, 87, 144.5 }, { 66, 176, 79, 180 },
		}) do
			tiles(c[1], c[2], c[3], c[4])
		end
		for i = 1, #path - 1 do
			local a, b = path[i], path[i + 1]
			local x1, x2 = math.min(a[1], b[1]) - 2.5, math.max(a[1], b[1]) + 2.5
			local z1, z2 = math.min(a[2], b[2]) - 2.5, math.max(a[2], b[2]) + 2.5
			B(x1, Y0, z1, x2, Y0 + 0.24, z2, "WingRoad", Color3.fromRGB(112, 106, 94), MAT.Cobblestone)
		end
		-- braziers beside the road, one every court, and the last stretch lined with them
		for _, p in ipairs({
			{ -46, 80 }, { -46, 90 }, { -42.5, 47 }, { -31, 14 }, { -9, 13 }, { 8, 23 }, { 35, 23 }, { 45, 42 }, { 33, 58 }, { 22.5, 78 }, { 46, 86 }, { 67.8, 90 },
			{ 68, 112 }, { 69, 130 }, { 67.8, 146 }, { 69, 160 }, { 66.8, 175 },
		}) do
			brazier(Vector3.new(p[1], Y0, p[2]))
		end

		-- the courts' dressing: (1,4) the landing court -------------------------------
		hut(-33, 88, -21, 96, 8, false) -- the guard post
		crate(-47, 94.5)
		crate(-44.5, 94.8, 2)
		barrel(-24, 72)
		barrel(-22, 74)
		keep(-52, 69, -46, 75, 14) -- a watch-tower in the corner
		-- (1,3) the west ward: cell-houses
		hut(-50, 52, -42, 64, 9, true)
		hut(-33, 55, -20, 64, 9, true)
		cage(-46, 36)
		cage(-47, 31)
		crate(-22, 34)
		stocks(-34, 38)
		-- (1,2) the gallows yard
		gallows(-42, 8)
		cage(-20, 22)
		cage(-47, 22)
		stocks(-33, 19)
		barrel(-48, -2)
		-- (2,2) the cistern court: a skylight into the dark, and a colonnade
		B(6, Y0, 4, 16, Y0 + 0.5, 14, "WingSkylight", IRON, MAT.Metal)
		part({ Name = "WingSkylightGlass", Size = Vector3.new(8.6, 0.3, 8.6), CFrame = CFrame.new(11, Y0 + 0.55, 9), Material = MAT.Glass, Color = Color3.fromRGB(20, 26, 30), Transparency = 0.3, Parent = wing })
		arcade(-14, -3, 14, -3)
		arcade(-14, 24, 6, 24)
		-- (3,2) the armoury
		rack(24, -2, true)
		rack(36, -2, true)
		rack(48, 6, false)
		barrel(22, 8)
		barrel(23.4, 10)
		crate(49, 22)
		crate(46, 24, 2.2)
		-- (3,3) the guard court: a keep, and its yard
		keep(46, 46, 52, 66, 16)
		crate(22, 34)
		crate(24, 31, 2)
		stocks(32, 36)
		cage(24, 60)
		-- (3,4) the parade ground: two rows of pillars either side of the road
		arcade(22, 74, 50, 74)
		arcade(22, 92, 50, 92)
		B(36, Y0, 82.5, 40, Y0 + 3, 86.5, "WingPlinth", TRIM, MAT.Slate)
		-- (4,4) the gate court: two gate towers
		keep(56, 88, 66, 97, 17)
		keep(78, 88, 87, 97, 17)
		crate(60, 72)
		barrel(84, 74)
		barrel(85.6, 75.6)
		-- the east block: the bell yard, the stair-well court, the ladder terrace
		keep(76, 108, 87, 120, 22) -- the belfry
		crate(60, 104)
		crate(61.6, 106, 2)
		barrel(84, 132)
		barrel(60, 135)
		cage(74, 134)
		B(70, Y0, 150, 74, Y0 + 3, 154, "WingPlinth", TRIM, MAT.Slate) -- a well-head
		stocks(75, 146)
		rack(72, 158, true)
		crate(86, 172, 2)
		-- the ladder terrace: a dais against the bastion's face, a colonnade before it
		B(68, Y0, 166, 84, Y0 + 2, 175, "WingDais", TRIM, MAT.Slate)
		B(70, Y0 + 2, 168, 82, Y0 + 3, 173, "WingDais", TRIM, MAT.Slate)
		arcade(68, 164, 84, 164)
		-- the bastion's south face (x 60..196, z 181) and its corner tower (z 177) bound the terrace: pilasters up the face
		-- and a blind archway with a dark recess in its middle, so the court reads as the keep's forecourt
		for _, x in ipairs({ 69, 75, 81, 87 }) do
			B(x - 1, Y0, 179.8, x + 1, Y0 + 22, 181, "WingPilaster", TRIM, MAT.Slate)
			B(x - 1.5, Y0, 179.5, x + 1.5, Y0 + 1.2, 181, "WingPilaster", TRIM, MAT.Slate)
		end
		B(68, Y0 + 20, 179.7, 88, Y0 + 21.4, 181, "WingCourse", TRIM, MAT.Slate)
		B(72, Y0, 180.2, 78, Y0 + 12, 181, "WingArchFrame", TRIM, MAT.Slate)
		B(73, Y0, 180.5, 77, Y0 + 10.4, 181, "WingArchRecess", VOIDC, MAT.Slate).CanCollide = false
		B(72, Y0 + 10.4, 180.2, 78, Y0 + 12, 181, "WingArchFrame", TRIM, MAT.Slate)

		-- the ladder's alcove and the ladder itself: hung over the curtain wall on the yard walk's side (x 50..52, y 30..46),
		-- lying on the terrace by the gap till it's kicked
		for _, m in ipairs(map:GetChildren()) do -- (the curtain wall's merlons that stood in the way)
			if m:IsA("BasePart") and m.Name == "Merlon" and math.abs(m.Position.X - 54) < 0.5 and math.abs(m.Position.Z - 173) < 3 and math.abs(m.Position.Y - 45) < 1 then
				m:Destroy()
			end
		end
		local block = part({ Name = "WingLadderGap", Size = Vector3.new(0.6, 9, 4), CFrame = CFrame.new(52.3, Y0 + 4.5, 173), Transparency = 1, CanQuery = false, Parent = wing })
		do
			local LZ, LEN = 173, 16
			local truss = Instance.new("TrussPart")
			truss.Name = "WingLadder"
			truss.Size = Vector3.new(2, LEN, 2)
			truss.Anchored, truss.Transparency = true, 1
			truss.CanCollide, truss.CanQuery = false, false
			local down = CFrame.new(51, 30.15 + LEN / 2, LZ) * CFrame.Angles(0, math.pi / 2, 0)
			truss.CFrame = down
			truss.Parent = map
			local wood, dark = Color3.fromRGB(84, 62, 42), Color3.fromRGB(62, 46, 32)
			local function bit(size, offset, color)
				local p = part({ Name = "LadderWood", Size = size, CFrame = down * offset, Material = MAT.Wood, Color = color, CanCollide = false, CanQuery = false, CanTouch = false, Massless = true })
				p.Anchored = false
				local wc = Instance.new("WeldConstraint")
				wc.Part0, wc.Part1 = truss, p
				wc.Parent = p
			end
			for _, x in ipairs({ -0.8, 0.8 }) do
				bit(Vector3.new(0.28, LEN, 0.32), CFrame.new(x, 0, 0), wood)
			end
			local lr = Random.new(181)
			for y = -LEN / 2 + 0.6, LEN / 2 - 0.4, 1 do
				bit(Vector3.new(1.65, 0.16, 0.18), CFrame.new(0, y, 0) * CFrame.Angles(0, 0, lr:NextNumber(-0.04, 0.04)), dark)
			end
			-- lying along the terrace's west wall, its foot at the gap and its tip to the SOUTH (the bastion's tower is north of it);
			-- init.server's kickLadder takes the lying direction from the truss
			truss.CFrame = CFrame.new(59, Y0 + 0.3, LZ - LEN / 2) * CFrame.Angles(-math.pi / 2, 0, 0)
			local spot = part({ Name = "LadderPrompt", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(57.5, Y0 + 1.5, LZ - 1), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
			local function climbPrompt(pos)
				local p = part({ Name = "LadderClimbPrompt", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(pos), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
				local pp = prompt(p, "Climb", "Ladder", 0, 6)
				pp.Enabled = false
				return pp
			end
			info.WingLadder = {
				Ladder = truss,
				Down = down,
				Block = block,
				Prompt = prompt(spot, "Kick down", "Ladder", 0, 7),
				UpPrompt = climbPrompt(Vector3.new(49.4, 32.65, LZ)),
				DownPrompt = climbPrompt(Vector3.new(54.8, Y0 + 2, LZ)),
				Climb = {
					foot = Vector3.new(49.4, 33.15, LZ),
					top = Vector3.new(49.4, Y0 + 3.3, LZ),
					off = Vector3.new(56, Y0 + 3.3, LZ),
				},
			}
		end

		-- the roof's hollows: stouter and quicker than the cell block's (Enemies.lua's Elite flag), a handful
		local function hollow(x, z, lx, lz)
			table.insert(info.EnemySpawns, { Type = "Hollow", Elite = true, CFrame = CFrame.lookAt(Vector3.new(x, Y0 + 3.2, z), Vector3.new(lx, Y0 + 3.2, lz)) })
		end
		hollow(-40, 38, -38, 48) -- the west ward
		hollow(-34, 25, -26, 8) -- the gallows yard
		hollow(36, 58, 40, 48) -- the guard court
		hollow(78, 78, 72, 82) -- the gate court
		hollow(70, 130, 64, 141) -- the bell yard
		hollow(68, 148, 64, 160) -- the stair-well court
		hollow(76, 170, 64, 173) -- the ladder terrace, on its dais
	end

	-----------------------------------------------------------------------
	-- 11. THE FALLEN CELLBLOCK, LOWER: west of the start's cell block, under the wing's west rooms (x -52..-20, z 28..96,
	--     y 0..18): a hallway like the first one (14-wide aisle, barred cells either side, pillars, arch of a ceiling at 16),
	--     reached by a stair down from the wing's far west room (the hole in that room's floor, x -44..-30, z 72..96). Its
	--     south end leads on into a winding passage under the wing's south side to the EAST wall (away from the mansion),
	--     blown out there (the smouldering hole, x 88..92, z -37..-27: nothing is built past it), and in
	--     the east cell opposite the bonfire cell's row a door goes through the first block's west wall (z 52..58): it opens
	--     only from this side (init.server), into the start's west cell 4, whose bars are opened for it - the cell directly
	--     across the corridor from the bonfire's. The bonfire cell itself has sewer rock behind it, so nothing can reach it
	--     from outside. Its own random stream.
	-----------------------------------------------------------------------
	do
		local fr = Random.new(4040)
		local wing = map:FindFirstChild("PrisonWing")
		local STONE = COL.Wall
		local function sc()
			return COL.Wall:Lerp(COL.WallDark, fr:NextNumber() * 0.6)
		end
		local function F(x1, y1, z1, x2, y2, z2, name, color, mat)
			return box(x1, y1, z1, x2, y2, z2, mat or MAT.Cobblestone, color or sc(), name or "FallenWall", wing)
		end
		local CHAR = Color3.fromRGB(28, 26, 24)
		local TRIMF = Color3.fromRGB(94, 90, 84)
		local RY = 44

		-- the shell: floor, ceiling (y 16..18, like the first), the south end wall, a north wall for the stair's shaft
		box(-52, -2, 28, -20, 0, 96, MAT.Slate, COL.Floor, "FallenFloor", wing)
		box(-52, 16, 28, -20, 18, 72, MAT.Slate, COL.Ceiling, "FallenCeiling", wing)
		F(-52, 0, 28, -40, 16, 30, "FallenWall") -- (open at x -40..-32: the way on, south)
		F(-32, 0, 28, -20, 16, 30, "FallenWall")
		-- (the east side is the first block's west wall, x -20..-18; the west side the wing's outer wall, x -56..-52)

		-- bars and pillars: the aisle is x -44..-30, cells 8 deep on the west (z 40..70) and 10 on the east (z 30..70)
		local function barsFront(x, z1, z2, gap)
			barRow(x, z1 + 0.8, z2 - 0.8, 16, gap and { gap } or nil)
		end
		for _, z in ipairs({ 40, 50, 60, 70 }) do
			F(-52, 0, z - 1, -44, 16, z + 1, "FallenDivider") -- west cell dividers
		end
		for _, z in ipairs({ 40, 50, 60, 70 }) do
			F(-30, 0, z - 1, -20, 16, z + 1, "FallenDivider") -- east
		end
		F(-30, 0, 29, -20, 16, 31, "FallenDivider")
		for _, z in ipairs({ 40, 50, 60, 70 }) do
			F(-44.8, 0, z - 0.8, -43.2, 16, z + 0.8, "FallenPillar")
		end
		for _, z in ipairs({ 30, 40, 50, 60, 70 }) do
			F(-30.8, 0, z - 0.8, -29.2, 16, z + 0.8, "FallenPillar")
		end
		-- west cells (the bay z 30..40 is open: it's where the wall's blown out)
		barsFront(-44, 40, 50)
		barsFront(-44, 50, 60, { 52, 58 }) -- (open)
		barsFront(-44, 60, 70)
		-- east cells: the third (z 50..60) is open - the door's cell
		barsFront(-30, 30, 40)
		barsFront(-30, 40, 50)
		barsFront(-30, 50, 60, { 52, 58 })
		barsFront(-30, 60, 70)
		-- the north end of the aisle: the stair's foot is x -37..-30 (flight 2); the rest, x -44..-37, is the fill under flight 1
		-- cell furniture: a plank bed, straw, bones on some floors
		for _, c in ipairs({ { -48, 45 }, { -48, 65 }, { -25, 35 }, { -25, 45 }, { -25, 65 } }) do
			local x, z = c[1], c[2]
			box(x - 1.3, 1.2, z - 2.7, x + 1.3, 1.6, z + 2.7, MAT.WoodPlanks, COL.Wood, "FallenBed", wing)
			box(x - 1.2, 0, z - 2.6, x - 0.8, 1.2, z - 2.2, MAT.Wood, COL.Wood, "FallenBedLeg", wing)
			box(x + 0.8, 0, z + 2.2, x + 1.2, 1.2, z + 2.6, MAT.Wood, COL.Wood, "FallenBedLeg", wing)
			local s = part({ Name = "FallenStraw", Size = Vector3.new(fr:NextNumber(2, 3.4), 0.2, fr:NextNumber(2, 3.4)), CFrame = CFrame.new(x + fr:NextNumber(-2, 2), 0.1, z + fr:NextNumber(-3, 3)) * CFrame.Angles(0, fr:NextNumber() * 3, 0), Material = MAT.Fabric, Color = COL.Straw, CanCollide = false, Parent = wing })
		end
		-- torches on the aisle's pillars (few, and low: this is a fallen place) - and the stair's top
		torch(Vector3.new(-43.2, 9, 60), Vector3.new(1, 0, 0))
		torch(Vector3.new(-29.2, 9, 50), Vector3.new(-1, 0, 0))
		torch(Vector3.new(-29.2, 9, 70), Vector3.new(-1, 0, 0))

		-- THE STAIR: from the room above (its floor, y 30) down two flights round a landing at y 14, to the aisle's end (x -44..-30,
		-- z 72..96 shaft; flight 1 x -44..-37 climbing north, flight 2 x -37..-30 coming back south to the aisle at z 74.8)
		F(-46, 0, 72, -44, 28, 96, "FallenShaft") -- west
		F(-30, 0, 72, -28, 28, 96, "FallenShaft") -- east
		F(-46, 0, 96, -28, 28, 98, "FallenShaft") -- north
		F(-46, 18, 70, -28, 28, 72, "FallenShaft") -- south, over the hallway's ceiling
		for i = 0, 14 do
			F(-44, 0, 72 + 1.4 * i, -37, 29 - i, 72 + 1.4 * (i + 1), "FallenStep", sc(), MAT.Slate)
		end
		F(-44, 0, 93, -30, 14, 96, "FallenLanding", sc(), MAT.Slate)
		for j = 0, 12 do
			F(-37, 0, 93 - 1.4 * (j + 1), -30, 13 - j, 93 - 1.4 * j, "FallenStep", sc(), MAT.Slate)
		end
		-- rails round the hole at the top (the floor above: y 30), the south edge open at flight 1 for the way in
		F(-45, 30, 72, -44, 33, 96, "FallenRail")
		F(-30, 30, 72, -29, 33, 96, "FallenRail")
		F(-37, 30, 71, -30, 33, 72, "FallenRail")
		torch(Vector3.new(-29.9, 12, 84), Vector3.new(-1, 0, 0))

		-- THE WAY OUT: the aisle's south end opens (x -40..-32) into a winding passage - south, east, down, east, back up, east,
		-- down, east - that runs under the wing's south side to its EAST wall (x 88..92), the side away from the mansion, and
		-- that wall is blasted open (z -37..-27, y 0..11). Laid out on a 4-stud grid: floor/ceiling per cell, wall wherever a
		-- cell's neighbour isn't passage. Nothing is built past the hole.
		box(-56, -8, 28, -52, RY, 42, MAT.Cobblestone, sc(), "WingOuter", wing) -- (the west wall is whole again)
		local P = {}
		local function leg(i1, j1, i2, j2)
			for i = math.min(i1, i2), math.max(i1, i2) do
				for j = math.min(j1, j2), math.max(j1, j2) do
					P[i .. "," .. j] = true
				end
			end
		end
		local legs = { { -10, 6, -9, -5 }, { -10, -5, -3, -4 }, { -4, -5, -3, -9 }, { -4, -9, 6, -8 }, { 5, -9, 6, -4 }, { 5, -5, 16, -4 }, { 15, -5, 16, -9 }, { 15, -9, 21, -8 } }
		for _, l in ipairs(legs) do
			leg(l[1], l[2], l[3], l[4])
		end
		local function has(i, j)
			return P[i .. "," .. j] == true
		end
		local function runs(a1, a2, b1, b2, test, emit) -- (maximal runs of test(a, b) along a, for each b)
			for b = b1, b2 do
				local s
				for a = a1, a2 + 1 do
					if a <= a2 and test(a, b) then
						s = s or a
					elseif s then
						emit(s, a - 1, b)
						s = nil
					end
				end
			end
		end
		-- DRESSED LIKE THE FIRST HALLWAY (section 8's detail pass): wall dressing, arch ribs, flagstones, a gutter, clutter
		local oldDetailRng = Detail.useRng(Random.new(4041))
		local face, dress = Detail.face, Detail.dressWall
		runs(-10, 21, -9, 6, has, function(s, e, j)
			box(4 * s, -2, 4 * j, 4 * e + 4, 0, 4 * j + 4, MAT.Slate, COL.Floor, "FallenFloor", wing)
			box(4 * s, 16, 4 * j, 4 * e + 4, 18, 4 * j + 4, MAT.Slate, COL.Ceiling, "FallenCeiling", wing)
			Detail.floorSeams(4 * s, 4 * j, 4 * e + 4, 4 * j + 4, 4)
			Detail.floorTiles(4 * s, 4 * j, 4 * e + 4, 4 * j + 4, 3, 0.22, COL.Floor)
		end)
		for _, dj in ipairs({ -1, 1 }) do -- (walls facing -z / +z; the +z side of the first row is the opening into the aisle)
			runs(-10, 21, -9, 6, function(i, j)
				return has(i, j) and not has(i, j + dj) and not (dj == 1 and j == 6)
			end, function(s, e, j)
				local z = dj < 0 and 4 * j - 2 or 4 * j + 4
				F(has(s - 1, j) and 4 * s or 4 * s - 2, 0, z, has(e + 1, j) and 4 * e + 4 or 4 * e + 6, 16, z + 2, "FallenWall")
				local zf, mid = dj < 0 and 4 * j or 4 * j + 4, 2 * (s + e + 1)
				if e - s >= 2 then
					torch(Vector3.new(mid, 9, zf - dj * 0.3), Vector3.new(0, 0, -dj))
				end
				dress(face(mid, zf, 0, -dj), 4 * (e - s + 1), 16, "corridor")
			end)
		end
		for _, di in ipairs({ -1, 1 }) do -- (walls facing -x / +x; none at the east end: that's the hole)
			runs(-9, 6, -10, 21, function(j, i)
				return has(i, j) and not has(i + di, j) and not (di == 1 and i == 21)
			end, function(s, e, i)
				local x = di < 0 and 4 * i - 2 or 4 * i + 4
				F(x, 0, has(i, s - 1) and 4 * s or 4 * s - 2, x + 2, 16, has(i, e + 1) and 4 * e + 4 or 4 * e + 6, "FallenWall")
				local xf, mid = di < 0 and 4 * i or 4 * i + 4, 2 * (s + e + 1)
				if e - s >= 2 then
					torch(Vector3.new(xf - di * 0.3, 9, mid), Vector3.new(-di, 0, 0))
				end
				dress(face(xf, mid, -di, 0), 4 * (e - s + 1), 16, "corridor")
			end)
		end
		for _, l in ipairs(legs) do -- (stone arch ribs every 12 studs, on piers down to the floor; none where a side passage joins)
			local i1, i2, j1, j2 = math.min(l[1], l[3]), math.max(l[1], l[3]), math.min(l[2], l[4]), math.max(l[2], l[4])
			local function rib(cf, pierSize, pierA, pierB)
				Detail.archRib(cf, 0, 11, 3.55, 4.3, 0.9, 1.3, 0, 11, MAT.Cobblestone, COL.Wall, false)
				for _, o in ipairs({ pierA, pierB }) do
					Detail.part(pierSize, cf * CFrame.new(o, 5.5, 0), MAT.Cobblestone, COL.Wall, { collide = true, name = "ArchPier" })
				end
			end
			if i2 - i1 < j2 - j1 then
				for j = j1, j2, 3 do
					if not has(i1 - 1, j) and not has(i2 + 1, j) then
						rib(CFrame.new(2 * (i1 + i2 + 1), 0, 4 * j + 2), Vector3.new(0.9, 11, 1.3), -3.55, 3.55)
					end
				end
			else
				for i = i1, i2, 3 do
					if not has(i, j1 - 1) and not has(i, j2 + 1) then
						rib(CFrame.new(4 * i + 2, 0, 2 * (j1 + j2 + 1)) * CFrame.Angles(0, math.pi / 2, 0), Vector3.new(0.9, 11, 1.3), -3.55, 3.55)
					end
				end
			end
		end
		Detail.gutter(-37, -19, 71)
		Detail.slumpedSkeleton(Vector3.new(-38.6, 0, 12), Vector3.new(1, 0, 0))
		Detail.slumpedSkeleton(Vector3.new(20, 0, -34.6), Vector3.new(0, 0, 1))
		Detail.slumpedSkeleton(Vector3.new(52, 0, -13.4), Vector3.new(0, 0, -1))
		Detail.slumpedSkeleton(Vector3.new(70, 0, -29.4), Vector3.new(0, 0, -1))
		Detail.bucket(Vector3.new(-33.5, 0, -2))
		Detail.bucket(Vector3.new(76, 0, -34.5))
		Detail.stool(Vector3.new(-12, 0, -14), true)
		Detail.stool(Vector3.new(38, 0, -18), false)
		Detail.bonePile(Vector3.new(10, 0, -32), 8)
		Detail.bonePile(Vector3.new(44, 0, -16), 6)
		-- the aisle: arch ribs over the pillar pairs, the cells' walls and dividers, flagstones, more torches, clutter
		for z = 40, 70, 10 do
			Detail.archRib(CFrame.new(-37, 0, z), 0, 11, 7, 4.3, 0.9, 1.3, 0, 11, MAT.Cobblestone, COL.Wall, false)
		end
		torch(Vector3.new(-43.2, 9, 40), Vector3.new(1, 0, 0))
		torch(Vector3.new(-43.2, 9, 70), Vector3.new(1, 0, 0))
		torch(Vector3.new(-29.2, 9, 30), Vector3.new(-1, 0, 0))
		dress(face(-46, 30, 0, 1), 12, 16, "corridor")
		dress(face(-26, 30, 0, 1), 12, 16, "corridor")
		for _, cz in ipairs({ 35, 45, 55, 65 }) do
			dress(face(-52, cz, 1, 0), 9, 16, "cell")
		end
		for _, cz in ipairs({ 35, 45, 65 }) do
			dress(face(-20, cz, -1, 0), 9, 16, "cell")
		end
		for _, z in ipairs({ 40, 50, 60, 70 }) do
			for _, cx in ipairs({ -48, -25 }) do
				local w = cx < -40 and 7 or 9
				dress(face(cx, z - 1, 0, -1), w, 16, "cell")
				if z < 70 then
					dress(face(cx, z + 1, 0, 1), w, 16, "cell")
				end
			end
		end
		Detail.floorSeams(-44, 30, -30, 72, 3)
		Detail.floorTiles(-44, 30, -30, 72, 3, 0.22, COL.Floor)
		chain(Vector3.new(-51.6, 9, 44), 6)
		chain(Vector3.new(-51.6, 9, 64), 8)
		chain(Vector3.new(-20.4, 9, 36), 5)
		chain(Vector3.new(-20.4, 9, 66), 7)
		remains(Vector3.new(-49, 0, 56))
		remains(Vector3.new(-23, 0, 63))
		Detail.slumpedSkeleton(Vector3.new(-50.6, 0, 69), Vector3.new(1, 0, 0))
		Detail.slumpedSkeleton(Vector3.new(-21.4, 0, 39), Vector3.new(-1, 0, 0))
		Detail.bucket(Vector3.new(-50, 0, 42))
		Detail.bucket(Vector3.new(-22, 0, 62))
		Detail.stool(Vector3.new(-27, 0, 43), true)
		Detail.bonePile(Vector3.new(-47, 0, 34), 8)
		Detail.bonePile(Vector3.new(-38, 0, 66), 6)
		Detail.useRng(oldDetailRng)

		-- THE SMOULDERING HOLE: the wing's east wall (x 88..92) blasted open at z -37..-27, y 0..11. Two layers - the outer
		-- wider than the inner, as if it blew outward - their edges jagged, charred and bitten; scorch and cracks round it,
		-- a litter of fallen stone on the floor, bent bars, embers, a fire, smoke, an orange light. Nothing past it.
		local function blast(x1, x2, opZ1, opZ2, topC, band)
			for k = 0, 13 do
				local z1 = -39 + k
				local zc = z1 + 0.5
				local h, hot
				if zc > opZ1 and zc < opZ2 then
					local m = (zc - opZ1) / (opZ2 - opZ1)
					h = topC - 3 * (2 * math.abs(m - 0.5)) ^ 1.6 + fr:NextNumber(-1.1, 1.1)
					hot = true
				else
					local dist = math.min(math.abs(zc - opZ1), math.abs(zc - opZ2))
					h = math.max(0, band - dist * 2.2) * fr:NextNumber(0.25, 1)
					hot = h > 0
				end
				box(x1, h, z1, x2, RY, z1 + 1, MAT.Cobblestone, hot and CHAR:Lerp(sc(), fr:NextNumber(0, 0.4)) or sc(), "BlastWall", wing)
			end
			box(x1, -8, -39, x2, 0, -25, MAT.Cobblestone, sc(), "BlastWall", wing)
		end
		blast(90, 92, -37, -27, 11.5, 7)
		blast(88, 90, -36, -28, 9.5, 4.5)
		-- scorch on the inner face and floor, cracks radiating (thin, dark, slightly proud of the wall)
		for _ = 1, 9 do
			local z, y = fr:NextNumber(-38.5, -25.5), fr:NextNumber(0.5, 13)
			local w, h = fr:NextNumber(1.2, 3.4), fr:NextNumber(1, 3)
			part({ Name = "BlastSoot", Size = Vector3.new(0.06, h, w), CFrame = CFrame.new(87.96, y, z) * CFrame.Angles(fr:NextNumber(-0.4, 0.4), 0, 0), Material = MAT.Slate, Color = Color3.fromRGB(14, 13, 12), Transparency = fr:NextNumber(0.1, 0.5), CanCollide = false, Parent = wing })
		end
		for k = 1, 16 do
			local ang = k / 16 * math.pi * 2 + fr:NextNumber(-0.2, 0.2)
			local len = fr:NextNumber(2.5, 7)
			local cy, cz = 5.2, -32
			part({ Name = "BlastCrack", Size = Vector3.new(0.06, len, 0.16), CFrame = CFrame.new(87.97, cy + math.cos(ang) * (5 + len / 2), cz + math.sin(ang) * (5 + len / 2)) * CFrame.Angles(ang - math.pi / 2 + math.pi / 2, 0, 0), Material = MAT.Slate, Color = Color3.fromRGB(10, 10, 9), CanCollide = false, Parent = wing })
		end
		part({ Name = "BlastScorch", Size = Vector3.new(11, 0.05, 14), CFrame = CFrame.new(83, 0.03, -32), Material = MAT.Slate, Color = Color3.fromRGB(12, 11, 10), CanCollide = false, Parent = wing })
		-- debris: fallen stone, charred beams, a few of them glowing
		local embers = {}
		for _ = 1, 22 do
			local s = fr:NextNumber(0.5, 2.2)
			local ch = part({ Name = "BlastDebris", Size = Vector3.new(s, s * fr:NextNumber(0.5, 1), s * fr:NextNumber(0.6, 1.3)), CFrame = CFrame.new(fr:NextNumber(79, 88), s * 0.3, fr:NextNumber(-38.5, -25.5)) * CFrame.Angles(fr:NextNumber(-0.7, 0.7), fr:NextNumber(0, 6.28), fr:NextNumber(-0.7, 0.7)), Material = MAT.Cobblestone, Color = fr:NextNumber() < 0.5 and CHAR or sc(), Parent = wing })
			if fr:NextNumber() < 0.3 then
				table.insert(embers, ch)
			end
		end
		for _ = 1, 3 do
			part({ Name = "BlastBeam", Size = Vector3.new(fr:NextNumber(4, 7), 0.6, 0.6), CFrame = CFrame.new(fr:NextNumber(82, 87), 1.2, fr:NextNumber(-37, -27)) * CFrame.Angles(fr:NextNumber(-0.3, 0.3), fr:NextNumber(0, 3.14), fr:NextNumber(-0.3, 0.3)), Material = MAT.Wood, Color = Color3.fromRGB(22, 18, 14), Parent = wing })
		end
		-- the cell bars, bent out at the hole's top
		for k = 1, 5 do
			part({ Name = "BlastBar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(fr:NextNumber(2.5, 5), 0.3, 0.3), CFrame = CFrame.new(88.8, 10, -35.4 + k * 1.3) * CFrame.Angles(fr:NextNumber(-0.3, 0.3), fr:NextNumber(-0.4, 0.4), math.pi / 2 + fr:NextNumber(-0.5, 0.5)), Material = MAT.Metal, Color = COL.Rust, CanCollide = false, Parent = wing })
		end
		-- smoulder: glowing coals on the rubble, a fire, rising smoke, and the orange glow of it all
		for _, e in ipairs(embers) do
			local coal = part({ Name = "BlastEmber", Size = Vector3.new(0.5, 0.18, 0.5), CFrame = e.CFrame * CFrame.new(0, e.Size.Y / 2 + 0.02, 0), Material = MAT.Neon, Color = Color3.fromRGB(255, 96, 24), CanCollide = false, Parent = wing })
			local smoke = Instance.new("ParticleEmitter")
			smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
			smoke.Color = ColorSequence.new(Color3.fromRGB(70, 66, 62))
			smoke.Size = NumberSequence.new(0.6, 2)
			smoke.Transparency = NumberSequence.new(0.5, 1)
			smoke.Lifetime = NumberRange.new(2, 3.5)
			smoke.Rate = 4
			smoke.Speed = NumberRange.new(0.8, 1.6)
			smoke.Acceleration = Vector3.new(0.6, 1.2, 0)
			smoke.SpreadAngle = Vector2.new(20, 20)
			smoke.Parent = coal
		end
		local burn = part({ Name = "BlastFire", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(86, 1.2, -32), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = wing })
		local fire = Instance.new("Fire")
		fire.Size, fire.Heat = 4, 6
		fire.Color, fire.SecondaryColor = Color3.fromRGB(255, 120, 30), Color3.fromRGB(120, 30, 10)
		fire.Parent = burn
		local glow = Instance.new("PointLight")
		glow.Color, glow.Range, glow.Brightness = Color3.fromRGB(255, 130, 50), 24, 2.2
		glow.Shadows = true
		glow.Parent = burn
		addFlicker(glow)
		local plume = part({ Name = "BlastSmoke", Size = Vector3.new(1, 6, 7), CFrame = CFrame.new(90, 6, -32), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = wing })
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
		pe.Color = ColorSequence.new(Color3.fromRGB(58, 54, 50))
		pe.Size = NumberSequence.new(2, 5)
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
		pe.Lifetime = NumberRange.new(3, 5)
		pe.Rate = 8
		pe.Speed = NumberRange.new(1, 2.5)
		pe.Acceleration = Vector3.new(0.5, 1.4, 0)
		pe.SpreadAngle = Vector2.new(25, 25)
		pe.Parent = plume

		-- THE UNDERFIRE: the smouldering hole's far side. Outside the breach the ground is gouged into a wide burning pit;
		-- its throat drops (a cut, in init.server) into a buried room far below: dark rock lit only by fire - a rubble heap
		-- under the broken ceiling, lava channels along the walls, braziers. Its own random stream. info.Underfire: Gate (the
		-- breach's lip), Pit, Landing, Zone.
		do
			local ur = Random.new(7070)
			local under = Instance.new("Folder")
			under.Name = "Underfire"
			under.Parent = map
			local function U(x1, y1, z1, x2, y2, z2, material, color, name)
				return box(x1, y1, z1, x2, y2, z2, material, color, name, under)
			end
			local function R(a, b)
				return ur:NextNumber(a, b)
			end
			local ROCK, DEEP = Color3.fromRGB(30, 27, 27), Color3.fromRGB(20, 18, 19)
			local EMBER = Color3.fromRGB(255, 70, 20)
			local function dark()
				return ur:NextNumber() < 0.5 and ROCK or DEEP
			end
			local function tilt(p, k)
				p.CFrame *= CFrame.Angles(R(-k, k), R(0, 6.28), R(-k, k))
			end
			local function lit(parent, color, range, brightness, shadows)
				local l = Instance.new("PointLight")
				l.Color, l.Range, l.Brightness, l.Shadows = color, math.min(range * 1.6, 60), brightness, shadows or false -- (heat throws its light far down here)
				l.Parent = parent
				addFlicker(l)
			end
			-- what is laid on freshly cut terrain (found by a ray down onto it) is placed a moment after the build: until the
			-- engine catches up with the new terrain, a ray finds nothing there (see the task.spawn at the end)
			local later = {}
			-- an invisible anchor for fire and particles
			local function ghost(x, y, z, sx, sy, sz)
				return part({ Name = "Fx", Size = Vector3.new(sx or 1, sy or 1, sz or 1), CFrame = CFrame.new(x, y, z), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = under })
			end
			local function blaze(x, y, z, size)
				local f = Instance.new("Fire")
				f.Size, f.Heat = size, size
				f.Color, f.SecondaryColor = Color3.fromRGB(255, 110, 30), Color3.fromRGB(110, 14, 8)
				f.Parent = ghost(x, y, z)
				return f.Parent
			end
			local function pile(cx, cz, rad, n, smax)
				for _ = 1, n do
					local a, r, s = R(0, 6.28), R(0, rad), R(smax * 0.4, smax)
					tilt(part({ Name = "Rubble", Size = Vector3.new(s, s * R(0.6, 1), s * R(0.8, 1.2)), CFrame = CFrame.new(cx + math.cos(a) * r, -110 + (1 - r / (rad + 1)) * smax * 0.8 + s * 0.3, cz + math.sin(a) * r), Material = MAT.Rock, Color = dark(), Parent = under }), 0.6)
				end
			end

			-- THE PIT: the ground east of the breach (x 88..92 is its wall) blown into a bowl, all of it terrain: scorched basalt
			-- shading into glowing cracked lava, a throat at the bottom, and only small things laid on it, each set on the real
			-- surface (a ray down onto the terrain): ember chips, flames, charred stones, a crown of leaning shards.
			local PX, PY, PZ = 108, -20, -32
			local T = workspace.Terrain
			T:FillBall(Vector3.new(PX, -4, PZ), 18, Enum.Material.Air)
			T:FillBall(Vector3.new(PX, -22, PZ), 6, Enum.Material.Air)
			do -- voxel by voxel (a Fill this narrow leaves half-full voxels): rock under the thin ground (above the keep's cut,
				-- y -50), the throat cut down into it (y -44..-20), then paint: lava at the bottom, mottled lava and basalt up
				-- the slope, scorch fading out past the rim
				local reg = Region3.new(Vector3.new(PX - 28, -52, PZ - 28), Vector3.new(PX + 28, 0, PZ + 28)):ExpandToGrid(4)
				local mats, occ = T:ReadVoxels(reg, 4)
				local o = reg.CFrame.Position - reg.Size / 2
				for i = 1, #mats do
					for j = 1, #mats[i] do
						for k = 1, #mats[i][j] do
							local d0, y = math.sqrt((o.X + (i - 0.5) * 4 - PX) ^ 2 + (o.Z + (k - 0.5) * 4 - PZ) ^ 2), o.Y + (j - 0.5) * 4
							if d0 < 12 and y < -36 then
								occ[i][j][k] = 1
							end
							if d0 < 6.5 and y > -44 and y < -20 then
								occ[i][j][k] = 0
							end
							if occ[i][j][k] > 0 then
								local d = d0 + R(-2, 2)
								if d < 10 then
									mats[i][j][k] = MAT.CrackedLava
								elseif d < 15 then
									mats[i][j][k] = ur:NextNumber() < 0.4 and MAT.CrackedLava or MAT.Basalt
								elseif d < 24 and ur:NextNumber() < (24 - d) / 9 then
									mats[i][j][k] = MAT.Basalt
								end
							end
						end
					end
				end
				T:WriteVoxels(reg, 4, mats, occ)
			end
			local onlyTerrain = RaycastParams.new()
			onlyTerrain.FilterType = Enum.RaycastFilterType.Include
			onlyTerrain.FilterDescendantsInstances = { T }
			-- the surface at angle a (0 = east, away from the wing), r out from the centre: position and normal, or nil
			local function ground(a, r)
				return workspace:Raycast(Vector3.new(PX + math.cos(a) * r, 10, PZ + math.sin(a) * r), Vector3.new(0, -60, 0), onlyTerrain)
			end
			local function anyAngle()
				local a = R(-2.5, 2.5) -- (never the wing's side, nor the line of the leap)
				return a
			end
			-- flames on the slope and down the throat, the throat's glow, smoke and sparks out of it
			table.insert(later, function()
				for _ = 1, 12 do
					local hit = ground(R(0, 6.28), R(5, 12))
					if hit then
						blaze(hit.Position.X, hit.Position.Y + 0.6, hit.Position.Z, R(4, 9))
					end
				end
			end)
			for k = 1, 4 do
				local a = k / 4 * math.pi * 2
				blaze(PX + math.cos(a) * 2.5, -24 - k * 2.5, PZ + math.sin(a) * 2.5, 7)
			end
			local throat = ghost(PX, -30, PZ)
			lit(throat, EMBER, 40, 3, true)
			local column = ghost(PX, -22, PZ)
			lit(column, Color3.fromRGB(255, 96, 32), 60, 2.2)
			local smoke = Instance.new("ParticleEmitter")
			smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
			smoke.Color = ColorSequence.new(Color3.fromRGB(46, 40, 38))
			smoke.Size = NumberSequence.new(4, 16)
			smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
			smoke.Lifetime = NumberRange.new(5, 8)
			smoke.Rate = 10
			smoke.Speed = NumberRange.new(6, 10)
			smoke.SpreadAngle = Vector2.new(12, 12)
			smoke.Parent = column
			local sparks = Instance.new("ParticleEmitter")
			sparks.Color = ColorSequence.new(EMBER)
			sparks.LightEmission = 1
			sparks.Size = NumberSequence.new(0.35, 0)
			sparks.Lifetime = NumberRange.new(2, 4)
			sparks.Rate = 30
			sparks.Speed = NumberRange.new(5, 14)
			sparks.SpreadAngle = Vector2.new(35, 35)
			sparks.Acceleration = Vector3.new(0, 3, 0)
			sparks.Parent = throat
			local haze = ghost(PX, -17, PZ, 22, 1, 22) -- (low smoke drifting over the bowl)
			local drift = smoke:Clone()
			drift.Size = NumberSequence.new(3, 8)
			drift.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.75), NumberSequenceKeypoint.new(1, 1) })
			drift.Speed = NumberRange.new(0.5, 1.5)
			drift.Rate = 6
			drift.SpreadAngle = Vector2.new(60, 60)
			drift.Parent = haze
			-- ember chips and charred stones strewn over the slope (strew: one, lying on the surface a ray found)
			local function strew(hit, glowing)
				local s = R(0.25, 0.8)
				local glow = ur:NextNumber() < (glowing or 0.6)
				local axis = Vector3.yAxis:Cross(hit.Normal) -- (lying on the slope: up turned to the surface's normal)
				local flat = axis.Magnitude > 1e-3 and CFrame.fromAxisAngle(axis.Unit, math.asin(math.min(axis.Magnitude, 1))) or CFrame.identity
				local cf = CFrame.new(hit.Position) * flat * CFrame.Angles(R(-0.3, 0.3), R(0, 6.28), R(-0.3, 0.3))
				local size = glow and Vector3.new(s, s * 0.4, s * R(0.6, 1.4)) or Vector3.new(s * 2, s * 1.4, s * R(1.6, 2.6))
				part({ Name = glow and "PitEmber" or "PitCinder", Size = size, CFrame = cf, Material = glow and MAT.Neon or MAT.Basalt, Color = glow and EMBER:Lerp(Color3.fromRGB(150, 30, 8), ur:NextNumber()) or dark(), CanCollide = false, Parent = under })
			end
			table.insert(later, function()
				for _ = 1, 70 do
					local hit = ground(R(0, 6.28), R(3, 15))
					if hit then
						strew(hit)
					end
				end
			end)
			table.insert(later, function()
				for _ = 1, 12 do -- half-buried charred boulders on the rim
					local hit = ground(anyAngle(), R(13, 21))
					if hit then
						local s = R(2, 4.5)
						tilt(part({ Name = "PitRock", Size = Vector3.new(s, s * R(0.6, 1), s * R(0.8, 1.3)), CFrame = CFrame.new(hit.Position + Vector3.new(0, s * 0.15, 0)), Material = MAT.Basalt, Color = dark(), Parent = under }), 0.5)
					end
				end
				-- shards: clusters round the rim leaning out (blown outward), and a few on the slope bent in over the throat;
				-- some burn at the tip
				local function shard(hit, h, lean, burning)
					local out = Vector3.new(hit.Position.X - PX, 0, hit.Position.Z - PZ).Unit
					local up = CFrame.fromAxisAngle(Vector3.yAxis:Cross(out).Unit, lean) -- (+lean: top tips away from the pit)
					local w = R(0.8, 2) * (h / 8 + 0.5)
					local cf = CFrame.new(hit.Position) * up * CFrame.Angles(R(-0.12, 0.12), R(0, 6.28), R(-0.12, 0.12)) * CFrame.new(0, h / 2 - 1.2, 0)
					part({ Name = "PitShard", Size = Vector3.new(w, h, w * R(0.5, 0.9)), CFrame = cf, Material = ur:NextNumber() < 0.6 and MAT.Basalt or MAT.Slate, Color = dark():Lerp(Color3.fromRGB(44, 36, 34), ur:NextNumber() * 0.5), Parent = under })
					local tip = cf * CFrame.new(0, h / 2 - 0.4, 0) * CFrame.Angles(0, 0, 0.55)
					part({ Name = "PitShardTip", Size = Vector3.new(w * 0.7, h * 0.22, w * 0.45), CFrame = tip, Material = MAT.Basalt, Color = DEEP, Parent = under })
					if burning then
						local f = blaze(tip.X, tip.Y + 0.6, tip.Z, R(3, 6))
						if ur:NextNumber() < 0.5 then
							lit(f, EMBER, 16, 1)
						end
					end
				end
				for c = 1, 15 do
					local a, r = anyAngle(), R(14, 22)
					for _ = 1, ur:NextInteger(2, 4) do
						local hit = ground(a + R(-0.08, 0.08), r + R(-1.5, 1.5))
						if hit then
							shard(hit, R(3, 12), R(0.15, 0.5), c % 3 == 0 and ur:NextNumber() < 0.6)
						end
					end
				end
				for _ = 1, 8 do
					local hit = ground(anyAngle(), R(8, 12))
					if hit then
						shard(hit, R(3, 7), -R(0.3, 0.6), ur:NextNumber() < 0.3)
					end
				end
			end)

			-- THE ROOM: the buried room the pit happened to break into, kept quiet: x 112..172, z -30..20, floor y -110, ceiling
			-- y -86; the heap under the broken ceiling, four columns (one fallen), low lava channels along the long walls, a few
			-- braziers. A door in its east wall leads round a corner to the fortress hall below.
			local X1, X2, Z1, Z2, FY, CY = 112, 172, -30, 20, -110, -86
			local HX, HZ = 128, -5 -- the broken ceiling's hole
			T:FillBlock(CFrame.new((X1 + X2) / 2, (FY + CY) / 2 + 10, (Z1 + Z2) / 2), Vector3.new(X2 - X1 + 16, CY - FY + 40, Z2 - Z1 + 16), Enum.Material.Air) -- (the ground the room and its shaft are cut from)
			T:FillBlock(CFrame.new(198, -88, 43), Vector3.new(80, 60, 118), Enum.Material.Air) -- (and the corridor and the hall)
			local function brazier(x, z, size, bright, tall)
				local h = tall or 4
				U(x - 1, FY, z - 1, x + 1, FY + h, z + 1, MAT.Basalt, DEEP, "Pedestal")
				U(x - 1.7, FY + h, z - 1.7, x + 1.7, FY + h + 0.8, z + 1.7, MAT.Metal, Color3.fromRGB(26, 22, 22), "Bowl")
				lit(blaze(x, FY + h + 1.6, z, size), EMBER, 30, bright)
			end
			local function column(x, z, top, broken, hw) -- (hw: the shaft's half-width, 2 by default)
				hw = hw or 2
				local b = hw + 0.6
				U(x - b, FY, z - b, x + b, FY + 1, z + b, MAT.Basalt, DEEP, "ColumnBase")
				local h = broken and R(7, 12) or top - FY - 2.2
				U(x - hw, FY + 1, z - hw, x + hw, FY + 1 + h, z + hw, MAT.Basalt, ROCK, "Column")
				if broken then
					tilt(part({ Name = "FallenDrum", Size = Vector3.new(hw * 2, hw * 2, R(7, 10)), CFrame = CFrame.new(x + R(1.5, 2.5) * hw, FY + hw, z + R(-2, 2)) * CFrame.Angles(0, R(-0.6, 0.6), 0), Material = MAT.Basalt, Color = ROCK, Parent = under }), 0)
					pile(x, z, hw * 2, 5, 2.5)
				else
					U(x - b, top - 1.2, z - b, x + b, top, z + b, MAT.Basalt, DEEP, "ColumnCap")
				end
			end
			U(X1 - 2, FY - 2, Z1 - 2, X2 + 2, FY, Z2 + 2, MAT.Slate, DEEP, "Floor")
			U(X1 - 2, FY, Z1 - 2, X1, CY + 2, Z2 + 2, MAT.Rock, ROCK, "Wall")
			U(X2, FY, Z1 - 2, X2 + 2, CY + 2, HZ - 4, MAT.Rock, ROCK, "Wall") -- (the east wall, round its door: z -9..-1, 12 high)
			U(X2, FY, HZ + 4, X2 + 2, CY + 2, Z2 + 2, MAT.Rock, ROCK, "Wall")
			U(X2, FY + 12, HZ - 4, X2 + 2, CY + 2, HZ + 4, MAT.Rock, ROCK, "Wall")
			U(X1, FY, Z1 - 2, X2, CY + 2, Z1, MAT.Rock, ROCK, "Wall")
			U(X1, FY, Z2, X2, CY + 2, Z2 + 2, MAT.Rock, ROCK, "Wall")
			U(X1, CY, Z1, HX - 8, CY + 2, Z2, MAT.Rock, DEEP, "Ceiling")
			U(HX + 8, CY, Z1, X2, CY + 2, Z2, MAT.Rock, DEEP, "Ceiling")
			U(HX - 8, CY, Z1, HX + 8, CY + 2, HZ - 8, MAT.Rock, DEEP, "Ceiling")
			U(HX - 8, CY, HZ + 8, HX + 8, CY + 2, Z2, MAT.Rock, DEEP, "Ceiling")
			-- the hole's shaft, capped above (no sky); the glow on the heap is the light below
			for _, w in ipairs({ { -8, -8, -7, 8 }, { 7, -8, 8, 8 }, { -8, -8, 8, -7 }, { -8, 7, 8, 8 } }) do
				U(HX + w[1], CY, HZ + w[2], HX + w[3], CY + 40, HZ + w[4], MAT.Rock, DEEP, "Shaft")
			end
			U(HX - 8, CY + 40, HZ - 8, HX + 8, CY + 41, HZ + 8, MAT.Rock, DEEP, "ShaftCap")
			local rain = ghost(HX, CY, HZ, 14, 1, 14)
			local ember = Instance.new("ParticleEmitter")
			ember.EmissionDirection = Enum.NormalId.Bottom
			ember.Color = ColorSequence.new(EMBER)
			ember.LightEmission = 1
			ember.Size = NumberSequence.new(0.3, 0)
			ember.Lifetime = NumberRange.new(3, 5)
			ember.Rate = 8
			ember.Speed = NumberRange.new(2, 5)
			ember.Acceleration = Vector3.new(0, -7, 0)
			ember.Parent = rain
			lit(rain, Color3.fromRGB(255, 110, 40), 55, 1.5, true)
			pile(HX, HZ, 7, 22, 5)
			pile(116, 14, 4, 6, 3) -- (and older falls in the corners)
			pile(116, -24, 3, 5, 2.5)
			column(146, HZ - 10, CY)
			column(160, HZ - 10, CY)
			column(146, HZ + 10, CY)
			column(160, HZ + 10, CY, true)
			-- jagged ceiling teeth (short: clear of a standing head) and rock heaved out of the walls
			for _ = 1, 22 do
				local x, z, s = R(X1 + 3, X2 - 3), R(Z1 + 3, Z2 - 3), R(1.5, 4.5)
				if math.abs(x - HX) > 11 or math.abs(z - HZ) > 11 then
					local h = s * R(1, 2.2)
					tilt(part({ Name = "Tooth", Size = Vector3.new(s, h, s * R(0.8, 1.3)), CFrame = CFrame.new(x, CY - h / 2 + 0.5, z), Material = MAT.Rock, Color = dark(), Parent = under }), 0.2)
				end
			end
			for _ = 1, 34 do
				local w, h, d = R(3, 8), R(4, 12), R(1.2, 3)
				local y = ur:NextNumber() < 0.5 and CY - h / 2 + 1 or FY + h / 2 - 1
				local side, along = ur:NextInteger(1, 4), R(0, 1)
				local c
				if side == 1 then
					c = CFrame.new(X1 + 5 + along * (X2 - X1 - 10), y, Z1 + d / 2 - 0.5)
				elseif side == 2 then
					c = CFrame.new(X1 + 5 + along * (X2 - X1 - 10), y, Z2 - d / 2 + 0.5)
				elseif side == 3 then
					c = CFrame.new(X1 + d / 2 - 0.5, y, Z1 + 5 + along * (Z2 - Z1 - 10)) * CFrame.Angles(0, math.pi / 2, 0)
				else
					c = CFrame.new(X2 - d / 2 + 0.5, y, Z1 + 5 + along * (Z2 - Z1 - 10)) * CFrame.Angles(0, math.pi / 2, 0)
				end
				if side ~= 4 or math.abs(c.Z - HZ) > 8 then -- (the door stays clear)
					part({ Name = "CaveRock", Size = Vector3.new(w, h, d), CFrame = c * CFrame.Angles(R(-0.12, 0.12), R(-0.2, 0.2), R(-0.12, 0.12)), Material = MAT.Rock, Color = dark(), Parent = under })
				end
			end
			-- low lava channels along the long walls (terrain, as in the pit), quiet here: only cinders on them, a dull glow
			for _, z in ipairs({ -22, 12 }) do
				T:FillBlock(CFrame.new(154, FY - 0.65, z), Vector3.new(28, 2.7, 6), MAT.CrackedLava) -- (y -112..-109.3: its voxel row part-full, so the surface stands ~0.7 above the floor)
				local function edge(x, zz)
					local s = R(1.2, 2.4)
					tilt(part({ Name = "LavaEdge", Size = Vector3.new(s * R(1, 1.6), s * R(0.6, 1), s), CFrame = CFrame.new(x, FY + s * 0.3, zz), Material = MAT.Basalt, Color = dark(), Parent = under }), 0.35)
				end
				for x = 140, 168, 2.2 do
					edge(x + R(-0.4, 0.4), z - 3.5 - R(-0.3, 0.4))
					edge(x + R(-0.4, 0.4), z + 3.5 + R(-0.3, 0.4))
				end
				for zz = z - 2, z + 2, 2 do
					edge(139 + R(-0.3, 0.3), zz)
					edge(169 + R(-0.3, 0.3), zz)
				end
				table.insert(later, function()
					for _ = 1, 14 do
						local hit = workspace:Raycast(Vector3.new(R(141, 167), FY + 10, z + R(-2.5, 2.5)), Vector3.new(0, -16, 0), onlyTerrain)
						if hit then
							strew(hit, 0)
						end
					end
				end)
				lit(ghost(147, FY + 2, z), EMBER, 24, 0.8)
				lit(ghost(161, FY + 2, z), EMBER, 24, 0.8)
			end
			for _, b in ipairs({ { 146, Z1 + 1.8 }, { 162, Z1 + 1.8 }, { 146, Z2 - 1.8 }, { 162, Z2 - 1.8 }, { X2 - 1.8, HZ - 9 }, { X2 - 1.8, HZ + 9 } }) do
				brazier(b[1], b[2], 7, 1)
			end

			-- sunk lava, the moat's way: terrain lava and crust with its surface near y -115, five below the floor (too deep to
			-- climb out of: it takes you, init.server), lit far brighter than it looks, heat and sparks off it. x1..x2, z1..z2 on
			-- the 4-stud grid; each one's box goes in deadly (info.Underfire.Moats). fierce (the gutters): little crust, fire of
			-- every size and heat bunched and overlapping along it, tongues of flame off all of it, thick sparks, and a jagged rim
			-- of shards leaning out over both edges - plainly death. clear: a stretch {from, to} along it the rim leaves open
			-- (where a bridge crosses)
			local deadly = {}
			local function sunk(x1, z1, x2, z2, fierce, clear)
				local reg = Region3.new(Vector3.new(x1, -124, z1), Vector3.new(x2, -116, z2)):ExpandToGrid(4)
				local mats, occ = T:ReadVoxels(reg, 4)
				for i = 1, #mats do
					for j = 1, #mats[i] do
						for k = 1, #mats[i][j] do
							mats[i][j][k] = ur:NextNumber() < (fierce and 0.9 or 0.55) and MAT.CrackedLava or MAT.Basalt
							occ[i][j][k] = j == 1 and 1 or 0.7
						end
					end
				end
				T:WriteVoxels(reg, 4, mats, occ)
				local alongX = x2 - x1 >= z2 - z1
				local len = alongX and x2 - x1 or z2 - z1
				local cx, cz = (x1 + x2) / 2, (z1 + z2) / 2
				local function at(d)
					return alongX and x1 + d or cx, alongX and cz or z1 + d
				end
				for d = 4, math.max(len - 4, 4), 10 do
					local x, z = at(d)
					lit(ghost(x, FY - 1, z), Color3.fromRGB(255, 96, 36), 40, fierce and 3 or 2.4)
				end
				if fierce then
					local across = (alongX and z2 - z1 or x2 - x1) / 2
					local function spot(d, o) -- d along it, o across from its centre line
						if alongX then
							return x1 + d, cz + o
						end
						return cx + o, z1 + d
					end
					local d = R(0.5, 3)
					while d < len - 0.5 do -- (bunches of one or two, at no set spacing, anywhere across it)
						for _ = 1, ur:NextInteger(1, 2) do
							local x, z = spot(d + R(-1.5, 1.5), R(0.6 - across, across - 0.6))
							local f = Instance.new("Fire")
							f.Size, f.Heat = R(3, 12), R(3, 18)
							f.Color = Color3.fromRGB(255, 110, 30):Lerp(Color3.fromRGB(255, 60, 15), ur:NextNumber())
							f.SecondaryColor = Color3.fromRGB(110, 14, 8):Lerp(Color3.fromRGB(60, 8, 4), ur:NextNumber())
							f.Parent = ghost(x, FY - R(2.5, 4.5), z)
						end
						d += R(3, 9)
					end
					local tongues = Instance.new("ParticleEmitter")
					tongues.Texture = "rbxasset://textures/particles/fire_main.dds"
					tongues.Color = ColorSequence.new(Color3.fromRGB(255, 140, 50), Color3.fromRGB(200, 40, 10))
					tongues.LightEmission = 1
					tongues.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5, 1), NumberSequenceKeypoint.new(0.4, 3, 2), NumberSequenceKeypoint.new(1, 0.5, 0.5) })
					tongues.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(0.3, 0.2), NumberSequenceKeypoint.new(1, 1) })
					tongues.Lifetime = NumberRange.new(0.5, 1.3)
					tongues.Speed = NumberRange.new(4, 11)
					tongues.SpreadAngle = Vector2.new(8, 8)
					tongues.Rotation = NumberRange.new(0, 360)
					tongues.RotSpeed = NumberRange.new(-40, 40)
					tongues.Rate = (x2 - x1) * (z2 - z1) / 6
					tongues.Parent = ghost(cx, FY - 4, cz, math.max(x2 - x1 - 1, 1), 1, math.max(z2 - z1 - 1, 1))
					for _, side in ipairs({ -1, 1 }) do -- the rim: shards leaning in over the lava from both edges
						local e = R(0, 1.5)
						while e < len do
							if not (clear and e > clear[1] and e < clear[2]) then
								local h, w = R(1, 3.5), R(0.7, 1.8)
								local x, z = spot(e, side * (across - R(-0.4, 0.5)))
								local lean = alongX and CFrame.Angles(-side * R(0.25, 0.6), 0, 0) or CFrame.Angles(0, 0, side * R(0.25, 0.6))
								part({ Name = "RimShard", Size = Vector3.new(w, h, w * R(0.6, 1.2)), CFrame = CFrame.new(x, FY - 0.6, z) * lean * CFrame.Angles(0, R(0, 6.28), 0) * CFrame.new(0, h / 2, 0), Material = ur:NextNumber() < 0.6 and MAT.Basalt or MAT.Slate, Color = dark(), Parent = under })
							end
							e += R(1, 2.6)
						end
					end
				end
				local heat = drift:Clone()
				heat.Parent = ghost(cx, FY - 1, cz, math.max(x2 - x1 - 4, 1), 1, math.max(z2 - z1 - 4, 1))
				local motes = sparks:Clone()
				motes.Rate = math.max(2, len / (fierce and 2 or 8))
				motes.SpreadAngle = Vector2.new(10, 10)
				motes.Parent = heat.Parent
				table.insert(deadly, { MinX = x1, MaxX = x2, MinZ = z1, MaxZ = z2, MaxY = FY + 1.5 })
			end
			local function merlons(x1, x2, z, y)
				for x = x1 + 0.8, x2 - 0.8, 3.2 do
					U(x - 0.8, y, z, x + 0.8, y + 2.2, z + 1.4, MAT.Basalt, DEEP, "Merlon")
				end
			end

			-- AROUND THE CORNER: no hallway but a winding gallery of the fortress, the same dark basalt, columns, buttresses and
			-- sunk lava: east from the door along a lava gutter and a colonnade, round the end of a battlemented wall (a squat
			-- tower on its end), back west along a second gutter at its foot, and south through the hall's mouth (x 180..196).
			-- Inside x 174..224, z -18..30, ceiling y -84; the wall between the two runs is x 174..208, z 2..12, open above.
			local GT = FY + 26
			T:FillBlock(CFrame.new(199, -88, 6), Vector3.new(58, 60, 56), Enum.Material.Air)
			-- the floor, round the gutters (z -18..-14 along the first run, x 176..220; z 12..16 at the wall's foot, x 180..204)
			U(172, FY - 2, -14, 226, FY, 12, MAT.Slate, DEEP, "Floor")
			U(172, FY - 2, -18, 176, FY, -14, MAT.Slate, DEEP, "Floor")
			U(220, FY - 2, -18, 226, FY, -14, MAT.Slate, DEEP, "Floor")
			U(172, FY - 2, 12, 180, FY, 16, MAT.Slate, DEEP, "Floor")
			U(204, FY - 2, 12, 226, FY, 16, MAT.Slate, DEEP, "Floor")
			U(172, FY - 2, 16, 226, FY, 30, MAT.Slate, DEEP, "Floor")
			-- outer walls (the north one down past the gutter's depth), the block west of the second run, the ceiling
			U(172, FY - 10, -20, 226, GT + 2, -18, MAT.Rock, ROCK, "Wall")
			U(224, FY, -18, 226, GT + 2, 30, MAT.Rock, ROCK, "Wall")
			U(174, FY, 12, 180, GT + 2, 30, MAT.Rock, ROCK, "Wall")
			U(172, GT, -20, 226, GT + 2, 30, MAT.Rock, DEEP, "Ceiling")
			for x = 182, 218, 12 do -- buttresses rising out of the gutter, and down the east wall
				U(x - 1.5, FY - 8, -18, x + 1.5, GT, -16.6, MAT.Basalt, DEEP, "Buttress")
			end
			for z = -6, 26, 16 do
				U(222.4, FY, z - 1.5, 224, GT, z + 1.5, MAT.Basalt, DEEP, "Buttress")
			end
			-- the gutters: beds, banks, ends, lava
			U(176, FY - 10, -18, 220, FY - 8, -14, MAT.Basalt, DEEP, "MoatBed")
			U(176, FY - 8, -14, 220, FY, -13, MAT.Basalt, DEEP, "MoatBank")
			U(175, FY - 8, -18, 176, FY, -14, MAT.Basalt, DEEP, "MoatBank")
			U(220, FY - 8, -18, 221, FY, -14, MAT.Basalt, DEEP, "MoatBank")
			sunk(176, -20, 220, -12, true)
			U(180, FY - 10, 12, 204, FY - 8, 16, MAT.Basalt, DEEP, "MoatBed")
			U(180, FY - 8, 11, 204, FY, 12, MAT.Basalt, DEEP, "MoatBank")
			U(180, FY - 8, 16, 204, FY, 17, MAT.Basalt, DEEP, "MoatBank")
			U(179, FY - 8, 12, 180, FY, 16, MAT.Basalt, DEEP, "MoatBank")
			U(204, FY - 8, 12, 205, FY, 16, MAT.Basalt, DEEP, "MoatBank")
			sunk(180, 12, 204, 16, true)
			-- the wall between the runs, battlemented both sides, a squat tower on its end
			U(174, FY, 2, 200, FY + 16, 12, MAT.Basalt, ROCK, "Curtain")
			merlons(174, 200, 2, FY + 16)
			merlons(174, 200, 10.6, FY + 16)
			U(200, FY, 1, 208, FY + 22, 13, MAT.Basalt, ROCK, "Tower")
			merlons(200, 208, 1, FY + 22)
			merlons(200, 208, 11.6, FY + 22)
			U(203.7, FY + 12, 0.9, 204.3, FY + 17, 1, MAT.SmoothPlastic, Color3.fromRGB(4, 3, 3), "ArrowSlit")
			-- a colonnade along the first gutter; two more columns by the hall's mouth; braziers at the turns
			for _, x in ipairs({ 184, 196, 208 }) do
				column(x, -11, GT)
			end
			column(206, 26, GT)
			column(216, 26, GT)
			for _, b in ipairs({ { 178, -11 }, { 221, -11 }, { 221, 8 }, { 221, 27 }, { 183, 27 } }) do
				brazier(b[1], b[2], 9, 1.4, 5)
			end
			for _ = 1, 12 do
				local x, z, s = R(176, 222), R(-16, 28), R(2, 4.5)
				local h = s * R(1, 2.2)
				tilt(part({ Name = "Tooth", Size = Vector3.new(s, h, s * R(0.8, 1.3)), CFrame = CFrame.new(x, GT - h / 2 + 0.5, z), Material = MAT.Rock, Color = dark(), Parent = under }), 0.2)
			end

			-- THE FORTRESS HALL: x 164..232, z 32..96, ceiling y -74. Columns either side of the way in, a moat of dull lava
			-- across the hall (half of it crusted over, yet throwing far more light than it looks like it should), one bridge,
			-- and beyond it a battlemented wall with two towers and a gate, its portcullis half down, choked with fallen rock
			local AX1, AX2, AZ1, AZ2, TOP = 164, 232, 32, 96, FY + 36
			local MZ1, MZ2 = 54, 68 -- the moat
			U(AX1 - 2, FY - 2, AZ1 - 2, AX2 + 2, FY, MZ1, MAT.Slate, DEEP, "Floor")
			U(AX1 - 2, FY - 2, MZ2, AX2 + 2, FY, AZ2 + 2, MAT.Slate, DEEP, "Floor")
			U(AX1 - 2, FY, AZ1 - 2, 180, TOP + 2, AZ1, MAT.Rock, ROCK, "Wall") -- (round its mouth from the gallery: x 180..196, 18 high)
			U(196, FY, AZ1 - 2, AX2 + 2, TOP + 2, AZ1, MAT.Rock, ROCK, "Wall")
			U(180, FY + 18, AZ1 - 2, 196, TOP + 2, AZ1, MAT.Rock, ROCK, "Wall")
			U(AX1 - 2, FY, AZ1, AX1, TOP + 2, 38, MAT.Rock, ROCK, "Wall") -- (round the door west: z 38..48, 16 high)
			U(AX1 - 2, FY, 48, AX1, TOP + 2, AZ2 + 2, MAT.Rock, ROCK, "Wall")
			U(AX1 - 2, FY + 16, 38, AX1, TOP + 2, 48, MAT.Rock, ROCK, "Wall")
			U(AX2, FY, AZ1, AX2 + 2, TOP + 2, 70, MAT.Rock, ROCK, "Wall") -- (round the door east, off the courtyard: z 70..84, 20 high)
			U(AX2, FY, 84, AX2 + 2, TOP + 2, AZ2 + 2, MAT.Rock, ROCK, "Wall")
			U(AX2, FY + 20, 70, AX2 + 2, TOP + 2, 84, MAT.Rock, ROCK, "Wall")
			U(AX1, FY, AZ2, AX2, TOP + 2, AZ2 + 2, MAT.Rock, ROCK, "Wall")
			U(AX1, TOP, AZ1, AX2, TOP + 2, AZ2, MAT.Rock, DEEP, "Ceiling")
			for z = AZ1 + 8, AZ2 - 4, 12 do -- buttresses up the side walls (not across the doors)
				if z < 36 or z > 50 then
					U(AX1, FY, z - 1.5, AX1 + 2, TOP, z + 1.5, MAT.Basalt, DEEP, "Buttress")
				end
				if z < 70 or z > 86 then
					U(AX2 - 2, FY, z - 1.5, AX2, TOP, z + 1.5, MAT.Basalt, DEEP, "Buttress")
				end
			end
			for _ = 1, 18 do
				local x, z, s = R(AX1 + 3, AX2 - 3), R(AZ1 + 3, AZ2 - 3), R(2, 5)
				local h = s * R(1, 2.4)
				tilt(part({ Name = "Tooth", Size = Vector3.new(s, h, s * R(0.8, 1.3)), CFrame = CFrame.new(x, TOP - h / 2 + 0.5, z), Material = MAT.Rock, Color = dark(), Parent = under }), 0.2)
			end
			column(179, 40, TOP)
			column(197, 40, TOP)
			column(179, 49, TOP)
			column(197, 49, TOP)
			brazier(170, 38, 10, 1.6, 5)
			brazier(226, 38, 10, 1.6, 5)
			-- the moat: banks and a bed of stone, lava (terrain) sunk in it, mottled with dark crust
			U(AX1, FY - 8, MZ1 - 1, AX2, FY, MZ1, MAT.Basalt, DEEP, "MoatBank")
			U(AX1, FY - 8, MZ2, AX2, FY, MZ2 + 1, MAT.Basalt, DEEP, "MoatBank")
			U(AX1, FY - 10, MZ1, AX2, FY - 8, MZ2, MAT.Basalt, DEEP, "MoatBed")
			sunk(AX1, MZ1 - 2, AX2, MZ2)
			-- the bridge, on one pier, with low parapets
			U(184, FY - 1.5, MZ1 - 2, 192, FY, MZ2 + 2, MAT.Basalt, ROCK, "Bridge")
			U(185, FY - 8, 59, 191, FY - 1.5, 63, MAT.Basalt, DEEP, "BridgePier")
			U(183, FY - 1.5, MZ1 - 2, 184, FY + 2.5, MZ2 + 2, MAT.Basalt, DEEP, "Parapet")
			U(192, FY - 1.5, MZ1 - 2, 193, FY + 2.5, MZ2 + 2, MAT.Basalt, DEEP, "Parapet")
			-- the wall beyond: curtain, two towers, battlements, the gate between
			U(AX1, FY, 84, 172, FY + 18, 88, MAT.Basalt, ROCK, "Curtain")
			U(204, FY, 84, AX2, FY + 18, 88, MAT.Basalt, ROCK, "Curtain")
			merlons(AX1, 172, 84, FY + 18)
			merlons(204, AX2, 84, FY + 18)
			for _, x1 in ipairs({ 172, 194 }) do
				U(x1, FY, 80, x1 + 10, FY + 26, 90, MAT.Basalt, ROCK, "Tower")
				merlons(x1, x1 + 10, 80, FY + 26)
				U(x1 + 4.7, FY + 14, 79.9, x1 + 5.3, FY + 19, 80, MAT.SmoothPlastic, Color3.fromRGB(4, 3, 3), "ArrowSlit")
			end
			U(182, FY + 14, 84, 194, FY + 18, 88, MAT.Basalt, DEEP, "GateLintel")
			merlons(182, 194, 84, FY + 18)
			for x = 183, 193, 2 do
				U(x - 0.2, FY + 7, 85.8, x + 0.2, FY + 14, 86.2, MAT.Metal, Color3.fromRGB(30, 28, 28), "Portcullis")
			end
			for _, y in ipairs({ FY + 8, FY + 11 }) do
				U(182.5, y, 85.8, 193.5, y + 0.4, 86.2, MAT.Metal, Color3.fromRGB(30, 28, 28), "Portcullis")
			end
			pile(188, 92, 4, 14, 4.5) -- (the gate's passage, caved in)
			brazier(178, 76, 9, 1.4, 5)
			brazier(198, 76, 9, 1.4, 5)

			task.spawn(function()
				for _ = 1, 50 do -- (until a ray finds the pit's floor; 10 s at most)
					if workspace:Raycast(Vector3.new(PX, 10, PZ), Vector3.new(0, -80, 0), onlyTerrain) then
						break
					end
					task.wait(0.2)
				end
				for _, f in ipairs(later) do
					f()
				end
			end)
			info.Underfire = {
				Gate = { MinX = 86, MaxX = 88.8, MinZ = -36.5, MaxZ = -27.5 }, -- (the breach's inner lip)
				Pit = Vector3.new(PX, PY, PZ),
				Landing = CFrame.lookAt(Vector3.new(141, FY + 3.2, HZ), Vector3.new(170, FY + 3.2, HZ)),
				Zone = { Name = "Maw of Pyralis", MinX = X1 - 4, MaxX = X2 + 4, MinZ = Z1 - 4, MaxZ = Z2 + 4, MinY = FY - 10, MaxY = CY + 45 },
				Moats = deadly, -- (down in the lava: it takes you, as the chasm does)
			}
			table.insert(info.Zones, 1, info.Underfire.Zone)
			-- the Cinder Knights (Characters/Cinder.lua) keeping the fortress, all the way to the arena's gate (none in it)
			for _, k in ipairs({
				{ 164, 8, 141, -5 }, -- the room: by its east door, toward the landing
				{ 214, -10, 190, -10 }, -- the gallery's first run
				{ 200, 22, 220, 22 }, -- its second run, at the wall's foot
				{ 198, 78, 198, 60 }, -- the hall, past the bridge
				{ 141, 70, 141, 44 }, -- the way west
				{ 130, 114, 140, 96 }, -- the side chamber, by its chest
				{ 262, 78, 240, 78 }, -- the way east
				{ 270, 110, 270, 92 }, -- its last stretch, before the arena
			}) do
				table.insert(info.EnemySpawns, { Type = "Cinder", CFrame = CFrame.lookAt(Vector3.new(k[1], FY + 3.2, k[2]), Vector3.new(k[3], FY + 3.2, k[4])) })
			end
			table.insert(info.Zones, 1, { Name = "Maw of Pyralis", MinX = X2, MaxX = AX2 + 4, MinZ = -24, MaxZ = AZ2 + 4, MinY = FY - 12, MaxY = TOP + 4 }) -- (the gallery and the fortress hall)
			-- THE BRANCHES off the fortress hall, the same fortress all through: west to a side chamber with a lava pit, and east
			-- by a great way to the arena. Their ground is cut away first (clear of the hall's moat, x 164..232).
			local PH = FY + 18 -- the passages' ceiling
			T:FillBlock(CFrame.new(140, -91, 79), Vector3.new(44, 62, 90), Enum.Material.Air) -- (x 118..162, z 34..124)
			local function teeth(x1, z1, x2, z2, top, n)
				for _ = 1, n do
					local s = R(1.5, 4)
					local h = s * R(1, 2.2)
					tilt(part({ Name = "Tooth", Size = Vector3.new(s, h, s * R(0.8, 1.3)), CFrame = CFrame.new(R(x1, x2), top - h / 2 + 0.5, R(z1, z2)), Material = MAT.Rock, Color = dark(), Parent = under }), 0.2)
				end
			end

			-- THE WAY WEST: through the hall's west wall (door z 38..48), west, then south into a side chamber
			-- (x 124..156, z 92..120) of four columns round a pit of lava
			U(134, FY - 2, 36, 162, FY, 92, MAT.Slate, DEEP, "Floor")
			U(134, PH, 36, 162, PH + 2, 92, MAT.Rock, DEEP, "Ceiling")
			U(134, FY, 36, 162, PH, 38, MAT.Rock, ROCK, "Wall")
			U(146, FY, 48, 162, PH, 50, MAT.Rock, ROCK, "Wall")
			U(134, FY, 38, 136, PH, 90, MAT.Rock, ROCK, "Wall")
			U(146, FY, 50, 148, PH, 90, MAT.Rock, ROCK, "Wall")
			for z = 60, 84, 12 do
				U(136, FY, z - 1.5, 137.4, PH, z + 1.5, MAT.Basalt, DEEP, "Buttress")
				U(144.6, FY, z - 1.5, 146, PH, z + 1.5, MAT.Basalt, DEEP, "Buttress")
			end
			brazier(139, 41, 8, 1.2, 5)
			teeth(137, 39, 160, 47, PH, 6)
			teeth(137, 50, 145, 88, PH, 6)
			local CH = FY + 24
			U(122, FY, 90, 136, CH, 92, MAT.Rock, ROCK, "Wall")
			U(146, FY, 90, 158, CH, 92, MAT.Rock, ROCK, "Wall")
			U(136, PH, 90, 146, CH, 92, MAT.Rock, ROCK, "Wall")
			U(122, FY, 120, 158, CH, 122, MAT.Rock, ROCK, "Wall")
			U(122, FY, 92, 124, CH, 120, MAT.Rock, ROCK, "Wall")
			U(156, FY, 92, 158, CH, 120, MAT.Rock, ROCK, "Wall")
			U(122, CH, 90, 158, CH + 2, 122, MAT.Rock, DEEP, "Ceiling")
			U(122, FY - 2, 92, 158, FY, 104, MAT.Slate, DEEP, "Floor") -- (round the pit: x 136..144, z 104..108)
			U(122, FY - 2, 108, 158, FY, 122, MAT.Slate, DEEP, "Floor")
			U(122, FY - 2, 104, 136, FY, 108, MAT.Slate, DEEP, "Floor")
			U(144, FY - 2, 104, 158, FY, 108, MAT.Slate, DEEP, "Floor")
			U(136, FY - 10, 104, 144, FY - 8, 108, MAT.Basalt, DEEP, "MoatBed")
			U(135, FY - 8, 103, 145, FY, 104, MAT.Basalt, DEEP, "MoatBank")
			U(135, FY - 8, 108, 145, FY, 109, MAT.Basalt, DEEP, "MoatBank")
			U(135, FY - 8, 104, 136, FY, 108, MAT.Basalt, DEEP, "MoatBank")
			U(144, FY - 8, 104, 145, FY, 108, MAT.Basalt, DEEP, "MoatBank")
			sunk(136, 104, 144, 108, true)
			column(130, 98, CH)
			column(150, 98, CH)
			column(130, 114, CH)
			column(150, 114, CH, true)
			brazier(125.8, 106, 8, 1.2, 5)
			brazier(154.2, 106, 8, 1.2, 5)
			pile(127, 117, 3, 5, 2.5)
			teeth(125, 93, 155, 119, CH, 8)
			do -- THE BLAZING CHEST, against the side chamber's south wall facing the way in: iron-bound, ember-cracked, burning
				-- (opened as the mushroom huts' are, init.server: the Armor of a Lion Hunter inside). No R(): the room's stream stays put
				local cf = CFrame.lookAt(Vector3.new(140, FY, 117), Vector3.new(140, FY, 100))
				local iron, char = Color3.fromRGB(40, 36, 34), Color3.fromRGB(34, 22, 18)
				chestBody(cf, Vector3.new(4, 2.2, 2.4), MAT.CrackedLava, char, "BlazeChest", under, { -1.5, 0, 1.5 }, MAT.Metal, iron)
				part({ Name = "BlazeChestLock", Size = Vector3.new(0.5, 0.55, 0.12), CFrame = cf * CFrame.new(0, 1.8, -1.25), Material = MAT.Metal, Color = Color3.fromRGB(196, 150, 70), CanCollide = false, Parent = under })
				local lid = part({ Name = "BlazeChestLid", Size = Vector3.new(4.05, 0.45, 2.45), CFrame = cf * CFrame.new(0, 2.42, 0), Material = MAT.CrackedLava, Color = char, Parent = under })
				lit(blaze(140, FY + 3.4, 117, 4), EMBER, 22, 1.6)
				info.MushroomChests = info.MushroomChests or {}
				table.insert(info.MushroomChests, { Lid = lid, Hinge = cf * CFrame.new(0, 2.65, 1.2), Item = { Attr = "PotbellyArmor", Text = "Armor of a Lion Hunter. Heavy iron, and something on its back that was never meant for a man. Press T to choose weapons and armor." }, Prompt = prompt(lid, "Open", "Blazing Chest", 0.5, 7) })
			end

			do -- (its own scope: the build function holds a great many locals already)
				-- THE WAY EAST to the arena: wide and high, the fortress at its grandest. East from the hall's courtyard (its door z
				-- 70..84) between two fierce lava gutters and colonnades, then south the same way to the arena's north gate.
				-- Inside x 234..284, z 64..92, then x 256..284, z 92..120; ceiling y -80
				local EH = FY + 30
				local IRON = Color3.fromRGB(34, 30, 28)
				local function banner(x, z, alongX, top) -- dark, tattered, on an iron rod, flat to a wall
					local cf = CFrame.new(x, top - 8, z) * (alongX and CFrame.identity or CFrame.Angles(0, math.pi / 2, 0))
					part({ Name = "BannerRod", Size = Vector3.new(5.4, 0.3, 0.3), CFrame = cf * CFrame.new(0, 6.1, 0), Material = MAT.Metal, Color = IRON, Parent = under })
					part({ Name = "Banner", Size = Vector3.new(4.5, 12, 0.2), CFrame = cf, Material = MAT.Fabric, Color = Color3.fromRGB(52, 14, 14), CanCollide = false, Parent = under })
					part({ Name = "Banner", Size = Vector3.new(2.2, 3, 0.2), CFrame = cf * CFrame.new(R(-1, 1), -7.2, 0) * CFrame.Angles(0, 0, R(-0.2, 0.2)), Material = MAT.Fabric, Color = Color3.fromRGB(44, 12, 12), CanCollide = false, Parent = under })
				end
				local function chain(x, z, top, len, cage) -- hung from the ceiling, some with an iron cage on the end
					part({ Name = "Chain", Size = Vector3.new(0.3, len, 0.3), CFrame = CFrame.new(x, top - len / 2, z), Material = MAT.Metal, Color = IRON, CanCollide = false, Parent = under })
					if cage then
						local y = top - len - 2.5
						for _, o in ipairs({ { -1.2, -1.2 }, { 1.2, -1.2 }, { -1.2, 1.2 }, { 1.2, 1.2 } }) do
							part({ Name = "Cage", Size = Vector3.new(0.2, 5, 0.2), CFrame = CFrame.new(x + o[1], y, z + o[2]), Material = MAT.Metal, Color = IRON, CanCollide = false, Parent = under })
						end
						part({ Name = "Cage", Size = Vector3.new(2.8, 0.3, 2.8), CFrame = CFrame.new(x, y + 2.5, z), Material = MAT.Metal, Color = IRON, CanCollide = false, Parent = under })
						part({ Name = "Cage", Size = Vector3.new(2.8, 0.3, 2.8), CFrame = CFrame.new(x, y - 2.5, z), Material = MAT.Metal, Color = IRON, CanCollide = false, Parent = under })
					end
				end
				-- rock heaved out of a walk's walls, anywhere up them: x1..x2, z1..z2 the walk, sides which of its edges are wall
				-- ("x1", "x2", "z1", "z2"), keep(x, z) false where none should go
				local function rough(x1, z1, x2, z2, top, n, sides, keep)
					for _ = 1, n do
						local side = sides[ur:NextInteger(1, #sides)]
						local w, h, d = R(3, 8), R(5, 16), R(1.2, 3)
						local y = R(FY + h / 2 - 2, top - h / 2)
						local c
						if side == "z1" then
							c = CFrame.new(R(x1 + 3, x2 - 3), y, z1 + d / 2 - 0.5)
						elseif side == "z2" then
							c = CFrame.new(R(x1 + 3, x2 - 3), y, z2 - d / 2 + 0.5)
						elseif side == "x1" then
							c = CFrame.new(x1 + d / 2 - 0.5, y, R(z1 + 3, z2 - 3)) * CFrame.Angles(0, math.pi / 2, 0)
						else
							c = CFrame.new(x2 - d / 2 + 0.5, y, R(z1 + 3, z2 - 3)) * CFrame.Angles(0, math.pi / 2, 0)
						end
						if not keep or keep(c.X, c.Z) then
							part({ Name = "CaveRock", Size = Vector3.new(w, h, d), CFrame = c * CFrame.Angles(R(-0.15, 0.15), R(-0.25, 0.25), R(-0.15, 0.15)), Material = MAT.Rock, Color = dark(), Parent = under })
						end
					end
				end
				T:FillBlock(CFrame.new(261, -89, 91), Vector3.new(54, 66, 62), Enum.Material.Air) -- (x 234..288, z 60..122: clear of the moat)
				U(232, FY - 2, 68, 280, FY, 88, MAT.Slate, DEEP, "Floor")
				U(260, FY - 2, 88, 280, FY, 120, MAT.Slate, DEEP, "Floor")
				U(232, FY - 2, 64, 236, FY, 68, MAT.Slate, DEEP, "Floor")
				U(232, FY - 2, 88, 236, FY, 92, MAT.Slate, DEEP, "Floor")
				U(232, FY - 8, 64, 236, FY - 2, 92, MAT.Basalt, DEEP, "MoatBank")
				U(236, FY - 8, 68, 280, FY - 2, 88, MAT.Basalt, DEEP, "MoatBank") -- (the walk's sides, down into the lava)
				U(260, FY - 8, 88, 280, FY - 2, 120, MAT.Basalt, DEEP, "MoatBank")
				U(232, FY - 10, 62, 286, FY - 8, 120, MAT.Basalt, DEEP, "MoatBed")
				U(232, FY - 10, 62, 286, EH + 2, 64, MAT.Rock, ROCK, "Wall")
				U(284, FY - 10, 64, 286, EH + 2, 120, MAT.Rock, ROCK, "Wall")
				U(232, FY - 10, 92, 256, EH + 2, 94, MAT.Rock, ROCK, "Wall")
				U(254, FY - 10, 94, 256, EH + 2, 120, MAT.Rock, ROCK, "Wall")
				U(232, EH, 62, 286, EH + 2, 120, MAT.Rock, DEEP, "Ceiling")
				sunk(236, 64, 284, 68, true)
				sunk(236, 88, 256, 92, true)
				sunk(256, 88, 260, 120, true)
				sunk(280, 68, 284, 120, true)
				for _, x in ipairs({ 246, 258, 270 }) do
					column(x, 71, EH)
					if x ~= 270 then -- (not at x 270: that one stood in the middle of the turn south)
						column(x, 85, EH)
					end
				end
				for _, z in ipairs({ 98, 110 }) do
					column(263, z, EH)
					column(277, z, EH)
				end
				for x = 242, 278, 12 do
					U(x - 1.5, FY - 8, 64, x + 1.5, EH, 65.4, MAT.Basalt, DEEP, "Buttress")
					banner(x + 6, 64.3, true, EH)
				end
				for z = 76, 112, 12 do
					U(282.6, FY - 8, z - 1.5, 284, EH, z + 1.5, MAT.Basalt, DEEP, "Buttress")
					banner(283.7, z + 6, false, EH)
				end
				banner(244, 91.7, true, EH)
				banner(256.3, 104, false, EH)
				brazier(240, 72, 10, 1.4, 6)
				brazier(240, 84, 10, 1.4, 6)
				brazier(276, 80, 10, 1.4, 6)
				brazier(262, 115, 12, 1.6, 6)
				brazier(278, 115, 12, 1.6, 6)
				chain(252, 78, EH, 12)
				chain(264, 78, EH, 10, true)
				chain(270, 101, EH, 14)
				chain(270, 108, EH, 9, true)
				teeth(236, 66, 282, 90, EH, 10)
				teeth(258, 92, 282, 118, EH, 6)
				rough(234, 64, 284, 92, EH, 16, { "z1" })
				rough(234, 64, 284, 120, EH, 16, { "x2" })
				rough(234, 64, 256, 92, EH, 6, { "z2" })
				rough(256, 92, 284, 120, EH, 8, { "x1" })

				-- THE ARENA, where the way east ends: x 200..312, z 120..232 inside, ceiling y -54. The floor an island
				-- (x 208..304, z 128..224) in a fierce gutter of lava all round the edge, buttresses rising out of it; its pillars
				-- gather toward the centre - four great ones close in, five further out (one broken). In from the north over a
				-- slab, under the gate's raised portcullis.
				local AT = FY + 56
				local CX, CZ = 256, 176
				T:FillBlock(CFrame.new(256, -85, 176), Vector3.new(120, 74, 120), Enum.Material.Air) -- (x 196..316, z 116..236)
				U(208, FY - 2, 128, 304, FY, 224, MAT.Slate, DEEP, "Floor")
				U(208, FY - 8, 128, 304, FY - 2, 224, MAT.Basalt, DEEP, "MoatBank")
				U(200, FY - 10, 120, 312, FY - 8, 232, MAT.Basalt, DEEP, "MoatBed")
				U(198, FY - 10, 118, 256, AT + 2, 120, MAT.Rock, ROCK, "Wall")
				U(284, FY - 10, 118, 314, AT + 2, 120, MAT.Rock, ROCK, "Wall")
				U(256, FY + 28, 118, 284, AT + 2, 120, MAT.Rock, ROCK, "Wall") -- (over the gate, x 256..284, 28 high)
				U(260, FY - 10, 118, 280, FY - 2, 120, MAT.Rock, ROCK, "Wall")
				-- the south wall, open at x 260..284 (28 high) on THE WATCHDOG'S LAIR: a bridge over the gutter into a hole too
				-- dark to see into - black-walled, unlit, and veiled by layers of murk across its mouth. Inside x 258..286, z 234..316
				U(198, FY - 10, 232, 260, AT + 2, 234, MAT.Rock, ROCK, "Wall")
				U(284, FY - 10, 232, 314, AT + 2, 234, MAT.Rock, ROCK, "Wall")
				U(260, FY + 28, 232, 284, AT + 2, 234, MAT.Rock, ROCK, "Wall")
				U(260, FY - 10, 232, 284, FY - 2, 234, MAT.Rock, ROCK, "Wall")
				U(262, FY - 1.5, 224, 282, FY, 234, MAT.Basalt, ROCK, "Bridge")
				do
					local VOID = Color3.fromRGB(3, 3, 3)
					T:FillBlock(CFrame.new(272, FY + 12, 276), Vector3.new(36, 36, 88), Enum.Material.Air) -- (x 254..290, z 232..320)
					U(258, FY - 2, 234, 286, FY, 316, MAT.SmoothPlastic, VOID, "LairFloor")
					U(256, FY - 2, 234, 258, FY + 30, 318, MAT.SmoothPlastic, VOID, "LairWall")
					U(286, FY - 2, 234, 288, FY + 30, 318, MAT.SmoothPlastic, VOID, "LairWall")
					U(258, FY - 2, 316, 264, FY + 30, 318, MAT.SmoothPlastic, VOID, "LairWall") -- (its back: a doorway at x 264..280,
					U(280, FY - 2, 316, 286, FY + 30, 318, MAT.SmoothPlastic, VOID, "LairWall") -- 20 high, its door PyralisBulwark's)
					U(264, FY + 20, 316, 280, FY + 30, 318, MAT.SmoothPlastic, VOID, "LairWall")
					U(256, FY + 28, 234, 288, FY + 30, 318, MAT.SmoothPlastic, VOID, "LairCeiling")
					for i, z in ipairs({ 235, 238, 242, 247, 253 }) do -- (each veil darker: past the third nothing shows)
						part({ Name = "Murk", Size = Vector3.new(28, 30, 0.2), CFrame = CFrame.new(272, FY + 13, z), Material = MAT.SmoothPlastic, Color = VOID, Transparency = 0.5 - i * 0.07, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Parent = under })
					end
				end
				U(198, FY - 10, 120, 200, AT + 2, 232, MAT.Rock, ROCK, "Wall")
				U(312, FY - 10, 120, 314, AT + 2, 232, MAT.Rock, ROCK, "Wall")
				U(198, AT, 118, 314, AT + 2, 234, MAT.Rock, DEEP, "Ceiling")
				U(260, FY - 1.5, 118, 280, FY, 128, MAT.Basalt, ROCK, "Bridge")
				-- (the portcullis, raised, its teeth under the arch: PyralisBulwark's, so it can come down)
				merlons(256, 284, 120, FY + 28)
				sunk(200, 120, 312, 128, true, { 57, 83 }) -- (the rim open where the bridge crosses, x 257..283)
				sunk(200, 224, 312, 232, true, { 61, 83 }) -- (and where the lair's bridge crosses, x 261..283)
				sunk(200, 128, 208, 224, true)
				sunk(304, 128, 312, 224, true)
				for x = 212, 300, 14 do
					if x < 252 or x > 288 then -- (the gate stays clear)
						U(x - 2, FY - 8, 120, x + 2, AT, 122.4, MAT.Basalt, DEEP, "Buttress")
					end
					if x < 258 or x > 286 then -- (the lair's mouth stays clear)
						U(x - 2, FY - 8, 229.6, x + 2, AT, 232, MAT.Basalt, DEEP, "Buttress")
					end
					if x + 7 < 256 or x + 7 > 288 then
						banner(x + 7, 231.7, true, AT - 10)
					end
				end
				for z = 134, 218, 14 do
					U(200, FY - 8, z - 2, 202.4, AT, z + 2, MAT.Basalt, DEEP, "Buttress")
					U(309.6, FY - 8, z - 2, 312, AT, z + 2, MAT.Basalt, DEEP, "Buttress")
					banner(200.3, z + 7, false, AT - 10)
					banner(311.7, z + 7, false, AT - 10)
				end
				local pillars = {} -- ({ x, z, half-width, broken }: the True Watchdog perches on the standing ones, and lands clear of all)
				for k = 1, 3 do -- great pillars close round the centre, more further out (one broken) - but none on the watchdog's
					-- side, between the centre and its lair (k 0 of the inner four, k 0 and 1 of the outer five: left out)
					local a = k / 4 * math.pi * 2 + math.pi / 4
					column(CX + math.cos(a) * 13, CZ + math.sin(a) * 13, AT, false, 3)
					table.insert(pillars, { CX + math.cos(a) * 13, CZ + math.sin(a) * 13, 3, false })
				end
				for k = 2, 4 do
					local a = k / 5 * math.pi * 2 + math.rad(18)
					column(CX + math.cos(a) * 28, CZ + math.sin(a) * 28, AT, k == 2, 2.5)
					table.insert(pillars, { CX + math.cos(a) * 28, CZ + math.sin(a) * 28, 2.5, k == 2 })
				end
				for _, c in ipairs({ { 213, 133 }, { 299, 133 }, { 213, 219 }, { 299, 219 } }) do
					brazier(c[1], c[2], 12, 1.6, 6)
				end
				-- THE TRUE WATCHDOG'S SPIRES: its own perches, out near the island's edge, nothing like the columns - a stack of
				-- basalt drums twisting as they narrow, split by veins of dark fire, crowned with iron talons hooked inward round a
				-- scarred slab it crouches on. ({ x, z, base half-width, top y }; their own random stream, so the rest stays put)
				local spires, sr = {}, Random.new(4242)
				local IRON, VEIN = Color3.fromRGB(38, 32, 30), Color3.fromRGB(150, 28, 14)
				for _, c in ipairs({ { 217, 152 }, { 216, 203 }, { 295, 150 }, { 238, 214 } }) do
					local x, z, H = c[1], c[2], sr:NextNumber(15, 17)
					local yaw, y = sr:NextNumber(0, 6.28), FY
					for k = 0, 5 do -- (the drums, each turned further and thinner than the last)
						local hw, h = 3.2 - k * 0.3, H / 6
						local cf = CFrame.new(x, y + h / 2, z) * CFrame.Angles(0, yaw + k * 0.32, 0)
						part({ Name = "Spire", Size = Vector3.new(hw * 2, h + 0.1, hw * 2), CFrame = cf, Material = MAT.Basalt, Color = k % 2 == 0 and ROCK or DEEP, Parent = under })
						for _, f in ipairs({ 0, math.pi * 0.5 + k, math.pi + k * 0.7 }) do
							if sr:NextNumber() < 0.6 then
								part({ Name = "SpireVein", Size = Vector3.new(0.5, h * sr:NextNumber(0.5, 0.95), 0.2), CFrame = cf * CFrame.Angles(0, f, 0) * CFrame.new(sr:NextNumber(-hw * 0.6, hw * 0.6), 0, -hw - 0.05) * CFrame.Angles(0, 0, sr:NextNumber(-0.3, 0.3)), Material = MAT.CrackedLava, Color = VEIN, CanCollide = false, Parent = under })
							end
						end
						y += h
					end
					part({ Name = "SpireTop", Size = Vector3.new(5.6, 0.8, 5.6), CFrame = CFrame.new(x, y + 0.3, z) * CFrame.Angles(0, yaw + 2, 0), Material = MAT.Basalt, Color = DEEP, Parent = under })
					for g = 1, 3 do -- (gouged by its talons)
						part({ Name = "Gouge", Size = Vector3.new(0.25, 0.1, 3.2), CFrame = CFrame.new(x + (g - 2) * 0.8, y + 0.72, z) * CFrame.Angles(0, yaw + 0.5, 0), Material = MAT.CrackedLava, Color = VEIN, CanCollide = false, Parent = under })
					end
					for k = 1, 5 do -- the crown: iron talons rising out of the slab's edge, leaning out, then hooked back in
						local a = k / 5 * math.pi * 2 + yaw
						local o, d = Vector3.new(x, y + 0.4, z), Vector3.new(math.cos(a), 0, math.sin(a))
						local p1, p2, p3 = o + d * 2.5, o + d * 3.6 + Vector3.new(0, 3.4, 0), o + d * 2.6 + Vector3.new(0, 4.8, 0)
						for _, s in ipairs({ { p1, p2, 0.8 }, { p2, p3, 0.55 } }) do
							part({ Name = "SpireTalon", Size = Vector3.new(s[3], s[3], (s[2] - s[1]).Magnitude + 0.3), CFrame = CFrame.lookAt((s[1] + s[2]) / 2, s[2]), Material = MAT.Metal, Color = IRON, Parent = under })
						end
					end
					lit(ghost(x, y + 2, z), Color3.fromRGB(170, 25, 10), 18, 1.4)
					table.insert(spires, { x, z, 3.2, y + 0.7 })
				end
				for _ = 1, 8 do
					local a, r = R(0, 6.28), R(18, 36)
					chain(CX + math.cos(a) * r, CZ + math.sin(a) * r, AT, R(14, 26), ur:NextNumber() < 0.5)
				end
				teeth(210, 130, 302, 222, AT, 30)
				rough(200, 120, 312, 232, AT, 70, { "x1", "x2", "z1", "z2" }, function(x, z)
					return (z > 125 or x < 252 or x > 288) and (z < 227 or x < 256 or x > 288) -- (not across the gate or the lair's mouth)
				end)
				table.insert(info.Zones, 1, { Name = "Maw of Pyralis", MinX = 196, MaxX = 316, MinZ = 60, MaxZ = 236, MinY = FY - 12, MaxY = AT + 4 }) -- (the way east and the arena)
				info.Underfire.Arena = { MinX = 208, MaxX = 304, MinZ = 128, MaxZ = 224, Centre = Vector3.new(CX, FY, CZ), Door = Vector3.new(270, FY, 119), Pillars = pillars, Spires = spires } -- (the island; for the boss to come)
				-- the arena's gates, the lair's door, the run and the great lift beyond it, and PYRALIS BULWARK above (its own file)
				require(script.Parent:WaitForChild("PyralisBulwark")).build({ bonfire = makeBonfire, part = part, box = box, prompt = prompt, addFlicker = addFlicker, info = info, map = map, under = under, FY = FY })
			end
			table.insert(info.Zones, 1, { Name = "Maw of Pyralis", MinX = 118, MaxX = 166, MinZ = 34, MaxZ = 124, MinY = FY - 12, MaxY = PH + 10 }) -- (the way west)
		end


		-- THE DOOR: through the first block's west wall (x -20..-18) at z 52..58, y 0..9.5, from this hallway's open east cell
		-- into the start's west cell 4. A plank-and-iron leaf hung at its south edge (z 52): it swings open into the cell
		-- (init.server), but only from here; from the cell it's "locked".
		for _, w in ipairs(map:GetChildren()) do
			if w.Name == "Wall" and w:IsA("BasePart") then
				local c, s = w.Position, w.Size
				local x1, x2, z1, z2 = c.X - s.X / 2, c.X + s.X / 2, c.Z - s.Z / 2, c.Z + s.Z / 2
				if math.abs(x1 + 20) < 0.01 and math.abs(x2 + 18) < 0.01 and z1 <= 52 and z2 >= 58 and s.Y >= 15 then
					local col, mat = w.Color, w.Material
					w:Destroy()
					box(-20, 0, z1, -18, 16, 52, mat, col, "Wall")
					box(-20, 0, 58, -18, 16, z2, mat, col, "Wall")
					box(-20, 9.5, 52, -18, 16, 58, mat, col, "Wall")
					break
				end
			end
		end
		-- (the start cell's decor and wall dressing in the way of the doorway, and the bed that would block it)
		local function clearBox(x1, y1, z1, x2, y2, z2, root)
			for _, p in ipairs(root:GetDescendants()) do
				if p:IsA("BasePart") and p.Name ~= "Wall" and p.Name ~= "Floor" and p.Name ~= "Ceiling" and p.Name ~= "Bar" and p.Name ~= "BarRail" and p.Name ~= "Pillar" then
					local c, h, cf = p.Position, p.Size / 2, p.CFrame
					local ex = Vector3.new(
						math.abs(cf.XVector.X) * h.X + math.abs(cf.YVector.X) * h.Y + math.abs(cf.ZVector.X) * h.Z,
						math.abs(cf.XVector.Y) * h.X + math.abs(cf.YVector.Y) * h.Y + math.abs(cf.ZVector.Y) * h.Z,
						math.abs(cf.XVector.Z) * h.X + math.abs(cf.YVector.Z) * h.Y + math.abs(cf.ZVector.Z) * h.Z
					)
					if c.X - ex.X < x2 and c.X + ex.X > x1 and c.Y - ex.Y < y2 and c.Y + ex.Y > y1 and c.Z - ex.Z < z2 and c.Z + ex.Z > z1 then
						p:Destroy()
					end
				end
			end
		end
		local detailF = map:FindFirstChild("Detail")
		if detailF then
			clearBox(-20.4, 0, 51.6, -17.6, 10, 58.4, detailF)
		end
		for _, p in ipairs(map:GetChildren()) do -- (bed, straw, chains and bones, in the cell side of the doorway)
			if p:IsA("BasePart") and (p.Name == "Bed" or p.Name == "BedLeg" or p.Name == "Straw" or p.Name == "Skull" or p.Name == "Bone" or p.Name == "Chain") then
				local c = p.Position
				if c.X > -19 and c.X < -10 and c.Z > 50 and c.Z < 60 then
					p:Destroy()
				end
			end
		end
		-- the doorway's frame, and the leaf (a model hinged at its south edge)
		F(-20.4, 0, 51.4, -17.6, 9.9, 52, "FallenDoorFrame", TRIMF, MAT.Slate)
		F(-20.4, 0, 58, -17.6, 9.9, 58.6, "FallenDoorFrame", TRIMF, MAT.Slate)
		F(-20.4, 9.5, 51.4, -17.6, 10.3, 58.6, "FallenDoorFrame", TRIMF, MAT.Slate)
		local hingeCF = CFrame.new(-19, 0, 52)
		local leaf = Instance.new("Model")
		leaf.Name = "FallenDoor"
		leaf.Parent = map
		local function lp(name, size, off, color, mat)
			return part({ Name = name, Size = size, CFrame = hingeCF * CFrame.new(off), Material = mat, Color = color, Parent = leaf })
		end
		local hinge = lp("DoorHinge", Vector3.one, Vector3.zero, COL.Iron, MAT.Metal)
		hinge.Transparency, hinge.CanCollide, hinge.CanQuery = 1, false, false
		leaf.PrimaryPart = hinge
		-- a classic cell door: iron stiles, three crossbars, upright bars between, a lock box on the free edge
		for _, z in ipairs({ 0.15, 5.65 }) do
			lp("DoorStile", Vector3.new(0.5, 9.3, 0.4), Vector3.new(0, 4.65, z), COL.Iron, MAT.Metal)
		end
		for k = 0, 7 do
			lp("DoorBar", Vector3.new(0.3, 9.3, 0.3), Vector3.new(0, 4.65, 0.75 + k * 0.62), COL.Iron, MAT.Metal)
		end
		for _, y in ipairs({ 0.4, 4.6, 8.9 }) do
			lp("DoorCrossbar", Vector3.new(0.5, 0.4, 5.9), Vector3.new(0, y, 3), COL.Iron, MAT.Metal)
		end
		lp("DoorLock", Vector3.new(0.9, 1.1, 1.0), Vector3.new(-0.2, 4.6, 5.0), COL.Rust, MAT.Metal)
		-- (the doorway filled, wall-deep, by an unseen block till the door's opened: the bars alone are too thin to stop a
		-- body at a dash's speed, which goes clean through them)
		local stop = part({ Name = "FallenDoorStop", Size = Vector3.new(2.6, 9.4, 6), CFrame = CFrame.new(-19, 4.7, 55), Transparency = 1, CanQuery = false, CanTouch = false, CastShadow = false, Parent = wing })
		local openSpot = part({ Name = "FallenDoorSpot", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(-23, 3, 55), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = wing })
		local lockedSpot = part({ Name = "FallenDoorLockedSpot", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(-16, 3, 55), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = wing })
		info.FallenStairDev = CFrame.lookAt(Vector3.new(-40.5, 33.2, 68), Vector3.new(-40.5, 33.2, 80)) -- (dev teleport: the top of the stair down to the door's hallway)
		info.FallenDoor = { Leaf = leaf, Hinge = hingeCF, Stop = stop, Prompt = prompt(openSpot, "Open", "Heavy Door", 0.4, 4), LockedPrompt = prompt(lockedSpot, "Open", "Heavy Door", 0, 7) }
	end

	do -- the grand gate, and the decayed land past it (its own file; the palace in it is cloned from Pyralis's)
		local t1 = os.clock()
		local ok, err = pcall(DecayedPalace.build, { part = part, box = box, info = info, map = map })
		if not ok then
			warn("[DGUS] DecayedPalace.build: " .. tostring(err))
		end
		print(string.format("[DGUS] map: the Decayed Palace (%.2fs)", os.clock() - t1))
	end

	do -- the kingdom on the colosseum's mountain (its own file)
		local t1 = os.clock()
		local ok, err = pcall(GildedHeights.build, { part = part, prompt = prompt, bonfire = makeBonfire, info = info, map = map })
		if not ok then
			warn("[DGUS] GildedHeights.build: " .. tostring(err))
		end
		print(string.format("[DGUS] map: the Gilded Heights (%.2fs)", os.clock() - t1))
	end
	-- Ossaria's bonfire, where she waits in the Rotted Court: after every other (a save knows bonfires by their order),
	-- and hidden till she's gone (GameServer/Ossaria)
	if info.OssariaPit then
		local s = info.OssariaPit.Spot
		info.OssariaPit.Bonfire = makeBonfire(s, CFrame.lookAt(s + Vector3.new(4.5, 3.2, 0), s + Vector3.new(0, 3.2, 0)), "The Rotted Court")
	end

	local t0 = os.clock()
	local faces = separateCoplanar(map)
	print(string.format("[DGUS] map: pulled %d overlapping coplanar faces apart (%.2fs)", faces, os.clock() - t0))
	return info
end

return MapBuilder
