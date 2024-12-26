-- timer.lua
local skynet = require "skynet"

local Timer = {}

function Timer.add(interval, callback)
    skynet.fork(function()
        while true do
            skynet.sleep(interval * 100) -- 转换为时间片
            callback()
        end
    end)
end

return Timer
