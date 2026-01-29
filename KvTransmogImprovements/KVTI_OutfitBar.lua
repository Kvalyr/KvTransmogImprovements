local addon, ns = ...
local i, _
local KVTI = ns.KVTI
local utils = ns.KVTI_Utils
local C_TransmogOutfitInfo = _G["C_TransmogOutfitInfo"]
-- ----------------------------------------------------------------------------------------------------------------
KVTI.outfitButtons = {}
local OUTFIT_BUTTON_NAME = "KVTI_OutfitButton"
local DEFAULT_OUTFIT_BUTTON_TEXTURE = 1602705 -- Achievement_transmog_collections


-- ----------------------------------------------------------------------------------------------------------------
function KVTI.GetOutfitInfosByOutfitID()
	local outfitInfos = {}
	local outfitsInfo = C_TransmogOutfitInfo.GetOutfitsInfo()
	for _, outfitInfo in pairs(outfitsInfo) do
		outfitInfos[outfitInfo.outfitID] = outfitInfo
	end
	return outfitInfos
end

-- ----------------------------------------------------------------------------------------------------------------
function KVTI.FindBlizzOutfitButton(findOutfitID)
	local frame = TransmogFrame.OutfitCollection.OutfitList.ScrollBox:ForEachFrame(
		function(frame)
			local elementData = frame:GetElementData();
			local outfitID
			local button = nil
			if elementData then
				button = frame.OutfitButton
				outfitID = elementData.outfitID
			end
			if button and outfitID then
				if outfitID == findOutfitID then
					return frame
				end
			end
		end
	)
	if frame and frame.OutfitIcon then
		return frame.OutfitIcon
	end
end


-- ----------------------------------------------------------------------------------------------------------------
function KVTI:ShowCooldownAllOutfitButtons(duration)
	duration = duration or 3
	local container = KVTI.OutfitButtons_Container
	if container then
		self.OutfitButtons_Container:ShowCooldowns(3)
	end
	local clearBtn = self:GetButton("KVTI_OutfitButton_Clear")
	if clearBtn then
		clearBtn:ShowCooldown(duration)
	end
end



-- ----------------------------------------------------------------------------------------------------------------
local function createSecureButton(btnName, icon, parent)
	local btn = CreateFrame("Button", btnName, parent or UIParent, "SecureActionButtonTemplate")
	btn.name = btnName
	btn:SetClampedToScreen(true)
	btn:EnableMouse(true)
	btn:RegisterForClicks("AnyUp", "AnyDown")
	btn:SetAttribute("useOnKeyDown", false)

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

	if not btn.Cooldown then
		btn.Cooldown = CreateFrame("Cooldown", "$parentCooldown", btn, "CooldownFrameTemplate")
		btn.Cooldown:SetAllPoints() -- Make it cover the whole button
	end

	function btn:ShowCooldown(duration)
		local start = GetTime()
		self.Cooldown:SetCooldown(start, duration)
	end

	btn:SetScript("PostClick", function(self, button, down)
		KVTI:ShowCooldownAllOutfitButtons(3)
	end)

    btn:SetScript("OnEnter", function(self)
		self:GetParent():AlphaCallback(1)
    end)
    btn:SetScript("OnLeave", function(self)
		self:AlphaCallback()
    end)

	function btn:AlphaCallback(alpha)
		self:GetParent():AlphaCallback(alpha)
	end


	btn.NormalTexture:SetTexture(icon)
	btn.NormalTexture:SetAllPoints()
	btn.HighlightTexture:SetAllPoints()
	btn.PushedTexture:SetAllPoints()

	return btn
end


