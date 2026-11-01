--!nonstrict
-- Enemies: the shared brain for regular enemies (Hollow, Skeleton, Jailer...).
-- Seeing you, chasing (straight or by pathfinding), giving up past the leash,
-- walking home, healing, dying and respawning all live here. What a KIND of
-- enemy is (stats, looks, weapon, attacks) lives in its own character file:
--   ReplicatedStorage/Characters/<Kind>.lua  ->  M.Def (stats) and M.attack(e, target)
-- To add a new kind: write its character file and add spawns in MapBuilder.
local Enemies = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local Map, EnemiesFolder, Roster
local now, flat, playSound, SOUNDS, burst, pose, setTrail, faceTowards, findShoulder, makeRig, makeCorpse, ragdoll, aliveChar

local enemyList = {}
local enemyByModel = {}
local losParams = RaycastParams.new()
losParams.FilterType = Enum.RaycastFilterType.Exclude
local navParams = RaycastParams.new()
navParams.FilterType = Enum.RaycastFilterType.Exclude

local function defOf(kind)
	local c = Roster.byKind[kind]
	return c and c.Def, c
end

local function canSee(fromPos, char)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end
	local res = workspace:Raycast(fromPos, hrp.Position - fromPos, losParams)
	return res == nil or res.Instance:IsDescendantOf(char)
end

local function findTarget(e)
	local best, bestD
	for _, pl in ipairs(Players:GetPlayers()) do
		local char, _, hrp = aliveChar(pl)
		if char then
			local d = (hrp.Position - e.root.Position).Magnitude
			local range = e.aggro and e.def.Aggro * 1.6 or e.def.Aggro
			if d <= range and (bestD == nil or d < bestD) then
				if e.aggro or canSee(e.root.Position + Vector3.new(0, 1.5, 0), char) then
					best, bestD = char, d
				end
			end
		end
	end
	return best, bestD
