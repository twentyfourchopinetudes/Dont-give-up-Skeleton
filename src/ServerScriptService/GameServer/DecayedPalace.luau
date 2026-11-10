--!nonstrict
-- DecayedPalace: what lies past THE GRAND GATE in the Vale of Errants' north wall - on the left of the track just out of
-- the west tunnel, on the way to the Colosseum. Through the mountain, a dead wood; west out of it, a dead town; and over
-- the town on its crag THE DECAYED PALACE: the Palace of Pyralis room for room (its parts cloned and moved here -
-- info.PalaceParts, from PyralisBulwark), but its fires long out, its stone bleached and mossed, its roofs fallen in, its
-- windows black, ivy down its walls. A grand stair climbs from the town's square to the drawbridge, rotted where it fell.
-- All of it walled in by mountains (the terrain pass heaps them round info.Decayed.Outline).
-- For now nobody gets in: the gate's doors are shut, and the Vale's invisible rim runs across its foot.
--   M.plan(k): in the Vale's section, before the terrain pass - the ground (hidden slabs, so the land pass leaves it be),
--     info.Decayed for the terrain pass, the zones; the Vale's trees cleared from in front of the gate
--   M.build(k): last of all - the gate and its passage through the mountain, the wood, the town, the palace
-- Its own random stream.
local M = {}

