--!strict
-- Class looks. The server only says what was cast. This module draws it for
-- every client, including the person who pressed the key.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Replicated = game:GetService("ReplicatedStorage").FightingClasses
local AbilityRegistry = require(Replicated.Shared.AbilityRegistry)
local Balance = require(Replicated.Shared.Balance)
local Classes = require(Replicated.Shared.Classes)
local Util = require(Replicated.Shared.Util)
local VfxKit = require(script.Parent.VfxKit)

local VfxThemes = {}

local FIRE = { FireBolt = true, FlameWave = true, EmberBurst = true, InfernoColumn = true }
local ICE = { IceShard = true, FrostBurst = true, HailVolley = true }
local BOLT = { LightningSpike = true, StormCage = true }

local function elementColor(abilityId: string, fallback: Color3): Color3
	if FIRE[abilityId] then
		return Color3.fromRGB(255, 110, 40)
	elseif ICE[abilityId] then
		return Color3.fromRGB(150, 220, 255)
	elseif BOLT[abilityId] then
		return Color3.fromRGB(230, 230, 90)
	elseif abilityId == "GalePush" then
		return Color3.fromRGB(200, 230, 220)
	end
	return fallback
end

local function rayEnd(origin: Vector3, direction: Vector3, range: number, ignore: Instance?): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	if ignore then
		params.FilterDescendantsInstances = { ignore }
	end
	local unit = if direction.Magnitude > 0.05 then direction.Unit else Vector3.new(0, 0, -1)
	local result = workspace:Raycast(origin, unit * range, params)
	if result then
		return result.Position
	end
	return origin + unit * range
end

local function launchOrb(origin: Vector3, direction: Vector3, color: Color3, speed: number, range: number, radius: number, style: string, ignore: Instance?)
	if direction.Magnitude < 0.05 then
		return
	end
	local unit = direction.Unit
	local orb = if style == "shuriken"
		then VfxKit.Shuriken(origin, unit, color, range / speed + 0.3)
		else VfxKit.Orb(origin, color, radius, range / speed + 0.3)
	if style == "fire" then
		VfxKit.Emit(orb, VfxKit.Texture.Fire, color, 40, NumberRange.new(0.15, 0.35), NumberRange.new(1, 3), 0.8)
	elseif style == "ice" then
		VfxKit.Emit(orb, VfxKit.Texture.Spark, Color3.fromRGB(220, 245, 255), 20, NumberRange.new(0.2, 0.4), NumberRange.new(1, 3), 0.4)
	end
	local attachment0 = Instance.new("Attachment")
	attachment0.Parent = orb
	local attachment1 = Instance.new("Attachment")
	attachment1.Position = Vector3.new(0, 0, -radius)
	attachment1.Parent = orb
	local trail = Instance.new("Trail")
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Color = ColorSequence.new(color)
	trail.LightEmission = 0.8
	trail.Lifetime = 0.18
	trail.Parent = orb
	task.spawn(function()
		local pos = origin
		local traveled = 0
		while orb.Parent and traveled < range do
			local dt = task.wait()
			local step = speed * dt
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			if ignore then
				params.FilterDescendantsInstances = { ignore }
			end
			local hit = workspace:Raycast(pos, unit * step, params)
			if hit then
				orb.Position = hit.Position
				VfxKit.Burst(hit.Position, color, if style == "fire" then VfxKit.Texture.Fire else VfxKit.Texture.Spark, 10, 0.3)
				break
			end
			pos += unit * step
			traveled += step
			orb.CFrame = CFrame.lookAt(pos, pos + unit) * CFrame.Angles(0, traveled * 12, 0)
		end
		if orb.Parent then
			orb.Transparency = 1
			Debris:AddItem(orb, 0.15)
		end
	end)
end

local function beamLook(classId: string, abilityId: string, from: Vector3, to: Vector3, color: Color3)
	if classId == "Speedster" or BOLT[abilityId] then
		VfxKit.Bolt(from, to, color, 0.22, 2.4)
	elseif classId == "Superhero" then
		local origin = from
		VfxKit.Segment(origin, to, Color3.fromRGB(255, 40, 50), 0.28, 0.28, 0.02)
		VfxKit.Segment(origin, to, Color3.fromRGB(255, 170, 160), 0.9, 0.28, 0.55)
		VfxKit.Burst(origin, Color3.fromRGB(255, 60, 70), VfxKit.Texture.Spark, 6, 0.15)
	elseif classId == "KiWarrior" then
		VfxKit.SwirlBeam(from, to, color, 0.32)
	else
		VfxKit.SwirlBeam(from, to, color, 0.28)
	end
