-- Wall Blink
-- Blink forward. If a wall is in the way, you kick up it.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under WallBlink.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".
-- Leave it as "" and the move still works. The client plays it when the id is set.

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.WallBlink

local Ability = {
	id = "WallBlink",
	classId = "Ninja",
	name = "Wall Blink",
	description = "Blink forward. If a wall is in the way, you kick up it.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "movement",
	isUltimate = false,
	sortOrder = 5,
	color = Color3.fromRGB(130, 80, 210),
	vfx = "blink",
	Execute = function(ctx)
		-- Server only. The client loads this module for the name and the numbers.
		return AbilityRunner.Call("Dash", ctx)
	end,
}

return Ability
