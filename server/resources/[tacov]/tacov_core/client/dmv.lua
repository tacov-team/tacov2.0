-- DMV und Fahrschule (Client): Schalter-Menü, Zulassung, Halterwechsel, Theorie als Menü, Praxisfahrt mit Kontrollpunkten.
TacoV = TacoV or {}
TacoV.DMV = {}

local function fmt(n)
  local s = tostring(math.floor(n + 0.5))
  local out = s:reverse():gsub('(%d%d%d)', '%1.'):reverse()
  if out:sub(1, 1) == '.' then out = out:sub(2) end
  return out .. ' $'
end
local labels = { A = 'Führerschein A (Motorrad)', B = 'Führerschein B (PKW)', C = 'Führerschein C (LKW)', weapon = 'Waffenschein' }

-- Nächster Spieler (Server-ID) im Umkreis
local function nearestPlayer(radius)
  local me, pos, best, bestD = PlayerPedId(), GetEntityCoords(PlayerPedId()), nil, radius
  for _, pid in ipairs(GetActivePlayers()) do
    local ped = GetPlayerPed(pid)
    if ped ~= me then
      local d = #(GetEntityCoords(ped) - pos)
      if d < bestD then best, bestD = GetPlayerServerId(pid), d end
    end
  end
  return best
end

-- Fahrzeuge im Umkreis (für Zulassung/Halterwechsel)
local function nearbyVehicles(radius)
  local list, pos = {}, GetEntityCoords(PlayerPedId())
  for _, veh in ipairs(GetGamePool('CVehicle')) do
    if #(GetEntityCoords(veh) - pos) <= radius then list[#list + 1] = NetworkGetNetworkIdFromEntity(veh) end
  end
  return list
end

TacoV.Prompt.register({
  id = 'dmv', label = 'DMV / Fahrschule', order = 10,
  when = function() return not IsPedInAnyVehicle(PlayerPedId(), false) and TacoV.Client.nearestLocation('dmv', 4.0) ~= nil end,
  run = function() TriggerServerEvent('tacov:dmv:open', nearbyVehicles(30.0)) end,
})

RegisterNetEvent('tacov:dmv:refresh', function() TriggerServerEvent('tacov:dmv:open', nearbyVehicles(30.0)) end)