end
local function navigate(e, goal, targetChar)
	local root, hum = e.root, e.hum
	local from = root.Position
	if math.abs(goal.Y - from.Y) < 2.5 then
		navParams.FilterDescendantsInstances = targetChar and { EnemiesFolder, Map.Bars, targetChar } or { EnemiesFolder, Map.Bars }
		if not workspace:Raycast(from, goal - from, navParams) then
			e.path = nil
			hum:MoveTo(goal)
			return
		end
	end
	local t = now()
	if not e.path or t > (e.pathExpire or 0) or (e.pathGoal - goal).Magnitude > 8 then
		e.pathExpire = t + 1
		e.pathGoal = goal
		if not e.pathObj then
			e.pathObj = PathfindingService:CreatePath({
				AgentRadius = 1.6 * e.def.Scale,
				AgentHeight = 5 * e.def.Scale,
				AgentCanJump = false,
				WaypointSpacing = 4,
			})
		end
		local ok = pcall(function()
			e.pathObj:ComputeAsync(from, goal)
		end)
		if ok and e.pathObj.Status == Enum.PathStatus.Success then
			e.path = e.pathObj:GetWaypoints()
			e.wp = 2
		else
			e.path = nil
			hum:MoveTo(goal) -- best effort
			return
		end
	end
	local wps = e.path
	from = root.Position
	while e.wp <= #wps and flat(wps[e.wp].Position - from).Magnitude < 2.5 do
		e.wp += 1
	end
	hum:MoveTo(e.wp <= #wps and wps[e.wp].Position or goal)
end

local function enemyAI(e)
	local def = e.def
	while e.alive and e.model.Parent do
		task.wait(0.1)
		if not e.alive then
			break
		end
		if now() < e.staggerUntil then
			continue
		end
		local hum, root = e.hum, e.root
		local homeDist = flat(root.Position - e.home.Position).Magnitude
		local target = findTarget(e)
		if target and homeDist > def.Leash then
			target = nil
			e.returning = true
		end
		if e.returning and homeDist < 4 then
			e.returning = false
		end
		if target and not e.returning then
			e.aggro = true
			local tRoot = target:FindFirstChild("HumanoidRootPart")
			if tRoot then
				local d = flat(tRoot.Position - root.Position).Magnitude
				-- NoticeRange: hands it to the character file from further out until it has
				-- noticed you once (the dog turns, sees you, and leaps from there)
				local engage = (def.NoticeRange and not e.noticed) and def.NoticeRange or def.Engage or def.Range - 0.5
				if d <= engage and not (e.char.crowded and e.char.crowded(e)) then
					local ok, err = pcall(e.char.attack, e, target)
					if not ok then
						warn("[DGUS] enemy attack error: " .. tostring(err))
						e.attacking = false
						hum.AutoRotate = true
					end
				else
					navigate(e, e.char.steer and e.char.steer(e, tRoot.Position) or tRoot.Position, target) -- (the Tillers keep apart)
				end
			end
		else
			e.aggro = false
			if homeDist > 2 then
				navigate(e, e.home.Position, nil)
			else
				hum:MoveTo(root.Position)
				faceTowards(root, root.Position + e.home.LookVector)
				if hum.Health < hum.MaxHealth then
					hum.Health = math.min(hum.MaxHealth, hum.Health + hum.MaxHealth * 0.02)
				end
			end
		end
	end
end
local function onEnemyDied(e)
	if not e.alive then
		return
	end
	e.alive = false
	if e.char and e.char.onDied then -- (the Tillers: both down opens the Citadel's gate)
		local ok, err = pcall(e.char.onDied, e)
		if not ok then
			warn("[DGUS] onDied error: " .. tostring(err))
		end
	end
	makeCorpse(e.model)
	ragdoll(e.model) -- limp, down to the floor
	local root = e.root
	if root and root.Parent then
		playSound(root, SOUNDS.Groan, 0.4, 0.6)
		burst(root.Position, Color3.fromRGB(70, 66, 60), 20, 0.5, 8)
	end
	local model = e.model
	task.delay(3, function()
		if not model.Parent then
			return
		end
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				TweenService:Create(d, TweenInfo.new(1.2), { Transparency = 1 }):Play()
			end
		end
		task.wait(1.3)
		model:Destroy()
	end)
end

local function spawnEnemy(spec)
	local def, char = defOf(spec.Type)
	if not def then
		warn("[DGUS] no character file for enemy kind " .. tostring(spec.Type))
		return nil
	end
	if spec.Elite then -- (the prison roof's: stouter, quicker, bigger and harder-hitting than the kind's own)
		def = table.clone(def)
		def.HP *= 2.2
		def.Speed *= 1.35
		def.Windup *= 0.75
		def.Recover *= 0.8
		def.Damage *= 1.2
		def.Scale *= 1.15
		def.Radius *= 1.15
	end
	local model, hum, weld = makeRig(spec.Type, spec.Type, def.Scale, def.Weapon)
	if not model then
		return nil
	end
	hum.MaxHealth = def.HP
	hum.Health = def.HP
	hum.WalkSpeed = def.Speed
	hum.BreakJointsOnDeath = false -- keep the joints: onEnemyDied turns them into a ragdoll
	model:SetAttribute("Radius", def.Radius)
	model:SetAttribute("Enemy", true)
	local root = model:FindFirstChild("HumanoidRootPart")
	root.CollisionGroup = "EnemyRoot"
	hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	model:PivotTo(spec.CFrame + Vector3.new(0, 3 * def.Scale - 3, 0))
	pcall(function()
		root:SetNetworkOwner(nil)
		hum:ChangeState(Enum.HumanoidStateType.Running) -- start standing (a waiting rig not "Running" sinks)
	end)
	local shoulder = findShoulder(model)
	local e = {
		def = def,
		char = char, -- its character file (attack, onStagger...)
		spec = spec,
		model = model,
		hum = hum,
		root = root,
		weld = weld,
		scale = def.Scale,
		shoulder = shoulder,
		c0 = shoulder and shoulder.C0,
		home = spec.CFrame,
		alive = true,
		aggro = false,
		attacking = false,
		returning = false,
		staggerUntil = 0,
	}
	enemyByModel[model] = e
	hum.Died:Connect(function()
		onEnemyDied(e)
	end)
	task.spawn(enemyAI, e)
	return e
end

local function respawnEnemies()
	for _, e in ipairs(enemyList) do
		e.alive = false
		enemyByModel[e.model] = nil
		if e.model then
			e.model:Destroy()
		end
	end
	table.clear(enemyList)
	for _, spec in ipairs(Map.EnemySpawns) do
		local _, c = defOf(spec.Type)
		if c and c.Defeated then -- (a gate keeper, once down, stays down)
			continue
		end
		local ok, e = pcall(spawnEnemy, spec)
		if ok and e then
			table.insert(enemyList, e)
		elseif not ok then
			warn("[DGUS] failed to spawn " .. tostring(spec.Type) .. ": " .. tostring(e))
		end
	end
end

function Enemies.respawn()
	respawnEnemies()
end
function Enemies.count()
	return #enemyList
end
function Enemies.byModel(model)
	return enemyByModel[model]
end

function Enemies.init(core)
	Map, EnemiesFolder, Roster = core.Map, core.EnemiesFolder, core.Roster
	now, flat, playSound, SOUNDS, burst, pose, setTrail = core.now, core.flat, core.playSound, core.SOUNDS, core.burst, core.pose, core.setTrail
	faceTowards, findShoulder = core.faceTowards, core.findShoulder
	makeRig, makeCorpse, ragdoll, aliveChar = core.makeRig, core.makeCorpse, core.ragdoll, core.aliveChar
	losParams.FilterDescendantsInstances = { EnemiesFolder, Map.Bars }
	-- hits on a regular enemy: poise, a stagger (any hit staggers the weak ones), knockback
	core.registerTarget(function(model)
		local e = enemyByModel[model]
		if not e then
			return nil
		end
		return {
			owner = e,
			actor = e,
			maxPoise = e.def.Poise,
			freeze = true,
			armor = e.def.HyperArmor and e.attacking,
			onHit = function()
				e.aggro = true
			end,
			onBreak = function(player, t, hitStop)
				local root = e.root
				e.staggerUntil = t + e.def.Stagger
				setTrail(e, false)
				pose(e, "Flinch", 0.1)
				if e.char and e.char.onStagger then
					e.char.onStagger(e)
				end
				task.delay(e.def.Stagger, function()
					if e.alive and not e.attacking then
						pose(e, "Idle", 0.25)
					end
				end)
				local pl = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if pl then
					local push = flat(root.Position - pl.Position)
					if push.Magnitude > 0.01 then
						task.delay(hitStop or 0, function()
							if root.Parent and not root.Anchored then
								root.AssemblyLinearVelocity = push.Unit * (e.def.StaggerPush or 16) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
							end
						end)
					end
				end
			end,
		}
	end)
end

return Enemies
