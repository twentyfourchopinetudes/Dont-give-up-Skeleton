--!nonstrict
-- How the Wardens are dressed: nothing on them is one big box. The rig's own boxes are shrunk out of sight (G.sink), and what you see
-- is built over them from small parts: rings of overlapping folds round an oval body, wrapped limbs, jointed fists, hoops of short
-- rounded pieces. Every function takes the k that RigBuilder hands to M.Look; sizes are unscaled, like k.V and k.at.
local CollectionService = game:GetService("CollectionService")

local G = {}
local TAU = 2 * math.pi
local CYL = Enum.PartType.Cylinder
G.UP = CFrame.Angles(0, 0, math.pi / 2) -- (a cylinder's axis is its X: this stands it upright)

-- the rig's own boxes, shrunk and darkened inside whatever's built over them
function G.sink(k, names, factor, color)
	for _, n in ipairs(names) do
		local p = k.parts[n]
		if p then
			p.Size *= factor
			p.Color = color
		end
	end
end

-- a ring of cloth folds round an oval: o = { a, c (radii across and front-to-back), top, bottom, n, tiers, color, dark, flare?, name? }.
-- Tiers overlap like shingles, each offset from the last, so no seam runs the whole way down
function G.shell(k, on, rng, o)
	local deco, V, at = k.deco, k.V, k.at
	local tall = (o.top - o.bottom) / o.tiers
	local around = TAU * math.sqrt((o.a * o.a + o.c * o.c) / 2)
	for t = 1, o.tiers do
		local y = o.top - (t - 0.5) * tall
		local grow = 1 + (o.tiers - t) * 0.04 -- (the upper tier lies over the lower)
		for i = 0, o.n - 1 do
			local ang = (i + (t % 2) * 0.5) / o.n * TAU + rng:NextNumber(-0.04, 0.04)
			local x, z = math.sin(ang) * o.a * grow, math.cos(ang) * o.c * grow
			local col = o.color:Lerp(o.dark, rng:NextNumber() ^ 1.4)
			local tilt = -(o.flare or 0.05) + rng:NextNumber(-0.05, 0.05)
			deco(on, o.name or "Fold", V(around / o.n * rng:NextNumber(1.25, 1.55), tall * rng:NextNumber(1.15, 1.4), rng:NextNumber(0.05, 0.09)), at(x, y + rng:NextNumber(-0.03, 0.03), z) * CFrame.Angles(0, ang, 0) * CFrame.Angles(tilt, 0, rng:NextNumber(-0.05, 0.05)), col, k.MAT.Fabric)
		end
	end
end

-- a closed hoop of short rounded pieces, flat in the part's XZ plane, on an oval (a rope, a belt, a rim, a band)
function G.hoop(k, on, y, a, c, n, thick, color, mat, name)
	local deco, V, at = k.deco, k.V, k.at
	local around = TAU * math.sqrt((a * a + c * c) / 2)
	for i = 0, n - 1 do
		local ang = i / n * TAU
		deco(on, name or "Hoop", V(around / n * 1.18, thick, thick), at(math.sin(ang) * a, y, math.cos(ang) * c) * CFrame.Angles(0, ang, 0), color, mat, CYL)
	end
end

-- one flat round slice, stood level
function G.disc(k, on, y, r, h, color, mat, name, tilt)
	k.deco(on, name or "Disc", k.V(h, r * 2, r * 2), k.at(0, y, 0) * CFrame.Angles(tilt or 0, 0, 0) * G.UP, color, mat, CYL)
end

-- a limb bound in strips, top to bottom
function G.wraps(k, on, rng, top, bottom, r, count, color, dark, mat)
	local step = (top - bottom) / count
	for i = 0, count - 1 do
		G.disc(k, on, top - (i + 0.5) * step, r * rng:NextNumber(0.96, 1.05), step * 1.3, color:Lerp(dark, rng:NextNumber()), mat, "Wrap", rng:NextNumber(-0.13, 0.13))
	end
end

-- the fist round a grip: palm, four fingers, thumb. y: its middle on that part. The rig's own square fist goes
function G.fist(k, on, y, w, color, dark)
	local deco, V, at, MAT = k.deco, k.V, k.at, k.MAT
	G.disc(k, on, y + 0.05, w * 0.46, w * 0.72, dark, MAT.Fabric, "Palm")
	for i = 0, 3 do
		local fy = y + w * (0.24 - i * 0.16)
		deco(on, "Finger", V(w * 0.84, w * 0.2, w * 0.2), at(0, fy, -w * 0.36), color, MAT.Fabric, CYL)
		deco(on, "Knuckle", V(w * 0.2, w * 0.2, w * 0.2), at(w * 0.36, fy, -w * 0.24), color, MAT.Fabric, Enum.PartType.Ball)
	end
	deco(on, "Thumb", V(w * 0.62, w * 0.24, w * 0.24), at(-w * 0.34, y + w * 0.1, -w * 0.26) * CFrame.Angles(0, math.pi / 2, 0.4), color, MAT.Fabric, CYL)
end
function G.hideRigFists(k)
	for _, c in ipairs(k.parts.Chest.Parent:GetChildren()) do
		if c.Name == "Fist" then
			c.Transparency = 1
		end
	end
end

-- a boot's foot: rounded lengths side by side, strapped across
function G.foot(k, on, size, color, dark)
	local deco, V, at, MAT = k.deco, k.V, k.at, k.MAT
	local along = CFrame.Angles(0, math.pi / 2, 0)
	for _, x in ipairs({ -0.33, 0, 0.33 }) do
		deco(on, "BootPart", V(size.Z * 0.96, size.X * 0.42, size.X * 0.42), at(x * size.X, 0, 0) * along, color, MAT.Leather, CYL)
	end
	for _, z in ipairs({ -0.28, 0.26 }) do
		deco(on, "BootStrap", V(size.X * 1.14, size.Y * 0.85, 0.09), at(0, 0, z * size.Z), dark, MAT.Leather)
	end
end

-- long cloth to the floor: narrow strips of the game's hanging cloth round an oval, each its own length and shade.
-- o = { a, c, y, n, len (of a segment), color, dark, from?, to? (angles round from the back, in turns) }
function G.skirt(k, on, rng, o)
	local from, to = o.from or 0, o.to or 1
	local around = TAU * math.sqrt((o.a * o.a + o.c * o.c) / 2) * (to - from)
	for i = 0, o.n - 1 do
		local ang = (from + (i + 0.5) / o.n * (to - from)) * TAU
		local col = o.color:Lerp(o.dark, rng:NextNumber())
		local anchor = k.deco(on, "SkirtAnchor", k.V(0.2, 0.2, 0.2), k.at(math.sin(ang) * o.a, o.y, math.cos(ang) * o.c) * CFrame.Angles(0, ang + math.pi, 0), col, k.MAT.SmoothPlastic)
		anchor.Transparency = 1
		anchor:SetAttribute("Drag", 0.95)
		anchor:SetAttribute("Gravity", 1.2)
		anchor:SetAttribute("Segs", 5)
		anchor:SetAttribute("Len", o.len * rng:NextNumber(0.82, 1.08) * k.s)
		anchor:SetAttribute("Width", around / o.n * rng:NextNumber(1.1, 1.45) * k.s)
		anchor:SetAttribute("Color", col)
		CollectionService:AddTag(anchor, "ClothChain")
	end
end

return G
