--==============================================================================
-- OldSchoolConsumables - AudioEngine.lua
-- World of Warcraft: Midnight (12.0+) Audio Playback & De-Bounce System
--==============================================================================

local addonName, OSC = ...
OSC.Audio = OSC.Audio or {}
local Audio = OSC.Audio

--------------------------------------------------------------------------------
-- Audio Engine State & Constants
--------------------------------------------------------------------------------
Audio.lastPotionTime = 0
Audio.lastFoodTime = 0
Audio.DEBOUNCE_WINDOW = 0.5 -- 500ms window suppresses duplicate spellcast & aura events

-- Supported WoW audio channels (default "Master" ensures audibility)
Audio.CHANNELS = {
    "Master",
    "SFX",
    "Dialog",
    "Ambience",
    "Music",
}

Audio.VALID_CHANNELS = {
    ["Master"]   = true,
    ["SFX"]      = true,
    ["Dialog"]   = true,
    ["Ambience"] = true,
    ["Music"]    = true,
}

Audio.DEFAULT_CHANNEL = "Master"

-- Built-in OSRS audio assets with .wav fallback paths
Audio.DEFAULT_POTION_SOUND  = "Interface\\AddOns\\OldSchoolConsumables\\Sounds\\potion.ogg"
Audio.FALLBACK_POTION_SOUND = "Interface\\AddOns\\OldSchoolConsumables\\Sounds\\potion.wav"

Audio.DEFAULT_FOOD_SOUND    = "Interface\\AddOns\\OldSchoolConsumables\\Sounds\\food.ogg"
Audio.FALLBACK_FOOD_SOUND   = "Interface\\AddOns\\OldSchoolConsumables\\Sounds\\food.wav"

--------------------------------------------------------------------------------
-- Settings Accessors
--------------------------------------------------------------------------------
function Audio:GetSetting(key, default)
    local val
    if OSC.db and OSC.db.profile and OSC.db.profile[key] ~= nil then
        val = OSC.db.profile[key]
    elseif OSC.settings and OSC.settings[key] ~= nil then
        val = OSC.settings[key]
    elseif _G.OldSchoolConsumablesDB and _G.OldSchoolConsumablesDB[key] ~= nil then
        val = _G.OldSchoolConsumablesDB[key]
    elseif OSC.Database and OSC.Database.DefaultSettings and OSC.Database.DefaultSettings[key] ~= nil then
        val = OSC.Database.DefaultSettings[key]
    end

    if val ~= nil then
        return val
    end
    return default
end

function Audio:SetSetting(key, val)
    if OSC.db and OSC.db.profile then
        OSC.db.profile[key] = val
    end
    if OSC.settings then
        OSC.settings[key] = val
    end
    if _G.OldSchoolConsumablesDB then
        _G.OldSchoolConsumablesDB[key] = val
    end
end

function Audio:IsEnabled()
    return Audio:GetSetting("enabled", true) == true
end

function Audio:GetChannel()
    local channel = Audio:GetSetting("soundChannel", Audio.DEFAULT_CHANNEL)
    if channel and Audio.VALID_CHANNELS[channel] then
        return channel
    end
    return Audio.DEFAULT_CHANNEL
end

function Audio:SetChannel(channel)
    if not channel or not Audio.VALID_CHANNELS[channel] then
        return false
    end
    Audio:SetSetting("soundChannel", channel)
    return true
end

function Audio:GetPotionSound()
    return Audio:GetSetting("potionSound", Audio.DEFAULT_POTION_SOUND)
end

function Audio:SetPotionSound(path)
    if type(path) ~= "string" or path == "" then return false end
    Audio:SetSetting("potionSound", path)
    return true
end

function Audio:GetFoodSound()
    return Audio:GetSetting("foodSound", Audio.DEFAULT_FOOD_SOUND)
end

function Audio:SetFoodSound(path)
    if type(path) ~= "string" or path == "" then return false end
    Audio:SetSetting("foodSound", path)
    return true
end

function Audio:SetDebounceWindow(seconds)
    if type(seconds) == "number" and seconds >= 0 then
        Audio.DEBOUNCE_WINDOW = seconds
        return true
    end
    return false
end

function Audio:GetDebounceWindow()
    return Audio.DEBOUNCE_WINDOW
end

function Audio:ResetDebounce()
    Audio.lastPotionTime = 0
    Audio.lastFoodTime = 0
end

