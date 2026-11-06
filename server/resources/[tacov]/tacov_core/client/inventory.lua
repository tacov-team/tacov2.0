-- Inventar-Client: F2 öffnet, Aktionen gehen an den Server, Ablagen am Boden werden für das Interaktionsrad gemerkt.
TacoV = TacoV or {}
TacoV.Inventory = { drops = {}, money = { cash = 0, black = 0, weight = 0, maxWeight = 30 } }

function TacoV.Inventory.open()
  if TacoV.UI.current() then return end
  TriggerServerEvent('tacov:inventory:open')
end

function TacoV.Inventory.close()
  if TacoV.UI.current() == 'inventory' then
    TacoV.UI.close()
    TriggerServerEvent('tacov:inventory:close')
  end
end

--- Nächste Ablage am Boden innerhalb maxDist, oder nil.
function TacoV.Inventory.nearestDrop(maxDist)
  local pos = GetEntityCoords(PlayerPedId())
  local best, bestD = nil, maxDist or 2.5
  for _, d in ipairs(TacoV.Inventory.drops) do
    local dist = #(pos - vector3(d.x, d.y, d.z))
    if dist < bestD then best, bestD = d, dist end
  end
  return best
end

RegisterNetEvent('tacov:inventory:data', function(data)
  -- Ziel für „Geben“: nächster Spieler (Server prüft erneut)
  local nearest, nearestId = nil, nil
  local me, mePos = PlayerPedId(), GetEntityCoords(PlayerPedId())
  for _, pid in ipairs(GetActivePlayers()) do
    local ped = GetPlayerPed(pid)
    if ped ~= me then
      local d = #(mePos - GetEntityCoords(ped))
      if d < 3.0 and (not nearest or d < nearest) then nearest, nearestId = d, GetPlayerServerId(pid) end
    end
  end
  data.target = nearestId
  if TacoV.UI.current() == 'inventory' then
    TacoV.UI.send('open', { view = 'inventory', data = data })
  else
    TacoV.UI.open('inventory', data)
  end
end)

RegisterNetEvent('tacov:inventory:money', function(m)
  TacoV.Inventory.money = m
  TacoV.UI.send('hud', { cash = m.cash, black = m.black, weight = m.weight, maxWeight = m.maxWeight })
end)

RegisterNetEvent('tacov:inventory:drops', function(list)
  TacoV.Inventory.drops = list or {}
end)

-- Kurze Animation beim Essen/Trinken
RegisterNetEvent('tacov:inventory:used', function(item)
  local def = TacoV.Config.Items[item]
  if not def or type(def.use) ~= 'table' then return end
  local ped = PlayerPedId()
  local dict, anim = 'mp_player_inteat@burger', 'mp_player_int_eat_burger'
  if def.category == 'drink' then dict, anim = 'mp_player_intdrink', 'loop_bottle' end
  RequestAnimDict(dict)
  local t = GetGameTimer()
  while not HasAnimDictLoaded(dict) and GetGameTimer() - t < 1000 do Wait(10) end
  TaskPlayAnim(ped, dict, anim, 8.0, -8.0, 2500, 49, 0, false, false, false)
  TacoV.UI.send('notify', { kind = 'success', text = def.label .. ' benutzt.' })
end)

-- NUI-Aktionen der Inventar-Ansicht (von core/client/ui.lua weitergereicht)
AddEventHandler('tacov:ui:inventory:action', function(data)
  TriggerServerEvent('tacov:inventory:action', data)
end)

AddEventHandler('tacov:ui:inventory:close', function()
  TacoV.Inventory.close()
end)

TacoV.Prompt.register({
  id = 'pickup', label = 'Ablage durchsuchen', order = 20,
  when = function() return TacoV.Inventory.nearestDrop(2.0) ~= nil end,
  run = function() TacoV.Inventory.open() end,
})
