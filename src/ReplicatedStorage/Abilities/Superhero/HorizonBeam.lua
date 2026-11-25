-- Horizon Beam
-- Ultimate. A sweeping eye beam, 8 damage a tick. Blocking reduces it. A stun cancels it.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under HorizonBeam.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".
-- Leave it as "" and the move still works. The client plays it when the id is set.

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.HorizonBeam

local Ability = {
	id = "HorizonBeam",
	classId = "Superhero",
	name = "Horizon Beam",
	description = "Ultimate. A sweeping eye beam, 8 damage a tick. Blocking reduces it. A stun cancels it.",
	icon = "",
	animationId = "",
	damage = (stats.damage or 0) * (stats.ticks or 1),
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "beam",
	isUltimate = true,
	sortOrder = 20,
	color = Color3.fromRGB(255, 40, 50),
	vfx = "channelBeam",
	Execute = function(ctx)
		-- Server only. The client loads this module for the name and the numbers.
		return AbilityRunner.Call("ChannelBeam", ctx)
	end,
}

return Ability
