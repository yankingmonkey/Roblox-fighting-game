--!strict
-- Every combat number lives here. Change a value, stop the playtest, and play again.
-- Ability modules copy the headline damage / cooldown / energy / range for the UI.
-- BALANCE.md explains how the classes compare.

local Types = require(script.Parent.Types)
type AbilityTuning = Types.AbilityTuning

-- Per-ability tuning. The key must match the ability module's id.
local abilities: { [string]: AbilityTuning } = {
	-- Ki Warrior: ranged, steady, aura buff.
	EnergyBolt = { damage = 18, cooldown = 4, energyCost = 12, range = 90, speed = 150, radius = 2.5, knockback = 12 },
	VolleyShot = {
		damage = 8,
		projectiles = 3,
		cooldown = 8,
		energyCost = 18,
		range = 80,
		speed = 130,
		radius = 2,
		spreadDeg = 14,
		knockback = 8,
	},
	PiercingBeam = { damage = 28, cooldown = 10, energyCost = 22, range = 75, knockback = 18 },
	PowerAura = { damage = 0, cooldown = 16, energyCost = 16, range = 0, damageBuff = 1.25, buffDuration = 6 },
	EnergyStep = {
		damage = 12,
		cooldown = 6,
		energyCost = 10,
		range = 8,
		distance = 18,
		width = 5,
		knockback = 10,
		iframe = 0.12,
	},
	NovaSphere = {
		damage = 64,
		cooldown = 42,
		energyCost = 75,
		range = 95,
		speed = 55,
		radius = 3,
		explosiveRadius = 14,
		knockback = 40,
	},

	-- Brawler: melee, super-armor, low range.
	HeavyPunch = { damage = 22, cooldown = 3.5, energyCost = 8, range = 8, width = 6, knockback = 22, superArmor = 0.35 },
	GrabToss = { damage = 16, cooldown = 10, energyCost = 16, range = 7, width = 5, stun = 0.85, knockback = 35 },
	GroundSlam = {
		damage = 20,
		cooldown = 8,
		energyCost = 18,
		range = 0,
		radius = 14,
		knockback = 28,
		slow = 0.65,
		slowDuration = 1.4,
	},
	ShoulderCharge = {
		damage = 18,
		cooldown = 7,
		energyCost = 12,
		range = 6,
		distance = 22,
		width = 6,
		knockback = 30,
		superArmor = 0.3,
	},
	IronBody = {
		damage = 0,
		cooldown = 16,
		energyCost = 20,
		range = 0,
		damageReduction = 0.4,
		superArmor = 4,
		buffDuration = 4,
	},
	CraterDrop = { damage = 58, cooldown = 40, energyCost = 70, range = 0, radius = 18, knockback = 48, superArmor = 0.8 },

	-- Speedster: mobility and multi-hit, lower per-hit damage.
	BurstDash = { damage = 0, cooldown = 2.5, energyCost = 8, range = 0, distance = 30, iframe = 0.15 },
	BlinkStrike = {
		damage = 24,
		cooldown = 5,
		energyCost = 14,
		range = 7,
		distance = 28,
		width = 6,
		knockback = 16,
		iframe = 0.12,
	},
	RapidFlurry = { hitDamage = 7, hits = 6, cooldown = 8, energyCost = 20, range = 7, width = 6, knockback = 6 },
	Afterimage = { damage = 0, cooldown = 12, energyCost = 14, range = 0, iframe = 0.5 },
	SpeedTrap = {
		damage = 14,
		cooldown = 9,
		energyCost = 16,
		range = 0,
		radius = 15,
		slow = 0.5,
		slowDuration = 2,
		knockback = 8,
	},
	TempoBarrage = {
		hitDamage = 10,
		hits = 8,
		cooldown = 40,
		energyCost = 72,
		range = 8,
		width = 7,
		knockback = 12,
	},

	-- Elemental: mixed projectiles, area, slows and a short stun.
	FireBolt = { damage = 20, cooldown = 4.5, energyCost = 14, range = 80, speed = 120, radius = 2.4, knockback = 14 },
	IceShard = {
		damage = 12,
		cooldown = 6,
		energyCost = 14,
		range = 75,
		speed = 140,
		radius = 2,
		slow = 0.55,
		slowDuration = 2.2,
	},
	LightningSpike = {
		damage = 26,
		cooldown = 9,
		energyCost = 20,
		range = 70,
		speed = 200,
		radius = 2,
		stun = 0.4,
		knockback = 10,
	},
	FrostBurst = {
		damage = 16,
		cooldown = 11,
		energyCost = 22,
		range = 0,
		radius = 16,
		slow = 0.45,
		slowDuration = 2.4,
	},
	FlameWave = { damage = 20, cooldown = 8, energyCost = 18, range = 22, width = 14, knockback = 24 },
	StormCage = { damage = 48, cooldown = 44, energyCost = 78, range = 0, radius = 18, stun = 1.05, knockback = 8 },

	-- Ninja: poke, a dodge, a fragile clone, blinks.
	ShurikenFan = {
		damage = 9,
		projectiles = 3,
		cooldown = 4,
		energyCost = 12,
		range = 75,
		speed = 160,
		radius = 1.6,
		spreadDeg = 16,
		knockback = 6,
	},
	LogSwap = { damage = 0, cooldown = 8, energyCost = 14, range = 0, distance = 16, iframe = 0.4, leaveLog = true, dodge = true },
	ShadowClone = { damage = 8, cooldown = 16, energyCost = 26, range = 4.5, cloneLifetime = 8, tickInterval = 1.5, width = 5 },
	SpiralPalm = { damage = 28, cooldown = 6.5, energyCost = 16, range = 8, width = 6, knockback = 36 },
	WallBlink = { damage = 0, cooldown = 4.5, energyCost = 10, range = 0, distance = 26, wall = true },
	CloneRush = {
		damage = 16,
		projectiles = 5,
		cooldown = 42,
		energyCost = 70,
		range = 55,
		speed = 70,
		radius = 3,
		knockback = 18,
	},

	-- Superhero: expensive beams, flight, heavy melee.
	ThermalGaze = {
		damage = 12,
		ticks = 5,
		tickInterval = 0.25,
		cooldown = 7,
		energyCost = 60,
		range = 90,
		knockback = 4,
	},
	Flight = { damage = 0, cooldown = 0.6, energyCost = 0, minEnergy = 8, energyPerSecond = 12, speed = 64, range = 0 },
	PowerPunch = { damage = 26, cooldown = 4.5, energyCost = 12, range = 9, width = 6, knockback = 32 },
	SonicClap = { damage = 16, cooldown = 8, energyCost = 16, range = 0, radius = 18, knockback = 55 },
	DiveBomb = {
		damage = 18,
		airDamage = 36,
		cooldown = 10,
		energyCost = 18,
		range = 0,
		radius = 13,
		heightNeeded = 12,
		knockback = 40,
	},
	HorizonBeam = {
		damage = 8,
		ticks = 10,
		tickInterval = 0.25,
		sweepDegrees = 80,
		cooldown = 45,
		energyCost = 80,
		range = 80,
		knockback = 10,
	},

	-- Extra pool moves. Sidegrades of the originals so the starter loadout stays the baseline.
	KiBurst = { damage = 16, cooldown = 7, energyCost = 16, range = 0, radius = 12, knockback = 18 },
	ChargedShot = { damage = 26, cooldown = 8, energyCost = 20, range = 85, speed = 70, radius = 3, knockback = 16 },
	KiBarrier = { damage = 0, cooldown = 14, energyCost = 16, range = 0, damageReduction = 0.3, buffDuration = 3 },
	DragonWave = { damage = 10, ticks = 8, tickInterval = 0.22, cooldown = 44, energyCost = 78, range = 80, knockback = 8 },

	Uppercut = { damage = 18, cooldown = 6, energyCost = 12, range = 7, width = 5, stun = 0.4, knockback = 32 },
	Lariat = { damage = 20, cooldown = 7, energyCost = 14, range = 9, width = 10, knockback = 24 },
	WarCry = { damage = 8, cooldown = 12, energyCost = 18, range = 0, radius = 16, slow = 0.7, slowDuration = 2, knockback = 10 },
	QuakeLine = { damage = 62, cooldown = 42, energyCost = 72, range = 28, width = 16, knockback = 36 },

	SparkKick = { damage = 18, cooldown = 4.5, energyCost = 12, range = 8, width = 6, knockback = 14 },
	ZipUpper = { damage = 14, cooldown = 6, energyCost = 12, range = 6, distance = 20, width = 5, knockback = 18, iframe = 0.1 },
	StaticField = { damage = 12, cooldown = 10, energyCost = 18, range = 0, radius = 14, stun = 0.25, knockback = 8 },
	StormRun = { damage = 70, cooldown = 40, energyCost = 70, range = 6, distance = 40, width = 7, knockback = 30, iframe = 0.12 },

	EmberBurst = { damage = 18, cooldown = 7, energyCost = 16, range = 0, radius = 12, knockback = 16 },
	HailVolley = {
		damage = 6,
		projectiles = 4,
		cooldown = 8,
		energyCost = 18,
		range = 70,
		speed = 130,
		radius = 1.8,
		spreadDeg = 18,
		slow = 0.6,
		slowDuration = 1.6,
	},
	GalePush = { damage = 10, cooldown = 9, energyCost = 16, range = 0, radius = 16, knockback = 60 },
	InfernoColumn = { damage = 66, cooldown = 44, energyCost = 76, range = 0, radius = 16, knockback = 28 },

	SmokeVeil = { damage = 6, cooldown = 11, energyCost = 16, range = 0, radius = 13, iframe = 0.35, slow = 0.6, slowDuration = 1.5 },
	NeedleToss = { damage = 14, cooldown = 3.5, energyCost = 8, range = 75, speed = 200, radius = 1.2, knockback = 4 },
	RisingKick = { damage = 20, cooldown = 6, energyCost = 14, range = 8, width = 5, knockback = 28 },
	ThousandStars = {
		damage = 8,
		projectiles = 8,
		cooldown = 42,
		energyCost = 72,
		range = 70,
		speed = 150,
		radius = 1.5,
		spreadDeg = 28,
		knockback = 8,
	},

	HeatPulse = { damage = 22, cooldown = 5, energyCost = 24, range = 70, knockback = 6 },
	HeroSlam = { damage = 22, cooldown = 8, energyCost = 16, range = 0, radius = 12, knockback = 30 },
	ShockwaveLeap = { damage = 16, cooldown = 7, energyCost = 14, range = 6, distance = 18, width = 6, knockback = 26 },
	SolarFlare = { damage = 70, cooldown = 46, energyCost = 80, range = 0, radius = 20, knockback = 34 },
}


