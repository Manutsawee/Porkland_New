local modname = modname
GLOBAL.setfenv(1, GLOBAL)

TravelCore.OnUnloadMods[modname] = function()
    TravelCore.WorldLocations[1].PORKLAND = nil

    TravelCore.OnUnloadlevel()
end
