function GetAbility(hero, index)
    local ability = hero:GetAbilityByIndex(index)
    return ability
end

function LevelHeroTo(hero, targetLevel)
    if not IsValidEntity(hero) then return end
    local current = hero:GetLevel() or 0
    if targetLevel <= current then return end
    for i = 1, (targetLevel - current) do
        hero:HeroLevelUp(false)
    end
end

function GiveItemSafe(hero, itemName)
    if not IsValidEntity(hero) then return false end
    local ok, err = pcall(function() hero:AddItemByName(itemName) end)
    if not ok then
        print("[HIDEANDHEAP] GiveItemSafe failed for item:", itemName, "err:", err)
        return false
    end
    return true
end

-----------------------------------------------------
-- Hero Initialization -- LEVELS, GOLD, ITEMS, ETC
-----------------------------------------------------
function InitializeHero(hero)
    if not IsValidEntity(hero) then return end
    if hero._hideAndHeapInit then return end
    hero._hideAndHeapInit = true

    local playerID = hero:GetPlayerOwnerID()
    local team = hero:GetTeamNumber()
    if DEV_MODE then
        hero:SetDayTimeVisionRange(DEV_MODE_CM_VISION)
        hero:SetNightTimeVisionRange(DEV_MODE_CM_VISION)
    end

    if team == DOTA_TEAM_GOODGUYS then -- CM Levels, Gold, & Items
        LevelHeroTo(hero, CM_STARTING_LEVEL)
        if playerID == nil or playerID < 0 then
            SetCMAbilities(hero)
        else
            --hero:SetAbsOrigin(GenerateRandomUnitLocation(CM_STARTING_DISTANCE_FROM_CENTER))
            PlayerResource:SetGold(playerID, CM_STARTING_GOLD, false)
        end
        GiveItemSafe(hero, "item_tranquil_boots")
        GiveItemSafe(hero, "item_ward_observer")
        GiveItemSafe(hero, "item_ward_sentry")
        GiveItemSafe(hero, "item_wind_lace")
        GiveItemSafe(hero, "item_hurricane_pike")
        GiveItemSafe(hero, "item_quelling_blade")
        pcall(function() GiveItemSafe(hero, "item_pogo_stick") end)
        GiveItemSafe(hero, "item_aghanims_shard")
    elseif team == DOTA_TEAM_BADGUYS then -- Pudge Levels, Gold, & Items
        LevelHeroTo(hero, PUDGE_STARTING_LEVEL)
        if playerID == nil or playerID < 0 then
            SetPudgeAbilities(hero)
        else
            PlayerResource:SetGold(playerID, PUDGE_STARTING_GOLD, false)
        end
		GiveItemSafe(hero, "item_aether_lens")
        GiveItemSafe(hero, "item_octarine_core")
        GiveItemSafe(hero, "item_ward_observer")
        GiveItemSafe(hero, "item_ward_observer")
        GiveItemSafe(hero, "item_ward_sentry")
		GiveItemSafe(hero, "item_boots")
        pcall(function() GiveItemSafe(hero, "item_smoke_of_deceit") end)
        pcall(function() GiveItemSafe(hero, "item_blood_grenade") end)
        pcall(function() GiveItemSafe(hero, "item_spider_legs") end)
        GiveItemSafe(hero, "item_aghanims_shard")
    end
end

function FindEnemyTargets(unit, radius, ability)
    local team = unit:GetTeamNumber()
    local current_position = unit:GetOrigin()
    local r = radius
    if ability ~= nil then
        r = ability:GetAOERadius()
    end
    local enemies = FindUnitsInRadius(team, current_position, nil, r, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_CAN_BE_SEEN, 0, true)
    return enemies
end

function GetHealthPercentage(hero)
    local max_health = hero:GetMaxHealth()
    local current_health = hero:GetHealth()
    current_health = current_health / max_health
    print("health percentage ", current_health*100)
    return current_health *100
end