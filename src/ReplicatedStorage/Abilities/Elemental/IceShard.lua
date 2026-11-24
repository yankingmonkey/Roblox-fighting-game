-- Ice Shard
-- A shard that slows whoever it hits.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under IceShard.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".
-- Leave it as "" and the move still works. The client plays it when the id is set.

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.IceShard

local Ability = {
	id = "IceShard",
	classId = "Elemental",
	name = "Ice Shard",
	description = "A shard that slows whoever it hits.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "projectile",
	isUltimate = false,
	sortOrder = 2,
	color = Color3.fromRGB(140, 220, 255),
	vfx = "projectile",
	Execute = function(ctx)
		-- Server only. The client loads this module for the name and the numbers.
		return AbilityRunner.Call("Projectile", ctx)
	end,
}

return Ability
