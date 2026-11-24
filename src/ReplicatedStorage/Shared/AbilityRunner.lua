--!strict
-- Bridge from an ability module (which the client also loads for names and
-- numbers) to the server-only AbilityFx module. Call() is server-only.

local AbilityRunner = {}

function AbilityRunner.Call(methodName: string, ctx: any): boolean?
	local rootName = script.Parent.Parent.Name
	local serverRoot = game:GetService("ServerScriptService"):FindFirstChild(rootName)
	if not serverRoot then
		error("Could not find ServerScriptService." .. rootName)
	end
	local services = serverRoot:WaitForChild("Services")
	local abilityFx = require(services:WaitForChild("AbilityFx"))
	local method = abilityFx[methodName]
	if type(method) ~= "function" then
		error("AbilityFx has no " .. methodName)
	end
	return method(ctx)
end

return AbilityRunner
