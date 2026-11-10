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

-- THE VEIL OF FLAME (Config.Armor.VeilOfFlame; the chest under the chapel's loft in Pyralis Bulwark): no helm at all -
-- the skull hidden in living fire: nothing solid, only flames - a churning core of them, tongues licking up off it,
-- sparks, a glow
function M.wearVeil(char)
	if char:FindFirstChild("VeilOfFlame") then
		return
	end
	local folder, deco, size = M.kit(char, "VeilOfFlame")
	local head = char:FindFirstChild("Head")
	for _, d in ipairs(char:GetDescendants()) do -- the skull and what's welded to it (unwear puts them back)
		local w = d:IsA("BasePart") and d:FindFirstChildOfClass("WeldConstraint")
		if head and (d == head or (w and w.Part0 == head)) and not d:IsDescendantOf(folder) then
			d:SetAttribute("VeilOfFlameT", d.Transparency)
			d.Transparency = 1
		end
	end
	local R = size("Head").Magnitude / 2
	local core = deco("Head", "VeilCore", Vector3.one * R * 1.8, CFrame.new(0, 0.1, 0), Color3.fromRGB(255, 110, 30), Enum.Material.Neon, Enum.PartType.Ball)
	if not core then
		return
	end
	core.Transparency = 1 -- (only what burns off it shows: no glowing ball)
	core.CastShadow = false
	local f = Instance.new("Fire")
	f.Size, f.Heat = R * 3, 9
	f.Color, f.SecondaryColor = Color3.fromRGB(255, 120, 30), Color3.fromRGB(150, 20, 6)
	f.Parent = core
	local tongues = Instance.new("ParticleEmitter") -- (the flames licking up off it, every one a little different)
	tongues.Texture = "rbxasset://textures/particles/fire_main.dds"
	tongues.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 120)), ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 110, 30)), ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 20, 6)) })
	tongues.LightEmission = 1
	tongues.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, R * 0.9), NumberSequenceKeypoint.new(1, 0) })
	tongues.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 1) })
	tongues.Lifetime = NumberRange.new(0.35, 0.75)
	tongues.Speed = NumberRange.new(1.5, 3.5)
	tongues.Acceleration = Vector3.new(0, 7, 0)
	tongues.SpreadAngle = Vector2.new(25, 25)
	tongues.Rotation, tongues.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-120, 120)
	tongues.Rate = 90
	tongues.Shape = Enum.ParticleEmitterShape.Sphere
	tongues.Parent = core
	local churn = tongues:Clone() -- (the head's shape: a tight knot of flame turning over itself where the skull was)
	churn.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, R * 1.6), NumberSequenceKeypoint.new(0.5, R * 1.4), NumberSequenceKeypoint.new(1, R * 0.5) })
	churn.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.6, 0.1), NumberSequenceKeypoint.new(1, 1) })
	churn.Lifetime, churn.Speed, churn.Acceleration = NumberRange.new(0.3, 0.5), NumberRange.new(0.2, 0.8), Vector3.new(0, 2.5, 0)
	churn.ShapeStyle, churn.Rate, churn.LightEmission = Enum.ParticleEmitterShapeStyle.Volume, 140, 0.4
	churn.Parent = core
	local body = churn:Clone() -- (a dense, unlit heart under it: additive fire alone is see-through)
	body.Color = ColorSequence.new(Color3.fromRGB(230, 90, 20), Color3.fromRGB(120, 20, 4))
	body.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, R * 1.25), NumberSequenceKeypoint.new(1, R * 0.6) })
	body.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.7, 0.15), NumberSequenceKeypoint.new(1, 1) })
	body.LightEmission, body.Rate, body.Speed = 0, 120, NumberRange.new(0.1, 0.4)
	body.Parent = core
	local sparks = Instance.new("ParticleEmitter")
	sparks.Color, sparks.LightEmission = ColorSequence.new(Color3.fromRGB(255, 170, 70), Color3.fromRGB(220, 50, 10)), 1
	sparks.Size = NumberSequence.new(0.12, 0)
	sparks.Lifetime, sparks.Speed, sparks.SpreadAngle = NumberRange.new(0.6, 1.4), NumberRange.new(2, 5), Vector2.new(50, 50)
	sparks.Acceleration, sparks.Rate = Vector3.new(0, 5, 0), 10
	sparks.Parent = core
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 130, 50), 12, 2
	l.Parent = core
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

-- THE PYRE PRIEST'S MASK and VESTMENTS (Config.Armor.PyreMask / PyreRobes; two chests hidden in the Palace of
-- Pyralis): the sun-cult's own, as its combat mages wear them (Characters/Pyre). The mask: a disc of beaten gold, rays
-- round it, slits for eyes with fire behind; a cowl; the mitre, cut down; and behind the head, floating, the halo -
-- a ring of fire that never goes out. The vestments: ash-grey robes over crimson, a gold-edged stole, a breastplate
-- of blackened steel, the skirt cut short with tabards in front, a sword belt and scabbard, a pauldron on the left
local P_ASH, P_CRIMSON, P_GOLD = Color3.fromRGB(70, 64, 60), Color3.fromRGB(96, 18, 16), Color3.fromRGB(176, 132, 58)
local P_SUN, P_FLAME, P_STEEL, P_LEATHER = Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 110, 30), Color3.fromRGB(34, 30, 30), Color3.fromRGB(40, 28, 22)
function M.wearPyreMask(char)
	if char:FindFirstChild("PyreMask") then
		return
	end
	local folder, deco, size = M.kit(char, "PyreMask")
	local head = char:FindFirstChild("Head")
	for _, d in ipairs(char:GetDescendants()) do -- the skull's own face and what's welded to it go under the cowl
		local w = d:IsA("BasePart") and d:FindFirstChildOfClass("WeldConstraint")
		if head and (d == head or (w and w.Part0 == head)) and not d:IsDescendantOf(folder) then
			d:SetAttribute("PyreMaskT", d.Transparency)
			d.Transparency = 1
		end
	end
	local h = size("Head")
	local k = h.Y / 1.25 -- (the Pyre's head is 1.25 tall: everything below in its measures)
	local function V(x, y, z)
		return Vector3.new(x, y, z) * k
	end
	local function at(x, y, z)
		return CFrame.new(x * k, y * k, z * k)
	end
	local cyl, up = Enum.PartType.Cylinder, CFrame.Angles(0, 0, math.pi / 2)
	local METAL, FABRIC, NEON = Enum.Material.Metal, Enum.Material.Fabric, Enum.Material.Neon
	deco("Head", "Cowl", V(1.3, 1.35, 1.3), at(0, 0, 0.08), P_ASH, FABRIC)
	deco("Head", "Mask", V(0.12, 1.15, 1.15), at(0, 0, -0.64) * CFrame.Angles(0, math.pi / 2, 0), P_GOLD, METAL, cyl)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		deco("Head", "MaskRay", V(0.12, 0.34, 0.05), at(math.cos(a) * 0.68, math.sin(a) * 0.68, -0.66) * CFrame.Angles(0, 0, a - math.pi / 2), P_GOLD, METAL)
	end
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "EyeSlit", V(0.3, 0.06, 0.04), at(sx * 0.22, 0.1, -0.71), Color3.fromRGB(6, 4, 2), Enum.Material.SmoothPlastic)
		deco("Head", "Eye", V(0.12, 0.05, 0.03), at(sx * 0.22, 0.1, -0.72), P_SUN, NEON)
	end
	deco("Head", "MaskMouth", V(0.2, 0.05, 0.04), at(0, -0.28, -0.71), Color3.fromRGB(6, 4, 2), Enum.Material.SmoothPlastic)
	for i = 0, 2 do -- the mitre, cut down for a fighter
		local w = 1.05 - i * 0.14
		deco("Head", "Mitre", V(w, 0.42, w * 0.8), at(0, 0.85 + i * 0.4, 0.05), i % 2 == 0 and P_CRIMSON or P_GOLD, i % 2 == 0 and FABRIC or METAL)
	end
	for i = 0, 15 do -- the halo: a ring of fire behind the head, floating
		local a = i / 16 * math.pi * 2
		local p = deco("Head", "Halo", V(0.16, 0.36, 0.16), at(math.cos(a) * 1.05, 0.3 + math.sin(a) * 1.05, 0.75) * CFrame.Angles(0, 0, a), P_SUN, NEON)
		if p and i % 4 == 0 then
			local f = Instance.new("Fire")
			f.Size, f.Heat = 2, 3
			f.Color, f.SecondaryColor = P_FLAME, Color3.fromRGB(120, 20, 6)
			f.Parent = p
		end
	end
	local hl = deco("Head", "HaloLight", V(0.2, 0.2, 0.2), at(0, 0.3, 0.75), P_SUN, NEON)
	if hl then
		hl.Transparency = 1
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = P_FLAME, 12, 1.4
		l.Parent = hl
	end
end

function M.wearPyreRobes(char)
	if char:FindFirstChild("PyreRobes") then
		return
	end
	local _, deco, size = M.kit(char, "PyreRobes")
	local chest, hips = size("Chest"), size("Hips")
	local cw, ch, cd, hw, hd = chest.X, chest.Y, chest.Z, hips.X, hips.Z
	local V, at = Vector3.new, CFrame.new
	local cyl, ball, up = Enum.PartType.Cylinder, Enum.PartType.Ball, CFrame.Angles(0, 0, math.pi / 2)
	local METAL, FABRIC, LEATHER = Enum.Material.Metal, Enum.Material.Fabric, Enum.Material.Leather
	-- the robes: ash over crimson, the mantle, the gold-edged stole, a sun on the breast; the breastplate over them
	deco("Chest", "Robe", V(cw * 1.1, ch * 1.05, cd * 1.15), at(0, 0, 0), P_ASH, FABRIC)
	deco("Chest", "Mantle", V(cw * 1.35, 0.5, cd * 1.45), at(0, ch / 2 - 0.12, 0), P_CRIMSON, FABRIC)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Chest", "Stole", V(0.32, ch * 1.6, 0.06), at(sx * cw * 0.2, -0.4, -cd * 0.6), P_CRIMSON, FABRIC)
		deco("Chest", "StoleEdge", V(0.06, ch * 1.6, 0.07), at(sx * cw * 0.2 + sx * 0.16, -0.4, -cd * 0.6), P_GOLD, METAL)
	end
	deco("Chest", "Breastplate", V(cw * 0.9, ch * 0.62, 0.14), at(0, 0.12, -cd * 0.66), P_STEEL, METAL)
	deco("Chest", "BreastplateRim", V(cw * 0.94, 0.1, 0.16), at(0, 0.12 + ch * 0.31, -cd * 0.66), P_GOLD, METAL)
	deco("Chest", "BreastSun", V(0.06, 0.5, 0.5), at(0, 0.2, -cd * 0.75) * CFrame.Angles(0, math.pi / 2, 0), P_GOLD, METAL, cyl)
	-- the waist: the cincture, a sword belt slung and its scabbard, the skirt in rings cut short, tabards before it
	deco("Hips", "Cincture", V(hw * 1.2, 0.22, hd * 1.25), at(0, 0.3, 0), P_GOLD, METAL)
	deco("Hips", "SwordBelt", V(hw * 1.25, 0.16, hd * 1.3), at(0, 0.05, 0) * CFrame.Angles(0, 0, 0.18), P_LEATHER, LEATHER)
	deco("Hips", "Scabbard", V(0.24, 2.0, 0.34), at(-hw * 0.62, -0.7, 0.1) * CFrame.Angles(0, 0, -0.25), Color3.fromRGB(30, 22, 18), LEATHER)
	for i = 0, 3 do
		deco("Hips", "Skirt", V(0.6, hw * 1.2 + i * 0.25, hw * 1.2 + i * 0.25), at(0, 0.05 - i * 0.5, 0) * up, i == 3 and P_GOLD or (i % 2 == 0 and P_ASH or P_CRIMSON), i == 3 and METAL or FABRIC, cyl)
	end
	for _, sx in ipairs({ -1, 1 }) do
		deco("Hips", "Tabard", V(0.5, 1.6, 0.06), at(sx * 0.32, -0.9, -hd * 0.7), P_CRIMSON, FABRIC)
	end
	-- the arms: sleeves, crimson cuffs gold-hemmed, bracers; the sword arm's pauldron
	for _, n in ipairs({ "R", "L" }) do
		local ua, la = size(n .. "UpperArm"), size(n .. "LowerArm")
		local aw = ua.X
		deco(n .. "UpperArm", "Sleeve", V(aw * 1.5, ua.Y * 0.95, aw * 1.5), at(0, 0, 0), P_ASH, FABRIC)
		deco(n .. "LowerArm", "Cuff", V(aw * 2.0, la.Y * 0.75, aw * 2.0), at(0, 0.12, 0), P_CRIMSON, FABRIC)
		deco(n .. "LowerArm", "CuffHem", V(aw * 2.04, 0.1, aw * 2.04), at(0, -la.Y * 0.25, 0), P_GOLD, METAL)
		deco(n .. "LowerArm", "Bracer", V(aw * 1.35, la.Y * 0.45, aw * 1.35), at(0, -la.Y * 0.12, 0), P_LEATHER, LEATHER)
	end
	local ua = size("LUpperArm")
	deco("LUpperArm", "Pauldron", V(ua.X * 2.2, ua.X * 1.3, ua.X * 2.2), at(-0.1, ua.Y * 0.34, 0), P_STEEL, METAL, ball)
	deco("LUpperArm", "PauldronRim", V(0.12, ua.X * 2.26, ua.X * 2.26), at(-0.1, ua.Y * 0.3, 0) * up, P_GOLD, METAL, cyl)
