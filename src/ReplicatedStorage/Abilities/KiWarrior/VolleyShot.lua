-- Volley Shot
-- Three bolts in a spread. 8 damage each.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under VolleyShot.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".
-- Leave it as "" and the move still works. The client plays it when the id is set.

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.VolleyShot

local Ability = {
	id = "VolleyShot",
	classId = "KiWarrior",
	name = "Volley Shot",
	description = "Three bolts in a spread. 8 damage each.",
	icon = "",
	animationId = "",
	damage = (stats.damage or 0) * (stats.projectiles or 1),
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "projectile",
	isUltimate = false,
	sortOrder = 2,
	color = Color3.fromRGB(120, 190, 255),
	vfx = "projectile",
	Execute = function(ctx)
		-- Server only. The client loads this module for the name and the numbers.
		return AbilityRunner.Call("Projectile", ctx)
	end,
}

return Ability
