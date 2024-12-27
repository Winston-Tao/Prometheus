-- server_router.lua
local skynet = require "skynet"
local config = require "combat.battle_conf.battle_config"
require "skynet.manager"

--------------------------------------------------------------------------------
-- 通用服务管理：注册、负载、分配
--------------------------------------------------------------------------------

local ServerRouter = {}
ServerRouter.__index = ServerRouter

function ServerRouter:new()
    local obj = setmetatable({}, self)
    -- services[service_type] = { { addr, load, max_capacity }, ... }
    obj.services = {}
    return obj
end

-- 注册一个服务实例
function ServerRouter:register_service(service_type, service_addr)
    self.services[service_type] = self.services[service_type] or {}
    local list = self.services[service_type]

    local entry = {
        addr = service_addr,
        load = 0,
        max_capacity = config.max_battles_per_service or 1000,
    }
    table.insert(list, entry)
    skynet.error("[ServerRouter] Registered:", service_type, service_addr)
end

-- 分配最空闲的实例
function ServerRouter:allocate_instance(service_type)
    local list = self.services[service_type]
    if not list or #list == 0 then
        skynet.error("[ServerRouter] No service found for type:", service_type)
        return nil
    end
    local selected, min_load = nil, math.huge
    for _, entry in ipairs(list) do
        if entry.load < entry.max_capacity and entry.load < min_load then
            min_load = entry.load
            selected = entry
        end
    end
    if not selected then
        skynet.error("[ServerRouter] All", service_type, "services at capacity!")
        return nil
    end
    return selected.addr
end

-- “占用”一个负载
function ServerRouter:acquire_load(service_type, service_addr)
    local list = self.services[service_type]
    if not list then return end
    for _, entry in ipairs(list) do
        if entry.addr == service_addr then
            entry.load = entry.load + 1
            break
        end
    end
end

-- “释放”一个负载
function ServerRouter:release_load(service_type, service_addr)
    local list = self.services[service_type]
    if not list then return end
    for _, entry in ipairs(list) do
        if entry.addr == service_addr then
            if entry.load > 0 then
                entry.load = entry.load - 1
            end
            break
        end
    end
end

--------------------------------------------------------------------------------
-- 使用表驱动替代 if-else 大量判断
--------------------------------------------------------------------------------

local CMD = {}

function CMD.register_service(router, service_type, service_addr)
    router:register_service(service_type, service_addr)
    skynet.ret()
end

function CMD.allocate_instance(router, service_type)
    local addr = router:allocate_instance(service_type)
    skynet.retpack(addr)
end

function CMD.acquire_load(router, service_type, service_addr)
    router:acquire_load(service_type, service_addr)
    skynet.ret()
end

function CMD.release_load(router, service_type, service_addr)
    router:release_load(service_type, service_addr)
    skynet.ret()
end

--------------------------------------------------------------------------------
-- Skynet start
--------------------------------------------------------------------------------
skynet.start(function()
    local router = ServerRouter:new()

    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = CMD[cmd]
        if f then
            -- 执行命令并返回结果
            pcall(f, router, ...)
        else
            skynet.error("[ServerRouter] Unknown command:", cmd)
            skynet.ret(skynet.pack(nil, "Unknown command: " .. cmd)) -- 返回未知命令错误
        end
    end)

    skynet.register(".serverRouter") -- 注册别名
    skynet.error("[ServerRouter] Service started.")
end)