local Balance = {
	-- A fresh character is set to this health when OverrideHealth is true.
	-- Delete that line in EnergyService if your game already sets health.
	PlayerHealth = 100,
	OverrideHealth = true,

	MaxEnergy = 100,
	-- Per second. In combat is slower so dumping a whole bar matters.
	RegenOutOfCombat = 12,
	RegenInCombat = 5,
	ResetEnergyOnSpawn = true,

	-- Blocked hits deal this fraction of the damage (0.35 = 35%).
	BlockDamageMultiplier = 0.35,
	-- Walk speed while holding block, as a fraction of BaseWalkSpeed.
	BlockMoveMultiplier = 0.55,
	-- Set true if holding block should also stop abilities.
	BlockPreventsCasting = false,

	-- Damage or an ability cast keeps you "in combat" this many seconds.
	-- Class changes are rejected while the timer is running.
	CombatTagSeconds = 8,

	-- Hard caps so a buggy client cannot flood the server.
	MinCastGap = 0.15,
	MaxCastsPerSecond = 8,

	-- A bit quicker than the default avatar so a fight doesn't feel like a walk.
	BaseWalkSpeed = 18,
	BaseJumpPower = 55,

	-- Basic 4-hit string (mouse / Attack). Melee filler. It spends a little energy
	-- so it cannot replace a class kit. Finisher is the 4th hit.
	BlockStopsBasics = true,
	M1 = {
		damages = { 3, 4, 4, 8 },
		energies = { 3, 3, 3, 4 },
		gap = 0.34,
		reset = 0.95,
		range = 6.5,
		width = 5,
		knockbacks = { 6, 8, 10, 26 },
	},
	-- Shift dash. Shorter than Speedster Burst Dash so that class stays the mobile one.
	CombatDash = {
		distance = 14,
		cooldown = 2.8,
		energy = 10,
		iframe = 0.08,
	},

	-- Tap R (starter control). A real parry system can set ParryWindow itself.
	ParryWindow = 0.18,
	ParryStun = 0.6,
	ParryCooldown = 1.2,

	-- Flight from the Superhero kit.
	-- Empty energy forces a landing. Any damaging hit (or a stun) also knocks
	-- you out of the air. Super-armor ignores the knockdown.
	FlightEmptyStun = 0.7,
	FlightKnockdownStun = 0.35,

	-- Set true to also block loadout edits during combat.
	LoadoutRequiresPeace = false,

	-- Iron Body and similar buffs cannot reduce damage past this fraction.
	MaxDamageReduction = 0.75,

	Abilities = abilities,
}

return Balance
