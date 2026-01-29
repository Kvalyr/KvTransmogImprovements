local addon, ns = ...
local i, _
local KVTI = ns.KVTI
local utils = ns.KVTI_Utils
local C_TransmogOutfitInfo = _G["C_TransmogOutfitInfo"]
-- ----------------------------------------------------------------------------------------------------------------


-- ----------------------------------------------------------------------------------------------------------------
function KVTI.TransmogFrame_OutfitPopup_OnShow(...)
	local iconSuggesterEnabled = KVTI.GetSavedVar("KVTI_DoIconSuggestions", true)
	if not KVTI.initDone or not iconSuggesterEnabled then
		if KVTI.icon_suggester then
			KVTI.icon_suggester:Hide()
		end
		print("KVTI.TransmogFrame_OutfitPopup_OnShow", "Quitting early")
		return
	end
	local TransmogFrame = KVTI.TransmogFrame
	local outfitData = TransmogFrame.OutfitPopup.outfitData
	if outfitData then
		C_TransmogOutfitInfo.ChangeViewedOutfit(outfitData.outfitID)
		KVTI.icon_suggester:Update()
		KVTI.icon_suggester:Show()
	else
		KVTI.icon_suggester:Hide()
	end
end


-- ----------------------------------------------------------------------------------------------------------------
function KVTI.TransmogFrame_OnShow(...)
	KVTI.transmogFrameShown = true
	if not KVTI.initDone then
		return
	end

	local outfitButtonsContainer = KVTI.OutfitButtons_Container
	if outfitButtonsContainer then
		outfitButtonsContainer:Update()
	end

	if KVTI.GetSavedVar("KVTI_AddOutfitNumbers") then
		KVTI.AddNumbersToOutfitList(KVTI.TransmogFrame)
	end

	local atNPC = C_Transmog.IsAtTransmogNPC()
	if atNPC then
		KVTI.disabler_overlay:Hide()
		KVTI.disabler_overlaySituations:Hide()
		KVTI.infoFrame:Hide()
		return
	end
	KVTI.disabler_overlay:Show()
	KVTI.disabler_overlaySituations:Show()
	KVTI.infoFrame:Show()
end
