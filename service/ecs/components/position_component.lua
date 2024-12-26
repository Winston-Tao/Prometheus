-- service/ecs/components/position_component.lua
local Component = require "ecs.component"
local PositionComponent = {}
PositionComponent.__index = PositionComponent

setmetatable(PositionComponent, {
    __index = Component,
})

function PositionComponent:new()
    local o = Component:new()
    return setmetatable(o, self)
end

function PositionComponent:init(entity, config)
    self.x = config.x or 0
    self.y = config.y or 0
end

function PositionComponent:setPosition(nx, ny)
    self.x = nx
    self.y = ny
    -- TODO: 通知 viewMgr relay更新玩家视野中的数据包（后续扩展）
end

return PositionComponent
