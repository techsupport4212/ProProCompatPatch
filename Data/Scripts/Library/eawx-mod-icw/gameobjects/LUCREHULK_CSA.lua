return {
	Ship_Crew_Requirement = 1350,
	Fighters = {
		["LIGHT_FIGHTER_DOUBLE"] = {
			DEFAULT = {Initial = 3, Reserve = 12},
			CORPORATE_SECTOR = {Initial = 3, Reserve = 12, TechLevel = GreaterOrEqualTo(99)},
			INDEPENDENT_FORCES = {Initial = 3, Reserve = 12, TechLevel = GreaterOrEqualTo(99)},
			HOSTILE = {Initial = 3, Reserve = 12, TechLevel = GreaterOrEqualTo(99)}
		},
		["R41_STARCHASER_SQUADRON_DOUBLE"] = {
			CORPORATE_SECTOR = {Initial = 3, Reserve = 12},
			INDEPENDENT_FORCES = {Initial = 3, Reserve = 12},
			HOSTILE = {Initial = 3, Reserve = 12},
			IMPERIAL_PROTEUS = {Initial = 3, Reserve = 12}
		},
		["INTERCEPTOR_DOUBLE"] = {
			DEFAULT = {Initial = 2, Reserve = 4}
		},
		["BOMBER2_DOUBLE"] = {
			DEFAULT = {Initial = 3, Reserve = 12},
			REBEL = {Initial = 3, Reserve = 12, TechLevel = GreaterOrEqualTo(4)}
		},
		["BOMBER_DOUBLE"] = {
			REBEL = {Initial = 3, Reserve = 12, TechLevel = LessThan(4)}
		}
	},
	Native = "CORPORATE_SECTOR",
	Scripts = {"multilayer", "fighter-spawn"}
}