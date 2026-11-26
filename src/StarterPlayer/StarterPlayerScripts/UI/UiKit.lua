--!strict
-- One look for every screen: glass panels, Gotham Bold titles, Builder body text.

local TweenService = game:GetService("TweenService")

local UiKit = {}

UiKit.FontTitle = Enum.Font.GothamBold
UiKit.FontBody = Enum.Font.BuilderSans
UiKit.Ink = Color3.fromRGB(236, 240, 248)
UiKit.Muted = Color3.fromRGB(176, 186, 208)
UiKit.Glass = Color3.fromRGB(12, 16, 26)

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
	label.Font = UiKit.FontBody
	label.TextColor3 = UiKit.Ink
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
	button.Font = UiKit.FontTitle
	button.TextColor3 = UiKit.Ink
	button.TextSize = 16
	button.TextWrapped = true
	button.Text = text
	button.BackgroundColor3 = Color3.fromRGB(24, 28, 42)
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Parent = parent
	UiKit.Motion(button)
	return button
end

function UiKit.Motion(button: GuiButton)
	local pop = Instance.new("UIScale")
	pop.Name = "Press"
	pop.Parent = button
	local base: Color3? = nil
	button.MouseEnter:Connect(function()
		base = button.BackgroundColor3
		TweenService:Create(button, TweenInfo.new(0.12), {
			BackgroundColor3 = base:Lerp(Color3.new(1, 1, 1), 0.16),
		}):Play()
	end)
	button.MouseLeave:Connect(function()
		if base then
			TweenService:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = base }):Play()
		end
		TweenService:Create(pop, TweenInfo.new(0.1), { Scale = 1 }):Play()
	end)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(pop, TweenInfo.new(0.06), { Scale = 0.96 }):Play()
	end)
	button.MouseButton1Up:Connect(function()
		TweenService:Create(pop, TweenInfo.new(0.1), { Scale = 1 }):Play()
	end)
end

function UiKit.Glass(parent: Instance, accent: Color3): Frame
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = UiKit.Glass
	frame.BackgroundTransparency = 0.22
	frame.BorderSizePixel = 0
	frame.Parent = parent
	UiKit.Corner(frame, 16)
	UiKit.Gradient(frame, Color3.fromRGB(28, 34, 48), Color3.fromRGB(10, 12, 18), 110)
	UiKit.Glow(frame, accent)
	return frame
end

function UiKit.Pop(frame: GuiObject)
	local pop = frame:FindFirstChild("PopScale")
	if not pop then
		pop = Instance.new("UIScale")
		pop.Name = "PopScale"
		pop.Parent = frame
	end
	if pop:IsA("UIScale") then
		pop.Scale = 0.94
		frame.Visible = true
		TweenService:Create(pop, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
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
