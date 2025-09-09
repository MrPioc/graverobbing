local QBCore = exports['qb-core']:GetCoreObject()

-- Reward player
RegisterNetEvent("forged_graverobbing:reward", function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local lootItem = Config.Loot[math.random(1, #Config.Loot)]
    local amount = math.random(lootItem.min, lootItem.max)

    if Config.InventoryType == "qb" then
        Player.Functions.AddItem(lootItem.name, amount)
        TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[lootItem.name], "add", amount)
    else
        TriggerClientEvent("ox_inventory:addItem", src, lootItem.name, amount)
        TriggerClientEvent("ox:notifyLoot", src, lootItem.name, amount)
    end
end)

-- Dispatch placeholder
RegisterNetEvent("forged_graverobbing:dispatch", function()
    local src = source
    if Config.Dispatch then
        -- Custom dispatch logic here
    end
end)

-- Spawn ambush NPC for all clients
RegisterNetEvent("forged_graverobbing:spawnAmbush", function(grave)
    TriggerClientEvent("forged_graverobbing:spawnAmbushClient", -1, grave, Config.Ambush.model, Config.Ambush.weapon)
end)
