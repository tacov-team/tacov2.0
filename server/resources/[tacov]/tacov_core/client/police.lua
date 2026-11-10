-- LSPD (Punkte 9.4–9.6, Client): Polizei-Menü am Spieler/Fahrzeug (X-Rad), Handschellen, Abführen, ins Fahrzeug setzen,
-- Haft (Zelle, Timer), Ausrüstungskauf, Asservatenkammer, MDT-Oberfläche, Einträge im Fraktionsmenü.
TacoV = TacoV or {}
TacoV.Police = {}

local P = TacoV.Config.Police
local function notify(kind, text) TacoV.UI.send('notify', { kind = kind, text = text }) end
local function onDuty()
  local c = TacoV.Client.character
  return c and c.faction == P.faction and c.duty == true
end

-- ---------------------------------------------------------------- Maßnahmen (X-Rad → Menü)

local function askFine(target)
  TacoV.UI.ask({ title = 'Geldstrafe', label = ('Betrag (max. %d $)'):format(P.fineMax), numeric = true }, function(amount)
    if not tonumber(amount) then return end
    TacoV.UI.ask({ title = 'Geldstrafe', label = 'Grund', maxLength = 120 }, function(reason)
      if reason and reason ~= '' then TriggerServerEvent('tacov:police:fine', target, tonumber(amount), reason) end
    end)
  end)
end
local function askJail(target)
  TacoV.UI.ask({ title = 'Festnahme', label = ('Minuten (max. %d)'):format(P.jailMaxMinutes), numeric = true }, function(minutes)
    if not tonumber(minutes) then return end
    TacoV.UI.ask({ title = 'Festnahme', label = 'Grund', maxLength = 120 }, function(reason)
      if reason and reason ~= '' then TriggerServerEvent('tacov:police:jail', target, tonumber(minutes), reason) end
    end)
  end)
end

local function nearestVehicle()
  local ped = PlayerPedId()
  local pos = GetEntityCoords(ped)
  local best, bestD = 0, 8.0
  for _, veh in ipairs(GetGamePool('CVehicle')) do
    local d = #(pos - GetEntityCoords(veh))
    if d < bestD then best, bestD = veh, d end
  end
  return best
end

local function openPlayerMenu(target)
  local st = Player(target).state
  local cuffed = st.cuffed == true
  local items = {
    { id = 'cuff', label = cuffed and 'Handschellen abnehmen' or 'Handschellen anlegen', icon = 'lock', section = 'Zugriff' },
    { id = 'escort', label = st.escort and 'Abführen beenden' or 'Abführen', icon = 'hands', sub = 'Person folgt dir', dim = not cuffed },
    { id = 'seat', label = 'Ins Fahrzeug setzen', icon = 'car', sub = 'Nächstes Fahrzeug, Rückbank', dim = not cuffed },
    { id = 'unseat', label = 'Aus dem Fahrzeug holen', icon = 'door', dim = not cuffed },
    { id = 'identify', label = 'Ausweis und Führerschein', icon = 'id', sub = 'Verlangen bzw. abnehmen', section = 'Kontrolle' },
    { id = 'breath', label = 'Atemtest', icon = 'drop' },
    { id = 'search', label = 'Durchsuchen', icon = 'search', sub = 'Nur gefesselt oder bewusstlos' },
    { id = 'file', label = 'Akte im MDT', icon = 'doc' },
    { id = 'fine', label = 'Geldstrafe', icon = 'cash', sub = ('bis %d $'):format(P.fineMax), section = 'Maßnahme' },
    { id = 'jail', label = 'Festnehmen', icon = 'lock', sub = ('In der Wache, bis %d min'):format(P.jailMaxMinutes) },
  }
  TacoV.Menu.open({ id = 'police_player', title = 'Polizei', icon = 'shield', info = 'ID ' .. target, items = items }, function(id)
    if id == 'cuff' then TriggerServerEvent('tacov:police:cuff', target)
    elseif id == 'escort' then TriggerServerEvent('tacov:police:escort', target)
    elseif id == 'seat' or id == 'unseat' then
      local veh = nearestVehicle()
      if veh == 0 then notify('error', 'Kein Fahrzeug in der Nähe.') return end
      TriggerServerEvent('tacov:police:seat', target, NetworkGetNetworkIdFromEntity(veh), id == 'unseat')
    elseif id == 'identify' then TriggerServerEvent('tacov:police:identify', target)
    elseif id == 'breath' then TriggerServerEvent('tacov:police:breath', target)
    elseif id == 'search' then TacoV.Menu.close() TriggerServerEvent('tacov:police:search', target) return
    elseif id == 'file' then TacoV.Menu.close() TacoV.Police.openMdt({ target = target }) return
    elseif id == 'fine' then askFine(target) return
    elseif id == 'jail' then askJail(target) return end
    TacoV.Menu.close()
  end)
end

TacoV.Interact.register({ id = 'police_player', label = 'Polizei', icon = 'shield', order = 5,
  when = function(ctx) return ctx.player ~= nil and onDuty() end,
  run = function(ctx) openPlayerMenu(ctx.player) end })

