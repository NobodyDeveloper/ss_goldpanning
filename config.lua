Config = {}

-- This script will auto detect the inventory and Framework.
-- Visit sv-functions.lua to add your own Framework or Inventory system. if not supported by default.

Config.Debug = false -- Enable debug messages

Config.Target = 'ox_target' -- Target system to use (e.g., 'ox_target', 'qb-target', Set to 'none' if you don't want to use a target system)

-- Notification system to use Can be: 'ox_lib', 'qb-core', 'esx', 'okok', 'sd-notify', 'wasabi', 'custom'
Config.Notify = 'ox_lib'

-- Time in seconds it takes to fill the pan
Config.PanFillDuration = 5

Config.Gold = {
    GoldChance = 0.25,              -- Chance to find gold when panning
    GoldReward = {
        Min = 1,                    -- Minimum amount of gold nuggets found when panning
        Max = 1,                    -- Maximum amount of gold nuggets found when panning
    },
    GoldNuggetItem = 'gold_nugget', -- Item name for the gold nugget
    -- Multiplier for the gold reward when panning
    GoldRushZoneChance = 0.35,      -- Chance to get a gold rush zone multiplier when in the zone (0.5 = 50%)
    GoldRushZoneMultiplier = 2      -- Multiplier for the gold reward when in a Gold Rush zone
}

Config.GoldSmelting = {
    -- Allow the player to smelt gold nuggets into gold bars (Disable if you want to use your own)
    AllowSmelting = false, -- Enable or disable gold smelting
    showBlip = false,      -- Show a blip on the map for the smelting location
    Locations = {
        {
            coords = vector3(1086.2880859375, -2003.7022705078, 31.173924636841), -- Coordinates of the smelting location
            size = 5.0,                                                           -- Size of the smelting area
        },
    },
    SmeltingTime = 5,         -- Time in seconds to smelt gold nuggets into bars
    NuggetsRequired = 100,    -- Number of gold nuggets required to smelt into a bar
    GoldBarItem = 'gold_bar', -- Item name for the gold bar
}

Config.Dirt = {
    AllowDirtItem = true,   -- Allow the player to find dirt (filler Items) when panning
    CleaningTime = 5,       -- Time in seconds to clean the dirt item
    DirtChance = 0.4,       -- Chance to find dirt when panning
    ItemInDirtChance = 0.4, -- Chance to find an item in the dirt when cleaning it
    DirtItem = 'dirt',      -- Item name for the dirt item

    -- Below is the table of rewards for the dirt item.
    -- Chance is between 0 and 100, if 2 or more items have the same chance, one will be selected randomly.
    -- The min and max values are the range of items that can be given.
    -- Atleast one item must be 100 chance, otherwise their will be no reward if the player rolls above the highest chance.
    DirtRewards = {
        [1] = { item = 'bandage', min = 1, max = 1, chance = 90 },
        [2] = { item = 'lighter', min = 1, max = 1, chance = 90 },
        [3] = { item = 'metalscrap', min = 1, max = 2, chance = 90 },
        [4] = { item = 'iron', min = 1, max = 2, chance = 90 },

    }
}



-- Gold Rush Zones
-- These use polyzones, Make sure all the z coords are the same height, otherwise your polyzones won't work.
Config.GoldRushZones = {
    {
        name = 'Zancudo Trail',
        showBlip = false,
        coords = {
            vector3(-691.3, 2915.88, 14.16),
            vector3(-681.07, 2894.38, 14.16),
            vector3(-626.36, 2930.81, 14.16),
            vector3(-573.63, 2921.27, 14.16),
            vector3(-515.32, 2889.39, 14.16),
            vector3(-503.77, 2919.51, 14.16),
            vector3(-534.06, 2940.54, 14.16),
            vector3(-587.62, 2974.02, 14.16)
        }
    },
    {
        name = 'Cassidy Trail',
        showBlip = false,
        coords = {
            vector3(-1169.57, 4374.35, 5.6),
            vector3(-1163.99, 4401.01, 5.6),
            vector3(-1188.46, 4402.87, 5.6),
            vector3(-1233.29, 4404.85, 5.6),
            vector3(-1246.73, 4416.37, 5.6),
            vector3(-1251.66, 4418.56, 5.6),
            vector3(-1278.84, 4382.44, 5.6),
            vector3(-1328.47, 4366.23, 5.6),
            vector3(-1325.32, 4337.28, 5.6)
        }
    },
    {
        name = 'Cassidy Trail 2',
        showBlip = false,
        coords = {
            vector3(-637.14, 4408.4, 15.98),
            vector3(-627.2, 4453.92, 15.98),
            vector3(-685.14, 4456.34, 15.98),
            vector3(-743.57, 4457.28, 15.98),
            vector3(-785.6, 4442.45, 15.98),
            vector3(-761.58, 4434.57, 15.98)
        }
    },
    {
        name = 'Tataviam Mountains',
        showBlip = false,
        coords = {
            vector3(1871.33, 211.26, 161.86),
            vector3(2001.48, 346.64, 161.86),
            vector3(2057.17, 443.36, 161.86),
            vector3(2020.22, 521.2, 161.86),
            vector3(2010.47, 629.73, 161.86),
            vector3(1983.35, 690.07, 161.86),
            vector3(1976.8, 665.93, 161.86),
            vector3(1958.4, 560.97, 161.86),
            vector3(1874.09, 455.7, 161.86),
            vector3(1807.29, 443.77, 161.86),
            vector3(1821.61, 368.91, 161.86),
            vector3(1818.36, 268.12, 161.86)
        }
    }

}
