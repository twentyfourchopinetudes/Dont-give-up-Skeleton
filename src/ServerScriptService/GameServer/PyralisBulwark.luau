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
	local T = workspace.Terrain
	local rng = Random.new(5151)
	local function R(a, b)
		return rng:NextNumber(a, b)
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
	local BRANCH = { { 150, -60, 320, 150 }, { 220, 150, 320, 200 } }
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
	for _, b in ipairs({ { 372, X2, Z1, Z2 }, { X1, 372, Z1, 312 }, { X1, 372, 344, Z2 }, { 150, 320, -60, 150 }, { 220, 320, 150, 200 } }) do
		table.insert(info.Underfire.Moats, { MinX = b[1], MaxX = b[2], MinZ = b[3], MaxZ = b[4], MaxY = -2.5 })
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
				slab("Buttress", f - 1.2, f + 1.2, y0 - 1.3, (y0 + top) / 2, sd > 0 and HS or -HS - 2.4, sd > 0 and HS + 2.4 or -HS, MAT.Basalt, GOTH)
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
				P({ Name = "Turret", Shape = Enum.PartType.Cylinder, Size = V3(top - y0 + 1.3, 5.5, 5.5), CFrame = CFrame.new(p.X, (y0 - 1.3 + top) / 2, p.Z) * UPRIGHT, Material = MAT.Basalt, Color = GOTH })
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
	local BR = { V3(380, 100, 240), V3(330, 108, 205), V3(280, 100, 170), V3(270, 120, 70), V3(220, 104, 30), V3(175, 116, 0) }
	local H3c, H1c, H2c = V3(411.5, 0, 331), V3(452.5, 0, 415), V3(275, 0, 120)
	-- H3, THE CHAPEL: in low at its back, across to the stair up its right wall, onto the choir loft, out high at its front
	local H3in, H3out, H3ia, H3oa = hall({
		c = H3c, prev = S1, nxt = S2, HF = 15, HS = 10, y0 = 96, eave = 20, roof = "gable", Hg = 10, wing = 3, rose = true,
		doorIn = { s = -3.5, y = 96 }, doorOut = { s = 0, y = 104 },
		floors = { { 4, 13.6, -8.6, 8.6, 104 } },
		stairs = { { -10, 4, 6.1, 96, 104, -1, 5 } },
		rails = { { { 4, -8.6 }, { 4, 3.35 }, y = 104 } },
		posts = { { 4.6, -5, 104 }, { 4.6, 0, 104 } },
		ribs = { -10, -3, 4, 11 }, butt = { -12, -4, 4, 12 }, lancets = { -8, 0, 8 }, lancetH = 12,
		lamps = { -8, 2 }, chandeliers = { { -3, 109 } },
		things = { { "pew", -5, -5 }, { "pew", -2.5, -5 }, { "pew", 0, -5 }, { "altar", 10, 0 }, { "banner", -13.4, 3, 14 } },
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
	-- the branch: S1 -> BR1 -> BR2 -> BR3 -> the tower-house -> BR4 -> BR5 -> BR6, the last looking out to the breach
	do
		local prev = S1
		for i, sp in ipairs(BR) do
			local from = i == 4 and H2out or prev
			local to = i == 3 and H2in or BR[i + 1]
			spire(sp.X, sp.Z, sp.Y, to and { bearing(sp, from), bearing(sp, to) } or { bearing(sp, from) })
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
		-- the last one's top: a broken pointed arch over its rim toward the breach, framing it, and a great basin of fire
		local e = BR[#BR]
		local a = bearing(e, V3(108, 0, -32))
		local dd = V3(math.cos(a), 0, math.sin(a))
		local across = dd:Cross(UPV).Unit
		local o = V3(e.X, e.Y, e.Z) + dd * 7
		blk("ArchPier", V3(1.8, 13, 1.8), CFrame.new(o - across * 4.6 + UPV * 6.5), MAT.Slate, GOTH)
		blk("ArchPier", V3(1.8, 8, 1.8), CFrame.new(o + across * 4.6 + UPV * 4), MAT.Slate, GOTH)
		local L = pointed(o - across * 4.6 + UPV * 13, o + UPV * 17.5, 6)
		for i = 1, #L - 1 do
			rib(L[i], L[i + 1], dd, 1.4, 1.8, GOTH_LT)
		end
		pinnacle(o - across * 4.6 + UPV * 13, 1.2, 4)
		P({ Name = "Basin", Shape = Enum.PartType.Cylinder, Size = V3(1.6, 5, 5), CFrame = CFrame.new(e - dd * 3 + V3(0, 0.8, 0)) * UPRIGHT, Material = MAT.Metal, Color = IRON })
		fire(e - dd * 3 + V3(0, 2.4, 0), 8, 14)
	end
	-- spires that stand alone in the lava, broken or whole, pinnacled (no bridges: they make it a forest of them)
	local LONE = { { 370, 380, 70 }, { 440, 270, 84 }, { 590, 360, 96 }, { 600, 250, 70 }, { 470, 470, 78 }, { 560, 470, 90 }, { 380, 200, 60 }, { 520, 200, 80 }, { 610, 450, 66 }, { 310, 92, 74 }, { 190, 90, 62 }, { 250, -30, 80 }, { 300, 10, 66 }, { 195, -40, 70 }, { 240, 185, 58 } }
	for _, d in ipairs(LONE) do
		local h = d[3]
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
	for _, c in ipairs({ { 340, 312 }, { 372, 344 }, { 340, 344 }, { 356, 309.5 }, { 356, 346.5 } }) do -- (lanterns round its top)
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
	-- the beacon, on the keep's roof: a great iron basin of fire
	B(C.X - 4, KY, C.Z - 4, C.X + 4, KY + 2, C.Z + 4, MAT.Slate, TRIM, "BeaconPlinth")
	P({ Name = "Beacon", Shape = Enum.PartType.Cylinder, Size = V3(2, 9, 9), CFrame = CFrame.new(C.X, KY + 3, C.Z) * UPRIGHT, Material = MAT.Metal, Color = IRON })
	P({ Name = "BeaconCoals", Shape = Enum.PartType.Cylinder, Size = V3(0.4, 8, 8), CFrame = CFrame.new(C.X, KY + 4.1, C.Z) * UPRIGHT, Material = MAT.Neon, Color = C3(255, 80, 20) })
	fire(V3(C.X, KY + 6, C.Z), 20, 25)
	embers(V3(C.X, KY + 6, C.Z), V3(6, 2, 6), 30)
	light(ghost(V3(C.X, KY + 10, C.Z)), C3(255, 110, 40), 60, 3)

	-- THE BRIMSTONE: shards of basalt, sulphur and obsidian breaking the lava's skin everywhere, in clusters, fire and
	-- smoke among them - kept off the spires' feet, the keep's pedestal and the lift's tower (and all far under the bridges)
	local feet = { { V3(356, 0, 328), 30 }, { V3(C.X, 0, C.Z), 46 }, { H3c, 26 }, { H1c, 36 }, { H2c, 28 } }
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
	crags(150, -60, 320, 150, 60)
	crags(220, 150, 320, 200, 10)
	embers(V3(C.X, 10, C.Z), V3(300, 4, 340), 50) -- (embers drifting up over all of it)

	table.insert(info.Zones, 1, { Name = "Pyralis Bulwark", MinX = X1, MaxX = X2, MinZ = Z1, MaxZ = Z2, MinY = TOP - 6 }) -- (only up here: the lift's top and on)
	for _, q in ipairs(BRANCH) do
		table.insert(info.Zones, 1, { Name = "Pyralis Bulwark", MinX = q[1], MaxX = q[3], MinZ = q[2], MaxZ = q[4], MinY = TOP - 6 })
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
	ridge({ V3(143, 0, -66), V3(143, 0, 155) }) -- (toward the prison and the pit)
	ridge({ V3(143, 0, -68), V3(327, 0, -68), V3(327, 0, 148) }) -- (and round the south)
	table.insert(info.Zones, 1, { Name = "Maw of Pyralis", MinX = 254, MaxX = 372, MinZ = 232, MaxZ = 344, MaxY = FY + 30 }) -- (the lair, the run, the shaft's foot)
	local falls = { { X1, Z1, X2, Z2 } }
	for _, q in ipairs(BRANCH) do
		table.insert(falls, q)
	end
	-- the Cinder Knights (Characters/Cinder.lua) up here too: on the spires' tops along the way and the branch, and the
	-- keep's roof (x, z, top, then the spot each one faces: the way you come from)
	for _, k in ipairs({
		{ S1, V3(376, 0, 313.6) }, { S2, H3c }, { S3, S2 }, { S5, H1c }, { S6, S5 }, { S8, S7 },
		{ BR[2], BR[1] }, { BR[5], BR[4] },
		{ V3(490, 120, 326), KEEP_IN },
	}) do
		local p = k[1] + V3(0, 3.2, 0)
		table.insert(info.EnemySpawns, { Type = "Cinder", Ledge = true, CFrame = CFrame.lookAt(p, V3(k[2].X, p.Y, k[2].Z)) })
	end
	info.Bulwark = { Falls = falls, FallY = 70, Shaft = { 342, 314, 370, 342 }, Gates = gates, Lair = lair, Lift = lift, Dev = CFrame.lookAt(V3(340, RING_Y + 3, 330), V3(376, RING_Y + 3, 313)) }
end

return M
