--==============================================================================
-- OldSchoolConsumables - TriggerEngine.lua
-- World of Warcraft: Midnight (12.0+) Event Interceptor & Spellcast Classifier
--==============================================================================

local addonName, OSC = ...
OSC.Trigger = {}
local Trigger = OSC.Trigger

--------------------------------------------------------------------------------
-- Event Frame Setup
--------------------------------------------------------------------------------
local eventFrame
if type(CreateFrame) == "function" then
    eventFrame = CreateFrame("Frame", "OSC_EventFrame")
    if eventFrame.Hide then
        eventFrame:Hide()
    end
else
    -- Fallback mock frame for headless environments
    eventFrame = {
        events = {},
        RegisterEvent = function(self, evt) self.events[evt] = true end,
        UnregisterEvent = function(self, evt) self.events[evt] = nil end,
        UnregisterAllEvents = function(self) self.events = {} end,
        SetScript = function(self, handler, fn) self[handler] = fn end,
    }
end

Trigger.eventFrame = eventFrame
Trigger.initialized = false
Trigger.playerGUID = nil

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------
local function GetPlayerGUID()
    if not Trigger.playerGUID and type(UnitGUID) == "function" then
        Trigger.playerGUID = UnitGUID("player")
    end
    return Trigger.playerGUID
end

local function IsCategoryEnabled(category)
    if not category then return false end
    if OSC.Database and OSC.Database.IsCategoryEnabled then
        local catConfig = (OSC.settings and OSC.settings.categories) or OSC.settings
        return OSC.Database:IsCategoryEnabled(category, catConfig)
    end
    if OSC.settings and OSC.settings.categories then
        local key = (OSC.Database and OSC.Database.CategoryToSettingKey and OSC.Database.CategoryToSettingKey[category]) or category
        if OSC.settings.categories[key] ~= nil then
            return OSC.settings.categories[key] == true
        end
    end
    return true
end

Trigger.IsCategoryEnabled = IsCategoryEnabled

function Trigger:TriggerPotion(force)
    if OSC.Audio and OSC.Audio.PlayPotionSound then
        OSC.Audio:PlayPotionSound(force or false)
    end
    if OSC.settings and OSC.settings.overheadText and OSC.Overhead and OSC.Overhead.TriggerPotionText then
        OSC.Overhead:TriggerPotionText()
    end
end

function Trigger:TriggerFood(force)
    if OSC.Audio and OSC.Audio.PlayFoodSound then
        OSC.Audio:PlayFoodSound(force or false)
    end
    if OSC.settings and OSC.settings.overheadText and OSC.Overhead and OSC.Overhead.TriggerFoodText then
        OSC.Overhead:TriggerFoodText()
    end
end

