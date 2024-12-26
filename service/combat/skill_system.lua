-- skill_system.lua
local skynet = require "skynet"
local ElementManager = require "element_manager"

local SkillSystem = {}
SkillSystem.__index = SkillSystem

function SkillSystem:new(skill_names, elemMgr)
    local obj = setmetatable({}, self)
    obj.elemMgr = elemMgr
    obj.skills = {}
    obj.casting = nil -- 当前施法中的数据
    for _, sn in ipairs(skill_names or {}) do
        local def = obj.elemMgr:getSkillDefinition(sn)
        if def then
            obj.skills[sn] = {
                name = sn, cd_left = 0, definition = def
            }
        end
    end
    return obj
end

function SkillSystem:update(dt)
    -- 冷却递减
    for _, s in pairs(self.skills) do
        if s.cd_left > 0 then
            s.cd_left = math.max(0, s.cd_left - dt)
        end
    end
    -- 处理中断 or 前摇进度
    if self.casting then
        local castData = self.casting
        castData.timer = castData.timer - dt
        -- 如果被眩晕/沉默/中断 => break
        if self:is_interrupted(castData.caster) then
            skynet.error("[SkillSystem] cast interrupted =>", castData.skill_name)
            self.casting = nil
        else
            if castData.timer <= 0 then
                skynet.error("[SkillSystem] cast done =>", castData.skill_name)
                -- 施法完成, 真正执行Buff挂载
                self:do_apply_skill(castData.skill_name, castData.caster, castData.battlefield)
                self.casting = nil
            end
        end
    end
end

-- 判断中断
function SkillSystem:is_interrupted(caster)
    local canCast = caster.attr:get("CanCastSkill")
    if canCast and canCast < 0 then
        return true
    end
    -- 也可判断 stun/silence
    return false
end

function SkillSystem:cast(skill_name, caster, battlefield)
    local sdata = self.skills[skill_name]
    if not sdata then return false, "No skill" end
    if sdata.cd_left > 0 then return false, "CDing" end
    local def = sdata.definition
    if caster.attr:get("MP") < (def.mana_cost or 0) then
        return false, "NoMP"
    end

    -- 前摇 cast_time
    local ct = def.cast_time or 0
    local break_on_stun = (def.break_on_stun ~= false) -- 默认被stun打断
    skynet.error(string.format("[SkillSystem] start cast skill=%s ct=%.2f", skill_name, ct))
    -- 施法过程
    self.casting = {
        skill_name = skill_name,
        caster = caster,
        battlefield = battlefield,
        timer = ct,
        break_on_stun = break_on_stun,
    }
    -- 扣蓝 & CD
    sdata.cd_left = def.cooldown or 0
    caster.attr:modify("MP", -(def.mana_cost or 0))

    return true, "casting"
end

-- 真正执行: 挂载Buff
function SkillSystem:do_apply_skill(skill_name, caster, battlefield)
    local sdata = self.skills[skill_name]
    if not sdata then return end
    local def = sdata.definition
    for _, buffItem in ipairs(def.buffs or {}) do
        local strategyName = buffItem.target_strategy or "closest_single"
        local st = self.elemMgr:getStrategyModule(strategyName)
        if st and st.findTargets then
            local targets = st:findTargets(caster, def, battlefield)
            for _, t in ipairs(targets) do
                t.buffsys:apply_buff(buffItem.buff_name, caster, t)
            end
        end
    end
end

return SkillSystem
