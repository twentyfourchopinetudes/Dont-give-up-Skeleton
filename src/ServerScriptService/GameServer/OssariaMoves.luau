--!nonstrict
-- OSSARIA'S CANDIDATE MOVES: the attack lab's (her dev menu: Attack lab). Each is a move like any of hers in
-- Characters/OssariaHeir - same shape, made of the same pieces (K: her kit, handed over by her M.init) - but marked
-- lab: she never picks one herself, it's only ever fired from the lab. To PROMOTE one into her fight: set lab = false
-- on it here (and give it a weight w and a cooldown cd); to cut one, delete it. Numbers live with each move here till
-- it's kept; then they belong in Config.Ossaria.Fight with the rest.
--   add(name, phase3only, minRange, maxRange, note, fn(b, tchar))   (note: no ; or | in it - the lab's list is split on them)
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

return function(K)
	local boss, F, V3 = K.boss, K.F, Vector3.new
	local moves = {}
	local function add(name, p3, min, max, note, fn, promoted) -- promoted: { w, cd } - it's in her fight, at that weight and cooldown
		table.insert(moves, { name = name, fn = fn, min = min, max = max, w = promoted and promoted.w or 3, cd = promoted and promoted.cd or 9, p3 = p3 or nil, lab = not promoted, note = note })
	end
	local function unit(v, fallback)
		v = K.flat(v)
		return v.Magnitude > 0.1 and v.Unit or fallback
	end
	local function facing(b)
		return unit(b.root.CFrame.LookVector, V3(1, 0, 0))
	end
	-- a ring of her string on the sand round c, drawn from r0 to r1 over sweep seconds (in to the middle, or out from
	-- it), shown faint for tell first: it cuts whoever it passes over (roll through it as it reaches you)
	local function ring(b, c, r0, r1, tell, sweep, damage, level)
		local N, segs = 12, {}
		local function place(r)
			for i = 1, N do
				local a1, a2 = (i - 1) / N * math.pi * 2, i / N * math.pi * 2
				local p1, p2 = c + V3(math.cos(a1), 0, math.sin(a1)) * r, c + V3(math.cos(a2), 0, math.sin(a2)) * r
				segs[i].Size = V3(segs[i].Size.X, segs[i].Size.Y, math.max((p2 - p1).Magnitude, 0.05))
				segs[i].CFrame = CFrame.lookAt((p1 + p2) / 2, p2)
			end
		end
		for i = 1, N do
			segs[i] = K.strand(c, c + V3(0, 0, 1), 0.25, 0.6)
			Debris:AddItem(segs[i], tell + sweep + 0.5)
		end
		place(math.max(r0, 1.5))
		task.wait(tell)
		if not K.live(b) then
			return
		end
		for _, s in ipairs(segs) do
			s.Color, s.Transparency, s.Size = K.PALE, 0.05, V3(0.5, 0.5, s.Size.Z)
		end
		K.playSound(b.root, K.SOUNDS.Lunge, 0.8, 1.3)
		local t0, was, seen = K.now(), {}, {}
		while K.live(b) do
			local k = (K.now() - t0) / sweep
			if k >= 1 then
				break
			end
			local r = r0 + (r1 - r0) * k
			place(math.max(r, 0.3))
			for pl, hrp in pairs(K.everyone()) do
				local inside = K.flat(hrp.Position - c).Magnitude < r
				if was[pl] ~= nil and was[pl] ~= inside then
					K.hitOnce({ pl }, seen, damage, c, level or "Large")
				end
				was[pl] = inside
			end
			RunService.Heartbeat:Wait()
		end
		for _, s in ipairs(segs) do
			s:Destroy()
		end
	end

	-- 1. THE NEEDLE: one string, dead straight through you, almost at once - and she's hauled along it after it, onto you
	add("Needle", false, 14, 90, "a string straight through you, then she rides it in and cuts", function(b, tchar)
		local tr = tchar:FindFirstChild("HumanoidRootPart")
		b.hum:MoveTo(b.root.Position)
		K.bodyPose(b, "OHCast", 0.25)
		K.flare(b, "R")
		if not K.hold(b, 0.45, tchar, 2.5) then
			return
		end
		local o = K.ground(b.root.Position) + V3(0, 0.15, 0)
		local d = K.flat(tr.Position - o)
		local dir = unit(d, facing(b))
		local len = math.min(d.Magnitude + 14, 80)
		local line = K.strand(o + dir * 3, o + dir * len, 0.2, 0.45)
		Debris:AddItem(line, 3)
		if not K.hold(b, 0.4) then
			line:Destroy()
			return
		end
		K.bodyPose(b, "OHYank", 0.08)
		K.pluck(line, 1.6)
		K.cut(o + dir * 3, dir, len, 1.7, {}, 24, "Medium")
		K.playSound(b.root, K.SOUNDS.Lunge, 1, 1.3)
		K.shake(o, 0.5)
		if not K.hold(b, 0.18) then
			return
		end
		local from = b.root.Position
		K.bodyPose(b, "OHPierce", 0.1)
		K.flight(b, from, K.clampToArena(b, from + dir * math.max(d.Magnitude - 7, 0)), 0.3, 1.5)
		if K.live(b) and K.cut1(b, tchar, "L", 0.5, 8, F.RakeRange, F.RakeArc, F.RakeDamage) then
			K.recover(b, 1.0)
		end
	end)

	-- 2. THE SNARE: a ring of her string laid round where you stand, and drawn shut; then another
	add("Snare", false, 0, 90, "a ring of string round you, drawn shut, twice", function(b, tchar)
		local tr = tchar:FindFirstChild("HumanoidRootPart")
		b.hum:MoveTo(b.root.Position)
		K.shift(b, tchar, 9, K.either())
		for i = 1, 2 do
			K.bodyPose(b, i == 1 and "OHCast" or "OHCastL", 0.2)
			K.flare(b, i == 1 and "R" or "L")
			local c = K.ground(tr.Position + K.flat(tr.AssemblyLinearVelocity) * 0.3) + V3(0, 0.15, 0)
			task.spawn(ring, b, c, 10, 0, 0.75, 0.6, 22)
			if not K.hold(b, 0.7, tchar, 1.5) then
				return
			end
			K.bodyPose(b, "OHYank", 0.08)
			if not K.hold(b, 0.45) then
				return
			end
		end
		K.recover(b, 0.9)
	end)

	-- 3. THE GUILLOTINE: a string strung pillar to pillar along one side of the sand, and drawn right across it to the
	-- other side; then back
	add("Guillotine", false, 0, 90, "a string pillar to pillar, swept across the whole sand and back", function(b, tchar)
		local A = K.arena()
		b.hum:MoveTo(b.root.Position)
		K.shift(b, tchar, 10, K.either())
		K.bodyPose(b, "OHRear", 0.4)
		K.flare(b)
		local a = K.rand(0, math.pi * 2)
		local n = V3(math.cos(a), 0, math.sin(a)) -- (the way it travels)
		local along = V3(-n.Z, 0, n.X)
		local R = 43
		local c = A.Centre + V3(0, 3.2, 0)
		local function ends(s)
			local half = math.sqrt(math.max(R * R - s * s, 1))
			return c + n * s - along * half, c + n * s + along * half
		end
		local p1, p2 = ends(-40)
		local line = K.strand(p1, p2, 0.3, 0.5)
		Debris:AddItem(line, 9)
		K.burst(p1, K.VIOLET, 10, 0.3, 10)
		K.burst(p2, K.VIOLET, 10, 0.3, 10)
		K.playSound(b.root, K.SOUNDS.Unsheath, 0.8, 0.6)
		local ok = K.hold(b, 0.9)
		for pass = 1, 2 do
			if not ok then
				break
			end
			K.bodyPose(b, pass == 1 and "OHYank" or "OHCast", 0.15)
			K.playSound(b.root, K.SOUNDS.Lunge, 1, 1.0)
			line.Color, line.Transparency = K.PALE, 0.05
			local from, to = pass == 1 and -40 or 40, pass == 1 and 40 or -40
			local t0, was, seen = K.now(), {}, {}
			while K.live(b) do
				local k = math.min((K.now() - t0) / 1.5, 1)
				local s = from + (to - from) * k
				p1, p2 = ends(s)
				line.Size, line.CFrame = V3(0.45, 0.45, (p2 - p1).Magnitude), CFrame.lookAt((p1 + p2) / 2, p2)
				for pl, hrp in pairs(K.everyone()) do
					local ahead = (hrp.Position - c):Dot(n) > s
					if was[pl] ~= nil and was[pl] ~= ahead then
						K.hitOnce({ pl }, seen, 24, hrp.Position - n * (to - from), "Large")
					end
					was[pl] = ahead
				end
				if k >= 1 then
					break
				end
				RunService.Heartbeat:Wait()
			end
			line.Color, line.Transparency = K.VIOLET, 0.5
			ok = K.hold(b, 0.5)
		end
		line:Destroy()
		if ok then
			K.recover(b, 0.8)
		end
	end)

	-- 4. THE BURROW: down into a pool of her own rot, and gone; pools open under you one after another, a hand up out
	-- of each - and out of the last of them, her
	add("Burrow", false, 0, 90, "she sinks into the sand, hands come up under you, then she does", function(b, tchar)
		local tr = tchar:FindFirstChild("HumanoidRootPart")
		local root = b.root
		b.hum:MoveTo(root.Position)
		K.bodyPose(b, "OHSlam", 0.3)
		K.flare(b)
		local pool = K.mark(root.Position, 6, 0.5)
		if not K.hold(b, 0.55) then
			K.unmark(pool)
			return
		end
		root.Anchored = true
		local top = root.CFrame
		local t0 = K.now()
		while K.live(b) do
			local k = math.min((K.now() - t0) / 0.45, 1)
			root.CFrame = top - V3(0, 22 * k * k, 0)
			if k >= 1 then
				break
			end
			RunService.Heartbeat:Wait()
		end
		K.unmark(pool)
		K.dustCloud(K.ground(top.Position), 4, 14)
		local at = K.ground(top.Position)
		for i = 1, 3 do
			if not K.live(b) then
				return
			end
			at = K.ground(tr.Position + K.flat(tr.AssemblyLinearVelocity) * 0.25)
			local last = i == 3
			local radius = last and 8 or 5
			local p = K.mark(at, radius, 0.6, true)
			K.playSound(p[1], K.SOUNDS.Lunge, 0.8, 0.3)
			task.wait(0.6)
			K.unmark(p)
			if not K.live(b) then
				return
			end
			K.erupt(at, radius, not last)
			K.hitOnce(K.playersInRadius(at, radius, 8), {}, last and 34 or 20, at, "Launch")
			K.shake(at, last and 1.4 or 0.7)
			if not last then
				task.wait(0.25)
			end
		end
		-- up out of the last of them
		local up = V3(at.X, K.standY(b), at.Z)
		local face = unit(tr.Position - up, facing(b))
		K.bodyPose(b, "OHRear", 0.1)
		K.tremor(0.8)
		t0 = K.now()
		while K.live(b) do
			local k = math.min((K.now() - t0) / 0.3, 1)
			local p = up + V3(0, -20 * (1 - k) ^ 2 + 5 * math.sin(k * math.pi), 0)
			root.CFrame = CFrame.lookAt(p, p + face)
			if k >= 1 then
				break
			end
			RunService.Heartbeat:Wait()
		end
		if K.live(b) then
			root.Anchored = false
			K.bodyPose(b, "OHSlamUp", 0.5)
			K.recover(b, 1.4)
		end
	end)

	-- 5. THE CARTWHEEL: three wheeling hops, side to side across you and closer each time, a talon out of every landing
	add("Cartwheel", false, 8, 90, "three wheeling hops side to side at you, a stab out of each", function(b, tchar)
		local tr = tchar:FindFirstChild("HumanoidRootPart")
		b.hum:MoveTo(b.root.Position)
		K.flare(b)
		local way = K.either()
		for i = 1, 3 do
			local from = b.root.Position
			local rel = K.flat(from - tr.Position)
			local out = unit(rel, V3(1, 0, 0))
			local side = V3(-out.Z, 0, out.X) * way
			local to = K.clampToArena(b, tr.Position + out * math.max(rel.Magnitude * 0.55, 9) + side * 8)
			K.bodyPose(b, "OHSplay", 0.12)
			K.playSound(b.root, K.SOUNDS.Lunge, 0.8, 0.9 + i * 0.1)
			K.flight(b, from, to, 0.42, 4, function(t)
				b.root.CFrame *= CFrame.Angles(0, 0, way * t * math.pi * 2)
			end)
			if not K.live(b) then
				return
			end
			local dir = unit(tr.Position - to, facing(b))
			b.root.CFrame = CFrame.lookAt(to, to + dir)
			K.dustCloud(K.ground(to), 2, 6)
			if not K.cut1(b, tchar, i % 2 == 1 and "R" or "L", 0.42, 6, 13, 55, 18) then
				return
			end
			way = -way
		end
		K.recover(b, 1.2)
	end)

	-- 6. THE SCREAM: reared right back, every flame of her flaring - and a ring of it out from her across the whole
	-- sand, throwing off its feet whoever it goes over
	add("Scream", false, 0, 90, "a ring bursts out from her over the whole sand", function(b, tchar)
		b.hum:MoveTo(b.root.Position)
		K.bodyPose(b, "OHUnfurl", 0.5)
		K.flare(b)
		K.playSound(b.root, K.SOUNDS.Groan, 1, 0.8)
		local c = K.ground(b.root.Position) + V3(0, 0.15, 0)
		local pool = K.mark(c, 5, 0.8)
		local ok = K.hold(b, 0.85)
		K.unmark(pool)
		if not ok then
			return
		end
		K.bodyPose(b, "OHBare", 0.1)
		K.shake(c, 1.3)
		K.tremor(1)
		K.dustCloud(c, 8, 26)
		ring(b, c, 3, 86, 0, 1.3, 18, "Knockdown")
		K.recover(b, 0.9)
	end)

	-- 7. (phase 3) THE CLAP: the great hands flung out wide either side of you, low - and brought together on you
	add("Clap", true, 0, 20, "the great hands out either side of you, then clapped shut on you", function(b, tchar)
		local tr = tchar:FindFirstChild("HumanoidRootPart")
		b.hum:MoveTo(b.root.Position)
		K.shift(b, tchar, 12, 0)
		K.bodyPose(b, "OHLoom", 0.3)
		K.flare(b)
		local rel = K.flat(tr.Position - b.root.Position)
		local dir = unit(rel, facing(b))
		local right = V3(-dir.Z, 0, dir.X)
		local zone = K.ground(b.root.Position + dir * math.clamp(rel.Magnitude, 7, 14))
		for _, s in ipairs({ -1, 1 }) do
			K.handTo(b, s, zone + right * s * 12 + V3(0, 2.5, 0), 0.6, false, -0.4)
		end
		local lines = { K.strand(zone - right * 12 + V3(0, 0.15, 0), zone + right * 12 + V3(0, 0.15, 0), 0.3, 0.55) }
		local pool = K.mark(zone, 7, 0.95 * K.tempo())
		local ok = K.hold(b, 0.95)
		K.unmark(pool)
		for _, l in ipairs(lines) do
			K.pluck(l, 5)
		end
		if not ok then
			K.handTo(b, 0, "Loom", 0.5)
			return
		end
		for _, s in ipairs({ -1, 1 }) do
			K.handTo(b, s, zone + right * s * 1.5 + V3(0, 2.5, 0), 0.13, true, 0.9)
		end
		task.wait(0.13)
		if not K.live(b) then
			return
		end
		local seen = {}
		K.hitOnce(K.playersInRadius(zone, 7, 8), seen, 44, zone - dir * 3, "Launch")
		K.cut(zone - right * 12, right, 24, 3.2, seen, 44, "Launch")
		K.shockwave(zone, 7)
		K.erupt(zone, 5)
		K.playSound(b.root, K.SOUNDS.WatchdogSmash, 1, 0.45)
		K.shake(zone, 1.6)
		K.tremor(1)
		ok = K.hold(b, 0.5)
		K.handTo(b, 0, "Loom", 0.6)
		if ok then
			K.recover(b, 1.2)
		end
	end)

	-- 8. (phase 3) THE SPOKES: six strings out of her to the colonnade, a wheel of them, and she turns it: each comes
	-- round the sand to you in its turn
	add("Spokes", true, 0, 90, "six strings out from her like a wheel's spokes, turned round the sand", function(b, tchar)
		local root = b.root
		b.hum:MoveTo(root.Position)
		K.bodyPose(b, "OHHang", 0.5)
		K.handTo(b, 0, "Sky", 0.6)
		K.flareStrings(true)
		K.flare(b)
		local c = K.ground(root.Position) + V3(0, 0.15, 0)
		local N, LEN = 6, 86
		local a0 = K.rand(0, math.pi * 2)
		local way = K.either()
		local spokes = {}
		local function place(th)
			for i = 1, N do
				local a = th + i / N * math.pi * 2
				local d = V3(math.cos(a), 0, math.sin(a))
				spokes[i].CFrame = CFrame.lookAt(c + d * (4 + LEN / 2), c + d * 500)
			end
		end
		for i = 1, N do
			spokes[i] = K.strand(c, c + V3(0, 0, LEN), 0.3, 0.55)
			Debris:AddItem(spokes[i], 8)
		end
		place(a0)
		K.playSound(root, K.SOUNDS.Unsheath, 0.9, 0.5)
		local ok = K.hold(b, 1.0)
		if ok then
			for _, s in ipairs(spokes) do
				s.Color, s.Transparency, s.Size = K.PALE, 0.05, V3(0.5, 0.5, LEN)
			end
			K.playSound(root, K.SOUNDS.Lunge, 1, 0.9)
			root.Anchored = true
			local cf0, t0, seen, last = root.CFrame, K.now(), {}, {}
			local DUR, TURN = 3.4, math.pi * 1.15
			while K.live(b) do
				local k = math.min((K.now() - t0) / DUR, 1)
				local th = a0 + way * TURN * K.smooth(k)
				place(th)
				root.CFrame = cf0 * CFrame.Angles(0, -way * TURN * K.smooth(k), 0)
				for pl, hrp in pairs(K.everyone()) do
					local rel = K.flat(hrp.Position - c)
					-- (which gap between two spokes you're in: when that changes, one's gone over you)
					local gap = math.floor(((math.atan2(rel.Z, rel.X) - th) / (math.pi * 2 / N)) % N)
					if last[pl] ~= nil and last[pl] ~= gap and rel.Magnitude > 4 and rel.Magnitude < LEN then
						if K.damagePlayer(pl, 22, hrp.Position, "Medium") then
							seen[pl] = true
						end
					end
					last[pl] = gap
				end
				if k >= 1 then
					break
				end
				RunService.Heartbeat:Wait()
			end
			root.CFrame = cf0 * CFrame.Angles(0, -way * TURN, 0)
			if K.live(b) then
				root.Anchored = false
			end
		end
		for _, s in ipairs(spokes) do
			K.pluck(s, 0.5)
		end
		K.flareStrings(false)
		K.handTo(b, 0, "Loom", 0.6)
		if ok then
			K.recover(b, 1.3)
		end
	end, { w = 5, cd = 7 }) -- (PROMOTED: one of her common ones in phase 3)

	---------------------------------------------------------------------------
	-- THE SECOND BATCH
	---------------------------------------------------------------------------
	local Core = K.Core
	local Players = game:GetService("Players")
	local C3 = Color3.fromRGB
	local BONE = C3(196, 188, 176)
	local function rolling(pl) -- (in a roll's invulnerability, this instant)
		local st = Core.states[pl]
		local t = K.now()
		return st ~= nil and t >= st.iStart and t <= st.iEnd
	end
	local function att(parent, pos)
		local a = Instance.new("Attachment")
		if pos then
			a.Position = pos
		end
		a.Parent = parent
		return a
	end
	local function beam(a0, a1, w) -- a lit string between two attachments (it goes when a0 does)
		local bm = Instance.new("Beam")
		bm.Attachment0, bm.Attachment1 = a0, a1
		bm.Width0, bm.Width1, bm.Segments, bm.FaceCamera = w, w, 1, true
		bm.Color = ColorSequence.new(K.PALE, K.VIOLET)
		bm.LightEmission, bm.Transparency = 0.7, NumberSequence.new(0.15)
		bm.Parent = a0
		return bm
	end
	local function sink(b) -- down into the sand where she stands, and held there (anchored): where she went down
		local root = b.root
		root.Anchored = true
		local top, t0 = root.CFrame, K.now()
		while K.live(b) do
			local k = math.min((K.now() - t0) / 0.45, 1)
			root.CFrame = top - V3(0, 22 * k * k, 0)
			if k >= 1 then
				break
			end
			RunService.Heartbeat:Wait()
		end
		K.dustCloud(K.ground(top.Position), 4, 14)
		return top
	end
	local function glide(b, from, to, dur, face, ease) -- carried (anchored) from one spot to another, facing `face`
		local t0 = K.now()
		while K.live(b) do
			local k = math.min((K.now() - t0) / dur, 1)
			local p = from:Lerp(to, ease == "in" and k * k or K.smooth(k))
			b.root.CFrame = CFrame.lookAt(p, p + face)
			if k >= 1 then
				break
			end
			RunService.Heartbeat:Wait()
		end
	end
	local function land(b, at, radius, damage) -- something of hers come down hard on the sand at `at`
		K.hitOnce(K.playersInRadius(at, radius, 8), {}, damage, at, "Launch")
		K.shockwave(at, radius)
		K.erupt(at, radius * 0.6)
		K.playSound(b.root, K.SOUNDS.WatchdogSmash, 1, 0.5)
		K.shake(at, 1.3)
		K.tremor(0.8)
	end

	-- 9. PUPPET STRINGS: four of her strings onto you, and you're drawn across the sand to her, slowly, for three
	-- seconds - roll, and they snap (and she reels); let them bring you in, and her talons come down
	add("Puppet", false, 12, 90, "strings on your limbs drag you to her - roll to snap them", function(b, tchar)
		local tr = tchar:FindFirstChild("HumanoidRootPart")
		local pl = Players:GetPlayerFromCharacter(tchar)
		local hands = { b.model:FindFirstChild("RHand"), b.model:FindFirstChild("LHand") }
		if not (pl and hands[1] and hands[2]) then
			return
		end
		b.hum:MoveTo(b.root.Position)
		K.bodyPose(b, "OHUnfurl", 0.3)
		K.flare(b)
		if not K.hold(b, 0.7, tchar, 1.5) then
			return
		end
		if rolling(pl) then -- (rolled as they came: they never caught)
			K.bodyPose(b, "OHYank", 0.1)
			K.recover(b, 1.0)
			return
		end
		local made = {}
		for i, h in ipairs(hands) do
			for j = 1, 2 do
				local a0, a1 = att(h), att(tr, V3((i - 1.5) * 1.6, (j - 1.5) * 2.4, 0))
				table.insert(made, a0)
				table.insert(made, a1)
				beam(a0, a1, 0.1)
			end
		end
		K.playSound(tr, K.SOUNDS.Unsheath, 0.8, 1.8)
		K.burst(tr.Position, K.VIOLET, 14, 0.3, 10)
		K.bodyPose(b, "OHCast", 0.3)
		local t0, snapped, nextPull = K.now(), false, 0
		while K.free(b) and K.now() - t0 < 3 do
			if rolling(pl) or not tr.Parent then
				snapped = true
				break
			end
			local rel = K.flat(b.root.Position - tr.Position)
			if rel.Magnitude < 9 then
				break
			end
			if K.now() >= nextPull then
				nextPull = K.now() + 0.25
				Core.FxRemote:FireClient(pl, "Shove", rel.Unit, 26)
			end
			K.turnTowards(b.root, tr.Position, math.rad(240) * task.wait())
		end
		for _, a in ipairs(made) do
			a:Destroy()
		end
		if snapped then
			K.burst(tr.Position, K.PALE, 16, 0.35, 14)
			K.bodyPose(b, "Stagger", 0.15)
			K.recover(b, 1.4)
		elseif K.free(b) and K.slam(b, tchar, 0.5) then
			K.recover(b, 1.0)
		end
	end)

	-- 10. THE STITCH: a zigzag of her string sewn across the sand from her to you and on past, stitch after stitch,
	-- each drawn taut a moment after it's laid
	add("Stitch", false, 8, 90, "a zigzag of string sewn across the sand at you, each stitch snapping in turn", function(b, tchar)
		local tr = tchar:FindFirstChild("HumanoidRootPart")
		b.hum:MoveTo(b.root.Position)
		K.shift(b, tchar, 9, K.either())
		K.bodyPose(b, "OHCast", 0.25)
		K.flare(b, "R")
		if not K.hold(b, 0.4, tchar, 2) then
			return
		end
		local o = K.ground(b.root.Position) + V3(0, 0.15, 0)
		local dir = unit(tr.Position - o, facing(b))
		local side = V3(-dir.Z, 0, dir.X)
		local n = math.clamp(math.floor(K.flat(tr.Position - o).Magnitude / 6) + 3, 5, 11)
		local prev = o + dir * 3
		for i = 1, n do
			local a, to = prev, o + dir * (3 + i * 6) + side * (i % 2 == 0 and 6 or -6)
			local line = K.strand(a, to, 0.22, 0.5)
			Debris:AddItem(line, 3)
			task.delay(0.6, function()
				if K.live(b) then
					K.cut(a, (to - a).Unit, (to - a).Magnitude, 1.5, {}, 18, "Medium")
				end
				K.pluck(line, 1.2)
			end)
			prev = to
			K.bodyPose(b, i % 2 == 0 and "OHCastL" or "OHCast", 0.1)
			if not K.hold(b, 0.1) then
				return
			end
		end
		K.bodyPose(b, "OHYank", 0.1)
		K.recover(b, 1.2)
	end)

	-- 11. THE TETHER: a string from the nearest pillar onto you, and short: stray past its reach and you're wrenched
	-- back in toward the pillar - for six seconds, while she comes at you
	add("Tether", false, 0, 90, "ties you to a pillar - stray past its reach and you're yanked back, while she comes", function(b, tchar)
		local tr = tchar:FindFirstChild("HumanoidRootPart")
		local pl = Players:GetPlayerFromCharacter(tchar)
		if not pl then
			return
		end
		b.hum:MoveTo(b.root.Position)
		K.bodyPose(b, "OHCast", 0.25)
		K.flare(b, "R")
		if not K.hold(b, 0.6, tchar, 1.5) then
			return
		end
		K.bodyPose(b, "OHYank", 0.1)
		if rolling(pl) then
			K.recover(b, 0.8)
			return
		end
		local rel = K.flat(tr.Position - K.arena().Centre)
		local post = K.pillar(math.floor(math.atan2(rel.Z, rel.X) / (math.pi * 2) * K.PILLARS + 0.5), 8)
		local reach = math.clamp(K.flat(tr.Position - post).Magnitude * 0.75, 12, 22)
		local a0, a1 = att(workspace.Terrain, post), att(tr)
		beam(a0, a1, 0.14)
		K.burst(post, K.VIOLET, 12, 0.3, 10)
		K.playSound(tr, K.SOUNDS.Unsheath, 0.8, 1.6)
		local over = K.now() + 6
		task.spawn(function()
			local nextYank = 0
			while K.live(b) and K.now() < over and tr.Parent do
				local out = K.flat(tr.Position - post)
				if out.Magnitude > reach and K.now() >= nextYank then
					nextYank = K.now() + 0.7
					K.damagePlayer(pl, 6, tr.Position + out.Unit * 4, "Medium", math.clamp((out.Magnitude - reach + 4) * 7, 20, 200))
				end
				task.wait(0.1)
			end
			a0:Destroy()
			a1:Destroy()
		end)
		for _, m in ipairs(K.MOVES) do -- (and while you're on it: her rake)
			if m.name == "Rake" then
				m.fn(b, tchar)
			end
		end
	end)

	-- 12. THE SHADOW: down into the sand; three pools open round you, and she comes up out of one of them, onto you
	add("Shadow", false, 0, 90, "three pools open round you, she leaps out of one of them", function(b, tchar)
		local tr = tchar:FindFirstChild("HumanoidRootPart")
		b.hum:MoveTo(b.root.Position)
		K.bodyPose(b, "OHSlam", 0.3)
		K.flare(b)
		local own = K.mark(b.root.Position, 6, 0.5)
		local ok = K.hold(b, 0.55)
		K.unmark(own)
		if not ok then
			return
		end
		sink(b)
		local c, a0, pools = tr.Position, K.rand(0, math.pi * 2), {}
		for i = 1, 3 do
			local a = a0 + i * math.pi * 2 / 3
			local at = K.ground(K.clampToArena(b, c + V3(math.cos(a), 0, math.sin(a)) * 13))
			pools[i] = { at = at, parts = K.mark(at, 6, 0.9, true) }
		end
		task.wait(0.9 + K.rand(0, 0.5))
		local pick = pools[math.random(3)]
		for _, p in ipairs(pools) do
			K.unmark(p.parts)
			if p ~= pick and K.live(b) then
				K.erupt(p.at, 4)
			end
		end
		if not K.live(b) then
			return
		end
		local to = K.clampToArena(b, tr.Position)
		local pool = K.mark(to, F.PounceRadius, 0.7)
		K.erupt(pick.at, 6)
		K.playSound(b.root, K.SOUNDS.Lunge, 1, 0.5)
		K.leap(b, V3(pick.at.X, K.standY(b) - 14, pick.at.Z), to, 0.7, 12)
		K.unmark(pool)
		if not K.live(b) then
			return
		end
		K.bodyPose(b, "OHLand", 0.08)
		land(b, K.ground(b.root.Position), F.PounceRadius, F.PounceDamage)
		K.recover(b, 1.3)
	end)

	-- 13. THE HANG: hauled up out of reach on one string; she drifts over you up there, as long as she likes - and drops
	add("Hang", false, 0, 90, "hauled up out of reach on a string, drifts over you, then drops", function(b, tchar)
		local tr = tchar:FindFirstChild("HumanoidRootPart")
		local root = b.root
		b.hum:MoveTo(root.Position)
		K.bodyPose(b, "OHHang", 0.4)
		K.flare(b)
		root.Anchored = true
		local face = facing(b)
		local a0, a1 = att(root, V3(0, 2 * b.scale, 0)), att(workspace.Terrain, root.Position + V3(0, 160, 0))
		beam(a0, a1, 0.16)
		K.playSound(root, K.SOUNDS.Unsheath, 0.9, 0.6)
		local base = K.standY(b)
		glide(b, root.Position, V3(root.Position.X, base + 20, root.Position.Z), 0.6, face)
		local t0, T = K.now(), K.rand(1.2, 2.2)
		while K.live(b) and K.now() - t0 < T do -- over you, wherever you go
			local dt = RunService.Heartbeat:Wait()
			local p = root.Position
			local want = K.flat(tr.Position - p)
			local step = want.Magnitude > 0.1 and want.Unit * math.min(want.Magnitude, 18 * dt) or Vector3.zero
			p = V3(p.X + step.X, base + 20 + math.sin(K.now() * 2) * 0.6, p.Z + step.Z)
			root.CFrame = CFrame.lookAt(p, p + face)
			a1.Position = V3(p.X, p.Y + 140, p.Z)
		end
		local at = K.ground(root.Position)
		local pool = K.mark(at, 8, 0.45)
		K.bodyPose(b, "OHPierce", 0.2)
		task.wait(0.45)
		a0:Destroy()
		a1:Destroy()
		glide(b, root.Position, V3(at.X, base, at.Z), 0.22, face, "in")
		K.unmark(pool)
		if not K.live(b) then
			return
		end
		root.Anchored = false
		K.bodyPose(b, "OHLand", 0.08)
		land(b, at, 8, 36)
		K.recover(b, 1.4)
	end)

	-- 14. THE FINGERS: her talons sunk in the sand, and fingers stab up out of it under you, one after another,
	-- wherever you go - each on a small pool, half a second after it shows
	add("Fingers", false, 0, 90, "fingers stab up out of the sand under you, one after another, wherever you go", function(b, tchar)
		local tr = tchar:FindFirstChild("HumanoidRootPart")
		b.hum:MoveTo(b.root.Position)
		K.shift(b, tchar, 10, K.either())
		K.bodyPose(b, "OHSlam", 0.3)
		K.flare(b)
		if not K.hold(b, 0.5) then
			return
		end
		for _ = 1, 9 do
			local c = K.ground(tr.Position + K.flat(tr.AssemblyLinearVelocity) * 0.35)
			local parts = K.mark(c, 3.2, 0.5)
			task.delay(0.5, function()
				if K.live(b) then
					K.erupt(c, 3.2, true)
					K.hitOnce(K.playersInRadius(c, 3.2, 6), {}, 14, c, "Medium")
				end
				K.unmark(parts)
			end)
			if not K.hold(b, 0.28) then
				return
			end
		end
		K.recover(b, 1.0)
	end)

	-- 15. (phase 3) THE JUGGLE: a great hand tosses a stone up, and bats it at you; the other hand, another; and a third
	add("Juggle", true, 10, 90, "the great hands toss three stones up and bat them at you", function(b, tchar)
		local tr = tchar:FindFirstChild("HumanoidRootPart")
		local root = b.root
		b.hum:MoveTo(root.Position)
		K.bodyPose(b, "OHLoom", 0.3)
		K.flare(b)
		for i = 1, 3 do
			local sx = i % 2 == 1 and 1 or -1
			local held = root.Position + unit(root.CFrame.RightVector, V3(1, 0, 0)) * sx * 9 + V3(0, 6, 0)
			local rock = K.wreck(3.5, 5.5)
			rock.Anchored = true
			rock.CFrame = CFrame.new(held)
			rock.Parent = workspace
			K.handTo(b, sx, held - V3(0, 1.5, 0), 0.15, false, 0.6)
			TweenService:Create(rock, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = CFrame.new(held + V3(0, 14, 0)) * CFrame.Angles(3, 2, 1) }):Play()
			K.handTo(b, sx, "Rear", 0.4)
			if not K.hold(b, 0.5, tchar, 1) then
				rock:Destroy()
				K.handTo(b, 0, "Loom", 0.5)
				return
			end
			K.handTo(b, sx, held + V3(0, 12, 0), 0.08, true, -0.3)
			K.playSound(root, K.SOUNDS.Lunge, 1, 0.9)
			K.rubble(b, tr.Position + K.flat(tr.AssemblyLinearVelocity) * 0.3, rock, 0.5, 5.5, 28)
			if not K.hold(b, 0.2) then
				return
			end
		end
		K.handTo(b, 0, "Loom", 0.6)
		K.recover(b, 1.2)
	end)

	-- 16. (phase 3) THE GRASP: a great hand held open over you, and brought down to take you: caught, you're lifted
	-- off the sand in it and thrown; missed, it's left planted there a moment
	add("Grasp", true, 0, 20, "a great hand comes down to take you - caught, you're lifted and thrown", function(b, tchar)
		local tr = tchar:FindFirstChild("HumanoidRootPart")
		local root = b.root
		b.hum:MoveTo(root.Position)
		K.shift(b, tchar, 12, 0)
		K.bodyPose(b, "OHLoom", 0.3)
		K.flare(b)
		local sx = K.either()
		local rel = K.flat(tr.Position - root.Position)
		local dir = unit(rel, facing(b))
		local zone = K.ground(root.Position + dir * math.clamp(rel.Magnitude, 6, 14))
		K.handTo(b, sx, zone + V3(0, 11, 0), 0.5, false, -0.4)
		local pool = K.mark(zone, 4.5, 0.75 * K.tempo())
		local ok = K.hold(b, 0.75, tchar, 0.3)
		K.unmark(pool)
		if not ok then
			K.handTo(b, 0, "Loom", 0.5)
			return
		end
		K.handTo(b, sx, zone + V3(0, 1.5, 0), 0.1, true, 0.9)
		task.wait(0.1)
		if not K.live(b) then
			return
		end
		K.shake(zone, 0.8)
		K.dustCloud(zone, 3, 8)
		local caught
		for _, p in ipairs(K.playersInRadius(zone, 4.5, 8)) do
			if not caught and K.damagePlayer(p, 10, zone, "Grabbed") then
				caught = p
			end
		end
		local st = caught and Core.states[caught]
		local hrp = caught and caught.Character and caught.Character:FindFirstChild("HumanoidRootPart")
		if st and hrp then
			local DUR = 1.0
			Core.setAction(st, K.now(), DUR, DUR, DUR)
			Core.cancelSwing(st)
			Core.FxRemote:FireClient(caught, "Grabbed", DUR)
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.Anchored = true
			local from, to = hrp.Position, root.Position + dir * 7 + V3(0, 9, 0)
			K.handTo(b, sx, to + V3(0, 1.5, 0), DUR * 0.8, false, 0.9)
			local t0 = K.now()
			while K.live(b) and hrp.Parent do
				local k = math.min((K.now() - t0) / (DUR * 0.8), 1)
				hrp.CFrame = CFrame.new(from:Lerp(to, K.smooth(k))) * hrp.CFrame.Rotation
				if k >= 1 then
					break
				end
				RunService.Heartbeat:Wait()
			end
			task.wait(DUR * 0.2)
			if hrp.Parent then -- (let go of, whatever's become of her meanwhile)
				hrp.Anchored = false
				pcall(function()
					hrp:SetNetworkOwner(caught)
				end)
				K.damagePlayer(caught, 26, root.Position, "Launch")
			end
			K.handTo(b, sx, zone + dir * 10 + V3(0, 6, 0), 0.12, true, -0.4)
			K.hold(b, 0.5)
		else
			K.hold(b, 0.8)
		end
		K.handTo(b, 0, "Loom", 0.6)
		K.recover(b, 1.2)
	end)

	-- 17. (phase 3) THE CAGE: the great hands come down either side of you and bars of bone come up round you (they're
	-- solid: be out before they're up, or roll through what bursts inside them)
	add("Cage", true, 0, 22, "bars of bone come up round you, and what's inside them bursts", function(b, tchar)
		local tr = tchar:FindFirstChild("HumanoidRootPart")
		local root = b.root
		b.hum:MoveTo(root.Position)
		K.shift(b, tchar, 12, 0)
		K.bodyPose(b, "OHLoom", 0.3)
		K.flare(b)
		local c = K.ground(tr.Position)
		K.handTo(b, 0, "Rear", 0.6)
		local pool = K.mark(c, 7, 0.8 * K.tempo())
		local ok = K.hold(b, 0.8)
		K.unmark(pool)
		if not ok then
			K.handTo(b, 0, "Loom", 0.5)
			return
		end
		local right = unit(root.CFrame.RightVector, V3(1, 0, 0))
		for _, s in ipairs({ -1, 1 }) do
			K.handTo(b, s, c + right * s * 7 + V3(0, 1.5, 0), 0.12, true, 0.2)
		end
		local bars = {}
		for i = 1, 12 do
			local a = i / 12 * math.pi * 2
			local at = c + V3(math.cos(a), 0, math.sin(a)) * 7
			local p = Instance.new("Part")
			p.Name, p.Size, p.Color, p.Material = "CageBar", V3(0.5, 11, 0.5), BONE, Enum.Material.SmoothPlastic
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, true, false, false
			p.CFrame = CFrame.new(at - V3(0, 6, 0))
			p.Parent = workspace
			TweenService:Create(p, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = CFrame.new(at + V3(0, 5, 0)) * CFrame.Angles(K.rand(-0.12, 0.12), 0, K.rand(-0.12, 0.12)) }):Play()
			Debris:AddItem(p, 4)
			bars[i] = p
		end
		K.playSound(root, K.SOUNDS.WatchdogSmash, 1, 0.55)
		K.shake(c, 1.2)
		K.tremor(0.6)
		local fill = K.mark(c, 6.5, 1.1, true)
		K.hold(b, 1.1)
		K.unmark(fill)
		for _, p in ipairs(bars) do
			p.CanCollide = false
			TweenService:Create(p, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = p.CFrame - V3(0, 12, 0) }):Play()
		end
		if K.live(b) then
			K.erupt(c, 6.5, true)
			K.hitOnce(K.playersInRadius(c, 6.5, 8), {}, 40, c, "Launch")
			K.shake(c, 1.4)
		end
		K.handTo(b, 0, "Loom", 0.6)
		K.recover(b, 1.3)
	end)

	-- 18. (phase 3) THE PENDULUM: she swings on her own strings, low across the sand through where you stand, and up
	-- the far side; and back through you; and again. A line on the sand shows each swing's way first
	add("Pendulum", true, 0, 90, "she swings on her strings low through you, three times", function(b, tchar)
		local tr = tchar:FindFirstChild("HumanoidRootPart")
		local root = b.root
		b.hum:MoveTo(root.Position)
		K.bodyPose(b, "OHHang", 0.4)
		K.handTo(b, 0, "Sky", 0.5)
		K.flareStrings(true)
		K.flare(b)
		root.Anchored = true
		local base = K.standY(b)
		local dir = facing(b)
		for _ = 1, 3 do
			local from = root.Position
			local through = K.ground(tr.Position)
			dir = unit(through - from, dir)
			local to = K.clampToArena(b, through + dir * 26)
			local line = K.strand(K.ground(from) + V3(0, 0.15, 0), K.ground(to) + V3(0, 0.15, 0), 0.3, 0.55)
			Debris:AddItem(line, 3)
			local top = V3(from.X, base + 9, from.Z) - dir * 4
			glide(b, from, top, 0.5, dir) -- (hauled up and back first: that's the warning)
			if not K.live(b) then
				return
			end
			K.pluck(line, 1.5)
			K.bodyPose(b, "OHPierce", 0.15)
			K.playSound(root, K.SOUNDS.Lunge, 1, 0.7)
			local seen, t0 = {}, K.now()
			while K.live(b) do
				local u = math.min((K.now() - t0) / 0.85, 1)
				local p = top:Lerp(V3(to.X, top.Y, to.Z), u)
				p = V3(p.X, base + 0.5 + (top.Y - base) * (2 * u - 1) ^ 2, p.Z)
				root.CFrame = CFrame.lookAt(p, p + dir) * CFrame.Angles(-0.6 + 1.2 * u, 0, 0)
				K.hitOnce(K.playersInRadius(K.ground(p), 5, 8), seen, 24, p - dir * 4, "Large")
				if u >= 1 then
					break
				end
				RunService.Heartbeat:Wait()
			end
			K.bodyPose(b, "OHHang", 0.2)
			if not K.live(b) then
				return
			end
			task.wait(0.25)
		end
		local p = root.Position
		glide(b, p, V3(p.X, base, p.Z), 0.3, dir)
		K.flareStrings(false)
		K.handTo(b, 0, "Loom", 0.6)
		if K.live(b) then
			root.Anchored = false
			K.recover(b, 1.4)
		end
	end)

	-- 19. (phase 3) THE ECLIPSE: the great wheel behind her head comes off it, and rolls: out across the sand through
	-- you to the colonnade, and back from there through wherever you've got to. A line shows each run of it first
	add("Eclipse", true, 0, 90, "the wheel behind her head comes off and rolls across the sand, and back", function(b, tchar)
		local tr = tchar:FindFirstChild("HumanoidRootPart")
		local root = b.root
		b.hum:MoveTo(root.Position)
		K.bodyPose(b, "OHRear", 0.4)
		K.flare(b)
		local own = {} -- (her own wheel: off her while this one's out)
		for _, p in ipairs(b.model:GetChildren()) do
			if p.Name == "WheelRim" or p.Name == "WheelSpike" or p.Name == "WheelMote" then
				table.insert(own, p)
			end
		end
		local R = 6.5
		local o = K.ground(root.Position)
		local dir = unit(tr.Position - o, facing(b))
		local far = K.ground(K.clampToArena(b, o + dir * 90))
		local up = V3(0, 0.15, 0)
		local line = K.strand(o + dir * 4 + up, far + up, 0.3, 0.55)
		Debris:AddItem(line, 4)
		if not K.hold(b, 0.8) then
			line:Destroy()
			return
		end
		for _, p in ipairs(own) do
			p.Transparency = 1
		end
		K.bodyPose(b, "OHSlam", 0.12)
		local disc = Instance.new("Part")
		disc.Name, disc.Shape = "EclipseWheel", Enum.PartType.Cylinder
		disc.Size, disc.Color, disc.Material = V3(0.5, R * 2, R * 2), BONE, Enum.Material.SmoothPlastic
		disc.Anchored, disc.CanCollide, disc.CanQuery, disc.CanTouch = true, false, false, false
		for _, l in ipairs({ { 0.56, R * 2 - 1.4, C3(14, 10, 18), Enum.Material.SmoothPlastic }, { 0.62, 2.2, C3(210, 160, 255), Enum.Material.Neon } }) do
			local p = Instance.new("Part")
			p.Name, p.Shape = "EclipseFace", Enum.PartType.Cylinder
			p.Size, p.Color, p.Material = V3(l[1], l[2], l[2]), l[3], l[4]
			p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, true
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = disc, p
			w.Parent = p
			p.Parent = disc
		end
		disc.CFrame = CFrame.lookAt(o + dir * 4 + V3(0, R, 0), o + dir * 5 + V3(0, R, 0))
		disc.Parent = workspace
		local function run(a, to, dur) -- rolled from a to `to` along the sand
			local seen, t0 = {}, K.now()
			local d = to - a
			local len, u = d.Magnitude, d.Unit
			while K.live(b) do
				local k = math.min((K.now() - t0) / dur, 1)
				local pos = a:Lerp(to, k) + V3(0, R, 0)
				disc.CFrame = CFrame.lookAt(pos, pos + u) * CFrame.Angles(-k * len / R, 0, 0)
				K.hitOnce(K.playersInRadius(K.ground(pos), 2.6, 8), seen, 26, pos - u * 3, "Large")
				if k >= 1 then
					break
				end
				RunService.Heartbeat:Wait()
			end
		end
		K.pluck(line, 1.5)
		K.playSound(root, K.SOUNDS.Lunge, 1, 0.6)
		run(o + dir * 4, far, (far - o).Magnitude / 48)
		K.tremor(0.5)
		K.shake(far, 0.8)
		if K.live(b) then
			local d2 = unit(tr.Position - far, -dir)
			local back = K.ground(K.clampToArena(b, K.ground(tr.Position) + d2 * 40))
			local l2 = K.strand(far + up, back + up, 0.3, 0.55)
			Debris:AddItem(l2, 4)
			task.wait(0.5)
			if K.live(b) then
				K.pluck(l2, 1.5)
				run(far, back, (back - far).Magnitude / 48)
			end
		end
		K.burst(disc.Position, BONE, 30, 0.5, 26)
		disc:Destroy()
		for _, p in ipairs(own) do
			if p.Parent then
				p.Transparency = 0
			end
		end
		K.recover(b, 1.2)
	end)

	return moves
end
