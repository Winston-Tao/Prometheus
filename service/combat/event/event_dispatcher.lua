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

return EventDispatcher
