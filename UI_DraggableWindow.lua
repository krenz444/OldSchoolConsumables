--==============================================================================
-- OldSchoolConsumables - UI_DraggableWindow.lua
-- World of Warcraft: Midnight (12.0+) Standalone Draggable OSRS-Themed GUI
--==============================================================================

local addonName, OSC = ...
OSC.UI = OSC.UI or {}
local UI = OSC.UI

--------------------------------------------------------------------------------
-- Theme Palette Constants (Classic Old School RuneScape Aesthetic)
--------------------------------------------------------------------------------
local THEME = {
    bg = { r = 0.169, g = 0.137, b = 0.114, a = 0.96 },       -- Dark stone #2b231d
    insetBg = { r = 0.110, g = 0.086, b = 0.071, a = 0.90 },  -- Recessed stone #1c1612
    border = { r = 0.361, g = 0.290, b = 0.220, a = 1.00 },   -- Muted bronze #5c4a38
    insetBorder = { r = 0.259, g = 0.212, b = 0.169, a = 0.9 }, -- Recessed border #42362b
    gold = { r = 1.000, g = 0.820, b = 0.000, a = 1.00 },     -- OSRS Gold #ffd100
    yellow = { r = 1.000, g = 1.000, b = 0.000, a = 1.00 },   -- Bright Yellow #ffff00
    parchment = { r = 0.880, g = 0.840, b = 0.760, a = 1.00 },-- Crisp Parchment #e0d6c2
    muted = { r = 0.600, g = 0.540, b = 0.460, a = 1.00 },    -- Muted Stone #998a75
    btnNormal = { r = 0.220, g = 0.180, b = 0.140, a = 1.00 },
    btnHover = { r = 0.300, g = 0.250, b = 0.200, a = 1.00 },
    btnBorder = { r = 0.480, g = 0.390, b = 0.300, a = 1.00 },
}

local SOUND_CHANNELS = { "Master", "SFX", "Dialog", "Ambience", "Music" }

--------------------------------------------------------------------------------
-- Helper Widgets & Styling
--------------------------------------------------------------------------------
local function CreateOSRSInset(parent, width, height)
    local inset = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    if width and height then
        inset:SetSize(width, height)
    end
    inset:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 0, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    inset:SetBackdropColor(THEME.insetBg.r, THEME.insetBg.g, THEME.insetBg.b, THEME.insetBg.a)
    inset:SetBackdropBorderColor(THEME.insetBorder.r, THEME.insetBorder.g, THEME.insetBorder.b, THEME.insetBorder.a)
    return inset
end

local function CreateOSRSButton(parent, text, width, height)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width or 100, height or 24)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 0, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    btn:SetBackdropColor(THEME.btnNormal.r, THEME.btnNormal.g, THEME.btnNormal.b, 1.0)
    btn:SetBackdropBorderColor(THEME.btnBorder.r, THEME.btnBorder.g, THEME.btnBorder.b, 1.0)

    local fontString = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fontString:SetPoint("CENTER", 0, 0)
    fontString:SetText(text or "")
    fontString:SetTextColor(THEME.gold.r, THEME.gold.g, THEME.gold.b)
    btn:SetFontString(fontString)
    btn.fontString = fontString

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(THEME.btnHover.r, THEME.btnHover.g, THEME.btnHover.b, 1.0)
        self:SetBackdropBorderColor(THEME.gold.r, THEME.gold.g, THEME.gold.b, 1.0)
        self.fontString:SetTextColor(THEME.yellow.r, THEME.yellow.g, THEME.yellow.b)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(THEME.btnNormal.r, THEME.btnNormal.g, THEME.btnNormal.b, 1.0)
        self:SetBackdropBorderColor(THEME.btnBorder.r, THEME.btnBorder.g, THEME.btnBorder.b, 1.0)
        self.fontString:SetTextColor(THEME.gold.r, THEME.gold.g, THEME.gold.b)
    end)
    btn:SetScript("OnMouseDown", function(self)
        self.fontString:SetPoint("CENTER", 1, -1)
    end)
    btn:SetScript("OnMouseUp", function(self)
        self.fontString:SetPoint("CENTER", 0, 0)
    end)

    return btn
end

