--!nonstrict
-- THE OSSUARY WARDEN: the boss beyond the fog. A faceless, nondescript black figure in plate and mail, hung all over
-- with loose patches of black mail that swing as he moves (Carrier.cloth); a great mace. Scale 2.25 * 1.15.
-- Every wind-up is a chain of several body beats (settle, heft, rise, hang...) eased into one another, and he
-- coasts to a stop out of a walk, runs his charge on his own legs and leaps only so far, rather than snapping
-- into a pose or sliding across the room.
-- Phase 1: slam (sometimes delayed), low sweep (+backhand), stomp, shoulder charge, shockline.
-- Phase 2 at 70%: flaming mace, leap, fire nova, the three-hit string, burning ground.
-- Tuning: Config.Boss. Moves and how he picks them: BOSS_MOVES near the bottom.
--
-- EVERYTHING ABOUT THIS CHARACTER IS IN THIS ONE FILE:
--   M.Proportions / M.Poses   body shape and its full-body poses (the client animator uses these too)
--   M.Colors / M.Look         how the rig is dressed (RigBuilder calls Look with a kit of helpers:
--                             deco(part, name, size, offset, color, material?, shape?), V(x,y,z), at(x,y,z) ...)
--   M.Weapons / M.Grips       the weapon's model, and the grip poses its swings tween between
--   M.init(Core) and below    behaviour (server only)
-- SHARED TOOLKIT: server code here gets the shared helpers through M.init(Core)
-- (see the list at the top of ServerScriptService/GameServer/Core.lua). Body
-- poses not defined here (Idle, Windup, Strike, SweepWindup, SweepEnd, Recover,
-- Flinch, Stagger, Crouch, Air, Roar, Kneel) are shared ones from PuppetMath.
local M = {}
M.Kind = "Warden"
M.Proportions = { girth = 1.15, arm = 1.12, hunch = 0.08, twoHand = -0.9 }
M.IdlePose = "BIdle"
M.Poses = {
	-- his resting stance: weight low and shifting, the chest heaving
	BIdle = { drop = 0.3, lean = 0.2, twist = -0.12, head = 0.08, footR = -0.35, footL = 0.4, spread = 0.12, breathe = 2.6, freeL = 0 },
	-- the first beat of every wind-up: he settles his weight and gathers himself
	BGather = { drop = 0.5, lean = 0.28, twist = -0.32, hip = -0.12, look = 0.12, side = 0.07, head = 0.18, footR = -0.3, footL = 0.45, spread = 0.14, breathe = 3, freeL = 0 },
	-- rearing back for an overhead blow (deeper than the shared Windup)
	BRear = { drop = 0.18, lean = -0.42, twist = 0.38, hip = 0.2, look = -0.15, side = -0.06, head = -0.28, footR = -0.5, footL = 0.6, spread = 0.1, breathe = 3, freeL = 0 },
	-- the torso wound round for a low sweep (deeper than the shared SweepWindup)
	BCoil = { drop = 0.65, lean = 0.3, twist = -1.15, side = -0.1, head = -0.05, footR = -0.4, footL = 0.6, spread = 0.25, breathe = 2.5, freeL = 0 },
	-- weight rocking onto the planted leg before the stomp
	BStompGather = { drop = 0.5, lean = 0.15, side = 0.18, twist = 0.1, hip = 0.12, liftL = 0.15, head = 0.1, footR = 0.2, footL = -0.1, breathe = 3, freeL = 0 },
	-- follow-through: the blow carries his whole body with it
	BSlamDrive = { drop = 0.85, lean = 0.82, twist = -0.25, hip = -0.18, look = 0.1, side = 0.05, head = 0.28, footR = 0.95, footL = -0.85, spread = 0.18, breathe = 3, freeL = 0 },
	BSweepThrough = { drop = 0.55, lean = 0.38, twist = 1.2, side = 0.1, head = 0.05, footR = 0.75, footL = -0.45, spread = 0.3, breathe = 3, freeL = 0 },
	BSweepReturn = { drop = 0.5, lean = 0.3, twist = -1.05, side = -0.1, head = 0.05, footR = -0.4, footL = 0.7, spread = 0.3, breathe = 3, freeL = 0 },
	-- squaring the shoulders and sinking before the charge
	BChargeSet = { drop = 0.6, lean = 0.45, twist = -0.2, hip = -0.15, side = 0.06, head = -0.1, footR = 0.6, footL = -0.7, breathe = 3, freeL = 0 },
	Charge = { drop = 0.85, lean = 0.8, twist = -0.35, hip = 0.1, look = 0.25, head = -0.25, footR = 1.0, footL = -1.0, la1 = -0.6, la3 = -0.4, lel = 1.0, freeL = 0 },
	StompLift = { drop = 0.1, lean = -0.18, side = -0.12, hip = 0.15, lift = 1.7, footR = 0.7, la1 = 0.5, la3 = -1.1, freeL = 0 },
	-- THE REAPING SWEEP (bossSweep): his whole body in it - feet, knees, hips over planted feet (hip), waist (twist, side,
	-- lean), and the head held on you over the shoulder (look) while the rest of him winds away.
	-- plant: the left foot thrown wide and forward, sinking, the mace let down at his right side
	WPlant = { drop = 0.55, lean = 0.3, twist = -0.4, hip = -0.2, side = 0.05, head = 0.15, look = 0.35, footR = -0.5, footL = 0.75, spread = 0.3, breathe = 3, freeL = 0 },
	-- haul: hips and shoulders dragged round to the right after the mace, its head grinding the floor behind him
	WHaul = { drop = 0.75, lean = 0.45, twist = -1.0, hip = -0.45, side = -0.08, head = 0.1, look = 0.65, footR = -0.8, footL = 0.9, spread = 0.35, breathe = 3.5, freeL = 0 },
	-- load: wound as far as he goes - back nearly to you, knees deep, only his eyes still on you. Then it all lets go
	WLoad = { drop = 0.95, lean = 0.5, twist = -1.5, hip = -0.75, side = -0.15, head = -0.05, look = 1.0, footR = -0.95, footL = 1.0, spread = 0.42, breathe = 4.5, freeL = 0 },
	-- the release: driving off the back foot, the hips leading the shoulders through, then the right foot dragged round
	-- after the swing as it pulls him on into the finish
	WRelease = { drop = 0.85, lean = 0.62, twist = 0.1, hip = 0.15, side = 0.1, head = 0.22, look = -0.1, footR = 0.1, footL = 1.15, spread = 0.42, breathe = 3, freeL = 0 },
	WFinish = { drop = 0.72, lean = 0.5, twist = 1.4, hip = 0.6, side = 0.16, head = 0.1, look = -0.6, footR = 0.9, footL = 0.35, spread = 0.3, breathe = 3, freeL = 0 },
	-- THE BACKHAND (phase 2): the swing's weight carried on round behind his left side, the right foot planted, wound the
	-- other way, then the whole of him unwinding back across
	WBackCoil = { drop = 0.9, lean = 0.45, twist = 1.6, hip = 0.8, side = 0.14, head = 0, look = -1.0, footR = 1.05, footL = -0.5, spread = 0.42, breathe = 4.5, freeL = 0 },
	WBackThrough = { drop = 0.85, lean = 0.62, twist = -0.1, hip = -0.15, side = -0.1, head = 0.22, look = 0.1, footR = 1.2, footL = -0.2, spread = 0.42, breathe = 3, freeL = 0 },
	WBackFinish = { drop = 0.75, lean = 0.55, twist = -1.4, hip = -0.6, side = -0.16, head = 0.12, look = 0.6, footR = 0.4, footL = -0.9, spread = 0.3, breathe = 3, freeL = 0 },
	-- (an old spin wind-up: sinks low, feet wide, torso wound all the way round)
	Coil = { drop = 0.95, lean = 0.35, twist = -1.45, side = -0.08, head = -0.1, footR = -0.6, footL = 0.7, spread = 0.3, la1 = 0.4, la3 = -1.0, lel = 0.4, freeL = 0, breathe = 2.5 },
	-- IN-BETWEENS (the Wd ones): the beats between his stance and the big poses, so a wind-up is several movements
	-- eased together instead of one snap. Settle: weight caught on the front foot as he comes out of a walk.
	WdSettle = { drop = 0.38, lean = 0.26, twist = -0.08, head = 0.12, footR = 0.35, footL = -0.2, spread = 0.12, breathe = 3, freeL = 0 },
	-- the mace hefted onto his shoulder, the chest rising on a breath
	WdShoulder = { drop = 0.2, lean = 0.02, twist = 0.24, hip = 0.08, head = -0.08, footR = -0.25, footL = 0.4, spread = 0.12, breathe = 4.5, freeL = 0 },
	-- up onto the back foot with it overhead, chest lifted, chin up
	WdRise = { drop = 0.04, lean = -0.48, twist = 0.3, hip = 0.15, head = -0.35, footR = -0.55, footL = 0.55, spread = 0.1, breathe = 3, freeL = 0 },
	-- hanging at the top: the knees give a little under the weight, the shoulders still back
	WdHang = { drop = 0.3, lean = -0.36, twist = 0.34, hip = 0.18, head = -0.2, footR = -0.5, footL = 0.6, spread = 0.12, breathe = 2, freeL = 0 },
	-- the stomp's knee coming up, halfway
	WdKnee = { drop = 0.28, lean = 0.04, side = 0.12, hip = 0.12, lift = 0.8, footR = 0.4, la1 = 0.4, la3 = -0.8, breathe = 3, freeL = 0 },
	-- the charge: a foot scraped back along the stone, head down
	WdPaw = { drop = 0.55, lean = 0.42, twist = -0.15, hip = -0.1, head = -0.12, footR = -0.9, footL = 0.4, lift = 0.35, breathe = 4, freeL = 0 },
	-- skidding out of the charge: leaning back against it, the front foot braced
	WdSkid = { drop = 0.6, lean = -0.15, twist = 0.2, head = 0.05, footR = 0.9, footL = -0.5, spread = 0.2, breathe = 4, la1 = 0.7, la3 = -0.9, freeL = 0 },
	-- straightening out of a recovery on his way back to his stance
	WdStraighten = { drop = 0.25, lean = 0.22, twist = -0.05, head = 0.12, footR = 0.2, footL = -0.1, spread = 0.1, breathe = 4, freeL = 0 },
}
local BLACK, BLACK_MAIL = Color3.fromRGB(16, 16, 18), Color3.fromRGB(22, 22, 24)
M.Colors = { skin = BLACK, torso = BLACK_MAIL, legs = BLACK_MAIL, arms = BLACK_MAIL }
M.FistSkin = true -- (black gauntlets, not the default brown fists)

