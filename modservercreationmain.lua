local modimport = modimport
local modname = modname
GLOBAL.setfenv(1, GLOBAL)

if not rawget(_G, "TravelCore") then
    for i, _modname in ipairs(ModManager:GetEnabledServerModNames()) do
        local modinfo = KnownModIndex:GetModInfo(_modname)
        if modinfo.name == "Travel Core" then
            ModManager:FrontendLoadMod(_modname)
            break
        end
    end
end

modimport("modfrontendmain")
modimport("modcustonsizitems")

TravelCore.WorldLocations[1].PORKLAND = true

scheduler:ExecuteInTime(0, function()  -- Delay a frame so we can get ServerCreationScreen when entering a existing world
    local servercreationscreen = TheFrontEnd:GetOpenScreenOfType("ServerCreationScreen")

    if not (KnownModIndex:IsModEnabled(modname) and servercreationscreen) then
        return
    end

    if not servercreationscreen:CanResume() then  -- Only when first time creating the world
        TravelCore.SetLevelLocations(servercreationscreen, "porkland", 1)  -- Automatically try switching to the porkland Preset
    end
end)
