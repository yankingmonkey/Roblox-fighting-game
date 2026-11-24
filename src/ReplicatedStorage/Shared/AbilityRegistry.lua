--!strict
-- Loads every ModuleScript under Abilities/<Class>/<Ability>.
-- Client and server both require this. Execute is only called on the server.

local Types = require(script.Parent.Types)
type AbilityDefinition = Types.AbilityDefinition

local byId: { [string]: AbilityDefinition } = {}
local byClass: { [string]: { AbilityDefinition } } = {}

local abilitiesFolder = script.Parent.Parent:WaitForChild("Abilities")

for _, classFolder in abilitiesFolder:GetChildren() do
	if classFolder:IsA("Folder") then
		for _, child in classFolder:GetChildren() do
			if child:IsA("ModuleScript") then
				local ok, ability = pcall(require, child)
				if ok and typeof(ability) == "table" and typeof(ability.id) == "string" then
					local typed = ability :: AbilityDefinition
					byId[typed.id] = typed
					local list = byClass[typed.classId]
					if not list then
						list = {}
						byClass[typed.classId] = list
					end
					table.insert(list, typed)
				else
					warn("[FightingClasses] Failed to load ability", child:GetFullName(), ability)
				end
			end
		end
	end
end

for _, list in byClass do
	table.sort(list, function(a, b)
		return a.sortOrder < b.sortOrder
	end)
end

local AbilityRegistry = {}

function AbilityRegistry.Get(id: string): AbilityDefinition?
	return byId[id]
end

function AbilityRegistry.GetClassAbilities(classId: string): { AbilityDefinition }
	local list = byClass[classId]
	if not list then
		return {}
	end
	return table.clone(list)
end

return AbilityRegistry
