-- skill_system.lua
local skynet        = require "skynet"

local EventConsumer = require "event.event_consumer"
local EventDef      = require "event.event_def"
local logger        = require "battle_logger"

local SkillSystem   = {}
SkillSystem.__index = SkillSystem

function SkillSystem:new(combatant, elemMgr)
    -- 调用父类构造函数
    local obj = setmetatable(EventConsumer:new() or {}, self)
    self.__index = self

    -- 初始化属性
    obj.elemMgr = elemMgr
    obj.owner = combatant
    obj.skills = {}

    -- 加载技能
    if combatant and type(combatant.skills) == "table" then
        obj:loadSkills(combatant.skills)
    else
        logger.error("[SkillSystem:new] Invalid or missing combatant.skills =》", type(combatant.skills))
    end
    logger.info("[SkillSystem:new] combatant SkillSystem init", "battle", {
        id = combatant.id
    })
    return obj
end

function SkillSystem:loadSkills(skill_names)
    -- 检查 skill_names 是否为有效表
    if type(skill_names) ~= "table" then
        logger.error(string.format("[SkillSystem:loadSkills] Owner ID: %s, Skills: [None]",
            tostring(self.owner and self.owner.id or "Unknown")))
        return
    end

    -- 打印技能列表
    local skill_names_str = table.concat(skill_names, ", ")
    logger.info(string.format("[SkillSystem:loadSkills] Owner ID: %s, Skills: [%s]",
        tostring(self.owner and self.owner.id or "Unknown"), skill_names_str), "", {
        id = self.owner.id,
        skill_names = skill_names_str
    })

    -- 加载技能
    for _, sn in ipairs(skill_names) do
        local def = self.elemMgr and self.elemMgr.getSkillDefinition and self.elemMgr:getSkillDefinition(sn)
        if def then
            self.skills[sn] = {
                name = sn,
                cd_left = 0,
                definition = def,
                casting = nil
            }
            logger.info(string.format("[SkillSystem:loadSkills] Owner ID: %s, Skills: [%s]",
                tostring(self.owner and self.owner.id or "Unknown"), sn), "", {
                id = self.owner.id,
                skill_name = sn
            })
        else
            logger.error(string.format("[SkillSystem:loadSkills] Skill definition not found for: %s", sn))
        end
    end
end

---- 订阅事件
--function SkillSystem:onRegisterToBattle(battle)
--    -- 订阅 BATTLE_TICK
--    battle:subscribeEvent(EventDef.EVENT_BATTLE_TICK, self)
--    -- 如果想监听 SKILL_CAST等也可以
--end

-- 事件回调：收到 "event_interrupt_skill"
function SkillSystem:onEvent(eventType, eventData)
    logger.debug("[SkillSystem] onEvent =>", "", { eventType = eventType })
    if eventType == EventDef.EVENT_BATTLE_TICK then
        self:onTick(eventData.battle)
    elseif eventType == EventDef.EVENT_INTERRUPT_SKILL then
        -- 如果当前在施法 -- 后续还可以从事件中传递更多参数 比如被谁打断等。。
        if self.casting and self.casting.caster == eventData.target then
            logger.info("[SkillSystem] cast interrupted =>", {
                caster = self.casting.caster.id,
                skill_name = self.casting.skill_name,
                reason = eventData.reason or "unknown"
            })
            self.casting = nil
        end
    end
end

function SkillSystem:onTick(battle)
    local dt = battle.tickInterval
    -- 冷却递减
    for _, s in pairs(self.skills) do
        if s.cd_left > 0 then
            s.cd_left = math.max(0, s.cd_left - dt)
        end
    end
    -- 施法完成判断
    if self.casting then
        local castData = self.casting
        castData.timer = castData.timer - dt
        if castData.timer <= 0 then
            logger.info("[SkillSystem] cast done => do_apply_skill", {
                caster = castData.caster.id,
                skill_name = castData.skill_name
            })
            self:do_apply_skill(castData.skill_name, castData.caster, castData.battlefield)
            self.casting = nil
        end
    end
end

-- 以往 self:is_interrupted(...) 改为事件通知
function SkillSystem:castInterrupt(caster, reason)
    local eventData = {
        target = caster,
        reason = reason,
    }
    local dispatcher = caster.battle.eventDispatcher
    dispatcher:publish(EventDef.EVENT_INTERRUPT_SKILL, eventData)
end

function SkillSystem:cast(skill_name, caster)
    local sdata = self.skills[skill_name]
    if not sdata then
        logger.error("[SkillSystem] release_skill fail: No skill", "battle", {
            caster_id = caster.id, skill_name = skill_name
        })
        return false, "No skill"
    end
    if sdata.cd_left > 0 then return false, "CDing" end
    local def = sdata.definition
    if caster.attr:get("MP") < (def.mana_cost or 0) then
        logger.debug("[SkillSystem] release_skill fail: NoMP", "battle", {
            caster_id = caster.id, skill_name = skill_name
        })
        return false, "NoMP"
    end

    -- 前摇 cast_time
    local ct = def.cast_time or 0
    local break_on_stun = (def.break_on_stun ~= false) -- 默认被stun打断

    -- 施法过程
    self.casting = {
        skill_name = skill_name,
        caster = caster,
        battlefield = caster.battle,
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
