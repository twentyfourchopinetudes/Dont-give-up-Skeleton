--!nonstrict
-- WRETCH GILES (kind Taylor): the old tailor in the shack by the Crossing, in the
-- rotted encampment. Ragged, decrepit, and far too cheerful about all of it.
-- His name and every line he says are in Config.Taylor.
--
-- EVERYTHING ABOUT THIS CHARACTER IS IN THIS ONE FILE:
--   M.Proportions / M.Poses   body shape and its full-body poses (the client animator uses these too)
--   M.Colors / M.Look         how the rig is dressed (RigBuilder calls Look with a kit of helpers:
--                             deco(part, name, size, offset, color, material?, shape?), V(x,y,z), at(x,y,z) ...)
--   M.init(Core) and below    behaviour (server only)
-- SHARED TOOLKIT: server code here gets the shared helpers through M.init(Core)
-- (see the list at the top of ServerScriptService/GameServer/Core.lua).
local M = {}
M.Kind = "Taylor"
-- thin, stooped, long in the arm; sits cross-legged in the corner of his shack
M.Proportions = { girth = 0.78, arm = 1.04, hunch = 0.32 }
M.IdlePose = "TaylorSit"
M.Poses = {
	-- sat cross-legged on the floor in his corner, hands in his lap, head down under the hat
	TaylorSit = { drop = 2.2, lean = 0.25, head = 0.45, cross = 1, la1 = 0.6, la3 = 0.2, lel = 1.0, ra1 = 0.6, ra3 = -0.2, rel = 1.0, freeL = 0, breathe = 1.2 },
	-- rocks back and slaps a knee, shoulders shaking (the head stays down: the hat keeps his face)
	TaylorLaugh = { drop = 2.2, lean = 0.05, head = 0.3, side = 0.08, cross = 1, la1 = 0.5, la3 = -0.6, lel = 0.5, ra1 = 0.9, ra3 = 0.2, rel = 0.3, freeL = 0, breathe = 3.5 },
	-- leans toward you, one finger up
	TaylorLean = { drop = 2.2, lean = 0.45, head = 0.3, twist = 0.12, cross = 1, la1 = 0.6, la3 = 0.2, lel = 1.0, ra1 = 1.5, ra3 = -0.1, rel = 1.6, freeL = 0 },
}
M.Colors = { skin = Color3.fromRGB(172, 148, 126), torso = Color3.fromRGB(74, 60, 46), legs = Color3.fromRGB(56, 48, 40), arms = Color3.fromRGB(74, 60, 46) }
M.FistSkin = true

function M.Look(k)
	-- no head to speak of: the hat and its shroud are all there is up there (the head
	-- block itself is hidden, or its corners poke out through the cone)
	k.parts.Head.Transparency = 1
	M.Outfit(k)
	for _, n in ipairs({ "R", "L" }) do
		k.parts[n .. "Foot"].Color = k.rgb(40, 32, 26) -- boots worn through
	end
end

