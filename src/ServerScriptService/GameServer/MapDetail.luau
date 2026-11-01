--!nonstrict
-- MapDetail: wall dressing, floor work, arches and props for the Don'tGiveUpSkeleton.
--
-- Walls are dressed through "faces": a CFrame sitting on the wall surface at
-- floor level, whose LookVector points out into the room. In face space,
-- X runs along the wall, Y is up, and "out" is distance from the wall.
--
-- Small decoration is non-colliding, not queryable (the camera and hit checks
-- ignore it) and casts no shadow, to keep things cheap and snag-free.
local CollectionService = game:GetService("CollectionService")

local Detail = {}

local MAT = Enum.Material
local C = {
	Stone = Color3.fromRGB(70, 67, 61),
	StoneLight = Color3.fromRGB(98, 94, 86),
	Mortar = Color3.fromRGB(30, 29, 27),
	Grime = Color3.fromRGB(22, 21, 19),
	Moss = Color3.fromRGB(58, 68, 40),
	MossDark = Color3.fromRGB(36, 46, 28),
	Iron = Color3.fromRGB(42, 39, 36),
	Rust = Color3.fromRGB(88, 56, 36),
	Wood = Color3.fromRGB(58, 43, 31),
	WoodDark = Color3.fromRGB(36, 28, 21),
	Bone = Color3.fromRGB(186, 178, 154),
	BoneDark = Color3.fromRGB(130, 122, 104),
	Cloth = Color3.fromRGB(84, 22, 20),
	ClothDark = Color3.fromRGB(44, 16, 14),
	Void = Color3.fromRGB(9, 9, 11),
	Wax = Color3.fromRGB(214, 204, 176),
	Rock = Color3.fromRGB(56, 58, 54),
	Ossuary = Color3.fromRGB(104, 98, 86),
}
Detail.Colors = C

local rng = Random.new(4242)
local parent: Instance
local avoid = {}
-- Doorways cut through already-dressed walls: { min = Vector3, max = Vector3 }.
-- A detail part whose centre falls inside a cutout's X/Y range is trimmed along
-- Z to stop at the opening (or dropped if it lies wholly inside). The random
-- stream is untouched, so everything else dresses exactly as before.
local cutouts = {}

function Detail.init(folder)
	parent = folder
end

-- world points (torches, levers...) that wall features must not cover
function Detail.setAvoid(points)
	avoid = points
end

function Detail.setCutouts(list)
	cutouts = list or {}
end

-- swap the random stream (new areas get their own, so older areas never shift)
function Detail.useRng(r)
	local old = rng
	rng = r
	return old
end

---------------------------------------------------------------------------
-- primitives
---------------------------------------------------------------------------
local d
local function trimmed(size, cf, mat, color, o)
	local pos = cf.Position
	for _, c in ipairs(cutouts) do
		-- axis = the direction the wall runs (the part is trimmed along it); "Z" by default
		local ax = c.axis or "Z"
		local u = ax == "Z" and "X" or "Z" -- the other horizontal axis
		local pu, pa = pos[u], pos[ax]
		if pu >= c.min[u] and pu <= c.max[u] and pos.Y >= c.min.Y and pos.Y <= c.max.Y then
			local axes = { cf.RightVector, cf.UpVector, -cf.LookVector }
			local dims = { size.X, size.Y, size.Z }
			local best, bi = 0, 1
			for i = 1, 3 do
				if math.abs(axes[i][ax]) > best then
					best, bi = math.abs(axes[i][ax]), i
				end
			end
			local half = (best > 0.97) and dims[bi] / 2 or 0
			local lo, hi = pa - half, pa + half
			if hi > c.min[ax] and lo < c.max[ax] then
				local first
				for _, seg in ipairs({ { lo, c.min[ax] }, { c.max[ax], hi } }) do
					if seg[2] - seg[1] > 0.3 then
						local nd = table.clone(dims)
						nd[bi] = seg[2] - seg[1]
						local mid = (seg[1] + seg[2]) / 2
						local shift = ax == "Z" and Vector3.new(0, 0, mid - pa) or Vector3.new(mid - pa, 0, 0)
						local p = d(Vector3.new(nd[1], nd[2], nd[3]), cf + shift, mat, color, o)
						first = first or p
					end
				end
				return true, first
			end
		end
	end
	return false, nil
end

d = function(size, cf, mat, color, o)
	o = o or {}
	if #cutouts > 0 then
		local cut, piece = trimmed(size, cf, mat, color, o)
		if cut then
			return piece
		end
	end
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if o.shape then
		p.Shape = o.shape
	end
	p.Size = size
	p.CFrame = cf
	p.Material = mat
	p.Color = color
	local solid = o.collide == true
	p.CanCollide = solid
	p.CanQuery = solid or o.query == true
	p.CanTouch = false
	p.CastShadow = solid or o.shadow == true
	if o.transparency then
		p.Transparency = o.transparency
	end
	if o.reflectance then
		p.Reflectance = o.reflectance
	end
	p.Name = o.name or "Detail"
	p.Parent = o.parent or parent
	return p
end
Detail.part = d

local function vary(c, amt)
	local k = rng:NextNumber(-amt, amt)
	if k < 0 then
		return c:Lerp(Color3.new(0, 0, 0), -k)
	end
	return c:Lerp(Color3.new(1, 1, 1), k)
end
Detail.vary = vary

local function at(cf, x, y, out)
	return cf * CFrame.new(x, y, -out)
end

function Detail.face(px, pz, nx, nz, y)
	y = y or 0
	return CFrame.lookAt(Vector3.new(px, y, pz), Vector3.new(px + nx, y, pz + nz))
end

local function blocked(cf, x, halfW)
	for _, p in ipairs(avoid) do
		local l = cf:PointToObjectSpace(p)
		if math.abs(l.Z) < 4 and math.abs(l.X - x) < halfW + 1.5 then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------------
-- wall features (all in face space)
---------------------------------------------------------------------------
local function plinth(cf, w, h, depth, color, mat)
	d(Vector3.new(w, h, depth), at(cf, 0, h / 2, depth / 2), mat or MAT.Cobblestone, color, { collide = true, name = "Plinth" })
	-- worn top edge
	d(Vector3.new(w, 0.18, depth + 0.12), at(cf, 0, h + 0.05, depth / 2), MAT.Slate, vary(C.StoneLight, 0.05), { name = "PlinthCap" })
end

local function band(cf, w, y, h, depth, color, mat)
	d(Vector3.new(w, h, depth), at(cf, 0, y, depth / 2), mat or MAT.Slate, color, { shadow = true, name = "Course" })
end

