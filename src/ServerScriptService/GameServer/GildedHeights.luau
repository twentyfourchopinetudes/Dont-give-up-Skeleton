--!nonstrict
-- GildedHeights: the land above the colosseum. Where the funnel of rock over the arena flares out to a flat top (the terrain
-- pass, info.Wilds.Funnel), a kingdom of pale stone and old gold, weathered by nothing worse than time.
-- The plan, round the hole over the arena (angles from the colosseum's middle, 0 = east, the way the road comes in):
--   two hexagons of halls wall to wall, an inner (apothem 58..86) and an outer (98..118), a street between them, doors
--   through every party wall, arcades across the street;
--   a stair tower at each corner of the inner one, each opening into the halls either side of it; up its stair, sky-galleries
--   tower to tower over the roofs, a bridge out to a belvedere over the corner's garden, and one great bridge over the hole;
--   west, the palace, its dome the highest thing in the land; east, a boulevard from a shut gate to a triumphal arch.
-- Nobody gets up here yet but by the dev menu. Built last of all, with its own random stream.
--
-- THE WAY THROUGH (doors are shut by HALLS and TOWER_DOORS below, the rest by the curtain walls; info.Heights.Route has it as
-- waypoints, and M.check walks them at startup in Debug). You can't jump here, so any wall will do.
--   Leg 1: the Gilded Gate's bonfire -> the long hall (side 60) -> north tower -> the great bridge -> the Almonry (a new hanging
--     keep off the rim at 300 degrees, down one floor and back up) -> the belvedere over the boulevard: KICK THE LADDER DOWN.
--   Leg 2: down its tower -> the halls of side 300, the street, side 240 -> up the 210 tower, along the sky-gallery -> the
--     Terraces (new, off the rim at 150 degrees) -> the tunnel under the land -> the stair down the hole: CALL THE LIFT, up to
--     the hole's walk (the hub: everything comes back to it). A door in the arrival court's wall, home, OPENS FROM THE HUB ONLY.
--   Leg 3 (or from the 150 tower, instead of the Terraces): side 120's halls -> the palace's wing -> the great hall -> its
--     front door, which OPENS FROM INSIDE ONLY, onto the hub.
-- THE WAY UP: the Great Stair, from the Silver Knight's sand through the hole to the arrival court (the walk's east end, walled
-- off from the hub), and through the arch to the bonfire, where Leg 1 begins. It's hidden until all three keys come to the sand.
local M = {}

