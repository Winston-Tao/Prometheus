-- effects/modify_attribute.lua
local skynet = require "skynet"

local modify_attribute = {}

function modify_attribute.execute(effConfig, caster, target, skillOrBuff, elemMgr)
    -- e.g. {effect_type="modify_attribute", attr="HP", value=-10}
    local attr = effConfig.attr
    local val  = effConfig.value or 0
    if attr then
        target.attr:modify(attr, val)
        if type(val) ~= "number" then
            skynet.error(string.format("[ModifyAttribute] Error: val is not a number, type: %s", type(val)))
        else
            skynet.error(string.format("[ModifyAttribute] val is %s", tostring(val)))
        end
    else
        skynet.error("[modify_attribute] missing 'attr'")
    end
end

return modify_attribute
