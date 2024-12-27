-- event/event_consumer.lua
local EventConsumer = {}
EventConsumer.__index = EventConsumer

function EventConsumer:new()
    return setmetatable({}, self)
end

function EventConsumer:onEvent(eventType, eventData)
    -- 子类实现
end

return EventConsumer
