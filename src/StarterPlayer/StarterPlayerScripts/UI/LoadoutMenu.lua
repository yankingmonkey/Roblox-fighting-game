--!strict
-- DCUO-style loadout. Click a move, then a slot, or drag the move onto a slot.
-- Slots 1-4 take any non-ultimate from your class pool. Q takes one ultimate.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Replicated = game:GetService("ReplicatedStorage").FightingClasses
local AbilityRegistry = require(Replicated.Shared.AbilityRegistry)
local Classes = require(Replicated.Shared.Classes)
local LoadoutUtil = require(Replicated.Shared.LoadoutUtil)
local Util = require(Replicated.Shared.Util)
local AbilityClient = require(script.Parent.Parent.Controllers.AbilityClient)
local ClassSelect = require(script.Parent.ClassSelect)
local UiKit = require(script.Parent.UiKit)

local KEYS = { "1", "2", "3", "4", "Q" }
local LoadoutMenu = {}
local panel: Frame? = nil

function LoadoutMenu.IsOpen(): boolean
	return panel ~= nil and panel.Visible
end

function LoadoutMenu.Close()
	if panel then
		panel.Visible = false
	end
end

function LoadoutMenu.Toggle()
	if not panel then
		return
	end
	panel.Visible = not panel.Visible
	if panel.Visible then
		panel.Position = UDim2.fromScale(0.5, 0.5)
		TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(0.5, 0.46),
		}):Play()
	end
end

