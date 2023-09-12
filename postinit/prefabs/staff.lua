
local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("telestaff", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local _spell = inst.components.spellcaster.spell
    inst.components.spellcaster.spell = function (inst, target, ...)
        if target:HasTag("gnat") and target.components.infester then
            target.components.infester:Uninfest()
        end
        _spell(inst, target, ...)
        target.components.health.invincible = true
    end
end)
