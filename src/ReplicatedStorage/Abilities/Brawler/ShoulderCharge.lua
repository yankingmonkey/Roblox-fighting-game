-- Shoulder Charge
-- Rush forward with super-armor and knockback.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under ShoulderCharge.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".
-- Leave it as "" and the move still works. The client plays it when the id is set.

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.ShoulderCharge

local Ability = {
	id = "ShoulderCharge",
	classId = "Brawler",
	name = "Shoulder Charge",
	description = "Rush forward with super-armor and knockback.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "movement",
	isUltimate = false,
	sortOrder = 4,
	color = Color3.fromRGB(240, 140, 60),
	vfx = "dash",
	Execute = function(ctx)
		-- Server only. The client loads this module for the name and the numbers.
		return AbilityRunner.Call("Dash", ctx)
	end,
}

return Ability