local MAT = Enum.Material
local C3 = Color3.fromRGB
local V3 = Vector3.new
local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2) -- (a cylinder's axis is X: stand it on end)

local Y = 26 -- the Vale's ground (LEDGE_Y), and all of this
local GX, GZ, GW = 86, 536, 16 -- the gate: its middle, its face (the Vale's north edge is z 535), its doorway's width
local PZ = 574 -- where its passage comes out into the wood
local SHIFT = V3(-436, -40, 520) -- the Palace of Pyralis -> here: its gate's sill (416, 100, 240) to (-20, 60, 760)
local PF = 60 -- so its floor is here
local WOODS = { { 4, 598, 60, 672 }, { 60, 574, 145, 672 }, { -34, 646, 4, 672 } } -- x1, z1, x2, z2 (the last: into the town)
local TOWN = { -200, 646, -34, 835 }
local PALACE = { -34, 672, 172, 835 } -- (its pedestal, foot and all: x -28..166, z 678..822)
local PASSAGE = { 76, 528, 96, PZ + 2 }
-- round the outside, each edge's outward side (d.Z, -d.X) away from the floor
local OUTLINE = { { -200, 646 }, { 4, 646 }, { 4, 598 }, { 60, 598 }, { 60, 574 }, { 145, 574 }, { 145, 672 }, { 172, 672 }, { 172, 835 }, { -200, 835 } }
local ROAD = { V3(86, Y, 572), V3(84, Y, 596), V3(70, Y, 620), V3(44, Y, 640), V3(16, Y, 656), V3(-16, Y, 663), V3(-40, Y, 665) }

local STONE, STONE_DK, STONE_LT = C3(134, 128, 110), C3(84, 80, 70), C3(176, 170, 150) -- bleached limestone
local MOSS, MOSS_DK = C3(74, 88, 52), C3(44, 54, 34)
local ROT = C3(34, 38, 30)
local VERDI = C3(80, 114, 98) -- bronze gone green
local TIMBER, PLASTER, ROOF = C3(70, 64, 56), C3(150, 142, 120), C3(60, 62, 58)
local CLOTH = C3(96, 88, 70)
local BARK = C3(60, 56, 52)
local WATER = C3(32, 42, 34)

function M.plan(k)
	local box, info, map = k.box, k.info, k.map
	local rects = {}
	for _, q in ipairs(WOODS) do
		table.insert(rects, q)
	end
	table.insert(rects, TOWN)
	for _, q in ipairs(rects) do -- hidden slabs under the terrain's ground (so the land pass counts it built), as the Vale's
		local slab = box(q[1], -20, q[2], q[3], Y - 0.5, q[4], MAT.Ground, C3(48, 44, 38), "DecayedGround")
		slab.Transparency, slab.CastShadow = 1, false
	end
	do -- (the palace's, far under it: its sunken court is cut down to y -28)
		local slab = box(PALACE[1], -60, PALACE[2], PALACE[3], -59, PALACE[4], MAT.Ground, C3(48, 44, 38), "DecayedGround")
		slab.Transparency, slab.CastShadow, slab.CanCollide = 1, false, false
	end
	table.insert(rects, PALACE)
	-- its mountains keep off everyone else's floors too: the Vale, the ravine, the encampment's pit, the gate's passage
	local keep = { PASSAGE, { 170, 452, 280, 540 } }
	for _, src in ipairs({ info.Wilds and info.Wilds.Rects or {}, info.FarSide and info.FarSide.Rects or {} }) do
		for _, q in ipairs(src) do
			table.insert(keep, q)
		end
	end
	info.Decayed = { Y = Y, Rects = rects, Outline = OUTLINE, Keep = keep, Mats = { Enum.Material.Mud, Enum.Material.Ground, Enum.Material.Mud, Enum.Material.Slate } }
	for _, q in ipairs({ { 76, 541, 96, PZ }, WOODS[1], WOODS[2], WOODS[3], TOWN, PALACE }) do
		table.insert(info.Zones, 1, { Name = "Decayed Palace", MinX = q[1], MaxX = q[3], MinZ = q[2], MaxZ = q[4] })
	end
	info.DecayedDev = CFrame.lookAt(V3(82, Y + 3.5, 588), V3(40, Y + 3.5, 640))

	-- a clearing before the gate: the Vale's trees there (each a Trunk and the Boughs and Leaves built after it), its
	-- stones and logs, and the fence along that side of the track
	local function inClearing(p) -- (and round the west tower, which stands in the edge of the woods)
		return (p.X > 46 and p.X < 126 and p.Z > 512 and p.Z < 537) or (p.X > 42 and p.X < 66 and p.Z > 512 and p.Z < 553)
	end
	local group, doomed = nil, {}
	for _, c in ipairs(map:GetChildren()) do
		if c:IsA("BasePart") then
			local n = c.Name
			if n == "Trunk" then
				group = inClearing(c.Position) and doomed or nil
			elseif n ~= "Bough" and n ~= "Leaves" then
				group = nil
			end
			if group or ((n == "Stone" or n == "Log" or n == "RailPost" or n == "RotBeam") and inClearing(c.Position)) then
				table.insert(doomed, c)
			end
		end
	end
	for _, c in ipairs(doomed) do
		c:Destroy()
	end
end

function M.build(k)
	local part, box, info, map = k.part, k.box, k.info, k.map
	local T = workspace.Terrain
	local rng = Random.new(8181)
	local function R(a, b)
		return rng:NextNumber(a, b)
	end
	local folder = Instance.new("Folder")
	folder.Name = "DecayedPalace"
	folder.Parent = map
	local function P(props)
		props.Parent = props.Parent or folder
		return part(props)
	end
	local function B(x1, y1, z1, x2, y2, z2, mat, col, name)
		return box(x1, y1, z1, x2, y2, z2, mat, col, name, folder)
	end
	local function wedge(cf, size, col, mat)
		local w = Instance.new("WedgePart")
		w.Anchored, w.Size, w.CFrame, w.Material, w.Color = true, size, cf, mat or MAT.Cobblestone, col
		w.TopSurface, w.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		w.Name = "Gable"
		w.Parent = folder
		return w
	end
	-- moss in patches (coherent noise, so it runs across neighbouring stones), more of it low down
	local function mossy(col, p, extra)
		local m = math.clamp(0.12 + math.noise(p.X / 19, p.Y / 11, p.Z / 19) * 0.55 + (extra or 0), 0, 0.7)
		return col:Lerp(MOSS:Lerp(MOSS_DK, R(0, 1)), m):Lerp(ROT, R(0, 0.12))
	end
	local function seg(name, a, b, thick, mat, col, collide) -- a timber, root or chain link from a to b
		local d = b - a
		if d.Magnitude < 0.05 then
			return
		end
		return P({ Name = name, Size = V3(thick, thick, d.Magnitude), CFrame = CFrame.lookAt((a + b) / 2, b), Material = mat, Color = col, CanCollide = collide == true })
	end
	local function cyl(name, a, b, dia, col, collide) -- a log from a to b
		local d = b - a
		return P({ Name = name, Shape = Enum.PartType.Cylinder, Size = V3(d.Magnitude, dia, dia), CFrame = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0), Material = MAT.Wood, Color = col, CanCollide = collide == true })
	end
	local function rubble(pos, n, spread, col, parent)
		for _ = 1, n do
			local s = R(0.6, 2.2)
			P({ Name = "Rubble", Size = V3(s * R(0.8, 1.6), s * R(0.5, 0.9), s), CFrame = CFrame.new(pos + V3(R(-spread, spread), s * 0.25, R(-spread, spread))) * CFrame.Angles(R(-0.5, 0.5), R(0, 6.3), R(-0.5, 0.5)), Material = MAT.Limestone, Color = (col or STONE):Lerp(MOSS, R(0, 0.45)), CanCollide = false, Parent = parent })
		end
	end
	-- a curtain of ivy hanging from top down a face (out: the face's outward normal)
	local function ivy(top, out, len)
		local across = out:Cross(V3(0, 1, 0)).Unit
		local w = R(1.2, 3)
		local c = top + out * 0.12 - V3(0, len / 2, 0)
		P({ Name = "Ivy", Size = V3(w, len, 0.2), CFrame = CFrame.lookAt(c, c + out), Material = MAT.Grass, Color = MOSS_DK:Lerp(MOSS, R(0, 1)), CanCollide = false, CastShadow = false })
		for _ = 1, math.floor(len / 6) + 1 do
			local q = top + out * 0.4 + across * R(-w / 2, w / 2) - V3(0, R(0, len), 0)
			P({ Name = "IvyLeaves", Shape = Enum.PartType.Ball, Size = Vector3.one * R(0.8, 1.8), CFrame = CFrame.new(q), Material = MAT.Grass, Color = MOSS:Lerp(MOSS_DK, R(0, 1)), CanCollide = false, CastShadow = false })
		end
	end
	local function mist(pos, size)
		local g = P({ Name = "Mist", Size = size, CFrame = CFrame.new(pos), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Color = ColorSequence.new(C3(150, 156, 136), C3(108, 114, 98))
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 6), NumberSequenceKeypoint.new(1, 14) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.84), NumberSequenceKeypoint.new(1, 1) })
		e.Lifetime, e.Speed, e.RotSpeed = NumberRange.new(10, 16), NumberRange.new(0.3, 1), NumberRange.new(-8, 8)
		e.Rate = 2
		e.Shape = Enum.ParticleEmitterShape.Box
		e.Parent = g
	end
	local function wisp(pos) -- a pale light hanging over rot, as the marsh gives off
		local g = P({ Name = "Wisp", Shape = Enum.PartType.Ball, Size = Vector3.one * 0.5, CFrame = CFrame.new(pos), Material = MAT.Neon, Color = C3(170, 210, 160), CanCollide = false, CanQuery = false, CastShadow = false })
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = C3(150, 200, 140), 14, 0.7
		l.Parent = g
	end
	-- a pointed arch's half: from its springing Sa (rising straight up out of it) to its apex A - 60 degrees of arc, as an
	-- equilateral arch, stretched to fit
	local function pointed(Sa, A, n)
		local pts, h = {}, V3(A.X - Sa.X, 0, A.Z - Sa.Z)
		for i = 0, n do
			local th = math.rad(60) * i / n
			table.insert(pts, Sa + h * ((1 - math.cos(th)) * 2) + V3(0, (A.Y - Sa.Y) * math.sin(th) / 0.8660254, 0))
		end
		return pts
	end
	local function rib(p1, p2, nrm, thick, deep, col)
		local d = p2 - p1
		if d.Magnitude < 0.05 then
			return
		end
		local x = d.Unit
		P({ Name = "Rib", Size = V3(d.Magnitude + thick * 0.4, thick, deep), CFrame = CFrame.fromMatrix((p1 + p2) / 2, x, nrm.Unit:Cross(x)), Material = MAT.Limestone, Color = col, CanCollide = false })
	end
	local function archRibs(Sa, Sb, apexY, nrm, thick, deep, col)
		local m = (Sa + Sb) / 2
		local A = V3(m.X, apexY, m.Z)
		for _, L in ipairs({ pointed(Sa, A, 7), pointed(Sb, A, 7) }) do
			for i = 1, #L - 1 do
				rib(L[i], L[i + 1], nrm, thick, deep, col)
			end
		end
	end
	-- a wall along local x (alongX) or z, from a1 to a2 at fixed, y1..y2, T thick, in the frame cf: holes { u1, u2, v1, v2 }
	-- cut out of it, its top broken down by up to jag (in pieces) if it's a ruin
	local function wallRun(cf, alongX, a1, a2, fixed, y1, y2, th, mat, col, holes, jag, name)
		holes = holes or {}
		local cuts = { a1, a2 }
		for _, h in ipairs(holes) do
			table.insert(cuts, math.clamp(h[1], a1, a2))
			table.insert(cuts, math.clamp(h[2], a1, a2))
		end
		table.sort(cuts)
		for i = 1, #cuts - 1 do
			local u1, u2 = cuts[i], cuts[i + 1]
			if u2 - u1 > 0.05 then
				local um = (u1 + u2) / 2
				local spans = { { y1, y2, true } } -- (the third: the topmost, the one that's broken down)
				for _, h in ipairs(holes) do
					if um > h[1] and um < h[2] then
						local cut = {}
						for _, s in ipairs(spans) do
							if h[4] <= s[1] or h[3] >= s[2] then
								table.insert(cut, s)
							else
								if h[3] > s[1] then
									table.insert(cut, { s[1], h[3], false })
								end
								if h[4] < s[2] then
									table.insert(cut, { h[4], s[2], s[3] })
								end
							end
						end
						spans = cut
					end
				end
				for _, s in ipairs(spans) do
					local broken = jag and s[3]
					local pieces = broken and math.max(1, math.floor((u2 - u1) / 2.5)) or 1
					local pw = (u2 - u1) / pieces
					for kk = 0, pieces - 1 do
						local top = broken and s[2] - R(0, jag) or s[2]
						if top - s[1] > 0.1 then
							local u = u1 + (kk + 0.5) * pw
							local yc = (s[1] + top) / 2
							local lcf = alongX and CFrame.new(u, yc, fixed) or CFrame.new(fixed, yc, u)
							local c = cf * lcf
							P({ Name = name or "Wall", Size = alongX and V3(pw, top - s[1], th) or V3(th, top - s[1], pw), CFrame = c, Material = mat, Color = mossy(col, c.Position, -0.05) })
						end
					end
				end
			end
		end
	end

	---------------------------------------------------------------------------
	-- THE GRAND GATE: a great pointed doorway walled into the mountain's face, two towers either side of it, its doors of
	-- bronze gone green shut and chained, roots grown over them; behind it a vaulted passage through the rock to the wood
	---------------------------------------------------------------------------
	do
		local FACE, BACK = GZ, GZ + 6
		local X1, X2 = GX - GW / 2, GX + GW / 2
		local SPRING, APEX, TOP = Y + 20, Y + 30, Y + 52
		local SOUTH = V3(0, 0, -1)
		local function S(x1, y1, z1, x2, y2, z2, name, col, mat)
			return B(x1, y1, z1, x2, y2, z2, mat or MAT.Limestone, mossy(col or STONE:Lerp(STONE_DK, R(0, 0.4)), V3((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2), 0.05), name or "GateStone")
		end
		-- the mountain it's set in: rock heaped up behind and over it, higher than the Vale's walls round it (never out over
		-- the Vale's floor, z < 535, nor the wood's, z > 574)
		local mats = { MAT.Basalt, MAT.Rock, MAT.Basalt, MAT.Slate }
		for x = 68, 142, 7 do -- (not west of 61: the Vale's woods run up to z 560 there)
			local fall = math.clamp(1 - math.abs(x - GX) / 64, 0, 1)
			for _, lay in ipairs({ { 552, Y + 10 }, { 556, Y + 30 }, { 560, Y + 34 + 26 * fall }, { 552, Y + 40 + 24 * fall } }) do
				local cz = lay[1] + R(-2, 2)
				local r = math.min(R(10, 16), cz - 537, 573 - cz, x - 61)
				T:FillBall(V3(x + R(-2, 2), lay[2] + R(-3, 3), cz), r, mats[rng:NextInteger(1, #mats)])
			end
			if rng:NextNumber() < 0.45 then -- a crag jutting from the top
				local h = R(10, 22)
				T:FillBlock(CFrame.new(x, Y + 52 + 18 * fall + h * 0.3, 556 + R(-3, 3)) * CFrame.Angles(R(-0.3, 0.3), R(0, 6), R(-0.3, 0.3)), V3(R(5, 9), h, R(4, 7)), MAT.Basalt)
			end
		end
		-- the passage cut through it all (whole voxels: x 76..96, y 24..56, z 528..576)
		T:FillBlock(CFrame.new(86, 40, 552), V3(20, 32, 48), MAT.Air)

		-- the face, the doorway through it, its head stepped in from both jambs to the apex (the ribs hide the steps)
		S(58, Y - 2, FACE, X1, TOP, BACK, "GateFace")
		S(X2, Y - 2, FACE, 114, TOP, BACK, "GateFace")
		S(X1, APEX, FACE, X2, TOP, BACK, "GateFace")
		local LV = 6
		for j = 1, LV do
			local fy = (j - 0.5) / LV
			local fw = (GW / 2) * (1 - math.cos(math.asin(fy * 0.8660254))) * 2
			local y1, y2 = SPRING + (j - 1) * (APEX - SPRING) / LV, SPRING + j * (APEX - SPRING) / LV
			S(X1, y1, FACE, X1 + fw, y2, BACK, "GateHead")
			S(X2 - fw, y1, FACE, X2, y2, BACK, "GateHead")
			-- and the tympanum over the doors, set back, filling the rest of the arch
			S(X1 + fw, y1, FACE + 3, X2 - fw, y2, FACE + 4, "Tympanum", STONE_DK)
		end
		-- three orders of archivolts, each standing further out, and their jambs
		for o = 0, 2 do
			local w, z = o * 1.6, FACE - 0.35 - o * 0.5
			local col = mossy(STONE_LT:Lerp(STONE, o * 0.3), V3(GX, SPRING, z), 0)
			archRibs(V3(X1 - w, SPRING, z), V3(X2 + w, SPRING, z), APEX + w * 0.9, SOUTH, 1.3, 0.7 + o * 0.5, col)
			for _, x in ipairs({ X1 - w, X2 + w }) do
				rib(V3(x, Y, z), V3(x, SPRING, z), SOUTH, 1.3, 0.7 + o * 0.5, col)
			end
		end
		-- the relief on the tympanum: a crown, one of its points broken off
		S(GX - 3, SPRING + 1.5, FACE + 2.6, GX + 3, SPRING + 3, FACE + 3, "Crown", STONE_LT)
		for i, x in ipairs({ -2.2, 0, 2.2 }) do
			if i ~= 3 then
				P({ Name = "CrownPoint", Size = V3(1.1, 1.1, 0.4), CFrame = CFrame.new(GX + x, SPRING + 3.6, FACE + 2.8) * CFrame.Angles(0, 0, math.pi / 4), Material = MAT.Limestone, Color = STONE_LT:Lerp(MOSS, 0.2), CanCollide = false })
			end
		end
		-- a band of lettering worn smooth, and the great roundel over it all, its crown worn to a stump
		S(64, Y + 35, FACE - 0.5, 108, Y + 38, FACE, "Inscription", STONE_DK)
		for x = 67, 105, 2.4 do
			if rng:NextNumber() < 0.55 then
				B(x, Y + 36, FACE - 0.6, x + R(0.6, 1.6), Y + 37, FACE - 0.5, MAT.SmoothPlastic, C3(44, 42, 38), "Letter")
			end
		end
		P({ Name = "Roundel", Shape = Enum.PartType.Cylinder, Size = V3(1, 11, 11), CFrame = CFrame.new(GX, Y + 44, FACE - 0.4) * CFrame.Angles(0, math.pi / 2, 0), Material = MAT.Limestone, Color = mossy(STONE_LT, V3(GX, Y + 44, FACE), 0.1) })
		P({ Name = "RoundelRim", Shape = Enum.PartType.Cylinder, Size = V3(0.6, 12.4, 12.4), CFrame = CFrame.new(GX, Y + 44, FACE - 0.2) * CFrame.Angles(0, math.pi / 2, 0), Material = MAT.Limestone, Color = mossy(STONE_DK, V3(GX, Y + 44, FACE), 0.1) })
		S(GX - 2.6, Y + 42, FACE - 1.4, GX + 2.6, Y + 43.5, FACE - 0.9, "RoundelCrown", STONE_LT)
		S(GX - 2.6, Y + 43.5, FACE - 1.4, GX - 1.4, Y + 45.5, FACE - 0.9, "RoundelCrown", STONE_LT)
		S(GX - 0.6, Y + 43.5, FACE - 1.4, GX + 0.6, Y + 44.5, FACE - 0.9, "RoundelCrown", STONE_LT)
		-- a cornice along the face's top, broken off at the east end
		S(56, TOP - 1, FACE - 1.2, 104, TOP + 0.4, BACK, "Cornice", STONE_LT)

		-- THE DOORS: two leaves of bronze in the doorway's back, shut, studded and banded, ring handles, a chain across
		-- them and a lock gone to a lump of green; roots out of the ground grown up over them
		local DZ = FACE + 4.5
		local beforeDoors = {}
		for _, c in ipairs(folder:GetChildren()) do
			beforeDoors[c] = true
		end
		for _, sd in ipairs({ -1, 1 }) do
			local x1, x2 = sd < 0 and X1 or GX, sd < 0 and GX or X2
			B(x1, Y + 0.1, DZ - 0.5, x2, SPRING, DZ + 0.5, MAT.CorrodedMetal, VERDI:Lerp(C3(58, 66, 54), R(0.1, 0.4)), "GateDoor")
			for _, y in ipairs({ 2, 8, 14, 19 }) do
				B(x1 + 0.3, Y + y - 0.4, DZ - 0.7, x2 - 0.3, Y + y + 0.4, DZ - 0.5, MAT.CorrodedMetal, VERDI:Lerp(C3(40, 50, 44), 0.5), "DoorBand")
			end
			for x = x1 + 1.4, x2 - 1, 2.2 do
				for y = 4, 17, 3 do
					P({ Name = "DoorStud", Shape = Enum.PartType.Ball, Size = Vector3.one * 0.6, CFrame = CFrame.new(x, Y + y, DZ - 0.6), Material = MAT.CorrodedMetal, Color = VERDI, CanCollide = false })
				end
			end
			local rx = GX - sd * 1.8
			P({ Name = "DoorRing", Shape = Enum.PartType.Cylinder, Size = V3(0.3, 2.2, 2.2), CFrame = CFrame.new(rx, Y + 9, DZ - 0.75) * CFrame.Angles(0, math.pi / 2, 0), Material = MAT.CorrodedMetal, Color = VERDI:Lerp(C3(30, 34, 30), 0.3), CanCollide = false })
			P({ Name = "DoorRingHole", Shape = Enum.PartType.Cylinder, Size = V3(0.34, 1.5, 1.5), CFrame = CFrame.new(rx, Y + 9, DZ - 0.75) * CFrame.Angles(0, math.pi / 2, 0), Material = MAT.CorrodedMetal, Color = VERDI:Lerp(C3(20, 22, 20), 0.7), CanCollide = false })
		end
		B(GX - 0.15, Y + 0.1, DZ - 0.8, GX + 0.15, SPRING, DZ - 0.5, MAT.SmoothPlastic, C3(10, 12, 10), "DoorSeam")
		do -- the chain, sagging from ring to ring, the lock in its middle
			local a, b = V3(GX - 1.8, Y + 8.2, DZ - 1), V3(GX + 1.8, Y + 8.2, DZ - 1)
			local prev = a
			for i = 1, 6 do
				local t = i / 6
				local p = a:Lerp(b, t) - V3(0, math.sin(t * math.pi) * 1.4, 0.2)
				seg("Chain", prev, p, 0.3, MAT.CorrodedMetal, C3(70, 66, 52))
				prev = p
			end
			P({ Name = "Padlock", Size = V3(1.2, 1.4, 0.6), CFrame = CFrame.new(GX, Y + 6.2, DZ - 1.3), Material = MAT.CorrodedMetal, Color = C3(84, 100, 80), CanCollide = false })
		end
		for _ = 1, 7 do -- roots, up over the doors
			local x0 = R(X1 + 0.5, X2 - 0.5)
			local p = V3(x0, Y, DZ - 1.2)
			for _ = 1, rng:NextInteger(3, 5) do
				local q = p + V3(R(-2.5, 2.5), R(1.5, 3.5), 0)
				q = V3(math.clamp(q.X, X1 + 0.3, X2 - 0.3), math.min(q.Y, SPRING - 1), DZ - 1.2)
				seg("Root", p, q, R(0.35, 0.8), MAT.Wood, BARK:Lerp(C3(40, 34, 28), R(0, 0.6)))
				p = q
			end
		end
		-- (for opening it: init.server's grand gate, with Giles's key) each leaf and what's on it, and what tears away
		local gate = { Leaves = { {}, {} }, Tear = {}, X1 = X1, X2 = X2, DZ = DZ, Y = Y, GX = GX, GW = GW, Padlock = nil }
		for _, c in ipairs(folder:GetChildren()) do
			if not beforeDoors[c] and c:IsA("BasePart") then
				if c.Name == "Chain" or c.Name == "Root" or c.Name == "DoorSeam" or c.Name == "Padlock" then
					table.insert(gate.Tear, c)
					if c.Name == "Padlock" then
						gate.Padlock = c
					end
				else
					table.insert(gate.Leaves[c.Position.X < GX and 1 or 2], c)
				end
			end
		end
		info.DecayedGate = gate
		for _ = 1, 9 do -- ivy down the face
			ivy(V3(R(58, 114), TOP - 0.2, FACE), SOUTH, R(6, 26))
		end

		-- THE TOWERS either side: battered at their feet, banded, slits dark, their battlements fallen in places (the
		-- east one's top broken right down)
		for _, tx in ipairs({ 56, 116 }) do
			local x1, x2, z1, z2 = tx - 6, tx + 6, 530, 548
			S(x1 - 1, Y - 2, z1 - 1, x2 + 1, Y + 6, z2 + 1, "TowerFoot", STONE_DK)
			local broken = tx > GX
			local top = broken and Y + 50 or Y + 66
			S(x1, Y + 6, z1, x2, top, z2, "GateTower")
			for _, y in ipairs({ Y + 24, Y + 46 }) do
				if y < top - 2 then
					S(x1 - 0.5, y, z1 - 0.5, x2 + 0.5, y + 1, z2 + 0.5, "TowerCourse", STONE_LT)
				end
			end
			for _, y in ipairs({ Y + 14, Y + 32, Y + 52 }) do
				if y < top - 6 then
					B(tx - 0.3, y, z1 - 0.1, tx + 0.3, y + 4, z1, MAT.SmoothPlastic, C3(10, 12, 10), "Slit")
				end
			end
			if broken then -- jagged to the sky, its fallen stones heaped below
				for x = x1, x2 - 2, 2 do
					for z = z1, z2 - 2, 3 do
						if rng:NextNumber() < 0.6 then
							S(x, top, z, x + 2, top + R(1, 9), z + 3, "GateTower")
						end
					end
				end
				rubble(V3(tx, Y, z1 - 4), 14, 4, STONE)
			else
				S(x1 - 0.8, top, z1 - 0.8, x2 + 0.8, top + 1.4, z2 + 0.8, "TowerCornice", STONE_LT)
				for t = 0, 1, 1 / 6 do
					for _, e in ipairs({ { x1 + (x2 - x1) * t, z1 }, { x1 + (x2 - x1) * t, z2 }, { x1, z1 + (z2 - z1) * t }, { x2, z1 + (z2 - z1) * t } }) do
						if rng:NextNumber() < 0.7 then
							S(e[1] - 0.8, top + 1.4, e[2] - 0.8, e[1] + 0.8, top + 4.2, e[2] + 0.8, "Merlon")
						end
					end
				end
			end
			for _ = 1, 3 do
				ivy(V3(R(x1 + 1, x2 - 1), top - 0.5, z1 - 0.02), SOUTH, R(8, 30))
			end
		end

		-- THE GUARDIANS on plinths before it, robed, swords point-down - one has lost its head, which lies at its feet
		for i, sx in ipairs({ 70, 102 }) do
			S(sx - 3, Y, 529, sx + 3, Y + 4, 534.6, "GuardianPlinth", STONE_DK)
			local c = V3(sx, Y + 4, 531.8)
			local col = mossy(STONE_LT, c, 0.1)
			P({ Name = "Guardian", Size = V3(3.4, 6, 2.4), CFrame = CFrame.new(c + V3(0, 3, 0)), Material = MAT.Limestone, Color = col })
			P({ Name = "Guardian", Size = V3(2.8, 4, 2), CFrame = CFrame.new(c + V3(0, 8, 0)), Material = MAT.Limestone, Color = col })
			P({ Name = "Guardian", Size = V3(3.6, 1.4, 2.2), CFrame = CFrame.new(c + V3(0, 9.6, 0)), Material = MAT.Limestone, Color = col })
			P({ Name = "GuardianSword", Size = V3(0.5, 8, 0.3), CFrame = CFrame.new(c + V3(0, 4.2, -1.5)), Material = MAT.Limestone, Color = col, CanCollide = false })
			P({ Name = "GuardianSword", Size = V3(2.6, 0.5, 0.4), CFrame = CFrame.new(c + V3(0, 8.4, -1.5)), Material = MAT.Limestone, Color = col, CanCollide = false })
			local head = i == 1 and CFrame.new(sx + 2.6, Y + 1, 526.5) or CFrame.new(c + V3(0, 11.5, 0))
			P({ Name = "GuardianHead", Shape = Enum.PartType.Ball, Size = Vector3.one * 2.2, CFrame = head, Material = MAT.Limestone, Color = col, CanCollide = false })
		end

		-- the apron before it: flagstones, cracked, some gone, tilting (a footing under where the passage's cut took the
		-- ground away)
		B(76, Y - 4, 528, 96, Y - 0.3, 536, MAT.Slate, C3(50, 48, 42), "GateFooting")
		for x = 64.5, 107, 3 do
			for z = 523.5, 535, 3 do
				if rng:NextNumber() < 0.78 then
					P({ Name = "Flagstone", Size = V3(2.9, 0.5, 2.9), CFrame = CFrame.new(x, Y - 0.05, z) * CFrame.Angles(R(-0.04, 0.04), R(-0.05, 0.05), R(-0.04, 0.04)), Material = MAT.Slate, Color = mossy(STONE_DK, V3(x, Y, z), 0.15) })
				end
			end
		end
		rubble(V3(GX + 9, Y, 532), 6, 2.5)

		-- THE PASSAGE: walled, vaulted, ribbed, its floor flagged, a broken arch at its far end, out into the wood
		B(76, Y - 6, BACK - 2, 96, Y + 0.1, PZ + 4, MAT.Slate, C3(66, 64, 56), "PassageFloor")
		S(76, Y, BACK, X1, Y + 30, PZ, "PassageWall", STONE_DK)
		S(X2, Y, BACK, 96, Y + 30, PZ, "PassageWall", STONE_DK)
		S(X1, Y + 28, BACK, X2, Y + 30, PZ, "PassageVault", STONE_DK)
		for z = BACK + 4, PZ - 3, 6 do
			archRibs(V3(X1 + 0.6, Y + 18, z), V3(X2 - 0.6, Y + 18, z), Y + 27.8, V3(0, 0, 1), 1, 1.2, mossy(STONE, V3(GX, Y + 20, z), 0))
			for _, x in ipairs({ X1 + 0.6, X2 - 0.6 }) do
				rib(V3(x, Y, z), V3(x, Y + 18, z), V3(0, 0, 1), 1, 1.2, mossy(STONE, V3(x, Y + 9, z), 0.1))
			end
		end
		for _ = 1, 8 do
			rubble(V3(R(X1 + 1, X2 - 1), Y + 0.1, R(BACK + 2, PZ - 2)), 2, 1)
		end
		S(74, Y, PZ - 1, X1, Y + 24, PZ + 1, "PassageMouth")
		S(X2, Y, PZ - 1, 98, Y + 24, PZ + 1, "PassageMouth")
		S(X1 - 0.5, Y + 21, PZ - 1, GX - 1, Y + 24, PZ + 1, "PassageMouth") -- (its lintel snapped, the rest lying in the way out)
		P({ Name = "FallenLintel", Size = V3(8, 3, 2), CFrame = CFrame.new(GX + 3, Y + 1.6, PZ + 3) * CFrame.Angles(0.2, 0.5, 0.3), Material = MAT.Limestone, Color = mossy(STONE, V3(GX, Y, PZ), 0.2), CanCollide = false })
	end

	---------------------------------------------------------------------------
	-- THE ROAD through the wood and THE WOOD: dead trees, grey and bare, crowding the edges, some snapped off, fungus up
	-- their trunks, grey moss hanging; logs, stumps, black pools, a graveyard, and mist
	---------------------------------------------------------------------------
	local function toRoad(p)
		local best = math.huge
		for i = 1, #ROAD - 1 do
			local a, b = ROAD[i], ROAD[i + 1]
			local ab = b - a
			local t = math.clamp((p - a):Dot(ab) / ab:Dot(ab), 0, 1)
			best = math.min(best, (V3(p.X, Y, p.Z) - (a + ab * t)).Magnitude)
		end
		return best
	end
	for i = 1, #ROAD - 1 do -- trodden mud, flat, as the Vale's track
		local a, b = ROAD[i], ROAD[i + 1]
		local mid, len = (a + b) / 2, (b - a).Magnitude + 5
		T:FillBlock(CFrame.lookAt(mid + V3(0, 2, 0), b + V3(0, 2, 0)), V3(6, 4, len), MAT.Air)
		T:FillBlock(CFrame.lookAt(mid - V3(0, 1, 0), b - V3(0, 1, 0)), V3(6, 2, len), MAT.Mud)
	end
	local POOLS = { { 30, 612, 6 }, { 128, 620, 6 }, { 122, 594, 4.5 }, { 48, 662, 4 } }
	local GRAVES = { 92, 646, 128, 668 }
	local function deadTree(pos, s)
		local h = R(12, 22) * s
		local lean = V3(R(-0.18, 0.18), 1, R(-0.18, 0.18)).Unit
		local snapped = rng:NextNumber() < 0.25
		local top = pos + lean * h * (snapped and R(0.35, 0.6) or 1)
		local col = BARK:Lerp(C3(32, 30, 28), R(0, 0.6))
		local r = R(0.7, 1.1) * s
		local mid = pos:Lerp(top, 0.55)
		cyl("DeadTrunk", pos - V3(0, 0.8, 0), mid, r * 2, col, true)
		cyl("DeadTrunk", mid, top, r * 1.4, col, true)
		for _ = 1, rng:NextInteger(2, 4) do -- roots, out over the ground
			local a = R(0, 6.3)
			seg("DeadRoot", pos + V3(0, 0.6, 0), pos + V3(math.cos(a), 0, math.sin(a)) * R(2.5, 4.5) * s - V3(0, 0.5, 0), r * 0.7, MAT.Wood, col)
		end
		if snapped then -- splinters jagged at the break
			for _ = 1, 4 do
				seg("DeadSplinter", top - V3(0, 0.5, 0), top + V3(R(-0.6, 0.6), R(1, 2.5), R(-0.6, 0.6)), r * 0.5, MAT.Wood, col)
			end
		else
			for _ = 1, rng:NextInteger(3, 6) do -- boughs, bare, crooked, twigs off their ends
				local from = pos:Lerp(top, R(0.45, 0.95))
				local a = R(0, 6.3)
				local out = V3(math.cos(a), R(0.2, 0.9), math.sin(a)).Unit
				local kn = from + out * R(3, 6) * s
				local e = kn + (out + V3(R(-0.5, 0.5), R(-0.3, 0.4), R(-0.5, 0.5))).Unit * R(2, 4.5) * s
				seg("DeadBough", from, kn, 0.55 * s, MAT.Wood, col)
				seg("DeadBough", kn, e, 0.35 * s, MAT.Wood, col)
				for _ = 1, 2 do
					seg("DeadTwig", e, e + V3(R(-2, 2), R(0, 2), R(-2, 2)) * s, 0.16, MAT.Wood, col)
				end
				if rng:NextNumber() < 0.35 then -- grey moss hanging off it
					local ml = R(2, 5)
					P({ Name = "HangingMoss", Size = V3(0.5, ml, 0.5), CFrame = CFrame.new(kn - V3(0, ml / 2, 0)), Material = MAT.Grass, Color = C3(112, 118, 94):Lerp(MOSS, R(0, 0.5)), CanCollide = false, CastShadow = false })
				end
			end
		end
		if rng:NextNumber() < 0.5 then -- bracket fungus up the trunk
			for _ = 1, rng:NextInteger(2, 4) do
				local a = R(0, 6.3)
				local f = R(1.2, 2.2)
				local p = pos + lean * R(1, h * 0.4) + V3(math.cos(a), 0, math.sin(a)) * r
				P({ Name = "Fungus", Shape = Enum.PartType.Cylinder, Size = V3(0.35, f, f), CFrame = CFrame.new(p) * UPRIGHT, Material = MAT.SmoothPlastic, Color = C3(170, 150, 110):Lerp(C3(118, 94, 70), R(0, 1)), CanCollide = false })
			end
		end
	end
	local function inWoods(x, z, m)
		for _, q in ipairs(WOODS) do
			if x > q[1] + m and x < q[3] - m and z > q[2] + m and z < q[4] - m then
				return true
			end
		end
		return false
	end
	local function clearOf(p)
		for _, pl in ipairs(POOLS) do
			if (p.X - pl[1]) ^ 2 + (p.Z - pl[2]) ^ 2 < (pl[3] + 3) ^ 2 then
				return false
			end
		end
		return not (p.X > GRAVES[1] - 2 and p.X < GRAVES[3] + 2 and p.Z > GRAVES[2] - 2 and p.Z < GRAVES[4] + 2) and not (p.X > 70 and p.X < 102 and p.Z < 590)
	end
	for x = -30, 143, 8 do
		for z = 576, 664, 8 do
			local p = V3(x + R(-3, 3), Y, z + R(-3, 3))
			if inWoods(p.X, p.Z, 1.5) and p.Z < 664 and toRoad(p) > 6 and clearOf(p) and rng:NextNumber() < (inWoods(p.X, p.Z, 14) and 0.45 or 0.85) then
				deadTree(p, R(0.8, 1.25))
			end
		end
	end
	for _ = 1, 40 do -- fallen trunks and stumps in the undergrowth
		local p = V3(R(-30, 143), Y, R(576, 668))
		if inWoods(p.X, p.Z, 3) and toRoad(p) > 5 and clearOf(p) then
			local col = BARK:Lerp(MOSS_DK, R(0, 0.5))
			if rng:NextNumber() < 0.5 then
				local a, len = R(0, 6.3), R(6, 13)
				local d = V3(math.cos(a), 0, math.sin(a)) * len / 2
				cyl("FallenTrunk", p - d + V3(0, 0.6, 0), p + d + V3(0, 0.6, 0), R(1.2, 1.8), col, false)
			else
				local hh = R(0.8, 2.4)
				P({ Name = "Stump", Shape = Enum.PartType.Cylinder, Size = V3(hh, R(1.6, 2.6), R(1.6, 2.6)), CFrame = CFrame.new(p + V3(0, hh / 2, 0)) * UPRIGHT, Material = MAT.Wood, Color = col })
			end
		end
	end
	for _, pl in ipairs(POOLS) do -- black water, a scum of moss round its edge
		P({ Name = "Pool", Shape = Enum.PartType.Cylinder, Size = V3(0.2, pl[3] * 2, pl[3] * 2), CFrame = CFrame.new(pl[1], Y + 0.12, pl[2]) * UPRIGHT, Material = MAT.Glass, Color = WATER, Transparency = 0.1, Reflectance = 0.25, CanCollide = false })
		P({ Name = "PoolScum", Shape = Enum.PartType.Cylinder, Size = V3(0.16, pl[3] * 2 + 1.6, pl[3] * 2 + 1.6), CFrame = CFrame.new(pl[1], Y + 0.06, pl[2]) * UPRIGHT, Material = MAT.Grass, Color = MOSS_DK, CanCollide = false })
		wisp(V3(pl[1] + R(-2, 2), Y + R(2, 4), pl[2] + R(-2, 2)))
	end
	do -- the graveyard off the road: stones leaning every which way, a few fallen flat, an iron fence half gone
		local g = GRAVES
		for x = g[1] + 4, g[3] - 3, 5 do
			for z = g[2] + 5, g[4] - 3, 6 do
				local r = rng:NextNumber()
				if r < 0.75 then
					local h = R(2, 3.4)
					local col = mossy(STONE:Lerp(STONE_DK, R(0, 0.5)), V3(x, Y, z), 0.15)
					local cf = r < 0.15 and CFrame.new(x, Y + 0.3, z - h / 2) * CFrame.Angles(math.pi / 2, R(-0.3, 0.3), 0) or CFrame.new(x, Y + h / 2 - 0.4, z) * CFrame.Angles(R(-0.25, 0.25), R(-0.2, 0.2), R(-0.2, 0.2))
					P({ Name = "Headstone", Size = V3(1.7, h, 0.5), CFrame = cf, Material = MAT.Limestone, Color = col })
				end
			end
		end
		local function fence(a, b)
			local n = math.floor((b - a).Magnitude / 2.5)
			for i = 0, n do
				if rng:NextNumber() < 0.7 then
					local p = a:Lerp(b, i / n)
					P({ Name = "GraveRail", Size = V3(0.25, 3.4, 0.25), CFrame = CFrame.new(p + V3(0, 1.7, 0)) * CFrame.Angles(R(-0.15, 0.15), 0, R(-0.15, 0.15)), Material = MAT.CorrodedMetal, Color = C3(74, 64, 52), CanCollide = false })
				end
			end
		end
		fence(V3(g[1], Y, g[2]), V3(g[3], Y, g[2]))
		fence(V3(g[3], Y, g[2]), V3(g[3], Y, g[4]))
		fence(V3(g[1], Y, g[4]), V3(g[3], Y, g[4]))
		fence(V3(g[1], Y, g[2] + 6), V3(g[1], Y, g[4])) -- (its gate gone, toward the road)
		wisp(V3(110, Y + 3, 657))
	end
	for _, m in ipairs({ { 86, 590 }, { 50, 630 }, { 110, 615 }, { 20, 655 }, { 125, 655 }, { 30, 605 } }) do
		mist(V3(m[1], Y + 2, m[2]), V3(26, 2, 26))
	end

	---------------------------------------------------------------------------
	-- THE TOWN: streets of cobbles gone to mud, houses of stone and old timber along them - roofs fallen in, walls broken
	-- down to shells - a square with a well, a chapel open to the sky, and the grand stair up out of the square to the
	-- palace's drawbridge
	---------------------------------------------------------------------------
	T:SetMaterialColor(MAT.Cobblestone, C3(80, 78, 70))
	local STREETS = {
		{ -198, 660, -36, 670, true }, -- the low street, in from the town's gate (x1, z1, x2, z2, along x)
		{ -155, 670, -145, 833, false }, -- the long street north
		{ -198, 755, -155, 765, true }, -- the upper street, west off the square
		{ -100, 670, -92, 748, false }, -- a lane north off the low street
		{ -145, 784, -40, 792, true }, -- and one east off the long street, under the palace's crag
	}
	local SQUARE = { -168, 744, -125, 776 }
	local taken = { { -127, 746, -45, 774 }, { -198, 768, -168, 808 }, { -40, 650, -30, 680 }, SQUARE } -- (the stair, the chapel, the gate)
	for _, s in ipairs(STREETS) do
		table.insert(taken, { s[1] - 0.5, s[2] - 0.5, s[3] + 0.5, s[4] + 0.5 })
	end
	for _, q in ipairs({ STREETS[1], STREETS[2], STREETS[3], STREETS[4], STREETS[5], SQUARE }) do
		local c = CFrame.new((q[1] + q[3]) / 2, Y, (q[2] + q[4]) / 2)
		T:FillBlock(c + V3(0, 2, 0), V3(q[3] - q[1], 4, q[4] - q[2]), MAT.Air)
		T:FillBlock(c - V3(0, 1, 0), V3(q[3] - q[1], 2, q[4] - q[2]), MAT.Cobblestone)
		for _ = 1, math.floor((q[3] - q[1]) * (q[4] - q[2]) / 60) do -- mud where the cobbles are gone
			T:FillBall(V3(R(q[1], q[3]), Y - R(1.2, 2), R(q[2], q[4])), R(1.5, 3), MAT.Mud)
		end
	end
	local function free(x1, z1, x2, z2)
		if x1 < TOWN[1] + 3 or x2 > TOWN[3] - 2 or z1 < TOWN[2] + 3 or z2 > TOWN[4] - 3 then
			return false
		end
		for _, q in ipairs(taken) do
			if x1 < q[3] and x2 > q[1] and z1 < q[4] and z2 > q[2] then
				return false
			end
		end
		return true
	end
	-- its ground: flat mud, so nothing of the terrain pokes up through a floor
	local function flatten(x1, z1, x2, z2)
		local c = CFrame.new((x1 + x2) / 2, Y, (z1 + z2) / 2)
		T:FillBlock(c + V3(0, 3, 0), V3(x2 - x1, 6, z2 - z1), MAT.Air)
		T:FillBlock(c - V3(0, 1, 0), V3(x2 - x1, 2, z2 - z1), MAT.Mud)
	end

	-- a house, its front (with the door) on local -z, w across, d deep: stone below, timber-framed plaster above if it has
	-- two floors. A third of them are shells, roofless, their walls broken down; a third have half the roof fallen in
	local function house(cx, cz, w, d, yaw)
		local cf = CFrame.new(cx, Y, cz) * CFrame.Angles(0, yaw, 0)
		local function L(name, size, lcf, mat, col, collide)
			return P({ Name = name, Size = size, CFrame = cf * lcf, Material = mat, Color = col, CanCollide = collide ~= false })
		end
		local TH = 1.2
		local two = rng:NextNumber() < 0.5
		local H1 = R(9, 10.5)
		local H = two and H1 + R(7, 8.5) or H1
		local fate = rng:NextNumber()
		local shell, halfRoof = fate < 0.3, fate >= 0.3 and fate < 0.65
		local stone = STONE:Lerp(STONE_DK, R(0, 0.7))
		local plaster = PLASTER:Lerp(C3(116, 106, 86), R(0, 0.6))
		local hx, hz = w / 2, d / 2
		local dx = R(-hx + 3, hx - 3)
		local holesF, holesB, windows = { { dx - 1.9, dx + 1.9, -1, 7.4 } }, {}, {}
		for _, wx in ipairs({ -hx + 2.6, hx - 2.6 }) do
			if math.abs(wx - dx) > 4.2 then
				table.insert(holesF, { wx - 1.1, wx + 1.1, 3.8, 7 })
				table.insert(windows, wx)
			end
			if rng:NextNumber() < 0.7 then
				table.insert(holesB, { wx - 1.1, wx + 1.1, 3.8, 7 })
			end
		end
		local top1 = two and H1 or H
		local jag = shell and 4 or nil
		local lowJag = (not two) and jag or nil -- (a two-storey shell keeps its ground floor whole: its upper storey is what's broken)
		local ex, ez = hx, hz -- (its footprint, in the world)
		if math.abs(math.sin(yaw)) > 0.5 then
			ex, ez = hz, hx
		end
		flatten(cx - ex - 0.5, cz - ez - 0.5, cx + ex + 0.5, cz + ez + 0.5)
		wallRun(cf, true, -hx, hx, -hz + TH / 2, 0, top1, TH, MAT.Cobblestone, stone, holesF, lowJag, "HouseWall")
		wallRun(cf, true, -hx, hx, hz - TH / 2, 0, top1, TH, MAT.Cobblestone, stone, holesB, lowJag, "HouseWall")
		for _, sx in ipairs({ -1, 1 }) do
			wallRun(cf, false, -hz + TH, hz - TH, sx * (hx - TH / 2), 0, top1, TH, MAT.Cobblestone, stone, rng:NextNumber() < 0.4 and { { -1.1, 1.1, 3.8, 7 } } or nil, lowJag, "HouseWall")
		end
		L("HouseFloor", V3(w - 2 * TH, 0.3, d - 2 * TH), CFrame.new(0, 0.15, 0), rng:NextNumber() < 0.5 and MAT.WoodPlanks or MAT.Slate, TIMBER:Lerp(C3(40, 36, 30), R(0, 0.6)))
		if two then
			-- the upper floor: plaster between dark timbers, the loft under it
			local up = {}
			for _, wx in ipairs({ -hx + 2.6, hx - 2.6 }) do
				table.insert(up, { wx - 1, wx + 1, H1 + 2.2, H1 + 5.2 })
			end
			wallRun(cf, true, -hx, hx, -hz + TH / 2, H1, H, TH, MAT.Plaster, plaster, up, jag, "HouseUpper")
			wallRun(cf, true, -hx, hx, hz - TH / 2, H1, H, TH, MAT.Plaster, plaster, up, jag, "HouseUpper")
			for _, sx in ipairs({ -1, 1 }) do
				wallRun(cf, false, -hz + TH, hz - TH, sx * (hx - TH / 2), H1, H, TH, MAT.Plaster, plaster, nil, jag, "HouseUpper")
			end
			local tcol = TIMBER:Lerp(C3(36, 32, 28), R(0, 0.5))
			for _, sz in ipairs({ -1, 1 }) do
				local z = sz * (hz + 0.12)
				for _, y in ipairs({ H1 + 0.2, H - 0.25 }) do
					if not (shell and y > H1 + 1) then
						L("Timber", V3(w + 0.2, 0.4, 0.25), CFrame.new(0, y, z), MAT.Wood, tcol, false)
					end
				end
				local n = math.ceil(w / 3)
				for i = 0, n do
					if not shell or rng:NextNumber() < 0.5 then
						L("Timber", V3(0.4, (H - H1) * (shell and R(0.3, 0.8) or 1), 0.25), CFrame.new(-hx + 0.2 + (w - 0.4) * i / n, H1 + (H - H1) * (shell and 0.25 or 0.5), z), MAT.Wood, tcol, false)
					end
				end
			end
			if shell then -- the loft fallen through, slumped from one wall to the floor
				L("FallenLoft", V3(w - 2 * TH, 0.4, (d - 2 * TH) * 0.65), CFrame.new(0, H1 * 0.45, R(-1, 1)) * CFrame.Angles(R(0.7, 1), 0, R(-0.15, 0.15)), MAT.WoodPlanks, TIMBER, false)
			else
				L("HouseLoft", V3(w - 2 * TH, 0.4, d - 2 * TH), CFrame.new(0, H1, 0), MAT.WoodPlanks, TIMBER)
			end
		end
		if not shell then
			-- the roof: a gable, its ridge along x, slates mossed over; or half of it fallen in, bare rafters over the hole
			local rise = d * R(0.34, 0.44)
			local run = hz + 0.8
			local len, th = math.sqrt(run * run + rise * rise) + 0.2, math.atan2(rise, run)
			local roofCol = ROOF:Lerp(MOSS, R(0.1, 0.5))
			local fallen = halfRoof and (rng:NextNumber() < 0.5 and -1 or 1) or 0
			for _, sd in ipairs({ -1, 1 }) do
				local scf = CFrame.new(0, H + rise / 2, sd * run / 2) * CFrame.Angles(sd * th, 0, 0)
				if sd == fallen then
					for x = -hx + 0.6, hx - 0.6, 2.4 do
						if rng:NextNumber() < 0.6 then
							L("Rafter", V3(0.35, 0.35, len), scf * CFrame.new(x, -0.3, 0), MAT.Wood, TIMBER, false)
						end
					end
					L("FallenRoof", V3(w * 0.6, 0.5, len * 0.7), CFrame.new(R(-hx / 3, hx / 3), 1.6, sd * hz * 0.45) * CFrame.Angles(sd * R(0.2, 0.5), R(-0.3, 0.3), R(-0.2, 0.2)), MAT.RoofShingles, roofCol, false)
				else
					L("Roof", V3(w + 1, 0.5, len), scf, MAT.RoofShingles, roofCol)
				end
			end
			local gcol = two and plaster or stone
			for _, gx in ipairs({ -hx + TH / 2, hx - TH / 2 }) do
				wedge(cf * CFrame.new(gx, H + rise / 2, -hz / 2), V3(TH, rise, hz), gcol, two and MAT.Plaster or MAT.Cobblestone)
				wedge(cf * CFrame.new(gx, H + rise / 2, hz / 2) * CFrame.Angles(0, math.pi, 0), V3(TH, rise, hz), gcol, two and MAT.Plaster or MAT.Cobblestone)
			end
			if rng:NextNumber() < 0.5 then
				local x = R(-hx + 2, hx - 2)
				L("Chimney", V3(1.8, rise + 2.5, 1.8), CFrame.new(x, H + (rise + 2.5) / 2, hz * 0.4), MAT.Cobblestone, stone)
			end
		end
		if shell or halfRoof then -- what came down, inside
			for _ = 1, 2 do
				rubble(cf * V3(R(-hx / 2, hx / 2), 0.3, R(-hz / 2, hz / 2)), 4, 1.5, stone)
			end
			if shell then
				seg("FallenBeam", cf * V3(-hx + 1, 0.4, R(-1, 1)), cf * V3(hx - 1, H1 * 0.6, R(-1, 1)), 0.6, MAT.Wood, TIMBER)
			end
		end
		-- the door: hanging open on one hinge, or gone; shutters askew; ivy, a barrel or a crate by the wall
		if rng:NextNumber() < 0.55 then
			L("HouseDoor", V3(3.7, 7.2, 0.25), CFrame.new(dx - 1.9, 0, -hz + 0.6) * CFrame.Angles(0, -R(0.6, 1.4), 0) * CFrame.new(1.85, 3.65, 0), MAT.WoodPlanks, TIMBER:Lerp(C3(48, 42, 34), R(0, 0.5)), false)
		end
		for _, wx in ipairs(windows) do
			if rng:NextNumber() < 0.5 then
				local side = rng:NextNumber() < 0.5 and -1 or 1
				L("Shutter", V3(1.1, 3, 0.15), CFrame.new(wx + side * 1.75, 5.4, -hz - 0.12) * CFrame.Angles(0, 0, side * R(0.1, 0.5)), MAT.WoodPlanks, TIMBER, false)
			end
		end
		if rng:NextNumber() < 0.4 then
			ivy(cf * V3(R(-hx + 1, hx - 1), top1 - 0.2, -hz), cf.LookVector, R(3, top1 - 1))
		end
		local r = rng:NextNumber()
		if r < 0.3 then
			P({ Name = "Barrel", Shape = Enum.PartType.Cylinder, Size = V3(2.2, 1.8, 1.8), CFrame = cf * CFrame.new(hx - 1.4, 1.1, -hz - 1.4) * UPRIGHT, Material = MAT.WoodPlanks, Color = TIMBER, CanCollide = false })
		elseif r < 0.5 then
			L("Crate", V3(2, 2, 2), CFrame.new(-hx + 1.4, 1, -hz - 1.4) * CFrame.Angles(0, R(-0.4, 0.4), 0), MAT.WoodPlanks, TIMBER, false)
		end
	end

	-- the chapel, open to the sky: tall broken walls, windows, a door to the upper street, a tower at its corner; pews
	-- mostly fallen, the altar, the roof's timbers lying across it all, and a dead tree grown up through the nave
	do
		local cx, cz, w, d = -183, 788, 24, 34
		local cf = CFrame.new(cx, Y, cz)
		local TH, H = 1.6, 18
		local hx, hz = w / 2, d / 2
		local col = STONE:Lerp(STONE_LT, 0.3)
		flatten(cx - hx - 1, cz - hz - 1, cx + hx + 1, cz + hz + 1)
		local side = {}
		for z = -hz + 5, hz - 5, 6 do
			table.insert(side, { z - 1.2, z + 1.2, 5, 14 })
		end
		wallRun(cf, true, -hx, hx, -hz + TH / 2, 0, H + 6, TH, MAT.Limestone, col, { { -2.6, 2.6, -1, 11 }, { -1.8, 1.8, 13, 19 } }, 6, "ChapelWall")
		wallRun(cf, true, -hx, hx, hz - TH / 2, 0, H + 4, TH, MAT.Limestone, col, { { -2, 2, 6, 16 } }, 7, "ChapelWall")
		for _, sx in ipairs({ -1, 1 }) do
			wallRun(cf, false, -hz + TH, hz - TH, sx * (hx - TH / 2), 0, H, TH, MAT.Limestone, col, side, 9, "ChapelWall")
			for z = -hz + 8, hz - 8, 6 do -- buttresses between the windows
				P({ Name = "ChapelButtress", Size = V3(1.8, R(8, 13), 2), CFrame = cf * CFrame.new(sx * (hx + 0.9), 5, z), Material = MAT.Limestone, Color = mossy(col, cf * V3(sx * hx, 3, z), 0.1) })
			end
		end
		B(cx - hx + TH, Y, cz - hz + TH, cx + hx - TH, Y + 0.3, cz + hz - TH, MAT.Slate, C3(70, 68, 60), "ChapelFloor")
		B(cx - 3, Y + 0.3, cz + hz - 6, cx + 3, Y + 3.6, cz + hz - 3.5, MAT.Limestone, mossy(STONE_LT, cf.Position, 0.1), "Altar")
		for z = -hz + 6, hz - 9, 3 do
			for _, sx in ipairs({ -1, 1 }) do
				local r = rng:NextNumber()
				if r < 0.75 then
					local tilt = r < 0.4 and CFrame.Angles(R(1.2, 1.5), R(-0.3, 0.3), 0) or CFrame.Angles(0, R(-0.15, 0.15), 0)
					P({ Name = "Pew", Size = V3(7, 1.8, 1.2), CFrame = cf * CFrame.new(sx * 5, 0.9, z) * tilt, Material = MAT.WoodPlanks, Color = TIMBER:Lerp(C3(40, 36, 30), R(0, 0.6)), CanCollide = false })
				end
			end
		end
		for _ = 1, 4 do
			seg("FallenTimber", cf * V3(R(-hx + 2, hx - 2), R(0.5, 8), R(-hz + 3, hz - 3)), cf * V3(R(-hx + 2, hx - 2), 0.6, R(-hz + 3, hz - 3)), 1, MAT.Wood, TIMBER, false)
		end
		for _ = 1, 5 do
			rubble(cf * V3(R(-hx + 3, hx - 3), 0.3, R(-hz + 3, hz - 3)), 5, 2, col)
		end
		deadTree(cf * V3(2, 0.3, 2), 1.3)
		-- the tower, at its south-west corner: its belfry's openings black, its top broken off
		local tx1, tz1 = cx - hx - 2, cz - hz - 2
		B(tx1, Y, tz1, tx1 + 8, Y + 30, tz1 + 8, MAT.Limestone, mossy(col, V3(tx1, Y + 10, tz1), 0.05), "ChapelTower")
		for x = tx1, tx1 + 6, 2 do
			for z = tz1, tz1 + 6, 2 do
				if rng:NextNumber() < 0.55 then
					B(x, Y + 30, z, x + 2, Y + 30 + R(1, 6), z + 2, MAT.Limestone, mossy(col, V3(x, Y + 30, z), 0), "ChapelTower")
				end
			end
		end
		B(tx1 + 2.5, Y + 22, tz1 - 0.1, tx1 + 5.5, Y + 28, tz1, MAT.SmoothPlastic, C3(10, 12, 10), "Belfry")
		B(tx1 - 0.1, Y + 22, tz1 + 2.5, tx1, Y + 28, tz1 + 5.5, MAT.SmoothPlastic, C3(10, 12, 10), "Belfry")
		ivy(V3(tx1 + 4, Y + 29.5, tz1), V3(0, 0, -1), 20)
		ivy(V3(tx1, Y + 29.5, tz1 + 4), V3(-1, 0, 0), 16)
	end

	-- the houses, along both sides of every street, wherever one fits
	for _, s in ipairs(STREETS) do
		for _, sd in ipairs({ -1, 1 }) do
			local a = (s[5] and s[1] or s[2]) + R(0, 3)
			local stop = s[5] and s[3] or s[4]
			while a < stop - 6 do
				local w, d = R(9, 14), R(8, 12)
				local c = a + w / 2
				local cx, cz, yaw, fx, fz
				if s[5] then
					cx, cz, yaw, fx, fz = c, sd > 0 and s[4] + 1 + d / 2 or s[2] - 1 - d / 2, sd > 0 and 0 or math.pi, w, d
				else
					cx, cz, yaw, fx, fz = sd > 0 and s[3] + 1 + d / 2 or s[1] - 1 - d / 2, c, sd > 0 and math.pi / 2 or -math.pi / 2, d, w
				end
				if a + w <= stop and free(cx - fx / 2, cz - fz / 2, cx + fx / 2, cz + fz / 2) then
					house(cx, cz, w, d, yaw)
					table.insert(taken, { cx - fx / 2 - 0.5, cz - fz / 2 - 0.5, cx + fx / 2 + 0.5, cz + fz / 2 + 0.5 })
					a += w + R(0.5, 3)
				else
					a += 2
				end
			end
		end
	end
	-- and in the yards behind them: dead trees, rubble, a broken cart
	for x = TOWN[1] + 6, TOWN[3] - 6, 9 do
		for z = TOWN[2] + 6, TOWN[4] - 6, 9 do
			local p = V3(x + R(-3, 3), Y, z + R(-3, 3))
			if free(p.X - 3, p.Z - 3, p.X + 3, p.Z + 3) then
				local r = rng:NextNumber()
				if r < 0.3 then
					deadTree(p, R(0.7, 1.05))
				elseif r < 0.42 then
					rubble(p, 6, 2.5)
				elseif r < 0.47 then -- a cart, tipped on its side, a wheel off
					local yaw = CFrame.Angles(0, R(0, 6.3), 0)
					local cf = CFrame.new(p + V3(0, 1.6, 0)) * yaw * CFrame.Angles(0, 0, 1.2)
					P({ Name = "Cart", Size = V3(3.4, 0.4, 6), CFrame = cf, Material = MAT.WoodPlanks, Color = TIMBER, CanCollide = false })
					P({ Name = "CartWheel", Shape = Enum.PartType.Cylinder, Size = V3(0.4, 3.2, 3.2), CFrame = CFrame.new(p + V3(2.5, 0.2, 1)) * yaw * UPRIGHT, Material = MAT.Wood, Color = TIMBER, CanCollide = false })
				end
			end
		end
	end

	-- the town's gate, where the road comes in from the wood: two piers, the arch between them fallen
	do
		local col = mossy(STONE, V3(-35, Y, 660), 0.1)
		B(-37, Y - 1, 653, -33, Y + 15, 658, MAT.Limestone, col, "TownGate")
		B(-37, Y - 1, 672, -33, Y + 10.5, 677, MAT.Limestone, col, "TownGate")
		B(-37.4, Y + 15, 652.6, -32.6, Y + 16, 658.4, MAT.Limestone, STONE_LT, "TownGateCap")
		B(-36.5, Y + 13, 658, -33.5, Y + 15, 662.5, MAT.Limestone, col, "TownGateArch") -- (a stub of it, out over the road)
		P({ Name = "FallenArch", Size = V3(3, 2.4, 6), CFrame = CFrame.new(-30, Y + 1, 673) * CFrame.Angles(0.15, 0.9, 0.3), Material = MAT.Limestone, Color = col, CanCollide = false })
		rubble(V3(-31, Y, 671), 6, 2)
	end

	-- the square: a well, its winch's frame rotted, a toppled statue, a dead tree
	do
		local wx, wz = -146, 760
		for i = 0, 9 do
			local a = i / 10 * math.pi * 2
			P({ Name = "WellStone", Size = V3(1.9, 2.6, 1), CFrame = CFrame.lookAt(V3(wx + math.cos(a) * 2.6, Y + 1.3, wz + math.sin(a) * 2.6), V3(wx, Y + 1.3, wz)), Material = MAT.Cobblestone, Color = mossy(STONE, V3(wx, Y, wz), 0.2) })
		end
		P({ Name = "WellWater", Shape = Enum.PartType.Cylinder, Size = V3(0.2, 4.4, 4.4), CFrame = CFrame.new(wx, Y + 0.6, wz) * UPRIGHT, Material = MAT.SmoothPlastic, Color = C3(14, 18, 14), CanCollide = false })
		for _, sz in ipairs({ -1, 1 }) do
			P({ Name = "WellPost", Size = V3(0.5, 6, 0.5), CFrame = CFrame.new(wx, Y + 3, wz + sz * 3.2) * CFrame.Angles(R(-0.1, 0.1), 0, R(-0.1, 0.1)), Material = MAT.Wood, Color = TIMBER })
		end
		seg("WellBeam", V3(wx, Y + 5.8, wz - 3.3), V3(wx + 0.4, Y + 4.6, wz + 3.1), 0.5, MAT.Wood, TIMBER)
		local col = mossy(STONE_LT, V3(-160, Y, 750), 0.15)
		B(-163, Y, 747, -157, Y + 4, 753, MAT.Limestone, mossy(STONE_DK, V3(-160, Y, 750), 0.1), "StatuePlinth")
		B(-162, Y + 4, 748.5, -160.4, Y + 6.5, 750.3, MAT.Limestone, col, "StatueStump")
		B(-159.6, Y + 4, 748.5, -158, Y + 5.2, 750.3, MAT.Limestone, col, "StatueStump")
		P({ Name = "FallenStatue", Size = V3(3.6, 2.6, 7), CFrame = CFrame.new(-158, Y + 1.3, 758) * CFrame.Angles(0, 0.4, 0.1), Material = MAT.Limestone, Color = col, CanCollide = false })
		P({ Name = "FallenStatueHead", Shape = Enum.PartType.Ball, Size = Vector3.one * 2, CFrame = CFrame.new(-153.5, Y + 1, 763), Material = MAT.Limestone, Color = col, CanCollide = false })
		deadTree(V3(-133, Y, 772), 1.35)
		wisp(V3(-146, Y + 2.5, 760))
	end

	-- THE GRAND STAIR: two flights east up out of the square, a landing between, broken balustrades, to the bastion
	-- the drawbridge fell onto
	do
		local Z1, Z2 = 753, 767
		local function flight(x1, x2, y1, y2, n)
			local t, r = (x2 - x1) / n, (y2 - y1) / n
			for i = 1, n do
				local top, a, b = y1 + i * r, x1 + (i - 1) * t, x1 + i * t
				B(a, Y - 1, Z1 - 0.8, b, top, Z2 + 0.8, MAT.Limestone, mossy(STONE, V3(b, top, 760), 0.05), "Stair")
				for _, z in ipairs({ Z1 - 0.8, Z2 }) do
					local q = rng:NextNumber()
					if q < 0.78 then
						B(a, top, z, b, top + (q < 0.12 and R(0.6, 1.6) or 2.6), z + 0.8, MAT.Limestone, mossy(STONE_LT, V3(a, top, z), 0.1), "Balustrade")
					elseif q < 0.86 then
						rubble(V3(a, top, z + (z < 760 and -2 or 2.8)), 1, 0.4)
					end
				end
			end
		end
		flight(-125, -96.5, Y, Y + 17, 20)
		B(-96.5, Y - 1, Z1 - 0.8, -88.5, Y + 17, Z2 + 0.8, MAT.Limestone, mossy(STONE, V3(-92, Y + 17, 760), 0.05), "StairLanding")
		flight(-88.5, -62, Y + 17, PF, 20)
		-- the bastion: a block of masonry up out of the town to the palace's floor, a parapet along its sides
		local col = mossy(STONE:Lerp(STONE_DK, 0.3), V3(-55, Y + 20, 760), 0.1)
		B(-62, Y - 1, 748, -47, PF, 772, MAT.Limestone, col, "Bastion")
		B(-62.6, PF - 1.4, 747.4, -47, PF - 0.4, 772.6, MAT.Limestone, STONE_LT, "BastionCourse")
		for _, z in ipairs({ 748, 771 }) do
			for x = -62, -48, 2 do
				if rng:NextNumber() < 0.75 then
					B(x, PF, z, x + 2, PF + R(1.8, 3), z + 1, MAT.Limestone, mossy(STONE_LT, V3(x, PF, z), 0.1), "Parapet")
				end
			end
		end
		for _, z in ipairs({ 745.5, 774.5 }) do -- buttresses up its south and north faces
			for _, x in ipairs({ -60, -50 }) do
				B(x - 1.2, Y - 1, z - 2.5, x + 1.2, PF - 8, z + 2.5, MAT.Limestone, col, "BastionButtress")
			end
		end
		for _ = 1, 4 do
			ivy(V3(R(-61, -48), PF - 0.5, 748), V3(0, 0, -1), R(10, 30))
			ivy(V3(R(-61, -48), PF - 0.5, 772), V3(0, 0, 1), R(10, 30))
		end
		rubble(V3(-55, PF, 760), 5, 3)
	end
	for _, m in ipairs({ { -80, 661 }, { -150, 700 }, { -150, 800 }, { -180, 661 }, { -110, 760 }, { -70, 790 } }) do
		mist(V3(m[1], Y + 2, m[2]), V3(30, 2, 30))
	end
	wisp(V3(-120, Y + 3, 700))
	wisp(V3(-180, Y + 3, 815))

	---------------------------------------------------------------------------
	-- THE DECAYED PALACE: Pyralis's, every part of it (as built, before anything's moved), cloned and moved here, then let
	-- go to ruin - its fires out, lava gone to black slime, gold and iron to verdigris, black stone bleached pale and mossed,
	-- its glass black holes, its cloth rotted away, its merlons and finials fallen, its roofs broken open over rubble, ivy
	-- down its walls, its statues broken off at the knee. Its drawbridge lies down, onto the bastion.
	---------------------------------------------------------------------------
	if info.PalaceParts then
		local pal = Instance.new("Folder")
		pal.Name = "Palace"
		pal.Parent = folder
		for _, c in ipairs(info.PalaceParts) do
			if c.Parent and c.Archivable and c.Name ~= "ThroneLift" then -- (no throne here: its shaft is THE PIT, below)
				c:Clone().Parent = pal
			end
		end
		-- the terrain out of its sunken court, the passage off it and the court's cellars (all inside its pedestal's rock)
		T:FillBlock(CFrame.new(50, -2, 740), V3(132, 60, 104), MAT.Air) -- (whole voxels: x -16..116, y -32..28, z 688..792)
		local hinge = CFrame.lookAt(V3(416, 100, 240), V3(415, 100, 240))
		local LOWER = hinge * CFrame.Angles(-math.pi / 2, 0, 0) * hinge:Inverse() -- (Pyralis's is raised against its gate)
		local BRIDGE = { Drawbridge = true, DrawbridgeEdge = true, DrawbridgeBand = true, DrawbridgeShoe = true, ChainEye = true }
		local GONE = { DrawChain = true, Chest = true, ChestBand = true, ChestLock = true, ChestSun = true, ChestLid = true, Fx = true }
		local FALLS = { Merlon = 0.3, Finial = 0.55, Spirelet = 0.25, LanternGlass = 1, LanternBar = 0.5, LanternCap = 0.5, Book = 0.5, Bottle = 0.6, SunRay = 0.35, PewBack = 0.3, Portcullis = 0.25, PortcullisTooth = 0.4, DrawbridgeBand = 0.4 }
		local IVY = { PalaceWall = true, CurtainWall = true, GateWall = true, Buttress = true, PalaceTower = true, PalaceTowerFoot = true, PalaceRock = true }
		local STRIP = { "Light", "Fire", "Smoke", "ParticleEmitter", "Sparkles", "ProximityPrompt", "Constraint", "WeldConstraint", "JointInstance", "BaseScript", "Beam", "Trail", "ClickDetector" }
		local roofs, floors, walls, plinths = {}, {}, {}, {}
		local function recolor(d) -- (true: it's gone)
			local m, col, p = d.Material, d.Color, d.Position
			local lum = col.R * 0.3 + col.G * 0.59 + col.B * 0.11
			if m == MAT.Neon then
				d.Material, d.Color, d.Reflectance = MAT.SmoothPlastic, C3(22, 28, 24):Lerp(MOSS_DK, R(0, 0.3)), 0.2
			elseif m == MAT.Glass then
				if rng:NextNumber() < 0.6 then
					d.Material, d.Color = MAT.SmoothPlastic, C3(10, 12, 10) -- (broken out: black)
				else
					d.Color, d.Transparency = C3(52, 60, 50), 0.3
				end
			elseif m == MAT.Metal or m == MAT.CorrodedMetal or m == MAT.DiamondPlate then
				d.Material, d.Color = MAT.CorrodedMetal, VERDI:Lerp(C3(62, 56, 46), R(0, 0.7))
			elseif m == MAT.Fabric then
				if rng:NextNumber() < 0.35 then
					d:Destroy()
					return true
				end
				d.Color = CLOTH:Lerp(MOSS_DK, R(0, 0.5)):Lerp(C3(30, 28, 24), R(0, 0.3))
			elseif m == MAT.Wood or m == MAT.WoodPlanks then
				d.Color = C3(84, 78, 66):Lerp(C3(40, 38, 32), R(0, 0.7)):Lerp(MOSS_DK, R(0, 0.3))
			elseif m == MAT.Marble then
				d.Color = mossy(C3(178, 170, 142):Lerp(C3(120, 114, 96), math.clamp(1 - lum * 2, 0, 1)), p, 0.05)
			elseif m == MAT.CrackedLava then
				d.Material, d.Color = MAT.Mud, C3(40, 40, 32)
			elseif m ~= MAT.SmoothPlastic then -- stone (the dark of doorways and niches, smooth, is left)
				if m == MAT.Basalt then
					d.Material = MAT.Limestone
				end
				local t = math.clamp((lum - 0.1) / 0.28, 0, 1)
				d.Color = mossy(STONE_DK:Lerp(STONE_LT, t), p, math.clamp(1 - (p.Y - Y) / 80, 0, 1) * 0.2)
			end
			return false
		end
		for _, d in ipairs(pal:GetDescendants()) do
			if d.Parent == nil then
				continue
			end
			if d:IsA("BasePart") then
				local n = d.Name
				local o = d.Position -- (still where it stands in Pyralis)
				local nearShaft = o.X > 490 and o.X < 520 and o.Z > 225 and o.Z < 255
				local landing = o.Y < 30 and o.X > 495 and o.X < 522 and o.Z > 222 and o.Z < 258 and (n == "LandingStep" or n == "StepNosing" or n == "LandingPit") -- (the steps round where the lift came down: gone with it)
				if not d.Anchored or d:IsA("TrussPart") or GONE[n] or (FALLS[n] and rng:NextNumber() < FALLS[n]) or (nearShaft and (n == "LeverPost" or n == "LeverHandle" or n == "Dais" or (n == "Carpet" and o.X > 497))) or landing then -- (no dais: the pit's eaten it)
					d:Destroy()
					continue
				end
				-- the Sunken Court, under it all, is only half gone: the rot fell down the pit, so it's thickest under it
				-- (its east end) and thins out west, in patches; what it hasn't reached keeps its marble (its fires still out)
				local pristine = false
				if o.X > 421 and o.X < 543 and o.Z > 171 and o.Z < 269 and o.Y > 5 and o.Y < 69 then
					local rot = 1.3 - (V3(o.X, 0, o.Z) - V3(508.5, 0, 240)).Magnitude / 90 + math.noise(o.X / 14, o.Y / 14, o.Z / 14) * 0.7
					pristine = rng:NextNumber() > rot and d.Material ~= MAT.Neon
				end
				if BRIDGE[n] then
					d.CFrame = LOWER * d.CFrame
				end
				d.CFrame += SHIFT
				if d.Transparency < 1 and not pristine and not recolor(d) then
					local up = math.abs(d.CFrame.UpVector.Y) > 0.99
					local block = d:IsA("Part") and d.Shape == Enum.PartType.Block
					if n == "Roof" and block and math.max(d.Size.X, d.Size.Z) > 10 then
						table.insert(roofs, d)
					elseif block and up and (string.find(n, "Floor") or n == "Paving" or n == "Landing" or n == "Causeway") then
						table.insert(floors, d)
					elseif IVY[n] then
						table.insert(walls, d)
					elseif n == "PlinthCap" or n == "ColossusPlinth" then
						table.insert(plinths, d)
					end
				end
			else
				for _, cls in ipairs(STRIP) do
					if d:IsA(cls) then
						d:Destroy()
						break
					end
				end
			end
		end
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Include
		rp.FilterDescendantsInstances = { pal }
		-- the roofs broken open: each cut into strips, the strips cut into runs, the runs where the noise says gone left out,
		-- rubble on whatever's under the holes
		for _, d in ipairs(roofs) do
			local s, cf = d.Size, d.CFrame
			local nx, nz = math.max(1, math.round(s.X / 4)), math.max(1, math.round(s.Z / 4))
			local cx, cz = s.X / nx, s.Z / nz
			local salt = R(0, 100)
			local open, any = {}, false
			for i = 0, nx - 1 do
				open[i] = {}
				for j = 0, nz - 1 do
					local w = cf * V3(-s.X / 2 + (i + 0.5) * cx, 0, -s.Z / 2 + (j + 0.5) * cz)
					open[i][j] = math.noise(w.X / 9, w.Z / 9, salt) > 0.2
					any = any or open[i][j]
				end
			end
			if any and rng:NextNumber() < 0.7 then
				local holes = {}
				for i = 0, nx - 1 do
					local run0
					for j = 0, nz do
						local gone = j == nz or open[i][j]
						if not gone and not run0 then
							run0 = j
						elseif gone and run0 then
							local q = d:Clone()
							q.Size = V3(cx, s.Y, (j - run0) * cz)
							q.CFrame = cf * CFrame.new(-s.X / 2 + (i + 0.5) * cx, 0, -s.Z / 2 + (run0 + j) / 2 * cz)
							q.Parent = d.Parent
							run0 = nil
						end
						if j < nz and open[i][j] then
							table.insert(holes, cf * V3(-s.X / 2 + (i + 0.5) * cx, 0, -s.Z / 2 + (j + 0.5) * cz))
						end
					end
				end
				d:Destroy()
				for i, h in ipairs(holes) do
					if i % 2 == 1 then
						local hit = workspace:Raycast(h - V3(0, 1, 0), V3(0, -120, 0), rp)
						if hit then
							rubble(hit.Position, 2, 1.5, STONE, pal)
						end
					end
				end
			end
		end
		-- moss over its floors, black puddles, a little rubble
		for _, d in ipairs(floors) do
			local s = d.Size
			local top = d.Position.Y + s.Y / 2
			for _ = 1, math.min(5, math.floor(s.X * s.Z / 160)) do
				local r = R(1.5, 4)
				if s.X > 2 * r + 1 and s.Z > 2 * r + 1 then
					local w = d.CFrame * V3(R(-s.X / 2 + r, s.X / 2 - r), 0, R(-s.Z / 2 + r, s.Z / 2 - r))
					local wet = rng:NextNumber() < 0.25
					P({ Name = wet and "Puddle" or "MossPatch", Shape = Enum.PartType.Cylinder, Size = V3(0.08, r * 2, r * 2), CFrame = CFrame.new(w.X, top + 0.04, w.Z) * UPRIGHT, Material = wet and MAT.Glass or MAT.Grass, Color = wet and WATER or MOSS:Lerp(MOSS_DK, R(0, 1)), Transparency = wet and 0.15 or 0, Reflectance = wet and 0.2 or 0, CanCollide = false, CastShadow = false, Parent = pal })
				end
			end
			if s.X * s.Z > 300 and rng:NextNumber() < 0.5 then
				rubble(d.CFrame * V3(R(-s.X / 3, s.X / 3), s.Y / 2, R(-s.Z / 3, s.Z / 3)), 4, 2, STONE, pal)
			end
		end
		-- ivy down its walls, its towers and its crag, wherever a face is open to the air
		for _, d in ipairs(walls) do
			if rng:NextNumber() < 0.45 then
				local s, cf = d.Size, d.CFrame
				local cylinder = d:IsA("Part") and d.Shape == Enum.PartType.Cylinder
				local upright = cylinder and math.abs(cf.RightVector.Y) > 0.99 or (not cylinder and math.abs(cf.UpVector.Y) > 0.99)
				local h = cylinder and s.X or s.Y
				if upright and h > 8 then
					local top = d.Position.Y + h / 2 - 0.3
					for _ = 1, rng:NextInteger(1, 2) do
						local pt, out
						if cylinder then
							local a = R(0, 6.28)
							out = V3(math.cos(a), 0, math.sin(a))
							pt = V3(d.Position.X, top, d.Position.Z) + out * (s.Y / 2)
						else
							local faces = { { cf.RightVector, s.X / 2, cf.LookVector, s.Z }, { -cf.RightVector, s.X / 2, cf.LookVector, s.Z }, { cf.LookVector, s.Z / 2, cf.RightVector, s.X }, { -cf.LookVector, s.Z / 2, cf.RightVector, s.X } }
							local f = faces[rng:NextInteger(1, 4)]
							if f[4] > 3 then
								out = f[1]
								pt = V3(d.Position.X, top, d.Position.Z) + out * f[2] + f[3] * R(-f[4] / 2 + 1, f[4] / 2 - 1)
							end
						end
						if pt and not workspace:Raycast(pt + out * 0.05, out * 3, rp) then
							ivy(pt, out, R(5, math.min(28, h * 0.8)))
						end
					end
				end
			end
		end
		-- the statues: Pyralis's king stands on these; here, only his legs to the knee, the rest of him fallen in front
		for _, c in ipairs(plinths) do
			local cf, col = c.CFrame, mossy(STONE_LT, c.Position, 0.1)
			if c.Name == "PlinthCap" then
				local kk = c.Size.X / 7.8
				for _, sx in ipairs({ -1, 1 }) do
					local hh = R(1.5, 4.5) * kk
					P({ Name = "StatueStump", Size = V3(1.7 * kk, hh, 2 * kk), CFrame = cf * CFrame.new(sx * 1.2 * kk, c.Size.Y / 2 + hh / 2, 0), Material = MAT.Limestone, Color = col, CanCollide = false, Parent = pal })
				end
				P({ Name = "FallenStatue", Size = V3(4.2 * kk, 3 * kk, 7 * kk), CFrame = cf * CFrame.new(R(-1, 1) * kk, -2.9 * kk, -7 * kk) * CFrame.Angles(0, R(-0.6, 0.6), R(-0.2, 0.2)), Material = MAT.Limestone, Color = col, CanCollide = false, Parent = pal })
				P({ Name = "FallenStatueHead", Shape = Enum.PartType.Ball, Size = Vector3.one * 2.2 * kk, CFrame = cf * CFrame.new(R(-3, 3) * kk, -3.3 * kk, -11 * kk), Material = MAT.Limestone, Color = col, CanCollide = false, Parent = pal })
			else -- the colossus, enthroned at the court's west end: its feet, and its head down on the court's floor
				local top = c.Position.Y + c.Size.Y / 2 + 0.6
				for _, sz in ipairs({ -4, 4 }) do
					local hh = R(8, 16)
					P({ Name = "ColossusStump", Size = V3(6, hh, 6.5), CFrame = CFrame.new(c.Position.X, top + hh / 2, c.Position.Z + sz), Material = MAT.Marble, Color = col, Parent = pal })
				end
				P({ Name = "ColossusHead", Shape = Enum.PartType.Ball, Size = Vector3.one * 10, CFrame = CFrame.new(c.Position.X + 22, c.Position.Y - c.Size.Y / 2 + 4.6, c.Position.Z + 9), Material = MAT.Marble, Color = col, Parent = pal })
				P({ Name = "ColossusArm", Size = V3(5, 5, 18), CFrame = CFrame.new(c.Position.X + 16, c.Position.Y - c.Size.Y / 2 + 2.4, c.Position.Z - 10) * CFrame.Angles(0, 0.7, 0.1), Material = MAT.Marble, Color = col, Parent = pal })
			end
		end
		for _, m in ipairs({ { 10, PF, 760 }, { 30, PF, 740 } }) do
			mist(V3(m[1], m[2] + 2, m[3]), V3(24, 2, 30))
		end

		-- THE PIT: where Pyralis's throne sinks to its court. Here there's no throne, and its shaft (x 67..78, z 750..770)
		-- is a hole into the dark - its lips crumbling in, roots and ivy hanging down it, black veils across it and murk
		-- welling up out of it, so you never see the bottom. 88 down: the Sunken Court, half rotted - Ossaria's
		-- (init.server: the first fall is a cutscene, and her bar shows while you're in her court)
		do
			local X1, Z1, X2, Z2 = 67, 750, 78, 770 -- (Pyralis's 503..514, 230..250, moved here)
			local CF_, CV = 12 - 40, 68 - 40 -- (the court's floor and vault, here)
			local cx, cz = (X1 + X2) / 2, (Z1 + Z2) / 2
			for y = PF - 2.5, CV + 3, -4 do -- (each lets a third through: a few and nothing shows)
				P({ Name = "PitDark", Size = V3(X2 - X1, 0.2, Z2 - Z1), CFrame = CFrame.new(cx, y, cz), Material = MAT.SmoothPlastic, Color = C3(6, 8, 6), Transparency = 0.35, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Parent = pal })
			end
			local murk = P({ Name = "PitMurk", Size = V3(X2 - X1 - 1, 1, Z2 - Z1 - 1), CFrame = CFrame.new(cx, PF - 5, cz), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = pal })
			local e = Instance.new("ParticleEmitter")
			e.Texture = "rbxasset://textures/particles/smoke_main.dds"
			e.Color = ColorSequence.new(C3(22, 26, 20), C3(8, 10, 8))
			e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(1, 9) })
			e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.5), NumberSequenceKeypoint.new(1, 1) })
			e.Lifetime, e.Speed, e.RotSpeed = NumberRange.new(3, 5), NumberRange.new(1, 2.5), NumberRange.new(-12, 12)
			e.Rate, e.LightInfluence = 8, 0
			e.Shape, e.EmissionDirection = Enum.ParticleEmitterShape.Box, Enum.NormalId.Top
			e.Parent = murk
			-- the darkness pouring out of it: black orbs of it heaped round the mouth and welling up over it, thinner the
			-- higher, each swelling, fading and rising slowly on its own beat; and a dark aura boiling up off them into the air
			local TS = game:GetService("TweenService")
			for _ = 1, 34 do
				local a = R(0, 6.3)
				local up = R(0, 1) ^ 1.6 -- (most low, a few high)
				local rr = R(3.2, 6.8) * (1 - up * 0.5)
				local q = V3(cx + math.cos(a) * rr, PF - 0.5 + up * 9, cz + math.sin(a) * rr)
				local s = R(2.5, 6.5) * (1 - up * 0.55)
				local tr = 1 - (1 - (0.35 + up * 0.45 + R(0, 0.15))) * 0.8 -- (thinned a fifth)
				local b = P({ Name = "PitGloom", Shape = Enum.PartType.Ball, Size = Vector3.one * s, CFrame = CFrame.new(q), Material = MAT.SmoothPlastic, Color = C3(4, 4, 6):Lerp(C3(24, 12, 30), R(0, 0.5)), Transparency = tr, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Parent = pal })
				TS:Create(b, TweenInfo.new(R(3, 7), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, R(0, 3)), { Size = Vector3.one * s * R(1.15, 1.45), Transparency = math.min(0.95, tr + R(0.1, 0.25)), CFrame = CFrame.new(q + V3(0, R(0.5, 1.5), 0)) }):Play()
			end
			local aura = P({ Name = "PitAura", Size = V3(12, 1, 12), CFrame = CFrame.new(cx, PF + 0.5, cz), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = pal })
			local ae = Instance.new("ParticleEmitter")
			ae.Texture = "rbxasset://textures/particles/smoke_main.dds"
			ae.Color = ColorSequence.new(C3(10, 8, 14), C3(30, 18, 40))
			ae.LightEmission, ae.LightInfluence = 0, 0
			ae.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.5), NumberSequenceKeypoint.new(0.5, 5), NumberSequenceKeypoint.new(1, 8) })
			ae.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.48), NumberSequenceKeypoint.new(0.6, 0.68), NumberSequenceKeypoint.new(1, 1) })
			ae.Lifetime, ae.Speed = NumberRange.new(2.5, 4.5), NumberRange.new(1.5, 3.5)
			ae.Rotation, ae.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-40, 40)
			ae.Acceleration, ae.Drag = V3(0, 1.2, 0), 0.6
			ae.SpreadAngle = Vector2.new(20, 20)
			ae.EmissionDirection = Enum.NormalId.Top
			ae.Rate = 26
			ae.Shape, ae.ShapeStyle = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume
			ae.Parent = aura
			-- its mouth: not the shaft's square edge but a ragged hole eaten into the floor - slabs round it sagging and
			-- tipping in toward it (some gone), more heaved up on the floor about it
			local salt = R(0, 100)
			for x = X1 + 0.5, X2 - 0.5 do
				for z = Z1 + 0.5, Z2 - 0.5 do
					local dx, dz = (x - cx) / 4.4, (z - cz) / 4.6 -- (round: the shaft's long ends slabbed over)
					local th = math.atan2(dz, dx)
					local edge = 1 + 0.3 * math.noise(math.cos(th) * 1.6, math.sin(th) * 1.6, salt)
					local r = math.sqrt(dx * dx + dz * dz)
					if r > edge and rng:NextNumber() < 0.9 then
						local near = math.clamp(1 - (r - edge) / 0.45, 0, 1) -- (1: right at the hole's edge)
						local axis = V3(x - cx, 0, z - cz).Unit:Cross(V3(0, 1, 0))
						local t = R(0.8, 1.4)
						local top = PF - near * R(0.4, 1.6) - R(0, 0.25)
						P({ Name = "PitShard", Size = V3(R(1.1, 1.7), t, R(1.1, 1.7)), CFrame = CFrame.new(x, top - t / 2, z) * CFrame.fromAxisAngle(axis, near * R(0.15, 0.5)) * CFrame.Angles(0, R(-0.6, 0.6), 0), Material = MAT.Limestone, Color = mossy(STONE_DK:Lerp(ROT, near * 0.6), V3(x, PF, z), 0.15), CanCollide = near < 0.5, Parent = pal })
					end
				end
			end
			for _ = 1, 12 do
				local a = R(0, 6.3)
				local d = R(7, 10)
				local q = V3(cx + math.cos(a) * d, PF + 0.2, cz + math.sin(a) * d)
				P({ Name = "PitShard", Size = V3(R(1.2, 2.4), 0.7, R(1.2, 2.4)), CFrame = CFrame.new(q) * CFrame.Angles(R(-0.35, 0.35), R(0, 6.3), R(-0.35, 0.35)), Material = MAT.Limestone, Color = mossy(STONE_DK, q, 0.2), CanCollide = false, Parent = pal })
			end
			rubble(V3(cx, PF, Z1 - 3), 6, 3, STONE, pal)
			rubble(V3(cx, PF, Z2 + 3), 6, 3, STONE, pal)
			local faces = { { V3(X1, 0, 0), V3(1, 0, 0) }, { V3(X2, 0, 0), V3(-1, 0, 0) }, { V3(0, 0, Z1), V3(0, 0, 1) }, { V3(0, 0, Z2), V3(0, 0, -1) } }
			for _ = 1, 9 do -- ivy down its walls into the dark
				local f = faces[rng:NextInteger(1, 4)]
				local top = f[2].X ~= 0 and V3(f[1].X, PF - 1.3, R(Z1 + 1, Z2 - 1)) or V3(R(X1 + 1, X2 - 1), PF - 1.3, f[1].Z)
				ivy(top, f[2], R(8, 18))
			end
			for _ = 1, 6 do -- roots, dangling
				local p = V3(R(X1 + 0.5, X2 - 0.5), PF - 0.6, rng:NextNumber() < 0.5 and Z1 + 0.4 or Z2 - 0.4)
				for _ = 1, 3 do
					local q = p + V3(R(-1.2, 1.2), -R(2.5, 5), R(-0.6, 0.6))
					seg("PitRoot", p, q, R(0.25, 0.6), MAT.Wood, BARK:Lerp(C3(30, 26, 22), R(0, 0.6)))
					p = q
				end
			end
			-- at its foot, the court: the vault round the hole fallen in about the landing, a few pale lights in the dark
			for _ = 1, 6 do
				local a, s = R(0, 6.3), R(2.5, 5)
				local at = V3(cx + math.cos(a) * R(13, 22), CF_ + s * 0.25, cz + math.sin(a) * R(13, 22)) -- (never in the landing)
				P({ Name = "FallenVault", Size = V3(s * R(1, 1.8), s * R(0.4, 0.7), s), CFrame = CFrame.new(at) * CFrame.Angles(R(-0.4, 0.4), R(0, 6.3), R(-0.4, 0.4)), Material = MAT.Slate, Color = mossy(STONE_DK, at, 0.25), Parent = pal })
				rubble(at, 3, 3, STONE, pal)
			end
			rubble(V3(cx, CF_ + 0.2, cz), 5, 4, STONE, pal)
			for _, w in ipairs({ { 64, 757 }, { 40, 720 }, { 40, 760 }, { 10, 740 }, { 92, 740 }, { 60, 702 }, { 60, 778 } }) do
				wisp(V3(w[1], CF_ + R(4, 9), w[2]))
			end
			local glow = P({ Name = "PitGlow", Size = Vector3.one * 0.2, CFrame = CFrame.new(cx, CF_ + 14, cz), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = pal })
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness = C3(150, 190, 150), 30, 0.6
			l.Parent = glow

			-- THE COURT, harder hit (the further from the pit, the less): its floor broken up, its piers bitten into and two
			-- of them down, its walls' cladding fallen away in places
			local function rotAt(p)
				return math.clamp(1.3 - (V3(p.X, 0, p.Z) - V3(cx, 0, cz)).Magnitude / 90 + math.noise(p.X / 14, 3.3, p.Z / 14) * 0.7, 0, 1)
			end
			local tiles, stains, piers, ribs = {}, {}, {}, {}
			for _, d in ipairs(pal:GetDescendants()) do
				local p = d:IsA("BasePart") and d.Position
				if p and p.X > -14 and p.X < 106 and p.Z > 692 and p.Z < 788 and p.Y > CF_ - 2 and p.Y < CV then
					local n = d.Name
					if n == "CourtFloor" then
						table.insert(tiles, d)
					elseif n == "Puddle" or n == "MossPatch" then
						table.insert(stains, d)
					elseif n == "Rib" then
						table.insert(ribs, d)
					elseif n == "PierCore" or n == "PierShaft" or n == "PierBase" or n == "PierCapital" then
						local key = (math.round((p.X + 2) / 12) * 12 - 2) .. "," .. (p.Z < 740 and 700 or 780) -- (its pier: x -2..94 by 12, z 700 or 780)
						piers[key] = piers[key] or {}
						table.insert(piers[key], d)
					end
				end
			end
			-- the floor: tiles cracked into quarters, heaved and sunk, some gone to mud
			for _, d in ipairs(tiles) do
				local p = d.Position
				if rng:NextNumber() < rotAt(p) * 0.55 then
					for _, st in ipairs(stains) do
						if st.Parent and math.abs(st.Position.X - p.X) < 4.5 and math.abs(st.Position.Z - p.Z) < 4.5 then
							st:Destroy()
						end
					end
					local col = d.Color
					d:Destroy()
					for _, o in ipairs({ { -2, -2 }, { -2, 2 }, { 2, -2 }, { 2, 2 } }) do
						local q = p + V3(o[1], 0, o[2])
						if rng:NextNumber() < 0.2 then
							P({ Name = "FloorGone", Size = V3(4, 0.2, 4), CFrame = CFrame.new(q - V3(0, 0.25, 0)), Material = MAT.Mud, Color = C3(30, 30, 26):Lerp(ROT, 0.5), Parent = pal })
						else
							P({ Name = "CourtFloor", Size = V3(R(3.6, 4), 0.9, R(3.6, 4)), CFrame = CFrame.new(q + V3(0, -0.35 + R(-0.45, 0.3), 0)) * CFrame.Angles(R(-0.09, 0.09), R(-0.08, 0.08), R(-0.09, 0.09)), Material = MAT.Marble, Color = mossy(col, q, 0.1), Parent = pal })
						end
					end
				end
			end
			-- a thin dark streak laid on a face (nrm: its normal), a to b
			local function streak(a, b, nrm, w, col)
				local d = b - a
				if d.Magnitude > 0.05 then
					P({ Name = "RotVein", Size = V3(w, 0.06, d.Magnitude + w * 0.5), CFrame = CFrame.lookAt((a + b) / 2 + nrm * 0.04, b + nrm * 0.04, nrm), Material = MAT.SmoothPlastic, Color = col, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Parent = pal })
				end
			end
			local CRACK = C3(16, 14, 12)
			-- the piers: two down across the floor in drums, their arches gone with them; the rest bitten into - their shafts
			-- broken through or snapped off, their cores cracked, rubble at their feet
			local COLLAPSE = { ["70,700"] = 1, ["22,780"] = -1 } -- (each falls in toward the court's middle, clear of hers)
			for key, parts in pairs(piers) do
				local px, pz = string.match(key, "(-?%d+),(%d+)")
				px, pz = tonumber(px), tonumber(pz)
				local col = parts[1].Color
				local base = V3(px, CF_ + 0.2, pz)
				if COLLAPSE[key] then
					for _, d in ipairs(parts) do
						d:Destroy()
					end
					for _, r in ipairs(ribs) do -- (its arcade both sides, and the great arch it carried across the vault)
						local q = r.Position
						if r.Parent and ((math.abs(q.X - px) < 12.5 and math.abs(q.Z - pz) < 2.5) or (math.abs(q.X - px) < 1.6 and q.Y > CF_ + 37)) then
							r:Destroy()
						end
					end
					local h = R(3, 6)
					P({ Name = "PierStump", Size = V3(3, h, 3), CFrame = CFrame.new(base + V3(0, h / 2, 0)), Material = MAT.Slate, Color = col, Parent = pal })
					for _, c in ipairs({ { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }) do
						local sh = R(1.5, 7)
						P({ Name = "PierStump", Shape = Enum.PartType.Cylinder, Size = V3(sh, 1.26, 1.26), CFrame = CFrame.new(base + V3(c[1] * 1.5, sh / 2, c[2] * 1.5)) * UPRIGHT, Material = MAT.Slate, Color = col, Parent = pal })
					end
					local f = V3(R(-0.35, 0.35), 0, COLLAPSE[key]).Unit
					local at = base + f * 3
					for _ = 1, 4 do
						local len = R(5, 8)
						local c = at + f * (len / 2) + V3(0, 1.8, 0)
						P({ Name = "FallenDrum", Shape = Enum.PartType.Cylinder, Size = V3(len, 3.6, 3.6), CFrame = CFrame.lookAt(c, c + f) * CFrame.Angles(0, math.pi / 2, 0), Material = MAT.Slate, Color = mossy(col, c, 0.15), Parent = pal })
						at += f * (len + R(0.3, 1.4))
						f = CFrame.Angles(0, R(-0.3, 0.3), 0) * f
					end
					P({ Name = "FallenCapital", Size = V3(4.6, 0.9, 4.6), CFrame = CFrame.new(at + V3(0, 0.8, 0)) * CFrame.Angles(R(-0.3, 0.3), R(0, 6.3), R(-0.3, 0.3)), Material = MAT.Slate, Color = col, Parent = pal })
					rubble(base, 8, 4, STONE, pal)
					rubble(at, 6, 3, STONE, pal)
				else
					local rot = rotAt(base)
					for _, d in ipairs(parts) do
						if d.Name == "PierShaft" and rng:NextNumber() < 0.25 + rot * 0.55 then
							local h, cf = d.Size.X, d.CFrame -- (a cylinder: its length along its own x)
							local g, gl = R(-h / 2 + 5, h / 2 - 6), R(1.6, 4.5)
							local snapped = rng:NextNumber() < 0.3 -- (all above the break gone, lying at its foot)
							for i, sp in ipairs({ { -h / 2, g - gl / 2 }, { g + gl / 2, h / 2 } }) do
								if i == 1 or not snapped then
									local q = d:Clone()
									q.Size = V3(sp[2] - sp[1], d.Size.Y, d.Size.Z)
									q.CFrame = cf * CFrame.new((sp[1] + sp[2]) / 2, 0, 0)
									q.Parent = pal
								end
							end
							if snapped then
								local a = R(0, 6.3)
								local c = base + V3(math.cos(a) * 3.5, 0.65, math.sin(a) * 3.5)
								P({ Name = "FallenDrum", Shape = Enum.PartType.Cylinder, Size = V3(R(3, 6), 1.26, 1.26), CFrame = CFrame.new(c) * CFrame.Angles(0, a + math.pi / 2, 0), Material = MAT.Slate, Color = d.Color, Parent = pal })
							end
							d:Destroy()
						elseif d.Name == "PierCore" and rng:NextNumber() < 0.3 + rot * 0.6 then
							for _ = 1, 2 do -- cracks down its faces, zigzag
								local yaw = rng:NextInteger(0, 3) * math.pi / 2
								local face = CFrame.new(d.Position) * CFrame.Angles(0, yaw, 0)
								local nrm = face.LookVector -- (the face at its local -z: out along its look)
								local p = (face * CFrame.new(R(-0.6, 0.6), R(-8, 14), -d.Size.Z / 2 - 0.02)).Position
								for _ = 1, rng:NextInteger(3, 6) do
									local q = p + face.RightVector * R(-0.7, 0.7) - V3(0, R(1.2, 2.6), 0)
									streak(p, q, nrm, R(0.12, 0.22), CRACK)
									p = q
								end
							end
						end
					end
					if rng:NextNumber() < 0.3 + rot * 0.5 then
						rubble(base, 4, 2.5, STONE, pal)
					end
				end
			end
			-- the veins of rot: dark branching streaks laid over whatever they cross (floor, rubble, wall), forking as they go
			local vq = RaycastParams.new()
			vq.FilterType = Enum.RaycastFilterType.Include
			vq.FilterDescendantsInstances = { pal }
			local VEIN, VEIN_LT = C3(44, 26, 52), C3(86, 56, 96)
			local function vein(p, dir, nrm, w, len, depth, col)
				while len > 0 and w > 0.1 do
					dir = CFrame.fromAxisAngle(nrm, R(-0.45, 0.45)) * dir
					local step = math.min(len, R(1.6, 2.8))
					local hit = workspace:Raycast(p + dir * step + nrm * 1.5, -nrm * 3, vq)
					if not hit or (hit.Position - p).Magnitude > step + 1.2 then
						return
					end
					streak(p, hit.Position, hit.Normal, w, col or VEIN:Lerp(VEIN_LT, R(0, 0.35)))
					p, len, w = hit.Position, len - step, w * 0.94
					if depth > 0 and rng:NextNumber() < 0.28 then
						vein(p, CFrame.fromAxisAngle(nrm, R(0.5, 1.1) * (rng:NextNumber() < 0.5 and -1 or 1)) * dir, nrm, w * 0.7, len * R(0.4, 0.75), depth - 1, col)
					end
				end
			end
			-- the walls: the cladding fallen off in places, the rough rock behind showing, cracks running out of it, rubble below;
			-- and rot climbing them from the floor
			local WALLS = {
				{ V3(20, 0, 692.4), V3(0, 0, 1) }, { V3(62, 0, 692.4), V3(0, 0, 1) }, { V3(88, 0, 692.4), V3(0, 0, 1) },
				{ V3(8, 0, 787.6), V3(0, 0, -1) }, { V3(52, 0, 787.6), V3(0, 0, -1) }, { V3(92, 0, 787.6), V3(0, 0, -1) },
				{ V3(-13.6, 0, 722), V3(1, 0, 0) }, { V3(-13.6, 0, 764), V3(1, 0, 0) },
				{ V3(105.6, 0, 704), V3(-1, 0, 0) }, { V3(105.6, 0, 774), V3(-1, 0, 0) },
			}
			for _, w in ipairs(WALLS) do
				local nrm = w[2]
				local along = nrm:Cross(V3(0, 1, 0))
				local c = V3(w[1].X, R(CF_ + 8, CV - 8), w[1].Z) + along * R(-6, 6)
				for _ = 1, rng:NextInteger(4, 7) do
					local q = c + along * R(-3.5, 3.5) + V3(0, R(-3, 3), 0) + nrm * R(0.1, 0.4)
					P({ Name = "WallBreach", Size = V3(R(1.5, 4), R(1.5, 4), 0.8), CFrame = CFrame.lookAt(q, q + nrm) * CFrame.Angles(0, 0, R(0, 6.3)), Material = MAT.Rock, Color = C3(46, 42, 38):Lerp(ROT, R(0, 0.5)), CanCollide = false, Parent = pal })
				end
				for _ = 1, 4 do
					local a = R(0, 6.3)
					vein(c + nrm * 0.45, along * math.cos(a) + V3(0, math.sin(a), 0), nrm, R(0.2, 0.35), R(5, 10), 1, CRACK)
				end
				rubble(V3(w[1].X, CF_ + 0.2, w[1].Z) + nrm * 2.5 + along * R(-4, 4), 6, 2.5, STONE, pal)
				for _ = 1, 2 do
					vein(V3(w[1].X, CF_ + 1, w[1].Z) + along * R(-12, 12) + nrm * 0.55, V3(0, 1, 0), nrm, R(0.5, 0.8), R(14, 26), 2)
				end
			end
			-- out from where it all fell: across the court's floor, and across the throne hall's from the pit's mouth
			for i = 1, 12 do
				local a = i / 12 * math.pi * 2 + R(-0.2, 0.2)
				local dir = V3(math.cos(a), 0, math.sin(a))
				local hit = workspace:Raycast(V3(cx, CF_ + 3, cz) + dir * 3, V3(0, -6, 0), vq)
				if hit then
					vein(hit.Position, dir, V3(0, 1, 0), R(0.9, 1.4), R(22, 48), 3)
				end
			end
			for i = 1, 11 do
				local a = i / 11 * math.pi * 2 + R(-0.2, 0.2)
				local dir = V3(math.cos(a), 0, math.sin(a))
				local hit = workspace:Raycast(V3(cx + dir.X * 7, PF + 3, cz + dir.Z * 7), V3(0, -5, 0), vq)
				if hit and hit.Position.Y > PF - 1.5 then
					vein(hit.Position, dir, V3(0, 1, 0), R(0.7, 1.1), R(16, 34), 2)
				end
			end
			-- and the throne hall's east wall behind the pit: rot climbing it from the floor, stains spreading down it
			-- (thickest low), so it's no clean grey over the hole
			local wall = workspace:Raycast(V3(cx, PF + 4, cz), V3(30, 0, 0), vq)
			if wall then
				local wn = wall.Normal
				for _ = 1, 9 do
					local foot = workspace:Raycast(V3(wall.Position.X, PF + 0.6, cz + R(-22, 22)) + wn * 1.5, -wn * 3, vq)
					if foot then
						vein(foot.Position, V3(0, 1, 0), wn, R(0.6, 1.1), R(18, 40), 3)
					end
				end
				for _ = 1, 16 do -- each a ragged blotch: faint ovals overlapping
					local h = R(0, 1) * R(0, 1) * 28
					local s = R(3, 9) * (1 - h / 40)
					local c = V3(wall.Position.X, PF + h + s / 3, cz + R(-24, 24))
					local col = VEIN:Lerp(MOSS_DK, R(0, 0.7))
					for _ = 1, rng:NextInteger(5, 9) do
						local b = R(0.25, 0.6) * s
						local q = c + V3(0, R(-0.4, 0.4) * s, R(-0.5, 0.5) * s) + wn * R(0.04, 0.08)
						P({ Name = "RotStain", Shape = Enum.PartType.Cylinder, Size = V3(0.06, b * R(0.6, 1.5), b), CFrame = CFrame.lookAt(q, q + wn) * CFrame.Angles(0, math.pi / 2, 0), Material = MAT.SmoothPlastic, Color = col:Lerp(C3(20, 20, 18), R(0, 0.4)), Transparency = R(0.45, 0.75), CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Parent = pal })
					end
				end
			end
			-- and up under its vault, specks of white light adrift, rising
			local motes = P({ Name = "CourtMotes", Size = V3(116, 18, 92), CFrame = CFrame.new(46, CV - 11, 740), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = pal })
			local m = Instance.new("ParticleEmitter")
			m.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			m.Color = ColorSequence.new(Color3.new(1, 1, 1))
			m.LightEmission, m.LightInfluence = 1, 0
			m.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, 0.4), NumberSequenceKeypoint.new(0.8, 0.32), NumberSequenceKeypoint.new(1, 0) })
			m.Brightness = 3
			m.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.1), NumberSequenceKeypoint.new(0.75, 0.3), NumberSequenceKeypoint.new(1, 1) })
			m.Lifetime, m.Speed = NumberRange.new(6, 11), NumberRange.new(0.2, 0.6)
			m.Acceleration, m.Drag = V3(0, 0.25, 0), 0.5
			m.SpreadAngle = Vector2.new(180, 180)
			m.Rate = 90
			m.Shape, m.ShapeStyle = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume
			m.Parent = motes

			table.insert(info.Zones, 1, { Name = "The Rotted Court", MinX = -14, MaxX = 106, MinZ = 692, MaxZ = 788, MaxY = CV + 2 })
			local foot = CF_ + 0.2 + 3.2 -- (the court's floor, and a root's height over it)
			-- (Spot: where Ossaria waits, the court's middle, her back to the pit - and where her bonfire is left: MapBuilder
			-- makes it, last of all the bonfires)
			info.OssariaPit = { MinX = X1, MaxX = X2, MinZ = Z1, MaxZ = Z2, Top = PF, Zone = "The Rotted Court", Landing = CFrame.lookAt(V3(cx, foot, cz), V3(0, foot, 740)), Spot = V3(46, CF_ + 0.2, 740) }
		end

		-- THE SEALED DOOR: the only way into the throne hall here is the arch from the library's mezzanine onto the
		-- triforium (its east wall, x 78..80, z 780.6..785.4, sill 87.6; the great doors stay barred and everything else
		-- leads on from inside). Shut with the Gilded King's crown: it opens only to his blessing (init.server: ThroneSeal,
		-- Config.GildedKing.BlessAt) - so nobody reaches the pit, or Ossaria, before they've been up to him.
		do
			local X, ZA, ZB, SILL, TOP = 78.8, 780.6, 785.4, 87.6, 95.2
			local BRONZE, GILT = C3(58, 52, 40), C3(150, 118, 56)
			local leaf = Instance.new("Model")
			leaf.Name = "ThroneSeal"
			local function L(name, size, cf, mat, col)
				return P({ Name = name, Size = size, CFrame = cf, Material = mat, Color = col, Parent = leaf })
			end
			local mid = V3(X, (SILL + TOP) / 2, (ZA + ZB) / 2)
			local slab = L("SealDoor", V3(0.5, TOP - SILL, ZB - ZA), CFrame.new(mid), MAT.CorrodedMetal, BRONZE)
			for _, y in ipairs({ SILL + 0.9, TOP - 0.9 }) do
				L("SealBand", V3(0.6, 0.35, ZB - ZA), CFrame.new(X, y, mid.Z), MAT.Metal, GILT)
			end
			for _, sx in ipairs({ -1, 1 }) do -- (the king's crown, in gilt, on both faces; a faint light at its heart)
				local fx = X + sx * 0.3
				L("SealCrown", V3(0.15, 0.5, 2.2), CFrame.new(fx, mid.Y - 0.4, mid.Z), MAT.Metal, GILT)
				for i = -1, 1 do
					L("SealCrown", V3(0.15, i == 0 and 1.1 or 0.8, 0.35), CFrame.new(fx, mid.Y + (i == 0 and 0.4 or 0.25), mid.Z + i * 0.85), MAT.Metal, GILT)
				end
				L("SealGlow", V3(0.12, 0.3, 0.3), CFrame.new(fx, mid.Y + 1.15, mid.Z), MAT.Neon, C3(255, 214, 120))
			end
			leaf.PrimaryPart = slab
			leaf.Parent = pal
			-- (the arch's head over it, walled up, so there's no way over the leaf)
			local over = workspace:Raycast(V3(74, 103, mid.Z), V3(8, 0, 0))
			P({ Name = "SealTympanum", Size = V3(0.6, 98.4 - TOP, ZB - ZA), CFrame = CFrame.new(X, (TOP + 98.4) / 2, mid.Z), Material = over and over.Material or MAT.Cobblestone, Color = over and over.Instance.Color or C3(70, 66, 62), Parent = pal })
			local pp = Instance.new("ProximityPrompt")
			pp.ActionText, pp.ObjectText = "Open", "Sealed Door"
			pp.HoldDuration, pp.MaxActivationDistance, pp.RequiresLineOfSight = 0, 8, false
			pp.Parent = slab
			info.ThroneSeal = { Leaf = leaf, Hinge = V3(X, SILL, ZA), Sign = -1, Prompt = pp } -- (it swings in, onto the triforium)
		end
	end
	-- ITS GARRISON: the palace of Pyralis's own guards at their own posts, gone to rot (Enemies: Decayed; the king stays home)
	local GUARDS = { Stoker = true, Forgeknight = true, Ashsmith = true, Executioner = true, Pyre = true }
	for i = 1, #info.EnemySpawns do
		local s = info.EnemySpawns[i]
		local p = s.CFrame.Position + SHIFT
		if GUARDS[s.Type] and not s.Ledge and p.X >= PALACE[1] and p.X <= PALACE[3] and p.Z >= PALACE[2] and p.Z <= PALACE[4] then
			table.insert(info.EnemySpawns, { Type = s.Type, Decayed = true, CFrame = s.CFrame + SHIFT })
			if s.Type == "Ashsmith" and math.abs(s.CFrame.X - 582) < 1 and math.abs(s.CFrame.Z - 224) < 1 then
				info.MabelRingAt = p - V3(3, 3.2, 0) -- (Mabel's ring, for Giles: in the armoury by the grindstone, the Ashsmith over it)
			end
		end
	end
	-- and the town's: out in its streets, mostly the Pyres (its mages), facing the way you come in (from the east, then north)
	for _, g in ipairs({
		{ -75, 666, -40, 665, "Pyre" }, -- (inside the town gate)
		{ -110, 664, -80, 665, "Stoker" },
		{ -96, 700, -96, 670, "Pyre" }, -- (up the lane)
		{ -150, 690, -150, 670, "Executioner" }, -- (at the foot of the long street)
		{ -190, 665, -160, 665, "Pyre" }, -- (the low street's far end)
		{ -160, 750, -150, 730, "Forgeknight" }, -- (in the square)
		{ -132, 770, -150, 745, "Pyre" },
		{ -180, 760, -155, 760, "Pyre" }, -- (the upper street)
		{ -120, 788, -145, 788, "Ashsmith" }, -- (the lane past the stair)
		{ -80, 788, -110, 788, "Pyre" },
	}) do
		local p = V3(g[1], Y + 3.2, g[2])
		table.insert(info.EnemySpawns, { Type = g[5], Decayed = true, CFrame = CFrame.lookAt(p, V3(g[3], p.Y, g[4])) })
	end
	-- Giles, got here ahead of you by his own ways: sat against the passage's west wall, where nobody walks past unseen
	info.GilesWood = CFrame.lookAt(V3(80.5, Y + 0.5, 560), V3(90, Y + 0.5, 562))
	-- the town's leavings: a few things to find, their words all there is of what happened here (init.server's chests)
	info.DecayedLore = {
		{ "Lore_Proclamation", V3(-150, Y, 672), V3(0, 0, -1), "A proclamation, nailed up and rotted down. \"By the King's grace the gate is shut. None shall leave until the sickness passes.\" It did not pass." },
		{ "Lore_Buttons", V3(-140, Y, 758), V3(1, 0, 0), "A tailor's tin: needles, a brass thimble stamped with a crown, a stub of chalk. Scratched into the lid: \"G. - Tailor to the Royal House.\"" },
		{ "Lore_Hymnal", V3(-183, Y, 796), V3(0, 0, -1), "A hymnal, swollen shut. The one page that opens is a hymn to the King, the word \"King\" scratched out each time and something else written over it." },
	}
	require(script.Parent:WaitForChild("Decay")).watch(info.Decayed.Rects, map) -- (their attacks' fire, as it's made)
end

return M
