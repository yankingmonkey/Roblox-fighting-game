--!strict
-- Bottom bar: energy, five slots, and touch buttons for block / parry / flight.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Replicated = game:GetService("ReplicatedStorage").FightingClasses
local AbilityRegistry = require(Replicated.Shared.AbilityRegistry)
local LoadoutUtil = require(Replicated.Shared.LoadoutUtil)
local Util = require(Replicated.Shared.Util)
local AbilityClient = require(script.Parent.Parent.Controllers.AbilityClient)
local MovementClient = require(script.Parent.Parent.Controllers.MovementClient)
local UiKit = require(script.Parent.UiKit)

local KEYS = { "1", "2", "3", "4", "Q" }

local Hotbar = {}

function Hotbar.Mount(gui: ScreenGui)
	local player = Players.LocalPlayer

	local root = Instance.new("Frame")
	root.Name = "Hotbar"
	root.AnchorPoint = Vector2.new(0.5, 1)
	root.Position = UDim2.fromScale(0.5, 0.97)
	root.Size = UDim2.fromScale(0.72, 0.2)
	root.BackgroundTransparency = 1
	root.Parent = gui

	local status = UiKit.Label(root, "")
	status.Name = "Status"
	status.AnchorPoint = Vector2.new(0.5, 1)
	status.Position = UDim2.fromScale(0.5, 0.02)
	status.Size = UDim2.fromScale(0.8, 0.16)
	status.TextXAlignment = Enum.TextXAlignment.Center
	status.Font = Enum.Font.GothamBold
	status.TextColor3 = Color3.fromRGB(255, 214, 120)

	local combat = UiKit.Label(root, "")
	combat.Name = "Combat"
	combat.AnchorPoint = Vector2.new(0.5, 1)
	combat.Position = UDim2.fromScale(0.5, 0.18)
	combat.Size = UDim2.fromScale(0.4, 0.12)
	combat.TextXAlignment = Enum.TextXAlignment.Center
	combat.Font = Enum.Font.GothamBold
	combat.TextSize = 13
	combat.TextColor3 = Color3.fromRGB(255, 120, 90)

	local energyBack = Instance.new("Frame")
	energyBack.Name = "Energy"
	energyBack.AnchorPoint = Vector2.new(0.5, 1)
	energyBack.Position = UDim2.fromScale(0.42, 0.36)
	energyBack.Size = UDim2.fromScale(0.7, 0.1)
	energyBack.BackgroundColor3 = Color3.fromRGB(18, 20, 32)
	energyBack.BorderSizePixel = 0
	energyBack.Parent = root
	UiKit.Corner(energyBack, 8)

	local energyFill = Instance.new("Frame")
	energyFill.Name = "Fill"
	energyFill.Size = UDim2.fromScale(1, 1)
	energyFill.BackgroundColor3 = Color3.fromRGB(70, 170, 255)
	energyFill.BorderSizePixel = 0
	energyFill.Parent = energyBack
	UiKit.Corner(energyFill, 8)

	local energyText = UiKit.Label(energyBack, "100 / 100")
	energyText.Size = UDim2.fromScale(1, 1)
	energyText.TextXAlignment = Enum.TextXAlignment.Center
	energyText.Font = Enum.Font.GothamBold
	energyText.TextSize = 14

	local slots = Instance.new("Frame")
	slots.Name = "Slots"
	slots.AnchorPoint = Vector2.new(0.5, 1)
	slots.Position = UDim2.fromScale(0.42, 0.98)
	slots.Size = UDim2.fromScale(0.7, 0.58)
	slots.BackgroundTransparency = 1
	slots.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0.015, 0)
	layout.Parent = slots

	type SlotGui = {
		button: TextButton,
		nameLabel: TextLabel,
		sweep: Frame,
		timeLabel: TextLabel,
		keyLabel: TextLabel,
	}
	local slotGuis: { SlotGui } = {}

	for index = 1, 5 do
		local button = UiKit.Button(slots, "")
		button.Name = "Slot" .. tostring(index)
		button.Size = UDim2.fromScale(0.18, 1)
		button.Text = ""
		button.BackgroundColor3 = Color3.fromRGB(22, 26, 40)
		button.LayoutOrder = index
		UiKit.Corner(button, 10)
		UiKit.Stroke(button, if index == 5 then Color3.fromRGB(255, 196, 80) else Color3.fromRGB(70, 80, 110), 1.5)

		local keyLabel = UiKit.Label(button, KEYS[index])
		keyLabel.Size = UDim2.fromScale(0.4, 0.28)
		keyLabel.Position = UDim2.fromScale(0.06, 0.06)
		keyLabel.Font = Enum.Font.GothamBold
		keyLabel.TextSize = 13
		keyLabel.TextColor3 = Color3.fromRGB(180, 190, 220)

		local nameLabel = UiKit.Label(button, "Empty")
		nameLabel.Size = UDim2.fromScale(0.88, 0.5)
		nameLabel.Position = UDim2.fromScale(0.06, 0.38)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextYAlignment = Enum.TextYAlignment.Bottom
		nameLabel.TextScaled = true
		local constraint = Instance.new("UITextSizeConstraint")
		constraint.MaxTextSize = 16
		constraint.MinTextSize = 8
		constraint.Parent = nameLabel

		local sweep = Instance.new("Frame")
		sweep.Name = "Sweep"
		sweep.AnchorPoint = Vector2.new(0.5, 1)
		sweep.Position = UDim2.fromScale(0.5, 1)
		sweep.Size = UDim2.fromScale(1, 0)
		sweep.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		sweep.BackgroundTransparency = 0.35
		sweep.BorderSizePixel = 0
		sweep.ZIndex = 2
		sweep.Visible = false
		sweep.Parent = button
		UiKit.Corner(sweep, 10)

		local timeLabel = UiKit.Label(button, "")
		timeLabel.Size = UDim2.fromScale(1, 1)
		timeLabel.TextXAlignment = Enum.TextXAlignment.Center
		timeLabel.Font = Enum.Font.GothamBold
		timeLabel.TextSize = 22
		timeLabel.ZIndex = 3
		timeLabel.Text = ""

		local slotIndex = index
		button.Activated:Connect(function()
			AbilityClient.Cast(slotIndex)
		end)

		slotGuis[index] = {
			button = button,
			nameLabel = nameLabel,
			sweep = sweep,
			timeLabel = timeLabel,
			keyLabel = keyLabel,
		}
	end

	local function sideButton(text: string, x: number): TextButton
		local button = UiKit.Button(root, text)
		button.AnchorPoint = Vector2.new(0, 1)
		button.Position = UDim2.fromScale(x, 0.98)
		button.Size = UDim2.fromScale(0.12, 0.28)
		button.TextSize = 13
		UiKit.Corner(button, 8)
		return button
	end

	local blockButton = sideButton("Block", 0.8)
	local parryButton = sideButton("Parry", 0.8)
	parryButton.Position = UDim2.fromScale(0.8, 0.66)
	blockButton.MouseButton1Down:Connect(function()
		AbilityClient.SetBlock(true)
	end)
	blockButton.MouseButton1Up:Connect(function()
		AbilityClient.SetBlock(false)
	end)
	blockButton.MouseLeave:Connect(function()
		AbilityClient.SetBlock(false)
	end)
	parryButton.Activated:Connect(function()
		AbilityClient.Parry()
	end)

	local rise = sideButton("Rise", 0.92)
	local drop = sideButton("Drop", 0.92)
	drop.Position = UDim2.fromScale(0.92, 0.66)
	rise.Visible = false
	drop.Visible = false
	rise.MouseButton1Down:Connect(function()
		MovementClient.SetVertical(1)
	end)
	rise.MouseButton1Up:Connect(function()
		MovementClient.SetVertical(0)
	end)
	drop.MouseButton1Down:Connect(function()
		MovementClient.SetVertical(-1)
	end)
	drop.MouseButton1Up:Connect(function()
		MovementClient.SetVertical(0)
	end)

	local function refreshLayout()
		local camera = workspace.CurrentCamera
		local width = if camera then camera.ViewportSize.X else 1280
		if width < 800 then
			root.Size = UDim2.fromScale(0.96, 0.24)
		else
			root.Size = UDim2.fromScale(0.72, 0.2)
		end
		local showFlight = UserInputService.TouchEnabled
		local slotsNow = LoadoutUtil.Decode(player:GetAttribute("Loadout"))
		for _, id in slotsNow do
			if id == "Flight" then
				showFlight = true
			end
		end
		local character = player.Character
		if character and character:GetAttribute("Flying") == true then
			showFlight = true
		end
		rise.Visible = showFlight
		drop.Visible = showFlight
	end

	local function refreshSlots()
		local equipped = LoadoutUtil.Decode(player:GetAttribute("Loadout"))
		for index, widgets in slotGuis do
			local abilityId = equipped[index] or ""
			local ability = if abilityId ~= "" then AbilityRegistry.Get(abilityId) else nil
			if ability then
				widgets.nameLabel.Text = ability.name
				widgets.button.BackgroundColor3 = ability.color:Lerp(Color3.fromRGB(16, 18, 28), 0.72)
				local remain = AbilityClient.GetRemaining(ability.id)
				if remain > 0.05 then
					local fraction = math.clamp(remain / math.max(ability.cooldown, 0.1), 0, 1)
					widgets.sweep.Visible = true
					widgets.sweep.Size = UDim2.fromScale(1, fraction)
					widgets.timeLabel.Text = tostring(math.ceil(remain))
				else
					widgets.sweep.Visible = false
					widgets.sweep.Size = UDim2.fromScale(1, 0)
					widgets.timeLabel.Text = ""
				end
			else
				widgets.nameLabel.Text = "Empty"
				widgets.button.BackgroundColor3 = Color3.fromRGB(22, 26, 40)
				widgets.sweep.Visible = false
				widgets.timeLabel.Text = ""
			end
		end
	end

	RunService.RenderStepped:Connect(function()
		local energy = Util.ReadNumber(player:GetAttribute("Energy"), 0)
		local maxEnergy = math.max(1, Util.ReadNumber(player:GetAttribute("MaxEnergy"), 100))
		energyFill.Size = UDim2.fromScale(math.clamp(energy / maxEnergy, 0, 1), 1)
		energyText.Text = string.format("%d / %d", math.floor(energy + 0.5), math.floor(maxEnergy + 0.5))
		status.Text = AbilityClient.GetStatus()
		combat.Text = if player:GetAttribute("InCombat") == true then "IN COMBAT" else ""
		refreshSlots()
	end)

	player:GetAttributeChangedSignal("Loadout"):Connect(refreshLayout)
	player:GetAttributeChangedSignal("ClassId"):Connect(refreshLayout)
	refreshLayout()
end

return Hotbar
