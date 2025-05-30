Framework = nil
Inventory = nil

-- Get framework
local function InitializeFramework()
    if GetResourceState('es_extended') == 'started' then
        ESX = exports['es_extended']:getSharedObject()
        Framework = 'esx'
    elseif GetResourceState('qbx_core') == 'started' then
        Framework = 'qbx'
    elseif GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
        Framework = 'qb'
    elseif GetResourceState('ox_core') == 'started' then
        Ox = require '@ox_core.lib.init'
        Framework = 'ox'
    else
        -- Add custom framework here
    end
    if not Framework then
        print(
            "Warning: No framework found. Please use either of the following: es_extended, qb-core, qbx_core or ox_core.")
    else
        print("Using framework: " .. Framework)
    end
end

local function InitializeInventory()
    if GetResourceState('ox_inventory') == 'started' then
        Inventory = 'ox_inventory'
        exports('gold_pan', function(event, item, inventory, slot, data)
            if event == 'usingItem' then
                local player = inventory.id
                HandleGoldPanning(player)
            end
        end)
        exports('dirt', function(event, item, inventory, slot, data)
            if event == 'usingItem' then
                local player = inventory.id
                local success = lib.callback.await('ss_goldpanning:client:cleanDirt', player)
                if success then
                    HandleRewardItem(player)
                end
            end
        end)
    elseif GetResourceState('qb-inventory') == 'started' or GetResourceState('ps-inventory') == 'started' or GetResourceState('core_inventory') == 'started' then
        Inventory = GetResourceState('qb-inventory') == 'started' and 'qb-inventory' or
            GetResourceState('ps-inventory') == 'started' and 'ps-inventory' or
            'core_inventory'
        if Framework == 'qb' then
            QBCore.Functions.CreateUseableItem('gold_pan', function(source, item)
                local player = source
                HandleGoldPanning(player)
            end)
            QBCore.Functions.CreateUseableItem(Config.Dirt.DirtItem, function(source, item)
                local player = source
                local success = lib.callback.await('ss_goldpanning:client:cleanDirt', player)
                if success then
                    HandleRewardItem(player)
                end
            end)
        elseif Framework == 'esx' then
            ESX.RegisterUsableItem('gold_pan', function(source)
                local player = source
                HandleGoldPanning(player)
            end)
            ESX.RegisterUsableItem(Config.Dirt.DirtItem, function(source)
                local player = source
                local success = lib.callback.await('ss_goldpanning:client:cleanDirt', player)
                if success then
                    HandleRewardItem(player)
                end
            end)
        end
    elseif GetResourceState('qs-inventory') == 'started' then
        Inventory = 'qs-inventory'
        exports['qs-inventory']:CreateUsableItem('gold_pan', function(source, item)
            local player = source
            HandleGoldPanning(player)
        end)
        exports['qs-inventory']:CreateUsableItem(Config.Dirt.DirtItem, function(source, item)
            local player = source
            local success = lib.callback.await('ss_goldpanning:client:cleanDirt', player)
            if success then
                HandleRewardItem(player)
            end
        end)
    elseif GetResourceState('origen_inventory') == 'started' then
        Inventory = 'origen_inventory'
        exports.origen_inventory:CreateUseableItem('gold_pan', function(source, item)
            local player = source
            HandleGoldPanning(player)
        end)
        exports.origen_inventory:CreateUseableItem(Config.Dirt.DirtItem, function(source, item)
            local player = source
            local success = lib.callback.await('ss_goldpanning:client:cleanDirt', player)
            if success then
                HandleRewardItem(player)
            end
        end)
    else
        print(
            "Warning: No inventory system found. Please use either of the following: ox_inventory, qb-inventory, qs-inventory, ps-inventory, origen_inventory or core_inventory.")
    end

    if not Inventory then
        print(
            "Warning: No inventory system found. Please use either of the following: ox_inventory, qb-inventory, qs-inventory, ps-inventory, origen_inventory or core_inventory.")
    else
        print("Using inventory system: " .. Inventory)
    end
end

-- Get player from source
--- @param source number Player ID
function GetPlayer(source)
    if not source then return end
    if Framework == 'esx' then
        return ESX.GetPlayerFromId(source)
    elseif Framework == 'qb' then
        return QBCore.Functions.GetPlayer(source)
    elseif Framework == 'qbx' then
        return exports.qbx_core:GetPlayer(source)
    elseif Framework == 'ox' then
        return Ox.GetPlayer(source)
    else
        -- Add custom framework here
    end
end

-- Adds an item to players inventory
--- @param source number Player ID
--- @param item string Item to add
--- @param count number Quantity to add
function AddItem(source, item, count, metadata)
    if count <= 0 then return end
    local player = GetPlayer(source)
    if not player then return end
    if Inventory then
        if Inventory == 'ox_inventory' then
            exports[Inventory]:AddItem(source, item, count)
        elseif Inventory == 'core_inventory' then
            exports[Inventory]:addItem(source, item, count)
        else
            exports[Inventory]:AddItem(source, item, count, nil)
            if Framework == 'qb' then
                TriggerClientEvent(Inventory .. ':client:ItemBox', source, QBCore.Shared.Items[item], 'add')
            end
        end
    else
        if Framework == 'esx' then
            player.addInventoryItem(item, count)
        elseif Framework == 'qb' then
            player.Functions.AddItem(item, count, nil)
        else
            -- Add custom framework here
        end
    end
end

