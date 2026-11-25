--!strict
-- Class names, blurbs, and which abilities they own.
-- abilityOrder is the full pool (8 moves + 2 ultimates).
-- defaultLoadout is the starter: slots 1-4 plus the ultimate on Q.
-- Players can put any non-ultimate in slots 1-4 and any ultimate on Q.

local Types = require(script.Parent.Types)
type ClassInfo = Types.ClassInfo

local list: { ClassInfo } = {
	{
		id = "KiWarrior",
		name = "Ki Warrior",
		role = "Ranged",
		summary = "Energy blasts, a piercing beam, and an aura that powers up your hits.",
		color = Color3.fromRGB(70, 160, 255),
		abilityOrder = {
			"EnergyBolt",
			"VolleyShot",
			"PiercingBeam",
			"PowerAura",
			"EnergyStep",
			"KiBurst",
			"ChargedShot",
			"KiBarrier",
			"NovaSphere",
			"DragonWave",
		},
		defaultLoadout = { "EnergyBolt", "PiercingBeam", "EnergyStep", "PowerAura", "NovaSphere" },
	},
	{
		id = "Brawler",
		name = "Brawler",
		role = "Tank",
		summary = "Heavy punches, a grab, ground slams, and super-armor.",
		color = Color3.fromRGB(220, 90, 50),
		abilityOrder = {
			"HeavyPunch",
			"GrabToss",
			"GroundSlam",
			"ShoulderCharge",
			"IronBody",
			"Uppercut",
			"Lariat",
			"WarCry",
			"CraterDrop",
			"QuakeLine",
		},
		defaultLoadout = { "HeavyPunch", "GrabToss", "GroundSlam", "ShoulderCharge", "CraterDrop" },
	},
	{
		id = "Speedster",
		name = "Speedster",
		role = "Mobility",
		summary = "Dashes, a teleport strike, and rapid multi-hits.",
		color = Color3.fromRGB(240, 200, 50),
		abilityOrder = {
			"BurstDash",
			"BlinkStrike",
			"RapidFlurry",
			"Afterimage",
			"SpeedTrap",
			"SparkKick",
			"ZipUpper",
			"StaticField",
			"TempoBarrage",
			"StormRun",
		},
		defaultLoadout = { "BurstDash", "BlinkStrike", "RapidFlurry", "Afterimage", "TempoBarrage" },
	},
	{
		id = "Elemental",
		name = "Elemental",
		role = "Control",
		summary = "Fire, ice, and lightning. Projectiles, areas, slows, and a stun.",
		color = Color3.fromRGB(70, 200, 170),
		abilityOrder = {
			"FireBolt",
			"IceShard",
			"LightningSpike",
			"FrostBurst",
			"FlameWave",
			"EmberBurst",
			"HailVolley",
			"GalePush",
			"StormCage",
			"InfernoColumn",
		},
		defaultLoadout = { "FireBolt", "IceShard", "LightningSpike", "FlameWave", "StormCage" },
	},
	{
		id = "Ninja",
		name = "Ninja",
		role = "Trickster",
		summary = "Throwing stars, a log dodge, a fragile clone, and blinks.",
		color = Color3.fromRGB(170, 90, 255),
		abilityOrder = {
			"ShurikenFan",
			"LogSwap",
			"ShadowClone",
			"SpiralPalm",
			"WallBlink",
			"SmokeVeil",
			"NeedleToss",
			"RisingKick",
			"CloneRush",
			"ThousandStars",
		},
		defaultLoadout = { "ShurikenFan", "LogSwap", "ShadowClone", "SpiralPalm", "CloneRush" },
	},
	{
		id = "Superhero",
		name = "Superhero",
		role = "Burst",
		summary = "Eye beams, flight, and heavy hits. Strong burst, hungry for energy.",
		color = Color3.fromRGB(220, 55, 75),
		abilityOrder = {
			"ThermalGaze",
			"Flight",
			"PowerPunch",
			"SonicClap",
			"DiveBomb",
			"HeatPulse",
			"HeroSlam",
			"ShockwaveLeap",
			"HorizonBeam",
			"SolarFlare",
		},
		defaultLoadout = { "ThermalGaze", "Flight", "PowerPunch", "DiveBomb", "HorizonBeam" },
	},
}

local byId: { [string]: ClassInfo } = {}
for _, info in list do
	byId[info.id] = info
end

local Classes = {
	List = list,
	ById = byId,
}

return Classes
