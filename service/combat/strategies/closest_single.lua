-- strategies/closest_single.lua
local closest_single = {}

function closest_single:findTargets(caster, skillDef, battlefield)
    local best = nil
    local minDist = math.huge
    for _, c in ipairs(battlefield.combatants) do
        if c ~= caster and c.attr:get("HP") > 0 then
            if c.type ~= caster.type then
                local dist = math.abs(c.id - caster.id)
                if dist < minDist then
                    minDist = dist
                    best = c
                end
            end
        end
    end
    return best and { best } or {}
end

return closest_single
