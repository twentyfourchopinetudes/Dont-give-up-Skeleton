--!nonstrict
-- OCULAST, THE BLINDED USHER: optional miniboss of the Blind Chapel, through the
-- Dim Yard's west wall.
--
-- She kneels at the overgrown altar with her back to the door. She is blind:
-- walk up quietly and you can get close (even land a hit - she answers it at
-- once with a turning reap); run, roll or drink a flask nearby and she hears you.
-- In the fight she is fast and hits very hard, but every attack is told by the
-- body: the growth over her eyes flares as she hisses, her stance winds up, the
-- haft scrapes sparks off the stone. No markers.
--
-- FIRST LIFE (the usher: measured, deliberate)
--   Spin      floats a hair off the floor, blade straight out, and turns slowly round
--             and round while drifting after you (speeds in Config.Usher.Spin)
--   Chop      raised high and brought down into the stone (sometimes held late)
--   Lunge     drops low, drags the haft along the floor, rushes in and reaps upward
--   Turnabout a turning reap at whoever is behind her (both lives)
-- When the first bar empties she falls; the bar and the music go. Then the rot
-- gets her up again: a spore burst, a second bar, a new name, a new fighter.
-- SECOND LIFE (the rot's puppet: jerky, relentless). As she rises an extra arm
-- tears out of her back and a single ragged wing unfolds from her head (mutate()).
--   Lurch     yanked sideways out of line, then a near-instant reap from the new angle
--   Dance     three cuts stepping in: across, up off the floor, back across
--   Plunge    crouch, dust, a leap, and down blade-first where you stood
--   Breath    rears back with spores leaking from the hood, breathes a choking cloud
--   Spin      her floating spin again, faster (x1.43), harder (x1.5), drifting after you quicker
--   Rot Tether  a ring of spores follows her; stray outside it and the haze chokes you.
--             It closes in slowly and stops well outside her reach (Config.Usher.Tether)
-- No fissures and no ground markers in either life.
-- Tuning: ReplicatedStorage/Config -> Config.Usher.
local Usher = {}

-- EVERYTHING ABOUT OCULAST IS IN THIS ONE FILE:
--   Usher.Proportions / Usher.Poses   body shape and full-body poses (the client animator uses these too)
--   Usher.Colors / Usher.Look         her robes, hood, shawl and the faint growth in the hood
--   Usher.Weapons / Usher.Grips       the long scythe, and the grip poses its swings tween between
--   Usher.init(ctx) and below         her behaviour (server only). ctx is the shared Core toolkit
--                                     (see the list at the top of GameServer/Core.lua)
-- Tuning: Config.Usher. Body poses not defined here (Windup, Strike, Recover, Stagger,
-- Crouch, Air, Roar, Kneel...) are shared ones from PuppetMath.
Usher.Kind = "Usher"
-- tall, narrow, long-armed; both hands on the haft (the left further up toward the butt)
Usher.Proportions = { girth = 0.74, arm = 1.18, hunch = 0.06, twoHand = 1.15 }
Usher.IdlePose = "UReady"
Usher.Poses = {
	-- kneeling vigil at the altar, head bowed; then lifting it to listen
	UKneel = { drop = 1.5, lean = 0.62, head = 0.55, footR = 0.95, footL = -1.25, freeL = 0, breathe = 0.5 },
	UListen = { drop = 1.3, lean = 0.05, side = 0.2, head = -0.3, twist = 0.15, footR = 0.95, footL = -1.25, freeL = 0, breathe = 2 },
	-- her fighting stance: low, poised, weight forward (her "Idle")
	UReady = { drop = 0.35, lean = 0.22, twist = 0.15, head = 0.05, footR = -0.4, footL = 0.45, spread = 0.12, freeL = 0 },
	-- dragging the blade low behind her before the rising reap; the reap itself
	UDrag = { drop = 0.85, lean = 0.6, twist = -0.55, head = -0.1, footR = -0.8, footL = 0.85, spread = 0.12, freeL = 0 },
	URise = { drop = 0.1, lean = -0.4, twist = 0.35, head = -0.45, footR = 0.9, footL = -0.55, freeL = 0 },
	-- head thrown back (spore breath); wound round to whip the blade behind her
	UShriek = { drop = 0.25, lean = -0.7, head = -0.9, side = 0.05, footR = 0.3, footL = -0.3, breathe = 3, freeL = 0 },
	UTwist = { drop = 0.5, lean = 0.3, twist = 1.2, head = -0.1, footR = 0.5, footL = -0.5, spread = 0.2, freeL = 0 },
	-- upright and still as she floats and turns, feet together, head bowed
	USpin = { drop = -0.05, lean = -0.05, head = 0.35, footR = 0.05, footL = -0.05, spread = -0.15, breathe = 0.3, freeL = 0 },
	-- second life: yanked sideways like a puppet; breathing spores out
	ULurch = { drop = 0.6, lean = 0.25, side = 0.4, twist = 0.45, head = 0.25, footR = 0.6, footL = -0.3, spread = 0.35, freeL = 0 },
	UExhale = { drop = 0.45, lean = 0.6, head = -0.15, footR = 0.6, footL = -0.5, breathe = 3, freeL = 0 },
	-- a skittering hop back out of reach
	UHop = { drop = 0.35, lean = -0.3, head = 0.1, tuck = 0.25, footR = -0.4, footL = 0.3, la1 = 0.7, la3 = -0.9, lel = 0.6, freeL = 0 },
	-- counter stance: planted wide and low, upright, blind face lifted, the haft held up over her head
	UStance = { drop = 0.6, lean = -0.12, head = -0.25, footR = -0.75, footL = 0.8, spread = 0.45, breathe = 0.2, freeL = 0 },
}
Usher.Colors = { skin = Color3.fromRGB(128, 126, 110), torso = Color3.fromRGB(74, 68, 56), legs = Color3.fromRGB(66, 60, 50), arms = Color3.fromRGB(74, 68, 56) }
Usher.FistSkin = true

function Usher.Look(k)
	local deco, parts, V, at, rgb, MAT, D, s, look = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT, k.D, k.s, k.look
	local cw, ch, cd, hw, hd, aw, lw, la = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la
	-- Oculast, the Blinded Usher: a chapel usher's vestments gone grey with damp,
	-- a deep hood and veil, and where her eyes were, the rot has taken root.
	local robe, robeDark, rope = look.torso, rgb(52, 47, 40), rgb(96, 84, 56)
	local bone, flesh, fleshDark = rgb(176, 168, 146), rgb(98, 82, 58), rgb(62, 48, 38)
	local shin = D.shin / s
	-- long skirt from the hips almost to the floor (front/back/sides, slightly flared)
	local skirtL = 2.45
	deco("Hips", "Skirt", V(hw * 1.05, skirtL, 0.1), at(0, -skirtL / 2 + 0.15, -hd / 2 - 0.06) * CFrame.Angles(-0.07, 0, 0), robe, MAT.Fabric)
	deco("Hips", "Skirt", V(hw * 1.1, skirtL, 0.1), at(0, -skirtL / 2 + 0.15, hd / 2 + 0.06) * CFrame.Angles(0.08, 0, 0), robeDark, MAT.Fabric)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Hips", "Skirt", V(0.1, skirtL - 0.1, hd * 1.05), at(sx * (hw / 2 + 0.06), -skirtL / 2 + 0.2, 0) * CFrame.Angles(0, 0, sx * 0.07), robeDark, MAT.Fabric)
	end
	-- a ragged hem
	for i = 0, 4 do
		local x = (i - 2) * hw * 0.24
		deco("Hips", "Hem", V(hw * 0.2, 0.35 + (i % 2) * 0.25, 0.1), at(x, -skirtL + 0.05 - (i % 2) * 0.12, -hd / 2 - 0.13), robe:Lerp(rgb(0, 0, 0), 0.2), MAT.Fabric)
	end
	-- the legs read as robe in motion
	for _, n in ipairs({ "R", "L" }) do
		parts[n .. "Thigh"].Color = robeDark
		parts[n .. "Shin"].Color = robeDark
		deco(n .. "Shin", "Wrap", V(lw * 1.1, shin * 0.5, lw * 1.1), at(0, -shin * 0.2, 0), rgb(84, 76, 60), MAT.Fabric)
	end
	-- tabard bearing the prison's eye, slashed through
	deco("Chest", "Tabard", V(cw * 0.6, ch * 1.05, 0.08), at(0, -0.1, -cd / 2 - 0.05), robeDark, MAT.Fabric)
	deco("Hips", "TabardTail", V(hw * 0.55, 1.4, 0.08), at(0, -0.55, -hd / 2 - 0.15), robeDark, MAT.Fabric)
	deco("Chest", "Emblem", V(0.5, 0.5, 0.04), at(0, 0.2, -cd / 2 - 0.1) * CFrame.Angles(0, 0, math.pi / 4), bone, MAT.Fabric)
	deco("Chest", "EmblemEye", V(0.17, 0.17, 0.05), at(0, 0.2, -cd / 2 - 0.12), rgb(30, 22, 20), MAT.Fabric)
	deco("Chest", "Slash", V(0.85, 0.07, 0.05), at(0, 0.2, -cd / 2 - 0.13) * CFrame.Angles(0, 0, 0.6), rgb(70, 24, 20), MAT.Fabric)
	-- mantle over the shoulders, rope belt, prayer beads, an unlit usher's lamp
	deco("Chest", "Mantle", V(cw * 1.2, 0.55, cd * 1.3), at(0, ch / 2 - 0.2, 0), robeDark, MAT.Fabric)
	deco("Chest", "MantleBack", V(cw * 1.05, 1.3, 0.1), at(0, ch / 2 - 0.85, cd / 2 + 0.08), robeDark, MAT.Fabric)
	deco("Hips", "Belt", V(hw + 0.1, 0.18, hd + 0.1), at(0, 0.28, 0), rope, MAT.Fabric)
	for i = 0, 5 do
		deco("Hips", "Bead", V(0.13, 0.13, 0.13), at(-hw / 2 + 0.05, 0.12 - i * 0.16, -hd / 2 + 0.05 + (i % 2) * 0.03), bone, MAT.SmoothPlastic, Enum.PartType.Ball)
	end
	deco("Hips", "Lamp", V(0.32, 0.45, 0.32), at(hw / 2 + 0.12, -0.35, -0.1), rgb(40, 36, 32), MAT.Metal)
	deco("Hips", "LampGlass", V(0.2, 0.28, 0.2), at(hw / 2 + 0.12, -0.35, -0.1), rgb(60, 58, 44), MAT.Glass)
	-- long bell sleeves
	for _, n in ipairs({ "R", "L" }) do
		deco(n .. "LowerArm", "Sleeve", V(aw * 1.45, la * 0.55, aw * 1.45), at(0, la * 0.05, 0), robe, MAT.Fabric)
	end
	-- the rot has climbed her: boils over the left shoulder and down the back
	for _, b in ipairs({ { -0.6, 0.65, 0.15, 0.42 }, { -0.75, 0.4, 0.3, 0.3 }, { -0.4, 0.75, 0.35, 0.28 }, { -0.2, 0.1, 0.55, 0.35 }, { 0.1, -0.3, 0.55, 0.25 } }) do
		deco("Chest", "Boil", V(b[4], b[4], b[4]), at(b[1] * cw / 2 * 1.6, b[2], b[3] * cd), fleshDark:Lerp(flesh, (b[1] + 1) / 2), MAT.SmoothPlastic, Enum.PartType.Ball)
	end
	-- hood and veil
	deco("Head", "HoodBack", V(1.35, 1.6, 0.3), at(0, 0.1, 0.62), robeDark, MAT.Fabric)
	deco("Head", "HoodTop", V(1.35, 0.3, 1.45), at(0, 0.78, 0.02), robeDark, MAT.Fabric)
	deco("Head", "HoodPeak", V(0.9, 0.5, 0.9), at(0, 0.98, 0.25) * CFrame.Angles(0.5, 0, 0), robeDark, MAT.Fabric)
	deco("Head", "HoodL", V(0.18, 1.55, 1.35), at(-0.66, 0.08, 0.02), robeDark, MAT.Fabric)
	deco("Head", "HoodR", V(0.18, 1.55, 1.35), at(0.66, 0.08, 0.02), robeDark, MAT.Fabric)
	deco("Head", "Veil", V(1.2, 1.9, 0.08), at(0, -0.95, 0.76) * CFrame.Angles(0.12, 0, 0), robe:Lerp(rgb(0, 0, 0), 0.3), MAT.Fabric)
	-- no face to speak of: a black void under the hood and a shawl over the mouth.
	-- Her eyes are bound: a stained linen blindfold knotted tight across them,
	-- with old dark streaks run down from under it. Nothing in her face glows.
	-- Her attack tell is the rot instead: parts named "Tell" (fungal caps sprouting
	-- through the crown of her hood, pustules on her rotting left shoulder) flare.
	parts.Head.Color = rgb(8, 8, 8)
	parts.Head.Material = MAT.SmoothPlastic
	deco("Head", "HoodBrim", V(1.42, 0.34, 0.4), at(0, 0.6, -0.6) * CFrame.Angles(0.25, 0, 0), robeDark, MAT.Fabric)
	deco("Head", "HoodLipL", V(0.2, 1.2, 0.3), at(-0.6, 0.05, -0.66), robeDark, MAT.Fabric)
	deco("Head", "HoodLipR", V(0.2, 1.2, 0.3), at(0.6, 0.05, -0.66), robeDark, MAT.Fabric)
	deco("Head", "Shawl", V(1.18, 0.62, 0.2), at(0, -0.36, -0.64) * CFrame.Angles(-0.08, 0, 0), robe:Lerp(rgb(0, 0, 0), 0.15), MAT.Fabric)
	deco("Head", "ShawlFold", V(1.0, 0.12, 0.22), at(0, -0.12, -0.7), robe:Lerp(rgb(0, 0, 0), 0.45), MAT.Fabric)
	deco("Chest", "ShawlDrape", V(cw * 0.7, 0.9, 0.14), at(-0.1, ch / 2 - 0.35, -cd / 2 - 0.12) * CFrame.Angles(0, 0, 0.12), robe:Lerp(rgb(0, 0, 0), 0.15), MAT.Fabric)
	local linen, linenDark, stain = rgb(124, 112, 88), rgb(92, 80, 62), rgb(64, 30, 24)
	deco("Head", "Blindfold", V(1.04, 0.27, 0.06), at(0, 0.14, -0.6), linen, MAT.Fabric) -- keeps the old part name other scripts may look for
	deco("Head", "BlindCloth", V(0.86, 0.11, 0.05), at(0.02, 0.17, -0.635) * CFrame.Angles(0, 0, 0.32), linenDark, MAT.Fabric) -- a second wrap, crossed
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "BlindStain", V(0.1, 0.16, 0.04), at(sx * 0.19, 0.17, -0.64), stain, MAT.Fabric) -- seeping through where the eyes were
		deco("Head", "TearStreak", V(0.05, 0.13, 0.03), at(sx * 0.2, -0.03, -0.62), stain, MAT.Fabric) -- dried, run down the void
	end
	-- the growth that took her eyes has come out through the top of the hood
	for _, c in ipairs({ { -0.32, 0.86, -0.42, 0.22 }, { -0.08, 0.95, -0.3, 0.18 }, { 0.22, 0.88, -0.4, 0.15 }, { -0.5, 0.7, -0.55, 0.13 } }) do
		deco("Head", "Tell", V(c[4], c[4], c[4]), at(c[1], c[2], c[3]), rgb(34, 32, 20), MAT.Neon, Enum.PartType.Ball)
	end
	for _, c in ipairs({ { -0.68, 0.78, -0.05, 0.2 }, { -0.85, 0.52, 0.1, 0.16 }, { -0.5, 0.88, 0.22, 0.15 } }) do
		deco("Chest", "Tell", V(c[4], c[4], c[4]), at(c[1] * cw / 2 * 1.6, c[2], c[3] * cd), rgb(34, 32, 20), MAT.Neon, Enum.PartType.Ball)
	end
