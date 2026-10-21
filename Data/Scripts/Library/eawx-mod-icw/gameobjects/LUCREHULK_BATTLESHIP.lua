return {
	Ship_Crew_Requirement = 1350,
	Fighters = {
		["BLASTBOAT"] = {
			IMPERIAL_PROTEUS = {Initial = 1, Reserve = 4}
		},
		["ELITE_INTERCEPTOR"] = {
			DEFAULT = {Initial = 1, Reserve = 4},
			INDEPENDENT_FORCES = {Initial = 1, Reserve = 4, TechLevel = GreaterThan(99)},
		},
		["BOMBER2"] = {
			DEFAULT = {Initial = 1, Reserve = 4}
		}
	},
	Native = "IMPERIAL",
	Scripts = {"multilayer", "fighter-spawn"}
}