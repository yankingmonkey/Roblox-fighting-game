-- Shuriken Fan
-- Three throwing stars, 9 damage each.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under ShurikenFan.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".
-- Leave it as "" and the move still works. The client plays it when the id is set.

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.ShurikenFan

local Ability = {
	id = "ShurikenFan",
	classId = "Ninja",
	name = "Shuriken Fan",
	description = "Three throwing stars, 9 damage each.",
	icon = "",
	animationId = "",
	damage = (stats.damage or 0) * (stats.projectiles or 1),
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "projectile",
	isUltimate = false,
	sortOrder = 1,
	color = Color3.fromRGB(200, 140, 255),
	vfx = "projectile",
	Execute = function(ctx)
		-- Server only. The client loads this module for the name and the numbers.
		return AbilityRunner.Call("Projectile", ctx)
	end,
}

return Ability
