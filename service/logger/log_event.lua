-- logger/log_event.lua
-- 每条日志可用结构化数据来存储
local skynet = require "skynet"

local LogEvent = {}
LogEvent.__index = LogEvent

function LogEvent:new(level, message, file, line, func, tags, data, timestamp)
    local obj     = setmetatable({}, self)
    obj.level     = level
    obj.message   = message
    obj.file      = file or "?"
    obj.line      = line or "?"
    obj.func      = func or "?"
    obj.tags      = tags or {}
    obj.data      = data or {}
    obj.timestamp = timestamp or skynet.time()
    return obj
end

return LogEvent
