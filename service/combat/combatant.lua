-- combatant.lua
local skynet = require "skynet"
local BuffSystem = require "buff_system"
local SkillSystem = require "skill_system"
local AttributeSystem = require "attribute_system"

local Combatant = {}
Combatant.__index = Combatant

function Combatant:new(entity_id, entity_data, elemMgr)
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

    obj.elemMgr = elemMgr
    obj.buffsys = BuffSystem:new(obj, elemMgr)
    obj.skillSys = SkillSystem:new(entity_data.skills, elemMgr)

    obj.type = entity_data.type or "Hero"
    return obj
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
function Combatant:release_skill(skill_name, battlefield)
    return self.skillSys:cast(skill_name, self, battlefield)
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
