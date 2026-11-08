-- Entwickler-Werkzeuge (5.14), Client: Koordinaten-Overlay und Kopieren, Entity-Info am Zeiger, Debug-Anzeige für Zonen/Orte,
-- Neuladen. Freigabe kommt vom Server (dev.tools).
TacoV = TacoV or {}
TacoV.Dev = { coords = false, entity = false, locations = false }

local function notify(kind, text) TacoV.UI.send('notify', { kind = kind, text = text }) end

RegisterNetEvent('tacov:dev:set', function(what, on)
  if what == 'zones' then TacoV.Zones.debug = on else TacoV.Dev[what] = on end
  if not TacoV.Dev.coords and not TacoV.Dev.entity then TacoV.UI.send('dev', nil) end
  notify('info', ('%s %s.'):format(({ coords = 'Koordinaten', entity = 'Entity-Info', zones = 'Zonen-Anzeige', locations = 'Orte-Anzeige' })[what] or what, on and 'an' or 'aus'))
end)

local function aim()
  local rot = GetGameplayCamRot(2)
  local yaw, pitch = math.rad(rot.z), math.rad(rot.x)
  local dir = vector3(-math.sin(yaw) * math.cos(pitch), math.cos(yaw) * math.cos(pitch), math.sin(pitch))
  local from = GetGameplayCamCoord()
  local to = from + dir * 50.0
  local handle = StartShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, 1 | 2 | 4 | 8 | 16, PlayerPedId(), 4)
  local _, hit, coords, _, ent = GetShapeTestResult(handle)
  return hit == 1, coords, ent
end

