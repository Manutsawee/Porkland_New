local function MakeFeather(name)
    local assetname = "feather_" .. name
    local assets = {
	    Asset("ANIM", "anim/" .. assetname .. ".zip"),
    }

    local function fn()
	    local inst = CreateEntity()
	    inst.entity:AddTransform()
	    inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank(assetname)
        inst.AnimState:SetBuild(assetname)
        inst.AnimState:PlayAnimation("idle")

        inst:AddTag("cattoy")
        inst:AddTag("birdfeather")

        MakeInventoryFloatable(inst, "small", 0.05, 0.95)
        MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.LIGHT, TUNING.WINDBLOWN_SCALE_MAX.LIGHT)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst:AddComponent("tradable")

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.TINY_FUEL

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.nobounce = true

        MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
        MakeSmallPropagator(inst)
        MakeHauntableLaunchAndIgnite(inst)

        return inst
    end
    return Prefab(assetname, fn, assets)
end

return MakeFeather("thunder")
