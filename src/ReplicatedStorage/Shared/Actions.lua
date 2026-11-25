--!strict
-- Names shared by the client remote and the server remote.
-- There is one client-to-server RemoteEvent and one server-to-client RemoteEvent.

local Actions = {
	Cast = "Cast",
	SetClass = "SetClass",
	SetLoadout = "SetLoadout",
	SetBlock = "SetBlock",
	Parry = "Parry",
	M1 = "M1",
	Dash = "Dash",

	CastResult = "CastResult",
	DashResult = "DashResult",
	Vfx = "Vfx",
	VfxStop = "VfxStop",
	Impact = "Impact",
	MenuResult = "MenuResult",
}

return Actions
