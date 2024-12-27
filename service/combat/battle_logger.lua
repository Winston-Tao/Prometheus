-- battle_logger.lua
local skynet       = require "skynet"
local LogManager   = require "logger.log_manager"
local LogLevel     = require "logger.log_level"
local LogFormatter = require "logger.log_formatter"
local FileHandler  = require "logger.file_handler"

local logger       = {}

-- 全局log manager
local logMgr

function logger.init()
    logMgr = LogManager:new()
    local formatter = LogFormatter:new()

    local fileHandler = FileHandler:new(formatter, LogLevel.DEBUG, "logs/battle.log")
    logMgr:addHandler(fileHandler)
end

function logger.debug(msg, tags, data)
    if logMgr then
        logMgr:debug(msg, tags, data)
    end
end

function logger.info(msg, tags, data)
    if logMgr then
        logMgr:info(msg, tags, data)
    end
end

function logger.warn(msg, tags, data)
    if logMgr then
        logMgr:warn(msg, tags, data)
    end
end

function logger.error(msg, tags, data)
    if logMgr then
        logMgr:error(msg, tags, data)
    end
end

function logger.critical(msg, tags, data)
    if logMgr then
        logMgr:critical(msg, tags, data)
    end
end

return logger
