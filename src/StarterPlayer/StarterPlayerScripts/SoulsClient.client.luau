--!nonstrict
-- SoulsClient: over-the-shoulder follow camera, lock-on, roll/backstep,
-- attacks, flask, HUD, boss bar, and the screens you'll see a lot of.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local StarterGui = game:GetService("StarterGui")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Action = Remotes:WaitForChild("Action")
local Fx = Remotes:WaitForChild("Fx")
local EnemiesFolder = workspace:WaitForChild("Enemies")
local P = Config.Player

task.spawn(function()
	for _ = 1, 20 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false) -- it sat on top of the HUD
		end)
		if ok then
			break
		end
		task.wait(0.25)
	end
end)
-- the newer TextChatService chat window and input bar are separate switches
task.spawn(function()
	local ok, tcs = pcall(function()
		return game:GetService("TextChatService")
	end)
	if not ok or not tcs then
		return
	end
	for _ = 1, 20 do
		local win = tcs:FindFirstChildOfClass("ChatWindowConfiguration")
		local bar = tcs:FindFirstChildOfClass("ChatInputBarConfiguration")
		if win then
			win.Enabled = false
		end
		if bar then
			bar.Enabled = false
		end
		if win and bar then
			break
		end
		task.wait(0.25)
	end
end)

---------------------------------------------------------------------------
-- tuning
---------------------------------------------------------------------------
local SENS = 0.0032
local CAM_DIST = 11
local SHOULDER = 1.7
local CAM_UP = 0.5
local FOV = 68
local CAM_RADIUS = 0.9

---------------------------------------------------------------------------
-- state
---------------------------------------------------------------------------
local char, hum, hrp
local yaw, pitch = 0, -0.25
local focus = nil
local lockTarget = nil
-- the current action, as timestamps (mirrors the server's cancel windows)
local dodgeAt, attackAt = 0, 0 -- from when a roll / an attack may cancel it
local inputFrom = 0 -- presses before this are dropped; after it they're buffered
local slowUntil, slowSpeed = 0, P.WalkSpeed
local rollUntil = 0 -- time-based so it can never get stuck "on"
local freezeUntil = 0 -- hit-stop
local spinReadyAt = 0 -- when the twin blades' spin is off cooldown
local phaseReadyAt = 0 -- when the Foul Dagger's Q is off cooldown
local laserToken = 0 -- bumped by any other action: ends a held Dark Book beam
local runBoost = nil -- { untilT, dir, speed, mult } during a Foul Dagger running attack, until it lands a hit
local spinUntil = 0 -- Caelen's twin blades: you're spinning (Q) until then, steering by walking
local buffered = nil -- { req = "Roll"|"Light"|"Heavy"|"Heal", at = time }; newest press wins
local lastKind, lastStep, comboUntil = nil, 0, 0
local iaiReadyAt = nil -- the Gozen Tachi's stance: when it settles (nil = not in one; doIai)
local recenterYaw = nil -- smooth camera swing behind the character
local sprintHeld = false
local sentSprint = false
local shake = 0
local cursorFree = false
local devFast = false -- P: 5x move speed, for getting around while building the game

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

local function new(class, props)
	local o = Instance.new(class)
	for k, v in pairs(props) do
		if k ~= "Parent" then
			o[k] = v
		end
	end
	if props.Parent then
		o.Parent = props.Parent
	end
	return o
end

local function tween(obj, t, goal, style)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end

---------------------------------------------------------------------------
-- UI
---------------------------------------------------------------------------
local gui = new("ScreenGui", {
	Name = "SoulsUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

local TEXT = Color3.fromRGB(226, 218, 200)
local FONT = Enum.Font.Garamond

local function makeBar(y, width, height, color)
	local frame = new("Frame", {
		Position = UDim2.fromOffset(36, y),
		Size = UDim2.fromOffset(width, height),
		BackgroundColor3 = Color3.fromRGB(12, 10, 10),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Parent = gui,
	})
	new("UIStroke", { Color = Color3.fromRGB(96, 84, 64), Thickness = 1, Parent = frame })
	local chip = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(205, 175, 95), BorderSizePixel = 0, Parent = frame })
	local fill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BorderSizePixel = 0, Parent = frame })
	return frame, fill, chip
end

local hpFrame, hpFill, hpChip = makeBar(32, 300, 12, Color3.fromRGB(150, 22, 20))
local _, stFill, stChip = makeBar(50, 250, 8, Color3.fromRGB(46, 118, 52))
local hpChipV, stChipV = 1, 1

-- poison building up (the township fog): a thin sickly bar under the flask count,
-- shown only while there's any (the server sets PoisonBuild, 0..1)
local poisonBack = new("Frame", {
	Position = UDim2.fromOffset(36, 94),
	Size = UDim2.fromOffset(160, 6),
	BackgroundColor3 = Color3.fromRGB(18, 20, 12),
	BackgroundTransparency = 0.2,
	BorderSizePixel = 0,
	Visible = false,
	Parent = gui,
})
new("UIStroke", { Color = Color3.fromRGB(96, 110, 52), Thickness = 1, Parent = poisonBack })
local poisonFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(150, 178, 70), BorderSizePixel = 0, Parent = poisonBack })

local flaskLabel = new("TextLabel", {
	Position = UDim2.fromOffset(36, 66),
	Size = UDim2.fromOffset(300, 24),
	BackgroundTransparency = 1,
	Font = FONT,
	TextSize = 20,
	TextColor3 = Color3.fromRGB(240, 170, 90),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextStrokeTransparency = 0.5,
	Text = "",
	Parent = gui,
})

-- boss bar
local bossFrame = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -64),
	Size = UDim2.new(0.6, 0, 0, 10),
	BackgroundColor3 = Color3.fromRGB(12, 10, 10),
	BackgroundTransparency = 0.2,
	BorderSizePixel = 0,
	Visible = false,
	Parent = gui,
})
new("UIStroke", { Color = Color3.fromRGB(96, 84, 64), Thickness = 1, Parent = bossFrame })
local bossChip = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(205, 175, 95), BorderSizePixel = 0, Parent = bossFrame })
local bossFill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(140, 18, 16), BorderSizePixel = 0, Parent = bossFrame })
local bossName = new("TextLabel", {
	Position = UDim2.new(0, 0, 0, -28),
	Size = UDim2.new(1, 0, 0, 24),
	BackgroundTransparency = 1,
	Font = FONT,
	TextSize = 24,
	TextColor3 = TEXT,
	TextStrokeTransparency = 0.4,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "",
	Parent = bossFrame,
})
local bossChipV = 1

-- full-screen fade overlay
local overlay = new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
	ZIndex = 5,
	Parent = gui,
})

-- cinema bars, slid in while a cutscene has the camera
local letterbox = {}
for i, y in ipairs({ 0, 1 }) do
	letterbox[i] = new("Frame", {
		AnchorPoint = Vector2.new(0, y),
		Position = UDim2.fromScale(0, y),
		Size = UDim2.fromScale(1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = gui,
	})
end
local cutscene = nil -- { shots = { { fromCF, toCF, seconds }... }, t0, skip = the server's RemoteEvent if skippable, held }

-- a skippable cutscene's "hold SPACE to skip": the bar fills as you hold it (SKIP_HOLD seconds), drains if you let go
local SKIP_HOLD = 1
local skipFrame = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -18),
	Size = UDim2.fromOffset(240, 34),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 6,
	Parent = gui,
})
new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 18),
	BackgroundTransparency = 1,
	Text = "Hold SPACE to skip",
	TextColor3 = Color3.fromRGB(200, 192, 176),
	TextSize = 15,
	Font = FONT,
	ZIndex = 6,
	Parent = skipFrame,
})
local skipTrack = new("Frame", {
	Position = UDim2.fromOffset(0, 24),
	Size = UDim2.new(1, 0, 0, 5),
	BackgroundColor3 = Color3.fromRGB(40, 36, 34),
	BorderSizePixel = 0,
	ZIndex = 6,
	Parent = skipFrame,
})
local skipFill = new("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = Color3.fromRGB(220, 210, 180),
	BorderSizePixel = 0,
	ZIndex = 7,
	Parent = skipTrack,
})

-- red damage vignette
-- the whole screen washed with a colour ("Flash": a blinding blast, or a dip to black between shots)
local flashFrame = new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 20,
	Parent = gui,
})
local vignette = new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(120, 0, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 4,
	Parent = gui,
})
new("UIGradient", {
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.25, 1),
		NumberSequenceKeypoint.new(0.75, 1),
		NumberSequenceKeypoint.new(1, 0),
	}),
	Parent = vignette,
})

-- banner (GAME OVER / area names / victory)
local bannerBack = new("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.fromScale(0, 0.5),
	Size = UDim2.new(1, 0, 0, 140),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 6,
	Parent = gui,
})
new("UIGradient", {
	Rotation = 90,
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0),
		NumberSequenceKeypoint.new(0.7, 0),
		NumberSequenceKeypoint.new(1, 1),
	}),
	Parent = bannerBack,
})
local bannerText = new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Font = FONT,
	TextSize = 72,
	TextColor3 = TEXT,
	TextTransparency = 1,
	RichText = true,
	Text = "",
	ZIndex = 7,
	Parent = gui,
})
bannerText.Parent = bannerBack
local bannerScale = new("UIScale", { Scale = 1, Parent = bannerText })

-- floor-message / hint popup
local messageLabel = new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.74),
	Size = UDim2.new(0.6, 0, 0, 60),
	BackgroundColor3 = Color3.fromRGB(10, 8, 8),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Font = FONT,
	TextSize = 24,
	TextWrapped = true,
	TextColor3 = TEXT,
	TextTransparency = 1,
	Text = "",
	ZIndex = 6,
	Parent = gui,
})

-- someone speaking to you: their name, and the line, low on the screen
local sayFrame = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -40),
	Size = UDim2.new(0.62, 0, 0, 96),
	BackgroundColor3 = Color3.fromRGB(10, 8, 8),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 7,
	Parent = gui,
})
local sayName = new("TextLabel", {
	Position = UDim2.new(0, 0, 0, 4),
	Size = UDim2.new(1, 0, 0, 24),
	BackgroundTransparency = 1,
	Font = FONT,
	TextSize = 22,
	TextColor3 = Color3.fromRGB(226, 200, 150),
	TextTransparency = 1,
	Text = "",
	ZIndex = 8,
	Parent = sayFrame,
})
local sayText = new("TextLabel", {
	Position = UDim2.new(0, 16, 0, 30),
	Size = UDim2.new(1, -32, 1, -36),
	BackgroundTransparency = 1,
	Font = FONT,
	TextSize = 22,
	TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextColor3 = Color3.fromRGB(222, 214, 196),
	TextTransparency = 1,
	Text = "",
	ZIndex = 8,
	Parent = sayFrame,
})
local sayToken = 0

