-- battle_monitor.lua
-- 仅示例：提供记录或查询接口

local BattleMonitor = {}
BattleMonitor.__index = BattleMonitor

function BattleMonitor:new()
    local obj = setmetatable({}, self)
    obj.battleStats = {} -- [battle_id] = { maxDeltaT, frameCount, totalCalc }
    return obj
end

function BattleMonitor:initBattle(battle_id)
    self.battleStats[battle_id] = { maxDeltaT = 0, frameCount = 0, totalCalc = 0 }
end

function BattleMonitor:updateStats(battle_id, deltaT, calcTime)
    local st = self.battleStats[battle_id]
    if not st then return end
    st.frameCount = st.frameCount + 1
    st.totalCalc  = st.totalCalc + calcTime
    if deltaT > st.maxDeltaT then
        st.maxDeltaT = deltaT
    end
end

function BattleMonitor:getStats(battle_id)
    local st = self.battleStats[battle_id]
    if not st then return nil end
    local avgCalc = 0
    if st.frameCount > 0 then
        avgCalc = st.totalCalc / st.frameCount
    end
    return {
        maxDeltaT = st.maxDeltaT,
        frameCount = st.frameCount,
        avgCalc = avgCalc
    }
end

function BattleMonitor:removeBattle(battle_id)
    self.battleStats[battle_id] = nil
end

return BattleMonitor
