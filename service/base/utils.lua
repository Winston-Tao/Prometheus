-- utils.lua
local utils = {}

-- 生成唯一ID（简单示例）
function utils.generate_unique_id()
    return tostring(math.random(100000, 999999))
end

-- 计算两点之间的距离
function utils.distance(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    return math.sqrt(dx * dx + dy * dy)
end

return utils
