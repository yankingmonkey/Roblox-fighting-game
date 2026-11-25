--!strict
-- Tells every client which pose to show, or plays an uploaded clip if you set one
-- in Shared/AnimationConfig.lua. Clips played here replicate. Empty ids use the
-- procedural poses on each client.

local AnimationConfig = require(game:GetService("ReplicatedStorage").FightingClasses.Shared.AnimationConfig)
local Types = require(game:GetService("ReplicatedStorage").FightingClasses.Shared.Types)

type AbilityDefinition = Types.AbilityDefinition

local PoseService = {}

local function playClip(character: Model, animationId: string, looped: boolean)
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
	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if ok and track then
		track.Priority = if looped then Enum.AnimationPriority.Idle else Enum.AnimationPriority.Action
		track.Looped = looped
		track:Play(0.08)
	end
end

function PoseService.Play(character: Model, poseName: string, duration: number)
	if character:GetAttribute("IsClone") == true then
		return
	end
	local clip = AnimationConfig.Clip(poseName)
	if clip ~= "" then
		playClip(character, clip, false)
		character:SetAttribute("Pose", "")
		return
	end
	local current = character:GetAttribute("PoseToken")
	local token = (if typeof(current) == "number" then current else 0) + 1
	character:SetAttribute("Pose", poseName)
	character:SetAttribute("PoseStart", workspace:GetServerTimeNow())
	character:SetAttribute("PoseDuration", duration)
	character:SetAttribute("PoseToken", token)
end

function PoseService.ForAbility(character: Model, ability: AbilityDefinition)
	local pose = "Cast"
	local duration = 0.45
	if ability.isUltimate then
		pose = "Ult"
		duration = 0.7
	elseif ability.vfx == "channelBeam" or ability.vfx == "buff" or ability.vfx == "charge" then
		pose = "Charge"
		duration = 0.9
	elseif ability.vfx == "flurry" then
		pose = "Flurry"
		duration = 0.7
	elseif ability.kind == "melee" or ability.vfx == "melee" then
		pose = "Punch1"
		duration = 0.4
	elseif ability.kind == "movement" or ability.vfx == "dash" or ability.vfx == "blink" or ability.vfx == "dive" then
		pose = "Dash"
		duration = 0.35
	elseif ability.vfx == "aoe" or ability.vfx == "cone" or ability.vfx == "smoke" then
		pose = "Stomp"
		duration = 0.5
	end
	if ability.vfx == "flight" then
		return
	end
	PoseService.Play(character, pose, duration)
end

function PoseService.Start()
	local function hook(character: Model)
		local idle = AnimationConfig.Clip("Idle")
		if idle == "" then
			return
		end
		task.defer(function()
			if character.Parent then
				playClip(character, idle, true)
			end
		end)
	end
	local function watch(player: Player)
		player.CharacterAdded:Connect(hook)
		if player.Character then
			hook(player.Character)
		end
	end
	local Players = game:GetService("Players")
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
end

return PoseService
