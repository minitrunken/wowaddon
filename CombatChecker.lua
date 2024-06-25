-- Create the frame
local frame = CreateFrame("Frame", "CombatSquareFrame", UIParent)
frame:SetSize(15, 15)
frame:SetPoint("LEFT", UIParent, "LEFT", 10, 0)  -- Placerar rutan till vänster med en marginal på 10 pixlar från vänsterkanten
frame.texture = frame:CreateTexture(nil, "BACKGROUND")
frame.texture:SetAllPoints(frame)
frame.texture:SetColorTexture(1, 0.07, 0.58, 1)  -- Initial color: neon pink (0xFF1294)

-- Event handler function
local function UpdateFrameColor()
    if InCombatLockdown() then
        -- In combat
        if UnitExists("target") then
            frame.texture:SetColorTexture(0, 1, 0, 1)  -- Grön (0x00FF00)
        else
            frame.texture:SetColorTexture(1, 0, 0, 1)  -- Röd (0xFF0000)
        end
    else
        -- Out of combat
        if UnitExists("target") then
            frame.texture:SetColorTexture(1, 1, 0, 1)  -- Gul (0xFFFF00)
        else
            frame.texture:SetColorTexture(1, 0.07, 0.58, 1)  -- Neon pink (0xFF1294)
        end
    end
end

-- Register events
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")

-- Set script to handle events
frame:SetScript("OnEvent", UpdateFrameColor)

-- Initial color update
UpdateFrameColor()