-- HIS OUTFIT (also the armor he gives you: M.wear): an old man under a ridiculous tall
-- patchwork hat pulled down over his face, in a long coat that is more patches than coat,
-- a tailor's tape round his neck and a pincushion strapped to his wrist. k = RigBuilder's
-- Look kit (deco, V, at, rgb, MAT, look, and the body's sizes); of the colours only
-- k.look.torso is read, and nothing here touches the body's own parts.
function M.Outfit(k)
	local deco, V, at, rgb, MAT, look = k.deco, k.V, k.at, k.rgb, k.MAT, k.look
	local cw, ch, cd, hw, hd, aw, la, ua, lw = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.la, k.ua, k.lw
	local coat, coatDark = look.torso, rgb(50, 40, 32)
	local tape = rgb(176, 150, 70)
	-- THE HAT: a tall patchwork cone pulled down past his nose (only the chin shows under
	-- it), leaning off to one side, the tip flopped over with a little bell on the end
	local hatA, hatB = rgb(92, 56, 72), rgb(120, 96, 56)
	local cyl = Enum.PartType.Cylinder
	local up = CFrame.Angles(0, 0, math.pi / 2) -- (a cylinder's length runs along X: stand it up)
	local N = 7
	for i = 0, N - 1 do
		local f = i / (N - 1)
		local d = 1.8 * (1 - f) + 0.22 * f
		local x, y = 0.012 * i * i, -0.08 + i * 0.4
		local col = (i % 2 == 0 and hatA or hatB):Lerp(rgb(40, 34, 30), (i % 3) * 0.12)
		deco("Head", "Hat", V(0.44, d, d), at(x, y, 0) * CFrame.Angles(0, 0, -i * 0.04) * up, col, MAT.Fabric, cyl)
	end
	deco("Head", "HatFlop", V(0.55, 0.2, 0.2), at(0.66, 2.42, 0) * CFrame.Angles(0, 0, -1.2) * up, hatA, MAT.Fabric, cyl)
	deco("Head", "HatBell", V(0.22, 0.22, 0.22), at(0.86, 2.18, 0), rgb(150, 120, 50), MAT.Metal, Enum.PartType.Ball)
	-- patches sewn on crooked, and a hole worn through
	deco("Head", "HatPatch", V(0.42, 0.36, 0.04), at(-0.2, 0.55, -0.72) * CFrame.Angles(-0.12, 0, 0.25), rgb(70, 80, 96), MAT.Fabric)
	deco("Head", "HatPatch", V(0.3, 0.3, 0.04), at(0.35, 0.95, 0.6) * CFrame.Angles(0.15, 0, -0.3), rgb(60, 76, 52), MAT.Fabric)
	deco("Head", "HatStitch", V(0.46, 0.04, 0.03), at(-0.2, 0.74, -0.75) * CFrame.Angles(-0.12, 0, 0.25), rgb(190, 180, 150), MAT.Fabric)
	deco("Head", "HatHole", V(0.16, 0.12, 0.03), at(0.15, 1.45, -0.46) * CFrame.Angles(-0.2, 0, 0), rgb(16, 12, 10), MAT.SmoothPlastic)
	-- the rim gone to rags, strips hanging down all round it
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		local l = 0.2 + ((i * 7) % 5) * 0.07
		deco("Head", "HatRag", V(0.22, l, 0.05), CFrame.Angles(0, a, 0) * at(0, -0.3 - l / 2, -0.88) * CFrame.Angles(0.1, 0, ((i % 3) - 1) * 0.15), (i % 2 == 0 and hatA or hatB):Lerp(rgb(0, 0, 0), 0.25), MAT.Fabric)
	end
	-- a dark shroud sewn under the rim: it falls all round his head to the shoulders
	-- (on the head, so it swings with it), and a mantle of the same over his chest and
	-- arms, so all you make out of him in there is hat, rags and shadow
	local shroud = rgb(40, 35, 31)
	for i = 0, 15 do
		local a = i / 16 * math.pi * 2
		local l = 1.0 + ((i * 5) % 4) * 0.12
		deco("Head", "Shroud", V(0.42, l, 0.05), CFrame.Angles(0, a, 0) * at(0, -0.28 - l / 2, -0.9) * CFrame.Angles(0.12, 0, 0), shroud:Lerp(rgb(0, 0, 0), (i % 3) * 0.12), MAT.Fabric)
	end
	for i = 0, 13 do
		local a = i / 14 * math.pi * 2
		local l = ch * 0.85 + ((i * 3) % 4) * 0.12
		local x, z = math.sin(a) * cw * 0.68, -math.cos(a) * cd * 0.8
		deco("Chest", "Mantle", V(cw * 0.42, l, 0.06), at(x, ch / 2 + 0.05 - l / 2, z) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0.08, 0, 0), shroud:Lerp(rgb(0, 0, 0), ((i + 1) % 3) * 0.1), MAT.Fabric)
	end
	-- the coat: long, to the knee, the hem in tatters, patched all over with odd scraps
	deco("Chest", "Coat", V(cw * 1.14, ch * 1.02, cd * 1.2), at(0, 0, 0), coat, MAT.Fabric)
	deco("Chest", "Lapel", V(0.28, ch * 0.6, 0.06), at(-cw * 0.18, 0.15, -cd * 0.62) * CFrame.Angles(0, 0, 0.18), coatDark, MAT.Fabric)
	deco("Chest", "Lapel", V(0.28, ch * 0.6, 0.06), at(cw * 0.18, 0.15, -cd * 0.62) * CFrame.Angles(0, 0, -0.18), coatDark, MAT.Fabric)
	deco("Hips", "CoatTails", V(hw * 1.2, 0.9, hd * 1.25), at(0, -0.3, 0), coat, MAT.Fabric) -- (short: he sits on them)
	local patches = { rgb(110, 46, 40), rgb(70, 80, 96), rgb(120, 104, 70), rgb(60, 76, 52) }
	for i, p in ipairs({ { "Chest", -cw * 0.3, -0.35 }, { "Chest", cw * 0.28, 0.3 }, { "Hips", hw * 0.3, -0.9 }, { "Chest", 0.05, -0.55 } }) do
		local z = p[1] == "Chest" and -cd * 0.61 or -hd * 0.64
		deco(p[1], "Patch", V(0.42, 0.36, 0.04), at(p[2], p[3], z) * CFrame.Angles(0, 0, (i - 2) * 0.2), patches[i], MAT.Fabric)
		deco(p[1], "Stitch", V(0.46, 0.04, 0.03), at(p[2], p[3] + 0.18, z - 0.02) * CFrame.Angles(0, 0, (i - 2) * 0.2), rgb(190, 180, 150), MAT.Fabric)
	end
	-- the tape round his neck, its ends hanging down his front
	deco("Chest", "TapeNeck", V(cw * 0.7, 0.08, cd * 1.25), at(0, ch / 2 - 0.05, 0), tape, MAT.Fabric)
	deco("Chest", "TapeEnd", V(0.14, ch * 0.7, 0.04), at(-cw * 0.12, 0.05, -cd * 0.64) * CFrame.Angles(0, 0, 0.06), tape, MAT.Fabric)
	deco("Chest", "TapeEnd", V(0.14, ch * 0.55, 0.04), at(cw * 0.12, 0.15, -cd * 0.64) * CFrame.Angles(0, 0, -0.08), tape, MAT.Fabric)
	-- sleeves too long, frayed cuffs; the pincushion on his left wrist
	for _, n in ipairs({ "R", "L" }) do
		deco(n .. "UpperArm", "Sleeve", V(aw * 1.3, ua * 0.95, aw * 1.3), at(0, 0, 0), coat, MAT.Fabric)
		deco(n .. "LowerArm", "Sleeve", V(aw * 1.25, la * 0.8, aw * 1.25), at(0, 0.1, 0), coat, MAT.Fabric)
		deco(n .. "LowerArm", "Cuff", V(aw * 1.35, 0.18, aw * 1.35), at(0, -la * 0.32, 0), coatDark, MAT.Fabric)
		deco(n .. "Shin", "Wrap", V(lw * 1.05, 0.2, lw * 1.05), at(0, -0.2, 0), rgb(120, 110, 90), MAT.Fabric)
	end
	deco("LLowerArm", "Pincushion", V(0.42, 0.42, 0.42), at(-aw * 0.6, -la * 0.2, 0), rgb(150, 40, 40), MAT.Fabric, Enum.PartType.Ball)
	for i = 0, 2 do
		deco("LLowerArm", "Pin", V(0.04, 0.22, 0.04), at(-aw * 0.6 - 0.12, -la * 0.2 + 0.12, -0.1 + i * 0.1) * CFrame.Angles(0, 0, 0.6 + i * 0.2), rgb(200, 200, 205), MAT.Metal)
	end
end

---------------------------------------------------------------------------
-- server: standing there, and talking to you
---------------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Map, FxRemote, now, bodyPose, applyLimbGroup, RigBuilder

function M.spawn()
	local NPCs = workspace:FindFirstChild("NPCs") or Instance.new("Folder") -- (shared: one folder only)
	NPCs.Name = "NPCs" -- animated by the Puppeteer like everyone else, but never hittable
	NPCs.Parent = workspace
	local model = RigBuilder.build("Taylor", 1)
	model.Name = "Taylor"
	pcall(function()
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	applyLimbGroup(model)
	model.Parent = NPCs
	local hum = model:FindFirstChildOfClass("Humanoid")
	hum.HipHeight = model:GetAttribute("HipHeight")
	local root = model:FindFirstChild("HumanoidRootPart")
	model:PivotTo(Map.Taylor + Vector3.new(0, 3, 0))
	root.Anchored = true
	-- a faint glow in the dark of the shack: enough to find him, not enough to see him by
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 190, 120)
	l.Range = 7
	l.Brightness = 0.35
	l.Parent = root
	local actor = { model = model, scale = 1 }
	bodyPose(actor, "TaylorSit", 0.1)

	local T = Config.Taylor or {}
	local INTRO = T.Intro or {}
	local MORE = T.More or { "..." }
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "Talk"
	pp.ObjectText = T.Name or "Wretch Giles"
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 9
	pp.RequiresLineOfSight = false
	pp.Parent = root

	local heard = {} -- per player: lines heard
	local busyUntil = 0
	pp.Triggered:Connect(function(player)
		local n = (heard[player] or 0) + 1
		heard[player] = n
		local line = n <= #INTRO and INTRO[n] or MORE[(n - #INTRO - 1) % #MORE + 1]
		-- you've put enough of them to rest: he gives you the armor (his own outfit, in your size)
		if n > #INTRO and not player:GetAttribute("Motley") and (player:GetAttribute("Kills") or 0) >= (T.ArmorKills or 5) then
			line = T.ArmorLine or line
			player:SetAttribute("Motley", true)
			Config.wearArmor(player, "Motley") -- (worn straight away: init.server dresses you)
			FxRemote:FireClient(player, "Message", Config.Armor.Motley.Name .. ". A tall patchwork hat and a coat of patches. Press T to choose weapons and armor.")
		end
		FxRemote:FireClient(player, "Say", T.Name or "Wretch Giles", line)
		bodyPose(actor, (string.find(line, "Ha[%s!%.]") or string.find(line, "He he")) and "TaylorLaugh" or "TaylorLean", 0.25)
		busyUntil = now() + 2.5
		task.delay(2.5, function()
			if now() >= busyUntil - 0.01 then
				bodyPose(actor, "TaylorSit", 0.6)
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(pl)
		heard[pl] = nil
	end)
end

-- put his outfit on a player's character, or take it off again (Config.Armor.Motley;
-- init.server's dressArmor). It hides the skull under the cone while it's on.
function M.unwear(char)
	local folder = char:FindFirstChild("Motley")
	if folder then
		folder:Destroy()
	end
	for _, d in ipairs(char:GetDescendants()) do
		local t = d:GetAttribute("MotleyT")
		if t then
			d.Transparency = t
			d:SetAttribute("MotleyT", nil)
		end
	end
end
function M.wear(char)
	local head = char:FindFirstChild("Head")
	if not head or char:FindFirstChild("Motley") then
		return
	end
	local folder = Instance.new("Model")
	folder.Name = "Motley"
	folder.Parent = char
	for _, d in ipairs(char:GetDescendants()) do -- the skull and whatever's welded to it
		local w = d:IsA("BasePart") and d:FindFirstChildOfClass("WeldConstraint")
		if d == head or (w and w.Part0 == head) then
			d:SetAttribute("MotleyT", d.Transparency) -- (unwear puts it back)
			d.Transparency = 1
		end
	end
	local function deco(onPart, name, size, offset, color, mat, shape)
		local base = char:FindFirstChild(onPart)
		if not base then
			return
		end
		local d = Instance.new("Part")
		d.Name = name
		if shape then
			d.Shape = shape
		end
		d.Size, d.Color, d.Material = size, color, mat or Enum.Material.SmoothPlastic
		d.CanCollide, d.CanQuery, d.CanTouch, d.Massless = false, false, false, true
		d.CFrame = base.CFrame * offset
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = base, d
		w.Parent = d
		d.Parent = folder
	end
	local function size(n)
		local p = char:FindFirstChild(n)
		return p and p.Size or Vector3.one
	end
	local chest, hips, ua, la, shin = size("Chest"), size("Hips"), size("RUpperArm"), size("RLowerArm"), size("RShin")
	M.Outfit({
		deco = deco, V = Vector3.new, at = CFrame.new, rgb = Color3.fromRGB, MAT = Enum.Material, look = M.Colors,
		cw = chest.X, ch = chest.Y, cd = chest.Z, hw = hips.X, hd = hips.Z, aw = ua.X, ua = ua.Y, la = la.Y, lw = shin.X / 0.9,
	})
	-- ...and on you it's long: a cloak to the feet (Armor.luau)
	local Armor = require(game:GetService("ServerScriptService"):WaitForChild("GameServer"):WaitForChild("Armor"))
	Armor.cloak(deco, size, M.Colors.torso, Color3.fromRGB(50, 40, 32))
end

function M.init(core)
	Map, FxRemote, now, bodyPose, applyLimbGroup, RigBuilder = core.Map, core.FxRemote, core.now, core.bodyPose, core.applyLimbGroup, core.RigBuilder
end

return M
