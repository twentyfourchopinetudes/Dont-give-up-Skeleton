--!nonstrict
-- ARMOR, as it looks on a player's character (server). What each piece is, which slots it
-- takes and what it gives: Config.Armor. Built here: the long cloak (Mabel's Dark Cloak,
-- and the bottom half of Giles's Motley - Characters/Taylor builds its hat and coat), the
-- Dark Hood, and the dark aura they give off. (The Castellan's Helm: init.server, wearHelmet.)
-- Each piece goes into its own model in the character, named for it, so it comes off whole.
local CollectionService = game:GetService("CollectionService")
local M = {}

local T = 0.06 -- cloth thickness

-- decorations welded onto a character's parts, all into one new model named name
function M.kit(char, name)
	local folder = Instance.new("Model")
	folder.Name = name
	folder.Parent = char
	local function deco(onPart, partName, size, offset, color, mat, shape)
		local base = char:FindFirstChild(onPart)
		if not base then
			return
		end
		local d = Instance.new("Part")
		d.Name = partName
		if shape then
			d.Shape = shape
		end
		d.Size, d.Color, d.Material = size, color, mat or Enum.Material.SmoothPlastic
		d.CanCollide, d.CanQuery, d.CanTouch, d.Massless = false, false, false, true
		d.CFrame = base.CFrame * offset
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = base, d
		w.Parent = d
		d.Parent = folder
		return d
	end
	local function size(n)
		local p = char:FindFirstChild(n)
		return p and p.Size or Vector3.one
	end
	return folder, deco, size
end

function M.unwear(char, name)
	local folder = char:FindFirstChild(name)
	if folder then
		folder:Destroy()
	end
	for _, d in ipairs(char:GetDescendants()) do -- whatever it hid (a "<name>T" attribute)
		local t = d:GetAttribute(name .. "T")
		if t then
			d.Transparency = t
			d:SetAttribute(name .. "T", nil)
		end
	end
end

-- TATTERS: cloth is never cut straight here. One strip of rag hangs from top (a CFrame
-- on its part, -Y = down) in two or three pieces, each kinked off the last at a slightly
-- different angle, and ends in a ragged tip; rng keeps a piece of armor the same every time.
-- rough (default 1) scales the kinks, fraying and scraps down for cloth that is only worn.
function M.tatter(deco, rng, onPart, top, w, l, color, hem, rough)
	rough = rough or 1
	local at, left = top, l
	local pieces = rng:NextInteger(2, 3)
	for i = 1, pieces do
		local len = i == pieces and left or left * rng:NextNumber(0.4, 0.6)
		left -= len
		-- each piece hangs from where the last one ended, swung a little further off true
		at = at * CFrame.Angles(rng:NextNumber(-0.09, 0.09) * rough, rng:NextNumber(-0.18, 0.18) * rough, rng:NextNumber(-0.08, 0.08) * rough)
		local pw = w * (1 - (i - 1) * rng:NextNumber(0.08, 0.2) * rough) -- (narrowing as it frays)
		local col = color:Lerp(hem, (i - 1) / pieces * rng:NextNumber(0.4, 0.9))
		deco(onPart, "Tatter", Vector3.new(pw, len + 0.03, T), at * CFrame.new(0, -len / 2, 0), col, Enum.Material.Fabric)
		at = at * CFrame.new(rng:NextNumber(-0.03, 0.03) * rough, -len, 0)
	end
	-- the frayed end: a narrow scrap or two hanging off one side or the other
	for _ = 1, rough < 1 and rng:NextInteger(0, 1) or rng:NextInteger(1, 2) do
		local fl = rng:NextNumber(0.12, 0.32)
		deco(onPart, "Fray", Vector3.new(w * rng:NextNumber(0.2, 0.4), fl, T), at * CFrame.new(w * rng:NextNumber(-0.3, 0.3), -fl / 2 + 0.02, 0) * CFrame.Angles(0, 0, rng:NextNumber(-0.35, 0.35)), hem, Enum.Material.Fabric)
	end
end

-- a cloak to the feet in tatters, open down the front. The rags before and behind each leg
-- hang off that thigh (so they swing with it and the leg never passes through them); the
-- sides and the middle of the back hang off the hips, flared out clear of the legs. A
-- panel is a row of overlapping tatters of uneven length, a rag torn short here and there.
function M.cloak(deco, size, coat, hem, seed)
	local rng = Random.new(seed or 7)
	local hips, thigh, shin, foot = size("Hips"), size("RThigh"), size("RShin"), size("RFoot")
	local function panel(onPart, top, rot, w, l, color)
		local n = math.max(3, math.floor(w / 0.2 + 0.5))
		for i = 1, n do
			local x = -w / 2 + (i - 0.5) * w / n
			local len = l * (rng:NextNumber() < 0.2 and rng:NextNumber(0.55, 0.75) or rng:NextNumber(0.85, 1.05))
			local col = color:Lerp(hem, rng:NextNumber(0, 0.35))
			local stripTop = top * rot * CFrame.new(x, 0, (i % 2) * 0.012) -- (alternate rags overlap)
			M.tatter(deco, rng, onPart, stripTop, w / n * 1.45, len, col, hem)
		end
	end
	local legL = thigh.Y + shin.Y + foot.Y * 0.4 -- thigh top to just above the floor
	local hipL = hips.Y * 0.8 + legL -- (the hips' panels start up under the coat)
	for _, side in ipairs({ "R", "L" }) do
		local tw = thigh.X
		local gap = thigh.Z / 2 + 0.14 -- clear of the leg's front and back
		panel(side .. "Thigh", CFrame.new(0, thigh.Y / 2 + 0.1, -gap), CFrame.Angles(0.08, 0, 0), tw * 1.9, legL + 0.1, coat)
		panel(side .. "Thigh", CFrame.new(0, thigh.Y / 2 + 0.1, gap), CFrame.Angles(-0.08, 0, 0), tw * 1.9, legL + 0.1, coat:Lerp(hem, 0.2))
		-- the side: turned to face out, its foot flared away from the leg
		local sx = side == "R" and 1 or -1
		panel("Hips", CFrame.new(sx * (hips.X / 2 + 0.12), hips.Y * 0.3, 0), CFrame.Angles(0, 0, sx * 0.14) * CFrame.Angles(0, math.pi / 2, 0), hips.Z * 1.6, hipL, coat)
	end
	panel("Hips", CFrame.new(0, hips.Y * 0.3, hips.Z / 2 + 0.2), CFrame.Angles(-0.16, 0, 0), hips.X * 0.8, hipL, coat:Lerp(hem, 0.1)) -- the middle of the back
end

-- Mabel's pair: a charcoal cloth with a bruise of violet in it (pure black just reads as a
-- hole), worn darker in places, hemmed in the same dusky violet so they go together
local CLOTH, SHADE, TRIM = Color3.fromRGB(40, 34, 48), Color3.fromRGB(22, 18, 28), Color3.fromRGB(78, 52, 104)

-- THE DARK CLOAK: no hood. The body wrapped close in it, a mantle of long overlapping
-- strips round the shoulders (cut like Giles's, but longer, falling past the waist), a
-- silver clasp at the throat with a violet stone, and the long cloak below to the feet
function M.wearDarkCloak(char)
	if char:FindFirstChild("DarkCloak") then
		return
	end
	local _, deco, size = M.kit(char, "DarkCloak")
	local chest = size("Chest")
	local cw, ch, cd = chest.X, chest.Y, chest.Z
	deco("Chest", "CloakBody", Vector3.new(cw * 1.12, ch * 1.0, cd * 1.18), CFrame.new(0, -0.02, 0), CLOTH, Enum.Material.Fabric)
	-- the mantle: a ring of rags from the shoulders, each torn to its own length
	local rng = Random.new(31)
	for i = 0, 17 do
		local a = i / 18 * math.pi * 2
		local l = ch * rng:NextNumber(0.85, 1.35)
		local x, z = math.sin(a) * cw * 0.7, -math.cos(a) * cd * 0.84
		local top = CFrame.new(x, ch / 2 + 0.1, z) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0.12, 0, 0)
		M.tatter(deco, rng, "Chest", top, cw * 0.36, l, CLOTH:Lerp(SHADE, rng:NextNumber(0, 0.6)), TRIM)
	end
	deco("Chest", "Collar", Vector3.new(cw * 0.8, 0.2, cd * 1.2), CFrame.new(0, ch / 2 + 0.08, 0.03), SHADE, Enum.Material.Fabric)
	deco("Chest", "Clasp", Vector3.new(0.34, 0.34, 0.1), CFrame.new(0, ch / 2 - 0.14, -cd * 0.64) * CFrame.Angles(0, 0, math.pi / 4), Color3.fromRGB(160, 160, 172), Enum.Material.Metal)
	deco("Chest", "ClaspStone", Vector3.new(0.16, 0.16, 0.16), CFrame.new(0, ch / 2 - 0.14, -cd * 0.68), Color3.fromRGB(140, 80, 210), Enum.Material.Neon, Enum.PartType.Ball)
	-- sleeves: loose to the wrist, torn at the elbow and cuff, rags hanging off the forearm
	for _, n in ipairs({ "R", "L" }) do
		local ua, la = size(n .. "UpperArm"), size(n .. "LowerArm")
		deco(n .. "UpperArm", "Sleeve", Vector3.new(ua.X * 1.45, ua.Y * 1.02, ua.Z * 1.45), CFrame.new(0, 0.02, 0), CLOTH, Enum.Material.Fabric)
		deco(n .. "LowerArm", "Sleeve", Vector3.new(la.X * 1.5, la.Y * 0.75, la.Z * 1.5), CFrame.new(0, la.Y * 0.12, 0), CLOTH:Lerp(SHADE, 0.3), Enum.Material.Fabric)
		for k = 0, 4 do -- the cuff's rags, round the forearm
			local a = k / 5 * math.pi * 2
			local r = la.X * 0.78
			local top = CFrame.new(math.sin(a) * r, -la.Y * 0.22, -math.cos(a) * r) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0.1, 0, 0)
			M.tatter(deco, rng, n .. "LowerArm", top, la.X * 0.7, rng:NextNumber(0.3, 0.6), CLOTH:Lerp(SHADE, rng:NextNumber(0, 0.5)), TRIM)
		end
		for k = 0, 2 do -- and a few at the elbow, over the forearm's top
			local a = (k / 3 + 0.15) * math.pi * 2
			local r = ua.X * 0.74
			local top = CFrame.new(math.sin(a) * r, -ua.Y * 0.4, -math.cos(a) * r) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0.08, 0, 0)
			M.tatter(deco, rng, n .. "UpperArm", top, ua.X * 0.6, rng:NextNumber(0.25, 0.45), CLOTH:Lerp(SHADE, rng:NextNumber(0, 0.5)), TRIM)
		end
	end
	M.cloak(deco, size, CLOTH, TRIM, 13)