local function stones(cf, w, h, y0, density, color, mat)
	local rowH = 1.6
	local y = y0 + rowH / 2
	local row = 0
	while y < h - 0.6 do
		local x = -w / 2 + 1.4 + (row % 2) * 1.5
		while x < w / 2 - 1.4 do
			local bw = rng:NextNumber(2.3, 3.4)
			local r = rng:NextNumber()
			if r < density then
				d(Vector3.new(bw - 0.16, rowH - 0.16, rng:NextNumber(0.12, 0.3)), at(cf, x, y, 0.06), mat or MAT.Cobblestone, vary(color, 0.18), { name = "Stone" })
			elseif r < density * 1.3 then
				d(Vector3.new(bw - 0.35, rowH - 0.35, 0.05), at(cf, x, y, 0.025), MAT.Slate, C.Void, { name = "MissingStone" })
			end
			x += bw
		end
		y += rowH
		row += 1
	end
end

local function cracks(cf, w, h, n)
	for _ = 1, n do
		local x = rng:NextNumber(-w / 2 + 1, w / 2 - 1)
		local y = rng:NextNumber(h * 0.35, h * 0.9)
		local ang = rng:NextNumber(-2.2, -0.9) -- running downward
		for _ = 1, rng:NextInteger(3, 6) do
			local len = rng:NextNumber(0.7, 1.6)
			local nx, ny = x + math.cos(ang) * len, y + math.sin(ang) * len
			if ny < 0.5 or math.abs(nx) > w / 2 - 0.3 then
				break
			end
			d(Vector3.new(len + 0.08, 0.12, 0.06), at(cf, (x + nx) / 2, (y + ny) / 2, 0.03) * CFrame.Angles(0, 0, ang), MAT.Slate, C.Mortar, { name = "Crack" })
			x, y = nx, ny
			ang += rng:NextNumber(-0.7, 0.7)
		end
	end
end

local function streaks(cf, w, h, n, wet)
	for _ = 1, n do
		local len = rng:NextNumber(h * 0.2, h * 0.6)
		local top = h - rng:NextNumber(0, h * 0.25)
		d(Vector3.new(rng:NextNumber(0.35, 1.2), len, 0.04), at(cf, rng:NextNumber(-w / 2 + 0.8, w / 2 - 0.8), top - len / 2, 0.025),
			MAT.SmoothPlastic, C.Grime, { transparency = 0.55, reflectance = wet and 0.25 or 0, name = "Streak" })
	end
end

local function moss(cf, w, n, maxH)
	for _ = 1, n do
		local s = rng:NextNumber(0.8, 2.6)
		d(Vector3.new(s, rng:NextNumber(0.4, 1.4), 0.18), at(cf, rng:NextNumber(-w / 2 + 0.5, w / 2 - 0.5), rng:NextNumber(0.3, maxH), 0.08),
			MAT.Grass, vary(C.Moss, 0.15), { name = "Moss" })
	end
end

local function ivy(cf, x, height)
	local y = 0.3
	while y < height do
		x += rng:NextNumber(-0.7, 0.7)
		for _ = 1, 2 do
			local s = rng:NextNumber(0.5, 1.3)
			d(Vector3.new(s, s, s * 0.5), at(cf, x + rng:NextNumber(-0.6, 0.6), y + rng:NextNumber(-0.3, 0.3), 0.2) * CFrame.Angles(0, 0, rng:NextNumber(0, 1.5)),
				MAT.Grass, vary(C.MossDark, 0.2), { name = "Ivy" })
		end
		y += rng:NextNumber(0.6, 1.1)
	end
end

local function shackles(cf, x, y)
	d(Vector3.new(1.6, 0.5, 0.14), at(cf, x, y, 0.07), MAT.Metal, C.Iron, { name = "ShacklePlate" })
	for _, sx in ipairs({ -0.6, 0.6 }) do
		for i = 0, 2 do
			d(Vector3.new(0.14, 0.4, 0.14), at(cf, x + sx, y - 0.45 - i * 0.42, 0.18) * CFrame.Angles(0, (i % 2) * math.pi / 2, 0), MAT.Metal, C.Iron, { name = "Chain" })
		end
		d(Vector3.new(0.18, 0.62, 0.62), at(cf, x + sx, y - 1.75, 0.22) * CFrame.Angles(0, 0, math.pi / 2), MAT.Metal, C.Rust, { shape = Enum.PartType.Cylinder, name = "Cuff" })
	end
end

-- An arch of wedge-ish blocks in the face plane. springY = where the curve starts.
local function archRib(cf, cx, springY, halfW, rise, thick, depth, out, segs, mat, color, collide)
	for i = 0, segs - 1 do
		local a0, a1 = math.pi * i / segs, math.pi * (i + 1) / segs
		local x0, y0 = cx + halfW * math.cos(a0), springY + rise * math.sin(a0)
		local x1, y1 = cx + halfW * math.cos(a1), springY + rise * math.sin(a1)
		local len = math.sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2) + 0.12
		d(Vector3.new(len, thick, depth), at(cf, (x0 + x1) / 2, (y0 + y1) / 2, out) * CFrame.Angles(0, 0, math.atan2(y1 - y0, x1 - x0)),
			mat or MAT.Cobblestone, vary(color or C.Stone, 0.06), { collide = collide, shadow = true, name = "Arch" })
	end
	-- keystone
	d(Vector3.new(0.9, thick + 0.5, depth + 0.2), at(cf, cx, springY + rise + 0.1, out), mat or MAT.Cobblestone, vary(color or C.StoneLight, 0.04), { shadow = true, name = "Keystone" })
end
Detail.archRib = archRib

local function window(cf, x, y, w, h, lit)
	-- y = bottom of the opening
	d(Vector3.new(w, h, 0.08), at(cf, x, y + h / 2, 0.04), lit and MAT.Neon or MAT.Slate, lit and Color3.fromRGB(34, 40, 54) or C.Void, { name = "WindowVoid" })
	d(Vector3.new(w, w / 2, 0.08), at(cf, x, y + h + w / 4 - 0.1, 0.04), lit and MAT.Neon or MAT.Slate, lit and Color3.fromRGB(34, 40, 54) or C.Void, { name = "WindowVoid" })
	archRib(cf, x, y + h, w / 2 + 0.35, w / 2 + 0.35, 0.7, 0.7, 0.35, 7, MAT.Cobblestone, C.StoneLight, false)
	for _, sx in ipairs({ -1, 1 }) do
		d(Vector3.new(0.7, h, 0.7), at(cf, x + sx * (w / 2 + 0.35), y + h / 2, 0.35), MAT.Cobblestone, vary(C.StoneLight, 0.05), { shadow = true, name = "Jamb" })
	end
	d(Vector3.new(w + 1.4, 0.45, 1.0), at(cf, x, y - 0.2, 0.5), MAT.Slate, vary(C.StoneLight, 0.05), { shadow = true, name = "Sill" })
	for i = 1, 3 do
		local bx = x - w / 2 + w * i / 4
		d(Vector3.new(h + w / 2, 0.2, 0.2), at(cf, bx, y + (h + w / 2) / 2, 0.15) * CFrame.Angles(0, 0, math.pi / 2), MAT.Metal, C.Iron, { shape = Enum.PartType.Cylinder, name = "WindowBar" })
	end
	d(Vector3.new(w, 0.18, 0.18), at(cf, x, y + h * 0.55, 0.15), MAT.Metal, C.Iron, { name = "WindowBar" })
