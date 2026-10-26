require("deepcore/std/class")
require("deepcore/crossplot/crossplot")
require("PGStoryMode")

---@class ShipMarket
ShipMarket = class()

function ShipMarket:new(gc)
    self.human_player = Find_Player("local")

    self.market_types = require("ShipMarketOptions")

    self.proteus_init = false
    if Find_Player("Imperial_Proteus").Is_Human() == true then
        crossplot:subscribe("PROTEUS_MARKET", self.proteus_init_setup, self)
    end
    self:first_week_setup()

    gc.Events.GalacticProductionStarted:attach_listener(self.on_production_queued, self)
    gc.Events.GalacticProductionCanceled:attach_listener(self.on_production_canceled, self)
    crossplot:subscribe("ADJUST_MARKET_CHANCE", self.adjust_ship_chance, self)
    crossplot:subscribe("ADJUST_MARKET_AMOUNT", self.add_or_remove_amount, self)
    crossplot:subscribe("LOCK_MARKET_OPTIONS", self.lock_or_unlock_options, self)

    self.Events = {}
    self.Events.ShipsAdded = Observable()
end

-- Return a flat list of market entries while preserving the nested data in
-- ShipMarketOptions.lua. PROTEUS_TWO has faction -> group -> market -> data.
function ShipMarket:get_markets(owner)
    local result = {}
    local faction_data = self.market_types[owner]
    if not faction_data then
        return result
    end

    if owner == "IMPERIAL_PROTEUS" then
        if self.proteus_init and self.current_proteus then
            local group_data = faction_data[self.current_proteus]
            if group_data then
                for market, market_data in pairs(group_data) do
                    if type(market_data) == "table" and market_data.list then
                        table.insert(result, {market = market, data = market_data})
                    end
                end
            end
        end
    elseif owner == "PROTEUS_TWO" then
        for group, group_data in pairs(faction_data) do
            if type(group_data) == "table" then
                for market, market_data in pairs(group_data) do
                    if type(market_data) == "table" and market_data.list then
                        table.insert(result, {group = group, market = market, data = market_data})
                    end
                end
            end
        end
    else
        for market, market_data in pairs(faction_data) do
            if type(market_data) == "table" and market_data.list then
                table.insert(result, {market = market, data = market_data})
            end
        end
    end

    return result
end

function ShipMarket:get_market_data(owner, market)
    for _, entry in pairs(self:get_markets(owner)) do
        if entry.market == market then
            return entry.data
        end
    end
    return nil
end

function ShipMarket:first_week_setup()
    -- Imperial Proteus is locked after its group has been selected. Other
    -- factions, including PROTEUS_TWO, can be processed immediately.
    for faction, _ in pairs(self.market_types) do
        if faction ~= "IMPERIAL_PROTEUS" then
            for _, entry in pairs(self:get_markets(faction)) do
                for ship, _ in pairs(entry.data.list) do
                    entry.data.faction_object.Lock_Tech(Find_Object_Type(ship))
                end
            end
        end
    end
end

function ShipMarket:proteus_init_setup()
    --Logger:trace("entering ShipMarket:proteus_init_setup")
    self.proteus_init = true
    self.current_proteus = GlobalValue.Get("PROTEUS_GROUP_NAME")
    for faction, market_tables in pairs(self.market_types) do
        if faction == "IMPERIAL_PROTEUS" then
            for proteus, proteus_data in pairs(market_tables) do
                if proteus ~= self.current_proteus then
                    self.market_types["IMPERIAL_PROTEUS"][proteus] = nil
                else
                    for market, market_data in pairs(proteus_data) do
                        for ship, ship_data in pairs(market_data.list) do
                            market_data.faction_object.Lock_Tech(Find_Object_Type(ship))
                        end
                    end
                end
            end
        end
    end
	crossplot:unsubscribe("PROTEUS_MARKET", self.proteus_init_setup, self)
end

function ShipMarket:update()
    for faction, _ in pairs(self.market_types) do
        if faction == "IMPERIAL_PROTEUS" then
            if self.proteus_init == true then
                for _, entry in pairs(self:get_markets(faction)) do
                    local market_data = entry.data
                    for ship, ship_data in pairs(market_data.list) do
                        if GameRandom.Free_Random(1, 1000) <= ship_data.chance and ship_data.locked == false and ship_data.gc_locked == false then
                            ship_data.amount = ship_data.amount + 1
                            if market_data.faction_object.Is_Human() then
                                self.Events.ShipsAdded:notify {
                                    added = ship_data.readable_name,
                                    market_name = market_data.market_name,
                                    news_colour = market_data.news_colour
                                }
                            end
                        end
                        if ship_data.amount > 0 then
                            market_data.faction_object.Unlock_Tech(Find_Object_Type(ship))
                        end
                    end
                end
            elseif self.proteus_init == false and GetCurrentTime() > 5 then
                crossplot:unsubscribe("PROTEUS_MARKET", self.proteus_init_setup, self)
                self.market_types["IMPERIAL_PROTEUS"] = nil
            end
        else
            for _, entry in pairs(self:get_markets(faction)) do
                local market_data = entry.data
                for ship, ship_data in pairs(market_data.list) do
                    if GameRandom.Free_Random(1, 1000) <= ship_data.chance and ship_data.locked == false and ship_data.gc_locked == false then
                        ship_data.amount = ship_data.amount + 1
                        if market_data.faction_object.Is_Human() then
                            self.Events.ShipsAdded:notify {
                                added = ship_data.readable_name,
                                market_name = market_data.market_name,
                                news_colour = market_data.news_colour
                            }
                        end
                    end
                    if ship_data.amount > 0 then
                        market_data.faction_object.Unlock_Tech(Find_Object_Type(ship))
                    end
                end
            end
        end
    end
