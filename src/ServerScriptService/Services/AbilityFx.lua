--!strict
-- What each ability actually does on the server. Ability modules pick a method
-- by name. Numbers come from Shared/Balance.lua.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local Balance = require(game:GetService("ReplicatedStorage").FightingClasses.Shared.Balance)
local MovementMath = require(game:GetService("ReplicatedStorage").FightingClasses.Shared.MovementMath)
local Types = require(game:GetService("ReplicatedStorage").FightingClasses.Shared.Types)
local Util = require(game:GetService("ReplicatedStorage").FightingClasses.Shared.Util)
local CombatService = require(script.Parent.CombatService)
local HitboxService = require(script.Parent.HitboxService)
local StatusService = require(script.Parent.StatusService)
local VfxRelay = require(script.Parent.VfxRelay)

type CastContext = Types.CastContext
type AbilityTuning = Types.AbilityTuning

local AbilityFx = {}

local function tuning(ctx: CastContext): AbilityTuning
	return Balance.Abilities[ctx.ability.id] or {}
end

local function casterOk(ctx: CastContext): boolean
	if not ctx.character.Parent or ctx.humanoid.Health <= 0 then
		return false
	end
	if ctx.character:GetAttribute("Stunned") == true then
		return false
	end
	return true
end

local function actorFolder(): Folder
	local existing = workspace:FindFirstChild("FightingClassActors")
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "FightingClassActors"
	folder.Parent = workspace
	return folder
end