-- lore page reader
local notePanel = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0, 560, 0, 470),
	BackgroundColor3 = Color3.fromRGB(20, 17, 14),
	BackgroundTransparency = 0.08,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 8,
	Parent = gui,
})
new("UIStroke", { Color = Color3.fromRGB(110, 92, 66), Thickness = 1.5, Parent = notePanel })
new("UIPadding", { PaddingLeft = UDim.new(0, 30), PaddingRight = UDim.new(0, 30), PaddingTop = UDim.new(0, 22), PaddingBottom = UDim.new(0, 18), Parent = notePanel })
local noteTitle = new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 34),
	BackgroundTransparency = 1,
	Font = FONT,
	TextSize = 28,
	TextColor3 = Color3.fromRGB(226, 200, 150),
	Text = "",
	ZIndex = 9,
	Parent = notePanel,
})
new("Frame", { Position = UDim2.new(0.15, 0, 0, 40), Size = UDim2.new(0.7, 0, 0, 1), BackgroundColor3 = Color3.fromRGB(110, 92, 66), BorderSizePixel = 0, ZIndex = 9, Parent = notePanel })
local noteBody = new("TextLabel", {
	Position = UDim2.new(0, 0, 0, 52),
	Size = UDim2.new(1, 0, 1, -82),
	BackgroundTransparency = 1,
	Font = FONT,
	TextSize = 19,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextColor3 = Color3.fromRGB(214, 204, 182),
	LineHeight = 1.1,
	Text = "",
	ZIndex = 9,
	Parent = notePanel,
})
new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 20),
	BackgroundTransparency = 1,
	Font = Enum.Font.SourceSans,
	TextSize = 14,
	TextColor3 = Color3.fromRGB(140, 128, 108),
	Text = "Click, Space or Esc to close",
	ZIndex = 9,
	Parent = notePanel,
})
local noteOpenAt = nil -- where you stood when you opened it
local noteOpenedTime = 0

-- chest panel: what's inside on the left, your ring slots on the right. Drag an item
-- onto a slot to take it and wear it (the server moves it: the chest in GameServer).
local LINE = Color3.fromRGB(110, 92, 66)
local CELL = UDim2.fromOffset(72, 104)
local chestPanel = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(560, 330),
	BackgroundColor3 = Color3.fromRGB(20, 17, 14),
	BackgroundTransparency = 0.08,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 8,
	Parent = gui,
})
new("UIStroke", { Color = LINE, Thickness = 1.5, Parent = chestPanel })
for _, h in ipairs({ { "Chest", 24 }, { "Rings", 296 } }) do
	new("TextLabel", { Position = UDim2.fromOffset(h[2], 16), Size = UDim2.fromOffset(240, 30), BackgroundTransparency = 1, Font = FONT, TextSize = 26, TextColor3 = Color3.fromRGB(226, 200, 150), Text = h[1], ZIndex = 9, Parent = chestPanel })
end
new("Frame", { Position = UDim2.fromOffset(280, 20), Size = UDim2.new(0, 1, 1, -60), BackgroundColor3 = LINE, BorderSizePixel = 0, ZIndex = 9, Parent = chestPanel })
local function grid(x)
	local f = new("Frame", { Position = UDim2.fromOffset(x, 58), Size = UDim2.fromOffset(240, 220), BackgroundTransparency = 1, ZIndex = 9, Parent = chestPanel })
	new("UIGridLayout", { CellSize = CELL, CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = f })
	return f
end
local chestGrid, ringGrid = grid(24), grid(296)
local chestEmpty = new("TextLabel", { Position = UDim2.fromOffset(24, 70), Size = UDim2.fromOffset(240, 24), BackgroundTransparency = 1, Font = FONT, TextSize = 18, TextColor3 = Color3.fromRGB(120, 110, 96), Text = "Nothing remains.", Visible = false, ZIndex = 9, Parent = chestPanel })
new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -10),
	Size = UDim2.new(1, 0, 0, 20),
	BackgroundTransparency = 1,
	Font = Enum.Font.SourceSans,
	TextSize = 14,
	TextColor3 = Color3.fromRGB(140, 128, 108),
	Text = "Drag an item onto a ring slot · Esc to close",
	ZIndex = 9,
	Parent = chestPanel,
})
local chestOpenAt = nil
local ringSlots = {} -- the slot boxes, by slot number (drop targets)
local dragging = nil -- { id = ring id, ghost = Frame } while an item is held

local function ringIcon(parent, z)
	local ring = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(34, 34), BackgroundTransparency = 1, ZIndex = z, Parent = parent })
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ring })
	new("UIStroke", { Color = Color3.fromRGB(205, 175, 95), Thickness = 4, Parent = ring })
	return ring
end

-- one cell: a dark square (with the ring in it, if any) and its name underneath
local function itemCell(parent, order, id, emptyText)
	local f = new("Frame", { BackgroundTransparency = 1, LayoutOrder = order, ZIndex = 9, Parent = parent })
	local box = new("Frame", { Size = UDim2.fromOffset(72, 72), BackgroundColor3 = Color3.fromRGB(12, 10, 9), BorderSizePixel = 0, ZIndex = 9, Parent = f })
	new("UIStroke", { Color = LINE, Thickness = 1, Parent = box })
	local def = Config.Rings[id]
	if def then
		ringIcon(box, 10)
	end
	new("TextLabel", { Position = UDim2.fromOffset(-6, 74), Size = UDim2.fromOffset(84, 30), BackgroundTransparency = 1, Font = FONT, TextSize = 14, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = def and TEXT or Color3.fromRGB(120, 110, 96), Text = def and def.Name or emptyText, ZIndex = 9, Parent = f })
	return box
end

local function stopDrag()
	if dragging then
		dragging.ghost:Destroy()
		dragging = nil
	end
end

local function renderChest(items, rings)
	stopDrag()
	for _, g in ipairs({ chestGrid, ringGrid }) do
		for _, c in ipairs(g:GetChildren()) do
			if c:IsA("Frame") then
				c:Destroy()
			end
		end
	end
	for i, id in ipairs(items) do
		itemCell(chestGrid, i, id, "").InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				stopDrag()
				local ghost = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(72, 72), BackgroundTransparency = 1, ZIndex = 12, Parent = gui })
				ringIcon(ghost, 12)
				dragging = { id = id, ghost = ghost }
			end
		end)
	end
	chestEmpty.Visible = #items == 0
	table.clear(ringSlots)
	for i = 1, P.RingSlots do
		ringSlots[i] = itemCell(ringGrid, i, rings[i] or "", "Ring " .. i)
	end
end

local function closeChest()
	stopDrag()
	chestPanel.Visible = false
	chestOpenAt = nil
end

RunService.RenderStepped:Connect(function()
	if dragging then
		local m = UserInputService:GetMouseLocation()
		dragging.ghost.Position = UDim2.fromOffset(m.X, m.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if not dragging or not (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		return
	end
	-- hit-test with the held icon's own centre, not the raw mouse: GetMouseLocation counts
	-- from the top of the screen but AbsolutePosition counts from below the top bar
	local g = dragging.ghost
	local m = g.AbsolutePosition + g.AbsoluteSize / 2
	for slot, box in pairs(ringSlots) do
		local p, s = box.AbsolutePosition, box.AbsoluteSize
		if m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y then
			Action:FireServer("TakeRing", dragging.id, slot)
		end
	end
	stopDrag()
end)

local helpLabel = new("TextLabel", {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 36, 1, -20),
	Size = UDim2.fromOffset(560, 40),
	BackgroundTransparency = 1,
	Font = Enum.Font.SourceSans,
	TextSize = 15,
	TextColor3 = Color3.fromRGB(170, 162, 150),
	TextTransparency = 0.2,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Bottom,
	TextWrapped = true,
	Text = "WASD move · Mouse look · LMB attack · RMB heavy · Space roll (no input = backstep) · Q deflect (Scythe) · T or Tab weapons & armor · K dev menu · R lock-on · Shift run · F Flask · E interact · M free cursor · H hide help",
	Parent = gui,
})

-- lock-on reticle
local reticle = new("BillboardGui", {
	Name = "LockOn",
	Size = UDim2.fromOffset(14, 14),
	AlwaysOnTop = true,
	Enabled = false,
	ResetOnSpawn = false,
	Parent = player.PlayerGui,
})
local dot = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(240, 235, 220), BorderSizePixel = 0, Parent = reticle })
new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
new("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1.5, Transparency = 0.3, Parent = dot })

---------------------------------------------------------------------------
-- banners & messages
---------------------------------------------------------------------------
local bannerToken = 0
local function showBanner(text, style)
	bannerToken += 1
	local my = bannerToken
	local color, size, hold = TEXT, 54, 2.2
	if style == "Death" then
		color, size, hold = Color3.fromRGB(150, 18, 18), 88, 3
	elseif style == "Victory" then
		color, size, hold = Color3.fromRGB(226, 196, 120), 72, 4
	elseif style == "Lit" then
		color, size, hold = Color3.fromRGB(240, 160, 80), 64, 2.5
	elseif style == "Area" then
		color, size, hold = TEXT, 46, 2.2
	elseif style == "Spell" then
		color, size, hold = Color3.fromRGB(150, 205, 235), 64, 6.5
	end
	local title, sub = string.match(text, "^(.-)\n(.+)$") -- (a second line: smaller, dimmer, under the title)
	if sub then
		text = title .. "\n<font size=\"22\" color=\"rgb(200,190,170)\">" .. sub .. "</font>"
	end
	bannerText.Text = text
	bannerText.TextColor3 = color
	bannerText.TextSize = size
	bannerText.TextTransparency = 1
	bannerBack.BackgroundTransparency = 1
	bannerScale.Scale = 0.96
	tween(bannerText, 1.4, { TextTransparency = 0 })
	tween(bannerBack, 1.4, { BackgroundTransparency = style == "Area" and 0.6 or 0.3 })
	tween(bannerScale, 1.4 + hold + 1.5, { Scale = 1.05 }, Enum.EasingStyle.Linear)
	task.delay(1.4 + hold, function()
		if my ~= bannerToken then
			return
		end
		tween(bannerText, 1.5, { TextTransparency = 1 })
		tween(bannerBack, 1.5, { BackgroundTransparency = 1 })
	end)
end

local messageToken = 0
local function showMessage(text)
	messageToken += 1
	local my = messageToken
	messageLabel.Text = text
	tween(messageLabel, 0.3, { TextTransparency = 0, BackgroundTransparency = 0.45 })
	task.delay(4.5, function()
		if my == messageToken then
			tween(messageLabel, 0.8, { TextTransparency = 1, BackgroundTransparency = 1 })
		end
	end)
end

---------------------------------------------------------------------------
-- movement helpers
---------------------------------------------------------------------------
local function faceDir(dir)
	if not hrp then
		return
	end
	dir = flat(dir)
	if dir.Magnitude < 0.01 then
		return
	end
	hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + dir.Unit)
end

local activePush = nil -- cleanup fn for the push in progress
local function pushVelocity(dir, speed, duration, decay)
	if not hrp or flat(dir).Magnitude < 0.01 then
		return
	end
	if activePush then
		activePush() -- a new push (roll, knockback) replaces the old one
	end
	dir = flat(dir).Unit
	local att = Instance.new("Attachment")
	att.Name = "PushAttachment"
	att.Parent = hrp
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
	lv.LineDirection = dir
	lv.LineVelocity = speed
	lv.MaxForce = 1e5
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.Parent = hrp
	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local a = (os.clock() - t0) / duration
		if a >= 1 or not lv.Parent then
			conn:Disconnect()
			return
		end
		lv.LineVelocity = speed * (1 - a * (decay or 0.5))
	end)
	local function cleanup()
		if conn.Connected then
			conn:Disconnect()
		end
		lv:Destroy()
		att:Destroy()
	end
	activePush = cleanup
	-- guaranteed cleanup, no matter what happens to the connection
	task.delay(duration, cleanup)
end

local function validTarget(m)
	if not m or not m.Parent then
		return false
	end
	local h = m:FindFirstChildOfClass("Humanoid")
	local r = m:FindFirstChild("HumanoidRootPart")
	return h ~= nil and r ~= nil and h.Health > 0
