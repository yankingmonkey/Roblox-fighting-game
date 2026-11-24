--!strict
-- Press L. Click an ability, then click a slot.
-- Slots 1-4 take normal moves. The Q slot takes only an ultimate.

local Players = game:GetService("Players")

local Replicated = game:GetService("ReplicatedStorage").FightingClasses
local AbilityRegistry = require(Replicated.Shared.AbilityRegistry)
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
end

function LoadoutMenu.Mount(gui: ScreenGui)
	local player = Players.LocalPlayer
	local selectedId = ""

	local frame = Instance.new("Frame")
	frame.Name = "Loadout"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.46)
	frame.Size = UDim2.fromScale(0.78, 0.72)
	frame.BackgroundColor3 = Color3.fromRGB(14, 16, 26)
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.ZIndex = 4
	frame.Parent = gui
	panel = frame
	UiKit.Corner(frame, 14)
	UiKit.Stroke(frame, Color3.fromRGB(90, 110, 160), 1.5)
	UiKit.Padding(frame, 12)

	local title = UiKit.Label(frame, "Loadout")
	title.Size = UDim2.fromScale(0.5, 0.08)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24

	local help = UiKit.Label(frame, "Click a move, then click a slot. L closes this menu.")
	help.Position = UDim2.fromScale(0, 0.08)
	help.Size = UDim2.fromScale(0.7, 0.06)
	help.TextSize = 14
	help.TextColor3 = Color3.fromRGB(180, 188, 210)

	local closeButton = UiKit.Button(frame, "Close")
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.fromScale(1, 0)
	closeButton.Size = UDim2.fromScale(0.14, 0.08)
	UiKit.Corner(closeButton, 8)
	closeButton.Activated:Connect(function()
		frame.Visible = false
	end)

	local changeClass = UiKit.Button(frame, "Change class")
	changeClass.AnchorPoint = Vector2.new(1, 0)
	changeClass.Position = UDim2.fromScale(0.84, 0)
	changeClass.Size = UDim2.fromScale(0.16, 0.08)
	UiKit.Corner(changeClass, 8)
	changeClass.Activated:Connect(function()
		frame.Visible = false
		ClassSelect.ShowSwitcher()
	end)

	local note = UiKit.Label(frame, "")
	note.Position = UDim2.fromScale(0, 0.92)
	note.Size = UDim2.fromScale(1, 0.07)
	note.TextColor3 = Color3.fromRGB(255, 206, 130)
	note.Font = Enum.Font.GothamBold

	local list = Instance.new("ScrollingFrame")
	list.Name = "Abilities"
	list.Position = UDim2.fromScale(0, 0.16)
	list.Size = UDim2.fromScale(0.58, 0.74)
	list.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.fromScale(0, 0)
	list.Parent = frame
	UiKit.Corner(list, 10)

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 8)
	listLayout.Parent = list
	UiKit.Padding(list, 8)

	local slotColumn = Instance.new("Frame")
	slotColumn.Name = "Slots"
	slotColumn.Position = UDim2.fromScale(0.62, 0.16)
	slotColumn.Size = UDim2.fromScale(0.38, 0.74)
	slotColumn.BackgroundTransparency = 1
	slotColumn.Parent = frame

	local slotLayout = Instance.new("UIListLayout")
	slotLayout.Padding = UDim.new(0.02, 0)
	slotLayout.Parent = slotColumn

	local abilityButtons: { TextButton } = {}
	local slotButtons: { TextButton } = {}

	local function currentSlots(): { string }
		return LoadoutUtil.Decode(player:GetAttribute("Loadout"))
	end

	local function paint()
		local classId = Util.ReadString(player:GetAttribute("ClassId"), "")
		local equipped = currentSlots()
		for _, button in abilityButtons do
			button:Destroy()
		end
		table.clear(abilityButtons)

		if classId == "" then
			note.Text = "Pick a class before editing slots."
			for index, button in slotButtons do
				button.Text = KEYS[index] .. "   Empty"
			end
			return
		end

		for _, ability in AbilityRegistry.GetClassAbilities(classId) do
			local headline = string.format("%s    %d dmg    %.1fs    %d energy", ability.name, ability.damage, ability.cooldown, ability.energyCost)
			if ability.isUltimate then
				headline = "ULT  " .. headline
			end
			local button = UiKit.Button(list, headline)
			button.Size = UDim2.new(1, -8, 0, 42)
			button.TextXAlignment = Enum.TextXAlignment.Left
			button.TextSize = 14
			button.BackgroundColor3 = if ability.id == selectedId then ability.color:Lerp(Color3.new(0, 0, 0), 0.45) else Color3.fromRGB(28, 32, 48)
			UiKit.Corner(button, 8)
			local id = ability.id
			button.Activated:Connect(function()
				selectedId = id
				note.Text = ability.name .. " — " .. ability.description
				task.defer(paint)
			end)
			table.insert(abilityButtons, button)
		end

		for index, button in slotButtons do
			local abilityId = equipped[index] or ""
			local ability = if abilityId ~= "" then AbilityRegistry.Get(abilityId) else nil
			if ability then
				button.Text = KEYS[index] .. "   " .. ability.name
				button.BackgroundColor3 = ability.color:Lerp(Color3.new(0, 0, 0), 0.55)
			else
				button.Text = KEYS[index] .. "   Empty"
				button.BackgroundColor3 = Color3.fromRGB(28, 32, 48)
			end
		end
	end

	for index = 1, 5 do
		local button = UiKit.Button(slotColumn, KEYS[index] .. "   Empty")
		button.Size = UDim2.fromScale(1, 0.16)
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.TextSize = 16
		UiKit.Corner(button, 8)
		local slotIndex = index
		button.Activated:Connect(function()
			local classId = Util.ReadString(player:GetAttribute("ClassId"), "")
			if classId == "" then
				note.Text = "Pick a class first."
				return
			end
			if selectedId == "" then
				note.Text = "Click an ability on the left first."
				return
			end
			local slots = currentSlots()
			for slot = 1, 5 do
				if slots[slot] == selectedId then
					slots[slot] = ""
				end
			end
			slots[slotIndex] = selectedId
			local ok, reason = LoadoutUtil.Validate(classId, slots)
			if not ok then
				note.Text = reason
				return
			end
			AbilityClient.SetLoadout(slots)
			note.Text = "Saving loadout..."
		end)
		slotButtons[index] = button
	end

	player:GetAttributeChangedSignal("Loadout"):Connect(paint)
	player:GetAttributeChangedSignal("ClassId"):Connect(function()
		selectedId = ""
		paint()
	end)
	frame:GetPropertyChangedSignal("Visible"):Connect(function()
		if frame.Visible then
			paint()
		end
	end)
	paint()
end

return LoadoutMenu
