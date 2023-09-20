local AddAction = AddAction
local AddComponentAction = AddComponentAction
GLOBAL.setfenv(1, GLOBAL)

local PL_ACTIONS = {
    PEAGAWK_TRANSFORM = Action({}),
    BARK = Action({}, nil, nil, nil, 3),
	RANSACK = Action({}, nil, nil, nil, 0.5),
    INFEST = Action({}, nil, nil, nil, 0.5),
    SPECIAL_ACTION = Action({}, nil, nil, nil, 1.2),
    DIGDUNG = Action({mount_enabled=true}),
	MOUNTDUNG = Action({}),
}

for name, ACTION in pairs(PL_ACTIONS) do
    ACTION.id = name
    ACTION.str = STRINGS.ACTIONS[name] or "PL_ACTION"
    AddAction(ACTION)
end

ACTIONS.PEAGAWK_TRANSFORM.fn = function(act)
    return true  -- Dummy action for flup hiding
end

ACTIONS.BARK.fn = function(act)
	return true
end

ACTIONS.RANSACK.fn = function(act)
	return true
end

ACTIONS.INFEST.fn = function(act)
    if not act.doer.components.infester.infesting then
        act.doer.components.infester:Infest(act.target)
    end
    return true
end

ACTIONS.SPECIAL_ACTION.fn = function(act)
    if act.doer.special_action then
        act.doer.special_action(act)
        return true
    end
end

ACTIONS.DIGDUNG.fn = function(act)
	act.target.components.workable:WorkedBy(act.doer, 1)
end

ACTIONS.MOUNTDUNG.fn = function(act)
    local doer = act.doer
	doer.dung_target:Remove()
    doer:AddTag("hasdung")
    doer.dung_target = nil
end

local _STORE_stroverridefn = ACTIONS.STORE.stroverridefn
function ACTIONS.STORE.stroverridefn(act, ...)
    if act.target and act.target:HasTag("smelter") then
        return STRINGS.ACTIONS.SMELT
    elseif _STORE_stroverridefn then
        return _STORE_stroverridefn(act, ...)
    end
end

local _COOK_stroverridefn = ACTIONS.COOK.stroverridefn
function ACTIONS.COOK.stroverridefn(act, ...)
    if act.target and act.target:HasTag("smelter") then
        return STRINGS.ACTIONS.SMELT
    elseif _COOK_stroverridefn then
        return _COOK_stroverridefn(act, ...)
    end
end

-- SCENE        using an object in the world
-- USEITEM      using an inventory item on an object in the world
-- POINT        using an inventory item on a point in the world
-- EQUIPPED     using an equiped item on yourself or a target object in the world
-- INVENTORY    using an inventory item
local PL_COMPONENT_ACTIONS =
{
    SCENE = { -- args: inst, doer, actions, right

    },

    USEITEM = { -- args: inst, doer, target, actions, right
    },

    POINT = { -- args: inst, doer, pos, actions, right, target

    },

    EQUIPPED = { -- args: inst, doer, target, actions, right

    },

    INVENTORY = { -- args: inst, doer, actions, right


    },
    ISVALID = { -- args: inst, action, right
    },
}

for actiontype, actons in pairs(PL_COMPONENT_ACTIONS) do
    for component, fn in pairs(actons) do
        AddComponentAction(actiontype, component, fn)
    end
end




-- hack
local COMPONENT_ACTIONS = ToolUtil.GetUpvalue(EntityScript.CollectActions, "COMPONENT_ACTIONS")
local SCENE = COMPONENT_ACTIONS.SCENE
local USEITEM = COMPONENT_ACTIONS.USEITEM
local POINT = COMPONENT_ACTIONS.POINT
local EQUIPPED = COMPONENT_ACTIONS.EQUIPPED
local INVENTORY = COMPONENT_ACTIONS.INVENTORY
