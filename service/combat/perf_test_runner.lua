-- perf_test_runner.lua
local skynet = require "skynet"
local config = require "perf_test_config"
local logger = require "battle_logger"

local runner = {}

function runner:start()
    skynet.error("[perf_test_runner] start...")

    -- 2) 批量创建battle
    for idx = 1, config.global.battle_count do
        -- 1) 分配 combat_manager, 只需一次 or 每battle一个
        -- 假设已存在一个 router_manager 负责分配
        local manager = skynet.call(".serverRouter", "lua", "allocate_instance", "combat_manager")
        if not manager then
            skynet.error("[perf_test_runner] no available combat_manager!")
            goto continue
        end
        skynet.error("[perf_test_runner] allocated manager =>", manager)

        local battleIndex = (idx - 1) % #config.battles + 1
        local battleCfg = config.battles[battleIndex]
        -- 继续处理 battleCfg...
        if not battleCfg then
            goto continue
        end

        local battle_id = skynet.call(manager, "lua", "create_battle")
        skynet.error("[perf_test_runner] create battle =>", battle_id)

        -- 3) 添加units
        for _, unit in ipairs(battleCfg.units) do
            skynet.call(manager, "lua", "add_combatant", battle_id, unit)
            skynet.error("[perf_test_runner] add unit =>", unit.id, " to battle", battle_id)
        end

        -- 4) 启动battle
        skynet.call(manager, "lua", "start_battle", battle_id)
        skynet.error("[perf_test_runner] start battle =>", battle_id)

        -- 5) 启动自动施法
        local auto_skills = battleCfg.auto_skills or {}
        self:startAutoCasting(manager, battle_id, auto_skills)
        ::continue::
    end

    skynet.error("[perf_test_runner] All battles created. performance test running.")
end

-- 定义自动施法循环
function runner:startAutoCasting(manager, battle_id, auto_skills)
    skynet.fork(function()
        while true do
            skynet.sleep(config.global.tick_interval) -- 每X tick(默认50=0.5s)施放一次

            for _, skillItem in ipairs(auto_skills) do
                local caster_id = skillItem.caster_id
                local skill_name = skillItem.skill_name
                local target_id = skillItem.target_id
                skynet.call(manager, "lua", "release_skill", battle_id, caster_id, skill_name, target_id)
            end

            -- 这里若要观察长时效果, 不退出
            -- 也可加条件(HP<=0 etc) => break
        end
    end)
end

return runner
