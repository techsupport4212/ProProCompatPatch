require("PGStoryMode")
require("deepcore/std/class")
require("deepcore/crossplot/crossplot")
require("eawx-util/UnitUtil")
CONSTANTS = ModContentLoader.get("GameConstants")

BuildLimits = class()

function BuildLimits:new(gc)
	self.initialized = false
	self.p_human = Find_Player("local")
	self.human_faction_name = self.p_human.Get_Faction_Name()

	self.library = require("BuildLimitLibrary")
	self.counts = {}

	crossplot:subscribe("INITIALIZE_AI", self.startup_check, self)

	gc.Events.GalacticProductionStarted:attach_listener(self.on_production_queued, self)
	gc.Events.GalacticProductionCanceled:attach_listener(self.on_production_canceled, self)
	gc.Events.GalacticProductionFinished:attach_listener(self.on_production_finished, self)
	gc.Events.GalacticLimitedUnitKilled:attach_listener(self.on_limited_unit_killed, self)
end

function BuildLimits:update()
	if self.initialized == false then
		return
	end

--selling companies doesn't trigger a death event, so this is necessary to reset concurrency counts
--selling a lifetime limited company will not decrement the lifetime count, so don't do it lightly

--reset current counts
	for company_name,actuals_data in pairs(self.counts) do
		for faction_name,entry_data in pairs(actuals_data) do
			entry_data.current_count = 0
		end
	end

--galactic census
    for company_name,company_data in pairs(self.library) do
        local unit_name = company_name.."_DUMMY"
        if self.library[company_name].alt_name then
            unit_name = self.library[company_name].alt_name
        end
        local all_unit_instances = Find_All_Objects_Of_Type(unit_name)
        local total_count = table.getn(all_unit_instances)

        if total_count > 0 then
            for _,unit_instance in pairs(all_unit_instances) do
                if TestValid(unit_instance.Get_Parent_Object()) then
                    self:change_build_count(company_name, unit_instance.Get_Owner().Get_Faction_Name(), "HEADCOUNT")
                end
            end
        end
    end
end

function BuildLimits:startup_check()
    if self.initialized == true then
        return
    end

    for company_name,company_data in pairs(self.library) do
        local unit_name = company_name.."_DUMMY"
        if self.library[company_name].alt_name then
            unit_name = self.library[company_name].alt_name
        end
        local all_unit_instances = Find_All_Objects_Of_Type(unit_name)
        local total_count = table.getn(all_unit_instances)
        
        if total_count > 0 then
            for _,unit_instance in pairs(all_unit_instances) do
                self:change_build_count(company_name, unit_instance.Get_Owner().Get_Faction_Name(), "INITIAL_SPAWNS")
            end
        end
    end
    
    self.initialized = true
end

function BuildLimits:on_production_queued(planet, company_name)
	if not self.library[company_name] then
		return
	end

	self:change_build_count(company_name, planet:get_owner().Get_Faction_Name(), "QUEUED")
end

function BuildLimits:on_production_canceled(planet, company_name)
	if not self.library[company_name] then
		return
	end

	self:change_build_count(company_name, planet:get_owner().Get_Faction_Name(), "CANCELLED")
end

function BuildLimits:on_production_finished(planet, company_name)
	if not self.library[company_name] then
		return
	end

	self:change_build_count(company_name, planet:get_owner().Get_Faction_Name(), "COMPLETED")
end

function BuildLimits:on_limited_unit_killed(company_name, owner_name)
	if not self.library[company_name] then
		return
	end

	self:change_build_count(company_name, owner_name, "KILLED")
end

