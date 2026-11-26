--!strict
-- Plays themed effects for the caster immediately and for everyone else when
-- the server confirms. Impact sparks and camera shake come from the Impact event.

local Players = game:GetService("Players")

local AbilityRegistry = require(game:GetService("ReplicatedStorage").FightingClasses.Shared.AbilityRegistry)
local VfxKit = require(script.Parent.VfxKit)
local VfxThemes = require(script.Parent.VfxThemes)

type Track = {
	cancelled: boolean,
}

local tracks: { [string]: Track } = {}
local VfxClient = {}

local function trackOf(castId: string?): Track?
	if not castId or castId == "" then
		return nil
	end
	local item = tracks[castId]
	if not item then
		item = { cancelled = false }
		tracks[castId] = item
	end
	return item
end

function VfxClient.Predict(abilityId: string, origin: Vector3, direction: Vector3, castId: string, endPosition: Vector3?)
	local ability = AbilityRegistry.Get(abilityId)
	VfxThemes.Play({
		abilityId = abilityId,
		origin = origin,
		direction = direction,
		castId = castId,
		endPosition = endPosition,
		vfx = if ability then ability.vfx else nil,
	}, true)
	if ability and ability.vfx == "channelBeam" then
		local item = trackOf(castId)
		local character = Players.LocalPlayer.Character
		if character and item then
			VfxThemes.Channel(abilityId, character, castId, function()
				return item.cancelled
			end)
		end
	end
end

function VfxClient.Play(payload: { [string]: any })
	local castId = payload.castId
	if typeof(castId) == "string" and tracks[castId] and payload.casterUserId == Players.LocalPlayer.UserId then
		return
	end
	VfxThemes.Play(payload, false)
end

function VfxClient.Stop(castId: string)
	local item = tracks[castId]
	if not item then
		return
	end
	item.cancelled = true
	tracks[castId] = nil
end

function VfxClient.Impact(payload: { [string]: any })
	VfxThemes.Impact(payload)
end

local function watchCharacter(character: Model)
	local highlight = Instance.new("Highlight")
	highlight.Name = "StateHighlight"
	highlight.FillTransparency = 0.72
	highlight.OutlineTransparency = 0.15
	highlight.Enabled = false
	highlight.Parent = character

	local function refresh()
		local flying = character:GetAttribute("Flying") == true
		VfxThemes.FlightTrail(character, flying)
		if character:GetAttribute("Stunned") == true then
			highlight.Enabled = true
			highlight.FillColor = Color3.fromRGB(186, 92, 255)
		elseif character:GetAttribute("IFrames") == true then
			highlight.Enabled = true
			highlight.FillColor = Color3.fromRGB(245, 245, 255)
		elseif flying then
			highlight.Enabled = true
			highlight.FillColor = Color3.fromRGB(230, 60, 80)
		elseif character:GetAttribute("SuperArmor") == true then
			highlight.Enabled = true
			highlight.FillColor = Color3.fromRGB(255, 140, 50)
		elseif character:GetAttribute("Blocking") == true then
			highlight.Enabled = true
			highlight.FillColor = Color3.fromRGB(70, 140, 255)
		else
			local buff = character:GetAttribute("DamageBuff")
			if typeof(buff) == "number" and buff > 1 then
				highlight.Enabled = true
				highlight.FillColor = Color3.fromRGB(80, 200, 255)
			else
				highlight.Enabled = false
			end
		end
		highlight.OutlineColor = highlight.FillColor
	end

	for _, name in { "Stunned", "IFrames", "Flying", "SuperArmor", "Blocking", "DamageBuff" } do
		character:GetAttributeChangedSignal(name):Connect(refresh)
	end
	refresh()
end

function VfxClient.Start()
	VfxKit.StartShake()
	local function hook(target: Player)
		target.CharacterAdded:Connect(watchCharacter)
		if target.Character then
			watchCharacter(target.Character)
		end
	end
	Players.PlayerAdded:Connect(hook)
	for _, target in Players:GetPlayers() do
		hook(target)
	end
end

return VfxClient
