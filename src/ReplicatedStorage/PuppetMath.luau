--!nonstrict
-- PuppetMath: the shared skeleton and the procedural animation solver.
--
-- Every character in the game (you, the hollows, the Jailer, the Warden) is a
-- Motor6D rig built from PuppetMath.dims/joints. The client animates all of
-- them every frame with PuppetMath.solve:
--   * body poses (windups, leans, kneels...) blended from server attributes
--   * a walk cycle driven by actual velocity
--   * two-bone IK so hands stay on the weapon grip and feet stay on the floor
--
-- Joint convention: Part1.CFrame = Part0.CFrame * C0 * C1:Inverse().
-- Limbs hang along their part's -Y axis from a joint at the top of the part.
local PM = {}

---------------------------------------------------------------------------
-- skeleton
---------------------------------------------------------------------------
-- body proportions per character kind come from each character file (M.Proportions)
local Roster = require((script.Parent :: any):WaitForChild("Roster"))
PM.KINDS = Roster.kinds

function PM.dims(kind, s)
	local k = PM.KINDS[kind] or PM.KINDS.Knight
	local g, a = k.girth, k.arm
	local leg = k.leg or 1 -- (an optional length multiplier for the legs: the hips and all above them are lifted by what it adds; the root stays where it is)
	local up = (leg - 1) * 2.3 * s
	return {
		kind = kind,
		s = s,
		hunch = k.hunch,
		twoHand = k.twoHand and k.twoHand * s or nil,
		elbowOut = k.elbowOut, -- (elbows carried wide of the body: 0 as everyone else, ~1 well out)
		walkRef = k.walkRef, -- (the speed, in its own body-lengths, it's fully walking at: 11 if not given)
		cadence = k.cadence, -- (how fast its steps come for its speed: 0.55 if not given - higher, shorter quicker steps)
		turnBend = k.turnBend, -- (bends into its turns: the Puppeteer sets ctx.bend from it)
		limbs = k.limbs, -- (extra joints: wrists and toes, see PM.joints)
		rootY = 3 * s, -- root part centre above the floor when standing
		rootSize = Vector3.new(2, 2, 1) * s,
		hipHeight = 2 * s,
		hipsY = 2.75 * s + up,
		hipsSize = Vector3.new(1.8 * g, 0.8, 0.95 * g) * s,
		waistY = 3.1 * s + up,
		chestH = 1.7 * (k.torso or 1) * s, -- (torso: an optional length multiplier, e.g. the dog's long body)
		chestSize = Vector3.new(2.0 * g, 1.7 * (k.torso or 1), 1.0 * g) * s,
		headSize = Vector3.new(1.15, 1.25, 1.15) * s,
		shoulderX = (1.0 * g + 0.3) * s,
		shoulderDown = 0.25 * s,
		upperArm = 1.15 * a * s,
		lowerArm = 1.2 * a * s,
		armW = 0.55 * g * s,
		hipX = 0.5 * g * s,
		hipJointY = 2.6 * s + up,
		thigh = 1.2 * leg * s,
		shin = 1.1 * leg * s,
		legW = 0.62 * g * s,
		ankleY = 0.3 * s,
		footSize = Vector3.new(0.62 * g, 0.3, 1.05) * s,
		handSize = Vector3.new(0.52 * g, 0.42, 0.55 * g) * s, -- (limbs rigs: the fist on its wrist)
		toeSize = Vector3.new(0.62 * g, 0.2, 0.42) * s, -- (limbs rigs: the front of the foot on its toe joint)
	}
end

-- joint name -> { p0, p1, C0 (rest), C1 }
function PM.joints(D)
	local J = {}
	J.Root = { p0 = "HumanoidRootPart", p1 = "Hips", C0 = CFrame.new(0, D.hipsY - D.rootY, 0), C1 = CFrame.new() }
	J.Waist = { p0 = "Hips", p1 = "Chest", C0 = CFrame.new(0, D.waistY - D.hipsY, 0), C1 = CFrame.new(0, -D.chestH / 2, 0) }
	J.Neck = { p0 = "Chest", p1 = "Head", C0 = CFrame.new(0, D.chestH / 2, 0), C1 = CFrame.new(0, -D.headSize.Y / 2, 0) }
	for _, side in ipairs({ { "R", 1 }, { "L", -1 } }) do
		local n, sx = side[1], side[2]
		J[n .. "Shoulder"] = { p0 = "Chest", p1 = n .. "UpperArm", C0 = CFrame.new(sx * D.shoulderX, D.chestH / 2 - D.shoulderDown, 0), C1 = CFrame.new(0, D.upperArm / 2, 0) }
		J[n .. "Elbow"] = { p0 = n .. "UpperArm", p1 = n .. "LowerArm", C0 = CFrame.new(0, -D.upperArm / 2, 0), C1 = CFrame.new(0, D.lowerArm / 2, 0) }
		J[n .. "Hip"] = { p0 = "Hips", p1 = n .. "Thigh", C0 = CFrame.new(sx * D.hipX, D.hipJointY - D.hipsY, 0), C1 = CFrame.new(0, D.thigh / 2, 0) }
		J[n .. "Knee"] = { p0 = n .. "Thigh", p1 = n .. "Shin", C0 = CFrame.new(0, -D.thigh / 2, 0), C1 = CFrame.new(0, D.shin / 2, 0) }
		J[n .. "Ankle"] = { p0 = n .. "Shin", p1 = n .. "Foot", C0 = CFrame.new(0, -D.shin / 2, 0), C1 = CFrame.new(0, D.footSize.Y / 2, D.footSize.Z * 0.22) }
		if D.limbs then
			J[n .. "Wrist"] = { p0 = n .. "LowerArm", p1 = n .. "Hand", C0 = CFrame.new(0, -D.lowerArm / 2, 0), C1 = CFrame.new(0, 0.08 * D.s, 0) }
			J[n .. "Toe"] = { p0 = n .. "Foot", p1 = n .. "Toe", C0 = CFrame.new(0, -D.footSize.Y / 2, -D.footSize.Z * 0.3), C1 = CFrame.new(0, -D.toeSize.Y / 2, D.toeSize.Z / 2) }
		end
	end
	return J
end

---------------------------------------------------------------------------
-- body poses (blended on the client; the server only names them)
--   drop  : how far the hips sink (studs at scale 1) - legs bend to match
--   lean  : torso pitch, + = forward      twist: chest yaw, + = to the left
--   hip   : hips yaw over planted feet, + = to the left (a whole-body coil; the head holds on)
--   look  : head yaw on the neck, + = to the left (peering over a shoulder)
--   liftL : left-foot lift (a step), like lift for the right
--   side  : lateral tilt                   head : + = look down
--   la*/ra*: free-arm angles (shoulder X/Y/Z, elbow) when not holding a grip
--   freeL : how much the left arm swings while walking
--   footR/footL: stance, studs forward(+)/back(-)    lift: right-foot lift (stomp)
--   tuck  : knees to chest (0..1)          breathe: breathing amplitude
--   cross : sitting cross-legged (0..1): feet tucked under the opposite knee, knees out
--   lwr/rwr: wrist bend, + = knuckles forward   toe: heels up onto the toes (radians)
--            (lwr/rwr/toe only move rigs with D.limbs)
---------------------------------------------------------------------------
local BASE = {
	drop = 0.05, lean = 0.06, twist = 0, side = 0, head = 0.05,
	la1 = 0.1, la2 = 0, la3 = -0.12, lel = 0.35, freeL = 1,
	ra1 = 0.1, ra2 = 0, ra3 = 0.12, rel = 0.35,
	footR = 0.15, footL = -0.15, spread = 0, lift = 0, tuck = 0, cross = 0, breathe = 1,
	lwr = 0, rwr = 0, toe = 0, hip = 0, look = 0, liftL = 0,
}
PM.BASE = BASE

-- shared body poses; each character file adds its own (M.Poses)
PM.POSES = {
	Idle = {},
	Windup = { drop = 0.2, lean = -0.28, twist = 0.3, head = -0.12, footR = -0.35, footL = 0.45, la1 = 0.5, la3 = -0.5, lel = 0.6, freeL = 0 },
	Strike = { drop = 0.6, lean = 0.55, twist = -0.2, head = 0.2, footR = 0.75, footL = -0.6, la1 = -0.3, la3 = -0.3, lel = 0.3, freeL = 0 },
	SweepWindup = { drop = 0.4, lean = 0.18, twist = -0.95, footR = -0.3, footL = 0.45, la1 = 0.6, la3 = -0.9, lel = 0.5, freeL = 0, rwr = -0.6, lwr = -0.5, toe = 0.5 },
	SweepEnd = { drop = 0.35, lean = 0.28, twist = 0.95, footR = 0.55, footL = -0.35, la1 = -0.4, la3 = -0.6, lel = 0.3, freeL = 0, rwr = 0.5, lwr = 0.4, toe = 0.35 },
	Recover = { drop = 0.55, lean = 0.65, head = 0.15, footR = 0.6, footL = -0.5, breathe = 4, la1 = 0.2, lel = 0.8, freeL = 0, rwr = 0.3, lwr = 0.5, toe = 0.25 },
	Flinch = { drop = 0.2, lean = -0.32, twist = 0.2, head = -0.35, freeL = 0, la1 = 0.4, la3 = -0.6 },
	Stagger = { drop = 0.45, lean = -0.5, twist = -0.35, side = 0.15, head = -0.45, footR = -0.55, footL = 0.45, la1 = 0.9, la3 = -1.2, lel = 0.4, freeL = 0 },
	Crouch = { drop = 1.1, lean = 0.5, head = -0.15, footR = 0.45, footL = -0.45, la1 = 0.3, la3 = -0.5, freeL = 0 },
	Kneel = { drop = 1.45, lean = 0.38, head = 0.3, footR = 1.0, footL = -1.3, la1 = 0.9, la3 = -0.15, lel = 0.15, freeL = 0, lwr = 0.4, toe = 0.7 },
	Roar = { drop = 0.1, lean = -0.55, head = -0.65, la1 = 2.4, la3 = -0.9, lel = 0.5, footR = 0.4, footL = -0.4, freeL = 0, rwr = -0.4, lwr = -0.8 },
	Air = { drop = 0.2, lean = 0.35, tuck = 0.7, la1 = 0.6, la3 = -0.7, freeL = 0 },
	Deflect = { drop = 0.25, lean = -0.05, twist = 0.18, head = 0.05, footR = 0.35, footL = -0.3, spread = 0.25, freeL = 0, la1 = 0.85, la3 = -0.4, lel = 0.9 },
	-- turning round to something behind you, led by the head (the King's entrance): the head first, then the chest
	-- and hips after it, then a step as the body comes round (L = turning to the left, R = to the right)
	TurnLookL = { look = 1.0, twist = 0.12, head = -0.05 },
	TurnTwistL = { look = 0.9, twist = 0.55, hip = 0.35, head = -0.05, footR = 0.25, footL = -0.05 },
	TurnStepL = { look = 0.4, twist = 0.25, hip = 0.15, liftL = 0.35, footL = -0.3 },
	TurnLookR = { look = -1.0, twist = -0.12, head = -0.05 },
	TurnTwistR = { look = -0.9, twist = -0.55, hip = -0.35, head = -0.05, footR = 0.05, footL = -0.25 },
	TurnStepR = { look = -0.4, twist = -0.25, hip = -0.15, lift = 0.35, footR = 0.3 },
}

for name, p in pairs(Roster.poses) do
	PM.POSES[name] = p
end

function PM.pose(name, kind)
	local kd = PM.KINDS[kind]
	if name == "Idle" and kd and kd.idlePose then
		name = kd.idlePose -- e.g. the knight's guard, Oculast's low stance
	end
	local p = table.clone(BASE)
	local over = PM.POSES[name] or PM.POSES.Idle
	for k, v in pairs(over) do
		p[k] = v
	end
	return p
end

-- the left arm folded behind the back (shoulder X/Y/Z, elbow, wrist), for ctx.armBehind
local BEHIND = { -0.18, -1.79, 0.16, 1.43, 0.25 }

function PM.lerpPose(a, b, t)
	local out = {}
	for k, v in pairs(b) do
		out[k] = (a[k] or v) + (v - (a[k] or v)) * t
	end
	return out
end

---------------------------------------------------------------------------
-- solver
---------------------------------------------------------------------------
-- frame at pos whose -Y runs along dir (the limb), X kept close to rightHint
local function frameAlong(pos, dir, rightHint)
	local y = -dir.Unit
	local x = rightHint - y * rightHint:Dot(y)
	if x.Magnitude < 1e-3 then
		x = Vector3.new(1, 0, 0) - y * y.X
		if x.Magnitude < 1e-3 then
			x = Vector3.new(0, 0, 1) - y * y.Z
		end
	end
	x = x.Unit
	return CFrame.fromMatrix(pos, x, y, x:Cross(y))
end
PM.frameAlong = frameAlong

-- two-bone IK: returns elbow/knee and the reached end point
local function twoBone(a, target, l1, l2, pole)
	local v = target - a
	local d = v.Magnitude
	local dir = d > 1e-4 and v / d or Vector3.new(0, -1, 0)
	d = math.clamp(d, math.abs(l1 - l2) + 1e-3, l1 + l2 - 1e-3)
	local x = (l1 * l1 - l2 * l2 + d * d) / (2 * d)
	local h = math.sqrt(math.max(l1 * l1 - x * x, 0))
	local p = pole - dir * pole:Dot(dir)
	if p.Magnitude < 1e-4 then
		p = Vector3.new(0, 0, 1) - dir * dir.Z
	end
	p = p.Unit
	return a + dir * x + p * h, a + dir * d
end
PM.twoBone = twoBone

-- ctx: phase, walk (0..1), stride, lift, moveDir, t, groundY,
--      rightTarget/leftTarget (world grip points), noIK,
--      bodyRot (CFrame, root space), bodyDrop, tuck, limp, armOverride {a1,a2,a3,el},
--      armBehind (0..1: the left arm folded behind the back, hand at the small of it),
--      bend (radians, + = left: a sideways curl into a turn - the hips swung out the other
--      way, the waist and the neck into it, all about the true vertical, so a body pitched
--      flat, like a dog's, curls round)
-- returns C0 by joint name, and world CFrames of key parts (for hand-held props)
function PM.solve(D, J, rootCF, P, ctx)
	local s = D.s
	local C0, W = {}, {}
	local walk = ctx.walk or 0
	local phase = ctx.phase or 0
	local bob = walk * 0.08 * s * (1 - math.cos(2 * phase)) * 0.5
	local breath = math.sin((ctx.t or 0) * 1.8) * 0.015 * (P.breathe or 1)

	-- hips (whole-body rotation for rolls / knockdowns happens here)
	-- (a bend into a turn swings the hips out the other way a little, so the body curls)
	local hipsBend = ctx.bend and CFrame.Angles(0, -ctx.bend * 0.5, 0) or CFrame.new()
	local hipsLocal = CFrame.new(0, -(P.drop * s) - bob - (ctx.bodyDrop or 0), 0) * hipsBend * CFrame.Angles(0, P.hip or 0, 0) * (ctx.bodyRot or CFrame.new()) * J.Root.C0
	C0.Root = hipsLocal
	local hipsCF = rootCF * hipsLocal
	W.Hips = hipsCF

	-- torso
	local lean = P.lean + D.hunch + breath + walk * 0.08
	local bend = ctx.bend or 0
	local waistC0 = J.Waist.C0 * CFrame.Angles(0, bend * 1.5, 0) * CFrame.Angles(-lean, P.twist, P.side) -- (1.5: back past the hips' swing)
	C0.Waist = waistC0
	local chestCF = hipsCF * waistC0 * J.Waist.C1:Inverse()
	W.Chest = chestCF
	-- (the neck's share of the bend turns about the world's up, as seen from the pitched chest)
	local neckBend = bend ~= 0 and CFrame.fromAxisAngle(Vector3.new(0, math.cos(lean), math.sin(lean)), bend * 1.3) or CFrame.new()
	C0.Neck = J.Neck.C0 * neckBend * CFrame.Angles(-P.head + lean * 0.45, -P.twist * 0.4 - (P.hip or 0) * 0.7 + (P.look or 0), 0)

	-- arms
	local chestRight = chestCF.RightVector
	for _, side in ipairs({ { "R", 1 }, { "L", -1 } }) do
		local n, sx = side[1], side[2]
		local Js, Je = J[n .. "Shoulder"], J[n .. "Elbow"]
		local target = (n == "R") and ctx.rightTarget or ctx.leftTarget
		if target and not ctx.noIK then
			local shoulderPos = (chestCF * Js.C0).Position
			local wide = D.elbowOut or 0 -- (the elbow bent out toward the side, not down and back)
			local pole = chestCF:VectorToWorldSpace(Vector3.new(sx * (0.8 + wide * 1.2), -0.55 + wide * 0.3, 0.6 - wide * 0.25))
			local elbow, tip = twoBone(shoulderPos, target, D.upperArm, D.lowerArm, pole)
			local J1 = frameAlong(shoulderPos, elbow - shoulderPos, chestRight)
			C0[n .. "Shoulder"] = chestCF:Inverse() * J1
			local upperCF = J1 * Js.C1:Inverse()
			local J2 = frameAlong(elbow, tip - elbow, chestRight)
			C0[n .. "Elbow"] = upperCF:Inverse() * J2
			W[n .. "LowerArm"] = J2 * Je.C1:Inverse()
		else
			local a1, a2, a3, el
			if ctx.armOverride then
				a1, a2, a3, el = ctx.armOverride[1], ctx.armOverride[2], sx * ctx.armOverride[3], ctx.armOverride[4]
			elseif n == "L" then
				a1, a2, a3, el = P.la1, P.la2, P.la3, P.lel
			else
				a1, a2, a3, el = P.ra1, P.ra2, P.ra3, P.rel
			end
			local k = n == "L" and ctx.armBehind or 0
			if k > 0 then
				local B = BEHIND
				a1, a2, a3, el = a1 + (B[1] - a1) * k, a2 + (B[2] - a2) * k, a3 + (B[3] - a3) * k, el + (B[4] - el) * k
			end
			local swing = (n == "L" and P.freeL or 1) * (1 - k) * walk * 0.55 * math.sin(phase + (n == "L" and 0 or math.pi))
			local sC0 = Js.C0 * CFrame.Angles(a1 + swing, a2, a3 + sx * (D.elbowOut or 0) * 0.25) -- (and the arm opened out at the shoulder)
			local eC0 = Je.C0 * CFrame.Angles(el + (1 - k) * walk * 0.25, 0, 0)
			C0[n .. "Shoulder"] = sC0
			C0[n .. "Elbow"] = eC0
			local upperCF = chestCF * sC0 * Js.C1:Inverse()
			W[n .. "LowerArm"] = upperCF * eC0 * Je.C1:Inverse()
		end
		local Jw = J[n .. "Wrist"]
		if Jw then
			local wr = n == "L" and P.lwr + (BEHIND[5] - P.lwr) * (ctx.armBehind or 0) or P.rwr
			C0[n .. "Wrist"] = Jw.C0 * CFrame.Angles(wr, 0, 0)
		end
	end

	-- legs
	local look = rootCF.LookVector
	local fwd = Vector3.new(look.X, 0, look.Z)
	fwd = fwd.Magnitude > 1e-3 and fwd.Unit or Vector3.new(0, 0, -1)
	local rgt = Vector3.new(-fwd.Z, 0, fwd.X)
	local yawRot = CFrame.fromMatrix(Vector3.zero, rgt, Vector3.new(0, 1, 0), -fwd)
	local moveDir = ctx.moveDir or fwd
	local groundY = ctx.groundY or (rootCF.Position.Y - D.rootY)
	local tuck = math.max(P.tuck or 0, ctx.tuck or 0)
	local limp = ctx.limp or 0
	local hipsRight = hipsCF.RightVector
	for _, side in ipairs({ { "R", 1 }, { "L", -1 } }) do
		local n, sx = side[1], side[2]
		local Jh, Jk, Ja = J[n .. "Hip"], J[n .. "Knee"], J[n .. "Ankle"]
		local hipPos = (hipsCF * Jh.C0).Position
		local ph = phase + (n == "R" and 0 or math.pi)
		local stance = ((n == "R") and P.footR or P.footL) * s
		local base = rootCF.Position + rgt * sx * (D.hipX + (P.spread or 0) * s) + fwd * stance
		local foot = Vector3.new(base.X, groundY + D.ankleY, base.Z)
			+ moveDir * math.sin(ph) * (ctx.stride or 0)
			+ Vector3.new(0, math.max(0, math.cos(ph)) * (ctx.lift or 0), 0)
		if n == "R" and (P.lift or 0) > 0 then
			foot += Vector3.new(0, P.lift * s, 0) + fwd * 0.35 * s * P.lift
		elseif n == "L" and (P.liftL or 0) > 0 then
			foot += Vector3.new(0, P.liftL * s, 0) + fwd * 0.35 * s * P.liftL
		end
		if tuck > 0 then
			local tucked = (hipsCF * CFrame.new(sx * D.hipX, -0.45 * s, -1.0 * s)).Position
			foot = foot:Lerp(tucked, math.clamp(tuck, 0, 1))
		end
		local cross = math.clamp(P.cross or 0, 0, 1)
		if cross > 0 then
			local crossed = (hipsCF * CFrame.new(-sx * D.hipX * 1.2, -0.3 * s, (-0.95 - sx * 0.12) * s)).Position
			foot = foot:Lerp(crossed, cross)
		end
		if limp > 0 then
			local straight = (hipsCF * CFrame.new(sx * D.hipX * 1.4, -(D.thigh + D.shin) * 0.97, -0.3 * s)).Position
			foot = foot:Lerp(straight, math.clamp(limp, 0, 1))
		end
		local knee, ankle = twoBone(hipPos, foot, D.thigh, D.shin, hipsCF.LookVector + fwd * 0.3 + hipsRight * sx * cross * 1.6)
		local J1 = frameAlong(hipPos, knee - hipPos, hipsRight)
		C0[n .. "Hip"] = hipsCF:Inverse() * J1
		local thighCF = J1 * Jh.C1:Inverse()
		local J2 = frameAlong(knee, ankle - knee, hipsRight)
		C0[n .. "Knee"] = thighCF:Inverse() * J2
		local shinCF = J2 * Jk.C1:Inverse()
		-- feet stay flat on the floor unless the whole body is rolling / lying down
		local flatFoot = CFrame.new(ankle) * yawRot
		-- (limbs rigs rise onto their toes: the foot pitched heel-up, the toes bent back flat)
		local toe = J[n .. "Toe"] and P.toe or 0
		local footJ = (tuck > 0.2 or limp > 0.2 or cross > 0.2) and (CFrame.new(ankle) * shinCF.Rotation) or flatFoot * CFrame.Angles(-toe, 0, 0)
		C0[n .. "Ankle"] = shinCF:Inverse() * footJ
		W[n .. "Foot"] = footJ * Ja.C1:Inverse()
		if J[n .. "Toe"] then
			C0[n .. "Toe"] = J[n .. "Toe"].C0 * CFrame.Angles(toe, 0, 0)
		end
	end
	return C0, W
end

return PM
