--logger/login_handler.lua
local Handler = {}
Handler.__index = Handler
LogLevel = require "log_level"

function Handler:new(formatter, level)
    local obj     = setmetatable({}, self)
    obj.formatter = formatter
    obj.minLevel  = level or LogLevel.DEBUG
    obj.filters   = {} -- { filterObj1, filterObj2... }
    return obj
end

function Handler:addFilter(filter)
    table.insert(self.filters, filter)
end

function Handler:emit(event)
    if event.level < self.minLevel then
        return
    end
    for _, flt in ipairs(self.filters) do
        if not flt:check(event) then
            return
        end
    end
    local line = self.formatter:formatEvent(event)
    self:write(line)
end

function Handler:write(line)
    print(line)
end

return Handler
