--!strict
-- Hit detection. Never uses Touched.
--   * melee / cones / dash paths: GetPartBoundsInBox
--   * ground slams, bursts, explosions: GetPartsInPart on a temporary ball
--   * beams and fast projectiles: Raycast, plus GetPartBoundsInRadius so a thin
--     ray does not slip between a character's legs

local MovementMath = require(game:GetService("ReplicatedStorage").FightingClasses.Shared.MovementMath)
local Types = require(game:GetService("ReplicatedStorage").FightingClasses.Shared.Types)
local CombatService = require(script.Parent.CombatService)

type CastContext = Types.CastContext
type AbilityTuning = Types.AbilityTuning
type HitInfo = CombatService.HitInfo

local HitboxService = {}

local function characterFromPart(part: Instance): Model?
	local model = part:FindFirstAncestorOfClass("Model")
	if not model then
		return nil
	end
	if model:FindFirstChildOfClass("Humanoid") or model:GetAttribute("IsClone") == true then
		return model
	end
	return nil
end

local function excludeList(ctx: CastContext): { Instance }
	local list: { Instance } = { ctx.character }
	local folder = workspace:FindFirstChild("FightingClassActors")
	if folder then
		for _, child in folder:GetChildren() do
			if child:IsA("Model") and child:GetAttribute("OwnerUserId") == ctx.player.UserId then
				table.insert(list, child)
			end
		end
	end
	return list
end

local function uniqueModels(parts: { BasePart }, attacker: Model): { Model }
	local seen: { [Model]: boolean } = {}
	local models: { Model } = {}
	for _, part in parts do
		local model = characterFromPart(part)
		if model and model ~= attacker and not seen[model] then
			seen[model] = true
			table.insert(models, model)
		end
	end
	return models
end

local function makeInfo(ctx: CastContext, stats: AbilityTuning, origin: Vector3): HitInfo
	return {
		stun = stats.stun,
		slow = stats.slow,
		slowDuration = stats.slowDuration,
		knockback = stats.knockback,
		origin = origin,
		abilityId = ctx.ability.id,
	}
end

function HitboxService.ModelsInBox(ctx: CastContext, cframe: CFrame, size: Vector3): { Model }
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = excludeList(ctx)
	params.MaxParts = 40
	return uniqueModels(workspace:GetPartBoundsInBox(cframe, size, params), ctx.character)
end

function HitboxService.ModelsNear(ctx: CastContext, position: Vector3, radius: number): { Model }
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = excludeList(ctx)
	params.MaxParts = 20
	return uniqueModels(workspace:GetPartBoundsInRadius(position, radius, params), ctx.character)
end

function HitboxService.ModelsInRadius(ctx: CastContext, position: Vector3, radius: number): { Model }
	-- Sphere probe so area attacks use GetPartsInPart, not a touch event.
	local probe = Instance.new("Part")
	probe.Name = "HitProbe"
	probe.Shape = Enum.PartType.Ball
	probe.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
	probe.CFrame = CFrame.new(position)
	probe.Anchored = true
	probe.CanCollide = false
	probe.CanQuery = false
	probe.Transparency = 1
	probe.Parent = workspace

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local filter = excludeList(ctx)
	table.insert(filter, probe)
	params.FilterDescendantsInstances = filter
	params.MaxParts = 40
	local parts = workspace:GetPartsInPart(probe, params)
	probe:Destroy()
	return uniqueModels(parts, ctx.character)
end

function HitboxService.DamageModels(ctx: CastContext, models: { Model }, damage: number, stats: AbilityTuning, origin: Vector3)
	if damage <= 0 then
		return
	end
	local info = makeInfo(ctx, stats, origin)
	for _, model in models do
		CombatService.ApplyDamage(ctx.player, model, damage, info)
	end
end

function HitboxService.Melee(ctx: CastContext, damage: number, stats: AbilityTuning, fromPosition: Vector3?)
	local range = stats.range or 7
	local width = stats.width or 6
	local flat = MovementMath.FlatLook(ctx.root, ctx.direction)
	local origin = fromPosition or ctx.root.Position
	local center = origin + flat * (range / 2)
	local cframe = CFrame.lookAt(center, center + flat)
	local size = Vector3.new(width, 6.5, math.max(range, 1))
	local models = HitboxService.ModelsInBox(ctx, cframe, size)
	HitboxService.DamageModels(ctx, models, damage, stats, origin)
