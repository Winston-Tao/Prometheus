-- effects/blade_mail.lua
-- trigger="onDamageTaken"时被调用
local damage_calc = require "damage_calc"

local blade_mail = {}

function blade_mail.execute(effConfig, caster, target, buffDef, elemMgr)
    -- effConfig: { reflect_percent=..., reflect_fixed=..., reflect_only_attack=bool }
    local reflectPercent      = effConfig.reflect_percent or 0
    local reflectFixed        = effConfig.reflect_fixed or 0
    local reflect_only_attack = effConfig.reflect_only_attack or false

    local damageInfo          = buffDef.damageInfo
    if not damageInfo then return end

    -- 如果伤害类型非普通攻击 or 物理伤害 =>检查
    if reflect_only_attack then
        if damageInfo.origin_type ~= "attack" then
            return
        end
    end

    -- 计算反伤
    local reflectDmg = reflectFixed + math.floor(damageInfo.dealt * reflectPercent)
    if reflectDmg <= 0 then return end

    -- 构造 damageInfo
    local newDmg = {
        source = target, -- 反伤由target来造成
        target = damageInfo.source,
        amount = reflectDmg,
        damage_type = damageInfo.damage_type, -- 与收到伤害相同
        is_reflect = true,                   -- 标记不再二次反射
        no_lifesteal = true,                 -- 不允许吸血
        no_spell_amp = true,                 -- 不允许法术增幅
        origin_type = "blade_mail_reflect"
    }
    damage_calc:applyDamage(newDmg)
end

return blade_mail
