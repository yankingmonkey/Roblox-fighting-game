--!strict
-- First join shows the class picker (ClassId stays empty until they choose).
-- Changing class is rejected while InCombat is true. The loadout resets to
-- that class's default when the class changes.

local Players = game:GetService("Players")

local Replicated = game:GetService("ReplicatedStorage").FightingClasses
local Actions = require(Replicated.Shared.Actions)
local Balance = require(Replicated.Shared.Balance)
local Classes = require(Replicated.Shared.Classes)
local LoadoutUtil = require(Replicated.Shared.LoadoutUtil)
local AbilityService = require(script.Parent.AbilityService)
local CombatService = require(script.Parent.CombatService)
local DataService = require(script.Parent.DataService)
local Remotes = require(script.Parent.Parent.Remotes)

local lastClassChange: { [Player]: number } = {}

local ClassService = {}

local function menu(player: Player, ok: boolean, reason: string)
	Remotes.Tell(player, {
		action = Actions.MenuResult,
		ok = ok,
		reason = reason,
	})
end

local function apply(player: Player, classId: string, slots: { string }, saveNow: boolean)
	player:SetAttribute("ClassId", classId)
	player:SetAttribute("Loadout", LoadoutUtil.Encode(slots))
	DataService.Set(player, {
		classId = classId,
		loadout = slots,
	}, true)
	if saveNow then
		DataService.Save(player)
	end
end

local function loadPlayer(player: Player)
	local data = DataService.Load(player)
	if not player.Parent then
		return
	end
	if player:GetAttribute("InCombat") == nil then
		player:SetAttribute("InCombat", false)
	end

	local classId = data.classId
	if classId ~= "" and Classes.ById[classId] then
		local slots = data.loadout
		local ok = LoadoutUtil.Validate(classId, slots)
		if not ok then
			slots = LoadoutUtil.Default(classId)
			apply(player, classId, slots, true)
		else
			player:SetAttribute("ClassId", classId)
			player:SetAttribute("Loadout", LoadoutUtil.Encode(slots))
		end
	else
		player:SetAttribute("ClassId", "")
		player:SetAttribute("Loadout", LoadoutUtil.Encode({ "", "", "", "", "" }))
	end
end

function ClassService.HandleSetClass(player: Player, payload: { [string]: any })
	local classId = payload.classId
	if typeof(classId) ~= "string" or not Classes.ById[classId] then
		menu(player, false, "Unknown class.")
		return
	end
	local now = os.clock()
	local previous = lastClassChange[player]
	if previous and now - previous < 1.5 then
		menu(player, false, "Wait a moment.")
		return
	end

	local current = player:GetAttribute("ClassId")
	if typeof(current) == "string" and current ~= "" and current ~= classId then
		if CombatService.IsInCombat(player) then
			menu(player, false, "Leave combat before changing class.")
			return
		end
	end
	if current == classId then
		menu(player, true, "Already that class.")
		return
	end

	lastClassChange[player] = now
	local slots = LoadoutUtil.Default(classId)
	apply(player, classId, slots, true)
	AbilityService.ClearAll(player)
	menu(player, true, "Class set.")
end

function ClassService.HandleSetLoadout(player: Player, payload: { [string]: any })
	local classId = player:GetAttribute("ClassId")
	if typeof(classId) ~= "string" or classId == "" then
		menu(player, false, "Pick a class first.")
		return
	end
	if Balance.LoadoutRequiresPeace and CombatService.IsInCombat(player) then
		menu(player, false, "Leave combat before changing your loadout.")
		return
	end
	if typeof(payload.slots) ~= "table" then
		menu(player, false, "Bad loadout.")
		return
	end

	local slots = { "", "", "", "", "" }
	for index = 1, 5 do
		local value = payload.slots[index]
		if value == nil or value == "" then
			slots[index] = ""
		elseif typeof(value) == "string" then
			slots[index] = value
		else
			menu(player, false, "Bad loadout.")
			return
		end
	end

	local ok, reason = LoadoutUtil.Validate(classId, slots)
	if not ok then
		menu(player, false, reason)
		return
	end
	apply(player, classId, slots, false)
	menu(player, true, "Loadout saved.")
end

function ClassService.Start()
	for _, info in Classes.List do
		local ok, reason = LoadoutUtil.Validate(info.id, info.defaultLoadout)
		if not ok then
			warn("[FightingClasses] Default loadout for", info.name, "is invalid:", reason)
		end
	end

	local function hook(player: Player)
		task.spawn(loadPlayer, player)
	end
	Players.PlayerAdded:Connect(hook)
	for _, player in Players:GetPlayers() do
		hook(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastClassChange[player] = nil
	end)
end

return ClassService
