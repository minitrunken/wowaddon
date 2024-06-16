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
    ["Mind Freeze"] = { spellId = 47528, icon = GetSpellTexture(47528), condition = function()
        local target = "target"
        if UnitExists(target) and UnitCanAttack("player", target) and not UnitIsDead(target) then
            local casting = UnitCastingInfo(target)
            local channeling = UnitChannelInfo(target)
            return casting or channeling
        end
        return false
    end, priority = 1 },
    ["Rune Tap"] = { spellId = 48982, icon = GetSpellTexture(48982), condition = function()
        return UnitHealth("player") / UnitHealthMax("player") < 0.30 or AuraUtil.FindAuraByName("Will of the Necropolis", "player")
    end, priority = 2 },
    ["Icebound Fortitude"] = { spellId = 48792, icon = GetSpellTexture(48792), condition = function()
        return UnitHealth("player") / UnitHealthMax("player") < 0.30
    end, priority = 3 },
    ["Vampiric Blood"] = { spellId = 55233, icon = GetSpellTexture(55233), condition = function()
        return UnitHealth("player") / UnitHealthMax("player") < 0.25
    end, priority = 4 },
    ["Raise Dead"] = { spellId = 46584, icon = GetSpellTexture(46584), condition = function()
        return UnitHealth("player") / UnitHealthMax("player") < 0.40
    end, priority = 5 },
    ["Death Pact"] = { spellId = 48743, icon = GetSpellTexture(48743), condition = function()
        return UnitHealth("player") / UnitHealthMax("player") < 0.40 and UnitExists("pet")
    end, priority = 6 },
    ["Horn of Winter"] = { spellId = 57330, icon = GetSpellTexture(57330), condition = function()
        return not AuraUtil.FindAuraByName("Horn of Winter", "player")
    end, priority = 7 },
    ["Bone Shield"] = { spellId = 49222, icon = GetSpellTexture(49222), condition = function()
        return not AuraUtil.FindAuraByName("Bone Shield", "player")
    end, priority = 8 },
    ["Dancing Rune Weapon"] = { spellId = 49028, icon = GetSpellTexture(49028), condition = function()
        return UnitPower("player") >= 60
    end, priority = 9 },
    ["Rune Strike"] = { spellId = 56815, icon = GetSpellTexture(56815), condition = function()
        return UnitPower("player") >= 30
    end, priority = 10 },
    ["Icy Touch"] = { spellId = 45477, icon = GetSpellTexture(45477), condition = function()
        local target = "target"
        if UnitExists(target) then
            return not HasFrostFever(target) and not HasCooldown(45477)
        end
        return false
    end, priority = 11 },
    ["Plague Strike"] = { spellId = 45462, icon = GetSpellTexture(45462), condition = function()
        local target = "target"
        if UnitExists(target) then
            return not HasBloodPlague(target) and not HasCooldown(45462)
        end
        return false
    end, priority = 12 },
    ["Blood Boil"] = { spellId = 48721, icon = GetSpellTexture(48721), condition = function()
        local enemies = GetNumEnemiesWithinRange(10)
        if AuraUtil.FindAuraByName("Crimson Scourge", "player") then
            return enemies >= 1 and not HasCooldown(48721)
        else
            return enemies >= 4 and AreBloodRunesAvailable() and not HasCooldown(48721)
        end
    end, priority = 13 },
    ["Heart Strike"] = { spellId = 55050, icon = GetSpellTexture(55050), condition = function()
        local enemies = GetNumEnemiesWithinRange(10)
        return enemies <= 3 and AreBloodRunesAvailable() and not HasCooldown(55050)
    end, priority = 14 },
    ["Pestilence"] = { spellId = 50842, icon = GetSpellTexture(50842), condition = function()
        return HasFrostFever("target") and AuraUtil.FindAuraByName("Blood Plague", "target") and not HasCooldown(50842)
    end, priority = 15 },
    ["Death Strike"] = { spellId = 49998, icon = GetSpellTexture(49998), condition = function()
        return IsUsableSpell(49998) and not HasCooldown(49998)
    end, priority = 16 },
    ["Death and Decay"] = { spellId = 43265, icon = GetSpellTexture(43265), condition = function()
        local enemies = GetNumEnemiesWithinRange(10)
        return enemies >= 2 and (AreUnholyRunesAvailable() or AreDeathRunesAvailable()) and not HasCooldown(43265)
    end, priority = 17 },
}

local function UpdateAbilityIcon()
    if not UnitAffectingCombat("player") then
        frame.icon:SetColorTexture(0, 0, 0, 1) -- Set the icon to black if not in combat
        return
    end

    local highestPriority = 99
    local selectedAbility = nil

    for name, ability in pairs(abilities) do
        if ability.condition() and ability.priority < highestPriority then
            highestPriority = ability.priority
            selectedAbility = ability
        end
    end

    if selectedAbility then
        frame.icon:SetTexture(selectedAbility.icon)
    else
        frame.icon:SetColorTexture(0, 0, 0, 1) -- Set the icon to black if no conditions are met
    end
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        -- Just update the ability icon on any combat log event
        UpdateAbilityIcon()
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Player has entered combat
        UpdateAbilityIcon()
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Player has left combat
        UpdateAbilityIcon()
    elseif event == "PLAYER_LOGIN" then
        -- When the player logs in
        UpdateAbilityIcon()
    end
end)

UpdateAbilityIcon()
