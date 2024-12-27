-- condition/hp_below_condition.lua
local HPBelowCond = {}
HPBelowCond.__index = HPBelowCond

function HPBelowCond:new(cfg)
    local obj = setmetatable({}, self)
    obj.threshold = cfg.threshold or 0.3
    return obj
end

function HPBelowCond:check(target)
    local maxHP = target.attr:get("MaxHP") or 1000
    local curHP = target.attr:get("HP") or maxHP
    return (curHP < maxHP * self.threshold)
end

return HPBelowCond
