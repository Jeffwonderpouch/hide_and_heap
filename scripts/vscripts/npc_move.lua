MAP_CENTER = Vector(0,0,0)
math.randomseed(GameRules:GetGameTime())

function FlipCoin(times)
    local tosses = {}
    for _ = 1, times do
        local flip = math.random(1,2)
        if flip == 2 then
            table.insert(tosses,-1)
        else
            table.insert(tosses,1)
        end 
    end
    for k,v in pairs(tosses) do
        DebugPrint("k ", k, "v", v)
    end
    return tosses
end

function GenerateNewPosition(current_position)
    local x_random_distance_change
    local y_random_distance_change
    local pos_neg = FlipCoin(2)
    for i, flip in pairs(pos_neg) do
        if i == 1 then
            x_random_distance_change = normalRandom(1000, 200, flip)
        else
            y_random_distance_change = normalRandom(1000, 200, flip)
        end
    end
    DebugPrint("Current location ", current_position)
    DebugPrint("X change", x_random_distance_change)
    DebugPrint("Y change", y_random_distance_change)
    current_position = current_position:__add(Vector(x_random_distance_change, 0, 0))
    current_position = current_position:__add(Vector(0, y_random_distance_change, 0))
    return current_position
end

function RandomCharMovement(npc_entity)
    local final_location = nil
    Timers:CreateTimer(function()
        local current_position = npc_entity:GetOrigin()
        if current_position ~= final_location and final_location ~= nil and Pathable(current_position, final_location) then
            -- print(GridNav:CanFindPath(current_position, final_location))
            -- print("Continuing travel to ", final_location,"from", current_position)
            npc_entity:MoveToPosition(final_location)
            return 1
        end
        local pathable = false
        local new_position = nil
        while pathable == false do
            new_position = GenerateNewPosition(current_position)
            DebugPrint("New location ", final_location)
            if Pathable(current_position, new_position) then
                npc_entity:MoveToPosition(new_position)
                return 1
            end
        end
        return 0
    end)
end

function Pathable(from, to)
    return GridNav:CanFindPath(from, to)
end

function RandomCharMovementWithAggro(npc_entity)
    if npc_entity.__movement_init == nil then
        npc_entity.__movement_init = true
    else return
    end
    Timers:CreateTimer(function()
        npc_entity.current_position = npc_entity:GetOrigin()
        npc_entity.target = npc_entity:GetAggroTarget()
        local target = npc_entity:GetAggroTarget()
        if target ~= nil and target:IsAlive() then
            npc_entity.isAggrod = true
        else
            npc_entity.isAggrod = false
        end
        if npc_entity.isAggrod then
            AttackAi(npc_entity, {target}, npc_entity.isAggrod)
            return 1
        end
        local targets = FindEnemyTargets(npc_entity, 2000, nil)
        if AttackAi(npc_entity, targets, false) then
            return 1
        end
        if npc_entity.next_position ~= nil and npc_entity.current_position ~= npc_entity.next_position and Pathable(npc_entity.current_position, npc_entity.next_position) then
            npc_entity:MoveToPosition(npc_entity.next_position)
            return 1
        end
        if npc_entity:GetName() == "npc_dota_hero_pudge" then
            ToggleRot(npc_entity, {})
        end
        local x_random_distance_change
        local y_random_distance_change
        local pos_neg = FlipCoin(2)
        for i, flip in pairs(pos_neg) do
            if i == 1 then
                x_random_distance_change = normalRandom(1000, 200, flip)
            else
                y_random_distance_change = normalRandom(1000, 200, flip)
            end
        end
        DebugPrint("Current position ", npc_entity.current_position)
        DebugPrint("X change", x_random_distance_change)
        DebugPrint("Y change", y_random_distance_change)
        local destination = npc_entity.current_position:__add(Vector(x_random_distance_change, 0, 0))
        npc_entity.next_position = destination:__add(Vector(0, y_random_distance_change, 0))
        npc_entity:MoveToPosition(npc_entity.next_position)
        return 1
    end)
end


function GenerateRandomUnitLocation(away_from_center)
    local coins = FlipCoin(2)
    local sd = away_from_center / 6
    x_loc= normalRandom(away_from_center, sd, coins[1])
    y_loc = normalRandom(away_from_center, sd, coins[2])
    local try = true
    while try do
        local loc_vector = Vector(x_loc, y_loc, 128)
        if GridNav:CanFindPath(MAP_CENTER, loc_vector) then
            try = false
        end
    end
    return Vector(x_loc, y_loc, 128)
end

-- start_location and end_location are Vectors
function UnitPartrol(npc_entity, location)
    if GridNav:CanFindPath(location) then
        npc_entity:PatrolToPosition(location)
    end
end


function normalRandom(mean, stdDev, pos_neg)
    local u1 = math.random() -- Uniform random number between 0 and 1
    local u2 = math.random() -- Uniform random number between 0 and 1

    -- Apply the Box-Muller transform
    local z0 = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)

    -- Scale and shift to the desired mean and standard deviation
    return pos_neg * (z0 * stdDev + mean)
end

function DebugPrint(...)
	if USE_DEBUG then
		print(...)
	end
end


