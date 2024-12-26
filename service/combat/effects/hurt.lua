-- effects/hurt.lua
local skynet = require "skynet"

local hurt = {}

function hurt.execute(effConfig, caster, target, skillOrBuff, elemMgr)
    -- effConfig: { damage_type="physical", base_damage=50, ... }
    local baseDmg = effConfig.base_damage or 0
    local dtype = effConfig.damage_type or "physical"
    local realDamage = caster:calculate_damage(baseDmg, dtype, target)
    target.attr:modify("HP", -realDamage)
    skynet.error(string.format("[HurtEffect] %s -> %s deal %d %sDamage", caster.id, target.id, realDamage, dtype))
end

return hurt
