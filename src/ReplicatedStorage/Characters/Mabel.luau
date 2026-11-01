--!nonstrict
-- MABEL (kind Wick): the girl in the candlelit nook north of the Upper Drain.
-- Wise past her years, and she knows rather more than she lets on. He he.
-- Her name and every line she says are in Config.Wick.
--
-- EVERYTHING ABOUT THIS CHARACTER IS IN THIS ONE FILE:
--   M.Proportions / M.Poses   body shape and its full-body poses (the client animator uses these too)
--   M.Colors / M.Look         how the rig is dressed (RigBuilder calls Look with a kit of helpers:
--                             deco(part, name, size, offset, color, material?, shape?), V(x,y,z), at(x,y,z) ...)
--   M.Weapons / M.Grips       the weapon's model, and the grip poses its swings tween between
--   M.init(Core) and below    behaviour (server only)
-- SHARED TOOLKIT: server code here gets the shared helpers through M.init(Core)
-- (see the list at the top of ServerScriptService/GameServer/Core.lua). Body
-- poses not defined here (Idle, Windup, Strike, SweepWindup, SweepEnd, Recover,
-- Flinch, Stagger, Crouch, Air, Roar, Kneel) are shared ones from PuppetMath.
local M = {}
M.Kind = "Wick"
-- small, slight, swallowed by a shawl several sizes too big
M.Proportions = { girth = 0.8, arm = 0.95, hunch = 0.12 }
M.IdlePose = "WickSit"
M.Poses = {
	-- sitting on her crate, knees drawn up, candle in her lap; a tilt of the head
	-- and hunched shoulders when she giggles; looking up at you
	WickSit = { drop = 2.05, lean = 0.22, head = 0.2, tuck = 0.85, footR = 0.3, footL = 0.3, la1 = 0.7, la3 = -0.35, lel = 1.5, freeL = 0, breathe = 0.6 },
	WickGiggle = { drop = 2.0, lean = 0.38, side = 0.14, head = 0.05, twist = 0.1, tuck = 0.9, footR = 0.3, footL = 0.3, la1 = 1.0, la3 = -0.3, lel = 2.0, freeL = 0, breathe = 3 },
	WickLook = { drop = 2.05, lean = 0.05, side = -0.1, head = -0.15, twist = -0.12, tuck = 0.85, footR = 0.3, footL = 0.3, la1 = 0.7, la3 = -0.35, lel = 1.5, freeL = 0 },
}
M.Colors = { skin = Color3.fromRGB(186, 170, 150), torso = Color3.fromRGB(88, 84, 76), legs = Color3.fromRGB(70, 64, 56), arms = Color3.fromRGB(88, 84, 76) }
M.FistSkin = true

