-- config/scene_config.lua
-- 定义多种场景配置，使用 Lua 表定义
return {
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
