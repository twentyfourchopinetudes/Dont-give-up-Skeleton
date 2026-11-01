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
				FxRemote:FireClient(player, "Message", def.Name .. " is too heavy for you. It needs " .. def.Strength .. " Strength.")
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
	for _, key in ipairs({ "DarkCloak", "DarkHood", "CaelenArmor" }) do
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
-- one item, a player attribute (the Bleak Manor key, the Dark Book, the Foul Dagger)
for _, ch in ipairs(Map.MushroomChests) do
	ch.Prompt.Triggered:Connect(function(player)
		if not ch.Prompt.Enabled then
			return
		end
		ch.Prompt.Enabled = false
		local swung = ch.Hinge * CFrame.Angles(math.rad(110), 0, 0) * ch.Hinge:Inverse() * ch.Lid.CFrame
		TweenService:Create(ch.Lid, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = swung }):Play()
		playSound(ch.Lid, SOUNDS.Unsheath, 0.6, 0.6)
		player:SetAttribute(ch.Item.Attr, true)
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
			local ch = Map.Chasm
			local pos = hrp.Position
			if ch and pos.Y < ch.MaxY and pos.X > ch.MinX and pos.X < ch.MaxX and pos.Z > ch.MinZ and pos.Z < ch.MaxZ then
				local _, hum = aliveChar(player)
				if hum then
					hum.Health = 0
				end
			end
			local zone = zoneAt(hrp.Position)
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