end

-- a jester's two points rising off a crown (a point on onPart, in its space), spread
-- apart each side, each curling over and flopping down away from the other, a little
-- silver bell on each tip; one in colA, one in colB. A point is a chain of tapering cloth
-- tubes, each turned further over than the last, balls at the joints so it bends smooth.
-- s = the wearer's scale. (The Dark Hood's, and Mabel's own: Characters/Mabel.)
function M.jesterPoints(deco, onPart, crown, spread, colA, colB, s)
	s = s or 1
	for _, sx in ipairs({ -1, 1 }) do
		local pos = crown + Vector3.new(sx * spread, 0, 0)
		local col = sx < 0 and colA or colB
		local N, L = 7, 0.34 * s
		for i = 1, N do
			local tilt = math.rad(12 + (i - 1) * 24) -- from near upright, over, to hanging down
			local dir = Vector3.new(sx * math.sin(tilt), math.cos(tilt), 0)
			local d = (0.72 * (1 - (i - 1) / N) + 0.12) * s
			local mid = pos + dir * L / 2
			deco(onPart, "JesterPoint", Vector3.new(L * 1.15, d, d), CFrame.lookAt(mid, mid + dir) * CFrame.Angles(0, math.pi / 2, 0), col, Enum.Material.Fabric, Enum.PartType.Cylinder)
			pos += dir * L
			deco(onPart, "JesterPoint", Vector3.one * d * 0.96, CFrame.new(pos), col, Enum.Material.Fabric, Enum.PartType.Ball)
		end
		deco(onPart, "JesterBell", Vector3.one * 0.22 * s, CFrame.new(pos + Vector3.new(0, -0.12 * s, 0)), Color3.fromRGB(170, 170, 182), Enum.Material.Metal, Enum.PartType.Ball)
	end
