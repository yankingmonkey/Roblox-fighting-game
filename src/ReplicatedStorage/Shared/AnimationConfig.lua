--!strict
-- Drop your uploaded R15 animation ids here to replace the procedural poses.
-- Leave a string empty ("") to keep the pose built in code.
-- Example: Punch1 = "rbxassetid://1234567890",
-- Upload an FBX from the Avatar tab in Studio, then paste the id.
-- Procedural joint angles live in Controllers/ProceduralAnim.lua.

local overrides: { [string]: string } = {
	Idle = "",
	Punch1 = "",
	Punch2 = "",
	Punch3 = "",
	Punch4 = "",
	Flurry = "",
	Cast = "",
	Charge = "",
	Dash = "",
	Flight = "",
	Stomp = "",
	Ult = "",
	Hit = "",
	Knockback = "",
	Block = "",
}

local MoveAnims = require(script.Parent.MoveAnims)

local AnimationConfig = {
	Overrides = overrides,
	-- Screen shake strength for CombatFeel. Settings can scale this 0 to 1.
	ShakeScale = 1,
	-- Photosensitivity. Settings turns impact flashes off.
	ImpactFlashes = true,
}

function AnimationConfig.Clip(poseName: string): string
	return overrides[poseName] or ""
end

function AnimationConfig.Feel(moveId: string)
	return MoveAnims[moveId] or MoveAnims.Punch1
end

function AnimationConfig.ImpactAt(moveId: string): number
	local feel = AnimationConfig.Feel(moveId)
	return feel.anticipation + feel.smear
end

function AnimationConfig.Length(moveId: string): number
	local feel = AnimationConfig.Feel(moveId)
	return feel.anticipation + feel.smear + feel.contact + feel.recovery
end

return AnimationConfig
