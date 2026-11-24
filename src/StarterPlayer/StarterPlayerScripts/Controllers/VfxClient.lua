--!strict
-- Placeholder effects made of neon parts, Beams, and ParticleEmitters.
-- The casting player plays these immediately. Everyone else plays them when
-- the server says the cast was real. Debris removes the parts.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local Replicated = game:GetService("ReplicatedStorage").FightingClasses
local AbilityRegistry = require(Replicated.Shared.AbilityRegistry)
local Balance = require(Replicated.Shared.Balance)
local Util = require(Replicated.Shared.Util)

local player = Players.LocalPlayer

type Track = {
	cancelled: boolean,
	parts: { Instance },
	stop: (() -> ())?,
}

local tracks: { [string]: Track } = {}

local VfxClient = {}

local function folder(): Folder
	local existing = workspace:FindFirstChild("FightingClassVfx")
	if existing and existing:IsA("Folder") then
		return existing
	end
	local created = Instance.new("Folder")
	created.Name = "FightingClassVfx"
	created.Parent = workspace
	return created
end

local function track(castId: string?): Track?
	if not castId or castId == "" then
		return nil
	end
	local item = tracks[castId]
	if not item then
		item = { cancelled = false, parts = {} }
		tracks[castId] = item
	end
	return item
end

local function own(castId: string?, instance: Instance)
	local item = track(castId)
	if item then
		table.insert(item.parts, instance)
	end
end

local function neon(size: Vector3, color: Color3, cframe: CFrame, life: number, castId: string?): Part
	local part = Instance.new("Part")
	part.Name = "AbilityVfx"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Size = size
	part.CFrame = cframe
	part.Parent = folder()
	Debris:AddItem(part, life)
	own(castId, part)
	return part
end

local function sparks(part: BasePart, color: Color3)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.tex"
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.85
	emitter.Lifetime = NumberRange.new(0.12, 0.35)
	emitter.Speed = NumberRange.new(2, 8)
	emitter.Rate = 40
	emitter.SpreadAngle = Vector2.new(40, 40)
	emitter.Parent = part
	task.delay(0.12, function()
		if emitter.Parent then
			emitter.Enabled = false
		end
	end)
end

local function showBeam(a: Vector3, b: Vector3, color: Color3, life: number, thickness: number, castId: string?)
	local distance = math.max((b - a).Magnitude, 0.2)
	local part = neon(Vector3.new(thickness, thickness, distance), color, CFrame.lookAt(a, b) * CFrame.new(0, 0, -distance / 2), life, castId)
	part.Transparency = 0.15

	local attachment0 = Instance.new("Attachment")
	attachment0.Position = Vector3.new(0, 0, distance / 2)
	attachment0.Parent = part
	local attachment1 = Instance.new("Attachment")
	attachment1.Position = Vector3.new(0, 0, -distance / 2)
	attachment1.Parent = part

	local beam = Instance.new("Beam")
	beam.Attachment0 = attachment0
	beam.Attachment1 = attachment1
	beam.Color = ColorSequence.new(color)
	beam.Width0 = thickness * 1.4
	beam.Width1 = thickness * 0.35
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.Transparency = NumberSequence.new(0.1)
	beam.Texture = "rbxasset://textures/particles/sparkles_main.tex"
	beam.TextureSpeed = 2
	beam.Parent = part
end

local function playAnimation(character: Model, animationId: string)
	if animationId == "" then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		local created = Instance.new("Animator")
		created.Parent = humanoid
		animator = created
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	local ok, trackOrErr = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if ok and trackOrErr then
		trackOrErr:Play()
	end
end

local function rayEnd(origin: Vector3, direction: Vector3, range: number, ignore: Instance?): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	if ignore then
		params.FilterDescendantsInstances = { ignore }
	end
	local result = workspace:Raycast(origin, direction * range, params)
	if result then
		return result.Position
	end
	return origin + direction * range
end

local function projectile(origin: Vector3, direction: Vector3, color: Color3, speed: number, range: number, radius: number, castId: string?, ignore: Instance?)
	if direction.Magnitude < 0.001 then
		return
	end
	local unit = direction.Unit
	local part = neon(Vector3.new(radius, radius, radius), color, CFrame.new(origin), range / math.max(speed, 1) + 0.25, castId)
	part.Shape = Enum.PartType.Ball
	sparks(part, color)
	task.spawn(function()
		local pos = origin
		local traveled = 0
		while part.Parent and traveled < range do
			local item = if castId then tracks[castId] else nil
			if item and item.cancelled then
				break
			end
			local dt = task.wait()
			local step = speed * dt
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			if ignore then
				params.FilterDescendantsInstances = { ignore }
			end
			local hit = workspace:Raycast(pos, unit * step, params)
			if hit then
				part.Position = hit.Position
				break
			end
			pos += unit * step
			traveled += step
			part.Position = pos
		end
		if part.Parent then
			sparks(part, color)
			part.Transparency = 1
			Debris:AddItem(part, 0.2)
		end
	end)
