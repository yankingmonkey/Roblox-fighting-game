--!strict
-- Client entry. Builds the HUD and connects keys.

local StarterGui = game:GetService("StarterGui")

local AbilityClient = require(script.Parent.Controllers.AbilityClient)
local InputController = require(script.Parent.Controllers.InputController)
local MovementClient = require(script.Parent.Controllers.MovementClient)
local ProceduralAnim = require(script.Parent.Controllers.ProceduralAnim)
local VfxClient = require(script.Parent.Controllers.VfxClient)
local ClassSelect = require(script.Parent.UI.ClassSelect)
local Hotbar = require(script.Parent.UI.Hotbar)
local LoadoutMenu = require(script.Parent.UI.LoadoutMenu)
local UiKit = require(script.Parent.UI.UiKit)

local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "FightingClasses"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 20
gui.Parent = playerGui
UiKit.BindScale(gui)

AbilityClient.Start()
MovementClient.Start()
ProceduralAnim.Start()
VfxClient.Start()
Hotbar.Mount(gui)
ClassSelect.Mount(gui)
LoadoutMenu.Mount(gui)

InputController.Start(function()
	return ClassSelect.IsOpen()
end, function()
	LoadoutMenu.Toggle()
end)

-- The custom hotbar replaces the default backpack so the two don't overlap.
task.spawn(function()
	for _ = 1, 8 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
		if ok then
			break
		end
		task.wait(0.25)
	end
end)

print("[FightingClasses] Client ready. Press 1-4 and Q to use abilities, L for the loadout.")
