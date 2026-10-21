--*******************************************
--***  Thrawn's Revenge: Isard's Revenge  ***
--*******************************************

require("PGStoryMode")
require("eawx-util/ChangeOwnerUtilities")
require("eawx-util/StoryUtil")
require("deepcore/crossplot/crossplot")
require("SetFighterResearch")

function Definitions()
	DebugMessage("%s -- In Definitions", tostring(Script))

	StoryModeEvents = {
		Trigger_Determine_Faction = State_Determine_Faction,
		Trigger_Delayed_Initialize = State_Delayed_Initialize,
		Trigger_Rogue_Disappearance = State_Rogue_Disappearance,
		Trigger_Requiem_Appears = State_Requiem_Appears,
		Trigger_NR_Builds_Lusankya = State_NR_Builds_Lusankya,
		Trigger_Isard_Takes_Lusankya = State_Isard_Takes_Lusankya,
	}

	crossplot:galactic()
end

function State_Determine_Faction(message)
	if message == OnEnter then
		local p_newrep = Find_Player("Rebel")
		local p_empire = Find_Player("Empire")

		local tech_unit = Find_Object_Type("TURR_PHENNIR_TIE_INTERCEPTOR_LOCATION_SET")
		p_empire.Lock_Tech(tech_unit)

		local tech_unit = Find_Object_Type("DUMMY_SALM_BWING")
		p_newrep.Lock_Tech(tech_unit)

		Clear_Fighter_Hero("ERISI_DLARIT_ELITE_SQUADRON")

		local tech_unit = Find_Object_Type("LORRIR_LOCATION_SET")
		p_empire.Unlock_Tech(tech_unit)

		if p_newrep.Is_Human() then
			Story_Event("NR_STORY_START")
		elseif p_empire.Is_Human() then
			Story_Event("GE_STORY_START")
		end
	end
end

function State_Delayed_Initialize(message)
	if message == OnEnter then
		crossplot:publish("COMMAND_STAFF_INITIALIZE", {
			["SUPCOM"] = {
				["SLOT_SET"] = 0,
				["LOCKIN"] = {"Ackbar"},
			},
			["HIGHCOM"] = {
				["SLOT_SET"] = 0,
				["LOCKIN"] = {"Iblis"},
			},
			["ADMIRAL"] = {
				["SLOT_SET"] = 0,
				["LOCKIN"] = {"Vantai","Bell"},
			},
			["ARMY"] = {
				["SLOT_SET"] = 0,
				["LOCKIN"] = {"Cracken"},
			},
			["JEDI"] = {
				["SLOT_SET"] = 0,
			},
		})
		Set_Fighter_Hero("WEDGE_ANTILLES_ROGUE_SQUADRON", "BELL_SWIFT_LIBERTY")
		Set_Fighter_Hero_Index("SALM_LOCATION_SET","SALM_B_WING_SQUADRON")

		crossplot:publish("NR_FILTER_REMOVE", {"Ranulf_Trommer_Location_Set"}, 2)

		--renames
		crossplot:publish("FACTION_DISPLAY_NAME_CHANGE", "EMPIRE", "Ciutric Hegemony")

		crossplot:publish("INITIALIZE_AI", "empty")
	else
		crossplot:update()
	end
end

function State_Rogue_Disappearance(message)
	if message == OnEnter then
		local p_rebel = Find_Player("Rebel")

		crossplot:publish("NR_FILTER_REMOVE", {"Wedge_Rogues_Location_Set"}, 2)
		Clear_Fighter_Hero("WEDGE_ANTILLES_ROGUE_SQUADRON")
	else
		crossplot:update()
	end
end

function State_Requiem_Appears(message)
	if message == OnEnter then
		local p_rebel = Find_Player("Rebel")
		local start_planet = FindPlanet("Ciutric")

		if not StoryUtil.CheckFriendlyPlanet(start_planet,p_rebel) then
			start_planet = StoryUtil.FindFriendlyPlanet(p_rebel)
		end

		local spawn_list_requiem = {"Requiem_Squadron_Space"}
		local RequiemSpawn = SpawnList(spawn_list_requiem, start_planet, p_rebel,false,false)
	end
end

function State_NR_Builds_Lusankya(message)
	if message == OnEnter then
		p_rebel = Find_Player("Rebel")
		start_planet = FindPlanet("Bilbringi")

		if not StoryUtil.CheckFriendlyPlanet(start_planet,p_rebel) then
			start_planet = StoryUtil.FindFriendlyPlanet(p_rebel)
		end

		local spawn_list_lusankya = {"Wedge_Lusankya"}
		local LusankyaSpawn = SpawnList(spawn_list_lusankya, start_planet, p_rebel,false,false)
	end
end

function State_Isard_Takes_Lusankya(message)
	if message == OnEnter then
		local p_empire = Find_Player("Empire")
		local start_planet = FindPlanet("Bilbringi")

		if not StoryUtil.CheckFriendlyPlanet(start_planet,p_empire) then
			start_planet = StoryUtil.FindFriendlyPlanet(p_empire)
		end

		local spawn_list_lusankya = {
			"Isard_Lusankya",
			"TIE_Defender_Squadron_Buildable",
			"TIE_Defender_Squadron_Buildable"
		}
		local LusankyaSpawn = SpawnList(spawn_list_lusankya, start_planet, p_empire,false,false)
	end
end
