return {
	Ship_Crew_Requirement = 110,
	Fighters = {
		["ELITE_INTERCEPTOR"] = {
			DEFAULT = {Initial = 1, Reserve = 2},
		},
		["BOMBER2"] = {
			DEFAULT = {Initial = 1, Reserve = 2}
		}
	},
	Native = "IMPERIAL",
	Scripts = {"multilayer", "fighter-spawn", "single-unit-retreat"},
	Flags = {HANGAR = true}
}