--!nonstrict
-- THE KING OF PYRALIS (kind KingInquisitor): THE SUN-INQUISITOR - the blend of B (KingArmored) and C (KingPontiff)
-- that was chosen. B's plate gone darker still, near black, edged in gold - but shaped to a man, not a box: the rig's
-- blocks hidden under it, every plate a rounded shell (a sphere mesh stretched to fit), the chest broad and deep over
-- a narrow waist and narrower hips, great domed pauldrons, swelling upper arms and forearms, thighs and calves over
-- slim knees and ankles - the V of a fighting man. C's tiara forged in that steel on a round helm, its coronets
-- crowned in B's flame-points, ember-gems in them; the sun-mask its visor, plain-cheeked; C's halo turned to a ring of
-- flame-blades; a tabard of C's ivory before and behind, swinging cloth below a gold-framed yoke with a
-- burning sun in it; a black cope of many strips behind him to the floor, lined in red, swinging as he moves; in both hands C's sun-wheel made a
-- weapon - a glaive, a crescent blade off the wheel, edged in fire - held diagonally across his body, its head up
-- over his right shoulder. (The shared pieces: KingHybrid.)
--
-- THE MOVESET (M.attack, which the shared brain calls once you're in reach - Def.Engage). Quick, all of it:
--   from out of his cut's reach he closes it with one of his GYMNASTIC MOVES (M.Moves) -
--     Reaping Slide      up into the air, hung there a moment (the tell), then a dive onto his knees, sliding
--                        past you, the glaive out low on his right
--     Corkscrew Vault    up off the planted glaive, over you turning a turn and a half, down behind you blade-first
--   and inside it, any of everything:
--   Sun-Cleave   the glaive hauled up over his right shoulder, then wound further - the whole body coiled round to
--                the right, sunk on the back leg, chest thrown back, the glaive's head hanging out behind him - held
--                there; then all that weight thrown forward through it: he drives off the back leg, uncoils, and
--                brings the glaive down diagonally across his body to his left foot, the blade into the floor. Roll
--                in toward his right as he uncoils, or be out of its sweep.
--   ...the Sun-Fall the cut's weight isn't spent: it carries him round - the glaive swung on round behind him and
--                up his right side as he spins a full turn on his heel to face you again - down into a crouch, and he
--                LEAPS, the glaive raised over his head, arched back in the air, and comes down on you with it,
--                the blade driven into the floor: a ring of fire where he lands. Get out from under him.
--   ...and FOUR MORE COMBOS (M.Combos), never the same twice running:
--     Twin Crescent (2)  a rising backhand from low left, then a flat sweep back across
--     Sunwheel (3)       a flat sweep carried into a full turn on his heel (it cuts all round him), then down overhead
--     March (4)          chop after chop down across him, stepping on into you each time, then an arched overhead slam
--     Judgement (5)      two thrusts from the hip, a flat sweep, a rising backhand, and down overhead
--   HIS POSTURE  (the bar under his health) spent by his own attacks; full, he's down on a knee 7s, heaving for breath.
--   THE COURT    he waits unseen inside the passage of fire in its east wall. Come far enough up the court (past
--                SunkenCourt.Trigger) and the lift is sealed in fire, and THE CUTSCENE: you turn, slowly, and he walks
--                out of the fire, stops, stares at you, brandishes the glaive (every time; hold Space to skip). The
--                seal lifts when he's beaten, or no one's left alive in the court - and he walks back into the fire.
--   BEATEN       he doesn't die: he goes down on his knees for good, and talks (Config.King) - the Key of Flame,
--                how he took his sister's key, the Foul Key, and Giles.
local H = require(script.Parent:WaitForChild("KingHybrid"))
local Base = require(script.Parent:WaitForChild("KingGilded"))
local B, C = H.B, H.C
local rgb = Color3.fromRGB
local D = { metal = rgb(28, 26, 28), metalDk = rgb(14, 13, 14), gold = B.gold, goldDk = B.goldDk, ember = B.ember, flame = B.ember, sun = rgb(255, 150, 60), leather = B.leather }
local HIDE = { Head = true, Chest = true, Hips = true, RUpperArm = true, LUpperArm = true, RLowerArm = true, LLowerArm = true, RThigh = true, LThigh = true, RShin = true, LShin = true, RFoot = true, LFoot = true, Fist = true }

-- (twoHand: the left fist's place up the haft from the right, toward its butt; elbowOut: his elbows carried wide;
-- walkRef / cadence: his full stride at his own slow pace for his size - 11 studs a second is 2.4 of his body-units -
-- and steps that keep up with how far he goes, not his feet skating)
local M = H.new("KingInquisitor", { girth = 0.88, arm = 1.25, hunch = 0, twoHand = 1.3, elbowOut = 0.9, walkRef = 3.2, cadence = 1.5 }, { skin = D.metalDk, torso = D.metal, legs = D.metal, arms = D.metal }, "QBGuard", function(k)
	local deco, V, at, MAT = k.deco, k.V, k.at, k.MAT
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local fx = k.D.footSize.X / k.s
	-- the rig's own blocks (and the fists it was given) go unseen: the shells below are his shape
	for _, p in ipairs(k.parts.Chest.Parent:GetChildren()) do
		if p:IsA("BasePart") and HIDE[p.Name] then
			p.Transparency = 1
		end
	end
	-- a rounded shell: a part drawn as the ellipsoid that fills it
	local function shell(on, name, size, cf, col, mat)
		local p = deco(on, name, size, cf, col, mat or MAT.Metal)
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.Sphere
		m.Parent = p
		return p
	end
	local STEEL, DARK, GOLD, GOLD_DK, EMBER = D.metal, D.metalDk, D.gold, D.goldDk, D.ember

	-- (his head is the rig's - a size every character shares, too big on him: everything on it drawn smaller, about the
	-- base of his neck, so it sits down on his shoulders)
	local HEADK = 0.72
	local realDeco, neck = k.deco, Vector3.new(0, -k.D.headSize.Y / 2, 0)
	k.deco = function(on, name, size, cf, ...)
		if on == "Head" then
			size, cf = size * HEADK, CFrame.new(neck + (cf.Position - neck) * HEADK) * cf.Rotation
		end
		return realDeco(on, name, size, cf, ...)
	end
	deco = k.deco
	-- THE HELM: a rounded bowl, a jaw-guard under it, a gold rim at the brow, the sun-mask its visor; the tiara on top
	shell("Head", "Helm", V(1.42, 1.5, 1.32), at(0, 0.1, 0.05), STEEL)
	shell("Head", "HelmJaw", V(1.3, 0.8, 1.18), at(0, -0.35, 0.06), DARK)
	shell("Head", "HelmBrow", V(1.46, 0.12, 1.36), at(0, 0.38, 0.05), GOLD)
	Base.Mask(k, GOLD, GOLD_DK, rgb(255, 170, 60), true)
	H.tiara(k, D, 0.92, DARK, { EMBER, C.panel[2] }, true)
	H.halo(k, D, 1.75, 0.6, 1.0, true)
	-- the gorget: three rounded rings stepping out down the neck
	for i = 0, 2 do
		local w = 1.35 + i * 0.25
		shell("Head", "Gorget", V(w, 0.26, w * 0.92), at(0, -0.72 - i * 0.15, 0.04), i == 1 and STEEL or DARK)
	end
	shell("Head", "GorgetEdge", V(1.88, 0.06, 1.75), at(0, -0.96, 0.04), GOLD)
	k.deco, deco = realDeco, realDeco -- (the head done: the rest at full size)

	-- THE TORSO: deep chest and broad back over a narrow waist - shells overlapping like the plates of a cuirass
	shell("Chest", "Thorax", V(cw * 1.04, ch * 0.95, cd * 1.18), at(0, ch * 0.1, 0), STEEL)
	shell("Chest", "Shoulders", V(cw * 1.14, ch * 0.4, cd * 1.0), at(0, ch * 0.36, 0.05), DARK)
	for _, sx in ipairs({ -1, 1 }) do
		shell("Chest", "Pectoral", V(cw * 0.42, ch * 0.42, cd * 0.5), at(sx * cw * 0.18, ch * 0.2, -cd * 0.36), STEEL)
		shell("Chest", "PectoralRim", V(cw * 0.42, 0.07, cd * 0.42), at(sx * cw * 0.18, ch * 0.0, -cd * 0.38) * CFrame.Angles(0, 0, -sx * 0.1), GOLD)
		shell("Chest", "Lat", V(cw * 0.26, ch * 0.75, cd * 0.85), at(sx * cw * 0.36, ch * 0.02, 0.06) * CFrame.Angles(0, 0, sx * 0.22), DARK)
		shell("Chest", "Shoulderblade", V(cw * 0.36, ch * 0.42, cd * 0.4), at(sx * cw * 0.17, ch * 0.22, cd * 0.4), STEEL)
	end
	deco("Chest", "Sternum", V(0.1, ch * 0.5, 0.08), at(0, ch * 0.12, -cd * 0.6), GOLD, MAT.Metal)
	-- the sun-boss at the breast's heart, burning
	deco("Chest", "SunBossRim", V(0.12, 0.66, 0.66), at(0, ch * 0.12, -cd * 0.6) * Base.FACE, GOLD_DK, MAT.Metal, Base.cyl)
	Base.sun(k, "Chest", at(0, ch * 0.12, -cd * 0.66), 0.3, GOLD, EMBER)
	local glow = deco("Chest", "SunBossGlow", V(0.2, 0.2, 0.2), at(0, ch * 0.12, -cd * 0.4), EMBER, MAT.Neon)
	glow.Transparency = 1
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = EMBER, 9 * k.s / Base.Scale, 1.1
	l.Parent = glow
	-- the waist: narrowing in lames to the belt, the abdomen's plates down its front
	for i = 0, 2 do
		local w = 0.76 - i * 0.06
		shell("Chest", "Waist", V(cw * w, 0.42, cd * (0.98 - i * 0.05)), at(0, -ch * 0.24 - i * 0.2, 0.02), i % 2 == 0 and DARK or STEEL)
		shell("Chest", "Abdomen", V(cw * (0.44 - i * 0.04), 0.26, 0.3), at(0, -ch * 0.2 - i * 0.2, -cd * (0.42 - i * 0.02)), STEEL)
		shell("Chest", "AbdomenEdge", V(cw * (0.44 - i * 0.04), 0.05, 0.26), at(0, -ch * 0.2 - i * 0.2 - 0.12, -cd * (0.43 - i * 0.02)), GOLD)
	end

	-- THE HIPS: a narrower pelvis, faulds flaring a little over the tops of the thighs, a studded belt
	shell("Hips", "Pelvis", V(hw * 0.86, 0.95, hd * 1.02), at(0, 0.05, 0), STEEL)
	for i = 0, 2 do
		shell("Hips", "Fauld", V(hw * (0.9 + i * 0.07), 0.24, hd * (1.06 + i * 0.07)), at(0, 0.2 - i * 0.17, 0), i % 2 == 0 and DARK or STEEL)
	end
	shell("Hips", "Belt", V(hw * 0.92, 0.16, hd * 1.1), at(0, 0.4, 0), D.leather, MAT.Leather)
	Base.studs(k, "Hips", 5, -hw * 0.3, hw * 0.3, 0.4, -hd * 0.55, 0.07, GOLD)

	-- THE ARMS: a great domed pauldron of lames, a swelling upper arm, a round couter, a forearm thick at the elbow
	-- and narrowing to the wrist, a gauntleted fist
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		local u, f = n .. "UpperArm", n .. "LowerArm"
		shell(u, "Pauldron", V(aw * 2.05, aw * 1.45, aw * 1.9), at(sx * 0.1, ua * 0.4, 0), STEEL)
		for j = 1, 3 do
			local w = aw * (2.05 - j * 0.1)
			shell(u, "PauldronLame", V(w, 0.3, w * 0.92), at(sx * (0.12 + j * 0.03), ua * (0.36 - j * 0.12), 0) * CFrame.Angles(0, 0, -sx * 0.3), j % 2 == 0 and STEEL or DARK)
			shell(u, "PauldronEdge", V(w + 0.02, 0.05, w * 0.92 + 0.02), at(sx * (0.12 + j * 0.03), ua * (0.36 - j * 0.12) - 0.13, 0) * CFrame.Angles(0, 0, -sx * 0.3), GOLD)
		end
		Base.sun(k, u, at(sx * 0.15, ua * 0.4, -aw * 1.07), 0.15, GOLD)
		shell(u, "Bicep", V(aw * 1.18, ua * 0.85, aw * 1.14), at(0, -ua * 0.08, 0), STEEL)
		shell(u, "ArmBand", V(aw * 1.2, 0.07, aw * 1.15), at(0, -ua * 0.42, 0), GOLD)
		deco(f, "Couter", V(aw * 1.0, aw * 1.0, aw * 1.0), at(0, la * 0.44, 0.04), DARK, MAT.Metal, Base.ball)
		shell(f, "Forearm", V(aw * 1.22, la * 0.6, aw * 1.15), at(0, la * 0.14, 0), STEEL)
		shell(f, "Wrist", V(aw * 0.92, la * 0.5, aw * 0.88), at(0, -la * 0.2, 0), DARK)
		shell(f, "GauntletCuff", V(aw * 1.3, 0.12, aw * 1.25), at(0, -la * 0.38, 0), GOLD)
		shell(f, "Gauntlet", V(aw * 1.0, 0.5, aw * 1.05), at(0, -la / 2 - 0.1, 0), DARK)
		Base.studs(k, f, 3, -aw * 0.3, aw * 0.3, -la / 2 - 0.08, -aw * 0.55, 0.07, GOLD_DK)
	end

	-- THE LEGS: thighs full under riveted tassets, round knees, calves swelling over slim ankles, pointed sabatons
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		local t, s, ft = n .. "Thigh", n .. "Shin", n .. "Foot"
		shell(t, "Cuisse", V(lw * 1.24, 1.38, lw * 1.2), at(0, 0.02, 0), STEEL)
		for j = 0, 1 do
			shell(t, "Tasset", V(lw * 1.45, 0.42, 0.3), at(0, 0.38 - j * 0.3, -lw * 0.6 - j * 0.02), j == 0 and DARK or STEEL)
			shell(t, "TassetEdge", V(lw * 1.4, 0.05, 0.26), at(0, 0.38 - j * 0.3 - 0.18, -lw * 0.62 - j * 0.02), GOLD)
		end
		deco(s, "Poleyn", V(lw * 0.98, lw * 0.98, lw * 0.98), at(0, 0.55, -0.06), DARK, MAT.Metal, Base.ball)
		Base.sun(k, s, at(0, 0.55, -lw * 0.6), 0.14, GOLD)
		deco(s, "PoleynFan", V(0.06, lw * 1.15, lw * 1.15), at(sx * lw * 0.55, 0.55, -0.04), STEEL, MAT.Metal, Base.cyl)
		shell(s, "Calf", V(lw * 1.14, 0.85, lw * 1.2), at(0, 0.12, 0.03), STEEL)
		shell(s, "Ankle", V(lw * 0.86, 0.7, lw * 0.9), at(0, -0.3, 0), DARK)
		deco(s, "GreaveRidge", V(0.07, 0.75, 0.07), at(0, 0.0, -lw * 0.66) * CFrame.Angles(0, math.pi / 4, 0), GOLD, MAT.Metal)
		shell(s, "GreaveBand", V(lw * 1.05, 0.07, lw * 1.08), at(0, -0.5, 0), GOLD)
		shell(ft, "Sabaton", V(fx * 1.15, 0.4, 1.15), at(0, 0.02, -0.05), DARK)
		shell(ft, "SabatonToe", V(fx * 0.7, 0.26, 0.6), at(0, -0.02, -0.5), STEEL)
		shell(ft, "SabatonEdge", V(fx * 1.1, 0.06, 0.9), at(0, 0.16, -0.1), GOLD)
	end

	H.tabardCloth(k, C.ivory, GOLD, GOLD_DK, EMBER, C.panel)
	H.copeCloth(k, rgb(22, 18, 20), rgb(12, 10, 12), rgb(90, 14, 16), cw * 0.58, 10)
end)

---------------------------------------------------------------------------
-- POSES AND GRIPS
---------------------------------------------------------------------------
-- body poses: the guard, and the Sun-Cleave's raise, coil, cut and follow-through - every joint in them. (twist +:
-- turned to his right; lean +: forward; head +: down; hip: the pelvis's own turn; side: a lean to his left; footR /
-- footL: each foot's place ahead (+) or behind; drop: sunk at the knees)
M.Poses = table.clone(H.Poses)
for name, p in pairs({
	-- guard: square, a little sunk, the glaive across him, his weight even
	QBGuard = { drop = 0.22, lean = 0.06, twist = 0.18, hip = 0.08, head = 0.06, footR = -0.4, footL = 0.45, spread = 0.18, breathe = 1.3, freeL = 0 },
	-- the raise: weight rocking back, chest opening to the right, chin up to watch you under it
	QBRaise = { drop = 0.4, lean = -0.3, twist = 0.62, hip = 0.32, side = -0.1, head = -0.22, footR = -0.75, footL = 0.62, spread = 0.26, breathe = 2.2, freeL = 0 },
	-- the coil: wound as far round as he goes, sunk deep on the back leg, chest thrown back, hips turned after it
	QBCoil = { drop = 0.78, lean = -0.48, twist = 1.0, hip = 0.5, side = -0.22, head = -0.3, footR = -0.95, footL = 0.8, spread = 0.36, breathe = 3.2, freeL = 0 },
	-- the cut: driven off the back leg onto the front, uncoiled hard round to the left, bent down after the blade
	QBCleave = { drop = 0.95, lean = 0.78, twist = -0.72, hip = -0.42, side = 0.16, head = 0.36, footR = 0.15, footL = 1.0, spread = 0.36, freeL = 0 },
	-- the follow-through: carried on round and down by its weight
	QBFollow = { drop = 1.12, lean = 0.92, twist = -0.98, hip = -0.52, side = 0.22, head = 0.46, footR = 0.05, footL = 1.05, spread = 0.42, freeL = 0 },
	-- the Sun-Fall: spun round on it - hips leading the turn, the chest dragged after, low and wide
	QBSpin = { drop = 0.75, lean = 0.45, twist = 0.45, hip = -0.75, side = 0.18, head = 0.15, footR = 0.45, footL = -0.35, spread = 0.42, breathe = 3, freeL = 0 },
	-- coming out of the turn: the chest whipping round past the hips, rising, the glaive coming up his right side
	QBSpinOut = { drop = 0.55, lean = 0.15, twist = -0.35, hip = 0.4, side = -0.12, head = -0.1, footR = -0.4, footL = 0.5, spread = 0.36, freeL = 0 },
	-- loading: still turning, sunk under the turn onto both legs, the chest over them, about to drive up
	QBLoad = { drop = 1.3, lean = 0.5, twist = 0.1, hip = -0.3, side = 0.1, head = -0.15, footR = -0.25, footL = 0.4, spread = 0.42, breathe = 4, freeL = 0 },
	-- the crouch: down deep on both legs, gathered, chest over the knees, ready to spring
	QBCrouch = { drop = 1.4, lean = 0.55, twist = 0.15, hip = 0.1, head = -0.15, footR = -0.35, footL = 0.45, spread = 0.4, breathe = 4, freeL = 0 },
	-- in the air: back arched, the knees drawn up, the glaive high over him
	QBAir = { drop = 0.35, lean = -0.45, twist = 0.22, head = -0.35, tuck = 0.55, footR = -0.25, footL = 0.3, spread = 0.2, freeL = 0 },
	-- over the top and down: folding forward onto it, the legs reaching for the floor
	QBDive = { drop = 0.45, lean = 0.55, twist = -0.1, head = 0.3, tuck = 0.2, footR = 0.45, footL = -0.15, spread = 0.32, freeL = 0 },
	-- his entrance: the glaive wrenched up out of the floor and held up before him, leaning back from it a little
	QBCast = { drop = 0.3, lean = -0.18, twist = 0.12, head = -0.18, footR = -0.45, footL = 0.45, spread = 0.26, breathe = 3, freeL = 0 },
	-- reared back for an overhead: bent back at every joint - knees sunk and forward, the waist thrown back, the head back
	QBArch = { drop = 0.65, lean = -0.78, twist = 0.06, side = -0.05, head = -0.55, footR = -0.85, footL = 0.75, spread = 0.34, breathe = 3.5, freeL = 0 },
	-- an overhead driven into the floor: folded all the way over it, the front knee deep
	QBLine = { drop = 1.25, lean = 1.0, twist = -0.05, head = 0.45, footR = -0.8, footL = 0.9, spread = 0.44, breathe = 4, freeL = 0 },
	-- on one knee, bowed over the glaive planted beside him: waiting for you, or his posture broken
	QBKneel = { drop = 1.6, lean = 0.55, twist = 0.1, head = 0.5, footR = -0.95, footL = 0.7, spread = 0.38, breathe = 2.5, freeL = 0 },
	-- rising from it: the head up first, the back straightening, still down on the knee
	QBRise = { drop = 1.3, lean = 0.1, twist = 0.05, head = -0.3, footR = -0.8, footL = 0.65, spread = 0.36, breathe = 3, freeL = 0 },
	-- the butt-spike: the glaive hauled forward through his hands, hunched over it...
	-- ...and driven straight back, stepping back onto it, the chest thrown back after it
	-- the gymnastic moves: crouched for the slide, the glaive out on his right; the low hop, tucked; and down on his
	-- knees sliding, leant back, the feet trailing behind
	QBSlideLoad = { drop = 0.8, lean = 0.6, twist = 0.3, hip = 0.2, head = -0.1, footR = -0.6, footL = 0.5, spread = 0.35, breathe = 3, freeL = 0 },
	QBTuckHop = { drop = 0.4, lean = 0.3, tuck = 0.6, head = -0.1, footR = -0.2, footL = 0.2, spread = 0.3, freeL = 0 },
	QBHover = { drop = 0.3, lean = -0.45, twist = 0.35, hip = 0.2, side = -0.1, head = -0.25, tuck = 0.65, footR = -0.3, footL = 0.25, spread = 0.3, breathe = 3, freeL = 0 },
	QBKneeSlide = { drop = 1.75, lean = -0.5, twist = 0.35, hip = 0.25, side = -0.15, head = -0.35, footR = -1.1, footL = -0.9, spread = 0.45, breathe = 3, freeL = 0 },
	-- the combos' swings: low on his left, the backhand up past his right shoulder
	QBLowL = { drop = 0.75, lean = 0.45, twist = -0.6, hip = -0.3, side = 0.1, head = 0.2, footR = 0.15, footL = 0.65, spread = 0.36, breathe = 2.5, freeL = 0 },
	QBRiseR = { drop = 0.3, lean = -0.28, twist = 0.62, hip = 0.32, side = -0.12, head = -0.25, footR = -0.55, footL = 0.5, spread = 0.32, freeL = 0 },
	-- wound round to his right for a flat sweep, and through it to his left
	QBWindR = { drop = 0.55, lean = 0.1, twist = 0.88, hip = 0.42, side = -0.12, head = -0.05, footR = -0.75, footL = 0.6, spread = 0.38, breathe = 2.5, freeL = 0 },
	QBSweepL = { drop = 0.68, lean = 0.38, twist = -0.88, hip = -0.46, side = 0.14, head = 0.15, footR = 0.2, footL = 0.88, spread = 0.4, freeL = 0 },
	-- up over his left shoulder, and chopped down across him to his right
	QBWindL = { drop = 0.45, lean = -0.22, twist = -0.72, hip = -0.32, side = 0.1, head = -0.18, footR = 0.5, footL = -0.4, spread = 0.32, breathe = 2.5, freeL = 0 },
	QBChopR = { drop = 0.92, lean = 0.72, twist = 0.52, hip = 0.32, side = -0.12, head = 0.36, footR = 0.88, footL = -0.1, spread = 0.36, freeL = 0 },
	-- drawn back for the thrust, weight on the back leg; and driven out, lunging onto the front
	QBThrustLoad = { drop = 0.62, lean = -0.12, twist = 0.48, hip = 0.32, head = -0.05, footR = -0.85, footL = 0.7, spread = 0.3, breathe = 2.5, freeL = 0 },
	QBThrust = { drop = 0.58, lean = 0.58, twist = -0.22, hip = -0.16, head = 0.1, footR = -0.45, footL = 1.15, spread = 0.3, freeL = 0 },
	-- landed: all of it into the blade - sunk to one knee nearly, bowed over the glaive
	QBSlam = { drop = 1.5, lean = 1.0, twist = 0, head = 0.55, footR = -0.75, footL = 0.85, spread = 0.46, breathe = 4, freeL = 0 },
}) do
	M.Poses[name] = p
end
M.BodyFor = { QGuard = "QBGuard" }
-- the glaive's grips: the right fist's place (studs from the root, at scale 1) and the way the glaive's head points
-- from it (its grip's -Y); the left fist rides 1.3 up the haft from the right (M.Proportions.twoHand)
local function grip(pos, head)
	local y = -head.Unit
	local x = Vector3.yAxis:Cross(y)
	x = x.Magnitude > 1e-3 and x.Unit or Vector3.xAxis
	return { pos * Vector3.new(1.2, 1, 1.2), CFrame.fromMatrix(Vector3.zero, x, y, x:Cross(y)) } -- (a fifth further out from him)
end
M.Grips = {
	QGuard = grip(Vector3.new(0.55, 0.9, -0.9), Vector3.new(0.55, 0.8, 0.15)), -- across him: head up over his right shoulder, butt by his left hip
	QRaise = grip(Vector3.new(0.95, 2.5, 0.1), Vector3.new(0.35, 0.55, 0.75)), -- hauled up over the shoulder, the head going back
	QCoil = grip(Vector3.new(1.3, 2.2, 0.8), Vector3.new(0.25, 0.25, 0.93)), -- wound back behind him, the head hanging out behind
	QCleave = grip(Vector3.new(-0.9, -0.6, -1.4), Vector3.new(-0.6, -0.5, -0.62)), -- brought down across him: the head at his left foot
	QFollow = grip(Vector3.new(-1.15, -0.75, -1.0), Vector3.new(-0.75, -0.4, -0.5)), -- carried on round past it
	QSpinBack = grip(Vector3.new(-0.9, 0.4, 1.2), Vector3.new(-0.5, -0.2, 0.85)), -- swung on round behind him, low
	QSpinUp = grip(Vector3.new(1.2, 1.8, 0.3), Vector3.new(0.6, 0.7, 0.3)), -- and up his right side
	QOverhead = grip(Vector3.new(0.3, 3.0, 0.4), Vector3.new(0.1, 0.35, 0.93)), -- high over his head, its head back behind him
	QSlam = grip(Vector3.new(0.1, -0.4, -1.8), Vector3.new(0.05, -0.75, -0.66)), -- driven down before him into the floor
	QCast = grip(Vector3.new(0.35, 1.4, -1.3), Vector3.new(0.05, 1, -0.15)), -- held up before him, upright, the wheel high
	QKneel = grip(Vector3.new(0.9, -0.3, -0.9), Vector3.new(0.1, -1, -0.1)), -- planted head-down in the floor beside him, leant on
	QLowLeft = grip(Vector3.new(-0.9, -0.2, -0.8), Vector3.new(-0.6, -0.6, 0.3)), -- low on his left, the head trailing down behind
	QHighRight = grip(Vector3.new(1.0, 2.2, -0.6), Vector3.new(0.6, 0.75, 0.0)), -- the backhand's end: up past his right shoulder
	QSideRight = grip(Vector3.new(1.3, 0.9, 0.3), Vector3.new(0.85, 0.05, 0.5)), -- wound back to his right, flat, for a sweep
	QSideLeft = grip(Vector3.new(-1.2, 0.9, -0.9), Vector3.new(-0.85, 0, -0.45)), -- swept through, flat, out to his left
	QSideOut = grip(Vector3.new(-1.3, 0.0, -0.4), Vector3.new(-1, -0.35, 0.1)), -- held out wide and low at his left as he spins, angled down to you
	QHighLeft = grip(Vector3.new(-0.7, 2.4, 0.0), Vector3.new(-0.4, 0.6, 0.65)), -- up over his left shoulder
	QChopRight = grip(Vector3.new(0.9, -0.5, -1.4), Vector3.new(0.6, -0.5, -0.6)), -- chopped down across him to his right foot
	QThrustLoad = grip(Vector3.new(0.9, 0.3, 0.9), Vector3.new(0, -0.15, -1)), -- drawn back at his right hip, levelled at you
	QThrust = grip(Vector3.new(0.35, 0.3, -2.0), Vector3.new(0, -0.3, -0.95)), -- driven out and down: the tip at your chest
	QSlideOut = grip(Vector3.new(1.7, -0.5, -0.3), Vector3.new(1, -0.2, -0.25)), -- held out low on his right, for the slide
	QVaultPlant = grip(Vector3.new(0.5, 0.8, -1.6), Vector3.new(0, 1, -0.05)), -- stood up before him, its butt to the floor
}

-- THE SUN-GLAIVE: C's sun-wheel on a long gold-ringed haft, a crescent blade off the wheel edged in fire, a spike
-- beyond it; the haft runs from the butt (+Y, past the left hand) to the head (-Y)
local GOLD, GOLD_DK, STEELB, EMBER, SUN = D.gold, D.goldDk, rgb(150, 146, 140), D.ember, D.sun
M.Weapons = {
	SunGlaive = function(w)
		local s, MAT = w.scale, Enum.Material
		local function off(x, a) -- (a sideways place and a turn in the wheel's plane: the X offset scaled here)
			return CFrame.new(x * s, 0, 0) * CFrame.Angles(0, 0, a or 0)
		end
		local handle = w.mk("Grip", Vector3.new(0.19, 1.0, 0.19), rgb(30, 22, 18), MAT.Leather)
		w.add(w.mk("Haft", Vector3.new(0.16, 6.4, 0.16), GOLD_DK, MAT.Metal), -0.8)
		for _, y in ipairs({ 1.9, 0.75, -1.2, -2.3, -3.4 }) do
			w.add(w.mk("HaftRing", Vector3.new(0.26, 0.1, 0.26), GOLD, MAT.Metal), y)
		end
		w.add(w.mk("Butt", Vector3.new(0.24, 0.32, 0.24), GOLD, MAT.Metal), 2.45)
		w.add(w.mk("ButtSpike", Vector3.new(0.12, 0.4, 0.12), STEELB, MAT.Metal), 2.75)
		local W = -4.6 -- the wheel's centre
		for i = 0, 11 do
			local a = i / 12 * math.pi * 2
			w.add(w.mk("Wheel", Vector3.new(0.14, 0.32, 0.14), GOLD, MAT.Metal), W + math.sin(a) * 0.6, off(math.cos(a) * 0.6, a))
			w.add(w.mk("WheelRay", Vector3.new(0.08, 0.2, 0.06), GOLD_DK, MAT.Metal), W + math.sin(a) * 0.82, off(math.cos(a) * 0.82, a - math.pi / 2))
		end
		for i = 0, 2 do
			w.add(w.mk("Spoke", Vector3.new(0.06, 1.2, 0.06), GOLD_DK, MAT.Metal), W, off(0, i * math.pi / 3))
		end
		local core = w.mk("WheelFire", Vector3.new(0.4, 0.4, 0.4), SUN, MAT.Neon)
		core.Shape = Enum.PartType.Ball
		w.add(core, W)
		for i = 0, 6 do -- the crescent, off the wheel's crown (on toward the head), its horns out either side
			local a = math.pi * (0.15 + i / 6 * 0.7)
			w.add(w.mk("GlaiveBlade", Vector3.new(0.5, 0.36, 0.06), STEELB, MAT.Metal), W - 0.55 - math.sin(a) * 1.1, off(math.cos(a) * 1.1, -(a - math.pi / 2)))
			w.add(w.mk("GlaiveEdge", Vector3.new(0.5, 0.06, 0.07), EMBER, MAT.Neon), W - 0.55 - math.sin(a) * 1.3, off(math.cos(a) * 1.3, -(a - math.pi / 2)))
		end
		w.add(w.mk("GlaiveSpike", Vector3.new(0.12, 1.0, 0.06), STEELB, MAT.Metal), W - 1.95)
		local function setup()
			local f = Instance.new("Fire")
			f.Size, f.Heat = 2.2 * s / Base.Scale, 5
			f.Color, f.SecondaryColor = EMBER, rgb(120, 20, 6)
			f.Parent = core
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness = EMBER, 12 * s / Base.Scale, 1.4
			l.Parent = core
		end
		return { handle = handle, bladeLen = 6.0, setup = setup }
	end,
}

-- stats (the shared brain in GameServer/Enemies.lua reads these): a giant, slow to start, who ends it in one cut
M.Def = {
	HP = 1067, Speed = 19, Scale = H.Scale, Damage = 47, Range = 16, HalfAngle = 80,
	Windup = 0.35, Recover = 0.75, Aggro = 70, Leash = 150, -- (the whole court: he's at home in its far end) Stagger = 3.2, StaggerPush = 0,
	HyperArmor = true, Weapon = "SunGlaive", Radius = 3.5, Lunge = 4,
	Poise = 1e9, HitLevel = "Large", Engage = 40, IdleGrip = "QGuard", -- (your blows don't break him: his own attacks do - Fatigue)
	CleaveRadius = 5, -- (the burst where the blade bites the floor)
	SpinTime = 0.75, TakeOff = 0.45, SpinDrift = 5, LeapTime = 0.85, LeapHeight = 14, LeapMax = 34, -- the Sun-Fall (studs, seconds)
	SlamRadius = 11, SlamDamage = 57, SlamRecover = 1.0,
	CleaveReach = 16, -- (inside this he cuts; outside it, out to Engage, he closes in with one of his gymnastic moves)
	Tempo = 0.65, -- (every combo's held wind-ups cut to this: he's quick)
	-- HIS POSTURE (the bar under his health): every attack he makes spends some of it - each blow of a combo, more for the
	-- leap and the gymnastic moves - and when it's full he's spent: down on a knee, breathing hard, ExhaustTime long,
	-- getting up slowly over its last Rise. Your chance
	Fatigue = { Hit = 0.06, SunFall = 0.22, Move = 0.16 }, ExhaustTime = 7, ExhaustRise = 2.6,
	Slide = { Crouch = 0.18, Rise = 16, Up = 0.32, Hang = 0.45, Dive = 0.3, DiveShare = 0.35, Slide = 0.5, Side = 6, Past = 10,
		Min = 14, Max = 36, Reach = 13, Band = 3.5, Damage = 33 }, -- (the Reaping Slide: up, hung there - the tell - the dive, the slide)
	Vault = { Tell = 0.25, Air = 0.75, Height = 16, Beyond = 8, Min = 10, Max = 34, Range = 15, Half = 55, Damage = 39 }, -- (the Corkscrew Vault)
	Commit = 0.22, -- (the coil's last moment: he stops turning after you - the cut goes where he's facing)
	Phase2 = 0.5, -- (at this much of his health left: quicker to strike and faster on his feet)
	Phase2Windup = 0.6, Phase2Speed = 1.2,
}

---------------------------------------------------------------------------
-- server: how he fights
---------------------------------------------------------------------------
local pose, bodyPose, playSound, SOUNDS, now, faceTowards, setTrail, flat, playersInSector, playersInRadius, damagePlayer, burst, dustCloud, FxRemote
local Map, aliveChar, dropSplinter, bossWatch, states, setAction, cancelSwing, makeRig, Config, Save

-- HIS SOUNDS: every swing a whoosh of the glaive layered with one of two others (picked fresh each time); and his
-- breathing, heavy, when he's spent himself
local SWING, SWING_WITH = "rbxassetid://90775708931474", { "rbxassetid://137628815514180", "rbxassetid://140228522212884" }
local BREATH = "rbxassetid://88247479280853"
local function whoosh(part, vol)
	local pitch = 0.95 + math.random() * 0.1
	playSound(part, SWING, vol or 1, pitch)
	playSound(part, SWING_WITH[math.random(#SWING_WITH)], vol or 1, pitch)
end

local function hold(e, duration, target)
	local t0 = now()
	while now() - t0 < duration do
		if not e.alive or now() < e.staggerUntil then
			return false
		end
		if target and target.Parent then
			faceTowards(e.root, target.Position)
		end
		task.wait()
	end
	return true
end

local function yawOf(v)
	return math.atan2(-v.X, -v.Z) -- (CFrame.Angles(0, yaw, 0) looks along (-sin yaw, 0, -cos yaw))
end
local function smooth(a)
	return a * a * (3 - 2 * a)
end
-- FIRE AFTERIMAGES: every blow of his leaves its mark burning where it struck, a moment after - the very shape it hit
-- (the cut's fan out to its reach and angle, the bite's and the slam's circles: what playersInSector / InRadius
-- took), glowing, flames licking off its rim, fading out; and the glaive's swing left hanging in the air behind it,
-- copies of it in fire along its path, fading. (Server-side, anchored, gone in a second or two)
local Debris, TweenService = game:GetService("Debris"), game:GetService("TweenService")
local SCORCH, BLAZE = rgb(150, 30, 8), rgb(255, 170, 70)
local function fxFolder()
	local f = workspace:FindFirstChild("KingFire")
	if not f then
		f = Instance.new("Folder")
		f.Name = "KingFire"
		f.Parent = workspace
	end
	return f
end
local function burnPart(size, cf, col, t0, life, shape)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	if shape then
		p.Shape = shape
	end
	p.Material, p.Color, p.Size, p.CFrame, p.Transparency = Enum.Material.Neon, col, size, cf, t0
	p.Parent = fxFolder()
	TweenService:Create(p, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 }):Play()
	Debris:AddItem(p, life + 0.2)
	return p
end
local function flames(p, rate, size, life)
	local f = Instance.new("ParticleEmitter")
	f.Texture = "rbxasset://textures/particles/fire_main.dds"
	f.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, rgb(255, 190, 90)), ColorSequenceKeypoint.new(0.5, rgb(255, 90, 20)), ColorSequenceKeypoint.new(1, rgb(90, 14, 4)) })
	f.LightEmission = 0.8
	f.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	f.Transparency = NumberSequence.new(0.2, 1)
	f.Lifetime, f.Speed, f.Acceleration = NumberRange.new(0.4, 0.9), NumberRange.new(1, 3), Vector3.new(0, 8, 0)
	f.Rate, f.Shape, f.EmissionDirection = rate, Enum.ParticleEmitterShape.Box, Enum.NormalId.Top
	f.Parent = p
	task.delay(life * 0.6, function()
		if f.Parent then
			f.Enabled = false
		end
	end)
end
-- a column of dense, dark fire filling a circle (as the Passage of Fire's: unlit, near-opaque, deep red to black,
-- brighter tongues through it), its height h - for life, then dying down
local function fireMass(c, r, h, life)
	local holder = burnPart(Vector3.new(r * 2, h, r * 2), CFrame.new(c + Vector3.new(0, h / 2, 0)), SCORCH, 1, life + 1.2)
	local m = Instance.new("ParticleEmitter")
	m.Texture = "rbxasset://textures/particles/fire_main.dds"
	m.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, rgb(130, 30, 8)), ColorSequenceKeypoint.new(0.45, rgb(70, 12, 6)), ColorSequenceKeypoint.new(1, rgb(14, 8, 6)) })
	m.LightEmission = 0.15
	m.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, r * 0.35), NumberSequenceKeypoint.new(0.5, r * 0.55), NumberSequenceKeypoint.new(1, r * 0.3) })
	m.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(0.15, 0.03), NumberSequenceKeypoint.new(0.8, 0.12), NumberSequenceKeypoint.new(1, 1) })
	m.Lifetime, m.Speed, m.Drag = NumberRange.new(0.8, 1.4), NumberRange.new(0.5, 2), 1
	m.Rotation, m.RotSpeed, m.Acceleration = NumberRange.new(0, 360), NumberRange.new(-40, 40), Vector3.new(0, 5, 0)
	m.Shape, m.ShapeStyle, m.Rate = Enum.ParticleEmitterShape.Cylinder, Enum.ParticleEmitterShapeStyle.Volume, 18 + r * 7
	m.Parent = holder
	local t = m:Clone() -- (the tongues: brighter, quicker, licking up out of it)
	t.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, rgb(255, 160, 60)), ColorSequenceKeypoint.new(0.4, rgb(210, 50, 12)), ColorSequenceKeypoint.new(1, rgb(60, 10, 4)) })
	t.LightEmission, t.Rate = 0.6, 10 + r * 3
	t.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, r * 0.22), NumberSequenceKeypoint.new(1, 0) })
	t.Transparency = NumberSequence.new(0.3, 1)
	t.Lifetime, t.Acceleration = NumberRange.new(0.5, 0.9), Vector3.new(0, 12, 0)
	t.Parent = holder
	task.delay(life * 0.65, function() -- (dying down: no more of it, and what's there burns out)
		m.Enabled, t.Enabled = false, false
	end)
end
local function fireDisc(c, r, life)
	burnPart(Vector3.new(0.15, r * 2, r * 2), CFrame.new(c + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.pi / 2), SCORCH, 0.2, life, Enum.PartType.Cylinder)
	fireMass(c, r, math.max(4, r * 0.5), life)
	local n = math.max(12, math.floor(r * 1.6))
	for i = 0, n - 1 do
		local a = i / n * 2 * math.pi
		local seg = burnPart(Vector3.new(2 * r * math.sin(math.pi / n) * 1.1, 0.25, 1.0), CFrame.new(c + Vector3.new(math.cos(a) * r, 0.1, math.sin(a) * r)) * CFrame.Angles(0, -a + math.pi / 2, 0), BLAZE, 0.15, life * 1.1)
		if i % 2 == 0 then
			flames(seg, 24, 3, life)
		end
	end
end
-- THE BLADE'S FIRE: where the glaive goes in a blow, it leaves itself burning in the air - every step of the swing, a
-- ribbon of fire laid between where the blade was and where it is now (from the server's own weapon, where the swing
-- has it: blade end or butt end), each burning on a moment and dying out, so the whole path it cut hangs there
local RunService = game:GetService("RunService")
local function bladePoints(e, butt)
	local w = e.model and e.model:FindFirstChild("Weapon")
	local h = w and w:FindFirstChild("Grip")
	if not h then
		return nil
	end
	local s = e.def.Scale
	if butt then -- (the butt and its spike)
		return (h.CFrame * CFrame.new(0, 1.5 * s, 0)).Position, (h.CFrame * CFrame.new(0, 2.95 * s, 0)).Position
	end
	return (h.CFrame * CFrame.new(0, -3.3 * s, 0)).Position, (h.CFrame * CFrame.new(0, -6.6 * s, 0)).Position -- (the wheel out to the spike)
end
local function bladeTrail(e, dur, butt, life)
	life = life or 0.9
	task.spawn(function()
		local a0, b0 = bladePoints(e, butt)
		local t0, n = now(), 0
		while a0 and now() - t0 < dur and e.alive do
			RunService.Heartbeat:Wait()
			local a1, b1 = bladePoints(e, butt)
			if not a1 then
				break
			end
			local move = (a1 + b1) / 2 - (a0 + b0) / 2
			local span = b1 - a1
			if move.Magnitude > 0.4 and span.Magnitude > 0.1 then
				local x = span.Unit
				local z = move - x * move:Dot(x)
				if z.Magnitude > 1e-3 then
					z = z.Unit
					n += 1
					local cf = CFrame.fromMatrix((a0 + b0 + a1 + b1) / 4, x, z:Cross(x), z)
					local len = math.max(span.Magnitude, (b0 - a0).Magnitude)
					local body = burnPart(Vector3.new(len, 0.3, move.Magnitude + 0.8), cf, rgb(255, 110, 30), 0.25, life)
					burnPart(Vector3.new(0.6, 0.35, move.Magnitude + 0.8), cf * CFrame.new(len / 2, 0, 0), BLAZE, 0.1, life * 1.1) -- (the edge, brightest)
					if n % 2 == 0 then
						flames(body, 16, 2.6, life)
					end
				end
			end
			a0, b0 = a1, b1
		end
	end)
end

-- THE SUN-CLEAVE: raised, coiled, held (the telegraph); then down across him with all his weight in it
local function cleave(e, tRoot)
	local def, root = e.def, e.root
	-- up over the shoulder, rocking back
	pose(e, "QRaise", 0.36, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	bodyPose(e, "QBRaise", 0.36)
	playSound(root, SOUNDS.Unsheath, 0.6, 0.4)
	if not hold(e, 0.34 * def.Tempo, tRoot) then
		return false
	end
	-- wound round further, sunk on the back leg - and held there, watching you
	pose(e, "QCoil", 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	bodyPose(e, "QBCoil", 0.4)
	local windup = e.phase2 and def.Windup * def.Phase2Windup or def.Windup
	if not hold(e, 0.4 + windup - def.Commit, tRoot) or not hold(e, def.Commit) then -- (the last of it not tracking you)
		return false
	end
	-- the cut: everything thrown into it, a step of weight forward
	setTrail(e, true)
	whoosh(root, 0.9)
	pose(e, "QCleave", 0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	bodyPose(e, "QBCleave", 0.24)
	bladeTrail(e, 0.38) -- (the swing left burning in the air where the blade went)
	local fwd = flat(root.CFrame.LookVector)
	root.AssemblyLinearVelocity = fwd * def.Lunge * 4
	task.wait(0.16)
	if not e.alive then
		return false
	end
	for _, pl in ipairs(playersInSector(root.CFrame, def.Range, def.HalfAngle, 8 * def.Scale)) do
		damagePlayer(pl, def.Damage, root.Position, def.HitLevel)
	end
	-- (no pause on it: the follow-through starts as the blade bites, and the Sun-Fall straight out of that)
	pose(e, "QFollow", 0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	bodyPose(e, "QBFollow", 0.24)
	-- the blade into the floor by his left foot: fire bursts out of the stone
	local bite = root.Position - Vector3.new(0, 3 * def.Scale - 0.3, 0) + fwd * def.Range * 0.65 - root.CFrame.RightVector * def.Range * 0.25
	for _, pl in ipairs(playersInRadius(bite, def.CleaveRadius, 6)) do
		damagePlayer(pl, def.Damage * 0.4, bite, "Medium")
	end
	fireDisc(bite, def.CleaveRadius, 1.4)
	burst(bite, EMBER, 30, 0.7, 24)
	dustCloud(bite, 6, 14)
	playSound(root, SOUNDS.WatchdogSmash, 0.9, 0.7)
	FxRemote:FireAllClients("Shake", bite, 0.6)
	task.wait(0.05) -- (a breath of the follow-through showing, then carried on round by its weight)
	return true
end

-- THE SUN-FALL: the cut's weight carried on round him and up into the air, all one movement. He turns on round to his
-- left (the way the cut went), drifting toward you on it, the glaive swung round behind him low; halfway round he's
-- sunk onto both legs under the turn - loading it - and before the turn is done he drives up off them, the glaive
-- coming up his right side and over his head as he rises, and finishes the turn in the air to come down facing you,
-- the blade into the floor where he lands
local function sunFall(e, tRoot)
	local def, root = e.def, e.root
	local start0 = root.Position
	local y0 = yawOf(root.CFrame.LookVector)
	local function toward(from)
		local d = tRoot.Parent and flat(tRoot.Position - from) or flat(root.CFrame.LookVector)
		return d.Magnitude > 0.1 and d or flat(root.CFrame.LookVector)
	end
	-- the whole turn: on round to his left to face you again, more than half a turn and less than a turn and a half
	local delta = (yawOf(toward(start0)) - y0) % (2 * math.pi)
	if delta < math.pi then
		delta += 2 * math.pi
	end
	local SPIN, OFF, AIR = def.SpinTime, def.TakeOff, def.LeapTime -- (the turn's length; when in it he leaves the floor; the flight)
	local drift = toward(start0).Unit * def.SpinDrift -- (the turn carries him on toward you a few steps before he jumps)
	root.Anchored = true
	bladeTrail(e, SPIN + AIR + 0.15) -- (the glaive's whole way round him, up, over and down, left burning)
	pose(e, "QSpinBack", OFF * 0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	bodyPose(e, "QBSpin", OFF * 0.5)
	whoosh(root, 0.8)
	local t0, step = now(), 0
	local start, landing, yOff, dOff -- (set at take-off)
	while e.alive do
		local t = now() - t0
		-- the beats, each starting from where the last left him
		if step == 0 and t > OFF * 0.5 then -- loading: sunk under the turn, the glaive coming round to his right
			step = 1
			bodyPose(e, "QBLoad", OFF * 0.5)
			pose(e, "QSpinUp", OFF * 0.6 + 0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		elseif step == 1 and t >= OFF then -- take-off: committed to where you are now, as far as he reaches
			step = 2
			start = root.Position
			local reach = toward(start)
			if reach.Magnitude > def.LeapMax then
				reach = reach.Unit * def.LeapMax
			end
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			local skip = { e.model }
			for _, pl in ipairs(game:GetService("Players"):GetPlayers()) do
				table.insert(skip, pl.Character)
			end
			params.FilterDescendantsInstances = skip
			local low = Vector3.new(0, 3 - 3 * def.Scale, 0) -- (a ray at his chest, and one just off the floor: plinths, steps)
			for _, from in ipairs({ start, start + low }) do
				local hit = reach.Magnitude > 0.5 and workspace:Raycast(from, reach + reach.Unit * def.Radius, params)
				if hit then -- (short of anything in the way)
					reach = reach.Unit * math.max(0, (flat(hit.Position - from)).Magnitude - def.Radius - 2)
				end
			end
			landing = start + reach
			local SC = Map and Map.SunkenCourt
			if SC then -- (and never off the court, nor onto the colossus's plinth and steps at its west end)
				local m = def.Radius + 3
				landing = Vector3.new(math.clamp(landing.X, SC.MinX + 26, SC.MaxX - m), landing.Y, math.clamp(landing.Z, SC.MinZ + m, SC.MaxZ - m))
				reach = landing - start
			end
			-- the rest of the turn, finished in the air, brought round to face where he'll land
			yOff = y0 + delta * smooth(math.min(OFF / SPIN, 1))
			dOff = (yawOf(reach.Magnitude > 0.5 and reach or root.CFrame.LookVector) - yOff) % (2 * math.pi)
			if dOff > math.pi * 1.5 then -- (nearly round already: a small correction back, not a whole extra turn)
				dOff -= 2 * math.pi
			end
			bodyPose(e, "QBAir", 0.24)
			pose(e, "QOverhead", 0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			whoosh(root, 1)
			dustCloud(start - Vector3.new(0, 3 * def.Scale - 0.3, 0), 6, 12)
			setTrail(e, true)
		elseif step == 2 and t >= OFF + AIR * 0.5 then -- over the top: folding onto it
			step = 3
			bodyPose(e, "QBDive", AIR * 0.3)
		elseif step == 3 and t >= OFF + AIR * 0.66 then -- and the blade brought down to land when he does
			step = 4
			pose(e, "QSlam", AIR * 0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end
		if step < 2 then -- on the floor, turning, carried forward
			local a = t / SPIN
			root.CFrame = CFrame.new(start0 + drift * smooth(math.min(t / OFF, 1))) * CFrame.Angles(0, y0 + delta * smooth(math.min(a, 1)), 0)
		else -- in the air: up off the floor fast and slowing to the top, then falling; still turning till he faces you
			local a = math.min((t - OFF) / AIR, 1)
			local spinA = math.min((t - OFF) / math.max(SPIN - OFF, 0.05), 1)
			local yaw = yOff + dOff * (1 - (1 - spinA) * (1 - spinA)) -- (easing out of the turn's speed)
			root.CFrame = CFrame.new(start:Lerp(landing, a) + Vector3.new(0, 4 * a * (1 - a) * def.LeapHeight, 0)) * CFrame.Angles(0, yaw, 0)
			if a >= 1 then
				break
			end
		end
		task.wait()
	end
	if root.Parent then
		root.Anchored = false
		root.AssemblyLinearVelocity = Vector3.zero
		pcall(function()
			root:SetNetworkOwner(nil)
		end)
	end
	if not e.alive then
		return false
	end
	local rot = root.CFrame.Rotation
	-- down: all of it into the blade, a ring of fire out of the stone
	bodyPose(e, "QBSlam", 0.08)
	local ground = landing - Vector3.new(0, 3 * def.Scale - 0.3, 0)
	local bite = ground + rot.LookVector * 6
	for _, pl in ipairs(playersInRadius(bite, def.SlamRadius, 8 * def.Scale)) do
		damagePlayer(pl, def.SlamDamage, bite, "Knockdown")
	end
	fireDisc(bite, def.SlamRadius, 1.8)
	playSound(root, SOUNDS.WatchdogSmash, 1, 0.55)
	FxRemote:FireAllClients("Shake", bite, 1.2)
	burst(bite, EMBER, 46, 0.9, 34)
	dustCloud(bite, 10, 22)
	for i = 0, 7 do -- (the ring: bursts thrown out round where it bit)
		local a = i / 8 * math.pi * 2
		burst(bite + Vector3.new(math.cos(a), 0, math.sin(a)) * def.SlamRadius * 0.6, EMBER, 12, 0.5, 12)
	end
	setTrail(e, false)
	return true
end

-- FIRE OF HIS OWN (the seal on the court, and what his blows leave): tiles of it, and dense dark flame out of a part
local Players = game:GetService("Players")
-- a tile of fire on the floor that warms, blazes, and dies on cue (set(t, dur): to transparency t over dur)
local function tile(size, cf, col, t0)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material, p.Color, p.Size, p.CFrame, p.Transparency = Enum.Material.Neon, col, size, cf, t0
	p.Parent = fxFolder()
	return p
end
local function to(p, t, dur)
	TweenService:Create(p, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { Transparency = t }):Play()
end
-- dense dark flame out of a part (the Passage of Fire's): scale, the flames' size
local function denseFire(p, scale, rate)
	local m = Instance.new("ParticleEmitter")
	m.Texture = "rbxasset://textures/particles/fire_main.dds"
	m.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, rgb(140, 32, 8)), ColorSequenceKeypoint.new(0.45, rgb(72, 12, 6)), ColorSequenceKeypoint.new(1, rgb(14, 8, 6)) })
	m.LightEmission = 0.18
	m.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, scale * 0.7), NumberSequenceKeypoint.new(0.5, scale), NumberSequenceKeypoint.new(1, scale * 0.6) })
	m.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(0.15, 0.03), NumberSequenceKeypoint.new(0.8, 0.12), NumberSequenceKeypoint.new(1, 1) })
	m.Lifetime, m.Speed, m.Drag = NumberRange.new(0.8, 1.3), NumberRange.new(1, 3), 1
	m.Rotation, m.RotSpeed, m.Acceleration = NumberRange.new(0, 360), NumberRange.new(-40, 40), Vector3.new(0, 7, 0)
	m.Shape, m.ShapeStyle, m.EmissionDirection, m.Rate = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume, Enum.NormalId.Top, rate
	m.Parent = p
	local t = m:Clone() -- (brighter tongues through it)
	t.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, rgb(255, 160, 60)), ColorSequenceKeypoint.new(0.4, rgb(210, 50, 12)), ColorSequenceKeypoint.new(1, rgb(60, 10, 4)) })
	t.LightEmission, t.Rate = 0.6, rate * 0.4
	t.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, scale * 0.5), NumberSequenceKeypoint.new(1, 0) })
	t.Transparency = NumberSequence.new(0.3, 1)
	t.Lifetime, t.Acceleration = NumberRange.new(0.4, 0.8), Vector3.new(0, 14, 0)
	t.Parent = p
	return { m, t }
