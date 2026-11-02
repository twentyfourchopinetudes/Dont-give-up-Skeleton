-- PyralisProto: three takes on Pyralis, the boss of the Maw of Pyralis - lion and dragon in one, a blazing mane - set in
-- the arena side by side for choosing between. Prototypes only: no attacks, no AI. Each stands where it's put, turns
-- toward you (a little either way of north, so its length stays on the island), and walks on the spot.
--   server: build(centre) makes the three round the arena's centre (workspace.PyralisProtos)
--   client: animate() moves them - every piece is an anchored part, posed here, locally, each frame
-- A design is a skeleton (bones: a parent, an offset from it, and a pose for the walk's phase) and parts hung on its bones;
-- the server and the client both read it, so a part is found again by its index alone.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local M = {}

local C = Color3.fromRGB
local MAT = Enum.Material
local FUR, FURD = C(156, 104, 52), C(110, 70, 36)
local SCALE, SCALE2 = C(46, 34, 30), C(74, 50, 36)
local BELLY, HORN, IVORY = C(132, 92, 58), C(38, 32, 28), C(206, 192, 160)
local CLAW, EYE = C(26, 22, 20), C(255, 196, 70)
local MANE, WING = C(205, 100, 40), C(66, 26, 20)
local PLATE, GOLD = C(52, 46, 42), C(150, 112, 52)

local sin, max, pi = math.sin, math.max, math.pi
local A = CFrame.Angles
local V = CFrame.new

-- walk pieces: ph is the walk's phase (radians), o a leg's offset in it
local function swing(o, a)
	return function(ph)
		return A(sin(ph + o) * a, 0, 0)
	end
end
local function fold(o, a) -- a joint that bends one way only, as the foot lifts (negative a: the other way)
	return function(ph)
		return A(max(0, sin(ph + o + 1.2)) * a, 0, 0)
	end
end

-- shared builds: a lion's head (on its bone, facing -Z) with horns and a burning mane, and a jaw
local function lionHead(part, fx, head, jaw, k, horns)
	part(head, Vector3.new(5.2, 4.6, 5.6) * k, V(0, 0.6 * k, 0), FUR, MAT.Fabric)
	part(head, Vector3.new(5.6, 1.2, 1.6) * k, V(0, 2.4 * k, -2.6 * k) * A(-0.2, 0, 0), FURD, MAT.Fabric)
	part(head, Vector3.new(3.6, 2.6, 3.6) * k, V(0, -0.6 * k, -4.2 * k), FUR, MAT.Fabric)
	part(head, Vector3.new(1.8, 1, 1) * k, V(0, 0.3 * k, -6.1 * k), CLAW, MAT.SmoothPlastic)
	part(head, Vector3.new(5.2, 2, 2.4) * k, V(0, -2.3 * k, -1.2 * k), FURD, MAT.Fabric) -- (the ruff under the jaw)
	for _, s in ipairs({ -1, 1 }) do
		part(head, Vector3.new(0.9, 0.45, 0.3) * k, V(s * 1.5 * k, 1.4 * k, -2.86 * k), EYE, MAT.Neon)
		part(head, Vector3.new(0.4, 1.3, 0.4) * k, V(s * 1.2 * k, -2.2 * k, -5.4 * k), IVORY, MAT.SmoothPlastic) -- (fangs)
		-- horns, swept back in segments, each thinner and turned further
		local cf = V(s * 2.3 * k, 2.6 * k, 0.8 * k) * A(horns.lift, s * horns.spread, 0)
		local w = horns.width * k
		for i = 1, horns.n do
			local len = horns.len * k * (1 - (i - 1) * 0.12)
			part(head, Vector3.new(w, w, len), cf * V(0, 0, len / 2), i == horns.n and IVORY or HORN, MAT.Slate)
			cf = cf * V(0, 0, len * 0.92) * A(horns.curl, s * horns.twist, 0)
			w *= 0.8
		end
	end
	part(jaw, Vector3.new(3.4, 1.1, 4.4) * k, V(0, -0.3 * k, -3.2 * k), FUR, MAT.Fabric)
	for _, s in ipairs({ -1, 1 }) do
		part(jaw, Vector3.new(0.35, 1.1, 0.35) * k, V(s * 1.1 * k, 0.6 * k, -5 * k), IVORY, MAT.SmoothPlastic)
	end
	-- the mane: a crown of charred, ember-cracked spikes round the back of the head, fire pouring off it
	for i = 1, 16 do
		local a = i / 16 * pi * 2
		local h = (4.5 + (i % 3) * 1.4) * k
		part(head, Vector3.new(1.3, h, 1.7) * k, V(0, 0.4 * k, 1.6 * k) * A(0, 0, a) * V(0, 2.8 * k + h / 2, 0) * A(0.55, 0, 0), MANE, MAT.CrackedLava)
	end
	fx(head, V(0, 3.5 * k, 1.8 * k), 1.3 * k, true)
	fx(head, V(-3 * k, 0.5 * k, 1.8 * k), 0.9 * k)
	fx(head, V(3 * k, 0.5 * k, 1.8 * k), 0.9 * k)
	fx(head, V(0, -2.6 * k, 0.6 * k), 0.8 * k)
end

-- a lion's leg: upper (on the shoulder or hip bone), lower, paw with claws
local function lionLeg(part, up, low, paw, k, hind)
	part(up, Vector3.new(3.6, 5.4, hind and 5 or 4) * k, V(0, -2.4 * k, hind and 0.3 * k or 0), FUR, MAT.Fabric)
	part(low, Vector3.new(2.8, 5, 3) * k, V(0, -2.3 * k, 0), SCALE2, MAT.Slate)
	part(paw, Vector3.new(3.8, 1.5, 4.6) * k, V(0, -0.6 * k, -0.6 * k), FURD, MAT.Fabric)
	for _, x in ipairs({ -1.1, 0, 1.1 }) do
		part(paw, Vector3.new(0.5, 0.6, 1.4) * k, V(x * k, -1 * k, -3.1 * k) * A(-0.3, 0, 0), CLAW, MAT.Slate)
	end
end

-- a dragon's wing on its shoulder bone, reaching out along x (s: -1 left, 1 right)
local function wing(part, w, s, k)
	part(w, Vector3.new(10, 0.9, 0.9) * k, V(s * 5 * k, 0, 0), SCALE, MAT.Slate)
	for i, a in ipairs({ 0.15, 0.55, 0.95 }) do
		local len = (11 - i * 1.5) * k
		part(w, Vector3.new(0.5 * k, 0.5 * k, len), V(s * (10 - i * 1.6) * k, 0, 0) * A(-0.1, s * -a, 0) * V(0, 0, len / 2), SCALE, MAT.Slate)
	end
	part(w, Vector3.new(10, 0.15, 9) * k, V(s * 5.5 * k, -0.2 * k, 4.4 * k) * A(-0.12, s * -0.25, 0), WING, MAT.Fabric)
	part(w, Vector3.new(0.6, 0.6, 2) * k, V(s * 10.3 * k, 0.4 * k, -0.6 * k) * A(0.5, 0, 0), CLAW, MAT.Slate) -- (the thumb claw)
end

-- spines down a back: n blocks on a bone, z from z1 to z2
local function spines(part, b, n, y, z1, z2, h, k)
	for i = 0, n - 1 do
		local z = z1 + (z2 - z1) * i / max(n - 1, 1)
		part(b, Vector3.new(0.9, h, 2) * k, V(0, y * k, z * k) * A(0.45, 0, 0) * V(0, h * k / 2, 0), SCALE, MAT.Slate)
	end
end

local DESIGNS = {}

-- A: THE MANE-WYRM. A great lion on all fours, dragon in its hide: scaled legs, plated haunches, spines down the back, a
-- dragon's tail ending in fire, wings half-raised, a crown of burning mane and swept-back horns.
DESIGNS.A = {
	label = "A - The Mane-Wyrm",
	note = "lion on all fours, dragon's hide, wings, tail",
	speed = 2.4,
	hit = { Vector3.new(12, 14, 14), Vector3.new(0, 7, 0) },
	make = function(bone, part, fx)
		local k = 1
		bone("root", nil, V(0, 12.1, 0), function(ph)
			return V(0, sin(ph * 2) * 0.35, 0) * A(0, 0, sin(ph) * 0.03)
		end)
		bone("chest", "root", V(0, 0.8, -4.5))
		bone("hips", "root", V(0, 0, 4.5))
		bone("neck", "chest", V(0, 2.5, -3.5) * A(0.5, 0, 0), function(ph)
			return A(sin(ph * 2) * 0.04, 0, 0)
		end)
		bone("head", "neck", V(0, 0, -5.5) * A(-0.5, 0, 0), function(ph, t)
			return A(sin(ph * 2 + 0.5) * 0.05, sin(t * 0.7) * 0.12, 0)
		end)
		bone("jaw", "head", V(0, -1.4, -1), function(_, t)
			return A(-(0.12 + sin(t * 1.7) * 0.06), 0, 0)
		end)
		for _, s in ipairs({ -1, 1 }) do
			local n = s < 0 and "L" or "R"
			local of, ob = s < 0 and 0 or pi, s < 0 and pi or 0 -- (diagonal pairs: front left with hind right)
			bone("F" .. n, "chest", V(s * 3.4, -1.5, -1), swing(of, 0.45))
			bone("F" .. n .. "k", "F" .. n, V(0, -4.8, 0), fold(of, -0.8))
			bone("F" .. n .. "p", "F" .. n .. "k", V(0, -4.6, 0), fold(of, 0.5))
			bone("B" .. n, "hips", V(s * 3.2, -1, 0.5), swing(ob, 0.4))
			bone("B" .. n .. "k", "B" .. n, V(0, -4.6, 0.4), fold(ob, 0.9))
			bone("B" .. n .. "p", "B" .. n .. "k", V(0, -4.2, 0), fold(ob, -0.6))
			bone("W" .. n, "chest", V(s * 3.8, 3.8, 1) * A(0, 0, s * 0.55), function(ph)
				return A(0, 0, s * sin(ph) * 0.08)
			end)
		end
		local prev = "hips"
		for i, off in ipairs({ V(0, 1, 4) * A(0.3, 0, 0), V(0, 0, 4.5), V(0, 0, 4), V(0, 0, 3.5) * A(-0.25, 0, 0) }) do
			bone("T" .. i, prev, off, function(ph)
				return A(0, sin(ph * 0.5 + i * 0.7) * 0.22, 0)
			end)
			prev = "T" .. i
		end

		part("root", Vector3.new(8.5, 7.5, 10), V(), FUR, MAT.Fabric)
		part("root", Vector3.new(7, 1, 9), V(0, -3.6, 0), BELLY, MAT.Fabric)
		part("chest", Vector3.new(10.5, 9.5, 8), V(), FUR, MAT.Fabric)
		part("chest", Vector3.new(8, 6, 1), V(0, -0.5, -4.1) * A(0.15, 0, 0), SCALE2, MAT.Slate)
		part("hips", Vector3.new(9, 8, 8), V(), FUR, MAT.Fabric)
		for _, s in ipairs({ -1, 1 }) do
			part("chest", Vector3.new(4, 4, 5), V(s * 4.2, 1.6, -0.5), FURD, MAT.Fabric) -- (shoulders)
			part("hips", Vector3.new(2, 5, 6), V(s * 4.6, 0.5, 0), SCALE, MAT.Slate) -- (plated haunches)
		end
		spines(part, "chest", 2, 4.6, -2, 1.5, 3, k)
		spines(part, "root", 2, 3.6, -2, 2, 2.6, k)
		spines(part, "hips", 2, 3.8, -1.5, 2.5, 2.2, k)
		part("neck", Vector3.new(5.5, 6, 7), V(0, 0, -2.5), FURD, MAT.Fabric)
		part("neck", Vector3.new(3.6, 1, 6), V(0, -3, -2.5), BELLY, MAT.Fabric)
		for i = 0, 4 do -- (the mane runs down the neck)
			part("neck", Vector3.new(1.2, 3.5 + i % 2, 1.6), V(0, 3, -4.5 + i * 1.6) * A(0.6, 0, 0) * V(0, 1.6, 0), MANE, MAT.CrackedLava)
		end
		fx("neck", V(0, 3.5, -2.5), 1)
		lionHead(part, fx, "head", "jaw", k, { lift = 0.5, spread = 0.35, len = 4, width = 1.3, n = 3, curl = 0.35, twist = 0.1 })
		for _, n in ipairs({ "L", "R" }) do
			lionLeg(part, "F" .. n, "F" .. n .. "k", "F" .. n .. "p", k)
			lionLeg(part, "B" .. n, "B" .. n .. "k", "B" .. n .. "p", k, true)
			wing(part, "W" .. n, n == "L" and -1 or 1, k)
		end
		for i, w in ipairs({ 3, 2.4, 1.8, 1.2 }) do
			part("T" .. i, Vector3.new(w, w, 4.6), V(0, 0, 2.2), SCALE, MAT.Slate)
			part("T" .. i, Vector3.new(0.6, w * 0.8, 1.4), V(0, w * 0.6, 1.5) * A(0.5, 0, 0), SCALE2, MAT.Slate)
		end
		fx("T4", V(0, 0, 4), 0.9) -- (a lion's tuft, of fire)
	end,
}

-- B: THE LION-KNIGHT. Upright and enormous: barrel chest and a lion's head, digitigrade legs, clawed hands in iron bracers,
-- dark plate at the shoulders, great wings spread behind, a dragon's tail, the mane falling down the shoulders in flame.
DESIGNS.B = {
	label = "B - The Lion-Knight",
	note = "upright, armoured, wings spread",
	speed = 2,
	hit = { Vector3.new(11, 22, 9), Vector3.new(0, 11, 0) },
	make = function(bone, part, fx)
		local k = 0.95
		bone("root", nil, V(0, 11.8, 0), function(ph)
			return V(0, -math.cos(ph * 2) * 0.3, 0) * A(0, sin(ph) * 0.06, 0)
		end)
		bone("torso", "root", V(0, 2, 0) * A(-0.18, 0, 0), function(ph)
			return A(0, -sin(ph) * 0.08, 0)
		end)
		bone("chest", "torso", V(0, 4, 0))
		bone("neck", "chest", V(0, 4.2, -0.8) * A(0.25, 0, 0))
		bone("head", "neck", V(0, 2.4, -1) * A(-0.1, 0, 0), function(ph, t)
			return A(sin(ph * 2) * 0.04, sin(t * 0.6) * 0.1, 0)
		end)
		bone("jaw", "head", V(0, -1.3, -1), function(_, t)
			return A(-(0.1 + sin(t * 1.5) * 0.06), 0, 0)
		end)
		for _, s in ipairs({ -1, 1 }) do
			local n = s < 0 and "L" or "R"
			local ol, oa = s < 0 and 0 or pi, s < 0 and pi or 0 -- (each arm swings with the other leg)
			bone("S" .. n, "chest", V(s * 5.8, 2.4, 0), function(ph)
				return A(sin(ph + oa) * 0.4, 0, s * 0.14)
			end)
			bone("E" .. n, "S" .. n, V(0, -5, 0), function(ph)
				return A(0.4 + max(0, sin(ph + oa)) * 0.4, 0, 0)
			end)
			bone("H" .. n, "E" .. n, V(0, -5, 0))
			bone("L" .. n, "root", V(s * 2.6, -1, 0), function(ph)
				return A(sin(ph + ol) * 0.5 + 0.25, 0, 0)
			end)
			bone("K" .. n, "L" .. n, V(0, -5, 0) * A(-0.75, 0, 0), fold(ol, -0.7))
			bone("P" .. n, "K" .. n, V(0, -5, 0) * A(0.5, 0, 0), fold(ol, 0.5))
			bone("W" .. n, "chest", V(s * 2.2, 2.6, 2.4) * A(-0.35, s * 0.35, s * 0.85), function(ph)
				return A(0, 0, s * sin(ph) * 0.06)
			end)
		end
		local prev = "root"
		for i, off in ipairs({ V(0, -0.5, 2.2) * A(0.6, 0, 0), V(0, 0, 4.4), V(0, 0, 4), V(0, 0, 3.4) * A(-0.3, 0, 0) }) do
			bone("T" .. i, prev, off, function(ph)
				return A(0, sin(ph * 0.5 + i * 0.7) * 0.25, 0)
			end)
			prev = "T" .. i
		end

		part("root", Vector3.new(6.4, 3.6, 4.6) * k, V(), SCALE, MAT.Slate)
		part("root", Vector3.new(7, 1, 5.2) * k, V(0, 1.2, 0), PLATE, MAT.Metal) -- (a war-belt)
		part("torso", Vector3.new(6.6, 4.6, 4.4) * k, V(0, 0.4, 0), BELLY, MAT.Fabric)
		for r = 0, 1 do
			for _, s in ipairs({ -1, 1 }) do
				part("torso", Vector3.new(2.6, 1.7, 0.6) * k, V(s * 1.45, (-0.6 + r * 1.9) * k, -2.3 * k), SCALE2, MAT.Slate)
			end
		end
		part("chest", Vector3.new(10.5, 6.2, 5.6) * k, V(0, 0.4, 0), FUR, MAT.Fabric)
		for _, s in ipairs({ -1, 1 }) do
			part("chest", Vector3.new(4.6, 3.2, 1.2) * k, V(s * 2.4 * k, 0.8 * k, -2.9 * k), FURD, MAT.Fabric) -- (pecs)
		end
		spines(part, "chest", 3, 3, 0.5, 3, 3, k)
		part("neck", Vector3.new(4.6, 4.4, 4.4) * k, V(0, 0.6, 0), FURD, MAT.Fabric)
		for i = 0, 5 do -- (the mane falls down over the shoulders and back)
			local a = (i - 2.5) * 0.5
			part("chest", Vector3.new(1.3, 5 + i % 2 * 1.5, 1.8) * k, V(0, 3.4 * k, 1 * k) * A(0, a, 0) * V(0, 0, 2.2 * k) * A(1, 0, 0) * V(0, 2.4 * k, 0), MANE, MAT.CrackedLava)
		end
		fx("chest", V(0, 4, 1.8), 1.2)
		fx("chest", V(-3.4, 3.4, 0.8), 0.9)
		fx("chest", V(3.4, 3.4, 0.8), 0.9)
		lionHead(part, fx, "head", "jaw", 0.9, { lift = 0.9, spread = 0.2, len = 3.4, width = 1.4, n = 4, curl = -0.15, twist = 0.35 })
		for _, n in ipairs({ "L", "R" }) do
			local s = n == "L" and -1 or 1
			part("S" .. n, Vector3.new(3.2, 5.2, 3.2) * k, V(0, -2.5, 0), FUR, MAT.Fabric)
			part("S" .. n, Vector3.new(4.8, 2.3, 5.2) * k, V(s * 0.4, 0.6, 0), PLATE, MAT.Metal) -- (pauldron)
			part("S" .. n, Vector3.new(5, 0.4, 5.4) * k, V(s * 0.4, -0.5, 0), GOLD, MAT.Metal)
			part("E" .. n, Vector3.new(2.7, 5, 2.7) * k, V(0, -2.5, 0), SCALE2, MAT.Slate)
			part("E" .. n, Vector3.new(3, 2.2, 3) * k, V(0, -3.6, 0), PLATE, MAT.Metal) -- (bracer)
			part("H" .. n, Vector3.new(2.6, 2.2, 2.4) * k, V(0, -1, 0), FURD, MAT.Fabric)
			for _, x in ipairs({ -0.9, -0.3, 0.3, 0.9 }) do
				part("H" .. n, Vector3.new(0.35, 1.5, 0.35) * k, V(x, -2.5, -0.5) * A(-0.35, 0, 0), CLAW, MAT.Slate)
			end
			part("L" .. n, Vector3.new(3.8, 5.6, 4.2) * k, V(0, -2.5, 0), FUR, MAT.Fabric)
			part("K" .. n, Vector3.new(2.5, 5.4, 2.5) * k, V(0, -2.5, 0), SCALE2, MAT.Slate)
			part("P" .. n, Vector3.new(3.2, 1.4, 5.2) * k, V(0, -0.5, -1.4), FURD, MAT.Fabric)
			for _, x in ipairs({ -1, 0, 1 }) do
				part("P" .. n, Vector3.new(0.5, 0.7, 1.5) * k, V(x, -0.8, -4.3) * A(-0.3, 0, 0), CLAW, MAT.Slate)
			end
			wing(part, "W" .. n, s, 1.15)
		end
		for i, w in ipairs({ 2.8, 2.2, 1.7, 1.1 }) do
			part("T" .. i, Vector3.new(w, w, 4.6) * k, V(0, 0, 2.2), SCALE, MAT.Slate)
		end
		fx("T4", V(0, 0, 3.8), 0.8)
	end,
}

-- C's forelegs: knotted together out of many pieces - lumps of muscle, knuckles, tendons, spurs - and not quite a pair:
-- the right swollen bigger, the left with a toe too many crowded in. s: -1 left, 1 right
local BALL, CYL = Enum.PartType.Ball, Enum.PartType.Cylinder
local UPRIGHT = A(0, 0, pi / 2) -- (a cylinder's length runs along x: this stands it up)
local function shaped(part) -- ball(bone, diameter, ...) and rod(bone, length, diameter, ...), standing along the cf's y
	return function(b, d, cf, col, mat)
		part(b, Vector3.one * d, cf, col, mat or MAT.Fabric, BALL)
	end, function(b, len, d, cf, col, mat)
		part(b, Vector3.new(len, d, d), cf * UPRIGHT, col, mat or MAT.Fabric, CYL)
	end
end
local function watchdogLeg(part, up, low, paw, s)
	local ball, rod = shaped(part)
	local sw = s > 0 and 1.18 or 1 -- (the right arm swollen)
	-- upper arm: a thick core with muscle knotted round it, unevenly
	ball(up, 4.4 * sw, V(s * 0.3, 0.3, 0), FURD) -- (the shoulder)
	rod(up, 4.6, 3, V(0, -2, 0) * A(0.08, 0, s * 0.07), FUR)
	ball(up, 3.2 * sw, V(0, -1.4, -1), FUR)
	ball(up, 2.8, V(-s * 0.3, -2.2, 1.1), FURD)
	ball(up, 2.4 * sw, V(s * 1.3, -1, 0.2), FUR)
	ball(up, 2, V(-s * 1, -3, -0.4), FURD)
	for i, z in ipairs({ -0.6, 0.1, 0.8 }) do -- (matted fur hanging in clumps off the outside)
		part(up, Vector3.new(0.8, 2.2, 0.7), V(s * 1.8, -1.4 - i * 0.5, z) * A(0.2, 0, s * 0.35), FURD, MAT.Fabric)
	end
	if s > 0 then -- (a growth on the swollen one: a cluster of blisters)
		for _, g in ipairs({ { 1.2, 2, -0.2, -1.6 }, { 0.9, 2.5, -0.9, -1.3 }, { 0.7, 2.2, -1.2, -2.2 } }) do
			ball(up, g[1], V(g[2], g[3], g[4]), BELLY)
		end
	end
	-- the knee: a knob of bone, a spur driven out the back of it
	ball(up, 2.9, V(0, -4, 0.2), SCALE2, MAT.Slate)
	part(up, Vector3.new(0.55, 0.55, 2.2), V(0, -3.7, 1.4) * A(-0.6, s * 0.2, 0) * V(0, 0, 1), IVORY, MAT.SmoothPlastic)
	-- shin: tapering, tendons standing proud down the back, scales overlapping and not quite lined up
	rod(low, 3.8, 2.4, V(0, -1.7, 0) * A(-0.05, 0, -s * 0.05), SCALE2, MAT.Slate)
	ball(low, 2.3, V(0, -0.6, -0.5), FUR)
	ball(low, 1.9, V(s * 0.6, -1.8, -0.6), FURD)
	for _, x in ipairs({ -0.55, 0.55 }) do
		rod(low, 3.4, 0.45, V(x, -1.6, 1.05) * A(0.1, 0, 0), BELLY)
	end
	for i = 0, 3 do
		part(low, Vector3.new(1.8 - i * 0.15, 0.3, 1.2), V(s * 0.1 * i, -0.4 - i * 0.8, -1.2) * A(-1.1, 0, i % 2 == 0 and 0.15 or -0.2), SCALE, MAT.Slate)
	end
	ball(low, 2.2, V(0, -3.4, 0), FURD) -- (the ankle)
	-- paw: a heel mass and knuckled toes, each two knuckles and a claw hooking down
	ball(paw, 3, V(0, -0.3, 0.2), FURD)
	for j, x in ipairs(s < 0 and { -1.5, -0.6, 0.2, 1.1 } or { -1.2, 0, 1.3 }) do
		local d = 1.3 + (j % 2) * 0.25
		local cf = V(x, -0.9, -1.3) * A(0, -x * 0.12, 0)
		ball(paw, d, cf, FUR)
		ball(paw, d * 0.8, cf * V(0, -0.1, -1), FURD)
		local c = cf * V(0, -0.2, -1.7) * A(-0.5, 0, 0)
		part(paw, Vector3.new(0.5, 0.45, 1), c, CLAW, MAT.Slate)
		part(paw, Vector3.new(0.32, 0.3, 0.8), c * V(0, -0.15, -0.7) * A(-0.5, 0, 0), CLAW, MAT.Slate)
	end
	part(paw, Vector3.new(0.4, 0.4, 1.1), V(-s * 1.4, 0.4, 0.3) * A(0.6, 0, 0), IVORY, MAT.SmoothPlastic) -- (the dewclaw)
end

-- C: THE MALFORMED WATCHDOG (once the Sun-Serpent), the one to build on. A lion's forequarters on a dragon-worm's body: no hind legs - past the chest it
-- slumps to the ground and drags, a long ringed and plated worm-back rippling as it hauls itself on by its forelegs. Its
-- mane a wheel of fire turning behind the head; its face crushed flat into a nightmare (nightmareFace).
local function nightmareFace(part, fx, head, jaw)
	-- the skull crushed flat and wide, the brow slipped askew, the muzzle shoved in
	part(head, Vector3.new(7, 2.8, 5.2), V(0, 0.2, 0), FUR, MAT.Fabric)
	part(head, Vector3.new(7.6, 1, 2.2), V(0.3, 1.4, -2.2) * A(-0.35, 0.1, 0.12), FURD, MAT.Fabric)
	part(head, Vector3.new(5.4, 1.8, 2.4), V(-0.2, -0.6, -3.4) * A(0, -0.08, -0.06), FUR, MAT.Fabric)
	part(head, Vector3.new(6.6, 1.6, 2.6), V(0, -1.6, -0.8), FURD, MAT.Fabric) -- (the ruff, crushed up under it)
	-- where the nose should be: a hole ringed with small teeth
	part(head, Vector3.new(2.2, 1.3, 0.4), V(0.3, -0.3, -4.65) * A(0, 0, 0.2), CLAW, MAT.SmoothPlastic)
	for i = 1, 7 do
		local a = i / 7 * pi * 2
		part(head, Vector3.new(0.22, 0.6, 0.22), V(0.3, -0.3, -4.75) * A(0, 0, a) * V(0, 0.75, 0) * A(0, 0, pi), IVORY, MAT.SmoothPlastic)
	end
	-- eyes that don't agree: sizes, colours, angles, places
	for _, e in ipairs({
		{ -2.6, 0.9, -2.6, 0.9, 0, EYE },
		{ -1.1, 1.05, -3.05, 0.45, 0.3, EYE },
		{ 1.9, 0.7, -2.85, 1.15, 0.6, C(232, 240, 200) },
		{ 2.95, -0.2, -2.2, 0.4, -0.9, EYE },
		{ 0.4, 1.7, -2.6, 0.3, pi / 2, C(255, 70, 30) },
		{ -3.3, -0.5, -1.4, 0.6, 1.2, C(255, 70, 30) },
	}) do
		part(head, Vector3.new(e[4], e[4] * 0.5, 0.3), V(e[1], e[2], e[3]) * A(0, 0, e[5]), e[6], MAT.Neon)
	end
	-- fangs hanging from the brow, where no teeth belong; a second mouth slit up the right cheek, toothed
	for x = -2.8, 2.8, 1.4 do
		part(head, Vector3.new(0.3, 1 + math.abs(x) * 0.15, 0.3), V(x, 0.6, -3.25) * A(0.2, 0, x * 0.05), IVORY, MAT.SmoothPlastic)
	end
	part(head, Vector3.new(0.35, 1.8, 2.6), V(3.55, -0.4, -1.2) * A(0, 0, 0.3), CLAW, MAT.SmoothPlastic)
	for z = -2.2, -0.2, 0.7 do
		part(head, Vector3.new(0.5, 0.2, 0.2), V(3.5, -0.4 + z * 0.15, z) * A(0, 0, 0.3), IVORY, MAT.SmoothPlastic)
	end
	-- shards jutting out of the face at angles that make no sense
	for _, sh in ipairs({
		{ -1.8, 1.6, -1.2, 3, 0.9, 0.4, -0.7 },
		{ 2.4, 1.2, -0.6, 2.4, -0.4, 1.1, 0.5 },
		{ -3.4, 0.4, -0.2, 2, 0.2, -1.3, 1.4 },
		{ 0.9, -1.2, -3.6, 1.6, -1.2, 0.3, 0.2 },
		{ 3.1, 1.5, 0.8, 2.8, 1.4, 0.6, -1 },
		{ -0.6, 2, 0.6, 2.2, -0.2, -0.5, 0.9 },
	}) do
		part(head, Vector3.new(0.55, 0.55, sh[4]), V(sh[1], sh[2], sh[3]) * A(sh[5], sh[6], sh[7]) * V(0, 0, -sh[4] / 2), sh[4] > 2.5 and HORN or SCALE2, MAT.Slate)
	end
	-- horns that don't match: a ram's curl on the left, a long spike and a broken stub on the right
	local function horn(cf, w, len, n, curl, twist)
		for i = 1, n do
			local l = len * (1 - (i - 1) * 0.12)
			part(head, Vector3.new(w, w, l), cf * V(0, 0, l / 2), i == n and IVORY or HORN, MAT.Slate)
			cf = cf * V(0, 0, l * 0.92) * A(curl, twist, 0)
			w *= 0.8
		end
	end
	horn(V(-3, 1.2, 0.6) * A(0.2, -0.9, 0), 1.7, 2.6, 5, 0.9, 0)
	horn(V(3, 1.3, 0.4) * A(0.7, 0.5, -0.3), 1.2, 5.5, 2, 0.05, 0.1)
	horn(V(1.4, 1.5, 1.4) * A(1.2, 0.2, 0), 1.1, 1.4, 1, 0, 0)
	-- the jaw split in three: two mandibles that close sideways and a short lower one, all toothed inward
	for _, s in ipairs({ -1, 1 }) do
		part(jaw, Vector3.new(1.6, 0.9, 4.2), V(s * 1.7, -0.2, -2.6) * A(0, s * 0.25, s * 0.2), FUR, MAT.Fabric)
		for z = -4, -1.6, 0.8 do
			part(jaw, Vector3.new(0.9, 0.25, 0.25), V(s * 1.05, -0.1, z) * A(0, 0, s * 0.2), IVORY, MAT.SmoothPlastic)
		end
	end
	part(jaw, Vector3.new(2.2, 0.7, 3), V(0, -0.9, -2.2) * A(0.2, 0, 0), FURD, MAT.Fabric)
	for x = -0.7, 0.7, 0.7 do
		part(jaw, Vector3.new(0.25, 0.9, 0.25), V(x, -0.3, -3.4), IVORY, MAT.SmoothPlastic)
	end
	fx(head, V(0, 1.6, 1.2), 1.1, true)
	fx(head, V(0, -1.8, -1.2), 0.7) -- (fire from the throat)
end

-- the True Watchdog's face: its brother's nightmare, but every horror mirrored - as if it were made that way on purpose
local function trueFace(part, fx, head, jaw, k)
	local function P(b, size, cf, col, mat)
		part(b, size * k, cf - cf.Position + cf.Position * k, col, mat)
	end
	P(head, Vector3.new(7, 2.8, 5.2), V(0, 0.2, 0), FUR, MAT.Fabric) -- (the skull, wide and flat)
	P(head, Vector3.new(7.6, 1, 2.2), V(0, 1.4, -2.2) * A(-0.35, 0, 0), FURD, MAT.Fabric)
	P(head, Vector3.new(5.4, 1.8, 2.4), V(0, -0.6, -3.4), FUR, MAT.Fabric)
	P(head, Vector3.new(6.6, 1.6, 2.6), V(0, -1.6, -0.8), FURD, MAT.Fabric)
	P(head, Vector3.new(2.2, 1.3, 0.4), V(0, -0.3, -4.65), CLAW, MAT.SmoothPlastic) -- (the nose a toothed hole)
	for i = 1, 8 do
		P(head, Vector3.new(0.22, 0.6, 0.22), V(0, -0.3, -4.75) * A(0, 0, i / 8 * pi * 2) * V(0, 0.75, 0) * A(0, 0, pi), IVORY, MAT.SmoothPlastic)
	end
	P(head, Vector3.new(0.35, 1.1, 0.3), V(0, 1.75, -2.75), C(255, 50, 25), MAT.Neon) -- (a third eye, slit upright in the brow)
	for x = -2.8, 2.8, 1.4 do -- (fangs hanging from the brow)
		P(head, Vector3.new(0.3, 1 + math.abs(x) * 0.15, 0.3), V(x, 0.6, -3.25) * A(0.2, 0, x * 0.05), IVORY, MAT.SmoothPlastic)
	end
	for _, s in ipairs({ -1, 1 }) do
		for _, e in ipairs({ -- (eyes in mirrored rows: { x, y, z, size, tilt, colour })
			{ 2.5, 0.9, -2.65, 0.95, 0.3, EYE },
			{ 1.15, 1.1, -3.05, 0.45, 0.5, EYE },
			{ 3.1, -0.2, -2.2, 0.45, -0.9, C(255, 50, 25) },
			{ 1.9, -0.25, -3.2, 0.35, 0.2, C(255, 50, 25) },
		}) do
			P(head, Vector3.new(e[4], e[4] * 0.5, 0.3), V(s * e[1], e[2], e[3]) * A(0, 0, s * e[5]), e[6], MAT.Neon)
		end
		P(head, Vector3.new(0.35, 1.8, 2.6), V(s * 3.55, -0.4, -1.2) * A(0, 0, s * 0.3), CLAW, MAT.SmoothPlastic) -- (a mouth up each cheek)
		for z = -2.2, -0.2, 0.7 do
			P(head, Vector3.new(0.5, 0.2, 0.2), V(s * 3.5, -0.4 + z * 0.15, z) * A(0, 0, s * 0.3), IVORY, MAT.SmoothPlastic)
		end
		for _, sh in ipairs({ { 1.8, 1.6, -1.2, 3, 0.9, 0.4, -0.7 }, { 3.4, 0.4, -0.2, 2, 0.2, 1.3, -1.4 }, { 1, -1.2, -3.6, 1.6, -1.2, 0.3, 0.2 } }) do
			P(head, Vector3.new(0.55, 0.55, sh[4]), V(s * sh[1], sh[2], sh[3]) * A(sh[5], s * sh[6], s * sh[7]) * V(0, 0, -sh[4] / 2), sh[4] > 2.5 and HORN or SCALE2, MAT.Slate)
		end
		-- horns: a matched pair sweeping back and up, and a short stub inside each
		local cf, w = V(s * 3, 1.3, 0.4) * A(0.5, s * 0.6, -s * 0.3), 1.4
		for i = 1, 5 do
			local l = 3.4 * (1 - (i - 1) * 0.12)
			P(head, Vector3.new(w, w, l), cf * V(0, 0, l / 2), i == 5 and IVORY or HORN, MAT.Slate)
			cf = cf * V(0, 0, l * 0.92) * A(0.28, s * 0.12, 0)
			w *= 0.8
		end
		P(head, Vector3.new(1, 1, 1.4), V(s * 1.4, 1.5, 1.4) * A(1.2, s * 0.2, 0) * V(0, 0, 0.7), HORN, MAT.Slate)
		-- the jaw split in three: two mandibles closing sideways, toothed inward
		P(jaw, Vector3.new(1.6, 0.9, 4.2), V(s * 1.7, -0.2, -2.6) * A(0, s * 0.25, s * 0.2), FUR, MAT.Fabric)
		for z = -4, -1.6, 0.8 do
			P(jaw, Vector3.new(0.9, 0.25, 0.25), V(s * 1.05, -0.1, z) * A(0, 0, s * 0.2), IVORY, MAT.SmoothPlastic)
		end
	end
	P(jaw, Vector3.new(2.2, 0.7, 3), V(0, -0.9, -2.2) * A(0.2, 0, 0), FURD, MAT.Fabric)
	for x = -0.7, 0.7, 0.7 do
		P(jaw, Vector3.new(0.25, 0.9, 0.25), V(x, -0.3, -3.4), IVORY, MAT.SmoothPlastic)
	end
	for i = 1, 14 do -- the mane: a crown of ember-cracked spikes, mirrored (cos 3a is the same either side)
		local a = i / 14 * pi * 2
		local h = 4 + 1.2 * (1 + math.cos(a * 3))
		P(head, Vector3.new(1.2, h, 1.5), V(0, 0.6, 1.4) * A(0, 0, a) * V(0, 2.6 + h / 2, 0) * A(0.55, 0, 0), MANE, MAT.CrackedLava)
	end
	fx(head, V(0, 2.4 * k, 1.4 * k), 1.1 * k, true)
	fx(head, V(0, -1.8 * k, -1.2 * k), 0.7 * k) -- (fire from the throat)
	for _, s in ipairs({ -1, 1 }) do
		fx(head, V(s * 2.6 * k, 0.6 * k, 1.4 * k), 0.8 * k)
	end
end

DESIGNS.C = {
	label = "C - The Malformed Watchdog",
	note = "lion's front, a dragon-worm behind, a wheel of fire, a nightmare face",
	speed = 2.2,
	turn = 0.35, -- (it's long: it turns only a little, so its tail stays on the island)
	hit = { Vector3.new(11, 12, 7), Vector3.new(0, 6, 0.5) }, -- (just its bulk behind the forelegs: you can walk right up to its front feet)
	make = function(bone, part, fx)
		bone("root", nil, V(0, 10.8, -6), function(ph)
			return V(0, sin(ph * 2) * 0.3, 0) * A(sin(ph * 2) * 0.03, 0, 0)
		end)
		-- c (from its entrance, else nil): stare 0..1, how hard it's fixed on you; halo, the wheel's angle; strain 0..1, it
		-- dragging itself (neck thrust low and forward, face kept up); gape, how wide the jaw's wrenched; legs, the forelegs'
		-- { swing, knee, paw } each side
		bone("neck", "root", V(0, 2.4, -3) * A(0.45, 0, 0), function(ph, _, c)
			return A(sin(ph * 2) * 0.05 + (c and c.stare or 0) * 0.12 - (c and c.strain or 0) * 0.45 + (c and c.rear or 0) * 0.5, sin(ph * 0.6) * 0.08 + (c and c.lead or 0) * 0.45, 0)
		end)
		bone("head", "neck", V(0, 0, -4.6) * A(-0.55, 0, 0), function(_, t, c)
			-- it twitches: a jerk of the head now and then
			local jerk = sin(t * 0.7) > 0.75 and sin(t * 23) * 0.06 or 0
			local idle = A(jerk + (c and c.strain or 0) * 0.35, sin(t * 0.8) * 0.1, sin(t * 0.5) * 0.12 + jerk)
			local s = c and c.stare or 0
			-- staring: the sway gone out of it, the head thrust at you, cocked, dead still but for a tremble
			local look = s > 0 and idle:Lerp(A(-0.2 + sin(t * 31) * 0.012, sin(t * 27) * 0.01, 0.14 + sin(t * 37) * 0.012), s) or idle
			return A(0, (c and c.lead or 0) * 0.4, 0) * look -- (turning: the head comes round first)
		end)
		bone("jaw", "head", V(0, -1.2, -0.8), function(_, t, c)
			local s = math.max(c and c.stare or 0, c and c.gape or 0)
			return A(-(0.25 + s * 0.3 + sin(t * 1.3) * 0.15 * (1 - s)), sin(t * 2.7) * 0.06, sin(t * 3.1) * 0.05)
		end)
		bone("halo", "head", V(0, 0.8, 2.6), function(_, t, c)
			return A(0, 0, c and c.halo or t * 0.5)
		end)
		for _, s in ipairs({ -1, 1 }) do
			local n = s < 0 and "L" or "R"
			local of = s < 0 and 0 or pi
			local sw, kn, pw = swing(of, 0.45), fold(of, -0.8), fold(of, 0.5)
			bone("F" .. n, "root", V(s * 3.4, -1.5, -0.5), function(ph, _, c)
				return c and c.legs and A(c.legs[n][1], 0, 0) or sw(ph)
			end)
			bone("F" .. n .. "k", "F" .. n, V(0, -4, 0), function(ph, _, c)
				return c and c.legs and A(c.legs[n][2], 0, 0) or kn(ph)
			end)
			bone("F" .. n .. "p", "F" .. n .. "k", V(0, -3.4, 0), function(ph, _, c)
				return c and c.legs and A(c.legs[n][3], 0, 0) or pw(ph)
			end)
		end
		-- the worm-back: down from the chest to the ground, then dragging along it, rippling side to side and humping a little
		local SAG = { -1.6, -2.2, -2, -0.6, -0.8, -0.5, -0.3, -0.2 } -- (each segment's drop below the last: on the ground by the fourth)
		local prev = "root"
		for i = 1, 8 do
			bone("S" .. i, prev, V(0, SAG[i], i == 1 and 4.5 or 3.6), function(ph, _, c)
				local coil = (c and c.coil or 0) * (i <= 4 and 0.2 or -0.24) -- (curled into an S: the front half one way, the back the other)
				coil += c and c.drag and c.drag[i] or 0 -- (turning: each segment dragged round after the one before it)
				local rise = i == 4 and c and c.rise or 0 -- (rearing up about this joint: from here back it stays on the floor)
				return A(-rise, 0, 0) * V(0, i > 3 and math.max(0, sin(ph * 0.6 - i * 0.9)) * 0.5 or 0, 0) * A(0, sin(ph * 0.6 - i * 0.8) * 0.2 + coil, 0)
			end)
			prev = "S" .. i
		end
		bone("T1", "S8", V(0, 0, 3), function(ph, _, c)
			return A(0, sin(ph * 0.6 - 7.2) * 0.25 + (c and c.drag and c.drag[9] or 0), 0)
		end)
		bone("T2", "T1", V(0, 0, 2.6), function(ph, _, c)
			return A(-0.15, sin(ph * 0.6 - 8) * 0.3 + (c and c.drag and c.drag[10] or 0), 0)
		end)

		-- the chest: a heap of muscle, not a box - pecs that sag unevenly, a knuckled breastbone, ribs showing on the flanks
		local ball, rod = shaped(part)
		local ALONG = A(pi / 2, 0, 0) -- (turns a rod to run along z)
		ball("root", 8, V(0, 0.5, 0.5), FUR)
		ball("root", 7.5, V(0, -1, -0.8), FUR)
		ball("root", 6.5, V(0, 2, 2.2), FURD) -- (the hump behind the shoulders)
		for _, s in ipairs({ -1, 1 }) do
			local sw = s > 0 and 1.18 or 1 -- (the right side swollen, like its arm)
			local sag = s < 0 and -0.6 or 0 -- (the left pec hangs lower)
			ball("root", 4.6 * sw, V(s * 2.2, 0.2 + sag, -2.6), FUR)
			ball("root", 3.6, V(s * 2, -1.6 + sag, -2.4), FURD)
			ball("root", 4.2 * sw, V(s * 3.8, 1.8, -0.5), FURD) -- (the shoulder)
			ball("root", 2.6, V(s * 3.2, 3.2, 0.6), FUR)
			for i = 1, 4 do
				rod("root", 5 - i * 0.4, 0.5, V(s * (4.1 - i * 0.15), 1.6 - i * 1.3, 0.8) * ALONG * A(0, 0, s * (0.15 + i * 0.05)), SCALE2, MAT.Slate)
			end
		end
		for i, y in ipairs({ 1.5, 0.4, -0.7, -1.8, -2.9 }) do
			ball("root", 1.3 - i * 0.08, V((i % 2) * 0.3 - 0.15, y, -4 + math.abs(y) * 0.12), IVORY, MAT.SmoothPlastic)
		end
		ball("root", 5, V(0, -3.2, 0.3), BELLY)
		ball("root", 3.6, V(-0.8, -3.6, -1), BELLY)
		ball("root", 3.2, V(1, -3.4, 1.2), BELLY)
		-- the neck: a thick trunk, lumped, a goitre swelling the throat, cords standing out down each side
		rod("neck", 6.5, 5, V(0, 0, -2.2) * ALONG, FURD)
		ball("neck", 4.6, V(0, 0.6, -0.6), FUR)
		ball("neck", 4, V(0.4, -0.4, -3.4), FURD)
		ball("neck", 3, V(-0.6, -1.8, -2.2), BELLY)
		for _, s in ipairs({ -1, 1 }) do
			rod("neck", 6, 0.6, V(s * 2.1, -0.6, -2.2) * ALONG * A(0, 0, s * 0.15), FUR)
		end
		for i, w in ipairs({ 8.6, 8, 7.4, 6.8, 6.1, 5.4, 4.7, 4 }) do
			local seg = "S" .. i
			local col, mat = i == 1 and FUR or SCALE, i == 1 and MAT.Fabric or MAT.Slate
			local j = sin(i * 2.7) -- (a fixed wobble per segment, so no two swell alike)
			-- a rounded trunk, swollen unevenly at the flanks, a soft belly sagging under it
			rod(seg, 4.2, w * 0.82, ALONG, col, mat)
			ball(seg, w * (0.58 + j * 0.06), V(-w * 0.24, -w * 0.05, j * 0.6), col, mat)
			ball(seg, w * (0.58 - j * 0.06), V(w * 0.24, -w * 0.05, -j * 0.6), col, mat)
			rod(seg, 3.8, w * 0.42, V(0, -w * 0.3, 0) * ALONG, BELLY)
			-- the ring between segments: a collar of bone, knobbed, a knob missing here and there
			rod(seg, 0.8, w * 0.86 + 0.6, V(0, 0, 1.9) * ALONG, SCALE2, MAT.Slate)
			for k = 1, 7 do
				if (i + k) % 5 ~= 0 then
					local a = k / 7 * pi * 2 + i
					ball(seg, 0.7 + (k % 3) * 0.2, V(math.cos(a) * w * 0.47, math.sin(a) * w * 0.47, 1.9), SCALE2, MAT.Slate)
				end
			end
			-- overlapping dorsal scales, not quite in line, and every other segment a ridge of ember-cracked spines
			for k, z in ipairs({ -1.2, 0.2, 1.4 }) do
				part(seg, Vector3.new(w * (0.42 - k * 0.04), 0.4, 1.8), V(j * 0.4 * (k - 2), w * 0.42, z) * A(-0.3, j * 0.15, (k - 2) * 0.12), SCALE2, MAT.Slate)
			end
			fx(seg, V(0, w * 0.45 + w * 0.5, 0), 0.6 + w * 0.04)
			for _, x in ipairs({ -1, 1 }) do -- (and off both flanks, leaning out)
				fx(seg, V(x * w * 0.42, w * 0.1, j * 0.5) * A(0, 0, -x * 0.7), 0.45 + w * 0.03)
			end
			if i % 2 == 1 then
				for j = -1, 1 do
					part(seg, Vector3.new(0.5, w * 0.45 + (1 - math.abs(j)) * 1.6, 1.4), V(0, w * 0.45, j * 1.3) * A(0.35, 0, 0) * V(0, w * 0.22, 0), MANE, MAT.CrackedLava)
				end
			else
				ball(seg, 1.6, V(j * 0.3, w * 0.46, 0), SCALE, MAT.Slate) -- (a bony knob, a spike bent out of it)
				part(seg, Vector3.new(0.5, 2.2, 0.5), V(j * 0.3, w * 0.46, 0) * A(0.5, 0, j * 0.4) * V(0, 1.1, 0), IVORY, MAT.SmoothPlastic)
			end
		end
		-- the tail: tapering, knuckled at the joints, a few bone hooks curling off the end
		ball("T1", 3, V(0, 0, 0), SCALE, MAT.Slate)
		rod("T1", 3.4, 2.5, V(0, 0, 1.5) * ALONG, SCALE, MAT.Slate)
		ball("T1", 1.4, V(0.5, 1.1, 1.2), SCALE2, MAT.Slate)
		ball("T2", 2, V(0, 0, 0), SCALE2, MAT.Slate)
		rod("T2", 3.2, 1.6, V(0, 0, 1.5) * ALONG, SCALE, MAT.Slate)
		ball("T2", 1.3, V(0, 0, 3.1), SCALE2, MAT.Slate)
		for k, a in ipairs({ -0.7, 0.2, 0.9 }) do
			part("T2", Vector3.new(0.35, 0.35, 1.4 - k * 0.2), V(0, 0, 3.1) * A(0.4 * k - 0.6, a, 0) * V(0, 0, 0.8), IVORY, MAT.SmoothPlastic)
		end
		fx("T2", V(0, 0, 3.2), 0.6)
		fx("T1", V(0, 1.4, 1.2), 0.6)
		fx("root", V(0, 5.6, 2.2), 1.1) -- (the hump)
		for _, x in ipairs({ -1, 1 }) do -- the shoulders, and the flanks of the chest, leaning out
			fx("root", V(x * 3.8, 4, -0.5), 0.8)
			fx("root", V(x * 4.4, 1, 1.2) * A(0, 0, -x * 0.7), 0.7)
			fx("root", V(x * 4.2, -1.2, -1.8) * A(0, 0, -x * 0.7), 0.6)
			fx("T1", V(x * 1.2, 0.3, 1.5) * A(0, 0, -x * 0.7), 0.45)
		end
		fx("neck", V(0, 2.8, -1.5), 0.8)
		nightmareFace(part, fx, "head", "jaw")
		for i = 1, 20 do -- the wheel of fire: a ring of spikes round a burning rim, turning
			local a = i / 20 * pi * 2
			local h = 2.4 + (i % 2) * 1.8
			part("halo", Vector3.new(1, h, 0.8), A(0, 0, a) * V(0, 6.4 + h / 2, 0), MANE, MAT.CrackedLava)
			part("halo", Vector3.new(2, 0.9, 0.7), A(0, 0, a) * V(0, 6, 0), SCALE, MAT.Slate)
		end
		for i = 0, 5 do
			fx("halo", A(0, 0, i / 6 * pi * 2) * V(0, 6.6, 0), 0.9, i == 0)
		end
		for _, s in ipairs({ -1, 1 }) do
			local n = s < 0 and "L" or "R"
			watchdogLeg(part, "F" .. n, "F" .. n .. "k", "F" .. n .. "p", s)
		end
	end,
}

-- D: THE TRUE WATCHDOG OF PYRALIS, the Malformed one's brother: what it should have been. It stands upright on two legs -
-- its brother's forelegs, the same knotted arms, carrying it as hind legs - a whole lion's head crowned in fire with a
-- smaller wheel of fire turning behind it, a gold-collared chest, and for arms two great wings of fire: charred bone spars,
-- a membrane of cracked, glowing lava-skin between them, flame pouring off every trailing edge. It flies; it perches on the
-- arena's pillars. c (the client's): legs { swing, knee, paw } each side; spread 0..1 (folded..open); flap (the beat, +
-- up); reach (+ forward, - swept back); lean (+ forward); gape; stare; halo
local WINGF, FIREC, FIREH = C(110, 34, 16), C(255, 120, 30), C(255, 190, 90)
local RAW, GORE, SEEP = C(120, 36, 30), C(70, 14, 12), C(170, 22, 12) -- (torn flesh, the deep of a wound, what glows in it)
-- a wound on a bone's surface at cf (its face turned -z, outward): a raw gash, its dark depth, a seep of fire down it, a
-- flap of torn hide hanging off its lip, and (bones) ribs or bone showing through
local function wound(part, b, cf, w, h, bones)
	part(b, Vector3.new(w, h, 0.35), cf, RAW, MAT.SmoothPlastic)
	part(b, Vector3.new(w * 0.6, h * 0.75, 0.3), cf * V(0, 0, -0.08), GORE, MAT.Slate)
	part(b, Vector3.new(w * 0.15, h * 0.6, 0.2), cf * V(w * 0.1, -h * 0.05, -0.15) * A(0, 0, 0.15), SEEP, MAT.Neon)
	part(b, Vector3.new(w * 0.7, h * 0.5, 0.15), cf * V(-w * 0.15, -h * 0.6, -0.1) * A(0.35, 0, 0.2), FURD, MAT.Fabric)
	for i = 1, bones or 0 do
		part(b, Vector3.new(w * 0.85, 0.28, 0.3), cf * V(0, h * (0.35 - (i - 1) / math.max(bones - 1, 1) * 0.7) * 0.8, -0.2) * A(0, 0, (i % 2 - 0.5) * 0.25), IVORY, MAT.SmoothPlastic)
	end
end
DESIGNS.D = {
	label = "D - The True Watchdog of Pyralis",
	note = "upright, on its brother's forelegs; wings of fire for arms",
	speed = 2.6,
	turn = pi,
	hit = { Vector3.new(9, 17, 7), Vector3.new(0, 8.5, 0) },
	make = function(bone, part, fx)
		local ball, rod = shaped(part)
		local ALONG = A(pi / 2, 0, 0) -- (turns a rod to run along z)
		local ACROSS = A(0, 0, pi / 2) -- (and along x)
		bone("root", nil, V(0, 9.6, 0), function(ph, _, c)
			return V(0, sin(ph * 2) * 0.12 + (c and c.bob or 0) - (c and c.crouch or 0), 0) * A(-(c and c.lean or 0) * 0.3, c and c.twist or 0, c and c.bank or 0)
		end)
		bone("chest", "root", V(0, 3, 0.2), function(ph, t, c)
			return A(-0.08 - (c and c.lean or 0) * 0.7 + sin(t * 1.6) * 0.02, sin(ph) * 0.03 + (c and c.ctwist or 0), c and c.croll or 0) -- (breathing; wrung round on its hips)
		end)
		bone("neck", "chest", V(0, 4.6, -0.9), function(_, _, c)
			return A(0.2 - (c and c.stare or 0) * 0.1 + (c and c.gape or 0) * 0.15, 0, 0)
		end)
		bone("head", "neck", V(0, 2.6, -0.5), function(_, t, c)
			local s = c and c.stare or 0
			return A(-0.15 * s + sin(t * 0.9) * 0.04 * (1 - s) + (c and c.nod or 0), sin(t * 0.6) * 0.08 * (1 - s) + (c and c.look or 0), sin(t * 0.45) * 0.05 * (1 - s) + (c and c.tilt or 0))
		end)
		bone("jaw", "head", V(0, -0.9, -0.9), function(_, t, c)
			return A(-(0.1 + (c and c.gape or 0) * 0.6 + sin(t * 1.3) * 0.04), 0, 0)
		end)
		bone("halo", "head", V(0, 0.6, 2.2), function(_, t, c)
			return A(0, 0, c and c.halo or t * 0.6)
		end)
		for _, s in ipairs({ -1, 1 }) do
			local n = s < 0 and "L" or "R"
			-- the legs: its brother's forelegs, as hind legs
			bone("H" .. n, "root", V(s * 2.5, -0.4, 0.4), function(_, _, c)
				return A(c and c.legs and c.legs[n][1] or 0, 0, 0)
			end)
			bone("H" .. n .. "k", "H" .. n, V(0, -4, 0), function(_, _, c)
				return A(c and c.legs and c.legs[n][2] or 0, 0, 0)
			end)
			bone("H" .. n .. "p", "H" .. n .. "k", V(0, -3.4, 0), function(_, _, c)
				return A(c and c.legs and c.legs[n][3] or 0, 0, 0)
			end)
			-- the wings: shoulder (open out, folded back and down), forearm (folding back along it), hand (the fan of spars)
			bone("W" .. n, "chest", V(s * 3.3, 3.8, 0.9), function(_, _, c)
				local o = c and c.side and c.side[n] or { 0, 0, 0 }
				local sp, fl, re = math.clamp((c and c.spread or 0.8) + o[1], 0, 1.1), (c and c.flap or 0) + o[2], (c and c.reach or 0) + o[3]
				-- display 1: pitched so the membrane hangs below the arm and faces front-back, toward you; 0: flat, for flight
				local dp = c and c.display or 1
				return A(0, s * (-1.1 * (1 - sp) + re * 0.9), 0) * A(0, 0, s * (-0.7 * (1 - sp) + 0.3 * sp + fl * 0.7)) * A(0.25 * (1 - sp) + dp * 1.4, 0, 0)
			end)
			bone("W" .. n .. "f", "W" .. n, V(s * 6.2, 0, 0), function(_, _, c)
				local o = c and c.side and c.side[n] or { 0, 0, 0 }
				local sp, fl = math.clamp((c and c.spread or 0.8) + o[1], 0, 1.1), (c and (c.flapF or c.flap) or 0) + o[2] * 0.5
				return A(0, s * (-1.6 * (1 - sp) + fl * 0.15), 0) * A(0, 0, s * fl * 0.25)
			end)
			bone("W" .. n .. "h", "W" .. n .. "f", V(s * 7, 0, 0), function(_, _, c)
				local sp, fl = c and c.spread or 0.8, c and (c.flapH or c.flap) or 0
				return A(0, s * (-0.9 * (1 - sp) + (c and c.fan or 0)), 0) * A(0, 0, s * fl * 0.2)
			end)
		end
		bone("T1", "root", V(0, -0.6, 2.6), function(_, t, c)
			return A(0.9 + sin(t * 1.2) * 0.08 + (c and c.curl or 0) * 0.3, sin(t * 0.9) * 0.2, 0)
		end)
		bone("T2", "T1", V(0, 0, 3), function(_, t, c)
			return A(-0.3 + sin(t * 1.1 - 1) * 0.1 - (c and c.curl or 0) * 0.6, sin(t * 0.9 - 0.8) * 0.25, 0)
		end)
		bone("T3", "T2", V(0, 0, 2.6), function(_, t, c)
			return A(-0.35 + sin(t * 1.1 - 2) * 0.12 - (c and c.curl or 0) * 0.8, sin(t * 0.9 - 1.6) * 0.3, 0)
		end)

		-- the hips: a heavy pelvis, belted in dark plate trimmed with gold
		ball("root", 5.4, V(0, 0.4, 0.3), FURD)
		ball("root", 4.2, V(0, -0.6, -0.8), BELLY)
		for _, s in ipairs({ -1, 1 }) do
			ball("root", 3.6, V(s * 2.2, 0, 0.3), FUR)
			part("root", Vector3.new(0.5, 3.4, 2.6), V(s * 2.9, -1.2, -0.2) * A(0, 0, s * 0.12), PLATE, MAT.Metal) -- (tassets)
			part("root", Vector3.new(0.55, 0.3, 2.7), V(s * 2.95, -2.9, -0.2) * A(0, 0, s * 0.12), GOLD, MAT.Metal)
		end
		part("root", Vector3.new(6.4, 1, 5.2), V(0, 1.6, 0.2), PLATE, MAT.Metal)
		part("root", Vector3.new(6.6, 0.3, 5.4), V(0, 2.15, 0.2), GOLD, MAT.Metal)
		part("root", Vector3.new(1.4, 1.2, 0.4), V(0, 1.6, -2.5), GOLD, MAT.Metal) -- (the buckle: a sun)
		-- the chest: deep, upright, muscled; ribs and a knuckled breastbone showing; the back ridged with spines
		ball("chest", 6.6, V(0, 1.6, 0), FUR)
		ball("chest", 6, V(0, 3.4, -0.3), FUR)
		ball("chest", 5, V(0, 3.6, 1.4), FURD) -- (the back, humped behind the shoulders)
		rod("chest", 3, 4.2, V(0, 0.2, -0.6), BELLY)
		for _, s in ipairs({ -1, 1 }) do
			ball("chest", 3.4, V(s * 1.5, 3, -2.1), FUR) -- (the pecs)
			ball("chest", 3.6, V(s * 3.1, 3.9, 0.6), FURD) -- (under the wing's root)
			for i = 0, 3 do
				part("chest", Vector3.new(0.4, 0.5, 3.6), V(s * 3, 3.1 - i * 0.9, -0.4) * A(0, 0, s * (0.2 + i * 0.05)), IVORY, MAT.SmoothPlastic)
			end
			fx("chest", V(s * 3.4, 4.8, 1.2), 0.7)
			fx("chest", V(s * 3.2, 1.6, 0.2) * A(0, 0, -s * 0.7), 0.55) -- (off its flanks, leaning out)
		end
		for i = 0, 4 do
			ball("chest", 0.9, V(0, 4.3 - i * 0.75, -3.05 + i * 0.12), IVORY, MAT.SmoothPlastic)
		end
		-- bulk: a barrel chest, great lats flaring under the wings, traps heaped to the neck, a slab of abs, thick thighs
		ball("chest", 8.4, V(0, 2.6, 0.4), FUR)
		for _, s in ipairs({ -1, 1 }) do
			ball("chest", 4.6, V(s * 1.9, 3.3, -1.9), FUR) -- (the pecs, swollen)
			ball("chest", 5.2, V(s * 3.4, 1.8, 0.8), FURD) -- (lats)
			ball("chest", 4.4, V(s * 4.2, 4.4, 0.4), FUR) -- (shoulders, under the wing roots)
			ball("chest", 3.8, V(s * 1.8, 5.6, 0.9), FURD) -- (traps)
			for i = 0, 2 do
				ball("chest", 1.9, V(s * 0.95, 1.2 - i * 1.25, -2.9 + i * 0.2), BELLY)
			end
			ball("root", 4.6, V(s * 2.6, -0.4, 0.2), FUR) -- (hips)
			local n = s < 0 and "L" or "R"
			ball("H" .. n, 5.4, V(0, -1.4, 0), FUR) -- (thigh)
			ball("H" .. n, 4, V(s * 0.9, -2.6, 0.6), FURD)
			ball("H" .. n .. "k", 3.2, V(0, -1.2, 0.5), FUR) -- (calf)
		end
		for i = 0, 4 do
			part("chest", Vector3.new(0.7, 0.7, 2.4 - i * 0.2), V(0, 5.2 - i * 1.2, 2.9) * A(0.3, 0, 0) * V(0, 0, 1.2), SCALE, MAT.Slate)
		end
		-- the collar: a torc of gold round the root of the neck, and a crown of burning spikes behind it
		for i = 1, 10 do
			local a = i / 10 * pi * 2
			part("chest", Vector3.new(1.8, 0.6, 0.7), V(0, 5, -0.3) * A(0, a, 0) * V(0, 0, 2.6), GOLD, MAT.Metal)
		end
		for i = 1, 9 do
			local a = (i - 5) * 0.28
			local h = 2.6 + (i % 3) * 0.9
			part("chest", Vector3.new(0.8, h, 1), V(0, 5, 1.2) * A(0, a, 0) * A(-0.8, 0, 0) * V(0, h / 2 + 1, 0), MANE, MAT.CrackedLava)
		end
		fx("chest", V(0, 5.6, 1.8), 1)
		-- the neck: thick, corded
		rod("neck", 3.6, 2.8, V(0, 1.2, 0), FUR)
		ball("neck", 3, V(0, 0, -0.3), FURD)
		for _, s in ipairs({ -1, 1 }) do
			rod("neck", 3.2, 0.5, V(s * 1.2, 1.1, -0.6) * A(0, 0, s * 0.1), FURD)
		end
		-- the head: a whole lion's, as its brother's was before it was crushed
		trueFace(part, fx, "head", "jaw", 0.66)
		-- its wheel of fire, smaller than its brother's
		for i = 1, 16 do
			local a = i / 16 * pi * 2
			local h = 1.8 + (i % 2) * 1.3
			part("halo", Vector3.new(0.8, h, 0.6), A(0, 0, a) * V(0, 4.8 + h / 2, 0), MANE, MAT.CrackedLava)
			part("halo", Vector3.new(1.6, 0.7, 0.55), A(0, 0, a) * V(0, 4.5, 0), SCALE, MAT.Slate)
		end
		for i = 0, 4 do
			fx("halo", A(0, 0, i / 5 * pi * 2) * V(0, 5, 0), 0.75, i == 0)
		end
		-- the tail: short, plated, burning at the end
		rod("T1", 3.2, 2, V(0, 0, 1.5) * ALONG, SCALE, MAT.Slate)
		ball("T1", 2.2, V(0, 0, 0), SCALE2, MAT.Slate)
		rod("T2", 2.8, 1.5, V(0, 0, 1.3) * ALONG, SCALE, MAT.Slate)
		ball("T2", 1.6, V(0, 0, 0), SCALE2, MAT.Slate)
		rod("T3", 2.4, 1, V(0, 0, 1.1) * ALONG, SCALE, MAT.Slate)
		for k = 1, 3 do
			part("T3", Vector3.new(0.5, 0.5, 1.6), V(0, 0, 2.4) * A(0.5 - k * 0.3, (k - 2) * 0.6, 0) * V(0, 0, 0.8), MANE, MAT.CrackedLava)
		end
		fx("T3", V(0, 0, 2.6), 0.6)
		-- the wings of fire
		for _, s in ipairs({ -1, 1 }) do
			local n = s < 0 and "L" or "R"
			local w, f, h = "W" .. n, "W" .. n .. "f", "W" .. n .. "h"
			ball(w, 2.6, V(0, 0, 0), FURD)
			rod(w, 6.4, 1.3, V(s * 3.1, 0, 0) * ACROSS, SCALE, MAT.Slate)
			ball(w, 1.6, V(s * 6.2, 0, 0), SCALE2, MAT.Slate)
			part(w, Vector3.new(6.2, 0.25, 4.2), V(s * 3.1, -0.1, 2.3), WINGF, MAT.CrackedLava)
			part(w, Vector3.new(6, 0.3, 0.25), V(s * 3.1, -0.05, 4.4), FIREC, MAT.Neon)
			fx(w, V(s * 3, 0, 4.4), 0.7)
			for i = 1, 3 do
				part(w, Vector3.new(0.5, 0.12, 1.4 + (i % 2) * 0.8), V(s * (1 + i * 1.6), -0.1, 5.1) * A(0, s * 0.1 * i, 0), FIREH, MAT.Neon)
			end
			rod(f, 7, 0.9, V(s * 3.5, 0, 0) * ACROSS, SCALE, MAT.Slate)
			part(f, Vector3.new(7, 0.22, 6), V(s * 3.5, -0.1, 3.2) * A(0, s * -0.08, 0), WINGF, MAT.CrackedLava)
			part(f, Vector3.new(7, 0.3, 0.25), V(s * 3.5, -0.05, 6.2), FIREC, MAT.Neon)
			fx(f, V(s * 2, 0, 6.2), 0.75)
			fx(f, V(s * 5, 0, 6.2), 0.75)
			for i = 1, 4 do
				part(f, Vector3.new(0.5, 0.12, 1.6 + (i % 2) * 1), V(s * i * 1.5, -0.1, 7) * A(0, s * -0.1 * i, 0), FIREH, MAT.Neon)
			end
			for i = 1, 3 do -- (bone spurs on its leading edge)
				part(f, Vector3.new(0.3, 0.3, 1.2), V(s * (1.5 + i * 1.8), 0.4, -0.5) * A(0.6, 0, 0), IVORY, MAT.SmoothPlastic)
			end
			ball(h, 1.3, V(0, 0, 0), SCALE2, MAT.Slate)
			part(h, Vector3.new(0.5, 0.5, 1.8), V(s * 0.4, 0.3, -1) * A(0.5, 0, 0), CLAW, MAT.Slate) -- (the thumb: what grips a pillar)
			part(h, Vector3.new(0.3, 0.3, 0.9), V(s * 0.4, 0.05, -2.1) * A(0.9, 0, 0), IVORY, MAT.SmoothPlastic)
			local SPARS = { { -0.1, 15 }, { 0.35, 14 }, { 0.8, 12.5 }, { 1.25, 10.5 }, { 1.7, 8.5 } }
			for i, sp in ipairs(SPARS) do
				local a, len = sp[1], sp[2]
				part(h, Vector3.new(len, 0.6, 0.6), A(0, s * -a, 0) * V(s * len / 2, 0, 0), SCALE, MAT.Slate)
				local nxt = SPARS[i + 1] or { 2.1, 6 }
				local mid, ml = (a + nxt[1]) / 2, math.min(len, nxt[2])
				part(h, Vector3.new(ml * 0.95, 0.2, ml * 0.5), A(0, s * -mid, 0) * V(s * ml * 0.48, -0.1, 0), WINGF, MAT.CrackedLava)
				part(h, Vector3.new(0.6, 0.15, 2.6), A(0, s * -a, 0) * V(s * (len + 0.7), 0, 0) * A(0, s * 1.2, 0), FIREH, MAT.Neon)
				fx(h, A(0, s * -a, 0) * V(s * len, 0, 0), 0.7)
			end
		end
		for _, s in ipairs({ -1, 1 }) do
			local n = s < 0 and "L" or "R"
			watchdogLeg(part, "H" .. n, "H" .. n .. "k", "H" .. n .. "p", s)
		end
		-- half-mangled from the front, where it's taken every blow: the hide torn open across its chest, ribs showing, the
		-- breastplate wrenched; gashes down the fronts of its thighs and shins, bone splintered through; its belt half torn off
		wound(part, "chest", V(-2, 3.7, -4.15) * A(0, 0.35, 0.5), 2.8, 2.2, 3) -- (the left pec, clawed open to the ribs)
		wound(part, "chest", V(1.6, 1.6, -3.6) * A(0.1, -0.25, -0.3), 2.2, 1.6, 2)
		wound(part, "chest", V(0.4, 5.3, -2.6) * A(-0.4, 0, 0.9), 1.6, 0.9)
		for _, g in ipairs({ { -0.9, 2.4, -0.4, -3.8 }, { 2.4, 3.2, 0.6, -4.15 }, { -2.8, 1.4, 0.2, -2.6 }, { 0.8, 0.4, -0.7, -3.75 } }) do -- (claw rakes, three a set)
			for j = -1, 1 do
				part("chest", Vector3.new(0.18, 1.6, 0.2), V(g[1] + j * 0.35, g[2], g[4]) * A(0, 0, g[3]), j == 0 and SEEP or GORE, j == 0 and MAT.Neon or MAT.Slate)
			end
		end
		part("chest", Vector3.new(0.3, 0.5, 1.8), V(2.4, 2.6, -3.9) * A(0.6, 0.4, 0) * V(0, 0, -0.6), IVORY, MAT.SmoothPlastic) -- (a rib snapped, sticking out)
		part("chest", Vector3.new(1.8, 0.6, 0.7), V(1.4, 4.2, -2.6) * A(0.5, 0.3, 0.9), GOLD, MAT.Metal) -- (a link of its collar, wrenched loose)
		wound(part, "root", V(1.2, 0.2, -2.35) * A(0, -0.2, 0.4), 1.8, 1.2)
		part("root", Vector3.new(0.5, 3.2, 2.4), V(-3.4, -1.9, -1.2) * A(0.5, 0.3, 0.5), PLATE, MAT.Metal) -- (a tasset torn half off, hanging)
		part("root", Vector3.new(1.4, 0.4, 0.3), V(-0.4, 1.7, -2.75) * A(0, 0, -0.5), GORE, MAT.Slate) -- (the buckle hacked)
		for _, s in ipairs({ -1, 1 }) do
			local n = s < 0 and "L" or "R"
			wound(part, "H" .. n, V(s * 0.4, -1.2, -2.75) * A(0, s * 0.2, s * 0.35), 2, 2.4, s < 0 and 2 or 0) -- (thigh)
			wound(part, "H" .. n .. "k", V(-s * 0.2, -1.4, -1.45) * A(0, 0, -s * 0.2), 1.2, 2, 1) -- (shin, bone bared)
			part("H" .. n .. "k", Vector3.new(0.35, 0.35, 1.6), V(0, -2, -1.6) * A(-0.9, s * 0.3, 0) * V(0, 0, -0.5), IVORY, MAT.SmoothPlastic) -- (splintered)
			for j = -1, 1 do -- (rakes down the front of each thigh)
				part("H" .. n, Vector3.new(0.18, 1.8, 0.2), V(s * 1.4 + j * 0.35, -2.4, -2.2) * A(0, s * 0.3, s * 0.3), j == 0 and SEEP or GORE, j == 0 and MAT.Neon or MAT.Slate)
			end
		end
		for _, s in ipairs({ -1, 1 }) do -- (the wings' leading edges, torn and holed)
			local n = s < 0 and "L" or "R"
			part("W" .. n .. "f", Vector3.new(1.4, 0.3, 1), V(s * 2.4, -0.05, 2.6), GORE, MAT.Slate)
			part("W" .. n .. "f", Vector3.new(0.9, 0.32, 0.6), V(s * 5, -0.05, 1.6), GORE, MAT.Slate)
			part("W" .. n, Vector3.new(1.2, 0.3, 0.9), V(s * 4, -0.05, 1.4), GORE, MAT.Slate)
		end
	end,
}

-- a design read out: bones in order (each after its parent), parts { bone, size, cf, color, material, fire, light }
local specs = {}
local function spec(v)
	if specs[v] then
		return specs[v]
	end
	local d = DESIGNS[v]
	local sp = { bones = {}, parts = {}, speed = d.speed, turn = d.turn or 0.9 }
	d.make(function(name, parent, offset, pose)
		table.insert(sp.bones, { name = name, parent = parent, offset = offset, pose = pose })
	end, function(b, size, cf, color, material, shape)
		table.insert(sp.parts, { bone = b, size = size, cf = cf, color = color, material = material, shape = shape })
	end, function(b, cf, size, light)
		table.insert(sp.parts, { bone = b, size = Vector3.one, cf = cf, fire = size, light = light })
	end)
	specs[v] = sp
	return sp
end

-- every bone's CFrame in the world at walk phase ph, time t, the creature standing on base (c: its entrance's controls)
local function pose(sp, base, ph, t, c)
	local world = {}
	for _, b in ipairs(sp.bones) do
		local cf = (b.parent and world[b.parent] or base) * b.offset
		world[b.name] = b.pose and cf * b.pose(ph, t, c) or cf
	end
	return world
end

-- THE MALFORMED WATCHDOG'S ENTRANCE (design C). Until the cutscene it's hidden; then (EmergeAt, server time) it drags itself
-- out of its lair behind its spot, over the south bridge, one arm at a time: a foreleg reaches far out and claws in, it
-- trembles under the strain, then hauls its whole weight up to the claws - slow to start, then a lurch - while the other
-- arm stays braced behind. Chest on the ground, head pressed forward, jaw wrenched open. After the third haul it near
-- collapses. Then it heaves itself up, sees you, fixes on you, and the wheel of fire behind its head spins up.
M.Name, M.HP = "Malformed Watchdog", 1200
M.Total = 17 -- (the cutscene's length)
local LAIR, H0, HD = 66, 0.8, 1.6 -- (it starts 66 behind its spot, deep in the dark; hauls from 0.8 s on, 1.6 s each)
local SHARE = { 0.8, 1.2, 1, 1.3, 0.7, 1 } -- (each haul's share of the way: they sum to 6)
local REACH, BRACED = 0.85, -0.6 -- (a foreleg's swing reached out in front; pulled back under and behind)
local DROP = 2.4 -- (how far its chest sinks, dragging)
M.See, M.Stare, M.Spin = 11, 11.6, 12.4 -- (it notices you; fixes on you; the wheel speeds up)
local UP = H0 + #SHARE * HD -- (the last haul done: it heaves itself up)
local function smooth(x)
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end
-- one foreleg through its haul (f 0..1): shoulder swing, knee, paw, how far the haul has pulled the body (0..1), and the
-- effort in it (0..1: what makes it shake)
local PULL0, PULL1 = 0.33, 0.92 -- (the pull, from the claws planting to the arm drawn back under it)
local STUTTERS = 3 -- (the pull sticks and gives this many times)
local function haulLeg(f, t)
	if f < 0.25 then -- reaching: lifted high, knee folded, swung far out in front
		local u = smooth(f / 0.25)
		return BRACED + (REACH - BRACED) * u, -1.5 * sin(u * pi), 0.9 * sin(u * pi), 0, 0
	elseif f < PULL0 then -- planted: the claws stab in
		return REACH, 0, -0.35, 0, 0
	elseif f < PULL1 then
		-- the pull: slow the whole way, against the weight - it sticks, strains, gives a little, sticks again. The effort is
		-- the pull's own: it shakes hardest where it's stuck, and eases only as the arm comes back under it.
		local x = (f - PULL0) / (PULL1 - PULL0)
		local w = 2 * pi * STUTTERS
		local v = math.clamp(x - sin(x * w) / w * 0.85, 0, 1)
		local effort = (0.6 + 0.4 * math.cos(x * w)) * smooth(x / 0.1) * (1 - smooth((x - 0.9) / 0.1))
		return REACH + (BRACED - REACH) * v + sin(t * 41) * 0.03 * effort, -0.6 * sin(v * pi), -0.35 + 0.65 * v, v, effort
	end
	return BRACED, 0, 0.3, 1, 0
end
-- at tau into it: its body's offset from its spot, the walk's phase, how hard it stares, how fast the wheel spins, and the
-- rest of its pose for the bones (c.legs, c.strain, c.gape)
function M.emerge(tau, t)
	t = t or tau
	local stare = tau < M.See and 0 or tau < M.Stare and 0.35 * smooth((tau - M.See) / 0.3) or math.min(1, 0.35 + (tau - M.Stare) / 0.2)
	local spin = tau < M.Spin and 0.5 or tau < M.Total and 0.5 + 6.5 * smooth((tau - M.Spin) / 3) or 4
	local braced = { BRACED, 0, 0.3 }
	if tau >= UP then -- heaving itself up off the ground onto its forelegs, then still but for breathing
		local r = smooth((tau - UP) / 0.8)
		local legs = { L = { BRACED * (1 - r), 0, 0.3 * (1 - r) }, R = { BRACED * (1 - r), 0, 0.3 * (1 - r) } }
		return V(0, -DROP * (1 - r), 0), #SHARE * pi * 2 + (tau - UP) * 0.3, stare, spin, legs, 1 - r, 0.4 * (1 - r)
	end
	local k = math.clamp((tau - H0) / HD, 0, #SHARE - 1e-6)
	local n = math.floor(k)
	local f = k - n
	local done = 0
	for i = 1, n do
		done += SHARE[i]
	end
	local side = n % 2 == 0 and -1 or 1 -- (left arm first, then turn about)
	local sw, kn, pw, v, effort = haulLeg(f, t)
	local active = side < 0 and "L" or "R"
	local legs = { L = braced, R = braced }
	legs[active] = { sw, kn, pw }
	local pull = f >= PULL0 and f < PULL1 and sin(v * pi) or 0 -- (leaning into the pulling arm)
	local plant = f >= 0.25 and f < PULL0 and sin((f - 0.25) / (PULL0 - 0.25) * pi) or 0 -- (the jolt as the claws hit)
	local sag = (f >= PULL1 and sin((f - PULL1) / (1 - PULL1) * pi) or 0) * (n == 2 and 2 or 0.5)
	local back = LAIR - (done + SHARE[n + 1] * (tau < H0 and 0 or v)) / 6 * LAIR
	local shake = effort * 0.1
	local off = V(side * pull * 0.6 + sin(t * 53) * shake, -DROP - sag - plant * 0.35 - effort * 0.25 + sin(t * 47) * shake * 0.6, back)
		* A(-pull * 0.07 + sag * 0.06 + sin(t * 43) * shake * 0.3, side * pull * 0.09, -side * pull * 0.08 + sin(t * 61) * shake * 0.6)
	return off, (done + v * SHARE[n + 1]) * pi * 2, stare, spin, legs, 1, 0.45 + effort * 0.55
end
do -- self-check: it starts deep in the lair and ends on its spot
	local o0 = M.emerge(0)
	local o1 = M.emerge(M.Total)
	assert(math.abs(o0.Position.Z - LAIR) < 1e-6 and o1.Position.Magnitude < 1e-6, "PyralisProto: the entrance's path is off")
end

-- THE TWISTING LEAP, its attack (the server's LeapAt / LeapFrom / LeapTo, server time). It winds itself up - crouched,
-- forelegs drawn under, torso wrenched round one way and the worm-body curled the other, shaking - then springs: in the air
-- it spins on its own length, head to tail, twice round like a drill, the body whipping its curl across from side to side,
-- forelegs flung out claws-first; it comes down on its feet facing where it leapt, slams, and rights itself. The server's
-- blow lands at M.LeapLand.
M.LeapTime, M.LeapLand = 2, 1.4
M.LeapMin, M.LeapMax = 36, 72 -- (how far it springs: at least, at most)
local ROLLS = 2
local WIND, HIGH, CHEST = 0.55, 16, 10.8 -- (the wind-up's length; the leap's height; the height it turns about)
-- at u into it: where it stands (its base CFrame, turning and all), the walk's phase, and the bones' pose (legs, strain,
-- gape, coil); and the way it faces (yaw), to carry on from after
function M.leap(u, from, to, t)
	local d = to - from
	local yaw = math.atan2(-d.X, -d.Z)
	local legs, strain, gape, coil, drop
	local pos, twist, pitch, roll = from, 0, 0, 0
	if u < WIND then -- winding up
		local w = smooth(u / WIND)
		local tremble = sin(t * 50) * 0.05 * w
		drop, twist, coil, strain, gape = 3 * w, -0.55 * w + tremble, -0.9 * w, w, 0.3 + 0.4 * w
		pitch = -0.12 * w
		legs = { L = { -0.35 * w, -1.1 * w, 0.6 * w }, R = { -0.25 * w, -1.2 * w, 0.7 * w } }
	elseif u < M.LeapLand then -- in the air
		local a = (u - WIND) / (M.LeapLand - WIND)
		pos = from + d * a + Vector3.new(0, 4 * HIGH * a * (1 - a), 0)
		drop = 3 * (1 - smooth(a / 0.15))
		roll = ROLLS * 2 * pi * smooth(a) -- (spinning on its length, head to tail: a helix through the air)
		twist = -0.55 * (1 - smooth(a / 0.3)) -- (the wind-up's wrench let go)
		pitch = a < 0.25 and -0.12 + 0.62 * smooth(a / 0.25) or 0.5 - 0.65 * smooth((a - 0.25) / 0.75) -- (nose up off the ground, down to land)
		coil = -0.9 + 1.8 * smooth(a / 0.6) - 0.6 * sin(a * pi) -- (the body whipping across)
		strain, gape = 0, 0.6 + 0.4 * a
		local reach = REACH * 1.1 * sin(a * pi)
		legs = { L = { reach, -0.4, -0.6 }, R = { reach * 0.85, -0.5, -0.5 } }
	else -- down: the slam, then righting itself
		local l = smooth((u - M.LeapLand) / (M.LeapTime - M.LeapLand))
		pos = to
		drop = 3.2 * (1 - l)
		coil = 0.9 * (1 - l) * math.cos(l * pi * 3)
		pitch = -0.15 * (1 - l)
		strain, gape = 0.5 * (1 - l), 1 - l
		legs = { L = { 0.5 * (1 - l), 0, -0.3 * (1 - l) }, R = { 0.4 * (1 - l), 0, -0.3 * (1 - l) } }
	end
	local base = CFrame.new(pos) * CFrame.Angles(0, yaw, 0) * CFrame.new(0, CHEST - drop, 0)
		* CFrame.Angles(0, twist, 0) * CFrame.Angles(pitch, 0, 0) * CFrame.Angles(0, 0, roll) * CFrame.new(0, -CHEST, 0)
	return base, t * 0.3, { legs = legs, strain = strain, gape = gape, coil = coil, stare = 1 }, yaw
end
-- THE FLOOD OF FIRE, its other attack (the server's BreathAt / BreathYaw0 / BreathYaw1, server time). It rears up, jaw
-- wrenched open (M.BreathWind), then slams its head down and vomits fire onto the floor: a gush from its mouth, and from
-- there a churning carpet of flame rolling out across the ground in a wide cone toward you - each patch flaring up tall as
-- the front reaches it, then burning, smoking, glowing molten underneath, and dying down. The front hits hard; the ground it
-- leaves burns. Dodged by getting out of the cone in the wind-up, or behind it - or rolling through the front and getting
-- off the burning ground. The server and every client work the cone out alike (M.fireCells, M.fireAt).
M.BreathWind = 1.2 -- (rearing up)
local FLOOD_SPEED, FLOOD_LEN, FLOOD_HALF = 17.6, 51.2, math.rad(35) -- (how fast the front rolls out; how far; the cone's half-width)
local FLOOD_BURN, FLOOD_CELL = 2.2, 5 -- (how long the ground burns after the front; the patches' spacing)
local MOUTH_AHEAD, MOUTH_UP = 12, 11 -- (its mouth from where it stands)
M.BreathTime = FLOOD_LEN / FLOOD_SPEED -- (the front's run)
M.BreathEnd = M.BreathWind + M.BreathTime + FLOOD_BURN + 1.2
function M.breathOf(model)
	local B = { at = model:GetAttribute("LeapTo") or model:GetAttribute("Base").Position, yaw0 = model:GetAttribute("BreathYaw0"), yaw1 = model:GetAttribute("BreathYaw1") }
	local aim = (B.yaw0 + B.yaw1) / 2
	B.fwd = Vector3.new(-sin(aim), 0, -math.cos(aim))
	B.right = Vector3.new(math.cos(aim), 0, -sin(aim))
	B.origin = B.at + B.fwd * (MOUTH_AHEAD - 3) -- (the cone's point, on the floor under its mouth)
	B.mouth = B.at + B.fwd * MOUTH_AHEAD + Vector3.new(0, MOUTH_UP, 0)
	B.seed = math.floor((B.yaw0 or 0) * 1e4) -- (the patches' scatter: the same on every client)
	return B
end
-- the way it faces u into it (its head dragged a little across as it spews)
function M.breathYaw(B, u)
	return B.yaw0 + (B.yaw1 - B.yaw0) * smooth((u - M.BreathWind) / M.BreathTime)
end
-- the carpet's patches: { pos, when it catches (u) }, scattered over the cone
function M.fireCells(B)
	local rng, cells = Random.new(B.seed), {}
	for d = 3, FLOOD_LEN, FLOOD_CELL * 0.8 do
		local half = d * math.tan(FLOOD_HALF)
		local n = math.max(1, math.floor(half * 2 / FLOOD_CELL))
		for j = 0, n - 1 do
			local dd = d + rng:NextNumber(-1.5, 1.5)
			local x = (-1 + 2 * (j + 0.5) / n) * half + rng:NextNumber(-1.5, 1.5)
			table.insert(cells, { B.origin + B.fwd * dd + B.right * x, M.BreathWind + math.max(0, dd) / FLOOD_SPEED, rng:NextNumber() })
		end
	end
	return cells
end
-- (server) what the fire does at p, u into it: "front" (the wall rolling over it), "burn" (burning ground) or nil
function M.fireAt(B, p, u)
	local rel = p - B.origin
	local d = rel:Dot(B.fwd)
	local x = math.abs(rel:Dot(B.right))
	if d < -2 or d > FLOOD_LEN + 3 or x > math.max(d, 0) * math.tan(FLOOD_HALF) + 3 or math.abs(rel.Y) > 8 then
		return nil
	end
	local since = u - (M.BreathWind + math.max(d, 0) / FLOOD_SPEED)
	return since >= 0 and since < 0.35 and "front" or since >= 0.35 and since < FLOOD_BURN and "burn" or nil
end
-- its pose u into it: the way it faces, and the bones' (rearing up, then head slammed down, the jaw wide)
function M.breath(B, u)
	local rear = u < M.BreathWind and smooth(u / M.BreathWind) or (1 - 2.2 * smooth((u - M.BreathWind) / 0.25)) * (1 - smooth((u - M.BreathWind - M.BreathTime) / 0.5))
	local gape = u < M.BreathWind and 0.3 + 0.7 * smooth(u / M.BreathWind) or 1 - smooth((u - M.BreathWind - M.BreathTime) / 0.5)
	return M.breathYaw(B, u), { stare = 1, rear = rear, gape = gape }
end

-- THE TAIL SLASH (the server's SwipeAt / SwipeYaw, server time). All of it winds up: crouched, chest wrenched round away from
-- you and the worm-body curled tight the other way, shaking with it - then it lets go, the whole of it spinning a full turn
-- round on the spot, the tail whipping out after it in a great circle low over the floor through everything near, and it
-- comes back round facing you. Dodged by rolling through the tail, or being out of its reach (M.SwipeReach).
M.SwipeWind, M.SwipeWhip, M.SwipeTime = 2, 0.6, 3.3
M.SwipeReach = 33
local SWIPE_BACK = 1.1 -- (how far round it winds itself away)
function M.swipeYaw(yaw0, u)
	if u < M.SwipeWind then
		return yaw0 - SWIPE_BACK * smooth(u / M.SwipeWind)
	end
	local a = math.clamp((u - M.SwipeWind) / M.SwipeWhip, 0, 1)
	return yaw0 - SWIPE_BACK + (2 * pi + SWIPE_BACK) * (1 - (1 - a) ^ 2.2) -- (let go all at once, slowing as it comes round)
end
-- its pose u into it: how low it crouches, and the bones' (the coil wound tight, then flung out)
function M.swipe(u, t)
	local w = smooth(u / M.SwipeWind)
	local a = math.clamp((u - M.SwipeWind) / M.SwipeWhip, 0, 1)
	local rest = smooth((u - M.SwipeWind - M.SwipeWhip) / (M.SwipeTime - M.SwipeWind - M.SwipeWhip))
	local wound = u < M.SwipeWind and w or 1 - smooth(a / 0.4)
	-- shaking with it, then dead still for a beat before it lets go (the tell's last moment)
	local shake = u < M.SwipeWind and sin(t * 50) * 0.06 * w * (1 - smooth((u - M.SwipeWind + 0.4) / 0.15)) or 0
	local drop = (u < M.SwipeWind and 2 * w or 2 * (1 - rest))
	return drop, { stare = 1, coil = 1.1 * wound + shake, strain = 0.6 * wound, gape = 0.4 + 0.6 * wound * (1 - rest),
		legs = { L = { -0.3 * wound, -0.6 * wound, 0.4 * wound }, R = { 0.35 * wound, -0.3 * wound, 0.2 * wound } } }
end

-- THE REARING SLAM (the server's SlamAt / SlamYaw, server time). It heaves its front half way up on its tail, the chest
-- towering over you, forelegs raised; holds there dead still for a beat, jaw wide; then flicks the whole of itself down and
-- slams into the floor ahead - and the floor bursts up in a wedge of rubble running out from where it struck, widening as
-- it goes. Both hit: the slam where it lands, the rubble as its front runs over you. Dodged by getting off to its side.
M.SlamRise, M.SlamHold, M.SlamFall = 0.9, 0.6, 0.22
M.SlamLand = M.SlamRise + M.SlamHold + M.SlamFall
M.SlamTime = M.SlamLand + 1.1
local SLAM_UP, SLAM_DIP = 1.1, -0.12 -- (how far it rears back: radians; and how far past level it slams)
local SLAM_PIVOT = Vector3.new(0, 4.4, 9.3) -- (S4's joint at rest: what it rears up about, so the tail stays down)
local SLAM_AHEAD, SLAM_R = 9, 10 -- (the slam's centre ahead of where it stands; its radius)
local RUBBLE_AHEAD, RUBBLE_LEN, RUBBLE_HALF, RUBBLE_SPEED = 8, 46, math.rad(22), 55 -- (the wedge: its point, length, half-width, how fast it runs)
M.SlamAhead = SLAM_AHEAD
M.SlamEnd = M.SlamLand + RUBBLE_LEN / RUBBLE_SPEED + 1.2 -- (the rubble sunk back)
function M.slamOf(model)
	local yaw = model:GetAttribute("SlamYaw")
	local S = { at = model:GetAttribute("LeapTo") or model:GetAttribute("Base").Position, yaw = yaw }
	S.fwd = Vector3.new(-sin(yaw), 0, -math.cos(yaw))
	S.right = Vector3.new(math.cos(yaw), 0, -sin(yaw))
	S.apex = S.at + S.fwd * RUBBLE_AHEAD
	return S
end
-- (server) what strikes p, u into it: "slam" (the instant it lands, near it), "rubble" (the wedge's front passing), or nil
function M.slamHit(S, p, u)
	local rel = p - S.at
	if math.abs(rel.Y) > 8 then
		return nil
	end
	if u >= M.SlamLand and u < M.SlamLand + 0.12 and (Vector3.new(rel.X, 0, rel.Z) - S.fwd * SLAM_AHEAD).Magnitude < SLAM_R then
		return "slam"
	end
	local r = p - S.apex
	local d, x = r:Dot(S.fwd), math.abs(r:Dot(S.right))
	local since = u - (M.SlamLand + math.max(d, 0) / RUBBLE_SPEED)
	if d > -1 and d < RUBBLE_LEN and x < math.max(d, 0) * math.tan(RUBBLE_HALF) + 2.5 and since >= 0 and since < 0.3 then
		return "rubble"
	end
	return nil
end
-- its pose u into it: its base off where it stands (at, facing yaw), and the bones'
function M.slam(u, at, yaw, t)
	local th, legs, gape
	local up = { L = { 0.9, -1.1, 0.5 }, R = { 0.75, -1.25, 0.6 } } -- (forelegs raised, claws hooked)
	local down = { L = { 0.55, -0.1, -0.3 }, R = { 0.45, 0, -0.3 } } -- (flung down claws-first)
	local zero = { L = { 0, 0, 0 }, R = { 0, 0, 0 } }
	local function mix(a, b, k)
		local o = {}
		for n, v in pairs(a) do
			o[n] = { v[1] + (b[n][1] - v[1]) * k, v[2] + (b[n][2] - v[2]) * k, v[3] + (b[n][3] - v[3]) * k }
		end
		return o
	end
	if u < M.SlamRise then -- heaving itself up, shaking with it
		local w = smooth(u / M.SlamRise)
		th, legs, gape = SLAM_UP * w + sin(t * 45) * 0.02 * w, mix(zero, up, w), 0.4 + 0.3 * w
	elseif u < M.SlamRise + M.SlamHold then -- the beat: dead still, jaw wide
		th, legs, gape = SLAM_UP, up, 1
	elseif u < M.SlamLand then -- flicked down, faster and faster
		local a = (u - M.SlamRise - M.SlamHold) / M.SlamFall
		th, legs, gape = SLAM_UP + (SLAM_DIP - SLAM_UP) * a * a, mix(up, down, a), 1
	else -- struck: righting itself
		local l = smooth((u - M.SlamLand) / (M.SlamTime - M.SlamLand))
		th, legs, gape = SLAM_DIP * (1 - l), mix(down, zero, l), 1 - 0.6 * l
	end
	local base = CFrame.new(at) * CFrame.Angles(0, yaw, 0) * CFrame.new(SLAM_PIVOT) * CFrame.Angles(th, 0, 0) * CFrame.new(-SLAM_PIVOT)
	return base, { stare = 1, legs = legs, gape = gape, strain = 0.3, rise = th }
end

do -- self-check: the slam lands ahead, the rubble runs out ahead and widens, nothing behind or off to its side
	local S = { at = Vector3.zero, fwd = Vector3.new(0, 0, -1), right = Vector3.new(1, 0, 0), apex = Vector3.new(0, 0, -RUBBLE_AHEAD) }
	local far = Vector3.new(0, 0, -RUBBLE_AHEAD - 30)
	local passes = M.SlamLand + 30 / RUBBLE_SPEED + 0.05
	assert(M.slamHit(S, Vector3.new(0, 0, -SLAM_AHEAD), M.SlamLand) == "slam", "PyralisProto: the slam misses ahead")
	assert(M.slamHit(S, far, passes) == "rubble", "PyralisProto: the rubble misses ahead")
	assert(M.slamHit(S, far, M.SlamLand) == nil and M.slamHit(S, Vector3.new(0, 0, 20), M.SlamLand + 0.05) == nil, "PyralisProto: the rubble hits too early or behind")
	assert(M.slamHit(S, Vector3.new(25, 0, -RUBBLE_AHEAD - 30), passes) == nil, "PyralisProto: the wedge is too wide")
end

-- THE TRUE WATCHDOG OF PYRALIS (design D), its brother, come down to it once it's a third gone. It keeps well away from
-- its brother, and from you. Where it is: the server's MoveFrom / MoveTo / MoveAt / MoveTime / MoveArc / MoveKind (a flight,
-- arcing up and down; "dive" runs straight at its pace), else Home. Perched (PerchYaw: the way it faces) it clings to a
-- pillar. Its attacks: from a pillar, the EMBER VOLLEY (ShotAt / ShotFrom / ShotTo, one per shot: balls of fire lobbed down
-- where you stand, each landing on a ring it marks) and the SUNFALL (SunAt / SunTo: a sun swollen over its head, then hurled
-- down onto a great ring, the ground left burning); on the ground, the GALE (GaleAt / GaleYaw: wings drawn back, then two
-- beats of fire rolling out in a wide cone) and the TALON DIVE (a "dive" flight through you, hind talons first).
M.TrueName, M.TrueHP = "True Watchdog of Pyralis", 480 -- (2/5 of its brother's)
M.ShotTime, M.ShotR = 0.95, 8.5
M.SunCharge, M.SunFall, M.SunR, M.SunBurn, M.PoolR = 1.8, 0.9, 13, 3.2, 9
M.GaleWind, M.GaleGap, M.GaleRange, M.GaleHalf = 0.8, 0.55, 30, math.rad(62)
M.GaleTime = M.GaleWind + M.GaleGap + 0.7
M.EnterTime, M.EnterR = 1.8, 9
M.DiveR = 9 -- (the talon dive: only its landing hurts, this far round where it marked) -- (its entrance: the dive down onto its ring, and the slam's reach)
-- where it stands (its feet), whether it's in flight, which way it's going, and how
function M.trueAt(model, now)
	local to = model:GetAttribute("MoveTo")
	if not to then
		return model:GetAttribute("Home"), false, nil, nil
	end
	local from, at, dur = model:GetAttribute("MoveFrom"), model:GetAttribute("MoveAt"), model:GetAttribute("MoveTime")
	local a = math.clamp((now - at) / dur, 0, 1)
	local kind = model:GetAttribute("MoveKind")
	local k = kind == "dive" and a or smooth(a)
	return from:Lerp(to, k) + Vector3.new(0, (model:GetAttribute("MoveArc") or 0) * 4 * k * (1 - k), 0), a < 1, to - from, kind
end
-- (server) is p in the gale's cone, from its feet at from, facing yaw
function M.galeHit(from, yaw, p)
	local rel = p - from
	local fl = Vector3.new(rel.X, 0, rel.Z)
	if fl.Magnitude > M.GaleRange or math.abs(rel.Y) > 8 then
		return false
	end
	if fl.Magnitude < 3 then
		return true
	end
	local fwd = Vector3.new(-sin(yaw), 0, -math.cos(yaw))
	return fl.Unit:Dot(fwd) >= math.cos(M.GaleHalf)
end
-- its wings through the gale, u into it: reach, flap, lean (drawn back and up; struck forward and down, twice; settled)
function M.galePose(u)
	local W, G = M.GaleWind, M.GaleGap
	if u < W then
		local k = smooth(u / W)
		return -0.9 * k, 0.9 * k, -0.15 * k
	end
	local v = u - W
	local second = v >= G
	if second then
		v -= G
	end
	local out = smooth(v / 0.16)
	local back = smooth((v - 0.2) / (second and 0.4 or G - 0.2))
	local reach, flap, lean = -0.9 + 1.8 * out, 0.9 - 1.6 * out, -0.15 + 0.45 * out
	if second then
		return reach * (1 - back), flap * (1 - back), lean * (1 - back)
	end
	return reach + (-0.9 - reach) * back, flap + (0.9 - flap) * back, lean + (-0.15 - lean) * back
end
do -- self-check: the gale finds you ahead, near its edge, and not behind or past its reach
	local o = Vector3.zero
	assert(M.galeHit(o, 0, Vector3.new(0, 0, -20)) and M.galeHit(o, 0, Vector3.new(14, 0, -14)), "PyralisProto: the gale misses ahead")
	assert(not M.galeHit(o, 0, Vector3.new(0, 0, 20)) and not M.galeHit(o, 0, Vector3.new(0, 0, -40)), "PyralisProto: the gale hits behind or too far")
	assert(not M.galeHit(o, 0, Vector3.new(20, 0, -5)), "PyralisProto: the gale is too wide")
	local r, f = M.galePose(M.GaleWind + 0.16)
	assert(r > 0.8 and f < -0.6, "PyralisProto: the gale's beat doesn't strike forward")
end

do -- self-check: it leaves from where it stood and comes down where it leapt, upright and facing that way
	local from, to = Vector3.new(0, 0, 0), Vector3.new(10, 0, -20)
	local b0 = M.leap(0, from, to, 0)
	local b1 = M.leap(M.LeapTime - 1e-3, from, to, 0)
	assert((b0.Position - from).Magnitude < 1e-3 and (b1.Position - to).Magnitude < 0.01 and b1.UpVector.Y > 0.999, "PyralisProto: the leap's path is off")
end

local function fire(p, k, light)
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/fire_main.dds"
	e.Color = ColorSequence.new(C(255, 170, 60), C(220, 50, 12))
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6 * k, 0.6 * k), NumberSequenceKeypoint.new(0.4, 3.4 * k, 1 * k), NumberSequenceKeypoint.new(1, 0.4 * k) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(0.3, 0.15), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.8, 1.6)
	e.Speed = NumberRange.new(1 * k, 3 * k)
	e.SpreadAngle = Vector2.new(25, 25)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-60, 60)
	e.Acceleration = Vector3.new(0, 11, 0)
	e.Drag = 1.2
	e.Rate = 60
	e.Parent = p
	local f = Instance.new("Fire")
	f.Size, f.Heat = 5 * k, 9
	f.Color, f.SecondaryColor = C(255, 120, 34), C(120, 20, 8)
	f.Parent = p
	if light then
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = C(255, 130, 50), 34, 2.2
		l.Parent = p
	end
end

-- (server) the entrance's camera, as SoulsClient's "Cutscene" shots { from, to, seconds }, off base (its spot). Framed by eye
-- in Studio: all on its side of the arena's pillars, the last two through the gap between the two great ones in front of
-- it. Timed to M.emerge; the lengths add up to M.Total.
function M.shots(base)
	local B, Vec = base.Position, Vector3.new
	local function shot(from, at, to, at2, secs)
		return { CFrame.lookAt(B + from, B + at), CFrame.lookAt(B + to, B + at2), secs }
	end
	return {
		-- on the island at the south bridge, low, creeping in toward the black hole: embers, and nothing else
		shot(Vec(-4, 6, 2), Vec(0, 11, 36), Vec(-3.5, 6, 9), Vec(0, 11, 36), 3.4),
		-- off to the side, three-quarters on: the head, the wheel, the forelegs haul out of the dark
		shot(Vec(21, 8, 8), Vec(0, 10, 25), Vec(20, 8, 4), Vec(1, 11, 10), 3.4),
		-- low at its flank: the long ringed body dragged out over the bridge after it
		shot(Vec(19, 5, 22), Vec(0, 9, 18), Vec(18, 5, 10), Vec(0, 9, 4), 2.6),
		-- its profile as it stops and lifts its head toward you
		shot(Vec(25, 11, 0), Vec(-1, 13, -12), Vec(24, 11, -4), Vec(-1, 13.5, -13), 2.4),
		-- its face between the two great pillars, pushing in as it fixes on you
		shot(Vec(1, 11.5, -30), Vec(0, 13.5, -12), Vec(1, 12, -25), Vec(0, 13.7, -12), 2.8),
		-- pulling slowly back and down through the gap: all of it, staring, the wheel whirling
		shot(Vec(1.5, 11, -26), Vec(0, 14, -12), Vec(2, 8, -39), Vec(0, 14, -12), 2.4),
	}
end

-- (server) the Malformed Watchdog, on its spot south-east of the arena's centre facing the gate - but built far below it, out of
-- sight, until its entrance brings it out (the clients pose it). Returns its model.
local SPOTS = { C = Vector3.new(16, 0, 28) } -- (x 272, z 204: clear of the pillars round the centre, its tail still in the lair's mouth)
local HIDDEN = V(0, -400, 0)
-- (server) a design's parts, posed at cf, in a model of its own (each part found again by its Index)
local function assemble(v, cf, name)
	local sp = spec(v)
	local world = pose(sp, cf, 0, 0)
	local model = Instance.new("Model")
	model.Name = name
	model:SetAttribute("Variant", v)
	for i, s in ipairs(sp.parts) do
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanTouch, p.CastShadow = true, false, false, s.fire == nil
		p.Shape = s.shape or Enum.PartType.Block -- (before Size: a ball's size is forced even)
		p.Size = s.size
		p.CFrame = world[s.bone] * s.cf
		if s.fire then
			p.Transparency, p.CanQuery = 1, false
			fire(p, s.fire, s.light)
		else
			p.Color, p.Material = s.color, s.material
		end
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Name = tostring(i)
		p:SetAttribute("Index", i)
		p.Parent = model
	end
	return model
end
function M.build(centre)
	local watchdog
	local folder = Instance.new("Folder")
	folder.Name = "PyralisProtos"
	for v, off in pairs(SPOTS) do
		local base = CFrame.new(centre + off)
		local model = assemble(v, base * HIDDEN, "MalformedWatchdog")
		model:SetAttribute("Base", base)
		model:SetAttribute("Lair", true) -- (hidden till EmergeAt is set)
		-- a still block to bump into (the parts themselves move only on the clients)
		local d = DESIGNS[v]
		local hit = Instance.new("Part")
		hit.Name = "Hit"
		hit.Anchored, hit.Transparency, hit.CanQuery = true, 1, false
		hit.Size = d.hit[1]
		hit.CFrame = base * CFrame.new(d.hit[2])
		hit.Parent = model
		model.Parent = folder
		watchdog = model
	end
	folder.Parent = workspace
	return watchdog
end
-- (server) the True Watchdog, unparented: posed by the clients once it is in workspace.PyralisProtos
function M.buildTrue(home)
	local model = assemble("D", CFrame.new(home) * HIDDEN, "TrueWatchdog")
	model:SetAttribute("Home", home)
	return model -- (the caller sets its flight in, then parents it to workspace.PyralisProtos)
end

-- (client) each frame: turn each toward you (within its turn of north) and walk it on the spot
-- (client) the flood of fire u into it, drawn: the gush from its mouth, and each patch of the carpet - a molten glow on the
-- floor under a churn of big flames and smoke, flaring as the front reaches it, burning, then dying down (B nil: all out)
local FIRE_TEX, SMOKE_TEX = "rbxasset://textures/particles/fire_main.dds", "rbxasset://textures/particles/smoke_main.dds"
local FLAME_COL = ColorSequence.new({ ColorSequenceKeypoint.new(0, C(255, 210, 100)), ColorSequenceKeypoint.new(0.4, C(240, 90, 20)), ColorSequenceKeypoint.new(1, C(90, 20, 10)) })
local DARK_COL = ColorSequence.new({ ColorSequenceKeypoint.new(0, C(230, 50, 30)), ColorSequenceKeypoint.new(0.4, C(150, 12, 8)), ColorSequenceKeypoint.new(1, C(40, 4, 4)) })
local DARKC, DARKH = C(120, 8, 6), C(185, 25, 15) -- (the True Watchdog's fire)
local function flames(parent, size, rate, dark)
	local e = Instance.new("ParticleEmitter")
	e.Texture, e.Color, e.LightEmission = FIRE_TEX, dark and DARK_COL or FLAME_COL, dark and 0.35 or 0.9
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size * 0.4), NumberSequenceKeypoint.new(0.3, size), NumberSequenceKeypoint.new(1, size * 0.25) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(0.25, 0.08), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.6, 1.3)
	e.Rotation, e.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-90, 90)
	e.Rate = rate
	e.Parent = parent
	return e
end
local function drawBreath(L, B, u)
	if not B or (L.fire and L.fireKey ~= B.seed) then -- (out: or a new one, the old put out first)
		for _, p in pairs(L.fire or {}) do
			if p then
				p:Destroy()
			end
		end
		L.fire, L.cells = nil, nil
		if not B then
			return
		end
	end
	if not L.fire then
		L.fire, L.cells, L.fireKey = {}, M.fireCells(B), B.seed
		local g = Instance.new("Part") -- the gush, out of its mouth and down onto the floor ahead
		g.Transparency, g.Size = 1, Vector3.new(2, 2, 1)
		g.Anchored, g.CanCollide, g.CanTouch, g.CanQuery = true, false, false, false
		g.CFrame = CFrame.lookAt(B.mouth, B.origin + B.fwd * 8)
		local e = flames(g, 8, 110)
		e.EmissionDirection = Enum.NormalId.Front
		e.Speed, e.SpreadAngle, e.Lifetime = NumberRange.new(30, 42), Vector2.new(16, 16), NumberRange.new(0.4, 0.6)
		e.Enabled = false
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness, l.Enabled = C(255, 130, 50), 30, 4, false
		l.Parent = g
		g.Parent = workspace
		L.fire.gush = g
	end
	local spewing = u >= M.BreathWind and u < M.BreathWind + M.BreathTime
	L.fire.gush.ParticleEmitter.Enabled = spewing
	L.fire.gush.PointLight.Enabled = spewing
	for i, cell in ipairs(L.cells) do
		local since = u - cell[2]
		local p = L.fire[i]
		if since >= 0 and p == nil then -- caught: the glow, the flames on it flaring up, its smoke
			p = Instance.new("Part")
			p.Size = Vector3.new(FLOOD_CELL + 1.5, 0.3, FLOOD_CELL + 1.5)
			p.CFrame = CFrame.new(cell[1] + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, cell[3] * 6.28, 0)
			p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
			p.Material, p.Color, p.Transparency = MAT.Neon, C(255, 120, 30):Lerp(C(150, 30, 10), cell[3]), 0.35
			local f = flames(p, 6 + cell[3] * 4, 10)
			f.Speed, f.SpreadAngle, f.Acceleration = NumberRange.new(2, 6), Vector2.new(40, 40), Vector3.new(0, 10, 0)
			f.Shape, f.ShapeStyle, f.EmissionDirection = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume, Enum.NormalId.Top
			local s = Instance.new("ParticleEmitter")
			s.Name = "Smoke"
			s.Texture, s.Color = SMOKE_TEX, ColorSequence.new(C(46, 34, 30))
			s.Size = NumberSequence.new(4, 13)
			s.Transparency = NumberSequence.new(0.55, 1)
			s.Lifetime, s.Speed, s.Acceleration = NumberRange.new(2, 3), NumberRange.new(3, 6), Vector3.new(0, 4, 0)
			s.Rotation, s.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-30, 30)
			s.Rate = 2
			s.Parent = p
			if i % 4 == 0 then
				local l = Instance.new("PointLight")
				l.Color, l.Range, l.Brightness = C(255, 110, 35), 18, 2.5
				l.Parent = p
			end
			p.Parent = workspace
			f:Emit(9) -- (the front, rolling over it)
			L.fire[i] = p
		end
		if p then
			if since >= FLOOD_BURN then -- dying down: the flames and smoke stop, the glow fades out
				p.ParticleEmitter.Enabled, p.Smoke.Enabled = false, false
				p.Transparency = 0.35 + 0.65 * smooth((since - FLOOD_BURN) / 1.2)
			end
			if since >= FLOOD_BURN + 1.2 then
				p:Destroy()
				L.fire[i] = false -- (burnt out: not to catch again)
			end
		end
	end
end

-- (client) the tail slash's tell: the floor splitting open round it under the strain. Jagged cracks, branching, run out
-- from under it in every direction, dust kicking up where they open, and the front of them reaches the tail's reach at the
-- very instant it lets go - so how far they've run is how long you have. Fire glows up out of them, hotter as it comes; as
-- it lets go they flare white and the floor coughs up dust and grit all along them.
local CRACK_ROCK, CRACK_GLOW = C(14, 12, 12), C(255, 120, 30)
local function crackPattern(seed)
	local rng, segs = Random.new(seed), {}
	local function run(p, dir, d0, steps, branch)
		local d = d0
		for _ = 1, steps do
			if d >= M.SwipeReach or #segs >= 700 then -- (shortcut: a hard cap on parts, not a look; raise it if the web looks thin)
				return
			end
			local radial = math.atan2(p.Y, p.X)
			dir = radial + math.clamp((dir - radial + pi) % (2 * pi) - pi + rng:NextNumber(-0.5, 0.5), -0.7, 0.7) -- (wandering, but outward)
			local q = p + Vector2.new(math.cos(dir), math.sin(dir)) * rng:NextNumber(2.5, 4.5)
			table.insert(segs, { p, q, d, 1.1 - 0.75 * d / M.SwipeReach })
			if branch and rng:NextNumber() < 0.24 then -- (a branch splitting off; branches don't branch again)
				run(q, dir + (rng:NextNumber() < 0.5 and -1 or 1) * rng:NextNumber(0.5, 1), q.Magnitude, rng:NextInteger(2, 5))
			end
			p, d = q, q.Magnitude
		end
	end
	local n = 26 -- (the floor shattered all round it: a web, not a few lines)
	for i = 1, n do
		local a = (i + rng:NextNumber(-0.35, 0.35)) / n * 2 * pi
		run(Vector2.new(math.cos(a), math.sin(a)) * 3, a, 3, 40, true)
	end
	return segs
end
local function clearSwipe(L, all)
	for _, c in ipairs(L.cracks or {}) do
		if c.rock then
			c.rock:Destroy()
			c.glow:Destroy()
		end
	end
	if L.dust then
		L.dust:Destroy()
	end
	L.cracks, L.dust = nil, nil
	if all then
		for _, s in ipairs(L.shards or {}) do
			s.p:Destroy()
		end
		L.shards, L.shardLast, L.swipeSeed = nil, nil, nil
	end
end
-- the slash itself, shown where it strikes: rock and rubble jabbing up out of the floor behind the tail as it sweeps round,
-- all across its reach, and sinking back - so you see the circle it filled, and that you were right not to be in it
local SHARD_RINGS = {}
for r = 6, M.SwipeReach - 1, 3.2 do
	table.insert(SHARD_RINGS, r)
end
local function shard(L, at, a, r)
	local pos = at + Vector3.new(-sin(a) * r, 0, -math.cos(a) * r)
	local h = 2.5 + math.random() * 3.5
	local p = Instance.new("Part")
	p.Size = Vector3.new(1.2 + math.random() * 1.4, h, 1 + math.random() * 1.2)
	p.Material = math.random() < 0.5 and MAT.Basalt or MAT.Slate
	p.Color = C(30, 26, 24):Lerp(C(58, 46, 40), math.random())
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	local cf = CFrame.new(pos) * CFrame.Angles(0, math.random() * 6.28, 0) * CFrame.Angles((math.random() - 0.5) * 0.9, 0, (math.random() - 0.5) * 0.9)
	p.CFrame = cf * CFrame.new(0, -h, 0)
	p.Parent = workspace
	table.insert(L.shards, { p = p, cf = cf, h = h, born = nil })
	if L.dust and math.random() < 0.6 then
		L.dust.CFrame = CFrame.new(pos)
		L.dust.ParticleEmitter:Emit(2)
	end
end
local function drawSwipe(L, at, u, seed, yaw0)
	local W = M.SwipeWind
	if not u or L.swipeSeed ~= seed then -- (gone: or a new one, the old cleared first)
		clearSwipe(L, true)
		if not u then
			return
		end
	end
	if not L.swipeSeed then
		L.swipeSeed, L.shards, L.shardLast = seed, {}, {}
		L.cracks = {}
		for _, s in ipairs(crackPattern(seed)) do
			table.insert(L.cracks, { seg = s })
		end
		local dust = Instance.new("Part")
		dust.Transparency, dust.Size = 1, Vector3.new(1, 1, 1)
		dust.Anchored, dust.CanCollide, dust.CanTouch, dust.CanQuery = true, false, false, false
		local e = Instance.new("ParticleEmitter")
		e.Texture, e.Color = SMOKE_TEX, ColorSequence.new(C(70, 58, 50))
		e.Size = NumberSequence.new(1.5, 5)
		e.Transparency = NumberSequence.new(0.35, 1)
		e.Lifetime, e.Speed, e.Acceleration = NumberRange.new(0.8, 1.6), NumberRange.new(2, 6), Vector3.new(0, 2, 0)
		e.SpreadAngle, e.Rate = Vector2.new(60, 60), 0
		e.Parent = dust
		dust.Parent = workspace
		L.dust = dust
	end
	-- the rubble: jabbed up behind the tail (where the server strikes: a beat behind the chest), every few studs round each
	-- ring of its reach as it passes; then each one sinks back into the floor
	if u >= W and u <= W + M.SwipeWhip + 0.1 then
		local tail = M.swipeYaw(yaw0, u - 0.08) + pi
		for j, r in ipairs(SHARD_RINGS) do
			local last = L.shardLast[j] or M.swipeYaw(yaw0, W - 0.08) + pi
			local step = 3.4 / r
			while last + step <= tail do
				last += step
				shard(L, at, last + (math.random() - 0.5) * step, r + (math.random() - 0.5) * 3)
			end
			L.shardLast[j] = last
		end
	end
	for i = #L.shards, 1, -1 do
		local s = L.shards[i]
		s.born = s.born or u
		local age = u - s.born
		if age > 1 then
			s.p:Destroy()
			table.remove(L.shards, i)
		else
			local k = smooth(age / 0.1) * (1 - smooth((age - 0.45) / 0.5)) -- (out fast, held, sunk back)
			s.p.CFrame = s.cf * CFrame.new(0, -s.h / 2 - 0.2 + s.h * 0.85 * k, 0)
		end
	end
	if u > W + 0.9 then -- the cracks done with
		clearSwipe(L, false)
		return
	end
	local front = 3 + (M.SwipeReach - 3) * math.min(1, u / W) -- (steady: it reaches the edge as it lets go)
	local heat = math.min(1, u / W) ^ 2
	local flare = u >= W and 1 - smooth((u - W) / 0.9) or 0
	for _, c in ipairs(L.cracks or {}) do
		local s = c.seg
		if not c.rock and s[3] <= front then -- opened: a dark split, fire glowing up out of it, dust kicked up
			local a3, b3 = at + Vector3.new(s[1].X, 0, s[1].Y), at + Vector3.new(s[2].X, 0, s[2].Y)
			local cf = CFrame.lookAt((a3 + b3) / 2, b3)
			local len = (b3 - a3).Magnitude + 0.3
			c.rock = Instance.new("Part")
			c.rock.Size, c.rock.CFrame = Vector3.new(s[4], 0.12, len), cf + Vector3.new(0, 0.06, 0)
			c.rock.Material, c.rock.Color = MAT.Slate, CRACK_ROCK
			c.glow = Instance.new("Part")
			c.glow.Size, c.glow.CFrame = Vector3.new(s[4] * 0.4, 0.14, len), cf + Vector3.new(0, 0.07, 0)
			c.glow.Material = MAT.Neon
			for _, p in ipairs({ c.rock, c.glow }) do
				p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
				p.Parent = workspace
			end
			L.dust.CFrame = CFrame.new(b3)
			L.dust.ParticleEmitter:Emit(2)
		end
		if c.glow then
			if flare > 0 then -- the instant: white-hot along every crack, grit thrown up, then dying
				if not c.flared then
					c.flared = true
					L.dust.CFrame = CFrame.new(at + Vector3.new(s[2].X, 0.5, s[2].Y))
					L.dust.ParticleEmitter:Emit(3)
				end
				c.glow.Color = CRACK_GLOW:Lerp(C(255, 245, 225), flare)
				c.glow.Transparency = 1 - flare
				c.rock.Transparency = 1 - flare
			else
				c.glow.Color = C(120, 25, 10):Lerp(CRACK_GLOW, heat)
				c.glow.Transparency = 0.85 - 0.75 * heat
			end
		end
	end
end

-- (client) the wedge of rubble, jabbing up row by row as its front runs out from the slam, then sinking back
local function drawSlam(L, S, u)
	if not u or L.slamSeed ~= S.yaw then -- (gone: or a new one, the old cleared first)
		for _, r in ipairs(L.rubble or {}) do
			r.p:Destroy()
		end
		L.rubble, L.slamSeed = nil, nil
		if not u then
			return
		end
	end
	if u < M.SlamLand then
		return
	end
	if not L.rubble then
		L.slamSeed, L.rubble = S.yaw, {}
		for d = 1, RUBBLE_LEN, 2.6 do
			local half = d * math.tan(RUBBLE_HALF) + 1.5
			local n = math.max(1, math.floor(half * 2 / 2.8))
			for j = 0, n - 1 do
				local dd = d + (math.random() - 0.5) * 2
				local x = (-1 + 2 * (j + 0.5) / n) * half + (math.random() - 0.5) * 2
				local h = 2.5 + math.random() * 3.5 * (1 - 0.4 * d / RUBBLE_LEN)
				local p = Instance.new("Part")
				p.Size = Vector3.new(1.4 + math.random() * 1.6, h, 1.2 + math.random() * 1.4)
				p.Material = math.random() < 0.5 and MAT.Basalt or MAT.Slate
				p.Color = C(30, 26, 24):Lerp(C(58, 46, 40), math.random())
				p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
				local cf = CFrame.new(S.apex + S.fwd * dd + S.right * x) * CFrame.Angles(0, math.random() * 6.28, 0)
					* CFrame.Angles((math.random() - 0.5) * 0.9, 0, (math.random() - 0.5) * 0.9)
				p.CFrame = cf * CFrame.new(0, -h, 0)
				p.Parent = workspace
				table.insert(L.rubble, { p = p, cf = cf, h = h, born = M.SlamLand + math.max(dd, 0) / RUBBLE_SPEED })
			end
		end
	end
	for _, r in ipairs(L.rubble) do
		local age = u - r.born
		local k = age > 0 and smooth(age / 0.08) * (1 - smooth((age - 0.6) / 0.5)) or 0 -- (out fast, held, sunk back)
		r.p.CFrame = r.cf * CFrame.new(0, -r.h / 2 - 0.2 + r.h * 0.85 * k, 0)
	end
end

-- (client) the True Watchdog's fire: each one a few anchored parts this screen moves and then clears away
local function fxPart(shape, size, color, tr)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Shape, p.Size, p.Color, p.Material, p.Transparency = shape, size, color, MAT.Neon, tr
	p.Parent = workspace
	return p
end
-- where something lands: the floor cracking open from the centre out, jagged, the cracks glowing from beneath and a broken
-- seam round the edge, heat shimmering and embers rising off it. mark:glow(tr) as a part's Transparency (lower: hotter)
local function ring(at, r, color)
	local f = Instance.new("Folder")
	f.Name = "Telegraph"
	f.Parent = workspace
	local segs, born = {}, os.clock()
	local rng = Random.new(math.floor(at.X * 7 + at.Z * 13 + born * 100))
	local function seg(a, b, w, d) -- (a crack from a to b, w wide, showing d seconds in)
		local p = fxPart(Enum.PartType.Block, Vector3.new(w, 0.08, (b - a).Magnitude + w * 0.5), color, 1)
		p.CFrame = CFrame.lookAt((a + b) / 2, b) + Vector3.new(0, 0.06, 0)
		p.Parent = f
		table.insert(segs, { p = p, d = d })
	end
	local y = at.Y + 0.05
	local arms = math.floor(5 + r * 0.5)
	for i = 1, arms do -- the cracks, each a few jagged steps out, a branch forking off now and then
		local a = (i + rng:NextNumber(-0.3, 0.3)) / arms * pi * 2
		local p, w = Vector3.new(at.X, y, at.Z), 0.55
		for k = 1, 4 do
			a += rng:NextNumber(-0.45, 0.45)
			local q = p + Vector3.new(math.cos(a), 0, math.sin(a)) * r * rng:NextNumber(0.2, 0.28)
			seg(p, q, w, k * 0.07)
			if k >= 2 and rng:NextNumber() < 0.45 then
				local b = a + rng:NextNumber(0.5, 0.9) * (rng:NextNumber() < 0.5 and -1 or 1)
				seg(q, q + Vector3.new(math.cos(b), 0, math.sin(b)) * r * 0.18, w * 0.6, k * 0.07 + 0.05)
			end
			p, w = q, w * 0.8
		end
	end
	local n = math.floor(r * 2.2)
	for i = 1, n do -- the seam round its edge: broken, not quite round
		if rng:NextNumber() < 0.78 then
			local a1, a2 = i / n * pi * 2, (i + 0.8) / n * pi * 2
			local r1, r2 = r * rng:NextNumber(0.95, 1.04), r * rng:NextNumber(0.95, 1.04)
			seg(Vector3.new(at.X + math.cos(a1) * r1, y, at.Z + math.sin(a1) * r1), Vector3.new(at.X + math.cos(a2) * r2, y, at.Z + math.sin(a2) * r2), 0.3, 0.3)
		end
	end
	local heat = fxPart(Enum.PartType.Block, Vector3.new(r * 1.6, 0.2, r * 1.6), color, 1)
	heat.CFrame = CFrame.new(at + Vector3.new(0, 0.3, 0))
	heat.Parent = f
	local e = Instance.new("ParticleEmitter") -- (embers)
	e.Shape, e.Color, e.LightEmission = Enum.ParticleEmitterShape.Box, ColorSequence.new(C(255, 90, 50), C(120, 10, 5)), 0.6
	e.Size = NumberSequence.new(0.18, 0)
	e.Lifetime, e.Speed, e.Acceleration = NumberRange.new(0.8, 1.6), NumberRange.new(2, 5), Vector3.new(0, 3, 0)
	e.Rate = 4 + r * 2
	e.Parent = heat
	local h = Instance.new("ParticleEmitter") -- (heat: a faint dark shimmer of smoke rolling up off it)
	h.Shape, h.Texture, h.Color = Enum.ParticleEmitterShape.Box, SMOKE_TEX, ColorSequence.new(C(70, 20, 15))
	h.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 4) })
	h.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.88), NumberSequenceKeypoint.new(1, 1) })
	h.Lifetime, h.Speed, h.RotSpeed = NumberRange.new(1, 1.8), NumberRange.new(1.5, 3), NumberRange.new(-30, 30)
	h.Rate = 3 + r
	h.Parent = heat
	local mark = {}
	function mark:glow(tr) -- (each crack shows as the split reaches it, then glows as hot as told, flickering)
		local u = os.clock() - born
		for i, sg in ipairs(segs) do
			sg.p.Transparency = u < sg.d and 1 or math.clamp(tr - 0.25 + sin(u * 9 + i) * 0.05, 0, 1)
		end
	end
	function mark:Destroy()
		f:Destroy()
	end
	mark:glow(0.6)
	return mark
end
local function blast(at, r) -- a flash of fire: swelling, fading, flames thrown up
	local f = fxPart(BALL, Vector3.one, DARKH, 0.15)
	f.CFrame = CFrame.new(at)
	local e = flames(f, r * 0.7, 0, true)
	e.Speed, e.SpreadAngle, e.Acceleration = NumberRange.new(r * 0.8, r * 1.6), Vector2.new(80, 80), Vector3.new(0, 12, 0)
	e:Emit(math.floor(12 + r * 2))
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local k = (os.clock() - t0) / 0.4
		if k >= 1 then
			conn:Disconnect()
			f.Transparency = 1
			task.delay(1.5, function()
				f:Destroy()
			end)
			return
		end
		f.Size = Vector3.one * (1 + r * 2 * smooth(k))
		f.Transparency = 0.15 + 0.85 * k
	end)
end
-- the volley: a ball of fire lobbed from its mouth onto the ring it marks where you stood
local function trueShot(at, from, to)
	local orb = fxPart(BALL, Vector3.one * 4.5, DARKC, 0.15)
	local haze = fxPart(BALL, Vector3.one * 8, DARKH, 0.75) -- (a shell of see-through fire round the core)
	flames(orb, 7, 120, true)
	local trail = flames(orb, 4, 90, true)
	trail.Speed, trail.SpreadAngle, trail.Lifetime = NumberRange.new(1, 4), Vector2.new(180, 180), NumberRange.new(0.4, 0.9)
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = DARKH, 18, 3
	l.Parent = orb
	local mark = ring(to, M.ShotR, DARKH)
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local a = (workspace:GetServerTimeNow() - at) / M.ShotTime
		if a >= 1 then
			conn:Disconnect()
			orb:Destroy()
			haze:Destroy()
			mark:Destroy()
			blast(to + Vector3.new(0, 1, 0), M.ShotR)
			return
		end
		orb.CFrame = CFrame.new(from:Lerp(to, a) + Vector3.new(0, 10 * a * (1 - a), 0))
		haze.CFrame = orb.CFrame
		haze.Size = Vector3.one * (8 + sin(a * 40))
		mark:glow(0.75 - 0.4 * a)
	end)
end
-- the sunfall: a sun swelling over its head (L.headPos), hurled down onto a great ring; the ground left burning
local function trueSun(L, at, to)
	local sun = fxPart(BALL, Vector3.one, DARKC, 0.15)
	local e = flames(sun, 4, 90, true)
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = DARKH, 10, 3
	l.Parent = sun
	local mark = ring(to, M.SunR, DARKH)
	local thrownFrom
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local u = workspace:GetServerTimeNow() - at
		mark:glow(0.7 - 0.25 * (0.5 + 0.5 * sin(u * 12)))
		if u < M.SunCharge then
			local k = smooth(u / M.SunCharge)
			sun.Size = Vector3.one * (1 + 7 * k)
			e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1 + 3 * k), NumberSequenceKeypoint.new(0.3, 2 + 6 * k), NumberSequenceKeypoint.new(1, 0.5) })
			l.Range = 10 + 40 * k
			sun.CFrame = CFrame.new((L.headPos or to) + Vector3.new(0, 6 + 3 * k, 0))
		elseif u < M.SunCharge + M.SunFall then
			thrownFrom = thrownFrom or sun.Position
			local a = (u - M.SunCharge) / M.SunFall
			sun.CFrame = CFrame.new(thrownFrom:Lerp(to + Vector3.new(0, 3, 0), a * a))
		else
			conn:Disconnect()
			sun:Destroy()
			mark:Destroy()
			blast(to + Vector3.new(0, 2, 0), M.SunR)
			-- the pool: a molten glow and flames over it, burning, then dying down
			local pool = fxPart(CYL, Vector3.new(0.25, M.PoolR * 2, M.PoolR * 2), DARKC, 0.35)
			pool.CFrame = CFrame.new(to + Vector3.new(0, 0.18, 0)) * A(0, 0, pi / 2)
			local burners = {}
			for i = 1, 6 do
				local a, r = i / 6 * pi * 2, i % 2 == 0 and M.PoolR * 0.6 or M.PoolR * 0.25
				local b = fxPart(Enum.PartType.Block, Vector3.one, DARKC, 1)
				b.CFrame = CFrame.new(to + Vector3.new(math.cos(a) * r, 0.5, math.sin(a) * r))
				flames(b, 3.5, 30, true)
				table.insert(burners, b)
			end
			task.delay(M.SunBurn, function()
				for _, b in ipairs(burners) do
					b.ParticleEmitter.Enabled = false
				end
				for k = 1, 10 do
					pool.Transparency = 0.35 + 0.065 * k
					task.wait(0.08)
				end
				pool:Destroy()
				task.wait(1.4)
				for _, b in ipairs(burners) do
					b:Destroy()
				end
			end)
		end
	end)
end
-- the gale: at each beat, sheets of fire rolling out from its chest across the cone, low over the floor, fading
local function trueGale(L, at, yaw)
	for beat = 0, 1 do
		task.delay(math.max(0, at + M.GaleWind + beat * M.GaleGap - workspace:GetServerTimeNow()), function()
			local o = (L.chestPos or Vector3.zero) - Vector3.new(0, 6, 0)
			local sheets = {}
			for i = 1, 14 do
				local a = yaw + (-1 + 2 * (i - 0.5) / 14) * M.GaleHalf + (math.random() - 0.5) * 0.1
				local p = fxPart(Enum.PartType.Block, Vector3.new(2, 0.3, 3), i % 3 == 0 and DARKH or DARKC, 0.25)
				local e = flames(p, 3.5, 35, true)
				e.Acceleration = Vector3.new(0, 6, 0)
				table.insert(sheets, { p = p, d = Vector3.new(-sin(a), 0, -math.cos(a)), y = math.random() * 2 })
			end
			local t0 = os.clock()
			local conn
			conn = RunService.RenderStepped:Connect(function()
				local k = (os.clock() - t0) / 0.5
				for _, s in ipairs(sheets) do
					if k >= 1 then
						s.p:Destroy()
					else
						local pos = o + s.d * (2 + (M.GaleRange - 2) * smooth(k)) + Vector3.new(0, s.y + 1.5 * sin(k * pi), 0)
						s.p.Size = Vector3.new(2 + 5 * k, 0.3, 3 + 3 * k)
						s.p.CFrame = CFrame.lookAt(pos, pos + s.d)
						s.p.Transparency = 0.25 + 0.75 * k
					end
				end
				if k >= 1 then
					conn:Disconnect()
				end
			end)
		end)
	end
end
-- its poses: standing (legs straight under it), in flight (dangling), clinging to a pillar (braced), diving (talons out)
local TRUE_STAND = { L = { 0.06, -0.18, 0.12 }, R = { -0.04, -0.12, 0.08 } }
local TRUE_DANGLE = { L = { 0.55, -1, 0.75 }, R = { 0.35, -1.1, 0.85 } }
local TRUE_TALONS = { L = { 1.3, -0.35, -0.7 }, R = { 1.15, -0.25, -0.7 } }
local TRUE_PERCH = { L = { 1.35, -2.25, 0.95 }, R = { 1.25, -2.15, 0.9 } } -- (a gargoyle's squat, gripping the pillar's edge)
local function legsMix(a, b, k) -- (a fresh table: callers add to it)
	local out = {}
	for _, n in ipairs({ "L", "R" }) do
		out[n] = { a[n][1] + (b[n][1] - a[n][1]) * k, a[n][2] + (b[n][2] - a[n][2]) * k, a[n][3] + (b[n][3] - a[n][3]) * k }
	end
	return out
end
local function trueWatch(model, L) -- (once, as it's added: its attacks' events)
	-- its entrance: the ring under where it'll land, pulsing till it slams down (set before the model reached us)
	local enterAt, enterTo = model:GetAttribute("EnterAt"), model:GetAttribute("EnterTo")
	if enterAt and enterTo and workspace:GetServerTimeNow() - enterAt < M.EnterTime then
		local mark = ring(enterTo, M.EnterR, DARKH)
		local conn
		conn = RunService.RenderStepped:Connect(function()
			local u = workspace:GetServerTimeNow() - enterAt
			if u >= M.EnterTime or not model.Parent then
				conn:Disconnect()
				mark:Destroy()
				if model.Parent then
					blast(enterTo + Vector3.new(0, 1.5, 0), M.EnterR)
				end
				return
			end
			mark:glow(0.7 - 0.3 * (0.5 + 0.5 * sin(u * 14)))
		end)
	end
	model:GetAttributeChangedSignal("ShotAt"):Connect(function()
		trueShot(model:GetAttribute("ShotAt"), model:GetAttribute("ShotFrom"), model:GetAttribute("ShotTo"))
	end)
	model:GetAttributeChangedSignal("SunAt"):Connect(function()
		trueSun(L, model:GetAttribute("SunAt"), model:GetAttribute("SunTo"))
	end)
	model:GetAttributeChangedSignal("DiveAt"):Connect(function() -- (the dive: its mark cracking open under you till it lands)
		local at, to, dur = model:GetAttribute("DiveAt"), model:GetAttribute("DiveTo"), model:GetAttribute("DiveTime")
		local mark = ring(to, M.DiveR, DARKH)
		local conn
		conn = RunService.RenderStepped:Connect(function()
			local u = (workspace:GetServerTimeNow() - at) / dur
			if u >= 1 or not model.Parent then
				conn:Disconnect()
				mark:Destroy()
				if model.Parent then
					blast(to + Vector3.new(0, 1.5, 0), M.DiveR)
				end
				return
			end
			mark:glow(0.75 - 0.45 * u)
		end)
	end)
	model:GetAttributeChangedSignal("GaleAt"):Connect(function()
		trueGale(L, model:GetAttribute("GaleAt"), model:GetAttribute("GaleYaw"))
	end)
end
local function animTrue(model, L, dt, t, hrp)
	local now = workspace:GetServerTimeNow()
	local pos, moving, dir, kind = M.trueAt(model, now)
	if not pos or (hrp.Position - pos).Magnitude > 300 then
		return
	end
	local perched = model:GetAttribute("Perched")
	local yaw
	if moving and dir and Vector3.new(dir.X, 0, dir.Z).Magnitude > 2 then
		yaw = math.atan2(-dir.X, -dir.Z)
	elseif perched then
		yaw = model:GetAttribute("PerchYaw")
	elseif model:GetAttribute("FaceYaw") then
		yaw = model:GetAttribute("FaceYaw")
	else
		local d = hrp.Position - pos
		yaw = math.atan2(-d.X, -d.Z)
	end
	local dy = ((yaw - L.yaw + pi) % (2 * pi) - pi) * math.min(1, dt * (moving and 6 or 4))
	L.yaw += dy
	L.bank = (L.bank or 0) + (math.clamp(-dy / math.max(dt, 1e-3) * 0.12, -0.5, 0.5) - (L.bank or 0)) * math.min(1, dt * 5)
	L.flap = (L.flap or 0) + dt * (moving and 8 or perched and 2.6 or 2)
	L.halo += dt * (moving and 5 or 1.6)
	-- its head snaps between looks like a bird's - held, then a jerk to the next - never a smooth sway
	local beat = math.floor(t / (perched and 1.3 or 1.9))
	local tiltTo, lookTo = sin(beat * 12.9898) * (perched and 0.45 or 0.25), sin(beat * 78.233) * 0.3
	L.tilt = (L.tilt or 0) + (tiltTo - (L.tilt or 0)) * math.min(1, dt * 14)
	L.look = (L.look or 0) + (lookTo - (L.look or 0)) * math.min(1, dt * 14)
	local c = { halo = L.halo, stare = moving and 0.3 or 1, gape = 0.3 + sin(t * 1.7) * 0.08, lean = 0, reach = 0, tilt = L.tilt, look = L.look, bank = moving and L.bank or 0 }
	c.side = { L = { 0, 0, 0 }, R = { 0, 0, 0 } }
	local function wingAdd(n, sp, fl, re)
		local o = c.side[n]
		o[1], o[2], o[3] = o[1] + sp, o[2] + fl, o[3] + re
	end
	local function legAdd(n, sw, kn, pw)
		local g = c.legs[n]
		g[1], g[2], g[3] = g[1] + sw, g[2] + kn, g[3] + pw
	end
	local mAt, mDur = model:GetAttribute("MoveAt"), model:GetAttribute("MoveTime") or 1
	local into = mAt and now - mAt or 1e9
	local since = into - mDur -- (since it last came down)
	if moving and kind == "dive" then
		c.spread, c.flap, c.reach, c.lean, c.legs, c.gape, c.display, c.curl = 0.7, 0.2, -1, 0.7, TRUE_TALONS, 1, 0.5, -0.5
		c.flapH = 0.2 + sin(t * 30) * 0.15 -- (its wingtips shuddering in the rush)
		c.legs = legsMix(TRUE_TALONS, TRUE_TALONS, 0)
		legAdd("R", 0.3, -0.4, 0.2) -- (one foot reaching ahead of the other)
		wingAdd("L", -0.35, -0.2, -0.3)
		wingAdd("R", 0.15, 0.25, 0.2)
		c.croll, c.ctwist, c.tilt = 0.25, 0.2, c.tilt - 0.3
	elseif moving then
		-- the beat: the wing's root leads, the forearm and hand follow late, whipping; the body rides up on each downstroke
		local off = smooth(into / 0.25) -- (just off the ground: the legs still kicking down, wings flung up)
		c.spread, c.lean, c.display = 1, 0.35 * off, 0.25 + 0.75 * (1 - off)
		c.flap, c.flapF, c.flapH = sin(L.flap) * off + (1 - off), sin(L.flap - 0.7) * off + (1 - off), sin(L.flap - 1.4) * off + (1 - off) * 0.6
		c.bob = -sin(L.flap) * 0.7 * off
		c.legs = legsMix(TRUE_PERCH, TRUE_DANGLE, off)
		c.legs.L[1] += sin(L.flap * 0.5) * 0.15 -- (dangling, swaying with the beat)
		c.legs.R[1] += sin(L.flap * 0.5 + 1) * 0.15
		c.crouch, c.curl = 2.5 * (1 - off), sin(L.flap - 2) * 0.3
	elseif perched then
		-- crouched on the pillar's lip like a gargoyle: hunched out over the drop, head low and cocked, both wings mantled
		-- forward round it like a cloak, the tail hooked round the stone behind; breathing, the wing edges creeping
		local breath = sin(t * 1.1)
		c.spread, c.flap, c.reach, c.legs, c.crouch, c.lean = 0.95, -0.25 + breath * 0.05, 0.75 + breath * 0.04, TRUE_PERCH, 3.8, 0.6
		c.flapH, c.fan, c.curl, c.nod, c.gape = -0.4 + sin(t * 0.7) * 0.1, -0.25, 1, 0.35, 0.2 + math.max(0, breath) * 0.25
		local ps = math.floor((model:GetAttribute("PerchYaw") or 0) * 10) % 2 == 0 and 1 or -1 -- (which way it sits: each spire its own)
		local open, shut = ps > 0 and "R" or "L", ps > 0 and "L" or "R"
		c.legs = legsMix(TRUE_PERCH, TRUE_PERCH, 0)
		wingAdd(open, 0.1, 0.55 + breath * 0.05, -1.25)
		wingAdd(shut, 0, -0.15, 0.25)
		legAdd(open, 0.35, -0.35, 0.1) -- (that foot up on the lip, the other hanging back)
		legAdd(shut, -0.2, 0.25, 0)
		c.ctwist, c.croll, c.bank, c.twist = ps * 0.35, ps * 0.12, -ps * 0.08, -ps * 0.15
		c.tilt, c.look = c.tilt + ps * 0.35, c.look - ps * 0.2
		local land = smooth(1 - since / 0.45) -- (just landed: wings flung wide to catch itself)
		if land > 0 then
			c.reach, c.flap, c.fan = c.reach * (1 - land) - 0.6 * land, c.flap + land * 0.8, c.fan * (1 - land)
		end
	else
		-- on the ground: its weight rolling foot to foot, wings breathing open and shut; every so often it rears and flares them
		-- full, jaw wide - a threat display
		local shift = sin(t * 0.9)
		local cyc = t % 8
		local flare = cyc < 1.6 and sin(cyc / 1.6 * pi) or 0
		c.spread, c.legs = 0.8 + sin(t * 0.8) * 0.06 + flare * 0.2, legsMix(TRUE_STAND, TRUE_STAND, 0)
		c.flap, c.flapF, c.flapH = 0.15 + sin(t * 1.6) * 0.06 + flare * 0.5, 0.1 + sin(t * 1.6 - 0.6) * 0.08, sin(t * 1.6 - 1.2) * 0.12 - flare * 0.3
		c.bank, c.twist, c.bob = shift * 0.05, sin(t * 0.45) * 0.08, -math.abs(shift) * 0.15
		c.legs.L[2] -= math.max(0, shift) * 0.25 -- (the unweighted knee eases)
		c.legs.R[2] -= math.max(0, -shift) * 0.25
		c.lean, c.gape, c.nod, c.fan = -0.25 * flare, c.gape + flare * 0.7, -0.3 * flare, flare * 0.3
		-- contrapposto: the weight sunk into one hip, the chest wrung back the other way at you, one wing hiked high and
		-- forward, the other low and trailing; every dozen seconds it shifts its weight over and the whole pose mirrors
		local w = math.clamp(sin(t * 0.26) * 2.2, -1, 1) -- (+1: its weight on its left foot)
		local wl, wr = math.max(0, w), math.max(0, -w)
		c.bank, c.twist, c.crouch = c.bank + w * 0.1, c.twist + w * 0.24, 0.5 * math.abs(w)
		c.ctwist, c.croll = -w * 0.4 - w * flare * 0.25, -w * 0.08
		c.tilt, c.look = c.tilt + w * 0.2, c.look + w * 0.16
		legAdd("L", -0.08 * wl + 0.45 * wr, -0.75 * wr, 0.32 * wr) -- (the free leg stepped out ahead, knee bent)
		legAdd("R", -0.08 * wr + 0.45 * wl, -0.75 * wl, 0.32 * wl)
		wingAdd("L", 0, 0.55 * w + flare * 0.5 * wl, 0.35 * w + flare * 0.3 * wl)
		wingAdd("R", 0, -0.55 * w + flare * 0.5 * wr, -0.35 * w + flare * 0.3 * wr)
		local land = smooth(1 - since / 0.5) -- (just come down: the knees taking the weight, wings thrown down for balance)
		if land > 0 then
			c.crouch, c.lean, c.flap, c.spread = 3 * land, c.lean + 0.5 * land, c.flap - 0.7 * land, 1
			c.legs = legsMix(c.legs, TRUE_PERCH, land * 0.8)
		end
	end
	local galeAt, sunAt, shotAt = model:GetAttribute("GaleAt"), model:GetAttribute("SunAt"), model:GetAttribute("ShotAt")
	local ug = galeAt and now - galeAt
	if ug and ug >= 0 and ug < M.GaleTime then -- (the gale: drawn back, two beats)
		c.reach, c.flap, c.lean = M.galePose(ug)
		c.spread, c.gape = 1, 0.8
		c.legs = c.legs and legsMix(c.legs, c.legs, 0) or legsMix(TRUE_STAND, TRUE_STAND, 0)
		c.side = { L = { 0, 0, 0 }, R = { 0, 0, 0 } }
		if ug < M.GaleWind then
			local k = smooth(ug / M.GaleWind)
			c.ctwist, c.twist, c.croll, c.look = 0.6 * k, 0.15 * k, -0.1 * k, -0.5 * k
			wingAdd("R", 0, 0.4 * k, -0.7 * k)
			wingAdd("L", 0, -0.25 * k, 0.45 * k)
			legAdd("L", 0.35 * k, -0.5 * k, 0.2 * k)
			c.crouch = 0.8 * k
		else
			local v = ug - M.GaleWind
			local second = v >= M.GaleGap
			local o = smooth((second and v - M.GaleGap or v) / 0.16)
			local fade = second and 1 - smooth((v - M.GaleGap - 0.25) / 0.4) or 1
			local dir, lead, other = second and -1 or 1, second and "L" or "R", second and "R" or "L"
			c.ctwist = dir * (0.6 - 1.2 * o) * fade
			c.twist, c.bank, c.look = c.ctwist * 0.35, dir * 0.14 * o * fade, -c.ctwist * 0.75
			c.croll, c.tilt = -dir * 0.12 * o * fade, c.tilt + dir * 0.2 * o * fade
			wingAdd(lead, 0, (0.4 * (1 - o) - 0.35 * o) * fade, (-0.7 * (1 - o) + 1 * o) * fade)
			wingAdd(other, 0, 0.35 * o * fade, -0.4 * o * fade)
			legAdd(lead, 0.55 * o * fade, -0.65 * o * fade, 0.25 * o * fade) -- (lunging after it)
			legAdd(other, -0.3 * o * fade, -0.1 * o * fade, 0)
			c.crouch = (c.crouch or 0) + 1.1 * o * fade
		end
	end
	local us = sunAt and now - sunAt
	if us and us >= 0 and us < M.SunCharge + 0.5 then -- (the sunfall: wings raised over it, then flung forward)
		local th = smooth((us - M.SunCharge) / 0.2)
		c.spread, c.flap, c.reach, c.lean, c.gape = 1, 1 - 1.5 * th, 0.5 + 0.5 * th, -0.2 + 0.7 * th, 0.7
		local k = smooth(us / M.SunCharge) * (1 - th)
		c.side = { L = { 0, 0, 0 }, R = { 0, 0, 0 } }
		wingAdd("R", 0, 0.5 * k - 0.6 * th, 0.4 * k + 0.4 * th) -- (the raised wing: up over it, then flung down through the throw)
		wingAdd("L", 0, -0.9 * k + 0.3 * th, -0.9 * k - 0.4 * th)
		c.ctwist, c.croll = 0.4 * k - 0.55 * th, -0.18 * k + 0.1 * th
		c.twist, c.bank = (c.twist or 0) + 0.15 * k - 0.2 * th, (c.bank or 0) + 0.08 * k - 0.12 * th
		c.nod, c.tilt, c.look = -0.35 * k + 0.25 * th, c.tilt + 0.3 * k, -c.ctwist * 0.6
	end
	local ush = shotAt and now - shotAt
	if ush and ush >= 0 and ush < 0.4 then -- (each shot: the jaw wide, a jolt forward)
		local k = 1 - ush / 0.4
		c.gape, c.lean = 0.3 + 0.7 * k, c.lean + 0.3 * k
		local sg = math.floor(shotAt * 7) % 2 == 0 and 1 or -1
		c.ctwist, c.look, c.tilt = (c.ctwist or 0) + sg * 0.35 * k, c.look - sg * 0.25 * k, c.tilt + sg * 0.2 * k
		wingAdd(sg > 0 and "R" or "L", 0, 0.5 * k, 0.3 * k)
	end
	local world = pose(L.sp, CFrame.new(pos) * CFrame.Angles(0, L.yaw, 0), t * L.sp.speed, t, c)
	for i, p in pairs(L.parts) do
		local s = L.sp.parts[i]
		p.CFrame = world[s.bone] * s.cf
	end
	L.headPos, L.chestPos = world.head.Position, world.chest.Position
	-- its stand-in among the enemies (what you lock onto), on this screen at its chest
	local enemies = workspace:FindFirstChild("Enemies")
	L.proxy = L.proxy and L.proxy.Parent and L.proxy or enemies and enemies:FindFirstChild(M.TrueName)
	local root = L.proxy and L.proxy:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = CFrame.new(L.chestPos + Vector3.new(0, 2, 0))
	end
end

function M.animate()
	local folder = workspace:WaitForChild("PyralisProtos", 120)
	if not folder then
		return
	end
	local player = Players.LocalPlayer
	local enemies = workspace:FindFirstChild("Enemies")
	local live = {}
	local function add(model)
		local v = model:GetAttribute("Variant")
		if not (v and DESIGNS[v]) then
			return
		end
		local parts = {}
		local function take(p)
			local i = p:GetAttribute("Index")
			if i then
				parts[i] = p
			end
		end
		for _, p in ipairs(model:GetChildren()) do
			take(p)
		end
		model.ChildAdded:Connect(take) -- (a model added mid-game can reach us before its parts do)
		if v == "D" then -- (the True Watchdog: its own animation)
			live[model] = { sp = spec(v), parts = parts, isTrue = true, yaw = 0, halo = 0 }
			trueWatch(model, live[model])
			return
		end
		live[model] = { sp = spec(v), parts = parts, at = model:GetAttribute("Base").Position, yaw = 0, halo = 0, w = 0, step = 0 }
	end
	for _, m in ipairs(folder:GetChildren()) do
		add(m)
	end
	folder.ChildAdded:Connect(add)
	RunService.RenderStepped:Connect(function(dt)
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end
		local t = os.clock()
		for model, L in pairs(live) do
			if not model.Parent then
				live[model] = nil
				if L.fire then
					drawBreath(L, nil) -- (slain mid-breath: its fire put out)
				end
				drawSwipe(L, nil)
				drawSlam(L, nil)
			elseif L.isTrue then
				animTrue(model, L, dt, t, hrp)
			elseif (hrp.Position - L.at).Magnitude < 260 and (not model:GetAttribute("Lair") or model:GetAttribute("EmergeAt")) then
				local at = model:GetAttribute("LeapTo") or L.at -- (where it stands now: where its last leap took it)
				local d = hrp.Position - at
				local want = math.atan2(-d.X, -d.Z)
				local off, ph, c, base = CFrame.identity, t * L.sp.speed, nil, nil
				local now = workspace:GetServerTimeNow()
				local settled = true -- (free to turn about as it likes: not crawling out, not in the air)
				if model:GetAttribute("Lair") then -- (its entrance, and after it: the server's clock, so every client agrees)
					local tau = now - model:GetAttribute("EmergeAt")
					settled = tau >= M.Total
					local stare, spin, legs, strain, gape
					off, ph, stare, spin, legs, strain, gape = M.emerge(tau, t)
					L.halo += dt * spin
					c = { stare = stare, halo = L.halo, legs = legs, strain = strain, gape = gape }
					if tau < M.See then
						want = 0 -- (straight out, till it sees you)
					elseif tau < M.Total then
						want = math.clamp(want, -L.sp.turn, L.sp.turn) -- (its tail still in the lair: never far off north)
					end
				else
					want = math.clamp(want, -L.sp.turn, L.sp.turn)
				end
				local leapAt, breathAt = model:GetAttribute("LeapAt"), model:GetAttribute("BreathAt")
				local u = leapAt and now - leapAt
				local ub = breathAt and now - breathAt
				local turn = 1.5
				if ub and ub >= 0 and ub < M.BreathEnd then
					drawBreath(L, M.breathOf(model), ub)
				elseif L.fire then
					drawBreath(L, nil)
				end
				local swipeAt = model:GetAttribute("SwipeAt")
				local us = swipeAt and now - swipeAt
				local tracking = false
				if us and us >= 0 and us < M.SwipeWind + 1.8 then -- (its tell, the strike, and the rubble sinking after)
					drawSwipe(L, at, us, math.floor(swipeAt * 100), model:GetAttribute("SwipeYaw"))
				elseif L.swipeSeed then
					drawSwipe(L, nil)
				end
				local slamAt = model:GetAttribute("SlamAt")
				local usl = slamAt and now - slamAt
				if usl and usl >= 0 and usl < M.SlamEnd then
					drawSlam(L, M.slamOf(model), usl)
				elseif L.rubble then
					drawSlam(L, nil)
				end
				if u and u >= 0 and u < M.LeapTime then
					local yaw
					base, ph, c, yaw = M.leap(u, model:GetAttribute("LeapFrom"), model:GetAttribute("LeapTo"), t)
					L.halo += dt * 4
					c.halo = L.halo
					L.yaw = yaw -- (it comes down facing the way it leapt, and turns on from there)
					settled = false
				elseif usl and usl >= 0 and usl < M.SlamTime then -- (the rearing slam: facing where it aimed)
					L.yaw += ((model:GetAttribute("SlamYaw") - L.yaw + pi) % (2 * pi) - pi) * math.min(1, dt * 8)
					local sc
					base, sc = M.slam(usl, at, L.yaw, t)
					sc.halo = c and c.halo
					c = sc
					settled = false
				elseif us and us >= 0 and us < M.SwipeTime then -- (the tail slash: its turning is the attack's)
					L.yaw = M.swipeYaw(model:GetAttribute("SwipeYaw"), us)
					local drop, sc = M.swipe(us, t)
					sc.halo = c and c.halo
					c = sc
					base = CFrame.new(at) * CFrame.Angles(0, L.yaw, 0) * CFrame.new(0, -drop, 0)
				else
					if ub and ub >= 0 and ub < M.BreathWind + M.BreathTime + 0.5 then -- (breathing: facing where its head sweeps)
						local bc
						want, bc = M.breath(M.breathOf(model), ub)
						bc.halo, bc.legs = c and c.halo, c and c.legs
						c, turn = bc, 8
					else
						tracking = true
					end
					L.yaw += ((want - L.yaw + pi) % (2 * pi) - pi) * math.min(1, dt * turn)
					base = CFrame.new(at) * CFrame.Angles(0, L.yaw, 0) * off
				end
				-- turning, whatever turns it: the head leading round toward where it's going, the forelegs stepping it round,
				-- the chest leaning into it, the long body dragged after in a curve
				local w = ((L.yaw - (L.lastYaw or L.yaw) + pi) % (2 * pi) - pi) / math.max(dt, 1e-3)
				L.lastYaw = L.yaw
				L.w += (math.clamp(w, -14, 14) - L.w) * math.min(1, dt * 10)
				if c and settled then
					c.trail = math.clamp(L.w, -8, 8)
					c.lead = tracking and math.clamp((want - L.yaw + pi) % (2 * pi) - pi, -0.9, 0.9) or 0
					local k = math.min(1, math.abs(L.w) * 1.2)
					L.step += dt * 7 * k
					if k > 0.01 then
						local legs = {}
						for _, n in ipairs({ "L", "R" }) do
							local of = n == "L" and 0 or pi
							local b = c.legs and c.legs[n] or { 0, 0, 0 }
							local lift = math.max(0, sin(L.step + of + 1.2)) * k
							legs[n] = { b[1] + sin(L.step + of) * 0.4 * k, b[2] - lift * 0.9, b[3] + lift * 0.5 }
						end
						c.legs = legs
					end
					base *= CFrame.Angles(0, 0, -c.trail * 0.03)
				end
				-- the long body dragged after it: each segment (S1..S8, T1, T2) slowly turning after the one it hangs off, so a
				-- turn leaves a curve that straightens as it's pulled through; in its attacks and entrance, held straight
				L.drag = L.drag or {}
				local prevW, drag = L.yaw, {}
				for i = 1, 10 do
					local w = L.drag[i] or prevW
					if settled then
						w += ((prevW - w + pi) % (2 * pi) - pi) * math.min(1, dt * 2.5)
					end
					local r = settled and math.clamp((w - prevW + pi) % (2 * pi) - pi, -0.4, 0.4) or 0
					L.drag[i], drag[i], prevW = prevW + r, r, prevW + r
				end
				if c then
					c.drag = drag
				end
				local world = pose(L.sp, base, ph, t, c)
				for i, p in pairs(L.parts) do
					local s = L.sp.parts[i]
					p.CFrame = world[s.bone] * s.cf
				end
				-- its stand-in among the enemies (what you lock onto), set here on its neck: the server keeps it on the chest
				-- for blows to land on; on this screen it rides up the neck, where the lock-on sits right
				enemies = enemies or workspace:FindFirstChild("Enemies")
				L.proxy = L.proxy and L.proxy.Parent and L.proxy or enemies and enemies:FindFirstChild(M.Name)
				local root = L.proxy and L.proxy:FindFirstChild("HumanoidRootPart")
				if root and world.neck then
					root.CFrame = CFrame.new((world.neck * CFrame.new(0, 0.5, -2.5)).Position)
				end
			end
		end
	end)
end

return M