end

function HitboxService.Path(ctx: CastContext, damage: number, stats: AbilityTuning, destination: Vector3)
	local width = stats.width or 5
	local startPos = ctx.root.Position
	local delta = destination - startPos
	local flat = Vector3.new(delta.X, 0, delta.Z)
	local distance = math.max(flat.Magnitude, 1)
	if flat.Magnitude < 0.05 then
		flat = MovementMath.FlatLook(ctx.root, ctx.direction)
	else
		flat = flat.Unit
	end
	local center = startPos + flat * (distance / 2)
	local cframe = CFrame.lookAt(center, center + flat)
	local size = Vector3.new(width, 6.5, distance)
	local models = HitboxService.ModelsInBox(ctx, cframe, size)
	HitboxService.DamageModels(ctx, models, damage, stats, startPos)
end

function HitboxService.Radius(ctx: CastContext, damage: number, stats: AbilityTuning, position: Vector3)
	local radius = stats.explosiveRadius or stats.radius or 12
	local models = HitboxService.ModelsInRadius(ctx, position, radius)
	HitboxService.DamageModels(ctx, models, damage, stats, position)
end

function HitboxService.RayDamage(ctx: CastContext, damage: number, stats: AbilityTuning, origin: Vector3, direction: Vector3, range: number): Vector3
	local dir = if direction.Magnitude > 0.001 then direction.Unit else ctx.root.CFrame.LookVector
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = excludeList(ctx)
	local result = workspace:Raycast(origin, dir * range, params)
	local endPos = origin + dir * range
	if result then
		endPos = result.Position
		local model = characterFromPart(result.Instance)
		if model and damage > 0 then
			CombatService.ApplyDamage(ctx.player, model, damage, makeInfo(ctx, stats, origin))
		end
	end
	return endPos
end

function HitboxService.LaunchProjectile(ctx: CastContext, direction: Vector3, stats: AbilityTuning)
	local speed = stats.speed or 120
	local range = stats.range or 60
	local radius = stats.radius or 2
	local explosive = stats.explosiveRadius or 0
	local damage = stats.damage or 0
	local dir = if direction.Magnitude > 0.001 then direction.Unit else Vector3.new(0, 0, -1)

	task.spawn(function()
		local pos = ctx.origin
		local traveled = 0
		local lived = 0
		local resolved = false

		local function resolve(hitPos: Vector3, direct: Model?)
			if resolved then
				return
			end
			resolved = true
			if explosive > 0 then
				HitboxService.Radius(ctx, damage, stats, hitPos)
			elseif direct and damage > 0 then
				CombatService.ApplyDamage(ctx.player, direct, damage, makeInfo(ctx, stats, hitPos))
			end
		end

		while not resolved and traveled < range and lived < 8 do
			local dt = task.wait()
			lived += dt
			local step = math.min(speed * dt, range - traveled)
			if step <= 0 then
				break
			end
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = excludeList(ctx)
			local wall = workspace:Raycast(pos, dir * step, params)
			local hitPos = pos + dir * step
			local hitDistance = step
			if wall then
				hitPos = wall.Position
				hitDistance = wall.Distance
				resolve(hitPos, characterFromPart(wall.Instance))
			else
				local overlap = OverlapParams.new()
				overlap.FilterType = Enum.RaycastFilterType.Exclude
				overlap.FilterDescendantsInstances = excludeList(ctx)
				overlap.MaxParts = 20
				local parts = workspace:GetPartBoundsInRadius(hitPos, radius, overlap)
				local models = uniqueModels(parts, ctx.character)
				if #models > 0 then
					resolve(hitPos, models[1])
				end
			end
			pos = hitPos
			traveled += hitDistance
		end

		if not resolved and explosive > 0 then
			resolve(pos, nil)
		end
	end)
end

return HitboxService
