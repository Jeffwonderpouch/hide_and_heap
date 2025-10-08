MAP_CENTER = Vector(0,0,0)

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

function RandomCharMovement(npc_entity) 
    local final_location = nil 
    Timers:CreateTimer(function()
        local current_position = npc_entity:GetOrigin()
        if current_position ~= final_location and final_location ~= nil and GridNav:CanFindPath(current_position, final_location) then 
            -- print(GridNav:CanFindPath(current_position, final_location))
            -- print("Continuing travel to ", final_location,"from", current_position)
            npc_entity:MoveToPosition(final_location)
            return 1
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
        DebugPrint("Current location ", current_position)
        DebugPrint("X change", x_random_distance_change)
        DebugPrint("Y change", y_random_distance_change)
        current_position = current_position:__add(Vector(x_random_distance_change, 0, 0))
        current_position = current_position:__add(Vector(0, y_random_distance_change, 0))
        final_location = current_position
        -- print("New location ", final_location)
        npc_entity:MoveToPosition(final_location)
        return 1
    end)
end

function RandomCharMovementWithAggro(npc_entity) 
    local final_location = nil
    local wasAggrod = nil
    local aggroTarget = nil 
    Timers:CreateTimer(function()
        local current_position = npc_entity:GetOrigin()
        local hasAggro = npc_entity:GetAggroTarget()
        if hasAggro ~= nil then
            wasAggrod = true
            return 1
        end
        if current_position ~= final_location and final_location ~= nil and GridNav:CanFindPath(current_position, final_location) and wasAggrod == false then 
            -- print(GridNav:CanFindPath(current_position, final_location))
            -- print("Continuing travel to ", final_location,"from", current_position)
            npc_entity:MoveToPosition(final_location)
            return 1
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
        DebugPrint("Current location ", current_position)
        DebugPrint("X change", x_random_distance_change)
        DebugPrint("Y change", y_random_distance_change)
        current_position = current_position:__add(Vector(x_random_distance_change, 0, 0))
        current_position = current_position:__add(Vector(0, y_random_distance_change, 0))
        final_location = current_position
        print("New location ", final_location)
        npc_entity:MoveToPosition(final_location)
        return 1
    end)
end


function GenerateRandomUnitLocation(away_from_center)
    local coins = FlipCoin(2)
    local sd = away_from_center / 6
    x_loc= normalRandom(away_from_center, sd, coins[1])
    y_loc = normalRandom(1000, 200, coins[2])
    local try = true
    while try do
        local loc_vector = Vector(x_loc, y_loc, 128)
        if GridNav:CanFindPath(MAP_CENTER, loc_vector) then
            try = false
        end
        print("Cant path to ", loc_vector)
    end
    return Vector(x_loc, y_loc, 128)
end

-- start_location and end_location are Vectors
function UnitPartrol(npc_entity, location)
    if GridNav:CanFindPath(location) then
        npc_entity:PatrolToPosition(location)
    end
end

--[[ 
function FindMapBounds()
    findPath = true
	local x_edge = 100 
	local y_edge = 100 
	while findPath do
		can_find_x = GridNav:CanFindPath(Vector(0,0,0), Vector(x_edge,0))
		can_find_y = GridNav:CanFindPath(Vector(0,0,0), Vector(y_edge,0))
		if can_find_x then
			x_edge
		end
		print("Can find x path", findPath)
		print("Can find y path", findPath)

	end
	return 
end 
]] 

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