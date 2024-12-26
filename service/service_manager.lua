-- service_manager.lua  全局服务管理器
local skynet = require "skynet"

local ServiceManager = {}

-- 存储服务句柄
local services = {}

-- 注册服务
function ServiceManager.register(name, handle)
    services[name] = handle
end

-- 获取服务句柄
function ServiceManager.get(name)
    if not services[name] then
        error("Service not registered: " .. name)
    end
    return services[name]
end

return ServiceManager
