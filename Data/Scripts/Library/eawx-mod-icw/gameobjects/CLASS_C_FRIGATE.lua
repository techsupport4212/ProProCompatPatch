return {
	Ship_Crew_Requirement = 45,
	Fighters = {
		["LIGHT_FIGHTER_HALF"] = {
			DEFAULT = {Initial = 1, Reserve = 2}
		},
		["BOMBER2_HALF"] = {
			DEFAULT = {Initial = 1, Reserve = 0}
		}
	},
	Native = "IMPERIAL",
	Scripts = {"multilayer", "fighter-spawn"},
	Flags = {HANGAR = true}
}