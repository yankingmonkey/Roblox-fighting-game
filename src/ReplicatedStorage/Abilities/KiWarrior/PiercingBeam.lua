-- Piercing Beam
-- A straight beam. It stops at the first person or wall.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under PiercingBeam.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".
-- Leave it as "" and the move still works. The client plays it when the id is set.

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.PiercingBeam

local Ability = {
	id = "PiercingBeam",
	classId = "KiWarrior",
	name = "Piercing Beam",
	description = "A straight beam. It stops at the first person or wall.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "beam",
	isUltimate = false,
	sortOrder = 3,
	color = Color3.fromRGB(90, 220, 255),
	vfx = "beam",
	Execute = function(ctx)
		-- Server only. The client loads this module for the name and the numbers.
		return AbilityRunner.Call("Beam", ctx)
	end,
}

return Ability
