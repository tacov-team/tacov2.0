-- Fitness (Server, 6.9): Trainingseinheit gutschreiben, täglicher Abbau ohne Training.
TacoV = TacoV or {}

local N = TacoV.Config.Needs
local F = TacoV.Config.Fitness
local lastTrain = {} -- [src][station] = os.time

RegisterNetEvent('tacov:fitness:trained', function(station)
  local src = source
  local c = TacoV.Characters.get(src)
  if not c then return end
  local loc = TacoV.Locations.nearest(src, 'gym', 4.0)
  if not loc or loc.name ~= station then return end
  lastTrain[src] = lastTrain[src] or {}
  if lastTrain[src][station] and os.time() - lastTrain[src][station] < F.cooldownSeconds - 5 then return end
  lastTrain[src][station] = os.time()
  c.needs.lastTraining = os.time()
  TacoV.Needs.add(src, 'fitness', N.fitness.gainEquipment)
  TriggerClientEvent('tacov:core:notify', src, 'success', ('Training: Fitness %d %%.'):format(math.floor(c.needs.fitness or 0)))
end)

-- Energydrink zählt als Training für den Abbau nicht; Abbau 1 % je Tag ohne Training
AddEventHandler('tacov:core:ready', function()
  CreateThread(function()
    while true do
      Wait(600000)
      for src in pairs(TacoV.Players.all()) do
        local c = TacoV.Characters.get(src)
        if c and (c.needs.fitness or 0) > 0 then
          local last = c.needs.lastTraining or 0
          local lastDecay = c.needs.lastFitnessDecay or last
          if os.time() - last > 86400 and os.time() - lastDecay > 86400 then
            c.needs.lastFitnessDecay = os.time()
            TacoV.Needs.add(src, 'fitness', -N.fitness.decayPerDay)
          end
        end
      end
    end
  end)
end)
AddEventHandler('playerDropped', function() lastTrain[source] = nil end)
