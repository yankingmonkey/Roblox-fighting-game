--!strict
-- Where a shot leaves the body. Two-handed moves use the point between the hands.
-- Eye beams use the head. The server uses this when the hit window opens.

local HandOrigin = {}

local function part(model: Model, name: string): BasePart?
	local found = model:FindFirstChild(name)
	if found and found:IsA("BasePart") then
		return found
	end
	return nil
end

function HandOrigin.From(character: Model, hands: string, fallback: BasePart): Vector3
	local right = part(character, "RightHand")
	local left = part(character, "LeftHand")
	local head = part(character, "Head")
	if hands == "head" and head then
		return head.Position + head.CFrame.LookVector * 0.45
	end
	if hands == "right" and right then
		return right.Position
	end
	if hands == "left" and left then
		return left.Position
	end
	if right and left then
		return (right.Position + left.Position) / 2
	end
	if right then
		return right.Position
	end
	return fallback.Position + Vector3.new(0, 1.2, 0)
end

return HandOrigin
