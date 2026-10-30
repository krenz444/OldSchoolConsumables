--==============================================================================
-- OldSchoolConsumables - UI_BlizzardSettings.lua
-- World of Warcraft: Midnight (12.0+) Blizzard Settings Integration
-- Registers OldSchoolConsumables into Game Menu -> Options -> AddOns
--==============================================================================

local addonName, OSC = ...
OSC.BlizzardSettings = {}
local BlizzSettings = OSC.BlizzardSettings

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------
local function PlayCheckboxSound()
    if SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end
end

--------------------------------------------------------------------------------
-- Panel Construction
--------------------------------------------------------------------------------
local panel = CreateFrame("Frame", "OSC_BlizzardSettingsPanel")
panel.name = "OldSchoolConsumables"
BlizzSettings.panel = panel

-- Title
local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("|cffffd100OldSchoolConsumables|r")

-- Version / Subtitle
local versionText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
versionText:SetPoint("LEFT", title, "RIGHT", 8, 0)
versionText:SetText("|cff888888v1.0.0 (Midnight 12.0+)|r")

-- Description
local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
desc:SetPoint("RIGHT", panel, -16, 0)
desc:SetJustifyH("LEFT")
desc:SetWordWrap(true)
desc:SetText("Plays authentic Old School RuneScape drinking and eating sound effects when using Midnight potions, flasks, and foods.")

-- Big prominent button: Open Draggable Customizer Window (/osc)
local openCustomizerBtn = CreateFrame("Button", "OSC_Blizz_OpenCustomizerBtn", panel, "UIPanelButtonTemplate")
openCustomizerBtn:SetSize(300, 30)
openCustomizerBtn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)
openCustomizerBtn:SetText("Open Draggable Customizer Window (/osc)")
openCustomizerBtn:SetScript("OnClick", function()
    if OSC.UI and OSC.UI.ToggleWindow then
        OSC.UI:ToggleWindow()
    elseif SlashCmdList and SlashCmdList["OLDSCHOOLCONSUMABLES"] then
        SlashCmdList["OLDSCHOOLCONSUMABLES"]("")
    end
end)
openCustomizerBtn:SetScript("OnEnter", function(self)
    if GameTooltip then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("OldSchoolConsumables Customizer", 1, 0.82, 0)
        GameTooltip:AddLine("Open the full draggable customizer window to configure sound volume, channels, category filters, and custom item/spell IDs.", 1, 1, 1, true)
        GameTooltip:Show()
    end
end)
openCustomizerBtn:SetScript("OnLeave", function()
    if GameTooltip then
        GameTooltip:Hide()
    end
end)

--------------------------------------------------------------------------------
-- Section: Quick Settings
--------------------------------------------------------------------------------
local quickHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
quickHeader:SetPoint("TOPLEFT", openCustomizerBtn, "BOTTOMLEFT", 0, -22)
quickHeader:SetText("Quick Settings")

