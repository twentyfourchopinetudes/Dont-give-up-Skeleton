--!nonstrict
-- OSSARIA, UNCLOAKED (kind OssariaHeir): what was under the shrouds (GameServer/Ossaria.luau sheds them, after her husk
-- falls). Spindly and wrong: ash-pale skin drawn over bone, a torso hardly wider than her spine, arms that hang past her
-- knees and end in long talons - and more fingers, of every length, branching off her arms and legs all the way down,
-- jointed and hooked like her hands'. The cloak didn't come off: it tore, and hangs off her limbs in rags, each one
-- swinging on its own (Carrier.cloth: a chain per rag).
--
-- EVERYTHING ABOUT THIS CHARACTER IS IN THIS ONE FILE:
--   M.Proportions / M.Poses   body shape and its full-body poses (the client animator uses these too)
--   M.Colors / M.Look         the rig's dress (RigBuilder calls Look with its kit of helpers)
--   M.Faces / M.Face          her face: the designs to choose between, M.Face the one she wears
--   M.init(Core) and below    HER OWN FIGHT (server only): phases 2 and 3 of hers (the first is her husk's:
--                             Champion.luau). Ossaria.luau's reveal hands her over (M.begin). Tuning: Config.Ossaria.Fight.
local CollectionService = game:GetService("CollectionService")

local M = {}

M.Kind = "OssariaHeir"
M.Proportions = { girth = 0.3, arm = 1.7, hunch = 0.2, limbs = true, torso = 1.35, leg = 1.3, elbowOut = 0.4 } -- (leg: long under that long torso)
M.IdlePose = "OHIdle"
M.FistSkin = true -- (her hands are her own skin, not gloves)
M.Poses = {
	-- hunched over, head hung forward, the long arms dangling loose past her knees, up on her toes
	OHIdle = { drop = 0.35, lean = 0.3, head = 0.3, side = 0.08, la1 = 0.15, la3 = -0.3, lel = 0.35, ra1 = 0.15, ra3 = 0.3, rel = 0.35, freeL = 0, breathe = 2.6, footR = 0.3, footL = -0.3, spread = 0.35, lwr = 0.6, rwr = 0.6, toe = 0.35 },
	-- the cloak flung open: arms thrown wide and up, chest out, head back
	OHUnfurl = { drop = 0.05, lean = -0.35, head = -0.5, la1 = 0.5, la3 = -1.55, lel = 0.15, ra1 = 0.5, ra3 = 1.55, rel = 0.15, freeL = 0, breathe = 3, spread = 0.2, lwr = -0.5, rwr = -0.5 },
	-- hanging in the air, legs trailing, arms half spread
	OHHang = { drop = 0, lean = 0.15, head = 0.2, la1 = 0.3, la3 = -0.8, lel = 0.5, ra1 = 0.3, ra3 = 0.8, rel = 0.5, freeL = 0, footR = -0.2, footL = 0.25, toe = 1.0, lwr = 0.5, rwr = 0.5 },
	-- landed: folded right down onto her haunches, one talon on the sand
	OHLand = { drop = 1.5, lean = 0.75, head = -0.25, la1 = -0.6, la3 = -0.4, lel = 0.2, ra1 = 0.9, ra3 = 0.6, rel = 0.3, freeL = 0, footR = 0.6, footL = -0.6, spread = 0.5, lwr = 0.9, rwr = -0.3, toe = 0.6 },
	-- her head tipped right over to one side, looking at you
	-- THE FIGHT. The rake: a long arm drawn right back and out, wound away from you...
	OHRakeSetR = { drop = 0.6, lean = 0.15, twist = -0.75, hip = -0.3, head = 0.1, ra1 = 0.5, ra3 = 1.5, rel = 0.5, rwr = -0.7, la1 = 0.4, la3 = -0.4, lel = 0.8, freeL = 0, footR = -0.6, footL = 0.6, spread = 0.35, breathe = 3, toe = 0.4 },
	-- ...and torn across in front of her, the whole of her going after it
	OHRakeR = { drop = 0.8, lean = 0.6, twist = 0.85, hip = 0.3, head = 0.1, ra1 = 1.45, ra3 = -0.5, rel = 0.1, rwr = 0.5, la1 = -0.3, la3 = -0.6, lel = 0.4, freeL = 0, footR = 0.9, footL = -0.7, spread = 0.35, toe = 0.3 },
	-- ...and carried right through by it: wrapped round herself, low, her head left behind on you
	OHRakeEndR = { drop = 1.05, lean = 0.75, twist = 1.25, hip = 0.5, head = -0.1, look = -0.5, ra1 = 1.0, ra3 = -0.95, rel = 0.5, rwr = 0.7, la1 = -0.6, la3 = -0.9, lel = 0.2, freeL = 0, footR = 1.1, footL = -0.9, spread = 0.4, toe = 0.4 },
	OHRakeEndL = { drop = 1.05, lean = 0.75, twist = -1.25, hip = -0.5, head = -0.1, look = 0.5, la1 = 1.0, la3 = 0.95, lel = 0.5, lwr = 0.7, ra1 = -0.6, ra3 = 0.9, rel = 0.2, freeL = 0, footR = -0.9, footL = 1.1, spread = 0.4, toe = 0.4 },
	-- the slam's talons dragged back out of the sand as she comes up off it
	OHSlamUp = { drop = 0.9, lean = 0.55, head = -0.45, la1 = 0.45, la3 = -0.35, lel = 0.5, ra1 = 0.45, ra3 = 0.35, rel = 0.5, lwr = 0.9, rwr = 0.9, freeL = 0, footR = 0.5, footL = -0.5, spread = 0.5, breathe = 5, toe = 0.4 },
	OHRakeSetL = { drop = 0.6, lean = 0.15, twist = 0.75, hip = 0.3, head = 0.1, la1 = 0.5, la3 = -1.5, lel = 0.5, lwr = -0.7, ra1 = 0.4, ra3 = 0.4, rel = 0.8, freeL = 0, footR = 0.6, footL = -0.6, spread = 0.35, breathe = 3, toe = 0.4 },
	OHRakeL = { drop = 0.8, lean = 0.6, twist = -0.85, hip = -0.3, head = 0.1, la1 = 1.45, la3 = 0.5, lel = 0.1, lwr = 0.5, ra1 = -0.3, ra3 = 0.6, rel = 0.4, freeL = 0, footR = -0.7, footL = 0.9, spread = 0.35, toe = 0.3 },
	-- both talons hoisted right up over her, arched back, up on her toes...
	OHRear = { drop = 0.15, lean = -0.45, head = -0.35, la1 = 2.9, la3 = -0.3, lel = 0.2, ra1 = 2.9, ra3 = 0.3, rel = 0.2, lwr = -0.6, rwr = -0.6, freeL = 0, footR = -0.3, footL = 0.3, spread = 0.3, breathe = 4, toe = 0.7 },
	-- ...and brought down, all of her folded after them into the sand
	OHSlam = { drop = 1.4, lean = 0.9, head = -0.3, la1 = 1.0, la3 = -0.15, lel = 0.1, ra1 = 1.0, ra3 = 0.15, rel = 0.1, lwr = 0.7, rwr = 0.7, freeL = 0, footR = 0.7, footL = -0.7, spread = 0.5, toe = 0.5 },
	-- a hand held out at you, fingers spread: her strings going out of it...
	OHCast = { drop = 0.3, lean = 0.05, twist = 0.3, head = 0.1, ra1 = 1.55, ra3 = 0.15, rel = 0.15, rwr = -0.8, la1 = 0.1, la3 = -0.5, lel = 0.5, freeL = 0, footR = 0.5, footL = -0.5, spread = 0.3, breathe = 3, toe = 0.3 },
	-- ...and wrenched back in to her: the strings drawn taut
	OHYank = { drop = 0.5, lean = -0.3, twist = -0.7, head = -0.1, ra1 = -0.4, ra3 = 0.5, rel = 1.6, rwr = 0.6, la1 = 0.6, la3 = -0.7, lel = 0.6, freeL = 0, footR = -0.6, footL = 0.5, spread = 0.35, toe = 0.2 },
	-- HER THIRD PHASE'S COMING: reeling, both hands up over her face...
	OHClutch = { drop = 0.5, lean = 0.45, head = 0.4, side = 0.1, la1 = 1.9, la3 = 0.35, lel = 2.2, ra1 = 1.9, ra3 = -0.35, rel = 2.2, freeL = 0, footR = -0.4, footL = 0.3, spread = 0.3, breathe = 5, toe = 0.2 },
	-- ...down on her knees with them...
	OHKneel = { drop = 1.45, lean = 0.55, head = 0.45, la1 = 1.9, la3 = 0.35, lel = 2.2, ra1 = 1.9, ra3 = -0.35, rel = 2.2, freeL = 0, footR = 1.0, footL = -1.3, breathe = 5, toe = 0.7 },
	-- ...and her face bared: still on her knees, arms flung wide, head thrown back
	OHBare = { drop = 1.3, lean = -0.3, head = -0.5, la1 = 0.5, la3 = -1.5, lel = 0.2, ra1 = 0.5, ra3 = 1.5, rel = 0.2, lwr = -0.5, rwr = -0.5, freeL = 0, footR = 1.0, footL = -1.3, breathe = 3, toe = 0.7 },
	-- phase 3, between moves: drawn up to her full height under the great hands, her own arms hanging (upright, the
	-- lean taking out her hunch: the great hands are solved on her chest as the server has it, unleaned)
	OHLoom = { drop = 0.1, lean = -0.2, head = 0.2, la1 = 0.1, la3 = -0.3, lel = 0.3, ra1 = 0.1, ra3 = 0.3, rel = 0.3, freeL = 0, breathe = 2.2, footR = 0.2, footL = -0.2, spread = 0.3, lwr = 0.5, rwr = 0.5, toe = 0.2 },
	-- come down off them onto the sand: knees bent under her but her back straight (as OHLoom: the great hands are
	-- planted either side of her), looking down at you
	OHPlant = { drop = 1.0, lean = -0.2, head = 0.35, la1 = 0.2, la3 = -0.7, lel = 0.5, ra1 = 0.2, ra3 = 0.7, rel = 0.5, freeL = 0, breathe = 4, footR = 0.5, footL = -0.5, spread = 0.5, lwr = 0.5, rwr = 0.5, toe = 0.4 },
	-- A LEAP (the pounce, the hounding): off the sand arched back, every limb flung wide, hung spread at the top...
	OHSplay = { drop = 0, lean = -0.4, head = -0.5, la1 = 0.3, la3 = -1.6, lel = 0.1, ra1 = 0.3, ra3 = 1.6, rel = 0.1, lwr = -0.7, rwr = -0.7, freeL = 0, footR = 0.9, footL = -1.0, spread = 1.0, tuck = 0.15, toe = -0.5 },
	-- ...then folded to a point: both talons driven out ahead of her, her legs trailed straight out behind
	OHPierce = { drop = 0.1, lean = 0.5, head = -0.8, la1 = 2.0, la3 = 0.2, lel = 0.05, ra1 = 2.0, ra3 = -0.2, rel = 0.05, lwr = 0.3, rwr = 0.3, freeL = 0, footR = -1.3, footL = -1.0, spread = 0.05, toe = -0.6 },
	OHCastL = { drop = 0.3, lean = 0.05, twist = -0.3, head = 0.1, la1 = 1.55, la3 = -0.15, lel = 0.15, lwr = -0.8, ra1 = 0.1, ra3 = 0.5, rel = 0.5, freeL = 0, footR = -0.5, footL = 0.5, spread = 0.3, breathe = 3, toe = 0.3 },
	-- down on all fours, her face up at you: the skitter (her legs walk under it)
	OHCrawl = { drop = 1.6, lean = 1.15, head = -0.9, la1 = 1.25, la3 = -0.5, lel = 0.5, ra1 = 1.25, ra3 = 0.5, rel = 0.5, lwr = -0.8, rwr = -0.8, footR = 0.4, footL = -0.9, spread = 0.6, breathe = 4, toe = 0.7 },
	-- ...a talon cocked back at her hip, and driven out ahead of her
	OHThrustSet = { drop = 1.1, lean = 0.7, twist = -0.6, head = -0.5, ra1 = -0.6, ra3 = 0.3, rel = 1.5, rwr = -0.5, la1 = 1.0, la3 = -0.3, lel = 0.4, freeL = 0, footR = -0.8, footL = 0.7, spread = 0.4, breathe = 4, toe = 0.6 },
	OHThrust = { drop = 0.9, lean = 0.95, twist = 0.6, head = -0.6, ra1 = 1.55, ra3 = -0.1, rel = 0.05, rwr = 0.3, la1 = -0.7, la3 = -0.5, lel = 0.3, freeL = 0, footR = 1.1, footL = -1.0, spread = 0.3, toe = 0.4 },
	-- the wheel: wound right round, low, arms out; then spun, still sunk right down on her haunches, her arms out and
	-- DOWN from her shoulders so her talons go round at the height of your chest (level, they went over your head)
	OHWheelSet = { drop = 1.5, lean = 0.2, twist = -1.1, hip = -0.6, head = 0.1, la1 = 0.3, la3 = -1.3, lel = 0.3, ra1 = 0.3, ra3 = 1.3, rel = 0.3, freeL = 0, footR = -0.5, footL = 0.5, spread = 0.45, breathe = 4, toe = 0.5 },
	OHWheel = { drop = 1.75, lean = 0.2, head = -0.3, la1 = 0.1, la3 = -1.1, lel = 0.05, ra1 = 0.1, ra3 = 1.1, rel = 0.05, lwr = -0.4, rwr = -0.4, freeL = 0, footR = 0.1, footL = -0.1, spread = 0.5, toe = 0.5 },
	-- between moves: craned right forward at you, one hand lifted, its fingers working
	OHCrane = { drop = 0.6, lean = 0.6, head = -0.55, look = 0.25, side = -0.1, ra1 = 0.9, ra3 = 0.2, rel = 1.3, rwr = -0.6, la1 = 0.15, la3 = -0.3, lel = 0.35, freeL = 0, breathe = 2.6, footR = 0.4, footL = -0.3, spread = 0.35, lwr = 0.6, toe = 0.35 },
	-- phase 3: her head tipped over at you, under the great hands
	OHLoomTilt = { drop = 0.1, lean = -0.2, head = 0.1, side = 0.2, look = -0.25, la1 = 0.1, la3 = -0.3, lel = 0.3, ra1 = 0.3, ra3 = 0.35, rel = 0.7, freeL = 0, breathe = 2.2, footR = 0.2, footL = -0.2, spread = 0.3, lwr = 0.5, rwr = 0.8, toe = 0.2 },
	OHTilt = { drop = 0.3, lean = 0.2, head = 0.05, side = 0.22, look = 0.15, la1 = 0.1, la3 = -0.35, lel = 0.4, ra1 = 0.25, ra3 = 0.4, rel = 0.6, freeL = 0, breathe = 2.2, footR = 0.3, footL = -0.3, spread = 0.35, lwr = 0.6, rwr = 0.8, toe = 0.35 },
}

local C3 = Color3.fromRGB
local ASH, BONE, DARK, EYE = C3(168, 160, 170), C3(196, 188, 176), C3(14, 10, 18), C3(210, 160, 255)
M.Colors = { skin = ASH, torso = ASH, legs = ASH, arms = ASH }

-- an anchor the clients hang a swinging rag of her cloak off (Carrier.cloth): its LookVector the side it hangs out on
local function clothAnchor(p, segs, len, width, color, phys)
	p.Transparency = 1
	for k, v in pairs(phys or {}) do
		p:SetAttribute(k, v)
	end
	p:SetAttribute("Segs", segs)
	p:SetAttribute("Len", len)
	p:SetAttribute("Width", width)
	p:SetAttribute("Color", color)
	CollectionService:AddTag(p, "ClothChain")
end

-- HER FACE: each design dresses the (hidden) Head part. f: deco, oval, V, at, MAT, s, and in head space, unscaled
-- (-Z her front, the neck at y -0.6): bone(a, b, w, color) a rod from point a to b, ball(p, d, color, mat), eye(p, d)
-- a light in a dark socket, chain(points, w, tip) a jointed finger through the points, sc(cf) an unscaled CFrame scaled.
local P = Vector3.new
local PLUM = C3(40, 20, 50)
-- her eye: a ball of bone, the light in its front, a dot of dark in that
local function eyeball(f, e, d)
	f.ball(e, d, BONE, nil, "EyeBall")
	f.ball(e + P(0, 0, -d * 0.33), d * 0.5, EYE, f.MAT.Neon, "Glint")
	f.ball(e + P(0, 0, -d * 0.53), d * 0.2, DARK, nil, "Pupil")
end
-- a strung thread of her light, a to b
local function thread(f, a, b, w)
	local up = math.abs((b - a).Unit.Y) > 0.99 and Vector3.xAxis or Vector3.yAxis
	return f.deco("Head", "Thread", f.V(w, w, (b - a).Magnitude), CFrame.lookAt((a + b) * f.s / 2, b * f.s, up), C3(170, 130, 220), f.MAT.Neon)