end
local function stop(emitters)
	for _, f in ipairs(emitters) do
		if f.Parent then
			f.Enabled = false
		end
	end
end

-- HIS COMBOS: each a run of blows, every blow a step - a wind-up he turns after you in (all but its last instant), then
-- the cut itself: the glaive swung through to its end, the body thrown after it, a step of weight forward, the blade's
-- fire hanging where it went, and whatever's in the arc it swept struck. A step:
--   wind / windBody / windT / holdT   the grip and body pose wound into, how long to get there, how long it's held
--   grip / body / t                   the strike's end grip and body pose, and how long the swing takes
--   range / half / dir                its reach, half-angle (degrees) and centre (radians to his left of ahead)
--   around                            (a spin) instead struck all round him, as he turns a full turn through it
--   dmg / level / lunge / bite        damage, hit level, how hard he steps into it, and (an overhead into the floor)
--                                     how far ahead the blade bites the stone, a ring of fire there
local function strike(e, tRoot, st, first)
	local def, root = e.def, e.root
	if st.wind then
		pose(e, st.wind, st.windT, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		bodyPose(e, st.windBody, st.windT)
		if first then
			playSound(root, SOUNDS.Unsheath, 0.6, 0.45)
		end
		local h = st.holdT * def.Tempo * (e.phase2 and def.Phase2Windup or 1)
		local commit = math.min(h, def.Commit * 0.6)
		if not hold(e, st.windT + h - commit, tRoot) or not hold(e, commit) then -- (the last instant: not turning)
			return false
		end
	end
	setTrail(e, true)
	whoosh(root, 0.85)
	pose(e, st.grip, st.t, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	bodyPose(e, st.body, st.t)
	bladeTrail(e, st.t + (st.around and st.t or 0) + 0.14)
	local fwd = flat(root.CFrame.LookVector)
	if st.around then -- the spin: a full turn on the spot, the blade held out, struck all round as it passes
		local pos, y0 = root.Position, yawOf(root.CFrame.LookVector)
		root.Anchored = true
		local t0, hit = now(), false
		while e.alive do
			local a = math.min((now() - t0) / (st.t * 2), 1)
			root.CFrame = CFrame.new(pos) * CFrame.Angles(0, y0 + 2 * math.pi * smooth(a), 0)
			if not hit and a > 0.45 then
				hit = true
				for _, pl in ipairs(playersInRadius(pos, st.range, 8 * def.Scale)) do
					damagePlayer(pl, st.dmg, pos, st.level or "Large")
				end
			end
			if a >= 1 then
				break
			end
			task.wait()
		end
		root.Anchored = false
		return e.alive
	end
	if st.lunge then
		root.AssemblyLinearVelocity = fwd * st.lunge * 4
	end
	task.wait(st.t * 0.7)
	if not e.alive or now() < e.staggerUntil then
		return false
	end
	for _, pl in ipairs(playersInSector(root.CFrame * CFrame.Angles(0, st.dir or 0, 0), st.range, st.half, 8 * def.Scale)) do
		damagePlayer(pl, st.dmg, root.Position, st.level or "Large")
	end
	if st.bite then -- (into the floor: the blade bites the stone ahead, fire bursts out of it)
		local at = root.Position - Vector3.new(0, 3 * def.Scale - 0.3, 0) + fwd * st.bite
		for _, pl in ipairs(playersInRadius(at, def.CleaveRadius, 6)) do
			damagePlayer(pl, st.dmg * 0.4, at, "Medium")
		end
		fireDisc(at, def.CleaveRadius, 1.3)
		burst(at, EMBER, 26, 0.6, 20)
		dustCloud(at, 5, 12)
		playSound(root, SOUNDS.WatchdogSmash, 0.8, 0.75)
		FxRemote:FireAllClients("Shake", at, 0.5)
	end
	task.wait(st.t * 0.3)
	return true
end

M.Combos = {
	-- TWIN CRESCENT (2): a rising backhand from low on his left up past his right shoulder; then, wound round to his
	-- right, a flat sweep back across
	{ name = "TwinCrescent",
		{ wind = "QLowLeft", windBody = "QBLowL", windT = 0.35, holdT = 0.45, grip = "QHighRight", body = "QBRiseR", t = 0.2, range = 14.7, half = 60, dmg = 32, lunge = 2.7 },
		{ wind = "QSideRight", windBody = "QBWindR", windT = 0.22, holdT = 0.18, grip = "QSideLeft", body = "QBSweepL", t = 0.22, range = 16.7, half = 85, dmg = 37, lunge = 2, pitch = 0.35 },
	},
	-- SUNWHEEL (3): a flat sweep right to left - its swing carried on into a full turn on his heel, the blade held out
	-- low and wide, cutting all round him - and out of the turn, up over his head and down into the floor
	{ name = "Sunwheel",
		{ wind = "QSideRight", windBody = "QBWindR", windT = 0.35, holdT = 0.4, grip = "QSideLeft", body = "QBSweepL", t = 0.22, range = 16, half = 80, dmg = 32, lunge = 2 },
		{ grip = "QSideOut", body = "QBSpin", t = 0.28, around = true, range = 14.7, dmg = 33, pitch = 0.3 },
		{ wind = "QOverhead", windBody = "QBRaise", windT = 0.28, holdT = 0.25, grip = "QSlam", body = "QBSlam", t = 0.2, range = 13.3, half = 30, dmg = 43, level = "Knockdown", lunge = 3.3, bite = 6.7, pitch = 0.3 },
	},
	-- EXECUTIONER'S MARCH (4): chop after chop down across him, high left to low right, high right to low left, each a
	-- step on into you; then reared back, arched over it, and the whole of him down into the floor
	{ name = "March",
		{ wind = "QHighLeft", windBody = "QBWindL", windT = 0.35, holdT = 0.35, grip = "QChopRight", body = "QBChopR", t = 0.2, range = 14.7, half = 45, dmg = 30, lunge = 4 },
		{ wind = "QRaise", windBody = "QBRaise", windT = 0.22, holdT = 0.1, grip = "QCleave", body = "QBCleave", t = 0.2, range = 14.7, half = 45, dmg = 30, lunge = 4, pitch = 0.45 },
		{ wind = "QHighLeft", windBody = "QBWindL", windT = 0.22, holdT = 0.1, grip = "QChopRight", body = "QBChopR", t = 0.2, range = 14.7, half = 45, dmg = 30, lunge = 4 },
		{ wind = "QOverhead", windBody = "QBArch", windT = 0.35, holdT = 0.35, grip = "QSlam", body = "QBLine", t = 0.2, range = 13.3, half = 30, dmg = 47, level = "Knockdown", lunge = 2.7, bite = 6.7, pitch = 0.3 },
	},
	-- JUDGEMENT (5): the glaive drawn back at his hip and driven straight out, twice, stepping in; then a flat sweep; a
	-- rising backhand; and up over his head and down - the sentence
	{ name = "Judgement",
		{ wind = "QThrustLoad", windBody = "QBThrustLoad", windT = 0.35, holdT = 0.35, grip = "QThrust", body = "QBThrust", t = 0.14, range = 20, half = 14, dmg = 30, lunge = 5.3, pitch = 0.55 },
		{ wind = "QThrustLoad", windBody = "QBThrustLoad", windT = 0.18, holdT = 0.06, grip = "QThrust", body = "QBThrust", t = 0.14, range = 20, half = 14, dmg = 30, lunge = 4, pitch = 0.6 },
		{ wind = "QSideRight", windBody = "QBWindR", windT = 0.2, holdT = 0.1, grip = "QSideLeft", body = "QBSweepL", t = 0.22, range = 16, half = 80, dmg = 30, lunge = 2 },
		{ wind = "QLowLeft", windBody = "QBLowL", windT = 0.18, holdT = 0.06, grip = "QHighRight", body = "QBRiseR", t = 0.2, range = 14.7, half = 60, dmg = 30, lunge = 2 },
		{ wind = "QOverhead", windBody = "QBArch", windT = 0.3, holdT = 0.35, grip = "QSlam", body = "QBSlam", t = 0.2, range = 13.3, half = 30, dmg = 47, level = "Knockdown", lunge = 3.3, bite = 6.7, pitch = 0.3 },
	},
}
local function combo(e, tRoot, c)
	for i, st in ipairs(c) do
		if not strike(e, tRoot, st, i == 1) then
			return false
		end
	end
	return true
end

-- HIS FEET: the gymnastic moves - he crosses the court in a blink, low, sideways, over your head. Each is the root carried
-- along a path (anchored: the server's, every client sees it), the body posed through it, the blade's fire after it
local function safeReach(e, start, reach) -- (as far along reach as he can go: short of anything in the way, on the court)
	local def = e.def
	if reach.Magnitude > 0.5 then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local skip = { e.model, fxFolder() }
		for _, pl in ipairs(Players:GetPlayers()) do
			table.insert(skip, pl.Character)
		end
		params.FilterDescendantsInstances = skip
		for _, from in ipairs({ start, start + Vector3.new(0, 3 - 3 * def.Scale, 0) }) do
			local hit = workspace:Raycast(from, reach + reach.Unit * def.Radius, params)
			if hit then
				reach = reach.Unit * math.max(0, flat(hit.Position - from).Magnitude - def.Radius - 2)
			end
		end
	end
	local landing = start + reach
	local SC = Map and Map.SunkenCourt
	if SC then -- (never off the court, nor onto the colossus's plinth and steps at its west end)
		local m = def.Radius + 3
		landing = Vector3.new(math.clamp(landing.X, SC.MinX + 26, SC.MaxX - m), landing.Y, math.clamp(landing.Z, SC.MinZ + m, SC.MaxZ - m))
	end
	return landing
end
-- the root carried from a to b over dur (height: an arc's top; ease: how the pace goes), turned by yawAt(k), each(k, pos)
-- called every step; false if he died on the way
local function travel(e, a, b, dur, height, ease, yawAt, each)
	local root = e.root
	root.Anchored = true
	local t0 = now()
	while e.alive do
		local k = math.min((now() - t0) / dur, 1)
		local m = ease and ease(k) or k
		local pos = a:Lerp(b, m) + Vector3.new(0, 4 * k * (1 - k) * (height or 0), 0)
		root.CFrame = CFrame.new(pos) * CFrame.Angles(0, yawAt(k), 0)
		if each then
			each(k, pos)
		end
		if k >= 1 then
			break
		end
		task.wait()
	end
	return e.alive
end
local function landed(e)
	local root = e.root
	if root.Parent then
		root.Anchored = false
		root.AssemblyLinearVelocity = Vector3.zero
		pcall(function()
			root:SetNetworkOwner(nil)
		end)
	end
end
local function easeOut(k)
	return 1 - (1 - k) * (1 - k)
end

-- THE REAPING SLIDE. The tell: a crouch, and he springs straight up - and HANGS there, high over the court, arched back,
-- knees drawn up, the glaive held out wide on his right, a flare of fire bursting off him, while he turns in
-- the air to watch you. Then he drops on you: a dive down onto the line, onto his knees, sliding past you on
-- his right side, leant back, cutting all along it; and up off his knees in one spring, the blade flicked up
local function reapingSlide(e, tRoot)
	local def, root = e.def, e.root
	local G = def.Slide
	local function toward(from)
		local d = tRoot.Parent and flat(tRoot.Position - from) or flat(root.CFrame.LookVector)
		return d.Magnitude > 0.1 and d or flat(root.CFrame.LookVector)
	end
	-- the crouch, and up
	pose(e, "QSlideOut", 0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	bodyPose(e, "QBCrouch", 0.16)
	playSound(root, SOUNDS.Unsheath, 0.6, 0.55)
	if not hold(e, G.Crouch, tRoot) then
		return false
	end
	local ground = root.Position
	local up = ground + Vector3.new(0, G.Rise, 0)
	setTrail(e, true)
	whoosh(root, 1)
	dustCloud(ground - Vector3.new(0, 3 * def.Scale - 0.3, 0), 5, 12)
	bodyPose(e, "QBHover", G.Up)
	if not travel(e, ground, up, G.Up, 0, easeOut, function()
		return yawOf(toward(ground))
	end) then
		landed(e)
		return false
	end
	-- hanging there: turning to watch you, bobbing on the air, a flare of fire off him
	burst(up, EMBER, 36, 0.7, 26)
	playSound(root, SOUNDS.WatchdogBlast, 1.2, 0.7)
	local t0 = now()
	while e.alive and now() - t0 < G.Hang * (e.phase2 and def.Phase2Windup or 1) do
		local t = now() - t0
		local at = up + Vector3.new(0, math.sin(t * 5) * 0.6, 0)
		root.CFrame = CFrame.new(at) * CFrame.Angles(0, yawOf(toward(at)), 0)
		task.wait()
	end
	if not e.alive then
		landed(e)
		return false
	end
	-- committed: the line past you on his right - he dives onto it a way short of you, and slides on past
	local from = root.Position
	local floorAt = Vector3.new(from.X, ground.Y, from.Z)
	local dir = toward(floorAt).Unit
	local left = Vector3.new(dir.Z, 0, -dir.X) -- (his left, facing along dir)
	local aim = Vector3.new(tRoot.Position.X, ground.Y, tRoot.Position.Z) + left * G.Side
	local line = flat(aim - floorAt)
	local startS = safeReach(e, floorAt, line * G.DiveShare)
	local reach = flat(aim - startS)
	reach = reach.Magnitude > 0.1 and reach.Unit * math.clamp(reach.Magnitude + G.Past, G.Min, G.Max) or dir * G.Min
	local finish = safeReach(e, startS, reach)
	local yaw = yawOf(finish - startS)
	bodyPose(e, "QBDive", G.Dive * 0.8)
	bladeTrail(e, G.Dive + G.Slide + 0.1)
	whoosh(root, 1)
	if not travel(e, from, startS, G.Dive, 0, function(k)
		return k * k -- (falling: faster and faster)
	end, function()
		return yaw
	end) then
		landed(e)
		return false
	end
	bodyPose(e, "QBKneeSlide", 0.08) -- (down on his knees)
	dustCloud(startS - Vector3.new(0, 3 * def.Scale - 0.3, 0), 6, 14)
	FxRemote:FireAllClients("Shake", startS, 0.5)
	local struck = {}
	local ok = travel(e, startS, finish, G.Slide, 0, easeOut, function()
		return yaw
	end, function(_, pos)
		local cf = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
		for _, pl in ipairs(Players:GetPlayers()) do -- (whoever's off his right side, out along the blade)
			local char, _, hrp = aliveChar(pl)
			if char and not struck[pl] then
				local rel = cf:PointToObjectSpace(hrp.Position)
				if rel.X > 0 and rel.X < G.Reach and math.abs(rel.Z) < G.Band and math.abs(rel.Y) < 4 * def.Scale then
					struck[pl] = true
					damagePlayer(pl, G.Damage, pos, "Large")
				end
			end
		end
	end)
	landed(e)
	if not ok then
		return false
	end
	-- up off his knees in one spring, the blade flicked up
	pose(e, "QHighRight", 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	bodyPose(e, "QBRiseR", 0.18)
	task.wait(0.2)
	setTrail(e, false)
	return e.alive
end

-- THE CORKSCREW VAULT: the glaive planted before him, and up off it - high over you, turning a turn and a half in the
-- air, tucked - down behind you, facing back, the blade brought down into the floor as he lands
local function corkscrewVault(e, tRoot)
	local def, root = e.def, e.root
	local G = def.Vault
	pose(e, "QVaultPlant", 0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	bodyPose(e, "QBCrouch", 0.22)
	playSound(root, SOUNDS.Unsheath, 0.6, 0.5)
	if not hold(e, G.Tell * (e.phase2 and def.Phase2Windup or 1), tRoot) then
		return false
	end
	local start = root.Position
	local to = flat(tRoot.Position - start)
	local dir = to.Magnitude > 0.1 and to.Unit or flat(root.CFrame.LookVector)
	local finish = safeReach(e, start, dir * math.clamp(to.Magnitude + G.Beyond, G.Min, G.Max))
	local y0 = yawOf(dir)
	setTrail(e, true)
	whoosh(root, 1)
	dustCloud(start - Vector3.new(0, 3 * def.Scale - 0.3, 0), 5, 10)
	bodyPose(e, "QBAir", 0.2)
	pose(e, "QOverhead", 0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	bladeTrail(e, G.Air + 0.1)
	local step = 0
	local ok = travel(e, start, finish, G.Air, G.Height, nil, function(k)
		return y0 + 3 * math.pi * smooth(k) -- (a turn and a half: down facing back the way he came)
	end, function(k)
		if step == 0 and k > 0.55 then
			step = 1
			bodyPose(e, "QBDive", G.Air * 0.3)
		elseif step == 1 and k > 0.7 then
			step = 2
			pose(e, "QSlam", G.Air * 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end
	end)
	landed(e)
	if not ok then
		return false
	end
	bodyPose(e, "QBSlam", 0.08)
	local fwd = flat(root.CFrame.LookVector)
	for _, pl in ipairs(playersInSector(root.CFrame, G.Range, G.Half, 8 * def.Scale)) do
		damagePlayer(pl, G.Damage, root.Position, "Knockdown")
	end
	local at = root.Position - Vector3.new(0, 3 * def.Scale - 0.3, 0) + fwd * 5
	fireDisc(at, def.CleaveRadius, 1.3)
	burst(at, EMBER, 26, 0.6, 20)
	playSound(root, SOUNDS.WatchdogSmash, 0.9, 0.7)
	FxRemote:FireAllClients("Shake", at, 0.6)
	task.wait(0.15)
	setTrail(e, false)
	return e.alive
end

M.Moves = { reapingSlide, corkscrewVault } -- (the gap-closers too: what he does when you're out of his cut's reach)

-- THE LOCK: while he fights, a wall of fire stands round the throne's lift where it came down, and its levers and its
-- ride are dead - no way out of the court but through him. (Map.Bulwark.ThroneLift)
local lockParts
local function lockCourt(on)
	local Lf = Map and Map.Bulwark and Map.Bulwark.ThroneLift
	if Lf then
		for _, pp in ipairs({ Lf.Prompt, Lf.CallBottom, Lf.CallTop }) do
			if pp then
				pp.Enabled = not on
			end
		end
	end
	if on and not lockParts then
		lockParts = {}
		local SC = Map and Map.SunkenCourt
		local y = SC and SC.Floor or 12
		local x1, z1, x2, z2, h = 501.5, 228.5, 515.5, 251.5, 14 -- (round the lift's deck, as it stands down here)
		for _, w in ipairs({ { (x1 + x2) / 2, z1, x2 - x1, 1 }, { (x1 + x2) / 2, z2, x2 - x1, 1 }, { x1, (z1 + z2) / 2, 1, z2 - z1 }, { x2, (z1 + z2) / 2, 1, z2 - z1 } }) do
			local p = Instance.new("Part")
			p.Name = "FireSeal"
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, true, false, false, false
			p.Material, p.Color, p.Transparency = Enum.Material.Neon, rgb(120, 26, 8), 0.45
			p.Size = Vector3.new(w[3], h, w[4])
			p.CFrame = CFrame.new(w[1], y + h / 2, w[2])
			p.Parent = fxFolder()
			denseFire(p, 5, 30)
			table.insert(lockParts, p)
		end
		burst(Vector3.new(508.5, y + 3, 240), EMBER, 30, 0.7, 24)
	elseif not on and lockParts then
		for _, p in ipairs(lockParts) do
			for _, f in ipairs(p:GetChildren()) do
				if f:IsA("ParticleEmitter") then
					f.Enabled = false
				end
			end
			TweenService:Create(p, TweenInfo.new(1.2), { Transparency = 1 }):Play()
			p.CanCollide = false
			Debris:AddItem(p, 2.5)
		end
		lockParts = nil
	end
end

-- WAITING: kneeling unseen in the passage of fire, bowed over the glaive planted beside him; nothing moves him
local function kneel(e)
	e.dormant = true
	e.staggerUntil = math.huge -- (the shared brain leaves him be while he's "staggered")
	pose(e, "QKneel", 0.5)
	bodyPose(e, "QBKneel", 0.5)
end
-- the living player nearest him (their root), if any
local function nearest(root)
	local best, bd
	for _, pl in ipairs(Players:GetPlayers()) do
		local char, _, hrp = aliveChar(pl)
		if char then
			local d = (hrp.Position - root.Position).Magnitude
			if not bd or d < bd then
				best, bd = hrp, d
			end
		end
	end
	return best
end
local function inCourt(p)
	local SC = Map and Map.SunkenCourt
	return SC and p.X > SC.MinX and p.X < SC.MaxX and p.Z > SC.MinZ and p.Z < SC.MaxZ and p.Y < SC.Floor + 40
end

-- HIS ENTRANCE, THE CUTSCENE (every time someone comes far enough up the court while he waits in the fire): the lift
-- sealed in fire, the camera taken and everyone in the court held. They turn, slowly, to the fire behind them; he walks
-- out of it, unhurried, stops, and stares at them; then he brandishes the glaive overhead and drives it down - fire
-- bursting round him - and it begins. Any of them can skip it by holding Space (the client's bar fires "KingSkip",
-- which sets e.skip): he's stood out of the fire at once, and they're let go
local SHOT = { turn = 3.2, out = 4.2, walk = 3.4, stare = 2.4, brandish = 3.4 }
local entering = {} -- (the kings mid-entrance, for the skip)
local function entrance(e)
	e.dormant, e.entering, e.skip = false, true, nil
	entering[e] = true
	lockCourt(true)
	local root, hum, SC = e.root, e.hum, Map.SunkenCourt
	local mouth = SC.Mouth
	local stopAt = Vector3.new(mouth.X - 18, root.Position.Y, mouth.Z) -- (out of the fire, well into the court)
	local head = e.model:FindFirstChild("Head") or root
	local total = SHOT.turn + SHOT.out + SHOT.walk + SHOT.stare + SHOT.brandish
	local V, up = Vector3.new, Vector3.yAxis
	local held = {}
	for _, pl in ipairs(Players:GetPlayers()) do
		local char, _, hrp = aliveChar(pl)
		if char and inCourt(hrp.Position) then
			local st = states[pl]
			if st then
				setAction(st, now(), total, total, total)
				st.healing = false
				cancelSwing(st)
			end
			hrp.Anchored = true
			local p = hrp.Position
			local toM = flat(mouth - p).Unit
			local side = V(-toM.Z, 0, toM.X)
			-- (which way round they turn - the short way - and whether it's worth a head-led turn at all)
			local lv = flat(hrp.CFrame.LookVector).Unit
			local way = lv:Dot(toM) < 0.9 and (lv:Cross(toM).Y >= 0 and "L" or "R") or nil
			held[pl] = { hrp = hrp, char = char, way = way, from = hrp.CFrame.Rotation, to = CFrame.lookAt(p, p + toM).Rotation }
			-- (the court runs east-west: he walks out west, so "in front of him" is -X)
			local shots = {
				-- they turn, slowly, to something behind them: close on their head, from the side they turn to
				{ toM * 5 + side * 6 + up * 0.6, toM * 4 + side * 4.5 + up * 0.4, SHOT.turn, char:FindFirstChild("Head") or hrp, nil, true },
				-- over their shoulder, down the whole length of the court, to the fire: he comes out of it
				{ CFrame.lookAt(p - toM * 7 + side * 3 + up * 5, mouth + up * 9), CFrame.lookAt(p - toM * 5 + side * 2.4 + up * 4.5, mouth + up * 8), SHOT.out },
				-- low in front of him as he walks, looking up at him
				{ V(-16, -2, 9), V(-12, -1.5, 7), SHOT.walk, root, V(0, 3, 0), true },
				-- his helm, close: he stares
				{ V(-7, 0.6, 2.5), V(-5.5, 0.4, 1.8), SHOT.stare, head, nil, true },
				-- wide: the glaive brandished, and down
				{ V(-24, 7, -13), V(-21, 6, -11), SHOT.brandish, root, V(0, 5, 0), true },
			}
			FxRemote:FireClient(pl, "Grabbed", total)
			FxRemote:FireClient(pl, "Cutscene", shots, "KingSkip")
		end
	end
	e.held = held
	local function going()
		return e.alive and not e.skip
	end
	local function hold(t, each) -- (cut short by a skip)
		local t0 = now()
		while now() - t0 < t and going() do
			if each then
				each((now() - t0) / t)
			end
			task.wait()
		end
	end
	local function stare()
		local who = nearest(root)
		if who then
			faceTowards(root, who.Position)
		end
	end
	-- (unseen in the fire) up off his knee; they turn, led by the head: it goes first, the chest and hips after it,
	-- then a step as the body comes round (the body's pose unwinding as it does, so the head stays on the fire)
	pose(e, "Idle", 0.8)
	local BEATS = { { 0, "TurnLook", 0.5 }, { 0.4, "TurnTwist", 0.7 }, { 1.0, "TurnStep", 0.6 }, { 1.8, "Idle", 1.3 } }
	local TURN0, TURN1 = 1.0, SHOT.turn - 0.2 -- (the body's own turn)
	local beat = 1
	hold(SHOT.turn, function(f)
		local t = f * SHOT.turn
		local cue = BEATS[beat]
		if cue and t >= cue[1] then
			beat += 1
			for _, h in pairs(held) do
				if h.way and h.char.Parent then
					bodyPose({ model = h.char }, cue[2] == "Idle" and "Idle" or cue[2] .. h.way, cue[3])
				end
			end
		end
		local k = math.clamp((t - TURN0) / (TURN1 - TURN0), 0, 1)
		local s = k * k * (3 - 2 * k)
		for _, h in pairs(held) do
			if h.hrp.Parent then
				h.hrp.CFrame = CFrame.new(h.hrp.Position) * h.from:Lerp(h.to, s)
			end
		end
	end)
	for _, h in pairs(held) do -- (skipped mid-turn: stood straight again)
		if h.way and h.char.Parent and e.skip then
			bodyPose({ model = h.char }, "Idle", 0.3)
		end
	end
	-- he walks out of the fire, slow, to stand in the court
	if going() then
		hum.WalkSpeed = flat(stopAt - root.Position).Magnitude / (SHOT.out + SHOT.walk - 0.5)
		hum:MoveTo(stopAt)
		hold(SHOT.out + SHOT.walk, function()
			if flat(stopAt - root.Position).Magnitude > 1 then
				hum:MoveTo(stopAt) -- (again: a MoveTo gives up after 8s)
			end
		end)
	end
	hum:MoveTo(root.Position)
	hum.WalkSpeed = e.phase2 and e.def.Speed * e.def.Phase2Speed or e.def.Speed
	-- stops, and stares
	if going() then
		hum.AutoRotate = false
		playSound(root, BREATH, 0.8, 0.8)
		hold(SHOT.stare, stare)
	end
	-- the glaive brandished: hauled up over his head, held there, and driven down into the floor
	if going() then
		pose(e, "QCast", 0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		bodyPose(e, "QBCast", 0.9)
		playSound(root, SOUNDS.Unsheath, 1, 0.35)
		hold(1.3, stare)
	end
	if going() then
		pose(e, "QSlam", 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		bodyPose(e, "QBLine", 0.2)
		bladeTrail(e, 0.3)
		task.wait(0.2)
		local floor = root.Position - Vector3.new(0, 3 * e.def.Scale - 0.3, 0)
		fireDisc(floor + flat(root.CFrame.LookVector) * 5, 10, 2)
		burst(floor, EMBER, 50, 0.9, 40)
		playSound(root, SOUNDS.WatchdogSmash, 1.2, 0.45)
		FxRemote:FireAllClients("Shake", floor, 1)
		hold(SHOT.brandish - 1.5)
	end
	if e.skip and e.alive then -- skipped: stood out in the court at once, facing them
		root.Anchored = false
		e.model:PivotTo(CFrame.new(stopAt) * root.CFrame.Rotation)
		hum:MoveTo(stopAt)
		stare()
	end
	-- and the players let go (the server's hold too, if skipped: the client's own ends with its bar)
	for pl, h in pairs(held) do
		if e.skip and states[pl] then
			setAction(states[pl], now(), 0, 0, 0)
		end
		if h.hrp.Parent then
			h.hrp.Anchored = false
			pcall(function()
				h.hrp:SetNetworkOwner(pl)
			end)
		end
	end
	e.held, e.skip = nil, nil
	entering[e] = nil
	hum.AutoRotate = true
	if e.alive then
		pose(e, "Idle", 0.6)
		e.staggerUntil = 0 -- (and the fight)
	end
	e.entering = false
end

local current -- (the king as he stands, for the dev menu)
function M.onSpawn(e)
	current = e
	kneel(e)
	bossWatch(e)
end
-- his posture broken: down on one knee, leaning on the glaive, a moment wide open (the stagger, Def.Stagger long)
function M.onStagger(e)
	e.broken = now() + e.def.Stagger
	if e.root.Anchored then -- (broken mid-air? he still comes down: only the pose waits)
		return
	end
	pose(e, "QKneel", 0.2)
	bodyPose(e, "QBKneel", 0.2)
	setTrail(e, false)
	burst(e.root.Position, BLAZE, 40, 0.7, 30)
	playSound(e.root, SOUNDS.Impact, 1, 0.8)
	FxRemote:FireAllClients("Shake", e.root.Position, 0.5)
end

-- HIM AS THE COURT'S BOSS (started the first time the brain turns him on someone): the big bar, named, up while anyone
-- alive is in the Sunken Court with him; his second phase at half his health; and, when no one's left in the court and
-- he's walked back home (the shared brain heals him there), the fight reset - his opener owed again, his spell ready
M.Name = "Sun-Inquisitor, King of Pyralis"
bossWatch = function(e)
	if e.bossWatch then
		return
	end
	e.bossWatch = true
	e.model:SetAttribute("Boss", true) -- (the big bar, not a floating one)
	local RS = game:GetService("ReplicatedStorage")
	task.spawn(function()
		local shown = false
		while e.alive and e.model.Parent do
			task.wait(0.2)
			local SC, inCourt, past = Map and Map.SunkenCourt, false, false
			for _, pl in ipairs(Players:GetPlayers()) do
				local char, _, hrp = aliveChar(pl)
				local p = char and hrp.Position
				if p and SC and p.X > SC.MinX and p.X < SC.MaxX and p.Z > SC.MinZ and p.Z < SC.MaxZ and p.Y < SC.Floor + 40 then
					inCourt = true
					past = past or p.X < SC.Trigger -- (come far enough up the court, toward the colossus)
				end
			end
			if inCourt and past and e.dormant and not e.entering then -- (someone's come for him: he comes out of the fire)
				task.spawn(entrance, e)
			end
			if not inCourt then -- (nobody left alive in here: the way out opens)
				lockCourt(false)
			end
			local hum = e.hum
			if not e.phase2 and hum.Health > 0 and hum.Health <= hum.MaxHealth * e.def.Phase2 then -- (his fire roars up)
				e.phase2 = true
				hum.WalkSpeed = e.def.Speed * e.def.Phase2Speed
				FxRemote:FireAllClients("Shake", e.root.Position, 0.8)
				burst(e.root.Position, EMBER, 50, 0.9, 40)
				playSound(e.root, SOUNDS.WatchdogSmash, 1, 0.4)
				fireDisc(e.root.Position - Vector3.new(0, 3 * e.def.Scale - 0.2, 0), 8, 1.6)
			end
			if not inCourt and not e.dormant and not e.entering and not e.attacking and hum.Health >= hum.MaxHealth and flat(e.root.Position - e.home.Position).Magnitude < 4 then
				e.lastCombo, e.phase2, e.fatigue = nil, false, 0 -- (nobody left fighting him: begun anew,
				hum.WalkSpeed = e.def.Speed -- back on his knee where he waited)
				faceTowards(e.root, e.root.Position + e.home.LookVector)
				kneel(e)
			end
			local want = inCourt and hum.Health > 0 and not e.dormant and not e.entering -- (up once he's come out)
			if want ~= shown then
				shown = want
				if want then
					RS:SetAttribute("BossName", M.Name)
					RS:SetAttribute("BossMaxHP", hum.MaxHealth)
				end
				RS:SetAttribute("BossActive", want)
			end
			if shown then
				RS:SetAttribute("BossHP", math.max(0, hum.Health))
				local pv = math.clamp(e.fatigue or 0, 0, 1) -- (his posture: spent by his own attacks; full while he's down)
				if e.broken and now() < e.broken then
					pv = 1
				end
				RS:SetAttribute("BossPosture", pv)
			else
				RS:SetAttribute("BossPosture", nil)
			end
		end
		if shown then
			RS:SetAttribute("BossActive", false)
		end
		RS:SetAttribute("BossPosture", nil)
	end)
end
-- BEATEN: he stays on his knees in his court for good, leant on the glaive, and talks to you (Config.King.Fallen, a
-- line each time): the Key of Flame on FlameKeyAt, his sister's Foul Key on FoulKeyAt. (A dead rig isn't posed by the
-- Puppeteer: he's swapped for a living copy, an NPC, that goes down on its knees where he stood.)
local lineAt = {} -- per player: when his last line to them went up
local function fallenKing(cf)
	local K = Config.King
	local NPCs = workspace:FindFirstChild("NPCs") or Instance.new("Folder") -- (shared: one folder only)
	NPCs.Name = "NPCs"
	NPCs.Parent = workspace
	local S = M.Def.Scale
	local model, hum, weld = makeRig("FallenKing", "KingInquisitor", S, M.Def.Weapon)
	model.Parent = NPCs
	hum.HipHeight = model:GetAttribute("HipHeight")
	local root = model:FindFirstChild("HumanoidRootPart")
	model:PivotTo(cf)
	root.Anchored = true
	local actor = { model = model, weld = weld, scale = S }
	pose(actor, "QKneel", 1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	bodyPose(actor, "QBKneel", 1.0)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText, pp.ObjectText, pp.HoldDuration, pp.MaxActivationDistance, pp.RequiresLineOfSight = "Talk", K.Name, 0, 16, false
	pp.Parent = root
	local heard = {} -- per player: lines heard
	pp.Triggered:Connect(function(pl)
		if now() - (lineAt[pl] or -math.huge) < K.LineHold then -- (the line before still being read: not cut short)
			return
		end
		lineAt[pl] = now()
		local n = (heard[pl] or 0) + 1
		heard[pl] = n
		FxRemote:FireClient(pl, "Say", K.Name, K.Fallen[n] or K.FallenAfter)
		if n >= #K.Fallen then
			pl:SetAttribute("KingAsked", true) -- (he's asked you to find Giles: Characters/Taylor)
		end
		for _, key in ipairs({ { K.FlameKeyAt, "FlameKey", K.FlameKey, K.FlameKeyBanner }, { K.FoulKeyAt, "FoulKey", K.FoulKey, K.FoulKeyBanner } }) do
			if n == key[1] and not pl:GetAttribute(key[2]) then
				pl:SetAttribute(key[2], true)
				FxRemote:FireClient(pl, "Banner", key[4], "Lit")
				task.delay(1.5, function()
					FxRemote:FireClient(pl, "Message", key[3])
				end)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(pl)
		heard[pl], lineAt[pl] = nil, nil
	end)
	return model
end

-- beaten: down for good (the shared spawner passes over a Defeated kind) - on his knees, not dead - the victory, and
-- what he leaves
function M.onDied(e)
	M.Defeated = true
	Save.mark("King")
	lockCourt(false)
	game:GetService("ReplicatedStorage"):SetAttribute("BossActive", false)
	game:GetService("ReplicatedStorage"):SetAttribute("BossPosture", nil)
	FxRemote:FireAllClients("Banner", "KING OF PYRALIS FELLED", "Victory")
	local root = e.root
	if not (root and root.Parent) then
		return
	end
	local SC, at = Map.SunkenCourt, root.Position
	local floor = Vector3.new(at.X, SC.Floor, at.Z)
	burst(at, EMBER, 60, 1, 40)
	fireDisc(floor + Vector3.new(0, 0.2, 0), 10, 2.2)
	for _, pl in ipairs(Players:GetPlayers()) do
		local char, _, hrp = aliveChar(pl)
		if char and inCourt(hrp.Position) then
			FxRemote:FireClient(pl, "Say", Config.King.Name, Config.King.Dying)
			lineAt[pl] = now()
		end
	end
	local who = nearest(root)
	local fwd = who and flat(who.Position - at) or flat(root.CFrame.LookVector)
	fwd = fwd.Magnitude > 0.1 and fwd.Unit or Vector3.new(-1, 0, 0)
	local stand = Vector3.new(at.X, SC.Floor + 3 * e.def.Scale + 0.2, at.Z)
	local fallen = fallenKing(CFrame.lookAt(stand, stand + fwd))
	if dropSplinter then
		dropSplinter(floor + fwd * 8 + Vector3.new(0, 3, 0), fallen)
	end
	local model = e.model
	task.defer(function() -- (after the shared death code has had it: the dead rig goes, his kneeling self stays)
		model:Destroy()
	end)
end

-- the dev menu's "end the king's fight": beaten where he stands - or, still waiting in the fire, out in the court
-- where his entrance would have left him - straight to his knees and his talk
function M.devEnd()
	local e = current
	if not (e and e.alive and e.model.Parent) then
		return
	end
	local mouth = Map.SunkenCourt.Mouth
	if e.dormant or e.entering or flat(e.root.Position - mouth).Magnitude < 12 then
		e.skip = true -- (mid-entrance: its players let go)
		e.model:PivotTo(CFrame.lookAt(Vector3.new(mouth.X - 18, e.root.Position.Y, mouth.Z), Vector3.new(mouth.X - 40, e.root.Position.Y, mouth.Z)))
	end
	e.hum.Health = 0
end

-- spent: down onto his knee, leant on the glaive, heaving for breath; and up again, slowly, at the end of it
local function exhausted(e)
	local def, root = e.def, e.root
	local T = def.ExhaustTime
	e.staggerUntil, e.broken = now() + T, now() + T -- (the shared brain leaves him be; the bar shows white, full)
	setTrail(e, false)
	pose(e, "QKneel", 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	bodyPose(e, "QBKneel", 0.7)
	burst(root.Position, BLAZE, 30, 0.6, 20)
	FxRemote:FireAllClients("Shake", root.Position, 0.4)
	local breath = Instance.new("Sound")
	breath.SoundId, breath.Volume, breath.Looped, breath.RollOffMaxDistance = BREATH, 1.4, true, 220
	breath.Parent = root
	breath:Play()
	task.spawn(function()
		task.wait(T - def.ExhaustRise)
		if e.alive then -- (the head up first, the back straightening, still on the knee...)
			bodyPose(e, "QBRise", def.ExhaustRise * 0.5)
		end
		task.wait(def.ExhaustRise * 0.5)
		if e.alive then -- (...and up onto his feet, the glaive coming up across him)
			pose(e, "Idle", def.ExhaustRise * 0.5)
		end
		TweenService:Create(breath, TweenInfo.new(def.ExhaustRise * 0.5), { Volume = 0 }):Play()
		task.wait(def.ExhaustRise * 0.5)
		breath:Destroy()
		e.fatigue = 0
	end)
end

function M.attack(e, targetChar)
	local def, hum, root = e.def, e.hum, e.root
	local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
	if not tRoot then
		return
	end
	bossWatch(e)
	e.attacking = true -- (the shared brain only hands him someone inside his reach: Def.Engage)
	hum:MoveTo(root.Position)
	hum.AutoRotate = false
	-- out of his cut's reach: one of the gymnastic moves to close it; in it, any of everything - never the same twice
	local d = flat(tRoot.Position - root.Position).Magnitude
	local nc, nm = #M.Combos, #M.Moves
	local pick
	repeat
		pick = d > def.CleaveReach and nc + 1 + math.random(nm) or math.random(nc + 1 + nm)
	until pick ~= e.lastCombo or (d > def.CleaveReach and nm < 2)
	e.lastCombo = pick
	local F, spent = def.Fatigue, 0
	if pick == nc + 1 then -- (the Sun-Cleave into the Sun-Fall)
		spent = F.SunFall
		if cleave(e, tRoot) and e.alive and sunFall(e, tRoot) then
			hold(e, def.SlamRecover)
		end
	elseif pick <= nc then
		spent = F.Hit * #M.Combos[pick]
		if combo(e, tRoot, M.Combos[pick]) then
			hold(e, def.Recover)
		end
	else
		spent = F.Move
		if M.Moves[pick - nc - 1](e, tRoot) then
			hold(e, def.Recover * 0.6)
		end
	end
	if root.Parent then
		root.Anchored = false
	end
	e.fatigue = math.min(1, (e.fatigue or 0) + spent) -- (his posture spent on it)
	if e.alive and e.fatigue >= 1 and now() >= e.staggerUntil then
		exhausted(e)
	end
	if root.Parent then
		root.Anchored = false
	end
	setTrail(e, false)
	if e.alive and now() >= e.staggerUntil then -- (broken: left on his knee; the brain stands him up after)
		pose(e, "Idle", 0.6)
	end
	hum.AutoRotate = true
	e.attacking = false
end

-- HIS WALK (every client, layered over the shared stride: Puppeteer calls this after the pose is solved). A heavy,
-- unhurried stalk: the hips rolling and swinging forward with each leg, the body dipping onto every footfall, the
-- chest twisting against the hips and leaning into the walk, the shoulders rolling with it, the head held level and on
-- you through all of it. Held back to a trace while he's in the middle of an attack (his body pose not his guard)
function M.Gait(model, st, dt, now)
	local j = st.joints
	local w = st.walk or 0
	if not (j and j.Root and j.Waist and j.Neck) or w < 0.02 then
		return
	end
	local bp = model:GetAttribute("BP")
	if bp and bp ~= "QBGuard" and bp ~= "Idle" then
		w *= 0.25
	end
	local ph, s = st.phase or 0, st.D.s
	local sp, cp = math.sin(ph), math.cos(ph)
	local dip = math.abs(sp) -- (lowest as each foot comes down, the stride at its widest)
	j.Root.C0 = j.Root.C0 * CFrame.new(0, -dip * 0.16 * s * w, 0) * CFrame.Angles(0.04 * w, sp * 0.2 * w, -sp * 0.07 * w)
	j.Waist.C0 = j.Waist.C0 * CFrame.Angles(0.14 * w + dip * 0.05 * w, -sp * 0.34 * w, sp * 0.06 * w + cp * 0.03 * w)
	j.Neck.C0 = j.Neck.C0 * CFrame.Angles(-0.1 * w - dip * 0.04 * w, sp * 0.14 * w, -sp * 0.04 * w)
end

function M.init(core)
	Base.init(core) -- (the shared statues: Characters/KingGilded)
	pose, bodyPose, playSound, SOUNDS, now, faceTowards, setTrail, flat = core.pose, core.bodyPose, core.playSound, core.SOUNDS, core.now, core.faceTowards, core.setTrail, core.flat
	playersInSector, playersInRadius, damagePlayer, burst, dustCloud, FxRemote = core.playersInSector, core.playersInRadius, core.damagePlayer, core.burst, core.dustCloud, core.FxRemote
	Map, aliveChar, dropSplinter = core.Map, core.aliveChar, core.dropSplinter
	states, setAction, cancelSwing, makeRig, Config = core.states, core.setAction, core.cancelSwing, core.makeRig, core.Config
	Save = core.Save
	-- a held player holding Space through his entrance (the client's bar)
	local skip = Instance.new("RemoteEvent")
	skip.Name = "KingSkip"
	skip.Parent = game:GetService("ReplicatedStorage")
	skip.OnServerEvent:Connect(function(pl)
		for e in pairs(entering) do
			if e.held and e.held[pl] then
				e.skip = true
			end
		end
	end)
	-- beaten in this save: never stood up again (the spawner passes over a Defeated kind), on his knees out in the
	-- court where his entrance would have left him, facing the way in
	Save.on("King", function()
		M.Defeated = true
		local SC = Map.SunkenCourt
		if SC then
			local stand = Vector3.new(SC.Mouth.X - 18, SC.Floor + 3 * M.Def.Scale + 0.2, SC.Mouth.Z)
			fallenKing(CFrame.lookAt(stand, stand + Vector3.xAxis))
		end
	end)
end

return M
