-- battle_params.lua
-- 新增: 动态 segmentTime + 自适应算法

local BattleParams = {
    FRAME_DURATION    = 100,          -- 每帧时长 (ms)
    CHASE_THRESHOLD   = 50,           -- 追帧阈值
    ADVANCE_THRESHOLD = 5,            -- 提前执行阈值
    MAX_FRAME_COUNT   = 300 * 2 * 10, -- 测试用, 超过此帧数则结束 十分钟

    -- 新增一个动态分片时长, 初始设为30ms, 之后可由系统根据实际负载自适应
    segmentTime       = 30,
    -- 本示例在1秒(1000ms)内可容纳 floor(1000 / segmentTime) 个错峰点
}

-- 新增函数: updateSegmentTime(averageFrameTime)
-- 根据上一秒或某段时间统计到的平均帧计算时长, 动态调整 segmentTime
-- 仅示例: segmentTime = base + averageFrameTime
function BattleParams:updateSegmentTime(averageFrameTime)
    local base = 30
    local recommended = base + averageFrameTime
    -- 避免过小或过大
    self.segmentTime = math.max(5, math.min(recommended, 200))
end

-- 优化: calcStartDelay(currentBattleCount, lastSecondAvgCalc)
-- 1) 每次创建战场时, 先根据 lastSecondAvgCalc 更新 segmentTime
-- 2) 在 1秒(1000ms) 内切分成 N 段, N = floor(1000 / segmentTime)
-- 3) 计算 index = (currentBattleCount % N), 返回 index * segmentTime
function BattleParams:calcStartDelay(currentBattleCount, lastSecondAvgCalc)
    if lastSecondAvgCalc then
        -- 动态调整 segmentTime
        self:updateSegmentTime(lastSecondAvgCalc)
    end

    local groupSize = math.floor(1000 / self.segmentTime)
    if groupSize < 1 then
        groupSize = 1
    end

    local index = currentBattleCount % groupSize
    return index * self.segmentTime
end

return BattleParams