-- Removes an item from players inventory
--- @param source number Player ID
--- @param item string Item to remove
--- @param count number Quantity to remove
function RemoveItem(source, item, count)
    local player = GetPlayer(source)
    if not player then return end
    if Inventory then
        if Inventory == 'core_inventory' then
            exports[Inventory]:removeItem(source, item, count)
        else
            exports[Inventory]:RemoveItem(source, item, count)
            if Framework == 'qb' then
                TriggerClientEvent(Inventory .. ':client:ItemBox', source, QBCore.Shared.Items[item], 'remove')
            end
        end
    else
        if Framework == 'esx' then
            player.removeInventoryItem(item, count)
        elseif Framework == 'qb' then
            player.Functions.RemoveItem(item, count)
        else
            -- Add custom framework here
        end
    end
end

-- Returns number of specified item in players inventory
--- @param source number Player ID
--- @param item string Item to search
--- @return number
function GetItemCount(source, item)
    if not source or not item then return 0 end
    local player = GetPlayer(source)
    if not player then return 0 end
    if Inventory then
        if Inventory == 'ox_inventory' then
            return exports[Inventory]:Search(source, 'count', item) or 0
        elseif Inventory == 'core_inventory' then
            return exports[Inventory]:getItemCount(source, item)
        else
            local itemData = exports[Inventory]:GetItemByName(source, item)
            if not itemData then return 0 end
            return itemData.amount or itemData.count or 0
        end
    else
        if Framework == 'esx' then
            local itemData = player.getInventoryItem(item)
            if not itemData then return 0 end
            return itemData.count or itemData.amount or 0
        elseif Framework == 'qb' then
            local itemData = player.Functions.GetItemByName(item)
            if not itemData then return 0 end
            return itemData.amount or itemData.count or 0
        else
            -- Add custom framework here
        end
    end
    return 0
end

function Notify(player, message, type, duration)
    lib.locale()
    if Config.Notify == 'ox_lib' then
        TriggerClientEvent('ox_lib:notify', player, {
            title = 'Gold Panning',
            description = message,
            type = type,
            duration = duration
        })
    elseif Config.Notify == 'qb-core' then
        TriggerClientEvent('QBCore:Notify', player, message, type, duration)
    elseif Config.Notify == 'esx' then
        TriggerClientEvent("esx:showNotification", player, message, type, duration)
    elseif Config.Notify == 'okok' then
        TriggerClientEvent('okokNotify:Alert', player, locale('title'), message, duration, type)
    elseif Config.Notify == 'sd-notify' then
        TriggerClientEvent('sd-notify:Notify', player, locale('title'), message, type, duration)
    elseif Config.Notify == 'wasabi' then
        TriggerClientEvent('wasabi_notify:notify', player, locale('title'), message, duration, type)
    elseif Config.Notify == 'custom' then
        -- Add your custom standalone notification logic here
    else
        print("Warning: Notification system not supported or not configured correctly.")
    end
end

-- Making the Item Useable
if Inventory == 'ox_inventory' then
    exports('gold_pan', function(event, item, inventory, slot, data)
        if event == 'usingItem' then
            local player = inventory.id
            HandleGoldPanning(player)
        end
    end)

    exports('dirt', function(event, item, inventory, slot, data)
        if event == 'usingItem' then
            local player = inventory.id
            local success = lib.callback.await('ss_goldpanning:client:cleanDirt', player)
            if success then
                HandleRewardItem(player)
            end
        end
    end)
elseif Inventory == 'qb-inventory' or 'ps-inventory' or 'core_inventory' then
    if Framework == 'qb' then
        QBCore.Functions.CreateUseableItem('gold_pan', function(source, item)
            local player = source
            HandleGoldPanning(player)
        end)
        QBCore.Functions.CreateUseableItem(Config.Dirt.DirtItem, function(source, item)
            local player = source

            local success = lib.callback.await('ss_goldpanning:client:cleanDirt', player)

            if success then
                HandleRewardItem(player)
            end
        end)
    elseif Framework == 'esx' then
        ESX.RegisterUsableItem('gold_pan', function(source)
            local player = source
            HandleGoldPanning(player)
        end)
        ESX.RegisterUsableItem(Config.Dirt.DirtItem, function(source)
            local player = source

            local success = lib.callback.await('ss_goldpanning:client:cleanDirt', player)

            if success then
                HandleRewardItem(player)
            end
        end)
    end
elseif Inventory == 'qs-inventory' then
    exports['qs-inventory']:CreateUsableItem('gold_pan', function(source, item)
        local player = source
        HandleGoldPanning(player)
    end)
    exports['qs-inventory']:CreateUsableItem(Config.Dirt.DirtItem, function(source, item)
        local player = source

        local success = lib.callback.await('ss_goldpanning:client:cleanDirt', player)

        if success then
            HandleRewardItem(player)
        end
    end)
elseif Inventory == 'origen_inventory' then
    exports.origen_inventory:CreateUseableItem('gold_pan', function(source, item)
        local player = source
        HandleGoldPanning(player)
    end)
    exports.origen_inventory:CreateUseableItem(Config.Dirt.DirtItem, function(source, item)
        local player = source

        local success = lib.callback.await('ss_goldpanning:client:cleanDirt', player)

        if success then
            HandleRewardItem(player)
        end
    end)
else
    print(
        "Warning: No inventory system found. Please use either of the following: ox_inventory, qb-inventory, qs-inventory, ps-inventory, origen_inventory or core_inventory.")
end

-- Initialize defaults
InitializeFramework()
InitializeInventory()
