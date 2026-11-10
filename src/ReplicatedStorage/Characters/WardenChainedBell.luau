--!nonstrict
-- THE WARDEN, hybrid B: THE CHAINED BELL. The Bellhead's body and rhythm, with the Turnkey's chain and keys. It still fights to its
-- count, but you can't simply wait the count out at range any more: the chain drags you in, and the next note goes off right on
-- top of you. Phase 2: the bell cracks, and it throws the clapper, which rings out another note when it comes home.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fight = require(ReplicatedStorage:WaitForChild("WardenFight"))
local Garb = require(ReplicatedStorage:WaitForChild("WardenGarb"))
local Turnkey = require(script.Parent:WaitForChild("WardenTurnkey"))
local Bell = require(script.Parent:WaitForChild("WardenBell"))

local S = 3.7
local M = {}
M.Kind = "WardenChainedBell"
M.Proportions = table.clone(Bell.Proportions)
M.IdlePose = "BLIdle"
M.Colors = Bell.Colors
M.FistSkin = true

function M.Look(k)
	Bell.LookRobe(k)
	Bell.LookBell(k)
	Turnkey.LookKeys(k)
	-- the chain, wound up its left arm and hung across its chest
	local deco, V, at, MAT, aw, la, ch, cd = k.deco, k.V, k.at, k.MAT, k.aw, k.la, k.ch, k.cd
	local iron = Color3.fromRGB(58, 56, 54)
	for i = 0, 4 do
		Garb.hoop(k, "LLowerArm", la / 2 - 0.2 - i * la / 5.5, aw * 0.98, aw * 0.98, 10, 0.15, iron, MAT.Metal, "ChainWrap")
	end
	for i = -3, 3 do
		deco("Chest", "ChainLink", V(0.26, 0.2, 0.1), at(i * 0.3, i * 0.26, -cd * 0.9 - (3 - math.abs(i)) * 0.03) * CFrame.Angles(0, 0, 0.72), iron, MAT.Metal)
	end
	deco("Chest", "ChainHook", V(0.34, 0.5, 0.14), at(0.98, ch * 0.42 - 0.95, -cd * 0.9), iron, MAT.Metal)
end

function M.init(core)
	local bl = Bell.moves(core)
	local F = Fight.init(core)
	local tk = Turnkey.moves(core, S / 1.95, {
		afterHook = bl.toll,
		onCatch = function(b)
			bl.bellSound(b, 1)
			F.wave(b, core.flat(b.root.Position), 22, 72, bl.NoteDamage, "Medium")
		end,
	})
	Fight.define({
		id = "ChainedBell",
		label = "The Chained Bell",
		kind = M.Kind,
		scale = S,
		weapon = "Clapper",
		idleGrip = "BLRest",
		hp = 780,
		poise = 170,
		stagger = 2.8,
		radius = 4.6,
		walk = 9.5,
		turn = 72,
		rest = { 0.65, 1.3 },
		keep = { 15, 24 },
		phase2At = 0.5,
		tempo2 = 0.88,
		restMult2 = 0.75,
		moves = {
			{ name = "Toll", fn = bl.toll, min = 0, max = 95, weight = 3, cd = 5 },
			{ name = "TollThree", fn = bl.tollThree, min = 14, max = 95, weight = 4, cd = 9 },
			{ name = "Swing", fn = bl.swing, min = 0, max = 27, weight = 6, cd = 2.5, fast = true, behind = true },
			{ name = "Down", fn = bl.down, min = 8, max = 30, weight = 4, cd = 4 },
			{ name = "Headlong", fn = bl.headlong, min = 3, max = 30, weight = 3, cd = 10 },
			{ name = "Hook", fn = tk.hook, min = 28, max = 90, weight = 5, cd = 7 },
			{ name = "ThrowClapper", fn = tk.throwKey, min = 20, max = 90, weight = 3, cd = 11, phase2 = true },
		},
		idle = bl.idle,
		onStagger = bl.onStagger,
		intro = bl.intro,
		phase2 = bl.phase2,
	})
end

return M
