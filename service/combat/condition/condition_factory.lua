-- condition/condition_factory.lua
local ConditionDef     = require "condition.condition_def"
local HPBelowCond      = require "condition.hp_below_condition"
local AttackCountCond  = require "condition.attack_count_condition"

local ConditionFactory = {}
function ConditionFactory:createCondition(cfg)
    if cfg.condition_type == ConditionDef.COND_HP_BELOW then
        return HPBelowCond:new(cfg)
    elseif cfg.condition_type == ConditionDef.COND_ATTACK_COUNT then
        return AttackCountCond:new(cfg)
    end
    return nil
end

return ConditionFactory
