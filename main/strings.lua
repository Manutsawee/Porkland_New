local MODROOT = MODROOT
local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

TravelCore.LoadAndTranslateString("scripts/languages/pl_", PLENV)