end

local function stamina()
	return player:GetAttribute("Stamina") or 0
end

local function isRolling()
	return os.clock() < rollUntil
end

local function alive()
	return hum ~= nil and hrp ~= nil and hum.Health > 0
end

-- if physics knocked the humanoid over, stand it back up
local function fixHumanoidState()
	if not hum or hum.Health <= 0 then
		return
	end
	hum.PlatformStand = false
	hum.Sit = false
	local s = hum:GetState()
	if s == Enum.HumanoidStateType.FallingDown or s == Enum.HumanoidStateType.Ragdoll
		or s == Enum.HumanoidStateType.Physics or s == Enum.HumanoidStateType.PlatformStanding then
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

local function setAction(t, total, dodgeAfter, attackAfter, inputAfter)
	laserToken += 1
	iaiReadyAt = nil -- anything else you do stands you up out of the Tachi's stance
	dodgeAt = t + (dodgeAfter or total)
	attackAt = t + (attackAfter or total)
	inputFrom = t + (inputAfter or 0)
end

local function ready(req)
	if os.clock() < freezeUntil then
		return false
	end
	if req == "Deflect" and Config.weaponOf(player).Spin then
		return os.clock() >= attackAt
	end
	if req == "Deflect" and Config.weaponOf(player).Iai then
		-- the Tachi's Q: the draw once the stance settles; a sheathe only once you could
		-- attack (as the server allows it), never earlier
		return os.clock() >= (iaiReadyAt or attackAt)
	end
	if req == "Roll" or req == "Deflect" then
		return os.clock() >= dodgeAt
	end
	return os.clock() >= attackAt
end

---------------------------------------------------------------------------
-- actions (each returns true if it actually happened)
---------------------------------------------------------------------------
-- the Gozen Tachi's Q (Config.TachiDraw): it sheathes; from then you're rooted in the
-- stance (iaiReadyAt set) and the next Q draws - queued if it's still going home. Holding
-- W as you draw: a dash forward. A roll leaves the stance any time, A/S/D from CancelAfter
-- on (updateMovement). The server runs it all and has the last word.
local function doIai()
	local D = Config.TachiDraw
	local t0 = os.clock()
	if iaiReadyAt then
		if stamina() <= 0 then
			return false
		end
		local dash = UserInputService:IsKeyDown(Enum.KeyCode.W)
		iaiReadyAt = nil
		Action:FireServer("Iai", dash)
		local a = dash and D.DashAttack or D.Attack
		local total = a.Windup + a.Swing + a.Recover
		local C = Config.Combat
		setAction(t0, total, a.Windup + a.Swing + a.Recover * C.DodgeCancel, a.Windup + a.Swing + a.Recover * C.AttackCancel, a.Windup + a.Swing)
		lastKind = nil
		if lockTarget and validTarget(lockTarget) then
			faceDir(lockTarget.HumanoidRootPart.Position - hrp.Position)
		end
		if dash then
			pushVelocity(flat(hrp.CFrame.LookVector).Unit, D.DashSpeed, D.DashTime, 0.6)
			slowUntil, slowSpeed = t0 + total, 2
		end
		return true
	end
	Action:FireServer("Iai")
	-- Q again is ready (and queues) from when it's settled; other actions (and a roll) any time
	setAction(t0, D.SheatheTime, 0, D.SheatheTime, 0)
	iaiReadyAt = t0 + D.SheatheTime
	lastKind = nil
	return true
end
player:GetAttributeChangedSignal("IaiReady"):Connect(function()
	-- the server broke the stance (it had settled): stand up here too
	if not player:GetAttribute("IaiReady") and iaiReadyAt and os.clock() > iaiReadyAt then
		iaiReadyAt = nil
	end
end)

-- the twin blades' Q (Config.CaelenSpin): the server deals the damage; here you turn round
-- at Yaw rad/s and walk as normal. A roll or a hit ends it
local function doSpin()
	local D = Config.CaelenSpin
	if stamina() <= 0 or os.clock() < spinReadyAt then
		return false
	end
	Action:FireServer("Spin")
	local t0 = os.clock()
	spinReadyAt = t0 + D.Duration + D.Cooldown
	setAction(t0, D.Duration, D.Duration * 0.3, D.Duration, D.Duration)
	slowUntil = 0
	lastKind = nil
	spinUntil = t0 + D.Duration
	local yaw = select(2, hrp.CFrame:ToOrientation())
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if os.clock() >= spinUntil or not alive() or isRolling() or os.clock() < freezeUntil then
			spinUntil = 0
			conn:Disconnect()
			return
		end
		yaw += D.Yaw * dt
		hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, yaw, 0)
	end)
	return true
end

-- the Foul Dagger's Q (Config.FoulPhase): the server does all of it; this just keeps the cooldown
local function doPhase()
	if os.clock() < phaseReadyAt then
		return false
	end
	Action:FireServer("Deflect")
	phaseReadyAt = os.clock() + Config.FoulPhase.Cooldown
	return true
end

local deflectAt = nil -- when the twirl in progress started (a hit clears it)
local function doDeflect()
	if Config.weaponOf(player).Phase then
		return doPhase()
	end
	if Config.weaponOf(player).Spin then
		return doSpin()
	end
	if Config.weaponOf(player).Iai then
		return doIai()
	end
	if player:GetAttribute("Weapon") ~= "Scythe" then
		return false
	end
	if stamina() <= 0 then
		return false
	end
	Action:FireServer("Deflect")
	local t0 = os.clock()
	local CFG = Config.ScytheDeflect
	local twirl = CFG.Twirl
	local dur = twirl + CFG.Duration
	rollUntil = t0 + dur
	setAction(t0, dur, twirl + CFG.Duration * 0.7, twirl + CFG.Duration * 0.75, twirl + CFG.Duration * 0.2)
	slowUntil, slowSpeed = t0 + dur, 3
	lastKind = nil
	if lockTarget and validTarget(lockTarget) then
		faceDir(lockTarget.HumanoidRootPart.Position - hrp.Position)
	else
		faceDir(workspace.CurrentCamera.CFrame.LookVector)
	end

	-- the beat, played locally so it's on time: whoosh, whoosh, CLICK (= the deflect frames open)
	local function beat(id, volume, speed)
		local s = Instance.new("Sound")
		s.SoundId = id
		s.Volume = volume
		s.PlaybackSpeed = speed
		s.Parent = workspace.CurrentCamera
		s:Play()
		Debris:AddItem(s, 2)
	end
	deflectAt = t0
	beat(CFG.TwirlSound, 0.35, 1.5)
	task.delay(twirl / 2, function()
		if deflectAt == t0 then
			beat(CFG.TwirlSound, 0.35, 1.7)
		end
	end)

	-- Instant local pose prediction: twirl overhead, then the guard
	if char then
		char:SetAttribute("BP", "Twirl")
		char:SetAttribute("BPT", 0.08)
		char:SetAttribute("BPN", t0)
	end
	task.delay(twirl, function()
		if deflectAt ~= t0 then
			return -- a hit broke the twirl: no click, no guard
		end
		beat(CFG.ClickSound, 0.9, 1.0)
		if char then
			char:SetAttribute("BP", "Deflect")
			char:SetAttribute("BPT", 0.04)
			char:SetAttribute("BPN", os.clock())
		end
	end)
	return true
end

local function doRoll()
	if stamina() <= 0 or player:GetAttribute("Broken") then -- (BROKEN: no rolling, Config.Break)
		return false
	end
	local move = flat(hum.MoveDirection)
	local back = move.Magnitude < 0.1
	local locked = lockTarget ~= nil and validTarget(lockTarget)
	Action:FireServer(back and "Backstep" or "Roll")

	local dir, dur, speed
	if back then
		dir = -flat(hrp.CFrame.LookVector).Unit
		dur, speed = P.BackstepDuration, P.BackstepSpeed
	else
		dir = move.Unit
		dur, speed = P.RollDuration, P.RollSpeed
		-- locked on: roll in any of 4 directions while still facing the target
		if not locked then
			faceDir(dir)
		end
	end
	local t0 = os.clock()
	rollUntil = t0 + dur
	setAction(t0, dur, dur * 0.8, dur * 0.8, dur * 0.25)
	slowUntil = 0
	lastKind = nil
	hum.AutoRotate = false
	pushVelocity(dir, speed, dur * 0.9, 0.55)

	-- ROLL ANIMATION (played by the Puppeteer), timed exactly to the i-frame window:
	-- a tucked somersault around the axis "over the top" toward the roll direction.
	local localDir = flat(hrp.CFrame:VectorToObjectSpace(dir))
	localDir = localDir.Magnitude > 0.01 and localDir.Unit or Vector3.new(0, 0, -1)
	local iStart = P.IFrameStart
	local iEnd = back and P.BackstepIFrameEnd or P.IFrameEnd
	char:SetAttribute("DownT0", 0) -- rolling out of a knockdown
	char:SetAttribute("RollAxis", Vector3.yAxis:Cross(localDir))
	char:SetAttribute("RollBack", back)
	char:SetAttribute("RollDur", iEnd - iStart)
	char:SetAttribute("RollT0", os.clock() + iStart)
	task.delay(dur + 0.03, function()
		if os.clock() >= rollUntil then
			fixHumanoidState()
		end
	end)
	return true
end

local function nextComboStep(kind)
	if kind ~= "Light" then
		return 1
	end
	if lastKind == "Light" and os.clock() <= comboUntil then
		return lastStep % #Config.weaponOf(player).Attacks.Light + 1
	end
	return 1
end

