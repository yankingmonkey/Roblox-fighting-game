--!strict
-- Rooftop arena options. The builder only adds a folder under
-- Workspace.FightingClasses. It does not delete your baseplate or spawns.
-- Set UseRoofSpawn to make new characters appear on the roof.
-- Set DisableOtherSpawns only if an old SpawnLocation is still winning.

local MapConfig = {
	ApplyLighting = true,
	UseRoofSpawn = true,
	DisableOtherSpawns = false,
	RoofCenter = Vector3.new(0, 220, 0),
	RoofSize = Vector3.new(150, 4, 150),
	FallY = 170,
}

return MapConfig
