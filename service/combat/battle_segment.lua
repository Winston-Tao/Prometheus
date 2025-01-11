-- battle_segment.lua
-- 新增: 动态 segmentTime + 自适应算法

local BattleMonitorLogger = require "battle_monitor_logger"


local BattleParams = {
    FRAME_DURATION    = 100,          -- 每帧时长 (ms)
    CHASE_THRESHOLD   = 50,           -- 追帧阈值
    ADVANCE_THRESHOLD = 5,            -- 提前执行阈值
    MAX_FRAME_COUNT   = 300 * 2 * 10, -- 测试用, 超过此帧数则结束 十分钟

    -- 新增一个动态分片时长, 初始设为30ms, 之后可由系统根据实际负载自适应
    segmentTime       = 10,
    -- 本示例在1秒(1000ms)内可容纳 floor(1000 / segmentTime) 个错峰点

    -- -- 允许 ± X ms(可定义)
    TOLERANCE         = 20
}

-- 优化: calcStartDelay(currentBattleCount, lastSecondAvgCalc)
-- 1) 每次创建战场时, 先根据 lastSecondAvgCalc 更新 segmentTime
-- 2) 在 1秒(1000ms) 内切分成 N 段, N = floor(1000 / segmentTime)
-- 3) 计算 index = (currentBattleCount % N), 返回 index * segmentTime
function BattleParams:calcStartDelay(currentBattleCount, lastSecondAvgCalc)
    --if lastSecondAvgCalc then
    --    -- 动态调整 segmentTime
    --    self:updateSegmentTime(lastSecondAvgCalc)
    --end

    local groupSize = math.floor(1000 / self.FRAME_DURATION)
    if groupSize < 1 then
        groupSize = 1
    end

    local index = currentBattleCount % groupSize

    local res = index * self.segmentTime
    BattleMonitorLogger.info("BattleParams:calcStartDelay", "battle_monitor", {
        currentBattleCount = currentBattleCount,
        res = res
    })

    return res
end

return BattleParams
