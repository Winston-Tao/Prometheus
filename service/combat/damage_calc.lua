-- damage_calc.lua
-- 集中处理 伤害类型、标记、反射限制 等
local damage_calc = {}

-- 核心函数:
--   damage_calc:applyDamage(damageInfo)
-- damageInfo包含:
--   source, target, amount, damage_type, is_reflect, no_lifesteal, no_spell_amp, ...
--   由 effect / buff 调用, 并最终修改 target HP

function damage_calc:applyDamage(dmg)
    -- 1) 如果 target是无敌/技能免疫,可在此判断
    if dmg.target.attr:get("HP") <= 0 then
        return 0
    end

    -- 2) 计算具体减伤, block,闪避...
    local real = dmg.amount
    if dmg.damage_type == "physical" then
        -- armor
        local armor = dmg.target.attr:get("Armor") or 0
        local r = armor / (100 + armor)
        real = math.floor(real * (1 - r))
        -- 还有可能伤害格挡 block
    elseif dmg.damage_type == "magical" then
        if not dmg.no_spell_amp then
            -- 可能被 "SpellAmplify"增幅
            local amp = dmg.source.attr:get("SpellDamageAmp") or 1.0
            real = math.floor(real * amp)
        end
        local mr = dmg.target.attr:get("MagicResist") or 0.25
        real = math.floor(real * (1 - mr))
    elseif dmg.damage_type == "pure" then
        -- pure伤害不受减免
    end

    -- 3) 扣血
    dmg.target.attr:modify("HP", -real)

    -- 4) 如果不是 no_lifesteal, 并source有skill吸血(如 BloodPact)
    if not dmg.no_lifesteal and (dmg.source.attr:get("SkillLifeSteal") > 0) then
        local ls = dmg.source.attr:get("SkillLifeSteal")
        local heal = math.floor(real * ls)
        dmg.source.attr:modify("HP", heal)
    end

    -- 5) 伤害反射标记 is_reflect: 不再二次反射
    -- ...
    return real
end

return damage_calc
