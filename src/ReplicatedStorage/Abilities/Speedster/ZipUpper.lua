-- Zip Upper
-- A short dash that clips anyone in the path.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under ZipUpper.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.ZipUpper

local Ability = {
	id = "ZipUpper",
	classId = "Speedster",
	name = "Zip Upper",
	description = "A short dash that clips anyone in the path.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "movement",
	isUltimate = false,
	sortOrder = 8,
	color = Color3.fromRGB(255, 200, 60),
	vfx = "dash",
	Execute = function(ctx)
		return AbilityRunner.Call("Dash", ctx)
	end,
}

return Ability
