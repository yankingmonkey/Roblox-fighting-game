--!strict
-- Shared shapes. Ability modules and services use these names.

export type AbilityKind = "projectile" | "melee" | "beam" | "buff" | "movement" | "aoe" | "summon"

export type AbilityTuning = {
	damage: number?,
	hitDamage: number?,
	hits: number?,
	airDamage: number?,
	cooldown: number?,
	energyCost: number?,
	minEnergy: number?,
	energyPerSecond: number?,
	range: number?,
	radius: number?,
	explosiveRadius: number?,
	speed: number?,
	distance: number?,
	width: number?,
	projectiles: number?,
	spreadDeg: number?,
	ticks: number?,
	tickInterval: number?,
	sweepDegrees: number?,
	stun: number?,
	slow: number?,
	slowDuration: number?,
	knockback: number?,
	iframe: number?,
	buffDuration: number?,
	damageBuff: number?,
	damageReduction: number?,
	superArmor: number?,
	cloneLifetime: number?,
	heightNeeded: number?,
	leaveLog: boolean?,
	dodge: boolean?,
	wall: boolean?,
}

export type CastContext = {
	player: Player,
	character: Model,
	humanoid: Humanoid,
	root: BasePart,
	ability: AbilityDefinition,
	origin: Vector3,
	direction: Vector3,
	aimPoint: Vector3,
	moveDirection: Vector3,
	slot: number,
	castId: string,
	move: MoveCommand?,
	failReason: string?,
}

export type MoveCommand = {
	kind: string,
	position: Vector3,
	look: Vector3,
}

export type AbilityDefinition = {
	id: string,
	classId: string,
	name: string,
	description: string,
	icon: string,
	animationId: string,
	damage: number,
	cooldown: number,
	energyCost: number,
	range: number,
	kind: AbilityKind,
	isUltimate: boolean,
	sortOrder: number,
	color: Color3,
	vfx: string,
	Execute: (ctx: CastContext) -> boolean?,
}

export type ClassInfo = {
	id: string,
	name: string,
	role: string,
	summary: string,
	color: Color3,
	abilityOrder: { string },
	defaultLoadout: { string },
}

export type OutfitSlot = {
	id: string,
	r: number,
	g: number,
	b: number,
}

export type SaveData = {
	classId: string,
	loadout: { string },
	outfit: { [string]: OutfitSlot },
}

return {}
