-- War Cry
-- A shout that slows people around you.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under WarCry.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.WarCry

local Ability = {
	id = "WarCry",
	classId = "Brawler",
	name = "War Cry",
	description = "A shout that slows people around you.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "aoe",
	isUltimate = false,
	sortOrder = 9,
	color = Color3.fromRGB(200, 70, 40),
	vfx = "aoe",
	Execute = function(ctx)
		return AbilityRunner.Call("Aoe", ctx)
	end,
}

return Ability
