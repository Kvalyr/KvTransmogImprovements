local addon, ns = ...
local i, _
local utils = ns.KVTI_Utils

-- ----------------------------------------------------------------------------------------------------------------
local KvTransmogImprovements = CreateFrame("Frame", "KvTransmogImprovements", UIParent)
local KVTI = KvTransmogImprovements
ns.KVTI = KVTI
KVTI.initDone = false
KVTI.author = "Kvalyr"
KVTI.addonPrefix = "KVTI"
KVTI.version = "0.3.1"
KVTI.savedVarsKey = "KvTransmogImprovements_SavedVariables"
KVTI.outfitNumbersAdded = false
KVTI.Masque = LibStub("Masque", true)
if KVTI.Masque then
	KVTI.Masque_Group_MainButtons = KVTI.Masque:Group("Transmog Improvements", "Main Buttons")
	KVTI.Masque_Group_OutfitButtons = KVTI.Masque:Group("Transmog Improvements", "Outfit Buttons")
end
KVTI.transmogFrameShown = false


-- ----------------------------------------------------------------------------------------------------------------
function KVTI:GetVersionNumber()
    return utils.versionStringToNumber(KVTI.version)
end


function KVTI:InitializeSavedVars()
	_G[KVTI.savedVarsKey] = {}
	_G[KVTI.savedVarsKey]["version_number"] = self:GetVersionNumber()
	_G[KVTI.savedVarsKey]["buttons"] = {}
end

function KVTI.SetupSavedVariables()
	local savedVars = _G[KVTI.savedVarsKey]
	if not savedVars or not savedVars["version_number"] then
		KVTI:InitializeSavedVars()
		savedVars = _G[KVTI.savedVarsKey]
	end
	KVTI.savedVars = _G[KVTI.savedVarsKey]
end


-- ----------------------------------------------------------------------------------------------------------------
KvTransmogImprovements:RegisterEvent("ADDON_LOADED")
KvTransmogImprovements:RegisterEvent("PLAYER_LOGIN")
KvTransmogImprovements:RegisterEvent("PLAYER_ENTERING_WORLD")
KvTransmogImprovements:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		KVTI.SetupSavedVariables()
	elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
		KVTI.Init(event, ...)
	end
end)


-- ----------------------------------------------------------------------------------------------------------------
function KVTI.LoadBlizzFrames(event)
	if not C_AddOns.IsAddOnLoaded("Blizard_TransmogShared") then
		C_AddOns.LoadAddOn("Blizard_TransmogShared")
	end
	if not C_AddOns.IsAddOnLoaded("Blizard_Transmog") then
		C_AddOns.LoadAddOn("Blizard_Transmog")
	end
	local TransmogFrame = _G["TransmogFrame"]
	if not TransmogFrame then
		UIParentLoadAddOn("Blizzard_Transmog")
	end

	if event == "PLAYER_ENTERING_WORLD" then
		assert(TransmogFrame ~= nil, "KVTI Error: Unable to load TransmogFrame during PLAYER_ENTERING_WORLD")
	end

	return TransmogFrame
end


-- ----------------------------------------------------------------------------------------------------------------
local function CreateBlockerFrame(parentFrame, frameName)
	local kvtido = CreateFrame("Frame", frameName, parentFrame)
	kvtido:SetFrameStrata("DIALOG")
	kvtido:EnableMouse(true)
	kvtido:SetPropagateMouseClicks(false)

	local tex = kvtido:CreateTexture(nil, "OVERLAY")
	tex:SetColorTexture(1, 0, 0, 0.15)
	tex:SetAllPoints()

	kvtido.UpdateTooltip = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:SetText("Visit a transmogrification NPC to modify outfits/sets.")
		GameTooltip:Show()
	end

	kvtido:SetScript("OnEnter", function(self)
		self:UpdateTooltip()
	end)

	kvtido:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	return kvtido
end


-- ----------------------------------------------------------------------------------------------------------------
function KVTI.ShowTransmogUI()
	UIParentLoadAddOn("Blizzard_Transmog");
	local TransmogFrame = KVTI.LoadBlizzFrames()
	TransmogFrame:Show()
end

function KVTI.CloseTransmogUI()
	local TransmogFrame = KVTI.LoadBlizzFrames()
	if TransmogFrame:IsShown() and TransmogFrame.CloseButton then
		TransmogFrame.CloseButton:Click()
	end
end

function KVTI.ToggleTransmogUI()
	local TransmogFrame = KVTI.LoadBlizzFrames()
	if TransmogFrame:IsShown() then
		KVTI.CloseTransmogUI()
		return
	end
	KVTI.ShowTransmogUI()
end

-- ----------------------------------------------------------------------------------------------------------------
local function SetupSlashCmd()
	SLASH_KVTI1 = "/transmog"
	SLASH_KVTI2 = "/kvti"

	-- 2. Define the function that runs when the command is used
	SlashCmdList["KVTI"] = function(msg)
		if not msg or msg == "" then
			KVTI.ShowTransmogUI()
		end
		if msg == "config" then
			Settings.OpenToCategory(KVTI.settingsCategory:GetID())
		end
	end
