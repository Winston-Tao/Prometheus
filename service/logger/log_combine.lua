-- log组件聚合
local Logger = {}
Logger.__index = Logger

LogEvent = require "log_event"

function Logger:new()
    local obj = setmetatable({}, self)
    obj.handlers = {}
    return obj
end

function Logger:addHandler(handler)
    table.insert(self.handlers, handler)
end

function Logger:log(level, msg, tags, data)
    local file, line, func = data.file, data.line, data.func
    local event = LogEvent:new(level, msg, file, line, func, tags, data)
    for _, hd in ipairs(self.handlers) do
        hd:emit(event)
    end
end

function Logger:debug(msg, tags, data) self:log(LogLevel.DEBUG, msg, tags, data) end

function Logger:info(msg, tags, data) self:log(LogLevel.INFO, msg, tags, data) end

function Logger:warn(msg, tags, data) self:log(LogLevel.WARNING, msg, tags, data) end

function Logger:error(msg, tags, data) self:log(LogLevel.ERROR, msg, tags, data) end

function Logger:critical(msg, tags, data) self:log(LogLevel.CRITICAL, msg, tags, data) end

--------------------------------------------------------------------------------
return Logger