end

local function aoeLook(classId: string, abilityId: string, position: Vector3, color: Color3, radius: number)
	if classId == "Brawler" or abilityId == "HeroSlam" or abilityId == "QuakeLine" then
		VfxKit.Shockwave(position, color, radius, 0.4)
		VfxKit.Cracks(position, color, radius * 0.7, 0.7)
		VfxKit.Burst(position, color, VfxKit.Texture.Smoke, 16, 0.5)
	elseif FIRE[abilityId] or abilityId == "SolarFlare" then
		VfxKit.Shockwave(position, color, radius, 0.35)
		VfxKit.Burst(position, color, VfxKit.Texture.Fire, 24, 0.5)
	elseif ICE[abilityId] then
		VfxKit.Shockwave(position, color, radius, 0.4)
		for index = 1, 5 do
			local angle = math.rad(index * 72)
			local spot = position + Vector3.new(math.cos(angle), 0, math.sin(angle)) * (radius * 0.45)
			local shard = VfxKit.Part(Vector3.new(0.4, 2.2, 0.4), color, CFrame.new(spot) * CFrame.Angles(0.2, angle, 0.4), 0.6)
			TweenService:Create(shard, TweenInfo.new(0.5), { Transparency = 1, Size = Vector3.new(0.1, 0.4, 0.1) }):Play()
		end
	elseif classId == "Ninja" or abilityId == "SmokeVeil" then
		VfxKit.Burst(position, Color3.fromRGB(40, 40, 48), VfxKit.Texture.Smoke, 28, 0.7)
		VfxKit.Shockwave(position, color, radius * 0.6, 0.35)
	elseif classId == "Speedster" then
		VfxKit.Bolt(position, position + Vector3.new(0, 8, 0), color, 0.25, 1.2)
		VfxKit.Shockwave(position, color, radius, 0.3)
	else
		VfxKit.Shockwave(position, color, radius, 0.35)
		VfxKit.Burst(position, color, VfxKit.Texture.Spark, 14, 0.35)
	end
end

