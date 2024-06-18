local addonName, addonTable = ...

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

local abilities = {
    ["Mind Freeze"] = { spellId = 47528, color = { r = 1, g = 0, b = 0 }, priority = 1, condition = function()
        local target = "target"
        if UnitExists(target) and UnitCanAttack("player", target) and not UnitIsDead(target) then
            local casting = UnitCastingInfo(target)
            local channeling = UnitChannelInfo(target)
            return casting or channeling
        end
        return false
    end },
    ["Rune Tap"] = { spellId = 48982, color = { r = 0, g = 1, b = 0 }, priority = 2, condition = function()
        return UnitHealth("player") / UnitHealthMax("player") < 0.30 or AuraUtil.FindAuraByName("Will of the Necropolis", "player")
    end },
    ["Icebound Fortitude"] = { spellId = 48792, color = { r = 0, g = 0, b = 1 }, priority = 3, condition = function()
        return UnitHealth("player") / UnitHealthMax("player") < 0.30
    end },
    ["Vampiric Blood"] = { spellId = 55233, color = { r = 0.5, g = 0, b = 0.5 }, priority = 4, condition = function()
        return UnitHealth("player") / UnitHealthMax("player") < 0.25
    end },
    ["Raise Dead"] = { spellId = 46584, color = { r = 1, g = 1, b = 0 }, priority = 5, condition = function()
        return UnitHealth("player") / UnitHealthMax("player") < 0.40
    end },
    ["Death Pact"] = { spellId = 48743, color = { r = 1, g = 0, b = 1 }, priority = 6, condition = function()
        return UnitHealth("player") / UnitHealthMax("player") < 0.40 and UnitExists("pet")
    end },
    ["Horn of Winter"] = { spellId = 57330, color = { r = 0, g = 1, b = 1 }, priority = 7, condition = function()
        return not AuraUtil.FindAuraByName("Horn of Winter", "player")
    end },
    ["Bone Shield"] = { spellId = 49222, color = { r = 0.5, g = 0.5, b = 0.5 }, priority = 8, condition = function()
        return not AuraUtil.FindAuraByName("Bone Shield", "player")
    end },
    ["Dancing Rune Weapon"] = { spellId = 49028, color = { r = 0.3, g = 0.3, b = 0.3 }, priority = 9, condition = function()
        return UnitPower("player") >= 60
    end },
    ["Rune Strike"] = { spellId = 56815, color = { r = 0.8, g = 0.8, b = 0.8 }, priority = 10, condition = function()
        return UnitPower("player") >= 30
    end },
    ["Icy Touch"] = { spellId = 45477, color = { r = 0.2, g = 0.2, b = 0.2 }, priority = 11, condition = function()
        local target = "target"
        if UnitExists(target) then
            return not HasFrostFever(target) and not HasCooldown(45477)
        end
        return false
    end },
    ["Plague Strike"] = { spellId = 45462, color = { r = 0.4, g = 0.4, b = 0.4 }, priority = 12, condition = function()
        local target = "target"
        if UnitExists(target) then
            return not HasBloodPlague(target) and not HasCooldown(45462)
        end
        return false
    end },
    ["Blood Boil"] = { spellId = 48721, color = { r = 1, g = 0.5, b = 0 }, priority = 13, condition = function()
        local enemies = GetNumEnemiesWithinRange(10)
        if AuraUtil.FindAuraByName("Crimson Scourge", "player") then
            return enemies >= 1 and not HasCooldown(48721)
        else
            return enemies >= 4 and AreBloodRunesAvailable() and not HasCooldown(48721)
        end
    end },
    ["Heart Strike"] = { spellId = 55050, color = { r = 0.5, g = 0, b = 0 }, priority = 14, condition = function()
        local enemies = GetNumEnemiesWithinRange(10)
        return enemies <= 3 and AreBloodRunesAvailable() and not HasCooldown(55050)
    end },
    ["Pestilence"] = { spellId = 50842, color = { r = 0.3, g = 0.3, b = 0.3 }, priority = 15, condition = function()
        return HasFrostFever("target") and AuraUtil.FindAuraByName("Blood Plague", "target") and not HasCooldown(50842)
    end },
    ["Death Strike"] = { spellId = 49998, color = { r = 0.1, g = 0.1, b = 0.1 }, priority = 16, condition = function()
        return IsUsableSpell(49998) and not HasCooldown(49998)
    end },
    ["Death and Decay"] = { spellId = 43265, color = { r = 0.7, g = 0.7, b = 0.7 }, priority = 17, condition = function()
        local enemies = GetNumEnemiesWithinRange(10)
        return enemies >= 2 and (AreUnholyRunesAvailable() or AreDeathRunesAvailable()) and not HasCooldown(43265)
    end },
}

local function UpdateAbilityIcon()
    if not UnitAffectingCombat("player") then
        frame.icon:SetColorTexture(0, 0, 0, 1) -- Set the icon to black if not in combat
        return
    end

    local highestPriority = 99
    local selectedColor = { r = 0, g = 0, b = 0 } -- Default to black

    for name, ability in pairs(abilities) do
        if ability.condition() and ability.priority < highestPriority then
            highestPriority = ability.priority
            selectedColor = ability.color
        end
    end

    frame.icon:SetColorTexture(selectedColor.r, selectedColor.g, selectedColor.b, 1)
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" or event == "PLAYER_TARGET_CHANGED" or event == "UNIT_AURA" or event == "RUNE_POWER_UPDATE" or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        UpdateAbilityIcon()
    elseif event == "PLAYER_LOGIN" then
        UpdateAbilityIcon()
    end
end)
