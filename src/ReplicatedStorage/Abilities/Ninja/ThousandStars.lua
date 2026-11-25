-- Thousand Stars
-- Ultimate. A wide fan of eight stars, 8 damage each.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under ThousandStars.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.ThousandStars

local Ability = {
	id = "ThousandStars",
	classId = "Ninja",
	name = "Thousand Stars",
	description = "Ultimate. A wide fan of eight stars, 8 damage each.",
	icon = "",
	animationId = "",
	damage = (stats.damage or 0) * (stats.projectiles or 1),
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "projectile",
	isUltimate = true,
	sortOrder = 21,
	color = Color3.fromRGB(220, 180, 255),
	vfx = "projectile",
	Execute = function(ctx)
		return AbilityRunner.Call("Projectile", ctx)
	end,
}

return Ability