end

-- THE DARK HOOD: deep and round, the face lost in its shadow, rags falling to the
-- shoulders behind. The shell is one cloth sphere (the square skull hidden inside it);
-- the face is a dark round opening set into its front, rimmed in the violet trim.
function M.wearDarkHood(char)
	if char:FindFirstChild("DarkHood") then
		return
	end
	local _, deco, size = M.kit(char, "DarkHood")
	local h = size("Head")
	local R = (h.Magnitude / 2 + 0.08) * 0.9 -- (a touch inside the skull's corners: it's hidden below)
	local head = char:FindFirstChild("Head")
	for _, d in ipairs(char:GetDescendants()) do -- the skull and what's welded to it, so no corner pokes out
		local w = d:IsA("BasePart") and d:FindFirstChildOfClass("WeldConstraint")
		if head and (d == head or (w and w.Part0 == head)) and not d:IsDescendantOf(char.DarkHood) then
			d:SetAttribute("DarkHoodT", d.Transparency) -- (unwear puts it back)
			d.Transparency = 1
		end
	end
	local c = Vector3.new(0, 0.06, 0.1) -- set back a little, so the face sits deep in it
	deco("Head", "Hood", Vector3.one * R * 2, CFrame.new(c), CLOTH, Enum.Material.Fabric, Enum.PartType.Ball)
	-- the opening: a dark disc flush with the shell's front, where its curve is this wide
	local r = R * 0.68
	local fz = c.Z - math.sqrt(R * R - r * r) - 0.01
	deco("Head", "HoodShadow", Vector3.new(0.04, r * 2, r * 2), CFrame.new(c.X, c.Y - 0.05, fz) * CFrame.Angles(0, math.pi / 2, 0), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	for i = 0, 17 do -- its rim, a soft roll of violet round the opening
		local a = i / 18 * math.pi * 2
		deco("Head", "HoodTrim", Vector3.one * 0.13, CFrame.new(c.X + math.cos(a) * r, c.Y - 0.05 + math.sin(a) * r, fz + 0.02), TRIM, Enum.Material.Fabric, Enum.PartType.Ball)
	end
	-- and behind, rags hanging from the hood down over the shoulders
	local rng = Random.new(47)
	for i = -2, 2 do
		local a = i * 0.32
		local top = CFrame.new(c + Vector3.new(math.sin(a) * R * 0.8, -R * 0.55, math.cos(a) * R * 0.8)) * CFrame.Angles(0, a, 0) * CFrame.Angles(-0.25, 0, 0)
		M.tatter(deco, rng, "Head", top, R * 0.5, rng:NextNumber(0.55, 0.85), CLOTH:Lerp(SHADE, rng:NextNumber(0, 0.5)), TRIM)
	end
	M.jesterPoints(deco, "Head", c + Vector3.new(0, R * 0.82, 0), R * 0.42, CLOTH, CLOTH:Lerp(TRIM, 0.55))
end

-- grow (or shrink back) the whole rig to g times its normal size: every part, joint and the
-- Humanoid's hip height, and the numbers the Puppeteer and the rig guard read. Returns whether
-- anything changed. (Armor that makes you bigger: Config.Armor Grow.)
function M.grow(char, g)
	local cur = char:GetAttribute("Grow") or 1
	if math.abs(cur - g) < 1e-3 then
		return false
	end
	local ratio = g / cur
	char:ScaleTo(char:GetScale() * ratio)
	char:SetAttribute("Grow", g)
	for _, n in ipairs({ "RigScale", "HipHeight", "StandHeight" }) do
		local v = char:GetAttribute(n)
		if v then
			char:SetAttribute(n, v * ratio)
		end
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and char:GetAttribute("HipHeight") then
		hum.HipHeight = char:GetAttribute("HipHeight")
	end
	return true
end

-- CAELEN'S SILVER PLATE (the Silver Knight's, Config.Armor.CaelenArmor): body armor, so it goes
-- with any helm. Bulky fluted silver edged in gold: a full cuirass with a gilt sun and a gorget,
-- tassets, pauldrons, sleeves, elbow cops, vambraces, gauntlets, cuisses, knee cops, greaves
-- and sabatons. The skeleton under it is hidden (unwear brings it back).
local SILVER, SILVER_DK, GOLD = Color3.fromRGB(190, 194, 202), Color3.fromRGB(138, 142, 152), Color3.fromRGB(176, 140, 66)
function M.wearCaelen(char)
	if char:FindFirstChild("CaelenArmor") then
		return
	end
	local folder, deco, size = M.kit(char, "CaelenArmor")
	-- the bones (and their rags and cloak) under it: every part of the body, not the skull or what's on it
	local head = char:FindFirstChild("Head")
	for _, d in ipairs(char:GetChildren()) do
		local w = d:IsA("BasePart") and d:FindFirstChildOfClass("WeldConstraint")
		if d:IsA("BasePart") and d ~= head and d.Name ~= "HumanoidRootPart" and not (w and w.Part0 == head) then
			d:SetAttribute("CaelenArmorT", d.Transparency)
			d.Transparency = 1
		end
	end
	local METAL, BALL = Enum.Material.Metal, Enum.PartType.Ball
	local chest, hips = size("Chest"), size("Hips")
	local function V(x, y, z)
		return Vector3.new(x, y, z)
	end
	local at = CFrame.new
	-- the cuirass: a shell, a raised fluted breastplate with a gilt sun, a backplate, a gorget
	deco("Chest", "Shell", V(chest.X * 1.14, chest.Y * 1.04, chest.Z * 1.2), at(0, 0, 0), SILVER_DK, METAL)
	deco("Chest", "Breastplate", V(chest.X * 1.08, chest.Y * 0.88, 0.34), at(0, 0.06, -chest.Z * 0.6 - 0.1), SILVER, METAL)
	for i = -2, 2 do
		deco("Chest", "Flute", V(0.09, chest.Y * 0.74, 0.08), at(i * chest.X * 0.19, 0.04, -chest.Z * 0.6 - 0.3), SILVER_DK, METAL)
	end
	deco("Chest", "Sun", V(0.56, 0.56, 0.08), at(0, chest.Y * 0.2, -chest.Z * 0.6 - 0.34), GOLD, METAL)
	deco("Chest", "GoldRim", V(chest.X * 1.1, 0.1, 0.38), at(0, -chest.Y * 0.38, -chest.Z * 0.6 - 0.1), GOLD, METAL)
	deco("Chest", "Backplate", V(chest.X * 1.1, chest.Y * 0.95, 0.3), at(0, 0, chest.Z * 0.6 + 0.08), SILVER, METAL)
	deco("Chest", "Gorget", V(chest.X * 0.72, 0.5, chest.Z * 1.1), at(0, chest.Y * 0.52, 0), SILVER, METAL)
	deco("Chest", "GorgetRim", V(chest.X * 0.78, 0.08, chest.Z * 1.16), at(0, chest.Y * 0.74, 0), GOLD, METAL)
	-- the waist: a skirt of plate, a gold belt, tassets hanging over the thighs
	deco("Hips", "Skirt", V(hips.X * 1.2, hips.Y * 1.1, hips.Z * 1.3), at(0, 0, 0), SILVER_DK, METAL)
	deco("Hips", "Belt", V(hips.X * 1.24, 0.16, hips.Z * 1.34), at(0, hips.Y * 0.38, 0), GOLD, METAL)
	deco("Hips", "BeltBoss", V(0.34, 0.3, 0.1), at(0, hips.Y * 0.38, -hips.Z * 0.67 - 0.02), GOLD, METAL)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Hips", "Tasset", V(hips.X * 0.5, hips.Y * 1.5, 0.16), at(sx * hips.X * 0.27, -hips.Y * 0.6, -hips.Z * 0.65) * CFrame.Angles(-0.1, 0, 0), SILVER, METAL)
		deco("Hips", "TassetSide", V(0.16, hips.Y * 1.3, hips.Z * 0.9), at(sx * (hips.X * 0.62 + 0.04), -hips.Y * 0.4, 0), SILVER, METAL)
	end
	for _, side in ipairs({ "R", "L" }) do
		local sx = side == "R" and 1 or -1
		local ua, la, hand = size(side .. "UpperArm"), size(side .. "LowerArm"), size(side .. "Hand")
		local th, sh, foot = size(side .. "Thigh"), size(side .. "Shin"), size(side .. "Foot")
		-- the arm: a big stacked pauldron, a sleeve, an elbow cop, a vambrace with a fin, a gauntlet
		local U, L = side .. "UpperArm", side .. "LowerArm"
		deco(U, "Pauldron", V(ua.X * 2.1, 0.62, ua.Z * 2.0), at(sx * 0.1, ua.Y / 2 - 0.08, 0) * CFrame.Angles(0, 0, -sx * 0.3), SILVER, METAL)
		deco(U, "PauldronLame", V(ua.X * 1.9, 0.22, ua.Z * 1.8), at(sx * 0.08, ua.Y / 2 - 0.5, 0) * CFrame.Angles(0, 0, -sx * 0.2), SILVER_DK, METAL)
		deco(U, "PauldronTrim", V(ua.X * 2.15, 0.08, ua.Z * 2.05), at(sx * 0.1, ua.Y / 2 - 0.38, 0) * CFrame.Angles(0, 0, -sx * 0.3), GOLD, METAL)
		deco(U, "Sleeve", V(ua.X * 1.3, ua.Y * 0.8, ua.Z * 1.3), at(0, -ua.Y * 0.08, 0), SILVER_DK, METAL)
		deco(L, "ElbowCop", V(la.X * 1.7, la.X * 1.7, la.X * 1.7), at(0, la.Y / 2, 0), SILVER, METAL, BALL)
		deco(L, "Vambrace", V(la.X * 1.4, la.Y * 0.92, la.Z * 1.4), at(0, -la.Y * 0.04, 0), SILVER, METAL)
		deco(L, "VambraceFin", V(0.08, la.Y * 0.7, la.Z * 1.7), at(sx * la.X * 0.5, 0, 0), GOLD, METAL)
		deco(side .. "Hand", "Gauntlet", V(hand.X * 1.5, hand.Y * 1.25, hand.Z * 1.5), at(0, 0, 0), SILVER_DK, METAL)
		deco(side .. "Hand", "Knuckles", V(hand.X * 1.55, 0.12, hand.Z * 1.2), at(0, -hand.Y * 0.4, -hand.Z * 0.2), GOLD, METAL)
		-- the leg: a cuisse, a knee cop, a greave with a ridge, a sabaton
		local T, S2, F = side .. "Thigh", side .. "Shin", side .. "Foot"
		deco(T, "Cuisse", V(th.X * 1.4, th.Y * 0.98, th.Z * 1.4), at(0, 0, 0), SILVER, METAL)
		deco(T, "CuisseTrim", V(th.X * 1.45, 0.08, th.Z * 1.45), at(0, th.Y * 0.4, 0), GOLD, METAL)
		deco(S2, "Greave", V(sh.X * 1.4, sh.Y * 1.0, sh.Z * 1.4), at(0, 0, 0), SILVER_DK, METAL)
		deco(S2, "GreaveRidge", V(0.1, sh.Y * 0.85, 0.1), at(0, 0, -sh.Z * 0.7), GOLD, METAL)
		deco(F, "Sabaton", V(foot.X * 1.4, foot.Y * 1.3, foot.Z * 1.25), at(0, 0, -foot.Z * 0.04), SILVER, METAL)
	end
	-- the capes, swinging cloth like the Silver Knight's (Carrier.cloth hangs a strip off each
	-- tagged anchor): a main cape to the heels, a heavier layer over it to thicken it, and a
	-- half-width one off the back of each shoulder, each with its own physics
	local th, sh, foot = size("RThigh"), size("RShin"), size("RFoot")
	local drop = chest.Y / 2 + hips.Y + th.Y + sh.Y + foot.Y * 0.4 -- the shoulders to just above the floor
	local CAPE = Color3.fromRGB(112, 22, 22)
	local function cape(name, segs, len, width, color, at, phys, onPart)
		local a = deco(onPart or "Chest", name, V(0.2, 0.2, 0.2), at * CFrame.Angles(0, math.pi, 0), color, Enum.Material.SmoothPlastic)
		a.Transparency = 1
		a:SetAttribute("Segs", segs)
		a:SetAttribute("Len", len / segs)
		a:SetAttribute("Width", width)
		a:SetAttribute("Color", color)
		for k, v in pairs(phys or {}) do
			a:SetAttribute(k, v)
		end
		CollectionService:AddTag(a, "ClothChain")
	end
	cape("CapeAnchor", 6, drop * 0.97, chest.X * 1.15, CAPE, at(0, chest.Y / 2 - 0.15, chest.Z / 2 + 0.3))
	cape("CapeAnchor2", 6, drop, chest.X * 1.2, CAPE:Lerp(Color3.new(), 0.25), at(0, chest.Y / 2 - 0.2, chest.Z / 2 + 0.36), { Drag = 0.92, Gravity = 1.3, Out = 0.14 })
	cape("CapeAnchor3", 6, drop * 1.03, chest.X * 1.1, CAPE:Lerp(Color3.fromRGB(255, 255, 255), 0.12), at(0, chest.Y / 2 - 0.1, chest.Z / 2 + 0.24), { Drag = 0.96, Gravity = 0.9, Out = 0.06 })
	for _, sx in ipairs({ -1, 1 }) do
		-- narrower ones between the shoulders and the middle, and short ones off the hips
		cape("InnerCapeAnchor", 6, drop * 0.85, chest.X * 0.55, CAPE:Lerp(Color3.new(), 0.1), at(sx * chest.X * 0.28, chest.Y / 2 - 0.12, chest.Z / 2 + 0.5), { Drag = 0.94, Gravity = 1.1, Out = 0.2 })
		cape("HipCapeAnchor", 4, drop * 0.4, hips.X * 0.7, CAPE:Lerp(Color3.new(), 0.2), at(sx * hips.X * 0.5, hips.Y * 0.3, hips.Z / 2 + 0.2), { Drag = 0.97, Gravity = 0.85, Out = 0.08 }, "Hips")
	end
	for _, sx in ipairs({ -1, 1 }) do
		cape("ShoulderCapeAnchor", 5, drop * 0.55, chest.X * 0.575, CAPE:Lerp(Color3.new(), 0.15), at(sx * (chest.X / 2 + 0.05), chest.Y / 2 - 0.1, chest.Z / 2 + 0.42), { Drag = 0.975, Gravity = 0.8, Out = 0.1 })
	end
