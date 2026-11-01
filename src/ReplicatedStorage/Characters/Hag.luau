--!nonstrict
-- THE OLD HAG (kind Hag): shut up behind the locked door at the end of the high bridge over
-- the rotted encampment. When it opens she totters out and falls flat, then hauls herself
-- up onto her knees and thanks you - and gives you a book of pyromancies (the Old Book).
-- Bent double, rag-wrapped, a hooked nose and pale eyes, and a wild mane of grey hair that
-- never stops writhing (hair anchors tagged "RotLimb" with a Hair colour; the clients grow
-- them, Carrier.growths). Her name and every line she says are in Config.Hag.
--
-- EVERYTHING ABOUT THIS CHARACTER IS IN THIS ONE FILE:
--   M.Proportions / M.Poses   body shape and its full-body poses (the client animator uses these too)
--   M.Colors / M.Look         how the rig is dressed (RigBuilder calls Look with a kit of helpers:
--                             deco(part, name, size, offset, color, material?, shape?), V(x,y,z), at(x,y,z) ...)
--   M.init(Core) and below    behaviour (server only)
local CollectionService = game:GetService("CollectionService")

local M = {}
M.Kind = "Hag"
-- tiny and bent double, arms long and stringy
M.Proportions = { girth = 0.72, arm = 1.12, hunch = 0.6 }
M.IdlePose = "HagKneel"
M.Poses = {
	-- on her knees, sagging forward, hands on the floor in front of her
	HagKneel = { drop = 1.5, lean = 0.6, head = -0.15, footR = 1.0, footL = -1.3, la1 = 1.1, la3 = -0.2, lel = 0.4, ra1 = 1.1, ra3 = 0.2, rel = 0.4, freeL = 0, breathe = 2.2 },
	-- reaching up toward you from her knees, imploring
	HagPlead = { drop = 1.4, lean = 0.3, head = -0.45, twist = 0.1, footR = 1.0, footL = -1.3, la1 = 0.9, la3 = -0.1, lel = 0.6, ra1 = 1.6, ra3 = -0.1, rel = 0.5, freeL = 0, breathe = 3 },
	-- holding something out to you in both hands
	HagGive = { drop = 1.4, lean = 0.4, head = -0.3, footR = 1.0, footL = -1.3, la1 = 1.5, la3 = 0.1, lel = 0.3, ra1 = 1.5, ra3 = -0.1, rel = 0.3, freeL = 0, breathe = 1.5 },
	-- pitching forward out of the dark, arms flung out
	HagFall = { drop = 0.3, lean = 0.9, head = -0.5, la1 = 1.8, la3 = -0.6, ra1 = 1.8, ra3 = 0.6, freeL = 0 },
}
local RAG, RAG_DARK, SKIN, HAIR = Color3.fromRGB(70, 62, 52), Color3.fromRGB(44, 38, 32), Color3.fromRGB(150, 142, 122), Color3.fromRGB(196, 192, 182)
M.Colors = { skin = SKIN, torso = RAG, legs = RAG_DARK, arms = RAG }
M.FistSkin = true

