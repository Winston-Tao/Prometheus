-- logger/log_event.lua
-- 每条日志可用结构化数据来存储
local skynet = require "skynet"

local LogEvent = {}
LogEvent.__index = LogEvent

function LogEvent:new(level, message, tags, data)
    local obj     = setmetatable({}, self)
    obj.level     = level         -- (LogLevel.*)
    obj.message   = message       -- string
    obj.tags      = tags or {}    -- { "battle", "buff", "damage" ...}
    obj.data      = data or {}    -- table for extra fields
    obj.timestamp = skynet.time() -- or os.time()
    return obj
end

return LogEvent
