-- Dive Bomb
-- Slam the ground. 36 damage from the air, 18 on the ground.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under DiveBomb.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".
-- Leave it as "" and the move still works. The client plays it when the id is set.

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.DiveBomb

local Ability = {
	id = "DiveBomb",
	classId = "Superhero",
	name = "Dive Bomb",
	description = "Slam the ground. 36 damage from the air, 18 on the ground.",
	icon = "",
	animationId = "",
	damage = stats.airDamage or stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "aoe",
	isUltimate = false,
	sortOrder = 5,
	color = Color3.fromRGB(200, 40, 55),
	vfx = "dive",
	Execute = function(ctx)
		-- Server only. The client loads this module for the name and the numbers.
		return AbilityRunner.Call("DiveBomb", ctx)
	end,
}

return Ability
