--==============================================================================
-- OldSchoolConsumables - OverheadDisplay.lua
-- World of Warcraft: Midnight (12.0+) Floating Retro Overhead Text Display
--==============================================================================

local addonName, OSC = ...
OSC.Overhead = {}
local Overhead = OSC.Overhead

--------------------------------------------------------------------------------
-- Visual Frame & Pool Setup
--------------------------------------------------------------------------------
-- UIParent anchor: Non-interactive, pure UI display layer.
-- Keeps the frame completely outside secure combat execution to prevent taint.
local displayFrame = CreateFrame("Frame", "OSC_OverheadFrame", UIParent)
displayFrame:SetSize(400, 100)
displayFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
displayFrame:SetFrameStrata("HIGH")
displayFrame:EnableMouse(false)

Overhead.displayFrame = displayFrame

local POOL_SIZE = 4
local slotPool = {}
local sequenceCounter = 0

local function CreateSlot(index)
    local slot = CreateFrame("Frame", "OSC_OverheadSlot" .. index, displayFrame)
    slot:SetSize(400, 50)
    slot:SetPoint("CENTER", displayFrame, "CENTER", 0, 0)
    slot:SetFrameStrata("HIGH")
    slot:EnableMouse(false)
    slot:Hide()

    local fontString = slot:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    if not fontString:GetFont() then
        if GameFontHighlightLarge then
            fontString:SetFontObject(GameFontHighlightLarge)
        elseif GameFontNormalHuge then
            fontString:SetFontObject(GameFontNormalHuge)
        end
    end

    fontString:SetAllPoints(slot)
    fontString:SetJustifyH("CENTER")
    fontString:SetJustifyV("MIDDLE")

    -- Retro OSRS-style drop shadow for readability against 3D game geometry
    fontString:SetShadowOffset(1.5, -1.5)
    fontString:SetShadowColor(0.0, 0.0, 0.0, 1.0)

    -- Animation Group: 1.2s translation upwards + alpha fadeout
    local animGroup = slot:CreateAnimationGroup()

    local translation = animGroup:CreateAnimation("Translation")
    translation:SetOffset(0, 45)
    translation:SetDuration(1.2)
    translation:SetSmoothing("OUT")

    local alpha = animGroup:CreateAnimation("Alpha")
    alpha:SetFromAlpha(1.0)
    alpha:SetToAlpha(0.0)
    alpha:SetDuration(1.2)
    alpha:SetSmoothing("IN")

    animGroup:SetScript("OnFinished", function()
        slot:Hide()
        slot.inUse = false
        slot.startTime = 0
    end)

    animGroup:SetScript("OnStop", function()
        slot:Hide()
        slot.inUse = false
        slot.startTime = 0
    end)

    slot.fontString = fontString
    slot.animGroup = animGroup
    slot.translation = translation
    slot.alpha = alpha
    slot.inUse = false
    slot.startTime = 0
    slot.sequence = 0
    slot.index = index

    return slot
end

for i = 1, POOL_SIZE do
    table.insert(slotPool, CreateSlot(i))
end

Overhead.slotPool = slotPool

--------------------------------------------------------------------------------
-- Slot Management
--------------------------------------------------------------------------------
local function AcquireSlot()
    local now = (GetTime and GetTime()) or 0
    sequenceCounter = sequenceCounter + 1

    -- 1. Find an idle slot
    for _, slot in ipairs(slotPool) do
        if not slot.inUse then
            slot.inUse = true
            slot.startTime = now
            slot.sequence = sequenceCounter
            return slot
        end
    end

    -- 2. If all slots are active, recycle the oldest slot
    local oldestSlot = slotPool[1]
    local minSeq = oldestSlot.sequence or 0

    for i = 2, #slotPool do
        local slot = slotPool[i]
        if (slot.sequence or 0) < minSeq then
            oldestSlot = slot
            minSeq = slot.sequence or 0
        end
    end

    if oldestSlot.animGroup and oldestSlot.animGroup.IsPlaying and oldestSlot.animGroup:IsPlaying() then
        oldestSlot.animGroup:Stop()
    end
    oldestSlot:Hide()
    oldestSlot.inUse = true
    oldestSlot.startTime = now
    oldestSlot.sequence = sequenceCounter
    return oldestSlot
end

local function DisplaySlotText(slot, text, r, g, b)
    r = r or 1.0
    g = g or 0.82
    b = b or 0.0

    slot.fontString:SetText(text)
    slot.fontString:SetTextColor(r, g, b, 1.0)

    -- Reset anchor to base frame and reset alpha
    slot:ClearAllPoints()
    slot:SetPoint("CENTER", displayFrame, "CENTER", 0, 0)
    slot:SetAlpha(1.0)

    slot:Show()
    if slot.animGroup then
        if slot.animGroup.Stop then
            slot.animGroup:Stop()
        end
        if slot.animGroup.Play then
            slot.animGroup:Play()
        end
    end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Trigger a floating overhead text message above the player
-- @param text string: Text message to display
-- @param r number: Red component (0.0 - 1.0), defaults to 1.0
-- @param g number: Green component (0.0 - 1.0), defaults to 0.82
-- @param b number: Blue component (0.0 - 1.0), defaults to 0.0
function Overhead:TriggerText(text, r, g, b)
    -- Overhead text is disabled by default per user specification
    if not OSC.settings or not OSC.settings.overheadText then
        return
    end

    if not text or text == "" then
        return
    end

    local slot = AcquireSlot()
    if slot then
        DisplaySlotText(slot, text, r, g, b)
    end
end

--- Trigger potion floating text (cool potion cyan/blue: 0.2, 0.9, 1.0)
function Overhead:TriggerPotionText()
    local text = (OSC.settings and OSC.settings.overheadPotText)
    if not text or text == "" then
        text = "*Gulp*"
    end
    Overhead:TriggerText(text, 0.2, 0.9, 1.0)
end

--- Trigger food floating text (classic OSRS gold/yellow: 1.0, 0.82, 0.0)
function Overhead:TriggerFoodText()
    local text = (OSC.settings and OSC.settings.overheadFoodText)
    if not text or text == "" then
        text = "*Chomp*"
    end
    Overhead:TriggerText(text, 1.0, 0.82, 0.0)
end

--- Preview / test floating text directly regardless of enabled state
-- @param text string: Optional text to preview
-- @param r number: Optional red color
-- @param g number: Optional green color
-- @param b number: Optional blue color
function Overhead:Test(text, r, g, b)
    text = text or "*Gulp*"
    local slot = AcquireSlot()
    if slot then
        DisplaySlotText(slot, text, r, g, b)
    end
end

--- Set custom screen offset coordinates relative to screen center
-- @param x number: Horizontal offset in pixels
-- @param y number: Vertical offset in pixels (defaults to 120 above center)
function Overhead:SetPosition(x, y)
    displayFrame:ClearAllPoints()
    displayFrame:SetPoint("CENTER", UIParent, "CENTER", x or 0, y or 120)
end

--- Get current screen offset coordinates
-- @return xOfs number, yOfs number
function Overhead:GetPosition()
    local point, relativeTo, relativePoint, xOfs, yOfs = displayFrame:GetPoint()
    return xOfs or 0, yOfs or 120
end

--- Reset position back to default centered offset (0, 120)
function Overhead:ResetPosition()
    self:SetPosition(0, 120)
end
