--!nonstrict
-- THE WARDEN, hybrid C: THE LOCKED BELL. The true fusion. Its head is a bell built of cage bars, with a flame shut inside for a
-- clapper, and its great key ends in a bell of its own, so everything the key does now rings. It drives the key into the floor and
-- TURNS it, and the note rolls out from the lock. The floor split ends in a note. The third cut of a run rings where it lands.
-- Phase 2: the flame breaks out, the key burns, the lock turns twice, and the thrown key rings when it comes home.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fight = require(ReplicatedStorage:WaitForChild("WardenFight"))
local Garb = require(ReplicatedStorage:WaitForChild("WardenGarb"))
local Turnkey = require(script.Parent:WaitForChild("WardenTurnkey"))
local Bell = require(script.Parent:WaitForChild("WardenBell"))

local S = 3.5
local K = S / 1.95
local M = {}
M.Kind = "WardenLockedBell"
M.Proportions = { girth = 1.08, arm = 1.25, hunch = 0.18, twoHand = -0.8, walkRef = 2.8, cadence = 0.85 }
M.IdlePose = "TKIdle"
local COAT, COAT_DK, IRON, IRON_DK, FLAME = Color3.fromRGB(46, 50, 46), Color3.fromRGB(28, 30, 28), Color3.fromRGB(70, 68, 66), Color3.fromRGB(38, 36, 36), Color3.fromRGB(166, 220, 226)
M.Colors = { skin = COAT_DK, torso = COAT, legs = COAT_DK, arms = COAT }
M.FistSkin = true

function M.Look(k)
	Bell.LookRobe(k, COAT, COAT_DK)
	Turnkey.LookKeys(k)
	local deco, parts, V, at, MAT = k.deco, k.parts, k.V, k.at, k.MAT
	parts.Head.Transparency = 1
	-- the bell's true shape, in bars you can see through: lip, waist, shoulder
	local radius = Bell.bellRadius
	local heights = { -1.08, -0.92, -0.62, -0.25, 0.25, 0.62, 0.86 }
	local function bar(p, q, thick)
		deco("Head", "BellBar", V(thick, thick, (q - p).Magnitude + 0.06), at((p.X + q.X) / 2, (p.Y + q.Y) / 2, (p.Z + q.Z) / 2) * CFrame.lookAt(Vector3.zero, q - p), IRON, MAT.Metal)
	end
	local N = 16
	local function point(i, y)
		local a = i / N * 2 * math.pi
		return Vector3.new(math.sin(a) * radius(y), y, math.cos(a) * radius(y))
	end
	for i = 0, N - 1 do
		for j = 1, #heights - 1 do
			bar(point(i, heights[j]), point(i, heights[j + 1]), 0.11)
		end
	end
	-- rim, waist and shoulder hoops
	for _, y in ipairs({ -1.08, -0.92, -0.25, 0.62 }) do
		Garb.hoop(k, "Head", y, radius(y), radius(y), 20, y == -1.08 and 0.16 or 0.09, y == -1.08 and IRON or IRON_DK, MAT.Metal, "BellHoop")
	end
	-- the crown, cast solid
	local y = 0.86
	while y < 1.09 do
		Garb.disc(k, "Head", y, radius(y), 0.07, IRON_DK, MAT.Metal, "BellCrown")
		y += 0.05
	end
	Bell.bellHanger(k, IRON, IRON_DK)
	-- the flame, shut in where the clapper would hang
	local flame = deco("Head", "BellFlame", V(0.85, 1.25, 0.85), at(0, 0, 0), FLAME, MAT.Neon, Enum.PartType.Ball)
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows = FLAME, 34, 1.4, false
	light.Parent = flame
end

M.Weapons = {
	-- the great key, with a bell for a bit
	BellKey = function(w)
		local mk, add = w.mk, w.add
		local green, dark = Color3.fromRGB(88, 116, 100), Color3.fromRGB(56, 76, 66)
		local handle = Turnkey.keyShank(w)
		local function ring(name, y, h, d, color)
			local p = mk(name, Vector3.new(h, d, d), color, Enum.Material.Metal)
			p.Shape = Enum.PartType.Cylinder
			add(p, y, Garb.UP)
		end
		-- slices of a small true bell, mouth to the end of the key
		ring("BitLip", -5.95, 0.12, 2.55, green)
		ring("Bit", -5.78, 0.2, 2.2, green)
		ring("BitFlare", -5.56, 0.24, 1.72, dark)
		ring("BitWaist", -5.26, 0.36, 1.42, green)
		ring("BitBand", -5.08, 0.06, 1.5, dark)
		ring("BitWaist2", -4.86, 0.36, 1.32, green)
		ring("BitShoulder", -4.62, 0.14, 1.12, dark)
		ring("BitCrown", -4.5, 0.12, 0.72, green)
		return { handle = handle, bladeLen = 5.6, gripC1 = CFrame.new(0, 1.05 * w.scale, 0) }
	end,
}
local R = math.rad
M.Grips = {
	-- the key in the floor, a quarter turn round
	LBTurned = { Vector3.new(0.3, -0.6, -2.3), CFrame.Angles(R(55), 0, 0) * CFrame.Angles(0, R(90), 0) },
}

