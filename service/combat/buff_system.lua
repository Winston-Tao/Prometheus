-- buff_system.lua
local skynet = require "skynet"
local ElementManager = require "element_manager"

local BuffSystem = {}
BuffSystem.__index = BuffSystem

function BuffSystem:new(owner, elemMgr)
    local obj = setmetatable({}, self)
    obj.owner = owner
    obj.elemMgr = elemMgr -- 引用ElementManager
    obj.buffs = {}        -- { [id] = { name=..., remaining=..., effects=... } }
    obj.next_id = 1
    return obj
end

function BuffSystem:update(dt)
    for buff_id, buffData in pairs(self.buffs) do
        buffData.remaining = buffData.remaining - dt
        if buffData.remaining <= 0 then
            self:remove_buff(buff_id, "timeout")
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

function BuffSystem:apply_buff(buff_name, caster, target)
    local def = self.elemMgr:getBuffDefinition(buff_name)
    if not def then
        skynet.error("[BuffSystem] no buff definition:", buff_name)
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
            skynet.error("[BuffSystem] refresh buff:", buff_name)
            return
        elseif overlap == "discard" then
            skynet.error("[BuffSystem] discard new apply buff:", buff_name)
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

    skynet.error(string.format("[BuffSystem] apply buff:%s => target:%s", buff_name, target.id))

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
    skynet.error(string.format("[BuffSystem] remove buff:%s from:%s reason:%s", bData.name, self.owner.id, reason))
end

return BuffSystem
