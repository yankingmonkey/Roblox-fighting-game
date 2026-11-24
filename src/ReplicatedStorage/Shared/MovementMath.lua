--!strict
-- Movement destinations shared by the server (for damage) and the client (so the
-- dash you see matches the dash the server scored). The player owns their
-- character, so the client applies the CFrame. The server does not trust a
-- client-sent position; it recomputes one from the character and the aim vector.

local MovementMath = {}

function MovementMath.RayParams(ignore: Instance): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { ignore }
	return params
end

-- A zero vector is valid here: the character is standing still.
function MovementMath.SanitizeMove(direction: any): Vector3
	if typeof(direction) ~= "Vector3" or direction ~= direction or direction.Magnitude > 3 then
		return Vector3.zero
	end
	return direction
end

function MovementMath.SanitizeDirection(direction: any, fallback: Vector3): Vector3
	if typeof(direction) ~= "Vector3" or direction ~= direction then
		return if fallback.Magnitude > 0.001 then fallback.Unit else Vector3.new(0, 0, -1)
	end
	if direction.Magnitude < 0.05 or direction.Magnitude > 3 then
		return if fallback.Magnitude > 0.001 then fallback.Unit else Vector3.new(0, 0, -1)
	end
	return direction.Unit
end

function MovementMath.FlatLook(root: BasePart, direction: Vector3): Vector3
	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude < 0.05 then
		local look = root.CFrame.LookVector
		flat = Vector3.new(look.X, 0, look.Z)
	end
	if flat.Magnitude < 0.05 then
		return Vector3.new(0, 0, -1)
	end
	return flat.Unit
end

function MovementMath.GroundBelow(root: BasePart): (Vector3, number)
	local params = MovementMath.RayParams(root.Parent :: Instance)
	local result = workspace:Raycast(root.Position, Vector3.new(0, -500, 0), params)
	if not result then
		return root.Position, 0
	end
	return result.Position, root.Position.Y - result.Position.Y
end

local function liftAboveGround(root: BasePart, position: Vector3): Vector3
	local params = MovementMath.RayParams(root.Parent :: Instance)
	local result = workspace:Raycast(position + Vector3.new(0, 8, 0), Vector3.new(0, -40, 0), params)
	if not result then
		return position
	end
	local minY = result.Position.Y + 3
	if position.Y < minY then
		return Vector3.new(position.X, minY, position.Z)
	end
	return position
end

-- mode: "dash" stops before a wall, "wall" steps up a wall, "dodge" prefers
-- the movement keys and otherwise hops backward.
function MovementMath.Compute(root: BasePart, aim: Vector3, moveDirection: Vector3, distance: number, mode: string): CFrame
	local ignore = root.Parent :: Instance
	local params = MovementMath.RayParams(ignore)
	local flatAim = MovementMath.FlatLook(root, aim)

	local travelDir = flatAim
	if mode == "dodge" then
		local move = Vector3.new(moveDirection.X, 0, moveDirection.Z)
		if move.Magnitude > 0.2 then
			travelDir = move.Unit
		else
			travelDir = -flatAim
		end
	end

	local result = workspace:Raycast(root.Position, travelDir * distance, params)
	local destination = root.Position + travelDir * distance

	if result then
		local hitWall = result.Normal.Y < 0.45
		if mode == "wall" and hitWall then
			destination = result.Position + result.Normal * 3 + Vector3.new(0, 5, 0)
		else
			local travel = math.max(0, result.Distance - 3)
			destination = root.Position + travelDir * travel
		end
	end

	destination = liftAboveGround(root, destination)
	return CFrame.lookAt(destination, destination + travelDir)
end

return MovementMath
