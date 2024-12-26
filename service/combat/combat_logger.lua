-- combat_logger.lua
local skynet = require "skynet"

local CombatLogger = {}
CombatLogger.__index = CombatLogger

function CombatLogger:log_event(event_data)
    -- 这里可以将日志存储到文件、数据库或内存中
    -- 示例中打印日志
    skynet.error("Combat Logger - Event:", event_data.event)
    skynet.error("Caster:", event_data.caster and event_data.caster.id or "nil")
    skynet.error("Skill:", event_data.skill and event_data.skill.name or "nil")
    skynet.error("Targets:")
    if event_data.targets then
        for _, target in ipairs(event_data.targets) do
            skynet.error(" - ", target.id, "HP after:", target.attributes:get("HP"))
        end
    end
    -- 可以根据需要扩展日志记录方式
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        if cmd == "log_event" then
            local event_data = ...
            CombatLogger:log_event(event_data)
            skynet.ret()
        else
            skynet.error("Unknown command to combat_logger:", cmd)
            skynet.ret()
        end
    end)
end)

return CombatLogger
