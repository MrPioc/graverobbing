local QBCore = exports['qb-core']:GetCoreObject()
local activeGraves = {}
local completedGraves = {}
local robbing = false
local showMarkers = false
local cooldown = false

-- Create relationship group for ambush NPCs (once)
local ambushGroup = GetHashKey("AMBUSHPEDS")
AddRelationshipGroup("AMBUSHPEDS")
SetRelationshipBetweenGroups(0, ambushGroup, ambushGroup)      -- Friendly to each other
SetRelationshipBetweenGroups(5, ambushGroup, GetHashKey("PLAYER")) -- Hostile to players
SetRelationshipBetweenGroups(5, GetHashKey("PLAYER"), ambushGroup)

-- Spawn Gravedigger NPC
CreateThread(function()
    local pedModel = joaat(Config.NPC.model)
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do Wait(0) end
    local npc = CreatePed(0, pedModel, Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z - 1.0, Config.NPC.coords.w, false, true)
    SetEntityInvincible(npc, true)
    FreezeEntityPosition(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)

    if Config.Target == "qb" then
        exports['qb-target']:AddTargetEntity(npc, {
            options = {
                {
                    type = "client",
                    event = "forged_graverobbing:startContract",
                    icon = "fas fa-skull-crossbones",
                    label = "Talk to Gravedigger",
                },
            },
            distance = 2.0
        })
    else
        exports.ox_target:addLocalEntity(npc, {
            {
                name = "forged_graverobbing:startContract",
                event = "forged_graverobbing:startContract",
                icon = "fas fa-skull-crossbones",
                label = "Talk to Gravedigger",
            }
        })
    end
end)

-- Draw markers + prompts
CreateThread(function()
    while true do
        Wait(0)
        if showMarkers and #activeGraves > 0 then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            for i, grave in pairs(activeGraves) do
                if not completedGraves[i] then
                    DrawMarker(
                        Config.Marker.type,
                        grave.x, grave.y, grave.z - 1.0,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        Config.Marker.scale.x, Config.Marker.scale.y, Config.Marker.scale.z,
                        Config.Marker.color.r, Config.Marker.color.g, Config.Marker.color.b, Config.Marker.color.a,
                        false, true, 2, nil, nil, false
                    )

                    if #(coords - vector3(grave.x, grave.y, grave.z)) < 2.0 then
                        local promptPos = vector3(grave.x, grave.y, grave.z + Config.Prompt.offset)
                        local dug = table.count(completedGraves, true)
                        local text = Config.Prompt.text
                        if #activeGraves > 1 then
                            text = text.." ("..(dug + 1).." of "..#activeGraves..")"
                        end
                        QBCore.Functions.DrawText3D(promptPos.x, promptPos.y, promptPos.z, text, Config.Prompt.scale, Config.Prompt.color)
                        if IsControlJustReleased(0, 38) and not robbing then
                            TriggerEvent("forged_graverobbing:digGrave", i)
                        end
                    end
                end
            end
        end
    end
end)

-- Start contract
RegisterNetEvent("forged_graverobbing:startContract", function()
    if #activeGraves > 0 then
        QBCore.Functions.Notify("You already have a grave contract!", "error")
        return
    end

    local hour = GetClockHours()
    if hour < 22 and hour >= 5 then
        QBCore.Functions.Notify("You can only rob graves at night!", "error")
        return
    end

    if cooldown then
        QBCore.Functions.Notify("You must wait before starting another grave robbery.", "error")
        return
    end

    local numGraves = math.random(Config.MinGraves, Config.MaxGraves)
    activeGraves = {}
    completedGraves = {}

    local gravesCopy = {}
    for k, v in pairs(Config.Graves) do gravesCopy[#gravesCopy+1] = v end

    for i=1, numGraves do
        local index = math.random(#gravesCopy)
        activeGraves[i] = gravesCopy[index]
        table.remove(gravesCopy, index)
        completedGraves[i] = false
    end

    showMarkers = true
    QBCore.Functions.Notify(("The gravedigger gave you %d graves to dig..."):format(numGraves), "success")
end)

-- Digging
RegisterNetEvent("forged_graverobbing:digGrave", function(graveIndex)
    if robbing or not activeGraves[graveIndex] then return end
    robbing = true

    QBCore.Functions.Progressbar("digging_grave", "Digging up the grave...", 10000, false, true, {
        disableMovement = true, disableCarMovement = true,
        disableMouse = false, disableCombat = true,
    }, {
        animDict = "amb@world_human_gardener_plant@male@base",
        anim = "base", flags = 49,
    }, {}, {}, function()
        ClearPedTasks(PlayerPedId())
        completedGraves[graveIndex] = true
        TriggerServerEvent("forged_graverobbing:reward")
        TriggerServerEvent("forged_graverobbing:dispatch")

        -- Random ambush scaled by number of graves with chance
        if Config.Ambush.enabled then
            if math.random(1, 100) <= Config.Ambush.chance then
                local numGraves = #activeGraves
                local scale = Config.Ambush.scaling[numGraves] or {min=1,max=2}
                local numNPCs = math.random(scale.min, scale.max)

                for i=1, numNPCs do
                    TriggerServerEvent("forged_graverobbing:spawnAmbush", activeGraves[graveIndex])
                end
            end
        end

        local allDone = true
        for i, done in pairs(completedGraves) do
            if not done then allDone = false break end
        end
        if allDone then
            cleanupGraves()
            cooldown = true
            SetTimeout(Config.Cooldown * 60000, function()
                cooldown = false
            end)
        end

        robbing = false
    end, function()
        ClearPedTasks(PlayerPedId())
        QBCore.Functions.Notify("You stopped digging.", "error")
        robbing = false
    end)
end)

-- Cleanup
function cleanupGraves()
    robbing = false
    showMarkers = false
    activeGraves = {}
    completedGraves = {}
end

-- Ox_inventory notify with item image
RegisterNetEvent("ox:notifyLoot", function(item, amount)
    local items = exports.ox_inventory:Items()
    local data = items[item]

    if data then
        lib.notify({
            title = "You received loot",
            description = ("x%d %s"):format(amount, data.label),
            type = "success",
            icon = data.image,
        })
    else
        lib.notify({
            title = "You received loot",
            description = ("x%d %s"):format(amount, item),
            type = "success",
        })
    end
end)

-- Spawn ambush NPC for all clients
RegisterNetEvent("forged_graverobbing:spawnAmbushClient", function(grave, pedModelName, weaponName)
    local pedModel = joaat(pedModelName)
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do Wait(0) end

    -- Pick a random spawn point from the config
    local spawnPoint = Config.Ambush.spawnPoints[math.random(1, #Config.Ambush.spawnPoints)]
    local x, y, z = spawnPoint.x, spawnPoint.y, spawnPoint.z

    local ped = CreatePed(4, pedModel, x, y, z, 0.0, true, true)

    -- Assign relationship group (already set globally)
    SetPedRelationshipGroupHash(ped, ambushGroup)

    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    GiveWeaponToPed(ped, GetHashKey(weaponName), 100, false, true)
    TaskCombatPed(ped, PlayerPedId(), 0, 16)
    SetPedKeepTask(ped, true)

    CreateThread(function()
        while DoesEntityExist(ped) do
            Wait(1000)
            local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(ped))
            if dist > Config.Ambush.despawnDistance or IsEntityDead(ped) then
                DeletePed(ped)
                break
            end
        end
    end)
end)

-- Helper
function table.count(t, val)
    local c = 0
    for k,v in pairs(t) do
        if v == val then c = c + 1 end
    end
    return c
end
