
CUSTOM_GAME_SETUP_TIME = 1.0      -- How long should custom game setup last - the screen where players pick a team?
STRATEGY_TIME = 0.0               -- How long should strategy time last? Bug: You can buy items during strategy time and it will not be spent!
SHOWCASE_TIME = 0.0               -- How long should show case time be?
DEV_MODE = 1
REQUIRED_PUDGE_COUNT = 2
REQUIRED_CM_COUNT = 10

-- iirc the 2 zeros are talent related 
PUDGE_ABILITIES = {4, 4, 4, 0, 0, 3}
function SetPudgeAbilities(hero)
    for index, level in ipairs(PUDGE_ABILITIES) do
        local ability = hero:GetAbilityByIndex(index-1)
        DebugPrint("ability ", ability:GetName())
        for _ = 0, level-1 do
            if ability:CanAbilityBeUpgraded() then
                hero:UpgradeAbility(ability)
            end
        end
    end
end

function GetAbility(hero, index)
    local ability = hero:GetAbilityByIndex(index)
    return ability
end


CM_ABILITIES = {1, 1, 1}
function SetCMAbilities(hero)
    for index, level in ipairs(CM_ABILITIES) do
        local ability = hero:GetAbilityByIndex(index-1)
        DebugPrint("ability ", ability:GetName())
        for _ = 0, level-1 do
            if ability:CanAbilityBeUpgraded() then
                hero:UpgradeAbility(ability)
            end
        end
    end
end