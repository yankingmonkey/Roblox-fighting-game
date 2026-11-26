--!strict
-- Client entry. Builds the HUD and connects keys.

local StarterGui = game:GetService("StarterGui")

local AbilityClient = require(script.Parent.Controllers.AbilityClient)
local CombatFeel = require(script.Parent.Controllers.CombatFeel)
local InputController = require(script.Parent.Controllers.InputController)
local MovementClient = require(script.Parent.Controllers.MovementClient)
local ProceduralAnim = require(script.Parent.Controllers.ProceduralAnim)
local VfxClient = require(script.Parent.Controllers.VfxClient)
local AimHud = require(script.Parent.UI.AimHud)
local ClassSelect = require(script.Parent.UI.ClassSelect)
local CustomizeMenu = require(script.Parent.UI.CustomizeMenu)
local Hotbar = require(script.Parent.UI.Hotbar)
local LoadoutMenu = require(script.Parent.UI.LoadoutMenu)
local MainMenu = require(script.Parent.UI.MainMenu)
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
CombatFeel.Start()
MovementClient.Start()
ProceduralAnim.Start()
VfxClient.Start()
Hotbar.Mount(gui)
ClassSelect.Mount(gui)
LoadoutMenu.Mount(gui)
MainMenu.Mount(gui, function()
	ClassSelect.OpenForPick()
end, function()
	LoadoutMenu.Toggle()
end, function()
	CustomizeMenu.Show()
end)
CustomizeMenu.Mount(gui, function()
	MainMenu.Show()
end)
AimHud.Mount(gui, function()
	return MainMenu.IsOpen() or ClassSelect.IsOpen() or LoadoutMenu.IsOpen() or CustomizeMenu.IsOpen()
end, function()
	return AbilityClient.ShiftLock()
end)
AbilityClient.OnMenu(function()
	MainMenu.Show()
end)

InputController.Start(function()
	return MainMenu.IsOpen() or ClassSelect.IsOpen() or LoadoutMenu.IsOpen() or CustomizeMenu.IsOpen()
end, function()
	LoadoutMenu.Toggle()
end, function()
	AbilityClient.ReturnToMenu()
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
