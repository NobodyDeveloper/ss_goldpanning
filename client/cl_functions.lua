function NotifyPlayer(message, type, duration)
    lib.locale()
    if Config.Notify == 'ox_lib' then
        TriggerEvent('ox_lib:notify', {
            title = 'Gold Panning',
            description = message,
            type = type,
            duration = duration
        })
    elseif Config.Notify == 'qb-core' then
        QBCore.Functions.Notify(message, type, duration)
    elseif Config.Notify == 'esx' then
        ESX.ShowNotification(message)
    elseif Config.Notify == 'okok' then
        exports['okokNotify']:Alert(locale('title'), message, duration, type)
    elseif Config.Notify == 'sd-notify' then
         exports['sd-notify']:Notify(locale('title'), message, type, duration)
    elseif Config.Notify == 'wasabi' then
        exports.wasabi_notify:notify(locale('title'), message, duration, type)
    elseif Config.Notify == 'custom' then
        -- Add your custom standalone notification logic here
    else
        print("Warning: Notification system not supported or not configured correctly.")
    end
end