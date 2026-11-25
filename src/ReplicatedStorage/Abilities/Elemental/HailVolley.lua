-- Hail Volley
-- Four icy shots. Each one slows.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under HailVolley.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.HailVolley

local Ability = {
	id = "HailVolley",
	classId = "Elemental",
	name = "Hail Volley",
	description = "Four icy shots. Each one slows.",
	icon = "",
	animationId = "",
	damage = (stats.damage or 0) * (stats.projectiles or 1),
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "projectile",
	isUltimate = false,
	sortOrder = 8,
	color = Color3.fromRGB(160, 220, 255),
	vfx = "projectile",
	Execute = function(ctx)
		return AbilityRunner.Call("Projectile", ctx)
	end,
}

return Ability
