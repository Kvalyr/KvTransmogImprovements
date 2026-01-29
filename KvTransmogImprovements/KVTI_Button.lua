local addon, ns = ...
local i, _
local KVTI = ns.KVTI
local utils = ns.KVTI_Utils

-- ----------------------------------------------------------------------------------------------------------------
KVTI.buttons = {}

local MAIN_BUTTON_NAME = "KVTI_TransmogButton_Main"
local DEFAULT_ANCHOR_1 = "CENTER"
local DEFAULT_ANCHOR_2 = "CENTER"
local DEFAULT_ANCHOR_FRAME = "UIParent"
local DEFAULT_X = 0
local DEFAULT_Y = -130
local DEFAULT_SIZE = 40
local DEFAULT_ENABLED = true
local DEFAULT_ALPHA = 0.5

local function CreateDefaultButtonSVTable(buttonSVTable)
    buttonSVTable = buttonSVTable or {}
    buttonSVTable.anchor1 = DEFAULT_ANCHOR_1
    buttonSVTable.anchor2 = DEFAULT_ANCHOR_2
    buttonSVTable.anchorFrame = DEFAULT_ANCHOR_FRAME
    buttonSVTable.x = DEFAULT_X
    buttonSVTable.y = DEFAULT_Y
    buttonSVTable.size = DEFAULT_SIZE
    buttonSVTable.enabled = DEFAULT_ENABLED
    -- buttonSVTable.showAlpha = 1.0
    buttonSVTable.fadeAlpha = DEFAULT_ALPHA
    return buttonSVTable
end

function KVTI:GetButton(btnName)
    btnName = btnName or MAIN_BUTTON_NAME
    local btn = self.buttons[btnName]
    return btn
end

function KVTI:MoveButtonToSavedPosition(btnName)
    btnName = btnName or MAIN_BUTTON_NAME
    local btn = self.buttons[btnName]
    btn:MovedToSavedPosition()
end

function KVTI:ResetButtonToDefaultPosition(btnName)
    btnName = btnName or MAIN_BUTTON_NAME
    local btn = self.buttons[btnName]
    btn:ResetPositionToDefault()
end

local function GetOrCreateButtonPositionTable(btnName)
    local buttonSVTable = KVTI.GetSavedVar("buttons." .. btnName) or CreateDefaultButtonSVTable()
    KVTI.SetSavedVar("buttons." .. btnName, buttonSVTable)
    return buttonSVTable
end

