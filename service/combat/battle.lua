--------------------------------------------------------------------------------
-- battle.lua
-- 不再 fork while；改用 :setupSchedule() + :doFrame() => 由上层调度器调度
--------------------------------------------------------------------------------
local skynet          = require "skynet"
local EventDispatcher = require "event.event_dispatcher"
local EventDef        = require "event.event_def"
local Combatant       = require "combat.combatant"
local ElementManager  = require "element_manager"
local battle_params   = require "battle_segment"
local logger          = require "battle_logger"

-- 模拟 战斗 高负载计算
local function cpu_heavy_task()
    local count = 0
    while true do
        count = count + 1
        -- 可以在这里添加一些复杂的计算以增加负载
        local x = math.sin(count) * math.cos(count)
        local y = math.sin(count) / math.cos(count)
        local c = x * y
        -- 可以选择适当的退出条件
        if count > 1e4 then -- 这里设置一个退出条件，避免无限循环
            break
        end
    end
end


local function formatTimestamp(ts)
    local sec     = math.floor(ts)
    local msec    = math.floor((ts - sec) * 1000)
    local dateStr = os.date("%Y-%m-%d %H:%M:%S", sec)
    return string.format("%s.%03d", dateStr, msec)
end

local Battle   = {}
Battle.__index = Battle

function Battle:new(bid, mapSize, battleMgr, delay)
    local obj = setmetatable({}, self)
    obj.id = bid
    obj.mapSize = mapSize or 10
    obj.combatants = {}
    obj.is_active = false
    obj.battleMgr = battleMgr

    -- 事件
    obj.eventDispatcher = EventDispatcher:new("sync")

    -- 用于技能cd
    obj.tickInterval = 1

    -- 帧时序
    obj.beginms = math.floor(skynet.time() * 1000) + delay -- 可以再加startDelay
    -- -- 预估执行时间(可随执行测量更新)
    obj.wcet = obj.beginms
    obj.count = 0
    obj.frame_duration = battle_params.FRAME_DURATION
    logger.info("Battle:new", "battle", {
        id = obj.id,
        time = formatTimestamp(skynet.time()),
        delay = delay
    })
    return obj
end

-- 注册事件消费者
function Battle:subscribeEvent(eventType, consumer)
    self.eventDispatcher:subscribe(eventType, consumer)
end

-- 让Battle知道如何把"下一帧任务"注册到调度器，以及如何汇报deltaT信息
function Battle:setupSchedule(pushTaskFunc, frameDoneFunc)
    self.pushTaskFunc  = pushTaskFunc
    self.frameDoneFunc = frameDoneFunc
end

function Battle:addCombatant(combatant)
    skynet.error("[Battle:addCombatant] combatant.id =》", combatant.id, type(combatant.skills))
    -- todo ElementManager:new()
    local realCom = Combatant:new(combatant.id, combatant, ElementManager:new(), self)
    -- 插入到 combatants 列表中
    table.insert(self.combatants, realCom)

    -- 调用 `onRegisterToBattle`
    realCom:onRegisterToBattle(self)
    logger.debug("[Battle] addCombatant", "battle", {
        id = realCom.id,
        type = realCom.type,
        attributes = realCom.ttributes,
        skills = realCom.skills,
    })
    self.battleMgr.monitor:updateCombatantCount(self.id, #self.combatants)
    return realCom
end

function Battle:getNextFrameTime()
    return self.beginms + self.count * self.frame_duration
end

function Battle:doFrame()
    local now = math.floor(skynet.time() * 1000)
    logger.info("[Battle:doFrame] begin", "battle", {
        battle_id = self.id,
        frame = self.count
    })
    if not self.is_active then return end

    local deltaT = now - self.wcet

    local st = now
    self.count = self.count + 1
    -- 发布事件 => AI / Buff / ...
    self.eventDispatcher:publish(EventDef.EVENT_BATTLE_TICK, { battle = self })

    self:checkEnd()

    -- 若尚未结束 => 推送下一帧任务
    if self.is_active then
        local nextFrameTime = self:getNextFrameTime()
        -- 追帧: 如果 deltaT> battle_params.CHASE_THRESHOLD => nextFrameTime= now
        if deltaT > battle_params.CHASE_THRESHOLD then
            nextFrameTime = now
        end
        self.pushTaskFunc(nextFrameTime, function()
            self:doFrame()
        end)
        self.wcet = nextFrameTime
    end

    -- 先模拟计算时间
    cpu_heavy_task()

    -- todo 如果结束，需要执行战场结算

    local calcTime = math.floor(skynet.time() * 1000) - st
    -- 回调给manager, 做统计
    if self.frameDoneFunc then
        self.frameDoneFunc(self.id, deltaT, calcTime)
    end

    if not self.is_active then
        -- 战场销毁
        self.battleMgr:removeBattle(self.id)
    end
end

function Battle:checkEnd()
    local heroAlive, enemyAlive = false, false
    for _, c in ipairs(self.combatants) do
        local hp = c.attr:get("HP")
        if hp > 0 then
            if c.type == "Hero" then
                heroAlive = true
            elseif c.type == "Enemy" then
                enemyAlive = true
            end
        end
    end
    if (not heroAlive) or (not enemyAlive) or (self.count >= battle_params.MAX_FRAME_COUNT) then
        self.is_active = false
        logger.debug(string.format("[Battle %d] battle end => frame=%d", self.id, self.count), "battle", {
            heroAlive = heroAlive,
            enemyAlive = enemyAlive,
            count = self.count
        })
    end
end

function Battle:release_skill(caster_id, skill_name, target_id)
    logger.debug("Battle:release_skill", "battle", { id = caster_id, skill_name = skill_name, target_id = target_id })
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
        logger.error(string.format("[Battle %d] release_skill no caster %s", self.id, caster_id), "battle")
        return
    end
    caster:release_skill(skill_name, target)
end

return Battle
