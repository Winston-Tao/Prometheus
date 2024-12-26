-- service/scene_factory.lua
-- 工厂模块，根据 conf_id 创建特定场景配置
-- 这里简单实现：根据 conf_id 返回对应的 entity_list 等信息
-- 实际上我们已有 scene_config 在 main 读取，这里可传入具体 scene_info

local SceneFactory = {}

function SceneFactory:createScene(scene_info)
    -- scene_info中包含 scene_id, conf_id, name, entity_list
    -- 可根据conf_id决定加载哪些系统或组件

    -- 返回一个SceneData结构，用于worldscene init时使用
    return {
        scene_id = scene_info.scene_id,
        name = scene_info.name,
        entity_list = scene_info.entity_list,
        -- 后续可添加更多玩法组件、system列表
    }
end

return SceneFactory
