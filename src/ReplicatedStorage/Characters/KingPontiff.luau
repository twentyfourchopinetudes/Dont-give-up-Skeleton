--!nonstrict
-- THE KING OF PYRALIS - proposal C of five (kind KingPontiff): THE SUN-PONTIFF. The king as high priest of the cult
-- his mages serve - the Pyre priests' master, in what they wear grown grand: a triple crown on a tall ivory tiara,
-- its lappets fringed; behind his head the priests' halo of fire, wider; a cope of crimson brocade, its orphreys
-- worked in panels of gold and colour, clasped by a great morse; under it an ivory chasuble trellised in gold, the
-- pallium down its front sewn with suns; bell sleeves over lace; the alb to his feet, lace at its hem. In his right
-- hand the priests' sun-wheel staff, fire caged in its spokes. (Shared pose, mask and spawn: Characters/KingGilded.)
local Base = require(script.Parent:WaitForChild("KingGilded"))

local M = table.clone(Base)
M.Kind = "KingPontiff"
M.Proportions = { girth = 0.92, arm = 1.08, hunch = 0 }
local rgb = Color3.fromRGB
local IVORY, IVORY_DK, CRIM, CRIM_DK = rgb(226, 214, 190), rgb(176, 162, 136), rgb(118, 20, 24), rgb(66, 10, 14)
local GOLD, GOLD_DK, SUN, FLAME = rgb(200, 154, 68), rgb(136, 96, 40), rgb(255, 200, 90), rgb(255, 110, 30)
local PANEL = { rgb(30, 54, 120), rgb(150, 24, 30), rgb(36, 86, 50) } -- (the orphreys' coloured panels)
M.Colors = { skin = IVORY_DK, torso = IVORY, legs = IVORY, arms = IVORY }

local cyl, ball, FACE = Base.cyl, Base.ball, Base.FACE

local function lace(k, on, n, x1, x2, y, z, len)
	for i = 0, n - 1 do
		local x = x1 + (x2 - x1) * i / (n - 1)
		k.deco(on, "Lace", k.V(0.05, len * (i % 2 == 0 and 1 or 0.65), 0.03), k.at(x, y - len / 2, z), IVORY, k.MAT.Fabric)
	end
end

function M.Look(k)
	local deco, parts, V, at, MAT = k.deco, k.parts, k.V, k.at, k.MAT
	local cw, ch, cd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.aw, k.lw, k.la, k.ua
	local up = CFrame.Angles(0, 0, math.pi / 2)
	-- THE HEAD: an ivory amice close round it, the mask before it
	parts.Head.Color = IVORY_DK
	deco("Head", "Amice", V(1.28, 1.32, 1.28), at(0, 0, 0.06), IVORY, MAT.Fabric)
	Base.Mask(k, GOLD, GOLD_DK)
	-- THE TIARA: a tall drum of ivory narrowing up, three coronets of gold round it - each a band, gems, points -
	-- a sun-orb on top; behind, two lappets to the shoulders, a sun on each and gold fringe at the ends
	for i = 0, 6 do
		local d = 1.3 - i * 0.1
		deco("Head", "Tiara", V(0.32, d, d), at(0, 0.72 + i * 0.3, 0.06) * up, IVORY, MAT.Fabric, cyl)
	end
	for c = 0, 2 do
		local y, d = 0.7 + c * 0.66, 1.36 - c * 0.2
		deco("Head", "Coronet", V(0.2, d, d), at(0, y, 0.06) * up, GOLD, MAT.Metal, cyl)
		deco("Head", "CoronetRim", V(0.05, d + 0.04, d + 0.04), at(0, y + 0.1, 0.06) * up, GOLD_DK, MAT.Metal, cyl)
		local n = 10 - c * 2
		for i = 0, n - 1 do
			local a = i / n * math.pi * 2
			local r = d / 2
			local p = at(math.sin(a) * r, y, 0.06 - math.cos(a) * r)
			deco("Head", "CoronetGem", V(0.1, 0.1, 0.06), p * CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, math.pi / 4), PANEL[i % 3 + 1], MAT.Glass)
			deco("Head", "CoronetPoint", V(0.09, 0.22, 0.04), at(math.sin(a) * r, y + 0.2, 0.06 - math.cos(a) * r) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, math.pi / 4), GOLD, MAT.Metal)
		end
	end
	deco("Head", "TiaraOrb", V(0.28, 0.28, 0.28), at(0, 2.75, 0.06), GOLD, MAT.Metal, ball)
	Base.sun(k, "Head", at(0, 3.05, 0.06), 0.18, GOLD, FLAME)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "Lappet", V(0.26, 1.3, 0.05), at(sx * 0.3, -0.35, 0.72), IVORY, MAT.Fabric)
		deco("Head", "LappetBand", V(0.28, 0.06, 0.06), at(sx * 0.3, -0.92, 0.72), GOLD, MAT.Metal)
		Base.sun(k, "Head", at(sx * 0.3, -0.6, 0.75) * CFrame.Angles(0, math.pi, 0), 0.08, CRIM)
		for i = 0, 4 do
			deco("Head", "LappetFringe", V(0.04, 0.14, 0.03), at(sx * 0.3 - 0.1 + i * 0.05, -1.05, 0.72), GOLD, MAT.Metal)
		end
	end
	-- THE HALO: the priests' ring of fire, wider, behind his head
	for i = 0, 23 do
		local a = i / 24 * math.pi * 2
		local p = deco("Head", "Halo", V(0.18, 0.4, 0.18), at(math.cos(a) * 1.55, 0.45 + math.sin(a) * 1.55, 0.95) * CFrame.Angles(0, 0, a), SUN, MAT.Neon)
		if i % 4 == 0 then
			local f = Instance.new("Fire")
			f.Size, f.Heat = 1.6, 4
			f.Color, f.SecondaryColor = FLAME, rgb(120, 20, 6)
			f.Parent = p
		end
	end
	local hl = deco("Head", "HaloLight", V(0.2, 0.2, 0.2), at(0, 0.45, 0.95), SUN, MAT.Neon)
	hl.Transparency = 1
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = FLAME, 14, 1.5
	l.Parent = hl
	-- THE CHASUBLE: ivory, trellised in gold, a gem in every other lozenge; the pallium down its middle, with suns
	local fz = -cd * 0.56 - 0.02
	deco("Chest", "Chasuble", V(cw * 1.08, ch * 1.02, cd * 1.12), at(0, 0, 0), IVORY, MAT.Fabric)
	Base.lattice(k, "Chest", cw * 0.5, ch * 0.9, 0, -0.02, fz, 0.24, GOLD)
	Base.brocade(k, "Chest", 0, -0.02, fz - 0.01, 4, 7, 0.24, 0.06, CRIM, PANEL[1])
	deco("Chest", "Pallium", V(0.26, ch * 0.92, 0.05), at(0, -0.04, fz - 0.03), IVORY, MAT.Fabric)
	deco("Chest", "PalliumEdge", V(0.3, ch * 0.92, 0.04), at(0, -0.04, fz - 0.015), GOLD, MAT.Metal)
	for j = 0, 2 do
		Base.sun(k, "Chest", at(0, 0.45 - j * 0.42, fz - 0.07), 0.1, CRIM)
	end
	deco("Chest", "PalliumRing", V(1.2, 0.16, 1.05), at(0, ch / 2 - 0.02, 0.02), IVORY, MAT.Fabric)
	deco("Chest", "PalliumRingEdge", V(1.24, 0.04, 1.09), at(0, ch / 2 - 0.1, 0.02), GOLD, MAT.Metal)
	-- THE COPE: crimson brocade over the shoulders and down the back and sides; its orphreys down the front, each a
	-- column of panels of colour framed in gold; the morse clasping it at the breast
	deco("Chest", "CopeShoulders", V(cw * 1.3, 0.4, cd * 1.45), at(0, ch / 2 - 0.14, 0.06), CRIM, MAT.Fabric)
	deco("Chest", "CopeBack", V(cw * 1.28, ch * 1.25, 0.12), at(0, -0.15, cd * 0.66), CRIM, MAT.Fabric)
	Base.lattice(k, "Chest", cw * 1.2, 0.36, 0, ch / 2 - 0.14, -cd * 0.73 - 0.01, 0.2, GOLD_DK)
	for _, sx in ipairs({ -1, 1 }) do
		local ox = sx * cw * 0.4
		deco("Chest", "CopeSide", V(cw * 0.22, ch * 1.02, cd * 1.25), at(sx * cw * 0.47, -0.02, 0.02), CRIM, MAT.Fabric)
		deco("Chest", "Orphrey", V(0.34, ch * 1.0, 0.05), at(ox, -0.02, -cd * 0.65), GOLD, MAT.Metal)
		for j = 0, 3 do
			local y = ch * 0.36 - j * 0.38
			deco("Chest", "OrphreyPanel", V(0.24, 0.28, 0.03), at(ox, y, -cd * 0.68), PANEL[(j + (sx > 0 and 1 or 0)) % 3 + 1], MAT.Fabric)
			Base.sun(k, "Chest", at(ox, y, -cd * 0.7), 0.07, GOLD)
		end
	end
	local my = ch / 2 - 0.4
	deco("Chest", "Morse", V(0.42, 0.42, 0.08), at(0, my, -cd * 0.72) * CFrame.Angles(0, 0, math.pi / 4), GOLD, MAT.Metal)
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2
		deco("Chest", "MorseLobe", V(0.2, 0.2, 0.2), at(math.cos(a) * 0.28, my + math.sin(a) * 0.28, -cd * 0.72), GOLD_DK, MAT.Metal, ball)
	end
	deco("Chest", "MorseStone", V(0.08, 0.2, 0.2), at(0, my, -cd * 0.78) * FACE, PANEL[2], MAT.Glass, cyl)
	Base.studs(k, "Chest", 2, -0.12, 0.12, my - 0.12, -cd * 0.79, 0.06, SUN, MAT.Neon)
	-- THE SLEEVES: the alb's close ivory, lace at the wrist; over them the cope's bell sleeves, gold-hemmed, trellised
	for _, n in ipairs({ "R", "L" }) do
		deco(n .. "UpperArm", "BellSleeve", V(aw * 1.6, ua * 0.95, aw * 1.6), at(0, 0, 0), CRIM, MAT.Fabric)
		deco(n .. "UpperArm", "SleeveBand", V(aw * 1.65, 0.1, aw * 1.65), at(0, -ua * 0.35, 0), GOLD, MAT.Metal)
		Base.brocade(k, n .. "UpperArm", 0, 0.05, -aw * 0.81, 2, 3, 0.2, 0.06, GOLD, GOLD_DK)
		deco(n .. "LowerArm", "Bell", V(aw * 1.9, la * 0.55, aw * 1.9), at(0, la * 0.18, 0), CRIM, MAT.Fabric)
		deco(n .. "LowerArm", "BellHem", V(aw * 1.95, 0.1, aw * 1.95), at(0, -la * 0.08, 0), GOLD, MAT.Metal)
		Base.studs(k, n .. "LowerArm", 3, -aw * 0.6, aw * 0.6, la * 0.2, -aw * 0.97, 0.07, PANEL[1], MAT.Glass)
		deco(n .. "LowerArm", "Alb", V(aw * 1.2, la * 0.4, aw * 1.2), at(0, -la * 0.25, 0), IVORY, MAT.Fabric)
		for f = 0, 3 do
			local face = CFrame.Angles(0, f * math.pi / 2, 0)
			for i = 0, 3 do
				deco(n .. "LowerArm", "Lace", V(0.05, 0.12, 0.03), face * at(-aw * 0.45 + i * aw * 0.3, -la * 0.45, -aw * 0.62), IVORY, MAT.Fabric)
			end
		end
	end
	deco("LLowerArm", "Ring", V(0.12, 0.12, 0.12), at(-aw * 0.3, -la / 2 - 0.2, -aw * 0.5), PANEL[2], MAT.Glass, ball)
	-- THE ALB to his feet, gold-hemmed, a crimson band down each knee, lace at the hem; the cope's falls either side
	Base.lapRobe(k, IVORY, GOLD, CRIM, CRIM_DK)
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		lace(k, n .. "Shin", 6, -sx * 0.07 - lw * 0.75, -sx * 0.07 + lw * 0.75, -0.58, -lw * 0.62, 0.16)
		Base.sun(k, n .. "Shin", at(-sx * 0.07, 0.1, -lw * 0.64), 0.12, GOLD)
		deco(n .. "Thigh", "CopeFall", V(0.1, 1.2, 1.25), at(-sx * 0.07 + sx * (lw * 0.875 + 0.06), 0.05, 0.5), CRIM, MAT.Fabric)
		deco(n .. "Thigh", "CopeFallHem", V(0.12, 0.08, 1.27), at(-sx * 0.07 + sx * (lw * 0.875 + 0.06), -0.57, 0.5), GOLD, MAT.Metal)
	end
	-- THE STAFF, upright in his right hand: the priests' sun-wheel, grown - a ringed shaft, a wheel of twelve
	-- segments and six spokes, fire caged in it
	local G = Base.held(k)
	deco("RLowerArm", "StaffShaft", V(0.16, 4.8, 0.16), G * at(0, 0.3, 0), GOLD_DK, MAT.Metal)
	for _, y in ipairs({ -1.8, -0.9, 0.6, 1.4, 2.2 }) do
		deco("RLowerArm", "StaffRing", V(0.26, 0.1, 0.26), G * at(0, y, 0), GOLD, MAT.Metal)
	end
	local W = G * at(0, 3.25, 0)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		deco("RLowerArm", "Wheel", V(0.14, 0.32, 0.14), W * at(math.cos(a) * 0.6, math.sin(a) * 0.6, 0) * CFrame.Angles(0, 0, a), GOLD, MAT.Metal)
		deco("RLowerArm", "WheelRay", V(0.08, 0.2, 0.06), W * at(math.cos(a) * 0.82, math.sin(a) * 0.82, 0) * CFrame.Angles(0, 0, a - math.pi / 2), GOLD_DK, MAT.Metal)
	end
	for i = 0, 2 do
		deco("RLowerArm", "Spoke", V(0.06, 1.2, 0.06), W * CFrame.Angles(0, 0, i * math.pi / 3), GOLD_DK, MAT.Metal)
	end
	local core = deco("RLowerArm", "WheelFire", V(0.4, 0.4, 0.4), W, SUN, MAT.Neon, ball)
	local f = Instance.new("Fire")
	f.Size, f.Heat = 2.2, 5
	f.Color, f.SecondaryColor = FLAME, rgb(120, 20, 6)
	f.Parent = core
	local fl = Instance.new("PointLight")
	fl.Color, fl.Range, fl.Brightness = FLAME, 12, 1.4
	fl.Parent = core
end

return M
