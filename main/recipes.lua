local AddRecipe2 = AddRecipe2
GLOBAL.setfenv(1, GLOBAL)

AddRecipe2("basefan", {Ingredient("alloy", 2), Ingredient("transistor", 2), Ingredient("gears", 1)}, TECH.SCIENCE_TWO, {placer="basefan_placer"}, {"STRUCTURES", "RAIN"})
TravelCore.SortBefore("basefan", "firesuppressor", "STRUCTURES")
TravelCore.SortBefore("basefan", "rainometer", "RAIN")
