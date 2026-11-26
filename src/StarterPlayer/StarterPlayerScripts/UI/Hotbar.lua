--!strict
-- Clean fight HUD: health, ki, five slots, combo count, and the foe in front of you.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Replicated = game:GetService("ReplicatedStorage").FightingClasses
local AbilityRegistry = require(Replicated.Shared.AbilityRegistry)
local Classes = require(Replicated.Shared.Classes)
local LoadoutUtil = require(Replicated.Shared.LoadoutUtil)
local Util = require(Replicated.Shared.Util)
local AbilityClient = require(script.Parent.Parent.Controllers.AbilityClient)
local MovementClient = require(script.Parent.Parent.Controllers.MovementClient)
local ClassDecor = require(script.Parent.ClassDecor)
local UiKit = require(script.Parent.UiKit)

local KEYS = { "1", "2", "3", "4", "Q" }
local Hotbar = {}

local function classColor(player: Player): Color3
	local info = Classes.ById[Util.ReadString(player:GetAttribute("ClassId"), "")]
	return if info then info.color else Color3.fromRGB(120, 160, 255)
end

function Hotbar.Mount(gui: ScreenGui)
	local player = Players.LocalPlayer
	local shownHealth = 1
	local shownEnergy = 1
	local shownTarget = 1
	local selected = 1
	local accent = classColor(player)

	local targetCard = UiKit.Glass(gui, accent)
	targetCard.Name = "Target"
	targetCard.AnchorPoint = Vector2.new(0.5, 0)
	targetCard.Position = UDim2.fromScale(0.5, 0.04)
	targetCard.Size = UDim2.fromScale(0.28, 0.07)
	targetCard.Visible = false
	local targetName = UiKit.Label(targetCard, "")
	targetName.Position = UDim2.fromScale(0.06, 0.08)
	targetName.Size = UDim2.fromScale(0.88, 0.42)
	targetName.Font = UiKit.FontTitle
	targetName.TextSize = 14
	local targetBack = Instance.new("Frame")
	targetBack.Position = UDim2.fromScale(0.06, 0.58)
	targetBack.Size = UDim2.fromScale(0.88, 0.28)
	targetBack.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
	targetBack.BorderSizePixel = 0
	targetBack.Parent = targetCard
	UiKit.Corner(targetBack, 6)
	local targetFill = Instance.new("Frame")
	targetFill.Size = UDim2.fromScale(1, 1)
	targetFill.BackgroundColor3 = Color3.fromRGB(220, 70, 80)
	targetFill.BorderSizePixel = 0
	targetFill.Parent = targetBack
	UiKit.Corner(targetFill, 6)

	local dock = UiKit.Glass(gui, accent)
	dock.Name = "Hotbar"
	dock.AnchorPoint = Vector2.new(0.5, 1)
	dock.Position = UDim2.fromScale(0.5, 0.97)
	dock.Size = UDim2.fromScale(0.52, 0.16)
	ClassDecor.Attach(dock, Util.ReadString(player:GetAttribute("ClassId"), "KiWarrior"))
	UiKit.Pop(dock)

	local function meter(name: string, y: number, color: Color3): (Frame, TextLabel)
		local back = Instance.new("Frame")
		back.Name = name
		back.Position = UDim2.fromScale(0.04, y)
		back.Size = UDim2.fromScale(0.62, 0.14)
		back.BackgroundColor3 = Color3.fromRGB(6, 8, 12)
		back.BackgroundTransparency = 0.15
		back.BorderSizePixel = 0
		back.Parent = dock
		UiKit.Corner(back, 7)
		local fill = Instance.new("Frame")
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = color
		fill.BorderSizePixel = 0
		fill.Parent = back
		UiKit.Corner(fill, 7)
		local text = UiKit.Label(back, "")
		text.Size = UDim2.fromScale(1, 1)
		text.TextXAlignment = Enum.TextXAlignment.Center
		text.Font = UiKit.FontTitle
		text.TextSize = 12
		return fill, text
	end

	local healthFill, healthText = meter("Health", 0.06, Color3.fromRGB(214, 72, 84))
	local energyFill, energyText = meter("Energy", 0.22, accent)

	local combo = UiKit.Label(dock, "")
	combo.AnchorPoint = Vector2.new(1, 0)
	combo.Position = UDim2.fromScale(0.66, 0.06)
	combo.Size = UDim2.fromScale(0.2, 0.28)
	combo.Font = UiKit.FontTitle
	combo.TextSize = 22
	combo.TextXAlignment = Enum.TextXAlignment.Right
	combo.TextColor3 = accent

	local slots = Instance.new("Frame")
	slots.Position = UDim2.fromScale(0.04, 0.42)
	slots.Size = UDim2.fromScale(0.62, 0.52)
	slots.BackgroundTransparency = 1
	slots.Parent = dock
	local row = Instance.new("UIListLayout")
	row.FillDirection = Enum.FillDirection.Horizontal
	row.Padding = UDim.new(0.018, 0)
	row.VerticalAlignment = Enum.VerticalAlignment.Center
	row.Parent = slots

	type Slot = { button: TextButton, nameLabel: TextLabel, sweep: Frame, hand: Frame, timeLabel: TextLabel, decor: Frame? }
	local slotGuis: { Slot } = {}

	for index = 1, 5 do
		local button = UiKit.Button(slots, "")
		button.Size = UDim2.fromScale(0.184, 1)
		button.Text = ""
		button.BackgroundTransparency = 0.12
		button.LayoutOrder = index
		UiKit.Corner(button, 10)
		UiKit.Glow(button, if index == 5 then Color3.fromRGB(255, 196, 90) else accent)
		local key = UiKit.Label(button, KEYS[index])
		key.Size = UDim2.fromScale(0.5, 0.28)
		key.Position = UDim2.fromScale(0.08, 0.06)
		key.Font = UiKit.FontTitle
		key.TextSize = 12
		key.TextColor3 = UiKit.Muted
		local nameLabel = UiKit.Label(button, "Empty")
		nameLabel.Position = UDim2.fromScale(0.08, 0.38)
		nameLabel.Size = UDim2.fromScale(0.84, 0.5)
		nameLabel.TextScaled = true
		nameLabel.Font = UiKit.FontTitle
		local cap = Instance.new("UITextSizeConstraint")
		cap.MaxTextSize = 14
		cap.MinTextSize = 8
		cap.Parent = nameLabel
		local sweep = Instance.new("Frame")
		sweep.AnchorPoint = Vector2.new(0.5, 1)
		sweep.Position = UDim2.fromScale(0.5, 1)
		sweep.Size = UDim2.fromScale(1, 0)
		sweep.BackgroundColor3 = Color3.new(0, 0, 0)
		sweep.BackgroundTransparency = 0.45
		sweep.BorderSizePixel = 0
		sweep.ZIndex = 3
		sweep.Visible = false
		sweep.Parent = button
		UiKit.Corner(sweep, 10)
		local hand = Instance.new("Frame")
		hand.AnchorPoint = Vector2.new(0.5, 1)
		hand.Position = UDim2.fromScale(0.5, 0.5)
		hand.Size = UDim2.new(0, 2, 0.46, 0)
		hand.BackgroundColor3 = Color3.new(1, 1, 1)
		hand.BorderSizePixel = 0
		hand.ZIndex = 4
		hand.Visible = false
		hand.Parent = button
		local timeLabel = UiKit.Label(button, "")
		timeLabel.Size = UDim2.fromScale(1, 0.46)
		timeLabel.Position = UDim2.fromScale(0, 0.24)
		timeLabel.TextXAlignment = Enum.TextXAlignment.Center
		timeLabel.Font = UiKit.FontTitle
		timeLabel.TextSize = 18
		timeLabel.ZIndex = 5
		local slotIndex = index
		button.Activated:Connect(function()
			selected = slotIndex
			AbilityClient.Cast(slotIndex)
		end)
		slotGuis[index] = {
			button = button,
			nameLabel = nameLabel,
			sweep = sweep,
			hand = hand,
			timeLabel = timeLabel,
		}
	end

	local tools = Instance.new("Frame")
	tools.Position = UDim2.fromScale(0.68, 0.08)
	tools.Size = UDim2.fromScale(0.29, 0.84)
	tools.BackgroundTransparency = 1
	tools.Parent = dock
	local toolRow = Instance.new("UIGridLayout")
	toolRow.CellSize = UDim2.fromScale(0.48, 0.2)
	toolRow.CellPadding = UDim2.fromScale(0.04, 0.04)
	toolRow.Parent = tools

	local function tool(text: string): TextButton
		local button = UiKit.Button(tools, text)
		button.TextSize = 12
		UiKit.Corner(button, 8)
		return button
	end
	tool("Menu").Activated:Connect(function()
		AbilityClient.ReturnToMenu()
	end)
	tool("Attack").Activated:Connect(function()
		AbilityClient.M1()
	end)
	tool("Dash").Activated:Connect(function()
		AbilityClient.Dash()
	end)
	local blockButton = tool("Block")
	local parryButton = tool("Parry")
	local rise = tool("Rise")
	local drop = tool("Drop")
	rise.Visible = false
	drop.Visible = false
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

	local decoratedSlot = 0
	local function retint()
		accent = classColor(player)
		local classId = Util.ReadString(player:GetAttribute("ClassId"), "KiWarrior")
		energyFill.BackgroundColor3 = accent
		combo.TextColor3 = accent
		local stroke = dock:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = accent
		end
		local targetStroke = targetCard:FindFirstChildOfClass("UIStroke")
		if targetStroke then
			targetStroke.Color = accent
		end
		ClassDecor.Attach(dock, classId)
		decoratedSlot = 0
	end

	local currentTarget: Humanoid? = nil
	RunService.RenderStepped:Connect(function(dt)
		local energy = Util.ReadNumber(player:GetAttribute("Energy"), 0)
		local maxEnergy = math.max(1, Util.ReadNumber(player:GetAttribute("MaxEnergy"), 100))
		shownEnergy += (energy / maxEnergy - shownEnergy) * math.min(1, dt * 10)
		energyFill.Size = UDim2.fromScale(math.clamp(shownEnergy, 0, 1), 1)
		energyText.Text = string.format("KI  %d", math.floor(energy + 0.5))

		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local hp = 1
		if humanoid and humanoid.MaxHealth > 0 then
			hp = humanoid.Health / humanoid.MaxHealth
			healthText.Text = string.format("HP  %d", math.floor(humanoid.Health + 0.5))
		end
		shownHealth += (hp - shownHealth) * math.min(1, dt * 8)
		healthFill.Size = UDim2.fromScale(math.clamp(shownHealth, 0, 1), 1)

		local untilTime = player:GetAttribute("ComboUntil")
		local step = player:GetAttribute("ComboStep")
		if typeof(step) == "number" and typeof(untilTime) == "number" and workspace:GetServerTimeNow() < untilTime then
			combo.Text = tostring(step) .. "x"
		else
			combo.Text = ""
		end

		local camera = workspace.CurrentCamera
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if camera and root and root:IsA("BasePart") then
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { character }
			local hit = workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * 180, params)
			local model = hit and hit.Instance:FindFirstAncestorOfClass("Model")
			local foe = model and model:FindFirstChildOfClass("Humanoid")
			if foe and foe.Health > 0 and model ~= character then
				currentTarget = foe
				targetCard.Visible = true
				targetName.Text = model.Name
			end
		end
		if currentTarget and currentTarget.Parent and currentTarget.Health > 0 then
			local ratio = currentTarget.Health / math.max(currentTarget.MaxHealth, 1)
			shownTarget += (ratio - shownTarget) * math.min(1, dt * 8)
			targetFill.Size = UDim2.fromScale(math.clamp(shownTarget, 0, 1), 1)
		else
			targetCard.Visible = false
			currentTarget = nil
		end

		local equipped = LoadoutUtil.Decode(player:GetAttribute("Loadout"))
		for index, widgets in slotGuis do
			local ability = AbilityRegistry.Get(equipped[index] or "")
			local chosen = index == selected
			if ability then
				widgets.nameLabel.Text = ability.name
				widgets.button.BackgroundColor3 = ability.color:Lerp(Color3.fromRGB(10, 12, 18), if chosen then 0.45 else 0.72)
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
				widgets.button.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
				widgets.sweep.Visible = false
				widgets.hand.Visible = false
				widgets.timeLabel.Text = ""
			end
		end

		if selected ~= decoratedSlot then
			decoratedSlot = selected
			local classId = Util.ReadString(player:GetAttribute("ClassId"), "KiWarrior")
			for index, widgets in slotGuis do
				local old = widgets.button:FindFirstChild("ClassDecor")
				if old and index ~= selected then
					old:Destroy()
				end
			end
			ClassDecor.Attach(slotGuis[selected].button, classId)
		end

		local showFlight = player.Character ~= nil and player.Character:GetAttribute("Flying") == true
		for _, id in LoadoutUtil.Decode(player:GetAttribute("Loadout")) do
			if id == "Flight" then
				showFlight = true
			end
		end
		rise.Visible = showFlight
		drop.Visible = showFlight
	end)

	player:GetAttributeChangedSignal("ClassId"):Connect(retint)
	retint()
end

return Hotbar
