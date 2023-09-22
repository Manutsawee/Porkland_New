local assets = {
    Asset("ANIM", "anim/gold_dust.zip"),
}

local function Shine(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    inst.task = nil
    -- if TheWorld.Map:IsOceanAtPoint(x, y, z, false) then
    --     inst.AnimState:PlayAnimation("sparkle_water")
    --     inst.AnimState:PushAnimation("idle_water")
    -- else
        inst.AnimState:PlayAnimation("sparkle")
        inst.AnimState:PushAnimation("idle")
    -- end
    inst.task = inst:DoTaskInTime(4 + math.random() * 5, function() Shine(inst) end)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("idle_water", "idle")
    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.MEDIUM, TUNING.WINDBLOWN_SCALE_MAX.MEDIUM)

    inst:AddTag("molebait")
    inst:AddTag("scarerbait")

    inst.AnimState:SetBank("gold_dust")
    inst.AnimState:SetBuild("gold_dust")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("stackable")
    inst:AddComponent("bait")
    inst:AddComponent("tradable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.GOLDDUST
    inst.components.edible.hungervalue = 1

    MakeHauntableLaunch(inst)

    inst:DoTaskInTime(0, Shine)

    return inst
end

return Prefab("gold_dust", fn, assets)
