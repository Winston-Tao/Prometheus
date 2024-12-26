-- service/ecs/entity.lua
local Entity = {}
Entity.__index = Entity

function Entity:new(id, entityType)
    local o = {
        id = id,
        entityType = entityType,
        components = {}
    }
    return setmetatable(o, self)
end

function Entity:init(config)
    -- 根据 config 加载组件
    -- 可调用 component factory 来创建组件
end

function Entity:dataInit()
    for _, comp in pairs(self.components) do
        comp:dataInit(self)
    end
end

function Entity:addComponent(component)
    table.insert(self.components, component)
end

function Entity:getComponent(compClass)
    for _, c in pairs(self.components) do
        if getmetatable(c) == compClass then
            return c
        end
    end
    return nil
end

function Entity:addToMap(map)
    for _, comp in pairs(self.components) do
        comp:onAddToMap(self, map)
    end
end

function Entity:removeFromMap(map)
    for _, comp in pairs(self.components) do
        comp:onRemoveFromMap(self, map)
    end
end

function Entity:destroy()
    for _, comp in pairs(self.components) do
        comp:onDestroy(self)
    end
    self.components = {}
end

return Entity
