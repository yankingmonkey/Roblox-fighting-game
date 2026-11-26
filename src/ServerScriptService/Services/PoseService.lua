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
	if ability.vfx == "flight" then
		return
	end
	-- The pose name is the ability id, so each move can have its own clip or sequence.
	local clip = AnimationConfig.Clip(ability.id)
	if clip == "" and ability.isUltimate then
		clip = AnimationConfig.Clip("Ult")
	end
	if clip ~= "" then
		playClip(character, clip, false)
		character:SetAttribute("Pose", "")
		return
	end
	PoseService.Play(character, ability.id, AnimationConfig.Length(ability.id))
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
