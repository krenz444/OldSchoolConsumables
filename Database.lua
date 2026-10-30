--==============================================================================
-- OldSchoolConsumables - Database.lua
-- World of Warcraft: Midnight (12.0+) Consumables Database & Registry
--==============================================================================

local addonName, OSC = ...
OSC.Database = {}
local DB = OSC.Database

--------------------------------------------------------------------------------
-- Default Configuration Schema
--------------------------------------------------------------------------------
DB.DefaultSettings = {
    enabled = true,
    soundChannel = "Master", -- Master, SFX, Dialog, Ambience, Music
    volume = 1.0,
    potionSound = "Interface\\AddOns\\OldSchoolConsumables\\Sounds\\potion.ogg",
    foodSound = "Interface\\AddOns\\OldSchoolConsumables\\Sounds\\food.ogg",
    categories = {
        flasks = true,
        potions = true,
        health = true,
        feasts = true,
        food = true,
        magebuns = true,
    },
    overheadText = false, -- Disabled by default per user specification
    overheadPotText = "*Gulp*",
    overheadFoodText = "*Chomp*",
    customItemIDs = {},
    customSpellIDs = {},
}

--------------------------------------------------------------------------------
-- Category Mapping Tables
--------------------------------------------------------------------------------
DB.CategoryToSettingKey = {
    flask   = "flasks",
    potion  = "potions",
    health  = "health",
    feast   = "feasts",
    food    = "food",
    magebun = "magebuns",
}

DB.SettingKeyToCategory = {
    flasks   = "flask",
    potions  = "potion",
    health   = "health",
    feasts   = "feast",
    food     = "food",
    magebuns = "magebun",
}

--------------------------------------------------------------------------------
-- Fast Lookup Caches (Populated at Load Time)
--------------------------------------------------------------------------------
DB.PotionSpells = {} -- [spellID] = "flask" | "potion" | "health"
DB.PotionItems  = {} -- [itemID]  = "flask" | "potion" | "health"
DB.FoodSpells   = {} -- [spellID] = "feast" | "food"   | "magebun"
DB.FoodItems    = {} -- [itemID]  = "feast" | "food"   | "magebun"

DB.BuiltinPotionSpells = {}
DB.BuiltinPotionItems  = {}
DB.BuiltinFoodSpells   = {}
DB.BuiltinFoodItems    = {}

DB.CustomSpellIDs = {}
DB.CustomItemIDs  = {}

