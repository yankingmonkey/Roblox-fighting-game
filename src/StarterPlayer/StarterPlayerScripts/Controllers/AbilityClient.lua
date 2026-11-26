--!strict
-- Listens to keys (through InputController) and the server's answers.
-- Plays your VFX immediately, then rolls the move back if the server says no.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("FightingClasses"):WaitForChild("Shared")
local Actions = require(Shared:WaitForChild("Actions"))
local AbilityRegistry = require(Shared:WaitForChild("AbilityRegistry"))
local Balance = require(Shared:WaitForChild("Balance"))
local LoadoutUtil = require(Shared:WaitForChild("LoadoutUtil"))
local MovementMath = require(Shared:WaitForChild("MovementMath"))
local Util = require(Shared:WaitForChild("Util"))
local AimRules = require(Shared:WaitForChild("AimRules"))
local Classes = require(Shared:WaitForChild("Classes"))
local VfxClient = require(script.Parent.VfxClient)
local VfxKit = require(script.Parent.VfxKit)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local actionEvent = remotes:WaitForChild("Action") :: RemoteEvent
local notifyEvent = remotes:WaitForChild("Notify") :: RemoteEvent

local serverEnds: { [string]: number } = {}
local optimisticEnds: { [string]: number } = {}
local savedCFrame: { [string]: CFrame } = {}
local savedDash: CFrame? = nil
local afterimages: () -> ()
local castAbility: { [string]: string } = {}
local castSerial = 0
local blocking = false
local onMenu: (() -> ())? = nil
local shiftLock = false
local statusText = ""
local statusUntil = 0

local AbilityClient = {}

local function setStatus(text: string)
	statusText = text
	statusUntil = os.clock() + 1.8
end

function AbilityClient.GetStatus(): string
	if os.clock() > statusUntil then
		return ""
	end
	return statusText
end

function AbilityClient.GetRemaining(abilityId: string): number
	local now = workspace:GetServerTimeNow()
	local endsAt = serverEnds[abilityId] or 0
	local optimistic = optimisticEnds[abilityId] or 0
	return math.max(0, math.max(endsAt, optimistic) - now)
end

local function readCooldowns()
	serverEnds = {}
	local blob = Util.ReadString(player:GetAttribute("Cooldowns"), "")
	if blob == "" then
		return
	end
	for _, piece in string.split(blob, ";") do
		local id, timeText = string.match(piece, "^(.-)=([%d%.]+)$")
		if id and timeText then
			serverEnds[id] = tonumber(timeText) or 0
		end
	end
end