function M.init(core)
	local F = Fight.init(core)
	local bl = Bell.moves(core)
	local SOUNDS, playSound, pose, burst, FxRemote = core.SOUNDS, core.playSound, core.pose, core.burst, core.FxRemote
	local function ringAt(b, at, reach)
		bl.bellSound(b, 0.9)
		FxRemote:FireAllClients("Shake", at, 0.5)
		burst(at + Vector3.new(0, 1, 0), bl.NOTE, 18, 0.35, 16)
		F.wave(b, at, 22, reach, bl.NoteDamage, "Medium")
	end

	-- THE LOCK: bent over the key where it's stuck, a slow grind, and it turns: the note rolls out from the floor. You can hit it the
	-- whole time, and you get a long opening afterwards, if you got through the note
	local function turnLock(b, _, at)
		for i = 1, F.phase2() and 2 or 1 do
			playSound(b.root, SOUNDS.Unsheath, 0.9, 0.35)
			if not F.hold(b, 0.8 * F.tempo()) then
				return
			end
			pose(b, i == 1 and "LBTurned" or "TKStuck", 0.16)
			playSound(b.root, SOUNDS.Impact, 0.9, 0.7)
			if not F.hold(b, 0.16) then
				return
			end
			ringAt(b, at, 72)
		end
		F.recover(b, 1.5, "TKHaul")
	end
	local tk = Turnkey.moves(core, K, {
		stuck = turnLock,
		splitEnd = function(b, at)
			ringAt(b, at, 34)
		end,
		onCatch = function(b)
			ringAt(b, core.flat(b.root.Position), 72)
		end,
	})

	-- THE RUN: three cuts, the last of them ringing where it lands
	local function run(b, target)
		F.halt(b)
		if not tk.cut(b, target, "TKShoulder", "TKCutMid", "TKCutEnd", "TKUp", "TKCutThrough", 0.85, 5) or not F.hold(b, 0.2) then
			return
		end
		if not tk.cut(b, target, "TKBackSet", "TKBackMid", "TKBackEnd", "TKBackSet", "TKBackThrough", 0.62, 4) or not F.hold(b, 0.2) then
			return
		end
		if not tk.cut(b, target, "TKShoulder", "TKCutMid", "TKCutEnd", "TKUp", "TKCutThrough", 0.62, 4, "Large") then
			return
		end
		ringAt(b, tk.tipFloor(b), 28)
		F.recover(b, 1.4, "TKHaul")
	end

	Fight.define({
		id = "LockedBell",
		label = "The Locked Bell",
		kind = M.Kind,
		scale = S,
		weapon = "BellKey",
		idleGrip = "TKRest",
		hp = 800,
		poise = 175,
		stagger = 2.7,
		radius = 2.4 * K,
		walk = 10,
		turn = 78,
		rest = { 0.6, 1.3 },
		keep = { 15, 25 },
		phase2At = 0.5,
		tempo2 = 0.88,
		restMult2 = 0.75,
		moves = {
			{ name = "Run", fn = run, min = 0, max = 26, weight = 5, cd = 2.5, fast = true },
			{ name = "Lock", fn = tk.thrust, min = 8, max = 40, weight = 4.5, cd = 6 },
			{ name = "Overhead", fn = tk.overhead, min = 0, max = 38, weight = 3.5, cd = 6 },
			{ name = "Spin", fn = tk.spin, min = 0, max = 22, weight = 2, cd = 7, behind = true },
			{ name = "Toll", fn = bl.toll, min = 16, max = 95, weight = 3.5, cd = 8 },
			{ name = "Hook", fn = tk.hook, min = 38, max = 90, weight = 3, cd = 7 },
			{ name = "ThrowKey", fn = tk.throwKey, min = 20, max = 90, weight = 3, cd = 11, phase2 = true },
		},
		idle = tk.idle,
		onStagger = tk.onStagger,
		intro = bl.intro,
		-- phase 2: the flame breaks out of the bars and the key takes fire from it
		phase2 = function(b)
			local flame = b.model:FindFirstChild("BellFlame")
			if flame then
				local e = Instance.new("Fire")
				e.Size, e.Heat, e.Color, e.SecondaryColor = 12, 8, FLAME, Color3.fromRGB(40, 70, 90)
				e.Parent = flame
			end
			tk.ignite(b)
			bl.phase2(b)
		end,
	})
end

return M
