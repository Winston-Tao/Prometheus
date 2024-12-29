-- element_manager.lua
local skynet = require "skynet"
local battle_data = require "battle_data"

local ElementManager = {}
ElementManager.__index = ElementManager

function ElementManager:new()
    local obj          = setmetatable({}, self)

    -- 1) from battle_data
    obj.skill_defs     = battle_data.skill_definitions or {}
    obj.buff_defs      = battle_data.buff_definitions or {}
    obj.strategy_defs  = battle_data.strategy_definitions or {}
    obj.instant_buffs  = battle_data.instant_buffs or {}

    -- 2) caches
    obj.effect_cache   = {}
    obj.strategy_cache = {}

    return obj
end

---------------------------
-- Skill
---------------------------
function ElementManager:getSkillDefinition(skill_name)
    return self.skill_defs[skill_name]
end

---------------------------
-- Buff
---------------------------
function ElementManager:getBuffDefinition(buff_name)
    -- 处理 instantBuff
    if buff_name:find("InstantBuff:") == 1 then
        local ibName = buff_name:sub(13) -- e.g. "HurtPhysical50"
        local ibDef  = self.instant_buffs[ibName]
        if ibDef then
            return {
                is_instant = true,
                duration   = ibDef.duration or 0.01,
                overlap    = "discard",
                effects    = ibDef.effects
            }
        end
        return nil
    end

    return self.buff_defs[buff_name]
end

---------------------------
-- Strategy
---------------------------
function ElementManager:getStrategyModule(strategy_name)
    local def = self.strategy_defs[strategy_name]
    if not def then
        skynet.error("[ElementManager] no strategy:", strategy_name)
        return nil
    end
    if not self.strategy_cache[strategy_name] then
        local ok, mod = pcall(require, def.script_file)
        if ok then
            self.strategy_cache[strategy_name] = mod
        else
            skynet.error("[ElementManager] load strategy fail:", strategy_name, mod)
            return nil
        end
    end
    return self.strategy_cache[strategy_name]
end

---------------------------
-- runEffect
---------------------------
function ElementManager:runEffect(effConfig, caster, target, skillOrBuff, originDamage)
    local etype = effConfig.effect_type
    if not etype then
        skynet.error("[ElementManager] Missing effect_type in config")
        return
    end
    -- dynamic load
    if not self.effect_cache[etype] then
        local path = "effects." .. etype
        local ok, mod = pcall(require, path)
        if ok then
            self.effect_cache[etype] = mod
        else
            skynet.error("[ElementManager] fail load effect:", path, mod)
            return
        end
    end
    local effect_mod = self.effect_cache[etype]
    if effect_mod and effect_mod.execute then
        effect_mod.execute(effConfig, caster, target, skillOrBuff, originDamage, self)
    else
        skynet.error("[ElementManager] effect missing 'execute':", etype)
    end
end

return ElementManager
