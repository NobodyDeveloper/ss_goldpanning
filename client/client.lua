local goldPanning = false
local goldPanProp = nil
local inPanningAnim = false
local panFull = false
local inGoldRushZone = false
local inMinigame = false
local inSmeltingZone = false
local cooldown = false

if Config.Framework == 'qb-core' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
end

function ShowContextMenu()
    lib.locale()
    local ped = cache.ped

    lib.registerContext({
        id = 'gold_smelting',
        title = locale('smeltingGold_Title'),
        canClose = true,
        options = {
            {
                title = locale('smeltingGold_Button'),
                icon = 'fa-solid fa-gold-pan',
                onSelect = function()
                    StartSmeltProcess()
                end
            }
        }

    })

    lib.showContext('gold_smelting')
end

function stopGame()
    if goldPanProp ~= nil and DoesEntityExist(goldPanProp) then
        DetachEntity(goldPanProp, true, true)
        DeleteObject(goldPanProp)
        DeleteEntity(goldPanProp)
        goldPanProp = nil
    end
    panFull = false
    inPanningAnim = false
    inMinigame = false
    goldPanning = false
    ClearPedTasks(cache.ped)
    lib.hideTextUI()
end

if Config.GoldSmelting.AllowSmelting then
    CreateThread(function()
        while inSmeltingZone do
            Wait(0)
            if IsControlJustPressed(0, 38) then
                ShowContextMenu()
            end
        end
    end)
end

function StartSmeltProcess()
    local playerGold, maxAmount = lib.callback.await('ss_goldpanning:server:getGoldAmount', source)

    if not playerGold then return end

    local input = lib.inputDialog('Smelting Gold', {
        { type = 'slider', label = 'Select Amount', min = 1, max = maxAmount, step = 1, required = true },
    })

    if not input then
        return
    end

    local amount = input[1] -- Directly use input[1] as the slider value

    local duration = Config.GoldSmelting.SmeltingTime * 1000

    local timesElapsed = 0

    while timesElapsed < amount do
        local success = lib.progressCircle({
            duration = duration,
            position = 'bottom',
            label = locale('smeltingGold_Progress'),
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = true,
                combat = true,
            },
            anim = {
                dict = 'anim@amb@business@coc@coc_unpack_cut_left@',
                clip = 'coke_cut_coccutter',
                flag = 1,
            },
        })

        if success then
            TriggerServerEvent('ss_goldpanning:server:smeltGold')
            timesElapsed = timesElapsed + 1
        else
            break
        end
    end
end

function StartSiftingAnim()
    local ped = cache.ped

    lib.RequestAnimDict("anim_casino_b@amb@casino@games@threecardpoker@dealer")

    CreateThread(function()
        while inMinigame do
            if not IsEntityPlayingAnim(ped, "anim_casino_b@amb@casino@games@threecardpoker@dealer", "deck_shuffle", 3) then
                TaskPlayAnim(ped, "anim_casino_b@amb@casino@games@threecardpoker@dealer", "deck_shuffle", 8.0, -8.0, -1,
                    49, 0, false, false,
                    false, false)
            end
            Wait(5000)
        end
    end)
end

function filledPan()
    lib.showTextUI('Press E to Sift Pan. \n Press X to cancel', {
        position = 'right-center',
        icon = 'fa-solid fa-gold-pan',
    })

    CreateThread(function()
        while panFull do
            if IsControlJustPressed(0, 38) then -- 38 is the key code for 'E'
                lib.hideTextUI()

                SetNuiFocus(true, true) -- Enable NUI focus
                -- Send the gold chance to the frontend
                SendNUIMessage({
                    action = "startSiftingMinigame",
                    goldChance = Config.Gold.GoldChance
                })
                inMinigame = true
                StartSiftingAnim()
                break
            elseif IsControlJustPressed(0, 73) then
                lib.hideTextUI()
                stopGame()
            end
            Wait(0)
        end
    end)
end