end

Usher.Weapons = {
	-- her harvest-blade: a long haft (hands near the butt) and a rusted crescent hooked
	-- off its end. The blade lies in the haft's YZ plane, curling back toward the hands;
	-- the edge is on the inside of the curve.
	Scythe = function(w)
		local R, mk, add = w.R, w.mk, w.add
		local rust, edge = Color3.fromRGB(92, 82, 70), Color3.fromRGB(150, 144, 128)
		-- (9 studs of haft at scale 1: hands near the butt, blade hooked off the far end)
		local handle = mk("Haft", Vector3.new(0.27, 9.0, 0.27), Color3.fromRGB(42, 33, 26), Enum.Material.Wood)
		add(mk("Wrap", Vector3.new(0.33, 0.9, 0.33), Color3.fromRGB(84, 76, 60), Enum.Material.Fabric), 3.1)
		add(mk("Wrap", Vector3.new(0.33, 0.7, 0.33), Color3.fromRGB(84, 76, 60), Enum.Material.Fabric), 4.25)
		add(mk("Collar", Vector3.new(0.48, 0.7, 0.48), w.iron, Enum.Material.Metal), -4.15)
		add(mk("Tang", Vector3.new(0.14, 0.4, 0.7), w.iron, Enum.Material.Metal), -4.3, nil, -0.3)
		for _, b in ipairs({ { 1.88, 0.62, 5, -4.25, -0.9 }, { 1.58, 0.52, 15, -3.98, -2.52 }, { 1.28, 0.38, 35, -3.44, -3.75 } }) do
			local rot = CFrame.Angles(R(b[3]), 0, 0)
			add(mk("Blade", Vector3.new(0.08, b[2], b[1]), rust, Enum.Material.CorrodedMetal), b[4], rot, b[5])
			-- the honed inner edge (toward the haft's hands)
			local up = rot.UpVector * (b[2] / 2 + 0.03)
			add(mk("Edge", Vector3.new(0.05, 0.07, b[1]), edge, Enum.Material.Metal), b[4] + up.Y, rot, b[5] + up.Z)
		end
		local scale = w.scale
		return {
			handle = handle,
			bladeLen = 3.3,
			gripC1 = CFrame.new(0, 3.1 * scale, 0), -- right hand 1.4 from the butt
			setup = function(h, a0, a1)
				-- hits are swept from the haft's middle, along to its end and out to the tip
				a0.Position = Vector3.new(0, -4.28 * scale, 0)
				a1.Position = Vector3.new(0, -3.09 * scale, -4.23 * scale)
				local mid = Instance.new("Attachment")
				mid.Name = "HaftMid"
				mid.Position = Vector3.new(0, -0.6 * scale, 0)
				mid.Parent = h
				-- sparks thrown off when the haft's end scrapes the floor (enabled by her moves)
				local sp = Instance.new("ParticleEmitter")
				sp.Name = "Sparks"
				sp.Texture = "rbxasset://textures/particles/sparkles_main.dds"
				sp.Rate = 70
				sp.Enabled = false
				sp.Lifetime = NumberRange.new(0.25, 0.6)
				sp.Speed = NumberRange.new(6, 14)
				sp.SpreadAngle = Vector2.new(60, 60)
				sp.Acceleration = Vector3.new(0, -40, 0)
				sp.Size = NumberSequence.new(0.22, 0)
				sp.Color = ColorSequence.new(Color3.fromRGB(255, 205, 140))
				sp.LightEmission = 1
				sp.Parent = a0
			end,
		}
	end,
}
-- scythe grips (positions at scale 1; the hand is on the haft near the butt)
Usher.Grips = {
	UIdle = { Vector3.new(1.1, -0.1, -0.6), CFrame.Angles(0, math.rad(-20), 0) * CFrame.Angles(math.rad(68), 0, 0) },
	UKneelGrip = { Vector3.new(0.15, -0.9, -1.1), CFrame.Angles(math.rad(180), 0, 0) }, -- planted upright, blade over her head
	URaise = { Vector3.new(0.7, 2.5, 0.5), CFrame.Angles(math.rad(233), 0, math.rad(8)) * CFrame.Angles(0, math.pi, 0) },
	UChop = { Vector3.new(0.25, -0.5, -1.9), CFrame.Angles(0, math.rad(8), 0) * CFrame.Angles(math.rad(72), 0, 0) * CFrame.Angles(0, math.pi, 0) },
	USweepBack = { Vector3.new(1.7, 0.3, 0.9), CFrame.Angles(0, math.rad(-50), 0) * CFrame.Angles(0, 0, math.rad(80)) },
	USweepMid = { Vector3.new(0.2, 0.3, -1.7), CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(0, 0, math.rad(80)) },
	USweepEnd = { Vector3.new(-1.3, 0.3, -0.6), CFrame.Angles(0, math.rad(200), 0) * CFrame.Angles(0, 0, math.rad(80)) },
	USweepEndR = { Vector3.new(-1.3, 0.3, -0.6), CFrame.Angles(0, math.rad(200), 0) * CFrame.Angles(0, 0, math.rad(80)) * CFrame.Angles(0, math.pi, 0) },
	USweepMidR = { Vector3.new(0.2, 0.3, -1.7), CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(0, 0, math.rad(80)) * CFrame.Angles(0, math.pi, 0) },
	USweepBackR = { Vector3.new(1.7, 0.3, 0.9), CFrame.Angles(0, math.rad(-50), 0) * CFrame.Angles(0, 0, math.rad(80)) * CFrame.Angles(0, math.pi, 0) },
	UDragBack = { Vector3.new(1.5, -0.6, 1.3), CFrame.Angles(0, math.rad(-165), 0) * CFrame.Angles(math.rad(70), 0, 0) }, -- haft end on the floor behind her
	URising = { Vector3.new(0.4, 2.4, -1.5), CFrame.Angles(0, math.rad(10), 0) * CFrame.Angles(math.rad(150), 0, 0) },
	UDeflect = { Vector3.new(0.3, 0.8, -1.2), CFrame.Angles(math.rad(35), math.rad(40), math.rad(-30)) * CFrame.Angles(0, math.pi, 0) },
	-- her counter stance: both hands over her head, haft level across it, the blade out to her right
	UStance = { Vector3.new(0.5, 2.6, -0.3), CFrame.Angles(0, math.rad(-90), 0) * CFrame.Angles(math.rad(100), 0, 0) },
	-- the player's scythe: carried high, haft at the chest and the blade up over the right shoulder
	UGuard = { Vector3.new(1.0, 0.9, -0.7), CFrame.Angles(0, math.rad(25), 0) * CFrame.Angles(math.rad(205), 0, 0) },
	-- the deflect's overhead twirl: one full turn in quarters, haft level just above the head
	UTwirlA = { Vector3.new(0.3, 2.9, -0.2), CFrame.Angles(0, 0, 0) * CFrame.Angles(math.rad(100), 0, 0) },
	UTwirlB = { Vector3.new(0.3, 2.9, -0.2), CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(math.rad(100), 0, 0) },
	UTwirlC = { Vector3.new(0.3, 2.9, -0.2), CFrame.Angles(0, math.rad(180), 0) * CFrame.Angles(math.rad(100), 0, 0) },
	UTwirlD = { Vector3.new(0.3, 2.9, -0.2), CFrame.Angles(0, math.rad(270), 0) * CFrame.Angles(math.rad(100), 0, 0) },
}
Usher.BodyFor = {
	UIdle = "Idle", URaise = "Windup", UChop = "Strike", USweepBack = "SweepWindup", USweepEnd = "SweepEnd",
	USweepEndR = "SweepEnd", USweepBackR = "SweepWindup", UDragBack = "UDrag", URising = "URise",
	UDeflect = "Deflect", UGuard = "Idle", UStance = "UStance",
	UTwirlA = "Twirl", UTwirlB = "Twirl", UTwirlC = "Twirl", UTwirlD = "Twirl",
}

local U: any = nil -- runtime state, created by Usher.init
local api: any = {}

function Usher.owns(model)
	return U ~= nil and model ~= nil and U.model == model
end
function Usher.actor()
	return U and U.current
end
function Usher.poiseState()
	return U
end
function Usher.onHit(player)
	if U and api.onHit then
		api.onHit(player)
	end
end
function Usher.onPoiseBreak()
	if U and api.onPoiseBreak then
		api.onPoiseBreak()
	end
end
function Usher.spawn()
	if U and api.spawn then
		api.spawn()
	end
end
function Usher.reset()
	if U and api.reset then
		api.reset()
	end
end
function Usher.isDead()
	return U ~= nil and U.state == "dead"
end
function Usher.inChapel(pos)
	return U ~= nil and api.inChapel and api.inChapel(pos) or false
end

function Usher.init(ctx)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local TweenService = game:GetService("TweenService")
	local Debris = game:GetService("Debris")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local CFG = ctx.Config.Usher
	local SOUNDS = ctx.SOUNDS
	local now, flat = ctx.now, ctx.flat
	local pose, bodyPose, setTrail, playSound = ctx.pose, ctx.bodyPose, ctx.setTrail, ctx.playSound
	local S = CFG.Scale
	local HOME = ctx.Map.Usher.Home
	local MINP, MAXP = ctx.Map.Usher.Min, ctx.Map.Usher.Max
	local ROT_DARK, ROT_FLESH = Color3.fromRGB(62, 48, 38), Color3.fromRGB(110, 92, 62)
	local SPORE = Color3.fromRGB(200, 192, 120)
	-- the faint growth deep in her black hood: barely there, flaring as her tell
	local BLIND_BASE, BLIND_P2, BLIND_FLARE = Color3.fromRGB(34, 32, 20), Color3.fromRGB(120, 110, 58), Color3.fromRGB(235, 225, 140)

	U = { state = "none", gen = 0, cd = {} } -- none | kneel | waking | fight | returning | dead
	if ctx.registerTarget then
		ctx.registerTarget(function(model)
			if not Usher.owns(model) then
				return nil
			end
			return {
				owner = U,
				actor = U.current,
				maxPoise = CFG.Poise,
				freeze = false,
				damageMult = function(player) -- weak to strength weapons (Config.Usher.WeakTo)
					return CFG.WeakTo[player:GetAttribute("Weapon")] or 1
				end,
				onHit = function(player)
					Usher.onHit(player) -- struck at her vigil: she wakes
				end,
				onBreak = function()
					Usher.onPoiseBreak()
				end,
				evade = function(player) -- true = the blow misses (her counter stance)
					return api.evade ~= nil and api.evade(player)
				end,
			}
		end)
	end

	local function rand(lo, hi)
		return lo + math.random() * (hi - lo)
	end

	local function dmg(x)
		return math.max(1, math.floor(x * (CFG.DamageScale or 1) + 0.5))
	end

	local function inChapel(pos)
		return pos.X >= MINP.X - 1 and pos.X <= MAXP.X + 1 and pos.Z >= MINP.Z - 1 and pos.Z <= MAXP.Z + 1 and pos.Y > -4 and pos.Y < 20
	end
	api.inChapel = inChapel

	local function live(a)
		return U.gen == a.gen and U.state == "fight" and a.hum.Parent ~= nil and a.hum.Health > 0
	end

	local function free(a)
		return live(a) and now() >= (U.staggerUntil or 0)
	end

	local function tempo()
		return U.phase2 and CFG.Phase2Tempo or 1
	end

	-- she is blind: the louder you are, the better she tracks you
	local function noisy(pl)
		local st = ctx.states[pl]
		local char, _, hrp = ctx.aliveChar(pl)
		if not (st and char) then
			return false
		end
		local t = now()
		local moving = flat(hrp.AssemblyLinearVelocity).Magnitude > 3
		local rolling = (st.iEnd or 0) > 0 and t >= st.iStart - 0.08 and t <= st.iEnd + 0.2
		return (st.sprinting and moving) or rolling or st.healing
	end

	local function turnRate(pl)
		local r = math.rad(U.phase2 and CFG.TurnRate2 or CFG.TurnRate)
		if pl then
			r *= noisy(pl) and 1.35 or 0.8
		end
		return r
	end

	-- nearest living player inside the chapel
	local function target(a)
		local best, bestD, bestPl
		for _, pl in ipairs(Players:GetPlayers()) do
			local char, _, hrp = ctx.aliveChar(pl)
			if char and inChapel(hrp.Position) then
				local d = flat(hrp.Position - a.root.Position).Magnitude
				if not bestD or d < bestD then
					best, bestD, bestPl = char, d, pl
				end
			end
		end
		return best, bestPl
	end

	---------------------------------------------------------------------------
	-- the boss bar + music
	---------------------------------------------------------------------------
	-- Her humanoid holds both lives (HP + HP2); the bar shows only the current one.
	-- quiet: the bar without the music (her second life's theme waits till she's up)
	local function showBar(a, quiet)
		U.barOn = true
		ReplicatedStorage:SetAttribute("BossName", U.phase2 and CFG.Name2 or CFG.Name)
		ReplicatedStorage:SetAttribute("BossMaxHP", U.phase2 and CFG.HP2 or CFG.HP)
		ReplicatedStorage:SetAttribute("BossHP", math.max(0, U.phase2 and a.hum.Health or a.hum.Health - CFG.HP2))
		ReplicatedStorage:SetAttribute("BossActive", true)
		if CFG.Music and CFG.Music ~= "" and not quiet then
			ReplicatedStorage:SetAttribute("Music", U.phase2 and "usher2" or "usher")
		end
	end

	local function hideBar()
		if not U.barOn then
			return
		end
		U.barOn = false
		ReplicatedStorage:SetAttribute("BossActive", false)
		local mus = ReplicatedStorage:GetAttribute("Music")
		if mus == "usher" or mus == "usher2" then
			ReplicatedStorage:SetAttribute("Music", "none")
		end
	end

	---------------------------------------------------------------------------
	-- tells and effects
	---------------------------------------------------------------------------
	local function blindfolds(a)
		local list = {}
		for _, d in ipairs(a.model:GetChildren()) do
			if d.Name == "Tell" and d:IsA("BasePart") then
				table.insert(list, d)
			end
		end
		return list
	end

	local function sporePuff(pos, n, size, speed)
		local anchor = ctx.fxAnchor(pos)
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
		pe.Rate = 0
		pe.Lifetime = NumberRange.new(0.8, 1.8)
		pe.Speed = NumberRange.new((speed or 4) * 0.4, speed or 4)
		pe.SpreadAngle = Vector2.new(70, 70)
		pe.Drag = 3
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, (size or 1) * 0.4), NumberSequenceKeypoint.new(1, (size or 1) * 1.3) })
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) })
		pe.Color = ColorSequence.new(SPORE)
		pe.LightEmission = 0.25
		pe.Parent = anchor
		pe:Emit(n or 8)
		Debris:AddItem(anchor, 2.2)
	end

	-- Every attack opens like this: the growth where her eyes were flares, she
	-- hisses, and a breath of spores escapes her hood.
	local function tell(a, pitch)
		playSound(a.root, SOUNDS.Groan, 0.75, pitch or 1.25)
		playSound(a.root, SOUNDS.Unsheath, 0.35, 1.7)
		for _, d in ipairs(blindfolds(a)) do
			d.Color = BLIND_FLARE
			task.delay(0.3, function()
				if d.Parent then
					TweenService:Create(d, TweenInfo.new(0.45), { Color = U.phase2 and BLIND_P2 or BLIND_BASE }):Play()
				end
			end)
		end
		local head = a.model:FindFirstChild("Head")
		if head then
			sporePuff(head.Position - Vector3.new(0, 0.3, 0), 5, 0.6, 2)
		end
		if U.phase2 and U.mut and U.current == a then
			U.mut.rear() -- second life: the back arm rears, the wing flares
		end
	end

	local function sparks(a, on)
		local weapon = a.model:FindFirstChild("Weapon")
		local sp = weapon and weapon:FindFirstChild("Sparks", true)
		if sp then
			sp.Enabled = on
		end
	end

	local function sparkBurst(pos, n)
		local anchor = ctx.fxAnchor(pos)
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Rate = 0
		pe.Lifetime = NumberRange.new(0.25, 0.6)
		pe.Speed = NumberRange.new(8, 18)
		pe.SpreadAngle = Vector2.new(70, 70)
		pe.Acceleration = Vector3.new(0, -45, 0)
		pe.Size = NumberSequence.new(0.25, 0)
		pe.Color = ColorSequence.new(Color3.fromRGB(255, 205, 140))
		pe.LightEmission = 1
		pe.Parent = anchor
		pe:Emit(n or 16)
		Debris:AddItem(anchor, 1)
	end

	local function bladePoints(a)
		local handle = a.weld and a.weld.Parent and a.weld.Part1
		if not handle or not handle.Parent then
			return nil
		end
		local m, b, t = handle:FindFirstChild("HaftMid"), handle:FindFirstChild("BladeBase"), handle:FindFirstChild("BladeTip")
		if not (m and b and t) then
			return nil
		end
		return m.WorldPosition, b.WorldPosition, t.WorldPosition
	end

	-- The scythe hurts wherever it actually travels: every frame, the path of the
	-- haft's outer half and the blade since last frame is swept with spheres.
	local hitParams = OverlapParams.new()
	hitParams.FilterType = Enum.RaycastFilterType.Include
	hitParams.CollisionGroup = "HitQuery"
	local function sweep(a, duration, damage, level, seen, radius)
		local chars = {}
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl.Character then
				table.insert(chars, pl.Character)
			end
		end
		hitParams.FilterDescendantsInstances = chars
		seen = seen or {}
		local t0 = now()
		local prev
		while now() - t0 < duration and live(a) do
			local m, b, t = bladePoints(a)
			if m then
				prev = prev or { m, b, t }
				for i = 0, 3 do
					local f = i / 3
					local pm, pb, pt = prev[1]:Lerp(m, f), prev[2]:Lerp(b, f), prev[3]:Lerp(t, f)
					for j = 0, 7 do
						local p = j < 4 and pm:Lerp(pb, j / 4) or pb:Lerp(pt, (j - 4) / 3)
						for _, part in ipairs(workspace:GetPartBoundsInRadius(p, radius or 1.5, hitParams)) do
							local pl = Players:GetPlayerFromCharacter(part:FindFirstAncestorOfClass("Model"))
							if pl and not seen[pl] and ctx.damagePlayer(pl, dmg(damage), a.root.Position, level) then
								seen[pl] = true
							end
						end
					end
				end
				prev = { m, b, t }
			end
			RunService.Heartbeat:Wait()
		end
		return seen
	end

	-- hold a windup, turning toward the target for the first trackFrac of it
	local function hold(a, duration, trackFrac, tChar, tPl)
		local t0 = now()
		while now() - t0 < duration do
			if not free(a) then
				return false
			end
			local dt = task.wait()
			local tr = tChar and tChar:FindFirstChild("HumanoidRootPart")
			if tr and now() - t0 < duration * (trackFrac or 0) then
				ctx.turnTowards(a.root, tr.Position, turnRate(tPl) * dt * 1.6)
			end
		end
		return true
	end

	-- A sweep's warning, made obvious: she draws back slowly (Config.Usher.Telegraph
	-- stretches it), the growth in her hood flares and the haft grates on the stone,
	-- and just before the swing comes a hard glint flashes on the blade's tip.
	local TG1 = CFG.Telegraph or 1.6
	local function tg()
		return U.phase2 and (CFG.Telegraph2 or TG1) or TG1
	end
	local function glint(a)
		local weapon = a.model:FindFirstChild("Weapon")
		local tipAtt = weapon and weapon:FindFirstChild("BladeTip", true)
		if not tipAtt then
			return
		end
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(255, 236, 196)
		l.Range = 14
		l.Brightness = 7
		l.Parent = tipAtt
		TweenService:Create(l, TweenInfo.new(0.45), { Brightness = 0 }):Play()
		Debris:AddItem(l, 0.5)
		local star = Instance.new("ParticleEmitter")
		star.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		star.Rate = 0
		star.Lifetime = NumberRange.new(0.35)
		star.Speed = NumberRange.new(0)
		star.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(0.3, 3), NumberSequenceKeypoint.new(1, 0) })
		star.Color = ColorSequence.new(Color3.fromRGB(255, 240, 210))
		star.LightEmission = 1
		star.RotSpeed = NumberRange.new(180, 260)
		star.LockedToPart = true
		star.Parent = tipAtt
		star:Emit(1)
		Debris:AddItem(star, 0.6)
		playSound(a.root, SOUNDS.Unsheath, 0.55, 2.1)
	end

	local function windup(a, duration, trackFrac, tChar, tPl)
		local d = duration * tg()
		for _, b in ipairs(blindfolds(a)) do
			b.Color = BLIND_FLARE
			task.delay(d, function()
				if b.Parent then
					TweenService:Create(b, TweenInfo.new(0.4), { Color = U.phase2 and BLIND_P2 or BLIND_BASE }):Play()
				end
			end)
		end
		playSound(a.root, SOUNDS.Unsheath, 0.45, 0.55) -- the haft grating as she draws back
		if not hold(a, d * 0.72, trackFrac, tChar, tPl) then
			return false
		end
		glint(a)
		return hold(a, d * 0.28, trackFrac > 0 and 1 or 0, tChar, tPl)
	end

	local function waitLive(a, duration)
		local t0 = now()
		while now() - t0 < duration do
			if not live(a) then
				return false
			end
			task.wait()
		end
		return true
	end

	local function push(a, dir, speed)
		local root = a.root
		if root.Parent and not root.Anchored then
			local v = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = dir * speed + Vector3.new(0, v.Y, 0)
		end
	end

	local function fwd(a)
		local f = flat(a.root.CFrame.LookVector)
		return f.Magnitude > 0.1 and f.Unit or Vector3.new(0, 0, -1)
	end

	local function stopAndFace(a, tChar)
		a.hum:MoveTo(a.root.Position)
		a.hum.AutoRotate = false
		local tr = tChar and tChar:FindFirstChild("HumanoidRootPart")
		if tr then
			ctx.turnTowards(a.root, tr.Position, math.rad(30))
		end
	end

	local function ready(a)
		setTrail(a, false)
		sparks(a, false)
		pose(a, "UIdle", 0.3)
	end

	---------------------------------------------------------------------------
	-- moves
	---------------------------------------------------------------------------
	-- the downward chop itself (shared by Chop, Reap's finisher and Harvest)
	local function chopStrike(a, damage)
		setTrail(a, true)
		pose(a, "UChop", 0.11)
		playSound(a.root, SOUNDS.Lunge, 0.8, 0.85)
		push(a, fwd(a), 10)
		local seen = {}
		task.spawn(sweep, a, 0.17, damage, "Large", seen, 1.6)
		task.wait(0.12)
		if not live(a) then
			return false
		end
		local _, base, tip = bladePoints(a)
		local hitAt = tip or (a.root.Position + fwd(a) * 7)
		if base and base.Y < hitAt.Y then
			hitAt = base
		end
		hitAt = Vector3.new(hitAt.X, 0.15, hitAt.Z)
		sparkBurst(hitAt + Vector3.new(0, 0.3, 0), 22)
		ctx.debrisChunks(hitAt + Vector3.new(0, 0.4, 0), 4, 22)
		ctx.dustCloud(hitAt + Vector3.new(0, 0.4, 0), 1.6, 6)
		playSound(a.root, SOUNDS.Impact, 0.9, 1.1)
		ctx.FxRemote:FireAllClients("Shake", hitAt, 0.55)
		return true
	end

	local function chop(a, tChar, tPl, opts)
		opts = opts or {}
		local m = tempo()
		stopAndFace(a, tChar)
		tell(a, 1.2)
		pose(a, "URaise", 0.45 * m * tg())
		playSound(a.root, SOUNDS.Unsheath, 0.6, 0.9)
		if not windup(a, 0.58 * m, 0.75, tChar, tPl) then
			return
		end
		if opts.delayed then
			-- leans back further with a rasping breath; the drop comes late
			bodyPose(a, "URise", 0.3)
			playSound(a.root, SOUNDS.Groan, 0.5, 1.5)
			if not hold(a, rand(0.3, 0.55), 0, nil, nil) then
				return
			end
		end
		if not chopStrike(a, CFG.Damage.Chop) then
			return
		end
		bodyPose(a, "Recover", 0.35) -- the blade is in the stone: punish her
		if not waitLive(a, opts.recover or 0.75 * m) then
			return
		end
		sparkBurst(a.root.Position + fwd(a) * 6 + Vector3.new(0, -2.5, 0), 8) -- wrenching it free
		if not opts.recover then
			ready(a)
		end
	end

	local function reap(a, tChar, tPl, opts)
		opts = opts or {}
		local m = tempo()
		local w = opts.wind or 1
		stopAndFace(a, tChar)
		if not opts.notell then
			tell(a, 1.3)
		end
		pose(a, "USweepBack", 0.36 * m * w * tg())
		playSound(a.root, SOUNDS.Unsheath, 0.5, 1.2)
		if not windup(a, 0.44 * m * w, 0.8, tChar, tPl) then
			return
		end
		setTrail(a, true)
		playSound(a.root, SOUNDS.Slash, 0.8, 0.8)
		pose(a, "USweepMid", 0.1, Enum.EasingStyle.Linear)
		task.delay(0.1, function()
			if live(a) then
				pose(a, "USweepEnd", 0.13)
			end
		end)
		push(a, fwd(a), 13)
		local k = opts.scale or 1
		sweep(a, 0.25, CFG.Damage.Reap * k, "Medium", {}, 1.5)
		if (opts.followUp or opts.finisher) and free(a) then
			-- turns the blade over in her hands and reaps back the other way
			setTrail(a, false)
			pose(a, "USweepEndR", 0.1)
			playSound(a.root, SOUNDS.Unsheath, 0.4, 1.5)
			if not windup(a, 0.3 * m, 0.7, tChar, tPl) then
				return
			end
			setTrail(a, true)
			playSound(a.root, SOUNDS.Slash, 0.8, 0.9)
			pose(a, "USweepMidR", 0.1, Enum.EasingStyle.Linear)
			task.delay(0.1, function()
				if live(a) then
					pose(a, "USweepBackR", 0.13)
				end
			end)
			push(a, fwd(a), 12)
			sweep(a, 0.25, CFG.Damage.Reverse * k, "Medium", {}, 1.5)
		end
		if opts.finisher and free(a) then
			setTrail(a, false)
			pose(a, "URaise", 0.22)
			tell(a, 1.4)
			if not windup(a, 0.3 * m, 0.6, tChar, tPl) then
				return
			end
			if not chopStrike(a, CFG.Damage.Chop * k) then
				return
			end
			bodyPose(a, "Recover", 0.35)
		end
		setTrail(a, false)
		if waitLive(a, opts.recover or (opts.finisher and 0.8 or 0.55) * m) and not opts.recover then
			ready(a)
		end
	end

	-- drops low, drags the haft's end along the stone (sparks), rushes in and reaps upward
	local wallParams = RaycastParams.new()
	wallParams.FilterType = Enum.RaycastFilterType.Exclude
	local function rising(a, damage, level)
		setTrail(a, true)
		sparks(a, false)
		pose(a, "URising", 0.13)
		playSound(a.root, SOUNDS.Slash, 0.9, 0.75)
		local base = select(2, bladePoints(a))
		if base then
			sparkBurst(Vector3.new(base.X, 0.3, base.Z), 14)
		end
		sweep(a, 0.24, damage, level or "Knockdown", {}, 1.6)
		setTrail(a, false)
	end

	local function lunge(a, tChar, tPl)
		local tr = tChar:FindFirstChild("HumanoidRootPart")
		if not tr then
			return
		end
		local m = tempo()
		stopAndFace(a, tChar)
		tell(a, 1.15)
		pose(a, "UDragBack", 0.3)
		task.delay(0.22, function()
			if live(a) then
				sparks(a, true) -- the haft's end hits the floor behind her and scrapes
				playSound(a.root, SOUNDS.Unsheath, 0.6, 0.6)
			end
		end)
		if not hold(a, 0.62 * m, 0.85, tChar, tPl) then
			sparks(a, false)
			return
		end
		local root = a.root
		local dir = fwd(a)
		local dist = math.clamp(flat(tr.Position - root.Position).Magnitude - 7, 3, 24)
		local ignore = { ctx.EnemiesFolder, ctx.Map.Bars }
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl.Character then
				table.insert(ignore, pl.Character)
			end
		end
		wallParams.FilterDescendantsInstances = ignore
		local res = workspace:Raycast(root.Position, dir * (dist + 3), wallParams)
		if res then
			dist = math.max(res.Distance - 3, 0)
		end
		root.Anchored = true
		local start, rot = root.Position, root.CFrame.Rotation
		local dur = math.max(dist / 46, 0.1)
		local t0, nextDust = now(), 0
		playSound(root, SOUNDS.Lunge, 0.7, 0.7)
		while live(a) do
			local k = math.min((now() - t0) / dur, 1)
			local pos = start + dir * dist * k
			root.CFrame = CFrame.new(pos) * rot
			if now() > nextDust then
				nextDust = now() + 0.06
				ctx.dustCloud(Vector3.new(pos.X, 0.5, pos.Z) - dir * 2, 0.8, 2)
			end
			if k >= 1 then
				break
			end
			RunService.Heartbeat:Wait()
		end
		root.Anchored = false
		pcall(function()
			root:SetNetworkOwner(nil)
		end)
		if not live(a) then
			sparks(a, false)
			return
		end
		rising(a, CFG.Damage.Rising)
		bodyPose(a, "Recover", 0.4)
		if waitLive(a, 0.75 * m) then
			ready(a)
		end
	end

	-- a turning reap at whoever is behind her
	local function turnabout(a, tChar, tPl, fast)
		local tr = tChar and tChar:FindFirstChild("HumanoidRootPart")
		if not tr then
			return
		end
		local m = fast and 0.6 or tempo()
		a.hum:MoveTo(a.root.Position)
		a.hum.AutoRotate = false
		tell(a, 1.45)
		bodyPose(a, "UTwist", 0.3 * m)
		pose(a, "USweepBack", 0.3 * m * tg())
		if not windup(a, 0.4 * m, 0, nil, nil) then
			return
		end
		-- whip round to face where the sound came from, the blade cutting the arc behind her
		local root = a.root
		local cur = fwd(a)
		local want = flat(tr.Position - root.Position)
		want = want.Magnitude > 0.1 and want.Unit or -cur
		local yaw0 = math.atan2(-cur.X, -cur.Z)
		local turn = (math.atan2(-want.X, -want.Z) - yaw0 + math.pi) % (2 * math.pi) - math.pi
		setTrail(a, true)
		playSound(root, SOUNDS.Slash, 0.9, 0.7)
		pose(a, "USweepMid", 0.28, Enum.EasingStyle.Linear)
		bodyPose(a, "SweepEnd", 0.28)
		local seen = {}
		task.spawn(sweep, a, 0.32, CFG.Damage.Turnabout, "Medium", seen, 1.6)
		local t0 = now()
		while live(a) do
			local k = math.min((now() - t0) / 0.28, 1)
			ctx.steerYaw(root, yaw0 + turn * k) -- (a physical twist: teleporting a standing rig makes it flicker)
			if k >= 1 then
				break
			end
			RunService.Heartbeat:Wait()
		end
		task.wait(0.06)
		setTrail(a, false)
		if waitLive(a, 0.5 * m) then
			ready(a)
		end
	end

	-- FIRST LIFE: she rises a hair off the floor, scythe held straight out, and
	-- turns slowly round and round while drifting after you across the chapel.
	-- The blade cuts whoever it passes. Speeds/height/length: Config.Usher.Spin.
	local function spin(a, tChar, tPl, second)
		local SP = CFG.Spin
		local speedMult = second and (SP.SpeedMult2 or 1.3) or 1
		local dmgMult = second and (SP.DamageMult2 or 1.5) or 1
		local drift = SP.DriftSpeed * (second and (SP.DriftMult2 or 1) or 1)
		stopAndFace(a, tChar)
		tell(a, 1.1)
		-- the tell: she straightens, the blade swings out level, the hem lifts
		bodyPose(a, "USpin", 0.6)
		pose(a, "USweepMid", 0.6)
		playSound(a.root, SOUNDS.Unsheath, 0.6, 0.6)
		if not windup(a, 0.8 * tempo(), 0.8, tChar, tPl) then
			return
		end
		local root = a.root
		local stand = root.Position.Y
		local yaw = math.atan2(-fwd(a).X, -fwd(a).Z)
		local turn = math.rad(SP.TurnRate * speedMult) * (math.random() < 0.5 and -1 or 1)
		root.Anchored = true
		setTrail(a, true)
		ctx.dustCloud(Vector3.new(root.Position.X, 0.4, root.Position.Z), 1.4, 6)
		local t0 = now()
		local last = t0
		local nextHit = t0
		local seen = {}
		local params = hitParams
		while free(a) and now() - t0 < SP.Duration do
			local t = now()
			local dt = t - last
			last = t
			-- rise into the float over the first half second, settle at the end
			local k = math.min((t - t0) / 0.5, 1, (SP.Duration - (t - t0)) / 0.4)
			yaw += turn * dt
			local pos = root.Position
			local tr = tChar and tChar:FindFirstChild("HumanoidRootPart")
			if tr then
				local rel = flat(tr.Position - pos)
				if rel.Magnitude > 2 then
					pos += rel.Unit * math.min(drift * dt, rel.Magnitude - 2)
				end
			end
			pos = Vector3.new(math.clamp(pos.X, MINP.X + 2, MAXP.X - 2), stand + SP.FloatHeight * math.max(k, 0), math.clamp(pos.Z, MINP.Z + 2, MAXP.Z - 2))
			root.CFrame = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
			-- the blade's real path hurts; each person can be cut again after a beat
			if t >= nextHit then
				nextHit = t + SP.RehitTime
				table.clear(seen)
			end
			local m, b, tip = bladePoints(a)
			if m then
				local chars = {}
				for _, pl in ipairs(Players:GetPlayers()) do
					if pl.Character then
						table.insert(chars, pl.Character)
					end
				end
				params.FilterDescendantsInstances = chars
				for j = 0, 7 do
					local p = j < 4 and m:Lerp(b, j / 4) or b:Lerp(tip, (j - 4) / 3)
					for _, part in ipairs(workspace:GetPartBoundsInRadius(p, 1.6, params)) do
						local pl = Players:GetPlayerFromCharacter(part:FindFirstAncestorOfClass("Model"))
						if pl and not seen[pl] and ctx.damagePlayer(pl, dmg(CFG.Damage.Spin * dmgMult), root.Position, "Medium") then
							seen[pl] = true
						end
					end
				end
			end
			RunService.Heartbeat:Wait()
		end
		setTrail(a, false)
		root.CFrame = CFrame.new(root.Position.X, stand, root.Position.Z) * CFrame.Angles(0, yaw, 0)
		if not free(a) then -- staggered out of it (or the fight ended): drop to the floor
			root.Anchored = false
			return
		end
		root.Anchored = false
		pcall(function()
			root:SetNetworkOwner(nil)
		end)
		-- giddy and open for a moment as she settles
		bodyPose(a, "Recover", 0.4)
		if waitLive(a, SP.Recover) then
			ready(a)
		end
	end

	-- skittering hop back out of reach
	local function hopBack(a)
		if not free(a) then
			return
		end
		bodyPose(a, "UHop", 0.1)
		push(a, -fwd(a), 26)
		playSound(a.root, SOUNDS.Unsheath, 0.3, 1.6)
		waitLive(a, 0.32)
		a.hum:MoveTo(a.root.Position)
		if live(a) then
			bodyPose(a, "Idle", 0.25)
		end
	end

	---------------------------------------------------------------------------
	-- SECOND LIFE: the rot has her now. A different fighter: she lurches about
	-- like a thing on strings, dances in three-cut strings, leaps on you blade
	-- first, and breathes spores. No fissures: the floor stays whole.
	---------------------------------------------------------------------------
	-- jerks sideways out of line (as if yanked), then reaps from the new angle
	local function lurchReap(a, tChar, tPl)
		local tr = tChar:FindFirstChild("HumanoidRootPart")
		if not tr then
			return
		end
		stopAndFace(a, tChar)
		tell(a, 1.5)
		local side = math.random() < 0.5 and -1 or 1
		local rel = flat(tr.Position - a.root.Position)
		rel = rel.Magnitude > 0.1 and rel.Unit or fwd(a)
		local dir = Vector3.new(-rel.Z, 0, rel.X) * side + rel * 0.35
		dir = dir.Unit
		bodyPose(a, "ULurch", 0.12)
		pose(a, "USweepBack", 0.2)
		if not hold(a, 0.22, 0, nil, nil) then
			return
		end
		local root = a.root
		local dist = 7.5
		local ignore = { ctx.EnemiesFolder, ctx.Map.Bars }
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl.Character then
				table.insert(ignore, pl.Character)
			end
		end
		wallParams.FilterDescendantsInstances = ignore
		local res = workspace:Raycast(root.Position, dir * (dist + 2.5), wallParams)
		if res then
			dist = math.max(res.Distance - 2.5, 0)
		end
		local nextPos = root.Position + dir * dist
		if not inChapel(nextPos) then
			dist = 0
		end
		root.Anchored = true
		local start, rot = root.Position, root.CFrame.Rotation
		local t0 = now()
		playSound(root, SOUNDS.Unsheath, 0.5, 0.5)
		while live(a) do
			local k = math.min((now() - t0) / 0.16, 1)
			root.CFrame = CFrame.new(start + dir * dist * k) * rot
			if k >= 1 then
				break
			end
			RunService.Heartbeat:Wait()
		end
		ctx.dustCloud(Vector3.new(root.Position.X, 0.5, root.Position.Z), 1.2, 5)
		root.Anchored = false
		pcall(function()
			root:SetNetworkOwner(nil)
		end)
		if not free(a) then
			return
		end
		-- snaps her head round to you, and the reap comes almost at once
		local tr2 = tChar:FindFirstChild("HumanoidRootPart")
		if tr2 then
			ctx.turnTowards(root, tr2.Position, math.rad(80))
		end
		reap(a, tChar, tPl, { wind = 0.55, followUp = math.random() < 0.5, notell = true })
	end

	-- three cuts, stepping in with each: across, up from the floor, back across
	local function dance(a, tChar, tPl)
		local m = tempo()
		stopAndFace(a, tChar)
		tell(a, 1.4)
		pose(a, "USweepBack", 0.26 * tg())
		if not windup(a, 0.34 * m, 0.8, tChar, tPl) then
			return
		end
		setTrail(a, true)
		playSound(a.root, SOUNDS.Slash, 0.8, 0.85)
		pose(a, "USweepMid", 0.09, Enum.EasingStyle.Linear)
		task.delay(0.09, function()
			if live(a) then
				pose(a, "USweepEnd", 0.12)
			end
		end)
		push(a, fwd(a), 16)
		sweep(a, 0.22, CFG.Damage.Dance1, "Medium", {}, 1.5)
		-- the blade drops behind her and comes up off the floor
		setTrail(a, false)
		pose(a, "UDragBack", 0.16)
		bodyPose(a, "UDrag", 0.16)
		if not windup(a, 0.38 * m, 0.9, tChar, tPl) then
			return
		end
		push(a, fwd(a), 14)
		rising(a, CFG.Damage.Dance2, "Medium")
		-- turned over and back across
		pose(a, "USweepEndR", 0.14)
		if not windup(a, 0.36 * m, 0.9, tChar, tPl) then
			return
		end
		setTrail(a, true)
		playSound(a.root, SOUNDS.Slash, 0.9, 0.75)
		pose(a, "USweepMidR", 0.09, Enum.EasingStyle.Linear)
		task.delay(0.09, function()
			if live(a) then
				pose(a, "USweepBackR", 0.12)
			end
		end)
		push(a, fwd(a), 16)
		sweep(a, 0.22, CFG.Damage.Dance3, "Large", {}, 1.5)
		setTrail(a, false)
		bodyPose(a, "Recover", 0.35)
		if waitLive(a, 0.75 * m) then
			ready(a)
		end
	end

	-- sinks into a crouch, kicks up dust, leaps and comes down blade first
	local function plunge(a, tChar, tPl)
		local tr = tChar:FindFirstChild("HumanoidRootPart")
		if not tr then
			return
		end
		stopAndFace(a, tChar)
		tell(a, 1.0)
		bodyPose(a, "Crouch", 0.4)
		pose(a, "URaise", 0.4)
		if not hold(a, 0.6 * tempo(), 1, tChar, tPl) then
			return
		end
		local root = a.root
		local landing = tr.Parent and tr.Position or root.Position
		landing = Vector3.new(math.clamp(landing.X, MINP.X + 3, MAXP.X - 3), root.Position.Y, math.clamp(landing.Z, MINP.Z + 3, MAXP.Z - 3))
		local start = root.Position
		local look = flat(landing - start)
		local rot = look.Magnitude > 0.1 and CFrame.lookAt(Vector3.zero, look).Rotation or root.CFrame.Rotation
		ctx.dustCloud(Vector3.new(start.X, 0.5, start.Z), 1.6, 8)
		playSound(root, SOUNDS.Lunge, 0.8, 0.6)
		bodyPose(a, "Air", 0.15)
		root.Anchored = true
		local t0, dur, struck = now(), 0.72, false
		while live(a) do
			local k = math.min((now() - t0) / dur, 1)
			root.CFrame = CFrame.new(start:Lerp(landing, k) + Vector3.new(0, math.sin(k * math.pi) * 11, 0)) * rot
			if k > 0.72 and not struck then
				struck = true
				setTrail(a, true)
				pose(a, "UChop", 0.18)
			end
			if k >= 1 then
				break
			end
			RunService.Heartbeat:Wait()
		end
		root.Anchored = false
		pcall(function()
			root:SetNetworkOwner(nil)
		end)
		if not live(a) then
			return
		end
		-- the landing: dust, thrown grit, sparks off the stone (and no cracks)
		bodyPose(a, "Strike", 0.08)
		local ground = Vector3.new(landing.X, 0.2, landing.Z) + fwd(a) * 4
		ctx.dustCloud(ground + Vector3.new(0, 0.5, 0), 3, 14)
		ctx.debrisChunks(ground + Vector3.new(0, 0.4, 0), 6, 24)
		sparkBurst(ground + Vector3.new(0, 0.3, 0), 24)
		playSound(root, SOUNDS.Impact, 1, 0.8)
		ctx.FxRemote:FireAllClients("Shake", ground, 1)
		local seen = sweep(a, 0.12, CFG.Damage.Plunge, "Knockdown", {}, 1.6)
		for _, pl in ipairs(Players:GetPlayers()) do
			local char, _, hrp = ctx.aliveChar(pl)
			if char and not seen[pl] and flat(hrp.Position - ground).Magnitude <= 5 then
				seen[pl] = true
				ctx.damagePlayer(pl, dmg(CFG.Damage.Plunge), ground, "Knockdown")
			end
		end
		setTrail(a, false)
		task.delay(0.25, function()
			if live(a) then
				bodyPose(a, "Recover", 0.4)
			end
		end)
		if waitLive(a, 1.05) then -- she has to drag the blade back out: punish
			ready(a)
		end
	end

	-- POISON (from her second-life Breath): linger in the spore mist longer than
	-- Config.Usher.Breath.PoisonAfter and you're poisoned (the shared status in Core,
	-- tuned by Config.Usher.Poison). It ends when she dies: the rot dies with her.
	local function poisonPlayer(pl)
		if U.state ~= "dead" then
			ctx.poisonPlayer(pl, CFG.Poison)
		end
	end
	local clearAllPoison = ctx.clearAllPoison
	local PCOL = Color3.fromRGB(150, 178, 70) -- poison green (her breath's mist is tinted toward it)

	-- rears back, chest swelling, spores leaking from the hood; then breathes out
	-- a great choking cloud that hangs in the air. Linger in it and you're poisoned.
	-- Size and timing: Config.Usher.Breath.
	local function breath(a, tChar, tPl)
		local BR = CFG.Breath or {}
		stopAndFace(a, tChar)
		tell(a, 0.9)
		pose(a, "UIdle", 0.3)
		bodyPose(a, "UShriek", 0.55)
		local head = a.model:FindFirstChild("Head")
		for i = 0, 4 do
			task.delay(i * 0.2, function()
				if live(a) and head then
					sporePuff(head.Position, 6, 0.8, 1.5)
				end
			end)
		end
		playSound(a.root, SOUNDS.Groan, 0.6, 0.75)
		if not hold(a, 0.9 * tempo() * tg(), 0.5, tChar, tPl) then
			return
		end
		bodyPose(a, "UExhale", 0.15)
		playSound(a.root, SOUNDS.Groan, 1, 1.35)
		playSound(a.root, SOUNDS.Groan, 0.7, 0.9)
		local origin = a.root.Position
		local aim = fwd(a)
		local range = BR.Range or 19
		local n = BR.Puffs or 9
		local baseR = BR.Radius or 3.2
		local linger = BR.Linger or 4
		local centers, radii = {}, {}
		for i = 1, n do
			local f = i / n
			-- the cloud spreads wider and sinks toward the floor the farther it goes
			centers[i] = origin + aim * (range * f) + Vector3.new(0, 2.2 - f * 1.6, 0)
			radii[i] = baseR * (0.75 + f * 0.7)
		end
		-- the gust itself: a heavy rolling burst along the whole length
		for i = 1, n do
			task.delay(i * 0.045, function()
				if live(a) then
					sporePuff(centers[i], 22, radii[i] * 0.6, 5)
				end
			end)
		end
		-- and the mist it leaves behind, hanging there for Linger seconds
		local MIST = SPORE:Lerp(PCOL, 0.55)
		for i = 1, n do
			local anchor = ctx.fxAnchor(centers[i])
			local pe = Instance.new("ParticleEmitter")
			pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
			pe.Rate = 9
			pe.Lifetime = NumberRange.new(1.4, 2.4)
			pe.Speed = NumberRange.new(0.3, 1.2)
			pe.SpreadAngle = Vector2.new(180, 180)
			pe.Drag = 2
			pe.RotSpeed = NumberRange.new(-20, 20)
			pe.Rotation = NumberRange.new(0, 360)
			pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, radii[i] * 0.7), NumberSequenceKeypoint.new(1, radii[i] * 1.5) })
			pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.55), NumberSequenceKeypoint.new(1, 1) })
			pe.Color = ColorSequence.new(MIST)
			pe.LightEmission = 0.15
			pe.Parent = anchor
			task.delay(linger, function()
				pe.Enabled = false
			end)
			Debris:AddItem(anchor, linger + 2.6)
		end
		local function inMist(p)
			for i = 1, n do
				local c = centers[i]
				if math.abs(p.Y - c.Y) < radii[i] + 3 and flat(p - c).Magnitude <= radii[i] then
					return true
				end
			end
			return false
		end
		-- the gust's hit
		for _, pl in ipairs(Players:GetPlayers()) do
			local char, _, hrp = ctx.aliveChar(pl)
			if char and inMist(hrp.Position) then
				ctx.damagePlayer(pl, dmg(CFG.Damage.Breath), origin, "Medium")
			end
		end
		-- the mist: stand in it longer than PoisonAfter and you're poisoned
		task.spawn(function()
			local inside, poisoned = {}, {}
			local t0 = now()
			while now() - t0 < linger and U.state ~= "dead" do
				local dt = RunService.Heartbeat:Wait()
				for _, pl in ipairs(Players:GetPlayers()) do
					local char, _, hrp = ctx.aliveChar(pl)
					if char and not poisoned[pl] and inMist(hrp.Position) then
						inside[pl] = (inside[pl] or 0) + dt
						if inside[pl] > (BR.PoisonAfter or 0.1) then
							poisoned[pl] = true
							poisonPlayer(pl)
						end
					else
						inside[pl] = 0
					end
				end
			end
		end)
		if waitLive(a, 0.9) then
			bodyPose(a, "Idle", 0.3)
			ready(a)
		end
	end

	-- COUNTER STANCE: sinks low, blade flat behind her, hood burning, and waits. Strike
	-- her and she slips the blow, is at your side, and cuts you down (Config.Usher.Stance).
	api.evade = function(player)
		if U.stanceOn and not U.stanceBy then
			U.stanceBy = player
		end
		return U.stanceOn == true
	end
	local function stance(a, tChar, tPl)
		local SC = CFG.Stance
		stopAndFace(a, tChar)
		tell(a, 0.8)
		pose(a, "UStance", 0.35)
		playSound(a.root, SOUNDS.Unsheath, 0.6, 0.4)
		if not hold(a, 0.35, 1, tChar, tPl) then
			return
		end
		local folds = blindfolds(a)
		for _, b in ipairs(folds) do
			b.Color = BLIND_FLARE -- lit the whole time she waits: the "don't" sign
		end
		U.stanceOn, U.stanceBy = true, nil
		local t0 = now()
		while now() - t0 < SC.Hold and free(a) and not U.stanceBy do
			task.wait()
		end
		U.stanceOn = false
		local pl = U.stanceBy
		U.stanceBy = nil
		for _, b in ipairs(folds) do
			if b.Parent then
				TweenService:Create(b, TweenInfo.new(0.4), { Color = U.phase2 and BLIND_P2 or BLIND_BASE }):Play()
			end
		end
		local char, hrp
		if pl then
			char, _, hrp = ctx.aliveChar(pl)
		end
		if not (char and free(a)) then
			if live(a) then
				ready(a)
				bodyPose(a, "Idle", 0.3)
			end
			return
		end
		-- the counter: gone from where you struck, already at your side
		ctx.FxRemote:FireClient(pl, "Message", "Parried!")
		local root = a.root
		sporePuff(root.Position, 10, 1, 4)
		local side = flat(hrp.CFrame.RightVector).Unit * (math.random() < 0.5 and -1 or 1)
		local ignore = { ctx.EnemiesFolder, ctx.Map.Bars, char }
		wallParams.FilterDescendantsInstances = ignore
		if workspace:Raycast(hrp.Position, side * 5, wallParams) or not inChapel(hrp.Position + side * 4) then
			side = -side
		end
		local spot = hrp.Position + side * 4
		spot = Vector3.new(spot.X, root.Position.Y, spot.Z)
		root.CFrame = CFrame.lookAt(spot, Vector3.new(hrp.Position.X, spot.Y, hrp.Position.Z))
		root.AssemblyLinearVelocity = Vector3.zero
		ctx.dustCloud(Vector3.new(spot.X, 0.5, spot.Z), 1.2, 5)
		setTrail(a, true)
		pose(a, "USweepEnd", SC.Delay)
		bodyPose(a, "SweepEnd", SC.Delay)
		playSound(root, SOUNDS.Slash, 1, 0.7)
		if not waitLive(a, SC.Delay) then
			return
		end
		local _, hum2 = ctx.aliveChar(pl)
		if hum2 and ctx.damagePlayer(pl, hum2.MaxHealth * 10, root.Position, "Knockdown") then
			sparkBurst(hrp.Position, 30)
			playSound(root, SOUNDS.Impact, 1, 0.8)
			ctx.FxRemote:FireAllClients("Shake", hrp.Position, 0.8)
		end
		if waitLive(a, 0.6) then
			setTrail(a, false)
			ready(a)
			bodyPose(a, "Idle", 0.3)
		end
	end

	---------------------------------------------------------------------------
	-- brain
	---------------------------------------------------------------------------
	local MOVES = {
		-- both lives: the counter stance
		{ name = "Stance", min = 0, max = 14, weight = CFG.Stance.Weight, cd = CFG.Stance.Cooldown, fn = stance },
		-- first life: the usher, measured and deliberate
		{ name = "Spin", life = 1, min = 0, max = 18, weight = 3, cd = 8, fn = spin },
		{ name = "Chop", life = 1, min = 0, max = 14, weight = 3, cd = 2.5, fn = function(a, t, pl)
			chop(a, t, pl, { delayed = math.random() < 0.4 })
		end },
		{ name = "Lunge", life = 1, min = 13, max = 32, weight = 3, cd = 4.5, noise = true, fn = lunge },
		{ name = "Turnabout", min = 0, max = 12, weight = 1, cd = 4, behind = true, fn = function(a, t, pl)
			turnabout(a, t, pl, false)
		end },
		-- second life: the rot's puppet
		{ name = "Lurch", life = 2, min = 0, max = 15, weight = 4, cd = 1.5, fn = lurchReap },
		{ name = "Dance", life = 2, min = 0, max = 12, weight = 3, cd = 4, fn = dance },
		{ name = "Plunge", life = 2, min = 12, max = 32, weight = 3, cd = 5, noise = true, fn = plunge },
		{ name = "Spin2", life = 2, min = 0, max = 22, weight = CFG.Spin.Weight2 or 2, cd = CFG.Spin.Cooldown2 or 10, fn = function(a, t, pl)
			spin(a, t, pl, true)
		end },
		{ name = "Breath", life = 2, min = 0, max = 14, weight = 3, cd = 7, fn = breath },
	}

	local function pick(dist, behind, loud)
		local list, total = {}, 0
		local t = now()
		for _, mv in ipairs(MOVES) do
			if (not mv.life or mv.life == (U.phase2 and 2 or 1)) and dist >= mv.min and dist <= mv.max and t >= (U.cd[mv.name] or 0) then
				local w = mv.weight
				if behind then
					w *= mv.behind and 6 or 0.3
				end
				if loud and mv.noise then
					w *= 3 -- she rushes the sound of a flask being drunk
				end
				if mv.name == U.lastMove then
					w *= 0.2 -- never the same thing twice running, if she can help it
				end
				total += w
				table.insert(list, { mv, w })
			end
		end
		if total <= 0 then
			return nil
		end
		local r = math.random() * total
		for _, e in ipairs(list) do
			r -= e[2]
			if r <= 0 then
				return e[1]
			end
		end
		return list[#list][1]
	end

	local function stalk(a, tr, pl)
		local rel = flat(a.root.Position - tr.Position)
		if rel.Magnitude < 0.1 then
			return
		end
		local keep = math.clamp(rel.Magnitude, 9, 13)
		local around = CFrame.Angles(0, U.stalkSide * 0.6, 0):VectorToWorldSpace(rel.Unit) * keep
		a.hum:MoveTo(tr.Position + around)
		ctx.turnTowards(a.root, tr.Position, turnRate(pl) * 0.1)
	end

	local function kneelAtHome(a)
		U.state = "kneel"
		-- Pinned (anchored) at her exact standing height while she waits. Left to physics, a
		-- rig that isn't moving slowly sinks, and every correction of that reached the client
		-- as a jitter. (Anchoring once made waiting rigs look sunk too, but that was the
		-- client's own HipHeight, which the Puppeteer now holds true.) Released in startFight.
		a.root.Anchored = true
		a.root.CFrame = HOME + Vector3.new(0, 3 * S - 3, 0)
		a.root.AssemblyLinearVelocity = Vector3.zero
		a.hum.AutoRotate = false
		a.hum:MoveTo(a.root.Position)
		pcall(function()
			a.root:SetNetworkOwner(nil)
			a.hum:ChangeState(Enum.HumanoidStateType.Running) -- standing (kneeling is only a pose): a waiting rig not "Running" sinks
		end)
		a.hum.Health = a.hum.MaxHealth
		setTrail(a, false)
		sparks(a, false)
		pose(a, "UKneelGrip", 0.8)
		bodyPose(a, "UKneel", 0.9)
		U.cd = {}
		U.lastMove = nil
		U.poise = nil
		U.stanceOn, U.stanceBy = false, nil
	end

	local watch -- forward

	local function brain(a)
		U.stalkUntil = now() + 0.3
		U.stalkSide = 1
		U.lostSince = nil
		while live(a) do
			task.wait(0.1)
			if not live(a) then
				break
			end
			if now() < (U.staggerUntil or 0) then
				continue
			end
			a.hum.AutoRotate = false
			local tChar, tPl = target(a)
			if not tChar then
				-- nobody left in the chapel: wait a moment, then go back to her vigil
				U.lostSince = U.lostSince or now()
				a.hum:MoveTo(a.root.Position)
				if now() - U.lostSince > 4 then
					if U.phase2 then
						task.defer(api.reset) -- second life: the whole fight starts over
						return
					end
					U.state = "returning"
					hideBar()
					task.spawn(watch, a)
					return
				end
				continue
			end
			U.lostSince = nil
			local tr = tChar:FindFirstChild("HumanoidRootPart")
			if not tr then
				continue
			end
			local rel = flat(tr.Position - a.root.Position)
			local dist = rel.Magnitude
			local facing = dist > 0.1 and fwd(a):Dot(rel.Unit) or 1
			local behind = facing < -0.2
			local loud = ctx.states[tPl] and ctx.states[tPl].healing
			if now() < U.stalkUntil and not behind and not loud then
				stalk(a, tr, tPl)
				continue
			end
			local mv = pick(dist, behind, loud)
			if mv then
				U.lastMove = mv.name
				U.cd[mv.name] = now() + mv.cd
				local ok, err = pcall(mv.fn, a, tChar, tPl)
				if not ok then
					warn("[DGUS] Oculast " .. mv.name .. " error: " .. tostring(err))
					sparks(a, false)
					if a.root.Parent then
						a.root.Anchored = false
					end
				end
				if ctx.Config.Debug then
					print("[Oculast] " .. mv.name)
				end
				if live(a) and mv.name ~= "Lunge" and math.random() < 0.3 and dist < 6 then
					hopBack(a)
				end
				U.stalkSide = math.random() < 0.5 and -1 or 1
				U.stalkUntil = now() + (U.phase2 and rand(0.05, 0.3) or rand(0.2, 0.55)) + (CFG.IdleExtra or 0)
			elseif dist < 4 then
				a.hum:MoveTo(a.root.Position - rel.Unit * 6)
				ctx.turnTowards(a.root, tr.Position, turnRate(tPl) * 0.1)
			else
				a.hum:MoveTo(tr.Position)
				ctx.turnTowards(a.root, tr.Position, turnRate(tPl) * 0.1)
			end
		end
	end

	-- the rot takes root in her: tendrils out of the hood, boils, a rotted blade
	local function growRot(a)
		local head, chest = a.model:FindFirstChild("Head"), a.model:FindFirstChild("Chest")
		local function add(base, size, off, color, shape)
			if not base then
				return
			end
			local p = Instance.new("Part")
			p.Name = "Rot"
			p.Size = size * S
			p.Color = color
			p.Material = Enum.Material.SmoothPlastic
			p.Reflectance = 0.1
			if shape then
				p.Shape = shape
			end
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Massless = true
			p.CFrame = base.CFrame * CFrame.new(off.Position * S) * off.Rotation
			local w = Instance.new("WeldConstraint")
			w.Part0 = base
			w.Part1 = p
			w.Parent = p
			p.Parent = a.model
		end
		for i = 1, 7 do
			local x = (i - 4) * 0.17
			add(head, Vector3.new(0.14, 1 + math.random() * 0.9, 0.14), CFrame.new(x, 0.75 + math.random() * 0.2, 0.25 + math.random() * 0.25) * CFrame.Angles(-0.6 - math.random() * 0.5, 0, -x * 1.6), ROT_DARK:Lerp(ROT_FLESH, math.random()))
		end
		for _, b in ipairs({ { 0.6, 0.7, 0.1, 0.5 }, { 0.75, 0.45, -0.2, 0.35 }, { -0.1, 0.85, 0.4, 0.4 }, { 0.3, 0.2, 0.55, 0.45 }, { -0.5, -0.2, 0.55, 0.3 }, { 0.2, -0.5, -0.55, 0.32 } }) do
			add(chest, Vector3.new(b[4], b[4], b[4]), CFrame.new(b[1], b[2], b[3]), ROT_DARK:Lerp(ROT_FLESH, math.random()), Enum.PartType.Ball)
		end
		local weapon = a.model:FindFirstChild("Weapon")
		if weapon then
			for _, d in ipairs(weapon:GetDescendants()) do
				if d:IsA("BasePart") and d.Name == "Blade" then
					d.Color = Color3.fromRGB(48, 36, 30)
				elseif d:IsA("BasePart") and d.Name == "Edge" then
					d.Color = Color3.fromRGB(150, 140, 80)
				end
			end
			local tip = weapon:FindFirstChild("BladeTip", true)
			if tip then
				local drip = Instance.new("ParticleEmitter")
				drip.Rate = 6
				drip.Lifetime = NumberRange.new(0.6, 1)
				drip.Speed = NumberRange.new(0, 0.5)
				drip.Acceleration = Vector3.new(0, -25, 0)
				drip.Size = NumberSequence.new(0.12, 0.05)
				drip.Color = ColorSequence.new(Color3.fromRGB(70, 66, 36))
				drip.Parent = tip
			end
		end
		if chest then
			local pe = Instance.new("ParticleEmitter")
			pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
			pe.Rate = 6
			pe.Lifetime = NumberRange.new(1, 2)
			pe.Speed = NumberRange.new(0.5, 1.5)
			pe.Size = NumberSequence.new(0.4, 1.2)
			pe.Transparency = NumberSequence.new(0.6, 1)
			pe.Color = ColorSequence.new(SPORE)
			pe.Parent = chest
		end
	end

	-- What the rot makes of her in her second life: a long, many-jointed arm tears
	-- out of her back and folds over her shoulder, and a single ragged wing
	-- unfolds out of the side of her head. Both grow out piece by piece as she
	-- rises, then never keep still: the arm twitches and claws at the air, the
	-- wing shudders and beats. Before each attack the arm rears up and spreads its
	-- fingers and the wing flares (part of her tell, see tell()).
	-- Shape: change the numbers in MUTANT below (sizes in studs at Scale 1).
	local MUTANT = {
		GrowTime = 1.6, -- how long the arm and wing take to grow out
		ArmLength = 1, -- multiplies the back arm's length
		WingLength = 1, -- multiplies the wing's length
		Flesh = Color3.fromRGB(150, 138, 116), -- the arm's skin: grey, bloodless
		Claw = Color3.fromRGB(40, 34, 28),
		Feather = Color3.fromRGB(176, 168, 146), -- dirty bone-white
		FeatherDark = Color3.fromRGB(92, 84, 70),
	}
	local function mutate(a)
		local head, chest = a.model:FindFirstChild("Head"), a.model:FindFirstChild("Chest")
		if not head or not chest then
			return
		end
		local ch, cd = chest.Size.Y / S, chest.Size.Z / S
		local growing = {} -- { part, weld, size, ball, at }
		-- a piece hinged at `joint` (in base's space, studs at scale 1; when the base
		-- is another piece, measured from that piece's own hinge) that extends along
		-- its own +Y from there; balls sit centred on the joint
		local function piece(base, size, joint, color, mat, at, ball)
			for _, g in ipairs(growing) do
				if g.p == base and not g.ball then
					joint = CFrame.new(0, -g.size.Y / S / 2, 0) * joint
				end
			end
			local p = Instance.new("Part")
			p.Name = "Mutation"
			p.Size = Vector3.new(0.05, 0.05, 0.05)
			p.Color = color
			p.Material = mat or Enum.Material.SmoothPlastic
			if ball then
				p.Shape = Enum.PartType.Ball
			end
			p.Transparency = 1
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Massless = true
			p.CastShadow = true
			p.TopSurface = Enum.SurfaceType.Smooth
			p.BottomSurface = Enum.SurfaceType.Smooth
			local w = Instance.new("Weld")
			w.Part0 = base
			w.Part1 = p
			w.C0 = CFrame.new(joint.Position * S) * joint.Rotation
			w.C1 = CFrame.new()
			p.CFrame = base.CFrame * w.C0
			w.Parent = p
			p.Parent = a.model
			table.insert(growing, { p = p, w = w, size = size * S, ball = ball, at = at })
			return p, w
		end
		local function len(p)
			for _, g in ipairs(growing) do
				if g.p == p then
					return g.size.Y / S
				end
			end
			return 0
		end
		local A, W = MUTANT.ArmLength, MUTANT.WingLength
		local flesh, fleshDark = MUTANT.Flesh, MUTANT.Flesh:Lerp(ROT_DARK, 0.55)

		-- THE ARM: torn out of her upper back, right of the spine, reaching up and
		-- back, then folding forward over her shoulder like a mantis's
		local T = 0
		piece(chest, Vector3.new(0.75, 0.75, 0.75), CFrame.new(0.28, ch * 0.28, cd / 2 + 0.02), ROT_FLESH, Enum.Material.SmoothPlastic, T, true)
		piece(chest, Vector3.new(0.5, 0.5, 0.5), CFrame.new(0.05, ch * 0.18, cd / 2 + 0.08), ROT_DARK, Enum.Material.SmoothPlastic, T, true)
		local upper, shoulderW = piece(chest, Vector3.new(0.34, 2.1 * A, 0.34), CFrame.new(0.3, ch * 0.3, cd / 2 + 0.05) * CFrame.Angles(0.75, 0, -0.5), flesh, Enum.Material.SmoothPlastic, T + 0.1)
		local uL = len(upper)
		piece(upper, Vector3.new(0.44, 0.44, 0.44), CFrame.new(0, uL, 0), fleshDark, Enum.Material.SmoothPlastic, T + 0.35, true)
		piece(upper, Vector3.new(0.12, 0.5, 0.12), CFrame.new(0, uL * 0.55, 0.16) * CFrame.Angles(0.5, 0, 0), MUTANT.Claw, Enum.Material.SmoothPlastic, T + 0.3) -- a bone spur
		local fore, elbowW = piece(upper, Vector3.new(0.27, 2.4 * A, 0.27), CFrame.new(0, uL, 0) * CFrame.Angles(-1.85, 0, -0.4), flesh:Lerp(fleshDark, 0.3), Enum.Material.SmoothPlastic, T + 0.4)
		local fL = len(fore)
		local hand, wristW = piece(fore, Vector3.new(0.4, 0.42, 0.16), CFrame.new(0, fL, 0) * CFrame.Angles(-0.35, 0, 0), fleshDark, Enum.Material.SmoothPlastic, T + 0.7)
		local fingers = {}
		for i = 1, 4 do
			local x = (i - 2.5) * 0.11
			local fing, fw = piece(hand, Vector3.new(0.07, 0.95 * A, 0.07), CFrame.new(x, 0.42, 0) * CFrame.Angles(-0.55, 0, -x * 1.8), flesh:Lerp(fleshDark, 0.5), Enum.Material.SmoothPlastic, T + 0.85 + i * 0.03)
			piece(fing, Vector3.new(0.06, 0.32, 0.06), CFrame.new(0, len(fing), 0) * CFrame.Angles(-0.6, 0, 0), MUTANT.Claw, Enum.Material.SmoothPlastic, T + 1.0 + i * 0.03)
			table.insert(fingers, { w = fw, base = fw.C0 })
		end

		-- THE WING: one, out of the left side of her head, through the hood; bare
		-- bone near the root, then ragged feathers, some missing
		T = 0.25
		piece(head, Vector3.new(0.55, 0.55, 0.55), CFrame.new(-0.55, 0.62, 0.25), ROT_FLESH, Enum.Material.SmoothPlastic, T, true)
		local humerus, rootW = piece(head, Vector3.new(0.22, 1.5 * W, 0.22), CFrame.new(-0.55, 0.62, 0.25) * CFrame.Angles(0.3, 0, 0.7), MUTANT.Feather:Lerp(ROT_FLESH, 0.5), Enum.Material.SmoothPlastic, T + 0.1)
		local hL = len(humerus)
		piece(humerus, Vector3.new(0.3, 0.3, 0.3), CFrame.new(0, hL, 0), ROT_FLESH, Enum.Material.SmoothPlastic, T + 0.35, true)
		local fa, faW = piece(humerus, Vector3.new(0.17, 2.3 * W, 0.17), CFrame.new(0, hL, 0) * CFrame.Angles(0.1, 0, 0.35), MUTANT.Feather, Enum.Material.SmoothPlastic, T + 0.4)
		local faL = len(fa)
		local tipB, tipW = piece(fa, Vector3.new(0.12, 1.6 * W, 0.12), CFrame.new(0, faL, 0) * CFrame.Angles(0.05, 0, 0.4), MUTANT.Feather, Enum.Material.SmoothPlastic, T + 0.7)
		local tL = len(tipB)
		-- feathers hang down off the trailing edge, swept back toward the tip
		local rnd = Random.new(7)
		local function feathers(bone, boneLen, n, l0, l1, t0)
			for i = 1, n do
				if rnd:NextNumber() > 0.18 then -- a few plucked out
					local f = (i - 0.5) / n
					local l = (l0 + (l1 - l0) * f) * W * (0.75 + rnd:NextNumber() * 0.35)
					local c = MUTANT.Feather:Lerp(MUTANT.FeatherDark, rnd:NextNumber() * 0.8)
					piece(bone, Vector3.new(0.34, l, 0.04), CFrame.new(0, boneLen * f, -0.02 * i) * CFrame.Angles(0, 0, math.pi / 2 - 0.15 - f * 0.3), c, Enum.Material.Fabric, t0 + f * 0.35)
				end
			end
		end
		feathers(humerus, hL, 3, 0.7, 1.1, T + 0.3)
		feathers(fa, faL, 7, 1.3, 2.3, T + 0.6)
		feathers(tipB, tL, 5, 2.4, 1.6, T + 0.9)

		-- grow it all out, root first; each piece unrolls from its hinge
		local grow = MUTANT.GrowTime / 1.6
		for _, g in ipairs(growing) do
			task.delay(g.at * grow, function()
				if not g.p.Parent then
					return
				end
				g.p.Transparency = 0
				local ti = TweenInfo.new(0.3 * grow + 0.05, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				if g.ball then
					TweenService:Create(g.p, ti, { Size = g.size }):Play()
				else
					g.p.Size = Vector3.new(g.size.X * 0.6, 0.05, g.size.Z * 0.6)
					TweenService:Create(g.p, ti, { Size = g.size }):Play()
					TweenService:Create(g.w, ti, { C1 = CFrame.new(0, -g.size.Y / 2, 0) }):Play()
				end
			end)
		end
		-- the wet crack of it breaking out of her
		for i = 0, 3 do
			task.delay(i * 0.3 * grow, function()
				if a.root.Parent then
					playSound(a.root, SOUNDS.Impact, 0.7, 0.35 + i * 0.08)
					sporePuff(chest.Position + chest.CFrame.LookVector * -0.8 * S, 6, 0.6, 3)
				end
			end)
		end

		-- after that it is never still
		local rest = {
			{ w = shoulderW, base = shoulderW.C0 },
			{ w = elbowW, base = elbowW.C0 },
			{ w = wristW, base = wristW.C0 },
		}
		local wing = { { w = rootW, base = rootW.C0 }, { w = faW, base = faW.C0 }, { w = tipW, base = tipW.C0 } }
		local rearing = 0
		local function twist(j, x, y, z, t, style)
			TweenService:Create(j.w, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { C0 = j.base * CFrame.Angles(x, y, z) }):Play()
		end
		local function rand2(r)
			return (math.random() * 2 - 1) * r
		end
		U.mut = {
			-- before an attack: the arm rears high, fingers splay; the wing flares wide
			rear = function()
				rearing = now() + 0.7
				twist(rest[1], 0.45, 0, -0.25, 0.18, Enum.EasingStyle.Back)
				twist(rest[2], 0.9, 0, 0, 0.18, Enum.EasingStyle.Back)
				twist(rest[3], 0.4, 0, 0, 0.18)
				for i, f in ipairs(fingers) do
					twist(f, 0.7, 0, (i - 2.5) * 0.25, 0.15)
				end
				twist(wing[1], -0.2, 0, 0.3, 0.2, Enum.EasingStyle.Back)
				twist(wing[2], 0, 0, -0.35, 0.2, Enum.EasingStyle.Back)
				twist(wing[3], 0, 0, -0.3, 0.2, Enum.EasingStyle.Back)
			end,
		}
		task.spawn(function()
			task.wait(MUTANT.GrowTime + 0.3)
			local nextBeat = now()
			while U.current == a and a.model.Parent and U.state ~= "dead" do
				if now() >= rearing then
					-- the arm twitches and claws at nothing; sometimes a hard spasm
					local hard = math.random() < 0.2
					local r = hard and 0.5 or 0.18
					local t = hard and 0.09 or rand(0.12, 0.3)
					twist(rest[1], rand2(r), rand2(r), rand2(r), t, Enum.EasingStyle.Back)
					twist(rest[2], rand2(r * 1.2), 0, rand2(r * 0.5), t, Enum.EasingStyle.Back)
					twist(rest[3], rand2(r), rand2(r), 0, t)
					local clench = math.random() < 0.5 and rand(0.4, 0.9) or rand(-0.4, 0)
					for i, f in ipairs(fingers) do
						task.delay(i * 0.03, function()
							twist(f, -clench + rand2(0.1), 0, rand2(0.1), 0.12)
						end)
					end
					-- the wing: a slow shudder most of the time, a full beat now and then
					if now() >= nextBeat then
						nextBeat = now() + rand(1.6, 3.2)
						twist(wing[1], 0.15, 0, 0.35, 0.25, Enum.EasingStyle.Sine)
						twist(wing[2], 0, 0, -0.4, 0.25, Enum.EasingStyle.Sine)
						task.delay(0.28, function()
							twist(wing[1], -0.1, 0, -0.45, 0.4, Enum.EasingStyle.Sine)
							twist(wing[2], 0, 0, 0.35, 0.4, Enum.EasingStyle.Sine)
							twist(wing[3], 0, 0, 0.3, 0.4, Enum.EasingStyle.Sine)
						end)
					else
						twist(wing[1], rand2(0.06), 0, rand2(0.1), 0.35, Enum.EasingStyle.Sine)
						twist(wing[2], 0, 0, rand2(0.12), 0.35, Enum.EasingStyle.Sine)
						twist(wing[3], 0, 0, rand2(0.15), 0.35, Enum.EasingStyle.Sine)
					end
					task.wait(hard and 0.15 or rand(0.25, 0.7))
				else
					task.wait(0.1)
				end
			end
		end)
	end

	-- Her first bar runs out. She falls to her knees, the bar goes, the music
	-- stops... and after a long breath the rot gets up instead, with a new bar.
	-- Her transition takes this much longer than its base timing (1.5 = 50% longer).
	local FALL = CFG.FallTime or 1.5

	-- Breathing while she lies fallen: slow breaths that start barely audible and
	-- swell, louder and harsher, until the rot bursts out of her. Uses SOUNDS.Breath
	-- (an asset id, if you set one) or, by default, Roblox's built-in wind sample
	-- pitched down and filtered so it reads as breath. Returns a function to stop it.
	local function breathing(a, total)
		local head = a.model:FindFirstChild("Head") or a.root
		local snd = Instance.new("Sound")
		local own = SOUNDS.Breath and SOUNDS.Breath ~= ""
		snd.SoundId = own and SOUNDS.Breath or "rbxasset://sounds/action_falling.mp3"
		snd.Looped = true
		snd.Volume = 0
		snd.RollOffMaxDistance = 90
		snd.RollOffMinDistance = 8
		snd.PlaybackSpeed = own and 1 or 0.45
		if not own then
			local eq = Instance.new("EqualizerSoundEffect")
			eq.HighGain = -18 -- soft, airy, no whistle
			eq.MidGain = 2
			eq.LowGain = -6
			eq.Parent = snd
		end
		snd.Parent = head
		snd:Play()
		local alive = true
		task.spawn(function()
			local t0 = now()
			while alive and snd.Parent do
				-- 0 -> 1 over the whole fall: barely there at first, loud by the end
				local k = math.clamp((now() - t0) / total, 0, 1)
				local peak = 0.03 + 1.6 * k * k
				local inhale = 1.5 - 0.6 * k -- breaths get quicker as it builds
				local exhale = 1.9 - 0.8 * k
				if not own then
					snd.PlaybackSpeed = 0.42 + 0.12 * k
				end
				TweenService:Create(snd, TweenInfo.new(inhale, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Volume = peak }):Play()
				task.wait(inhale)
				if not alive then
					break
				end
				if not own then
					snd.PlaybackSpeed = 0.36 + 0.1 * k -- the out-breath sits lower
				end
				TweenService:Create(snd, TweenInfo.new(exhale, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Volume = peak * 0.08 }):Play()
				task.wait(exhale)
			end
		end)
		return function()
			alive = false
			TweenService:Create(snd, TweenInfo.new(0.15), { Volume = 0 }):Play()
			Debris:AddItem(snd, 0.3)
		end
	end

	-- ROT TETHER (second life only). A ring of brambles tears up out of the floor
	-- around her: clusters of black, thorned, rotting branches taller than you,
	-- their tips curling in over the arena, bound together by roots creeping along
	-- the stone, spores drifting off them. The ring follows her about. Inside it
	-- you're fine; stray outside and the haze starts to choke you after a short
	-- grace, a little at first and worse the longer you stay out. It starts wide,
	-- closes in slowly, and stops at MinRadius, well outside her reach, so you
	-- never have to hug her to live. The haze isn't dodged by rolling but never
	-- stuns or knocks you about. Only players inside the chapel are affected.
	-- Tuning: Config.Usher.Tether.
	local BRAMBLE_WOOD = Color3.fromRGB(40, 31, 25)
	local BRAMBLE_THORN = Color3.fromRGB(24, 20, 16)

	-- one cluster of brambles, built around its own invisible root at the origin.
	-- Local space: -Z points in at her, +Z out of the ring, Y up.
	local function bramble(seed, height)
		local rnd = Random.new(seed)
		local function r(lo, hi)
			return rnd:NextNumber(lo, hi)
		end
		local model = Instance.new("Model")
		model.Name = "Bramble"
		local root = Instance.new("Part")
		root.Name = "BrambleRoot"
		root.Size = Vector3.new(3, 1, 3)
		root.Transparency = 1
		root.Anchored = true
		root.CanCollide = false
		root.CanQuery = false
		root.CanTouch = false
		root.CFrame = CFrame.new()
		root.Parent = model
		model.PrimaryPart = root
		local function bit(size, cf, color, mat, ball)
			local p = Instance.new("Part")
			p.Name = "Bramble"
			p.Size = size
			p.CFrame = cf
			p.Color = color
			p.Material = mat or Enum.Material.Wood
			if ball then
				p.Shape = Enum.PartType.Ball
			end
			p.Anchored = false
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Massless = true
			p.TopSurface = Enum.SurfaceType.Smooth
			p.BottomSurface = Enum.SurfaceType.Smooth
			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = p
			w.Parent = p
			p.Parent = model
			return p
		end
		local function along(from, dir)
			-- a CFrame at `from` whose Z axis runs along `dir`
			local up = math.abs(dir.Y) > 0.9 and Vector3.xAxis or Vector3.yAxis
			return CFrame.lookAt(from, from + dir, up)
		end
		-- the twisted stalks: rising, kinking, their tips curling in over the arena
		for _ = 1, rnd:NextInteger(3, 4) do
			local pos = Vector3.new(r(-1.3, 1.3), -0.6, r(-0.7, 0.9))
			local dir = Vector3.new(r(-0.35, 0.35), 1, r(-0.1, 0.45)).Unit
			local w = r(0.4, 0.6)
			local segs = 4
			local len = height * r(0.7, 1.15) / segs
			local curl = r(0.15, 0.4)
			for g = 1, segs do
				local center = pos + dir * len / 2
				bit(Vector3.new(w, w, len + w * 0.4), along(center, dir), BRAMBLE_WOOD:Lerp(ROT_DARK, r(0, 0.6)))
				-- a gnarled knot at the bend
				bit(Vector3.new(w * 1.35, w * 1.35, w * 1.35), CFrame.new(pos), BRAMBLE_WOOD:Lerp(ROT_FLESH, r(0, 0.35)), Enum.Material.Wood, true)
				-- thorns
				for _ = 1, 2 do
					local tp = pos + dir * len * r(0.15, 0.9)
					local side = dir:Cross(Vector3.new(r(-1, 1), r(-1, 1), r(-1, 1))).Unit
					if side.Magnitude == side.Magnitude then -- (skip a NaN)
						local tl = r(0.35, 0.65)
						bit(Vector3.new(0.09, 0.09, tl), along(tp + side * (w / 2 + tl / 2), side + dir * 0.4), BRAMBLE_THORN, Enum.Material.Wood)
					end
				end
				-- now and then a swollen rot-pod or a short side shoot
				if rnd:NextNumber() < 0.3 then
					local side = dir:Cross(Vector3.new(0, 0, 1))
					side = side.Magnitude > 0.05 and side.Unit or Vector3.xAxis
					local sz = r(0.5, 0.9)
					bit(Vector3.new(sz, sz, sz), CFrame.new(pos + dir * len * 0.5 + side * (w / 2 + sz * 0.3)), ROT_FLESH:Lerp(SPORE, r(0, 0.3)), Enum.Material.SmoothPlastic, true)
				elseif rnd:NextNumber() < 0.45 then
					local sd = (dir + Vector3.new(r(-0.9, 0.9), r(-0.2, 0.3), r(-0.9, 0.9))).Unit
					local sl = len * r(0.5, 0.9)
					local sp = pos + dir * len * 0.6
					bit(Vector3.new(w * 0.45, w * 0.45, sl), along(sp + sd * sl / 2, sd), BRAMBLE_WOOD)
				end
				pos += dir * len
				dir = (dir + Vector3.new(r(-0.35, 0.35), -0.08 * g, -curl * g + r(-0.15, 0.15))).Unit
				w *= 0.7
			end
			-- the tip: a dripping hook, or a hanging pod
			if rnd:NextNumber() < 0.4 then
				local sz = r(0.45, 0.75)
				bit(Vector3.new(sz, sz, sz), CFrame.new(pos + Vector3.new(0, -sz / 2, 0)), ROT_FLESH, Enum.Material.SmoothPlastic, true)
			else
				bit(Vector3.new(0.08, 0.08, 0.7), along(pos + dir * 0.35, dir), BRAMBLE_THORN)
			end
		end
		-- the clump of rot at its foot, and roots creeping along the stone either
		-- way round the ring to meet the next cluster
		bit(Vector3.new(3.2, 0.5, 2.6), CFrame.new(0, 0.05, 0) * CFrame.Angles(0, r(-0.4, 0.4), 0), ROT_DARK, Enum.Material.Slate)
		for _, sx in ipairs({ -1, 1 }) do
			for k = 1, 2 do
				local l = r(4, 7)
				local off = Vector3.new(sx * (1 + l / 2), 0.05 + k * 0.08, r(-0.6, 0.6))
				bit(Vector3.new(r(0.3, 0.5), r(0.25, 0.4), l), CFrame.new(off) * CFrame.Angles(r(-0.05, 0.05), math.pi / 2 + r(-0.25, 0.25), 0), BRAMBLE_WOOD:Lerp(ROT_DARK, r(0, 0.5)))
			end
		end
		-- spores drift off it
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
		pe.Rate = 2
		pe.Lifetime = NumberRange.new(2, 3.5)
		pe.Speed = NumberRange.new(0.3, 1.2)
		pe.SpreadAngle = Vector2.new(40, 40)
		pe.EmissionDirection = Enum.NormalId.Top
		pe.Drag = 0.8
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 3) })
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.75), NumberSequenceKeypoint.new(1, 1) })
		pe.Color = ColorSequence.new(SPORE)
		pe.LightEmission = 0.15
		pe.Parent = root
		return model, root, pe
	end

	local function rotTether(a)
		local TT = CFG.Tether
		if not TT or TT.Enabled == false then
			return
		end
		local function on()
			local st: string = U.state
			return U.gen == a.gen and U.current == a and U.phase2 and st == "fight" and a.hum.Parent ~= nil and a.hum.Health > 0
		end
		local floorY = HOME.Position.Y - 3
		local N = TT.Clusters or 18
		local H = TT.BrambleHeight or 7
		local folder = Instance.new("Folder")
		folder.Name = "RotTether"
		folder.Parent = workspace
		local roots, emitters = {}, {}
		local seed = math.random(1, 1e6)
		for i = 1, N do
			local model, root, pe = bramble(seed + i * 17, H * (0.8 + ((i * 7) % 5) * 0.1))
			model.Parent = folder
			roots[i] = root
			emitters[i] = pe
		end
		-- the tear of them coming up through the floor
		playSound(a.root, SOUNDS.Impact, 0.8, 0.35)
		playSound(a.root, SOUNDS.Groan, 0.5, 0.5)
		ctx.FxRemote:FireAllClients("Shake", a.root.Position, 0.5)
		if TT.Warning and TT.Warning ~= "" then
			for _, pl in ipairs(Players:GetPlayers()) do
				local char, _, hrp = ctx.aliveChar(pl)
				if char and inChapel(hrp.Position) then
					ctx.FxRemote:FireClient(pl, "Message", TT.Warning)
				end
			end
		end
		local t0 = now()
		local RISE = 1.8
		local outSince = {}
		local nextTick = t0 + RISE -- nothing hurts until they've finished rising
		local phase = 0
		local center = a.root.Position
		local last = {}
		local function radius()
			local k = math.clamp((now() - t0) / TT.ShrinkTime, 0, 1)
			k = 1 - (1 - k) * (1 - k) -- quick at first, slowing as it nears the end
			return TT.StartRadius + (TT.MinRadius - TT.StartRadius) * k
		end
		local function place(r, sink, t)
			for i = 1, N do
				local th = phase + (i / N) * math.pi * 2
				local pos = Vector3.new(center.X + math.cos(th) * r, floorY - sink, center.Z + math.sin(th) * r)
				local inward = Vector3.new(center.X, pos.Y, center.Z)
				local sway = CFrame.Angles(math.sin(t * 0.7 + i * 1.3) * 0.035, 0, math.cos(t * 0.55 + i * 0.9) * 0.035)
				local cf = CFrame.lookAt(pos, inward) * sway
				roots[i].CFrame = cf
				last[i] = cf
			end
		end
		while on() do
			local dt = RunService.Heartbeat:Wait()
			if not on() then
				break
			end
			local t = now()
			local r = radius()
			center = a.root.Position
			phase += dt * 0.05 -- the ring creeps round, slowly
			local rise = math.clamp((t - t0) / RISE, 0, 1)
			rise = 1 - (1 - rise) ^ 3
			place(r, (1 - rise) * (H + 2), t)
			if t >= nextTick then
				local step = TT.TickTime or 0.5
				nextTick = t + step
				for _, pl in ipairs(Players:GetPlayers()) do
					local char, _, hrp = ctx.aliveChar(pl)
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					if hum and hum.Health > 0 and inChapel(hrp.Position) and flat(hrp.Position - center).Magnitude > r then
						outSince[pl] = outSince[pl] or t
						local out = t - outSince[pl]
						-- spores gather round you as a warning, even during the grace
						sporePuff(hrp.Position + Vector3.new(0, 1, 0), out < TT.Grace and 2 or 5, 0.7, 1.5)
						if out >= TT.Grace then
							local ramp = math.clamp((out - TT.Grace) / TT.RampTime, 0, 1)
							local dps = TT.DPS + (TT.DPSMax - TT.DPS) * ramp
							hum.Health = math.max(0, hum.Health - dps * step)
						end
					else
						outSince[pl] = nil
					end
				end
			end
		end
		-- she died, the fight reset, or everyone left: the brambles sink back into the floor
		for _, pe in ipairs(emitters) do
			pe.Enabled = false
		end
		task.spawn(function()
			local s0 = now()
			while now() - s0 < 1.4 and folder.Parent do
				local k = (now() - s0) / 1.4
				for i, root in ipairs(roots) do
					if root.Parent and last[i] then
						root.CFrame = last[i] - Vector3.new(0, k * k * (H + 2), 0)
					end
				end
				RunService.Heartbeat:Wait()
			end
			folder:Destroy()
		end)
	end

	api.fall = function(a)
		U.state = "fallen"
		U.transition = true
		setTrail(a, false)
		sparks(a, false)
		local root = a.root
		root.Anchored = false
		pcall(function()
			root:SetNetworkOwner(nil)
		end)
		a.hum:MoveTo(root.Position)
		a.hum.AutoRotate = false
		if U.barOn then
			ReplicatedStorage:SetAttribute("BossHP", 0)
		end
		local mus = ReplicatedStorage:GetAttribute("Music")
		if mus == "usher" then
			ReplicatedStorage:SetAttribute("Music", "none")
		end
		playSound(root, SOUNDS.Groan, 1, 0.8)
		pose(a, "UKneelGrip", 0.6)
		bodyPose(a, "Recover", 0.25)
		task.delay(0.3, function()
			if U.gen == a.gen then
				bodyPose(a, "UKneel", 0.9)
			end
		end)
		for _, d in ipairs(blindfolds(a)) do
			TweenService:Create(d, TweenInfo.new(1.2), { Color = Color3.fromRGB(8, 8, 8) }):Play()
		end
		task.delay(1, function()
			if U.gen == a.gen and U.barOn then
				U.barOn = false
				ReplicatedStorage:SetAttribute("BossActive", false)
			end
		end)
		local function still()
			local st: string = U.state
			return U.gen == a.gen and st == "fallen" and a.hum.Parent ~= nil
		end
		local stopBreath = breathing(a, (3.4 + 0.45 + 0.4 + 1.1) * FALL)
		task.wait(3.4 * FALL)
		if not still() then
			return
		end
		-- something stirs under the robe: a twitch, a breath of spores
		local head = a.model:FindFirstChild("Head")
		bodyPose(a, "Stagger", 0.08)
		sporePuff(head and head.Position or root.Position, 6, 0.8, 2)
		playSound(root, SOUNDS.Unsheath, 0.4, 0.45)
		task.wait(0.45 * FALL)
		if not still() then
			return
		end
		bodyPose(a, "UKneel", 0.2)
		task.wait(0.4 * FALL)
		if not still() then
			return
		end
		-- the tell for the burst: the growth in her hood flares and stays lit,
		-- spores pour out of her, the altar's growth swells with light
		bodyPose(a, "UListen", 0.35)
		for _, d in ipairs(blindfolds(a)) do
			d.Color = BLIND_FLARE
		end
		if ctx.Map.UsherHeart then
			ctx.Map.UsherHeart:SetAttribute("Base", 3)
		end
		playSound(root, SOUNDS.Groan, 0.9, 0.7)
		for i = 0, 3 do
			task.delay(i * 0.25 * FALL, function()
				if still() then
					sporePuff((head and head.Position or root.Position), 8, 1, 3)
				end
			end)
		end
		task.wait(1.1 * FALL)
		if not still() then
			return
		end
		stopBreath()
		local center = Vector3.new(root.Position.X, 0.2, root.Position.Z)
		sporePuff(center + Vector3.new(0, 2, 0), 34, 3, 14)
		ctx.dustCloud(center + Vector3.new(0, 0.6, 0), 4, 16)
		ctx.FxRemote:FireAllClients("Shake", center, 1)
		playSound(root, SOUNDS.Groan, 1, 1.05)
		for _, pl in ipairs(Players:GetPlayers()) do
			local char, _, hrp = ctx.aliveChar(pl)
			if char and flat(hrp.Position - center).Magnitude <= 7.5 then
				ctx.damagePlayer(pl, dmg(CFG.Damage.Burst), center, "Medium")
			end
		end
		growRot(a)
		local okM, errM = pcall(mutate, a) -- looks only: never let it stop the fight
		if not okM and ctx.Config.Debug then
			warn("[Oculast] mutate failed: " .. tostring(errM))
		end
		U.phase2 = true
		U.transition = false
		a.hum.WalkSpeed = CFG.WalkSpeed2
		a.hum.Health = math.min(a.hum.Health, CFG.HP2)
		for _, d in ipairs(blindfolds(a)) do
			TweenService:Create(d, TweenInfo.new(0.8), { Color = BLIND_P2 }):Play()
		end
		if ctx.Map.UsherHeart then
			ctx.Map.UsherHeart:SetAttribute("Base", 2.4)
		end
		bodyPose(a, "Roar", 0.3)
		pose(a, "URaise", 0.35)
		showBar(a, true) -- the second bar (the music waits for her to stand)
		task.wait(0.9 * FALL)
		if not still() then
			return
		end
		ready(a)
		if CFG.Music and CFG.Music ~= "" then
			ReplicatedStorage:SetAttribute("Music", "usher2")
		end
		bodyPose(a, "Idle", 0.3)
		U.cd = {}
		U.lastMove = nil
		U.staggerUntil = 0
		U.poise = nil
		U.state = "fight"
		task.spawn(rotTether, a) -- the ring rises and starts closing in
		brain(a)
	end

	local function startFight(a)
		local root = a.root
		root.Anchored = false
		pcall(function()
			root:SetNetworkOwner(nil)
		end)
		U.state = "fight"
	end

	-- she lifts her head, listens, rises and turns to face you
	local function wake(a, byHit, pl)
		if U.state ~= "kneel" or U.gen ~= a.gen then
			return
		end
		U.state = "waking"
		showBar(a)
		local function stillWaking()
			local st: string = U.state
			return U.gen == a.gen and st == "waking"
		end
		task.spawn(function()
			local tChar = pl and pl.Character
			if byHit then
				-- struck at her vigil: she answers at once
				startFight(a)
				turnabout(a, tChar, pl, true)
				if live(a) then
					brain(a)
				end
				return
			end
			bodyPose(a, "UListen", 0.5)
			tell(a, 1.05)
			task.wait(0.8)
			if not stillWaking() then
				return
			end
			bodyPose(a, "Idle", 0.9)
			pose(a, "UIdle", 0.9)
			playSound(a.root, SOUNDS.Unsheath, 0.6, 0.7)
			local base = select(2, bladePoints(a))
			if base then
				sparkBurst(Vector3.new(base.X, 0.3, base.Z), 10)
			end
			task.wait(0.7)
			-- turns, slowly, toward the sound
			local t0 = now()
			while now() - t0 < 0.9 and stillWaking() do
				local dt = task.wait()
				local tr = tChar and tChar:FindFirstChild("HumanoidRootPart")
				if tr then
					ctx.turnTowards(a.root, tr.Position, math.rad(240) * dt)
				end
			end
			if not stillWaking() then
				return
			end
			playSound(a.root, SOUNDS.Groan, 0.8, 1.15)
			startFight(a)
			brain(a)
		end)
	end

	-- kneeling: listen for intruders. returning: walk home, kneel, heal.
	watch = function(a)
		while U.gen == a.gen and a.hum.Parent and a.hum.Health > 0 do
			if U.state == "returning" then
				local tChar = target(a)
				if tChar then
					-- someone came back in before she got home
					showBar(a)
					U.state = "fight"
					brain(a)
					return
				end
				local home = HOME.Position
				if flat(a.root.Position - home).Magnitude > 2 then
					a.hum.AutoRotate = true
					a.hum:MoveTo(Vector3.new(home.X, a.root.Position.Y, home.Z))
				else
					a.hum.AutoRotate = false
					kneelAtHome(a)
				end
			elseif U.state == "kneel" then
				for _, pl in ipairs(Players:GetPlayers()) do
					local char, _, hrp = ctx.aliveChar(pl)
					if char and inChapel(hrp.Position) then
						local d = flat(hrp.Position - a.root.Position).Magnitude
						if d < CFG.WakeQuiet or (d < CFG.WakeNoisy and noisy(pl)) then
							wake(a, false, pl)
							break
						end
					end
				end
			else
				return
			end
			task.wait(0.15)
		end
	end

	---------------------------------------------------------------------------
	-- life and death
	---------------------------------------------------------------------------
	local function onDied(a)
		if U.gen ~= a.gen or U.state == "dead" then
			return
		end
		U.state = "dead"
		ctx.Save.mark("Usher")
		U.barOn = true
		hideBar()
		clearAllPoison() -- the rot dies with her
		ctx.FxRemote:FireAllClients("Banner", "USHER FELLED", "Victory")
		ctx.dropSplinter(a.root.Position, a.model)
		playSound(a.root, SOUNDS.Groan, 1, 0.9)
		if ctx.Map.UsherHeart then
			ctx.Map.UsherHeart:SetAttribute("Base", 0.35) -- the altar's growth gutters
		end
		for _, d in ipairs(a.model:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
			end
		end
		task.spawn(function()
			for _ = 1, 5 do
				if a.root.Parent then
					sporePuff(a.root.Position + Vector3.new(rand(-2, 2), rand(-1, 3), rand(-2, 2)), 12, 1.5, 4)
				end
				task.wait(0.3)
			end
			for _, d in ipairs(a.model:GetDescendants()) do
				if d:IsA("BasePart") then
					TweenService:Create(d, TweenInfo.new(2), { Transparency = 1 }):Play()
				end
			end
			task.wait(2.2)
			a.model:Destroy()
		end)
		-- her reward: her harvest-blade, straight into your hands (moveset: Config.ScytheAttacks)
		task.delay(4, function()
			for _, pl in ipairs(Players:GetPlayers()) do
				pl:SetAttribute("Has_Scythe", true)
				ctx.equipWeapon(pl, "Scythe")
				ctx.FxRemote:FireClient(pl, "Message", ctx.Config.Weapons.Scythe.Name .. ". Her blade is yours now.")
			end
		end)
		-- the reliquary gate in the north wall rises (MapBuilder 9b)
		local gate = ctx.Map.UsherGate
		if gate then
			task.delay(8, function()
				playSound(gate.PrimaryPart, SOUNDS.Unsheath, 1, 0.3)
				local start = gate:GetPivot()
				for i = 1, 75 do
					gate:PivotTo(start + Vector3.new(0, 11.6 * (i / 75), 0))
					task.wait(1 / 30)
				end
				ctx.FxRemote:FireAllClients("Message", "In the chapel's north wall, a gate has opened.")
			end)
		end
	end

	api.spawn = function()
		if U.state == "dead" then
			return
		end
		if ctx.Save.done("Usher") then -- (felled in this save: gone, her growth guttering, the reliquary gate up)
			U.state = "dead"
			if ctx.Map.UsherHeart then
				ctx.Map.UsherHeart:SetAttribute("Base", 0.35)
			end
			local gate = ctx.Map.UsherGate
			if gate then
				gate:PivotTo(gate:GetPivot() + Vector3.new(0, 11.6, 0))
			end
			return
		end
		U.gen += 1
		local model, hum, weld = ctx.makeRig("Oculast", "Usher", S, "Scythe")
		if not model then
			return
		end
		hum.MaxHealth = CFG.HP + CFG.HP2 -- both lives; see showBar
		hum.Health = CFG.HP + CFG.HP2
		hum.WalkSpeed = CFG.WalkSpeed
		hum.BreakJointsOnDeath = false
		hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
		model:SetAttribute("Radius", 1.6)
		model:SetAttribute("Boss", true) -- uses the big bar, not a floating one
		model:SetAttribute("Enemy", true)
		local root = model:FindFirstChild("HumanoidRootPart")
		root.CollisionGroup = "EnemyRoot"
		model:PivotTo(HOME + Vector3.new(0, 3 * S - 3, 0))
		U.model, U.hum, U.root, U.weld = model, hum, root, weld
		U.phase2 = false
		U.transition = false
		U.staggerUntil = 0
		U.poise = nil
		U.cd = {}
		U.lastMove = nil
		U.mut = nil
		local a = { model = model, hum = hum, root = root, weld = weld, scale = S, gen = U.gen }
		U.current = a
		if ctx.Map.UsherHeart then
			ctx.Map.UsherHeart:SetAttribute("Base", 1.6)
		end
		hum.HealthChanged:Connect(function(h)
			if U.gen ~= a.gen or U.state == "dead" then
				return
			end
			if not U.phase2 then
				if h <= CFG.HP2 then
					-- her first life is spent: she can't drop past it, and she falls
					if h < CFG.HP2 then
						hum.Health = CFG.HP2
					end
					if not U.transition then
						U.transition = true
						task.spawn(api.fall, a)
					end
					return
				end
				if U.barOn then
					ReplicatedStorage:SetAttribute("BossHP", h - CFG.HP2)
				end
			elseif U.barOn then
				ReplicatedStorage:SetAttribute("BossHP", math.max(0, h))
			end
		end)
		hum.Died:Connect(function()
			onDied(a)
		end)
		kneelAtHome(a)
		task.spawn(watch, a)
	end

	api.reset = function()
		if U.state == "dead" or U.state == "none" then
			return
		end
		hideBar()
		if U.model then
			U.model:Destroy()
		end
		U.state = "none"
		api.spawn()
	end

	api.onHit = function(player)
		local a = U.current
		if a and U.state == "kneel" then
			wake(a, true, player)
		end
	end

	api.onPoiseBreak = function()
		local a = U.current
		if not a or U.state ~= "fight" then
			return
		end
		U.staggerUntil = now() + CFG.Stagger
		setTrail(a, false)
		sparks(a, false)
		if a.root.Anchored then
			a.root.Anchored = false -- broken out of a lunge
		end
		pose(a, "UIdle", 0.15)
		bodyPose(a, "Stagger", 0.12)
		a.hum:MoveTo(a.root.Position)
		playSound(a.root, SOUNDS.Groan, 0.9, 1.3)
		local head = a.model:FindFirstChild("Head")
		sporePuff(head and head.Position or a.root.Position, 10, 1, 4)
		local gen = a.gen
		task.delay(CFG.Stagger, function()
			if U.gen == gen and U.state == "fight" then
				ready(a)
				bodyPose(a, "Idle", 0.3)
			end
		end)
	end
end

return Usher
