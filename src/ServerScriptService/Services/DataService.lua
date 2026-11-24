--!strict
-- Saves class id + the 5 loadout slots.
-- Session cache is the copy gameplay reads. DataStore writes are wrapped in
-- pcall with a few retries. If Studio API access is off, we warn once and keep
-- playing with the in-memory copy.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Types = require(game:GetService("ReplicatedStorage").FightingClasses.Shared.Types)
type SaveData = Types.SaveData

local DATASTORE_NAME = "ClassLoadout_v1"
local MAX_ATTEMPTS = 3

local session: { [Player]: SaveData } = {}
local dirty: { [Player]: boolean } = {}
local storeDisabled = false
local warned = false
local store: DataStore? = nil

local DataService = {}

local function key(player: Player): string
	return "u" .. tostring(player.UserId)
end

local function warnDisabled(err: any)
	if warned then
		return
	end
	warned = true
	warn(
		"[FightingClasses] DataStore is unavailable (",
		err,
		"). Class and loadout work for this session but will not save. In Studio, turn on Game Settings > Security > Enable Studio Access to API Services. A published game saves normally."
	)
end

local function isApiDisabled(err: any): boolean
	local text = string.lower(tostring(err))
	local mentionsStudio = string.find(text, "studio", 1, true) ~= nil
	local mentionsAccess = string.find(text, "api", 1, true) ~= nil or string.find(text, "publish", 1, true) ~= nil
	return mentionsStudio and mentionsAccess
end

local function getStore(): DataStore?
	if storeDisabled then
		return nil
	end
	if store then
		return store
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(DATASTORE_NAME)
	end)
	if not ok then
		if isApiDisabled(result) then
			storeDisabled = true
			warnDisabled(result)
		else
			warn("[FightingClasses] Could not open the DataStore:", result)
		end
		return nil
	end
	store = result
	return store
end

local function copySlots(raw: any): { string }
	local slots = { "", "", "", "", "" }
	if typeof(raw) ~= "table" then
		return slots
	end
	for index = 1, 5 do
		local value = raw[index]
		if typeof(value) == "string" then
			slots[index] = value
		end
	end
	return slots
end

local function readOnce(player: Player): (boolean, any)
	local dataStore = getStore()
	if not dataStore then
		return true, nil
	end
	return pcall(function()
		return dataStore:GetAsync(key(player))
	end)
end

function DataService.Load(player: Player): SaveData
	local cached = session[player]
	if cached then
		return cached
	end

	local loaded: any = nil
	if not storeDisabled then
		for attempt = 1, MAX_ATTEMPTS do
			local ok, result = readOnce(player)
			if ok then
				loaded = result
				break
			end
			if isApiDisabled(result) then
				storeDisabled = true
				warnDisabled(result)
				break
			end
			warn("[FightingClasses] Load failed for", player.Name, "attempt", attempt, result)
			task.wait(attempt)
		end
	end

	local classId = ""
	local slots = { "", "", "", "", "" }
	if typeof(loaded) == "table" then
		if typeof(loaded.classId) == "string" then
			classId = loaded.classId
		end
		slots = copySlots(loaded.loadout)
	end

	local data: SaveData = {
		classId = classId,
		loadout = slots,
	}
	session[player] = data
	return data
end

function DataService.Get(player: Player): SaveData?
	return session[player]
end

function DataService.Set(player: Player, data: SaveData, markDirty: boolean)
	session[player] = {
		classId = data.classId,
		loadout = table.clone(data.loadout),
	}
	if markDirty then
		dirty[player] = true
	end
end

function DataService.Save(player: Player)
	local data = session[player]
	if not data or storeDisabled then
		dirty[player] = nil
		return
	end
	local dataStore = getStore()
	if not dataStore then
		dirty[player] = nil
		return
	end
	local payload = {
		classId = data.classId,
		loadout = table.clone(data.loadout),
	}
	for attempt = 1, MAX_ATTEMPTS do
		local ok, err = pcall(function()
			dataStore:SetAsync(key(player), payload)
		end)
		if ok then
			dirty[player] = nil
			return
		end
		if isApiDisabled(err) then
			storeDisabled = true
			warnDisabled(err)
			dirty[player] = nil
			return
		end
		warn("[FightingClasses] Save failed for", player.Name, "attempt", attempt, err)
		if attempt < MAX_ATTEMPTS then
			task.wait(attempt)
		end
	end
end

function DataService.Start()
	Players.PlayerRemoving:Connect(function(player)
		DataService.Save(player)
		session[player] = nil
		dirty[player] = nil
	end)

	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			DataService.Save(player)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(20)
			for _, player in Players:GetPlayers() do
				if dirty[player] then
					DataService.Save(player)
				end
			end
		end
	end)
end

return DataService
