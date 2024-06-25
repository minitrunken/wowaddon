local function SetRaidMarker(target, marker)
    local index = GetRaidTargetIndex(target)
    if not index then
        C_Timer.After(0.0, function() 
            if UnitExists(target) and not UnitIsDead(target) and UnitCanAttack("player", target) then
                SetRaidTarget(target, marker)
            end
        end)
    else
    end
end

local function MaintainRaidMarker()
    local target = "target"
    if UnitExists(target) and not UnitIsDead(target) and UnitCanAttack("player", target) then
        local index = GetRaidTargetIndex(target)
        if not index then
            SetRaidMarker(target, 3)  -- Sätter raid marker 7 (röd krysset) på målet
        else
            print("Target already has a raid marker.")
        end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_TARGET_CHANGED" or event == "UPDATE_MOUSEOVER_UNIT" then
        MaintainRaidMarker()
    end
end)

print("AutoRaidMarker loaded.")
