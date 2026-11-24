--!strict
-- Energy lives on the Player as attributes "Energy" and "MaxEnergy", so the
-- hotbar does not flicker when the character respawns. Flight drain and regen
-- both happen here. While Flying is true, Blocking is forced off.

local Players = game:GetService("Players")

local Balance = require(game:GetService("ReplicatedStorage").FightingClasses.Shared.Balance)
local CombatService = require(script.Parent.CombatService)
local StatusService = require(script.Parent.StatusService)
local Util = require(game:GetService("ReplicatedStorage").FightingClasses.Shared.Util)

local EnergyService = {}

local function setEnergy(player: Player, value: number)
	local clamped = math.clamp(value, 0, Balance.MaxEnergy)
	local shown = Util.Round(clamped, 1)
	if player:GetAttribute("Energy") ~= shown then
		player:SetAttribute("Energy", shown)
	end
	if player:GetAttribute("MaxEnergy") ~= Balance.MaxEnergy then
		player:SetAttribute("MaxEnergy", Balance.MaxEnergy)
	end
end

function EnergyService.Get(player: Player): number
	return Util.ReadNumber(player:GetAttribute("Energy"), 0)
end

function EnergyService.Spend(player: Player, amount: number): boolean
	if amount <= 0 then
		return true
	end
	local current = EnergyService.Get(player)
	if current + 0.001 < amount then
		return false
	end
	setEnergy(player, current - amount)
	return true
end

function EnergyService.Refund(player: Player, amount: number)
	if amount <= 0 then
		return
	end
	setEnergy(player, EnergyService.Get(player) + amount)
end

local function prepareCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 8)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end
	character:WaitForChild("HumanoidRootPart", 8)

	if Balance.OverrideHealth then
		humanoid.MaxHealth = Balance.PlayerHealth
		humanoid.Health = Balance.PlayerHealth
	end

	character:SetAttribute("Stunned", false)
	character:SetAttribute("Blocking", false)
	character:SetAttribute("Flying", false)
	character:SetAttribute("SuperArmor", false)
	character:SetAttribute("IFrames", false)
	character:SetAttribute("ParryWindow", false)
	character:SetAttribute("DamageBuff", 1)
	character:SetAttribute("DamageReduction", 0)
	character:SetAttribute("MoveSpeedMultiplier", 1)
	StatusService.RefreshMove(character)

	if Balance.ResetEnergyOnSpawn or player:GetAttribute("Energy") == nil then
		setEnergy(player, Balance.MaxEnergy)
	end

	humanoid.Died:Connect(function()
		if character.Parent then
			character:SetAttribute("Flying", false)
			character:SetAttribute("Blocking", false)
			character:SetAttribute("Stunned", false)
		end
	end)
end

local function hookPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		task.spawn(prepareCharacter, player, character)
	end)
	if player.Character then
		task.spawn(prepareCharacter, player, player.Character)
	end
	if player:GetAttribute("MaxEnergy") == nil then
		player:SetAttribute("MaxEnergy", Balance.MaxEnergy)
	end
	if player:GetAttribute("Energy") == nil then
		setEnergy(player, Balance.MaxEnergy)
	end
end

local function stepPlayer(player: Player, dt: number)
	local character = player.Character
	local flying = character ~= nil and character:GetAttribute("Flying") == true
	local energy = EnergyService.Get(player)

	if flying and character then
		if character:GetAttribute("Blocking") == true then
			character:SetAttribute("Blocking", false)
			StatusService.RefreshMove(character)
		end
		local drain = Balance.Abilities.Flight.energyPerSecond or 12
		energy -= drain * dt
		if energy <= 0 then
			energy = 0
			character:SetAttribute("Flying", false)
			character:SetAttribute("Blocking", false)
			StatusService.ApplyStun(character, Balance.FlightEmptyStun)
		end
	else
		local regen = if CombatService.IsInCombat(player) then Balance.RegenInCombat else Balance.RegenOutOfCombat
		energy = math.min(Balance.MaxEnergy, energy + regen * dt)
	end

	setEnergy(player, energy)
end

function EnergyService.Start()
	Players.PlayerAdded:Connect(hookPlayer)
	for _, player in Players:GetPlayers() do
		hookPlayer(player)
	end

	task.spawn(function()
		while true do
			local dt = task.wait(0.1)
			for _, player in Players:GetPlayers() do
				stepPlayer(player, dt)
			end
		end
	end)
end

return EnergyService
