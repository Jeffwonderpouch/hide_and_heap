if HideAndHeap == nil then
    HideAndHeap = class({})
end

HideAndHeap.ROUND_DURATION = GAME_ROUND_DURATION --> LOOK TO SETTINGS FOR VALUE

function HideAndHeap:StartRound() -- START ROUND FUNCTION
    print("[HideAndHeap] Preparing to start round...")

    -- Wait until the game actually starts
    GameRules:GetGameModeEntity():SetThink(function()
        local state = GameRules:State_Get()

        -- Only start once the game is actually in progress
        if state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
            print("[HideAndHeap] Round started (using game clock)!")
            HideAndHeap:StartItemSpawner() -- startup the item spawner script
            ---------------------------------------------------------- 
            -- Delay activating the round logic until after hide phase
            ----------------------------------------------------------
            Timers:CreateTimer(HIDE_DURATION, function()
                self.roundActive = true
                -- Start monitoring the clock once per second
                GameRules:GetGameModeEntity():SetThink(function()
                    if not self.roundActive then return nil end

                    local gameTime = GameRules:GetDOTATime(false, false)

                    -- Check win conditions
                    local result = self:CheckWinConditions()
                    if result then
                        self:EndRound(result)
                        return nil
                    end

                    -- Time up?
                    if gameTime >= self.ROUND_DURATION then
                        print("[HideAndHeap] Times up! Checking win...")
                        self:EndRound("time_up")
                        return nil
                    end

                    return 1 -- keep checking every second
                end, "RoundThink", 1)
            end)

            return nil -- stop waiting for state change
        end

        return 1 -- check again every second until game starts
    end, "WaitForStart", 1)
end

function HideAndHeap:CheckWinConditions() -- CHECK WIN CONDITIONS FUNCTION
    local cmAlive = 0
    local pudgeAlive = 0

    for _, hero in pairs(HeroList:GetAllHeroes()) do
        if hero:IsRealHero() and hero:IsAlive() and hero:GetTeam() == DOTA_TEAM_GOODGUYS then
            cmAlive = cmAlive + 1
        end
    end

    if cmAlive == 0 then
        return "heap_win"
    end

    for _, hero in pairs(HeroList:GetAllHeroes()) do
        if hero:IsRealHero() and hero:IsAlive() and hero:GetTeam() == DOTA_TEAM_BADGUYS then
            pudgeAlive = pudgeAlive + 1
        end
    end

    if pudgeAlive == 0 then
        return "cm_win"
    end

    return nil
end

function HideAndHeap:EndRound(result) -- END OF ROUND FUNCTION
    if not self.roundActive then return end
    self.roundActive = false

    print("[HideAndHeap] Ending round: " .. result)

    local winningTeam = DOTA_TEAM_GOODGUYS
    local victoryText = "Team Crystal Maiden Wins!"

    if result == "heap_win" then
        winningTeam = DOTA_TEAM_BADGUYS
        victoryText = "Team Pudge Wins!"
    elseif result == "time_up" or "cm_win" then
        -- If time runs out and any CM alive → Radiant win
        winningTeam = DOTA_TEAM_GOODGUYS
        victoryText = "Team Crystal Maiden Wins!"
    end

    -- Announce winner in chat
    GameRules:SendCustomMessage(victoryText, 0, 0)

    -- Delay slightly so message prints before end
    --Timers:CreateTimer(2.0, function()
        GameRules:SetSafeToLeave(true)
        GameRules:SetGameWinner(winningTeam)
        GameRules:SetCustomVictoryMessage(victoryText)
        GameRules:SetCustomVictoryMessageDuration(10)
    --end)
end