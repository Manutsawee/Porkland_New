require("brains/thunderbirdbrain")
require ("stategraphs/SGthunderbird")

local assets = {
    Asset("ANIM", "anim/thunderbird.zip"),
}

local fx_assets = {
    Asset("ANIM", "anim/thunderbird_fx.zip"),
}

local prefabs = {
    "drumstick",
    "feather_thunder",
    "thunderbird_fx",
}

local loot = {
    "drumstick",
    "drumstick",
    "feather_thunder"
}

local brain = require("brains/thunderbirdbrain")

local function DoLightning(inst, target)
    local LIGHTNING_COUNT = 3
    local COOLDOWN = 60

    if TheWorld.state.isaporkalypse then
        LIGHTNING_COUNT = 10
    end

    for i = 1, LIGHTNING_COUNT do
        inst:DoTaskInTime(0.4 * i, function()
            local rad = math.random(4, 8)
            local angle = i*((4 * PI) / LIGHTNING_COUNT)
            local pos = Vector3(target.Transform:GetWorldPosition()) + Vector3(rad * math.cos(angle), 0, rad * math.sin(angle))
            TheWorld:PushEvent("ms_sendlightningstrike", pos)
        end)
    end

    inst.cooling_down = true
    inst.components.timer:StartTimer("charge_cd", COOLDOWN)
end

local function SpawnFx(inst)
    if not inst.thunderbird_fx then
        inst.thunderbird_fx = inst:SpawnChild("thunderbird_fx")
        inst.thunderbird_fx.Transform:SetPosition(0,0,0)
    end
end

local function TimerDone(inst, data)
    if data.name == "fleeing_cd" then
        inst.is_fleeing = false
    elseif data.name == "charge_cd" then
        inst.cooling_down = false
    end
end

local function SPECIAL_ACTION(act)
    local inst = act.doer
    inst.sg:GoToState("thunder_attack")
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(1.5, .75)
    inst.Transform:SetFourFaced()

    inst.Light:SetFalloff(.7)
    inst.Light:SetIntensity(.75)
    inst.Light:SetRadius(2.5)
    inst.Light:SetColour(120/255, 120/255, 120/255)
    inst.Light:Enable(true)

    MakeCharacterPhysics(inst, 50, .5)

    inst:AddTag("character")
    -- inst:AddTag("berrythief")
    inst:AddTag("thunderbird")
    inst:AddTag("lightningblocker")

    inst.AnimState:SetBank("thunderbird")
    inst.AnimState:SetBuild("thunderbird")
    inst.AnimState:Hide("hat")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventory")
    inst:AddComponent("inspectable")
    inst:AddComponent("timer")

    inst:AddComponent("sleeper")
    inst.components.sleeper.onlysleepsfromitems = true

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(loot)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.THUNDERBIRD_HEALTH)

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({FOODTYPE.RAW, FOODTYPE.VEGGIE}, {FOODTYPE.RAW})

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"

    inst:AddComponent("locomotor")
    inst.components.locomotor.runspeed = TUNING.THUNDERBIRD_RUN_SPEED
    inst.components.locomotor.walkspeed = TUNING.THUNDERBIRD_WALK_SPEED

    inst:ListenForEvent("timerdone", TimerDone)

    inst:SetStateGraph("SGthunderbird")
    inst:SetBrain(brain)

    inst.DoLightning = DoLightning
    inst.special_action = SPECIAL_ACTION

    MakeHauntablePanic(inst)
    MakeMediumFreezableCharacter(inst, "body")
    MakeMediumBurnableCharacter(inst, "body")
    -- inst.components.burnable.lightningimmune = true

    inst:DoTaskInTime(0, SpawnFx)

    return inst
end

local function fx_fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("NOCLICK")

    inst.AnimState:SetBank("thunderbird_fx")
    inst.AnimState:SetBuild("thunderbird_fx")
    inst.AnimState:SetSortOrder(2)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoTaskInTime(math.random() * 1, function()
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 0.5)
        for _, v in ipairs(ents)do
            if v.prefab == "thunderbird_fx" and v ~= inst then
                v:Remove()
            end
        end
    end)

    return inst
end

c_spawn("thunderbird", 10)

return Prefab("thunderbird", fn, assets, prefabs),
       Prefab("thunderbird_fx", fx_fn, fx_assets)