RegisterNUICallback('minigameResult', function(data, cb)
    SetNuiFocus(false, false)
    inMinigame = false
    if data.success then
        panFull = false
        ClearPedTasks(cache.ped)
        TriggerServerEvent('ss_goldpanning:server:completeGold', data.showedGold)
        cooldown = true
        Wait(4000)
        cooldown = false
        goldPanning = true
        startGoldPanAnim()
    else
        panFull = false
        goldPanning = false
        if goldPanProp ~= nil and DoesEntityExist(goldPanProp) then
            DetachEntity(goldPanProp, true, true)
            DeleteObject(goldPanProp)
            DeleteEntity(goldPanProp)
            goldPanProp = nil
        end
        ClearPedTasks(cache.ped)
    end
    cb('ok')
end)

function startGoldPanning()
    inPanningAnim = true
    lib.hideTextUI()

    lib.locale()

    local success = lib.progressCircle({
        duration = Config.PanFillDuration * 1000,
        position = 'bottom',
        label = locale('fillingPan'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'amb@world_human_bum_wash@male@low@idle_a',
            clip = 'idle_a',
            flag = 1,
        },
    })

    if success then
        inPanningAnim = false
        panFull = true

        filledPan()
    else
        inPanningAnim = false
        panFull = false
    end
end

function isPlayerInWater()
    local ped = cache.ped
    local pedCoords = GetEntityCoords(ped)

    if IsPedSwimming(ped) then
        local isOpen = lib.isTextUIOpen()
        if isOpen then
            lib.hideTextUI()
        end

        return false
    end

    local hit, coords = TestProbeAgainstAllWater(pedCoords.x, pedCoords.y, pedCoords.z, pedCoords.x, pedCoords.y,
        pedCoords.z - 1.0, 128)

    return hit
end

function startGoldPanAnim()
    if goldPanning and not cooldown then
        local ped = cache.ped
        local pedCoords = GetEntityCoords(ped)

        lib.RequestAnimDict("anim@heists@box_carry@")

        if not IsEntityPlayingAnim(ped, "anim@heists@box_carry@", "idle", 3) and not inPanningAnim and not inMinigame then
            TaskPlayAnim(ped, "anim@heists@box_carry@", "idle", 8.0, -8.0, -1, 49, 0, false, false, false, false)
        end

        if goldPanProp == nil or not DoesEntityExist(goldPanProp) then
            RequestModel("salt_metalbowl_full")
            while not HasModelLoaded("salt_metalbowl_full") do
                Wait(100)
            end

            if goldPanProp == nil or not DoesEntityExist(goldPanProp) then
                goldPanProp = CreateObject("salt_metalbowl_full", pedCoords.x, pedCoords.y, pedCoords.z, true,
                    true, false)
            end


            AttachEntityToEntity(goldPanProp, ped, GetPedBoneIndex(ped, 18905), 0.23, 0.0, 0.21, -72.89, 0.0, 30.02, true,
                true, false, true, 1, true)
        end

        lib.showTextUI('Press E to pan for gold. \n Press X to stop', {
            position = 'right-center',
            icon = 'fa-solid fa-gold-pan',
        })
    end

    CreateThread(function()
        while goldPanning do
            if IsControlJustPressed(0, 38) then
                -- Check if the player is in water
                if isPlayerInWater() then
                    startGoldPanning()
                    break
                else
                    lib.notify({
                        title = 'Gold Panning',
                        description = 'You need to be in water to pan for gold.',
                        type = 'error',
                    })
                end
            elseif IsControlJustPressed(0, 73) then
                lib.hideTextUI()
                stopGame()
                break
            end
            Wait(0)
        end
    end)
end

RegisterNetEvent('ss_goldpanning:client:useGoldPan', function()
    local ped = cache.ped

    if goldPanning then
        goldPanning = false
        TriggerServerEvent('ss_goldpanning:server:stopGoldPan')
        if goldPanProp ~= nil and DoesEntityExist(goldPanProp) then
            DetachEntity(goldPanProp, true, true)
            DeleteObject(goldPanProp)
            DeleteEntity(goldPanProp)
            goldPanProp = nil
        end

        ClearPedTasks(ped)
        lib.hideTextUI()
        return
    end

    goldPanning = true

    startGoldPanAnim()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        stopGame()
        ClearPedTasks(cache.ped)
        lib.hideTextUI()
    end
end)

