require("stategraphs/commonstates")

local actionhandlers = {
    ActionHandler(ACTIONS.EAT, "eat"),
    ActionHandler(ACTIONS.BARK, "bark_at_friend"),
    ActionHandler(ACTIONS.RANSACK, "ransack"),
}

local events = {
    CommonHandlers.OnSleep(),
    CommonHandlers.OnLocomote(true, true),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttacked(true),
    CommonHandlers.OnDeath(),
    EventHandler("barked_at", function(inst, data)
        if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") and not inst.sg:HasStateTag("preoccupied") and data.belly then
            inst.sg:GoToState("belly")
        else
            if inst.components.sleeper:IsAsleep() then
                inst.components.sleeper:WakeUp()
            end
        end
    end),
    EventHandler("doattack", function(inst, data)
        if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("attack", data.target)
        end
    end),
}

local function Rummage(inst,target)
     if target and target.components.container then
        local CANT_TAGS = {"FX", "NOCLICK", "DECOR","INLIMBO", "aquatic"}
        local food = FindEntity(inst, TUNING.POG_SEE_FOOD, function(item) return inst.components.eater:CanEat(item) and item:IsOnValidGround() and item:GetTimeAlive() > TUNING.POG_EAT_DELAY end, nil, CANT_TAGS)

        local items = target.components.container:FindItems(function() return true end)
        if #items > 0 and not food then
            return true
        end
    end
end

