-- battle_logic.lua
local skynet = require "skynet"

skynet.start(function()
    skynet.error("[battle_logic] start...")

    -- 1) 通过 router_manager 分配一个 combat_manager 实例
    local manager = skynet.call(".serverRouter", "lua", "allocate_instance", "combat_manager")
    if not manager then
        skynet.error("[battle_logic] no available combat_manager!")
        skynet.exit()
        return
    end
    skynet.error("[battle_logic] allocated manager =>", manager)

    -- 2) 创建一个 battle
    local battle_id = skynet.call(manager, "lua", "create_battle")
    skynet.error("[battle_logic] create battle =>", battle_id)

    -- 3) 添加 Hero
    local hero_data = {
        type = "Hero",
        attributes = { HP = 30000, MP = 150000000, Armor = 10, NT = 300 },
        skills = {
            "PhysicalAttack",
            "FireAndHeal",
            "FireBall",
            "BladeMailSkill",
            "SpellAmplifySkill",
            "BloodPactSkill"
        },
        onRegisterToBattle = nil,
        id = 101
    }
    local hero_id = 101
    skynet.call(manager, "lua", "add_combatant", battle_id, hero_data)
    skynet.error("[battle_logic] add Hero =>", hero_id)

    -- 4) 添加 Enemy
    local enemy_data = {
        type = "Enemy",
        attributes = { HP = 40000, MP = 1000, Armor = 8, NT = 500 },
        skills = { "PhysicalAttack", "ThornSkill", "YadonSkill" },
        onRegisterToBattle = nil,
        id = 202
    }
    local enemy_id = 202
    skynet.call(manager, "lua", "add_combatant", battle_id, enemy_data)
    skynet.error("[battle_logic] add Enemy =>", enemy_id)

    -- 5) 启动战斗
    skynet.call(manager, "lua", "start_battle", battle_id)
    skynet.error("[battle_logic] start battle =>", battle_id)

    skynet.fork(function()
        while true do
            skynet.sleep(100)
            skynet.call(manager, "lua", "release_skill", battle_id, hero_id, "PhysicalAttack", enemy_id)

            skynet.call(manager, "lua", "release_skill", battle_id, hero_id, "BladeMailSkill", enemy_id)
            --
            skynet.sleep(100)
            --skynet.error("[battle_logic] enemy cast PhysicalAttack")
            skynet.call(manager, "lua", "release_skill", battle_id, enemy_id, "PhysicalAttack", hero_id)

        end
    end)

    skynet.wait()
end)
