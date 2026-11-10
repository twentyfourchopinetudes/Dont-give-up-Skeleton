--!nonstrict
-- THE CARRIER, server half: what answers the prison's bell. Every time someone rings it,
-- the thing (its look and its path: ReplicatedStorage/Carrier, drawn by every client) hauls
-- itself up the outside of the battlements and comes for them. They back away from it,
-- arm up, but it takes them anyway, and flies them off over the township to drop them on
-- the ground beyond its north edge (Map.NewArea). (A bonfire there lets them wake there.)
-- Here: the plan, and the player - held, resisting, carried along its path, let go.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = require(ReplicatedStorage:WaitForChild("Carrier"))

local M = {}
local Core, Map

-- the first trip only: halfway over, the camera leaves you hanging there and goes looking at where the land leads -
-- the Colosseum, Pyralis Bulwark's keep over its lava, the pit in the Decayed Palace's throne hall, and what waits
-- under it. Each shot is { from, to, seconds } (SoulsClient's "Cutscene"); any whose place isn't built is left out.
local function vistaShots()
	local V, look = Vector3.new, CFrame.lookAt
	local shots = {}
	local C = Map.Champion and Map.Champion.Centre
	if C then -- from over the road in from the east: the Colosseum, sunk in its hills
		table.insert(shots, { look(C + V(110, 40, 0), C + V(0, 18, 0)), look(C + V(95, 34, 12), C + V(0, 16, 0)), 3.2 })
	end
	if Map.Bulwark then -- high over the lift's tower: the spires out of the lava, the keep in the middle
		table.insert(shots, { look(V(370, 135, 340), V(482, 118, 222)), look(V(392, 128, 318), V(482, 112, 222)), 3.6 })
	end
	local O = Map.OssariaPit
	if O then -- the pit's lip, down into the black (the descent's own first framing), then her, in the court under it
		local c, F = V(O.Landing.Position.X, 0, O.Landing.Position.Z), O.Landing.Position.Y
		table.insert(shots, { look(c + V(0, O.Top + 10, -16), c + V(0, O.Top - 10, 2)), look(c + V(0, O.Top + 8, -12), c + V(0, O.Top - 24, 2)), 3 })
		if O.Spot then
			table.insert(shots, { look(c + V(10, F + 12, 6), O.Spot + V(0, 5, 0)), look(c + V(4, F + 9, 3), O.Spot + V(0, 6, 0)), 3.4 })
		end
	end
	return shots
end

