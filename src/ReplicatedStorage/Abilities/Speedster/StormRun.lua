-- Storm Run
-- Ultimate. A long lightning dash through anyone in the way.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under StormRun.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.StormRun

local Ability = {
	id = "StormRun",
	classId = "Speedster",
	name = "Storm Run",
	description = "Ultimate. A long lightning dash through anyone in the way.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "movement",
	isUltimate = true,
	sortOrder = 21,
	color = Color3.fromRGB(255, 230, 90),
	vfx = "dash",
	Execute = function(ctx)
		return AbilityRunner.Call("Dash", ctx)
	end,
}

return Ability
