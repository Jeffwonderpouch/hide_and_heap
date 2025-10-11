
if HideAndHeap == nil then
    _G.HideAndHeap = class({})
end

require("libraries/timers")
require("libraries/pudge")
require("libraries/cm")
require("libraries/hero_utils")
require("libraries/npc_move")
require("game_setup")
require("settings")

-----------------------------------------------------
-- Precache
-----------------------------------------------------
function Precache(context)
    PrecacheUnitByNameSync("npc_dota_hero_crystal_maiden", context)
    PrecacheUnitByNameSync("npc_dota_hero_pudge", context)
end

-----------------------------------------------------
-- Entry
-----------------------------------------------------
function Activate()
    LinkLuaModifier("pudge_thinker", "libraries/pudge.lua", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("cm_thinker", "libraries/cm.lua", LUA_MODIFIER_MOTION_NONE)
    GameRules.HideAndHeap = HideAndHeap()
    GameRules.HideAndHeap:InitGameMode()
end


-----------------------------------------------------
-- Init Game Mode
-----------------------------------------------------
function HideAndHeap:InitGameMode()
    print("[HIDEANDHEAP] GameMode Init")

    local mode = GameRules:GetGameModeEntity()

    GameRules:EnableCustomGameSetupAutoLaunch(true)
    GameRules:SetCustomGameSetupAutoLaunchDelay(LOBBY_WAIT_TIME)
    GameRules:SetCustomGameSetupRemainingTime(30)
    GameRules:SetCustomGameSetupTimeout(30)

    -- Team caps
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 8)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, 2)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_CUSTOM_1, 0)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_CUSTOM_2, 0)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_CUSTOM_3, 0)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_CUSTOM_4, 0)

    -- Timers
    GameRules:SetHeroSelectionTime(0)
    GameRules:SetStrategyTime(0)
    GameRules:SetShowcaseTime(0)
    GameRules:SetPreGameTime(0)

    -- SCANS
    mode:SetCustomScanCooldown(30)
    mode:SetCustomScanMaxCharges(3)

    -- Disabling respawn & buyback
    GameRules:SetHeroRespawnEnabled(false)
    GameRules:GetGameModeEntity():SetFixedRespawnTime(-1)
    mode:SetBuybackEnabled(false)
    -- 💰 Set global gold rules
    GameRules:SetStartingGold(69)   -- gives 69 base gold to everyone
    GameRules:SetGoldPerTick(69)     -- 69 gold per tick
    GameRules:SetGoldTickTime(60) -- gold ticks every minute

    -- Force-pick CM for everyone initially
    mode:SetCustomGameForceHero("npc_dota_hero_crystal_maiden")

    -- listen state changes
    ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(HideAndHeap, "OnGameStateChange"), self)

    -- npc_spawned -> initialize heroes
    ListenToGameEvent("npc_spawned", function(event)
        local entIndex = event and (event.entindex or event.entindex_ent or event.entindex_entindex)
        if not entIndex then return end
        Timers:CreateTimer(0.05, function()
            local unit = EntIndexToHScript(tonumber(entIndex))
            if unit and IsValidEntity(unit) and unit:IsRealHero() then
                local ok, err = pcall(function() InitializeHero(unit) end)
                if not ok then print("[HIDEANDHEAP] InitializeHero error:", err) end
            end
        end)
    end, nil)

    print("[HIDEANDHEAP] InitGameMode complete")
end

