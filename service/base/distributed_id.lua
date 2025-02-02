-- distributed_id.lua
-- 分布式唯一 ID 生成器（64 位）

local distributed_id = {}

----------------------------------------------------------------
--【1】 配置与常量定义
----------------------------------------------------------------
-- 配置各字段的位数（可根据需求调整，但要求 TIMESTAMP_BITS + SEQUENCE_BITS = 52）
distributed_id.CONFIG = {
    NODE_TYPE_BITS       = 2,  -- 节点类型
    NODE_ID_BITS         = 4,  -- 节点 ID
    BUSINESS_MODULE_BITS = 6,  -- 业务模块 ID
    TIMESTAMP_BITS       = 42, -- 时间戳位数（单位：毫秒，相对于纪元）
    SEQUENCE_BITS        = 10, -- 同一毫秒内序列号
}

-- 检查时间戳和序列号位数和是否为 52 位
local total_ts_seq = distributed_id.CONFIG.TIMESTAMP_BITS + distributed_id.CONFIG.SEQUENCE_BITS
if total_ts_seq ~= 52 then
    error("TIMESTAMP_BITS + SEQUENCE_BITS 必须等于 52 位！")
end

-- 预计算各字段在 64 位内的左移位数（从低位依次拼接：序列号 -> 时间戳 -> 业务模块 -> 节点 ID -> 节点类型）
distributed_id.SHIFTS = {
    SEQUENCE_SHIFT        = 0,
    TIMESTAMP_SHIFT       = distributed_id.CONFIG.SEQUENCE_BITS,
    BUSINESS_MODULE_SHIFT = distributed_id.CONFIG.SEQUENCE_BITS + distributed_id.CONFIG.TIMESTAMP_BITS,
    NODE_ID_SHIFT         = distributed_id.CONFIG.SEQUENCE_BITS + distributed_id.CONFIG.TIMESTAMP_BITS +
        distributed_id.CONFIG.BUSINESS_MODULE_BITS,
    NODE_TYPE_SHIFT       = distributed_id.CONFIG.SEQUENCE_BITS + distributed_id.CONFIG.TIMESTAMP_BITS +
        distributed_id.CONFIG.BUSINESS_MODULE_BITS + distributed_id.CONFIG.NODE_ID_BITS,
}

-- 位掩码计算函数
local function mask(bits)
    return (1 << bits) - 1
end

distributed_id.MASKS = {
    SEQUENCE_MASK        = mask(distributed_id.CONFIG.SEQUENCE_BITS),
    TIMESTAMP_MASK       = mask(distributed_id.CONFIG.TIMESTAMP_BITS),
    BUSINESS_MODULE_MASK = mask(distributed_id.CONFIG.BUSINESS_MODULE_BITS),
    NODE_ID_MASK         = mask(distributed_id.CONFIG.NODE_ID_BITS),
    NODE_TYPE_MASK       = mask(distributed_id.CONFIG.NODE_TYPE_BITS),
}

-- 固定枚举定义（可根据需要扩展）
distributed_id.NodeType = {
    DEFAULT = 0,
    -- 可扩展其他类型，如 MASTER = 1, SLAVE = 2, 等
}

distributed_id.BusinessModule = {
    DEFAULT = 0,
    -- 可扩展其他业务模块编号定义
}

-- 默认纪元（例如：2020-01-01 00:00:00 UTC，单位毫秒）
distributed_id.DEFAULT_EPOCH = 1577836800000

----------------------------------------------------------------
--【2】 内部状态与辅助函数
----------------------------------------------------------------
-- 内部状态：记录上一次生成 ID 使用的逻辑时间及序列号
local state = {
    last_timestamp = 0,
    sequence       = 0,
}

-- 获取当前时间（毫秒）
local function current_millis()
    local ok, socket = pcall(require, "socket")
    if ok and socket.gettime then
        return math.floor(socket.gettime() * 1000)
    else
        return os.time() * 1000
    end
end

----------------------------------------------------------------
--【3】 生成 ID 接口（严格单调递增的逻辑时间）
----------------------------------------------------------------
--- 生成唯一 ID
-- @param node_type       节点类型（例如 distributed_id.NodeType.DEFAULT）
-- @param node_id         节点 ID（数值，范围 0 ~ 2^(NODE_ID_BITS)-1）
-- @param business_module 业务模块 ID（数值，范围 0 ~ 2^(BUSINESS_MODULE_BITS)-1）
-- @param epoch           可选，自定义纪元（毫秒），默认为 distributed_id.DEFAULT_EPOCH
-- @return 64 位整型唯一 ID
function distributed_id.generate_id(node_type, node_id, business_module, epoch)
    epoch = epoch or distributed_id.DEFAULT_EPOCH
    local now = current_millis() - epoch

    local ts = 0
    if now < state.last_timestamp then
        -- 系统时钟回拨或时间未前进，使用逻辑时间递增方式
        ts = state.last_timestamp + 1
        state.sequence = 0
    elseif now == state.last_timestamp then
        -- 同一毫秒内，序列号自增
        state.sequence = state.sequence + 1
        if state.sequence > distributed_id.MASKS.SEQUENCE_MASK then
            -- 序列号溢出，等待下一个逻辑时间
            repeat
                now = current_millis() - epoch
            until now > state.last_timestamp
            ts = now
            state.sequence = 0
        else
            ts = now
        end
    else
        -- 时间正常推进，重置序列号
        ts = now
        state.sequence = 0
    end
    state.last_timestamp = ts

    -- 组合各字段生成 64 位 ID
    local id = 0
    id = id | ((node_type & distributed_id.MASKS.NODE_TYPE_MASK) << distributed_id.SHIFTS.NODE_TYPE_SHIFT)
    id = id | ((node_id & distributed_id.MASKS.NODE_ID_MASK) << distributed_id.SHIFTS.NODE_ID_SHIFT)
    id = id |
        ((business_module & distributed_id.MASKS.BUSINESS_MODULE_MASK) << distributed_id.SHIFTS.BUSINESS_MODULE_SHIFT)
    id = id | ((ts & distributed_id.MASKS.TIMESTAMP_MASK) << distributed_id.SHIFTS.TIMESTAMP_SHIFT)
    id = id | ((state.sequence & distributed_id.MASKS.SEQUENCE_MASK) << distributed_id.SHIFTS.SEQUENCE_SHIFT)
    return id
end

----------------------------------------------------------------
--【4】 解析 ID 接口
----------------------------------------------------------------
--- 解析生成的 ID，提取出各个字段
-- @param id 64 位整型唯一 ID
-- @return table，包含 node_type, node_id, business_module, timestamp, sequence 字段
function distributed_id.parse_id(id)
    local result           = {}
    result.sequence        = id & distributed_id.MASKS.SEQUENCE_MASK
    result.timestamp       = (id >> distributed_id.SHIFTS.TIMESTAMP_SHIFT) & distributed_id.MASKS.TIMESTAMP_MASK
    result.business_module = (id >> distributed_id.SHIFTS.BUSINESS_MODULE_SHIFT) &
        distributed_id.MASKS.BUSINESS_MODULE_MASK
    result.node_id         = (id >> distributed_id.SHIFTS.NODE_ID_SHIFT) & distributed_id.MASKS.NODE_ID_MASK
    result.node_type       = (id >> distributed_id.SHIFTS.NODE_TYPE_SHIFT) & distributed_id.MASKS.NODE_TYPE_MASK
    return result
end

----------------------------------------------------------------
--【6】 模块返回
----------------------------------------------------------------
return distributed_id