end

---@param planet Planet
function ShipMarket:on_production_canceled(planet, game_object_type_name)
    --Logger:trace("entering ShipMarket:on_production_canceled")
    local owner = planet:get_owner().Get_Faction_Name()
    if self.market_types[owner] then
        self:find_market(owner, game_object_type_name, 1)
    end
end

function ShipMarket:on_production_queued(planet, game_object_type_name)
     --Logger:trace("entering ShipMarket:on_production_queued")
    local owner = planet:get_owner().Get_Faction_Name()
    if self.market_types[owner] then
        self:find_market(owner, game_object_type_name, -1)
    end
end

function ShipMarket:find_market(owner, game_object_type_name, adjustment)
    for _, entry in pairs(self:get_markets(owner)) do
        if entry.data.list[game_object_type_name] then
            self:add_or_remove_amount({{owner, entry.market, game_object_type_name, adjustment}})
            return
        end
    end
end

function ShipMarket:add_or_remove_amount(add_or_remove_tables)
    DebugMessage("In ShipMarket:add_or_remove_amount")
    for _, adjustment_data in pairs(add_or_remove_tables) do
        local owner = adjustment_data[1]
        local market = adjustment_data[2]
        local game_object_type_name = adjustment_data[3]
        local adjustment = adjustment_data[4]
        local overwrite = adjustment_data[5]
        local market_data = self:get_market_data(owner, market)
        local ship_data = market_data and market_data.list[game_object_type_name]

        if ship_data then
            if overwrite then
                ship_data.amount = adjustment
            else
                ship_data.amount = ship_data.amount + adjustment
            end
            if ship_data.amount < 1 then
                market_data.faction_object.Lock_Tech(Find_Object_Type(game_object_type_name))
            else
                market_data.faction_object.Unlock_Tech(Find_Object_Type(game_object_type_name))
            end
        end
    end
end

function ShipMarket:adjust_ship_chance(adjustment_tables)
    DebugMessage("In ShipMarket:adjust_ship_chance")
    for _, adjustment_data in pairs(adjustment_tables) do
        local owner = adjustment_data[1]
        local market = adjustment_data[2]
        local game_object_type_name = adjustment_data[3]
        local adjustment = adjustment_data[4]
        local overwrite = adjustment_data[5]
        local market_data = self:get_market_data(owner, market)
        local ship_data = market_data and market_data.list[game_object_type_name]

        if ship_data then
            if overwrite == true then
                ship_data.chance = adjustment
            else
                ship_data.chance = ship_data.chance + adjustment
            end
        end
    end
end

function ShipMarket:lock_or_unlock_options(lock_tables)
    DebugMessage("In ShipMarket:lock_or_unlock_options")
    for _, lock_data in pairs(lock_tables) do
        local owner = lock_data[1]
        local market = lock_data[2]
        local game_object_type_name = lock_data[3]
        local lock = lock_data[4]
        local remove_existing = lock_data[5]
        local gc_lock = lock_data[6]
        local market_data = self:get_market_data(owner, market)
        local ship_data = market_data and market_data.list[game_object_type_name]

        if ship_data then
            if gc_lock == true then
                ship_data.gc_locked = true
            elseif gc_lock == false then
                ship_data.gc_locked = false
            end
            if lock == true then
                ship_data.locked = true
            elseif lock == false then
                ship_data.locked = false
            end
            if remove_existing == true then
                self:add_or_remove_amount({{owner, market, game_object_type_name, 0, true}})
            end
        end
    end
end

function ShipMarket:adjust_ship_requirements(adjustment_tables)
    DebugMessage("In ShipMarket:adjust_ship_requirements")
    for _, adjustment_data in pairs(adjustment_tables) do
        local owner = adjustment_data[1]
        local market = adjustment_data[2]
        local game_object_type_name = adjustment_data[3]
        local new_requirement = adjustment_data[4]
        local market_data = self:get_market_data(owner, market)
        local ship_data = market_data and market_data.list[game_object_type_name]

        if ship_data then
            ship_data.text_requirement = new_requirement
        end
    end
end

return ShipMarket
