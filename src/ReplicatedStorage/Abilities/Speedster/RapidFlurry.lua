-- Rapid Flurry
-- Six quick punches, 7 damage each.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under RapidFlurry.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".
-- Leave it as "" and the move still works. The client plays it when the id is set.

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.RapidFlurry

local Ability = {
	id = "RapidFlurry",
	classId = "Speedster",
	name = "Rapid Flurry",
	description = "Six quick punches, 7 damage each.",
	icon = "",
	animationId = "",
	damage = (stats.hitDamage or 0) * (stats.hits or 1),
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "melee",
	isUltimate = false,
	sortOrder = 3,
	color = Color3.fromRGB(255, 230, 120),
	vfx = "flurry",
	Execute = function(ctx)
		-- Server only. The client loads this module for the name and the numbers.
		return AbilityRunner.Call("Flurry", ctx)
	end,
}

return Ability