for i = 1, #Config.GoldRushZones do
    local zone = Config.GoldRushZones[i]
    local createdZone = lib.zones.poly({
        name = zone.name,
        points = zone.coords,
        thickness = 10.0,
        debug = Config.Debug,
        onEnter = function()
            inGoldRushZone = true
        end,
        onExit = function()
            inGoldRushZone = false
        end,

    })

    if zone.showBlip then
        -- Calculate the centroid of the zone
        local totalX, totalY, totalZ = 0, 0, 0
        local numPoints = #zone.coords

        for _, coord in ipairs(zone.coords) do
            totalX = totalX + coord.x
            totalY = totalY + coord.y
            totalZ = totalZ + (coord.z or 0) -- Handle cases where z might be nil
        end

        local centerX = totalX / numPoints
        local centerY = totalY / numPoints
        local centerZ = totalZ / numPoints

        -- Create a blip at the centroid
        local blip = AddBlipForCoord(centerX, centerY, centerZ)
        SetBlipSprite(blip, 618) -- Example sprite, change as needed
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 46) -- Example color, change as needed
        SetBlipAsShortRange(blip, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(zone.name)
        EndTextCommandSetBlipName(blip)
    end
end

if Config.GoldSmelting.showBlip and Config.GoldSmelting.AllowSmelting then
    for _, location in ipairs(Config.GoldSmelting.Locations) do
        local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
        SetBlipSprite(blip, 436) -- Example sprite, change as needed
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 47) -- Example color, change as needed
        SetBlipAsShortRange(blip, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString('Gold Smelting')
        EndTextCommandSetBlipName(blip)
    end
end

if Config.GoldSmelting.AllowSmelting then
    for k, v in pairs(Config.GoldSmelting.Locations) do
        if Config.Target == 'none' then
            local createdZone = lib.zones.sphere({
                name = 'gold_smelting',
                coords = v.coords,
                radius = v.size,
                debug = Config.Debug,
                onEnter = function()
                    if Config.GoldSmelting.AllowSmelting then
                        lib.showTextUI('Press E to Smelt Gold', {
                            position = 'right-center',
                            icon = 'fa-solid fa-gold-pan',
                        })
                    end
                    inSmeltingZone = true
                end,
                onExit = function()
                    lib.hideTextUI()
                    inSmeltingZone = false
                end,
            })
        elseif Config.Target == 'ox_target' then
            local createdZone = exports.ox_target:addSphereZone({
                name = 'gold_smelting',
                coords = v.coords,
                radius = v.size,
                debug = Config.Debug,
                options = {
                    {
                        name = 'gold_smelting',
                        icon = 'fa-solid fa-gold-pan',
                        label = 'Smelt Gold',
                        onSelect = function()
                            ShowContextMenu()
                        end,
                    },
                }
            })
        elseif Config.Target == 'qb-target' then
    exports['qb-target']:AddCircleZone("gold_smelting", v.coords, v.size, {
        name = "gold_smelting",
        debugPoly = Config.Debug,
        useZ = true
    }, {
        options = {
            {
                num = 1,
                type = "client",
                event = "ss_goldpanning:client:smeltGold",
                icon = "fa-solid fa-gold-pan",
                label = "Smelt Gold",
                action = function(entity)
                    ShowContextMenu()
                end,
            }
        },
        distance = 2.5
    })
end
    end
end

lib.callback.register('ss_goldpanning:client:checkZone', function()
    return inGoldRushZone
end)

lib.callback.register('ss_goldpanning:client:cleanDirt', function()
    lib.locale()

    local inWater = isPlayerInWater()

    if not inWater then
        NotifyPlayer(locale('requireWater'), 'error', 8000)
        return false
    end

    if goldPanning or inPanningAnim or inMinigame then
        NotifyPlayer(locale('busy'), 'error', 8000)
        return false
    end
    local success = lib.progressCircle({
        duration = Config.Dirt.CleaningTime * 1000,
        position = 'bottom',
        label = locale('cleaningDirt'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'amb@world_human_bum_wash@male@high@idle_a',
            clip = 'idle_a',
            flag = 1,
        },
        prop = {
            model = 'prop_rock_5_smash1',
            bone = 57005,
            pos = { x = 0.15, y = 0.1, z = -0.02 },
            rot = { x = 0.0, y = 0.0, z = 0.0 },
        },
    })

    if success then
        return true
    else
        return false
    end
end)
