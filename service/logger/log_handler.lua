-- logger/log_handler.lua
local LogHandler   = {}
LogHandler.__index = LogHandler
local skynet       = require "skynet"

function LogHandler:new(formatter, level)
    local obj = setmetatable({}, self)
    obj.formatter = formatter
    obj.minLevel = level or 10 -- default: DEBUG
    return obj
end

-- sync write
function LogHandler:emit(event)
    if event.level < self.minLevel then
        return
    end
    local line = self.formatter:formatEvent(event)
    self:write(line)
end

function LogHandler:write(line)
    print(line)
end

return LogHandler
