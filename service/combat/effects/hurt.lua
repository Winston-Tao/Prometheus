-- effects/hurt.lua
local logger   = require "battle_logger"
local EventDef = require "event.event_def"

local hurt     = {}

function hurt.execute(effConfig, caster, target, buffConfig)
    -- effConfig: { damage_type="physical", base_damage=50, ... }
    -- 包成伤害事件丢给目标
    local acceptDamageeEvent = {
        battle = target.battle,
        source = caster,
        target = target,
        type = EventDef.EVENT_ACCEPT_DAMAGE,
        dmgInfo = {
            source_id = caster.id,
            target_id = target.id,
            base_damage_factor = effConfig.base_damage_factor,
            damage_type = effConfig.damage_type or "physical",
            no_reflect = effConfig.no_reflect or false,
            no_lifesteal = effConfig.no_lifesteal or false,
            no_spell_amp = effConfig.no_spell_amp or false
        }
    }
    logger.info("[HurtEffect] execute", "", {
        effConfig = effConfig,
        dmgInfo = acceptDamageeEvent.dmgInfo
    })
    target.battle.eventDispatcher:publishTo({ target }, acceptDamageeEvent, "sync")
end

return hurt