-- ----------------------------------------------------------------------------------------------------------------
local function createOutfitButton(idx, parent, size)
	local btnName = OUTFIT_BUTTON_NAME .. "_" .. idx
	local btn = createSecureButton(btnName, DEFAULT_OUTFIT_BUTTON_TEXTURE, parent)
	btn.idx = idx
	size = size or 40

	btn:SetSize(size, size)

	-- ------------
	-- Tooltip
	btn:SetScript("OnEnter", function(self)
		self:AlphaCallback(1)
		if not self.outfitName then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if KVTI.GetSavedVar("KVTI_AddOutfitNumbers") then
			GameTooltip:AddLine(idx .. ": " .. self.outfitName, 1, 1, 1)
		else
			GameTooltip:AddLine(self.outfitName, 1, 1, 1)
		end
		GameTooltip:Show()
	end)

	btn:SetScript("OnLeave", function(self)
		self:AlphaCallback()
		GameTooltip:Hide()
	end)

	function btn:Update(outfitTable)
		local outfitID = outfitTable.outfitID
		self.outfitID = outfitID
		self.outfitName = outfitTable.name
		self:SetID(outfitID)
		local blizzOutfitButton = KVTI.FindBlizzOutfitButton(outfitID)
		if blizzOutfitButton then
			utils.setupButtonProxy(btn, blizzOutfitButton)
		end
		self.NormalTexture:SetTexture(outfitTable.icon)
		self:Show()
	end

	function btn:Reset()
		self.outfitID = nil
		self.outfitName = "[No Outfit]"
		self.NormalTexture:SetTexture(DEFAULT_OUTFIT_BUTTON_TEXTURE)
		self:SetID(-1)
		self:Hide()
	end

	if KVTI.Masque_Group_OutfitButtons then
		KVTI.Masque_Group_OutfitButtons:AddButton(
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


-- ----------------------------------------------------------------------------------------------------------------
-- "Interface\\Buttons\\WHITE8x8"
-- "Interface\\Tooltips\\UI-Tooltip-Border"
-- "Interface\\DialogFrame\\UI-DialogBox-Border"
local function createBorderForFrame(frame, borderThickness, borderEdgeFile)
	local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	borderThickness = borderThickness or 16
	local borderInset = borderThickness / 2
	borderEdgeFile = borderEdgeFile or "Interface\\Tooltips\\UI-Tooltip-Border"
	border:SetPoint("TOPLEFT", frame, "TOPLEFT", -borderInset, borderInset)
	border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", borderInset, -borderInset)
	border:SetBackdrop({
		edgeFile = borderEdgeFile,
		edgeSize = borderThickness,
		insets = { left = borderInset, right = borderInset, top = borderInset, bottom = borderInset },
	})
	border:SetBackdropBorderColor(1, 1, 1, 1)
	return border
end


-- ----------------------------------------------------------------------------------------------------------------
local clearButtonDone = false
function KVTI:CreateClearTransmogButton(parent, size)
	if clearButtonDone then
		return
	end
	clearButtonDone = true

	size = size or 40
	local btnName = OUTFIT_BUTTON_NAME .. "_Clear"

	local icon_transmog = 7539422 -- Ui_transmog_showequippedgear
	local clearBtn = createSecureButton(btnName, icon_transmog, parent)
	utils.setupButtonProxy(clearBtn, TransmogFrame.OutfitCollection.ShowEquippedGearSpellFrame.Button)
	clearBtn.NormalTexture:SetVertexColor(1, 0.75, 0.75, 1)

	clearBtn:SetScript("OnEnter", function(self)
		self:AlphaCallback(1)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Clear Current Transmogrification", 1, 0.75, 0.15)
		GameTooltip:AddLine(" ", 1, 0.75, 0.15)
		GameTooltip:AddLine("Resets all equipped gear to their original appearance", 1, 0.75, 0.15)
		GameTooltip:Show()
	end)

	clearBtn:SetScript("OnLeave", function(self)
		self:AlphaCallback()
		GameTooltip:Hide()
	end)

	function clearBtn:Toggle(forceState)
		if forceState ~= nil then
			self:SetShown(forceState)
			return
		end
		self:SetShown(not self:IsShown())
	end

	clearBtn:SetSize(size, size)

	if KVTI.Masque_Group_MainButtons then
		KVTI.Masque_Group_MainButtons:AddButton(
			clearBtn,
			{
				Icon = clearBtn.NormalTexture,
				Highlight = clearBtn.HighlightTexture,
				Pushed = clearBtn.PushedTexture,
			}
		)
	end

	clearBtn:Hide()
	self.buttons[btnName] = clearBtn
	return clearBtn
end

-- ----------------------------------------------------------------------------------------------------------------
local outfitBarDone = false
function KVTI:CreateOutfitBar(parentFrame)
	if outfitBarDone then
		return
	end
	outfitBarDone = true

	parentFrame = parentFrame or UIParent

	local outfitButtonSize = 36
	local outfitButtonsPerRow = 8
	local maxOutfitButtonsCount = 50 -- C_TransmogOutfitInfo.GetMaxNumberOfUsableOutfits() or 51
	local numRows = math.ceil(maxOutfitButtonsCount / outfitButtonsPerRow)

	local containerPadding = 5
	local containerFrame = CreateFrame("Frame", "KVTI_OutfitButtons_Container", parentFrame, "VerticalLayoutFrame")
	containerFrame:SetPoint("LEFT")
	containerFrame:SetSize(700, 700)
	containerFrame:SetClampedToScreen(true)
	containerFrame.bg = containerFrame:CreateTexture(nil, "BACKGROUND")
	containerFrame.bg:SetAllPoints(containerFrame)
	containerFrame.bg:SetColorTexture(0, 0, 0, 0.5)
	containerFrame.topPadding = containerPadding
	containerFrame.bottomPadding = containerPadding
	containerFrame.leftPadding = containerPadding
	containerFrame.rightPadding = containerPadding
	containerFrame.spacing = 0
	containerFrame.outfitButtons = {}
	KVTI.OutfitButtons_Container = containerFrame
	local border = createBorderForFrame(containerFrame, 4, "Interface\\Buttons\\WHITE8x8")
	border:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)

	containerFrame.buttonLayoutFrames = {}

    containerFrame:SetScript("OnEnter", function(self)
		self:GetParent():AlphaCallback(1)
    end)
    containerFrame:SetScript("OnLeave", function(self)
		self:AlphaCallback()
    end)
    containerFrame:SetScript("OnShow", function(self)
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
    end)

	function containerFrame:AlphaCallback(alpha)
		self:GetParent():AlphaCallback(alpha)
	end

	function containerFrame:Toggle(event)
		self:SetShown(not self:IsShown())
	end

	function containerFrame:ShowCooldowns(duration)
		for idx, button in pairs(containerFrame.outfitButtons) do
			button:ShowCooldown(duration)
		end
	end

	function containerFrame:Update(event)
		local allOutfitInfos = C_TransmogOutfitInfo.GetOutfitsInfo()
		for idx, button in pairs(containerFrame.outfitButtons) do
			local outfitTable = allOutfitInfos[idx]
			if outfitTable then
				button:Update(outfitTable)
			else
				button:Reset()
			end
		end

		for _, buttonLayout in pairs(self.buttonLayoutFrames) do
			buttonLayout:Layout()
		end
		containerFrame:Layout()
	end

	for rowIdx = 1, numRows do
		local buttonsLayout = CreateFrame("Frame", "KVTI_ButtonLayout_" .. rowIdx, containerFrame, "HorizontalLayoutFrame")
		buttonsLayout.spacing = 2
		buttonsLayout.expand = true
		buttonsLayout:SetScript("OnEnter", function(self)
			self:AlphaCallback(1)
		end)
		buttonsLayout:SetScript("OnLeave", function(self)
			self:AlphaCallback()
		end)

		function buttonsLayout:AlphaCallback(alpha)
			self:GetParent():AlphaCallback(alpha)
		end
		local border = createBorderForFrame(buttonsLayout, 2, "Interface\\Buttons\\WHITE8x8")
		border:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.75)

		buttonsLayout.layoutIndex = numRows - rowIdx + 1
		tinsert(containerFrame.buttonLayoutFrames, buttonsLayout)

		do
			for idx = 1, outfitButtonsPerRow do
				local buttonOverallIndex = idx + (outfitButtonsPerRow * (rowIdx - 1))
				local btn = createOutfitButton(buttonOverallIndex, buttonsLayout, outfitButtonSize)
				tinsert(containerFrame.outfitButtons, btn)
				btn.layoutIndex = idx
				btn.align = "center"
			end
			buttonsLayout:Layout()
		end
	end

	KVTI:CreateClearTransmogButton(containerFrame, 28)

	containerFrame:Update()
	containerFrame:Hide()
end
