-- Laden-Client: E-Aufforderung am Ladenort, Ansicht öffnen, Kauf an den Server.
TacoV = TacoV or {}
TacoV.Shops = {}

function TacoV.Shops.open()
  if TacoV.UI.current() then return end
  TriggerServerEvent('tacov:shop:open')
end

function TacoV.Shops.close()
  if TacoV.UI.current() == 'shop' then
    TacoV.UI.close()
    TriggerServerEvent('tacov:shop:close')
  end
end

RegisterNetEvent('tacov:shop:data', function(data)
  if TacoV.UI.current() == 'shop' then
    TacoV.UI.send('open', { view = 'shop', data = data })
  else
    TacoV.UI.open('shop', data)
  end
end)

AddEventHandler('tacov:ui:shop:buy', function(data)
  TriggerServerEvent('tacov:shop:buy', data)
end)

AddEventHandler('tacov:ui:shop:close', function()
  TacoV.Shops.close()
end)

TacoV.Prompt.register({
  id = 'shop', label = 'Laden', order = 10,
  when = function()
    local loc = TacoV.Client.nearestLocation('shop', 3.0)
    return loc ~= nil
  end,
  run = function() TacoV.Shops.open() end,
})
