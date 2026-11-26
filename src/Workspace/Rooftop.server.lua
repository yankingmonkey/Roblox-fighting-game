--!strict
-- Builds a boxed rooftop arena and a city around it. Safe to run in a place
-- that already has a map: everything lives under this script's parent folder.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local MapConfig = require(script.Parent.MapConfig)

local arena = script.Parent:FindFirstChild("RooftopArena")
if arena then
	arena:Destroy()
end
arena = Instance.new("Folder")
arena.Name = "RooftopArena"
arena.Parent = script.Parent

local center = MapConfig.RoofCenter
local size = MapConfig.RoofSize

local function make(name: string, partSize: Vector3, cframe: CFrame, color: Color3, material: Enum.Material): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = partSize
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = arena
	return part
end

local roof = make(
	"Roof",
	size,
	CFrame.new(center),
	Color3.fromRGB(58, 62, 72),
	Enum.Material.Concrete
)

local function wall(name: string, partSize: Vector3, offset: Vector3, glass: boolean)
	local part = make(name, partSize, CFrame.new(center + offset), if glass then Color3.fromRGB(170, 210, 230) else Color3.fromRGB(255, 255, 255), if glass then Enum.Material.Glass else Enum.Material.SmoothPlastic)
	if glass then
		part.Transparency = 0.45
	else
		part.Transparency = 1
		part.CanQuery = false
	end
	return part
end

local halfX = size.X / 2
local halfZ = size.Z / 2
wall("GlassNorth", Vector3.new(size.X, 5, 1), Vector3.new(0, 4, -halfZ), true)
wall("GlassSouth", Vector3.new(size.X, 5, 1), Vector3.new(0, 4, halfZ), true)
wall("GlassEast", Vector3.new(1, 5, size.Z), Vector3.new(halfX, 4, 0), true)
wall("GlassWest", Vector3.new(1, 5, size.Z), Vector3.new(-halfX, 4, 0), true)
wall("BoundNorth", Vector3.new(size.X + 4, 28, 1), Vector3.new(0, 16, -halfZ - 1), false)
wall("BoundSouth", Vector3.new(size.X + 4, 28, 1), Vector3.new(0, 16, halfZ + 1), false)
wall("BoundEast", Vector3.new(1, 28, size.Z + 4), Vector3.new(halfX + 1, 16, 0), false)
wall("BoundWest", Vector3.new(1, 28, size.Z + 4), Vector3.new(-halfX - 1, 16, 0), false)

local function ring(radius: number, count: number, thickness: number, color: Color3)
	for index = 1, count do
		local angle = (index / count) * math.pi * 2
		local pos = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		make(
			"Helipad",
			Vector3.new(thickness, 0.2, thickness * 2.2),
			CFrame.new(center + Vector3.new(0, size.Y / 2 + 0.15, 0) + pos) * CFrame.Angles(0, -angle, 0),
			color,
			Enum.Material.Neon
		)
	end
end
ring(18, 28, 1.2, Color3.fromRGB(240, 190, 40))
make("HelipadH", Vector3.new(1.2, 0.25, 10), CFrame.new(center + Vector3.new(0, size.Y / 2 + 0.2, 0)), Color3.fromRGB(240, 190, 40), Enum.Material.Neon)
make("HelipadBar", Vector3.new(7, 0.25, 1.2), CFrame.new(center + Vector3.new(0, size.Y / 2 + 0.2, -4.4)), Color3.fromRGB(240, 190, 40), Enum.Material.Neon)
make("HelipadBar2", Vector3.new(7, 0.25, 1.2), CFrame.new(center + Vector3.new(0, size.Y / 2 + 0.2, 4.4)), Color3.fromRGB(240, 190, 40), Enum.Material.Neon)

local function box(name: string, partSize: Vector3, localPos: Vector3, color: Color3, material: Enum.Material): Part
	return make(name, partSize, CFrame.new(center + localPos + Vector3.new(0, size.Y / 2 + partSize.Y / 2, 0)), color, material)
end

box("AC1", Vector3.new(8, 5, 6), Vector3.new(-50, 0, -48), Color3.fromRGB(70, 74, 82), Enum.Material.Metal)
box("AC2", Vector3.new(6, 4, 5), Vector3.new(-40, 0, -50), Color3.fromRGB(80, 84, 92), Enum.Material.Metal)
box("AC3", Vector3.new(7, 4, 7), Vector3.new(52, 0, 40), Color3.fromRGB(66, 70, 78), Enum.Material.Metal)
make("Fan", Vector3.new(3, 0.4, 3), CFrame.new(center + Vector3.new(-50, size.Y / 2 + 5.4, -48)), Color3.fromRGB(40, 42, 48), Enum.Material.Metal)

local tower = box("WaterTower", Vector3.new(10, 8, 10), Vector3.new(48, 10, -46), Color3.fromRGB(90, 40, 40), Enum.Material.Metal)
tower.Shape = Enum.PartType.Cylinder
tower.CFrame = tower.CFrame * CFrame.Angles(0, 0, math.rad(90))
box("TowerLeg", Vector3.new(1, 10, 1), Vector3.new(44, 0, -50), Color3.fromRGB(50, 52, 58), Enum.Material.Metal)
box("TowerLeg2", Vector3.new(1, 10, 1), Vector3.new(52, 0, -42), Color3.fromRGB(50, 52, 58), Enum.Material.Metal)