--------------------------------------------------------------------------------
-- Midnight 12.0+ & Core Consumable Database Definitions
-- Strictly compliant with Midnight secret values (stores static numeric IDs only)
--------------------------------------------------------------------------------
DB.Consumables = {
    flasks = {
        category = "flask",
        entries = {
            {
                name = "Flask of the Shattered Sun",
                buff = 1235111,
                items = { 245929, 245928, 241326, 241327 },
            },
            {
                name = "Flask of the Magisters",
                buff = 1235108,
                items = { 245933, 245932, 241322, 241323 },
            },
            {
                name = "Flask of the Blood Knights",
                buff = 1235110,
                items = { 245931, 245930, 241324, 241325 },
            },
            {
                name = "Flask of Thalassian Resistance",
                buff = 1235057,
                items = { 245926, 245927, 241320, 241321 },
            },
            {
                name = "Vicious Thalassian Flask of Honor",
                buff = 1239355,
            },
            {
                name = "Midnight PvP Flasks",
                spells = { 1235113, 1235114, 1235115, 1235116 },
            },
            {
                name = "Freightrunner's Flask",
                spell = 1250533,
                item = 250215,
            },
            {
                name = "Prepare Midnight Flask Cauldron",
                spells = { 1240019, 1240195 },
            },
            {
                name = "The War Within Flasks",
                spells = { 432473, 432021, 431974, 431973, 431972, 431971 },
                items = { 212739, 212740, 212741, 212735, 212736, 212738, 212732, 212733, 212734, 212775, 212776, 212777 },
            },
        },
    },

    potions = {
        category = "potion",
        entries = {
            {
                name = "Light's Potential",
                spell = 1236616,
                items = { 241308, 241309, 245897, 245898 }, -- Normal r2, r1, Fleeting r1, r2
            },
            {
                name = "Potion of Recklessness",
                spell = 1236994,
                items = { 241288, 241289, 245902, 245903 },
            },
            {
                name = "Draught of Rampant Abandon",
                spells = { 1236998, 1237154 },
                items = { 241292, 241293 },
            },
            {
                name = "Potion of Zealotry",
                spells = { 1238443, 1237158 },
                items = { 241296, 241297, 245900, 245901 },
            },
            {
                name = "Liquid Luster",
                spell = 1295132,
                items = { 271887, 274764, 274763, 271886 },
            },
            {
                name = "Potion of Devoured Dreams",
                spell = 1239479,
            },
            {
                name = "Prepare Midnight Potion Cauldron",
                spells = { 1240225, 1240267 },
            },
            {
                name = "Haranir Phial of Perception",
                spell = 1236763,
            },
            {
                name = "Haranir Phial of Finesse",
                spell = 1236767,
            },
            {
                name = "Haranir Phial of Ingenuity",
                spell = 1239755,
            },
            {
                name = "Murder Row Swiftstrike Phial",
                spells = { 1259280, 1259591 },
            },
            {
                name = "The War Within Combat Potions",
                spells = { 431932, 431914, 431925, 431941 },
                items = { 212963, 212964, 212965, 212966, 212967, 212968, 212969, 212970, 212971, 212972, 212973, 212974 },
            },
        },
    },

    health = {
        category = "health",
        entries = {
            {
                name = "Silvermoon Health Potion",
                spell = 1234768,
                items = { 241304, 241305, 271884, 271883 }, -- Normal r2, r1, Concentrated r2, r1
            },
            {
                name = "Invigorating Healing Potion",
                spell = 1238009,
            },
            {
                name = "Emergency Healing Tonic",
                spells = { 1259276, 1259508 },
            },
            {
                name = "Basic Rejuvenation Potion",
                spell = 1236590,
            },
            {
                name = "Lightfused Mana Potion",
                spell = 1236648,
                items = { 241300, 241301, 245916, 245917 },
            },
            {
                name = "Invisibility Potion",
                spells = { 371125, 431424, 371133, 371134, 1236551 },
                items = { 241302, 241303 },
            },
            {
                name = "Healthstone",
                items = { 5512 },
                spells = { 6262 },
            },
            {
                name = "Demonic Healthstone",
                items = { 224464 },
                spells = { 452930, 29893 },
            },
            {
                name = "Algari Healing Potion",
                spells = { 431416, 431417, 431418 },
                items = { 211880, 211878, 211879 },
            },
            {
                name = "Algari Mana Potions",
                spells = { 431422, 431423, 431424 },
                items = { 211883, 211884, 211885 },
            },
            {
                name = "Slumbering Soul Salve",
                spells = { 431425, 431426, 431427 },
            },
            {
                name = "Legacy Healing Potions",
                spells = { 370511, 415569, 359867, 307192, 331974 },
            },
        },
    },

    feasts = {
        category = "feast",
        entries = {
            {
                name = "Quel'dorei Medley",
                spells = { 1259657, 1278915 },
                items = { 266986 },
            },
            {
                name = "Harandar Celebration",
                spells = { 1259658, 1278929 },
                items = { 255846, 266996 },
            },
            {
                name = "Blooming Feast",
                spells = { 1259656, 1237104, 1278909 },
                items = { 242273, 242745 },
            },
            {
                name = "Silvermoon Parade",
                spells = { 1259659, 1278895 },
                items = { 255845, 266985 },
            },
            {
                name = "Mite-y Feast",
                spell = 1243843,
            },
            {
                name = "Feast of the Midnight Masquerade",
                spells = { 445113, 457285, 462213 },
            },
            {
                name = "Feast Items Common",
                items = { 255845, 255846, 242275, 255847, 255848, 242274, 242273, 242745, 266985, 266986, 266996 },
            },
        },
    },

    food = {
        category = "food",
        entries = {
            {
                name = "Refreshment",
                spells = { 1232917, 1232919 },
                items = { 255847, 255848 },
            },
            {
                name = "Hearty Refreshment",
                spells = { 1233767, 1233768 },
                items = { 268679, 268680 },
            },
            {
                name = "Royal Roast, Become Well Fed",
                spell = 1219179,
            },
            {
                name = "Hearty Well Fed",
                spells = { 1232076, 1232078, 1233733 },
            },
            {
                name = "Midnight Well Fed Buffs",
                spells = {
                    1219182, 1219183, 1219184, 1219185,
                    1232086, 1232087, 1232089, 1232091,
                    1232313, 1232316, 1232317, 1232318,
                    1232320, 1232321, 1232324, 1232325,
                    1232490, 1232491, 1232492, 1232493,
                    1232496, 1232498, 1232500, 1232501,
                    1232582, 1232584, 1232585,
                    1233400, 1233401, 1233402, 1233403,
                    1233404, 1233405, 1233406, 1233407, 1233408,
                },
            },
            {
                name = "Generic Eating Channel Spells",
                spells = { 1232065, 1269917, 1269920, 1269921, 1269922, 1277461 },
            },
            {
                name = "The War Within Food & Drinks",
                spells = { 460938 },
            },
        },
    },

    magebuns = {
        category = "magebun",
        entries = {
            {
                name = "Conjured Mana Bun",
                item = 113509,
                spells = { 192002, 192001, 167152 },
            },
            {
                name = "Conjure Refreshment",
                spell = 190336,
            },
            {
                name = "Refreshment Table",
                spell = 43987,
            },
        },
    },
}

