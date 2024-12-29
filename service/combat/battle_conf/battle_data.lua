-- battle_data.lua
local EffectDef   = require "effect_def"
local TriggerDef  = require "trigger_def"
local DamageDef   = require "damage_def"

local battle_data = {}


---------------------------
-- 2. Buff Definitions
---------------------------
battle_data.buff_definitions     = {
    -- SlowDebuff: 对目标减速
    SlowDebuff = {
        duration = 3,
        overlap = "refresh",
        effects = {
            {
                effect_type = EffectDef.types.MODIFY_ATTRIBUTE,
                trigger     = TriggerDef.TRIGGERS.ON_APPLY,
                attr        = "MoveSpeed",
                value       = -100
            },
            {
                effect_type = EffectDef.types.MODIFY_ATTRIBUTE,
                trigger     = TriggerDef.TRIGGERS.ON_APPLY,
                attr        = "AttackSpeed",
                value       = -0.3
            }
        }
    },
    -- FireDamageBuff: 每秒造成火焰伤害
    FireDamageBuff = {
        duration = 5,
        overlap = "stack", -- 可以堆叠
        effects = {
            {
                effect_type = EffectDef.types.HURT,
                trigger = TriggerDef.TRIGGERS.ON_TICK,
                tick_interval = 1,
                damage_type = DamageDef.DAMAGES.MAGICAL,
                base_damage = 20
            }
        }
    },
    -- HealOverTimeBuff: 每秒回复一定HP
    HealOverTimeBuff = {
        duration = 5,
        overlap = "refresh",
        effects = {
            {
                effect_type = EffectDef.types.MODIFY_ATTRIBUTE,
                trigger = "onTick",
                tick_interval = 1,
                attr = "HP",
                value = 10
            }
        }
    },
    -------------------------------------------------------
    -- 刃甲主动 Buff: 在持续时间内, 反弹 XX% 攻击伤害
    -------------------------------------------------------
    BladeMailActive = {
        duration = 4, -- 4秒
        overlap  = "discard",
        effects  = {
            {
                effect_type = "blade_mail", -- 由 effects/blade_mail.lua 处理
                trigger = "onDamageTaken",  -- 当受伤害时执行 -- todo 后续优化成事件驱动
                reflect_percent = 0.5,      -- 反弹50%
            }
        }
    },
    -------------------------------------------------------
    -- 刃甲被动 Buff: 永久存在(用一个大数字duration或干脆写-1表示永久)
    -------------------------------------------------------
    BladeMailPassive = {
        duration = 9999,
        overlap  = "discard", -- 不叠加
        effects  = {
            {
                effect_type = "blade_mail", -- 同一个effect, 但参数不同
                trigger = "onDamageTaken",
                reflect_fixed = 20,
                reflect_percent = 0.2,     -- 20%
                reflect_only_attack = true -- 仅对普通攻击 / 物理攻击生效
            }
        }
    },

    -------------------------------------------------------
    -- 法术强化 (SpellAmplify) - 被动Buff
    -- 机制: "下一次单体法术" -> +150伤害, 并减速目标
    -------------------------------------------------------
    SpellAmplifyPassive = {
        duration = 9999,
        effects = {
            {
                effect_type = "store_reflect_damage", -- 这里复用或另写 effect: "spell_amplify_condition"
                trigger = "onCastSkill",
                only_single_target = true,
                bonus_damage = 150,
                slow_debuff = "SpellAmplifySlowDebuff", -- 施加减速
                once_only = true,
            }
        }
    },
    SpellAmplifySlowDebuff = {
        duration = 1.5,
        overlap = "discard",
        effects = {
            {
                effect_type = EffectDef.types.MODIFY_ATTRIBUTE,
                trigger     = TriggerDef.TRIGGERS.ON_APPLY,
                attr        = "MoveSpeed",
                value       = -50
            },
        }
    },

    -------------------------------------------------------
    -- 血契 (BloodPact) - 被动Buff
    -- 机制: 对英雄的技能吸血75%, 对小兵15%
    -------------------------------------------------------
    BloodPactPassive = {
        duration = 9999,
        effects = {
            {
                effect_type = EffectDef.types.MODIFY_ATTRIBUTE,
                trigger = "onSpellDamageDealt",
                attr = "SkillLifeSteal", -- 伪属性
                -- 具体由 damage_calc 里判断单位类型(英雄/小兵)
                value = 0.75
            }
        }
    },
    -- 也可继续定义 StunDebuff, SilenceDebuff 等...

    ["ThornBuff"] = {
        duration = 9999,
        effects = {
            {
                effect_type     = "summon_creature",
                trigger         = TriggerDef.TRIGGERS.ON_APPLY,
                creature_name   = "ThornMonster",
                inherit_percent = 100
            },
            {
                effect_type = "hurt",
                trigger = "onAttack", --扇形攻击,可再custom
                base_damage = 50
            },
            {
                effect_type = EffectDef.types.MODIFY_ATTRIBUTE,
                trigger     = TriggerDef.TRIGGERS.ON_APPLY,
                attr        = "MaxHP",
                value       = 45, -- +45% ...
            },
            {
                effect_type = "hpDrainPerSec", -- ...
            },
            {
                effect_type = "apply_buff", --苦痛附身
                trigger = "onCast",
                buff_name = "PainBuff"
            }
        }
    },
    ["PainBuff"] = {
        duration = 2,
        effects = {
            {
                effect_type = EffectDef.types.MODIFY_ATTRIBUTE,
                trigger     = TriggerDef.TRIGGERS.ON_APPLY,
                attr        = "CanMove",
                value       = -1
            },
            {
                effect_type = "hurt",
                trigger = "onTick",
                damage_type = DamageDef.DAMAGES.PHYSICAL,
                base_damage_factor = 1.4
            }
        }
    },
    ["YadonCloudBuff"] = {
        duration = 6,
        effects = {
            {
                effect_type = "hurt",
                trigger = "onTick",
                damage_type = DamageDef.DAMAGES.PHYSICAL,
                base_damage_factor = 1.4
            }
        }
    }
}

