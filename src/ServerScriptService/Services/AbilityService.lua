--!strict
-- Checks every cast, then runs the ability's Execute.
-- The client cannot send damage, cooldown, or position. It only sends a slot,
-- an aim direction, and the movement keys it is holding.

local Players = game:GetService("Players")

local Replicated = game:GetService("ReplicatedStorage").FightingClasses
local Actions = require(Replicated.Shared.Actions)
local AbilityRegistry = require(Replicated.Shared.AbilityRegistry)
local Balance = require(Replicated.Shared.Balance)
local LoadoutUtil = require(Replicated.Shared.LoadoutUtil)
local MovementMath = require(Replicated.Shared.MovementMath)
local Types = require(Replicated.Shared.Types)
local Util = require(Replicated.Shared.Util)
local CombatService = require(script.Parent.CombatService)
local EnergyService = require(script.Parent.EnergyService)
local PoseService = require(script.Parent.PoseService)
local Remotes = require(script.Parent.Parent.Remotes)

type CastContext = Types.CastContext

local cooldownUntil: { [Player]: { [string]: number } } = {}
local lastAccepted: { [Player]: number } = {}
local recentRequests: { [Player]: { number } } = {}

local AbilityService = {}

local function reject(player: Player, castId: string, reason: string)
	Remotes.Tell(player, {
		action = Actions.CastResult,
		ok = false,
		castId = castId,
		reason = reason,
	})
end

local function writeCooldowns(player: Player)
	local map = cooldownUntil[player]
	local now = workspace:GetServerTimeNow()
	local parts: { string } = {}
	if map then
		for abilityId, endsAt in map do
			if endsAt > now then
				table.insert(parts, abilityId .. "=" .. string.format("%.3f", endsAt))
			end
		end
	end
	table.sort(parts)
	player:SetAttribute("Cooldowns", table.concat(parts, ";"))
end

local function tooManyRequests(player: Player): boolean
	local now = os.clock()
	local kept: { number } = {}
	local bucket = recentRequests[player]
	if bucket then
		for _, stamp in bucket do
			if now - stamp < 1 then
				table.insert(kept, stamp)
			end
		end
	end
	if #kept >= Balance.MaxCastsPerSecond then
		recentRequests[player] = kept
		return true
	end
	table.insert(kept, now)
	recentRequests[player] = kept
	return false
end

local function castIdOf(payload: { [string]: any }): string
	local castId = payload.castId
	if typeof(castId) ~= "string" or #castId < 1 or #castId > 40 then
		return "cast"
	end
	return castId
end

function AbilityService.ClearAll(player: Player)
	cooldownUntil[player] = {}
	writeCooldowns(player)
end

function AbilityService.HandleCast(player: Player, payload: { [string]: any })
	local castId = castIdOf(payload)
	if tooManyRequests(player) then
		reject(player, castId, "Too fast")
		return
	end

	local character = player.Character
	if not character then
		reject(player, castId, "You cannot fight right now.")
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") or humanoid.Health <= 0 then
		reject(player, castId, "You cannot fight right now.")
		return
	end
	if character:GetAttribute("Stunned") == true then
		reject(player, castId, "Stunned")
		return
	end
	if Balance.BlockPreventsCasting and character:GetAttribute("Blocking") == true then
		reject(player, castId, "You are blocking.")
		return
	end

	local classId = Util.ReadString(player:GetAttribute("ClassId"), "")
	if classId == "" then
		reject(player, castId, "Pick a class first.")
		return
	end

	local slot = payload.slot
	if typeof(slot) ~= "number" or slot ~= math.floor(slot) or slot < 1 or slot > 5 then
		reject(player, castId, "Bad slot.")
		return
	end

	local slots = LoadoutUtil.Decode(player:GetAttribute("Loadout"))
	local abilityId = slots[slot] or ""
	if abilityId == "" then
		reject(player, castId, "No ability in that slot.")
		return
	end
	local ability = AbilityRegistry.Get(abilityId)
	if not ability or ability.classId ~= classId then
		reject(player, castId, "You do not have that ability.")
		return
	end
	if (slot == 5 and not ability.isUltimate) or (slot < 5 and ability.isUltimate) then
		reject(player, castId, "That ability does not fit this slot.")
		return
	end

	local now = workspace:GetServerTimeNow()
	local map = cooldownUntil[player]
	if map and map[ability.id] and map[ability.id] > now then
		reject(player, castId, "Cooling down")
		return
	end
	local last = lastAccepted[player]
	if last and os.clock() - last < Balance.MinCastGap then
		reject(player, castId, "Too fast")
		return
	end
	if not EnergyService.Spend(player, ability.energyCost) then
		reject(player, castId, "Not enough energy")
		return
	end

	lastAccepted[player] = os.clock()
	if not map then
		map = {}
		cooldownUntil[player] = map
	end
	local endsAt = now + ability.cooldown
	if ability.cooldown > 0 then
		map[ability.id] = endsAt
	end
	writeCooldowns(player)

	local spent = ability.energyCost
	local refunded = false
	local function refund()
		if refunded then
			return
		end
		refunded = true
		EnergyService.Refund(player, spent)
		map[ability.id] = nil
		writeCooldowns(player)
	end

	local ctx: CastContext = {
		player = player,
		character = character,
		humanoid = humanoid,
		root = root,
		ability = ability,
		origin = root.Position + Vector3.new(0, 1.2, 0),
		direction = MovementMath.SanitizeDirection(payload.direction, root.CFrame.LookVector),
		moveDirection = MovementMath.SanitizeMove(payload.moveDirection),
		slot = slot,
		castId = castId,
		move = nil,
		failReason = nil,
	}

	PoseService.ForAbility(character, ability)
	local okRun, result = pcall(function()
		return ability.Execute(ctx)
	end)
	if not okRun then
		warn("[FightingClasses] Ability error", ability.id, result)
		refund()
		reject(player, castId, "Ability failed")
		return
	end
	if result == false then
		refund()
		reject(player, castId, ctx.failReason or "Can't use that right now.")
		return
	end

	CombatService.TagPlayer(player)
	Remotes.Tell(player, {
		action = Actions.CastResult,
		ok = true,
		castId = castId,
		abilityId = ability.id,
		slot = slot,
		cooldownEnds = if ability.cooldown > 0 then endsAt else 0,
		reason = "",
		move = ctx.move,
	})
end

function AbilityService.Start()
	local function hook(player: Player)
		if player:GetAttribute("Cooldowns") == nil then
			player:SetAttribute("Cooldowns", "")
		end
	end
	Players.PlayerAdded:Connect(hook)
	for _, player in Players:GetPlayers() do
		hook(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		cooldownUntil[player] = nil
		lastAccepted[player] = nil
		recentRequests[player] = nil
	end)
end

return AbilityService
