--!nonstrict
-- SAVE: the game is single-player - a server holds one player, and its world is theirs. Everything they have and have
-- done is a player attribute (weapons, armor, stats, splinters, lit bonfires, quest steps), and so is every one-time
-- event in the world (a gate opened, a chest emptied, a boss beaten: "W_<name>", Save.mark). A save is just those
-- attributes, in a DataStore. init.server loads it before the world wakes ("go"): the events marked in it are replayed
-- then (Save.on, quietly: Save.quiet), and each boss checks Save.done before it stands up.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Save = { player = nil, quiet = false }
local KEY = "player_"
-- the moment's state, not progress: never saved
local SKIP = {
	Flasks = true, MaxFlasks = true, Stamina = true, MaxStamina = true, InFog = true, PoisonBuild = true, Beneath = true,
	Smoulder = true, CourtDark = true, RottedAir = true, Gleam = true, ConsulTint = true, Broken = true, IaiReady = true, GildedNext = true,
	Dev = true, -- (the dev menu is given afresh each time: init.server's isDev)
}
local store
pcall(function()
	store = DataStoreService:GetDataStore("DGUS_Save_v1")
end)
local loadFailed, wiped = false, false

-- the world's one-time events
function Save.done(name)
	return Save.player ~= nil and Save.player:GetAttribute("W_" .. name) == true
end
function Save.mark(name)
	if Save.player then
		Save.player:SetAttribute("W_" .. name, true)
	end
end
local replays = {}
-- fn(): put the world as event `name` left it - run once at load if the save has it (and usually, after Save.mark,
-- when it happens). init.server has sounds off meanwhile (Save.quiet), and the client holding its messages
function Save.on(name, fn)
	table.insert(replays, { name, fn })
end
function Save.replay()
	for _, r in ipairs(replays) do
		if Save.done(r[1]) then
			local ok, err = pcall(r[2])
			if not ok then
				warn("[Save] replaying " .. r[1] .. ": " .. tostring(err))
			end
		end
	end
end

-- true if a save was found and put on the player
function Save.load(player)
	Save.player = player
	if not store then
		loadFailed = true
		warn("[Save] no DataStore (in Studio: Game Settings > Security > Enable Studio Access to API Services). Progress won't be saved.")
		return false
	end
	local ok, data = pcall(store.GetAsync, store, KEY .. player.UserId)
	if not ok then
		loadFailed = true -- (never write over a save we couldn't read: it would be lost)
		warn("[Save] couldn't load, so progress won't be saved this session: " .. tostring(data))
		return false
	end
	for name, v in pairs(data and data.attrs or {}) do
		player:SetAttribute(name, v)
	end
	return data ~= nil
end

function Save.write()
	local pl = Save.player
	if not (store and pl) or loadFailed or wiped then
		return
	end
	local attrs = {}
	for name, v in pairs(pl:GetAttributes()) do
		local t = typeof(v)
		if not SKIP[name] and (t == "boolean" or t == "number" or t == "string") then
			attrs[name] = v
		end
	end
	local ok, err = pcall(store.SetAsync, store, KEY .. pl.UserId, { v = 1, attrs = attrs }, { pl.UserId })
	if not ok then
		warn("[Save] couldn't save: " .. tostring(err))
	end
end

-- everything gone: the save wiped, and the player sent to a fresh server (Studio can't teleport: they're asked to rejoin)
function Save.reset(player)
	if player ~= Save.player then
		return false
	end
	if store and not loadFailed then
		local ok, err = pcall(store.RemoveAsync, store, KEY .. player.UserId)
		if not ok then
			warn("[Save] couldn't wipe the save: " .. tostring(err))
			return false
		end
	end
	wiped = true
	local sent = not RunService:IsStudio() and pcall(TeleportService.TeleportAsync, TeleportService, game.PlaceId, { player })
	if not sent then
		player:Kick("Your progress has been reset. Rejoin to start a new game.")
	end
	return true
end

-- one player to a server (also set Max Players to 1 in Game Settings > Places)
Players.PlayerAdded:Connect(function(pl)
	if Save.player and Save.player.Parent and pl ~= Save.player then
		pl:Kick("This is a single-player game.")
	end
end)
Players.PlayerRemoving:Connect(function(pl)
	if pl == Save.player then
		Save.write()
	end
end)
game:BindToClose(function()
	if Save.player and Save.player.Parent then
		Save.write()
	end
end)
task.spawn(function()
	while true do
		task.wait(30)
		if Save.player and Save.player.Parent then
			Save.write()
		end
	end
end)

return Save
