local addon, ns = ...
local i, _
local KVTI = ns.KVTI
-- ----------------------------------------------------------------------------------------------------------------
local NUM_SUGGESTIONS = 14 -- 14 addressable equipment slots + extra 1 for separate shoulder slot
local NUM_SUGGESTIONS_ROW_T = 7
local NUM_SUGGESTIONS_ROW_B = NUM_SUGGESTIONS - NUM_SUGGESTIONS_ROW_T

local SUGGESTIONS_START_INDEX_LEFT = 1
local SUGGESTIONS_START_INDEX_RIGHT = 9 -- Allow for 7 slots in leftSlots + 1 extra when separate shoulders
local SUGGESTIONS_START_INDEX_BOTTOM = 13


-- ----------------------------------------------------------------------------------------------------------------
local function CreateIconSuggestionButton(TransmogFrame, parentFrame, idx)
    local btn = CreateFrame("Button", parentFrame:GetName() .. "Button" .. idx, parentFrame, "ActionButtonTemplate")
    btn:SetSize(45,45)
    btn.Icon = btn:CreateTexture(nil, "ARTWORK")
    btn.Icon:SetAllPoints()

    btn.OnClick = function(...)
        local iconTextureID = btn.Icon:GetTexture()

        TransmogFrame.OutfitPopup.IconSelector:SetSelectedIndex(
            TransmogFrame.OutfitPopup:GetIndexOfIcon(iconTextureID)
        )
        TransmogFrame.OutfitPopup.BorderBox.SelectedIconArea.SelectedIconButton:SetIconTexture(
            iconTextureID
        );
        TransmogFrame.OutfitPopup.IconSelector:ScrollToSelectedIndex();

    end
    btn:SetScript("OnMouseUp", btn.OnClick)

    btn.UpdateTexture = function(self, iconTexture)
        if not iconTexture or iconTexture == 7344439 then
            btn.Icon:Hide()
            btn:Disable()
            btn:SetAlpha(0.5)
            return
        end
        btn.Icon:SetTexture(iconTexture)
        btn.Icon:Show()
        btn:Enable()
        btn:SetAlpha(1)
    end
    return btn
end

-- ----------------------------------------------------------------------------------------------------------------
local function createSplitSuggestionIcons(TransmogFrame, parentFrame)
    -- Create 3 different subframes of suggestion slots mapping to letSlots, rightSlots, bottomSlots

    -- ------------------------
	local function UpdateIconSuggestionButtonSet(self)
		for idx,slot in pairs(self.associatedBlizzFrame:GetLayoutChildren()) do
			local btn = self.buttons[idx]
			if not btn then
				local anchorFrame = self
				local anchorPoint = "TOP"
				local xOffset = 0
				local yOffset = -12
				local prevBtn = self.buttons[idx-1]
				if prevBtn then
					anchorFrame = prevBtn
					anchorPoint = "BOTTOM"
					xOffset = 0
					yOffset = -5
				end
				btn = CreateIconSuggestionButton(TransmogFrame, self, idx)
				btn:SetPoint("TOP", anchorFrame, anchorPoint, xOffset, yOffset)
				self.buttons[idx] = btn
			end
			btn:UpdateTexture(slot.Icon:GetTexture())
		end
	end

    -- ------------------------
	local leftSlots = CreateFrame("Frame", parentFrame:GetName() .. "LeftSlots", parentFrame)
	leftSlots:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, -20)
	leftSlots:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOM", 0, 0)
	leftSlots.buttons = {}
	leftSlots.associatedBlizzFrame = TransmogFrame.CharacterPreview.LeftSlots
	leftSlots.UpdateButtons = UpdateIconSuggestionButtonSet
	parentFrame.leftSlots = leftSlots

	local rightSlots = CreateFrame("Frame", parentFrame:GetName() .. "RightSlots", parentFrame)
	rightSlots:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", 0, -20)
	rightSlots:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOM", 0, 120)
	rightSlots.buttons = {}
	rightSlots.associatedBlizzFrame = TransmogFrame.CharacterPreview.RightSlots
	rightSlots.UpdateButtons = UpdateIconSuggestionButtonSet
	parentFrame.rightSlots = rightSlots

    -- Weapon Slots
	local bottomSlots = CreateFrame("Frame", parentFrame:GetName() .. "BottomSlots", parentFrame)
	bottomSlots:SetPoint("TOPLEFT", rightSlots, "BOTTOMLEFT", 0, 0)
	bottomSlots:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", 0, 0)
	bottomSlots.buttons = {}
	bottomSlots.associatedBlizzFrame = TransmogFrame.CharacterPreview.BottomSlots
	bottomSlots.UpdateButtons = UpdateIconSuggestionButtonSet
	parentFrame.bottomSlots = bottomSlots
end


