--!nonstrict
-- THE SILVER KNIGHT (Caelen, Knight of the Iron Vow): the last of the knights who came to the
-- Crowned Colosseum to fight, and the one who never lost. Tall and lean in pale silver fluted
-- plate, a narrow crowned helm with a long grey plume, a ragged crimson cape to his heels, a
-- greatsword half again as long as he is tall in one hand, the other folded behind his back -
-- he doesn't need it. The sword is too heavy to swing with an arm: every cut is heaved round
-- with his whole body, coiled long and plainly first (hips, waist, knees, toes, wrist), and its
-- weight carries him through after. Between cuts he fights like an acrobat, never still: he
-- sinks onto his haunches and springs at you from across the sand, passing straight through
-- where you stood; flips end over end into a slam; heaves; spins; hops back and lunges.
-- Phase 2 at half health: he plants his sword, declares you worthy, and his free arm comes out
-- from behind his back and draws a second, identical sword out of the sand beside him (the
-- first time, a cutscene); he roars, embers pour off him, and he comes faster, a sword in each
-- hand, with two new moves: the whirlwind and the crossing cut. From range he throws the
-- sword spinning across the arena after you, leaps after it and comes out of the landing in a
-- huge sweep. Tuning: Config.Champion.
-- A spring or a flip is always followed by 1-2 more of either, back to back.
-- The first time, he stands out on the sand with his back to you; when someone walks out onto
-- it the camera is taken for his entrance (SoulsClient's "Cutscene"). After that he waits on
-- the colonnade's parapet (Map.Champion.Perch) and jumps down to meet each new attempt.
--
-- His cape (6 segments) and plume (3) hang off anchors tagged "ClothChain": every client
-- swings them as cloth (Carrier.cloth). His rig has wrists and toes besides (Proportions.limbs,
-- posed by lwr/rwr/toe): he cocks his wrists and rises onto his toes into every tell and cut.
--
-- EVERYTHING ABOUT THIS CHARACTER IS IN THIS ONE FILE (same layout as Castellan.lua):
--   M.Proportions / M.Poses   body shape and its full-body poses
--   M.Colors / M.Look         how the rig is dressed
--   M.Weapons / M.Grips       the greatsword, and the grip poses its cuts tween between
--   M.init(Core) and below    behaviour (server only)
local CollectionService = game:GetService("CollectionService")

local M = {}
M.Kind = "Champion"
M.Proportions = { girth = 0.95, arm = 1.12, hunch = 0.06, limbs = true } -- long-limbed and lean
M.IdlePose = "CHIdle"
M.Poses = {
	-- on guard: low and loose, weight on the back foot, sword hand low, the free hand out
	CHIdle = { drop = 0.4, lean = 0.2, twist = -0.18, head = -0.05, footR = -0.5, footL = 0.6, spread = 0.22, breathe = 2.2, la1 = 0.35, la3 = -0.45, lel = 0.6, freeL = 0.2, rwr = -0.15, toe = 0.1 },
	-- on the parapet, waiting: standing tall and proud, chin up, his hand on the planted sword's pommel
	CProud = { drop = 0, lean = -0.12, head = -0.22, footR = 0.05, footL = -0.05, spread = 0.14, freeL = 0, breathe = 1.6, rwr = 0.25 },
	-- the turn (his back to you first): the head round over his shoulder to peer at you...
	CPeer = { drop = 0.05, lean = -0.08, head = 0.1, twist = 0.35, look = 1.3, footR = 0.05, footL = -0.05, spread = 0.14, freeL = 0, breathe = 1.4, rwr = 0.25 },
	-- ...the waist pivoting after it, the hips following, the feet still planted...
	CPivot = { drop = 0.25, lean = 0.05, head = 0.15, twist = 0.9, hip = 0.55, look = 1.3, side = 0.06, footR = -0.1, footL = 0.1, spread = 0.18, freeL = 0, breathe = 2, rwr = -0.2, toe = 0.15 },
	-- ...then stepping round under it, left foot then right, the body unwinding as the feet come round
	CStep1 = { drop = 0.3, lean = 0.08, head = 0.18, twist = 0.6, hip = 0.5, look = 0.9, footR = 0, footL = 0.35, spread = 0.18, liftL = 0.45, freeL = 0, breathe = 2, rwr = -0.2, toe = 0.2 },
	CStep2 = { drop = 0.3, lean = 0.1, head = 0.2, twist = 0.45, hip = 0.3, look = 0.6, footR = -0.3, footL = 0.4, spread = 0.2, lift = 0.45, freeL = 0, breathe = 2, rwr = -0.2, toe = 0.15 },
	-- turned on you: sunk a little, chin down, glaring
	CGlare = { drop = 0.3, lean = 0.12, head = 0.22, twist = -0.15, footR = -0.35, footL = 0.4, spread = 0.2, freeL = 0, breathe = 2.6, rwr = -0.2, toe = 0.1 },
	-- THE HEAVE: coiled right round away from you, low, hips and all, the sword dragged out behind
	CHeave = { drop = 1.05, lean = -0.25, twist = -1.15, hip = -0.75, side = -0.18, head = 0.05, footR = -0.95, footL = 0.85, spread = 0.42, freeL = 0, breathe = 4, rwr = -0.9, lwr = -0.6, toe = 0.6 },
	-- ...and carried on through by its weight, over his front foot
	CHeaveEnd = { drop = 0.95, lean = 0.7, twist = 1.1, hip = 0.6, side = 0.15, head = -0.1, footR = 1.1, footL = -0.9, spread = 0.4, freeL = 0, rwr = 0.7, lwr = 0.5, toe = 0.4 },
	-- hoisting it up behind his head: arched back, up on his toes
	CHoist = { drop = 0.6, lean = -0.55, head = -0.35, hip = -0.2, twist = -0.3, footR = -0.8, footL = 0.7, spread = 0.35, freeL = 0, breathe = 5, rwr = -0.8, lwr = -0.5, toe = 0.7 },
	-- ...and the whole of him folded down behind it into the sand
	CSlam = { drop = 1.5, lean = 1.0, head = -0.4, footR = 1.15, footL = -1.0, spread = 0.45, freeL = 0, rwr = 0.5, lwr = 0.6, toe = 0.5 },
	-- down on his haunches, coiled to spring: low, leaning in, the free hand back for balance
	CHaunch = { drop = 1.75, lean = 0.95, head = -0.5, footR = 0.35, footL = -0.95, spread = 0.38, la1 = -0.3, la3 = -0.95, lel = 0.9, freeL = 0, breathe = 4, rwr = -0.7, lwr = -0.9, toe = 0.75 },
	-- in flight: stretched out along the leap
	CLaunch = { drop = 0.15, lean = 0.75, head = -0.35, footR = -0.95, footL = 0.6, spread = 0.1, la1 = -0.9, la3 = -0.6, lel = 0.2, freeL = 0, rwr = 0.35, lwr = 0.6, toe = -0.45 },
	-- tucked for the flip
	CTuck = { drop = 0.6, lean = 0.6, head = 0.3, tuck = 0.95, la1 = 0.4, la3 = -0.6, lel = 1.0, freeL = 0, rwr = -0.5, lwr = 0.8, toe = -0.4 },
	-- landed: skidding low, one knee nearly down, the free hand trailing on the sand
	CLand = { drop = 1.45, lean = 0.75, side = 0.12, head = -0.2, footR = 0.95, footL = -1.15, spread = 0.42, la1 = -0.6, la3 = -1.1, lel = 0.3, freeL = 0, breathe = 4, rwr = 0.45, lwr = -1.1, toe = 0.6 },
	-- the thrust: wound back, then driven through on a long lunge
	CThrustSet = { drop = 0.7, lean = 0.2, twist = -0.65, head = -0.05, footR = -0.75, footL = 0.75, spread = 0.2, la1 = 0.8, la3 = -0.6, lel = 0.6, freeL = 0, rwr = -0.65, lwr = -0.6, toe = 0.55 },
	CThrust = { drop = 0.8, lean = 0.8, twist = 0.45, head = -0.15, footR = 1.15, footL = -1.05, spread = 0.18, la1 = -0.6, la3 = -0.5, lel = 0.2, freeL = 0, rwr = 0.4, lwr = 0.5, toe = 0.35 },
	-- wound right round for the spinning cut
	CSpin = { drop = 0.95, lean = 0.3, twist = -1.4, hip = -0.8, side = -0.15, footR = -0.6, footL = 0.75, spread = 0.38, la1 = 0.7, la3 = -1.1, lel = 0.4, freeL = 0, rwr = -0.75, lwr = -0.7, toe = 0.65 },
	-- THE THROW: hauled back over his shoulder, coiled, the free arm out aiming at you...
	CThrowSet = { drop = 0.7, lean = -0.35, twist = -1.25, hip = -0.6, side = -0.2, head = -0.05, footR = -0.9, footL = 0.8, spread = 0.38, la1 = 1.5, la2 = 0, la3 = -0.25, lel = 0.1, freeL = 0, breathe = 4, rwr = -1.0, lwr = 0.3, toe = 0.55 },
	-- ...and flung, all of him following through after it
	CThrow = { drop = 0.6, lean = 0.75, twist = 1.0, hip = 0.5, head = -0.2, footR = 1.1, footL = -0.95, spread = 0.36, la1 = -0.4, la3 = -0.6, lel = 0.3, freeL = 0, rwr = 0.6, lwr = -0.4, toe = 0.4 },
	-- the roar (his second wind): reared back, arms flung wide
	CRoar = { drop = 0.25, lean = -0.5, head = -0.7, la1 = 2.2, la3 = -1.0, lel = 0.4, footR = 0.5, footL = -0.5, spread = 0.32, freeL = 0, breathe = 5, rwr = -0.5, lwr = -1.0 },
	-- phase 2: kneeling, the free hand reaching down to the hilt rising out of the sand
	CKneelReach = { drop = 1.45, lean = 0.38, head = 0.3, footR = 1.0, footL = -1.3, la1 = -0.6, la3 = -1.1, lel = 0.3, freeL = 0, rwr = 0.25, lwr = -1.1, toe = 0.7 },
	-- the whirlwind's tell: sunk wide and low, both arms flung out, wound back against the spin
	CWhirlSet = { drop = 0.8, lean = 0.1, twist = -0.5, head = 0.05, footR = -0.45, footL = 0.45, spread = 0.48, freeL = 0, breathe = 4, toe = 0.45 },
	-- ...and spinning like a top, upright, chin up
	CWhirl = { drop = 0.5, lean = -0.08, head = -0.12, footR = -0.2, footL = 0.2, spread = 0.42, freeL = 0, toe = 0.3 },
	-- levelling the sword at you
	CPoint = { drop = 0.3, lean = 0.08, twist = 0.35, head = -0.1, footR = -0.55, footL = 0.6, spread = 0.2, la1 = 0.35, la3 = -0.55, lel = 0.6, freeL = 0, rwr = 0.25, lwr = 0.3, toe = 0.2 },
}
local STEEL, STEEL_DK, GOLD, CAPE, PLUME = Color3.fromRGB(190, 194, 202), Color3.fromRGB(138, 142, 152), Color3.fromRGB(176, 140, 66), Color3.fromRGB(112, 22, 22), Color3.fromRGB(176, 172, 164)
M.Colors = { skin = STEEL, torso = STEEL, legs = STEEL_DK, arms = STEEL }

-- an anchor the clients hang a swinging strip of cloth off (Carrier.cloth): its UpVector
-- the way the cloth's top edge runs, its LookVector the side of the body it hangs out on
local function clothAnchor(p, segs, len, width, color, phys)
	p.Transparency = 1
	for k, v in pairs(phys or {}) do -- (Drag / Gravity / Out: Carrier.cloth)
		p:SetAttribute(k, v)
	end
	p:SetAttribute("Segs", segs)
	p:SetAttribute("Len", len)
	p:SetAttribute("Width", width)
	p:SetAttribute("Color", color)
	CollectionService:AddTag(p, "ClothChain")
end

function M.Look(k)
	local deco, parts, V, at, rgb, MAT, D, s = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT, k.D, k.s
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local shin, th = D.shin / s, D.thigh / s
	for _, pn in ipairs({ "RUpperArm", "LUpperArm", "RLowerArm", "LLowerArm", "RHand", "LHand", "RThigh", "LThigh", "RShin", "LShin", "RToe", "LToe", "Chest", "Hips" }) do
		parts[pn].Color = STEEL_DK
		parts[pn].Material = MAT.Metal
	end
	-- fluted cuirass, gilt-edged, a crowned sun on the breast
	deco("Chest", "Breastplate", V(cw * 1.02, ch * 0.82, 0.3), at(0, 0.08, -cd / 2 - 0.1), STEEL, MAT.Metal)
	for i = -2, 2 do
		deco("Chest", "Flute", V(0.08, ch * 0.7, 0.06), at(i * cw * 0.16, 0.05, -cd / 2 - 0.27), STEEL_DK, MAT.Metal)
	end
	deco("Chest", "Sun", V(0.5, 0.5, 0.06), at(0, 0.25, -cd / 2 - 0.3), GOLD, MAT.Metal, Enum.PartType.Ball)
	deco("Chest", "Backplate", V(cw * 1.0, ch * 0.82, 0.24), at(0, 0.08, cd / 2 + 0.08), STEEL, MAT.Metal)
	deco("Chest", "Gorget", V(cw * 0.6, 0.36, cd * 1.15), at(0, ch / 2 - 0.02, 0), STEEL, MAT.Metal)
	deco("Chest", "GorgetTrim", V(cw * 0.64, 0.08, cd * 1.2), at(0, ch / 2 - 0.2, 0), GOLD, MAT.Metal)
	-- belt and a long split skirt of mail and red cloth
	deco("Hips", "Belt", V(hw + 0.16, 0.24, hd + 0.16), at(0, 0.3, 0), rgb(40, 30, 24), MAT.Leather)
	deco("Hips", "Buckle", V(0.32, 0.26, 0.06), at(0, 0.3, -hd / 2 - 0.1), GOLD, MAT.Metal)
	for _, z in ipairs({ -1, 1 }) do
		deco("Hips", "Skirt", V(hw * 0.8, 1.9, 0.08), at(0, -1.0, z * (hd / 2 + 0.12)), CAPE:Lerp(rgb(0, 0, 0), 0.3), MAT.Fabric)
	end
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		-- layered pauldrons swept up into a point, couters, long gauntlets; cuisses, poleyns, greaves
		deco(n .. "UpperArm", "Pauldron", V(aw * 1.9, 0.55, aw * 1.8), at(sx * 0.1, ua / 2 - 0.1, 0) * CFrame.Angles(0, 0, -sx * 0.3), STEEL, MAT.Metal)
		deco(n .. "UpperArm", "PauldronLame", V(aw * 1.7, 0.2, aw * 1.6), at(sx * 0.08, ua / 2 - 0.45, 0) * CFrame.Angles(0, 0, -sx * 0.2), STEEL_DK, MAT.Metal)
		deco(n .. "UpperArm", "PauldronTrim", V(aw * 1.95, 0.08, aw * 1.85), at(sx * 0.1, ua / 2 - 0.36, 0) * CFrame.Angles(0, 0, -sx * 0.3), GOLD, MAT.Metal)
		deco(n .. "LowerArm", "Couter", V(aw * 1.35, 0.38, aw * 1.35), at(0, la / 2 - 0.12, 0), STEEL, MAT.Metal)
		deco(n .. "LowerArm", "Vambrace", V(aw * 1.15, la * 0.6, aw * 1.15), at(0, -0.05, 0), STEEL, MAT.Metal)
		deco(n .. "LowerArm", "Gauntlet", V(aw * 1.25, 0.46, aw * 1.25), at(0, -la / 2 + 0.2, 0), STEEL_DK, MAT.Metal)
		deco(n .. "Thigh", "Cuisse", V(lw * 1.15, th * 0.72, lw * 1.15), at(0, 0.05, 0), STEEL, MAT.Metal)
		deco(n .. "Shin", "Poleyn", V(lw * 1.25, 0.42, lw * 1.3), at(0, shin / 2 - 0.08, -0.05), GOLD, MAT.Metal)
		deco(n .. "Shin", "Greave", V(lw * 1.12, shin * 0.66, lw * 1.12), at(0, -shin * 0.1, 0), STEEL, MAT.Metal)
		deco(n .. "Foot", "Sabaton", V(D.footSize.X / s * 1.1, 0.26, D.footSize.Z / s * 0.95), at(0, 0.06, -0.05), STEEL_DK, MAT.Metal)
		deco(n .. "Toe", "ToeCap", V(D.toeSize.X / s * 1.1, 0.16, D.toeSize.Z / s * 0.9), at(0, 0.03, -0.03), STEEL, MAT.Metal)
		deco(n .. "Hand", "Knuckles", V(D.handSize.X / s * 1.1, 0.14, D.handSize.Z / s * 1.12), at(0, -0.1, 0), STEEL, MAT.Metal)
	end
	-- the helm: tall and narrow, a T of darkness for a face, a thin gold crown round its brow
	parts.Head.Transparency = 1
	deco("Head", "Helm", V(1.15, 1.15, 1.2), at(0, 0.255, 0), STEEL, MAT.Metal)
	-- (its lower edge narrower than the dome: squared notches out of both bottom corners)
	deco("Head", "HelmJaw", V(0.75, 0.35, 1.2), at(0, -0.495, 0), STEEL, MAT.Metal)
	deco("Head", "HelmCrest", V(0.16, 0.5, 1.2), at(0, 0.95, 0), STEEL_DK, MAT.Metal)
	deco("Head", "Slit", V(0.9, 0.09, 0.05), at(0, 0.2, -0.62), rgb(6, 6, 8), MAT.SmoothPlastic)
	deco("Head", "SlitDown", V(0.12, 0.6, 0.05), at(0, -0.12, -0.62), rgb(6, 6, 8), MAT.SmoothPlastic)
	deco("Head", "Crown", V(1.2, 0.14, 1.25), at(0, 0.6, 0), GOLD, MAT.Metal)
	for i = 0, 4 do
		deco("Head", "CrownPoint", V(0.14, 0.32, 0.14), at(0, 0.78, 0) * CFrame.Angles(0, i * math.pi * 2 / 5, 0) * CFrame.new(0, 0, 0.6 * s), GOLD, MAT.Metal)
	end
	-- the cloth: a long cape from under the pauldrons, a plume off the crest (Carrier.cloth)
	clothAnchor(deco("Chest", "CapeAnchor", V(0.2, 0.2, 0.2), at(0, ch / 2 - 0.15, cd / 2 + 0.25) * CFrame.Angles(0, math.pi, 0), CAPE, MAT.SmoothPlastic), 6, 0.95 * s, cw * 1.15 * s, CAPE)
	-- a second layer over it, heavier and slower, a touch wider and longer so the weave overlaps
	clothAnchor(deco("Chest", "CapeAnchor2", V(0.2, 0.2, 0.2), at(0, ch / 2 - 0.2, cd / 2 + 0.3) * CFrame.Angles(0, math.pi, 0), CAPE, MAT.SmoothPlastic), 6, 1.0 * s, cw * 1.2 * s, CAPE:Lerp(rgb(0, 0, 0), 0.25), { Drag = 0.92, Gravity = 1.3, Out = 0.14 })
	-- a short half-width cape off the back of each shoulder, light and quick to flutter
	for _, sx in ipairs({ -1, 1 }) do
		clothAnchor(deco("Chest", "ShoulderCapeAnchor", V(0.2, 0.2, 0.2), at(sx * (cw / 2 + 0.05), ch / 2 - 0.1, cd / 2 + 0.35) * CFrame.Angles(0, math.pi, 0), CAPE, MAT.SmoothPlastic), 5, 0.75 * s, cw * 0.575 * s, CAPE:Lerp(rgb(0, 0, 0), 0.15), { Drag = 0.975, Gravity = 0.8, Out = 0.1 })
	end
	clothAnchor(deco("Head", "PlumeAnchor", V(0.2, 0.2, 0.2), at(0, 1.15, 0.35) * CFrame.Angles(0, math.pi, 0), PLUME, MAT.SmoothPlastic), 3, 0.7 * s, 0.35 * s, PLUME)
end

M.Weapons = {
	-- a huge straight greatsword, half again as long as he is tall: a long wire-wrapped grip,
	-- a disc pommel, a broad crossguard, a slab of a blade near as wide as his forearm is long.
	-- Held a quarter turn round in his fist (gripC1): it's a club as much as a blade, so every
	-- sideways heave lands flat-on
	ChampionBlade = function(w)
		local mk, add = w.mk, w.add
		local steel, dark, gold = Color3.fromRGB(184, 186, 192), Color3.fromRGB(46, 44, 46), Color3.fromRGB(176, 140, 66)
		local handle = mk("Grip", Vector3.new(0.3, 1.7, 0.3), dark, Enum.Material.Leather)
		add(mk("Pommel", Vector3.new(0.6, 0.6, 0.2), gold, Enum.Material.Metal), 0.98)
		add(mk("Guard", Vector3.new(2.9, 0.28, 0.36), gold, Enum.Material.Metal), -0.92)
		add(mk("Blade", Vector3.new(1.3, 7.6, 0.14), steel, Enum.Material.Metal), -4.75)
		add(mk("Fuller", Vector3.new(0.36, 6.6, 0.16), Color3.fromRGB(120, 122, 128), Enum.Material.Metal), -4.45)
		add(mk("Point", Vector3.new(0.92, 0.92, 0.14), steel, Enum.Material.Metal), -8.55, CFrame.Angles(0, 0, math.pi / 4))
		return { handle = handle, bladeLen = 8.6, gripC1 = CFrame.Angles(0, math.pi / 2, 0) }
	end,
}
local R = math.rad
M.Weapons.CaelenBlades = M.Weapons.ChampionBlade -- (the player's pair, Config.Weapons: the same swords at half the size)
M.Grips = {
	-- held low and trailing, its point dragging back along the sand (his guard, and the run-up to a leap)
	GLow = { Vector3.new(1.3, -0.7, 0.4), CFrame.Angles(R(-75), 0, R(8)) },
	-- the heave: dragged far out behind him, point dipping to the sand
	GHeaveBack = { Vector3.new(2.2, 0.2, 1.8), CFrame.Angles(0, R(-75), 0) * CFrame.Angles(0, 0, R(72)) },
	-- ...and flung on round past his left side
	GHeaveEnd = { Vector3.new(-1.6, 0.2, 0.2), CFrame.Angles(0, R(215), 0) * CFrame.Angles(0, 0, R(80)) },
	-- brought down from overhead into the sand before him
	GSlam = { Vector3.new(0.4, -0.2, -2.0), CFrame.Angles(R(72), 0, 0) },
	LGSlam = { Vector3.new(-0.4, -0.2, -2.0), CFrame.Angles(R(72), 0, 0) }, -- (the left sword down beside it, both forward)
	-- reached out ahead, point first (the leap through you, the lunge)
	GThrust = { Vector3.new(0.5, 0.5, -2.1), CFrame.Angles(R(90), 0, 0) },
	GThrustSet = { Vector3.new(1.4, 0.8, 1.2), CFrame.Angles(R(90), R(-15), 0) },
	-- straight up over his head (the flip's slam)
	GHigh = { Vector3.new(0.6, 3.0, 0.2), CFrame.Angles(R(210), 0, 0) },
	-- point driven deep into the sand before him, his hand on the pommel
	GPlant = { Vector3.new(0.4, 1.4, -1.5), CFrame.Angles(R(-8), 0, 0) },
	-- the throw: hauled back high beside his shoulder, point behind him...
	GThrowSet = { Vector3.new(1.8, 2.4, 1.6), CFrame.Angles(0, R(-80), 0) * CFrame.Angles(0, 0, R(95)) },
	-- ...and his arm flung out ahead after it (the sword's gone by then)
	GThrowRelease = { Vector3.new(0.8, 1.4, -2.6), CFrame.Angles(0, R(90), 0) * CFrame.Angles(0, 0, R(90)) },
	-- levelled at you, arm out
	GPoint = { Vector3.new(1.0, 1.3, -2.6), CFrame.Angles(R(92), 0, 0) },
	-- PHASE 2's second sword, in the left hand (poseL): its own grip "L" .. name if it has one,
	-- else the mirror image of the right's
	-- the whirlwind: both arms flung out, the right blade pointing ahead and the left behind,
	-- each dipping a little toward the sand
	GWhirl = { Vector3.new(2.9, 0.5, 0), CFrame.Angles(R(75), 0, 0) },
	LGWhirl = { Vector3.new(-2.9, 0.5, 0), CFrame.Angles(R(-75), 0, 0) },
	-- the roar: flung wide, up and out
	GWide = { Vector3.new(2.6, 1.8, 0.3), CFrame.Angles(0, 0, R(120)) },
	-- crossed before him in an X, hands crossed at the wrist
	GX = { Vector3.new(-0.4, 1.2, -1.8), CFrame.Angles(0, 0, R(150)) },
	-- the crossing cut: both raised high and out to the sides, then brought down across each other
	GCrossSet = { Vector3.new(1.8, 2.8, 0.4), CFrame.Angles(0, 0, R(-30)) * CFrame.Angles(R(210), 0, 0) },
	GCrossEnd = { Vector3.new(-0.8, -0.3, -2.2), CFrame.Angles(0, 0, R(-35)) * CFrame.Angles(R(70), 0, 0) },
}
M.BodyFor = {}

---------------------------------------------------------------------------
-- server: the fight
---------------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local C = Config.Champion
local S = C.Scale
local Core, Map, FxRemote, states, now, flat, rand, turnTowards, SOUNDS, playSound, burst, dustCloud, shockwave, debrisChunks, pose, bodyPose, setTrail, aliveChar, damagePlayer, playersInRadius

local boss: any = { state = "none", gen = 0, phase2 = false, seen = false } -- state: none | dormant | intro | fight | dead
local EASE, INOUT, LINEAR = Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, Enum.EasingStyle.Linear

local function dmg(x)
	return math.max(1, math.floor(x * (C.DamageScale or 1) + 0.5))
end
local function arena()
	return Map.Champion
end
local function inArena(pos) -- out on the sand, inside the colonnade
	local A = arena()
	return flat(pos - A.Centre).Magnitude < A.Radius + 3 and pos.Y > A.Centre.Y - 3 and pos.Y < A.Centre.Y + 20
end
local function live(b)
	return boss.gen == b.gen and boss.state == "fight" and b.hum.Parent ~= nil and b.hum.Health > 0
end
local function free(b)
	return live(b) and now() >= (boss.staggerUntil or 0)
end
local function waitLive(b, d)
	local t0 = now()
	while now() - t0 < d do
		if not live(b) then
			return false
		end
		task.wait()
	end
	return true
end
local function tempo() -- every wait in a move is scaled by this
	return boss.phase2 and 0.8 or 1
end
local function standY()
	return arena().Centre.Y + 3 * S
end
local function perchPos() -- his root on the parapet
	return arena().Perch.Position + Vector3.new(0, 3 * S, 0)
end
local function landSpot() -- his root out on the sand, between the centre and the parapet
	local A = arena()
	return Vector3.new(A.Centre.X, 0, A.Centre.Z) + flat(perchPos() - A.Centre).Unit * 14 + Vector3.new(0, standY(), 0)
end
-- where on the sand he may stand: pulled in from the colonnade
local function clampToArena(p)
	local A = arena()
	local rel = flat(p - A.Centre)
	if rel.Magnitude > A.Radius then
		rel = rel.Unit * A.Radius
	end
	return Vector3.new(A.Centre.X + rel.X, standY(), A.Centre.Z + rel.Z)
end
local function draw(b, grip, body, t)
	pose(b, grip, t, EASE, INOUT)
	if body then
		bodyPose(b, body, t)
	end
end
-- wind up, turning toward the target for the first trackFrac of it (at rate x his usual turn: 0 = not at all)
local function windupTrack(b, duration, trackFrac, target, rate)
	local t0 = now()
	duration *= tempo()
	while now() - t0 < duration do
		if not free(b) then
			return false
		end
		local tr = target and target:FindFirstChild("HumanoidRootPart")
		local dt = task.wait()
		if tr and now() - t0 < duration * trackFrac then
			turnTowards(b.root, tr.Position, math.rad(boss.phase2 and 260 or 200) * (rate or 1) * dt)
		end
	end
	return true
end
local function hitOnce(list, seen, amount, fromPos, level)
	for _, pl in ipairs(list) do
		if not seen[pl] and damagePlayer(pl, dmg(amount), fromPos, level) then
			seen[pl] = true
		end
	end
end

-- the blade's real path hurts: sampled every frame between last frame's and this frame's
local bladeParams = OverlapParams.new()
bladeParams.FilterType = Enum.RaycastFilterType.Include
bladeParams.CollisionGroup = "HitQuery"
local function bladeEnds(b, weld) -- (weld: the second sword's, else his first)
	weld = weld or b.weld
	local handle = weld and weld.Parent and weld.Part1
	local base, tip = handle and handle:FindFirstChild("BladeBase"), handle and handle:FindFirstChild("BladeTip")
	if base and tip then
		return base.WorldPosition, tip.WorldPosition
	end
end
local function bladeSweep(b, duration, amount, level, seen, radius, weld)
	local chars = {}
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl.Character then
			table.insert(chars, pl.Character)
		end
	end
	bladeParams.FilterDescendantsInstances = chars
	local t0, pb, pt = now(), nil, nil
	while now() - t0 < duration and live(b) do
		local base, tip = bladeEnds(b, weld)
		if base then
			pb, pt = pb or base, pt or tip
			for i = 0, 3 do
				local bb, tt = pb:Lerp(base, i / 3), pt:Lerp(tip, i / 3)
				for j = 0, 5 do
					for _, part in ipairs(workspace:GetPartBoundsInRadius(bb:Lerp(tt, j / 5), radius, bladeParams)) do
						local pl = Players:GetPlayerFromCharacter(part:FindFirstAncestorOfClass("Model"))
						if pl and not seen[pl] and damagePlayer(pl, dmg(amount), b.root.Position, level) then
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

local function feetAt(p)
	return Vector3.new(p.X, arena().Centre.Y + 0.1, p.Z)
end
local function landFx(b, big)
	local at = feetAt(b.root.Position)
	dustCloud(at, big and 3 or 2, big and 16 or 9)
	playSound(b.root, SOUNDS.Impact, big and 1 or 0.7, big and 0.45 or 0.6)
	FxRemote:FireAllClients("Shake", at, big and 1.3 or 0.6)
end
-- the second sword (phase 2, b.weld2) in the left hand, its weld tweened like the first's
local function mirror(cf)
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
	return CFrame.new(-x, y, z, r00, -r01, -r02, -r10, r11, r12, -r20, r21, r22)
end
local function gripCF(name)
	local g = M.Grips[name]
	return CFrame.new(g[1] * S) * g[2]
end
local function poseL(b, name, t, style)
	local w = b.weld2
	if w and w.Parent then
		local cf = M.Grips["L" .. name] and gripCF("L" .. name) or mirror(gripCF(name))
		TweenService:Create(w, TweenInfo.new(math.max(t, 0.01), style or EASE, INOUT), { C0 = cf }):Play()
	end
end
local function setTrail2(b, on)
	local trail = b.weld2 and b.weld2.Parent and b.weld2.Parent:FindFirstChildWhichIsA("Trail")
	if trail then
		trail.Enabled = on
	end
end
-- after snapping him round (too small a turn for the cloth to call a teleport): every client
-- hangs his cape straight again (Carrier.cloth)
local function settleCloth(b)
	for _, a in ipairs(b.model:GetDescendants()) do
		if CollectionService:HasTag(a, "ClothChain") then
			a:SetAttribute("Settle", (a:GetAttribute("Settle") or 0) + 1)
		end
	end
end
local function idle(b)
	setTrail(b, false)
	setTrail2(b, false)
	pose(b, "GLow", 0.6, EASE, INOUT)
	poseL(b, "GLow", 0.6)
	bodyPose(b, "CHIdle", 0.6)
end
local function recover(b, t)
	bodyPose(b, "Recover", 0.4)
	if waitLive(b, t * tempo()) then
		idle(b)
	end
end
-- carried bodily (anchored) along a jump: from a to b (root positions) over dur seconds,
-- rising height at the top; flips = forward somersaults on the way; each(t) every frame
local function flight(b, a, bpos, dur, height, flips, each)
	local root = b.root
	root.Anchored = true
	local dir = flat(bpos - a)
	if dir.Magnitude < 0.1 then
		dir = flat(root.CFrame.LookVector)
	end
	dir = dir.Unit
	local t0 = now()
	while true do
		local t = math.min((now() - t0) / dur, 1)
		local p = a:Lerp(bpos, t) + Vector3.new(0, 4 * height * t * (1 - t), 0)
		local spin = flips * math.pi * 2 * (t < 0.5 and 2 * t * t or 1 - (-2 * t + 2) ^ 2 / 2)
		root.CFrame = CFrame.lookAt(p, p + dir) * CFrame.Angles(-spin, 0, 0)
		if each then
			each(t)
		end
		if t >= 1 or boss.gen ~= b.gen then
			break
		end
		RunService.Heartbeat:Wait()
	end
	root.CFrame = CFrame.lookAt(bpos, bpos + dir)
	root.AssemblyLinearVelocity = Vector3.zero
	if boss.state == "fight" then
		root.Anchored = false
	end
end

---------------------------------------------------------------------------
-- MOVES (each returns when it's done; picked by range in brain)
---------------------------------------------------------------------------
-- THE SPRING: down onto his haunches, glaring along the sand at you, then a long flat leap
-- that passes straight through where you stand, sword out ahead - and on past, to land
-- low and skidding the far side
-- (in a chain of leaps, brain): snap round to face you, no turning
local function faceNow(b, tr)
	if boss.followUp and tr then
		turnTowards(b.root, tr.Position, math.pi * 2)
	end
end

local function spring(b, target)
	local tr = target:FindFirstChild("HumanoidRootPart")
	faceNow(b, tr)
	b.hum:MoveTo(b.root.Position)
	draw(b, "GLow", "CHaunch", 0.35 * tempo())
	playSound(b.root, SOUNDS.Unsheath, 0.8, 0.45)
	dustCloud(feetAt(b.root.Position), 1.6, 5)
	if not windupTrack(b, C.SpringTell, 0.85, target) then
		return
	end
	local from = b.root.Position
	local to = Vector3.new(tr.Position.X, standY(), tr.Position.Z)
	local dir = flat(to - from)
	dir = dir.Magnitude > 0.1 and dir.Unit or flat(b.root.CFrame.LookVector).Unit
	local land = clampToArena(to + dir * C.SpringOvershoot)
	setTrail(b, true)
	draw(b, "GThrust", "CLaunch", 0.12)
	playSound(b.root, SOUNDS.Lunge, 1, 0.5)
	local seen = {}
	local dist = (land - from).Magnitude
	flight(b, from, land, math.clamp(dist / C.SpringSpeed, 0.35, 1.0), C.SpringHeight, 0, function(t)
		if t > 0.1 and t < 0.92 then
			hitOnce(playersInRadius(b.root.Position, 3.6 * S * 0.6, 4 * S), seen, C.SpringDamage, b.root.Position, "Launch")
		end
	end)
	setTrail(b, false)
	draw(b, "GLow", "CLand", 0.12)
	landFx(b, false)
	-- the skid: a few studs more along the sand
	local skid = clampToArena(b.root.Position + dir * 4)
	b.hum:MoveTo(skid)
	recover(b, boss.chainMore and C.ChainRecover or C.SpringRecover)
end

-- THE SOMERSAULT: a short crouch, then up and over end-over-end, the sword brought down
-- with all of him behind it where you were standing
local function somersault(b, target)
	local tr = target:FindFirstChild("HumanoidRootPart")
	faceNow(b, tr)
	b.hum:MoveTo(b.root.Position)
	draw(b, "GHigh", "CHaunch", 0.3 * tempo())
	if not windupTrack(b, C.FlipTell, 0.9, target) then
		return
	end
	local from = b.root.Position
	local v = tr.AssemblyLinearVelocity
	local to = clampToArena(Vector3.new(tr.Position.X, standY(), tr.Position.Z) + flat(v) * 0.25)
	local dir = flat(to - from)
	if dir.Magnitude > 3 then
		to -= dir.Unit * 3 -- (lands just short: the blade comes down on you)
	end
	draw(b, "GHigh", "CTuck", 0.15)
	playSound(b.root, SOUNDS.Lunge, 0.9, 0.6)
	setTrail(b, true)
	flight(b, from, to, C.FlipTime, C.FlipHeight, 1, function(t)
		if t > 0.72 then
			pose(b, "Strike", 0.08)
			bodyPose(b, "CLand", 0.1)
		end
	end)
	-- only the blade and where its point bites the sand hurt: not his feet, nor behind him
	local at = feetAt(b.root.Position + flat(b.root.CFrame.LookVector).Unit * C.FlipReach)
	local seen = {}
	hitOnce(playersInRadius(at, C.FlipRadius, 4 * S), seen, C.FlipDamage, at, "Launch")
	shockwave(at, C.FlipRadius)
	task.spawn(bladeSweep, b, 0.12, C.FlipDamage, "Launch", seen, 1.4)
	landFx(b, true)
	setTrail(b, false)
	recover(b, boss.chainMore and C.ChainRecover or C.FlipRecover)
end

-- THE HEAVE: three cuts too heavy for an arm. Each one is coiled long and plainly first -
-- hips, waist and knees wound away, up on his toes, wrist cocked, the sword dragged out
-- behind - then heaved round with all of him and carried on through by its weight a step
-- into you: right to left, back left to right, then hoisted up behind his head and brought
-- down into the sand
local function string3(b, target)
	b.hum:MoveTo(b.root.Position)
	local function step(d)
		local fwd = flat(b.root.CFrame.LookVector)
		if fwd.Magnitude > 0.1 then
			b.hum.WalkSpeed = d / 0.25
			b.hum:MoveTo(clampToArena(b.root.Position + fwd.Unit * d))
		end
	end
	-- { coil grip, coil body, coil time, held tell, swing-through grip, end grip, end body }
	local cuts = {
		{ "GHeaveBack", "CHeave", 0.55, C.HeaveTell, "SweepMid", "GHeaveEnd", "CHeaveEnd" },
		{ "GHeaveEnd", "CHeaveEnd", 0.4, C.HeaveTell * 0.75, "SweepMid", "GHeaveBack", "CHeave" },
		{ "GHigh", "CHoist", 0.6, C.HoistTell, "Mid", "GSlam", "CSlam" },
	}
	for i, c in ipairs(cuts) do
		draw(b, c[1], c[2], c[3] * tempo())
		dustCloud(feetAt(b.root.Position), 1.2, 4) -- (his feet digging in)
		-- (tracking you at half his usual turn; the back-cut, none: it comes from where the first left him)
		if not windupTrack(b, c[4], 0.85, target, i == 2 and 0 or 0.5) then
			return
		end
		setTrail(b, true)
		step(i == 3 and 4 or 7.5) -- (the two heaves carry him 1.5x as far)
		playSound(b.root, SOUNDS.Slash, 1, 0.42 + i * 0.04)
		pose(b, c[5], 0.09, LINEAR)
		task.delay(0.09, function()
			if boss.gen == b.gen then
				pose(b, c[6], 0.14)
				bodyPose(b, c[7], 0.18)
			end
		end)
		local seen = {}
		if i == 3 then
			-- the slam: where the point bites into the sand
			task.delay(0.2, function()
				if live(b) then
					local at = feetAt(b.root.Position + flat(b.root.CFrame.LookVector).Unit * 7 * S)
					hitOnce(playersInRadius(at, C.SlamRadius, 4 * S), seen, C.CutDamage * 1.3, b.root.Position, "Launch")
					shockwave(at, C.SlamRadius)
					landFx(b, true)
				end
			end)
		end
		bladeSweep(b, 0.3, i == 3 and C.CutDamage * 1.3 or C.CutDamage, "Launch", seen, 1.6)
		setTrail(b, false)
		b.hum.WalkSpeed = C.WalkSpeed
		-- the weight drags on him a beat after each cut (the opening between them)
		if i < 3 and not waitLive(b, C.HeaveDrag * tempo()) then
			return
		end
	end
	recover(b, C.StringRecover)
end

-- THE SPIN: wound right round, hips and all, the sword dragged out behind - then its weight
-- swings him a full turn with the blade held out flat
local function spin(b, target)
	b.hum:MoveTo(b.root.Position)
	draw(b, "GHeaveBack", "CSpin", 0.5 * tempo())
	dustCloud(feetAt(b.root.Position), 1.2, 4)
	if not windupTrack(b, C.SpinTell, 0.7, target) then
		return
	end
	setTrail(b, true)
	pose(b, "SweepMid", 0.08, LINEAR)
	bodyPose(b, "SweepEnd", 0.2)
	playSound(b.root, SOUNDS.Slash, 1, 0.45)
	local root = b.root
	root.Anchored = true
	local base = root.CFrame
	-- only the blade itself hurts as it comes round (so you can strafe away from it)
	task.spawn(bladeSweep, b, 0.5, C.SpinDamage, "Launch", {}, 1.6)
	local t0 = now()
	while now() - t0 < 0.5 and boss.gen == b.gen do
		local t = (now() - t0) / 0.5
		root.CFrame = base * CFrame.Angles(0, -t * math.pi * 2, 0)
		RunService.Heartbeat:Wait()
	end
	root.CFrame = base
	if boss.state == "fight" then
		root.Anchored = false
	end
	setTrail(b, false)
	recover(b, 0.55)
end

-- THE HOP AND LUNGE: a light backward hop out of reach, then straight back in on the point
local function hopLunge(b, target)
	local tr = target:FindFirstChild("HumanoidRootPart")
	local from = b.root.Position
	local back = clampToArena(from - flat(b.root.CFrame.LookVector).Unit * C.HopDistance)
	draw(b, "GThrustSet", "CThrustSet", 0.2)
	flight(b, from, back, 0.38, 3, 0, function()
		if tr.Parent then
			b.root.CFrame = CFrame.lookAt(b.root.Position, Vector3.new(tr.Position.X, b.root.Position.Y, tr.Position.Z))
		end
	end)
	b.root.Anchored = true -- (held a beat, set, then the lunge)
	if not windupTrack(b, 0.3, 0.9, target) then
		b.root.Anchored = false
		return
	end
	local to = clampToArena(b.root.Position + flat(b.root.CFrame.LookVector).Unit * C.LungeDistance)
	setTrail(b, true)
	draw(b, "GThrust", "CThrust", 0.1)
	playSound(b.root, SOUNDS.Lunge, 1, 0.65)
	local seen = {}
	flight(b, b.root.Position, to, 0.32, 0.6, 0, function()
		hitOnce(playersInRadius(b.root.Position + flat(b.root.CFrame.LookVector).Unit * 3, 3.5, 4 * S), seen, C.LungeDamage, b.root.Position, "Launch")
	end)
	setTrail(b, false)
	recover(b, C.LungeRecover)
end

-- THE THROW (never from close in): the sword hauled back over his shoulder, a glint running
-- down the blade, his body turning with you exactly the whole time - then flung. It spins flat
-- across the sand dead straight along that aim, and drives point-first into it where it runs out (or at the colonnade);
-- he leaps across the arena after it, tears it free and heaves it round in one huge sweep
local function showSword(b, on)
	local w = b.model:FindFirstChild("Weapon")
	for _, p in ipairs(w and w:GetDescendants() or {}) do
		if p:IsA("BasePart") then
			if on then
				p.Transparency = p:GetAttribute("WasT") or p.Transparency
			else
				p:SetAttribute("WasT", p:GetAttribute("WasT") or p.Transparency)
				p.Transparency = 1
			end
		end
	end
end
-- a copy of his sword to fly on its own: its handle anchored and carried, the rest welded on
local function thrownSword(b)
	local w = b.model:FindFirstChild("Weapon")
	local grip = w and w:FindFirstChild("GripWeld", true)
	if not grip then
		return nil
	end
	local copy = w:Clone()
	local handle
	for _, d in ipairs(copy:GetDescendants()) do
		if d.Name == "GripWeld" then
			handle = d.Parent
			d:Destroy()
		elseif d:IsA("Trail") then
			d.Enabled = true
		end
	end
	handle.Anchored = true
	copy.Name = "ThrownSword"
	copy.Parent = workspace
	return copy, handle
end

local function throwSword(b, target)
	local tr = target:FindFirstChild("HumanoidRootPart")
	local sword, handle
	local function finish() -- (also run by brain/onDied if the move is cut short)
		boss.cleanup = nil
		if sword then
			sword:Destroy()
			sword = nil
		end
		showSword(b, true)
	end
	boss.cleanup = finish
	b.hum:MoveTo(b.root.Position)
	draw(b, "GThrowSet", "CThrowSet", 0.45 * tempo())
	playSound(b.root, SOUNDS.Unsheath, 1, 1.4)
	FxRemote:FireAllClients("Shake", b.root.Position, 0.3)
	task.delay(0.35, function() -- the glint down the blade: unmistakable
		local _, tip = bladeEnds(b)
		if tip and live(b) then
			burst(tip, Color3.fromRGB(255, 250, 220), 24, 0.45, 10)
			playSound(b.root, SOUNDS.Unsheath, 0.8, 2)
		end
	end)
	-- he turns with you exactly, right up to the throw
	local t0 = now()
	while now() - t0 < C.ThrowTell * tempo() do
		if not free(b) then
			return
		end
		if tr.Parent then
			turnTowards(b.root, tr.Position, math.pi * 2)
		end
		task.wait()
	end
	-- flung: spinning flat along the sand at chest height
	draw(b, "GThrowRelease", "CThrow", 0.1)
	playSound(b.root, SOUNDS.Lunge, 1, 0.55)
	sword, handle = thrownSword(b)
	showSword(b, false)
	setTrail(b, false)
	if not sword then
		return
	end
	local A = arena()
	local y = A.Centre.Y + 3
	local fwd = flat(b.root.CFrame.LookVector).Unit
	local pos = Vector3.new(b.root.Position.X, y, b.root.Position.Z) + fwd * 4
	local vel = fwd * C.ThrowSpeed
	local mid = CFrame.new(0, 4.4 * S, 0) -- (it spins about the blade's middle, not the hilt)
	local spin, seen, t1, nextWhirr = 0, {}, now(), 0
	while now() - t1 < C.ThrowTime and live(b) do
		local dt = RunService.Heartbeat:Wait()
		pos += vel * dt -- (dead straight: all the aim was in his turning before the throw)
		local rel = flat(pos - A.Centre)
		local hitWall = rel.Magnitude > A.Radius
		if hitWall then
			pos = Vector3.new(A.Centre.X, y, A.Centre.Z) + rel.Unit * A.Radius
		end
		spin += dt * C.ThrowSpin
		handle.CFrame = CFrame.new(pos) * CFrame.Angles(0, spin, 0) * CFrame.Angles(0, 0, math.pi / 2) * mid
		hitOnce(playersInRadius(pos, C.ThrowRadius, 4 * S), seen, C.ThrowDamage, pos, "Launch")
		if now() > nextWhirr then
			nextWhirr = now() + 0.28
			playSound(handle, SOUNDS.Slash, 0.7, 0.6)
		end
		turnTowards(b.root, pos, math.rad(360) * dt) -- (he watches it go)
		if hitWall then
			break
		end
	end
	if not live(b) then
		return
	end
	-- it runs out and drives point-first into the sand, standing tall
	local from, stuck = handle.CFrame, CFrame.new(pos.X, A.Centre.Y + 8 * S, pos.Z) * CFrame.Angles(R(8), spin, 0)
	for i = 1, 6 do
		handle.CFrame = from:Lerp(stuck, i / 6)
		RunService.Heartbeat:Wait()
	end
	local sand = feetAt(pos)
	dustCloud(sand, 2, 10)
	playSound(handle, SOUNDS.Impact, 0.9, 0.7)
	FxRemote:FireAllClients("Shake", sand, 0.6)
	if not waitLive(b, 0.3 * tempo()) or not free(b) then
		return
	end
	-- the leap across the arena after it
	local start = b.root.Position
	local toward = flat(pos - start)
	local land = clampToArena(Vector3.new(pos.X, standY(), pos.Z) - (toward.Magnitude > 0.1 and toward.Unit * 2.5 or Vector3.zero))
	draw(b, "GLow", "CHaunch", 0.25 * tempo())
	if not waitLive(b, 0.3 * tempo()) then
		return
	end
	draw(b, "GHigh", "CTuck", 0.15) -- (tucked into a roll)
	playSound(b.root, SOUNDS.Lunge, 1, 0.5)
	flight(b, start, land, math.clamp((land - start).Magnitude / C.GrabLeapSpeed, 0.5, 1.3), C.GrabLeapHeight, 1, function(t)
		if t > 0.75 then -- (out of the flip, his hand reaching for the hilt)
			pose(b, "GThrust", 0.1)
			bodyPose(b, "CLand", 0.1)
		end
	end)
	landFx(b, false)
	if not live(b) then
		return
	end
	-- tears it out of the sand, back in his hands and straight into the coil
	finish()
	if tr.Parent then
		turnTowards(b.root, tr.Position, math.pi * 2)
	end
	draw(b, "GHeaveBack", "CHeave", 0.2)
	dustCloud(sand, 2, 8)
	playSound(b.root, SOUNDS.Unsheath, 1, 0.5)
	if not windupTrack(b, C.GrabSweepTell, 0.7, target) then
		return
	end
	-- the huge sweep
	setTrail(b, true)
	playSound(b.root, SOUNDS.Slash, 1, 0.35)
	pose(b, "SweepMid", 0.1, LINEAR)
	task.delay(0.1, function()
		if boss.gen == b.gen then
			pose(b, "GHeaveEnd", 0.16)
			bodyPose(b, "CHeaveEnd", 0.2)
		end
	end)
	local seen2 = {}
	task.delay(0.08, function()
		if live(b) then
			hitOnce(Core.playersInSector(b.root.CFrame, C.GrabSweepRange, C.GrabSweepArc, 4 * S), seen2, C.GrabSweepDamage, b.root.Position, "Launch")
			FxRemote:FireAllClients("Shake", b.root.Position, 1.1)
			dustCloud(feetAt(b.root.Position + flat(b.root.CFrame.LookVector).Unit * 8), 3, 14)
		end
	end)
	bladeSweep(b, 0.32, C.GrabSweepDamage, "Launch", seen2, 2)
	setTrail(b, false)
	recover(b, C.ThrowRecover)
end

-- THE WHIRLWIND (phase 2): both arms flung out, the swords pointing opposite ways, wound up
-- long and plainly - then he spins like a top and is carried once round a curved triangle
-- through the arena, paying you no mind at all: get out of its path (its edges pass close to
-- the middle, its corners near the wall: the pockets of sand between the corners are clear).
-- Dizzy after.
local function whirl(b, target)
	local root = b.root
	b.hum:MoveTo(root.Position)
	root.Anchored = true
	root.AssemblyLinearVelocity = Vector3.zero
	draw(b, "GWhirl", "CWhirlSet", 0.6)
	poseL(b, "GWhirl", 0.6)
	playSound(root, SOUNDS.Groan, 0.8, 0.7)
	dustCloud(feetAt(root.Position), 2, 8)
	for _, d in ipairs({ 0.5, 1.2 }) do -- glints down both blades
		task.delay(d, function()
			if live(b) then
				for _, w in ipairs({ b.weld, b.weld2 }) do
					local _, tip = bladeEnds(b, w)
					if tip then
						burst(tip, Color3.fromRGB(255, 250, 220), 18, 0.4, 8)
					end
				end
				playSound(root, SOUNDS.Unsheath, 0.8, 1.6)
			end
		end)
	end
	-- the tell: wound slowly back against the spin
	local base, t0 = root.CFrame, now()
	while now() - t0 < C.WhirlTell do
		if not live(b) then
			return
		end
		local a = (now() - t0) / C.WhirlTell
		root.CFrame = base * CFrame.Angles(0, -0.9 * a * a * (3 - 2 * a), 0)
		RunService.Heartbeat:Wait()
	end
	-- the spin, carried round r = WhirlPath * (1 + WhirlBulge cos 3(th - th0)): a corner where he stands
	local A = arena()
	local mid = Vector3.new(A.Centre.X, standY(), A.Centre.Z)
	local start = root.Position
	local rel = flat(start - mid)
	local th0 = rel.Magnitude > 1 and math.atan2(rel.Z, rel.X) or math.random() * math.pi * 2
	local dir = math.random() < 0.5 and -1 or 1
	local function along(th)
		local r = C.WhirlPath * (1 + C.WhirlBulge * math.cos(3 * (th - th0)))
		return mid + Vector3.new(math.cos(th) * r, 0, math.sin(th) * r)
	end
	setTrail(b, true)
	setTrail2(b, true)
	bodyPose(b, "CWhirl", 0.2)
	local _, yaw = root.CFrame:ToOrientation()
	local nextHit, nextWhirr, nextDust = {}, 0, 0
	t0 = now()
	local last = t0
	while live(b) and now() - t0 < C.WhirlTime do
		local t, dt = now() - t0, now() - last
		last = now()
		local p = along(th0 + dir * t / C.WhirlTime * math.pi * 2)
		if t < 0.5 then -- (eased from where he stands onto the path)
			local a = t / 0.5
			p = start:Lerp(p, a * a * (3 - 2 * a))
		end
		yaw += C.WhirlSpin * math.min(1, t / 0.3, (C.WhirlTime - t) / 0.5) * dt -- (spun up, and down at the end)
		root.CFrame = CFrame.new(p) * CFrame.Angles(0, yaw, 0)
		for _, pl in ipairs(playersInRadius(p, C.WhirlReach, 4 * S)) do
			if now() >= (nextHit[pl] or 0) and damagePlayer(pl, dmg(C.WhirlDamage), p, "Launch") then
				nextHit[pl] = now() + C.WhirlTick
			end
		end
		if now() > nextWhirr then
			nextWhirr = now() + 0.22
			playSound(root, SOUNDS.Slash, 0.8, 0.5)
		end
		if now() > nextDust then
			nextDust = now() + 0.15
			dustCloud(feetAt(p), 1.5, 4)
		end
		RunService.Heartbeat:Wait()
	end
	setTrail(b, false)
	setTrail2(b, false)
	if not live(b) then
		return
	end
	-- dizzy: the swords dropped low
	root.AssemblyLinearVelocity = Vector3.zero
	root.Anchored = false
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	draw(b, "GLow", "Recover", 0.3)
	poseL(b, "GLow", 0.3)
	recover(b, C.WhirlRecover)
end

-- THE CROSSING CUT (phase 2): both swords raised high and out to the sides, then brought down
-- across each other in an X, a step into you
local function crossCut(b, target)
	b.hum:MoveTo(b.root.Position)
	draw(b, "GCrossSet", "CHoist", 0.45 * tempo())
	poseL(b, "GCrossSet", 0.45 * tempo())
	playSound(b.root, SOUNDS.Unsheath, 0.9, 0.7)
	dustCloud(feetAt(b.root.Position), 1.2, 4)
	if not windupTrack(b, C.CrossTell, 0.85, target) then
		return
	end
	setTrail(b, true)
	setTrail2(b, true)
	b.hum.WalkSpeed = 6 / 0.3125
	b.hum:MoveTo(clampToArena(b.root.Position + flat(b.root.CFrame.LookVector).Unit * 6))
	playSound(b.root, SOUNDS.Slash, 1, 0.4)
	pose(b, "GCrossEnd", 0.175, LINEAR)
	poseL(b, "GCrossEnd", 0.175, LINEAR)
	bodyPose(b, "CSlam", 0.2)
	local seen = {}
	task.delay(0.15, function()
		if live(b) then
			hitOnce(Core.playersInSector(b.root.CFrame, C.CrossRange, C.CrossArc, 4 * S), seen, C.CrossDamage, b.root.Position, "Launch")
			shockwave(feetAt(b.root.Position + flat(b.root.CFrame.LookVector).Unit * 9), 6)
			landFx(b, true)
		end
	end)
	task.spawn(bladeSweep, b, 0.375, C.CrossDamage, "Launch", seen, 1.6, b.weld2)
	bladeSweep(b, 0.375, C.CrossDamage, "Launch", seen, 1.6)
	setTrail(b, false)
	setTrail2(b, false)
	b.hum.WalkSpeed = C.WalkSpeed
	recover(b, C.CrossRecover)
end

-- his second wind (half health): plants the sword and kneels; a second sword rises out of the
-- sand at his left hand, and he rips it out overhead as he stands; roars, both swords flung
-- wide, embers pouring off him. The first time it's a cutscene (everyone on the sand held,
-- the camera taken, and longer: crossing the swords at the end); after that, quick.
local function phase2(b)
	boss.phase2 = true
	local first = not boss.seen2
	boss.seen2 = true
	local root = b.root
	b.hum:MoveTo(root.Position)
	root.Anchored = true
	root.AssemblyLinearVelocity = Vector3.zero
	local A = arena()
	local P = root.Position
	local toMid = flat(A.Centre - P)
	if first and toMid.Magnitude > 4 then -- (facing the middle: room for the camera before him)
		root.CFrame = CFrame.lookAt(P, P + toMid.Unit)
		settleCloth(b)
	end
	local rot = root.CFrame.Rotation
	local fwd, right = flat(rot.LookVector).Unit, flat(rot.RightVector).Unit
	local spot = Vector3.new(P.X, A.Centre.Y, P.Z) - right * 1.8 * S + fwd * 0.4 * S
	-- the second sword, sunk out of sight in the sand at his left hand
	local w2 = b.model:FindFirstChild("Weapon"):Clone()
	w2.Name = "Weapon2"
	local weld2 = w2:FindFirstChild("GripWeld", true)
	local handle = weld2.Part1
	weld2.Enabled = false
	handle.Anchored = true
	local function hilt(h)
		handle.CFrame = CFrame.new(spot + Vector3.new(0, h, 0)) * rot
	end
	hilt(-2.5 * S)
	w2.Parent = b.model

	local T = first and { rise = 2.6, riseDur = 1.2, grab = 3.9, roar = 5.8, cross = 7.2, done = 8.6 }
		or { rise = 0.3, riseDur = 0.7, grab = 1.1, roar = 2.2, done = 3.4 }
	local held = {}
	if first then
		local V, look = Vector3.new, CFrame.lookAt
		local low = V(0, -3 * S, 0) -- (root height down to the sand)
		local shots = {
			-- low before him as he kneels and speaks: a slow push in
			{ look(P + fwd * 20 + right * 7 + low + V(0, 3, 0), P + V(0, 1, 0)), look(P + fwd * 15 + right * 5 + low + V(0, 3.5, 0), P + V(0, 1.5, 0)), 3.0 },
			-- down at his left side: the hilt rising out of the sand, his hand closing on it, the draw
			{ look(P + fwd * 10 - right * 12 + low + V(0, 2.5, 0), spot + V(0, 2, 0)), look(P + fwd * 9 - right * 10 + low + V(0, 5, 0), P - right * 2 + V(0, 4, 0)), 2.6 },
			-- wide and low before him: the roar, then the swords crossed
			{ look(P + fwd * 24 + low + V(0, 1.5, 0), P + V(0, 4, 0)), look(P + fwd * 19 - right * 6 + low + V(0, 2.5, 0), P + V(0, 5, 0)), 3.0 },
		}
		for _, pl in ipairs(Players:GetPlayers()) do
			local char, _, hrp = aliveChar(pl)
			local st = states[pl]
			if char and st and inArena(hrp.Position) then
				held[pl] = hrp
				Core.setAction(st, now(), T.done, T.done, T.done)
				st.healing = false
				Core.cancelSwing(st)
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.Anchored = true
				FxRemote:FireClient(pl, "Grabbed", T.done)
				FxRemote:FireClient(pl, "Cutscene", shots)
			end
		end
	end
	for _, pl in ipairs(Players:GetPlayers()) do
		local char, _, hrp = aliveChar(pl)
		if char and inArena(hrp.Position) then
			FxRemote:FireClient(pl, "Say", C.Name2, C.PhaseLine)
		end
	end
	draw(b, "GPlant", "CKneelReach", 0.5)
	playSound(root, SOUNDS.Impact, 0.8, 0.4)
	b.model:SetAttribute("ArmBehind", nil) -- (the free arm comes out from behind his back, reaching down)

	if first then -- the intro is timed to end with the cutscene
		ReplicatedStorage:SetAttribute("MusicIntro", T.done)
		ReplicatedStorage:SetAttribute("Music", "championintro2")
	else
		ReplicatedStorage:SetAttribute("Music", "champion2")
	end
	local t0 = now()
	local function at(t)
		task.wait(math.max(t - (now() - t0), 0))
		return boss.gen == b.gen and b.hum.Health > 0
	end
	local ok = at(T.rise)
	if ok then -- the ground shakes, and a hilt rises out of the sand beside him
		FxRemote:FireAllClients("Shake", spot, 0.5)
		dustCloud(spot, 2, 10)
		playSound(root, SOUNDS.Groan, 0.7, 0.35)
		task.spawn(function()
			local t1 = now()
			while handle.Parent and not weld2.Enabled do
				local a = math.min((now() - t1) / T.riseDur, 1)
				hilt(-2.5 * S + 3.3 * S * a * a * (3 - 2 * a))
				if a >= 1 then
					break
				end
				RunService.Heartbeat:Wait()
			end
		end)
		ok = at(T.grab)
	end
	if ok then -- his hand closes on it...
		weld2.C0 = root.CFrame:Inverse() * handle.CFrame * weld2.C1
		handle.Anchored = false
		weld2.Enabled = true
		b.weld2 = weld2
		playSound(root, SOUNDS.Unsheath, 1, 0.35)
		ok = at(T.grab + 0.25)
	end
	if ok then -- ...and rips it out overhead as he rises, his first sword coming up with it
		setTrail2(b, true)
		pose(b, "GHigh", 0.6)
		poseL(b, "GHigh", 0.6)
		bodyPose(b, "CHoist", 0.6)
		shockwave(spot, 5)
		burst(spot + Vector3.new(0, 1, 0), Color3.fromRGB(255, 220, 160), 30, 0.5, 14)
		FxRemote:FireAllClients("Shake", spot, 0.9)
		ok = at(T.roar)
		setTrail2(b, false)
	end
	if ok then -- the roar, both swords flung wide
		draw(b, "GWide", "CRoar", 0.35)
		poseL(b, "GWide", 0.35)
		for _, a in ipairs(b.model:GetDescendants()) do -- ...and so do all his capes (not the plume)
			if a.Name:find("CapeAnchor") then
				a:SetAttribute("Glow", true)
			end
		end
		for _, n in ipairs({ "Slit", "SlitDown" }) do -- the T of his visor lights white, like the sand
			local slit = b.model:FindFirstChild(n, true)
			if slit then
				slit.Color, slit.Material = Color3.new(1, 1, 1), Enum.Material.Neon
				local light = Instance.new("PointLight")
				light.Color, light.Range, light.Brightness = Color3.new(1, 1, 1), 10, 0
				light.Parent = slit
				TweenService:Create(light, TweenInfo.new(0.8), { Brightness = 1.5 }):Play()
			end
		end
		playSound(root, SOUNDS.Groan, 1, 0.5)
		FxRemote:FireAllClients("Shake", root.Position, 1.6)
		shockwave(feetAt(root.Position), 10)
		if not first then -- (no hitting anyone the cutscene is holding still)
			hitOnce(playersInRadius(root.Position, 9, 4 * S), {}, C.RoarDamage, root.Position, "Knockdown")
		end
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/fire_main.dds"
		pe.Color = ColorSequence.new(Color3.fromRGB(255, 120, 50), Color3.fromRGB(120, 20, 10))
		pe.LightEmission = 0.8
		pe.Size = NumberSequence.new(1.6, 0)
		pe.Lifetime = NumberRange.new(0.5, 1)
		pe.Rate = 40
		pe.Speed = NumberRange.new(1, 4)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.Acceleration = Vector3.new(0, 6, 0)
		pe.Parent = b.model:FindFirstChild("Chest") or root
		ReplicatedStorage:SetAttribute("BossName", C.Name2)
		if T.cross then
			ok = at(T.cross)
		end
	end
	if ok and T.cross then -- the swords crossed before him, ringing
		draw(b, "GX", "CGlare", 0.4)
		poseL(b, "GX", 0.4)
		task.delay(0.4, function()
			if boss.gen == b.gen then
				burst(P + fwd * 1.8 * S + Vector3.new(0, 1.2 * S, 0), Color3.fromRGB(255, 240, 200), 26, 0.45, 12)
				playSound(root, SOUNDS.Unsheath, 1, 1.5)
			end
		end)
	end
	if ok then
		at(T.done)
	end
	if boss.gen == b.gen and boss.state == "fight" then
		ReplicatedStorage:SetAttribute("Music", "champion2")
	end
	for pl, hrp in pairs(held) do
		if hrp.Parent then
			hrp.Anchored = false
			pcall(function()
				hrp:SetNetworkOwner(pl)
			end)
		end
	end
	if boss.gen == b.gen and boss.state == "fight" then
		root.Anchored = false
		pcall(function()
			root:SetNetworkOwner(nil)
		end)
		idle(b)
	end
end

-- THE ARENA SLASH (phase 2 opener; Config.Champion.ArenaSlash): coiled for ArenaSlashTell
-- seconds, then one cut that reaches everything on the sand. Nothing but a roll's
-- invulnerability beats it. Safe to delete along with its call in brain and its Config lines.
local function clearGlare()
	if boss.glare then
		boss.glare:Destroy()
		boss.glare = nil
	end
end
local function fadeGlare() -- (he falls: the sand comes back)
	local g = boss.glare
	boss.glare = nil
	if g then
		TweenService:Create(g, TweenInfo.new(3, Enum.EasingStyle.Sine), { Transparency = 1 }):Play()
		game:GetService("Debris"):AddItem(g, 3.2)
	end
end
local function arenaSlash(b, target)
	b.hum:MoveTo(b.root.Position)
	-- the sand darkens as it charges (a disc laid over it), then flashes white and stays so
	clearGlare()
	local A0 = arena()
	local glare = Instance.new("Part")
	glare.Name = "ArenaGlare"
	glare.Shape = Enum.PartType.Cylinder
	glare.Size = Vector3.new(0.2, A0.Radius * 2, A0.Radius * 2)
	glare.CFrame = CFrame.new(A0.Centre + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	glare.Anchored, glare.CanCollide, glare.CanQuery, glare.CanTouch = true, false, false, false
	glare.Material = Enum.Material.SmoothPlastic
	glare.Color = Color3.new(0, 0, 0)
	glare.Transparency = 1
	glare.Parent = workspace
	boss.glare = glare
	TweenService:Create(glare, TweenInfo.new(C.ArenaSlashTell, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 0.1 }):Play()
	draw(b, "GHigh", "CHoist", 0.5)
	poseL(b, "GHigh", 0.5)
	playSound(b.root, SOUNDS.Groan, 1, 0.5)
	local t0 = now()
	local nextGlint = 0
	while now() - t0 < C.ArenaSlashTell do
		if not free(b) then
			clearGlare() -- (interrupted: the sand comes back)
			return
		end
		if now() > nextGlint then -- the glints quicken as it nears
			nextGlint = now() + math.max(0.15, 0.5 * (1 - (now() - t0) / C.ArenaSlashTell))
			local _, tip = bladeEnds(b)
			if tip then
				burst(tip, Color3.fromRGB(255, 250, 220), 20, 0.4, 10)
			end
			FxRemote:FireAllClients("Shake", b.root.Position, 0.25 + 0.5 * (now() - t0) / C.ArenaSlashTell)
		end
		task.wait()
	end
	setTrail(b, true)
	setTrail2(b, true)
	playSound(b.root, SOUNDS.Slash, 1, 0.3)
	pose(b, "Mid", 0.14, LINEAR) -- (the slam runs at 0.64x of the original speed)
	task.delay(0.14, function()
		if boss.gen == b.gen then
			pose(b, "GSlam", 0.219)
			poseL(b, "GSlam", 0.219) -- (both swords down together)
			bodyPose(b, "CSlam", 0.281)
		end
	end)
	if not waitLive(b, 0.14 + 0.219) then -- (the swords land: only now does anything hit)
		return
	end
	glare.Material, glare.Color, glare.Transparency = Enum.Material.Neon, Color3.new(1, 1, 1), 0.5 -- (stays: half way between the sand and white)
	local A = arena()
	FxRemote:FireAllClients("Shake", A.Centre, 1.6)
	shockwave(feetAt(b.root.Position), A.Radius)
	dustCloud(feetAt(b.root.Position), 3, 14)
	local seen, t1 = {}, now()
	while now() - t1 < C.ArenaSlashWindow and live(b) do
		for _, pl in ipairs(Players:GetPlayers()) do
			local char, _, hrp = aliveChar(pl)
			if char and inArena(hrp.Position) then
				hitOnce({ pl }, seen, C.ArenaSlashDamage, b.root.Position, "Launch")
			end
		end
		task.wait()
	end
	setTrail(b, false)
	setTrail2(b, false)
	recover(b, C.ArenaSlashRecover)
end

local MOVES = {
	{ name = "Spring", fn = spring, min = 14, max = 70, cd = 3, w = 3 },
	{ name = "Somersault", fn = somersault, min = 8, max = 24, cd = 6, w = 2 },
	{ name = "String", fn = string3, min = 0, max = 11, cd = 2.5, w = 3 },
	{ name = "Spin", fn = spin, min = 0, max = 8, cd = 5, w = 1.5 },
	{ name = "HopLunge", fn = hopLunge, min = 0, max = 9, cd = 5, w = 1.5 },
	{ name = "Throw", fn = throwSword, min = 22, max = 80, cd = 12, w = 2 },
	-- (p2: phase 2 only, a sword in each hand)
	{ name = "Whirl", fn = whirl, min = 0, max = 80, cd = 14, w = 2.5, p2 = true },
	{ name = "Cross", fn = crossCut, min = 0, max = 12, cd = 5, w = 2.5, p2 = true },
}
local function pickMove(dist)
	local list, total = {}, 0
	for _, mv in ipairs(MOVES) do
		if dist >= mv.min and dist <= mv.max and now() >= (boss.cd[mv.name] or 0) and boss.lastMove ~= mv.name and (boss.phase2 or not mv.p2) and (mv.name ~= "Whirl" or boss.whirlLock <= 0) then
			table.insert(list, mv)
			total += mv.w
		end
	end
	local r = math.random() * total
	for _, mv in ipairs(list) do
		r -= mv.w
		if r <= 0 then
			return mv
		end
	end
	return nil
end

local function target(b)
	local best, bestD
	for _, pl in ipairs(Players:GetPlayers()) do
		local char, _, hrp = aliveChar(pl)
		if char and inArena(hrp.Position) then
			local d = flat(hrp.Position - b.root.Position).Magnitude
			if not bestD or d < bestD then
				best, bestD = char, d
			end
		end
	end
	return best
end

local function brain(b)
	boss.cd, boss.circleSide, boss.circleUntil = {}, 1, 0
	boss.whirlLock, boss.noRegen = 0, false
	while live(b) do
		task.wait(0.08)
		if not free(b) or b.root.Anchored then
			continue
		end
		b.hum.AutoRotate = false
		local tchar = target(b)
		local tr = tchar and tchar:FindFirstChild("HumanoidRootPart")
		if not tr then
			b.hum:MoveTo(b.root.Position)
			continue
		end
		if not boss.phase2 and not boss.husk and b.hum.Health <= b.hum.MaxHealth * 0.5 then -- (the husk never gets a second wind)
			boss.attacking = true
			phase2(b)
			if C.ArenaSlash and live(b) then
				local ok, err = pcall(arenaSlash, b, tchar)
				if not ok then
					warn("[Champion] arenaSlash: " .. tostring(err))
				end
			end
			boss.attacking = false
			continue
		end
		local rel = flat(tr.Position - b.root.Position)
		local dist = rel.Magnitude
		turnTowards(b.root, tr.Position, math.rad(240) * 0.08)
		if now() < boss.circleUntil then
			-- between moves: circling you light on his feet, never still
			local keep = math.clamp(dist, 9, 16)
			b.hum.WalkSpeed = C.WalkSpeed * 0.8
			b.hum:MoveTo(clampToArena(tr.Position + CFrame.Angles(0, boss.circleSide * 0.6, 0):VectorToWorldSpace(-rel.Unit) * keep))
			continue
		end
		local mv = pickMove(dist)
		if mv then
			boss.attacking, boss.lastMove = true, mv.name
			boss.cd[mv.name] = now() + mv.cd * tempo()
			-- a spring or a flip is followed by 1-2 more of either, back to back: only the last
			-- one gets its full recovery
			local leap = mv.name == "Spring" or mv.name == "Somersault"
			local chain = leap and math.random(1, 2) or 0
			boss.chainMore = chain > 0
			boss.noRegen = mv.name == "Whirl" -- (no mending while he whirls)
			local ok, err = pcall(mv.fn, b, tchar)
			local last = mv.fn
			for i = 1, chain do
				if not ok or not live(b) or not tchar.Parent then
					break
				end
				boss.chainMore, boss.followUp = i < chain, true
				-- nearly always the other one of the two (spring, flip, spring...)
				local other = last == spring and somersault or spring
				last = math.random() < C.ChainAlternate and other or last
				ok, err = pcall(last, b, tchar)
			end
			boss.chainMore, boss.followUp = false, false
			boss.noRegen = false
			-- after a whirl he can't whirl again for the next 4 attacks
			boss.whirlLock = mv.name == "Whirl" and 4 or math.max(0, boss.whirlLock - 1)
			if boss.cleanup then
				boss.cleanup() -- (a throw cut short: the sword back in his hand)
			end
			if not ok then
				warn("[DGUS] Champion move " .. mv.name .. " error: " .. tostring(err))
				b.root.Anchored = false
			end
			boss.attacking = false
			b.hum.WalkSpeed = C.WalkSpeed
			boss.circleSide = math.random() < 0.5 and -1 or 1
			boss.circleUntil = now() + rand(0.4, 1.0) * tempo() + (C.IdleExtra or 0)
		else
			b.hum.WalkSpeed = C.WalkSpeed
			b.hum:MoveTo(clampToArena(tr.Position))
		end
	end
end

---------------------------------------------------------------------------
-- spawn, the cutscene, death, reset
---------------------------------------------------------------------------
local function seal(on)
	for _, p in ipairs(arena().Seal) do
		p.CanCollide = on
		TweenService:Create(p, TweenInfo.new(on and 0.8 or 2), { Transparency = on and 0.82 or 1 }):Play()
	end
end

-- pinned to the sand's height and kept inside the colonnade whenever he's on his own feet
local function confine(b)
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if boss.gen ~= b.gen or boss.state ~= "fight" or not b.root.Parent then
			conn:Disconnect()
			return
		end
		if b.root.Anchored then
			return -- (a jump carries him itself)
		end
		local p = b.root.Position
		local q = clampToArena(p)
		if (q - p).Magnitude > 0.05 then
			b.root.CFrame = CFrame.new(q) * b.root.CFrame.Rotation
			local v = b.root.AssemblyLinearVelocity
			b.root.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
		end
	end)
end

-- BEATEN: he stays on his knees on the sand for good, his swords laid down either side of him,
-- and talks to you (Config.Champion.Fallen, a line each time you talk to him): he gives you
-- the Silver Key of his own will on line FallenKeyAt.
local function fallenKnight(cf)
	local NPCs = workspace:FindFirstChild("NPCs") or Instance.new("Folder") -- (shared: one folder only)
	NPCs.Name = "NPCs" -- animated by the Puppeteer like everyone else, but never hittable
	NPCs.Parent = workspace
	local model = Core.RigBuilder.build("Champion", S)
	model.Name = "FallenChampion"
	pcall(function()
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	local weld = Core.giveWeapon(model, "ChampionBlade", S)
	Core.applyLimbGroup(model)
	model.Parent = NPCs
	model:FindFirstChildOfClass("Humanoid").HipHeight = model:GetAttribute("HipHeight")
	local root = model:FindFirstChild("HumanoidRootPart")
	model:PivotTo(cf)
	root.Anchored = true
	-- the swords on the sand (no grip weld left: the Puppeteer leaves his hands empty)
	local sword, handle = model:FindFirstChild("Weapon"), weld.Part1
	weld:Destroy()
	handle.Anchored = true
	local sword2 = sword:Clone()
	sword2.Name = "Weapon2"
	sword2.Parent = model
	local fwd, right = flat(cf.LookVector).Unit, flat(cf.RightVector).Unit
	local feet = Vector3.new(cf.X, arena().Centre.Y + 0.2 * S, cf.Z)
	for i, h in ipairs({ handle, sword2:FindFirstChild(handle.Name) }) do
		local side = i == 1 and 1 or -1
		local p = feet + right * side * 1.8 * S + fwd * 0.6 * S
		local d = (fwd + right * side * 0.35).Unit
		h.CFrame = CFrame.lookAt(p, p + d) * CFrame.Angles(math.pi / 2, 0, 0) -- (flat, blade pointing out ahead)
	end
	bodyPose({ model = model }, "Kneel", 1.0)

	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "Talk"
	pp.ObjectText = C.Name
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 12
	pp.RequiresLineOfSight = false
	pp.Parent = root
	local heard = {} -- per player: lines heard
	pp.Triggered:Connect(function(pl)
		local n = (heard[pl] or 0) + 1
		heard[pl] = n
		FxRemote:FireClient(pl, "Say", C.Name2, C.Fallen[n] or C.FallenAfter)
		if n == C.FallenKeyAt and not pl:GetAttribute("SilverKey") then
			pl:SetAttribute("SilverKey", true)
			FxRemote:FireClient(pl, "Message", C.SilverKey)
		end
		-- ...and with it his swords and his armor (picked in the weapon menu, T)
		if n == C.FallenKeyAt and not pl:GetAttribute("Has_CaelenBlades") then
			pl:SetAttribute("Has_CaelenBlades", true)
			pl:SetAttribute("CaelenArmor", true)
			task.delay(3.5, function()
				FxRemote:FireClient(pl, "Message", C.Gift)
			end)
		end
	end)
	Players.PlayerRemoving:Connect(function(pl)
		heard[pl] = nil
	end)
	return model
end

---------------------------------------------------------------------------
-- THE HUSK (Ossaria.luau's challenge): Caelen as she has him now, on her strings. The same body and his first
-- phase's moves (never a second wind: no second sword, no arena slash, no mending), and every few seconds a hole of
-- decay opens round your feet (Config.Ossaria.Knight.Hole). He runs on this file's one `boss`, which is free by
-- then: the Silver Knight himself is "gone" (M.vanish) before she can be challenged. boss.husk holds Ossaria's hooks.
---------------------------------------------------------------------------
local function decayHole(b, at)
	local HC = Config.Ossaria.Knight.Hole
	local Heir = Core.Roster.byKind.OssariaHeir -- (the pools of rot are hers: the same in all three phases)
	local R = HC.Radius
	local c = Vector3.new(at.X, arena().Centre.Y, at.Z)
	local parts = Heir.pool(c, R, HC.Delay, true)
	playSound(parts[1], SOUNDS.Lunge, 0.8, 0.3)
	task.delay(HC.Delay, function() -- (it opens; a second later it erupts: the only moment it hurts)
		if live(b) then
			Heir.erupt(c, R, true)
			playSound(parts[1], SOUNDS.WatchdogSmash, 0.7, 0.45)
			hitOnce(playersInRadius(c, R, 6), {}, HC.Damage, c, "Launch")
		end
		Heir.unpool(parts)
	end)
end
-- every Every[1]..Every[2] seconds, one under each of you on the sand: its centre a random 0..Radius from your feet,
-- so even at its farthest its edge still reaches them
local function decayHoles(b)
	local HC = Config.Ossaria.Knight.Hole
	task.spawn(function()
		while waitLive(b, rand(HC.Every[1], HC.Every[2])) do
			for _, pl in ipairs(Players:GetPlayers()) do
				local char, _, hrp = aliveChar(pl)
				if char and inArena(hrp.Position) then
					local a, r = rand(0, math.pi * 2), rand(0, HC.Radius)
					decayHole(b, hrp.Position + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
				end
			end
		end
	end)
end
local function huskDied(b)
	local hooks = boss.husk
	boss.husk, boss.state = nil, "gone" -- (gone again: nothing of the Silver Knight's comes back after him)
	if boss.cleanup then
		boss.cleanup()
	end
	ReplicatedStorage:SetAttribute("BossActive", false)
	ReplicatedStorage:SetAttribute("Music", "none") -- (no victory: she's still up there)
	FxRemote:FireAllClients("Banner", "HUSK FELLED", "Victory")
	seal(false)
	-- (a dead rig is no longer posed) he goes to dust where he stands, from the head down, each piece sinking and
	-- shrinking away into it; Ossaria's reveal plays over it (hooks.onDied)
	local at = b.root.Position
	if hooks.onDied then
		task.spawn(hooks.onDied, at)
	end
	local pieces = {}
	for _, p in ipairs(b.model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			table.insert(pieces, p)
		end
	end
	table.sort(pieces, function(p, q)
		return p.Position.Y > q.Position.Y
	end)
	local DUST = Color3.fromRGB(70, 62, 58)
	for i, p in ipairs(pieces) do
		task.delay(0.5 + 2.2 * i / #pieces, function()
			if i % 6 == 0 then
				burst(p.Position, DUST, 6, 0.5, 4)
			end
			TweenService:Create(p, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1, Size = p.Size * 0.3, CFrame = p.CFrame - Vector3.new(0, 1.5, 0) }):Play()
		end)
	end
	task.delay(0.6, function()
		playSound(b.root, SOUNDS.Impact, 0.6, 0.35)
	end)
	task.delay(1.4, function()
		dustCloud(feetAt(at), 5, 22)
	end)
	game:GetService("Debris"):AddItem(b.model, 3.6)
end

local function onDied(b)
	if boss.gen ~= b.gen or boss.state == "dead" or boss.state == "gone" then
		return
	end
	if boss.husk then
		return huskDied(b)
	end
	boss.state = "dead"
	Core.Save.mark("Champion")
	if boss.cleanup then
		boss.cleanup()
	end
	ReplicatedStorage:SetAttribute("BossActive", false)
	ReplicatedStorage:SetAttribute("Music", "victory")
	fadeGlare()
	FxRemote:FireAllClients("Banner", "CHAMPION FELLED", "Victory")
	for _, pl in ipairs(Players:GetPlayers()) do
		local char, _, hrp = aliveChar(pl)
		if char and inArena(hrp.Position) then
			FxRemote:FireClient(pl, "Say", C.Name2, C.Dying)
		end
	end
	-- (a dead rig is no longer posed by the Puppeteer: he's swapped for a living copy, an NPC
	-- that goes down on its knees where he stood and stays there)
	local fwd = flat(b.root.CFrame.LookVector)
	fwd = fwd.Magnitude > 0.1 and fwd.Unit or Vector3.new(0, 0, -1)
	local at = Vector3.new(b.root.Position.X, standY(), b.root.Position.Z)
	b.model:Destroy()
	boss.fallen = fallenKnight(CFrame.lookAt(at, at + fwd))
	Core.dropSplinter(at + fwd * 6, boss.fallen)
	seal(false)
end

local function spawn()
	boss.gen += 1
	if boss.fallen then -- (the dev menu bringing him back: off his knees)
		boss.fallen:Destroy()
		boss.fallen = nil
	end
	boss.centred = false
	local model, hum, weld = Core.makeRig("Champion", "Champion", S, "ChampionBlade")
	if not model then
		return
	end
	hum.MaxHealth, hum.Health = C.HP, C.HP
	hum.WalkSpeed = C.WalkSpeed
	hum.BreakJointsOnDeath = false
	model:SetAttribute("Radius", 2.4)
	model:SetAttribute("Boss", true)
	model:SetAttribute("ArmBehind", true) -- (his free arm folded behind his back until his second wind)
	local root = model:FindFirstChild("HumanoidRootPart")
	-- pinned (anchored) until his entrance: the first time standing out on the sand, his back
	-- to the middle; after that up on the parapet, looking down at it
	root.Anchored = true
	if boss.seen then
		model:PivotTo(arena().Perch + Vector3.new(0, 3 * S, 0))
	else
		local p = landSpot()
		model:PivotTo(CFrame.lookAt(p, p + flat(perchPos() - arena().Centre)))
	end
	root.CollisionGroup = "EnemyRoot"
	hum.AutoRotate = false
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	boss.model, boss.hum, boss.root = model, hum, root
	boss.phase2, boss.staggerUntil, boss.poise, boss.lastMove, boss.attacking = false, 0, nil, nil, false
	boss.state = "dormant"
	local b = { model = model, hum = hum, root = root, weld = weld, scale = S, gen = boss.gen }
	boss.current = b
	pose(b, "GPlant", 0.01)
	bodyPose(b, "CProud", 0.01)
	hum.HealthChanged:Connect(function(h)
		if boss.gen == b.gen and boss.state == "fight" then
			ReplicatedStorage:SetAttribute("BossHP", math.max(0, h))
		end
	end)
	hum.Died:Connect(function()
		onDied(b)
	end)
end

-- his entrance (the first time only): he stands proud on the sand with his back to you, his
-- hand on the pommel of his sword planted beside him. His head turns first, round over his
-- shoulder to peer at you; then his waist pivots after it, wrenching the sword out of the
-- sand, and his feet step him round under it; he glares while he speaks, then heaves the
-- great sword round with all of him and levels it at you. Everyone on the sand is held still.
local function cutscene(b)
	local A = arena()
	local land = landSpot()
	local held, near = {}, nil
	for _, pl in ipairs(Players:GetPlayers()) do
		local char, _, hrp = aliveChar(pl)
		if char and states[pl] and inArena(hrp.Position) then
			held[pl] = hrp
			if not near or (hrp.Position - land).Magnitude < (near.Position - land).Magnitude then
				near = hrp
			end
		end
	end
	-- toward whoever walked in (he starts with his back square to them)
	local toYou = near and flat(near.Position - land) or flat(A.Centre - land)
	toYou = toYou.Magnitude > 0.1 and toYou.Unit or flat(A.Centre - land).Unit
	local away = CFrame.lookAt(land, land - toYou)
	b.root.CFrame = away
	settleCloth(b)
	local V, look = Vector3.new, CFrame.lookAt
	local side = Vector3.new(-toYou.Z, 0, toYou.X)
	local shots = {
		-- low on the sand behind your shoulder, looking up at his back: a slow push in as he turns
		{ look(land + toYou * 22 + side * 4 + V(0, -3 * S + 2.5, 0), land + V(0, 3, 0)), look(land + toYou * 17 + side * 3 + V(0, -3 * S + 3, 0), land + V(0, 3.5, 0)), 3.9 },
		-- closer, up at his helm, while he speaks
		{ look(land + toYou * 12 + side * 3, land + V(0, 4.5, 0)), look(land + toYou * 9 + side * 2 + V(0, 0.5, 0), land + V(0, 4.5, 0)), 5.4 },
		-- wider and low as he heaves the sword round and levels it
		{ look(land + toYou * 16 + side * 8 + V(0, -3, 0), land + V(0, 2, 0)), look(land + toYou * 17 - side * 6 + V(0, -2.5, 0), land + V(0, 3, 0)), 3.6 },
	}
	local total = 12.9
	for pl, hrp in pairs(held) do
		local st = states[pl]
		Core.setAction(st, now(), total, total, total)
		st.healing = false
		Core.cancelSwing(st)
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.Anchored = true
		FxRemote:FireClient(pl, "Grabbed", total)
		FxRemote:FireClient(pl, "Cutscene", shots)
	end
	ReplicatedStorage:SetAttribute("MusicIntro", total) -- (the intro is timed to end with the cutscene)
	ReplicatedStorage:SetAttribute("Music", "championintro")
	local t0 = now()
	local function at(t)
		task.wait(math.max(t - (now() - t0), 0))
		return boss.gen == b.gen and boss.state == "intro"
	end
	local function say(line)
		for pl in pairs(held) do
			FxRemote:FireClient(pl, "Say", C.Name, line)
		end
	end
	-- one step of the turn: the root comes round to yaw (radians off "away") over dur while the
	-- body pose unwinds over the same time, so his upper body holds on you as his feet come round
	local function stepRound(yaw, body, dur)
		bodyPose(b, body, dur)
		task.spawn(function()
			local from, to = b.root.CFrame, away * CFrame.Angles(0, yaw, 0)
			local t1 = now()
			while boss.gen == b.gen and boss.state == "intro" do
				local a = math.min((now() - t1) / dur, 1)
				b.root.CFrame = from:Lerp(to, a * a * (3 - 2 * a))
				if a >= 1 then
					break
				end
				RunService.Heartbeat:Wait()
			end
		end)
	end
	local steps = {
		{ 0.6, function() bodyPose(b, "CPeer", 0.9) end }, -- the head comes round first
		{ 1.9, function() -- the waist pivots after it, pulling the sword out of the sand
			bodyPose(b, "CPivot", 0.7)
			pose(b, "GLow", 0.7)
			playSound(b.root, SOUNDS.Unsheath, 0.7, 0.35)
		end },
		{ 2.6, function() stepRound(1.0, "CStep1", 0.35) end },
		{ 2.95, function() stepRound(2.0, "CStep2", 0.35) end },
		{ 3.3, function() stepRound(math.pi, "CGlare", 0.4) end },
		{ 4.0, function() say(C.Lines[1]) end },
		{ 8.4, function() say(C.Lines[2]) end },
		{ 9.4, function() draw(b, "GHeaveBack", "CHeave", 0.7); dustCloud(feetAt(land), 1.2, 4) end },
		{ 10.3, function()
			pose(b, "SweepMid", 0.09, LINEAR)
			task.delay(0.09, function()
				pose(b, "GHeaveEnd", 0.14)
				bodyPose(b, "CHeaveEnd", 0.18)
			end)
			playSound(b.root, SOUNDS.Slash, 1, 0.42)
		end },
		{ 11.2, function() draw(b, "GPoint", "CPoint", 0.5) end },
		{ total, function() end },
	}
	local ok = true
	for _, s in ipairs(steps) do
		ok = at(s[1])
		if not ok then
			break
		end
		s[2]()
	end
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

local function start()
	if boss.state ~= "dormant" or boss.husk then -- (the husk is started by Ossaria's challenge: M.huskStart)
		return
	end
	boss.state = "intro"
	local b = boss.current
	seal(true)
	task.spawn(function()
		if not boss.seen then
			boss.seen = true
			Core.Save.mark("ChampionSeen")
			if not cutscene(b) then
				return
			end
		else
			FxRemote:FireAllClients("Say", C.Name, C.Again)
			-- down off the parapet to meet you
			draw(b, "GHigh", "CTuck", 0.2)
			flight(b, perchPos(), landSpot(), 1.2, 8, 1)
			b.root.Anchored = true
			landFx(b, true)
			idle(b)
			task.wait(0.8)
			if boss.gen ~= b.gen or boss.state ~= "intro" then
				return
			end
		end
		ReplicatedStorage:SetAttribute("BossName", C.Name)
		ReplicatedStorage:SetAttribute("BossMaxHP", b.hum.MaxHealth)
		ReplicatedStorage:SetAttribute("BossHP", b.hum.Health)
		ReplicatedStorage:SetAttribute("BossActive", true)
		ReplicatedStorage:SetAttribute("Music", "champion")
		boss.state = "fight"
		b.root.Anchored = false
		pcall(function()
			b.root:SetNetworkOwner(nil)
			b.hum:ChangeState(Enum.HumanoidStateType.Running)
		end)
		idle(b)
		confine(b)
		task.spawn(function() -- he mends a little, always
			while live(b) do
				task.wait(0.5)
				if live(b) and not boss.noRegen then
					b.hum.Health = math.min(b.hum.MaxHealth, b.hum.Health + b.hum.MaxHealth * C.Regen * 0.5)
				end
			end
		end)
		brain(b)
	end)
end

local function anyoneInArena()
	for _, pl in ipairs(Players:GetPlayers()) do
		local char, _, hrp = aliveChar(pl)
		if char and inArena(hrp.Position) then
			return true
		end
	end
	return false
end

local function reset()
	if boss.state == "dead" or boss.state == "dormant" or boss.state == "gone" then
		return
	end
	if boss.model then
		boss.model:Destroy()
	end
	ReplicatedStorage:SetAttribute("BossActive", false)
	ReplicatedStorage:SetAttribute("Music", "none")
	clearGlare()
	seal(false)
	if boss.husk then -- (Ossaria's knight: gone, and she waits on her sand to be challenged again)
		local hooks = boss.husk
		boss.husk, boss.state = nil, "gone"
		boss.gen += 1
		hooks.onReset()
		return
	end
	spawn()
end

function M.init(core)
	Core = core
	Map, FxRemote, states, now, flat, rand, turnTowards, SOUNDS, playSound, burst, dustCloud, shockwave, debrisChunks, pose, bodyPose, setTrail, aliveChar, damagePlayer, playersInRadius = core.Map, core.FxRemote, core.states, core.now, core.flat, core.rand, core.turnTowards, core.SOUNDS, core.playSound, core.burst, core.dustCloud, core.shockwave, core.debrisChunks, core.pose, core.bodyPose, core.setTrail, core.aliveChar, core.damagePlayer, core.playersInRadius
	core.registerTarget(function(model)
		if not boss.model or boss.model ~= model then
			return nil
		end
		return {
			owner = boss,
			actor = boss.current,
			maxPoise = C.Poise,
			freeze = false,
			armor = boss.attacking, -- mid-move he shrugs off half of every poise hit
			onBreak = function(_, t)
				if boss.state ~= "fight" or boss.root.Anchored then
					return -- (no knocking him out of the air)
				end
				local actor = boss.current
				boss.staggerUntil = t + C.Stagger
				setTrail(actor, false)
				pose(actor, "Flinch", 0.15)
				bodyPose(actor, "Stagger", 0.12)
				boss.hum:MoveTo(boss.root.Position)
				playSound(boss.root, SOUNDS.Impact, 0.9, 0.55)
				FxRemote:FireAllClients("Shake", boss.root.Position, 0.5)
				local gen = boss.gen
				task.delay(C.Stagger, function()
					if boss.gen == gen and boss.state == "fight" then
						idle(actor)
					end
				end)
			end,
		}
	end)
	-- he comes down when someone walks out onto the sand
	task.spawn(function()
		while true do
			task.wait(0.25)
			if boss.state == "dormant" and not boss.husk and Map.Champion then
				for _, pl in ipairs(Players:GetPlayers()) do
					local char, _, hrp = aliveChar(pl)
					if char and flat(hrp.Position - arena().Centre).Magnitude < arena().Radius - 4 and math.abs(hrp.Position.Y - arena().Centre.Y) < 8 then
						start()
						break
					end
				end
			end
		end
	end)
end

M.spawn = function()
	boss.seen = boss.seen or Core.Save.done("ChampionSeen") -- (his entrance: only ever the first time)
	if not Core.Save.done("Champion") then
		return spawn()
	end
	-- beaten in this save: on his knees on the sand where he first stood (the Great Stair's moving him to the middle
	-- takes it from there: init.server)
	boss.state = "dead"
	local p = landSpot()
	boss.fallen = fallenKnight(CFrame.lookAt(p, p + flat(perchPos() - arena().Centre)))
end
M.reset = reset
M.devWound = function() -- (dev menu) one hit from death
	if boss.hum and boss.hum.Health > 0 then
		boss.hum.Health = 1
	end
end
M.state = function()
	return boss.state
end
M.anyoneInArena = anyoneInArena
M.seal = seal -- (OssariaHeir.luau: her own fight is on his sand)
M.inArena = inArena
-- (init.server: the Great Stair lands round the middle of the sand) he's moved there, swords and all, while nobody's looking
M.fallenCentred = function()
	return boss.centred
end
M.centreFallen = function()
	if boss.fallen then
		local c = Vector3.new(arena().Centre.X, standY(), arena().Centre.Z)
		boss.fallen:PivotTo(CFrame.lookAt(c, c + Vector3.xAxis)) -- (facing the arch's side, where the road comes in)
		boss.centred = true
	end
end
-- (Ossaria.luau: her meeting) gone from his sand for good, standing, fighting or on his knees, before she brings the
-- Heights down onto it; nothing brings him back (state "gone": no reset, no entrance, no Great Stair)
M.vanish = function()
	local fighting = boss.state == "fight"
	boss.gen += 1
	boss.state = "gone"
	if fighting and boss.cleanup then
		pcall(boss.cleanup)
	end
	for _, m in ipairs({ boss.model, boss.fallen }) do
		if m then
			m:Destroy()
		end
	end
	boss.model, boss.fallen = nil, nil
	if fighting then
		ReplicatedStorage:SetAttribute("BossActive", false)
		ReplicatedStorage:SetAttribute("Music", "none")
		clearGlare()
	end
	seal(false)
end
M.devKill = function() -- (dev menu) dead, wherever he stands
	if boss.hum and boss.hum.Health > 0 then
		boss.hum.Health = 0
	end
end
-- (init.server's onPlayerDied) someone fell on his sand mid-fight: he has a word for them
M.onPlayerDied = function(pl)
	local hrp = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
	if boss.state == "fight" and not boss.husk and hrp and inArena(hrp.Position) then
		FxRemote:FireClient(pl, "Say", boss.phase2 and C.Name2 or C.Name, C.Victor)
	end
end

-- (Ossaria.luau) the husk's body, anchored and still at cf, on this file's `boss` but not fighting yet (her cutscene
-- moves it). dress(model) rots it before it's shown. hooks: onReset() (everyone died: it's gone, she waits again),
-- onDied() (beaten). Returns the actor (model, hum, root, weld, scale) for her cutscene to pose.
M.huskSpawn = function(cf, dress, hooks)
	local H = Config.Ossaria.Knight
	boss.gen += 1
	local model, hum = Core.RigBuilder.build("Champion", S)
	model.Name = "OssariaKnight"
	pcall(function()
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	local weld = Core.giveWeapon(model, "ChampionBlade", S)
	Core.applyLimbGroup(model)
	dress(model) -- (before it's parented: the clients read its cloth's colours once)
	hum.MaxHealth, hum.Health = H.HP, H.HP
	hum.WalkSpeed = C.WalkSpeed
	hum.BreakJointsOnDeath = false
	hum.AutoRotate = false
	model:SetAttribute("Radius", 2.4)
	model:SetAttribute("Boss", true)
	local root = model:FindFirstChild("HumanoidRootPart")
	root.Anchored = true
	root.CollisionGroup = "EnemyRoot"
	model:PivotTo(cf)
	model.Parent = Core.EnemiesFolder
	hum.HipHeight = model:GetAttribute("HipHeight")
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	boss.model, boss.hum, boss.root = model, hum, root
	boss.phase2, boss.staggerUntil, boss.poise, boss.lastMove, boss.attacking = false, 0, nil, nil, false
	boss.state, boss.husk = "dormant", hooks
	local b = { model = model, hum = hum, root = root, weld = weld, scale = S, gen = boss.gen }
	boss.current = b
	hum.HealthChanged:Connect(function(h)
		if boss.gen == b.gen and boss.state == "fight" then
			ReplicatedStorage:SetAttribute("BossHP", math.max(0, h))
		end
	end)
	hum.Died:Connect(function()
		onDied(b)
	end)
	return b
end
-- (Ossaria.luau, at her cutscene's end) the fight: the seal, his bar, his moves, and the holes
M.huskStart = function()
	local b = boss.current
	if not boss.husk or boss.state ~= "dormant" or not b then
		return
	end
	local H = Config.Ossaria.Knight
	seal(true)
	ReplicatedStorage:SetAttribute("BossName", H.Name)
	ReplicatedStorage:SetAttribute("BossMaxHP", b.hum.MaxHealth)
	ReplicatedStorage:SetAttribute("BossHP", b.hum.Health)
	ReplicatedStorage:SetAttribute("BossActive", true)
	ReplicatedStorage:SetAttribute("Music", "champion")
	boss.state = "fight"
	b.root.Anchored = false
	pcall(function()
		b.root:SetNetworkOwner(nil)
		b.hum:ChangeState(Enum.HumanoidStateType.Running)
	end)
	idle(b)
	confine(b)
	decayHoles(b)
	task.spawn(brain, b)
end

return M
