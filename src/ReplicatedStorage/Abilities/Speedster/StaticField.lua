-- Static Field
-- A ring of static that can stun for a moment.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under StaticField.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.StaticField

local Ability = {
	id = "StaticField",
	classId = "Speedster",
	name = "Static Field",
	description = "A ring of static that can stun for a moment.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "aoe",
	isUltimate = false,
	sortOrder = 9,
	color = Color3.fromRGB(255, 240, 140),
	vfx = "aoe",
	Execute = function(ctx)
		return AbilityRunner.Call("Aoe", ctx)
	end,
}

return Ability