function M.Look(k)
	local deco, parts, V, at, rgb, MAT, look = k.deco, k.parts, k.V, k.at, k.rgb, k.MAT, k.look
	local cw, ch, cd, hw, hd, aw, la, ua = k.cw, k.ch, k.cd, k.hw, k.hd, k.aw, k.la, k.ua
	-- a small girl in a grey shawl far too big for her, hood up, bare feet,
	-- a twist of red thread round one wrist. Most of her face is in shadow;
	-- what you can see is a pale chin and a small, knowing smile.
	local shawl, shawlDark, thread = look.torso, rgb(62, 58, 52), rgb(130, 34, 30)
	parts.Head.Color = rgb(14, 12, 12) -- the dark inside the hood
	deco("Head", "Chin", V(0.72, 0.36, 0.1), at(0, -0.33, -0.61), look.skin, MAT.SmoothPlastic)
	deco("Head", "Smile", V(0.32, 0.05, 0.04), at(0.03, -0.37, -0.675) * CFrame.Angles(0, 0, 0.12), rgb(70, 40, 36), MAT.SmoothPlastic)
	deco("Head", "SmileCorner", V(0.07, 0.05, 0.04), at(0.2, -0.345, -0.675) * CFrame.Angles(0, 0, 0.6), rgb(70, 40, 36), MAT.SmoothPlastic)
	deco("Head", "HoodBack", V(1.4, 1.6, 0.32), at(0, 0.1, 0.62), shawl, MAT.Fabric)
	deco("Head", "HoodTop", V(1.42, 0.32, 1.5), at(0, 0.8, 0), shawl, MAT.Fabric)
	deco("Head", "HoodBrim", V(1.44, 0.3, 0.42), at(0, 0.62, -0.62) * CFrame.Angles(0.3, 0, 0), shawlDark, MAT.Fabric)
	deco("Head", "HoodL", V(0.2, 1.55, 1.45), at(-0.68, 0.06, 0), shawl, MAT.Fabric)
	deco("Head", "HoodR", V(0.2, 1.55, 1.45), at(0.68, 0.06, 0), shawl, MAT.Fabric)
	deco("Head", "Fringe", V(0.9, 0.18, 0.06), at(-0.05, 0.33, -0.6), rgb(52, 40, 30), MAT.Fabric) -- a fall of dark hair
	-- her hood comes up in a jester's two points, flopping off either way (the same as the
	-- Dark Hood she gives you: Armor.luau), one in the shawl, one in her red thread
	local Armor = require(game:GetService("ServerScriptService"):WaitForChild("GameServer"):WaitForChild("Armor"))
	Armor.jesterPoints(deco, "Head", Vector3.new(0, 0.9, 0.05) * k.s, 0.4 * k.s, shawl, shawl:Lerp(thread, 0.6), k.s)
	-- the shawl: draped over the shoulders, down past the hips, ragged at the hem
	deco("Chest", "Shawl", V(cw * 1.3, ch * 0.95, cd * 1.35), at(0, -0.05, 0), shawl, MAT.Fabric)
	deco("Chest", "ShawlDrape", V(cw * 1.2, 1.3, 0.12), at(0, -1.2, -cd * 0.65), shawl, MAT.Fabric)
	deco("Chest", "ShawlDrapeB", V(cw * 1.25, 1.5, 0.12), at(0, -1.3, cd * 0.65), shawlDark, MAT.Fabric)
	for i = 0, 3 do
		deco("Chest", "Fray", V(cw * 0.26, 0.3 + (i % 2) * 0.2, 0.1), at(-cw * 0.45 + i * cw * 0.3, -2.0 - (i % 2) * 0.1, -cd * 0.66), shawl:Lerp(rgb(0, 0, 0), 0.2), MAT.Fabric)
	end
	deco("Hips", "Skirt", V(hw * 1.1, 1.2, hd * 1.1), at(0, -0.45, 0), shawlDark, MAT.Fabric)
	for _, n in ipairs({ "R", "L" }) do
		deco(n .. "UpperArm", "Sleeve", V(aw * 1.4, ua * 0.9, aw * 1.4), at(0, 0, 0), shawl, MAT.Fabric)
		parts[n .. "Foot"].Color = look.skin:Lerp(rgb(60, 50, 40), 0.35) -- bare, dirty feet
		parts[n .. "Shin"].Color = look.skin:Lerp(rgb(60, 50, 40), 0.2)
	end
	deco("LLowerArm", "Thread", V(aw * 0.95, 0.07, aw * 0.95), at(0, -la / 2 + 0.25, 0), thread, MAT.Fabric)
	-- eyes: direct children named "Eye"
	for _, x in ipairs({ -0.22, 0.22 }) do
		deco("Head", "Eye", V(0.09, 0.07, 0.05), at(x * 0.9, 0.05, -0.585), rgb(150, 120, 70), MAT.Neon)
	end
end

