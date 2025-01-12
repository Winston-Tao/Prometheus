-- combat_manager.lua
local skynet        = require "skynet"
local Battle        = require "battle"
local logger        = require "battle_logger"
local hotlogger     = require "hot_update_logger"
local Monitor       = require "battle_monitor"
local BattleSegment = require "battle_segment"
local PriorityQueue = require "priority_queue"
local ProFi         = require "profi"

-- 小型优先队列实现(以runTime为key)
local function newPriorityQueue()
    local pq = {}
    -- 获取队列头(最早 runTime 的任务)
    function pq:peek()
        if #self == 0 then return nil end
        return self[1]
    end

    -- 插入(保持 runTime 升序)
    function pq:push(task)
        table.insert(self, task)
        local i = #self
        while i > 1 do
            local parent = math.floor(i / 2)
            if self[parent].runTime <= self[i].runTime then break end
            self[parent], self[i] = self[i], self[parent]
            i = parent
        end
    end

    -- 弹出最早任务
    function pq:pop()
        if #self == 0 then return nil end
        local root = self[1]
        self[1] = self[#self]
        self[#self] = nil
        local i = 1
        while true do
            local left = i * 2
            local right = i * 2 + 1
            local smallest = i
            if left <= #self and self[left].runTime < self[smallest].runTime then
                smallest = left
            end
            if right <= #self and self[right].runTime < self[smallest].runTime then
                smallest = right
            end
            if smallest == i then break end
            self[i], self[smallest] = self[smallest], self[i]
            i = smallest
        end
        return root
    end

    return pq
end

local CombatManager   = {}
CombatManager.__index = CombatManager

function CombatManager:new(manager_id)
    local obj          = setmetatable({}, self)
    obj.manager_id     = manager_id
    obj.battles        = {} -- [battle_id] = Battle object
    obj.next_battle_id = 1

    obj.monitor        = Monitor:new() -- 用于统计

    -- 任务队列(按runTime升序)
    --obj.taskQueue      = cpriorityqueue.create(128)
    obj.taskQueue      = PriorityQueue:new(128)

    obj.running        = false

    -- 启动任务调度器
    obj:startScheduler()
    return obj
end

--------------------------------------------------------------------------------
-- 主循环: 不再对每个battle fork while循环，而是统一在这里选任务执行
--------------------------------------------------------------------------------
function CombatManager:startScheduler()
    if self.running then return end
    self.running = true

    skynet.fork(function()
        while self.running do
            local top = self.taskQueue:peek()
            if not top then
                -- 没有任务 => sleep一下再看
                skynet.sleep(1)
            else
                local now = math.floor(skynet.time() * 1000)
                -- 允许提前 BattleSegment.TOLERANCE 执行
                if now + BattleSegment.TOLERANCE < top.runTime then
                    -- 未到执行时间 => sleep (最小间隔=1ms)
                    local dt = top.runTime - now - BattleSegment.TOLERANCE
                    logger.debug(string.format("[Scheduler] job skip, top.runTime=%dms", top.runTime), { "skip" })
                    if dt > 0 then
                        skynet.sleep(dt / 10) -- ms-> 0.01s
                    end
                else
                    -- 到执行时间 => pop, 执行
                    local task = self.taskQueue:pop()
                    if task and task.func then
                        local st = math.floor(skynet.time() * 1000)
                        task.func() -- 执行真正的“Battle帧更新”
                        local cost = math.floor(skynet.time() * 1000) - st
                        logger.debug(string.format("[Scheduler] job done, cost=%dms", cost), { "scheduler" })
                    end
                end
            end
        end
    end)
end

-- 增加一个任务
function CombatManager:addJob(runTime, func)
    local task = { runTime = runTime, func = func }
    self.taskQueue:push(task)
end

--------------------------------------------------------------------------------
-- 其它CombatManager逻辑
--------------------------------------------------------------------------------
function CombatManager:createBattle(mapSize)
    local battle_id = self.next_battle_id
    self.next_battle_id = battle_id + 1

    -- 统计当前战场数量

    -- todo 动态设置 估算上一秒的平均帧计算时间
    local lastSecondAvgCalc = 10

    -- 计算启动延迟
    local delay = BattleSegment:calcStartDelay(#self.battles, lastSecondAvgCalc)

    local battle = Battle:new(battle_id, mapSize, self, delay)
    self.battles[battle_id] = battle

    self.monitor:initBattle(battle_id)
    return battle_id
end

function CombatManager:getBattle(bid)
    return self.battles[bid]
end

function CombatManager:removeBattle(bid)
    self.battles[bid] = nil
    self.monitor:removeBattle(bid)
    logger.info("[CombatManager:destory Battle]", "battle", {
        battle_id = bid
    })
end

function CombatManager:startBattle(battle_id)
    local b = self.battles[battle_id]
    if not b then return "fail" end
    -- 给 Battle 一个 “启动”调用
    b:setupSchedule(function(taskRunTime, taskFunc)
            self:addJob(taskRunTime, taskFunc)
        end,
        function(bid, deltaT, calcTime)
            self.monitor:updateStats(bid, deltaT, calcTime, b)
        end)

    b.is_active = true

    -- 先推送battle第一帧
    local firstFrameTime = b:getNextFrameTime() -- b.beginms
    self:addJob(firstFrameTime, function()
        b:doFrame()
    end)
    logger.info("[CombatManager:startBattle]", "battle", {
        battle_id = battle_id
    })
    return "ok"
end

-- 手动施法
function CombatManager:releaseSkill(battle_id, caster_id, skill_name, target_id)
    local battle = self:getBattle(battle_id);
    if battle then
        battle:release_skill(caster_id, skill_name, target_id)
    else
        logger.warn("[CombatManager:releaseSkill battle destroyed]", "battle", {
            battle_id = battle_id
        })
    end
end

---------------------------------------------------------------------------------
-- SKynet service
--------------------------------------------------------------------------------
local CMD = {}
local manager

function CMD.init(mgr, manager_id)
    mgr.manager_id = manager_id
end

function CMD.start_scheduler(mgr)
    mgr:startScheduler()
    skynet.retpack("ok")
end

function CMD.create_battle(mgr, mapSize)
    local bid = mgr:createBattle(mapSize)
    skynet.send(".serverRouter", "lua", "acquire_load", "combat_manager", skynet.self())
    skynet.retpack(bid)
end

function CMD.start_battle(mgr, bid)
    local r = mgr:startBattle(bid)
    skynet.retpack(r)
end

function CMD.add_combatant(mgr, bid, cdata)
    local battle = mgr:getBattle(bid)
    if not battle then return nil end
    local c = battle:addCombatant(cdata)
    skynet.retpack(c.id)
end

function CMD.release_skill(mgr, bid, caster_id, skill_name, target_id)
    mgr:releaseSkill(bid, caster_id, skill_name, target_id)
    skynet.retpack("ok")
end

function CMD.destroy_battle(mgr, bid)
    mgr:removeBattle(bid)
    skynet.send(".serverRouter", "lua", "release_load", "combat_manager", skynet.self())
    skynet.retpack("ok")
end

-- 热更接口
function CMD.hotfix(mgr, modules)
    hotlogger.info(string.format("[SubscriberService] Received hotfix for modules: %s", table.concat(modules, ", ")))
    for _, module_name in ipairs(modules) do
        package.loaded[module_name] = nil
        local ok, mod = pcall(require, module_name)
        if ok then
            hotlogger.info(string.format("[SubscriberService] Successfully reloaded module: %s", module_name))
        else
            hotlogger.error(string.format("[SubscriberService] Failed to reload module: %s, error: %s", module_name, mod))
        end
    end
    skynet.ret()
end

-- 订阅热更服务
function CMD.subscribe_to_hotfix()
    local status, result = pcall(skynet.call, ".hotfix_service", "lua", "subscribe", skynet.self())
    hotlogger.info("[SubscriberService] Subscribed to hotfix service.", "subscribe_to_hotfix",
        { status = status, result = result })
end

--------------------------------------------------------------------------------
skynet.start(function()
    manager = CombatManager:new(nil)
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
    ProFi:start()
    ProFi:setGetTimeMethod(skynet.now)
    skynet.fork(function()
        skynet.sleep(100 * 15)
        ProFi:stop()
        ProFi:writeReport('combatCpu.txt')
    end)
    skynet.error("[combat_manager] Service started.")
end)
