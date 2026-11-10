--!nonstrict
-- THE GILDED KING (kind GildedKing): the Heights' old king, in his Ballroom, father of the Silver Knight, the King of Pyralis and Ossaria. He
-- doesn't fight. He's Caelen grown old: the same fluted silver plate and T-slit helm, but taller and broader, a crown of arches risen out
-- of the helm itself, a white beard spilling out under its jaw, a great crimson mantle lined with ermine that sweeps the floor behind
-- him, a gold sun the size of a shield on his breast. He stands on his dais under the great window, both hands folded on the pommel of a
-- sword grounded point-down in front of him. When you speak to him he lifts his head.
-- His lines are Config.GildedKing; where he stands, and the stone dancers round him, GildedHeights (Map.Heights.Ballroom).
local K = require(script.Parent.Parent:WaitForChild("GildedKit"))
local M = {}
M.Kind = "GildedKing"
M.Proportions = { girth = 1.0, arm = 1.12, hunch = 0, limbs = true, twoHand = 0.5 }
M.IdlePose = "GKBStand"
M.Poses = {
	-- upright, chin down a little, both hands resting on the pommel before him
	GKBStand = { drop = 0, lean = 0.04, head = 0.24, footR = -0.12, footL = 0.14, spread = 0.12, breathe = 0.4, freeL = 0, rwr = 0.2, lwr = 0.2 },
	-- looking up at you, shoulders back
	GKBSpeak = { drop = 0, lean = -0.06, head = -0.12, footR = -0.12, footL = 0.14, spread = 0.12, breathe = 0.9, freeL = 0, rwr = 0.2, lwr = 0.2 },
	-- (the dancers' statues: a lady's turn, arms up and round; a lord's, one arm at her waist)
	GKBLady = { drop = 0.1, lean = -0.12, twist = 0.3, head = -0.2, footR = -0.35, footL = 0.4, spread = 0.1, la1 = 2.2, la3 = -0.4, lel = 1.2, freeL = 0 },
	GKBLord = { drop = 0.12, lean = 0.08, twist = -0.25, head = 0.12, footR = 0.4, footL = -0.3, spread = 0.12, la1 = 1.6, la3 = -0.7, lel = 0.9, freeL = 0 },
}
local R = math.rad
M.Grips = {
	GKPommel = { Vector3.new(0, 0.55, -1.25), CFrame.Angles(0, R(90), 0) }, -- the sword stood point-down in front of him
	GKLady = { Vector3.new(1.5, 1.6, -0.6), CFrame.Angles(R(160), 0, R(25)) },
}
M.BodyFor = { GKPommel = "GKBStand" }
local STEEL, STEEL_DK, GOLD, MANTLE, ERMINE, BEARD = Color3.fromRGB(196, 200, 208), Color3.fromRGB(140, 144, 154), K.GOLD, Color3.fromRGB(122, 18, 30), Color3.fromRGB(238, 236, 228), Color3.fromRGB(232, 230, 224)
M.Colors = { skin = STEEL, torso = STEEL, legs = STEEL_DK, arms = STEEL }

function M.Look(k)
	local deco, parts, V, at, rgb, MAT, D, s = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT, k.D, k.s
	local cw, ch, cd, hw, hd, aw, lw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.lw, k.la, k.ua
	local th, shin = D.thigh / s, D.shin / s
	-- THE PLATE: Caelen's, fluted, but every edge gilt and the sun on his chest as big as a shield
	deco("Chest", "Breastplate", V(cw * 1.04, ch * 0.84, 0.32), at(0, 0.08, -cd / 2 - 0.1), STEEL, MAT.Metal)
	for i = -2, 2 do
		deco("Chest", "Flute", V(0.08, ch * 0.72, 0.06), at(i * cw * 0.16, 0.05, -cd / 2 - 0.28), STEEL_DK, MAT.Metal)
	end
	deco("Chest", "SunDisc", V(0.08, 1.2, 1.2), at(0, 0.22, -cd / 2 - 0.32) * K.FACE, GOLD, MAT.Metal, Enum.PartType.Cylinder)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		deco("Chest", "SunRay", V(0.12, i % 2 == 0 and 0.5 or 0.32, 0.05), at(math.cos(a) * 0.82, 0.22 + math.sin(a) * 0.82, -cd / 2 - 0.32) * CFrame.Angles(0, 0, a - math.pi / 2), K.LIGHT, MAT.Metal)
	end
	deco("Chest", "Backplate", V(cw, ch * 0.84, 0.24), at(0, 0.08, cd / 2 + 0.08), STEEL, MAT.Metal)
	deco("Chest", "Gorget", V(cw * 0.62, 0.38, cd * 1.18), at(0, ch / 2 - 0.02, 0), STEEL, MAT.Metal)
	deco("Chest", "GorgetTrim", V(cw * 0.66, 0.08, cd * 1.22), at(0, ch / 2 - 0.2, 0), GOLD, MAT.Metal)
	-- a chain of office over it all, heavy gold links and a ruby
	for i = 0, 10 do
		local a = i / 10 * math.pi
		deco("Chest", "ChainLink", V(0.2, 0.2, 0.1), at(math.cos(a) * cw * 0.42, ch * 0.42 - math.sin(a) * ch * 0.36, -cd / 2 - 0.36), GOLD, MAT.Metal, Enum.PartType.Ball)
	end
	deco("Hips", "Belt", V(hw + 0.16, 0.26, hd + 0.16), at(0, 0.3, 0), rgb(40, 30, 24), MAT.Leather)
	deco("Hips", "Buckle", V(0.4, 0.3, 0.06), at(0, 0.3, -hd / 2 - 0.1), GOLD, MAT.Metal)
	for _, z in ipairs({ -1, 1 }) do
		deco("Hips", "Skirt", V(hw * 0.95, 2.2, 0.08), at(0, -1.15, z * (hd / 2 + 0.12)), MANTLE, MAT.Fabric)
		deco("Hips", "SkirtHem", V(hw * 0.97, 0.16, 0.1), at(0, -2.2, z * (hd / 2 + 0.13)), GOLD, MAT.Metal)
	end
	for _, n in ipairs({ "R", "L" }) do
		local sx = n == "R" and 1 or -1
		deco(n .. "UpperArm", "Pauldron", V(aw * 2.05, 0.6, aw * 1.9), at(sx * 0.12, ua / 2 - 0.1, 0) * CFrame.Angles(0, 0, -sx * 0.3), STEEL, MAT.Metal)
		deco(n .. "UpperArm", "PauldronLame", V(aw * 1.8, 0.22, aw * 1.7), at(sx * 0.08, ua / 2 - 0.48, 0) * CFrame.Angles(0, 0, -sx * 0.2), STEEL_DK, MAT.Metal)
		deco(n .. "UpperArm", "PauldronTrim", V(aw * 2.1, 0.09, aw * 1.95), at(sx * 0.12, ua / 2 - 0.38, 0) * CFrame.Angles(0, 0, -sx * 0.3), GOLD, MAT.Metal)
		deco(n .. "LowerArm", "Couter", V(aw * 1.35, 0.4, aw * 1.35), at(0, la / 2 - 0.12, 0), STEEL, MAT.Metal)
		deco(n .. "LowerArm", "Vambrace", V(aw * 1.15, la * 0.6, aw * 1.15), at(0, -0.05, 0), STEEL, MAT.Metal)
		deco(n .. "LowerArm", "Gauntlet", V(aw * 1.28, 0.48, aw * 1.28), at(0, -la / 2 + 0.2, 0), GOLD, MAT.Metal)
		deco(n .. "Thigh", "Cuisse", V(lw * 1.15, th * 0.72, lw * 1.15), at(0, 0.05, 0), STEEL, MAT.Metal)
		deco(n .. "Shin", "Poleyn", V(lw * 1.25, 0.42, lw * 1.3), at(0, shin / 2 - 0.08, -0.05), GOLD, MAT.Metal)
		deco(n .. "Shin", "Greave", V(lw * 1.12, shin * 0.66, lw * 1.12), at(0, -shin * 0.1, 0), STEEL, MAT.Metal)
		deco(n .. "Foot", "Sabaton", V(D.footSize.X / s * 1.1, 0.26, D.footSize.Z / s * 0.95), at(0, 0.06, -0.05), STEEL_DK, MAT.Metal)
		deco(n .. "Toe", "ToeCap", V(D.toeSize.X / s * 1.1, 0.16, D.toeSize.Z / s * 0.9), at(0, 0.03, -0.03), STEEL, MAT.Metal)
		deco(n .. "Hand", "Knuckles", V(D.handSize.X / s * 1.1, 0.14, D.handSize.Z / s * 1.12), at(0, -0.1, 0), GOLD, MAT.Metal)
	end
	-- THE HELM: Caelen's T-slit, and the crown grown up out of it, its arches meeting under an orb; the beard below the jaw
	deco("Head", "Helm", V(1.15, 1.15, 1.2), at(0, 0.255, 0), STEEL, MAT.Metal)
	deco("Head", "HelmJaw", V(0.75, 0.35, 1.2), at(0, -0.495, 0), STEEL, MAT.Metal)
	deco("Head", "Slit", V(0.9, 0.09, 0.05), at(0, 0.2, -0.62), rgb(6, 6, 8), MAT.SmoothPlastic)
	deco("Head", "SlitDown", V(0.12, 0.6, 0.05), at(0, -0.12, -0.62), rgb(6, 6, 8), MAT.SmoothPlastic)
	for _, sx in ipairs({ -1, 1 }) do
		deco("Head", "EyeGlint", V(0.12, 0.05, 0.03), at(sx * 0.22, 0.2, -0.64), K.LIGHT, MAT.Neon)
	end
	deco("Head", "Circlet", V(1.24, 0.24, 1.29), at(0, 0.62, 0), GOLD, MAT.Metal)
	for i = 0, 7 do
		local a = i * math.pi / 4
		deco("Head", "Fleuron", V(0.18, 0.44, 0.1), at(math.sin(a) * 0.64, 0.92, math.cos(a) * 0.66) * CFrame.Angles(0, a, 0), K.LIGHT, MAT.Metal)
		deco("Head", "CrownJewel", V(0.14, 0.14, 0.06), at(math.sin(a) * 0.66, 0.62, math.cos(a) * 0.68) * CFrame.Angles(0, a, 0), i % 2 == 0 and K.RUG or K.LAPIS, MAT.Glass)
	end
	for _, a in ipairs({ 0, math.pi / 2 }) do
		for i = 0, 6 do
			local t = i / 6 * math.pi
			deco("Head", "Arch", V(0.12, 0.18, 0.14), at(math.cos(t) * 0.6 * math.cos(a), 0.78 + math.sin(t) * 0.55, math.cos(t) * 0.6 * math.sin(a)) * CFrame.Angles(0, a, t - math.pi / 2), GOLD, MAT.Metal)
		end
	end
	deco("Head", "CrownCap", V(1.05, 0.5, 1.05), at(0, 0.95, 0), MANTLE, MAT.Fabric, Enum.PartType.Ball)
	deco("Head", "Orb", V(0.32, 0.32, 0.32), at(0, 1.42, 0), GOLD, MAT.Metal, Enum.PartType.Ball)
	deco("Head", "OrbCross", V(0.08, 0.32, 0.08), at(0, 1.66, 0), GOLD, MAT.Metal)
	deco("Head", "Beard", V(0.9, 0.7, 0.36), at(0, -0.9, -0.36), BEARD, MAT.Sand)
	deco("Chest", "BeardFall", V(0.72, 0.9, 0.2), at(0, ch * 0.28, -cd / 2 - 0.42), BEARD, MAT.Sand)
	deco("Chest", "BeardPoint", V(0.4, 0.5, 0.16), at(0, ch * 0.0, -cd / 2 - 0.44), BEARD, MAT.Sand)
	-- THE MANTLE: crimson, an ermine collar round his shoulders, two great lengths of it falling behind him to the floor and beyond
	deco("Chest", "ErmineCollar", V(cw * 1.32, 0.55, cd * 1.55), at(0, ch / 2 + 0.05, 0.05), ERMINE, MAT.Fabric)
	for i = 0, 13 do
		deco("Chest", "ErmineSpot", V(0.07, 0.18, 0.05), at(-cw * 0.6 + i * cw * 0.092, ch / 2 + 0.05, -cd * 0.79), K.INK, MAT.Fabric)
	end
	K.cloth(deco("Chest", "MantleAnchor", V(0.2, 0.2, 0.2), at(0, ch / 2 - 0.1, cd / 2 + 0.32) * K.BACK, MANTLE, MAT.SmoothPlastic), 7, 0.95 * s, cw * 1.35 * s, MANTLE, { Drag = 0.94, Gravity = 1.4, Out = 0.12 })
	for _, sx in ipairs({ -1, 1 }) do
		K.cloth(deco("Chest", "MantleSideAnchor", V(0.2, 0.2, 0.2), at(sx * (cw / 2 + 0.1), ch / 2 - 0.12, cd / 2 + 0.36) * K.BACK, MANTLE, MAT.SmoothPlastic), 6, 0.9 * s, cw * 0.6 * s, MANTLE:Lerp(rgb(0, 0, 0), 0.2), { Drag = 0.97, Gravity = 1, Out = 0.1 })
	end
end

M.Weapons = {
	-- his sword: Caelen's, as long as he is tall, the blade etched gold along its fuller, a sun for a pommel
	GildedKingBlade = function(w)
		local mk, add = w.mk, w.add
		local steel, dark = Color3.fromRGB(196, 198, 204), Color3.fromRGB(46, 44, 46)
		local handle = mk("Grip", Vector3.new(0.3, 1.8, 0.3), dark, Enum.Material.Leather)
		local pom = mk("Pommel", Vector3.new(0.18, 0.8, 0.8), GOLD, Enum.Material.Metal)
		pom.Shape = Enum.PartType.Cylinder
		add(pom, 1.1, CFrame.Angles(0, 0, 0))
		add(mk("Guard", Vector3.new(3.1, 0.3, 0.38), GOLD, Enum.Material.Metal), -0.98)
		for _, sx in ipairs({ -1, 1 }) do
			add(mk("GuardEnd", Vector3.new(0.42, 0.42, 0.42), K.LIGHT, Enum.Material.Metal), -0.98, CFrame.new(sx * 1.55 * w.scale, 0, 0))
		end
		add(mk("Blade", Vector3.new(1.3, 7.6, 0.14), steel, Enum.Material.Metal), -4.85)
		add(mk("Fuller", Vector3.new(0.3, 6.6, 0.16), GOLD, Enum.Material.Metal), -4.55)
		add(mk("Point", Vector3.new(0.92, 0.92, 0.14), steel, Enum.Material.Metal), -8.65, CFrame.Angles(0, 0, math.pi / 4))
		return { handle = handle, bladeLen = 8.7 }
	end,
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Map, FxRemote, now, pose, bodyPose, giveWeapon, applyLimbGroup, RigBuilder, Roster

local SCALE = 2.3 -- (the Silver Knight's 2.0; his father a head taller)
function M.spawn()
	local B = Map.Heights and Map.Heights.Ballroom
	if not B then
		return
	end
	local Config = require(ReplicatedStorage:WaitForChild("Config"))
	local NPCs = workspace:FindFirstChild("NPCs") or Instance.new("Folder")
	NPCs.Name = "NPCs"
	NPCs.Parent = workspace
	-- the dancers first: couples in stone round the floor, a Dowager and an Oathsworn each, in the middle of the turn
	local Statue = Roster.byKind.KingGilded
	if Statue and Statue.statue then
		local folder = Instance.new("Model")
		folder.Name = "BallroomDancers"
		folder.Parent = workspace
		for _, c in ipairs(B.Dancers) do
			for _, pair in ipairs({ { "Dowager", c.Lady, "GKBLady" }, { "Oathsworn", c.Lord, "GKBLord" } }) do
				local ok, m = pcall(Statue.statue, pair[1], pair[2], 1.25, pair[3])
				if ok then
					m.Parent = folder
				else
					warn("[DGUS] ballroom dancer failed: " .. tostring(m))
				end
			end
		end
	end
	local model = RigBuilder.build("GildedKing", SCALE)
	model.Name = "GildedKing"
	pcall(function()
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	local weld = giveWeapon(model, "GildedKingBlade", SCALE)
	applyLimbGroup(model)
	model.Parent = NPCs
	local hum = model:FindFirstChildOfClass("Humanoid")
	hum.HipHeight = model:GetAttribute("HipHeight")
	local root = model:FindFirstChild("HumanoidRootPart")
	model:PivotTo(B.King + Vector3.new(0, 3 * SCALE, 0))
	root.Anchored = true
	local actor = { model = model, weld = weld, scale = SCALE, idleGrip = "GKPommel" }
	pose(actor, "GKPommel", 0.1)
	bodyPose(actor, "GKBStand", 0.1)

	local G = Config.GildedKing or {}
	local INTRO, MORE = G.Intro or {}, G.More or { "..." }
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText, pp.ObjectText = "Talk", G.Name or "The Gilded King"
	pp.HoldDuration, pp.MaxActivationDistance, pp.RequiresLineOfSight = 0, 14, false
	pp.Parent = root
	local talk, busyUntil = {}, 0
	pp.Triggered:Connect(function(player)
		local n = (talk[player] or 0) + 1
		talk[player] = n
		local line = n <= #INTRO and INTRO[n] or MORE[(n - #INTRO - 1) % #MORE + 1]
		FxRemote:FireClient(player, "Say", G.Name or "The Gilded King", line)
		if n == G.BlessAt and not player:GetAttribute("KingsBlessing") then -- (it opens the Decayed Palace's sealed door)
			player:SetAttribute("KingsBlessing", true)
			task.delay(3, function()
				FxRemote:FireClient(player, "Message", G.Blessing)
			end)
		end
		bodyPose(actor, "GKBSpeak", 0.5)
		busyUntil = now() + 3
		task.delay(3, function()
			if now() >= busyUntil - 0.01 then
				bodyPose(actor, "GKBStand", 1)
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(pl)
		talk[pl] = nil
	end)
end

function M.init(core)
	Map, FxRemote, now, pose, bodyPose, giveWeapon, applyLimbGroup, RigBuilder, Roster = core.Map, core.FxRemote, core.now, core.pose, core.bodyPose, core.giveWeapon, core.applyLimbGroup, core.RigBuilder, core.Roster
end

return M
