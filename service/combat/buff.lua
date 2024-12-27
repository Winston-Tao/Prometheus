-- buff.lua
local Buff = {}
Buff.__index = Buff

function Buff:new(name, duration, effect, value, damage_type, caster, target)
    local obj = setmetatable({}, Buff)
    obj.name = name
    obj.duration = duration
    obj.remaining_time = duration
    obj.effect = effect
    obj.value = value
    obj.damage_type = damage_type
    obj.caster = caster
    obj.target = target
    obj.trigger_time = "on_apply" -- 可以根据配置进行动态设置
    return obj
end

return Buff
