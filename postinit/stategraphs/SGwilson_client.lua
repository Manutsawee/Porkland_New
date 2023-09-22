local AddStategraphState = AddStategraphState
local AddStategraphActionHandler = AddStategraphActionHandler
GLOBAL.setfenv(1, GLOBAL)

local TIMEOUT = 2

local actionhandlers = {
    ActionHandler(ACTIONS.PAN, function(inst)
        return not inst.sg:HasStateTag("prepan") and "pan_start" or nil
    end),
}

local states = {
    State{
        name = "pan_start",
        tags = {"prepan", "panning", "working"},
        server_states = {"pan_start", "pan"},

        onenter = function(inst)
            inst.components.locomotor:Stop()

            if not inst.sg:ServerStateMatches() then
                inst.AnimState:PlayAnimation("pan_pre")
                inst.AnimState:PushAnimation("pan_loop", true)
            end

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst.sg:ServerStateMatches() then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("pan_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("pan_pst")
            inst.sg:GoToState("idle", true)
        end
    },
}

for _, actionhandler in ipairs(actionhandlers) do
    AddStategraphActionHandler("wilson_client", actionhandler)
end

for _, state in ipairs(states) do
    AddStategraphState("wilson_client", state)
end

-- AddStategraphPostInit("wilson", function(sg)
-- end)
