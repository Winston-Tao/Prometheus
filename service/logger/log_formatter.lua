-- logger/log_formatter.lua
-- 为了避免 Lua 字符串频繁拼接性能问题，采用 table buffer + table.concat 的方式。

local LogFormatter = {}
LogFormatter.__index = LogFormatter

function LogFormatter:new()
    return setmetatable({}, self)
end

-- 自定义递归序列化：将 table 转为可读字符串
local function serializeTable(val, indent, visited)
    if type(val) ~= "table" then
        return tostring(val)
    end

    if visited[val] then
        return "<circular reference>"
    end
    visited[val] = true

    indent = indent or 0
    local buffer = {}
    local indentStr = string.rep("  ", indent)

    table.insert(buffer, "{\n")
    for k, v in pairs(val) do
        table.insert(buffer, indentStr .. "  " .. tostring(k) .. " = ")
        if type(v) == "table" then
            local sub = serializeTable(v, indent + 1, visited)
            table.insert(buffer, sub)
        else
            table.insert(buffer, tostring(v))
        end
        table.insert(buffer, ",\n")
    end
    table.insert(buffer, indentStr .. "}")
    return table.concat(buffer)
end

local function formatTimestamp(ts)
    local sec     = math.floor(ts)
    local msec    = math.floor((ts - sec) * 1000)
    local dateStr = os.date("%Y-%m-%d %H:%M:%S", sec)
    return string.format("%s.%03d", dateStr, msec)
end

-- 将 event (LogEvent) 转为字符串
function LogFormatter:formatEvent(event)
    -- event 是一个表: { level, timestamp, message, tags, data }
    local buffer = {}
    local dateTimeStr = formatTimestamp(event.timestamp or 0)
    table.insert(buffer, dateTimeStr)
    if event.file or event.line or event.func then
        local src = string.format("[%s:%s:%s]",
            event.file or "?", event.line or "?", event.func or "?")
        table.insert(buffer, ", location=" .. src)
    end
    table.insert(buffer, " [LogEvent] level=" .. tostring(event.level))
    table.insert(buffer, ", timestamp=" .. tostring(event.timestamp))
    table.insert(buffer, ", message=" .. tostring(event.message))

    -- tags
    if event.tags and #event.tags > 0 then
        local tagsStr = serializeTable(event.tags, 0, {})
        table.insert(buffer, ", tags=" .. tagsStr)
    end

    -- data
    if event.data then
        local dataStr = serializeTable(event.data, 0, {})
        table.insert(buffer, ", data=" .. dataStr)
    end

    return table.concat(buffer)
end

return LogFormatter