end

Detail.window = window

local function banner(cf, x, top, len, w, color)
	d(Vector3.new(w + 1.2, 0.3, 0.3), at(cf, x, top, 0.7) * CFrame.Angles(0, 0, math.pi / 2) * CFrame.Angles(0, 0, -math.pi / 2), MAT.Wood, C.WoodDark, { name = "BannerPole" })
	for _, sx in ipairs({ -1, 1 }) do
		d(Vector3.new(0.2, 0.2, 0.7), at(cf, x + sx * (w / 2 + 0.4), top, 0.35), MAT.Metal, C.Iron, { name = "BannerBracket" })
	end
	local body = len * 0.72
	local tilt = CFrame.Angles(rng:NextNumber(-0.04, 0.04), 0, rng:NextNumber(-0.03, 0.03))
	d(Vector3.new(w, body, 0.1), at(cf, x, top - body / 2 - 0.15, 0.7) * tilt, MAT.Fabric, vary(color, 0.08), { name = "Banner" })
	-- ragged tails of uneven length
	local strips = 4
	for i = 1, strips do
		local sw = w / strips
		local sl = len * rng:NextNumber(0.12, 0.3)
		d(Vector3.new(sw - 0.06, sl, 0.1), at(cf, x - w / 2 + sw * (i - 0.5), top - body - 0.15 - sl / 2, 0.7) * tilt, MAT.Fabric, vary(color, 0.12), { name = "BannerTail" })
	end
	-- faded emblem: a bone-white diamond with a dark eye
	d(Vector3.new(w * 0.4, w * 0.4, 0.04), at(cf, x, top - body * 0.42, 0.77) * tilt * CFrame.Angles(0, 0, math.pi / 4), MAT.Fabric, C.BoneDark, { name = "Emblem" })
	d(Vector3.new(w * 0.14, w * 0.14, 0.05), at(cf, x, top - body * 0.42, 0.79) * tilt, MAT.Fabric, C.ClothDark, { name = "Emblem" })
end

Detail.banner = banner

local function buttress(cf, x, h)
	d(Vector3.new(3, h * 0.62, 2.6), at(cf, x, h * 0.31, 1.3), MAT.Cobblestone, vary(C.Stone, 0.08), { collide = true, name = "Buttress" })
	d(Vector3.new(3.3, 0.5, 2.9), at(cf, x, h * 0.62 + 0.25, 1.45), MAT.Slate, vary(C.StoneLight, 0.05), { shadow = true, name = "ButtressLedge" })
	d(Vector3.new(2.4, h * 0.28, 1.5), at(cf, x, h * 0.62 + 0.5 + h * 0.14, 0.75), MAT.Cobblestone, vary(C.Stone, 0.08), { shadow = true, name = "Buttress" })
	d(Vector3.new(2.7, 0.45, 1.8), at(cf, x, h * 0.9 + 0.75, 0.9), MAT.Slate, vary(C.StoneLight, 0.05), { shadow = true, name = "ButtressLedge" })
end

local function pilaster(cf, x, h, w)
	d(Vector3.new(w, h - 3, 1.0), at(cf, x, h / 2, 0.5), MAT.Limestone, vary(C.Ossuary, 0.05), { collide = true, name = "Pilaster" })
	d(Vector3.new(w + 0.9, 1.6, 1.6), at(cf, x, 0.8, 0.8), MAT.Limestone, vary(C.Ossuary, 0.04), { collide = true, name = "PilasterBase" })
	d(Vector3.new(w + 0.9, 1.1, 1.5), at(cf, x, h - 1.6, 0.75), MAT.Limestone, vary(C.Ossuary, 0.04), { shadow = true, name = "PilasterCap" })
	for _, gx in ipairs({ -w * 0.22, w * 0.22 }) do
		d(Vector3.new(0.16, h - 5, 0.06), at(cf, x + gx, h / 2, 1.02), MAT.Slate, C.Mortar, { name = "Fluting" })
	end
end

local function niche(cf, x, y, w, h)
	-- y = bottom of the niche
	d(Vector3.new(w, h, 0.06), at(cf, x, y + h / 2, 0.03), MAT.Slate, C.Void, { name = "NicheVoid" })
	d(Vector3.new(w + 0.4, 0.3, 0.7), at(cf, x, y - 0.15, 0.35), MAT.Limestone, vary(C.Ossuary, 0.05), { name = "NicheLedge" })
	local roll = rng:NextNumber()
	if roll < 0.55 then
		d(Vector3.new(0.85, 0.85, 0.85), at(cf, x + rng:NextNumber(-0.3, 0.3), y + 0.43, 0.5), MAT.SmoothPlastic, vary(C.Bone, 0.08), { shape = Enum.PartType.Ball, name = "Skull" })
	elseif roll < 0.8 then
		for i = 0, 1 do
			d(Vector3.new(0.75, 0.75, 0.75), at(cf, x - 0.45 + i * 0.9, y + 0.38, 0.45), MAT.SmoothPlastic, vary(C.Bone, 0.08), { shape = Enum.PartType.Ball, name = "Skull" })
		end
	elseif roll < 0.95 then
		for i = 0, 2 do
			d(Vector3.new(w - 0.3, 0.16, 0.16), at(cf, x, y + 0.12 + i * 0.17, 0.35 + rng:NextNumber(-0.05, 0.05)) * CFrame.Angles(0, rng:NextNumber(-0.15, 0.15), 0), MAT.SmoothPlastic, vary(C.Bone, 0.1), { name = "Bone" })
		end
	end
end

local function rockOutcrops(cf, w, h, n)
	for _ = 1, n do
		local s = rng:NextNumber(1.2, 3)
		d(Vector3.new(s, s * rng:NextNumber(0.6, 1.3), s * rng:NextNumber(0.5, 0.9)),
			at(cf, rng:NextNumber(-w / 2 + 1, w / 2 - 1), rng:NextNumber(0.5, h - 0.8), rng:NextNumber(0.05, 0.35)) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(-0.5, 0.5), rng:NextNumber(-0.8, 0.8)),
			MAT.Rock, vary(C.Rock, 0.12), { name = "Outcrop" })
	end
end

---------------------------------------------------------------------------
-- wall styles
---------------------------------------------------------------------------
local STYLES = {}

STYLES.cell = function(cf, w, h)
	plinth(cf, w, 1.0, 0.45, vary(C.Stone, 0.1))
	stones(cf, w, h, 1.2, 0.13, C.Stone)
	cracks(cf, w, h, rng:NextInteger(1, 2))
	streaks(cf, w, h, rng:NextInteger(1, 3), false)
	moss(cf, w, rng:NextInteger(1, 4), 1.6)
	if w >= 8 and rng:NextNumber() < 0.45 and not blocked(cf, 0, 1.5) then
		shackles(cf, rng:NextNumber(-w / 4, w / 4), rng:NextNumber(6, 7.5))
	end
end

