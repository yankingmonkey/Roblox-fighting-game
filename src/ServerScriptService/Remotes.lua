--!strict
-- One remote for client requests, one remote for server messages.
-- Created as soon as the server starts so clients can WaitForChild them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("Remotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
end

local function remote(name: string): RemoteEvent
	local existing = folder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = folder
	return event
end

local actionEvent = remote("Action")
local notifyEvent = remote("Notify")

local Remotes = {
	Action = actionEvent,
	Notify = notifyEvent,
}

function Remotes.Tell(player: Player, payload: any)
	notifyEvent:FireClient(player, payload)
end

function Remotes.TellAll(payload: any)
	for _, other in game:GetService("Players"):GetPlayers() do
		notifyEvent:FireClient(other, payload)
	end
end

function Remotes.TellOthers(except: Player, payload: any)
	for _, other in game:GetService("Players"):GetPlayers() do
		if other ~= except then
			notifyEvent:FireClient(other, payload)
		end
	end
end

return Remotes
