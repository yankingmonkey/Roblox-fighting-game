--!strict
-- Encodes 5 ability ids into one string attribute and checks that a loadout
-- is legal: slots 1-4 are normal abilities, slot 5 (Q) is an ultimate.

local AbilityRegistry = require(script.Parent.AbilityRegistry)
local Classes = require(script.Parent.Classes)

local LoadoutUtil = {}

local EMPTY = "_"
local SEP = "|"

function LoadoutUtil.Encode(slots: { string }): string
	local parts = {}
	for index = 1, 5 do
		local id = slots[index]
		if id == nil or id == "" then
			parts[index] = EMPTY
		else
			parts[index] = id
		end
	end
	return table.concat(parts, SEP)
end

function LoadoutUtil.Decode(blob: any): { string }
	local slots = { "", "", "", "", "" }
	if typeof(blob) ~= "string" or blob == "" then
		return slots
	end
	local index = 1
	local startAt = 1
	for pos = 1, #blob + 1 do
		if pos == #blob + 1 or string.sub(blob, pos, pos) == SEP then
			local piece = string.sub(blob, startAt, pos - 1)
			if piece ~= EMPTY then
				slots[index] = piece
			end
			index += 1
			startAt = pos + 1
			if index > 5 then
				break
			end
		end
	end
	return slots
end

function LoadoutUtil.Default(classId: string): { string }
	local info = Classes.ById[classId]
	if not info then
		return { "", "", "", "", "" }
	end
	local slots = { "", "", "", "", "" }
	for index = 1, 5 do
		slots[index] = info.defaultLoadout[index] or ""
	end
	return slots
end

function LoadoutUtil.Validate(classId: string, slots: { string }): (boolean, string)
	if not Classes.ById[classId] then
		return false, "Unknown class."
	end
	local seen: { [string]: boolean } = {}
	for index = 1, 5 do
		local id = slots[index]
		if typeof(id) ~= "string" then
			return false, "Bad ability id."
		end
		if id ~= "" then
			if seen[id] then
				return false, "That ability is already equipped."
			end
			seen[id] = true
			local ability = AbilityRegistry.Get(id)
			if not ability or ability.classId ~= classId then
				return false, "That ability is not part of this class."
			end
			if index < 5 and ability.isUltimate then
				return false, "Ultimates only go in the Q slot."
			end
			if index == 5 and not ability.isUltimate then
				return false, "The Q slot only accepts an ultimate."
			end
		end
	end
	return true, ""
end

return LoadoutUtil
