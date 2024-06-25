local frame = CreateFrame("Frame")

-- Define the error messages to ignore and change color, and optionally replace text
local ignoreErrorListMessages = {
    ["Not enough runic power"] = {r = 0.5, g = 0.0, b = 0.5, newText = "You need more runic power!"}, -- Purple
    ["There is nothing to attack."] = {r = 1.0, g = 1.0, b = 0.0, newText = "No target to attack!"}, -- Yellow
    ["Target needs to be in front of you."] = {r = 0.0, g = 1.0, b = 0.0, newText = "Your target must be in front!"}, -- Green
    ["You are facing the wrong way!"] = {r = 0.0, g = 1.0, b = 0.0, newText = "Turn around!"}, -- Green
    ["Ability is not ready yet."] = {r = 0.0, g = 1.0, b = 1.0, newText = "Ability is on cooldown!"}, -- Turquoise
    ["You are too far away!"] = {r = 1.0, g = 0.5, b = 0.0, newText = "Move closer!"}, -- Orange
    ["Out of range."] = {r = 0.0, g = 0.5, b = 0.0, newText = "Target is too far!"} -- Dark Green
}

-- Create a new frame for the color-changing box
local colorBox = CreateFrame("Frame", nil, UIParent)
colorBox:SetSize(25, 25)
colorBox:SetPoint("TOP", UIParent, "TOP", 150, -10)
colorBox.texture = colorBox:CreateTexture(nil, "BACKGROUND")
colorBox.texture:SetAllPoints(colorBox)
colorBox.texture:SetColorTexture(0, 0, 0) -- Default to black

-- Create a new frame to anchor UIErrorsFrame to
local errorFrameAnchor = CreateFrame("Frame", nil, UIParent)
errorFrameAnchor:SetSize(50, 50) -- You can adjust the size
errorFrameAnchor:SetPoint("CENTER", UIParent, "CENTER") -- Center the error messages
UIErrorsFrame:ClearAllPoints()
UIErrorsFrame:SetPoint("CENTER", errorFrameAnchor, "CENTER")

-- Function to reset the color box to black after a delay
local function ResetColorBox()
    colorBox.texture:SetColorTexture(0, 0, 0)
end

-- Function to handle UI error messages
local function OnUIErrorMessage(_, _, message)
    if ignoreErrorListMessages[message] then
        local config = ignoreErrorListMessages[message]
        local displayText = config.newText or message
        UIErrorsFrame:Clear() -- Clear existing errors to prevent duplicates
        UIErrorsFrame:AddMessage(displayText, config.r, config.g, config.b) -- show message in defined color
        
        -- Change the color of the color box
        colorBox.texture:SetColorTexture(config.r, config.g, config.b)
        
        -- Reset the color box to black after 3 seconds
        C_Timer.After(3, ResetColorBox)
        return
    end

    -- Handle other messages normally
    UIErrorsFrame:AddMessage(message, 1.0, 0.0, 0.0) -- default red color for unknown messages
    
    -- Reset the color box to black after 3 seconds for unknown messages
    C_Timer.After(3, ResetColorBox)
end

-- Register the event and set the script
frame:RegisterEvent("UI_ERROR_MESSAGE")
frame:SetScript("OnEvent", function(self, event, errorType, message)
    if message then
        OnUIErrorMessage(self, event, message)
    else
        print("No message received in UI_ERROR_MESSAGE event.")
    end
end)