end

---------------------------------------------------------------------------
-- THE FOUND PIECES (Config.Armor TurnkeyCoif .. HeadsmanJerkin; each in a chest of its own, init.server's ARMOR
-- CHESTS). M.Wear[key](char) dresses one; dressArmor puts on and takes off all of them by this table. Head pieces
-- are measured for a head 1.25 tall, as the Pyre's are: x and z +-0.575, y +-0.625, the face at -z.
---------------------------------------------------------------------------
M.Wear = {}
local C, V3, CF, ANG, PI = Color3.fromRGB, Vector3.new, CFrame.new, CFrame.Angles, math.pi
local BALL, CYL = Enum.PartType.Ball, Enum.PartType.Cylinder
local FAB, LEA, MET, SM, GLASS, NEON = Enum.Material.Fabric, Enum.Material.Leather, Enum.Material.Metal, Enum.Material.SmoothPlastic, Enum.Material.Glass, Enum.Material.Neon
local UP = ANG(0, 0, PI / 2) -- (a cylinder runs along X: this stands it on end - a disc lying flat)
local FACE = ANG(0, PI / 2, 0) -- (and this turns it along Z - a disc facing front)
local KNIGHT_HELM = { Helm = true, HelmTop = true, HelmCrest = true, HelmBand = true, Visor = true, Breaths = true }

local function piece(key, fn)
	M.Wear[key] = function(char)
		if not char:FindFirstChild(key) then
			fn(char, key, M.kit(char, key))
		end
	end
end
-- a piece on the head: hides the knight's own helm (skull: the whole head and all on it; unwear puts them back).
-- Returns put(name, size, cf, color, mat, shape) in the head's 1.25 measures, and that scale
local function onHead(char, key, folder, deco, size, skull)
	local head = char:FindFirstChild("Head")
	for _, d in ipairs(char:GetDescendants()) do
		local w = d:IsA("BasePart") and d:FindFirstChildOfClass("WeldConstraint")
		local hide = d:IsA("BasePart") and KNIGHT_HELM[d.Name] or skull and (d == head or (w and head and w.Part0 == head))
		if hide and not d:IsDescendantOf(folder) then
			d:SetAttribute(key .. "T", d.Transparency)
			d.Transparency = 1
		end
	end
	local k = size("Head").Y / 1.25
	return function(name, sz, cf, color, mat, shape)
		return deco("Head", name, sz * k, cf.Rotation + cf.Position * k, color, mat, shape)
	end, k
end
local function on(deco, partName)
	return function(name, sz, cf, color, mat, shape)
		return deco(partName, name, sz, cf, color, mat, shape)
	end
end
-- n of a thing evenly from point a to point b, each turned by rot
local function line(put, name, a, b, n, sz, color, mat, shape, rot)
	for i = 0, n - 1 do
		put(name, sz, CF(a:Lerp(b, n > 1 and i / (n - 1) or 0.5)) * (rot or CF()), color, mat, shape)
	end
end
-- n of a thing round an ellipse (radii rx, rz) about c, from angle a0 to a1 (-pi/2 = straight ahead; a whole turn
-- spaces them evenly), each turned to face out (its X outward, Z along the ring), then by rot
local function ring(put, name, c, rx, rz, n, a0, a1, sz, color, mat, shape, rot)
	local full = math.abs(a1 - a0) >= 2 * PI - 1e-3
	for i = 0, n - 1 do
		local a = a0 + (a1 - a0) * (full and i / n or (n > 1 and i / (n - 1) or 0.5))
		put(name, sz, CF(c + V3(math.cos(a) * rx, 0, math.sin(a) * rz)) * ANG(0, -a, 0) * (rot or CF()), color, mat, shape)
	end
end
-- a cord, strap or shaft from a to b
local function strand(put, name, a, b, w, color, mat)
	return put(name, V3(w, w, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), color, mat or FAB)
end
local function body(size)
	local c, h = size("Chest"), size("Hips")
	return c.X, c.Y, c.Z, h.X, h.Y, h.Z
end
-- fn(upper, lower, upperSize, lowerSize, sx) for each arm: put()s on its upper and lower arm, sx +1 right, -1 left
local function sleeves(deco, size, fn)
	for _, s in ipairs({ "R", "L" }) do
		fn(on(deco, s .. "UpperArm"), on(deco, s .. "LowerArm"), size(s .. "UpperArm"), size(s .. "LowerArm"), s == "R" and 1 or -1)
	end
end
-- a coat's skirt, whole cloth, len below the waist: before and behind each leg off that thigh (so it swings with
-- it and the leg never passes through), the sides off the hips, flared; a hem along every panel's foot
local function skirt(deco, size, len, color, hem, mat)
	local hips, thigh = size("Hips"), size("RThigh")
	for _, s in ipairs({ "R", "L" }) do
		local sx = s == "R" and 1 or -1
		for _, sz in ipairs({ -1, 1 }) do
			local top = CF(0, thigh.Y / 2 + 0.1, sz * (thigh.Z / 2 + 0.1)) * ANG(-sz * 0.08, 0, 0)
			deco(s .. "Thigh", "Skirt", V3(thigh.X * 1.7, len, 0.06), top * CF(0, -len / 2, 0), color, mat)
			deco(s .. "Thigh", "SkirtHem", V3(thigh.X * 1.72, 0.09, 0.08), top * CF(0, -len + 0.05, 0), hem, mat)
		end
		local sl = len + hips.Y * 0.5
		local side = CF(sx * (hips.X / 2 + 0.06), hips.Y * 0.3, 0) * ANG(0, 0, sx * 0.12)
		deco("Hips", "Skirt", V3(0.06, sl, hips.Z * 1.3), side * CF(0, -sl / 2, 0), color, mat)
		deco("Hips", "SkirtHem", V3(0.08, 0.09, hips.Z * 1.32), side * CF(0, -sl + 0.05, 0), hem, mat)
	end
end

-- HELMS -------------------------------------------------------------------

-- THE TURNKEY'S COIF (the keep's barracks): a quilted linen arming cap, its hood down the sides and back sewn over
-- with mail in rows; the face left bare. A cell key tied at the temple
piece("TurnkeyCoif", function(char, key, folder, deco, size)
	local p = onHead(char, key, folder, deco, size)
	local LINEN, SEAM, MAIL, IRON = C(176, 160, 128), C(118, 102, 78), C(124, 126, 132), C(64, 62, 60)
	p("Cap", V3(1.26, 0.36, 1.26), CF(0, 0.5, 0.03), LINEN, FAB)
	p("CapCrown", V3(1.02, 0.14, 1.02), CF(0, 0.73, 0.03), LINEN, FAB)
	for _, x in ipairs({ -0.42, -0.14, 0.14, 0.42 }) do
		p("Quilt", V3(0.06, 0.06, 1.3), CF(x, 0.69, 0.03), SEAM, FAB)
	end
	p("CapRoll", V3(1.32, 0.1, 1.32), CF(0, 0.33, 0.03), SEAM, FAB)
	for _, sx in ipairs({ -1, 1 }) do
		p("CoifSide", V3(0.08, 0.95, 1.0), CF(sx * 0.66, -0.1, 0.1), LINEN, FAB)
	end
	p("CoifBack", V3(1.4, 0.95, 0.08), CF(0, -0.1, 0.68), LINEN, FAB)
	for r = 0, 5 do
		ring(p, "Mail", V3(0, 0.22 - r * 0.16, 0.06), 0.76 + r * 0.04, 0.76 + r * 0.04, 18, -PI / 2 + 0.8, 3 * PI / 2 - 0.8, Vector3.one * 0.13, MAIL, MET, BALL)
	end
	strand(p, "KeyCord", V3(-0.8, 0.48, -0.28), V3(-0.86, 0.22, -0.3), 0.03, SEAM)
	p("KeyRing", V3(0.05, 0.28, 0.28), CF(-0.88, 0.1, -0.3), IRON, MET, CYL)
	p("KeyShaft", V3(0.05, 0.42, 0.07), CF(-0.88, -0.22, -0.3), IRON, MET)
	p("KeyBit", V3(0.05, 0.1, 0.17), CF(-0.88, -0.38, -0.37), IRON, MET)
	p("KeyBit", V3(0.05, 0.07, 0.11), CF(-0.88, -0.26, -0.35), IRON, MET)
end)

-- THE HANGMAN'S HOOD (by the gallows in the Dim Yard): black canvas over the whole head, its peak slumped back,
-- a coarse seam up the front, eyeholes whipped round in hemp; a noose about the neck, its knot coiled behind
piece("HangmanHood", function(char, key, folder, deco, size)
	local p = onHead(char, key, folder, deco, size, true)
	local CANVAS, CANVAS_DK, HEMP, HEMP_DK = C(34, 31, 31), C(18, 17, 17), C(156, 128, 84), C(104, 84, 54)
	p("Hood", V3(1.3, 1.36, 1.3), CF(0, 0.02, 0.03), CANVAS, FAB)
	p("HoodPeak", V3(0.95, 0.4, 0.95), CF(0, 0.82, 0.12) * ANG(-0.25, 0, 0), CANVAS, FAB)
	p("HoodTip", V3(0.55, 0.36, 0.55), CF(0, 1.04, 0.36) * ANG(-0.55, 0, 0.12), CANVAS_DK, FAB)
	line(p, "Stitch", V3(0, 0.62, -0.665), V3(0, -0.52, -0.665), 8, V3(0.14, 0.035, 0.03), HEMP_DK, FAB)
	for _, sx in ipairs({ -1, 1 }) do
		line(p, "Stitch", V3(sx * 0.665, 0.6, 0.05), V3(sx * 0.665, -0.52, 0.05), 7, V3(0.03, 0.035, 0.14), HEMP_DK, FAB)
		p("EyeHole", V3(0.3, 0.17, 0.04), CF(sx * 0.27, 0.14, -0.66) * ANG(0, 0, sx * 0.08), C(0, 0, 0), SM)
		for i = 0, 5 do
			local a = i / 6 * 2 * PI
			p("Whip", V3(0.05, 0.05, 0.03), CF(sx * 0.27 + math.cos(a) * 0.19, 0.14 + math.sin(a) * 0.12, -0.67), HEMP_DK, FAB)
		end
	end
	ring(p, "Fray", V3(0, -0.72, 0.03), 0.64, 0.64, 16, 0, 2 * PI, V3(0.05, 0.22, 0.18), CANVAS_DK, FAB)
	ring(p, "Noose", V3(0, -0.72, 0.02), 0.52, 0.52, 18, 0, 2 * PI, Vector3.one * 0.2, HEMP, FAB, BALL)
	line(p, "Knot", V3(0.4, -0.66, 0.42), V3(0.4, -1.02, 0.42), 5, V3(0.12, 0.27, 0.27), HEMP_DK, FAB, CYL, UP)
	strand(p, "NooseEnd", V3(0.4, -1.08, 0.44), V3(0.46, -1.7, 0.56), 0.1, HEMP)
	p("NooseFray", V3(0.16, 0.12, 0.16), CF(0.46, -1.74, 0.57), HEMP_DK, FAB)
end)