local function CreateOSRSCheckbox(parent, labelText, tooltipText)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(22, 22)
    cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    cb.text:SetText(labelText)
    cb.text:SetTextColor(THEME.parchment.r, THEME.parchment.g, THEME.parchment.b)

    if tooltipText then
        cb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(labelText, THEME.gold.r, THEME.gold.g, THEME.gold.b)
            GameTooltip:AddLine(tooltipText, THEME.parchment.r, THEME.parchment.g, THEME.parchment.b, true)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    return cb
end

local function GetItemDisplayName(itemID)
    if C_Item and C_Item.GetItemInfo then
        local name = C_Item.GetItemInfo(itemID)
        if name then return name end
    elseif _G.GetItemInfo then
        local name = _G.GetItemInfo(itemID)
        if name then return name end
    end
    if C_Item and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(itemID)
    end
    return nil
end

local function GetSpellDisplayName(spellID)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info and info.name then return info.name end
    elseif _G.GetSpellInfo then
        local name = _G.GetSpellInfo(spellID)
        if name then return name end
    end
    return nil
end

local function SyncAddonSetting(key, val)
    if OSC.settings then OSC.settings[key] = val end
    if OSC.db and OSC.db.profile then OSC.db.profile[key] = val end
    if _G.OldSchoolConsumablesDB then _G.OldSchoolConsumablesDB[key] = val end
end

local function SyncCategorySetting(catKey, isChecked)
    if OSC.settings then
        OSC.settings.categories = OSC.settings.categories or {}
        OSC.settings.categories[catKey] = isChecked
    end
    if OSC.db and OSC.db.profile then
        OSC.db.profile.categories = OSC.db.profile.categories or {}
        OSC.db.profile.categories[catKey] = isChecked
    end
    if _G.OldSchoolConsumablesDB then
        _G.OldSchoolConsumablesDB.categories = _G.OldSchoolConsumablesDB.categories or {}
        _G.OldSchoolConsumablesDB.categories[catKey] = isChecked
    end
end

--------------------------------------------------------------------------------
-- Custom ID Retrieval & Management Helper
--------------------------------------------------------------------------------
function UI:GetActiveCustomIDs()
    local list = {}
    local seen = {}

    local itemSource = (OSC.db and OSC.db.profile and OSC.db.profile.customItemIDs)
        or (OSC.settings and OSC.settings.customItemIDs)
        or (_G.OldSchoolConsumablesDB and _G.OldSchoolConsumablesDB.customItemIDs)
        or (OSC.Database and OSC.Database.CustomItemIDs)
    if type(itemSource) == "table" then
        for id, cat in pairs(itemSource) do
            local numID = tonumber(id)
            if numID then
                local key = "item_" .. numID
                if not seen[key] then
                    seen[key] = true
                    table.insert(list, { type = "item", id = numID, category = cat })
                end
            end
        end
    end

    local spellSource = (OSC.db and OSC.db.profile and OSC.db.profile.customSpellIDs)
        or (OSC.settings and OSC.settings.customSpellIDs)
        or (_G.OldSchoolConsumablesDB and _G.OldSchoolConsumablesDB.customSpellIDs)
        or (OSC.Database and OSC.Database.CustomSpellIDs)
    if type(spellSource) == "table" then
        for id, cat in pairs(spellSource) do
            local numID = tonumber(id)
            if numID then
                local key = "spell_" .. numID
                if not seen[key] then
                    seen[key] = true
                    table.insert(list, { type = "spell", id = numID, category = cat })
                end
            end
        end
    end

    table.sort(list, function(a, b)
        if a.type ~= b.type then
            return a.type < b.type
        end
        return a.id < b.id
    end)

    return list
end

