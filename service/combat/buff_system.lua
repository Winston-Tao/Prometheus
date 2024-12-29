-- buff_system.lua
local skynet       = require "skynet"

local EventDef     = require "event.event_def"
local damage_calc  = require "damage_calc"
local logger       = require "battle_logger"

local BuffSystem   = {}
BuffSystem.__index = BuffSystem

function BuffSystem:new(owner, elemMgr)
    local obj = setmetatable({}, self)
    obj.owner = owner
    obj.elemMgr = elemMgr -- 引用ElementManager
    obj.buffs = {}        -- { [id] = { name=..., remaining=..., effects=... } }
    obj.next_id = 1
    return obj
end

--function BuffSystem:onRegisterToBattle(battle)
--    battle:subscribeEvent(EventDef.EVENT_BATTLE_TICK, self)
--end

function BuffSystem:onEvent(eventType, eventData)
    if eventType == EventDef.EVENT_ACCEPT_DAMAGE then
        self:onAcceptDamageEvent(eventData)
    elseif eventType == EventDef.EVENT_BATTLE_TICK then
        self:onTick(eventData)
    end
end

function BuffSystem:onTick(eventData)
    local dt = eventData.battle.tickInterval
    for buff_id, buffData in pairs(self.buffs) do
        buffData.remaining = buffData.remaining - dt
        if buffData.remaining <= 0 then
            self:remove_buff(buff_id, "timeout")
            logger.debug("[BuffSystem] remove_buff:", "", {
                id = self.owner.id, apply_buff = buff_id })
        else
            -- 每秒/指定tick执行
            for _, eff in ipairs(buffData.definition.effects or {}) do
                if eff.trigger == "onTick" then
                    buffData.tick_timers[eff] = (buffData.tick_timers[eff] or eff.tick_interval or 1) - dt
                    if buffData.tick_timers[eff] <= 0 then
                        self.elemMgr:runEffect(eff, buffData.caster, self.owner, buffData.definition)
                        buffData.tick_timers[eff] = eff.tick_interval or 1
                    end
                end
            end
        end
    end
end

function BuffSystem:onAcceptDamageEvent(evt)
    logger.info("[BuffSystem] onAcceptDamageEvent:", "", {
        accept_id = self.owner.id,
        dmgInfo = evt.dmgInfo
    })
    -- evt={ battle, source, target, dmgInfo }
    -- self.owner受到伤害
    local di = evt.dmgInfo
    -- 先计算实际伤害
    local originDamage = {
        source = evt.source,
        target = self.owner,
        base_damage_factor = di.base_damage_factor,
        damage_type = di.damage_type,
        no_reflect = di.no_reflect,
        no_lifesteal = di.no_lifesteal,
        no_spell_amp = di.no_spell_amp,
        reflectDmg = di.reflectDmg
    }
    local realDamage = damage_calc:applyDamage(originDamage)
    originDamage.real = realDamage
    di.dealt = realDamage
    -- 伤害完成后, Buff检查onDamageTaken
    -- todo 这里需要检查 no_reflect no_lifesteal no_spell_amp 比如不能再执行反弹的effect
    for _, buff in pairs(self.buffs) do
        for _, eff in ipairs(buff.definition.effects or {}) do
            -- todo 传参后续再优化下 被事件触发的 effect 应该有更优雅的传参方式，默认effect就能取到触发事件更好，这里先写死了
            if eff.trigger == "onDamageTaken" then
                buff.tempDamageInfo = di
                self.elemMgr:runEffect(eff, evt.source, self.owner, buff.definition, originDamage)
                buff.tempDamageInfo = nil
            end
        end
    end
end

function BuffSystem:apply_buff(buff_name, caster, target)
    local def = self.elemMgr:getBuffDefinition(buff_name)
    if not def then
        logger.error("[BuffSystem] no buff definition:", buff_name)
        return
    end

    -- 处理“instantBuff”特性
    local is_instant  = def.is_instant
    local duration    = def.duration or 0
    local overlap     = def.overlap or "discard"

    -- 如果已有同名Buff
    local existing_id = nil
    for id, bData in pairs(self.buffs) do
        if bData.name == buff_name then
            existing_id = id
            break
        end
    end
    if existing_id then
        if overlap == "refresh" then
            self.buffs[existing_id].remaining = duration
            logger.info("[BuffSystem] refresh buff:", "", {
                id = self.owner.id,
                buff_id = existing_id
            })
            return
        elseif overlap == "discard" then
            logger.info("[BuffSystem] discard buff:", "", {
                id = self.owner.id,
                buff_id = existing_id
            })
            return
        elseif overlap == "stack" then
            -- 继续叠加 => 不移除
        end
    end

    local buff_id = self.next_id
    self.next_id = buff_id + 1
    local newData = {
        id          = buff_id,
        name        = buff_name,
        definition  = def, -- BuffDefinition
        remaining   = duration,
        caster      = caster,
        tick_timers = {}
    }
    self.buffs[buff_id] = newData

    -- 立即触发 onApply
    for _, eff in ipairs(def.effects or {}) do
        if (eff.trigger == "onApply") or (not eff.trigger) then
            self.elemMgr:runEffect(eff, caster, target, def)
        end
    end

    logger.info(string.format("[BuffSystem] apply buff:%s => target:%s", buff_name, target.id))

    if is_instant then
        -- 立即移除 => OneShot
        self:remove_buff(buff_id, "instant_done")
    end
end

function BuffSystem:remove_buff(buff_id, reason)
    local bData = self.buffs[buff_id]
    if not bData then return end

    -- onRemove
    for _, eff in ipairs(bData.definition.effects or {}) do
        if eff.trigger == "onRemove" then
            self.elemMgr:runEffect(eff, bData.caster, self.owner, bData.definition)
        end
    end
    self.buffs[buff_id] = nil
    logger.error(string.format("[BuffSystem] remove buff:%s from:%s reason:%s", bData.name, self.owner.id, reason))
end

return BuffSystem
