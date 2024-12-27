-- logger/log_storage.lua
-- 轮转示例,基于文件大小or每天一文件, 仅示例,实务可更强大

local LogStorage = {}
LogStorage.__index = LogStorage

function LogStorage:new(basePath, maxSize)
    local obj = setmetatable({}, self)
    obj.basePath = basePath or "./logs/log"
    obj.maxSize = maxSize or (5 * 1024 * 1024)
    obj.currentFileName = obj:genFileName()
    obj.file = io.open(obj.currentFileName, "a")
    return obj
end

function LogStorage:genFileName()
    local t = os.date("%Y%m%d_%H%M%S")
    return string.format("%s_%s.log", self.basePath, t)
end

function LogStorage:append(line)
    if not self.file then
        self.file = io.open(self.currentFileName, "a")
    end
    self.file:write(line, "\n")
    if self.file:seek() >= self.maxSize then
        self:rollover()
    end
end

function LogStorage:rollover()
    self.file:flush()
    self.file:close()
    self.currentFileName = self:genFileName()
    self.file = io.open(self.currentFileName, "a")
end

function LogStorage:close()
    if self.file then
        self.file:flush()
        self.file:close()
        self.file = nil
    end
end

return LogStorage
