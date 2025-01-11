-- battle_monitor.lua
-- 统计并输出战斗详细数据报表

local skynet = require "skynet"
local BattleMonitorLogger = require "battle_monitor_logger"

local BattleMonitor = {}
BattleMonitor.__index = BattleMonitor

function BattleMonitor:new()
    local obj = setmetatable({}, self)
    obj.battleStats = {}               -- [battle_id] = { frameCount, totalCalc, maxDeltaT, minDeltaT, sumDeltaT, ...}
    obj.lastReportTime = skynet.time() -- 用于定时输出报表
    obj.battleCount = 0
    return obj
end

--------------------------------------------------------------------------------
-- 初始化某Battle的监控数据
--------------------------------------------------------------------------------
function BattleMonitor:initBattle(battle_id)
    -- 若尚未记录 => 新建
    if not self.battleStats[battle_id] then
        self.battleStats[battle_id] = {
            frameCount     = 0,
            totalCalc      = 0,
            maxDeltaT      = 0,
            minDeltaT      = 9999999999,
            sumDeltaT      = 0,
            maxCalcTime    = 0,
            minCalcTime    = 9999999999,
            sumCalcTime    = 0,
            startTime      = skynet.time(), -- 记录战斗开始时间
            combatantCount = 0,             -- 单位数量
        }
        self.battleCount = self.battleCount + 1
    end
end

--------------------------------------------------------------------------------
-- 移除Battle
--------------------------------------------------------------------------------
function BattleMonitor:removeBattle(battle_id)
    st = self.battleStats[battle_id]
    if self.battleStats[battle_id] then
        self.battleStats[battle_id] = nil
        self.battleCount = math.max(0, self.battleCount - 1)
        local bReport = self:singleBattleInfo(battle_id, st)
        BattleMonitorLogger.info("[CombatManager_monitor:battle end report]", "battle_monitor", {
            monitor_info = bReport
        })
    end
end

--------------------------------------------------------------------------------
-- 更新战斗单位数量 todo 也可以直接实时取战场内的战斗单位数量 - 目前是初始数量
--------------------------------------------------------------------------------
-- 在 add_combatant 等操作时调用
function BattleMonitor:updateCombatantCount(battle_id, count)
    local st = self.battleStats[battle_id]
    if not st then return end
    st.combatantCount = count
end

--------------------------------------------------------------------------------
-- 统计帧信息
-- @param battle table, 包含battle.id, battle.combatants等信息
--------------------------------------------------------------------------------
function BattleMonitor:updateStats(battle_id, deltaT, calcTime, battle)
    local st = self.battleStats[battle_id]
    if not st then return end

    -- 累计帧数
    st.frameCount = st.frameCount + 1

    -- 记录calcTime相关
    st.totalCalc = st.totalCalc + calcTime
    if calcTime > st.maxCalcTime then
        st.maxCalcTime = calcTime
    end
    if calcTime < st.minCalcTime then
        st.minCalcTime = calcTime
    end
    st.sumCalcTime = st.sumCalcTime + calcTime

    -- 记录deltaT相关
    if deltaT > st.maxDeltaT then
        st.maxDeltaT = deltaT
    end
    if deltaT < st.minDeltaT then
        st.minDeltaT = deltaT
    end
    st.sumDeltaT = st.sumDeltaT + deltaT

    -- 如果battle有更多可获取的数据，如 buff数量、AI执行时间等，也可记录

    -- 可定时(例如每隔10秒)或者按帧计数输出一次报表
    self:maybeReport()
end

--------------------------------------------------------------------------------
-- 定时或按需输出战斗数据报表
--------------------------------------------------------------------------------
function BattleMonitor:maybeReport()
    local now = skynet.time()
    -- 每 10 秒输出一次 (可调)
    if now - self.lastReportTime >= 10 then
        self.lastReportTime = now
        self:reportAllBattles()
    end
end

--------------------------------------------------------------------------------
-- 报表输出主函数
--------------------------------------------------------------------------------
function BattleMonitor:reportAllBattles()
    local battleReports = {}

    for battle_id, st in pairs(self.battleStats) do
        local bReport = self:singleBattleInfo(battle_id, st)
        table.insert(battleReports, bReport)
    end

    BattleMonitorLogger.info("[CombatManager_monitor:reportAllBattles]", "battle_monitor", {
        totalBattleCount = self.battleCount,
        battleReports = battleReports
    })
end

--------------------------------------------------------------------------------
-- 手动输出 (若需要在外部指令触发报表，也可调用此函数)
--------------------------------------------------------------------------------
function BattleMonitor:manualReport()
    self:reportAllBattles()
end

function BattleMonitor:singleBattleInfo(battle_id, st)
    local frames = st.frameCount
    if frames <= 0 then frames = 1 end -- 避免除0
    local avgDeltaT = st.sumDeltaT / frames
    local avgCalc   = st.sumCalcTime / frames
    local runTime   = skynet.time() - st.startTime

    local r         = {
        battle_id      = battle_id,
        runtime_sec    = string.format("%.2f", runTime),
        frameCount     = st.frameCount,
        combatantCount = st.combatantCount,
        deltaT_max     = string.format("%.2f", st.maxDeltaT),
        deltaT_min     = string.format("%.2f", st.minDeltaT),
        deltaT_avg     = string.format("%.2f", avgDeltaT),
        calcTime_max   = string.format("%.2f", st.maxCalcTime),
        calcTime_min   = string.format("%.2f", st.minCalcTime),
        calcTime_avg   = string.format("%.2f", avgCalc),
    }
    local strRes    = string.format(
        "[BattleMonitor] BattleID=%d, run=%.2fs, frames=%d, units=%d | DeltaT[max=%.2f,min=%.2f,avg=%.2f] Calc[max=%.2f,min=%.2f,avg=%.2f]",
        r.battle_id, r.runtime_sec, r.frameCount, r.combatantCount,
        r.deltaT_max, r.deltaT_min, r.deltaT_avg,
        r.calcTime_max, r.calcTime_min, r.calcTime_avg
    )
    return strRes
end

return BattleMonitor