local function spawnLog(position: Vector3)
	local log = Instance.new("Part")
	log.Name = "SubstitutionLog"
	log.Shape = Enum.PartType.Cylinder
	log.Size = Vector3.new(5, 1.5, 1.5)
	log.Color = Color3.fromRGB(122, 78, 42)
	log.Material = Enum.Material.Wood
	log.Anchored = true
	log.CanCollide = false
	log.CFrame = CFrame.new(position + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	log.Parent = actorFolder()
	Debris:AddItem(log, 2.5)
end

local function makeClone(name: string, color: Color3, position: Vector3, ownerUserId: number): Model
	local model = Instance.new("Model")
	model.Name = name

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.Anchored = true
	root.CFrame = CFrame.new(position)
	root.Parent = model

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Color = color
	torso.Material = Enum.Material.Neon
	torso.CanCollide = false
	torso.Anchored = true
	torso.CFrame = CFrame.new(position)
	torso.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.3, 1.3, 1.3)
	head.Color = color
	head.Material = Enum.Material.Neon
	head.CanCollide = false
	head.Anchored = true
	head.CFrame = CFrame.new(position + Vector3.new(0, 1.8, 0))
	head.Parent = model

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.DisplayName = "Clone"
	humanoid.NameDisplayDistance = 50
	humanoid.HealthDisplayDistance = 0
	humanoid.PlatformStand = true
	humanoid.AutoRotate = false
	-- Don't let the Humanoid fight the anchored parts. It is only here so hits can find it.
	humanoid.EvaluateStateMachine = false
	humanoid.Parent = model

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(90, 24)
	billboard.StudsOffset = Vector3.new(0, 3.2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = "Clone"
	label.Parent = billboard

	local highlight = Instance.new("Highlight")
	highlight.FillColor = color
	highlight.OutlineColor = color
	highlight.FillTransparency = 0.55
	highlight.Parent = model

	model.PrimaryPart = root
	model:SetAttribute("IsClone", true)
	model:SetAttribute("OwnerUserId", ownerUserId)
	model:SetAttribute("CloneAlive", true)
	model.Parent = actorFolder()
	return model
end

local function placeClone(model: Model, cframe: CFrame)
	model:PivotTo(cframe)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
end

function AbilityFx.Projectile(ctx: CastContext)
	local stats = tuning(ctx)
	local count = stats.projectiles or 1
	local directions = Util.SpreadDirections(ctx.direction, count, stats.spreadDeg or 0)
	for _, direction in directions do
		HitboxService.LaunchProjectile(ctx, direction, stats)
	end
	VfxRelay.Play(ctx, { vfx = "projectile" })
end

function AbilityFx.Beam(ctx: CastContext)
	local stats = tuning(ctx)
	local origin = Util.HeadPosition(ctx.character)
	local endPos = HitboxService.RayDamage(ctx, stats.damage or 0, stats, origin, ctx.direction, stats.range or 70)
	VfxRelay.Play(ctx, { vfx = "beam", origin = origin, endPosition = endPos })
end

function AbilityFx.ChannelBeam(ctx: CastContext)
	local stats = tuning(ctx)
	local ticks = stats.ticks or 1
	local interval = stats.tickInterval or 0.25
	local perTick = stats.damage or 0
	local sweep = stats.sweepDegrees
	local startLook = ctx.root.CFrame

	task.spawn(function()
		for tickIndex = 1, ticks do
			if not casterOk(ctx) then
				-- Stun (or death) cuts the beam off. Energy was already spent.
				VfxRelay.Stop(ctx)
				break
			end
			local origin = Util.HeadPosition(ctx.character)
			local direction: Vector3
			if sweep then
				local span = math.rad(sweep)
				local alpha = if ticks <= 1 then 0.5 else (tickIndex - 1) / (ticks - 1)
				local angle = -span / 2 + span * alpha
				direction = (startLook * CFrame.Angles(0, angle, 0)).LookVector
			else
				direction = ctx.root.CFrame.LookVector
			end
			local endPos = HitboxService.RayDamage(ctx, perTick, stats, origin, direction, stats.range or 70)
			VfxRelay.Play(ctx, {
				vfx = "beam",
				origin = origin,
				endPosition = endPos,
				castId = ctx.castId .. "-" .. tostring(tickIndex),
			})
			task.wait(interval)
		end
	end)
end

function AbilityFx.Melee(ctx: CastContext)
	local stats = tuning(ctx)
	if stats.superArmor and stats.superArmor > 0 then
		StatusService.ApplySuperArmor(ctx.character, stats.superArmor)
	end
	HitboxService.Melee(ctx, stats.damage or 0, stats, nil)
	VfxRelay.Play(ctx, { vfx = "melee" })
end

function AbilityFx.Flurry(ctx: CastContext)
	local stats = tuning(ctx)
	local hits = stats.hits or 1
	local perHit = stats.hitDamage or stats.damage or 0
	local fromPosition: Vector3? = nil
	if stats.distance and stats.distance > 0 then
		local goal = MovementMath.Compute(ctx.root, ctx.direction, ctx.moveDirection, stats.distance, "dash")
		ctx.move = { kind = "dash", position = goal.Position, look = goal.LookVector }
		fromPosition = goal.Position
	end
	VfxRelay.Play(ctx, { vfx = "flurry" })
	task.spawn(function()
		for _ = 1, hits do
			if not casterOk(ctx) then
				break
			end
			HitboxService.Melee(ctx, perHit, stats, fromPosition)
			task.wait(stats.tickInterval or 0.08)
		end
	end)
end

function AbilityFx.Aoe(ctx: CastContext)
	local stats = tuning(ctx)
	if stats.superArmor and stats.superArmor > 0 then
		StatusService.ApplySuperArmor(ctx.character, stats.superArmor)
	end
	HitboxService.Radius(ctx, stats.damage or 0, stats, ctx.root.Position)
	VfxRelay.Play(ctx, { vfx = "aoe" })
end

function AbilityFx.Cone(ctx: CastContext)
	local stats = tuning(ctx)
	HitboxService.Melee(ctx, stats.damage or 0, stats, nil)
	VfxRelay.Play(ctx, { vfx = "cone" })
end

function AbilityFx.Dash(ctx: CastContext)
	local stats = tuning(ctx)
	local mode = if stats.wall then "wall" elseif stats.dodge then "dodge" else "dash"
	local goal = MovementMath.Compute(ctx.root, ctx.direction, ctx.moveDirection, stats.distance or 16, mode)
	ctx.move = { kind = mode, position = goal.Position, look = goal.LookVector }
	if stats.iframe and stats.iframe > 0 then
		StatusService.ApplyIFrames(ctx.character, stats.iframe)
	end
	if stats.superArmor and stats.superArmor > 0 then
		StatusService.ApplySuperArmor(ctx.character, stats.superArmor)
	end
	if stats.damage and stats.damage > 0 then
		HitboxService.Path(ctx, stats.damage, stats, goal.Position)
	end
	if stats.leaveLog then
		spawnLog(ctx.root.Position)
	end
	VfxRelay.Play(ctx, { vfx = ctx.ability.vfx, endPosition = goal.Position })
end

function AbilityFx.Buff(ctx: CastContext)
	local stats = tuning(ctx)
	local duration = stats.buffDuration or stats.iframe or stats.superArmor or 1
	if stats.damageBuff then
		StatusService.ApplyDamageBuff(ctx.character, stats.damageBuff, stats.buffDuration or duration)
	end
	if stats.damageReduction then
		StatusService.ApplyReduction(ctx.character, stats.damageReduction, duration)
	end
	if stats.superArmor and stats.superArmor > 0 then
		StatusService.ApplySuperArmor(ctx.character, stats.superArmor)
	end
	if stats.iframe and stats.iframe > 0 then
		StatusService.ApplyIFrames(ctx.character, stats.iframe)
	end
	VfxRelay.Play(ctx, { vfx = "buff" })
end

function AbilityFx.ToggleFlight(ctx: CastContext): boolean?
	local stats = tuning(ctx)
	if ctx.character:GetAttribute("Flying") == true then
		ctx.character:SetAttribute("Flying", false)
		ctx.character:SetAttribute("Blocking", false)
		StatusService.RefreshMove(ctx.character)
		VfxRelay.Play(ctx, { vfx = "flight" })
		return nil
	end
	local energy = Util.ReadNumber(ctx.player:GetAttribute("Energy"), 0)
	if energy < (stats.minEnergy or 8) then
		ctx.failReason = "Not enough energy to take off."
		return false
	end
	ctx.character:SetAttribute("Blocking", false)
	ctx.character:SetAttribute("Flying", true)
	StatusService.RefreshMove(ctx.character)
	VfxRelay.Play(ctx, { vfx = "flight" })
	return nil
end

function AbilityFx.DiveBomb(ctx: CastContext)
	local stats = tuning(ctx)
	local ground, height = MovementMath.GroundBelow(ctx.root)
	local airborne = height >= (stats.heightNeeded or 12) or ctx.character:GetAttribute("Flying") == true
	local damage = if airborne then (stats.airDamage or stats.damage or 0) else (stats.damage or 0)
	if airborne then
		local look = MovementMath.FlatLook(ctx.root, ctx.direction)
		ctx.move = {
			kind = "dive",
			position = ground + Vector3.new(0, 3, 0),
			look = look,
		}
		ctx.character:SetAttribute("Flying", false)
	end
	HitboxService.Radius(ctx, damage, stats, ground + Vector3.new(0, 2, 0))
	VfxRelay.Play(ctx, { vfx = "dive", endPosition = ground })
end

local function nearestEnemy(owner: Player, fromPosition: Vector3): Model?
	local best: Model? = nil
	local bestDistance = 90
	for _, player in Players:GetPlayers() do
		if player ~= owner and player.Character then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			local root = Util.Root(player.Character)
			if humanoid and humanoid.Health > 0 and root then
				local distance = (root.Position - fromPosition).Magnitude
				if distance < bestDistance then
					best = player.Character
					bestDistance = distance
				end
			end
		end
	end
	return best
end

function AbilityFx.ShadowClone(ctx: CastContext)
	local stats = tuning(ctx)
	local lifetime = stats.cloneLifetime or 8
	local clone = makeClone("ShadowClone", ctx.ability.color, ctx.root.Position + ctx.root.CFrame.LookVector * 3, ctx.player.UserId)
	VfxRelay.Play(ctx, { vfx = "clone" })

	task.spawn(function()
		local elapsed = 0
		local nextHit = 0.4
		while clone.Parent and elapsed < lifetime and ctx.player.Parent do
			local dt = task.wait(0.2)
			elapsed += dt
			local root = Util.Root(clone)
			if not root then
				break
			end
			local target = nearestEnemy(ctx.player, root.Position)
			if target then
				local targetRoot = Util.Root(target)
				if targetRoot then
					local offset = Vector3.new(targetRoot.Position.X - root.Position.X, 0, targetRoot.Position.Z - root.Position.Z)
					if offset.Magnitude > 0.2 then
						local step = math.min(16 * dt, math.max(0, offset.Magnitude - 3.5))
						local nextPos = root.Position + offset.Unit * step
						placeClone(clone, CFrame.lookAt(nextPos, nextPos + offset))
						nextHit -= dt
						if nextHit <= 0 and offset.Magnitude <= (stats.range or 4.5) + 2 then
							nextHit = stats.tickInterval or 1.5
							CombatService.ApplyDamage(ctx.player, target, stats.damage or 8, {
								knockback = 8,
								origin = root.Position,
								abilityId = ctx.ability.id,
							})
						end
					end
				end
			end
		end
		if clone.Parent then
			clone:Destroy()
		end
	end)
end

function AbilityFx.CloneRush(ctx: CastContext)
	local stats = tuning(ctx)
	local count = stats.projectiles or 5
	local directions = Util.SpreadDirections(ctx.direction, count, 18)
	VfxRelay.Play(ctx, { vfx = "cloneRush" })

	for index, direction in directions do
		task.delay((index - 1) * 0.12, function()
			if not ctx.player.Parent then
				return
			end
			local flat = MovementMath.FlatLook(ctx.root, direction)
			local start = ctx.root.Position + flat * 2
			local clone = makeClone("RushClone", ctx.ability.color, start, ctx.player.UserId)
			task.spawn(function()
				local pos = start
				local traveled = 0
				local range = stats.range or 50
				local speed = stats.speed or 70
				while clone.Parent and traveled < range do
					local dt = task.wait()
					local step = math.min(speed * dt, range - traveled)
					local nextPos = pos + flat * step
					placeClone(clone, CFrame.lookAt(nextPos, nextPos + flat))
					pos = nextPos
					traveled += step
					local models = HitboxService.ModelsNear(ctx, pos, stats.radius or 3)
					local hit = false
					for _, model in models do
						if model ~= clone then
							CombatService.ApplyDamage(ctx.player, model, stats.damage or 16, {
								knockback = stats.knockback,
								origin = pos,
								abilityId = ctx.ability.id,
							})
							hit = true
						end
					end
					if hit then
						break
					end
				end
				if clone.Parent then
					clone:Destroy()
				end
			end)
		end)
	end
end

return AbilityFx