M.Weapons = {
	-- her candle: a fat stub, held upright in her lap
	Candle = function(w)
		local handle = w.mk("Wax", Vector3.new(0.3, 0.75, 0.3), Color3.fromRGB(214, 202, 172), Enum.Material.SmoothPlastic)
		w.add(w.mk("Flame", Vector3.new(0.14, 0.26, 0.14), Color3.fromRGB(255, 176, 90), Enum.Material.Neon), -0.52)
		return { handle = handle, bladeLen = 0.2 }
	end,
}
M.Grips = {
	-- upright in her lap (the flame is toward the grip's -Y, so flip it up)
	CandleLap = { Vector3.new(0.15, -1.55, -0.85), CFrame.Angles(math.pi, 0, 0) },
}

---------------------------------------------------------------------------
-- server: sitting there, and talking to you
---------------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Map, FxRemote, now, pose, bodyPose, giveWeapon, applyLimbGroup, RigBuilder, Roster

function M.spawn()
	local NPCs = workspace:FindFirstChild("NPCs") or Instance.new("Folder") -- (shared: one folder only)
	NPCs.Name = "NPCs" -- animated by the Puppeteer like everyone else, but never hittable
	NPCs.Parent = workspace
	local WICK_SCALE = 0.72
	local model = RigBuilder.build("Wick", WICK_SCALE)
	model.Name = "Wick"
	pcall(function()
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	local weld = giveWeapon(model, "Candle", WICK_SCALE)
	applyLimbGroup(model)
	model.Parent = NPCs
	local hum = model:FindFirstChildOfClass("Humanoid")
	hum.HipHeight = model:GetAttribute("HipHeight")
	local root = model:FindFirstChild("HumanoidRootPart")
	model:PivotTo(Map.Wick + Vector3.new(0, 3 * WICK_SCALE, 0))
	root.Anchored = true -- she's sitting on her crate; she isn't going anywhere
	local weapon = model:FindFirstChild("Weapon")
	local flame = weapon and weapon:FindFirstChild("Flame")
	if flame then
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(255, 170, 90)
		l.Range = 11
		l.Brightness = 1.4
		l.Parent = flame
		l:SetAttribute("Base", l.Brightness)
		game:GetService("CollectionService"):AddTag(l, "Flicker")
	end
	local actor = { model = model, weld = weld, scale = WICK_SCALE }
	pose(actor, "CandleLap", 0.1)
	bodyPose(actor, "WickSit", 0.1)

	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "Talk"
	pp.ObjectText = "Wick"
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 8
	pp.RequiresLineOfSight = false
	pp.Parent = root

	-- her lines live in ReplicatedStorage/Config -> Config.Wick
	local W = Config.Wick or {}
	local INTRO = W.Intro or {}
	local MORE = W.More or { "..." }
	local AFTER_USHER = W.AfterUsher
	local AFTER_WARDEN = W.AfterWarden
	pp.ObjectText = W.Name or "Wick"

	local talk = {} -- per player: { n = lines heard, usher = said?, warden = said? }
	-- one of her gifts (Config.Armor), put straight on
	local function give(player, key)
		if player:GetAttribute(key) then
			return
		end
		player:SetAttribute(key, true)
		if not Config.wornArmor(player)[key] then
			Config.wearArmor(player, key)
		end
		FxRemote:FireClient(player, "Message", Config.Armor[key].Name .. ". Press T to choose weapons and armor.")
	end
	local busyUntil = 0
	pp.Triggered:Connect(function(player)
		local t = talk[player] or { n = 0 }
		talk[player] = t
		local line
		if Roster.byKind.Warden and Roster.byKind.Warden.isDead() and AFTER_WARDEN and AFTER_WARDEN ~= "" and not t.warden then
			t.warden = true
			line = AFTER_WARDEN
		elseif Roster.byKind.Usher and Roster.byKind.Usher.isDead() and AFTER_USHER and AFTER_USHER ~= "" and not t.usher then
			t.usher = true
			line = AFTER_USHER
			give(player, "DarkHood") -- relieved: the hood that goes with her cloak
		elseif t.n >= #INTRO and not player:GetAttribute("DarkCloak") then
			line = W.CloakLine or "..."
			give(player, "DarkCloak")
		else
			t.n += 1
			line = t.n <= #INTRO and INTRO[t.n] or MORE[(t.n - #INTRO - 1) % #MORE + 1]
		end
		FxRemote:FireClient(player, "Say", W.Name or "Wick", line)
		-- she tilts her head to look at you; a giggle hunches her shoulders
		local giggle = string.find(line, "He he") ~= nil
		bodyPose(actor, giggle and "WickGiggle" or "WickLook", 0.25)
		local now0 = now()
		busyUntil = now0 + 2.2
		task.delay(2.2, function()
			if now() >= busyUntil - 0.01 then
				bodyPose(actor, "WickSit", 0.6)
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