local lastEnt = 0
CreateThread(function()
  while true do
    if TacoV.Dev.coords or TacoV.Dev.entity then
      Wait(100)
      local lines = {}
      local ped = PlayerPedId()
      if TacoV.Dev.coords then
        local p = GetEntityCoords(ped)
        local h = GetEntityHeading(ped)
        lines[#lines + 1] = ('Pos  %.2f, %.2f, %.2f  H %.1f'):format(p.x, p.y, p.z, h)
        local v = GetVehiclePedIsIn(ped, false)
        if v ~= 0 then lines[#lines + 1] = ('Fzg  %s  %.0f km/h'):format(TacoV.Vehicles.plateOf(v), GetEntitySpeed(v) * 3.6) end
        local sn = GetNameOfZone(p.x, p.y, p.z)
        lines[#lines + 1] = ('Zone %s · Straße %s'):format(sn, GetStreetNameFromHashKey(GetStreetNameAtCoord(p.x, p.y, p.z)))
      end
      if TacoV.Dev.entity then
        local hit, c, ent = aim()
        if hit and ent ~= 0 and DoesEntityExist(ent) then
          lastEnt = ent
          local t = GetEntityType(ent)
          local model = GetEntityModel(ent)
          local ep = GetEntityCoords(ent)
          lines[#lines + 1] = ('Entity %d  Typ %s  Modell %s'):format(ent, ({ 'Ped', 'Fahrzeug', 'Objekt' })[t] or t, model)
          lines[#lines + 1] = ('  @ %.2f, %.2f, %.2f  H %.1f  Netz %s'):format(ep.x, ep.y, ep.z, GetEntityHeading(ent),
            NetworkGetEntityIsNetworked(ent) and tostring(NetworkGetNetworkIdFromEntity(ent)) or 'lokal')
          if t == 2 then lines[#lines + 1] = ('  Kennz. %s  Motor %.0f  Karosserie %.0f'):format(TacoV.Vehicles.plateOf(ent), GetVehicleEngineHealth(ent), GetVehicleBodyHealth(ent)) end
          if t == 1 then lines[#lines + 1] = ('  Leben %d/%d  Rüstung %d'):format(GetEntityHealth(ent), GetEntityMaxHealth(ent), GetPedArmour(ent)) end
          DrawMarker(28, ep.x, ep.y, ep.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.25, 0.25, 167, 139, 250, 150, false, true, 2, nil, nil, false)
        elseif hit then
          lines[#lines + 1] = ('Treffer %.2f, %.2f, %.2f (Welt)'):format(c.x, c.y, c.z)
        end
      end
      TacoV.UI.send('dev', table.concat(lines, '\n'))
    else
      Wait(500)
    end
  end
end)

-- Orte-Anzeige: Marker und Name für Orte in 60 m
CreateThread(function()
  while true do
    if TacoV.Dev.locations then
      Wait(0)
      local p = GetEntityCoords(PlayerPedId())
      for _, l in ipairs(TacoV.Client.locations) do
        if #(p - vector3(l.x, l.y, l.z)) < 60.0 then
          DrawMarker(1, l.x, l.y, l.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.8, 0.8, 1.2, 167, 139, 250, 90, false, false, 2, false, nil, nil, false)
          SetDrawOrigin(l.x, l.y, l.z + 0.6, 0)
          SetTextFont(4) SetTextScale(0.3, 0.3) SetTextCentre(true) SetTextOutline()
          BeginTextCommandDisplayText('STRING') AddTextComponentSubstringPlayerName(('%s [%s]'):format(l.label or l.name, l.name)) EndTextCommandDisplayText(0.0, 0.0)
          ClearDrawOrigin()
        end
      end
    else
      Wait(500)
    end
  end
end)

function TacoV.Dev.copyCoords(withHeading)
  local ped = PlayerPedId()
  local p = GetEntityCoords(ped)
  local text = withHeading and ('x = %.2f, y = %.2f, z = %.2f, heading = %.1f'):format(p.x, p.y, p.z, GetEntityHeading(ped))
    or ('vector3(%.2f, %.2f, %.2f)'):format(p.x, p.y, p.z)
  TacoV.UI.send('copy', text)
  print('[tacov] ' .. text)
  notify('success', 'Kopiert: ' .. text)
end

function TacoV.Dev.openMenu()
  TacoV.Menu.open({ id = 'dev', title = 'Entwickler', icon = 'tool', info = 'dev.tools', items = {
    { id = 'coords', label = 'Koordinaten-Overlay', icon = 'pin', badge = TacoV.Dev.coords and 'An' or 'Aus', section = 'Anzeige' },
    { id = 'entity', label = 'Entity-Info am Zeiger', icon = 'search', badge = TacoV.Dev.entity and 'An' or 'Aus' },
    { id = 'zones', label = 'Zonen anzeigen', icon = 'pin', badge = TacoV.Zones.debug and 'An' or 'Aus' },
    { id = 'locations', label = 'Orte anzeigen', icon = 'pin', badge = TacoV.Dev.locations and 'An' or 'Aus' },
    { id = 'copy', label = 'Position kopieren (vector3)', icon = 'doc', section = 'Kopieren' },
    { id = 'copyh', label = 'Position mit Blickrichtung kopieren', icon = 'doc' },
    { id = 'entinfo', label = 'Entity-Besitzer abfragen (Zeiger)', icon = 'id' },
    { id = 'reloadData', label = 'Daten und Config-Überschreibungen neu laden', icon = 'back', section = 'Neu laden' },
    { id = 'restart', label = 'Kern-Resource neu starten', icon = 'warn', sub = 'speichert alle, trennt kurz die Oberflächen' },
  } }, function(id)
    if id == 'coords' or id == 'entity' or id == 'zones' or id == 'locations' then
      local cur = id == 'zones' and TacoV.Zones.debug or TacoV.Dev[id]
      TriggerServerEvent('tacov:dev:toggle', id, not cur)
      TacoV.Menu.close()
    elseif id == 'copy' then TacoV.Dev.copyCoords(false)
    elseif id == 'copyh' then TacoV.Dev.copyCoords(true)
    elseif id == 'entinfo' then
      TacoV.Menu.close()
      local hit, _, ent = aim()
      if hit and ent ~= 0 and NetworkGetEntityIsNetworked(ent) then TriggerServerEvent('tacov:dev:entity', NetworkGetNetworkIdFromEntity(ent))
      else notify('info', lastEnt ~= 0 and 'Entity ist lokal (kein Netzwerk).' or 'Kein Entity anvisiert.') end
    elseif id == 'reloadData' then TacoV.Menu.close() TriggerServerEvent('tacov:dev:reload', 'overrides')
    elseif id == 'restart' then
      TacoV.Menu.open({ id = 'dev_restart', title = 'Kern wirklich neu starten?', icon = 'warn', items = {
        { id = 'yes', label = 'Ja, neu starten', icon = 'x' }, { id = 'no', label = 'Abbrechen', icon = 'back' } } }, function(a)
        TacoV.Menu.close()
        if a == 'yes' then TriggerServerEvent('tacov:dev:reload', 'resource') end
      end)
    end
  end)
end

RegisterCommand('coords', function() if TacoV.Client.character then TacoV.Dev.copyCoords(true) end end, false)
