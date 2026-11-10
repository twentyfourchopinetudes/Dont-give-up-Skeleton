--!nonstrict
-- THE KING OF PYRALIS - proposal D of five (kind KingMolten): THE MOLTEN TYRANT. The king the fire has kept: robes of
-- black, a lattice of molten seams glowing through them everywhere, gold studs at its crossings; a standing collar of
-- obsidian blades tipped in gold fanned behind his head; over his head, floating, a crown of obsidian shards burning
-- at their points round a ring of molten fire; pauldrons of obsidian scales gold-edged; swags of gold chain across
-- his breast; claws of gold over his knuckles; molten drops falling off his hems. Both hands grip the throne.
-- (Shared pose, mask and spawn: Characters/KingGilded.)
local Base = require(script.Parent:WaitForChild("KingGilded"))

local M = table.clone(Base)
M.Kind = "KingMolten"
M.Proportions = { girth = 1.1, arm = 1.02, hunch = 0 }
local rgb = Color3.fromRGB
local OBS, BLACK, CHAR = rgb(14, 11, 12), rgb(26, 20, 20), rgb(44, 30, 26)
local GOLD, GOLD_DK, MOLTEN, SUN, CINDER = rgb(196, 146, 58), rgb(120, 84, 34), rgb(255, 104, 24), rgb(255, 200, 90), rgb(120, 20, 6)
M.Colors = { skin = OBS, torso = BLACK, legs = BLACK, arms = BLACK }

local ball = Base.ball

local function burn(p, size)
	local f = Instance.new("Fire")
	f.Size, f.Heat = size, size * 2
	f.Color, f.SecondaryColor = MOLTEN, CINDER
	f.Parent = p
end
-- molten drops off a hem: falling, burning (the Pyre priests' sword's, slower)
local function drips(p, rate)
	local pe = Instance.new("ParticleEmitter")
	pe.Color, pe.LightEmission = ColorSequence.new(SUN, MOLTEN), 1
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.05) })
	pe.Lifetime, pe.Speed, pe.Rate = NumberRange.new(0.5, 0.8), NumberRange.new(0, 0.5), rate
	pe.Acceleration, pe.SpreadAngle = Vector3.new(0, -40, 0), Vector2.new(180, 180)
	pe.Parent = p
end

