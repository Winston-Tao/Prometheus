local skynet = require "skynet"

local logger_common = {}

-- 确保 Logger 服务存在
function logger_common.ensureLogger()
    if not logger_common.loggerSvc then
        logger_common.loggerSvc = skynet.localname(".log_service") or skynet.queryservice("log_service")
    end
end

-- 通用日志函数生成器
function logger_common.createLogger(tag)
    local logger = {}

    local function getCaller()
        local info = debug.getinfo(4, "nSl")
        local file = info and info.short_src or "?"
        local line = info and info.currentline or "?"
        local func = info and info.name or "?"
        return file, line, func
    end

    -- 通用日志方法
    local function log(level, msg, tags, data)
        logger_common.ensureLogger()
        local file, line, func = getCaller()
        if data == nil or type(data) ~= "table" then
            data = {}
        end
        local debugInfo = {
            file = file,
            line = line,
            func = func
        }
        for k, v in pairs(debugInfo) do
            data[k] = v
        end

        skynet.send(logger_common.loggerSvc, "lua", level, msg, tags, data)
    end

    -- 自动生成日志接口
    for _, level in ipairs({ "debug", "info", "warn", "error", "critical" }) do
        logger[level] = function(msg, tags, data)
            log(level, msg, tag, data)
        end
    end

    return logger
end

return logger_common
