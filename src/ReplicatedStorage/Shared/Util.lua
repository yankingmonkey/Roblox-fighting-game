--!strict
-- Small helpers used by both the server and the client.

local Util = {}

function Util.ReadNumber(value: any, default: number): number
	if typeof(value) == "number" and value == value then
		return value
	end
	return default
end

function Util.ReadString(value: any, default: string): string
	if typeof(value) == "string" then
		return value
	end
	return default
end

function Util.Round(value: number, places: number): number
	local power = 10 ^ places
	return math.floor(value * power + 0.5) / power
end

-- Fan a direction into `count` rays. count 1 returns the direction unchanged.
function Util.SpreadDirections(direction: Vector3, count: number, spreadDeg: number): { Vector3 }
	local list: { Vector3 } = {}
	if direction.Magnitude < 0.001 then
		direction = Vector3.new(0, 0, -1)
	end
	local unit = direction.Unit
	if count <= 1 then
		table.insert(list, unit)
		return list
	end
	local spread = math.rad(spreadDeg)
	local base = CFrame.lookAt(Vector3.zero, unit)
	for index = 1, count do
		local alpha = (index - 1) / (count - 1) - 0.5
		local angled = base * CFrame.Angles(0, alpha * spread * 2, 0)
		table.insert(list, angled.LookVector)
	end
	return list
end

function Util.HumanoidModel(part: Instance): Model?
	local model = part:FindFirstAncestorOfClass("Model")
	if not model then
		return nil
	end
	if model:FindFirstChildOfClass("Humanoid") then
		return model
	end
	return nil
end

function Util.Root(model: Model): BasePart?
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	if model.PrimaryPart then
		return model.PrimaryPart
	end
	return nil
end

function Util.HeadPosition(model: Model): Vector3
	local head = model:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head.Position
	end
	local root = Util.Root(model)
	if root then
		return root.Position + Vector3.new(0, 1.5, 0)
	end
	return model:GetPivot().Position
end

return Util
