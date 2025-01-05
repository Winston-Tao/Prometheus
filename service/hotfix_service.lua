local skynet = require "skynet"
local skyMgr = require "skynet.manager"
local hotfix_service = {}
local CMD = {}
local subscribers = {} -- 存储订阅者服务地址列表
local hotlogger = require "hot_update_logger"

-- 订阅热更服务
function hotfix_service.subscribe(address)
    if not subscribers[address] then
        subscribers[address] = true
        hotlogger.debug(string.format("[HotfixService] Service %s subscribed.", skynet.address(address)))
    else
        hotlogger.debug(string.format("[HotfixService] Service %s already subscribed.", skynet.address(address)))
    end
end

-- 触发热更
function hotfix_service.trigger(modules, target)
    if target then
        -- 热更指定服务
        hotlogger.debug(string.format("[HotfixService] Triggering hotfix for %s with modules: %s",
            skynet.address(target), table.concat(modules, ", ")))
        skynet.call(target, "lua", "hotfix", modules)
    else
        -- 广播热更给所有订阅者
        local count = 0
        for address, _ in pairs(subscribers) do
            count = count + 1
            local ok, err = pcall(skynet.call, address, "lua", "hotfix", modules)
            if not ok then
                hotlogger.debug(string.format("[HotfixService] hotfix %s: ", "hotUpdate", {
                    err = err,
                    modules = modules
                }))
            end
        end
        hotlogger.debug(
            string.format("[HotfixService] Broadcasting hotfix with modules: %s", table.concat(modules, ", ")),
            "hotUpdate",
            { count = count })
    end
end

-- 订阅服务
function CMD.subscribe(address)
    hotfix_service.subscribe(address)
    skynet.retpack(true)
end

-- 触发热更
function CMD.trigger(modules, target)
    hotfix_service.trigger(modules, target)
    skynet.retpack(true)
end

-- 热更服务启动
-- skynet.call(hotfix_service, "lua", "trigger", {"battle"})
-- call 0100000b  "trigger", {"battle", "combat_manager"}
-- call 0100000c  "trigger", {"battle", "skill_system"}
skynet.start(function()
    skynet.dispatch("lua", function(_, source, cmd, ...)
        hotlogger.debug(string.format("[HotfixService] execute command: %s", cmd))
        local f = CMD[cmd]
        if f then
            f(...)
        else
            hotlogger.debug(string.format("[HotfixService] Unknown command: %s", cmd))
        end
    end)
    skyMgr.register(".hotfix_service")
    hotlogger.debug("[HotfixService] Service started.")
end)
