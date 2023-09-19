
local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("telestaff", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local _spell = inst.components.spellcaster.spell
    inst.components.spellcaster.spell = function(inst, target, pos, caster, ...)
        if target ~= nil and target:HasTag("gnat") and target.components.infester then
            target.components.infester:Uninfest()
            target.components.health.invincible = true
        end
        _spell(inst, target, pos, caster, ...)
    end
end)
