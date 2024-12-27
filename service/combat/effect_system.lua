-- effect_system.lua
local skynet = require "skynet"
local Combatant = require "combatant"

local EffectSystem = {}
EffectSystem.__index = EffectSystem

function EffectSystem:new()
    local obj = setmetatable({}, EffectSystem)
    return obj
end

-- 执行效果
function EffectSystem:execute_effect(buff)
    local effect_type = buff.effect
    local target = buff.target
    local caster = buff.caster
    local value = buff.value

    if effect_type == "hurt" then
        -- 扣除生命值
        target.attributes:modify("HP", -value)
        skynet.send("combat_logger", "lua", "log_event", {
            event = "Damage",
            source = caster,
            target = target,
            value = value,
            damage_type = buff.damage_type,
        })
    elseif effect_type == "heal" then
        -- 恢复生命值
        target.attributes:modify("HP", value)
        skynet.send("combat_logger", "lua", "log_event", {
            event = "Heal",
            source = caster,
            target = target,
            value = value,
        })
    elseif effect_type == "buff" then
        -- 增加属性
        target.attributes:modify(buff.attribute, value)
        skynet.send("combat_logger", "lua", "log_event", {
            event = "AttributeBuff",
            source = caster,
            target = target,
            attribute = buff.attribute,
            value = value,
        })
    elseif effect_type == "dodge" then
        -- 实现闪避逻辑（示例）
        local dodge_chance = value / 100 -- 假设 value 是百分比
        if math.random() < dodge_chance then
            skynet.send("combat_logger", "lua", "log_event", {
                event = "Dodge",
                source = target,
                target = caster,
            })
            -- 可以在此取消攻击或其他逻辑
        end
    else
        skynet.error("Unknown effect type: " .. effect_type)
    end
end

return EffectSystem
