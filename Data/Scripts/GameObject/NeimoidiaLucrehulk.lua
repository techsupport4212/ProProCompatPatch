require("PGBase")
require("PGStateMachine")
require("PGStoryMode")
require("PGSpawnUnits")

function Definitions()
    DebugMessage("%s -- In Definitions", tostring(Script))

    Define_State("State_Init", State_Init);
end


function State_Init(message)
    if message == OnEnter then
        if Get_Game_Mode() ~= "Galactic" then
            ScriptExit()
        end

        local owner = Object.Get_Owner()
        owner.Lock_Tech(Find_Object_Type("Lucrehulk_Auxiliary"))
        owner.Unlock_Tech(Find_Object_Type("Lucrehulk_Battleship"))
        owner.Unlock_Tech(Find_Object_Type("Lucrehulk_CSA"))
        
        Object.Despawn()
        ScriptExit()
    end
end