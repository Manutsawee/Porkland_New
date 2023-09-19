require("brains/gnatbrain")
require("stategraphs/SGgnat")

local assets = {
    Asset("ANIM", "anim/gnat.zip"),
}

local brain = require("brains/gnatbrain")

local function KeepTargetFn(inst, target)
    return target
    and target.components.combat
    and target.components.health
    and not target.components.health:IsDead()
    and not (inst.components.follower and inst.components.follower.leader == target)
    and not (inst.components.follower and inst.components.follower.leader:HasTag("player") and target:HasTag("companion"))
end

local function Retarget(inst)
    local CANT_TAGS = {"FX", "NOCLICK","INLIMBO", "monster"}
    local function fn(guy)
        if inst.components.combat:CanTarget(guy)
            and not (inst.components.follower and inst.components.follower.leader == guy)
            and not (inst.components.follower and inst.components.follower.leader:HasTag("player") and guy:HasTag("companion")) then
            return (guy:HasTag("player") and not guy:HasTag("monster"))
        end
    end
    return FindEntity(inst, TUNING.GNAT_TARGET_DIST, fn, nil, CANT_TAGS)
end

local function Bite(inst)
    if inst.components.infester.target then
        inst.bufferedaction = BufferedAction(inst, inst.components.infester.target, ACTIONS.ATTACK)
        inst:PushEvent("doattack")
    end
end

local function FindLight(inst)
    local CANT_TAGS = {"NOCLICK","INLIMBO"}
    local light = FindEntity(inst, 15, function(guy)
        if guy.Light and guy.Light:IsEnabled() and guy:HasTag("lightsource") then
            return true
        end
    end, nil, CANT_TAGS)
    return light
end

local function StopInfest(inst)
    if TheWorld.state.isdusk or TheWorld.state.isnight then
        local target = FindLight(inst)
        if target and inst:GetDistanceSqToInst(target) > 5*5 then
            return target
        end
    end
end

local function OnUninfest(inst)
    local homeseeker = inst.components.homeseeker
    if not (homeseeker and homeseeker.home and homeseeker.home:IsValid()) then
        inst.components.knownlocations:RememberLocation("home", inst:GetPosition())
    end
end

local function MakeHome(act)
    local inst = act.doer
    local gnatmound = SpawnPrefab("gnatmound")
    local x,y,z = inst.Transform:GetWorldPosition()
    gnatmound.Transform:SetPosition(x,y,z)
    gnatmound.components.workable.workleft = 1
    gnatmound.RebuildFn(gnatmound)
    gnatmound.components.childspawner:TakeOwnership(inst)
    gnatmound.components.childspawner.childreninside = gnatmound.components.childspawner.childreninside -1
    inst:PushEvent("takeoff")
end

local function OnFreeze(inst)
    if inst.components.freezable then
        inst.components.health:SetInvincible(false)
    end
end

local function UnFreeze(inst)
    if inst.components.freezable then
        inst.components.health:SetInvincible(true)
    end
end

local function OnChangeArea(inst, data)
    if data and data.tags and table.contains(data.tags, "Gas_Jungle") then
        inst:DoTaskInTime(1, function()
            inst.components.health:SetInvincible(false)
            local x, y, z = inst.Transform:GetWorldPosition()
            local player = inst.components.infester.target
            if player ~= nil and player:HasTag("player") then
                player:DoTaskInTime(0.5, function()
                    player.components.talker:Say(GetString(player, "ANNOUNCE_GNATS_DIED"))
                end)
            end
            inst.components.health:Kill()
        end)
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(2, .6)
    inst.Transform:SetFourFaced()

    MakeCharacterPhysics(inst, 1, .25)
    inst.Physics:SetCollisionGroup(COLLISION.FLYERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
    --inst.Physics:CollidesWith(COLLISION.INTWALL)

    inst.AnimState:SetBuild("gnat")
    inst.AnimState:SetBank("gnat")
    inst.AnimState:PlayAnimation("idle_loop")
    inst.AnimState:SetRayTestOnBB(true)

    inst:AddTag("gnat")
    inst:AddTag("flying")
    inst:AddTag("insect")
    inst:AddTag("animal")
    inst:AddTag("smallcreature")
    -- inst:AddTag("avoidonhit")
    inst:AddTag("no_durability_loss_on_hit")
    inst:AddTag("hostile")

    -- inst:AddTag("lastresort") -- for auto attacking

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("hauntable")
    inst:AddComponent("knownlocations")
    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")
    inst:AddComponent("timer")
    inst:AddComponent("areaaware")

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_TINY * 2

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(1)
    inst.components.health:SetInvincible(true)

    inst:AddComponent("infester")
    inst.components.infester.bitefn = Bite
    inst.components.infester.stopinfesttestfn = StopInfest
    inst.components.infester.onuninfestfn = OnUninfest

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.walkspeed = TUNING.GNAT_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.GNAT_RUN_SPEED

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "fx_puff"
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat:SetDefaultDamage(1)
    inst.components.combat:SetAttackPeriod(10)
    inst.components.combat:SetRetargetFunction(1, Retarget)

    inst.special_action = MakeHome
    inst.FindLight = FindLight

    inst:ListenForEvent("freeze", OnFreeze)
    inst:ListenForEvent("unfreeze", UnFreeze)
    inst:ListenForEvent("changearea", OnChangeArea)

    MakeTinyFreezableCharacter(inst, "fx_puff")

    inst:SetBrain(brain)
    inst:SetStateGraph("SGgnat")

    return inst
end
return Prefab("gnat", fn, assets)