-- THE TOWNWARDEN'S TRICORNE (in the mesa town): black felt, its brim turned up in three walls edged in gold braid; a
-- cockade on the left, a long crimson plume sweeping back from it; a black ribbon bow at the nape
piece("Tricorne", function(char, key, folder, deco, size)
	local ph = onHead(char, key, folder, deco, size)
	local function p(name, sz, cf, ...) -- (the hat a fifth bigger, sunk down over the cranium to just above the sockets)
		return ph(name, sz * 1.2, cf.Rotation + cf.Position * 1.2 + V3(0, -0.42, 0), ...)
	end
	local FELT, FELT_DK, GOLD, PLUME, COCKADE, RIBBON = C(28, 26, 32), C(16, 15, 18), C(196, 160, 80), C(150, 24, 28), C(232, 226, 212), C(30, 40, 90)
	p("Crown", V3(0.42, 1.08, 1.08), CF(0, 0.8, 0.03) * UP, FELT, FAB, CYL)
	p("CrownTop", V3(0.05, 0.95, 0.95), CF(0, 1.02, 0.03) * UP, FELT_DK, FAB, CYL)
	p("Brim", V3(0.06, 1.55, 1.55), CF(0, 0.6, 0.03) * UP, FELT, FAB, CYL)
	for i = 0, 2 do
		local a = PI / 2 + i * 2 * PI / 3
		local w = CF(math.cos(a) * 0.56, 0.78, math.sin(a) * 0.56 + 0.03) * ANG(0, -a, 0) * ANG(0, 0, -0.32)
		p("BrimWall", V3(0.08, 0.42, 1.75), w, FELT, FAB)
		for z = -0.84, 0.85, 0.14 do
			p("Braid", Vector3.one * 0.09, w * CF(0.02, 0.21, z), GOLD, MET, BALL)
		end
		if i == 1 then -- (the front left wall)
			p("Cockade", V3(0.05, 0.36, 0.36), w * CF(0.06, 0.02, 0.32), COCKADE, FAB, CYL)
			p("CockadeEye", V3(0.06, 0.18, 0.18), w * CF(0.08, 0.02, 0.32), RIBBON, FAB, CYL)
			p("CockadeButton", Vector3.one * 0.1, w * CF(0.1, 0.02, 0.32), GOLD, MET, BALL)
			for j = 0, 9 do
				local b = j / 10 * 2 * PI
				p("Pleat", V3(0.04, 0.07, 0.07), w * CF(0.07, 0.02 + math.cos(b) * 0.17, 0.32 + math.sin(b) * 0.17), COCKADE:Lerp(RIBBON, j % 2 * 0.5), FAB)
			end
		end
	end
	-- the plume, from the cockade up and back over the crown, barbs either side
	local p0, p1, p2 = V3(-0.62, 0.95, -0.25), V3(-0.5, 1.55, 0.25), V3(-0.22, 1.18, 0.95)
	local function bez(t)
		return p0:Lerp(p1, t):Lerp(p1:Lerp(p2, t), t)
	end
	for i = 0, 8 do
		local t = i / 9
		local seg = CFrame.lookAt(bez(t), bez(t + 0.06))
		p("Plume", V3(0.06, 0.05, 0.2), seg, PLUME, FAB)
		for _, sx in ipairs({ -1, 1 }) do
			p("Barb", V3(0.22 * (1 - t * 0.5), 0.03, 0.08), seg * CF(sx * 0.12, 0, 0) * ANG(0, sx * 0.5, 0), PLUME:Lerp(C(255, 255, 255), 0.12 * (i % 2)), FAB)
		end
	end
	for _, sx in ipairs({ -1, 1 }) do -- (under the brim's back, against the skull: not scaled with the hat)
		ph("Bow", V3(0.2, 0.24, 0.06), CF(sx * 0.14, 0.17, 0.6) * ANG(0, 0, sx * 0.5), C(12, 12, 14), FAB)
		ph("BowTail", V3(0.08, 0.32, 0.03), CF(sx * 0.06, 0.0, 0.6) * ANG(0.25, 0, sx * 0.12), C(12, 12, 14), FAB)
	end
	ph("BowKnot", Vector3.one * 0.11, CF(0, 0.17, 0.62), C(12, 12, 14), FAB, BALL)
end)

-- THE WIDOW'S MOURNING VEIL (the Hollow Mansion's dormitory): a little velvet pillbox ringed in jet beads, a black
-- lace veil from it over the face, a bow behind with long ribbons, and a dried rose pinned at the side
piece("MourningVeil", function(char, key, folder, deco, size)
	local p = onHead(char, key, folder, deco, size)
	local VELVET, JET, LACE, ROSE, LEAF = C(20, 18, 22), C(34, 34, 40), C(14, 12, 16), C(96, 20, 30), C(52, 64, 40)
	p("Pillbox", V3(0.3, 0.78, 0.78), CF(0.1, 0.78, -0.02) * UP, VELVET, FAB, CYL)
	p("PillboxButton", Vector3.one * 0.12, CF(0.1, 0.95, -0.02), JET, SM, BALL)
	ring(p, "Jet", V3(0.1, 0.66, -0.02), 0.4, 0.4, 14, 0, 2 * PI, Vector3.one * 0.08, JET, SM, BALL)
	local veil = { p("Veil", V3(1.3, 1.0, 0.03), CF(0, 0.12, -0.66), LACE, FAB) }
	for _, sx in ipairs({ -1, 1 }) do
		table.insert(veil, p("VeilSide", V3(0.03, 1.0, 0.9), CF(sx * 0.67, 0.12, -0.2), LACE, FAB))
	end
	for _, v in ipairs(veil) do
		v.Transparency = 0.45 -- (the face shows dimly through)
	end
	p("VeilBand", V3(1.34, 0.08, 0.06), CF(0, 0.62, -0.67), JET, SM)
	for _, y in ipairs({ 0.42, 0.18, -0.06, -0.3 }) do
		line(p, "Lace", V3(-0.55, y, -0.68), V3(0.55, y, -0.68), 9, Vector3.one * 0.05, LACE, FAB, BALL)
	end
	line(p, "Scallop", V3(-0.6, -0.4, -0.67), V3(0.6, -0.4, -0.67), 11, Vector3.one * 0.13, LACE, FAB, BALL)
	for _, sx in ipairs({ -1, 1 }) do
		p("Bow", V3(0.06, 0.24, 0.3), CF(0.1 + sx * 0.16, 0.8, 0.42) * ANG(0, sx * 0.6, 0), VELVET, FAB)
		p("Ribbon", V3(0.12, 0.7, 0.03), CF(0.1 + sx * 0.08, 0.38, 0.6) * ANG(0.1, 0, sx * 0.1), VELVET, FAB)
	end
	p("BowKnot", Vector3.one * 0.12, CF(0.1, 0.8, 0.44), JET, SM, BALL)
	p("Rose", Vector3.one * 0.2, CF(-0.36, 0.86, -0.25), ROSE, FAB, BALL)
	for j = 0, 5 do
		local a = j / 6 * 2 * PI
		p("Petal", Vector3.one * 0.12, CF(-0.36 + math.cos(a) * 0.11, 0.84, -0.25 + math.sin(a) * 0.11), ROSE:Lerp(C(0, 0, 0), 0.25), FAB, BALL)
	end
	p("RoseLeaf", V3(0.22, 0.03, 0.1), CF(-0.52, 0.8, -0.14) * ANG(0, 0.6, 0.3), LEAF, FAB)
end)

-- THE CROWNED CHAMPION'S GALEA (the Crowned Colosseum): a bronze brimmed helm, a grilled face, cheek guards and a
-- neck guard; a laurel of gold round the bowl, a circlet of gold points over the brow, a crest of red horsehair
piece("ChampionGalea", function(char, key, folder, deco, size)
	local p = onHead(char, key, folder, deco, size, true)
	local BRONZE, BRONZE_DK, GOLD, PLUME, DARK = C(170, 120, 58), C(120, 82, 40), C(214, 176, 84), C(150, 22, 24), C(12, 10, 8)
	p("Bowl", Vector3.one * 1.34, CF(0, 0.16, 0.04), BRONZE, MET, BALL)
	p("Brim", V3(0.07, 1.8, 1.8), CF(0, 0.26, 0.04) * UP, BRONZE_DK, MET, CYL)
	p("FaceGuard", V3(1.1, 0.8, 0.2), CF(0, -0.2, -0.58), BRONZE_DK, MET)
	p("GrilleBack", V3(0.9, 0.66, 0.04), CF(0, -0.2, -0.69), DARK, SM)
	line(p, "GrilleBar", V3(-0.4, -0.2, -0.71), V3(0.4, -0.2, -0.71), 7, V3(0.05, 0.66, 0.05), BRONZE, MET)
	for _, y in ipairs({ 0.06, -0.2, -0.46 }) do
		p("GrilleRail", V3(0.9, 0.05, 0.05), CF(0, y, -0.715), BRONZE, MET)
	end
	for _, sx in ipairs({ -1, 1 }) do
		p("Cheek", V3(0.08, 0.72, 0.55), CF(sx * 0.63, -0.25, -0.28) * ANG(0, 0, -sx * 0.08), BRONZE, MET)
		line(p, "Rivet", V3(sx * 0.68, 0.0, -0.4), V3(sx * 0.7, -0.5, -0.4), 3, Vector3.one * 0.07, GOLD, MET, BALL)
	end
	p("NeckGuard", V3(1.1, 0.3, 0.12), CF(0, -0.35, 0.62) * ANG(0.4, 0, 0), BRONZE_DK, MET)
	ring(p, "Laurel", V3(0, 0.36, 0.04), 0.66, 0.66, 22, 0, 2 * PI, V3(0.05, 0.08, 0.16), GOLD, MET, nil, ANG(0.5, 0, 0))
	ring(p, "CrownPoint", V3(0, 0.5, 0.04), 0.62, 0.62, 9, -PI + 0.3, -0.3, V3(0.06, 0.2, 0.08), GOLD, MET)
	for i = 0, 9 do
		local t = i / 9
		local z = -0.55 + t * 1.15
		local base = 0.16 + math.sqrt(math.max(0, 0.67 ^ 2 - (z - 0.04) ^ 2))
		local h = 0.28 + math.sin(t * PI) * 0.3
		p("CrestFoot", V3(0.14, 0.06, 0.13), CF(0, base, z), GOLD, MET)
		p("Crest", V3(0.16, h, 0.14), CF(0, base + h / 2, z), PLUME:Lerp(C(0, 0, 0), (i % 2) * 0.15), FAB)
	end
end)

-- THE BULWARK SENTINEL'S SALLET (Pyralis's guard hall): blackened steel, a long tail of lames flaring behind, a visor
-- with an ember glowing in its slit, a bevor at the chin; a gold sun on the brow, a gilt comb, a plume of embers
piece("SentinelSallet", function(char, key, folder, deco, size)
	local p = onHead(char, key, folder, deco, size, true)
	local STEEL, STEEL_DK, GOLD, EMBER, PLUME = C(40, 36, 36), C(26, 24, 24), C(176, 132, 58), C(255, 120, 40), C(200, 60, 20)
	p("Bowl", Vector3.one * 1.32, CF(0, 0.15, 0.06), STEEL, MET, BALL)
	for i = 0, 2 do
		local cf = CF(0, -0.12 - i * 0.12, 0.58 + i * 0.16) * ANG(0.35 + i * 0.12, 0, 0)
		p("Lame", V3(1.2 - i * 0.06, 0.13, 0.5), cf, i % 2 == 0 and STEEL or STEEL_DK, MET)
		p("LameEdge", V3(1.22 - i * 0.06, 0.04, 0.06), cf * CF(0, 0, 0.24), GOLD, MET)
	end
	p("SalletVisor", V3(1.24, 0.5, 0.2), CF(0, 0.12, -0.6), STEEL_DK, MET) -- (not "Visor": that name is the knight's own helm's)
	p("Slit", V3(0.95, 0.07, 0.05), CF(0, 0.18, -0.705), C(4, 2, 2), SM)
	p("SlitGlow", V3(0.7, 0.03, 0.03), CF(0, 0.18, -0.72), EMBER, NEON)
	p("VisorRidge", V3(0.06, 0.5, 0.05), CF(0, 0.12, -0.725), GOLD, MET)
	p("Bevor", V3(1.1, 0.55, 0.3), CF(0, -0.38, -0.5) * ANG(-0.2, 0, 0), STEEL, MET)
	line(p, "Breath", V3(0.18, -0.3, -0.67), V3(0.42, -0.3, -0.67), 4, V3(0.04, 0.14, 0.04), C(4, 2, 2), SM)
	p("BrowSun", V3(0.05, 0.3, 0.3), CF(0, 0.5, -0.55) * FACE, GOLD, MET, CYL)
	for j = 0, 7 do
		local a = j / 8 * 2 * PI
		p("Ray", V3(0.04, 0.14, 0.05), CF(math.cos(a) * 0.2, 0.5 + math.sin(a) * 0.2, -0.55) * ANG(0, 0, a - PI / 2), GOLD, MET)
	end
	p("Comb", V3(0.08, 0.14, 1.0), CF(0, 0.8, 0.06), GOLD, MET)
	ring(p, "Rivet", V3(0, -0.04, 0.06), 0.66, 0.66, 12, -PI / 2 + 0.9, 3 * PI / 2 - 0.9, Vector3.one * 0.07, GOLD, MET, BALL)
	local holder = p("PlumeHolder", V3(0.14, 0.2, 0.14), CF(0, 0.78, 0.42), GOLD, MET)
	for j = -2, 2 do
		p("Plume", V3(0.08, 0.1, 0.75), CF(0, 0.88, 0.5) * ANG(0, j * 0.18, 0) * ANG(-0.3, 0, 0) * CF(0, 0, 0.32), PLUME:Lerp(EMBER, (j + 2) / 4), FAB)
	end
	if holder then
		local f = Instance.new("Fire")
		f.Size, f.Heat = 1.2, 4
		f.Color, f.SecondaryColor = EMBER, C(120, 20, 6)
		f.Parent = holder
	end
end)

