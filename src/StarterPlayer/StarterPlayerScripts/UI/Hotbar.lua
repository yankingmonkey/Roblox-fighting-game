--!strict
-- Glass hotbar: health, energy, five ability slots, and touch buttons.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Replicated = game:GetService("ReplicatedStorage").FightingClasses
local AbilityRegistry = require(Replicated.Shared.AbilityRegistry)
local Classes = require(Replicated.Shared.Classes)
local LoadoutUtil = require(Replicated.Shared.LoadoutUtil)
local Util = require(Replicated.Shared.Util)
local AbilityClient = require(script.Parent.Parent.Controllers.AbilityClient)
local MovementClient = require(script.Parent.Parent.Controllers.MovementClient)
local UiKit = require(script.Parent.UiKit)

local KEYS = { "1", "2", "3", "4", "Q" }
local Hotbar = {}

local function classColor(player: Player): Color3
	local info = Classes.ById[Util.ReadString(player:GetAttribute("ClassId"), "")]
	return if info then info.color else Color3.fromRGB(90, 140, 255)
end

function Hotbar.Mount(gui: ScreenGui)
	local player = Players.LocalPlayer
	local shownEnergy = 100
	local shownHealth = 1

	local root = Instance.new("Frame")
	root.Name = "Hotbar"
	root.AnchorPoint = Vector2.new(0.5, 1)
	root.Position = UDim2.fromScale(0.5, 0.98)
	root.Size = UDim2.fromScale(0.62, 0.22)
	root.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
	root.BackgroundTransparency = 0.28
	root.BorderSizePixel = 0
	root.Parent = gui
	UiKit.Corner(root, 16)
	local panelStroke = UiKit.Glow(root, classColor(player))
	UiKit.Gradient(root, Color3.fromRGB(18, 22, 34), Color3.fromRGB(8, 10, 16), 90)

	local status = UiKit.Label(root, "")
	status.AnchorPoint = Vector2.new(0.5, 1)
	status.Position = UDim2.fromScale(0.4, -0.02)
	status.Size = UDim2.fromScale(0.7, 0.16)
	status.TextXAlignment = Enum.TextXAlignment.Center
	status.Font = Enum.Font.GothamBold
	status.TextColor3 = Color3.fromRGB(255, 220, 140)

	local combat = UiKit.Label(root, "")
	combat.AnchorPoint = Vector2.new(0, 0)
	combat.Position = UDim2.fromScale(0.03, 0.04)
	combat.Size = UDim2.fromScale(0.28, 0.12)
	combat.Font = Enum.Font.GothamBold
	combat.TextSize = 12
	combat.TextColor3 = Color3.fromRGB(255, 120, 90)

	local function bar(name: string, y: number, color: Color3): (Frame, TextLabel)
		local back = Instance.new("Frame")
		back.Name = name
		back.Position = UDim2.fromScale(0.03, y)
		back.Size = UDim2.fromScale(0.62, 0.1)
		back.BackgroundColor3 = Color3.fromRGB(6, 8, 12)
		back.BackgroundTransparency = 0.2
		back.BorderSizePixel = 0
		back.Parent = root
		UiKit.Corner(back, 8)
		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = color
		fill.BorderSizePixel = 0
		fill.Parent = back
		UiKit.Corner(fill, 8)
		UiKit.Gradient(fill, color, color:Lerp(Color3.new(1, 1, 1), 0.35), 0)
		local text = UiKit.Label(back, "")
		text.Size = UDim2.fromScale(1, 1)
		text.TextXAlignment = Enum.TextXAlignment.Center
		text.Font = Enum.Font.GothamBold
		text.TextSize = 13
		return fill, text
	end

	local healthFill, healthText = bar("Health", 0.18, Color3.fromRGB(220, 70, 80))
	local energyFill, energyText = bar("Energy", 0.3, classColor(player))

	local slots = Instance.new("Frame")
	slots.Name = "Slots"
	slots.Position = UDim2.fromScale(0.03, 0.44)
	slots.Size = UDim2.fromScale(0.62, 0.5)
	slots.BackgroundTransparency = 1
	slots.Parent = root
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0.02, 0)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = slots

	type SlotGui = { button: TextButton, nameLabel: TextLabel, sweep: Frame, hand: Frame, timeLabel: TextLabel }
	local slotGuis: { SlotGui } = {}

	for index = 1, 5 do
		local button = UiKit.Button(slots, "")
		button.Name = "Slot" .. tostring(index)
		button.Size = UDim2.fromScale(0.18, 1)
		button.Text = ""
		button.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
		button.BackgroundTransparency = 0.15
		button.LayoutOrder = index
		UiKit.Corner(button, 10)
		UiKit.Glow(button, if index == 5 then Color3.fromRGB(255, 196, 80) else Color3.fromRGB(80, 90, 120))
		local keyLabel = UiKit.Label(button, KEYS[index])
		keyLabel.Size = UDim2.fromScale(0.42, 0.28)
		keyLabel.Position = UDim2.fromScale(0.06, 0.06)
		keyLabel.Font = Enum.Font.GothamBold
		keyLabel.TextSize = 12
		keyLabel.TextColor3 = Color3.fromRGB(200, 210, 230)
		local nameLabel = UiKit.Label(button, "Empty")
		nameLabel.Size = UDim2.fromScale(0.88, 0.46)
		nameLabel.Position = UDim2.fromScale(0.06, 0.4)
		nameLabel.TextScaled = true
		local limit = Instance.new("UITextSizeConstraint")
		limit.MaxTextSize = 14
		limit.MinTextSize = 8
		limit.Parent = nameLabel
		local sweep = Instance.new("Frame")
		sweep.AnchorPoint = Vector2.new(0.5, 1)
		sweep.Position = UDim2.fromScale(0.5, 1)
		sweep.Size = UDim2.fromScale(1, 0)
		sweep.BackgroundColor3 = Color3.new(0, 0, 0)
		sweep.BackgroundTransparency = 0.4
		sweep.BorderSizePixel = 0
		sweep.ZIndex = 2
		sweep.Visible = false
		sweep.Parent = button
		UiKit.Corner(sweep, 10)
		local hand = Instance.new("Frame")
		hand.AnchorPoint = Vector2.new(0.5, 1)
		hand.Position = UDim2.fromScale(0.5, 0.5)
		hand.Size = UDim2.new(0, 2, 0.48, 0)
		hand.BackgroundColor3 = Color3.new(1, 1, 1)
		hand.BorderSizePixel = 0
		hand.ZIndex = 4
		hand.Visible = false
		hand.Parent = button
		local timeLabel = UiKit.Label(button, "")
		timeLabel.Size = UDim2.fromScale(1, 0.4)
		timeLabel.Position = UDim2.fromScale(0, 0.3)
		timeLabel.TextXAlignment = Enum.TextXAlignment.Center
		timeLabel.Font = Enum.Font.GothamBold
		timeLabel.TextSize = 18
		timeLabel.ZIndex = 5
		local slotIndex = index
		button.Activated:Connect(function()
			AbilityClient.Cast(slotIndex)
		end)
		slotGuis[index] = { button = button, nameLabel = nameLabel, sweep = sweep, hand = hand, timeLabel = timeLabel }
	end

	local function side(text: string, x: number, y: number): TextButton
		local button = UiKit.Button(root, text)
		button.Position = UDim2.fromScale(x, y)
		button.Size = UDim2.fromScale(0.15, 0.2)
		button.TextSize = 13
		button.BackgroundTransparency = 0.1
		UiKit.Corner(button, 8)
		UiKit.Glow(button, classColor(player))
		return button
	end

	local menuButton = side("Menu", 0.68, 0.02)
	menuButton.Size = UDim2.fromScale(0.31, 0.14)
	menuButton.Activated:Connect(function()
		AbilityClient.ReturnToMenu()
	end)
	local attack = side("Attack", 0.68, 0.18)
	local dash = side("Dash", 0.84, 0.18)
	local blockButton = side("Block", 0.68, 0.42)
	local parryButton = side("Parry", 0.84, 0.42)
	local rise = side("Rise", 0.68, 0.66)
	local drop = side("Drop", 0.84, 0.66)
	rise.Visible = false
	drop.Visible = false
	attack.Activated:Connect(function()
		AbilityClient.M1()
	end)
	dash.Activated:Connect(function()
		AbilityClient.Dash()
	end)
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

	local function refreshChrome()
		local camera = workspace.CurrentCamera
		local width = if camera then camera.ViewportSize.X else 1280
		root.Size = if width < 800 then UDim2.fromScale(0.96, 0.28) else UDim2.fromScale(0.62, 0.22)
		local accent = classColor(player)
		panelStroke.Color = accent
		energyFill.BackgroundColor3 = accent
		local showFlight = UserInputService.TouchEnabled
		for _, id in LoadoutUtil.Decode(player:GetAttribute("Loadout")) do
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

	RunService.RenderStepped:Connect(function(dt)
		local energy = Util.ReadNumber(player:GetAttribute("Energy"), 0)
		local maxEnergy = math.max(1, Util.ReadNumber(player:GetAttribute("MaxEnergy"), 100))
		local targetEnergy = energy / maxEnergy
		shownEnergy += (targetEnergy - shownEnergy) * math.min(1, dt * 10)
		energyFill.Size = UDim2.fromScale(math.clamp(shownEnergy, 0, 1), 1)
		energyText.Text = string.format("KI  %d", math.floor(energy + 0.5))

		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local targetHealth = 1
		if humanoid and humanoid.MaxHealth > 0 then
			targetHealth = humanoid.Health / humanoid.MaxHealth
			healthText.Text = string.format("HP  %d", math.floor(humanoid.Health + 0.5))
		else
			healthText.Text = "HP"
		end
		shownHealth += (targetHealth - shownHealth) * math.min(1, dt * 8)
		healthFill.Size = UDim2.fromScale(math.clamp(shownHealth, 0, 1), 1)

		status.Text = AbilityClient.GetStatus()
		local inCombat = player:GetAttribute("InCombat") == true
		combat.Text = if inCombat then "IN COMBAT" else ""
		local equipped = LoadoutUtil.Decode(player:GetAttribute("Loadout"))
		for index, widgets in slotGuis do
			local ability = AbilityRegistry.Get(equipped[index] or "")
			if ability then
				widgets.nameLabel.Text = ability.name
				widgets.button.BackgroundColor3 = ability.color:Lerp(Color3.fromRGB(10, 12, 20), 0.72)
				local remain = AbilityClient.GetRemaining(ability.id)
				if remain > 0.05 then
					local fraction = math.clamp(remain / math.max(ability.cooldown, 0.1), 0, 1)
					widgets.sweep.Visible = true
					widgets.sweep.Size = UDim2.fromScale(1, fraction)
					widgets.hand.Visible = true
					widgets.hand.Rotation = -90 + 360 * (1 - fraction)
					widgets.timeLabel.Text = tostring(math.ceil(remain))
				else
					widgets.sweep.Visible = false
					widgets.hand.Visible = false
					widgets.timeLabel.Text = ""
				end
			else
				widgets.nameLabel.Text = "Empty"
				widgets.button.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
				widgets.sweep.Visible = false
				widgets.hand.Visible = false
				widgets.timeLabel.Text = ""
			end
		end
	end)

	player:GetAttributeChangedSignal("ClassId"):Connect(function()
		TweenService:Create(panelStroke, TweenInfo.new(0.25), { Color = classColor(player) }):Play()
		refreshChrome()
	end)
	player:GetAttributeChangedSignal("Loadout"):Connect(refreshChrome)
	refreshChrome()
end

return Hotbar
