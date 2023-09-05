local AddRecipe2 = AddRecipe2
GLOBAL.setfenv(1, GLOBAL)

AddRecipe2("basefan", {Ingredient("alloy", 2), Ingredient("transistor", 2), Ingredient("gears", 1)}, TECH.SCIENCE_TWO, {placer="basefan_placer"}, {"STRUCTURES", "RAIN"})
TravelCore.SortBefore("basefan", "firesuppressor", "STRUCTURES")
TravelCore.SortBefore("basefan", "rainometer", "RAIN")

AddRecipe2("shears", {Ingredient("iron", 2), Ingredient("twigs", 2)}, TECH.SCIENCE_ONE, nil, {"TOOLS"})
TravelCore.SortAfter("shears", "pickaxe", "TOOLS")

AddRecipe2("armor_metalplate", {Ingredient("alloy", 3), Ingredient("hammer", 1)}, TECH.SCIENCE_ONE, nil, {"ARMOUR"})
TravelCore.SortBefore("armor_metalplate", "armor_sanity", "ARMOUR")

AddRecipe2("halberd", {Ingredient("alloy", 1), Ingredient("twigs", 2)}, TECH.SCIENCE_TWO, nil, {"TOOLS","WEAPONS"})
TravelCore.SortAfter("halberd", "goldenpitchfork", "TOOLS")
TravelCore.SortAfter("halberd", "spear_wathgrithr", "WEAPONS")

AddRecipe2("smelter", {Ingredient("cutstone", 6), Ingredient("boards", 4), Ingredient("redgem", 1)}, TECH.SCIENCE_TWO,{placer="smelter_placer"}, {"STRUCTURES", "TOOLS"})
TravelCore.SortAfter("smelter", "turfcraftingstation", "STRUCTURES")
TravelCore.SortAfter("smelter", "archive_resonator_item", "TOOLS")