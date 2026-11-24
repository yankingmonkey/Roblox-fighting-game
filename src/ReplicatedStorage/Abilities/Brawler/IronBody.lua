-- Iron Body
-- Take 40% less damage and ignore stuns for 4 seconds.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under IronBody.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".
-- Leave it as "" and the move still works. The client plays it when the id is set.

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.IronBody

local Ability = {
	id = "IronBody",
	classId = "Brawler",
	name = "Iron Body",
	description = "Take 40% less damage and ignore stuns for 4 seconds.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "buff",
	isUltimate = false,
	sortOrder = 5,
	color = Color3.fromRGB(180, 70, 40),
	vfx = "buff",
	Execute = function(ctx)
		-- Server only. The client loads this module for the name and the numbers.
		return AbilityRunner.Call("Buff", ctx)
	end,
}

return Ability
