--!strict
-- One animator for every class decoration so the HUD stays cheap.
-- Attach a frame for the panel, or a slot for the ability that is selected.

local RunService = game:GetService("RunService")

local Classes = require(game:GetService("ReplicatedStorage").FightingClasses.Shared.Classes)

type Entry = {
	classId: string,
	root: Frame,
	bits: { Frame },
	stroke: UIStroke?,
}

local entries: { Entry } = {}
local started = false

local function colorFor(classId: string): Color3
	local info = Classes.ById[classId]
	return if info then info.color else Color3.fromRGB(150, 170, 220)
end

local function bit(parent: Frame, size: UDim2): Frame
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BackgroundTransparency = 0.35
	frame.BorderSizePixel = 0
	frame.Size = size
	frame.ZIndex = parent.ZIndex
	frame.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame
	return frame
end

local function step(entry: Entry, now: number)
	local classId = entry.classId
	local bits = entry.bits
	local color = colorFor(classId)
	if classId == "Speedster" then
		for index, item in bits do
			local angle = now * 6 + index * 1.4
			item.Position = UDim2.fromScale(0.5 + math.cos(angle) * 0.46, 0.5 + math.sin(angle) * 0.42)
			item.Rotation = math.deg(angle)
			item.BackgroundColor3 = color
			item.BackgroundTransparency = 0.25
			item.Size = UDim2.fromOffset(3, 18)
		end
	elseif classId == "Elemental" then
		local palette = {
			Color3.fromRGB(255, 120, 40),
			Color3.fromRGB(150, 220, 255),
			Color3.fromRGB(200, 230, 210),
			Color3.fromRGB(170, 140, 90),
		}
		for index, item in bits do
			local angle = now * 1.2 + index * (math.pi / 2)
			item.Position = UDim2.fromScale(0.5 + math.cos(angle) * 0.4, 0.5 + math.sin(angle) * 0.36)
			item.BackgroundColor3 = palette[((index - 1) % 4) + 1]
			item.Size = UDim2.fromOffset(12, 12)
			item.BackgroundTransparency = 0.15
		end
	elseif classId == "KiWarrior" then
		local pulse = 0.35 + math.sin(now * 3) * 0.2
		for _, item in bits do
			item.Position = UDim2.fromScale(0.5, 0.5)
			item.Size = UDim2.fromScale(0.92, 0.86)
			item.BackgroundTransparency = 1
		end
		if entry.stroke then
			entry.stroke.Transparency = pulse
			entry.stroke.Color = color
			entry.stroke.Thickness = 2 + math.sin(now * 3) * 0.6
		end
	elseif classId == "Brawler" then
		for index, item in bits do
			item.Position = UDim2.fromScale(0.15 + index * 0.18, 0.86)
			item.Size = UDim2.fromOffset(18 + (index % 2) * 10, 3)
			item.Rotation = -18 + index * 9
			item.BackgroundColor3 = color:Lerp(Color3.fromRGB(40, 20, 16), 0.35)
			item.BackgroundTransparency = 0.2 + math.abs(math.sin(now * 5 + index)) * 0.4
		end
	elseif classId == "Ninja" then
		for index, item in bits do
			local rise = (now * 0.12 + index * 0.22) % 1
			item.Position = UDim2.fromScale(0.12 + index * 0.18, 1 - rise)
			item.Size = UDim2.fromOffset(14, 6)
			item.BackgroundColor3 = Color3.fromRGB(190, 190, 200)
			item.BackgroundTransparency = rise
		end
	else
		for index, item in bits do
			item.Position = UDim2.fromScale(0.08 + index * 0.2, 0.08)
			item.Size = UDim2.fromOffset(22, 3)
			item.BackgroundColor3 = color:Lerp(Color3.new(1, 1, 1), 0.4)
			item.BackgroundTransparency = 0.2 + math.sin(now * 2 + index) * 0.15
		end
		if entry.stroke then
			entry.stroke.Color = color
		end
	end
end

local function ensure()
	if started then
		return
	end
	started = true
	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		for index = #entries, 1, -1 do
			local entry = entries[index]
			if entry.root.Parent == nil then
				table.remove(entries, index)
			elseif entry.root.Visible then
				step(entry, now)
			end
		end
	end)
end

local ClassDecor = {}

function ClassDecor.Attach(parent: GuiObject, classId: string): Frame
	local old = parent:FindFirstChild("ClassDecor")
	if old then
		old:Destroy()
	end
	local root = Instance.new("Frame")
	root.Name = "ClassDecor"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.ClipsDescendants = true
	root.ZIndex = parent.ZIndex + 1
	root.Active = false
	root.Parent = parent
	local stroke = parent:FindFirstChildOfClass("UIStroke")
	local bits = {}
	for _ = 1, 4 do
		table.insert(bits, bit(root, UDim2.fromOffset(8, 16)))
	end
	table.insert(entries, {
		classId = classId,
		root = root,
		bits = bits,
		stroke = stroke,
	})
	ensure()
	return root
end

return ClassDecor
