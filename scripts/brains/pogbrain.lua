require "behaviours/follow"
require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/panic"
require "behaviours/runaway"
require "behaviours/leash"
require "behaviours/doaction"
require "behaviours/chaseandattack"

local BrainCommon = require("brains/braincommon")

local MIN_FOLLOW_DIST = 0
local MAX_FOLLOW_DIST = 12
local TARGET_FOLLOW_DIST = 6
local FOLLOWPLAYER_DIST = 30

local WANDER_DIST_DAY = 20
local WANDER_DIST_NIGHT = 5
local BARK_AT_FRIEND_DIST = 12

local START_FACE_DIST = 4
local KEEP_FACE_DIST = 6

local MAX_CHASE_TIME = 4
local MAX_CHASE_DIST = 10

local CANT_TAGS = {"FX", "NOCLICK", "DECOR","INLIMBO", "stump", "burnt"}
local MUST_ONEOF_TAGS = {"cattoy", "cattoyairborne", "catfood"}

local PogBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function EatFoodAction(inst)
    local target = nil

    if inst.components.inventory and inst.components.eater then
        target = inst.components.inventory:FindItem(function(item) return inst.components.eater:CanEat(item) end)
    end

    if not target then
        local CANT_TAGS = {"FX", "NOCLICK", "DECOR","INLIMBO", "aquatic"}
        target = FindEntity(inst, TUNING.POG_SEE_FOOD, function(item) return inst.components.eater:CanEat(item) and not item:HasTag("poisonous") and item:IsOnValidGround() and item:GetTimeAlive() > TUNING.POG_EAT_DELAY end, nil, CANT_TAGS)

        local pt = Vector3(inst.Transform:GetWorldPosition())
        local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, TUNING.POG_SEE_FOOD, {"pog"})
        for i,ent in ipairs(ents)do

            -- if another nearby pog is already going to this food, maybe go after it?
            if ((ent.components.locomotor.bufferedaction and ent.components.locomotor.bufferedaction.target and ent.components.locomotor.bufferedaction.target == target) or
                (inst.bufferedaction and inst.bufferedaction.target and inst.bufferedaction.target == target) )
                and ent ~= inst then
                if math.random() < 0.9 then
                    return nil
                end
            end
        end
    end
    if target then
        return BufferedAction(inst, target, ACTIONS.EAT)
    end
end

local function GetLeader(inst)
    return inst.components.follower.leader
end

local function GetPlayerTarget(inst, distance)
    local CANT_TAGS = {"playerghost", "INLIMBO"}
    local MUST_ONEOF_TAGS = {"player", "monster", "scarytoprey"}
    local target = FindEntity(inst, distance, nil, nil, CANT_TAGS, MUST_ONEOF_TAGS)
    if target then
        return target
    end
end

local function GetFaceTargetFn(inst)
    local target = FindEntity(inst, START_FACE_DIST, nil, nil, CANT_TAGS, MUST_ONEOF_TAGS)
    if target and not target:HasTag("notarget") then
        return target
    end
end

local function KeepFaceTargetFn(inst, target)
    return inst:GetDistanceSqToInst(target) <= KEEP_FACE_DIST * KEEP_FACE_DIST and not target:HasTag("notarget")
end

local function GetWanderDistFn(inst)
    if TheWorld.state.isday then
        return WANDER_DIST_NIGHT
    else
        return WANDER_DIST_DAY
    end
end

local function BarkAtFriend(inst)
    local target = FindEntity(inst, BARK_AT_FRIEND_DIST, function(item) return (item.sg and item.sg:HasStateTag("idle")) or item:HasTag("pogproof") end, nil,nil,{"pog","pogproof"}) --  item:HasTag("pog") and
    if target and ((target:HasTag("pogproof") and math.random() < 0.05) or math.random() < 0.01) then
        return BufferedAction(inst, target, ACTIONS.BARK)
    end
end

local function Ransack(inst)
    local CANT_TAGS = {"pogproof", "aquatic"}
    local MUST_TAGS = {"structure"}
    local pt = Vector3(inst.Transform:GetWorldPosition())
    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, TUNING.POG_SEE_FOOD, MUST_TAGS, CANT_TAGS)
    local containers = {}
    for i, ent in ipairs(ents) do
        if ent.components.container then
            table.insert(containers,ent)
        end
    end

    if #containers > 0 then
        local container = containers[math.random(1,#containers)]
        local items = container.components.container:FindItems(function() return true end)
        if #items > 0 then
            return BufferedAction(inst, container, ACTIONS.RANSACK)
        end
    end
end

local function HarassPlayer(inst)
    if not GetLeader(inst) then
        local target = GetPlayerTarget(inst, FOLLOWPLAYER_DIST)
        local item
        local target_pt
        local item_pt

        if target and target.components.inventory then
            target_pt = Vector3(target.Transform:GetWorldPosition())
            item_pt = Vector3(inst.Transform:GetWorldPosition())
            item = target.components.inventory:FindItem(function(item) return inst.components.eater:CanEat(item) end )
        end

        if item and distsq(target_pt, item_pt) < FOLLOWPLAYER_DIST * FOLLOWPLAYER_DIST and not (target and target.components.driver and target.components.driver:GetIsDriving()) then
            return target
        end
    end
end

local function SuggestTarget(inst)
    local player = GetPlayerTarget(inst, 15)
    if player ~= nil then
        inst.components.combat:SuggestTarget(player)
    end
end

function PogBrain:OnStart()
    local root =
    PriorityNode({
        BrainCommon.PanicTrigger(self.inst),
        DoAction(self.inst, function() return EatFoodAction(self.inst) end, "Eat", true),
        IfNode(function() return TheWorld.state.isaporkalypse end, "AporkalypseActive",
            ChaseAndAttack(self.inst, MAX_CHASE_TIME * 5, MAX_CHASE_DIST * 5 )),
        ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST),
        DoAction(self.inst, function() return Ransack(self.inst) end, "ransack", true),
        Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),
        FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
        Follow(self.inst, function() return HarassPlayer(self.inst) end, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST, true),
        DoAction(self.inst, function() return BarkAtFriend(self.inst) end, "Bark at friend", true),
        Wander(self.inst, function() return self.inst:GetPosition() end, GetWanderDistFn)
    }, .25)

    self.bt = BT(self.inst, root)
end

return PogBrain
