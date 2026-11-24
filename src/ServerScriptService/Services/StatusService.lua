--!strict
-- Timed states live on the character as attributes so other scripts (and the
-- client) can read them: Stunned, SuperArmor, IFrames, DamageBuff,
-- DamageReduction, MoveSpeedMultiplier, Knockback.

local Balance = require(game:GetService("ReplicatedStorage").FightingClasses.Shared.Balance)

local stunToken: { [Model]: number } = {}
local armorToken: { [Model]: number } = {}
local iframeToken: { [Model]: number } = {}
local buffToken: { [Model]: number } = {}
local reductionToken: { [Model]: number } = {}
local slowToken: { [Model]: number } = {}
local slowFactor: { [Model]: number } = {}
local slowUntil: { [Model]: number } = {}
local watched: { [Model]: boolean } = {}

local StatusService = {}

local function nextToken(bucket: { [Model]: number }, model: Model): number
	local token = (bucket[model] or 0) + 1
	bucket[model] = token
	return token
end

local function watch(model: Model)
	if watched[model] then
		return
	end
	watched[model] = true
	model.AncestryChanged:Connect(function(_, parent)
		if parent ~= nil then
			return
		end
		watched[model] = nil
		stunToken[model] = nil
		armorToken[model] = nil
		iframeToken[model] = nil
		buffToken[model] = nil
		reductionToken[model] = nil
		slowToken[model] = nil
		slowFactor[model] = nil
		slowUntil[model] = nil
	end)
end

function StatusService.RefreshMove(model: Model)
	local multiplier = 1
	if model:GetAttribute("Stunned") == true then
		multiplier = 0
	elseif model:GetAttribute("Blocking") == true then
		multiplier = Balance.BlockMoveMultiplier
	else
		local untilTime = slowUntil[model]
		if untilTime and workspace:GetServerTimeNow() < untilTime then
			multiplier = slowFactor[model] or 1
		end
	end
	model:SetAttribute("MoveSpeedMultiplier", multiplier)

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid and model:GetAttribute("IsClone") ~= true then
		humanoid.WalkSpeed = Balance.BaseWalkSpeed * multiplier
		humanoid.UseJumpPower = true
		humanoid.JumpPower = if multiplier <= 0 then 0 else Balance.BaseJumpPower
	end
end

function StatusService.ApplyStun(model: Model, duration: number)
	watch(model)
	local token = nextToken(stunToken, model)
	model:SetAttribute("Stunned", true)
	model:SetAttribute("Blocking", false)
	model:SetAttribute("ParryWindow", false)
	-- A stun knocks you out of the air. Flight cannot be used to ignore it.
	if model:GetAttribute("Flying") == true then
		model:SetAttribute("Flying", false)
	end
	StatusService.RefreshMove(model)
	task.delay(duration, function()
		if model.Parent and stunToken[model] == token then
			model:SetAttribute("Stunned", false)
			StatusService.RefreshMove(model)
		end
	end)
end

function StatusService.ApplySlow(model: Model, multiplier: number, duration: number)
	watch(model)
	local token = nextToken(slowToken, model)
	slowFactor[model] = multiplier
	slowUntil[model] = workspace:GetServerTimeNow() + duration
	StatusService.RefreshMove(model)
	task.delay(duration, function()
		if model.Parent and slowToken[model] == token then
			slowUntil[model] = nil
			StatusService.RefreshMove(model)
		end
	end)
end

function StatusService.ApplySuperArmor(model: Model, duration: number)
	watch(model)
	local token = nextToken(armorToken, model)
	model:SetAttribute("SuperArmor", true)
	task.delay(duration, function()
		if model.Parent and armorToken[model] == token then
			model:SetAttribute("SuperArmor", false)
		end
	end)
end

function StatusService.ApplyIFrames(model: Model, duration: number)
	watch(model)
	local token = nextToken(iframeToken, model)
	model:SetAttribute("IFrames", true)
	task.delay(duration, function()
		if model.Parent and iframeToken[model] == token then
			model:SetAttribute("IFrames", false)
		end
	end)
end

function StatusService.ApplyDamageBuff(model: Model, multiplier: number, duration: number)
	watch(model)
	local token = nextToken(buffToken, model)
	model:SetAttribute("DamageBuff", multiplier)
	task.delay(duration, function()
		if model.Parent and buffToken[model] == token then
			model:SetAttribute("DamageBuff", 1)
		end
	end)
end

function StatusService.ApplyReduction(model: Model, fraction: number, duration: number)
	watch(model)
	local token = nextToken(reductionToken, model)
	model:SetAttribute("DamageReduction", math.clamp(fraction, 0, Balance.MaxDamageReduction))
	task.delay(duration, function()
		if model.Parent and reductionToken[model] == token then
			model:SetAttribute("DamageReduction", 0)
		end
	end)
end

function StatusService.ApplyKnockback(model: Model, velocity: Vector3)
	if model:GetAttribute("IsClone") == true then
		return
	end
	local current = model:GetAttribute("KnockbackToken")
	local token = (if typeof(current) == "number" then current else 0) + 1
	model:SetAttribute("Knockback", velocity)
	model:SetAttribute("KnockbackToken", token)
end

function StatusService.Start()
	-- States are applied on demand. Nothing to spawn here.
end

return StatusService
