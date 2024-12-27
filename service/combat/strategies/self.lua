-- strategies/self.lua
local self_strategy = {}

function self_strategy:findTargets(caster, skillDef, battlefield)
    return { caster }
end

return self_strategy
