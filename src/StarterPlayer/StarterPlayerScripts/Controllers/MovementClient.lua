--!strict
-- The player owns their character, so speed, knockback, and flight are applied
-- here. The server decides the attributes (Stunned, Flying, MoveSpeedMultiplier,
-- Knockback). This script only makes the body obey them.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Balance = require(game:GetService("ReplicatedStorage").FightingClasses.Shared.Balance)
local Util = require(game:GetService("ReplicatedStorage").FightingClasses.Shared.Util)

local player = Players.LocalPlayer
local verticalIntent = 0
local controls: any = nil

local MovementClient = {}

function MovementClient.SetVertical(direction: number)
	verticalIntent = direction
end

local function getMoveVector(): Vector3
	if not controls then
		local ok, result = pcall(function()
			local scripts = player:WaitForChild("PlayerScripts")
			local playerModule = require(scripts:WaitForChild("PlayerModule"))
			return playerModule:GetControls()
		end)
		if ok then
			controls = result
		end
	end
	if not controls then
		return Vector3.zero
	end
	local ok, vector = pcall(function()
		return controls:GetMoveVector()
	end)
	if ok and typeof(vector) == "Vector3" then
		return vector
	end
	return Vector3.zero
end

local function applySpeed(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or character:GetAttribute("Flying") == true then
		return
	end
	local multiplier = Util.ReadNumber(character:GetAttribute("MoveSpeedMultiplier"), 1)
	humanoid.WalkSpeed = Balance.BaseWalkSpeed * multiplier
	humanoid.UseJumpPower = true
	humanoid.JumpPower = if multiplier <= 0 then 0 else Balance.BaseJumpPower
end

local function bindCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 8)
	local root = character:WaitForChild("HumanoidRootPart", 8)
	if not humanoid or not humanoid:IsA("Humanoid") or not root or not root:IsA("BasePart") then
		return
	end

	applySpeed(character)
	character:GetAttributeChangedSignal("MoveSpeedMultiplier"):Connect(function()
		applySpeed(character)
	end)
	character:GetAttributeChangedSignal("Flying"):Connect(function()
		if character:GetAttribute("Flying") ~= true then
			humanoid.PlatformStand = false
			applySpeed(character)
		end
	end)
	character:GetAttributeChangedSignal("KnockbackToken"):Connect(function()
		local velocity = character:GetAttribute("Knockback")
		if typeof(velocity) == "Vector3" then
			root.AssemblyLinearVelocity += velocity
		end
	end)
end

local function flightWish(): Vector3
	local camera = workspace.CurrentCamera
	if not camera then
		return Vector3.zero
	end
	local wish = Vector3.zero
	local look = camera.CFrame.LookVector
	local right = camera.CFrame.RightVector
	local usingKeys = false
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		wish += look
		usingKeys = true
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		wish -= look
		usingKeys = true
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		wish += right
		usingKeys = true
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		wish -= right
		usingKeys = true
	end
	if not usingKeys then
		-- Thumbstick / gamepad. PlayerModule's Z is negative when moving forward.
		local move = getMoveVector()
		if move.Magnitude > 0.05 then
			wish = right * move.X + look * -move.Z
		end
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) or verticalIntent > 0 then
		wish += Vector3.yAxis
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or verticalIntent < 0 then
		wish -= Vector3.yAxis
	end
	if wish.Magnitude < 0.05 then
		return Vector3.zero
	end
	local speed = Balance.Abilities.Flight.speed or 60
	return wish.Unit * speed
end

function MovementClient.Start()
	player.CharacterAdded:Connect(function(character)
		task.spawn(bindCharacter, character)
	end)
	if player.Character then
		task.spawn(bindCharacter, player.Character)
	end

	RunService.RenderStepped:Connect(function()
		local character = player.Character
		if not character then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local root = Util.Root(character)
		if not humanoid or not root or humanoid.Health <= 0 then
			return
		end
		if character:GetAttribute("Flying") == true then
			humanoid.PlatformStand = true
			root.AssemblyLinearVelocity = flightWish()
		end
	end)
end

return MovementClient
