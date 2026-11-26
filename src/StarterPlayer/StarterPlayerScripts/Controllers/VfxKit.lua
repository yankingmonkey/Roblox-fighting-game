--!strict
-- Building blocks for the class effects. Built-in Roblox textures only.
-- Parts live in a local folder, so they are not duplicated by the server.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local VfxKit = {}

VfxKit.Texture = {
	Spark = "rbxasset://textures/particles/sparkles_main.tex",
	Smoke = "rbxasset://textures/particles/smoke_main.dds",
	Fire = "rbxasset://textures/particles/fire_main.dds",
}

local shakeLeft = 0

function VfxKit.Folder(): Folder
	local existing = workspace:FindFirstChild("FightingClassVfx")
	if existing and existing:IsA("Folder") then
		return existing
	end
	local created = Instance.new("Folder")
	created.Name = "FightingClassVfx"
	created.Parent = workspace
	return created
end

function VfxKit.Part(size: Vector3, color: Color3, cframe: CFrame, life: number): Part
	local part = Instance.new("Part")
	part.Name = "AbilityVfx"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Size = size
	part.CFrame = cframe
	part.Parent = VfxKit.Folder()
	Debris:AddItem(part, life)
	return part
end

function VfxKit.Light(parent: BasePart, color: Color3, range: number, brightness: number)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Parent = parent
end

function VfxKit.Emit(parent: BasePart, texture: string, color: Color3, rate: number, life: NumberRange, speed: NumberRange, size: number)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = texture
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.7
	emitter.Lifetime = life
	emitter.Speed = speed
	emitter.Rate = rate
	emitter.Size = NumberSequence.new(size)
	emitter.RotSpeed = NumberRange.new(-80, 80)
	emitter.SpreadAngle = Vector2.new(35, 35)
	emitter.Parent = parent
	return emitter
end

function VfxKit.Burst(position: Vector3, color: Color3, texture: string, count: number, life: number)
	local host = VfxKit.Part(Vector3.new(0.4, 0.4, 0.4), color, CFrame.new(position), life)
	host.Transparency = 1
	local emitter = VfxKit.Emit(host, texture, color, 0, NumberRange.new(0.15, 0.4), NumberRange.new(6, 16), 0.6)
	emitter:Emit(count)
	VfxKit.Light(host, color, 10, 2)
	return host
end

function VfxKit.Segment(a: Vector3, b: Vector3, color: Color3, thickness: number, life: number, transparency: number): Part
	local delta = b - a
	local distance = math.max(delta.Magnitude, 0.05)
	local part = VfxKit.Part(Vector3.new(thickness, thickness, distance), color, CFrame.lookAt(a, b) * CFrame.new(0, 0, -distance / 2), life)
	part.Transparency = transparency
	local attachment0 = Instance.new("Attachment")
	attachment0.Position = Vector3.new(0, 0, distance / 2)
	attachment0.Parent = part
	local attachment1 = Instance.new("Attachment")
	attachment1.Position = Vector3.new(0, 0, -distance / 2)
	attachment1.Parent = part
	local beam = Instance.new("Beam")
	beam.Attachment0 = attachment0
	beam.Attachment1 = attachment1
	beam.Color = ColorSequence.new(color)
	beam.Width0 = thickness * 2.2
	beam.Width1 = thickness * 0.4
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.Transparency = NumberSequence.new(transparency)
	beam.Texture = VfxKit.Texture.Spark
	beam.TextureSpeed = 3
	beam.CurveSize0 = thickness * 2
	beam.CurveSize1 = -thickness * 2
	beam.Parent = part
	return part
end

function VfxKit.Bolt(from: Vector3, to: Vector3, color: Color3, life: number, jagged: number)
	local points = { from }
	local span = to - from
	local length = math.max(span.Magnitude, 0.2)
	local forward = span.Unit
	local side = forward:Cross(Vector3.yAxis)
	if side.Magnitude < 0.2 then
		side = forward:Cross(Vector3.xAxis)
	end
	side = side.Unit
	local steps = math.clamp(math.floor(length / 4), 4, 14)
	for index = 1, steps - 1 do
		local along = from + forward * (length * index / steps)
		local sway = (math.noise(index * 0.7, time()) - 0.5) * 2 * jagged
		local lift = (math.noise(index * 0.4, 4) - 0.5) * jagged
		table.insert(points, along + side * sway + Vector3.yAxis * lift)
	end
	table.insert(points, to)
	for index = 1, #points - 1 do
		local thickness = if index == 1 then 0.35 else 0.18
		local segment = VfxKit.Segment(points[index], points[index + 1], color, thickness, life, 0.05)
		if index % 2 == 0 then
			VfxKit.Light(segment, color, 8, 3)
		end
	end
	VfxKit.Burst(to, color, VfxKit.Texture.Spark, 12, life)
end

function VfxKit.SwirlBeam(from: Vector3, to: Vector3, color: Color3, life: number)
	local core = VfxKit.Segment(from, to, color, 0.45, life, 0.05)
	local glow = color:Lerp(Color3.new(1, 1, 1), 0.35)
	VfxKit.Segment(from, to, glow, 1.3, life, 0.55)
	VfxKit.Light(core, color, 16, 3)
	VfxKit.Emit(core, VfxKit.Texture.Spark, color, 40, NumberRange.new(0.1, 0.25), NumberRange.new(1, 4), 0.35)
	local mid = (from + to) / 2
	local orb = VfxKit.Part(Vector3.new(1.4, 1.4, 1.4), color, CFrame.new(mid), life)
	orb.Shape = Enum.PartType.Ball
	orb.Transparency = 0.25
	TweenService:Create(orb, TweenInfo.new(life, Enum.EasingStyle.Quad), {
		Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1,
	}):Play()
