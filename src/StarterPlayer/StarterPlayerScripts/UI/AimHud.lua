--!strict
-- Crosshair, and a ring on the ground where a placed area would land.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local AimRules = require(game:GetService("ReplicatedStorage").FightingClasses.Shared.AimRules)
local UiKit = require(script.Parent.UiKit)

local AimHud = {}

function AimHud.Mount(gui: ScreenGui, menusOpen: () -> boolean, shiftLock: () -> boolean)
	local player = Players.LocalPlayer
	local cross = Instance.new("Frame")
	cross.Name = "Crosshair"
	cross.AnchorPoint = Vector2.new(0.5, 0.5)
	cross.Position = UDim2.fromScale(0.5, 0.5)
	cross.Size = UDim2.fromOffset(18, 18)
	cross.BackgroundTransparency = 1
	cross.Parent = gui
	for _, spec in { { 1, 0.15, 0.5, 0 }, { 0.15, 1, 0, 0.5 } } do
		local line = Instance.new("Frame")
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Position = UDim2.fromScale(0.5, 0.5)
		line.Size = UDim2.fromScale(spec[1], spec[2])
		line.BackgroundColor3 = Color3.new(1, 1, 1)
		line.BackgroundTransparency = 0.25
		line.BorderSizePixel = 0
		line.Parent = cross
		UiKit.Corner(line, 2)
	end

	local ring = Instance.new("Part")
	ring.Name = "AimRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.15, 8, 8)
	ring.Color = Color3.fromRGB(255, 255, 255)
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.45
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Parent = workspace
	ring.CFrame = CFrame.new(0, -50, 0) * CFrame.Angles(0, 0, math.rad(90))

	RunService.RenderStepped:Connect(function()
		local hide = menusOpen()
		cross.Visible = not hide
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local camera = workspace.CurrentCamera
		if hide or not root or not root:IsA("BasePart") or not camera then
			ring.Transparency = 1
			return
		end
		local origin = root.Position + Vector3.new(0, 1.6, 0)
		local aim = camera.CFrame.LookVector
		if not shiftLock() then
			local hit = player:GetMouse().Hit.Position
			local offset = hit - origin
			if offset.Magnitude > 0.2 then
				aim = offset.Unit
			end
		end
		local flat = Vector3.new(aim.X, 0, aim.Z)
		if flat.Magnitude < 0.05 then
			flat = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		end
		flat = flat.Unit * math.min(AimRules.PlaceRange, 28)
		local spot = root.Position + flat
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { character }
		local ground = workspace:Raycast(spot + Vector3.new(0, 12, 0), Vector3.new(0, -40, 0), params)
		local at = if ground then ground.Position else spot
		ring.Transparency = 0.55
		ring.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90))
	end)
end

return AimHud