end


-- ----------------------------------------------------------------------------------------------------------------
function KVTI.AddNumbersToOutfitList(TransmogFrame)
	local idx = 1
	TransmogFrame.OutfitCollection.OutfitList.ScrollBox:ForEachFrame(function(frame)
		local elementData = frame:GetElementData();
		local button = nil
		if elementData then
			button = frame.OutfitButton
		end
		if button then
			local idx_text = tostring(idx)
			if strlen(idx_text) == 1 then
				idx_text = " " .. idx_text
			end
			idx_text = "\124cFFFFFF00" .. idx_text .. ":   " .. "|r"
			button.TextContent.Name:SetText(idx_text .. elementData.name);
		end
		idx = idx + 1
	end)
end

-- ----------------------------------------------------------------------------------------------------------------
function KVTI.Init(event, ...)
	if KVTI.initDone then
		return
	end

	-- For debugging convenience
	if not _G["KVTI"] then
		_G["KVTI"] = KVTI
	end

	local TransmogFrame = KVTI.LoadBlizzFrames(event)
	if not TransmogFrame then
		-- TODO: error logging?
		return
	end
	KVTI.TransmogFrame = TransmogFrame
	SetupSlashCmd()
	local OutfitList = TransmogFrame.OutfitCollection.OutfitList
	local SituationsFrame = TransmogFrame.WardrobeCollection.TabContent.SituationsFrame

	local kvtido = CreateBlockerFrame(TransmogFrame, "KVTI_BlockerL")
	KVTI.disabler_overlay = kvtido
	kvtido:SetPoint("TOPRIGHT", OutfitList, "BOTTOMRIGHT", 4, 0)
	kvtido:SetPoint("BOTTOMLEFT", TransmogFrame, "BOTTOMLEFT", 2, 4)

	local kvtidoSituations = CreateBlockerFrame(SituationsFrame, "KVTI_BlockerR")
	KVTI.disabler_overlaySituations = kvtidoSituations
	kvtidoSituations:SetPoint("BOTTOMLEFT", SituationsFrame, "BOTTOMLEFT", 4, 11)
	kvtidoSituations:SetPoint("BOTTOMRIGHT", SituationsFrame, "BOTTOMRIGHT", -8, 11)
	kvtidoSituations:SetHeight(100)

	local infoFrame = CreateFrame("Frame", "KVTI_Info", TransmogFrame, "TranslucentFrameTemplate")
	infoFrame:SetPoint("BOTTOMLEFT", TransmogFrame, "BOTTOMLEFT", 2, 4)
	infoFrame:SetPoint("TOP", OutfitList, "BOTTOM", 0, -4)
	infoFrame:SetWidth(550)
	infoFrame:SetFrameStrata("TOOLTIP")
	infoFrame:Hide()
	KVTI.infoFrame = infoFrame

	local infoFrameTextTitle = infoFrame:CreateFontString("KVTIInfoFrameText", "OVERLAY", "GameTooltipText")
	infoFrame.textTitle = infoFrameTextTitle
	infoFrameTextTitle:SetPoint("TOP", 0, -15)
	infoFrameTextTitle:SetTextColor(1, 0, 0, 1)
	infoFrameTextTitle:SetText("Transmog Functions are limited when not interacting with a Transmog NPC.")

	local infoFrameText = infoFrame:CreateFontString("KVTIInfoFrameTextTitle", "OVERLAY", "GameTooltipText")
	infoFrame.text = infoFrameText
	infoFrameText:SetPoint("CENTER", 0, 0)
	infoFrameText:SetPoint("TOPLEFT", infoFrame, "TOPLEFT", 14, -24)
	infoFrameText:SetPoint("BOTTOMRIGHT", infoFrame, "BOTTOMRIGHT", -14, 14)
	infoFrameText:SetText(
	"You CAN modify 'Custom Sets' and you CAN browse, preview and apply 'Outfits'.\nYou CANNOT save any modifications to Outfits or purchase new Outfit Slots.\n\nVisit a transmog NPC to make changes to Outfits.")

	KVTI.icon_suggester = KVTI.CreateIconSuggester(TransmogFrame)

	TransmogFrame:HookScript("OnShow", KVTI.TransmogFrame_OnShow)
	-- Also hook Init so that we re-update the outfit numbers after the player edits an outfit's name/icon
	hooksecurefunc(TransmogOutfitEntryMixin, "Init", KVTI.TransmogFrame_OnShow)

	TransmogFrame.OutfitPopup:HookScript("OnShow", KVTI.TransmogFrame_OutfitPopup_OnShow)

	local mainButton = KVTI:SetupButton()
	KVTI:CreateOutfitBar(mainButton)
	KVTI:SetupOptions()


	if KVTI.GetSavedVar("KVTI_CloseTransmogWithEsc") then
		tinsert(UISpecialFrames, "TransmogFrame")
	end

	KVTI.disabler_overlay:Hide()
	KVTI.disabler_overlaySituations:Hide()
	KVTI.infoFrame:Hide()

	KVTI.initDone = true
end
