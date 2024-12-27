-- service/ecs/behaviors/move_behavior.lua
-- 简单移动行为：解析tar坐标并更新 PositionComponent

local MoveBehavior = {}
MoveBehavior.__index = MoveBehavior

function MoveBehavior:new()
    local o = {}
    return setmetatable(o, self)
end

function MoveBehavior:execute(entity, cmd_table)
    local tar = cmd_table.tar
    if not tar then
        return false, "no target coordinate provided"
    end
    -- tar = "100,100"
    local x, y = tar:match("^(%d+),(%d+)$")
    x = tonumber(x)
    y = tonumber(y)
    if not x or not y then
        return false, "invalid target coordinate"
    end

    -- 假设直接瞬移过去（简单示例，实际可能需要移动系统逐步移动）
    local posComp = entity:getComponent(require("ecs.components.position_component"))
    if not posComp then
        return false, "entity has no position component"
    end

    posComp:setPosition(x, y)
    skynet.error(string.format("Entity %s moved to %d,%d", entity.id, x, y))
    return true
end

return MoveBehavior