function M.Look(k)
	local deco, parts, V, at, MAT = k.deco, k.parts, k.V, k.at, k.MAT
	local cw, ch, cd, hw, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.aw, k.lw, k.la, k.ua
	-- THE HEAD: a hood of black cracked through with fire, the mask before it, its eyes burning white
	parts.Head.Color = OBS
	deco("Head", "Hood", V(1.3, 1.36, 1.3), at(0, 0.02, 0.06), BLACK, MAT.Fabric)
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		deco("Head", "HoodSeam", V(0.03, 1.1, 0.03), at(math.sin(a) * 0.66, 0.05, 0.06 - math.cos(a) * 0.66) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, (i % 2 - 0.5) * 0.4), MOLTEN, MAT.Neon)
	end
	Base.Mask(k, GOLD, GOLD_DK, rgb(255, 236, 190))
	-- THE CROWN: floating over his head - a ring of molten fire, eleven obsidian shards round it leaning out, each
	-- with a burning point and a gold collar
	for i = 0, 15 do
		local a = i / 16 * math.pi * 2
		deco("Head", "FireRing", V(0.32, 0.08, 0.1), at(math.sin(a) * 0.82, 1.08, 0.06 - math.cos(a) * 0.82) * CFrame.Angles(0, -a, 0), MOLTEN, MAT.Neon)
	end
	for i = 0, 10 do
		local a = i / 11 * math.pi * 2
		local h = (i % 3 == 0) and 1.0 or (i % 3 == 1 and 0.7 or 0.55)
		local base = at(math.sin(a) * 0.8, 1.15, 0.06 - math.cos(a) * 0.8) * CFrame.Angles(0, -a, 0) * CFrame.Angles(-0.3, 0, 0)
		deco("Head", "Shard", V(0.2, h, 0.12), base * at(0, h / 2, 0) * CFrame.Angles(0, math.pi / 4, 0), OBS, MAT.Glass)
		deco("Head", "ShardCollar", V(0.26, 0.07, 0.18), base * at(0, 0.06, 0), GOLD, MAT.Metal)
		local tip = deco("Head", "ShardTip", V(0.1, 0.18, 0.08), base * at(0, h + 0.06, 0), SUN, MAT.Neon)
		if i % 3 == 0 then
			burn(tip, 1.2)
		end
	end
	-- THE STANDING COLLAR: blades of obsidian fanned behind the head, gold-tipped, on a gold-edged band
	deco("Chest", "CollarBand", V(1.3, 0.22, 1.1), at(0, ch / 2 + 0.06, 0.06), OBS, MAT.Glass)
	deco("Chest", "CollarBandEdge", V(1.34, 0.05, 1.14), at(0, ch / 2 + 0.17, 0.06), GOLD, MAT.Metal)
	for i = 0, 10 do
		local a = (i / 10 - 0.5) * math.pi * 1.25 -- (from his left ear round the back to his right)
		local h = 1.0 - math.abs(i - 5) * 0.08
		local base = at(math.sin(a) * 0.62, ch / 2 + 0.12, 0.1 + math.cos(a) * 0.52) * CFrame.Angles(0, a, 0) * CFrame.Angles(0.35, 0, 0)
		deco("Chest", "CollarBlade", V(0.22, h, 0.05), base * at(0, h / 2, 0), OBS, MAT.Glass)
		deco("Chest", "CollarBladeEdge", V(0.04, h, 0.06), base * at(0.1, h / 2, 0), GOLD_DK, MAT.Metal)
		deco("Chest", "CollarTip", V(0.13, 0.13, 0.06), base * at(0, h + 0.02, 0) * CFrame.Angles(0, 0, math.pi / 4), GOLD, MAT.Metal)
	end
	-- THE ROBE: black, the molten lattice glowing through it, gold studs at the hearts of its lozenges; char at the seams
	local fz = -cd * 0.56 - 0.02
	deco("Chest", "Robe", V(cw * 1.08, ch * 1.02, cd * 1.12), at(0, 0, 0), BLACK, MAT.Fabric)
	Base.lattice(k, "Chest", cw * 1.0, ch * 0.9, 0, -0.04, fz, 0.3, MOLTEN, MAT.Neon, 0.03)
	Base.brocade(k, "Chest", 0, -0.04, fz - 0.01, 6, 5, 0.3, 0.07, GOLD, GOLD_DK)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Chest", "CharSeam", V(0.08, ch * 1.0, cd * 1.16), at(sx * cw * 0.54, 0, 0), CHAR, MAT.Fabric)
	end
	-- the swags of chain, two, shoulder to shoulder, gold links and molten drops between
	for s = 0, 1 do
		local depth = 0.55 + s * 0.4
		for i = 0, 18 do
			local t = i / 18 * 2 - 1
			local x, y = t * cw * 0.38, ch / 2 - 0.25 - depth * (1 - t * t)
			if i % 3 == 2 then
				deco("Chest", "ChainDrop", V(0.06, 0.06, 0.06), at(x, y, fz - 0.07), MOLTEN, MAT.Neon, ball)
			else
				deco("Chest", "ChainLink", V(0.12, 0.08, 0.05), at(x, y, fz - 0.06) * CFrame.Angles(0, 0, (i % 2) * math.pi / 2), GOLD, MAT.Metal)
			end
		end
	end
	Base.sun(k, "Chest", at(0, ch / 2 - 0.25 - 0.95, fz - 0.08), 0.2, GOLD, MOLTEN)
	-- the girdle: obsidian plates on gold
	deco("Chest", "Girdle", V(cw * 1.12, 0.22, cd * 1.18), at(0, -ch / 2 + 0.12, 0), GOLD_DK, MAT.Metal)
	for i = -4, 4 do
		deco("Chest", "GirdlePlate", V(0.16, 0.18, 0.05), at(i * 0.24, -ch / 2 + 0.12, -cd * 0.61), OBS, MAT.Glass)
		deco("Chest", "GirdleSeam", V(0.03, 0.18, 0.055), at(i * 0.24 + 0.12, -ch / 2 + 0.12, -cd * 0.61), MOLTEN, MAT.Neon)
	end
	-- THE ARMS: pauldrons of obsidian scales in three rows, gold-edged; black sleeves banded with molten seams;
	-- bracers of gold; gold claws over the knuckles
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		deco(n .. "UpperArm", "Pauldron", V(aw * 1.9, aw * 1.4, aw * 1.9), at(sx * 0.08, ua * 0.36, 0), OBS, MAT.Glass, ball)
		for j = 0, 2 do
			local r, y = aw * (0.98 - j * 0.12), ua * (0.36 - j * 0.14)
			for i = 0, 9 do
				local a = i / 10 * math.pi * 2 + j * 0.3
				local c = at(sx * 0.08 + math.sin(a) * r, y, -math.cos(a) * r) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0.35, 0, 0)
				deco(n .. "UpperArm", "Scale", V(0.22, 0.24, 0.04), c * CFrame.Angles(0, 0, math.pi / 4), j % 2 == 0 and OBS or BLACK, MAT.Glass)
				if (i + j) % 2 == 0 then
					deco(n .. "UpperArm", "ScaleEdge", V(0.2, 0.03, 0.045), c * at(0, -0.12, 0), GOLD, MAT.Metal)
				end
			end
		end
		deco(n .. "UpperArm", "Sleeve", V(aw * 1.35, ua * 0.7, aw * 1.35), at(0, -ua * 0.1, 0), BLACK, MAT.Fabric)
		for _, y in ipairs({ -ua * 0.05, -ua * 0.3 }) do
			deco(n .. "UpperArm", "SleeveSeam", V(aw * 1.38, 0.04, aw * 1.38), at(0, y, 0), MOLTEN, MAT.Neon)
		end
		deco(n .. "LowerArm", "Sleeve", V(aw * 1.3, la * 0.6, aw * 1.3), at(0, 0.15, 0), BLACK, MAT.Fabric)
		deco(n .. "LowerArm", "Bracer", V(aw * 1.42, la * 0.4, aw * 1.42), at(0, -la * 0.22, 0), GOLD_DK, MAT.Metal)
		for f = 0, 3 do
			local face = CFrame.Angles(0, f * math.pi / 2, 0)
			deco(n .. "LowerArm", "BracerSun", V(0.12, 0.12, 0.03), face * at(0, -la * 0.22, -aw * 0.72) * CFrame.Angles(0, 0, math.pi / 4), GOLD, MAT.Metal)
			deco(n .. "LowerArm", "BracerSeam", V(0.03, la * 0.38, 0.03), face * at(aw * 0.45, -la * 0.22, -aw * 0.72), MOLTEN, MAT.Neon)
		end
		for i = 0, 3 do -- the claws: curved gold over each knuckle
			local x = (i - 1.5) * aw * 0.26
			deco(n .. "LowerArm", "Claw", V(0.07, 0.24, 0.07), at(x, -la / 2 - 0.3, -aw * 0.45) * CFrame.Angles(-0.5, 0, 0), GOLD, MAT.Metal)
			deco(n .. "LowerArm", "ClawRing", V(0.11, 0.06, 0.11), at(x, -la / 2 - 0.14, -aw * 0.4), GOLD_DK, MAT.Metal)
		end
	end
	-- THE LAP: black to the floor, the lattice through it, a band of char down each knee, molten drops off the hem
	Base.lapRobe(k, BLACK, GOLD, CHAR, OBS)
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		Base.lattice(k, n .. "Thigh", lw * 1.6, 1.2, -sx * 0.07, 0, -lw * 0.66, 0.3, MOLTEN, MAT.Neon, 0.03)
		Base.lattice(k, n .. "Shin", lw * 1.6, 1.0, -sx * 0.07, 0, -lw * 0.63, 0.3, MOLTEN, MAT.Neon, 0.03)
		Base.studs(k, n .. "Shin", 4, -sx * 0.07 - lw * 0.7, -sx * 0.07 + lw * 0.7, -0.53, -lw * 0.66, 0.08, GOLD)
		local h = deco(n .. "Shin", "HemGlow", V(lw * 1.8, 0.05, lw * 1.22), at(-sx * 0.07, -0.6, 0), MOLTEN, MAT.Neon)
		drips(h, 3)
		deco(n .. "Thigh", "SideSeam", V(0.11, 1.3, 0.04), at(-sx * 0.07 + sx * lw * 0.875, 0, 0.6), MOLTEN, MAT.Neon)
	end
	-- (the heat off him)
	local glow = deco("Chest", "Heat", V(0.2, 0.2, 0.2), at(0, 0, fz + 0.2), MOLTEN, MAT.Neon)
	glow.Transparency = 1
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = MOLTEN, 14, 1.3
	l.Parent = glow
end

return M