--------------------------------------------------------------------------------
-- Internal Sound Playback Helper
--------------------------------------------------------------------------------
local function ExecutePlaySound(soundPath, fallbackDefault, channel)
    local playFn = _G.PlaySoundFile or PlaySoundFile
    if type(playFn) ~= "function" then
        return true
    end

    -- 1. Primary path with specified channel
    local ok, willPlay = pcall(playFn, soundPath, channel)
    if ok and willPlay then
        return true
    end

    -- 2. Primary path without channel (defaults to system SFX channel)
    local okNoChan, willPlayNoChan = pcall(playFn, soundPath)
    if okNoChan and willPlayNoChan then
        return true
    end

    -- 3. Attempt fallback to .wav or alternate format
    local fallbackPaths = {}
    if soundPath:match("%.[oO][gG][gG]$") then
        table.insert(fallbackPaths, soundPath:gsub("%.[oO][gG][gG]$", ".wav"))
    elseif soundPath:match("%.[wW][aA][vV]$") then
        table.insert(fallbackPaths, soundPath:gsub("%.[wW][aA][vV]$", ".ogg"))
    end
    if fallbackDefault and fallbackDefault ~= soundPath then
        table.insert(fallbackPaths, fallbackDefault)
    end
    -- Also include direct numeric sound IDs in Sounds/ directory
    if soundPath:lower():find("potion") then
        table.insert(fallbackPaths, "Interface\\AddOns\\OldSchoolConsumables\\Sounds\\2401.wav")
    elseif soundPath:lower():find("food") then
        table.insert(fallbackPaths, "Interface\\AddOns\\OldSchoolConsumables\\Sounds\\2393.wav")
    end

    for _, altPath in ipairs(fallbackPaths) do
        local okAlt, willPlayAlt = pcall(playFn, altPath, channel)
        if okAlt and willPlayAlt then
            return true
        end
        local okAltDef, willPlayAltDef = pcall(playFn, altPath)
        if okAltDef and willPlayAltDef then
            return true
        end
    end

    return false
end

--------------------------------------------------------------------------------
-- Core Playback Methods
--------------------------------------------------------------------------------

--- Plays the drinking sound effect for potions, flasks, and health draughts.
-- @param force boolean If true, bypasses addon enabled status and de-bounce timing.
-- @return boolean true if sound playback triggered, false if blocked or disabled.
function Audio:PlayPotionSound(force)
    if not force and not Audio:IsEnabled() then
        return false
    end

    local getTimeFn = _G.GetTime or GetTime
    local now = (type(getTimeFn) == "function" and getTimeFn()) or 0

    if not force and Audio.lastPotionTime > 0 and (now >= Audio.lastPotionTime) and (now - Audio.lastPotionTime < Audio.DEBOUNCE_WINDOW) then
        return false
    end
    Audio.lastPotionTime = now

    local soundPath = Audio:GetPotionSound()
    local channel = Audio:GetChannel()

    ExecutePlaySound(soundPath, Audio.FALLBACK_POTION_SOUND, channel)
    return true
end

--- Plays the eating sound effect for food, feasts, and mage buns.
-- @param force boolean If true, bypasses addon enabled status and de-bounce timing.
-- @return boolean true if sound playback triggered, false if blocked or disabled.
function Audio:PlayFoodSound(force)
    if not force and not Audio:IsEnabled() then
        return false
    end

    local getTimeFn = _G.GetTime or GetTime
    local now = (type(getTimeFn) == "function" and getTimeFn()) or 0

    if not force and Audio.lastFoodTime > 0 and (now >= Audio.lastFoodTime) and (now - Audio.lastFoodTime < Audio.DEBOUNCE_WINDOW) then
        return false
    end
    Audio.lastFoodTime = now

    local soundPath = Audio:GetFoodSound()
    local channel = Audio:GetChannel()

    ExecutePlaySound(soundPath, Audio.FALLBACK_FOOD_SOUND, channel)
    return true
end

--- Dispatches playback based on the consumable category type.
-- @param consumableType string "potion", "flask", "health", "food", "feast", "magebun"
-- @param force boolean If true, bypasses de-bounce check and enabled check.
-- @return boolean true if sound playback triggered.
function Audio:PlayConsumableSound(consumableType, force)
    if not consumableType then return false end
    if consumableType == "potion" or consumableType == "flask" or consumableType == "health" then
        return Audio:PlayPotionSound(force)
    elseif consumableType == "food" or consumableType == "feast" or consumableType == "magebun" then
        return Audio:PlayFoodSound(force)
    end
    return false
end

--------------------------------------------------------------------------------
-- UI & Options Test Helpers
--------------------------------------------------------------------------------

--- Tests the potion sound effect unconditionally.
function Audio:TestPotion()
    return Audio:PlayPotionSound(true)
end

--- Tests the food sound effect unconditionally.
function Audio:TestFood()
    return Audio:PlayFoodSound(true)
end
