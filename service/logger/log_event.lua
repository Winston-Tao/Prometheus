-- logger/log_event.lua
-- 每条日志可用结构化数据来存储
local skynet = require "skynet"

local LogEvent = {}
LogEvent.__index = LogEvent

-- todo 取堆栈应该有性能问题，后续再看看有没有其他方式
function LogEvent:new(level, message, tags, data)
    -- 获取调用栈信息（栈深为 3，因为 LogEvent:new 通常是被 log 调用的）
    local debug_info = debug.getinfo(5, "nSl")

    -- 初始化 LogEvent 对象
    local obj = setmetatable({}, self)
    obj.level = level             -- (LogLevel.*)
    obj.message = message         -- string
    obj.tags = tags or {}         -- { "battle", "buff", "damage" ...}
    obj.data = data or {}         -- table for extra fields
    obj.timestamp = skynet.time() -- or os.time()

    -- 自动填充调用信息
    obj.file = debug_info.short_src or "unknown" -- 文件名
    obj.line = debug_info.currentline or -1      -- 行号
    obj.func = debug_info.name or "anonymous"    -- 函数名

    return obj
end

return LogEvent