STYLES.corridor = function(cf, w, h)
	plinth(cf, w, 1.2, 0.6, vary(C.Stone, 0.08))
	stones(cf, w, h, 1.4, 0.16, C.Stone)
	cracks(cf, w, h, 2)
	streaks(cf, w, h, 3, false)
	moss(cf, w, 5, 2)
end

STYLES.tunnel = function(cf, w, h)
	rockOutcrops(cf, w, h, math.floor(w / 2.5))
	streaks(cf, w, h, math.floor(w / 5), true)
	moss(cf, w, math.floor(w / 3), 3)
end

STYLES.yard = function(cf, w, h)
	plinth(cf, w, 1.6, 0.8, vary(C.Stone, 0.06))
	stones(cf, w, h, 1.8, 0.08, C.Stone, MAT.Brick)
	band(cf, w, 13, 0.6, 0.45, vary(C.StoneLight, 0.04))
	band(cf, w, h - 1.2, 1.2, 0.9, vary(C.StoneLight, 0.04))
	-- buttresses every ~12 studs, with a window or banner in each bay
	local bays = math.max(1, math.floor(w / 12))
	local bayW = w / bays
	for i = 0, bays do
		local bx = -w / 2 + i * bayW
		if i > 0 and i < bays and not blocked(cf, bx, 1.5) then
			buttress(cf, bx, h)
		end
		if i < bays then
			local cx = bx + bayW / 2
			local roll = rng:NextNumber()
			if roll < 0.55 and not blocked(cf, cx, 1.8) then
				window(cf, cx, 16.5, 3, 5.5, rng:NextNumber() < 0.5)
			elseif roll < 0.85 and not blocked(cf, cx, 2) then
				banner(cf, cx, 25, 10, 3.2, rng:NextNumber() < 0.5 and C.Cloth or C.ClothDark)
			end
			if rng:NextNumber() < 0.5 then
				ivy(cf, cx + rng:NextNumber(-bayW / 3, bayW / 3), rng:NextNumber(6, 16))
			end
		end
	end
	cracks(cf, w, h, math.floor(w / 20))
	streaks(cf, w, h, math.floor(w / 8), false)
	moss(cf, w, math.floor(w / 6), 2.5)
end

-- the Castellan's keep: dressed brick, a skirting plinth and a cornice band; kept, not rotting
STYLES.keep = function(cf, w, h)
	plinth(cf, w, 1.0, 0.5, vary(C.Stone, 0.06))
	stones(cf, w, h, 1.4, 0.1, C.Stone, MAT.Brick)
	band(cf, w, h - 0.8, 0.8, 0.6, vary(C.StoneLight, 0.04))
	cracks(cf, w, h, math.max(1, math.floor(w / 16)))
	streaks(cf, w, h, math.floor(w / 10), false)
end

STYLES.ossuary = function(cf, w, h)
	plinth(cf, w, 1.4, 0.8, vary(C.Ossuary, 0.05), MAT.Limestone)
	band(cf, w, h - 2, 1.4, 1.1, vary(C.Ossuary, 0.04), MAT.Limestone)
	band(cf, w, 15.5, 0.6, 0.6, vary(C.Ossuary, 0.04), MAT.Limestone)
	local bays = math.max(1, math.floor(w / 11))
	local bayW = w / bays
	for i = 0, bays do
		local bx = -w / 2 + i * bayW
		if not blocked(cf, bx, 1.5) then
			pilaster(cf, bx, h, 2.2)
		end
		if i < bays then
			local cx = bx + bayW / 2
			-- three rows of skull niches
			local cols = math.max(1, math.floor((bayW - 2.6) / 2.7))
			local span = cols * 2.7
			for r = 0, 2 do
				for c = 0, cols - 1 do
					local nx = cx - span / 2 + 1.35 + c * 2.7
					if not blocked(cf, nx, 1.1) then
						niche(cf, nx, 2.6 + r * 4.2, 2, 2.6)
					end
				end
			end
			-- tall gothic window every other bay, banners between
			if i % 2 == 0 and not blocked(cf, cx, 2) then
				window(cf, cx, 20, 3.2, 9, true)
			elseif not blocked(cf, cx, 2) and rng:NextNumber() < 0.7 then
				banner(cf, cx, 33, 12, 3.4, C.ClothDark)
			end
		end
	end
	cracks(cf, w, h, math.floor(w / 18))
	streaks(cf, w, h, math.floor(w / 10), false)
end

---------------------------------------------------------------------------
-- the rot: the Vanguard's daughter's weeping, grown into the stone
---------------------------------------------------------------------------
local ROT = {
	Flesh = Color3.fromRGB(98, 82, 58),
	FleshDark = Color3.fromRGB(62, 48, 38),
	Vein = Color3.fromRGB(44, 30, 30),
	VeinLight = Color3.fromRGB(68, 50, 40),
	Glow = Color3.fromRGB(178, 172, 98),
	Mold = Color3.fromRGB(64, 70, 42),
	Slime = Color3.fromRGB(38, 44, 32),
	Stone = Color3.fromRGB(54, 54, 48),
}
Detail.Rot = ROT

-- a wet boil. glow = a faint sickly light inside it
local function boil(cf, s, glow)
	if glow then
		d(Vector3.new(s, s, s), cf, MAT.Neon, vary(ROT.Glow, 0.06), { shape = Enum.PartType.Ball, transparency = 0.35, name = "GlowBoil" })
	else
		d(Vector3.new(s, s * rng:NextNumber(0.75, 1), s), cf, MAT.SmoothPlastic, vary(rng:NextNumber() < 0.5 and ROT.Flesh or ROT.FleshDark, 0.1), { shape = Enum.PartType.Ball, reflectance = 0.14, name = "Boil" })
	end
end

-- a cluster of boils half-sunk into the floor
function Detail.boils(pos, n, spread, glowChance)
	for _ = 1, n do
		local s = rng:NextNumber(0.35, 1.3)
		local a, r = rng:NextNumber(0, 6.28), rng:NextNumber(0, spread)
		boil(CFrame.new(pos + Vector3.new(math.cos(a) * r, s * 0.18, math.sin(a) * r)), s, rng:NextNumber() < (glowChance or 0))
	end
end

-- a segment of vein lying from a to b
local function veinSeg(a, b, thick, color)
	local len = (b - a).Magnitude
	if len < 0.05 then
		return
	end
	d(Vector3.new(len + thick * 0.45, thick, thick), CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0), MAT.SmoothPlastic, vary(color or ROT.Vein, 0.08), { shape = Enum.PartType.Cylinder, reflectance = 0.1, name = "Vein" })
end

