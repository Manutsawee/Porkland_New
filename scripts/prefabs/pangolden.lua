require("brains/pangoldenbrain")
require("stategraphs/SGpangolden")

local assets = {
    Asset("ANIM", "anim/pango_basic.zip"),
    Asset("ANIM", "anim/pango_action.zip"),
}

local prefabs = {
    "meat",
}

local brain = require("brains/pangoldenbrain")

SetSharedLootTable("pangolden", {
    {"meat",    1.00},
    {"meat",    1.00},
    {"meat",    1.00},
})

-- local function KeepTarget(inst, target)
--     local target_pt = Vector3(target.Transform:GetWorldPosition())
--     local inst_pt = Vector3(inst.Transform:GetWorldPosition())
--     return (not inst.sg:HasStateTag("ball")) and distsq(target_pt, inst_pt) < TUNING.PANGOLDEN_CHASE_DIST * TUNING.PANGOLDEN_CHASE_DIST
-- end

-- local function OnAttacked(inst, data)
--     inst.components.combat:SetTarget(data.attacker)
-- end

local function OnEat(inst)
    inst.goldlevel = inst.goldlevel + 1/3
end

local function OnLoad(inst, data)
    if data ~= nil then
        if data.goldlevel then
            inst.goldlevel = data.goldlevel
        end
    end
end

local function OnSave(inst, data)
    data.goldlevel = inst.goldlevel
end

local function SpawnGoldNugget(act)
    local inst = act.doer
    local gold = SpawnPrefab("goldnugget")
    local x, y, z = inst.Transform:GetWorldPosition()
    gold.Transform:SetPosition(x, y, z)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(6, 2)
    inst.Transform:SetFourFaced()

    MakeCharacterPhysics(inst, 100, .5)

    inst:AddTag("pangolden")
    inst:AddTag("animal")
    inst:AddTag("largecreature")

    inst.AnimState:SetBank("pango")
    inst.AnimState:SetBuild("pango_action")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("knownlocations")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.PANGOLDEN_HEALTH)

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(3)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("pangolden")

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({FOODTYPE.GOLDDUST}, {FOODTYPE.GOLDDUST})
    inst.components.eater.oneatfn = OnEat

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = TUNING.PANGOLDEN_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.PANGOLDEN_RUN_SPEED

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "pang_bod"
    -- inst.components.combat:SetDefaultDamage(TUNING.PANGOLDEN_DAMAGE)
    -- inst.components.combat:SetRetargetFunction(1, Retarget)
    -- inst.components.combat:SetKeepTargetFunction(KeepTarget)

    -- inst:ListenForEvent("attacked", OnAttacked)

    MakeHauntablePanic(inst)
    MakeLargeBurnableCharacter(inst, "pang_bod")
    MakeLargeFreezableCharacter(inst, "pang_bod")

    inst:SetBrain(brain)
    inst:SetStateGraph("SGpangolden")

    inst.goldlevel = 0
    inst.special_action = SpawnGoldNugget
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("pangolden", fn, assets, prefabs)
