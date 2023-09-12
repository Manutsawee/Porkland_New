local Rebuilder = Class(function(self, inst)
    self.inst = inst
end)

function Rebuilder:Init(setdelay, randdelay)
    self.setdelay = setdelay
    self.randdelay = randdelay
    self.delaytime = self.inst:DoPeriodicTask(self.setdelay + (math.random() * self.randdelay), function()
        self:Rebuild()
    end)
end

function Rebuilder:Rebuild()
    if self.inst.components.workable and self.inst.components.workable.workleft < self.inst.components.workable.maxwork then
        self.inst.components.workable:SetWorkLeft(self.inst.components.workable.workleft + 1)
        if self.rebuildfn then
            self.rebuildfn(self.inst)
        end
    end
end

function Rebuilder:OnRemoveEntity()
    if self.delaytime then
        self.delaytime:Cancel()
        self.delaytime = nil
    end
end

return Rebuilder