-- A branching vein crawling over a floor (or under a ceiling: hang = true).
-- bounds = { x1, z1, x2, z2 } keeps it out of the walls.
function Detail.rotVein(p, ang, len, thick, depth, bounds, hang)
	local travelled = 0
	local y = p.Y
	while travelled < len and thick > 0.1 do
		local l = rng:NextNumber(1.3, 2.5)
		ang += rng:NextNumber(-0.45, 0.45)
		local q = p + Vector3.new(math.cos(ang), 0, math.sin(ang)) * l
		if bounds and (q.X < bounds[1] or q.X > bounds[3] or q.Z < bounds[2] or q.Z > bounds[4]) then
			local cx, cz = (bounds[1] + bounds[3]) / 2, (bounds[2] + bounds[4]) / 2
			ang = math.atan2(cz - p.Z, cx - p.X) + rng:NextNumber(-0.7, 0.7)
			q = p + Vector3.new(math.cos(ang), 0, math.sin(ang)) * l
		end
		local lift = hang and -thick * 0.22 or thick * 0.22
		veinSeg(Vector3.new(p.X, y + lift, p.Z), Vector3.new(q.X, y + lift, q.Z), thick, thick > 0.5 and ROT.Vein or ROT.VeinLight)
		if depth > 0 and rng:NextNumber() < 0.3 then
			Detail.rotVein(Vector3.new(q.X, y, q.Z), ang + (rng:NextNumber() < 0.5 and -1 or 1) * rng:NextNumber(0.5, 1.1), (len - travelled) * rng:NextNumber(0.3, 0.6), thick * 0.6, depth - 1, bounds, hang)
		end
		if not hang and thick > 0.35 and rng:NextNumber() < 0.1 then
			boil(CFrame.new(q.X, y + thick * 0.4, q.Z), thick * rng:NextNumber(1.2, 2), rng:NextNumber() < 0.25)
		end
		thick *= rng:NextNumber(0.9, 0.97)
		p = q
		travelled += l
	end
end

-- a vein climbing a wall (face space), branching sideways as it goes
local function wallVein(cf, x, y, height, thick, depth)
	local ang = math.pi / 2 + rng:NextNumber(-0.3, 0.3)
	local top = y + height
	while y < top and thick > 0.1 do
		local l = rng:NextNumber(1.0, 2.0)
		ang = math.clamp(ang + rng:NextNumber(-0.5, 0.5), 0.3, math.pi - 0.3)
		local nx, ny = x + math.cos(ang) * l, y + math.sin(ang) * l
		local a, b = (cf * CFrame.new(x, y, -thick * 0.3)).Position, (cf * CFrame.new(nx, ny, -thick * 0.3)).Position
		veinSeg(a, b, thick, ROT.Vein)
		if depth > 0 and rng:NextNumber() < 0.25 then
			wallVein(cf, nx, ny, (top - ny) * rng:NextNumber(0.3, 0.6), thick * 0.6, depth - 1)
		end
		thick *= 0.93
		x, y = nx, ny
	end
end
Detail.wallVein = wallVein

-- slime strands hanging from a ceiling, a drop at the end of each
function Detail.strands(x1, z1, x2, z2, ceilY, n)
	for _ = 1, n do
		local x, z = rng:NextNumber(x1, x2), rng:NextNumber(z1, z2)
		local len = rng:NextNumber(1, 4.5)
		d(Vector3.new(0.07, len, 0.07), CFrame.new(x, ceilY - len / 2, z) * CFrame.Angles(rng:NextNumber(-0.06, 0.06), 0, rng:NextNumber(-0.06, 0.06)), MAT.Glass, ROT.Slime, { transparency = 0.25, reflectance = 0.3, name = "Strand" })
		d(Vector3.new(0.2, 0.26, 0.2), CFrame.new(x, ceilY - len - 0.1, z), MAT.Glass, ROT.Slime, { shape = Enum.PartType.Ball, transparency = 0.2, reflectance = 0.35, name = "Drop" })
	end
end

-- diseased flagstones: the stone itself gone soft and veined
function Detail.rotPatches(x1, z1, x2, z2, n, y)
	for _ = 1, n do
		-- a few overlapping, turned slabs so the edge reads as a blot, not a tile
		local cx, cz = rng:NextNumber(x1, x2), rng:NextNumber(z1, z2)
		local mat = rng:NextNumber() < 0.6 and MAT.CrackedLava or MAT.Mud
		local col = rng:NextNumber() < 0.5 and ROT.FleshDark or ROT.Slime
		for k = 1, rng:NextInteger(2, 4) do
			local s = rng:NextNumber(1.0, 3.2)
			local ox, oz = rng:NextNumber(-1.2, 1.2), rng:NextNumber(-1.2, 1.2)
			if cx + ox > x1 - 0.5 and cx + ox < x2 + 0.5 and cz + oz > z1 - 0.5 and cz + oz < z2 + 0.5 then
				d(Vector3.new(s, 0.05, s * rng:NextNumber(0.5, 1.1)), CFrame.new(cx + ox, (y or 0) + 0.02 + k * 0.006, cz + oz) * CFrame.Angles(0, rng:NextNumber(0, 6), 0),
					mat, vary(col, 0.1), { name = "RotPatch" })
			end
		end
	end
end

-- pools of standing filth
function Detail.puddle(pos, w, l, yaw)
	d(Vector3.new(w, 0.06, l), CFrame.new(pos + Vector3.new(0, 0.04, 0)) * CFrame.Angles(0, yaw or 0, 0), MAT.Glass, Color3.fromRGB(34, 40, 28), { transparency = 0.3, reflectance = 0.3, name = "Puddle" })
end

-- k = how far the rot has got (0 = barely, 1 = everywhere)
STYLES.rot = function(cf, w, h, k)
	k = k or 1
	plinth(cf, w, 1.2, 0.6, vary(ROT.Stone, 0.08))
	stones(cf, w, h, 1.4, 0.15, ROT.Stone)
	cracks(cf, w, h, math.max(1, math.floor(w / 14)))
	streaks(cf, w, h, math.floor(w / 4 * (0.4 + k)), true)
	moss(cf, w, math.floor(w / 3 * (0.3 + k)), 2 + 3 * k)
	for _ = 1, math.floor(w / 7 * k + 0.5) do
		local x = rng:NextNumber(-w / 2 + 1, w / 2 - 1)
		if not blocked(cf, x, 1) then
			wallVein(cf, x, 0.2, rng:NextNumber(h * 0.3, h * 0.9) * (0.5 + k * 0.5), rng:NextNumber(0.35, 0.75) * (0.6 + k * 0.4), 2)
		end
	end
	for _ = 1, math.floor(w / 9 * k) do
		local x, y = rng:NextNumber(-w / 2 + 1, w / 2 - 1), rng:NextNumber(0.4, h * 0.5)
		if not blocked(cf, x, 1.2) then
			for _ = 1, rng:NextInteger(3, 7) do
				local s = rng:NextNumber(0.35, 1.2)
				boil(at(cf, x + rng:NextNumber(-1.1, 1.1), y + rng:NextNumber(-0.8, 0.8), s * 0.25), s, rng:NextNumber() < 0.2 * k)
			end
		end
	end
end

function Detail.dressWall(cf, w, h, style, k)
	local f = STYLES[style]
	if f then
		f(cf, w, h, k)
	end
end

