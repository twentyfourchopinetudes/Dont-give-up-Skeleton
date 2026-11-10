--!nonstrict
-- THE CARRIER, shared half: what answers the prison's bell (GameServer/Carrier runs the event).
-- A knot of sinew with no front and no face, bristling with forty-odd spindly grey arms that
-- sprout every which way and never agree on anything - some drag it along, the rest twitch
-- and claw at the air - and three ragged wings, one of them stupidly on its front. Built in
-- the image of what the rot made of the Usher (Characters/Oculast, mutate()), only far more.
--
--   Carrier.at(plan, t)  where its body is t seconds into the trip, for the server (which
--                        carries the player along it) and the clients (which draw it)
--   Carrier.play(plan)   (client) builds it, runs the whole trip, and throws it away
-- plan = { wallX, z, ktop, start (the player), back (unit, their way of backing off), held
-- (where they end up), landing, seed }: made by the server, sent to every client.
local RunService = game:GetService("RunService")
local PM = require(script.Parent:WaitForChild("PuppetMath"))

local Carrier = {}
Carrier.HANG = CFrame.new(0, -6, -8) -- where the held player hangs, in its body's space

-- the trip, in seconds
Carrier.CLIMB, Carrier.CREST, Carrier.GRAB, Carrier.FLY, Carrier.LEAVE = 4, 1.4, 0.9, 8, 3

local function frame(pos, fwd, up)
	return CFrame.lookAt(pos, pos + fwd, up)
end

local function legs(plan)
	local top = Vector3.new(plan.wallX + 4, plan.ktop + 1, plan.z)
	local over = Vector3.new(plan.wallX - 4, plan.ktop + 5, plan.z)
	local to = Vector3.new(plan.held.X, plan.ktop + 5, plan.held.Z)
	local dir = Vector3.new(to.X - over.X, 0, to.Z - over.Z)
	dir = dir.Magnitude > 1 and dir.Unit or Vector3.new(-1, 0, 0)
	local dist = (Vector3.new(to.X, 0, to.Z) - Vector3.new(over.X, 0, over.Z)).Magnitude
	local stopAt = over + dir * math.max(dist - 10, 0)
	return top, over, dir, stopAt, math.max(dist / 9, 0.8)
end

function Carrier.crawlTime(plan)
	return select(5, legs(plan))
end

function Carrier.total(plan)
	return Carrier.CLIMB + Carrier.CREST + Carrier.crawlTime(plan) + Carrier.GRAB + Carrier.FLY + Carrier.LEAVE + (plan.pauseFor or 0)
end

-- the trip's clock with its pause taken out (plan.pauseAt, .pauseFor: it hangs in the air there while the first
-- trip's cutscene has the camera, GameServer/Carrier)
function Carrier.pathTime(plan, t)
	if plan.pauseAt and t > plan.pauseAt then
		return math.max(plan.pauseAt, t - plan.pauseFor)
	end
	return t
end

-- the flight: up from the deck in a long arc over the township, down to just above the landing
local function flight(plan, stopAt, k)
	local p2 = plan.landing + Vector3.new(0, 18, -14)
	local p1 = (stopAt + p2) / 2 + Vector3.new(0, 110, 0)
	local e = k < 0.5 and 2 * k * k or 1 - (-2 * k + 2) ^ 2 / 2
	return stopAt:Lerp(p1, e):Lerp(p1:Lerp(p2, e), e)
end

-- returns its body frame, "walk" or "fly", and what its arms reach for (nil = nothing)
function Carrier.at(plan, t)
	local top, over, dir, stopAt, crawl = legs(plan)
	local up = Vector3.new(0, 1, 0)
	if t < Carrier.CLIMB then -- up the outside of the wall, its back to the drop
		local k = t / Carrier.CLIMB
		local bottom = top - Vector3.new(0, 47, 0)
		return frame(bottom:Lerp(top, k), up, Vector3.new(1, 0, 0)), "walk"
	end
	t -= Carrier.CLIMB
	if t < Carrier.CREST then -- over the parapet, tipping onto the deck
		local k = t / Carrier.CREST
		local e = k * k * (3 - 2 * k)
		return frame(top, up, Vector3.new(1, 0, 0)):Lerp(frame(over, Vector3.new(-1, 0, 0), up), e) + up * math.sin(k * math.pi) * 5, "walk"
	end
	t -= Carrier.CREST
	if t < crawl then -- across the deck
		return frame(over:Lerp(stopAt, t / crawl), dir, up), "walk"
	end
	t -= crawl
	if t < Carrier.GRAB then -- it reaches
		return frame(stopAt, dir, up), "walk", plan.held + Vector3.new(0, 1, 0)
	end
	t -= Carrier.GRAB
	if t < Carrier.FLY then -- and carries
		local k = t / Carrier.FLY
		local p, q = flight(plan, stopAt, k), flight(plan, stopAt, math.max(k - 0.01, 0))
		local v = p - q
		local flat = Vector3.new(v.X, 0, v.Z)
		flat = flat.Magnitude > 0.001 and flat.Unit or dir
		local fwd = v.Magnitude > 0.001 and (flat + up * (v.Unit.Y * 0.6)).Unit or flat
		local cf = frame(p, fwd, up) * CFrame.Angles(0, 0, math.sin(k * 9) * 0.15)
		return cf, "fly", (cf * Carrier.HANG).Position + up * 2
	end
	t -= Carrier.FLY
	local from = flight(plan, stopAt, 1)
	local k = math.min(t / Carrier.LEAVE, 1)
	return frame(from + Vector3.new(k * 30, k * k * 170, k * 60), Vector3.new(0.4, 0.6, 0.7).Unit, up), "fly"