end

-- the dark they give off: 0 none, 1 a faint aura about you, 2 (the pair) a thick one. Its
-- look comes from Config.DarkAuraAsset, loaded once: a VFX model's own emitters (at 80%
-- for 1), or an image drawn as the haze. Failing that (or 0), a bruised violet haze -
-- never pure black, which can't be seen in a dark prison. Faint lit wisps go up through it.
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"))
local auraKit -- { emitters = { ParticleEmitter }, texture = string? }, once loaded
local function loadAura()
	if auraKit then
		return auraKit
	end
	auraKit = { emitters = {} }
	local id = Config.DarkAuraAsset or 0
	if id == 0 and not game:GetService("ReplicatedStorage"):FindFirstChild("DarkAuraVFX") then
		return auraKit
	end
	-- (Roblox only lets a game load models its owner owns: one put in the place by hand, as
	-- ReplicatedStorage.DarkAuraVFX, is used instead)
	local placed = game:GetService("ReplicatedStorage"):FindFirstChild("DarkAuraVFX")
	local ok, model = pcall(function()
		return placed or game:GetService("InsertService"):LoadAsset(id)
	end)
	if ok and model then
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("ParticleEmitter") then
				table.insert(auraKit.emitters, d)
			elseif (d:IsA("Decal") or d:IsA("Texture")) and not auraKit.texture then
				auraKit.texture = d.Texture -- (a decal's own image)
			end
		end
	else
		auraKit.texture = "rbxassetid://" .. id -- (not loadable as a model: take it as an image)
		warn("[DGUS] DarkAuraAsset " .. id .. " didn't load as a model (" .. tostring(model) .. "); using it as an image")
	end
	return auraKit
end

function M.aura(char, strength)
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	for _, d in ipairs(root:GetChildren()) do
		if d:GetAttribute("DarkAura") then
			d:Destroy()
		end
	end
	if strength <= 0 then
		return
	end
	local thick = strength >= 2
	local kit = loadAura()
	-- it all rises off an invisible volume round you, bigger than you are (a root part is a
	-- small box at your middle), and every particle is scaled up with it: Config.DarkAuraScale
	local k = Config.DarkAuraScale or 1
	local volume = Instance.new("Part")
	volume.Name = "DarkAuraVolume"
	volume.Size = Vector3.new(2.6, 4.6, 2.6) * k
	volume.Transparency = 1
	volume.CanCollide, volume.CanQuery, volume.CanTouch, volume.Massless = false, false, false, true
	volume.CFrame = root.CFrame
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1 = root, volume
	weld.Parent = volume
	volume:SetAttribute("DarkAura", true)
	volume.Parent = root
	local function scaled(seq)
		local keys = {}
		for _, p in ipairs(seq.Keypoints) do
			table.insert(keys, NumberSequenceKeypoint.new(p.Time, p.Value * k, p.Envelope * k))
		end
		return NumberSequence.new(keys)
	end
	local function add(pe)
		pe.Size = scaled(pe.Size)
		pe.Speed = NumberRange.new(pe.Speed.Min * k, pe.Speed.Max * k)
		pe.Rate *= k -- (more of them to fill the bigger space)
		pe.Parent = volume
	end
	if #kit.emitters > 0 then
		for _, src in ipairs(kit.emitters) do
			local pe = src:Clone()
			pe.Enabled = true
			pe.Rate = math.max(src.Rate, 6) * (thick and 1 or 0.8)
			add(pe)
		end
	else
		local haze = Instance.new("ParticleEmitter")
		haze.Name = "DarkAura"
		haze.Texture = kit.texture or "rbxasset://textures/particles/smoke_main.dds"
		haze.Color = ColorSequence.new(Color3.fromRGB(70, 44, 96), Color3.fromRGB(24, 14, 34))
		haze.LightInfluence = 0
		haze.LightEmission = 0
		haze.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, thick and 2.4 or 1.6), NumberSequenceKeypoint.new(1, thick and 4.5 or 3) })
		haze.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, thick and 0.35 or 0.6), NumberSequenceKeypoint.new(1, 1) })
		haze.Lifetime = NumberRange.new(1.4, 2.2)
		haze.Rate = thick and 26 or 10
		haze.Speed = NumberRange.new(0.3, 1)
		haze.SpreadAngle = Vector2.new(180, 180)
		haze.Acceleration = Vector3.new(0, 0.9, 0)
		haze.RotSpeed = NumberRange.new(-40, 40)
		haze.Rotation = NumberRange.new(0, 360)
		haze.Shape = Enum.ParticleEmitterShape.Box
		add(haze)
	end
	local wisps = Instance.new("ParticleEmitter")
	wisps.Name = "DarkWisps"
	wisps.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	wisps.Color = ColorSequence.new(Color3.fromRGB(170, 120, 230))
	wisps.LightInfluence = 0
	wisps.LightEmission = 0.6
	wisps.Size = NumberSequence.new(thick and 0.35 or 0.25, 0)
	wisps.Transparency = NumberSequence.new(0.3, 1)
	wisps.Lifetime = NumberRange.new(1, 1.8)
	wisps.Rate = thick and 14 or 4
	wisps.Speed = NumberRange.new(0.5, 1.5)
	wisps.SpreadAngle = Vector2.new(180, 180)
	wisps.Acceleration = Vector3.new(0, 2, 0)
	wisps.Shape = Enum.ParticleEmitterShape.Box
	add(wisps)
