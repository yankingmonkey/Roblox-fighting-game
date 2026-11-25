-- Ki Barrier
-- A short barrier. You take 30% less damage for 3 seconds.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under KiBarrier.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.KiBarrier

local Ability = {
	id = "KiBarrier",
	classId = "KiWarrior",
	name = "Ki Barrier",
	description = "A short barrier. You take 30% less damage for 3 seconds.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "buff",
	isUltimate = false,
	sortOrder = 9,
	color = Color3.fromRGB(180, 220, 255),
	vfx = "buff",
	Execute = function(ctx)
		return AbilityRunner.Call("Buff", ctx)
	end,
}

return Ability
