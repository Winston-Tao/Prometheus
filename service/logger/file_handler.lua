-- logger/file_handler.lua

local LogHandler = require "log_handler"
assert(type(LogHandler) == "table", "LogHandler is not a valid module")
local FileHandler   = setmetatable({}, { __index = LogHandler })
FileHandler.__index = FileHandler

-- 定义一个表，将 LogLevel 映射成字符串
local levelNameMap  = {
    [LogLevel.DEBUG]    = "debug",
    [LogLevel.INFO]     = "info",
    [LogLevel.WARNING]  = "warning",
    [LogLevel.ERROR]    = "error",
    [LogLevel.CRITICAL] = "critical",
}

function FileHandler:new(formatter, level, fileName)
    local obj = LogHandler:new(formatter, level)
    setmetatable(obj, self)
    -- 根据 level 获取对应字符串, 默认 "unknown" 避免 nil
    local levelStr = levelNameMap[level] or "unknown"

    obj.fileName = (fileName .. levelStr .. ".log") or "logs/game.log"
    obj.file = io.open(obj.fileName, "a")
    return obj
end

function FileHandler:write(line)
    if self.file then
        self.file:write(line, "\n")
        self.file:flush()
    end
end

function FileHandler:close()
    if self.file then
        self.file:close()
        self.file = nil
    end
end

return FileHandler
