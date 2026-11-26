--!strict
-- Dress the preview, then save. The server rebuilds the same parts on your character.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Replicated = game:GetService("ReplicatedStorage").FightingClasses
local OutfitBuilder = require(Replicated.Shared.OutfitBuilder)
local OutfitCatalog = require(Replicated.Shared.OutfitCatalog)
local AbilityClient = require(script.Parent.Parent.Controllers.AbilityClient)
local UiKit = require(script.Parent.UiKit)

local SWATCHES = {
	Color3.fromRGB(220, 60, 70),
	Color3.fromRGB(40, 90, 200),
	Color3.fromRGB(240, 200, 60),
	Color3.fromRGB(30, 30, 36),
	Color3.fromRGB(230, 230, 235),
	Color3.fromRGB(120, 70, 200),
	Color3.fromRGB(40, 160, 120),
	Color3.fromRGB(200, 120, 50),
}

local CustomizeMenu = {}
local frame: Frame? = nil

local function readSaved(): { [string]: any }
	local blob = Players.LocalPlayer:GetAttribute("OutfitJson")
	if typeof(blob) ~= "string" or blob == "" then
		return {}
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(blob)
	end)
	if ok and typeof(decoded) == "table" then
		return decoded
	end
	return {}
end

function CustomizeMenu.IsOpen(): boolean
	return frame ~= nil and frame.Visible
end

