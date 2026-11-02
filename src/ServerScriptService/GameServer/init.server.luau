--!nonstrict
-- GameServer: starts everything up and runs the world: the bonfire, the shortcut
-- gate, the fog wall, deaths and respawns, players, stamina and area names.
--
-- WHERE THINGS LIVE
--   ReplicatedStorage/Characters/*.lua   one file per character (looks, weapon, poses, AI)
--   GameServer/Core.lua                  the shared toolkit characters use (effects, damage, poses...)
--   GameServer/Enemies.lua               the shared brain for regular enemies
--   GameServer/MapBuilder + MapDetail    the level
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local StarterPlayer = game:GetService("StarterPlayer")

local Core = require(script:WaitForChild("Core")) -- (builds the level)
local Enemies = require(script:WaitForChild("Enemies"))
local Config, P, Map, FxRemote, ActionRemote = Core.Config, Core.P, Core.Map, Core.FxRemote, Core.ActionRemote
local Roster, RigBuilder = Core.Roster, Core.RigBuilder
local dressArmor -- (defined with the helm, below)
local states, aliveChar, playSound, SOUNDS, makeCorpse = Core.states, Core.aliveChar, Core.playSound, Core.SOUNDS, Core.makeCorpse
local applyLimbGroup, syncStamina = Core.applyLimbGroup, Core.syncStamina
local now, flat = Core.now, Core.flat

-- wake every character file's server side
Enemies.init(Core)
require(script:WaitForChild("Mimic")).init(Core)
local Carrier = require(script:WaitForChild("Carrier")) -- (what answers the bell)
Carrier.init(Core)
for _, c in ipairs(Roster.list) do
	if c.init then
		c.init(Core)
	end
end
local Knight, Warden, Oculast, Mabel, Castellan = Roster.byKind.Knight, Roster.byKind.Warden, Roster.byKind.Usher, Roster.byKind.Wick, Roster.byKind.Castellan
local Champion = Roster.byKind.Champion

-- You play as a hollowed knight: a Motor6D rig we fully animate (see Puppeteer).
-- (Roblox avatars may use joints scripts can't pose, so the body never moved.)
Players.CharacterAutoLoads = false
do
	local old = StarterPlayer:FindFirstChild("StarterCharacter")
	if old then
		old:Destroy()
	end
	local knight = RigBuilder.build("Knight", 1)
	knight.Name = "StarterCharacter"
	knight.Parent = StarterPlayer
end
Players.CharacterAutoLoads = true
-- anyone who spawned before the knight existed gets respawned as the knight
task.defer(function()
	for _, pl in ipairs(Players:GetPlayers()) do
		if not (pl.Character and pl.Character:GetAttribute("PrisonRig")) then
			pl:LoadCharacter()
		end
	end
end)

StarterPlayer.EnableMouseLockOption = false
StarterPlayer.CharacterUseJumpPower = false
StarterPlayer.CharacterJumpHeight = 0
Players.RespawnTime = P.RespawnTime

---------------------------------------------------------------------------
-- lighting: bleak, grey, desaturated
---------------------------------------------------------------------------
do
	-- Dim and grey, but readable. Interiors rely on ambient + torches, so ambient
	-- can't be near-black or everything outside torchlight becomes a void.
	Lighting.ClockTime = 6.9
	Lighting.Brightness = 1.75
	Lighting.Ambient = Color3.fromRGB(57, 56, 61)
	Lighting.OutdoorAmbient = Color3.fromRGB(102, 103, 111)
	Lighting.EnvironmentDiffuseScale = 0.45
	Lighting.EnvironmentSpecularScale = 0.28
	Lighting.ExposureCompensation = 0.18
	Lighting.GlobalShadows = true
	for _, c in ipairs(Lighting:GetChildren()) do
		if c:IsA("PostEffect") or c:IsA("Atmosphere") or c:IsA("Sky") then
			c:Destroy()
		end
	end
	local atm = Instance.new("Atmosphere")
	atm.Density = 0.34
	atm.Offset = 0.22
	-- (the sky's colour comes from these: both 20% darker than they were, 140,140,146 / 60,58,62)
	atm.Color = Color3.fromRGB(112, 112, 117)
	atm.Decay = Color3.fromRGB(48, 46, 50)
	atm.Glare = 0
	atm.Haze = 1.6
	atm.Parent = Lighting
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Saturation = -0.42
	cc.Contrast = 0.11
	cc.Brightness = 0.01
	cc.TintColor = Color3.fromRGB(225, 220, 210)
	cc.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.6
	bloom.Size = 30
	bloom.Threshold = 1.6
	bloom.Parent = Lighting
	local sky = Instance.new("Sky")
	sky.CelestialBodiesShown = false
	sky.StarCount = 0
	sky.Parent = Lighting
end

---------------------------------------------------------------------------
-- your actions arrive here (the moveset itself is in Characters/Knight.lua)
---------------------------------------------------------------------------
ActionRemote.OnServerEvent:Connect(function(player, action, arg, arg2, arg3)
	if action == "Equip" then
		-- the weapon menu (I): only what you've found, and not mid-action
		local st = states[player]
		local def = typeof(arg) == "string" and Config.Weapons[arg]
		if st and def and (arg == "Sword" or player:GetAttribute("Has_" .. arg)) and now() >= st.busyUntil then
			if not Core.equipWeapon(player, arg) then
				if def.FireReq and Config.statOf(player, "Fire") < def.FireReq then
					FxRemote:FireClient(player, "Message", def.Name .. " won't answer you. It needs " .. def.FireReq .. " Fire.")
				else
					FxRemote:FireClient(player, "Message", def.Name .. " is too heavy for you. It needs " .. def.Strength .. " Strength.")
				end
			end
		end
	elseif action == "WearArmor" and typeof(arg) == "string" and Config.Armor[arg] and player:GetAttribute(arg) == true then
		Config.wearArmor(player, arg) -- (on, or off if it was on; the attributes' listener dresses you)
	elseif action == "LevelUp" and typeof(arg) == "string" and table.find(Config.Stats, arg) then
		-- spends one Bone Splinter, only while at a bonfire
		local _, _, hrp = aliveChar(player)
		local n = player:GetAttribute("Splinters") or 0
		local near = false
		for _, bf in ipairs(Map.Bonfires) do
			near = near or (hrp ~= nil and (hrp.Position - bf.CF.Position).Magnitude < 16)
		end
		if near and n > 0 then
			player:SetAttribute("Splinters", n - 1)
			player:SetAttribute("Stat_" .. arg, Core.stat(player, arg) + 1)
		end
	elseif action == "DevGiveAll" and Config.Debug then
		-- every weapon and every piece of armor, to pick from in the menu (I)
		for key in pairs(Config.Weapons) do
			player:SetAttribute("Has_" .. key, true)
		end
		for key in pairs(Config.Armor) do
			player:SetAttribute(key, true)
		end
	elseif action == "DevSplinters" and Config.Debug then
		player:SetAttribute("Splinters", (player:GetAttribute("Splinters") or 0) + 10)
	elseif action == "DevGive" and Config.Debug and typeof(arg) == "string" and Config.Weapons[arg] then
		player:SetAttribute("Has_" .. arg, true)
		Core.equipWeapon(player, arg)
	elseif action == "Attack" and (arg == "Light" or arg == "Heavy" or arg == "Running") and not (arg == "Light" and Config.weaponOf(player).NoLight) then
		Knight.attack(player, arg, typeof(arg2) == "number" and arg2 or nil, typeof(arg3) == "Vector3" and arg3 or nil)
	elseif action == "LaserAim" or action == "LaserStop" then -- (the Dark Book's held beam: Knight.castLaser)
		local st = states[player]
		if st and action == "LaserStop" then
			st.laserStop = true
		elseif st and typeof(arg) == "Vector3" and arg.Magnitude > 0.5 then
			st.laserAim = arg.Unit
		end
	elseif action == "Roll" then
		Knight.roll(player, false)
	elseif action == "Backstep" then
		Knight.roll(player, true)
	elseif action == "Deflect" then
		Knight.deflect(player)
	elseif action == "Iai" then
		Knight.iai(player, arg == true)
	elseif action == "Spin" then
		Knight.spin(player)
	elseif action == "IaiCancel" then
		Knight.iaiCancel(player)
	elseif action == "Heal" then
		Knight.heal(player)
	elseif action == "Sprint" then
		local st = states[player]
		if st then
			st.sprinting = arg == true
		end
	end
end)

---------------------------------------------------------------------------
-- world reset, death, bonfire, shortcut, fog, messages
---------------------------------------------------------------------------

-- what a player carries, kept across deaths as player attributes: the Castellan's Helm
-- (+50% health) and any spare flasks found
local function maxHealth(player)
	local bonus = Config.weaponOf(player).HealthBonus or 0
	return P.MaxHealth * (1 + Config.armorBonus(player).Health + bonus) -- (only armor that's worn counts)
end
-- max health changed (the helm put on, a weapon swapped): keep the same fraction of it
local function refreshHealth(player)
	local _, hum = aliveChar(player)
	if hum then
		local new = maxHealth(player)
		local health = hum.Health * new / hum.MaxHealth
		hum.MaxHealth = new
		hum.Health = health
	end
end
-- armor that mends you (Config.Armor Regen = { Amount, Every }): a little health, always
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, pl in ipairs(Players:GetPlayers()) do
			local rate = Config.armorBonus(pl).Regen
			local _, hum = aliveChar(pl)
			if rate > 0 and hum and hum.Health < hum.MaxHealth then
				hum.Health = math.min(hum.MaxHealth, hum.Health + rate * 0.5)
			end
		end
	end
end)
-- AT REST: half a second after his last action he straightens up out of whatever he finished in
-- and stands tall (the Knight's "Rest" body pose). Only from the plain "Idle" pose: a book's
-- reading stoop, the Tachi's stance and the like keep their own.
task.spawn(function()
	local REST_AFTER = 0.5
	while true do
		task.wait(0.1)
		local t = now()
		for pl, st in pairs(states) do
			local char = pl.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				local bpn, bp = char:GetAttribute("BPN") or 0, char:GetAttribute("BP")
				if bpn ~= st.restBPN then -- (something posed him: the half second starts over)
					st.restBPN, st.restAt = bpn, t
				elseif (bp == nil or bp == "Idle") and t - (st.restAt or t) >= REST_AFTER and t >= math.max(st.attackAt or 0, st.dodgeAt or 0) then
					Core.bodyPose(st, "Rest", 0.6)
					st.restBPN = char:GetAttribute("BPN")
				end
			end
		end
	end
end)
local function maxFlasks(player)
	return P.Flasks + (player:GetAttribute("ExtraFlasks") or 0)
end

local function onPlayerDied(player)
	FxRemote:FireClient(player, "Died")
	Champion.onPlayerDied(player)
	if (Warden.state() == "fight" or Warden.state() == "intro") and not Warden.anyoneInArena() then
		ReplicatedStorage:SetAttribute("Music", "none")
	end
	if Castellan.state() == "fight" and not Castellan.anyoneInArena() then
		ReplicatedStorage:SetAttribute("Music", "none")
	end
	if Champion.state() == "fight" and not Champion.anyoneInArena() then
		ReplicatedStorage:SetAttribute("Music", "none")
	end
	local char = player.Character
	if char then
		makeCorpse(char)
	end
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		playSound(hrp, SOUNDS.Groan, 0.7, 0.8)
	end
	task.delay(P.RespawnTime - 0.4, function()
		if (Warden.state() == "fight" or Warden.state() == "intro") and not Warden.anyoneInArena() then
			Warden.reset()
		end
		if not Castellan.anyoneInArena() then
			Castellan.reset() -- (does nothing while he's dormant or dead)
		end
		if not Champion.anyoneInArena() then
			Champion.reset() -- (the same)
		end
		local usherBusy = false
		for _, pl in ipairs(Players:GetPlayers()) do
			local c, _, r = aliveChar(pl)
			if c and Oculast.inChapel(r.Position) then
				usherBusy = true -- someone else is still fighting her
			end
		end
		if not usherBusy then
			Oculast.reset()
		end
		Enemies.respawn()
	end)
end

-- every bonfire (Map.Bonfires): lit the first time, then rested at - you wake at the last
-- one you rested at, healed, flasks refilled, and the world resets
-- (resting also writes it into your "Bonfire_<n>" attributes - the lit ones the travel menu lists - and "AtBonfire")
local function restAt(player, bf, i, first, silent)
	local st = states[player]
	local char, hum = aliveChar(player)
	if not (st and char) then
		return
	end
	st.checkpoint = bf.CF
	hum.Health = hum.MaxHealth
	st.flasks = maxFlasks(player)
	player:SetAttribute("Flasks", st.flasks)
	st.stamina = P.MaxStamina
	player:SetAttribute("Bonfire_" .. i, bf.Name)
	player:SetAttribute("AtBonfire", i)
	if not silent then
		FxRemote:FireClient(player, "Rest", first)
	end
	Enemies.respawn()
	Oculast.reset()
end
for i, bf in ipairs(Map.Bonfires) do
	local lit = false
	bf.Prompt.Triggered:Connect(function(player)
		local st = states[player]
		local char = aliveChar(player)
		if not (st and char) then
			return
		end
		local first = not lit
		if first then
			lit = true
			bf.Fire.Enabled = true
			bf.Light.Enabled = true
			bf.Glow.Enabled = false
			bf.Sparks.Rate = 6
			bf.Prompt.ActionText = "Rest"
		end
		restAt(player, bf, i, first)
	end)
end

-- the prison wing's portcullis (MapBuilder section 10): sealed until the Consul's spell breaks (the same
-- moment bonfire travel opens, ReplicatedStorage "BonfireTravel"), then it lifts for good
do
	local G, open = Map.PrisonGate, false
	Map.PrisonGatePrompt.Triggered:Connect(function(player)
		FxRemote:FireClient(player, "Message", open and "The portcullis stands open." or "A portcullis, sealed fast. Something other than rust holds it shut.")
	end)
	ReplicatedStorage:GetAttributeChangedSignal("BonfireTravel"):Connect(function()
		if open or ReplicatedStorage:GetAttribute("BonfireTravel") ~= true then
			return
		end
		open = true
		FxRemote:FireAllClients("Message", "Far off, iron grinds. A way has opened into the prison's walls.")
		playSound(G.Bars[1], SOUNDS.Unsheath, 1, 0.3)
		for _, b in ipairs(G.Bars) do
			TweenService:Create(b, TweenInfo.new(4, Enum.EasingStyle.Quad), { Position = b.Position + Vector3.new(0, 12, 0) }):Play()
		end
		task.delay(2.5, function()
			G.Blocker.CanCollide = false
		end)
	end)
end

-- THE DRAWBRIDGE (MapBuilder: Map.DrawBridge, in the citadel's east wall). Once the Consul has fallen (bonfire travel
-- open), the first time a player is out in the mansion's forecourt - walking out of the door, or waking at its bonfire
-- after a death - they're taken for a cutscene, and the bridge comes slamming down onto the prison wing's roof.
-- (Everyone after that gets a shorter one, of the bridge already down.)
do
	local D = Map.DrawBridge
	local state = "up" -- "up" | "falling" | "down"
	local function slam()
		state = "falling"
		local th, w, last = D.Up, 0, os.clock()
		while true do
			task.wait()
			local t = os.clock()
			local dt = math.min(t - last, 0.05)
			last = t
			w -= 3.2 * dt -- (it falls: gravity on the leaf)
			th += w * dt
			if th <= D.Down then
				th = D.Down
				local s = -w
				if s > 0.4 then -- it lands, and bounces; twice, smaller each time
					playSound(D.Model.PrimaryPart, SOUNDS.Impact, math.min(1, s / 2), 0.4)
					FxRemote:FireAllClients("Shake", D.Tip, math.min(1, s / 3))
					Core.burst(D.Tip, Color3.fromRGB(150, 140, 125), 24, 0.6, 22)
					w = s * 0.3
				else
					D.Set(th)
					break
				end
			end
			D.Set(th)
		end
		D.Block.CanCollide = false
		state = "down"
	end
	local function scene(pl)
		local st = states[pl]
		local char, _, hrp = aliveChar(pl)
		if not (st and char) then
			return
		end
		st.bridgeSeen = true
		while state == "falling" do -- (someone else's is under way: theirs, then yours of the bridge already down)
			task.wait(0.2)
		end
		if aliveChar(pl) ~= char then
			st.bridgeSeen = nil
			return
		end
		local first = state == "up"
		if first then
			state = "falling" -- (taken now, so nobody else starts it too)
		end
		local V, look = Vector3.new, CFrame.lookAt
		local raised = V(-92, 80, 85)
		local shots = first and {
			{ look(V(-135, 70, 62), raised), look(V(-124, 72, 68), raised), 3.2 },
			{ look(V(-34, 60, 100), V(-78, 62, 85)), look(V(-38, 56, 104), V(-78, 62, 85)), 4.5 }, -- (from the wing's roof, above where the bridge lands: clear air, no terrain on this side)
			{ look(V(-100, 72, 84), V(-30, 46, 84)), look(V(-66, 58, 84), V(-30, 44, 84)), 3.5 },
		} or {
			{ look(V(-135, 70, 62), V(-80, 52, 85)), look(V(-124, 72, 68), V(-80, 52, 85)), 2.5 },
			{ look(V(-100, 72, 84), V(-30, 46, 84)), look(V(-66, 58, 84), V(-30, 44, 84)), 3.5 },
		}
		local total = 0
		for _, s in ipairs(shots) do
			total += s[3]
		end
		Core.setAction(st, now(), total, total, total)
		st.iStart, st.iEnd = now(), now() + total + 0.5 -- (nothing hurts you through it)
		st.healing = false
		Core.cancelSwing(st)
		hrp.Anchored = true
		Roster.byKind.Consul.brighten(3) -- (the night, if any is left, is gone within 3 s of it starting)
		FxRemote:FireClient(pl, "Grabbed", total)
		FxRemote:FireClient(pl, "Cutscene", shots)
		if first then
			task.delay(3.2, slam) -- (as the camera comes round to the side)
		end
		task.delay(total, function()
			if hrp.Parent then
				hrp.Anchored = false
				pcall(function()
					hrp:SetNetworkOwner(pl)
				end)
			end
			FxRemote:FireClient(pl, "Message", "The courtyard's bridge has fallen. Beyond it, the old prison stands open.")
		end)
	end
	task.spawn(function()
		while true do
			task.wait(0.5)
			if ReplicatedStorage:GetAttribute("BonfireTravel") == true then
				for pl, st in pairs(states) do
					if not st.bridgeSeen and not st.travelling and now() >= st.busyUntil then
						local char, _, hrp = aliveChar(pl)
						local p = hrp and hrp.Position
						if char and p.Y > 50 and p.X > -244 and p.X < -123 and p.Z > 16 and p.Z < 104 then
							task.spawn(scene, pl)
						end
					end
				end
			end
		end
	end)
end

-- the Fallen Cellblock's door (MapBuilder section 11): in the first block's west wall, from the lower hallway into the west cell
-- opposite the bonfire's. It swings open from the hallway's side for good; from the cell it won't budge.
do
	local D = Map.FallenDoor
	local open = false
	D.LockedPrompt.Triggered:Connect(function(player)
		FxRemote:FireClient(player, "Message", open and "The door stands open." or "It will not budge. It must open from the other side.")
	end)
	D.Prompt.Triggered:Connect(function(player)
		local _, _, hrp = aliveChar(player)
		if open or not hrp or hrp.Position.X > -19 then -- (only from the hallway side, west of the door)
			return
		end
		open = true
		D.Prompt.Enabled = false
		D.LockedPrompt.Enabled = false
		playSound(D.Leaf.PrimaryPart, SOUNDS.Unsheath, 1, 0.3)
		task.spawn(function()
			local t0 = os.clock()
			while true do
				local k = math.min((os.clock() - t0) / 1.1, 1)
				local e = k * k * (3 - 2 * k)
				D.Leaf:PivotTo(D.Hinge * CFrame.Angles(0, math.rad(100) * e, 0))
				if k >= 1 then
					break
				end
				task.wait()
			end
			playSound(D.Leaf.PrimaryPart, SOUNDS.Impact, 0.6, 0.7)
		end)
	end)
end

-- TRAVEL (once the Consul has fallen: ReplicatedStorage "BonfireTravel"): from beside a bonfire, to any other
-- you've rested at. The screen fades (the "Rest" event), you're moved while it's black, and rest there.
ActionRemote.OnServerEvent:Connect(function(player, action, idx)
	if action ~= "Travel" or typeof(idx) ~= "number" then
		return
	end
	local st = states[player]
	local char, _, hrp = aliveChar(player)
	local dest = Map.Bonfires[idx]
	if not (st and char and dest and not st.travelling and ReplicatedStorage:GetAttribute("BonfireTravel")) then
		return
	end
	if not player:GetAttribute("Bonfire_" .. idx) or player:GetAttribute("AtBonfire") == idx then
		return
	end
	local near = false
	for _, bf in ipairs(Map.Bonfires) do
		near = near or (hrp.Position - bf.CF.Position).Magnitude < 16
	end
	if not near then
		return
	end
	st.travelling = true
	FxRemote:FireClient(player, "Rest", false)
	task.delay(0.45, function()
		st.travelling = nil
		if aliveChar(player) == char then
			char:PivotTo(dest.CF)
			restAt(player, dest, idx, false, true)
		end
	end)
end)

-- standing on the battlements after the Castellan has fallen, before ever resting, is a checkpoint of its own:
-- otherwise dying after being flung off them sends you back to the first spawn, cut off from the keep
-- (not during the fight: dying to him still means the runback)
task.spawn(function()
	while true do
		task.wait(0.5)
		for pl, st in pairs(states) do
			local _, _, hrp = aliveChar(pl)
			if hrp and st.checkpoint == Map.Spawn and Castellan.state() == "dead" and Castellan.onRoof(hrp.Position) then
				st.checkpoint = Map.CastellanArena.Spawn
			end
		end
	end
end)

local gateOpen = false
local function openGate()
	if gateOpen then
		return
	end
	gateOpen = true
	Map.LeverPrompt.Enabled = false
	Map.LockedPrompt.Enabled = false
	task.spawn(function()
		for i = 1, 20 do
			local a = 0.7 - 1.4 * (i / 20)
			Map.LeverHandle.CFrame = Map.LeverPivot * CFrame.Angles(0, 0, a) * CFrame.new(0, 1.1, 0)
			task.wait(1 / 30)
		end
	end)
	playSound(Map.Gate.PrimaryPart, SOUNDS.Unsheath, 1, 0.3)
	local start = Map.Gate:GetPivot()
	task.spawn(function()
		task.wait(0.4)
		for i = 1, 75 do
			Map.Gate:PivotTo(start + Vector3.new(0, 13.6 * (i / 75), 0))
			task.wait(1 / 30)
		end
	end)
end

Map.LeverPrompt.Triggered:Connect(function(player)
	openGate()
	FxRemote:FireClient(player, "Message", "A shortcut has opened.")
end)

-- a ladder that lies up high until it is kicked down: it stays down (a way between the two levels).
-- L = { Ladder, Down, Prompt, UpPrompt, DownPrompt, Climb, Block? } - the yard's, and the Hollow Mansion's
local yardLadder = { Ladder = Map.Ladder, Down = Map.LadderDown, Prompt = Map.LadderPrompt, UpPrompt = Map.LadderUpPrompt, DownPrompt = Map.LadderDownPrompt, Climb = Map.LadderClimb }
local function kickLadder(player, L)
	L = L or yardLadder
	if not L.Prompt.Enabled then
		return
	end
	L.Prompt.Enabled = false
	local ladder, to = L.Ladder, L.Down
	local half = ladder.Size.Y / 2
	local foot = ladder.CFrame * Vector3.new(0, -half, 0) -- lying flat, its foot at the gap
	local function run(dur, step) -- step(a) for a = 0..1 over dur seconds
		local t0 = os.clock()
		while true do
			local a = math.min((os.clock() - t0) / dur, 1)
			step(a)
			if a >= 1 then
				return
			end
			task.wait()
		end
	end
	playSound(ladder, SOUNDS.Unsheath, 0.8, 0.5)
	task.spawn(function()
		-- 1) stood up on its foot
		local lie = ladder.CFrame.UpVector -- (foot to tip, flat on the deck: +z for the yard's and mansion's, -z for the wing's)
		local psi = math.atan2(lie.X, lie.Z)
		run(0.45, function(a)
			local th = a * math.pi / 2
			ladder.CFrame = CFrame.new(foot + Vector3.new(lie.X * math.cos(th), math.sin(th), lie.Z * math.cos(th)) * half) * CFrame.Angles(0, psi, 0) * CFrame.Angles(math.pi / 2 - th, 0, 0)
		end)
		-- 2) swung round so its rungs run along the wall
		local up = foot + Vector3.new(0, half, 0)
		run(0.2, function(a)
			ladder.CFrame = CFrame.new(up) * CFrame.Angles(0, psi + a * math.pi / 2, 0)
		end)
		-- 3) heaved up and over the gap (its foot clears the battlements)...
		local over = Vector3.new(to.Position.X, up.Y + 2.2, to.Position.Z)
		run(0.3, function(a)
			ladder.CFrame = CFrame.new(up:Lerp(over, a)) * to.Rotation
		end)
		-- 4) ...and let go: down into the yard
		run(0.55, function(a)
			ladder.CFrame = CFrame.new(over:Lerp(to.Position, a * a)) * to.Rotation
		end)
		ladder.CFrame = to
		playSound(ladder, SOUNDS.Impact, 1, 0.6)
		FxRemote:FireClient(player, "Message", "A shortcut has opened.")
		if L.Block then
			L.Block.CanCollide = false
		end
		L.UpPrompt.Enabled = true
		L.DownPrompt.Enabled = true
	end)
end
Map.LadderPrompt.Triggered:Connect(function(player)
	kickLadder(player, yardLadder)
end)
Map.MansionLadder.Prompt.Triggered:Connect(function(player)
	kickLadder(player, Map.MansionLadder)
end)
Map.WingLadder.Prompt.Triggered:Connect(function(player) -- (the prison wing's: down its shaft to the cell block)
	kickLadder(player, Map.WingLadder)
end)

-- the Castellan's keep: its portcullis is hauled up by the chain inside and stays up
-- (a way back in from the hall's roof); from the roof it won't budge till then
local keepOpen = false
Map.KeepChainPrompt.Triggered:Connect(function(player)
	if keepOpen then
		return
	end
	keepOpen = true
	Map.KeepChainPrompt.Enabled = false
	Map.KeepGateLocked.Enabled = false
	local ring, c0 = Map.KeepChain, Map.KeepChain.CFrame
	task.spawn(function() -- the ring hauled down, and let go
		for i = 1, 10 do
			ring.CFrame = c0 * CFrame.new(0, -1.2 * i / 10, 0)
			task.wait(1 / 30)
		end
		task.wait(0.25)
		for i = 1, 10 do
			ring.CFrame = c0 * CFrame.new(0, -1.2 * (1 - i / 10), 0)
			task.wait(1 / 30)
		end
	end)
	local gate = Map.KeepGate
	playSound(gate.PrimaryPart, SOUNDS.Unsheath, 1, 0.3)
	local start = gate:GetPivot()
	task.spawn(function()
		task.wait(0.4)
		for i = 1, 75 do
			gate:PivotTo(start + Vector3.new(0, 7.8 * (i / 75), 0))
			task.wait(1 / 30)
		end
		playSound(gate.PrimaryPart, SOUNDS.Impact, 0.8, 0.5)
	end)
	FxRemote:FireClient(player, "Message", "A shortcut has opened.")
end)
Map.KeepGateLocked.Triggered:Connect(function(player)
	FxRemote:FireClient(player, "Message", "It will not budge. It must open from the other side.")
end)
-- the great door into the Castellan's hall: the bar lifted off, both leaves swung in
-- (open for now, so the hall can be looked over; the fight behind it is still to come)
local greatDoorOpen = false
Map.GreatDoor.Prompt.Triggered:Connect(function()
	if greatDoorOpen then
		return
	end
	greatDoorOpen = true
	local D = Map.GreatDoor
	D.Prompt.Enabled = false
	playSound(D.Bar, SOUNDS.Unsheath, 0.8, 0.4)
	local bar0 = D.Bar.CFrame
	task.spawn(function()
		for i = 1, 12 do
			D.Bar.CFrame = bar0 * CFrame.new(-0.8 * i / 12, 0.6 * i / 12, 0)
			task.wait(1 / 30)
		end
		D.Bar.CanCollide = false
		D.Bar.CFrame = bar0 * CFrame.new(-1.2, -4.3, 0) * CFrame.Angles(0, 0, 0.2) -- set down against the wall
		task.wait(0.15)
		playSound(D.Leaves[1].PrimaryPart, SOUNDS.Impact, 0.7, 0.45)
		local starts = { D.Leaves[1]:GetPivot(), D.Leaves[2]:GetPivot() }
		for i = 1, 45 do
			local a = math.sin(i / 45 * math.pi / 2) * math.pi / 2 -- easing out
			for k, leaf in ipairs(D.Leaves) do
				local h = CFrame.new(D.Hinges[k])
				leaf:PivotTo(h * CFrame.Angles(0, D.Signs[k] * a, 0) * h:Inverse() * starts[k])
			end
			task.wait(1 / 30)
		end
	end)
end)

-- the keep's pickups: taken once (for everyone), kept across deaths as a player attribute
local function takePickup(pk)
	pk.Prompt.Enabled = false
	for _, p in ipairs(pk.Parts) do
		p.Transparency = 1
		for _, c in ipairs(p:GetChildren()) do
			if c:IsA("ParticleEmitter") or c:IsA("Light") then
				c.Enabled = false
			end
		end
	end
	playSound(pk.Glow, SOUNDS.Unsheath, 0.6, 1.5)
end
-- the Castellan's Helm, worn in place of the knight's own helm
local MapBuilder = require(script:WaitForChild("MapBuilder"))
local KNIGHT_HELM = { Helm = true, HelmTop = true, HelmCrest = true, HelmBand = true, Visor = true, Breaths = true }
local function wearHelmet(char)
	local head = char:FindFirstChild("Head")
	if not head or char:FindFirstChild("CastellanHelm") then
		return
	end
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") and KNIGHT_HELM[d.Name] then
			d.Transparency = 1
		end
	end
	local helm = MapBuilder.helm(head.CFrame)
	helm.Name = "CastellanHelm"
	for _, p in ipairs(helm:GetChildren()) do
		p.Anchored = false
		p.Massless = true
		p.CanQuery, p.CanTouch = false, false
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = head, p
		w.Parent = p
	end
	helm.Parent = char
end
-- ARMOR (Config.Armor): dress the character in what's worn ("ArmorHead"/"ArmorBody"),
-- taking off whatever isn't first. How each piece looks: Armor.luau (and Taylor's, wearHelmet)
local Armor = require(script:WaitForChild("Armor"))
function dressArmor(player, char)
	local worn = Config.wornArmor(player)
	local helm = char:FindFirstChild("CastellanHelm")
	if helm and not worn.Helmet then
		helm:Destroy()
		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("BasePart") and KNIGHT_HELM[d.Name] then
				d.Transparency = 0
			end
		end
	end
	if not worn.Motley then
		Roster.byKind.Taylor.unwear(char)
	end
	for _, key in ipairs({ "DarkCloak", "DarkHood", "CaelenArmor", "PotbellyArmor" }) do
		if not worn[key] then
			Armor.unwear(char, key)
		end
	end
	-- armor that makes you bigger (Config.Armor Grow): the whole rig, then your weapon rebuilt to fit
	if Armor.grow(char, Config.armorBonus(player).Grow) then
		Core.equipWeapon(player, player:GetAttribute("Weapon") or "Sword")
	end
	if worn.Helmet then
		wearHelmet(char)
	end
	if worn.Motley then
		Roster.byKind.Taylor.wear(char)
	end
	if worn.DarkCloak then
		Armor.wearDarkCloak(char)
	end
	if worn.CaelenArmor then
		Armor.wearCaelen(char)
	end
	if worn.PotbellyArmor then
		Armor.wearPotbelly(char)
	end
	if worn.DarkHood then
		Armor.wearDarkHood(char)
	end
	Armor.aura(char, Config.armorBonus(player).Aura)
end
Map.Pickups.Helmet.Prompt.Triggered:Connect(function(player)
	if not Map.Pickups.Helmet.Prompt.Enabled then
		return
	end
	takePickup(Map.Pickups.Helmet)
	player:SetAttribute("Helmet", true)
	if not Config.wornArmor(player).Helmet then
		Config.wearArmor(player, "Helmet") -- (worn straight away: dressArmor)
	end
	FxRemote:FireClient(player, "Message", "Castellan's Helm. A crowned great helm, kept polished by someone. You put it on, and feel sturdier for it.")
end)
-- spare flasks: the armory's, and the Hollow Mansion's two
for _, pk in ipairs({ Map.Pickups.Flask, Map.Pickups.MansionFlaskA, Map.Pickups.MansionFlaskB }) do
	pk.Prompt.Triggered:Connect(function(player)
		if not pk.Prompt.Enabled then
			return
		end
		takePickup(pk)
		player:SetAttribute("ExtraFlasks", (player:GetAttribute("ExtraFlasks") or 0) + 1)
		player:SetAttribute("MaxFlasks", maxFlasks(player))
		local st = states[player]
		if st then
			st.flasks += 1
			player:SetAttribute("Flasks", st.flasks)
		end
		FxRemote:FireClient(player, "Message", "Spare Flask. Still stoppered, still full. You can carry one more draught.")
	end)
end
Map.Pickups.KeepKey.Prompt.Triggered:Connect(function(player)
	if not Map.Pickups.KeepKey.Prompt.Enabled then
		return
	end
	takePickup(Map.Pickups.KeepKey)
	player:SetAttribute("KeepKey", true)
	FxRemote:FireClient(player, "Message", "Key to the Battlements. Heavy iron, warm, as if a hand let go of it only just now.")
end)
Map.Pickups.ChestKey.Prompt.Triggered:Connect(function(player)
	if not Map.Pickups.ChestKey.Prompt.Enabled then
		return
	end
	takePickup(Map.Pickups.ChestKey)
	player:SetAttribute("ChestKey", true)
	FxRemote:FireClient(player, "Message", "Castellan's Chest Key. Small, plain, worn smooth. It would fit the chests of his keep.")
end)
Map.Pickups.TunnelKey.Prompt.Triggered:Connect(function(player)
	if not Map.Pickups.TunnelKey.Prompt.Enabled then
		return
	end
	takePickup(Map.Pickups.TunnelKey)
	player:SetAttribute("TunnelKey", true)
	FxRemote:FireClient(player, "Message", "Tunnel Key. Rusted through, grey sinew knotted round its bow. It would fit the door at the end of the high bridge.")
end)

-- the keep's locked chests (MapBuilder: KeepChests), opened with the chest key, once (for everyone)
local TweenService = game:GetService("TweenService")
for _, ch in ipairs(Map.KeepChests) do
	ch.Prompt.Triggered:Connect(function(player)
		if not ch.Prompt.Enabled then
			return
		end
		if not player:GetAttribute("ChestKey") then
			FxRemote:FireClient(player, "Message", "Locked.")
			return
		end
		ch.Prompt.Enabled = false
		local swung = ch.Hinge * CFrame.Angles(math.rad(110), 0, 0) * ch.Hinge:Inverse() * ch.Lid.CFrame
		TweenService:Create(ch.Lid, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = swung }):Play()
		playSound(ch.Lid, SOUNDS.Unsheath, 0.6, 0.6)
		local def = ch.Loot and Config.Weapons[ch.Loot]
		if not def then
			FxRemote:FireClient(player, "Message", "Nothing inside but dust.")
			return
		end
		player:SetAttribute("Has_" .. ch.Loot, true)
		FxRemote:FireClient(player, "Message", def.Name .. ". Press T to choose weapons and armor.")
	end)
end

-- the mushroom huts' chests (MapBuilder: MushroomChests): unlocked, opened once (for everyone); each holds
-- one item, a player attribute (the Bleak Manor key, the Foul Dagger; the Dark Book's is empty - Aldous drops it now)
for _, ch in ipairs(Map.MushroomChests) do
	ch.Prompt.Triggered:Connect(function(player)
		if not ch.Prompt.Enabled then
			return
		end
		ch.Prompt.Enabled = false
		local swung = ch.Hinge * CFrame.Angles(math.rad(110), 0, 0) * ch.Hinge:Inverse() * ch.Lid.CFrame
		TweenService:Create(ch.Lid, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = swung }):Play()
		playSound(ch.Lid, SOUNDS.Unsheath, 0.6, 0.6)
		if ch.Item.Attr then -- (an empty one has none)
			player:SetAttribute(ch.Item.Attr, true)
		end
		FxRemote:FireClient(player, "Message", ch.Item.Text)
	end)
end

-- the grate over the hole down to the Oculast arena (MapBuilder: HoleGrate): a prompt slides it aside, for good
do
	local G = Map.HoleGrate
	G.Prompt.Triggered:Connect(function(player)
		if not G.Prompt.Enabled then
			return
		end
		G.Prompt.Enabled = false
		FxRemote:FireClient(player, "Message", "The grate scrapes aside. A long way down.")
		for _, p in ipairs(G.Parts) do
			playSound(p, SOUNDS.Impact, 0.5, 0.5)
			p.CanCollide = false
			TweenService:Create(p, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = p.Position + Vector3.new(0, 0, -14) }):Play()
		end
	end)
end

-- the Citadel's gate and its winch (MapBuilder: CitadelGate, CitadelWinch): the Steel Crank, from the Usher's
-- chest, fits the winch; turning it raises the gate for everyone, for good
do
	local W, G = Map.CitadelWinch, Map.CitadelGate
	local up = false
	W.Prompt.Triggered:Connect(function(player)
		if up then
			return
		end
		if not player:GetAttribute("SteelCrank") then
			FxRemote:FireClient(player, "Message", "A winch for the gate. Its crank is long gone.")
			return
		end
		up = true
		W.Prompt.Enabled = false
		FxRemote:FireClient(player, "Message", "The Steel Crank fits. The gate groans.")
		for _, p in ipairs(W.Crank) do
			p.Transparency = 0
		end
		-- the handle turns while the gate climbs
		task.spawn(function()
			local c0 = W.Crank[1].CFrame
			local axis = c0.Position
			for i = 1, 90 do
				local rot = CFrame.new(axis) * CFrame.Angles(i / 90 * math.pi * 6, 0, 0) * CFrame.new(-axis)
				for _, p in ipairs(W.Crank) do
					p.CFrame = rot * (p == W.Crank[1] and c0 or W.CrankHome[p])
				end
				task.wait(1 / 30)
			end
		end)
		playSound(G.Bars[1], SOUNDS.Impact, 0.8, 0.4)
		FxRemote:FireAllClients("Message", "The gate to the Hollow Mansion grinds open.")
		G.Blocker.CanCollide = false
		for _, p in ipairs(G.Bars) do
			TweenService:Create(p, TweenInfo.new(3.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { Position = p.Position + Vector3.new(0, 12, 0) }):Play()
		end
	end)
	W.CrankHome = {}
	for _, p in ipairs(W.Crank) do
		W.CrankHome[p] = p.CFrame
	end
end

-- locked doors: each opens with its key (a player attribute), for everyone, and stays open
--   the battlement door on the keep's roof (the strongroom's key)
--   the tunnel door at the end of the high bridge over the encampment (the far ravine's key);
--     the old hag shut in behind it falls out (onOpen: Characters/Hag)
local function swingDoor(D)
	D.Prompt.Enabled = false
	playSound(D.Leaf.PrimaryPart, SOUNDS.Unsheath, 0.9, 0.35)
	local start = D.Leaf:GetPivot()
	task.spawn(function()
		task.wait(0.3)
		local h = CFrame.new(D.Hinge)
		for i = 1, 40 do
			local a = math.sin(i / 40 * math.pi / 2) * math.pi / 2
			D.Leaf:PivotTo(h * CFrame.Angles(0, D.Sign * a, 0) * h:Inverse() * start)
			task.wait(1 / 30)
		end
		playSound(D.Leaf.PrimaryPart, SOUNDS.Impact, 0.7, 0.5)
	end)
end
local function lockedDoor(D, keyAttr, lockedText, onOpen)
	local open = false
	D.Prompt.Triggered:Connect(function(player)
		if open then
			return
		end
		if not player:GetAttribute(keyAttr) then
			FxRemote:FireClient(player, "Message", lockedText)
			return
		end
		open = true
		FxRemote:FireClient(player, "Message", "The key turns.")
		swingDoor(D)
		if onOpen then
			onOpen()
		end
	end)
end
lockedDoor(Map.RoofDoor, "KeepKey", "Locked. A heavy lock, made for a heavy key.")
lockedDoor(Map.TunnelDoor, "TunnelKey", "Locked. The lock is caked in rot, but it's whole.", Roster.byKind.Hag.emerge)

-- the Hollow Mansion's doors that open from one side only: from the other, they will not budge
-- (which prompt fired says nothing: both reach through the door, so where the player stands decides)
for _, D in ipairs(Map.MansionDoors) do
	local function try(player)
		if not D.Prompt.Enabled then
			return
		end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - D.Hinge):Dot(D.Normal) > 0 then
			D.Blocked.Enabled = false
			swingDoor(D)
		else
			FxRemote:FireClient(player, "Message", "It will not budge. It must open from the other side.")
		end
	end
	D.Prompt.Triggered:Connect(try)
	D.Blocked.Triggered:Connect(try)
end

-- the dry brushwood choking the west tunnel off the high bridge (MapBuilder: Map.Brushwood):
-- a fireball sets it Lit (Knight's castFireball), it goes up, chars and falls away, and the
-- way through is open, for everyone
do
	local B = Map.Brushwood
	B:GetAttributeChangedSignal("Lit"):Connect(function()
		if B:GetAttribute("Burning") then
			return
		end
		B:SetAttribute("Burning", true)
		local parts = {}
		for _, p in ipairs(B:GetDescendants()) do
			if p:IsA("BasePart") then
				table.insert(parts, p)
			end
		end
		for i, p in ipairs(parts) do
			if p.Transparency < 1 and i % 3 == 0 then
				local f = Instance.new("Fire")
				f.Size, f.Heat = 7, 12
				f.Color, f.SecondaryColor = Color3.fromRGB(255, 120, 30), Color3.fromRGB(255, 220, 120)
				f.Parent = p
			end
		end
		local glow = Instance.new("PointLight")
		glow.Color, glow.Range, glow.Brightness = Color3.fromRGB(255, 150, 60), 24, 3
		glow.Parent = parts[1]
		playSound(parts[1], SOUNDS.FireHit, 1, 0.6)
		task.delay(2.5, function()
			for _, p in ipairs(parts) do
				if p.Transparency < 1 then
					TweenService:Create(p, TweenInfo.new(2.5), { Color = Color3.fromRGB(24, 20, 18), Transparency = 1 }):Play()
				end
			end
			task.wait(1.5)
			for _, p in ipairs(parts) do
				p.CanCollide = false
			end
			task.wait(1.5)
			B:Destroy()
		end)
	end)
end

-- the prison's bell, at the end of the battlements: rung from its rope once the Castellan
-- has fallen (Characters/Castellan enables the prompt). It swings out and back, tolling.
do
	local B = Map.Bell
	local rel = {}
	for i, p in ipairs(B.Parts) do
		rel[i] = B.Pivot:ToObjectSpace(p.CFrame)
	end
	local ringing = false
	B.Prompt.Triggered:Connect(function(player)
		if ringing then
			return
		end
		ringing = true
		B.Prompt.Enabled = false
		if not player:GetAttribute("RangBell") then
			player:SetAttribute("RangBell", true)
			FxRemote:FireClient(player, "Message", "The bell tolls out over the prison, for the first time in a long while.")
		end
		task.spawn(Carrier.take, player) -- (something hears it: once, for whoever rang)
		task.spawn(function()
			local t0 = os.clock()
			local tolled = 0
			while true do
				local t = os.clock() - t0
				if t >= 6 then
					break
				end
				local a = math.sin(t * math.pi / 1.5) * 0.45 * (1 - t / 6) -- swings out and back, dying away
				for i, p in ipairs(B.Parts) do
					p.CFrame = B.Pivot * CFrame.Angles(a, 0, 0) * rel[i]
				end
				if t >= tolled * 1.5 + 0.75 then -- a toll at the height of each swing
					tolled += 1
					playSound(B.Parts[1], SOUNDS.Impact, 1, 0.22)
					FxRemote:FireAllClients("Shake", B.Parts[1].Position, 0.4)
				end
				task.wait()
			end
			for i, p in ipairs(B.Parts) do
				p.CFrame = B.Pivot * rel[i]
			end
			ringing = false
			B.Prompt.Enabled = true
		end)
	end)
end

-- dev menu cheats (the client's K menu): only while Config.Debug is on
ActionRemote.OnServerEvent:Connect(function(player, action)
	if action == "DevLadder" and Config.Debug then
		kickLadder(player)
	elseif action == "DevKeepStair" and Config.Debug then
		local char = aliveChar(player)
		if char then
			char:PivotTo(Map.KeepStair)
		end
	elseif action == "DevNewArea" and Config.Debug then
		local char = aliveChar(player)
		if char then
			char:PivotTo(Map.NewArea.Landing)
		end
	elseif action == "DevTownship" and Config.Debug then
		-- just through the Warden's arena exit, into Gallows Square, where the dogs are
		local char = aliveChar(player)
		if char then
			char:PivotTo(CFrame.lookAt(Vector3.new(64, 3, 260), Vector3.new(124, 3, 252)))
		end
	elseif action == "DevCastellanHP" and Config.Debug then
		Castellan.devWound()
	elseif action == "DevColosseum" and Config.Debug then
		local char = aliveChar(player)
		if char then
			char:PivotTo(Map.ColosseumDev)
		end
	elseif action == "DevCitadel" and Config.Debug then
		local char = aliveChar(player)
		if char then
			char:PivotTo(Map.CitadelDev)
		end
	elseif action == "DevAtticStair" and Config.Debug then
		local char = aliveChar(player)
		if char then
			char:PivotTo(Map.AtticStairDev)
		end
	elseif action == "DevFallenStair" and Config.Debug then
		local char = aliveChar(player)
		if char then
			char:PivotTo(Map.FallenStairDev)
		end
	elseif action == "DevMesa" and Config.Debug then
		local char = aliveChar(player)
		if char then
			char:PivotTo(Map.MesaDev)
		end
	elseif action == "DevChampionHP" and Config.Debug then
		Champion.devWound()
	elseif action == "DevConsulHP" and Config.Debug then
		Roster.byKind.Consul.devWound()
	elseif action == "DevBulwark" and Config.Debug then
		local char = aliveChar(player)
		if char and Map.Bulwark then
			char:PivotTo(Map.Bulwark.Dev)
		end
	elseif action == "DevPyralis" and Config.Debug then
		-- the way east's last stretch, ten short of the arena's gate, facing it
		local char = aliveChar(player)
		local door = Map.Underfire and Map.Underfire.Arena and Map.Underfire.Arena.Door
		if char and door then
			char:PivotTo(CFrame.lookAt(door + Vector3.new(0, 3.2, -10), door + Vector3.new(0, 3.2, 20)))
		end
	end
end)

-- climbing it: Climbing is off for every rig, so you're carried hand over hand up the
-- rungs and over the top (or the reverse), pinned and with your inputs held meanwhile
local climbing = {}
local function climbLadder(player, up, L)
	local char, _, hrp = aliveChar(player)
	local st = states[player]
	if not (char and st) or climbing[player] or now() < (st.busyUntil or 0) then
		return
	end
	climbing[player] = true
	local C = L.Climb
	local RUNG_SPEED = 9 -- studs per second up or down the rungs
	-- legs of the trip: { from, to, seconds, onRungs }
	local legs = up and {
		{ C.foot, C.top, (C.top - C.foot).Magnitude / RUNG_SPEED, true },
		{ C.top, C.off, 0.45, false },
	} or {
		{ C.off, C.top, 0.45, false },
		{ C.top, C.foot, (C.top - C.foot).Magnitude / RUNG_SPEED, true },
	}
	local total = legs[1][3] + legs[2][3]
	Core.setAction(st, now(), total, total, total)
	st.healing = false
	Core.cancelSwing(st)
	FxRemote:FireClient(player, "Grabbed", total) -- (the client holds its inputs too)
	local facing = Vector3.new(1, 0, 0) -- toward the wall
	local function pose(name, blend)
		char:SetAttribute("BP", name)
		char:SetAttribute("BPT", blend)
		char:SetAttribute("BPN", (char:GetAttribute("BPN") or 0) + 1)
	end
	hrp.Anchored = true
	for _, leg in ipairs(legs) do
		local a, b, dur, rungs = leg[1], leg[2], leg[3], leg[4]
		local t0, lastStep, n = os.clock(), -1, 0
		while hrp.Parent and aliveChar(player) == char do
			local k = math.min((os.clock() - t0) / dur, 1)
			hrp.CFrame = CFrame.lookAt(a:Lerp(b, k), a:Lerp(b, k) + facing)
			if rungs and os.clock() - lastStep > 0.3 then -- hand over hand
				lastStep = os.clock()
				n += 1
				pose(n % 2 == 0 and "Climb" or "Climb2", 0.25)
				playSound(hrp, SOUNDS.Unsheath, 0.15, 0.4 + math.random() * 0.1) -- the wood creaks
			elseif not rungs and k == 0 then
				pose("Idle", 0.3)
			end
			if k >= 1 then
				break
			end
			task.wait()
		end
	end
	if hrp.Parent then
		hrp.Anchored = false
		pcall(function()
			hrp:SetNetworkOwner(player)
		end)
		pose("Idle", 0.2)
	end
	climbing[player] = nil
end
for _, L in ipairs({ yardLadder, Map.MansionLadder, Map.WingLadder }) do
	L.UpPrompt.Triggered:Connect(function(player)
		climbLadder(player, true, L)
	end)
	L.DownPrompt.Triggered:Connect(function(player)
		climbLadder(player, false, L)
	end)
end

Map.LockedPrompt.Triggered:Connect(function(player)
	FxRemote:FireClient(player, "Message", "It will not budge. It must open from the other side.")
end)

Map.FogPrompt.Triggered:Connect(function(player)
	local char = aliveChar(player)
	if not char or Warden.isDead() then
		return
	end
	char:PivotTo(Map.ArenaEntry)
	FxRemote:FireClient(player, "Fog")
	Warden.start()
end)

-- the rusted key, on the mantel in the one open house in the Lane, and the gate it opens
-- (the last fence before the standing house). Whoever has the key opens it for everyone,
-- and it stays open. The key is kept across deaths (a player attribute).
do
	local key, gate = Map.GateKey, Map.TownGate
	key.Prompt.Triggered:Connect(function(player)
		if player:GetAttribute("GateKey") then
			return
		end
		player:SetAttribute("GateKey", true)
		for _, p in ipairs(key.Parts) do
			p.Transparency = 1
			for _, c in ipairs(p:GetChildren()) do
				if c:IsA("ParticleEmitter") then
					c.Enabled = false
				end
			end
		end
		key.Prompt.Enabled = false
		playSound(key.Parts[1], SOUNDS.Unsheath, 0.5, 1.6)
		FxRemote:FireClient(player, "Message", "Rusted Key. Heavy, and old. It looks like it would fit a gate.")
	end)
	local opened = false
	gate.Prompt.Triggered:Connect(function(player)
		if opened then
			return
		end
		if not player:GetAttribute("GateKey") then
			FxRemote:FireClient(player, "Message", "Locked. Chained and padlocked. Someone in this town had the key.")
			return
		end
		opened = true
		gate.Prompt.Enabled = false
		gate.Wall.CanCollide = false
		for _, p in ipairs(gate.Lock) do
			p.Anchored = false -- the padlock and chain drop
			p.CanCollide = true
		end
		playSound(gate.Lock[#gate.Lock], SOUNDS.Unsheath, 1, 0.5)
		FxRemote:FireClient(player, "Message", "The rusted lock gives, and the gate grinds open.")
		for _, leaf in ipairs(gate.Leaves) do
			local rel = leaf.Hinge:ToObjectSpace(leaf.Model:GetPivot())
			task.spawn(function()
				for i = 1, 60 do
					local k = i / 60
					local eased = 1 - (1 - k) * (1 - k)
					leaf.Model:PivotTo(leaf.Hinge * CFrame.Angles(0, leaf.Swing * 1.75 * eased, 0) * rel)
					task.wait(1 / 30)
				end
			end)
		end
	end)
end

-- the shop window on Gallows Square: hold E with the old brick to smash it (the brick goes
-- through it), and the house behind it can be climbed into over the low sill
do
	local win = Map.TownWindow
	local DebrisService = game:GetService("Debris")
	win.Prompt.Triggered:Connect(function(player)
		if not player:GetAttribute("OldBrick") then
			FxRemote:FireClient(player, "Message", "Old, thick glass. You'd need something heavy to break it.")
			return
		end
		player:SetAttribute("OldBrick", nil)
		local glass = win.Panes[1]
		local inward = -glass.CFrame.LookVector
		playSound(glass, SOUNDS.Impact, 1, 1.7)
		for _ = 1, 16 do
			local shard = Instance.new("Part")
			shard.Name = "GlassShard"
			shard.Size = Vector3.new(math.random(2, 6) / 10, 0.05, math.random(2, 5) / 10)
			shard.Material = Enum.Material.Glass
			shard.Color = glass.Color
			shard.Transparency = 0.4
			shard.CFrame = glass.CFrame * CFrame.new((math.random() - 0.5) * glass.Size.X, (math.random() - 0.5) * glass.Size.Y, 0) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
			shard.CollisionGroup = "Debris"
			shard.AssemblyLinearVelocity = inward * math.random(8, 18) + Vector3.new(0, math.random(2, 8), 0)
			shard.Parent = workspace
			DebrisService:AddItem(shard, 5)
		end
		for _, p in ipairs(win.Panes) do
			p:Destroy()
		end
		FxRemote:FireClient(player, "Message", "The old brick goes through the glass. You can climb in.")
	end)
end

-- the old brick, lying on the floor of the standing house at the end of the township
do
	local brick = Map.OldBrick
	brick.Prompt.Triggered:Connect(function(player)
		if player:GetAttribute("OldBrick") then
			return
		end
		player:SetAttribute("OldBrick", true)
		for _, p in ipairs(brick.Parts) do
			p.Transparency = 1
			for _, c in ipairs(p:GetChildren()) do
				if c:IsA("ParticleEmitter") then
					c.Enabled = false
				end
			end
		end
		brick.Prompt.Enabled = false
		playSound(brick.Parts[1], SOUNDS.Impact, 0.4, 1.1)
		FxRemote:FireClient(player, "Message", "Old brick acquired")
	end)
end

-- the Usher's chest (behind the gate that opens when she dies). Every player loots their
-- own copy of it: opening it shows its contents (SoulsClient's chest panel), and dragging
-- a ring onto a ring slot asks here to take it. A ring already in that slot goes back in.
do
	local chest = Map.UsherChest
	local lidRel = chest.Hinge:ToObjectSpace(chest.Lid:GetPivot())
	local opened = false
	local contents = {} -- [player] = { ring ids still in the chest }
	local function show(player, st)
		local rings = {}
		for i = 1, P.RingSlots do
			rings[i] = st.rings[i] or "" -- no holes: remotes drop sparse arrays
			player:SetAttribute("Ring" .. i, st.rings[i]) -- (the equipment menu reads these)
		end
		FxRemote:FireClient(player, "Chest", contents[player], rings)
	end
	chest.Prompt.Triggered:Connect(function(player)
		local st = states[player]
		if not st then
			return
		end
		st.rings = st.rings or {}
		contents[player] = contents[player] or { "Embellishment" }
		if not player:GetAttribute("SteelCrank") then -- (the chest holds the crank to the Citadel's gate)
			player:SetAttribute("SteelCrank", true)
			FxRemote:FireClient(player, "Message", "Steel Crank. Heavy, geared, cold: the handle of some great winch.")
		end
		if not opened then
			opened = true
			playSound(chest.Prompt.Parent, SOUNDS.Impact, 0.8, 0.6)
			task.spawn(function()
				for i = 1, 20 do
					chest.Lid:PivotTo(chest.Hinge * CFrame.Angles(1.9 * (i / 20), 0, 0) * lidRel)
					task.wait(1 / 30)
				end
			end)
		end
		show(player, st)
	end)
	ActionRemote.OnServerEvent:Connect(function(player, action, id, slot)
		if action ~= "TakeRing" then
			return
		end
		local st, items = states[player], contents[player]
		local _, _, hrp = aliveChar(player)
		if not (st and items and hrp and typeof(id) == "string" and typeof(slot) == "number") then
			return
		end
		if slot % 1 ~= 0 or slot < 1 or slot > P.RingSlots or (hrp.Position - chest.Hinge.Position).Magnitude > 12 then
			return
		end
		local at = table.find(items, id)
		if not at then
			return
		end
		table.remove(items, at)
		if st.rings[slot] then
			table.insert(items, st.rings[slot])
		end
		st.rings[slot] = id
		show(player, st)
	end)
end

for _, pp in ipairs(Map.Notes or {}) do
	pp.Triggered:Connect(function(player)
		FxRemote:FireClient(player, "Note", pp:GetAttribute("Title"), pp:GetAttribute("Text"))
	end)
end

Mabel.spawn() -- the girl in the nook (Characters/Mabel.lua)
Roster.byKind.Taylor.spawn() -- the old tailor by the Crossing (Characters/Taylor.lua)

for _, pp in ipairs(Map.Messages) do
	pp.Triggered:Connect(function(player)
		FxRemote:FireClient(player, "Message", pp:GetAttribute("Text"))
	end)
end

---------------------------------------------------------------------------
-- players
---------------------------------------------------------------------------
local function onCharacter(player, char)
	local st = states[player]
	if not st then
		return
	end
	local hum = char:WaitForChild("Humanoid")
	char:WaitForChild("HumanoidRootPart")
	hum.MaxHealth = maxHealth(player)
	hum.Health = hum.MaxHealth
	hum.WalkSpeed = P.WalkSpeed
	hum.UseJumpPower = false
	hum.JumpHeight = 0
	hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	applyLimbGroup(char)
	char:WaitForChild("HumanoidRootPart").CollisionGroup = "PlayerRoot"
	-- a faint personal light so you can always see your feet
	local lantern = Instance.new("PointLight")
	lantern.Name = "Lantern"
	lantern.Color = Color3.fromRGB(255, 205, 150)
	lantern.Range = 13
	lantern.Brightness = 0.6
	lantern.Shadows = false
	lantern.Parent = char:WaitForChild("HumanoidRootPart")
	st.stamina = P.MaxStamina
	st.flasks = maxFlasks(player)
	st.busyUntil, st.dodgeAt, st.attackAt = 0, 0, 0
	st.attackId = (st.attackId or 0) + 1
	st.lastKind, st.lastStep, st.comboUntil = nil, 0, 0
	st.iStart, st.iEnd = 0, 0
	st.hurtImmuneUntil = 0
	st.healing = false
	st.sprinting = false
	st.weld, st.scale, st.shoulder, st.c0 = nil, 1, nil, nil
	player:SetAttribute("Flasks", st.flasks)
	player:SetAttribute("MaxFlasks", maxFlasks(player))
	syncStamina(player, st)

	task.spawn(function()
		if not char:IsDescendantOf(workspace) then
			char.AncestryChanged:Wait()
		end
		task.wait()
		char:PivotTo(st.checkpoint)
	end)

	task.spawn(function()
		if not char:GetAttribute("PrisonRig") then
			-- not our knight rig (shouldn't happen): wait for the avatar to finish loading
			local t0 = os.clock()
			while not player:HasAppearanceLoaded() and os.clock() - t0 < 5 do
				task.wait(0.1)
			end
		end
		task.wait(0.05)
		if not char.Parent then
			return
		end
		st.scale = 1
		Core.equipWeapon(player, player:GetAttribute("Weapon") or "Sword")
		dressArmor(player, char)
		st.model = char
		local motors, constraints = 0, 0
		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("Motor6D") then
				motors += 1
			elseif d:IsA("AnimationConstraint") then
				constraints += 1
			end
		end
		if constraints > 0 then
			warn("[DGUS] the knight rig was converted to AnimationConstraints - limbs can't be animated. Check Workspace avatar joint settings.")
		end
		if Config.Debug then
			print(string.format("[Combat] %s armed. Rig: %s (%d Motor6D joints)", player.Name, tostring(char:GetAttribute("PrisonRig")), motors))
		end
	end)

	hum.Died:Connect(function()
		onPlayerDied(player)
	end)
end

local function onPlayerAdded(player)
	-- armor changed (found, or picked in the menu): dress for it now (and on every spawn)
	for _, slot in ipairs(Config.ArmorSlots) do
		player:GetAttributeChangedSignal("Armor" .. slot):Connect(function()
			if player.Character then
				dressArmor(player, player.Character)
			end
			refreshHealth(player)
		end)
	end
	states[player] = {
		stamina = P.MaxStamina,
		lastSpend = 0,
		busyUntil = 0,
		dodgeAt = 0,
		attackAt = 0,
		attackId = 0,
		lastStep = 0,
		comboUntil = 0,
		iStart = 0,
		iEnd = 0,
		deflectStart = 0,
		deflectEnd = 0,
		hurtImmuneUntil = 0,
		sprinting = false,
		flasks = P.Flasks,
		healing = false,
		checkpoint = Map.Spawn,
		seenZones = {},
		zone = nil,
	}
	player:SetAttribute("MaxStamina", P.MaxStamina)
	player:GetAttributeChangedSignal("Weapon"):Connect(function()
		refreshHealth(player) -- (a weapon's HealthBonus)
	end)
	player.CharacterAdded:Connect(function(c)
		onCharacter(player, c)
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, pl in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, pl)
end
Players.PlayerRemoving:Connect(function(pl)
	states[pl] = nil
end)

---------------------------------------------------------------------------
-- per-frame: stamina, area names
---------------------------------------------------------------------------
local function zoneAt(pos)
	for _, z in ipairs(Map.Zones) do
		if pos.X >= z.MinX and pos.X <= z.MaxX and pos.Z >= z.MinZ and pos.Z <= z.MaxZ and (not z.MinY or pos.Y >= z.MinY) and (not z.MaxY or pos.Y <= z.MaxY) then
			return z.Name
		end
	end
	return nil
end

-- The breach at the end of the Fallen Cellblock (Map.Underfire): the first time you reach its lip, a cutscene - the
-- knight creeps out, falters, leaps into the burning pit and is gone into the dark - then he stands in the buried room
-- below and the camera looks it over. Later (quick), dropping into the pit just cuts there.
-- The Malformed Watchdog, in Pyralis's arena. The first time anyone steps off the north bridge onto the island, its
-- entrance: everyone on the island held while it hauls itself out of its lair (PyralisProto's clients pose it off EmergeAt)
-- and fixes on you. Then it fights: a stand-in among the enemies to lock onto and hit, its health bar up whenever someone
-- alive is on the island, and every few seconds the twisting leap or the helix of fire.
if Map.Underfire and Map.Underfire.Arena then
	local ok, err = pcall(function() -- (a prototype must never stop the server starting)
		local Proto = require(ReplicatedStorage:WaitForChild("PyralisProto"))
		local Ar = Map.Underfire.Arena
		local model = Proto.build(Ar.Centre)
		local function onIsland(p)
			return p.X > Ar.MinX and p.X < Ar.MaxX and p.Z > Ar.MinZ and p.Z < Ar.MaxZ and math.abs(p.Y - Ar.Centre.Y - 4) < 12
		end
		local shown, nextLeap, proxy = false, 0, nil
		local sinceLeap, leapEvery = 0, 3 -- (with its brother down: attacks since its last leap, and how many before the next)
		local fighters = {} -- (who's stepped onto the island against it since it was last whole: player -> their character)
		-- what blows and spells land on, standing: all of it from the floor to over its head, its forelegs to its neck (where the
		-- lock-on sits on every screen, so a beam or a fireball aimed at it passes through this)
		local TARGET_SIZE, TARGET_OFF = Vector3.new(12, 20, 18), Vector3.new(0, 10, -5)
		-- THE TRUE WATCHDOG OF PYRALIS, its brother (PyralisProto design D): down on the island once the Malformed one is a
		-- third gone. Its own stand-in, its own bar (Boss2*), its own mind: keeping well away from its brother, it flies to the
		-- pillars to rain fire down (the volley, the sunfall), or on the ground beats a gale of fire at you or dives through you.
		local T -- (the one on the island now, if any: { model, dead, destroy })
		-- THE GATES (Map.Bulwark): the north gate's portcullis down while anyone's on the island and a brother lives, once
		-- the fight's begun; the lair's once the Malformed one is out of it. Both up for good when the two are slain, and the
		-- lair's back wall opens (its door sinks, its murk lifts, its lamps come on) onto the way to the great lift
		local Bw = Map.Bulwark
		local malDead, won, emergedAt = false, false, nil
		local gateDown, gateBase = {}, {}
		local function setGate(i, down)
			local g = Bw and Bw.Gates[i]
			if not g or (gateDown[i] or false) == down then
				return
			end
			gateDown[i] = down
			for _, p in ipairs(g.Parts) do
				gateBase[p] = gateBase[p] or p.CFrame
				local info = down and TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In) or TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				TweenService:Create(p, info, { CFrame = gateBase[p] - Vector3.new(0, down and g.Up or 0, 0) }):Play()
			end
			g.Blocker.CanCollide = down
			playSound(g.Parts[1], down and SOUNDS.Impact or SOUNDS.Unsheath, 2.5, down and 0.5 or 0.4)
		end
		task.spawn(function()
			while true do
				task.wait(0.25)
				local anyIn = false
				for _, pl in ipairs(Players:GetPlayers()) do
					local char, _, hrp = aliveChar(pl)
					anyIn = anyIn or (char ~= nil and onIsland(hrp.Position))
				end
				emergedAt = emergedAt or model:GetAttribute("EmergeAt")
				local on = anyIn and emergedAt ~= nil and not won and (not malDead or (T ~= nil and not T.dead))
				setGate(1, on)
				setGate(2, on and workspace:GetServerTimeNow() - emergedAt > Proto.Total)
			end
		end)
		local function openLair()
			local L = Bw and Bw.Lair
			if not L then
				return
			end
			TweenService:Create(L.Door, TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = L.Door.CFrame - Vector3.new(0, 21, 0) }):Play()
			L.Door.CanCollide = false
			playSound(L.Door, SOUNDS.Impact, 3, 0.35)
			for _, m in ipairs(L.Murk) do
				TweenService:Create(m, TweenInfo.new(4), { Transparency = 1 }):Play()
			end
			for _, l in ipairs(L.Lamps) do
				l.Enabled = true
			end
			FxRemote:FireAllClients("Message", "Deep in the lair, stone grinds open.")
		end
		-- one brother slain: only once the other's down too (or never came) the victory, and two splinters where the last fell
		local function felled(at)
			if (T == nil or T.dead) and not (proxy and proxy.Parent and proxy.Humanoid.Health > 0) then
				FxRemote:FireAllClients("Banner", "WATCHDOGS FELLED", "Victory")
				won = true
				task.delay(3, openLair)
				at = Vector3.new(at.X, Ar.Centre.Y + 3, at.Z) -- (on the floor, not on the spire it fell from)
				for _, sp in ipairs(Ar.Spires or {}) do
					local off = Vector3.new(at.X - sp[1], 0, at.Z - sp[2])
					if off.Magnitude < 7 then
						at += (off.Magnitude > 0.1 and off.Unit or Vector3.new(1, 0, 0)) * (7 - off.Magnitude)
					end
				end
				Core.dropSplinter(at + Vector3.new(3, 0, 0))
				Core.dropSplinter(at + Vector3.new(-3, 0, 2))
				for _, pl in ipairs(Players:GetPlayers()) do -- (and their fang, to everyone who fought them on the island)
					local char, _, hrp = aliveChar(pl)
					if char and onIsland(hrp.Position) and not pl:GetAttribute("Has_PyralisFang") then
						pl:SetAttribute("Has_PyralisFang", true)
						FxRemote:FireClient(pl, "Message", Config.Weapons.PyralisFang.Name .. ". Press T to choose weapons and armor.")
					end
				end
			end
		end
		local function flatDist(a, b)
			return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
		end
		local function spawnTrue()
			local FY = Ar.Centre.Y
			local function brother() -- (where the Malformed one stands, while it lives)
				return model.Parent and proxy and proxy.Parent and proxy.Humanoid.Health > 0 and (model:GetAttribute("LeapTo") or model:GetAttribute("Base").Position) or nil
			end
			local function onIt()
				local list = {}
				for _, pl in ipairs(Players:GetPlayers()) do
					local char, _, hrp = aliveChar(pl)
					if char and states[pl] and onIsland(hrp.Position) then
						table.insert(list, { pl, hrp })
					end
				end
				return list
			end
			-- somewhere on the island to stand: clear of the pillars, far from its brother, about 24 from tp (if given)
			local function spot(tp)
				local best, bs
				for _ = 1, 24 do
					local p = Vector3.new(math.random(Ar.MinX + 10, Ar.MaxX - 10), FY, math.random(Ar.MinZ + 10, Ar.MaxZ - 10))
					local clear = true
					for _, list in ipairs({ Ar.Pillars, Ar.Spires }) do
						for _, pi in ipairs(list) do
							if flatDist(p, Vector3.new(pi[1], 0, pi[2])) < pi[3] + 5 then
								clear = false
							end
						end
					end
					if clear then
						local b = brother()
						local s = (b and math.min(flatDist(p, b), 80) or 0) - (tp and math.abs(flatDist(p, tp) - 24) * 0.8 or 0)
						if not bs or s > bs then
							best, bs = p, s
						end
					end
				end
				return best or Ar.Centre
			end
			-- its entrance: a dive out of the dark, from high and far off its brother's side, down onto a ring it marks under
			-- one of you - a slam where it lands
			local list0 = onIt()
			local tp0 = #list0 > 0 and list0[math.random(#list0)][2].Position or spot(nil)
			local home = Vector3.new(math.clamp(tp0.X, Ar.MinX + 8, Ar.MaxX - 8), FY, math.clamp(tp0.Z, Ar.MinZ + 8, Ar.MaxZ - 8))
			local away = brother() and Vector3.new(home.X - brother().X, 0, home.Z - brother().Z) or Vector3.new(0, 0, -1)
			away = away.Magnitude > 0.1 and away.Unit or Vector3.new(0, 0, -1)
			local tm = Proto.buildTrue(home)
			local self = { model = tm, dead = false }
			local function pos()
				return (Proto.trueAt(tm, workspace:GetServerTimeNow()))
			end
			local function setMove(from, to, arc, dur, kind)
				tm:SetAttribute("MoveFrom", from)
				tm:SetAttribute("MoveTo", to)
				tm:SetAttribute("MoveArc", arc)
				tm:SetAttribute("MoveTime", dur)
				tm:SetAttribute("MoveKind", kind)
				tm:SetAttribute("MoveAt", workspace:GetServerTimeNow())
			end
			setMove(home + away * 45 + Vector3.new(0, 55, 0), home, 0, Proto.EnterTime, "dive")
			tm:SetAttribute("EnterTo", home)
			tm:SetAttribute("EnterAt", workspace:GetServerTimeNow())
			tm.Parent = workspace:FindFirstChild("PyralisProtos")
			-- its stand-in among the enemies: what you lock onto and hit, kept on its body wherever it flies
			local px = Instance.new("Model")
			px.Name = Proto.TrueName
			px:SetAttribute("Boss", true)
			px:SetAttribute("Radius", 3.5)
			local root = Instance.new("Part")
			root.Name = "HumanoidRootPart"
			root.Size = Vector3.new(7, 15, 7)
			root.Anchored, root.CanCollide, root.CanTouch, root.Transparency = true, false, false, 1
			root.CFrame = CFrame.new(pos() + Vector3.new(0, 7.5, 0))
			root.Parent = px
			local hum = Instance.new("Humanoid")
			hum.MaxHealth, hum.Health = Proto.TrueHP, Proto.TrueHP
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			hum.Parent = px
			px.PrimaryPart = root
			px.Parent = Core.EnemiesFolder
			local follow = game:GetService("RunService").Heartbeat:Connect(function()
				root.CFrame = CFrame.new(pos() + Vector3.new(0, 7.5, 0))
			end)
			local function live()
				return not self.dead and tm.Parent ~= nil and hum.Health > 0
			end
			local function hold(s)
				local untilT = now() + s
				while now() < untilT do
					task.wait(0.05)
					if not live() then
						return false
					end
				end
				return true
			end
			local function flyTo(p, arc, speed, kind)
				local from = pos()
				local d = (p - from).Magnitude
				local dur = math.max(0.5, d / (speed or 36))
				tm:SetAttribute("Perched", false)
				setMove(from, p, arc or math.min(16, 4 + d * 0.2), dur, kind)
				return hold(dur)
			end
			local function hurt(list, amount, from, kind)
				for _, e in ipairs(list) do
					Core.damagePlayer(e[1], amount, from, kind)
				end
			end
			local function within(at, r, dy) -- (everyone alive within r of at, flat, and dy of its height)
				local out = {}
				for _, e in ipairs(onIt()) do
					if flatDist(e[2].Position, at) < r and math.abs(e[2].Position.Y - at.Y) < dy then
						table.insert(out, e)
					end
				end
				return out
			end
			-- up onto one of its spires (the one furthest from its brother), crouched on top facing the centre
			local function perch()
				local b, best, bs = brother(), nil, nil
				for _, sp in ipairs(Ar.Spires) do
					local s = (b and flatDist(Vector3.new(sp[1], 0, sp[2]), b) or 0) + math.random() * 12
					if not bs or s > bs then
						best, bs = sp, s
					end
				end
				local top = Vector3.new(best[1], best[4], best[2])
				local d = Vector3.new(Ar.Centre.X - top.X, 0, Ar.Centre.Z - top.Z)
				d = d.Magnitude > 0.1 and d.Unit or Vector3.new(0, 0, -1)
				if not flyTo(top, 8, 34) then
					return false
				end
				tm:SetAttribute("PerchYaw", math.atan2(-d.X, -d.Z))
				tm:SetAttribute("Perched", true)
				return hold(0.35)
			end
			local function mouth()
				local yaw = tm:GetAttribute("PerchYaw") or 0
				return pos() + Vector3.new(-math.sin(yaw), 0, -math.cos(yaw)) * 3.5 + Vector3.new(0, 13, 0) -- (its head, crouched)
			end
			local function volley() -- three balls of fire, one after another, each where someone stands now
				if not perch() then
					return
				end
				for _ = 1, 3 do
					local list = onIt()
					if #list == 0 then
						break
					end
					local tp = list[math.random(#list)][2].Position
					local to = Vector3.new(tp.X, FY, tp.Z)
					tm:SetAttribute("ShotFrom", mouth())
					tm:SetAttribute("ShotTo", to)
					tm:SetAttribute("ShotAt", workspace:GetServerTimeNow())
					playSound(root, SOUNDS.FireCast, 2, 0.8)
					task.delay(Proto.ShotTime, function()
						if not self.dead then
							playSound(root, SOUNDS.FireHit, 1.6, 0.9)
							hurt(within(to, Proto.ShotR, 7), 22, to, "Large")
						end
					end)
					if not hold(0.55) then
						return
					end
				end
				hold(0.3)
			end
			local function sunfall(tp) -- a sun swollen over its head, hurled down; the ground it strikes left burning
				if not perch() then
					return
				end
				local to = Vector3.new(tp.X, FY, tp.Z)
				tm:SetAttribute("SunTo", to)
				tm:SetAttribute("SunAt", workspace:GetServerTimeNow())
				playSound(root, SOUNDS.Groan, 2, 0.4)
				task.delay(Proto.SunCharge, function()
					if not self.dead then
						playSound(root, SOUNDS.FireCast, 3, 0.5)
					end
				end)
				if not hold(Proto.SunCharge + Proto.SunFall) then
					return
				end
				Core.shockwave(to, Proto.SunR)
				playSound(root, SOUNDS.FireHit, 3, 0.6)
				hurt(within(to, Proto.SunR, 8), 38, to, "Knockdown")
				-- (the pool burns on while it swoops down)
				task.spawn(function() -- (the pool: burning whoever stands in it)
					local untilT = now() + Proto.SunBurn
					while now() < untilT and not self.dead do
						task.wait(0.5)
						hurt(within(to, Proto.PoolR, 6), 7, to, "Small")
					end
				end)
				hold(0.3)
			end
			local function gale(tp) -- wings drawn back, then two beats of fire rolling out across a wide cone
				local from = pos()
				local d = tp - from
				local yaw = math.atan2(-d.X, -d.Z)
				tm:SetAttribute("FaceYaw", yaw)
				tm:SetAttribute("GaleYaw", yaw)
				tm:SetAttribute("GaleAt", workspace:GetServerTimeNow())
				playSound(root, SOUNDS.Groan, 2, 0.6)
				for beat = 0, 1 do
					task.delay(Proto.GaleWind + beat * Proto.GaleGap, function()
						if self.dead then
							return
						end
						playSound(root, SOUNDS.FireCast, 2.5, 0.7 + beat * 0.1)
						for _, e in ipairs(onIt()) do
							if Proto.galeHit(from, yaw, e[2].Position) then
								Core.damagePlayer(e[1], 18, from, "Large")
							end
						end
					end)
				end
				hold(Proto.GaleTime)
				tm:SetAttribute("FaceYaw", nil)
			end
			local function dive(tp) -- up, and down onto where you stood, talons first: only the slam as it lands hurts
				local from = pos()
				local to = Vector3.new(math.clamp(tp.X, Ar.MinX + 8, Ar.MaxX - 8), FY, math.clamp(tp.Z, Ar.MinZ + 8, Ar.MaxZ - 8))
				playSound(root, SOUNDS.Groan, 2, 0.7)
				local dur = math.max(0.95, (to - from).Magnitude / 44) -- (time enough to see its mark and get off it)
				tm:SetAttribute("Perched", false)
				setMove(from, to, 10, dur, "dive")
				tm:SetAttribute("DiveTo", to)
				tm:SetAttribute("DiveTime", dur)
				tm:SetAttribute("DiveAt", workspace:GetServerTimeNow())
				if hold(dur) then
					Core.shockwave(to, Proto.DiveR)
					playSound(root, SOUNDS.Impact, 2, 0.7)
					hurt(within(to, Proto.DiveR, 7), 30, to, "Knockdown")
					hold(0.5)
				end
			end
			task.delay(Proto.EnterTime, function() -- (the slam as it lands)
				if not self.dead then
					Core.shockwave(home, Proto.EnterR + 2)
					playSound(root, SOUNDS.Impact, 3, 0.5)
					hurt(within(home, Proto.EnterR, 8), 28, home, "Knockdown")
				end
			end)
			-- its mind: settle after coming down, then every couple of seconds an attack - and never long near its brother. A
			-- pillar's only ever for one attack, and never two running: up, the attack, and straight back down in a swoop
			task.spawn(function()
				if not hold(Proto.EnterTime + 1.2) then
					return
				end
				local wasUp = false
				while live() do
					local list = onIt()
					if #list == 0 then
						hold(0.3)
						continue
					end
					local tp = list[math.random(#list)][2].Position
					local me, b = pos(), brother()
					if b and flatDist(me, b) < 42 then
						flyTo(spot(tp))
						continue
					end
					local r, gap = math.random(), flatDist(me, tp)
					local up = not wasUp and r < (b and 0.45 or 0.32) -- (with its brother: more often up out of reach, raining fire)
					wasUp = up
					if up and r < 0.18 then
						volley()
						flyTo(spot(tp), 3, 55) -- (the swoop down)
					elseif up then
						sunfall(tp)
						flyTo(spot(tp), 3, 55)
					elseif r < 0.7 and gap < Proto.GaleRange - 4 then
						gale(tp)
					elseif b and math.random() < 0.6 then -- (with its brother, it doesn't chase you down: it keeps its range)
						flyTo(spot(tp), 6, 30)
					else
						dive(tp)
					end
					hold(1.4 + math.random())
				end
			end)
			function self.destroy()
				self.dead = true
				follow:Disconnect()
				tm:Destroy()
				px:Destroy()
				ReplicatedStorage:SetAttribute("Boss2Active", false)
			end
			function self.heal() -- (everyone fighting it fell, its brother already slain: whole again, back down on its spot)
				hum.Health = Proto.TrueHP
				tm:SetAttribute("Perched", false)
				setMove(pos(), spot(nil), 8, 1.5, nil)
			end
			-- slain: its bar down, a burst of fire, and the victory if its brother's gone too
			hum.Died:Connect(function()
				self.dead = true
				follow:Disconnect()
				local at = root.Position
				Core.shockwave(Vector3.new(at.X, FY, at.Z), 12)
				Core.burst(at, Color3.fromRGB(255, 150, 60), 40, 0.6, 30)
				ReplicatedStorage:SetAttribute("Boss2Active", false)
				felled(at)
				tm:Destroy()
				task.delay(1, function()
					px:Destroy()
				end)
			end)
			-- its bar, and (once its brother's gone) its own reset when everyone fighting it falls
			task.spawn(function()
				local shown2, fought = false, {}
				while not self.dead do
					task.wait(0.2)
					local list = onIt()
					for _, e in ipairs(list) do
						fought[e[1]] = e[2].Parent
					end
					if #list == 0 and not brother() then
						for pl, char in pairs(fought) do
							if pl.Parent and aliveChar(pl) ~= char and live() then
								fought = {}
								self.heal()
								break
							end
						end
					end
					local want = live() and #list > 0
					if want ~= shown2 then
						shown2 = want
						if want then
							ReplicatedStorage:SetAttribute("Boss2Name", Proto.TrueName)
							ReplicatedStorage:SetAttribute("Boss2MaxHP", Proto.TrueHP)
						end
						ReplicatedStorage:SetAttribute("Boss2Active", want)
					end
					if shown2 then
						ReplicatedStorage:SetAttribute("Boss2HP", math.max(0, hum.Health))
					end
				end
			end)
			return self
		end
		task.spawn(function()
			while model.Parent do
				task.wait(0.2)
				local inside = {}
				for _, pl in ipairs(Players:GetPlayers()) do
					local char, _, hrp = aliveChar(pl)
					if char and states[pl] and onIsland(hrp.Position) then
						inside[pl] = hrp
					end
				end
				local first = next(inside)
				if first and not model:GetAttribute("EmergeAt") then
					local base = model:GetAttribute("Base")
					local shots = Proto.shots(base)
					local total = Proto.Total
					model:SetAttribute("EmergeAt", workspace:GetServerTimeNow())
					for pl, hrp in pairs(inside) do
						local st = states[pl]
						Core.setAction(st, now(), total, total, total)
						st.iStart, st.iEnd = now(), now() + total + 0.5
						st.healing = false
						Core.cancelSwing(st)
						hrp.AssemblyLinearVelocity = Vector3.zero
						hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(base.X, hrp.Position.Y, base.Z)) -- (facing where it'll come)
						hrp.Anchored = true
						FxRemote:FireClient(pl, "Grabbed", total)
						FxRemote:FireClient(pl, "Cutscene", shots)
					end
					task.wait(total)
					for pl, hrp in pairs(inside) do
						if hrp.Parent then
							hrp.Anchored = false
							pcall(function()
								hrp:SetNetworkOwner(pl)
							end)
						end
					end
				end
				local emerged = model:GetAttribute("EmergeAt")
				local out = emerged and workspace:GetServerTimeNow() - emerged > Proto.Total
				-- once it's out: a stand-in for it among the enemies, to lock onto and to hit (its Humanoid holds its health),
				-- kept on its chest - where it stands, or wherever it is in a leap
				if out and not proxy then
					proxy = Instance.new("Model")
					proxy.Name = Proto.Name
					proxy:SetAttribute("Boss", true)
					proxy:SetAttribute("Radius", 7) -- (it's broad: blows land on its bulk)
					proxy:SetAttribute("NoPush", true) -- (its Hit block is what you bump into: walk right up to its forelegs)
					local root = Instance.new("Part")
					root.Name = "HumanoidRootPart"
					root.Size = TARGET_SIZE
					root.Anchored, root.CanCollide, root.CanTouch, root.Transparency = true, false, false, 1 -- (CanQuery left on: some blows find their mark by raycast)
					root.CFrame = CFrame.new((model:GetAttribute("LeapTo") or model:GetAttribute("Base").Position) + TARGET_OFF)
					root.Parent = proxy
					local hum = Instance.new("Humanoid")
					hum.MaxHealth, hum.Health = Proto.HP, Proto.HP
					hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
					hum.Parent = proxy
					proxy.PrimaryPart = root
					proxy.Parent = Core.EnemiesFolder
					local follow = game:GetService("RunService").Heartbeat:Connect(function()
						local leapAt = model:GetAttribute("LeapAt")
						local u = leapAt and workspace:GetServerTimeNow() - leapAt
						if u and u >= 0 and u < Proto.LeapTime then
							root.CFrame = CFrame.new((Proto.leap(u, model:GetAttribute("LeapFrom"), model:GetAttribute("LeapTo"), 0) * CFrame.new(0, 10.8, -6)).Position)
						else
							root.CFrame = CFrame.new((model:GetAttribute("LeapTo") or model:GetAttribute("Base").Position) + TARGET_OFF)
						end
					end)
					-- slain: the bar down, and it gone in a burst of fire and ash
					hum.Died:Connect(function()
						follow:Disconnect()
						malDead = true
						local at = root.Position
						Core.shockwave(at - Vector3.new(0, 9, 0), 14)
						Core.burst(at, Color3.fromRGB(255, 120, 40), 40, 0.6, 30)
						if shown then
							shown = false
							ReplicatedStorage:SetAttribute("BossActive", false)
						end
						felled(at)
						model:Destroy() -- (the loop ends with it; its brother, in the same folder, fights on)
						task.delay(1, function()
							proxy:Destroy()
						end)
					end)
				end
				local alive = proxy and proxy.Parent and proxy.Humanoid.Health > 0
				if alive and not T and proxy.Humanoid.Health <= Proto.HP * 0.6 then -- (60%: its brother comes down)
					T = spawnTrue()
				end
				-- its attacks, every few seconds, at someone on the island: the twisting leap, landing on them, or the helix of fire
				if first and out and alive and now() >= nextLeap then
					local list = {}
					for _, hrp in pairs(inside) do
						table.insert(list, hrp)
					end
					local target = list[math.random(#list)].Position
					local hit = model:FindFirstChild("Hit")
					local from = model:GetAttribute("LeapTo") or model:GetAttribute("Base").Position
					-- the leap only closes a gap: never at someone already near it; far off, it's the likeliest
					local gap = Vector3.new(target.X - from.X, 0, target.Z - from.Z).Magnitude
					-- (once its brother's down with it: it mostly answers distance with fire, but still closes the gap every 3-4 attacks)
					local duo = T and not T.dead and T.model and T.model.Parent ~= nil
					local pick
					if duo then
						sinceLeap += 1
						pick = gap >= Proto.LeapMin and (sinceLeap >= leapEvery and 4 or math.random(2, 3)) or math.random(3)
						if pick == 4 then
							sinceLeap, leapEvery = 0, math.random(3, 4)
						end
					else
						pick = gap >= Proto.LeapMin and (math.random() < 0.5 and 4 or math.random(2, 3)) or math.random(3)
					end
					if pick == 1 then -- the tail slash: wound up, then the whole of it spun round, the tail sweeping a circle
						local d = target - from
						local yaw0 = math.atan2(-d.X, -d.Z)
						local t0 = workspace:GetServerTimeNow()
						model:SetAttribute("SwipeYaw", yaw0)
						model:SetAttribute("SwipeAt", t0)
						playSound(hit, SOUNDS.Groan, 2, 0.5)
						task.delay(Proto.SwipeWind, function()
							playSound(hit, SOUNDS.WatchdogBlast, 3, 1)
						end)
						nextLeap = now() + Proto.SwipeTime + 2 + math.random() * 1.6
						task.spawn(function() -- struck as the tail passes over you (a beat behind the chest: it drags), once each
							local struck, prev = {}, nil
							while model.Parent do
								local u = workspace:GetServerTimeNow() - t0
								if u > Proto.SwipeTime then
									break
								end
								local tail = Proto.swipeYaw(yaw0, u - 0.08) + math.pi -- (its tail points behind it)
								if prev and tail > prev and u > Proto.SwipeWind then
									for _, pl in ipairs(Players:GetPlayers()) do
										local char, _, phrp = aliveChar(pl)
										local rel = char and phrp.Position - from
										local r = rel and Vector3.new(rel.X, 0, rel.Z).Magnitude
										if r and not struck[pl] and r > 4 and r < Proto.SwipeReach and math.abs(rel.Y) < 8 then
											local ang = math.atan2(-rel.X, -rel.Z)
											if (ang - prev) % (2 * math.pi) <= tail - prev then
												struck[pl] = true
												Core.damagePlayer(pl, 32, phrp.Position - rel.Unit, "Knockdown")
											end
										end
									end
								end
								prev = tail
								task.wait(0.03)
							end
						end)
						continue
					elseif pick == 2 then
						local d = target - from
						local aim = math.atan2(-d.X, -d.Z)
						local side = math.random() < 0.5 and -1 or 1 -- (which way its head drags across as it spews)
						model:SetAttribute("BreathYaw0", aim - side * 0.2 + math.random() * 1e-3) -- (the jitter: each flood's own scatter)
						model:SetAttribute("BreathYaw1", aim + side * 0.2)
						local t0 = workspace:GetServerTimeNow()
						model:SetAttribute("BreathAt", t0)
						playSound(hit, SOUNDS.Groan, 2, 0.45)
						task.delay(Proto.BreathWind, function()
							playSound(hit, SOUNDS.FireCast, 3, 0.45)
						end)
						nextLeap = now() + Proto.BreathWind + Proto.BreathTime + 2.4 + math.random() * 1.6
						task.spawn(function() -- the front hits hard as it rolls over you; the ground it leaves burns
							local B, burnt = Proto.breathOf(model), {}
							while model.Parent do
								local u = workspace:GetServerTimeNow() - t0
								if u > Proto.BreathEnd then
									break
								end
								for _, pl in ipairs(Players:GetPlayers()) do
									local char, _, phrp = aliveChar(pl)
									local what = char and Proto.fireAt(B, phrp.Position, u)
									if what == "front" and (not burnt[pl] or now() - burnt[pl] > 0.8) then
										burnt[pl] = now()
										Core.damagePlayer(pl, 26, B.origin, "Large")
									elseif what == "burn" and (not burnt[pl] or now() - burnt[pl] > 0.5) then
										burnt[pl] = now()
										Core.damagePlayer(pl, 7, phrp.Position, "Small")
									end
								end
								task.wait(0.05)
							end
						end)
						continue
					elseif pick == 3 then -- the rearing slam: up on its tail, a beat, then flung down - the slam, and a wedge of rubble ahead
						local d = target - from
						model:SetAttribute("SlamYaw", math.atan2(-d.X, -d.Z) + math.random() * 1e-4) -- (the jitter: each wedge its own)
						local t0 = workspace:GetServerTimeNow()
						model:SetAttribute("SlamAt", t0)
						playSound(hit, SOUNDS.Groan, 2, 0.5)
						nextLeap = now() + Proto.SlamTime + 2 + math.random() * 1.6
						task.spawn(function()
							local S, struck, landed = Proto.slamOf(model), {}, false
							while model.Parent do
								local u = workspace:GetServerTimeNow() - t0
								if u > Proto.SlamEnd then
									break
								end
								if not landed and u >= Proto.SlamLand then
									landed = true
									Core.shockwave(S.at + S.fwd * Proto.SlamAhead, 12)
									playSound(hit, SOUNDS.WatchdogSmash, 2.5, 1)
								end
								for _, pl in ipairs(Players:GetPlayers()) do
									local char, _, phrp = aliveChar(pl)
									local what = char and Proto.slamHit(S, phrp.Position, u)
									if what and not struck[pl] then -- (once each: the slam or the rubble, whichever finds you first)
										struck[pl] = true
										if what == "slam" then
											Core.damagePlayer(pl, 36, S.at, "Knockdown")
										else
											Core.damagePlayer(pl, 24, phrp.Position - S.fwd, "Large")
										end
									end
								end
								task.wait(0.03)
							end
						end)
						continue
					end
					local to = Vector3.new(math.clamp(target.X, Ar.MinX + 10, Ar.MaxX - 10), Ar.Centre.Y, math.clamp(target.Z, Ar.MinZ + 10, Ar.MaxZ - 10))
					-- (as far as you, but never a short hop nor further than it can spring; still on the island)
					local dist = (to - from).Magnitude
					local dir = dist > 0.1 and (to - from).Unit or Vector3.new(0, 0, -1)
					to = from + dir * math.clamp(dist, Proto.LeapMin, Proto.LeapMax)
					if duo then -- (never landing on top of its brother: pushed out to 26 from him)
						local tp = Proto.trueAt(T.model, workspace:GetServerTimeNow())
						local off = tp and Vector3.new(to.X - tp.X, 0, to.Z - tp.Z)
						if off and off.Magnitude < 26 then
							to += (off.Magnitude > 0.1 and off.Unit or -dir) * (26 - off.Magnitude)
						end
					end
					to = Vector3.new(math.clamp(to.X, Ar.MinX + 10, Ar.MaxX - 10), to.Y, math.clamp(to.Z, Ar.MinZ + 10, Ar.MaxZ - 10))
					model:SetAttribute("LeapFrom", from)
					model:SetAttribute("LeapTo", to)
					model:SetAttribute("LeapAt", workspace:GetServerTimeNow())
					local hit = model:FindFirstChild("Hit")
					playSound(hit, SOUNDS.Groan, 2, 0.55)
					nextLeap = now() + Proto.LeapTime + 2 + math.random() * 1.6
					task.delay(Proto.LeapLand, function()
						Core.shockwave(to, 12)
						playSound(hit, SOUNDS.WatchdogSmash, 2.5, 1)
						for _, pl in ipairs(Core.playersInRadius(to, 12, 10)) do
							Core.damagePlayer(pl, 30, to, "Knockdown")
						end
						if hit then -- (its still block, where it now stands)
							hit.CFrame += to - from
						end
					end)
				end
				-- everyone who fought it dead and nobody left on the island: it's whole again, back on its spot (its entrance
				-- isn't played again: it's already out)
				for pl, hrp in pairs(inside) do
					fighters[pl] = hrp.Parent
				end
				if alive and not first then
					local wiped = false
					for pl, char in pairs(fighters) do
						if pl.Parent and aliveChar(pl) ~= char then
							wiped = true
						end
					end
					if wiped then
						fighters = {}
						if T then
							T.destroy()
							T = nil
						end
						proxy.Humanoid.Health = Proto.HP
						local hit, from = model:FindFirstChild("Hit"), model:GetAttribute("LeapTo")
						if hit and from then
							hit.CFrame += model:GetAttribute("Base").Position - from
						end
						for _, a in ipairs({ "LeapTo", "LeapFrom", "LeapAt", "SwipeAt", "BreathAt", "SlamAt" }) do
							model:SetAttribute(a, nil)
						end
					end
				end
				-- its bar: only ever switched on and off by this (so another boss's are left alone)
				local want = alive and first ~= nil and model:GetAttribute("EmergeAt") ~= nil
				if want ~= shown then
					shown = want
					if want then
						ReplicatedStorage:SetAttribute("BossName", Proto.Name)
						ReplicatedStorage:SetAttribute("BossMaxHP", Proto.HP)
					end
					ReplicatedStorage:SetAttribute("BossActive", want)
				end
				if shown then
					ReplicatedStorage:SetAttribute("BossHP", alive and proxy.Humanoid.Health or Proto.HP)
				end
			end
		end)
	end)
	if not ok then
		warn("PyralisProto: " .. tostring(err))
	end
end

-- THE GREAT LIFT (Map.Bulwark.Lift: PyralisBulwark), from the Watchdog's Run up to Pyralis Bulwark. Its lever sends it to
-- the other end; the levers at each end call it there. Whoever's standing on its deck rides it, held still on it
do
	local Lf = Map.Bulwark and Map.Bulwark.Lift
	if Lf then
		local moving = false
		local function go(to)
			if moving or Lf.At == to then
				return
			end
			moving = true
			local from, dest = Lf[Lf.At], Lf[to]
			local riders = {}
			for _, pl in ipairs(Players:GetPlayers()) do
				local char, _, hrp = aliveChar(pl)
				local rel = char and from:PointToObjectSpace(hrp.Position)
				if rel and math.abs(rel.X) < 11 and math.abs(rel.Z) < 11 and rel.Y > 0 and rel.Y < 8 then
					hrp.AssemblyLinearVelocity = Vector3.zero
					hrp.Anchored = true
					table.insert(riders, { pl, hrp, from:ToObjectSpace(hrp.CFrame) })
				end
			end
			local dur = (dest.Position - from.Position).Magnitude / 14 -- (14 studs a second: slow, as such lifts are)
			for _, rd in ipairs(riders) do
				FxRemote:FireClient(rd[1], "Grabbed", dur + 0.6)
				local st = states[rd[1]]
				if st then
					Core.setAction(st, now(), dur + 0.6, dur + 0.6, dur + 0.6)
				end
			end
			playSound(Lf.Deck, SOUNDS.Impact, 2.5, 0.4)
			task.wait(0.6)
			local t0 = os.clock()
			while true do
				local a = math.clamp((os.clock() - t0) / dur, 0, 1)
				local cf = from:Lerp(dest, a * a * (3 - 2 * a))
				for _, e in ipairs(Lf.Parts) do
					e[1].CFrame = cf * e[2]
				end
				for _, rd in ipairs(riders) do
					if rd[2].Parent then
						rd[2].CFrame = cf * rd[3]
					end
				end
				if a >= 1 then
					break
				end
				RunService.Heartbeat:Wait()
			end
			Lf.At = to
			playSound(Lf.Deck, SOUNDS.Impact, 2.5, 0.5)
			for _, rd in ipairs(riders) do
				if rd[2].Parent then
					rd[2].Anchored = false
					pcall(function()
						rd[2]:SetNetworkOwner(rd[1])
					end)
				end
			end
			moving = false
		end
		Lf.Prompt.Triggered:Connect(function()
			task.spawn(go, Lf.At == "Bottom" and "Top" or "Bottom")
		end)
		Lf.CallBottom.Triggered:Connect(function()
			task.spawn(go, "Bottom")
		end)
		Lf.CallTop.Triggered:Connect(function()
			task.spawn(go, "Top")
		end)
	end
end

-- falls that kill: the chasm beyond the township, the Maw of Pyralis's lava
local DEADLY = {}
if Map.Chasm then
	table.insert(DEADLY, Map.Chasm)
end
for _, m in ipairs(Map.Underfire and Map.Underfire.Moats or {}) do
	table.insert(DEADLY, m)
end

local function underfireDescent(player, st, char, hrp, quick)
	local D = Map.Underfire
	st.underfireAt = now()
	local V, look = Vector3.new, CFrame.lookAt
	local function alive()
		return hrp.Parent and player.Character == char
	end
	if quick then
		FxRemote:FireClient(player, "Flash", Color3.new(0, 0, 0), 1.2, 0.4)
		task.delay(0.2, function()
			if alive() then
				char:PivotTo(D.Landing)
				hrp.AssemblyLinearVelocity = V()
			end
		end)
		return
	end
	st.underfireSeen = true
	local P0, L = hrp.Position, D.Landing.Position
	local y0 = P0.Y
	-- {time, position}: out to the lip, a pause, a step back, a pause, the run-up; the leap is at JUMP
	local JUMP, LAND = 4.1, 5.7
	local keys = { { 0, P0 }, { 1.4, V(90.3, y0, -32) }, { 2.6, V(90.3, y0, -32) }, { 3.1, V(89.5, y0, -32) }, { 3.7, V(89.5, y0, -32) }, { JUMP, V(91.3, y0, -32) } }
	local shots = {
		{ look(V(77, 5.5, -32), V(92, 3, -32)), look(V(81, 5, -32), V(94, 2, -32)), 2.6 }, -- behind him down the hallway (4 wide: dead centre), the glow ahead
		{ look(V(100, -8, -38), V(91, 3, -32)), look(V(98, -5, -36), V(91, 4, -32)), 1.5 }, -- from the pit, up at him
		{ look(V(96, 6, -44), V(98, 0, -32)), look(V(112, -6, -44), V(108, -22, -32)), 1.6 }, -- the leap
		{ look(V(146, -108, 8), V(128, -88, -5)), look(V(150, -105, 6), V(130, -94, -5)), 3.0 }, -- the broken ceiling
		{ look(V(136.5, -103.5, -1.5), V(158, -99, -5)), look(V(138.5, -103.8, -3), V(172, -98, -5)), 3.4 }, -- past his shoulder
		{ look(V(166, -101, 12), V(140, -106, -5)), look(V(166, -101, -20), V(140, -106, -5)), 3.4 }, -- round the room, back to him
	}
	local total = 0
	for _, shot in ipairs(shots) do
		total += shot[3]
	end
	st.underfireAt = now() + total -- (falling past the pit's mouth in it doesn't start the quick drop)
	Core.setAction(st, now(), total, total, total)
	st.iStart, st.iEnd = now(), now() + total + 0.5 -- (nothing hurts you through it)
	st.healing = false
	Core.cancelSwing(st)
	hrp.Anchored = true
	FxRemote:FireClient(player, "Grabbed", total)
	FxRemote:FireClient(player, "Cutscene", shots)
	-- his body: eyes on the pit, a flinch back, gathering himself, the tucked leap, a crouched landing, then up
	local function bp(name, blend)
		char:SetAttribute("BP", name)
		char:SetAttribute("BPT", blend)
		char:SetAttribute("BPN", (char:GetAttribute("BPN") or 0) + 1)
	end
	for _, e in ipairs({ { 1.4, "Read", 0.4 }, { 2.6, "Flinch", 0.2 }, { 3.1, "Read", 0.3 }, { 3.7, "Crouch", 0.35 }, { JUMP, "Air", 0.12 }, { LAND, "Kneel", 0.05 }, { LAND + 2.2, "Idle", 0.9 } }) do
		task.delay(e[1], function()
			if alive() then
				bp(e[2], e[3])
			end
		end)
	end
	task.delay(LAND - 0.35, function() -- (he drops into the dark)
		FxRemote:FireClient(player, "Flash", Color3.new(0, 0, 0), 1.4, 0.8)
	end)
	task.spawn(function()
		local t0, prev, last = os.clock(), P0, os.clock()
		while alive() do
			local t = os.clock() - t0
			if t >= total then
				break
			end
			local p, yaw = nil, 0 -- (yaw 0 faces +x)
			if t < JUMP then
				for i = 2, #keys do
					if t <= keys[i][1] then
						local a, b = keys[i - 1], keys[i]
						local k = math.clamp((t - a[1]) / (b[1] - a[1]), 0, 1)
						p = a[2]:Lerp(b[2], k * k * (3 - 2 * k))
						break
					end
				end
			elseif t < LAND then
				local d = t - JUMP -- (a ballistic leap: 22 up, gravity 60, 1.3 s to the pit's lip)
				p = V(91.3 + math.min(12.85 * d, D.Pit.X - 91.3), y0 + 22 * d - 30 * d * d, -32)
			else
				p = L
				local k = math.clamp((total - t) / 2, 0, 1) -- (looks about, then settles facing the hall)
				yaw = 0.55 * math.sin((t - LAND) * 1.1) * k
			end
			char:PivotTo(CFrame.lookAt(p, p + V(math.cos(yaw), 0, math.sin(yaw))))
			local now2 = os.clock()
			hrp.AssemblyLinearVelocity = t < LAND and (p - prev) / math.max(now2 - last, 1 / 60) or V() -- (the walk cycle reads it)
			prev, last = p, now2
			RunService.Heartbeat:Wait()
		end
		if alive() then
			bp("Idle", 0.3)
			char:PivotTo(D.Landing)
			hrp.Anchored = false
			pcall(function()
				hrp:SetNetworkOwner(player)
			end)
		end
	end)
end

RunService.Heartbeat:Connect(function(dt)
	local t = now()
	for player, st in pairs(states) do
		local char, _, hrp = aliveChar(player)
		if char then
			local moving = flat(hrp.AssemblyLinearVelocity).Magnitude > 3
			if st.sprinting and moving and t >= st.busyUntil then
				st.stamina = math.max(0, st.stamina - P.SprintDrain * dt)
				st.lastSpend = t
			elseif t - st.lastSpend >= P.StaminaRegenDelay and t >= st.busyUntil then
				st.stamina = math.min(P.MaxStamina, st.stamina + P.StaminaRegen * dt)
			end
			syncStamina(player, st)

			-- the area name shows every time you walk into a different area
			-- (a short per-area cooldown stops it flickering if you hover on a border)
			-- fell off the crossing beyond the township: the chasm takes you
			-- (and the sunk lava of the Maw of Pyralis, beneath the Fallen Cellblock: DEADLY)
			local pos = hrp.Position
			for _, ch in ipairs(DEADLY) do
				if pos.Y < ch.MaxY and pos.X > ch.MinX and pos.X < ch.MaxX and pos.Z > ch.MinZ and pos.Z < ch.MaxZ then
					local _, hum = aliveChar(player)
					if hum then
						hum.Health = 0
					end
				end
			end
			-- (and the fall off Pyralis Bulwark's spires, bridges and halls: below 70 over any of it you're dead - not in
			-- the lift's shaft, though, unless you're falling down it rather than riding)
			local Bw = Map.Bulwark
			if Bw and pos.Y < Bw.FallY and pos.Y > -40 then
				local sh = Bw.Shaft
				local inShaft = pos.X > sh[1] and pos.X < sh[3] and pos.Z > sh[2] and pos.Z < sh[4]
				if not inShaft or (not hrp.Anchored and hrp.AssemblyLinearVelocity.Y < -60) then
					for _, q in ipairs(Bw.Falls) do
						if pos.X > q[1] and pos.X < q[3] and pos.Z > q[2] and pos.Z < q[4] then
							local _, hum = aliveChar(player)
							if hum then
								hum.Health = 0
							end
							break
						end
					end
				end
			end
			local zone = zoneAt(hrp.Position)
			local D = Map.Underfire
			if D and t - (st.underfireAt or -100) > 4 then
				local g = D.Gate
				if not st.underfireSeen and pos.X >= g.MinX and pos.X <= g.MaxX and pos.Z >= g.MinZ and pos.Z <= g.MaxZ and pos.Y > -5 then
					task.spawn(underfireDescent, player, st, char, hrp)
				elseif pos.Y < D.Pit.Y + 1 and (pos.X - D.Pit.X) ^ 2 + (pos.Z - D.Pit.Z) ^ 2 < 25 then
					task.spawn(underfireDescent, player, st, char, hrp, true) -- (into the pit's mouth, any time after)
				end
			end
			local beneath = st.zone == "Maw of Pyralis"
			if player:GetAttribute("Beneath") ~= beneath then
				player:SetAttribute("Beneath", beneath) -- (the client darkens the air)
			end
			local smoulder = st.zone == "Pyralis Bulwark"
			if player:GetAttribute("Smoulder") ~= smoulder then
				player:SetAttribute("Smoulder", smoulder) -- (the client dims it a little, smoky and red)
			end
			if zone and zone ~= st.zone then
				st.zone = zone
				if t - (st.seenZones[zone] or -100) > 8 then
					FxRemote:FireClient(player, "Area", zone)
				end
				st.seenZones[zone] = t
			elseif not zone then
				st.zone = nil -- outside every named area (fog passage, arena): re-entering shows the name again
			end

			-- the township fog (Config.TownFog): poison builds while you breathe it and ebbs
			-- outside; full, and you're poisoned. The client reads InFog (the slow, the
			-- thick air) and PoisonBuild (0..1, the bar under your stamina).
			local fog = Config.TownFog
			local inFog = st.zone == fog.Zone
			if player:GetAttribute("InFog") ~= inFog then
				player:SetAttribute("InFog", inFog)
			end
			st.poisonBuild = math.clamp((st.poisonBuild or 0) + (inFog and fog.Buildup or -fog.Ebb) * dt, 0, 100)
			if st.poisonBuild >= 100 then
				st.poisonBuild = 0
				Core.poisonPlayer(player, fog.Poison)
			end
			local shown = math.floor(st.poisonBuild) / 100 -- whole steps, to spare the network
			if player:GetAttribute("PoisonBuild") ~= shown then
				player:SetAttribute("PoisonBuild", shown)
			end
		end
	end
end)

---------------------------------------------------------------------------
-- go
---------------------------------------------------------------------------
Enemies.respawn()
local bossOk, bossErr = pcall(Warden.spawn)
if not bossOk then
	warn("[DGUS] failed to spawn boss: " .. tostring(bossErr))
end
local championOk, championErr = pcall(Champion.spawn) -- (the Crowned Colosseum's, Characters/Champion.lua)
if not championOk then
	warn("[DGUS] failed to spawn the Champion: " .. tostring(championErr))
end
local castellanOk, castellanErr = pcall(Castellan.spawn)
if not castellanOk then
	warn("[DGUS] failed to spawn the Castellan: " .. tostring(castellanErr))
end
local consulOk, consulErr = pcall(Roster.byKind.Consul.spawn) -- (the Hollow Mansion's attic, Characters/Consul.lua)
if not consulOk then
	warn("[DGUS] failed to spawn the Consul: " .. tostring(consulErr))
end
local usherOk, usherErr = pcall(Oculast.spawn)
if not usherOk then
	warn("[DGUS] failed to spawn Oculast: " .. tostring(usherErr))
end
print(string.format("[DGUS] ready: %d enemies, boss %s", Enemies.count(), Warden.model() and "spawned" or "MISSING"))