-- a patch of mail the clients hang off this anchor and swing (Carrier.cloth): its LookVector the side it hangs out on,
-- its RightVector the way its top edge runs. len/width are at scale 1.
local function mailPatch(k, onPart, cf, segs, len, width)
	local p = k.deco(onPart, "MailAnchor", k.V(0.1, 0.1, 0.1), cf, BLACK_MAIL, k.MAT.SmoothPlastic)
	p.Transparency = 1
	p:SetAttribute("Segs", segs)
	p:SetAttribute("Len", len * k.s)
	p:SetAttribute("Width", width * k.s)
	p:SetAttribute("Color", BLACK_MAIL)
	p:SetAttribute("Material", "DiamondPlate")
	p:SetAttribute("Drag", 0.93)
	p:SetAttribute("Gravity", 1.4) -- (mail: heavier than cloth, it swings rather than floats)
	game:GetService("CollectionService"):AddTag(p, "ClothChain")
end

function M.Look(k)
	local deco, V, at, MAT, D, s = k.deco, k.V, k.at, k.MAT, k.D, k.s
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	-- THE OSSUARY WARDEN: a nondescript black shape of plate and mail - no face, no device, nothing to know him by -
	-- hung all over with loose patches of black mail that swing and flutter as he moves.
	local plate, plateDark = Color3.fromRGB(26, 26, 28), Color3.fromRGB(12, 12, 13)
	local BALL = Enum.PartType.Ball
	for _, pn in ipairs({ "Chest", "Hips", "RUpperArm", "LUpperArm", "RThigh", "LThigh" }) do
		k.parts[pn].Material = MAT.DiamondPlate
	end
	-- the head: a closed mail coif over it, nothing showing
	deco("Head", "Coif", V(1.3, 1.36, 1.3), at(0, 0.03, 0.02), BLACK_MAIL, MAT.DiamondPlate)
	deco("Head", "CoifCrown", V(1.1, 0.2, 1.1), at(0, 0.72, 0.02), plateDark, MAT.DiamondPlate)
	-- plate: collar, shoulders, elbows, forearms, knees, shins, feet, a plain belt
	deco("Chest", "Gorget", V(cw * 0.62, 0.45, cd * 1.12), at(0, ch / 2 - 0.05, 0), plate, MAT.Metal)
	deco("Chest", "GorgetRim", V(cw * 0.68, 0.12, cd * 1.18), at(0, ch / 2 + 0.17, 0), plateDark, MAT.Metal)
	deco("Hips", "Belt", V(hw + 0.18, 0.28, hd + 0.18), at(0, 0.28, 0), plateDark, MAT.Leather)
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		for i = 0, 2 do
			deco(n .. "UpperArm", "Pauldron", V(aw * (1.95 - i * 0.1), 0.24, aw * (1.85 - i * 0.1)), at(sx * 0.06, ua / 2 - 0.02 - i * 0.2, 0) * CFrame.Angles(0, 0, -sx * (0.2 + i * 0.12)), i % 2 == 0 and plate or plateDark, MAT.Metal)
		end
		deco(n .. "UpperArm", "Couter", V(aw * 1.05, aw * 1.05, aw * 1.05), at(0, -ua / 2, 0.04), plate, MAT.Metal, BALL)
		deco(n .. "LowerArm", "Vambrace", V(aw * 1.12, la * 0.55, aw * 1.12), at(0, 0.05, 0), plate, MAT.Metal)
		deco(n .. "LowerArm", "Cuff", V(aw * 1.3, 0.25, aw * 1.3), at(0, -la / 2 + 0.25, 0), plateDark, MAT.Metal)
	end
	local tl, sl, fs = D.thigh / s, D.shin / s, D.footSize / s
	for _, n in ipairs({ "R", "L" }) do
		deco(n .. "Thigh", "Poleyn", V(lw * 1.05, lw * 1.05, lw * 1.05), at(0, -tl / 2, -0.08), plate, MAT.Metal, BALL)
		deco(n .. "Shin", "Greave", V(lw * 1.06, sl * 0.85, lw * 1.06), at(0, 0.02, 0), plate, MAT.Metal)
		deco(n .. "Foot", "Sabaton", V(fs.X * 1.08, fs.Y * 1.1, fs.Z * 1.04), at(0, 0.01, 0), plateDark, MAT.Metal)
	end
	-- under it all, a static mail skirt to the knee (so nothing shows between the loose patches)
	local rng = Random.new(23)
	for _, z in ipairs({ -1, 1 }) do
		for i = 1, 5 do
			local top = CFrame.new((-0.5 + (i - 0.5) / 5) * (hw + 0.1), 0.05, z * (hd / 2 + 0.06))
			k.tatter(rng, "Hips", top, (hw + 0.1) / 5 * 1.35, rng:NextNumber(1.15, 1.3), BLACK_MAIL, BLACK, 0.2)
		end
	end
	for _, sx in ipairs({ -1, 1 }) do
		for i = 1, 3 do
			local top = CFrame.new(sx * (hw / 2 + 0.05), 0.05, (-0.5 + (i - 0.5) / 3) * hd) * CFrame.Angles(0, math.pi / 2, 0)
			k.tatter(rng, "Hips", top, hd / 3 * 1.35, rng:NextNumber(1.05, 1.2), BLACK_MAIL, BLACK, 0.2)
		end
	end

	-- THE LOOSE MAIL: patches hung all over him that the clients swing (facing: yaw that turns the anchor's look
	-- from forward (-Z) to the side it hangs on). Short ones on the chest and arms, long ones round the skirt.
	local FRONT, BACK, RIGHT, LEFT = CFrame.new(), CFrame.Angles(0, math.pi, 0), CFrame.Angles(0, -math.pi / 2, 0), CFrame.Angles(0, math.pi / 2, 0)
	for _, side in ipairs({ { -1, FRONT }, { 1, BACK } }) do
		local z, face = side[1] * (cd / 2 + 0.06), side[2]
		for _, x in ipairs({ -0.62, 0, 0.62 }) do -- (across the breast, under the collar)
			mailPatch(k, "Chest", at(x * cw / 2, ch / 2 - 0.3, z) * face, 2, 0.32, 0.62)
		end
		for _, x in ipairs({ -0.35, 0.35 }) do -- (a lower row, staggered)
			mailPatch(k, "Chest", at(x * cw / 2, -0.05, z) * face, 2, 0.3, 0.7)
		end
		for _, x in ipairs({ -0.6, 0, 0.6 }) do -- (round the skirt: long, to below the knee)
			mailPatch(k, "Hips", at(x * hw / 2, -0.05, side[1] * (hd / 2 + 0.14)) * face, 3, 0.48, 0.66)
		end
	end
	for _, sx in ipairs({ -1, 1 }) do
		local face = sx == 1 and RIGHT or LEFT
		for _, z in ipairs({ -0.25, 0.25 }) do
			mailPatch(k, "Hips", at(sx * (hw / 2 + 0.14), -0.05, z * hd) * face, 3, 0.46, 0.55)
		end
		local n = sx == 1 and "R" or "L"
		mailPatch(k, n .. "UpperArm", at(sx * (aw / 2 + 0.12), ua / 2 - 0.55, 0) * face, 2, 0.3, 0.55) -- (off the pauldron's edge)
		mailPatch(k, n .. "LowerArm", at(sx * (aw / 2 + 0.08), la / 2 - 0.1, 0) * face, 2, 0.26, 0.45)
		mailPatch(k, n .. "Thigh", at(0, tl / 2 - 0.1, -(lw / 2 + 0.1)), 2, 0.34, 0.6)
	end
end

M.Weapons = {
	-- a great flanged mace: a thick ironbound haft wrapped in leather where he holds it,
	-- a heavy pommel, and a head of six blunt flanges between iron bands, a skull lashed
	-- under it with chain. All blunt. (Sizes are at scale 1; the hit sweep is unchanged.)
	Mace = function(w)
		local mk, add, s = w.mk, w.add, w.scale
		local iron, ironDark = Color3.fromRGB(52, 48, 44), Color3.fromRGB(34, 32, 30)
		local leather, bone = Color3.fromRGB(58, 40, 28), Color3.fromRGB(176, 168, 146)
		local function ball(name, size, color, material, y, rot)
			local p = mk(name, Vector3.new(size, size, size), color, material)
			p.Shape = Enum.PartType.Ball
			add(p, y, rot)
			return p
		end
		local handle = mk("Haft", Vector3.new(0.6, 3.8, 0.6), Color3.fromRGB(40, 30, 22), Enum.Material.Wood)
		-- leather grip, bound in rings around the hand (the hand sits at +1.4)
		for i = 0, 4 do
			add(mk("Wrap", Vector3.new(0.68, 0.2, 0.68), leather, Enum.Material.Fabric), 0.75 + i * 0.28, CFrame.Angles(0, i * 0.4, 0))
		end
		add(mk("Pommel", Vector3.new(0.9, 0.45, 0.9), ironDark, Enum.Material.Metal), 2.05)
		ball("PommelKnob", 0.62, iron, Enum.Material.Metal, 2.4)
		-- iron langets riveted down the haft below the head
		for k = 0, 3 do
			add(mk("Langet", Vector3.new(0.4, 1.5, 0.1), iron, Enum.Material.Metal), -1.0, CFrame.Angles(0, k * math.pi / 2, 0) * CFrame.new(0, 0, 0.33 * s))
		end
		add(mk("Collar", Vector3.new(0.98, 0.32, 0.98), ironDark, Enum.Material.Metal), -1.6)
		-- the head: an iron core, six flanges, bands top and bottom, a capped crown
		add(mk("Head", Vector3.new(1.3, 1.8, 1.3), ironDark, Enum.Material.Metal), -2.4)
		for k = 0, 5 do
			add(mk("Flange", Vector3.new(0.22, 1.6, 0.85), iron, Enum.Material.Metal), -2.4, CFrame.Angles(0, k * math.pi / 3, 0) * CFrame.new(0, 0, 0.85 * s))
		end
		for _, y in ipairs({ -1.55, -3.25 }) do
			add(mk("HeadBand", Vector3.new(1.5, 0.2, 1.5), ironDark, Enum.Material.Metal), y)
		end
		add(mk("Cap", Vector3.new(0.95, 0.4, 0.95), iron, Enum.Material.Metal), -3.5)
		ball("Finial", 0.55, ironDark, Enum.Material.Metal, -3.8)
		-- a skull lashed under the head with a few links of chain
		ball("Skull", 0.62, bone, Enum.Material.SmoothPlastic, -1.2, CFrame.Angles(0, 0.4, 0) * CFrame.new(0, 0, 0.62 * s))
		for i = 0, 2 do
			add(mk("Link", Vector3.new(0.08, 0.24, 0.16), iron, Enum.Material.Metal), -1.35 - i * 0.2, CFrame.Angles(0, 0.4 + (i % 2) * math.pi / 2, 0) * CFrame.new(0, 0, 0.4 * s))
		end
		-- the haft is centred on the hand, the head hangs below it
		return { handle = handle, bladeLen = 3.3, gripC1 = CFrame.new(0, 1.4 * s, 0) }
	end,
}
-- low sweeps: hip-high, wide, and tilted 24 deg down, so a big mace passes through player
-- height and its tip just clears the floor (the Castellan swings through these too)
M.Grips = {
	BSweepBack = { Vector3.new(2.0, -0.6, 1.0), CFrame.Angles(0, math.rad(-45), 0) * CFrame.Angles(0, 0, math.rad(66)) },
	BSweepMid = { Vector3.new(0, -0.6, -2.2), CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(0, 0, math.rad(66)) },
	BSweepEnd = { Vector3.new(-1.6, -0.6, -0.4), CFrame.Angles(0, math.rad(205), 0) * CFrame.Angles(0, 0, math.rad(66)) },
	-- the first beat of a wind-up: hefted up onto the shoulder, head standing behind it
	BHeft = { Vector3.new(1.3, 1.0, 0.7), CFrame.Angles(math.rad(190), 0, math.rad(15)) },
	-- ...or dropped low at his side, head trailing, before a sweep or a charge
	BSweepGather = { Vector3.new(1.4, -0.6, 0.3), CFrame.Angles(0, math.rad(-20), 0) * CFrame.Angles(math.rad(-45), 0, math.rad(55)) },
	-- THE REAPING SWEEP (his alone; the B ones above are shared with the Castellan). Yaw = which way out the haft points,
	-- the second angle how near flat it lies. Let down at his side, dragged round behind him head on the floor, lifted
	-- into the load, then out wide - well past where the old sweep reached - right, front, left, and wrapped round
	WReapLow = { Vector3.new(1.5, -0.8, 0.5), CFrame.Angles(0, math.rad(-25), 0) * CFrame.Angles(math.rad(-35), 0, math.rad(48)) },
	WReapHaul = { Vector3.new(1.6, -0.8, 1.8), CFrame.Angles(0, math.rad(-75), 0) * CFrame.Angles(0, 0, math.rad(52)) },
	WReapLoad = { Vector3.new(1.2, -0.4, 2.3), CFrame.Angles(0, math.rad(-100), 0) * CFrame.Angles(math.rad(8), 0, math.rad(72)) },
	WReapR = { Vector3.new(2.7, -0.7, -0.6), CFrame.Angles(0, math.rad(12), 0) * CFrame.Angles(0, 0, math.rad(68)) },
	WReapFront = { Vector3.new(0.2, -0.7, -2.9), CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(0, 0, math.rad(68)) },
	WReapL = { Vector3.new(-2.5, -0.7, -0.9), CFrame.Angles(0, math.rad(160), 0) * CFrame.Angles(0, 0, math.rad(68)) },
	WReapEnd = { Vector3.new(-1.5, -0.5, 0.9), CFrame.Angles(0, math.rad(215), 0) * CFrame.Angles(0, 0, math.rad(62)) },
	-- the backhand: the swing's weight carried on round behind his left side and lifted, then back across the same way
	WBackLoad = { Vector3.new(-1.0, -0.4, 2.3), CFrame.Angles(0, math.rad(255), 0) * CFrame.Angles(math.rad(-8), 0, math.rad(72)) },
	WBackEnd = { Vector3.new(1.7, -0.5, 1.0), CFrame.Angles(0, math.rad(-35), 0) * CFrame.Angles(0, 0, math.rad(62)) },
}
M.BodyFor = { BSweepBack = "SweepWindup", BSweepEnd = "SweepEnd" }

---------------------------------------------------------------------------
-- server: the fight
---------------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Map, EnemiesFolder, FxRemote, states, now, flat, rand, turnTowards, SOUNDS, playSound, burst, fxAnchor, dustCloud, crackLines, fadeAway, shockwave, groundHeave, debrisChunks, SMOKE, SPARK, pose, bodyPose, setTrail, makeRig, findShoulder, aliveChar, damagePlayer, playersInRadius
local dropSplinter

local BOSS_SCALE = 2.25 * 1.15
local K = BOSS_SCALE / 3 -- reach and body-sized hitboxes were tuned at scale 3: they shrink with him
local SPEED = 1.1 -- everything he does (moves, turns, wind-ups, swings, recoveries) runs this much faster
local boss: any = {
	state = "none", -- none | dormant | intro | fight | dead
	gen = 0, -- bumps every respawn so stale coroutines stop touching the new boss
	phase2 = false,
	leapReady = 0,
	stompReady = 0,
}
	-- boss.current = the live boss's actor snapshot (weld/tween/root for posing)

-- every boss hit goes through this (difficulty knob: Config.Boss.DamageScale)
local function bossDmg(x)
	return math.max(1, math.floor(x * (Config.Boss.DamageScale or 1) + 0.5))
end

---------------------------------------------------------------------------
-- boss: the old Warden (no longer spawned, see the end of this file)
---------------------------------------------------------------------------
local bossAI -- forward declaration

local function snapBoss()
	-- one actor table per boss life, shared by every coroutine (so hit-stop can find its tween)
	if boss.current and boss.current.gen == boss.gen then
		return boss.current
	end
	return {
		model = boss.model,
		hum = boss.hum,
		root = boss.root,
		weld = boss.weld,
		scale = BOSS_SCALE,
		shoulder = boss.shoulder,
		c0 = boss.c0,
		gen = boss.gen,
	}
end

local function live(b)
	return boss.gen == b.gen and boss.state == "fight" and b.hum.Parent ~= nil and b.hum.Health > 0
end

-- back to his stance in two movements: he straightens up out of the recovery, then settles into his guard
local function bossIdleArm(b)
	setTrail(b, false)
	local tok = {}
	boss.idleTok = tok
	bodyPose(b, "WdStraighten", 0.4)
	task.delay(0.35 / SPEED, function()
		if boss.idleTok == tok and boss.gen == b.gen and b.hum.Parent then
			pose(b, "Idle", 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		end
	end)
end

local function leapTo(b, groundPos, duration, damage)
	local root = b.root
	if not root or not root.Parent then
		return
	end
	root.Anchored = true
	local startPos = root.Position
	local height = 3 * BOSS_SCALE
	local endPos = Vector3.new(math.clamp(groundPos.X, -38, 38), height, math.clamp(groundPos.Z, 222, 286))
	local look = flat(endPos - startPos)
	local rot = look.Magnitude > 0.1 and CFrame.lookAt(Vector3.zero, look) or root.CFrame.Rotation
	local t0 = now()
	while true do
		local a = math.min((now() - t0) / duration, 1)
		local across = a * 0.5 + a * a * (3 - 2 * a) * 0.5 -- eases off the ground and into the landing
		local arc = 6 + flat(endPos - startPos).Magnitude * 0.3 -- (a short hop stays low, a long one goes high)
		local pos = startPos:Lerp(endPos, across) + Vector3.new(0, math.sin(a * math.pi) * arc, 0)
		root.CFrame = CFrame.new(pos) * rot.Rotation
		if a >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
		if boss.gen ~= b.gen or boss.state == "dead" or not root.Parent then
			return
		end
	end
	local ground = Vector3.new(endPos.X, 0.2, endPos.Z)
	shockwave(ground, 14 * K)
	playSound(root, SOUNDS.Impact, 1, 0.5)
	FxRemote:FireAllClients("Shake", ground, 1.4)
	if damage then
		for _, pl in ipairs(playersInRadius(ground, 11 * K, 14)) do
			damagePlayer(pl, bossDmg(damage), ground, "Knockdown")
		end
	end
end

---------------------------------------------------------------------------
-- boss helpers
---------------------------------------------------------------------------
local function tempo()
	return boss.phase2 and 0.85 or 1 -- phase 2 winds up faster
end

local function turnRate()
	return math.rad(boss.phase2 and 170 or 115) * SPEED -- deg/s: slow enough to roll behind it
end

local function walkSpeed()
	return (boss.phase2 and 14 or 11) * SPEED
end

local function bossFree(b)
	return live(b) and now() >= (boss.staggerUntil or 0)
end

-- wind up, turning toward the target for the first trackFrac of it, then commit.
-- Returns false if the boss died, reset or got staggered.
local function windupTrack(b, duration, trackFrac, target)
	duration /= SPEED
	local t0 = now()
	while now() - t0 < duration do
		if not bossFree(b) then
			return false
		end
		local tr = target and target:FindFirstChild("HumanoidRootPart")
		local dt = task.wait()
		if tr and now() - t0 < duration * trackFrac then
			turnTowards(b.root, tr.Position, turnRate() * dt * 1.6)
		end
	end
	return true
end

-- Telegraphs build up instead of snapping: a wind-up eases in and out, and comes in
-- two beats - he gathers his weight with the mace part-way, then makes the full draw -
-- with his body and the mace moving together. gather/full = { grip, body pose, seconds }.
-- Tracks the target for the first `track` seconds. Same false-on-interrupt as windupTrack.
local EASE, INOUT = Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
local function draw(b, grip, body, t)
	boss.idleTok = nil -- (a move has begun: a pending return to stance mustn't land on top of it)
	pose(b, grip, t, EASE, INOUT)
	if body then
		bodyPose(b, body, t)
	end
end
-- any number of beats: { grip, body pose, seconds, onStart? } each; tracks for the first `track` seconds in all
local function windupBeats(b, target, list, track)
	for _, bt in ipairs(list) do
		draw(b, bt[1], bt[2], bt[3])
		if bt[4] then
			bt[4]()
		end
		if not windupTrack(b, bt[3], math.clamp(track / bt[3], 0, 1), target) then
			return false
		end
		track -= bt[3]
	end
	return true
end

local function waitLive(b, duration)
	duration /= SPEED
	local t0 = now()
	while now() - t0 < duration do
		if not live(b) then
			return false
		end
		task.wait()
	end
	return true
end

local function hitOnce(list, seen, damage, fromPos, level)
	for _, pl in ipairs(list) do
		if not seen[pl] then
			if damagePlayer(pl, bossDmg(damage), fromPos, level) then
				seen[pl] = true
			end
		end
	end
end

local function inArena(pos)
	return pos.X > -43 and pos.X < 43 and pos.Z > 217 and pos.Z < 303
end

-- The mace's real path hurts: sample it every frame (like the player's sword).
local maceParams = OverlapParams.new()
maceParams.FilterType = Enum.RaycastFilterType.Include
maceParams.CollisionGroup = "HitQuery"

local function maceEnds(b)
	local weld = b.weld
	local handle = weld and weld.Parent and weld.Part1
	if not handle or not handle.Parent then
		return nil
	end
	local base, tip = handle:FindFirstChild("BladeBase"), handle:FindFirstChild("BladeTip")
	if base and tip then
		return base.WorldPosition, tip.WorldPosition
	end
	return nil
end

local function maceSweep(b, duration, damage, level, seen, radius)
	duration /= SPEED
	local chars = {}
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl.Character then
			table.insert(chars, pl.Character)
		end
	end
	maceParams.FilterDescendantsInstances = chars
	local t0 = now()
	local pb, pt
	while now() - t0 < duration and live(b) do
		local base, tip = maceEnds(b)
		if base then
			pb, pt = pb or base, pt or tip
			for i = 0, 3 do
				local f = i / 3
				local bb, tt = pb:Lerp(base, f), pt:Lerp(tip, f)
				for j = 0, 6 do
					for _, part in ipairs(workspace:GetPartBoundsInRadius(bb:Lerp(tt, j / 6), radius or 2.2, maceParams)) do
						local pl = Players:GetPlayerFromCharacter(part:FindFirstAncestorOfClass("Model"))
						if pl and not seen[pl] and damagePlayer(pl, bossDmg(damage), b.root.Position, level) then
							seen[pl] = true
						end
					end
				end
			end
			pb, pt = base, tip
		end
		RunService.Heartbeat:Wait()
	end
end
-- Fissures in the floor that glow hotter as a blast builds. Returns a function that fades them.
local function heatCracks(center, radius, dur)
	local list = crackLines(Vector3.new(center.X, center.Y + 0.04, center.Z), radius, 10, Color3.fromRGB(70, 18, 6), Enum.Material.Neon, dur * 0.7)
	for _, seg in ipairs(list) do
		TweenService:Create(seg, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Color = Color3.fromRGB(255, 140, 50) }):Play()
	end
	local glow = fxAnchor(center + Vector3.new(0, 1, 0))
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 120, 50)
	l.Range = radius * 1.6
	l.Brightness = 0
	l.Parent = glow
	TweenService:Create(l, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Brightness = 4 }):Play()
	local embers = Instance.new("ParticleEmitter")
	embers.Texture = SPARK
	embers.Rate = 40
	embers.Lifetime = NumberRange.new(0.8, 1.6)
	embers.Speed = NumberRange.new(2, 6)
	embers.SpreadAngle = Vector2.new(30, 30)
	embers.Size = NumberSequence.new(0.25, 0)
	embers.Color = ColorSequence.new(Color3.fromRGB(255, 150, 60))
	embers.LightEmission = 1
	embers.Acceleration = Vector3.new(0, 4, 0)
	embers.Parent = glow
	return function()
		embers.Enabled = false
		TweenService:Create(l, TweenInfo.new(1), { Brightness = 0 }):Play()
		Debris:AddItem(glow, 1.5)
		for _, seg in ipairs(list) do
			TweenService:Create(seg, TweenInfo.new(1.2), { Color = Color3.fromRGB(30, 26, 24) }):Play()
			seg.Material = Enum.Material.Slate
		end
		fadeAway(list, 3, 1.5)
	end