---------------------------------------------------------------------------
-- floors
---------------------------------------------------------------------------
function Detail.floorSeams(x1, z1, x2, z2, step, color)
	color = color or C.Mortar
	for z = z1 + step, z2 - 0.01, step do
		d(Vector3.new(x2 - x1, 0.04, 0.14), CFrame.new((x1 + x2) / 2, 0.02, z), MAT.Slate, color, { name = "Seam" })
	end
	for x = x1 + step, x2 - 0.01, step do
		d(Vector3.new(0.14, 0.04, z2 - z1), CFrame.new(x, 0.02, (z1 + z2) / 2), MAT.Slate, color, { name = "Seam" })
	end
end

function Detail.floorTiles(x1, z1, x2, z2, step, chance, color, mat)
	for x = x1, x2 - step + 0.01, step do
		for z = z1, z2 - step + 0.01, step do
			if rng:NextNumber() < chance then
				local cx, cz = x + step / 2, z + step / 2
				if rng:NextNumber() < 0.25 then
					-- cracked flagstone: two halves at slightly different heights
					d(Vector3.new(step - 0.3, 0.07, step / 2 - 0.2), CFrame.new(cx, 0.035, cz - step / 4), mat or MAT.Slate, vary(color, 0.12), { name = "Flagstone" })
					d(Vector3.new(step - 0.3, 0.1, step / 2 - 0.2), CFrame.new(cx, 0.05, cz + step / 4) * CFrame.Angles(0.03, 0, 0), mat or MAT.Slate, vary(color, 0.12), { name = "Flagstone" })
				else
					d(Vector3.new(step - 0.25, 0.07, step - 0.25), CFrame.new(cx, 0.035, cz), mat or MAT.Slate, vary(color, 0.12), { name = "Flagstone" })
				end
			end
		end
	end
end

function Detail.gutter(x, z1, z2)
	d(Vector3.new(0.9, 0.05, z2 - z1), CFrame.new(x, 0.025, (z1 + z2) / 2), MAT.Slate, C.Void, { name = "Gutter" })
	d(Vector3.new(0.9, 0.06, z2 - z1), CFrame.new(x, 0.02, (z1 + z2) / 2), MAT.Glass, Color3.fromRGB(20, 26, 26), { transparency = 0.5, reflectance = 0.3, name = "GutterWater" })
	for z = z1 + 6, z2 - 1, 12 do
		for i = -1, 1 do
			d(Vector3.new(1.4, 0.08, 0.16), CFrame.new(x, 0.05, z + i * 0.35), MAT.Metal, C.Rust, { name = "Grate" })
		end
	end
end

function Detail.ritualCircle(center, r)
	for _, rr in ipairs({ r, r * 0.78 }) do
		local segs = 32
		for i = 0, segs - 1 do
			local a = (i + 0.5) / segs * math.pi * 2
			local len = 2 * math.pi * rr / segs + 0.1
			d(Vector3.new(len, 0.05, 0.35), CFrame.new(center + Vector3.new(math.cos(a) * rr, 0.03, math.sin(a) * rr)) * CFrame.Angles(0, -a + math.pi / 2, 0),
				MAT.Slate, C.BoneDark, { transparency = 0.25, name = "Rune" })
		end
	end
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		local mid = (r * 0.78 + r * 0.3) / 2
		d(Vector3.new(0.3, 0.05, r * 0.48), CFrame.new(center + Vector3.new(math.cos(a) * mid, 0.03, math.sin(a) * mid)) * CFrame.Angles(0, -a + math.pi / 2, 0) * CFrame.Angles(0, math.pi / 2, 0),
			MAT.Slate, C.BoneDark, { transparency = 0.3, name = "Rune" })
	end
	d(Vector3.new(r * 0.5, 0.05, r * 0.5), CFrame.new(center + Vector3.new(0, 0.03, 0)) * CFrame.Angles(0, math.pi / 4, 0), MAT.Slate, C.Mortar, { transparency = 0.2, name = "Sigil" })
end

---------------------------------------------------------------------------
-- props
---------------------------------------------------------------------------
function Detail.bonePile(pos, n)
	for _ = 1, n do
		d(Vector3.new(0.18, 0.18, rng:NextNumber(0.9, 1.8)), CFrame.new(pos + Vector3.new(rng:NextNumber(-1.6, 1.6), rng:NextNumber(0.1, 0.5), rng:NextNumber(-1.6, 1.6)))
			* CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6), rng:NextNumber(-0.3, 0.3)), MAT.SmoothPlastic, vary(C.Bone, 0.12), { name = "Bone" })
	end
	for _ = 1, rng:NextInteger(1, 3) do
		d(Vector3.new(0.85, 0.85, 0.85), CFrame.new(pos + Vector3.new(rng:NextNumber(-1.2, 1.2), 0.45, rng:NextNumber(-1.2, 1.2))), MAT.SmoothPlastic, vary(C.Bone, 0.1), { shape = Enum.PartType.Ball, name = "Skull" })
	end
end

function Detail.bucket(pos)
	d(Vector3.new(1.1, 1.0, 1.0), CFrame.new(pos + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.pi / 2), MAT.WoodPlanks, C.Wood, { shape = Enum.PartType.Cylinder, name = "Bucket" })
	d(Vector3.new(0.12, 1.05, 1.05), CFrame.new(pos + Vector3.new(0, 0.85, 0)) * CFrame.Angles(0, 0, math.pi / 2), MAT.Metal, C.Iron, { shape = Enum.PartType.Cylinder, name = "BucketBand" })
end

function Detail.stool(pos, tipped)
	local cf = CFrame.new(pos) * (tipped and CFrame.Angles(math.pi / 2, rng:NextNumber(0, 6), 0) * CFrame.new(0, 0, -0.9) or CFrame.Angles(0, rng:NextNumber(0, 6), 0))
	d(Vector3.new(1.6, 0.25, 1.6), cf * CFrame.new(0, 1.4, 0), MAT.WoodPlanks, C.Wood, { name = "Stool" })
	for _, o in ipairs({ { 0.6, 0.6 }, { -0.6, 0.6 }, { 0.6, -0.6 }, { -0.6, -0.6 } }) do
		d(Vector3.new(0.2, 1.3, 0.2), cf * CFrame.new(o[1], 0.65, o[2]), MAT.Wood, C.WoodDark, { name = "StoolLeg" })
	end
end

function Detail.barrel(pos, onSide)
	local cf = CFrame.new(pos + Vector3.new(0, onSide and 1.1 or 1.5, 0)) * (onSide and CFrame.Angles(0, rng:NextNumber(0, 6), 0) or CFrame.Angles(0, 0, math.pi / 2))
	d(Vector3.new(3, 2.2, 2.2), cf, MAT.WoodPlanks, vary(C.Wood, 0.1), { collide = true, shape = Enum.PartType.Cylinder, name = "Barrel" })
	for _, x in ipairs({ -1.0, 1.0 }) do
		d(Vector3.new(0.18, 2.28, 2.28), cf * CFrame.new(x, 0, 0), MAT.Metal, C.Iron, { shape = Enum.PartType.Cylinder, name = "Hoop" })
	end
end

