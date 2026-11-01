--!nonstrict
-- Roster: loads every character file in ReplicatedStorage/Characters and indexes
-- what the rest of the game needs from them: body shapes and poses (PuppetMath,
-- for the animator on every client), looks (RigBuilder), weapons and grip poses
-- (Core). To add a character, drop a new file in Characters; nothing else to wire.
local RunService = game:GetService("RunService")

local Roster = { byKind = {}, list = {}, kinds = {}, poses = {}, weapons = {}, grips = {}, bodyFor = {} }

function Roster.register(c)
	if type(c) ~= "table" or not c.Kind or Roster.byKind[c.Kind] then
		return
	end
	Roster.byKind[c.Kind] = c
	table.insert(Roster.list, c)
	local k = table.clone(c.Proportions or { girth = 1, arm = 1, hunch = 0 })
	k.idlePose = c.IdlePose
	Roster.kinds[c.Kind] = k
	for name, p in pairs(c.Poses or {}) do
		Roster.poses[name] = p
	end
	for name, w in pairs(c.Weapons or {}) do
		Roster.weapons[name] = w
	end
	for name, g in pairs(c.Grips or {}) do
		Roster.grips[name] = g
	end
	for name, b in pairs(c.BodyFor or {}) do
		Roster.bodyFor[name] = b
	end
end

pcall(function()
	if RunService:IsClient() and RunService:IsRunning() and not game:IsLoaded() then -- (in Edit it never loads: the dummy)
		game.Loaded:Wait()
	end
	local folder = (script.Parent :: any):WaitForChild("Characters", 10)
	if folder then
		for _, m in ipairs(folder:GetChildren()) do
			if m:IsA("ModuleScript") then
				local ok, c = pcall(require, m)
				if ok then
					Roster.register(c)
				else
					warn("[DGUS] character file " .. m.Name .. " failed to load: " .. tostring(c))
				end
			end
		end
	end
end)

return Roster
