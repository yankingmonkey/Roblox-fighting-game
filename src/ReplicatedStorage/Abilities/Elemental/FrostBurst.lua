-- Frost Burst
-- Cold around you. Damage and a strong slow.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under FrostBurst.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".
-- Leave it as "" and the move still works. The client plays it when the id is set.

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.FrostBurst

local Ability = {
	id = "FrostBurst",
	classId = "Elemental",
	name = "Frost Burst",
	description = "Cold around you. Damage and a strong slow.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "aoe",
	isUltimate = false,
	sortOrder = 4,
	color = Color3.fromRGB(170, 230, 255),
	vfx = "aoe",
	Execute = function(ctx)
		-- Server only. The client loads this module for the name and the numbers.
		return AbilityRunner.Call("Aoe", ctx)
	end,
}

return Ability
