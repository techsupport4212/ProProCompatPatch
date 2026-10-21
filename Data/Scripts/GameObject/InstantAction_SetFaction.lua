--//////////////////////////////////////////////////////////////////////////////////////
-- Add Units to the reinforcement pool// This script is part of the Survival Mode
-- � Pox
--//////////////////////////////////////////////////////////////////////////////////////

require("PGBase")
require("PGStateMachine")
require("PGStoryMode")
require("eawx-util/MissionUtil")

function Definitions()
	
	DebugMessage("%s -- In Definitions", tostring(Script))

	Define_State("State_Init", State_Init);


end


function State_Init(message)
	if message == OnEnter then
		if Get_Game_Mode() ~= "Space" then
			ScriptExit()
		end
		local setterName = Object.Get_Type().Get_Name()
		local factionName = string.gsub(setterName, "IA_SET_", "")
		GlobalValue.Set("IA_FACTION", factionName)
		if factionName == "IMPERIAL_PROTEUS" then
			local proteus_groups = {
			[1]	 = {"ANTEMERIDIAS", "Antemeridian Sector"},
			[2]	 = {"ARDA", "Imperial Arda"},
			[3]	 = {"BAKURA", "Imperial Bakura"},
			[4]	 = {"BRAK", "Brak Sector"},
			[5]	 = {"CATO_NEIMOIDIA", "Imperial Neimoidia"},
			[6]	 = {"CIUTRIC_HEGEMONY", "Ciutric Hegemony"},
			[7]	 = {"DASTA", "D'Astan Sector"},
			[8]	 = {"ELROOD", "Elrood Sector"},
			[9]	 = {"GAROS",  "Imperial Garos"},
			[10] = {"HAMMERS", "Imperial Hammers"},
			[11] = {"IMPERIAL_LIANNA", "Imperial Lianna"},
			[12] = {"ISECTOR",  "I-sector"},
			[13] = {"JARDEEN", "Imperial Jardeen"},
			[14] = {"KAARENTH_DISSENSION", "Kaarenth Dissension"},
			[15] = {"KAMINO", "Imperial Kamino"},
			[16] = {"KASHYYYK", "Imperial Kashyyyk"},
			[17] = {"KUAT", "Kuat Sector"},
			[18] = {"LAMBDA", "Lambda Sector"},
			[19] = {"LUMIYA", "Lumiya's Sith"},
			[20] = {"MAELSTROM", "Maelstrom Command"},
			[21] = {"NABOO", "Imperial Naboo"},
			[22] = {"PRAKITH", "Protectorate of Prakith"},
			[23] = {"PRENTIOCH", "Prentioch's Dominion"},
			[24] = {"PROPHETS", "Prophets of the Dark Side"},
			[25] = {"PROTECTORATE",  "The Protectorate"},
			[26] = {"QUINTAD", "The Quintad"},
			[27] = {"RADAMA", "Imperial Ord Radama"},
			[28] = {"RAYTER", "Rayter Sector"},
			[29] = {"RESTORED_EMPIRE", "Restored Empire"},
			[30] = {"SECTOR_5", "Sector 5"},
			[31] = {"SELLASAS", "Imperial Sellasas"},
			[32] = {"SHADOWSPAWN", "Shadow Realm"},
			[33] = {"TAGGE", "House of Tagge"},
			[34] = {"TAMARIN", "Tamarin Sector"},
			[35] = {"TAPANI", "Tapani Sector"},
			[36] = {"TIERFON", "Tierfon Sector"},
			[37] = {"VOGEL", "Dustig Oversector"},
			[38] = {"WESSEX", "Relgim Oversector"},
			[39] = {"WILD_SPACE", "Delurin's Empire"},
			[40] = {"ZAARIN_REMNANTS", "Zaarin Remnants"},
			[41] = {"ZERO_COMMAND", "Zero Command"},
			[42] = {"ZSINJ_REMNANTS", "Zsinj Remnants"},
			}
		
			local index = GlobalValue.Get("CURRENT_PROTEUS_INDEX")
			index = index + 1
			if index > table.getn(proteus_groups) then
				index = 1
			end
			local proteus_group_name = proteus_groups[index][1]
			local proteus_friendly_name = proteus_groups[index][2]
			GlobalValue.Set("PROTEUS_GROUP_NAME",proteus_group_name)
			StoryUtil.ShowScreenText("Imperial Proteus group set to "..proteus_friendly_name..". Group: "..tostring(index).." / "..tostring(table.getn(proteus_groups)), 10, nil, {r=255, g=255, b=255})
			GlobalValue.Set("CURRENT_PROTEUS_INDEX", index)
		end

		ScriptExit()
		
	end
end