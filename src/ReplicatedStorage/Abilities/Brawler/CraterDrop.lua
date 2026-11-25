-- Crater Drop
-- Ultimate. A heavy slam around you. You have super-armor as it lands.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under CraterDrop.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".
-- Leave it as "" and the move still works. The client plays it when the id is set.

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.CraterDrop

local Ability = {
	id = "CraterDrop",
	classId = "Brawler",
	name = "Crater Drop",
	description = "Ultimate. A heavy slam around you. You have super-armor as it lands.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "aoe",
	isUltimate = true,
	sortOrder = 20,
	color = Color3.fromRGB(255, 90, 40),
	vfx = "aoe",
	Execute = function(ctx)
		-- Server only. The client loads this module for the name and the numbers.
		return AbilityRunner.Call("Aoe", ctx)
	end,
}

return Ability