local function doAttack(kind)
	if stamina() <= 0 or (kind == "Light" and Config.weaponOf(player).NoLight) then
		return false
	end
	local C = Config.Combat
	-- light attack while moving = running attack (you keep your momentum)
	local moveIn = flat(hum.MoveDirection)
	local speedNow = flat(hrp.AssemblyLinearVelocity).Magnitude
	local L = kind == "Light" and Config.weaponOf(player).Attacks.Light[1].Laser
	local holdLaser = L and L.Hold
	local running = not holdLaser and kind == "Light" and moveIn.Magnitude > 0.1 and speedNow >= C.RunAttackMinSpeed
	if running then
		kind = "Running"
	end
	local step = running and 1 or nextComboStep(kind)
	local list = Config.weaponOf(player).Attacks[kind]
	local a = list[math.min(step, #list)]
	-- where a spell goes (the Old Book): at your lock-on target, or where the camera looks
	local aim = workspace.CurrentCamera.CFrame.LookVector
	if lockTarget and validTarget(lockTarget) then
		aim = (lockTarget.HumanoidRootPart.Position - hrp.Position).Unit
	end
	Action:FireServer("Attack", kind, step, aim)
	local t = os.clock()
	local total = a.Windup + a.Swing + a.Recover
	local cancelAttack = a.Windup + a.Swing + a.Recover * C.AttackCancel
	setAction(t, total, a.Windup + a.Swing + a.Recover * C.DodgeCancel, cancelAttack, a.Windup * 0.5)
	if running then
		lastKind, lastStep, comboUntil = "Light", 2, t + total + C.ComboGrace -- next light = backhand
		local dir = moveIn.Unit
		faceDir(dir)
		-- carry the run through the swing; it only bleeds off right at the end
		pushVelocity(dir, math.max(speedNow, a.CarrySpeed), total * a.Carry, 0.25)
		slowUntil, slowSpeed = t + total * a.Carry, 2
		local mult = Config.weaponOf(player).RunBoost
		runBoost = mult and { untilT = t + total * a.Carry, dir = dir, speed = math.max(speedNow, a.CarrySpeed), mult = mult } or nil
		return true
	end
	lastKind, lastStep, comboUntil = kind, step, t + total + C.ComboGrace
	slowUntil, slowSpeed = t + cancelAttack, kind == "Heavy" and 9 or 3 -- you can still walk through a heavy
	if lockTarget and validTarget(lockTarget) then
		faceDir(lockTarget.HumanoidRootPart.Position - hrp.Position)
	elseif moveIn.Magnitude > 0.1 then
		faceDir(moveIn)
	else
		faceDir(workspace.CurrentCamera.CFrame.LookVector)
	end
	task.delay(a.Windup, function()
		if alive() then
			pushVelocity(hrp.CFrame.LookVector, kind == "Heavy" and 14 or 10, 0.14, 0.8)
		end
	end)
	if holdLaser then
		-- the Dark Book's beam: held out while the button is down and stamina lasts (the server drains
		-- it); you walk slowly and face where it points, and it follows your aim
		laserToken += 1
		local token, since, sent, stopped = laserToken, t + a.Windup + L.Duration, 0, false
		task.spawn(function()
			local function held()
				return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
					or UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonR1)
			end
			while laserToken == token and alive() do
				RunService.Heartbeat:Wait()
				local now = os.clock()
				local down = held()
				if not down and not stopped then
					stopped = true -- (a tap: the server's beam then lasts its Duration and no more)
					Action:FireServer("LaserStop")
				end
				if now >= since then
					if not down or stamina() <= 0 then
						break
					end
					attackAt, slowUntil, slowSpeed = now + 0.1, now + 0.1, 5
				end
				local look = workspace.CurrentCamera.CFrame.LookVector
				if lockTarget and validTarget(lockTarget) then
					look = (lockTarget.HumanoidRootPart.Position - hrp.Position).Unit
				end
				if now >= since then
					faceDir(look)
				end
				if now - sent > 0.05 then
					sent = now
					Action:FireServer("LaserAim", look)
				end
			end
			Action:FireServer("LaserStop")
			if laserToken == token then
				attackAt, slowUntil = os.clock() + 0.25, 0
			end
		end)
	end
	return true
end

local function doHeal()
	if (player:GetAttribute("Flasks") or 0) <= 0 then
		showMessage("Your flask is empty.")
		return false
	end
	Action:FireServer("Heal")
	local t = os.clock()
	setAction(t, P.FlaskTime + 0.02, P.FlaskTime, P.FlaskTime, P.FlaskTime * 0.6)
	slowUntil, slowSpeed = t + P.FlaskTime, 4
	lastKind = nil
	return true
end

local DO = {
	Roll = doRoll,
	Deflect = doDeflect,
	Light = function()
		return doAttack("Light")
	end,
	Heavy = function()
		return doAttack("Heavy")
	end,
	Heal = doHeal,
}

-- A press either happens now, or (if the current action has reached its input
-- window) waits in a one-slot buffer until the action can be cancelled into it.
local function closeNote()
	notePanel.Visible = false
	noteOpenAt = nil
end

local function request(req)
	if not alive() then
		return
	end
	if ready(req) then
		buffered = nil
		DO[req]()
	elseif os.clock() >= inputFrom then
		buffered = { req = req, at = os.clock() }
	end
end

local function updateBuffer()
	if not buffered then
		return
	end
	if not alive() or os.clock() - buffered.at > Config.Combat.BufferTime then
		buffered = nil
		return
	end
	if ready(buffered.req) then
		local req = buffered.req
		buffered = nil
		DO[req]()
	end
end

-- Hit reactions: flinch / stagger / big stagger / knockdown
local function onHurt(dir, level)
	local r = Config.HitReactions[level] or Config.HitReactions.Medium
	local t = os.clock()
	buffered = nil
	lastKind = nil
	deflectAt = nil
	setAction(t, r.Stun, r.RollOut or r.Stun, r.Stun, r.Stun * 0.5)
	local staggered = level == "Stagger"
	slowUntil, slowSpeed = t + r.Stun, staggered and 0 or 1 -- a stagger roots you to the spot
	shake = math.max(shake, r.Down and 1 or level == "Large" and 0.7 or staggered and 0.6 or 0.4)
	pushVelocity(dir, r.Push, r.PushTime or (r.Down and 0.35 or 0.18), 0.7)
	if r.Lift and hrp then
		hrp.AssemblyLinearVelocity += Vector3.new(0, r.Lift, 0) -- (thrown up into the air: Launch)
	end
	-- a stagger flashes pale instead of red, so it reads as "knocked off balance", not just hurt
	vignette.BackgroundColor3 = staggered and Color3.fromRGB(230, 210, 150) or Color3.fromRGB(120, 0, 0)
	vignette.BackgroundTransparency = staggered and 0.15 or 0.25
	tween(vignette, staggered and r.Stun + 0.15 or 0.6, { BackgroundTransparency = 1 })
	if not char then
		return
	end
	if r.Down then
		-- thrown onto your back (the Puppeteer animates it)
		char:SetAttribute("RollT0", 0)
		char:SetAttribute("DownGetUp", math.max(r.Stun - 0.45, 0.3))
		char:SetAttribute("DownDur", r.Stun)
		char:SetAttribute("DownT0", t)
	else
		-- flinch / stagger body pose, locally and immediately
		char:SetAttribute("BP", (level == "Large" or staggered) and "Stagger" or "Flinch")
		char:SetAttribute("BPT", staggered and 0.05 or 0.08)
		char:SetAttribute("BPN", t)
		task.delay(r.Stun, function()
			if char and char:GetAttribute("BPN") == t then
				char:SetAttribute("BP", "Idle")
				char:SetAttribute("BPT", 0.3)
				char:SetAttribute("BPN", t + 0.001)
			end
		end)
	end
end

local function findLockTarget()
	if not hrp then
		return nil
	end
	local best, bestScore
	local camLook = flat(workspace.CurrentCamera.CFrame.LookVector).Unit
	local bossOnly = ReplicatedStorage:GetAttribute("BossActive") == true -- (a boss fight on: nothing else to lock onto)
	for _, m in ipairs(EnemiesFolder:GetChildren()) do
		if validTarget(m) and (not bossOnly or m:GetAttribute("Boss")) then
			local rel = flat(m.HumanoidRootPart.Position - hrp.Position)
			local d = rel.Magnitude
			if d < 45 then
				local ang = d > 0.1 and math.acos(math.clamp(rel.Unit:Dot(camLook), -1, 1)) or 0
				-- anything in your front 180 degrees beats anything behind you; within it, the nearer the
				-- middle of your view (then the nearer to you) the better
				local score = d + ang * 40 + (ang > math.rad(90) and 10000 or 0)
				if not bestScore or score < bestScore then
					best, bestScore = m, score
				end
			end
		end
	end
	return best
end

-- a boss fight begun (the bar up: for the Consul, as each of his cutscenes ends): locked onto him at once
ReplicatedStorage:GetAttributeChangedSignal("BossActive"):Connect(function()
	if ReplicatedStorage:GetAttribute("BossActive") ~= true or not hrp then
		return
	end
	for _, m in ipairs(EnemiesFolder:GetChildren()) do
		if m:GetAttribute("Boss") and validTarget(m) and (m.HumanoidRootPart.Position - hrp.Position).Magnitude < 60 then
			lockTarget = m
			return
		end
	end
end)

local function toggleLock()
	if lockTarget then
		lockTarget = nil
	else
		lockTarget = findLockTarget()
		if not lockTarget and hrp then
			-- nothing to lock onto: swing the camera round behind the character
			local lv = hrp.CFrame.LookVector
			recenterYaw = math.atan2(-lv.X, -lv.Z)
		end
	end
end

-- Personal space: you can't walk through enemies, and since character roots
-- don't physically collide any more, you can't climb onto them either.
local function separateFromEnemies()
	if not alive() then
		return
	end
	local pos = hrp.Position
	local push = Vector3.zero
	for _, m in ipairs(EnemiesFolder:GetChildren()) do
		local r = m:FindFirstChild("HumanoidRootPart")
		local h = m:FindFirstChildOfClass("Humanoid")
		if r and h and h.Health > 0 then
			local radius = m:GetAttribute("Radius") or 1.2
			local rel = flat(pos - r.Position)
			local minD = Config.Combat.PlayerRadius + radius
			local d = rel.Magnitude
			if d < minD and math.abs(pos.Y - r.Position.Y) < radius * 2 + 4 then
				local away = d > 0.05 and rel.Unit or -flat(hrp.CFrame.LookVector).Unit
				push += away * (minD - d)
			end
		end
	end
	if push.Magnitude > 0.001 then
		hrp.CFrame = hrp.CFrame + push
		-- also kill any velocity driving us into them
		local v = hrp.AssemblyLinearVelocity
		local n = push.Unit
		local into = v:Dot(n)
		if into < 0 then
			hrp.AssemblyLinearVelocity = v - n * into
		end
	end
end

---------------------------------------------------------------------------
-- dev menu (K): cheats for getting around while building the game
---------------------------------------------------------------------------
local function toggleDevFast()
	devFast = not devFast
	showMessage(devFast and "Dev speed ON (x5)." or "Dev speed off.")
	-- shortcut: temporary movement readout while hunting the "can't walk" bug; delete once found
	if hum and hrp then
		local c = os.clock()
		local bits = {}
		for _, d in ipairs(hrp:GetChildren()) do
			if d:IsA("Constraint") or d:IsA("BodyMover") then
				table.insert(bits, d.ClassName .. ":" .. d.Name)
			end
		end
		print(string.format("[MoveDebug] state=%s ws=%.1f moveDir=%s platform=%s sit=%s anchored=%s hip=%.2f floor=%s vel=%s",
			tostring(hum:GetState()), hum.WalkSpeed, tostring(hum.MoveDirection), tostring(hum.PlatformStand), tostring(hum.Sit),
			tostring(hrp.Anchored), hum.HipHeight, tostring(hum.FloorMaterial), tostring(hrp.AssemblyLinearVelocity)))
		print(string.format("[MoveDebug] slowFor=%.2f slowSpeed=%s freezeFor=%.2f rollFor=%.2f inFog=%s lock=%s movers=[%s] pos=%s",
			slowUntil - c, tostring(slowSpeed), freezeUntil - c, rollUntil - c, tostring(player:GetAttribute("InFog")),
			tostring(lockTarget), table.concat(bits, ", "), tostring(hrp.Position)))
	end
end

local devPanel = new("Frame", {
	Name = "DevMenu",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -36, 0.5, 0),
	Size = UDim2.fromOffset(250, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = Color3.fromRGB(14, 12, 12),
	BackgroundTransparency = 0.12,
	BorderSizePixel = 0,
	Visible = false,
	Parent = gui,
})
new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = devPanel })
new("UIStroke", { Color = Color3.fromRGB(90, 80, 64), Thickness = 1, Parent = devPanel })
new("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = devPanel })
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = devPanel })
new("TextLabel", {
	LayoutOrder = 0,
	Size = UDim2.new(1, 0, 0, 22),
	BackgroundTransparency = 1,
	Font = FONT,
	TextSize = 20,
	TextColor3 = Color3.fromRGB(220, 200, 160),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Dev menu  (K to close)",
	Parent = devPanel,
})
local function devButton(order, onClick)
	local b = new("TextButton", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = Color3.fromRGB(40, 34, 30),
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Font = Enum.Font.SourceSansSemibold,
		TextSize = 17,
		TextColor3 = Color3.fromRGB(230, 220, 200),
		Parent = devPanel,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 4), Parent = b })
	b.Activated:Connect(onClick)
	return b
