-- timers.lua - minimal timers helper
if Timers == nil then
    Timers = {}
end

function Timers:CreateTimer(delay, callback)
    if type(delay) == "function" then 
        callback = delay
        delay = 0
    end
    local ctx = DoUniqueString("timer")
    return GameRules:GetGameModeEntity():SetContextThink(ctx, function()
        return callback()
    end, delay)
end
