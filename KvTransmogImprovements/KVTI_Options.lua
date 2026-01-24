local addon, ns = ...
local i, _
local KVTI = ns.KVTI
-- ----------------------------------------------------------------------------------------------------------------

function KVTI.SetupOptions()
    local category = Settings.RegisterVerticalLayoutCategory("Transmog Improvements")
    Settings.RegisterAddOnCategory(category)
    KVTI.settingsCategory = category

    local KVTI_AddOutfitNumbers = Settings.RegisterAddOnSetting(
        category,
        "KVTI_AddOutfitNumbers",
        "KVTI_AddOutfitNumbers",
        KvTransmogImprovements_SavedVariables,
        "boolean",
        "Outfit Numbers",
        true
    )
    Settings.CreateCheckbox(category, KVTI_AddOutfitNumbers, "Add index numbers to Outfits in the Transmog Menu.\n\nNote: These are NOT internal Outfit IDs!")

    local KVTI_DoIconSuggestions = Settings.RegisterAddOnSetting(
        category,
        "KVTI_DoIconSuggestions",
        "KVTI_DoIconSuggestions",
        KvTransmogImprovements_SavedVariables,
        "boolean",
        "Suggest Icons from Appearances",
        true
    )
    Settings.CreateCheckbox(category, KVTI_DoIconSuggestions, "When (re)naming an outfit: Adds a small window with icons of the gear appearances in the outfit.\n\nYou can click them to choose their icon as the icon of the outfit before saving.")

    local CloseTransmogWithEsc = Settings.RegisterAddOnSetting(
        category,
        "KVTI_CloseTransmogWithEsc",
        "KVTI_CloseTransmogWithEsc",
        KvTransmogImprovements_SavedVariables,
        "boolean",
        "Close Transmog Menu with ESC",
        false
    )
    Settings.CreateCheckbox(category, CloseTransmogWithEsc, "When enabled, pressing ESC/Escape will close the Transmog menu.\n\nYour UI must reload (or log in/out) for this setting to take effect.")

end

-- ----------------------------------------------------------------------------------------------------------------
function KVTI.GetSetting(settingKey)
    local setting = KvTransmogImprovements_SavedVariables[settingKey]
    return setting or false
end

-- ----------------------------------------------------------------------------------------------------------------
function KVTI.SetupMinimapButton()
    local LDB = LibStub("LibDataBroker-1.1")
    if not LDB then return end
    local LDBI = LibStub("LibDBIcon-1.0")
    if not LDBI then return end

    -- TODO: Bundle libs

    local onclick_func = function(self, button)
        if button == "LeftButton" then
            KVTI.ShowTransmogUI()
        elseif button == "RightButton" then
            Settings.OpenToCategory(KVTI.settingsCategory:GetID())
        end
    end

    local KVTI_LDB = LDB:NewDataObject("KVTI", {
        type = "data source",
        text = "Transmog Improvements",
        icon = "Interface\\Icons\\INV_Chest_Cloth_17",
        OnClick = onclick_func,
    })

    LDBI:Register("KVTI", KVTI_LDB, nil)
end