end
M.Faces = {
	-- 1. THE BIRDCAGE: no head - a cage of bone bars on her neck, domed and ringed, nothing in it but a knot of dark and
	-- her two lights; three fingers of whatever's kept in there reach out between the bars.
	function(f)
		local bone, ball, chain = f.bone, f.ball, f.chain
		local n = 9
		local function bar(i, r, y)
			local a = i / n * 2 * math.pi
			return P(math.sin(a) * r, y, math.cos(a) * r)
		end
		for i = 0, n - 1 do
			bone(bar(i, 0.5, -0.55), bar(i, 0.53, 0.35), 0.055)
			bone(bar(i, 0.53, 0.35), bar(i, 0.3, 0.78), 0.05)
			bone(bar(i, 0.3, 0.78), P(0, 0.92, 0), 0.045)
			bone(bar(i, 0.5, -0.55), bar(i + 1, 0.5, -0.55), 0.08) -- (the base ring)
			bone(bar(i, 0.53, 0.35), bar(i + 1, 0.53, 0.35), 0.06) -- (the shoulder ring)
		end
		ball(P(0, 0.95, 0), 0.18)
		bone(P(0, 1.0, 0), P(0, 1.25, 0.02), 0.05)
		ball(P(0, 1.28, 0.02), 0.12, DARK)
		ball(P(0, 0.05, 0.05), 0.55, DARK)
		for _, sx in ipairs({ -1, 1 }) do
			ball(P(sx * 0.12, 0.12, -0.22), 0.09, EYE, f.MAT.Neon, "Glint")
		end
		for i, l in ipairs({ 0.55, 0.7, 0.5 }) do
			local x = -0.3 + i * 0.08
			chain({ P(x, -0.2 + i * 0.05, -0.2), P(x - 0.06, -0.15 + i * 0.05, -0.55 - l * 0.3), P(x - 0.1, -0.35 + i * 0.05, -0.62 - l * 0.6) }, 0.05, P(0, -0.14, -0.05))
		end
	end,
	-- 2. THE PRAYER: no head - two long hands rise from her neck in its place and press palm to palm, fingers up past where
	-- her crown would be; her light leaks out of the seam between them.
	function(f)
		local deco, V, at, MAT, bone, ball, chain = f.deco, f.V, f.at, f.MAT, f.bone, f.ball, f.chain
		deco("Head", "Seam", V(0.03, 0.75, 0.42), at(0, 0.05, -0.02), EYE, MAT.Neon)
		for _, sx in ipairs({ -1, 1 }) do
			bone(P(sx * 0.38, -0.8, 0.12), P(sx * 0.1, -0.35, 0.02), 0.13, ASH) -- (the wrists, up from behind her neck)
			deco("Head", "Palm", V(0.1, 0.72, 0.5), at(sx * 0.07, 0.02, 0) * CFrame.Angles(0, 0, -sx * 0.04), ASH:Lerp(BONE, 0.3), MAT.SmoothPlastic)
			for i, z in ipairs({ -0.19, -0.065, 0.065, 0.19 }) do
				local l = ({ 0.75, 1.0, 0.92, 0.6 })[i]
				chain({ P(sx * 0.07, 0.36, z), P(sx * 0.06, 0.36 + l * 0.5, z * 1.05), P(sx * 0.035, 0.36 + l * 0.92, z), P(sx * 0.015, 0.36 + l * 1.2, z * 0.9) }, 0.055, P(-sx * 0.02, 0.1, 0))
			end
			chain({ P(sx * 0.1, -0.2, -0.24), P(sx * 0.1, 0.05, -0.36), P(sx * 0.05, 0.3, -0.38) }, 0.06, P(0, 0.1, 0.02)) -- (the thumbs)
		end
		ball(P(0, 0.32, -0.27), 0.07, EYE, MAT.Neon, "Glint")
		ball(P(0, 0.12, -0.27), 0.06, EYE, MAT.Neon, "Glint")
	end,
	-- 3. THE BLOOM: from her neck stump a ring of long jointed fingers grows up and splays open like a flower, every one
	-- a different length; cradled in the middle of them, one great eye.
	function(f)
		local deco, V, at, MAT, ball, chain = f.deco, f.V, f.at, f.MAT, f.ball, f.chain
		local rng = Random.new(31)
		for i = 0, 6 do
			local a = i / 7 * 2 * math.pi + 0.25
			local c, sn = math.sin(a), math.cos(a)
			local l = rng:NextNumber(0.75, 1.2)
			chain({ P(c * 0.12, -0.5, sn * 0.12), P(c * 0.38, 0.05, sn * 0.38), P(c * 0.55 * l, 0.15 + 0.5 * l, sn * 0.55 * l), P(c * 0.75 * l, 0.25 + 0.75 * l, sn * 0.75 * l) }, 0.075, P(c * 0.16, -0.08, sn * 0.16))
		end
		ball(P(0, 0.2, 0.02), 0.62, DARK)
		ball(P(0, 0.2, -0.1), 0.42, BONE:Lerp(DARK, 0.15), nil, "EyeBall")
		ball(P(0, 0.2, -0.24), 0.24, EYE, MAT.Neon, "Glint")
		deco("Head", "Pupil", V(0.05, 0.2, 0.04), at(0, 0.2, -0.35), DARK, MAT.SmoothPlastic)
	end,
	-- 4. THE LURE: no head - her neck just goes on, a stalk of vertebrae arching up and forward over her, and from its end
	-- a single violet light hangs on a thread, like an angler's.
	function(f)
		local bone, ball, MAT = f.bone, f.ball, f.MAT
		local pts = { P(0, -0.55, 0.05), P(0, -0.05, 0.02), P(0, 0.42, -0.1), P(0, 0.78, -0.36), P(0, 0.94, -0.72), P(0, 0.86, -1.08), P(0, 0.62, -1.34) }
		for i, p in ipairs(pts) do
			local d = 0.32 - i * 0.025
			ball(p, d, ASH, nil, "Vertebra")
			bone(p, p + P(0, d * 0.75, d * 0.4), 0.05, BONE:Lerp(DARK, 0.35), "Spine")
			if pts[i + 1] then
				bone(p, pts[i + 1], 0.12, BONE)
			end
		end
		bone(pts[#pts], P(0, -0.2, -1.38), 0.025, DARK, "Thread")
		ball(P(0, -0.34, -1.38), 0.3, EYE, MAT.Neon, "Lure")
		ball(P(0, -0.34, -1.38), 0.36, DARK, nil, "LureHusk").Transparency = 0.6
	end,
	-- 5. THE SPLIT: her head split down the middle, the halves hinged apart like a cracked shell; teeth all along both
	-- inner edges, strands of rot still strung across the gap, and three eyes stacked inside, looking out.
	function(f)
		local deco, V, MAT, bone, ball, eye, sc = f.deco, f.V, f.MAT, f.bone, f.ball, f.eye, f.sc
		deco("Head", "Inside", V(0.22, 1.0, 0.55), sc(CFrame.new(0, 0.1, 0.08)), DARK, MAT.SmoothPlastic)
		local H = {}
		for _, sx in ipairs({ -1, 1 }) do
			local h = CFrame.new(sx * 0.06, -0.5, 0) * CFrame.Angles(0, 0, -sx * 0.42)
			H[sx] = h
			deco("Head", "Half", V(0.3, 1.1, 0.85), sc(h * CFrame.new(sx * 0.17, 0.55, 0)), ASH, MAT.SmoothPlastic)
			deco("Head", "HalfInner", V(0.02, 1.0, 0.75), sc(h * CFrame.new(sx * 0.01, 0.55, 0)), PLUM, MAT.SmoothPlastic)
			for i = 1, 7 do
				local y = 0.12 + i * 0.13
				bone(h * P(0, y, -0.38), h * P(-sx * 0.14, y - 0.03, -0.4), 0.04, BONE, "Tooth")
			end
		end
		for _, y in ipairs({ 0.35, 0.62, 0.9 }) do
			bone(H[-1] * P(0, y, 0.1), H[1] * P(0, y - 0.08, 0.1), 0.02, PLUM, "Strand")
		end
		eye(P(0, -0.05, -0.22), 0.1)
		eye(P(0, 0.25, -0.22), 0.14)
		eye(P(0, 0.58, -0.22), 0.08)
	end,
	-- 6. THE FRAME: where her head should be, an empty ring of bone held up on two long fingers, and in the middle of the
	-- nothing one eye, strung up by threads to the ring.
	function(f)
		local bone, ball, chain, MAT = f.bone, f.ball, f.chain, f.MAT
		local c, r, n = P(0, 0.3, 0), 0.62, 16
		local function ring(i)
			local a = i / n * 2 * math.pi
			return c + P(math.sin(a) * r, math.cos(a) * r, 0)
		end
		for i = 0, n - 1 do
			bone(ring(i), ring(i + 1), 0.1)
			if i % 4 == 0 then
				ball(ring(i), 0.16)
			end
		end
		for _, sx in ipairs({ -1, 1 }) do
			chain({ P(sx * 0.1, -0.7, 0.1), P(sx * 0.32, -0.45, 0.06), P(sx * 0.48, -0.12, 0.0), P(sx * 0.42, -0.02, -0.12) }, 0.075, P(-sx * 0.05, 0.08, 0.04))
		end
		local e = c + P(0, -0.05, 0)
		bone(ring(0), e, 0.02, DARK, "Thread")
		for _, i in ipairs({ 3, 6, 10, 13 }) do
			bone(ring(i), e, 0.015, DARK, "Thread")
		end
		ball(e, 0.36, BONE, nil, "EyeBall")
		ball(e + P(0, 0, -0.12), 0.18, EYE, MAT.Neon, "Glint")
		ball(e + P(0, 0, -0.19), 0.07, DARK, nil, "Pupil")
	end,
	-- 7. THE TOTEM: three small masks stacked on a spine, each tipped its own way - one smiling, one weeping light, one
	-- screaming.
	function(f)
		local deco, V, MAT, bone, sc = f.deco, f.V, f.MAT, f.bone, f.sc
		bone(P(0, -0.65, 0.12), P(0, 1.2, 0.12), 0.08, BONE:Lerp(DARK, 0.4), "Spine")
		local function mask(pos, d, roll, color)
			local m = CFrame.new(pos) * CFrame.Angles(0.08, 0, roll)
			deco("Head", "Mask", V(0.09, d, d), sc(m * CFrame.Angles(0, math.pi / 2, 0)), color, MAT.SmoothPlastic, Enum.PartType.Cylinder)
			return function(name, size, x, y, rz, c, mat)
				deco("Head", name, V(size.X, size.Y, 0.03), sc(m * CFrame.new(x, y, -0.05) * CFrame.Angles(0, 0, rz or 0)), c or DARK, mat or MAT.SmoothPlastic)
			end
		end
		local top = mask(P(0.02, 0.92, 0.02), 0.5, 0.28, C3(214, 208, 200))
		for _, sx in ipairs({ -1, 1 }) do
			top("Eye", P(0.12, 0.03), sx * 0.1, 0.06, -sx * 0.4)
			top("Smile", P(0.08, 0.03), sx * 0.07, -0.12, sx * 0.45)
		end
		top("Smile", P(0.08, 0.03), 0, -0.14)
		local mid = mask(P(0.04, 0.38, -0.02), 0.62, -0.16, BONE)
		for _, sx in ipairs({ -1, 1 }) do
			mid("Glint", P(0.08, 0.05), sx * 0.13, 0.08, 0, EYE, MAT.Neon)
			mid("Tear", P(0.03, 0.26), sx * 0.13, -0.12, 0, EYE, MAT.Neon)
		end
		local low = mask(P(-0.03, -0.2, 0.0), 0.55, 0.1, ASH)
		for _, sx in ipairs({ -1, 1 }) do
			low("Eye", P(0.08, 0.08), sx * 0.12, 0.09, 0.785)
		end
		low("Scream", P(0.12, 0.24), 0, -0.1)
	end,
	-- 8. THE MOTH: a small dark knot of a head, and spread out from it either side two great fans of thin bone, webbed
	-- with something grey and torn, each with a violet eye-spot staring out of it.
	function(f)
		local deco, V, MAT, bone, ball = f.deco, f.V, f.MAT, f.bone, f.ball
		bone(P(0, -0.5, 0.03), P(0, -0.05, 0), 0.13, ASH, "Neck")
		ball(P(0, 0.05, 0), 0.48, DARK)
		for _, sx in ipairs({ -1, 1 }) do
			ball(P(sx * 0.1, 0.1, -0.2), 0.07, EYE, MAT.Neon, "Glint")
			local o = P(sx * 0.12, 0.15, 0.05)
			local ends = {}
			for i = 0, 6 do
				local t = i / 6
				local a, l = 0.15 + t * 1.35, 1.35 + 0.55 * math.sin(t * math.pi)
				ends[i] = o + P(sx * math.cos(a) * l, math.sin(a) * l, 0.15 * l)
				bone(o, ends[i], 0.04, BONE, "Rib")
				ball(ends[i], 0.07, DARK, nil, "RibTip")
			end
			for i = 0, 5 do -- (the web between each two ribs, out to most of the way along them)
				local tip = (ends[i] + ends[i + 1]) / 2
				local d = tip - o
				local w = (ends[i] - ends[i + 1]).Magnitude * 0.55
				local web = deco("Head", "Web", V(w, 0.015, d.Magnitude * 0.92), CFrame.lookAt((o + d * 0.46) * f.s, tip * f.s, Vector3.zAxis), C3(92, 84, 96):Lerp(PLUM, (i % 2) * 0.5), MAT.SmoothPlastic)
				web.Transparency = 0.15
			end
			local spot = o + (ends[3] - o) * 0.62 + P(0, 0, -0.04)
			ball(spot, 0.26, DARK, nil, "Spot")
			ball(spot + P(0, 0, -0.06), 0.15, EYE, MAT.Neon, "SpotGlint")
		end
	end,
	-- 9. THE ROOTS: no face - a crown of dark wood, and hung from it a curtain of long thin roots down past her neck and
	-- onto her chest; somewhere behind them, two lights.
	function(f)
		local deco, V, at, MAT, bone, ball = f.deco, f.V, f.at, f.MAT, f.bone, f.ball
		local rng = Random.new(77)
		deco("Head", "Crown", V(0.14, 1.05, 1.05), at(0, 0.78, 0) * CFrame.Angles(0, 0, math.pi / 2), DARK, MAT.SmoothPlastic, Enum.PartType.Cylinder)
		ball(P(0, 0.2, 0.05), 0.72, DARK)
		for _, sx in ipairs({ -1, 1 }) do
			ball(P(sx * 0.13, 0.32, -0.3), 0.09, EYE, MAT.Neon, "Glint")
		end
		for i = 0, 23 do
			local a = i / 24 * 2 * math.pi + rng:NextNumber(-0.08, 0.08)
			local r = rng:NextNumber(0.42, 0.5)
			local c, sn = math.sin(a), math.cos(a)
			local p1 = P(c * r, 0.74, sn * r)
			local p2 = P(c * r * 0.95 + rng:NextNumber(-0.04, 0.04), 0.05, sn * r * 0.95)
			local p3 = P(c * r * 1.05 + rng:NextNumber(-0.06, 0.06), -0.55 - rng:NextNumber(0, 0.7), sn * r * 1.05 - 0.05)
			local col = DARK:Lerp(PLUM, rng:NextNumber()):Lerp(ASH, rng:NextNumber(0, 0.25))
			local w = rng:NextNumber(0.035, 0.055)
			bone(p1, p2, w, col, "Root")
			bone(p2, p3, w * 0.75, col, "Root")
		end
	end,
	-- 10. THE NAILED: a small black knot of a thing run through with long bone pins in every direction, their heads
	-- standing out of it like a pincushion; between them, three lights.
	function(f)
		local bone, ball, MAT = f.bone, f.ball, f.MAT
		local rng = Random.new(5)
		local c = P(0, 0.15, 0)
		bone(P(0, -0.5, 0.03), P(0, -0.05, 0), 0.13, ASH, "Neck")
		ball(c, 0.62, DARK)
		local placed = 0
		while placed < 17 do
			local d = P(rng:NextNumber(-1, 1), rng:NextNumber(-0.6, 1), rng:NextNumber(-1, 1))
			if d.Magnitude > 0.3 and d.Unit.Z > -0.55 then -- (keep her front clear for the lights)
				d = d.Unit
				local l = rng:NextNumber(0.55, 1.25)
				bone(c - d * 0.2, c + d * l, rng:NextNumber(0.035, 0.055), BONE, "Pin")
				ball(c + d * l, 0.11, C3(40, 36, 44), MAT.Metal, "PinHead")
				placed += 1
			end
		end
		for _, e in ipairs({ { -0.13, 0.27, 0.1 }, { 0.12, 0.2, 0.08 }, { 0.0, 0.0, 0.065 } }) do
			ball(P(e[1], e[2], -0.27), e[3], EYE, MAT.Neon, "Glint")
		end
	end,
	-- 11. THE HELD FACE (the earlier pick, kept to compare): a hollow of black where her face should be, her two lights
	-- far back in it, and a long hand of bone reaching up over her head, its five fingers curled down across the dark.
	function(f)
		local deco, oval, V, at, MAT = f.deco, f.oval, f.V, f.at, f.MAT
		oval("Void", V(0.82, 1.45, 0.85), at(0, 0.3, 0), DARK)
		for _, sx in ipairs({ -1, 1 }) do
			deco("Head", "Glint", V(0.09, 0.09, 0.09), at(sx * 0.14, 0.35, -0.41), EYE, MAT.Neon, Enum.PartType.Ball) -- (just out of the dark's face: any further back and it hides them)
		end
		deco("Head", "Palm", V(0.6, 0.7, 0.12), at(0, 0.1, 0.5), BONE, MAT.SmoothPlastic)
		for i = 1, 5 do
			local x = (i - 3) * 0.14
			local l = 1 - math.abs(i - 3) * 0.15 -- (the middle finger longest, reaching furthest down the face)
			deco("Head", "Finger" .. i, V(0.07, 0.75, 0.07), at(x, 0.75, 0.48), BONE, MAT.SmoothPlastic)
			deco("Head", "Knuckle" .. i, V(0.1, 0.1, 0.1), at(x, 1.12, 0.42), BONE, MAT.SmoothPlastic, Enum.PartType.Ball)
			deco("Head", "FingerTop" .. i, V(0.07, 0.07, 0.84), at(x, 1.12, 0), BONE, MAT.SmoothPlastic)
			deco("Head", "Knuckle" .. i, V(0.1, 0.1, 0.1), at(x, 1.12, -0.42), BONE, MAT.SmoothPlastic, Enum.PartType.Ball)
			deco("Head", "FingerDown" .. i, V(0.06, 0.8 * l, 0.06), at(x, 1.12 - 0.4 * l, -0.46), BONE, MAT.SmoothPlastic)
			deco("Head", "FingerTip" .. i, V(0.05, 0.2, 0.05), at(x, 1.12 - 0.8 * l - 0.06, -0.4) * CFrame.Angles(0.7, 0, 0), DARK, MAT.SmoothPlastic)
		end
	end,
	-- 12. THE LILY: a double bloom - a short inner ring of fingers cupped up around the eye, and a long outer ring opened
	-- right out, curling over and down at the tips like a lily's petals.
	function(f)
		local chain = f.chain
		for i = 0, 4 do
			local a = i / 5 * 2 * math.pi
			local c, sn = math.sin(a), math.cos(a)
			chain({ P(c * 0.1, -0.45, sn * 0.1), P(c * 0.27, 0.08, sn * 0.27), P(c * 0.3, 0.48, sn * 0.3) }, 0.06, P(-c * 0.06, 0.1, -sn * 0.06))
		end
		local rng = Random.new(12)
		for i = 0, 6 do
			local a = i / 7 * 2 * math.pi + 0.45
			local c, sn = math.sin(a), math.cos(a)
			local l = rng:NextNumber(0.85, 1.15)
			chain({ P(c * 0.14, -0.5, sn * 0.14), P(c * 0.45 * l, 0.0, sn * 0.45 * l), P(c * 0.78 * l, 0.42 * l, sn * 0.78 * l), P(c * 1.0 * l, 0.32 * l, sn * 1.0 * l) }, 0.07, P(c * 0.04, -0.16, sn * 0.04))
		end
		eyeball(f, P(0, 0.3, -0.02), 0.42)
	end,
	-- 13. THE CRADLE: one great hand where her head was, palm up, holding her eye like an egg - its fingers reaching up
	-- from behind and over the top, the thumb curled round the front.
	function(f)
		local deco, V, at, MAT, bone, chain = f.deco, f.V, f.at, f.MAT, f.bone, f.chain
		bone(P(0, -0.6, 0.18), P(0, -0.24, 0.16), 0.16, ASH, "Wrist")
		deco("Head", "Palm", V(0.62, 0.1, 0.6), at(0, -0.2, 0), ASH:Lerp(BONE, 0.3), MAT.SmoothPlastic)
		for i, x in ipairs({ -0.24, -0.08, 0.08, 0.24 }) do
			local l = ({ 0.85, 1.05, 1.0, 0.8 })[i]
			chain({ P(x, -0.2, 0.27), P(x * 1.25, 0.2 * l, 0.38), P(x * 1.15, 0.62 * l, 0.18), P(x * 0.9, 0.74 * l, -0.18) }, 0.07, P(0, -0.16, -0.05))
		end
		chain({ P(0.3, -0.2, 0.02), P(0.42, 0.05, -0.22), P(0.26, 0.2, -0.36) }, 0.075, P(-0.1, 0.02, -0.03)) -- (the thumb)
		eyeball(f, P(0, 0.15, -0.04), 0.46)
	end,
	-- 14. THE SPOKES: the Frame's ring, but every spoke of it a finger, jointed, all reaching in to the eye in the middle
	-- and stopping just short of touching it.
	function(f)
		local bone, ball, chain = f.bone, f.ball, f.chain
		local c, r, n = P(0, 0.3, 0), 0.65, 16
		local function ring(i)
			local a = i / n * 2 * math.pi
			return c + P(math.sin(a) * r, math.cos(a) * r, 0)
		end
		for i = 0, n - 1 do
			bone(ring(i), ring(i + 1), 0.1)
		end
		bone(P(0, -0.55, 0.06), ring(n / 2), 0.13, BONE, "Stalk")
		for i = 0, n - 1, 2 do
			local rp = ring(i)
			local to = c - rp
			ball(rp, 0.15)
			chain({ rp, rp + to * 0.45 + P(0, 0, -0.12), rp + to * 0.68 + P(0, 0, -0.06) }, 0.055, to.Unit * 0.07)
		end
		eyeball(f, c, 0.32)
	end,
	-- 15. THE ORRERY: her eye on a stalk of bone, and two rings of bone swung round it at angles to each other, like the
	-- bands of an armillary sphere.
	function(f)
		local bone, ball = f.bone, f.ball
		local c = P(0, 0.3, 0)
		bone(P(0, -0.55, 0.06), c - P(0, 0.2, -0.02), 0.13, BONE, "Stalk")
		for k, ring in ipairs({ { CFrame.Angles(0, 0.7, 0.3), 0.56 }, { CFrame.Angles(1.25, 0, -0.4), 0.66 }, { CFrame.Angles(0.2, -0.9, -1.1), 0.46 } }) do
			local R, r, n = ring[1], ring[2], 18
			local function pt(i)
				local a = i / n * 2 * math.pi
				return c + R:VectorToWorldSpace(P(math.sin(a) * r, math.cos(a) * r, 0))
			end
			for i = 0, n - 1 do
				bone(pt(i), pt(i + 1), 0.08 - k * 0.01)
				if i % 6 == 0 then
					ball(pt(i), 0.13)
				end
			end
		end
		eyeball(f, c, 0.36)
	end,
	-- 16. THE SHUTTER: a ring of bone, and inside it ten fingers curled in from the rim one over the next, closing like the
	-- blades of an iris; in the small gap they leave at the centre, her eye.
	function(f)
		local bone, chain = f.bone, f.chain
		local c, r, n = P(0, 0.3, 0), 0.62, 16
		local function at2(rad, a, z)
			return c + P(math.sin(a) * rad, math.cos(a) * rad, z)
		end
		for i = 0, n - 1 do
			bone(at2(r, i / n * 2 * math.pi, 0), at2(r, (i + 1) / n * 2 * math.pi, 0), 0.1)
		end
		for i = 0, 9 do
			local a = i / 10 * 2 * math.pi
			chain({ at2(r, a, -0.02), at2(0.42, a + 0.55, -0.06 - i * 0.004), at2(0.2, a + 1.15, -0.09 - i * 0.004) }, 0.06, (at2(0.12, a + 1.6, -0.1) - at2(0.2, a + 1.15, -0.1)))
		end
		for _, sx in ipairs({ -1, 1 }) do
			chain({ P(sx * 0.1, -0.7, 0.1), P(sx * 0.32, -0.45, 0.06), P(sx * 0.48, -0.12, 0.0), P(sx * 0.42, -0.02, -0.12) }, 0.075, P(-sx * 0.05, 0.08, 0.04))
		end
		eyeball(f, c + P(0, 0, 0.04), 0.26)
	end,
	-- 17. THE BUD: the Bloom closed - its fingers rise and curve back in, their tips almost meeting over the top, a cage of
	-- them around her eye; one missing at the front, so it can look out.
	function(f)
		local chain = f.chain
		local rng = Random.new(17)
		for i = 0, 6 do
			if i ~= 0 then -- (the gap at the front)
				local a = i / 7 * 2 * math.pi + math.pi
				local c, sn = math.sin(a), math.cos(a)
				local l = rng:NextNumber(0.92, 1.08)
				chain({ P(c * 0.12, -0.5, sn * 0.12), P(c * 0.46, -0.05, sn * 0.46), P(c * 0.5 * l, 0.42 * l, sn * 0.5 * l), P(c * 0.24, 0.74 * l, sn * 0.24) }, 0.075, P(-c * 0.1, -0.05, -sn * 0.1))
			end
		end
		eyeball(f, P(0, 0.18, -0.04), 0.46)
	end,
	-- 18. THE CLAW: a stalk of bone up her back and over, and from the top of it a hand hanging down like a crane's grab,
	-- its fingers curled in underneath her eye, holding it up in front of her.
	function(f)
		local bone, ball, chain = f.bone, f.ball, f.chain
		local top = P(0, 1.02, -0.02)
		bone(P(0, -0.55, 0.2), P(0, 0.85, 0.28), 0.13, BONE, "Stalk")
		bone(P(0, 0.85, 0.28), top, 0.11, BONE, "Stalk")
		ball(P(0, 0.85, 0.28), 0.17)
		ball(top, 0.2)
		for i = 0, 4 do
			local a = i / 5 * 2 * math.pi + math.pi / 5 -- (none dead centre at the front, so the eye shows)
			local c, sn = math.sin(a), math.cos(a)
			chain({ top, P(c * 0.38, 0.86, sn * 0.38 - 0.02), P(c * 0.5, 0.36, sn * 0.5 - 0.02), P(c * 0.24, -0.06, sn * 0.24 - 0.02) }, 0.07, P(-c * 0.08, 0.06, -sn * 0.08))
		end
		eyeball(f, P(0, 0.3, -0.02), 0.44)
	end,
	-- 19. THE CROWN OF EYES: the Frame's ring held up on its two fingers, but empty in the middle - the eyes are set all
	-- round the ring itself, eight of them, and every one looking at you.
	function(f)
		local bone, ball, chain = f.bone, f.ball, f.chain
		local c, r, n = P(0, 0.3, 0), 0.62, 16
		local function ring(i)
			local a = i / n * 2 * math.pi
			return c + P(math.sin(a) * r, math.cos(a) * r, 0)
		end
		for i = 0, n - 1 do
			bone(ring(i), ring(i + 1), 0.09)
		end
		for _, sx in ipairs({ -1, 1 }) do
			chain({ P(sx * 0.1, -0.7, 0.1), P(sx * 0.32, -0.45, 0.06), P(sx * 0.48, -0.12, 0.0), P(sx * 0.42, -0.02, -0.12) }, 0.075, P(-sx * 0.05, 0.08, 0.04))
		end
		for i = 0, n - 1, 2 do
			eyeball(f, ring(i) + P(0, 0, -0.04), i % 4 == 0 and 0.22 or 0.17)
		end
		for _, i in ipairs({ 0, 4, 8, 12 }) do
			bone(ring(i), c, 0.015, DARK, "Thread")
		end
		ball(c, 0.1, DARK, nil, "Knot")
	end,
	-- 20. THE WILT: the Bloom gone over - its fingers droop out and down like a dead flower's petals, and her eye hangs
	-- forward off a bent stalk in the middle of them, looking down at you.
	function(f)
		local bone, ball, chain = f.bone, f.ball, f.chain
		local rng = Random.new(20)
		for i = 0, 6 do
			local a = i / 7 * 2 * math.pi + 0.45
			local c, sn = math.sin(a), math.cos(a)
			local l = rng:NextNumber(0.85, 1.15)
			chain({ P(c * 0.1, -0.45, sn * 0.1), P(c * 0.3, 0.3, sn * 0.3), P(c * 0.6 * l, 0.52, sn * 0.6 * l), P(c * 0.85 * l, 0.2, sn * 0.85 * l), P(c * 0.9 * l, -0.25 * l, sn * 0.9 * l) }, 0.07, P(c * 0.02, -0.15, sn * 0.02))
		end
		bone(P(0, -0.45, 0.02), P(0, 0.4, 0.04), 0.11, BONE, "Stalk")
		bone(P(0, 0.4, 0.04), P(0, 0.62, -0.18), 0.09, BONE, "Stalk")
		ball(P(0, 0.4, 0.04), 0.14)
		local e = P(0, 0.5, -0.32)
		eyeball(f, e, 0.38)
		bone(e - P(0, 0.18, 0), e - P(0, 0.42, -0.02), 0.03, PLUM, "Drip")
	end,
	-- 21. THE SUNBURST: her eye at the centre of a great halo of fingers fanned out behind it in every direction but
	-- down, long and short by turns, each jointed and curled at its tip.
	function(f)
		local deco, V, MAT, chain = f.deco, f.V, f.MAT, f.chain
		local o = P(0, 0.25, 0.15)
		f.bone(P(0, -0.55, 0.08), o, 0.13, BONE, "Stalk")
		deco("Head", "Disc", V(0.06, 0.62, 0.62), CFrame.new(o * f.s) * CFrame.Angles(0, math.pi / 2, 0), DARK, MAT.SmoothPlastic, Enum.PartType.Cylinder)
		for i = 0, 14 do
			local a = math.rad(-35 + i * (250 / 14))
			local dir = P(math.cos(a), math.sin(a), 0)
			local perp = P(-dir.Y, dir.X, 0)
			local L = i % 2 == 0 and 1.05 or 0.78
			chain({ o + dir * 0.25, o + dir * 0.62 * L + P(0, 0, 0.02), o + dir * L + perp * 0.08 + P(0, 0, -0.04) }, 0.06, dir * 0.08 + perp * 0.06)
		end
		eyeball(f, P(0, 0.25, -0.1), 0.46)
	end,
	-- 22..26: FIVE MORE FOR HER SECOND PHASE, none with a mass of dark to it: bone, thread and her lights only.
	-- 22. THE SHUT FAN (her third phase's face before it opens): the same fan of fingers off the same hub, but every one
	-- folded forward and closed over her eye like a hand over a candle; its light gets out between them.
	function(f)
		local deco, V, MAT, bone, chain = f.deco, f.V, f.MAT, f.bone, f.chain
		local o = P(0, 0.25, 0.15)
		bone(P(0, -0.55, 0.08), o, 0.13, BONE, "Stalk")
		deco("Head", "Disc", V(0.06, 0.5, 0.5), CFrame.new(o * f.s) * CFrame.Angles(0, math.pi / 2, 0), DARK, MAT.SmoothPlastic, Enum.PartType.Cylinder)
		for i = 0, 14 do
			local a = math.rad(-35 + i * (250 / 14))
			local dir = P(math.cos(a), math.sin(a), 0)
			local L = i % 2 == 0 and 1 or 0.8
			chain({ o + dir * 0.25, o + dir * 0.5 * L + P(0, 0, -0.34), P(0, 0.25, -0.7 * L) + dir * 0.13 }, 0.06, P(0, 0, -0.07) - dir * 0.07)
		end
		eyeball(f, P(0, 0.25, -0.1), 0.4)
	end,
	-- 23. THE CAT'S CRADLE: no head - two small hands up out of her neck on long wrists, a cat's cradle of her strings
	-- held taut between their fingers; her two lights are beads on one thread of it.
	function(f)
		local bone, ball, chain, MAT = f.bone, f.ball, f.chain, f.MAT
		local tips = { [-1] = {}, [1] = {} }
		for _, sx in ipairs({ -1, 1 }) do
			local palm = P(sx * 0.46, 0.12, 0)
			bone(P(sx * 0.1, -0.55, 0.06), palm, 0.1, ASH, "Wrist")
			ball(palm, 0.17)
			for i = 0, 3 do
				local tip = palm + P(sx * 0.04, 0.42 + i * 0.13, -0.3 + i * 0.17)
				chain({ palm, palm + P(sx * 0.14, 0.2 + i * 0.08, -0.2 + i * 0.12), tip }, 0.05, P(-sx * 0.05, 0.05, 0))
				tips[sx][i] = tip
			end
		end
		for i = 0, 3 do
			thread(f, tips[-1][i], tips[1][i], 0.018)
			thread(f, tips[-1][i], tips[1][3 - i], 0.018)
		end
		ball((tips[-1][1] + tips[1][2]) / 2, 0.07, DARK, nil, "Knot")
		ball(tips[-1][1]:Lerp(tips[1][1], 0.34), 0.11, EYE, MAT.Neon, "Glint")
		ball(tips[-1][1]:Lerp(tips[1][1], 0.66), 0.11, EYE, MAT.Neon, "Glint")
	end,
	-- 24. THE MARIONETTE: no head - a puppeteer's cross of dark wood hung in the air over the stump of her neck, tipped,
	-- on one string going up; its own strings come down to her shoulders and her neck, and off its front bar her two
	-- lights hang on theirs, at different lengths. She's on strings too.
	function(f)
		local bone, ball, MAT = f.bone, f.ball, f.MAT
		local WOOD = C3(58, 44, 38)
		ball(P(0, -0.4, 0.02), 0.2, ASH, nil, "Stump")
		local L, R, F, B = P(-0.62, 1.1, 0), P(0.62, 0.94, 0), P(0, 1.0, -0.52), P(0, 1.04, 0.42)
		local FL, FR = F + P(-0.3, 0.03, 0), F + P(0.3, -0.03, 0)
		bone(L, R, 0.09, WOOD, "Bar")
		bone(F, B, 0.09, WOOD, "Bar")
		bone(FL, FR, 0.07, WOOD, "Bar")
		ball(P(0, 1.02, 0), 0.14, WOOD, nil, "Boss")
		thread(f, P(0, 1.08, 0), P(0, 2.3, 0), 0.015)
		thread(f, L, P(-0.72, -0.8, 0.05), 0.015)
		thread(f, R, P(0.72, -0.8, 0.05), 0.015)
		thread(f, B, P(0, -0.4, 0.1), 0.015)
		for _, e in ipairs({ { FL, P(-0.2, 0.3, -0.46) }, { FR, P(0.2, 0.1, -0.5) } }) do
			thread(f, e[1], e[2], 0.015)
			ball(e[2], 0.13, EYE, MAT.Neon, "Glint")
		end
	end,
	-- 25. THE CROWNED VEIL: no head - her crown, tarnished, one point gone, hung level in the air where her brow would
	-- be, and a veil of fine threads hanging off it all the way round, past the stump of her neck; her two lights behind them.
	function(f)
		local bone, ball, MAT = f.bone, f.ball, f.MAT
		local GILT = C3(120, 96, 52)
		local rng = Random.new(25)
		local n, r, y = 14, 0.5, 0.78
		local function ring(i)
			local a = i / n * 2 * math.pi
			return P(math.sin(a) * r, y + math.sin(a) * 0.06, -math.cos(a) * r)
		end
		for i = 0, n - 1 do
			bone(ring(i), ring(i + 1), 0.07, GILT:Lerp(C3(40, 34, 30), rng:NextNumber(0, 0.5)), "Crown")
			if i % 2 == 0 and i ~= 6 then
				bone(ring(i), ring(i) + P(0, i == 0 and 0.4 or 0.24, 0), 0.05, GILT, "CrownPoint")
			end
		end
		for i = 0, 27 do
			local a = (i + rng:NextNumber(-0.3, 0.3)) / 28 * 2 * math.pi
			local top = P(math.sin(a) * r * 0.96, y, -math.cos(a) * r * 0.96)
			bone(top, top + P(math.sin(a) * 0.06, -rng:NextNumber(1.0, 1.75), -math.cos(a) * 0.06), 0.022, DARK:Lerp(ASH, rng:NextNumber(0.1, 0.6)), "Veil")
		end
		ball(P(0, -0.4, 0.02), 0.2, ASH, nil, "Stump")
		for _, sx in ipairs({ -1, 1 }) do
			ball(P(sx * 0.13, 0.22, -0.2), 0.1, EYE, MAT.Neon, "Glint")
		end
	end,
	-- 26. THE SIX WICKS (the one she wears): no head - her neck forks into six long jointed fingers, each a different
	-- height, and on the tip of each one a flame of her light stands, like a candle held up.
	function(f)
		local ball, chain, MAT = f.ball, f.chain, f.MAT
		for _, w in ipairs({ { 0.05, 1.35, -0.1 }, { -0.3, 1.1, 0.14 }, { 0.3, 0.98, 0.1 }, { -0.55, 0.8, -0.1 }, { 0.58, 0.62, -0.16 }, { -0.12, 0.6, -0.3 } }) do
			local x, top, z = w[1], w[2], w[3]
			local tip = P(x, top, z)
			chain({ P(x * 0.2, -0.5, 0.04), P(x * 0.75, -0.5 + (top + 0.5) * 0.4, z * 0.3 + 0.08), P(x * 1.1, -0.5 + (top + 0.5) * 0.75, z * 0.8), tip }, 0.07, P(0, 0.07, 0))
			ball(tip + P(0, 0.15, 0), 0.15, EYE, MAT.Neon, "Glint")
			ball(tip + P(0, 0.28, 0), 0.08, C3(232, 214, 255), MAT.Neon, "Flame")
		end
	end,
}
M.Face = 26 -- (which of M.Faces she wears)

-- her face (design n of M.Faces) dressed onto the Head with deco (RigBuilder's; or liveDeco's, on a rig that's already
-- up: her third phase bares another). Every piece of it is marked "Face", so it can be taken off her again.
local function dressFace(n, deco, s)
	local MAT = Enum.Material
	local function fdeco(...)
		local p = deco(...)
		p:SetAttribute("Face", true)
		return p
	end
	local function V(x, y, z)
		return Vector3.new(x, y, z) * s
	end
	local function bone(a, b, w, c, name)
		local d = b - a
		local up = math.abs(d.Unit.Y) > 0.99 and Vector3.xAxis or Vector3.yAxis
		return fdeco("Head", name or "Bone", V(w, w, d.Magnitude), CFrame.lookAt((a + b) * s / 2, b * s, up), c or BONE, MAT.SmoothPlastic)
	end
	local function ball(p, d, c, mat, name)
		return fdeco("Head", name or "Knob", V(d, d, d), CFrame.new(p * s), c or BONE, mat or MAT.SmoothPlastic, Enum.PartType.Ball)
	end
	M.Faces[n]({
		deco = fdeco, V = V, MAT = MAT, s = s, bone = bone, ball = ball,
		at = function(x, y, z)
			return CFrame.new(x * s, y * s, z * s)
		end,
		oval = function(name, size, cf, color)
			local p = fdeco("Head", name, size, cf, color, MAT.SmoothPlastic)
			local m = Instance.new("SpecialMesh")
			m.MeshType = Enum.MeshType.Sphere
			m.Parent = p
			return p
		end,
		eye = function(p, d)
			ball(p, d * 1.7, DARK, nil, "Socket")
			ball(p - Vector3.new(0, 0, d * 0.5), d, EYE, MAT.Neon, "Glint")
		end,
		chain = function(pts, w, tip) -- (bones through the points, knuckles between, a dark talon off the end)
			for i = 1, #pts - 1 do
				bone(pts[i], pts[i + 1], w * (1 - 0.12 * (i - 1)))
				if i > 1 then
					ball(pts[i], w * 1.45)
				end
			end
			bone(pts[#pts], pts[#pts] + tip, w * 0.65, DARK, "Talon")
		end,
		sc = function(cf)
			return cf.Rotation + cf.Position * s
		end,
	})
end

function M.Look(k)
	local deco, parts, V, at, MAT, D, s = k.deco, k.parts, k.V, k.at, k.MAT, k.D, k.s
	local cw, ch, cd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.aw, k.lw, k.la, k.ua
	local shin, th = D.shin / s, D.thigh / s
	local rng = Random.new(4471) -- (the same rags and fingers every time)
	local function R(a, b)
		return rng:NextNumber(a, b)
	end
	local function shade() -- each rag a shade off the next, as her shrouds were: near black, plum, a little moss
		return C3(26, 22, 30):Lerp(C3(74, 58, 80), R(0, 1)):Lerp(C3(44, 54, 40), R(0, 0.35))
	end
	for _, pn in ipairs({ "Chest", "Hips", "RUpperArm", "LUpperArm", "RLowerArm", "LLowerArm", "RThigh", "LThigh", "RShin", "LShin", "RFoot", "LFoot", "RToe", "LToe", "RHand", "LHand" }) do
		parts[pn].Material = MAT.SmoothPlastic
	end

	-- a rod of bone on a part from point a to b (unscaled, in the part's space), and a knob
	local function bone(on, a, b, w, c, name)
		local d = b - a
		local up = math.abs(d.Unit.Y) > 0.99 and Vector3.xAxis or Vector3.yAxis
		return deco(on, name or "Bone", V(w, w, d.Magnitude), CFrame.lookAt((a + b) * s / 2, b * s, up), c or BONE, MAT.SmoothPlastic)
	end
	local function ball(on, p, d, c, mat, name)
		return deco(on, name or "Knob", V(d, d, d), CFrame.new(p * s), c or BONE, mat or MAT.SmoothPlastic, Enum.PartType.Ball)
	end

	-- the torso drawn in to little more than her spine (the shoulder joints stay where they were), and a long collarbone
	-- either side, front and back, still carrying them out
	local tw, td = cw * 0.5, cd * 0.7
	parts.Chest.Size = V(tw, ch, td)
	for _, sx in ipairs({ -1, 1 }) do
		bone("Chest", Vector3.new(sx * 0.03, ch / 2 - 0.08, -td / 2 - 0.02), Vector3.new(sx * 0.56, ch / 2 - 0.2, -0.03), 0.1, BONE, "Clavicle")
		bone("Chest", Vector3.new(sx * 0.03, ch / 2 - 0.14, td / 2 + 0.02), Vector3.new(sx * 0.56, ch / 2 - 0.22, 0.04), 0.08, BONE, "Scapula")
	end
	ball("Chest", Vector3.new(0, ch / 2 - 0.1, -td / 2 - 0.02), 0.15, BONE, nil, "Sternum")
	-- the ribs showing through, a ridge of spine down her back
	for i = 0, 4 do
		deco("Chest", "Rib", V(tw * (1.1 - i * 0.05), 0.07, 0.06), at(0, ch * (0.28 - i * 0.12), -td / 2 - 0.02), ASH:Lerp(DARK, 0.45), MAT.SmoothPlastic)
	end
	for i = 0, 6 do
		deco("Chest", "Spine", V(0.12, 0.12, 0.12), at(0, ch * (0.42 - i * 0.14), td / 2 + 0.02), BONE, MAT.SmoothPlastic, Enum.PartType.Ball)
	end

	-- a jointed finger growing off a limb at (x, y, z) on it: out (roll) and forward/back (pitch) from hanging straight
	-- down, l1 to the knuckle, l2 on to the hooked talon
	local function finger(on, x, y, z, roll, pitch, l1, l2, w)
		local base = CFrame.new(x * s, y * s, z * s) * CFrame.Angles(pitch, 0, roll)
		deco(on, "Finger", V(w, l1, w), base * CFrame.new(0, -l1 * s / 2, 0), ASH:Lerp(BONE, 0.5), MAT.SmoothPlastic)
		local knuckle = base * CFrame.new(0, -l1 * s, 0) * CFrame.Angles(-pitch * 0.4, 0, -roll * 0.7)
		local kn = deco(on, "FingerKnuckle", V(w * 1.5, w * 1.5, w * 1.5), knuckle, BONE, MAT.SmoothPlastic, Enum.PartType.Ball)
		local seg = deco(on, "Finger", V(w * 0.85, l2, w * 0.85), knuckle * CFrame.new(0, -l2 * s / 2, 0), ASH:Lerp(BONE, 0.5), MAT.SmoothPlastic)
		local talon = deco(on, "FingerTalon", V(w * 0.7, 0.22, w * 0.7), knuckle * CFrame.new(0, -l2 * s - 0.08 * s, 0) * CFrame.Angles(0.6, 0, 0), DARK, MAT.SmoothPlastic)
		-- (the second bone, and its talon with it, on a joint at the knuckle: every client crooks each in its own time, M.Gait)
		seg:FindFirstChildOfClass("WeldConstraint"):Destroy()
		talon:FindFirstChildOfClass("WeldConstraint"):Destroy()
		local tw = Instance.new("WeldConstraint")
		tw.Part0, tw.Part1 = seg, talon
		tw.Parent = talon
		local m = Instance.new("Motor6D")
		m.Name = "Knuckle"
		m.Part0, m.Part1, m.C1 = kn, seg, CFrame.new(0, l2 * s / 2, 0)
		m.Parent = kn
	end
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		-- bony knobs at the joints
		deco(n .. "LowerArm", "Elbow", V(aw * 1.4, aw * 1.4, aw * 1.4), at(0, la / 2, 0), BONE, MAT.SmoothPlastic, Enum.PartType.Ball)
		deco(n .. "Shin", "Knee", V(lw * 1.4, lw * 1.4, lw * 1.4), at(0, shin / 2, -0.03), BONE, MAT.SmoothPlastic, Enum.PartType.Ball)
		deco(n .. "UpperArm", "Shoulder", V(aw * 1.7, aw * 1.7, aw * 1.7), at(0, ua / 2, 0), BONE, MAT.SmoothPlastic, Enum.PartType.Ball)
		-- her hands: three long talons each
		for f = -1, 1 do
			local fl = 0.95 + (f == 0 and 0.25 or 0)
			deco(n .. "Hand", "Talon", V(0.06, fl, 0.06), at(f * 0.09, -0.15 - fl / 2, -0.04) * CFrame.Angles(0.12, 0, f * 0.08), BONE, MAT.SmoothPlastic)
			deco(n .. "Hand", "TalonTip", V(0.05, 0.3, 0.05), at(f * 0.09 + f * 0.04, -0.18 - fl, -0.12) * CFrame.Angles(0.7, 0, 0), DARK, MAT.SmoothPlastic)
		end
		-- and the fingers branching off her limbs all the way down, out and back, every one a different length
		for _, lim in ipairs({ { n .. "UpperArm", ua, aw, 2 }, { n .. "LowerArm", la, aw, 3 }, { n .. "Thigh", th, lw, 2 }, { n .. "Shin", shin, lw, 3 } }) do
			local on, len, wd, count = lim[1], lim[2], lim[3], lim[4]
			for i = 1, count do
				local y = len * (0.35 - 0.7 * (i - 0.5) / count) + R(-0.08, 0.08)
				local back = rng:NextNumber() < 0.4 -- (some off the back of the limb rather than its outside)
				local x, z = back and sx * wd * 0.2 or sx * wd * 0.5, back and wd * 0.5 or R(-wd, wd) * 0.3
				finger(on, x, y, z, sx * R(0.45, 1.0), back and R(0.5, 0.9) or R(-0.4, 0.4), R(0.25, 0.75), R(0.2, 0.6), R(0.05, 0.07))
			end
		end
	end

	-- the head: hidden, and dressed in her face (M.Faces)
	parts.Head.Transparency = 1
	bone("Head", Vector3.new(0, -0.85, 0.06), Vector3.new(0, -0.45, 0.02), 0.14, ASH, "Neck")
	dressFace(M.Face, deco, s)

	-- THE RAGS: her cloak, torn into pieces that hang off her limbs, each its own chain. dir: the side it hangs out on,
	-- in the part's own space (-Z is her front)
	local function rag(on, x, y, z, dir, segs, len, width, phys)
		local a = deco(on, "RagAnchor", V(0.2, 0.2, 0.2), at(x, y, z) * CFrame.lookAt(Vector3.zero, dir), DARK, MAT.SmoothPlastic)
		clothAnchor(a, segs, len * s, width * s, shade(), phys)
	end
	local light = { Drag = 0.97, Gravity = 0.8, Out = 0.05 } -- (quick to flutter)
	local heavy = { Drag = 0.92, Gravity = 1.3, Out = 0.12 } -- (slow and swinging)
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		local out = Vector3.new(sx, 0, 0)
		-- off the shoulders and down the arms: long ones from the upper arm, shorter from the forearm
		rag(n .. "UpperArm", sx * aw * 0.5, ua * 0.4, 0, out, 5, R(0.45, 0.6), R(0.45, 0.6), heavy)
		rag(n .. "UpperArm", 0, ua * 0.2, aw * 0.5, Vector3.new(sx * 0.4, 0, 1).Unit, 4, R(0.4, 0.5), R(0.35, 0.5), light)
		rag(n .. "LowerArm", sx * aw * 0.45, la * 0.3, 0, out, 4, R(0.35, 0.5), R(0.35, 0.45), light)
		rag(n .. "LowerArm", 0, -la * 0.1, aw * 0.45, Vector3.new(0, 0, 1), 3, R(0.35, 0.45), R(0.3, 0.4), light)
		-- off the legs
		rag(n .. "Thigh", sx * lw * 0.5, th * 0.4, 0, out, 4, R(0.4, 0.55), R(0.4, 0.55), heavy)
		rag(n .. "Shin", sx * lw * 0.5, shin * 0.35, 0, out, 3, R(0.3, 0.45), R(0.3, 0.4), light)
	end
	-- what's left of the shawl, down her back (no hood: there's no skull left to hang it off)
	rag("Chest", -tw * 0.25, ch * 0.4, td / 2 + 0.05, Vector3.new(0, 0, 1), 6, R(0.55, 0.65), 0.5, heavy)
	rag("Chest", tw * 0.25, ch * 0.35, td / 2 + 0.05, Vector3.new(0, 0, 1), 5, R(0.5, 0.6), 0.45, heavy)

	-- THE BULK OF HER CLOAK, what the tearing left on her: not strips but layers of it, heavy, one over another. A
	-- mantle over her shoulders and down her back and sides (open at the front: her ribs, and the light behind them,
	-- still show), a high ragged collar stood up behind the wicks, two tiers of skirts off her hips, wraps round her
	-- arms, and a long train off the mantle's back hem
	local function shroud(on, yTop, len, r, n, flare, gap, thick) -- a ring of hung panels round a part, a gap left at its front
		for i = 1, n do
			local a = gap + (i - 0.5 + R(-0.3, 0.3)) / n * (math.pi * 2 - gap * 2)
			local h = len * R(0.75, 1.15)
			local w = (math.pi * 2 - gap * 2) * r / n * R(1.4, 1.9)
			deco(on, "Shroud", V(w, h, thick or 0.05), CFrame.Angles(0, a, 0) * CFrame.new(0, (yTop - h / 2) * s, -r * s) * CFrame.Angles(flare * R(0.8, 1.2), 0, R(-0.08, 0.08)), shade(), MAT.Fabric)
		end
	end
	shroud("Chest", ch / 2 + 0.08, 1.5, 0.66, 12, 0.34, 0.85, 0.06)
	shroud("Chest", ch / 2 + 0.02, 0.9, 0.72, 10, 0.6, 0.7)
	shroud("Chest", ch * 0.1, 1.6, 0.3, 8, 0.2, 1.1)
	for i = 0, 5 do
		deco("Chest", "Collar", V(R(0.3, 0.42), R(0.9, 1.4), 0.05), CFrame.Angles(0, 2.0 + i / 5 * 2.28, 0) * CFrame.new(0, (ch / 2 + 0.5) * s, -0.42 * s) * CFrame.Angles(-0.3, 0, R(-0.1, 0.1)), shade(), MAT.Fabric)
	end
	shroud("Hips", 0.35, 1.7, 0.34, 11, 0.24, 0.6, 0.06)
	shroud("Hips", 0.1, 2.6, 0.3, 9, 0.13, 0.75)
	for _, n in ipairs({ "R", "L" }) do
		shroud(n .. "UpperArm", ua * 0.45, 1.3, aw * 0.75, 4, 0.18, 0)
		shroud(n .. "LowerArm", la * 0.4, 1.0, aw * 0.7, 3, 0.2, 0)
	end
	for _, x in ipairs({ -0.45, -0.15, 0.15, 0.45 }) do
		rag("Chest", x, ch / 2 - 1.2, 0.72, Vector3.new(0, 0, 1), 7, R(0.55, 0.7), R(0.5, 0.7), heavy)
	end

	-- MORE HUNG OFF HER. A skirt of rags round her hips, to her shins
	for i = 0, 7 do
		local a = (i + R(-0.25, 0.25)) / 8 * math.pi * 2
		rag("Hips", math.sin(a) * k.hw * 0.5, -0.2, math.cos(a) * k.hd * 0.5, Vector3.new(math.sin(a), 0, math.cos(a)), 5, R(0.42, 0.58), R(0.32, 0.5), i % 2 == 0 and heavy or light)
	end
	-- her own strings, let hang: thin and lit, one off each talon of her hands and one off each elbow, swinging
	local function hang(on, x, y, z, segs, len)
		local a = deco(on, "RagAnchor", V(0.2, 0.2, 0.2), at(x, y, z), DARK, MAT.SmoothPlastic)
		clothAnchor(a, segs, len * s, 0.07 * s, C3(170, 130, 220), { Drag = 0.98, Gravity = 0.6, Material = "Neon" })
	end
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		for f = -1, 1 do
			hang(n .. "Hand", f * 0.11, -1.15, -0.1, 5, R(0.35, 0.5))
		end
		hang(n .. "LowerArm", sx * aw * 0.5, la * 0.45, 0, 6, R(0.42, 0.55))
		-- a fringe of small finger bones off each shoulder
		for i = 0, 4 do
			local z, l = -0.22 + i * 0.11, R(0.3, 0.7)
			local top = Vector3.new(sx * aw * 0.55, ua / 2 - 0.05, z)
			local mid = top + Vector3.new(sx * 0.12, -l * 0.55, 0)
			bone(n .. "UpperArm", top, mid, 0.045, BONE, "Fringe")
			ball(n .. "UpperArm", mid, 0.07, BONE, nil, "FringeKnuckle")
			bone(n .. "UpperArm", mid, mid + Vector3.new(-sx * 0.03, -l * 0.45, 0), 0.04, i % 2 == 0 and DARK or BONE, "Fringe")
		end
	end
	-- her crown, fallen from the head she hasn't got: round the root of her neck like a collar, askew, its gilt gone
	-- to tarnish, a point over every other piece of it
	local tilt = CFrame.new(0, ch / 2 + 0.1, 0) * CFrame.Angles(0.22, 0, 0.14)
	local function rim(i)
		local a = i / 12 * math.pi * 2
		return tilt * Vector3.new(math.sin(a) * 0.4, 0, -math.cos(a) * 0.4)
	end
	for i = 0, 11 do
		local gilt = C3(120, 96, 52):Lerp(C3(40, 34, 30), R(0, 0.5))
		bone("Chest", rim(i), rim(i + 1), 0.07, gilt, "Crown")
		if i % 2 == 0 and i ~= 8 then
			bone("Chest", rim(i), rim(i) + tilt:VectorToWorldSpace(Vector3.new(0, i == 0 and 0.42 or 0.26, 0)), 0.05, gilt, "CrownPoint")
		end
	end
	-- a row of long spines up out of her back, the tallest between her shoulders
	for i = 0, 5 do
		local root = Vector3.new(0, ch * (0.42 - i * 0.14), td / 2 + 0.02)
		local tip = root + Vector3.new(R(-0.1, 0.1), 0.3 + R(0, 0.2) - i * 0.03, 0.95 - i * 0.11 + R(0, 0.2))
		bone("Chest", root, tip, 0.05, BONE, "Spine")
		bone("Chest", tip, tip + Vector3.new(0, 0.1, 0.16), 0.035, DARK, "SpineTip")
	end
	-- and behind her ribs, her light: it shows between them, and lights her from inside
	local heart = ball("Chest", Vector3.new(0, ch * 0.1, -td * 0.15), 0.2, EYE, MAT.Neon, "Heart")
	local glow = Instance.new("PointLight")
	glow.Color, glow.Range, glow.Brightness = EYE, 9, 1.2
	glow.Parent = heart
end

---------------------------------------------------------------------------
-- server: HER OWN FIGHT. Phase 1 of the three is her husk (Champion.luau); these are the other two, each on a bar
-- of its own (Config.Ossaria.HP, then HP3: one Humanoid holds both, and the bar shows whichever she's on).
-- PHASE 2, her true body (her strings laced round the whole colonnade as it starts): she rakes with her talons and
-- brings them both down, wheels, pounces, skitters round you on all fours and lunges, comes at you in a frenzy of
-- lunging cuts, hounds you leap after leap, holds her talons up over you as long as she likes, lays her strings out over the
-- sand and draws them taut, strings a cat's cradle across you off the colosseum's pillars, strings YOU and drags you
-- in under her, and opens wells of rot under your feet.
-- PHASE 3 (her first bar emptied; the first time, a cutscene: Save "OssariaHand"): the hand
-- over her face lets go of it, two great hands tear out of her back, and she hangs herself from the dark on her own
-- strings - "Ossaria, Hand of Decay". The sand rots black under her, and the wreck of the Heights lifts off the
-- ground round the colosseum and turns in rings over it for as long as she's up. Everything of hers comes faster, and
-- she adds the great hands' slams and their scour, pieces of the turning wreck thrown at you, the sky pulled down
-- as she did to the Heights, and the loom: a web over the whole sand off the pillars, drawn in ring by ring.
-- Ossaria.luau's reveal hands her over, standing on the sand: M.begin(heir, hooks). hooks.onReset() everyone died
-- (she's gone: Ossaria.luau puts her back under her shrouds), hooks.onDied() beaten.
---------------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local O = Config.Ossaria
local F = O.Fight
local MAT = Enum.Material
local V3 = Vector3.new
local VIOLET, PALE, ROT = C3(150, 110, 200), C3(232, 214, 255), C3(14, 8, 18)
local Core, PM, Map, FxRemote, states, now, flat, rand, turnTowards, SOUNDS, playSound, burst, dustCloud, shockwave, bodyPose, aliveChar, damagePlayer, playersInRadius, playersInSector

local boss: any = { state = "none", gen = 0, phase = 2, fx = {} } -- state: none | fight | dead

local function smooth(k)
	k = math.clamp(k, 0, 1)
	return k * k * (3 - 2 * k)
end
local function champion() -- (the sand is his: its seal, and who's on it)
	return Core.Roster.byKind.Champion
end
local function arena()
	return Map.Champion
end
local function inArena(pos)
	return champion().inArena(pos)
end
local function live(b)
	return boss.gen == b.gen and boss.state == "fight" and b.hum.Parent ~= nil and b.hum.Health > 0
end
local function free(b)
	return live(b) and now() >= (boss.staggerUntil or 0)
end
local function tempo() -- every tell of hers is scaled by this
	return boss.phase == 3 and F.Tempo3 or 1
end
local function ground(p) -- p, down on the sand
	return V3(p.X, arena().Centre.Y + 0.1, p.Z)
end
local function standY(b)
	return arena().Centre.Y + 3 * b.scale
end
local function clampToArena(b, p) -- where her root may be: pulled in from the colonnade
	local A = arena()
	local rel = flat(p - A.Centre)
	if rel.Magnitude > A.Radius - 2 then
		rel = rel.Unit * (A.Radius - 2)
	end
	return V3(A.Centre.X + rel.X, standY(b), A.Centre.Z + rel.Z)
end
local function everyone() -- { player = their root }: alive, out on the sand
	local out = {}
	for _, pl in ipairs(Players:GetPlayers()) do
		local char, _, hrp = aliveChar(pl)
		if char and inArena(hrp.Position) then
			out[pl] = hrp
		end
	end
	return out
end
local function target(b)
	local best, bestD
	for pl, hrp in pairs(everyone()) do
		local d = flat(hrp.Position - b.root.Position).Magnitude
		if not bestD or d < bestD then
			best, bestD = pl.Character, d
		end
	end
	return best
end
local function hitOnce(list, seen, amount, fromPos, level)
	for _, pl in ipairs(list) do
		if not seen[pl] and damagePlayer(pl, math.max(1, math.floor(amount + 0.5)), fromPos, level) then
			seen[pl] = true
		end
	end
end
local function shake(at, amount)
	FxRemote:FireAllClients("Shake", at, amount)
end
local function say(name, line)
	for pl in pairs(everyone()) do
		FxRemote:FireClient(pl, "Say", name, line)
	end
end
-- wait d seconds (at her tempo), turning after tchar at rate x her usual; false if she's cut short (staggered, dead)
local function hold(b, d, tchar, rate)
	local t0 = now()
	d *= tempo()
	while now() - t0 < d do
		if not free(b) then
			return false
		end
		local tr = tchar and tchar:FindFirstChild("HumanoidRootPart")
		local dt = task.wait()
		if tr and not b.root.Anchored then
			turnTowards(b.root, tr.Position, math.rad(220) * (rate or 1) * dt)
		end
	end
	return free(b)
end

---------------------------------------------------------------------------
-- A POOL OF ROT (all three phases': her husk's holes are these too, Champion.luau) opening on the sand at c, out to
-- radius over lead seconds: something's about to come up there, or down. A glowing rim; over it the rot - a black
-- heart, and a ragged edge of blots creeping out past it, each in its own time; her light welling up through the
-- middle, full when it's about to go; dark coming off it. rich (the wells, the husk's holes): veins of her light out
-- through the sand round it too, and when it goes (erupt) a hand of bone closes up out of it.
---------------------------------------------------------------------------
local function disc(c, y, d, color, mat, tr)
	local p = Instance.new("Part")
	p.Name, p.Shape = "RotMark", Enum.PartType.Cylinder
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Size, p.CFrame = V3(0.1, d, d), CFrame.new(c + V3(0, y, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	p.Color, p.Material, p.Transparency = color, mat, tr
	p.Parent = workspace
	return p
end
local function swell(p, d, t, style, delay, goal)
	goal = goal or {}
	goal.Size = V3(0.1, d, d)
	TweenService:Create(p, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, delay or 0), goal):Play()
end
local function mark(c, radius, lead, rich)
	c = ground(c)
	local grow = math.min(lead * 0.5, 0.4)
	local heart = disc(c, 0.06, 0.5, ROT, MAT.SmoothPlastic, 0.04)
	swell(heart, radius * 1.7, grow)
	local rim = disc(c, 0.03, 0.5, VIOLET, MAT.Neon, 0.5)
	swell(rim, radius * 2 + 0.9, grow)
	local parts = { heart, rim } -- (parts[1]: its sounds hang on it)
	local n = rich and 11 or 7
	for i = 1, n do
		local a = (i + rand(-0.3, 0.3)) / n * math.pi * 2
		local br = radius * rand(0.2, 0.34)
		local blot = disc(c + V3(math.cos(a), 0, math.sin(a)) * (radius - br * rand(0.8, 1)), 0.06, 0.3, ROT, MAT.SmoothPlastic, 0.04)
		swell(blot, br * 2, grow + rand(0.05, 0.3), nil, rand(0, grow * 0.6))
		table.insert(parts, blot)
	end
	local fill = disc(c, 0.09, 0.3, C3(120, 70, 170), MAT.Neon, 0.6)
	swell(fill, radius * 1.6, lead, Enum.EasingStyle.Linear, 0, { Transparency = 0.2 })
	table.insert(parts, fill)
	if rich then
		for _, v in ipairs(Core.crackLines(c + V3(0, 0.1, 0), radius * 1.6, 5, C3(104, 60, 140), MAT.Neon, lead * 0.8)) do
			table.insert(parts, v)
		end
	end
	local wisps = Instance.new("ParticleEmitter") -- (out of the heart's whole face: it lies on its side, its X up)
	wisps.Texture = "rbxasset://textures/particles/smoke_main.dds"
	wisps.Color = ColorSequence.new(C3(12, 8, 16), C3(70, 36, 96))
	wisps.LightEmission, wisps.LightInfluence = 0.1, 0
	wisps.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 2.4) })
	wisps.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.45), NumberSequenceKeypoint.new(1, 1) })
	wisps.Lifetime, wisps.Speed, wisps.Rate = NumberRange.new(0.7, 1.3), NumberRange.new(2, 5), radius * (rich and 3 or 1.5)
	wisps.Rotation, wisps.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-60, 60)
	wisps.EmissionDirection, wisps.Acceleration = Enum.NormalId.Right, V3(0, 3, 0)
	wisps.Parent = heart
	return parts
end
local function unmark(parts)
	for _, p in ipairs(parts) do
		local e = p:FindFirstChildOfClass("ParticleEmitter")
		if e then
			e.Enabled = false
		end
		TweenService:Create(p, TweenInfo.new(0.7), { Transparency = 1 }):Play()
		Debris:AddItem(p, 1.6)
	end
end
local function rod(a, b, w, color)
	local p = Instance.new("Part")
	p.Name = "RotFinger"
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Size, p.CFrame = V3(w, w, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b)
	p.Color, p.Material = color, MAT.SmoothPlastic
	return p
end
-- a hand of bone up out of the sand round c and closed over it: five fingers in a ring, each two bones and a talon,
-- up in an instant and sunk back a moment after
local function grasp(c, radius)
	local w = math.clamp(radius * 0.07, 0.3, 0.6)
	for i = 1, 5 do
		local a = i / 5 * math.pi * 2 + rand(-0.25, 0.25)
		local out = V3(math.cos(a), 0, math.sin(a))
		local l1, l2 = radius * rand(0.55, 0.8), radius * rand(0.4, 0.55)
		local p0 = c + out * radius * 0.55
		local p1 = p0 + V3(0, l1, 0) + out * l1 * 0.25 -- (the knuckle: up and a little out)
		local p2 = p1 + V3(0, l2 * 0.45, 0) - out * l2 * 0.85 -- (bent back in over the pool)
		local p3 = p2 - V3(0, w * 2, 0) - out * w * 1.5
		local sink = V3(0, l1 + l2 + 1, 0)
		for _, r in ipairs({ rod(p0, p1, w, ASH:Lerp(BONE, 0.5)), rod(p1, p2, w * 0.85, ASH:Lerp(BONE, 0.5)), rod(p2, p3, w * 0.6, DARK) }) do
			local up = r.CFrame
			r.CFrame = up - sink
			r.Parent = workspace
			TweenService:Create(r, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, i * 0.02), { CFrame = up }):Play()
			task.delay(0.65, function()
				TweenService:Create(r, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = up - sink }):Play()
			end)
			Debris:AddItem(r, 1.25)
		end
	end
end
local function erupt(c, radius, hand) -- rot thrown up out of the sand: a gout of it, and (hand) the hand closing up through it
	burst(c + V3(0, 2, 0), C3(40, 18, 56), 36, 0.7, radius * 2.5)
	dustCloud(c, radius * 0.5, 14)
	local h = radius * 2.2
	local g = Instance.new("Part")
	g.Name, g.Shape = "RotGout", Enum.PartType.Cylinder
	g.Anchored, g.CanCollide, g.CanQuery, g.CanTouch, g.CastShadow = true, false, false, false, false
	g.Material, g.Color, g.Transparency = MAT.Neon, C3(46, 22, 66), 0.3
	g.Size, g.CFrame = V3(1, radius * 1.3, radius * 1.3), CFrame.new(c + V3(0, 0.5, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	g.Parent = workspace
	TweenService:Create(g, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = V3(h, radius * 0.5, radius * 0.5), CFrame = CFrame.new(c + V3(0, h / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Transparency = 1 }):Play()
	Debris:AddItem(g, 0.5)
	if hand then
		grasp(c, radius)
	end
end

---------------------------------------------------------------------------
-- THE COLOSSEUM'S PILLARS (MapBuilder's colonnade: 44 to a row, the inner row 46 out from the middle, 20 tall; the
-- Heights' fall snapped some short): what her strings catch on. THE WRECK OF THE HEIGHTS, lifted and turning.
---------------------------------------------------------------------------
local PILLARS = 44
local pillarTops = {}
local function pillar(k, h) -- a point on pillar k's face onto the sand, h up it (no higher than what's left standing of it)
	local A = arena()
	local a = k / PILLARS * math.pi * 2
	local out = V3(math.cos(a), 0, math.sin(a))
	local i = k % PILLARS
	if not pillarTops[i] then -- (from inside a whole one the ray sees nothing of it: only a stump's top)
		local hit = workspace:Raycast(A.Centre + out * 46 + V3(0, 19.5, 0), V3(0, -19, 0))
		pillarTops[i] = hit and hit.Instance.Name == "Column" and hit.Position.Y - A.Centre.Y or 20
	end
	return A.Centre + out * 44.6 + V3(0, math.min(h, pillarTops[i] - 0.5), 0)
end
-- a string between two points, laid faint (strand); drawn taut (pluck): it flares, and thins away to nothing; and
-- what it cuts (cut): everyone on the sand within width of the len of it from a along d
local function strand(a, to, w, tr)
	local p = Instance.new("Part")
	p.Name = "OssariaThread"
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material, p.Color, p.Transparency = MAT.Neon, VIOLET, tr or 0.6
	p.Size, p.CFrame = V3(w, w, (to - a).Magnitude), CFrame.lookAt((a + to) / 2, to)
	p.Parent = workspace
	return p
end
local function triple(a, to, w, tr) -- three of them side by side, F.StringGap apart: one string of hers is always three
	local d = flat(to - a)
	local side = V3(-d.Z, 0, d.X).Unit * F.StringGap
	local out = {}
	for i = -1, 1 do
		local p = strand(a + side * i, to + side * i, w, tr)
		Debris:AddItem(p, 6)
		table.insert(out, p)
	end
	return out
end
local function pluck(p, w)
	p.Color, p.Transparency, p.Size = PALE, 0, V3(w, math.min(w, 0.5), p.Size.Z)
	TweenService:Create(p, TweenInfo.new(0.35), { Size = V3(0.05, 0.05, p.Size.Z), Transparency = 1 }):Play()
	Debris:AddItem(p, 0.5)
end
local function cut(a, d, len, width, seen, amount, level)
	for pl, hrp in pairs(everyone()) do
		local rel = flat(hrp.Position - a)
		local along = rel:Dot(d)
		if along > 0 and along < len and (rel - d * along).Magnitude < width then
			hitOnce({ pl }, seen, amount, V3(a.X, hrp.Position.Y, a.Z) + d * along, level)
		end
	end
end
-- her strings laced round the whole colonnade, pillar to pillar, low then high: there from the moment her own fight starts
local function lace()
	local gen = boss.gen
	local at = {}
	for k = 0, PILLARS do
		local a = Instance.new("Attachment")
		a.Position = pillar(k, k % 2 == 0 and 4 or 13)
		a.Parent = workspace.Terrain
		at[k] = a
		table.insert(boss.fx, a)
	end
	for k = 0, PILLARS - 1 do
		task.delay(k * 0.03, function()
			if boss.gen ~= gen or boss.state ~= "fight" then
				return
			end
			local beam = Instance.new("Beam")
			beam.Attachment0, beam.Attachment1 = at[k], at[k + 1]
			beam.Width0, beam.Width1, beam.Segments, beam.FaceCamera = 0.12, 0.12, 1, true
			beam.Color = ColorSequence.new(VIOLET)
			beam.LightEmission, beam.Transparency = 0.5, NumberSequence.new(0.45)
			beam.Parent = workspace.Terrain
			table.insert(boss.fx, beam)
			if k % 4 == 0 then
				burst(at[k].Position, VIOLET, 6, 0.3, 8)
			end
		end)
	end
end
-- a piece of the Heights (as HeightsRuin heaped them round the colosseum): a column's drum, a slab of wall, a gilt beam, glass
local GEMS = { C3(150, 40, 50), C3(40, 80, 150), C3(60, 130, 80), C3(170, 130, 40) }
local function wreck(lo, hi)
	local p = Instance.new("Part")
	local k, d = math.random(), rand(lo, hi)
	if k < 0.4 then
		p.Shape, p.Size = Enum.PartType.Cylinder, V3(d * rand(0.5, 0.9), d * 0.6, d * 0.6)
		p.Material, p.Color = MAT.Limestone, C3(196, 186, 160):Lerp(C3(60, 52, 58), rand(0.2, 0.6))
	elseif k < 0.75 then
		p.Size = V3(d, d * rand(0.2, 0.35), d * rand(0.5, 0.8))
		p.Material, p.Color = MAT.Limestone, C3(206, 192, 158):Lerp(C3(60, 52, 58), rand(0.2, 0.6))
	elseif k < 0.92 then
		p.Size = V3(d * 0.16, d * 0.16, d * 1.3)
		p.Material, p.Color = MAT.Metal, C3(176, 140, 66):Lerp(C3(70, 60, 44), rand(0.3, 0.8))
	else
		p.Size = V3(d * 0.4, d * 0.6, 0.3)
		p.Material, p.Color, p.Transparency = MAT.Glass, GEMS[math.random(#GEMS)], 0.3
	end
	p.Name = "HeightsWreck"
	p.CanCollide, p.CanQuery, p.CanTouch, p.Massless, p.CastShadow = false, false, false, true, false
	return p
end
-- (her third phase's coming) THE WRECK LIFTED: what the Heights' fall left heaped round the colosseum comes up off
-- the ground, and more of it down out of the dark, into three rings turning over the sand and round it, each its own
-- way, for as long as she's up. Each ring is one anchored hub, its pieces welded to it: three parts moved a frame.
-- The middle ring's pieces (boss.rocks) are hers to throw (hurl).
local RINGS = { -- (down where you're looking: the first two turn just inside the colonnade, from over your head to the roof)
	{ r = { 37, 43 }, n = 22, y0 = 140, y1 = 13, w = 0.3, tilt = 0.03, size = { 6, 11 }, spread = 5 }, -- round the sand's edge, low
	{ r = { 24, 34 }, n = 16, y0 = 170, y1 = 22, w = -0.42, tilt = 0.08, size = { 4, 8 }, spread = 4, rocks = true }, -- inside that, the other way: hers to throw
	{ r = { 10, 20 }, n = 12, y0 = 200, y1 = 31, w = 0.75, tilt = -0.18, size = { 2.5, 5 }, spread = 3 }, -- over the middle
	{ r = { 8, 42 }, n = 40, y0 = 70, y1 = 8, w = 0.95, tilt = 0.02, size = { 0.8, 2.4 }, spread = 5 }, -- grit and small stone, fast, over the whole sand at your own height
	{ r = { 52, 72 }, n = 14, y0 = 3, y1 = 42, w = 0.16, tilt = 0.05, size = { 12, 22 }, spread = 7 }, -- off the heaps outside: the biggest, over the colonnade's roof
}
local function hang(hub, lcf, lo, hi) -- a piece on a ring's hub, at lcf in its space
	local rock = wreck(lo, hi)
	rock.CFrame = hub.CFrame * lcf
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = hub, rock
	w.Parent = rock
	rock.Parent = hub
	return { part = rock, hub = hub, lcf = lcf, lo = lo, hi = hi }
end
-- the air over the sand, full: grit lifted off the whole of it (and, her third phase, motes of her light with it)
local function haze(rate, motes)
	local A = arena()
	local air = Instance.new("Part")
	air.Name, air.Transparency = "OssariaAir", 1
	air.Anchored, air.CanCollide, air.CanQuery, air.CanTouch = true, false, false, false
	air.Size, air.CFrame = V3(A.Radius * 1.8, 1, A.Radius * 1.8), CFrame.new(A.Centre + V3(0, 1, 0))
	local grit = Instance.new("ParticleEmitter")
	grit.Texture = "rbxasset://textures/particles/smoke_main.dds"
	grit.Color = ColorSequence.new(C3(64, 56, 62))
	grit.LightEmission, grit.LightInfluence = 0, 0.6
	grit.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 3) })
	grit.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.7), NumberSequenceKeypoint.new(1, 1) })
	grit.Lifetime, grit.Speed, grit.Rate = NumberRange.new(3, 5), NumberRange.new(3, 7), rate
	grit.Rotation, grit.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-50, 50)
	grit.EmissionDirection, grit.SpreadAngle, grit.Acceleration = Enum.NormalId.Top, Vector2.new(30, 30), V3(0, 1.5, 0)
	grit.Parent = air
	if motes then
		local m = Instance.new("ParticleEmitter")
		m.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		m.Color = ColorSequence.new(C3(170, 130, 220))
		m.LightEmission = 0.9
		m.Size = NumberSequence.new(0.28, 0)
		m.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.1), NumberSequenceKeypoint.new(1, 1) })
		m.Lifetime, m.Speed, m.Rate = NumberRange.new(2, 4), NumberRange.new(2, 6), motes
		m.EmissionDirection, m.SpreadAngle = Enum.NormalId.Top, Vector2.new(40, 40)
		m.Parent = air
	end
	air.Parent = workspace
	table.insert(boss.fx, air)
