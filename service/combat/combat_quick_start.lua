local skynet = require "skynet"
require "skynet.manager" -- for skynet.register

skynet.start(function()
    -- 1) 启动 router
    local router = skynet.newservice("server_router")
    skynet.register(".router") -- 注册别名，方便 other service query

    -- 2) 启动若干 combat_manager，做多核并行
    local manager_count = 2 -- 你可根据 CPU 核心数或业务来配置
    for i = 1, manager_count do
        skynet.newservice("combat_manager")
    end

    -- 3) 启动一个 battle_logic 服务做演示
    skynet.newservice("battle_logic")

    -- main 不需要继续执行，退出
    skynet.exit()
end)
