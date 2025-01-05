-- event/event_dispatcher.lua

local skynet            = require "skynet"
local EventModeStrategy = require "event.event_mode_strategy"

local EventDispatcher   = {}
EventDispatcher.__index = EventDispatcher

function EventDispatcher:new(mode)
    local obj = setmetatable({}, self)
    obj.subscribers = {}
    obj.mode = mode or "sync"
    return obj
end

function EventDispatcher:subscribe(eventType, consumer, priority)
    self.subscribers[eventType] = self.subscribers[eventType] or {}
    consumer.priority = priority or 50
    table.insert(self.subscribers[eventType], consumer)
    skynet.error("[EventDispatcher] subscribe success")
end

function EventDispatcher:publish(eventType, eventData)
    local subs = self.subscribers[eventType]
    if not subs then return end
    eventData.type = eventType
    if self.mode == "sync" then
        EventModeStrategy:handleEventSync(subs, eventData)
    else
        EventModeStrategy:handleEventAsync(subs, eventData)
    end
end

function EventDispatcher:publishTo(consumers, eventData, syncOrAsync)
    if not consumers or #consumers == 0 then
        return
    end
    eventData.type = eventData.type or "custom_event"
    if syncOrAsync == "sync" then
        self:dispatchSync(consumers, eventData)
    else
        self:dispatchAsync(consumers, eventData)
    end
end

-- 同步按优先级
function EventDispatcher:dispatchSync(consumers, eventData)
    table.sort(consumers, function(a, b)
        return (a.priority or 50) > (b.priority or 50)
    end)
    for _, c in ipairs(consumers) do
        c:onEvent(eventData.type, eventData)
    end
end

-- 异步
function EventDispatcher:dispatchAsync(consumers, eventData)
    for _, c in ipairs(consumers) do
        skynet.fork(function()
            c:onEvent(eventData.type, eventData)
        end)
    end
end

return EventDispatcher