end
-- (her third phase) pieces of the wreck torn loose and across the sand overhead, one every couple of seconds, a streak
-- of dark behind each: nothing they hit, only what the air's like in there now
local function streaks(b)
	local A = arena()
	task.spawn(function()
		while true do
			task.wait(rand(1.4, 3.2))
			if boss.gen ~= b.gen or boss.state ~= "fight" then
				return
			end
			local a = rand(0, math.pi * 2)
			local a2 = a + math.pi + rand(-0.7, 0.7)
			local rock = wreck(2.5, 6)
			rock.Anchored = true
			rock.CFrame = CFrame.new(A.Centre + V3(math.cos(a) * 52, rand(12, 30), math.sin(a) * 52)) * CFrame.Angles(rand(0, 6), rand(0, 6), 0)
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			a0.Position, a1.Position = V3(0, rock.Size.Y / 2, 0), V3(0, -rock.Size.Y / 2, 0)
			a0.Parent, a1.Parent = rock, rock
			local tr = Instance.new("Trail")
			tr.Attachment0, tr.Attachment1 = a0, a1
			tr.Color = ColorSequence.new(C3(60, 40, 80), C3(10, 8, 12))
			tr.Transparency = NumberSequence.new(0.4, 1)
			tr.Lifetime, tr.LightEmission = 0.45, 0
			tr.Parent = rock
			rock.Parent = workspace
			TweenService:Create(rock, TweenInfo.new(rand(1.0, 1.7), Enum.EasingStyle.Linear), { CFrame = CFrame.new(A.Centre + V3(math.cos(a2) * 56, rand(7, 26), math.sin(a2) * 56)) * CFrame.Angles(rand(0, 12), rand(0, 12), 0) }):Play()
			Debris:AddItem(rock, 1.8)
		end
	end)
