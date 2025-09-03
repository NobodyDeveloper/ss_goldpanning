local playersPanning = {}

if Config.Framework == 'qb-core' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
end

function HandleGoldPanning(player)
    TriggerClientEvent('ss_goldpanning:client:useGoldPan', player)
    playersPanning[player] = true
end

function HandleRewardItem(player)
    -- Roll a single random number
    local roll = math.random(1, 100)
    local noRewardRoll = math.random(1, 100)

    local chance = Config.Dirt.ItemInDirtChance * 100

    if noRewardRoll >= chance then
        Notify(player, locale('nothingFoundDirt'), "error", 8000)
        RemoveItem(player, Config.Dirt.DirtItem, 1)
        return
    end


    -- Sort the rewards by chance in ascending order
    table.sort(Config.Dirt.DirtRewards, function(a, b)
        return a.chance < b.chance
    end)

    -- Check the rolled number against the loot pool
    local eligibleRewards = {}
    for _, reward in ipairs(Config.Dirt.DirtRewards) do
        if roll <= reward.chance then
            -- Add the reward to the eligible rewards table
            table.insert(eligibleRewards, reward)
        end
    end

    lib.locale()

    if #eligibleRewards == 0 then
        Notify(player, locale('nothingFoundDirt'), "error", 8000)
        return
    end



    -- If multiple rewards are eligible, randomly select one
    if #eligibleRewards > 0 then
        local selectedReward = eligibleRewards[math.random(1, #eligibleRewards)]
        local amount = math.random(selectedReward.min, selectedReward.max)

        AddItem(player, selectedReward.item, amount)
    else
        -- If no reward was found
        print('No rewards were eligible for player: ' .. player)
    end

    RemoveItem(player, Config.Dirt.DirtItem, 1)
end

RegisterNetEvent('ss_goldpanning:server:completeGold', function(gold)
    if not source then return end

    if not playersPanning[source] then return end

    if gold then
        local amount = math.random(Config.Gold.GoldReward.Min, Config.Gold.GoldReward.Max)
        local inZone = lib.callback.await('ss_goldpanning:client:checkZone', source)

        if inZone then
            local multChance = math.random(0, 100)
            if multChance <= Config.Gold.GoldRushZoneChance * 100 then
                local multiplier = Config.Gold.GoldRushZoneMultiplier
                amount = math.floor(amount * multiplier)
            end
        end
        AddItem(source, Config.Gold.GoldNuggetItem, amount)
    end

    if not Config.Dirt.AllowDirtItem then return end

    local dirtChance = math.random(0, 100)
    if dirtChance <= Config.Dirt.DirtChance * 100 then
        AddItem(source, 'dirt', 1)
    else
        noDirtFound = true
    end

    lib.locale()

    if gold then
        Notify(source, locale('foundGold'), "success", 8000)
    elseif noDirtFound then
        Notify(source, locale('nothingFound'), "error", 8000)
    else
        Notify(source, locale('foundDirt'), "success", 8000)
    end
end)

RegisterNetEvent('ss_goldpanning:server:stopGoldPan', function()
    if not source then return end
    playersPanning[source] = false
end)

local smeltingLocation = false

RegisterNetEvent('ss_goldpanning:server:smeltGold', function()
    if not source then return end

    local itemCount = GetItemCount(source, Config.Gold.GoldNuggetItem)


    if not itemCount then return end

    local playerCoords = GetEntityCoords(GetPlayerPed(source))

    for _, location in ipairs(Config.GoldSmelting.Locations) do
        local distance = #(playerCoords - location.coords)

        if distance <= 50 then
            smeltingLocation = true
            break
        end
    end

    lib.locale()

    if itemCount >= Config.GoldSmelting.NuggetsRequired and smeltingLocation then
        Notify(source, locale('smeltingGold'), "success", 8000)
        RemoveItem(source, Config.Gold.GoldNuggetItem, Config.GoldSmelting.NuggetsRequired)
        AddItem(source, Config.GoldSmelting.GoldBarItem, 1)
    else
        Notify(source, locale('notEnoughNuggets'), "error", 8000)
    end

    smeltingLocation = false
end)

lib.callback.register('ss_goldpanning:server:getGoldAmount', function(source)
    local itemCount = GetItemCount(source, Config.Gold.GoldNuggetItem)


    if not itemCount or itemCount <= 0 then
        Notify(source, locale('NoGoldDesc'), "error", 8000)
        return false
    end

    local maxAmount = math.floor(itemCount / Config.GoldSmelting.NuggetsRequired)

    if maxAmount <= 0 then
        Notify(source, locale('NoGoldDesc'), "error", 8000)
        return false
    end

    return itemCount, maxAmount
end)