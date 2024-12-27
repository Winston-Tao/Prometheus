-- config.lua
local config = {}

-------------------------------------------------------------------------------
-- 通用设置
-------------------------------------------------------------------------------
config.max_battles_per_service = 5

-------------------------------------------------------------------------------
-- 属性配置
-- 这部分可扩展出力量(STR)、敏捷(AGI)、智力(INT)等, 并影响衍生属性
-------------------------------------------------------------------------------
config.default_attributes = {
    STR         = 20, -- 力量
    AGI         = 20, -- 敏捷
    INT         = 20, -- 智力
    HP          = 500,
    MP          = 300,
    Armor       = 10,
    MoveSpeed   = 300,
    AttackSpeed = 1.0,  -- 攻击间隔(秒)
    MagicResist = 0.25, -- 基础魔抗，减少25%魔法伤害
}

-------------------------------------------------------------------------------
-- 技能配置
-- 每种技能包含：CD、伤害类型、状态效果、消耗等
-------------------------------------------------------------------------------
config.skill_templates = {
    -- 1. 普通物理打击 skill
    ["PhysicalAttack"] = {
        name = "PhysicalAttack",
        cooldown = 1, -- 冷却1秒
        mana_cost = 0,
        range = 150,
        damage_type = "physical",
        base_damage = 50,
        apply_effects = {}, -- 普通攻击没有附加buff
        is_auto = true,     -- 标识可由AI自动使用
    },
    -- 2. 火球术 FireBall
    ["FireBall"] = {
        name = "FireBall",
        cooldown = 5,
        mana_cost = 50,
        range = 600,
        damage_type = "magical",
        base_damage = 120,
        apply_effects = {
            -- 附加一个减速效果Buff
            { buff_name = "SlowDebuff" }
        },
        is_auto = false, -- 手动技能(需要显式触发)
    },
    -- 3. 吸血鬼一击 VampireStrike
    ["VampireStrike"] = {
        name = "VampireStrike",
        cooldown = 8,
        mana_cost = 30,
        range = 150,
        damage_type = "physical",
        base_damage = 70,
        lifesteal_percent = 0.3, -- 吸血30%
        apply_effects = {},      -- 不带额外buff
        is_auto = true,
    },
}

-------------------------------------------------------------------------------
-- Buff配置
-------------------------------------------------------------------------------
config.buff_templates = {
    -- 减速Debuff
    ["SlowDebuff"] = {
        name = "SlowDebuff",
        duration = 3, -- 3秒
        effects = {
            -- 减移动速度、减攻击速度
            { effect_type = "modify_attribute", attr = "MoveSpeed",   value = -100 },
            { effect_type = "modify_attribute", attr = "AttackSpeed", value = -0.3 },
        },
        overlap = "refresh", -- 同样的Debuff再次施加时刷新时长
    },
    -- 晕眩Stun
    ["StunDebuff"] = {
        name = "StunDebuff",
        duration = 2,
        effects = {
            -- stun可表示成： AttackSpeed=0, MoveSpeed=0, Silenced = true 等
            { effect_type = "stun", value = true },
        },
        overlap = "discard", -- 不叠加
    },
    -- 流血Dot (持续伤害)
    ["BleedDot"] = {
        name = "BleedDot",
        duration = 5,
        effects = {
            -- 每秒造成 20 物理伤害
            { effect_type = "damage_over_time", damage_type = "physical", damage_per_tick = 20, tick_interval = 1 },
        },
        overlap = "stack", -- 可以叠加(多层流血)
    },
}

return config