TacoV.Interact.register({ id = 'police_vehicle', label = 'Polizei: Fahrzeug', icon = 'shield', order = 6,
  when = function(ctx) return ctx.vehicle ~= nil and onDuty() end,
  run = function(ctx)
    local veh, plate = ctx.vehicle, (ctx.plate or ''):gsub('^%s+', ''):gsub('%s+$', '')
    TacoV.Menu.open({ id = 'police_vehicle', title = 'Polizei', icon = 'shield', info = plate, items = {
      { id = 'query', label = 'Kennzeichen abfragen', icon = 'search', sub = 'Halter, Zulassung, Fahndung (MDT)' },
      { id = 'seize', label = 'Beschlagnahmen', icon = 'lock', sub = ('Verwahrhof, Auslösung %d $'):format(P.impoundFee) },
    } }, function(id)
      TacoV.Menu.close()
      if id == 'query' then TacoV.Police.openMdt({ plate = plate })
      elseif id == 'seize' then TriggerServerEvent('tacov:police:seize', NetworkGetNetworkIdFromEntity(veh)) end
    end)
  end })

-- ---------------------------------------------------------------- Gefesselt / abgeführt / ins Fahrzeug (Betroffener)

local CUFF_BLOCK = { 21, 22, 23, 24, 25, 37, 44, 45, 47, 58, 73, 75, 140, 141, 142, 143, 257, 263, 264 }
CreateThread(function()
  local wasCuffed, attachedTo = false, nil
  while true do
    local st = LocalPlayer.state
    if st.cuffed then
      local ped = PlayerPedId()
      if not wasCuffed then
        wasCuffed = true
        RequestAnimDict('mp_arresting')
        local t = GetGameTimer()
        while not HasAnimDictLoaded('mp_arresting') and GetGameTimer() - t < 1000 do Wait(10) end
        SetEnableHandcuffs(ped, true)
        SetPedCanPlayGestureAnims(ped, false)
      end
      if not IsEntityPlayingAnim(ped, 'mp_arresting', 'idle', 3) then TaskPlayAnim(ped, 'mp_arresting', 'idle', 8.0, -8.0, -1, 49, 0.0, false, false, false) end
      for _, c in ipairs(CUFF_BLOCK) do DisableControlAction(0, c, true) end
      -- Abführen: an den Beamten hängen
      local by = st.escort
      if by and by ~= attachedTo then
        local officerPed = GetPlayerPed(GetPlayerFromServerId(by))
        if officerPed ~= 0 and officerPed ~= ped and not IsPedInAnyVehicle(ped, false) then
          AttachEntityToEntity(ped, officerPed, 11816, 0.45, 0.45, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
          attachedTo = by
        end
      elseif not by and attachedTo then
        DetachEntity(ped, true, false)
        attachedTo = nil
      end
      Wait(0)
    else
      if wasCuffed then
        wasCuffed = false
        local ped = PlayerPedId()
        if attachedTo then DetachEntity(ped, true, false) attachedTo = nil end
        SetEnableHandcuffs(ped, false)
        SetPedCanPlayGestureAnims(ped, true)
        StopAnimTask(ped, 'mp_arresting', 'idle', 1.0)
      end
      Wait(400)
    end
  end
end)

RegisterNetEvent('tacov:police:seat', function(netId, out)
  local ped = PlayerPedId()
  if out then
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then TaskLeaveVehicle(ped, veh, 16) end
    return
  end
  local veh = NetworkGetEntityFromNetworkId(netId or 0)
  if veh == 0 or not DoesEntityExist(veh) then return end
  DetachEntity(ped, true, false)
  for seat = GetVehicleMaxNumberOfPassengers(veh) - 1, 0, -1 do
    if IsVehicleSeatFree(veh, seat) then TaskWarpPedIntoVehicle(ped, veh, seat) return end
  end
end)

-- ---------------------------------------------------------------- Haft (Betroffener)

local jail = nil   -- { x, y, z, seconds, radius }
local function jailNotice()
  if not jail then TacoV.UI.send('hud', { notice = false }) return end
  TacoV.UI.send('hud', { notice = ('In Haft · noch %d:%02d min'):format(math.floor(jail.seconds / 60), jail.seconds % 60) })
end
RegisterNetEvent('tacov:police:jail', function(d)
  jail = d
  if TacoV.UI.current() then TacoV.UI.close() end
  TacoV.Creator.fadeTeleport(d.x, d.y, d.z, 0.0)
  jailNotice()
end)
RegisterNetEvent('tacov:police:jailTime', function(seconds) if jail then jail.seconds = seconds jailNotice() end end)
RegisterNetEvent('tacov:police:released', function(pos)
  jail = nil
  jailNotice()
  if pos then TacoV.Creator.fadeTeleport(pos.x, pos.y, pos.z, pos.h) end
end)
CreateThread(function()
  while true do
    Wait(1000)
    if jail then
      jail.seconds = math.max(0, jail.seconds - 1)
      jailNotice()
      local ped = PlayerPedId()
      if #(GetEntityCoords(ped) - vector3(jail.x, jail.y, jail.z)) > jail.radius then
        SetEntityCoordsNoOffset(ped, jail.x, jail.y, jail.z, false, false, false)
        notify('warn', 'Du bleibst in der Zelle.')
      end
    end
  end
end)

-- ---------------------------------------------------------------- Wache: Ausrüstung, Asservatenkammer, Insassen

local function at(name)
  local c = TacoV.Client.character
  if not c or c.faction ~= P.faction then return false end
  for _, l in ipairs(TacoV.Client.locations) do
    if l.name == name and #(GetEntityCoords(PlayerPedId()) - vector3(l.x, l.y, l.z)) < 2.5 then return l end
  end
  return false
end
TacoV.Prompt.register({ id = 'police_equipment', label = 'Ausrüstung', order = 9, when = function() return at('faction_equipment_lspd') end,
  run = function() TriggerServerEvent('tacov:police:equipment') end })
TacoV.Prompt.register({ id = 'police_evidence', label = 'Asservatenkammer', order = 9, when = function() return at('faction_evidence_lspd') end,
  run = function() TriggerServerEvent('tacov:police:evidence') end })

RegisterNetEvent('tacov:police:equipment', function(list)
  local items = {}
  for _, e in ipairs(list) do
    items[#items + 1] = { id = 'e_' .. e.index, label = e.label, icon = 'box', price = e.price, sub = e.locked and ('ab ' .. e.rankName) or nil, dim = e.locked,
      badge = e.price > 0 and (e.price .. ' $') or 'frei' }
  end
  TacoV.Menu.open({ id = 'police_equipment', title = 'Ausrüstung', icon = 'shield', info = 'Kauf aus eigener Tasche · bleibt bei dir', items = items }, function(id)
    TriggerServerEvent('tacov:police:equipment', tonumber(id:sub(3)))
  end)
end)

RegisterNetEvent('tacov:police:inmates', function(list)
  local items = {}
  for _, j in ipairs(list) do
    items[#items + 1] = { id = 'j_' .. j.id, label = j.name, icon = 'lock', sub = ('noch %d min · Enter: vorzeitig entlassen'):format(math.ceil(j.seconds / 60)) }
  end
  if #items == 0 then items[1] = { id = 'none', label = 'Niemand in Haft', dim = true } end
  TacoV.Menu.open({ id = 'police_inmates', title = 'Insassen', icon = 'lock', items = items }, function(id)
    if id:sub(1, 2) == 'j_' then TriggerServerEvent('tacov:police:release', tonumber(id:sub(3))) TacoV.Menu.close() end
  end)
end)

-- ---------------------------------------------------------------- MDT

local mdtOpts = nil
function TacoV.Police.openMdt(opts)
  if not onDuty() then notify('error', 'Das MDT gibt es nur im Dienst.') return end
  mdtOpts = opts
  TriggerServerEvent('tacov:mdt:open')
end
RegisterNetEvent('tacov:mdt:open', function(d)
  if TacoV.UI.current() then TacoV.UI.close() end
  d.plate = mdtOpts and mdtOpts.plate or nil
  TacoV.UI.open('mdt', d, true)
  if mdtOpts and mdtOpts.plate then TriggerServerEvent('tacov:mdt:vehicle', mdtOpts.plate) end
  mdtOpts = nil
end)
RegisterNetEvent('tacov:mdt:data', function(kind, data) TacoV.UI.send('mdt', { kind = kind, data = data }) end)
AddEventHandler('tacov:ui:mdt:close', function() TacoV.UI.close() end)
for _, name in ipairs({ 'person', 'file', 'vehicle', 'record', 'warrant', 'warrantClose', 'report' }) do
  AddEventHandler('tacov:ui:mdt:' .. name, function(d) TriggerServerEvent('tacov:mdt:' .. name, d and d.value ~= nil and d.value or d) end)
end
RegisterCommand('mdt', function() TacoV.Police.openMdt() end, false)

-- ---------------------------------------------------------------- Fraktionsmenü (F6): MDT, Einsätze, Insassen

TacoV.Factions.extras.lspd = function(data)
  if not data.duty then return {} end
  return {
    { id = 'mdt', label = 'MDT', icon = 'search', sub = 'Personen, Fahrzeuge, Fahndung, Berichte', section = 'Polizei' },
    { id = 'dispatch', label = 'Einsätze', icon = 'warn', sub = 'Notrufe und Meldungen, Einheiten, Status' },
    { id = 'inmates', label = 'Insassen', icon = 'lock', sub = 'Haftzeiten, vorzeitig entlassen' },
  }, function(id)
    if id == 'mdt' then TacoV.Menu.close() TacoV.Police.openMdt() return true end
    if id == 'dispatch' then TacoV.Dispatch.open() return true end
    if id == 'inmates' then TriggerServerEvent('tacov:police:inmates') return true end
    return false
  end
end
