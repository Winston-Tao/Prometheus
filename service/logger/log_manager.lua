-- logger/log_manager.lua
local LogEvent     = require "logger.log_event"
local LogLevel     = require "logger.log_level"
local LogFormatter = require "logger.log_formatter"
local LogHandler   = require "logger.log_handler"
local FileHandler  = require "logger.file_handler"

local LogManager   = {}
LogManager.__index = LogManager

function LogManager:new()
    local obj = setmetatable({}, self)
    obj.defaultLevel = LogLevel.DEBUG
    obj.formatter = LogFormatter:new()
    obj.handlers = {}
    return obj
end

function LogManager:addHandler(handler)
    table.insert(self.handlers, handler)
end

function LogManager:log(level, message, tags, data)
    local event = LogEvent:new(level, message, tags, data)
    for _, h in ipairs(self.handlers) do
        h:emit(event)
    end
end

-- 常用封装
function LogManager:debug(msg, tags, data)
    self:log(LogLevel.DEBUG, msg, tags, data)
end

function LogManager:info(msg, tags, data)
    self:log(LogLevel.INFO, msg, tags, data)
end

function LogManager:warn(msg, tags, data)
    self:log(LogLevel.WARNING, msg, tags, data)
end

function LogManager:error(msg, tags, data)
    self:log(LogLevel.ERROR, msg, tags, data)
end

function LogManager:critical(msg, tags, data)
    self:log(LogLevel.CRITICAL, msg, tags, data)
end

return LogManager
