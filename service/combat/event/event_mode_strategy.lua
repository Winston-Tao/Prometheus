-- event/event_mode_strategy.lua
local skynet = require "skynet"

local EventModeStrategy = {}
EventModeStrategy.__index = EventModeStrategy

function EventModeStrategy:handleEventSync(subscribers, eventData)
    table.sort(subscribers, function(a, b)
        return (a.priority or 50) > (b.priority or 50)
    end)
    for _, c in ipairs(subscribers) do
        c:onEvent(eventData.type, eventData)
    end
end

function EventModeStrategy:handleEventAsync(subscribers, eventData)
    for _, c in ipairs(subscribers) do
        skynet.fork(function()
            c:onEvent(eventData.type, eventData)
        end)
    end
end

return EventModeStrategy
