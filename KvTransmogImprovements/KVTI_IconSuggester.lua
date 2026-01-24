local addon, ns = ...
local i, _
local KVTI = ns.KVTI
-- ----------------------------------------------------------------------------------------------------------------

function KVTI.CreateIconSuggester(TransmogFrame)

	local frame = CreateFrame("Frame", "KVTI_IconSuggest", TransmogFrame.OutfitPopup, "TranslucentFrameTemplate")
	frame:SetSize(140,440)
	frame:SetPoint("TOPLEFT", TransmogFrame.OutfitPopup, "TOPRIGHT", 0, 0)

    local frameTitle = frame:CreateFontString("KVTI_IconSuggest", "OVERLAY", "GameTooltipText")
    frame.titleFS = frameTitle
    frameTitle:SetPoint("TOP", 0, -15)
    frameTitle:SetText("Icon Suggestions")

    -- ------------------------
	local function CreateIconSuggestionButton(parentFrame, idx)
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
				btn = CreateIconSuggestionButton(self, idx)
				btn:SetPoint("TOP", anchorFrame, anchorPoint, xOffset, yOffset)
				self.buttons[idx] = btn
			end
			btn:UpdateTexture(slot.Icon:GetTexture())
		end
	end

    -- ------------------------
	local leftSlots = CreateFrame("Frame", frame:GetName() .. "LeftSlots", frame)
	leftSlots:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -20)
	leftSlots:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", 0, 0)
	leftSlots.buttons = {}
	leftSlots.associatedBlizzFrame = TransmogFrame.CharacterPreview.LeftSlots
	leftSlots.UpdateButtons = UpdateIconSuggestionButtonSet
	frame.leftSlots = leftSlots

	local rightSlots = CreateFrame("Frame", frame:GetName() .. "RightSlots", frame)
	rightSlots:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -20)
	rightSlots:SetPoint("BOTTOMLEFT", frame, "BOTTOM", 0, 120)
	rightSlots.buttons = {}
	rightSlots.associatedBlizzFrame = TransmogFrame.CharacterPreview.RightSlots
	rightSlots.UpdateButtons = UpdateIconSuggestionButtonSet
	frame.rightSlots = rightSlots

    -- Weapon Slots
	local bottomSlots = CreateFrame("Frame", frame:GetName() .. "BottomSlots", frame)
	bottomSlots:SetPoint("TOPLEFT", rightSlots, "BOTTOMLEFT", 0, 0)
	bottomSlots:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
	bottomSlots.buttons = {}
	bottomSlots.associatedBlizzFrame = TransmogFrame.CharacterPreview.BottomSlots
	bottomSlots.UpdateButtons = UpdateIconSuggestionButtonSet
	frame.bottomSlots = bottomSlots


    -- Add an overlay frame to significantly darken the CharacterPreview frame and better highlight the TransmogFrame.OutfitPopup when open
    local previewOverlay = CreateFrame("Frame", nil, frame)
    previewOverlay:SetPoint("TOPLEFT", TransmogFrame.CharacterPreview, "TOPLEFT", 0, -4)
    previewOverlay:SetPoint("BOTTOMRIGHT", TransmogFrame.CharacterPreview, "BOTTOMRIGHT", 0, 4)
    -- previewOverlay:SetFrameStrata("MEDIUM")
    previewOverlay:SetFrameLevel(TransmogFrame.CharacterPreview:GetFrameLevel()-1)

    previewOverlay.tex = previewOverlay:CreateTexture(nil, "ARTWORK")
    previewOverlay.tex:SetColorTexture(0, 0, 0, 0.75)
    previewOverlay.tex:SetAllPoints()

	return frame

end
