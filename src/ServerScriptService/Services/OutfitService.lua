--!strict
-- Checks a cosmetic loadout and welds it onto the character.
-- Parts are created on the server so every player sees them.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Replicated = game:GetService("ReplicatedStorage").FightingClasses
local Actions = require(Replicated.Shared.Actions)
local OutfitBuilder = require(Replicated.Shared.OutfitBuilder)
local OutfitCatalog = require(Replicated.Shared.OutfitCatalog)
local Types = require(Replicated.Shared.Types)
local DataService = require(script.Parent.DataService)
local Remotes = require(script.Parent.Parent.Remotes)

type OutfitSlot = Types.OutfitSlot

local OutfitService = {}

local function sanitize(payload: any): { [string]: OutfitSlot }?
	if typeof(payload) ~= "table" then
		return nil
	end
	local outfit: { [string]: OutfitSlot } = {}
	for _, category in OutfitCatalog.Order do
		local raw = payload[category]
		if raw == nil then
			continue
		end
		if typeof(raw) ~= "table" or typeof(raw.id) ~= "string" then
			return nil
		end
		if raw.id == "" then
			continue
		end
		if not OutfitCatalog.Find(category, raw.id) then
			return nil
		end
		local r = if typeof(raw.r) == "number" then raw.r else -1
		local g = if typeof(raw.g) == "number" then raw.g else -1
		local b = if typeof(raw.b) == "number" then raw.b else -1
		if r < 0 or r > 1 or g < 0 or g > 1 or b < 0 or b > 1 then
			return nil
		end
		outfit[category] = { id = raw.id, r = r, g = g, b = b }
	end
	return outfit
end

local function apply(player: Player)
	local data = DataService.Get(player)
	local character = player.Character
	if not data or not character then
		return
	end
	OutfitBuilder.Apply(character, data.outfit)
	if player:GetAttribute("OutfitJson") == nil then
		player:SetAttribute("OutfitJson", HttpService:JSONEncode(data.outfit))
	end
end

function OutfitService.HandleSet(player: Player, payload: { [string]: any })
	local outfit = sanitize(payload.outfit)
	if not outfit then
		Remotes.Tell(player, { action = Actions.MenuResult, ok = false, reason = "That outfit is not allowed." })
		return
	end
	local data = DataService.Get(player)
	if not data then
		return
	end
	data.outfit = outfit
	DataService.Set(player, data, true)
	local encoded = HttpService:JSONEncode(outfit)
	player:SetAttribute("OutfitJson", encoded)
	apply(player)
	Remotes.Tell(player, { action = Actions.MenuResult, ok = true, reason = "Outfit saved." })
end

function OutfitService.Start()
	local function watch(player: Player)
		player.CharacterAdded:Connect(function()
			task.defer(function()
				apply(player)
			end)
		end)
		if player.Character then
			task.defer(function()
				apply(player)
			end)
		end
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
end

return OutfitService