end

-- Soot-black scorching that creeps across the stone to exactly where a blast
-- will reach, with heat-shimmer smoke rising off it. Returns a function that fades it.
local function scorchSpread(center, radius, dur)
	local disc = Instance.new("Part")
	disc.Name = "Scorch"
	disc.Anchored = true
	disc.CanCollide = false
	disc.CanQuery = false
	disc.CanTouch = false
	disc.CastShadow = false
	disc.Shape = Enum.PartType.Cylinder
	disc.Material = Enum.Material.Slate
	disc.Color = Color3.fromRGB(14, 12, 11)
	disc.Transparency = 0.7
	disc.Size = Vector3.new(0.05, radius * 0.4, radius * 0.4)
	disc.CFrame = CFrame.new(center.X, center.Y + 0.035, center.Z) * CFrame.Angles(0, 0, math.pi / 2)
	disc.Parent = workspace
	local info = TweenInfo.new(dur * 0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(disc, info, { Size = Vector3.new(0.05, radius * 2, radius * 2), Transparency = 0.12 }):Play()
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = SMOKE
	smoke.Rate = math.clamp(radius * 3, 8, 50)
	smoke.Lifetime = NumberRange.new(0.8, 1.5)
	smoke.Speed = NumberRange.new(1.5, 4)
	smoke.EmissionDirection = Enum.NormalId.Right -- the cylinder's axis points up
	smoke.SpreadAngle = Vector2.new(10, 10)
	smoke.Size = NumberSequence.new(0.8, 2.2)
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
	smoke.Color = ColorSequence.new(Color3.fromRGB(30, 27, 25))
	smoke.LightInfluence = 1
	smoke.Parent = disc
	return function()
		smoke.Enabled = false
		task.delay(1, function()
			if disc.Parent then
				TweenService:Create(disc, TweenInfo.new(2), { Transparency = 1 }):Play()
			end
		end)
		Debris:AddItem(disc, 3.2)
	end
end

local function burnPlayer(pl, dmg)
	local st = states[pl]
	local char, hum = aliveChar(pl)
	if not (st and char) then
		return
	end
	local t = now()
	if t >= st.iStart and t <= st.iEnd then
		return
	end
	hum:TakeDamage(bossDmg(dmg))
	FxRemote:FireClient(pl, "Burn")
end

-- burning ground (phase 2): damage over time, no stagger
local function firePatch(pos, radius, duration)
	local p = Instance.new("Part")
	p.Name = "FirePatch"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Shape = Enum.PartType.Cylinder
	p.Material = Enum.Material.Slate
	p.Color = Color3.fromRGB(24, 21, 19) -- scorched stone
	p.Transparency = 0.25
	p.Size = Vector3.new(0.05, radius * 2, radius * 2)
	p.CFrame = CFrame.new(pos.X, pos.Y + 0.02, pos.Z) * CFrame.Angles(0, 0, math.pi / 2)
	p.Parent = workspace
	local embers = Instance.new("ParticleEmitter")
	embers.Texture = SPARK
	embers.Rate = 25
	embers.Lifetime = NumberRange.new(0.6, 1.4)
	embers.Speed = NumberRange.new(1, 4)
	embers.Size = NumberSequence.new(0.2, 0)
	embers.Color = ColorSequence.new(Color3.fromRGB(255, 140, 60))
	embers.LightEmission = 1
	embers.Acceleration = Vector3.new(0, 3, 0)
	embers.Parent = p
	local f = Instance.new("Fire")
	f.Size = radius * 1.4
	f.Heat = 6
	f.Color = Color3.fromRGB(255, 110, 30)
	f.SecondaryColor = Color3.fromRGB(100, 20, 5)
	f.Parent = p
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 120, 50)
	l.Range = radius * 3
	l.Brightness = 1.5
	l.Parent = p
	TweenService:Create(p, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Transparency = 1 }):Play()
	Debris:AddItem(p, duration + 0.1)
	task.spawn(function()
		local t0 = now()
		while now() - t0 < duration do
			for _, pl in ipairs(playersInRadius(pos, radius, 6)) do
				burnPlayer(pl, 5)
			end
			task.wait(0.4)
		end
	end)
