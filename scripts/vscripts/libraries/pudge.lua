--[[
A "thinker" is a funciton that gets run peridically, basically a built in timer.
Here we define a "modifier" (a term given by the api/mod community) class which 
hooks into a set of defined events that are checked for every "think" interval
refs:
https://moddota.com/abilities/lua-modifiers/1
Modifier functions
https://moddota.com/api/#!/vscripts/modifierfunction
Modifier api
https://moddota.com/api/#!/vscripts/CDOTA_Modifier_Lua
https://moddota.com/api/#!/vscripts?search=StartIntervalThink
]]
if pudge_thinker == nil then
    pudge_thinker = class({})
end


function ApplyPudgeThinker(pudge_entity)
   pudge_entity:AddNewModifier(pudge_entity, nil, "pudge_thinker", {})
end

-- don't show the modifier on the character
function pudge_thinker:IsHidden()
    return true
end
-- set up the thinker
function pudge_thinker:OnCreated(kv)
   if IsServer() then
    -- inherited from Buff 
    self:StartIntervalThink(1.0)
    end
end
-- make sure it doesn't get turned off
function pudge_thinker:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

-- Declare events that this modifier applies to
-- function pudge_thinker:DeclareFunctions()
--     local funcs = {
        --  MODIFIER_EVENT_ON_TAKEDAMAGE
--     }
--     return funcs
-- end

-- function pudge_thinker:OnTakeDamage(event_keys)
--     PudgeThinker(self)
-- end

function pudge_thinker:OnIntervalThink()
    self:pudge_think(self:GetParent())
end

local function toggleRot(pudge_entity, target)
    local ability = pudge_entity:GetAbilityByIndex(1)
    local range = tonumber(ability:GetAbilityKeyValues().AbilityCastRangeBuffer)
    local aggro_unit = pudge_entity:GetAggroTarget()
    local target_close = false
    if (aggro_unit == nil or target == nil) and ability:GetToggleState() then
        DebugPrint("turn off rot, no aggro or target")
        pudge_entity:CastAbilityToggle(ability, pudge_entity:GetEntityIndex())
        return
    end
    if aggro_unit ~= nil then
        target_close = pudge_entity:GetRangeToUnit(aggro_unit) <= range
    else
        if target ~= nil and #target > 0 then
            target_close = pudge_entity:GetRangeToUnit(target) <= range
        end
    end
    if target_close and ability:GetToggleState() and GetHealthPercentage(pudge_entity) > 15 then
        print("target is close rot is ", ability:GetToggleState())
        return
    end
    if target_close and not ability:GetToggleState() then
        pudge_entity:CastAbilityToggle(ability, pudge_entity:GetEntityIndex())
        DebugPrint("target is close and rot not toggled rot is ", ability:GetToggleState())
        return
    end
    --[[ 
    Turn it off if no one is near or
    If below 40% toggle off, it will be toggled on if someone is close, leading to 
    a toggle on and off feature so the npc doesn't just burn its health down. 
    ]]-- 
    if ability:GetToggleState() and GetHealthPercentage(pudge_entity) < 40 then
        DebugPrint("below 40% turn off rot")
        pudge_entity:CastAbilityToggle(ability, pudge_entity:GetEntityIndex())
        return
    end
end

local function handlePudgeAgression(hero, target)
    if hero:GetTeamNumber() ~= target:GetTeamNumber() then
        local hook_ability = GetAbility(hero, 0)
        local dismember_ability = GetAbility(hero, 5)
        if hero:IsChanneling() then
            return true
        end
        toggleRot(hero, target)
        TryToCastAbility(hero, target, hook_ability)
        -- Can't have 2 dismembers on at the same time.. fix
        TryToCastAbility(hero, target, dismember_ability)
    end
    return false
end

function pudge_thinker:pudge_think(pudge_entity)
    pudge_entity.current_position = pudge_entity:GetOrigin()
    pudge_entity.target = pudge_entity:GetAggroTarget()
    local target = pudge_entity:GetAggroTarget()
    if target ~= nil and target:IsAlive() then
        pudge_entity.isAggrod = true
    else
        pudge_entity.isAggrod = false
    end
    if pudge_entity.isAggrod then
        AttackAi(pudge_entity, {target}, handlePudgeAgression)
        return 1
    end
    local targets = FindEnemyTargets(pudge_entity, pudge_entity:GetCurrentVisionRange(), nil)
    if AttackAi(pudge_entity, targets, handlePudgeAgression) then
        return 1
    end
    -- If we are already on our way somewhere, keep going because we haven't been aggroed at this point 
    if pudge_entity.next_position ~= nil and pudge_entity.current_position ~= pudge_entity.next_position and Pathable(pudge_entity.current_position, pudge_entity.next_position) then
        pudge_entity:MoveToPosition(pudge_entity.next_position)
        return 1
    end
    toggleRot(pudge_entity, {})
    MoveToNewRandomLocation(pudge_entity)
    return 1
end


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