function VfxThemes.Play(payload: { [string]: any }, predicted: boolean)
	local abilityId = payload.abilityId
	if typeof(abilityId) ~= "string" then
		return
	end
	local ability = AbilityRegistry.Get(abilityId)
	local classId = if ability then ability.classId else "KiWarrior"
	if abilityId == "CombatDash" then
		classId = "Speedster"
	end
	local color = if ability then ability.color else Color3.fromRGB(255, 255, 255)
	color = elementColor(abilityId, color)
	local stats = Balance.Abilities[abilityId]
	local vfx = if typeof(payload.vfx) == "string" then payload.vfx else if ability then ability.vfx else "projectile"
	local origin = if typeof(payload.origin) == "Vector3" then payload.origin else Vector3.zero
	local direction = if typeof(payload.direction) == "Vector3" then payload.direction else Vector3.new(0, 0, -1)

	local caster: Model? = nil
	if typeof(payload.casterUserId) == "number" then
		local player = Players:GetPlayerByUserId(payload.casterUserId)
		caster = if player then player.Character else nil
	elseif predicted then
		caster = Players.LocalPlayer.Character
	end
	if caster and ability and ability.animationId ~= "" then
		local humanoid = caster:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		if humanoid and animator then
			local animation = Instance.new("Animation")
			animation.AnimationId = ability.animationId
			local ok, track = pcall(function()
				return animator:LoadAnimation(animation)
			end)
			if ok and track then
				track:Play()
			end
		end
	end

	if vfx == "projectile" then
		local count = if stats then stats.projectiles or 1 else 1
		local spread = if stats then stats.spreadDeg or 0 else 0
		local speed = if stats then stats.speed or 120 else 120
		local range = if stats then stats.range or 60 else 60
		local radius = if stats then stats.radius or 2 else 2
		local style = if classId == "Ninja" then "shuriken" elseif FIRE[abilityId] then "fire" elseif ICE[abilityId] then "ice" else "ki"
		for _, shot in Util.SpreadDirections(direction, count, spread) do
			launchOrb(origin, shot, color, speed, range, radius, style, caster)
		end
	elseif vfx == "beam" or vfx == "channelBeam" then
		local from = if typeof(payload.origin) == "Vector3" then payload.origin else origin
		if caster and (classId == "Superhero" or vfx == "channelBeam") then
			from = Util.HeadPosition(caster)
		end
		local ending = payload.endPosition
		local to = if typeof(ending) == "Vector3" then ending else rayEnd(from, direction, if stats then stats.range or 70 else 70, caster)
		if vfx == "channelBeam" and predicted then
			return
		end
		beamLook(classId, abilityId, from, to, color)
	elseif vfx == "melee" or vfx == "flurry" then
		local root = if caster then Util.Root(caster) else nil
		local look = if root then root.CFrame.LookVector else direction
		local at = if root then root.Position + look * 3 else origin
		local flashes = if vfx == "flurry" then 4 else 1
		task.spawn(function()
			for _ = 1, flashes do
				if classId == "Speedster" then
					VfxKit.Bolt(at, at + look * 3, color, 0.12, 0.8)
				elseif classId == "Brawler" then
					VfxKit.Shockwave(at, color, 4, 0.18)
				else
					VfxKit.Burst(at, color, VfxKit.Texture.Spark, 8, 0.15)
				end
				task.wait(0.08)
			end
		end)
	elseif vfx == "aoe" or vfx == "dive" or vfx == "cone" or vfx == "smoke" then
		local at = origin
		if typeof(payload.endPosition) == "Vector3" then
			at = payload.endPosition
		elseif caster then
			local root = Util.Root(caster)
			if root then
				at = root.Position
			end
		end
		local radius = if stats then (stats.explosiveRadius or stats.radius or stats.range or 12) else 12
		aoeLook(classId, abilityId, at, color, radius)
		if vfx == "dive" then
			VfxKit.Cracks(at, color, radius, 0.8)
			VfxKit.Shake(0.6)
		end
	elseif vfx == "dash" or vfx == "blink" then
		local root = if caster then Util.Root(caster) else nil
		local from = if root then root.Position else origin
		local ending = payload.endPosition
		local to = if typeof(ending) == "Vector3" then ending else from + direction.Unit * 12
		if classId == "Speedster" or abilityId == "CombatDash" then
			VfxKit.Bolt(from, to, color, 0.2, 1.4)
		elseif classId == "Ninja" then
			VfxKit.Burst(from, Color3.fromRGB(30, 30, 36), VfxKit.Texture.Smoke, 16, 0.4)
		elseif classId == "Superhero" then
			VfxKit.Shockwave(from, color, 8, 0.25)
		else
			VfxKit.SwirlBeam(from, to, color, 0.2)
		end
		if caster then
			VfxKit.Afterimage(caster, color)
		end
	elseif vfx == "buff" or vfx == "flight" or vfx == "clone" or vfx == "cloneRush" then
		local root = if caster then Util.Root(caster) else nil
		local at = if root then root.Position else origin
		if classId == "KiWarrior" then
			local aura = VfxKit.Orb(at, color, 5, 0.6)
			aura.Transparency = 0.55
			VfxKit.Emit(aura, VfxKit.Texture.Spark, color, 50, NumberRange.new(0.3, 0.6), NumberRange.new(2, 5), 0.5)
		elseif classId == "Ninja" then
			VfxKit.Burst(at, Color3.fromRGB(40, 40, 48), VfxKit.Texture.Smoke, 22, 0.6)
		else
			VfxKit.Shockwave(at, color, 7, 0.3)
			VfxKit.Burst(at, color, VfxKit.Texture.Spark, 12, 0.3)
		end
	end
end

