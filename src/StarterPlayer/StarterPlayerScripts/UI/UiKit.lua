--!strict
-- Tiny helpers for building the HUD in code. No imported images.

local UiKit = {}

function UiKit.Corner(parent: Instance, pixels: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, pixels)
	corner.Parent = parent
end

function UiKit.Stroke(parent: Instance, color: Color3, thickness: number)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
end

function UiKit.Padding(parent: Instance, pixels: number)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, pixels)
	padding.PaddingBottom = UDim.new(0, pixels)
	padding.PaddingLeft = UDim.new(0, pixels)
	padding.PaddingRight = UDim.new(0, pixels)
	padding.Parent = parent
end

function UiKit.Label(parent: Instance, text: string): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextColor3 = Color3.fromRGB(235, 240, 255)
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextWrapped = true
	label.Text = text
	label.Parent = parent
	return label
end

function UiKit.Button(parent: Instance, text: string): TextButton
	local button = Instance.new("TextButton")
	button.AutoButtonColor = true
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.fromRGB(240, 244, 255)
	button.TextSize = 16
	button.TextWrapped = true
	button.Text = text
	button.BackgroundColor3 = Color3.fromRGB(24, 28, 42)
	button.BorderSizePixel = 0
	button.Parent = parent
	return button
end

function UiKit.BindScale(gui: ScreenGui)
	local scale = Instance.new("UIScale")
	scale.Name = "ScreenScale"
	scale.Parent = gui

	local function refresh()
		local camera = workspace.CurrentCamera
		local viewport = if camera then camera.ViewportSize else Vector2.new(1280, 720)
		local shortSide = math.min(viewport.X, viewport.Y)
		-- Sizes below are mostly Scale, so they already follow the screen.
		-- UIScale is an extra nudge so text stays usable on phones.
		if shortSide < 520 then
			scale.Scale = 0.9
		else
			scale.Scale = 1
		end
	end

	refresh()
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		local nextCamera = workspace.CurrentCamera
		if nextCamera then
			nextCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
		end
		refresh()
	end)
end

function UiKit.Gradient(parent: Instance, fromColor: Color3, toColor: Color3, rotation: number)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(fromColor, toColor)
	gradient.Rotation = rotation
	gradient.Parent = parent
	return gradient
end

function UiKit.Glow(parent: Instance, color: Color3)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 1.6
	stroke.Transparency = 0.2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

return UiKit