function BuildLimits:change_build_count(company_name, faction_name, mode)
	faction_name = self:check_initiation(company_name, faction_name)

	if mode == "QUEUED" then
		self.counts[company_name][faction_name].queued_count = self.counts[company_name][faction_name].queued_count + 1
	elseif mode == "CANCELLED" then
		self.counts[company_name][faction_name].queued_count = self.counts[company_name][faction_name].queued_count - 1
	elseif mode == "COMPLETED" then
		self.counts[company_name][faction_name].queued_count = self.counts[company_name][faction_name].queued_count - 1
		self.counts[company_name][faction_name].current_count = self.counts[company_name][faction_name].current_count + 1
	elseif mode == "KILLED" then
		self.counts[company_name][faction_name].current_count = self.counts[company_name][faction_name].current_count - 1
	elseif mode == "HEADCOUNT" then
		self.counts[company_name][faction_name].current_count = self.counts[company_name][faction_name].current_count + 1
	elseif mode == "INITIAL_SPAWNS" then
		self.counts[company_name][faction_name].current_count = self.counts[company_name][faction_name].current_count + 1
	end

	if not self.library[company_name].lifetime_limit then
		--this space intentionally left blank
	elseif mode == "COMPLETED" then
		self.counts[company_name][faction_name].lifetime_count = self.counts[company_name][faction_name].lifetime_count + 1
	elseif mode == "INITIAL_SPAWNS" then
		self.counts[company_name][faction_name].lifetime_count = self.counts[company_name][faction_name].lifetime_count + 1
	end

	self:enforce_limits(company_name, faction_name)
end

function BuildLimits:enforce_limits(company_name, faction_name)
	faction_name = self:check_initiation(company_name, faction_name)

	-- Lifetime Limits
	if self.library[company_name].lifetime_limit then
		if self.counts[company_name][faction_name].lifetime_count >= self.library[company_name].lifetime_limit then
			if faction_name == "SHARED" then
				for _,faction_name in pairs(CONSTANTS.PLAYABLE_FACTIONS) do
					Find_Player(faction_name).Lock_Tech(Find_Object_Type(company_name))
				end
			else
				Find_Player(faction_name).Lock_Tech(Find_Object_Type(company_name))
			end
			return
		end
	end

	-- Current Limits
	local enable = true
	if self.counts[company_name][faction_name].current_count + self.counts[company_name][faction_name].queued_count >= self.library[company_name].current_limit then
		enable = false
	end

	if faction_name == "SHARED" then
		for _,faction_name in pairs(CONSTANTS.PLAYABLE_FACTIONS) do
			UnitUtil.SetBuildable(Find_Player(faction_name), company_name, enable)
		end
	else
		UnitUtil.SetBuildable(Find_Player(faction_name), company_name, enable)
	end

	-- Slay any in existence in excess of current limit
	-- for the AI too ~Mord
	-- if faction_name ~= self.human_faction_name then
		-- return
	-- end

	-- if self.counts[company_name][faction_name].current_count >= self.library[company_name].current_limit then
	-- 	local to_despawn = self.counts[company_name][faction_name].current_count - self.library[company_name].current_limit
	-- 	for i = 1, to_despawn do
	-- 		local subject = Find_First_Object(company_name.."_DUMMY")
	-- 		subject.Get_Owner().Give_Money(Find_Object_Type(company_name).Get_Build_Cost())
	-- 		subject.Despawn()
	-- 		self.counts[company_name][faction_name].current_count = self.counts[company_name][faction_name].current_count - 1
	-- 	end
	-- end
end

function BuildLimits:check_initiation(company_name, faction_name)
	if self.library[company_name].shared_cap == true then
		faction_name = "SHARED"
	end

	if self.counts[company_name] then
		if self.counts[company_name][faction_name] then
			return faction_name
		end
	else
		self.counts[company_name] = {}
	end

	self.counts[company_name][faction_name] = {}
	self.counts[company_name][faction_name].current_count = 0
	self.counts[company_name][faction_name].queued_count = 0
	if self.library[company_name].lifetime_limit then
		self.counts[company_name][faction_name].lifetime_count = 0
	end

	return faction_name
end

return BuildLimits
