--!strict
-- Tells every other client to play a placeholder effect.
-- The caster already played theirs locally when they pressed the key.

local Actions = require(game:GetService("ReplicatedStorage").FightingClasses.Shared.Actions)
local Types = require(game:GetService("ReplicatedStorage").FightingClasses.Shared.Types)
local Remotes = require(script.Parent.Parent.Remotes)

type CastContext = Types.CastContext

local VfxRelay = {}

function VfxRelay.Play(ctx: CastContext, extra: { [string]: any }?)
	local payload: { [string]: any } = {
		action = Actions.Vfx,
		castId = ctx.castId,
		abilityId = ctx.ability.id,
		casterUserId = ctx.player.UserId,
		origin = ctx.origin,
		direction = ctx.direction,
		vfx = ctx.ability.vfx,
	}
	if extra then
		for key, value in extra do
			payload[key] = value
		end
	end
	payload.action = Actions.Vfx
	Remotes.TellOthers(ctx.player, payload)
end

function VfxRelay.Stop(ctx: CastContext)
	Remotes.Tell(ctx.player, {
		action = Actions.VfxStop,
		castId = ctx.castId,
	})
end

return VfxRelay
