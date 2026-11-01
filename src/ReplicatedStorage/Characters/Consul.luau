--!nonstrict
-- THE CONSUL OF DECAY: the daughter's right hand, waiting in the Hollow Mansion's attic. Skinny, gangly and
-- four-armed: a long sword in each upper hand, a spell catalyst in each lower one (a censer on a staff, a ring of
-- bone round a dark orb). He lies in pieces about the arena until someone climbs up: his head, on the dais,
-- notices them and turns to look; it rises to where it belongs while the rest of him crawls to it across the
-- floor and knits together; and he unfolds into his stance. The fog over the stair's head holds you in until he
-- falls or you do. (No attacks yet: he holds his stance and turns to watch you.) Tuning: Config.Consul.
--
-- EVERYTHING ABOUT THIS CHARACTER IS IN THIS ONE FILE (same layout as Castellan.lua):
--   M.Proportions / M.Poses   body shape and its full-body poses
--   M.Colors / M.Look         the rig's dress: the head, ribs, rags, the two swords
--   M.init(Core) and below    the lower arms and catalysts, the assembly, the seal (server only)
local M = {}
M.Kind = "Consul"
M.Proportions = { girth = 0.62, arm = 1.65, hunch = 0.14, torso = 1.3 }
M.IdlePose = "XStance"
M.Poses = {
	-- what the pieces come together into (the server poses its own joints to this before laying them out, so the rig
	-- matches them when it's shown): up on bent legs, arched back, face to the ceiling, the swords curled up over his
	-- head towards each other (the lower arms, ARMS.Reach, curled up beneath them)
	XRest = { drop = 0.5, lean = -0.2, twist = 0.1, side = 0.05, head = -0.35, la1 = 2.8, la2 = 1.0, la3 = -0.25, lel = 1.4, ra1 = 2.8, ra2 = -1.0, ra3 = 0.25, rel = 1.4, footR = 0.35, footL = -0.35, spread = 0.6, breathe = 0, freeL = 0 },
	-- whole, and slumped forward over himself, head lolling
	XUnfold = { drop = 1.2, lean = 0.95, side = 0.2, head = 0.7, la1 = -0.1, la3 = -0.2, lel = 0.1, ra1 = -0.1, ra3 = 0.25, rel = 0.1, footR = 0.3, footL = -0.4, spread = 0.2, breathe = 0.5, freeL = 0 },
	-- jerked upright, too far: thrown back, arms flung wide
	XLurch = { drop = 0.3, lean = -0.35, twist = -0.4, side = -0.15, head = -0.5, la1 = 1.2, la3 = -1.4, lel = 1.2, ra1 = 2.6, ra3 = 0.9, rel = 0.4, footR = 0.6, footL = -0.7, spread = 0.5, freeL = 0, breathe = 4 },
	-- the slash: the right sword drawn up and back, his body coiled away from you...
	XSlashWind = { drop = 0.8, lean = -0.15, twist = -0.55, side = 0.1, head = -0.2, la1 = 0.8, la2 = 0.3, la3 = -1.25, lel = 1.4, ra1 = 2.9, ra2 = -0.5, ra3 = 1.1, rel = 0.5, footR = -0.6, footL = 0.5, spread = 0.5, freeL = 0, breathe = 2 },
	-- ...and brought down across him, lunging into it
	XSlash = { drop = 1.0, lean = 0.7, twist = 0.75, side = -0.1, head = 0.1, la1 = 0.8, la2 = 0.3, la3 = -1.25, lel = 1.4, ra1 = 0.1, ra2 = 0.9, ra3 = -0.2, rel = 0.1, footR = 0.9, footL = -0.8, spread = 0.55, freeL = 0, breathe = 2 },
	-- the uppercut after it: the left sword dropped low behind him on his left, turned into it...
	XUpperWind = { drop = 1.1, lean = 0.75, twist = 0.9, side = 0.1, head = 0.1, la1 = -0.4, la2 = -0.4, la3 = -0.6, lel = 0.2, ra1 = 0.1, ra2 = 0.9, ra3 = -0.2, rel = 0.1, footR = 0.9, footL = -0.8, spread = 0.55, freeL = 0, breathe = 2 },
	-- ...and ripped up across him, rising with it
	XUpper = { drop = 0.4, lean = -0.35, twist = -0.6, side = -0.1, head = -0.4, la1 = 2.8, la2 = 0.3, la3 = -0.6, lel = 0.3, ra1 = 0.1, ra2 = 0.9, ra3 = -0.2, rel = 0.1, footR = 0.6, footL = -0.5, spread = 0.5, freeL = 0, breathe = 2 },
	-- the wheel: the broadsword lifted back over his left shoulder for the back limb to take...
	XOffer = { drop = 0.7, lean = 0.1, twist = 0.3, side = 0.1, head = -0.1, la1 = 2.7, la2 = 0.8, la3 = -0.5, lel = 1.9, ra1 = 2.1, ra2 = -0.3, ra3 = 0.75, rel = 0.85, footR = 0.6, footL = -0.6, spread = 0.5, freeL = 0, breathe = 2 },
	-- ...and, held up high on it, shown off: chest out, arms flung wide, his face up to it
	XShow = { drop = 0.3, lean = -0.35, twist = 0, side = 0, head = -0.55, la1 = 1.3, la2 = 0, la3 = -1.1, lel = 0.5, ra1 = 1.3, ra2 = 0, ra3 = 1.1, rel = 0.5, footR = 0.3, footL = -0.3, spread = 0.5, freeL = 0, breathe = 3 },
	-- the beam: drawn up to his full height, arched back with his face to the ceiling and every arm thrown up and wide
	XCast = { drop = 0, lean = -0.6, twist = 0, side = 0, head = -0.8, la1 = 2.3, la2 = 0.5, la3 = -0.7, lel = 0.4, ra1 = 2.3, ra2 = -0.5, ra3 = 0.7, rel = 0.4, footR = 0.2, footL = -0.2, spread = 0.7, freeL = 0, breathe = 4 },
	-- the blast: folded in on himself, every arm clutched against his middle, head down over it
	XClutch = { drop = 0.9, lean = 0.9, twist = 0, side = 0, head = 0.4, la1 = 0.8, la2 = 0.9, la3 = -1.25, lel = 1.9, ra1 = 0.8, ra2 = -0.9, ra3 = 1.25, rel = 1.9, footR = 0.5, footL = -0.5, spread = 0.4, freeL = 0, breathe = 6 },
	-- his stance: sunk low and wide, twisted, head cocked, one sword high behind him and one low out in front
	-- on the move (the crawl itself is M.Gait: it takes over his limbs and body, so this is little more than its name)
	XCrawl = { drop = 0, lean = 0.15, twist = 0, side = 0, head = -0.2, la1 = 1.9, la2 = 0.5, la3 = -1.7, lel = 0.5, ra1 = 1.6, ra2 = -0.5, ra3 = 1.6, rel = 0.6, freeL = 0, breathe = 5 },
	XStance = { drop = 0.95, lean = 0.55, twist = 0.45, side = 0.18, head = -0.25, look = -0.3, la1 = 0.8, la2 = 0.3, la3 = -1.25, lel = 1.4, ra1 = 2.1, ra2 = -0.3, ra3 = 0.75, rel = 0.85, footR = 0.9, footL = -1.0, spread = 0.55, freeL = 0, breathe = 3 },
	-- risen again (his second phase's cutscene): drawn up straight and tall, chest out, chin up, the right sword held
	-- point-up before his face and the left down at his side
	XRighteous = { drop = 0, lean = -0.2, twist = 0, side = 0, head = -0.35, la1 = 0.3, la2 = 0.2, la3 = -0.35, lel = 0.2, ra1 = 2.3, ra2 = -0.2, ra3 = 0.15, rel = 1.3, footR = 0.25, footL = -0.25, spread = 0.35, freeL = 0, breathe = 1.5 },
}
M.Colors = { skin = Color3.fromRGB(196, 188, 170), torso = Color3.fromRGB(22, 19, 22), legs = Color3.fromRGB(20, 17, 19), arms = Color3.fromRGB(24, 20, 23) }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT, D, s = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT, k.D, k.s
	local cw, ch, cd, hw, hd, aw, lw, la = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la
	local flesh, bone, boneDk, rag, vein = rgb(22, 19, 22), rgb(204, 196, 176), rgb(140, 132, 114), rgb(30, 22, 32), rgb(92, 112, 44)
	for _, pn in ipairs({ "Chest", "Hips", "RUpperArm", "LUpperArm", "RLowerArm", "LLowerArm", "RThigh", "LThigh", "RShin", "LShin", "RFoot", "LFoot" }) do
		parts[pn].Material = MAT.Slate
	end
	-- THE HEAD: a long pale mask split down its middle, one sick eye in the split, a hanging jaw, a fan of black
	-- needles standing out behind it, black hair down his back
	parts.Head.Transparency = 1 -- (the head's own block stood out of the back of the cage; the mask is his head)
	deco("Head", "Mask", V(0.95, 2.1, 0.8), at(0, 0.45, -0.12), bone, MAT.Marble)
	deco("Head", "MaskBrow", V(1.05, 0.22, 0.86), at(0, 0.88, -0.12), boneDk, MAT.Marble)
	deco("Head", "Split", V(0.08, 1.95, 0.05), at(0, 0.42, -0.54), rgb(6, 4, 6), MAT.SmoothPlastic)
	deco("Head", "Eye", V(0.2, 0.42, 0.1), at(0, 0.62, -0.55), rgb(196, 226, 86), MAT.Neon)
	deco("Head", "Jaw", V(0.66, 0.6, 0.6), at(0, -0.62, -0.25) * CFrame.Angles(0.35, 0, 0), boneDk, MAT.Marble)
	for i = -4, 4 do
		deco("Head", "Needle", V(0.09, 2.7 - math.abs(i) * 0.16, 0.09), at(0, 0.9, 0.3) * CFrame.Angles(-0.4, 0, i * 0.27) * CFrame.new(0, (1.35 - math.abs(i) * 0.08) * s, 0), rgb(10, 8, 10), MAT.Metal)
	end
	for _, x in ipairs({ -0.35, -0.12, 0.12, 0.35 }) do
		deco("Head", "Hair", V(0.12, 2.6, 0.05), at(x, -0.8, 0.5) * CFrame.Angles(0.12, 0, x * 0.3), rgb(12, 10, 12), MAT.Fabric)
	end
	-- a lantern cage of black iron hugging the mask (two front bars frame the eye), and a curved bar binding
	-- the needles' outer arc
	local iron = rgb(26, 22, 20)
	local function bar(a, b, t) -- a straight bar between two unscaled points on the head
		deco("Head", "CageBar", V(t, t, (b - a).Magnitude), CFrame.lookAt(a * s, b * s) * CFrame.new(0, 0, -(b - a).Magnitude * s / 2), iron, MAT.Metal)
	end
	local X, Z, C, Z0 = 0.6, 0.5, 0.12, -0.12
	local ring = { { -X + C, -Z }, { X - C, -Z }, { X, -Z + C }, { X, Z - C }, { X - C, Z }, { -X + C, Z }, { -X, Z - C }, { -X, -Z + C } }
	for i, p in ipairs(ring) do
		local q = ring[i % #ring + 1]
		local n = math.max(1, math.round(math.sqrt((q[1] - p[1]) ^ 2 + (q[2] - p[2]) ^ 2) / 0.13))
		for j = 0, n - 1 do -- close-set bars all round, but a window left for the eye
			local x, z = p[1] + (q[1] - p[1]) * j / n, p[2] + (q[2] - p[2]) * j / n
			if not (z < -Z + 0.01 and math.abs(x) < 0.18) then
				bar(Vector3.new(x, -0.55, Z0 + z), Vector3.new(x, 1.6, Z0 + z), 0.06)
			end
		end
		for k = 0, 8 do -- hoops all the way up, bottom to top bar; across the face they break for the eye
			local y = -0.55 + k * 2.15 / 8
			local a, c = Vector3.new(p[1], y, Z0 + p[2]), Vector3.new(q[1], y, Z0 + q[2])
			if i == 1 and y > 0.3 and y < 0.95 then
				bar(a, Vector3.new(-0.18, y, Z0 + p[2]), 0.07)
				bar(Vector3.new(0.18, y, Z0 + p[2]), c, 0.07)
			else
				bar(a, c, 0.07)
			end
		end
	end
	local function tip(i) -- needle i's very end (the needles' own placement, unscaled)
		return Vector3.new(0, 0.9, 0.3) + (CFrame.Angles(-0.4, 0, i * 0.27) * Vector3.new(0, 2.7 - math.abs(i) * 0.16, 0))
	end
	for i = -4, 4 do
		deco("Head", "CageRivet", V(0.14, 0.14, 0.14), CFrame.new(tip(i) * s), iron, MAT.Metal, Enum.PartType.Ball)
		if i < 4 then
			bar(tip(i), tip(i + 1), 0.09)
		end
	end
	-- THE BODY: no box of a chest but an open ribcage, bone ribs curving round from a knotted spine to a sternum,
	-- a shoulder yoke of collarbones, and in the hollow a heart of the darkest red with rot running out from it to the ribs
	local function link(pn, name, a, b, t, color, mat) -- a bar between two unscaled points on part pn
		deco(pn, name, V(t, t, (b - a).Magnitude + t), CFrame.lookAt(a * s, b * s) * CFrame.new(0, 0, -(b - a).Magnitude * s / 2), color, mat)
	end
	parts.Chest.Transparency = 1
	deco("Chest", "Gut", V(cw * 0.3, ch * 0.95, cd * 0.3), at(0, -ch * 0.02, cd * 0.22), flesh, MAT.Slate)
	for i = 0, 7 do
		deco("Chest", "Spine", V(0.3, 0.2, 0.26), at(0, ch * 0.46 - i * ch * 0.13, cd * 0.42), boneDk, MAT.Marble)
	end
	deco("Chest", "Sternum", V(0.18, ch * 0.5, 0.12), at(0, ch * 0.16, -cd * 0.5), bone, MAT.Marble)
	local ribEnds = {}
	for i = 0, 5 do
		local y = ch * (0.36 - i * 0.13)
		local wide = 0.82 + 0.28 * math.sin((i + 1) / 7 * math.pi) -- (fullest mid-chest, drawn in at the bottom)
		local rx, rz = cw / 2 * wide, cd / 2 * 1.05
		for _, sx in ipairs({ -1, 1 }) do
			local prev
			for j = 0, 4 do
				local th = 0.45 + j / 4 * (math.pi - 0.75) -- (from beside the sternum round to beside the spine)
				local p = Vector3.new(sx * rx * math.sin(th), y - 0.32 * (1 - j / 4), -rz * math.cos(th))
				if prev then
					link("Chest", "Rib", prev, p, 0.12, j == 1 and boneDk or bone, MAT.Marble)
				end
				prev = p
				if j == 2 then
					table.insert(ribEnds, p)
				end
			end
		end
	end
	local heart = Vector3.new(0, ch * 0.1, -cd * 0.05)
	deco("Chest", "Heart", V(0.6, 0.75, 0.55), CFrame.new(heart * s), rgb(58, 6, 10), MAT.Glass, Enum.PartType.Ball)
	for i, e in ipairs(ribEnds) do
		if i % 2 == 1 then
			link("Chest", "Vein", heart, e * 0.92, 0.05, vein, MAT.Neon)
		end
	end
	local shY = (D.chestH / 2 - D.shoulderDown) / s
	for _, sx in ipairs({ -1, 1 }) do
		local sh = Vector3.new(sx * D.shoulderX / s, shY, 0)
		link("Chest", "Collarbone", Vector3.new(0, ch * 0.42, -cd * 0.48), sh, 0.14, bone, MAT.Marble)
		link("Chest", "Scapula", Vector3.new(0, ch * 0.4, cd * 0.42), sh, 0.12, boneDk, MAT.Marble)
		deco("Chest", "ShoulderKnob", V(0.5, 0.5, 0.5), CFrame.new(sh * s), flesh, MAT.Slate, Enum.PartType.Ball)
		deco("Chest", "Spur", V(0.12, 1.1, 0.12), at(sx * cw * 0.42, ch / 2 + 0.15, 0.1) * CFrame.Angles(0.3, 0, -sx * 0.7), bone, MAT.Marble)
	end
	-- rags hanging from his hips, long and uneven, all the way round
	for i, l in ipairs({ 3.4, 2.6, 3.9, 2.2, 3.1, 4.2, 2.8, 3.6 }) do
		local a = (i - 0.5) / 8 * math.pi * 2
		deco("Hips", "Rag", V(0.42, l, 0.05), at(math.sin(a) * (hw / 2 + 0.06), -l / 2 + 0.25, math.cos(a) * (hd / 2 + 0.06)) * CFrame.Angles(0, a, 0), rag, MAT.Fabric)
	end
	-- his upper left arm half as long again, both bones. The animation (Puppeteer) only ever rewrites a joint's C0,
	-- so the bones are lengthened through their C1s: the upper bone is drawn as a longer sleeve hung off its shoulder
	-- (its own part, hidden, keeps the elbow where the animation puts it), and the forearm simply grows
	local LONG = 1.5
	local ua = D.upperArm / s
	local sh, el, fore = parts.Chest.LShoulder, parts.LUpperArm.LElbow, parts.LLowerArm
	sh.C1 = CFrame.new(0, D.upperArm * (LONG - 0.5), 0)
	fore.Size = Vector3.new(fore.Size.X, D.lowerArm * LONG, fore.Size.Z)
	el.C1 = CFrame.new(0, fore.Size.Y / 2, 0)
	-- (and moved there now, as RigBuilder places every part: the decorations weld to wherever the bone is when
	-- the model enters the world, before the joints have pulled it to its new place)
	parts.LUpperArm.CFrame = parts.Chest.CFrame * sh.C0 * sh.C1:Inverse()
	fore.CFrame = parts.LUpperArm.CFrame * el.C0 * el.C1:Inverse()
	parts.LUpperArm.Transparency = 1
	deco("LUpperArm", "LongUpperArm", V(aw, ua * LONG, aw), at(0, ua * (LONG - 1) / 2, 0), M.Colors.arms, MAT.Slate)
	for _, f in ipairs(fore.Parent:GetChildren()) do -- (the shared fist was set at the old length, and in the wrong colour)
		local w = f.Name == "Fist" and f:FindFirstChildWhichIsA("WeldConstraint")
		if w and (w.Part0 == fore or w.Part0 == parts.RLowerArm) then
			f:Destroy()
		end
	end
	-- long arms: knobbed elbows and fists in his own black, claws past the fists; and a long sword in each hand,
	-- held out ahead of the fist
	for _, n in ipairs({ "R", "L" }) do
		local la = n == "L" and la * LONG or la
		deco(n .. "LowerArm", "Elbow", V(aw * 1.5, 0.3, aw * 1.5), at(0, la / 2 - 0.08, 0.04), M.Colors.arms, MAT.Slate)
		deco(n .. "LowerArm", "Fist", V(aw * 0.95, 0.42, aw * 1.0), at(0, -la / 2 - 0.08, 0), M.Colors.arms, MAT.Slate)
		for _, dx in ipairs({ -0.12, 0, 0.12 }) do
			deco(n .. "LowerArm", "Claw", V(0.06, 0.7, 0.06), at(dx, -la / 2 - 0.5, -0.12) * CFrame.Angles(-0.35, 0, dx), bone, MAT.Marble)
		end
		local hilt = at(0, -la / 2 - 0.3, 0) * CFrame.Angles(1.2, 0, 0) -- (from the fist, its blade runs along -Y: forward and a little down)
		local function along(y)
			return hilt * CFrame.new(0, -y * s, 0)
		end
		deco(n .. "LowerArm", "SwordGrip", V(0.14, 0.8, 0.14), along(0), rgb(30, 24, 20), MAT.Fabric)
		deco(n .. "LowerArm", "SwordGuard", V(0.8, 0.12, 0.22), along(0.45), rgb(40, 36, 34), MAT.Metal)
		-- the left: a dark broadsword, straight and wide, a fuller down it and ridged edges (dark for now: LitColor is
		-- the purple they light up with, kept for his second phase: litBlade), from the same hand as his purple staff
		if n == "L" then
			deco(n .. "LowerArm", "SwordGuard", V(1.3, 0.2, 0.3), along(0.45), rgb(24, 20, 26), MAT.Metal)
			for i = 1, 6 do
				local y = 0.55 + (i - 0.5) * 0.75
				local w = i == 6 and 0.55 or 0.85
				local piece = deco(n .. "LowerArm", "SwordBlade", V(0.12, 0.79, w), along(y), rgb(20, 17, 22), MAT.Metal)
				if i == 1 or i == 6 then
					piece:SetAttribute(i == 1 and "TrailBase" or "TrailTip", n)
				end
				deco(n .. "LowerArm", "SwordFuller", V(0.14, 0.75, 0.1), along(y), rgb(14, 12, 16), MAT.Metal):SetAttribute("LitColor", rgb(140, 70, 190))
				for _, e in ipairs({ -1, 1 }) do
					deco(n .. "LowerArm", "SwordEdge", V(0.05, 0.77, 0.05), along(y) * CFrame.new(0, 0, e * w / 2 * s), rgb(30, 26, 32), MAT.Metal):SetAttribute("LitColor", rgb(110, 60, 150))
				end
			end
			deco(n .. "LowerArm", "SwordPoint", V(0.12, 0.5, 0.4), along(0.55 + 4.5 + 0.2) * CFrame.Angles(math.pi / 4, 0, 0), rgb(20, 17, 22), MAT.Metal)
		else
			-- the right: dark iron in a curve (a run of short pieces, each bent a little further), a saw of teeth
			-- along its outer edge and a hook here and there off its back
			local cf, seg = along(0.45), 0.62
			for i = 1, 7 do
				local w = 0.4 - i * 0.035
				cf = cf * CFrame.Angles(0.085, 0, 0) * CFrame.new(0, -seg / 2 * s, 0)
				local piece = deco(n .. "LowerArm", "SwordBlade", V(0.08, seg + 0.04, w), cf, rgb(26, 23, 28), MAT.Metal)
				if i == 1 or i == 7 then -- (the blade's ends, for the trail it leaves in a cut: spawn)
					piece:SetAttribute(i == 1 and "TrailBase" or "TrailTip", n)
				end
				for _, dy in ipairs({ -0.16, 0.16 }) do
					deco(n .. "LowerArm", "SwordTooth", V(0.07, 0.2, 0.2), cf * CFrame.new(0, dy * s, w / 2 * s) * CFrame.Angles(math.pi / 4 + 0.25, 0, 0), rgb(18, 13, 15), MAT.CorrodedMetal)
				end
				if i % 2 == 0 then
					deco(n .. "LowerArm", "SwordHook", V(0.07, 0.34, 0.08), cf * CFrame.new(0, 0, -w / 2 * s) * CFrame.Angles(0.7, 0, 0) * CFrame.new(0, -0.1 * s, -0.06 * s), rgb(34, 28, 30), MAT.Metal)
				end
				cf = cf * CFrame.new(0, -seg / 2 * s, 0)
			end
		end
		deco(n .. "Thigh", "Rag", V(lw * 1.1, 1.2, lw * 1.1), at(0, 0.1, 0), rag, MAT.Fabric)
		deco(n .. "Shin", "KneeSpur", V(0.1, 0.8, 0.1), at(0, D.shin / s / 2, -0.2) * CFrame.Angles(0.6, 0, 0), bone, MAT.Marble)
	end
end

---------------------------------------------------------------------------
-- server: the attic
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- client: HOW HE MOVES (the Puppeteer calls this after posing him, every frame). He doesn't walk, he crawls on
-- everything he has: his legs, all four arms, the two long arms between them and the six little ones. Body low
-- and pitched forward, so his head leads on its neck; every limb plants its tip on the floor (two-bone IK to the
-- spot) and holds it there while he goes over it, and only steps - lifted high, flung ahead - when it's
-- stretched too far behind. A few step at a time, never a limb and its twin together: the rest are always down.
-- Standing (his stance) the Puppeteer has him, and the little arms only twitch.
---------------------------------------------------------------------------
local function lerpC0(m, cf, w)
	if m and m.Parent then
		m.C0 = w >= 0.999 and cf or m.C0:Lerp(cf, w)
	end
end
-- two bones a, b from pivot P to reach T, the joint between them bent towards pole: the first bone's direction,
-- the joint, the second bone's direction, and the normal of the plane they bend in
local function ik(P, T, a, b, pole)
	local v = T - P
	local dir = v.Magnitude > 1e-3 and v.Unit or -Vector3.yAxis
	local d = math.clamp(v.Magnitude, math.abs(a - b) + 0.05, a + b - 0.02)
	local perp = pole - dir * pole:Dot(dir)
	perp = perp.Magnitude > 1e-3 and perp.Unit or dir:Cross(Vector3.xAxis).Unit
	local cosA = math.clamp((a * a + d * d - b * b) / (2 * a * d), -1, 1)
	local u = dir * cosA + perp * math.sqrt(1 - cosA * cosA)
	local E = P + u * a
	local l = (P + dir * d - E).Unit
	local n = u:Cross(l)
	n = n.Magnitude > 1e-3 and n.Unit or perp:Cross(dir).Unit
	return u, E, l, n
end
-- the rig's own limbs: its two joints, how far the tip reaches past the second joint (x scale), where it plants
-- (his frame: x right, -z ahead), and its twin
local MOTOR_LIMBS = {
	{ "RHip", "RKnee", 0.3, Vector3.new(0.45, 0, 0.9), "LHip" },
	{ "LHip", "LKnee", 0.3, Vector3.new(-0.45, 0, 0.9), "RHip" },
	{ "RShoulder", "RElbow", 0.4, Vector3.new(0.5, 0, -0.85), "LShoulder" },
	{ "LShoulder", "LElbow", 0.4, Vector3.new(-0.5, 0, -0.85), "RShoulder" },
}
local MAX_STEP = 6
local crawlRay = RaycastParams.new()
crawlRay.FilterType = Enum.RaycastFilterType.Exclude

function M.AnimRest(model, st, now)
	local g = st.gait
	if not g then
		return
	end
	for _, L in ipairs(g.limbs) do
		if L.w1 then
			L.w1.C0, L.w2.C0 = L.w1:GetAttribute("RestC0") or L.w1.C0, L.w2:GetAttribute("RestC0") or L.w2.C0
		end
		L.F, L.step = nil, nil
	end
	for _, jw in ipairs(g.idle) do
		jw.C0 = jw:GetAttribute("RestC0") or jw.C0
	end
	for _, sw in ipairs(g.spin) do
		sw.C0 = sw:GetAttribute("SpinAt") * CFrame.Angles(0, now * sw:GetAttribute("Spin"), 0) * sw:GetAttribute("SpinOff")
	end
	for _, snd in ipairs(g.sounds) do
		snd.Volume = 0
	end
end

function M.Gait(model, st, dt, now)
	local root = model:FindFirstChild("HumanoidRootPart")
	local D, J, joints = st.D, st.J, st.joints
	if not (root and joints.Root and joints.Waist and joints.Neck) or dt <= 0 then
		return
	end
	local s = D.s
	local g = st.gait
	if not g then
		g = { w = 0, spd = 0, vel = Vector3.zero, last = root.Position, moved = -1, twitch = 0, idle = {}, rest = {}, limbs = {}, byName = {}, spin = {} }
		for _, w in ipairs(model:GetDescendants()) do
			if w:IsA("Weld") and w:GetAttribute("Spin") then
				table.insert(g.spin, w)
			end
		end
		-- the sound of him crawling: two layered loops, here on this client, as loud as he's moving
		local cc = require(game:GetService("ReplicatedStorage"):WaitForChild("Config")).Consul
		g.sounds, g.crawlVol = {}, cc.CrawlVolume or 0.7
		for _, id in ipairs(cc.CrawlSounds or {}) do
			local snd = Instance.new("Sound")
			snd.SoundId, snd.Looped, snd.Volume, snd.RollOffMaxDistance = id, true, 0, 140
			snd.Parent = root
			snd:Play()
			table.insert(g.sounds, snd)
		end
		for _, ml in ipairs(MOTOR_LIMBS) do
			table.insert(g.limbs, { name = ml[1], j1 = ml[1], j2 = ml[2], tip = ml[3] * s, dir = ml[4].Unit, pair = ml[5] })
		end
		-- the welded limbs: each "CrawlerJoint" pair (Limb, Seg 1/2; Pivot, Len, Dir, Pair on the first)
		local segs = {}
		for _, w in ipairs(model:GetDescendants()) do
			if w:IsA("Motor6D") and w:GetAttribute("Limb") then
				segs[w:GetAttribute("Limb")] = segs[w:GetAttribute("Limb")] or {}
				segs[w:GetAttribute("Limb")][w:GetAttribute("Seg")] = w
				if w:GetAttribute("Idle") then
					table.insert(g.idle, w)
				end
			end
		end
		for id, pair in pairs(segs) do
			local w1, w2 = pair[1], pair[2]
			if w1 and w2 and w1:GetAttribute("Dir") then
				local high = w1:GetAttribute("High") -- (the back limbs: elbows kept up over his head)
				table.insert(g.limbs, { name = id, w1 = w1, w2 = w2, tip = 0.3 * s, dir = w1:GetAttribute("Dir").Unit, pair = w1:GetAttribute("Pair"), high = high })
			end
		end
		for i, L in ipairs(g.limbs) do
			g.byName[L.name] = L
			L.slot = i -- (its place round the ball, when he rolls)
		end
		st.gait = g
	end

	-- how fast he's going, from where the server has put him
	local delta = root.Position - g.last
	g.last = root.Position
	local v = Vector3.new(delta.X, 0, delta.Z) / dt
	if v.Magnitude > 60 then
		v = Vector3.zero -- (a teleport)
	end
	g.vel = g.vel:Lerp(v, 1 - math.exp(-dt * 6))
	if g.vel.Magnitude > 1.5 * s then
		g.moved = now
	end
	-- crawling while he's on the move (and a moment after, so a pause in a surge doesn't stand him up)
	-- (an attack, the server's "Busy", stands him up at once: its pose has the sword arm; his stilt, "Stilt", is all
	-- planted limbs: the crawl at once, and not a foot moved while the server lifts him on them and topples him)
	-- (and his wheel, "Ball", every limb a spoke of it, as long as he rolls; "HeldBy": the limb the server is moving)
	local stilt, ball, heldBy = model:GetAttribute("Stilt"), model:GetAttribute("Ball"), model:GetAttribute("HeldBy")
	if model:GetAttribute("Cutscene") then -- (his cutscenes: the server's poses only, whatever else is set)
		stilt, ball, heldBy = nil, nil, nil
		if g.w > 0 then
			-- cut in on him mid-crawl: every limb the crawl had put straight back on the server's own rest (RestC0, as he
			-- was built), and that kept as the rest to come back to. (Not g.rest: that's only ever what they last stood
			-- in - e.g. his intro's star, the back forearms up - and blending to it leaves them stuck off, for good.)
			for _, L in ipairs(g.limbs) do
				if L.w1 and not L.w1:GetAttribute("Idle") then
					for _, jw in ipairs({ L.w1, L.w2 }) do
						local r = jw:GetAttribute("RestC0")
						if r then
							jw.C0, g.rest[jw] = r, r
						end
					end
				end
				L.F, L.step = nil, nil
			end
			g.w = 0
		end
	elseif ball then
		g.w += (1 - g.w) * (1 - math.exp(-dt * 14))
	elseif stilt then
		g.w += (1 - g.w) * (1 - math.exp(-dt * 8))
	elseif model:GetAttribute("Busy") then
		g.w += (0 - g.w) * (1 - math.exp(-dt * 12))
	else
		g.w += (((now - g.moved) < 0.8 and 1 or 0) - g.w) * (1 - math.exp(-dt * 3))
	end
	local w = g.w * g.w * (3 - 2 * g.w)
	local loud = stilt and 0 or ball and 1 or math.clamp(g.vel.Magnitude / (6 * s), 0, 1)
	for _, snd in ipairs(g.sounds) do
		snd.Volume += (g.crawlVol * loud - snd.Volume) * (1 - math.exp(-dt * 8))
		snd.PlaybackSpeed = 0.9 + 0.25 * loud
	end

	-- the catalysts' hoops and shards, turning about their heads
	for _, sw in ipairs(g.spin) do
		sw.C0 = sw:GetAttribute("SpinAt") * CFrame.Angles(0, now * sw:GetAttribute("Spin"), 0) * sw:GetAttribute("SpinOff")
	end
	-- the little arms' own life: never quite still, now and then a twitch (what the crawl blends from)
	local idleC0 = {}
	for i, jw in ipairs(g.idle) do
		local pivot, len, low = jw:GetAttribute("Pivot"), jw:GetAttribute("Len"), jw:GetAttribute("Seg") == 2
		local k = i * 1.73
		local jerk = math.noise(now * 6, k)
		jerk = math.abs(jerk) > 0.3 and jerk * 0.9 or 0
		local rot = low and CFrame.Angles(0.7 + 0.6 * math.noise(now * 1.8, k + 9) + jerk, 0, 0)
			or CFrame.Angles(0.6 * math.noise(now * 1.5, k) + jerk, 0, 0.5 * math.noise(now * 1.2, k + 5))
		idleC0[jw] = pivot * rot * CFrame.new(0, -len / 2, 0)
	end
	if w < 0.001 then
		for jw, cf in pairs(idleC0) do
			jw.C0 = cf
		end
		for _, L in ipairs(g.limbs) do -- (feet picked up; and the server's own set of the welded arms kept, to come back to)
			L.F, L.step = nil, nil
			if L.w1 and not L.w1:GetAttribute("Idle") then
				g.rest[L.w1], g.rest[L.w2] = L.w1.C0, L.w2.C0
			end
		end
		return
	end

	-- THE BODY: low, pitched forward, swaying; the head up on its neck, on you. (Rolling, curled up into his own middle:
	-- hips tucked under, chest folded down over them, head down into it)
	local sway = math.noise(now * 1.7, 11)
	if ball then
		lerpC0(joints.Root, J.Root.C0 * CFrame.Angles(-0.7, 0, 0), w)
		lerpC0(joints.Waist, J.Waist.C0 * CFrame.Angles(-1.0, 0, 0), w)
		lerpC0(joints.Neck, J.Neck.C0 * CFrame.Angles(-0.5, 0, 0), w)
	else
		lerpC0(joints.Root, CFrame.new(0, D.hipsY - D.rootY - 1.3 * s, 0.5 * s) * CFrame.Angles(-0.5 + 0.15 * sway, 0.25 * math.noise(now * 1.1, 12), 0.2 * math.noise(now * 1.4, 13)), w)
		lerpC0(joints.Waist, J.Waist.C0 * CFrame.Angles(-0.75, 0.3 * math.noise(now * 0.9, 14), 0.15 * sway), w)
		lerpC0(joints.Neck, CFrame.new(0, D.chestH / 2 + 0.35 * s, -0.25 * s) * CFrame.Angles(1.2 + 0.2 * math.noise(now * 4, 1), 0.3 * math.noise(now * 4, 2), 0.35 * math.noise(now * 3, 3)), w)
	end
	local rootCF = root.CFrame
	local world = {}
	world.Hips = rootCF * joints.Root.C0 * joints.Root.C1:Inverse()
	world.Chest = world.Hips * joints.Waist.C0 * joints.Waist.C1:Inverse()
	local skip = { model, workspace:FindFirstChild("Enemies") }
	for _, pl in ipairs(game:GetService("Players"):GetPlayers()) do
		table.insert(skip, pl.Character)
	end
	crawlRay.FilterDescendantsInstances = skip
	-- his face held on a point the server gives ("FaceAt": you, through his stilt), however he's pitched
	local faceAt = model:GetAttribute("FaceAt")
	if faceAt then
		local neck = world.Chest * joints.Neck.C0.Position
		if (faceAt - neck).Magnitude > 0.5 then
			-- (and in the wheel, the head bobs a little with each turn, nodding on its neck)
			local bob = ball and CFrame.Angles(0.12 * math.sin((model:GetAttribute("BallTh") or 0) * 2) + 0.05 * math.noise(now * 5, 77), 0, 0.06 * math.sin((model:GetAttribute("BallTh") or 0) * 2 + 1)) or CFrame.identity
			joints.Neck.C0 = world.Chest:Inverse() * CFrame.lookAt(neck, faceAt) * bob
		end
	end
	local floorHit = workspace:Raycast(root.Position, Vector3.new(0, -12 * s, 0), crawlRay)
	local floorY = floorHit and floorHit.Position.Y or root.Position.Y - D.rootY
	local function groundAt(p)
		local hit = workspace:Raycast(Vector3.new(p.X, floorY + 4 * s, p.Z), Vector3.new(0, -8 * s, 0), crawlRay)
		return Vector3.new(p.X, hit and hit.Position.Y or floorY, p.Z)
	end

	local stepping = 0
	for _, L in ipairs(g.limbs) do
		if L.step then
			stepping += 1
		end
	end
	local up = rootCF.UpVector
	for _, L in ipairs(g.limbs) do -- (legs first: the thigh-arms hang off where they've just been put)
		if L.name == heldBy then
			continue
		end
		local lw = w
		-- where it hangs from, and how far it reaches
		local base, P, a, b
		local m1, m2 = L.j1 and joints[L.j1], L.j2 and joints[L.j2]
		if L.j1 then
			if not (m1 and m2) then
				continue
			end
			base = world[J[L.j1].p0]
			P = base * J[L.j1].C0.Position
			a = m1.C1.Position.Y - J[L.j2].C0.Position.Y
			b = 2 * m2.C1.Position.Y + L.tip
		else
			base = world[L.w1.Part0.Name]
			if not base then
				continue
			end
			P = base * L.w1:GetAttribute("Pivot").Position
			a = L.w1:GetAttribute("Len")
			b = L.w2:GetAttribute("Len") + L.tip
		end
		local reach = a + b
		local out = rootCF:VectorToWorldSpace(L.dir)
		local T, radial
		if ball then
			-- a spoke of the ball: each limb has its own heading on a sphere round him (spread over all of it, sides and
			-- front and back, not one flat wheel), and the turn carries that heading over and round his middle. The tip
			-- doesn't sit on the heading, it's a weight on a spring after it, in the world: it lags the turn, whips out
			-- past it, rebounds, is stopped by the end of the limb and by the floor, and drags where it's planted - so the
			-- momentum is in the limbs, not just the angle. (The limb with the sword - "BallLead" - is exact: the thing
			-- the whole ball goes round after)
			local C = rootCF.Position
			local lead = L.name == model:GetAttribute("BallLead")
			local th = model:GetAttribute("BallTh") or 0
			local i, n = (L.slot or 1) - 1, #g.limbs
			local hy = 1 - 2 * (i + 0.5) / n
			local hr = math.sqrt(1 - hy * hy)
			local hx, hz = hr * math.cos(i * 2.39996), hr * math.sin(i * 2.39996)
			if lead then
				hx, hy, hz = 0, 1, 0
			end
			local ca, sa = math.cos(th), math.sin(th)
			local head = (rootCF.RightVector * hx + rootCF.UpVector * (hy * ca - hz * sa) + rootCF.LookVector * (hy * sa + hz * ca)).Unit
			local r01 = (i * 0.618) % 1
			local want = lead and 0.5 * reach or math.min(0.95 * reach, (C.Y - floorY) * (2.2 + 0.5 * math.noise(now * 0.9, #L.name + 60)) * (0.8 + 0.4 * r01))
			if lead then
				T = C + head * want
			else
				if not L.bp then
					L.bp, L.bv = C + head * want, g.vel
				end
				local wn, zeta = 16 + 9 * r01, 0.3 + 0.25 * ((i * 0.37) % 1) -- (each its own stiffness and looseness)
				local h = math.min(dt, 1 / 30)
				local acc = (C + head * want - L.bp) * (wn * wn) - L.bv * (2 * zeta * wn)
				L.bv += acc * h
				L.bp += L.bv * h
				if L.bp.Y <= floorY then -- (planted: it can't go through, and it drags and grips as he goes over)
					L.bp = Vector3.new(L.bp.X, floorY, L.bp.Z)
					L.bv = Vector3.new(L.bv.X, math.max(L.bv.Y, 0), L.bv.Z) * Vector3.new(math.exp(-h * 10), 1, math.exp(-h * 10))
				end
				local off = L.bp - P -- (and no further than the limb reaches: the end of it snaps the tip back)
				if off.Magnitude > 0.97 * reach then
					local d = off.Unit
					L.bp = P + d * 0.97 * reach
					L.bv -= d * math.max(0, L.bv:Dot(d)) * 1.3
				end
				T = L.bp
			end
			radial = (T - C).Magnitude > 0.1 and (T - C).Unit or head
			if T.Y < floorY then
				T = Vector3.new(T.X, floorY, T.Z)
			end
			L.F, L.step = nil, nil
		else
			L.bp, L.bv = nil, nil
			-- its place on the floor: out along its own line, as far as it reaches from this height
			local h = P.Y - floorY
			local R = 0.8 * reach
			local r = h < R and math.sqrt(R * R - h * h) or 0.1 * R
			local home = groundAt(Vector3.new(P.X, 0, P.Z) + out * r)
			if L.high then -- a back limb: its upper bone stood up and out off his back, the foot a forearm's length from that elbow
				local E0 = P + (up * math.sin(1.13) + out * math.cos(1.13)) * a
				local hE = E0.Y - floorY
				home = groundAt(Vector3.new(E0.X, 0, E0.Z) + out * (hE < b and math.sqrt(b * b - hE * hE) or 0.1 * b))
			end
			if not L.F then
				L.F = home
			end
			-- stepping: lifted high and thrown ahead, landing where he'll be
			if L.step then
				local k = (now - L.step.t0) / L.step.dur
				if k >= 1 then
					L.F, L.step = L.step.to, nil
					stepping -= 1
				end
			end
			if not L.step and not stilt then
				local stretch = (Vector3.new(L.F.X, 0, L.F.Z) - Vector3.new(home.X, 0, home.Z)).Magnitude / (0.28 * reach)
				local dF = (L.F - P).Magnitude
				if dF > reach * 0.97 or (L.high and dF < (b - a) * 1.05) then
					stretch += 2
				end
				local twin = L.pair and g.byName[L.pair]
				-- and for no reason at all: a limb lifts and resets, now and then, moving or not
				local twitch = now > g.twitch and math.random() < (g.vel.Magnitude < 1 and 0.12 or 0.05)
				if (stretch > 1 or twitch) and stepping < MAX_STEP and not (twin and twin.step) then
					if twitch then
						g.twitch = now + 0.15 + math.random() * 0.4
					end
					local side = Vector3.new(-L.dir.Z, 0, L.dir.X)
					local to = home + g.vel * 0.35 + rootCF:VectorToWorldSpace(side) * (math.random() - 0.5) * 0.7 * r
					if (to - P).Magnitude > reach * 0.95 then
						to = P + (to - P).Unit * reach * 0.9
					end
					if L.high and (to - P).Magnitude < (b - a) * 1.1 then
						to = P + (to - P).Unit * (b - a) * 1.15
					end
					L.step = { from = L.F, to = groundAt(to), t0 = now, dur = 0.16 + 0.045 * reach / s }
					stepping += 1
				end
			end
			T = L.F
			if L.step then
				local k = math.clamp((now - L.step.t0) / L.step.dur, 0, 1)
				-- lifted high, and flailing on the way: a wide swing out and back, the tip shaking
				local swing = rootCF:VectorToWorldSpace(L.dir) * math.sin(k * math.pi * 2) * 0.18 * reach
				local shake = Vector3.new(math.noise(now * 9, #L.name), math.noise(now * 9, #L.name + 3), math.noise(now * 9, #L.name + 6)) * 0.25 * s
				T = L.step.from:Lerp(L.step.to, k) + Vector3.yAxis * math.sin(k * math.pi) * 0.45 * reach + swing + shake
			else -- planted, it still won't keep still: scratching and kneading at the floor
				T += Vector3.new(math.noise(now * 3, #L.name + 20), 0, math.noise(now * 3, #L.name + 30)) * 0.3 * s
			end
		end
		-- the joint bent up and out (spider-like), wavering
		local pole = (ball and radial * 2 or L.high and up * 4 + out * 0.3 or up * 1.3 + out) + Vector3.new(math.noise(now * 3.5, #L.name), math.noise(now * 2.5, #L.name + 13) * 0.5, math.noise(now * 3.5, #L.name + 7)) * 1.4
		local u, E, l, n = ik(P, T, a, b, pole)
		local f1 = CFrame.fromMatrix(P, n, -u)
		if L.j1 then
			lerpC0(m1, base:Inverse() * f1, lw)
			local w1 = f1 * m1.C1:Inverse()
			lerpC0(m2, w1:Inverse() * CFrame.fromMatrix(E, n, -l), lw)
			if L.j1 == "RHip" or L.j1 == "LHip" then
				world[L.j1 == "RHip" and "RThigh" or "LThigh"] = base * m1.C0 * m1.C1:Inverse()
			end
		else
			local upW = CFrame.fromMatrix(P + u * a / 2, n, -u)
			local foreW = CFrame.fromMatrix(E + l * L.w2:GetAttribute("Len") / 2, n, -l)
			local c1, c2 = base:Inverse() * upW, upW:Inverse() * foreW
			local r1 = idleC0[L.w1] or g.rest[L.w1] or L.w1.C0
			local r2 = idleC0[L.w2] or g.rest[L.w2] or L.w2.C0
			L.w1.C0 = lw >= 0.999 and c1 or r1:Lerp(c1, lw)
			L.w2.C0 = lw >= 0.999 and c2 or r2:Lerp(c2, lw)
		end
	end
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local C = Config.Consul
local S = C.Scale
local Core, Map, FxRemote, states, now, bodyPose, aliveChar, playSound, SOUNDS, burst

local boss: any = { state = "none", gen = 0 } -- state: none | dormant | intro | fight | dead
local ROT, ORB = Color3.fromRGB(150, 180, 70), Color3.fromRGB(120, 60, 150)

local function inAttic(pos)
	local A = Map.Consul
	local b, h = A.Bounds, A.Hole
	-- (over the stair's head counts once the fog has sealed it: you're standing on the seal, not on the stairs)
	local sealed = boss.state == "intro" or boss.state == "fight" or boss.state == "rising"
	return pos.Y > A.Floor + 0.5 and pos.X > b[1] and pos.X < b[3] and pos.Z > b[2] and pos.Z < b[4]
		and (sealed or not (pos.X > h[1] and pos.X < h[3] and pos.Z > h[2] and pos.Z < h[4]))
end
local function playersInAttic()
	local list = {}
	for _, pl in ipairs(Players:GetPlayers()) do
		local char, _, hrp = aliveChar(pl)
		if char and inAttic(hrp.Position) then
			table.insert(list, { pl, hrp })
		end
	end
	return list
end

local function seal(on)
	local f = Map.Consul.Seal
	f.CanCollide = on
	TweenService:Create(f, TweenInfo.new(on and 0.6 or 2), { Transparency = on and 0.05 or 1 }):Play()
end

---------------------------------------------------------------------------
-- THE LOWER ARMS: a second pair out of his ribs, under the first, each with its catalyst. Welds, not the
-- Puppeteer's joints (it knows two arms): the server sets and tweens them. ARMS: per stance, per side,
-- { shoulder forward, shoulder out, elbow } in radians.
---------------------------------------------------------------------------
local ARMS = {
	Fold = { R = { 0.25, 0.15, 2.3 }, L = { 0.25, 0.15, 2.3 } }, -- tucked against the ribs
	Reach = { R = { 2.5, 0.35, 1.5 }, L = { 2.5, 0.35, 1.5 } }, -- raised and curled in over him (what he's assembled into)
	Cast = { R = { 2.7, 0.6, 0.35 }, L = { 1.7, 0.2, 0.15 } }, -- the censer thrown up and out, the talisman levelled ahead (the beam)
	Clutch = { R = { 0.9, 0.2, 2.6 }, L = { 0.9, 0.2, 2.6 } }, -- both pulled in against his middle (the blast)
	Stance = { R = { 0.4, 1.15, 1.0 }, L = { 1.7, 0.55, 0.5 } }, -- the censer out low and wide, the talisman thrust up ahead
	Sky = { R = { 3.0, 0.25, 0.2 }, L = { 3.0, 0.25, 0.2 } }, -- both thrust straight up to the sky (the matrix)
}
-- a joint of one of his extra limbs: a Motor6D (an animation editor can key those, and play them), parented to the
-- bone it moves, like a weld
local function limbJoint(name, p0, p1)
	local m = Instance.new("Motor6D")
	m.Name, m.Part0, m.Part1 = name, p0, p1
	m.Parent = p1
	return m
end
local function lowerArm(model, side)
	local chest = model:FindFirstChild("Chest")
	local sx = side == "R" and 1 or -1
	local long = side == "R" and 1.5 or 1 -- (the right one half as long again)
	local aw, ua, la = 0.3 * S, 1.15 * M.Proportions.arm * S * long, 1.2 * M.Proportions.arm * S * long
	local flesh = Color3.fromRGB(24, 20, 23)
	local function piece(name, size, color, mat, shape)
		local p = Instance.new("Part")
		p.Name = name
		if shape then
			p.Shape = shape
		end
		p.Size, p.Color, p.Material = size, color, mat
		p.CanCollide, p.CanTouch, p.Massless = false, false, true
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end
	local function weld(p0, p1, c0)
		local w = Instance.new("Weld")
		w.Part0, w.Part1, w.C0 = p0, p1, c0
		w.Parent = p1
		return w
	end
	local up = piece("X" .. side .. "UpperArm", Vector3.new(aw, ua, aw), flesh, Enum.Material.Slate)
	local fore = piece("X" .. side .. "LowerArm", Vector3.new(aw * 0.9, la, aw * 0.9), flesh, Enum.Material.Slate)
	local arm = {
		sx = sx, ua = ua, la = la,
		shoulder = CFrame.new(sx * (chest.Size.X / 2 + 0.12 * S), -0.1 * chest.Size.Y, 0.05 * S),
		w1 = limbJoint("X" .. side .. "Shoulder", chest, up),
		w2 = limbJoint("X" .. side .. "Elbow", up, fore),
	}
	-- (resting in his stance: what an animation of him is made on, and comes back to)
	local v = ARMS.Stance[side]
	arm.w1.C0 = arm.shoulder * CFrame.Angles(v[1], 0, sx * v[2]) * CFrame.new(0, -ua / 2, 0)
	arm.w2.C0 = CFrame.new(0, -ua / 2, 0) * CFrame.Angles(v[3], 0, 0) * CFrame.new(0, -la / 2, 0)
	arm.w1:SetAttribute("RestC0", arm.w1.C0)
	arm.w2:SetAttribute("RestC0", arm.w2.C0)
	-- (it crawls too: M.Gait takes it over on the move, from these; the server's stance is what it comes back to)
	arm.w1:SetAttribute("Limb", "X" .. side)
	arm.w1:SetAttribute("Seg", 1)
	arm.w1:SetAttribute("Pivot", arm.shoulder)
	arm.w1:SetAttribute("Len", ua)
	arm.w1:SetAttribute("Dir", Vector3.new(sx * 0.95, 0, -0.3))
	arm.w1:SetAttribute("Pair", "X" .. (side == "R" and "L" or "R"))
	arm.w2:SetAttribute("Limb", "X" .. side)
	arm.w2:SetAttribute("Seg", 2)
	arm.w2:SetAttribute("Len", la)
	weld(fore, piece("Claw", Vector3.new(aw * 1.1, 0.4 * S, aw * 1.1), flesh, Enum.Material.Slate), CFrame.new(0, -la / 2 - 0.1 * S, 0))
	local fist = CFrame.new(0, -la / 2 - 0.2 * S, 0)
	-- THE CATALYSTS' HEADS: glass within glass round a burning core, gripped in iron claws, with hoops and shards that
	-- turn about it (on every client, M.Gait, from Spin/SpinAt/SpinOff on their welds)
	local iron = Color3.fromRGB(30, 26, 28)
	local function sphere(name, at, d, color, mat, tr)
		local p = piece(name, Vector3.new(d, d, d) * S, color, mat, Enum.PartType.Ball)
		p.Transparency = tr or 0
		weld(fore, p, at)
		return p
	end
	local function bar(name, at, a, b, t, color, mat) -- from a to b (studs, in at's frame)
		local len = (b - a).Magnitude
		weld(fore, piece(name, Vector3.new(t, t, len + t), color, mat), at * CFrame.lookAt(a, b) * CFrame.new(0, 0, -len / 2))
	end
	local function spinning(w, at, off, rate)
		w:SetAttribute("Spin", rate)
		w:SetAttribute("SpinAt", at)
		w:SetAttribute("SpinOff", off)
	end
	local function hoop(name, at, r, n, t, color, mat, rate) -- a ring of n bars round at's Y axis, turning
		for i = 0, n - 1 do
			local a1, a2 = i / n * math.pi * 2, (i + 1) / n * math.pi * 2
			local p1, p2 = Vector3.new(math.cos(a1), 0, math.sin(a1)) * r, Vector3.new(math.cos(a2), 0, math.sin(a2)) * r
			local off = CFrame.lookAt(p1, p2) * CFrame.new(0, 0, -(p2 - p1).Magnitude / 2)
			spinning(weld(fore, piece(name, Vector3.new(t, t, (p2 - p1).Magnitude + t * 0.5), color, mat), at * off), at, off, rate)
		end
	end
	local function claws(name, at, n, r, from) -- n curved iron prongs from the staff's end round the glass, hooked in under it
		for i = 0, n - 1 do
			local ph = i / n * math.pi * 2
			local prev = Vector3.new(0, from, 0)
			for _, th in ipairs({ 0.55, 1.25, 1.95, 2.5 }) do
				local q = Vector3.new(math.sin(th) * math.cos(ph), math.cos(th), math.sin(th) * math.sin(ph)) * r * (th > 2.3 and 0.85 or 1)
				bar(name, at, prev, q, 0.07 * S, iron, Enum.Material.Metal)
				prev = q
			end
		end
	end
	if side == "R" then
		-- a censer on a long staff, smoking with rot
		local base = fist * CFrame.Angles(0.9, 0, 0)
		weld(fore, piece("CatalystStaff", Vector3.new(0.16, 4.2, 0.16) * S, Color3.fromRGB(34, 28, 24), Enum.Material.Wood), base * CFrame.new(0, -1.6 * S, 0))
		-- (its head turned so the staff comes into it from above: +Y towards the hand)
		local C = base * CFrame.new(0, -3.9 * S, 0)
		local censer = sphere("Censer", C, 0.4, ROT, Enum.Material.Neon) -- the burning core (its light and smoke below)
		sphere("CenserShell", C, 0.8, ROT, Enum.Material.ForceField)
		sphere("CenserGlass", C, 1.3, Color3.fromRGB(90, 120, 50), Enum.Material.Glass, 0.6)
		weld(fore, piece("CenserCollar", Vector3.new(0.42, 0.3, 0.42) * S, iron, Enum.Material.Metal), C * CFrame.new(0, 0.85 * S, 0))
		claws("CenserClaw", C, 6, 0.72 * S, 0.95 * S)
		hoop("CenserHoop", C * CFrame.Angles(0.55, 0, 0.3), 1.0 * S, 14, 0.05 * S, iron, Enum.Material.Metal, 1.3)
		hoop("CenserHoop", C * CFrame.Angles(-0.7, 0, -0.45), 1.15 * S, 16, 0.04 * S, ROT, Enum.Material.Neon, -0.8)
		for i = 0, 2 do -- drips of rot hanging under it
			local ph = i / 3 * math.pi * 2
			bar("CenserDrip", C, Vector3.new(math.cos(ph) * 0.25, -0.62, math.sin(ph) * 0.25) * S, Vector3.new(math.cos(ph) * 0.3, -1.05 - i * 0.12, math.sin(ph) * 0.3) * S, 0.06 * S, ROT, Enum.Material.Neon)
		end
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = ROT, 14, 1.2
		l.Parent = censer
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
		pe.Rate, pe.Lifetime, pe.Speed = 6, NumberRange.new(1.5, 2.5), NumberRange.new(0.5, 1.2)
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 2.2) })
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
		pe.Color = ColorSequence.new(Color3.fromRGB(110, 130, 60))
		pe.Acceleration = Vector3.new(0, 1.5, 0)
		pe.Parent = censer
	else
		-- a tall staff of black wood bound in dark iron, a ring of iron shards round a dark orb at its head
		local base = fist * CFrame.Angles(0.6, 0, 0)
		weld(fore, piece("CatalystStaff", Vector3.new(0.18, 6.4, 0.18) * S, Color3.fromRGB(22, 18, 20), Enum.Material.Wood), base * CFrame.new(0, -2.5 * S, 0))
		for _, y in ipairs({ 0.4, -1.4, -3.2, -4.9 }) do
			weld(fore, piece("StaffBinding", Vector3.new(0.26, 0.22, 0.26) * S, Color3.fromRGB(34, 28, 30), Enum.Material.Metal), base * CFrame.new(0, y * S, 0))
		end
		local ring = base * CFrame.new(0, -6.25 * S, 0)
		local orb = sphere("TalismanOrb", ring, 0.32, ORB, Enum.Material.Neon) -- the core (its light below)
		sphere("TalismanShell", ring, 0.62, ORB, Enum.Material.ForceField)
		sphere("TalismanGlass", ring, 1.05, Color3.fromRGB(90, 50, 120), Enum.Material.Glass, 0.55)
		claws("TalismanClaw", ring, 3, 0.6 * S, 0.6 * S)
		hoop("TalismanHoop", ring * CFrame.Angles(math.pi / 2, 0, 0), 0.85 * S, 12, 0.05 * S, iron, Enum.Material.Metal, 1.1)
		hoop("TalismanHoop", ring * CFrame.Angles(0, 0, math.pi / 2), 0.95 * S, 12, 0.04 * S, ORB, Enum.Material.Neon, -1.4)
		for k = 0, 9 do -- a wheel of iron shards round it, long and short, turning slowly
			local a = k / 10 * math.pi * 2
			local off = CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -1.25 * S) * CFrame.Angles(-1.2, 0, 0)
			spinning(weld(fore, piece("TalismanShard", Vector3.new(0.12, k % 2 == 0 and 0.75 or 0.45, 0.12) * S, Color3.fromRGB(30, 24, 28), Enum.Material.Metal), ring * off), ring, off, 0.6)
		end
		for k = 0, 2 do -- and three small lights going round it the other way
			local off = CFrame.Angles(0.4, k / 3 * math.pi * 2, 0) * CFrame.new(0, 0, -1.5 * S)
			local mote = piece("TalismanMote", Vector3.new(0.16, 0.16, 0.16) * S, ORB, Enum.Material.Neon, Enum.PartType.Ball)
			spinning(weld(fore, mote, ring * off), ring, off, -1.6)
		end
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = ORB, 12, 1.4
		l.Parent = orb
	end
	return arm
end
-- THE CRAWLING ARMS: thin black arms for him to crawl on: two long ones from his sides between his upper and lower
-- arms, and six short: two from the tops of his thighs, two from the back of his hips, two from under his ribs.
-- Each is two bones on welds the server only sets up; every client moves them (M.Gait), from the attributes on
-- each "CrawlerJoint": Limb (its name), Seg (1/2), Pivot, Len; and on the first, Dir (where it plants, in his
-- frame) and Pair (its twin, never lifted with it).
local function along(d) -- a rotation whose -Y runs along d (how a bone hangs from its joint)
	local y = -d.Unit
	local x = y:Cross(Vector3.zAxis)
	x = x.Magnitude > 1e-3 and x.Unit or y:Cross(Vector3.xAxis).Unit
	return CFrame.fromMatrix(Vector3.zero, x, y)
end
local function crawlers(model)
	local flesh, claw = Color3.fromRGB(24, 20, 23), Color3.fromRGB(30, 26, 28)
	local chest, hips = model:FindFirstChild("Chest"), model:FindFirstChild("Hips")
	local cs, hs = chest.Size, hips.Size
	local mounts = {} -- { base, pivot, size, name, dir }
	for _, sx in ipairs({ 1, -1 }) do
		local n, o = sx == 1 and "R" or "L", sx == 1 and "L" or "R"
		local th = model:FindFirstChild(n .. "Thigh")
		table.insert(mounts, { th, CFrame.new(0, th.Size.Y / 2 - 0.2 * S, -th.Size.Z / 2) * CFrame.Angles(1.1, 0, sx * 0.5), 0.8, "Thigh", Vector3.new(sx * 0.9, 0, 0.45) })
		table.insert(mounts, { hips, CFrame.new(sx * hs.X * 0.4, -0.1 * S, hs.Z / 2) * CFrame.Angles(-1.0, 0, sx * 0.7), 1, "Hip", Vector3.new(sx * 0.6, 0, 0.8) })
		table.insert(mounts, { chest, CFrame.new(sx * cs.X * 0.4, -cs.Y * 0.35, -cs.Z * 0.15) * CFrame.Angles(0.3, 0, sx * 1.2), 1, "Rib", Vector3.new(sx * 0.85, 0, -0.35) })
		table.insert(mounts, { chest, CFrame.new(sx * (cs.X / 2 + 0.1 * S), cs.Y * 0.2, cs.Z * 0.15) * CFrame.Angles(0, 0, sx * 1.3), 2, "Side", Vector3.new(sx, 0, -0.1) })
		for i = #mounts - 3, #mounts do
			mounts[i][4], mounts[i][6] = n .. mounts[i][4], o .. mounts[i][4]
		end
	end
	local function piece(name, size, color)
		local p = Instance.new("Part")
		p.Name, p.Size, p.Color, p.Material = name, size, color, Enum.Material.Slate
		p.CanCollide, p.CanTouch, p.CanQuery, p.Massless = false, false, false, true
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end
	local function joint(p0, p1, pivot, len, name, seg)
		local w = limbJoint("CrawlerJoint", p0, p1)
		w.C0 = pivot * CFrame.Angles(seg == 2 and 0.7 or 0, 0, 0) * CFrame.new(0, -len / 2, 0)
		w:SetAttribute("RestC0", w.C0)
		w:SetAttribute("Limb", name)
		w:SetAttribute("Seg", seg)
		w:SetAttribute("Pivot", pivot)
		w:SetAttribute("Len", len)
		w:SetAttribute("Idle", true) -- (twitching when he stands still)
		return w
	end
	for _, m in ipairs(mounts) do
		local base, pivot, k = m[1], m[2], m[3]
		local aw, ua, la = 0.16 * S * (k > 1.5 and 1.35 or 1), 0.9 * k * S, 1.0 * k * S
		local up = piece(m[4] .. "ArmUpper", Vector3.new(aw, ua, aw), flesh) -- (each bone its own name: animations find them by it)
		local fore = piece(m[4] .. "ArmFore", Vector3.new(aw * 0.85, la, aw * 0.85), flesh)
		local w1 = joint(base, up, pivot, ua, m[4], 1)
		w1:SetAttribute("Dir", m[5])
		w1:SetAttribute("Pair", m[6])
		joint(up, fore, CFrame.new(0, -ua / 2, 0), la, m[4], 2)
		for _, dx in ipairs({ -0.5, 0.5 }) do -- two hooked fingers
			local f = piece("CrawlerClaw", Vector3.new(aw * 0.5, 0.45 * S, aw * 0.5), claw)
			local w = Instance.new("Weld")
			w.Part0, w.Part1, w.C0 = fore, f, CFrame.new(dx * aw, -la / 2 - 0.18 * S, 0) * CFrame.Angles(0.5, 0, dx * 0.6)
			w.Parent = f
		end
	end
	-- THE BACK LIMBS: four more off his upper back, as thick as his weapon arms, with the upper bone of his long ones
	-- and forearms longer still (2.6x): their elbows stand up over his head like a harvestman's (High), planted as
	-- he crawls. Standing, each pair its own shape: the top two from mid-back, steeply up and a little out, knees
	-- peaked high beside his head (as high as they go and still clear its cage and needles, by a stud between centre
	-- lines, even with his head thrown back and turned as in his lurch), the forearms dropping straight down and out
	-- from the peaks; the lower two from low on his back,
	-- reaching out sideways and back, the forearms dropping to the floor
	for _, m in ipairs({
		-- name, twin, where on his back, where it plants crawling, and standing: the upper bone's line, the forearm's
		{ "BackRU", "BackLU", Vector3.new(cs.X * 0.6, 0, cs.Z / 2), Vector3.new(0.75, 0, -0.65), Vector3.new(0.45, 0.9, 0.2), Vector3.new(0.55, -0.9, 0) },
		{ "BackLU", "BackRU", Vector3.new(-cs.X * 0.6, 0, cs.Z / 2), Vector3.new(-0.75, 0, -0.65), Vector3.new(-0.45, 0.9, 0.2), Vector3.new(-0.55, -0.9, 0) },
		{ "BackRL", "BackLL", Vector3.new(cs.X * 0.45, -cs.Y * 0.3, cs.Z / 2), Vector3.new(0.8, 0, 0.6), Vector3.new(0.8, 0.35, 0.5), Vector3.new(0.35, -0.93, 0.1) },
		{ "BackLL", "BackRL", Vector3.new(-cs.X * 0.45, -cs.Y * 0.3, cs.Z / 2), Vector3.new(-0.8, 0, 0.6), Vector3.new(-0.8, 0.35, 0.5), Vector3.new(-0.35, -0.93, 0.1) },
	}) do
		local aw, ua, la = 0.55 * M.Proportions.girth * S, 1.15 * M.Proportions.arm * S * 1.5, 1.2 * M.Proportions.arm * S * 2.6
		local up = piece(m[1] .. "Upper", Vector3.new(aw, ua, aw), flesh)
		local fore = piece(m[1] .. "Fore", Vector3.new(aw * 0.9, la, aw * 0.9), flesh)
		local upRot = along(m[5])
		local w1 = joint(chest, up, CFrame.new(m[3]) * upRot, ua, m[1], 1)
		local w2 = joint(up, fore, CFrame.new(0, -ua / 2, 0), la, m[1], 2)
		w2.C0 = CFrame.new(0, -ua / 2, 0) * along(upRot:VectorToObjectSpace(m[6])) * CFrame.new(0, -la / 2, 0)
		w2:SetAttribute("RestC0", w2.C0)
		w1:SetAttribute("Dir", m[4])
		w1:SetAttribute("Pair", m[2])
		w1:SetAttribute("High", true)
		w1:SetAttribute("Idle", nil)
		w2:SetAttribute("Idle", nil)
		for _, e in ipairs({ { "BackElbow", Vector3.new(aw * 1.5, aw * 1.5, aw * 1.5), CFrame.new(0, la / 2, 0) }, { "BackClaw", Vector3.new(aw * 1.1, 0.4 * S, aw * 1.1), CFrame.new(0, -la / 2 - 0.1 * S, 0) } }) do
			local p = piece(e[1], e[2], flesh)
			local w = Instance.new("Weld")
			w.Part0, w.Part1, w.C0 = fore, p, e[3]
			w.Parent = p
		end
	end
end

-- the cutscene's star: the two top back limbs' forearms raised slowly from hanging down and out to reaching up and
-- out (still a stud clear of his head), or back (up = false)
local function backStar(b, up, t)
	for _, w in ipairs(b.model:GetDescendants()) do
		local id = w:IsA("Motor6D") and w:GetAttribute("Limb")
		local w1 = (id == "BackRU" or id == "BackLU") and w:GetAttribute("Seg") == 2 and w.Part0:FindFirstChild("CrawlerJoint")
		if w1 then
			local rest = w:GetAttribute("Rest") or w.C0
			w:SetAttribute("Rest", rest)
			local ua, la = w1:GetAttribute("Len"), w:GetAttribute("Len")
			-- turned about the elbow itself (a tween would slide the forearm's middle straight across, off the joint)
			local elbow, half = CFrame.new(0, -ua / 2, 0), CFrame.new(0, -la / 2, 0)
			local from = (elbow:Inverse() * w.C0 * half:Inverse()).Rotation
			local to = up and along(w1.C0.Rotation:VectorToObjectSpace(Vector3.new(id == "BackRU" and 0.6 or -0.6, 0.8, 0.1)))
				or (elbow:Inverse() * rest * half:Inverse()).Rotation
			local gen, t0 = b.gen, now()
			task.spawn(function()
				repeat
					local k = math.clamp((now() - t0) / t, 0, 1)
					w.C0 = elbow * from:Lerp(to, (1 - math.cos(k * math.pi)) / 2) * half
					RunService.Heartbeat:Wait()
				until k >= 1 or boss.gen ~= gen or not w.Parent
			end)
		end
	end
end

-- the upper-left back limb (the one that takes the broadsword) swung about its own joints to new lines - the upper
-- bone's and the forearm's, in his chest's frame - or (no lines) back to how it hangs, over t s
local function swingBack(b, upDir, foreDir, t)
	local w1, w2 = b.backArm and b.backArm[1], b.backArm and b.backArm[2]
	if not (w1 and w2) then
		return
	end
	local ua, la = w1:GetAttribute("Len"), w2:GetAttribute("Len")
	local pivot, elbow, h1, h2 = CFrame.new(w1:GetAttribute("Pivot").Position), CFrame.new(0, -ua / 2, 0), CFrame.new(0, -ua / 2, 0), CFrame.new(0, -la / 2, 0)
	b.backRest = b.backRest or { w1.C0, w2.C0 }
	local from1 = (pivot:Inverse() * w1.C0 * h1:Inverse()).Rotation
	local from2 = (elbow:Inverse() * w2.C0 * h2:Inverse()).Rotation
	local to1 = upDir and along(upDir) or (pivot:Inverse() * b.backRest[1] * h1:Inverse()).Rotation
	local to2 = foreDir and along(to1:VectorToObjectSpace(foreDir)) or (elbow:Inverse() * b.backRest[2] * h2:Inverse()).Rotation
	b.backSwing = (b.backSwing or 0) + 1
	local me, gen, t0 = b.backSwing, b.gen, now()
	task.spawn(function()
		repeat
			local k = t > 0 and math.clamp((now() - t0) / t, 0, 1) or 1
			local e = (1 - math.cos(k * math.pi)) / 2
			w1.C0 = pivot * from1:Lerp(to1, e) * h1
			w2.C0 = elbow * from2:Lerp(to2, e) * h2
			RunService.Heartbeat:Wait()
		until k >= 1 or boss.gen ~= gen or b.backSwing ~= me or not w1.Parent
	end)
end
-- the broadsword in the back limb's hand (its twin there shown, the hand's hidden), or back in his hand
local function swapBlade(b, toBack)
	for _, p in ipairs(b.handSword or {}) do
		p.Transparency = toBack and 1 or 0
	end
	for _, p in ipairs(b.backSword or {}) do
		p.Transparency = toBack and 0 or 1
	end
end

-- (for his second phase, to come) the broadsword's fuller and edges lit purple, or dark again
local function litBlade(b, on)
	for _, p in ipairs(b.model:GetChildren()) do
		local lit = p:GetAttribute("LitColor")
		if lit then
			p:SetAttribute("DarkColor", p:GetAttribute("DarkColor") or p.Color)
			p.Color, p.Material = on and lit or p:GetAttribute("DarkColor"), on and Enum.Material.Neon or Enum.Material.Metal
		end
	end
end
M.litBlade = litBlade

-- his extra limbs and catalysts, on a rig RigBuilder has built: for the boss, and for the dummy animations are made
-- on (M.dress, from the command bar or a tool: RigBuilder.build("Consul", Config.Consul.Scale), then this). The arms
-- table: the lower pair (armsTo)
local function dress(model)
	local arms = { R = lowerArm(model, "R"), L = lowerArm(model, "L") }
	crawlers(model)
	return arms
end
M.dress = dress

local function armsTo(b, stance, t)
	for side, a in pairs(b.arms) do
		local v = ARMS[stance][side]
		local c1 = a.shoulder * CFrame.Angles(v[1], 0, a.sx * v[2]) * CFrame.new(0, -a.ua / 2, 0)
		local c2 = CFrame.new(0, -a.ua / 2, 0) * CFrame.Angles(v[3], 0, 0) * CFrame.new(0, -a.la / 2, 0)
		if t <= 0 then
			a.w1.C0, a.w2.C0 = c1, c2
		else
			local info = TweenInfo.new(t, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			TweenService:Create(a.w1, info, { C0 = c1 }):Play()
			TweenService:Create(a.w2, info, { C0 = c2 }):Play()
		end
	end
end

---------------------------------------------------------------------------
-- THE PIECES: while he waits, the real rig is hidden and anchored copies of its parts lie about the arena, a
-- limb at a time (GROUP); the assembly moves each group whole, as one, from where it lies to where it belongs.
---------------------------------------------------------------------------
local GROUP = {
	Head = "Head", Chest = "Chest", Hips = "Hips",
	RUpperArm = "RArm", RLowerArm = "RArm", LUpperArm = "LArm", LLowerArm = "LArm",
	RThigh = "RLeg", RShin = "RLeg", RFoot = "RLeg", LThigh = "LLeg", LShin = "LLeg", LFoot = "LLeg",
	XRUpperArm = "XR", XRLowerArm = "XR", XLUpperArm = "XL", XLLowerArm = "XL",
}
local ORDER = { "RLeg", "LLeg", "Hips", "Chest", "RArm", "LArm", "XR", "XL" } -- (the order they set off in)
-- the bone each limb bends at as it crawls (the joint at the top of it), and the bones that go with it
local BEND = { RArm = "RLowerArm", LArm = "LLowerArm", RLeg = "RShin", LLeg = "LShin", XR = "XRLowerArm", XL = "XLLowerArm" }
local BENDS = { RLowerArm = true, LLowerArm = true, RShin = true, RFoot = true, LShin = true, LFoot = true, XRLowerArm = true, XLLowerArm = true }
local function boneOf(p) -- the body part (a GROUP key) a piece hangs from
	for _ = 1, 6 do
		if GROUP[p.Name] then
			return p.Name
		end
		local w = p:FindFirstChildWhichIsA("WeldConstraint") or p:FindFirstChildWhichIsA("JointInstance")
		if not (w and w.Part0) then
			break
		end
		p = w.Part0
	end
	return nil
end
local function groupOf(p)
	for _ = 1, 6 do
		if GROUP[p.Name] then
			return GROUP[p.Name]
		end
		local w = p:FindFirstChildWhichIsA("WeldConstraint") or p:FindFirstChildWhichIsA("JointInstance")
		if not (w and w.Part0) then
			break
		end
		p = w.Part0
	end
	return "Chest"
end
local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end
local function turnFrom(f, dir) -- the rotation that turns facing f to face dir (both flat)
	return CFrame.lookAt(Vector3.zero, dir.Unit) * CFrame.lookAt(Vector3.zero, f.Unit):Inverse()
end

local function scatter(b)
	local A = Map.Consul
	local folder = Instance.new("Folder")
	folder.Name = "ConsulPieces"
	folder.Parent = workspace
	local groups = {}
	for p, tr in pairs(b.vis) do
		local c = p:Clone()
		for _, k in ipairs(c:GetChildren()) do -- (its light and haze go with it: the head glows even in pieces)
			if k:IsA("Light") or k:IsA("ParticleEmitter") or k:IsA("Attachment") then
				for _, f in ipairs(k:GetDescendants()) do
					f.Enabled = true
				end
				if not k:IsA("Attachment") then
					k.Enabled = true
				end
			else
				k:Destroy()
			end
		end
		c.Anchored, c.CanCollide, c.CanQuery, c.CanTouch = true, false, false, false
		c.Transparency = tr
		c.Parent = folder
		local name = groupOf(p)
		groups[name] = groups[name] or { name = name, parts = {} }
		table.insert(groups[name].parts, { c, p.CFrame, nil, BENDS[boneOf(p) or ""] })
	end
	local r = Random.new(9301)
	local facing = flat(b.home.LookVector)
	for i, name in ipairs(ORDER) do
		local g = groups[name]
		if g then
			local a = (i - 0.5) / #ORDER * math.pi * 2 + r:NextNumber(-0.25, 0.25)
			local rad = r:NextNumber(19, 25)
			local at = Vector3.new(A.Dais.X + math.cos(a) * rad, A.Floor + 0.5 * S, A.Dais.Z + math.sin(a) * rad)
			-- lying flat on the floor, any which way
			g.start = CFrame.new(at) * CFrame.Angles(0, r:NextNumber(0, 6.28), 0) * CFrame.Angles(math.pi / 2 * (r:NextNumber() < 0.5 and 1 or -1), 0, r:NextNumber(-0.4, 0.4))
			g.delay = 1.6 + (i - 1) * 0.36
			g.crawl = r:NextNumber(2.2, 2.7)
			g.rise = r:NextNumber(0.9, 1.2)
			g.seed = r:NextNumber(0, 100)
		end
	end
	local head = groups.Head
	if head then -- on the dais, on its side, looking away
		head.start = CFrame.new(A.Dais.X, A.Dais.Y + 1.1 * S, A.Dais.Z) * turnFrom(facing, -facing) * CFrame.Angles(0, 0, 0.6)
	end
	for _, g in pairs(groups) do
		local sum = Vector3.zero
		for _, e in ipairs(g.parts) do
			sum += e[2].Position
		end
		g.pivot = CFrame.new(sum / #g.parts) -- (where the group belongs; each part kept relative to it)
		for _, e in ipairs(g.parts) do
			e[3] = g.pivot:Inverse() * e[2]
		end
		local bone = BEND[g.name] and b.model:FindFirstChild(BEND[g.name])
		if bone then -- (its joint, where the bone below it bends, in the group's own frame)
			g.joint = g.pivot:Inverse() * bone.CFrame * CFrame.new(0, bone.Size.Y / 2, 0)
		end
	end
	return { folder = folder, groups = groups }
end
local function place(G, cfOf) -- cfOf(g) gives where the group is, and how far its limb is bent at its joint
	local ps, cfs = {}, {}
	for _, g in pairs(G.groups) do
		local cf, flex = cfOf(g)
		if cf then
			local bend = flex and g.joint and g.joint * CFrame.Angles(flex, 0, 0) * g.joint:Inverse()
			for _, e in ipairs(g.parts) do
				table.insert(ps, e[1])
				table.insert(cfs, (bend and e[4]) and cf * bend * e[3] or cf * e[3])
			end
		end
	end
	workspace:BulkMoveTo(ps, cfs, Enum.BulkMoveMode.FireCFrameChanged)
end
local function ease(x)
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

local function showReal(b, on)
	for p, tr in pairs(b.vis) do
		p.Transparency = on and tr or 1
	end
	for _, f in ipairs(b.fx) do
		f.Enabled = on
	end
end

-- the attic's lamps gutter out while he's up (and come back when he's gone): the arena's big warm lights drown his
-- glow, so the room goes dark but for the moon, and he is its light
local lamps
local function snuff(on)
	if not lamps then
		lamps = {}
		local A = Map.Consul
		for _, d in ipairs(workspace:GetDescendants()) do
			local p = d.Parent
			if d:IsA("Light") and p:IsA("BasePart") and (p.Name == "ColumnLight" or p.Name == "ChandelierLight" or p.Name == "ArenaLight") then
				local q = p.Position
				if q.Y > A.Floor and q.X > A.Bounds[1] and q.X < A.Bounds[3] and q.Z > A.Bounds[2] and q.Z < A.Bounds[4] then
					lamps[d] = d.Brightness
				end
			end
		end
	end
	for l, br in pairs(lamps) do
		l.Enabled = true
		local tw = TweenService:Create(l, TweenInfo.new(on and 3 or 2), { Brightness = on and 0 or br })
		if on then
			tw.Completed:Connect(function(state)
				if state == Enum.PlaybackState.Completed then
					l.Enabled = false
				end
			end)
		end
		tw:Play()
	end
end

local rise -- (below: phase 1's health gone)
local restoreDay -- (below: the sky back to day)
local function onDied(b)
	if boss.gen ~= b.gen or boss.state == "dead" then
		return
	end
	boss.state = "dead"
	boss.purple = false
	ReplicatedStorage:SetAttribute("BossActive", false)
	ReplicatedStorage:SetAttribute("Music", "victory")
	FxRemote:FireAllClients("Banner", "CONSUL FELLED", "Victory")
	FxRemote:FireAllClients("Say", C.Name2, C.DeathLine)
	seal(false)
	snuff(false)
	Core.dropSplinter(b.root.Position, b.model)
	restoreDay(45) -- the night lifts, slowly
	-- a while after he's gone (his last words, the victory banner, the music have had their time): his hold on
	-- the bonfires ends, and rest at one lets you be carried to any other you've lit (init.server's "Travel")
	task.delay(11, function()
		ReplicatedStorage:SetAttribute("BonfireTravel", true)
		FxRemote:FireAllClients("Banner", "THE SPELL IS BROKEN\nThe Consul's enchantment unravels, and the flame remembers its kin.", "Spell")
		task.wait(5)
		FxRemote:FireAllClients("Message", "The Consul's spell has been broken. Teleportation between bonfires is now possible.")
	end)
	task.spawn(function()
		task.wait(2)
		for _, d in ipairs(b.model:GetDescendants()) do
			if d:IsA("BasePart") and d.Transparency < 1 then
				TweenService:Create(d, TweenInfo.new(2.5), { Transparency = 1 }):Play()
			end
		end
		task.wait(2.7)
		b.model:Destroy()
	end)
end

local function spawn()
	boss.gen += 1
	local model, hum = Core.makeRig("Consul", "Consul", S, nil)
	if not model then
		return
	end
	hum.MaxHealth, hum.Health = C.HP, C.HP
	hum.BreakJointsOnDeath = false
	hum.AutoRotate = false
	hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false) -- (his health running out is his rise, then his death: below)
	model:SetAttribute("Radius", 2.4)
	model:SetAttribute("Boss", true)
	local root = model:FindFirstChild("HumanoidRootPart")
	root.Anchored = true -- (pinned all the while: he stands his ground, turned by hand)
	root.CollisionGroup = "EnemyRoot"
	local A = Map.Consul
	local y = A.Dais.Y + 3 * S
	local home = CFrame.lookAt(Vector3.new(A.Dais.X, y, A.Dais.Z), Vector3.new(-228, y, -30)) -- (towards the stair's head)
	model:PivotTo(home)
	local b = { model = model, hum = hum, root = root, scale = S, gen = boss.gen, home = home }
	b.arms = dress(model)
	armsTo(b, "Reach", 0)
	bodyPose(b, "XRest", 0.01)
	-- (and the server's own joints set to it, for the pieces to be laid out from: the clients pose him themselves,
	-- to the same XRest by the same math. Required here: at the top it would load this file in a circle)
	local PM = require(ReplicatedStorage:WaitForChild("PuppetMath"))
	local D = PM.dims("Consul", S)
	local rest = PM.solve(D, PM.joints(D), root.CFrame, PM.pose("XRest", "Consul"), { groundY = root.Position.Y - D.rootY })
	for _, m in ipairs(model:GetDescendants()) do
		if m:IsA("Motor6D") and rest[m.Name] then
			m.C0 = rest[m.Name]
		end
	end
	-- his head is never without its light: the eye's sick glow, a cold rim behind the needles, and a haze about it
	local headPart, eyePart = model:FindFirstChild("Head"), model:FindFirstChild("Eye")
	if headPart and eyePart then
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness, l.Shadows = Color3.fromRGB(196, 226, 86), 44, 4.4, true -- (the arena's own lights are low: this is most of what lights the fight)
		l.Parent = eyePart
		local beam = Instance.new("SpotLight")
		beam.Color, beam.Range, beam.Brightness, beam.Angle, beam.Face = Color3.fromRGB(196, 226, 86), 60, 5.2, 50, Enum.NormalId.Front
		beam.Parent = eyePart
		local rim = Instance.new("Attachment")
		rim.Position = Vector3.new(0, 1.2 * S, 1.4 * S)
		rim.Parent = headPart
		local rl = Instance.new("PointLight")
		rl.Color, rl.Range, rl.Brightness = Color3.fromRGB(150, 110, 200), 9, 3.25
		rl.Parent = rim
		local haze = Instance.new("ParticleEmitter")
		haze.Texture = "rbxasset://textures/particles/smoke_main.dds"
		haze.Rate, haze.Lifetime, haze.Speed, haze.SpreadAngle = 10, NumberRange.new(2, 3.5), NumberRange.new(0.2, 0.6), Vector2.new(180, 180)
		haze.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2 * S), NumberSequenceKeypoint.new(1, 3 * S) })
		haze.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.61), NumberSequenceKeypoint.new(1, 1) })
		haze.Color = ColorSequence.new(Color3.fromRGB(120, 140, 70), Color3.fromRGB(70, 50, 90))
		haze.LightEmission, haze.Acceleration = 0.4, Vector3.new(0, 0.6, 0)
		haze.Parent = headPart
		-- a halo drawn as particles: it glows whatever the room's lighting
		local halo = Instance.new("ParticleEmitter")
		halo.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		halo.Rate, halo.Lifetime, halo.Speed, halo.LockedToPart = 12, NumberRange.new(0.5, 0.8), NumberRange.new(0), true
		halo.Size = NumberSequence.new(1.6 * S)
		halo.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.55), NumberSequenceKeypoint.new(1, 1) })
		halo.Color = ColorSequence.new(Color3.fromRGB(196, 226, 86))
		halo.LightEmission, halo.LightInfluence = 1, 0
		halo.Parent = eyePart
	end
	-- a faint trail of light off each sword, only while it cuts (b.trails.R / .L, set on by the attacks)
	local ends = {}
	for _, d in ipairs(model:GetChildren()) do
		for _, key in ipairs({ "TrailBase", "TrailTip" }) do
			local n = d:GetAttribute(key)
			if n then
				ends[n] = ends[n] or {}
				ends[n][key] = d
			end
		end
	end
	b.trails = {}
	for n, e in pairs(ends) do
		if e.TrailBase and e.TrailTip then
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			a0.Position, a1.Position = Vector3.new(0, e.TrailBase.Size.Y / 2, 0), Vector3.new(0, -e.TrailTip.Size.Y / 2, 0)
			a0.Parent, a1.Parent = e.TrailBase, e.TrailTip
			local tr = Instance.new("Trail")
			tr.Attachment0, tr.Attachment1 = a0, a1
			tr.Lifetime, tr.MinLength, tr.LightEmission, tr.Enabled = 0.22, 0, 0.6, false
			tr.Color = ColorSequence.new(Color3.fromRGB(205, 220, 160))
			tr.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
			tr.Parent = e.TrailTip
			b.trails[n] = tr
		end
	end
	-- the broadsword's twin, hidden in the upper-left back limb's hand, and its own trail ("B"): the wheel shows it
	-- there (and hides the one in his hand) when that limb takes the sword
	b.handSword, b.backSword, b.backArm = {}, {}, {}
	local lfore, grip = model:FindFirstChild("LLowerArm"), nil
	for _, d in ipairs(model:GetChildren()) do
		local wc = d:FindFirstChildWhichIsA("WeldConstraint")
		if wc and wc.Part0 == lfore and d.Name:sub(1, 5) == "Sword" then
			table.insert(b.handSword, d)
			if d.Name == "SwordGrip" then
				grip = d
			end
		end
	end
	for _, w in ipairs(model:GetDescendants()) do
		if w:IsA("Motor6D") and w:GetAttribute("Limb") == "BackLU" then
			b.backArm[w:GetAttribute("Seg")] = w
		end
	end
	if grip and b.backArm[2] then
		local bfore = b.backArm[2].Part1
		local hand = CFrame.new(0, -bfore.Size.Y / 2 - 0.3 * S, 0) -- (the blade on along the forearm's line)
		local tb, tt
		for _, part in ipairs(b.handSword) do
			local c = part:Clone()
			c:ClearAllChildren()
			c.Transparency = 1
			if c:GetAttribute("TrailBase") then
				tb = c
			elseif c:GetAttribute("TrailTip") then
				tt = c
			end
			c:SetAttribute("TrailBase", nil)
			c:SetAttribute("TrailTip", nil)
			c.Parent = model
			local w = Instance.new("Weld")
			w.Part0, w.Part1, w.C0 = bfore, c, hand * grip.CFrame:Inverse() * part.CFrame
			w.Parent = c
			table.insert(b.backSword, c)
		end
		if tb and tt and b.trails.L then
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			a0.Position, a1.Position = Vector3.new(0, tb.Size.Y / 2, 0), Vector3.new(0, -tt.Size.Y / 2, 0)
			a0.Parent, a1.Parent = tb, tt
			local tr = b.trails.L:Clone()
			tr.Attachment0, tr.Attachment1, tr.Enabled = a0, a1, false
			tr.Parent = tt
			b.trails.B = tr
		end
	end
	local heart = model:FindFirstChild("Heart")
	if heart then -- (lights his ribs from inside)
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = Color3.fromRGB(120, 10, 16), 6, 1.56
		l.Parent = heart
	end
	b.vis, b.fx = {}, {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d ~= root and d.Transparency < 1 then
			b.vis[d] = d.Transparency
		elseif d:IsA("Light") or d:IsA("ParticleEmitter") then
			table.insert(b.fx, d)
		end
	end
	showReal(b, false)
	boss.model, boss.hum, boss.root, boss.current = model, hum, root, b
	boss.state = "dormant"
	hum.HealthChanged:Connect(function(h)
		if boss.gen == b.gen and boss.state == "fight" then
			ReplicatedStorage:SetAttribute("BossHP", math.max(0, h))
			if h <= 0 then
				if b.phase2 then
					onDied(b)
				else
					task.spawn(rise, b)
				end
			end
		end
	end)
	-- (the pieces are laid out once the welds have put the rig's parts where they belong)
	task.spawn(function()
		RunService.Heartbeat:Wait()
		RunService.Heartbeat:Wait()
		if boss.gen == b.gen then
			b.ghost = scatter(b)
			place(b.ghost, function(g)
				return g.start
			end)
		end
	end)
end

-- THE ASSEMBLY (seconds from the trigger): the head turns to whoever came up (0.5-2), rises to its place (2.2-4.8);
-- the limbs crawl in by turns, lurching, and lift up into place (1.6-7.6); at COMBINE he is whole, and unfolds
local COMBINE = 7.6 -- (whole a beat ahead of the music; he holds it a moment before he slumps, below)
local function assemble(b, lookAt, rising) -- (rising: his rise, below - the head crawls in with the rest, and it stops once he's shown)
	local G = b.ghost
	if not G then
		return false
	end
	local head = G.groups.Head
	local facing = flat(b.home.LookVector)
	local eye
	if head and not rising then
		for _, e in ipairs(head.parts) do
			if e[1].Name == "Eye" then
				eye = e[1]
			end
		end
		local dir = flat(lookAt - head.start.Position)
		-- (it lies half way round to you already, so it has less to turn)
		local at = head.start.Position
		head.start = (CFrame.new(at) * head.start.Rotation):Lerp(CFrame.new(at) * turnFrom(facing, dir.Magnitude > 0.1 and dir or facing) * CFrame.Angles(0, 0, 0.6), 0.5)
		head.look = CFrame.new(head.start.Position + Vector3.new(0, 0.5, 0)) * turnFrom(facing, dir.Magnitude > 0.1 and dir or facing) * CFrame.Angles(0, 0, 0.25)
	end
	-- where a limb is at t, and how bent: lying where it fell (twitching), then crawling in - drawing itself up,
	-- bending at its joint, and throwing itself out straight, again and again, like something that has to pull
	-- itself along - then lifted up into place, curling as it goes and straightening into his pose
	local function limbCF(g, t)
		local u = t - g.delay
		if u <= 0 then
			return g.start, 0.25 * math.max(0, math.noise(g.seed, t * 3) - 0.2)
		end
		-- crawling in: lurching, a stagger at a time, writhing side to side
		local A = Map.Consul
		local fin = g.pivot.Position
		local stop = Vector3.new(fin.X, A.Dais.Y + 0.6 * S, fin.Z)
		local p0 = g.start.Position
		local rot = g.start.Rotation
		if u < g.crawl then
			local x = u / g.crawl * 5
			local k = (math.floor(x) + math.clamp(x % 1 * 1.4, 0, 1) ^ 3) / 5
			local side = flat(stop - p0)
			side = side.Magnitude > 0.1 and Vector3.new(-side.Z, 0, side.X).Unit or Vector3.zero
			local writhe = side * math.sin(u * 9) * 0.5 * S * (1 - k)
			local yaw = CFrame.Angles(0, math.noise(g.seed, u * 2.5) * 0.8, 0)
			local flex = 1.1 * math.sin(math.min(x % 1 * 1.25, 1) * math.pi) + 0.2 * math.noise(g.seed + 5, u * 4)
			local heave = Vector3.yAxis * math.sin(math.min(x % 1 * 1.25, 1) * math.pi) * 0.35 * S
			return CFrame.new(p0:Lerp(stop, k) + writhe + heave) * yaw * rot * CFrame.Angles(0.25 * math.sin(x * math.pi * 2), 0, 0), flex
		end
		-- and up into place, with a shudder as it gets there
		local v = math.clamp((u - g.crawl) / g.rise, 0, 1)
		local k = 1 - (1 - v) ^ 3
		local shake = (1 - v) * 0.15 * S
		local from = CFrame.new(stop) * rot
		return from:Lerp(g.pivot, k) + Vector3.new(math.noise(g.seed, t * 20) * shake, 0, math.noise(t * 20, g.seed) * shake), 0.8 * math.sin(v * math.pi) * (1 - v)
	end
	local t0 = now()
	local lit = false
	local slow = rising and C.Rise.Slow or 1 -- (his rise: slower, every lurch and writhe of it)
	while true do
		local t = (now() - t0) / slow
		if boss.gen ~= b.gen or boss.state ~= (rising and "rising" or "intro") then
			return false
		end
		if eye and not lit and t > 0.9 then -- the eye kindles as it finds you
			lit = true
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness = Color3.fromRGB(196, 226, 86), 10, 2
			l.Parent = eye
			playSound(eye, SOUNDS.Unsheath, 0.5, 0.4)
		end
		place(G, function(g)
			if g == head and not rising then
				if t < 0.5 then
					return g.start
				elseif t < 2.0 then
					local k = ease((t - 0.5) / 1.5)
					local twitch = (t > 1.1 and t < 1.25) and CFrame.Angles(0, 0, 0.2) or CFrame.new()
					return g.start:Lerp(g.look, k) * twitch
				end
				-- it waits there, watching, until his chest comes up under it, and is carried up on its neck the rest
				-- of the way (picked up as the neck reaches it, not before)
				local chest = G.groups.Chest
				if not chest then
					return g.look:Lerp(g.pivot, ease((t - 2.2) / 2.6))
				end
				local carried = limbCF(chest, t) * (chest.pivot:Inverse() * g.pivot)
				return g.look:Lerp(carried, ease((carried.Position.Y - g.look.Position.Y) / (0.6 * S)))
			end
			return limbCF(g, t)
		end)
		if t >= COMBINE or b.skip then
			break
		end
		task.wait()
	end
	-- whole: the copies go, he is shown, slumps, jerks upright too far, and sinks into his stance
	G.folder:Destroy()
	b.ghost = nil
	showReal(b, true)
	burst(b.root.Position, Color3.fromRGB(40, 30, 44), 40, 0.7, 16)
	burst(b.root.Position + Vector3.new(0, 2 * S, 0), ROT, 24, 0.4, 10)
	playSound(b.root, SOUNDS.Impact, 1, 0.3)
	FxRemote:FireAllClients("Shake", b.root.Position, 0.6)
	if rising then
		return boss.gen == b.gen and boss.state == "rising"
	end
	local function pause(t) -- (cut short by a skip)
		local t1 = now() + t
		while now() < t1 and not b.skip do
			task.wait()
		end
	end
	pause(0.2) -- (whole, held in the pose he made himself into, a moment)
	if boss.gen ~= b.gen then
		return false
	end
	bodyPose(b, "XUnfold", 0.25)
	-- a beat, slumped and still, a groan, and only then the pose
	pause(1.1)
	if not b.skip then
		playSound(b.root, SOUNDS.Groan, 0.6, 0.5)
	end
	pause(0.8)
	if boss.gen ~= b.gen then
		return false
	end
	local step
	if not b.skip then
		bodyPose(b, "XLurch", 0.45)
		armsTo(b, "Stance", 1.2)
		step = TweenService:Create(b.root, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = b.home * CFrame.new(0, 0, -3) })
		step:Play()
		pause(0.5)
		bodyPose(b, "XStance", 0.9)
		playSound(b.root, SOUNDS.Unsheath, 0.9, 0.6)
		pause(1.0)
	end
	if b.skip then -- skipped: straight into his stance, where it would have left him
		if step then
			step:Cancel()
		end
		armsTo(b, "Stance", 0)
		bodyPose(b, "XStance", 0.2)
		b.root.CFrame = b.home * CFrame.new(0, 0, -3)
	end
	return boss.gen == b.gen and boss.state == "intro"
end

-- every time: the camera taken and everyone in the attic held still while he comes together. Any of them can skip
-- it by holding Space (the client's bar; it fires "ConsulSkip", which sets b.skip): he stands up whole at once
local function cutscene(b, lookAt, watchers)
	local A = Map.Consul
	local cx, cz, F, dy = A.Dais.X, A.Dais.Z, A.Floor, A.Dais.Y
	local V, look = Vector3.new, CFrame.lookAt
	-- (framed for him at scale 1.9, and grown with him: k)
	local k = S / 1.9
	local function P(x, y, z)
		return V(cx + x * k, F + y * k, cz + z * k)
	end
	local function Q(y) -- (over the dais)
		return V(cx, dy + y * k, cz)
	end
	local shots = {
		{ look(P(9, 5, 11), Q(1.5)), look(P(7, 4, 9), Q(1.5)), 2.4 },
		{ look(P(4, 3.5, 6), Q(2)), look(P(3.5, 3.3, 5), Q(2.4)), 1.6 },
		{ look(P(-20, 9, 26), P(0, 3, 0)), look(P(-16, 12, 22), P(0, 5, 0)), 3.6 },
		-- whole, slumped, and the pause before the pose: a slow push in from low
		{ look(P(2, 3, 15), P(0, 8, 0)), look(P(1, 3, 12), P(0, 9, 0)), 2.2 },
		-- the pose, struck
		{ look(P(-6, 5, 13), P(0, 9, 2)), look(P(-8, 6, 16), P(0, 10, 2)), 1.8 },
		-- and held, while the camera takes him in: low round his flank, looking up at him
		{ look(P(11, 2, 8), P(0, 10, 3)), look(P(7, 2.5, 12), P(0, 11, 3)), 2.6 },
		-- his head, the eye in its cage, a slow creep in
		{ look(P(-1, 10.5, 12), P(0, 10.5, 4)), look(P(-0.5, 10.8, 9), P(0, 10.8, 4)), 2.8 },
	}
	local total = 0
	for _, sh in ipairs(shots) do
		total += sh[3]
	end
	local held = {}
	for _, w in ipairs(watchers) do
		local pl, hrp = w[1], w[2]
		local st = states[pl]
		if st then
			Core.setAction(st, now(), total, total, total)
			st.healing = false
			Core.cancelSwing(st)
		end
		hrp.Anchored = true
		held[pl] = hrp
		FxRemote:FireClient(pl, "Grabbed", total)
		FxRemote:FireClient(pl, "Cutscene", shots, "ConsulSkip")
	end
	b.skip, b.held = nil, held
	ReplicatedStorage:SetAttribute("MusicIntro", total) -- (the client starts Config.Consul.CutsceneMusic so it ends as this does)
	ReplicatedStorage:SetAttribute("Music", "consulintro")
	local t0 = now()
	local ok = assemble(b, lookAt)
	if ok then -- he holds his pose through the last shots, the top back limbs' forearms rising into a star
		if not b.skip then
			backStar(b, true, 3.5)
		end
		while now() - t0 < total and not b.skip do
			task.wait()
		end
		ok = boss.gen == b.gen and boss.state == "intro"
		if ok then
			backStar(b, false, b.skip and 0.3 or 0.8)
		end
	end
	if b.skip then -- (and the server's hold on them let go too, and the cutscene's music cut)
		for pl in pairs(held) do
			if states[pl] then
				Core.setAction(states[pl], now(), 0, 0, 0)
			end
		end
		ReplicatedStorage:SetAttribute("ConsulIntroCut", (ReplicatedStorage:GetAttribute("ConsulIntroCut") or 0) + 1)
	end
	b.held = nil
	for pl, hrp in pairs(held) do
		if hrp.Parent then
			hrp.Anchored = false
			pcall(function()
				hrp:SetNetworkOwner(pl)
			end)
		end
	end
	return ok
end

-- the players within radius of the line a-b (flat), and within height of it
local function playersAlong(a, b, radius, height)
	local out = {}
	local ab = flat(b - a)
	for _, pl in ipairs(Players:GetPlayers()) do
		local char, _, hrp = aliveChar(pl)
		if char then
			local p = hrp.Position
			local t = ab.Magnitude > 1e-3 and math.clamp(flat(p - a):Dot(ab) / ab:Dot(ab), 0, 1) or 0
			local q = a + (b - a) * t
			if flat(p - q).Magnitude <= radius and math.abs(p.Y - q.Y) <= height then
				table.insert(out, pl)
			end
		end
	end
	return out
end

-- turned towards target (an HRP) by at most rate rad/s, where he stands
local function turnTo(b, target, rate, dt)
	if target.Parent then
		local p, to = b.root.Position, flat(target.Position - b.root.Position)
		local look = b.root.CFrame.LookVector
		local have = math.atan2(-look.X, -look.Z)
		local diff = (math.atan2(-to.X, -to.Z) - have + math.pi) % (2 * math.pi) - math.pi
		b.root.CFrame = CFrame.new(p) * CFrame.Angles(0, have + math.clamp(diff, -rate * dt, rate * dt), 0)
	end
end

-- THE SLASH (Config.Consul.Slash): stood up out of his crawl, the right sword drawn up and
-- back while he keeps turning to you, then brought down across him; it lands in the wedge in front of him
-- (windup: its own, for the wheel's follow-up; single: the first cut alone)
local function slash(b, target, windup, single)
	local A = C.Slash
	windup = windup or A.Windup
	b.model:SetAttribute("Busy", true)
	bodyPose(b, "XSlashWind", windup * 0.8)
	playSound(b.root, SOUNDS.Unsheath, 0.8, 0.7)
	local t0 = now()
	while now() - t0 < windup do
		local dt = task.wait()
		if boss.gen ~= b.gen or boss.state ~= "fight" then
			return
		end
		turnTo(b, target, 2, dt)
	end
	local function trail(n, on)
		if b.trails and b.trails[n] then
			b.trails[n].Enabled = on
		end
	end
	trail("R", true)
	bodyPose(b, "XSlash", A.Swing)
	playSound(b.root, C.SlashSounds[1], 1, 1)
	task.wait(A.Swing * 0.6)
	if boss.gen ~= b.gen or boss.state ~= "fight" then
		return
	end
	for _, pl in ipairs(Core.playersInSector(b.root.CFrame, A.Range, A.HalfAngle, 10)) do
		Core.damagePlayer(pl, math.max(1, math.floor(A.Damage * (C.DamageScale or 1) + 0.5)), b.root.Position, "Large")
	end
	if single then
		task.wait(A.Swing * 0.6)
		trail("R", false)
	else
		-- and at once the other sword: dropped low on his left, and ripped up back across him
		local U = A.Upper
		task.wait(U.Gap)
		trail("R", false)
		bodyPose(b, "XUpperWind", U.Windup * 0.7)
		t0 = now()
		while now() - t0 < U.Windup do
			local dt = task.wait()
			if boss.gen ~= b.gen or boss.state ~= "fight" then
				return
			end
			turnTo(b, target, 3, dt)
		end
		trail("L", true)
		bodyPose(b, "XUpper", U.Swing)
		playSound(b.root, C.SlashSounds[2], 1, 1)
		task.wait(U.Swing * 0.6)
		if boss.gen ~= b.gen or boss.state ~= "fight" then
			return
		end
		for _, pl in ipairs(Core.playersInSector(b.root.CFrame, A.Range, A.HalfAngle, 10)) do
			Core.damagePlayer(pl, math.max(1, math.floor(U.Damage * (C.DamageScale or 1) + 0.5)), b.root.Position, "Large")
		end
		task.wait(U.Swing * 0.6)
		trail("L", false)
	end
	task.wait(A.Recover)
	if boss.gen == b.gen and boss.state == "fight" then
		bodyPose(b, "XStance", 0.5)
		task.wait(0.3)
		b.model:SetAttribute("Busy", nil)
	end
end

-- THE BEAM (Config.Consul.Beam): he draws himself up and arches back with every arm thrown wide (the catalysts
-- blazing), the purple one (the talisman, his left lower hand) swelling with dark light and a thin line out of it
-- where the beam will start; then it fires out of it, and he turns on the spot with it, a whole circle round the arena. It stops at the first wall or column
-- (stand behind one), is as high as his chest (a roll goes through it, and a jump almost never clears it), and
-- hurts each player once
local PURPLE, PURPLE_CORE = Color3.fromRGB(62, 20, 125), Color3.fromRGB(130, 80, 195)
local function beamRun(b, target, ground, fx, A)
	local function alive()
		return boss.gen == b.gen and boss.state == "fight"
	end
	local function glow(shape, size, color, tr)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Material, p.Color, p.Size, p.Transparency, p.Shape = Enum.Material.Neon, color, size, tr, shape
		p.Parent = workspace
		table.insert(fx, p)
		return p
	end
	local function dirOf(a)
		return Vector3.new(-math.sin(a), 0, -math.cos(a))
	end
	b.model:SetAttribute("Busy", true)
	local base = b.root.Position
	-- up, and the pose
	bodyPose(b, "XCast", A.Rise)
	armsTo(b, "Cast", A.Rise)
	playSound(b.root, SOUNDS.Groan, 1, 0.4)
	local tal = b.model:FindFirstChild("TalismanOrb") -- (the purple catalyst's core: where it comes out)
	local hit0 = workspace:Raycast(base, Vector3.new(0, -14 * S, 0), ground)
	local floorY = hit0 and hit0.Position.Y or base.Y - 3 * S
	local orb = glow(Enum.PartType.Ball, Vector3.one, PURPLE, 0.25)
	local lamp = Instance.new("PointLight")
	lamp.Color, lamp.Range, lamp.Brightness = Color3.fromRGB(100, 45, 190), 40, 2.4
	lamp.Parent = orb
	local line = glow(Enum.PartType.Block, Vector3.new(0.25 * S, 0.25 * S, 1), PURPLE, 0.5)
	local feed = glow(Enum.PartType.Block, Vector3.new(0.1, 0.1, 0.1), PURPLE, 0.3) -- (the catalyst to where the level beam starts, when its hand is high or low)
	local function hand()
		return tal and tal.Position or b.root.Position + b.root.CFrame.LookVector * 4 * S
	end
	local function origin() -- the beam runs level at a height a player is hit at, from straight out of the catalyst
		local h = hand()
		return Vector3.new(h.X, math.clamp(h.Y, floorY + 2.8, floorY + 5.5), h.Z)
	end
	local function link(o)
		local h = hand()
		local m = (h - o).Magnitude
		feed.Size = Vector3.new(A.Width * 0.5, A.Width * 0.5, math.max(m, 0.05))
		feed.CFrame = m > 0.05 and CFrame.lookAt((h + o) / 2, o) or CFrame.new(o)
	end
	local function reach(o, dir) -- how far a line from o along dir goes before a wall or column
		local hit = workspace:Raycast(o, dir * A.Length, ground)
		return hit and (hit.Position - o).Magnitude or A.Length
	end
	local angle = math.atan2(-b.root.CFrame.LookVector.X, -b.root.CFrame.LookVector.Z)
	local t0, total = now(), A.Rise + A.Charge
	local pinged = false
	while true do
		local dt = task.wait()
		if not alive() then
			return
		end
		local t = now() - t0
		if t < total - 0.35 then -- (tracking you until the last beat, then fixed: the line is where it starts)
			local to = target.Parent and flat(target.Position - b.root.Position)
			if to and to.Magnitude > 0.1 then
				local want = math.atan2(-to.X, -to.Z)
				angle += math.clamp((want - angle + math.pi) % (2 * math.pi) - math.pi, -2.5 * dt, 2.5 * dt)
			end
		elseif not pinged then
			pinged = true
			playSound(b.root, SOUNDS.Unsheath, 1, 0.35)
		end
		local lift = A.Lift * (1 - (1 - math.min(t / A.Rise, 1)) ^ 3)
		b.root.CFrame = CFrame.new(base + Vector3.new(0, lift, 0)) * CFrame.Angles(0, angle, 0)
		local o, d = origin(), dirOf(angle)
		local grow = math.clamp((t - A.Rise * 0.5) / (A.Charge + A.Rise * 0.5), 0, 1)
		orb.Size = Vector3.one * (0.6 + 3.4 * grow + 0.3 * math.sin(t * 30) * grow) * S
		orb.Position = hand()
		link(o)
		local len = reach(o, d)
		line.Size = Vector3.new(0.25 * S, 0.25 * S, len)
		line.CFrame = CFrame.lookAt(o + d * len / 2, o + d * len)
		line.Transparency = 0.75 - 0.4 * grow
		if t >= total then
			break
		end
	end
	-- fired: the beam
	local width = A.Width
	local outer = glow(Enum.PartType.Block, Vector3.new(width, width, 1), PURPLE, 0.2)
	local core = glow(Enum.PartType.Block, Vector3.new(width * 0.4, width * 0.4, 1), PURPLE_CORE, 0.1)
	local flare = glow(Enum.PartType.Ball, Vector3.one * width * 1.8, PURPLE, 0.3)
	line:Destroy()
	playSound(b.root, C.SlamSound, 1.3, 0.6)
	FxRemote:FireAllClients("Shake", b.root.Position, 0.7)
	local hitOnce = {}
	local a0, t1 = angle, now()
	local lastBurst = 0
	while true do
		task.wait()
		if not alive() then
			return
		end
		local k = math.clamp((now() - t1) / A.Sweep, 0, 1)
		angle = a0 + 2 * math.pi * k
		b.root.CFrame = CFrame.new(base + Vector3.new(0, A.Lift, 0)) * CFrame.Angles(0, angle, 0)
		local o, d = origin(), dirOf(angle)
		local len = reach(o, d)
		local mid, tip = o + d * len / 2, o + d * len
		outer.Size, core.Size = Vector3.new(width, width, len), Vector3.new(width * 0.4, width * 0.4, len)
		outer.CFrame, core.CFrame = CFrame.lookAt(mid, tip), CFrame.lookAt(mid, tip)
		flare.Position, orb.Position = tip, hand()
		orb.Size = Vector3.one * 4 * S
		link(o)
		if now() - lastBurst > 0.4 then -- (sparks where the end of it burns)
			lastBurst = now()
			burst(Vector3.new(tip.X, base.Y - 3 * S, tip.Z), PURPLE, 10, 0.4, 10)
		end
		for _, w in ipairs(playersInAttic()) do
			local pl, hrp = w[1], w[2]
			if not hitOnce[pl] then
				local v = hrp.Position - o
				local along = v:Dot(d)
				if along > 0 and along < len + 1 and math.abs(v.Y) < 3.5 and (v - d * along - Vector3.new(0, v.Y, 0)).Magnitude < width / 2 + 1.2 then
					hitOnce[pl] = true
					Core.damagePlayer(pl, math.max(1, math.floor(A.Damage * (C.DamageScale or 1) + 0.5)), o, "Large")
				end
			end
		end
		if k >= 1 then
			break
		end
	end
	-- spent: the beam thins to nothing, and he comes down
	t1 = now()
	while now() - t1 < 0.15 do
		task.wait()
		if not alive() then
			return
		end
		local f = 1 - (now() - t1) / 0.15
		outer.Size, core.Size = Vector3.new(width * f, width * f, outer.Size.Z), Vector3.new(width * 0.4 * f, width * 0.4 * f, core.Size.Z)
		orb.Size = Vector3.one * 4 * S * f
		feed.Size = Vector3.new(width * 0.5 * f, width * 0.5 * f, feed.Size.Z)
		flare.Size = Vector3.one * width * 1.8 * f
	end
	bodyPose(b, "XStance", 0.3)
	armsTo(b, "Stance", 0.3)
	t1 = now()
	while now() - t1 < A.Recover do
		task.wait()
		if not alive() then
			return
		end
		local k = math.clamp((now() - t1) / A.Recover, 0, 1)
		b.root.CFrame = CFrame.new(base + Vector3.new(0, A.Lift * (1 - k), 0)) * b.root.CFrame.Rotation
	end
	b.root.CFrame = CFrame.new(base) * b.root.CFrame.Rotation
end

local function beam(b, target, ground)
	local fx = {}
	local ok, err = pcall(beamRun, b, target, ground, fx, C.Beam)
	for _, p in ipairs(fx) do
		p:Destroy()
	end
	if not ok then
		warn("[Consul] beam: " .. tostring(err))
	end
	if boss.gen == b.gen and boss.state == "fight" then
		armsTo(b, "Stance", 0.3)
		b.model:SetAttribute("Busy", nil)
	end
end

-- THE BLAST (Config.Consul.Blast): the censer's spell. He folds in on himself, every arm clutched to his middle,
-- and rot gathers in him; then it goes off, a disc of it racing out across the floor to A.Radius. It hits whatever
-- is on the ground as its front passes (a roll goes through it, and a jump over it clears it), once each. What
-- is drawn is a pale dome, spreading exactly as far as it can hurt and a touch past (SHOW: never short of it), and
-- it hangs there a moment, fading, so you can see how far it reached
local function blastRun(b, target, ground, fx, A)
	local function alive()
		return boss.gen == b.gen and boss.state == "fight"
	end
	local function glow(shape, size, color, tr, mat)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Material, p.Color, p.Size, p.Transparency, p.Shape = mat or Enum.Material.Neon, color, size, tr, shape
		p.Parent = workspace
		table.insert(fx, p)
		return p
	end
	b.model:SetAttribute("Busy", true)
	local base = b.root.Position
	local hit0 = workspace:Raycast(base, Vector3.new(0, -14 * S, 0), ground)
	local floorY = hit0 and hit0.Position.Y or base.Y - 3 * S
	local flat90 = CFrame.Angles(0, 0, math.pi / 2) -- (a cylinder lies on its side; stood on its end it's a disc)
	local function disc(r, y)
		return CFrame.new(base.X, floorY + y, base.Z) * flat90, Vector3.new(0.12, r * 2, r * 2)
	end
	-- clutched in
	bodyPose(b, "XClutch", A.Charge * 0.4)
	armsTo(b, "Clutch", A.Charge * 0.4)
	playSound(b.root, SOUNDS.Groan, 1, 0.35)
	local core = glow(Enum.PartType.Ball, Vector3.one, ROT, 0.2)
	local lamp = Instance.new("PointLight")
	lamp.Color, lamp.Range, lamp.Brightness = ROT, 35, 3
	lamp.Parent = core
	local t0 = now()
	local pinged = false
	while true do
		local dt = task.wait()
		if not alive() then
			return
		end
		local t = now() - t0
		local k = math.clamp(t / A.Charge, 0, 1)
		turnTo(b, target, 1.2, dt)
		-- (shuddering harder as it builds, and sinking a little)
		local shake = Vector3.new(math.noise(t * 40, 1), 0, math.noise(t * 40, 2)) * 0.35 * S * k
		b.root.CFrame = b.root.CFrame.Rotation + base + shake - Vector3.new(0, 0.5 * S * k, 0)
		core.Position = b.root.Position + Vector3.new(0, 0.6 * S, 0)
		core.Size = Vector3.one * (0.8 + 4.5 * k ^ 2 + 0.4 * math.sin(t * 28) * k) * S
		lamp.Brightness = 2 + 5 * k
		if k > 0.8 and not pinged then -- (the last beat)
			pinged = true
			playSound(b.root, SOUNDS.Unsheath, 1, 0.3)
		end
		if k >= 1 then
			break
		end
	end
	-- gone off
	local SHOW = 1.05 -- (drawn this much bigger than it hurts)
	local HIT = 4 -- (it hurts this far either side of its front: the hit reaches Radius, and no further)
	local dome = glow(Enum.PartType.Ball, Vector3.one, Color3.fromRGB(205, 230, 150), 0.8)
	local flashBall = core
	playSound(b.root, C.SlamSound, 1.5, 0.7)
	playSound(b.root, SOUNDS.Impact, 1.2, 0.3)
	FxRemote:FireAllClients("Shake", base, 1.3)
	Core.shockwave(Vector3.new(base.X, floorY, base.Z), 12)
	bodyPose(b, "XShow", 0.15)
	armsTo(b, "Reach", 0.15)
	local hitOnce = {}
	local t1 = now()
	while true do
		task.wait()
		if not alive() then
			return
		end
		local k = math.clamp((now() - t1) / A.Blast, 0, 1)
		local e = 1 - (1 - k) ^ 2
		local front = (A.Radius - HIT) * e
		-- what is drawn: a dome spreading out as far as it can hurt, and a touch past
		dome.Size = Vector3.one * ((A.Radius - HIT) * e + HIT) * SHOW * 2
		dome.Position = Vector3.new(base.X, floorY, base.Z)
		dome.Transparency = 0.8 + 0.1 * k
		flashBall.Size = Vector3.one * (5 + 14 * k) * S
		flashBall.Transparency = 0.2 + 0.8 * k
		for _, w in ipairs(playersInAttic()) do
			local pl, hrp = w[1], w[2]
			if not hitOnce[pl] then
				local dist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(base.X, 0, base.Z)).Magnitude
				if math.abs(dist - front) < HIT and hrp.Position.Y - floorY < 6.5 then
					hitOnce[pl] = true
					Core.damagePlayer(pl, math.max(1, math.floor(A.Damage * (C.DamageScale or 1) + 0.5)), base, "Knockdown")
				end
			end
		end
		if k >= 1 then
			break
		end
	end
	-- the dome hangs there a moment, fading: how far it reached (it outlasts the attack, so the cleanup leaves it)
	for i, p in ipairs(fx) do
		if p == dome then
			table.remove(fx, i)
			break
		end
	end
	for _, p in ipairs(fx) do
		p.Transparency = 1
	end
	TweenService:Create(dome, TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 }):Play()
	task.delay(2.6, dome.Destroy, dome)
	-- and he's spent: a long moment to hit him
	bodyPose(b, "XStance", 0.3)
	armsTo(b, "Stance", 0.3)
	local t2 = now()
	local from = b.root.CFrame
	while now() - t2 < A.Recover do
		local dt = task.wait()
		if not alive() then
			return
		end
		local k = math.clamp((now() - t2) / A.Recover, 0, 1)
		b.root.CFrame = from.Rotation + base - Vector3.new(0, 0.5 * S * (1 - k), 0)
		turnTo(b, target, 1, dt)
	end
	b.root.CFrame = b.root.CFrame.Rotation + base
end

local function blast(b, target, ground)
	local fx = {}
	local ok, err = pcall(blastRun, b, target, ground, fx, C.Blast)
	for _, p in ipairs(fx) do
		p:Destroy()
	end
	if not ok then
		warn("[Consul] blast: " .. tostring(err))
	end
	if boss.gen == b.gen and boss.state == "fight" then
		armsTo(b, "Stance", 0.3)
		b.model:SetAttribute("Busy", nil)
	end
end

-- THE STILT (Config.Consul.Stilt): his limbs planted round him (the client's crawl, held: "Stilt"), he's lifted on
-- them as high as they reach, looms there turning to you, then topples forward onto you, faster as he goes; where
-- his head comes down it hurts, and he lies sprawled a moment, his limbs scrambling back under him, then rights himself
local function stiltRun(b, target, ground)
	local A = C.Stilt
	local function alive()
		return boss.gen == b.gen and boss.state == "fight"
	end
	b.model:SetAttribute("Stilt", true)
	playSound(b.root, SOUNDS.Groan, 0.8, 0.45)
	local base = b.root.Position
	local t0 = now()
	while now() - t0 < A.Rise + A.Hold do
		local dt = task.wait()
		if not alive() then
			return
		end
		local k = math.clamp((now() - t0) / A.Rise, 0, 1)
		turnTo(b, target, 1.5, dt)
		if target.Parent then
			b.model:SetAttribute("FaceAt", target.Position) -- (his face on you, all through it: M.Gait)
		end
		b.root.CFrame = b.root.CFrame.Rotation + base + Vector3.new(0, A.Lift * (1 - (1 - k) ^ 3), 0)
	end
	-- the topple: forward and down onto you, pitching over as he goes
	local top = b.root.CFrame
	local fwd = flat(top.LookVector).Unit
	local dist = target.Parent and math.clamp(flat(target.Position - base).Magnitude - 2 * S, 3, A.Reach) or A.Reach * 0.6
	local landXZ = base + fwd * dist
	local hit = workspace:Raycast(landXZ + Vector3.new(0, 6 * S, 0), Vector3.new(0, -12 * S, 0), ground)
	local floorY = hit and hit.Position.Y or base.Y - 3 * S
	local bx = Map.Consul.Bounds
	local land = Vector3.new(math.clamp(landXZ.X, bx[1] + 4, bx[3] - 4), floorY + 1.6 * S, math.clamp(landXZ.Z, bx[2] + 4, bx[4] - 4))
	t0 = now()
	local slammed = false
	while true do
		task.wait()
		if not alive() then
			return
		end
		if not slammed and now() - t0 >= A.Fall - 0.1 then -- (the sound starts a beat late: sent 0.1 s ahead of the impact)
			slammed = true
			playSound(b.root, C.SlamSound, 1.2, 1)
		end
		-- a wave breaking: thrown out forward first, then the whole of him comes down at once, curling over
		local k = math.clamp((now() - t0) / A.Fall, 0, 1)
		local ahead, drop = 1 - (1 - k) ^ 2, k ^ 2.5
		b.root.CFrame = CFrame.new(top.Position + (land - top.Position) * Vector3.new(ahead, drop, ahead)) * top.Rotation * CFrame.Angles(-1.4 * k ^ 1.5, 0, 0)
		if target.Parent then
			b.model:SetAttribute("FaceAt", target.Position)
		end
		if k >= 1 then
			break
		end
	end
	-- down
	local head = (b.root.CFrame * CFrame.new(0, 3.5 * S, 0)).Position
	local impact = Vector3.new(head.X, floorY, head.Z)
	burst(impact, Color3.fromRGB(60, 50, 44), 40, 0.8, 18)
	playSound(b.root, SOUNDS.Impact, 1, 0.25) -- (the old slam, under the new one)
	FxRemote:FireAllClients("Shake", impact, 1.1)
	-- (only along him: from where he came down to where his head hit, as wide as he is)
	local landed = Vector3.new(b.root.Position.X, floorY, b.root.Position.Z)
	for _, pl in ipairs(playersAlong(landed, impact, A.Radius, 8)) do
		Core.damagePlayer(pl, math.max(1, math.floor(A.Damage * (C.DamageScale or 1) + 0.5)), impact, "Knockdown")
	end
	b.model:SetAttribute("Stilt", nil) -- (his limbs scramble back under him)
	task.wait(A.Down)
	if not alive() then
		return
	end
	-- and rights himself
	local down = b.root.CFrame
	local stand = CFrame.new(land.X, floorY + 3 * S, land.Z) * top.Rotation
	t0 = now()
	while true do
		task.wait()
		if not alive() then
			return
		end
		local k = math.clamp((now() - t0) / A.Righting, 0, 1)
		b.root.CFrame = down:Lerp(stand, 1 - (1 - k) ^ 2)
		if k >= 1 then
			break
		end
	end
	b.model:SetAttribute("FaceAt", nil)
end

local function stilt(b, target, ground)
	local ok, err = pcall(stiltRun, b, target, ground)
	b.model:SetAttribute("Stilt", nil) -- (cut short or not: never left planted on them)
	b.model:SetAttribute("FaceAt", nil)
	if not ok then
		warn("[Consul] stilt: " .. tostring(err))
	end
end

local matrix -- (below, with the ruin it needs: phase 2's)
local function fight(b)
	-- (no attacks yet) he comes after the nearest of you: rolling in fits and surges (his roll is M.Gait, from how
	-- far he moves), weaving, his face kept on you; he stops a little way off, and holds his stance
	local A = Map.Consul
	local bx, h = A.Bounds, A.Hole
	local ground = RaycastParams.new()
	ground.FilterType = Enum.RaycastFilterType.Exclude
	local rolling, t0, y = false, now(), b.root.Position.Y
	local function allowed(name) -- (Config.Consul.OnlyAttack: testing one attack on its own)
		return not C.OnlyAttack or C.OnlyAttack == name
	end
	b.nextStilt = now() + 4 -- (not the moment the fight starts)
	b.nextBeam = now() + 7
	b.nextBlast = now() + 12
	b.nextMatrix = now() + C.Matrix.First -- (phase 2's)
	while boss.gen == b.gen and boss.state == "fight" do
		local dt = task.wait()
		if boss.gen ~= b.gen or boss.state ~= "fight" then
			break -- (felled, or gone, while it waited: no move, no attack started after it - his rise has him now)
		end
		local near, best = nil, math.huge
		local skip = { b.model, workspace:FindFirstChild("Enemies") }
		for _, w in ipairs(playersInAttic()) do
			local d = (w[2].Position - b.root.Position).Magnitude
			table.insert(skip, w[2].Parent)
			if d < best then
				near, best = w[2], d
			end
		end
		ground.FilterDescendantsInstances = skip
		if near then
			local t = now() - t0
			local p = b.root.Position
			local to = flat(near.Position - p)
			local want = math.atan2(-to.X, -to.Z)
			local look = b.root.CFrame.LookVector
			local have = math.atan2(-look.X, -look.Z)
			local diff = (want - have + math.pi) % (2 * math.pi) - math.pi
			local yaw = have + math.clamp(diff, -3.5 * dt, 3.5 * dt)
			local d = to.Magnitude
			-- phase 2, and rested: the matrix (up a column, lasers down on the floor, and a leap at you)
			if b.phase2 and allowed("Matrix") and now() >= (b.nextMatrix or 0) then
				rolling = false
				matrix(b, near, ground)
				b.nextMatrix = now() + C.Matrix.Cooldown
				b.nextBeam = math.max(b.nextBeam or 0, now() + 4)
				b.nextBlast = math.max(b.nextBlast or 0, now() + 4)
				b.nextStilt = math.max(b.nextStilt or 0, now() + 3)
				b.nextSlash = math.max(b.nextSlash or 0, now() + 0.6)
				y = b.root.Position.Y
				continue
			end
			-- facing you and rested: the blast (it holds the loop until he's recovered)
			if allowed("Blast") and d < C.Blast.Max and math.abs(diff) < 0.5 and now() >= (b.nextBlast or 0) then
				rolling = false
				blast(b, near, ground)
				b.nextBlast = now() + C.Blast.Cooldown
				b.nextBeam = math.max(b.nextBeam or 0, now() + 4)
				b.nextStilt = math.max(b.nextStilt or 0, now() + 3)
				b.nextSlash = math.max(b.nextSlash or 0, now() + 0.6)
				y = b.root.Position.Y
				continue
			end
			-- facing you and rested: the beam (it holds the loop until he's down again)
			if allowed("Beam") and d > C.Beam.Min and d < C.Beam.Max and math.abs(diff) < 0.5 and now() >= (b.nextBeam or 0) then
				rolling = false
				beam(b, near, ground)
				b.nextBeam = now() + C.Beam.Cooldown
				b.nextBlast = math.max(b.nextBlast or 0, now() + 4)
				b.nextStilt = math.max(b.nextStilt or 0, now() + 3)
				b.nextSlash = math.max(b.nextSlash or 0, now() + 0.6)
				y = b.root.Position.Y
				continue
			end
			-- far enough, near enough, facing you, and rested: the stilt (it holds the loop until he's up again)
			if allowed("Stilt") and d > C.Stilt.Min and d < C.Stilt.Max and math.abs(diff) < 0.5 and now() >= (b.nextStilt or 0) then
				rolling = false
				stilt(b, near, ground)
				b.nextStilt = now() + C.Stilt.Cooldown
				b.nextBeam = math.max(b.nextBeam or 0, now() + 3)
				b.nextBlast = math.max(b.nextBlast or 0, now() + 3)
				b.nextSlash = math.max(b.nextSlash or 0, now() + 0.6)
				y = b.root.Position.Y
				continue
			end
			-- in reach, facing you, and rested: the slash (it holds the loop until he's recovered)
			if allowed("Slash") and d < C.Slash.Range and math.abs(diff) < 0.5 and now() >= (b.nextSlash or 0) then
				rolling = false
				slash(b, near)
				b.nextSlash = now() + C.Slash.Cooldown
				continue
			end
			-- go, or stop (with some slack, so he doesn't stutter at the edge of it)
			if rolling and d < C.Keep then
				rolling = false
				bodyPose(b, "XStance", 0.5)
			elseif not rolling and d > C.Keep + 3 then
				rolling = true
				bodyPose(b, "XCrawl", 0.5)
			end
			local move = Vector3.zero
			if rolling then
				local surge = 0.45 + 0.75 * math.sin(t * 2.1) ^ 2 + 0.25 * math.noise(t * 0.8, 7)
				local fwd = to.Unit
				local side = Vector3.new(-fwd.Z, 0, fwd.X)
				move = (fwd + side * 0.45 * math.sin(t * 1.3)) * C.RollSpeed * math.max(surge, 0.15) * dt
				-- round the columns, not through them: slide along what's in the way
				local hit = workspace:Raycast(p, move.Unit * (move.Magnitude + 2.5 * S), ground)
				if hit and hit.Normal.Y < 0.5 then
					local n = flat(hit.Normal).Unit
					move -= n * move:Dot(n)
				end
			end
			local q = p + move
			q = Vector3.new(math.clamp(q.X, bx[1] + 4, bx[3] - 4), q.Y, math.clamp(q.Z, bx[2] + 4, bx[4] - 4))
			if q.X > h[1] - 3 and q.X < h[3] + 3 and q.Z > h[2] - 3 and q.Z < h[4] + 3 then
				q = Vector3.new(p.X, q.Y, p.Z) -- (never over the stair's head)
			end
			-- on the floor, or up on the dais
			local down = workspace:Raycast(q + Vector3.new(0, 4 * S, 0), Vector3.new(0, -10 * S, 0), ground)
			if down then
				y += (down.Position.Y + 3 * S - y) * (1 - math.exp(-dt * 10))
			end
			b.root.CFrame = CFrame.new(q.X, y, q.Z) * CFrame.Angles(0, yaw, 0)
		elseif rolling then
			rolling = false
			bodyPose(b, "XStance", 0.5)
		end
	end
end

---------------------------------------------------------------------------
-- HIS RISE (Config.Consul.Rise): phase 1's health gone, he comes apart - every limb its own, tumbling where it falls -
-- and lies in pieces a moment, as if beaten. Then a cutscene (everyone in the attic held and hidden from it; any of
-- them can skip it, as the first): the pieces crawl back to his dais and knit together, he draws himself up into a
-- righteous stance, speaks, swells with purple power, and one quick sweep of his beam slices the whole top off the
-- building at his shoulder. It slides away, its cut edges left seared and burning purple, pieces of it crash down
-- round the arena, and he fights on (phase 2's moves aren't built: his first's, at full health). reset() undoes it.
---------------------------------------------------------------------------
local ruin = nil -- the top he cut off: { root (folder), chunks, dir, top = { {part, cf, collide, transparency, query} }, cut, clones, joints, fx, limbs, hidden }
local rubble = nil -- the folder of what fell, the seared edges, and the fires

-- the sky goes to a dark starry night when phase 1 ends; reset() (he beat you) brings the day back in 3 s, his death in 45
local Lighting = game:GetService("Lighting")
local dayLook = nil -- what nightfall() changed, as it was
local NIGHT = {
	Lighting = { ClockTime = 0, Brightness = 0.8, Ambient = Color3.fromRGB(26, 28, 44), OutdoorAmbient = Color3.fromRGB(32, 36, 62) },
	Atmosphere = { Color = Color3.fromRGB(12, 14, 30), Decay = Color3.fromRGB(5, 5, 14), Density = 0.3, Haze = 0.5 },
}
local function nightfall()
	if dayLook then
		return
	end
	local atm, sky = Lighting:FindFirstChildOfClass("Atmosphere"), Lighting:FindFirstChildOfClass("Sky")
	dayLook = { Lighting = {}, Atmosphere = {}, sky = sky and { sky.StarCount, sky.CelestialBodiesShown } }
	for k in pairs(NIGHT.Lighting) do
		dayLook.Lighting[k] = Lighting[k]
	end
	TweenService:Create(Lighting, TweenInfo.new(6, Enum.EasingStyle.Sine), NIGHT.Lighting):Play()
	if atm then
		for k in pairs(NIGHT.Atmosphere) do
			dayLook.Atmosphere[k] = atm[k]
		end
		TweenService:Create(atm, TweenInfo.new(6, Enum.EasingStyle.Sine), NIGHT.Atmosphere):Play()
	end
	if sky then
		sky.StarCount, sky.CelestialBodiesShown = 4000, true
	end
end
local daySaved -- the day look, kept once it's being restored (so M.brighten can finish it sooner)
function restoreDay(dur, again) -- over dur seconds (default 3: he beat you; his death takes 45)
	dur = dur or 3
	local d = dayLook
	dayLook = nil
	if d then
		daySaved = d
	elseif again and daySaved then
		d = daySaved -- (the slow restore may be part way: tween from wherever it is, over dur)
	else
		return
	end
	local info = again and TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) or TweenInfo.new(dur, Enum.EasingStyle.Sine) -- (finishing it early: quick at first)
	TweenService:Create(Lighting, info, d.Lighting):Play()
	local atm, sky = Lighting:FindFirstChildOfClass("Atmosphere"), Lighting:FindFirstChildOfClass("Sky")
	if atm then
		TweenService:Create(atm, info, d.Atmosphere):Play()
	end
	if sky and d.sky then
		task.delay(dur > 3 and dur or 0, function() -- (the stars stay till the day is back)
			sky.StarCount, sky.CelestialBodiesShown = d.sky[1], d.sky[2]
		end)
	end
end

local function ruinFolder()
	if not rubble then
		rubble = Instance.new("Folder")
		rubble.Name = "ConsulRuin"
		rubble.Parent = workspace
	end
	return rubble
end

-- purple fire at p (the ruin's blaze): an invisible anchor with a fire, and (lit) its light
local FIRE, FIRE_DEEP, SEAR = Color3.fromRGB(150, 70, 255), Color3.fromRGB(40, 0, 70), Color3.fromRGB(86, 22, 150)
local function blaze(p, size, lit)
	local a = Instance.new("Part")
	a.Name = "ConsulBlaze"
	a.Anchored, a.CanCollide, a.CanQuery, a.CanTouch, a.Transparency, a.Size = true, false, false, false, 1, Vector3.one
	a.Position = p
	local f = Instance.new("Fire")
	f.Color, f.SecondaryColor, f.Size, f.Heat = FIRE, FIRE_DEEP, size, size * 0.8
	f.Parent = a
	if lit then
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = FIRE, size * 2.4, 2
		l.Parent = a
	end
	a.Parent = ruinFolder()
end

-- the building's top, cut at y (the columns' stumps each a little higher or lower: broken, not sliced clean): the
-- whole mansion block, towers and all, so nothing is left hanging. Blocks across the cut are split (the lower half
-- kept, the upper a copy, the cut face seared and burning); everything above it is welded to one anchored root, so
-- the whole of it moves (and replicates) as one
local BLOCK = { -300, -172, -128, 34 } -- x1, z1, x2, z2: the mansion and everything on it
local CHUNK = 24
local CollectionService = game:GetService("CollectionService")
local function sliceRoof(y, dir)
	local R = { top = {}, cut = {}, clones = {}, joints = {}, fx = {}, limbs = {}, stumps = {}, dir = dir }
	local set, n = {}, 0
	local function cutOne(p, cf, sz, yy) -- (one part, cut at yy)
		local q = cf.Position
		do
			do
				local half = (math.abs(cf.RightVector.Y) * sz.X + math.abs(cf.UpVector.Y) * sz.Y + math.abs(cf.LookVector.Y) * sz.Z) / 2
				local lo, hi = q.Y - half, q.Y + half
				local upright = p:IsA("Part") and p.Shape == Enum.PartType.Block and math.abs(cf.UpVector.Y) > 0.999
				if upright and lo < yy - 0.2 and hi > yy + 0.2 then
					local up = p:Clone()
					up:ClearAllChildren()
					up.Size = Vector3.new(sz.X, hi - yy, sz.Z)
					up.CFrame = cf.Rotation + Vector3.new(q.X, (yy + hi) / 2, q.Z)
					up.Parent = p.Parent
					table.insert(R.clones, up)
					table.insert(R.cut, { p, cf, sz })
					if p.Name == "AtticColumn" then -- (a stump he can climb: where its top is)
						table.insert(R.stumps, Vector3.new(q.X, yy, q.Z))
					end
					p.Size = Vector3.new(sz.X, yy - lo, sz.Z)
					p.CFrame = cf.Rotation + Vector3.new(q.X, (lo + yy) / 2, q.Z)
					set[up] = true
					-- the cut face: seared, glowing, and (where there's room for it) on fire along its length
					if p.Transparency < 1 then
						local cap = Instance.new("Part")
						cap.Name = "ConsulSear"
						cap.Anchored, cap.CanCollide, cap.CanQuery, cap.CanTouch, cap.CastShadow = true, false, false, false, false
						cap.Material, cap.Color, cap.Size = Enum.Material.Neon, SEAR, Vector3.new(sz.X + 0.05, 0.3, sz.Z + 0.05)
						cap.CFrame = cf.Rotation + Vector3.new(q.X, yy, q.Z)
						cap.Parent = ruinFolder()
						local long, short = math.max(sz.X, sz.Z), math.min(sz.X, sz.Z)
						if short >= 1.5 and long >= 2.5 then
							local along = (sz.X >= sz.Z) and cf.RightVector or cf.LookVector
							local k = math.max(1, math.floor(long / 11))
							for i = 1, k do
								n += 1
								local at = Vector3.new(q.X, yy + 0.6, q.Z) + along * ((i - 0.5) / k - 0.5) * long
								blaze(at, k == 1 and math.clamp(long * 1.4, 5, 9) or 6 + (n % 3) * 1.5, n % 2 == 0)
							end
						end
					end
				elseif lo >= yy - 0.2 or (not upright and q.Y > yy) then
					set[p] = true
				end
			end
		end
	end
	for _, p in ipairs(workspace:WaitForChild("DGUS"):GetDescendants()) do
		if p:IsA("BasePart") and p.Anchored then
			local q = p.Position
			if q.X > BLOCK[1] and q.X < BLOCK[3] and q.Z > BLOCK[2] and q.Z < BLOCK[4] then
				local cf, sz = p.CFrame, p.Size
				local long = math.max(sz.X, sz.Z)
				if p.Name == "AtticColumn" then
					cutOne(p, cf, sz, y + math.clamp(math.noise(q.X * 0.31, q.Z * 0.31, 7.7) * 12, -4, 5))
				elseif long > 6 and p:IsA("Part") and p.Shape == Enum.PartType.Block and math.abs(cf.UpVector.Y) > 0.999
					and q.Y - sz.Y / 2 < y + 8 and q.Y + sz.Y / 2 > y - 8 then
					-- a wall across the cut: in slabs ~3.5 studs wide, each cut at its own height, so the top is jagged
					local alongV, L = cf.RightVector, sz.X
					if sz.Z > sz.X then
						alongV, L = cf.LookVector, sz.Z
					end
					local m = math.min(math.ceil(L / 3.5), 40)
					for k = 1, m do
						local c = q + alongV * ((k - 0.5) / m - 0.5) * L
						local ssz = sz.X >= sz.Z and Vector3.new(L / m, sz.Y, sz.Z) or Vector3.new(sz.X, sz.Y, L / m)
						local scf = cf.Rotation + c
						local yk = y + math.clamp(math.noise(c.X * 0.5, c.Z * 0.5, 1.3) * 9 + math.noise(c.X * 1.9, c.Z * 1.9, 5.1) * 5, -8, 8)
						local piece = p
						if k > 1 then
							piece = p:Clone()
							piece:ClearAllChildren()
							piece.Parent = p.Parent
							table.insert(R.clones, piece)
						end
						piece.Size, piece.CFrame = ssz, scf
						cutOne(piece, scf, ssz, yk)
					end
					table.insert(R.cut, { p, cf, sz }) -- (last: restores the whole wall)
				else
					cutOne(p, cf, sz, y)
				end
			end
		end
	end
	local root = Instance.new("Folder")
	root.Name = "ConsulRoof"
	root.Parent = workspace
	R.root = root
	-- broken up as it goes: the top in chunks (CHUNK studs square, each its whole height), each welded to a root of
	-- its own at its foot, which is what moves (and replicates) - it tips over that
	local A = Map.Consul
	local mid = Vector3.new(A.Dais.X, 0, A.Dais.Z)
	local bx = A.Bounds
	local ground = A.Floor - 46.5 -- (the plateau the mansion stands on)
	local byKey = {}
	R.chunks = {}
	for p in pairs(set) do
		local q = p.Position
		local key = math.floor((q.X - BLOCK[1]) / CHUNK) .. "," .. math.floor((q.Z - BLOCK[2]) / CHUNK)
		local c = byKey[key]
		if not c then
			local ix, iz = math.floor((q.X - BLOCK[1]) / CHUNK), math.floor((q.Z - BLOCK[2]) / CHUNK)
			c = { parts = {}, fx = {}, sum = Vector3.zero, low = math.huge, seed = 1 + ix * 7919 + iz * 104729 }
			byKey[key] = c
			table.insert(R.chunks, c)
		end
		table.insert(c.parts, p)
		c.sum += q
		c.low = math.min(c.low, q.Y - p.Size.Y / 2)
		table.insert(R.top, { p, p.CFrame, p.CanCollide, p.Transparency, p.CanQuery })
		if CollectionService:HasTag(p, "RotLimb") then -- (the arms grown out of it go with it: the clients drop theirs)
			CollectionService:RemoveTag(p, "RotLimb")
			table.insert(R.limbs, p)
		end
		for _, j in ipairs(p:GetJoints()) do -- (its own joints let go: its chunk's root holds it now)
			if j.Enabled then
				j.Enabled = false
				table.insert(R.joints, j)
			end
		end
		for _, d in ipairs(p:GetDescendants()) do
			if d:IsA("Light") or d:IsA("ParticleEmitter") or d:IsA("Fire") then
				table.insert(R.fx, { d, d.Enabled })
				table.insert(c.fx, d)
			end
		end
	end
	for _, c in ipairs(R.chunks) do
		local rng = Random.new(c.seed) -- (its own, from where it is: it breaks the same way every time)
		local at = c.sum / #c.parts
		c.base = Vector3.new(at.X, c.low, at.Z)
		local out = flat(at - mid)
		local r = out.Magnitude
		out = r > 0.5 and out.Unit or dir
		local inside = at.X > bx[1] + 2 and at.X < bx[3] - 2 and at.Z > bx[2] + 2 and at.Z < bx[4] - 2
		if inside then -- over the arena: it caves in onto the floor (pushed clear of the dais)
			c.vel = out * (r < 18 and rng:NextNumber(10, 18) or rng:NextNumber(2, 8)) + dir * 4 + Vector3.new(0, rng:NextNumber(0, 5), 0)
			c.floor = A.Floor + 0.5
		else -- the walls and everything outside: thrown off the building, down to the ground
			c.vel = out * rng:NextNumber(14, 28) + dir * 8 + Vector3.new(0, rng:NextNumber(0, 8), 0)
			c.floor = ground
		end
		c.axis = Vector3.yAxis:Cross(out).Unit -- (tipping outwards, over its foot)
		c.spin = rng:NextNumber(0.6, 1.6) * (inside and 0.7 or 1)
		c.wobble = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)).Unit
		c.delay = 0.15 + rng:NextNumber(0, 0.45) + (inside and 0.2 or 0) + math.max(0, c.low - y) * 0.004
		c.root = Instance.new("Part")
		c.root.Name = "ConsulRoofChunk"
		c.root.Anchored, c.root.CanCollide, c.root.CanQuery, c.root.CanTouch, c.root.Transparency = true, false, false, false, 1
		c.root.Size = Vector3.one
		c.root.CFrame = CFrame.new(c.base)
		c.root.Parent = root
		for _, p in ipairs(c.parts) do
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = c.root, p
			w.Parent = c.root
			p.CanCollide = false
			p.Anchored = false
		end
	end
	return R
end

-- the top coming down, t s after the cut: it all sags a little at once, then breaks up - each chunk in its turn
-- tips over its foot and falls, and where it hits (the arena floor, or the ground outside) it's gone in a cloud of
-- dust and stone
local GRAVITY = 110
local function collapse(R, t)
	local settle = -1.2 * math.min(t / 0.12, 1)
	local lastHit = R.lastHit or 0
	for _, c in ipairs(R.chunks) do
		if not c.gone then
			local s = math.max(0, t - c.delay)
			local d = c.vel * s + Vector3.new(0, settle - 0.5 * GRAVITY * s * s, 0)
			if c.base.Y + d.Y <= c.floor then
				c.gone = true
				for _, p in ipairs(c.parts) do
					p.Transparency, p.CanQuery = 1, false
				end
				for _, f in ipairs(c.fx) do
					f.Enabled = false
				end
				local at = Vector3.new(c.base.X + d.X, c.floor + 1, c.base.Z + d.Z)
				burst(at, Color3.fromRGB(62, 54, 52), 36, 1.4, 24)
				burst(at, PURPLE_CORE, 10, 0.6, 18)
				if t - lastHit > 0.12 then -- (not every one: a roar of them, not a click-track)
					lastHit = t
					playSound(c.root, SOUNDS.Impact, 1.6, 0.25 + math.random() * 0.2)
					FxRemote:FireAllClients("Shake", at, 0.7)
				end
			else
				c.root.CFrame = CFrame.new(c.base + d) * CFrame.fromAxisAngle(c.axis, c.spin * s) * CFrame.fromAxisAngle(c.wobble, 0.3 * s)
			end
		end
	end
	R.lastHit = lastHit
end

local function hideRoof(R)
	if R.hidden then
		return
	end
	R.hidden = true
	for _, c in ipairs(R.chunks) do
		c.gone = true
	end
	for _, e in ipairs(R.top) do
		e[1].Transparency, e[1].CanQuery = 1, false
	end
	for _, f in ipairs(R.fx) do
		f[1].Enabled = false
	end
end

local function restoreRoof()
	local R = ruin
	ruin = nil
	if rubble then
		rubble:Destroy()
		rubble = nil
	end
	if not R then
		return
	end
	for _, e in ipairs(R.top) do
		e[1].Anchored = true
	end
	R.root:Destroy()
	for _, e in ipairs(R.top) do
		e[1].CFrame, e[1].CanCollide, e[1].Transparency, e[1].CanQuery = e[2], e[3], e[4], e[5]
	end
	for _, p in ipairs(R.limbs) do
		CollectionService:AddTag(p, "RotLimb")
	end
	for _, j in ipairs(R.joints) do
		j.Enabled = true
	end
	for _, f in ipairs(R.fx) do
		f[1].Enabled = f[2]
	end
	for _, c in ipairs(R.cut) do
		c[1].Size, c[1].CFrame = c[3], c[2]
	end
	for _, c in ipairs(R.clones) do
		c:Destroy()
	end
end

-- the pieces of roof that come down into the arena: where each lands, laid out ahead (so a skip can drop the rest at once)
local function planRubble()
	local A = Map.Consul
	local rng = Random.new(4242) -- (the same fall every time)
	local list = {}
	for i = 1, C.Rise.Rubble do
		local a = (i + rng:NextNumber(-0.35, 0.35)) / C.Rise.Rubble * math.pi * 2
		local r = rng:NextNumber(19, 42) -- (off the dais; some out past the columns)
		local size = Vector3.new(rng:NextNumber(4, 9), rng:NextNumber(2.5, 5), rng:NextNumber(4, 9))
		local at = Vector3.new(A.Dais.X + math.cos(a) * r, A.Floor + size.Y * 0.35, A.Dais.Z + math.sin(a) * r)
		local tilt = CFrame.Angles(rng:NextNumber(-0.35, 0.35), rng:NextNumber(0, math.pi * 2), rng:NextNumber(-0.35, 0.35))
		list[i] = { cf = CFrame.new(at) * tilt, size = size, delay = 0.35 + (i - 1) * 0.16 + rng:NextNumber(0, 0.1) }
	end
	return list
end
local function dropRubble(b, r, instant)
	if r.part or boss.gen ~= b.gen then
		return
	end
	local p = Instance.new("Part")
	p.Name = "ConsulRubble"
	p.Anchored, p.Size, p.Material, p.Color = true, r.size, Enum.Material.Slate, Color3.fromRGB(30, 27, 28)
	p.CFrame = instant and r.cf or r.cf * CFrame.new(0, 70, 0) * CFrame.Angles(1.2, 0, 0.8)
	p.Parent = ruinFolder()
	r.part = p
	if not instant then
		local from, t0 = p.CFrame, now()
		while not b.skip and boss.gen == b.gen and p.Parent do
			task.wait()
			local k = math.min((now() - t0) / 0.65, 1)
			p.CFrame = from:Lerp(r.cf, k * k)
			if k >= 1 then
				break
			end
		end
		if boss.gen ~= b.gen or not p.Parent then
			return
		end
		p.CFrame = r.cf
		if not b.skip then
			burst(r.cf.Position, Color3.fromRGB(50, 40, 56), 30, 0.7, 16)
			playSound(p, SOUNDS.Impact, 1.2, 0.3 + math.random() * 0.15)
			FxRemote:FireAllClients("Shake", r.cf.Position, 0.8)
		end
	end
	blaze(r.cf.Position + Vector3.new(0, r.size.Y * 0.5, 0), math.max(r.size.X, r.size.Z) * 0.9, true)
end

local function hideChars(held, on) -- (the held players, out of his cutscene's way: kept where they are, unseen)
	for _, hrp in pairs(held) do
		local char = hrp.Parent
		if char then
			for _, d in ipairs(char:GetDescendants()) do
				if d:IsA("BasePart") or d:IsA("Decal") then
					if on then
						d:SetAttribute("CutHide", d.Transparency)
						d.Transparency = 1
					elseif d:GetAttribute("CutHide") then
						d.Transparency = d:GetAttribute("CutHide")
						d:SetAttribute("CutHide", nil)
					end
				end
			end
		end
	end
end

-- his aura from the rise on: purple sparks off him, and their light (strength k: 0-1)
local function aura(b, k)
	local e, l = b.root:FindFirstChild("RiseAura"), b.root:FindFirstChild("RiseLight")
	if not e then
		e = Instance.new("ParticleEmitter")
		e.Name = "RiseAura"
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Lifetime, e.Speed, e.SpreadAngle = NumberRange.new(0.8, 1.6), NumberRange.new(3, 8), Vector2.new(180, 180)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5 * S), NumberSequenceKeypoint.new(1, 0) })
		e.Color = ColorSequence.new(FIRE, FIRE_DEEP)
		e.LightEmission, e.Acceleration = 1, Vector3.new(0, 10, 0)
		e.Parent = b.root
		l = Instance.new("PointLight")
		l.Name = "RiseLight"
		l.Color, l.Range = FIRE, 40
		l.Parent = b.root
	end
	e.Rate = 40 + 230 * k
	l.Brightness = 1.5 + 5 * k
end

-- felled: he comes apart where he stands - the same pieces he lay in at first, each limb loose and tumbling, flung
-- a little out from him (they knock against the floor and walls, not each other, nor you)
local function fallApart(b)
	armsTo(b, "Reach", 0) -- (the layout the pieces are cut to: the one he was first put together in)
	RunService.Heartbeat:Wait()
	local G = scatter(b)
	b.ghost = G
	local from = b.root.CFrame
	showReal(b, false)
	local rng = Random.new()
	G.welds = {}
	for _, g in pairs(G.groups) do
		local main = g.parts[1][1]
		for _, e in ipairs(g.parts) do
			local c = e[1]
			if c ~= main then
				local w = Instance.new("WeldConstraint")
				w.Part0, w.Part1 = main, c
				w.Parent = main
				table.insert(G.welds, w)
			end
			c.CanCollide, c.CollisionGroup = true, "ConsulPieces"
		end
		for _, e in ipairs(g.parts) do
			e[1].Anchored = false
		end
		pcall(function()
			main:SetNetworkOwner(nil)
		end)
		local out = flat(g.pivot.Position - from.Position)
		out = out.Magnitude > 0.1 and out.Unit or Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)).Unit
		main.AssemblyLinearVelocity = out * rng:NextNumber(6, 14) + Vector3.new(0, rng:NextNumber(4, 12), 0)
		main.AssemblyAngularVelocity = Vector3.new(rng:NextNumber(-6, 6), rng:NextNumber(-4, 4), rng:NextNumber(-6, 6))
	end
	return G, from
end

-- ...and, for his rise (under the screen's dip to black), stilled and laid out where his cutscene wants them: the
-- same places every time - his intro's own layout round the dais (scatter's, seeded), the head on the floor before
-- it - whatever the ragdoll did; their places on him moved to his dais, and set off in turn to crawl back to it
local function gather(b, G, from)
	for _, w in ipairs(G.welds) do
		w:Destroy()
	end
	local T = b.home * from:Inverse()
	for _, g in pairs(G.groups) do
		for _, e in ipairs(g.parts) do
			e[1].Anchored, e[1].CanCollide = true, false
		end
		g.pivot = T * g.pivot
	end
	for i, name in ipairs(ORDER) do
		local g = G.groups[name]
		if g then
			g.delay = 0.3 + (i - 1) * 0.3
		end
	end
	local head = G.groups.Head
	if head then
		local A = Map.Consul
		local facing = flat(b.home.LookVector).Unit
		local at = Vector3.new(A.Dais.X, A.Floor + 0.5 * S, A.Dais.Z) + facing * 16
		head.start = CFrame.new(at) * turnFrom(facing, -facing) * CFrame.Angles(0, 0, 0.6)
		head.delay, head.crawl, head.rise, head.seed = 1.6, 2.4, 1.1, 37
	end
	place(G, function(g)
		return g.start
	end)
	b.root.CFrame = b.home
end

local function riseRun(b)
	if boss.gen ~= b.gen or boss.state ~= "fight" then
		return
	end
	boss.state = "rising" -- (the fight loop and any attack stop: they run only while "fight")
	-- back above 0 at once: every client's Puppeteer stops posing a rig at 0 health (no poses, no gait), so through his
	-- whole cutscene he'd stay frozen however he fell - mid-crawl, on all fours. (Hits slide off him while he rises.)
	b.hum.Health = 1
	local R = C.Rise
	local A = Map.Consul
	ReplicatedStorage:SetAttribute("BossActive", false)
	ReplicatedStorage:SetAttribute("Music", "consulfall") -- (the client: phase 1's piece fades over 1 s, then silence till the cutscene's)
	nightfall()
	-- "Busy" all through it: the clients' gait (M.Gait) never crawls him while the server is posing and moving him
	-- for the camera - only once the fight is back on. (And nothing else that takes over his limbs.)
	b.model:SetAttribute("Busy", true)
	b.model:SetAttribute("Stilt", nil)
	b.model:SetAttribute("Ball", nil)
	b.model:SetAttribute("HeldBy", nil)
	b.model:SetAttribute("FaceAt", nil)
	for _, tr in pairs(b.trails) do
		tr.Enabled = false
	end
	local function alive()
		return boss.gen == b.gen and boss.state == "rising"
	end
	burst(b.root.Position, Color3.fromRGB(60, 50, 44), 40, 0.8, 18)
	playSound(b.root, C.SlamSound, 1.1, 0.8)
	FxRemote:FireAllClients("Shake", b.root.Position, 0.9)
	local G, from = fallApart(b)
	task.wait(R.Lie)
	if not alive() then
		return
	end
	local watchers = playersInAttic()
	if #watchers == 0 then
		return -- (the watchdog puts him back in pieces)
	end
	-- a dip to black, and under it the pieces laid out where the cutscene starts them
	for _, w in ipairs(watchers) do
		FxRemote:FireClient(w[1], "Flash", Color3.new(0, 0, 0), 1.2, 0.35)
	end
	task.wait(0.2)
	if not alive() then
		return
	end
	gather(b, G, from)

	-- THE CUTSCENE, round his dais (G: its top), framed off the way he faces there; every camera inside the ring of
	-- columns (radius 34: none is ever further than 27 out)
	local G0 = Vector3.new(b.home.X, A.Dais.Y, b.home.Z)
	local fwd = flat(b.home.LookVector).Unit
	local right = fwd:Cross(Vector3.yAxis)
	local function at(f, r, y)
		return G0 + fwd * f + right * r + Vector3.new(0, y, 0)
	end
	local look = CFrame.lookAt
	local cutY = A.Floor + R.Cut
	local AS = COMBINE * R.Slow -- (the assembly's length, slowed)
	local head = b.model:FindFirstChild("Head") -- (once he's whole, the shots are kept on it: wherever his pose holds it)
	local V = Vector3.new
	local shots = {
		-- high over the arena, creeping: his pieces dragging themselves back in from where they fell
		{ look(at(24, 8, 20), at(0, 0, 1)), look(at(20, -2, 16), at(0, 0, 1)), AS * 0.38 },
		-- down on the floor with them, the dais ahead: a limb hauling itself past
		{ look(at(-14, 12, 1.2), at(0, 0, 2)), look(at(-11, 9, 1.5), at(0, 0, 3)), AS * 0.3 },
		-- lower and close: knitting together, lifted up into him
		{ look(at(16, -10, 4), at(0, 0, 6)), look(at(13, -8, 6), at(0, 0, 9)), AS * 0.32 },
		-- whole, slumped: a slow push in from low, on his body
		{ at(15, 2, 3), at(11, 1, 3), 3.0, head, V(0, -4, 0) },
		-- he draws himself up: low before him, looking up at him
		{ at(10, 0, 1.5), at(12, 3, 2), 3.6, head, V(0, -1, 0) },
		-- the line: his face, close, at its own height (the camera placed off his head, not the floor)
		{ fwd * 9 + right * 2 - V(0, 1, 0), fwd * 7.5 + right * 1.5 - V(0, 0.5, 0), 3.6, head, V(0, 0, 0), true },
		-- the power: pulling back as it swells in him
		{ at(14, 0, 5), at(24, -8, 9), 4.2, head, V(0, -3, 0) },
		-- the cut: wide, the line of it running round the walls behind him
		{ look(at(24, 5, 5), at(0, 0, R.Cut)), look(at(25, 6, 6), at(0, 0, R.Cut)), 1.6 },
		-- the top goes: low by him, looking up and out over his head as it slides away
		{ look(at(-6, 8, 3), at(30, 0, 40)), look(at(-7, 9, 2), at(40, 0, 26)), 3.4 },
		-- and him, in the blazing ruin
		{ at(20, 10, 6), at(17, 7, 5), 2.6, head, V(0, -3, 0) },
	}
	local total = 0
	for _, sh in ipairs(shots) do
		total += sh[3]
	end
	local held = {}
	for _, w in ipairs(watchers) do
		local pl, hrp = w[1], w[2]
		local st = states[pl]
		if st then
			Core.setAction(st, now(), total, total, total)
			st.healing = false
			Core.cancelSwing(st)
		end
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.Anchored = true
		held[pl] = hrp
		FxRemote:FireClient(pl, "Grabbed", total)
		FxRemote:FireClient(pl, "Cutscene", shots, "ConsulSkip")
	end
	hideChars(held, true)
	b.skip, b.held = nil, held
	ReplicatedStorage:SetAttribute("MusicIntro", total) -- (the client starts Config.Consul.RiseMusic so it ends as this does)
	ReplicatedStorage:SetAttribute("Music", "consulrise")
	local fx = {} -- (the cutscene's own parts: gone at its end)
	local t0 = now()
	local function till(t) -- wait until t s into it (cut short by a skip); false if he's gone meanwhile
		while now() - t0 < t and not b.skip and alive() do
			task.wait()
		end
		return alive()
	end
	local function glow(shape, size, color, tr)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Material, p.Color, p.Size, p.Transparency, p.Shape = Enum.Material.Neon, color, size, tr, shape
		p.Parent = workspace
		table.insert(fx, p)
		return p
	end
	local plan = planRubble()
	local stand = b.home
	local function play() -- (each beat skipped once b.skip is set; what's left is put right after it)
		-- back together (COMBINE s): the pieces crawl in to the dais and lift up into him, and he's shown, whole
		if not assemble(b, G0 + fwd * 20 + Vector3.new(0, 3, 0), true) then
			return false
		end
		if not b.skip then
			bodyPose(b, "XUnfold", 0.25)
		end
		if not till(AS + 1.4) then
			return false
		end
		if not b.skip then
			playSound(b.root, SOUNDS.Groan, 0.7, 0.45)
		end
		-- he draws himself up, slow, into his righteous stance
		if not till(AS + 3.0) then
			return false
		end
		if not b.skip then
			bodyPose(b, "XRighteous", 3.0)
			armsTo(b, "Stance", 2.6)
		end
		if not till(AS + 6.2) then
			return false
		end
		if not b.skip then
			playSound(b.root, SOUNDS.Unsheath, 1, 0.5)
		end
		-- the line
		if not till(AS + 6.8) then
			return false
		end
		if not b.skip then
			for pl in pairs(held) do
				FxRemote:FireClient(pl, "Say", C.Name, R.Line)
			end
		end
		-- the power: the room goes purple, and it swells in him
		if not till(AS + 10.2) then
			return false
		end
		boss.purple = true -- (M.init's loop tints the attic for whoever's in it: the client's "ConsulTint")
		for pl in pairs(held) do
			pl:SetAttribute("ConsulTint", true)
		end
		if not b.skip then
			playSound(b.root, SOUNDS.Groan, 1.3, 0.3)
			bodyPose(b, "XCast", 2.2)
			armsTo(b, "Cast", 2.2)
			local tal = b.model:FindFirstChild("TalismanOrb")
			local orb = glow(Enum.PartType.Ball, Vector3.one, PURPLE, 0.2)
			local t1 = now()
			while now() - t1 < 3.8 and not b.skip and alive() do
				task.wait()
				local k = math.min((now() - t1) / 3.8, 1)
				local shake = Vector3.new(0, math.noise(k * 60, 1) * 0.25 * S * k, 0) -- (up and down only: never moved off his mark)
				b.root.CFrame = stand + Vector3.new(0, 2.5 * k, 0) + shake
				orb.Size = Vector3.one * (0.6 + 4 * k * k + 0.4 * math.sin(k * 90) * k) * S
				orb.Position = tal and tal.Position or b.root.Position + fwd * 4 * S
				aura(b, k)
				if k > 0.5 and math.random() < 0.06 then
					FxRemote:FireAllClients("Shake", G0, 0.4 * k)
				end
			end
		end
		-- the cut: one sweep, a whole circle, at his shoulder, through every wall and column
		if not till(AS + 14.0) then
			return false
		end
		if not b.skip then -- the breath before it: a crackle drawn in, sinking, the orb at its brightest
			playSound(b.root, SOUNDS.Lightning[1], 2.5, 0.45)
			playSound(b.root, SOUNDS.Unsheath, 2, 0.3)
		end
		if not till(AS + 14.4) then
			return false
		end
		if not b.skip then
			local halo = glow(Enum.PartType.Block, Vector3.new(9, 9, 150), PURPLE, 0.75)
			local outer = glow(Enum.PartType.Block, Vector3.new(4.5, 4.5, 150), PURPLE, 0.1)
			local core = glow(Enum.PartType.Block, Vector3.new(1.6, 1.6, 150), Color3.fromRGB(245, 225, 255), 0)
			local flare = glow(Enum.PartType.Ball, Vector3.one * 12, PURPLE_CORE, 0.1)
			local light = Instance.new("PointLight")
			light.Color, light.Range, light.Brightness = FIRE, 60, 12
			light.Parent = flare
			-- the blast: everything at once, low and huge, crackling
			playSound(b.root, SOUNDS.FireHit, 3, 0.55)
			playSound(b.root, C.SlamSound, 3, 0.45)
			playSound(b.root, SOUNDS.Impact, 2.5, 0.2)
			playSound(b.root, SOUNDS.Lightning[2], 3, 0.7)
			task.delay(0.12, playSound, b.root, SOUNDS.Lightning[3], 3, 0.6)
			for pl in pairs(held) do
				FxRemote:FireClient(pl, "Flash", Color3.fromRGB(215, 170, 255), 0.9)
			end
			FxRemote:FireAllClients("Shake", G0, 2.5)
			local o = Vector3.new(G0.X, cutY, G0.Z)
			local a0 = math.atan2(-fwd.X, -fwd.Z)
			local p0 = b.root.Position
			local walls = RaycastParams.new()
			walls.FilterType = Enum.RaycastFilterType.Include
			walls.FilterDescendantsInstances = { workspace:WaitForChild("DGUS") }
			local t1, lastSpark = now(), 0
			while not b.skip and alive() do
				task.wait()
				local k = math.min((now() - t1) / 0.4, 1)
				local a = a0 + 2 * math.pi * k
				local d = Vector3.new(-math.sin(a), 0, -math.cos(a))
				local beamCF = CFrame.lookAt(o + d * 75, o + d * 150)
				halo.CFrame, outer.CFrame, core.CFrame = beamCF, beamCF, beamCF
				local pulse = 1 + 0.25 * math.sin(now() * 80)
				halo.Size, outer.Size = Vector3.new(9 * pulse, 9 * pulse, 150), Vector3.new(4.5 * pulse, 4.5 * pulse, 150)
				flare.Position = o
				b.root.CFrame = CFrame.lookAt(p0, p0 + d) -- (he turns with it, a whole circle)
				if now() - lastSpark > 0.03 then -- (sparks and stone flying where it bites into the walls)
					lastSpark = now()
					local hit = workspace:Raycast(o + d * 6, d * 140, walls)
					if hit then
						burst(hit.Position, PURPLE_CORE, 14, 0.6, 30)
						burst(hit.Position, Color3.fromRGB(50, 44, 48), 6, 0.9, 18)
					end
				end
				if k >= 1 then
					break
				end
			end
			-- and gone: it thins away, the flare swelling out over the whole room
			TweenService:Create(halo, TweenInfo.new(0.5), { Size = Vector3.new(0.1, 18, 150), Transparency = 1 }):Play()
			TweenService:Create(outer, TweenInfo.new(0.35), { Size = Vector3.new(0.1, 8, 150), Transparency = 1 }):Play()
			TweenService:Create(core, TweenInfo.new(0.25), { Size = Vector3.new(0.05, 3, 150), Transparency = 1 }):Play()
			TweenService:Create(flare, TweenInfo.new(1.0), { Size = Vector3.one * 90, Transparency = 1 }):Play()
			TweenService:Create(light, TweenInfo.new(1.2), { Brightness = 0 }):Play()
			playSound(b.root, SOUNDS.FireHit, 2.5, 0.35)
			FxRemote:FireAllClients("Shake", G0, 2.5)
		end
		if not alive() then
			return false
		end
		if not ruin then
			ruin = sliceRoof(cutY, fwd)
		end
		-- the top goes, and pieces of it come down round the arena
		if not till(AS + 15.8) then
			return false
		end
		if not b.skip then
			for _, r in ipairs(plan) do
				task.delay(r.delay, dropRubble, b, r, false)
			end
			local t1 = now()
			while not b.skip and alive() and ruin do
				task.wait()
				local t = now() - t1
				collapse(ruin, t)
				if t >= 3.4 then
					break
				end
			end
			if ruin and alive() then
				hideRoof(ruin) -- (gone over the edge)
			end
		end
		-- and he settles into his stance, in the ruin
		if not till(AS + 19.2) then
			return false
		end
		if not b.skip then
			bodyPose(b, "XStance", 0.8)
			armsTo(b, "Stance", 0.8)
			TweenService:Create(b.root, TweenInfo.new(0.8, Enum.EasingStyle.Quad), { CFrame = stand }):Play()
		end
		return till(total)
	end
	local fine = play()
	for _, p in ipairs(fx) do
		p:Destroy()
	end
	if b.skip then
		for pl in pairs(held) do
			if states[pl] then
				Core.setAction(states[pl], now(), 0, 0, 0)
			end
		end
		ReplicatedStorage:SetAttribute("ConsulIntroCut", (ReplicatedStorage:GetAttribute("ConsulIntroCut") or 0) + 1)
	end
	b.held = nil
	hideChars(held, false)
	for pl, hrp in pairs(held) do
		if hrp.Parent then
			hrp.Anchored = false
			pcall(function()
				hrp:SetNetworkOwner(pl)
			end)
		end
	end
	if not (fine and alive()) then
		return
	end
	-- where a skip, or the end, leaves it all: the top gone, the rubble down, the fires lit, him standing in his aura
	boss.purple = true
	if not ruin then
		ruin = sliceRoof(cutY, fwd)
	end
	hideRoof(ruin)
	for _, r in ipairs(plan) do
		dropRubble(b, r, true)
	end
	aura(b, 0)
	b.root.CFrame = stand
	bodyPose(b, "XStance", 0.3)
	armsTo(b, "Stance", 0.3)
	-- phase 2 (its moves aren't built yet: his first's, at full health)
	b.phase2 = true
	for _, d in ipairs(b.model:GetDescendants()) do -- (3x the light off him: eye, rim, aura; the room's own lights stay as they are)
		if d:IsA("Light") then
			d.Brightness *= 3
			if d:IsA("PointLight") or d:IsA("SpotLight") then
				d.Range *= 1.3
			end
		end
	end
	b.hum.MaxHealth = math.floor(C.HP * R.Health + 0.5)
	b.hum.Health = b.hum.MaxHealth
	ReplicatedStorage:SetAttribute("BossMaxHP", b.hum.MaxHealth)
	ReplicatedStorage:SetAttribute("BossHP", b.hum.Health)
	ReplicatedStorage:SetAttribute("BossActive", true)
	ReplicatedStorage:SetAttribute("BossName", C.Name2)
	ReplicatedStorage:SetAttribute("Music", "consul2")
	return true
end

-- the rise, guarded: every frame of it (from his fall to the fight resuming) he's flagged as in a cutscene and
-- nothing that takes over his limbs is left set - whatever any other thread does to him meanwhile; and if it
-- breaks, whoever it holds is let go
local HOLD_OFF = { "Stilt", "Ball", "HeldBy", "FaceAt" }
rise = function(b)
	if boss.gen ~= b.gen or boss.state ~= "fight" then
		return
	end
	local m = b.model
	local guard = RunService.Heartbeat:Connect(function()
		if m:GetAttribute("Cutscene") ~= true then
			m:SetAttribute("Cutscene", true)
		end
		if m:GetAttribute("Busy") ~= true then
			m:SetAttribute("Busy", true)
		end
		for _, k in ipairs(HOLD_OFF) do
			if m:GetAttribute(k) ~= nil then
				m:SetAttribute(k, nil)
			end
		end
	end)
	m:SetAttribute("Cutscene", true)
	local ok, go = pcall(riseRun, b)
	guard:Disconnect()
	if not ok then
		warn("[Consul] rise: " .. tostring(go))
		for pl, hrp in pairs(b.held or {}) do
			if hrp.Parent then
				hrp.Anchored = false
				pcall(function()
					hrp:SetNetworkOwner(pl)
				end)
			end
		end
		hideChars(b.held or {}, false)
		b.held = nil
	end
	if ok and go and boss.gen == b.gen and boss.state == "rising" then
		boss.state = "fight"
		m:SetAttribute("Cutscene", nil)
		m:SetAttribute("Busy", nil)
		fight(b)
	end
end

-- THE MATRIX (Config.Consul.Matrix, phase 2 only): he crawls to the nearest broken column, hauls himself up it in
-- lurches and stands on its stump; raises both catalysts to the open sky (a beam of it up out of the talisman); then
-- Waves times a pattern of the floor's squares glows, brighter and faster, and lasers come down out of the sky on
-- exactly those squares (checkerboard, the other checkerboard, stripes: there's always somewhere to stand). Then
-- he leaps down at you - a ring where he'll land, locked where you stood as he crouched - and lies open a moment
local function matrixRun(b, target, ground, fx, M2)
	local R = ruin
	if not (R and R.stumps and #R.stumps > 0) then
		return
	end
	local A = Map.Consul
	local function alive()
		return boss.gen == b.gen and boss.state == "fight"
	end
	local function glow(shape, size, color, tr)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Material, p.Color, p.Size, p.Transparency, p.Shape = Enum.Material.Neon, color, size, tr, shape
		p.Parent = workspace
		table.insert(fx, p)
		return p
	end
	local function dmg(x)
		return math.max(1, math.floor(x * (C.DamageScale or 1) + 0.5))
	end
	local mid = Vector3.new(A.Dais.X, 0, A.Dais.Z)
	-- the nearest stump, and the foot of it on the arena's side
	local P = b.root.Position
	local st, best = nil, math.huge
	for _, s in ipairs(R.stumps) do
		local d = flat(s - P).Magnitude
		if d < best then
			st, best = s, d
		end
	end
	local inward = flat(mid - st)
	inward = inward.Magnitude > 0.1 and inward.Unit or -flat(b.root.CFrame.LookVector).Unit
	local foot = Vector3.new(st.X, 0, st.Z) + inward * 5
	b.model:SetAttribute("Busy", nil) -- (crawling there: his gait)
	bodyPose(b, "XCrawl", 0.4)
	local t0 = now()
	while true do
		local dt = task.wait()
		if not alive() then
			return
		end
		local p = b.root.Position
		local to = flat(foot - p)
		if to.Magnitude < 1 or now() - t0 > 4 then
			break
		end
		local q = p + to.Unit * math.min(to.Magnitude, C.RollSpeed * 1.3 * dt)
		local down = workspace:Raycast(q + Vector3.new(0, 4 * S, 0), Vector3.new(0, -10 * S, 0), ground)
		local y = down and down.Position.Y + 3 * S or p.Y
		b.root.CFrame = CFrame.lookAt(Vector3.new(q.X, y, q.Z), Vector3.new(q.X, y, q.Z) + to.Unit)
	end
	-- up it: limbs planted on it ("Stilt"), hauled up in lurches, and over the lip onto its top
	local top = Vector3.new(st.X, st.Y + 3 * S, st.Z)
	b.model:SetAttribute("Stilt", true)
	playSound(b.root, SOUNDS.Unsheath, 0.8, 0.5)
	local from = b.root.Position
	local face = CFrame.lookAt(from, Vector3.new(st.X, from.Y, st.Z)).Rotation
	t0 = now()
	local lurch = 0
	while true do
		task.wait()
		if not alive() then
			return
		end
		local k = math.min((now() - t0) / M2.Climb, 1)
		local x = k * 4
		local up = math.min((math.floor(x) + math.clamp(x % 1 * 1.5, 0, 1) ^ 2) / 4, 1)
		if math.floor(x) > lurch and k < 1 then -- (each haul: a scrape, and grit off the column)
			lurch = math.floor(x)
			burst(b.root.Position + face.LookVector * 2 * S, Color3.fromRGB(60, 52, 50), 10, 0.5, 8)
			playSound(b.root, SOUNDS.Impact, 0.6, 0.5)
		end
		local over = ease((k - 0.75) / 0.25)
		local xz = Vector3.new(from.X, 0, from.Z):Lerp(Vector3.new(top.X, 0, top.Z), over)
		b.root.CFrame = CFrame.new(xz.X, from.Y + (top.Y - from.Y) * up, xz.Z) * face
		if k >= 1 then
			break
		end
	end
	-- on top: stood up (and kept so: "Busy", till he's down again), facing the arena
	b.model:SetAttribute("Stilt", nil)
	b.model:SetAttribute("Busy", true)
	b.root.CFrame = CFrame.lookAt(top, Vector3.new(mid.X, top.Y, mid.Z))
	burst(top - Vector3.new(0, 3 * S, 0), Color3.fromRGB(60, 52, 50), 24, 0.7, 14)
	playSound(b.root, C.SlamSound, 0.9, 1)
	-- the catalysts up to the sky, and a beam of it up out of the talisman
	bodyPose(b, "XCast", M2.Raise)
	armsTo(b, "Sky", M2.Raise)
	playSound(b.root, SOUNDS.Lightning[1], 2, 0.5)
	local tal = b.model:FindFirstChild("TalismanOrb")
	local function hand()
		return tal and tal.Position or b.root.Position + Vector3.new(0, 5 * S, 0)
	end
	local sky = glow(Enum.PartType.Block, Vector3.new(0.1, 400, 0.1), PURPLE, 0.2)
	local skyCore = glow(Enum.PartType.Block, Vector3.new(0.1, 400, 0.1), Color3.fromRGB(240, 220, 255), 0)
	local orb = glow(Enum.PartType.Ball, Vector3.one, PURPLE_CORE, 0.1)
	local lamp = Instance.new("PointLight")
	lamp.Color, lamp.Range, lamp.Brightness = FIRE, 50, 6
	lamp.Parent = orb
	local function skyAt(k) -- (k: how thick)
		local h = hand()
		sky.Size, skyCore.Size = Vector3.new(2.4 * k, 400, 2.4 * k), Vector3.new(0.8 * k, 400, 0.8 * k)
		sky.CFrame, skyCore.CFrame = CFrame.new(h + Vector3.new(0, 200, 0)), CFrame.new(h + Vector3.new(0, 200, 0))
		orb.Size = Vector3.one * (1 + 2.5 * k + 0.3 * math.sin(now() * 40)) * S
		orb.Position = h
	end
	t0 = now()
	while now() - t0 < M2.Raise do
		task.wait()
		if not alive() then
			return
		end
		skyAt(math.clamp((now() - t0) / M2.Raise * 1.5 - 0.5, 0, 1))
	end
	playSound(b.root, SOUNDS.FireHit, 2.2, 0.6)
	FxRemote:FireAllClients("Shake", top, 1)

	-- the floor in squares, round his dais, each laid on whatever's really on top there (the dais, its step, the
	-- inlaid rings over the floor: drawn at a fixed height they'd sink under them, and vanish)
	local cell = M2.Cell
	local cells = {}
	local bx = A.Bounds
	local n = math.ceil(math.max(A.Bounds[3] - A.Bounds[1], A.Bounds[4] - A.Bounds[2]) / 2 / cell) + 1
	local floorOnly = RaycastParams.new()
	floorOnly.FilterType = Enum.RaycastFilterType.Include
	floorOnly.FilterDescendantsInstances = { workspace:WaitForChild("DGUS") }
	for i = -n, n - 1 do
		for j = -n, n - 1 do
			local c = Vector3.new(A.Dais.X + (i + 0.5) * cell, 0, A.Dais.Z + (j + 0.5) * cell)
			-- (the whole attic floor now, edges and corners too: staying out at the sides no longer dodges it)
			if c.X > bx[1] + 1 and c.X < bx[3] - 1 and c.Z > bx[2] + 1 and c.Z < bx[4] - 1 then
				local hit = workspace:Raycast(Vector3.new(c.X, A.Floor + 6, c.Z), Vector3.new(0, -10, 0), floorOnly)
				table.insert(cells, { pos = c, i = i, j = j, y = hit and hit.Position.Y or A.Floor })
			end
		end
	end
	local function hot(c, w)
		local m = (w - 1) % 3
		if m == 0 then
			return (c.i + c.j) % 2 == 0
		elseif m == 1 then
			return (c.i + c.j) % 2 == 1
		end
		return c.i % 2 == 0
	end
	for w = 1, M2.Waves do
		local marks = {}
		for _, c in ipairs(cells) do
			if hot(c, w) then
				local m = glow(Enum.PartType.Block, Vector3.new(cell - 0.6, 0.3, cell - 0.6), PURPLE, 0.85)
				m.CFrame = CFrame.new(c.pos.X, c.y + 0.2, c.pos.Z) -- (clear of the surface: never z-fighting it)
				table.insert(marks, { c = c, m = m })
			end
		end
		playSound(b.root, SOUNDS.Lightning[1], 1.5, 0.8)
		-- the telegraph: the squares glowing up, flickering faster as it comes
		local t1 = now()
		while true do
			task.wait()
			if not alive() then
				return
			end
			local k = math.min((now() - t1) / M2.Telegraph, 1)
			local tr = 0.85 - 0.5 * k + 0.08 * math.sin(now() * (10 + 30 * k))
			for _, e in ipairs(marks) do
				e.m.Transparency = tr
			end
			skyAt(1)
			if k >= 1 then
				break
			end
		end
		-- the lasers, down on every one
		local beams = {}
		for i, e in ipairs(marks) do
			local h = 160
			local at = CFrame.new(e.c.pos.X, e.c.y + h / 2, e.c.pos.Z)
			local p = glow(Enum.PartType.Block, Vector3.new(cell - 1.2, h, cell - 1.2), PURPLE, 0.3)
			local core = glow(Enum.PartType.Block, Vector3.new(cell * 0.35, h, cell * 0.35), Color3.fromRGB(240, 220, 255), 0.05)
			p.CFrame, core.CFrame = at, at
			table.insert(beams, p)
			table.insert(beams, core)
			e.m.Color, e.m.Transparency = PURPLE_CORE, 0
			if i % 2 == 0 then
				burst(Vector3.new(e.c.pos.X, e.c.y + 0.5, e.c.pos.Z), PURPLE_CORE, 8, 0.5, 16)
			end
		end
		playSound(b.root, SOUNDS.FireHit, 2.5, 0.75)
		playSound(b.root, SOUNDS.Lightning[2 + (w % 2)], 2.5, 0.9)
		FxRemote:FireAllClients("Shake", Vector3.new(mid.X, A.Floor, mid.Z), 1.2)
		local hit = {}
		t1 = now()
		while now() - t1 < M2.Fire do
			task.wait()
			if not alive() then
				return
			end
			skyAt(1.3)
			for _, pw in ipairs(playersInAttic()) do
				local pl, hrp = pw[1], pw[2]
				if not hit[pl] then
					for _, e in ipairs(marks) do
						local d = hrp.Position - e.c.pos
						if math.abs(d.X) < cell / 2 and math.abs(d.Z) < cell / 2 and hrp.Position.Y - e.c.y < 8 then
							hit[pl] = true
							Core.damagePlayer(pl, dmg(M2.Damage), hrp.Position + Vector3.new(0, 6, 0), "Large")
							break
						end
					end
				end
			end
		end
		-- gone: the lasers thin out, the squares left scorched a moment
		for _, p in ipairs(beams) do
			TweenService:Create(p, TweenInfo.new(0.25), { Transparency = 1, Size = Vector3.new(0.2, p.Size.Y, 0.2) }):Play()
		end
		for _, e in ipairs(marks) do
			e.m.Color = Color3.fromRGB(40, 12, 60)
			TweenService:Create(e.m, TweenInfo.new(M2.Gap + 0.4), { Transparency = 1 }):Play()
		end
		t1 = now()
		while now() - t1 < M2.Gap do
			task.wait()
			if not alive() then
				return
			end
			skyAt(1)
		end
	end
	sky.Transparency, skyCore.Transparency, orb.Transparency = 1, 1, 1
	lamp.Enabled = false

	-- the leap: crouched, a ring where you stood, then down onto it
	armsTo(b, "Stance", 0.3)
	bodyPose(b, "XClutch", 0.35)
	local land = target.Parent and target.Position or mid
	local bx = A.Bounds
	land = Vector3.new(math.clamp(land.X, bx[1] + 4, bx[3] - 4), 0, math.clamp(land.Z, bx[2] + 4, bx[4] - 4))
	local hitL = workspace:Raycast(Vector3.new(land.X, A.Floor + 30, land.Z), Vector3.new(0, -40, 0), ground)
	local spot = Vector3.new(land.X, hitL and hitL.Position.Y or A.Floor, land.Z)
	local ring = glow(Enum.PartType.Cylinder, Vector3.new(0.15, M2.LeapRadius * 2, M2.LeapRadius * 2), PURPLE, 0.6)
	ring.CFrame = CFrame.new(spot + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	playSound(b.root, SOUNDS.Unsheath, 1.2, 0.4)
	t0 = now()
	while now() - t0 < M2.Crouch do
		task.wait()
		if not alive() then
			return
		end
	end
	from = b.root.Position
	local to = spot + Vector3.new(0, 3 * S, 0)
	local dir = flat(to - from)
	dir = dir.Magnitude > 0.1 and dir.Unit or flat(b.root.CFrame.LookVector).Unit
	bodyPose(b, "XShow", 0.2)
	t0 = now()
	while true do
		task.wait()
		if not alive() then
			return
		end
		local k = math.min((now() - t0) / M2.Air, 1)
		local pos = from:Lerp(to, k) + Vector3.new(0, M2.Arc * 4 * k * (1 - k), 0)
		b.root.CFrame = CFrame.lookAt(pos, pos + dir)
		ring.Transparency = 0.6 - 0.45 * k
		if k >= 1 then
			break
		end
	end
	-- down
	bodyPose(b, "XSlash", 0.1)
	burst(spot, Color3.fromRGB(60, 50, 44), 44, 0.9, 22)
	burst(spot, PURPLE_CORE, 18, 0.6, 20)
	Core.shockwave(spot, 12)
	playSound(b.root, C.SlamSound, 1.6, 0.8)
	playSound(b.root, SOUNDS.Impact, 1.4, 0.3)
	FxRemote:FireAllClients("Shake", spot, 1.4)
	for _, pw in ipairs(playersInAttic()) do
		local pl, hrp = pw[1], pw[2]
		if flat(hrp.Position - spot).Magnitude < M2.LeapRadius and hrp.Position.Y - spot.Y < 7 then
			Core.damagePlayer(pl, dmg(M2.LeapDamage), spot, "Knockdown")
		end
	end
	ring.Transparency = 1
	-- and open a moment
	t0 = now()
	while now() - t0 < M2.Recover do
		task.wait()
		if not alive() then
			return
		end
	end
	bodyPose(b, "XStance", 0.4)
end

matrix = function(b, target, ground)
	local fx = {}
	local ok, err = pcall(matrixRun, b, target, ground, fx, C.Matrix)
	for _, p in ipairs(fx) do
		p:Destroy()
	end
	if not ok then
		warn("[Consul] matrix: " .. tostring(err))
	end
	b.model:SetAttribute("Stilt", nil)
	if boss.gen == b.gen and boss.state == "fight" then
		armsTo(b, "Stance", 0.3)
		b.model:SetAttribute("Busy", nil)
	end
end

local function start(watchers)
	if boss.state ~= "dormant" or not boss.current.ghost then
		return
	end
	boss.state = "intro"
	local b = boss.current
	b.model:SetAttribute("Busy", true) -- (his cutscene: never crawling, whatever the server moves him by; the fight clears it)
	b.model:SetAttribute("Cutscene", true)
	seal(true)
	snuff(true)
	task.spawn(function()
		local lookAt = watchers[1][2].Position
		local ok = cutscene(b, lookAt, watchers)
		if not ok then
			return
		end
		ReplicatedStorage:SetAttribute("BossName", C.Name)
		ReplicatedStorage:SetAttribute("BossMaxHP", b.hum.MaxHealth)
		ReplicatedStorage:SetAttribute("BossHP", b.hum.Health)
		ReplicatedStorage:SetAttribute("BossActive", true)
		ReplicatedStorage:SetAttribute("Music", "consul") -- (Config.Consul.Music: the placeholder)
		boss.state = "fight"
		b.model:SetAttribute("Cutscene", nil)
		b.model:SetAttribute("Busy", nil)
		fight(b)
	end)
end

local function reset()
	if boss.state == "dead" or boss.state == "dormant" then
		return
	end
	local b = boss.current
	if b and b.ghost then
		b.ghost.folder:Destroy()
	end
	if boss.model then
		boss.model:Destroy()
	end
	ReplicatedStorage:SetAttribute("BossActive", false)
	ReplicatedStorage:SetAttribute("Music", "none")
	seal(false)
	snuff(false)
	boss.purple = false
	restoreRoof()
	restoreDay()
	spawn()
end

function M.init(core)
	Core = core
	Map, FxRemote, states, now, bodyPose, aliveChar, playSound, SOUNDS, burst = core.Map, core.FxRemote, core.states, core.now, core.bodyPose, core.aliveChar, core.playSound, core.SOUNDS, core.burst
	if not Map.Consul then
		return
	end
	local PhysicsService = game:GetService("PhysicsService")
	pcall(function()
		PhysicsService:RegisterCollisionGroup("ConsulPieces")
	end)
	for _, g in ipairs({ "ConsulPieces", "PlayerRoot", "EnemyRoot", "Limbs", "HitQuery" }) do
		PhysicsService:CollisionGroupSetCollidable("ConsulPieces", g, false)
	end
	-- hits find him, but slide off until he's whole and standing
	core.registerTarget(function(model)
		if not boss.model or boss.model ~= model then
			return nil
		end
		return {
			owner = boss,
			actor = boss.current,
			maxPoise = 1e9,
			freeze = false,
			evade = function()
				return boss.state ~= "fight"
			end,
		}
	end)
	-- a held player holding Space through the cutscene
	local skip = Instance.new("RemoteEvent")
	skip.Name = "ConsulSkip"
	skip.Parent = ReplicatedStorage
	skip.OnServerEvent:Connect(function(pl)
		local b = boss.current
		if (boss.state == "intro" or boss.state == "rising") and b and b.held and b.held[pl] then
			b.skip = true
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.25)
			if boss.state == "dormant" then
				local here = playersInAttic()
				if #here > 0 then
					start(here)
				end
			elseif boss.state == "intro" or boss.state == "fight" or boss.state == "rising" then
				if #playersInAttic() == 0 then -- everyone up here died (or left): back to pieces
					reset()
				end
			end
			for _, pl in ipairs(Players:GetPlayers()) do -- (the ruin's purple, for whoever's in it: the client's ConsulTint)
				local _, _, hrp = aliveChar(pl)
				local tint = boss.purple == true and hrp ~= nil and inAttic(hrp.Position)
				if pl:GetAttribute("ConsulTint") ~= tint then
					pl:SetAttribute("ConsulTint", tint)
				end
			end
		end
	end)
end

M.spawn = spawn
M.reset = reset
M.brighten = function(dur) -- (init.server's drawbridge cutscene: the sky is day by its end, however far the 45 s fade has got)
	restoreDay(dur, true)
end
M.devWound = function() -- (dev menu) one hit from his rise (or, after it, his death)
	if boss.state == "fight" and boss.hum and boss.hum.Health > 0 then
		boss.hum.Health = 1
	end
end
M.state = function()
	return boss.state
end

return M