end
local speedButton
local function devRefresh()
	speedButton.Text = devFast and "Dev speed (x5): ON" or "Dev speed (x5): OFF"
end
devButton(1, function()
	Action:FireServer("DevGive", "Scythe")
end).Text = "Give Scythe"
devButton(5, function()
	Action:FireServer("DevGive", "CastellanMace")
end).Text = "Give Castellan's Mace"
speedButton = devButton(2, function()
	toggleDevFast()
	devRefresh()
end)
devButton(3, function()
	Action:FireServer("DevLadder")
end).Text = "Drop the yard ladder"
devButton(4, function()
	Action:FireServer("DevKeepStair")
end).Text = "Teleport: keep's spiral stair"
devButton(6, function()
	Action:FireServer("DevNewArea")
end).Text = "Teleport: beyond the township"
devButton(8, function()
	Action:FireServer("DevGive", "GozenTachi")
end).Text = "Give Gozen Tachi"
devButton(9, function()
	Action:FireServer("DevGive", "OldBook")
end).Text = "Give Old Book"
devButton(12, function()
	Action:FireServer("DevTownship")
end).Text = "Teleport: past the Warden, into the township (dogs)"
devButton(10, function()
	Action:FireServer("DevGiveAll")
end).Text = "Give every weapon and armor"
devButton(11, function()
	Action:FireServer("DevSplinters")
end).Text = "Give 10 Bone Splinters"
devButton(7, function()
	Action:FireServer("DevCastellanHP")
end).Text = "Castellan's health to 1"
devButton(13, function()
	Action:FireServer("DevColosseum")
end).Text = "Teleport: outside the Crowned Colosseum"
devButton(14, function()
	Action:FireServer("DevChampionHP")
end).Text = "Champion's health to 1"
devButton(15, function()
	Action:FireServer("DevMesa")
end).Text = "Teleport: the mesa town (over the Blind Chapel)"
devButton(16, function()
	Action:FireServer("DevCitadel")
end).Text = "Teleport: the citadel gate (before the mansion)"
devButton(17, function()
	Action:FireServer("DevAtticStair")
end).Text = "Teleport: foot of the mansion's attic stair"
devButton(19, function()
	Action:FireServer("DevFallenStair")
end).Text = "Teleport: stair down to the one-way cell door"
devButton(18, function()
	Action:FireServer("DevConsulHP")
end).Text = "Consul's health to 1 (his rise)"
devRefresh()

-- the equipment menu (T / Tab), Dark Souls 2 style: your five slots down the left (weapon, head,
-- body, two rings), and what you've found for the selected slot on the right. Click a piece to
-- put it on; click the worn one to take armor off. Rings only move at a chest (see chestPanel).
local equipPanel
do
	local GOLD = Color3.fromRGB(205, 175, 95)
	local DIM = Color3.fromRGB(120, 110, 96)
	local SLOTS = {
		{ id = "Weapon", label = "Weapon" },
		{ id = "Head", label = "Head" },
		{ id = "Body", label = "Body" },
		{ id = "Ring1", label = "Ring 1" },
		{ id = "Ring2", label = "Ring 2" },
	}
	equipPanel = new("Frame", {
		Name = "EquipMenu",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(680, 440),
		BackgroundColor3 = Color3.fromRGB(10, 9, 8),
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		Visible = false,
		Parent = gui,
	})
	new("UIStroke", { Color = LINE, Thickness = 1.5, Parent = equipPanel })
	local function label(parent, x, y, w, h, size, color, text, align)
		return new("TextLabel", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, Font = FONT, TextSize = size, TextColor3 = color, TextXAlignment = align or Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = text, Parent = parent })
	end
	label(equipPanel, 24, 14, 300, 30, 28, Color3.fromRGB(226, 200, 150), "Equipment")
	label(equipPanel, 0, 414, 680, 20, 14, Color3.fromRGB(140, 128, 108), "Select a slot · click a piece to equip it · T or Esc to close", Enum.TextXAlignment.Center)
	new("Frame", { Position = UDim2.fromOffset(290, 56), Size = UDim2.fromOffset(1, 340), BackgroundColor3 = LINE, BorderSizePixel = 0, Parent = equipPanel })
	local slotBox = new("Frame", { Position = UDim2.fromOffset(24, 56), Size = UDim2.fromOffset(250, 340), BackgroundTransparency = 1, Parent = equipPanel })
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = slotBox })
	local listBox = new("ScrollingFrame", { Position = UDim2.fromOffset(306, 90), Size = UDim2.fromOffset(350, 306), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = equipPanel })
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = listBox })
	local header = label(equipPanel, 306, 56, 350, 28, 22, GOLD, "")
	local selected = "Weapon"

	-- what's on in a slot: key, def (Motley fills both Head and Body)
	local function worn(slot)
		if slot == "Weapon" then
			local key = player:GetAttribute("Weapon") or "Sword"
			return key, Config.Weapons[key]
		elseif slot == "Head" or slot == "Body" then
			local key = player:GetAttribute("Armor" .. slot)
			return key, key and Config.Armor[key]
		end
		local key = player:GetAttribute(slot)
		return key, key and Config.Rings[key]
	end
	local function entry(order, def, on, onClick)
		local b = new("TextButton", { LayoutOrder = order, Size = UDim2.new(1, -8, 0, 52), BackgroundColor3 = on and Color3.fromRGB(46, 38, 28) or Color3.fromRGB(24, 21, 18), BorderSizePixel = 0, AutoButtonColor = true, Text = "", Parent = listBox })
		new("UIStroke", { Color = on and GOLD or LINE, Thickness = on and 1.5 or 1, Parent = b })
		label(b, 12, 4, 320, 24, 20, TEXT, (on and "◆ " or "") .. def.Name)
		label(b, 12, 28, 320, 20, 15, DIM, def.Note or "")
		b.Activated:Connect(onClick)
	end

	local function refresh()
		for _, c in ipairs(slotBox:GetChildren()) do
			if c:IsA("GuiButton") then
				c:Destroy()
			end
		end
		for _, c in ipairs(listBox:GetChildren()) do
			if c:IsA("GuiButton") or c:IsA("TextLabel") then
				c:Destroy()
			end
		end
		for i, s in ipairs(SLOTS) do
			local key, def = worn(s.id)
			local sel = s.id == selected
			local b = new("TextButton", { LayoutOrder = i, Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = sel and Color3.fromRGB(46, 38, 28) or Color3.fromRGB(18, 16, 14), BorderSizePixel = 0, AutoButtonColor = false, Text = "", Parent = slotBox })
			new("UIStroke", { Color = sel and GOLD or LINE, Thickness = sel and 2 or 1, Parent = b })
			local icon = new("Frame", { Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(48, 48), BackgroundColor3 = Color3.fromRGB(12, 10, 9), BorderSizePixel = 0, Parent = b })
			new("UIStroke", { Color = LINE, Thickness = 1, Parent = icon })
			if def then
				if s.id:sub(1, 4) == "Ring" then
					ringIcon(icon, 2)
				else
					new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = FONT, TextSize = 32, TextColor3 = GOLD, Text = def.Name:sub(1, 1), Parent = icon })
				end
			end
			label(b, 64, 8, 178, 18, 14, DIM, s.label)
			label(b, 64, 28, 178, 24, 19, def and TEXT or DIM, def and def.Name or "— empty —")
			b.Activated:Connect(function()
				selected = s.id
				refresh()
			end)
		end

		header.Text = (selected:sub(1, 4) == "Ring" and "Rings" or selected)
		local n = 0
		if selected == "Weapon" then
			local held = worn("Weapon")
			for _, key in ipairs(Config.WeaponOrder) do
				local def = Config.Weapons[key]
				if def and (key == "Sword" or player:GetAttribute("Has_" .. key)) then
					n += 1
					entry(n, def, key == held, function()
						Action:FireServer("Equip", key)
					end)
				end
			end
		elseif selected == "Head" or selected == "Body" then
			local on = worn(selected)
			for _, key in ipairs(Config.ArmorOrder) do
				local def = Config.Armor[key]
				if player:GetAttribute(key) == true and table.find(def.Slots, selected) then
					n += 1
					entry(n, def, key == on, function()
						Action:FireServer("WearArmor", key)
					end)
				end
			end
		else
			label(listBox, 0, 0, 340, 44, 17, DIM, "Rings are set at a chest.").TextWrapped = true
			n = 1
		end
		if n == 0 then
			label(listBox, 0, 0, 340, 24, 17, DIM, "Nothing found yet.")
		end
	end
	player.AttributeChanged:Connect(function(name)
		if name == "Weapon" or name:sub(1, 4) == "Has_" or name:sub(1, 5) == "Armor" or name:sub(1, 4) == "Ring" or Config.Armor[name] then
			refresh()
		end
	end)
	refresh()
end
-- T or Tab opens it (toggled in the input handler below, which sees every key press;
-- this bind only stops Roblox opening its player list on Tab).
ContextActionService:BindActionAtPriority("SoulsWeapons", function()
	if UserInputService:GetFocusedTextBox() then
		return Enum.ContextActionResult.Pass
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.ContextActionPriority.High.Value + 10, Enum.KeyCode.Tab)

