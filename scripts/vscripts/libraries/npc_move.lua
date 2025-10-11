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
            AttackAi(npc_entity, {target})
            return 1
        end
        local targets = FindEnemyTargets(npc_entity, 2000, nil)
        if AttackAi(npc_entity, targets) then
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

function MoveToNewRandomLocation(entity)
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
    DebugPrint("Current position ", entity.current_position)
    DebugPrint("X change", x_random_distance_change)
    DebugPrint("Y change", y_random_distance_change)
    local destination = entity.current_position:__add(Vector(x_random_distance_change, 0, 0))
    entity.next_position = destination:__add(Vector(0, y_random_distance_change, 0))
    entity:MoveToPosition(entity.next_position)
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

--[[
AttackAi - generally picks the closest target unless the entity is already aggroed to a unit
hero - CDOTA_BaseNPC
targets - table of target CDOTA_BaseNPC
aggression - handle attacks for the hero
]]
function AttackAi(hero, targets, aggression)
    local closest_distance = nil
    local closest_target = nil
    local channeling = false
    if targets == nil or #targets == 0 then return false end
    if targets ~= nil then
        if #targets == 1 then
            hero:SetAggroTarget(targets[1])
            channeling = aggression(hero, targets[1])
            if channeling then
                return true
            end
        else
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
            channeling = aggression(hero, closest_target)
            if channeling then
                return true
            end
        end
    end
    return false
end

-- If the ability is ready, cast it
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

function PrintKeys(keys)
   for name, value in pairs(keys) do
        print("key", name, "value", value, "type", type(value))
   end
end

function hasBehavior(behavior, target_beahvior)
    return bit.band(behavior, target_beahvior) ~= 0
end
