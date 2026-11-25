-- Heat Pulse
-- A cheaper, shorter eye beam. Blocking cuts it.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under HeatPulse.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.HeatPulse

local Ability = {
	id = "HeatPulse",
	classId = "Superhero",
	name = "Heat Pulse",
	description = "A cheaper, shorter eye beam. Blocking cuts it.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "beam",
	isUltimate = false,
	sortOrder = 7,
	color = Color3.fromRGB(255, 70, 80),
	vfx = "beam",
	Execute = function(ctx)
		return AbilityRunner.Call("Beam", ctx)
	end,
}

return Ability