--------------------------------------------------------------------------------
-- Main Window Construction
--------------------------------------------------------------------------------
function UI:CreateWindow()
    if UI.frame then
        return UI.frame
    end

    local frame = CreateFrame("Frame", "OSC_MainWindow", UIParent, "BackdropTemplate")
    frame:SetSize(500, 580)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("HIGH")

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 0, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(THEME.bg.r, THEME.bg.g, THEME.bg.b, THEME.bg.a)
    frame:SetBackdropBorderColor(THEME.border.r, THEME.border.g, THEME.border.b, THEME.border.a)

    -- Close with ESC
    if _G.UISpecialFrames then
        table.insert(_G.UISpecialFrames, "OSC_MainWindow")
    end

    -- Close Button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function()
        UI:HideWindow()
    end)

    -- Header Title & Subtitle
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -12)
    title:SetText("|cffffd100Old School Consumables|r")

    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -2)
    subtitle:SetText("|cffbfb59dRuneScape Audio & Consumable Customizer|r")

    local headerLine = frame:CreateTexture(nil, "ARTWORK")
    headerLine:SetSize(468, 2)
    headerLine:SetPoint("TOP", frame, "TOP", 0, -48)
    headerLine:SetColorTexture(0.70, 0.55, 0.20, 0.75)

    ----------------------------------------------------------------------------
    -- Section 1: General & Audio Settings
    ----------------------------------------------------------------------------
    local audioSection = CreateOSRSInset(frame, 468, 136)
    audioSection:SetPoint("TOP", frame, "TOP", 0, -54)

    local audioHeader = audioSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    audioHeader:SetPoint("TOPLEFT", audioSection, "TOPLEFT", 12, -8)
    audioHeader:SetText("|cffffd100General & Audio Settings|r")

    -- Global Addon Enable Checkbox
    local enableCheck = CreateOSRSCheckbox(
        audioSection,
        "Enable OldSchoolConsumables",
        "Toggles all sound triggers and visual effects for consumables globally."
    )
    enableCheck:SetPoint("TOPLEFT", audioSection, "TOPLEFT", 12, -26)
    enableCheck:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked()
        SyncAddonSetting("enabled", isChecked)
    end)
    UI.enableCheck = enableCheck

    -- Sound Channel Dropdown Selector
    local channelLabel = audioSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    channelLabel:SetPoint("TOPLEFT", audioSection, "TOPLEFT", 14, -58)
    channelLabel:SetTextColor(THEME.parchment.r, THEME.parchment.g, THEME.parchment.b)
    channelLabel:SetText("Sound Channel:")

    local channelBtn = CreateOSRSButton(audioSection, "Channel: Master", 120, 22)
    channelBtn:SetPoint("LEFT", channelLabel, "RIGHT", 8, 0)
    UI.channelBtn = channelBtn

    local channelDropdown = CreateFrame("Frame", "OSC_ChannelDropdownMenu", frame, "BackdropTemplate")
    channelDropdown:SetSize(120, #SOUND_CHANNELS * 22 + 8)
    channelDropdown:SetPoint("TOPLEFT", channelBtn, "BOTTOMLEFT", 0, -2)
    channelDropdown:SetFrameStrata("DIALOG")
    channelDropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 0, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    channelDropdown:SetBackdropColor(0.14, 0.11, 0.09, 0.98)
    channelDropdown:SetBackdropBorderColor(0.55, 0.45, 0.32, 1.0)
    channelDropdown:Hide()

    for i, chan in ipairs(SOUND_CHANNELS) do
        local opt = CreateFrame("Button", nil, channelDropdown)
        opt:SetSize(114, 20)
        opt:SetPoint("TOPLEFT", channelDropdown, "TOPLEFT", 3, -((i - 1) * 22 + 4))

        local optText = opt:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        optText:SetPoint("LEFT", opt, "LEFT", 8, 0)
        optText:SetText(chan)
        optText:SetTextColor(THEME.parchment.r, THEME.parchment.g, THEME.parchment.b)
        opt.optText = optText

        opt:SetScript("OnEnter", function()
            optText:SetTextColor(THEME.yellow.r, THEME.yellow.g, THEME.yellow.b)
        end)
        opt:SetScript("OnLeave", function()
            optText:SetTextColor(THEME.parchment.r, THEME.parchment.g, THEME.parchment.b)
        end)
        opt:SetScript("OnClick", function()
            SyncAddonSetting("soundChannel", chan)
            channelBtn:SetText("Channel: " .. chan)
            channelDropdown:Hide()
        end)
    end

    channelBtn:SetScript("OnClick", function()
        if channelDropdown:IsShown() then
            channelDropdown:Hide()
        else
            channelDropdown:Show()
        end
    end)

    -- Volume Slider
    local volumeSlider = CreateFrame("Slider", "OSC_VolumeSlider", audioSection, "OptionsSliderTemplate")
    volumeSlider:SetSize(160, 16)
    volumeSlider:SetPoint("TOPRIGHT", audioSection, "TOPRIGHT", -24, -58)
    volumeSlider:SetMinMaxValues(10, 100)
    volumeSlider:SetValueStep(5)
    volumeSlider:SetObeyStepOnDrag(true)

    local volumeText = audioSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    volumeText:SetPoint("BOTTOM", volumeSlider, "TOP", 0, 4)
    volumeText:SetTextColor(THEME.gold.r, THEME.gold.g, THEME.gold.b)
    volumeText:SetText("Sound Volume: 100%")
    UI.volumeText = volumeText

    local lowText = _G[volumeSlider:GetName() .. "Low"] or volumeSlider:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    lowText:SetText("10%")
    lowText:ClearAllPoints()
    lowText:SetPoint("TOPLEFT", volumeSlider, "BOTTOMLEFT", 0, -2)

    local highText = _G[volumeSlider:GetName() .. "High"] or volumeSlider:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    highText:SetText("100%")
    highText:ClearAllPoints()
    highText:SetPoint("TOPRIGHT", volumeSlider, "BOTTOMRIGHT", 0, -2)

    volumeSlider:SetScript("OnValueChanged", function(_, value)
        local pct = math.floor(value + 0.5)
        volumeText:SetText("Sound Volume: " .. pct .. "%")
        local normalized = pct / 100
        SyncAddonSetting("volume", normalized)
    end)
    UI.volumeSlider = volumeSlider

    -- Side-by-side Test Buttons
    local testPotBtn = CreateOSRSButton(audioSection, "Test Potion Sound", 200, 24)
    testPotBtn:SetPoint("BOTTOMLEFT", audioSection, "BOTTOMLEFT", 18, 12)
    testPotBtn:SetScript("OnClick", function()
        if OSC.Audio and OSC.Audio.TestPotion then
            OSC.Audio:TestPotion()
        elseif _G.PlaySoundFile then
            local s = (OSC.db and OSC.db.profile) or OSC.settings or _G.OldSchoolConsumablesDB or (OSC.Database and OSC.Database.DefaultSettings)
            local chan = (s and s.soundChannel) or "Master"
            local path = (s and s.potionSound) or "Interface\\AddOns\\OldSchoolConsumables\\Sounds\\potion.ogg"
            _G.PlaySoundFile(path, chan)
        end
    end)

    local testFoodBtn = CreateOSRSButton(audioSection, "Test Food Sound", 200, 24)
    testFoodBtn:SetPoint("BOTTOMRIGHT", audioSection, "BOTTOMRIGHT", -18, 12)
    testFoodBtn:SetScript("OnClick", function()
        if OSC.Audio and OSC.Audio.TestFood then
            OSC.Audio:TestFood()
        elseif _G.PlaySoundFile then
            local s = (OSC.db and OSC.db.profile) or OSC.settings or _G.OldSchoolConsumablesDB or (OSC.Database and OSC.Database.DefaultSettings)
            local chan = (s and s.soundChannel) or "Master"
            local path = (s and s.foodSound) or "Interface\\AddOns\\OldSchoolConsumables\\Sounds\\food.ogg"
            _G.PlaySoundFile(path, chan)
        end
    end)

    ----------------------------------------------------------------------------
    -- Section 2: Consumable Categories (2-Column Grid)
    ----------------------------------------------------------------------------
    local catSection = CreateOSRSInset(frame, 468, 110)
    catSection:SetPoint("TOP", audioSection, "BOTTOM", 0, -8)

    local catHeader = catSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    catHeader:SetPoint("TOPLEFT", catSection, "TOPLEFT", 12, -8)
    catHeader:SetText("|cffffd100Sound Trigger Categories|r")

    local categoriesConfig = {
        -- Column 1
        { key = "flasks", label = "Flasks", tooltip = "Play potion sound on flask usage.", col = 1, row = 1 },
        { key = "potions", label = "Combat Potions", tooltip = "Play potion sound on combat potions.", col = 1, row = 2 },
        { key = "health", label = "Healing Potions & Healthstones", tooltip = "Play potion sound on health pots and warlock healthstones.", col = 1, row = 3 },
        -- Column 2
        { key = "feasts", label = "Feasts", tooltip = "Play eating sound on raid feast interaction.", col = 2, row = 1 },
        { key = "food", label = "Personal Food", tooltip = "Play eating sound on personal food & drinks.", col = 2, row = 2 },
        { key = "magebuns", label = "Mage Buns", tooltip = "Play eating sound on Conjured Mana Buns.", col = 2, row = 3 },
    }

    UI.categoryCheckboxes = {}
    local colX = { [1] = 18, [2] = 246 }
    local rowY = { [1] = -26, [2] = -50, [3] = -74 }

    for _, cfg in ipairs(categoriesConfig) do
        local cb = CreateOSRSCheckbox(catSection, cfg.label, cfg.tooltip)
        cb:SetPoint("TOPLEFT", catSection, "TOPLEFT", colX[cfg.col], rowY[cfg.row])
        cb:SetScript("OnClick", function(self)
            local isChecked = self:GetChecked()
            SyncCategorySetting(cfg.key, isChecked)
        end)
        UI.categoryCheckboxes[cfg.key] = cb
    end

    ----------------------------------------------------------------------------
    -- Section 3: Visual Feedback Section
    ----------------------------------------------------------------------------
    local visualSection = CreateOSRSInset(frame, 468, 44)
    visualSection:SetPoint("TOP", catSection, "BOTTOM", 0, -8)

    local overheadCheck = CreateOSRSCheckbox(
        visualSection,
        "Enable Floating Overhead Text (|cffffd100*Gulp*|r / |cffffd100*Chomp*|r)",
        "Displays classic floating overhead text above your character when drinking or eating.\n(Disabled by default)"
    )
    overheadCheck:SetPoint("TOPLEFT", visualSection, "TOPLEFT", 12, -10)
    overheadCheck:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked()
        SyncAddonSetting("overheadText", isChecked)
    end)
    UI.overheadCheck = overheadCheck

    ----------------------------------------------------------------------------
    -- Section 4: Custom ID Manager Section
    ----------------------------------------------------------------------------
    local customSection = CreateOSRSInset(frame, 468, 192)
    customSection:SetPoint("TOP", visualSection, "BOTTOM", 0, -8)

    local customHeader = customSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    customHeader:SetPoint("TOPLEFT", customSection, "TOPLEFT", 12, -8)
    customHeader:SetText("|cffffd100Add Custom Item or Spell ID|r")

    local idLabel = customSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    idLabel:SetPoint("TOPLEFT", customSection, "TOPLEFT", 14, -30)
    idLabel:SetTextColor(THEME.parchment.r, THEME.parchment.g, THEME.parchment.b)
    idLabel:SetText("ID:")

    local editBox = CreateFrame("EditBox", "OSC_CustomIDEditBox", customSection, "BackdropTemplate")
    editBox:SetSize(72, 22)
    editBox:SetPoint("LEFT", idLabel, "RIGHT", 4, 0)
    editBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 0, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    editBox:SetBackdropColor(0.08, 0.06, 0.05, 0.95)
    editBox:SetBackdropBorderColor(0.45, 0.36, 0.28, 1.0)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetTextColor(THEME.gold.r, THEME.gold.g, THEME.gold.b)
    editBox:SetNumeric(true)
    editBox:SetMaxLetters(9)
    editBox:SetAutoFocus(false)
    editBox:SetTextInsets(4, 4, 0, 0)
    editBox:SetScript("OnEscapePressed", editBox.ClearFocus)
    UI.editBox = editBox

    local selectedType = "item"
    local typeBtn = CreateOSRSButton(customSection, "Type: Item", 80, 22)
    typeBtn:SetPoint("LEFT", editBox, "RIGHT", 6, 0)
    typeBtn:SetScript("OnClick", function()
        if selectedType == "item" then
            selectedType = "spell"
            typeBtn:SetText("Type: Spell")
        else
            selectedType = "item"
            typeBtn:SetText("Type: Item")
        end
    end)
    UI.typeBtn = typeBtn

    local selectedCategory = "potion"
    local catBtn = CreateOSRSButton(customSection, "Sound: Potion", 94, 22)
    catBtn:SetPoint("LEFT", typeBtn, "RIGHT", 6, 0)
    catBtn:SetScript("OnClick", function()
        if selectedCategory == "potion" then
            selectedCategory = "food"
            catBtn:SetText("Sound: Food")
        else
            selectedCategory = "potion"
            catBtn:SetText("Sound: Potion")
        end
    end)
    UI.catBtn = catBtn

    local addBtn = CreateOSRSButton(customSection, "+ Add ID", 72, 22)
    addBtn:SetPoint("LEFT", catBtn, "RIGHT", 6, 0)
    UI.addBtn = addBtn

    local statusText = customSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusText:SetPoint("LEFT", addBtn, "RIGHT", 6, 0)
    statusText:SetPoint("RIGHT", customSection, "RIGHT", -8, 0)
    statusText:SetJustifyH("LEFT")
    statusText:SetText("")
    UI.statusText = statusText

    -- Custom ID Scroll Area
    local listInset = CreateOSRSInset(customSection, 444, 126)
    listInset:SetPoint("TOP", customSection, "TOP", 0, -56)

    local scrollFrame = CreateFrame("ScrollFrame", "OSC_CustomIDScrollFrame", listInset, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", listInset, "TOPLEFT", 6, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", listInset, "BOTTOMRIGHT", -26, 6)

    local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
    if scrollBar then
        scrollBar:ClearAllPoints()
        scrollBar:SetPoint("TOPRIGHT", listInset, "TOPRIGHT", -4, -18)
        scrollBar:SetPoint("BOTTOMRIGHT", listInset, "BOTTOMRIGHT", -4, 18)
    end

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(412, 1)
    scrollFrame:SetScrollChild(scrollChild)
    UI.scrollChild = scrollChild
    UI.scrollFrame = scrollFrame

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(_, delta)
        if scrollBar then
            local cur = scrollBar:GetValue() or 0
            local minVal, maxVal = scrollBar:GetMinMaxValues()
            scrollBar:SetValue(math.min(maxVal, math.max(minVal, cur - delta * 24)))
        end
    end)

    local emptyLabel = listInset:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    emptyLabel:SetPoint("CENTER", listInset, "CENTER", 0, 0)
    emptyLabel:SetTextColor(THEME.muted.r, THEME.muted.g, THEME.muted.b)
    emptyLabel:SetText("No custom IDs registered.\nEnter an item or spell ID above to customize.")
    UI.emptyLabel = emptyLabel

    addBtn:SetScript("OnClick", function()
        local text = editBox:GetText()
        local id = tonumber(text)
        if not id or id <= 0 then
            statusText:SetText("|cffff5555Invalid ID|r")
            return
        end

        if OSC.Database and OSC.Database.AddCustomID then
            OSC.Database:AddCustomID(selectedType, id, selectedCategory)
        end

        if selectedType == "item" then
            if OSC.settings then
                OSC.settings.customItemIDs = OSC.settings.customItemIDs or {}
                OSC.settings.customItemIDs[id] = selectedCategory
            end
            if OSC.db and OSC.db.profile then
                OSC.db.profile.customItemIDs = OSC.db.profile.customItemIDs or {}
                OSC.db.profile.customItemIDs[id] = selectedCategory
            end
            if _G.OldSchoolConsumablesDB then
                _G.OldSchoolConsumablesDB.customItemIDs = _G.OldSchoolConsumablesDB.customItemIDs or {}
                _G.OldSchoolConsumablesDB.customItemIDs[id] = selectedCategory
            end
        else
            if OSC.settings then
                OSC.settings.customSpellIDs = OSC.settings.customSpellIDs or {}
                OSC.settings.customSpellIDs[id] = selectedCategory
            end
            if OSC.db and OSC.db.profile then
                OSC.db.profile.customSpellIDs = OSC.db.profile.customSpellIDs or {}
                OSC.db.profile.customSpellIDs[id] = selectedCategory
            end
            if _G.OldSchoolConsumablesDB then
                _G.OldSchoolConsumablesDB.customSpellIDs = _G.OldSchoolConsumablesDB.customSpellIDs or {}
                _G.OldSchoolConsumablesDB.customSpellIDs[id] = selectedCategory
            end
        end

        statusText:SetText("|cff55ff55Added " .. id .. "!|r")
        editBox:SetText("")
        editBox:ClearFocus()
        UI:RefreshCustomIDList()
    end)

    editBox:SetScript("OnEnterPressed", function()
        addBtn:Click()
    end)

    ----------------------------------------------------------------------------
    -- Footer Info
    ----------------------------------------------------------------------------
    local footer = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    footer:SetPoint("BOTTOM", frame, "BOTTOM", 0, 8)
    footer:SetTextColor(THEME.muted.r, THEME.muted.g, THEME.muted.b)
    footer:SetText("Old School Consumables 1.0.0 • Midnight 12.0+ • Type /osc or /runescape")

    frame:Hide()
    UI.frame = frame
    return frame
