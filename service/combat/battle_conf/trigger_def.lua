-- trigger_def.lua
-- 统一管理可用的触发点
local TriggerDef = {}

TriggerDef.TRIGGERS = {
    ON_APPLY        = "onApply",       -- Buff挂载时立即执行
    ON_REMOVE       = "onRemove",      -- Buff移除时
    ON_TICK         = "onTick",        -- 每秒(或每回合)触发
    ON_DAMAGE_TAKEN = "onDamageTaken", -- 受到伤害时
    ON_ATTACK       = "onAttack",      -- 发起攻击时
    ON_CAST         = "onCast",        -- 施放技能时
    -- 更多可扩展: "onCriticalHit", "onEnterScene", ...
}

return TriggerDef
