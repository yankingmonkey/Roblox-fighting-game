--!strict
-- Title screen. Play drops you into the fight. The camera orbits your character
-- while this menu is open.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local AbilityClient = require(script.Parent.Parent.Controllers.AbilityClient)
local VfxKit = require(script.Parent.Parent.Controllers.VfxKit)
local UiKit = require(script.Parent.UiKit)
local ClassDecor = require(script.Parent.ClassDecor)

local MainMenu = {}
local open = true

function MainMenu.IsOpen(): boolean
	return open
end

function MainMenu.Mount(gui: ScreenGui, openClasses: () -> (), openLoadout: () -> (), openCustomize: () -> ())
	local player = Players.LocalPlayer
	local blur = Instance.new("BlurEffect")
	blur.Name = "MenuBlur"
	blur.Size = 16
	blur.Parent = game:GetService("Lighting")

	local frame = Instance.new("Frame")
	frame.Name = "MainMenu"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(6, 8, 14)
	frame.BackgroundTransparency = 0.35
	frame.BorderSizePixel = 0
	frame.ZIndex = 6
	frame.Parent = gui
	UiKit.Gradient(frame, Color3.fromRGB(20, 24, 40), Color3.fromRGB(6, 8, 14), 90)

	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.fromScale(0.34, 0.62)
	card.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
	card.BackgroundTransparency = 0.15
	card.BorderSizePixel = 0
	card.Parent = frame
	UiKit.Corner(card, 18)
	UiKit.Glow(card, Color3.fromRGB(150, 170, 220))
	ClassDecor.Attach(card, "KiWarrior")

	local kicker = UiKit.Label(card, "ROOFTOP ARENA")
	kicker.Position = UDim2.fromScale(0.1, 0.05)
	kicker.Size = UDim2.fromScale(0.8, 0.05)
	kicker.Font = UiKit.FontTitle
	kicker.TextSize = 12
	kicker.TextXAlignment = Enum.TextXAlignment.Center
	kicker.TextColor3 = Color3.fromRGB(255, 196, 120)

	local title = UiKit.Label(card, "FIGHTING")
	title.Position = UDim2.fromScale(0.08, 0.1)
	title.Size = UDim2.fromScale(0.84, 0.09)
	title.Font = UiKit.FontTitle
	title.TextSize = 36
	title.TextXAlignment = Enum.TextXAlignment.Center

	local word = UiKit.Label(card, "CLASSES")
	word.Position = UDim2.fromScale(0.08, 0.18)
	word.Size = UDim2.fromScale(0.84, 0.07)
	word.Font = UiKit.FontTitle
	word.TextSize = 22
	word.TextXAlignment = Enum.TextXAlignment.Center
	word.TextColor3 = Color3.fromRGB(140, 190, 255)

	local rule = Instance.new("Frame")
	rule.AnchorPoint = Vector2.new(0.5, 0)
	rule.Position = UDim2.fromScale(0.5, 0.26)
	rule.Size = UDim2.fromScale(0.28, 0.008)
	rule.BackgroundColor3 = Color3.fromRGB(255, 196, 120)
	rule.BorderSizePixel = 0
	rule.Parent = card
	UiKit.Corner(rule, 4)

	local sub = UiKit.Label(card, "Aim. Lead the shot. Don't fall off the roof.")
	sub.Position = UDim2.fromScale(0.08, 0.28)
	sub.Size = UDim2.fromScale(0.84, 0.06)
	sub.TextSize = 14
	sub.TextXAlignment = Enum.TextXAlignment.Center
	sub.TextColor3 = UiKit.Muted

	local settings = Instance.new("Frame")
	settings.Name = "Settings"
	settings.Position = UDim2.fromScale(0.1, 0.38)
	settings.Size = UDim2.fromScale(0.8, 0.5)
	settings.BackgroundTransparency = 1
	settings.Visible = false
	settings.Parent = card

	local volumeLabel = UiKit.Label(settings, "Volume")
	volumeLabel.Size = UDim2.fromScale(1, 0.15)
	local volume = Instance.new("TextButton")
	volume.Size = UDim2.fromScale(1, 0.18)
	volume.Position = UDim2.fromScale(0, 0.16)
	volume.BackgroundColor3 = Color3.fromRGB(30, 36, 52)
	volume.Text = "100%"
	volume.Font = Enum.Font.GothamBold
	volume.TextSize = 16
	volume.TextColor3 = Color3.new(1, 1, 1)
	volume.Parent = settings
	UiKit.Corner(volume, 8)
	local volumeValue = 1
	volume.Activated:Connect(function()
		volumeValue = (volumeValue + 0.25) % 1.25
		if volumeValue > 1 then
			volumeValue = 0
		end
		volume.Text = tostring(math.floor(volumeValue * 100)) .. "%"
		local group = game:GetService("SoundService"):FindFirstChild("Fighting")
		if group and group:IsA("SoundGroup") then
			group.Volume = volumeValue
		end
	end)

	local shake = UiKit.Button(settings, "Camera shake: On")
	shake.Position = UDim2.fromScale(0, 0.42)
	shake.Size = UDim2.fromScale(1, 0.2)
	UiKit.Corner(shake, 8)
	local shakeOn = true
	shake.Activated:Connect(function()
		shakeOn = not shakeOn
		shake.Text = if shakeOn then "Camera shake: On" else "Camera shake: Off"
		VfxKit.SetShakeEnabled(shakeOn)
	end)

	local aimMode = UiKit.Button(settings, "Aim mode: Mouse")
	aimMode.Position = UDim2.fromScale(0, 0.68)
	aimMode.Size = UDim2.fromScale(1, 0.2)
	UiKit.Corner(aimMode, 8)
	aimMode.Activated:Connect(function()
		local enabled = not AbilityClient.ShiftLock()
		AbilityClient.SetShiftLock(enabled)
		aimMode.Text = if enabled then "Aim mode: Shift-lock" else "Aim mode: Mouse"
	end)

	local buttons = Instance.new("Frame")
	buttons.Position = UDim2.fromScale(0.12, 0.36)
	buttons.Size = UDim2.fromScale(0.76, 0.6)
	buttons.BackgroundTransparency = 1
	buttons.Parent = card
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0.04, 0)
	layout.Parent = buttons

	local function showHome()
		buttons.Visible = true
		settings.Visible = false
		title.Text = "FIGHTING CLASSES"
	end

	local function add(text: string, callback: () -> ())
		local button = UiKit.Button(buttons, text)
		button.Size = UDim2.new(1, 0, 0, 42)
		UiKit.Corner(button, 10)
		button.Activated:Connect(callback)
	end

	local function close()
		open = false
		frame.Visible = false
		TweenService:Create(blur, TweenInfo.new(0.2), { Size = 0 }):Play()
	end

	add("Play", function()
		local classId = player:GetAttribute("ClassId")
		if classId == nil or classId == "" then
			frame.Visible = false
			open = false
			blur.Size = 8
			openClasses()
			return
		end
		close()
	end)
	add("Classes", function()
		frame.Visible = false
		open = false
		blur.Size = 8
		openClasses()
	end)
	add("Loadout", function()
		if player:GetAttribute("ClassId") == nil or player:GetAttribute("ClassId") == "" then
			sub.Text = "Pick a class first."
			return
		end
		close()
		openLoadout()
	end)
	add("Customize", function()
		close()
		openCustomize()
	end)
	add("Settings", function()
		buttons.Visible = false
		settings.Visible = true
		title.Text = "SETTINGS"
	end)

	local back = UiKit.Button(card, "Back")
	back.Position = UDim2.fromScale(0.12, 0.88)
	back.Size = UDim2.fromScale(0.3, 0.08)
	UiKit.Corner(back, 8)
	back.Activated:Connect(showHome)

	function MainMenu.Show()
		open = true
		frame.Visible = true
		showHome()
		UiKit.Pop(card)
		TweenService:Create(blur, TweenInfo.new(0.2), { Size = 16 }):Play()
	end

	RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not open or not camera or not root or not root:IsA("BasePart") then
			if camera and camera.CameraType == Enum.CameraType.Scriptable and not open then
				camera.CameraType = Enum.CameraType.Custom
			end
			return
		end
		local angle = os.clock() * 0.35
		local focus = root.Position + Vector3.new(0, 2, 0)
		local position = focus + Vector3.new(math.cos(angle) * 14, 4, math.sin(angle) * 14)
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.new(position, focus)
	end)

	local group = Instance.new("SoundGroup")
	group.Name = "Fighting"
	group.Volume = 1
	group.Parent = game:GetService("SoundService")
end

return MainMenu