local MAT = Enum.Material
local C3 = Color3.fromRGB
local V3 = Vector3.new
local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2) -- (a cylinder's axis is X: stand it on end)

-- old stone and old gold: kept up, but centuries up here all the same (far paler than the Hollow Mansion's 62,58,56)
local IVORY, CREAM, BLUSH = C3(218, 216, 208), C3(202, 198, 188), C3(208, 198, 192)
local GOLD, LIGHT_GOLD = C3(201, 160, 74), C3(235, 200, 120)
local TARNISH, SOOT, MORTAR = C3(112, 88, 48), C3(106, 102, 96), C3(150, 146, 136)
local RUG = C3(120, 24, 44)
local LEAF, BLOSSOM, WATER = C3(86, 140, 74), C3(206, 150, 170), C3(92, 170, 178)
local GEMS = { C3(30, 70, 150), C3(150, 40, 90), C3(24, 120, 100), C3(170, 100, 30) } -- each quarter's windows: lapis, rose, jade, amber
local DOOR_W, DOOR_H = 8, 11 -- (a hall's floor is 1 up, so 10 clear)
local SKY = 31 -- the sky-galleries' floor, above the paving; every inner roof stays under it
-- which of the halls' doors exist. front/back: by hall (1 is the hall nearest the higher-degree tower); left/right: the row's
-- far ends (left the higher-degree one). The party walls between neighbours always have theirs.
local HALLS = {
	[60] = { inner = { back = { [2] = true }, right = true }, outer = { left = true, right = true } },
	[120] = { inner = { back = { [3] = true }, left = true }, outer = { front = { [4] = true }, left = true } },
	[240] = { inner = { back = { [1] = true }, right = true }, outer = { front = { [2] = true } } },
	[300] = { inner = { back = { [3] = true }, left = true }, outer = { front = { [2] = true }, right = true } },
}
-- each tower's doors, as bearings from its own deg: 0 out to the garden, 120 the way to the next tower round, 240 the way back,
-- 180 the great bridge. Stairless 270 is reached only from above, so the route can't drop out of the first leg early.
local TOWER_DOORS = {
	[30] = { ground = { 120 }, upper = { 0, 120, 240 } },
	[90] = { ground = { 0 }, upper = { 180, 240 } },
	[150] = { ground = { 240 }, upper = { 0, 120 } },
	[210] = { ground = { 120 }, upper = { 240 } },
	[270] = { ground = {}, upper = { 0, 180 } },
	[330] = { ground = { 240 }, upper = { 0, 120 } },
}
local LIFT_DEG, TUNNEL_DEG = 202.5, 148.5 -- (each the middle of one of the hole's 40 collar segments, which come out for them)
local function off(a, b) -- degrees between two bearings
	return math.abs((a - b + 180) % 360 - 180)
end

function M.build(k)
	local part, info, map, prompt = k.part, k.info, k.map, k.prompt
	info.HeightsRock = info.HeightsRock or {}
	local terrain = require(script.Parent:WaitForChild("HeightsRuin")).record(k.terrain or workspace.Terrain, info.HeightsRock) -- (its rock, logged: Ossaria's slash empties it)
	local Fn = info.Wilds.Funnel
	local ORIGIN = V3(Fn.Centre.X, Fn.Top + 0.6, Fn.Centre.Z) -- on the paving, every height below is from here
	local RIM, HOLE = Fn.Rim, 50
	local folder = Instance.new("Folder")
	folder.Name = "GildedHeights"
	folder.Parent = map

	local function P(name, size, cf, mat, col, collide)
		return part({ Name = name, Size = size, CFrame = cf, Material = mat, Color = col, CanCollide = collide ~= false, Parent = folder })
	end
	local function up(name, dia, len, base, mat, col, collide) -- a cylinder standing on base
		return part({ Name = name, Shape = Enum.PartType.Cylinder, Size = V3(len, dia, dia), CFrame = CFrame.new(base + V3(0, len / 2, 0)) * UPRIGHT, Material = mat, Color = col, CanCollide = collide ~= false, Parent = folder })
	end
	local function ball(name, dia, pos, mat, col)
		return part({ Name = name, Shape = Enum.PartType.Ball, Size = Vector3.one * dia, CFrame = CFrame.new(pos), Material = mat, Color = col, CanCollide = false, Parent = folder })
	end
	-- a pointed roof: rings stacked and narrowing, "dome" full-bellied to a point, anything else a slender spire
	local function taper(base, r, h, n, shape, tip)
		local dy = h / n
		for i = 0, n - 1 do
			local t = (i + 0.5) / n
			local rr = shape == "dome" and r * (1 - t ^ 2.4) or r * (1 - t) ^ 1.3
			up("RoofTier", 2 * math.max(rr, 0.35), dy + 0.03, base + V3(0, i * dy, 0), MAT.Metal, GOLD, false)
		end
		if tip then
			up("Needle", 0.5, tip, base + V3(0, h - dy / 2, 0), MAT.Metal, GOLD, false)
		end
	end
	local rng = Random.new(9191)
	local function R(a, b)
		return rng:NextNumber(a, b)
	end
	-- a thin skin of dirt on a face: seen, but never in anything's way
	local function film(name, size, cf, col, transparency)
		local p = P(name, size, cf, MAT.SmoothPlastic, col, false)
		p.Transparency, p.CastShadow, p.CanQuery, p.CanTouch = transparency or 0, false, false, false
		return p
	end
	local function slope(name, size, cf, mat, col) -- a wedge, rising towards its +Z
		local w = Instance.new("WedgePart")
		w.Name, w.Anchored, w.Size, w.CFrame, w.Material, w.Color = name, true, size, cf, mat, col
		w.TopSurface, w.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		w.Parent = folder
		return w
	end
	local function glow(pos, range, brightness)
		local g = P("Lamp", V3(1.2, 1.8, 1.2), CFrame.new(pos), MAT.Neon, LIGHT_GOLD, false)
		P("LampCap", V3(1.8, 0.4, 1.8), CFrame.new(pos + V3(0, 1.1, 0)), MAT.Metal, GOLD, false)
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = C3(255, 240, 220), range, brightness * 0.4
		l.Parent = g
	end
	local function dir(deg)
		local a = math.rad(deg)
		return V3(math.cos(a), 0, math.sin(a))
	end
	local function pol(deg, r)
		return ORIGIN + dir(deg) * r
	end
	local function side(deg, apothem) -- a frame on the hexagons' side at deg: +Z out, away from the hole
		return CFrame.lookAt(pol(deg, apothem), ORIGIN)
	end
	-- a ring of n segments round c, r1..r2 out, y1..y2 up (gap(deg): segments to leave out)
	local function ring(c, r1, r2, y1, y2, n, mat, col, name, phase, gap)
		for i = 0, n - 1 do
			local deg = (i + 0.5) * 360 / n + (phase or 0)
			if not (gap and gap(deg)) then
				local out = dir(deg)
				local m = c + out * ((r1 + r2) / 2) + V3(0, (y1 + y2) / 2, 0)
				P(name, V3(2 * r2 * math.sin(math.pi / n) + 0.2, y2 - y1, r2 - r1), CFrame.lookAt(m, m + out), mat, col)
			end
		end
	end

	-- a wall along a to b (both in cf's space, on its floor), with the openings in cuts ({ u along it, w, y1, y2 }). Its
	-- inside is the returned frame's +X, so walk a building's walls in the order hall() does. The frame's -Z runs a to b.
	local function wall(cf, a, b, y1, y2, t, cuts, mat, col)
		local F = cf * CFrame.lookAt(a, b)
		local function piece(u1, u2, v1, v2)
			if u2 - u1 > 0.01 and v2 - v1 > 0.01 then
				P("Wall", V3(t, v2 - v1, u2 - u1), F * CFrame.new(t / 2, (v1 + v2) / 2, -(u1 + u2) / 2), mat, col)
			end
		end
		local u = 0
		for _, c in ipairs(cuts) do
			piece(u, c.u - c.w / 2, y1, y2)
			piece(c.u - c.w / 2, c.u + c.w / 2, y1, c.y1)
			piece(c.u - c.w / 2, c.u + c.w / 2, c.y2, y2)
			u = c.u + c.w / 2
		end
		piece(u, (b - a).Magnitude, y1, y2)
		return F
	end
	-- spec: { "d" door and windows, "w" windows, "p" door only (a party wall); u = where the door is, h = wall height }
	local function facade(cf, a, b, h, spec, gem)
		local kind, wh, T = spec[1], spec.h or h, 1.2
		local len = (b - a).Magnitude
		local du = spec.u or len / 2
		local door = kind ~= "w"
		local F = wall(cf, a, b, 0, wh, T, door and { { u = du, w = DOOR_W, y1 = 0, y2 = DOOR_H } } or {}, MAT.Limestone, IVORY)
		if kind == "p" then
			return
		end
		-- its age: mortar courses (around the door), rain run down from the cornice, dirt along its foot, a crack or two
		local function across(name, y, h, depth, col, transparency)
			local spans = door and y - h / 2 < DOOR_H + 1.2 and { { 0, du - 5.2 }, { du + 5.2, len } } or { { 0, len } }
			for _, q in ipairs(spans) do
				if q[2] - q[1] > 0.1 then
					film(name, V3(depth, h, q[2] - q[1]), F * CFrame.new(-depth / 2, y, -(q[1] + q[2]) / 2), col, transparency)
				end
			end
		end
		for y = 3.6, wh - 1.5, 3.6 do
			across("Course", y, 0.14, 0.05, MORTAR, 0.15)
		end
		across("FootDirt", 0.8, 1.6, 0.04, SOOT, 0.55)
		for _ = 1, math.ceil(len / 5) do
			local u = R(0.5, len - 0.5)
			local top = wh - R(0.2, 1.5)
			local run = R(3, wh * 0.5)
			if door and math.abs(u - du) < 5.5 then
				run = math.min(run, top - DOOR_H - 1.2)
			end
			if run > 0.5 then
				film("Streak", V3(0.03, run, R(0.4, 1.3)), F * CFrame.new(-0.02, top - run / 2, -u), SOOT, R(0.55, 0.78))
			end
		end
		if rng:NextNumber() < 0.55 then
			local u, y, ang = R(1, len - 1), R(wh * 0.5, wh - 2), R(-2.2, -0.9)
			for _ = 1, rng:NextInteger(3, 6) do
				local seg = R(0.7, 1.5)
				local u2, y2 = u + math.cos(ang) * seg, y + math.sin(ang) * seg
				if y2 < DOOR_H + 1.5 or u2 < 0.3 or u2 > len - 0.3 then
					break
				end
				film("Crack", V3(0.04, 0.1, seg + 0.08), F * CFrame.new(-0.03, (y + y2) / 2, -(u + u2) / 2) * CFrame.Angles(math.atan2(y2 - y, u2 - u), 0, 0), C3(92, 84, 70))
				u, y = u2, y2
				ang += R(-0.7, 0.7)
			end
		end
		local n = math.max(math.floor(len / 10), 1)
		local bay = len / n
		local paneW = math.min(bay * 0.45, 4)
		for i = 1, n do
			local u = (i - 0.5) * bay
			if not door or math.abs(u - du) > DOOR_W / 2 + paneW / 2 + 0.5 then
				local top = wh - 3 - paneW / 2
				P("Window", V3(T + 0.3, top - 5, paneW), F * CFrame.new(T / 2, (top + 5) / 2, -u), MAT.Glass, gem)
				part({ Name = "WindowHead", Shape = Enum.PartType.Cylinder, Size = V3(T + 0.3, paneW, paneW), CFrame = F * CFrame.new(T / 2, top, -u), Material = MAT.Glass, Color = gem, Parent = folder })
				P("Sill", V3(0.5, 0.3, paneW + 0.6), F * CFrame.new(-0.25, 4.85, -u), MAT.Limestone, CREAM, false)
				film("SillDrip", V3(0.03, 2.4, paneW * 0.7), F * CFrame.new(-0.02, 3.4, -u), SOOT, 0.72)
			end
		end
		for i = 0, n do
			local u = i * bay
			if not door or math.abs(u - du) > DOOR_W / 2 + 1 then
				P("Pilaster", V3(0.6, wh - 1, 1.4), F * CFrame.new(-0.3, (wh - 1) / 2, -u), MAT.Limestone, CREAM)
				P("PilasterCap", V3(1, 0.8, 2), F * CFrame.new(-0.4, wh - 1.2, -u), MAT.Metal, GOLD, false)
			end
		end
		if door then -- a gilt frame, and a jewel over it
			for _, s in ipairs({ -1, 1 }) do
				P("DoorFrame", V3(0.6, DOOR_H, 0.8), F * CFrame.new(-0.2, DOOR_H / 2, -(du + s * (DOOR_W / 2 + 0.4))), MAT.Metal, GOLD)
			end
			P("DoorFrame", V3(0.6, 0.9, DOOR_W + 1.6), F * CFrame.new(-0.2, DOOR_H + 0.45, -du), MAT.Metal, GOLD, false)
			if wh >= 16 then
				part({ Name = "Rosette", Shape = Enum.PartType.Cylinder, Size = V3(T + 0.3, 3.6, 3.6), CFrame = F * CFrame.new(T / 2, DOOR_H + 3, -du), Material = MAT.Glass, Color = gem, Parent = folder })
			end
		end
	end
	local function pinnacle(cf, x, y, z)
		local base = (cf * CFrame.new(x, y, z)).Position
		taper(base, 0.6, 4, 3, "spire")
	end
	-- a hall, x1..x2, z1..z2 in cf's space. walls: front (z1), right (x2), back (z2), left (x1), each a facade spec or nil for
	-- none (a neighbour's). roof: "gable", "vault", "dome", or nil
	local function hall(cf, x1, x2, z1, z2, h, roof, walls, gem)
		local w, d = x2 - x1, z2 - z1
		local cx, cz = (x1 + x2) / 2, (z1 + z2) / 2
		local at = function(x, y, z)
			return cf * CFrame.new(x, y, z)
		end
		P("Floor", V3(w, 1, d), at(cx, 0.5, cz), MAT.Limestone, CREAM)
		P("Runner", V3(4, 0.1, d - 2), at(cx, 1.05, cz), MAT.Fabric, RUG, false)
		local perimeter = {
			{ walls.front, V3(x1, 0, z1), V3(x2, 0, z1) },
			{ walls.right, V3(x2, 0, z1), V3(x2, 0, z2) },
			{ walls.back, V3(x2, 0, z2), V3(x1, 0, z2) },
			{ walls.left, V3(x1, 0, z2), V3(x1, 0, z1) },
		}
		for _, q in ipairs(perimeter) do
			if q[1] then
				facade(cf, q[2], q[3], h, q[1], gem)
			end
		end
		-- the gold ceiling, its edge a gilt band under the cornice
		P("Ceiling", V3(w + 1.2, 0.5, d + 1.2), at(cx, h - 0.25, cz), MAT.Metal, GOLD)
		P("Cornice", V3(w + 2, 1.2, d + 2), at(cx, h + 0.6, cz), MAT.Limestone, IVORY)
		if d >= 18 and w >= 18 then
			local n = math.floor((w - 4) / 16) * 2 -- (an even number: none on the hall's axis, in the way from door to door)
			for i = 1, n do
				for _, s in ipairs({ -1, 1 }) do
					up("HallColumn", 1.6, h - 1.5, (at(x1 + i * w / (n + 1), 1, cz + s * d / 4)).Position, MAT.Limestone, IVORY)
				end
			end
		end
		if w >= 14 then
			P("ChandelierChain", V3(0.3, 4, 0.3), at(cx, h - 2.5, cz), MAT.Metal, GOLD, false)
			glow(at(cx, h - 5, cz).Position, 30, 1.3)
		end
		local top = h + 1.2
		if roof == "gable" then
			local rise, run = d * 0.25, d / 2 + 0.9
			slope("Roof", V3(w + 1.8, rise, run), at(cx, top + rise / 2, z1 - 0.9 + run / 2), MAT.Metal, GOLD)
			slope("Roof", V3(w + 1.8, rise, run), at(cx, top + rise / 2, z2 + 0.9 - run / 2) * CFrame.Angles(0, math.pi, 0), MAT.Metal, GOLD)
			P("Ridge", V3(w + 1.8, 0.5, 0.9), at(cx, top + rise + 0.1, cz), MAT.Limestone, IVORY, false)
		elseif roof == "vault" then
			-- (on a solid attic as tall as the barrel's radius, or its round ends would show through the doors below)
			local r = d / 2 - 0.5
			P("Attic", V3(w - 0.2, r, d - 1), at(cx, top + r / 2, cz), MAT.Limestone, IVORY)
			part({ Name = "Vault", Shape = Enum.PartType.Cylinder, Size = V3(w - 0.2, 2 * r, 2 * r), CFrame = at(cx, top + r, cz), Material = MAT.Metal, Color = GOLD, CanCollide = false, Parent = folder })
		elseif roof == "dome" then
			local r = math.min(w, d) / 2 - 1
			local base = at(cx, top, cz).Position
			up("Drum", 2 * r, 2.5, base, MAT.Limestone, IVORY)
			taper(base + V3(0, 2.5, 0), r, r * 1.6, 14, "dome", 3.5)
		end
		if roof then
			for _, c in ipairs({ { x1, z1 }, { x2, z1 }, { x1, z2 }, { x2, z2 } }) do
				pinnacle(cf, c[1], top, c[2])
			end
		end
	end

	-- a stair tower: 12 faces round c, the first looking along deg. doors: [bearing from deg, a multiple of 30] = { y1, y2 } list
	local function tower(c, deg, r, H, doors, stairs, gem)
		local faceW = 2 * r * math.tan(math.pi / 12) + 0.3
		for i = 0, 11 do
			local b = i * 30
			local out = dir(deg + b)
			local m = c + out * (r - 0.6)
			local F = CFrame.lookAt(m, m + out)
			local y = 0
			local function piece(v1, v2)
				if v2 - v1 > 0.01 then
					P("TowerWall", V3(faceW, v2 - v1, 1.2), F * CFrame.new(0, (v1 + v2) / 2, 0), MAT.Limestone, IVORY)
				end
			end
			for _, cut in ipairs(doors[b] or {}) do
				piece(y, cut[1])
				y = cut[2]
				if cut[1] > 0 then -- (a sill: the landing and the stair's top stop short of the wall)
					P("Landing", V3(faceW, 0.6, 2.6), F * CFrame.new(0, cut[1] - 0.3, 0.1), MAT.Limestone, CREAM)
				end
			end
			piece(y, H)
			if i % 2 == 1 and not doors[b] then
				P("TowerSlit", V3(1.5, 12, 1.5), F * CFrame.new(0, H * 0.5, 0), MAT.Glass, gem)
			end
			if not doors[b] then
				local run = R(6, H * 0.45)
				film("Streak", V3(R(0.5, 1.4), run, 0.03), F * CFrame.new(R(-1.4, 1.4), H - 3 - run / 2, -0.62), SOOT, R(0.58, 0.78))
			end
		end
		up("TowerFloor", 2 * r - 1, 1, c, MAT.Limestone, CREAM)
		if stairs == "deck" then -- (no way down: the whole landing floored)
			up("Landing", 2 * r - 1, 0.6, c + V3(0, SKY - 0.6, 0), MAT.Limestone, CREAM)
		end
		ring(c, r - 0.1, r + 0.4, H - 3, H - 2, 12, MAT.Metal, GOLD, "TowerBand", deg - 15)
		up("TowerCornice", 2 * r + 2, 1.2, c + V3(0, H, 0), MAT.Limestone, IVORY)
		-- a slender gold spire; its courses above the doors, and the rain's marks down its faces
		taper(c + V3(0, H + 1.2, 0), r, r * 3.2, 20, "spire", 4)
		for _, y in ipairs({ 14, 24 }) do
			ring(c, r - 0.1, r + 0.04, y - 0.07, y + 0.07, 12, MAT.Limestone, MORTAR, "Course", deg - 15)
		end
		if stairs == true then
			-- one whole turn, 1.25 up every 15 degrees, from bearing 20 round to bearing 5: clear of each ground door's
			-- headroom, and coming out right beside the door at bearing 0
			for i = 1, 24 do
				local out = dir(deg + 5 + 15 * i)
				local m = c + out * 5.2 + V3(0, 0.55 + i * 1.25, 0)
				P("Stair", V3(3, 0.9, 4.4), CFrame.lookAt(m, m + out), MAT.Limestone, CREAM)
			end
			-- the landing, open over the stair's last steps
			for b = 30, 270, 30 do
				local out = dir(deg + b)
				local m = c + out * 5.2 + V3(0, SKY - 0.3, 0)
				P("Landing", V3(4.2, 0.6, 4.6), CFrame.lookAt(m, m + out), MAT.Limestone, CREAM)
			end
			up("Landing", 6, 0.6, c + V3(0, SKY - 0.6, 0), MAT.Limestone, CREAM)
		end
	end

	-- a covered walk from a to b, its floor at their height: open columns under a gold pitched roof. opts: floor and rail (up in the
	-- air), legs (how far its piers drop to the roofs below)
	local function gallery(a, b, w, h, opts)
		local len = (b - a).Magnitude
		local F = CFrame.lookAt(a, b)
		local n = math.max(math.round(len / 8), 1)
		for i = 0, n do
			for _, s in ipairs({ -1, 1 }) do
				local p = (F * CFrame.new(s * (w / 2 - 0.5), 0, -len * i / n)).Position
				up("GalleryColumn", 1.1, h, p, MAT.Limestone, IVORY)
				if opts.legs and i % 2 == 0 then
					up("GalleryPier", 1.6, opts.legs, p - V3(0, opts.legs, 0), MAT.Limestone, CREAM)
				end
			end
		end
		P("GalleryCeiling", V3(w + 0.8, 0.6, len), F * CFrame.new(0, h + 0.3, -len / 2), MAT.Limestone, IVORY)
		local rise, run = w * 0.3, w / 2 + 0.4
		for _, s in ipairs({ -1, 1 }) do
			slope("GalleryRoof", V3(len, rise, run), F * CFrame.new(s * run / 2, h + 0.6 + rise / 2, -len / 2) * CFrame.Angles(0, s > 0 and -math.pi / 2 or math.pi / 2, 0), MAT.Metal, GOLD)
		end
		if opts.floor then
			P("GalleryFloor", V3(w, 0.8, len), F * CFrame.new(0, -0.4, -len / 2), MAT.Limestone, CREAM)
			P("Runner", V3(2.4, 0.1, len), F * CFrame.new(0, 0.05, -len / 2), MAT.Fabric, RUG, false)
		end
		if opts.rail then
			for _, s in ipairs({ -1, 1 }) do
				P("GalleryRail", V3(0.5, 3, len), F * CFrame.new(s * (w / 2 - 0.5), 1.5, -len / 2), MAT.Limestone, IVORY)
			end
		end
	end
	-- a blossom tree: roots, a leaning trunk in three lengths, six branches spreading flat off its top two joints, clumps of
	-- blossom in mixed pinks along them, petals drifted round its foot and falling. (About 7 out and 11 up.)
	local BARK = C3(74, 54, 50)
	local PINKS = { BLOSSOM, C3(226, 176, 192), C3(240, 206, 214), C3(188, 120, 146) }
	local function tree(pos)
		local tr = Random.new(math.floor(pos.X * 7 + pos.Z * 13)) -- (its own stream: the land's rng stays as it was)
		local function n(a, b)
			return tr:NextNumber(a, b)
		end
		local function limb(a, b, d, collide)
			local m = (a + b) / 2
			part({ Name = "BlossomLimb", Shape = Enum.PartType.Cylinder, Size = V3((b - a).Magnitude + d * 0.4, d, d), CFrame = CFrame.lookAt(m, b) * CFrame.Angles(0, math.pi / 2, 0), Material = MAT.Wood, Color = BARK, CanCollide = collide, Parent = folder })
			ball("BlossomKnot", d * 1.05, b, MAT.Wood, BARK)
		end
		local last
		local function clump(at, k, s)
			for _ = 1, k do
				last = ball("Blossom", n(s * 0.75, s), at + V3(n(-1.1, 1.1), n(-0.3, 0.7), n(-1.1, 1.1)), MAT.SmoothPlastic, PINKS[tr:NextInteger(1, #PINKS)])
			end
		end
		local la = n(0, math.pi * 2)
		for i = 0, 3 do
			local a = la + i * math.pi / 2 + n(-0.35, 0.35)
			limb(pos + V3(0, 1.4, 0), pos + V3(math.cos(a), 0, math.sin(a)) * n(1.6, 2.3) + V3(0, 0.15, 0), 0.6, false)
		end
		local lean = V3(math.cos(la), 0, math.sin(la))
		local joints, p = {}, pos
		for _, q in ipairs({ { 2.6, 0.15, 1.5 }, { 2.2, 0.3, 1.2 }, { 1.6, 0.1, 0.95 } }) do -- rise, lean, girth
			local nx = p + V3(n(-0.15, 0.15), q[1], n(-0.15, 0.15)) + lean * q[2]
			limb(p, nx, q[3], true)
			table.insert(joints, nx)
			p = nx
		end
		for i = 1, 6 do
			local a = la + i * math.pi / 3 + n(-0.25, 0.25)
			local out = V3(math.cos(a), 0, math.sin(a))
			local from = joints[i % 2 == 0 and 2 or 3]
			local elbow = from + out * n(1.6, 2.2) + V3(0, n(0.7, 1.3), 0)
			local tip = elbow + out * n(1.2, 1.8) + V3(0, n(0.1, 0.6), 0)
			limb(from, elbow, 0.5, false)
			limb(elbow, tip, 0.3, false)
			clump(tip + V3(0, 0.6, 0), 4, 2.6)
			clump(elbow + V3(0, 0.9, 0), 1, 2.2)
		end
		clump(p + V3(0, 1.8, 0), 3, 3)
		local crown = last
		for _ = 1, 6 do
			local d = n(0.8, 1.8)
			local at = pos + V3(n(-4, 4), 0.06, n(-4, 4))
			part({ Name = "FallenPetals", Shape = Enum.PartType.Cylinder, Size = V3(0.06, d, d), CFrame = CFrame.new(at) * UPRIGHT, Material = MAT.SmoothPlastic, Color = PINKS[tr:NextInteger(2, #PINKS)], CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Parent = folder })
		end
		local e = Instance.new("ParticleEmitter")
		e.Name = "Petals"
		e.Color = ColorSequence.new(C3(240, 200, 212), BLOSSOM)
		e.Size = NumberSequence.new(0.22, 0.14)
		e.Lifetime = NumberRange.new(6, 9)
		e.Rate = 1.5
		e.Speed = NumberRange.new(0.2, 0.6)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Acceleration = V3(0.4, -0.7, 0.3)
		e.Drag = 0.6
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-90, 90)
		e.Shape, e.ShapeStyle = Enum.ParticleEmitterShape.Sphere, Enum.ParticleEmitterShapeStyle.Volume
		e.Parent = crown
	end
	local function fountain(pos)
		up("FountainRim", 18, 1.6, pos, MAT.Limestone, IVORY)
		up("FountainWater", 16, 0.2, pos + V3(0, 1.6, 0), MAT.Glass, WATER, false)
		up("FountainStem", 2.4, 6, pos + V3(0, 1.6, 0), MAT.Limestone, IVORY)
		up("FountainBowl", 7, 0.8, pos + V3(0, 7.6, 0), MAT.Metal, GOLD)
		local g = up("FountainHead", 1.2, 2, pos + V3(0, 8.4, 0), MAT.Metal, GOLD)
		local e = Instance.new("ParticleEmitter")
		e.Color = ColorSequence.new(C3(220, 250, 255))
		e.Size = NumberSequence.new(0.5, 0.15)
		e.Lifetime = NumberRange.new(1, 1.6)
		e.Speed = NumberRange.new(10, 14)
		e.Acceleration = V3(0, -22, 0)
		e.SpreadAngle = Vector2.new(22, 22)
		e.Rate = 50
		e.EmissionDirection = Enum.NormalId.Right -- (a standing cylinder's end)
		e.Parent = g
	end
	local function lamp(pos)
		up("LampPost", 0.7, 8, pos, MAT.Metal, GOLD)
		glow(pos + V3(0, 9, 0), 24, 1)
	end

	-- THE GROUND: paving in bands, a gold collar round the hole, a gilt skirt over the rock at the rim, parapets on both edges
	for _, q in ipairs({ { 49, 58, IVORY }, { 58, 86, CREAM }, { 86, 100, BLUSH }, { 100, RIM + 0.5, IVORY } }) do
		ring(ORIGIN, q[1], q[2], -0.6, 0, math.ceil(2 * math.pi * q[2] / 16), MAT.Pavement, q[3], "Paving")
	end
	local function liftGap(deg)
		return off(deg, LIFT_DEG) < 1
	end
	ring(ORIGIN, 48, 50, -12, -0.2, 40, MAT.Metal, GOLD, "HoleCollar", 0, function(deg)
		return liftGap(deg) or off(deg, TUNNEL_DEG) < 1
	end)
	local function stairGap(deg) -- (the two segments due east, gone once the Great Stair's bridge is there)
		return off(deg, 0) < 5
	end
	local function solid(deg)
		return liftGap(deg) or stairGap(deg)
	end
	local function onlyGap(deg)
		return not stairGap(deg)
	end
	ring(ORIGIN, HOLE, HOLE + 0.9, 0, 2.6, 40, MAT.Limestone, IVORY, "Parapet", 0, solid)
	ring(ORIGIN, HOLE - 0.1, HOLE + 1, 2.6, 3, 40, MAT.Metal, GOLD, "ParapetCap", 0, solid)
	ring(ORIGIN, HOLE, HOLE + 0.9, 0, 2.6, 40, MAT.Limestone, IVORY, "StairParapet", 0, onlyGap)
	ring(ORIGIN, HOLE - 0.1, HOLE + 1, 2.6, 3, 40, MAT.Metal, GOLD, "StairParapet", 0, onlyGap)
	ring(ORIGIN, RIM - 2, RIM + 0.6, -14, -0.8, 72, MAT.Limestone, IVORY, "RimSkirt", 0, function(deg)
		return off(deg, 147.5) < 1 -- (the tunnel's mouth)
	end)
	ring(ORIGIN, RIM - 2, RIM + 0.9, -0.8, -0.1, 72, MAT.Metal, GOLD, "RimBand")
	local function ballroomGap(deg) -- (behind the palace: the Ballroom's stair goes out over the rim here)
		return off(deg, 180) < 3
	end
	ring(ORIGIN, RIM - 0.4, RIM + 0.5, 0, 3.2, 72, MAT.Limestone, IVORY, "Parapet", 0, ballroomGap)
	ring(ORIGIN, RIM - 0.5, RIM + 0.6, 3.2, 3.6, 72, MAT.Metal, GOLD, "ParapetCap", 0, ballroomGap)
	-- old stains on the paving (the halls' floors stand over any that fall under them), and the rain's long marks down the rim
	for _ = 1, 150 do
		local d = R(3, 14)
		part({ Name = "Stain", Shape = Enum.PartType.Cylinder, Size = V3(0.04, d, d), CFrame = CFrame.new(pol(R(0, 360), R(53, RIM - 3)) + V3(0, 0.03, 0)) * UPRIGHT, Material = MAT.SmoothPlastic, Color = SOOT, Transparency = R(0.72, 0.88), CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Parent = folder })
	end
	for _ = 1, 60 do
		local out = dir(R(0, 360))
		local run = R(3, 11)
		local m = ORIGIN + out * (RIM + 0.75) + V3(0, -1 - run / 2, 0)
		film("Streak", V3(R(0.5, 1.8), run, 0.04), CFrame.lookAt(m, m + out), SOOT, R(0.55, 0.78))
	end

	-- THE HALLS: the four sides north and south (east's the boulevard, west's the palace), all their doors in line
	local INNER = { { 16, "gable" }, { 14, "gable" }, { 17, "gable" }, { 15, "gable" } } -- (gables only: the sky-galleries run over these)
	local OUTER = { { 22, "dome" }, { 17, "gable" }, { 24, "vault" }, { 19, "gable" }, { 21, "dome" }, { 18, "gable" } }
	local INNER_X = { -33.5, -11, 11, 33.5 }
	local OUTER_X = { -48, -34.5, -10, 10, 34.5, 48 }
	for si, deg in ipairs({ 60, 120, 240, 300 }) do
		local gem = GEMS[si]
		local function row(cf, xs, types, z1, z2, open)
			local function door(on)
				return { on and "d" or "w" }
			end
			for i = 1, #xs - 1 do
				local t, nxt = types[(i + si) % #types + 1], types[(i + si + 1) % #types + 1]
				hall(cf, xs[i], xs[i + 1], z1, z2, t[1], t[2], {
					front = door(open.front and open.front[i]),
					back = door(open.back and open.back[i]),
					left = i == 1 and door(open.left) or nil,
					right = i < #xs - 1 and { "p", h = math.max(t[1], nxt[1]) } or door(open.right),
				}, gem)
			end
		end
		local inner, outer = side(deg, 72), side(deg, 108)
		row(inner, INNER_X, INNER, -14, 14, HALLS[deg].inner)
		row(outer, OUTER_X, OUTER, -10, 10, HALLS[deg].outer)
		-- covered ways over the street, door to door, and its lamps
		for _, x in ipairs({ -22.25, 22.25 }) do
			gallery((inner * CFrame.new(x, 0, 14)).Position, (outer * CFrame.new(x, 0, -10)).Position, 9, 13, {})
		end
		for _, x in ipairs({ -8, 8 }) do
			lamp((inner * CFrame.new(x, 0, 20)).Position)
		end
	end

	-- THE PALACE (west): a porticoed front, a great hall under the dome, and a wing each side of it
	do
		local cf = side(180, 72)
		local gem = C3(120, 60, 220)
		hall(cf, -33, 33, -14, 4, 20, "gable", { front = { "d" }, right = { "w" }, back = { "p" }, left = { "w" } }, gem)
		hall(cf, -30, 30, 4, 46, 26, nil, { right = { "p", u = 26 }, back = { "d" }, left = { "p", u = 16 } }, gem) -- (back: the door behind the throne, out to the Ballroom's stair)
		for _, s in ipairs({ -1, 1 }) do
			local x1, x2 = math.min(s * 30, s * 46), math.max(s * 30, s * 46)
			hall(cf, x1, x2, 14, 46, 22, "dome", { front = { "w" }, back = { "w" }, right = s > 0 and { "d" } or nil, left = s < 0 and { "w" } or nil }, gem)
		end
		-- the portico
		for i = 0, 7 do
			local x = -28 + i * 8
			up("PorticoColumn", 2, 18, (cf * CFrame.new(x, 0, -18)).Position, MAT.Limestone, IVORY)
			P("PorticoCap", V3(3, 1, 3), cf * CFrame.new(x, 18.5, -18), MAT.Metal, GOLD, false)
		end
		P("PorticoLintel", V3(62, 2, 8), cf * CFrame.new(0, 20, -17), MAT.Limestone, IVORY)
		for _, s in ipairs({ -1, 1 }) do
			slope("Pediment", V3(7, 6, 31), cf * CFrame.new(s * 15.5, 24, -17) * CFrame.Angles(0, s > 0 and -math.pi / 2 or math.pi / 2, 0), MAT.Limestone, IVORY)
		end
		-- the throne, at the back of the great hall
		P("Dais", V3(18, 1, 8), cf * CFrame.new(0, 1.5, 39), MAT.Limestone, IVORY)
		P("Throne", V3(5, 2, 4), cf * CFrame.new(0, 3, 39.5), MAT.Metal, GOLD)
		P("ThroneBack", V3(5, 9, 1), cf * CFrame.new(0, 6.5, 41.2), MAT.Metal, GOLD)
		-- the drum and the dome, off the great hall's roof
		local base = (cf * CFrame.new(0, 27.2, 25)).Position
		up("GreatDrum", 38, 19, base, MAT.Limestone, IVORY)
		for i = 0, 15 do
			local a = i * 22.5
			up("DrumColumn", 1.6, 17, base + dir(a) * 20, MAT.Limestone, CREAM)
			local out = dir(a + 11.25)
			local m = base + out * 18.9 + V3(0, 9, 0)
			P("DrumWindow", V3(3, 12, 0.5), CFrame.lookAt(m, m + out), MAT.Glass, GEMS[i % 4 + 1])
		end
		up("DrumCornice", 44, 2, base + V3(0, 17, 0), MAT.Metal, GOLD)
		-- the great dome, ribbed, rising to a point under a little lantern
		local domeBase, DOME_R, DOME_H = base + V3(0, 19, 0), 19, 32
		taper(domeBase, DOME_R, DOME_H, 32, "dome")
		for i = 0, 11 do
			local out = dir(i * 30)
			local function ribAt(t)
				return domeBase + out * (DOME_R * (1 - t ^ 2.4) + 0.1) + V3(0, DOME_H * t, 0)
			end
			for s = 0, 7 do
				local p, q = ribAt(s / 9), ribAt((s + 1) / 9)
				P("DomeRib", V3(0.9, 0.7, (q - p).Magnitude + 0.2), CFrame.lookAt((p + q) / 2, q), MAT.Metal, LIGHT_GOLD, false)
			end
		end
		local lantern = domeBase + V3(0, DOME_H * 0.88, 0)
		up("Lantern", 9, 5, lantern, MAT.Limestone, IVORY)
		for i = 0, 7 do
			up("LanternColumn", 0.8, 5, lantern + dir(i * 45) * 4.7, MAT.Limestone, CREAM)
		end
		up("LanternCornice", 11, 0.8, lantern + V3(0, 5, 0), MAT.Metal, GOLD)
		taper(lantern + V3(0, 5.8, 0), 4.6, 13, 8, "spire", 6)
	end

	-- THE CORNERS: the stair towers, the sky-galleries between them, belvederes out over the gardens
	local TOWER_R, TOWER_AT = 9, 83
	local UPPER = { SKY, SKY + 8 }
	local towers = {}
	local BELVEDERE_OUT = { [150] = { 150 }, [270] = { 300 }, [330] = { 300, 330 } }
	for i, v in ipairs({ 30, 90, 150, 210, 270, 330 }) do
		local c = pol(v, TOWER_AT)
		towers[v] = c
		local doors = {}
		for _, b in ipairs(TOWER_DOORS[v].ground) do
			doors[b] = { { 0, DOOR_H } }
		end
		for _, b in ipairs(TOWER_DOORS[v].upper) do
			doors[b] = doors[b] or {}
			table.insert(doors[b], UPPER)
		end
		tower(c, v, TOWER_R, 44, doors, v == 270 and "deck" or true, GEMS[i % 4 + 1])
		local sky = V3(0, SKY, 0)
		-- to the next tower round: in the air the whole way, over the roofs (or the arch, or the palace's front)
		local nxt = pol(v + 60, TOWER_AT)
		local along = dir(v + 120)
		gallery(c + sky + along * TOWER_R, nxt + sky - along * TOWER_R, 6, 8, { floor = true, rail = true, legs = 7 })

		-- the belvedere: a domed lookout on a stalk, its bridge out from the tower's top
		local b = pol(v, 112)
		local outs = BELVEDERE_OUT[v] or {} -- (bearings its rail is open towards, besides its bridge)
		local function faces(deg, within)
			for _, o in ipairs(outs) do
				if off(deg, o) < within then
					return true
				end
			end
			return false
		end
		up("BelvedereStalk", 6, SKY - 0.6, b, MAT.Limestone, IVORY) -- (slim: the way round it at the foot of the tower is a squeeze)
		ring(b, 2.8, 3.4, 4, 5, 8, MAT.Metal, GOLD, "StalkBand")
		up("BelvedereFloor", 15, 0.6, b + V3(0, SKY - 0.6, 0), MAT.Limestone, CREAM)
		ring(b, 6.6, 7.4, SKY, SKY + 3, 12, MAT.Limestone, IVORY, "BelvedereRail", 0, function(deg)
			return off(deg, v + 180) < 20 or faces(deg, 20)
		end)
		for n = 0, 7 do
			if not faces(n * 45 + 22.5, 14) and off(n * 45 + 22.5, v + 180) > 14 then -- (none in a doorway, its bridge's included)
				up("BelvedereColumn", 1, 10, b + dir(n * 45 + 22.5) * 6.6 + V3(0, SKY, 0), MAT.Limestone, IVORY)
			end
		end
		up("BelvedereRoof", 16, 1, b + V3(0, SKY + 10, 0), MAT.Limestone, IVORY)
		taper(b + V3(0, SKY + 11, 0), 7, 11, 12, "dome", 3)
		gallery(pol(v, TOWER_AT + TOWER_R) + sky, pol(v, 112 - 7) + sky, 6, 8, { floor = true, rail = true })

		-- its garden: a lawn round the stalk, blossom at either end
		up("Lawn", 30, 0.3, b, MAT.Grass, LEAF, false)
		if v ~= 90 and v ~= 270 then -- (the way past the stalks there is narrow enough)
			tree(pol(v, 100))
			if v ~= 330 then -- (the ladder comes down here)
				tree(pol(v, 124))
			end
		end
	end

	-- THE GREAT BRIDGE over the hole, north tower to south, sprung on two gold ribs from the hole's rim
	do
		local sky = V3(0, SKY, 0)
		local a, b = towers[90] + sky + dir(270) * TOWER_R, towers[270] + sky + dir(90) * TOWER_R
		gallery(a, b, 8, 9, { floor = true, rail = true })
		local n = 14
		for _, x in ipairs({ -3.2, 3.2 }) do
			local function at(i)
				local s = i / n * 2 - 1
				return ORIGIN + V3(x, -2 + (SKY - 0.8 + 2) * (1 - s * s), s * 52)
			end
			for i = 0, n - 1 do
				local p, q = at(i), at(i + 1)
				P("BridgeRib", V3(1.2, 1.8, (q - p).Magnitude + 0.5), CFrame.lookAt((p + q) / 2, q), MAT.Metal, GOLD)
			end
		end
	end

	-- THE BOULEVARD (east): a shut gold gate at the cliff, a fountain, an avenue of blossom, a triumphal arch into the hole's walk
	do
		local cf = side(0, 72)
		local gem = GEMS[1]
		wall(cf, V3(-14, 0, 0), V3(14, 0, 0), 0, 24, 6, { { u = 14, w = 12, y1 = 0, y2 = 18 } }, MAT.Limestone, IVORY)
		-- (the wall stands z 0..6, wall() building it to its inside)
		P("ArchAttic", V3(31, 4, 10), cf * CFrame.new(0, 26, 3), MAT.Limestone, IVORY)
		P("ArchBand", V3(31.6, 0.8, 10.6), cf * CFrame.new(0, 24.2, 3), MAT.Metal, GOLD, false)
		for _, x in ipairs({ -11, 11 }) do
			for _, z in ipairs({ -1.2, 7.2 }) do
				up("ArchColumn", 2, 24, (cf * CFrame.new(x, 0, z)).Position, MAT.Limestone, IVORY)
			end
			taper((cf * CFrame.new(x, 28, 3)).Position, 1.4, 7, 5, "spire")
		end
		-- colonnades from the arch to the towers either side of it
		gallery(towers[330] + dir(90) * TOWER_R, (cf * CFrame.new(14, 0, 3)).Position, 8, 12, {})
		gallery(towers[30] + dir(270) * TOWER_R, (cf * CFrame.new(-14, 0, 3)).Position, 8, 12, {})

		fountain(pol(0, 96))
		for _, x in ipairs({ -24, 24 }) do
			for _, apo in ipairs({ 86, 98, 110 }) do
				tree((side(0, apo) * CFrame.new(x, 0, 0)).Position)
			end
			lamp((side(0, 104) * CFrame.new(x * 0.6, 0, 0)).Position)
		end

		local gate = side(0, 118)
		for _, x in ipairs({ -16, 16 }) do
			tower((gate * CFrame.new(x, 0, 0)).Position, 0, 8, 34, {}, false, gem)
		end
		wall(gate, V3(-8, 0, 0), V3(8, 0, 0), 0, 22, 4, { { u = 8, w = 12, y1 = 0, y2 = 16 } }, MAT.Limestone, IVORY)
		P("GateBand", V3(16.6, 1, 4.6), gate * CFrame.new(0, 19, 2), MAT.Metal, GOLD, false)
		for i = -2, 2 do
			up("GateBar", 0.8, 16, (gate * CFrame.new(i * 2.4, 0, 2)).Position, MAT.Metal, GOLD)
		end
		P("GateRail", V3(12, 0.8, 0.8), gate * CFrame.new(0, 6, 2), MAT.Metal, GOLD)
		P("GateRail", V3(12, 0.8, 0.8), gate * CFrame.new(0, 12, 2), MAT.Metal, GOLD)
	end

	-- round the hole's walk
	for i = 0, 5 do
		lamp(pol(i * 60 + 15, 54))
	end

	-- THE ROUTE: the walls that make one way through the ring, and the new country off the rim
	local function at(x, y, z)
		return ORIGIN + V3(x, y, z)
	end
	local function deck(name, cf, x1, x2, z1, z2, top, thick) -- a floor, its top at height top in cf's space
		thick = thick or 0.8
		return P(name, V3(x2 - x1, thick, z2 - z1), cf * CFrame.new((x1 + x2) / 2, top - thick / 2, (z1 + z2) / 2), MAT.Limestone, CREAM)
	end
	local function rail(a, b) -- a balustrade between two points on a floor
		local up3 = V3(0, 1.5, 0)
		P("Rail", V3(0.6, 3, (b - a).Magnitude), CFrame.lookAt((a + b) / 2 + up3, b + up3), MAT.Limestone, IVORY)
		P("RailCap", V3(0.8, 0.25, (b - a).Magnitude), CFrame.lookAt((a + b) / 2 + up3 * 2.08, b + up3 * 2.08), MAT.Metal, GOLD, false)
	end
	local function rails(cf, y, pts) -- rail round cf-space points { x, z }, ...
		for i = 1, #pts - 1 do
			rail((cf * CFrame.new(pts[i][1], y, pts[i][2])).Position, (cf * CFrame.new(pts[i + 1][1], y, pts[i + 1][2])).Position)
		end
	end
	-- a straight stair from landing a to landing b (points on their floors), no rise over 1. sides: which rails (+1 is the right
	-- going from a to b), both if nil
	local function flight(a, b, w, sides)
		local n = math.ceil(math.abs(b.Y - a.Y))
		local run = V3(b.X - a.X, 0, b.Z - a.Z)
		local tread = run.Magnitude / n
		local F = CFrame.lookAt(a, a + run)
		for i = 1, n do
			local y = (b.Y - a.Y) * i / n
			P("Stair", V3(w, 0.8, tread + 0.3), F * CFrame.new(0, y - 0.4, -(i - 0.5) * tread), MAT.Limestone, CREAM)
		end
		local mid = (a + b) / 2
		P("Stringer", V3(w, 0.8, (b - a).Magnitude), CFrame.lookAt(mid, b) * CFrame.new(0, -1.2, 0), MAT.Limestone, IVORY)
		for _, s in ipairs(sides or { -1, 1 }) do
			local o = F.RightVector * s * (w / 2 + 0.3)
			rail(a + o, b + o)
		end
	end
	local function curtain(a, b, h) -- a plain wall across a street, a gilt coping along its top
		local mid = (a + b) / 2
		local F = CFrame.lookAt(mid, b)
		local len = (b - a).Magnitude
		P("Curtain", V3(2, h, len), F * CFrame.new(0, h / 2, 0), MAT.Limestone, IVORY)
		P("CurtainCap", V3(2.5, 0.6, len + 0.4), F * CFrame.new(0, h + 0.3, 0), MAT.Metal, GOLD, false)
		for u = -len / 2 + 2, len / 2 - 2, 7 do
			P("CurtainPier", V3(2.8, h - 1, 1.2), F * CFrame.new(0, (h - 1) / 2, u), MAT.Limestone, CREAM)
		end
	end
	-- a door that opens from one side only (init.server: info.MansionDoors): mid its middle, opener the way to whoever may open it
	local function oneWay(mid, along, w, h, opener, name, col)
		local leaf = Instance.new("Model")
		leaf.Name = "HeightsDoor"
		leaf.Parent = folder
		local F = CFrame.lookAt(mid, mid + opener)
		local main = part({ Name = "Door", Size = V3(w - 0.1, h, 0.7), CFrame = F, Material = MAT.Metal, Color = col or TARNISH, Parent = leaf })
		leaf.PrimaryPart = main
		for y = -h / 2 + 1.2, h / 2 - 1, 3 do
			part({ Name = "DoorBand", Size = V3(w - 0.1, 0.4, 0.9), CFrame = F * CFrame.new(0, y, 0), Material = MAT.Metal, Color = GOLD, CanCollide = false, Parent = leaf })
		end
		local function spot(s)
			return part({ Name = "DoorPrompt", Size = Vector3.one, CFrame = CFrame.new(mid + opener * s * 2.5 - V3(0, h / 2 - 3, 0)), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = folder })
		end
		local hinge = mid - along * (w / 2)
		table.insert(info.MansionDoors, {
			Leaf = leaf,
			Hinge = hinge,
			Sign = V3(0, 1, 0):Cross(along):Dot(opener) < 0 and 1 or -1, -- (away from whoever opens it)
			Normal = opener,
			Prompt = prompt(spot(1), "Open", name, 0.4, 8),
			Blocked = prompt(spot(-1), "Open", name, 0, 8),
			Message = "A shortcut has opened.",
		})
	end

	-- the street shut at the corners: each tower to the near corner of a row of outer halls. (From 45 degrees round the tower
	-- from its garden door, so the door's left clear.)
	for _, c in ipairs({ { 30, 60, 48 }, { 90, 60, -48 }, { 90, 120, 48 }, { 150, 120, -48 }, { 210, 240, 48 }, { 270, 300, 48 }, { 330, 300, -48 } }) do
		local v, rowDeg, x = c[1], c[2], c[3]
		curtain(towers[v] + dir(v + (off(rowDeg, v + 30) < 1 and 45 or -45)) * 8.8, (side(rowDeg, 98) * CFrame.new(x, 0, 0)).Position, 13)
	end
	-- the boulevard shut off from the hole's walk: the colonnades walled on their garden side, the arch's gate home
	local arch = side(0, 72)
	for _, s in ipairs({ -1, 1 }) do
		curtain((arch * CFrame.new(s * 14, 0, 6)).Position, (arch * CFrame.new(s * 36, 0, 6)).Position, 12.4)
	end
	-- the arrival court, the walk's east end, where the Great Stair comes up: walled off from the rest of the walk at 30 degrees
	-- either way. Its way out's the arch (always open); the door here lets you home from the hub, and only from the hub.
	curtain(pol(330, 50.9), pol(330, 67), 13)
	curtain(pol(30, 50.9), pol(30, 55), 13)
	curtain(pol(30, 63), pol(30, 67), 13)
	P("CurtainCap", V3(2, 2, 8.6), CFrame.lookAt(pol(30, 59) + V3(0, 12, 0), pol(30, 67) + V3(0, 12, 0)), MAT.Limestone, IVORY)
	oneWay(pol(30, 59) + V3(0, 5.5, 0), dir(30), 8, 11, dir(120), "Court Door", GOLD)
	oneWay((side(180, 72) * CFrame.new(0, 5.5, -13.4)).Position, side(180, 72).RightVector, 8, 11, -side(180, 72).LookVector, "Palace Door", GOLD)
	-- the top of the 90 tower, from the 30's gallery: a way back to the bridge, once you've come round
	oneWay(towers[90] + dir(330) * 8.4 + V3(0, SKY + 4, 0), dir(60), 5.2, 8, dir(330), "Gallery Door")

	-- the bonfire, inside the shut gate
	local fire = pol(0, 111)
	local rest = CFrame.lookAt(pol(0, 115.5) + V3(0, 3.2, 0), fire + V3(0, 3.2, 0))
	if k.bonfire then
		k.bonfire(fire, rest, "The Gilded Gate")
	end
	info.HeightsDev = rest

	-- THE ALMONRY, on the cliff at 300 degrees: two long halls over a light-well, a third under the far one. In from the 270
	-- belvedere, along the front hall, over the well, back along the rear hall, out and down a stair on its back wall, the whole
	-- length of the lower hall, up a stair on its end wall into the end room, and out to the 330 belvedere.
	local Q = side(300, 170) -- (x -62..60 along, z -20..20 out; the belvederes' bridges come in at x = +-56)
	local gem = C3(150, 40, 90)
	local Q31, Q19 = Q * CFrame.new(0, 30, 0), Q * CFrame.new(0, 18, 0)
	terrain:FillBlock(Q * CFrame.new(0, 40, 0), V3(170, 150, 90), Enum.Material.Air)
	-- (a spur of the mountain under it: a shallow bed under the plinth, a boss under each corner turret and the buttresses,
	-- nothing lower than 54 down so the regions below keep their sky)
	local spur = { { 66, -34, 24, 14 }, { 66, -34, -24, 14 }, { -66, -34, 24, 14 }, { -66, -34, -24, 14 }, { 56, -44, -43, 14 }, { -56, -44, -43, 14 } }
	for x = -60, 60, 24 do
		table.insert(spur, { x, -36, -10, 18 })
		table.insert(spur, { x, -36, 10, 18 })
	end
	for _, b in ipairs(spur) do
		terrain:FillBall((Q * CFrame.new(b[1], b[2], b[3])).Position, b[4], Enum.Material.Rock)
	end
	P("Plinth", V3(122, 48, 40), Q * CFrame.new(-1, -6, 0), MAT.Limestone, IVORY)
	P("Plinth", V3(122, 12, 12), Q * CFrame.new(-1, 24, -14), MAT.Limestone, IVORY) -- (under the front halls)
	P("Plinth", V3(1, 13, 16), Q * CFrame.new(-61.5, 24.5, 0), MAT.Limestone, IVORY) -- (the well's ends)
	P("Plinth", V3(1, 13, 16), Q * CFrame.new(59.5, 24.5, 0), MAT.Limestone, IVORY)
	P("Lawn", V3(120, 0.2, 16), Q * CFrame.new(-1, 18.1, 0), MAT.Grass, LEAF, false)
	tree((Q * CFrame.new(-8, 18, 0)).Position)
	tree((Q * CFrame.new(34, 18, 0)).Position)
	fountain((Q * CFrame.new(12, 18, 0)).Position)
	hall(Q31, -36, 60, -20, -8, 14, "gable", { front = { "d", u = 92 }, right = { "w" }, back = { "d", u = 91 }, left = { "w" } }, gem)
	gallery((Q31 * CFrame.new(-31, 1, -8)).Position, (Q31 * CFrame.new(-31, 1, 8)).Position, 8, 9, { floor = true, rail = true })
	hall(Q31, -36, 60, 8, 20, 14, "gable", { front = { "d", u = 5 }, right = { "w" }, back = { "d", u = 8 }, left = { "w" } }, gem)
	-- down the back wall to the lower hall
	deck("Landing", Q, 44, 60, 20, 27, 31)
	rails(Q, 31, { { 44, 27 }, { 60, 27 }, { 60, 20 } })
	flight((Q * CFrame.new(44, 31, 24)).Position, (Q * CFrame.new(25, 19, 24)).Position, 6)
	deck("Landing", Q, 19, 25, 20, 27, 19)
	rails(Q, 19, { { 25, 27 }, { 19, 27 }, { 19, 20 } })
	hall(Q19, -62, 60, 8, 20, 11, nil, { front = { "w" }, right = { "w" }, back = { "d", u = 38 }, left = { "d" } }, gem)
	-- up the end wall to the end room (shut off from the front hall: that's the whole point of the walk round)
	deck("Landing", Q, -68, -62, 13, 18.5, 19)
	rails(Q, 19, { { -68, 13 }, { -68, 18.5 }, { -62, 18.5 } })
	flight((Q * CFrame.new(-65, 19, 13)).Position, (Q * CFrame.new(-65, 31, -6)).Position, 6, { -1 })
	deck("Landing", Q, -68, -62, -18, -6, 31)
	rails(Q, 31, { { -68, -6 }, { -68, -18 }, { -62, -18 } })
	hall(Q31, -62, -40, -20, -8, 14, "gable", { front = { "d", u = 6 }, right = { "w" }, back = { "w" }, left = { "d" } }, gem)
	-- corner turrets for its outline, buttresses under its bridges, the bridges
	for _, c in ipairs({ { -69, -27 }, { 69, -27 }, { -69, 27 }, { 69, 27 } }) do
		tower((Q * CFrame.new(c[1], -28, c[2])).Position, 300, 7, 78, {}, false, gem)
	end
	for _, b in ipairs({ { 56, 118 }, { 56, 136 }, { -56, 118 }, { -56, 136 } }) do
		up("Buttress", 5, 69, (side(300, b[2]) * CFrame.new(b[1], -38.5, 0)).Position, MAT.Limestone, IVORY)
	end
	local sky = V3(0, SKY, 0)
	gallery(pol(270, 112) + dir(300) * 7 + sky, (Q * CFrame.new(56, SKY, -20)).Position, 6, 9, { floor = true, rail = true })
	gallery((Q * CFrame.new(-56, SKY, -20)).Position, pol(330, 112) + dir(300) * 7 + sky, 6, 9, { floor = true, rail = true })

	-- SHORTCUT: THE LADDER, lying along the 330 belvedere with its foot at the rail's gap over the boulevard
	local ladder
	do
		local b, e = pol(330, 112), dir(330)
		local lie, LEN = -e, SKY + 1
		local psi = math.atan2(lie.X, lie.Z)
		local truss = Instance.new("TrussPart")
		truss.Name = "HeightsLadder"
		truss.Size = V3(2, LEN, 2)
		truss.Anchored, truss.Transparency = true, 1
		truss.CanCollide, truss.CanQuery = false, false
		local down = CFrame.new(b + e * 9 + V3(0, LEN / 2, 0)) * CFrame.Angles(0, psi, 0)
		truss.CFrame = down
		truss.Parent = folder
		local function bit(size, offset, color)
			local p = part({ Name = "LadderWood", Size = size, CFrame = down * offset, Material = MAT.Wood, Color = color, CanCollide = false, CanQuery = false, CanTouch = false, Massless = true, Parent = folder })
			p.Anchored = false
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = truss, p
			w.Parent = p
		end
		for _, x in ipairs({ -0.8, 0.8 }) do
			bit(V3(0.28, LEN, 0.32), CFrame.new(x, 0, 0), C3(84, 62, 42))
		end
		for y = -LEN / 2 + 0.6, LEN / 2 - 0.4, 1 do
			bit(V3(1.65, 0.16, 0.18), CFrame.new(0, y, 0), C3(62, 46, 32))
		end
		truss.CFrame = CFrame.new(b + e * 7.2 + lie * (LEN / 2) + V3(0, SKY + 0.3, 0)) * CFrame.Angles(0, psi, 0) * CFrame.Angles(math.pi / 2, 0, 0)
		local gap = P("LadderGap", V3(8, 4, 0.6), CFrame.lookAt(b + e * 7.3 + V3(0, SKY + 2, 0), b + e * 8 + V3(0, SKY + 2, 0)), MAT.SmoothPlastic, IVORY)
		gap.Transparency, gap.CanQuery = 1, false -- (for good: the ladder's the way off here, not the drop)
		local function spot(pos)
			return part({ Name = "LadderPrompt", Size = Vector3.one, CFrame = CFrame.new(pos), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = folder })
		end
		local function climbPrompt(pos)
			local pp = prompt(spot(pos), "Climb", "Ladder", 0, 6)
			pp.Enabled = false
			return pp
		end
		ladder = {
			Ladder = truss,
			Down = down,
			Swing = 0, -- (it lies square to the drop: its rungs are already along the edge)
			Prompt = prompt(spot(b + e * 5.5 + V3(0, SKY + 1.5, 0)), "Kick down", "Ladder", 0, 7),
			UpPrompt = climbPrompt(b + e * 11 + V3(0, 2.5, 0)),
			DownPrompt = climbPrompt(b + e * 6 + V3(0, SKY + 2, 0)),
			Climb = {
				foot = b + e * 10.6 + V3(0, 3, 0),
				top = b + e * 10.6 + V3(0, SKY + 3.15, 0),
				off = b + e * 5 + V3(0, SKY + 3.15, 0),
				facing = lie,
			},
		}
	end

	-- THE TERRACES, on the cliff at 150 degrees: a garden out on a pilgrims' hall, stairs down to a lower terrace and back in
	-- under the garden, through the hall, and on down to a door in the cliff
	local G = side(TUNNEL_DEG, 1) * CFrame.new(0, 0, -1) -- (on the middle: z is how far out, x along; the tunnel runs down its axis. side(deg, 0) would look at itself)
	local gem2 = C3(170, 100, 30)
	terrain:FillBlock(G * CFrame.new(0, 40, 170), V3(100, 150, 80), Enum.Material.Air)
	-- (three under each plinth reach all its corners; one between them, one at the cliff; nothing lower than 62 down)
	for _, b in ipairs({ { -14, -45, 160, 17 }, { 0, -45, 160, 17 }, { 14, -45, 160, 17 }, { -14, -45, 200, 17 }, { 0, -45, 200, 17 }, { 14, -45, 200, 17 }, { 0, -42, 180, 12 }, { 0, -42, 140, 20 } }) do
		terrain:FillBall((G * CFrame.new(b[1], b[2], b[3])).Position, b[4], Enum.Material.Rock)
	end
	gallery(pol(150, 112) + dir(150) * 7 + sky, (G * CFrame.new(0, SKY, 149)).Position, 6, 9, { floor = true, rail = true })
	-- the upper terrace, the hall's roof
	P("Plinth", V3(48, 38, 20), G * CFrame.new(0, -21, 160), MAT.Limestone, IVORY)
	hall(G * CFrame.new(0, -2, 0), -24, 24, 150, 170, 31, nil, { front = { "d" }, right = { "w" }, back = { "d", u = 38 }, left = { "w" } }, gem2)
	deck("Terrace", G, -25, 25, 149, 171, SKY)
	rails(G, SKY, { { -3, 149 }, { -25, 149 }, { -25, 171 }, { 11, 171 } })
	rails(G, SKY, { { 17, 171 }, { 25, 171 }, { 25, 149 }, { 3, 149 } })
	P("Lawn", V3(16, 0.2, 18), G * CFrame.new(-15, SKY + 0.1, 160), MAT.Grass, LEAF, false)
	fountain((G * CFrame.new(-12, SKY, 160)).Position)
	lamp((G * CFrame.new(21, SKY, 153)).Position)
	-- out and down to the lower terrace, and back in under the upper one
	flight((G * CFrame.new(14, SKY, 171)).Position, (G * CFrame.new(14, 15, 192)).Position, 6)
	P("Plinth", V3(48, 55, 16), G * CFrame.new(0, -12.5, 200), MAT.Limestone, IVORY)
	rails(G, 15, { { 11, 192 }, { -11, 192 } })
	rails(G, 15, { { 17, 192 }, { 24, 192 }, { 24, 208 }, { -24, 208 }, { -24, 192 }, { -17, 192 } })
	P("Lawn", V3(44, 0.2, 5), G * CFrame.new(0, 15.1, 204.5), MAT.Grass, LEAF, false)
	for _, x in ipairs({ -16, 0, 16 }) do
		tree((G * CFrame.new(x, 15, 205)).Position)
	end
	flight((G * CFrame.new(-14, 15, 192)).Position, (G * CFrame.new(-14, -1, 170)).Position, 6)
	-- out the hall's front, under the bridge, to the door in the cliff
	flight((G * CFrame.new(0, -1, 150)).Position, (G * CFrame.new(0, -15, 131)).Position, 6)

	-- THE TUNNEL under the land, from the cliff to the hole
	terrain:FillBlock(G * CFrame.new(0, -10, 87), V3(12, 14, 84), Enum.Material.Air)
	deck("TunnelFloor", G, -3, 3, 48.5, 131, -15)
	for _, s in ipairs({ -1, 1 }) do
		P("TunnelWall", V3(0.8, 10, 79), G * CFrame.new(s * 3.4, -10, 87.5), MAT.Limestone, CREAM)
	end
	P("TunnelRoof", V3(7.6, 0.8, 79), G * CFrame.new(0, -4.6, 87.5), MAT.Limestone, IVORY)
	P("Lintel", V3(9, 4.2, 4), G * CFrame.new(0, -2.9, 127), MAT.Limestone, IVORY)
	for _, x in ipairs({ -4, 4 }) do
		P("TunnelJamb", V3(1.2, 10, 1.2), G * CFrame.new(x, -10, 127.4), MAT.Metal, GOLD)
	end
	for z = 52, 124, 12 do
		for _, s in ipairs({ -1, 1 }) do
			P("TunnelRib", V3(0.4, 10, 1), G * CFrame.new(s * 2.85, -10, z), MAT.Metal, GOLD)
		end
		P("TunnelRib", V3(6, 0.4, 1), G * CFrame.new(0, -5.2, z), MAT.Metal, GOLD)
		if (z - 52) % 24 == 0 then
			glow((G * CFrame.new(0, -7.2, z + 6)).Position, 22, 1)
		end
	end

	-- THE STAIR DOWN THE HOLE, on the wall under the land's overhang, from the tunnel's mouth round to the lift
	deck("Landing", G, -6, 6, 40, 48.5, -15)
	rails(G, -15, { { -6, 40 }, { 6, 40 }, { 6, 48.5 } })
	local function arcBit(deg, r, y)
		return CFrame.lookAt(pol(deg, r) + V3(0, y, 0), pol(deg, r) + dir(deg) + V3(0, y, 0))
	end
	local STEPS, D0, DSTEP = 24, TUNNEL_DEG + 8, 1.6
	for i = 1, STEPS do
		local deg, y = D0 + (i - 1) * DSTEP, -15 - i
		P("Stair", V3(1.9, 0.8, 8.5), arcBit(deg, 43.5, y - 0.4), MAT.Limestone, CREAM)
		for _, r in ipairs({ 39.3, 47.7 }) do
			P("Rail", V3(1.9, 3, 0.5), arcBit(deg, r, y + 1.5), MAT.Limestone, IVORY)
		end
		if i % 4 == 0 and y < -21 then -- (hung from the overhang, its underside 20 down)
			P("Hanger", V3(0.35, -20 - y, 0.35), arcBit(deg, 47.7, (y - 20) / 2), MAT.Metal, GOLD, false)
		end
	end
	local LOW = -15 - STEPS
	P("Landing", V3(5.2, 0.8, 8.5), arcBit(195.7, 43.5, LOW - 0.4), MAT.Limestone, CREAM)
	P("Rail", V3(5.2, 3, 0.5), arcBit(195.7, 39.3, LOW + 1.5), MAT.Limestone, IVORY)
	P("Rail", V3(5.2, 3, 0.5), arcBit(195.7, 47.7, LOW + 1.5), MAT.Limestone, IVORY)

	-- SHORTCUT: THE LIFT in the hole, up to the walk round it. (It starts at the top: you call it from the bottom, the first time.)
	local lift
	do
		local base = pol(LIFT_DEG, 44.75)
		local top = CFrame.lookAt(base, base + dir(LIFT_DEG))
		lift = { Top = top, Bottom = top - V3(0, top.Y - (ORIGIN.Y + LOW), 0), At = "Top", Parts = {}, HalfX = 3.4, HalfZ = 3.7, Speed = 8 }
		local function bit(name, size, rel, mat, col, collide)
			local p = P(name, size, top * rel, mat, col, collide)
			table.insert(lift.Parts, { p, rel })
			return p
		end
		lift.Deck = bit("LiftDeck", V3(7, 0.8, 7.5), CFrame.new(0, -0.4, 0), MAT.Metal, TARNISH)
		bit("LiftGilt", V3(7.2, 0.3, 7.7), CFrame.new(0, -0.95, 0), MAT.Metal, GOLD, false)
		bit("LiftRail", V3(7, 3, 0.5), CFrame.new(0, 1.5, 3.5), MAT.Limestone, IVORY) -- (on the hole side)
		bit("LiftRail", V3(0.5, 3, 7.5), CFrame.new(3.5, 1.5, 0), MAT.Limestone, IVORY) -- (the side away from the stair, which comes up from the lower degrees)
		lift.Prompt = prompt(lift.Deck, "Ride", "Lift", 0.6, 8)
		local function lever(pos)
			up("LeverPost", 1, 3.6, pos, MAT.Metal, TARNISH)
			local h = P("LeverHandle", V3(0.3, 2.2, 0.3), CFrame.new(pos + V3(0, 4.4, 0)) * CFrame.Angles(0, 0, 0.5), MAT.Metal, GOLD, false)
			return prompt(h, "Pull", "Lever", 0.4, 7)
		end
		lift.CallBottom = lever(pol(195.7, 46.5) + V3(0, LOW, 0))
		lift.CallTop = lever(pol(195, 53))
	end

	info.Heights = { Ladder = ladder, Lift = lift, Folder = folder }

	-- THE GREAT STAIR, out of sight until all three keys come to the sand (init.server plays its descent; the client carries it):
	-- two turns up through the hole from the Silver Knight's arena, him kneeling in the middle of it, to the arrival court's
	-- edge. One rigid helix: it comes down by screwing along its own path, so it never passes through anything it won't end in.
	do
		local A = info.Champion
		local C = V3(ORIGIN.X, A.Centre.Y, ORIGIN.Z)
		local H = ORIGIN.Y - C.Y
		local TURNS, R1, R2, END_DEG = 2, 18, 34, -19 -- (ends just short of due east, climbing into the deck)
		local N = math.ceil(H / 0.8)
		local function degOf(i)
			return END_DEG + (i - N) * TURNS * 360 / N
		end
		local function onStep(i, r, dy)
			local deg = degOf(i)
			return C + dir(deg) * r + V3(0, H * i / N + (dy or 0), 0), deg
		end
		local home = folder
		local steps = Instance.new("Folder")
		steps.Name = "GreatStair"
		steps.Parent = home
		local deckFolder = Instance.new("Folder")
		deckFolder.Name = "GreatStairDeck"
		deckFolder.Parent = home
		folder = steps
		local RM = (R1 + R2) / 2
		for i = 1, N do
			local m, deg = onStep(i, RM, -1.5)
			local F = CFrame.lookAt(m, m + dir(deg))
			P("Stair", V3(3.6, 3, R2 - R1), F, MAT.Limestone, CREAM)
			P("StairEdge", V3(3.6, 3.2, 0.6), F * CFrame.new(0, -0.05, -(R2 - R1) / 2 - 0.2), MAT.Metal, GOLD)
			if i % 6 == 0 then
				P("StairRib", V3(1.2, 5, R2 - R1 + 1), F * CFrame.new(0, -3.8, 0), MAT.Metal, GOLD, false)
			end
		end
		for i = 1, N - 2, 2 do
			for _, r in ipairs({ R1 - 0.3, R2 + 0.5 }) do
				rail((onStep(i, r)), (onStep(i + 2, r)))
			end
		end
		for i = 12, N, 12 do
			local foot0 = onStep(i, R2 + 0.5)
			up("StairPost", 1.4, 8, foot0, MAT.Limestone, IVORY)
			taper(foot0 + V3(0, 8, 0), 1, 4, 3, "spire")
			glow(foot0 + V3(0, 9, 0) + (C - foot0) * V3(1, 0, 1) * 0.03, 26, 1.2)
		end
		-- the deck at its head, and the bridge to the parapet (these come in last, where they stand)
		folder = deckFolder
		P("StairDeck", V3(31.5, 0.8, 16), CFrame.new(at(33.75, -0.35, 0)), MAT.Limestone, CREAM)
		P("Runner", V3(31.5, 0.1, 4), CFrame.new(at(33.75, 0.1, 0)), MAT.Fabric, RUG, false)
		rail(at(18, 0, -8), at(18, 0, 8))
		rail(at(18, 0, 8), at(49.5, 0, 8))
		rail(at(34, 0, -8), at(49.5, 0, -8))
		folder = home
		local gate = {}
		for _, p in ipairs(home:GetChildren()) do
			if p.Name == "StairParapet" then
				table.insert(gate, p)
			end
		end
		for _, f in ipairs({ steps, deckFolder }) do
			for _, p in ipairs(f:GetDescendants()) do
				if p:IsA("BasePart") then
					p:SetAttribute("Collide", p.CanCollide)
					p.Transparency, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = 1, false, false, false, false
				elseif p:IsA("Light") then
					p.Enabled = false
				end
			end
		end
		local way = {}
		for i = 2, N, 7 do
			table.insert(way, (onStep(i, RM)))
		end
		table.insert(way, (onStep(N, RM)))
		table.insert(way, at(26, 0, 0))
		table.insert(way, at(48, 0, 0))
		table.insert(way, pol(0, 56))
		table.insert(way, pol(0, 69))
		table.insert(way, pol(0, 80))
		info.Heights.Stair = { Steps = steps, Deck = deckFolder, Gate = gate, Centre = C, Height = H, Turns = TURNS, Plane = ORIGIN.Y + 1, Way = way }
	end

	-- THE GILDED BALLROOM, floating on its own rock behind the palace and well above it: a sixteen-sided rotunda under a gold dome, a crown
	-- of spires round its top. The only way up is the end of the route: the door behind the throne in the palace's great hall, out on
	-- to a stair of floating steps that goes straight out over the rim and then curls up round under the rock to the Ballroom's door.
	-- The old king's in there (Characters/GildedKing), and the dancers are statues (Map.Heights.Ballroom.Dancers).
	local ballroom
	do
		local PAL = side(180, 72) -- (the palace's frame: +Z out the back, away from the hole)
		local FY, RB, RS, H = 78, 40, 54, 34 -- floor (from the paving), the walls' radius, the stair's radius round it, the walls' height
		local N, TREAD, W, L1 = 86, 2.2, 7, 40
		local outDir = (PAL * CFrame.new(0, 0, 1)).Position - PAL.Position -- (out of the back door, along +Z)
		-- the island stands off to one side of the straight run, a stair's radius away, so the run meets the curl round it head on
		local J = (PAL * CFrame.new(0, 0, 56.6 + L1)).Position
		local Cf = J - PAL.RightVector * RS -- (round towards 210 degrees: the Terraces are off the rim at 150)
		local C = Cf + V3(0, FY, 0) -- (on the floor, in the middle)
		-- out of the back door: a terrace to the rim, rails along it, and across the parapet's gap either side
		deck("BackTerrace", PAL, -8, 8, 46, 56.6, 1)
		rails(PAL, 1, { { -8, 46.2 }, { -8, 56.6 } })
		rails(PAL, 1, { { 8, 46.2 }, { 8, 56.6 } })
		rails(PAL, 0, { { -8, 56.3 }, { -12.5, 56.3 } })
		rails(PAL, 0, { { 8, 56.3 }, { 12.5, 56.3 } })
		-- THE STAIR: 86 floating steps, each a gold keel under it, rails every other step, a hanging lamp every eighth
		local RISE = (FY - 1) / N
		local th0 = math.atan2((J - Cf).Z, (J - Cf).X) -- (where the run meets the circle)
		local sgn = V3(-math.sin(th0), 0, math.cos(th0)):Dot(outDir) > 0 and 1 or -1 -- (round the way the run's already going)
		local ARC = (N * TREAD - L1) / RS
		local function along(s) -- a point on the stair's line (on the paving's level) and the way it's going
			if s <= L1 then
				return (PAL * CFrame.new(0, 0, 56.6 + s)).Position, outDir
			end
			local th = th0 + sgn * (s - L1) / RS
			return Cf + V3(math.cos(th), 0, math.sin(th)) * RS, V3(-math.sin(th), 0, math.cos(th)) * sgn
		end
		local edges = {}
		for i = 1, N do
			local p, t = along((i - 0.5) * TREAD)
			local y = 1 + i * RISE
			local F = CFrame.lookAt(p + V3(0, y - 0.4, 0), p + V3(0, y - 0.4, 0) + t)
			P("Stair", V3(W, 0.8, TREAD + 0.45), F, MAT.Limestone, CREAM)
			P("StairKeel", V3(1.4, 1.6, TREAD + 0.2), F * CFrame.new(0, -1.15, 0), MAT.Metal, GOLD, false)
			P("StairEdge", V3(W + 0.2, 0.3, 0.3), F * CFrame.new(0, -0.3, -(TREAD + 0.45) / 2), MAT.Metal, GOLD, false)
			edges[i] = { (F * CFrame.new(-W / 2 - 0.3, 0.4, 0)).Position, (F * CFrame.new(W / 2 + 0.3, 0.4, 0)).Position }
			if i % 8 == 4 then
				P("LampChain", V3(0.25, 5, 0.25), F * CFrame.new(0, -4.2, 0), MAT.Metal, GOLD, false)
				glow((F * CFrame.new(0, -7.6, 0)).Position, 26, 1.1)
			end
		end
		for i = 1, N - 2, 2 do
			rail(edges[i][1], edges[i + 2][1])
			rail(edges[i][2], edges[i + 2][2])
		end
		rail(edges[N - 1][1], edges[N][1])
		rail(edges[N - 1][2], edges[N][2])
		-- the landing at its head, in to the door
		local thE = th0 + sgn * ARC
		local inward = -V3(math.cos(thE), 0, math.sin(thE))
		local doorBear = math.deg(math.atan2(-inward.Z, -inward.X)) -- (from the middle, out to the door)
		local landC = Cf + (-inward) * ((RS + RB) / 2 + 1.5) + V3(0, FY - 0.4, 0)
		local LAND = CFrame.lookAt(landC, landC + inward)
		P("Landing", V3(10, 0.8, RS - RB + 5), LAND, MAT.Limestone, CREAM)
		P("LandingKeel", V3(10.4, 1.4, RS - RB + 5.4), LAND * CFrame.new(0, -1.1, 0), MAT.Metal, GOLD, false)
		for _, sx in ipairs({ -1, 1 }) do
			local a = (LAND * CFrame.new(sx * 5, 0.4, (RS - RB + 5) / 2 - 1.5)).Position
			local b = (LAND * CFrame.new(sx * 5, 0.4, -(RS - RB + 5) / 2 + 1)).Position
			rail(a, b)
		end

		-- THE ISLAND: rock heaped up under it in a long point, and a few loose boulders drifting round it with lamps on
		for i = 0, 8 do
			terrain:FillCylinder(CFrame.new(Cf + V3(0, FY - 7 - i * 7, 0)), 8, 46 - i * 5, Enum.Material.Rock)
		end
		local rr = Random.new(4040)
		for _ = 1, 10 do
			local a = rr:NextNumber(0, math.pi * 2)
			terrain:FillBall(Cf + V3(math.cos(a) * rr:NextNumber(18, 34), FY - rr:NextNumber(14, 50), math.sin(a) * rr:NextNumber(18, 34)), rr:NextNumber(9, 14), Enum.Material.Rock)
		end
		terrain:FillBall(Cf + V3(0, FY - 72, 0), 9, Enum.Material.Rock)
		for k = 0, 5 do
			local a = k * math.pi / 3 + 0.4
			local at0 = Cf + V3(math.cos(a), 0, math.sin(a)) * rr:NextNumber(78, 96) + V3(0, FY - rr:NextNumber(10, 40), 0)
			terrain:FillBall(at0, rr:NextNumber(5, 8), Enum.Material.Rock)
			up("DriftPost", 0.7, 6, at0 + V3(0, 4, 0), MAT.Metal, GOLD)
			glow(at0 + V3(0, 11, 0), 24, 1)
		end
		-- the plinth it all stands on, its gilt skirt, gold chains hung under it with lamps on the ends
		up("Plinth", 2 * (RB + 3), 6, C - V3(0, 6, 0), MAT.Limestone, IVORY)
		ring(C, RB + 2.4, RB + 3.4, -6.5, -0.2, 32, MAT.Metal, GOLD, "PlinthBand")
		for k = 0, 7 do
			local a = math.rad(k * 45 + 22.5)
			local top = C + V3(math.cos(a), 0, math.sin(a)) * (RB + 2.2) - V3(0, 6.5, 0)
			P("HangChain", V3(0.4, 22, 0.4), CFrame.new(top - V3(0, 11, 0)), MAT.Metal, GOLD, false)
			glow(top - V3(0, 23, 0), 28, 1.2)
		end
		-- gold motes falling off it the whole time
		local mote = P("Motes", V3(2 * RB, 1, 2 * RB), CFrame.new(C - V3(0, 7, 0)), MAT.SmoothPlastic, IVORY, false)
		mote.Transparency, mote.CanQuery, mote.CanTouch, mote.CastShadow = 1, false, false, false
		local em = Instance.new("ParticleEmitter")
		em.Shape, em.ShapeStyle = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume
		em.Color = ColorSequence.new(LIGHT_GOLD)
		em.LightEmission, em.Size = 1, NumberSequence.new(0.25, 0.05)
		em.Lifetime, em.Rate, em.Speed = NumberRange.new(5, 8), 18, NumberRange.new(1, 2)
		em.EmissionDirection, em.Acceleration = Enum.NormalId.Bottom, V3(0, -2, 0)
		em.Parent = mote

		-- THE FLOOR: inlaid marble, rings of ivory and rose, a gold sun in the middle; a crimson runner door to dais
		for i, q in ipairs({ { 1, 8 }, { 8, 15 }, { 15, 23 }, { 23, 31 }, { 31, RB + 0.5 } }) do
			local n = 8 + i * 4
			local function even(deg)
				return math.floor((deg + 0.01) / (360 / n)) % 2 == 0
			end
			ring(C, q[1], q[2], -0.6, 0, n, MAT.Marble, i % 2 == 0 and IVORY or C3(226, 210, 206), "BallFloor", 0, even)
			ring(C, q[1], q[2], -0.6, 0, n, MAT.Marble, i % 2 == 0 and C3(176, 120, 132) or IVORY, "BallFloor", 0, function(deg)
				return not even(deg)
			end)
			ring(C, q[2] - 0.15, q[2] + 0.15, -0.58, 0.02, 48, MAT.Metal, GOLD, "FloorBand")
		end
		up("FloorSun", 2.2, 0.06, C, MAT.Metal, GOLD, false)
		up("FloorSunDisc", 3.4, 0.04, C, MAT.Metal, LIGHT_GOLD, false)
		-- THE WALLS: sixteen bays round, a window and a mirror by turns, the door's bay facing the stair and the great window opposite
		local BAY = 2 * RB * math.tan(math.pi / 16)
		local bays = {}
		for k = 0, 15 do
			local deg = doorBear + k * 22.5
			local out = dir(deg)
			local F = CFrame.lookAt(C + out * (RB + 0.75), C) -- (-Z in, to the middle; the wall's 1.5 thick from here in)
			local Fm = F * CFrame.new(0, 0, -0.75) -- (the wall's middle)
			local cuts, kind
			local mid = BAY / 2 + 0.4 -- (the wall's run from a to b is the bay and a little over)
			if k == 0 then
				kind, cuts = "door", { { u = mid, w = 9, y1 = 0, y2 = 13 } }
			elseif k == 8 then
				kind, cuts = "great", { { u = mid, w = 10, y1 = 3, y2 = 28 } }
			elseif k % 2 == 1 then
				kind, cuts = "window", { { u = mid, w = 6.5, y1 = 5, y2 = 24 } }
			else
				kind, cuts = "mirror", {}
			end
			wall(F, V3(BAY / 2 + 0.4, 0, 0), V3(-BAY / 2 - 0.4, 0, 0), 0, H, 1.5, cuts, MAT.Limestone, IVORY)
			bays[k] = { F = F, deg = deg, kind = kind }
			if kind == "window" or kind == "great" then
				local c = cuts[1]
				local gem = kind == "great" and C3(240, 210, 140) or GEMS[(k // 2) % 4 + 1]
				P("Window", V3(c.w, c.y2 - c.y1, 0.4), Fm * CFrame.new(0, (c.y1 + c.y2) / 2, 0), MAT.Glass, gem)
				part({ Name = "WindowHead", Shape = Enum.PartType.Cylinder, Size = V3(1.5, c.w, c.w), CFrame = Fm * CFrame.new(0, c.y2, 0) * CFrame.Angles(0, math.pi / 2, 0), Material = MAT.Glass, Color = gem, Parent = folder })
				for _, sx in ipairs({ -1, 1 }) do
					P("WindowFrame", V3(0.5, c.y2 - c.y1, 2), Fm * CFrame.new(sx * (c.w / 2 + 0.25), (c.y1 + c.y2) / 2, 0), MAT.Metal, GOLD, false)
				end
				P("WindowSill", V3(c.w + 1.4, 0.5, 2.2), Fm * CFrame.new(0, c.y1 - 0.25, 0), MAT.Metal, GOLD, false)
				if kind == "great" then -- (a rose window over it)
					part({ Name = "RoseWindow", Shape = Enum.PartType.Cylinder, Size = V3(1.6, 6, 6), CFrame = Fm * CFrame.new(0, c.y2 + 2.4, 0) * CFrame.Angles(0, math.pi / 2, 0), Material = MAT.Glass, Color = GEMS[2], Parent = folder })
				end
			elseif kind == "mirror" then
				local m = P("Mirror", V3(7, 19, 0.2), Fm * CFrame.new(0, 14.5, -0.85), MAT.Glass, C3(228, 236, 240), false)
				m.Reflectance = 0.55
				P("MirrorFrame", V3(8, 20, 0.15), Fm * CFrame.new(0, 14.5, -0.78), MAT.Metal, GOLD, false)
				P("MirrorCrest", V3(3, 1.6, 0.4), Fm * CFrame.new(0, 25.2, -0.85), MAT.Metal, LIGHT_GOLD, false)
			elseif kind == "door" then
				for _, sx in ipairs({ -1, 1 }) do
					P("DoorFrame", V3(0.8, 13, 2.2), Fm * CFrame.new(sx * 4.9, 6.5, 0), MAT.Metal, GOLD)
				end
				P("DoorFrame", V3(10.6, 1.2, 2.2), Fm * CFrame.new(0, 13.6, 0), MAT.Metal, GOLD, false)
				part({ Name = "Rosette", Shape = Enum.PartType.Cylinder, Size = V3(1.6, 4, 4), CFrame = Fm * CFrame.new(0, 17, 0) * CFrame.Angles(0, math.pi / 2, 0), Material = MAT.Glass, Color = GEMS[1], Parent = folder })
			end
			-- the pier between this bay and the next: a gilt pilaster in, a buttress out with a spire on it (the crown round its top)
			local pier = dir(deg + 11.25)
			up("BallPilaster", 1.8, H - 2, C + pier * (RB - 0.9), MAT.Limestone, CREAM)
			P("BallPilasterCap", V3(2.6, 1, 2.6), CFrame.new(C + pier * (RB - 0.9) + V3(0, H - 1.5, 0)), MAT.Metal, GOLD, false)
			local bm = C + pier * (RB + 2.6)
			P("Buttress", V3(2.6, H + 6, 3.6), CFrame.lookAt(bm + V3(0, (H + 6) / 2 - 6, 0), bm + V3(0, (H + 6) / 2 - 6, 0) + pier), MAT.Limestone, IVORY)
			taper(bm + V3(0, H, 0), 1.8, 12, 6, "spire", 3)
			glow(C + pier * (RB - 2.4) + V3(0, 12, 0), 20, 0.9)
		end
		ring(C, RB - 1.2, RB + 2.6, H, H + 1.6, 32, MAT.Limestone, IVORY, "BallCornice")
		ring(C, RB - 0.4, RB + 2.8, H + 1.6, H + 2.3, 32, MAT.Metal, GOLD, "BallCorniceGilt")
		-- the gallery round the walls at mid-height (looked at, not walked: no stair up), and its colonnade
		ring(C, 33.6, RB - 0.2, 16.4, 17.2, 32, MAT.Limestone, CREAM, "GalleryDeck")
		ring(C, 33.6, 34.3, 17.2, 19.8, 32, MAT.Limestone, IVORY, "GalleryRail")
		ring(C, 33.5, 34.4, 19.8, 20.2, 32, MAT.Metal, GOLD, "GalleryRailCap")
		for k = 0, 15 do
			local p = C + dir(doorBear + k * 22.5 + 11.25) * 33.95
			up("GalleryColumn", 1.3, 16.4, p, MAT.Limestone, IVORY)
			P("GalleryColumnCap", V3(2, 0.6, 2), CFrame.new(p + V3(0, 16.1, 0)), MAT.Metal, GOLD, false)
		end
		-- THE DOME, and a lantern on it; the great chandelier hung from its eye
		taper(C + V3(0, H + 2.3, 0), RB + 1.5, 30, 22, "dome", nil)
		local lan = C + V3(0, H + 2.3 + 27, 0)
		up("BallLantern", 8, 6, lan, MAT.Limestone, IVORY)
		for i = 0, 7 do
			up("BallLanternColumn", 0.8, 6, lan + dir(i * 45) * 4.2, MAT.Limestone, CREAM)
		end
		taper(lan + V3(0, 6, 0), 4.6, 14, 8, "spire", 7)
		local chTop = C + V3(0, H + 14, 0)
		P("ChandelierChain", V3(0.6, 18, 0.6), CFrame.new(chTop - V3(0, 9, 0)), MAT.Metal, GOLD, false)
		for t, q in ipairs({ { 9, -16 }, { 6.5, -13 }, { 3.6, -10 } }) do
			local c = chTop + V3(0, q[2], 0)
			ring(c, q[1] - 0.3, q[1] + 0.3, -0.25, 0.25, 24, MAT.Metal, GOLD, "ChandelierHoop")
			for i = 0, 11 + (3 - t) * 4 do
				local a = i / (12 + (3 - t) * 4) * 360
				local cp = c + dir(a) * q[1]
				P("ChandelierCandle", V3(0.35, 1.2, 0.35), CFrame.new(cp + V3(0, 0.85, 0)), MAT.SmoothPlastic, IVORY, false)
				P("ChandelierFlame", V3(0.3, 0.55, 0.3), CFrame.new(cp + V3(0, 1.75, 0)), MAT.Neon, C3(255, 214, 140), false)
				P("ChandelierDrop", V3(0.3, 0.9, 0.3), CFrame.new(cp - V3(0, 0.9, 0)), MAT.Glass, C3(230, 240, 246), false)
			end
		end
		local hub = ball("ChandelierHub", 3.2, chTop - V3(0, 17, 0), MAT.Metal, GOLD)
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = C3(255, 228, 180), 60, 1.6
		l.Parent = hub
		-- THE DAIS under the great window: three steps up, the throne, and room in front of it for its king
		local kingIn = -dir(doorBear + 180) -- (from the window, in to the middle)
		local dc = C + dir(doorBear + 180) * (RB - 6)
		local DF = CFrame.lookAt(dc, dc + kingIn)
		for s, q in ipairs({ { 18, 10 }, { 14, 8 }, { 10, 6 } }) do
			P("Dais", V3(q[1], 0.7, q[2]), DF * CFrame.new(0, s * 0.7 - 0.35, (10 - q[2]) / 2), MAT.Marble, IVORY)
			P("DaisEdge", V3(q[1] + 0.1, 0.12, 0.12), DF * CFrame.new(0, s * 0.7, -q[2] / 2 + (10 - q[2]) / 2), MAT.Metal, GOLD, false)
		end
		P("Throne", V3(5, 2.4, 4), DF * CFrame.new(0, 2.1 + 1.2, 2.2), MAT.Metal, GOLD)
		P("ThroneBack", V3(5.4, 12, 1), DF * CFrame.new(0, 2.1 + 6, 4.2), MAT.Metal, GOLD)
		part({ Name = "ThroneSun", Shape = Enum.PartType.Cylinder, Size = V3(0.6, 5, 5), CFrame = DF * CFrame.new(0, 2.1 + 12.5, 4.2) * CFrame.Angles(0, math.pi / 2, 0), Material = MAT.Metal, Color = LIGHT_GOLD, Parent = folder })
		local kingFoot = DF * CFrame.new(0, 2.1, -2.2) -- (before the throne, looking down the room)
		P("Runner", V3(4, 0.1, 2 * RB - 18), CFrame.lookAt(C + V3(0, 0.06, 0), C + V3(0, 0.06, 0) + kingIn) * CFrame.new(0, 0, -2), MAT.Fabric, RUG, false)
		-- where the dancers stand: couples round the floor, each pair facing, frozen in the middle of the turn (GildedKing puts them)
		local dancers = {}
		for k = 0, 5 do
			local a = doorBear + 30 + k * 60
			local m = C + dir(a) * (k % 2 == 0 and 17 or 25)
			local across = dir(a + 90)
			table.insert(dancers, { Lady = CFrame.lookAt(m - across * 1.6, m + across), Lord = CFrame.lookAt(m + across * 1.6, m - across) })
		end
		ballroom = {
			King = kingFoot, Dancers = dancers, Centre = C,
			Dev = CFrame.lookAt(C + dir(doorBear) * (RB - 6) + V3(0, 3.2, 0), C + V3(0, 3.2, 0)),
			Way = { (PAL * CFrame.new(0, 1, 30)).Position, (PAL * CFrame.new(13, 1, 30)).Position, (PAL * CFrame.new(13, 1, 44.2)).Position, (PAL * CFrame.new(0, 1, 44.2)).Position, (PAL * CFrame.new(0, 1, 50)).Position, (PAL * CFrame.new(0, 1, 56)).Position },
		}
		for i = 2, N, 3 do
			local p = along((i - 0.5) * TREAD)
			table.insert(ballroom.Way, p + V3(0, 1 + i * RISE, 0))
		end
		table.insert(ballroom.Way, (LAND * CFrame.new(0, 0.4, 0)).Position)
		table.insert(ballroom.Way, C + dir(doorBear) * (RB - 3))
		table.insert(ballroom.Way, C)
		ballroom.Zone = { Name = "The Gilded Ballroom", MinX = Cf.X - 64, MaxX = Cf.X + 64, MinZ = Cf.Z - 64, MaxZ = Cf.Z + 64, MinY = C.Y - 14 }
	end
	info.Heights.Ballroom = ballroom

	-- the way through, as waypoints on the floors (M.check walks them; nothing else reads them)
	local function foot(cf, x, y, z)
		return (cf * CFrame.new(x, y, z)).Position
	end
	local function stairWay(pts, v, goingUp) -- round a tower's stair
		local c = towers[v]
		local list = {}
		for i = 1, 24, 2 do
			table.insert(list, c + dir(v + 5 + 15 * i) * 5.2 + V3(0, 1 + 1.25 * i, 0))
		end
		table.insert(list, c + dir(v + 5 + 15 * 24) * 5.2 + V3(0, SKY, 0))
		for i = 1, #list do
			table.insert(pts, list[goingUp and i or #list + 1 - i])
		end
	end
	local function towerSide(v, bearing, y) -- just outside a tower's door
		return towers[v] + dir(v + bearing) * 9.6 + V3(0, y, 0)
	end
	local S60, S300o, S300i, S240, S120i, S120o = side(60, 108), side(300, 108), side(300, 72), side(240, 72), side(120, 72), side(120, 108)
	local palace = side(180, 72)
	local leg1 = {
		pol(0, 115.5), at(107, 0, 6), at(106.5, 0, 14.4), at(104, 0, 24), at(103, 0, 40), at(103.5, 0, 56),
		foot(S60, 52, 0, 0), foot(S60, 46, 1, 0), foot(S60, -46, 1, 0), foot(S60, -52, 0, 0),
		at(5.2, 0, 112), at(3, 0, 100), at(0, 0, 93.5), towers[90] + V3(0, 1, 0),
	}
	stairWay(leg1, 90, true)
	for _, p in ipairs({
		towers[90] + sky, towerSide(90, 180, SKY), towerSide(270, 180, SKY), towers[270] + sky, towerSide(270, 0, SKY),
		pol(270, 112) + sky, pol(270, 112) + dir(300) * 7 + sky, foot(Q, 56, SKY, -20), foot(Q, 56, SKY, -14), foot(Q, -31, SKY, -14),
		foot(Q, -31, SKY, -8), foot(Q, -31, SKY, 8), foot(Q, -31, SKY, 14), foot(Q, 52, SKY, 14), foot(Q, 52, SKY, 22), foot(Q, 44, SKY, 24),
		foot(Q, 25, 19, 24), foot(Q, 22, 19, 24), foot(Q, 22, 19, 14), foot(Q, -58, 19, 14), foot(Q, -65, 19, 15.5), foot(Q, -65, 19, 13),
		foot(Q, -65, SKY, -6), foot(Q, -65, SKY, -14), foot(Q, -56, SKY, -14), foot(Q, -56, SKY, -20),
		pol(330, 112) + dir(300) * 7 + sky, pol(330, 112) + sky, pol(330, 112) + dir(330) * 5 + sky,
	}) do
		table.insert(leg1, p)
	end
	local leg2 = { pol(330, 112) + sky, pol(330, 105) + sky, towerSide(330, 0, SKY) }
	stairWay(leg2, 330, false)
	for _, p in ipairs({
		towers[330] + V3(0, 1, 0), towerSide(330, 240, 1), foot(S300i, -30, 1, 0), foot(S300i, 22.25, 1, 0), foot(S300i, 22.25, 1, 14), foot(S300i, 22.25, 0, 17),
		foot(S300i, -22.25, 0, 17), foot(S300i, -22.25, 0, 26), foot(S300o, -22.25, 1, 0), foot(S300o, 46, 1, 0), foot(S300o, 52, 0, 0),
		at(0, 0, -118), at(-5.4, 0, -112), at(-5.4, 0, -107), foot(S240, -22.25, 0, 17), foot(S240, -22.25, 1, 10), foot(S240, -22.25, 1, 0), foot(S240, 30, 1, 0),
		towerSide(210, 120, 1), towers[210] + V3(0, 1, 0),
	}) do
		table.insert(leg2, p)
	end
	stairWay(leg2, 210, true)
	for _, p in ipairs({
		towers[210] + sky, towerSide(210, 240, SKY), towerSide(150, 120, SKY), towers[150] + sky, towers[150] + dir(155) * 5.2 + sky, towerSide(150, 0, SKY),
		pol(150, 112) + sky, pol(150, 112) + dir(150) * 7 + sky, foot(G, 0, SKY, 149), foot(G, 14, SKY, 160), foot(G, 14, SKY, 171),
		foot(G, 14, 15, 192), foot(G, 14, 15, 200), foot(G, -14, 15, 200), foot(G, -14, 15, 192), foot(G, -14, -1, 170), foot(G, -14, -1, 168.5),
		foot(G, -10, -1, 167), foot(G, -9.6, -1, 160), foot(G, 0, -1, 160), foot(G, 0, -1, 150), foot(G, 0, -15, 131), foot(G, 0, -15, 48.5), foot(G, 0, -15, 44), foot(G, -5, -15, 44),
	}) do
		table.insert(leg2, p)
	end
	for i = 1, STEPS, 3 do
		table.insert(leg2, pol(D0 + (i - 1) * DSTEP, 43.5) + V3(0, -15 - i, 0))
	end
	table.insert(leg2, pol(195.7, 43.5) + V3(0, LOW, 0))
	table.insert(leg2, pol(LIFT_DEG, 44.75) + V3(0, LOW, 0))
	local leg3 = { towers[150] + sky, towers[150] + dir(155) * 5.2 + sky }
	stairWay(leg3, 150, false)
	for _, p in ipairs({
		towers[150] + V3(0, 1, 0), towerSide(150, 240, 1), foot(S120i, -30, 1, 0), foot(S120i, 22.25, 1, 0), foot(S120i, 22.25, 1, 14), foot(S120i, 22.25, 0, 17), foot(S120i, 22.25, 0, 26),
		foot(S120o, 22.25, 1, 0), foot(S120o, -46, 1, 0), foot(S120o, -52, 0, 0), at(-103, 0, 58),
		foot(palace, 50, 0, 30), foot(palace, 44, 1, 30), foot(palace, 28, 1, 30), foot(palace, 0, 1, 25), foot(palace, 0, 1, -8), foot(palace, 0, 1, -12), foot(palace, 0, 0, -16),
	}) do
		table.insert(leg3, p)
	end
	local home = { foot(palace, 0, 0, -16), foot(palace, 31, 0, -16), pol(135, 56), pol(120, 55.8), pol(105, 55.8), pol(90, 55.8), pol(75, 55.8), pol(60, 55.8), pol(45, 56), pol(30, 59), pol(20, 58), pol(0, 62), pol(0, 69), pol(0, 80), pol(0, 86), at(96, 0, -11.5), at(107, 0, -8) }
	info.Heights.Route = {
		{ Name = "leg 1, gate to ladder", Points = leg1 },
		{ Name = "leg 2, ladder to lift", Points = leg2 },
		{ Name = "leg 3, 150 tower to palace door", Points = leg3 },
		{ Name = "palace door home, through the court door and the arch", Points = home },
		{ Name = "behind the throne, up to the Ballroom", Points = ballroom.Way },
	}

	-- no two blocks of stone or leaves of gold quite alike, and their ageing in patches, running across neighbours
	-- (not the paving or landings: they overlap flush, and two colours there would flicker)
	for _, p in ipairs(folder:GetChildren()) do
		if p:IsA("BasePart") and p.Name ~= "Paving" and p.Name ~= "Landing" then
			local q = p.Position
			local patch = math.clamp(0.5 + math.noise(q.X / 23, q.Y / 13, q.Z / 23), 0, 1)
			if p.Material == MAT.Limestone then
				p.Color = p.Color:Lerp(SOOT, patch * 0.32 + R(0, 0.06))
			elseif p.Material == MAT.Metal then
				p.Color = p.Color:Lerp(TARNISH, patch * 0.42 + R(0, 0.08))
			end
		end
	end

	-- THE COURT, STILL AT ITS POSTS: the kinds (ReplicatedStorage/GildedKit and the files that use it) along the way through, in the
	-- halls, on the bridges and the terraces. Each spot names a kind; Config.GildedEnemies says which are in, and a spot whose kind is out
	-- takes the next one in that list instead, so culling the list never leaves a hall empty.
	do
		local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"))
		local enabled, isOn = Config.GildedEnemies or {}, {}
		for i, kind in ipairs(enabled) do
			isOn[kind] = i
		end
		local n = 0
		local function guard(pos, toward, kind)
			n += 1
			if #enabled == 0 then
				return
			end
			kind = isOn[kind] and kind or enabled[n % #enabled + 1]
			local p = pos + V3(0, 3.2, 0)
			table.insert(info.EnemySpawns, { Type = kind, CFrame = CFrame.lookAt(p, V3(toward.X, p.Y, toward.Z)) })
		end
		local S60, S300o, S300i, S240, S120i, S120o = side(60, 108), side(300, 108), side(300, 72), side(240, 72), side(120, 72), side(120, 108)
		local palace = side(180, 72)
		local function F(cf, x, y, z)
			return (cf * CFrame.new(x, y, z)).Position
		end
		local sky = V3(0, SKY, 0)
		-- (half the posts the court once kept, every hall and gallery still held, and only its six best: Config.GildedEnemies)
		-- leg 1: the outer halls of side 60, the boulevard, the great bridge, the Almonry
		guard(F(S60, 22, 1, 0), F(S60, 30, 1, 0), "Oathsworn")
		guard(F(S60, -22, 1, 0), F(S60, -10, 1, 0), "Dowager")
		guard(at(104, 0, 48), at(104, 0, 30), "Caryatid")
		guard(at(-2, 0, 106), at(0, 0, 95), "Topiarist")
		guard(ORIGIN + sky + V3(0, 0, -6), ORIGIN + sky + V3(0, 0, -40), "GiltSeraph")
		guard(F(Q, 0, SKY, -14), F(Q, 20, SKY, -14), "Dowager")
		guard(F(Q, 0, 20, 14), F(Q, 20, 20, 14), "Seneschal")
		guard(F(Q, -51, SKY, -14), F(Q, -56, SKY, -20), "Oathsworn")
		-- leg 2: the halls of side 300, the street, side 240; the sky-gallery; the Terraces
		guard(F(S300i, -22, 1, -4), F(S300i, -30, 1, 0), "Oathsworn")
		guard(F(S300i, 0, 0, 20), F(S300i, -22, 0, 20), "Seneschal")
		guard(F(S300o, 0, 1, 0), F(S300o, -10, 1, 0), "Dowager")
		guard(F(S300o, 41, 1, 0), F(S300o, 34, 1, 0), "Caryatid")
		guard(at(-5, 0, -112), at(0, 0, -100), "Topiarist")
		guard(F(S240, -22, 1, -4), F(S240, -30, 1, 0), "Seneschal")
		guard((towers[210] + towers[150]) / 2 + sky, towers[150] + sky, "GiltSeraph")
		guard(F(G, 8, SKY, 157), F(G, 0, SKY, 149), "Topiarist")
		guard(F(G, 8, -1, 160), F(G, 0, -1, 150), "Caryatid")
		-- leg 3: side 120's halls, the palace's wing, its great hall; and the hole's walk, after the lift
		guard(F(S120i, 0, 1, 5), F(S120i, 11, 1, 0), "Dowager")
		guard(F(S120i, -22, 1, -4), F(S120i, -11, 1, 0), "GiltSeraph")
		guard(F(S120o, 0, 1, 0), F(S120o, 10, 1, 0), "Oathsworn")
		guard(F(palace, 38, 1, 30), F(palace, 46, 1, 30), "Oathsworn")
		guard(F(palace, 14, 1, 24), F(palace, 30, 1, 30), "Caryatid")
		guard(F(palace, 0, 1, -6), F(palace, 0, 1, 4), "Seneschal")
		guard(pol(240, 56), pol(210, 56), "GiltSeraph")
	end

	local REACH = RIM + 95 -- (out to the Almonry and the Terraces, and down their cliffs)
	table.insert(info.Zones, 1, { Name = "The Gilded Heights", MinX = ORIGIN.X - REACH, MaxX = ORIGIN.X + REACH, MinZ = ORIGIN.Z - REACH, MaxZ = ORIGIN.Z + REACH, MinY = Fn.Top - 50 })
	table.insert(info.Zones, 1, ballroom.Zone) -- (ahead of the Heights': its box overlaps theirs)
end

-- Debug: walk info.Heights.Route's legs: floor under every step, nothing in the way of a body (doors excepted, they open).
-- Prints each leg's length and time; a leg that doesn't go through warns where.
function M.check(route)
	local rp = RaycastParams.new()
	rp.RespectCanCollide = true
	local op = OverlapParams.new()
	op.RespectCanCollide = true
	for _, leg in ipairs(route) do
		local len, bad = 0, {}
		for i = 1, #leg.Points - 1 do
			local a, b = leg.Points[i], leg.Points[i + 1]
			local d = (b - a).Magnitude
			len += d
			for n = 0, math.floor(d / 2) do
				local p = a:Lerp(b, n * 2 / math.max(d, 2))
				-- (either side of the line too: the slivers between paving rings are no gap to a pair of feet)
				local hit = workspace:Raycast(p + V3(0, 2.5, 0), V3(0, -6, 0), rp) or workspace:Raycast(p + V3(0.7, 2.5, 0.7), V3(0, -6, 0), rp) or workspace:Raycast(p + V3(-0.7, 2.5, -0.7), V3(0, -6, 0), rp)
				if not hit then
					table.insert(bad, string.format("no floor at %.0f,%.0f,%.0f", p.X, p.Y, p.Z))
				end
				-- (the body from the knees up: anything lower's a step, and the stairs' next treads are that)
				for _, q in ipairs(workspace:GetPartBoundsInBox(CFrame.new(p + V3(0, 4, 0)), V3(1.6, 1.8, 1.6), op)) do
					if q.Name ~= "Door" then
						table.insert(bad, string.format("%s in the way at %.0f,%.0f,%.0f", q.Name, p.X, p.Y, p.Z))
						break
					end
				end
			end
		end
		print(string.format("[DGUS] Heights, %s: %.0f studs (%.0fs walking, %.0fs sprinting), %d problems", leg.Name, len, len / 12, len / 19, #bad))
		for i = 1, math.min(#bad, 12) do
			warn("[DGUS]   " .. bad[i])
		end
	end
end

return M