end

function VfxKit.Orb(position: Vector3, color: Color3, radius: number, life: number): Part
	local orb = VfxKit.Part(Vector3.new(radius, radius, radius), color, CFrame.new(position), life + 0.2)
	orb.Shape = Enum.PartType.Ball
	orb.Transparency = 0.15
	VfxKit.Light(orb, color, radius * 6, 2.5)
	VfxKit.Emit(orb, VfxKit.Texture.Spark, color, 30, NumberRange.new(0.15, 0.35), NumberRange.new(1, 4), 0.4)
	return orb
end

function VfxKit.Shockwave(position: Vector3, color: Color3, radius: number, life: number)
	local ring = VfxKit.Part(Vector3.new(2, 0.25, 2), color, CFrame.new(position), life)
	ring.Transparency = 0.2
	TweenService:Create(ring, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(radius * 2, 0.15, radius * 2),
		Transparency = 1,
	}):Play()
	local dust = VfxKit.Part(Vector3.new(1, 1, 1), color, CFrame.new(position), life)
	dust.Transparency = 1
	local emitter = VfxKit.Emit(dust, VfxKit.Texture.Smoke, color:Lerp(Color3.new(0.4, 0.3, 0.2), 0.5), 0, NumberRange.new(0.3, 0.7), NumberRange.new(4, 12), 1.4)
	emitter.Drag = 3
	emitter:Emit(18)
end

function VfxKit.Cracks(position: Vector3, color: Color3, radius: number, life: number)
	for index = 1, 6 do
		local angle = math.rad((index - 1) * 60 + math.random(-8, 8))
		local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local endPos = position + dir * radius
		local crack = VfxKit.Segment(position, endPos, color:Lerp(Color3.new(0.15, 0.1, 0.08), 0.4), 0.15, life, 0.2)
		crack.Material = Enum.Material.Slate
	end
end

function VfxKit.Shuriken(position: Vector3, direction: Vector3, color: Color3, life: number): Part
	local part = VfxKit.Part(Vector3.new(1.6, 0.15, 1.6), color, CFrame.lookAt(position, position + direction), life)
	part.Material = Enum.Material.Metal
	for index = 0, 3 do
		local wedge = Instance.new("WedgePart")
		wedge.Size = Vector3.new(0.16, 0.7, 1.1)
		wedge.Color = color
		wedge.Material = Enum.Material.Neon
		wedge.Anchored = false
		wedge.CanCollide = false
		wedge.CanQuery = false
		wedge.CFrame = part.CFrame * CFrame.Angles(0, math.rad(90 * index), 0) * CFrame.new(0, 0, -0.7)
		wedge.Parent = part
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = part
		weld.Part1 = wedge
		weld.Parent = wedge
	end
	local attachment0 = Instance.new("Attachment")
	attachment0.Parent = part
	local attachment1 = Instance.new("Attachment")
	attachment1.Position = Vector3.new(0, 0, -0.6)
	attachment1.Parent = part
	local trail = Instance.new("Trail")
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Color = ColorSequence.new(color)
	trail.Lifetime = 0.2
	trail.LightEmission = 1
	trail.WidthScale = NumberSequence.new(0.4)
	trail.Parent = part
	return part
end

function VfxKit.Afterimage(character: Model, color: Color3)
	local ghost = Instance.new("Model")
	ghost.Name = "Afterimage"
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.Transparency < 0.9 and descendant.Name ~= "HumanoidRootPart" then
			local copy = descendant:Clone()
			for _, child in copy:GetChildren() do
				if not child:IsA("DataModelMesh") and not child:IsA("SpecialMesh") then
					child:Destroy()
				end
			end
			copy.Anchored = true
			copy.CanCollide = false
			copy.CanQuery = false
			copy.CanTouch = false
			copy.Massless = true
			copy.Color = color
			copy.Material = Enum.Material.Neon
			copy.Transparency = 0.4
			copy.CFrame = descendant.CFrame
			copy.Parent = ghost
		end
	end
	ghost.Parent = VfxKit.Folder()
	Debris:AddItem(ghost, 0.35)
	task.delay(0.05, function()
		for _, part in ghost:GetDescendants() do
			if part:IsA("BasePart") then
				TweenService:Create(part, TweenInfo.new(0.28), { Transparency = 1 }):Play()
			end
		end
	end)
end

local shakeEnabled = true

function VfxKit.SetShakeEnabled(enabled: boolean)
	shakeEnabled = enabled
	if not enabled then
		shakeLeft = 0
	end
end

function VfxKit.Shake(amount: number)
	if not shakeEnabled then
		return
	end
	shakeLeft = math.clamp(shakeLeft + amount, 0, 1.6)
end

function VfxKit.StartShake()
	local player = Players.LocalPlayer
	RunService.RenderStepped:Connect(function(dt)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end
		if shakeLeft <= 0 then
			if humanoid.CameraOffset.Magnitude > 0.01 then
				humanoid.CameraOffset = Vector3.zero
			end
			return
		end
		shakeLeft = math.max(0, shakeLeft - dt * 3.5)
		humanoid.CameraOffset = Vector3.new((math.random() - 0.5) * shakeLeft, (math.random() - 0.5) * shakeLeft, 0)
	end)
end

return VfxKit
