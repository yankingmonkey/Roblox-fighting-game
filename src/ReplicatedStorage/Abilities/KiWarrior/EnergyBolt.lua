-- Energy Bolt
-- A fast bolt of ki.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under EnergyBolt.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".
-- Leave it as "" and the move still works. The client plays it when the id is set.

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.EnergyBolt

local Ability = {
	id = "EnergyBolt",
	classId = "KiWarrior",
	name = "Energy Bolt",
	description = "A fast bolt of ki.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "projectile",
	isUltimate = false,
	sortOrder = 1,
	color = Color3.fromRGB(80, 180, 255),
	vfx = "projectile",
	Execute = function(ctx)
		-- Server only. The client loads this module for the name and the numbers.
		return AbilityRunner.Call("Projectile", ctx)
	end,
}

return Ability