function AttackAi(hero, targets, aggroed)
    local closest_distance = nil
    local closest_target = nil
    local channeling = false
    if targets == nil or #targets == 0 then return false end
    if targets ~= nil then
        if #targets == 1 then
            hero:SetAggroTarget(targets[1])
            channeling = HandleAgression(hero, targets[1])
            if channeling then
                return true
            end
        else
            if hero:GetName() == "npc_dota_hero_pudge" then
                print("handle aggression for targets")
            end
            for _, target in pairs(targets) do
                local d = hero:GetRangeToUnit(target)
                if closest_distance == nil and closest_target == nil then
                    closest_distance = d
                    closest_target = target
                else
                    if d <= closest_distance then
                        closest_distance = d
                        closest_target = target
                    end
                end
            end
            hero:SetAggroTarget(closest_target)
            channeling = HandleAgression(hero, closest_target)
            if channeling then
                return true
            end
        end
    end
    -- if not aggroed and closest_target ~= nil then
    --     hero:SetAggroTarget(closest_target)
    --     return true
    -- end
    return false
end

function HandleAgression(hero, target)
    if hero:GetTeamNumber() ~= target:GetTeamNumber() then
        if hero:GetName() == "npc_dota_hero_pudge" then
            local hook_ability = GetAbility(hero, 0)
            local dismember_ability = GetAbility(hero, 5)
            -- print("is channeling", hero:IsChanneling())
            if hero:IsChanneling() then
                return true
            end
            ToggleRot(hero, target)
            TryToCastAbility(hero, target, hook_ability)
            -- Can't have 2 dismembers on at the same time.. fix
            TryToCastAbility(hero, target, dismember_ability)
        end
        if hero:GetName() == "npc_dota_hero_crystal_maiden" then
            local nova_ability = GetAbility(hero, 0)
            TryToCastAbility(hero, target, nova_ability)
        end
    end
    return false
end

function TryToCastAbility(source, target, ability)
    local behavior = ability:GetBehaviorInt()
    if ability:IsFullyCastable() then
        if hasBehavior(behavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET ) then
            -- print(source:GetName(), "with ID", source:GetEntityIndex(), " casting target ability ", ability:GetAbilityName(),"to target", target:GetName(), target:GetEntityIndex())
            source:CastAbilityOnTarget(target, ability, source:GetEntityIndex())
            if ability:GetChannelTime() > 0 then
                source:AttackNoEarlierThan(ability:GetChannelTime(), 1)
            end
        else
            -- print(source:GetName(), "with ID", source:GetEntityIndex(), " casting position ability ", ability:GetAbilityName(),"to target", target:GetName(), target:GetEntityIndex())
            source:SetCursorPosition(target:GetOrigin())
            source:CastAbilityOnPosition(target:GetCenter(), ability, source:GetEntityIndex())
        end
    end
end

function ToggleRot(pudge_entity, target)
    local ability = pudge_entity:GetAbilityByIndex(1)
    local range = tonumber(ability:GetAbilityKeyValues().AbilityCastRangeBuffer)
    local aggro_unit = pudge_entity:GetAggroTarget()
    local target_close = false
    if (aggro_unit == nil or target == nil) and ability:GetToggleState() then
        print("turn off rot, no aggro or target")
        pudge_entity:CastAbilityToggle(ability, pudge_entity:GetEntityIndex())
        print("rot is ", ability:GetToggleState())
        return
    end
    if aggro_unit ~= nil then
        target_close = pudge_entity:GetRangeToUnit(aggro_unit) <= range
    else
        target_close = pudge_entity:GetRangeToUnit(target) <= range
    end
    if target_close and ability:GetToggleState() and GetHealthPercentage(pudge_entity) > 15 then
        print("target is close rot is ", ability:GetToggleState())
        return
    end
    if target_close and not ability:GetToggleState() then
        pudge_entity:CastAbilityToggle(ability, pudge_entity:GetEntityIndex())
        print("target is close and rot not toggled rot is ", ability:GetToggleState())
        return
    end
    --[[ 
    Turn it off if no one is near or
    If below 40% toggle off, it will be toggled on if someone is close, leading to 
    a toggle on and off feature so the npc doesn't just burn its health down. 
    ]]-- 
    if ability:GetToggleState() and GetHealthPercentage(pudge_entity) < 40 then
        print("below 40% turn off rot")
        pudge_entity:CastAbilityToggle(ability, pudge_entity:GetEntityIndex())
        print("rot is ", ability:GetToggleState())
        return
    end
end

function GetHealthPercentage(hero)
    local max_health = hero:GetMaxHealth()
    local current_health = hero:GetHealth()
    current_health = current_health / max_health
    print("health percentage ", current_health*100)
    return current_health *100
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

-- FindUnitsInRadius(team: DOTATeam_t, location: Vector, cacheUnit: CBaseEntity | nil, radius: float, teamFilter: DOTA_UNIT_TARGET_TEAM, typeFilter: DOTA_UNIT_TARGET_TYPE, flagFilter: DOTA_UNIT_TARGET_FLAGS, order: FindOrder, canGrowCache: bool): [CDOTA_BaseNPC]FindUnitsInRadius
function PrintKeys(keys)
   for name, value in pairs(keys) do
        print("key", name, "value", value, "type", type(value))
   end
end

function hasBehavior(behavior, target_beahvior)
    return bit.band(behavior, target_beahvior) ~= 0
end
