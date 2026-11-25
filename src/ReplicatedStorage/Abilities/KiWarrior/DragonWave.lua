-- Dragon Wave
-- Ultimate. A swirling beam, 10 damage a tick. Blocking cuts it. A stun ends it.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under DragonWave.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.DragonWave

local Ability = {
	id = "DragonWave",
	classId = "KiWarrior",
	name = "Dragon Wave",
	description = "Ultimate. A swirling beam, 10 damage a tick. Blocking cuts it. A stun ends it.",
	icon = "",
	animationId = "",
	damage = (stats.damage or 0) * (stats.ticks or 1),
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "beam",
	isUltimate = true,
	sortOrder = 21,
	color = Color3.fromRGB(200, 230, 255),
	vfx = "channelBeam",
	Execute = function(ctx)
		return AbilityRunner.Call("ChannelBeam", ctx)
	end,
}

return Ability
