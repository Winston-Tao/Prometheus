-- battle.lua
local skynet          = require "skynet"
local EventDispatcher = require "event.event_dispatcher"
local EventDef        = require "event.event_def"
local Combatant       = require "combat.combatant"
local ElementManager  = require "element_manager"
local logger          = require "battle_logger"

local Battle          = {}
Battle.__index        = Battle

function Battle:new(battle_id, mapSize)
    local obj = setmetatable({}, self)
    obj.id = battle_id
    obj.mapSize = mapSize or 10 -- NxN
    obj.combatants = {}
    obj.is_active = false

    obj.eventDispatcher = EventDispatcher:new("sync")
    obj.tickInterval = 1 -- 1秒
    logger.debug("Battle", "create", obj)
    return obj
end

-- 注册事件消费者
function Battle:subscribeEvent(eventType, consumer)
    self.eventDispatcher:subscribe(eventType, consumer)
end

-- 启动战场(使用事件驱动)
function Battle:start()
    self.is_active = true
    skynet.fork(function()
        while self.is_active do
            skynet.sleep(self.tickInterval * 100)
            -- 发布 BATTLE_TICK 事件
            skynet.error("[battle] publish EventDef.EVENT_BATTLE_TICK.")
            self.eventDispatcher:publish(EventDef.EVENT_BATTLE_TICK, { battle = self })
            self:checkEnd()
        end
    end)
end

function Battle:checkEnd()
    local heroAlive, enemyAlive = false, false
    local hpInfo = {} -- 用于存储战斗者的 HP 信息

    for _, c in ipairs(self.combatants) do
        local hp = c.attr:get("HP")
        hpInfo[c.id] = { type = c.type, hp = hp } -- 假设 c 有一个唯一的 id 属性

        if hp > 0 then
            if c.type == "Hero" then
                heroAlive = true
            elseif c.type == "Enemy" then
                enemyAlive = true
            end
        end
    end

    -- 打印 HP 信息
    for id, info in pairs(hpInfo) do
        skynet.error(string.format("[Battle] Combatant ID: %s, Type: %s, HP: %d", id, info.type, info.hp))
    end

    -- 检查战斗是否结束
    if (not heroAlive) or (not enemyAlive) then
        self.is_active = false
        skynet.error(string.format("[Battle] end => %s", self.id))
    else
        skynet.error("[Battle] checkEnd false")
    end
end

function Battle:addCombatant(combatant)
    skynet.error("[Battle:addCombatant] combatant.id =》", combatant.id, type(combatant.skills))
    -- todo ElementManager:new()
    local realCom = Combatant:new(combatant.id, combatant, ElementManager:new(), self)
    -- 插入到 combatants 列表中
    table.insert(self.combatants, realCom)

    -- 调用 `onRegisterToBattle`
    realCom:onRegisterToBattle(self)

    return realCom
end

-- 手动施法
function Battle:release_skill(caster_id, skill_name, target_id)
    local caster, target
    for _, c in ipairs(self.combatants) do
        if tostring(c.id) == tostring(caster_id) then
            caster = c
        end
        if tostring(c.id) == tostring(target_id) then
            target = c
        end
    end
    if not caster then
        skynet.error("[CombatManager] no caster", caster_id)
        return
    end
    local can, msg = caster:release_skill(skill_name)
    if can then
        skynet.error("[CombatManager] manual skill success:", skill_name, "by", caster_id)
    else
        skynet.error("[CombatManager] manual skill fail:", skill_name, msg)
    end
end

-- 对外伤害接口 => 发布伤害事件
function Battle:applyDamage(source, target, dmgInfo)
    -- dmgInfo = { amount, damage_type, origin_type, ... }
    local eventData = {
        battle = self,
        source = source,
        target = target,
        dmgInfo = dmgInfo
    }
    -- 发布 DAMAGE事件
    self.eventDispatcher:publish(EventDef.EVENT_DAMAGE, eventData)
end

return Battle
