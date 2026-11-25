-- Clone Rush
-- Ultimate. Five charging clones, 16 damage each. A hit destroys a clone before it connects.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under CloneRush.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".
-- Leave it as "" and the move still works. The client plays it when the id is set.

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.CloneRush

local Ability = {
	id = "CloneRush",
	classId = "Ninja",
	name = "Clone Rush",
	description = "Ultimate. Five charging clones, 16 damage each. A hit destroys a clone before it connects.",
	icon = "",
	animationId = "",
	damage = (stats.damage or 0) * (stats.projectiles or 1),
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "summon",
	isUltimate = true,
	sortOrder = 20,
	color = Color3.fromRGB(230, 180, 255),
	vfx = "cloneRush",
	Execute = function(ctx)
		-- Server only. The client loads this module for the name and the numbers.
		return AbilityRunner.Call("CloneRush", ctx)
	end,
}

return Ability
