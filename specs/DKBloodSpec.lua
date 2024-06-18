-- Modules/DKBloodSpec.lua

local addonName, addonTable = ...

addonTable.DKBloodSpec = addonTable.DKBloodSpec or {}

local DKBloodSpec = addonTable.DKBloodSpec

function DKBloodSpec.Initialize()
    print("DKBloodSpec initialized")
    
    if addonTable.FrameHandler and addonTable.FrameHandler.UpdateSpecText then
        addonTable.FrameHandler.UpdateSpecText("DK Blood", {r = 0, g = 1, b = 0})
    end
    
    local frame = CreateFrame("Frame", "DKAbilityHelperFrame", UIParent)
    frame:SetSize(25, 25)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -10)

    frame.icon = frame:CreateTexture(nil, "BACKGROUND")
    frame.icon:SetAllPoints(true)

    frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("UNIT_AURA")
    frame:RegisterEvent("RUNE_POWER_UPDATE")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_LOGIN")

    local function GetNumEnemiesWithinRange(range)
        local count = 0
        for i = 1, 40 do
            local unit = "nameplate" .. i
            if UnitExists(unit) and UnitCanAttack("player", unit) and IsItemInRange(37727, unit) then
                count = count + 1
            end
        end
        return count
    end

    local function AreBloodRunesAvailable()
        return GetRuneCooldown(1) == 0 or GetRuneCooldown(2) == 0
    end

    local function AreUnholyRunesAvailable()
        return GetRuneCooldown(3) == 0 or GetRuneCooldown(4) == 0
    end

    local function AreDeathRunesAvailable()
        return GetRuneCooldown(5) == 0 or GetRuneCooldown(6) == 0
    end

    local function HasCooldown(spellId)
        local start, duration, enabled = GetSpellCooldown(spellId)
        return start > 0 and duration > 1.5
    end

    local function HasFrostFever(unit)
        for i = 1, 40 do
            local name, _, _, _, _, _, _, _, _, spellId = UnitAura(unit, i, "HARMFUL")
            if name and spellId == 55095 then -- Frost Fever's spell ID is 55095
                return true
            end
        end
        return false
    end

    local function HasBloodPlague(unit)
        for i = 1, 40 do
            local name, _, _, _, _, _, _, _, _, spellId = UnitAura(unit, i, "HARMFUL")
            if name and spellId == 55078 then -- Blood Plague's spell ID is 55078
                return true
            end
        end
        return false
    end

    -- New function to check if an ability is usable (no cooldown)
    local function IsAbilityUsable(spellId)
        return not HasCooldown(spellId)
    end

    local abilities = {
        ["Mind Freeze"] = { spellId = 47528, color = { r = 1, g = 0, b = 0 }, priority = 1, condition = function()
            local target = "target"
            if UnitExists(target) and UnitCanAttack("player", target) and not UnitIsDead(target) then
                local casting = UnitCastingInfo(target)
                local channeling = UnitChannelInfo(target)
                return (casting or channeling) and IsAbilityUsable(47528) and UnitPower("player") >= 20
            end
            return false
        end },
        ["Rune Tap"] = { spellId = 48982, color = { r = 0, g = 1, b = 0 }, priority = 2, condition = function()
            local target = "target"
            return UnitExists(target) and (UnitHealth("player") / UnitHealthMax("player") < 0.30 or AuraUtil.FindAuraByName("Will of the Necropolis", "player")) and IsAbilityUsable(48982)
        end },
        ["Icebound Fortitude"] = { spellId = 48792, color = { r = 0, g = 0, b = 1 }, priority = 3, condition = function()
            local target = "target"
            return UnitExists(target) and UnitHealth("player") / UnitHealthMax("player") < 0.30 and IsAbilityUsable(48792)
        end },
        ["Vampiric Blood"] = { spellId = 55233, color = { r = 0.5, g = 0, b = 0.5 }, priority = 4, condition = function()
            local target = "target"
            return UnitExists(target) and UnitHealth("player") / UnitHealthMax("player") < 0.25 and IsAbilityUsable(55233)
        end },
        ["Raise Dead"] = { spellId = 46584, color = { r = 1, g = 1, b = 0 }, priority = 5, condition = function()
            local target = "target"
            return UnitExists(target) and UnitHealth("player") / UnitHealthMax("player") < 0.40 and IsAbilityUsable(46584)
        end },
        ["Death Pact"] = { spellId = 48743, color = { r = 1, g = 0, b = 1 }, priority = 6, condition = function()
            local target = "target"
            return UnitExists(target) and UnitHealth("player") / UnitHealthMax("player") < 0.40 and UnitExists("pet") and IsAbilityUsable(48743)
        end },
        ["Horn of Winter"] = { spellId = 57330, color = { r = 0, g = 1, b = 1 }, priority = 7, condition = function()
            local target = "target"
            return UnitExists(target) and not AuraUtil.FindAuraByName("Horn of Winter", "player") and IsAbilityUsable(57330)
        end },
        ["Bone Shield"] = { spellId = 49222, color = { r = 0.5, g = 0.5, b = 0.5 }, priority = 8, condition = function()
            local target = "target"
            return UnitExists(target) and not AuraUtil.FindAuraByName("Bone Shield", "player") and IsAbilityUsable(49222)
        end },
        ["Death and Decay"] = { spellId = 43265, color = { r = 0.7, g = 0.7, b = 0.7 }, priority = 9, condition = function()
            local enemies = GetNumEnemiesWithinRange(10)
            local target = "target"
            return UnitExists(target) and enemies >= 2 and (AreUnholyRunesAvailable() or AreDeathRunesAvailable()) and IsAbilityUsable(43265)
        end },
        ["Dancing Rune Weapon"] = { spellId = 49028, color = { r = 0.3, g = 0.3, b = 0.3 }, priority = 10, condition = function()
            local target = "target"
            return UnitExists(target) and UnitPower("player") >= 60 and IsAbilityUsable(49028)
        end },
        ["Rune Strike"] = { spellId = 56815, color = { r = 0.8, g = 0.8, b = 0.8 }, priority = 11, condition = function()
            local target = "target"
            return UnitExists(target) and UnitPower("player") >= 30 and IsAbilityUsable(56815)
        end },
        ["Icy Touch"] = { spellId = 45477, color = { r = 0.2, g = 0.2, b = 0.2 }, priority = 12, condition = function()
            local target = "target"
            if UnitExists(target) then
                return not HasFrostFever(target) and IsAbilityUsable(45477)
            end
            return false
        end },
        ["Plague Strike"] = { spellId = 45462, color = { r = 0.4, g = 0.4, b = 0.4 }, priority = 13, condition = function()
            local target = "target"
            if UnitExists(target) then
                return not HasBloodPlague(target) and IsAbilityUsable(45462)
            end
            return false
        end },
        ["Blood Boil"] = { spellId = 48721, color = { r = 1, g = 0.5, b = 0 }, priority = 14, condition = function()
            local enemies = GetNumEnemiesWithinRange(10)
            local target = "target"
            if UnitExists(target) then
                if AuraUtil.FindAuraByName("Crimson Scourge", "player") then
                    return enemies >= 1 and IsAbilityUsable(48721)
                else
                    return enemies >= 4 and AreBloodRunesAvailable() and IsAbilityUsable(48721)
                end
            end
            return false
        end },
        ["Heart Strike"] = { spellId = 55050, color = { r = 0.5, g = 0, b = 0 }, priority = 15, condition = function()
            local enemies = GetNumEnemiesWithinRange(10)
            local target = "target"
            return UnitExists(target) and enemies <= 3 and AreBloodRunesAvailable() and IsAbilityUsable(55050)
        end },
        ["Pestilence"] = { spellId = 50842, color = { r = 0.3, g = 0.3, b = 0.3 }, priority = 16, condition = function()
            local target = "target"
            return UnitExists(target) and HasFrostFever("target") and AuraUtil.FindAuraByName("Blood Plague", "target") and IsAbilityUsable(50842)
        end },
        ["Death Strike"] = { spellId = 49998, color = { r = 0.1, g = 0.1, b = 0.1 }, priority = 17, condition = function()
            local target = "target"
            return UnitExists(target) and IsUsableSpell(49998) and IsAbilityUsable(49998)
        end },
    }

    local function UpdateAbilityIcon()
        if not UnitAffectingCombat("player") then
            frame.icon:SetColorTexture(0, 0, 0, 1) -- Set the icon to black if not in combat
            if addonTable.FrameHandler and addonTable.FrameHandler.UpdateDebugText then
                addonTable.FrameHandler.UpdateDebugText("") -- Clear debug text when not in combat
            end
            return
        end

        local highestPriority = 99
        local selectedAbility = nil
        local selectedColor = { r = 0, g = 0, b = 0 } -- Default to black

        for name, ability in pairs(abilities) do
            if ability.condition() and ability.priority < highestPriority then
                highestPriority = ability.priority
                selectedAbility = name
                selectedColor = ability.color
            end
        end

        frame.icon:SetColorTexture(selectedColor.r, selectedColor.g, selectedColor.b, 1)
        
        if addonTable.debugMode and selectedAbility then
            if addonTable.FrameHandler and addonTable.FrameHandler.UpdateDebugText then
                addonTable.FrameHandler.UpdateDebugText(selectedAbility)
            end
        else
            if addonTable.FrameHandler and addonTable.FrameHandler.UpdateDebugText then
                addonTable.FrameHandler.UpdateDebugText("")
            end
        end
    end

    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" or event == "PLAYER_TARGET_CHANGED" or event == "UNIT_AURA" or event == "RUNE_POWER_UPDATE" or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
            UpdateAbilityIcon()
        elseif event == "PLAYER_LOGIN" then
            UpdateAbilityIcon()
        end
    end)
end

function DKBloodSpec.Unload()
    print("DKBloodSpec unloaded")
    -- Lägg till den funktionalitet du behöver för att rensa upp här
    if addonTable.FrameHandler and addonTable.FrameHandler.UpdateSpecText then
        addonTable.FrameHandler.UpdateSpecText("Choose Spec.", {r = 1, g = 0, b = 0})
    end
end
