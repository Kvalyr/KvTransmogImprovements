local addon, ns = ...
local i, _
local KVTI = ns.KVTI
local utils = ns.KVTI_Utils
-- ----------------------------------------------------------------------------------------------------------------


-- ----------------------------------------------------------------------------------------------------------------
function KVTI.GetSavedVar(varPath, default)
	local savedVars = _G[KVTI.savedVarsKey]
    -- assert(varPath and type(varPath) == "string")
	if not varPath or type(varPath) ~= "string" then return end
    if savedVars[varPath] ~= nil then
        return savedVars[varPath]
    end

	local retVar = savedVars
	for w in string.gmatch(varPath, "[%w_]+") do
		if retVar and type(retVar) == "table" then
			retVar = retVar[w]
		end
	end
    if retVar == nil then
        return default
    end
	return retVar
end


-- ----------------------------------------------------------------------------------------------------------------
function KVTI.SetSavedVar(varPath, newValue)
	local savedVars = _G[KVTI.savedVarsKey]
    -- assert(varPath and type(varPath) == "string")
	if not varPath or type(varPath) ~= "string" then return end
	local tbl = savedVars

    if not string.find(varPath, "%.") and tbl[varPath] ~= nil then
        savedVars[varPath] = newValue
        return
    end

    for w, d in string.gmatch(varPath, "([%w_]+)(.?)") do
		if d == "." then
			tbl[w] = tbl[w] or {}
			tbl = tbl[w]
		else
			tbl[w] = newValue
		end
	end
end


-- ----------------------------------------------------------------------------------------------------------------


local function getGlobalSavedVar(savedVarKey, default)
    return KVTI.GetSavedVar(savedVarKey, default)
end


local function setGlobalSavedVar(savedVarKey, newValue)
    return KVTI.SetSavedVar(savedVarKey, newValue)
end


local function getSavedVarForButton(btnName, savedVarKey, default)
    local btn = KVTI:GetButton(btnName)
    return btn:GetSavedVar(savedVarKey, default)
end


local function setSavedVarForButton(btnName, savedVarKey, newValue)
    local btn = KVTI:GetButton(btnName)
    return btn:SetSavedVar(savedVarKey, newValue)
end


local function createSetting(category, settingType, settingName, savedVarsKey, settingLabel, defaultValue)
    local getValueFunc = function() return getGlobalSavedVar(savedVarsKey, defaultValue) end
    local setValueFunc = function(newValue) return setGlobalSavedVar(savedVarsKey, newValue) end
    return Settings.RegisterProxySetting(
        category, settingName, settingType, settingLabel, defaultValue, getValueFunc, setValueFunc
    )
end

local redText = "\124cffFF0000"
local greyText = "\124cffAAAAAA"
local closeColorTag = "\124r"

