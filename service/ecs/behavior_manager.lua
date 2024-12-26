-- service/ecs/behavior_manager.lua
local MoveBehavior = require "ecs.behaviors.move_behavior"

local BehaviorManager = {
    behaviors = {
        move = MoveBehavior:new() -- 注册 "move" 操作对应的行为实例
    }
}

function BehaviorManager:execute(op, entity, cmd_table)
    local b = self.behaviors[op]
    if not b then
        return false, "unknown operation: " .. op
    end

    return b:execute(entity, cmd_table)
end

return BehaviorManager