-- THE BONFIRE MENU: opens every time you rest, Level Up on the left and Travel on the right. Level Up:
-- each click spends one Bone Splinter on a stat (Config.Stats; the server checks you're at a bonfire).
-- Travel: the bonfires you've rested at (the server's "Bonfire_<n>" attributes); click one to be carried
-- there - once the Consul's spell is broken (ReplicatedStorage "BonfireTravel").
local levelPanel
local levelRefresh
do
	local GOLD = Color3.fromRGB(205, 175, 95)
	local DIM = Color3.fromRGB(120, 110, 96)
	local ROW = Color3.fromRGB(24, 21, 18)
	local ROW_ON = Color3.fromRGB(46, 38, 28)
	local function label(parent, x, y, w, h, size, color, text, align)
		return new("TextLabel", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, Font = FONT, TextSize = size, TextColor3 = color, TextXAlignment = align or Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, RichText = true, Text = text, Parent = parent })
	end
	levelPanel = new("Frame", { Name = "BonfireMenu", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(820, 470), BackgroundTransparency = 1, Visible = false, Parent = gui })
	local function panel(x, title)
		local f = new("Frame", { Position = UDim2.fromOffset(x, 0), Size = UDim2.fromOffset(400, 440), BackgroundColor3 = Color3.fromRGB(10, 9, 8), BackgroundTransparency = 0.06, BorderSizePixel = 0, Parent = levelPanel })
		new("UIStroke", { Color = LINE, Thickness = 1.5, Parent = f })
		label(f, 24, 14, 352, 30, 28, Color3.fromRGB(226, 200, 150), title)
		new("Frame", { Position = UDim2.fromOffset(24, 50), Size = UDim2.fromOffset(352, 1), BackgroundColor3 = LINE, BorderSizePixel = 0, Parent = f })
		return f
	end
	-- leaving: this button, Backspace or gamepad B (the input handler), or walking away (below). Not Esc: that's Roblox's menu.
	-- (not E either: it would rest at the bonfire all over again)
	local leave = new("TextButton", { Position = UDim2.fromOffset(310, 446), Size = UDim2.fromOffset(200, 46), BackgroundColor3 = ROW, BorderSizePixel = 0, AutoButtonColor = false, Font = FONT, TextSize = 21, TextColor3 = TEXT, Text = "Leave", Parent = levelPanel })
	new("UIStroke", { Color = LINE, Thickness = 1, Parent = leave })
	leave.MouseEnter:Connect(function()
		leave.BackgroundColor3 = ROW_ON
	end)
	leave.MouseLeave:Connect(function()
		leave.BackgroundColor3 = ROW
	end)
	leave.Activated:Connect(function()
		levelPanel.Visible = false
	end)

	-- LEVEL UP
	local lv = panel(0, "Level Up")
	local splinterLabel = label(lv, 24, 60, 352, 24, 19, TEXT, "")
	local list = new("Frame", { Position = UDim2.fromOffset(24, 96), Size = UDim2.fromOffset(352, 320), BackgroundTransparency = 1, Parent = lv })
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	local statRows = {}
	for i, name in ipairs(Config.Stats) do
		local b = new("TextButton", { LayoutOrder = i, Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = ROW, BorderSizePixel = 0, AutoButtonColor = false, Text = "", Parent = list })
		local stroke = new("UIStroke", { Color = LINE, Thickness = 1, Parent = b })
		label(b, 14, 0, 170, 46, 21, TEXT, name)
		local value = label(b, 180, 0, 100, 46, 21, TEXT, "", Enum.TextXAlignment.Right)
		local plus = new("TextLabel", { Position = UDim2.fromOffset(298, 8), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = Color3.fromRGB(12, 10, 9), BorderSizePixel = 0, Font = FONT, TextSize = 24, TextColor3 = GOLD, Text = "+", Parent = b })
		new("UIStroke", { Color = GOLD, Thickness = 1, Parent = plus })
		b.MouseEnter:Connect(function()
			b.BackgroundColor3 = (player:GetAttribute("Splinters") or 0) > 0 and ROW_ON or ROW
		end)
		b.MouseLeave:Connect(function()
			b.BackgroundColor3 = ROW
		end)
		b.Activated:Connect(function()
			if (player:GetAttribute("Splinters") or 0) > 0 then
				Action:FireServer("LevelUp", name)
			end
		end)
		statRows[name] = { value = value, plus = plus, stroke = stroke }
	end

	-- TRAVEL
	local tv = panel(420, "Travel")
	local note = label(tv, 24, 60, 352, 40, 17, DIM, "")
	note.TextWrapped = true
	note.TextYAlignment = Enum.TextYAlignment.Top
	local fires = new("Frame", { Position = UDim2.fromOffset(24, 110), Size = UDim2.fromOffset(352, 306), BackgroundTransparency = 1, Parent = tv })
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = fires })

	function levelRefresh()
		local n = player:GetAttribute("Splinters") or 0
		splinterLabel.Text = "Bone Splinters   <font color=\"rgb(205,175,95)\">" .. n .. "</font>"
		for name, r in pairs(statRows) do
			local own, total = player:GetAttribute("Stat_" .. name) or 0, Config.statOf(player, name)
			r.value.Text = own .. (total > own and ("  <font color=\"rgb(150,190,110)\">+" .. (total - own) .. "</font>") or "")
			r.plus.Visible = n > 0
			r.stroke.Color = n > 0 and GOLD or LINE
		end
		-- the bonfires you've lit, in the order of the map's
		local open = ReplicatedStorage:GetAttribute("BonfireTravel") == true
		local here = player:GetAttribute("AtBonfire")
		tv.Visible = open -- (not seen at all until the Consul has fallen; Level Up takes the middle)
		lv.Position = UDim2.fromOffset(open and 0 or 210, 0)
		for _, c in ipairs(fires:GetChildren()) do
			if c:IsA("GuiButton") then
				c:Destroy()
			end
		end
		note.Text = open and "Flame answers flame. Choose where to be carried." or "The Consul's spell still binds the flame. No bonfire answers another."
		local found = {}
		for key, name in pairs(player:GetAttributes()) do
			local idx = string.match(key, "^Bonfire_(%d+)$")
			if idx then
				table.insert(found, { tonumber(idx), name })
			end
		end
		table.sort(found, function(x, y)
			return x[1] < y[1]
		end)
		for _, f in ipairs(found) do
			local idx, name = f[1], f[2]
			local isHere = idx == here
			local can = open and not isHere
			local b = new("TextButton", { LayoutOrder = idx, Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = isHere and ROW_ON or ROW, BorderSizePixel = 0, AutoButtonColor = false, Text = "", Parent = fires })
			new("UIStroke", { Color = isHere and GOLD or LINE, Thickness = isHere and 1.5 or 1, Parent = b })
			local flame = new("Frame", { Position = UDim2.fromOffset(14, 16), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = isHere and GOLD or DIM, Rotation = 45, BorderSizePixel = 0, Parent = b })
			flame.BackgroundTransparency = open and 0 or 0.5
			label(b, 48, 0, 210, 52, 21, open and TEXT or DIM, name)
			label(b, 250, 0, 90, 52, 16, isHere and GOLD or DIM, isHere and "You are here" or (open and "Travel" or "Bound"), Enum.TextXAlignment.Right)
			b.MouseEnter:Connect(function()
				b.BackgroundColor3 = can and ROW_ON or (isHere and ROW_ON or ROW)
			end)
			b.MouseLeave:Connect(function()
				b.BackgroundColor3 = isHere and ROW_ON or ROW
			end)
			b.Activated:Connect(function()
				if can then
					Action:FireServer("Travel", idx)
					levelPanel.Visible = false -- (the fade takes over; the menu is back at the other end)
				end
			end)
		end
	end
	player.AttributeChanged:Connect(function(name)
		if name == "Splinters" or string.sub(name, 1, 5) == "Stat_" or string.sub(name, 1, 5) == "Armor" or string.sub(name, 1, 8) == "Bonfire_" or name == "AtBonfire" then
			levelRefresh()
		end
	end)
	ReplicatedStorage:GetAttributeChangedSignal("BonfireTravel"):Connect(levelRefresh)
	levelRefresh()
	-- walking off (more than 10 studs from where it opened) closes it
	local openedAt
	levelPanel:GetPropertyChangedSignal("Visible"):Connect(function()
		openedAt = levelPanel.Visible and hrp and hrp.Position or nil
	end)
	RunService.Heartbeat:Connect(function()
		if openedAt and hrp and (hrp.Position - openedAt).Magnitude > 10 then
			levelPanel.Visible = false
		end
	end)
end
-- and say so, under the flasks
new("TextLabel", {
	Position = UDim2.fromOffset(36, 90),
	Size = UDim2.fromOffset(300, 18),
	BackgroundTransparency = 1,
	Font = FONT,
	TextSize = 16,
	TextColor3 = Color3.fromRGB(200, 190, 170),
	TextTransparency = 0.25,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextStrokeTransparency = 0.6,
	Text = "T / Tab  -  Weapons",
	Parent = gui,
})

---------------------------------------------------------------------------
-- input
---------------------------------------------------------------------------
local KEY_ACTIONS = {
	[Enum.KeyCode.Space] = "Roll",
	[Enum.KeyCode.ButtonB] = "Roll",
	[Enum.KeyCode.ButtonR1] = "Light",
	[Enum.KeyCode.ButtonR2] = "Heavy",
	[Enum.KeyCode.LeftShift] = "Sprint",
	[Enum.KeyCode.ButtonL3] = "Sprint",
	[Enum.KeyCode.Q] = "Deflect",
	[Enum.KeyCode.R] = "Lock",
	[Enum.KeyCode.ButtonR3] = "Lock",
	[Enum.KeyCode.ButtonL1] = "Deflect",
	[Enum.KeyCode.F] = "Heal",
	[Enum.KeyCode.ButtonX] = "Heal",
	[Enum.KeyCode.M] = "Cursor",
	[Enum.KeyCode.H] = "Help",
	[Enum.KeyCode.P] = "DevSpeed",
	[Enum.KeyCode.K] = "DevMenu",
	[Enum.KeyCode.T] = "Weapons",
	[Enum.KeyCode.Tab] = "Weapons",
}
local MOUSE_ACTIONS = {
	[Enum.UserInputType.MouseButton1] = "Light",
	[Enum.UserInputType.MouseButton2] = "Heavy",
	[Enum.UserInputType.MouseButton3] = "Lock",
}

local function actionFor(input)
	if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.Gamepad1 then
		return KEY_ACTIONS[input.KeyCode]
	end
	return MOUSE_ACTIONS[input.UserInputType]
end

UserInputService.InputBegan:Connect(function(input)
	-- while reading a page, clicks/space/esc just close it (no accidental swings)
	if notePanel.Visible then
		if os.clock() - noteOpenedTime > 0.2 and (input.UserInputType == Enum.UserInputType.MouseButton1
			or input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.Escape
			or input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.ButtonB) then
			closeNote()
		end
		return
	end
	-- the chest panel takes the mouse (dragging items); only the close keys do anything
	if chestPanel.Visible then
		if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.ButtonB then
			closeChest()
		end
		return
	end
	if UserInputService:GetFocusedTextBox() then
		return -- typing in chat
	end
	-- the weapon and level-up menus take the mouse too
	if equipPanel.Visible or levelPanel.Visible then
		if input.KeyCode == Enum.KeyCode.Escape or (levelPanel.Visible and (input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.ButtonB)) then
			equipPanel.Visible = false
			levelPanel.Visible = false
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
			return
		end
	end
	-- the dev menu takes the mouse (its buttons): clicks don't swing, Esc closes it
	if devPanel.Visible then
		if input.KeyCode == Enum.KeyCode.Escape then
			devPanel.Visible = false
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
			return
		end
	end
	local action = actionFor(input)
	if action == "Roll" or action == "Deflect" or action == "Light" or action == "Heavy" or action == "Heal" then
		request(action)
	elseif action == "Sprint" then
		sprintHeld = true
	elseif action == "Lock" then
		toggleLock()
	elseif action == "Cursor" then
		cursorFree = not cursorFree
	elseif action == "Help" then
		helpLabel.Visible = not helpLabel.Visible
	elseif action == "DevSpeed" then
		toggleDevFast()
		devRefresh()
	elseif action == "DevMenu" then
		devPanel.Visible = not devPanel.Visible
	elseif action == "Weapons" then
		equipPanel.Visible = not equipPanel.Visible
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if actionFor(input) == "Sprint" then
		sprintHeld = false
	end
end)

-- Swallow Space (default jump) and Shift (shift-lock) so Roblox's defaults don't fight us.
ContextActionService:BindActionAtPriority("SoulsSinkDefaults", function()
	return Enum.ContextActionResult.Sink
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Space, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonA)

---------------------------------------------------------------------------
-- camera
---------------------------------------------------------------------------
local camParams = RaycastParams.new()
camParams.FilterType = Enum.RaycastFilterType.Exclude

local function lerpAngle(a, b, t)
	local d = (b - a + math.pi) % (2 * math.pi) - math.pi
	return a + d * t
end

