-- Shockwave Leap
-- Leap forward and clip anyone in the path.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under ShockwaveLeap.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.ShockwaveLeap

local Ability = {
	id = "ShockwaveLeap",
	classId = "Superhero",
	name = "Shockwave Leap",
	description = "Leap forward and clip anyone in the path.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "movement",
	isUltimate = false,
	sortOrder = 9,
	color = Color3.fromRGB(255, 90, 100),
	vfx = "dash",
	Execute = function(ctx)
		return AbilityRunner.Call("Dash", ctx)
	end,
}

return Ability