----------------------------------------------------- 
-- OnGameStateChange -> Fill bots + swap heroes
-----------------------------------------------------
function HideAndHeap:OnGameStateChange()
    HideAndHeap.NPC_PUDGE = {}
    HideAndHeap.NPC_CM = {}
    local state = GameRules:State_Get()
    print("[HIDEANDHEAP] State Changed:", state)

    local pudge_count = 0
    local cm_count = 0
    -- Step 1: Setup heroes when map loads
    if state == DOTA_GAMERULES_STATE_PRE_GAME then
        print("[HIDEANDHEAP] Waiting for map to load - preparing pudge hero swaps")

        -- for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
        for playerID = 0, REQUIRED_CM_COUNT + REQUIRED_PUDGE_COUNT - 1 do
            if PlayerResource:IsValidPlayerID(playerID) then
                local team = PlayerResource:GetTeam(playerID)
                if team == DOTA_TEAM_BADGUYS then
                    pudge_count = pudge_count + 1
                    PrecacheUnitByNameAsync("npc_dota_hero_pudge", function()
                        local ok, newHero = pcall(function()
                            return PlayerResource:ReplaceHeroWith(playerID, "npc_dota_hero_pudge", 0, 0)
                        end)

                        if ok and newHero then
                            newHero:SetModelScale(PUDGE_INIT_SIZE_SCALE)
                            print("[HIDEANDHEAP] Replaced Dire player " .. playerID .. " with Pudge")
                            print("[HideAndHeap] Pregame started — locking Dire for " .. HIDE_DURATION .. " seconds")
                            HideAndHeap:LockDireDuringPregame(HIDE_DURATION)
                        else
                            print("[HIDEANDHEAP] ReplaceHeroWith failed for Dire player", playerID)
                        end
                    end, playerID)
                else
                    cm_count = cm_count + 1
                end
            else
                if cm_count < REQUIRED_CM_COUNT and AUTO_FILL_TEAMS then
                    local cm = CreateUnitByName("npc_dota_hero_crystal_maiden", GenerateRandomUnitLocation(3000), true, nil, nil, DOTA_TEAM_GOODGUYS)
                    table.insert(HideAndHeap.NPC_CM, cm)
                    ApplyCMThinker(cm)
                end
            end
        end
        if pudge_count < REQUIRED_PUDGE_COUNT and AUTO_FILL_TEAMS then
            local count = REQUIRED_PUDGE_COUNT - pudge_count
            for num = 1, count do
                local pudge = CreateUnitByName("npc_dota_hero_pudge", Vector(0,0,0), true, nil, nil, DOTA_TEAM_BADGUYS)
                table.insert(HideAndHeap.NPC_PUDGE, pudge)
                ApplyPudgeThinker(pudge)
            end
        end
    end

    -- Step 1.5 -- TIMED MESSAGES
    if state== DOTA_GAMERULES_STATE_PRE_GAME then
        local duration = HIDE_DURATION
        GameRules:SendCustomMessage("Crystal Maidens, run and hide now!", 0, 0)
                -- Pudge countdown message
        for i = duration, 1, -5 do
            Timers:CreateTimer(duration - i, function()
                GameRules:SendCustomMessage("Pudges free to move in " .. i .. " seconds!", 0, 0)
            end)
        end
        -- PUDGES ARE RELEASED!
        Timers:CreateTimer(duration, function()
            GameRules:SendCustomMessage("Pudges are released! Time to hunt!", 0, 0)
        end)
    end

    -- Step 2: Once the game actually begins, start the round
    if state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        HideAndHeap:StartItemSpawner() -- startup the item spawner script
        self:StartRound()
        local roundTime = ROUND_TIME
        -- Minute countdown message
        for i = roundTime, 1, -60 do
            Timers:CreateTimer(roundTime - i, function()
                GameRules:SendCustomMessage("The round has " .. math.floor(i / 60) .. " minutes left!", 0, 0)
            end)
        end
    end
end

---------------------------------------------------------
-- LOCK DIRE DURING PREGAME (HIDE PHASE)
---------------------------------------------------------
function HideAndHeap:LockDireDuringPregame(duration)
    print("Locking Dire players for " .. duration .. " seconds")

    for _, hero in pairs(HeroList:GetAllHeroes()) do
        if hero:IsRealHero() and hero:GetTeamNumber() == DOTA_TEAM_BADGUYS then
            hero:AddNewModifier(hero, nil, "modifier_stunned", { duration = duration })
        end
    end
end