local function updateCamera(dt)
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = FOV
	local free = cursorFree or chestPanel.Visible or devPanel.Visible or equipPanel.Visible or levelPanel.Visible
	UserInputService.MouseBehavior = free and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = free
	if cutscene and cutscene.skip then
		-- held long enough: skipped (the server stands him up and lets you go; the camera and your grab end here)
		local held = UserInputService:IsKeyDown(Enum.KeyCode.Space)
		cutscene.held = math.clamp(cutscene.held + (held and dt or -2 * dt), 0, SKIP_HOLD)
		skipFill.Size = UDim2.fromScale(cutscene.held / SKIP_HOLD, 1)
		if cutscene.held >= SKIP_HOLD then
			cutscene.skip:FireServer()
			cutscene.t0 = -math.huge -- (past its last shot: it ends just below)
			local t = os.clock()
			freezeUntil = t
			setAction(t, 0, 0, 0, 0)
			buffered = nil -- (the Space you held isn't a roll)
		end
	end
	if cutscene then
		-- each shot glides from one framing to the next, eased
		local t = os.clock() - cutscene.t0
		for _, s in ipairs(cutscene.shots) do
			if t < s[3] then
				local k = t / s[3]
				local e = k * k * (3 - 2 * k)
				local aim = s[4]
				if aim and aim.Parent then
					-- a shot kept on something that moves (his head, as this client poses it): the camera glides s[1] to
					-- s[2] (offsets from it, if s[6]) and looks at it (plus s[5])
					local at = aim.Position
					local pos = s[1]:Lerp(s[2], e)
					if s[6] then
						pos += at
					end
					camera.CFrame = CFrame.lookAt(pos, at + (s[5] or Vector3.zero))
				elseif typeof(s[1]) == "CFrame" then
					camera.CFrame = s[1]:Lerp(s[2], e)
				else
					camera.CFrame = CFrame.new(s[1]:Lerp(s[2], e))
				end
				return
			end
			t -= s[3]
		end
		cutscene = nil
		focus = nil
		skipFrame.Visible = false
		for _, bar in ipairs(letterbox) do
			tween(bar, 0.6, { Size = UDim2.fromScale(1, 0) })
		end
	end
	if not hrp or not hrp.Parent then
		return
	end

	if lockTarget and not validTarget(lockTarget) then
		lockTarget = nil
	end
	if lockTarget and ReplicatedStorage:GetAttribute("BossActive") == true and not lockTarget:GetAttribute("Boss") then
		lockTarget = nil -- (a boss fight on: never anything else, e.g. something on the floor below)
	end
	if lockTarget and (lockTarget.HumanoidRootPart.Position - hrp.Position).Magnitude > 60 then
		lockTarget = nil
	end

	if lockTarget then
		recenterYaw = nil
		local dir = flat(lockTarget.HumanoidRootPart.Position - hrp.Position)
		if dir.Magnitude > 0.5 then
			local k = 1 - math.exp(-dt * 8)
			yaw = lerpAngle(yaw, math.atan2(-dir.X, -dir.Z), k)
			pitch = pitch + (-0.24 - pitch) * k
		end
	elseif not free then
		local delta = UserInputService:GetMouseDelta()
		if delta.Magnitude > 0 then
			recenterYaw = nil -- moving the mouse takes the camera back
			yaw -= delta.X * SENS
			pitch = math.clamp(pitch - delta.Y * SENS, -0.95, 0.55)
		elseif recenterYaw then
			-- smooth swing round behind the character (lock-on with nothing to lock)
			local k = 1 - math.exp(-dt * 12)
			yaw = lerpAngle(yaw, recenterYaw, k)
			pitch = pitch + (-0.25 - pitch) * k
			if math.abs((recenterYaw - yaw + math.pi) % (2 * math.pi) - math.pi) < 0.01 then
				recenterYaw = nil
			end
		end
	end

	-- horizontal follow is tight; vertical is lazier so hops and stairs don't jolt the view
	local target = hrp.Position + Vector3.new(0, 2, 0)
	if not focus or (target - focus).Magnitude > 20 then
		focus = target
	end
	local kFlat = 1 - math.exp(-dt * 14)
	local kUp = 1 - math.exp(-dt * 6)
	focus = Vector3.new(
		focus.X + (target.X - focus.X) * kFlat,
		focus.Y + (target.Y - focus.Y) * kUp,
		focus.Z + (target.Z - focus.Z) * kFlat
	)

	local rot = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)
	local ignore = { char, EnemiesFolder }
	local bars = workspace:FindFirstChild("DGUS") and workspace.DGUS:FindFirstChild("Bars")
	if bars then
		table.insert(ignore, bars)
	end
	camParams.FilterDescendantsInstances = ignore

	-- 1) slide out to the shoulder, 2) pull back behind it. Sphere casts keep the
	--    camera's near plane out of walls and ceilings in tight cells.
	local function cast(from, vec)
		if vec.Magnitude < 0.01 then
			return from
		end
		local res = workspace:Spherecast(from, CAM_RADIUS, vec, camParams)
		if res then
			return from + vec.Unit * math.max(res.Distance - 0.15, 0)
		end
		return from + vec
	end
	local shoulderPos = cast(focus, rot:VectorToWorldSpace(Vector3.new(SHOULDER, CAM_UP, 0)))
	local camPos = cast(shoulderPos, rot:VectorToWorldSpace(Vector3.new(0, 0, CAM_DIST)))

	-- fade the character when the camera is jammed right against it (applied by the Puppeteer)
	local closeness = (camPos - focus).Magnitude
	char:SetAttribute("CamFade", closeness < 2.2 and 0.75 or 0)

	local cf = CFrame.new(camPos) * rot
	if shake > 0 then
		cf = cf * CFrame.Angles((math.random() - 0.5) * shake * 0.06, (math.random() - 0.5) * shake * 0.06, (math.random() - 0.5) * shake * 0.03)
		shake = math.max(0, shake - dt * 2.5)
	end
	camera.CFrame = cf
	camera.Focus = CFrame.new(focus)

	-- reticle
	if lockTarget then
		reticle.Adornee = lockTarget.HumanoidRootPart
		reticle.Enabled = true
	else
		reticle.Enabled = false
	end
end

---------------------------------------------------------------------------
-- per-frame movement + HUD
---------------------------------------------------------------------------
local function updateMovement()
	if not hum or not hrp or hum.Health <= 0 then
		return
	end
	if hrp.Anchored then
		return -- held (a dog has you in its jaws): the server has the body, don't turn or steer it
	end
	local t = os.clock()
	local moving = hum.MoveDirection.Magnitude > 0.1
	local sprinting = sprintHeld and moving and stamina() > 0 and t >= attackAt
	if sprinting ~= sentSprint then
		sentSprint = sprinting
		Action:FireServer("Sprint", sprinting)
	end
	local speed = sprinting and P.SprintSpeed or P.WalkSpeed
	if lockTarget and not sprinting then
		speed *= 0.85
	end
	if player:GetAttribute("InFog") then
		speed *= Config.TownFog.Slow -- the township fog drags at your legs
	end
	speed *= Config.weaponOf(player).MoveSpeed or 1 -- (the Gozen Tachi: a touch lighter on your feet)
	if iaiReadyAt and t > iaiReadyAt + 0.4 and not player:GetAttribute("IaiReady") then
		iaiReadyAt = nil -- the server never settled you into it (refused the sheathe): walk free
	end
	if iaiReadyAt and t >= iaiReadyAt - Config.TachiDraw.SheatheTime + Config.TachiDraw.CancelAfter
		and (UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.D)) then
		iaiReadyAt = nil -- walked out of the Tachi's stance
		Action:FireServer("IaiCancel")
	end
	if iaiReadyAt or player:GetAttribute("Broken") then
		speed = 0 -- rooted in the Tachi's stance (W is held for the dash, not to walk), or BROKEN (Config.Break)
	end
	if t < slowUntil then
		speed = slowSpeed
	end
	if isRolling() then
		speed = 2
	end
	if t < freezeUntil then
		speed = 0 -- hit-stop
	end
	if devFast then
		speed *= 5
	end
	hum.WalkSpeed = speed

	local locked = lockTarget and validTarget(lockTarget)
	if isRolling() then
		hum.AutoRotate = false
	elseif os.clock() < spinUntil then
		hum.AutoRotate = false -- (the spin turns you itself)
	elseif locked and not sprinting then
		hum.AutoRotate = false
		faceDir(lockTarget.HumanoidRootPart.Position - hrp.Position)
	elseif t < attackAt then
		hum.AutoRotate = false
	else
		hum.AutoRotate = true
	end
end

local function updateHud(dt)
	local hp = (hum and hum.MaxHealth > 0) and math.clamp(hum.Health / hum.MaxHealth, 0, 1) or 0
	local st = math.clamp(stamina() / (player:GetAttribute("MaxStamina") or P.MaxStamina), 0, 1)
	-- max health buffs (the Castellan's helm...) widen the bar in proportion
	local wide = (hum and hum.MaxHealth > 0) and hum.MaxHealth / P.MaxHealth or 1
	hpFrame.Size = UDim2.fromOffset(300 * wide, 12)
	hpFill.Size = UDim2.fromScale(hp, 1)
	stFill.Size = UDim2.fromScale(st, 1)
	hpChipV = hp >= hpChipV and hp or math.max(hp, hpChipV - dt * 0.35)
	stChipV = st >= stChipV and st or math.max(st, stChipV - dt * 0.8)
	hpChip.Size = UDim2.fromScale(hpChipV, 1)
	stChip.Size = UDim2.fromScale(stChipV, 1)

	local flasks = player:GetAttribute("Flasks") or 0
	flaskLabel.Text = "Flask  " .. string.rep("◆ ", flasks) .. string.rep("◇ ", math.max(0, (player:GetAttribute("MaxFlasks") or P.Flasks) - flasks))

	local build = player:GetAttribute("PoisonBuild") or 0
	poisonBack.Visible = build > 0
	poisonFill.Size = UDim2.fromScale(build, 1)

	local active = ReplicatedStorage:GetAttribute("BossActive") == true
	bossFrame.Visible = active
	if active then
		local maxHp = ReplicatedStorage:GetAttribute("BossMaxHP") or 1
		local b = math.clamp((ReplicatedStorage:GetAttribute("BossHP") or 0) / maxHp, 0, 1)
		bossName.Text = ReplicatedStorage:GetAttribute("BossName") or ""
		bossFill.Size = UDim2.fromScale(b, 1)
		bossChipV = b >= bossChipV and b or math.max(b, bossChipV - dt * 0.25)
		bossChip.Size = UDim2.fromScale(bossChipV, 1)
	else
		bossChipV = 1
	end
end

RunService.Heartbeat:Connect(function()
	if notePanel.Visible and (not hrp or not noteOpenAt or (hrp.Position - noteOpenAt).Magnitude > 8) then
		closeNote()
	end
	if chestPanel.Visible and (not alive() or not chestOpenAt or (hrp.Position - chestOpenAt).Magnitude > 8) then
		closeChest()
	end
end)

RunService:BindToRenderStep("SoulsCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
	updateBuffer()
	separateFromEnemies()
	updateMovement()
	updateCamera(dt)
	updateHud(dt)
end)

---------------------------------------------------------------------------
-- enemy health bars (shown once damaged, like the games)
---------------------------------------------------------------------------
local function attachEnemyBar(model)
	if model:GetAttribute("Boss") then
		return
	end
	local h = model:WaitForChild("Humanoid", 5)
	local head = model:WaitForChild("Head", 5)
	if not h or not head then
		return
	end
	local bb = new("BillboardGui", {
		Name = "EnemyBar",
		Size = UDim2.fromOffset(70, 6),
		StudsOffsetWorldSpace = Vector3.new(0, head.Size.Y + 0.8, 0),
		AlwaysOnTop = false,
		Enabled = false,
		MaxDistance = 60,
		Parent = head,
	})
	local back = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(12, 10, 10), BackgroundTransparency = 0.2, BorderSizePixel = 0, Parent = bb })
	local fill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(150, 22, 20), BorderSizePixel = 0, Parent = back })
	h.HealthChanged:Connect(function(v)
		bb.Enabled = v > 0 and v < h.MaxHealth
		fill.Size = UDim2.fromScale(math.clamp(v / h.MaxHealth, 0, 1), 1)
	end)
