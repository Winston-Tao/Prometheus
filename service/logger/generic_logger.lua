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

    local function handle_unsupported_type(value, key_repr)
        local value_type = type(value)
        if value_type == "function" then
            -- 获取函数的详细信息
            local func_info = debug.getinfo(value, "nS")
            local func_name = func_info.name or "<anonymous>" -- 函数名，可能为匿名
            local source = func_info.source or "<unknown>"    -- 函数定义来源
            local line = func_info.linedefined or -1          -- 函数定义的行号
            skynet.error(string.format(
                "[Sanitize] Removed unsupported type 'function' at key '%s': %s (defined in %s at line %d)",
                key_repr, tostring(value), source, line
            ))
            return nil
        elseif value_type == "thread" then
            skynet.error(string.format("[Sanitize] Removed unsupported type 'thread' at key '%s'", key_repr))
            return nil
        elseif value_type == "userdata" then
            skynet.error(string.format("[Sanitize] Removed unsupported type 'userdata' at key '%s'", key_repr))
            return nil
        else
            -- 支持的类型直接返回原值
            return value
        end
    end


    -- 检查并移除不支持的数据类型
    local function sanitize_data(data, parent_key)
        parent_key = parent_key or "<root>"

        -- 针对非 table 类型的数据直接处理
        if type(data) ~= "table" then
            local sanitized_value = handle_unsupported_type(data, parent_key)
            return sanitized_value or data -- 返回处理后的值或原值
        end

        -- 针对 table 类型的数据递归处理
        local sanitized = {}
        for k, v in pairs(data) do
            local key_repr = string.format("%s.%s", parent_key, tostring(k))
            if type(v) == "table" then
                -- 递归检查子表
                sanitized[k] = sanitize_data(v, key_repr)
            else
                -- 非表类型交给辅助函数处理
                local sanitized_value = handle_unsupported_type(v, key_repr)
                if sanitized_value ~= nil then
                    sanitized[k] = sanitized_value
                end
            end
        end

        return sanitized
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

        -- 检查并移除不可序列化的数据
        local sanitized_data = sanitize_data(data)
        local sanitized_msg = sanitize_data(msg)
        local sanitized_tags = sanitize_data(tags)

        skynet.send(logger_common.loggerSvc, "lua", level, sanitized_msg, sanitized_tags, sanitized_data)
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