--------------------------------------------------------------------------------
-- Lookup Construction
--------------------------------------------------------------------------------
local function RegisterSpell(spellID, category)
    if not spellID then return end
    spellID = tonumber(spellID)
    if not spellID then return end

    if category == "flask" or category == "potion" or category == "health" then
        DB.PotionSpells[spellID] = category
        DB.BuiltinPotionSpells[spellID] = category
    elseif category == "feast" or category == "food" or category == "magebun" then
        DB.FoodSpells[spellID] = category
        DB.BuiltinFoodSpells[spellID] = category
    end
end

local function RegisterItem(itemID, category)
    if not itemID then return end
    itemID = tonumber(itemID)
    if not itemID then return end

    if category == "flask" or category == "potion" or category == "health" then
        DB.PotionItems[itemID] = category
        DB.BuiltinPotionItems[itemID] = category
    elseif category == "feast" or category == "food" or category == "magebun" then
        DB.FoodItems[itemID] = category
        DB.BuiltinFoodItems[itemID] = category
    end
end

function DB:BuildLookups()
    for _, group in pairs(DB.Consumables) do
        local cat = group.category
        if group.entries then
            for _, entry in ipairs(group.entries) do
                if entry.buff then
                    RegisterSpell(entry.buff, cat)
                end
                if entry.spell then
                    RegisterSpell(entry.spell, cat)
                end
                if entry.spells then
                    for _, s in ipairs(entry.spells) do
                        RegisterSpell(s, cat)
                    end
                end
                if entry.item then
                    RegisterItem(entry.item, cat)
                end
                if entry.items then
                    for _, i in ipairs(entry.items) do
                        RegisterItem(i, cat)
                    end
                end
            end
        end
    end
end

-- Initialize built-in lookups immediately
DB:BuildLookups()

--------------------------------------------------------------------------------
-- Custom ID Management & Sync
--------------------------------------------------------------------------------
function DB:AddCustomID(idType, id, category)
    id = tonumber(id)
    if not id or not category then return false end

    if idType == "item" then
        DB.CustomItemIDs[id] = category
        if _G.OldSchoolConsumablesDB and type(_G.OldSchoolConsumablesDB.customItemIDs) == "table" then
            _G.OldSchoolConsumablesDB.customItemIDs[id] = category
        end
        if category == "flask" or category == "potion" or category == "health" then
            DB.PotionItems[id] = category
            DB.FoodItems[id] = nil
        elseif category == "feast" or category == "food" or category == "magebun" then
            DB.FoodItems[id] = category
            DB.PotionItems[id] = nil
        end
        return true
    elseif idType == "spell" then
        DB.CustomSpellIDs[id] = category
        if _G.OldSchoolConsumablesDB and type(_G.OldSchoolConsumablesDB.customSpellIDs) == "table" then
            _G.OldSchoolConsumablesDB.customSpellIDs[id] = category
        end
        if category == "flask" or category == "potion" or category == "health" then
            DB.PotionSpells[id] = category
            DB.FoodSpells[id] = nil
        elseif category == "feast" or category == "food" or category == "magebun" then
            DB.FoodSpells[id] = category
            DB.PotionSpells[id] = nil
        end
        return true
    end
    return false
