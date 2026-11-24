--!strict
-- Full-screen class picker. First join cannot close it. Opening it from the
-- loadout menu can, and the server still rejects a switch during combat.

local Players = game:GetService("Players")

local Replicated = game:GetService("ReplicatedStorage").FightingClasses
local AbilityRegistry = require(Replicated.Shared.AbilityRegistry)
local Classes = require(Replicated.Shared.Classes)
local AbilityClient = require(script.Parent.Parent.Controllers.AbilityClient)
local UiKit = require(script.Parent.UiKit)

local ClassSelect = {}

local panel: Frame? = nil
local switching = false
local chosenId = ""
local refreshView: () -> () = function() end

function ClassSelect.IsOpen(): boolean
	return panel ~= nil and panel.Visible
end

function ClassSelect.ShowSwitcher()
	switching = true
	refreshView()
end

function ClassSelect.Mount(gui: ScreenGui)
	local player = Players.LocalPlayer

	local frame = Instance.new("Frame")
	frame.Name = "ClassSelect"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
	frame.BackgroundTransparency = 0.12
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.ZIndex = 5
	frame.Parent = gui
	panel = frame

	local title = UiKit.Label(frame, "Choose your class")
	title.Position = UDim2.fromScale(0.06, 0.03)
	title.Size = UDim2.fromScale(0.6, 0.07)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 28

	local hint = UiKit.Label(frame, "You can change class later from the loadout menu, but only out of combat.")
	hint.Position = UDim2.fromScale(0.06, 0.1)
	hint.Size = UDim2.fromScale(0.7, 0.05)
	hint.TextSize = 15
	hint.TextColor3 = Color3.fromRGB(180, 190, 214)

	local closeButton = UiKit.Button(frame, "Close")
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.fromScale(0.96, 0.04)
	closeButton.Size = UDim2.fromScale(0.12, 0.06)
	closeButton.Visible = false
	UiKit.Corner(closeButton, 8)
	closeButton.Activated:Connect(function()
		switching = false
		chosenId = ""
		frame.Visible = false
	end)

	local banner = UiKit.Label(frame, "")
	banner.Position = UDim2.fromScale(0.06, 0.15)
	banner.Size = UDim2.fromScale(0.88, 0.04)
	banner.TextColor3 = Color3.fromRGB(255, 150, 120)
	banner.Font = Enum.Font.GothamBold

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Cards"
	scroll.Position = UDim2.fromScale(0.04, 0.2)
	scroll.Size = UDim2.fromScale(0.92, 0.62)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.CanvasSize = UDim2.fromScale(0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = frame

	local grid = Instance.new("UIGridLayout")
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.CellPadding = UDim2.fromOffset(12, 12)
	grid.CellSize = UDim2.new(0.31, 0, 0, 200)
	grid.Parent = scroll

	local function columnsFor(width: number): number
		if width < 720 then
			return 1
		elseif width < 1100 then
			return 2
		end
		return 3
	end

	local function reflow()
		local camera = workspace.CurrentCamera
		local width = if camera then camera.ViewportSize.X else 1280
		local columns = columnsFor(width)
		grid.CellSize = UDim2.new(1 / columns - 0.02, 0, 0, 210)
	end
	reflow()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(reflow)
	end

	local buttons: { [string]: TextButton } = {}

	for order, info in Classes.List do
		local button = UiKit.Button(scroll, "")
		button.Name = info.id
		button.Text = ""
		button.LayoutOrder = order
		button.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
		button.AutoButtonColor = true
		UiKit.Corner(button, 12)
		UiKit.Stroke(button, info.color, 2)

		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(1, 0, 0, 8)
		bar.BackgroundColor3 = info.color
		bar.BorderSizePixel = 0
		bar.Parent = button

		local nameLabel = UiKit.Label(button, info.name)
		nameLabel.Position = UDim2.fromScale(0.05, 0.08)
		nameLabel.Size = UDim2.fromScale(0.9, 0.16)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 20

		local role = UiKit.Label(button, info.role)
		role.Position = UDim2.fromScale(0.05, 0.24)
		role.Size = UDim2.fromScale(0.9, 0.1)
		role.TextColor3 = info.color
		role.TextSize = 14

		local summary = UiKit.Label(button, info.summary)
		summary.Position = UDim2.fromScale(0.05, 0.36)
		summary.Size = UDim2.fromScale(0.9, 0.24)
		summary.TextSize = 13
		summary.TextColor3 = Color3.fromRGB(210, 216, 230)

		local lines = {}
		for _, ability in AbilityRegistry.GetClassAbilities(info.id) do
			local line = ability.name
			if ability.isUltimate then
				line ..= " (Ult)"
			end
			table.insert(lines, line)
		end
		local moves = UiKit.Label(button, table.concat(lines, " · "))
		moves.Position = UDim2.fromScale(0.05, 0.62)
		moves.Size = UDim2.fromScale(0.9, 0.32)
		moves.TextSize = 12
		moves.TextColor3 = Color3.fromRGB(170, 178, 200)

		local classId = info.id
		button.Activated:Connect(function()
			local current = player:GetAttribute("ClassId")
			local inCombat = player:GetAttribute("InCombat") == true
			if typeof(current) == "string" and current ~= "" and inCombat then
				banner.Text = "Leave combat before changing class."
				return
			end
			chosenId = classId
			banner.Text = "Play as " .. info.name .. "? Press Confirm."
		end)
		buttons[info.id] = button
	end

	local confirm = UiKit.Button(frame, "Confirm")
	confirm.AnchorPoint = Vector2.new(1, 1)
	confirm.Position = UDim2.fromScale(0.96, 0.96)
	confirm.Size = UDim2.fromScale(0.16, 0.07)
	confirm.BackgroundColor3 = Color3.fromRGB(48, 110, 70)
	UiKit.Corner(confirm, 8)
	confirm.Activated:Connect(function()
		if chosenId == "" then
			banner.Text = "Click a class first."
			return
		end
		AbilityClient.ChooseClass(chosenId)
	end)

	local function refresh()
		local classId = player:GetAttribute("ClassId")
		local inCombat = player:GetAttribute("InCombat") == true
		closeButton.Visible = switching and typeof(classId) == "string" and classId ~= ""
		if switching then
			frame.Visible = true
			title.Text = "Change class"
			scroll.Visible = true
			confirm.Visible = true
		elseif classId == nil then
			frame.Visible = true
			title.Text = "Loading your fighter..."
			scroll.Visible = false
			confirm.Visible = false
		elseif classId == "" then
			frame.Visible = true
			title.Text = "Choose your class"
			scroll.Visible = true
			confirm.Visible = true
			switching = false
		else
			frame.Visible = false
			switching = false
			chosenId = ""
		end

		if typeof(classId) == "string" and classId ~= "" and inCombat and switching then
			banner.Text = "Leave combat before changing class."
		end
		for id, button in buttons do
			local blocked = typeof(classId) == "string" and classId ~= "" and inCombat
			button.AutoButtonColor = not blocked
			button.BackgroundTransparency = if blocked then 0.35 else 0
			if id == chosenId then
				button.BackgroundColor3 = Color3.fromRGB(36, 48, 72)
			else
				button.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
			end
		end
	end

	refreshView = refresh
	player:GetAttributeChangedSignal("ClassId"):Connect(function()
		-- A new class id means the server accepted the choice, so close the picker.
		switching = false
		chosenId = ""
		refresh()
	end)
	player:GetAttributeChangedSignal("InCombat"):Connect(refresh)
	task.defer(refresh)
end

return ClassSelect