end

local function playKind(payload: { [string]: any }, predicted: boolean)
	local abilityId = payload.abilityId
	if typeof(abilityId) ~= "string" then
		return
	end
	local ability = AbilityRegistry.Get(abilityId)
	if not ability then
		return
	end
	local stats = Balance.Abilities[abilityId]
	local castId = if typeof(payload.castId) == "string" then payload.castId else nil
	local origin = if typeof(payload.origin) == "Vector3" then payload.origin else Vector3.zero
	local direction = if typeof(payload.direction) == "Vector3" then payload.direction else Vector3.new(0, 0, -1)
	local vfx = if typeof(payload.vfx) == "string" then payload.vfx else ability.vfx
	local color = ability.color

	local casterCharacter: Model? = nil
	if typeof(payload.casterUserId) == "number" then
		local caster = Players:GetPlayerByUserId(payload.casterUserId)
		if caster then
			casterCharacter = caster.Character
		end
	elseif predicted then
		casterCharacter = player.Character
	end
	if casterCharacter then
		playAnimation(casterCharacter, ability.animationId)
	end

	if vfx == "projectile" then
		local count = if stats then stats.projectiles or 1 else 1
		local spread = if stats then stats.spreadDeg or 0 else 0
		local speed = if stats then stats.speed or 120 else 120
		local range = if stats then stats.range or ability.range else ability.range
		local radius = if stats then (stats.radius or 2) * 1.1 else 2
		local directions = Util.SpreadDirections(direction, count, spread)
		for _, shot in directions do
			projectile(origin, shot, color, speed, range, radius, castId, casterCharacter)
		end
	elseif vfx == "beam" then
		local endPosition = payload.endPosition
		local from = if typeof(payload.origin) == "Vector3" then payload.origin else origin
		local to = if typeof(endPosition) == "Vector3"
			then endPosition
			else rayEnd(from, direction, ability.range, casterCharacter)
		showBeam(from, to, color, 0.28, 0.45, castId)
	elseif vfx == "channelBeam" or (predicted and (ability.vfx == "channelBeam")) then
		local ticks = if stats then stats.ticks or 1 else 1
		local interval = if stats then stats.tickInterval or 0.25 else 0.25
		local range = if stats then stats.range or ability.range else ability.range
		local sweep = if stats then stats.sweepDegrees else nil
		local item = track(castId)
		task.spawn(function()
			local startPivot = if casterCharacter then casterCharacter:GetPivot() else CFrame.new()
			for tickIndex = 1, ticks do
				if item and item.cancelled then
					break
				end
				local character = casterCharacter
				if not character or not character.Parent or character:GetAttribute("Stunned") == true then
					break
				end
				local from = Util.HeadPosition(character)
				local aim: Vector3
				if sweep then
					local span = math.rad(sweep)
					local alpha = if ticks <= 1 then 0.5 else (tickIndex - 1) / (ticks - 1)
					aim = (startPivot * CFrame.Angles(0, -span / 2 + span * alpha, 0)).LookVector
				else
					local root = Util.Root(character)
					aim = if root then root.CFrame.LookVector else direction
				end
				showBeam(from, rayEnd(from, aim, range, character), color, interval + 0.08, 0.55, nil)
				task.wait(interval)
			end
		end)
	elseif vfx == "melee" or vfx == "flurry" then
		local root = if casterCharacter then Util.Root(casterCharacter) else nil
		local look = if root then root.CFrame.LookVector else direction
		local at = if root then root.Position + look * 3 else origin
		local flashes = if vfx == "flurry" then 4 else 1
		task.spawn(function()
			for _ = 1, flashes do
				local item = if castId then tracks[castId] else nil
				if item and item.cancelled then
					break
				end
				local part = neon(Vector3.new(4.5, 1.2, 2.2), color, CFrame.lookAt(at, at + look), 0.12, castId)
				sparks(part, color)
				task.wait(0.08)
			end
		end)
	elseif vfx == "aoe" or vfx == "dive" then
		local at = origin
		if typeof(payload.endPosition) == "Vector3" then
			at = payload.endPosition
		end
		local radius = if stats then (stats.explosiveRadius or stats.radius or 12) else 12
		local part = neon(Vector3.new(2, 2, 2), color, CFrame.new(at), 0.35, castId)
		part.Shape = Enum.PartType.Ball
		sparks(part, color)
		task.spawn(function()
			local grew = 0
			while part.Parent and grew < 1 do
				grew += task.wait() * 6
				local size = math.clamp(grew, 0.2, 1) * radius * 2
				part.Size = Vector3.new(size, size, size)
				part.Transparency = grew * 0.7
			end
		end)
	elseif vfx == "cone" then
		local root = if casterCharacter then Util.Root(casterCharacter) else nil
		local look = if root then Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z) else direction
		if look.Magnitude < 0.05 then
			look = direction
		end
		look = look.Unit
		local from = if root then root.Position else origin
		local length = if stats then stats.range or 18 else 18
		local part = neon(Vector3.new(6, 3, length), color, CFrame.lookAt(from, from + look) * CFrame.new(0, 0, -length / 2), 0.25, castId)
		part.Transparency = 0.35
		sparks(part, color)
	elseif vfx == "dash" or vfx == "blink" then
		local root = if casterCharacter then Util.Root(casterCharacter) else nil
		local from = if root then root.Position else origin
		local to = if typeof(payload.endPosition) == "Vector3" then payload.endPosition else from + direction * 12
		showBeam(from, to, color, 0.2, 0.35, castId)
		neon(Vector3.new(2, 3, 2), color, CFrame.new(from), 0.25, castId)
	elseif vfx == "buff" or vfx == "flight" or vfx == "clone" or vfx == "cloneRush" then
		local root = if casterCharacter then Util.Root(casterCharacter) else nil
		local at = if root then root.Position else origin
		local part = neon(Vector3.new(3, 5, 3), color, CFrame.new(at), 0.35, castId)
		part.Transparency = 0.45
		sparks(part, color)
	end