end

function DB:RemoveCustomID(idType, id)
    id = tonumber(id)
    if not id then return false end

    if idType == "item" then
        DB.CustomItemIDs[id] = nil
        if _G.OldSchoolConsumablesDB and type(_G.OldSchoolConsumablesDB.customItemIDs) == "table" then
            _G.OldSchoolConsumablesDB.customItemIDs[id] = nil
        end
        DB.PotionItems[id] = DB.BuiltinPotionItems[id]
        DB.FoodItems[id] = DB.BuiltinFoodItems[id]
        return true
    elseif idType == "spell" then
        DB.CustomSpellIDs[id] = nil
        if _G.OldSchoolConsumablesDB and type(_G.OldSchoolConsumablesDB.customSpellIDs) == "table" then
            _G.OldSchoolConsumablesDB.customSpellIDs[id] = nil
        end
        DB.PotionSpells[id] = DB.BuiltinPotionSpells[id]
        DB.FoodSpells[id] = DB.BuiltinFoodSpells[id]
        return true
    end
    return false
end

function DB:SyncCustomIDs(savedCustomSpells, savedCustomItems)
    local spells = savedCustomSpells or (_G.OldSchoolConsumablesDB and _G.OldSchoolConsumablesDB.customSpellIDs)
    if type(spells) == "table" then
        for spellID, category in pairs(spells) do
            local id = tonumber(spellID)
            if id and category then
                DB.CustomSpellIDs[id] = category
                if category == "flask" or category == "potion" or category == "health" then
                    DB.PotionSpells[id] = category
                elseif category == "feast" or category == "food" or category == "magebun" then
                    DB.FoodSpells[id] = category
                end
            end
        end
    end

    local items = savedCustomItems or (_G.OldSchoolConsumablesDB and _G.OldSchoolConsumablesDB.customItemIDs)
    if type(items) == "table" then
        for itemID, category in pairs(items) do
            local id = tonumber(itemID)
            if id and category then
                DB.CustomItemIDs[id] = category
                if category == "flask" or category == "potion" or category == "health" then
                    DB.PotionItems[id] = category
                elseif category == "feast" or category == "food" or category == "magebun" then
                    DB.FoodItems[id] = category
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Lookup Helper Functions
--------------------------------------------------------------------------------
function DB:IsConsumablePotion(spellID, itemID, spellName)
    -- 1. Exact Spell ID Lookup
    if spellID ~= nil then
        local sID = tonumber(spellID)
        if sID then
            if _G.OldSchoolConsumablesDB and type(_G.OldSchoolConsumablesDB.customSpellIDs) == "table" then
                local customCat = _G.OldSchoolConsumablesDB.customSpellIDs[sID]
                if customCat and (customCat == "flask" or customCat == "potion" or customCat == "health") then
                    return true, customCat
                end
            end
            local cat = DB.PotionSpells[sID]
            if cat then
                return true, cat
            end
        end
    end

    -- 2. Exact Item ID Lookup
    if itemID ~= nil then
        local iID = tonumber(itemID)
        if iID then
            if _G.OldSchoolConsumablesDB and type(_G.OldSchoolConsumablesDB.customItemIDs) == "table" then
                local customCat = _G.OldSchoolConsumablesDB.customItemIDs[iID]
                if customCat and (customCat == "flask" or customCat == "potion" or customCat == "health") then
                    return true, customCat
                end
            end
            local cat = DB.PotionItems[iID]
            if cat then
                return true, cat
            end
        end
    end

    -- 3. Dynamic Item-to-Spell Resolution
    if itemID ~= nil and C_Item and type(C_Item.GetItemSpell) == "function" then
        local spellInfo = C_Item.GetItemSpell(itemID)
        if spellInfo then
            local resolvedSpellID = (type(spellInfo) == "table" and spellInfo.spellID) or spellInfo
            if resolvedSpellID and DB.PotionSpells[resolvedSpellID] then
                return true, DB.PotionSpells[resolvedSpellID]
            end
        end
    end

    -- 4. Smart Name Pattern Matching Fallback (Captures unlisted or new potions)
    local name = spellName
    if not name and spellID and C_Spell and type(C_Spell.GetSpellName) == "function" then
        name = C_Spell.GetSpellName(spellID)
    end
    if name and type(name) == "string" then
        local lower = name:lower()
        if lower:find("potential") or lower:find("potion") or lower:find("flask") or lower:find("draught") or lower:find("phial") or lower:find("tonic") or lower:find("elixir") or lower:find("healthstone") then
            if lower:find("flask") then
                return true, "flask"
            elseif lower:find("health") or lower:find("tonic") or lower:find("healthstone") then
                return true, "health"
            else
                return true, "potion"
            end
        end
    end

    return false, nil
