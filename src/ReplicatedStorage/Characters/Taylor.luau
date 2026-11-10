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
local makeCorpse, ragdoll
local Debris = game:GetService("Debris")

-- one Giles, sat at cf: his rig, his glow, his prompt; onTalk(player) -> the line he says. He calls out once to
-- anyone who comes within CallRange (if callOut, and only while canCall() says so), so nobody walks past him.
local function seat(cf, callOut, canCall, onTalk)
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
	model:PivotTo(cf + Vector3.new(0, 3, 0))
	root.Anchored = true
	-- a warm glow round him and a candle at his feet: you see him from the walkway
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 190, 120)
	l.Range = 14
	l.Brightness = 0.9
	l.Parent = root
	local candle = Instance.new("Part")
	candle.Name = "GilesCandle"
	candle.Size, candle.Material, candle.Color = Vector3.new(0.3, 0.7, 0.3), Enum.Material.Neon, Color3.fromRGB(255, 214, 150)
	candle.CFrame = cf * CFrame.new(1.4, -0.2, -1.2)
	candle.Anchored, candle.CanCollide, candle.CanQuery, candle.CanTouch = true, false, false, false
	candle.Parent = model
	local actor = { model = model, scale = 1 }
	bodyPose(actor, "TaylorSit", 0.1)

	local T = Config.Taylor or {}
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "Talk"
	pp.ObjectText = T.Name or "Wretch Giles"
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 9
	pp.RequiresLineOfSight = false
	pp.Parent = root

	local busyUntil = 0
	local function say(player, line)
		FxRemote:FireClient(player, "Say", T.Name or "Wretch Giles", line)
		bodyPose(actor, (string.find(line, "Ha[%s!%.]") or string.find(line, "He he")) and "TaylorLaugh" or "TaylorLean", 0.25)
		busyUntil = now() + 2.5
		task.delay(2.5, function()
			if now() >= busyUntil - 0.01 then
				bodyPose(actor, "TaylorSit", 0.6)
			end
		end)
	end
	pp.Triggered:Connect(function(player)
		if player:GetAttribute("GilesDead") then -- (gone, for you: SoulsClient hides him)
			return
		end
		local line = onTalk(player)
		if line then
			say(player, line)
		end
	end)
	model:SetAttribute("Giles", "Alive") -- (SoulsClient: hidden from those who've seen him die)
	if callOut then
		local called = {}
		task.spawn(function()
			while model.Parent do
				task.wait(0.5)
				if canCall() then
					for _, pl in ipairs(Players:GetPlayers()) do
						local hrp = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
						if hrp and not called[pl] and not pl:GetAttribute("GilesDead") and (hrp.Position - root.Position).Magnitude < (T.CallRange or 45) then
							called[pl] = true
							say(pl, callOut)
						end
					end
				end
			end
		end)
		Players.PlayerRemoving:Connect(function(pl)
			called[pl] = nil
		end)
	end
	return root
end

function M.spawn()
	local T = Config.Taylor or {}
	local INTRO = T.Intro or {}
	local MORE = T.More or { "..." }
	local AFTER = T.AfterArmor or MORE
	local heard = {} -- per player: lines heard (here; and by the gate: woodHeard)
	-- the King's asked after him (KingAsked): his answer, at either of him, and at its end the Mabel questline begun
	-- (MabelQuest); after that, his plea again until her ring's been found. nil: nothing to say about it
	local KL = T.KingLines or {}
	local function kingTalk(player)
		if not player:GetAttribute("KingAsked") or #KL == 0 then
			return nil
		end
		if not player:GetAttribute("MabelQuest") then
			local k = (player:GetAttribute("GilesKingTalk") or 0) + 1
			player:SetAttribute("GilesKingTalk", k)
			if k >= #KL then
				player:SetAttribute("MabelQuest", true)
			end
			return KL[k] or KL[#KL]
		end
		return nil
	end
	-- by the Crossing: his intro; enough kills after it -> his armor; then small talk until the King's asked after him
	seat(Map.Taylor, T.CallOut, function()
		return true
	end, function(player)
		-- the King's asked after him: nothing but the Mabel questline from here on (none of his old talk)
		if player:GetAttribute("KingAsked") then
			local k = kingTalk(player)
			if k then
				return k
			end
			if not player:GetAttribute("GateKey") then
				player:SetAttribute("GateKey", true)
				FxRemote:FireClient(player, "Message", T.KeyItem or "Gate Key.")
				return T.QuestKey or KL[#KL]
			end
			if player:GetAttribute("MabelKnows") then
				return T.ToGate or KL[#KL]
			end
			return player:GetAttribute("MabelRing") and (T.Wood or {}).RingLine or KL[#KL]
		end
		local n = (heard[player] or 0) + 1
		heard[player] = n
		if n <= #INTRO then
			if n == #INTRO and player:GetAttribute("GilesKillsFrom") == nil then
				player:SetAttribute("GilesKillsFrom", player:GetAttribute("Kills") or 0) -- (only kills after he's asked count)
			end
			return INTRO[n]
		end
		if not player:GetAttribute("Motley") then
			local since = (player:GetAttribute("Kills") or 0) - (player:GetAttribute("GilesKillsFrom") or 0)
			if since >= (T.ArmorKills or 5) then -- you've put enough of them to rest
				player:SetAttribute("Motley", true)
				Config.wearArmor(player, "Motley") -- (worn straight away: init.server dresses you)
				FxRemote:FireClient(player, "Message", Config.Armor.Motley.Name .. ". A tall patchwork hat and a coat of patches. Press T to choose weapons and armor.")
				return T.ArmorLine or MORE[1]
			end
			return MORE[(n - #INTRO - 1) % #MORE + 1]
		end
		return AFTER[(n - 1) % #AFTER + 1] -- (the grand gate's key waits for the King's errand: QuestKey, above)
	end)
	Players.PlayerRemoving:Connect(function(pl)
		heard[pl] = nil
	end)
	-- in the grand gate's passage, once it's open: what became of Mabel (her ring in the palace; her, in the drains)
	if Map.GilesWood then
		local W = T.Wood or {}
		local WI, WM = W.Intro or {}, W.More or { "..." }
		local woodHeard = {}
		local woodRoot
		local dying = {}
		-- Ossaria takes him, for this player: her voice, the rot coming up round him, his last words; then he's gone
		-- for them (GilesDead: SoulsClient hides him, both of him, and shows his remains)
		local function ossariaTakes(player)
			task.wait(3.2)
			FxRemote:FireClient(player, "Say", W.OssariaName or "Ossaria", W.OssariaLine or "...")
			local pe = Instance.new("ParticleEmitter")
			pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
			pe.Color = ColorSequence.new(Color3.fromRGB(70, 40, 92), Color3.fromRGB(24, 40, 24))
			pe.LightEmission, pe.Rate, pe.Lifetime = 0, 60, NumberRange.new(0.8, 1.6)
			pe.Size = NumberSequence.new(1.5, 4)
			pe.Speed, pe.SpreadAngle = NumberRange.new(1, 3), Vector2.new(180, 180)
			pe.Transparency = NumberSequence.new(0.3, 1)
			pe.Parent = woodRoot
			task.wait(3.5)
			FxRemote:FireClient(player, "Say", T.Name or "Wretch Giles", W.LastLine or "...")
			task.wait(2.5)
			pe.Enabled = false
			Debris:AddItem(pe, 2)
			player:SetAttribute("GilesDead", true)
		end
		woodRoot = seat(Map.GilesWood, W.CallOut, function()
			return Map.DecayedGateOpen
		end, function(player)
			if dying[player] then
				return nil -- (in the middle of dying)
			end
			if player:GetAttribute("MabelKnows") and player:GetAttribute("MabelQuest") then -- (and not dead yet: seat() stops the dead talking)
				dying[player] = true
				player:SetAttribute("GilesReunited", true)
				task.spawn(function()
					ossariaTakes(player)
					dying[player] = nil
				end)
				return W.ReunionLine or "..."
			end
			local n = (woodHeard[player] or 0) + 1
			woodHeard[player] = n
			if n <= #WI then
				return WI[n]
			end
			local k = kingTalk(player)
			if k then
				return k
			end
			if player:GetAttribute("MabelQuest") and not player:GetAttribute("GilesReunited") then
				return player:GetAttribute("MabelRing") and W.RingLine or KL[#KL]
			end
			return WM[(n - #WI - 1) % #WM + 1]
		end)
		Players.PlayerRemoving:Connect(function(pl)
			woodHeard[pl] = nil
		end)
		-- HIS REMAINS, where he sat: slumped, limp, only for those he's died for (SoulsClient shows them; "Search" gives
		-- his scrap for Mabel, GilesScrap)
		local body = RigBuilder.build("Taylor", 1)
		body.Name = "GilesRemains"
		body:SetAttribute("Giles", "Remains")
		applyLimbGroup(body)
		local bh = body:FindFirstChildOfClass("Humanoid")
		bh.BreakJointsOnDeath = false
		bh:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
		body:PivotTo(Map.GilesWood + Vector3.new(0, 2.5, 0))
		body.Parent = workspace
		makeCorpse(body)
		ragdoll(body)
		bh.PlatformStand = true
		local broot = body:FindFirstChild("HumanoidRootPart")
		task.delay(5, function() -- (settled: pinned where it fell)
			for _, d in ipairs(body:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Anchored = true
				end
			end
		end)
		local sp = Instance.new("ProximityPrompt")
		sp.ActionText, sp.ObjectText, sp.HoldDuration, sp.MaxActivationDistance, sp.RequiresLineOfSight = "Search", "Wretch Giles", 0.6, 8, false
		sp.Parent = broot
		sp.Triggered:Connect(function(player)
			if not player:GetAttribute("GilesDead") or player:GetAttribute("GilesScrap") then
				return
			end
			player:SetAttribute("GilesScrap", true)
			FxRemote:FireClient(player, "Message", W.RemainsItem or "A scrap of cloth.")
		end)
	end
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
	makeCorpse, ragdoll = core.makeCorpse, core.ragdoll
end

return M
