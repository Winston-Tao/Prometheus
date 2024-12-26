-- service/ecs/component.lua
local Component = {}
Component.__index = Component

function Component:new()
    local o = {}
    return setmetatable(o, self)
end

function Component:init(entity, config)
    -- 实例化组件时的初始化逻辑
end

function Component:dataInit(entity)
    -- 从数据源加载状态
end

function Component:onAddToMap(entity, map)
    -- 实体加入地图时回调
end

function Component:onRemoveFromMap(entity, map)
end

function Component:onDestroy(entity)
end

return Component