end

--------------------------------------------------------------------------------
-- Custom ID List Renderer
--------------------------------------------------------------------------------
local rowPool = {}

function UI:RefreshCustomIDList()
    if not UI.frame or not UI.scrollChild then return end

    local list = UI:GetActiveCustomIDs()

    if #list == 0 then
        if UI.emptyLabel then UI.emptyLabel:Show() end
    else
        if UI.emptyLabel then UI.emptyLabel:Hide() end
    end

    for _, row in ipairs(rowPool) do
        row:Hide()
    end

    local rowHeight = 22
    local totalHeight = #list * rowHeight

    for i, entry in ipairs(list) do
        local row = rowPool[i]
        if not row then
            row = CreateFrame("Frame", nil, UI.scrollChild, "BackdropTemplate")
            row:SetSize(UI.scrollChild:GetWidth(), rowHeight)
            row:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = nil,
                tile = false, tileSize = 0, edgeSize = 0,
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            })

            local typeTag = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            typeTag:SetPoint("LEFT", row, "LEFT", 6, 0)
            row.typeTag = typeTag

            local idText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            idText:SetPoint("LEFT", typeTag, "RIGHT", 6, 0)
            row.idText = idText

            local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            nameText:SetPoint("LEFT", idText, "RIGHT", 6, 0)
            nameText:SetWidth(150)
            nameText:SetJustifyH("LEFT")
            nameText:SetWordWrap(false)
            row.nameText = nameText

            local catText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            catText:SetPoint("RIGHT", row, "RIGHT", -64, 0)
            row.catText = catText

            local removeBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
            removeBtn:SetSize(48, 18)
            removeBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
            removeBtn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = false, tileSize = 0, edgeSize = 8,
                insets = { left = 1, right = 1, top = 1, bottom = 1 }
            })
            removeBtn:SetBackdropColor(0.28, 0.12, 0.10, 0.9)
            removeBtn:SetBackdropBorderColor(0.55, 0.25, 0.20, 1.0)

            local rText = removeBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            rText:SetPoint("CENTER", 0, 0)
            rText:SetText("|cffff5555Remove|r")
            removeBtn:SetFontString(rText)
            removeBtn.rText = rText

            removeBtn:SetScript("OnEnter", function(self)
                self:SetBackdropColor(0.45, 0.15, 0.12, 1.0)
                self:SetBackdropBorderColor(1.0, 0.4, 0.3, 1.0)
            end)
            removeBtn:SetScript("OnLeave", function(self)
                self:SetBackdropColor(0.28, 0.12, 0.10, 0.9)
                self:SetBackdropBorderColor(0.55, 0.25, 0.20, 1.0)
            end)

            row.removeBtn = removeBtn
            rowPool[i] = row
        end

        row:SetPoint("TOPLEFT", UI.scrollChild, "TOPLEFT", 0, -((i - 1) * rowHeight))
        row:SetPoint("TOPRIGHT", UI.scrollChild, "TOPRIGHT", 0, -((i - 1) * rowHeight))

        if i % 2 == 0 then
            row:SetBackdropColor(0.14, 0.11, 0.09, 0.6)
        else
            row:SetBackdropColor(0.18, 0.14, 0.11, 0.6)
        end

        if entry.type == "item" then
            row.typeTag:SetText("|cff88ccff[Item]|r")
            local itemName = GetItemDisplayName(entry.id)
            row.nameText:SetText(itemName and ("|cffe0d8c3" .. itemName .. "|r") or "")
        else
            row.typeTag:SetText("|cffffaa55[Spell]|r")
            local spellName = GetSpellDisplayName(entry.id)
            row.nameText:SetText(spellName and ("|cffe0d8c3" .. spellName .. "|r") or "")
        end

        row.idText:SetText("|cffffd100" .. entry.id .. "|r")

        local cat = entry.category or "potion"
        if cat == "potion" or cat == "flask" or cat == "health" then
            row.catText:SetText("|cffff7755Potion|r")
        else
            row.catText:SetText("|cff55ff77Food|r")
        end

        local curType = entry.type
        local curID = entry.id
        row.removeBtn:SetScript("OnClick", function()
            if OSC.Database and OSC.Database.RemoveCustomID then
                OSC.Database:RemoveCustomID(curType, curID)
            end

            if curType == "item" then
                if OSC.settings and OSC.settings.customItemIDs then
                    OSC.settings.customItemIDs[curID] = nil
                end
                if OSC.db and OSC.db.profile and OSC.db.profile.customItemIDs then
                    OSC.db.profile.customItemIDs[curID] = nil
                end
                if _G.OldSchoolConsumablesDB and _G.OldSchoolConsumablesDB.customItemIDs then
                    _G.OldSchoolConsumablesDB.customItemIDs[curID] = nil
                end
            else
                if OSC.settings and OSC.settings.customSpellIDs then
                    OSC.settings.customSpellIDs[curID] = nil
                end
                if OSC.db and OSC.db.profile and OSC.db.profile.customSpellIDs then
                    OSC.db.profile.customSpellIDs[curID] = nil
                end
                if _G.OldSchoolConsumablesDB and _G.OldSchoolConsumablesDB.customSpellIDs then
                    _G.OldSchoolConsumablesDB.customSpellIDs[curID] = nil
                end
            end

            UI:RefreshCustomIDList()
        end)

        row:Show()
    end

    UI.scrollChild:SetHeight(math.max(totalHeight, UI.scrollFrame:GetHeight() or 1))
