-- Lightning Spike
-- A fast spike that stuns for a moment.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under LightningSpike.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".
-- Leave it as "" and the move still works. The client plays it when the id is set.

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.LightningSpike

local Ability = {
	id = "LightningSpike",
	classId = "Elemental",
	name = "Lightning Spike",
	description = "A fast spike that stuns for a moment.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "projectile",
	isUltimate = false,
	sortOrder = 3,
	color = Color3.fromRGB(230, 230, 80),
	vfx = "projectile",
	Execute = function(ctx)
		-- Server only. The client loads this module for the name and the numbers.
		return AbilityRunner.Call("Projectile", ctx)
	end,
}

return Ability
