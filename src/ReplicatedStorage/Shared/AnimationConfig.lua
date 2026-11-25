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

local AnimationConfig = {
	Overrides = overrides,
}

function AnimationConfig.Clip(poseName: string): string
	return overrides[poseName] or ""
end

return AnimationConfig
