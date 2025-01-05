-- combatant.lua
local skynet          = require "skynet"
local BuffSystem      = require "buff_system"
local SkillSystem     = require "skill_system"
local AttributeSystem = require "attribute_system"
local EventDef        = require "event.event_def"
logger                = require "battle_logger"

local Combatant       = {}
Combatant.__index     = Combatant

function Combatant:new(entity_id, entity_data, elemMgr, battle)
    local obj = setmetatable({}, self)
    obj.id = entity_id
    local baseAttr = {
        HP = 300,
        MP = 100,
        Armor = 5,
        AttackSpeed = 1.0
        -- ... 你可以再加
    }
    -- 合并 entity_data.attributes
    if entity_data.attributes then
        for k, v in pairs(entity_data.attributes) do
            baseAttr[k] = v
        end
    end
    obj.attr = AttributeSystem:new(baseAttr)
    obj.battle = battle
    obj.skills = entity_data.skills
    obj.elemMgr = elemMgr
    obj.buffsys = BuffSystem:new(obj, elemMgr)
    obj.skillSys = SkillSystem:new(obj, elemMgr)

    obj.type = entity_data.type or "Hero"


    obj.onRegisterToBattle = function(self, battle)
        battle:subscribeEvent(EventDef.EVENT_BATTLE_TICK, self)
        --battle:subscribeEvent(EventDef.EVENT_ACCEPT_DAMAGE, self)
        --battle:subscribeEvent(EventDef.EVENT_ATTACK, self)
        --battle:subscribeEvent(EventDef.EVENT_INTERRUPT, self)
    end

    return obj
end

function Combatant:onEvent(eventType, eventData)
    logger.debug("[Combatant] onEvent =>", "", { eventType = eventType })
    if eventType == EventDef.EVENT_BATTLE_TICK then
        self:onTick(eventData.battle)
    end
    if eventType ~= EventDef.EVENT_BATTLE_TICK then
        logger.info("[Combatant] onEvent =>", "", { eventType = eventType })
    end
    -- 投递给子模块
    self.skillSys:onEvent(eventType, eventData)
    self.buffsys:onEvent(eventType, eventData)
end

function Combatant:onTick(dt, battlefield)
end

function Combatant:update(dt, battlefield)
    -- buff & skill system
    self.buffsys:update(dt)
    self.skillSys:update(dt)
    -- 如果自动技能: 释放
    self:auto_cast(dt, battlefield)
end

-- 计算伤害
function Combatant:calculate_damage(rawDamage, damage_type, target)
    if damage_type == "physical" then
        local armor = target.attr:get("Armor") or 0
        local reduction = armor / (armor + 100)
        return math.floor(rawDamage * (1 - reduction))
    elseif damage_type == "magical" then
        local mr = target.attr:get("MagicResist") or 0.25
        return math.floor(rawDamage * (1 - mr))
    elseif damage_type == "pure" then
        return rawDamage
    end
    return rawDamage
end

-- 手动释放
function Combatant:release_skill(skill_name)
    return self.skillSys:cast(skill_name, self)
end

-- 自动施法
function Combatant:auto_cast(dt, battlefield)
    for name, sdata in pairs(self.skillSys.skills) do
        local def = sdata.definition
        if def and def.is_auto then
            -- 尝试释放
            local can, msg = self.skillSys:cast(name, self, battlefield)
            if can then
                skynet.error(string.format("[AutoCast] %s cast skill:%s", self.id, name))
            end
        end
    end
end

return Combatant