---------------------------------------------------------
-- WHEN A HERO DIES -> PUDGE BONUS
---------------------------------------------------------
ListenToGameEvent("entity_killed", function(event)
    local killed = EntIndexToHScript(event.entindex_killed or -1)
    local attacker = EntIndexToHScript(event.entindex_attacker or -1)
    if not (killed and killed:IsRealHero()) then return end

    ---------------------------------------------------------
    -- 💀 If the killer is a Pudge, grant vision + move speed bonuses
    ---------------------------------------------------------
    if attacker and attacker:IsRealHero() and attacker:GetUnitName() == "npc_dota_hero_pudge" then
        -- Track and apply cumulative bonuses
        attacker._visionBonus = (attacker._visionBonus or 0) + PUDGE_KILL_VISION_BONUS -- +200 vision per kill
        attacker._movespeedBonus = (attacker._movespeedBonus or 0) + PUDGE_KILL_MOVE_SPEED_BONUS -- +25 MS per kill

        local baseDayVision = 1800
        local baseNightVision = 800

        local newDayVision = baseDayVision + attacker._visionBonus
        local newNightVision = baseNightVision + attacker._visionBonus

        attacker:SetDayTimeVisionRange(newDayVision)
        attacker:SetNightTimeVisionRange(newNightVision)

        -- Apply move speed bonus via modifier or directly
        local baseMS = attacker:GetBaseMoveSpeed()
        attacker:SetBaseMoveSpeed(baseMS + attacker._movespeedBonus)

        -- Get current model scale
        local currentScale = attacker:GetModelScale()
        -- Increase scale by a small amount
        attacker:SetModelScale(currentScale + PUDGE_KILL_SIZE_SCALING) -- adjust growth per kill

        -- Feedback messages
        local msg = string.format(
            "Pudge grows from his kill! Vision: +%d (Total %d / %d), Move Speed: +%d",
            attacker._visionBonus,
            newDayVision,
            newNightVision,
            attacker._movespeedBonus
        )

        GameRules:SendCustomMessage(msg, attacker:GetPlayerOwnerID(), attacker:GetPlayerOwnerID())
        print("[HideAndHeap] Pudge " .. attacker:GetPlayerOwnerID() ..
              " gained bonuses: Vision +" .. attacker._visionBonus ..
              ", MS +" .. attacker._movespeedBonus)
    end
end, nil)

---------------------------------------------------------
-- 📘 Spawn Random Items Every 2 Minutes
---------------------------------------------------------
function HideAndHeap:StartItemSpawner()
    -- Run immediately, then every 120 seconds
    Timers:CreateTimer(0, function()
        self:SpawnBooks()
        self:SpawnRandomItems()
        print("[HideAndHeap] New items have spawned!")
        return 120.0 -- repeat every 120 seconds
    end)
end

---------------------------------------------------------
-- 📘 Spawn Tomes of Knowledge around the map
---------------------------------------------------------
function HideAndHeap:SpawnBooks()
    -- Define potential spawn locations
    local spawnPoints = {
        Vector(-1666, -5755, 60), -- first location
        Vector(1945, 5832, 60), -- second location
    }

    for _, pos in pairs(spawnPoints) do
        local item = CreateItem("item_tome_of_knowledge", nil, nil)
        if item then
            local drop = CreateItemOnPositionSync(pos, item)
            print("[HideAndHeap] Spawned Tome of Knowledge at " .. tostring(pos))
        end
    end
end

---------------------------------------------------------
-- 📘 Spawn Random Items at Key Locations
---------------------------------------------------------
function HideAndHeap:SpawnRandomItems()
    -- List of possible items to spawn
    local itemPool = {
        "item_black_king_bar",
        "item_bloodthorn",
        "item_butterfly",
        "item_cyclone",
        "item_diffusal_blade",
        "item_echo_sabre",
        "item_ethereal_blade",
        "item_force_staff",
        "item_gem",
        "item_glimmer_cape",
        "item_heart",
        "item_helm_of_the_dominator",
        "item_invis_sword",
        "item_lotus_orb",
        "item_manta",
        "item_meteor_hammer",
        "item_monkey_king_bar",
        "item_nullifier",
        "item_orchid",
        "item_pipe",
        "item_refresher",
        "item_sheepstick",
        "item_silver_edge",
        "item_solar_crest",
        "item_sphere",
        "item_travel_boots_2",
        "item_vanguard",
        "item_vladmir",
        "item_yasha",
        "item_sange",
        "item_kaya",
        "item_shivas_guard",
        "item_iron_branch",
        "item_blood_grenade"
    }

    -- Define spawn locations
    local spawnPoints = {
        Vector(-5799, 5840, 150),  -- top left
        Vector(5720, -5739, 150),  -- bottom right
    }

    for _, pos in pairs(spawnPoints) do
        local itemName = itemPool[RandomInt(1, #itemPool)]
        local item = CreateItem(itemName, nil, nil)
        if item then
            CreateItemOnPositionSync(pos, item)
            print("[HideAndHeap] Spawned random item (" .. itemName .. ") at " .. tostring(pos))
        end
    end
end

-- Use DeepPrintTable to see table values
-- EntIndexToHScript use en