local function rootAndHumanoid(): (BasePart?, Humanoid?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") then
		return nil, nil
	end
	return root, humanoid
end

function AbilityClient.OnMenu(callback: () -> ())
	onMenu = callback
end

function AbilityClient.SetShiftLock(enabled: boolean)
	shiftLock = enabled
	game:GetService("UserInputService").MouseBehavior = if enabled
		then Enum.MouseBehavior.LockCenter
		else Enum.MouseBehavior.Default
end

function AbilityClient.ShiftLock(): boolean
	return shiftLock
end

local function readAim(maxRange: number): (Vector3, Vector3)
	local camera = workspace.CurrentCamera
	local root = select(1, rootAndHumanoid())
	local look = if camera then camera.CFrame.LookVector else Vector3.new(0, 0, -1)
	local origin = if root then root.Position + Vector3.new(0, 1.6, 0) else Vector3.zero
	if shiftLock or not camera then
		return look, origin + look * maxRange
	end
	local mouse = player:GetMouse()
	local hit = mouse.Hit.Position
	local offset = hit - origin
	if offset.Magnitude < 0.3 then
		return look, origin + look * maxRange
	end
	return offset.Unit, hit
end

local function place(root: BasePart, position: Vector3, look: Vector3)
	local flat = if look.Magnitude > 0.05 then look.Unit else root.CFrame.LookVector
	root.CFrame = CFrame.lookAt(position, position + flat)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
end

local function predictMove(castId: string, abilityId: string, direction: Vector3, moveDirection: Vector3): boolean
	local character = player.Character
	local root = if character then Util.Root(character) else nil
	if not character or not root then
		return false
	end
	local stats = Balance.Abilities[abilityId]
	if not stats then
		return false
	end
	local ability = AbilityRegistry.Get(abilityId)
	if not ability then
		return false
	end

	if abilityId == "DiveBomb" then
		local ground, height = MovementMath.GroundBelow(root)
		local airborne = height >= (stats.heightNeeded or 12) or character:GetAttribute("Flying") == true
		if not airborne then
			return false
		end
		savedCFrame[castId] = root.CFrame
		character:SetAttribute("Flying", false)
		place(root, ground + Vector3.new(0, 3, 0), MovementMath.FlatLook(root, direction))
		return true
	end

	if stats.distance and stats.distance > 0 and (ability.kind == "movement" or ability.vfx == "flurry") then
		local mode = if stats.wall then "wall" elseif stats.dodge then "dodge" else "dash"
		local goal = MovementMath.Compute(root, direction, moveDirection, stats.distance, mode)
		savedCFrame[castId] = root.CFrame
		place(root, goal.Position, goal.LookVector)
		return true
	end
	return false
end

function AbilityClient.Cast(slot: number)
	local classId = Util.ReadString(player:GetAttribute("ClassId"), "")
	if classId == "" then
		setStatus("Pick a class first.")
		return
	end
	local character = player.Character
	local root, humanoid = rootAndHumanoid()
	if not character or not root or not humanoid or humanoid.Health <= 0 then
		return
	end
	if character:GetAttribute("Stunned") == true then
		setStatus("Stunned")
		return
	end
	local slots = LoadoutUtil.Decode(player:GetAttribute("Loadout"))
	local abilityId = slots[slot] or ""
	if abilityId == "" then
		setStatus("Empty slot.")
		return
	end
	local ability = AbilityRegistry.Get(abilityId)
	if not ability then
		return
	end
	if AbilityClient.GetRemaining(abilityId) > 0.05 then
		setStatus("Cooling down")
		return
	end
	local stats = Balance.Abilities[abilityId]
	local energy = Util.ReadNumber(player:GetAttribute("Energy"), 0)
	if energy + 0.001 < ability.energyCost then
		setStatus("Not enough energy")
		return
	end
	if abilityId == "Flight" and character:GetAttribute("Flying") ~= true then
		local minimum = if stats then stats.minEnergy or 8 else 8
		if energy < minimum then
			setStatus("Not enough energy to take off.")
			return
		end
	end

	castSerial += 1
	local castId = tostring(player.UserId) .. "-" .. tostring(castSerial)
	castAbility[castId] = abilityId
	local reach = if AimRules.IsGround(abilityId) then AimRules.PlaceRange else math.max(ability.range, 20)
	local direction, aimPoint = readAim(reach)
	local moveDirection = humanoid.MoveDirection

	if ability.cooldown > 0 then
		optimisticEnds[abilityId] = workspace:GetServerTimeNow() + ability.cooldown
	end
	local effectOrigin = root.Position + Vector3.new(0, 1.2, 0)
	local effectEnd = if AimRules.IsGround(abilityId) then aimPoint else nil
	VfxClient.Predict(abilityId, effectOrigin, direction, castId, effectEnd)
	if predictMove(castId, abilityId, direction, moveDirection) then
		afterimages()
	end

	actionEvent:FireServer({
		action = Actions.Cast,
		slot = slot,
		direction = direction,
		aimPoint = aimPoint,
		moveDirection = moveDirection,
		castId = castId,
	})
end

function AbilityClient.SetBlock(wantBlock: boolean)
	if blocking == wantBlock then
		return
	end
	blocking = wantBlock
	actionEvent:FireServer({
		action = Actions.SetBlock,
		blocking = wantBlock,
	})
end

local function aimDirection(): Vector3
	local camera = workspace.CurrentCamera
	if camera then
		return camera.CFrame.LookVector
	end
	local root = select(1, rootAndHumanoid())
	return if root then root.CFrame.LookVector else Vector3.new(0, 0, -1)
end

local function classColor(): Color3
	local classId = Util.ReadString(player:GetAttribute("ClassId"), "")
	local info = Classes.ById[classId]
	return if info then info.color else Color3.fromRGB(255, 255, 255)
end

function afterimages()
	local character = player.Character
	if not character then
		return
	end
	local color = classColor()
	VfxKit.Afterimage(character, color)
	task.delay(0.07, function()
		if character.Parent then
			VfxKit.Afterimage(character, color)
		end
	end)
	task.delay(0.14, function()
		if character.Parent then
			VfxKit.Afterimage(character, color)
		end
	end)
end

function AbilityClient.ReturnToMenu()
	actionEvent:FireServer({ action = Actions.ReturnToMenu })
end

function AbilityClient.SetOutfit(outfit: { [string]: any })
	actionEvent:FireServer({
		action = Actions.SetOutfit,
		outfit = outfit,
	})
end

function AbilityClient.M1()
	local character = player.Character
	if not character or character:GetAttribute("Stunned") == true then
		return
	end
	if character:GetAttribute("Blocking") == true then
		return
	end
	local direction = select(1, readAim(12))
	actionEvent:FireServer({
		action = Actions.M1,
		direction = direction,
	})
end

function AbilityClient.Dash()
	local root, humanoid = rootAndHumanoid()
	if not root or not humanoid then
		return
	end
	local character = player.Character
	if character and character:GetAttribute("Stunned") == true then
		setStatus("Stunned")
		return
	end
	local direction = aimDirection()
	local moveDirection = humanoid.MoveDirection
	local stats = Balance.CombatDash
	local saved = root.CFrame
	local goal = MovementMath.Compute(root, direction, moveDirection, stats.distance, "dash")
	place(root, goal.Position, goal.LookVector)
	afterimages()
	actionEvent:FireServer({
		action = Actions.Dash,
		direction = direction,
		moveDirection = moveDirection,
	})
	savedDash = saved
end

function AbilityClient.Parry()
	actionEvent:FireServer({
		action = Actions.Parry,
	})
	setStatus("Parry")
end

function AbilityClient.ChooseClass(classId: string)
	actionEvent:FireServer({
		action = Actions.SetClass,
		classId = classId,
	})
end

function AbilityClient.SetLoadout(slots: { string })
	actionEvent:FireServer({
		action = Actions.SetLoadout,
		slots = slots,
	})
end

local function onCastResult(payload: { [string]: any })
	local castId = if typeof(payload.castId) == "string" then payload.castId else ""
	local fromServer = if typeof(payload.abilityId) == "string" then payload.abilityId else ""
	local abilityId = if fromServer ~= "" then fromServer else (castAbility[castId] or "")
	castAbility[castId] = nil
	if payload.ok == true then
		if abilityId ~= "" and typeof(payload.cooldownEnds) == "number" and payload.cooldownEnds > 0 then
			serverEnds[abilityId] = payload.cooldownEnds
		end
		if abilityId ~= "" then
			optimisticEnds[abilityId] = nil
		end
		local move = payload.move
		local saved = savedCFrame[castId]
		savedCFrame[castId] = nil
		if typeof(move) == "table" and typeof(move.position) == "Vector3" and typeof(move.look) == "Vector3" then
			local root = select(1, rootAndHumanoid())
			if root and (not saved or (root.Position - move.position).Magnitude > 6) then
				place(root, move.position, move.look)
			end
		end
	else
		local reason = if typeof(payload.reason) == "string" then payload.reason else "Can't do that."
		setStatus(reason)
		VfxClient.Stop(castId)
		if abilityId ~= "" then
			optimisticEnds[abilityId] = nil
		end
		local saved = savedCFrame[castId]
		savedCFrame[castId] = nil
		if saved and next(savedCFrame) == nil then
			local root = select(1, rootAndHumanoid())
			if root then
				root.CFrame = saved
				root.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end
end

function AbilityClient.Start()
	readCooldowns()
	player:GetAttributeChangedSignal("Cooldowns"):Connect(readCooldowns)

	notifyEvent.OnClientEvent:Connect(function(payload: any)
		if typeof(payload) ~= "table" then
			return
		end
		local action = payload.action
		if action == Actions.CastResult then
			onCastResult(payload)
		elseif action == Actions.Vfx then
			VfxClient.Play(payload)
		elseif action == Actions.VfxStop then
			if typeof(payload.castId) == "string" then
				VfxClient.Stop(payload.castId)
			end
		elseif action == Actions.DashResult then
			if payload.ok == true and typeof(payload.move) == "table" then
				local move = payload.move
				local root = select(1, rootAndHumanoid())
				if root and typeof(move.position) == "Vector3" and typeof(move.look) == "Vector3" then
					if (root.Position - move.position).Magnitude > 6 then
						place(root, move.position, move.look)
					end
				end
				savedDash = nil
			else
				if typeof(payload.reason) == "string" and payload.reason ~= "" then
					setStatus(payload.reason)
				end
				local root = select(1, rootAndHumanoid())
				if root and savedDash then
					root.CFrame = savedDash
					root.AssemblyLinearVelocity = Vector3.zero
				end
				savedDash = nil
			end
		elseif action == Actions.Impact then
			VfxClient.Impact(payload)
		elseif action == Actions.MenuResult then
			if typeof(payload.reason) == "string" and payload.reason ~= "" and payload.reason ~= "Class set." and payload.reason ~= "Loadout saved." then
				setStatus(payload.reason)
			elseif payload.ok == true and payload.reason == "Loadout saved." then
				setStatus("Loadout saved.")
			elseif payload.ok == true and payload.reason == "Class set." then
				setStatus("Class set.")
			elseif payload.ok == true and payload.reason == "Menu" then
				if onMenu then
					onMenu()
				end
			elseif payload.ok == true and payload.reason == "Outfit saved." then
				setStatus("Outfit saved.")
			end
		end
	end)

	player.CharacterAdded:Connect(function()
		blocking = false
	end)
end

return AbilityClient
