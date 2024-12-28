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

--- msg 描述日志的主要内容，应简单明了。
--- tags 为日志添加分类信息，用于快速过滤和检索。
--- data 存储上下文信息和详细数据，用于调试和分析。
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
