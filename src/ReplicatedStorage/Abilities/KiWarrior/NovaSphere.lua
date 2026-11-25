-- Nova Sphere
-- Ultimate. A slow heavy sphere that bursts on impact.
-- Tune damage, cooldown, energy, and range in Shared/Balance.lua under NovaSphere.
-- animationId: paste an animation here when you have one, for example "rbxassetid://123".
-- Leave it as "" and the move still works. The client plays it when the id is set.

local root = script.Parent.Parent.Parent
local Balance = require(root.Shared.Balance)
local AbilityRunner = require(root.Shared.AbilityRunner)

local stats = Balance.Abilities.NovaSphere

local Ability = {
	id = "NovaSphere",
	classId = "KiWarrior",
	name = "Nova Sphere",
	description = "Ultimate. A slow heavy sphere that bursts on impact.",
	icon = "",
	animationId = "",
	damage = stats.damage or 0,
	cooldown = stats.cooldown or 0,
	energyCost = stats.energyCost or 0,
	range = stats.range or 0,
	kind = "projectile",
	isUltimate = true,
	sortOrder = 20,
	color = Color3.fromRGB(190, 230, 255),
	vfx = "projectile",
	Execute = function(ctx)
		-- Server only. The client loads this module for the name and the numbers.
		return AbilityRunner.Call("Projectile", ctx)
	end,
}

return Ability