-- ----------------------------------------------------------------------------------------------------------------
local function createCombinedSuggestionIcons(TransmogFrame, parentFrame)
    -- Create one bucket of suggestion slots across all of leftSlots, rightSlots, bottomSlots

    -- ------------------------
	local function UpdateIconSuggestionButtonSet(self)
        local leftSlots = TransmogFrame.CharacterPreview.LeftSlots:GetLayoutChildren()
        local rightSlots = TransmogFrame.CharacterPreview.RightSlots:GetLayoutChildren()
        local bottomSlots = TransmogFrame.CharacterPreview.BottomSlots:GetLayoutChildren()
        local combinedSlots = {}

        for idx=1, SUGGESTIONS_START_INDEX_RIGHT-1 do
            combinedSlots[idx] = leftSlots[idx] -- We expect the value at idx 9 to occasionally be nil
        end
        for _, v in pairs(rightSlots) do
            tinsert(combinedSlots, v)
        end
        for _, v in pairs(bottomSlots) do
            tinsert(combinedSlots, v)
        end

        for idx=1, self.maxButtons do
            local slot = combinedSlots[self.startIndex -1 + idx]
			local btn = self.buttons[idx]
			if not btn then
				local anchorFrame = self
				local anchorPoint = "LEFT"
				local xOffset = 12
				local yOffset = 0
				local prevBtn = self.buttons[idx-1]
				if prevBtn then
					anchorFrame = prevBtn
					anchorPoint = "RIGHT"
					xOffset = 5
					yOffset = -0
				end
				btn = CreateIconSuggestionButton(TransmogFrame, self, idx)
				btn:SetPoint("LEFT", anchorFrame, anchorPoint, xOffset, yOffset)
				self.buttons[idx] = btn
			end
            if slot then
			    btn:UpdateTexture(slot.Icon:GetTexture())
            else
                btn:Disable()
                btn:SetAlpha(0.5)
            end
		end
	end

    -- ------------------------
    local rowT = CreateFrame("Frame", parentFrame:GetName() .. "RowT", parentFrame)
	rowT:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 1, -25)
	rowT:SetPoint("BOTTOMRIGHT", parentFrame, "RIGHT", -0, -10)
    rowT.maxButtons = NUM_SUGGESTIONS_ROW_T
    rowT.startIndex = 1
	rowT.buttons = {}
	rowT.UpdateButtons = UpdateIconSuggestionButtonSet
	parentFrame.rowT = rowT
    -- ------------------------
    local rowB = CreateFrame("Frame", parentFrame:GetName() .. "RowB", parentFrame)
    rowB:SetPoint("TOP", rowT, "BOTTOM")
    rowB:SetSize(rowT:GetWidth(), rowT:GetHeight())
    rowB.maxButtons = NUM_SUGGESTIONS_ROW_B
    rowB.startIndex = NUM_SUGGESTIONS_ROW_T + 1
	rowB.buttons = {}
	rowB.UpdateButtons = UpdateIconSuggestionButtonSet
	parentFrame.rowB = rowB
end


-- ----------------------------------------------------------------------------------------------------------------
function KVTI.CreateIconSuggester(TransmogFrame)
    local splitSuggestions = false
    local suggestionFrame_selfAnchor = "TOP"
    local suggestionFrame_targetAnchor = "BOTTOM"
    local suggestionFrame_width = 370
    local suggestionFrame_height = 145
    local suggestionFrame_x = 0
    local suggestionFrame_y = 10
    if splitSuggestions then
        suggestionFrame_selfAnchor = "TOPLEFT"
        suggestionFrame_targetAnchor = "TOPRIGHT"
        suggestionFrame_width = 140
        suggestionFrame_height = 440
        suggestionFrame_x = 0
        suggestionFrame_y = 0
    end

	local frame = CreateFrame("Frame", "KVTI_IconSuggest", TransmogFrame.OutfitPopup, "TranslucentFrameTemplate")
	frame:SetSize(suggestionFrame_width, suggestionFrame_height)
	frame:SetPoint(suggestionFrame_selfAnchor, TransmogFrame.OutfitPopup, suggestionFrame_targetAnchor, suggestionFrame_x, suggestionFrame_y)

    local frameTitle = frame:CreateFontString("KVTI_IconSuggest", "OVERLAY", "GameTooltipText")
    frame.titleFS = frameTitle
    frameTitle:SetPoint("TOP", 0, -15)
    frameTitle:SetText("Icon Suggestions")

    -- Add an overlay frame to significantly darken the CharacterPreview frame and better highlight the TransmogFrame.OutfitPopup when open
    local previewOverlay = CreateFrame("Frame", nil, frame)
    previewOverlay:SetPoint("TOPLEFT", TransmogFrame.CharacterPreview, "TOPLEFT", 0, -4)
    previewOverlay:SetPoint("BOTTOMRIGHT", TransmogFrame.CharacterPreview, "BOTTOMRIGHT", 0, 4)
    previewOverlay:SetFrameLevel(TransmogFrame.CharacterPreview:GetFrameLevel()-1)

    previewOverlay.tex = previewOverlay:CreateTexture(nil, "ARTWORK")
    previewOverlay.tex:SetColorTexture(0, 0, 0, 0.75)
    previewOverlay.tex:SetAllPoints()

    if splitSuggestions then
        createSplitSuggestionIcons(TransmogFrame, frame)
    else
        createCombinedSuggestionIcons(TransmogFrame, frame)
    end

    frame.Update = function(self)
        if splitSuggestions then
            self.leftSlots:UpdateButtons()
            self.rightSlots:UpdateButtons()
            self.bottomSlots:UpdateButtons()
        else
            self.rowT:UpdateButtons()
            self.rowB:UpdateButtons()
        end
    end

	return frame

end
