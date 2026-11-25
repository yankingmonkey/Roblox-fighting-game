--!strict
-- All ability damage goes through ApplyDamage.
--
-- HOOKS for a block / parry system you already have (or will write):
--   * Set character attribute "Blocking" to true while a block is held.
--     Blocked hits deal Balance.BlockDamageMultiplier damage (default 35%).
--     Flying characters cannot block: Blocking is ignored while Flying is true.
--     Any damaging hit knocks a flyer down (FlightKnockdownStun) unless they
--     have SuperArmor. A stun does the same.
--   * Set character attribute "ParryWindow" to true for a short moment.
--     A hit during that window deals 0 damage and stuns the attacker
--     (unless the attacker has SuperArmor). The window is consumed.
--   * Set "Stunned" yourself if you want; AbilityService will refuse casts.
--   * Set "IFrames" to ignore damage completely.
--   * Set "SuperArmor" to ignore stun and knockback (damage still applies).
--   * Set "DamageReduction" to a fraction (0.4 = 40% less damage).
-- The F and R keys in this repo are a small starter so you can see the hooks
-- work. Delete SetBlocking / TryParry usage in Main if you replace them.

local Players = game:GetService("Players")

local Replicated = game:GetService("ReplicatedStorage").FightingClasses
local Actions = require(Replicated.Shared.Actions)
local Balance = require(Replicated.Shared.Balance)
local StatusService = require(script.Parent.StatusService)
local Util = require(Replicated.Shared.Util)
local PoseService = require(script.Parent.PoseService)
local Remotes = require(script.Parent.Parent.Remotes)

export type HitInfo = {
	stun: number?,
	slow: number?,
	slowDuration: number?,
	knockback: number?,
	origin: Vector3?,
	unblockable: boolean?,
	abilityId: string?,
}

local combatUntil: { [Player]: number } = {}
local parryReadyAt: { [Player]: number } = {}

local CombatService = {}

function CombatService.TagPlayer(player: Player?)
	if not player then
		return
	end
	combatUntil[player] = workspace:GetServerTimeNow() + Balance.CombatTagSeconds
	if player:GetAttribute("InCombat") ~= true then
		player:SetAttribute("InCombat", true)
	end
end

function CombatService.IsInCombat(player: Player): boolean
	local untilTime = combatUntil[player]
	return untilTime ~= nil and workspace:GetServerTimeNow() < untilTime
end

local function ownerOf(model: Model): Player?
	local player = Players:GetPlayerFromCharacter(model)
	if player then
		return player
	end
	local ownerId = model:GetAttribute("OwnerUserId")
	if typeof(ownerId) == "number" then
		return Players:GetPlayerByUserId(ownerId)
	end
	return nil
end

local function knockVelocity(target: Model, info: HitInfo, attacker: Player): Vector3?
	local power = info.knockback
	if not power or power <= 0 then
		return nil
	end
	local root = Util.Root(target)
	if not root then
		return nil
	end
	local origin = info.origin
	if not origin and attacker.Character then
		local attackerRoot = Util.Root(attacker.Character)
		if attackerRoot then
			origin = attackerRoot.Position
		end
	end
	if not origin then
		return nil
	end
	local away = root.Position - origin
	local flat = Vector3.new(away.X, 0, away.Z)
	if flat.Magnitude < 0.1 then
		local look = attacker.Character and Util.Root(attacker.Character)
		flat = if look then look.CFrame.LookVector else Vector3.new(0, 0, -1)
		flat = Vector3.new(flat.X, 0, flat.Z)
	end
	if flat.Magnitude < 0.1 then
		flat = Vector3.new(0, 0, -1)
	end
	return flat.Unit * power + Vector3.new(0, power * 0.28, 0)
end

