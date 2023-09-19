require "behaviours/wander"
require "behaviours/doaction"
require "behaviours/panic"
require "behaviours/findlight"
require "behaviours/follow"

local MAX_WANDER_DIST = 20
local AGRO_DIST = 5
local AGRO_STOP_DIST = 7

local function FindInfestTarget(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local target = FindClosestPlayerInRangeSq(x, y, z, 10 * 10, true)
    if not inst.components.health:IsDead() and not inst.components.freezable:IsFrozen() and target and inst:GetDistanceSqToInst(target) < AGRO_DIST*AGRO_DIST and not inst.components.infester.infesting and not (target.sg and target.sg:HasStateTag("hiding") and target:HasTag("player")) then
        inst.chasingtargettask = inst:DoPeriodicTask(0.2,function()
            if inst:GetDistanceSqToInst(target) > AGRO_STOP_DIST*AGRO_STOP_DIST then
                inst:ClearBufferedAction()
                inst.components.locomotor:Stop()
                inst.sg:GoToState("idle")

                if inst.chasingtargettask then
                    inst.chasingtargettask:Cancel()
                    inst.chasingtargettask = nil
                end
            end
        end)
        return BufferedAction(inst, target, ACTIONS.INFEST)
    end
    return false
end

local function FindLightTarget(inst)
    local light = inst.FindLight(inst)
    if light then
        return light
    end
end

local function MakeNest(inst)
    if not inst.components.homeseeker and not inst.makehome and not inst.makehometime then
        inst.makehometime = inst:DoTaskInTime(TUNING.TOTAL_DAY_TIME * (0.5 + (math.random()*0.5)), function()
            inst.makehome = true
        end)
    end

    if inst.makehome and not inst.components.homeseeker then
        local CANT_TAGS = {"FX", "NOCLICK", "DECOR","INLIMBO"}
        local x,y,z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 4, nil, CANT_TAGS)
        -- 将离水体的最近距离从2修改为4，防止虫丘离水体过近
        if #ents <= 1 and IsSurroundedByLand(x, y, z, 4) then
            inst.makehome = nil
            if inst.makehometime then
                inst.makehometime:Cancel()
                inst.makehometime = nil
            end
            return BufferedAction(inst, nil, ACTIONS.SPECIAL_ACTION)
        end
    end
end

local GnatBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function GnatBrain:OnStart()
    local root = PriorityNode({
        WhileNode(function() return not self.inst.components.infester.infesting end, "not infesting",
        PriorityNode{
            WhileNode(function() return TheWorld.state.isdusk or TheWorld.state.isnight end, "chase light",
                Follow(self.inst, function() return FindLightTarget(self.inst) end, 0, 1, 1)),
            DoAction(self.inst, function() return FindInfestTarget(self.inst) end, "infest", true),
            DoAction(self.inst, function() return MakeNest(self.inst) end, "make nest", true),
            Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST)
        },.5)
    },1)

    self.bt = BT(self.inst, root)
end

return GnatBrain
