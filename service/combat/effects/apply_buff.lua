-- effects/apply_buff.lua
local skynet = require "skynet"

local apply_buff = {}

function apply_buff.execute(effConfig, caster, target, skillOrBuff, elemMgr)
    local buff_name = effConfig.buff_name
    if not buff_name then
        skynet.error("[apply_buff] no buff_name in effConfig")
        return
    end
    target.buffsys:apply_buff(buff_name, caster, target)
end

return apply_buff
