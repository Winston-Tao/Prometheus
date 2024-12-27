-- condition/attack_count_condition.lua
local AttackCountCond = {}
AttackCountCond.__index = AttackCountCond

function AttackCountCond:new(cfg)
    local obj = setmetatable({}, self)
    obj.count = cfg.count or 5
    obj.accum = 0
    return obj
end

function AttackCountCond:check(target)
    return (self.accum >= self.count)
end

function AttackCountCond:increment()
    self.accum = self.accum + 1
end

return AttackCountCond
