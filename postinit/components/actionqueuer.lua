local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

-- for client mod ActionQueue
AddComponentPostInit("actionqueuer", function(self)
    self.AddActionList("allclick", "PAN")
    self.AddActionList("leftclick", "PAN")
    self.AddActionList("autocollect", "PAN")
    self.AddActionList("noworkdelay", "PAN")
end)