end

-- THE ARMOR OF A LION HUNTER (Config.Armor.PotbellyArmor; the Underfire's blazing chest): Caelen's bulk, forged by someone
-- with more iron than taste. Thick dull grey, and on its BACK a great round barrel of iron bulging out behind (rivets
-- round it, a knob in the middle), as if it carried its own hump; a belt cinched too tight, pot-lid pauldrons with a knob
-- on top, round mitten gauntlets, huge ball knee cops, bucket greaves and stubby round toes. The skeleton under it is
-- hidden, as under Caelen's (unwear brings it back).
local GREY, GREY_DK, RIVET = Color3.fromRGB(126, 126, 124), Color3.fromRGB(86, 86, 88), Color3.fromRGB(56, 54, 52)
function M.wearPotbelly(char)
	if char:FindFirstChild("PotbellyArmor") then
		return
	end
	local _, deco, size = M.kit(char, "PotbellyArmor")
	local head = char:FindFirstChild("Head")
	for _, d in ipairs(char:GetChildren()) do
		local w = d:IsA("BasePart") and d:FindFirstChildOfClass("WeldConstraint")
		if d:IsA("BasePart") and d ~= head and d.Name ~= "HumanoidRootPart" and not (w and w.Part0 == head) then
			d:SetAttribute("PotbellyArmorT", d.Transparency)
			d.Transparency = 1
		end
	end
	local METAL, BALL, V, at = Enum.Material.Metal, Enum.PartType.Ball, Vector3.new, CFrame.new
	local chest, hips = size("Chest"), size("Hips")
	-- the hump: a ball of iron bigger than the chest, pushed out behind (+z), a ring of rivets round it and a boss in its
	-- middle; a squarer shell, a flat breastplate in front, a short thick stovepipe of a gorget
	local bd = chest.X * 1.55
	deco("Chest", "Hump", V(bd, bd, bd), at(0, chest.Y * 0.05, chest.Z * 0.45), GREY, METAL, BALL)
	deco("Chest", "Shell", V(chest.X * 1.3, chest.Y * 1.12, chest.Z * 1.5), at(0, 0.05, -0.05), GREY_DK, METAL)
	deco("Chest", "Breastplate", V(chest.X * 1.25, chest.Y * 1.05, 0.4), at(0, 0, -chest.Z * 0.75 - 0.1), GREY, METAL)
	for i = 0, 11 do
		local a = (i / 12 - 0.5) * math.pi * 1.4 -- (round the back of the hump, side to side)
		deco("Chest", "Rivet", V(0.16, 0.16, 0.16), at(math.sin(a) * bd * 0.5, chest.Y * 0.05, chest.Z * 0.45 + math.cos(a) * bd * 0.5), RIVET, METAL, BALL)
	end
	deco("Chest", "Boss", V(0.34, 0.34, 0.34), at(0, chest.Y * 0.25, chest.Z * 0.45 + bd * 0.48), RIVET, METAL, BALL)
	deco("Chest", "Gorget", V(chest.X * 0.7, 0.7, chest.Z * 1.2), at(0, chest.Y * 0.58, 0), GREY_DK, METAL)
	deco("Chest", "GorgetLip", V(chest.X * 0.8, 0.14, chest.Z * 1.3), at(0, chest.Y * 0.58 + 0.38, 0), GREY, METAL)
	-- the waist: a heavy skirt, and a belt far too small for the belly over it, a little square buckle
	deco("Hips", "Skirt", V(hips.X * 1.35, hips.Y * 1.15, hips.Z * 1.5), at(0, -0.05, 0), GREY_DK, METAL)
	deco("Hips", "Belt", V(hips.X * 1.4, 0.2, hips.Z * 1.55), at(0, hips.Y * 0.42, 0), RIVET, Enum.Material.Leather)
	deco("Hips", "Buckle", V(0.24, 0.22, 0.08), at(0, hips.Y * 0.42, -hips.Z * 0.78 - 0.02), GREY, METAL)
	for _, side in ipairs({ "R", "L" }) do
		local sx = side == "R" and 1 or -1
		local ua, la, hand = size(side .. "UpperArm"), size(side .. "LowerArm"), size(side .. "Hand")
		local th, sh, foot = size(side .. "Thigh"), size(side .. "Shin"), size(side .. "Foot")
		local U, L = side .. "UpperArm", side .. "LowerArm"
		-- pot lids for pauldrons, each with a knob on top; a thick sleeve, a ball at the elbow, a round mitten
		local pd = ua.X * 2.7
		deco(U, "Pauldron", V(pd, pd, pd), at(sx * 0.15, ua.Y / 2 - pd * 0.15, 0), GREY, METAL, BALL)
		deco(U, "PauldronKnob", V(0.3, 0.3, 0.3), at(sx * 0.15, ua.Y / 2 + pd * 0.36, 0), RIVET, METAL, BALL)
		deco(U, "Sleeve", V(ua.X * 1.6, ua.Y * 0.8, ua.Z * 1.6), at(0, -ua.Y * 0.1, 0), GREY_DK, METAL)
		deco(L, "ElbowCop", V(la.X * 2, la.X * 2, la.X * 2), at(0, la.Y / 2, 0), GREY, METAL, BALL)
		deco(L, "Vambrace", V(la.X * 1.65, la.Y * 0.9, la.Z * 1.65), at(0, -la.Y * 0.04, 0), GREY_DK, METAL)
		local md = hand.X * 2
		deco(side .. "Hand", "Mitten", V(md, md, md), at(0, -hand.Y * 0.1, 0), GREY, METAL, BALL)
		-- the leg: a thick cuisse, a great ball of a knee, a bucket greave with a rim, a stubby round toe
		local T, S2, F = side .. "Thigh", side .. "Shin", side .. "Foot"
		deco(T, "Cuisse", V(th.X * 1.65, th.Y * 0.98, th.Z * 1.65), at(0, 0, 0), GREY, METAL)
		local kd = th.X * 1.9
		deco(S2, "KneeCop", V(kd, kd, kd), at(0, sh.Y / 2, -sh.Z * 0.2), GREY, METAL, BALL)
		deco(S2, "Greave", V(sh.X * 1.7, sh.Y * 0.95, sh.Z * 1.7), at(0, -sh.Y * 0.05, 0), GREY_DK, METAL)
		deco(S2, "GreaveRim", V(sh.X * 1.85, 0.14, sh.Z * 1.85), at(0, -sh.Y * 0.45, 0), GREY, METAL)
		deco(F, "Sabaton", V(foot.X * 1.5, foot.Y * 1.4, foot.Z * 1.2), at(0, 0, 0.05), GREY_DK, METAL)
		local td = foot.X * 1.5
		deco(F, "Toe", V(td, td, td), at(0, 0, -foot.Z * 0.55), GREY, METAL, BALL)
	end
end

return M
