-- Lariat
-- A wide swinging punch.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under Lariat.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.Lariat

local Ability = {
	id = "Lariat",
	classId = "Brawler",
	name = "Lariat",
	description = "A wide swinging punch.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "melee",
	isUltimate = false,
	sortOrder = 8,
	color = Color3.fromRGB(220, 80, 40),
	vfx = "melee",
	Execute = function(ctx)
		return AbilityRunner.Call("Melee", ctx)
	end,
}

return Ability
