-- Main.lua

local addonName, addonTable = ...

addonTable.EventHandler = addonTable.EventHandler or {}
addonTable.FrameHandler = addonTable.FrameHandler or {}

local frameHandler = addonTable.FrameHandler

addonTable.autoTauntEnabled = false  -- Initialisera variabeln

-- När addon laddas, initialisera ramhanteraren
local function OnAddonLoaded(event, name)
    if name == addonName then
        print("Initializing frameHandler for " .. addonName)
        frameHandler.Initialize()
    else
        print("Addon name mismatch: expected " .. addonName .. " but got " .. name)
    end
end

-- Registrera event för addon laddad
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        OnAddonLoaded(event, name)
    end
end)

print("Main.lua loaded")
