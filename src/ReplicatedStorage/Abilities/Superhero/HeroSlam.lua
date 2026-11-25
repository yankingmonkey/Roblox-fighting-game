-- Hero Slam
-- Slam the ground around you.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under HeroSlam.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.HeroSlam

local Ability = {
	id = "HeroSlam",
	classId = "Superhero",
	name = "Hero Slam",
	description = "Slam the ground around you.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "aoe",
	isUltimate = false,
	sortOrder = 8,
	color = Color3.fromRGB(230, 50, 60),
	vfx = "aoe",
	Execute = function(ctx)
		return AbilityRunner.Call("Aoe", ctx)
	end,
}

return Ability