end
local function raiseWreck(b, dur)
	haze(34, 30)
	streaks(b)
	local A = arena()
	local rings = {}
	boss.rocks = {}
	for _, R in ipairs(RINGS) do
		local hub = Instance.new("Part")
		hub.Name, hub.Size, hub.Transparency = "WreckHub", Vector3.one, 1
		hub.Anchored, hub.CanCollide, hub.CanQuery, hub.CanTouch = true, false, false, false
		hub.CFrame = CFrame.new(A.Centre + V3(0, R.y0, 0))
		for j = 1, R.n do
			local a = (j + rand(-0.3, 0.3)) / R.n * math.pi * 2
			local r = rand(R.r[1], R.r[2])
			local rock = hang(hub, CFrame.new(math.cos(a) * r, rand(-R.spread, R.spread), math.sin(a) * r) * CFrame.Angles(rand(0, 6), rand(0, 6), rand(0, 6)), R.size[1], R.size[2])
			if R.rocks then
				table.insert(boss.rocks, rock)
			end
		end
		hub.Parent = workspace
		table.insert(boss.fx, hub)
		table.insert(rings, { hub = hub, R = R, ang = rand(0, 6) })
	end
	local t0, conn = now(), nil
	conn = RunService.Heartbeat:Connect(function(dt)
		if boss.gen ~= b.gen or boss.state ~= "fight" then
			conn:Disconnect()
			return
		end
		local k = smooth((now() - t0) / dur)
		for _, ring in ipairs(rings) do
			local R = ring.R
			ring.ang += R.w * dt * (0.25 + 0.75 * k)
			ring.hub.CFrame = CFrame.new(A.Centre + V3(0, R.y0 + (R.y1 - R.y0) * k, 0)) * CFrame.Angles(0, ring.ang, 0) * CFrame.Angles(R.tilt * k, 0, 0)
		end
	end)
end

---------------------------------------------------------------------------
-- THE GREAT HANDS (her third phase): two more arms out of her back, each longer than she is tall and ending in a hand
-- the size of you, every finger of it jointed. The server builds them (growHands) and only says where each hand
-- should go (handTo: attributes on her model); every client moves them itself (M.Gait, below): the arm solved each
-- frame off her chest as that client has her posed, so a hand sent to a spot on the sand is on that spot however
-- she's leaning, and the fingers curled and rippling on their own joints.
--   GH<R|L> where (her chest's space; or the world's, if GHW)   GHT seconds to get there   GHS 0 eased | 1 a slam,
--   only ever faster | 2 steady   GHC its fingers' curl (-0.4 splayed .. 1 a fist)   GHN counts up: a new order
---------------------------------------------------------------------------
local HAND = { -- where a hand rests (the right one's, in her chest's space, x her scale), and its fingers' curl there
	Fold = { V3(0.5, -1.4, 0.7), 0.8 }, -- down her back, out of sight
	Loom = { V3(4.5, 2.6, 0.6), 0.15 }, -- up and out either side of her, elbows high
	Rear = { V3(2.5, 6.5, -1.5), -0.3 }, -- hoisted right up over her, fingers spread
	Sky = { V3(5.5, 5.5, 0), -0.4 }, -- flung wide and high
}
local function handTo(b, sx, where, dur, snap, curl) -- sx: -1 | 1 | 0 (both); where: a HAND name, or a point in the world
	if not boss.hands then
		return
	end
	local m = b.model
	for _, n in ipairs(sx == 0 and { "R", "L" } or { sx == 1 and "R" or "L" }) do
		local world = typeof(where) == "Vector3"
		local to = where
		if not world then
			local p = HAND[where][1] * b.scale
			to = V3(p.X * (n == "R" and 1 or -1), p.Y, p.Z)
		end
		m:SetAttribute("GH" .. n, to)
		m:SetAttribute("GHW" .. n, world)
		m:SetAttribute("GHT" .. n, math.max(dur, 0.01))
		m:SetAttribute("GHS" .. n, snap == true and 1 or snap == "steady" and 2 or 0)
		m:SetAttribute("GHC" .. n, curl or (not world and HAND[where][2]) or 0.1)
		m:SetAttribute("GHN" .. n, (m:GetAttribute("GHN" .. n) or 0) + 1)
	end
