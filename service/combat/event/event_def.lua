-- event/event_def.lua
local EventDef               = {}

EventDef.EVENT_ACCEPT_DAMAGE = "event_accept_damage"
EventDef.EVENT_SKILL_CAST    = "event_skill_cast"
EventDef.EVENT_BATTLE_TICK   = "event_battle_tick"
EventDef.EVENT_ATTACK        = "event_attack"
EventDef.EVENT_INTERRUPT     = "event_interrupt_skill"
-- 其他事件需求可扩展

return EventDef