function Detail.gravestone(pos, yaw)
	local cf = CFrame.new(pos) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(rng:NextNumber(-0.15, 0.15), 0, rng:NextNumber(-0.12, 0.12))
	local kind = rng:NextNumber()
	if kind < 0.6 then
		d(Vector3.new(2, 2.6, 0.5), cf * CFrame.new(0, 1.1, 0), MAT.Slate, vary(C.StoneLight, 0.1), { collide = true, name = "Headstone" })
		d(Vector3.new(0.5, 2, 2), cf * CFrame.new(0, 2.4, 0) * CFrame.Angles(0, 0, math.pi / 2), MAT.Slate, vary(C.StoneLight, 0.1), { collide = true, shape = Enum.PartType.Cylinder, name = "Headstone" })
	else
		d(Vector3.new(0.6, 3.4, 0.5), cf * CFrame.new(0, 1.5, 0), MAT.Slate, vary(C.StoneLight, 0.1), { collide = true, name = "Cross" })
		d(Vector3.new(2, 0.5, 0.5), cf * CFrame.new(0, 2.4, 0), MAT.Slate, vary(C.StoneLight, 0.1), { collide = true, name = "Cross" })
	end
	d(Vector3.new(2.4, 0.3, 4.2), CFrame.new(pos + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, yaw, 0) * CFrame.new(0, 0, -2.3), MAT.Ground, Color3.fromRGB(46, 40, 34), { name = "Grave" })
end

function Detail.well(pos)
	local r = 2.6
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		d(Vector3.new(1.5, 2.4, 1.1), CFrame.new(pos + Vector3.new(math.cos(a) * r, 1.2, math.sin(a) * r)) * CFrame.Angles(0, -a, 0), MAT.Cobblestone, vary(C.Stone, 0.1), { collide = true, name = "WellStone" })
	end
	d(Vector3.new(0.1, r * 2, r * 2), CFrame.new(pos + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.pi / 2), MAT.Slate, C.Void, { shape = Enum.PartType.Cylinder, name = "WellVoid" })
	for _, sx in ipairs({ -1, 1 }) do
		d(Vector3.new(0.5, 6, 0.5), CFrame.new(pos + Vector3.new(sx * (r + 0.2), 3, 0)), MAT.Wood, C.WoodDark, { collide = true, name = "WellPost" })
	end
	d(Vector3.new(r * 2 + 1.4, 0.4, 0.4), CFrame.new(pos + Vector3.new(0, 5.6, 0)), MAT.Wood, C.WoodDark, { name = "WellBeam" })
	d(Vector3.new(r * 2 + 2, 0.3, 3.6), CFrame.new(pos + Vector3.new(0, 6.6, 0.9)) * CFrame.Angles(0.5, 0, 0), MAT.WoodPlanks, C.Wood, { shadow = true, name = "WellRoof" })
	d(Vector3.new(r * 2 + 2, 0.3, 3.6), CFrame.new(pos + Vector3.new(0, 6.6, -0.9)) * CFrame.Angles(-0.5, 0, 0), MAT.WoodPlanks, C.Wood, { shadow = true, name = "WellRoof" })
	d(Vector3.new(0.1, 3.5, 0.1), CFrame.new(pos + Vector3.new(0, 3.8, 0)), MAT.Fabric, Color3.fromRGB(96, 84, 52), { name = "Rope" })
	Detail.bucket(pos + Vector3.new(0, 1.2, 0))
end

function Detail.weeds(pos, n)
	for _ = 1, n do
		local h = rng:NextNumber(0.4, 1.2)
		d(Vector3.new(0.12, h, 0.5), CFrame.new(pos + Vector3.new(rng:NextNumber(-0.8, 0.8), h / 2, rng:NextNumber(-0.8, 0.8))) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6), rng:NextNumber(-0.4, 0.4)),
			MAT.Grass, vary(C.Moss, 0.2), { name = "Weed" })
	end
end

function Detail.chandelier(pos, topY, dim)
	local r = 3.2
	for i = 0, math.floor((topY - pos.Y) / 0.6) do
		d(Vector3.new(0.2, 0.55, 0.2), CFrame.new(pos + Vector3.new(0, 0.6 + i * 0.6, 0)) * CFrame.Angles(0, (i % 2) * math.pi / 2, 0), MAT.Metal, C.Iron, { name = "Chain" })
	end
	for i = 0, 11 do
		local a = (i + 0.5) / 12 * math.pi * 2
		d(Vector3.new(2 * math.pi * r / 12 + 0.1, 0.35, 0.35), CFrame.new(pos + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)) * CFrame.Angles(0, -a + math.pi / 2, 0), MAT.Metal, C.Iron, { name = "ChandelierRing" })
	end
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2
		local tip = pos + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		local top = pos + Vector3.new(0, 3, 0)
		d(Vector3.new(0.15, 0.15, (top - tip).Magnitude), CFrame.lookAt((tip + top) / 2, top), MAT.Metal, C.Iron, { name = "ChandelierArm" })
	end
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		local cpos = pos + Vector3.new(math.cos(a) * r, 0.65, math.sin(a) * r)
		d(Vector3.new(0.3, 0.9, 0.3), CFrame.new(cpos), MAT.SmoothPlastic, vary(C.Wax, 0.06), { name = "Candle" })
		d(Vector3.new(0.12, 0.25, 0.12), CFrame.new(cpos + Vector3.new(0, 0.6, 0)), MAT.Neon, Color3.fromRGB(255, 170, 80), { name = "Flame" })
	end
	local core = d(Vector3.new(0.2, 0.2, 0.2), CFrame.new(pos + Vector3.new(0, 0.8, 0)), MAT.SmoothPlastic, C.Iron, { transparency = 1, name = "ChandelierLight" })
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 170, 100)
	l.Range = 30
	l.Brightness = 1.3 * (dim or 1)
	l.Shadows = true
	l.Parent = core
	l:SetAttribute("Base", l.Brightness)
	CollectionService:AddTag(l, "Flicker")
end

-- a dead prisoner slumped against a wall. facing = direction it looks (away from the wall)
function Detail.slumpedSkeleton(pos, facing)
	local cf = CFrame.lookAt(pos, pos + facing)
	d(Vector3.new(1.4, 1.6, 0.6), cf * CFrame.new(0, 1.2, 0.2) * CFrame.Angles(-0.25, 0, 0), MAT.Fabric, Color3.fromRGB(60, 52, 42), { name = "Rags" })
	for i = 0, 3 do
		d(Vector3.new(1.1, 0.12, 0.12), cf * CFrame.new(0, 0.7 + i * 0.32, -0.1), MAT.SmoothPlastic, vary(C.Bone, 0.1), { name = "Rib" })
	end
	d(Vector3.new(0.85, 0.85, 0.85), cf * CFrame.new(0.2, 2.2, -0.1), MAT.SmoothPlastic, C.Bone, { shape = Enum.PartType.Ball, name = "Skull" })
	for _, sx in ipairs({ -0.4, 0.4 }) do
		d(Vector3.new(0.18, 0.18, 2.1), cf * CFrame.new(sx, 0.15, -1.0) * CFrame.Angles(0, sx * 0.3, 0), MAT.SmoothPlastic, vary(C.Bone, 0.08), { name = "LegBone" })
	end
	d(Vector3.new(0.16, 0.16, 1.6), cf * CFrame.new(0.8, 0.5, -0.5) * CFrame.Angles(0.6, 0.3, 0), MAT.SmoothPlastic, vary(C.Bone, 0.08), { name = "ArmBone" })