end

function VfxClient.Predict(abilityId: string, origin: Vector3, direction: Vector3, castId: string)
	playKind({
		abilityId = abilityId,
		origin = origin,
		direction = direction,
		castId = castId,
		vfx = nil,
	}, true)
end

function VfxClient.Play(payload: { [string]: any })
	-- A channel cast predicts its own looping beam. Per-tick beams still arrive
	-- for everyone else. The caster ignores the echo of their own cast id.
	local castId = payload.castId
	if typeof(castId) == "string" and tracks[castId] and payload.casterUserId == player.UserId then
		return
	end
	playKind(payload, false)
end

function VfxClient.Stop(castId: string)
	local item = tracks[castId]
	if not item then
		return
	end
	item.cancelled = true
	for _, instance in item.parts do
		instance:Destroy()
	end
	tracks[castId] = nil
end

local function watchCharacter(character: Model)
	local highlight = Instance.new("Highlight")
	highlight.Name = "StateHighlight"
	highlight.FillTransparency = 0.7
	highlight.OutlineTransparency = 0.2
	highlight.Enabled = false
	highlight.Parent = character

	local function refresh()
		if character:GetAttribute("Stunned") == true then
			highlight.Enabled = true
			highlight.FillColor = Color3.fromRGB(186, 92, 255)
			highlight.OutlineColor = highlight.FillColor
		elseif character:GetAttribute("IFrames") == true then
			highlight.Enabled = true
			highlight.FillColor = Color3.fromRGB(245, 245, 255)
			highlight.OutlineColor = highlight.FillColor
		elseif character:GetAttribute("Flying") == true then
			highlight.Enabled = true
			highlight.FillColor = Color3.fromRGB(230, 60, 80)
			highlight.OutlineColor = highlight.FillColor
		elseif character:GetAttribute("SuperArmor") == true then
			highlight.Enabled = true
			highlight.FillColor = Color3.fromRGB(255, 140, 50)
			highlight.OutlineColor = highlight.FillColor
		elseif character:GetAttribute("Blocking") == true then
			highlight.Enabled = true
			highlight.FillColor = Color3.fromRGB(70, 140, 255)
			highlight.OutlineColor = highlight.FillColor
		else
			local buff = character:GetAttribute("DamageBuff")
			if typeof(buff) == "number" and buff > 1 then
				highlight.Enabled = true
				highlight.FillColor = Color3.fromRGB(80, 200, 255)
				highlight.OutlineColor = highlight.FillColor
			else
				highlight.Enabled = false
			end
		end
	end

	for _, name in { "Stunned", "IFrames", "Flying", "SuperArmor", "Blocking", "DamageBuff" } do
		character:GetAttributeChangedSignal(name):Connect(refresh)
	end
	refresh()
end

function VfxClient.Start()
	local function hook(target: Player)
		target.CharacterAdded:Connect(watchCharacter)
		if target.Character then
			watchCharacter(target.Character)
		end
	end
	Players.PlayerAdded:Connect(hook)
	for _, target in Players:GetPlayers() do
		hook(target)
	end
end

return VfxClient
