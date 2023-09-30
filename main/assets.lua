local TheNet = GLOBAL.TheNet
local ToolUtil = GLOBAL.ToolUtil

PrefabFiles = {
    "alloy",
    "aporkalypse_clock",
    "armor_metalplate",
    "asparagus_planted",
    "chitin",
    "deep_jungle_fern_noise",
    "dungball",
    "dungbeetle",
    "dungpile",
    "flower_rainforest",
    "glowfly",
    "grass_tall",
    "gnatmound",
    "gnat",
    "gold_dust",
    "goldpan",
    "halberd",
    "iron",
    "pl_wave_shore",
    "jungle_border_vine",
    "nettle",
    "peagawk",
    "peagawk_spawner",
    "peagawkfeather",
    "porkland_network",
    "pog",
    "pogherd",
    "rabid_beetle",
    "porkland",
    "pl_feathers",
    "pangolden",
    "sedimentpuddle",
    "shears",
    "smelter",
    "tree_pillar",
    "thunderbird",
    "thunderbirdnest",
    -- "tuber",
    -- "tubertrees",
    "weevole_carapace",
    "weevole",
    "basefan",
}

Assets = {
    -- minimap
    Asset("IMAGE", "images/minimap/pl_minimap.tex"),
    Asset("ATLAS", "images/minimap/pl_minimap.xml"),

    -- inventoryimages
    Asset("IMAGE", "images/pl_inventoryimages.tex"),
    Asset("ATLAS", "images/pl_inventoryimages.xml"),
    Asset("ATLAS_BUILD", "images/pl_inventoryimages.xml", 256),  -- for minisign

    -- hud
    Asset("ATLAS", "images/overlays/fx4.xml"),  -- pollen(hayfever)
    Asset("IMAGE", "images/overlays/fx4.tex"),
    Asset("ATLAS", "images/overlays/fx5.xml"),  -- fog
    Asset("IMAGE", "images/overlays/fx5.tex"),

    Asset("ANIM", "anim/moon_aporkalypse_phases.zip"),  -- blood moon

    -- player_actions
    Asset("ANIM", "anim/player_sneeze.zip"),
    Asset("ANIM", "anim/player_mount_sneeze.zip"),
    Asset("ANIM", "anim/player_actions_panning.zip"),
}

ToolUtil.RegisterImageAtlas("images/pl_inventoryimages.xml")
AddMinimapAtlas("images/minimap/pl_minimap.xml")

local sounds = {
    Asset("SOUND", "sound/DLC003_AMB_stream.fsb"),
    Asset("SOUND", "sound/DLC003_music_stream.fsb"),
    Asset("SOUND", "sound/DLC003_sfx.fsb"),
    Asset("SOUNDPACKAGE", "sound/dontstarve_DLC003.fev")
}

if not TheNet:IsDedicated() then
    for _, asset in ipairs(sounds) do
        table.insert(Assets, asset)
    end
end
