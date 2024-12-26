-- service/worldscene.lua
local skynet = require "skynet"
local Entity = require "ecs.entity"
-- 后续可加载更多模块：system, behavior, viewMgr等

local BehaviorManager = require "ecs.behavior_manager"

local scene_data = {} -- 保存场景状态
local CMD = {}

function CMD.init(scene_info)
    scene_data.scene_id = scene_info.scene_id
    scene_data.name = scene_info.name
    scene_data.entities = {}

    -- 创建实体列表
    for _, econf in ipairs(scene_info.entity_list or {}) do
        -- 根据type创建实体对象 (demoMapEntity)
        local cls = require("ecs.entities." .. econf.type)
        local ent = cls:new("entity_" .. econf.type .. "_" .. econf.config.x .. "_" .. econf.config.y, econf.config)
        ent:init(econf.config)
        table.insert(scene_data.entities, ent)
    end
    skynet.error(string.format("Scene (%d) %s init complete, entities: %d",
        scene_data.scene_id, scene_data.name, #scene_data.entities))
end

function CMD.enter_player(player_id)
    -- todo: 将player entity加入场景
    skynet.error(string.format("Player %d enters scene %d", player_id, scene_data.scene_id))
end

function CMD.handle_operation(cmd_table)
    -- { op = "move", tar = "100,100", sceneid=XX, entityId=XX }
    local op = cmd_table.op
    local entityId = cmd_table.entityId
    local entity = scene_data.entities[entityId]
    if not entity then
        return false, "entity not found"
    end

    -- 调用 BehaviorManager执行操作
    local ok, err = BehaviorManager:execute(op, entity, cmd_table)
    if not ok then
        skynet.error("handle_operation failed:", err)
        return false, err
    end
    return true
end

-- 定时器函数
local function task()
    skynet.error("Executing worldScene periodic task")
    skynet.timeout(100 * 60, task) -- 100 时间片后再次执行 (约 1 秒)
end

skynet.start(function()
    skynet.dispatch("lua", function(session, addr, cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.retpack(f(...))
        else
            skynet.error("worldscene unknown cmd:", cmd)
            skynet.ret()
        end
    end)
    -- 定时任务
    skynet.timeout(100 * 5, task)
end)