local function TossItems(inst,target)
    if target and target.components.container then
        local items = target.components.container:FindItems(function() return true end)
        if #items > 0 then
            local item = items[math.random(1,#items)]
            item = target.components.container:RemoveItem(item)

            local x,y,z = target.Transform:GetWorldPosition()
            item.Transform:SetPosition(x,1,z)

            local vel = Vector3(0, 5, 0)
            local speed = 3 + math.random()
            local angle = math.random()*2*PI
            vel.x = speed*math.cos(angle)
            vel.y = speed*3
            vel.z = speed*math.sin(angle)
            item.Physics:SetVel(vel.x, vel.y, vel.z)
        end
    end
end

local function bark_at_friends(inst)
    local pt = Vector3(inst.Transform:GetWorldPosition())
    local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, 4, {"pog"})

    local nottriggered  = true
    for i, ent in ipairs(ents)do
        local belly = false
        if ent.sg:HasStateTag("idle") then

            if nottriggered then
                belly = true
                nottriggered = nil
            end
        end
        inst:DoTaskInTime(math.random()*0.3, function() ent:PushEvent("barked_at",{belly = belly})  end)
    end
end

local states = {
    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, playanim)
            inst.components.locomotor:StopMoving()
            if inst.wantstobark then
                inst.wantstobark = nil
                inst.sg:GoToState("bark_at_friend")
            else
                if inst.can_beg and math.random() < 0.6 then
                    inst.sg:GoToState("beg")
                else
                    if playanim then
                        inst.AnimState:PlayAnimation(playanim)
                        inst.AnimState:PushAnimation("idle_loop", true)
                    else
                        inst.AnimState:PlayAnimation("idle_loop", true)
                    end

                    inst.sg:SetTimeout(2 + 2*math.random())
                end
            end
        end,

        ontimeout = function(inst)
            local rand = math.random()

            if inst.can_beg then
                inst.sg:GoToState(rand < .5 and "beg" or rand < 0.75 and "cute" or "tailchase")
            else
                inst.sg:GoToState(rand < .5 and "cute" or "tailchase")
            end
        end,
    },

    State{
        name = "cute",
        tags = {"canrotate"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("emote_cute")
        end,

        timeline = {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/cute") end),
            TimeEvent(28*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/cute") end),
        },

        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "tailchase",
        tags = {"canrotate", "preoccupied"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("emote_tailchase_pre")
        end,

        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("tailchase_loop") end),
        },
    },

    State{
        name = "tailchase_loop",
        tags = {"canrotate", "preoccupied"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("emote_tailchase_loop")
        end,

        timeline = {
            TimeEvent(11*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/bark") end),
        },

        events = {
            EventHandler("animover", function(inst)
                if math.random() < 0.3 then
                    inst.sg:GoToState("tailchase_loop")
                else
                    inst.sg:GoToState("tailchase_pst")
                end
            end),
        },
    },

    State{
        name = "tailchase_pst",
        tags = {"canrotate", "preoccupied"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("emote_tailchase_pst")
        end,

        timeline = {
            TimeEvent(11*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/bark") end),
        },

        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "ransack_pre",
        tags = {"canrotate", "preoccupied"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("rummage_pre")
        end,

        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("ransack") end),
        },
    },

    State{
        name = "ransack",
        tags = {"canrotate", "preoccupied"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            local act = inst:GetBufferedAction()
            local target = act.target
            if act and target and target:HasTag("pogproof") then
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle","rummage_pst")
                inst.wantstobark = target
            else
                if not act or not Rummage(inst, target) or target:HasTag("pogged") then
                    inst:ClearBufferedAction()
                    inst.sg:GoToState("idle","rummage_pst")
                else
                    target.components.container:Open(act.doer)
                    target:AddTag("pogged")
                    inst.ransacking = target
                    inst.AnimState:PlayAnimation("rummage_loop")
                end
            end
        end,

        timeline = {
            TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/rummage") end),
        },

        onupdate = function(inst)
            local p_pt = Vector3(inst.ransacking.Transform:GetWorldPosition())
            local m_pt = Vector3(inst.Transform:GetWorldPosition())
            if distsq(p_pt, m_pt) > 1.5 * 1.5 then
                inst.sg:GoToState("idle", "rummage_pst")
            end
        end,

        onexit = function(inst)
            if inst.ransacking and not inst.keepransacking then
                inst.ransacking.components.container:Close()
                inst.ransacking:RemoveTag("pogged")
            end
            inst.keepransacking = nil
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.keepransacking = true
                inst.sg:GoToState("ransack_throw")
            end),
        },
    },

    State{
        name = "ransack_throw",
        tags = {"canrotate", "preoccupied"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("rummage_throw")
        end,

        timeline = {
            TimeEvent(10*FRAMES, function(inst) TossItems(inst,inst.ransacking) end),
            TimeEvent(9*FRAMES, function(inst) if math.random() < 0.5 then inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/bark",nil,.5) end end),
            TimeEvent(16*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/wilson/make_whoosh") end),
        },

        onexit = function(inst)
            if not inst.keepransacking then
               inst.ransacking.components.container:Close()
            end
            if inst.ransacking then
                inst.ransacking:RemoveTag("pogged")
                inst.ransacking = nil
            end
            inst.keepransacking = nil
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.keepransacking = true
                inst.sg:GoToState("ransack")
            end),
        },
    },

    State{
        name = "beg",
        tags = {"canrotate", "preoccupied"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("emote_beg")
        end,

        timeline = {
            TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/beg") end),
        },

        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "belly",
        tags = {"canrotate"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("emote_belly")
            inst.bellysoundtask = inst:DoTaskInTime(math.random()*(81/30), function() inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/belly")   end )
        end,

        onexit = function(inst)
            inst.bellysoundtask:Cancel()
            inst.bellysoundtask = nil
        end,

        timeline = {
            TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/belly") end),
            TimeEvent(45*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/belly") end),
        },

        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "bark_at_friend",
        tags = {"canrotate", "preoccupied", "busy"},

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("emote_stretch")
        end,

        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },

        timeline = {
            TimeEvent(10*FRAMES, function(inst) bark_at_friends(inst) end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/bark") end),
            TimeEvent(21*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/bark") end),
        },
    },

    State{
        name = "eat",
        tags = {"preoccupied"},

        onenter = function(inst,data)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat_pre")
        end,

        timeline = {
            TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/eat") end),
            ---TimeEvent(21*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/bark") end),
        },

        events = {
            EventHandler("animover", function(inst)
                if inst:PerformBufferedAction() then
                    inst.sg:GoToState("eat_loop")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "eat_loop",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat_loop", true)
            inst.sg:SetTimeout(1+math.random()*1)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle", "eat_pst")
        end,
    },

    State{
        name = "hit",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
        end,

        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },
}

CommonStates.AddFrozenStates(states)
CommonStates.AddSimpleState(states, "refuse", "emote_stretch", {"busy"})
CommonStates.AddWalkStates(states, {
    walktimeline = {
        TimeEvent(FRAMES, function(inst) PlayFootstep(inst) end),
        TimeEvent(8*FRAMES, function(inst) PlayFootstep(inst) end),
        TimeEvent(15*FRAMES, function(inst) PlayFootstep(inst) end),
        TimeEvent(23*FRAMES, function(inst) PlayFootstep(inst) end),
    }
})
CommonStates.AddRunStates(states, {
    runtimeline = {
        TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/step") end)
    }
})
CommonStates.AddSleepStates(states, {
    starttimeline = {
        TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/yawn") end)
    },

    sleeptimeline = {
        TimeEvent(37*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/catcoon/sleep", nil, .25) end)
    },
})
CommonStates.AddCombatStates(states, {
	attacktimeline = {
        TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/bark") end),
        TimeEvent(16*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
	},

	deathtimeline = {
        TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/death") end),
	},
},
{attack = "attack"})

return StateGraph("pog", states, events, "idle", actionhandlers)
