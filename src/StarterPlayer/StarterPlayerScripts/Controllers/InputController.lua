--!strict
-- Keyboard controls. The on-screen buttons call the same functions, so phones
-- can play without a keyboard.
--   1 2 3 4  ability slots
--   Q        ultimate
--   L        loadout menu
--   F        hold to block (starter hook)
--   R        tap to parry (starter hook)

local UserInputService = game:GetService("UserInputService")

local AbilityClient = require(script.Parent.AbilityClient)

local SLOT_KEYS: { [Enum.KeyCode]: number } = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Q] = 5,
}

local InputController = {}

function InputController.Start(isMenuOpen: () -> boolean, toggleLoadout: () -> ())
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		if input.KeyCode == Enum.KeyCode.L then
			toggleLoadout()
			return
		end
		if isMenuOpen() then
			return
		end
		local slot = SLOT_KEYS[input.KeyCode]
		if slot then
			AbilityClient.Cast(slot)
		elseif input.KeyCode == Enum.KeyCode.F then
			AbilityClient.SetBlock(true)
		elseif input.KeyCode == Enum.KeyCode.R then
			AbilityClient.Parry()
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.KeyCode == Enum.KeyCode.F then
			AbilityClient.SetBlock(false)
		end
	end)
end

return InputController
