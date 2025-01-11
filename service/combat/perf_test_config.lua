-- perf_test_config.lua
-- 用于定义"战斗性能测试"相关的配置

local M = {}

-- 全局配置
M.global = {
    battle_count = 10,  -- 要创建的战场数量
    tick_interval = 50, -- 每隔多少tick(1=0.01s)释放技能(默认0.5秒)
}

-- 对每个battle的配置
-- 也可做成列表，循环生成
M.battles = {
    {
        battle_id = 1,
        units = {
            {
                id = 101,
                type = "Hero",
                attributes = { HP = 300, MP = 150000, Armor = 10, NT = 300 },
                skills = { "PhysicalAttack", "FireAndHeal", "FireBall",
                    "BladeMailSkill", "SpellAmplifySkill", "BloodPactSkill" }
            },
            {
                id = 202,
                type = "Enemy",
                attributes = { HP = 400, MP = 1000, Armor = 8, NT = 500 },
                skills = { "PhysicalAttack", "ThornSkill", "YadonSkill" }
            },
        },
        auto_skills = {
            -- 定义哪些unit对哪些目标释放什么技能
            -- 用于在循环中自动调用 release_skill
            {
                caster_id = 101,
                skill_name = "PhysicalAttack",
                target_id = 202
            },
            {
                caster_id = 101,
                skill_name = "BladeMailSkill",
                target_id = 202
            },
            {
                caster_id = 202,
                skill_name = "PhysicalAttack",
                target_id = 101
            },
        }
    },
    -- 如果需要多个battle配置，可继续添加
    {
        battle_id = 2,
        units = {
            {
                id = 301,
                type = "Hero",
                attributes = { HP = 30, MP = 200000, Armor = 12, NT = 300 },
                skills = { "PhysicalAttack", "BladeMailSkill" }
            },
            {
                id = 302,
                type = "Enemy",
                attributes = { HP = 400, MP = 1500, Armor = 15, NT = 500 },
                skills = { "PhysicalAttack", "FireBall" }
            }
        },
        auto_skills = {
            {
                caster_id = 301,
                skill_name = "PhysicalAttack",
                target_id = 302
            },
            {
                caster_id = 302,
                skill_name = "PhysicalAttack",
                target_id = 301
            }
        }
    }
    -- ...
}

return M