-- THE DRIFTER'S HAT (the far township): a wide cone of straw sunk down over the skull to the brow, woven, frayed
-- round its edge, cords under the chin, a float and hook hung off the brim; a faded scarf wound over the mouth
piece("DrifterHat", function(char, key, folder, deco, size)
	local p = onHead(char, key, folder, deco, size)
	local STRAW, STRAW_DK, CORD, SCARF, SCARF_DK = C(196, 170, 110), C(160, 134, 82), C(110, 80, 50), C(70, 90, 110), C(50, 64, 80)
	local B = 0.28 -- the brim's height: just over the sockets (the cranium's top is at 0.67)
	for i = 0, 6 do -- (rings 0.12 apart and 0.14 thick: no gaps up the cone)
		local d = 3.0 - i * 0.42
		p("Straw", V3(0.14, d, d), CF(0, B + i * 0.12, 0.03) * UP, i % 2 == 0 and STRAW or STRAW_DK, FAB, CYL)
	end
	p("Tip", Vector3.one * 0.24, CF(0, B + 0.78, 0.03), STRAW_DK, FAB, BALL)
	ring(p, "Weave", V3(0, B + 0.4, 0.03), 0.86, 0.86, 14, 0, 2 * PI, V3(1.0, 0.03, 0.04), STRAW_DK, FAB, nil, ANG(0, 0, -0.52))
	ring(p, "Fringe", V3(0, B - 0.04, 0.03), 1.5, 1.5, 36, 0, 2 * PI, V3(0.22, 0.03, 0.07), STRAW, FAB, nil, ANG(0, 0, -0.6))
	ring(p, "HatBand", V3(0, B + 0.36, 0.03), 0.95, 0.95, 20, 0, 2 * PI, V3(0.05, 0.1, 0.36), SCARF_DK, FAB)
	for _, sx in ipairs({ -1, 1 }) do
		strand(p, "ChinCord", V3(sx * 0.6, B - 0.05, -0.05), V3(sx * 0.08, -0.62, -0.46), 0.04, CORD)
	end
	p("CordKnot", Vector3.one * 0.09, CF(0, -0.64, -0.47), CORD, FAB, BALL)
	strand(p, "Line", V3(1.06, B - 0.05, 0.55), V3(1.08, -0.16, 0.57), 0.03, C(200, 200, 190))
	p("Float", Vector3.one * 0.14, CF(1.08, -0.22, 0.57), C(190, 40, 30), SM, BALL)
	p("FloatTop", Vector3.one * 0.08, CF(1.08, -0.13, 0.57), C(230, 226, 214), SM, BALL)
	p("Hook", V3(0.03, 0.14, 0.03), CF(1.08, -0.35, 0.57), C(120, 120, 124), MET)
	p("Scarf", V3(1.26, 0.42, 1.26), CF(0, -0.42, 0.02), SCARF, FAB)
	for _, y in ipairs({ -0.3, -0.42, -0.54 }) do
		p("Fold", V3(1.28, 0.04, 1.28), CF(0, y, 0.02) * ANG(0, 0, (y + 0.42) * 0.6), SCARF_DK, FAB)
	end
	p("ScarfTail", V3(0.26, 0.75, 0.06), CF(0.32, -0.8, 0.66) * ANG(0.2, 0, 0.15), SCARF, FAB)
	p("ScarfTail", V3(0.2, 0.6, 0.06), CF(0.12, -0.75, 0.68) * ANG(0.15, 0, -0.1), SCARF_DK, FAB)
end)

-- BODIES ------------------------------------------------------------------

-- a body piece: takes off the knight's own ragged blue cloak and its collar (the rig's Cloak, CloakHem and Hood,
-- straight on the character - not any armor's) while it's on; unwear puts them back
local CAPE = { Cloak = true, CloakHem = true, Hood = true }
local function bodyPiece(key, fn)
	piece(key, function(char, k, folder, deco, size)
		for _, d in ipairs(char:GetChildren()) do
			if d:IsA("BasePart") and CAPE[d.Name] then
				d:SetAttribute(k .. "T", d.Transparency)
				d.Transparency = 1
			end
		end
		fn(char, k, folder, deco, size)
	end)
end

-- THE PIKEMAN'S BRIGANDINE (the keep's armory): red canvas over hidden plates - rows of brass rivets front and
-- back - a quilted collar, shoulder straps, a belt over a skirt of mail; riveted tassets down the thighs, quilted
-- sleeves and strapped leather bracers
bodyPiece("Brigandine", function(char, key, folder, deco, size)
	local cw, ch, cd, hw, hh, hd = body(size)
	local c, h = on(deco, "Chest"), on(deco, "Hips")
	local CANVAS, CANVAS_DK, BRASS, LINEN, LINEN_DK, LEATHER, MAIL = C(124, 30, 28), C(84, 20, 20), C(186, 146, 70), C(176, 160, 128), C(130, 114, 88), C(70, 46, 30), C(120, 122, 128)
	c("Brigandine", V3(cw * 1.12, ch * 0.98, cd * 1.3), CF(0, -0.02, 0), CANVAS, FAB)
	for r = 0, 5 do
		local y = ch * 0.36 - r * ch * 0.15
		for _, zs in ipairs({ -1, 1 }) do
			line(c, "Rivet", V3(-cw * 0.44, y, zs * cd * 0.66), V3(cw * 0.44, y, zs * cd * 0.66), 6, Vector3.one * 0.09, BRASS, MET, BALL)
			if r < 5 then
				c("Seam", V3(cw * 1.1, 0.03, 0.02), CF(0, y - ch * 0.075, zs * cd * 0.655), CANVAS_DK, FAB)
			end
		end
	end
	c("Collar", V3(cw * 0.6, 0.3, cd * 1.15), CF(0, ch / 2 + 0.1, 0), LINEN, FAB)
	for i = 0, 2 do
		c("CollarQuilt", V3(cw * 0.62, 0.03, cd * 1.17), CF(0, ch / 2 + 0.02 + i * 0.08, 0), LINEN_DK, FAB)
	end
	for _, sx in ipairs({ -1, 1 }) do
		c("ShoulderStrap", V3(0.2, 0.06, cd * 1.36), CF(sx * cw * 0.32, ch / 2 - 0.02, 0), LEATHER, LEA)
		c("StrapBuckle", V3(0.16, 0.08, 0.14), CF(sx * cw * 0.32, ch / 2 + 0.01, -cd * 0.5), BRASS, MET)
	end
	-- the mail skirt: a hauberk's hem showing under the canvas, rings in rows over it
	h("MailSkirt", V3(hw * 1.04, hh * 0.75, hd * 1.06), CF(0, -hh * 0.08, 0), MAIL, MET)
	for r = 0, 2 do
		ring(h, "Mail", V3(0, hh * 0.1 - r * 0.17, 0), hw * 0.53, hd * 0.57, 26, 0, 2 * PI, Vector3.one * 0.13, MAIL, MET, BALL)
	end
	h("Belt", V3(hw * 1.22, 0.18, hd * 1.32), CF(0, hh * 0.38, 0), LEATHER, LEA)
	h("Buckle", V3(0.24, 0.2, 0.06), CF(0, hh * 0.38, -hd * 0.68), BRASS, MET)
	-- tassets: two riveted lames down the front of each thigh, from under the mail
	for _, s in ipairs({ "R", "L" }) do
		local th = size(s .. "Thigh")
		local t = on(deco, s .. "Thigh")
		for i, l in ipairs({ { th.Y * 0.25, 0.5, 1.3 }, { -th.Y * 0.12, 0.38, 1.2 } }) do
			local z = -th.Z / 2 - 0.035
			t("Tasset", V3(th.X * l[3], l[2], 0.07), CF(0, l[1], z), i == 1 and CANVAS or CANVAS_DK, FAB)
			t("TassetEdge", V3(th.X * l[3] + 0.02, 0.05, 0.08), CF(0, l[1] - l[2] / 2 + 0.03, z), BRASS, MET)
			line(t, "Rivet", V3(-th.X * 0.42, l[1] + l[2] * 0.25, z - 0.04), V3(th.X * 0.42, l[1] + l[2] * 0.25, z - 0.04), 3, Vector3.one * 0.07, BRASS, MET, BALL)
		end
	end
	sleeves(deco, size, function(u, l, ua, la)
		u("Sleeve", V3(ua.X * 1.35, ua.Y * 0.95, ua.Z * 1.35), CF(), LINEN, FAB)
		for i = 0, 3 do
			u("Quilt", V3(ua.X * 1.42, 0.04, ua.Z * 1.42), CF(0, ua.Y * (0.3 - i * 0.2), 0), LINEN_DK, FAB)
		end
		l("Bracer", V3(la.X * 1.35, la.Y * 0.55, la.Z * 1.35), CF(0, -la.Y * 0.12, 0), LEATHER, LEA)
		for _, y in ipairs({ 0.08, -0.32 }) do
			l("BracerStrap", V3(la.X * 1.42, 0.07, la.Z * 1.42), CF(0, la.Y * y, 0), C(40, 28, 20), LEA)
			l("StrapBuckle", V3(0.1, 0.1, 0.05), CF(0, la.Y * y, -la.Z * 0.72), BRASS, MET)
		end
	end)
end)

-- THE JAILER'S LONG COAT (by the dead jailer in the cistern): dark leather to the knee, wide lapels, two rows of iron
-- buttons, a high collar stitched round; his tally of years scratched over the heart; a ring of keys hung off his belt
-- and an iron-shod truncheon through a loop on the other side
bodyPiece("GaolerCoat", function(char, key, folder, deco, size)
	local cw, ch, cd, hw, hh, hd = body(size)
	local c, h = on(deco, "Chest"), on(deco, "Hips")
	local COAT, COAT_LT, IRON, BELT, PALE, WOOD = C(58, 40, 28), C(92, 66, 44), C(70, 68, 66), C(24, 20, 18), C(170, 150, 120), C(84, 60, 40)
	c("Coat", V3(cw * 1.12, ch * 1.0, cd * 1.28), CF(), COAT, LEA)
	for _, sx in ipairs({ -1, 1 }) do
		c("Lapel", V3(cw * 0.2, ch * 0.5, 0.06), CF(sx * cw * 0.17, ch * 0.2, -cd * 0.66) * ANG(0, 0, sx * 0.25), COAT_LT, LEA)
		line(c, "Button", V3(sx * cw * 0.2, ch * 0.02, -cd * 0.67), V3(sx * cw * 0.2, -ch * 0.42, -cd * 0.67), 4, Vector3.one * 0.1, IRON, MET, BALL)
	end
	c("Collar", V3(cw * 0.72, 0.34, cd * 1.22), CF(0, ch / 2 + 0.12, 0.04), COAT_LT, LEA)
	ring(c, "CollarStitch", V3(0, ch / 2 + 0.26, 0.04), cw * 0.37, cd * 0.63, 18, 0, 2 * PI, V3(0.02, 0.03, 0.07), PALE, FAB)
	for i = 0, 3 do
		c("Tally", V3(0.03, 0.2, 0.02), CF(-cw * 0.32 + i * 0.07, ch * 0.32, -cd * 0.645), PALE, FAB)
	end
	c("Tally", V3(0.03, 0.3, 0.02), CF(-cw * 0.32 + 0.105, ch * 0.32, -cd * 0.65) * ANG(0, 0, 1.1), PALE, FAB)
	h("Belt", V3(hw * 1.24, 0.2, hd * 1.34), CF(0, hh * 0.35, 0), BELT, LEA)
	h("Buckle", V3(0.26, 0.22, 0.06), CF(0, hh * 0.35, -hd * 0.7), IRON, MET)
	-- the keys: a ring hung under the belt on the right, against the coat's side
	local kx = hw / 2 + 0.13
	h("KeyLoop", V3(0.08, 0.18, 0.12), CF(kx, hh * 0.25, -0.1), IRON, MET)
	h("KeyRing", V3(0.05, 0.5, 0.5), CF(kx, -0.05, -0.1), IRON, MET, CYL)
	for i = 0, 3 do
		local k = CF(kx + 0.02, -0.3, -0.1) * ANG((i - 1.5) * 0.35, 0, 0)
		h("Key", V3(0.04, 0.4, 0.06), k * CF(0, -0.2, 0), IRON, MET)
		h("KeyBit", V3(0.04, 0.09, 0.13), k * CF(0, -0.36, -0.07), IRON, MET)
	end
	-- the truncheon on the left, through a leather loop at the belt, an iron knob at its foot
	local g = CF(-hw / 2 - 0.14, -0.25, 0.15) * ANG(0, 0, PI / 2 - 0.1)
	h("Truncheon", V3(1.1, 0.15, 0.15), g, WOOD, Enum.Material.Wood, CYL)
	h("TruncheonKnob", Vector3.one * 0.2, g * CF(-0.55, 0, 0), IRON, MET, BALL)
	h("TruncheonBand", V3(0.06, 0.18, 0.18), g * CF(-0.3, 0, 0), IRON, MET, CYL)
	h("TruncheonLoop", V3(0.2, 0.24, 0.24), (g * CF(0.47, 0, 0)), BELT, LEA, CYL) -- (round it, up at the belt)
	skirt(deco, size, 1.5, COAT, COAT_LT, LEA)
	sleeves(deco, size, function(u, l, ua, la, sx)
		u("Sleeve", V3(ua.X * 1.28, ua.Y * 0.95, ua.Z * 1.28), CF(), COAT, LEA)
		l("Sleeve", V3(la.X * 1.25, la.Y * 0.85, la.Z * 1.25), CF(0, la.Y * 0.05, 0), COAT, LEA)
		l("Cuff", V3(la.X * 1.55, la.Y * 0.26, la.Z * 1.55), CF(0, -la.Y * 0.3, 0), COAT_LT, LEA)
		line(l, "CuffButton", V3(sx * la.X * 0.79, -la.Y * 0.24, -0.06), V3(sx * la.X * 0.79, -la.Y * 0.36, -0.06), 2, Vector3.one * 0.07, IRON, MET, BALL)
	end)
end)

