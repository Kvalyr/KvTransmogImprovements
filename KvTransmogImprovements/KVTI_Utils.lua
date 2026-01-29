local addon, ns = ...
local i, _

local utils = {}
ns.KVTI_Utils = utils
-- ----------------------------------------------------------------------------------------------------------------


function utils.versionStringToNumber(v)
    local major, minor, build = v:match("(%d+)%.(%d+)%.(%d+)")
    return (major * 65536) + (minor * 256) + (build * 1)
end


function utils.numberToVersion(n)
    local major = math.floor(n / 65536)
    local minor = math.floor((n % 65536) / 256)
    local build = n % 256
    return string.format("%d.%d.%d", major, minor, build)
end


function utils.setupButtonProxy(secureButton, targetFrame)
    -- Sets attributes on a SecureActionButton to make it a proxy to click another secure frame
	secureButton:EnableMouse(true)
	secureButton:RegisterForClicks("AnyUp", "AnyDown")
	-- TODO: Make this left click only so that other functions can be assigned to other types
	secureButton:SetAttribute("type", "click")
	secureButton:SetAttribute("clickbutton", targetFrame)
end