function LoadoutMenu.Mount(gui: ScreenGui)
	local player = Players.LocalPlayer
	local selectedId = ""
	local draggingId = ""

	local frame = Instance.new("Frame")
	frame.Name = "Loadout"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.46)
	frame.Size = UDim2.fromScale(0.78, 0.74)
	frame.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.ZIndex = 4
	frame.Parent = gui
	panel = frame
	UiKit.Corner(frame, 16)
	local stroke = UiKit.Glow(frame, Color3.fromRGB(120, 150, 220))
	UiKit.Gradient(frame, Color3.fromRGB(22, 26, 40), Color3.fromRGB(8, 10, 16), 120)
	UiKit.Padding(frame, 14)

	local title = UiKit.Label(frame, "Loadout")
	title.Size = UDim2.fromScale(0.45, 0.08)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 26

	local help = UiKit.Label(frame, "Drag a move onto a slot, or click it and then click the slot. 1–4 are any move. Q is one ultimate.")
	help.Position = UDim2.fromScale(0, 0.08)
	help.Size = UDim2.fromScale(0.72, 0.06)
	help.TextSize = 14
	help.TextColor3 = Color3.fromRGB(180, 190, 214)

	local closeButton = UiKit.Button(frame, "Close")
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.fromScale(1, 0)
	closeButton.Size = UDim2.fromScale(0.12, 0.08)
	UiKit.Corner(closeButton, 8)
	closeButton.Activated:Connect(function()
		frame.Visible = false
	end)

	local changeClass = UiKit.Button(frame, "Change class")
	changeClass.AnchorPoint = Vector2.new(1, 0)
	changeClass.Position = UDim2.fromScale(0.86, 0)
	changeClass.Size = UDim2.fromScale(0.16, 0.08)
	UiKit.Corner(changeClass, 8)
	changeClass.Activated:Connect(function()
		frame.Visible = false
		ClassSelect.ShowSwitcher()
	end)

	local note = UiKit.Label(frame, "")
	note.Position = UDim2.fromScale(0, 0.92)
	note.Size = UDim2.fromScale(1, 0.07)
	note.TextColor3 = Color3.fromRGB(255, 214, 140)
	note.Font = Enum.Font.GothamBold

	local tip = UiKit.Label(gui, "")
	tip.Name = "Tooltip"
	tip.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
	tip.BackgroundTransparency = 0.08
	tip.TextXAlignment = Enum.TextXAlignment.Left
	tip.TextSize = 14
	tip.Visible = false
	tip.ZIndex = 8
	tip.Size = UDim2.fromOffset(280, 72)
	UiKit.Corner(tip, 8)
	UiKit.Padding(tip, 8)

	local list = Instance.new("ScrollingFrame")
	list.Name = "Pool"
	list.Position = UDim2.fromScale(0, 0.16)
	list.Size = UDim2.fromScale(0.58, 0.74)
	list.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
	list.BackgroundTransparency = 0.35
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.fromScale(0, 0)
	list.Parent = frame
	UiKit.Corner(list, 12)
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 6)
	listLayout.Parent = list
	UiKit.Padding(list, 8)

	local slotColumn = Instance.new("Frame")
	slotColumn.Position = UDim2.fromScale(0.62, 0.16)
	slotColumn.Size = UDim2.fromScale(0.38, 0.74)
	slotColumn.BackgroundTransparency = 1
	slotColumn.Parent = frame
	local slotLayout = Instance.new("UIListLayout")
	slotLayout.Padding = UDim.new(0.025, 0)
	slotLayout.Parent = slotColumn

	local abilityButtons: { GuiObject } = {}
	local slotButtons: { TextButton } = {}

	local function showTip(text: string, button: GuiObject)
		tip.Text = text
		tip.Visible = true
		local x = button.AbsolutePosition.X + button.AbsoluteSize.X + 8
		local y = button.AbsolutePosition.Y
		tip.Position = UDim2.fromOffset(x, y)
	end

	local function assign(slotIndex: number, abilityId: string)
		local classId = Util.ReadString(player:GetAttribute("ClassId"), "")
		if classId == "" then
			note.Text = "Pick a class first."
			return
		end
		if abilityId == "" then
			note.Text = "Pick a move from the pool."
			return
		end
		local slots = LoadoutUtil.Decode(player:GetAttribute("Loadout"))
		for slot = 1, 5 do
			if slots[slot] == abilityId then
				slots[slot] = ""
			end
		end
		slots[slotIndex] = abilityId
		local ok, reason = LoadoutUtil.Validate(classId, slots)
		if not ok then
			note.Text = reason
			return
		end
		AbilityClient.SetLoadout(slots)
		note.Text = "Saving loadout..."
	end

	local function paint()
		local classId = Util.ReadString(player:GetAttribute("ClassId"), "")
		local info = Classes.ById[classId]
		if info then
			stroke.Color = info.color
			title.Text = info.name .. " loadout"
		end
		for _, button in abilityButtons do
			button:Destroy()
		end
		table.clear(abilityButtons)
		local equipped = LoadoutUtil.Decode(player:GetAttribute("Loadout"))
		if classId == "" then
			note.Text = "Pick a class before editing slots."
			return
		end
		local function header(text: string)
			local label = UiKit.Label(list, text)
			label.Size = UDim2.new(1, -8, 0, 22)
			label.Font = Enum.Font.GothamBold
			label.TextColor3 = if info then info.color else Color3.new(1, 1, 1)
			table.insert(abilityButtons, label)
		end
		header("MOVES")
		local function addAbility(ability)
			local line = string.format("%s    %d dmg    %.1fs    %d energy", ability.name, ability.damage, ability.cooldown, ability.energyCost)
			local button = UiKit.Button(list, line)
			button.Size = UDim2.new(1, -8, 0, 36)
			button.TextXAlignment = Enum.TextXAlignment.Left
			button.TextSize = 14
			button.BackgroundColor3 = if ability.id == selectedId
				then ability.color:Lerp(Color3.new(0, 0, 0), 0.35)
				else Color3.fromRGB(20, 24, 36)
			UiKit.Corner(button, 8)
			UiKit.Glow(button, ability.color)
			local id = ability.id
			local description = ability.name .. " — " .. ability.description
			button.MouseEnter:Connect(function()
				showTip(description, button)
			end)
			button.MouseLeave:Connect(function()
				tip.Visible = false
			end)
			button.Activated:Connect(function()
				selectedId = id
				note.Text = description
				task.defer(paint)
			end)
			button.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					draggingId = id
					selectedId = id
				end
			end)
			table.insert(abilityButtons, button)
		end
		for _, ability in AbilityRegistry.GetClassAbilities(classId) do
			if not ability.isUltimate then
				addAbility(ability)
			end
		end
		header("ULTIMATES  (Q)")
		for _, ability in AbilityRegistry.GetClassAbilities(classId) do
			if ability.isUltimate then
				addAbility(ability)
			end
		end
		for index, button in slotButtons do
			local ability = AbilityRegistry.Get(equipped[index] or "")
			if ability then
				button.Text = KEYS[index] .. "   " .. ability.name
				button.BackgroundColor3 = ability.color:Lerp(Color3.new(0, 0, 0), 0.45)
			else
				button.Text = KEYS[index] .. "   Empty"
				button.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
			end
		end
	end

	for index = 1, 5 do
		local button = UiKit.Button(slotColumn, KEYS[index] .. "   Empty")
		button.Name = "Drop" .. tostring(index)
		button.Size = UDim2.fromScale(1, 0.16)
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.TextSize = 16
		UiKit.Corner(button, 8)
		local slotIndex = index
		button.Activated:Connect(function()
			if selectedId ~= "" then
				assign(slotIndex, selectedId)
			else
				note.Text = "Click a move on the left first."
			end
		end)
		slotButtons[index] = button
	end

	UserInputService.InputEnded:Connect(function(input)
		if draggingId == "" then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local point = Vector2.new(input.Position.X, input.Position.Y)
		for index, button in slotButtons do
			local pos = button.AbsolutePosition
			local size = button.AbsoluteSize
			if point.X >= pos.X and point.X <= pos.X + size.X and point.Y >= pos.Y and point.Y <= pos.Y + size.Y then
				assign(index, draggingId)
				break
			end
		end
		draggingId = ""
	end)

	player:GetAttributeChangedSignal("Loadout"):Connect(paint)
	player:GetAttributeChangedSignal("ClassId"):Connect(function()
		selectedId = ""
		paint()
	end)
	frame:GetPropertyChangedSignal("Visible"):Connect(function()
		if frame.Visible then
			paint()
		else
			tip.Visible = false
			draggingId = ""
		end
	end)
	paint()
end

return LoadoutMenu