end
EnemiesFolder.ChildAdded:Connect(function(m)
	task.spawn(attachEnemyBar, m)
end)
for _, m in ipairs(EnemiesFolder:GetChildren()) do
	task.spawn(attachEnemyBar, m)
end

---------------------------------------------------------------------------
-- torch flicker
---------------------------------------------------------------------------
task.spawn(function()
	while true do
		for _, l in ipairs(CollectionService:GetTagged("Flicker")) do
			local base = l:GetAttribute("Base") or 1
			l.Brightness = base * (0.82 + math.random() * 0.32)
		end
		task.wait(0.08)
	end
end)

-- the rot's glowing growths breathe slowly instead of flickering
task.spawn(function()
	while true do
		local t = os.clock()
		for i, l in ipairs(CollectionService:GetTagged("Pulse")) do
			local base = l:GetAttribute("Base") or 1
			l.Brightness = base * (0.7 + 0.3 * math.sin(t * 1.3 + i * 1.7))
		end
		task.wait(0.05)
	end
end)

-- the township fog seen from inside: the air thickens while you're in it and clears
-- when you leave (Config.TownFog; the server sets InFog). Lighting changes here are local.
do
	local Lighting = game:GetService("Lighting")
	local clear = nil -- the air as the server set it, captured the first time
	local function setFogAir(on)
		local atm = Lighting:FindFirstChildOfClass("Atmosphere")
		if not atm then
			return
		end
		clear = clear or { Density = atm.Density, Haze = atm.Haze, Color = atm.Color, Decay = atm.Decay }
		local F = Config.TownFog
		tween(atm, 2.5, on and { Density = F.Density, Haze = F.Haze, Color = F.Color, Decay = F.Decay } or clear, Enum.EasingStyle.Sine)
	end
	player:GetAttributeChangedSignal("InFog"):Connect(function()
		setFogAir(player:GetAttribute("InFog") == true)
	end)
	-- the Consul's ruined attic, from his rise on: a dark, blazing purple (the server sets ConsulTint)
	local tint = Instance.new("ColorCorrectionEffect")
	tint.Name = "ConsulTint"
	tint.Parent = Lighting
	player:GetAttributeChangedSignal("ConsulTint"):Connect(function()
		local on = player:GetAttribute("ConsulTint") == true
		tween(tint, on and 1.5 or 2, on and { TintColor = Color3.fromRGB(200, 150, 255), Brightness = -0.06, Contrast = 0.2, Saturation = 0.15 } or { TintColor = Color3.new(1, 1, 1), Brightness = 0, Contrast = 0, Saturation = 0 })
	end)
end

---------------------------------------------------------------------------
-- server effects
---------------------------------------------------------------------------
Fx.OnClientEvent:Connect(function(kind, a, b, c)
	if kind == "Hurt" then
		spinUntil = 0 -- (a hit breaks the spin)
		onHurt(a, b)
	elseif kind == "Flash" then
		-- the screen washed with colour a (a blinding blast; black, a dip between shots), held c seconds, fading over b
		flashFrame.BackgroundColor3 = a
		flashFrame.BackgroundTransparency = a == Color3.new(0, 0, 0) and 0 or 0.25
		task.delay(c or 0, function()
			tween(flashFrame, b or 0.8, { BackgroundTransparency = 1 })
		end)
	elseif kind == "Burn" then
		-- standing in fire: orange flash, no stagger
		vignette.BackgroundColor3 = Color3.fromRGB(200, 90, 10)
		vignette.BackgroundTransparency = 0.45
		local tw = tween(vignette, 0.35, { BackgroundTransparency = 1 })
		tw.Completed:Connect(function()
			vignette.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
		end)
	elseif kind == "Grabbed" then
		-- held by something (the mimic): no inputs until it lets go (a seconds)
		local t = os.clock()
		buffered = nil
		lastKind = nil
		deflectAt = nil
		setAction(t, a, a, a, a)
		-- an anchored root keeps its last velocity, which the walk cycle reads: stand still
		freezeUntil = math.max(freezeUntil, t + a)
		if hrp then
			hrp.AssemblyLinearVelocity = Vector3.zero
		end
	elseif kind == "HitConfirm" then
		-- hit-stop: freeze for an instant when your blade bites
		shake = math.max(shake, 0.18)
		freezeUntil = math.max(freezeUntil, os.clock() + (a or 0))
		-- the Foul Dagger's running attack landed: the rest of the run is quicker
		if runBoost and os.clock() < runBoost.untilT - 0.05 then
			pushVelocity(runBoost.dir, runBoost.speed * runBoost.mult, runBoost.untilT - os.clock(), 0.25)
			runBoost = nil
		end
	elseif kind == "DeflectConfirm" then
		-- crisp deflect sound played locally for zero-latency acoustic response
		local s = Instance.new("Sound")
		s.SoundId = Config.ScytheDeflect.Sound
		s.Volume = 1.0
		s.PlaybackSpeed = 1.0
		s.Parent = workspace.CurrentCamera
		s:Play()
		Debris:AddItem(s, 3)

		local layer = Instance.new("Sound")
		layer.SoundId = Config.ScytheDeflect.Sound2
		layer.Volume = 0.9
		layer.PlaybackSpeed = 1.3
		layer.Parent = workspace.CurrentCamera
		layer:Play()
		Debris:AddItem(layer, 3)

		local s2 = Instance.new("Sound")
		s2.SoundId = "rbxasset://sounds/unsheath.wav"
		s2.Volume = 0.75
		s2.PlaybackSpeed = 1.8
		s2.Parent = workspace.CurrentCamera
		s2:Play()
		Debris:AddItem(s2, 2)

		-- Gold flash & camera shake
		shake = math.max(shake, 0.45)
		vignette.BackgroundColor3 = Color3.fromRGB(255, 230, 160)
		vignette.BackgroundTransparency = 0.55
		tween(vignette, 0.25, { BackgroundTransparency = 1 })

		if char then
			char:SetAttribute("BP", "Deflect")
			char:SetAttribute("BPT", 0.04)
			char:SetAttribute("BPN", os.clock())
		end
	elseif kind == "Shake" then
		if hrp then
			local d = (hrp.Position - a).Magnitude
			shake = math.max(shake, b * math.clamp(1 - d / 80, 0, 1))
		end
	elseif kind == "Died" then
		lockTarget = nil
		buffered = nil
		showBanner("GAME OVER", "Death")
		task.delay(P.RespawnTime - 1.2, function()
			tween(overlay, 1, { BackgroundTransparency = 0 })
		end)
	elseif kind == "Rest" then
		tween(overlay, 0.5, { BackgroundTransparency = 0 })
		task.delay(0.9, function()
			tween(overlay, 1, { BackgroundTransparency = 1 })
			if a then
				showBanner("BONFIRE LIT", "Lit")
			end
			levelPanel.Visible = true -- (Level Up and Travel, side by side)
		end)
	elseif kind == "Fog" then
		overlay.BackgroundColor3 = Color3.new(1, 1, 1)
		overlay.BackgroundTransparency = 0.2
		local tw = tween(overlay, 0.8, { BackgroundTransparency = 1 })
		tw.Completed:Connect(function()
			overlay.BackgroundColor3 = Color3.new(0, 0, 0)
		end)
		lockTarget = nil
		focus = nil
	elseif kind == "Carrier" then
		-- what answers the bell: drawn here, on every client, along the server's plan
		require(ReplicatedStorage:WaitForChild("Carrier")).play(a)
	elseif kind == "Cutscene" then
		cutscene = { shots = a, t0 = os.clock(), skip = b and ReplicatedStorage:FindFirstChild(b), held = 0 }
		skipFill.Size = UDim2.fromScale(0, 1)
		skipFrame.Visible = cutscene.skip ~= nil
		lockTarget = nil
		for _, bar in ipairs(letterbox) do
			tween(bar, 0.8, { Size = UDim2.fromScale(1, 0.11) })
		end
	elseif kind == "Banner" then
		showBanner(a, b)
	elseif kind == "Area" then
		showBanner(a, "Area")
	elseif kind == "Note" then
		noteTitle.Text = a or ""
		noteBody.Text = b or ""
		notePanel.Visible = true
		noteOpenedTime = os.clock()
		noteOpenAt = hrp and hrp.Position or nil
	elseif kind == "Chest" then
		-- a = ring ids still in the chest, b = your ring slots ("" = empty); resent after each move
		renderChest(a or {}, b or {})
		if not chestPanel.Visible then
			chestPanel.Visible = true
			chestOpenAt = hrp and hrp.Position or nil
		end
	elseif kind == "Message" then
		showMessage(a)
	elseif kind == "SayClear" then
		sayToken += 1
		tween(sayFrame, 0.8, { BackgroundTransparency = 1 })
		tween(sayName, 0.8, { TextTransparency = 1 })
		tween(sayText, 0.8, { TextTransparency = 1 })
	elseif kind == "Say" then
		sayToken += 1
		local my = sayToken
		-- over the boss bar (and its name) while one is up, not on top of it
		sayFrame.Position = UDim2.new(0.5, 0, 1, ReplicatedStorage:GetAttribute("BossActive") == true and -112 or -40)
		sayName.Text = a or ""
		sayText.RichText = true -- (a line may colour a phrase with <font color=...>)
		sayText.Text = b or ""
		tween(sayFrame, 0.25, { BackgroundTransparency = 0.4 })
		tween(sayName, 0.25, { TextTransparency = 0 })
		tween(sayText, 0.25, { TextTransparency = 0 })
		if c then
			return -- held: stays up until a "SayClear"
		end
		task.delay(3 + #(b or "") * 0.045, function()
			if my == sayToken then
				tween(sayFrame, 0.8, { BackgroundTransparency = 1 })
				tween(sayName, 0.8, { TextTransparency = 1 })
				tween(sayText, 0.8, { TextTransparency = 1 })
			end
		end)
	end
end)

---------------------------------------------------------------------------
-- character lifecycle
---------------------------------------------------------------------------
local function onCharacter(c)
	char = c
	hum = c:WaitForChild("Humanoid")
	hrp = c:WaitForChild("HumanoidRootPart")
	hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	hum.WalkSpeed = P.WalkSpeed
	lockTarget = nil
	rollUntil = 0
	dodgeAt, attackAt, inputFrom, slowUntil, freezeUntil = 0, 0, 0, 0, 0
	buffered = nil
	lastKind, lastStep, comboUntil = nil, 0, 0
	recenterYaw = nil
	sentSprint = false
	focus = nil
	-- wait for the server to place us at the checkpoint, then look the way we face
	task.delay(0.35, function()
		if hrp and hrp.Parent then
			local lv = hrp.CFrame.LookVector
			yaw = math.atan2(-lv.X, -lv.Z)
			pitch = -0.2
			focus = nil
		end
		tween(overlay, 1.6, { BackgroundTransparency = 1 })
	end)
end

player.CharacterAdded:Connect(onCharacter)
-- the arms growing out of the rot in the encampment past the township (ReplicatedStorage/Carrier)
task.spawn(function()
	workspace:WaitForChild("DGUS", 30)
	require(ReplicatedStorage:WaitForChild("Carrier")).growths()
	require(ReplicatedStorage:WaitForChild("Carrier")).cloth()
end)
if player.Character then
	task.spawn(onCharacter, player.Character)
end
