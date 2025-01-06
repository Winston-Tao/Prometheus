-- 基于原子化技能设计 女王之召 技能配置demo
skill_definitions = {
    ["ThornSkill"] = {     -- 英雄所释放的技能-女王之召
        cooldown  = 12,    -- 技能冷却cd
        mana_cost = 80,    -- 技能耗蓝量
        is_auto   = false, -- 是否自动释放
        buffs     = {
            {
                -- 条件 不存在召唤物
                conditions      = {
                    condition = {
                        "check_existing_summon", false
                    }
                },
                target_strategy = "enemy_dense_area", -- 自定义一个策略：选敌人最密集的格子范围
                buff_name       = "ThornSummonBuff"
            },
            {
                -- 条件 存在召唤物
                conditions      = {
                    condition = {
                        "check_existing_summon", true
                    }
                },
                target_strategy = "MySummon",                           -- 自定义一个策略：选择我的召唤物
                buff_name       = { "SummonRecover", "SummonDecrease" } -- 满血并且刷新技能cd
            }
        }
    },

    ["PainFetterSkill"] = { -- 召唤物释放的技能 苦痛附身
        cooldown  = 12,     -- 技能冷却cd
        is_auto   = true,   -- 自动释放
        mana_cost = 0,      -- 技能耗蓝量
        buffs     = {
            {
                target_strategy = { "findAroundGrid", 2 }, -- 自定义一个策略：周围两格
                buff_name       = "PainFetterBuff"
            },
        }
    },
}

buff_definitions = {
    ["ThornSummonBuff"] = {
        duration = 0.1, -- 仅持续一个瞬间(可视作“InstantBuff”)
        effects  = {
            {
                effect_type  = "summon_creature",
                monster_id   = "1",       -- 索引到怪物配置表
                trigger      = "onApply", -- 挂载时执行
                copy_percent = 100,       -- 复制召唤者属性百分比
            }
        }
    },

    ["PainFetterBuff"] = {
        duration = 2, -- 持续两秒
        effects  = {
            {
                effect_type = "modify_state",
                trigger     = "onApply",
                attr        = "CanMove",
                value       = -1 -- 禁止移动状态
            },
            {
                effect_type   = "hurt",
                trigger       = "onTick",
                tick_interval = 1,                      -- 每个 tick 执行
                formula       = { "casterAttack", 1.4 } -- 伤害计算公式 1.4倍攻击伤害
            }
        }
    },

    ["SummonRecover"] = {
        duration = 0.1,
        effects  = {
            {
                effect_type = "modify_attribute", -- 修改属性
                trigger     = "onApply",
                attr        = "HP",
                value       = "max"
            },
            {
                effect_type = "refreshSkillCd", -- 刷新技能cd -- 则会再次释放 “苦痛附身”
                trigger     = "onApply",
            }
        }
    },
    ["SummonDecrease"] = {
        duration = 0.1,
        effects  = {
            {
                effect_type = "modify_attribute", -- 修改属性
                trigger     = "onApply",
                attr        = "HP",
                formula     = { "maxHp", 1.45 } -- 最大生命值增加45%
            },
            {
                effect_type   = "modify_attribute", -- 修改属性
                trigger       = "onTick",
                tick_interval = 1,                  -- 每秒
                attr          = "HP",
                formula       = { "maxHp", 0.96 }   -- 最大生命值每秒减少4%
            },
        }
    },
}
