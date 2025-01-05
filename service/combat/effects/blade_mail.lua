-- effects/blade_mail.lua
-- trigger="onDamageTaken"时被调用
local damage_calc = require "damage_calc"
local logger      = require "battle_logger"
local EventDef    = require "event.event_def"


local blade_mail = {}

function blade_mail.execute(effConfig, caster, target, buffDef, originDamage)
    logger.info("[blade_mail] begin:", "", {
        accept_id = target.id,
        reflect_to = caster.id,
        effConfig = effConfig,
        base_damage_factor = originDamage.base_damage_factor,
        damage_type = originDamage.damage_type,
        no_reflect = originDamage.no_reflect,
    })
    -- effConfig: { reflect_physical=1.05, reflect_phys_fixed=10, reflect_other=0.85, ... }
    -- 这里 target= 受伤者（装备刃甲Buff的人）， caster= 伤害来源(由于 buffSystem:runEffect(eff,caster,target) 的逻辑可能相反，
    if not originDamage then
        return
    end

    -- 检查 “不反射标记” => 避免递归
    if originDamage.no_reflect then
        logger.info("[blade_mail] no_reflect return:", "", {
            accept_id = target.id,
            reflect_to = caster.id
        })
        return
    end

    local reflectRatio = effConfig.reflect_percent

    -- 先根据受到的真实伤害计算
    if originDamage.real == nil then
        logger.info("[blade_mail] originDamage.real == nil default:", "", {
            defaultReal = 100
        })
        originDamage.real = 100
    end
    local reflectDmg = math.floor((originDamage.real * reflectRatio))
    logger.info("[blade_mail] calc return valu:", "", {
        accept_id = target.id,
        reflect_to = caster.id,
        reflectRatio = reflectRatio,
        reflectDmg = reflectDmg
    })

    if reflectDmg <= 0 then
        return
    end

    local damageeEvent = {
        battle = target.battle,
        source = target,
        target = caster,
        -- todo 可以细分为反伤事件
        type = EventDef.EVENT_ACCEPT_DAMAGE,
        dmgInfo = {
            source_id          = target.id,
            target_id          = caster.id,
            base_damage_factor = 1,
            damage_type        = originDamage.damage_type,
            reflectDmg         = reflectDmg,
            no_reflect         = true, -- 不允许再被反射
            no_lifesteal       = true, -- 无法吸血
            no_spell_amp       = true, -- 不受法术增幅
        }
    }

    caster.battle.eventDispatcher:publishTo({ caster }, damageeEvent, "sync")
    logger.info("[blade_mail] execute FINISH!", "", {})
end

return blade_mail
