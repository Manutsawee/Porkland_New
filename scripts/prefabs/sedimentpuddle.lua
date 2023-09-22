local assets = {
    Asset("ANIM", "anim/gold_puddle.zip"),
}

local ripple_assets = {
    Asset("ANIM", "anim/water_ring_fx.zip"),
}

local prefabs = {
    "gold_dust",
}

local function GetAnim(inst, state)
    local size = "big"

    if inst.stage == 1 then
        size = "small"
    elseif inst.stage == 2 then
        size = "med"
    end

    return size .."_" .. state
end

local function SetDisappearStage(inst, preanim)
    inst.stage = 0
    inst.components.workable:SetWorkLeft(0)
    inst.components.workable:SetWorkable(false)
    inst.components.ripplespawner:SetRange(0)

    inst:AddTag("NOCLICK")

    inst.MiniMapEntity:SetEnabled(false)

    if preanim then
        inst.AnimState:PlayAnimation(preanim)
        --anim:PushAnimation(GetAnim(inst, "idle"), true)
    else
        inst.AnimState:PlayAnimation(GetAnim(inst, "idle"), true)
        inst:Hide()
    end
end

local function PlayAnim(inst, preanim)
    if preanim then
        inst.AnimState:PlayAnimation(preanim)
        inst.AnimState:PushAnimation(GetAnim(inst, "idle"), true)
    else
        inst.AnimState:PlayAnimation(GetAnim(inst, "idle"), true)
    end
end

local stage_data = {
    {stage = 1, workleft = 1, range = 1.6},
    {stage = 2, workleft = 2, range = 2.6},
    {stage = 3, workleft = 3, range = 3.5},
}

local function ChangeStage(inst, data, preanim)
    inst:Show()
    inst.stage = data.stage
    inst.components.workable:SetWorkLeft(data.workleft)
    inst.components.ripplespawner:SetRange(data.range)

    inst:RemoveTag("NOCLICK")

    inst.MiniMapEntity:SetEnabled(true)

    PlayAnim(inst, preanim)
end

local function Spread(inst)
    local stage = inst.stage

    if stage == 0 then
        inst.watercollected = 0
        ChangeStage(inst, stage_data[1], "appear")
    elseif stage == 1 then
        ChangeStage(inst, stage_data[2] , "small_to_med")
    elseif stage == 2 then
        ChangeStage(inst, stage_data[3] , "med_to_big")
    end
end

local function Shrink(inst)
    local stage = inst.stage

    if stage == 3 then
        ChangeStage(inst, stage_data[2], "big_to_med")
    elseif stage == 2 then
        ChangeStage(inst, stage_data[1], "med_to_small")
    elseif stage == 1 then
        inst.watercollected = 0
        SetDisappearStage(inst, "disappear")
    end
end

local function GetWaterLimit()
    return 36 + (math.random() * 8)  -- 36 * 5 = 180 seconds to go up one level .. 3 minutes of rain.
end

local function OnWorkCallback(inst, worker, workleft)
    inst.components.lootdropper:SpawnLootPrefab("gold_dust")
    Shrink(inst, inst.stage)
end

local function OnAnimOver(inst)
    if inst.AnimState:IsCurrentAnimation("disappear") then
        inst:Hide()
    end
end

local function CollectRain(inst)
    print("CollectRain")
    inst.watercollected = inst.watercollected + 1
    if inst.watercollected > inst.waterlimit then
        inst.watercollected = 0
        Spread(inst, inst.stage)
        inst.waterlimit = GetWaterLimit(inst)
    end
end

local function StartSpread(inst)
    inst.spreadtesk = inst:DoPeriodicTask(5, function() CollectRain(inst) end)
end

local function StopSpread(inst)
    inst.spreading = false
    if inst.spreadtesk then
        inst.spreadtesk:Cancel()
        inst.spreadtesk = nil
    end
end

local function OnIsRaining(inst, israining)
    if israining then
        if (inst.stage and inst.stage > 0) or math.random() < 0.2 then
            inst.spreading = true
            StartSpread(inst)
        end
    else
        StopSpread(inst)
    end
end

local function SwitchStage(inst, stage)
    if stage == 0 then
        SetDisappearStage(inst)
    elseif stage == 1 then
        ChangeStage(inst, stage_data[1])
    elseif stage == 2 then
        ChangeStage(inst, stage_data[2])
    elseif stage == 3 then
        ChangeStage(inst, stage_data[3])
    end
