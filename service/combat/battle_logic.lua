-- battle_logic.lua
local skynet = require "skynet"

skynet.start(function()
    skynet.error("[battle_logic] start...")

    -- 申请一个战场管理器
    local manager = skynet.call(".serverRouter", "lua", "allocate_instance", "combat_manager")

    -- 创建battle
    local battle_id = skynet.call(manager, "lua", "create_battle")
    skynet.error("[battle_logic] create battle =>", battle_id)

    -- 添加一个Hero
    local hero_data = {
        type = "Hero",
        attributes = { HP = 30000, MP = 1500, Armor = 10 },
        skills = { "PhysicalAttack", "FireAndHeal", "FireBall",
            "BladeMailSkill", "SpellAmplifySkill", "BloodPactSkill" } -- FireBall手动, PhysicalAttack自动, FireAndHeal手动
    }
    local hero_id = 101
    skynet.call(manager, "lua", "add_combatant", battle_id, hero_id, hero_data)

    -- 添加一个Enemy
    local enemy_data = {
        type = "Enemy",
        attributes = { HP = 40000, MP = 1000, Armor = 8 },
        skills = { "PhysicalAttack" } --自动物理攻击
    }

    local enemy_id = 202
    skynet.call(manager, "lua", "add_combatant", battle_id, enemy_id, enemy_data)

    -- 开始战斗
    skynet.call(manager, "lua", "start_battle", battle_id)
    skynet.error("[battle_logic] start battle =>", battle_id)

    -- 等5秒后 手动放 FireAndHeal
    skynet.sleep(500)
    skynet.error("[battle_logic] hero cast FireAndHeal => enemy & self")
    skynet.call(manager, "lua", "release_skill", battle_id, hero_id, "FireAndHeal", enemy_id)

    -- 再等5秒后 手动放 FireBall
    skynet.sleep(500)
    skynet.error("[battle_logic] hero cast FireBall => enemy")
    skynet.call(manager, "lua", "release_skill", battle_id, hero_id, "FireBall", enemy_id)

    -- 3秒后, 手动释放“BladeMailSkill”
    skynet.sleep(300)
    skynet.error("[battle_logic] hero cast BladeMailSkill")
    skynet.call(manager, "lua", "release_skill", battle_id, hero_id, "BladeMailSkill", enemy_id)

    skynet.sleep(3000)
    skynet.error("[battle_logic] end logic.")
    skynet.exit()
end)