-- THE PENITENT'S SACKCLOTH (the Fallen Cellblock): a burlap robe to the ankle, patched and patched again, its cowl
-- fallen down the back, a rope belt knotted with its ends hanging and a string of wooden beads off it; a prayer board
-- on a cord at the breast; iron manacles, their chains snapped
bodyPiece("Sackcloth", function(char, key, folder, deco, size)
	local cw, ch, cd, hw, hh, hd = body(size)
	local c, h = on(deco, "Chest"), on(deco, "Hips")
	local BURLAP, BURLAP_DK, ROPE, IRON, WOOD, STITCH = C(150, 128, 92), C(116, 98, 70), C(170, 146, 100), C(64, 62, 60), C(96, 72, 50), C(60, 46, 32)
	local PATCH = { C(120, 104, 80), C(170, 150, 112), C(98, 90, 74), C(132, 96, 70) }
	c("Robe", V3(cw * 1.1, ch * 1.0, cd * 1.24), CF(), BURLAP, FAB)
	h("RobeWaist", V3(hw * 1.08, hh * 0.9, hd * 1.12), CF(0, 0.02, 0), BURLAP, FAB)
	local rng = Random.new(83)
	for i = 1, 7 do
		local zs = i <= 4 and -1 or 1
		local w, ht = rng:NextNumber(0.28, 0.42), rng:NextNumber(0.24, 0.36)
		local pcf = CF(rng:NextNumber(-0.35, 0.35) * cw, rng:NextNumber(-0.38, 0.3) * ch, zs * cd * 0.635) * ANG(0, 0, rng:NextNumber(-0.2, 0.2))
		c("Patch", V3(w, ht, 0.03), pcf, PATCH[i % 4 + 1], FAB)
		for _, cxy in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
			c("Stitch", V3(0.06, 0.06, 0.03), pcf * CF(cxy[1] * (w / 2 - 0.04), cxy[2] * (ht / 2 - 0.04), zs * 0.015), STITCH, FAB)
		end
	end
	-- the cowl, thrown back: a fold of burlap lying over the shoulders behind, its dark mouth turned up
	c("Cowl", V3(cw * 0.66, 0.5, 0.42), CF(0, ch / 2 - 0.1, cd * 0.62) * ANG(0.3, 0, 0), BURLAP_DK, FAB)
	c("CowlMouth", V3(cw * 0.5, 0.06, 0.26), CF(0, ch / 2 + 0.14, cd * 0.66) * ANG(0.3, 0, 0), C(40, 32, 24), FAB)
	c("Board", V3(0.55, 0.68, 0.07), CF(0, ch * 0.02, -cd * 0.66), WOOD, Enum.Material.Wood)
	for i = 0, 3 do
		c("Carving", V3(0.36 - (i % 2) * 0.1, 0.03, 0.02), CF(0, ch * 0.02 + 0.2 - i * 0.13, -cd * 0.66 - 0.045), C(40, 28, 20), Enum.Material.Wood)
	end
	for _, sx in ipairs({ -1, 1 }) do
		strand(c, "Cord", V3(sx * 0.24, ch * 0.02 + 0.32, -cd * 0.68), V3(sx * cw * 0.18, ch / 2 + 0.02, -cd * 0.3), 0.03, ROPE)
	end
	ring(h, "Rope", V3(0, hh * 0.3, 0), hw * 0.58, hd * 0.6, 24, 0, 2 * PI, Vector3.one * 0.15, ROPE, FAB, BALL)
	h("RopeKnot", Vector3.one * 0.24, CF(-hw * 0.2, hh * 0.3, -hd * 0.62), ROPE, FAB, BALL)
	for i = 0, 1 do
		local e = CF(-hw * 0.2 + i * 0.12 - 0.06, hh * 0.3 - 0.42, -hd * 0.64) * ANG(0, 0, (i - 0.5) * 0.15)
		h("RopeEnd", V3(0.1, 0.7, 0.1), e, ROPE, FAB)
		h("RopeFray", V3(0.14, 0.12, 0.14), e * CF(0, -0.38, 0), BURLAP_DK, FAB)
	end
	-- the beads: a string of them off the rope on the right, a little wooden cross at its end
	line(h, "Bead", V3(hw * 0.26, hh * 0.3 - 0.08, -hd * 0.64), V3(hw * 0.3, hh * 0.3 - 0.62, -hd * 0.66), 7, Vector3.one * 0.09, WOOD, Enum.Material.Wood, BALL)
	h("CrossUpright", V3(0.06, 0.24, 0.04), CF(hw * 0.3, hh * 0.3 - 0.78, -hd * 0.66), WOOD, Enum.Material.Wood)
	h("CrossArm", V3(0.16, 0.05, 0.04), CF(hw * 0.3, hh * 0.3 - 0.74, -hd * 0.66), WOOD, Enum.Material.Wood)
	skirt(deco, size, 2.0, BURLAP, BURLAP_DK, FAB)
	sleeves(deco, size, function(u, l, ua, la)
		u("Sleeve", V3(ua.X * 1.3, ua.Y * 0.95, ua.Z * 1.3), CF(), BURLAP, FAB)
		l("Sleeve", V3(la.X * 1.25, la.Y * 0.6, la.Z * 1.25), CF(0, la.Y * 0.2, 0), BURLAP_DK, FAB)
		l("Manacle", V3(0.22, la.X * 1.6, la.X * 1.6), CF(0, -la.Y * 0.32, 0) * UP, IRON, MET, CYL)
		l("ManacleRivet", Vector3.one * 0.09, CF(0, -la.Y * 0.32, -la.X * 0.82), C(40, 38, 36), MET, BALL)
		for j = 0, 2 do -- (the snapped chain, link through link down from the rivet)
			l("Link", V3(0.07, 0.16, 0.1), CF(0.02 * j, -la.Y * 0.32 - 0.1 - j * 0.13, -la.X * 0.82) * ANG(0, j * 1.57, 0), IRON, MET)
		end
	end)
end)

-- THE STEWARD'S TAILCOAT (the Hollow Mansion's foyer): black, satin lapels, a white shirtfront and cravat with a
-- garnet pin, a claret waistcoat and its watch chain, a dried rose in the buttonhole; long tails behind lined in
-- claret; white gloves, lace at the cuffs, and a serving cloth still over the left arm
bodyPiece("Tailcoat", function(char, key, folder, deco, size)
	local cw, ch, cd, hw, hh, hd = body(size)
	local c, h = on(deco, "Chest"), on(deco, "Hips")
	local BLACK, SATIN, WHITE, CLARET, BRASS, GOLD, ROSE = C(22, 20, 24), C(44, 42, 50), C(226, 222, 212), C(100, 22, 30), C(186, 146, 70), C(214, 176, 84), C(120, 24, 36)
	c("Coat", V3(cw * 1.1, ch * 0.98, cd * 1.24), CF(), BLACK, FAB)
	c("Shirt", V3(cw * 0.34, ch * 0.62, 0.04), CF(0, ch * 0.18, -cd * 0.63), WHITE, FAB)
	line(c, "Stud", V3(0, ch * 0.36, -cd * 0.655), V3(0, ch * 0.08, -cd * 0.655), 3, Vector3.one * 0.06, C(240, 240, 236), SM, BALL)
	c("Waistcoat", V3(cw * 0.62, ch * 0.44, 0.05), CF(0, -ch * 0.2, -cd * 0.645), CLARET, FAB)
	line(c, "WaistcoatButton", V3(0, -ch * 0.04, -cd * 0.68), V3(0, -ch * 0.38, -cd * 0.68), 4, Vector3.one * 0.07, BRASS, MET, BALL)
	for i = 0, 6 do
		local t = i / 6
		c("Chain", Vector3.one * 0.045, CF(-t * cw * 0.22, -ch * (0.15 + t * 0.07) - math.sin(t * PI) * 0.08, -cd * 0.68), GOLD, MET, BALL)
	end
	c("Watch", V3(0.04, 0.16, 0.16), CF(-cw * 0.24, -ch * 0.27, -cd * 0.68) * FACE, GOLD, MET, CYL)
	for _, sx in ipairs({ -1, 1 }) do
		c("Lapel", V3(cw * 0.17, ch * 0.55, 0.05), CF(sx * cw * 0.26, ch * 0.12, -cd * 0.645) * ANG(0, 0, sx * 0.32), SATIN, SM)
	end
	-- the buttonhole rose, on the right lapel
	c("Rose", Vector3.one * 0.13, CF(cw * 0.28, ch * 0.28, -cd * 0.7), ROSE, FAB, BALL)
	for j = 0, 4 do
		local a = j / 5 * 2 * PI
		c("Petal", Vector3.one * 0.08, CF(cw * 0.28 + math.cos(a) * 0.07, ch * 0.28 + math.sin(a) * 0.07, -cd * 0.69), ROSE:Lerp(C(0, 0, 0), 0.3), FAB, BALL)
	end
	c("RoseStem", V3(0.03, 0.18, 0.03), CF(cw * 0.3, ch * 0.2, -cd * 0.68) * ANG(0, 0, -0.3), C(50, 60, 36), FAB)
	c("PocketSquare", V3(0.16, 0.1, 0.03), CF(-cw * 0.32, ch * 0.3, -cd * 0.66), WHITE, FAB)
	c("Cravat", V3(0.3, 0.32, 0.1), CF(0, ch * 0.4, -cd * 0.66), WHITE, FAB)
	c("CravatKnot", Vector3.one * 0.16, CF(0, ch * 0.46, -cd * 0.7), WHITE, FAB, BALL)
	c("CravatPin", Vector3.one * 0.06, CF(0, ch * 0.36, -cd * 0.73), C(140, 30, 40), GLASS, BALL)
	c("Collar", V3(cw * 0.66, 0.24, cd * 1.16), CF(0, ch / 2 + 0.07, 0.03), BLACK, FAB)
	-- the tails: up under the coat's hem behind, against the hips, so nothing hangs loose
	for _, sx in ipairs({ -1, 1 }) do
		local tcf = CF(sx * hw * 0.22, -0.55, hd * 0.53) * ANG(-0.06, 0, sx * 0.04)
		h("Tail", V3(hw * 0.42, 1.9, 0.06), tcf, BLACK, FAB)
		h("TailLining", V3(0.06, 1.9, 0.065), tcf * CF(-sx * hw * 0.19, 0, 0), CLARET, FAB)
		h("TailButton", Vector3.one * 0.09, CF(sx * hw * 0.2, hh * 0.35, hd * 0.53 + 0.06), BRASS, MET, BALL)
		h("Flap", V3(hw * 0.36, 0.45, 0.05), CF(sx * hw * 0.34, -0.05, -hd * 0.53) * ANG(0.05, 0, -sx * 0.1), BLACK, FAB)
	end
	sleeves(deco, size, function(u, l, ua, la, sx)
		u("Sleeve", V3(ua.X * 1.25, ua.Y * 0.95, ua.Z * 1.25), CF(), BLACK, FAB)
		l("Sleeve", V3(la.X * 1.22, la.Y * 0.8, la.Z * 1.22), CF(0, la.Y * 0.08, 0), BLACK, FAB)
		l("Cuff", V3(la.X * 1.3, 0.12, la.Z * 1.3), CF(0, -la.Y * 0.36, 0), WHITE, FAB)
		ring(l, "Lace", V3(0, -la.Y * 0.44, 0), la.X * 0.6, la.Z * 0.6, 10, 0, 2 * PI, Vector3.one * 0.08, WHITE, FAB, BALL)
		l("Glove", V3(la.X * 1.18, 0.46, la.Z * 1.18), CF(0, -la.Y / 2 - 0.08, 0), WHITE, FAB) -- (over the fist)
		if sx < 0 then -- the serving cloth, draped over the forearm
			for _, side in ipairs({ -1, 1 }) do
				l("Towel", V3(0.05, 0.62, 0.5), CF(side * la.X * 0.56, -la.Y * 0.05, 0), WHITE, FAB)
				l("TowelStripe", V3(0.055, 0.06, 0.5), CF(side * la.X * 0.56, -la.Y * 0.05 - 0.22, 0), CLARET, FAB)
			end
			l("TowelFold", V3(la.X * 1.2, 0.06, 0.5), CF(0, -la.Y * 0.05 + 0.31, 0), WHITE, FAB)
		end
	end)
end)