function KVTI:SetupOptions()
    local category, layout = Settings.RegisterVerticalLayoutCategory("Transmog Improvements")
    Settings.RegisterAddOnCategory(category)
    KVTI.settingsCategory = category

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Version: " .. KVTI.version))
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Transmog Menu QoL Improvements"))

    do
        local settingName = "KVTI_AddOutfitNumbers"
        local savedVarsKey = settingName
        local settingLabel = "Outfit Numbers"
        local settingType = "boolean"
        local settingTooltip = "Add index numbers to Outfits in the Transmog Menu.\n\n" .. greyText .. "Note: These are NOT internal Outfit IDs!" .. closeColorTag
        local defaultValue = true
        local setting = createSetting(category, settingType, settingName, savedVarsKey, settingLabel, defaultValue)
        Settings.CreateCheckbox(category, setting, settingTooltip)
    end

    do
        local settingName = "KVTI_DoIconSuggestions"
        local savedVarsKey = settingName
        local settingLabel = "Suggest Icons from Appearances"
        local settingType = "boolean"
        local settingTooltip = "When (re)naming an outfit: Adds a small window with icons of the gear appearances in the outfit.\n\nYou can click them to choose their icon as the icon of the outfit before saving."
        local defaultValue = true
        local setting = createSetting(category, settingType, settingName, savedVarsKey, settingLabel, defaultValue)
        Settings.CreateCheckbox(category, setting, settingTooltip)

    end

    do
        local settingName = "KVTI_CloseTransmogWithEsc"
        local savedVarsKey = settingName
        local settingLabel = "Close Transmog Menu with ESC"
        local settingType = "boolean"
        local settingTooltip = "When enabled, pressing ESC/Escape will close the Transmog menu.\n\n" .. redText .. "Note: Your UI must reload (or log in/out) for this setting to take effect." .. closeColorTag
        local defaultValue = false
        local setting = createSetting(category, settingType, settingName, savedVarsKey, settingLabel, defaultValue)
        Settings.CreateCheckbox(category, setting, settingTooltip)
    end

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Transmog Menu Button"))

    do
        local settingName = "KVTI_TransmogButton_Main_Enabled"
        local settingLabel = "Transmog Button Enabled"
        local settingTooltip = "When enabled, a button will be shown in your UI that can be clicked to open the Transmog Menu"
        local defaultValue = true
        local setting = Settings.RegisterProxySetting(
            category, settingName, "boolean", settingLabel, defaultValue,
            function()
                return getSavedVarForButton("KVTI_TransmogButton_Main", "enabled", defaultValue)
            end,
            function(newValue)
                KVTI:GetButton("KVTI_TransmogButton_Main"):ToggleCallback(newValue)
            end
        )
        Settings.CreateCheckbox(category, setting, settingTooltip)
    end

    local buttonPositionSlider_default = 0
    local buttonPositionSlider_max = 2000
    local buttonPositionSlider_step = 1
    do
        local setting = Settings.RegisterProxySetting(
            category,
            "KVTI_TransmogButton_Main_X",
            "number",
            "Transmog Button X Position",
            buttonPositionSlider_default,
            function()
                return getSavedVarForButton("KVTI_TransmogButton_Main", "x", buttonPositionSlider_default)
            end,
            function(newValue)
                -- anchor1, anchor2, anchorFrame, x, y, size, moveAfter
                KVTI:GetButton("KVTI_TransmogButton_Main"):NewPositionCallback(nil, nil, nil, newValue, nil, nil, true)
            end
        )
        local tooltip = "X (left/right) position of Transmog Button\n\n" .. greyText .. "Note: You can also just click-and-drag the button to position it" .. closeColorTag
        local options = Settings.CreateSliderOptions(-buttonPositionSlider_max, buttonPositionSlider_max, buttonPositionSlider_step)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right);
        Settings.CreateSlider(category, setting, options, tooltip)
    end

    do
        local setting = Settings.RegisterProxySetting(
            category,
            "KVTI_TransmogButton_Main_Y",
            "number",
            "Transmog Button Y Position",
            buttonPositionSlider_default,
            function()
                return getSavedVarForButton("KVTI_TransmogButton_Main", "y", buttonPositionSlider_default)
            end,
            function(newValue)
                local btn = KVTI:GetButton("KVTI_TransmogButton_Main")
                -- anchor1, anchor2, anchorFrame, x, y, size, moveAfter
                btn:NewPositionCallback(nil, nil, nil, nil, newValue, nil, true)
            end
        )
        local tooltip = "Y (left/right) position of Transmog Button\n\n" .. greyText .. "Note: You can also just click-and-drag the button to position it" .. closeColorTag
        local options = Settings.CreateSliderOptions(-buttonPositionSlider_max, buttonPositionSlider_max, buttonPositionSlider_step)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right);
        Settings.CreateSlider(category, setting, options, tooltip)
    end


    local alphaSlider_max = 1.0
    local alphaSlider_min = 0.0
    local alphaSlider_step = 0.05
    do
        local settingName = "KVTI_TransmogButton_Main_FadeAlpha"
        local settingLabel = "Transmog Button Faded Opacity"
        local settingTooltip = "Sets the opacity that the main button will fade to when you're not mousing over it."
        local settingType = "number"
        local defaultValue = 0.5
        local savedVarsKey = "fadeAlpha"
        local setting = Settings.RegisterProxySetting(
            category, settingName, settingType, settingLabel, defaultValue,
            function()
                return getSavedVarForButton("KVTI_TransmogButton_Main", savedVarsKey, defaultValue)
            end,
            function(newValue)
                setSavedVarForButton("KVTI_TransmogButton_Main", savedVarsKey, newValue)
                local btn = KVTI:GetButton("KVTI_TransmogButton_Main")
                if btn then
                    btn:AlphaCallback(newValue)
                end
            end
        )
        local options = Settings.CreateSliderOptions(alphaSlider_min, alphaSlider_max, alphaSlider_step)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value) return (RoundToSignificantDigits(value, 2) * 100) .. "%" end);
        Settings.CreateSlider(category, setting, options, settingTooltip)
    end

    do
        local settingName = "KVTI_ClearButton_Enabled"
        local savedVarsKey = settingName
        local settingLabel = "Clear Transmog Button"
        local settingTooltip = "When enabled, a button will be shown with the outfit bar (near the Transmog Menu button) that you can use to clear all current transmog appearances."
        local defaultValue = true
        local setting = Settings.RegisterProxySetting(
            category, settingName, "boolean", settingLabel, defaultValue,
            function()
                return getGlobalSavedVar(savedVarsKey, defaultValue)
            end,
            function(newValue)
                setGlobalSavedVar(savedVarsKey, newValue)
                local clearBtn = KVTI:GetButton("KVTI_OutfitButton_Clear")
                if clearBtn then
                    clearBtn:Toggle(newValue)
                end
            end
        )
        Settings.CreateCheckbox(category, setting, settingTooltip)
    end

end
