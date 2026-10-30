--==============================================================================
-- OldSchoolConsumables - Core.lua
-- World of Warcraft: Midnight (12.0+) Core Integration, SavedVariables & Slash Commands
--==============================================================================

local addonName, OSC = ...
addonName = addonName or "OldSchoolConsumables"
OSC = OSC or {}
_G.OldSchoolConsumables = OSC

--------------------------------------------------------------------------------
-- Table Utility Functions
--------------------------------------------------------------------------------

local function DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == "table" then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = DeepCopy(orig_value)
        end
    else
        copy = orig
    end
    return copy
end

local function MergeDefaults(target, defaults)
    if type(target) ~= "table" or type(defaults) ~= "table" then
        return
    end
    for k, v in pairs(defaults) do
        if target[k] == nil then
            if type(v) == "table" then
                target[k] = DeepCopy(v)
            else
                target[k] = v
            end
        elseif type(v) == "table" and type(target[k]) == "table" then
            MergeDefaults(target[k], v)
        end
    end
end

--------------------------------------------------------------------------------
-- Addon Lifecycle & SavedVariables
--------------------------------------------------------------------------------

function OSC:OnAddonLoaded(loadedAddon)
    if loadedAddon ~= addonName then return end

    -- SavedVariables Management
    if _G.OldSchoolConsumablesDB == nil then
        if OSC.Database and OSC.Database.DefaultSettings then
            _G.OldSchoolConsumablesDB = DeepCopy(OSC.Database.DefaultSettings)
        else
            _G.OldSchoolConsumablesDB = {}
        end
    else
        if OSC.Database and OSC.Database.DefaultSettings then
            MergeDefaults(_G.OldSchoolConsumablesDB, OSC.Database.DefaultSettings)
        end
    end

    OSC.settings = _G.OldSchoolConsumablesDB

    -- Initialize custom IDs
    if OSC.Database and OSC.Database.SyncCustomIDs then
        OSC.Database:SyncCustomIDs(OSC.settings.customSpellIDs, OSC.settings.customItemIDs)
    end

    -- Initialize Trigger Engine
    if OSC.Trigger and OSC.Trigger.Init then
        OSC.Trigger:Init()
    end

    -- Initialize Blizzard Settings
    if OSC.BlizzardSettings then
        if OSC.BlizzardSettings.Init then
            OSC.BlizzardSettings:Init()
        elseif OSC.BlizzardSettings.Register then
            OSC.BlizzardSettings:Register()
        end
    end

    -- Yellow startup message to chat
    local printFn = _G.print or print
    if type(printFn) == "function" then
        printFn("|cffffd100OldSchoolConsumables|r v1.0.0 loaded! Type |cffffd100/osc|r for settings.")
    end
end

-- Initialization Frame for ADDON_LOADED
local initFrame
if type(CreateFrame) == "function" then
    initFrame = CreateFrame("Frame", "OSC_InitFrame")
    initFrame:RegisterEvent("ADDON_LOADED")
    initFrame:SetScript("OnEvent", function(self, event, loadedAddon, ...)
        if event == "ADDON_LOADED" and loadedAddon == addonName then
            OSC:OnAddonLoaded(loadedAddon)
            if self.UnregisterEvent then
                self:UnregisterEvent("ADDON_LOADED")
            end
        end
    end)
else
    -- Fallback mock frame for headless environments
    initFrame = {
        RegisterEvent = function() end,
        UnregisterEvent = function() end,
        SetScript = function() end,
    }
end
OSC.initFrame = initFrame

--------------------------------------------------------------------------------
-- Slash Command Handlers & Registration
--------------------------------------------------------------------------------

_G.SLASH_OLDSCHOOLCONSUMABLES1 = "/osc"
_G.SLASH_OLDSCHOOLCONSUMABLES2 = "/runescape"
_G.SLASH_OLDSCHOOLCONSUMABLES3 = "/rsc"

local SlashList = _G.SlashCmdList or {}
_G.SlashCmdList = SlashList

SlashList["OLDSCHOOLCONSUMABLES"] = function(msg)
    local cmd = ""
    if type(msg) == "string" then
        cmd = msg:match("^%s*(.-)%s*$"):lower()
    end

    local printFn = _G.print or print

    if cmd == "" or cmd == "config" or cmd == "ui" then
        if OSC.UI and OSC.UI.ToggleWindow then
            OSC.UI:ToggleWindow()
        end
    elseif cmd == "test" or cmd == "potion" or cmd == "pot" then
        if OSC.Audio and OSC.Audio.TestPotion then
            OSC.Audio:TestPotion()
            if type(printFn) == "function" then
                printFn("|cffffd100OldSchoolConsumables|r: Playing potion test sound.")
            end
        end
    elseif cmd == "testfood" or cmd == "food" then
        if OSC.Audio and OSC.Audio.TestFood then
            OSC.Audio:TestFood()
            if type(printFn) == "function" then
                printFn("|cffffd100OldSchoolConsumables|r: Playing food test sound.")
            end
        end
    elseif cmd == "overhead" or cmd == "text" then
        if OSC.settings then
            OSC.settings.overheadText = not OSC.settings.overheadText
            local status = OSC.settings.overheadText and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"
            if type(printFn) == "function" then
                printFn("|cffffd100OldSchoolConsumables|r: Overhead text display is now " .. status .. ".")
            end
            if OSC.UI and OSC.UI.RefreshWindow then
                OSC.UI:RefreshWindow()
            end
            if OSC.BlizzardSettings and OSC.BlizzardSettings.RefreshUI then
                OSC.BlizzardSettings:RefreshUI()
            end
        end
    elseif cmd == "help" then
        if type(printFn) == "function" then
            printFn("|cffffd100OldSchoolConsumables Slash Commands:|r")
            printFn("  |cffffd100/osc|r, |cffffd100/runescape|r, |cffffd100/rsc|r - Open/toggle settings window")
            printFn("  |cffffd100/osc test|r (or |cffffd100/osc pot|r) - Play test potion sound")
            printFn("  |cffffd100/osc food|r (or |cffffd100/osc testfood|r) - Play test food sound")
            printFn("  |cffffd100/osc overhead|r - Toggle overhead floating text display")
            printFn("  |cffffd100/osc help|r - Show available commands")
        end
    else
        if type(printFn) == "function" then
            printFn("|cffffd100OldSchoolConsumables|r: Unknown command '|cffffffff" .. tostring(msg) .. "|r'. Type |cffffd100/osc help|r for available commands.")
        end
    end
end