-- THE NIGHTWATCH GREATCOAT (the Hollow Mansion's rear hall): charcoal, a ragged two-tier capelet, a stand-up collar
-- open at the throat; belts crossed over the breast with a silver buckle, vials of blood down one and a silver dagger
-- sheathed along the other; long tattered tails; gloves
bodyPiece("HunterCoat", function(char, key, folder, deco, size)
	local cw, ch, cd = body(size)
	local c = on(deco, "Chest")
	local COAT, COAT_DK, BELT, SILVER, VIAL, GLOVE, LINING = C(40, 38, 40), C(26, 25, 27), C(58, 40, 28), C(180, 184, 190), C(150, 20, 24), C(30, 24, 20), C(90, 20, 26)
	c("Coat", V3(cw * 1.14, ch * 1.0, cd * 1.3), CF(), COAT, FAB)
	c("Capelet", V3(cw * 1.42, 0.5, cd * 1.62), CF(0, ch / 2 - 0.22, 0), COAT_DK, FAB)
	c("Capelet2", V3(cw * 1.3, 0.3, cd * 1.52), CF(0, ch / 2 - 0.55, 0), COAT, FAB)
	ring(c, "CapeletFray", V3(0, ch / 2 - 0.74, 0), cw * 0.66, cd * 0.78, 20, 0, 2 * PI, V3(0.05, 0.22, 0.18), COAT_DK, FAB)
	-- the collar: up behind the neck and round the sides only, flared, lined in red - the throat left bare
	c("Collar", V3(cw * 0.72, 0.6, 0.1), CF(0, ch / 2 + 0.25, cd * 0.5) * ANG(0.2, 0, 0), COAT_DK, FAB)
	c("CollarLining", V3(cw * 0.66, 0.52, 0.02), CF(0, ch / 2 + 0.26, cd * 0.44) * ANG(0.2, 0, 0), LINING, FAB)
	for _, sx in ipairs({ -1, 1 }) do
		c("CollarSide", V3(0.1, 0.5, cd * 0.62), CF(sx * cw * 0.35, ch / 2 + 0.2, 0.16) * ANG(0, 0, -sx * 0.2), COAT_DK, FAB)
		for _, zs in ipairs({ -1, 1 }) do
			c("CrossBelt", V3(0.17, ch * 1.25, 0.05), CF(0, -0.05, zs * cd * 0.68) * ANG(0, 0, sx * 0.55), BELT, LEA)
		end
	end
	c("Buckle", V3(0.24, 0.24, 0.06), CF(0, -0.05, -cd * 0.72), SILVER, MET)
	for _, t in ipairs({ -0.62, -0.42, 0.36, 0.56 }) do
		local v = CF(0, -0.05, -cd * 0.72) * ANG(0, 0, 0.55) * CF(0, t, -0.04)
		c("Vial", V3(0.24, 0.11, 0.11), v * UP, VIAL, GLASS, CYL)
		c("VialCap", V3(0.05, 0.12, 0.12), v * CF(0, 0.14, 0) * UP, SILVER, MET, CYL)
	end
	-- the dagger, along the other belt below the buckle: sheath, guard, grip, pommel
	local d = CF(0, -0.05, -cd * 0.735) * ANG(0, 0, -0.55)
	c("Sheath", V3(0.12, 0.44, 0.06), d * CF(0, -0.66, 0), BELT:Lerp(C(0, 0, 0), 0.3), LEA)
	c("SheathTip", V3(0.13, 0.08, 0.065), d * CF(0, -0.88, 0), SILVER, MET)
	c("Guard", V3(0.3, 0.06, 0.07), d * CF(0, -0.43, 0), SILVER, MET)
	c("Grip", V3(0.07, 0.18, 0.07), d * CF(0, -0.31, 0), C(20, 18, 18), LEA)
	c("Pommel", Vector3.one * 0.1, d * CF(0, -0.2, 0), SILVER, MET, BALL)
	line(c, "Button", V3(cw * 0.2, ch * 0.3, -cd * 0.66), V3(cw * 0.2, -ch * 0.4, -cd * 0.66), 5, Vector3.one * 0.08, SILVER, MET, BALL)
	M.cloak(deco, size, COAT, COAT_DK, 19)
	sleeves(deco, size, function(u, l, ua, la, sx)
		u("Sleeve", V3(ua.X * 1.3, ua.Y * 0.95, ua.Z * 1.3), CF(), COAT, FAB)
		u("ArmStrap", V3(ua.X * 1.4, 0.08, ua.Z * 1.4), CF(0, ua.Y * 0.1, 0), BELT, LEA)
		u("StrapBuckle", Vector3.one * 0.08, CF(sx * ua.X * 0.7, ua.Y * 0.1, 0), SILVER, MET, BALL)
		l("Sleeve", V3(la.X * 1.25, la.Y * 0.6, la.Z * 1.25), CF(0, la.Y * 0.18, 0), COAT, FAB)
		l("Glove", V3(la.X * 1.3, la.Y * 0.4, la.Z * 1.3), CF(0, -la.Y * 0.3, 0), GLOVE, LEA)
		l("GloveCuff", V3(la.X * 1.6, 0.22, la.Z * 1.6), CF(0, -la.Y * 0.08, 0), GLOVE, LEA)
		l("CuffStrap", V3(la.X * 1.64, 0.05, la.Z * 1.64), CF(0, -la.Y * 0.08, 0), SILVER, MET)
	end)
end)

-- THE RAGPICKER'S PATCHWORK (the far township): rags over rags in every dun colour, patches stitched on all sides, a
-- scrap of fur on one shoulder, a string of found things across the chest; a rope belt with sacks and a tin cup tied
-- to it, a bundle of sticks strapped across the back, tatters to the feet
bodyPiece("Patchwork", function(char, key, folder, deco, size)
	local cw, ch, cd, hw, hh, hd = body(size)
	local c, h = on(deco, "Chest"), on(deco, "Hips")
	local RAG = { C(96, 84, 64), C(120, 96, 70), C(78, 72, 60), C(110, 60, 44), C(70, 80, 66), C(140, 126, 96) }
	local STITCH, BONE, BRASS, WOOD, TIN = C(40, 32, 24), C(214, 204, 176), C(176, 140, 66), C(92, 70, 46), C(150, 150, 146)
	local rng = Random.new(97)
	c("Rags", V3(cw * 1.16, ch * 1.0, cd * 1.32), CF(), RAG[1], FAB)
	for i = 1, 12 do
		local side = i % 4
		local w, ht = rng:NextNumber(0.25, 0.45), rng:NextNumber(0.2, 0.4)
		local y, col = rng:NextNumber(-0.4, 0.38) * ch, RAG[rng:NextInteger(2, #RAG)]
		if side < 2 then
			local zs = side == 0 and -1 or 1
			local pcf = CF(rng:NextNumber(-0.38, 0.38) * cw, y, zs * cd * 0.665) * ANG(0, 0, rng:NextNumber(-0.3, 0.3))
			c("Patch", V3(w, ht, 0.03), pcf, col, FAB)
			line(c, "Stitch", (pcf * CF(-w / 2 + 0.05, ht / 2 - 0.03, zs * 0.015)).Position, (pcf * CF(w / 2 - 0.05, ht / 2 - 0.03, zs * 0.015)).Position, 4, V3(0.03, 0.07, 0.03), STITCH, FAB)
		else
			c("Patch", V3(0.03, ht, w * 0.6), CF((side == 2 and -1 or 1) * cw * 0.585, y, rng:NextNumber(-0.25, 0.25) * cd) * ANG(rng:NextNumber(-0.3, 0.3), 0, 0), col, FAB)
		end
	end
	c("Fur", V3(cw * 0.5, 0.3, cd * 1.4), CF(-cw * 0.3, ch / 2 + 0.02, 0), C(110, 96, 80), FAB)
	for _ = 1, 7 do
		c("Tuft", Vector3.one * rng:NextNumber(0.14, 0.22), CF(-cw * 0.3 + rng:NextNumber(-0.3, 0.3), ch / 2 + 0.14, rng:NextNumber(-0.35, 0.35)), C(130, 114, 96):Lerp(C(80, 70, 60), rng:NextNumber()), FAB, BALL)
	end
	local s0, s1 = V3(cw * 0.32, ch * 0.45, -cd * 0.68), V3(-cw * 0.4, -ch * 0.42, -cd * 0.68)
	strand(c, "String", s0, s1, 0.03, STITCH)
	for j = 1, 6 do
		local at = CF(s0:Lerp(s1, j / 7) + V3(0, -0.05, -0.03))
		if j % 3 == 1 then
			c("Bone", V3(0.06, 0.22, 0.06), at * ANG(0, 0, 0.4), BONE, SM)
		elseif j % 3 == 2 then
			c("Bell", Vector3.one * 0.12, at, BRASS, MET, BALL)
		else
			c("Button", V3(0.03, 0.14, 0.14), at * FACE, RAG[4], SM, CYL)
		end
	end
	-- the bundle on the back: three sticks lashed together on the slant, a strap over the right shoulder
	local b = CF(0, -0.05, cd * 0.66 + 0.05) * ANG(0, 0, -0.6)
	for k = -1, 1 do
		c("Stick", V3(0.1, ch * 1.15 - math.abs(k) * 0.2, 0.1), b * CF(k * 0.11, k * 0.05, 0), WOOD:Lerp(C(60, 46, 30), (k + 1) / 3), Enum.Material.Wood)
	end
	for _, y in ipairs({ -0.4, 0.4 }) do
		c("BundleCord", V3(0.42, 0.06, 0.2), b * CF(0, y, 0.02), STITCH, FAB)
	end
	local st = { V3(cw * 0.28, ch * 0.42, cd * 0.69), V3(cw * 0.28, ch / 2 + 0.02, cd * 0.4), V3(cw * 0.28, ch / 2 + 0.02, -cd * 0.4), V3(cw * 0.28, ch * 0.3, -cd * 0.69) }
	for i = 1, 3 do -- (from the bundle's top, over the shoulder, down the front)
		strand(c, "BundleStrap", st[i], st[i + 1], 0.1, STITCH)
	end
	-- the rope belt, and what hangs off it: sacks tied at the sides and behind, a tin cup in front
	h("RopeBelt", V3(hw * 1.12, 0.14, hd * 1.16), CF(0, hh * 0.3, 0), STITCH, FAB)
	for i, s in ipairs({ { hw * 0.6, -0.1 }, { -hw * 0.6, 0.15 }, { 0.1, hd * 0.7 } }) do
		h("Sack", Vector3.one * 0.42, CF(s[1], 0.0, s[2]), RAG[i + 1], FAB, BALL)
		h("SackTie", Vector3.one * 0.12, CF(s[1], hh * 0.25, s[2]), STITCH, FAB, BALL)
	end
	h("Cup", V3(0.22, 0.2, 0.2), CF(hw * 0.25, hh * 0.15, -hd * 0.58 - 0.1) * UP, TIN, MET, CYL)
	h("CupRim", V3(0.03, 0.22, 0.22), CF(hw * 0.25, hh * 0.15 + 0.1, -hd * 0.58 - 0.1) * UP, TIN:Lerp(C(255, 255, 255), 0.2), MET, CYL)
	M.cloak(deco, size, RAG[2], RAG[3], 31)
	sleeves(deco, size, function(u, l, ua, la)
		u("Wrap", V3(ua.X * 1.3, ua.Y * 0.9, ua.Z * 1.3), CF(), RAG[3], FAB)
		for j = 0, 2 do
			l("Wrap", V3(la.X * 1.35, 0.12, la.Z * 1.35), CF(0, la.Y * (0.25 - j * 0.25), 0) * ANG(0, 0, 0.25), RAG[j + 4], FAB)
		end
	end)
end)

-- THE MIRE-DIVER'S OILSKIN (the Rot Below): a waxed smock, glossy and green-black, its hood rolled at the nape, bone
-- toggles down the front; braces down to rubber waders; a brass air-tank on the back with its hose over the shoulder
-- to a mouthpiece; a rope across the body and coiled at the hip, a lantern on a strap
bodyPiece("Oilskin", function(char, key, folder, deco, size)
	local cw, ch, cd, hw, hh, hd = body(size)
	local c, h = on(deco, "Chest"), on(deco, "Hips")
	local OIL, OIL_DK, BONE, ROPE, RUBBER, BRASS, SLIME = C(52, 62, 44), C(36, 44, 30), C(214, 200, 170), C(150, 124, 80), C(28, 30, 26), C(176, 140, 66), C(140, 190, 60)
	local sm = c("Smock", V3(cw * 1.14, ch * 1.0, cd * 1.3), CF(), OIL, SM)
	if sm then
		sm.Reflectance = 0.12
	end
	c("Hood", V3(cw * 0.8, 0.42, 0.42), CF(0, ch / 2 + 0.02, cd * 0.55), OIL_DK, SM, CYL)
	for _, sx in ipairs({ -1, 1 }) do
		for _, zs in ipairs({ -1, 1 }) do
			c("Seam", V3(0.05, ch, 0.05), CF(sx * cw * 0.57, 0, zs * cd * 0.65), OIL_DK, SM) -- (down the smock's corners)
			c("Brace", V3(0.14, ch * 1.05, 0.04), CF(sx * cw * 0.25, 0, zs * cd * 0.67), RUBBER, LEA)
		end
		c("BraceClip", V3(0.16, 0.12, 0.05), CF(sx * cw * 0.25, ch * 0.35, -cd * 0.7), BRASS, MET)
	end
	for i = 0, 3 do
		local y = ch * 0.32 - i * ch * 0.22
		c("Toggle", V3(0.24, 0.07, 0.07), CF(0, y, -cd * 0.69), BONE, SM)
		c("Loop", V3(0.12, 0.04, 0.04), CF(0.12, y, -cd * 0.68), OIL_DK, SM)
	end
	line(c, "Rope", V3(cw * 0.35, ch * 0.48, -cd * 0.7), V3(-cw * 0.38, -ch * 0.45, -cd * 0.7), 11, Vector3.one * 0.14, ROPE, FAB, BALL)
	-- the air-tank, between the braces on the back, banded, a dome and valve on top; its hose up over the right shoulder
	local tz = cd * 0.65 + 0.31
	c("AirTank", V3(1.1, 0.62, 0.62), CF(0, -0.05, tz) * UP, BRASS, MET, CYL)
	for _, y in ipairs({ -0.4, 0.3 }) do
		c("TankBand", V3(0.08, 0.66, 0.66), CF(0, y, tz) * UP, RUBBER, LEA, CYL)
	end
	c("TankDome", Vector3.one * 0.6, CF(0, 0.47, tz), BRASS, MET, BALL)
	c("TankValve", V3(0.16, 0.14, 0.14), CF(0.1, 0.78, tz) * UP, C(70, 68, 66), MET, CYL)
	local hose = { V3(0.1, 0.8, tz), V3(0.45, ch / 2 + 0.1, cd * 0.5), V3(0.55, ch / 2 + 0.1, -cd * 0.62), V3(0.6, 0.45, -cd * 0.72) }
	for i = 1, #hose - 1 do
		strand(c, "Hose", hose[i], hose[i + 1], 0.1, RUBBER, SM)
		c("HoseJoint", Vector3.one * 0.12, CF(hose[i + 1]), RUBBER, SM, BALL)
	end
	c("Mouthpiece", V3(0.16, 0.16, 0.16), CF(hose[#hose] + V3(0, -0.08, 0)), BRASS, MET, BALL)
	-- the rope's coil at the left hip, against the smock's hem
	local cx = -hw * 0.63 - 0.07
	h("Coil", V3(0.14, 0.6, 0.6), CF(cx, -0.1, 0), ROPE, FAB, CYL)
	h("CoilHole", V3(0.15, 0.3, 0.3), CF(cx, -0.1, 0), OIL_DK, SM, CYL)
	h("CoilWrap", V3(0.18, 0.08, 0.22), CF(cx, 0.18, 0), C(110, 90, 60), FAB)
	h("SmockHem", V3(hw * 1.26, hh * 1.1, hd * 1.38), CF(0, -0.05, 0), OIL, SM)
	h("HemBand", V3(hw * 1.3, 0.08, hd * 1.42), CF(0, -hh * 0.55, 0), OIL_DK, SM)
	-- the lantern at the right hip, hung on a strap from the hem's top
	local lx, lz = hw * 0.63 + 0.13, -0.12
	local glass = h("LanternGlass", V3(0.26, 0.34, 0.26), CF(lx, -0.32, lz), C(210, 230, 120), NEON)
	for _, o in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
		h("LanternPost", V3(0.05, 0.42, 0.05), CF(lx + o[1] * 0.14, -0.32, lz + o[2] * 0.14), C(40, 38, 34), MET)
	end
	h("LanternCap", V3(0.34, 0.06, 0.34), CF(lx, -0.1, lz), C(40, 38, 34), MET)
	h("LanternHandle", V3(0.04, 0.2, 0.2), CF(lx, 0.0, lz), C(40, 38, 34), MET, CYL)
	strand(h, "LanternStrap", V3(hw * 0.63, hh * 0.4, lz), V3(lx, 0.08, lz), 0.05, RUBBER, LEA)
	if glass then
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = C(200, 230, 120), 10, 0.8
		l.Parent = glass
	end
	for _, s in ipairs({ "R", "L" }) do
		local th, sh = size(s .. "Thigh"), size(s .. "Shin")
		local t, n = on(deco, s .. "Thigh"), on(deco, s .. "Shin")
		t("Wader", V3(th.X * 1.3, th.Y * 0.98, th.Z * 1.3), CF(), RUBBER, SM)
		t("WaderStrap", V3(th.X * 1.36, 0.08, th.Z * 1.36), CF(0, th.Y * 0.42, 0), C(50, 40, 30), LEA)
		t("WaderBuckle", V3(0.12, 0.12, 0.05), CF(0, th.Y * 0.42, -th.Z * 0.7), BRASS, MET)
		n("Wader", V3(sh.X * 1.35, sh.Y * 0.98, sh.Z * 1.35), CF(), RUBBER, SM)
		n("KneePatch", V3(0.24, 0.24, 0.03), CF(0, sh.Y * 0.32, -sh.Z * 0.69), OIL_DK, SM)
		n("Slime", Vector3.one * 0.1, CF(sh.X * 0.3, -sh.Y * 0.2, -sh.Z * 0.66), SLIME, GLASS, BALL)
	end
	sleeves(deco, size, function(u, l, ua, la)
		u("Sleeve", V3(ua.X * 1.3, ua.Y * 0.95, ua.Z * 1.3), CF(), OIL, SM)
		l("Sleeve", V3(la.X * 1.28, la.Y * 0.85, la.Z * 1.28), CF(0, la.Y * 0.05, 0), OIL, SM)
		l("CuffStrap", V3(la.X * 1.34, 0.08, la.Z * 1.34), CF(0, -la.Y * 0.3, 0), RUBBER, LEA)
	end)
end)

-- THE CROWNED CHAMPION'S HARNESS (the Crowned Colosseum): a linen tunic hemmed in red under crossed straps hung with
-- bronze phalerae; a manica of bronze lames down the sword arm, a shoulder guard, gold rings on the other; a studded
-- balteus, leather strips tipped in bronze round the hips, a gladius in its scabbard on the left; a red half-cloak
-- pinned at the left shoulder; greaves
bodyPiece("ChampionHarness", function(char, key, folder, deco, size)
	local cw, ch, cd, hw, hh, hd = body(size)
	local c, h = on(deco, "Chest"), on(deco, "Hips")
	local LINEN, RED, LEATHER, BRONZE, BRONZE_DK, GOLD = C(214, 204, 180), C(150, 22, 24), C(92, 58, 34), C(170, 120, 58), C(120, 82, 40), C(214, 176, 84)
	c("Tunic", V3(cw * 1.06, ch * 0.95, cd * 1.14), CF(0, -0.02, 0), LINEN, FAB)
	c("TunicTrim", V3(cw * 1.08, 0.1, cd * 1.16), CF(0, -ch * 0.45, 0), RED, FAB)
	for _, zs in ipairs({ -1, 1 }) do
		for _, sx in ipairs({ -1, 1 }) do
			c("Strap", V3(0.2, ch * 1.3, 0.05), CF(0, 0, zs * cd * 0.6) * ANG(0, 0, sx * 0.48), LEATHER, LEA)
		end
	end
	for _, pt in ipairs({ { 0, 0 }, { 0.15, 0.28 }, { -0.15, 0.28 }, { 0.15, -0.28 }, { -0.15, -0.28 } }) do
		c("Phalera", V3(0.05, 0.3, 0.3), CF(pt[1], pt[2], -cd * 0.63) * FACE, BRONZE, MET, CYL)
		c("PhaleraBoss", Vector3.one * 0.12, CF(pt[1], pt[2], -cd * 0.66), GOLD, MET, BALL)
	end
	c("Cloak", V3(cw * 0.55, ch * 1.25, 0.06), CF(-cw * 0.28, -ch * 0.12, cd * 0.6) * ANG(-0.05, 0, 0), RED, FAB)
	c("CloakDrape", V3(cw * 0.5, 0.3, cd * 1.3), CF(-cw * 0.28, ch * 0.48, 0), RED, FAB)
	c("Brooch", V3(0.05, 0.24, 0.24), CF(-cw * 0.28, ch * 0.4, -cd * 0.67) * FACE, GOLD, MET, CYL)
	line(c, "Fringe", V3(-cw * 0.5, -ch * 0.76, cd * 0.63), V3(-cw * 0.06, -ch * 0.76, cd * 0.63), 6, V3(0.06, 0.14, 0.04), GOLD, FAB)
	h("Balteus", V3(hw * 1.25, 0.34, hd * 1.32), CF(0, hh * 0.3, 0), LEATHER, LEA)
	line(h, "Stud", V3(-hw * 0.5, hh * 0.3, -hd * 0.68), V3(hw * 0.5, hh * 0.3, -hd * 0.68), 7, Vector3.one * 0.1, BRONZE, MET, BALL)
	ring(h, "Pteryx", V3(0, -hh * 0.3, 0), hw * 0.62, hd * 0.68, 16, 0, 2 * PI, V3(0.05, 0.72, 0.2), LEATHER, LEA)
	ring(h, "PteryxTip", V3(0, -hh * 0.3 - 0.38, 0), hw * 0.63, hd * 0.69, 16, 0, 2 * PI, V3(0.06, 0.08, 0.2), BRONZE, MET)
	-- the gladius, on the left: a frog off the balteus, the scabbard against the strips, its hilt up by the belt
	local gx = -hw * 0.62 - 0.07
	h("Frog", V3(0.12, 0.26, 0.2), CF(gx + 0.02, hh * 0.25, -0.05), LEATHER, LEA)
	local g = CF(gx, -0.1, -0.05) * ANG(0.12, 0, 0)
	h("Scabbard", V3(0.07, 0.95, 0.16), g * CF(0, -0.35, 0), C(60, 30, 20), LEA)
	h("Chape", V3(0.08, 0.1, 0.17), g * CF(0, -0.82, 0), BRONZE, MET)
	h("Throat", V3(0.08, 0.08, 0.17), g * CF(0, 0.1, 0), BRONZE, MET)
	h("Guard", V3(0.1, 0.07, 0.3), g * CF(0, 0.17, 0), BRONZE, MET)
	h("Grip", V3(0.08, 0.2, 0.08), g * CF(0, 0.3, 0), C(40, 26, 18), LEA)
	h("Pommel", Vector3.one * 0.14, g * CF(0, 0.44, 0), GOLD, MET, BALL)
	sleeves(deco, size, function(u, l, ua, la, sx)
		if sx > 0 then -- the manica, down the sword arm
			for i = 0, 5 do
				u("Lame", V3(0.17, ua.X * 1.55, ua.X * 1.55), CF(0, ua.Y * (0.38 - i * 0.15), 0) * UP, i % 2 == 0 and BRONZE or BRONZE_DK, MET, CYL)
			end
			for i = 0, 4 do
				l("Lame", V3(0.17, la.X * 1.5, la.X * 1.5), CF(0, la.Y * (0.3 - i * 0.15), 0) * UP, i % 2 == 0 and BRONZE or BRONZE_DK, MET, CYL)
			end
			u("Shoulder", V3(ua.X * 2.3, 0.16, ua.Z * 2.1), CF(0.05, ua.Y / 2 + 0.04, 0) * ANG(0, 0, -0.2), BRONZE, MET)
			u("ShoulderRim", V3(ua.X * 2.35, 0.05, ua.Z * 2.15), CF(0.05, ua.Y / 2 + 0.04, 0) * ANG(0, 0, -0.2) * CF(0, 0.09, 0), GOLD, MET)
		else
			for _, y in ipairs({ 0.18, 0.02 }) do -- armillae: gold rings won in the sand
				u("Armilla", V3(0.1, ua.X * 1.18, ua.X * 1.18), CF(0, ua.Y * y, 0) * UP, GOLD, MET, CYL)
			end
			l("Wrap", V3(la.X * 1.35, la.Y * 0.35, la.Z * 1.35), CF(0, -la.Y * 0.3, 0), LEATHER, LEA)
			for _, y in ipairs({ -0.18, -0.42 }) do
				l("WrapBand", V3(la.X * 1.4, 0.05, la.Z * 1.4), CF(0, la.Y * y, 0), BRONZE, MET)
			end
		end
	end)
	for _, s in ipairs({ "R", "L" }) do
		local sh = size(s .. "Shin")
		local n = on(deco, s .. "Shin")
		n("Greave", V3(sh.X * 1.3, sh.Y * 0.78, 0.12), CF(0, -0.05, -sh.Z * 0.6), BRONZE, MET)
		n("GreaveRidge", V3(0.05, sh.Y * 0.78, 0.04), CF(0, -0.05, -sh.Z * 0.6 - 0.07), GOLD, MET)
		n("KneeBoss", Vector3.one * 0.22, CF(0, sh.Y * 0.38, -sh.Z * 0.66), BRONZE_DK, MET, BALL)
		n("GreaveStrap", V3(sh.X * 1.32, 0.07, sh.Z * 1.32), CF(0, -sh.Y * 0.25, 0), LEATHER, LEA)
	end
end)

-- THE EMBER COURT DOUBLET (Pyralis's east wing): crimson, slashed to show gold beneath, gold buttons, a white ruff;
-- a chain of office over the shoulders with a sun hung from it; a black sash edged in gold; a short black cape on the
-- left shoulder embroidered with flames; puffed and slashed sleeves and trunk hose
bodyPiece("EmberDoublet", function(char, key, folder, deco, size)
	local cw, ch, cd, hw = body(size)
	local c, h = on(deco, "Chest"), on(deco, "Hips")
	local CRIMSON, CRIMSON_DK, GOLD, RUFF, BLACK, EMBER = C(120, 22, 20), C(84, 14, 14), C(206, 166, 74), C(232, 226, 212), C(22, 18, 18), C(255, 120, 40)
	c("Doublet", V3(cw * 1.1, ch * 0.98, cd * 1.24), CF(), CRIMSON, FAB)
	for r = 0, 2 do
		for k = 0, 3 do
			c("Slash", V3(0.05, 0.26, 0.02), CF(-cw * 0.36 + k * cw * 0.24, ch * 0.25 - r * ch * 0.27, -cd * 0.625), GOLD, FAB)
		end
	end
	line(c, "Button", V3(0, ch * 0.42, -cd * 0.64), V3(0, -ch * 0.42, -cd * 0.64), 7, Vector3.one * 0.08, GOLD, MET, BALL)
	c("Waist", V3(cw * 1.12, 0.12, cd * 1.26), CF(0, -ch * 0.47, 0), GOLD, FAB)
	for row = 0, 1 do
		ring(c, "Ruff", V3(0, ch / 2 + 0.1 + row * 0.08, 0), cw * 0.34 + row * 0.04, cd * 0.62 + row * 0.04, 20, row * 0.15, 2 * PI + row * 0.15, Vector3.one * 0.2, RUFF, FAB, BALL)
	end
	local sash = CF(0, 0, -cd * 0.66) * ANG(0, 0, 0.55)
	c("Sash", V3(0.26, ch * 1.3, 0.05), sash, BLACK, FAB)
	for _, sx in ipairs({ -1, 1 }) do
		c("SashEdge", V3(0.03, ch * 1.3, 0.055), sash * CF(sx * 0.13, 0, 0), GOLD, FAB)
	end
	c("SashKnot", Vector3.one * 0.24, CF(-cw * 0.42, -ch * 0.4, -cd * 0.64), BLACK, FAB, BALL)
	-- the chain of office: links sagging across the breast from shoulder to shoulder (and shallower behind), a sun at its foot
	for _, zs in ipairs({ -1, 1 }) do
		local sag = zs < 0 and 0.38 or 0.18
		for i = 0, 16 do
			local t = i / 16
			c("Link", Vector3.one * 0.09, CF((-0.38 + 0.76 * t) * cw, ch * (0.48 - math.sin(t * PI) * sag), zs * cd * 0.66), GOLD, MET, BALL)
		end
	end
	local sy = ch * (0.48 - 0.38) - 0.16
	c("Sun", V3(0.05, 0.28, 0.28), CF(0, sy, -cd * 0.68) * FACE, GOLD, MET, CYL)
	c("SunHeart", Vector3.one * 0.1, CF(0, sy, -cd * 0.71), EMBER, NEON, BALL)
	for j = 0, 7 do
		local a = j / 8 * 2 * PI
		c("SunRay", V3(0.04, 0.12, 0.04), CF(math.cos(a) * 0.19, sy + math.sin(a) * 0.19, -cd * 0.68) * ANG(0, 0, a - PI / 2), GOLD, MET)
	end
	c("Cape", V3(cw * 0.62, ch * 0.85, 0.06), CF(-cw * 0.22, ch * 0.05, cd * 0.63), BLACK, FAB)
	c("CapeShoulder", V3(cw * 0.5, 0.2, cd * 1.3), CF(-cw * 0.3, ch * 0.5, 0), BLACK, FAB)
	c("CapeHem", V3(cw * 0.62, 0.06, 0.065), CF(-cw * 0.22, -ch * 0.37, cd * 0.63), GOLD, FAB)
	for j = 0, 6 do
		local x = -cw * 0.5 + j * cw * 0.093
		c("Flame", V3(0.07, 0.2, 0.02), CF(x, -ch * 0.27 + (j % 2) * 0.06, cd * 0.665) * ANG(0, 0, j % 2 == 0 and 0.35 or -0.35), EMBER, NEON)
		c("Flame", V3(0.05, 0.12, 0.02), CF(x + 0.04, -ch * 0.12 + (j % 2) * 0.05, cd * 0.665) * ANG(0, 0, j % 2 == 0 and -0.3 or 0.3), GOLD, NEON)
	end
	for _, sx in ipairs({ -1, 1 }) do
		h("Hose", Vector3.one * hw * 0.62, CF(sx * hw * 0.25, -0.15, 0), CRIMSON, FAB, BALL)
		-- (short panes, set in a little: their ends stay on the ball's curve)
		ring(h, "Pane", V3(sx * hw * 0.25, -0.15, 0), hw * 0.295, hw * 0.295, 8, 0, 2 * PI, V3(0.03, hw * 0.24, 0.07), GOLD, FAB)
	end
	sleeves(deco, size, function(u, l, ua, la, sx)
		u("Puff", Vector3.one * ua.X * 2.0, CF(0, ua.Y * 0.3, 0), CRIMSON, FAB, BALL)
		ring(u, "PuffSlash", V3(0, ua.Y * 0.3, 0), ua.X, ua.X, 8, 0, 2 * PI, V3(0.03, 0.3, 0.06), GOLD, FAB)
		u("Sleeve", V3(ua.X * 1.2, ua.Y * 0.6, ua.Z * 1.2), CF(0, -ua.Y * 0.2, 0), CRIMSON_DK, FAB)
		l("Sleeve", V3(la.X * 1.2, la.Y * 0.9, la.Z * 1.2), CF(), CRIMSON_DK, FAB)
		line(l, "SleeveButton", V3(sx * la.X * 0.62, la.Y * 0.3, 0), V3(sx * la.X * 0.62, -la.Y * 0.35, 0), 4, Vector3.one * 0.06, GOLD, MET, BALL)
		l("Cuff", V3(la.X * 1.4, 0.12, la.Z * 1.4), CF(0, -la.Y * 0.44, 0), RUFF, FAB)
	end)
end)

-- THE HEADSMAN'S JERKIN (Pyralis's cellars, where the Executioner keeps watch): studded black leather, a stitched
-- mantle, straps crossed through an iron ring; a spiked pauldron on the axe arm; a heavy apron under the belt, stained;
-- banded bracers; a whetstone in a pouch at the hip, a chain
bodyPiece("HeadsmanJerkin", function(char, key, folder, deco, size)
	local cw, ch, cd, hw, hh, hd = body(size)
	local c, h = on(deco, "Chest"), on(deco, "Hips")
	local LEATHER, LEATHER_LT, IRON, APRON, STAIN, STRAP = C(26, 22, 22), C(46, 38, 34), C(70, 68, 66), C(64, 44, 30), C(70, 12, 12), C(14, 12, 12)
	c("Jerkin", V3(cw * 1.14, ch * 1.0, cd * 1.3), CF(), LEATHER, LEA)
	for r = 0, 2 do
		line(c, "Stud", V3(-cw * 0.45, ch * 0.4 - r * 0.18, -cd * 0.66), V3(cw * 0.45, ch * 0.4 - r * 0.18, -cd * 0.66), 7, Vector3.one * 0.08, IRON, MET, BALL)
	end
	c("Mantle", V3(cw * 1.36, 0.45, cd * 1.6), CF(0, ch / 2 - 0.1, 0), LEATHER_LT, LEA)
	ring(c, "MantleStitch", V3(0, ch / 2 - 0.3, 0), cw * 0.68, cd * 0.8, 22, 0, 2 * PI, V3(0.02, 0.04, 0.08), C(150, 120, 90), FAB)
	for _, sx in ipairs({ -1, 1 }) do
		c("Strap", V3(0.18, ch * 1.1, 0.05), CF(0, -0.1, -cd * 0.68) * ANG(0, 0, sx * 0.5), STRAP, LEA)
	end
	c("StrapRing", V3(0.06, 0.3, 0.3), CF(0, -0.1, -cd * 0.72) * FACE, IRON, MET, CYL)
	h("Belt", V3(hw * 1.25, 0.22, hd * 1.34), CF(0, hh * 0.35, 0), STRAP, LEA)
	h("Buckle", V3(0.28, 0.24, 0.06), CF(0, hh * 0.35, -hd * 0.7), IRON, MET)
	-- the apron: its top tucked up under the belt, hanging close in front of the hips
	local apron = CF(0, -0.85, -hd * 0.6) * ANG(0.05, 0, 0)
	h("Apron", V3(hw * 0.95, 2.2, 0.08), apron, APRON, LEA)
	for _, sx in ipairs({ -1, 1 }) do
		for j = 0, 7 do
			h("ApronStitch", V3(0.03, 0.08, 0.03), apron * CF(sx * (hw * 0.475 - 0.05), 0.9 - j * 0.26, -0.045), C(140, 110, 80), FAB)
		end
	end
	local rng = Random.new(13)
	for _ = 1, 5 do
		local r = rng:NextNumber(0.12, 0.26)
		h("Stain", V3(r, r * 0.8, 0.02), apron * CF(rng:NextNumber(-0.4, 0.4) * hw, rng:NextNumber(-0.8, 0.6), -0.045) * ANG(0, 0, rng:NextNumber(0, PI)), STAIN, SM)
	end
	-- the pouch, hung at the belt on the right against the hip, the whetstone poking out of it
	local px = hw / 2 + 0.15
	h("Pouch", V3(0.3, 0.4, 0.22), CF(px, 0.0, -0.05), LEATHER_LT, LEA)
	h("Whetstone", V3(0.12, 0.2, 0.16), CF(px, 0.27, -0.05), C(120, 118, 112), Enum.Material.Slate)
	h("PouchFlap", V3(0.32, 0.12, 0.24), CF(px, 0.17, -0.05), LEATHER, LEA)
	line(h, "Link", V3(-hw * 0.62, hh * 0.2, -0.1), V3(-hw * 0.66, -0.6, -0.1), 6, V3(0.06, 0.14, 0.1), IRON, MET)
	sleeves(deco, size, function(u, l, ua, la, sx)
		u("Sleeve", V3(ua.X * 1.3, ua.Y * 0.6, ua.Z * 1.3), CF(0, ua.Y * 0.2, 0), LEATHER, LEA)
		if sx > 0 then -- the pauldron: a plate of black iron off the shoulder, three spikes up off it
			local pf = CF(0.08, ua.Y / 2 + 0.02, 0) * ANG(0, 0, -0.3)
			u("Pauldron", V3(ua.X * 2.0, 0.18, ua.Z * 1.9), pf, C(34, 32, 32), MET)
			u("PauldronRim", V3(ua.X * 2.05, 0.06, ua.Z * 1.95), pf * CF(0, -0.1, 0), IRON, MET)
			for j = -1, 1 do
				u("Spike", V3(0.3 - math.abs(j) * 0.08, 0.09, 0.09), pf * CF(j * 0.17, 0.09 + 0.14 - math.abs(j) * 0.04, 0) * UP, IRON, MET, CYL)
			end
		end
		l("Bracer", V3(la.X * 1.4, la.Y * 0.6, la.Z * 1.4), CF(0, -la.Y * 0.15, 0), LEATHER_LT, LEA)
		for j = 0, 2 do
			l("Band", V3(la.X * 1.46, 0.06, la.Z * 1.46), CF(0, la.Y * (0.1 - j * 0.18), 0), IRON, MET)
		end
	end)
end)

return M
