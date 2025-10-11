
if cm_thinker == nil then
    cm_thinker = class({})
end

function ApplyCMThinker(cm_entity)
   cm_entity:AddNewModifier(cm_entity, nil, "cm_thinker", {})
end

-- don't show the modifier on the character
function cm_thinker:IsHidden()
    return true
end
-- set up the thinker
function cm_thinker:OnCreated(kv)
   if IsServer() then
    -- inherited from Buff 
    self:StartIntervalThink(1.0)
   end
end
-- make sure it doesn't get turned off
function cm_thinker:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function cm_thinker:OnIntervalThink()
    self:cm_think(self:GetParent())
end

local function handleCMAgression(hero, target)
    if hero:GetTeamNumber() ~= target:GetTeamNumber() then
        local nova_ability = GetAbility(hero, 0)
        TryToCastAbility(hero, target, nova_ability)
        local freeze_ability = GetAbility(hero, 1)
        TryToCastAbility(hero, target, freeze_ability)
    end
    return false
end

function cm_thinker:cm_think(cm_entity)
    cm_entity.current_position = cm_entity:GetOrigin()
    cm_entity.target = cm_entity:GetAggroTarget()
    local target = cm_entity:GetAggroTarget()
    if target ~= nil and target:IsAlive() then
        cm_entity.isAggrod = true
    else
        cm_entity.isAggrod = false
    end
    if cm_entity.isAggrod then
        AttackAi(cm_entity, {target}, handleCMAgression)
        return 1
    end
    local targets = FindEnemyTargets(cm_entity, cm_entity:GetCurrentVisionRange(), nil)
    if AttackAi(cm_entity, targets, handleCMAgression) then
        return 1
    end
    -- If we are already on our way somewhere, keep going because we haven't been aggroed at this point 
    if cm_entity.next_position ~= nil and cm_entity.current_position ~= cm_entity.next_position and Pathable(cm_entity.current_position, cm_entity.next_position) then
        cm_entity:MoveToPosition(cm_entity.next_position)
        return 1
    end
    MoveToNewRandomLocation(cm_entity)
    return 1
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