-- Shadow Clone
-- A decoy that punches for 8 every 1.5s. Any hit destroys it.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under ShadowClone.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".
-- Leave it as "" and the move still works. The client plays it when the id is set.

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.ShadowClone

local Ability = {
	id = "ShadowClone",
	classId = "Ninja",
	name = "Shadow Clone",
	description = "A decoy that punches for 8 every 1.5s. Any hit destroys it.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "summon",
	isUltimate = false,
	sortOrder = 3,
	color = Color3.fromRGB(180, 120, 255),
	vfx = "clone",
	Execute = function(ctx)
		-- Server only. The client loads this module for the name and the numbers.
		return AbilityRunner.Call("ShadowClone", ctx)
	end,
}

return Ability
