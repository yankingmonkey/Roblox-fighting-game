-- Ember Burst
-- Fire around your feet.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under EmberBurst.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.EmberBurst

local Ability = {
	id = "EmberBurst",
	classId = "Elemental",
	name = "Ember Burst",
	description = "Fire around your feet.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "aoe",
	isUltimate = false,
	sortOrder = 7,
	color = Color3.fromRGB(255, 120, 40),
	vfx = "aoe",
	Execute = function(ctx)
		return AbilityRunner.Call("Aoe", ctx)
	end,
}

return Ability