end

-- rock spikes bursting out of the floor
local function eruption(pos, radius, damage, level, fiery)
	local color = fiery and Color3.fromRGB(150, 60, 30) or Color3.fromRGB(80, 74, 66)
	for i = 1, 5 do
		local a = i / 5 * math.pi * 2 + math.random()
		local spike = Instance.new("Part")
		spike.Name = "Spike"
		spike.Anchored = true
		spike.CanCollide = false
		spike.CanQuery = false
		spike.CanTouch = false
		spike.Material = Enum.Material.Slate
		spike.Color = color
		local h = radius * rand(1.2, 1.9)
		spike.Size = Vector3.new(0.9, h, 0.9)
		local base = pos + Vector3.new(math.cos(a) * radius * 0.45, 0, math.sin(a) * radius * 0.45)
		local tilt = CFrame.Angles(rand(-0.4, 0.4), rand(0, 6), rand(-0.4, 0.4))
		spike.CFrame = CFrame.new(base - Vector3.new(0, h / 2, 0)) * tilt
		spike.Parent = workspace
		TweenService:Create(spike, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = CFrame.new(base + Vector3.new(0, h * 0.3, 0)) * tilt }):Play()
		task.delay(0.7, function()
			TweenService:Create(spike, TweenInfo.new(0.4), { CFrame = CFrame.new(base - Vector3.new(0, h, 0)) * tilt }):Play()
		end)
		Debris:AddItem(spike, 1.2)
	end
	shockwave(pos, radius * 1.2)
	hitOnce(playersInRadius(pos, radius, 8), {}, damage, pos, level)
	if fiery then
		firePatch(pos, radius * 0.8, 2.5)
	end
end

-- Out of a walk he doesn't freeze mid-stride: he coasts a step or so to a stop while the wind-up starts above it.
local function stopAndFace(b, target)
	b.hum.AutoRotate = false
	local v = flat(b.root.AssemblyLinearVelocity)
	if v.Magnitude > 2 and not b.root.Anchored then
		b.hum.WalkSpeed = v.Magnitude * 0.45
		b.hum:MoveTo(b.root.Position + v.Unit * math.min(v.Magnitude * 0.2, 2.5))
	else
		b.hum:MoveTo(b.root.Position)
	end
end

-- Every attack opens with a physical tell: the eyes flare and it growls.
local function tell(b, pitch, hold) -- (hold: seconds the eyes stay lit, 0.35 by default)
	playSound(b.root, SOUNDS.Groan, 0.7, pitch or 0.32)
	for _, d in ipairs(b.model:GetChildren()) do
		if d.Name == "Eye" and d:IsA("BasePart") then
			local base = d.Color
			d.Color = Color3.fromRGB(255, 150, 90)
			task.delay(hold or 0.35, function()
				if d.Parent then
					TweenService:Create(d, TweenInfo.new(0.5), { Color = base }):Play()
				end
			end)
		end
	end
end

-- dust kicked up by a foot (charge wind-up, leap take-off)
local function footDust(b, side, amount)
	local root = b.root
	local p = root.CFrame * Vector3.new(side * 1.6 * BOSS_SCALE * 0.5, -3 * BOSS_SCALE + 0.4, 0.5 * BOSS_SCALE)
	dustCloud(p, 1.6, amount or 6)
end