end

local function OnSave(inst, data)
    data.stage = inst.stage
    data.growing = inst.growing
    data.watercollected = inst.watercollected
    data.waterlimit = inst.waterlimit
    data.spawned = inst.spawned
    data.rot = inst.Transform:GetRotation()
end

local function OnLoad(inst, data)
    if data ~= nil then
        inst.stage = data.stage
        SwitchStage(inst, inst.stage)

        inst.watercollected = data.watercollected
        inst.waterlimit = data.waterlimit
        inst.growing = data.growing

        if inst.growing then
            StartSpread(inst)
        end

        if data.spawned then
            inst.spawned = true
        end

        if data.rot then
            inst.Transform:SetRotation(data.rot)
        end
    end
end

local function FindVaildLocation(inst)
    local SAFE_EDGE_RANGE = 7
    local SAFE_PUDDLE_RANGE = 7
    local pt = Vector3(inst.Transform:GetWorldPosition())
    local tiles = {}

    for i = 1, 8 do
        local angle = (i - 1) * PI/4
        local offset = Vector3(SAFE_EDGE_RANGE * math.cos(angle), 0, -SAFE_EDGE_RANGE * math.sin(angle))
        local tile = TheWorld.Map:GetTileAtPoint(pt.x + offset.x, 0, pt.z + offset.z)
        table.insert(tiles,tile)
    end

    local offsets = {}
    for i, tile in ipairs(tiles)do
        if tile ~= WORLD_TILES.PAINTED then
            local angle = ((i - 1) * PI/4) - PI
            local offset = Vector3(SAFE_EDGE_RANGE * math.cos(angle), 0, -SAFE_EDGE_RANGE * math.sin(angle))
            table.insert(offsets,offset)
        end
    end

    if #offsets > 0 then
        local offset = Vector3(0, 0, 0)
        for i, noffset in ipairs(offsets) do
            offset = offset + noffset
        end
        offset.x = offset.x / #offsets
        offset.z = offset.z / #offsets

        pt.x = pt.x + offset.x
        pt.y = pt.y + offset.y
        pt.z = pt.z + offset.z

        inst.Transform:SetPosition(pt.x, pt.y, pt.z)
    end

    inst.spawned = true

    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, SAFE_PUDDLE_RANGE, {"sedimentpuddle"})
    if #ents > 1 then
        inst:Remove()
    end
end

local function DoPostInit(inst)
    if not inst.spawned then
        FindVaildLocation(inst)
    end

    if not inst.stage then
        local stage = math.random(0, 3)
        SwitchStage(inst, stage)
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("gold_puddle.tex")

    inst:AddTag("sedimentpuddle")
    inst:AddTag("NOBLOCK")
    inst:AddTag("onfloor")

    inst.AnimState:SetBuild("gold_puddle")
    inst.AnimState:SetBank("gold_puddle")
    -- inst.AnimState:PlayAnimation("big_idle", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(2)

    inst.Transform:SetRotation(math.random() * 360)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("hauntable")
    inst:AddComponent("lootdropper")
    inst:AddComponent("ripplespawner")
    inst:AddComponent("inspectable")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.PAN)
    inst.components.workable:SetWorkLeft(3)
    inst.components.workable:SetOnWorkCallback(OnWorkCallback)

    inst:WatchWorldState("israining", OnIsRaining)
    OnIsRaining(inst, TheWorld.state.israining)

    inst:ListenForEvent("animover", OnAnimOver)

    inst.no_wet_prefix = true
    inst.watercollected = 0
    inst.waterlimit = GetWaterLimit()
    inst.Shrink = Shrink
    inst.Spread = Spread
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:DoTaskInTime(0, DoPostInit)

    return inst
end

local function MakeRipple(speed)
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst:AddTag("NOBLOCK")

        inst.AnimState:SetBuild("water_ring_fx")
        inst.AnimState:SetBank("water_ring_fx")
        inst.AnimState:PlayAnimation(speed)
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetSortOrder(3)
        inst.AnimState:SetMultColour(1, 1, 1, 1)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.persists = false

        inst:ListenForEvent("animover", inst.Remove)
        inst:ListenForEvent("entitysleep", inst.Remove)

        return inst
    end
    return Prefab("puddle_ripple_" .. speed .. "_fx", fn, ripple_assets)
end

return Prefab("sedimentpuddle", fn, assets, prefabs),
    MakeRipple("fast"),
    MakeRipple("slow")