RegisterNetEvent('tacov:dmv:data', function(d)
  local items = {
    { id = 'licenses', label = 'Meine Führerscheine', icon = 'id', sub = #d.licenses > 0 and (#d.licenses .. ' vorhanden') or 'keine' },
    { id = 'register', label = 'Fahrzeug zulassen', icon = 'car', price = fmt(d.fees.registration), sub = 'Fahrzeug muss vor dem DMV stehen', section = 'Zulassung' },
    { id = 'transfer', label = 'Halterwechsel', icon = 'group', price = fmt(d.fees.transfer), sub = 'Käufer muss neben dir stehen' },
    { id = 'B', label = labels.B, icon = 'car', price = fmt(d.school.B), section = 'Fahrschule', sub = 'Theorie + Praxisfahrt' },
    { id = 'A', label = labels.A, icon = 'speed', price = fmt(d.school.A), sub = 'Theorie + Praxisfahrt' },
    { id = 'C', label = labels.C, icon = 'trunk', price = fmt(d.school.C), sub = 'Theorie + Praxisfahrt' },
  }
  local has = {}
  for _, l in ipairs(d.licenses) do has[l.type] = l end
  for _, it in ipairs(items) do
    if has[it.id] then it.dim, it.badge, it.price = true, 'vorhanden', nil end
  end
  local menuOpen = TacoV.Menu.isOpen()
  if menuOpen then TacoV.Menu.close() end
  TacoV.Menu.open({
    id = 'dmv', title = 'DMV', icon = 'id', info = ('Konto %s · Wiederholung einer Prüfung %s'):format(fmt(d.bank), fmt(d.school.retry)),
    note = 'Zulassung: 150 $, ohne Kennzeichen droht Beschlagnahme. Ab 8 Punkten Entzug.',
    items = items,
  }, function(id)
    if id == 'licenses' then
      local li = {}
      for _, l in ipairs(d.licenses) do li[#li + 1] = { id = l.type, label = labels[l.type] or l.type, icon = 'id', sub = ('%d Punkte'):format(l.points), dim = true } end
      if #li == 0 then li[1] = { id = 'none', label = 'Keine Führerscheine', dim = true, icon = 'info' } end
      TacoV.Menu.open({ id = 'dmv_lic', title = 'Führerscheine', icon = 'id', info = 'Deine Fahrerlaubnisse und Punkte', items = li }, function() end)
    elseif id == 'register' then
      local vi = {}
      for _, v in ipairs(d.vehicles) do
        vi[#vi + 1] = { id = tostring(v.netId), label = v.model, icon = 'car', sub = v.plate .. (v.registered and ' · bereits zugelassen' or ''), dim = v.registered }
      end
      if #vi == 0 then vi[1] = { id = 'none', label = 'Kein eigenes Fahrzeug in der Nähe', dim = true, icon = 'info', sub = 'Stell es vor das DMV (30 m)' } end
      TacoV.Menu.open({ id = 'dmv_reg', title = 'Zulassung', icon = 'car', info = fmt(d.fees.registration) .. ' je Fahrzeug', items = vi }, function(netId)
        if netId ~= 'none' then TacoV.Menu.close() TriggerServerEvent('tacov:dmv:register', tonumber(netId)) end
      end)
    elseif id == 'transfer' then
      local vi = {}
      for _, v in ipairs(d.vehicles) do vi[#vi + 1] = { id = tostring(v.id), label = v.model, icon = 'car', sub = v.plate } end
      if #vi == 0 then vi[1] = { id = 'none', label = 'Kein eigenes Fahrzeug in der Nähe', dim = true, icon = 'info' } end
      TacoV.Menu.open({ id = 'dmv_tr', title = 'Halterwechsel', icon = 'group', info = ('Käufer zahlt %s · muss neben dir stehen'):format(fmt(d.fees.transfer)), items = vi }, function(vid)
        if vid == 'none' then return end
        local target = nearestPlayer(3.0)
        TacoV.Menu.close()
        if not target then return TacoV.UI.send('notify', { kind = 'error', text = 'Der Käufer muss direkt neben dir stehen.' }) end
        TriggerServerEvent('tacov:dmv:transfer:offer', tonumber(vid), target)
      end)
    elseif id == 'A' or id == 'B' or id == 'C' then
      TacoV.Menu.close()
      TriggerServerEvent('tacov:dmv:school:start', id)
    end
  end)
end)

-- Halterwechsel: Käufer bestätigt
RegisterNetEvent('tacov:dmv:transfer:ask', function(o)
  if TacoV.UI.current() and TacoV.UI.current() ~= 'menu' then return TriggerServerEvent('tacov:dmv:transfer:accept', false) end
  if TacoV.Menu.isOpen() then TacoV.Menu.close() end
  TacoV.Menu.open({
    id = 'dmv_accept', title = 'Halterwechsel', icon = 'group', info = ('%s überschreibt dir %s (%s)'):format(o.seller, o.model, o.plate),
    note = ('Gebühr %s von deinem Konto. Alle bisherigen Schlüssel verfallen.'):format(fmt(o.fee)),
    items = { { id = 'yes', label = 'Annehmen und bezahlen', icon = 'check', price = fmt(o.fee) }, { id = 'no', label = 'Ablehnen', icon = 'x' } },
  }, function(id)
    TacoV.Menu.close()
    TriggerServerEvent('tacov:dmv:transfer:accept', id == 'yes')
  end)
end)

-- Zulassung: neues Kennzeichen am Fahrzeug setzen
RegisterNetEvent('tacov:vehicles:setPlate', function(netId, plate)
  local veh = NetworkGetEntityFromNetworkId(netId)
  if veh == 0 or not DoesEntityExist(veh) then return end
  NetworkRequestControlOfEntity(veh)
  local t = GetGameTimer()
  while not NetworkHasControlOfEntity(veh) and GetGameTimer() - t < 1000 do Wait(10) end
  SetVehicleNumberPlateText(veh, plate)
  TacoV.Vehicles.keys[plate] = true
end)

-- ---------------------------------------------------------------- Theorie

RegisterNetEvent('tacov:dmv:theory:question', function(q)
  local items = {}
  for i, a in ipairs(q.answers) do items[i] = { id = tostring(i), label = a, icon = 'next' } end
  if TacoV.Menu.isOpen() then TacoV.Menu.close() end
  TacoV.Menu.open({
    id = 'dmv_q', title = ('Frage %d von %d'):format(q.n, q.total), icon = 'book', info = q.text, items = items,
    note = 'Mit ↑ ↓ wählen, Enter antwortet. Esc bricht die Prüfung ab (Gebühr verfällt).',
    onClose = function() if TacoV.DMV.inTheory then TacoV.DMV.inTheory = false; TriggerServerEvent('tacov:dmv:practice:fail', 'Prüfung abgebrochen') end end,
  }, function(id)
    TacoV.DMV.inTheory = false
    TriggerServerEvent('tacov:dmv:theory:answer', tonumber(id))
  end)
  TacoV.DMV.inTheory = true
end)

-- ---------------------------------------------------------------- Praxis

local exam = nil -- { veh, points, idx, blip, speedLimit, tolerance, maxDamage, deadline, overspeedSince }

local function loadModel(model)
  local hash = GetHashKey(model)
  RequestModel(hash)
  local t = GetGameTimer()
  while not HasModelLoaded(hash) and GetGameTimer() - t < 8000 do Wait(20) end
  return HasModelLoaded(hash) and hash or nil
end

local function clearExam()
  if not exam then return end
  if exam.blip then RemoveBlip(exam.blip) end
  if exam.veh and DoesEntityExist(exam.veh) then DeleteEntity(exam.veh) end
  exam = nil
end

local function setBlip()
  if exam.blip then RemoveBlip(exam.blip) end
  local p = exam.points[exam.idx]
  if not p then return end
  exam.blip = AddBlipForCoord(p.x, p.y, p.z)
  SetBlipSprite(exam.blip, 1); SetBlipColour(exam.blip, 5); SetBlipRoute(exam.blip, true); SetBlipRouteColour(exam.blip, 5)
end

RegisterNetEvent('tacov:dmv:practice:start', function(d)
  clearExam()
  TacoV.Menu.close()
  local hash = loadModel(d.vehicle)
  if not hash then return TriggerServerEvent('tacov:dmv:practice:fail', 'Prüfungsfahrzeug fehlt') end
  local s = d.start
  local veh = CreateVehicle(hash, s.x, s.y, s.z, s.h, true, false)
  local t = GetGameTimer()
  while not DoesEntityExist(veh) and GetGameTimer() - t < 3000 do Wait(20) end
  SetModelAsNoLongerNeeded(hash)
  SetEntityAsMissionEntity(veh, true, true)
  SetVehicleNumberPlateText(veh, 'FAHRSCHU')
  SetVehicleOnGroundProperly(veh)
  Entity(veh).state:set('fuel', 40.0, true)
  Entity(veh).state:set('engine', true, true)
  TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
  SetVehicleEngineOn(veh, true, true, false)
  -- Kontrollpunkte auf den nächsten befahrbaren Straßenpunkt legen (Config-Punkte können neben der Fahrbahn liegen)
  for _, p in ipairs(d.points) do
    local ok, node = GetClosestVehicleNode(p.x, p.y, p.z, 1, 3.0, 0)
    if ok and #(node - vector3(p.x, p.y, p.z)) < 40.0 then p.x, p.y, p.z = node.x, node.y, node.z end
  end
  exam = { veh = veh, points = d.points, idx = 1, speedLimit = d.speedLimit, tolerance = d.tolerance, maxDamage = d.maxDamage,
    deadline = GetGameTimer() + d.timeLimit * 1000, radius = d.radius, overspeedSince = nil }
  setBlip()
  TacoV.UI.send('notify', { kind = 'info', text = ('Praxisfahrt: %d Kontrollpunkte, höchstens %d km/h. Folge der Route.'):format(#d.points, d.speedLimit) })

  CreateThread(function()
    while exam and exam.veh == veh do
      Wait(0)
      if not exam or exam.veh ~= veh then break end -- Prüfung wurde während des Wartens beendet
      local p = exam.points[exam.idx]
      if p then DrawMarker(1, p.x, p.y, p.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, exam.radius * 2, exam.radius * 2, 1.5, 139, 92, 246, 120, false, false, 2, false, nil, nil, false) end
      local ped = PlayerPedId()
      if GetVehiclePedIsIn(ped, false) ~= veh then
        TriggerServerEvent('tacov:dmv:practice:fail', 'Fahrzeug verlassen'); clearExam(); break
      end
      local speed = GetEntitySpeed(veh) * 3.6
      if speed > exam.speedLimit + exam.tolerance then
        exam.overspeedSince = exam.overspeedSince or GetGameTimer()
        if GetGameTimer() - exam.overspeedSince > 3000 then TriggerServerEvent('tacov:dmv:practice:fail', 'zu schnell gefahren'); clearExam(); break end
      else
        exam.overspeedSince = nil
      end
      if GetVehicleBodyHealth(veh) < 1000.0 - exam.maxDamage then
        TriggerServerEvent('tacov:dmv:practice:fail', 'Unfall'); clearExam(); break
      end
      if GetGameTimer() > exam.deadline then
        TriggerServerEvent('tacov:dmv:practice:fail', 'Zeit überschritten'); clearExam(); break
      end
      if p and #(GetEntityCoords(veh) - vector3(p.x, p.y, p.z)) <= exam.radius then
        TriggerServerEvent('tacov:dmv:practice:checkpoint', exam.idx, p.x, p.y, p.z)
        exam.idx = exam.idx + 1
        if exam.points[exam.idx] then
          setBlip()
          TacoV.UI.send('notify', { kind = 'info', text = ('Kontrollpunkt %d von %d – weiter zum nächsten.'):format(exam.idx - 1, #exam.points) })
        else
          if exam.blip then RemoveBlip(exam.blip); exam.blip = nil end
        end
      end
    end
  end)
end)

RegisterNetEvent('tacov:dmv:exam:end', function()
  TacoV.DMV.inTheory = false
  if TacoV.Menu.isOpen() then TacoV.Menu.close() end
  CreateThread(function()
    Wait(1500)
    clearExam()
  end)
end)
