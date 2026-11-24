-- Speed Trap
-- A burst around you that damages and slows.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under SpeedTrap.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".
-- Leave it as "" and the move still works. The client plays it when the id is set.

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.SpeedTrap

local Ability = {
	id = "SpeedTrap",
	classId = "Speedster",
	name = "Speed Trap",
	description = "A burst around you that damages and slows.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "aoe",
	isUltimate = false,
	sortOrder = 5,
	color = Color3.fromRGB(230, 180, 40),
	vfx = "aoe",
	Execute = function(ctx)
		-- Server only. The client loads this module for the name and the numbers.
		return AbilityRunner.Call("Aoe", ctx)
	end,
}

return Ability
