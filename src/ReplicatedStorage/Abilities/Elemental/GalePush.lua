-- Gale Push
-- A gust that barely hurts and knocks people back hard.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under GalePush.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.GalePush

local Ability = {
	id = "GalePush",
	classId = "Elemental",
	name = "Gale Push",
	description = "A gust that barely hurts and knocks people back hard.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "aoe",
	isUltimate = false,
	sortOrder = 9,
	color = Color3.fromRGB(190, 230, 220),
	vfx = "aoe",
	Execute = function(ctx)
		return AbilityRunner.Call("Aoe", ctx)
	end,
}

return Ability
