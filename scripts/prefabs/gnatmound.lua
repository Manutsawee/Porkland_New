local assets = {
    Asset("ANIM", "anim/gnat_mound.zip"),
}

local prefabs = {
    "gnat",
}

SetSharedLootTable("gnatmound",{
    {"rocks",  1.00},
    {"rocks",  0.25},
    {"flint",  0.25},
    {"iron",   0.25},
    {"nitre",  0.25},
})

local function OnFinishCallback(inst)
    inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("stone")
    inst:Remove()
end

local function RebuildFn(inst)
    local workleft = inst.components.workable.workleft
    inst.AnimState:PlayAnimation(workleft > 4 and "full" or workleft > 2 and "med2" or "low2", false)
end

local function OnWorkCallback(inst)
    local workleft = inst.components.workable.workleft
    if workleft == 4 or workleft == 2 then
        inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
        inst.SoundEmitter:PlaySound("dontstarve/common/destroy_stone")
        if inst.components.childspawner then
            inst.components.childspawner:ReleaseAllChildren()
        end
    end

    inst.AnimState:PlayAnimation(workleft > 4 and "full" or workleft > 2 and "med" or "low", false)
end

local function OnSave(inst, data)
    data.workleft = inst.components.workable.workleft
end

local function OnLoad(inst, data)
    if data and data.workleft then
        inst.components.workable.workleft = data.workleft
    end
    RebuildFn(inst)
end

local function CanSpawn(inst)
    if TheWorld.state.israining then
        return false
    end
    return true
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("gnat_mound.tex")

    MakeObstaclePhysics(inst, .5)

    inst.AnimState:SetBank("gnat_mound")
    inst.AnimState:SetBuild("gnat_mound")
    inst.AnimState:PlayAnimation("full")

    inst:AddTag("structure")
    inst:AddTag("gnatmound")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("hauntable")
    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("gnatmound")

    inst:AddComponent("rebuilder")
    inst.components.rebuilder:Init(TUNING.TOTAL_DAY_TIME*1.5, TUNING.TOTAL_DAY_TIME*0.5 )
    inst.components.rebuilder.rebuildfn = RebuildFn

    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "gnat"
    inst.components.childspawner:SetRegenPeriod(TUNING.GNATMOUND_REGEN_TIME)
    inst.components.childspawner:SetSpawnPeriod(TUNING.GNATMOUND_RELEASE_TIME)
    inst.components.childspawner:SetMaxChildren(TUNING.GNATMOUND_MAX_CHILDREN)
    inst.components.childspawner.canspawnfn = CanSpawn
    inst.components.childspawner:StartSpawning()
    WorldSettings_ChildSpawner_SpawnPeriod(inst, TUNING.GNATMOUND_RELEASE_TIME, TUNING.GNAT_ENABLED)
    WorldSettings_ChildSpawner_RegenPeriod(inst, TUNING.GNATMOUND_REGEN_TIME, TUNING.GNAT_ENABLED)
    if not TUNING.GNAT_ENABLED then
        inst.components.childspawner.childreninside = 0
    end

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetMaxWork(TUNING.GNATMOUND_MAX_WORK)
    inst.components.workable:SetWorkLeft(TUNING.GNATMOUND_MAX_WORK)
    inst.components.workable:SetOnFinishCallback(OnFinishCallback)
    inst.components.workable:SetOnWorkCallback(OnWorkCallback)

    inst.RebuildFn = RebuildFn
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)
    MakeSnowCovered(inst)

    return inst
end

return Prefab("gnatmound", fn, assets, prefabs)
