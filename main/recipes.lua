local AddRecipe2 = AddRecipe2
GLOBAL.setfenv(1, GLOBAL)

AddRecipe2("basefan", {Ingredient("alloy", 2), Ingredient("transistor", 2), Ingredient("gears", 1)}, TECH.SCIENCE_TWO, {placer="basefan_placer"}, {"STRUCTURES", "RAIN"})
IACore.SortBefore("basefan", "firesuppressor", "STRUCTURES")
IACore.SortBefore("basefan", "rainometer", "RAIN")