--------------------------------------------------------------------------------
-- Event Dispatcher
--------------------------------------------------------------------------------
function Trigger:OnEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
        GetPlayerGUID()
        return
    end

    if OSC.settings and OSC.settings.enabled == false then
        return
    end

    -- 1. Direct Spellcast Succeeded (Instant Potions, Flasks, Food Clicks)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unitTarget, castGUID, spellID = ...
        if unitTarget ~= "player" then return end
        if not spellID or not OSC.Database then return end

        local isPotion, potCat = OSC.Database:IsConsumablePotion(spellID)
        if isPotion then
            if IsCategoryEnabled(potCat) then
                Trigger:TriggerPotion(false)
            end
            return
        end

        local isFood, foodCat = OSC.Database:IsConsumableFood(spellID)
        if isFood then
            if IsCategoryEnabled(foodCat) then
                Trigger:TriggerFood(false)
            end
            return
        end

    -- 2. Combat Log Interception (Authoritative Combat Potion & Buff Detection)
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local combatLogFn = _G.CombatLogGetCurrentEventInfo or CombatLogGetCurrentEventInfo
        if type(combatLogFn) == "function" then
            local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName = combatLogFn()
            local pGUID = GetPlayerGUID()

            if sourceGUID and pGUID and sourceGUID == pGUID and subevent == "SPELL_CAST_SUCCESS" then
                if spellID and OSC.Database then
                    local isPotion, potCat = OSC.Database:IsConsumablePotion(spellID, nil, spellName)
                    if isPotion and IsCategoryEnabled(potCat) then
                        Trigger:TriggerPotion(false)
                        return
                    end

                    local isFood, foodCat = OSC.Database:IsConsumableFood(spellID, nil, spellName)
                    if isFood and IsCategoryEnabled(foodCat) then
                        Trigger:TriggerFood(false)
                        return
                    end
                end
            elseif destGUID and pGUID and destGUID == pGUID and (subevent == "SPELL_AURA_APPLIED" or subevent == "SPELL_AURA_REFRESH") then
                if spellID and OSC.Database then
                    local isPotion, potCat = OSC.Database:IsConsumablePotion(spellID, nil, spellName)
                    if isPotion and IsCategoryEnabled(potCat) then
                        Trigger:TriggerPotion(false)
                        return
                    end

                    local isFood, foodCat = OSC.Database:IsConsumableFood(spellID, nil, spellName)
                    if isFood and IsCategoryEnabled(foodCat) then
                        Trigger:TriggerFood(false)
                        return
                    end
                end
            end
        end

    -- 3. Channeled Consumables (Mage Buns, Feasts, Channeled Drinks)
    elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
        local unitTarget, castGUID, spellID = ...
        if unitTarget ~= "player" then return end
        if not spellID then return end

        local isFood, foodCat = false, nil
        if OSC.Database and OSC.Database.IsConsumableFood then
            isFood, foodCat = OSC.Database:IsConsumableFood(spellID)
        end
        if not isFood and (spellID == 192002 or spellID == 167152 or spellID == 192001) then
            isFood, foodCat = true, "magebun"
        end

        if isFood and IsCategoryEnabled(foodCat) then
            Trigger:TriggerFood(false)
        end

    -- 4. Unit Aura Updates (Secret-Values Safe: inspects plain spellId only)
    elseif event == "UNIT_AURA" then
        local unitTarget, updateInfo = ...
        if unitTarget ~= "player" then return end

        -- Midnight 12.0+ Secret Values Compliance:
        -- Sensitive combat numbers (duration, expirationTime, applications) are opaque secret values.
        -- We strictly inspect ONLY aura.spellId (plain integer) and aura.name (plain string).
        if updateInfo and updateInfo.addedAuras then
            for _, aura in ipairs(updateInfo.addedAuras) do
                local sid = aura.spellId
                local sname = aura.name
                if sid and OSC.Database then
                    local isPotion, potCat = OSC.Database:IsConsumablePotion(sid, nil, sname)
                    if isPotion and IsCategoryEnabled(potCat) then
                        Trigger:TriggerPotion(false)
                    else
                        local isFood, foodCat = OSC.Database:IsConsumableFood(sid, nil, sname)
                        if isFood and IsCategoryEnabled(foodCat) then
                            Trigger:TriggerFood(false)
                        end
                    end
                end
            end
        end

        if updateInfo and updateInfo.updatedAuraInstanceIDs and C_UnitAuras and type(C_UnitAuras.GetAuraDataByAuraInstanceID) == "function" then
            for _, auraInstanceID in ipairs(updateInfo.updatedAuraInstanceIDs) do
                local aura = C_UnitAuras.GetAuraDataByAuraInstanceID("player", auraInstanceID)
                if aura and aura.spellId and OSC.Database then
                    local sid = aura.spellId
                    local isPotion, potCat = OSC.Database:IsConsumablePotion(sid, nil, aura.name)
                    if isPotion and IsCategoryEnabled(potCat) then
                        Trigger:TriggerPotion(false)
                    end
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------
function Trigger:Init()
    if Trigger.initialized then return end
    Trigger.initialized = true

    GetPlayerGUID()

    if eventFrame.RegisterEvent then
        eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
        eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        eventFrame:RegisterEvent("UNIT_AURA")
        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        eventFrame:RegisterEvent("PLAYER_LOGIN")

        eventFrame:SetScript("OnEvent", function(self, event, ...)
            Trigger:OnEvent(event, ...)
        end)
    end
end

function Trigger:RegisterEvents()
    Trigger:Init()
end

function Trigger:UnregisterEvents()
    if eventFrame.UnregisterAllEvents then
        eventFrame:UnregisterAllEvents()
        Trigger.initialized = false
    end
end
