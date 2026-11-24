-- Grab Toss
-- Hit the nearest foe and throw them. Stuns briefly.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under GrabToss.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".
-- Leave it as "" and the move still works. The client plays it when the id is set.

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.GrabToss

local Ability = {
	id = "GrabToss",
	classId = "Brawler",
	name = "Grab Toss",
	description = "Hit the nearest foe and throw them. Stuns briefly.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "melee",
	isUltimate = false,
	sortOrder = 2,
	color = Color3.fromRGB(210, 80, 50),
	vfx = "melee",
	Execute = function(ctx)
		-- Server only. The client loads this module for the name and the numbers.
		return AbilityRunner.Call("Melee", ctx)
	end,
}

return Ability