-- he steps into a blow: a short burst of his own walk toward where he faces, a foot
-- coming down in dust, so the strike travels with his whole weight behind it
local function stepInto(b, dist, dur)
	dur /= SPEED
	local hum, root = b.hum, b.root
	if root.Anchored then
		return
	end
	local fwd = flat(root.CFrame.LookVector)
	if fwd.Magnitude < 0.1 then
		return
	end
	hum.WalkSpeed = dist / dur
	hum:MoveTo(root.Position + fwd.Unit * dist)
	task.delay(dur, function()
		if boss.gen == b.gen and b.hum.Parent then
			hum.WalkSpeed = walkSpeed()
			hum:MoveTo(root.Position)
			footDust(b, 1, 4)
		end
	end)
end

-- stand on the floor exactly (after leaps), whatever happened mid-air
local snapParams = RaycastParams.new()
snapParams.FilterType = Enum.RaycastFilterType.Exclude
local function snapToGround(b)
	local root = b.root
	b.hum.HipHeight = b.model:GetAttribute("HipHeight") or b.hum.HipHeight
	local ignore = { EnemiesFolder }
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl.Character then
			table.insert(ignore, pl.Character)
		end
	end
	snapParams.FilterDescendantsInstances = ignore
	local res = workspace:Raycast(root.Position + Vector3.new(0, 6, 0), Vector3.new(0, -40, 0), snapParams)
	if res then
		root.CFrame = CFrame.new(root.Position.X, res.Position.Y + 3 * BOSS_SCALE, root.Position.Z) * root.CFrame.Rotation
	end
	root.AssemblyLinearVelocity = Vector3.zero
	pcall(function()
		b.hum:ChangeState(Enum.HumanoidStateType.Running)
	end)
end

---------------------------------------------------------------------------
-- boss moves
---------------------------------------------------------------------------
-- Overhead slam: rears back with the mace high. `delayed`: holds at the top.
local function bossSlam(b, target, opts)
	opts = opts or {}
	local m = tempo()
	stopAndFace(b, target)
	tell(b)
	playSound(b.root, SOUNDS.Unsheath, 0.9, 0.45)
	-- heft onto the shoulder on a breath, sink his weight, lift it overhead rising onto the back foot, rear the last of the way
	if not windupBeats(b, target, {
		{ "BHeft", "WdShoulder", 0.3 * m },
		{ "BHeft", "BGather", 0.25 * m },
		{ "Raise", "WdRise", 0.4 * m },
		{ "Raise", "BRear", 0.3 * m },
	}, 0.95 * m) then
		return
	end
	if opts.delayed then
		-- hangs at the top, knees giving under it, then leans back further still, creaking, and the drop comes late
		bodyPose(b, "WdHang", 0.25)
		if not windupTrack(b, 0.25, 0, target) then
			return
		end
		bodyPose(b, "Roar", 0.35)
		playSound(b.root, SOUNDS.Unsheath, 0.7, 0.32)
		if not windupTrack(b, 0.35 + math.random() * 0.3, 0, target) then
			return
		end
	end
	setTrail(b, true)
	stepInto(b, 5 * K, 0.25)
	pose(b, "Mid", 0.06, Enum.EasingStyle.Linear)
	task.delay(0.06, function()
		pose(b, "Strike", 0.08)
		bodyPose(b, "BSlamDrive", 0.12) -- the whole body drives down through it
	end)
	playSound(b.root, SOUNDS.Lunge, 0.9, 0.5)
	local seen = {}
	task.spawn(maceSweep, b, 0.2, 45, "Knockdown", seen, 2.2 * K)
	task.wait(0.13 / SPEED)
	if not live(b) then
		return
	end
	local _, tip = maceEnds(b)
	local impact = tip or (b.root.Position + flat(b.root.CFrame.LookVector).Unit * 15 * K)
	impact = Vector3.new(impact.X, 0.2, impact.Z)
	shockwave(impact, 9 * K)
	playSound(b.root, SOUNDS.Impact, 1, 0.6)
	FxRemote:FireAllClients("Shake", impact, 1.1)
	hitOnce(playersInRadius(impact, 6 * K, 10), seen, 30, impact, "Large")
	if boss.phase2 then
		firePatch(impact, 6, 4)
	end
	if not opts.recover then
		bodyPose(b, "Recover", 0.5) -- bent over the stuck mace: punish it
	end
	if waitLive(b, opts.recover or 1.3 * m) and not opts.recover then
		bossIdleArm(b)
	end
end

-- THE REAPING SWEEP: the move he puts the most into, and gives you the longest look at. He lets the mace down at his
-- side and plants his front foot wide; hauls it round behind him, its head grinding sparks along the floor; then winds
-- all the way - back nearly to you, knees deep, eyes still on you - while the floor cracks out to where it will reach
-- (glowing, in phase 2) and he draws a long breath. He stops turning to follow you for that last beat: that's the read.
-- Then everything lets go at once, from the feet up - a big step in, the hips leading the shoulders through - and the
-- mace goes out wide, much further from him than his other blows, right round to his left. opts.followUp (phase 2):
-- the weight carried on round behind his other side into a second, shorter wind and the backhand back across.
local REACH = 24 * K -- studs from where he stands that the sweep's cracks run out to (the swing's tip, plus the step)

-- the mace's head dragged on the floor: sparks and grit where it is, every few frames, for dur
local function scrape(b, dur)
	task.spawn(function()
		local t0, gen = now(), b.gen
		while now() - t0 < dur / SPEED and boss.gen == gen and live(b) do
			local _, tip = maceEnds(b)
			if tip then
				local p = Vector3.new(tip.X, 0.3, tip.Z)
				burst(p, Color3.fromRGB(255, 170, 80), 5, 0.25, 18)
				dustCloud(p, 1.2, 2)
			end
			task.wait(0.06)
		end
	end)
end

-- the floor cracking out round him to the sweep's reach while he loads it; returns what fades it
local function sweepCracks(b, dur)
	local fwd = flat(b.root.CFrame.LookVector)
	local c = b.root.Position + (fwd.Magnitude > 0.1 and fwd.Unit * 4 or Vector3.zero)
	c = Vector3.new(c.X, 0.2, c.Z)
	FxRemote:FireAllClients("Shake", c, 0.25)
	if boss.phase2 then
		return heatCracks(c, REACH, dur)
	end
	local list = crackLines(c, REACH, 9, Color3.fromRGB(26, 24, 22), Enum.Material.Slate, dur)
	return function()
		fadeAway(list, 1.5, 1)
	end
end

