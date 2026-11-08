-- Einreise (Client, 6.4): ohne Einreise bleibt der Charakter am Flughafen (sanfte Rückführung), Hinweis im HUD; Team-Menü → Einreise.
TacoV = TacoV or {}
TacoV.Immigration = { done = true }

local O = TacoV.Config.Onboarding

RegisterNetEvent('tacov:immigration:state', function(done)
  TacoV.Immigration.done = done
  TacoV.UI.send('hud', { notice = done and false or 'Einreise ausstehend · bitte in der Ankunftshalle warten' })
end)

AddEventHandler('tacov:client:characterLoaded', function(c)
  TacoV.Immigration.done = c.immigrated ~= false
  if not TacoV.Immigration.done then TacoV.UI.send('hud', { notice = 'Einreise ausstehend · bitte in der Ankunftshalle warten' }) end
end)

CreateThread(function()
  while true do
    Wait(2000)
    if TacoV.Client.character and not TacoV.Immigration.done then
      local ped = PlayerPedId()
      local pos = GetEntityCoords(ped)
      local s = O.spawn
      if #(pos - vector3(s.x, s.y, s.z)) > O.airportRadius then
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 then TaskLeaveVehicle(ped, veh, 16) Wait(1200) end
        TacoV.Creator.fadeTeleport(s.x, s.y, s.z, s.w)
        TacoV.UI.send('notify', { kind = 'warn', text = 'Ohne Einreise kannst du den Flughafen nicht verlassen.' })
      end
    end
  end
end)

-- Team-Menü → Einreise
RegisterNetEvent('tacov:immigration:list', function(list)
  local items = {}
  for i, e in ipairs(list) do
    local mins = e.waitMinutes or 0
    items[#items + 1] = { id = tostring(e.id), label = ('#%d  %s'):format(e.id, e.name), icon = 'user', sub = ('Herkunft: %s · wartet seit %d min'):format(e.origin or '–', mins),
      section = i == 1 and 'Warteschlange' or nil }
  end
  if #items == 0 then items[1] = { id = 'none', label = 'Niemand wartet auf die Einreise', icon = 'info', dim = true } end
  TacoV.Menu.open({ id = 'immigration', title = 'Einreise', icon = 'id', info = ('%d wartend'):format(#list),
    note = 'Gespräch: Person, Grund der Einreise, zwei kurze Situationen. Nicht bestanden = Rückflug, neuer Versuch nach 24 h.', items = items }, function(id)
    if id == 'none' then return end
    local target = tonumber(id)
    local name
    for _, e in ipairs(list) do if e.id == target then name = e.name end end
    TacoV.Menu.open({ id = 'immigration_one', title = name or ('#' .. id), icon = 'id', info = 'Einreise', items = {
      { id = 'goto', label = 'Zum Schalter / zu Spieler teleportieren', icon = 'next' },
      { id = 'bring', label = 'Spieler zu mir holen', icon = 'back' },
      { id = 'pass', label = 'Einreise bestanden', icon = 'check', section = 'Entscheidung' },
      { id = 'fail', label = 'Nicht bestanden (Rückflug)', icon = 'x' },
    } }, function(a)
      if a == 'goto' or a == 'bring' then
        TacoV.Menu.close()
        TriggerServerEvent('tacov:admin:teleport', a == 'goto' and 'player' or 'bring', target)
      elseif a == 'pass' then
        TacoV.Menu.close()
        TriggerServerEvent('tacov:immigration:decide', target, true)
      elseif a == 'fail' then
        TacoV.UI.ask({ title = 'Grund der Ablehnung', placeholder = 'z. B. kein Roleplay-Verständnis', maxLength = 120, icon = 'x' }, function(v)
          if v and #v >= 3 then TacoV.Menu.close() TriggerServerEvent('tacov:immigration:decide', target, false, v) end
        end)
      end
    end)
  end)
end)
