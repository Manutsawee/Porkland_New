local Infester = Class(function(self, inst)
    self.inst = inst
    self.inst:AddTag("infester")
    self.infesting = false
    self.basetime = 8
    self.randtime = 8
    self.onuninfestfn = nil

    self.inst:ListenForEvent("death", function() self:Uninfest() end)
    self.inst:ListenForEvent("freeze", function() self:Uninfest() end)
end)

function Infester:Uninfest()
    self.infesting = false
    if self.target then
        self.target:RemoveChild(self.inst)
        local pos = Vector3(self.target.Transform:GetWorldPosition())
        self.inst.Physics:Teleport(pos.x,pos.y,pos.z)
        self.target.components.infestable:Uninfest(self.inst)
        self.target = nil
    end

    if self.inst.bitetask then
        self.inst.bitetask:Cancel()
        self.inst.bitetask = nil
    end

    if self.onuninfestfn then
        self.onuninfestfn(self.inst)
    end

    self.inst:ClearBufferedAction()
    self.inst:StopUpdatingComponent(self)
end

function Infester:Bite()
    if self.bitefn then
        self.bitefn(self.inst)
    end
    self.inst.bitetask = self.inst:DoTaskInTime(self.basetime + (math.random() * self.randtime), function() self:Bite() end)
end

function Infester:Infest(target)
    if target:HasTag("player") and not target:HasTag("playerghost") and target.components.infestable then
        self.infesting = true
        self.target = target

        if self.stopinfesttestfn then
            self.inst:StartUpdatingComponent(self)
        end

        self.inst.bitetask = self.inst:DoTaskInTime(self.basetime + (math.random() * self.randtime), function() self:Bite() end)

        target:AddChild(self.inst)
        self.inst.AnimState:SetFinalOffset(1)
        self.inst.Physics:Teleport(0,0,0)
        target.components.infestable:Infest(self.inst)
    end
end

function Infester:OnUpdate( dt )
    if self.stopinfesttestfn then
        if self.stopinfesttestfn(self.inst) then
            self:Uninfest()
        end
    end
    if self.target and self.target:HasTag("playerghost") then
        self:Uninfest()
    end
    --[[
    if self.target then
        local pos = Vector3(self.target.Transform:GetWorldPosition())
        self.inst.Transform:SetPosition(pos.x,pos.y,pos.z)
    end
    ]]
end

function Infester:OnRemoveEntity()
    self.inst:RemoveTag("infester")
    self.inst:StopUpdatingComponent(self)
    self.inst:RemoveEventCallback("death", function() self:Uninfest() end)
    self.inst:RemoveEventCallback("freeze", function() self:Uninfest() end)
    if self.inst.bitetask then
        self.inst.bitetask:Cancel()
        self.inst.bitetask = nil
    end
end

Infester.OnRemoveFromEntity = Infester.OnRemoveEntity

return Infester
