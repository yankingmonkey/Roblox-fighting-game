-- Flame Wave
-- A wave of fire in front of you.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under FlameWave.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".
-- Leave it as "" and the move still works. The client plays it when the id is set.

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.FlameWave

local Ability = {
	id = "FlameWave",
	classId = "Elemental",
	name = "Flame Wave",
	description = "A wave of fire in front of you.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "aoe",
	isUltimate = false,
	sortOrder = 5,
	color = Color3.fromRGB(255, 80, 30),
	vfx = "cone",
	Execute = function(ctx)
		-- Server only. The client loads this module for the name and the numbers.
		return AbilityRunner.Call("Cone", ctx)
	end,
}

return Ability
