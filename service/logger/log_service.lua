--------------------------------------------------------------------------------
-- log_service.lua
--------------------------------------------------------------------------------
local skynet  = require "skynet"
Logger        = require "log_combine"
local CMD     = {}
local logger -- 全局Logger实例
BaseFormatter = require "log_formatter"
FileHandler   = require "file_handler"
ModuleFilter  = require "log_filter"

function CMD.init()
    logger                   = Logger:new()

    local baseFormatter      = BaseFormatter:new()

    -- 1) battleHandler => battle.log
    local battleDebugHandler = FileHandler:new(baseFormatter, LogLevel.DEBUG, "logs/battle_")
    local battleInfoHandler  = FileHandler:new(baseFormatter, LogLevel.INFO, "logs/battle_")

    -- 只过滤 "battle" 模块 => ModuleFilter
    local battleFilter       = ModuleFilter:new { ["battle"] = true }
    battleDebugHandler:addFilter(battleFilter)
    battleInfoHandler:addFilter(battleFilter)

    logger:addHandler(battleDebugHandler)
    logger:addHandler(battleInfoHandler)

    -- 2) hotUpdateHandler => ai.log
    local hotUpdateHandler       = FileHandler:new(baseFormatter, LogLevel.DEBUG, "logs/hotUpdate")
    local hotUpdateHandlerFilter = ModuleFilter:new { ["hotUpdate"] = true }
    hotUpdateHandler:addFilter(hotUpdateHandlerFilter)
    logger:addHandler(hotUpdateHandler)

    -- 3) 其他通用 => game.log
    local generalHandler = FileHandler:new(baseFormatter, LogLevel.INFO, "logs/game.log")
    logger:addHandler(generalHandler)

    skynet.error("LoggerService init done, multiple handlers attached")
end

function CMD.debug(msg, tags, data)
    if logger then
        logger:debug(msg, tags, data)
    end
end

function CMD.info(msg, tags, data)
    if logger then
        logger:info(msg, tags, data)
    end
end

function CMD.warn(msg, tags, data)
    if logger then
        logger:warn(msg, tags, data)
    end
end

function CMD.error(msg, tags, data)
    if logger then
        logger:error(msg, tags, data)
    end
end

function CMD.critical(msg, tags, data)
    if logger then
        logger:critical(msg, tags, data)
    end
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.retpack(f(...))
        else
            skynet.ret()
        end
    end)
    CMD.init()
end)
