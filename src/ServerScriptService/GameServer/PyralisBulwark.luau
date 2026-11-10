--!nonstrict
-- PyralisBulwark: the way on past the Watchdogs, and where it goes. Built by MapBuilder (the Underfire's arena block) with
-- its kit; init.server drives what moves (the gates, the lair's door, the lift).
--   THE GATES: a portcullis in the arena's north gate and another in the lair's mouth, both raised; down while a fight
--     with the brothers is on (info.Bulwark.Gates).
--   THE LAIR'S DOOR: its black back wall (z 316..318) has a slab in it, x 264..280, that sinks once both are slain; the
--     murk over the lair's mouth lifts and its lamps come on (info.Bulwark.Lair).
--   THE WATCHDOG'S RUN: a short tunnel, south then east (x 262..344, z 318..338), to THE GREAT LIFT: a shaft (x 344..368,
--     z 316..340) from the depths (FY) up through the ground and on up inside its own tower to 90, and a platform the
--     size of a room that carries you up it, like the old lifts of Lordran: a lever on it, and one at each end to call it
--     (info.Bulwark.Lift).
--   PYRALIS BULWARK (the zone, from 84 up: its name only shows as the lift reaches the top), east of the township: a sea
--     of lava broken by shards of brimstone, and out of it spires of black stone linked high up by bridges - from the
--     lift's tower south-east, then north, back west, east and on round, one spire climbed by a stair wound round its
--     outside - to the keep on its pedestal of rock in the middle, where a beacon burns on the roof. The only terrain is
--     the lava's bed, under everything: nothing of it reaches the stone.
-- Its own random stream.
local M = {}

local C3 = Color3.fromRGB
local MAT = Enum.Material
local V3 = Vector3.new

function M.build(k)
	local part, box, prompt, addFlicker, info, map, FY = k.part, k.box, k.prompt, k.addFlicker, k.info, k.map, k.FY
	local makeBonfire = k.bonfire
	local T = workspace.Terrain
	local rng = Random.new(5151)
	local function R(a, b)
		return rng:NextNumber(a, b)
	end
	-- the Bulwark's and the palace's rank and file: the three forge-brutes in turn (Characters/Stoker, Forgeknight, Ashsmith)
	local BRUTES, nBrute = { "Stoker", "Forgeknight", "Ashsmith" }, 0
	local function brute()
		nBrute += 1
		return BRUTES[(nBrute - 1) % #BRUTES + 1]
	end
	local folder = Instance.new("Folder")
	folder.Name = "PyralisBulwark"
	folder.Parent = map
	local function P(props)
		props.Parent = props.Parent or folder
		return part(props)
	end
	local function B(x1, y1, z1, x2, y2, z2, mat, col, name)
		return box(x1, y1, z1, x2, y2, z2, mat, col, name, folder)
	end
	local function light(parent, col, range, bright)
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = col, range, bright
		l.Parent = parent
		addFlicker(l)
		return l
	end
	local function ghost(pos, size)
		return P({ Name = "Fx", Size = size or Vector3.one, CFrame = CFrame.new(pos), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	end
	local function fire(pos, size, heat)
		local f = Instance.new("Fire")
		f.Size, f.Heat = size, heat or size
		f.Color, f.SecondaryColor = C3(255, 100, 30), C3(120, 16, 8)
		f.Parent = ghost(pos)
		return f.Parent
	end
	local function smoke(pos, size, rate)
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Color = ColorSequence.new(C3(52, 40, 34), C3(22, 18, 18))
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size * 0.5), NumberSequenceKeypoint.new(1, size * 2.4) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
		e.Lifetime, e.Speed, e.RotSpeed = NumberRange.new(4, 7), NumberRange.new(3, 6), NumberRange.new(-20, 20)
		e.Acceleration, e.Rate = V3(1.5, 2, 0), rate or 3
		e.Parent = ghost(pos, V3(size, 1, size))
	end
	local function embers(pos, size, rate)
		local e = Instance.new("ParticleEmitter")
		e.Color, e.LightEmission = ColorSequence.new(C3(255, 150, 60), C3(200, 40, 10)), 1
		e.Size = NumberSequence.new(0.2, 0)
		e.Lifetime, e.Speed, e.SpreadAngle = NumberRange.new(1.5, 3), NumberRange.new(2, 6), Vector2.new(40, 40)
		e.Acceleration, e.Rate = V3(0, 4, 0), rate or 8
		e.Shape = Enum.ParticleEmitterShape.Box
		e.Parent = ghost(pos, size)
	end

	local IRON, VOID = C3(34, 30, 28), C3(3, 3, 3)
	local STONE, STONE_DK, TRIM = C3(58, 50, 46), C3(40, 34, 32), C3(82, 70, 62)
	local LAVA, EMBER = C3(255, 84, 20), C3(255, 90, 30)

	---------------------------------------------------------------------------
	-- THE GATES (raised: lifted 22, their teeth showing under the arches) and THE LAIR'S DOOR
	---------------------------------------------------------------------------
	local UP = 22
	local function portcullis(x1, x2, z)
		local g = { Parts = {}, Up = UP }
		for x = x1 + 1, x2 - 1, 2 do
			table.insert(g.Parts, P({ Name = "Portcullis", Size = V3(0.4, 28, 0.4), CFrame = CFrame.new(x, FY + 14 + UP, z), Material = MAT.Metal, Color = IRON }))
		end
		for _, y in ipairs({ 4, 11, 18, 25 }) do
			table.insert(g.Parts, P({ Name = "Portcullis", Size = V3(x2 - x1 - 1, 0.5, 0.5), CFrame = CFrame.new((x1 + x2) / 2, FY + y + UP, z), Material = MAT.Metal, Color = IRON, CanCollide = false }))
		end
		g.Blocker = P({ Name = "GateBlock", Size = V3(x2 - x1, 28, 1.2), CFrame = CFrame.new((x1 + x2) / 2, FY + 14, z), Transparency = 1, CanCollide = false, CanQuery = false })
		return g
	end
	local gates = { portcullis(260, 280, 119), portcullis(260, 284, 233) }
	local lair = {
		Door = P({ Name = "LairDoor", Size = V3(16, 20, 2), CFrame = CFrame.new(272, FY + 10, 317), Material = MAT.SmoothPlastic, Color = VOID }),
		Murk = {},
		Lamps = {},
	}
	for _, p in ipairs(k.under:GetChildren()) do
		if p.Name == "Murk" then
			table.insert(lair.Murk, p)
		end
	end
	for _, z in ipairs({ 250, 270, 290, 310 }) do -- (dark till it's opened)
		for _, x in ipairs({ 259, 285 }) do
			local l = light(ghost(V3(x, FY + 8, z)), C3(200, 60, 20), 22, 1.2)
			l.Enabled = false
			table.insert(lair.Lamps, l)
		end
	end

	---------------------------------------------------------------------------
	-- THE WATCHDOG'S RUN and THE GREAT LIFT
	---------------------------------------------------------------------------
	local TOP = 90 -- the lift's top: up inside its own tower, high over the lava
	-- THE GROUND, cleared first so nothing of it is left in the way: every old hill in the area gone, a bed of cracked lava
	-- laid over the bedrock (its top at -5, under the lava's skin), and the run and the shaft cut through it all
	local X1, X2, Z1, Z2 = 320, 640, 150, 510
	T:FillBlock(CFrame.new((X1 + X2) / 2, 193, (Z1 + Z2) / 2), V3(X2 - X1, 414, Z2 - Z1), MAT.Air) -- (y -14..400)
	T:FillBlock(CFrame.new((X1 + X2) / 2, -9.5, (Z1 + Z2) / 2), V3(X2 - X1, 9, Z2 - Z1), MAT.CrackedLava) -- (y -14..-5)
	-- THE BRANCH WEST, back toward the Fallen Cellblock (the open land between it and the township's bastion): its lava
	-- in two more rects, joined to the rest along x 320 (none west of x 150: the breach's pit, x 80..136, is left be)
	local BRANCH = { { 150, -140, 320, 150 }, { 220, 150, 320, 200 } } -- (to -140: room for the Censery)
	for _, q in ipairs(BRANCH) do
		T:FillBlock(CFrame.new((q[1] + q[3]) / 2, 193, (q[2] + q[4]) / 2), V3(q[3] - q[1], 414, q[4] - q[2]), MAT.Air)
		T:FillBlock(CFrame.new((q[1] + q[3]) / 2, -9.5, (q[2] + q[4]) / 2), V3(q[3] - q[1], 9, q[4] - q[2]), MAT.CrackedLava)
	end
	T:FillBlock(CFrame.new(303, FY + 10, 328), V3(86, 24, 24), MAT.Air) -- (the run, x 260..346, z 316..340)
	T:FillBlock(CFrame.new(356, (FY - 4 - 4) / 2, 328), V3(32, -4 - FY + 4, 32), MAT.Air) -- (the shaft, x 340..372, up through the bed)
	local RUN = C3(26, 22, 22)
	B(264, FY - 2, 318, 344, FY, 336, MAT.Slate, STONE_DK, "RunFloor")
	B(262, FY, 318, 264, FY + 22, 338, MAT.Rock, RUN, "RunWall")
	B(280, FY, 318, 344, FY + 22, 320, MAT.Rock, RUN, "RunWall")
	B(262, FY, 336, 344, FY + 22, 338, MAT.Rock, RUN, "RunWall")
	B(262, FY + 20, 316, 344, FY + 22, 338, MAT.Rock, RUN, "RunCeiling")
	for x = 276, 340, 16 do -- (ribs of black iron, and lamps low on the walls)
		B(x - 0.6, FY, 320, x + 0.6, FY + 20, 320.8, MAT.Metal, IRON, "RunRib")
		B(x - 0.6, FY, 335.2, x + 0.6, FY + 20, 336, MAT.Metal, IRON, "RunRib")
		B(x - 0.6, FY + 19.2, 320, x + 0.6, FY + 20, 336, MAT.Metal, IRON, "RunRib")
		light(ghost(V3(x + 8, FY + 4, 335)), C3(210, 70, 25), 20, 1)
		fire(V3(x + 8, FY + 1, 335), 2)
	end
	for _ = 1, 10 do -- (scorch and rubble on its floor)
		local s = R(0.8, 2)
		P({ Name = "Rubble", Size = V3(s, s * 0.6, s), CFrame = CFrame.new(R(266, 340), FY + s * 0.3, R(322, 334)) * CFrame.Angles(R(-0.4, 0.4), R(0, 6.28), R(-0.4, 0.4)), Material = MAT.Basalt, Color = STONE_DK })
	end
	-- THE LIFT'S TOWER: the shaft's walls (the west one open on the run) carried on up out of the lava as a tower, to 89
	B(344, FY - 4, 316, 368, FY - 2, 340, MAT.Slate, STONE_DK, "LiftPit")
	B(342, FY - 4, 314, 344, FY, 342, MAT.Rock, STONE, "LiftWall")
	B(342, FY + 20, 314, 344, TOP - 1, 342, MAT.Rock, STONE, "LiftWall")
	B(342, FY, 314, 344, FY + 20, 320, MAT.Rock, STONE, "LiftWall")
	B(342, FY, 336, 344, FY + 20, 342, MAT.Rock, STONE, "LiftWall")
	B(368, FY - 4, 314, 370, TOP - 1, 342, MAT.Rock, STONE, "LiftWall")
	B(344, FY - 4, 314, 368, TOP - 1, 316, MAT.Rock, STONE, "LiftWall")
	B(344, FY - 4, 340, 368, TOP - 1, 342, MAT.Rock, STONE, "LiftWall")
	for y = FY + 10, TOP - 10, 20 do -- (bands of iron round its inside, and lamps)
		B(344, y, 316, 368, y + 1, 316.6, MAT.Metal, IRON, "LiftBand")
		B(344, y, 339.4, 368, y + 1, 340, MAT.Metal, IRON, "LiftBand")
		B(367.4, y, 316, 368, y + 1, 340, MAT.Metal, IRON, "LiftBand")
		light(ghost(V3(y % 40 == 0 and 345 or 367, y + 2, 328)), C3(240, 140, 80), 34, 1.5)
	end
	for _, c in ipairs({ { 344.4, 316.4 }, { 367.6, 316.4 }, { 344.4, 339.6 }, { 367.6, 339.6 } }) do -- (its great chains, top to bottom)
		P({ Name = "LiftChain", Size = V3(0.6, TOP - FY + 2, 0.6), CFrame = CFrame.new(c[1], (FY + TOP) / 2, c[2]), Material = MAT.Metal, Color = IRON, CanCollide = false })
	end
	-- its outside, above the lava: a battered foot, buttresses up its corners, courses of trim, cracks of fire, slits
	local function hollow(o, y1, y2, mat, col, name) -- (a ring round the tower's walls, o out from them: never across the shaft)
		B(342 - o, y1, 314 - o, 370 + o, y2, 314, mat, col, name)
		B(342 - o, y1, 342, 370 + o, y2, 342 + o, mat, col, name)
		B(342 - o, y1, 314, 342, y2, 342, mat, col, name)
		B(370, y1, 314, 370 + o, y2, 342, mat, col, name)
	end
	hollow(4, -8, 10, MAT.Basalt, STONE_DK, "LiftTowerFoot")
	for _, c in ipairs({ { 342, 314 }, { 370, 314 }, { 342, 342 }, { 370, 342 } }) do
		B(c[1] - 2.5, 10, c[2] - 2.5, c[1] + 2.5, TOP - 3, c[2] + 2.5, MAT.Basalt, STONE, "LiftButtress")
	end
	for y = 22, TOP - 8, 16 do
		hollow(0.6, y, y + 1, MAT.Slate, TRIM, "LiftCourse")
	end
	-- its top: a ring of flagstones round the shaft's mouth (out over the walls on corbels), merlons round its edge but
	-- for the way off east-south-east, and an iron rail round the mouth on three sides (it's open to the west)
	local RING_Y = TOP + 0.2
	for _, e in ipairs({ { 336, 308, 376, 317 }, { 336, 339, 376, 348 }, { 336, 317, 345, 339 }, { 367, 317, 376, 339 } }) do
		B(e[1], TOP - 1, e[2], e[3], RING_Y - 0.1, e[4], MAT.Slate, STONE, "LiftTop")
	end
	hollow(7, TOP - 3, TOP - 1, MAT.Basalt, STONE_DK, "LiftCorbel") -- (under the ring's overhang)
	local exitAt = V3(376, RING_Y, 313.6) -- (where the first bridge leaves, toward the first spire)
	light(ghost(V3(356, RING_Y + 12, 328)), C3(255, 160, 100), 40, 1.6)
	for _, e in ipairs({ { 336, 308, 376, 308 }, { 336, 348, 376, 348 }, { 336, 308, 336, 348 }, { 376, 308, 376, 348 } }) do
		local a, b = V3(e[1], 0, e[2]), V3(e[3], 0, e[4])
		for t = 0, 1, 1 / 12 do
			local p = a:Lerp(b, t)
			if (V3(p.X, 0, p.Z) - V3(exitAt.X, 0, exitAt.Z)).Magnitude > 7.5 and (p - a).Magnitude > 2 and (p - b).Magnitude > 2 then
				B(p.X - 0.8, RING_Y, p.Z - 0.8, p.X + 0.8, RING_Y + 3, p.Z + 0.8, MAT.Basalt, STONE, "Merlon")
			end
		end
	end
	for _, e in ipairs({ { 345, 316.6, 367, 317 }, { 345, 339, 367, 339.4 }, { 367, 317, 367.4, 339 } }) do
		B(e[1], RING_Y, e[2], e[3], RING_Y + 3, e[4], MAT.Metal, IRON, "LiftRail")
	end
	-- the platform (resting at the bottom: its top flush with the run's floor), each piece kept with its offset
	local base = CFrame.new(356, FY - 0.8, 328)
	local lift = { Parts = {}, Bottom = base, Top = base + V3(0, RING_Y - FY, 0), At = "Bottom" }
	local function lp(props)
		local p = P(props)
		table.insert(lift.Parts, { p, base:ToObjectSpace(p.CFrame) })
		return p
	end
	lift.Deck = lp({ Name = "LiftDeck", Size = V3(22, 1.6, 22), CFrame = base, Material = MAT.Slate, Color = STONE })
	light(lift.Deck, C3(255, 170, 110), 34, 1.6)
	for _, e in ipairs({ { 0, 10.6, 22, 0.8 }, { 0, -10.6, 22, 0.8 }, { 10.6, 0, 0.8, 22 }, { -10.6, 0, 0.8, 22 } }) do
		lp({ Name = "LiftRim", Size = V3(e[3], 0.5, e[4]), CFrame = base * CFrame.new(e[1], 1.05, e[2]), Material = MAT.Metal, Color = IRON, CanCollide = false })
	end
	for i = -1, 1 do -- (iron straps across its deck, and a sun worked in the middle)
		lp({ Name = "LiftStrap", Size = V3(0.6, 0.1, 21), CFrame = base * CFrame.new(i * 6, 0.85, 0), Material = MAT.Metal, Color = IRON, CanCollide = false })
	end
	lp({ Name = "LiftSun", Shape = Enum.PartType.Cylinder, Size = V3(0.12, 5, 5), CFrame = base * CFrame.new(0, 0.86, 0) * CFrame.Angles(0, 0, math.pi / 2), Material = MAT.Metal, Color = C3(150, 112, 52), CanCollide = false })
	lp({ Name = "LeverPost", Size = V3(0.8, 3.4, 0.8), CFrame = base * CFrame.new(-7, 2.5, -7), Material = MAT.Metal, Color = IRON })
	local handle = lp({ Name = "LeverHandle", Size = V3(0.3, 2.2, 0.3), CFrame = base * CFrame.new(-7, 4.4, -7) * CFrame.Angles(0.5, 0, 0), Material = MAT.Metal, Color = C3(150, 112, 52), CanCollide = false })
	lift.Prompt = prompt(handle, "Pull", "Lever", 0.4, 8)
	-- the levers that call it: at the run's end, and on the tower's top, on the open (west) side of the mouth
	local lb = P({ Name = "CallLever", Size = V3(0.8, 3.4, 0.8), CFrame = CFrame.new(339, FY + 1.7, 334.5), Material = MAT.Metal, Color = IRON })
	lift.CallBottom = prompt(lb, "Pull", "Lever", 0.4, 8)
	local lt = P({ Name = "CallLever", Size = V3(0.8, 3.4, 0.8), CFrame = CFrame.new(339, RING_Y + 1.7, 322), Material = MAT.Metal, Color = IRON })
	lift.CallTop = prompt(lt, "Pull", "Lever", 0.4, 8)

	---------------------------------------------------------------------------
	-- PYRALIS BULWARK: a sea of lava, and standing out of it spires of black stone, linked high up by bridges - from the
	-- lift's tower, round and back and on, one spire climbed by a stair wound round its outside - to the keep in the
	-- middle, on a great pedestal of rock, where a beacon burns
	---------------------------------------------------------------------------
	local C = V3(480, 0, 330) -- the keep's centre
	local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2) -- (a part cylinder lies along x: this stands it up)
	-- the lava's skin over the whole of it, glowing; light, fire and smoke off it
	local function lavaRect(x1, z1, x2, z2) -- (the glow: low lights over it, every 48)
		for x = x1 + 24, x2 - 1, 48 do
			for z = z1 + 24, z2 - 1, 48 do
				light(ghost(V3(x, -2.5, z)), C3(255, 90, 30), 46, 1.3)
			end
		end
	end
	lavaRect(X1, Z1, X2, Z2)
	for _, q in ipairs(BRANCH) do
		lavaRect(q[1], q[2], q[3], q[4])
	end
	-- into it: it takes you (all but the lift's shaft, which goes down through it)
	for _, b in ipairs({ { 372, X2, Z1, Z2 }, { X1, 372, Z1, 312 }, { X1, 372, 344, Z2 }, { 150, 320, -140, 150 }, { 220, 320, 150, 200 } }) do
		-- (MinY: only in the lava itself - the Maw of Pyralis lies far beneath it, at FY, and must not count)
		table.insert(info.Underfire.Moats, { MinX = b[1], MaxX = b[2], MinZ = b[3], MaxZ = b[4], MaxY = -2.5, MinY = -40 })
	end

	---------------------------------------------------------------------------
	-- GOTHIC: the pieces everything up here is built of
	---------------------------------------------------------------------------
	local GOTH, GOTH_DK, GOTH_LT = C3(64, 56, 52), C3(42, 36, 34), C3(92, 82, 74)
	local WALK, PARA = C3(56, 48, 44), C3(70, 60, 54)
	local GLASS = C3(16, 12, 14)
	local WOOD, WOOD_DK = C3(70, 52, 40), C3(46, 34, 26)
	local W = 9 -- (a bridge's width, between its parapets)
	local UPV = V3(0, 1, 0)
	local function blk(name, size, cf, mat, col, collide)
		return P({ Name = name, Size = size, CFrame = cf, Material = mat or MAT.Slate, Color = col or GOTH, CanCollide = collide ~= false })
	end
	local function wedge(name, size, cf, col)
		local w = Instance.new("WedgePart")
		w.Name, w.Anchored, w.Size, w.CFrame, w.Material, w.Color = name, true, size, cf, MAT.Slate, col or GOTH_DK
		w.TopSurface, w.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		w.Parent = folder
		return w
	end
	-- a rib: a block from p1 to p2, thick across the line (in the plane whose normal is nrm), deep along nrm
	local function rib(p1, p2, nrm, thick, deep, col, mat)
		local d = p2 - p1
		local len = d.Magnitude
		if len < 0.05 then
			return
		end
		local x = d.Unit
		local y = nrm.Unit:Cross(x)
		P({ Name = "Rib", Size = V3(len + thick * 0.4, thick, deep), CFrame = CFrame.fromMatrix((p1 + p2) / 2, x, y), Material = mat or MAT.Slate, Color = col or GOTH, CanCollide = false })
	end
	-- half a pointed arch: from a springing Sa (rising straight up out of it) to the apex A (where it meets its other
	-- half at an angle): an arc of 60 degrees, as in an equilateral arch, stretched to fit
	local function pointed(Sa, A, n)
		local pts, h = {}, V3(A.X - Sa.X, 0, A.Z - Sa.Z)
		for i = 0, n do
			local th = math.rad(60) * i / n
			table.insert(pts, Sa + h * ((1 - math.cos(th)) * 2) + V3(0, (A.Y - Sa.Y) * math.sin(th) / 0.8660254, 0))
		end
		return pts
	end
	local function archRibs(Sa, Sb, apexY, nrm, thick, deep, col)
		local m = (Sa + Sb) / 2
		local A = V3(m.X, apexY, m.Z)
		local L1, L2 = pointed(Sa, A, 7), pointed(Sb, A, 7)
		for i = 1, #L1 - 1 do
			rib(L1[i], L1[i + 1], nrm, thick, deep, col)
			rib(L2[i], L2[i + 1], nrm, thick, deep, col)
		end
		return L1, L2
	end
	-- a pinnacle: a shaft, a band, a spirelet of shrinking blocks turning as they go, a finial; pos its foot
	local function pinnacle(pos, s, h)
		blk("Pinnacle", V3(s, h * 0.42, s), CFrame.new(pos + V3(0, h * 0.21, 0)), MAT.Slate, GOTH)
		blk("PinnacleBand", V3(s * 1.2, h * 0.06, s * 1.2), CFrame.new(pos + V3(0, h * 0.44, 0)), MAT.Slate, GOTH_LT)
		for i = 0, 3 do
			local w = s * (0.9 - i * 0.2)
			blk("Spirelet", V3(w, h * 0.13, w), CFrame.new(pos + V3(0, h * (0.53 + i * 0.12), 0)) * CFrame.Angles(0, (i % 2) * math.pi / 4, 0), MAT.Slate, GOTH_DK)
		end
		P({ Name = "Finial", Shape = Enum.PartType.Ball, Size = Vector3.one * math.max(0.4, s * 0.4), CFrame = CFrame.new(pos + V3(0, h, 0)), Material = MAT.Metal, Color = IRON, CanCollide = false })
	end
	-- an iron lantern on a post, lit warm; pos its foot
	local function lantern(pos)
		blk("LanternFoot", V3(0.9, 0.3, 0.9), CFrame.new(pos + V3(0, 0.15, 0)), MAT.Metal, IRON, false)
		local g = blk("LanternGlass", V3(0.7, 1.1, 0.7), CFrame.new(pos + V3(0, 0.85, 0)), MAT.Glass, C3(255, 176, 100), false)
		for _, c in ipairs({ { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }) do
			blk("LanternBar", V3(0.12, 1.1, 0.12), CFrame.new(pos + V3(c[1] * 0.38, 0.85, c[2] * 0.38)), MAT.Metal, IRON, false)
		end
		blk("LanternCap", V3(1, 0.3, 1), CFrame.new(pos + V3(0, 1.55, 0)) * CFrame.Angles(0, math.pi / 4, 0), MAT.Metal, IRON, false)
		light(g, C3(255, 165, 95), 28, 1.5)
	end
	-- a pointed opening's frame on a wall's face: jambs up from bottom (p0, the middle of its sill) to the springing, then
	-- the arch to its apex; across = along the wall, out = the wall's outward normal. fillCol: the head's corners filled
	-- in (on a real opening) - rows of stone between the arch and the square of the opening
	local function pointedFrame(p0, w, spring, rise, across, out, thick, deep, col)
		local a0, b0 = p0 - across * (w / 2), p0 + across * (w / 2)
		rib(a0, a0 + UPV * spring, out, thick, deep, col)
		rib(b0, b0 + UPV * spring, out, thick, deep, col)
		archRibs(a0 + UPV * spring, b0 + UPV * spring, p0.Y + spring + rise, out, thick, deep, col)
	end
	local function headFill(p0, w, spring, rise, across, inward, depth, col)
		for j = 1, 4 do
			local fy = (j - 0.5) / 4
			local th = math.asin(math.clamp(fy * 0.8660254, 0, 1))
			local fx = (1 - math.cos(th)) * 2
			local fw = (w / 2) * fx
			for _, sd in ipairs({ -1, 1 }) do
				local c = p0 + across * (sd * (w / 2 - fw / 2)) + UPV * (spring + rise * fy) + inward * (depth / 2)
				blk("ArchHead", V3(1, 1, 1), CFrame.lookAt(c, c + inward), MAT.Slate, col or GOTH).Size = V3(math.max(fw, 0.05), rise / 4 + 0.02, depth)
			end
		end
	end
	-- a lancet window set into a wall's face (dark glass, a pointed head, its frame proud of the wall, a mullion)
	local function lancet(p0, w, h, across, out, col)
		local spring, rise = h - w * 0.8, w * 0.8
		local back = p0 + out * 0.02
		blk("Lancet", V3(w, spring, 0.12), CFrame.lookAt(back + UPV * (spring / 2), back + UPV * (spring / 2) + out), MAT.Glass, GLASS, false)
		for j = 1, 3 do
			local fy = (j - 0.5) / 3
			local th = math.asin(fy * 0.8660254)
			local fw = w * (1 - (1 - math.cos(th)) * 2)
			local c = back + UPV * (spring + rise * fy)
			blk("Lancet", V3(math.max(fw, 0.1), rise / 3 + 0.02, 0.12), CFrame.lookAt(c, c + out), MAT.Glass, GLASS, false)
		end
		pointedFrame(p0 + out * 0.25, w + 0.5, spring, rise + 0.3, across, out, 0.5, 0.6, col or GOTH_LT)
		rib(p0 + out * 0.2, p0 + out * 0.2 + UPV * (spring + rise * 0.6), out, 0.25, 0.3, col or GOTH_LT)
		blk("Sill", V3(w + 1, 0.4, 0.8), CFrame.lookAt(p0 + out * 0.35 - UPV * 0.2, p0 + out * 1.35 - UPV * 0.2), MAT.Slate, col or GOTH_LT)
	end
	-- a rose window: a disc of dark glass, a ring, spokes, a boss; c its centre, out its outward normal
	local function rose(c, r, out)
		local across = out:Cross(UPV).Unit
		P({ Name = "Rose", Shape = Enum.PartType.Cylinder, Size = V3(0.2, r * 2, r * 2), CFrame = CFrame.fromMatrix(c + out * 0.05, out, UPV), Material = MAT.Glass, Color = GLASS, CanCollide = false })
		local ring = {}
		for i = 0, 16 do
			local a = i / 16 * math.pi * 2
			table.insert(ring, c + out * 0.3 + across * (math.cos(a) * r) + UPV * (math.sin(a) * r))
		end
		for i = 1, 16 do
			rib(ring[i], ring[i + 1], out, 0.6, 0.7, GOTH_LT)
			if i % 2 == 0 then
				rib(c + out * 0.3, ring[i], out, 0.3, 0.4, GOTH_LT)
			end
		end
		P({ Name = "RoseBoss", Shape = Enum.PartType.Ball, Size = Vector3.one * r * 0.3, CFrame = CFrame.new(c + out * 0.3), Material = MAT.Slate, Color = GOTH_LT, CanCollide = false })
	end
	-- a cluster pier (a core and four shafts round it, a base, a capital): from y1 to y2 at p, turned to yaw
	local function clusterPier(p, y1, y2, s, yaw)
		local h = y2 - y1
		local base = CFrame.new(p.X, 0, p.Z) * yaw
		blk("PierCore", V3(s, h, s), base + V3(0, y1 + h / 2, 0), MAT.Slate, GOTH)
		for _, c in ipairs({ { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }) do
			P({ Name = "PierShaft", Shape = Enum.PartType.Cylinder, Size = V3(h, s * 0.42, s * 0.42), CFrame = (base * CFrame.new(c[1] * s * 0.5, y1 + h / 2, c[2] * s * 0.5)) * UPRIGHT, Material = MAT.Slate, Color = GOTH_LT })
		end
		blk("PierBase", V3(s * 1.6, math.min(2, h * 0.1), s * 1.6), base + V3(0, y1 + math.min(1, h * 0.05), 0), MAT.Slate, GOTH_DK)
		blk("PierCapital", V3(s * 1.55, 0.9, s * 1.55), base + V3(0, y2 - 0.45, 0), MAT.Slate, GOTH_LT)
	end
	local function sconce(pos, inward)
		blk("SconceArm", V3(0.3, 0.3, 1), CFrame.lookAt(pos + inward * 0.5, pos + inward * 1.5), MAT.Metal, IRON, false)
		lantern(pos + inward * 1 - UPV * 0.6)
	end

	---------------------------------------------------------------------------
	-- A BRIDGE: a deck from a to b (its top surface), its parapets with posts, pinnacles and lanterns, a corbel table
	-- under its edges; under it, carried on pointed arches springing from ca and cb (solid faces at either end) with
	-- open tracery up to the deck - and, if it's long, a cluster pier up out of the lava in the middle
	---------------------------------------------------------------------------
	local function bridge(a, b, ca, cb)
		ca, cb = ca or a, cb or b
		local len = (b - a).Magnitude
		local cf = CFrame.lookAt((a + b) / 2, b)
		blk("Deck", V3(W, 1.2, len), cf * CFrame.new(0, -0.6, 0), MAT.Slate, WALK)
		blk("DeckBody", V3(W - 1.4, 2.4, len), cf * CFrame.new(0, -2.4, 0), MAT.Basalt, GOTH_DK)
		for _, sx in ipairs({ -1, 1 }) do
			blk("DeckCourse", V3(0.7, 0.6, len), cf * CFrame.new(sx * (W / 2 + 0.1), -1.5, 0), MAT.Slate, GOTH_LT)
			for z = -len / 2 + 1.5, len / 2 - 1.5, 3 do
				blk("Corbel", V3(0.7, 1, 0.9), cf * CFrame.new(sx * (W / 2 - 0.3), -2.3, z), MAT.Slate, GOTH, false)
			end
		end
		local pl = len - 5 -- (the parapets stop 2.5 short of each end: nothing across where you step on or off)
		if pl > 1 then
			for _, sx in ipairs({ -1, 1 }) do
				local px = sx * (W / 2 + 0.45)
				blk("Parapet", V3(0.9, 2.2, pl), cf * CFrame.new(px, 1.1, 0), MAT.Slate, PARA)
				blk("Coping", V3(1.3, 0.35, pl + 0.4), cf * CFrame.new(px, 2.37, 0), MAT.Slate, GOTH_LT)
				local n = math.max(1, math.floor(pl / 7))
				for i = 0, n do
					local post = cf * CFrame.new(px, 0, -pl / 2 + pl * i / n)
					blk("ParapetPost", V3(1.5, 3, 1.5), post * CFrame.new(0, 1.5, 0), MAT.Slate, GOTH)
					local top = (post * CFrame.new(0, 3, 0)).Position
					if (i + (sx > 0 and 1 or 0)) % 2 == 0 then
						pinnacle(top, 1, 3.4)
					else
						lantern(top)
					end
					if i < n and pl / n > 3.6 then -- (blind tracery on its outer face: a little pointed panel between each pair of posts)
						local mid = (cf * CFrame.new(sx * (W / 2 + 0.92), 0.3, -pl / 2 + pl * (i + 0.5) / n)).Position
						local out = cf.RightVector * sx
						local across = cf.LookVector
						pointedFrame(mid, math.min(2.6, pl / n - 2.2), 0.9, 0.9, across, out, 0.22, 0.12, GOTH_DK)
					end
				end
			end
		end
		-- the support: pointed arches, their spandrels open tracery (posts from the arch up to the deck's underside)
		local flat = V3(b.X - a.X, 0, b.Z - a.Z)
		local hl = flat.Magnitude
		local nrm = V3(-flat.Z, 0, flat.X).Unit
		local yaw = CFrame.lookAt(Vector3.zero, flat).Rotation
		local function under(p) -- (the deck's underside, over p)
			local t = math.clamp((V3(p.X, 0, p.Z) - V3(a.X, 0, a.Z)):Dot(flat) / (hl * hl), 0, 1)
			return a.Y + (b.Y - a.Y) * t - 3.5
		end
		local D = math.clamp(hl * 0.3, 6, 16)
		local sy = math.min(a.Y, b.Y) - 3.5 - D
		local function span(Sa, Sb)
			local L1, L2 = archRibs(Sa, Sb, under((Sa + Sb) / 2) - 0.1, nrm, 1.8, W - 1.8, GOTH)
			for _, L in ipairs({ L1, L2 }) do
				for i = 2, #L - 1 do
					local p = L[i]
					local h = under(p) - p.Y
					if h > 0.8 then
						blk("Tracery", V3(W - 2.6, h, 0.8), CFrame.new(p + V3(0, h / 2, 0)) * yaw, MAT.Slate, GOTH, false)
					end
				end
			end
		end
		local Sa, Sb = V3(ca.X, sy, ca.Z), V3(cb.X, sy, cb.Z)
		if hl > 30 then
			local m = (Sa + Sb) / 2
			clusterPier(m, -7, under(m), 4.2, yaw)
			span(Sa, V3(m.X, sy, m.Z))
			span(V3(m.X, sy, m.Z), Sb)
		else
			span(Sa, Sb)
		end
	end

	---------------------------------------------------------------------------
	-- A SPIRE: a column of black stone out of the lava, buttressed, banded, its shaft set with blind lancets; at its
	-- top a round platform (radius sr) carried out on a corbelled cone and brackets, a parapet round its rim with
	-- pinnacles, open where its bridges meet it (opens: bearings, radians), a fire basin and a lamp
	---------------------------------------------------------------------------
	local function spire(x, z, top, opens, sr)
		sr = sr or 12
		local c0 = V3(x, 0, z)
		local h = top - 6 + 8
		P({ Name = "Spire", Shape = Enum.PartType.Cylinder, Size = V3(h, 16, 16), CFrame = CFrame.new(x, -8 + h / 2, z) * UPRIGHT, Material = MAT.Basalt, Color = STONE })
		P({ Name = "SpireFoot", Shape = Enum.PartType.Cylinder, Size = V3(16, 26, 26), CFrame = CFrame.new(x, 0, z) * UPRIGHT, Material = MAT.Basalt, Color = STONE_DK })
		P({ Name = "SpireFoot", Shape = Enum.PartType.Cylinder, Size = V3(10, 20, 20), CFrame = CFrame.new(x, 12, z) * UPRIGHT, Material = MAT.Basalt, Color = STONE_DK })
		for y = 26, top - 14, 18 do
			P({ Name = "SpireCourse", Shape = Enum.PartType.Cylinder, Size = V3(1.2, 17, 17), CFrame = CFrame.new(x, y, z) * UPRIGHT, Material = MAT.Slate, Color = GOTH_LT })
		end
		-- the corbelled cone up to the platform, and brackets under its rim
		P({ Name = "SpireCorbel", Shape = Enum.PartType.Cylinder, Size = V3(3, 19, 19), CFrame = CFrame.new(x, top - 7, z) * UPRIGHT, Material = MAT.Slate, Color = GOTH })
		P({ Name = "SpireCorbel", Shape = Enum.PartType.Cylinder, Size = V3(3.6, sr * 2 - 2, sr * 2 - 2), CFrame = CFrame.new(x, top - 3.9, z) * UPRIGHT, Material = MAT.Slate, Color = GOTH_DK })
		P({ Name = "SpireTop", Shape = Enum.PartType.Cylinder, Size = V3(2, sr * 2, sr * 2), CFrame = CFrame.new(x, top - 1.1, z) * UPRIGHT, Material = MAT.Slate, Color = STONE })
		for i = 0, 15 do
			local a = i / 16 * math.pi * 2
			local d = V3(math.cos(a), 0, math.sin(a))
			local p = c0 + d * (sr - 1.4) + V3(0, top - 4.6, 0)
			blk("Bracket", V3(1.2, 2.6, 2.4), CFrame.lookAt(p, p + d), MAT.Slate, GOTH, false)
		end
		-- four buttresses up its shaft, set back in two stages, each topped by a pinnacle under the platform
		local quiet, q = 0, -1 -- (the bearing furthest from any bridge, for the basin; buttresses at it and every 90)
		for i = 0, 23 do
			local cb = i / 24 * math.pi * 2
			local near = math.pi
			for _, b in ipairs(opens) do
				near = math.min(near, math.abs((cb - b + math.pi) % (2 * math.pi) - math.pi))
			end
			if near > q then
				quiet, q = cb, near
			end
		end
		for k = 0, 3 do
			local a = quiet + k * math.pi / 2 + math.pi / 4
			local d = V3(math.cos(a), 0, math.sin(a))
			local y1, y2 = 12, top - 16
			local f = CFrame.lookAt(c0 + d * 8.6, c0 + d * 10)
			blk("SpireButtress", V3(2.4, (y2 - y1) * 0.6, 2.4), f + V3(0, y1 + (y2 - y1) * 0.3, 0), MAT.Basalt, GOTH)
			blk("SpireButtress", V3(1.8, (y2 - y1) * 0.4, 1.6), (f * CFrame.new(0, 0, 0.4)) + V3(0, y1 + (y2 - y1) * 0.8, 0), MAT.Basalt, GOTH)
			pinnacle((f * CFrame.new(0, 0, 0.4)).Position + V3(0, y2, 0), 1.4, 5)
			-- blind lancets between the buttresses
			local b2 = a + math.pi / 4
			local d2 = V3(math.cos(b2), 0, math.sin(b2))
			for _, y in ipairs({ 34, top - 30 }) do
				if y > 20 and y < top - 22 then
					lancet(c0 + d2 * 8.02 + V3(0, y, 0), 2.2, 8, d2:Cross(UPV).Unit, d2)
				end
			end
		end
		-- the parapet round its rim, in short chords, open where the bridges come on
		local openHalf = math.asin(math.min(1, (W / 2 + 1.8) / sr)) + 0.05
		local N = 28
		local kept = {}
		for i = 0, N - 1 do
			local a1, a2 = i / N * math.pi * 2, (i + 1) / N * math.pi * 2
			local am = (a1 + a2) / 2
			local open = false
			for _, b in ipairs(opens) do
				open = open or math.abs((am - b + math.pi) % (2 * math.pi) - math.pi) < openHalf
			end
			kept[i] = not open
			if not open then
				local r0 = sr - 0.5
				local p1 = c0 + V3(math.cos(a1) * r0, top, math.sin(a1) * r0)
				local p2 = c0 + V3(math.cos(a2) * r0, top, math.sin(a2) * r0)
				local cfp = CFrame.lookAt((p1 + p2) / 2, p2)
				blk("RimParapet", V3(0.9, 2.2, (p2 - p1).Magnitude + 0.15), cfp * CFrame.new(0, 1.1, 0), MAT.Slate, PARA)
				blk("RimCoping", V3(1.3, 0.35, (p2 - p1).Magnitude + 0.3), cfp * CFrame.new(0, 2.37, 0), MAT.Slate, GOTH_LT)
			end
		end
		for i = 0, N - 1, 4 do
			if kept[i] and kept[(i - 1) % N] then
				local a = i / N * math.pi * 2
				local p = c0 + V3(math.cos(a) * (sr - 0.5), top, math.sin(a) * (sr - 0.5))
				blk("RimPost", V3(1.5, 3, 1.5), CFrame.new(p + V3(0, 1.5, 0)), MAT.Slate, GOTH)
				pinnacle(p + V3(0, 3, 0), 1, 3.6)
			end
		end
		local bp = c0 + V3(math.cos(quiet) * (sr - 3.5), top, math.sin(quiet) * (sr - 3.5))
		P({ Name = "Basin", Shape = Enum.PartType.Cylinder, Size = V3(1.2, 2.6, 2.6), CFrame = CFrame.new(bp + V3(0, 0.6, 0)) * UPRIGHT, Material = MAT.Metal, Color = IRON })
		fire(bp + V3(0, 1.6, 0), 3.5)
		light(ghost(V3(x, top + 8, z)), C3(255, 165, 100), 34, 1.7)
	end
	local function bearing(from, to)
		return math.atan2(to.Z - from.Z, to.X - from.X)
	end
	local function edge(s, toward, sr) -- (where a bridge's deck meets a spire's top: half a stud inside its rim)
		local a = bearing(s, toward)
		return V3(s.X + math.cos(a) * ((sr or 12) - 0.5), s.Y, s.Z + math.sin(a) * ((sr or 12) - 0.5))
	end
	local function face(s, toward) -- (where a bridge's arches spring from a spire: its shaft's face)
		local a = bearing(s, toward)
		return V3(s.X + math.cos(a) * 7.5, 0, s.Z + math.sin(a) * 7.5)
	end

	---------------------------------------------------------------------------
	-- A HALL, as Sen's upper fortress has them: a gothic house on its own pier in the lava, that the way goes into, across,
	-- up and out of. d: c, prev, nxt (it's laid along prev -> next), HF/HS (half its length/width), y0 (its floor), eave
	-- (its walls' height), roof ("gable": Hg its height; "tower": flat, battlemented, a spire), wing (how far its pier
	-- reaches out each side), doorIn/doorOut { s, y } (back/front walls), floors { f1, f2, s1, s2, y }, stairs { fa, fb,
	-- s, ya, yb, open (which side is open: its rail), w }, rails { { f, s }... , y }, pillars { f, s }, posts { f, s }
	-- (under the galleries), ribs (vault ribs at f), butt (buttresses at f), lancets (windows at f), flying, turrets
	-- Returns where the bridges meet its doors (just inside the doorways) and where their arches spring (its pier's faces)
	---------------------------------------------------------------------------
	local function hall(d)
		local dir = V3(d.nxt.X - d.prev.X, 0, d.nxt.Z - d.prev.Z).Unit
		local F = CFrame.lookAt(V3(d.c.X, 0, d.c.Z), V3(d.c.X, 0, d.c.Z) + dir)
		local FW, SW = F.LookVector, F.RightVector -- (forward: f; right: s)
		local function at(f, y, s)
			return F * CFrame.new(s, y, -f)
		end
		local function pos(f, y, s)
			return at(f, y, s).Position
		end
		local function slab(name, f1, f2, ya, yb, s1, s2, mat, col, collide)
			if math.abs(f2 - f1) < 0.05 or math.abs(yb - ya) < 0.05 or math.abs(s2 - s1) < 0.05 then
				return nil -- (nothing left of it: a wall that ends where a doorway begins)
			end
			return blk(name, V3(math.abs(s2 - s1), math.abs(yb - ya), math.abs(f2 - f1)), at((f1 + f2) / 2, (ya + yb) / 2, (s1 + s2) / 2), mat, col, collide)
		end
		local HF, HS, y0, TW = d.HF, d.HS, d.y0, 1.4
		local EY = y0 + d.eave
		local WG = d.wing
		-- the pier, battered at its foot, coursed
		slab("HallPier", -HF - 1.5, HF + 1.5, -8, y0 - 1.3, -HS - WG, HS + WG, MAT.Basalt, GOTH_DK)
		slab("HallPierFoot", -HF - 5, HF + 5, -8, 10, -HS - WG - 4, HS + WG + 4, MAT.Basalt, GOTH_DK)
		for y = 24, y0 - 12, 22 do
			slab("PierCourse", -HF - 1.9, HF + 1.9, y, y + 0.9, -HS - WG - 0.4, HS + WG + 0.4, MAT.Slate, GOTH_LT)
		end
		for _, sd in ipairs({ -1, 1 }) do -- (blind arcading down the pier's sides)
			for f = -HF + 4, HF - 4, 8 do
				lancet(pos(f, 30, sd * (HS + WG + 0.02)), 3, 14, FW, SW * sd, GOTH)
			end
		end
		slab("HallFloor", -HF + TW, HF - TW, y0 - 1.3, y0 - 0.1, -HS + TW, HS - TW, MAT.Slate, STONE)
		for _, dr in ipairs({ { -1, d.doorIn }, { 1, d.doorOut } }) do
			if dr[2].y <= y0 + 0.01 then
				local fo = dr[1] * (HF - 0.08)
				local fi = dr[1] * (HF - TW)
				slab("Threshold", math.min(fo, fi), math.max(fo, fi), y0 - 1.3, y0 - 0.1, dr[2].s - 5, dr[2].s + 5, MAT.Slate, STONE)
			end
		end
		-- the long walls (windows and buttresses on them), and the end walls with their pointed doorways
		for _, sd in ipairs({ -1, 1 }) do
			slab("HallWall", -HF, HF, y0 - 1.3, EY, sd > 0 and HS - TW or -HS, sd > 0 and HS or -HS + TW, MAT.Basalt, GOTH)
			slab("HallCornice", -HF - 0.3, HF + 0.3, EY - 0.8, EY, sd > 0 and HS - 0.2 or -HS - 0.6, sd > 0 and HS + 0.6 or -HS + 0.2, MAT.Slate, GOTH_LT)
			for _, f in ipairs(d.lancets) do
				for row = 1, d.lancetRows or 1 do
					lancet(pos(f, y0 + 4 + (row - 1) * 14, sd * (HS + 0.02)), d.lancetW or 2.6, d.lancetH or 11, FW, SW * sd)
				end
			end
			for _, f in ipairs(d.butt) do
				local top = d.flying and EY - 5 or EY - 3
				slab("Buttress", f - 1.2, f + 1.2, -8, (y0 + top) / 2, sd > 0 and HS or -HS - 2.4, sd > 0 and HS + 2.4 or -HS, MAT.Basalt, GOTH) -- (from the lava: where it stands out past a narrow pier, no foot shows)
				slab("Buttress", f - 0.9, f + 0.9, (y0 + top) / 2, top, sd > 0 and HS or -HS - 1.6, sd > 0 and HS + 1.6 or -HS, MAT.Basalt, GOTH)
				pinnacle(pos(f, top, sd * (HS + 0.8)), 1.3, 5)
				if d.flying then -- the flying buttress: an outer pier on the pier's wing, an arch flung from it to the wall
					local o = sd * (HS + WG - 2)
					slab("FlyingPier", f - 1.4, f + 1.4, y0 - 1.3, EY + 1, o - 1.4, o + 1.4, MAT.Basalt, GOTH)
					pinnacle(pos(f, EY + 1, o), 2, 8)
					local Sa = pos(f, EY - 10, o - sd * 1.4)
					local A = pos(f, EY - 2.5, sd * HS)
					local L = pointed(Sa, A, 6)
					for i = 1, #L - 1 do
						rib(L[i], L[i + 1], FW, 1.2, 1.6, GOTH)
						rib(L[i] + UPV * 1.6, L[i + 1] + UPV * 1.6, FW, 0.8, 1.2, GOTH_LT)
					end
				end
			end
		end
		local function endWall(fsign, door)
			local f1, f2 = fsign < 0 and -HF or HF - TW, fsign < 0 and -HF + TW or HF
			local ds1, ds2, dy = door.s - 5, door.s + 5, door.y
			slab("HallWall", f1, f2, y0 - 1.3, EY, -HS + TW, ds1, MAT.Basalt, GOTH)
			slab("HallWall", f1, f2, y0 - 1.3, EY, ds2, HS - TW, MAT.Basalt, GOTH)
			if dy > y0 then
				slab("HallWall", f1, f2, y0 - 1.3, dy - 0.1, ds1, ds2, MAT.Basalt, GOTH)
			end
			slab("HallWall", f1, f2, dy + 11, EY, ds1, ds2, MAT.Basalt, GOTH)
			-- its pointed head (the corners above the arch filled), its moulded frame proud of the wall outside
			local out = FW * fsign
			local wf = fsign < 0 and -HF or HF
			local p0 = pos(wf, dy, door.s)
			headFill(p0 - out * TW, 10, 6.5, 4.5, SW, out, TW, GOTH)
			pointedFrame(p0 + out * 0.3, 10.6, 6.5, 4.8, SW, out, 0.9, 1.4, GOTH_LT)
			for _, sd in ipairs({ -1, 1 }) do
				pinnacle(pos(wf + fsign * 0.6, dy + 11.5, door.s + sd * 6.2), 1, 4)
			end
		end
		endWall(-1, d.doorIn)
		endWall(1, d.doorOut)
		-- the roof
		if d.roof == "gable" then
			local Hg = d.Hg
			local ang = math.atan2(Hg, HS)
			local sw = math.sqrt(HS * HS + Hg * Hg) + 1.4
			for _, sd in ipairs({ -1, 1 }) do
				blk("Roof", V3(sw, 1, HF * 2 + 2), at(0, EY + Hg / 2 + 0.4, sd * HS / 2) * CFrame.Angles(0, 0, -sd * ang), MAT.Slate, GOTH_DK)
				for _, fsign in ipairs({ -1, 1 }) do -- (the gables: two wedges each end)
					local zt = SW * -sd
					local xt = UPV:Cross(zt)
					wedge("Gable", V3(TW, Hg, HS), CFrame.fromMatrix(pos(fsign * (HF - TW / 2), EY + Hg / 2, sd * HS / 2), xt, UPV), GOTH)
				end
			end
			for f = -HF, HF + 0.01, 3 do -- (a crest of little spikes down its ridge)
				blk("RidgeCrest", V3(0.5, 1.4, 0.5), at(f, EY + Hg + 1.1, 0) * CFrame.Angles(0, math.pi / 4, 0), MAT.Metal, IRON, false)
			end
			for _, fsign in ipairs({ -1, 1 }) do
				pinnacle(pos(fsign * HF, EY + Hg + 0.5, 0), 1.4, 6)
				if d.rose then
					rose(pos(fsign * HF, EY + Hg * 0.36, 0), math.min(HS * 0.36, Hg * 0.32), FW * fsign)
				end
			end
		else -- the tower: a flat roof, battlemented, a spire in the middle
			slab("Roof", -HF, HF, EY, EY + 1.2, -HS, HS, MAT.Slate, GOTH_DK)
			for f = -HF + 1, HF - 0.9, 2.8 do
				for _, sd in ipairs({ -1, 1 }) do
					slab("Merlon", f - 0.6, f + 0.6, EY + 1.2, EY + 3.8, sd * HS - 0.7, sd * HS + 0.7, MAT.Basalt, GOTH)
					slab("Merlon", sd * HF - 0.7, sd * HF + 0.7, EY + 1.2, EY + 3.8, f - 0.6, f + 0.6, MAT.Basalt, GOTH)
				end
			end
			for i = 0, 5 do
				local w = HS * (0.7 - i * 0.11)
				blk("TowerSpire", V3(w, 3.4, w), at(0, EY + 2.9 + i * 3.4, 0) * CFrame.Angles(0, (i % 2) * math.pi / 4, 0), MAT.Slate, i % 2 == 0 and GOTH_DK or GOTH)
			end
			pinnacle(pos(0, EY + 23.4, 0), 1.6, 8)
		end
		if d.turrets then -- turrets on its corners, each with a cone of stacked drums
			for _, c in ipairs({ { -1, -1 }, { -1, 1 }, { 1, -1 }, { 1, 1 } }) do
				local p = pos(c[1] * HF, 0, c[2] * HS)
				local top = EY + 6
				-- (from the lava up: it stands out past the pier's corner, and a turret ending in mid-air under there showed)
				P({ Name = "Turret", Shape = Enum.PartType.Cylinder, Size = V3(top + 8, 5.5, 5.5), CFrame = CFrame.new(p.X, (top - 8) / 2, p.Z) * UPRIGHT, Material = MAT.Basalt, Color = GOTH })
				for i = 0, 4 do
					P({ Name = "TurretCap", Shape = Enum.PartType.Cylinder, Size = V3(2.4, 6.2 - i * 1.3, 6.2 - i * 1.3), CFrame = CFrame.new(p.X, top + 1.2 + i * 2.4, p.Z) * UPRIGHT, Material = MAT.Slate, Color = i % 2 == 0 and GOTH_DK or GOTH })
				end
				P({ Name = "Finial", Shape = Enum.PartType.Ball, Size = Vector3.one * 0.9, CFrame = CFrame.new(p.X, top + 13.4, p.Z), Material = MAT.Metal, Color = IRON, CanCollide = false })
			end
		end
		-- inside: the galleries, the stairs (solid under them, a rail with balusters on their open side), the rails round
		-- the galleries' open edges (meeting the stairs' rails), pillars, posts, the vault ribs, lamps
		for _, g in ipairs(d.floors) do
			slab("Gallery", g[1], g[2], g[5] - 1.2, g[5] - 0.1, g[3], g[4], MAT.WoodPlanks, WOOD)
			for f = math.min(g[1], g[2]) + 1, math.max(g[1], g[2]) - 1, 3 do
				slab("GalleryJoist", f - 0.3, f + 0.3, g[5] - 1.9, g[5] - 1.2, g[3], g[4], MAT.Wood, WOOD_DK, false)
			end
		end
		local function railLine(p1, p2, ytop)
			local d2 = p2 - p1
			local n = math.max(1, math.ceil(d2.Magnitude / 2.2))
			for i = 0, n do
				local p = p1 + d2 * (i / n)
				blk("Baluster", V3(0.3, 2.6, 0.3), CFrame.new(p + UPV * 1.3), MAT.Wood, WOOD_DK)
			end
			rib(p1 + UPV * 2.75, p2 + UPV * 2.75, (d2:Cross(UPV)).Magnitude > 0.01 and d2:Cross(UPV) or FW, 0.35, 0.45, WOOD_DK, MAT.Wood)
			rib(p1 + UPV * 1.2, p2 + UPV * 1.2, (d2:Cross(UPV)).Magnitude > 0.01 and d2:Cross(UPV) or FW, 0.2, 0.25, WOOD_DK, MAT.Wood)
		end
		for _, st in ipairs(d.stairs) do
			local fa, fb, s, ya, yb, open, w = st[1], st[2], st[3], st[4], st[5], st[6], st[7]
			local A, Bp = pos(fa, ya - 0.1, s), pos(fb, yb - 0.1, s)
			local len = (Bp - A).Magnitude
			local scf = CFrame.lookAt((A + Bp) / 2, Bp)
			blk("Stair", V3(w, 1, len), scf * CFrame.new(0, -0.5, 0), MAT.WoodPlanks, WOOD)
			for i = 1, math.floor(len / 1.4) do -- (the treads' nosings, to read as steps)
				blk("Nosing", V3(w, 0.12, 0.25), scf * CFrame.new(0, 0.04, len / 2 - i * 1.4), MAT.Wood, WOOD_DK, false)
			end
			local n = math.ceil(math.abs(fb - fa) / 2) -- (solid stone under it, stepped)
			for i = 0, n - 1 do
				local f1, f2 = fa + (fb - fa) * i / n, fa + (fb - fa) * (i + 1) / n
				local ylow = ya + (yb - ya) * i / n - 0.1 - 1.05
				if ylow > y0 + 0.2 then
					slab("StairFill", f1, f2, y0 - 0.1, ylow, s - w / 2, s + w / 2, MAT.Basalt, GOTH)
				end
			end
			local rs = s + open * (w / 2 + 0.25)
			railLine(pos(fa, ya - 0.1, rs), pos(fb, yb - 0.1, rs))
		end
		for _, rl in ipairs(d.rails) do
			for i = 1, #rl - 1 do
				railLine(pos(rl[i][1], rl.y - 0.1, rl[i][2]), pos(rl[i + 1][1], rl.y - 0.1, rl[i + 1][2]))
			end
		end
		for _, pl in ipairs(d.pillars or {}) do
			clusterPier(pos(pl[1], 0, pl[2]), y0 - 0.1, EY - 4, 1.6, F.Rotation)
		end
		for _, pp in ipairs(d.posts or {}) do
			clusterPier(pos(pp[1], 0, pp[2]), y0 - 0.1, pp[3] - 1.2, 1.1, F.Rotation)
		end
		for _, f in ipairs(d.ribs or {}) do -- (vault ribs across under the roof, springing from corbels)
			local Sa, Sb = pos(f, EY - 4, -HS + TW), pos(f, EY - 4, HS - TW)
			archRibs(Sa, Sb, EY - 4 + math.min(HS * 0.62, (d.Hg or 6) + 2), FW, 0.8, 1.1, GOTH_LT)
			for _, sd in ipairs({ -1, 1 }) do
				blk("VaultCorbel", V3(1.2, 1.4, 1.2), at(f, EY - 4.7, sd * (HS - TW - 0.5)), MAT.Slate, GOTH_LT, false)
			end
		end
		for _, f in ipairs(d.lamps or {}) do
			for _, sd in ipairs({ -1, 1 }) do
				sconce(pos(f, y0 + 6, sd * (HS - TW)), SW * -sd)
			end
		end
		for _, ch in ipairs(d.chandeliers or {}) do
			local cp = pos(ch[1], ch[2], 0)
			P({ Name = "Chandelier", Shape = Enum.PartType.Cylinder, Size = V3(0.4, 6, 6), CFrame = CFrame.new(cp) * UPRIGHT, Material = MAT.Metal, Color = IRON, CanCollide = false })
			blk("ChandelierChain", V3(0.2, EY - ch[2], 0.2), CFrame.new(cp + UPV * ((EY - ch[2]) / 2)), MAT.Metal, IRON, false)
			for i = 0, 5 do
				local a = i / 6 * math.pi * 2
				lantern(cp + V3(math.cos(a) * 2.6, 0.2, math.sin(a) * 2.6))
			end
		end
		for _, it in ipairs(d.things or {}) do -- (furniture: { kind, f, s })
			if it[1] == "pew" then
				slab("Pew", it[2] - 0.5, it[2] + 0.5, y0 - 0.1, y0 + 1.1, it[3] - 3, it[3] + 3, MAT.Wood, WOOD_DK)
				slab("PewBack", it[2] + 0.4, it[2] + 0.7, y0 - 0.1, y0 + 2.4, it[3] - 3, it[3] + 3, MAT.Wood, WOOD_DK)
			elseif it[1] == "altar" then
				slab("Altar", it[2] - 1.2, it[2] + 1.2, y0 - 0.1, y0 + 3, it[3] - 3, it[3] + 3, MAT.Slate, GOTH_LT)
				for _, sx in ipairs({ -2, 0, 2 }) do
					lantern(pos(it[2], y0 + 3, it[3] + sx))
				end
			elseif it[1] == "table" then
				slab("Table", it[2] - 5, it[2] + 5, y0 + 2, y0 + 2.6, it[3] - 1.6, it[3] + 1.6, MAT.WoodPlanks, WOOD)
				for _, e in ipairs({ { -4.4, -1.2 }, { -4.4, 1.2 }, { 4.4, -1.2 }, { 4.4, 1.2 } }) do
					slab("TableLeg", it[2] + e[1] - 0.25, it[2] + e[1] + 0.25, y0 - 0.1, y0 + 2, it[3] + e[2] - 0.25, it[3] + e[2] + 0.25, MAT.Wood, WOOD_DK)
				end
				for _, sx in ipairs({ -2.8, 2.8 }) do
					slab("Bench", it[2] - 4.5, it[2] + 4.5, y0 - 0.1, y0 + 1.2, it[3] + sx - 0.5, it[3] + sx + 0.5, MAT.Wood, WOOD_DK)
				end
			elseif it[1] == "chest" then -- (opened as the mushroom huts' are, init.server; it[4]: what's in it) facing the way in
				local cf = at(it[2], y0 - 0.1, it[3]) * CFrame.Angles(0, math.pi, 0)
				local function c(name, size, off, mat, col, collide)
					return blk(name, size, cf * off, mat, col, collide)
				end
				c("Chest", V3(4, 2.2, 2.4), CFrame.new(0, 1.1, 0), MAT.WoodPlanks, WOOD_DK)
				for _, x in ipairs({ -1.5, 0, 1.5 }) do
					c("ChestBand", V3(0.3, 2.3, 2.5), CFrame.new(x, 1.1, 0), MAT.Metal, IRON, false)
				end
				c("ChestLock", V3(0.5, 0.55, 0.12), CFrame.new(0, 1.8, -1.25), MAT.Metal, C3(196, 150, 70), false)
				local lid = c("ChestLid", V3(4.05, 0.45, 2.45), CFrame.new(0, 2.42, 0), MAT.WoodPlanks, WOOD_DK)
				info.MushroomChests = info.MushroomChests or {}
				table.insert(info.MushroomChests, { Lid = lid, Hinge = cf * CFrame.new(0, 2.65, 1.2), Item = it[4], Prompt = prompt(lid, "Open", "Chest", 0.5, 7) })
			elseif it[1] == "barrel" then
				P({ Name = "Barrel", Shape = Enum.PartType.Cylinder, Size = V3(2.2, 1.8, 1.8), CFrame = at(it[2], y0 + 1, it[3]) * UPRIGHT, Material = MAT.WoodPlanks, Color = WOOD_DK })
			elseif it[1] == "banner" then
				local side = math.abs(it[3]) > HS - 3 -- (on a long wall: thin across s; on an end wall: thin along f)
				blk("Banner", side and V3(0.15, 12, 4.5) or V3(4.5, 12, 0.15), at(it[2], y0 + (it[4] or 14), it[3]), MAT.Fabric, C3(96, 18, 12), false)
			end
		end
		return pos(-HF + 0.6, d.doorIn.y, d.doorIn.s), pos(HF - 0.6, d.doorOut.y, d.doorOut.s), pos(-HF - 1.5, 0, d.doorIn.s), pos(HF + 1.5, 0, d.doorOut.s)
	end

	---------------------------------------------------------------------------
	-- THE WAY: spires (x, top, z), the three halls, the stair spire S7, the keep; and the branch west
	---------------------------------------------------------------------------
	local S1, S2, S3 = V3(395, 96, 300), V3(428, 104, 362), V3(405, 96, 400)
	local S5, S6, S7, S8 = V3(500, 106, 430), V3(540, 112, 395), V3(545, 132, 340), V3(520, 126, 290)
	local KEEP_IN = V3(503, 120.1, 334) -- (where the last bridge comes onto the keep's roof, 0.1 over it)
	local BR = { V3(380, 100, 240), V3(330, 108, 205), V3(280, 100, 170), V3(270, 120, 70), V3(220, 104, 30) } -- (then the Censery)
	local GATE_IN = V3(296, 104, 4.8) -- (where the bridge off BR5 comes in at the Censery's gatehouse door, as built: doubled and moved east)
	local H3c, H1c, H2c = V3(411.5, 0, 331), V3(452.5, 0, 415), V3(275, 0, 120)
	-- H3, THE CHAPEL: in low at its back, across to the stair up its right wall, onto the choir loft, out high at its front
	local H3in, H3out, H3ia, H3oa = hall({
		c = H3c, prev = S1, nxt = S2, HF = 15, HS = 10, y0 = 96, eave = 20, roof = "gable", Hg = 10, wing = 3, rose = true,
		doorIn = { s = -3.5, y = 96 }, doorOut = { s = 0, y = 104 },
		floors = { { 4, 13.6, -8.6, 8.6, 104 } },
		stairs = { { -10, 4, 6.1, 96, 104, -1, 5 } },
		rails = { { { 4, -8.6 }, { 4, 3.35 }, y = 104 } },
		posts = { { 4.6, 0, 104 } },
		ribs = { -10, -3, 4, 11 }, butt = { -12, -4, 4, 12 }, lancets = { -8, 0, 8 }, lancetH = 12,
		lamps = { -8, 2 }, chandeliers = { { -3, 109 } },
		things = { { "pew", -5, -5 }, { "pew", -2.5, -5 }, { "pew", 0, -5 }, { "chest", 11.06, -3.74, { Attr = "VeilOfFlame", Text = "Veil of Flame. Fire that will not go out, and will not let go. Press T to choose weapons and armor." } }, { "banner", -13.4, 3, 14 } },
	})
	-- H1, THE GREAT HALL: a nave between arcades, a loft over its front; in at the back-left, across the nave, up the
	-- stair in the right aisle, over the loft, out at the front - and flying buttresses down both its sides
	local H1in, H1out, H1ia, H1oa = hall({
		c = H1c, prev = S3, nxt = S5, HF = 22, HS = 15, y0 = 100, eave = 26, roof = "gable", Hg = 13, wing = 8, rose = true, flying = true, turrets = true,
		doorIn = { s = -8.5, y = 100 }, doorOut = { s = 0, y = 110 },
		floors = { { 4, 20.6, -13.6, 13.6, 110 } },
		stairs = { { -16, 4, 10.85, 100, 110, -1, 5.5 } },
		rails = { { { 4, -13.6 }, { 4, 7.85 }, y = 110 } },
		pillars = { { -15, -6.5 }, { -8, -6.5 }, { -1, -6.5 }, { -15, 6.5 }, { -8, 6.5 }, { -1, 6.5 } },
		posts = { { 4.6, -6.5, 110 }, { 4.6, 0, 110 }, { 4.6, 6.5, 110 } },
		ribs = { -18, -11, -4, 3, 10, 17 }, butt = { -14, -4, 6, 16 }, lancets = { -9, 1, 11 }, lancetW = 3, lancetH = 15,
		lamps = { -16, -6, 4, 14 }, chandeliers = { { -8, 119 }, { 12, 120 } },
		things = { { "table", -6, -1.5 }, { "barrel", 18, -12 }, { "barrel", 18, -10 }, { "banner", -20.6, 0, 16 } },
	})
	-- H2, THE TOWER-HOUSE (on the branch): three floors; up a stair on its right to a gallery across its front, up
	-- another on its left back to a gallery across its back, along its right side to a door high in its front
	local H2in, H2out, H2ia, H2oa = hall({
		c = H2c, prev = BR[3], nxt = BR[4], HF = 16, HS = 16, y0 = 104, eave = 32, roof = "tower", wing = 2, turrets = true,
		doorIn = { s = -8, y = 104 }, doorOut = { s = 9.6, y = 124 },
		floors = { { 4, 14.6, -14.6, 14.6, 114 }, { -14.6, -9, -14.6, 14.6, 124 }, { -9, 14.6, 4.6, 14.6, 124 } },
		stairs = { { -12, 4, 11.85, 104, 114, -1, 5.5 }, { 9, -9, -11.85, 114, 124, 1, 5.5 } },
		rails = { { { 4, -8.85 }, { 4, 8.85 }, y = 114 }, { { -9, -8.85 }, { -9, 4.35 }, { 14.6, 4.35 }, y = 124 } },
		posts = { { 4.6, -4, 114 }, { 4.6, 4, 114 } },
		butt = { -10, 0, 10 }, lancets = { -6, 6 }, lancetRows = 2, lancetH = 10,
		lamps = { -10, 10 }, chandeliers = { { -2, 121 } },
		things = { { "barrel", 12, -2 }, { "barrel", 12, -4.2 }, { "banner", 8, -14.5, 12 } },
	})
	-- the main way: the lift's tower -> S1 -> the chapel -> S2 -> S3 -> the great hall -> S5 -> S6 -> the stair spire S7
	-- -> S8 -> the keep's roof; S1 also opens onto the branch
	spire(S1.X, S1.Z, S1.Y, { bearing(S1, exitAt), bearing(S1, H3in), bearing(S1, BR[1]) })
	bridge(exitAt, edge(S1, exitAt), V3(373, 0, 313.6), face(S1, exitAt))
	bridge(edge(S1, H3in), H3in, face(S1, H3in), H3ia)
	spire(S2.X, S2.Z, S2.Y, { bearing(S2, H3out), bearing(S2, S3) })
	bridge(H3out, edge(S2, H3out), H3oa, face(S2, H3out))
	spire(S3.X, S3.Z, S3.Y, { bearing(S3, S2), bearing(S3, H1in) })
	bridge(edge(S2, S3), edge(S3, S2), face(S2, S3), face(S3, S2))
	bridge(edge(S3, H1in), H1in, face(S3, H1in), H1ia)
	spire(S5.X, S5.Z, S5.Y, { bearing(S5, H1out), bearing(S5, S6) })
	bridge(H1out, edge(S5, H1out), H1oa, face(S5, H1out))
	spire(S6.X, S6.Z, S6.Y, { bearing(S6, S5), bearing(S6, S7) })
	bridge(edge(S5, S6), edge(S6, S5), face(S5, S6), face(S6, S5))
	-- S7, the stair spire: a stair wound a turn and a quarter round its outside on long corbels, from where the bridge
	-- from S6 meets it up 24 to its top (a smaller one, radius 9: the stair stands clear outside it)
	local b0 = bearing(S7, S6)
	local SPIN, STEPS, SRAD, SW_ = math.rad(450), 30, 13.5, 8
	local stair = {}
	for i = 0, STEPS do
		local a = b0 + SPIN * i / STEPS
		table.insert(stair, V3(S7.X + math.cos(a) * SRAD, S7.Y - 24 + 24 * i / STEPS, S7.Z + math.sin(a) * SRAD))
	end
	local aEnd = b0 + SPIN
	table.insert(stair, V3(S7.X + math.cos(aEnd) * 6, S7.Y, S7.Z + math.sin(aEnd) * 6)) -- (and in onto its top)
	local onto = V3(S7.X + math.cos(b0) * (SRAD + SW_ / 2), stair[1].Y, S7.Z + math.sin(b0) * (SRAD + SW_ / 2))
	bridge(edge(S6, S7), onto, face(S6, S7), face(S7, S6))
	for i = 1, #stair - 1 do
		local a, b = stair[i], stair[i + 1]
		local len = (b - a).Magnitude
		local cf = CFrame.lookAt((a + b) / 2, b)
		blk("Stair", V3(SW_, 1.2, len + 0.6), cf * CFrame.new(0, -0.6, 0), MAT.Slate, WALK)
		blk("StairPad", V3(SW_ + 0.4, 1.2, SW_ * 0.5), CFrame.new(a - V3(0, 0.66, 0)) * CFrame.lookAt(a, V3(b.X, a.Y, b.Z)).Rotation, MAT.Slate, WALK)
		local inner = i < #stair - 1 -- (the last stretch, in onto the top, has no parapets: nothing across the way on)
		if inner then
			local cut = i == #stair - 2 and 4.5 or 0
			for _, sx in ipairs({ -1, 1 }) do
				local outer = sx < 0 -- (the stair winds with increasing angle: its left side is the outside)
				if not (outer and i <= 2) and len + 0.3 - cut > 0.5 then
					blk("Parapet", V3(0.9, 2.2, len + 0.3 - cut), cf * CFrame.new(sx * (SW_ / 2 + 0.45), 1.1, cut / 2), MAT.Slate, PARA)
					blk("Coping", V3(1.3, 0.35, len + 0.5 - cut), cf * CFrame.new(sx * (SW_ / 2 + 0.45), 2.37, cut / 2), MAT.Slate, GOTH_LT)
				end
			end
			if i % 3 == 0 then -- (long stepped corbels under it, out of the shaft)
				local ang = b0 + SPIN * (i - 1) / STEPS
				local d = V3(math.cos(ang), 0, math.sin(ang))
				local y = a.Y - 1.2
				blk("StairCorbel", V3(2, 2.2, SRAD + SW_ / 2 - 7), CFrame.lookAt(S7 * V3(1, 0, 1) + d * ((SRAD + SW_ / 2 + 7) / 2) + V3(0, y - 1.1, 0), S7 * V3(1, 0, 1) + d * 30 + V3(0, y - 1.1, 0)), MAT.Slate, GOTH)
				blk("StairCorbel", V3(1.6, 2, (SRAD + SW_ / 2 - 7) * 0.6), CFrame.lookAt(S7 * V3(1, 0, 1) + d * (7 + (SRAD + SW_ / 2 - 7) * 0.3) + V3(0, y - 3.2, 0), S7 * V3(1, 0, 1) + d * 30 + V3(0, y - 3.2, 0)), MAT.Slate, GOTH_DK)
			end
			if i % 6 == 0 then
				lantern((cf * CFrame.new(SW_ / 2 + 0.45, 2.55, 0)).Position)
			end
		end
	end
	spire(S7.X, S7.Z, S7.Y, { aEnd, bearing(S7, S8) }, 9)
	bridge(edge(S7, S8, 9), edge(S8, S7), face(S7, S8), face(S8, S7))
	spire(S8.X, S8.Z, S8.Y, { bearing(S8, S7), bearing(S8, KEEP_IN) })
	bridge(edge(S8, KEEP_IN), KEEP_IN, face(S8, KEEP_IN), V3(502.5, 0, 334))
	-- the branch: S1 -> BR1 -> BR2 -> BR3 -> the tower-house -> BR4 -> BR5 -> THE CENSERY (below)
	do
		local prev = S1
		for i, sp in ipairs(BR) do
			local from = i == 4 and H2out or prev
			local to = i == 3 and H2in or BR[i + 1] or GATE_IN
			spire(sp.X, sp.Z, sp.Y, { bearing(sp, from), bearing(sp, to), i == 1 and 0 or nil }) -- (BR1: east too, where the palace's drawbridge comes down)
			if i == 4 then
				bridge(H2out, edge(sp, H2out), H2oa, face(sp, H2out))
			else
				bridge(edge(prev, sp), edge(sp, prev), face(prev, sp), face(sp, prev))
			end
			if i == 3 then
				bridge(edge(sp, H2in), H2in, face(sp, H2in), H2ia)
			end
			prev = sp
		end
		bridge(edge(BR[#BR], GATE_IN), GATE_IN, face(BR[#BR], GATE_IN), V3(296, 0, 7))
	end

	---------------------------------------------------------------------------
	-- THE CENSERY: where the branch ends, a fortress-house up over the lava, all of it one gauntlet, all of it one building.
	-- Through the gatehouse into the Blade Hall - no floor but a beam over the drop, two great blades swinging across it
	-- from the roof - a turn, the Sweep Gallery (another beam, an arm turning over it), into the Censer Hall, its floor gone
	-- too: a beam with great burning censers swinging across it on long chains, a stair up the wall, a beam above with
	-- another censer, and out through a high door into the belfry, up to its roof and the bell swinging there. No enemies: the place itself is the fight. Anything that swings or sweeps into you throws you the way it
	-- was going (init.server moves them all and does the hitting: info.Bulwark.Censery); below 70 here the fall kills.
	--   (as laid out, before the doubling below:) gatehouse x 213..231, z -12..6 | Blade Hall x 196..213, z -21.5..3.5 | the turn
	--   x 182..196, z -15..-3 | Sweep Gallery x 180..196, z -30..-15 | Censer Hall x 160..198, z -56..-30 (beams at 104 and
	--   116) | belfry x 160..180, z -30..-11, floor 116
	---------------------------------------------------------------------------
	local censery = { Hazards = {}, Center = V3(195, 112, -22), Radius = 95 }
	local doorway, turret, merlons, cornice, gable -- (the Censery's builders, defined in it: the palace uses them too)
	-- (laid out below at half its size, into a folder of its own; then every part is doubled about the gatehouse's north-east
	-- corner at its floor, (231, 104, 6), and that corner set down at (318, 104, 6): the whole place twice as big, moved east)
	local mainFolder = folder
	local cfold = Instance.new("Folder")
	cfold.Name = "Censery"
	cfold.Parent = mainFolder
	folder = cfold
	do
		local BLADE, HOT = C3(60, 54, 50), C3(255, 110, 40)
		-- a moving thing: its parts kept with their offsets from a pivot (init.server sets pivot * offset each frame)
		local function mover(kind, base, t)
			local hz = t or {}
			hz.Kind, hz.Base, hz.Parts = kind, base, {}
			local function add(name, size, off, mat, col, shape)
				local p = P({ Name = name, Shape = shape, Size = size, CFrame = base * off, Material = mat, Color = col, CanCollide = false, CanQuery = false, CanTouch = false })
				table.insert(hz.Parts, { p, off })
				return p
			end
			table.insert(censery.Hazards, hz)
			return hz, add
		end
		-- A BLADE: a great crescent on a rod, its edge glowing hot, swung across the walk (along: the walk's way)
		local function blade(pivot, along, len, amp, period, phase)
			local k = 1.5 -- (the crescent half as big again as it was)
			local T = 0.75 -- (its thickness, along the walk: a heavy slab of iron, not a sheet)
			local _, add = mover("swing", CFrame.fromMatrix(pivot, along, UPV), { Amp = amp, Period = period, Phase = phase, Damage = 0, HitOffset = CFrame.new(0, -len + 0.8 * k, 0), HitSize = V3(1.8, 4.4, 7.4) * k })
			-- the crescent: an arc of nine plates round a centre above it, concave up, its horns tapering; each plate a body,
			-- a hot edge on its outside, a darker spine on its inside. (In the pivot's space: x along the walk, y up, z across;
			-- a plate turned by -phi about x has its -y pointing out from the arc's centre.)
			local R, H, PHI, N = 3.6 * k, 1.5 * k, 1.25, 9
			local Cy = -len + R -- (the arc's centre: its lowest point is at -len)
			local SPINE = BLADE:Lerp(C3(0, 0, 0), 0.35)
			for i = 0, N - 1 do
				local a1, a2 = -PHI + 2 * PHI * i / N, -PHI + 2 * PHI * (i + 1) / N
				local am = (a1 + a2) / 2
				local taper = 1 - 0.6 * (math.abs(am) / PHI) ^ 1.6 -- (full in the middle, narrowing to the horns' points)
				local h = H * taper
				local chord = 2 * R * math.sin((a2 - a1) / 2) + 0.12
				local turn = CFrame.Angles(-am, 0, 0)
				local function on(r) -- a point r out from the arc's centre, at am
					return CFrame.new(0, Cy - math.cos(am) * r, math.sin(am) * r) * turn
				end
				add("Blade", V3(T, h, chord), on(R - h / 2), MAT.Metal, BLADE)
				add("BladeEdge", V3(T * 0.45, 0.32, chord), on(R + 0.1), MAT.Neon, HOT)
				add("BladeSpine", V3(T * 1.25, 0.34, chord * 0.98), on(R - h - 0.12), MAT.Metal, SPINE)
			end
			-- what carries it: a heavy plate down onto the middle of the crescent, braces out to either side, rivets; the rod
			-- (thick, banded), a collar, the hub
			local top = -len + H + 0.25 -- (just above the crescent's inner edge at its middle)
			add("BladeMount", V3(T * 1.4, 1.6 * k, 1.8 * k), CFrame.new(0, top + 0.6 * k, 0), MAT.Metal, IRON)
			for _, sz in ipairs({ -1, 1 }) do
				add("BladeBrace", V3(T * 1.1, 0.45 * k, 2.4 * k), CFrame.new(0, top + 0.1 * k, sz * 1.5 * k) * CFrame.Angles(sz * 0.55, 0, 0), MAT.Metal, IRON)
				for _, sy in ipairs({ 0.2, 1.0 }) do
					for _, sx in ipairs({ -1, 1 }) do
						add("Rivet", V3(0.28, 0.28, 0.28) * k, CFrame.new(sx * T * 0.72, top + sy * k, sz * 0.5 * k), MAT.Metal, C3(150, 112, 52), Enum.PartType.Ball)
					end
				end
			end
			local rodTop, rodLow = -0.5, top + 1.4 * k
			add("PendulumRod", V3(0.6, rodTop - rodLow, 0.6), CFrame.new(0, (rodTop + rodLow) / 2, 0), MAT.Metal, IRON)
			for f = 0.25, 0.76, 0.25 do
				add("RodBand", V3(0.85, 0.3, 0.85), CFrame.new(0, rodLow + (rodTop - rodLow) * f, 0), MAT.Metal, C3(150, 112, 52))
			end
			add("PendulumCollar", V3(1.1, 0.9, 1.1), CFrame.new(0, rodLow + 0.3, 0), MAT.Metal, IRON)
			add("PendulumHub", V3(1.4, 1.4, 1.4), CFrame.new(), MAT.Metal, IRON, Enum.PartType.Ball)
		end
		-- A CENSER: an iron sphere banded in gold, a stepped cap, vents glowing, fire pouring off it, on a long chain
		local function censer(pivot, along, len, amp, period, phase)
			local _, add = mover("swing", CFrame.fromMatrix(pivot, along, UPV), { Amp = amp, Period = period, Phase = phase, Damage = 32, HitOffset = CFrame.new(0, -len, 0), HitSize = V3(4.4, 4.4, 4.4) })
			add("CenserChain", V3(0.3, len - 2, 0.3), CFrame.new(0, -(len - 2) / 2, 0), MAT.Metal, IRON)
			for i = 0, 2 do
				add("CenserCap", V3(0.6, 2.6 - i * 0.7, 2.6 - i * 0.7), CFrame.new(0, -len + 1.9 + i * 0.6, 0) * UPRIGHT, MAT.Metal, IRON, Enum.PartType.Cylinder)
			end
			add("CenserBand", V3(0.45, 3.85, 3.85), CFrame.new(0, -len, 0) * UPRIGHT, MAT.Metal, C3(150, 112, 52), Enum.PartType.Cylinder)
			for i = 0, 5 do
				add("CenserVent", V3(0.3, 0.8, 0.12), CFrame.new(0, -len - 0.5, 0) * CFrame.Angles(0, i * math.pi / 3, 0) * CFrame.new(0, 0, -1.72), MAT.Neon, HOT)
			end
			local body = add("Censer", V3(3.6, 3.6, 3.6), CFrame.new(0, -len, 0), MAT.Metal, C3(46, 40, 36), Enum.PartType.Ball)
			local f = Instance.new("Fire")
			f.Size, f.Heat = 4, 9
			f.Color, f.SecondaryColor = C3(255, 110, 30), C3(120, 16, 8)
			f.Parent = body
			light(body, C3(255, 140, 60), 22, 1.4)
		end
		-- THE ARM: two iron arms on a drum at the foot of a shaft hung from a tie under the ceiling, turning flat at body
		-- height, spiked on their leading sides, weighted at their ends (half: each arm's length; shaftTop: the tie's underside)
		local function sweeper(hub, half, speed, shaftTop)
			local _, add = mover("spin", CFrame.new(hub), { Speed = speed, Damage = 0, HitOffset = CFrame.new(), HitSize = V3(half * 2 + 1, 2.4, 1.8) })
			local up = shaftTop - hub.Y
			add("SpinShaft", V3(up, 0.9, 0.9), CFrame.new(0, up / 2, 0) * UPRIGHT, MAT.Metal, IRON, Enum.PartType.Cylinder)
			add("SpinDrum", V3(1.4, 2.4, 2.4), CFrame.new(0, 0.2, 0) * UPRIGHT, MAT.Metal, IRON, Enum.PartType.Cylinder)
			add("SpinArm", V3(half * 2, 0.8, 0.8), CFrame.new(), MAT.Metal, IRON)
			add("SpinEdge", V3(half * 2 - 2.6, 0.18, 0.84), CFrame.new(0, -0.45, 0), MAT.Neon, HOT)
			for x = 2, half - 0.8, 1.6 do
				for _, s in ipairs({ -1, 1 }) do
					add("SpinSpike", V3(0.3, 0.3, 1.2), CFrame.new(s * x, 0, -0.9 * s), MAT.Metal, BLADE)
				end
			end
			for _, s in ipairs({ -1, 1 }) do
				add("SpinWeight", V3(1.4, 1.4, 1.4), CFrame.new(s * half, 0, 0), MAT.Metal, BLADE, Enum.PartType.Ball)
			end
		end
		-- a doorway through a wall: its pointed head filled above the arch, a moulded frame proud of the outside.
		-- p0: the middle of its sill on the outer face; out: outward; w wide, h high (to the arch's apex)
		function doorway(p0, w, h, across, out, depth)
			local rise = math.min(w * 0.5, 4.5)
			headFill(p0 - out * depth, w, h - rise, rise, across, out, depth, GOTH)
			pointedFrame(p0 + out * 0.3, w + 0.6, h - rise, rise + 0.3, across, out, 0.9, 1.4, GOTH_LT)
		end
		function turret(x, z, top) -- a corner turret with a cone of stacked drums, up out of the lava (it overhangs its pier)
			P({ Name = "Turret", Shape = Enum.PartType.Cylinder, Size = V3(top + 8, 5.5, 5.5), CFrame = CFrame.new(x, (top - 8) / 2, z) * UPRIGHT, Material = MAT.Basalt, Color = GOTH })
			for i = 0, 4 do
				P({ Name = "TurretCap", Shape = Enum.PartType.Cylinder, Size = V3(2.4, 6.2 - i * 1.3, 6.2 - i * 1.3), CFrame = CFrame.new(x, top + 1.2 + i * 2.4, z) * UPRIGHT, Material = MAT.Slate, Color = i % 2 == 0 and GOTH_DK or GOTH })
			end
			P({ Name = "Finial", Shape = Enum.PartType.Ball, Size = Vector3.one * 0.9, CFrame = CFrame.new(x, top + 13.4, z), Material = MAT.Metal, Color = IRON, CanCollide = false })
		end
		function merlons(x1, z1, x2, z2, y) -- battlements round a flat roof's edge: merlons with gaps between
			for x = x1 + 1, x2 - 0.9, 2.8 do
				for _, z in ipairs({ z1 + 0.7, z2 - 0.7 }) do
					B(x - 0.6, y, z - 0.7, x + 0.6, y + 2.6, z + 0.7, MAT.Basalt, GOTH, "Merlon")
				end
			end
			for z = z1 + 1, z2 - 0.9, 2.8 do
				for _, x in ipairs({ x1 + 0.7, x2 - 0.7 }) do
					B(x - 0.7, y, z - 0.6, x + 0.7, y + 2.6, z + 0.6, MAT.Basalt, GOTH, "Merlon")
				end
			end
		end
		local function pier(x1, z1, x2, z2, top) -- a block of a building's foot, out of the lava: battered, coursed, arcaded
			B(x1, -8, z1, x2, top, z2, MAT.Basalt, GOTH_DK, "CenseryPier")
			B(x1 - 4, -8, z1 - 4, x2 + 4, 10, z2 + 4, MAT.Basalt, STONE_DK, "CenseryPierFoot")
			for y = 24, top - 10, 22 do
				B(x1 - 0.4, y, z1 - 0.4, x2 + 0.4, y + 0.9, z2 + 0.4, MAT.Slate, GOTH_LT, "PierCourse")
			end
			for _, fc in ipairs({ { V3(x1 - 0.02, 0, (z1 + z2) / 2), V3(-1, 0, 0), z2 - z1 }, { V3(x2 + 0.02, 0, (z1 + z2) / 2), V3(1, 0, 0), z2 - z1 }, { V3((x1 + x2) / 2, 0, z1 - 0.02), V3(0, 0, -1), x2 - x1 }, { V3((x1 + x2) / 2, 0, z2 + 0.02), V3(0, 0, 1), x2 - x1 } }) do
				local across = fc[2]:Cross(UPV).Unit
				for o = -fc[3] / 2 + 4, fc[3] / 2 - 3.9, 8 do
					lancet(fc[1] + across * o + V3(0, 32, 0), 3, 14, across, fc[2], GOTH)
				end
			end
		end
		function cornice(x1, z1, x2, z2, y1, y2) -- a moulding round a building's walls at their top: a ring, 1.4 in, 0.4 out
			B(x1 - 0.4, y1, z1 - 0.4, x2 + 0.4, y2, z1 + 1.4, MAT.Slate, GOTH_LT, "Cornice")
			B(x1 - 0.4, y1, z2 - 1.4, x2 + 0.4, y2, z2 + 0.4, MAT.Slate, GOTH_LT, "Cornice")
			B(x1 - 0.4, y1, z1 + 1.4, x1 + 1.4, y2, z2 - 1.4, MAT.Slate, GOTH_LT, "Cornice")
			B(x2 - 1.4, y1, z1 + 1.4, x2 + 0.4, y2, z2 - 1.4, MAT.Slate, GOTH_LT, "Cornice")
		end
		-- a steep slate gable over x1..x2, z1..z2 from eave EY, Hg high; its ridge along x (alongX) or along z; the gable ends
		-- walled in (a wedge either side of the ridge), a crest of iron spikes down the ridge
		function gable(x1, z1, x2, z2, EY, Hg, alongX)
			local cx, cz = (x1 + x2) / 2, (z1 + z2) / 2
			local half = alongX and (z2 - z1) / 2 or (x2 - x1) / 2
			local ang = math.atan2(Hg, half)
			local sw = math.sqrt(half * half + Hg * Hg) + 1.4
			for _, sd in ipairs({ -1, 1 }) do
				if alongX then
					blk("Roof", V3(x2 - x1 + 1, 1, sw), CFrame.new(cx, EY + Hg / 2 + 0.4, cz + sd * half / 2) * CFrame.Angles(sd * ang, 0, 0), MAT.Slate, GOTH_DK)
					for _, x in ipairs({ x1 + 0.7, x2 - 0.7 }) do
						local at = V3(x, EY + Hg / 2, cz + sd * half / 2)
						wedge("Gable", V3(1.4, Hg, half), CFrame.lookAt(at, at + V3(0, 0, sd)), GOTH)
					end
				else
					blk("Roof", V3(sw, 1, z2 - z1 + 1), CFrame.new(cx + sd * half / 2, EY + Hg / 2 + 0.4, cz) * CFrame.Angles(0, 0, -sd * ang), MAT.Slate, GOTH_DK)
					for _, z in ipairs({ z1 + 0.7, z2 - 0.7 }) do
						local at = V3(cx + sd * half / 2, EY + Hg / 2, z)
						wedge("Gable", V3(1.4, Hg, half), CFrame.lookAt(at, at + V3(sd, 0, 0)), GOTH)
					end
				end
			end
			local len = alongX and x2 - x1 or z2 - z1
			for d = 0, len + 0.01, 3 do
				local p = alongX and V3(x1 + d, EY + Hg + 1.1, cz) or V3(cx, EY + Hg + 1.1, z1 + d)
				blk("RidgeCrest", V3(0.5, 1.4, 0.5), CFrame.new(p) * CFrame.Angles(0, math.pi / 4, 0), MAT.Metal, IRON, false)
			end
		end
		local function stair(A, Bp, w) -- a wooden stair from A to Bp (their treads' height), open at its sides
			local len = (Bp - A).Magnitude
			local scf = CFrame.lookAt((A + Bp) / 2, Bp)
			blk("Stair", V3(w, 1, len), scf * CFrame.new(0, -0.5, 0), MAT.WoodPlanks, WOOD)
			for i = 1, math.floor(len / 1.4) do
				blk("Nosing", V3(w, 0.12, 0.25), scf * CFrame.new(0, 0.04, len / 2 - i * 1.4), MAT.Wood, WOOD_DK, false)
			end
		end

		-- (one building: the gatehouse; west of it the Blade Hall; the turn; south of that the Sweep Gallery; south again the
		-- Censer Hall; and the belfry against the hall's north wall. Each shares its walls with the next, every door is in a
		-- shared wall, and every wall goes down into the lava. The halls with blades, the arm and the censers have no floor
		-- but a beam over the drop: inside walls, under a roof, and still a fall to your death off its side.)

		-- THE GATEHOUSE ------------------------------------------------------------
		pier(213, -12, 231, 6, 103)
		B(213, 103, -12, 231, 104, 6, MAT.Slate, STONE, "GateFloor")
		B(213, 104, 4.6, 215, 126, 6, MAT.Basalt, GOTH, "GateWall") -- north, the bridge's door x 215..225
		B(225, 104, 4.6, 231, 126, 6, MAT.Basalt, GOTH, "GateWall")
		B(215, 115, 4.6, 225, 126, 6, MAT.Basalt, GOTH, "GateWall")
		doorway(V3(220, 104, 6), 10, 11, V3(1, 0, 0), V3(0, 0, 1), 1.4)
		B(213, 104, -12, 214.4, 126, -11.5, MAT.Basalt, GOTH, "GateWall") -- west, into the Blade Hall (z -11.5..-6.5)
		B(213, 104, -6.5, 214.4, 126, 4.6, MAT.Basalt, GOTH, "GateWall")
		B(213, 113, -11.5, 214.4, 126, -6.5, MAT.Basalt, GOTH, "GateWall")
		doorway(V3(213, 104, -9), 5, 9, V3(0, 0, 1), V3(-1, 0, 0), 1.4)
		B(229.6, 104, -12, 231, 126, 4.6, MAT.Basalt, GOTH, "GateWall")
		B(214.4, 104, -12, 229.6, 126, -10.6, MAT.Basalt, GOTH, "GateWall")
		for _, z in ipairs({ -6, 0 }) do
			lancet(V3(231.02, 108, z), 2.6, 11, V3(0, 0, 1), V3(1, 0, 0))
		end
		for _, x in ipairs({ 218, 225 }) do
			lancet(V3(x, 108, -12.02), 2.6, 11, V3(1, 0, 0), V3(0, 0, -1))
		end
		cornice(213, -12, 231, 6, 125.2, 126)
		B(213, 126, -12, 231, 127.2, 6, MAT.Slate, GOTH_DK, "GateRoof")
		merlons(213, -12, 231, 6, 127.2)
		for _, c in ipairs({ { 213, 6 }, { 231, -12 }, { 231, 6 } }) do
			turret(c[1], c[2], 132)
		end
		for i = 0, 5 do
			blk("TowerSpire", V3(7 - i * 1.1, 3.4, 7 - i * 1.1), CFrame.new(222, 128.9 + i * 3.4, -3) * CFrame.Angles(0, (i % 2) * math.pi / 4, 0), MAT.Slate, i % 2 == 0 and GOTH_DK or GOTH)
		end
		pinnacle(V3(222, 149.4, -3), 1.6, 8)
		for _, s in ipairs({ { V3(229.6, 110, -7), V3(-1, 0, 0) }, { V3(229.6, 110, 1), V3(-1, 0, 0) }, { V3(222, 110, 4.6), V3(0, 0, -1) } }) do
			sconce(s[1], s[2])
		end
		blk("Banner", V3(4.5, 12, 0.15), CFrame.new(222, 116, -10.4), MAT.Fabric, C3(96, 18, 12), false)

		-- THE BLADE HALL: x 196..213, z -21.5..3.5, its eave at 124. A beam from the gatehouse door to the turn's, the drop
		-- either side; two blades hung from ties across it, swinging over the beam from wall to wall
		B(196, -8, -21.5, 213, 124, -20.1, MAT.Basalt, GOTH, "HallWall")
		B(196, -8, 2.1, 213, 124, 3.5, MAT.Basalt, GOTH, "HallWall")
		B(213, -8, -21.5, 214.4, 124, -12, MAT.Basalt, GOTH, "HallWall") -- (east, past the gatehouse's side)
		B(194.6, -8, -3, 196, 124, 3.5, MAT.Basalt, GOTH, "HallWall") -- (west, past the turn's side; the rest is the turn's wall and the gallery's)
		B(196, 102.8, -11, 213.4, 104, -7, MAT.Slate, WALK, "HallBeam")
		B(196.5, 101.2, -10.5, 212.9, 102.8, -7.5, MAT.Basalt, GOTH_DK, "BeamBody")
		for i, x in ipairs({ 207, 201.5 }) do
			blk("BladeTie", V3(0.9, 0.9, 22.2), CFrame.new(x, 118.9, -9), MAT.Metal, IRON, false)
			blade(V3(x, 118, -9), V3(-1, 0, 0), 12, 0.7, 5.6, (i - 1) * 2.6)
		end
		cornice(196, -21.5, 213, 3.5, 123.2, 124)
		gable(196, -21.5, 213, 3.5, 124, 9, true)
		for _, x in ipairs({ 200, 205.5, 210.5 }) do
			lancet(V3(x, 108, 3.52), 2.4, 10, V3(1, 0, 0), V3(0, 0, 1))
			lancet(V3(x, 108, -21.52), 2.4, 10, V3(1, 0, 0), V3(0, 0, -1))
		end
		sconce(V3(204.5, 112, 2.1), V3(0, 0, -1))
		sconce(V3(204.5, 112, -20.1), V3(0, 0, 1))
		embers(V3(204.5, 70, -9), V3(14, 2, 20), 6)

		-- THE TURN: a small square room on its own pier, x 182..196, z -15..-3, a floor under you at last; doors east (from the
		-- Blade Hall) and south (into the Sweep Gallery)
		pier(182, -15, 196, -3, 103)
		B(182, 103, -15, 196, 104, -3, MAT.Slate, STONE, "TurnFloor")
		B(194.6, 104, -15, 196, 124, -12, MAT.Basalt, GOTH, "TurnWall")
		B(194.6, 104, -6, 196, 124, -3, MAT.Basalt, GOTH, "TurnWall")
		B(194.6, 113, -12, 196, 124, -6, MAT.Basalt, GOTH, "TurnWall")
		doorway(V3(196, 104, -9), 6, 9, V3(0, 0, 1), V3(1, 0, 0), 1.4)
		B(182, 104, -15, 185, 124, -13.6, MAT.Basalt, GOTH, "TurnWall")
		B(191, 104, -15, 196, 124, -13.6, MAT.Basalt, GOTH, "TurnWall")
		B(185, 113, -15, 191, 124, -13.6, MAT.Basalt, GOTH, "TurnWall")
		doorway(V3(188, 104, -15), 6, 9, V3(1, 0, 0), V3(0, 0, -1), 1.4)
		B(182, 104, -13.6, 183.4, 124, -3, MAT.Basalt, GOTH, "TurnWall")
		B(183.4, 104, -4.4, 194.6, 124, -3, MAT.Basalt, GOTH, "TurnWall")
		lancet(V3(181.98, 108, -7), 2.4, 10, V3(0, 0, 1), V3(-1, 0, 0))
		for _, x in ipairs({ 186, 192 }) do
			lancet(V3(x, 108, -2.98), 2.4, 10, V3(1, 0, 0), V3(0, 0, 1))
		end
		cornice(182, -15, 196, -3, 123.2, 124)
		B(182, 124, -15, 196, 125.2, -3, MAT.Slate, GOTH_DK, "TurnRoof")
		merlons(182, -15, 196, -3, 125.2)
		turret(182, -3, 130)
		for i = 0, 4 do
			blk("TowerSpire", V3(5.6 - i * 1, 3, 5.6 - i * 1), CFrame.new(189, 126.7 + i * 3, -9) * CFrame.Angles(0, (i % 2) * math.pi / 4, 0), MAT.Slate, i % 2 == 0 and GOTH_DK or GOTH)
		end
		pinnacle(V3(189, 140.2, -9), 1.4, 6)
		sconce(V3(183.4, 110, -9), V3(1, 0, 0))
		blk("Banner", V3(4.5, 11, 0.15), CFrame.new(189, 115, -4.2), MAT.Fabric, C3(96, 18, 12), false)

		-- THE SWEEP GALLERY: x 180..196, z -30..-15, its eave at 124. A beam from the turn's door to the Censer Hall's, the
		-- drop either side; the arm turning over it, hung from a tie under the roof
		B(180, -8, -30, 181.4, 124, -15, MAT.Basalt, GOTH, "HallWall")
		B(180, -8, -15, 182, 124, -13.6, MAT.Basalt, GOTH, "HallWall") -- (closing the corner by the turn)
		B(194.6, -8, -30, 196, 124, -15, MAT.Basalt, GOTH, "HallWall") -- (the Blade Hall's west wall too, along z -21.5..-15)
		B(186, 102.8, -30.6, 190, 104, -15, MAT.Slate, WALK, "HallBeam")
		B(186.5, 101.2, -30.6, 189.5, 102.8, -15, MAT.Basalt, GOTH_DK, "BeamBody")
		blk("SpinnerTie", V3(13.2, 0.9, 0.9), CFrame.new(188, 122.9, -22.5), MAT.Metal, IRON, false)
		sweeper(V3(188, 106.3, -22.5), 5.6, 0.9, 122.45) -- (5.6: its weights clear the walls)
		cornice(180, -30, 196, -15, 123.2, 124)
		gable(180, -30, 196, -15, 124, 7, false)
		lancet(V3(196.02, 108, -26), 2.4, 10, V3(0, 0, 1), V3(1, 0, 0))
		sconce(V3(181.4, 112, -22.5), V3(1, 0, 0))
		sconce(V3(194.6, 112, -27), V3(-1, 0, 0))
		embers(V3(188, 70, -22.5), V3(12, 2, 12), 5)

		-- THE CENSER HALL ------------------------------------------------------------
		local HY, EY = -8, 140 -- its walls' foot (down into the lava, like the rest) and their top
		for _, c in ipairs({ { 160, -56 }, { 198, -56 }, { 160, -30 }, { 198, -30 } }) do -- great round towers at its corners
			P({ Name = "HallTower", Shape = Enum.PartType.Cylinder, Size = V3(EY + 6 + 8, 7, 7), CFrame = CFrame.new(c[1], (EY + 6 - 8) / 2, c[2]) * UPRIGHT, Material = MAT.Basalt, Color = GOTH })
			P({ Name = "HallTowerFoot", Shape = Enum.PartType.Cylinder, Size = V3(18, 11, 11), CFrame = CFrame.new(c[1], 1, c[2]) * UPRIGHT, Material = MAT.Basalt, Color = STONE_DK })
			for y = 30, EY - 10, 22 do
				P({ Name = "TowerCourse", Shape = Enum.PartType.Cylinder, Size = V3(0.9, 7.6, 7.6), CFrame = CFrame.new(c[1], y, c[2]) * UPRIGHT, Material = MAT.Slate, Color = GOTH_LT })
			end
			for i = 0, 4 do
				P({ Name = "TurretCap", Shape = Enum.PartType.Cylinder, Size = V3(2.6, 7.6 - i * 1.5, 7.6 - i * 1.5), CFrame = CFrame.new(c[1], EY + 7.3 + i * 2.6, c[2]) * UPRIGHT, Material = MAT.Slate, Color = i % 2 == 0 and GOTH_DK or GOTH })
			end
			P({ Name = "Finial", Shape = Enum.PartType.Ball, Size = Vector3.one, CFrame = CFrame.new(c[1], EY + 20.4, c[2]), Material = MAT.Metal, Color = IRON, CanCollide = false })
		end
		-- the walls: north (two doors: in at 104 from the Sweep Gallery, out at 116 into the belfry), the others whole
		B(160, HY, -31.4, 165, EY, -30, MAT.Basalt, GOTH, "HallWall")
		B(165, HY, -31.4, 171, 116, -30, MAT.Basalt, GOTH, "HallWall")
		B(165, 125, -31.4, 171, EY, -30, MAT.Basalt, GOTH, "HallWall")
		B(171, HY, -31.4, 185, EY, -30, MAT.Basalt, GOTH, "HallWall")
		B(185, HY, -31.4, 191, 104, -30, MAT.Basalt, GOTH, "HallWall")
		B(185, 113, -31.4, 191, EY, -30, MAT.Basalt, GOTH, "HallWall")
		B(191, HY, -31.4, 198, EY, -30, MAT.Basalt, GOTH, "HallWall")
		doorway(V3(188, 104, -30), 6, 9, V3(1, 0, 0), V3(0, 0, 1), 1.4)
		doorway(V3(168, 116, -30), 6, 9, V3(1, 0, 0), V3(0, 0, 1), 1.4)
		B(160, HY, -56, 198, EY, -54.6, MAT.Basalt, GOTH, "HallWall")
		B(160, HY, -54.6, 161.4, EY, -31.4, MAT.Basalt, GOTH, "HallWall")
		B(196.6, HY, -54.6, 198, EY, -31.4, MAT.Basalt, GOTH, "HallWall")
		for _, b in ipairs({ { 159.4, -56.6, 198.6, -54.6 }, { 159.4, -54.6, 161.4, -31.4 }, { 196.6, -54.6, 198.6, -31.4 } }) do
			B(b[1], 88.8, b[2], b[3], 90, b[4], MAT.Slate, GOTH_LT, "HallCourse") -- (a string course round its outer faces)
		end
		cornice(160, -56, 198, -30, EY - 0.8, EY)
		-- outside: lancets down the south wall, buttresses with pinnacles, rose windows high in the gable ends
		for x = 164, 194, 7.5 do
			lancet(V3(x, 104, -56.02), 2.6, 11, V3(1, 0, 0), V3(0, 0, -1))
			lancet(V3(x, 124, -56.02), 2.6, 11, V3(1, 0, 0), V3(0, 0, -1))
		end
		for _, x in ipairs({ 168, 179, 190 }) do
			B(x - 1.2, HY, -58.4, x + 1.2, EY - 4, -56, MAT.Basalt, GOTH, "Buttress")
			pinnacle(V3(x, EY - 4, -57.2), 1.3, 5)
		end
		local CZ = -43
		gable(160, -56, 198, -30, EY, 14, true)
		for _, e in ipairs({ { 159.95, -1 }, { 198.05, 1 } }) do
			rose(V3(e[1], EY + 14 * 0.36, CZ), 4, V3(e[2], 0, 0))
			pinnacle(V3(e[1], EY + 14.5, CZ), 1.4, 6)
		end
		-- inside, the way across (all of it open to the drop): the beam in, the platform at the far wall, the stair up the
		-- south wall, the landing, the upper beam, the landing by the high door
		B(186, 102.8, -44, 190, 104, -30.6, MAT.Slate, WALK, "HallBeam")
		B(182, 102.8, -54.6, 194, 104, -44, MAT.Slate, WALK, "HallPlatform")
		stair(V3(186, 103.9, -51), V3(174, 115.9, -51), 4) -- (its head at the landing's edge, x 174: not under it)
		B(161.4, 114.8, -54.6, 174, 116, -44, MAT.Slate, WALK, "HallLanding")
		B(168, 114.8, -44, 172, 116, -38, MAT.Slate, WALK, "HallBeam")
		B(161.4, 114.8, -38, 176, 116, -31.4, MAT.Slate, WALK, "HallLanding")
		for _, b in ipairs({ { 186, 190, -44, -30.6, 103.4 }, { 182, 194, -54.6, -44, 103.4 }, { 161.4, 174, -54.6, -44, 115.4 }, { 168, 172, -44, -38, 115.4 }, { 161.4, 176, -38, -31.4, 115.4 } }) do
			B(b[1] + 0.5, b[5] - 1.6, b[3], b[2] - 0.5, b[5] - 0.6, b[4], MAT.Basalt, GOTH_DK, "BeamBody") -- (the stone under each)
		end
		-- what holds them up: iron hangers to the ties under the roof (none where a censer swings)
		for _, x in ipairs({ 168, 172, 186, 190 }) do
			blk("RoofTie", V3(0.8, 0.8, 23.2), CFrame.new(x, EY - 2.6, CZ), MAT.Metal, IRON, false)
		end
		for _, h in ipairs({ { 186, -37.75, 104 }, { 190, -37.75, 104 }, { 186, -44, 104 }, { 190, -44, 104 }, { 194, -44, 104 }, { 168, -36.5, 116 }, { 172, -36.5, 116 }, { 172, -44, 116 }, { 174, -44, 116 } }) do
			blk("Hanger", V3(0.25, EY - 2.6 - h[3], 0.25), CFrame.new(h[1], (EY - 2.6 + h[3]) / 2, h[2]), MAT.Metal, IRON, false)
		end
		-- the censers: two over the beam in, one over the upper beam, swinging across them
		censer(V3(188, 136.5, -35), V3(0, 0, 1), 30.3, 0.22, 6.4, 0)
		censer(V3(188, 136.5, -40.5), V3(0, 0, 1), 30.3, 0.22, 6.4, 3.6)
		censer(V3(170, 136.5, -40.5), V3(0, 0, 1), 18.3, 0.36, 5.0, 1.0)
		blk("CenserTie", V3(4.8, 0.6, 0.6), CFrame.new(188, 137.4, -35), MAT.Metal, IRON, false)
		blk("CenserTie", V3(4.8, 0.6, 0.6), CFrame.new(188, 137.4, -40.5), MAT.Metal, IRON, false)
		blk("CenserTie", V3(4.8, 0.6, 0.6), CFrame.new(170, 137.4, -40.5), MAT.Metal, IRON, false)
		-- light: lamps on the walls at both levels, a fire basin on the platform, embers rising out of the drop
		for _, s in ipairs({ { V3(161.4, 109, -42), V3(1, 0, 0) }, { V3(196.6, 109, -48), V3(-1, 0, 0) }, { V3(196.6, 121, -38), V3(-1, 0, 0) }, { V3(179, 121, -54.6), V3(0, 0, 1) }, { V3(161.4, 122, -50), V3(1, 0, 0) }, { V3(176, 109, -31.4), V3(0, 0, -1) } }) do
			sconce(s[1], s[2])
		end
		P({ Name = "Basin", Shape = Enum.PartType.Cylinder, Size = V3(1.2, 2.6, 2.6), CFrame = CFrame.new(192.4, 104.6, -53) * UPRIGHT, Material = MAT.Metal, Color = IRON })
		fire(V3(192.4, 105.6, -53), 3.5)
		embers(V3(179, 80, -43), V3(30, 2, 18), 10)

		-- THE BELFRY: x 160..180, z -30..-11, against the Censer Hall's north wall (that wall is its south one, the high door
		-- in it); stairs inside up to a hatch, the bell on the battlemented roof
		pier(160, -30, 180, -11, 115)
		B(160, 115, -30, 180, 116, -11, MAT.Slate, STONE, "BelfryFloor")
		B(160, 116, -30, 161.4, 132, -11, MAT.Basalt, GOTH, "BelfryWall")
		B(161.4, 116, -12.4, 178.6, 132, -11, MAT.Basalt, GOTH, "BelfryWall")
		B(178.6, 116, -30, 180, 132, -12.4, MAT.Basalt, GOTH, "BelfryWall")
		for _, z in ipairs({ -24, -17 }) do
			lancet(V3(159.98, 120, z), 2.4, 10, V3(0, 0, 1), V3(-1, 0, 0))
		end
		for _, x in ipairs({ 165, 172 }) do
			lancet(V3(x, 120, -10.98), 2.4, 10, V3(1, 0, 0), V3(0, 0, 1))
		end
		-- up inside: a flight along the east wall, a landing, a flight back along the north wall to a hatch in the roof
		stair(V3(176.6, 115.9, -27), V3(176.6, 123.9, -16.4), 4)
		B(174.6, 123, -16.4, 178.6, 124, -12.4, MAT.WoodPlanks, WOOD, "BelfryLanding")
		stair(V3(174.6, 123.9, -14.4), V3(166, 133.1, -14.4), 4)
		sconce(V3(161.4, 121, -21), V3(1, 0, 0))
		sconce(V3(178.6, 121, -29), V3(-1, 0, 0))
		-- the roof: flat, battlemented; the hatch the length of the second flight (x 161.4..174.6, z -16.4..-12.4), so no head
		-- meets the roof on the way up; an open frame in the middle with the bell in it
		B(160, 132, -30, 180, 133.2, -16.4, MAT.Slate, GOTH_DK, "BelfryRoof")
		B(174.6, 132, -16.4, 180, 133.2, -11, MAT.Slate, GOTH_DK, "BelfryRoof")
		B(160, 132, -12.4, 174.6, 133.2, -11, MAT.Slate, GOTH_DK, "BelfryRoof")
		B(160, 132, -16.4, 161.4, 133.2, -12.4, MAT.Slate, GOTH_DK, "BelfryRoof")
		cornice(160, -30, 180, -11, 131.2, 132)
		merlons(160, -30, 180, -11, 133.2)
		for _, c in ipairs({ { 180, -30 }, { 160, -11 }, { 180, -11 } }) do
			pinnacle(V3(c[1], 135.8, c[2]), 1.6, 6)
		end
		-- (the bell in its frame, on the roof's middle at (170, -23): built full size after the doubling - bell(), below)
	end
	do -- DOUBLED: every part twice the size, about (231, 104, 6), that point set at (318, 104, 6); lights and fire with it;
		-- the moving things' pivots, offsets and hit boxes the same
		local S, O, O2 = 2, V3(231, 104, 6), V3(318, 104, 6)
		local function T(p)
			return O2 + (p - O) * S
		end
		local function TCF(cf)
			return CFrame.new(T(cf.Position)) * cf.Rotation
		end
		local function grow(cf)
			return CFrame.new(cf.Position * S) * cf.Rotation
		end
		for _, d in ipairs(cfold:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Size *= S
				d.CFrame = TCF(d.CFrame)
			elseif d:IsA("PointLight") then
				d.Range = math.min(d.Range * S, 60)
			elseif d:IsA("Fire") then
				d.Size = math.min(d.Size * S, 30)
				d.Heat *= 1.5
			end
		end
		for _, hz in ipairs(censery.Hazards) do
			hz.Base = TCF(hz.Base)
			for _, e in ipairs(hz.Parts) do
				e[2] = grow(e[2])
			end
			hz.HitOffset, hz.HitSize = grow(hz.HitOffset), hz.HitSize * S
		end
		censery.Center, censery.Radius = T(censery.Center), censery.Radius * S
		-- (dev: on the bridge, 12 short of the gatehouse door, facing it)
		local back = V3(BR[#BR].X - GATE_IN.X, 0, BR[#BR].Z - GATE_IN.Z).Unit
		local at = GATE_IN + back * 12 + V3(0, 3.2, 0)
		censery.Dev = CFrame.lookAt(at, V3(GATE_IN.X, at.Y, GATE_IN.Z))
		table.insert(info.Zones, 1, { Name = "The Censery", MinX = 160, MaxX = 324, MinZ = -134, MaxZ = 28, MinY = 96 })
	end
	folder = mainFolder
	-- THE BELLS: one on the Censery's belfry, one on the keep's roof where the beacon burned - the same bell in the same
	-- frame. Each hangs still till it's rung (a prompt on its lip); init.server swings and tolls it, and once both have
	-- rung, the palace's drawbridge comes down onto BR1 (info.Bulwark.Bells, .Drawbridge). base: the middle of its
	-- frame's foot; s: its scale (2: as the Censery's was, doubled)
	local bells = {}
	local function bell(base, s)
		local BELL = C3(92, 70, 40)
		local function at(x, y, z)
			return base + V3(x, y, z) * s
		end
		for _, c in ipairs({ { -5.5, -3.5 }, { 5.5, -3.5 }, { -5.5, 3.5 }, { 5.5, 3.5 } }) do -- four piers out of its plane (it swings along z), beams over them
			blk("BellPier", V3(1.8, 9.4, 1.8) * s, CFrame.new(at(c[1], 4.7, c[2])), MAT.Slate, GOTH)
			pinnacle(at(c[1], 9.4, c[2]), 1.2 * s, 4 * s)
		end
		for _, z in ipairs({ -3.5, 3.5 }) do
			blk("BellBeam", V3(12.8, 0.8, 0.8) * s, CFrame.new(at(0, 9, z)), MAT.Wood, WOOD_DK)
		end
		blk("BellYokeBeam", V3(0.8, 0.8, 7.8) * s, CFrame.new(at(0, 9, 0)), MAT.Wood, WOOD_DK)
		local b = { Base = CFrame.fromMatrix(at(0, 8.6, 0), V3(1, 0, 0), UPV), Parts = {} } -- (pivot: the yoke beam's underside, which it hangs from)
		local function add(name, size, off, mat, col, shape) -- (each part kept with its offset from the pivot)
			off = CFrame.new(off.Position * s) * off.Rotation
			local p = P({ Name = name, Size = size * s, CFrame = b.Base * off, Material = mat, Color = col })
			if shape then
				p.Shape = shape
			end
			table.insert(b.Parts, { p, off })
			return p
		end
		-- the bell: stepped drums widening to its lip, a clapper
		-- iron straps up from the bell's yoke round the beam above, and the crown it hangs by
		for _, x in ipairs({ -0.55, 0.55 }) do
			add("BellStrap", V3(0.3, 2.8, 0.95), CFrame.new(x, -0.75, 0), MAT.Metal, IRON)
		end
		add("BellStrapTop", V3(1.4, 0.25, 0.95), CFrame.new(0, 0.9, 0), MAT.Metal, IRON) -- (over the beam's top)
		add("BellCrown", V3(0.8, 2.2, 0.8), CFrame.new(0, -3, 0), MAT.Metal, BELL)
		add("BellYoke", V3(3, 0.8, 0.8), CFrame.new(0, -1.7, 0), MAT.Wood, WOOD_DK)
		for i = 0, 3 do
			add("Bell", V3(1, 1.8 + i * 0.75, 1.8 + i * 0.75), CFrame.new(0, -4.5 - i * 0.9, 0) * UPRIGHT, MAT.Metal, BELL, Enum.PartType.Cylinder)
		end
		local lip = add("BellLip", V3(0.4, 4.6, 4.6), CFrame.new(0, -7.8, 0) * UPRIGHT, MAT.Metal, BELL:Lerp(C3(0, 0, 0), 0.25), Enum.PartType.Cylinder)
		add("BellClapper", V3(0.9, 0.9, 0.9), CFrame.new(0, -7.6, 0), MAT.Metal, IRON, Enum.PartType.Ball)
		b.Prompt = prompt(lip, "Ring", "Great Bell", 0.6, 7 * s)
		light(ghost(at(0, 6.8, 0)), C3(255, 165, 100), 50, 1.4)
		table.insert(bells, b)
	end
	bell(V3(196, 162.4, -52), 2) -- (the belfry roof's middle, (170, 133.2, -23) as laid out, doubled)
	-- spires that stand alone in the lava, broken or whole, pinnacled (no bridges: they make it a forest of them)
	local LONE = { { 370, 380, 70 }, { 440, 270, 84 }, { 590, 360, 96 }, { 600, 250, 70 }, { 470, 470, 78 }, { 560, 470, 90 }, { 380, 200, 60 }, { 520, 200, 80 }, { 610, 450, 66 }, { 310, 92, 74 }, { 190, 90, 62 }, { 230, 100, 80 }, { 160, 100, 66 }, { 165, 40, 70 }, { 240, 185, 58 } } -- (the last four's places kept clear of the Censery)
	local gone = Instance.new("Folder") -- (those where the palace stands now: built into this, then thrown away)
	for _, d in ipairs(LONE) do
		local h = d[3]
		folder = (d[1] > 404 and d[1] < 612 and d[2] > 150 and d[2] < 300) and gone or mainFolder
		P({ Name = "Spire", Shape = Enum.PartType.Cylinder, Size = V3(h + 8, 12, 12), CFrame = CFrame.new(d[1], -8 + (h + 8) / 2, d[2]) * UPRIGHT, Material = MAT.Basalt, Color = STONE })
		P({ Name = "SpireFoot", Shape = Enum.PartType.Cylinder, Size = V3(14, 20, 20), CFrame = CFrame.new(d[1], 0, d[2]) * UPRIGHT, Material = MAT.Basalt, Color = STONE_DK })
		for y = 20, h - 8, 16 do
			P({ Name = "SpireCourse", Shape = Enum.PartType.Cylinder, Size = V3(1, 13, 13), CFrame = CFrame.new(d[1], y, d[2]) * UPRIGHT, Material = MAT.Slate, Color = GOTH_LT })
		end
		for k = 0, 3 do
			local a = k * math.pi / 2 + R(0, 0.5)
			pinnacle(V3(d[1] + math.cos(a) * 5.2, h - 1, d[2] + math.sin(a) * 5.2), 1.4, 7)
		end
		for i = 0, 3 do
			P({ Name = "SpireTip", Shape = Enum.PartType.Cylinder, Size = V3(4, 10 - i * 2.4, 10 - i * 2.4), CFrame = CFrame.new(d[1], h + 2 + i * 4, d[2]) * UPRIGHT, Material = MAT.Slate, Color = i % 2 == 0 and STONE_DK or STONE })
		end
		P({ Name = "Finial", Shape = Enum.PartType.Ball, Size = Vector3.one * 1.6, CFrame = CFrame.new(d[1], h + 15, d[2]), Material = MAT.Metal, Color = IRON, CanCollide = false })
	end
	folder = mainFolder
	gone:Destroy()

	-- the lift's tower, gothic too: lancets up its faces, pinnacles at its top's corners
	for _, fc in ipairs({ { V3(341.95, 0, 328), V3(-1, 0, 0) }, { V3(370.05, 0, 328), V3(1, 0, 0) }, { V3(356, 0, 313.95), V3(0, 0, -1) }, { V3(356, 0, 342.05), V3(0, 0, 1) } }) do
		local across = fc[2]:Cross(UPV).Unit
		for _, y in ipairs({ 28, 52, 72 }) do
			for _, o in ipairs({ -6, 6 }) do
				lancet(fc[1] + across * o + V3(0, y, 0), 2.4, 10, across, fc[2])
			end
		end
	end
	for _, c in ipairs({ { 336, 308 }, { 376, 308 }, { 336, 348 }, { 376, 348 } }) do
		pinnacle(V3(c[1], RING_Y, c[2]), 2.2, 9)
	end
	-- the Bulwark's bonfire, at the top of the lift, in its north-west corner (where a lantern stood)
	if makeBonfire then
		makeBonfire(V3(340, RING_Y, 312.6), CFrame.lookAt(V3(341, RING_Y + 3.2, 320), V3(340, RING_Y + 3.2, 312.6)), "Pyralis Bulwark")
	end
	for _, c in ipairs({ { 372, 344 }, { 340, 344 }, { 356, 309.5 }, { 356, 346.5 } }) do -- (lanterns round its top)
		blk("LanternPost", V3(0.6, 3.4, 0.6), CFrame.new(c[1], RING_Y + 1.6, c[2]), MAT.Metal, IRON)
		lantern(V3(c[1], RING_Y + 3.3, c[2]))
	end
	for _, fc in ipairs({ { V3(341.4, 0, 328), V3(-1, 0, 0) }, { V3(370.6, 0, 328), V3(1, 0, 0) }, { V3(356, 0, 313.4), V3(0, 0, -1) }, { V3(356, 0, 342.6), V3(0, 0, 1) } }) do
		for _, y in ipairs({ 40, 64 }) do -- (and lamps on its outside, lighting its walls)
			sconce(fc[1] + V3(0, y, 0), fc[2])
		end
	end

	-- THE KEEP, on its pedestal: a great block of rock out of the lava (x 452..508, z 302..358, to 80), the keep on it
	-- (44 square, x 458..502, z 308..352), its roof at 120, turrets at its corners; a sealed gate in its west face over the
	-- drop; the beacon on the roof
	local KX1, KX2, KZ1, KZ2, KY = C.X - 22, C.X + 22, C.Z - 22, C.Z + 22, 120
	B(KX1 - 6, -8, KZ1 - 6, KX2 + 6, 80, KZ2 + 6, MAT.Basalt, STONE_DK, "KeepPedestal")
	B(KX1 - 10, -8, KZ1 - 10, KX2 + 10, 14, KZ2 + 10, MAT.Basalt, STONE_DK, "KeepPedestalFoot")
	for _, fc in ipairs({ { V3(KX1 - 6.02, 0, C.Z), V3(-1, 0, 0) }, { V3(KX2 + 6.02, 0, C.Z), V3(1, 0, 0) }, { V3(C.X, 0, KZ1 - 6.02), V3(0, 0, -1) }, { V3(C.X, 0, KZ2 + 6.02), V3(0, 0, 1) } }) do
		local across = fc[2]:Cross(UPV).Unit -- (blind arcading down the pedestal)
		for o = -24, 24.1, 8 do
			lancet(fc[1] + across * o + V3(0, 30, 0), 3.4, 22, across, fc[2], GOTH)
		end
	end
	B(KX1, 80, KZ1, KX2, KY, KZ2, MAT.Basalt, STONE, "Keep")
	B(KX1 - 0.6, KY - 2, KZ1 - 0.6, KX2 + 0.6, KY - 0.8, KZ2 + 0.6, MAT.Slate, TRIM, "KeepCourse")
	B(KX1 - 0.6, 86, KZ1 - 0.6, KX2 + 0.6, 87.2, KZ2 + 0.6, MAT.Slate, TRIM, "KeepCourse")
	for _, x in ipairs({ KX1 + 11, C.X, KX2 - 11 }) do
		B(x - 1.5, 80, KZ1 - 2.5, x + 1.5, KY - 2, KZ1, MAT.Basalt, STONE_DK, "Buttress")
		B(x - 1.5, 80, KZ2, x + 1.5, KY - 2, KZ2 + 2.5, MAT.Basalt, STONE_DK, "Buttress")
	end
	for _, z in ipairs({ KZ1 + 11, KZ2 - 11 }) do
		B(KX1 - 2.5, 80, z - 1.5, KX1, KY - 2, z + 1.5, MAT.Basalt, STONE_DK, "Buttress")
		if z < 327 then -- (the east face clear from z 327 on: the last bridge's arches spring there)
			B(KX2, 80, z - 1.5, KX2 + 2.5, KY - 2, z + 1.5, MAT.Basalt, STONE_DK, "Buttress")
		end
	end
	for _, bt in ipairs({ { KX1 + 11, KZ1 - 1.25 }, { C.X, KZ1 - 1.25 }, { KX2 - 11, KZ1 - 1.25 }, { KX1 + 11, KZ2 + 1.25 }, { C.X, KZ2 + 1.25 }, { KX2 - 11, KZ2 + 1.25 }, { KX1 - 1.25, KZ1 + 11 }, { KX1 - 1.25, KZ2 - 11 }, { KX2 + 1.25, KZ1 + 11 } }) do
		pinnacle(V3(bt[1], KY - 2, bt[2]), 1.8, 9)
	end
	for _, fc in ipairs({ { V3(KX1 - 0.02, 0, C.Z), V3(-1, 0, 0) }, { V3(C.X, 0, KZ1 - 0.02), V3(0, 0, -1) }, { V3(C.X, 0, KZ2 + 0.02), V3(0, 0, 1) }, { V3(KX2 + 0.02, 0, C.Z), V3(1, 0, 0) } }) do
		local across = fc[2]:Cross(UPV).Unit -- (tall lancets in the keep's walls, between its buttresses)
		for _, o in ipairs({ -16, -5.5, 5.5, 16 }) do
			if not (fc[2].X < 0 and math.abs(o) < 8) and not (fc[2].X > 0) then -- (not over the sealed gate; the east face, where the bridge's arches spring, left plain)
				lancet(fc[1] + across * o + V3(0, 90, 0), 3, 20, across, fc[2])
			end
		end
	end
	for _, c in ipairs({ { KX1, KZ1 }, { KX2, KZ1 }, { KX1, KZ2 }, { KX2, KZ2 } }) do
		P({ Name = "Turret", Shape = Enum.PartType.Cylinder, Size = V3(60, 12, 12), CFrame = CFrame.new(c[1], 110, c[2]) * UPRIGHT, Material = MAT.Basalt, Color = STONE })
		for i = 0, 3 do
			P({ Name = "TurretSpire", Shape = Enum.PartType.Cylinder, Size = V3(4, 11 - i * 3, 11 - i * 3), CFrame = CFrame.new(c[1], 142 + i * 4, c[2]) * UPRIGHT, Material = MAT.Slate, Color = i % 2 == 0 and STONE_DK or STONE })
		end
		P({ Name = "Finial", Shape = Enum.PartType.Ball, Size = Vector3.one * 1.6, CFrame = CFrame.new(c[1], 156.6, c[2]), Material = MAT.Metal, Color = IRON, CanCollide = false })
	end
	local function roofMerlon(x, z) -- (none where the bridge lands, z 327..341 on the east edge, nor by the turrets)
		if (x > KX2 - 1.6 and z > 327 and z < 341) or ((x < KX1 + 6 or x > KX2 - 6) and (z < KZ1 + 6 or z > KZ2 - 6)) then
			return
		end
		B(x - 0.8, KY, z - 0.8, x + 0.8, KY + 3, z + 0.8, MAT.Basalt, STONE, "Merlon")
	end
	for t = 0, 14 do
		local u = t / 14
		roofMerlon(KX1 + 44 * u, KZ1 + 0.8)
		roofMerlon(KX1 + 44 * u, KZ2 - 0.8)
		roofMerlon(KX1 + 0.8, KZ1 + 44 * u)
		roofMerlon(KX2 - 0.8, KZ1 + 44 * u)
	end
	do -- the sealed gate in its west face, toward the lift's tower: great doors of iron over nothing, chains snapped
		local face = CFrame.lookAt(V3(KX1 - 0.3, 0, C.Z), V3(KX1 - 10, 0, C.Z))
		P({ Name = "GreatGate", Size = V3(18, 26, 0.6), CFrame = face * CFrame.new(0, 95, 0), Material = MAT.Metal, Color = IRON })
		P({ Name = "GateArch", Size = V3(24, 4, 1.4), CFrame = face * CFrame.new(0, 109.5, 0.2), Material = MAT.Slate, Color = TRIM })
		for x = -7.5, 7.6, 3 do
			for y = 85, 105, 4 do
				P({ Name = "Stud", Shape = Enum.PartType.Ball, Size = Vector3.one * 0.6, CFrame = face * CFrame.new(x, y, -0.35), Material = MAT.Metal, Color = C3(70, 60, 50), CanCollide = false })
			end
		end
		pointedFrame((face * CFrame.new(0, 82, -0.4)).Position, 20, 18, 9, face.RightVector, face.LookVector, 1.2, 1.4, GOTH_LT)
		for _, sx in ipairs({ -8, 8 }) do
			P({ Name = "SnappedChain", Size = V3(0.5, 9, 0.5), CFrame = face * CFrame.new(sx, 103, -1) * CFrame.Angles(0.35, 0, 0), Material = MAT.Metal, Color = IRON, CanCollide = false })
		end
	end
	-- the bell, on the keep's roof where the beacon burned (the same as the Censery's: bell(), above)
	bell(V3(C.X, KY, C.Z), 2)

	---------------------------------------------------------------------------
	-- THE PALACE OF PYRALIS: east of BR1, on a pedestal of rock of its own over the lava, shut away till both bells have
	-- rung - then its drawbridge falls out of its gatehouse onto BR1 (init.server: info.Bulwark.Drawbridge). Floor 100.
	-- In over the drawbridge to the gatehouse and the forecourt (the nearest bonfire: the lift's top); the great doors, ahead,
	-- are barred from within. The way round, as in Lordran's castles, is a long loop back to them, three shortcuts on it:
	--   1 THE GUARD HALL (south of the forecourt, x 418..470, z 170..200) - its door east is barred from the far side -
	--     down the stair at its west end to
	--   2 THE CELLARS (under it, floor 86, cut in the pedestal's rock), east through a passage to
	--   3 THE CISTERN (under the long gallery): a causeway over black water (fall in and it's the long
	--     way round, up the stair at its west end), a spur north to
	--   4 THE CRYPT (under the chapel), tombs in rows; up the stair at its west side into
	--   5 THE CHAPEL OF EMBERS (x 516..550, z 198..244) - the stair up its east wall, open - and south out of it
	--   6 THE LONG GALLERY (x 468..550, z 174..200), west along it to its far end: the guard hall's door, UNBARRED from
	--     here - the first shortcut, the drawbridge to here - and back to the chapel, up its stair to its gallery (114),
	--     north to
	--   7 THE LIBRARY (x 516..550, z 244..272, floor 114), out east over a bridge into
	--   8 THE EAST WING (x 558..594, z 200..270): the hall of arms (114), its well open to the roof; south through the
	--     armoury under its upper floor, up the stair to the solar (128), round the galleries over the well, out west over
	--     the covered bridge (128) back into
	--   9 THE LIBRARY'S MEZZANINE (128), west through the throne hall's wall onto
	--  10 THE TRIFORIUM (128, high in the throne hall's north-east), down its stair to the balcony (114), north through
	--     the wall into
	--  11 THE NORTH GALLERY (x 418..486, z 280..296, floor 114) - its balcony over the forecourt, a ladder lying on it to
	--     KICK DOWN: the second shortcut - and at its west end the stair down to
	--  12 THE SERVANTS' PASSAGE (under it, floor 100), east along it and in under the balcony to
	--  13 THE THRONE HALL (x 466..516, z 198..280) - and its great doors, LIFTED FROM INSIDE: the third, straight back out
	--     to the forecourt (info.Bulwark.PalaceDoors, .PalaceLadder) - and its throne: the
	--     dais's upper tier is a lift (info.Bulwark.ThroneLift), and it sinks, throne and all, down through the rock to
	--  14 THE SUNKEN COURT (x 422..542, z 172..268, floor 12, vault to 68): the arena, cut out of the pedestal under the
	--     forecourt and the throne hall - a pillared hall of state, galleries, great arches, a colossus of the sun-king
	--     enthroned at its west end, lava running in its gutters and falling down its east wall
	---------------------------------------------------------------------------
	local drawbridge, palaceLadder, throneLift
	local palaceDoors = {}
	local beforePalace = {} -- (what's here already: the rest, built after it, is the palace - info.PalaceParts, for DecayedPalace)
	for _, c in ipairs(folder:GetChildren()) do
		beforePalace[c] = true
	end
	do
		local PF = 100
		local GOLD, CLOTH = C3(150, 112, 52), C3(96, 18, 12)
		-- the pedestal: a block of rock, a battered foot, courses
		-- solid rock over x1..x2, z1..z2 from y1 to y2, but for the voids in it (rects { x1, z1, x2, z2 }): cut into a grid
		-- at every edge, each strip along z merged into runs
		local function rock(x1, z1, x2, z2, y1, y2, voids, name, mat, col)
			local xs, zs = { x1, x2 }, { z1, z2 }
			for _, v in ipairs(voids) do
				for _, x in ipairs({ v[1], v[3] }) do
					if x > x1 and x < x2 then
						table.insert(xs, x)
					end
				end
				for _, z in ipairs({ v[2], v[4] }) do
					if z > z1 and z < z2 then
						table.insert(zs, z)
					end
				end
			end
			table.sort(xs)
			table.sort(zs)
			for i = 1, #xs - 1 do
				local a1, a2 = xs[i], xs[i + 1]
				if a2 - a1 > 0.01 then
					local run
					for j = 1, #zs do
						local solid = false
						if j < #zs then
							local cx, cz = (a1 + a2) / 2, (zs[j] + zs[j + 1]) / 2
							solid = true
							for _, v in ipairs(voids) do
								if cx > v[1] and cx < v[3] and cz > v[2] and cz < v[4] then
									solid = false
								end
							end
						end
						if solid and not run then
							run = zs[j]
						elseif not solid and run then
							if zs[j] - run > 0.01 then
								B(a1, y1, run, a2, y2, zs[j], mat or MAT.Basalt, col or STONE_DK, name or "PalaceRock")
							end
							run = nil
						end
					end
				end
			end
		end
		local CF0 = 86 -- (the cellars' floor)
		local DEEP1 = { { 470, 176, 548, 198 } } -- (the cistern's basin, 72.8..86)
		local DEEP2 = { { 420, 172, 468, 198 }, { 468, 184, 470, 188 }, { 470, 176, 548, 198 }, { 524, 198, 530, 200 }, { 516, 200, 548, 242 } } -- (cellars, passage, cistern, passage, crypt)
		local HOLES = { { 422, 173, 444, 179 }, { 517, 222, 522, 242 } } -- (in the floor: the stairs down, the guard hall's and the crypt's)
		local AX1, AZ1, AX2, AZ2, AF, AC = 422, 172, 542, 268, 12, 68 -- THE SUNKEN COURT: its floor, its vault
		local PASSAGE, PT = { 542, 212, 552, 228 }, AF + 22 -- (the passage of fire out of the court's east wall, to its lintel)
		local SHAFT = { 503, 230, 514, 250 } -- (the throne lift's, from the throne hall's floor down to the court's vault)
		table.insert(DEEP1, SHAFT)
		table.insert(DEEP2, SHAFT)
		table.insert(HOLES, SHAFT)
		for _, r in ipairs({ { 414, 164, 508, 296 }, { 508, 164, 552, 274 }, { 552, 196, 596, 272 } }) do -- (east of 508 it stops short of S8)
			-- the battered foot round it, the court cut out of it (whole, it stood 10 deep on the court's floor)
			rock(r[1] - 6, r[2] - 6, r[3] + 6, math.min(r[4] + 2, 296), -8, 22, { { AX1, AZ1, AX2, AZ2 }, PASSAGE }, "PalaceRockFoot", MAT.Basalt, STONE_DK)
			rock(r[1], r[2], r[3], r[4], -8, AF, {})
			rock(r[1], r[2], r[3], r[4], AF, AC, { { AX1, AZ1, AX2, AZ2 }, PASSAGE })
			rock(r[1], r[2], r[3], r[4], AC, 72.8, { SHAFT })
			rock(r[1], r[2], r[3], r[4], 72.8, CF0, DEEP1)
			rock(r[1], r[2], r[3], r[4], CF0, PF - 1.2, DEEP2)
			rock(r[1], r[2], r[3], r[4], PF - 1.2, PF, HOLES, "PalaceFloor", MAT.Slate, WALK)
		end
		-- its courses: bands round the pedestal's outside face only (whole slabs cut across the court, the cellars and
		-- the cistern), along the outline of the three blocks
		local OUTLINE = { { 414, 164 }, { 552, 164 }, { 552, 196 }, { 596, 196 }, { 596, 272 }, { 552, 272 }, { 552, 274 }, { 508, 274 }, { 508, 296 }, { 414, 296 } }
		for _, y in ipairs({ 40, 64, 86 }) do
			for i, a in ipairs(OUTLINE) do
				local b = OUTLINE[i % #OUTLINE + 1]
				B(math.min(a[1], b[1]) - 0.6, y, math.min(a[2], b[2]) - 0.6, math.max(a[1], b[1]) + 0.6, y + 1.4, math.max(a[2], b[2]) + 0.6, MAT.Slate, GOTH_LT, "PalaceRockCourse")
			end
		end
		-- a round tower: banded, slit, a corbelled crown of merlons, a cone of stacked drums
		local function tower(x, z, r, top, footX)
			P({ Name = "PalaceTower", Shape = Enum.PartType.Cylinder, Size = V3(top - PF + 2, r * 2, r * 2), CFrame = CFrame.new(x, (PF - 2 + top) / 2, z) * UPRIGHT, Material = MAT.Basalt, Color = GOTH })
			-- footX: it stands out past the pedestal's side, so it's carried on down to the pedestal's foot (its bottom
			-- showed in mid-air) - centred at footX, a little further out where straight down it would cut into the
			-- cellars or the court behind that side
			if footX then
				P({ Name = "PalaceTowerFoot", Shape = Enum.PartType.Cylinder, Size = V3(PF - 2 - 20, r * 2, r * 2), CFrame = CFrame.new(footX, (20 + PF - 2) / 2, z) * UPRIGHT, Material = MAT.Basalt, Color = GOTH })
			end
			for y = PF + 12, top - 6, 14 do
				P({ Name = "TowerBand", Shape = Enum.PartType.Cylinder, Size = V3(1, r * 2 + 0.6, r * 2 + 0.6), CFrame = CFrame.new(x, y, z) * UPRIGHT, Material = MAT.Slate, Color = GOTH_LT })
			end
			P({ Name = "TowerCrown", Shape = Enum.PartType.Cylinder, Size = V3(2.4, r * 2 + 2.4, r * 2 + 2.4), CFrame = CFrame.new(x, top + 1.2, z) * UPRIGHT, Material = MAT.Slate, Color = GOTH_DK })
			for i = 0, 13 do
				local a = i / 14 * math.pi * 2
				local d = V3(math.cos(a), 0, math.sin(a))
				blk("Merlon", V3(1.4, 2.6, 1.2), CFrame.lookAt(V3(x, top + 3.7, z) + d * (r + 0.6), V3(x, top + 3.7, z) + d * (r + 2)), MAT.Basalt, GOTH)
				if i % 2 == 0 then
					blk("TowerCorbel", V3(1, 1.6, 1.2), CFrame.lookAt(V3(x, top - 0.8, z) + d * (r + 0.6), V3(x, top - 0.8, z) + d * (r + 2)), MAT.Slate, GOTH_LT, false)
				end
			end
			for i = 0, 7 do
				local w = (r * 2 + 0.4) * (1 - i / 8.6)
				P({ Name = "TowerCap", Shape = Enum.PartType.Cylinder, Size = V3(3.2, w, w), CFrame = CFrame.new(x, top + 4 + i * 3, z) * UPRIGHT, Material = MAT.Slate, Color = i % 2 == 0 and GOTH_DK or GOTH })
			end
			P({ Name = "Finial", Shape = Enum.PartType.Ball, Size = Vector3.one * 1.4, CFrame = CFrame.new(x, top + 4 + 8 * 3 + 0.4, z), Material = MAT.Metal, Color = IRON, CanCollide = false })
			for k = 0, 3 do -- arrow slits, lit from within
				local a = k * math.pi / 2 + math.pi / 4
				local d = V3(math.cos(a), 0, math.sin(a))
				for y = PF + 8, top - 10, 13 do
					blk("Slit", V3(0.5, 3.4, 0.5), CFrame.new(V3(x, y, z) + d * (r - 0.1)), MAT.Neon, C3(255, 120, 50), false)
				end
			end
		end
		-- THE CURTAIN WALL: its front either side of the gatehouse, its sides, merlons along all of it; towers at its front corners
		local CW = PF + 22
		B(416, PF, 198, 418, CW, 228, MAT.Basalt, GOTH, "CurtainWall")
		B(416, PF, 252, 418, CW, 282, MAT.Basalt, GOTH, "CurtainWall")
		for z = 199.5, 227, 2.8 do
			B(416, CW, z - 0.6, 418, CW + 2.6, z + 0.6, MAT.Basalt, GOTH, "Merlon")
			B(416, CW, 480 - z - 0.6, 418, CW + 2.6, 480 - z + 0.6, MAT.Basalt, GOTH, "Merlon")
		end
		B(415.6, CW - 1.2, 197.6, 418.4, CW - 0.4, 228, MAT.Slate, GOTH_LT, "Cornice")
		B(415.6, CW - 1.2, 252, 418.4, CW - 0.4, 282.4, MAT.Slate, GOTH_LT, "Cornice")
		for _, z in ipairs({ 206, 216, 264, 274 }) do -- buttresses down its front
			B(414.6, PF, z - 1, 416, CW - 6, z + 1, MAT.Basalt, GOTH_DK, "Buttress")
			pinnacle(V3(415.3, CW - 6, z), 1.2, 4)
		end
		tower(418, 199, 4.5, 134, 415.4) -- (clear of the cellars, x 420..)
		tower(418, 281, 4.5, 134, 418)
		-- THE GATEHOUSE: a tall block over a hall through it, the gate in its front and back walls, battlements, a room
		-- over the hall, two round towers flanking its front
		local GT = PF + 40
		for _, wx in ipairs({ { 416, 418 }, { 432, 434 } }) do
			B(wx[1], PF, 228, wx[2], GT, 235, MAT.Basalt, GOTH, "GateWall")
			B(wx[1], PF, 245, wx[2], GT, 252, MAT.Basalt, GOTH, "GateWall")
			B(wx[1], PF + 18, 235, wx[2], GT, 245, MAT.Basalt, GOTH, "GateWall")
		end
		B(418, PF, 228, 432, GT, 230, MAT.Basalt, GOTH, "GateWall")
		B(418, PF, 250, 432, GT, 252, MAT.Basalt, GOTH, "GateWall")
		B(418, PF + 22, 230, 432, PF + 23.4, 250, MAT.Slate, GOTH_DK, "GateVault")
		B(418, GT - 1.2, 230, 432, GT, 250, MAT.Slate, GOTH_DK, "GateRoof")
		cornice(416, 228, 434, 252, GT - 2, GT - 1.2)
		merlons(416, 228, 434, 252, GT)
		doorway(V3(416, PF, 240), 10, 18, V3(0, 0, 1), V3(-1, 0, 0), 2)
		doorway(V3(434, PF, 240), 10, 18, V3(0, 0, 1), V3(1, 0, 0), 2)
		for x = 419, 431, 4 do -- machicolations over the gate's face, and its portcullis, raised (its teeth under the arch)
			B(x - 0.7, GT - 8, 226.6, x + 0.7, GT - 5, 228, MAT.Slate, GOTH_LT, "Corbel")
		end
		B(415, GT - 7, 226.6, 416, GT - 5, 253.4, MAT.Slate, GOTH_DK, "Machicolation")
		for z = 236, 244.1, 1.6 do
			blk("Portcullis", V3(0.35, 4, 0.35), CFrame.new(419, PF + 16.2, z), MAT.Metal, IRON, false)
			blk("PortcullisTooth", V3(0.35, 0.8, 0.35), CFrame.new(419, PF + 13.9, z) * CFrame.Angles(0, math.pi / 4, 0), MAT.Metal, IRON, false)
		end
		blk("PortcullisBar", V3(0.4, 0.4, 9.6), CFrame.new(419, PF + 15, 240), MAT.Metal, IRON, false)
		lancet(V3(415.95, PF + 29.5, 240), 2.6, 7.5, V3(0, 0, 1), V3(-1, 0, 0)) -- (over the drawbridge, raised)
		for _, z in ipairs({ 231.5, 248.5 }) do
			sconce(V3(418, PF + 7, z), V3(1, 0, 0))
		end
		tower(418, 225.5, 5.5, 150, 416.4) -- (clear of the court, x 422..)
		tower(418, 254.5, 5.5, 150, 416.4)
		-- (no bonfire here: the Bulwark's is at the top of the lift)
		-- THE DRAWBRIDGE: hinged at the gate's sill, raised flat against its face; let down, it lies west onto BR1's rim.
		-- Every part kept with its offset from the hinge (local -z: along the bridge, x across it); chains from its tip up
		-- into slots in the gatehouse's face, restretched as it falls
		local hinge = CFrame.lookAt(V3(416, PF, 240), V3(415, PF, 240))
		local L, DW = 27, 11
		local up = hinge * CFrame.Angles(math.pi / 2, 0, 0)
		drawbridge = { Hinge = hinge, Up = math.pi / 2, Parts = {}, Chains = {}, Tip = CFrame.new(0, 0, -L) }
		local function dpart(name, size, off, mat, col, collide)
			local p = blk(name, size, up * off, mat, col, collide)
			table.insert(drawbridge.Parts, { p, off })
			return p
		end
		dpart("Drawbridge", V3(DW, 1.4, L), CFrame.new(0, -0.7, -L / 2), MAT.WoodPlanks, WOOD)
		for _, sx in ipairs({ -1, 1 }) do
			dpart("DrawbridgeEdge", V3(0.7, 1.8, L), CFrame.new(sx * (DW / 2 + 0.35), -0.6, -L / 2), MAT.Metal, IRON)
		end
		for d = 2.5, L - 1, 4 do
			dpart("DrawbridgeBand", V3(DW, 0.16, 0.6), CFrame.new(0, 0.06, -d), MAT.Metal, IRON, false)
		end
		dpart("DrawbridgeShoe", V3(DW + 1.4, 1.6, 0.8), CFrame.new(0, -0.6, -L + 0.4), MAT.Metal, IRON)
		for _, sx in ipairs({ -1, 1 }) do
			local tip = CFrame.new(sx * 4.4, 0.4, -L + 1.2)
			dpart("ChainEye", V3(0.9, 0.9, 0.9), tip, MAT.Metal, IRON, false)
			local anchor = V3(415.4, PF + L + 4, 240 - sx * 4.4) -- (the hinge's local x is the world's -z)
			blk("ChainSlot", V3(0.4, 1.6, 1.6), CFrame.new(anchor + V3(0.4, 0, 0)), MAT.Slate, VOID, false)
			local tp = (up * tip).Position
			local ch = blk("DrawChain", V3(0.45, 0.45, (anchor - tp).Magnitude), CFrame.lookAt((tp + anchor) / 2, anchor), MAT.Metal, IRON, false)
			table.insert(drawbridge.Chains, { Part = ch, Anchor = anchor, Tip = tip })
		end
		-- THE FORECOURT: paved up its middle, lamps either side, two statues of knights, braziers before the palace's door
		B(434, PF, 235, 466, PF + 0.15, 245, MAT.Slate, GOTH_LT, "Paving")
		for x = 440, 461, 7 do
			for _, z in ipairs({ 232.5, 247.5 }) do
				blk("LampPost", V3(1, 3.4, 1), CFrame.new(x, PF + 1.7, z), MAT.Slate, GOTH)
				lantern(V3(x, PF + 3.4, z))
			end
		end
		-- a statue of the king on a plinth (f: its foot, facing; k: its scale - 1 the forecourt's, a figure some 15 high):
		-- the plinth here; the king in stone on it later (info.KingStatues: Characters/KingGilded.spawnStatues)
		info.KingStatues = info.KingStatues or {}
		local function statue(f, k)
			for _, b in ipairs({ { "Plinth", V3(7, 4, 7), 2, GOTH }, { "PlinthCap", V3(7.8, 0.8, 7.8), 4.4, GOTH_LT } }) do
				blk(b[1], b[2] * k, f * CFrame.new(0, b[3] * k, 0), MAT.Slate, b[4])
			end
			table.insert(info.KingStatues, { Foot = f * CFrame.new(0, 4.8 * k, 0), Scale = 1.65 * k })
		end
		for _, z in ipairs({ 214, 266 }) do -- (facing the gate)
			statue(CFrame.lookAt(V3(450, PF, z), V3(420, PF, 240)), 1)
		end
		for _, z in ipairs({ 229, 251 }) do
			blk("BrazierFoot", V3(1.4, 3, 1.4), CFrame.new(462, PF + 1.5, z), MAT.Metal, IRON)
			P({ Name = "Brazier", Shape = Enum.PartType.Cylinder, Size = V3(1.2, 4, 4), CFrame = CFrame.new(462, PF + 3.4, z) * UPRIGHT, Material = MAT.Metal, Color = IRON })
			P({ Name = "BrazierCoals", Shape = Enum.PartType.Cylinder, Size = V3(0.3, 3.4, 3.4), CFrame = CFrame.new(462, PF + 4, z) * UPRIGHT, Material = MAT.Neon, Color = C3(255, 80, 20), CanCollide = false })
			fire(V3(462, PF + 5, z), 5)
			embers(V3(462, PF + 5, z), V3(2, 1, 2), 6)
			light(ghost(V3(462, PF + 7, z)), C3(255, 130, 60), 30, 1.8)
		end
		-- THE PALACE. Walls: a box with holes cut in it (doors: { u1, u2, v1, v2 [, v3, v4] } along its length and up -
		-- a second v pair for a door over a door)
		local rngP = Random.new(4242) -- (its own stream: the brimstone's below keeps its)
		local function RP(a, b)
			return rngP:NextNumber(a, b)
		end
		local function wall(x1, y1, z1, x2, y2, z2, holes)
			local alongX = (x2 - x1) >= (z2 - z1)
			local cuts = { alongX and x1 or z1, alongX and x2 or z2 }
			for _, h in ipairs(holes or {}) do
				table.insert(cuts, h[1])
				table.insert(cuts, h[2])
			end
			table.sort(cuts)
			local function bx(u1, u2, v1, v2)
				if u2 - u1 > 0.01 and v2 - v1 > 0.01 then
					if alongX then
						B(u1, v1, z1, u2, v2, z2, MAT.Basalt, GOTH, "PalaceWall")
					else
						B(x1, v1, u1, x2, v2, u2, MAT.Basalt, GOTH, "PalaceWall")
					end
				end
			end
			for i = 1, #cuts - 1 do
				local u1, u2, hole = cuts[i], cuts[i + 1], nil
				for _, h in ipairs(holes or {}) do
					if u1 >= h[1] - 0.01 and u2 <= h[2] + 0.01 then
						hole = h
					end
				end
				if hole then
					bx(u1, u2, y1, hole[3])
					if hole[5] then
						bx(u1, u2, hole[4], hole[5])
						bx(u1, u2, hole[6], y2)
					else
						bx(u1, u2, hole[4], y2)
					end
				else
					bx(u1, u2, y1, y2)
				end
			end
		end
		local function steps(a, b, w, noRail) -- a solid stair, its foot a (on the floor), its head b, along x or z, w wide
			local d = V3(b.X - a.X, 0, b.Z - a.Z)
			local len, along = d.Magnitude, d.Unit
			local n = math.max(1, math.floor((b.Y - a.Y) / 0.7 + 0.5))
			for i = 1, n do
				local f1, f2 = (i - 1) / n * len, i / n * len
				local h = (b.Y - a.Y) * i / n
				local c = a + along * ((f1 + f2) / 2) + V3(0, h / 2, 0)
				blk("Step", V3(w, h, f2 - f1 + 0.02), CFrame.lookAt(c, c + along), MAT.Slate, i % 2 == 0 and WALK or PARA)
			end
			if noRail then
				return
			end
			local L2 = (b - a).Magnitude -- (a rail up its open side, sloped)
			local side = along:Cross(UPV).Unit
			for _, sd in ipairs({ -1, 1 }) do
				local p1, p2 = a + side * sd * (w / 2 + 0.4) + V3(0, 1.3, 0), b + side * sd * (w / 2 + 0.4) + V3(0, 1.3, 0)
				local r = blk("StairRail", V3(0.8, 2.6, L2), CFrame.lookAt((p1 + p2) / 2, p2), MAT.Slate, PARA)
				r:SetAttribute("Side", sd)
			end
		end
		-- a door leaf's pointed head: strips stepping in, filling its share of the arch over the doorway (the opening's
		-- square part only reaches the springing: a square leaf left the point of the arch open over it). The opening:
		-- w wide, its arch springing at spring over the hinge's foot, rising rise (as doorway() builds it); u runs across
		-- it from its middle, the hinge at uh, the leaf over ua..ub; the leaf's parts are placed off its hinge (lp)
		local function leafHead(lp, thick, w, spring, rise, uh, ua, ub, mat, col)
			for j = 1, 4 do
				local fy = (j - 0.5) / 4
				local fx = (1 - math.cos(math.asin(math.clamp(fy * 0.8660254, 0, 1)))) * 2 -- (as headFill's corners)
				local half = (w / 2) * (1 - fx)
				local lo, hi = math.max(ua, -half), math.min(ub, half)
				if hi - lo > 0.05 then
					lp("DoorHead", V3(thick, rise / 4 + 0.02, hi - lo), CFrame.new(0, spring + rise * fy, (lo + hi) / 2 - uh), mat, col)
				end
			end
		end
		local function parapet(x1, z1, x2, z2, y) -- a low stone balustrade, its coping
			B(x1, y, z1, x2, y + 2.4, z2, MAT.Slate, PARA, "Parapet")
			B(x1 - 0.2, y + 2.4, z1 - 0.2, x2 + 0.2, y + 2.8, z2 + 0.2, MAT.Slate, GOTH_LT, "Coping")
		end
		local function chandelier(cp, ceil)
			P({ Name = "Chandelier", Shape = Enum.PartType.Cylinder, Size = V3(0.4, 6, 6), CFrame = CFrame.new(cp) * UPRIGHT, Material = MAT.Metal, Color = IRON, CanCollide = false })
			blk("ChandelierChain", V3(0.2, ceil - cp.Y, 0.2), CFrame.new(cp + UPV * ((ceil - cp.Y) / 2)), MAT.Metal, IRON, false)
			for i = 0, 5 do
				local a = i / 6 * math.pi * 2
				lantern(cp + V3(math.cos(a) * 2.6, 0.2, math.sin(a) * 2.6))
			end
		end
		local function brazier(p, y)
			blk("BrazierFoot", V3(1, 1.2, 1), CFrame.new(p.X, y + 0.6, p.Z), MAT.Metal, IRON)
			P({ Name = "Brazier", Shape = Enum.PartType.Cylinder, Size = V3(1.2, 3.4, 3.4), CFrame = CFrame.new(p.X, y + 1.8, p.Z) * UPRIGHT, Material = MAT.Metal, Color = IRON })
			P({ Name = "BrazierCoals", Shape = Enum.PartType.Cylinder, Size = V3(0.3, 2.8, 2.8), CFrame = CFrame.new(p.X, y + 2.4, p.Z) * UPRIGHT, Material = MAT.Neon, Color = C3(255, 80, 20), CanCollide = false })
			fire(V3(p.X, y + 3.4, p.Z), 4)
			light(ghost(V3(p.X, y + 5, p.Z)), C3(255, 130, 60), 30, 1.8)
		end
		local function banner(cf, w, h)
			blk("Banner", V3(w, h, 0.15), cf, MAT.Fabric, CLOTH, false)
			blk("BannerSun", V3(w * 0.42, w * 0.42, 0.2), cf * CFrame.new(0, h * 0.18, 0) * CFrame.Angles(0, 0, math.pi / 4), MAT.Neon, C3(255, 120, 40), false)
			blk("BannerRod", V3(w + 0.8, 0.3, 0.3), cf * CFrame.new(0, h / 2 + 0.1, 0), MAT.Metal, IRON, false)
		end
		local function guard(x, y, z, fx, fz, kind) -- one of the palace's own standing watch (a forge-brute unless kind), facing (fx, fz)
			local p = V3(x, y + 3.2, z)
			table.insert(info.EnemySpawns, { Type = kind or brute(), CFrame = CFrame.lookAt(p, V3(fx, p.Y, fz)) })
		end
		-- a chest on the floor at (x, y, z), its lock facing yaw's way (yaw 0: -z), item what's in it (init.server opens
		-- it, as the mushroom huts' are)
		local function chest(x, y, z, yaw, item)
			local cf = CFrame.new(x, y, z) * CFrame.Angles(0, yaw, 0)
			local function c(name, size, off, mat, col, collide)
				return blk(name, size, cf * off, mat, col, collide)
			end
			c("Chest", V3(4, 2.2, 2.4), CFrame.new(0, 1.1, 0), MAT.WoodPlanks, WOOD_DK)
			for _, bx in ipairs({ -1.5, 0, 1.5 }) do
				c("ChestBand", V3(0.3, 2.3, 2.5), CFrame.new(bx, 1.1, 0), MAT.Metal, IRON, false)
			end
			c("ChestLock", V3(0.5, 0.55, 0.12), CFrame.new(0, 1.8, -1.25), MAT.Metal, GOLD, false)
			c("ChestSun", V3(0.9, 0.9, 0.1), CFrame.new(0, 1.0, -1.26) * CFrame.Angles(0, 0, math.pi / 4), MAT.Metal, GOLD, false)
			local lid = c("ChestLid", V3(4.05, 0.45, 2.45), CFrame.new(0, 2.42, 0), MAT.WoodPlanks, WOOD_DK)
			info.MushroomChests = info.MushroomChests or {}
			table.insert(info.MushroomChests, { Lid = lid, Hinge = cf * CFrame.new(0, 2.65, 1.2), Item = item, Prompt = prompt(lid, "Open", "Chest", 0.5, 7) })
		end
		local UF = 114 -- (the upper floor)
		local XIN, XOUT, ZIN, ZOUT = V3(1, 0, 0), V3(-1, 0, 0), V3(0, 0, 1), V3(0, 0, -1)

		-- 1 THE GUARD HALL: low, flat-roofed, battlemented; piers down its middle; racks of arms, a table, barrels
		wall(418, PF, 170, 470, 122, 172)
		wall(418, PF, 198, 466, 122, 200, { { 440, 446, PF, PF + 10 } })
		wall(418, PF, 172, 420, 122, 198)
		wall(468, PF, 172, 470, 126, 198, { { 180, 186, PF, PF + 10 } })
		doorway(V3(443, PF, 200), 6, 10, XIN, ZIN, 2)
		doorway(V3(470, PF, 183), 6, 10, ZIN, XIN, 2)
		B(418, 120.8, 170, 470, 122, 200, MAT.Slate, GOTH_DK, "Roof")
		cornice(418, 170, 470, 200, 120, 120.8)
		merlons(418, 170, 470, 200, 122)
		tower(419, 171, 5, 136)
		for _, x in ipairs({ 432, 444, 456 }) do
			clusterPier(V3(x, 0, 185), PF, 120.8, 1.8, CFrame.new())
		end
		for _, x in ipairs({ 428, 440, 452, 464 }) do
			lancet(V3(x, PF + 6, 169.95), 2.6, 11, XIN, ZOUT)
			sconce(V3(x + 6, PF + 7, 172), ZIN)
		end
		B(426, PF + 2.4, 189, 446, PF + 3, 193, MAT.WoodPlanks, WOOD, "Table")
		for _, e in ipairs({ { 427, 190 }, { 445, 190 }, { 427, 192 }, { 445, 192 } }) do
			B(e[1] - 0.3, PF, e[2] - 0.3, e[1] + 0.3, PF + 2.4, e[2] + 0.3, MAT.Wood, WOOD_DK, "TableLeg")
		end
		for _, z in ipairs({ 187.2, 194.8 }) do
			B(427, PF, z - 0.5, 445, PF + 1.3, z + 0.5, MAT.Wood, WOOD_DK, "Bench")
		end
		for _, z in ipairs({ 186, 191 }) do -- racks of halberds against the west wall
			B(420, PF, z - 2, 421, PF + 0.6, z + 2, MAT.Wood, WOOD_DK, "Rack")
			B(420, PF + 5, z - 2, 421, PF + 5.4, z + 2, MAT.Wood, WOOD_DK, "Rack")
			for dz = -1.5, 1.6, 1 do
				blk("RackPole", V3(0.25, 8, 0.25), CFrame.new(420.6, PF + 4, z + dz) * CFrame.Angles(0, 0, -0.08), MAT.Wood, WOOD, false)
				blk("RackHead", V3(0.15, 1.6, 0.9), CFrame.new(420.3, PF + 8.4, z + dz), MAT.Metal, IRON, false)
			end
		end
		for _, b in ipairs({ { 462, 174 }, { 464.4, 174.2 }, { 463, 176.4 }, { 422, 195.5 } }) do
			P({ Name = "Barrel", Shape = Enum.PartType.Cylinder, Size = V3(2.2, 1.8, 1.8), CFrame = CFrame.new(b[1], PF + 1, b[2]) * UPRIGHT, Material = MAT.WoodPlanks, Color = WOOD_DK })
		end
		brazier(V3(452, 0, 194), PF)
		banner(CFrame.new(450, PF + 13, 172.2), 4, 9)
		guard(452, PF, 180, 443, 198)
		-- the stair down into the cellars, at its west end (the hole x 422..444, z 173..179), a balustrade round it
		steps(V3(424, CF0, 176), V3(444, PF, 176), 5)
		parapet(422, 179, 443, 179.8, PF)
		parapet(421.2, 173, 422, 179.8, PF)
		do -- its door into the long gallery: barred from the gallery's side
			local hinge = CFrame.new(469, PF, 180)
			local leaf = { Hinge = hinge, Parts = {}, Angle = math.rad(100) } -- (swings into the gallery)
			local function lp(name, size, off, mat, col, collide)
				local p = blk(name, size, hinge * off, mat, col, collide)
				table.insert(leaf.Parts, { p, off })
			end
			lp("Door", V3(0.8, 7, 6), CFrame.new(0, 3.5, 3), MAT.WoodPlanks, WOOD_DK)
			leafHead(lp, 0.8, 6, 7, 3, -3, -3, 3, MAT.WoodPlanks, WOOD_DK) -- (its doorway: 6 wide, 10 high)
			for _, y in ipairs({ 1.5, 5.5 }) do
				lp("DoorBand", V3(1, 0.5, 6), CFrame.new(0, y, 3), MAT.Metal, IRON, false)
			end
			local d = { Leaves = { leaf }, Inside = function(p)
				return p.X > 470
			end }
			d.Bar = blk("DoorBar", V3(0.7, 0.8, 8), CFrame.new(470.5, PF + 4, 183), MAT.Wood, WOOD, false)
			d.BarAside = CFrame.new(471, PF + 4.2, 188.6) * CFrame.Angles(-0.2, 0, 0) * CFrame.Angles(math.pi / 2, 0, 0)
			for _, z in ipairs({ 179.4, 186.6 }) do
				blk("BarBracket", V3(1, 1.2, 0.5), CFrame.new(470.5, PF + 4, z), MAT.Metal, IRON, false)
			end
			d.Prompt = prompt(ghost(V3(471.4, PF + 4, 183)), "Lift the bar", "Door", 0.6, 7)
			d.LockedPrompt = prompt(ghost(V3(466.6, PF + 4, 183)), "Open", "Door", 0, 7)
			table.insert(palaceDoors, d)
		end

		-- 2 THE CELLARS (x 420..468, z 172..198, floor 86): low and close under the guard hall, casks and racks of
		-- bottles, piers of the living rock; a passage east (x 468..470, z 184..188)
		for _, x in ipairs({ 436, 452 }) do
			B(x - 1.5, CF0, 183.5, x + 1.5, PF - 1.2, 186.5, MAT.Basalt, STONE_DK, "CellarPier")
		end
		for _, c in ipairs({ { 430, 196 }, { 432.4, 196 }, { 434.8, 196 }, { 431.2, 196, 1 }, { 433.6, 196, 1 }, { 460, 174 }, { 462.4, 174 }, { 461.2, 174, 1 } }) do
			P({ Name = "Cask", Shape = Enum.PartType.Cylinder, Size = V3(2.2, 2.2, 2.2), CFrame = CFrame.new(c[1], CF0 + 1.1 + (c[3] and 1.9 or 0), c[2]) * CFrame.Angles(0, math.pi / 2, 0), Material = MAT.WoodPlanks, Color = WOOD_DK })
		end
		for _, x in ipairs({ 444, 456 }) do -- wine racks against the north wall
			B(x - 3, CF0, 196.6, x + 3, CF0 + 6, 198, MAT.Wood, WOOD_DK, "WineRack")
			for y = CF0 + 0.8, CF0 + 5.4, 1.1 do
				for dx = -2.4, 2.5, 0.8 do
					blk("Bottle", V3(0.35, 0.35, 0.6), CFrame.new(x + dx, y, 196.4), MAT.Glass, C3(30, 50, 34), false)
				end
			end
		end
		for _, b in ipairs({ { 464, 194 }, { 425, 190 }, { 427, 192.4 } }) do
			blk("Crate", V3(2.2, 2.2, 2.2), CFrame.new(b[1], CF0 + 1.1, b[2]) * CFrame.Angles(0, RP(-0.4, 0.4), 0), MAT.WoodPlanks, WOOD)
		end
		for _, x in ipairs({ 452, 464 }) do
			sconce(V3(x, CF0 + 6, 172), ZIN)
		end
		sconce(V3(436, CF0 + 6, 198), ZOUT)
		doorway(V3(470, CF0, 186), 4, 8, ZIN, XIN, 2)
		guard(450, CF0, 190, 426, 176, "Executioner")

		-- 3 THE CISTERN (x 470..548, z 176..198): a vault, floored over at the cellars' level from wall to wall (the
		-- passage comes in at its west end; north through the doorway at x 524..530 to the crypt). The Decayed Palace's is
		-- a clone of this one.
		B(470, CF0 - 1.2, 176, 548, CF0, 198, MAT.Slate, WALK, "CisternFloor")
		for x = 486, 542, 12 do
			clusterPier(V3(x, 0, 180.5), 72.8, PF - 1.2, 1.6, CFrame.new())
			if x > 500 and x ~= 522 then
				clusterPier(V3(x, 0, 193.5), 72.8, PF - 1.2, 1.6, CFrame.new())
			end
		end
		for _, x in ipairs({ 478, 499, 518, 528 }) do
			lantern(V3(x, CF0, 185.6))
		end
		light(ghost(V3(510, 78, 187)), C3(60, 120, 120), 40, 0.6) -- (a cold glow off the water)
		doorway(V3(527, CF0, 200), 6, 9, XIN, ZIN, 2)
		guard(527, CF0, 194, 476, 187, "Pyre") -- (on the spur, firing down the causeway as you come along it)

		-- 4 THE CRYPT (x 516..548, z 200..242, floor 86): the old kings' tombs in a row down its middle, niches of bones in
		-- its walls, candles; its stair up (x 517..522, z 224..242) into the chapel
		for _, z in ipairs({ 206, 214, 230, 238 }) do
			B(532.5, CF0, z - 1.6, 539.5, CF0 + 2.4, z + 1.6, MAT.Slate, GOTH, "Tomb")
			B(532.2, CF0 + 2.4, z - 1.8, 539.8, CF0 + 2.9, z + 1.8, MAT.Slate, GOTH_LT, "TombLid")
			B(533.5, CF0 + 2.9, z - 0.7, 538.5, CF0 + 3.5, z + 0.7, MAT.Slate, GOTH_LT, "TombEffigy")
			lantern(V3(540.8, CF0, z))
		end
		for z = 204, 240, 6 do -- niches along the east wall, skulls in them
			B(547.2, CF0 + 3, z - 1, 548, CF0 + 5, z + 1, MAT.Slate, VOID, "Niche")
			P({ Name = "Skull", Shape = Enum.PartType.Ball, Size = Vector3.one * 0.9, CFrame = CFrame.new(547.4, CF0 + 3.5, z), Material = MAT.Slate, Color = C3(170, 160, 140), CanCollide = false })
		end
		steps(V3(519.5, CF0, 224), V3(519.5, PF, 242), 5, true) -- (no rails: it's stepped off sideways at its head)
		for _, z in ipairs({ 210, 226 }) do
			sconce(V3(548, CF0 + 6, z), XOUT)
		end
		-- behind the last tomb, in the crypt's far corner: the Pyre Priest's mask
		chest(544.5, CF0, 240.4, 0, { Attr = "PyreMask", Text = "Pyre Priest's Mask. Beaten gold, a sun with slits for eyes; set it on and a ring of fire kindles behind your head. Press T to choose weapons and armor." })
		guard(536, CF0, 222, 527, 200, "Stoker") -- (between the rows of tombs; the Furnace Brute reworks: Stoker, Forgeknight, Ashsmith)

		-- 2 THE LONG GALLERY: under a gable, a colonnade down its middle, the old kings in stone along its south wall
		-- between the windows, a runner up its length; its far end turns north
		wall(470, PF, 174, 550, 126, 176)
		wall(548, PF, 176, 550, 126, 198)
		gable(468, 174, 550, 200, 126, 10, true)
		cornice(468, 174, 550, 200, 125.2, 126)
		for x = 482, 538, 14 do
			clusterPier(V3(x, 0, 187), PF, 124, 1.6, CFrame.new())
		end
		for _, x in ipairs({ 477, 491, 505, 519, 533 }) do
			B(x - 1.8, PF, 176, x + 1.8, PF + 2.4, 179.6, MAT.Slate, GOTH, "Plinth")
			statue(CFrame.lookAt(V3(x, PF + 2.4, 178), V3(x, PF + 2.4, 190)), 0.55)
			lancet(V3(x + 7, PF + 7, 173.95), 2.6, 13, XIN, ZOUT)
			sconce(V3(x + 7, PF + 6.5, 176), ZIN)
		end
		B(472, PF, 191, 546, PF + 0.12, 195, MAT.Fabric, CLOTH, "Carpet")
		for _, x in ipairs({ 489, 517, 541 }) do
			chandelier(V3(x, PF + 17, 192), 131)
		end
		banner(CFrame.new(547.9, PF + 13, 187) * CFrame.Angles(0, -math.pi / 2, 0), 4.5, 11)
		guard(505, PF, 192, 470, 183)
		guard(540, PF, 182, 505, 187, "Executioner")

		-- 3 THE CHAPEL OF EMBERS: tall, gabled; an altar with a great bowl of fire, pews; a stair up its east wall to a
		-- gallery across its north end, and the door on from there
		wall(516, PF, 198, 550, 134, 200, { { 530, 536, PF, PF + 10 } })
		wall(548, PF, 200, 550, 134, 242)
		wall(516, PF, 242, 550, 138, 244, { { 524, 530, UF, UF + 10 } })
		doorway(V3(533, PF, 200), 6, 10, XIN, ZIN, 2)
		doorway(V3(527, UF, 244), 6, 10, XIN, ZIN, 2)
		gable(516, 198, 550, 244, 134, 14, false)
		cornice(516, 198, 550, 244, 133.2, 134)
		tower(549, 199, 5, 146)
		steps(V3(544.5, PF, 206), V3(544.5, UF, 228), 5)
		B(516, UF - 1.2, 228, 548, UF, 242, MAT.Slate, WALK, "Gallery")
		parapet(516, 228, 541.6, 228.8, UF)
		for _, x in ipairs({ 524, 534 }) do
			clusterPier(V3(x, 0, 228.6), PF, UF - 1.2, 1.1, CFrame.new())
		end
		B(518, PF, 207, 524, PF + 3, 219, MAT.Slate, GOTH_LT, "Altar")
		P({ Name = "EmberBowl", Shape = Enum.PartType.Cylinder, Size = V3(1.4, 5, 5), CFrame = CFrame.new(521, PF + 3.7, 213) * UPRIGHT, Material = MAT.Metal, Color = IRON })
		P({ Name = "EmberCoals", Shape = Enum.PartType.Cylinder, Size = V3(0.3, 4.4, 4.4), CFrame = CFrame.new(521, PF + 4.3, 213) * UPRIGHT, Material = MAT.Neon, Color = C3(255, 80, 20), CanCollide = false })
		fire(V3(521, PF + 5.4, 213), 7)
		embers(V3(521, PF + 6, 213), V3(3, 1, 3), 10)
		light(ghost(V3(521, PF + 9, 213)), C3(255, 120, 50), 40, 2.2)
		parapet(522, 221.2, 522.8, 238, PF) -- (round the crypt's stairwell: open at its head, x 522.. by the north wall)
		parapet(517, 221.2, 522, 222, PF)
		for _, s in ipairs({ { 207, 211 }, { 215, 219 } }) do
			lantern(V3(519, PF + 3, s[1]))
			lantern(V3(519, PF + 3, s[2]))
		end
		for x = 528, 538.1, 3 do
			for _, zr in ipairs({ { 205, 214 }, { 219, 226 } }) do
				B(x - 0.5, PF, zr[1], x + 0.5, PF + 1.1, zr[2], MAT.Wood, WOOD_DK, "Pew")
				B(x + 0.4, PF, zr[1], x + 0.7, PF + 2.4, zr[2], MAT.Wood, WOOD_DK, "PewBack")
			end
		end
		for _, z in ipairs({ 210, 222, 236 }) do
			lancet(V3(550.05, PF + 14, z), 3, 15, ZIN, XIN)
		end
		banner(CFrame.new(516.1, PF + 16, 213) * CFrame.Angles(0, math.pi / 2, 0), 5, 14)
		chandelier(V3(532, PF + 20, 214), 146.5)
		guard(534, UF, 236, 544.5, 222, "Pyre") -- (on the gallery, over the stair you come up)

		-- 4 THE LIBRARY, up on the chapel's level: stacks in rows off its east side, reading tables, books everywhere;
		-- out through its west wall onto the throne hall's balcony
		wall(548, PF, 244, 550, 138, 270, { { 250, 256, 128, 136 }, { 262, 268, UF, UF + 10 } })
		wall(516, PF, 270, 550, 138, 272)
		doorway(V3(550, UF, 265), 6, 10, ZIN, XIN, 2)
		doorway(V3(550, 128, 253), 6, 8, ZIN, XIN, 2)
		-- the mezzanine over its stacks (x 530..548), a walk west from it to the throne hall's wall (z 258..268)
		B(530, 126.8, 246, 548, 128, 270, MAT.WoodPlanks, WOOD, "Mezzanine")
		B(516, 126.8, 258, 530, 128, 268, MAT.WoodPlanks, WOOD, "Mezzanine")
		parapet(529.2, 246, 530, 257.2, 128)
		parapet(529.2, 268.8, 530, 270, 128)
		parapet(516, 257.2, 530, 258, 128)
		parapet(516, 268, 530, 268.8, 128)
		for _, p in ipairs({ { 530.6, 246.6 }, { 530.6, 257.4 }, { 516.6, 257.4 }, { 529.4, 268.4 } }) do
			B(p[1] - 0.4, UF, p[2] - 0.4, p[1] + 0.4, 126.8, p[2] + 0.4, MAT.Wood, WOOD_DK, "MezzaninePost")
		end
		B(516, PF, 244, 548, UF, 270, MAT.Basalt, GOTH_DK, "LibraryUndercroft")
		B(516, UF - 0.2, 244, 548, UF, 270, MAT.WoodPlanks, WOOD, "LibraryFloor")
		gable(516, 244, 550, 272, 138, 12, false)
		cornice(516, 244, 550, 272, 137.2, 138)
		tower(549, 271, 5, 150, 549)
		local BOOK = { C3(62, 26, 26), C3(54, 22, 24), C3(70, 34, 32), C3(48, 26, 22), C3(58, 38, 30), C3(44, 30, 28) } -- (faded burgundies and old leather browns)
		local function stack(x1, z1, x2, z2) -- a bookcase: its frame, five shelves, books of every colour
			B(x1, UF, z1, x2, UF + 9, z2, MAT.Wood, WOOD_DK, "Bookcase")
			local alongX = (x2 - x1) > (z2 - z1)
			for y = UF + 0.6, UF + 8, 1.7 do
				local u = alongX and x1 + 0.3 or z1 + 0.3
				local uEnd = alongX and x2 - 0.3 or z2 - 0.3
				while u < uEnd - 0.3 do
					local w = math.min(RP(0.3, 0.6), uEnd - u)
					local h = RP(1, 1.45)
					local col = BOOK[rngP:NextInteger(1, #BOOK)]
					for _, sd in ipairs({ -1, 1 }) do
						local c = alongX and V3(u + w / 2, y + h / 2, (z1 + z2) / 2 + sd * ((z2 - z1) / 2 + 0.05)) or V3((x1 + x2) / 2 + sd * ((x2 - x1) / 2 + 0.05), y + h / 2, u + w / 2)
						blk("Book", alongX and V3(w - 0.04, h, 0.5) or V3(0.5, h, w - 0.04), CFrame.new(c), MAT.Fabric, col, false)
					end
					u += w
				end
			end
		end
		for _, z in ipairs({ 250, 256, 262 }) do
			stack(533, z - 0.6, 547, z + 0.6)
		end
		for _, t in ipairs({ { 522, 250 }, { 524, 268 } }) do
			B(t[1] - 3, UF + 2.4, t[2] - 1.5, t[1] + 3, UF + 2.9, t[2] + 1.5, MAT.WoodPlanks, WOOD, "Table")
			for _, e in ipairs({ { -2.6, -1.1 }, { 2.6, -1.1 }, { -2.6, 1.1 }, { 2.6, 1.1 } }) do
				B(t[1] + e[1] - 0.2, UF, t[2] + e[2] - 0.2, t[1] + e[1] + 0.2, UF + 2.4, t[2] + e[2] + 0.2, MAT.Wood, WOOD_DK, "TableLeg")
			end
			lantern(V3(t[1] + 1.8, UF + 2.9, t[2]))
			for i = 1, 4 do
				blk("Book", V3(0.9, 0.25, 1.3), CFrame.new(t[1] - 1.5 + i * 0.5, UF + 3.05 + (i % 2) * 0.25, t[2] + RP(-0.4, 0.4)) * CFrame.Angles(0, RP(-0.6, 0.6), 0), MAT.Fabric, BOOK[i], false)
			end
		end
		for _ = 1, 10 do -- (fallen ones, on the floor)
			blk("Book", V3(0.9, 0.25, 1.3), CFrame.new(RP(519, 531), UF + 0.12, RP(246, 270)) * CFrame.Angles(0, RP(0, 6.28), 0), MAT.Fabric, BOOK[rngP:NextInteger(1, #BOOK)], false)
		end
		chandelier(V3(524, UF + 12, 250), 146)
		guard(524, UF, 259, 527, 246) -- (out on the open floor: by the cases it was jammed against them and a post)

		-- 8 THE THRONE HALL: the tallest of it all, its gable up to 168 and a flèche on the ridge; piers down it, the
		-- dais and the throne at its east end; a balcony round its north-east (114) - in from the library, out north to
		-- the north gallery - and under it the servants' door; its great doors in its front, barred from inside
		local EY = PF + 48
		wall(466, PF, 198, 468, EY, 280, { { 234, 246, PF, PF + 24 } })
		wall(466, PF, 198, 516, EY, 200)
		wall(514, PF, 200, 516, EY, 278, { { 260, 266, 128, 138 } })
		wall(466, PF, 278, 516, EY, 280, { { 476, 482, PF, PF + 10, UF, UF + 10 } })
		doorway(V3(466, PF, 240), 12, 24, ZIN, XOUT, 2)
		doorway(V3(514, 128, 263), 6, 10, ZIN, XOUT, 2)
		doorway(V3(479, PF, 278), 6, 10, XIN, ZOUT, 2)
		doorway(V3(479, UF, 280), 6, 10, XIN, ZIN, 2)
		B(466.6, PF + 19, 234, 467.4, PF + 24, 246, MAT.Slate, GOTH_DK, "Tympanum")
		blk("TympanumSun", V3(0.3, 3, 3), CFrame.new(466.4, PF + 21.3, 240) * CFrame.Angles(math.pi / 4, 0, 0), MAT.Neon, C3(255, 120, 40), false)
		cornice(466, 198, 516, 280, EY - 0.8, EY)
		gable(466, 198, 516, 280, EY, 20, false)
		do -- the flèche: a slender spire of shrinking drums up off the ridge, a burning finial
			local fx, fz = 491, 239
			B(fx - 3, EY + 16, fz - 3, fx + 3, EY + 26, fz + 3, MAT.Slate, GOTH, "Fleche")
			for _, c in ipairs({ { -3, -3 }, { 3, -3 }, { -3, 3 }, { 3, 3 } }) do
				pinnacle(V3(fx + c[1], EY + 26, fz + c[2]), 1, 5)
			end
			for i = 0, 7 do
				local w = 5 * (1 - i / 8.5)
				blk("FlecheTier", V3(w, 3, w), CFrame.new(fx, EY + 27.5 + i * 3, fz) * CFrame.Angles(0, (i % 2) * math.pi / 4, 0), MAT.Slate, i % 2 == 0 and GOTH_DK or GOTH)
			end
			P({ Name = "FlecheFinial", Shape = Enum.PartType.Ball, Size = Vector3.one * 1.6, CFrame = CFrame.new(fx, EY + 52.5, fz), Material = MAT.Neon, Color = C3(255, 120, 40), CanCollide = false })
			light(ghost(V3(fx, EY + 53, fz)), C3(255, 130, 60), 40, 2)
		end
		rose(V3(465.9, PF + 33, 240), 7, XOUT)
		for _, z in ipairs({ 210, 222, 258, 270 }) do
			lancet(V3(465.95, PF + 8, z), 3, 18, ZIN, XOUT)
			lancet(V3(465.95, PF + 32, z), 2.6, 11, ZIN, XOUT)
		end
		for x = 476, 507, 10 do -- clerestory windows high in its sides, over the roofs round it; pinnacles on its eaves
			lancet(V3(x, PF + 33, 197.95), 2.6, 12, XIN, ZOUT)
			lancet(V3(x, PF + 33, 280.05), 2.6, 12, XIN, ZIN)
			pinnacle(V3(x + 5, EY, 198.7), 1.2, 5)
			pinnacle(V3(x + 5, EY, 279.3), 1.2, 5)
		end
		for z = 213, 268, 11 do
			if math.abs(z - 240) > 6 then
				pinnacle(V3(466.6, EY, z), 1.2, 5)
			end
		end
		for _, z in ipairs({ 229, 251 }) do -- its door's flanking pinnacles, tall
			B(464.6, PF, z - 1.2, 466, PF + 30, z + 1.2, MAT.Basalt, GOTH_DK, "Buttress")
			pinnacle(V3(465.3, PF + 30, z), 1.6, 8)
		end
		tower(467, 199, 6.5, 170)
		tower(467, 279, 6.5, 170)
		-- inside: piers, tie beams, the carpet, the dais and the throne
		for _, x in ipairs({ 478, 490, 502 }) do
			for _, z in ipairs({ 216, 262 }) do
				clusterPier(V3(x, 0, z), PF, EY - 3, 2.4, CFrame.new())
			end
		end
		for _, z in ipairs({ 208, 224, 240, 256, 272 }) do
			blk("TieBeam", V3(46, 1.4, 1.4), CFrame.new(491, EY - 0.7, z), MAT.Wood, WOOD_DK, false)
		end
		B(468, PF, 236, 498, PF + 0.12, 244, MAT.Fabric, CLOTH, "Carpet")
		B(498, PF, 226, 503, PF + 0.8, 254, MAT.Slate, GOTH_LT, "Dais")
		B(503, PF, 226, 514, PF + 0.8, 230, MAT.Slate, GOTH_LT, "Dais")
		B(503, PF, 250, 514, PF + 0.8, 254, MAT.Slate, GOTH_LT, "Dais")
		B(498, PF + 0.8, 236, 503, PF + 0.92, 244, MAT.Fabric, CLOTH, "Carpet")
		-- THE THRONE'S LIFT: the dais's upper tier (x 503..514, z 230..250) and the throne on it, on a deep iron base;
		-- ridden down the shaft into the Sunken Court (init.server, as the great lift)
		local liftModel = Instance.new("Model")
		liftModel.Name = "ThroneLift"
		liftModel.Parent = mainFolder
		folder = liftModel
		B(503, PF + 0.8, 230, 514, PF + 1.6, 250, MAT.Slate, GOTH_LT, "Dais")
		B(503.3, PF - 4, 230.3, 513.7, PF + 0.8, 249.7, MAT.Metal, IRON, "LiftBase")
		B(503.2, PF - 4.3, 230.2, 513.8, PF - 3.9, 249.8, MAT.Neon, C3(255, 120, 40), "LiftGlow")
		for _, c in ipairs({ { 503.6, 230.6 }, { 513.4, 230.6 }, { 503.6, 249.4 }, { 513.4, 249.4 } }) do
			P({ Name = "LiftBoss", Shape = Enum.PartType.Ball, Size = Vector3.one * 0.9, CFrame = CFrame.new(c[1], PF + 1.7, c[2]), Material = MAT.Metal, Color = GOLD, CanCollide = false })
		end
		do -- the throne: black iron, gold-trimmed, a tall spiked back
			local y, X = PF + 1.6, 510
			B(X - 3.5, y, 237, X + 0.5, y + 2, 243, MAT.Metal, IRON, "Throne")
			B(X + 0, y, 236.6, X + 1.6, y + 15, 243.4, MAT.Metal, IRON, "ThroneBack")
			B(X - 3.5, y + 2, 236.4, X + 0.5, y + 3.6, 237.2, MAT.Metal, IRON, "ThroneArm")
			B(X - 3.5, y + 2, 242.8, X + 0.5, y + 3.6, 243.6, MAT.Metal, IRON, "ThroneArm")
			B(X - 3.8, y + 1.9, 237, X - 3.4, y + 2.1, 243, MAT.Metal, GOLD, "ThroneTrim")
			B(X - 0.2, y + 14.6, 236.4, X + 1.8, y + 15.2, 243.6, MAT.Metal, GOLD, "ThroneTrim")
			for i, z in ipairs({ 237, 238.7, 240, 241.3, 243 }) do
				local h = (i == 3) and 5 or (i == 2 or i == 4) and 3.6 or 2.4
				blk("ThroneSpike", V3(0.5, h, 0.5), CFrame.new(X + 0.8, y + 15 + h / 2, z), MAT.Metal, IRON)
			end
			blk("ThroneSun", V3(0.3, 4, 4), CFrame.new(X - 0.1, y + 11, 240) * CFrame.Angles(math.pi / 4, 0, 0), MAT.Neon, C3(255, 120, 40), false)
		end
		folder = mainFolder
		do
			local top = CFrame.new(508.5, PF + 1.6, 240)
			throneLift = { Top = top, Bottom = CFrame.new(508.5, AF + 5.6, 240), At = "Top", Parts = {}, HalfX = 5.6, HalfZ = 10.2, Speed = 8 }
			local seat
			for _, d in ipairs(liftModel:GetDescendants()) do
				if d:IsA("BasePart") then
					table.insert(throneLift.Parts, { d, top:ToObjectSpace(d.CFrame) })
					if d.Name == "Throne" then
						seat = d
					end
				end
			end
			throneLift.Deck = seat
			throneLift.Prompt = prompt(seat, "Ride", "The Throne", 0.8, 9)
			-- the lever that calls it back up, beside the shaft on the dais
			B(499.6, PF + 0.8, 232.4, 500.8, PF + 4, 233.6, MAT.Metal, IRON, "LeverPost")
			local h = blk("LeverHandle", V3(0.3, 2.2, 0.3), CFrame.new(500.2, PF + 4.6, 233) * CFrame.Angles(0, 0, 0.5), MAT.Metal, GOLD, false)
			throneLift.CallTop = prompt(h, "Pull", "Lever", 0.4, 7)
		end
		banner(CFrame.new(513.8, PF + 24, 240) * CFrame.Angles(0, -math.pi / 2, 0), 10, 26)
		for _, z in ipairs({ 208, 226, 254, 272 }) do
			banner(CFrame.new(468.2, PF + 22, z) * CFrame.Angles(0, math.pi / 2, 0), 4, 12)
		end
		for _, x in ipairs({ 484, 496 }) do
			sconce(V3(x, PF + 8, 200), ZIN)
		end
		brazier(V3(500, 0, 229), PF + 0.8)
		brazier(V3(500, 0, 251), PF + 0.8)
		for _, c in ipairs({ { 478, 240 }, { 492, 240 }, { 486, 224 } }) do
			chandelier(V3(c[1], PF + 26, c[2]), EY - 0.7)
		end
		-- the balcony: along its north wall and down its east side to the library's door, a balustrade on its edge, posts
		B(468, UF - 1.2, 268, 514, UF, 278, MAT.Slate, WALK, "Balcony")
		B(506, UF - 1.2, 254, 514, UF, 268, MAT.Slate, WALK, "Balcony")
		parapet(468, 267.2, 506, 268, UF)
		parapet(505.2, 254, 506, 267.2, UF)
		parapet(506, 254, 514, 254.8, UF)
		for _, p in ipairs({ { 488, 268 }, { 500, 268 }, { 506, 260 } }) do
			clusterPier(V3(p[1], 0, p[2]), PF, UF - 1.2, 1.1, CFrame.new())
		end
		for x = 470, 512, 6 do
			blk("BalconyCorbel", V3(1, 1.4, 1.2), CFrame.new(x, UF - 1.9, 268.4), MAT.Slate, GOTH_LT, false)
		end
		-- 14 THE SUNKEN COURT (x 422..542, z 172..268): its floor at 12, its vault at 68, cut out of the rock under the
		-- forecourt and the throne hall. Clad in dark stone and marble; galleries down its sides on cluster piers and
		-- arches; great transverse arches across its vault; at its west end the sun-king enthroned in stone, thirty high,
		-- under a sun of fire; down its east wall two falls of lava; the throne's lift comes down through its vault onto a
		-- stepped dais near its east end. Kept clear down its middle, for a fight
		do
			local LAVA_C = C3(255, 90, 24)
			local DARK, PALE, VEIN = C3(34, 20, 20), C3(78, 66, 58), C3(120, 92, 50)
			-- the floor: a field of marble, dark and pale; a sun inlaid in gold and fire in its middle
			for x = AX1, AX2 - 0.1, 8 do
				for z = AZ1, AZ2 - 0.1, 8 do
					local dark = ((x - AX1) / 8 + (z - AZ1) / 8) % 2 == 0
					B(x, AF, z, x + 8, AF + 0.2, z + 8, MAT.Marble, dark and DARK or PALE, "CourtFloor")
				end
			end
			local SC = V3(474, AF + 0.2, 220)
			for i, r in ipairs({ 15, 14.2, 9, 8.4, 3.4 }) do
				P({ Name = "SunInlay", Shape = Enum.PartType.Cylinder, Size = V3(0.06 + i * 0.01, r * 2, r * 2), CFrame = CFrame.new(SC + V3(0, i * 0.01, 0)) * UPRIGHT, Material = i % 2 == 1 and MAT.Metal or MAT.Marble, Color = i % 2 == 1 and GOLD or DARK, CanCollide = false })
			end
			P({ Name = "SunHeart", Shape = Enum.PartType.Cylinder, Size = V3(0.12, 5, 5), CFrame = CFrame.new(SC + V3(0, 0.06, 0)) * UPRIGHT, Material = MAT.Neon, Color = LAVA_C, CanCollide = false })
			for i = 0, 23 do
				local a = i / 24 * math.pi * 2
				local len = i % 2 == 0 and 10 or 6
				local c = SC + V3(math.cos(a) * (15 + len / 2), 0.04, math.sin(a) * (15 + len / 2))
				blk("SunRay", V3(i % 2 == 0 and 1.4 or 0.9, 0.08, len), CFrame.lookAt(c, c + V3(math.cos(a), 0, math.sin(a))), MAT.Metal, GOLD, false)
			end
			-- the walls clad, a wainscot of marble, lava running in gutters at their feet
			B(AX1, AF, AZ1, AX2, AC, AZ1 + 0.4, MAT.Slate, GOTH, "Clad")
			B(AX1, AF, AZ2 - 0.4, AX2, AC, AZ2, MAT.Slate, GOTH, "Clad")
			B(AX1, AF, AZ1 + 0.4, AX1 + 0.4, AC, AZ2 - 0.4, MAT.Slate, GOTH, "Clad")
			B(AX2 - 0.4, AF, AZ1 + 0.4, AX2, AC, PASSAGE[2], MAT.Slate, GOTH, "Clad") -- (the east wall's: round the passage)
			B(AX2 - 0.4, AF, PASSAGE[4], AX2, AC, AZ2 - 0.4, MAT.Slate, GOTH, "Clad")
			B(AX2 - 0.4, PT, PASSAGE[2], AX2, AC, PASSAGE[4], MAT.Slate, GOTH, "Clad")
			B(AX1, AF, AZ1 + 0.4, AX2, AF + 4, AZ1 + 0.9, MAT.Marble, DARK, "Wainscot")
			B(AX1, AF, AZ2 - 0.9, AX2, AF + 4, AZ2 - 0.4, MAT.Marble, DARK, "Wainscot")
			B(AX2 - 0.9, AF, AZ1 + 0.9, AX2 - 0.4, AF + 4, PASSAGE[2], MAT.Marble, DARK, "Wainscot")
			B(AX2 - 0.9, AF, PASSAGE[4], AX2 - 0.4, AF + 4, AZ2 - 0.9, MAT.Marble, DARK, "Wainscot")
			B(AX1, AF + 4, AZ1 + 0.4, AX2, AF + 4.4, AZ1 + 1.1, MAT.Metal, GOLD, "WainscotRail")
			B(AX1, AF + 4, AZ2 - 1.1, AX2, AF + 4.4, AZ2 - 0.4, MAT.Metal, GOLD, "WainscotRail")
			for _, z in ipairs({ AZ1 + 0.9, AZ2 - 2.3 }) do
				B(AX1 + 1, AF + 0.2, z, AX2 - 1, AF + 0.4, z + 1.4, MAT.Neon, LAVA_C, "LavaGutter")
				light(ghost(V3(452, AF + 2, z + 0.7)), LAVA_C, 50, 0.8)
				light(ghost(V3(512, AF + 2, z + 0.7)), LAVA_C, 50, 0.8)
			end
			-- the vault: clad, open over the lift's shaft, a gold frame round that; a ridge rib down its middle
			B(AX1, AC - 0.4, AZ1, 503, AC, AZ2, MAT.Slate, GOTH_DK, "Vault")
			B(514, AC - 0.4, AZ1, AX2, AC, AZ2, MAT.Slate, GOTH_DK, "Vault")
			B(503, AC - 0.4, AZ1, 514, AC, 230, MAT.Slate, GOTH_DK, "Vault")
			B(503, AC - 0.4, 250, 514, AC, AZ2, MAT.Slate, GOTH_DK, "Vault")
			B(502, AC - 1.8, 229, 515, AC - 0.4, 230, MAT.Metal, GOLD, "ShaftFrame")
			B(502, AC - 1.8, 250, 515, AC - 0.4, 251, MAT.Metal, GOLD, "ShaftFrame")
			B(502, AC - 1.8, 230, 503, AC - 0.4, 250, MAT.Metal, GOLD, "ShaftFrame")
			B(514, AC - 1.8, 230, 515, AC - 0.4, 250, MAT.Metal, GOLD, "ShaftFrame")
			blk("RidgeRib", V3(AX2 - AX1, 1.2, 1.8), CFrame.new((AX1 + AX2) / 2, AC - 1, 220), MAT.Slate, GOTH_LT, false)
			-- the colonnades: cluster piers down both sides, arches between them, galleries over the aisles behind
			for x = 434, 530, 12 do
				for _, z in ipairs({ 180, 260 }) do
					clusterPier(V3(x, 0, z), AF, 50, 3, CFrame.new())
					if x < 530 then
						archRibs(V3(x + 1.5, 50, z), V3(x + 10.5, 50, z), 57, ZIN, 1.2, 2.6, GOTH_LT)
					end
				end
				if math.abs(x - 508.5) > 8 then -- (a great arch across the vault from each pair - not across the shaft)
					archRibs(V3(x, 50, 181.5), V3(x, 50, 258.5), AC - 1.5, XIN, 1.5, 2.4, GOTH_LT)
				end
			end
			for _, g in ipairs({ { AZ1 + 0.4, 179 }, { 261, AZ2 - 0.4 } }) do
				B(AX1 + 0.4, 50, g[1], AX2 - 0.4, 51.2, g[2], MAT.Slate, GOTH_DK, "Gallery")
			end
			parapet(AX1 + 0.4, 178.2, AX2 - 0.4, 179, 51.2)
			parapet(AX1 + 0.4, 261, AX2 - 0.4, 261.8, 51.2)
			for x = 440, 524, 12 do -- banners hung from the galleries, lancets and lamps in the walls above them
				banner(CFrame.new(x, 43.5, 179.2), 4, 12)
				banner(CFrame.new(x, 43.5, 260.8) * CFrame.Angles(0, math.pi, 0), 4, 12)
				lancet(V3(x, 53.5, AZ1 + 0.45), 3.2, 11, XIN, ZIN)
				lancet(V3(x, 53.5, AZ2 - 0.45), 3.2, 11, XIN, ZOUT)
			end
			for x = 434, 530, 24 do
				sconce(V3(x, 56, AZ1 + 0.4), ZIN)
				sconce(V3(x, 56, AZ2 - 0.4), ZOUT)
			end
			-- the old guard in stone down the aisles, between the piers, facing in
			for x = 440, 524, 24 do
				for _, s in ipairs({ { 176, 1 }, { 264, -1 } }) do
					B(x - 1.8, AF, s[1] - 1.8, x + 1.8, AF + 1.6, s[1] + 1.8, MAT.Marble, DARK, "Plinth")
					statue(CFrame.lookAt(V3(x, AF + 1.6, s[1]), V3(x, AF + 1.6, s[1] + s[2] * 10)), 0.75)
				end
			end
			-- THE SUN-KING at the west end: a plinth, stood before the back of a throne of stone, the king himself in stone,
			-- colossal, glaive in hand (info.KingStatues); behind him on the wall a sun of fire with rays of gold
			B(424, AF, 202, 440, AF + 6, 238, MAT.Marble, DARK, "ColossusPlinth")
			B(423.6, AF + 6, 201.6, 440.4, AF + 6.6, 238.4, MAT.Metal, GOLD, "ColossusPlinthRim")
			for i = 1, 3 do
				B(440, AF, 210 - i, 440 + i * 1.6, AF + 6 - i * 1.5, 230 + i, MAT.Marble, DARK, "ColossusStep")
			end
			do
				local f = CFrame.lookAt(V3(432, AF + 6.6, 220), V3(500, AF + 6.6, 220))
				local function s(name, size, off, col, mat)
					blk(name, size, f * off, mat or MAT.Slate, col or PALE)
				end
				s("KingThroneBack", V3(15, 26, 2.4), CFrame.new(0, 13, 6.4), GOTH)
				s("KingThroneTrim", V3(15.6, 1, 2.8), CFrame.new(0, 26.4, 6.4), GOLD, MAT.Metal)
				for i = -2, 2 do
					s("KingThroneSpire", V3(1.2, 4 - math.abs(i) * 0.8, 1.2), CFrame.new(i * 3.2, 28.6 - math.abs(i) * 0.4, 6.4), GOTH)
				end
				info.KingStatues = info.KingStatues or {}
				table.insert(info.KingStatues, { Foot = f * CFrame.new(0, 0, -2), Scale = 4.5 }) -- (some 40 high, glaive to 45)
			end
			local SUNC = V3(422.6, 46, 220)
			P({ Name = "SunOfFire", Shape = Enum.PartType.Cylinder, Size = V3(0.4, 22, 22), CFrame = CFrame.new(SUNC), Material = MAT.Neon, Color = LAVA_C, CanCollide = false })
			P({ Name = "SunRing", Shape = Enum.PartType.Cylinder, Size = V3(0.5, 24, 24), CFrame = CFrame.new(SUNC - V3(0.1, 0, 0)), Material = MAT.Metal, Color = GOLD, CanCollide = false })
			for i = 0, 23 do
				local a = i / 24 * math.pi * 2
				local len = i % 2 == 0 and 9 or 5
				blk("SunRayWall", V3(0.3, len, i % 2 == 0 and 1.6 or 1), CFrame.new(SUNC + V3(0.2, math.sin(a) * (12 + len / 2), math.cos(a) * (12 + len / 2))) * CFrame.Angles(-a, 0, 0) * CFrame.Angles(math.pi / 2, 0, 0), MAT.Metal, GOLD, false)
			end
			light(ghost(V3(430, 46, 220)), LAVA_C, 60, 2.4)
			embers(V3(426, 46, 220), V3(2, 20, 20), 20)
			for _, z in ipairs({ 196, 244 }) do -- great braziers either side of him
				B(434, AF, z - 2.5, 439, AF + 6, z + 2.5, MAT.Marble, DARK, "BrazierPlinth")
				P({ Name = "GreatBrazier", Shape = Enum.PartType.Cylinder, Size = V3(2, 7, 7), CFrame = CFrame.new(436.5, AF + 7, z) * UPRIGHT, Material = MAT.Metal, Color = IRON })
				P({ Name = "GreatBrazierCoals", Shape = Enum.PartType.Cylinder, Size = V3(0.4, 6, 6), CFrame = CFrame.new(436.5, AF + 8, z) * UPRIGHT, Material = MAT.Neon, Color = LAVA_C, CanCollide = false })
				fire(V3(436.5, AF + 10, z), 12, 16)
				embers(V3(436.5, AF + 10, z), V3(4, 2, 4), 14)
				light(ghost(V3(436.5, AF + 14, z)), C3(255, 130, 60), 60, 2)
			end
			-- the east wall: two falls of lava down it into basins, windows of fire between
			for _, z in ipairs({ 196, 244 }) do
				B(540.6, AF + 1, z - 2, 541.6, AC - 3, z + 2, MAT.Neon, LAVA_C, "Lavafall")
				B(540, AC - 4, z - 3, 542, AC - 2, z + 3, MAT.Slate, GOTH_LT, "LavafallMouth")
				B(536, AF, z - 4, 541.6, AF + 1.4, z + 4, MAT.Slate, GOTH_DK, "LavaBasin")
				B(536.6, AF + 1, z - 3.4, 541.6, AF + 1.5, z + 3.4, MAT.Neon, LAVA_C, "LavaPool")
				embers(V3(538, AF + 3, z), V3(4, 2, 6), 16)
				smoke(V3(538, AF + 4, z), 6, 3)
				light(ghost(V3(536, AF + 8, z)), LAVA_C, 50, 2)
			end
			for _, z in ipairs({ 208, 232 }) do
				lancet(V3(AX2 - 0.45, 30, z), 3.4, 18, ZIN, XOUT)
			end
			-- THE PASSAGE OF FIRE: a great arch cut into the east wall between the falls, 16 wide, 22 high, 10 deep, and
			-- filled - like the Veil of Flame, but a whole doorway of it - with smouldering dark fire so dense you see three
			-- or four feet into it and no further: layer on layer of unlit, near-opaque flame (deep red to black), tongues
			-- of brighter fire licking through it and up out of its mouth, embers, a low glow
			do
				local x1, z1, x2, z2 = PASSAGE[1], PASSAGE[2], PASSAGE[3], PASSAGE[4]
				local zc, w, h = (z1 + z2) / 2, z2 - z1, PT - AF
				B(x1, AF - 0.2, z1, x2, AF, z2, MAT.CrackedLava, C3(60, 18, 8), "PassageFloor") -- (charred, cracked through)
				for _, z in ipairs({ z1 - 1.6, z2 }) do -- the jambs, and the arch's lintel and keystone
					B(AX2 - 1.4, AF, z, AX2 + 0.2, PT, z + 1.6, MAT.Slate, GOTH_LT, "PassageJamb")
				end
				B(AX2 - 1.4, PT, z1 - 1.6, AX2 + 0.2, PT + 2, z2 + 1.6, MAT.Slate, GOTH_LT, "PassageLintel")
				blk("PassageKeystone", V3(1.8, 3.2, 2.4), CFrame.new(AX2 - 0.7, PT + 1.2, zc), MAT.Slate, GOTH)
				B(AX2 - 1.5, PT - 0.4, z1 - 1.6, AX2 - 1.3, PT, z2 + 1.6, MAT.Metal, GOLD, "PassageLintelEdge")
				local DEEP, BLOOD, BLACK = C3(120, 26, 8), C3(70, 12, 6), C3(14, 8, 6)
				-- what stops the eye: veils of dark fire-glow hung across it a stud and a half apart, each half seen
				-- through - three of them and you see nothing - and the passage's far end blacked out behind
				for i = 0, 5 do
					local v = P({ Name = "PassageVeil", Size = V3(0.2, h, w), CFrame = CFrame.new(x1 + 0.3 + i * 1.6, AF + h / 2, zc), Material = MAT.SmoothPlastic, Color = C3(70, 16, 8):Lerp(C3(8, 5, 4), i / 5), Transparency = i == 0 and 0.5 or 0.4, CanCollide = false, CanQuery = false, CanTouch = false })
					v.CastShadow = false
				end
				B(x2 - 0.4, AF, z1, x2, PT, z2, MAT.SmoothPlastic, C3(4, 3, 3), "PassageDark")
				-- and a blind of solid dark behind the second veil, walk-through: the king waits behind it unseen, and
				-- comes out of it (the veils alone let him show through)
				local blind = P({ Name = "PassageBlind", Size = V3(0.2, h, w), CFrame = CFrame.new(x1 + 3.1, AF + h / 2, zc), Material = MAT.SmoothPlastic, Color = C3(6, 4, 3), CanCollide = false, CanQuery = false, CanTouch = false })
				blind.CastShadow = false
				-- the mass: sheets of it every stud and a half from the mouth back, each a box of churning fire
				for i = 0, 6 do
					local e = Instance.new("ParticleEmitter")
					e.Texture = "rbxasset://textures/particles/fire_main.dds"
					e.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, DEEP), ColorSequenceKeypoint.new(0.45, BLOOD), ColorSequenceKeypoint.new(1, BLACK) })
					e.LightEmission = i == 0 and 0.35 or 0.15
					e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(0.5, 6.5), NumberSequenceKeypoint.new(1, 4.5) })
					e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(0.15, 0.02), NumberSequenceKeypoint.new(0.8, 0.1), NumberSequenceKeypoint.new(1, 1) })
					e.Lifetime, e.Speed = NumberRange.new(2, 3.2), NumberRange.new(0.5, 1.5)
					e.Rotation, e.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-35, 35)
					e.Acceleration, e.Drag = V3(0, 2.2, 0), 1
					e.Shape, e.ShapeStyle, e.Rate = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume, 36
					e.Parent = ghost(V3(x1 - 0.2 + i * 1.5, AF + h / 2, zc), V3(0.6, h, w))
				end
				-- the tongues: brighter fire through it, licking up out of the mouth
				local t = Instance.new("ParticleEmitter")
				t.Texture = "rbxasset://textures/particles/fire_main.dds"
				t.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C3(255, 150, 60)), ColorSequenceKeypoint.new(0.4, C3(200, 50, 12)), ColorSequenceKeypoint.new(1, C3(60, 10, 4)) })
				t.LightEmission = 0.6
				t.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.5), NumberSequenceKeypoint.new(1, 0.4) })
				t.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
				t.Lifetime, t.Speed, t.SpreadAngle = NumberRange.new(0.6, 1.2), NumberRange.new(2, 5), Vector2.new(20, 20)
				t.Rotation, t.RotSpeed, t.Acceleration = NumberRange.new(0, 360), NumberRange.new(-90, 90), V3(0, 9, 0)
				t.Shape, t.ShapeStyle, t.Rate = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume, 40
				t.Parent = ghost(V3(x1 + 0.6, AF + h * 0.4, zc), V3(1.6, h * 0.8, w - 1))
				embers(V3(x1 + 0.5, AF + 2, zc), V3(2, 2, w), 22)
				fire(V3(x1 - 0.4, AF + 1, zc - 4), 10, 12)
				fire(V3(x1 - 0.4, AF + 1, zc + 4), 10, 12)
				light(ghost(V3(x1 - 2, AF + 6, zc)), C3(200, 50, 16), 30, 1.4)
			end
			-- the vault's chandeliers: great wheels of lamps on long chains (kept off the shaft)
			for _, c in ipairs({ { 446, 200 }, { 446, 240 }, { 478, 200 }, { 478, 240 } }) do
				local cp = V3(c[1], 46, c[2])
				P({ Name = "GreatChandelier", Shape = Enum.PartType.Cylinder, Size = V3(0.6, 10, 10), CFrame = CFrame.new(cp) * UPRIGHT, Material = MAT.Metal, Color = IRON, CanCollide = false })
				P({ Name = "GreatChandelierRim", Shape = Enum.PartType.Cylinder, Size = V3(0.3, 10.6, 10.6), CFrame = CFrame.new(cp + V3(0, 0.3, 0)) * UPRIGHT, Material = MAT.Metal, Color = GOLD, CanCollide = false })
				blk("ChandelierChain", V3(0.3, AC - 0.4 - cp.Y, 0.3), CFrame.new(cp + UPV * ((AC - 0.4 - cp.Y) / 2)), MAT.Metal, IRON, false)
				for i = 0, 9 do
					local a = i / 10 * math.pi * 2
					lantern(cp + V3(math.cos(a) * 4.6, 0.3, math.sin(a) * 4.6))
				end
			end
			for x = 446, 530, 28 do -- (just light enough to fight by: it's meant to be dark down here)
				for _, z in ipairs({ 196, 244 }) do
					light(ghost(V3(x, 36, z)), C3(255, 160, 100), 60, 0.55)
				end
			end
			embers(V3(482, 30, 220), V3(110, 20, 80), 26)
			-- the lift's landing: three steps up all round to where the throne comes down (x 503..514, z 230..250)
			local function ringStep(x1, z1, x2, z2, h, ix1, iz1, ix2, iz2)
				B(x1, AF, z1, x2, AF + h, iz1, MAT.Marble, PALE, "LandingStep")
				B(x1, AF, iz2, x2, AF + h, z2, MAT.Marble, PALE, "LandingStep")
				B(x1, AF, iz1, ix1, AF + h, iz2, MAT.Marble, PALE, "LandingStep")
				B(ix2, AF, iz1, x2, AF + h, iz2, MAT.Marble, PALE, "LandingStep")
				B(x1 - 0.1, AF + h - 0.2, z1 - 0.1, x2 + 0.1, AF + h, z1 + 0.3, MAT.Metal, GOLD, "StepNosing")
			end
			ringStep(497, 224, 520, 256, 1.4, 499, 226, 518, 254)
			ringStep(499, 226, 518, 254, 2.8, 501, 228, 516, 252)
			ringStep(501, 228, 516, 252, 4.2, 503, 230, 514, 250)
			B(503, AF, 230, 514, AF + 0.4, 250, MAT.Slate, GOTH_DK, "LandingPit")
			B(494.4, AF, 235.4, 495.6, AF + 3.4, 236.6, MAT.Metal, IRON, "LeverPost")
			local h = blk("LeverHandle", V3(0.3, 2.2, 0.3), CFrame.new(495, AF + 4, 236) * CFrame.Angles(0, 0, 0.5), MAT.Metal, GOLD, false)
			throneLift.CallBottom = prompt(h, "Pull", "Lever", 0.4, 7)
			-- the king himself, in his arena: waiting unseen inside the passage of fire, facing out west down the court
			-- (he walks out of it when someone comes far enough up the court: Trigger, the x past which they've come)
			table.insert(info.EnemySpawns, { Type = "KingInquisitor", CFrame = CFrame.lookAt(V3(549, AF + 3.2, 220), V3(500, AF + 3.2, 220)) })
			table.insert(info.Zones, 1, { Name = "The Sunken Court", MinX = AX1, MaxX = AX2, MinZ = AZ1, MaxZ = AZ2, MaxY = AC + 2 })
			info.SunkenCourt = { MinX = AX1, MaxX = AX2, MinZ = AZ1, MaxZ = AZ2, Floor = AF, Centre = V3(482, AF, 220), Trigger = 469, Mouth = V3(PASSAGE[1], AF, (PASSAGE[2] + PASSAGE[4]) / 2) }
		end
		-- the triforium, high in its north-east corner (128), in from the library's mezzanine; its stair down west along
		-- the north wall onto the balcony
		B(506, 126.8, 252, 514, 128, 278, MAT.Slate, WALK, "Triforium")
		B(502, 126.8, 270, 506, 128, 278, MAT.Slate, WALK, "Triforium")
		parapet(505.2, 252, 506, 269.2, 128)
		parapet(505.2, 251.2, 514, 252, 128)
		parapet(502, 269.2, 506, 270, 128)
		steps(V3(484, UF, 274), V3(502, 128, 274), 5)
		for x = 508, 513, 5 do
			blk("TriforiumCorbel", V3(1, 1.4, 1.2), CFrame.new(x, 126.1, 252.4), MAT.Slate, GOTH_LT, false)
		end
		guard(492, PF, 233, 470, 240)
		-- THE GREAT DOORS: two leaves shut in the doorway (z 234..240, 240..246), a beam across them inside in iron
		-- brackets. Lifted from inside (init.server), the beam is set aside and they swing in for good; from the
		-- forecourt they won't budge. Each leaf kept with its offset from its hinge
		local palaceDoor = { Leaves = {}, Inside = function(p)
			return p.X > 468
		end }
		table.insert(palaceDoors, palaceDoor)
		for _, sd in ipairs({ -1, 1 }) do
			local hinge = CFrame.new(467.4, PF, 240 + sd * 6)
			local leaf = { Hinge = hinge, Parts = {}, Angle = sd * math.rad(-100) } -- (each swings in, to +x)
			local function lp(name, size, off, mat, col, collide)
				local p = blk(name, size, hinge * off, mat, col, collide)
				table.insert(leaf.Parts, { p, off })
			end
			lp("GreatDoor", V3(0.9, 19.5, 6), CFrame.new(0, 9.75, -sd * 3), MAT.WoodPlanks, WOOD_DK)
			leafHead(lp, 0.9, 12, 19.5, 4.5, sd * 6, math.min(0, sd * 6), math.max(0, sd * 6), MAT.WoodPlanks, WOOD_DK) -- (its doorway: 12 wide, 24 high)
			for _, y in ipairs({ 2.5, 9.5, 16.5 }) do
				lp("DoorBand", V3(1.1, 0.6, 6), CFrame.new(0, y, -sd * 3), MAT.Metal, IRON, false)
			end
			lp("DoorRing", V3(1.2, 1.2, 0.3), CFrame.new(-0.6, 9, -sd * 5.2), MAT.Metal, GOLD, false)
			table.insert(palaceDoor.Leaves, leaf)
		end
		palaceDoor.Bar = blk("DoorBar", V3(0.9, 1.1, 15), CFrame.new(468.4, PF + 10, 240), MAT.Wood, WOOD, false)
		palaceDoor.BarAside = CFrame.new(469.2, PF + 7.5, 231.8) * CFrame.Angles(0.25, 0, 0) * CFrame.Angles(math.pi / 2, 0, 0)
		for _, z in ipairs({ 233.2, 246.8 }) do
			blk("BarBracket", V3(1.2, 1.6, 0.6), CFrame.new(468.4, PF + 10, z), MAT.Metal, IRON, false)
		end
		local inSpot = ghost(V3(469.5, PF + 5, 240))
		local outSpot = ghost(V3(464.5, PF + 5, 240))
		palaceDoor.Prompt = prompt(inSpot, "Lift the bar", "Great Doors", 0.8, 8)
		palaceDoor.LockedPrompt = prompt(outSpot, "Open", "Great Doors", 0, 8)

		-- 8 THE EAST WING (x 558..594, z 200..270), over the narrow court east of the library: solid to 114; the hall of
		-- arms, its middle (the well, x 566..584, z 236..262) open to the roof; the armoury south of it under the upper
		-- floor (128) - the solar - and a gallery round the well's other three sides at 128; the stair up in the armoury's
		-- east side. Bridges to the library: an open one at 114 (z 262..268), a covered one at 128 (z 250..256)
		local WY = 152
		wall(558, PF, 200, 594, WY, 202)
		wall(558, PF, 268, 594, WY, 270)
		wall(592, PF, 202, 594, WY, 268)
		wall(558, PF, 202, 560, WY, 268, { { 250, 256, 128, 136 }, { 262, 268, UF, UF + 10 } })
		doorway(V3(558, UF, 265), 6, 10, ZIN, XOUT, 2)
		doorway(V3(558, 128, 253), 6, 8, ZIN, XOUT, 2)
		B(560, PF, 202, 592, UF - 0.2, 268, MAT.Basalt, GOTH_DK, "WingFill")
		B(560, UF - 0.2, 202, 592, UF, 268, MAT.Slate, WALK, "WingFloor")
		gable(558, 200, 594, 270, WY, 14, false)
		cornice(558, 200, 594, 270, WY - 0.8, WY)
		tower(594, 201, 6, 178, 594)
		tower(594, 269, 5, 166, 594)
		-- the upper floor (128): the solar over the armoury, its stairwell (x 585..592, z 207..229); the galleries
		B(560, 126.8, 202, 585, 128, 236, MAT.WoodPlanks, WOOD, "UpperFloor")
		B(585, 126.8, 202, 592, 128, 207, MAT.WoodPlanks, WOOD, "UpperFloor")
		B(585, 126.8, 229, 592, 128, 236, MAT.WoodPlanks, WOOD, "UpperFloor")
		B(584, 126.8, 236, 592, 128, 262, MAT.WoodPlanks, WOOD, "Gallery")
		B(560, 126.8, 262, 592, 128, 268, MAT.WoodPlanks, WOOD, "Gallery")
		B(560, 126.8, 248, 566, 128, 262, MAT.WoodPlanks, WOOD, "Gallery")
		parapet(560, 236, 583.2, 236.8, 128)
		parapet(583.2, 236.8, 584, 261.2, 128)
		parapet(566, 261.2, 584, 262, 128)
		parapet(566, 248, 566.8, 261.2, 128)
		parapet(560, 247.2, 566.8, 248, 128)
		parapet(584.2, 207, 585, 229, 128)
		parapet(584.2, 206.2, 592, 207, 128)
		steps(V3(588.5, UF, 209), V3(588.5, 128, 229), 5)
		for _, p in ipairs({ { 566.4, 236.4 }, { 583.6, 236.4 }, { 583.6, 261.6 }, { 566.4, 261.6 }, { 575, 236.4 } }) do
			clusterPier(V3(p[1], 0, p[2]), UF, 126.8, 1.1, CFrame.new())
		end
		-- the hall of arms: suits of armour on plinths round the well, banners hung from the galleries
		for _, p in ipairs({ { 569, 240, 575, 250 }, { 581, 240, 575, 250 }, { 569, 258, 575, 250 }, { 581, 258, 575, 250 } }) do
			B(p[1] - 1.4, UF, p[2] - 1.4, p[1] + 1.4, UF + 1.6, p[2] + 1.4, MAT.Slate, GOTH, "Plinth")
			statue(CFrame.lookAt(V3(p[1], UF + 1.6, p[2]), V3(p[3], UF + 1.6, p[4])), 0.45)
		end
		for _, x in ipairs({ 570, 580 }) do
			banner(CFrame.new(x, 120.5, 261.9), 3.5, 9)
		end
		chandelier(V3(575, 142, 249), 162)
		-- the armoury: racks of arms down its walls, a grindstone, a forge-brazier
		for _, z in ipairs({ 208, 216, 224 }) do
			B(560, UF, z - 2, 561, UF + 0.6, z + 2, MAT.Wood, WOOD_DK, "Rack")
			B(560, UF + 5, z - 2, 561, UF + 5.4, z + 2, MAT.Wood, WOOD_DK, "Rack")
			for dz = -1.5, 1.6, 1 do
				blk("RackPole", V3(0.25, 8, 0.25), CFrame.new(560.6, UF + 4, z + dz) * CFrame.Angles(0, 0, -0.08), MAT.Wood, WOOD, false)
				blk("RackHead", V3(0.15, 1.6, 0.9), CFrame.new(560.3, UF + 8.4, z + dz), MAT.Metal, IRON, false)
			end
		end
		for _, x in ipairs({ 566, 574, 582 }) do
			B(x - 1.6, UF, 202, x + 1.6, UF + 0.5, 203.4, MAT.Wood, WOOD_DK, "ShieldShelf")
			P({ Name = "Shield", Shape = Enum.PartType.Cylinder, Size = V3(0.3, 2.8, 2.8), CFrame = CFrame.new(x, UF + 4, 202.25) * CFrame.Angles(0, math.pi / 2, 0), Material = MAT.Metal, Color = IRON })
			blk("ShieldBoss", V3(0.3, 0.9, 0.9), CFrame.new(x, UF + 4, 202.45), MAT.Metal, GOLD, false)
		end
		P({ Name = "Grindstone", Shape = Enum.PartType.Cylinder, Size = V3(0.8, 3, 3), CFrame = CFrame.new(572, UF + 2, 228), Material = MAT.Slate, Color = GOTH_LT })
		B(571, UF, 227.4, 573, UF + 0.8, 228.6, MAT.Wood, WOOD_DK, "GrindstoneFrame")
		brazier(V3(578, 0, 214), UF)
		for _, x in ipairs({ 568, 580 }) do
			sconce(V3(x, UF + 7, 202), ZIN)
		end
		-- the solar: the sun of Pyralis in gold and fire on its south wall, a long table, a hearth
		P({ Name = "SunDisc", Shape = Enum.PartType.Cylinder, Size = V3(0.4, 8, 8), CFrame = CFrame.new(575, 140, 202.25) * CFrame.Angles(0, math.pi / 2, 0), Material = MAT.Neon, Color = C3(255, 120, 40), CanCollide = false })
		for i = 0, 11 do
			local a = i / 12 * math.pi * 2
			blk("SunRay", V3(0.8, 4.5, 0.3), CFrame.new(575 + math.cos(a) * 6.4, 140 + math.sin(a) * 6.4, 202.2) * CFrame.Angles(0, 0, a - math.pi / 2), MAT.Metal, GOLD, false)
		end
		light(ghost(V3(575, 140, 205)), C3(255, 130, 60), 30, 1.6)
		B(564, 128 + 2.4, 212, 580, 128 + 3, 216, MAT.WoodPlanks, WOOD, "Table")
		for _, e in ipairs({ { 565, 213 }, { 579, 213 }, { 565, 215 }, { 579, 215 } }) do
			B(e[1] - 0.25, 128, e[2] - 0.25, e[1] + 0.25, 130.4, e[2] + 0.25, MAT.Wood, WOOD_DK, "TableLeg")
		end
		for _, x in ipairs({ 568, 576 }) do
			lantern(V3(x, 131, 214))
		end
		for _, z in ipairs({ 212, 224, 246, 258 }) do -- windows east, both floors
			lancet(V3(594.05, UF + 3, z), 2.6, 9, ZIN, XIN)
			lancet(V3(594.05, 128 + 4, z), 2.6, 12, ZIN, XIN)
		end
		for _, x in ipairs({ 566, 584 }) do
			lancet(V3(x, 128 + 4, 199.95), 2.6, 12, XIN, ZOUT)
		end
		guard(575, UF, 250, 560, 265, "Forgeknight") -- (in the well, where there's room to swing)
		guard(582, UF, 224, 575, 236, "Ashsmith") -- (in the armoury, by the grindstone)
		guard(568, UF, 220, 575, 236, "Pyre") -- (the east wing was four brutes in thirty studs: two of them mages now)
		guard(570, 128, 222, 588.5, 229, "Pyre") -- (up in the solar, casting down)
		-- the bridges over the court: open at 114, covered at 128, corbelled out under
		B(550, UF - 1.6, 262, 558, UF, 268, MAT.Slate, WALK, "Bridge")
		parapet(550, 261.2, 558, 262, UF)
		parapet(550, 268, 558, 268.8, UF)
		B(550, 126.4, 250, 558, 128, 256, MAT.Slate, WALK, "Bridge")
		B(550, 128, 249.2, 558, 135.6, 250, MAT.Basalt, GOTH, "BridgeWall")
		B(550, 128, 256, 558, 135.6, 256.8, MAT.Basalt, GOTH, "BridgeWall")
		B(549.6, 135.6, 248.8, 558.4, 136.6, 257.2, MAT.Slate, GOTH_DK, "BridgeRoof")
		for _, z in ipairs({ 263, 267, 251, 255 }) do
			local y = z > 260 and UF - 1.6 or 126.4
			blk("BridgeCorbel", V3(8, 1.6, 1), CFrame.new(554, y - 0.8, z), MAT.Slate, GOTH_LT)
		end

		-- 6 THE NORTH GALLERY (114) over 7 THE SERVANTS' PASSAGE (100): a long wing north of the forecourt and on east
		-- behind the throne hall; the gallery's floor open at its west end over the stair down
		wall(418, PF, 280, 466, 130, 282, { { 449, 455, UF, UF + 10 } })
		wall(418, PF, 294, 486, 130, 296)
		wall(418, PF, 282, 420, 130, 294)
		wall(484, PF, 280, 486, 130, 294)
		doorway(V3(452, UF, 280), 6, 10, XIN, ZOUT, 2)
		gable(418, 280, 486, 296, 130, 8, true)
		cornice(418, 280, 486, 296, 129.2, 130)
		B(420, UF - 1.2, 282, 484, UF, 288, MAT.WoodPlanks, WOOD, "GalleryFloor")
		B(466, UF - 1.2, 280, 484, UF, 282, MAT.WoodPlanks, WOOD, "GalleryFloor")
		B(440, UF - 1.2, 288, 484, UF, 294, MAT.WoodPlanks, WOOD, "GalleryFloor")
		-- the stair: its foot out in the passage (east), climbing west to a landing against the west wall - a foot
		-- against that wall left no room to get onto it
		B(420, UF - 1.2, 288, 425, UF, 294, MAT.WoodPlanks, WOOD, "GalleryFloor")
		parapet(425, 287.2, 440, 288, UF) -- (round the stairwell: open at the landing)
		parapet(439.2, 288, 440, 294, UF)
		steps(V3(441, PF, 290.6), V3(425, UF, 290.6), 4.6)
		for x = 426, 481, 9 do -- portraits of the house down its north wall, busts along its south, windows out north
			B(x - 2, UF + 3, 293.6, x + 2, UF + 8.4, 294, MAT.Metal, GOLD, "PortraitFrame")
			B(x - 1.6, UF + 3.4, 293.4, x + 1.6, UF + 8, 293.6, MAT.SmoothPlastic, C3(RP(30, 60), RP(20, 40), RP(18, 34)), "Portrait")
			lancet(V3(x + 4.5, UF + 2, 296.05), 2.2, 10, XIN, ZIN)
		end
		for _, x in ipairs({ 430, 442, 462, 474 }) do
			B(x - 0.8, UF, 282, x + 0.8, UF + 3.6, 283.6, MAT.Slate, GOTH, "BustPlinth")
			P({ Name = "Bust", Shape = Enum.PartType.Ball, Size = Vector3.one * 1.6, CFrame = CFrame.new(x, UF + 4.4, 282.8), Material = MAT.Slate, Color = GOTH_LT })
		end
		B(442, UF, 288.4, 482, UF + 0.12, 291.6, MAT.Fabric, CLOTH, "Carpet")
		for _, x in ipairs({ 436, 458, 476 }) do
			chandelier(V3(x, UF + 11, 288), 137.5)
		end
		guard(462, UF, 290, 482, 284, "Executioner")
		-- the balcony over the forecourt: a ladder lies on it, through the door; kicked down, it stands from the
		-- forecourt up to the gap in its balustrade - the first shortcut (init.server kickLadder, as the yard's)
		B(447, UF - 1.2, 276, 457, UF, 280, MAT.Slate, WALK, "Balcony")
		parapet(447, 276, 447.8, 280, UF)
		parapet(456.2, 276, 457, 280, UF)
		parapet(447.8, 276, 451, 276.8, UF)
		parapet(453, 276, 456.2, 276.8, UF)
		for _, x in ipairs({ 448.5, 455.5 }) do
			blk("BalconyCorbel", V3(1, 2.4, 3.6), CFrame.new(x, UF - 2.4, 278), MAT.Slate, GOTH_LT)
		end
		do
			local LEN = 15
			local truss = Instance.new("TrussPart")
			truss.Name = "PalaceLadder"
			truss.Size = V3(2, LEN, 2)
			truss.Anchored, truss.Transparency = true, 1
			truss.CanCollide, truss.CanQuery = false, false
			local down = CFrame.new(452, PF + LEN / 2, 275.3)
			truss.CFrame = down
			truss.Parent = folder
			for _, x in ipairs({ -0.8, 0.8 }) do
				local p = P({ Name = "LadderWood", Size = V3(0.28, LEN, 0.32), CFrame = down * CFrame.new(x, 0, 0), Material = MAT.Wood, Color = WOOD, CanCollide = false, CanQuery = false, CanTouch = false, Massless = true })
				p.Anchored = false
				local w = Instance.new("WeldConstraint")
				w.Part0, w.Part1 = truss, p
				w.Parent = p
			end
			for y = -LEN / 2 + 0.6, LEN / 2 - 0.4, 1 do
				local p = P({ Name = "LadderWood", Size = V3(1.65, 0.16, 0.18), CFrame = down * CFrame.new(0, y, 0), Material = MAT.Wood, Color = WOOD_DK, CanCollide = false, CanQuery = false, CanTouch = false, Massless = true })
				p.Anchored = false
				local w = Instance.new("WeldConstraint")
				w.Part0, w.Part1 = truss, p
				w.Parent = p
			end
			truss.CFrame = CFrame.new(452, UF + 0.3, 276.6 + LEN / 2) * CFrame.Angles(math.pi / 2, 0, 0) -- (lying, its foot at the gap)
			local function spot(pos)
				return ghost(pos)
			end
			local function climbPrompt(pos)
				local pp = prompt(spot(pos), "Climb", "Ladder", 0, 6)
				pp.Enabled = false
				return pp
			end
			palaceLadder = {
				Ladder = truss,
				Down = down,
				Prompt = prompt(spot(V3(452, UF + 1.5, 278)), "Kick down", "Ladder", 0, 7),
				UpPrompt = climbPrompt(V3(452, PF + 2.5, 274.2)),
				DownPrompt = climbPrompt(V3(452, UF + 2, 278.2)),
				Climb = { foot = V3(452, PF + 3, 274.3), top = V3(452, UF + 3.15, 274.3), off = V3(452, UF + 3.15, 278.4), facing = ZIN },
			}
		end
		-- the servants' passage: stores, a hearth, the stair up at its west end, the door into the throne hall at its east
		B(456, PF, 293, 464, PF + 7, 294, MAT.Slate, GOTH_DK, "Hearth")
		B(457, PF, 292, 463, PF + 0.6, 293, MAT.Slate, GOTH_DK, "HearthStone")
		fire(V3(460, PF + 1.2, 292.8), 3)
		light(ghost(V3(460, PF + 3, 291.5)), C3(255, 130, 60), 22, 1.6)
		B(455.5, PF + 7, 291.8, 464.5, PF + 7.6, 294, MAT.Slate, GOTH_LT, "Mantel")
		-- tucked in the dark corner under the stair's landing, behind a barrel: the Pyre Priest's vestments
		chest(422.4, PF, 285, -math.pi / 2, { Attr = "PyreRobes", Text = "Pyre Priest's Vestments. Ash and crimson, the hem singed and never burnt through, a breastplate under it all. Press T to choose weapons and armor." })
		for _, b in ipairs({ { 425.6, 283.2 }, { 470, 292.8 }, { 472.2, 292.6 } }) do
			P({ Name = "Barrel", Shape = Enum.PartType.Cylinder, Size = V3(2.2, 1.8, 1.8), CFrame = CFrame.new(b[1], PF + 1, b[2]) * UPRIGHT, Material = MAT.WoodPlanks, Color = WOOD_DK })
		end
		for _, c in ipairs({ { 476, 291.5 }, { 478.5, 291.2 }, { 477, 291.4, 2 } }) do
			blk("Crate", V3(2.2, 2.2, 2.2), CFrame.new(c[1], PF + 1.1 + (c[3] and 2.2 or 0), c[2]) * CFrame.Angles(0, RP(-0.3, 0.3), 0), MAT.WoodPlanks, WOOD)
		end
		for x = 428, 482, 18 do
			sconce(V3(x, PF + 6.5, 282), ZIN)
		end
		table.insert(info.Zones, 1, { Name = "Palace of Pyralis", MinX = 414, MaxX = 596, MinZ = 164, MaxZ = 296, MinY = 70 })
	end
	info.PalaceParts = {}
	for _, c in ipairs(folder:GetChildren()) do
		if not beforePalace[c] then
			table.insert(info.PalaceParts, c)
		end
	end

	-- THE BRIMSTONE: shards of basalt, sulphur and obsidian breaking the lava's skin everywhere, in clusters, fire and
	-- smoke among them - kept off the spires' feet, the keep's pedestal and the lift's tower (and all far under the bridges)
	local feet = { { V3(356, 0, 328), 30 }, { V3(C.X, 0, C.Z), 46 }, { H3c, 26 }, { H1c, 36 }, { H2c, 28 }, { V3(241, 0, -50), 80 }, { V3(452, 0, 230), 72 }, { V3(530, 0, 218), 52 }, { V3(576, 0, 234), 46 } } -- (the last four: the Censery, the palace)
	for _, sp in ipairs({ S1, S2, S3, S5, S6, S7, S8, BR[1], BR[2], BR[3], BR[4], BR[5], BR[6] }) do
		table.insert(feet, { sp, 18 })
	end
	local function clear(p)
		for _, f in ipairs(feet) do
			if (V3(p.X, 0, p.Z) - V3(f[1].X, 0, f[1].Z)).Magnitude < f[2] then
				return false
			end
		end
		return true
	end
	local SHARD = { -- (all dark: basalt, scorched slate, obsidian, a few glowing at the core)
		{ MAT.Basalt, C3(40, 34, 32) },
		{ MAT.Basalt, C3(30, 26, 26) },
		{ MAT.Basalt, C3(54, 44, 38) },
		{ MAT.Slate, C3(46, 38, 34) },
		{ MAT.Slate, C3(62, 50, 42) },
		{ MAT.Glass, C3(22, 16, 20) }, -- (obsidian)
		{ MAT.Glass, C3(14, 10, 14) },
		{ MAT.CrackedLava, C3(90, 30, 14) },
	}
	local function brimstone(x1, z1, x2, z2, n)
		for c = 1, n do
			local p = V3(R(x1 + 6, x2 - 6), -5, R(z1 + 6, z2 - 6))
			if clear(p) then
				local big = rng:NextNumber() < 0.45
				for _ = 1, rng:NextInteger(big and 3 or 4, big and 7 or 10) do
					local m = SHARD[rng:NextInteger(1, #SHARD)]
					local h = big and R(4, 14) or R(1.2, 4.5)
					local w = big and R(0.8, 3.2) or R(0.4, 1.6)
					P({ Name = "Brimstone", Size = V3(w, h, w * R(0.6, 1.2)), CFrame = CFrame.new(p + V3(R(-6, 6), h * 0.28, R(-6, 6))) * CFrame.Angles(R(-0.7, 0.7), R(0, 6.28), R(-0.7, 0.7)), Material = m[1], Color = m[2], Reflectance = m[1] == MAT.Glass and 0.15 or 0, CastShadow = big })
				end
				if c % 9 == 0 then
					smoke(p + V3(0, 2, 0), 7, 2)
				end
			end
		end
	end
	brimstone(X1, Z1, X2, Z2, 260)
	brimstone(150, -60, 320, 150, 130)
	brimstone(220, 150, 320, 200, 30)
	-- the crust: rafts of dark rock floating on the lava (terrain, kept well off everything built)
	local function crust(x1, z1, x2, z2, n)
		for _ = 1, n do
			local p = V3(R(x1 + 6, x2 - 6), 0, R(z1 + 6, z2 - 6))
			local rad = R(3, 6)
			local ok = true
			for i, f in ipairs(feet) do
				ok = ok and (V3(p.X, 0, p.Z) - V3(f[1].X, 0, f[1].Z)).Magnitude > f[2] + rad + 4
			end
			if ok then
				T:FillBall(V3(p.X, -5 - rad + R(1, 2.5), p.Z), rad, rng:NextNumber() < 0.7 and MAT.Basalt or MAT.Rock)
			end
		end
	end
	crust(X1, Z1, X2, Z2, 160)
	crust(150, -60, 320, 150, 80)
	crust(220, 150, 320, 200, 16)
	-- THE GREAT SHARDS: crags of black rock thrust up out of the lava, leaning, in clumps of a great one and its lesser
	-- ones - a forest of them for the bridges to pass high over (none reaches past 58: the lowest bridge is at 90)
	local CRAG = { { MAT.Basalt, C3(34, 30, 30) }, { MAT.Basalt, C3(46, 38, 34) }, { MAT.Slate, C3(40, 34, 32) }, { MAT.Rock, C3(30, 27, 27) } }
	local function crags(x1, z1, x2, z2, n)
		for _ = 1, n do
			local p = V3(R(x1 + 8, x2 - 8), 0, R(z1 + 8, z2 - 8))
			local big = R(18, 48)
			local ok = true
			for _, f in ipairs(feet) do
				ok = ok and (V3(p.X, 0, p.Z) - V3(f[1].X, 0, f[1].Z)).Magnitude > f[2] + 32 -- (room for its lean and its lesser ones)
			end
			for _, d in ipairs(LONE) do
				ok = ok and (V3(p.X, 0, p.Z) - V3(d[1], 0, d[2])).Magnitude > 34
			end
			if ok then
				for k = 1, rng:NextInteger(2, 5) do
					local m = CRAG[rng:NextInteger(1, #CRAG)]
					local h = k == 1 and big or big * R(0.3, 0.75)
					local w = k == 1 and R(5, 11) or R(2.5, 7)
					local q = p + (k == 1 and Vector3.zero or V3(R(-7, 7), 0, R(-7, 7)))
					local tilt = CFrame.Angles(R(-0.22, 0.22), R(0, 6.28), R(-0.22, 0.22))
					P({ Name = "Crag", Size = V3(w, h, w * R(0.6, 1)), CFrame = CFrame.new(q + V3(0, -6 + h / 2, 0)) * tilt, Material = m[1], Color = m[2] })
					if k == 1 then -- (its point: a narrower tip, glowing a little at its root where it meets the lava)
						P({ Name = "CragTip", Size = V3(w * 0.5, h * 0.25, w * 0.4), CFrame = CFrame.new(q + V3(0, -6 + h / 2, 0)) * tilt * CFrame.new(0, h * 0.55, 0) * CFrame.Angles(0, 0.4, 0.08), Material = m[1], Color = m[2] })
						P({ Name = "CragRoot", Size = V3(w * 1.15, 1.2, w * 1.1), CFrame = CFrame.new(q + V3(0, -4.6, 0)) * tilt.Rotation, Material = MAT.CrackedLava, Color = C3(120, 36, 14), CanCollide = false })
					end
				end
			end
		end
	end
	crags(X1, Z1, X2, Z2, 120)
	crags(150, -140, 320, 150, 60)
	crags(220, 150, 320, 200, 10)
	embers(V3(C.X, 10, C.Z), V3(300, 4, 340), 50) -- (embers drifting up over all of it)

	table.insert(info.Zones, 1, { Name = "Pyralis Bulwark", MinX = X1, MaxX = X2, MinZ = Z1, MaxZ = Z2, MinY = TOP - 6 }) -- (only up here: the lift's top and on)
	for _, q in ipairs(BRANCH) do
		table.insert(info.Zones, 1, { Name = "Pyralis Bulwark", MinX = q[1], MaxX = q[3], MinZ = q[2], MaxZ = q[4], MinY = TOP - 6 })
	end
	for _, name in ipairs({ "The Censery", "Palace of Pyralis" }) do -- (inside the Bulwark's: put first, so they're found first)
		for i, z in ipairs(info.Zones) do
			if z.Name == name then
				table.insert(info.Zones, 1, table.remove(info.Zones, i))
				break
			end
		end
	end

	-- THE RIDGES: walls of dark rock heaped along the lava's west and north edges and round the south, so from the
	-- township (and the bastion, and the prison) it's a ridge you see, not lava at your feet. Every lump is shrunk to keep
	-- 2 clear of what's built, of the breach's pit and of every spire and hall; none higher than 52 (far under the bridges)
	local KEEP_OFF = { { 59, 224, 161, 296 }, { 99, 295, 161, 391 }, { 159, 329, 281, 421 }, { 60, 181, 196, 221 }, { 56, 105, 92, 181 }, { -56, -44, 92, 105 } }
	local function room(x, z)
		local best = math.sqrt((x - 108) ^ 2 + (z + 32) ^ 2) - 30 -- (the pit)
		for _, q in ipairs(KEEP_OFF) do
			local dx, dz = math.max(q[1] - x, 0, x - q[3]), math.max(q[2] - z, 0, z - q[4])
			best = math.min(best, math.sqrt(dx * dx + dz * dz))
		end
		for _, f in ipairs(feet) do
			best = math.min(best, (V3(x, 0, z) - V3(f[1].X, 0, f[1].Z)).Magnitude - f[2])
		end
		return best - 2
	end
	local function ridge(pts)
		for i = 1, #pts - 1 do
			local a, b = pts[i], pts[i + 1]
			local n = math.max(1, math.floor((b - a).Magnitude / 7))
			for j = 0, n do
				local p = a:Lerp(b, j / n) + V3(R(-3, 3), 0, R(-3, 3))
				for k, L in ipairs({ { 13, 2 }, { 10, 16 }, { 8, 30 }, { 6, 42 } }) do
					if k <= 2 or rng:NextNumber() < 0.75 then
						local rad = math.min(L[1] * R(0.8, 1.2), room(p.X, p.Z))
						if rad >= 3 then
							T:FillBall(V3(p.X + R(-2, 2), L[2] + R(-3, 3), p.Z + R(-2, 2)), rad, rng:NextNumber() < 0.65 and MAT.Basalt or MAT.Rock)
						end
					end
				end
			end
		end
	end
	ridge({ V3(150, 0, 158), V3(209, 0, 158), V3(209, 0, 207), V3(313, 0, 207), V3(313, 0, 515) }) -- (north and west: the township's side)
	ridge({ V3(143, 0, -146), V3(143, 0, 155) }) -- (toward the prison and the pit)
	ridge({ V3(143, 0, -148), V3(327, 0, -148), V3(327, 0, 148) }) -- (and round the south)

	-- THE RIM: the fire ocean walled in by mountains on every side but the township's - north, east, south, and south
	-- and east of the branch - in two ranks, a nearer one and taller peaks behind, some of them burning. Each: a body
	-- of terrain, its slopes plated in slabs of rock leaning on it (basalt, slate, rock, every one a different shade),
	-- a crown of crags; the burning ones a crater with a lava pool, smoke, embers and lava running down from the lip in
	-- cracks; scree and glowing roots at every foot where it meets the lava. Its own random stream
	do
		local rr = Random.new(6161)
		local function Q(a, b)
			return rr:NextNumber(a, b)
		end
		local SKIN = { { MAT.Basalt, C3(36, 32, 32) }, { MAT.Basalt, C3(50, 42, 38) }, { MAT.Rock, C3(44, 38, 36) }, { MAT.Slate, C3(30, 27, 28) }, { MAT.Slate, C3(62, 50, 44) }, { MAT.Rock, C3(28, 24, 24) } }
		local HOT, GLOW = C3(150, 44, 16), C3(255, 96, 30)
		local function rock(name, size, cf)
			local m = SKIN[rr:NextInteger(1, #SKIN)]
			local t = Q(-0.04, 0.04) -- (no two the same shade)
			local col = Color3.new(math.clamp(m[2].R + t, 0, 1), math.clamp(m[2].G + t * 0.8, 0, 1), math.clamp(m[2].B + t * 0.7, 0, 1))
			return P({ Name = name, Size = size, CFrame = cf, Material = m[1], Color = col })
		end
		-- a frame on the cone's surface at angle a, height y: X across the slope, Y up it, Z out of it
		local function onCone(p, h, r, a, y)
			local d = V3(math.cos(a), 0, math.sin(a))
			local at = p + d * r * (1 - y / h) + V3(0, y, 0)
			local up = (V3(0, h, 0) - d * r).Unit
			local out = (d * h + V3(0, r, 0)).Unit
			return CFrame.fromMatrix(at, up:Cross(out).Unit, up, out)
		end
		-- lava run down a slope from y0: a crack of glowing rock, kinking as it goes, widening toward its foot
		local function lavaRun(p, h, r, a, y0)
			local y = y0
			while y > 4 do
				local len = Q(10, 18)
				local cf = onCone(p, h, r, a, y - len / 2)
				local w = 1.2 + (y0 - y) / y0 * 2.4
				P({ Name = "LavaRun", Size = V3(w, len + 1, 0.8), CFrame = cf * CFrame.new(0, 0, 0.6) * CFrame.Angles(0, 0, Q(-0.1, 0.1)), Material = MAT.CrackedLava, Color = GLOW, CanCollide = false })
				P({ Name = "LavaRunCore", Size = V3(w * 0.3, len + 1, 0.3), CFrame = cf * CFrame.new(0, 0, 1.05), Material = MAT.Neon, Color = C3(255, 150, 60), CanCollide = false })
				y -= len
				a += Q(-0.06, 0.06) * 60 / r
			end
		end
		local function peak(p, h, r, burning)
			-- the body: terrain heaped up in narrowing balls
			-- (where the terrain actually tops out - the top ball's crown, a little inside it - so the crags and
			-- crater sit on rock, not on the nominal h far above it)
			local ytop, topXZ = 0, p
			for y = 0, h * 0.78, r * 0.32 do
				local c = V3(p.X + Q(-0.08, 0.08) * r, y, p.Z + Q(-0.08, 0.08) * r)
				local rad = math.max(6, r * (1 - y / h) * Q(0.82, 0.95))
				T:FillBall(c, rad, rr:NextNumber() < 0.7 and MAT.Basalt or MAT.Rock)
				if y + rad * 0.8 > ytop then
					ytop, topXZ = y + rad * 0.8, V3(c.X, 0, c.Z)
				end
			end
			-- the slopes, plated: rings of slabs leaning on it, each at its own angle, ledges jutting off some
			local rings = math.max(3, math.floor(h / 20))
			for i = 0, rings - 1 do
				local y = (i + Q(0.1, 0.6)) / rings * h * 0.82
				local ring = r * (1 - y / h)
				local n = 5 + math.floor(ring / 9)
				for j = 1, n do
					local cf = onCone(p, h, r, (j + Q(-0.3, 0.3)) / n * math.pi * 2, y)
					local s = V3(Q(8, 18) * (0.6 + ring / r * 0.6), Q(14, 34), Q(3, 8))
					rock("RimSlab", s, cf * CFrame.new(0, 0, s.Z * 0.2) * CFrame.Angles(Q(-0.2, 0.2), Q(-0.35, 0.35), Q(-0.3, 0.3)))
					if rr:NextNumber() < 0.35 then
						rock("RimLedge", V3(Q(4, 9), Q(2, 4), Q(4, 8)), cf * CFrame.new(Q(-4, 4), Q(-6, 6), s.Z * 0.6 + 1.5) * CFrame.Angles(Q(-0.2, 0.2), Q(0, 6.28), Q(-0.2, 0.2)))
					end
				end
			end
			local top = topXZ + V3(0, ytop, 0)
			if burning then
				-- the crater: a broken lip of crags round a lava pool, smoking, spitting embers; lava down its sides
				local cr = math.max(8, r * 0.16)
				T:FillBall(top + V3(0, cr * 0.4, 0), cr * 1.1, MAT.Air) -- (the bowl the pool lies in, dug out of the top)
				for j = 1, 11 do
					local a = j / 11 * math.pi * 2 + Q(-0.15, 0.15)
					local d = V3(math.cos(a), 0, math.sin(a))
					local hh = Q(8, 20)
					rock("CraterLip", V3(Q(6, 11), hh, Q(5, 9)), CFrame.lookAt(top + d * cr + V3(0, hh / 2 - 7, 0), top + d * (cr + 10) + V3(0, hh / 2 - 7, 0)) * CFrame.Angles(Q(-0.4, -0.1), 0, Q(-0.2, 0.2)))
				end
				P({ Name = "CraterPool", Shape = Enum.PartType.Cylinder, Size = V3(1, cr * 1.9, cr * 1.9), CFrame = CFrame.new(top + V3(0, -5, 0)) * UPRIGHT, Material = MAT.CrackedLava, Color = GLOW, CanCollide = false })
				P({ Name = "CraterHeart", Shape = Enum.PartType.Cylinder, Size = V3(0.6, cr * 1.1, cr * 1.1), CFrame = CFrame.new(top + V3(0, -4.4, 0)) * UPRIGHT, Material = MAT.Neon, Color = C3(255, 140, 50), CanCollide = false })
				local vent = ghost(top + V3(0, -2, 0), V3(cr * 1.4, 1, cr * 1.4))
				local sm = Instance.new("ParticleEmitter")
				sm.Texture = "rbxasset://textures/particles/smoke_main.dds"
				sm.Color = ColorSequence.new(C3(70, 48, 38), C3(22, 18, 18))
				sm.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, cr * 0.8), NumberSequenceKeypoint.new(1, cr * 4) })
				sm.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
				sm.Lifetime, sm.Speed, sm.Rate = NumberRange.new(8, 14), NumberRange.new(6, 12), 4
				sm.Acceleration, sm.RotSpeed = V3(3, 2, 1), NumberRange.new(-10, 10)
				sm.Shape, sm.EmissionDirection = Enum.ParticleEmitterShape.Box, Enum.NormalId.Top
				sm.Parent = vent
				embers(top + V3(0, 2, 0), V3(cr * 1.6, 2, cr * 1.6), 25)
				light(vent, C3(255, 110, 40), 60, 3)
				for _ = 1, rr:NextInteger(3, 5) do
					lavaRun(p, h, r, Q(0, 6.28), ytop - 6)
				end
			else
				-- a crown of crags, leaning every which way: the jagged skyline
				for _ = 1, rr:NextInteger(4, 7) do
					local hh = Q(14, 36)
					local off = V3(Q(-1, 1), 0, Q(-1, 1)) * r * 0.14
					rock("RimCrag", V3(Q(5, 11), hh, Q(4, 9)), CFrame.new(top + off + V3(0, hh / 2 - 10, 0)) * CFrame.Angles(Q(-0.3, 0.3), Q(0, 6.28), Q(-0.3, 0.3)))
				end
				if rr:NextNumber() < 0.4 then -- (cracks of fire down some of the quiet ones too)
					lavaRun(p, h, r, Q(0, 6.28), ytop * Q(0.5, 0.85))
				end
			end
			-- its foot: scree and boulders, glowing where they sit in the lava
			for _ = 1, rr:NextInteger(8, 14) do
				local a = Q(0, 6.28)
				local q = p + V3(math.cos(a), 0, math.sin(a)) * r * Q(0.85, 1.15)
				local sz = Q(3, 10)
				rock("Scree", V3(sz, sz * Q(0.5, 0.9), sz * Q(0.7, 1.1)), CFrame.new(q + V3(0, -5 + sz * 0.3, 0)) * CFrame.Angles(Q(0, 6.28), Q(0, 6.28), Q(0, 6.28)))
				if rr:NextNumber() < 0.4 then
					P({ Name = "ScreeRoot", Size = V3(sz * 1.3, 1, sz * 1.3), CFrame = CFrame.new(q + V3(0, -4.6, 0)) * CFrame.Angles(0, Q(0, 6.28), 0), Material = MAT.CrackedLava, Color = HOT, CanCollide = false })
				end
			end
		end
		-- the ranks along each side, a to b, out = away from the lava: the near rank with its feet at the edge, the
		-- taller one behind it, staggered
		local function range(a, b, out, step)
			local len = (b - a).Magnitude
			local along = (b - a).Unit
			for s = 0, len, step do
				local base = a + along * s
				local h1, r1 = Q(95, 150), Q(42, 60)
				peak(base + along * Q(-8, 8) + out * (r1 * 0.55 + Q(0, 10)), h1, r1, rr:NextNumber() < 0.12)
				local h2, r2 = Q(160, 250), Q(60, 85)
				peak(base + along * (step / 2 + Q(-10, 10)) + out * (r1 + r2 * 0.6 + Q(10, 35)), h2, r2, rr:NextNumber() < 0.3)
			end
		end
		range(V3(338, 0, 512), V3(700, 0, 512), V3(0, 0, 1), 52) -- north (east of the chasm)
		range(V3(642, 0, 540), V3(642, 0, 100), V3(1, 0, 0), 52) -- east
		range(V3(700, 0, 140), V3(340, 0, 140), V3(0, 0, -1), 52) -- south of the main sea (set back a little: the palace stands near this edge)
		range(V3(330, 0, 120), V3(330, 0, -150), V3(1, 0, 0), 52) -- east of the branch
		range(V3(330, 0, -142), V3(150, 0, -142), V3(0, 0, -1), 52) -- south of the branch
	end
	table.insert(info.Zones, 1, { Name = "Maw of Pyralis", MinX = 254, MaxX = 372, MinZ = 232, MaxZ = 344, MaxY = FY + 30 }) -- (the lair, the run, the shaft's foot)
	local falls = { { X1, Z1, X2, Z2 } }
	for _, q in ipairs(BRANCH) do
		table.insert(falls, q)
	end
	-- the forge-brutes up here too: on the spires' tops along the way (none on the branch to the Censery), and the
	-- keep's roof (x, z, top, then the spot each one faces: the way you come from)
	for _, k in ipairs({
		{ S1, V3(376, 0, 313.6) }, { S2, H3c }, { S3, S2 }, { S5, H1c }, { S6, S5 }, { S8, S7 },
		{ V3(498, 120, 330), KEEP_IN },
	}) do
		local p = k[1] + V3(0, 3.2, 0)
		table.insert(info.EnemySpawns, { Type = brute(), Ledge = true, CFrame = CFrame.lookAt(p, V3(k[2].X, p.Y, k[2].Z)) })
	end
	info.Bulwark = { Falls = falls, FallY = 70, Shaft = { 342, 314, 370, 342 }, Gates = gates, Lair = lair, Lift = lift, Censery = censery, Bells = bells, Drawbridge = drawbridge, PalaceDoors = palaceDoors, PalaceLadder = palaceLadder, ThroneLift = throneLift, Safe = { { 420, 170, 544, 270 } }, Dev = CFrame.lookAt(V3(340, RING_Y + 3, 330), V3(376, RING_Y + 3, 313)) }
end

return M
