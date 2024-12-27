-- service/main.lua
local skynet = require "skynet"
require "skynet.manager" -- import skynet.register
local service_manager = require "service_manager"
local logger = require "battle_logger"

skynet.error("package.path=", package.path)
skynet.error("package.cpath=", package.cpath)

local scene_mgr
local SceneFactory = require "scene_factory"

skynet.start(function()
    skynet.error("Server start")

    local scene_config = {
        scenes = {
            {
                scene_id = 1001,
                conf_id = "default_scene_conf",
                name = "TestScene1",
                entity_list = {
                    { type = "demoMapEntity", config = { x = 100, y = 200 } }
                }
            },
            {
                scene_id = 1002,
                conf_id = "pvp_scene_conf",
                name = "PVPBattleField",
                entity_list = {
                    { type = "demoMapEntity", config = { x = 50, y = 50 } }
                    -- 后续可添加更多实体
                }
            }
        },
        -- 后续可添加更多场景定义
    }

    -- 启动 worldscene_mgr 服务
    scene_mgr = skynet.uniqueservice("worldscene_mgr")
    service_manager.register("scene_mgr", scene_info)

    -- 举例从配置中读取场景confId,先使用 scene_id=1001 场景
    local scene_id = 1001

    for _, sc in ipairs(scene_config.scenes) do
        if sc.scene_id == scene_id then
            scene_info = sc
            break
        end
    end

    if not scene_info then
        skynet.error(string.format("Scene_id %d not found in config", scene_id))
        skynet.exit()
        return
    end

    -- 使用工厂创建场景数据
    local factory_data = SceneFactory:createScene(scene_info)

    -- 在mgr中创建场景
    local ok, scene_service = pcall(function()
        return skynet.call(scene_mgr, "lua", "create_scene", factory_data)
    end)

    if not ok then
        skynet.error("Failed to create scene:", scene_service)
        skynet.exit()
        return
    end

    skynet.error("Scene created service:", scene_service)

    -- 测试路由与进入场景操作
    local ok_enter, err = skynet.call(scene_mgr, "lua", "enter_scene", scene_id, 1001)
    if not ok_enter then
        skynet.error("Failed to enter scene:", err)
    else
        skynet.error("Player 1001 entered scene", scene_id)
    end

    skynet.error("main service ready")

    -- 保持main服务存活
    skynet.dispatch("lua", function(session, address, cmd, ...)
        skynet.error("main service got message:", cmd)
        skynet.ret()
    end)

    ---- 启动一个console服务(可选),在console中输入json指令
    ---- 输入格式例如: { "op": "move", "tar": "100,100", "sceneid": 1001, "entityId": "player_1" }
    --skynet.newservice("console", scene_mgr)

    -- 启动 服务router
    local router
    local ok, err = pcall(function()
        router = skynet.uniqueservice("server_router")
    end)
    if not ok then
        skynet.error("[ERROR] Failed to start service: server_router. Reason:", err)
    else
        skynet.error("[INFO] Service 'server_router' started successfully with handle:", router)
    end

    -- 启动战斗日志服务
    logger.init() -- 初始化日志系统

    -- 启动多个 combat_manager
    for i = 1, 2 do
        local combat_manager
        ok, err = pcall(function()
            combat_manager = skynet.newservice("combat_manager")
        end)
        if not ok then
            skynet.error(string.format("[ERROR] Failed to start service: combat_manager (instance %d). Reason: %s", i,
                err))
        else
            skynet.error(string.format(
                "[INFO] Service 'combat_manager' (instance %d) started successfully with handle: %s", i, combat_manager))
        end
    end

    -- 启动 battle_logic
    local battle_logic
    ok, err = pcall(function()
        battle_logic = skynet.newservice("battle_logic")
    end)
    if not ok then
        skynet.error("[ERROR] Failed to start service: battle_logic. Reason:", err)
    else
        skynet.error("[INFO] Service 'battle_logic' started successfully with handle:", battle_logic)
    end

    skynet.wait() -- 阻塞等待，防止main退出
end)


-- 返回一个函数用于获取 scene_mgr
local function getSceneMgr()
    return scene_mgr
end

return {
    getSceneMgr = getSceneMgr
}
