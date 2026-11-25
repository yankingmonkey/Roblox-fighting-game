-- Inferno Column
-- Ultimate. A pillar of fire around you.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under InfernoColumn.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.InfernoColumn

local Ability = {
	id = "InfernoColumn",
	classId = "Elemental",
	name = "Inferno Column",
	description = "Ultimate. A pillar of fire around you.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "aoe",
	isUltimate = true,
	sortOrder = 21,
	color = Color3.fromRGB(255, 80, 20),
	vfx = "aoe",
	Execute = function(ctx)
		return AbilityRunner.Call("Aoe", ctx)
	end,
}

return Ability