---------------------------
-- 3. Skill Definitions
---------------------------
battle_data.skill_definitions    = {
    -- 普通物理攻击
    PhysicalAttack = {
        cooldown = 1,
        mana_cost = 0,
        is_auto = true,
        buffs = {
            -- “buffs”数组内的每一项，对应对一批目标应用的“Buff”或“InstantBuff”
            {
                target_strategy = "closest_single",
                buff_name = "InstantBuff:HurtPhysical50"
                -- “InstantBuff:HurtPhysical50”在 effect 里直接伤害
            }
        }
    },
    -- 火球 FireBall (单体伤害 + 减速)
    FireBall = {
        cooldown = 5,
        mana_cost = 50,
        is_auto = false,
        buffs = {
            {
                target_strategy = "closest_single",
                buff_name = "InstantBuff:FireDamageInstant"
                -- 释放时立刻造成一次火焰伤害 + 上 SlowDebuff
            }
        }
    },
    -- FireAndHeal：对敌施加火焰伤害Buff，对己方施加治疗Buff
    FireAndHeal = {
        cooldown = 8,
        mana_cost = 40,
        is_auto = false,
        buffs = {
            {
                target_strategy = "closest_single", -- 敌方
                buff_name = "FireDamageBuff"
            },
            {
                target_strategy = "self", -- 自己
                buff_name = "HealOverTimeBuff"
            }
        }
    },
    -------------------------------------------------------
    -- 刃甲(主动+被动)
    -------------------------------------------------------
    BladeMailSkill = {
        cooldown      = 15,
        mana_cost     = 25,
        cast_time     = 0.0,   -- 前摇0秒
        break_on_stun = false, -- 不会被施法者眩晕打断
        is_auto       = false,
        buffs         = {
            -- 施加一个Buff: BladeMailActive
            {
                target_strategy = "self",
                buff_name = "BladeMailActive"
            },
            -- 并确保身上也有被动Buff(如角色出生自带，也可在此加)
            {
                target_strategy = "self",
                buff_name = "BladeMailPassive"
            }
        }
    },

    -------------------------------------------------------
    -- 法术强化(SpellAmplify) - 被动
    -- 这里也可以当做主动=0秒CD,只要学了就存在
    -------------------------------------------------------
    SpellAmplifySkill = {
        cooldown = 0,
        mana_cost = 0,
        cast_time = 0,
        is_auto = false,
        passivelyGranted = true, -- 代表学此技能就得到对应Buff
        buffs = {
            {
                target_strategy = "self",
                buff_name = "SpellAmplifyPassive"
            }
        }
    },

    -------------------------------------------------------
    -- 血契(BloodPact) - 被动
    -------------------------------------------------------
    BloodPactSkill = {
        cooldown = 0,
        mana_cost = 0,
        cast_time = 0,
        passivelyGranted = true,
        buffs = {
            {
                target_strategy = "self",
                buff_name = "BloodPactPassive"
            }
        }
    },
    -- 荆棘
    ["ThornSkill"] = {
        cooldown = 10,
        mana_cost = 20,
        is_auto = false,
        buffs = {
            {
                target_strategy = "self",
                buff_name = "ThornBuff"
            }
        }
    },

    -- 雅顿"
    ["YadonSkill"] = {
        cooldown = 12,
        mana_cost = 50,
        is_auto = false,
        buffs = {
            {
                target_strategy = "selectArea",
                buff_name = "YadonCloudBuff"
            }
        }
    }
}

---------------------------
-- 4. Strategy definitions
---------------------------
battle_data.strategy_definitions = {
    closest_single = {
        script_file = "closest_single",
    },
    random_single = {
        script_file = "random_single",
    },
    self = {
        script_file = "self"
    },
    selectArea = {
        script_file = "select_area"
    }
}

---------------------------
-- 5. Special InstantBuff
--   “InstantBuff:XXX”
--   这里也可配置
---------------------------
-- InstantBuff =
--   并不真正存在buff持续时间，而是“挂载后立刻移除”，只执行其effects
--   方便表达一次性伤害、一次性治疗
battle_data.instant_buffs        = {
    HurtPhysical50 = {
        duration = 0.01,
        effects = {
            {
                effect_type = "hurt",
                trigger     = TriggerDef.TRIGGERS.ON_APPLY,
                damage_type = DamageDef.DAMAGES.PHYSICAL,
                base_damage = 50
            }
        }
    },
    FireDamageInstant = {
        duration = 0.01,
        effects = {
            {
                effect_type = "hurt",
                trigger     = TriggerDef.TRIGGERS.ON_APPLY,
                damage_type = DamageDef.DAMAGES.MAGICAL,
                base_damage = 100
            },
            {
                effect_type = "apply_buff",
                trigger     = TriggerDef.TRIGGERS.ON_APPLY,
                buff_name   = "SlowDebuff"
            }
        }
    }
}

return battle_data
