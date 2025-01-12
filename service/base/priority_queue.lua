-- priority_queue.lua
local cpriorityqueue = require "cpriorityqueue"

local PriorityQueue = {}
PriorityQueue.__index = PriorityQueue

--------------------------------------------------------------------------------
-- Lua层包装
--------------------------------------------------------------------------------
function PriorityQueue:new(initialCap)
    local obj    = setmetatable({}, self)
    -- cObj: C端优先队列指针
    obj._cObj    = cpriorityqueue.create(initialCap or 16)
    obj._nextId  = 1
    obj._storage = {} -- { [id] = task }
    return obj
end

function PriorityQueue:push(task)
    -- 1) 确保有 runTime
    local runTime = task.runTime
    if not runTime then
        error("task must have a runTime field!")
    end
    -- 2) todo 生成id  可以使用唯一 id 生成算法
    local id = self._nextId
    self._nextId = id + 1

    -- 3) 存储到 storage
    self._storage[id] = task

    -- 4) 调用 C push
    local ok = self._cObj:push(runTime, id)
    return ok
end

function PriorityQueue:peek()
    local id = self._cObj:peek()
    if not id then
        return nil
    end
    local t = self._storage[id]
    return t
end

function PriorityQueue:pop()
    local id = self._cObj:pop()
    if not id then
        return nil
    end
    local t = self._storage[id]
    if t then
        self._storage[id] = nil
        return t
    end
    return nil
end

function PriorityQueue:size()
    return cpriorityqueue.size(self._cObj)
end

return PriorityQueue
