-- logger/file_handler.lua

local skynet        = require "skynet"
local LogHandler    = require "logger.log_handler"
local FileHandler   = setmetatable({}, { __index = LogHandler })
FileHandler.__index = FileHandler

function FileHandler:new(formatter, level, fileName)
    local obj = LogHandler:new(formatter, level)
    setmetatable(obj, self)
    obj.fileName = fileName or "logs/game.log"
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
