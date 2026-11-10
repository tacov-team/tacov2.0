-- Dispatch (Punkt 9.5, Client): neue Einsätze als Hinweis mit Ton und Blip, Einsatzliste (übernehmen, abschließen, Status),
-- Schussmeldung an die Leitstelle.
TacoV = TacoV or {}
TacoV.Dispatch = {}

local D = TacoV.Config.Dispatch
local function notify(kind, text) TacoV.UI.send('notify', { kind = kind, text = text }) end
local KIND = { ['110'] = 'Notruf 110', ['112'] = 'Notruf 112', shots = 'Schüsse', speed = 'Blitzer' }
local blips = {}

local function street(x, y)
  local s = GetStreetNameAtCoord(x + 0.0, y + 0.0, 30.0)
  return GetStreetNameFromHashKey(s)
end

RegisterNetEvent('tacov:dispatch:new', function(call)
  PlaySoundFrontend(-1, 'Event_Start_Text', 'GTAO_FM_Events_Soundset', true)
  notify('warn', ('%s #%d · %s · %s'):format(KIND[call.kind] or 'Einsatz', call.id, street(call.x, call.y), call.text))
  local b = AddBlipForCoord(call.x + 0.0, call.y + 0.0, 30.0)
  SetBlipSprite(b, call.kind == 'shots' and 110 or 526)
  SetBlipColour(b, 1)
  SetBlipScale(b, 0.9)
  SetBlipFlashes(b, true)
  BeginTextCommandSetBlipName('STRING')
  AddTextComponentString((KIND[call.kind] or 'Einsatz') .. ' #' .. call.id)
  EndTextCommandSetBlipName(b)
  blips[call.id] = b
  SetTimeout(D.keepMinutes * 60000, function() if blips[call.id] then RemoveBlip(blips[call.id]) blips[call.id] = nil end end)
end)

RegisterNetEvent('tacov:dispatch:route', function(x, y)
  SetNewWaypoint(x + 0.0, y + 0.0)
  notify('info', 'Wegpunkt zum Einsatz gesetzt.')
end)

function TacoV.Dispatch.open() TriggerServerEvent('tacov:dispatch:list') end

RegisterNetEvent('tacov:dispatch:list', function(list, units, myStatus)
  local items = {}
  for _, c in ipairs(list) do
    items[#items + 1] = { id = 'c_' .. c.id, label = ('#%d · %s'):format(c.id, KIND[c.kind] or 'Einsatz'), icon = c.kind == 'shots' and 'gun' or 'warn',
      sub = ('%s · %s · vor %d min%s'):format(street(c.x, c.y), c.text, math.floor(c.age / 60), c.callerName and (' · ' .. c.callerName .. (c.number and (' (' .. c.number .. ')') or '')) or ''),
      badge = c.takenName and ('→ ' .. c.takenName) or 'offen', section = 'Einsätze' }
  end
  if #list == 0 then items[#items + 1] = { id = 'none', label = 'Keine offenen Einsätze', dim = true, section = 'Einsätze' } end
  for key, label in pairs(D.statuses) do
    items[#items + 1] = { id = 's_' .. key, label = 'Status: ' .. label, icon = 'radio', badge = myStatus == key and 'aktiv' or nil, section = 'Mein Status' }
  end
  for i, u in ipairs(units) do
    items[#items + 1] = { id = 'u_' .. i, label = u.name, icon = 'user', sub = u.rank, badge = D.statuses[u.status] or u.status, section = 'Einheiten im Dienst', dim = true }
  end
  TacoV.Menu.open({ id = 'dispatch', title = 'Einsätze', icon = 'warn', info = ('%d offen · %d Einheiten'):format(#list, #units), items = items }, function(id)
    if id:sub(1, 2) == 's_' then TriggerServerEvent('tacov:dispatch:status', id:sub(3)) TacoV.Menu.close() return end
    if id:sub(1, 2) ~= 'c_' then return end
    local cid = tonumber(id:sub(3))
    TacoV.Menu.open({ id = 'dispatch_call', title = 'Einsatz #' .. cid, icon = 'warn', items = {
      { id = 'take', label = 'Übernehmen', icon = 'pin', sub = 'Wegpunkt setzen, Anrufer informieren' },
      { id = 'close', label = 'Abschließen', icon = 'check', sub = 'Aus der Liste entfernen' },
    } }, function(a)
      if a == 'take' then TriggerServerEvent('tacov:dispatch:take', cid)
      else
        TriggerServerEvent('tacov:dispatch:close', cid)
        if blips[cid] then RemoveBlip(blips[cid]) blips[cid] = nil end
      end
      TacoV.Menu.close()
    end)
  end)
end)

-- Schüsse melden: nur prüfen, solange eine Schusswaffe in der Hand ist (Taser und Schalldämpfer zählen nicht)
local STUN = GetHashKey('WEAPON_STUNGUN')
local lastShot = 0
CreateThread(function()
  while true do
    local ped = PlayerPedId()
    if TacoV.Client.character and D.shots.enabled and IsPedArmed(ped, 4) then
      if IsPedShooting(ped) and GetGameTimer() - lastShot > D.shots.cooldown * 1000 then
        local weapon = GetSelectedPedWeapon(ped)
        if weapon ~= STUN and not IsPedCurrentWeaponSilenced(ped) then
          lastShot = GetGameTimer()
          TriggerServerEvent('tacov:dispatch:shots')
        end
      end
      Wait(0)
    else
      Wait(500)
    end
  end
end)
