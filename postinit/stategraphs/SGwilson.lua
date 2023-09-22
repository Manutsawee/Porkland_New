local AddStategraphState = AddStategraphState
local AddStategraphEvent = AddStategraphEvent
local AddStategraphActionHandler = AddStategraphActionHandler
local AddStategraphPostInit = AddStategraphPostInit
GLOBAL.setfenv(1, GLOBAL)

local actionhandlers = {
    ActionHandler(ACTIONS.PAN, function(inst)
        if not inst.sg:HasStateTag("panning") then
            return "pan_start"
        end
    end),
}

local eventhandlers = {
    EventHandler("sneeze", function(inst, data)
        if not inst.components.health:IsDead() and not inst.components.health:IsInvincible() then
            if inst.sg:HasStateTag("busy") then
                inst.sg.wantstosneeze = true
            else
                inst.sg:GoToState("sneeze")
            end
        end
    end),
}

local states = {
    State{
        name = "sneeze",
        tags = {"busy", "sneeze", "nopredict"},

        onenter = function(inst)
            if inst.components.drownable ~= nil and inst.components.drownable:ShouldDrown() then
                inst.sg:GoToState("sink_fast")
                return
            end

            inst.sg.wantstosneeze = false
            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()

            inst.SoundEmitter:PlaySound("dontstarve/wilson/hit", nil, .02)
            inst.AnimState:PlayAnimation("sneeze")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/characters/sneeze")
            inst:ClearBufferedAction()

            if not inst:HasTag("mime") then
                local sound_name = inst.soundsname or inst.prefab
                local path = inst.talker_path_override or "dontstarve/characters/"

                local sound_event = path .. sound_name .. "/hurt"
                inst.SoundEmitter:PlaySound(inst.hurtsoundoverride or sound_event)
            end

            inst.components.talker:Say(GetString(inst, "ANNOUNCE_SNEEZE"))
        end,

        timeline =
        {
            TimeEvent(10 * FRAMES, function(inst)
                if inst.components.hayfever then
                    inst.components.hayfever:DoSneezeEffects()
                end
                inst.sg:RemoveStateTag("busy")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "pan_start",
        tags = {"prepan", "panning", "working"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("pan_pre")
        end,

        events = {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst) inst.sg:GoToState("pan") end),
        },
    },

    State{
        name = "pan",
        tags = {"prepan", "panning", "working"},

        onenter = function(inst)
            inst.sg.statemem.action = inst:GetBufferedAction()
            inst.AnimState:PlayAnimation("pan_loop", true)
            inst.sg:SetTimeout(1 + math.random())
        end,

        timeline = {
            TimeEvent(6 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/pool/pan") end),
            TimeEvent(14 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/pool/pan") end),
            TimeEvent((6 + 15) * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/pool/pan") end),
            TimeEvent((14 + 15) * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/pool/pan") end),
            TimeEvent((6 + 30) * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/pool/pan") end),
            TimeEvent((14 + 30) * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/pool/pan") end),
            TimeEvent((6 + 45) * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/pool/pan") end),
            TimeEvent((14 + 45) * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/pool/pan") end),
            TimeEvent((6 + 60) * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/pool/pan") end),
            TimeEvent((14 + 60) * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/pool/pan") end),
        },

        ontimeout = function(inst)
            inst:PerformBufferedAction()
            inst.sg:GoToState("idle", "pan_pst")
        end,

        events = {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle", "pan_pst") end),
        },
    },
}

for _, actionhandler in ipairs(actionhandlers) do
    AddStategraphActionHandler("wilson", actionhandler)
end

for _, eventhandler in ipairs(eventhandlers) do
    AddStategraphEvent("wilson", eventhandler)
end

for _, state in ipairs(states) do
    AddStategraphState("wilson", state)
end

AddStategraphPostInit("wilson", function(sg)
    local _attack_deststate = sg.actionhandlers[ACTIONS.ATTACK].deststate
    sg.actionhandlers[ACTIONS.ATTACK].deststate = function(inst, ...)
        if not inst.sg:HasStateTag("sneeze") then
            return _attack_deststate and _attack_deststate(inst, ...)
        end
    end

    local _attacked_eventhandler = sg.events.attacked.fn
    sg.events.attacked.fn = function(inst, data)
        if data.attacker and (data.attacker:HasTag("insect"))then
            local is_idle = inst.sg:HasStateTag("idle")
            if not is_idle then
                return
            end
        end

        if _attacked_eventhandler ~= nil then
            _attacked_eventhandler(inst, data)
        end
    end

    local _idle_onenter = sg.states["idle"].onenter
    sg.states["idle"].onenter = function(inst, ...)
        if not (inst.components.drownable ~= nil and inst.components.drownable:ShouldDrown()) then
            if inst.sg.wantstosneeze then
                inst.components.locomotor:Stop()
                inst.components.locomotor:Clear()

                inst.sg:GoToState("sneeze")
                return
            end
        end

        if _idle_onenter ~= nil then
            return _idle_onenter(inst, ...)
        end
    end

    local _mounted_idle_onenter = sg.states["mounted_idle"].onenter
    sg.states["mounted_idle"].onenter = function(inst, ...)
        if inst.sg.wantstosneeze then
            inst.sg:GoToState("sneeze")
            return
        end

        if _mounted_idle_onenter ~= nil then
            return _mounted_idle_onenter(inst, ...)
        end
    end
end)
