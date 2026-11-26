--!strict
-- Turns a client aim point into a direction the server is willing to use.
-- The origin is always the character. A point that is too far away is ignored.

local AimRules = require(script.Parent.AimRules)

local AimMath = {}

local function finite(point: Vector3): boolean
	return point == point and math.abs(point.X) < 100000
end

function AimMath.Resolve(root: BasePart, maxRange: number, direction: any, aimPoint: any, ground: boolean): (Vector3, Vector3)
	local origin = root.Position + Vector3.new(0, 1.6, 0)
	local fallback = root.CFrame.LookVector
	if typeof(direction) == "Vector3" and finite(direction) and direction.Magnitude > 0.05 and direction.Magnitude < 4 then
		fallback = direction.Unit
	end
	local reach = math.max(maxRange, if ground then AimRules.PlaceRange else 8)
	local point = origin + fallback * reach
	if typeof(aimPoint) == "Vector3" and finite(aimPoint) then
		local offset = aimPoint - origin
		if offset.Magnitude > 0.4 and offset.Magnitude <= AimRules.MaxAimDistance then
			local dir = offset.Unit
			local dist = math.min(offset.Magnitude, reach)
			point = origin + dir * dist
			fallback = dir
		end
	end
	if ground then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		if root.Parent then
			params.FilterDescendantsInstances = { root.Parent }
		end
		local flat = Vector3.new(point.X - root.Position.X, 0, point.Z - root.Position.Z)
		if flat.Magnitude > AimRules.PlaceRange then
			flat = flat.Unit * AimRules.PlaceRange
		end
		local flatPoint = root.Position + flat
		local hit = workspace:Raycast(flatPoint + Vector3.new(0, 12, 0), Vector3.new(0, -80, 0), params)
		if hit then
			point = hit.Position
		else
			point = Vector3.new(flatPoint.X, root.Position.Y - 3, flatPoint.Z)
		end
		local face = point - origin
		if face.Magnitude > 0.2 then
			fallback = face.Unit
		end
	end
	return fallback, point
end

return AimMath