local mast = box("Antenna", Vector3.new(0.6, 22, 0.6), Vector3.new(-55, 0, 50), Color3.fromRGB(40, 42, 48), Enum.Material.Metal)
make("Dish", Vector3.new(4, 0.4, 4), mast.CFrame * CFrame.new(0, 6, 1.5) * CFrame.Angles(math.rad(70), 0, 0), Color3.fromRGB(200, 200, 210), Enum.Material.Metal)

local function sign(text: string, localPos: Vector3, color: Color3)
	local board = box("Sign", Vector3.new(14, 4, 0.6), localPos, Color3.fromRGB(12, 12, 16), Enum.Material.SmoothPlastic)
	local face = Instance.new("SurfaceGui")
	face.Face = Enum.NormalId.Front
	face.Parent = board
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = face
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 18
	light.Brightness = 2
	light.Parent = board
end
sign("ROOF", Vector3.new(0, 6, -halfZ + 2), Color3.fromRGB(80, 180, 255))
sign("NORTH", Vector3.new(-halfX + 8, 6, 20), Color3.fromRGB(255, 90, 120))

local street = make("Streets", Vector3.new(900, 2, 900), CFrame.new(center.X, 0, center.Z), Color3.fromRGB(28, 30, 34), Enum.Material.Asphalt)
for index = -4, 4 do
	make("Lane", Vector3.new(2, 0.2, 70), CFrame.new(center.X + index * 28, 1.2, center.Z), Color3.fromRGB(210, 180, 60), Enum.Material.Neon)
end

local rng = Random.new(7)
for index = 1, 18 do
	local angle = (index / 18) * math.pi * 2 + 0.2
	local radius = rng:NextNumber(210, 340)
	local height = rng:NextNumber(50, 190)
	local footprint = rng:NextNumber(28, 48)
	local pos = Vector3.new(center.X + math.cos(angle) * radius, height / 2, center.Z + math.sin(angle) * radius)
	local building = make("Tower", Vector3.new(footprint, height, footprint), CFrame.new(pos), Color3.fromRGB(rng:NextInteger(32, 58), rng:NextInteger(34, 62), rng:NextInteger(48, 78)), Enum.Material.Concrete)
	for window = 1, 6 do
		local y = -height / 2 + 8 + window * (height / 8)
		local glow = make("Window", Vector3.new(footprint * 0.7, 1.2, 0.4), building.CFrame * CFrame.new(0, y, -footprint / 2), Color3.fromRGB(255, 196, 120), Enum.Material.Neon)
		glow.Transparency = if rng:NextNumber() > 0.25 then 0.15 else 0.65
	end
end

local spawn = Instance.new("SpawnLocation")
spawn.Name = "RoofSpawn"
spawn.Size = Vector3.new(8, 1, 8)
spawn.Anchored = true
spawn.Neutral = true
spawn.Duration = 0
spawn.Color = Color3.fromRGB(80, 180, 255)
spawn.Material = Enum.Material.Neon
spawn.CFrame = CFrame.new(center + Vector3.new(0, size.Y / 2 + 1, 24))
spawn.Parent = arena

local function claimSpawn(player: Player)
	if MapConfig.UseRoofSpawn then
		player.RespawnLocation = spawn
	end
end

local function lighting()
	if not MapConfig.ApplyLighting then
		return
	end
	Lighting.ClockTime = 18.6
	Lighting.GeographicLatitude = 18
	Lighting.Brightness = 1.5
	Lighting.Ambient = Color3.fromRGB(48, 42, 72)
	Lighting.OutdoorAmbient = Color3.fromRGB(86, 70, 104)
	Lighting.EnvironmentDiffuseScale = 0.45
	Lighting.EnvironmentSpecularScale = 0.55
	local function effect(className: string, name: string): Instance
		local existing = Lighting:FindFirstChild(name)
		if existing then
			return existing
		end
		local created = Instance.new(className)
		created.Name = name
		created.Parent = Lighting
		return created
	end
	local atmosphere = effect("Atmosphere", "FightingAtmosphere") :: Atmosphere
	atmosphere.Density = 0.35
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(190, 150, 130)
	atmosphere.Decay = Color3.fromRGB(80, 70, 120)
	atmosphere.Glare = 0.25
	atmosphere.Haze = 1.6
	local bloom = effect("BloomEffect", "FightingBloom") :: BloomEffect
	bloom.Intensity = 0.55
	bloom.Size = 18
	bloom.Threshold = 0.85
	local color = effect("ColorCorrectionEffect", "FightingColor") :: ColorCorrectionEffect
	color.TintColor = Color3.fromRGB(255, 228, 210)
	color.Contrast = 0.08
	color.Saturation = 0.12
	local rays = effect("SunRaysEffect", "FightingSunRays") :: SunRaysEffect
	rays.Intensity = 0.07
	rays.Spread = 0.6
	effect("Sky", "FightingSky")
end

lighting()
if MapConfig.DisableOtherSpawns then
	for _, child in workspace:GetDescendants() do
		if child:IsA("SpawnLocation") and child ~= spawn then
			child.Enabled = false
		end
	end
end

local falling: { [Player]: boolean } = {}
local function watch(player: Player)
	claimSpawn(player)
	player.CharacterAdded:Connect(function()
		claimSpawn(player)
		falling[player] = false
	end)
end
Players.PlayerAdded:Connect(watch)
for _, player in Players:GetPlayers() do
	watch(player)
end

task.spawn(function()
	while arena.Parent do
		task.wait(0.35)
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 and root.Position.Y < MapConfig.FallY and not falling[player] then
				falling[player] = true
				player:LoadCharacter()
			end
		end
	end
end)

roof.Name = "Roof"
street.Name = "Streets"