end
-- (either end of the wire) a great hand's pieces and joints, once they're all there; and its three arm joints set
-- from where its hand is (at, in her chest's space)
local function handRig(model, n)
	local chest, upper, fore, palm = model:FindFirstChild("Chest"), model:FindFirstChild("GreatUpper" .. n), model:FindFirstChild("GreatFore" .. n), model:FindFirstChild("GreatPalm" .. n)
	local mU, mF, mP = upper and upper:FindFirstChild("GreatJoint"), fore and fore:FindFirstChild("GreatJoint"), palm and palm:FindFirstChild("GreatJoint")
	if not (chest and mU and mF and mP) then
		return nil
	end
	local sx = n == "R" and 1 or -1
	local h = {
		sx = sx, chest = chest, mU = mU, mF = mF, mP = mP, L1 = upper.Size.Y, L2 = fore.Size.Y, fingers = {},
		sh = Vector3.new(sx * chest.Size.X * 0.45, chest.Size.Y * 0.3, chest.Size.Z * 0.5), -- (its shoulder: her shoulder blade)
	}
	for _, p in ipairs(model:GetChildren()) do
		if p:GetAttribute("Great") == n then
			local m = p:FindFirstChild("GreatFinger") or p:FindFirstChild("GreatFinger2")
			if m then
				table.insert(h.fingers, { m = m, rest = m.C0, second = m.Name == "GreatFinger2", i = p:GetAttribute("Finger") or 0 })
			end
		end
	end
	return #h.fingers == 12 and h or nil -- (six fingers, two joints each)
end
local function solveHand(pm, h, at)
	local elbow, hand = pm.twoBone(h.sh, at, h.L1, h.L2, Vector3.new(h.sx * 0.3, 1, 0.9))
	h.mU.C0 = pm.frameAlong(h.sh, elbow - h.sh, Vector3.xAxis)
	h.mF.C0 = pm.frameAlong(elbow, hand - elbow, Vector3.xAxis)
	h.mP.C0 = pm.frameAlong(hand, hand - elbow, -Vector3.xAxis) -- (so a hand held up curls its fingers forward, one reaching out curls them down)
end
local function growHands(b)
	local s = b.scale
	local chest = b.model:FindFirstChild("Chest")
	local L1, L2 = 4.3 * s, 4.7 * s -- (long enough to lay a hand on the sand HandReach out from her, from her shoulder blades' height)
	local made, tips = {}, {}
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		local function piece(name, size, color, shape)
			local p = Instance.new("Part")
			p.Name, p.Size, p.Color, p.Material = name, size, color, MAT.SmoothPlastic
			if shape then
				p.Shape = shape
			end
			p.CanCollide, p.CanQuery, p.CanTouch, p.Massless, p.Transparency = false, false, false, true, 1
			p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			p.CFrame = chest.CFrame
			p:SetAttribute("Great", n)
			table.insert(made, p)
			return p
		end
		local function joint(name, p0, p1, c0, c1)
			local m = Instance.new("Motor6D")
			m.Name = name
			m.Part0, m.Part1, m.C0, m.C1 = p0, p1, c0, c1
			m.Parent = p1
			p1.CFrame = p0.CFrame * c0 * c1:Inverse() -- (where the joint will put it: what's welded on next is welded there)
		end
		local function on(base, name, size, cf, color, shape) -- welded onto a piece (cf in its space)
			local p = piece(name, size, color or BONE, shape)
			p.CFrame = base.CFrame * cf
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = base, p
			w.Parent = p
			return p
		end
		local upper = piece("GreatUpper" .. n, V3(0.3 * s, L1, 0.3 * s), ASH)
		local fore = piece("GreatFore" .. n, V3(0.24 * s, L2, 0.24 * s), ASH)
		local palm = piece("GreatPalm" .. n, V3(0.42 * s, 0.3 * s, 0.24 * s), BONE) -- (no slab of a palm: a knot of wrist bones, and a long bone out from it to each finger)
		joint("GreatJoint", chest, upper, CFrame.new(), CFrame.new(0, L1 / 2, 0))
		joint("GreatJoint", chest, fore, CFrame.new(), CFrame.new(0, L2 / 2, 0))
		joint("GreatJoint", chest, palm, CFrame.new(), CFrame.new(0, 0.15 * s, 0))
		on(upper, "GreatKnob", Vector3.one * 0.5 * s, CFrame.new(0, L1 / 2, 0), BONE, Enum.PartType.Ball)
		on(fore, "GreatKnob", Vector3.one * 0.45 * s, CFrame.new(0, L2 / 2, 0), BONE, Enum.PartType.Ball)
		-- rags off the arm all the way down it, and her strings let hang off the hand (cloth: every client swings them)
		local back = CFrame.Angles(0, math.pi, 0)
		local function shade()
			return C3(26, 22, 30):Lerp(C3(74, 58, 80), math.random())
		end
		for _, y in ipairs({ 0.3, 0.05, -0.2, -0.42 }) do
			clothAnchor(on(upper, "ClothAnchor", Vector3.one * 0.2, CFrame.new(0, L1 * y, 0) * back), 4, rand(0.45, 0.65) * s, rand(0.4, 0.6) * s, shade(), { Drag = 0.95, Gravity = 1.1 })
		end
		for _, y in ipairs({ 0.3, 0, -0.3 }) do
			clothAnchor(on(fore, "ClothAnchor", Vector3.one * 0.2, CFrame.new(0, L2 * y, 0) * back), 3, rand(0.4, 0.55) * s, rand(0.3, 0.45) * s, shade(), { Drag = 0.96, Gravity = 0.9 })
		end
		for i = 1, 6 do -- and the arm itself shrouded, shoulder to elbow: heavy panels of it hung round the bone
			local h = rand(0.9, 1.6) * s
			on(upper, "GreatShroud", V3(rand(0.5, 0.8) * s, h, 0.06 * s), CFrame.Angles(0, i / 6 * math.pi * 2 + rand(-0.3, 0.3), 0) * CFrame.new(0, L1 * rand(0.1, 0.42) - h / 2, -0.3 * s) * CFrame.Angles(rand(0.1, 0.3), 0, rand(-0.1, 0.1)), shade()).Material = Enum.Material.Fabric
		end
		for i = -1, 1 do
			clothAnchor(on(palm, "ClothAnchor", Vector3.one * 0.2, CFrame.new(i * 0.2 * s, -0.4 * s, 0) * back), 6, rand(0.4, 0.55) * s, 0.07 * s, C3(170, 130, 220), { Drag = 0.98, Gravity = 0.6, Material = "Neon" })
		end
		-- five fingers off the palm's far edge, the middle one longest, and a thumb: each two bones on joints of their
		-- own (GreatFinger at the palm, GreatFinger2 at the knuckle) and a hooked dark talon
		local function finger(i, base, l)
			local l2 = l * 0.8
			local seg = piece("GreatBone", V3(0.13 * s, l, 0.13 * s), ASH:Lerp(BONE, 0.5))
			seg:SetAttribute("Finger", i)
			joint("GreatFinger", palm, seg, base, CFrame.new(0, l / 2, 0))
			on(seg, "GreatKnuckle", Vector3.one * 0.2 * s, CFrame.new(0, -l / 2, 0), BONE, Enum.PartType.Ball)
			local seg2 = piece("GreatBone", V3(0.11 * s, l2, 0.11 * s), ASH:Lerp(BONE, 0.5))
			seg2:SetAttribute("Finger", i)
			joint("GreatFinger2", seg, seg2, CFrame.new(0, -l / 2, 0), CFrame.new(0, l2 / 2, 0))
			local talon = on(seg2, "GreatTalon", V3(0.09 * s, 0.5 * s, 0.09 * s), CFrame.new(0, -l2 / 2 - 0.2 * s, 0) * CFrame.Angles(0.6, 0, 0), DARK)
			local a = Instance.new("Attachment") -- (her strings go up from here)
			a.Parent = talon
			table.insert(tips, a)
		end
		local function meta(to) -- a bone of the hand: from the wrist out to a finger's root, a knuckle on its end
			local a = V3(to.X * 0.25, -0.05 * s, 0)
			on(palm, "GreatMeta", V3(0.1 * s, 0.1 * s, (to - a).Magnitude), CFrame.lookAt((a + to) / 2, to), ASH:Lerp(BONE, 0.4))
			on(palm, "GreatKnuckle", Vector3.one * 0.19 * s, CFrame.new(to), BONE, Enum.PartType.Ball)
		end
		for i = -2, 2 do
			local to = V3(i * 0.28 * s, -0.75 * s, 0)
			meta(to)
			finger(i + 3, CFrame.new(to) * CFrame.Angles(0.25, 0, i * 0.16), (1.5 - math.abs(i) * 0.18) * s)
		end
		local thumb = V3(-sx * 0.5 * s, -0.22 * s, 0)
		meta(thumb)
		finger(6, CFrame.new(thumb) * CFrame.Angles(0.3, 0, -sx * 1.0), 0.9 * s)
	end
	for _, p in ipairs(made) do
		p.Parent = b.model
		if p.Name ~= "ClothAnchor" then -- (those stay unseen: only what hangs off them shows)
			TweenService:Create(p, TweenInfo.new(0.35), { Transparency = 0 }):Play()
		end
	end
	for _, n in ipairs({ "R", "L" }) do -- (the server's own copy of them: folded down her back, where the clients start them)
		local h = handRig(b.model, n)
		local f = HAND.Fold[1] * s
		solveHand(PM, h, V3(f.X * h.sx, f.Y, f.Z))
	end
	boss.hands = { tips = tips }
	handTo(b, 0, "Fold", 0.01)
end

---------------------------------------------------------------------------
-- (every client, every frame: the Puppeteer's hook for a character's own way of moving, after it's posed her) HER
-- OWN JOINTS, the ones the pose doesn't know about. The fingers down her limbs each crook and straighten in their
-- own time, and now and then all clench at once; her head ticks from one tilt to the next like a bird's; her wrists
-- turn; the fan of fingers behind her bared eye wheels slowly; and the great hands go where the server's sent them.
---------------------------------------------------------------------------
function M.Gait(model, st, dt, now)
	local joints, s = st.joints, st.D.s
	local g = st.gait
	if not g then
		g = { knuckles = {}, hands = {}, tick = CFrame.new(), tickTo = CFrame.new(), nextTick = 0, scan = 0, clenchAt = now + 3 }
		st.gait = g
	end
	if now >= g.scan then -- (looked for afresh now and then: her third phase puts new joints on her)
		g.scan = now + 1
		g.knuckles, g.spins, g.rest, g.flames = {}, {}, g.rest or {}, {}
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") and (d.Name == "Flame" or d.Name == "Glint" or d.Name == "Wisp" or d.Name == "Heart") then
				table.insert(g.flames, d)
			end
			if d:IsA("Motor6D") and d.Name == "Knuckle" then
				table.insert(g.knuckles, d)
			elseif d:IsA("Motor6D") and d.Name == "Spin" then -- (what turns about her third phase's head)
				g.rest[d] = g.rest[d] or d.C0
				table.insert(g.spins, { m = d, rest = g.rest[d], y = d:GetAttribute("Axis") == "Y", rate = d:GetAttribute("Rate") or 0.3 })
			end
		end
	end
	if now > g.clenchAt + 0.7 then
		g.clenchAt = now + 3 + math.random() * 6
	end
	local clench = math.max(0, math.sin(math.clamp((now - g.clenchAt) / 0.7, 0, 1) * math.pi))
	-- (and with what she's doing: every finger spread as she winds up, all shut as she strikes)
	local bp = model:GetAttribute("BP") or ""
	local want = (bp:find("Set") or bp:find("Rear") or bp:find("Splay")) and -0.45 or (bp:find("Rake") or bp:find("Slam") or bp:find("Thrust") or bp:find("Pierce") or bp:find("Yank")) and 0.9 or 0
	g.grip = (g.grip or 0) + (want - (g.grip or 0)) * (1 - math.exp(-dt * 14))
	for i, m in ipairs(g.knuckles) do
		m.C0 = CFrame.Angles(0.25 + 0.3 * math.sin(now * (0.7 + (i % 5) * 0.23) + i * 1.7) * (1 - math.abs(g.grip)) + 0.7 * clench + g.grip, 0, 0)
	end
	-- THE WEIGHT OF HER, over whatever pose she's in. She leans into where she's going, and out of a turn her arms
	-- are flung wide; every new pose lands with a shudder up her spine that dies away, harder the quicker she got
	-- there; and whatever she's doing, what she has for a head stays turned on you
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and dt > 0 then
		local pos, look = root.Position, root.CFrame.LookVector
		local yaw = math.atan2(-look.X, -look.Z)
		local vel = g.pos and root.CFrame:VectorToObjectSpace((pos - g.pos) / dt) or Vector3.zero
		local spin = g.yaw and ((yaw - g.yaw + math.pi) % (2 * math.pi) - math.pi) / dt or 0
		g.pos, g.yaw = pos, yaw
		local k = 1 - math.exp(-dt * 6)
		g.lean = (g.lean or Vector3.zero):Lerp(Vector3.new(math.clamp(vel.Z / s * 0.012, -0.25, 0.25), 0, math.clamp(-vel.X / s * 0.012, -0.25, 0.25)), k)
		g.fling = (g.fling or 0) + (math.clamp(math.abs(spin) * 0.1, 0, 0.7) - (g.fling or 0)) * k
		if joints.Root and joints.Root.Parent then
			joints.Root.C0 *= CFrame.Angles(g.lean.X, 0, g.lean.Z)
		end
		if joints.RShoulder and joints.LShoulder then
			joints.RShoulder.C0 *= CFrame.Angles(0, 0, g.fling)
			joints.LShoulder.C0 *= CFrame.Angles(0, 0, -g.fling)
		end
	end
	local bpn = model:GetAttribute("BPN")
	if bpn ~= g.bpn then
		g.bpn, g.kickAt = bpn, now
		g.kick = math.clamp(0.2 / (model:GetAttribute("BPT") or 0.2), 0, 1)
	end
	g.kick = (g.kick or 0) * math.exp(-dt * 6)
	if g.kick > 0.02 and joints.Waist and joints.Waist.Parent then
		local w = now - g.kickAt
		joints.Waist.C0 *= CFrame.Angles(math.sin(w * 20) * 0.07 * g.kick, 0, math.sin(w * 15) * 0.05 * g.kick)
	end
	local me = game:GetService("Players").LocalPlayer
	local you = me and me.Character and me.Character:FindFirstChild("HumanoidRootPart")
	local chest = model:FindFirstChild("Chest")
	if you and chest and joints.Neck and joints.Neck.Parent then
		local to = chest.CFrame:PointToObjectSpace(you.Position)
		local aim = Vector3.new(math.clamp(math.atan2(to.Y, math.sqrt(to.X * to.X + to.Z * to.Z)), -0.6, 0.3), math.clamp(math.atan2(-to.X, -to.Z), -0.9, 0.9), 0)
		g.look = (g.look or Vector3.zero):Lerp(aim, 1 - math.exp(-dt * 4))
		joints.Neck.C0 *= CFrame.Angles(g.look.X * 0.6, g.look.Y * 0.6, 0)
	end
	-- her flames gutter, each in its own time
	for i, f in ipairs(g.flames or {}) do
		f.LocalTransparencyModifier = 0.18 + 0.18 * math.sin(now * (9 + i % 4 * 2.3) + i * 2.1) * math.sin(now * 3.1 + i)
	end
	if now >= g.nextTick then
		g.nextTick = now + 0.5 + math.random() * 1.8
		g.tickTo = CFrame.Angles((math.random() - 0.5) * 0.16, (math.random() - 0.5) * 0.3, (math.random() - 0.5) * 0.34)
	end
	g.tick = g.tick:Lerp(g.tickTo, 1 - math.exp(-dt * 18)) -- (snapped to, not eased)
	if joints.Neck and joints.Neck.Parent then
		joints.Neck.C0 *= g.tick
	end
	for i, n in ipairs({ "RWrist", "LWrist" }) do
		local m = joints[n]
		if m and m.Parent then
			m.C0 *= CFrame.Angles(0.18 * math.sin(now * 1.3 + i * 2), 0, 0.12 * math.sin(now * 0.9 + i))
		end
	end
	for _, sp in ipairs(g.spins or {}) do
		if sp.m.Parent then
			sp.m.C0 = sp.rest * (sp.y and CFrame.Angles(0, now * sp.rate, 0) or CFrame.Angles(0, 0, now * sp.rate))
		end
	end
	for _, n in ipairs({ "R", "L" }) do
		local order = model:GetAttribute("GHN" .. n)
		local h = g.hands[n]
		if h and not h.mU.Parent then
			h, g.hands[n] = nil, nil
		end
		if order and not h then
			h = handRig(model, n)
			if h then
				PM = PM or require(ReplicatedStorage:WaitForChild("PuppetMath"))
				local f = HAND.Fold[1] * s
				h.at, h.curl = Vector3.new(f.X * h.sx, f.Y, f.Z), HAND.Fold[2]
				g.hands[n] = h
			end
		end
		if h then
			if h.order ~= order then
				h.order, h.from, h.t0 = order, h.at, now
				h.to, h.world = model:GetAttribute("GH" .. n), model:GetAttribute("GHW" .. n)
				h.dur, h.mode, h.curlTo = model:GetAttribute("GHT" .. n) or 0.3, model:GetAttribute("GHS" .. n) or 0, model:GetAttribute("GHC" .. n) or 0.1
			end
			local k = math.clamp((now - h.t0) / h.dur, 0, 1)
			k = h.mode == 1 and k * k or h.mode == 2 and k or k * k * (3 - 2 * k)
			h.at = h.from:Lerp(h.world and h.chest.CFrame:PointToObjectSpace(h.to) or h.to, k)
			local sway = h.mode == 0 and s or 0 -- (sent somewhere hard, or planted: no drifting)
			solveHand(PM, h, h.at + Vector3.new(0, math.sin(now * 1.3 + h.sx) * 0.12, math.cos(now * 0.9 + h.sx) * 0.1) * sway)
			h.curl += (h.curlTo - h.curl) * (1 - math.exp(-dt * 10))
			for _, f in ipairs(h.fingers) do
				local ripple = math.sin(now * 2.1 - f.i * 0.7 + h.sx) * 0.12 -- (along them, little finger to first)
				f.m.C0 = f.rest * CFrame.Angles((f.second and 0.35 + h.curl * 1.2 or h.curl * 0.9) + ripple, 0, 0)
			end
		end
	end
end

-- her strings: from every finger of the great hands up into the dark over the middle of the sand
local function stringUp()
	boss.strings = {}
	local A = arena()
	do
		for _, tip in ipairs(boss.hands and boss.hands.tips or {}) do
			local anchor = Instance.new("Attachment")
			anchor.Position = tip.WorldPosition
			anchor.Parent = workspace.Terrain
			local beam = Instance.new("Beam")
			beam.Attachment0, beam.Attachment1 = tip, anchor
			beam.Width0, beam.Width1, beam.Segments, beam.FaceCamera = 0.08, 0.5, 1, true
			beam.Color = ColorSequence.new(VIOLET)
			beam.LightEmission, beam.Transparency = 0.6, NumberSequence.new(0.3)
			beam.Parent = workspace.Terrain
			TweenService:Create(anchor, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = A.Centre + V3(rand(-10, 10), 170, rand(-10, 10)) }):Play()
			table.insert(boss.strings, beam)
			table.insert(boss.fx, beam)
			table.insert(boss.fx, anchor)
		end
	end
end
local function flareStrings(on) -- (drawn taut and thrumming, or let hang again)
	for _, beam in ipairs(boss.strings or {}) do
		beam.Color = ColorSequence.new(on and PALE or VIOLET)
		beam.Width0, beam.Width1 = on and 0.2 or 0.08, on and 1.4 or 0.5
	end
end
local function clearFx()
	for _, x in ipairs(boss.fx) do
		x:Destroy()
	end
	boss.fx, boss.hands, boss.strings, boss.rocks = {}, nil, nil, nil
end

-- a rig that's already up, dressed as RigBuilder's deco dresses one being built (her third phase's face)
local function liveDeco(model)
	return function(on, name, size, offset, color, mat, shape)
		local base = model:FindFirstChild(on)
		local d = Instance.new("Part")
		d.Name = name
		if shape then
			d.Shape = shape
		end
		d.Size, d.Color, d.Material = size, color, mat or MAT.SmoothPlastic
		d.CanCollide, d.CanQuery, d.CanTouch, d.Massless = false, false, false, true
		d.TopSurface, d.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		d.CFrame = base.CFrame * offset
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = base, d
		w.Parent = d
		d.Parent = model
		return d
	end
end
-- the hand over her face lets go: under it, her eye, and every finger of the hand fanned out behind it (F.Face3)
local function unmask(b)
	for _, p in ipairs(b.model:GetChildren()) do
		if p:GetAttribute("Face") then
			p:Destroy()
		end
	end
	-- (F.Head3 times the size her first face was: grown up off her neck, not down into it)
	local s3 = b.scale * F.Head3
	local lift = CFrame.new(0, 0.55 * (s3 - b.scale), 0)
	local deco = liveDeco(b.model)
	dressFace(F.Face3, function(on, name, size, offset, ...)
		return deco(on, name, size, lift * offset, ...)
	end, s3)
	local head = b.model:FindFirstChild("Head")
	local glint = b.model:FindFirstChild("Glint")
	if glint then
		local light = Instance.new("PointLight")
		light.Color, light.Range, light.Brightness = EYE, 26, 2.4
		light.Parent = glint
	end
	-- WHAT TURNS ABOUT HER HEAD (every client turns them: M.Gait, any joint named "Spin", by its Axis and Rate): each a
	-- hub on a joint of its own off her head, with its pieces welded to it
	local function spinner(at, axis, rate)
		local hub = Instance.new("Part")
		hub.Name, hub.Size, hub.Transparency = "SpinHub", Vector3.one * 0.2, 1
		hub.CanCollide, hub.CanQuery, hub.CanTouch, hub.Massless = false, false, false, true
		hub.CFrame = head.CFrame * at
		local m = Instance.new("Motor6D")
		m.Name = "Spin"
		m.Part0, m.Part1, m.C0 = head, hub, at
		m:SetAttribute("Axis", axis)
		m:SetAttribute("Rate", rate)
		m.Parent = hub
		return hub
	end
	local function hung(hub, name, size, cf, color, mat, shape) -- a piece on a hub, at cf in its space
		local p = Instance.new("Part")
		p.Name, p.Size, p.Color, p.Material = name, size, color, mat or MAT.SmoothPlastic
		if shape then
			p.Shape = shape
		end
		p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, true
		p.CFrame = hub.CFrame * cf
		p:SetAttribute("Face", true)
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = hub, p
		w.Parent = p
		p.Parent = b.model
		return p
	end
	if F.Face3 == 21 then -- the fan of fingers behind her eye, wheeling slowly
		local hub = spinner(lift * CFrame.new(V3(0, 0.25, 0.15) * s3), "Z", 0.35)
		for _, p in ipairs(b.model:GetChildren()) do
			local w = p:GetAttribute("Face") and (p.Name == "Bone" or p.Name == "Knob" or p.Name == "Talon") and p:FindFirstChildOfClass("WeldConstraint")
			if w then
				w:Destroy()
				w = Instance.new("WeldConstraint")
				w.Part0, w.Part1 = hub, p
				w.Parent = p
			end
		end
		hub.Parent = b.model
	end
	-- a great wheel of bone stood behind all of it, wider than her shoulders, turning the other way: a spike out of
	-- every other joint of it, a mote of her light on every fifth
	local wheelHub = spinner(lift * CFrame.new(V3(0, 0.25, 0.32) * s3), "Z", -0.18)
	local WR, WN = 1.75 * s3, 20
	local function rimAt(i, r)
		local a = i / WN * math.pi * 2
		return V3(math.cos(a) * r, math.sin(a) * r, 0)
	end
	for i = 0, WN - 1 do
		local p0, p1 = rimAt(i, WR), rimAt(i + 1, WR)
		hung(wheelHub, "WheelRim", V3(0.07 * s3, 0.07 * s3, (p1 - p0).Magnitude), CFrame.lookAt((p0 + p1) / 2, p1), BONE)
		if i % 2 == 0 then
			local tip = rimAt(i, WR + (i % 4 == 0 and 0.5 or 0.28) * s3)
			hung(wheelHub, "WheelSpike", V3(0.05 * s3, 0.05 * s3, (tip - p0).Magnitude), CFrame.lookAt((p0 + tip) / 2, tip), i % 4 == 0 and BONE or DARK)
		end
		if i % 5 == 0 then
			hung(wheelHub, "WheelMote", Vector3.one * 0.14 * s3, CFrame.new(p0), EYE, MAT.Neon, Enum.PartType.Ball)
		end
	end
	wheelHub.Parent = b.model
	-- and her six flames, off their wicks: circling her head, each at its own height
	local wispHub = spinner(lift * CFrame.new(0, 0.25 * s3, 0), "Y", 1.1)
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		local wisp = hung(wispHub, "Wisp", Vector3.one * 0.15 * b.scale, CFrame.new(math.cos(a) * 1.15 * s3, (i % 3 - 1) * 0.4 * s3, math.sin(a) * 1.15 * s3), EYE, MAT.Neon, Enum.PartType.Ball)
		if i % 2 == 0 then
			local wl = Instance.new("PointLight")
			wl.Color, wl.Range, wl.Brightness = EYE, 9, 1
			wl.Parent = wisp
		end
	end
	wispHub.Parent = b.model
	burst(head.Position, BONE, 30, 0.5, 26)
	burst(head.Position, EYE, 24, 0.4, 18)
end
-- the sand rots black, out from the middle to the colonnade
local function spreadRot(dur)
	local A = arena()
	local p = Instance.new("Part")
	p.Name, p.Shape = "OssariaRot", Enum.PartType.Cylinder
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Size, p.CFrame = V3(0.1, 1, 1), CFrame.new(A.Centre + V3(0, 0.06, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	p.Color, p.Material, p.Transparency = ROT, MAT.SmoothPlastic, 0.08
	p.Parent = workspace
	TweenService:Create(p, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Size = V3(0.1, A.Radius * 2 + 8, A.Radius * 2 + 8) }):Play()
	table.insert(boss.fx, p)
end

---------------------------------------------------------------------------
-- MOVES (each returns when it's done; picked by range in brain)
---------------------------------------------------------------------------
local function idle(b)
	bodyPose(b, boss.phase == 3 and "OHLoom" or "OHIdle", 0.6)
	handTo(b, 0, "Loom", 0.6)
end
local function recover(b, t) -- left as the move ended a while (your opening), then back on guard
	if hold(b, t) then
		idle(b)
	end
end
-- carried bodily (anchored) along a leap: from a to `to` (root positions) over dur seconds, rising height at the top
local function flight(b, a, to, dur, height, each)
	local root = b.root
	root.Anchored = true
	local dir = flat(to - a)
	dir = dir.Magnitude > 0.1 and dir.Unit or flat(root.CFrame.LookVector).Unit
	local t0 = now()
	while true do
		local t = math.min((now() - t0) / dur, 1)
		local p = a:Lerp(to, t) + V3(0, 4 * height * t * (1 - t), 0)
		root.CFrame = CFrame.lookAt(p, p + dir)
		if each then
			each(t)
		end
		if t >= 1 or boss.gen ~= b.gen then
			break
		end
		RunService.Heartbeat:Wait()
	end
	root.AssemblyLinearVelocity = Vector3.zero
	if live(b) then
		root.Anchored = false
	end
end

-- A LEAP of hers (the pounce, the hounding): carried along it (flight), and all of her moving through it - off the
-- sand arched back with every limb flung wide (the great hands too, in her third phase), hung spread at the top of
-- it, then folded to a point, both talons driven out ahead of her, and down nose first onto where it ends
local function leap(b, from, to, dur, height)
	local folded = false
	bodyPose(b, "OHSplay", dur * 0.3)
	handTo(b, 0, "Sky", dur * 0.35)
	flight(b, from, to, dur, height, function(t)
		if not folded and t >= 0.55 then
			folded = true
			bodyPose(b, "OHPierce", dur * 0.3)
			handTo(b, 0, "Rear", dur * 0.3)
		end
		b.root.CFrame *= CFrame.Angles(0.45 - 1.4 * smooth((t - 0.3) / 0.7), 0, 0) -- (reared back, then over onto her nose)
	end)
	local d = flat(to - from)
	if live(b) and d.Magnitude > 0.1 then
		b.root.CFrame = CFrame.lookAt(to, to + d.Unit) -- (upright again, as she lands)
	end
end
local function plant(b, at) -- (her third phase) the great hands down on the sand either side of where she's landed
	local right = flat(b.root.CFrame.RightVector).Unit
	for _, s in ipairs({ -1, 1 }) do
		handTo(b, s, at + right * s * 7 + V3(0, 0.5, 0), 0.1, true, 0.45)
	end
end

---------------------------------------------------------------------------
-- HER TELLS. Every move of hers starts with a spark of her light and a high note (flare: off the hand that's about to
-- do it, or her heart); every cut shows its reach on the sand ahead of her for its last moment (fan), by when she's
-- stopped turning with you; everything that comes down shows the pool it comes down on (mark). And she's never
-- still for any of it: a scuttle round you or in at you before she casts or strikes (shift), a lunge with every cut.
---------------------------------------------------------------------------
-- THE COLOSSEUM FEELS IT, whenever something of hers lands hard: dust shaken down off the colonnade all the way round,
-- stone off the feet of some of its pillars
local function tremor(power)
	for _ = 1, math.floor(3 + power * 5) do
		local k = math.random(0, PILLARS - 1)
		dustCloud(pillar(k, 19), 2 + power * 2, 6)
		if math.random() < 0.4 then
			Core.debrisChunks(pillar(k, 1), 3, 14)
		end
	end
end
local LOCK = 0.28 -- (the last of a wind-up: she's stopped turning, and where it will land is shown)
local function flare(b, n) -- n: "R" | "L", or nil = her heart
	local part = b.model:FindFirstChild(n and (n .. "Hand") or "Heart") or b.root
	burst(part.Position, PALE, 12, 0.35, 12)
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = PALE, 16, 5
	l.Parent = part
	TweenService:Create(l, TweenInfo.new(0.45), { Brightness = 0 }):Play()
	Debris:AddItem(l, 0.5)
	playSound(b.root, SOUNDS.Unsheath, 0.55, 1.9)
end
local function fan(o, dir, range, arc, life) -- a cut's reach, drawn on the sand from o: arc degrees either side of dir
	local th0, a = math.atan2(dir.Z, dir.X), math.rad(arc)
	local function at(u, r)
		return o + V3(math.cos(th0 + u), 0, math.sin(th0 + u)) * r + V3(0, 0.12, 0)
	end
	local parts = { strand(at(-a, 1.5), at(-a, range), 0.2, 0.5), strand(at(a, 1.5), at(a, range), 0.2, 0.5) }
	for i = 0, 5 do
		table.insert(parts, strand(at(-a + i / 3 * a, range), at(-a + (i + 1) / 3 * a, range), 0.2, 0.5))
	end
	for _, p in ipairs(parts) do
		p.Color = PALE
		TweenService:Create(p, TweenInfo.new(life), { Transparency = 0.05 }):Play()
		Debris:AddItem(p, life)
	end
end
-- a scuttle before a move: round you by dist (way: 1 | -1), or straight in at you to within eight (way 0), low and quick
local function shift(b, tchar, dist, way)
	local tr = tchar and tchar:FindFirstChild("HumanoidRootPart")
	if not tr or not free(b) or b.root.Anchored then
		return
	end
	local from = b.root.Position
	local rel = flat(from - tr.Position)
	local r = rel.Magnitude
	if r < 1 then
		return
	end
	local to
	if way == 0 then
		to = from - rel.Unit * math.min(dist, math.max(r - 8, 0))
	else
		to = tr.Position + CFrame.Angles(0, way * dist / r, 0):VectorToWorldSpace(rel)
	end
	to = clampToArena(b, to)
	if flat(to - from).Magnitude < 2 then
		return
	end
	bodyPose(b, "OHCrawl", 0.12)
	dustCloud(ground(from), 1.6, 4)
	flight(b, from, to, 0.3, 1.0)
	if live(b) then
		local face = flat(tr.Position - to)
		if face.Magnitude > 0.1 then
			b.root.CFrame = CFrame.lookAt(to, to + face.Unit) -- (her face back on you as she stops)
		end
	end
end
local function either()
	return math.random() < 0.5 and 1 or -1
end
-- ONE CUT of a talon (the rake's, the frenzy's): wound up on side n for tell seconds, turning with you; then for the
-- last LOCK of it she's stopped, its reach drawn on the sand where it will land; then she's thrown at you with it, a
-- lunge of up to step along the sand, and it cuts as she arrives
local function cut1(b, tchar, n, tell, step, range, arc, damage)
	local tr = tchar:FindFirstChild("HumanoidRootPart")
	bodyPose(b, "OHRakeSet" .. n, 0.16)
	flare(b, n)
	if not hold(b, math.max(tell - LOCK, 0.05), tchar, 2.2) then
		return false
	end
	local from = b.root.Position
	local d = flat(tr.Position - from)
	local dir = d.Magnitude > 0.1 and d.Unit or flat(b.root.CFrame.LookVector).Unit
	local to = clampToArena(b, from + dir * math.clamp(d.Magnitude - 5, 0, step))
	fan(ground(to), dir, range, arc, LOCK * tempo() + 0.2)
	if not hold(b, LOCK) then
		return false
	end
	bodyPose(b, "OHRake" .. n, 0.08)
	playSound(b.root, SOUNDS.Lunge, 0.9, 0.8)
	local done = false
	flight(b, from, to, 0.2, 0.7, function(t)
		if t >= 0.9 and not done then
			done = true
			hitOnce(playersInSector(CFrame.lookAt(to, to + dir), range, arc, 10), {}, damage, to, "Medium")
			burst(ground(to + dir * 7) + V3(0, 3, 0), VIOLET, 16, 0.4, 26)
			dustCloud(ground(to + dir * 5), 2.5, 6)
		end
	end)
	if live(b) then
		bodyPose(b, "OHRakeEnd" .. n, 0.1)
		return true
	end
	return false
end

-- both talons hoisted up over her and brought down: a blast round where they bite the sand, SlamReach ahead of her.
-- She walks in at you as she hoists them; for the last LOCK of it she's stopped, the pool it'll land on shown
local function slam(b, tchar, tell)
	local tr = tchar and tchar:FindFirstChild("HumanoidRootPart")
	bodyPose(b, "OHRear", 0.3 * tempo())
	flare(b)
	if tr then
		b.hum.WalkSpeed = F.WalkSpeed * 1.3
		b.hum:MoveTo(clampToArena(b, tr.Position))
	end
	local ok = hold(b, math.max(tell - LOCK, 0.05), tchar, 0.9)
	b.hum:MoveTo(b.root.Position)
	if not ok then
		return false
	end
	local pool = mark(b.root.Position + flat(b.root.CFrame.LookVector).Unit * F.SlamReach, F.SlamRadius, LOCK * tempo())
	ok = hold(b, LOCK)
	unmark(pool)
	if not ok then
		return false
	end
	bodyPose(b, "OHSlam", 0.1)
	task.wait(0.1)
	if not live(b) then
		return false
	end
	local at = ground(b.root.Position + flat(b.root.CFrame.LookVector).Unit * F.SlamReach)
	hitOnce(playersInRadius(at, F.SlamRadius, 8), {}, F.SlamDamage, at, "Knockdown")
	shockwave(at, F.SlamRadius)
	erupt(at, F.SlamRadius * 0.6)
	playSound(b.root, SOUNDS.WatchdogSmash, 1, 0.5)
	shake(at, 1.1)
	tremor(0.6)
	task.delay(0.4, function()
		if live(b) and b.model:GetAttribute("BP") == "OHSlam" then
			bodyPose(b, "OHSlamUp", 0.5)
		end
	end)
	return true
end

-- THE RAKE: a long arm wound right back and torn across in front of her, stepping into you - one side, then the
-- other - and then both talons brought down
local function rake(b, tchar)
	for i, n in ipairs({ "R", "L" }) do
		if not cut1(b, tchar, n, i == 1 and F.RakeTell or F.RakeTell * 0.9, F.RakeStep, F.RakeRange, F.RakeArc, F.RakeDamage) then
			return
		end
		if not hold(b, 0.35) then
			return
		end
	end
	if slam(b, tchar, F.SlamTell) then
		recover(b, F.RakeRecover)
	end
end

-- THE POUNCE: down on her haunches, a talon on the sand, then up and over onto where you stand
local function pounce(b, tchar)
	local tr = tchar:FindFirstChild("HumanoidRootPart")
	b.hum:MoveTo(b.root.Position)
	bodyPose(b, "OHLand", 0.3 * tempo())
	dustCloud(ground(b.root.Position), 1.6, 5)
	playSound(b.root, SOUNDS.Unsheath, 0.8, 0.4)
	if not hold(b, F.PounceTell, tchar, 1.2) then
		return
	end
	local from = b.root.Position
	local to = clampToArena(b, tr.Position + flat(tr.AssemblyLinearVelocity) * 0.25)
	local d = flat(to - from)
	if d.Magnitude > 5 then
		to -= d.Unit * 4 -- (lands just short: the blast is round her)
	end
	playSound(b.root, SOUNDS.Lunge, 1, 0.5)
	local pool = mark(to, F.PounceRadius, F.PounceTime)
	leap(b, from, to, F.PounceTime, F.PounceHeight)
	unmark(pool)
	if not live(b) then
		return
	end
	bodyPose(b, "OHLand", 0.08)
	local at = ground(b.root.Position)
	plant(b, at)
	hitOnce(playersInRadius(at, F.PounceRadius, 8), {}, F.PounceDamage, at, "Launch")
	shockwave(at, F.PounceRadius)
	erupt(at, F.PounceRadius * 0.6)
	playSound(b.root, SOUNDS.Impact, 1, 0.45)
	shake(at, 1.3)
	tremor(0.8)
	recover(b, F.PounceRecover)
end

-- HER STRINGS: a hand held out, and a fan of them laid along the sand from her, faint; a beat later she wrenches
-- them taut, and every one cuts. Phase 3: a second fan straight after
local function threads(b, tchar)
	local tr = tchar:FindFirstChild("HumanoidRootPart")
	b.hum:MoveTo(b.root.Position)
	shift(b, tchar, 12, either())
	for _ = 1, boss.phase == 3 and 2 or 1 do
		bodyPose(b, "OHCast", 0.3 * tempo())
		if not hold(b, 0.4, tchar, 1.5) then
			return
		end
		local o = ground(b.root.Position) + V3(0, 0.15, 0)
		local aim = flat(tr.Position - o)
		aim = aim.Magnitude > 0.1 and aim.Unit or flat(b.root.CFrame.LookVector).Unit
		local a0 = math.atan2(aim.Z, aim.X) + rand(-0.5, 0.5) * F.ThreadSpread
		local lines = {}
		for i = 1, F.ThreadCount do
			local a = a0 + (i - (F.ThreadCount + 1) / 2) * F.ThreadSpread
			local dir = V3(math.cos(a), 0, math.sin(a))
			table.insert(lines, { triple(o + dir * 3, o + dir * (3 + F.ThreadLength), 0.22, 0.6), o + dir * 3, dir })
		end
		playSound(b.root, SOUNDS.Unsheath, 0.8, 1.6)
		if not hold(b, F.ThreadTell) then
			for _, l in ipairs(lines) do
				for _, p in ipairs(l[1]) do
					p:Destroy()
				end
			end
			return
		end
		bodyPose(b, "OHYank", 0.08)
		playSound(b.root, SOUNDS.Lunge, 1, 1.2)
		shake(o, 0.5)
		local seen = {}
		for _, l in ipairs(lines) do
			for _, p in ipairs(l[1]) do
				pluck(p, 0.9)
			end
			cut(l[2], l[3], F.ThreadLength, F.ThreadWidth, seen, F.ThreadDamage, "Medium")
		end
		if not hold(b, 0.3) then
			return
		end
	end
	recover(b, F.ThreadRecover)
end

-- THE CAT'S CRADLE: she flicks her strings out, hand after hand, and each catches on two of the colosseum's pillars:
-- a string across the sand at the height of your chest, through where you stand, each at its own angle - a web
-- drawn round you. Each is wrenched taut CradleTell after it's strung, in the order they went out
local function chord(q, ang) -- the string through q at bearing ang: its two ends, on the pillars nearest
	local A = arena()
	local d = V3(math.cos(ang), 0, math.sin(ang))
	local rel = flat(q - A.Centre)
	if rel.Magnitude > 38 then
		rel = rel.Unit * 38
	end
	local along = rel:Dot(d)
	local reach = math.sqrt(math.max(44.6 ^ 2 - (rel:Dot(rel) - along * along), 0))
	local function nearest(p)
		return pillar(math.floor(math.atan2(p.Z, p.X) / (math.pi * 2) * PILLARS + 0.5), 3.2)
	end
	return nearest(rel + d * (reach - along)), nearest(rel - d * (reach + along))
end
local function cradle(b, tchar)
	local tr = tchar:FindFirstChild("HumanoidRootPart")
	b.hum:MoveTo(b.root.Position)
	shift(b, tchar, 10, either())
	local n = F.CradleCount + (boss.phase == 3 and 2 or 0)
	local a0 = rand(0, math.pi)
	for i = 1, n do
		bodyPose(b, i % 2 == 1 and "OHCast" or "OHCastL", 0.18)
		local q = tr.Position + flat(tr.AssemblyLinearVelocity) * 0.4
		if i > 1 then -- (the first is dead on you)
			q += V3(rand(-6, 6), 0, rand(-6, 6))
		end
		local p1, p2 = chord(q, a0 + (i - 1) * math.pi / n + rand(-0.12, 0.12))
		local line = triple(p1, p2, 0.18, 0.55)
		burst(p1, VIOLET, 8, 0.3, 8)
		burst(p2, VIOLET, 8, 0.3, 8)
		playSound(b.root, SOUNDS.Unsheath, 0.6, 1.5 + i * 0.12)
		task.delay(F.CradleTell * tempo(), function()
			if live(b) then
				local d = flat(p2 - p1)
				cut(p1, d.Unit, d.Magnitude, F.CradleWidth, {}, F.CradleDamage, "Medium")
				playSound(b.root, SOUNDS.Lunge, 0.7, 1.4)
			end
			for _, p in ipairs(line) do
				pluck(p, 0.9)
			end
		end)
		if not hold(b, F.CradleGap, tchar, 1) then
			return
		end
	end
	bodyPose(b, "OHYank", 0.1)
	recover(b, F.CradleRecover)
end

-- THE SKITTER: down on all fours and round you in a scuttle, sideways, her face on you the whole way - then out of
-- it straight at you, a talon first
local function skitter(b, tchar)
	local tr = tchar:FindFirstChild("HumanoidRootPart")
	bodyPose(b, "OHCrawl", 0.25 * tempo())
	playSound(b.root, SOUNDS.Unsheath, 0.7, 0.5)
	b.hum.WalkSpeed = F.SkitterSpeed
	local way = math.random() < 0.5 and 1 or -1
	local t0 = now()
	while now() - t0 < F.SkitterTime * tempo() do
		if not free(b) then
			b.hum:MoveTo(b.root.Position)
			return
		end
		local away = flat(b.root.Position - tr.Position)
		away = away.Magnitude > 0.1 and away.Unit or V3(1, 0, 0)
		b.hum:MoveTo(clampToArena(b, tr.Position + CFrame.Angles(0, way * 0.9, 0):VectorToWorldSpace(away) * 14))
		turnTowards(b.root, tr.Position, math.rad(400) * task.wait())
	end
	b.hum:MoveTo(b.root.Position)
	bodyPose(b, "OHThrustSet", 0.15)
	if not hold(b, F.SkitterTell, tchar, 2) then
		return
	end
	local from = b.root.Position
	local d = flat(tr.Position - from)
	local dir = d.Magnitude > 0.1 and d.Unit or flat(b.root.CFrame.LookVector).Unit
	bodyPose(b, "OHThrust", 0.08)
	playSound(b.root, SOUNDS.Lunge, 1, 0.7)
	local seen = {}
	flight(b, from, clampToArena(b, from + dir * math.min(d.Magnitude + 4, F.SkitterLunge)), 0.28, 1.2, function(t)
		if t > 0.15 then
			hitOnce(playersInRadius(b.root.Position + dir * 4, 4.5, 8), seen, F.SkitterDamage, b.root.Position, "Large")
		end
	end)
	dustCloud(ground(b.root.Position), 2, 8)
	recover(b, F.SkitterRecover)
end

-- THE WHEEL (when you're in under her): wound right round, arms flung out, and spun twice on the spot, her talons
-- and every rag of her out level round her - each turn of it can catch you
local function wheel(b, tchar)
	b.hum:MoveTo(b.root.Position)
	bodyPose(b, "OHWheelSet", 0.3 * tempo())
	local tr = tchar:FindFirstChild("HumanoidRootPart")
	local way = tr and flat(tr.Position - b.root.Position) or Vector3.zero
	local travel = way.Magnitude > 0.1 and way.Unit * math.min(F.WheelTravel, math.max(way.Magnitude - 3, 0)) or Vector3.zero
	local pool = mark(b.root.Position + travel * 0.5, F.WheelRadius + travel.Magnitude * 0.5, F.WheelTell * tempo())
	local wound = hold(b, F.WheelTell, tchar, 1)
	unmark(pool)
	if not wound then
		return
	end
	bodyPose(b, "OHWheel", 0.1)
	playSound(b.root, SOUNDS.Lunge, 1, 0.6)
	local root = b.root
	root.Anchored = true
	local cf0, t0, nextHit = root.CFrame, now(), 1
	while true do
		local k = math.min((now() - t0) / F.WheelTime, 1)
		root.CFrame = (cf0 + travel * k) * CFrame.Angles(0, -k * math.pi * 4, 0) -- (spun, and carried at you as she spins)
		if nextHit <= 2 and k >= nextHit * 0.5 - 0.3 then -- (her talons come round to the front: once a turn)
			nextHit += 1
			hitOnce(playersInRadius(root.Position, F.WheelRadius, 8), {}, F.WheelDamage, root.Position, "Large")
			burst(ground(root.Position) + V3(0, 3, 0), VIOLET, 20, 0.4, 30)
		end
		if k >= 1 or not live(b) then
			break
		end
		RunService.Heartbeat:Wait()
	end
	root.CFrame = cf0 + travel
	if live(b) then
		root.Anchored = false
	end
	bodyPose(b, "OHTilt", 0.5)
	recover(b, F.WheelRecover)
end

-- THE FRENZY (the Orphan's way: no let-up, and no counting it): a shriek, and she comes at you swinging - five to
-- seven talons, one side then the other, each thrown at you on a lunge of its own along the sand, so there's no
-- backing out of it; most a beat apart, but any of them may hang wound up a moment longer first. Each is one cut, at
-- one instant, in front of her: roll through them, toward her. The last of it is both talons, down.
local function frenzy(b, tchar)
	local tr = tchar:FindFirstChild("HumanoidRootPart")
	b.hum:MoveTo(b.root.Position)
	bodyPose(b, "OHUnfurl", 0.25)
	playSound(b.root, SOUNDS.Groan, 1, 0.95)
	shake(b.root.Position, 0.6)
	if not hold(b, F.FrenzyTell, tchar, 1.5) then
		return
	end
	for i = 1, math.random(F.FrenzyCuts[1], F.FrenzyCuts[2]) do
		if not cut1(b, tchar, i % 2 == 1 and "R" or "L", math.random() < F.FrenzyHang and F.FrenzyLong or F.FrenzyBeat, F.FrenzyStep, F.FrenzyRange, F.FrenzyArc, F.FrenzyDamage) then
			return
		end
	end
	if slam(b, tchar, F.FrenzySlamTell) then
		recover(b, F.FrenzyRecover)
	end
end

-- THE HOUNDING: a leap onto you, talons first - and if it didn't catch you, straight off the landing into another, and
-- another, each quicker off the sand than the first
local function hound(b, tchar)
	local tr = tchar:FindFirstChild("HumanoidRootPart")
	for i = 1, F.HoundLeaps do
		b.hum:MoveTo(b.root.Position)
		bodyPose(b, "OHLand", 0.2)
		if not hold(b, i == 1 and F.HoundTell or F.HoundBeat, tchar, 2) then
			return
		end
		local from = b.root.Position
		local to = clampToArena(b, tr.Position + flat(tr.AssemblyLinearVelocity) * 0.2)
		local d = flat(to - from)
		if d.Magnitude > 4 then
			to -= d.Unit * 3
		end
		playSound(b.root, SOUNDS.Lunge, 1, 0.55)
		local pool = mark(to + (d.Magnitude > 0.1 and d.Unit or Vector3.zero) * 4, F.HoundRadius, F.HoundTime)
		leap(b, from, to, F.HoundTime, F.HoundHeight)
		unmark(pool)
		if not live(b) then
			return
		end
		bodyPose(b, "OHSlam", 0.06)
		local at = ground(b.root.Position + flat(b.root.CFrame.LookVector).Unit * 4)
		plant(b, at)
		local seen = {}
		hitOnce(playersInRadius(at, F.HoundRadius, 8), seen, F.HoundDamage, at, "Knockdown")
		shockwave(at, F.HoundRadius)
		erupt(at, F.HoundRadius * 0.6)
		playSound(b.root, SOUNDS.Impact, 1, 0.5)
		shake(at, 1.2)
		tremor(0.5)
		if next(seen) then
			break -- (she has you: no need of another)
		end
	end
	recover(b, F.HoundRecover)
end

-- THE DIRGE: both talons hoisted up over her and HELD there - as long as she likes, never the same twice (roll on
-- the hoist and it finds you getting up) - then down; and the rot runs on from where they bite, well after well in a
-- line along the sand out to the colonnade, a hand up out of each
local function dirge(b, tchar)
	b.hum:MoveTo(b.root.Position)
	shift(b, tchar, 14, 0)
	bodyPose(b, "OHRear", 0.35)
	playSound(b.root, SOUNDS.Groan, 0.9, 0.7)
	if not hold(b, rand(F.DirgeHold[1], F.DirgeHold[2]), tchar, 1.6) then
		return
	end
	local pool = mark(b.root.Position + flat(b.root.CFrame.LookVector).Unit * F.SlamReach, F.SlamRadius, LOCK * tempo())
	local held = hold(b, LOCK)
	unmark(pool)
	if not held then
		return
	end
	bodyPose(b, "OHSlam", 0.08)
	task.wait(0.09)
	if not live(b) then
		return
	end
	local dir = flat(b.root.CFrame.LookVector).Unit
	local o = ground(b.root.Position) + dir * F.SlamReach
	hitOnce(playersInRadius(o, F.SlamRadius, 8), {}, F.SlamDamage, o, "Knockdown")
	shockwave(o, F.SlamRadius)
	erupt(o, F.SlamRadius * 0.6)
	playSound(b.root, SOUNDS.WatchdogSmash, 1, 0.5)
	shake(o, 1.2)
	for i = 1, F.DirgeWells do
		local c = o + dir * (F.SlamRadius * 0.5 + i * F.DirgeRadius * 1.5)
		if flat(c - arena().Centre).Magnitude > arena().Radius then
			break
		end
		task.delay(i * 0.13, function()
			if not live(b) then
				return
			end
			local parts = mark(c, F.DirgeRadius, 0.3)
			task.delay(0.3, function()
				if live(b) then
					erupt(c, F.DirgeRadius, true)
					hitOnce(playersInRadius(c, F.DirgeRadius, 6), {}, F.DirgeDamage, c, "Launch")
				end
				unmark(parts)
			end)
		end)
	end
	recover(b, F.DirgeRecover)
end

-- THE PULL: one string, onto YOU. PullTell later she wrenches it in: roll through the yank, or be dragged across the
-- sand to her feet, where both talons are already coming down
local function pull(b, tchar)
	local tr = tchar:FindFirstChild("HumanoidRootPart")
	local pl = Players:GetPlayerFromCharacter(tchar)
	local hand = b.model:FindFirstChild("RHand")
	if not (pl and hand) then
		return
	end
	b.hum:MoveTo(b.root.Position)
	shift(b, tchar, 9, either())
	bodyPose(b, "OHCast", 0.3 * tempo())
	flare(b, "R")
	if not hold(b, 0.35, tchar, 1.5) then
		return
	end
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Parent, a1.Parent = hand, tr
	local beam = Instance.new("Beam")
	beam.Attachment0, beam.Attachment1 = a0, a1
	beam.Width0, beam.Width1, beam.Segments, beam.FaceCamera = 0.14, 0.14, 1, true
	beam.Color = ColorSequence.new(PALE, VIOLET)
	beam.LightEmission, beam.Transparency = 0.7, NumberSequence.new(0.15)
	beam.Parent = hand
	playSound(tr, SOUNDS.Unsheath, 0.8, 1.8)
	burst(tr.Position, VIOLET, 10, 0.3, 8)
	local ok = hold(b, F.PullTell, tchar, 1.5)
	local hit = false
	if ok and tr.Parent then
		bodyPose(b, "OHYank", 0.08)
		playSound(b.root, SOUNDS.Lunge, 1, 0.8)
		local away = flat(tr.Position - b.root.Position)
		if away.Magnitude > 1 then -- (hurt "from" beyond you: thrown toward her)
			hit = damagePlayer(pl, F.PullDamage, tr.Position + away.Unit * 4, "Large", math.clamp((away.Magnitude - F.PullTo) * F.PullSpeed, 10, 300))
		end
	end
	a0:Destroy()
	a1:Destroy()
	beam:Destroy()
	if not ok then
		return
	end
	if hit and not slam(b, tchar, F.PullSlamTell) then
		return
	end
	recover(b, F.PullRecover)
end

-- WELLS OF ROT: her talons sunk into the sand, and a well opens under you, and another, and another; each erupts
-- WellDelay after it shows (the only moment it hurts)
local function well(b, at)
	local c = ground(at)
	local parts = mark(c, F.WellRadius, F.WellDelay, true)
	playSound(parts[1], SOUNDS.Lunge, 0.8, 0.3)
	task.delay(F.WellDelay, function()
		if live(b) then
			erupt(c, F.WellRadius, true)
			playSound(parts[1], SOUNDS.WatchdogSmash, 0.7, 0.45)
			hitOnce(playersInRadius(c, F.WellRadius, 6), {}, F.WellDamage, c, "Launch")
		end
		unmark(parts)
	end)
end
local function wells(b)
	b.hum:MoveTo(b.root.Position)
	shift(b, target(b), 10, either())
	bodyPose(b, "OHSlam", 0.35 * tempo())
	if not hold(b, 0.5) then
		return
	end
	shake(b.root.Position, 0.6)
	playSound(b.root, SOUNDS.Impact, 0.8, 0.35)
	for _ = 1, boss.phase == 3 and F.Wells3 or F.Wells do
		for _, hrp in pairs(everyone()) do
			well(b, hrp.Position + flat(hrp.AssemblyLinearVelocity) * 0.3)
		end
		if not hold(b, F.WellGap) then
			return
		end
	end
	recover(b, F.WellRecover)
end

-- (phase 3) THE GREAT HANDS: one hoisted up over her and brought down on you, then the other, then both together -
-- each on a pool that shows where, as far as HandReach from her
local function greatHands(b, tchar)
	local tr = tchar:FindFirstChild("HumanoidRootPart")
	b.hum:MoveTo(b.root.Position)
	shift(b, tchar, 12, 0)
	bodyPose(b, "OHLoom", 0.3)
	local lead = math.random() < 0.5 and 1 or -1
	for _, sx in ipairs({ lead, -lead, 0 }) do
		local both = sx == 0
		local rel = flat(tr.Position - b.root.Position)
		local dir = rel.Magnitude > 0.1 and rel.Unit or flat(b.root.CFrame.LookVector).Unit
		local zone = ground(b.root.Position + dir * math.clamp(rel.Magnitude, 7, F.HandReach))
		local radius, tell = F.HandRadius * (both and F.HandBoth or 1), F.HandTell * (both and 1.3 or 1)
		handTo(b, sx, "Rear", tell * tempo() * 0.8)
		local parts = mark(zone, radius, tell * tempo())
		playSound(b.root, SOUNDS.Lunge, 0.7, 0.4)
		if not hold(b, tell, tchar, 0.4) then
			unmark(parts)
			handTo(b, 0, "Loom", 0.5)
			return
		end
		local right = V3(-dir.Z, 0, dir.X)
		for _, s in ipairs(both and { -1, 1 } or { sx }) do
			handTo(b, s, zone + right * s * (both and 3.5 or 0) + V3(0, 0.6, 0), 0.12, true, 0.45)
		end
		task.wait(0.12)
		unmark(parts)
		if not live(b) then
			return
		end
		hitOnce(playersInRadius(zone, radius, 8), {}, F.HandDamage * (both and F.HandBoth or 1), zone, both and "Launch" or "Knockdown")
		shockwave(zone, radius)
		erupt(zone, radius * 0.6, both)
		playSound(b.root, SOUNDS.WatchdogSmash, 1, both and 0.4 or 0.55)
		shake(zone, both and 1.6 or 1.2)
		tremor(both and 1 or 0.5)
		local ok = hold(b, 0.4)
		handTo(b, sx, "Loom", 0.5)
		if not ok then
			return
		end
	end
	recover(b, F.HandRecover)
end

-- a piece of the Heights coming down on c, on a pool that shows where: out of the dark (made here), or one she's
-- thrown (rock, off the ring: hurl); fall seconds on its way
local function rubble(b, c, rock, fall, radius, amount)
	c = ground(c)
	local parts = mark(c, radius, fall)
	if not rock then
		rock = wreck(5, 8)
		rock.CFrame = CFrame.new(c + V3(rand(-12, 12), 120, rand(-12, 12))) * CFrame.Angles(rand(0, 6), rand(0, 6), rand(0, 6))
	end
	rock.Anchored = true
	rock.Parent = workspace
	TweenService:Create(rock, TweenInfo.new(fall, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.new(c + V3(0, 1.2, 0)) * CFrame.Angles(rand(0, 6), rand(0, 6), rand(0, 6)) }):Play()
	task.delay(fall, function()
		unmark(parts)
		if boss.gen == b.gen and boss.state == "fight" then
			hitOnce(playersInRadius(c, radius, 8), {}, amount, c, "Launch")
		end
		shockwave(c, radius)
		playSound(rock, SOUNDS.WatchdogSmash, 0.9, 0.6)
		shake(c, 0.9)
		TweenService:Create(rock, TweenInfo.new(1.2), { Transparency = 1 }):Play()
		Debris:AddItem(rock, 1.3)
	end)
end

-- (phase 3) THE HURL: a string out of her hand onto a piece of the wreck turning overhead, and it's wrenched off its
-- ring and down onto you; and another; and another. (Another piece drifts in to take each one's place.)
local function hurl(b, tchar)
	local tr = tchar:FindFirstChild("HumanoidRootPart")
	b.hum:MoveTo(b.root.Position)
	for i = 1, F.HurlCount do
		local rocks = boss.rocks
		local r = rocks and #rocks > 0 and table.remove(rocks, math.random(#rocks))
		local hand = b.model:FindFirstChild(i % 2 == 1 and "RHand" or "LHand")
		if not (r and r.part.Parent and hand) then
			break
		end
		local sx = i % 2 == 1 and 1 or -1
		bodyPose(b, sx == 1 and "OHCast" or "OHCastL", 0.2)
		handTo(b, sx, "Rear", 0.3)
		local rock = r.part
		local w = rock:FindFirstChildOfClass("WeldConstraint")
		if w then
			w:Destroy()
		end
		rock.Anchored = true
		rock.Parent = workspace
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Parent, a1.Parent = hand, rock
		local beam = Instance.new("Beam")
		beam.Attachment0, beam.Attachment1 = a0, a1
		beam.Width0, beam.Width1, beam.Segments, beam.FaceCamera = 0.12, 0.4, 1, true
		beam.Color = ColorSequence.new(PALE, VIOLET)
		beam.LightEmission, beam.Transparency = 0.7, NumberSequence.new(0.15)
		beam.Parent = rock
		Debris:AddItem(a0, F.HurlTell + F.HurlFall + 1)
		playSound(b.root, SOUNDS.Unsheath, 0.7, 1.7)
		task.delay(5, function() -- (another in its place on the ring)
			if boss.gen == b.gen and boss.state == "fight" and r.hub.Parent and boss.rocks then
				local nr = hang(r.hub, r.lcf, r.lo, r.hi)
				local tr1 = nr.part.Transparency
				nr.part.Transparency = 1
				TweenService:Create(nr.part, TweenInfo.new(1.5), { Transparency = tr1 }):Play()
				table.insert(boss.rocks, nr)
			end
		end)
		local ok = hold(b, F.HurlTell, tchar, 1.5)
		bodyPose(b, "OHYank", 0.08)
		handTo(b, sx, "Loom", 0.15, true)
		playSound(b.root, SOUNDS.Lunge, 1, 0.9)
		rubble(b, tr.Position + flat(tr.AssemblyLinearVelocity) * 0.35, rock, F.HurlFall, F.HurlRadius, F.HurlDamage) -- (off its ring: it comes down either way)
		if not ok or not hold(b, 0.25) then
			return
		end
	end
	recover(b, F.HurlRecover)
end

-- (phase 3) THE SCOUR: a great hand reached out low to one side of her, and dragged right round her front to the
-- other across the sand - everything inside its reach, as it comes to it. A line of her light along the sand shows
-- its way first
local function scour(b, tchar)
	local tr = tchar:FindFirstChild("HumanoidRootPart")
	b.hum:MoveTo(b.root.Position)
	shift(b, tchar, 10, 0)
	bodyPose(b, "OHLoom", 0.3)
	local sx = math.random() < 0.5 and 1 or -1
	local o = b.root.Position
	local aim = flat(tr.Position - o)
	aim = aim.Magnitude > 0.1 and aim.Unit or flat(b.root.CFrame.LookVector).Unit
	local th0, SPAN = math.atan2(aim.Z, aim.X), 1.75
	local function at(u, h) -- a point on its way: u its bearing off straight at you (+ = her right)
		return ground(o + V3(math.cos(th0 + u), 0, math.sin(th0 + u)) * F.ScourReach) + V3(0, h, 0)
	end
	handTo(b, sx, at(sx * SPAN, 1.2), F.ScourTell * tempo() * 0.7, false, -0.2)
	local arc = {}
	for i = 0, 7 do
		table.insert(arc, strand(at(sx * SPAN * (1 - i / 4), 0.15), at(sx * SPAN * (1 - (i + 1) / 4), 0.15), 0.3, 0.6))
	end
	playSound(b.root, SOUNDS.Lunge, 0.7, 0.4)
	if not hold(b, F.ScourTell) then
		for _, p in ipairs(arc) do
			p:Destroy()
		end
		handTo(b, 0, "Loom", 0.5)
		return
	end
	playSound(b.root, SOUNDS.WatchdogSmash, 0.9, 0.6)
	local t0, seen, prev, leg = now(), {}, sx * SPAN, 0
	while live(b) do
		local k = math.min((now() - t0) / F.ScourTime, 1)
		if leg < 4 and k * 4 >= leg then -- (the hand's sent along it in four straight legs)
			leg += 1
			handTo(b, sx, at(sx * SPAN * (1 - leg / 2), 1.2), F.ScourTime / 4, "steady", 0.3)
		end
		local u = sx * SPAN * (1 - 2 * k)
		for pl, hrp in pairs(everyone()) do
			local rel = flat(hrp.Position - o)
			local du = (math.atan2(rel.Z, rel.X) - th0 + math.pi) % (2 * math.pi) - math.pi
			if rel.Magnitude < F.ScourReach + 3 and du <= math.max(prev, u) and du >= math.min(prev, u) then
				hitOnce({ pl }, seen, F.ScourDamage, at(u + sx * 0.3, 0), "Launch") -- (thrown on the way it's going)
			end
		end
		dustCloud(at(u, 0), 2.5, 3)
		prev = u
		if k >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end
	for _, p in ipairs(arc) do
		pluck(p, 0.8)
	end
	shake(o, 1.1)
	local ok = hold(b, 0.35)
	handTo(b, sx, "Loom", 0.6)
	if ok then
		recover(b, F.ScourRecover)
	end
end

-- (phase 3) THE LOOM: she's hauled up on her strings to hang over the middle of the sand, and strings a web over the
-- whole of it off the colosseum's pillars - a spoke along the sand to every fourth one, and the lines she hangs it
-- by down to their heads. The spokes are drawn taut; then ring after ring of it is drawn in from the pillars to the
-- middle, over everything on the sand (roll through each as it reaches you); then she drops off it into the middle.
local function ringIn(b, c, k0)
	local R0 = 41
	local segs = {}
	for i = 0, 10 do
		local a1, a2 = (k0 + i * 4) / PILLARS * math.pi * 2, (k0 + i * 4 + 4) / PILLARS * math.pi * 2
		local seg = strand(c + V3(math.cos(a1), 0, math.sin(a1)) * R0, c + V3(math.cos(a2), 0, math.sin(a2)) * R0, 0.25, 0.6)
		Debris:AddItem(seg, F.LoomRingTell + F.LoomSweep + 0.2)
		table.insert(segs, seg)
	end
	task.wait(F.LoomRingTell)
	if not live(b) then
		return
	end
	playSound(b.root, SOUNDS.Lunge, 0.8, 1.3)
	for _, seg in ipairs(segs) do
		seg.Color, seg.Transparency, seg.Size = PALE, 0.05, V3(0.5, 0.5, seg.Size.Z)
		TweenService:Create(seg, TweenInfo.new(F.LoomSweep, Enum.EasingStyle.Linear), { CFrame = seg.CFrame.Rotation + c, Size = V3(0.5, 0.5, 0.05) }):Play()
	end
	local t0, was, seen = now(), {}, {}
	while live(b) do
		local r = R0 * (1 - (now() - t0) / F.LoomSweep)
		if r <= 0 then
			break
		end
		for pl, hrp in pairs(everyone()) do
			local inside = flat(hrp.Position - c).Magnitude < r
			if was[pl] and not inside then -- (it's gone over you)
				hitOnce({ pl }, seen, F.LoomDamage, c, "Large")
			end
			was[pl] = inside
		end
		RunService.Heartbeat:Wait()
	end
end
local function loom(b)
	local A = arena()
	local c = ground(A.Centre) + V3(0, 0.15, 0)
	local root = b.root
	b.hum:MoveTo(root.Position)
	bodyPose(b, "OHHang", 0.6)
	handTo(b, 0, "Sky", 0.6)
	flareStrings(true)
	playSound(root, SOUNDS.Groan, 0.9, 0.5)
	root.Anchored = true
	local from, hub, face = root.Position, V3(c.X, standY(b) + F.LoomHeight, c.Z), root.CFrame.Rotation
	local t0 = now()
	while live(b) do
		local k = math.min((now() - t0) / 1.0, 1)
		root.CFrame = CFrame.new(from:Lerp(hub, smooth(k)) + V3(0, math.sin(k * math.pi) * 5, 0)) * face
		if k >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end
	local made = {} -- (the web: all of it gone when this is over, however it ends)
	local top = Instance.new("Attachment")
	top.Position = V3(0, 2 * b.scale, 0)
	top.Parent = root
	table.insert(made, top)
	local k0 = math.random(0, 3)
	local spokes = {}
	for i = 0, 10 do
		local foot = pillar(k0 + i * 4, 0)
		foot = V3(foot.X, c.Y, foot.Z)
		local line = strand(c, foot, 0.25, 0.55)
		table.insert(made, line)
		table.insert(spokes, { line, flat(foot - c).Unit, flat(foot - c).Magnitude })
		local head = Instance.new("Attachment")
		head.Position = pillar(k0 + i * 4, 19)
		head.Parent = workspace.Terrain
		local beam = Instance.new("Beam")
		beam.Attachment0, beam.Attachment1 = top, head
		beam.Width0, beam.Width1, beam.Segments, beam.FaceCamera = 0.1, 0.35, 1, true
		beam.Color = ColorSequence.new(PALE, VIOLET)
		beam.LightEmission, beam.Transparency = 0.6, NumberSequence.new(0.3)
		beam.Parent = workspace.Terrain
		table.insert(made, head)
		table.insert(made, beam)
		burst(head.Position, VIOLET, 8, 0.3, 8)
	end
	playSound(root, SOUNDS.Unsheath, 0.9, 0.5)
	local ok = hold(b, F.LoomTell)
	if ok then -- the spokes, drawn taut
		bodyPose(b, "OHYank", 0.1)
		playSound(root, SOUNDS.Lunge, 1, 1.1)
		shake(c, 0.8)
		local seen = {}
		for _, sp in ipairs(spokes) do
			cut(c, sp[2], sp[3], F.LoomWidth, seen, F.LoomDamage, "Medium")
			sp[1].Color, sp[1].Transparency, sp[1].Size = PALE, 0, V3(F.LoomWidth, 0.4, sp[3])
			TweenService:Create(sp[1], TweenInfo.new(0.5), { Size = V3(0.25, 0.25, sp[3]), Transparency = 0.6, Color = VIOLET }):Play()
		end
		bodyPose(b, "OHHang", 0.5)
		for _ = 1, F.LoomRings do -- then the rings, in
			task.spawn(ringIn, b, c, k0)
			if not hold(b, F.LoomRingGap / tempo()) then
				break
			end
		end
		ok = hold(b, (F.LoomRingTell + F.LoomSweep - F.LoomRingGap + 0.2) / tempo())
	end
	for _, x in ipairs(made) do
		x:Destroy()
	end
	flareStrings(false)
	if not live(b) then
		return
	end
	-- and she comes down off it into the middle
	local parts = mark(c, F.LoomSlamRadius, 0.6)
	bodyPose(b, "Air", 0.2)
	handTo(b, 0, "Rear", 0.4)
	hold(b, 0.35 / tempo())
	local land = V3(c.X, standY(b), c.Z)
	t0 = now()
	while live(b) do
		local k = math.min((now() - t0) / 0.25, 1)
		root.CFrame = CFrame.new(hub:Lerp(land, k * k)) * face
		if k >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end
	unmark(parts)
	if not live(b) then
		return
	end
	bodyPose(b, "OHPlant", 0.08)
	local fwd, right = flat(face.LookVector).Unit, flat(face.RightVector).Unit
	for _, s in ipairs({ -1, 1 }) do
		handTo(b, s, c + fwd * 6 + right * s * 9 + V3(0, 0.5, 0), 0.1, true, 0.45)
	end
	hitOnce(playersInRadius(c, F.LoomSlamRadius, 8), {}, F.LoomSlamDamage, c, "Launch")
	shockwave(c, F.LoomSlamRadius)
	erupt(c, F.LoomSlamRadius * 0.6, true)
	playSound(root, SOUNDS.WatchdogSmash, 1, 0.4)
	shake(c, 1.6)
	tremor(1.2)
	root.Anchored = false
	recover(b, F.LoomRecover)
end

-- (phase 3) THE SKY PULLED DOWN, as she did to the Heights: every hand flung up, her strings drawn taut - and yanked.
-- What's left of the Heights comes down onto the sand piece by piece, every third one on you, each on a pool that
-- shows where; she doesn't wait for them
local function skyfall(b)
	b.hum:MoveTo(b.root.Position)
	bodyPose(b, "OHRear", 0.5)
	handTo(b, 0, "Sky", 0.6)
	flareStrings(true)
	playSound(b.root, SOUNDS.Groan, 0.9, 0.45)
	local ok = hold(b, F.SkyTell)
	flareStrings(false)
	if not ok then
		handTo(b, 0, "Loom", 0.5)
		return
	end
	bodyPose(b, "OHSlam", 0.12)
	handTo(b, 0, "Loom", 0.15, true) -- (the yank)
	playSound(b.root, SOUNDS.WatchdogSmash, 1, 0.3)
	shake(b.root.Position, 1.4)
	task.spawn(function()
		local A = arena()
		for i = 1, F.SkyCount do
			if not live(b) then
				return
			end
			local tchar = target(b)
			local tr = tchar and tchar:FindFirstChild("HumanoidRootPart")
			if i % 3 == 1 and tr then
				rubble(b, tr.Position + flat(tr.AssemblyLinearVelocity) * 0.5, nil, F.SkyFall, F.SkyRadius, F.SkyDamage)
			else
				local a, r = rand(0, math.pi * 2), math.sqrt(math.random()) * (A.Radius - 4)
				rubble(b, A.Centre + V3(math.cos(a) * r, 0, math.sin(a) * r), nil, F.SkyFall, F.SkyRadius, F.SkyDamage)
			end
			task.wait(F.SkyGap)
		end
	end)
	recover(b, F.SkyRecover)
end

---------------------------------------------------------------------------
-- HER THIRD PHASE'S COMING. The first time (Save "OssariaHand") a cutscene, everyone on the sand held still: she
-- reels, her hands to her face, and goes down on her knees; the sand rots black from the middle out; the hand over
-- her face lets go (unmask); the great hands tear out of her back and lift her off the sand; her strings go up into
-- the dark from every finger and she hangs there on them, and round the colosseum the wreck of the Heights comes up
-- off the ground and starts to turn (seen from high over it all); and she comes down, the great hands either side
-- of her. After that, the same in a few seconds, no camera, and a blast off her as the hands come out.
---------------------------------------------------------------------------
local function phase3(b)
	boss.phase, boss.busy = 3, true -- (busy: nothing hurts her till it's done)
	local first = not Core.Save.done("OssariaHand")
	Core.Save.mark("OssariaHand")
	local root, A = b.root, arena()
	b.hum:MoveTo(root.Position)
	root.Anchored = true
	root.AssemblyLinearVelocity = Vector3.zero
	local K = V3(root.Position.X, A.Centre.Y, root.Position.Z) -- (her feet)
	local up = V3(0, 3 * b.scale, 0)
	local tchar = target(b)
	local tr = tchar and tchar:FindFirstChild("HumanoidRootPart")
	local youP = tr and tr.Position or K + flat(root.CFrame.LookVector).Unit * 20 + V3(0, 3, 0)
	local toYou = flat(youP - K)
	toYou = toYou.Magnitude > 0.1 and toYou.Unit or V3(1, 0, 0)
	local side = V3(-toYou.Z, 0, toYou.X)
	root.CFrame = CFrame.lookAt(K + up, K + up + toYou)
	local T = first and { clutch = 1.2, kneel = 3.4, rot = 3.9, unmask = 10.6, sprout = 12.5, rise = 12.9, strings = 17.4, drop = 23.9, land = 24.4, done = 26.2 }
		or { clutch = 0.15, kneel = 0.5, rot = 0.6, unmask = 1.5, sprout = 1.7, strings = 2.5, done = 3.6 }
	local held = {}
	if first then
		local function cam(p, at) -- (a framing, its camera kept inside the colonnade)
			local rel = flat(p - A.Centre)
			if rel.Magnitude > A.Radius - 3 then
				p = V3(A.Centre.X, p.Y, A.Centre.Z) + rel.Unit * (A.Radius - 3)
			end
			return CFrame.lookAt(p, at)
		end
		local face = K + toYou * 1.5 + V3(0, 10.6, 0) -- (her face, down on her knees)
		local shots = { -- (their lengths add up to T.done)
			-- low before her as she reels, her hands going to her face: a slow push in
			{ cam(K + toYou * 14 + side * 4 + V3(0, 2.5, 0), K + V3(0, 10, 0)), cam(K + toYou * 11 + side * 3 + V3(0, 3, 0), K + V3(0, 10, 0)), 3.4 },
			-- from behind you, wide: down on her knees, and the rot coming out over the sand
			{ cam(youP + toYou * 8 + side * 5 + V3(0, 6, 0), K + V3(0, 4, 0)), cam(youP + toYou * 10 + side * 6 + V3(0, 9, 0), K + V3(0, 3, 0)), 4.4 },
			-- her face, close, from a little under it: the light through the fingers, and the hand letting go
			{ cam(K + toYou * 8 + side * 2 + V3(0, 6.5, 0), face), cam(K + toYou * 6 + side * 0.8 + V3(0, 7.2, 0), face), 4.4 },
			-- behind her, low: her back splitting, the great hands coming up out of it as she's lifted
			{ cam(K - toYou * 13 + side * 5 + V3(0, 2, 0), K + V3(0, 10, 0)), cam(K - toYou * 17 + side * 7 + V3(0, 3, 0), K + V3(0, 15, 0)), 4.2 },
			-- from high over the colosseum (not kept inside it): the wreck of the Heights coming up off the ground all
			-- round it and down out of the dark, turning; her strings going up out of the middle of it
			{ CFrame.lookAt(A.Centre + V3(105, 95, 80), A.Centre + V3(0, 18, 0)), CFrame.lookAt(A.Centre + V3(80, 110, 100), A.Centre + V3(0, 24, 0)), 3.6 },
			-- wide and low before her: hung there on her own strings, every hand spread, the wreck turning over her
			{ cam(K + toYou * 26 + side * 9 + V3(0, 1.5, 0), K + V3(0, 14, 0)), cam(K + toYou * 21 + side * 7 + V3(0, 2, 0), K + V3(0, 18, 0)), 3.6 },
			-- over your shoulder: she comes down
			{ cam(youP + toYou * 7 + side * 3 + V3(0, 3.5, 0), K + V3(0, 9, 0)), cam(youP + toYou * 5.5 + side * 2.5 + V3(0, 3, 0), K + V3(0, 10, 0)), 2.6 },
		}
		for pl, hrp in pairs(everyone()) do
			local st = states[pl]
			if st then
				held[pl] = hrp
				Core.setAction(st, now(), T.done, T.done, T.done)
				st.iStart, st.iEnd = now(), now() + T.done + 0.5
				st.healing = false
				Core.cancelSwing(st)
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.Anchored = true
				FxRemote:FireClient(pl, "Grabbed", T.done)
				FxRemote:FireClient(pl, "Cutscene", shots)
			end
		end
		ReplicatedStorage:SetAttribute("MusicIntro", T.done) -- (the intro is timed to end with the cutscene)
		ReplicatedStorage:SetAttribute("Music", "championintro2")
	else
		ReplicatedStorage:SetAttribute("Music", "champion2")
	end
	say(O.Name, first and O.Phase3[1] or O.Again3)
	bodyPose(b, "Stagger", 0.15)
	playSound(root, SOUNDS.Impact, 0.9, 0.45)

	local t0 = now()
	local function at(t)
		task.wait(math.max(t - (now() - t0), 0))
		return boss.gen == b.gen and b.hum.Health > 0
	end
	local function later(t, fn) -- (a beat on the side, t into it, while the main line of it waits)
		task.delay(math.max(t - (now() - t0), 0), function()
			if boss.gen == b.gen and b.hum.Health > 0 then
				fn()
			end
		end)
	end
	-- her height off the sand (the cutscene lifts her on the great hands, and drops her): eased by this, every frame
	local lift = { from = 0, to = 0, t0 = 0, dur = 1, h = 0, snap = false }
	local function liftTo(h, dur, snap)
		lift.from, lift.to, lift.t0, lift.dur, lift.snap = lift.h, h, now(), dur, snap
	end
	local riding = true
	task.spawn(function()
		while riding and boss.gen == b.gen do
			local k = math.clamp((now() - lift.t0) / lift.dur, 0, 1)
			lift.h = lift.from + (lift.to - lift.from) * (lift.snap and k * k or smooth(k))
			local p = K + up + V3(0, lift.h + math.sin(now() * 1.1) * 0.3 * math.min(lift.h / 3, 1), 0)
			root.CFrame = CFrame.lookAt(p, p + toYou)
			RunService.Heartbeat:Wait()
		end
	end)

	local ok = at(T.clutch)
	if ok then -- her hands to her face
		bodyPose(b, "OHClutch", first and 0.9 or 0.3)
		playSound(root, SOUNDS.Groan, 0.8, 0.5)
		ok = at(T.kneel)
	end
	if ok then -- down on her knees
		bodyPose(b, "OHKneel", first and 1.4 or 0.4)
		ok = at(T.rot)
	end
	if ok then -- and the sand rots: veins of her light out from under her, and black from the middle to the colonnade
		spreadRot(first and 5.5 or 2)
		Core.fadeAway(Core.crackLines(K + V3(0, 0.2, 0), 18, 9, VIOLET, MAT.Neon, first and 2.5 or 0.8), 9, 2)
		playSound(root, SOUNDS.WatchdogSmash, 0.7, 0.3)
		shake(K, 0.7)
		if first then
			later(5.6, function()
				playSound(root, SOUNDS.Impact, 0.8, 0.25)
				shake(K, 0.5)
			end)
			later(8.2, function() -- (still up as the great hands come out)
				say(O.Name, O.Phase3[2])
			end)
			later(T.unmask - 1.6, function() -- her lights, through the fingers: burning
				for _, g in ipairs(b.model:GetChildren()) do
					if g.Name == "Glint" then
						TweenService:Create(g, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = g.Size * 2.6 }):Play()
					end
				end
				playSound(root, SOUNDS.Unsheath, 0.7, 0.3)
			end)
		end
		ok = at(T.unmask)
	end
	if ok then -- the hand over her face lets go of it
		for pl in pairs(held) do
			FxRemote:FireClient(pl, "Flash", Color3.new(0, 0, 0), 0.5, 0.1)
		end
		unmask(b)
		bodyPose(b, "OHBare", 0.2)
		playSound(root, SOUNDS.WatchdogSmash, 0.9, 0.7)
		playSound(root, SOUNDS.Groan, 1, 0.6)
		shake(K, 1.1)
		ok = at(T.sprout)
	end
	if ok then -- and out of her back, two more
		growHands(b)
		handTo(b, 0, "Loom", first and 1.6 or 0.7)
		local back = K + V3(0, 9, 0) - toYou * 1.5
		burst(back, C3(20, 12, 26), 60, 0.9, 30)
		burst(back, BONE, 24, 0.5, 22)
		dustCloud(K - toYou * 2, 6, 20)
		playSound(root, SOUNDS.WatchdogSmash, 1, 0.4)
		playSound(root, SOUNDS.Lunge, 1, 0.4)
		shake(K, 1.4)
		if not first then -- (nobody's held: a blast off her as they come out)
			hitOnce(playersInRadius(K, 13, 12), {}, F.SlamDamage * 0.6, K, "Knockdown")
			shockwave(K, 12)
			bodyPose(b, "OHUnfurl", 0.3)
		end
		raiseWreck(b, first and 7 or 3.5) -- and round the colosseum, the wreck of the Heights starts up off the ground
		if T.rise then
			ok = at(T.rise)
		end
	end
	if ok and T.rise then -- lifted off the sand on them
		later(T.rise + 1.2, function() -- (the ground, as the heaps come up off it)
			playSound(root, SOUNDS.WatchdogSmash, 0.8, 0.25)
			shake(K, 0.9)
		end)
		liftTo(5.5, 2.8)
		bodyPose(b, "OHUnfurl", 1.2)
		later(T.rise + 1.6, function()
			bodyPose(b, "OHHang", 1.4)
		end)
		later(T.strings + 2.6, function() -- (as the camera comes back down to her)
			say(O.Name, O.Phase3[3])
		end)
	end
	if ok then
		ok = at(T.strings)
	end
	if ok then -- her strings, up into the dark from every finger: hung there on them. Her name
		handTo(b, 0, "Sky", first and 0.7 or 0.4)
		stringUp()
		for pl in pairs(held) do
			FxRemote:FireClient(pl, "Flash", PALE, 1.2, 0.05)
		end
		playSound(root, SOUNDS.Groan, 1, 0.4)
		playSound(root, SOUNDS.Impact, 1, 0.3)
		shake(K, 1.7)
		ReplicatedStorage:SetAttribute("BossName", O.Name3)
		boss.bar3 = true -- (her second bar, full, under her new name)
		b.hum.Health = O.HP3
		ReplicatedStorage:SetAttribute("BossMaxHP", O.HP3)
		ReplicatedStorage:SetAttribute("BossHP", O.HP3)
		local smoke = Instance.new("ParticleEmitter") -- the dark coming off her again, as it did off her shrouds
		smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
		smoke.Color = ColorSequence.new(C3(10, 8, 14), C3(30, 18, 40))
		smoke.LightEmission, smoke.LightInfluence = 0, 0
		smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 5) })
		smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.7), NumberSequenceKeypoint.new(1, 1) })
		smoke.Lifetime, smoke.Speed, smoke.Rate = NumberRange.new(1.5, 2.5), NumberRange.new(1, 3), 14
		smoke.Rotation, smoke.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-40, 40)
		smoke.Acceleration = V3(0, 2, 0)
		smoke.Parent = b.model:FindFirstChild("Chest") or root
		if T.drop then
			ok = at(T.drop)
		end
	end
	if ok and T.drop then -- and down
		bodyPose(b, "Air", 0.2)
		handTo(b, 0, "Rear", 0.45)
		liftTo(0, T.land - T.drop, true)
		playSound(root, SOUNDS.Lunge, 1, 0.45)
		ok = at(T.land)
	end
	if ok and T.land then -- onto the sand, a great hand planted either side of her
		bodyPose(b, "OHPlant", 0.08)
		for _, s in ipairs({ -1, 1 }) do
			handTo(b, s, K + toYou * 7 + side * s * 9 + V3(0, 0.5, 0), 0.12, true, 0.45)
		end
		shockwave(K, 16)
		erupt(K + toYou * 7, 8, true)
		playSound(root, SOUNDS.WatchdogSmash, 1, 0.4)
		playSound(root, SOUNDS.Impact, 1, 0.5)
		shake(K, 1.6)
		later(T.land + 0.9, function()
			bodyPose(b, "OHLoom", 1.0)
			handTo(b, 0, "Loom", 0.9)
		end)
	end
	if ok then
		at(T.done)
	end
	riding = false
	for pl, hrp in pairs(held) do
		if hrp.Parent then
			hrp.Anchored = false
			pcall(function()
				hrp:SetNetworkOwner(pl)
			end)
		end
	end
	if boss.gen == b.gen and boss.state == "fight" then
		ReplicatedStorage:SetAttribute("Music", "champion2")
		root.CFrame = CFrame.lookAt(K + up, K + up + toYou)
		root.Anchored = false
		pcall(function()
			root:SetNetworkOwner(nil)
		end)
		idle(b)
	end
	boss.busy = false
end

---------------------------------------------------------------------------
-- her mind; the fight's start, and its end either way
---------------------------------------------------------------------------
local MOVES = {
	{ name = "Rake", fn = rake, min = 0, max = 17, w = 4, cd = 1.5 },
	{ name = "Wheel", fn = wheel, min = 0, max = 11, w = 3, cd = 7 },
	{ name = "Frenzy", fn = frenzy, min = 0, max = 30, w = 4, cd = 9 },
	{ name = "Hound", fn = hound, min = 12, max = 90, w = 3, cd = 8 },
	{ name = "Dirge", fn = dirge, min = 0, max = 20, w = 2.5, cd = 7 },
	{ name = "Pounce", fn = pounce, min = 15, max = 90, w = 3, cd = 5 },
	{ name = "Skitter", fn = skitter, min = 13, max = 90, w = 3, cd = 8 },
	{ name = "Threads", fn = threads, min = 12, max = 90, w = 3, cd = 6 },
	{ name = "Cradle", fn = cradle, min = 0, max = 90, w = 2.5, cd = 11 },
	{ name = "Pull", fn = pull, min = 16, max = 90, w = 2, cd = 9 },
	{ name = "Wells", fn = wells, min = 0, max = 90, w = 2, cd = 11 },
	{ name = "Hands", fn = greatHands, min = 0, max = 19, w = 5, cd = 4, p3 = true },
	{ name = "Scour", fn = scour, min = 0, max = 18, w = 3, cd = 7, p3 = true },
	{ name = "Hurl", fn = hurl, min = 12, max = 90, w = 3, cd = 9, p3 = true, ready = function()
		return boss.rocks ~= nil and #boss.rocks >= F.HurlCount
	end },
	{ name = "Skyfall", fn = skyfall, min = 0, max = 90, w = 2, cd = 18, p3 = true },
	{ name = "Loom", fn = loom, min = 0, max = 90, w = 2, cd = 26, p3 = true },
}
local function pickMove(dist)
	local list, again, total = {}, nil, 0
	for _, mv in ipairs(MOVES) do
		if dist >= mv.min and dist <= mv.max and now() >= (boss.cd[mv.name] or 0) and (boss.phase == 3 or not mv.p3) and (not mv.ready or mv.ready()) and not mv.lab then -- (lab: a candidate, fired only from the attack lab)
			if boss.lastMove == mv.name then
				again = mv -- (never twice running, unless it's all she has)
			else
				table.insert(list, mv)
				total += mv.w
			end
		end
	end
	local r = math.random() * total
	for _, mv in ipairs(list) do
		r -= mv.w
		if r <= 0 then
			return mv
		end
	end
	return again
end

local reset
local function brain(b)
	boss.cd, boss.circleSide, boss.circleUntil = {}, 1, 0
	local alone -- (since when there's been nobody on the sand)
	while live(b) do
		task.wait(0.08)
		if not free(b) or b.root.Anchored then
			continue
		end
		local tchar = target(b)
		local tr = tchar and tchar:FindFirstChild("HumanoidRootPart")
		if not tr then
			b.hum:MoveTo(b.root.Position)
			if not alone then
				alone = now()
				ReplicatedStorage:SetAttribute("Music", "none") -- (it cuts the moment you die)
			end
			if now() - alone > 4 then -- everyone's dead: she goes back under her shrouds (hooks.onReset)
				reset()
				return
			end
			continue
		end
		alone = nil
		if boss.phase == 2 and b.hum.Health <= O.HP3 then -- (her first bar's empty)
			boss.attacking = true
			local ok, err = pcall(phase3, b)
			if ok and live(b) then
				ok, err = pcall(skyfall, b) -- (her first act with them: the sky)
			end
			if not ok then
				warn("[DGUS] Ossaria's third phase: " .. tostring(err))
				boss.busy = false
				if live(b) then
					b.root.Anchored = false
				end
			end
			boss.attacking = false
			continue
		end
		local rel = flat(tr.Position - b.root.Position)
		local dist = rel.Magnitude
		local walk = boss.phase == 3 and F.WalkSpeed3 or F.WalkSpeed
		turnTowards(b.root, tr.Position, math.rad(240) * 0.08)
		local mv
		if boss.forced then -- (the attack lab, M.lab: this move, now - and again and again, if it's set to loop)
			for _, m in ipairs(MOVES) do
				if m.name == boss.forced and (boss.phase == 3 or not m.p3) then
					mv = m
				end
			end
			if not boss.loop or not mv then
				boss.forced = nil
			end
			if not mv then
				continue
			end
		elseif boss.passive then -- (the lab: she stands, her face on you, and waits to be told)
			b.hum:MoveTo(b.root.Position)
			continue
		elseif now() < boss.circleUntil and dist > 0.5 then -- between moves: stalking round you, never quite still
			if now() >= (boss.fidgetAt or 0) then
				boss.fidgetAt = now() + rand(1.2, 2.6)
				local list = boss.phase == 3 and { "OHLoom", "OHLoomTilt" } or { "OHIdle", "OHTilt", "OHCrane" }
				bodyPose(b, list[math.random(#list)], 0.5)
			end
			b.hum.WalkSpeed = walk * 0.7
			b.hum:MoveTo(clampToArena(b, tr.Position + CFrame.Angles(0, boss.circleSide * 0.6, 0):VectorToWorldSpace(-rel.Unit) * math.clamp(dist, 10, 18)))
			continue
		end
		mv = mv or pickMove(dist)
		if mv then
			boss.attacking, boss.lastMove = true, mv.name
			boss.cd[mv.name] = now() + mv.cd * tempo()
			flare(b) -- (whatever it is: it's starting)
			local ok, err = pcall(mv.fn, b, tchar)
			if not ok then
				warn("[DGUS] Ossaria move " .. mv.name .. " error: " .. tostring(err))
				if live(b) then
					b.root.Anchored = false
				end
			end
			boss.attacking = false
			b.hum.WalkSpeed = walk
			boss.circleSide = math.random() < 0.5 and -1 or 1
			boss.circleUntil = now() + (boss.phase == 2 and rand(F.Lull2[1], F.Lull2[2]) or rand(0.4, 1.0) * tempo()) -- (phase 2: hardly a breath between)
		else
			b.hum.WalkSpeed = walk
			b.hum:MoveTo(clampToArena(b, tr.Position))
		end
	end
end

-- pinned to the sand's height and kept inside the colonnade whenever she's on her own feet
local function confine(b)
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if boss.gen ~= b.gen or boss.state ~= "fight" or not b.root.Parent then
			conn:Disconnect()
			return
		end
		if b.root.Anchored then
			return -- (a leap, or her third phase's coming, carries her itself)
		end
		local p = b.root.Position
		local q = clampToArena(b, p)
		if (q - p).Magnitude > 0.05 then
			b.root.CFrame = CFrame.new(q) * b.root.CFrame.Rotation
			local v = b.root.AssemblyLinearVelocity
			b.root.AssemblyLinearVelocity = V3(v.X, 0, v.Z)
		end
	end)
end

-- HER WEIGHT: every Stride she covers on her own feet, a footfall - dust off the sand, a low thud, the ground under you
local function strides(b)
	local last, covered = b.root.Position, 0
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if boss.gen ~= b.gen or boss.state ~= "fight" or not b.root.Parent then
			conn:Disconnect()
			return
		end
		local p = b.root.Position
		if not b.root.Anchored then
			covered += flat(p - last).Magnitude
		end
		last = p
		if covered > F.Stride then
			covered = 0
			dustCloud(ground(p), 1.4, 3)
			playSound(b.root, SOUNDS.Impact, 0.22, 0.4)
			shake(ground(p), boss.phase == 3 and 0.22 or 0.16)
		end
	end)
end

-- everyone on the sand died: she's gone from it, and so is everything of hers (Ossaria.luau puts her back, shrouded)
reset = function()
	if boss.state ~= "fight" then
		return
	end
	boss.gen += 1
	boss.state = "none"
	if boss.model then
		boss.model:Destroy()
	end
	clearFx()
	ReplicatedStorage:SetAttribute("BossActive", false)
	ReplicatedStorage:SetAttribute("Music", "none")
	ReplicatedStorage:SetAttribute("MusicSteady", nil)
	champion().seal(false)
	if boss.hooks and boss.hooks.onReset then
		boss.hooks.onReset()
	end
end

-- BEATEN: her strings let go of her, the black goes out of the sand, and she comes apart where she stands, from the
-- head down, as her husk did
local function onDied(b)
	if boss.gen ~= b.gen or boss.state ~= "fight" then
		return
	end
	boss.state = "dead"
	Core.Save.mark("Ossaria")
	ReplicatedStorage:SetAttribute("BossActive", false)
	ReplicatedStorage:SetAttribute("Music", "victory")
	ReplicatedStorage:SetAttribute("MusicSteady", nil)
	FxRemote:FireAllClients("Banner", "HEIR FELLED", "Victory")
	say(boss.phase == 3 and O.Name3 or O.Name, O.Dying)
	champion().seal(false)
	local at = b.root.Position
	for _, x in ipairs(boss.fx) do -- (her strings go slack and fade; the rot goes out of the sand)
		if x:IsA("Beam") then
			x.Color = ColorSequence.new(PALE)
			TweenService:Create(x, TweenInfo.new(1.2), { Width0 = 0, Width1 = 0 }):Play()
		elseif x.Name == "WreckHub" then -- (and the wreck she had turning comes down, all of it at once)
			for _, rock in ipairs(x:GetChildren()) do
				if rock:IsA("BasePart") then
					local w = rock:FindFirstChildOfClass("WeldConstraint")
					if w then
						w:Destroy()
					end
					rock.AssemblyLinearVelocity = V3(rand(-8, 8), rand(-10, 0), rand(-8, 8))
				end
			end
		elseif x:IsA("BasePart") then
			TweenService:Create(x, TweenInfo.new(5), { Transparency = 1 }):Play()
		end
		Debris:AddItem(x, 5.2)
	end
	boss.fx, boss.hands, boss.strings, boss.rocks = {}, nil, nil, nil
	local pieces = {}
	for _, p in ipairs(b.model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			table.insert(pieces, p)
		elseif p:IsA("ParticleEmitter") then
			p.Enabled = false
		end
	end
	table.sort(pieces, function(p, q)
		return p.Position.Y > q.Position.Y
	end)
	for i, p in ipairs(pieces) do
		task.delay(1.2 + 3.2 * i / #pieces, function()
			if i % 8 == 0 then
				burst(p.Position, C3(40, 18, 56), 6, 0.5, 4)
			end
			TweenService:Create(p, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1, Size = p.Size * 0.3, CFrame = p.CFrame - V3(0, 2, 0) }):Play()
		end)
	end
	playSound(b.root, SOUNDS.Groan, 1, 0.4)
	shake(at, 1)
	task.delay(2.4, function()
		dustCloud(ground(at), 7, 26)
	end)
	Debris:AddItem(b.model, 5.6)
	Core.dropSplinter(at, b.model)
	if boss.hooks and boss.hooks.onDied then
		task.spawn(boss.hooks.onDied, at)
	end
end

function M.init(core)
	Core = core
	PM = require(ReplicatedStorage:WaitForChild("PuppetMath")) -- (not at the top: PuppetMath's Roster loads this file)
	Map, FxRemote, states, now, flat, rand, turnTowards, SOUNDS, playSound, burst, dustCloud, shockwave, bodyPose, aliveChar, damagePlayer, playersInRadius, playersInSector = core.Map, core.FxRemote, core.states, core.now, core.flat, core.rand, core.turnTowards, core.SOUNDS, core.playSound, core.burst, core.dustCloud, core.shockwave, core.bodyPose, core.aliveChar, core.damagePlayer, core.playersInRadius, core.playersInSector
	-- HER CANDIDATE MOVES (GameServer/OssariaMoves: the attack lab's): handed everything a move of hers is made of,
	-- and added to her moves marked lab - fired only from the lab (M.lab, below) till one's promoted there
	local kit = {
		boss = boss, F = F, O = O, Core = core, MOVES = MOVES, PILLARS = PILLARS, VIOLET = VIOLET, PALE = PALE, ROT = ROT,
		now = now, flat = flat, rand = rand, smooth = smooth, turnTowards = turnTowards, SOUNDS = SOUNDS, playSound = playSound, burst = burst, dustCloud = dustCloud,
		shockwave = shockwave, bodyPose = bodyPose, damagePlayer = damagePlayer, playersInRadius = playersInRadius, playersInSector = playersInSector,
		arena = arena, live = live, free = free, tempo = tempo, ground = ground, standY = standY, clampToArena = clampToArena, everyone = everyone, target = target,
		hitOnce = hitOnce, shake = shake, hold = hold, mark = mark, unmark = unmark, erupt = erupt, pillar = pillar, strand = strand, triple = triple, pluck = pluck, cut = cut,
		wreck = wreck, handTo = handTo, flareStrings = flareStrings, idle = idle, recover = recover, flight = flight, leap = leap, plant = plant, slam = slam, flare = flare,
		fan = fan, shift = shift, either = either, cut1 = cut1, tremor = tremor, rubble = rubble,
	}
	local okMoves, extra = pcall(function()
		return require(game:GetService("ServerScriptService"):WaitForChild("GameServer"):WaitForChild("OssariaMoves"))(kit)
	end)
	if okMoves then
		for _, mv in ipairs(extra) do
			table.insert(MOVES, mv)
		end
	else
		warn("[DGUS] Ossaria's candidate moves: " .. tostring(extra))
	end
	local names = {} -- (for the lab's panel: name|phase it's from|pool or lab|a line on it)
	for _, mv in ipairs(MOVES) do
		table.insert(names, mv.name .. "|" .. (mv.p3 and 3 or 2) .. "|" .. (mv.lab and "lab" or "pool") .. "|" .. (mv.note or ""))
	end
	ReplicatedStorage:SetAttribute("OssLab", table.concat(names, ";"))
	core.registerTarget(function(model)
		if boss.state ~= "fight" or boss.model ~= model then
			return nil
		end
		return {
			owner = boss,
			actor = boss.current,
			maxPoise = F.Poise,
			freeze = false,
			armor = boss.attacking, -- mid-move she shrugs off half of every poise hit
			evade = function() -- (her third phase's coming: nothing touches her)
				return boss.busy
			end,
			onBreak = function(_, t)
				if boss.state ~= "fight" or boss.busy or boss.root.Anchored then
					return -- (no knocking her out of the air)
				end
				local actor = boss.current
				boss.staggerUntil = t + F.Stagger
				bodyPose(actor, "Stagger", 0.12)
				handTo(actor, 0, "Loom", 0.4)
				boss.hum:MoveTo(boss.root.Position)
				playSound(boss.root, SOUNDS.Impact, 0.9, 0.55)
				shake(boss.root.Position, 0.5)
				local gen = boss.gen
				task.delay(F.Stagger, function()
					if boss.gen == gen and boss.state == "fight" and not boss.busy then
						idle(actor)
					end
				end)
			end,
		}
	end)
end

-- (Ossaria.luau, at her reveal's end) the fight: h = { model, root, scale }, her true body standing on the sand
-- (anchored, an NPC till now: never hittable). The seal, her bar, her moves.
M.begin = function(h, hooks)
	local model, root = h.model, h.root
	local hum = model:FindFirstChildOfClass("Humanoid")
	boss.gen += 1
	clearFx()
	hum.MaxHealth = O.HP + O.HP3 -- (both her bars: the bar shows what's left of the one she's on)
	hum.Health = O.HP + O.HP3
	hum.WalkSpeed, hum.BreakJointsOnDeath, hum.AutoRotate = F.WalkSpeed, false, false
	model:SetAttribute("Radius", 3)
	model:SetAttribute("Boss", true)
	root.CollisionGroup = "EnemyRoot"
	model.Parent = Core.EnemiesFolder
	hum.HipHeight = model:GetAttribute("HipHeight")
	local b = { model = model, hum = hum, root = root, scale = h.scale, gen = boss.gen }
	boss.current, boss.model, boss.hum, boss.root, boss.hooks = b, model, hum, root, hooks
	boss.phase, boss.busy, boss.staggerUntil, boss.poise, boss.lastMove, boss.attacking, boss.bar3 = 2, false, 0, nil, nil, false, false
	boss.passive, boss.forced, boss.loop = false, nil, false
	boss.state = "fight"
	hum.HealthChanged:Connect(function(hp)
		if boss.gen == b.gen and boss.state == "fight" then
			ReplicatedStorage:SetAttribute("BossHP", math.max(0, boss.bar3 and hp or hp - O.HP3))
		end
	end)
	hum.Died:Connect(function()
		onDied(b)
	end)
	champion().seal(true)
	ReplicatedStorage:SetAttribute("BossName", O.Name)
	ReplicatedStorage:SetAttribute("BossMaxHP", O.HP)
	ReplicatedStorage:SetAttribute("BossHP", O.HP)
	ReplicatedStorage:SetAttribute("BossActive", true)
	ReplicatedStorage:SetAttribute("MusicSteady", true) -- (Music.client: no dying away toward half a bar, as for the Silver Knight's second wind)
	ReplicatedStorage:SetAttribute("Music", "champion")
	root.Anchored = false
	pcall(function()
		root:SetNetworkOwner(nil)
		hum:ChangeState(Enum.HumanoidStateType.Running)
	end)
	idle(b)
	confine(b)
	strides(b)
	lace()
	haze(10)
	task.spawn(brain, b)
end
-- (Champion.luau: her husk's holes of decay are these same pools)
M.pool, M.unpool, M.erupt = mark, unmark, erupt
M.state = function()
	return boss.state
end
-- (Ossaria.luau's dev menu) her third phase's coming is playing; her fight called off, as if you'd died; dead, now
M.busy = function()
	return boss.busy == true
end
-- THE ATTACK LAB (Ossaria.luau's dev menu): she waits and does nothing of her own (passive), and is told one move at a
-- time (fire: by its name in MOVES, a candidate or one of her own; loop: over and over till stop)
M.lab = {
	passive = function(on)
		boss.passive = on == true
	end,
	fire = function(name, loop)
		boss.forced, boss.loop = name, loop == true
	end,
	stop = function()
		boss.forced, boss.loop = nil, false
	end,
}
M.reset = function()
	reset()
end
M.devKill = function()
	if boss.state == "fight" and boss.hum.Health > 0 then
		boss.busy = false
		boss.hum.Health = 0
	end
end
M.devWound = function() -- (for testing) a hit from her third phase; in it, from death
	if boss.state == "fight" and boss.hum.Health > 0 then
		boss.hum.Health = boss.phase == 2 and O.HP3 or 1
	end
end

return M
