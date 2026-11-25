-- Smoke Veil
-- Vanish in smoke. Brief invincibility and a slow around you.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under SmokeVeil.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.SmokeVeil

local Ability = {
	id = "SmokeVeil",
	classId = "Ninja",
	name = "Smoke Veil",
	description = "Vanish in smoke. Brief invincibility and a slow around you.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "aoe",
	isUltimate = false,
	sortOrder = 7,
	color = Color3.fromRGB(160, 110, 230),
	vfx = "smoke",
	Execute = function(ctx)
		AbilityRunner.Call("Buff", ctx)
		AbilityRunner.Call("Aoe", ctx)
	end,
}

return Ability
