local ModuleFilter = {}
ModuleFilter.__index = ModuleFilter

function ModuleFilter:new(whitelist)
    local obj     = setmetatable({}, self)
    obj.whitelist = whitelist or {} -- {["battle"]=true, ...}
    obj.stats     = {}              -- 记录计数
    return obj
end

----------- 后续性能优化
function ModuleFilter:check(event)
    -- moduleName = event.file
    local allow = false
    for mod, _ in pairs(self.whitelist) do
        if mod == event.tags or event.file == mod then
            allow = true
            break
        end
    end
    if allow then
        local key = event.file
        self.stats[key] = (self.stats[key] or 0) + 1
        -- 后续可做更多限流
    end
    return allow
end

return ModuleFilter