function VfxThemes.Channel(abilityId: string, caster: Model, _castId: string, cancelled: () -> boolean)
	local ability = AbilityRegistry.Get(abilityId)
	if not ability then
		return
	end
	local stats = Balance.Abilities[abilityId]
	local ticks = if stats then stats.ticks or 1 else 1
	local interval = if stats then stats.tickInterval or 0.25 else 0.25
	local range = if stats then stats.range or 70 else 70
	local sweep = if stats then stats.sweepDegrees else nil
	local color = elementColor(abilityId, ability.color)
	task.spawn(function()
		local startPivot = caster:GetPivot()
		for tickIndex = 1, ticks do
			if cancelled() or not caster.Parent or caster:GetAttribute("Stunned") == true then
				break
			end
			local from = Util.HeadPosition(caster)
			local aim: Vector3
			if sweep then
				local span = math.rad(sweep)
				local alpha = if ticks <= 1 then 0.5 else (tickIndex - 1) / (ticks - 1)
				aim = (startPivot * CFrame.Angles(0, -span / 2 + span * alpha, 0)).LookVector
			else
				local root = Util.Root(caster)
				aim = if root then root.CFrame.LookVector else Vector3.new(0, 0, -1)
			end
			beamLook(ability.classId, abilityId, from, rayEnd(from, aim, range, caster), color)
			task.wait(interval)
		end
	end)
end

function VfxThemes.Impact(payload: { [string]: any })
	local position = payload.position
	if typeof(position) ~= "Vector3" then
		return
	end
	local classId = if typeof(payload.classId) == "string" then payload.classId else ""
	local info = Classes.ById[classId]
	local color = if info then info.color else Color3.fromRGB(255, 230, 160)
	local abilityId = if typeof(payload.abilityId) == "string" then payload.abilityId else ""
	color = elementColor(abilityId, color)
	local heavy = payload.heavy == true
	if classId == "Speedster" then
		VfxKit.Bolt(position, position + Vector3.new(0, if heavy then 6 else 3, 0), color, 0.18, 1)
	elseif classId == "Brawler" or heavy then
		VfxKit.Shockwave(position, color, if heavy then 10 else 5, 0.25)
		VfxKit.Burst(position, color, VfxKit.Texture.Smoke, 10, 0.3)
	elseif FIRE[abilityId] then
		VfxKit.Burst(position, color, VfxKit.Texture.Fire, 14, 0.3)
	else
		VfxKit.Burst(position, color, VfxKit.Texture.Spark, if heavy then 16 else 8, 0.25)
	end
	local localId = Players.LocalPlayer.UserId
	local involved = payload.attackerUserId == localId or payload.victimUserId == localId
	local root = Players.LocalPlayer.Character and Util.Root(Players.LocalPlayer.Character)
	local near = root ~= nil and (root.Position - position).Magnitude < 30
	if involved or near then
		local amount = if typeof(payload.amount) == "number" then payload.amount else 8
		VfxKit.Shake(math.clamp(amount / 80, 0.12, 0.7) + if heavy then 0.25 else 0)
	end
end

function VfxThemes.FlightTrail(character: Model, on: boolean)
	local existing = character:FindFirstChild("LocalFlightFx")
	if not on then
		if existing then
			existing:Destroy()
		end
		return
	end
	if existing then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "LocalFlightFx"
	folder.Parent = character
	local info = Classes.ById["Superhero"]
	local color = if info then info.color else Color3.fromRGB(255, 60, 70)
	for _, partName in { "RightHand", "LeftHand", "RightFoot", "LeftFoot" } do
		local limb = character:FindFirstChild(partName)
		if limb and limb:IsA("BasePart") then
			local a0 = Instance.new("Attachment")
			a0.Name = "FlightA0"
			a0.Position = Vector3.new(0, 0.4, 0)
			a0.Parent = limb
			local a1 = Instance.new("Attachment")
			a1.Name = "FlightA1"
			a1.Position = Vector3.new(0, -0.4, 0)
			a1.Parent = limb
			local trail = Instance.new("Trail")
			trail.Attachment0 = a0
			trail.Attachment1 = a1
			trail.Color = ColorSequence.new(color)
			trail.LightEmission = 1
			trail.Lifetime = 0.25
			trail.Parent = folder
			folder.Destroying:Connect(function()
				a0:Destroy()
				a1:Destroy()
			end)
		end
	end
	VfxKit.Shockwave(character:GetPivot().Position, color, 8, 0.25)
end

return VfxThemes
