-- service/worldscene_mgr.lua
-- 管理多个worldscene, 场景路由
local skynet = require "skynet"

local CMD = {}
local scenes = {} -- scene_id -> worldscene service handle

function CMD.create_scene(scene_info)
    local scene_service = skynet.newservice("worldscene")
    skynet.call(scene_service, "lua", "init", scene_info)
    scenes[scene_info.scene_id] = scene_service
    return scene_service
end

function CMD.get_scene(scene_id)
    return scenes[scene_id]
end

function CMD.enter_scene(scene_id, player_id)
    local s = scenes[scene_id]
    if s then
        skynet.call(s, "lua", "enter_player", player_id)
        return true
    else
        return false, "scene not found"
    end
end

-- 新增分发命令的接口
function CMD.dispatch_command(cmd_table)
    local scene_id = cmd_table.sceneid
    local s = scenes[scene_id]
    if not s then
        return false, "scene not found"
    end
    return skynet.call(s, "lua", "handle_operation", cmd_table)
end

skynet.start(function()
    skynet.dispatch("lua", function(session, address, cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.retpack(f(...))
        else
            skynet.error("worldscene_mgr unknown cmd:", cmd)
            skynet.ret()
        end
    end)
end)
