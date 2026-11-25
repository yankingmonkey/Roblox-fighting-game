-- Quake Line
-- Ultimate. A shockwave in a line in front of you.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under QuakeLine.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.QuakeLine

local Ability = {
	id = "QuakeLine",
	classId = "Brawler",
	name = "Quake Line",
	description = "Ultimate. A shockwave in a line in front of you.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "aoe",
	isUltimate = true,
	sortOrder = 21,
	color = Color3.fromRGB(255, 100, 40),
	vfx = "cone",
	Execute = function(ctx)
		return AbilityRunner.Call("Cone", ctx)
	end,
}

return Ability