local busy = false
function M.take(player)
	local char, hum, hrp = Core.aliveChar(player)
	local st = Core.states[player]
	if busy or not (char and st) then -- (every ring: the only way back out of the prison once you have dropped into it)
		return
	end
	busy = true
	local function pose(name, blend)
		char:SetAttribute("BP", name)
		char:SetAttribute("BPT", blend)
		char:SetAttribute("BPN", (char:GetAttribute("BPN") or 0) + 1)
	end
	local function hold(seconds)
		Core.setAction(st, Core.now(), seconds, seconds, seconds)
		Core.FxRemote:FireClient(player, "Grabbed", seconds)
	end
	local function alive()
		return hrp.Parent and hum.Health > 0 and player.Parent ~= nil
	end
	local ok, err = pcall(function()
		task.wait(2.2) -- (the bell's first tolls)
		if not alive() then
			return
		end
		local ktop = Map.CastellanArena.Center.Y
		local wallX = 196 -- the north arm's outer east face
		local z = math.clamp(hrp.Position.Z - 8, 228, 276)
		local start = hrp.Position
		local away = Vector3.new(start.X - (wallX - 4), 0, start.Z - z)
		away = away.Magnitude > 0.5 and away.Unit or Vector3.new(-1, 0, 0)
		local back = 4
		local plan = {
			wallX = wallX, z = z, ktop = ktop, start = start, back = away,
			held = start + away * back, landing = Map.NewArea.Landing.Position,
			seed = math.random(1, 1e6),
		}
		local tCrawl = Shared.CLIMB + Shared.CREST
		local tGrab = tCrawl + Shared.crawlTime(plan)
		local tFly = tGrab + Shared.GRAB
		local tDrop = tFly + Shared.FLY
		local vista = not Core.Save.done("CarrierVista") and vistaShots() or {}
		if #vista > 0 then
			plan.pauseAt, plan.pauseFor = tFly + Shared.FLY / 2, 0
			for _, s in ipairs(vista) do
				plan.pauseFor += s[3]
			end
		end
		hold(tDrop + 1 + (plan.pauseFor or 0))
		hrp.Anchored = true
		Core.FxRemote:FireAllClients("Carrier", plan)
		local t0 = os.clock()
		local lastPose, poseN = 0, 0
		local RESIST = { "Deflect", "Flinch", "Stagger", "Deflect", "Recover" }
		local STRUGGLE = { "Air", "Stagger", "Air", "Flinch" }
		while true do
			RunService.Heartbeat:Wait()
			if not alive() then
				error("gone", 0)
			end
			local t = Shared.pathTime(plan, os.clock() - t0)
			if plan.pauseAt and t >= plan.pauseAt and not Core.Save.done("CarrierVista") then
				Core.Save.mark("CarrierVista")
				Core.FxRemote:FireClient(player, "Cutscene", vista)
			end
			local cf = Shared.at(plan, math.min(t, tDrop))
			if t < tGrab then
				-- it comes: you face it and give ground, stumbling, an arm up against it
				local k = math.clamp((t - Shared.CLIMB) / (tGrab - Shared.CLIMB), 0, 1)
				local pos = start + away * back * (1 - (1 - k) ^ 2)
				local look = Vector3.new(cf.Position.X, pos.Y, cf.Position.Z)
				hrp.CFrame = (look - pos).Magnitude > 0.1 and CFrame.lookAt(pos, look) or CFrame.new(pos) * hrp.CFrame.Rotation
				if t > Shared.CLIMB * 0.5 and t - lastPose > 0.55 then
					lastPose, poseN = t, poseN + 1
					pose(RESIST[(poseN - 1) % #RESIST + 1], 0.2)
				end
			elseif t < tFly then
				-- its arms close on you: you thrash
				if t - lastPose > 0.25 then
					lastPose, poseN = t, poseN + 1
					pose(poseN % 2 == 0 and "Stagger" or "Flinch", 0.12)
					if poseN % 3 == 0 then
						Core.playSound(hrp, Core.SOUNDS.Impact, 0.5, 0.6)
					end
				end
			elseif t < tDrop then
				-- carried, kicking
				local wr = CFrame.Angles(0.5 + math.sin(t * 11) * 0.25, math.sin(t * 7) * 0.3, math.sin(t * 13) * 0.25)
				hrp.CFrame = cf * Shared.HANG * wr
				if t - lastPose > 0.45 then
					lastPose, poseN = t, poseN + 1
					pose(STRUGGLE[(poseN - 1) % #STRUGGLE + 1], 0.2)
				end
			else
				break
			end
		end
		-- let go
		hrp.Anchored = false
		hrp.AssemblyLinearVelocity = Vector3.new(0, -10, 0)
		pcall(function()
			hrp:SetNetworkOwner(player)
		end)
		pose("Idle", 0.4)
		player:SetAttribute("Taken", true)
		hold(0)
	end)
	if not ok then
		-- (they died or left mid-way, or something broke: never leave anyone pinned)
		if hrp.Parent then
			hrp.Anchored = false
			pcall(function()
				hrp:SetNetworkOwner(player)
			end)
		end
		if player.Parent then
			hold(0)
		end
		if err ~= "gone" and Core.Config.Debug then
			warn("[Carrier] " .. tostring(err))
		end
	end
	busy = false
end

function M.init(core)
	Core, Map = core, core.Map
end

return M
