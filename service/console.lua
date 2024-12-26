-- service/console.lua
-- 简单控制台交互: 输入json命令, 调用scene_mgr的 dispatch_command

local skynet = require "skynet"
local service_manager = require "service_manager"

local function read_input()
    -- 这里只是示意，不建议在生产环境中用 blocking IO
    while true do
        local line = io.read("*l")
        if line then
            local scene_mgr = service_manager.get("scene_mgr")
            skynet.error("console_input" .. line)
            local ret, err = skynet.call(scene_mgr, "lua", "dispatch_command", line)
            if not ret then
                skynet.error("Command error:", err)
            end
        else
            skynet.error("stdin closed?")
            break
        end
    end
end

skynet.start(function()
    skynet.fork(read_input)
end)


local function useSceneManager()
    local scene_mgr = service_manager.get("scene_mgr")
    local result = skynet.call(scene_mgr, "lua", "load_scene", "MainScene")
    print(result) -- 输出: Scene MainScene loaded successfully
end

return {
    useSceneManager = useSceneManager
}
