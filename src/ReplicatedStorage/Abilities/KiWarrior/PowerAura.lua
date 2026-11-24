-- Power Aura
-- Raise your damage by 25% for 6 seconds.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under PowerAura.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".
-- Leave it as "" and the move still works. The client plays it when the id is set.

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.PowerAura

local Ability = {
	id = "PowerAura",
	classId = "KiWarrior",
	name = "Power Aura",
	description = "Raise your damage by 25% for 6 seconds.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "buff",
	isUltimate = false,
	sortOrder = 4,
	color = Color3.fromRGB(140, 210, 255),
	vfx = "buff",
	Execute = function(ctx)
		-- Server only. The client loads this module for the name and the numbers.
		return AbilityRunner.Call("Buff", ctx)
	end,
}

return Ability