end

---------------------------------------------------------------------------
-- its body (client)
---------------------------------------------------------------------------
local FLESH = Color3.fromRGB(150, 138, 116) -- grey, bloodless (the Usher's arm)
local ROT_FLESH, ROT_DARK = Color3.fromRGB(110, 92, 62), Color3.fromRGB(62, 48, 38)
local FLESH_DARK = FLESH:Lerp(ROT_DARK, 0.55)
local CLAW = Color3.fromRGB(40, 34, 28)
local FEATHER, FEATHER_DARK = Color3.fromRGB(176, 168, 146), Color3.fromRGB(92, 84, 70)
local SPORE = Color3.fromRGB(200, 192, 120)
local LIMBS, WALKERS = 42, 16 -- (WALKERS of them actually find the ground)

local function build(seed)
	local rnd = Random.new(seed)
	local function r(a, b)
		return rnd:NextNumber(a, b)
	end
	local model = Instance.new("Model")
	model.Name = "Carrier"
	local all = {}
	local function mk(name, size, color, shape, mat)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = mat or Enum.Material.SmoothPlastic
		p.Reflectance = 0.06
		p.Anchored = true
		p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
		p.CastShadow = false
		if shape then
			p.Shape = shape
		end
		p.Parent = model
		table.insert(all, p)
		return p
	end
	local BALL, CYL = Enum.PartType.Ball, Enum.PartType.Cylinder
	local c = { model = model, all = all, walkers = {}, flailers = {}, wings = {} }
	-- no body to speak of: a knot of sinew - short limb-ends grown into each other, densest
	-- at the middle and thinning out - with little knuckles where they meet. Everything else
	-- sprouts from its knots, and the whole knot flexes.
	c.nodes, c.sinews, c.knuckles = {}, {}, {}
	for i = 1, 26 do
		local d = Vector3.new(r(-1, 1), r(-1, 1), r(-1, 1))
		d = d.Magnitude > 0.01 and d.Unit or Vector3.new(0, 1, 0)
		local k = i == 1 and 0 or rnd:NextNumber() ^ 1.7 -- (most of them near the middle)
		table.insert(c.nodes, { base = Vector3.new(d.X * 4.5, d.Y * 3, d.Z * 6.5) * k, ph = r(0, 6) })
	end
	local function sinew(a, b)
		local la, lb = c.nodes[a].base, c.nodes[b].base
		local th = 0.6 - math.min((la.Magnitude + lb.Magnitude) / 2 / 6, 1) * 0.42
		local col = FLESH:Lerp(ROT_FLESH, r(0, 0.7)):Lerp(ROT_DARK, r(0, 0.4))
		table.insert(c.sinews, { a = a, b = b, p = mk("Sinew", Vector3.new((la - lb).Magnitude, th, th), col, CYL) })
	end
	for i = 2, #c.nodes do
		-- tied to the nearest knot before it (so it's all one knot), and sometimes another
		local best, bestD = 1, math.huge
		for j = 1, i - 1 do
			local d = (c.nodes[i].base - c.nodes[j].base).Magnitude
			if d < bestD then
				best, bestD = j, d
			end
		end
		sinew(i, best)
		if rnd:NextNumber() < 0.6 then
			local j = rnd:NextInteger(1, i - 1)
			if j ~= best then
				sinew(i, j)
			end
		end
	end
	for i, n in ipairs(c.nodes) do
		if i == 1 or rnd:NextNumber() < 0.5 then
			local s = r(0.35, 0.7) + (1 - math.min(n.base.Magnitude / 6, 1)) * 0.4
			table.insert(c.knuckles, { i = i, p = mk("Knuckle", Vector3.new(s, s, s), (rnd:NextNumber() < 0.3 and SPORE:Lerp(ROT_FLESH, 0.5) or FLESH_DARK:Lerp(ROT_DARK, r(0, 0.6))), BALL) })
		end
	end
	-- where an arm sprouts: a knot, pointing roughly away from the middle (under = downward)
	local function surface(under)
		local pick
		for _ = 1, 12 do
			pick = rnd:NextInteger(1, #c.nodes)
			if not under or c.nodes[pick].base.Y <= 0.3 then
				break
			end
		end
		local b = c.nodes[pick].base
		local u = (b.Magnitude > 0.3 and b.Unit * 0.6 or Vector3.zero) + Vector3.new(r(-1, 1), r(-1, 1), r(-1, 1)) * 0.8
		if under then
			u = Vector3.new(u.X, -math.abs(u.Y) - 0.5, u.Z)
		end
		return pick, u.Magnitude > 0.01 and u.Unit or Vector3.new(0, -1, 0)
	end
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pe.Rate = 14
	pe.Lifetime = NumberRange.new(1.5, 3)
	pe.Speed = NumberRange.new(1, 3)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Size = NumberSequence.new(0.8, 2.5)
	pe.Transparency = NumberSequence.new(0.6, 1)
	pe.Color = ColorSequence.new(SPORE)
	pe.Parent = c.knuckles[1].p
	-- the arms. Walkers sprout from underneath and grope for footing; the rest sprout from
	-- anywhere, pointing anywhere, a few joints each, twitching on their own
	for i = 1, LIMBS do
		local col = FLESH:Lerp(FLESH_DARK, r(0, 0.8))
		if i <= WALKERS then
			local node, u = surface(true)
			local l1, l2 = r(5, 8), r(6, 10)
			local out = Vector3.new(u.X, 0, u.Z)
			out = out.Magnitude > 0.05 and out.Unit or Vector3.new(r(-1, 1), 0, r(-1, 1)).Unit
			table.insert(c.walkers, {
				node = node, out = out, l1 = l1, l2 = l2,
				reach = r(0.6, 1.1), -- how far out it gropes (some barely bother)
				thresh = r(4, 9), stepDur = r(0.12, 0.35), miss = Vector3.new(r(-2, 2), 0, r(-2, 2)),
				a = mk("Limb", Vector3.new(l1, r(0.3, 0.5), r(0.3, 0.5)), col, CYL),
				b = mk("Limb", Vector3.new(l2, r(0.2, 0.35), r(0.2, 0.35)), col:Lerp(FLESH_DARK, 0.3), CYL),
				knee = mk("Joint", Vector3.new(0.7, 0.7, 0.7), FLESH_DARK, BALL),
				claw = mk("Claw", Vector3.new(1.4, 0.15, 0.15), CLAW, CYL),
				ph = r(0, 6),
			})
		else
			local node, u = surface(false)
			local n = rnd:NextInteger(3, 5)
			local segs = {}
			for k = 1, n do
				local len = r(2, 4.6) * (1 - (k - 1) * 0.12)
				local th = math.max(0.38 - k * 0.06, 0.12)
				table.insert(segs, {
					len = len,
					p = mk("Limb", Vector3.new(len, th, th), col:Lerp(FLESH_DARK, k * 0.12), CYL),
					j = mk("Joint", Vector3.new(th * 1.6, th * 1.6, th * 1.6), FLESH_DARK, BALL),
					rest = Vector2.new(r(-0.9, 0.9), r(-0.9, 0.9)),
					cur = Vector2.zero, goal = Vector2.zero,
				})
			end
			if rnd:NextNumber() < 0.25 then -- a bone spur
				segs[1].spur = mk("Spur", Vector3.new(0.9, 0.12, 0.12), CLAW, CYL)
			end
			local hand
			if rnd:NextNumber() < 0.4 then -- a hand: four long fingers
				hand = {}
				for f = 1, 4 do
					table.insert(hand, { p = mk("Finger", Vector3.new(r(1, 1.8), 0.1, 0.1), FLESH_DARK, CYL), tip = mk("Claw", Vector3.new(0.6, 0.08, 0.08), CLAW, CYL), splay = (f - 2.5) * 0.35 })
				end
			else
				hand = { claw = mk("Claw", Vector3.new(1, 0.12, 0.12), CLAW, CYL) }
			end
			table.insert(c.flailers, { node = node, u = u, segs = segs, hand = hand, next = 0, clench = 0 })
		end
	end
	-- the three wings: two off its back, set wrong, and one on its front, for no reason
	for _, w in ipairs({
		{ at = Vector3.new(-2.5, 3.5, 2), spread = Vector3.new(-1, 0.6, 0.4), axis = Vector3.new(0, 0, 1), lens = { 4, 6.5, 4.5 }, ph = 0 },
		{ at = Vector3.new(3, 3, -1), spread = Vector3.new(1, 0.9, 0.2), axis = Vector3.new(0, 0, 1), lens = { 3.5, 5.5, 5 }, ph = 1.7 },
		{ at = Vector3.new(0.5, 1, -8), spread = Vector3.new(0.3, 0.7, -1), axis = Vector3.new(1, 0, 0), lens = { 3, 5, 3.5 }, ph = 0.6 },
	}) do
		w.spread = w.spread.Unit
		local best, bestD = 1, math.huge
		for i, n in ipairs(c.nodes) do
			local d = (n.base - w.at).Magnitude
			if d < bestD then
				best, bestD = i, d
			end
		end
		w.node = best
		w.bones = {}
		for k, len in ipairs(w.lens) do
			local feathers = {}
			for f = 1, ({ 3, 7, 5 })[k] do
				if rnd:NextNumber() > 0.2 then -- some plucked out
					table.insert(feathers, { f = (f - 0.5) / ({ 3, 7, 5 })[k], len = ({ 2, 4.5, 4 })[k] * r(0.6, 1.1), p = nil })
				end
			end
			for _, fe in ipairs(feathers) do
				fe.p = mk("Feather", Vector3.new(0.5, fe.len, 0.05), FEATHER:Lerp(FEATHER_DARK, r(0, 0.8)), nil, Enum.Material.Fabric)
			end
			table.insert(w.bones, { len = len, p = mk("WingBone", Vector3.new(len, 0.25 - k * 0.04, 0.25 - k * 0.04), FEATHER:Lerp(ROT_FLESH, 0.5), CYL), j = mk("Joint", Vector3.new(0.45, 0.45, 0.45), ROT_FLESH, BALL), feathers = feathers, bend = Vector2.new(r(-0.4, 0.2), r(-0.3, 0.3)) })
		end
		table.insert(c.wings, w)
	end
	model.Parent = workspace
	return c, rnd
end

-- a limb segment from a to b (cylinders run along X)
local function seg(a, b)
	if (b - a).Magnitude < 0.01 then
		return CFrame.new(a)
	end
	return CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0)
end

local footParams = RaycastParams.new()
footParams.FilterType = Enum.RaycastFilterType.Include

local function draw(c, rnd, cf, mode, t, dt, reach)
	local parts, cfs = {}, {}
	local function put(p, x)
		table.insert(parts, p)
		table.insert(cfs, x)
	end
	local up = cf.UpVector
	local flying = mode == "fly"
	-- the knot flexes: its outer knots wander more than the middle
	local np = {}
	for i, n in ipairs(c.nodes) do
		local wob = Vector3.new(math.sin(t * 3 + n.ph), math.cos(t * 2.6 + n.ph), math.sin(t * 2.2 + n.ph * 1.3))
		np[i] = cf * (n.base + wob * 0.35 * (0.4 + n.base.Magnitude / 6))
	end
	for _, s in ipairs(c.sinews) do
		put(s.p, seg(np[s.a], np[s.b]))
	end
	for _, k in ipairs(c.knuckles) do
		put(k.p, CFrame.new(np[k.i]))
	end
	-- walkers: each gropes for the stone on its own schedule
	for _, w in ipairs(c.walkers) do
		local hip = np[w.node]
		local ideal
		if not flying then
			local dir = cf:VectorToWorldSpace((w.out * w.reach + Vector3.new(0, -1, 0)).Unit)
			local res = workspace:Raycast(hip + up, dir * (w.l1 + w.l2 + 4), footParams)
			ideal = (res and res.Position or hip + cf:VectorToWorldSpace(w.out) * 8 - up * 8) + w.miss
		else
			ideal = hip + cf:VectorToWorldSpace(w.out) * (w.l1 + w.l2) * 0.5 - up * (w.l1 + w.l2) * 0.6
				+ Vector3.new(math.sin(t * 7 + w.ph), math.cos(t * 6 + w.ph), math.sin(t * 5 + w.ph * 2)) * 3
		end
		w.foot = w.foot or ideal
		if w.stepT then
			w.stepT += dt / w.stepDur
			local k = math.min(w.stepT, 1)
			w.foot = w.from:Lerp(w.to, k) + up * math.sin(k * math.pi) * 2.5
			if k >= 1 then
				w.stepT = nil
			end
		elseif flying then
			w.foot = w.foot:Lerp(ideal, math.min(dt * 6, 1))
		elseif (ideal - w.foot).Magnitude > w.thresh and rnd:NextNumber() < 0.5 then
			w.from, w.to, w.stepT = w.foot, ideal, 0
			w.miss = Vector3.new(rnd:NextNumber(-2, 2), 0, rnd:NextNumber(-2, 2))
		end
		local knee, foot = PM.twoBone(hip, w.foot, w.l1, w.l2, up * 2 + cf:VectorToWorldSpace(w.out))
		put(w.a, seg(hip, knee))
		put(w.b, seg(knee, foot))
		put(w.knee, CFrame.new(knee))
		local d = (foot - knee).Magnitude > 0.01 and (foot - knee).Unit or -up
		put(w.claw, seg(foot, foot + d * 1.4))
	end
	-- the rest: twitching, spasming, clawing at nothing - and the nearest few reach when told to
	for i, f in ipairs(c.flailers) do
		local root = np[f.node]
		local reaching = reach and i <= 8
		if t >= f.next then
			local hard = rnd:NextNumber() < 0.2
			local amp = (hard and 1.1 or 0.35) * (flying and 1.6 or 1)
			for _, s in ipairs(f.segs) do
				s.goal = s.rest + Vector2.new(rnd:NextNumber(-amp, amp), rnd:NextNumber(-amp, amp))
			end
			f.clench = rnd:NextNumber() < 0.5 and rnd:NextNumber(0.4, 1) or rnd:NextNumber(-0.4, 0)
			f.next = t + (hard and 0.08 or rnd:NextNumber(0.12, 0.5))
		end
		local dir = cf:VectorToWorldSpace(f.u)
		if reaching then
			dir = (reach - root).Magnitude > 0.1 and (reach - root).Unit or dir
		end
		local F = CFrame.lookAt(root, root + dir, math.abs(dir.Y) > 0.95 and cf.LookVector or up)
		for k, s in ipairs(f.segs) do
			s.cur = s.cur:Lerp(reaching and Vector2.new(0.08, 0.05) or s.goal, math.min(dt * 14, 1))
			F = F * CFrame.Angles(s.cur.X * (k == 1 and 0.4 or 1), s.cur.Y * (k == 1 and 0.4 or 1), 0)
			local a = F.Position
			local b = a + F.LookVector * s.len
			put(s.p, seg(a, b))
			put(s.j, CFrame.new(a))
			if s.spur then
				put(s.spur, seg(a:Lerp(b, 0.5), a:Lerp(b, 0.5) + F.UpVector * 0.9))
			end
			F = CFrame.new(b) * F.Rotation
		end
		if f.hand.claw then
			put(f.hand.claw, seg(F.Position, F.Position + F.LookVector))
		else
			for _, fg in ipairs(f.hand) do
				local G = F * CFrame.Angles(-f.clench, fg.splay, 0)
				local tip = G.Position + G.LookVector * fg.p.Size.X
				put(fg.p, seg(G.Position, tip))
				local G2 = CFrame.new(tip) * G.Rotation * CFrame.Angles(-0.6 - f.clench * 0.5, 0, 0)
				put(fg.tip, seg(tip, tip + G2.LookVector * 0.6))
			end
		end
	end
	-- wings: a slow shudder on the ground; in the air, beating out of time with each other
	for _, w in ipairs(c.wings) do
		local flap = flying and math.sin(t * 6 + w.ph) * 0.9 or math.sin(t * 2 + w.ph) * 0.12 + (rnd:NextNumber() < 0.02 and 0.3 or 0)
		local F = CFrame.new(np[w.node]) * cf.Rotation * CFrame.fromAxisAngle(w.axis, flap) * CFrame.lookAt(Vector3.zero, w.spread)
		for k, b in ipairs(w.bones) do
			F = F * CFrame.Angles(b.bend.X + (k > 1 and flap * 0.3 or 0), b.bend.Y, 0)
			local a = F.Position
			local e = a + F.LookVector * b.len
			put(b.p, seg(a, e))
			put(b.j, CFrame.new(a))
			for _, fe in ipairs(b.feathers) do
				local base = a:Lerp(e, fe.f)
				local hang = -F.UpVector * 0.85 - F.LookVector * 0.3
				local y = (hang - F.LookVector * hang:Dot(F.LookVector)).Unit
				put(fe.p, CFrame.fromMatrix(base + y * fe.len / 2, F.LookVector, y))
			end
			F = CFrame.new(e) * F.Rotation
		end
	end
	workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
end

function Carrier.play(plan)
	local map = workspace:FindFirstChild("DGUS")
	footParams.FilterDescendantsInstances = { map }
	local c, rnd = build(plan.seed)
	local t0, total = os.clock(), Carrier.total(plan)
	local last = t0
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local now = os.clock()
		local t = now - t0
		if t >= total then
			conn:Disconnect()
			c.model:Destroy()
			return
		end
		local ok, err = pcall(function()
			local cf, mode, reach = Carrier.at(plan, Carrier.pathTime(plan, t))
			draw(c, rnd, cf, mode, t, now - last, reach)
		end)
		last = now
		if not ok then
			conn:Disconnect()
			c.model:Destroy()
			warn("[Carrier] " .. tostring(err))
		end
	end)
end

---------------------------------------------------------------------------
-- (client) the same arms, grown out of things: every part tagged "RotLimb" (its LookVector
-- = which way the arm sprouts, attributes Scale and Seed) gets one, twitching and clawing
-- at nothing - and reaching for you when you come close. Only the ones near the camera move.
-- An anchor with the attribute Follow (one on a creature's body) is tracked as it moves,
-- and its arm goes when the anchor does.
---------------------------------------------------------------------------
function Carrier.growths()
	local CollectionService = game:GetService("CollectionService")
	local Players = game:GetService("Players")
	local folder = Instance.new("Folder")
	folder.Name = "RotLimbs"
	folder.Parent = workspace
	local limbs = {}
	local BALL, CYL = Enum.PartType.Ball, Enum.PartType.Cylinder
	local made -- (while growing one: every part it's built from, so a followed one can be cleared)
	local function mk(name, size, color, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.Reflectance = 0.06
		p.Anchored = true
		p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
		p.CastShadow = false
		p.Shape = shape
		p.Parent = folder
		table.insert(made, p)
		return p
	end
	local NEAR, REACH = 140, 12
	local function poseLimb(l, t, dt, you, put)
		local root = l.cf.Position
		local rnd = l.rnd
		local reaching = not l.hair and you and (you - root).Magnitude < REACH
		if t >= l.next then
			local hard = rnd:NextNumber() < 0.2
			local amp = hard and 1.1 or 0.35
			for _, s in ipairs(l.segs) do
				s.goal = s.rest + Vector2.new(rnd:NextNumber(-amp, amp), rnd:NextNumber(-amp, amp))
			end
			l.clench = rnd:NextNumber() < 0.5 and rnd:NextNumber(0.4, 1) or rnd:NextNumber(-0.4, 0)
			l.next = t + (hard and 0.08 or rnd:NextNumber(0.12, 0.6))
		end
		local dir = l.cf.LookVector
		if reaching then
			dir = (dir + (you - root).Unit * 2).Unit -- it turns toward you, grasping
		end
		local F = CFrame.lookAt(root, root + dir, math.abs(dir.Y) > 0.95 and Vector3.new(1, 0, 0) or Vector3.new(0, 1, 0))
		for k, s in ipairs(l.segs) do
			s.cur = s.cur:Lerp(reaching and s.goal * 0.25 or s.goal, math.min(dt * 14, 1))
			F = F * CFrame.Angles(s.cur.X * (k == 1 and 0.4 or 1), s.cur.Y * (k == 1 and 0.4 or 1), 0)
			local a = F.Position
			local b = a + F.LookVector * s.len
			put(s.p, seg(a, b))
			put(s.j, CFrame.new(a))
			F = CFrame.new(b) * F.Rotation
		end
		if l.hand.claw then
			put(l.hand.claw, seg(F.Position, F.Position + F.LookVector * l.hand.claw.Size.X))
		else
			for _, fg in ipairs(l.hand) do
				local G = F * CFrame.Angles(-l.clench, fg.splay, 0)
				local tip = G.Position + G.LookVector * fg.p.Size.X
				put(fg.p, seg(G.Position, tip))
				local G2 = CFrame.new(tip) * G.Rotation * CFrame.Angles(-0.6 - l.clench * 0.5, 0, 0)
				put(fg.tip, seg(tip, tip + G2.LookVector * 0.6))
			end
		end
	end
	local function grow(anchor)
		if not anchor:IsA("BasePart") then
			return
		end
		local rnd = Random.new(anchor:GetAttribute("Seed") or 1)
		local sc = anchor:GetAttribute("Scale") or 1
		local hair = anchor:GetAttribute("Hair") -- (a Color3: a writhing lock of hair instead, thin, no hand, never reaching: Characters/Hag)
		made = {}
		local col = hair or FLESH:Lerp(FLESH_DARK, rnd:NextNumber(0, 0.8))
		local segs = {}
		for k = 1, rnd:NextInteger(3, 5) do
			local len = rnd:NextNumber(2, 4.6) * (1 - (k - 1) * 0.12) * sc
			local th = hair and 0.07 or math.max(0.38 - k * 0.06, 0.12) * sc
			table.insert(segs, {
				len = len,
				p = mk("Limb", Vector3.new(len, th, th), hair and col:Lerp(Color3.new(), k * 0.06) or col:Lerp(FLESH_DARK, k * 0.12), CYL),
				j = mk("Joint", Vector3.one * th * 1.6, hair or FLESH_DARK, BALL),
				rest = Vector2.new(rnd:NextNumber(-0.9, 0.9), rnd:NextNumber(-0.9, 0.9)),
				cur = Vector2.zero,
				goal = Vector2.zero,
			})
		end
		local hand
		if rnd:NextNumber() < 0.45 then
			hand = {}
			for f = 1, 4 do
				table.insert(hand, { p = mk("Finger", Vector3.new(rnd:NextNumber(1, 1.8) * sc, 0.1, 0.1), FLESH_DARK, CYL), tip = mk("Claw", Vector3.new(0.6, 0.08, 0.08), CLAW, CYL), splay = (f - 2.5) * 0.35 })
			end
		else
			hand = { claw = mk("Claw", Vector3.new(sc, 0.12, 0.12), CLAW, CYL) }
		end
		if hair then -- (the hand's parts were made only to keep the stream: a wisp for a tip)
			for _, p in ipairs(made) do
				if p.Name == "Finger" or p.Name == "Claw" then
					p:Destroy()
				end
			end
			hand = { claw = mk("Claw", Vector3.new(sc * 1.2, 0.04, 0.04), col, CYL) }
		end
		local l = { cf = anchor.CFrame, segs = segs, hand = hand, rnd = rnd, next = 0, clench = 0, anchor = anchor, follow = anchor:GetAttribute("Follow"), parts = made, hair = hair }
		for _, s in ipairs(segs) do
			s.cur, s.goal = s.rest, s.rest
		end
		poseLimb(l, -1, 0, nil, function(part, cf)
			part.CFrame = cf
		end)
		table.insert(limbs, l)
	end
	for _, a in ipairs(CollectionService:GetTagged("RotLimb")) do
		grow(a)
	end
	CollectionService:GetInstanceAddedSignal("RotLimb"):Connect(grow)
	CollectionService:GetInstanceRemovedSignal("RotLimb"):Connect(function(anchor)
		for i = #limbs, 1, -1 do
			if limbs[i].anchor == anchor then
				for _, p in ipairs(limbs[i].parts) do
					p:Destroy()
				end
				table.remove(limbs, i)
			end
		end
	end)

	local t0, last = os.clock(), os.clock()
	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		local t, dt = now - t0, math.min(now - last, 0.1)
		last = now
		local cam = workspace.CurrentCamera.CFrame.Position
		local char = Players.LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local you = hrp and hrp.Position + Vector3.new(0, 1, 0)
		local parts, cfs = {}, {}
		local function put(p, x)
			table.insert(parts, p)
			table.insert(cfs, x)
		end
		for _, l in ipairs(limbs) do
			if l.follow then
				l.cf = l.anchor.CFrame
			end
			if (l.cf.Position - cam).Magnitude < NEAR then
				poseLimb(l, t, dt, you, put)
			end
		end
		if #parts > 0 then
			workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
		end
	end)
end

---------------------------------------------------------------------------
-- (client) CLOTH: every part tagged "ClothChain" (a cape's top edge, a plume's root) gets a
-- strip of cloth hung off it, a chain of Segs pieces Len long and Width wide (Color), swung
-- every frame as a hanging rope - gravity, a little drag, held to its length - so it trails
-- and whips behind whatever it's on. Its anchor's LookVector is the side of the body it
-- hangs out on: the cloth is never let through to the other side. (Characters/Champion.)
---------------------------------------------------------------------------
function Carrier.cloth()
	local CollectionService = game:GetService("CollectionService")
	local folder = Instance.new("Folder")
	folder.Name = "Cloth"
	folder.Parent = workspace
	local chains = {}
	local function settle(c) -- hung straight down from the anchor
		local cf = c.anchor.CFrame
		for i = 0, c.n do
			local p = cf.Position - Vector3.new(0, c.len * i, 0) + cf.LookVector * 0.2 * i
			c.pts[i], c.old[i] = p, p
		end
	end
	local function add(anchor)
		if not anchor:IsA("BasePart") then
			return
		end
		local n, len, w = anchor:GetAttribute("Segs") or 5, anchor:GetAttribute("Len") or 1, anchor:GetAttribute("Width") or 1
		local col = anchor:GetAttribute("Color") or Color3.fromRGB(90, 20, 20)
		local mat = Enum.Material[anchor:GetAttribute("Material") or "Fabric"] -- (optional, by name: e.g. the Warden's mail)
		-- (optional per-chain physics, so stacked layers move differently: Drag, Gravity = a multiple of
		-- the default, Out = how far off the body it's kept)
		local c = {
			anchor = anchor, n = n, len = len, pts = {}, old = {}, parts = {},
			drag = anchor:GetAttribute("Drag") or 0.95,
			grav = anchor:GetAttribute("Gravity") or 1,
			out = anchor:GetAttribute("Out") or 0,
		}
		for i = 1, n do
			local p = Instance.new("Part")
			p.Name = "Cloth"
			p.Size = Vector3.new(w * (1 - 0.2 * (i - 1) / n), len + 0.15, 0.12)
			p.Color = col:Lerp(Color3.new(), 0.08 * i)
			p.Material = mat
			p.Anchored = true
			p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
			p.Parent = folder
			c.parts[i] = p
		end
		settle(c)
		-- (the server sets "Glow" to turn the whole cloth glowing white)
		local function glow()
			if anchor:GetAttribute("Glow") then
				for _, p in ipairs(c.parts) do
					p.Material = Enum.Material.Neon
					game:GetService("TweenService"):Create(p, TweenInfo.new(0.8), { Color = Color3.new(1, 1, 1) }):Play()
				end
			end
		end
		glow()
		anchor:GetAttributeChangedSignal("Glow"):Connect(glow)
		-- (the server bumps "Settle" after snapping it round: hung straight on the next frame,
		-- once the move itself has arrived)
		anchor:GetAttributeChangedSignal("Settle"):Connect(function()
			c.away = true
		end)
		table.insert(chains, c)
	end
	for _, a in ipairs(CollectionService:GetTagged("ClothChain")) do
		add(a)
	end
	CollectionService:GetInstanceAddedSignal("ClothChain"):Connect(add)
	CollectionService:GetInstanceRemovedSignal("ClothChain"):Connect(function(anchor)
		for i = #chains, 1, -1 do
			if chains[i].anchor == anchor then
				for _, p in ipairs(chains[i].parts) do
					p:Destroy()
				end
				table.remove(chains, i)
			end
		end
	end)
	local GRAVITY, NEAR = Vector3.new(0, -70, 0), 220
	RunService.RenderStepped:Connect(function(dt)
		dt = math.min(dt, 1 / 30)
		local cam = workspace.CurrentCamera.CFrame.Position
		local parts, cfs = {}, {}
		for _, c in ipairs(chains) do
			local cf = c.anchor.CFrame
			if (cf.Position - cam).Magnitude > NEAR then
				c.away = true
				continue
			end
			-- (teleported, streamed in, back in range, or snapped round to face another way:
			-- hung straight again instead of whipping through the body)
			if c.away or (cf.Position - c.pts[0]).Magnitude > 30 or (c.look and cf.LookVector:Dot(c.look) < 0.5) then
				settle(c)
			end
			c.away, c.look = false, cf.LookVector
			c.pts[0] = cf.Position
			for i = 1, c.n do
				local p = c.pts[i]
				local v = (p - c.old[i]) * c.drag
				c.old[i] = p
				c.pts[i] = p + v + GRAVITY * c.grav * dt * dt
			end
			for _ = 1, 3 do -- held to its length, and kept on its own side of the body
				for i = 1, c.n do
					local d = c.pts[i] - c.pts[i - 1]
					local m = d.Magnitude
					if m > 1e-4 then
						c.pts[i] = c.pts[i - 1] + d / m * c.len
					end
					local out = (c.pts[i] - cf.Position):Dot(cf.LookVector)
					local min = c.out + 0.12 * i
					if out < min then
						c.pts[i] += cf.LookVector * (min - out)
					end
				end
			end
			for i = 1, c.n do
				local a, b = c.pts[i - 1], c.pts[i]
				local up = a - b
				up = up.Magnitude > 1e-4 and up.Unit or Vector3.new(0, 1, 0)
				local right = cf.RightVector
				right = (right - up * right:Dot(up))
				right = right.Magnitude > 1e-4 and right.Unit or up:Cross(Vector3.new(0, 0, 1)).Unit
				table.insert(parts, c.parts[i])
				table.insert(cfs, CFrame.fromMatrix((a + b) / 2, right, up))
			end
		end
		if #parts > 0 then
			workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
		end
	end)
end

return Carrier
