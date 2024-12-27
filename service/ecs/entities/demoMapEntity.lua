-- service/ecs/entities/demoMapEntity.lua
-- 示例的地图实体类型，加载一个PositionComponent为例

local Entity = require "ecs.entity"
local PositionComponent = require "ecs.components.position_component"

local DemoMapEntity = {}
DemoMapEntity.__index = DemoMapEntity

setmetatable(DemoMapEntity, {
    __index = Entity, -- 继承自Entity
})

function DemoMapEntity:new(id, config)
    local o = Entity:new(id, "DemoMap")
    setmetatable(o, self)
    return o
end

function DemoMapEntity:init(config)
    -- 调用父类 init if needed
    Entity.init(self, config)
    -- 加载组件
    local posComp = PositionComponent:new()
    posComp:init(self, config)
    self:addComponent(posComp)
end

return DemoMapEntity