end

function Detail.timberFrame(a, b, h)
	-- a, b = floor points on opposite walls
	for _, p in ipairs({ a, b }) do
		d(Vector3.new(0.9, h, 0.9), CFrame.new(p + Vector3.new(0, h / 2, 0)), MAT.Wood, vary(C.WoodDark, 0.1), { collide = true, name = "Post" })
	end
	local top = (a + b) / 2 + Vector3.new(0, h - 0.4, 0)
	d(Vector3.new(0.9, 0.9, (b - a).Magnitude + 0.6), CFrame.lookAt(top, top + (b - a)), MAT.Wood, vary(C.WoodDark, 0.1), { shadow = true, name = "Lintel" })
	for _, p in ipairs({ a, b }) do
		local s = p + Vector3.new(0, h - 2.6, 0)
		local e = p + (top - p - Vector3.new(0, h - 0.4, 0)).Unit * 2.2 + Vector3.new(0, h - 0.6, 0)
		d(Vector3.new(0.5, 0.5, (e - s).Magnitude), CFrame.lookAt((s + e) / 2, e), MAT.Wood, vary(C.WoodDark, 0.1), { name = "Brace" })
	end
end

function Detail.stalactites(x1, z1, x2, z2, ceilingY, n)
	for _ = 1, n do
		local x, z = rng:NextNumber(x1, x2), rng:NextNumber(z1, z2)
		local len = rng:NextNumber(0.8, 2.4)
		local w = rng:NextNumber(0.4, 0.9)
		local y = ceilingY
		for k = 0, 2 do
			local seg = len / 3
			d(Vector3.new(w * (1 - k * 0.3), seg, w * (1 - k * 0.3)), CFrame.new(x, y - seg / 2, z) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), MAT.Rock, vary(C.Rock, 0.1), { name = "Stalactite" })
			y -= seg
		end
	end
end

function Detail.pipe(a, b)
	local len = (b - a).Magnitude
	d(Vector3.new(len, 0.8, 0.8), CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0), MAT.CorrodedMetal, C.Rust, { shape = Enum.PartType.Cylinder, shadow = true, name = "Pipe" })
	local dir = (b - a).Unit
	for t = 4, len - 1, 8 do
		local p = a + dir * t
		d(Vector3.new(1.0, 1.0, 0.3), CFrame.lookAt(p, p + dir), MAT.Metal, C.Iron, { name = "PipeBracket" })
	end
	for _ = 1, 3 do
		local p = a + dir * rng:NextNumber(2, len - 2)
		d(Vector3.new(0.12, rng:NextNumber(1.5, 4), 0.06), CFrame.new(p - Vector3.new(0, 2.2, 0)), MAT.SmoothPlastic, C.Rust, { transparency = 0.4, name = "RustDrip" })
	end
end

-- a chapel pew. broken = split and slumped, half sunk into the rot
function Detail.pew(pos, yaw, len, broken)
	local cf = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
	if broken then
		cf = cf * CFrame.Angles(rng:NextNumber(-0.12, 0.12), 0, rng:NextNumber(0.1, 0.25)) * CFrame.new(0, -0.3, 0)
	end
	local wood = vary(C.WoodDark, 0.12)
	d(Vector3.new(len, 0.3, 1.5), cf * CFrame.new(0, 1.5, 0), MAT.WoodPlanks, wood, { collide = not broken, name = "PewSeat" })
	d(Vector3.new(len, 1.6, 0.25), cf * CFrame.new(0, 2.5, 0.7) * CFrame.Angles(-0.1, 0, 0), MAT.WoodPlanks, wood, { collide = not broken, name = "PewBack" })
	for _, x in ipairs({ -len / 2 + 0.3, len / 2 - 0.3 }) do
		d(Vector3.new(0.3, 1.5, 1.5), cf * CFrame.new(x, 0.75, 0), MAT.Wood, wood, { collide = not broken, name = "PewEnd" })
	end
	-- the rot has climbed it
	for _ = 1, rng:NextInteger(1, 4) do
		boil(cf * CFrame.new(rng:NextNumber(-len / 2, len / 2), rng:NextNumber(0.4, 1.8), rng:NextNumber(-0.6, 0.6)), rng:NextNumber(0.3, 0.8), false)
	end
end

-- a reading stand. returns the open book (for an examine prompt)
function Detail.lectern(pos, facing)
	local cf = CFrame.lookAt(pos, pos + facing)
	d(Vector3.new(1.6, 0.3, 1.6), cf * CFrame.new(0, 0.15, 0), MAT.Wood, C.WoodDark, { collide = true, name = "LecternFoot" })
	d(Vector3.new(0.45, 3.1, 0.45), cf * CFrame.new(0, 1.7, 0), MAT.Wood, C.WoodDark, { collide = true, name = "LecternPost" })
	d(Vector3.new(1.9, 0.18, 1.4), cf * CFrame.new(0, 3.35, 0) * CFrame.Angles(-0.45, 0, 0), MAT.Wood, C.Wood, { name = "LecternTop" })
	local book = d(Vector3.new(1.5, 0.12, 1.05), cf * CFrame.new(0, 3.5, 0.02) * CFrame.Angles(-0.45, 0, 0), MAT.Fabric, Color3.fromRGB(186, 170, 134), { query = true, name = "Register" })
	d(Vector3.new(0.08, 0.14, 1.06), cf * CFrame.new(0, 3.52, 0.02) * CFrame.Angles(-0.45, 0, 0), MAT.Fabric, C.ClothDark, { name = "Spine" })
	-- mould has crept up the post and over one page
	for _ = 1, 4 do
		boil(cf * CFrame.new(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0.3, 2.6), rng:NextNumber(-0.3, 0.3)), rng:NextNumber(0.25, 0.5), false)
	end
	d(Vector3.new(0.6, 0.13, 0.7), cf * CFrame.new(0.4, 3.52, 0.1) * CFrame.Angles(-0.45, 0, 0), MAT.Mud, ROT.FleshDark, { name = "Mould" })
	return book
end

-- a corpse the rot has half swallowed
function Detail.overgrownCorpse(pos, facing)
	Detail.slumpedSkeleton(pos, facing)
	local cf = CFrame.lookAt(pos, pos + facing)
	for _ = 1, rng:NextInteger(4, 8) do
		boil(cf * CFrame.new(rng:NextNumber(-0.9, 0.9), rng:NextNumber(0.2, 1.8), rng:NextNumber(-1.2, 0.5)), rng:NextNumber(0.35, 0.9), rng:NextNumber() < 0.15)
	end
end

return Detail
