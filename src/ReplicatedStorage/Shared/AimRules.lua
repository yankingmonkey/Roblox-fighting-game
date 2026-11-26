--!strict
-- Which moves use the mouse.
-- "ground" places the area on the floor under the cursor, inside PlaceRange.
-- "cursor" aims the shot at the cursor. Dashes and self buffs stay "self".
-- Projectiles still fly over time, so you have to lead a moving target.

local GROUND: { [string]: boolean } = {
	GroundSlam = true,
	KiBurst = true,
	EmberBurst = true,
	FrostBurst = true,
	HeroSlam = true,
	InfernoColumn = true,
	StormCage = true,
	SolarFlare = true,
	StaticField = true,
	WarCry = true,
}

local AimRules = {
	PlaceRange = 36,
	MaxAimDistance = 180,
}

function AimRules.Style(abilityId: string, kind: string, vfx: string): string
	if GROUND[abilityId] then
		return "ground"
	end
	if kind == "movement" or vfx == "dash" or vfx == "blink" or vfx == "flight" or vfx == "buff" then
		return "self"
	end
	if kind == "projectile" or kind == "beam" or vfx == "channelBeam" or vfx == "cone" or vfx == "melee" or vfx == "flurry" then
		return "cursor"
	end
	return "self"
end

function AimRules.IsGround(abilityId: string): boolean
	return GROUND[abilityId] == true
end

return AimRules
