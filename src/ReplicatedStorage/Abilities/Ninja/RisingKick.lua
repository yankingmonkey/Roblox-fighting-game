-- Rising Kick
-- A close kick with knockback.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under RisingKick.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.RisingKick

local Ability = {
	id = "RisingKick",
	classId = "Ninja",
	name = "Rising Kick",
	description = "A close kick with knockback.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "melee",
	isUltimate = false,
	sortOrder = 9,
	color = Color3.fromRGB(200, 140, 255),
	vfx = "melee",
	Execute = function(ctx)
		return AbilityRunner.Call("Melee", ctx)
	end,
}

return Ability
