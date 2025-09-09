Config = {}

-- How many graves are assigned per contract
Config.MinGraves = 1
Config.MaxGraves = 7

-- Cooldown in minutes
Config.Cooldown = 30

-- Target system (qb-target or ox_target)
Config.Target = "qb" -- options: "qb", "ox"
Config.Inventory = "qb" -- "qb" or "ox"

-- Loot table
Config.LootTable = {
    { item = "goldbar", chance = 100, amount = {1, 2} },
    { item = "diamond", chance = 100, amount = {1, 1} },
    { item = "rolex", chance = 100, amount = {1, 3} },
}


-- NPC Settings
Config.NPC = {
    model = "a_m_m_hasjew_01",
    coords = vector4(372.92, -1441.33, 29.43, 226.93), -- graveyard area
}

-- Grave locations
Config.Graves = {
    vector3(-1641.49, -154.83, 57.62),
    vector3(-1657.57, -159.48, 57.51),
    vector3(-1709.41, -184.31, 58.02),
    vector3(-1710.54, -220.77, 57.56),
    vector3(-1726.69, -224.2, 56.33),
    vector3(-1712.52, -225.29, 56.42),
    vector3(-1697.17, -221.86, 57.53),
}
--Random NPC Ambush Settings
Config.Ambush = {
    enabled = true,
    model = "g_m_m_chicold_01",
    weapon = "WEAPON_HEAVYPISTOL",
    spawnPoints = {
        vector3(-1764.51, -173.88, 62.47),
    },
    despawnDistance = 200.0,
    scaling = {
        [1] = {min=0, max=1},
        [2] = {min=0, max=1},
        [3] = {min=1, max=2},
        [4] = {min=1, max=2},
        [5] = {min=2, max=3},
        [6] = {min=2, max=3},
        [7] = {min=2, max=3},
    },
    chance = 30,  -- % chance to spawn per grave
}

Config.Marker = {
    type = 1,          -- Marker type (1 = cylinder, see https://docs.fivem.net/docs/game-references/markers/)
    scale = vector3(1.5, 1.5, 0.5),  -- Size of the marker (x, y, z)
    color = { r = 150, g = 0, b = 200, a = 150 }, -- RGBA color
}

Config.Prompt = {
    text = "[E] Dig Grave",      -- The prompt text
    scale = 0.35,                -- Text size
    color = { r = 255, g = 255, b = 255, a = 255 }, -- RGBA color
    offset = 0.2                 -- Height above the marker
}

-- Dispatch (customizable)
Config.Dispatch = function(src, coords)
    -- Example with ps-dispatch
    TriggerEvent("ps-dispatch:server:policeAlert", {
        coords = coords,
        message = "Suspicious grave robbing reported!"
    })

    -- Or qb-policejob
    -- TriggerClientEvent('police:client:policeAlert', -1, "Suspicious grave robbing reported!", coords)
end