-- one swing along a chain of grips: { grip, seconds } each, the body following; hurts for as long as the chain runs
-- but its last link (the follow-through). Returns once the hurting part is over
local function reap(b, chain, bodyMid, bodyEnd, damage, step)
	setTrail(b, true)
	stepInto(b, step * K, 0.32)
	footDust(b, -1, 6)
	bodyPose(b, bodyMid, 0.24)
	playSound(b.root, SOUNDS.Slash, 1, 0.42)
	playSound(b.root, SOUNDS.Lunge, 0.8, 0.45)
	local hurt = 0
	for i = 1, #chain - 1 do
		hurt += chain[i][2]
	end
	task.spawn(function()
		local gen = b.gen
		for i, link in ipairs(chain) do
			if boss.gen ~= gen or not live(b) then
				return
			end
			pose(b, link[1], link[2], i == #chain and Enum.EasingStyle.Quad or Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
			if i == #chain - 1 then
				bodyPose(b, bodyEnd, 0.32)
			end
			task.wait(link[2] / SPEED)
		end
	end)
	maceSweep(b, hurt + 0.04, damage, "Large", {}, 2.8 * K)
	FxRemote:FireAllClients("Shake", b.root.Position, 0.5)
end

local function bossSweep(b, target, opts)
	opts = opts or {}
	local m = tempo()
	stopAndFace(b, target)
	local load = 0.55 * m
	local wind = 0.2 * m + 0.32 * m + 0.6 * m + load
	tell(b, 0.36, wind / SPEED)
	playSound(b.root, SOUNDS.Unsheath, 0.8, 0.38)
	local fade
	local ok = windupBeats(b, target, {
		-- (first the mace let down off his guard, his weight settling, before the foot goes out)
		{ "BSweepGather", "WdSettle", 0.2 * m },
		{ "WReapLow", "WPlant", 0.32 * m, function()
			footDust(b, -1, 5)
		end },
		{ "WReapHaul", "WHaul", 0.6 * m, function()
			scrape(b, 0.6 * m)
			playSound(b.root, SOUNDS.Unsheath, 0.9, 0.28)
		end },
		{ "WReapLoad", "WLoad", load, function()
			fade = sweepCracks(b, load / SPEED)
			playSound(b.root, SOUNDS.Breath, 0.9, 0.5)
		end },
	}, 0.2 * m + 0.32 * m + 0.6 * m) -- (tracks you through the settle, the plant and the haul; the load is committed)
	if fade then
		fade()
	end
	if not ok then
		return
	end
	reap(b, { { "WReapR", 0.09 }, { "WReapFront", 0.12 }, { "WReapL", 0.12 }, { "WReapEnd", 0.24 } }, "WRelease", "WFinish", 30, 8)
	if opts.followUp and bossFree(b) then
		-- the backhand: the mace's weight carried on round behind his left side, his right foot planted, wound the other
		-- way while the eyes flare again; then back across
		local coil = 0.55 * m
		tell(b, 0.4, coil / SPEED)
		scrape(b, 0.3)
		local fade2
		local ok2 = windupBeats(b, target, {
			{ "WBackLoad", "WBackCoil", coil, function()
				footDust(b, 1, 6)
				playSound(b.root, SOUNDS.Breath, 0.8, 0.6)
				fade2 = sweepCracks(b, coil / SPEED)
			end },
		}, coil * 0.6)
		if fade2 then
			fade2()
		end
		if not ok2 then
			return
		end
		reap(b, { { "WReapL", 0.1 }, { "WReapFront", 0.12 }, { "WReapR", 0.12 }, { "WBackEnd", 0.24 } }, "WBackThrough", "WBackFinish", 28, 6)
	end
	bodyPose(b, "Recover", 0.6) -- (bent over, the mace's weight still pulling him round: the punish window)
	if waitLive(b, opts.recover or 0.95 * m) and not opts.recover then
		bossIdleArm(b)
	end
end

-- Stomp: lifts a leg high, then brings it down.
local function bossStomp(b)
	local m = tempo()
	stopAndFace(b, nil)
	tell(b, 0.45)
	-- settles, rocks his weight over onto the planted leg, the knee comes up halfway, then all the way
	if not windupBeats(b, nil, {
		{ "BHeft", "WdSettle", 0.2 * m },
		{ "BHeft", "BStompGather", 0.28 * m },
		{ "Mid", "WdKnee", 0.25 * m },
		{ "Mid", "StompLift", 0.32 * m },
	}, 0) then
		return
	end
	b.model:SetAttribute("Airborne", true) -- (the boss footing in Core lets him leave the floor)
	task.delay(0.45, function()
		b.model:SetAttribute("Airborne", nil)
	end)
	b.root.AssemblyLinearVelocity = Vector3.new(0, 30 * K, 0)
	bodyPose(b, "Strike", 0.12)
	if not waitLive(b, 0.32) then
		return
	end
	local ground = Vector3.new(b.root.Position.X, 0.2, b.root.Position.Z) + flat(b.root.CFrame.LookVector) * 2 * K
	shockwave(ground, 12 * K)
	playSound(b.root, SOUNDS.Impact, 1, 0.45)
	FxRemote:FireAllClients("Shake", ground, 1)
	hitOnce(playersInRadius(ground, 9.5 * K, 14), {}, 26, ground, "Medium")
	if waitLive(b, 0.8 * m) then
		bossIdleArm(b)
	end
end

-- Shoulder charge: drops low, scrapes a foot twice, then barrels forward.
-- Slamming into a wall or pillar stuns it.
local chargeParams = RaycastParams.new()
chargeParams.FilterType = Enum.RaycastFilterType.Exclude

local CHARGE_TOP = 30 -- studs/s flat out (a sprinting player makes 19, a roll 26)
local CHARGE_ACCEL = 46 -- studs/s per second: most of a second to get up to speed, so you see it build
local function bossCharge(b, target)
	local tr = target:FindFirstChild("HumanoidRootPart")
	if not tr then
		return
	end
	local m = tempo()
	stopAndFace(b, target)
	tell(b, 0.3)
	local function paw()
		footDust(b, 1, 6)
		playSound(b.root, SOUNDS.Impact, 0.4, 0.35)
	end
	-- sinks and squares up, scrapes a foot back, sets again, scrapes it again, then drops his shoulder
	if not windupBeats(b, target, {
		{ "BSweepGather", "BChargeSet", 0.25 * m },
		{ "BSweepGather", "WdPaw", 0.22 * m, paw },
		{ "BSweepGather", "BChargeSet", 0.18 * m },
		{ "BSweepGather", "WdPaw", 0.2 * m, paw },
		{ "BSweepBack", "Charge", 0.3 * m },
	}, 0.95 * m) then
		return
	end
	local root, hum = b.root, b.hum
	local dir = flat(root.CFrame.LookVector).Unit
	local dist = math.clamp(flat(tr.Position - root.Position).Magnitude + 8 * K, 10, 36)
	local ignore = { EnemiesFolder, Map.Bars }
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl.Character then
			table.insert(ignore, pl.Character)
		end
	end
	chargeParams.FilterDescendantsInstances = ignore
	-- He runs it on his own legs (the humanoid's walk, so the puppeteer strides him), building speed step by step
	-- rather than being slid across the floor; a wall or pillar just ahead stops him dead.
	local start = root.Position
	local speed, seen, nextDust, hitWall = walkSpeed() * 0.5, {}, 0, false
	local t0, last = now(), now()
	while live(b) do
		local t = now()
		speed = math.min(speed + CHARGE_ACCEL * (t - last), CHARGE_TOP)
		last = t
		hum.WalkSpeed = speed
		hum:MoveTo(root.Position + dir * 12)
		local pos = root.Position
		for _, pl in ipairs(playersInRadius(pos, 5.5 * K, 12)) do
			if not seen[pl] and damagePlayer(pl, bossDmg(32), pos - dir * 3, "Large") then
				seen[pl] = true
			end
		end
		if t > nextDust then
			nextDust = t + 0.12
			dustCloud(Vector3.new(pos.X, 0.6, pos.Z), 1.2, 3)
		end
		if workspace:Raycast(pos, dir * (3 * K + speed * 0.1), chargeParams) then
			hitWall = true
			break
		end
		-- (the time limit: something soft in his way he can't push through)
		if flat(pos - start).Magnitude >= dist or t - t0 > dist / CHARGE_TOP * 1.6 + 0.8 then
			break
		end
		RunService.Heartbeat:Wait()
	end
	if not live(b) then
		return
	end
	if hitWall then
		-- rammed the wall: stunned, wide open
		hum.WalkSpeed = walkSpeed()
		hum:MoveTo(root.Position)
		local wallPoint = Vector3.new(root.Position.X, 0.2, root.Position.Z) + dir * 3 * K
		shockwave(wallPoint, 7 * K)
		playSound(root, SOUNDS.Impact, 1, 0.4)
		FxRemote:FireAllClients("Shake", root.Position, 1.2)
		boss.staggerUntil = now() + 1.6
		boss.idleTok = nil
		pose(b, "Flinch", 0.15)
		bodyPose(b, "Stagger", 0.15)
		task.delay(1.6, function()
			if live(b) then
				bossIdleArm(b)
			end
		end)
		return
	end
	-- skids out of it: leaning back against his own weight, the front foot braced, sliding to a stop
	bodyPose(b, "WdSkid", 0.18)
	local skid0, top = now(), speed
	while live(b) and now() - skid0 < 0.4 do
		local f = (now() - skid0) / 0.4
		hum.WalkSpeed = math.max(top * (1 - f), 0.1)
		hum:MoveTo(root.Position + dir * 6)
		if now() > nextDust then
			nextDust = now() + 0.08
			footDust(b, 1, 4)
		end
		RunService.Heartbeat:Wait()
	end
	if not live(b) then
		return
	end
	hum.WalkSpeed = walkSpeed()
	hum:MoveTo(root.Position)
	bodyPose(b, "Recover", 0.35) -- winded
	if waitLive(b, 0.9 * m) then
		bossIdleArm(b)
	end
end

-- Shockline: mace into the floor; the stone heaves and erupts along a line
-- toward you (three lines in a fan in phase 2).
local function bossShockline(b, target)
	local tr = target:FindFirstChild("HumanoidRootPart")
	if not tr then
		return
	end
	local m = tempo()
	stopAndFace(b, target)
	-- The line's direction is committed the moment his body starts the windup:
	-- he no longer turns to follow you, and the fissures run where he faced.
	local aim = flat(b.root.CFrame.LookVector)
	aim = aim.Magnitude > 0.1 and aim.Unit or Vector3.new(0, 0, 1)
	tell(b, 0.28)
	playSound(b.root, SOUNDS.Unsheath, 0.9, 0.38)
	-- heft, sink, lift it high on his toes, then reared right back, head thrown up
	if not windupBeats(b, nil, {
		{ "BHeft", "WdShoulder", 0.25 * m },
		{ "BHeft", "BGather", 0.2 * m },
		{ "Raise", "WdRise", 0.25 * m },
		{ "Raise", "Roar", 0.3 * m },
	}, 0) then
		return
	end
	setTrail(b, true)
	stepInto(b, 3 * K, 0.2)
	pose(b, "Mid", 0.06, Enum.EasingStyle.Linear)
	task.delay(0.06, function()
		pose(b, "Strike", 0.08)
		bodyPose(b, "BSlamDrive", 0.12)
	end)
	task.wait(0.13 / SPEED)
	if not live(b) then
		return
	end
	local _, tip = maceEnds(b)
	local origin = tip or (b.root.Position + flat(b.root.CFrame.LookVector).Unit * 15 * K)
	origin = Vector3.new(origin.X, 0.2, origin.Z)
	shockwave(origin, 6)
	playSound(b.root, SOUNDS.Impact, 1, 0.55)
	FxRemote:FireAllClients("Shake", origin, 0.8)
	local fiery = boss.phase2
	local spread = fiery and { -0.38, 0, 0.38 } or { 0 }
	for _, ang in ipairs(spread) do
		local d = CFrame.Angles(0, ang, 0):VectorToWorldSpace(aim)
		for k = 1, 7 do
			local pos = origin + d * (k * 4.6)
			if not inArena(pos) then
				break
			end
			task.delay(k * 0.13, function()
				if boss.gen ~= b.gen then
					return
				end
				groundHeave(pos, 3.4, 0.45)
				task.delay(0.45, function()
					if boss.gen == b.gen and boss.state == "fight" then
						eruption(pos, 3.4, 22, "Medium", fiery)
					end
				end)
			end)
		end
	end
	bodyPose(b, "Recover", 0.5)
	if waitLive(b, 1.1 * m) then
		bossIdleArm(b)
	end
end

-- Phase 2 gap closer: sinks into a deep crouch, then leaps onto where you stood.
local function bossLeap(b, target)
	local tr = target:FindFirstChild("HumanoidRootPart")
	if not tr then
		return
	end
	stopAndFace(b, target)
	tell(b, 0.3)
	-- settles, draws himself up to fix where you are (chin up, mace raised), then sinks deep into his legs
	if not windupBeats(b, target, {
		{ "BHeft", "WdSettle", 0.25 },
		{ "Raise", "WdRise", 0.3 },
		{ "Raise", "Crouch", 0.45 },
	}, 0.85) then
		return
	end
	-- He's a man, not a catapult: the leap reaches only so far (it closes a gap, it doesn't cross the room),
	-- and the further it goes, the longer and higher he hangs in the air.
	local LEAP_MAX = 26
	local want = tr.Parent and tr.Position or b.root.Position
	local off = flat(want - b.root.Position)
	if off.Magnitude > LEAP_MAX then
		off = off.Unit * LEAP_MAX
	end
	local landing = b.root.Position + off
	landing = Vector3.new(math.clamp(landing.X, -38, 38), 0, math.clamp(landing.Z, 222, 286))
	footDust(b, 1, 8)
	footDust(b, -1, 8)
	setTrail(b, true)
	pose(b, "Strike", 0.8)
	bodyPose(b, "Air", 0.25)
	leapTo(b, landing, 0.7 + off.Magnitude / 40, 38)
	if not live(b) then
		return
	end
	bodyPose(b, "Strike", 0.06)
	-- (no fire patch on landing: it burned the spot under him right in the punish window)
	b.root.Anchored = false
	snapToGround(b)
	pcall(function()
		b.root:SetNetworkOwner(nil)
	end)
	task.delay(0.25, function()
		if live(b) then
			bodyPose(b, "Recover", 0.4)
		end
	end)
	if waitLive(b, 1.3) then -- landing recovery: punish window
		bossIdleArm(b)
	end
end

-- The delayed blast: he kneels and plants the mace, the floor around him gives way
-- outward to the blast's edge, and the edge itself heaves and spits pebbles - then it
-- all goes off. Run out, or roll as it blows.
--   phase 1: plain stone - dark cracks spreading, dust shaking off the floor, a burst
--            of dust and rubble (radius 15)
--   phase 2: fire - fissures glowing hotter and hotter, the stone blackening, flames
--            gathering on him, a ring of fire (radius 18: 20% wider)
local NOVA_WINDUP = 2.0 / SPEED -- (was 1.7: a beat longer to read it and get clear)
local function bossNova(b)
	local fiery = boss.phase2
	local radius = fiery and 18 or 15
	stopAndFace(b, nil)
	tell(b, 0.25)
	-- lets the mace down and sags over it before he goes to one knee
	draw(b, "BSweepGather", "WdSettle", 0.3)
	if not windupTrack(b, 0.3, 0, nil) then
		return
	end
	draw(b, "Idle", "Kneel", 0.6)
	playSound(b.root, SOUNDS.Groan, 1, 0.25)
	local ground = Vector3.new(b.root.Position.X, 0.2, b.root.Position.Z)
	local cool, unscorch, gather
	if fiery then
		cool = heatCracks(ground, radius, NOVA_WINDUP)
		unscorch = scorchSpread(ground, radius, NOVA_WINDUP)
		gather = Instance.new("Fire")
		gather.Size = 4
		gather.Heat = 4
		gather.Color = Color3.fromRGB(255, 120, 40)
		gather.SecondaryColor = Color3.fromRGB(120, 30, 5)
		gather.Parent = b.root
		TweenService:Create(gather, TweenInfo.new(NOVA_WINDUP), { Size = 18, Heat = 18 }):Play()
		Debris:AddItem(gather, NOVA_WINDUP + 0.3)
	else
		-- no fire: the stone splits in dark cracks that spread out to the edge, and dust
		-- shakes up off the floor harder and harder
		local cracks = crackLines(Vector3.new(ground.X, ground.Y + 0.04, ground.Z), radius, 10, Color3.fromRGB(24, 22, 20), Enum.Material.Slate, NOVA_WINDUP * 0.7)
		cool = function()
			fadeAway(cracks, 3, 1.5)
		end
		unscorch = function() end
		task.spawn(function()
			for i = 1, 4 do
				if boss.gen ~= b.gen then
					return
				end
				dustCloud(ground + Vector3.new(0, 0.4, 0), radius * (0.25 + i * 0.1), 3 + i)
				task.wait(NOVA_WINDUP / 4)
			end
		end)
	end
	for i = 1, 9 do
		local a = i / 9 * math.pi * 2
		local pos = ground + Vector3.new(math.cos(a), 0, math.sin(a)) * radius * 0.92
		if inArena(pos) then
			groundHeave(pos, 2.6, NOVA_WINDUP)
		end
	end
	local ok = windupTrack(b, NOVA_WINDUP * SPEED, 0, nil) -- windupTrack rescales; the fx above already use the sped-up time
	if gather then
		gather:Destroy()
	end
	cool()
	unscorch()
	if not ok then
		return -- staggered out of it
	end
	bodyPose(b, "Roar", 0.08)
	shockwave(ground, radius)
	for i = 1, 10 do
		local a = i / 10 * math.pi * 2
		local p = ground + Vector3.new(math.cos(a) * radius * 0.6, 2, math.sin(a) * radius * 0.6)
		if fiery then
			burst(p, Color3.fromRGB(255, 120, 40), 18, 1.2, 18)
		else
			burst(p, Color3.fromRGB(96, 90, 82), 16, 1.1, 14)
		end
	end
	if not fiery then
		debrisChunks(ground + Vector3.new(0, 1, 0), 10, 28)
	end
	playSound(b.root, SOUNDS.Impact, 1, 0.35)
	FxRemote:FireAllClients("Shake", ground, 1.5)
	hitOnce(playersInRadius(ground, radius, 14), {}, 40, ground, "Knockdown")
	task.delay(0.4, function()
		if live(b) then
			bodyPose(b, "Recover", 0.5)
		end
	end)
	if waitLive(b, 1.6) then -- spent: big punish window
		bossIdleArm(b)
	end
end

-- Phase 2: slam -> sweep -> backhand, no breathing room until the end.
local function bossString(b, target)
	bossSlam(b, target, { recover = 0.25 })
	if not bossFree(b) then
		return
	end
	bossSweep(b, target, { followUp = true })
end

local function bossPhase2(b)
	boss.phase2 = true
	ReplicatedStorage:SetAttribute("Music", "boss2")
	stopAndFace(b, nil)
	draw(b, "Raise", "Roar", 0.6)
	playSound(b.root, SOUNDS.Groan, 1, 0.28)
	FxRemote:FireAllClients("Shake", b.root.Position, 0.8)
	local weapon = b.model:FindFirstChild("Weapon")
	local head = weapon and weapon:FindFirstChild("Head")
	if head then
		local f = Instance.new("Fire")
		f.Size = 10
		f.Heat = 12
		f.Color = Color3.fromRGB(255, 100, 30)
		f.SecondaryColor = Color3.fromRGB(90, 20, 5)
		f.Parent = head
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(255, 120, 50)
		l.Range = 22
		l.Brightness = 2
		l.Parent = head
	end
	for _, d in ipairs(b.model:GetChildren()) do
		if d.Name == "Eye" and d:IsA("BasePart") then
			d.Color = Color3.fromRGB(255, 60, 20)
		end
	end
	b.hum.WalkSpeed = walkSpeed()
	-- the room answers his roar: the floor heaves, then bursts in a ring around him
	local center = Vector3.new(b.root.Position.X, 0.2, b.root.Position.Z)
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		local pos = center + Vector3.new(math.cos(a), 0, math.sin(a)) * 13
		if inArena(pos) then
			groundHeave(pos, 3.4, 1.2)
			local unscorch = scorchSpread(pos, 3.4, 1.2)
			task.delay(1.2, function()
				unscorch()
				if boss.gen == b.gen and boss.state == "fight" then
					eruption(pos, 3.4, 18, "Medium", true)
				end
			end)
		end
	end
	if waitLive(b, 1.6) then
		bossIdleArm(b)
	end
end

---------------------------------------------------------------------------
-- boss brain
---------------------------------------------------------------------------
-- min/max = distance band (studs). behind = good answer to you being behind it.
-- fast = used to punish you drinking a flask.
local BOSS_MOVES = {
	-- (melee bands are in K: they shrink with his reach)
	{ name = "Slam", min = 6 * K, max = 17 * K, weight = 3, cd = 0, fast = false, fn = function(b, t) bossSlam(b, t, { delayed = math.random() < (boss.phase2 and 0.5 or 0.3) }) end },
	{ name = "Sweep", min = 5 * K, max = 21 * K, weight = 3, cd = 0, fast = true, fn = function(b, t) bossSweep(b, t, { followUp = boss.phase2 and math.random() < 0.6 }) end }, -- (the backhand: phase 2 only)
	{ name = "Stomp", min = 0, max = 9 * K, weight = 2, cd = 4, behind = true, fn = function(b) bossStomp(b) end },
	{ name = "Charge", min = 14 * K, max = 36, weight = 3, cd = 6, fast = true, fn = bossCharge },
	{ name = "Shockline", min = 12, max = 50, weight = 2, cd = 7, fn = bossShockline },
	{ name = "Leap", min = 18, max = 70, weight = 3, cd = 9, phase2 = true, fn = bossLeap },
	{ name = "Nova", min = 0, max = 12, weight = 2, cd = 12, behind = true, fn = function(b) bossNova(b) end }, -- (both phases: fire only in phase 2)
	{ name = "String", min = 6 * K, max = 15 * K, weight = 2, cd = 8, phase2 = true, fn = bossString },
}

local function pickMove(dist, behind, healing)
	local list, total = {}, 0
	local t = now()
	for _, mv in ipairs(BOSS_MOVES) do
		if (not mv.phase2 or boss.phase2) and dist >= mv.min and dist <= mv.max and t >= (boss.cd[mv.name] or 0) then
			local w = mv.weight
			if behind then
				w *= mv.behind and 4 or 0.3
			end
			if healing and mv.fast then
				w *= 4
			end
			if mv.name == boss.lastMove then
				w *= 0.25 -- avoid repeating itself
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

local function bossTarget(b)
	local best, bestD, bestPl
	for _, pl in ipairs(Players:GetPlayers()) do
		local char, _, hrp = aliveChar(pl)
		if char and hrp.Position.Z > 214 then
			local d = flat(hrp.Position - b.root.Position).Magnitude
			if not bestD or d < bestD then
				best, bestD, bestPl = char, d, pl
			end
		end
	end
	return best, bestPl
end

-- between attacks it circles you, always facing you
local function stalk(b, tr)
	local rel = flat(b.root.Position - tr.Position)
	if rel.Magnitude < 0.1 then
		return
	end
	local keep = math.clamp(rel.Magnitude, 9 * K, 16 * K)
	local around = CFrame.Angles(0, boss.stalkSide * 0.55, 0):VectorToWorldSpace(rel.Unit) * keep
	b.hum.WalkSpeed = walkSpeed() * 0.7 -- circles with a heavier, slower step than when he closes in
	b.hum:MoveTo(tr.Position + around)
	boss.faceAt = tr
end

bossAI = function(b)
	boss.cd = boss.cd or {}
	boss.stalkUntil = 0
	boss.stalkSide = 1
	-- Between moves he turns to face you every frame (the brain only decides ten times a
	-- second, which turned him in visible steps). Moves do their own turning: faceAt = nil.
	boss.faceAt = nil
	local turner = RunService.Heartbeat:Connect(function(dt)
		local tr = boss.faceAt
		if tr and tr.Parent and live(b) and now() >= (boss.staggerUntil or 0) and not b.root.Anchored then
			turnTowards(b.root, tr.Position, turnRate() * dt)
		end
	end)
	while live(b) do
		task.wait(0.1)
		if not live(b) then
			break
		end
		if now() < (boss.staggerUntil or 0) then
			continue
		end
		b.hum.AutoRotate = false
		local target, targetPlayer = bossTarget(b)
		if not target then
			b.hum:MoveTo(b.root.Position)
			continue
		end
		if not boss.phase2 and b.hum.Health <= b.hum.MaxHealth * 0.7 then
			bossPhase2(b)
			boss.stalkUntil = now() + 0.3
			continue
		end
		local tr = target:FindFirstChild("HumanoidRootPart")
		if not tr then
			continue
		end
		local rel = flat(tr.Position - b.root.Position)
		local dist = rel.Magnitude
		local facing = dist > 0.1 and flat(b.root.CFrame.LookVector).Unit:Dot(rel.Unit) or 1
		local behind = facing < -0.15
		local st = states[targetPlayer]
		local healing = st and st.healing

		-- breathing room after an attack (cut short if you heal or get behind it)
		if now() < boss.stalkUntil and not healing and not behind then
			stalk(b, tr)
			continue
		end

		local mv = pickMove(dist, behind, healing)
		if mv then
			boss.faceAt = nil
			b.hum.WalkSpeed = walkSpeed()
			boss.lastMove = mv.name
			boss.cd[mv.name] = now() + mv.cd
			local ok, err = pcall(mv.fn, b, target)
			if not ok then
				warn("[DGUS] boss move " .. mv.name .. " error: " .. tostring(err))
			end
			if Config.Debug then
				print("[Boss] " .. mv.name)
			end
			boss.stalkSide = math.random() < 0.5 and -1 or 1
			boss.stalkUntil = now() + (boss.phase2 and rand(0.11, 0.45) or rand(0.26, 0.83)) + (Config.Boss.IdleExtra or 0) -- (25% shorter than it was)
		elseif dist < 7 * K then
			-- you're hugging it and its close-range tools are on cooldown: back off to make room
			b.hum.WalkSpeed = walkSpeed() * 0.8
			b.hum:MoveTo(b.root.Position - rel.Unit * 8 * K)
			boss.faceAt = tr
		else
			-- nothing in range: close in, turning as it walks
			b.hum.WalkSpeed = walkSpeed()
			b.hum:MoveTo(tr.Position)
			boss.faceAt = tr
		end
	end
	boss.faceAt = nil
	turner:Disconnect()
end

local function onBossDied(b)
	if boss.gen ~= b.gen or boss.state == "dead" then
		return
	end
	boss.state = "dead"
	ReplicatedStorage:SetAttribute("BossActive", false)
	ReplicatedStorage:SetAttribute("Music", "victory")
	FxRemote:FireAllClients("Banner", "WARDEN FELLED", "Victory")
	dropSplinter(b.root.Position, b.model)
	playSound(b.root, SOUNDS.Groan, 1, 0.22)
	for _, d in ipairs(b.model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	task.spawn(function()
		for _ = 1, 6 do
			if b.root.Parent then
				burst(b.root.Position + Vector3.new(math.random(-4, 4), math.random(-4, 6), math.random(-4, 4)), Color3.fromRGB(70, 66, 60), 40, 1, 10)
			end
			task.wait(0.35)
		end
		for _, d in ipairs(b.model:GetDescendants()) do
			if d:IsA("BasePart") then
				TweenService:Create(d, TweenInfo.new(2), { Transparency = 1 }):Play()
			end
		end
		task.wait(2.2)
		b.model:Destroy()
	end)
	-- the fog lifts and the way onward opens
	TweenService:Create(Map.Fog, TweenInfo.new(2), { Transparency = 1 }):Play()
	Map.Fog.CanCollide = false
	Map.FogPrompt.Enabled = false
	local pe = Map.Fog:FindFirstChildOfClass("ParticleEmitter")
	if pe then
		pe.Enabled = false
	end
	TweenService:Create(Map.ExitDoor, TweenInfo.new(4, Enum.EasingStyle.Sine), { CFrame = Map.ExitDoor.CFrame + Vector3.new(0, 15.5, 0) }):Play()
	local glow = Map.ExitLight:FindFirstChildOfClass("PointLight")
	if glow then
		glow.Enabled = true
	end
	-- the veil of light behind the door thins away: the Ruined Township lies beyond
	task.delay(3.5, function()
		TweenService:Create(Map.ExitLight, TweenInfo.new(2.5), { Transparency = 1 }):Play()
		Map.ExitLight.CanCollide = false
		Map.ExitLight.CanQuery = false
	end)
end

local function spawnBoss()
	boss.gen += 1
	local model, hum, weld = makeRig("Warden", "Warden", BOSS_SCALE, "Mace")
	if not model then
		return
	end
	hum.MaxHealth = Config.Boss.HP
	hum.Health = Config.Boss.HP
	hum.WalkSpeed = walkSpeed()
	hum.BreakJointsOnDeath = false
	model:SetAttribute("Radius", 3.6 * K)
	model:SetAttribute("Boss", true)
	local root = model:FindFirstChild("HumanoidRootPart")
	model:PivotTo(Map.BossHome + Vector3.new(0, 3 * BOSS_SCALE - 3, 0))
	-- Pinned (anchored) at his exact standing height while dormant: left to physics, a rig
	-- that isn't moving slowly sinks, and every correction of that jittered on the client.
	-- (The intro's leap carries him from here and lets him go when he lands.)
	root.Anchored = true
	root.AssemblyLinearVelocity = Vector3.zero
	hum.AutoRotate = false
	hum:MoveTo(root.Position)
	pcall(function()
		root:SetNetworkOwner(nil)
		hum:ChangeState(Enum.HumanoidStateType.Running) -- standing, as after the intro leap (snapToGround)
	end)
	local shoulder = findShoulder(model)
	boss.model, boss.hum, boss.root, boss.weld = model, hum, root, weld
	boss.shoulder, boss.c0 = shoulder, shoulder and shoulder.C0
	boss.phase2 = false
	boss.leapReady = 0
	boss.stompReady = 0
	boss.staggerUntil = 0
	boss.poise = nil
	boss.cd = {}
	boss.lastMove = nil
	boss.stalkUntil = 0
	boss.stalkSide = 1
	boss.state = "dormant"
	root.CollisionGroup = "EnemyRoot"
	local b = snapBoss()
	boss.current = b
	ReplicatedStorage:SetAttribute("BossMaxHP", hum.MaxHealth)
	ReplicatedStorage:SetAttribute("BossHP", hum.Health)
	hum.HealthChanged:Connect(function(h)
		if boss.gen == b.gen then
			ReplicatedStorage:SetAttribute("BossHP", math.max(0, h))
		end
	end)
	hum.Died:Connect(function()
		onBossDied(b)
	end)
end

local function startBoss()
	if boss.state ~= "dormant" then
		return
	end
	boss.state = "intro"
	local b = snapBoss()
	ReplicatedStorage:SetAttribute("BossName", Config.Boss.Name)
	ReplicatedStorage:SetAttribute("BossMaxHP", b.hum.MaxHealth) -- (Oculast shares this bar)
	ReplicatedStorage:SetAttribute("BossHP", b.hum.Health)
	ReplicatedStorage:SetAttribute("BossActive", true)
	ReplicatedStorage:SetAttribute("Music", "boss")
	task.spawn(function()
		-- wakes, rears up and roars, then drops into a crouch and leaps down to you
		playSound(b.root, SOUNDS.Groan, 1, 0.3)
		pose(b, "Raise", 0.6)
		bodyPose(b, "Roar", 0.6)
		task.wait(1.2)
		if boss.gen ~= b.gen or boss.state ~= "intro" then
			return
		end
		bodyPose(b, "Crouch", 0.35)
		task.wait(0.4)
		footDust(b, 1, 8)
		footDust(b, -1, 8)
		bodyPose(b, "Air", 0.15)
		leapTo(b, Vector3.new(0, 0, 262), 1.0, nil)
		if boss.gen ~= b.gen or boss.state ~= "intro" then
			return
		end
		bodyPose(b, "Strike", 0.08)
		b.root.Anchored = false
		snapToGround(b)
		pcall(function()
			b.root:SetNetworkOwner(nil)
		end)
		bossIdleArm(b)
		boss.state = "fight"
		task.wait(0.6)
		bossAI(b)
	end)
end

local function resetBoss()
	if boss.state == "dead" or boss.state == "dormant" then
		return
	end
	if boss.model then
		boss.model:Destroy()
	end
	ReplicatedStorage:SetAttribute("BossActive", false)
	ReplicatedStorage:SetAttribute("Music", "none")
	spawnBoss()
end

local function anyoneAliveInArena()
	for _, pl in ipairs(Players:GetPlayers()) do
		local char, _, hrp = aliveChar(pl)
		if char and hrp.Position.Z > 214 then
			return true
		end
	end
	return false
end

function M.init(core)
	Map, EnemiesFolder, FxRemote, states, now, flat, rand, turnTowards, SOUNDS, playSound, burst, fxAnchor, dustCloud, crackLines, fadeAway, shockwave, groundHeave, debrisChunks, SMOKE, SPARK, pose, bodyPose, setTrail, makeRig, findShoulder, aliveChar, damagePlayer, playersInRadius = core.Map, core.EnemiesFolder, core.FxRemote, core.states, core.now, core.flat, core.rand, core.turnTowards, core.SOUNDS, core.playSound, core.burst, core.fxAnchor, core.dustCloud, core.crackLines, core.fadeAway, core.shockwave, core.groundHeave, core.debrisChunks, core.SMOKE, core.SPARK, core.pose, core.bodyPose, core.setTrail, core.makeRig, core.findShoulder, core.aliveChar, core.damagePlayer, core.playersInRadius
	local rawPose, rawBodyPose = pose, bodyPose
	pose = function(b, name, t, ...)
		return rawPose(b, name, t / SPEED, ...)
	end
	bodyPose = function(b, name, t, ...)
		return rawBodyPose(b, name, (t or 0.2) / SPEED, ...)
	end
	dropSplinter = core.dropSplinter
	-- hits on the Warden: his poise breaks into a big stagger (cancels a wind-up)
	core.registerTarget(function(model)
		if boss.model ~= model or not boss.model then
			return nil
		end
		return {
			owner = boss,
			actor = boss.current,
			maxPoise = Config.Boss.Poise,
			freeze = false,
			onBreak = function(player, t)
				if boss.state ~= "fight" then
					return
				end
				local actor = boss.current
				local root = boss.root
				boss.staggerUntil = t + Config.Boss.Stagger
				boss.idleTok = nil -- (a pending return to stance mustn't cut the stagger short)
				setTrail(actor, false)
				pose(actor, "Flinch", 0.15)
				bodyPose(actor, "Stagger", 0.12) -- reels back, wide open
				boss.hum:MoveTo(root.Position)
				playSound(root, SOUNDS.Groan, 0.9, 0.5)
				FxRemote:FireAllClients("Shake", root.Position, 0.5)
				local gen = boss.gen
				task.delay(Config.Boss.Stagger, function()
					if boss.gen == gen and boss.state == "fight" then
						pose(actor, "Idle", 0.3)
					end
				end)
			end,
		}
	end)
end

-- THE WARDEN that fights is ReplicatedStorage/WardenFight's (Config.Boss.Trial: the Bell Warden). Everything that asks for
-- the Warden gets that one. This old one no longer spawns: only its Grips and poses are still in use (the Castellan
-- swings through them).
local Fight = require(ReplicatedStorage:WaitForChild("WardenFight"))
M.spawn, M.start, M.reset, M.state, M.isDead, M.model, M.anyoneInArena = Fight.spawn, Fight.start, Fight.reset, Fight.state, Fight.isDead, Fight.model, Fight.anyoneInArena

return M
