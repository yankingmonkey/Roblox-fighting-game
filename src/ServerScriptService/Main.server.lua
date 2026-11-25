--!strict
-- Server entry. Rojo turns this file into a Script that runs when the game starts.
-- Remotes are created first, then each service.

local Replicated = game:GetService("ReplicatedStorage"):WaitForChild("FightingClasses")
local Actions = require(Replicated.Shared.Actions)

local Remotes = require(script.Parent.Remotes)
local AbilityService = require(script.Parent.Services.AbilityService)
local BasicCombat = require(script.Parent.Services.BasicCombat)
local ClassService = require(script.Parent.Services.ClassService)
local CombatService = require(script.Parent.Services.CombatService)
local DataService = require(script.Parent.Services.DataService)
local EnergyService = require(script.Parent.Services.EnergyService)
local PoseService = require(script.Parent.Services.PoseService)

DataService.Start()
CombatService.Start()
EnergyService.Start()
AbilityService.Start()
ClassService.Start()
BasicCombat.Start()
PoseService.Start()

Remotes.Action.OnServerEvent:Connect(function(player: Player, payload: any)
	if typeof(payload) ~= "table" then
		return
	end
	local action = payload.action
	if action == Actions.Cast then
		AbilityService.HandleCast(player, payload)
	elseif action == Actions.SetClass then
		ClassService.HandleSetClass(player, payload)
	elseif action == Actions.SetLoadout then
		ClassService.HandleSetLoadout(player, payload)
	elseif action == Actions.SetBlock then
		CombatService.SetBlocking(player, payload.blocking == true)
	elseif action == Actions.Parry then
		CombatService.TryParry(player)
	elseif action == Actions.M1 then
		BasicCombat.HandleM1(player, payload)
	elseif action == Actions.Dash then
		BasicCombat.HandleDash(player, payload)
	end
end)

print("[FightingClasses] Server ready. Abilities, energy, and saving are running.")
