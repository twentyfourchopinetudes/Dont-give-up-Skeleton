--!nonstrict
-- THE CARRIER, server half: what answers the prison's bell. The first time someone rings it,
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

local busy = false
function M.take(player)
	local char, hum, hrp = Core.aliveChar(player)
	local st = Core.states[player]
	if busy or not (char and st) or player:GetAttribute("Taken") then
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
		hold(tDrop + 1)
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
			local t = os.clock() - t0
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