function M.Look(k)
	local deco, parts, V, at, rgb, MAT = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT
	local cw, ch, cd, hw, hd, aw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.la, k.ua
	parts.Head.Color = SKIN
	-- the face: a long hooked nose, sunken pale eyes, a slack mouth
	-- (the bridge rooted on the face between the eyes, sloping out and down to a hooked tip)
	deco("Head", "Nose", V(0.16, 0.5, 0.2), at(0, -0.1, -0.7) * CFrame.Angles(0.4, 0, 0), SKIN:Lerp(rgb(120, 90, 80), 0.3), MAT.SmoothPlastic)
	deco("Head", "NoseTip", V(0.17, 0.17, 0.17), at(0, -0.35, -0.79), SKIN:Lerp(rgb(120, 90, 80), 0.4), MAT.SmoothPlastic, Enum.PartType.Ball)
	deco("Head", "Mouth", V(0.36, 0.08, 0.04), at(0, -0.44, -0.6), rgb(40, 26, 24), MAT.SmoothPlastic)
	for _, x in ipairs({ -0.22, 0.22 }) do
		deco("Head", "Socket", V(0.24, 0.16, 0.04), at(x, 0.08, -0.6), rgb(50, 44, 40), MAT.SmoothPlastic)
		deco("Head", "Eye", V(0.08, 0.06, 0.05), at(x, 0.08, -0.62), rgb(210, 220, 200), MAT.Neon)
	end
	-- a grey thatch over the skull, and hanks of it down her back and over her face
	deco("Head", "HairMass", V(1.35, 0.6, 1.4), at(0, 0.5, 0.05), HAIR:Lerp(rgb(0, 0, 0), 0.2), MAT.Fabric)
	deco("Head", "HairBack", V(1.3, 1.6, 0.35), at(0, -0.3, 0.6), HAIR:Lerp(rgb(0, 0, 0), 0.25), MAT.Fabric)
	deco("Head", "HairL", V(0.25, 1.3, 1.1), at(-0.66, -0.2, 0.1), HAIR:Lerp(rgb(0, 0, 0), 0.15), MAT.Fabric)
	deco("Head", "HairR", V(0.25, 1.5, 1.1), at(0.66, -0.3, 0.1), HAIR:Lerp(rgb(0, 0, 0), 0.15), MAT.Fabric)
	-- and the wild part: locks sprouting all over her head, writhing (Carrier.growths)
	local hr = Random.new(6161)
	for i = 1, 22 do
		local a = hr:NextNumber(0, math.pi * 2)
		local y = hr:NextNumber(0.1, 0.75)
		local pos = Vector3.new(math.cos(a) * 0.62, y, math.sin(a) * 0.62 + 0.1)
		local dir = Vector3.new(math.cos(a), hr:NextNumber(0.1, 1.2), math.sin(a) + 0.5).Unit
		local p = deco("Head", "RotLimbRoot", V(0.2, 0.2, 0.2), CFrame.lookAt(pos * k.s, (pos + dir) * k.s), HAIR, MAT.SmoothPlastic)
		p.Transparency = 1
		p:SetAttribute("Seed", 6200 + i)
		p:SetAttribute("Scale", hr:NextNumber(0.25, 0.45) * k.s)
		p:SetAttribute("Hair", HAIR:Lerp(rgb(120, 116, 104), hr:NextNumber(0, 0.6)))
		p:SetAttribute("Follow", true)
		CollectionService:AddTag(p, "RotLimb")
	end
	-- rags: a shapeless wrap over the shoulders, a shawl, a skirt in strips to the floor
	deco("Chest", "Wrap", V(cw * 1.3, ch * 1.0, cd * 1.35), at(0, -0.05, 0), RAG, MAT.Fabric)
	deco("Chest", "Shawl", V(cw * 1.4, 0.5, cd * 1.45), at(0, ch / 2 - 0.2, 0), RAG_DARK, MAT.Fabric)
	deco("Hips", "Skirt", V(hw * 1.2, 1.4, hd * 1.2), at(0, -0.6, 0), RAG_DARK, MAT.Fabric)
	for i = 0, 4 do
		deco("Hips", "Strip", V(hw * 0.22, 1.2 + (i % 2) * 0.4, 0.1), at(-hw * 0.48 + i * hw * 0.24, -1.6, -hd * 0.62), RAG:Lerp(rgb(0, 0, 0), (i % 3) * 0.15), MAT.Fabric)
	end
	for _, n in ipairs({ "R", "L" }) do
		deco(n .. "UpperArm", "Sleeve", V(aw * 1.3, ua * 0.9, aw * 1.3), at(0, 0, 0), RAG, MAT.Fabric)
		parts[n .. "LowerArm"].Color = SKIN -- bare, stringy forearms
		parts[n .. "Foot"].Color = SKIN:Lerp(rgb(50, 40, 32), 0.4)
	end
