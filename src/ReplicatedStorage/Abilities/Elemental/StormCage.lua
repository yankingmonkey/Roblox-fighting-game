-- Storm Cage
-- Ultimate. A storm around you that stuns.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under StormCage.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".
-- Leave it as "" and the move still works. The client plays it when the id is set.

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.StormCage

local Ability = {
	id = "StormCage",
	classId = "Elemental",
	name = "Storm Cage",
	description = "Ultimate. A storm around you that stuns.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "aoe",
	isUltimate = true,
	sortOrder = 6,
	color = Color3.fromRGB(120, 170, 255),
	vfx = "aoe",
	Execute = function(ctx)
		-- Server only. The client loads this module for the name and the numbers.
		return AbilityRunner.Call("Aoe", ctx)
	end,
}

return Ability
