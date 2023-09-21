local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("kramped", function(self, inst)
    local OnPlayerJoined = inst:GetEventCallbacks("ms_playerjoined", TheWorld, "scripts/components/kramped.lua")
    local _OnKilledOther = ToolUtil.GetUpvalue(OnPlayerJoined, "OnKilledOther")
    local _activeplayers = ToolUtil.GetUpvalue(self.GetDebugString, "_activeplayers")
    local OnNaughtyAction

    if _OnKilledOther ~= nil then
        OnNaughtyAction = ToolUtil.GetUpvalue(_OnKilledOther, "OnNaughtyAction")
    end

    local function OnKilledOther(player, data)
        local victim = data.victim
        if data ~= nil and victim and victim:HasTag("city_pig") then
            local naughtiness = 6
            local playerdata = _activeplayers[player]
            local naughty_val = FunctionOrValue(naughtiness, player, data)
            OnNaughtyAction(naughty_val * (data.stackmult or 1), playerdata)
        else
            _OnKilledOther(player, data)
        end
    end

    if OnPlayerJoined ~= nil then
        ToolUtil.SetUpvalue(OnPlayerJoined, OnKilledOther, "OnKilledOther")
    end
end)