end

---------------------------------------------------------------------------
-- server: falling out of the door, and talking to you
---------------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Map, FxRemote, now, bodyPose, applyLimbGroup, RigBuilder, playSound, SOUNDS

-- once, when the tunnel door opens (init.server's lockedDoor): she's built just behind it,
-- totters out and pitches face-first onto the floor at the mouth, lies there a moment, then
-- pushes herself up onto her knees - and only then can you talk to her
local out = false
function M.emerge()
	if out or not Map.Hag then
		return
	end
	out = true
	local NPCs = workspace:FindFirstChild("NPCs") or Instance.new("Folder") -- (shared: one folder only)
	NPCs.Name = "NPCs"
	NPCs.Parent = workspace
	local model = RigBuilder.build("Hag", 1)
	model.Name = "Hag"
	pcall(function()
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	applyLimbGroup(model)
	model.Parent = NPCs
	local hum = model:FindFirstChildOfClass("Humanoid")
	hum.HipHeight = model:GetAttribute("HipHeight")
	local root = model:FindFirstChild("HumanoidRootPart")
	root.Anchored = true
	local UP = Vector3.new(0, 3, 0)
	local inside, kneel = Map.Hag.Inside + UP, Map.Hag.Out + UP
	local lying = (Map.Hag.Out + Vector3.new(0, 0.9, 0)) * CFrame.Angles(-1.45, 0, 0) -- (face down, her head toward the pit)
	model:PivotTo(inside)
	local actor = { model = model, scale = 1 }
	bodyPose(actor, "HagFall", 0.1)

	local H = Config.Hag or {}
	local INTRO, MORE = H.Intro or {}, H.More or { "..." }
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "Talk"
	pp.ObjectText = H.Name or "Old Hag"
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 9
	pp.RequiresLineOfSight = false
	pp.Enabled = false
	pp.Parent = root

	task.spawn(function()
		task.wait(1) -- (the door's still swinging)
		for i = 1, 22 do -- a few lurching steps, then down
			local t = i / 22
			model:PivotTo(inside:Lerp(lying, t * t))
			task.wait(1 / 30)
		end
		playSound(root, SOUNDS.Impact, 0.6, 0.7)
		task.wait(1.6)
		bodyPose(actor, "HagKneel", 0.8)
		for i = 1, 36 do
			model:PivotTo(lying:Lerp(kneel, math.sin(i / 36 * math.pi / 2)))
			task.wait(1 / 30)
		end
		pp.Enabled = true
	end)

	local heard = {} -- per player: lines heard
	local busyUntil = 0
	pp.Triggered:Connect(function(player)
		local n = (heard[player] or 0) + 1
		heard[player] = n
		local line = n <= #INTRO and INTRO[n] or MORE[(n - #INTRO - 1) % #MORE + 1]
		local posed = "HagPlead"
		-- after her thanks, the book (the Old Book: every attack casts a fireball)
		if n > #INTRO and not player:GetAttribute("Has_OldBook") then
			line = H.BookLine or line
			posed = "HagGive"
			player:SetAttribute("Has_OldBook", true)
			FxRemote:FireClient(player, "Message", Config.Weapons.OldBook.Name .. ". A book of pyromancies, its pages singed. Press T to choose weapons and armor.")
		end
		FxRemote:FireClient(player, "Say", H.Name or "Old Hag", line)
		bodyPose(actor, posed, 0.3)
		busyUntil = now() + 2.5
		task.delay(2.5, function()
			if now() >= busyUntil - 0.01 then
				bodyPose(actor, "HagKneel", 0.6)
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(pl)
		heard[pl] = nil
	end)
end

function M.init(core)
	Map, FxRemote, now, bodyPose, applyLimbGroup, RigBuilder, playSound, SOUNDS = core.Map, core.FxRemote, core.now, core.bodyPose, core.applyLimbGroup, core.RigBuilder, core.playSound, core.SOUNDS
end

return M
