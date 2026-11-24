--!strict
-- Names shared by the client remote and the server remote.
-- There is one client-to-server RemoteEvent and one server-to-client RemoteEvent.

local Actions = {
	Cast = "Cast",
	SetClass = "SetClass",
	SetLoadout = "SetLoadout",
	SetBlock = "SetBlock",
	Parry = "Parry",

	CastResult = "CastResult",
	Vfx = "Vfx",
	VfxStop = "VfxStop",
	MenuResult = "MenuResult",
}

return Actions