-- Checkbox factory
local function CreateCheckbox(name, labelText, tooltipText)
    local cb = CreateFrame("CheckButton", name, panel, "InterfaceOptionsCheckButtonTemplate")
    if not cb then
        cb = CreateFrame("CheckButton", name, panel, "UICheckButtonTemplate")
    end

    local text = cb.Text or (name and _G[name .. "Text"])
    if not text then
        text = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        text:SetPoint("LEFT", cb, "RIGHT", 4, 1)
        cb.Text = text
    end
    text:SetText(labelText)

    if tooltipText then
        cb:SetScript("OnEnter", function(self)
            if GameTooltip then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(labelText, 1, 0.82, 0)
                GameTooltip:AddLine(tooltipText, 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)
        cb:SetScript("OnLeave", function()
            if GameTooltip then
                GameTooltip:Hide()
            end
        end)
    end

    return cb
end

-- 1. Checkbox: Enable Sound Effects (syncs with OSC.settings.enabled)
local cbEnabled = CreateCheckbox("OSC_Blizz_EnableSounds", "Enable Sound Effects", "Toggle all OldSchoolConsumables eating and drinking audio effects.")
cbEnabled:SetPoint("TOPLEFT", quickHeader, "BOTTOMLEFT", 0, -10)
cbEnabled:SetScript("OnClick", function(self)
    local isChecked = self:GetChecked()
    if OSC.settings then
        OSC.settings.enabled = isChecked
    end
    PlayCheckboxSound()
    if OSC.UI and OSC.UI.RefreshWindow then
        OSC.UI:RefreshWindow()
    end
end)

-- 2. Checkbox: Enable Overhead Text (syncs with OSC.settings.overheadText)
local cbOverhead = CreateCheckbox("OSC_Blizz_EnableOverhead", "Enable Overhead Text (*Gulp* / *Chomp*)", "Displays animated floating RuneScape-style yellow overhead text above your character when consuming items.")
cbOverhead:SetPoint("TOPLEFT", cbEnabled, "BOTTOMLEFT", 0, -8)
cbOverhead:SetScript("OnClick", function(self)
    local isChecked = self:GetChecked()
    if OSC.settings then
        OSC.settings.overheadText = isChecked
    end
    PlayCheckboxSound()
    if OSC.UI and OSC.UI.RefreshWindow then
        OSC.UI:RefreshWindow()
    end
end)

--------------------------------------------------------------------------------
-- Section: Audio Test Buttons
--------------------------------------------------------------------------------
local testHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
testHeader:SetPoint("TOPLEFT", cbOverhead, "BOTTOMLEFT", 0, -20)
testHeader:SetText("Audio Test")

-- Test Potion button
local testPotBtn = CreateFrame("Button", "OSC_Blizz_TestPotBtn", panel, "UIPanelButtonTemplate")
testPotBtn:SetSize(140, 26)
testPotBtn:SetPoint("TOPLEFT", testHeader, "BOTTOMLEFT", 0, -10)
testPotBtn:SetText("Test Potion")
testPotBtn:SetScript("OnClick", function()
    if OSC.Audio and OSC.Audio.TestPotion then
        OSC.Audio:TestPotion()
    elseif OSC.Audio and OSC.Audio.PlayPotionSound then
        OSC.Audio:PlayPotionSound()
    end
end)

-- Test Food button
local testFoodBtn = CreateFrame("Button", "OSC_Blizz_TestFoodBtn", panel, "UIPanelButtonTemplate")
testFoodBtn:SetSize(140, 26)
testFoodBtn:SetPoint("LEFT", testPotBtn, "RIGHT", 12, 0)
testFoodBtn:SetText("Test Food")
testFoodBtn:SetScript("OnClick", function()
    if OSC.Audio and OSC.Audio.TestFood then
        OSC.Audio:TestFood()
    elseif OSC.Audio and OSC.Audio.PlayFoodSound then
        OSC.Audio:PlayFoodSound()
    end
end)

--------------------------------------------------------------------------------
-- Section: Information Footer (Slash Commands & Help)
--------------------------------------------------------------------------------
local footerBox = CreateFrame("Frame", "OSC_Blizz_FooterBox", panel, "BackdropTemplate")
footerBox:SetPoint("TOPLEFT", testPotBtn, "BOTTOMLEFT", 0, -24)
footerBox:SetPoint("RIGHT", panel, -20, 0)
footerBox:SetHeight(120)

if footerBox.SetBackdrop then
    footerBox:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    footerBox:SetBackdropColor(0.08, 0.08, 0.12, 0.85)
    footerBox:SetBackdropBorderColor(0.4, 0.4, 0.45, 0.7)
end

local footerTitle = footerBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
footerTitle:SetPoint("TOPLEFT", footerBox, 12, -10)
footerTitle:SetText("Slash Commands & Quick Reference")

local footerLine1 = footerBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
footerLine1:SetPoint("TOPLEFT", footerTitle, "BOTTOMLEFT", 0, -6)
footerLine1:SetPoint("RIGHT", footerBox, -12, 0)
footerLine1:SetJustifyH("LEFT")
footerLine1:SetText("|cffffd100/osc|r or |cffffd100/runescape|r or |cffffd100/rsc|r  —  Toggle the draggable OSRS customizer window.")

local footerLine2 = footerBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
footerLine2:SetPoint("TOPLEFT", footerLine1, "BOTTOMLEFT", 0, -4)
footerLine2:SetPoint("RIGHT", footerBox, -12, 0)
footerLine2:SetJustifyH("LEFT")
footerLine2:SetText("|cffffd100/osc test pot|r / |cffffd100/osc test food|r  —  Play test sound effects directly from chat.")

local footerLine3 = footerBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
footerLine3:SetPoint("TOPLEFT", footerLine2, "BOTTOMLEFT", 0, -4)
footerLine3:SetPoint("RIGHT", footerBox, -12, 0)
footerLine3:SetJustifyH("LEFT")
footerLine3:SetText("|cffffd100/osc help|r  —  Print full command usage and database status in the chat frame.")

local footerLine4 = footerBox:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
footerLine4:SetPoint("TOPLEFT", footerLine3, "BOTTOMLEFT", 0, -6)
footerLine4:SetPoint("RIGHT", footerBox, -12, 0)
footerLine4:SetJustifyH("LEFT")
footerLine4:SetText("Tip: Open the draggable customizer window to adjust sound channels, volume, categories, and custom item/spell IDs.")

--------------------------------------------------------------------------------
-- State Synchronization & OnShow
--------------------------------------------------------------------------------
local function RefreshUI()
    if not OSC.settings then return end
    if cbEnabled then
        cbEnabled:SetChecked(OSC.settings.enabled == true)
    end
    if cbOverhead then
        cbOverhead:SetChecked(OSC.settings.overheadText == true)
    end
end

panel:SetScript("OnShow", RefreshUI)
panel.refresh = RefreshUI

BlizzSettings.RefreshUI = RefreshUI

--------------------------------------------------------------------------------
-- Category Registration
--------------------------------------------------------------------------------
function BlizzSettings:Register()
    if self.registered then return end

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "OldSchoolConsumables")
        if Settings.RegisterAddOnCategory then
            Settings.RegisterAddOnCategory(category)
        end
        BlizzSettings.category = category
        self.registered = true
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
        BlizzSettings.category = panel
        self.registered = true
    end
end

-- Open helper
function BlizzSettings:OpenToCategory()
    if Settings and Settings.OpenToCategory and BlizzSettings.category then
        local catID = (type(BlizzSettings.category) == "table" and BlizzSettings.category.GetID)
            and BlizzSettings.category:GetID()
            or BlizzSettings.category
        Settings.OpenToCategory(catID)
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(panel)
    end
end

-- Initialize registration immediately at file load
BlizzSettings:Register()