end

--------------------------------------------------------------------------------
-- Settings Sync & Window Visibility Control
--------------------------------------------------------------------------------
function UI:SyncSettingsToWidgets()
    if not UI.frame then return end

    local s = (OSC.db and OSC.db.profile) or OSC.settings or _G.OldSchoolConsumablesDB or (OSC.Database and OSC.Database.DefaultSettings) or {}

    if UI.enableCheck then
        UI.enableCheck:SetChecked(s.enabled ~= false)
    end

    local chan = s.soundChannel or "Master"
    if UI.channelBtn then
        UI.channelBtn:SetText("Channel: " .. chan)
    end

    local vol = s.volume
    if vol == nil then vol = 1.0 end
    local pct = math.floor((vol * 100) + 0.5)
    if UI.volumeSlider then
        UI.volumeSlider:SetValue(pct)
    end
    if UI.volumeText then
        UI.volumeText:SetText("Sound Volume: " .. pct .. "%")
    end

    local cats = s.categories or {}
    if UI.categoryCheckboxes then
        for key, cb in pairs(UI.categoryCheckboxes) do
            cb:SetChecked(cats[key] ~= false)
        end
    end

    if UI.overheadCheck then
        UI.overheadCheck:SetChecked(s.overheadText == true)
    end

    UI:RefreshCustomIDList()
end

UI.RefreshWindow = UI.SyncSettingsToWidgets

function UI:ShowWindow()
    local frame = UI:CreateWindow()
    UI:SyncSettingsToWidgets()
    frame:Show()
end

function UI:HideWindow()
    if UI.frame and UI.frame:IsShown() then
        UI.frame:Hide()
    end
end

function UI:ToggleWindow()
    if UI.frame and UI.frame:IsShown() then
        UI:HideWindow()
    else
        UI:ShowWindow()
    end
end

--------------------------------------------------------------------------------
-- Fallback Slash Command Registration (Ensures /osc & /runescape always work)
--------------------------------------------------------------------------------
if not _G.SlashCmdList or not _G.SlashCmdList["OLDSCHOOLCONSUMABLES"] then
    _G.SLASH_OLDSCHOOLCONSUMABLES1 = "/osc"
    _G.SLASH_OLDSCHOOLCONSUMABLES2 = "/runescape"
    _G.SlashCmdList = _G.SlashCmdList or {}
    _G.SlashCmdList["OLDSCHOOLCONSUMABLES"] = function()
        UI:ToggleWindow()
    end
end