function CustomizeMenu.Mount(gui: ScreenGui, returnToMenu: () -> ())
	local player = Players.LocalPlayer
	local draft: { [string]: any } = {}
	local category = "Headgear"
	local angle = 0

	local root = Instance.new("Frame")
	root.Name = "Customize"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
	root.BackgroundTransparency = 0.2
	root.Visible = false
	root.ZIndex = 7
	root.Parent = gui
	frame = root
	UiKit.Gradient(root, Color3.fromRGB(18, 22, 34), Color3.fromRGB(8, 10, 16), 80)

	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromScale(0.92, 0.88)
	panel.Position = UDim2.fromScale(0.04, 0.06)
	panel.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
	panel.BackgroundTransparency = 0.12
	panel.Parent = root
	UiKit.Corner(panel, 16)
	UiKit.Glow(panel, Color3.fromRGB(180, 60, 80))

	local title = UiKit.Label(panel, "Customize")
	title.Position = UDim2.fromScale(0.03, 0.03)
	title.Size = UDim2.fromScale(0.4, 0.08)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 26

	local viewport = Instance.new("ViewportFrame")
	viewport.Position = UDim2.fromScale(0.52, 0.14)
	viewport.Size = UDim2.fromScale(0.44, 0.7)
	viewport.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
	viewport.BorderSizePixel = 0
	viewport.Parent = panel
	UiKit.Corner(viewport, 12)
	local world = Instance.new("WorldModel")
	world.Parent = viewport
	local camera = Instance.new("Camera")
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromScale(0.03, 0.28)
	list.Size = UDim2.fromScale(0.46, 0.42)
	list.BackgroundTransparency = 1
	list.ScrollBarThickness = 6
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.fromScale(0, 0)
	list.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = list

	local cats = Instance.new("Frame")
	cats.Position = UDim2.fromScale(0.03, 0.14)
	cats.Size = UDim2.fromScale(0.46, 0.12)
	cats.BackgroundTransparency = 1
	cats.Parent = panel
	local catLayout = Instance.new("UIListLayout")
	catLayout.FillDirection = Enum.FillDirection.Horizontal
	catLayout.Padding = UDim.new(0.02, 0)
	catLayout.Parent = cats

	local colors = Instance.new("Frame")
	colors.Position = UDim2.fromScale(0.03, 0.72)
	colors.Size = UDim2.fromScale(0.46, 0.12)
	colors.BackgroundTransparency = 1
	colors.Parent = panel
	local colorLayout = Instance.new("UIListLayout")
	colorLayout.FillDirection = Enum.FillDirection.Horizontal
	colorLayout.Padding = UDim.new(0.02, 0)
	colorLayout.Parent = colors

	local chosenColor = SWATCHES[1]

	local function currentSlot()
		return draft[category]
	end

	local function refreshView()
		world:ClearAllChildren()
		local character = player.Character
		if not character then
			return
		end
		character.Archivable = true
		local clone = character:Clone()
		character.Archivable = false
		for _, child in clone:GetChildren() do
			if child:IsA("Script") or child:IsA("LocalScript") then
				child:Destroy()
			end
		end
		clone.Parent = world
		OutfitBuilder.Apply(clone, table.clone(draft))
		local rootPart = clone:FindFirstChild("HumanoidRootPart")
		if rootPart and rootPart:IsA("BasePart") then
			local focus = rootPart.Position + Vector3.new(0, 1, 0)
			local offset = CFrame.Angles(0, angle, 0) * Vector3.new(0, 1.5, 8)
			camera.CFrame = CFrame.new(focus + offset, focus)
		end
	end

	local function paintItems()
		for _, child in list:GetChildren() do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		local clear = UiKit.Button(list, "None")
		clear.Size = UDim2.new(1, -8, 0, 32)
		UiKit.Corner(clear, 8)
		clear.Activated:Connect(function()
			draft[category] = nil
			refreshView()
		end)
		for _, info in OutfitCatalog.Categories[category] do
			local button = UiKit.Button(list, info.name)
			button.Size = UDim2.new(1, -8, 0, 32)
			UiKit.Corner(button, 8)
			local worn = currentSlot()
			if worn and worn.id == info.id then
				button.BackgroundColor3 = chosenColor:Lerp(Color3.new(0, 0, 0), 0.4)
			end
			local itemId = info.id
			button.Activated:Connect(function()
				draft[category] = {
					id = itemId,
					r = chosenColor.R,
					g = chosenColor.G,
					b = chosenColor.B,
				}
				refreshView()
				paintItems()
			end)
		end
	end

	for _, name in OutfitCatalog.Order do
		local button = UiKit.Button(cats, name)
		button.Size = UDim2.fromScale(0.13, 1)
		button.TextSize = 11
		UiKit.Corner(button, 6)
		button.Activated:Connect(function()
			category = name
			paintItems()
		end)
	end

	for _, swatch in SWATCHES do
		local button = Instance.new("TextButton")
		button.Size = UDim2.fromOffset(28, 28)
		button.BackgroundColor3 = swatch
		button.Text = ""
		button.Parent = colors
		UiKit.Corner(button, 6)
		button.Activated:Connect(function()
			chosenColor = swatch
			local worn = currentSlot()
			if worn then
				worn.r = swatch.R
				worn.g = swatch.G
				worn.b = swatch.B
				refreshView()
			end
		end)
	end

	local rotate = UiKit.Button(panel, "Rotate")
	rotate.Position = UDim2.fromScale(0.52, 0.86)
	rotate.Size = UDim2.fromScale(0.18, 0.08)
	UiKit.Corner(rotate, 8)
	rotate.Activated:Connect(function()
		angle += math.rad(40)
		refreshView()
	end)

	local save = UiKit.Button(panel, "Save outfit")
	save.Position = UDim2.fromScale(0.72, 0.86)
	save.Size = UDim2.fromScale(0.22, 0.08)
	save.BackgroundColor3 = Color3.fromRGB(48, 110, 70)
	UiKit.Corner(save, 8)
	save.Activated:Connect(function()
		AbilityClient.SetOutfit(draft)
	end)

	local back = UiKit.Button(panel, "Menu")
	back.Position = UDim2.fromScale(0.03, 0.86)
	back.Size = UDim2.fromScale(0.16, 0.08)
	UiKit.Corner(back, 8)
	back.Activated:Connect(function()
		root.Visible = false
		returnToMenu()
	end)

	function CustomizeMenu.Show()
		draft = readSaved()
		root.Visible = true
		paintItems()
		refreshView()
	end
end

return CustomizeMenu