end

function DB:IsConsumableFood(spellID, itemID, spellName)
    -- 1. Exact Spell ID Lookup
    if spellID ~= nil then
        local sID = tonumber(spellID)
        if sID then
            if _G.OldSchoolConsumablesDB and type(_G.OldSchoolConsumablesDB.customSpellIDs) == "table" then
                local customCat = _G.OldSchoolConsumablesDB.customSpellIDs[sID]
                if customCat and (customCat == "feast" or customCat == "food" or customCat == "magebun") then
                    return true, customCat
                end
            end
            local cat = DB.FoodSpells[sID]
            if cat then
                return true, cat
            end
        end
    end

    -- 2. Exact Item ID Lookup
    if itemID ~= nil then
        local iID = tonumber(itemID)
        if iID then
            if _G.OldSchoolConsumablesDB and type(_G.OldSchoolConsumablesDB.customItemIDs) == "table" then
                local customCat = _G.OldSchoolConsumablesDB.customItemIDs[iID]
                if customCat and (customCat == "feast" or customCat == "food" or customCat == "magebun") then
                    return true, customCat
                end
            end
            local cat = DB.FoodItems[iID]
            if cat then
                return true, cat
            end
        end
    end

    -- 3. Dynamic Item-to-Spell Resolution
    if itemID ~= nil and C_Item and type(C_Item.GetItemSpell) == "function" then
        local spellInfo = C_Item.GetItemSpell(itemID)
        if spellInfo then
            local resolvedSpellID = (type(spellInfo) == "table" and spellInfo.spellID) or spellInfo
            if resolvedSpellID and DB.FoodSpells[resolvedSpellID] then
                return true, DB.FoodSpells[resolvedSpellID]
            end
        end
    end

    -- 4. Smart Name Pattern Matching Fallback
    local name = spellName
    if not name and spellID and C_Spell and type(C_Spell.GetSpellName) == "function" then
        name = C_Spell.GetSpellName(spellID)
    end
    if name and type(name) == "string" then
        local lower = name:lower()
        if lower:find("feast") then
            return true, "feast"
        elseif lower:find("mage bun") or lower:find("mana bun") or lower:find("refreshment") then
            return true, "magebun"
        elseif lower:find("food") or lower:find("well fed") or lower:find("eating") then
            return true, "food"
        end
    end

    return false, nil
end

function DB:GetConsumableType(spellID, itemID, spellName)
    local isPot, potCat = DB:IsConsumablePotion(spellID, itemID, spellName)
    if isPot then
        return "potion", potCat
    end

    local isFood, foodCat = DB:IsConsumableFood(spellID, itemID, spellName)
    if isFood then
        return "food", foodCat
    end

    return nil, nil
end

function DB:IsCategoryEnabled(category, settings)
    if not category then return false end
    local s = settings or (_G.OldSchoolConsumablesDB and _G.OldSchoolConsumablesDB.categories) or DB.DefaultSettings.categories
    local settingKey = DB.CategoryToSettingKey[category] or category
    if s and s[settingKey] ~= nil then
        return s[settingKey] == true
    end
    return true
end
