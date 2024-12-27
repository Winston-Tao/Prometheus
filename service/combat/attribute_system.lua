-- attribute_system.lua
local AttributeSystem = {}
AttributeSystem.__index = AttributeSystem

function AttributeSystem:new(initial)
    local obj = setmetatable({}, self)
    obj.base = {}
    obj.current = {}
    for k, v in pairs(initial) do
        obj.base[k] = v
        obj.current[k] = v
    end
    return obj
end

-- 获取当前某属性
function AttributeSystem:get(attr)
    return self.current[attr] or 0
end

-- 修改某属性
function AttributeSystem:modify(attr, delta)
    local old = self.current[attr] or 0
    local newv = old + delta
    self.current[attr] = newv
    if newv < 0 and (attr == "HP") then
        self.current[attr] = math.max(0, newv) -- HP不应低于0
    end
end

-- 复原到base
function AttributeSystem:reset_to_base()
    for k, v in pairs(self.base) do
        self.current[k] = v
    end
end

-- Tick(每秒或固定时间片调用)
function AttributeSystem:update(dt)
    -- 例如可以在此恢复MP, HP regen, etc
end

return AttributeSystem
