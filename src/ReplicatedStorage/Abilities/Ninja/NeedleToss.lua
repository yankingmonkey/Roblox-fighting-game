-- Needle Toss
-- A fast, cheap needle.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under NeedleToss.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.NeedleToss

local Ability = {
	id = "NeedleToss",
	classId = "Ninja",
	name = "Needle Toss",
	description = "A fast, cheap needle.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "projectile",
	isUltimate = false,
	sortOrder = 8,
	color = Color3.fromRGB(190, 150, 255),
	vfx = "projectile",
	Execute = function(ctx)
		return AbilityRunner.Call("Projectile", ctx)
	end,
}

return Ability
