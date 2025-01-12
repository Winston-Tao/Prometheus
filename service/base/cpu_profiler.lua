-- File: ProFiAdvanced.lua
-- Industrial-level Lua profiler for Skynet / general Lua usage.
-- Supports real-time measurement, ignoring certain [C] calls, optional JSON output.

local skynet             = require "skynet"
--local cjson              = require "cjson.safe" -- Or any JSON library you have
local ProFiAdvanced      = {}
ProFiAdvanced.__index    = ProFiAdvanced

local onDebugHook
local IGNORE_C_FUNCTIONS = true
local DEFAULT_HOOK_MASK  = "cr"
local DEFAULT_HOOK_COUNT = 0

function ProFiAdvanced.new()
    local self          = setmetatable({}, ProFiAdvanced)
    self.reports        = {}
    self.reportsByTitle = {}
    self.hasStarted     = false
    self.hasStopped     = false
    self.hookMask       = DEFAULT_HOOK_MASK
    self.hookCount      = DEFAULT_HOOK_COUNT
    self.startTime      = 0
    self.stopTime       = 0
    return self
end

function ProFiAdvanced:getTime()
    return skynet.now()
end

function ProFiAdvanced:start()
    if self.hasStarted then return end
    self.hasStarted = true
    self.startTime  = self:getTime()
    debug.sethook(onDebugHook, self.hookMask, self.hookCount)
    ProFiAdvanced._instance = self
end

function ProFiAdvanced:stop()
    if self.hasStopped then return end
    self.hasStopped = true
    self.stopTime   = self:getTime()
    debug.sethook()
    ProFiAdvanced._instance = nil
end

function ProFiAdvanced:onFunctionCall(funcInfo)
    if IGNORE_C_FUNCTIONS and (funcInfo.short_src == "[C]") then
        return
    end
    local fr = self:getFuncReport(funcInfo)
    fr.callTime = self:getTime()
    fr.count = fr.count + 1
end

function ProFiAdvanced:onFunctionReturn(funcInfo)
    if IGNORE_C_FUNCTIONS and (funcInfo.short_src == "[C]") then
        return
    end
    local fr = self:getFuncReport(funcInfo)
    if fr.callTime then
        local now = self:getTime()
        fr.timer = fr.timer + (now - fr.callTime)
        fr.callTime = nil
    end
end

function ProFiAdvanced:getFuncReport(funcInfo)
    local title = self:makeFuncTitle(funcInfo)
    local fr = self.reportsByTitle[title]
    if not fr then
        fr = {
            title       = title,
            source      = funcInfo.short_src or "[C]",
            name        = funcInfo.name or "anonymous",
            linedefined = funcInfo.linedefined or 0,
            count       = 0,
            timer       = 0,
            callTime    = nil,
        }
        self.reportsByTitle[title] = fr
        table.insert(self.reports, fr)
    end
    return fr
end

function ProFiAdvanced:makeFuncTitle(fi)
    local src  = fi.short_src or "[C]"
    local name = fi.name or "anonymous"
    local line = fi.linedefined or 0
    return string.format("%s:%s:%d", src, name, line)
end

function ProFiAdvanced:writeReport(filename)
    filename = filename or "ProFiAdvanced_report.txt"
    local f, err = io.open(filename, "w")
    if not f then return end
    local totalTime = self.stopTime - self.startTime
    table.sort(self.reports, function(a, b) return a.timer > b.timer end)
    f:write(string.format("TOTAL TIME = %.3f seconds\n", totalTime))
    f:write(string.format("%-70s  %10s  %10s  %8s\n", "Function", "Time(s)", "Rel%", "Calls"))
    for _, r in ipairs(self.reports) do
        local rel = 0
        if totalTime > 0 then rel = (r.timer / totalTime) * 100 end
        f:write(string.format(
            "%-70s  %10.3f  %9.2f%%  %8d\n",
            r.title, r.timer, rel, r.count
        ))
    end
    f:close()
end

--function ProFiAdvanced:writeJson(filename)
--    filename = filename or "ProFiAdvanced_report.json"
--    local f, err = io.open(filename, "w")
--    if not f then return end
--    local totalTime = self.stopTime - self.startTime
--    table.sort(self.reports, function(a, b) return a.timer > b.timer end)
--    local data = {
--        totalTime = totalTime,
--        records   = {},
--    }
--    for _, r in ipairs(self.reports) do
--        local rel = 0
--        if totalTime > 0 then rel = (r.timer / totalTime) * 100 end
--        table.insert(data.records, {
--            title    = r.title,
--            time     = r.timer,
--            relative = rel,
--            count    = r.count,
--        })
--    end
--    f:write(cjson.encode(data))
--    f:close()
--end

onDebugHook = function(hookType)
    local self = ProFiAdvanced._instance
    if not self then return end
    local fi = debug.getinfo(2, "nS")
    if hookType == "call" then
        self:onFunctionCall(fi)
    elseif hookType == "return" then
        self:onFunctionReturn(fi)
    end
end

return ProFiAdvanced
