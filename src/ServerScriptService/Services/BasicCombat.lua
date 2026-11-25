--!strict
-- Mouse combo and the shift dash. Same rules as abilities: server hitboxes,
-- energy, stun, and a rate limit. Damage numbers are Balance.M1 and Balance.CombatDash.

local Players = game:GetService("Players")

local Replicated = game:GetService("ReplicatedStorage").FightingClasses
local Actions = require(Replicated.Shared.Actions)
local Balance = require(Replicated.Shared.Balance)
local MovementMath = require(Replicated.Shared.MovementMath)
local CombatService = require(script.Parent.CombatService)
local EnergyService = require(script.Parent.EnergyService)
local HitboxService = require(script.Parent.HitboxService)
local PoseService = require(script.Parent.PoseService)
local StatusService = require(script.Parent.StatusService)
local Remotes = require(script.Parent.Parent.Remotes)

local comboIndex: { [Player]: number } = {}
local comboTime: { [Player]: number } = {}
local dashReady: { [Player]: number } = {}

local BasicCombat = {}

local function alive(player: Player): (Model?, Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") or humanoid.Health <= 0 then
		return nil, nil, nil
	end
	if character:GetAttribute("Stunned") == true then
		return nil, nil, nil
	end
	return character, humanoid, root
end

local function reject(player: Player, reason: string)
	Remotes.Tell(player, {
		action = Actions.DashResult,
		ok = false,
		reason = reason,
	})
end

function BasicCombat.HandleM1(player: Player, payload: { [string]: any })
	local character, _, root = alive(player)
	if not character or not root then
		return
	end
	if Balance.BlockStopsBasics and character:GetAttribute("Blocking") == true then
		return
	end
	local now = os.clock()
	local last = comboTime[player] or 0
	local index = comboIndex[player] or 1
	if now - last > Balance.M1.reset then
		index = 1
	elseif now - last < Balance.M1.gap then
		return
	end
	local damages = Balance.M1.damages
	local energies = Balance.M1.energies
	local knockbacks = Balance.M1.knockbacks
	local damage = damages[index] or damages[1]
	local cost = energies[index] or 0
	if not EnergyService.Spend(player, cost) then
		Remotes.Tell(player, { action = Actions.MenuResult, ok = false, reason = "Not enough energy" })
		return
	end
	comboIndex[player] = if index >= #damages then 1 else index + 1
	comboTime[player] = now

	local direction = MovementMath.SanitizeDirection(payload.direction, root.CFrame.LookVector)
	local flat = MovementMath.FlatLook(root, direction)
	local reach = Balance.M1.range
	local center = root.Position + flat * (reach / 2)
	local box = CFrame.lookAt(center, center + flat)
	local models = HitboxService.OpponentsInBox(player, character, box, Vector3.new(Balance.M1.width, 6, reach))
	for _, model in models do
		CombatService.ApplyDamage(player, model, damage, {
			knockback = knockbacks[index] or 8,
			origin = root.Position,
			abilityId = "M1",
		})
	end
	CombatService.TagPlayer(player)
	PoseService.Play(character, "Punch" .. tostring(index), 0.38)
end

function BasicCombat.HandleDash(player: Player, payload: { [string]: any })
	local character, _, root = alive(player)
	if not character or not root then
		reject(player, "You cannot dash right now.")
		return
	end
	local now = workspace:GetServerTimeNow()
	local readyAt = dashReady[player]
	if readyAt and now < readyAt then
		reject(player, "Dash is cooling down")
		return
	end
	if not EnergyService.Spend(player, Balance.CombatDash.energy) then
		reject(player, "Not enough energy")
		return
	end
	dashReady[player] = now + Balance.CombatDash.cooldown
	local direction = MovementMath.SanitizeDirection(payload.direction, root.CFrame.LookVector)
	local moveDirection = MovementMath.SanitizeMove(payload.moveDirection)
	local goal = MovementMath.Compute(root, direction, moveDirection, Balance.CombatDash.distance, "dash")
	if Balance.CombatDash.iframe > 0 then
		StatusService.ApplyIFrames(character, Balance.CombatDash.iframe)
	end
	PoseService.Play(character, "Dash", 0.32)
	CombatService.TagPlayer(player)
	Remotes.Tell(player, {
		action = Actions.DashResult,
		ok = true,
		reason = "",
		move = {
			kind = "dash",
			position = goal.Position,
			look = goal.LookVector,
		},
		cooldown = Balance.CombatDash.cooldown,
	})
	Remotes.TellOthers(player, {
		action = Actions.Vfx,
		vfx = "dash",
		abilityId = "CombatDash",
		casterUserId = player.UserId,
		origin = root.Position,
		direction = direction,
		endPosition = goal.Position,
		castId = "dash-" .. tostring(player.UserId),
	})
end

function BasicCombat.Start()
	Players.PlayerRemoving:Connect(function(player)
		comboIndex[player] = nil
		comboTime[player] = nil
		dashReady[player] = nil
	end)
end

return BasicCombat
