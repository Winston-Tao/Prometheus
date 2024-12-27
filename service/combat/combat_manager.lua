-- combat_manager.lua
-- combat_manager.lua
local skynet = require "skynet"
local Combatant = require "combat.combatant"
local damage_calc = require "damage_calc"
local Battle = require "battle"
local logger = require "battle_logger"

local CombatManager = {}
CombatManager.__index = CombatManager

function CombatManager:new(manager_id)
    local obj = setmetatable({}, self)
    obj.manager_id = manager_id -- 唯一编号
    obj.battles = {}
    obj.next_battle_id = 1
    return obj
end

function CombatManager:createBattle(mapSize)
    local bid = self.next_battle_id
    self.next_battle_id = bid + 1
    local battle = Battle:new(bid, mapSize)
    self.battles[bid] = battle
    return battle
end

function CombatManager:getBattle(bid)
    return self.battles[bid]
end

function CombatManager:removeBattle(bid)
    self.battles[bid] = nil
end

function CombatManager:add_combatant(battle_id, entity_id, entity_data)
    local b = self.battles[battle_id]
    if not b then return nil end
    local c = Combatant:new(entity_id, entity_data, self.elemMgr)
    table.insert(b.combatants, c)
    skynet.error(string.format("[CombatManager] add_combatant => battle:%d, id:%s", battle_id, entity_id))
    return entity_id
end

function CombatManager:start_battle(battle_id)
    local b = self.battles[battle_id]
    if not b then return end
    if b.is_active then
        skynet.error("[CombatManager] battle already active:", battle_id)
        return
    end
    b.is_active = true
    skynet.fork(function()
        self:battle_loop(battle_id)
    end)
    skynet.error("[CombatManager] start battle:", battle_id)
end

function CombatManager:battle_loop(battle_id)
    local dt = 1
    local b = self.battles[battle_id]
    while b and b.is_active do
        skynet.sleep(dt * 100)
        -- update each
        for _, c in ipairs(b.combatants) do
            if c.attr:get("HP") > 0 then
                c:update(dt, b)
            end
        end
        -- 检查结束
        if self:check_end(b) then
            b.is_active = false
            skynet.error(string.format("[CombatManager:battle_id] %d end", battle_id))
            break
        end
    end
end

-- 攻击/伤害流程(可由auto attack or effect call)
function CombatManager:applyDamage(source, target, rawDamage, dmgType, originType)
    -- 1) 构造 damageInfo
    local info = {
        source = source,
        target = target,
        amount = rawDamage,
        damage_type = dmgType,
        origin_type = originType or "attack",
        is_reflect = false,
        no_lifesteal = false,
        no_spell_amp = false,
        dealt = 0 --实际造成多少
    }
    -- 2) apply
    local real = damage_calc:applyDamage(info)
    info.dealt = real
    -- 3) 通知target Buff: "onDamageTaken"
    for _, buff in pairs(target.buffsys.buffs) do
        for _, eff in ipairs(buff.definition.effects or {}) do
            if eff.trigger == "onDamageTaken" then
                buff.definition.damageInfo = info --临时记录
                self.elemMgr:runEffect(eff, source, target, buff.definition)
                buff.definition.damageInfo = nil
            end
        end
    end
    return real
end

function CombatManager:check_end(battle)
    local hero_alive = false
    local enemy_alive = false
    for _, c in ipairs(battle.combatants) do
        local hp = math.tointeger(c.attr:get("HP")) or 0
        skynet.error(string.format("[CombatManager:check_end] Combatant Type: %s, HP: %d", c.type, hp))
        if hp > 0 then
            if c.type == "Hero" then
                hero_alive = true
            elseif c.type == "Enemy" then
                enemy_alive = true
            end
        end
    end
    return (not hero_alive) or (not enemy_alive)
end

-- 手动施法
function CombatManager:release_skill(battle_id, caster_id, skill_name, target_id)
    skynet.error("[DEBUG] bid222:", battle_id, caster_id, skill_name, target_id)
    local battle = self:getBattle(battle_id);
    battle:release_skill(caster_id, skill_name, target_id)
end

--------------------------------------
-- Skynet service part
--------------------------------------
local CMD = {}

function CMD.init(mgr, manager_id)
    mgr.manager_id = manager_id
end

function CMD.create_battle(mgr, mapSize)
    local b = mgr:createBattle(mapSize)
    skynet.retpack(b.id)
end

function CMD.add_combatant(mgr, bid, cdata)
    local battle = mgr:getBattle(bid)
    if not battle then return nil end
    local c = battle:addCombatant(cdata)
    skynet.retpack(c.id)
end

function CMD.start_battle(mgr, bid)
    local b = mgr:getBattle(bid)
    if b then
        b:start()
        skynet.retpack("ok")
    else
        skynet.retpack("fail")
    end
end

function CMD.destroy_battle(mgr, bid)
    mgr:removeBattle(bid)
    skynet.retpack("ok")
end

function CMD.release_skill(mgr, battle_id, caster_id, skill_name, target_id)
    skynet.error("[DEBUG] bid111:", battle_id, caster_id, skill_name, target_id)
    mgr:release_skill(battle_id, caster_id, skill_name, target_id)
    skynet.retpack("ok")
end

--------------------------------------------------------------------------------
skynet.start(function()
    logger.init() -- 初始化日志系统
    local manager = CombatManager:new(nil)
    -- 注册自己到router
    skynet.send(".serverRouter", "lua", "register_service", "combat_manager", skynet.self())
    skynet.error("combat_manager-register_service-success")
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = CMD[cmd]
        if f then
            f(manager, ...)
        else
            skynet.error("[combat_manager] Unknown cmd:", cmd)
            skynet.ret()
        end
    end)

    skynet.error("[combat_manager] Service started.")
end)
