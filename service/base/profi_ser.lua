local skynet = require "skynet"
local ProFi  = require "cpu_profiler"
require "skynet.manager"

local CMD = {}

local profiler = ProFi.new()

function CMD.start_profile()
    profiler:start()
    skynet.error("profiling started")
end

function CMD.stop_profile()
    profiler:stop()
    profiler:writeReport("lua_profile.txt")
    skynet.error("profiling stopped, report => lua_profile.txt")
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = CMD[cmd]
        if f then
            local r = f(...)
            skynet.retpack(r)
        else
            skynet.ret()
        end
    end)
    skynet.register(".profi_ser") -- 注册别名
end)