-- ----------------------------------------------------------------------------------------------------------------
function KVTI:SetupButton()
    if InCombatLockdown() then return end

    local buttonSVTable = GetOrCreateButtonPositionTable(MAIN_BUTTON_NAME)

    local btn = CreateFrame("Button", "KVTI_TransmogButton", UIParent, "SecureActionButtonTemplate")
    btn.name = MAIN_BUTTON_NAME
    self.buttons[MAIN_BUTTON_NAME] = btn
    btn:SetClampedToScreen(true)
    btn:EnableMouse(true)
    btn:RegisterForClicks("AnyUp", "AnyDown")
    btn:SetAttribute("useOnKeyDown", false)
    if not buttonSVTable.enabled then
        btn:Hide()
    end
    self:SetAlpha(buttonSVTable.fadeAlpha)

    btn:SetFrameStrata("HIGH")

    if not btn.NormalTexture then
        btn.NormalTexture = btn:CreateTexture(nil, "ARTWORK")
    end
    if not btn.HighlightTexture then
        btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
        btn.HighlightTexture = btn:GetHighlightTexture()
    end
    if not btn.PushedTexture then
        btn:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
        btn.PushedTexture = btn:GetPushedTexture()
    end

    -- local icon_transmog = 7539422               -- Ui_transmog_showequippedgear
    -- local icon_transmog = 1602705               -- Achievement_transmog_collections
    local icon_transmog = 1723993               -- Ability_racial_etherealconnection
    btn.NormalTexture:SetTexture(icon_transmog)
    btn.NormalTexture:SetAllPoints()
    btn.HighlightTexture:SetAllPoints()
    btn.PushedTexture:SetAllPoints()

    function btn:ToggleOutfitFrames(event)
        if not KVTI.transmogFrameShown then
            KVTI.ShowTransmogUI()
            KVTI.CloseTransmogUI()
        end
        local outfitButtonsContainer = KVTI.OutfitButtons_Container -- TODO: Clean up how we access this
        local clearBtn = KVTI:GetButton("KVTI_OutfitButton_Clear") -- TODO: Clean up how we access this
        if outfitButtonsContainer then
            outfitButtonsContainer:ClearAllPoints()
            outfitButtonsContainer:SetPoint("BOTTOM", self, "TOP", 0, 4)
            outfitButtonsContainer:Toggle() -- TODO: Clean up how we access this
        end
        if clearBtn then
            clearBtn:ClearAllPoints()
            clearBtn:SetPoint("TOP", self, "BOTTOM", 0, -4)
            local showSetting = KVTI.GetSavedVar("KVTI_ClearButton_Enabled", true)
            clearBtn:Toggle(showSetting)
        end
    end

    local mount1 = "Grand Expedition Yak"
    local mount2 = "Grizzly Hills Packmaster"
    local transmogToy = "Ethereal Transmogrifier"
    -- Left-Click
    btn:SetAttribute("type1", "macro")
    btn:SetAttribute("macrotext1", "/run KVTI.ToggleTransmogUI()")
    -- Right-Click
    -- TODO: Outfits bar
    btn:SetAttribute("type2", "macro")
    btn:SetAttribute("macrotext2", "/run KVTI_TransmogButton:ToggleOutfitFrames()")
    -- Shift + Right-Click
    btn:SetAttribute("shift-type2", "macro")
    btn:SetAttribute("shift-macrotext2", "/cast " .. mount1)
    -- Ctrl + Right-Click
    btn:SetAttribute("ctrl-type2", "macro")
    btn:SetAttribute("ctrl-macrotext2", "/cast " .. mount2)
    -- Alt + Right-Click
    btn:SetAttribute("alt-type2", "macro")
    btn:SetAttribute("alt-macrotext2", "/use " .. transmogToy)
    -- Middle-Click
    btn:SetAttribute("type3", "macro")
    btn:SetAttribute("macrotext3", "/run Settings.OpenToCategory(KVTI.settingsCategory:GetID())")


    local closeColorTag = "\124r"
    local greyColorTag = "\124cffBBBBBB"
    local whiteColorTag = "\124cffFFFFFF"
    local pinkColorTag = "\124cffFF99FF"
    local blueColorTag = "\124cff0088FF"

    local LClickText = "Left-Click: " .. whiteColorTag .. "Open Transmog Menu anywhere" .. closeColorTag
    local RClickText = "Right-Click: " .. whiteColorTag .. "Expand Oufits Bar" .. closeColorTag
    local ShiftRClickText = pinkColorTag .. "Shift " .. closeColorTag .. "+ Right-Click: " .. greyColorTag .. "Mount: " .. closeColorTag .. whiteColorTag .. mount1 .. closeColorTag
    local CtrlRClickText = pinkColorTag .. "Ctrl " .. closeColorTag .. "+ Right-Click: " .. greyColorTag .. "Mount: " .. closeColorTag .. whiteColorTag .. mount2 .. closeColorTag
    local AltRClickText = pinkColorTag .. "Alt " .. closeColorTag .. " + Right-Click: " .. greyColorTag .. "Toy: " .. closeColorTag .. whiteColorTag .. transmogToy .. closeColorTag
    local MClickText = "Middle-Click: Open Transmog Improvements Config. This button can also be toggled there."
    local dragText = "Left-Click and Drag to reposition this button."

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Transmog Improvements", 1, 0.5, 1)
        GameTooltip:AddLine("-", 0, 0, 0)
        GameTooltip:AddLine(LClickText, 0.5, 1, 1)
        GameTooltip:AddLine(RClickText, 0, 0.55, 1)
        GameTooltip:AddLine("-", 0, 0, 0)
        GameTooltip:AddLine(ShiftRClickText, 0, 0.55, 1)
        GameTooltip:AddLine(CtrlRClickText, 0, 0.55, 1)
        GameTooltip:AddLine(AltRClickText, 0, 0.55, 1)
        GameTooltip:AddLine("-", 0, 0, 0)
        GameTooltip:AddLine(MClickText, 0.9, 0.9, 1)
        GameTooltip:AddLine("-", 0, 0, 0)
        GameTooltip:AddLine(dragText, 0.75, 0.75, 1)
        GameTooltip:Show()
        self:SetAlpha(1)
    end)

    btn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        self:AlphaCallback()
    end)

    function btn:AlphaCallback(forceValue)
        if forceValue then
            self:SetAlpha(forceValue)
            return
        end
        local buttonSVTable = self:GetSavedVarsTable()
        if buttonSVTable.fadeAlpha and buttonSVTable.fadeAlpha < 1 then
            self:SetAlpha(buttonSVTable.fadeAlpha)
        end
    end

    btn:SetMovable(true)
    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", btn.StartMoving)
    btn:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        -- StopMovingOrSizing() re-anchors to the nearest parent anchor - We want to maintain our X/Y relative to CENTER/CENTER
        local centerX, centerY = self:GetCenter()
        if not centerX or not centerY then
            centerX = 0
            centerY = 0
        end
        local parentCenterX, parentCenterY = self:GetParent():GetCenter()
        -- local scale = self:GetEffectiveScale() -- TODO
        local xOffset = (centerX - parentCenterX)
        local yOffset = (centerY - parentCenterY)

        local anchor1 = "CENTER"
        local anchor2 = "CENTER"
        local anchorFrame = self:GetParent():GetName()
        self:ClearAllPoints()
        self:SetPoint(anchor1, anchorFrame, anchor2, xOffset, yOffset)

        btn:NewPositionCallback(anchor1, anchor2, anchorFrame, xOffset, yOffset, nil, false)
    end)

    btn.MoveToSavedPosition = function(self)
        local buttonSVTable = self:GetSavedVarsTable()
        self:ClearAllPoints()
        self:SetPoint(
            buttonSVTable.anchor1 or DEFAULT_ANCHOR_1,
            buttonSVTable.anchorFrame or DEFAULT_ANCHOR_FRAME,
            buttonSVTable.anchor2 or DEFAULT_ANCHOR_2,
            buttonSVTable.x or DEFAULT_X,
            buttonSVTable.y or DEFAULT_Y
        )
        self:SetSize(
            buttonSVTable.size or DEFAULT_SIZE,
            buttonSVTable.size or DEFAULT_SIZE
        )
        self:AlphaCallback()
    end

    btn.ResetPositionToDefault = function(self)
        KVTI.SetSavedVar("buttons." .. self.name, CreateDefaultButtonSVTable())
        self:MoveToSavedPosition()
    end

    btn.NewPositionCallback = function(self, anchor1, anchor2, anchorFrame, x, y, size, moveAfter)
        local buttonSVTable = self:GetSavedVarsTable()

        x = x or buttonSVTable.x
        x = math.floor(x * 2 + 0.5) / 2

        y = y or buttonSVTable.y
        y = math.floor(y * 2 + 0.5) / 2

        buttonSVTable.anchor1 = anchor1 or buttonSVTable.anchor1
        buttonSVTable.anchor2 = anchor2 or buttonSVTable.anchor2
        buttonSVTable.anchorFrame = anchorFrame or buttonSVTable.anchorFrame
        buttonSVTable.x = x
        buttonSVTable.y = y
        buttonSVTable.size = size or buttonSVTable.size
        if moveAfter then
            self:MoveToSavedPosition()
        end
    end

    btn.ToggleCallback = function(self, newValue)
        self:SetSavedVar("enabled", newValue)
        if newValue then
            self:Show()
        else
            self:Hide()
        end
    end

    btn.GetSavedVarsTable = function(self)
        return KVTI.GetSavedVar("buttons." .. self.name)
    end

    btn.GetSavedVar = function(self, varKey, default)
        return KVTI.GetSavedVar("buttons." .. self.name .. "." .. varKey, default)
    end

    btn.SetSavedVar = function(self, varKey, newValue)
        return KVTI.SetSavedVar("buttons." .. self.name .. "." .. varKey, newValue)
    end

    btn:MoveToSavedPosition()
	if KVTI.Masque_Group_MainButtons then
		KVTI.Masque_Group_MainButtons:AddButton(
			btn,
			{
				Icon = btn.NormalTexture,
				Highlight = btn.HighlightTexture,
				Pushed = btn.PushedTexture,
			}
		)
	end
    return btn
end
