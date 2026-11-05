-- Startreihenfolge des Kerns: DB -> Migrationen -> Autosave. Andere Resources warten auf das Export `isReady`.
TacoV = TacoV or {}

local ready = false

function TacoV.isReady()
  return ready
end

CreateThread(function()
  TacoV.DB.waitReady()
  if not TacoV.Migrations.run() then
    print('^1[tacov_core]^7 Migrationen fehlgeschlagen; Kern bleibt gesperrt.')
    return
  end
  ready = true
  print(('^2[tacov_core]^7 bereit · %s · %d Slots'):format(TacoV.Config.Server.name, TacoV.Config.Server.slots))
  TriggerEvent('tacov:core:ready')
end)

-- Autosave (Konzept 1: alle 5 Minuten)
CreateThread(function()
  while true do
    Wait(TacoV.Config.Server.autosaveSeconds * 1000)
    if ready then
      local n = 0
      for src in pairs(TacoV.Players.all()) do
        if TacoV.Characters.get(src) then
          TacoV.Characters.save(src)
          n = n + 1
        end
      end
      if n > 0 then print(('^2[tacov_core]^7 Autosave: %d Charaktere'):format(n)) end
    end
  end
end)

-- Alles speichern, wenn die Resource stoppt
AddEventHandler('onResourceStop', function(res)
  if res ~= GetCurrentResourceName() then return end
  for src in pairs(TacoV.Players.all()) do
    TacoV.Characters.save(src)
  end
end)

exports('isReady', TacoV.isReady)
