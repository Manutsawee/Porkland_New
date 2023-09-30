local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("book_brimstone", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local _OnRead = inst.components.book.onread
    inst.components.book.onread = function(inst, reader)
        if TheWorld:HasTag("porkland") then
            if TheWorld.net == nil or TheWorld.net.components.plateauweather == nil then
                return false
            end

            local pt = reader:GetPosition()
            local num_lightnings = 16

            reader:StartThread(function()
                for k = 0, num_lightnings do
                    local rad = math.random(3, 15)
                    local angle = k * 4 * PI / num_lightnings
                    local pos = pt + Vector3(rad * math.cos(angle), 0, rad * math.sin(angle))
                    TheWorld:PushEvent("ms_sendlightningstrike", pos)
                    Sleep(.3 + math.random() * .2)
                end
            end)
            return true
        else
            return _OnRead(inst, reader)
        end
    end
end)
