-- Burst Dash
-- Dash forward with a very short invincible window.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under BurstDash.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".
-- Leave it as "" and the move still works. The client plays it when the id is set.

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.BurstDash

local Ability = {
	id = "BurstDash",
	classId = "Speedster",
	name = "Burst Dash",
	description = "Dash forward with a very short invincible window.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "movement",
	isUltimate = false,
	sortOrder = 1,
	color = Color3.fromRGB(255, 220, 80),
	vfx = "dash",
	Execute = function(ctx)
		-- Server only. The client loads this module for the name and the numbers.
		return AbilityRunner.Call("Dash", ctx)
	end,
}

return Ability