function CombatService.ApplyDamage(attacker: Player, target: Model, rawDamage: number, info: HitInfo): number
	if target == attacker.Character then
		return 0
	end
	local ownerId = target:GetAttribute("OwnerUserId")
	if ownerId ~= nil and ownerId == attacker.UserId then
		return 0
	end

	local humanoid = target:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return 0
	end

	-- Invincible windows (dashes, afterimage) ignore the hit completely.
	if target:GetAttribute("IFrames") == true then
		return 0
	end

	-- Clones soak exactly one damaging hit, then they are gone.
	if target:GetAttribute("IsClone") == true and rawDamage > 0 then
		CombatService.TagPlayer(attacker)
		CombatService.TagPlayer(ownerOf(target))
		local cloneRoot = Util.Root(target)
		Remotes.TellAll({
			action = Actions.Impact,
			position = if cloneRoot then cloneRoot.Position else target:GetPivot().Position,
			classId = attacker:GetAttribute("ClassId"),
			amount = 1,
			abilityId = info.abilityId,
			attackerUserId = attacker.UserId,
		})
		target:Destroy()
		return 0
	end

	-- HOOK: parry. Set ParryWindow = true for a few tenths of a second.
	if target:GetAttribute("ParryWindow") == true and info.unblockable ~= true then
		target:SetAttribute("ParryWindow", false)
		local attackerCharacter = attacker.Character
		if attackerCharacter and attackerCharacter:GetAttribute("SuperArmor") ~= true then
			StatusService.ApplyStun(attackerCharacter, Balance.ParryStun)
		end
		CombatService.TagPlayer(attacker)
		CombatService.TagPlayer(ownerOf(target))
		return 0
	end

	local amount = rawDamage
	local attackerCharacter = attacker.Character
	if attackerCharacter then
		local buff = attackerCharacter:GetAttribute("DamageBuff")
		if typeof(buff) == "number" and buff > 0 then
			amount *= buff
		end
	end

	local reduction = target:GetAttribute("DamageReduction")
	if typeof(reduction) == "number" then
		amount *= 1 - math.clamp(reduction, 0, Balance.MaxDamageReduction)
	end

	-- HOOK: block. Flying forces this off, so lasers and punches still land in the air.
	local flying = target:GetAttribute("Flying") == true
	local blocking = target:GetAttribute("Blocking") == true and not flying
	if blocking and info.unblockable ~= true then
		amount *= Balance.BlockDamageMultiplier
	end

	amount = math.max(0, amount)
	if amount > 0 then
		humanoid:TakeDamage(amount)
	end

	local superArmor = target:GetAttribute("SuperArmor") == true
	-- A real hit knocks a flyer out of the sky. Blocking is already impossible
	-- while Flying is true, so projectiles are the counter to flight.
	if flying and amount > 0 and not superArmor then
		target:SetAttribute("Flying", false)
		target:SetAttribute("Blocking", false)
	end

	if humanoid.Health > 0 and not superArmor then
		local stunFor = info.stun or 0
		if flying and amount > 0 and stunFor < Balance.FlightKnockdownStun then
			stunFor = Balance.FlightKnockdownStun
		end
		if stunFor > 0 then
			StatusService.ApplyStun(target, stunFor)
		end
		local velocity = knockVelocity(target, info, attacker)
		if velocity then
			StatusService.ApplyKnockback(target, velocity)
		end
	end

	if humanoid.Health > 0 and info.slow and info.slowDuration and info.slowDuration > 0 then
		StatusService.ApplySlow(target, info.slow, info.slowDuration)
	end

	if amount > 0 and target:GetAttribute("IsClone") ~= true then
		local heavy = (info.knockback or 0) >= 20
		PoseService.Play(target, if heavy then "Knockback" else "Hit", if heavy then 0.5 else 0.28)
		local victim = ownerOf(target)
		local targetRoot = Util.Root(target)
		Remotes.TellAll({
			action = Actions.Impact,
			position = if targetRoot then targetRoot.Position else target:GetPivot().Position,
			classId = attacker:GetAttribute("ClassId"),
			amount = amount,
			abilityId = info.abilityId,
			attackerUserId = attacker.UserId,
			victimUserId = if victim then victim.UserId else 0,
			heavy = heavy,
		})
	end

	CombatService.TagPlayer(attacker)
	CombatService.TagPlayer(ownerOf(target))
	return amount
end

function CombatService.SetBlocking(player: Player, blocking: boolean)
	local character = player.Character
	if not character then
		return
	end
	if not blocking or character:GetAttribute("Stunned") == true or character:GetAttribute("Flying") == true then
		character:SetAttribute("Blocking", false)
	else
		character:SetAttribute("Blocking", true)
	end
	StatusService.RefreshMove(character)
end

function CombatService.TryParry(player: Player)
	local character = player.Character
	if not character then
		return
	end
	if character:GetAttribute("Stunned") == true or character:GetAttribute("Flying") == true then
		return
	end
	local now = os.clock()
	local readyAt = parryReadyAt[player]
	if readyAt and now < readyAt then
		return
	end
	parryReadyAt[player] = now + Balance.ParryCooldown
	character:SetAttribute("ParryWindow", true)
	task.delay(Balance.ParryWindow, function()
		if character.Parent then
			character:SetAttribute("ParryWindow", false)
		end
	end)
end

function CombatService.Start()
	task.spawn(function()
		while true do
			task.wait(0.25)
			local now = workspace:GetServerTimeNow()
			for _, player in Players:GetPlayers() do
				local untilTime = combatUntil[player]
				local inCombat = untilTime ~= nil and now < untilTime
				if player:GetAttribute("InCombat") ~= inCombat then
					player:SetAttribute("InCombat", inCombat)
				end
				if not inCombat then
					combatUntil[player] = nil
				end
			end
		end
	end)
end

return CombatService
