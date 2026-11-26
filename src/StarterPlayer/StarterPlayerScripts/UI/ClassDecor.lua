--!strict
-- Small animated shapes that sit on a glass panel and match the class.

local RunService = game:GetService("RunService")

local Classes = require(game:GetService("ReplicatedStorage").FightingClasses.Shared.Classes)

local ClassDecor = {}

function ClassDecor.Attach(parent: GuiObject, classId: string)
	local existing = parent:FindFirstChild("ClassDecor")
	if existing then
		existing:Destroy()
	end
	local info = Classes.ById[classId]
	local color = if info then info.color else Color3.fromRGB(140, 160, 210)
	local folder = Instance.new("Frame")
	folder.Name = "ClassDecor"
	folder.BackgroundTransparency = 1
	folder.Size = UDim2.fromScale(1, 1)
	folder.ZIndex = parent.ZIndex + 1
	folder.Parent = parent

	local bits: { Frame } = {}
	for index = 1, 4 do
		local bit = Instance.new("Frame")
		bit.AnchorPoint = Vector2.new(0.5, 0.5)
		bit.Size = UDim2.fromOffset(10, 28)
		bit.Position = UDim2.fromScale(0.15 * index, 0.2)
		bit.BackgroundColor3 = color
		bit.BackgroundTransparency = 0.35
		bit.BorderSizePixel = 0
		bit.ZIndex = folder.ZIndex
		bit.Parent = folder
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = bit
		bits[index] = bit
	end

	local connection = RunService.RenderStepped:Connect(function()
		if not folder.Parent then
			return
		end
		local t = os.clock()
		if classId == "Speedster" then
			for index, bit in bits do
				bit.Rotation = math.sin(t * 18 + index) * 30
				bit.BackgroundTransparency = 0.2 + (math.noise(t * 4, index) + 1) * 0.3
			end
		elseif classId == "Elemental" then
			local colors = {
				Color3.fromRGB(255, 120, 40),
				Color3.fromRGB(140, 210, 255),
				Color3.fromRGB(190, 230, 210),
				Color3.fromRGB(160, 130, 90),
			}
			for index, bit in bits do
				local angle = t * 1.4 + index * math.pi / 2
				bit.Position = UDim2.fromScale(0.5 + math.cos(angle) * 0.38, 0.5 + math.sin(angle) * 0.32)
				bit.BackgroundColor3 = colors[index]
				bit.Size = UDim2.fromOffset(14, 14)
			end
		elseif classId == "KiWarrior" then
			local pulse = 0.25 + math.sin(t * 4) * 0.2
			for _, bit in bits do
				bit.BackgroundTransparency = pulse
				bit.Size = UDim2.fromOffset(18, 18)
			end
		elseif classId == "Brawler" then
			local jolt = math.noise(t * 8) * 4
			folder.Position = UDim2.fromOffset(jolt, math.noise(t * 6, 2) * 3)
		elseif classId == "Ninja" then
			for index, bit in bits do
				local y = (t * 0.15 + index * 0.2) % 1
				bit.Position = UDim2.fromScale(0.2 + index * 0.15, 1 - y)
				bit.BackgroundTransparency = y
				bit.BackgroundColor3 = Color3.fromRGB(180, 180, 190)
				bit.Size = UDim2.fromOffset(16, 8)
			end
		else
			for index, bit in bits do
				bit.Position = UDim2.fromScale(0.2 + index * 0.15, 0.12)
				bit.BackgroundTransparency = 0.15 + math.sin(t * 3 + index) * 0.15
				bit.BackgroundColor3 = color:Lerp(Color3.new(1, 1, 1), 0.35)
			end
		end
	end)
	folder.Destroying:Connect(function()
		connection:Disconnect()
	end)
	return folder
end

return ClassDecor
