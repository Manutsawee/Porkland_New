local AddBrainPostInit = AddBrainPostInit
GLOBAL.setfenv(1, GLOBAL)

local _DIG_TAGS = {"dungpile"}

AddBrainPostInit("shadowwaxwellbrain", function(self)
    if self.inst.prefab == "shadowworker" then
        local DIG_TAGS = ToolUtil.GetUpvalue(self.OnStart, "DIG_TAGS")
        for k, v in pairs(_DIG_TAGS) do
            table.insert(DIG_TAGS, v)
        end
    end
end)
