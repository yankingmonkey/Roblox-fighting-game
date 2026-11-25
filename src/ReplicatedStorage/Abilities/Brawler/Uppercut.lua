-- Uppercut
-- A rising punch that stuns briefly.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under Uppercut.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.Uppercut

local Ability = {
	id = "Uppercut",
	classId = "Brawler",
	name = "Uppercut",
	description = "A rising punch that stuns briefly.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "melee",
	isUltimate = false,
	sortOrder = 7,
	color = Color3.fromRGB(240, 120, 70),
	vfx = "melee",
	Execute = function(ctx)
		return AbilityRunner.Call("Melee", ctx)
	end,
}

return Ability
