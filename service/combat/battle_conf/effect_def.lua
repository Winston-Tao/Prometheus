-- effect_def.lua
-- 用于统一管理可用的 effect_type、其参数，以及可能的错误提示
local EffectDef = {}

EffectDef.types = {
    MODIFY_ATTRIBUTE = "modify_attribute", -- 改属性
    HURT             = "hurt",             -- 伤害
    APPLY_BUFF       = "apply_buff",       -- 施加 Buff
    SUMMON_CREATURE  = "summon_creature",  -- 召唤生物
    -- 其他扩展: "knockback", "fear", "heal", ...
}

return EffectDef
