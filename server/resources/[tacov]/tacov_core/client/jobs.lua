-- Jobs (Phase 8, Client): Jobcenter/Hof-Menüs, Firmenfahrzeug, Routenführung (Blip + Hinweis), Stationen mit Aktionszeit,
-- Bus-Fahrgäste, Taxameter, Holz tragen. Der Server prüft jede Station; hier wird nur angezeigt und gemeldet.
TacoV = TacoV or {}
TacoV.Jobs = { state = false }

local R = TacoV.Config.JobRules
local D = TacoV.Config.JobDetails
local function notify(kind, text) TacoV.UI.send('notify', { kind = kind, text = text }) end

local blip, busy, carrying = nil, false, nil
local passengers = {}      -- Bus: lokale Fahrgäste { ped, stop }

local function clearBlip() if blip then RemoveBlip(blip) blip = nil end end
local function setTarget(s)
  clearBlip()
  if not s or not s.x then return end
  blip = AddBlipForCoord(s.x, s.y, s.z)
  SetBlipSprite(blip, 1)
  SetBlipColour(blip, 5)
  SetBlipScale(blip, 0.9)
  SetBlipRoute(blip, true)
  SetBlipRouteColour(blip, 5)
  BeginTextCommandSetBlipName('STRING')
  AddTextComponentString(s.label or 'Ziel')
  EndTextCommandSetBlipName(blip)
end

local function jobVehicle()
  local s = TacoV.Jobs.state
  if not s or not s.plate then return 0 end
  for _, veh in ipairs(GetGamePool('CVehicle')) do
    if TacoV.Vehicles.plateOf(veh) == s.plate then return veh end
  end
  return 0
end

local function dropLog()
  if carrying then
    if DoesEntityExist(carrying) then DeleteEntity(carrying) end
    carrying = nil
    ClearPedTasks(PlayerPedId())
  end
end

RegisterNetEvent('tacov:jobs:state', function(st)
  TacoV.Jobs.state = st
  if not st then
    clearBlip() dropLog()
    for _, p in ipairs(passengers) do if DoesEntityExist(p.ped) then DeleteEntity(p.ped) end end
    passengers = {}
    TacoV.UI.send('hud', { job = nil })
    return
  end
  setTarget(st.current)
  TacoV.UI.send('hud', { job = ('%s · %s'):format(st.label, st.current and st.current.label or '') })
end)

-- ---------------------------------------------------------------- Menüs (Jobcenter / Hof)

local function openJobMenu(where, list, st)
  local items = {}
  if st then
    items[#items + 1] = { id = 'status', label = ('Im Dienst: %s'):format(st.label), icon = 'briefcase',
      sub = ('%d Aufträge · %d $ verdient'):format(st.orders or 0, st.earned or 0), section = 'Deine Schicht', dim = true }
    if where ~= 'center' and D[st.job].vehicle then items[#items + 1] = { id = 'vehicle', label = 'Fahrzeug holen', icon = 'car', sub = st.plate and ('Steht bereit: ' .. st.plate) or 'Vom Hof' } end
    if st.job == 'taxi' then items[#items + 1] = { id = 'npc', label = 'Fahrgast suchen', icon = 'user', sub = 'NPC-Fahrgast mit Ziel' } end
    items[#items + 1] = { id = 'stop', label = 'Feierabend', icon = 'x', sub = 'Schicht beenden, Fahrzeug zurückgeben' }
  end
  for _, j in ipairs(list) do
    local req = {}
    if j.license then req[#req + 1] = 'Führerschein ' .. j.license .. (j.hasLicense and ' ✓' or ' ✗') end
    if j.tool then req[#req + 1] = TacoV.Config.Items[j.tool].label .. ' nötig' end
    items[#items + 1] = { id = 'job:' .. j.id, label = j.label, icon = j.icon, section = where == 'center' and 'Jobs' or 'Hier arbeiten',
      sub = ('%s · max. %d $/h · %s%s'):format(j.pay, j.cap, j.desc, #req > 0 and (' · ' .. table.concat(req, ', ')) or ''),
      badge = j.earned > 0 and (j.earned .. ' $/h') or nil, dim = st ~= nil or not j.hasLicense }
  end
  TacoV.Menu.open({ id = 'jobs', title = where == 'center' and 'Jobcenter' or 'Ansprechpartner', icon = 'briefcase',
    info = 'Lohn je Auftrag · Obergrenze je Stunde · 8 % Einkommensteuer', items = items }, function(id)
    if id == 'stop' then TacoV.Menu.close() TriggerServerEvent('tacov:jobs:stop')
    elseif id == 'vehicle' then TacoV.Menu.close() TriggerServerEvent('tacov:jobs:vehicle')
    elseif id == 'npc' then TacoV.Menu.close() TriggerServerEvent('tacov:jobs:taxi:npc')
    elseif id:sub(1, 4) == 'job:' then TacoV.Menu.close() TriggerServerEvent('tacov:jobs:start', id:sub(5)) end
  end)
end
RegisterNetEvent('tacov:jobs:menu', function(where, list, st) openJobMenu(where, list, st) end)

TacoV.Prompt.register({ id = 'jobcenter', label = 'Jobcenter', order = 12,
  when = function() return TacoV.Client.nearestLocation('jobcenter', 2.5) or false end,
  run = function() TriggerServerEvent('tacov:jobs:info', 'center') end })
TacoV.Prompt.register({ id = 'job', label = 'Ansprechpartner', order = 12,
  when = function()
    local loc = TacoV.Client.nearestLocation('job', 2.5)
    if not loc then return false end
    local st = TacoV.Jobs.state
    -- im Dienst zählt der Hof als Station (Rückkehr/Verkauf) – dann hat die Station Vorrang
    if st and st.current and st.current.x and #(GetEntityCoords(PlayerPedId()) - vector3(st.current.x, st.current.y, st.current.z)) < R.pointRadius then return false end
    return loc
  end,
  run = function() TriggerServerEvent('tacov:jobs:info', 'hof') end })

-- ---------------------------------------------------------------- Firmenfahrzeug

local function loadModel(model)
  local hash = GetHashKey(model)
  if not IsModelInCdimage(hash) then return nil end
  RequestModel(hash)
  local t = GetGameTimer()
  while not HasModelLoaded(hash) and GetGameTimer() - t < 8000 do Wait(20) end
  return HasModelLoaded(hash) and hash or nil
end

RegisterNetEvent('tacov:jobs:spawnVehicle', function(d)
  local hash = loadModel(d.model)
  if not hash then notify('error', 'Fahrzeugmodell konnte nicht geladen werden.') return end
  local s = d.spawn
  local veh = CreateVehicle(hash, s.x, s.y, s.z, s.h or 0.0, true, false)
  local t = GetGameTimer()
  while not DoesEntityExist(veh) and GetGameTimer() - t < 3000 do Wait(20) end
  if not DoesEntityExist(veh) then notify('error', 'Fahrzeug konnte nicht erstellt werden.') return end
  SetModelAsNoLongerNeeded(hash)
  SetEntityAsMissionEntity(veh, true, true)
  SetVehicleNumberPlateText(veh, d.plate)
  SetVehicleOnGroundProperly(veh)
  SetVehicleDoorsLocked(veh, 1)
  TacoV.Vehicles.keys[d.plate] = true
  local tank = TacoV.Vehicles.tankOf(veh)
  Entity(veh).state:set('fuel', tank, true)
  Entity(veh).state:set('jobVehicle', true, true)
  SetVehicleFuelLevel(veh, 100.0)
  TriggerServerEvent('tacov:jobs:vehicleSpawned', NetworkGetNetworkIdFromEntity(veh))
  notify('success', ('Dein Firmenfahrzeug (%s) steht bereit.'):format(d.plate))
end)

-- ---------------------------------------------------------------- Stationen mit Aktionszeit

local function doAction(label, seconds, scenario, cb)
  if busy then return end
  busy = true
  local ped = PlayerPedId()
  if scenario then TaskStartScenarioInPlace(ped, scenario, 0, true) end
  local t0 = GetGameTimer()
  CreateThread(function()
    while GetGameTimer() - t0 < seconds * 1000 do
      Wait(100)
      local p = PlayerPedId()
      local frac = (GetGameTimer() - t0) / (seconds * 1000)
      TacoV.UI.send('hint', { key = '…', text = label, progress = frac })
      if IsPedInAnyVehicle(p, false) or GetEntityHealth(p) <= 100 or (not scenario and (IsPedRunning(p) or IsPedSprinting(p))) then
        ClearPedTasks(p)
        busy = false
        TacoV.UI.send('hint', nil)
        notify('warn', 'Abgebrochen.')
        return
      end
    end
    ClearPedTasks(PlayerPedId())
    busy = false
    TacoV.UI.send('hint', nil)
    cb()
  end)
end

local function carryLog()
  local ped = PlayerPedId()
  RequestAnimDict('anim@heists@box_carry@')
  local t = GetGameTimer()
  while not HasAnimDictLoaded('anim@heists@box_carry@') and GetGameTimer() - t < 1000 do Wait(10) end
  local model = GetHashKey('prop_log_01')
  RequestModel(model)
  t = GetGameTimer()
  while not HasModelLoaded(model) and GetGameTimer() - t < 3000 do Wait(10) end
  local pos = GetEntityCoords(ped)
  carrying = CreateObject(model, pos.x, pos.y, pos.z, true, true, false)
  AttachEntityToEntity(carrying, ped, GetPedBoneIndex(ped, 60309), 0.05, 0.1, -0.25, 0.0, 90.0, 0.0, true, true, false, true, 1, true)
  TaskPlayAnim(ped, 'anim@heists@box_carry@', 'idle', 8.0, -8.0, -1, 50, 0.0, false, false, false)
end

local SCENARIO = { trash = 'WORLD_HUMAN_GARDENER_PLANT', deliver = nil, chop = 'WORLD_HUMAN_HAMMERING', mine = 'WORLD_HUMAN_HAMMERING' }

TacoV.Prompt.register({ id = 'jobstep', label = 'Station', order = 6,
  when = function()
    local st = TacoV.Jobs.state
    if not st or not st.current or busy then return false end
    local s = st.current
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) and s.kind ~= 'return' then return false end
    if s.kind == 'stop' or s.kind == 'taxi' then return false end
    if s.kind == 'load' then
      if not carrying then return false end
      local veh = jobVehicle()
      if veh == 0 or #(GetEntityCoords(ped) - GetEntityCoords(veh)) > 6.0 then return false end
      return { s = s, label = 'Stamm aufladen' }
    end
    if s.kind == 'chop' and carrying then return false end
    if not s.x or #(GetEntityCoords(ped) - vector3(s.x, s.y, s.z)) > R.pointRadius then return false end
    local label = s.label
    if s.kind == 'return' then label = (st.job == 'lumber' and 'Stämme abliefern') or 'Auftrag abschließen' end
    if s.kind == 'sell' then label = 'Erz verkaufen' end
    return { s = s, label = label }
  end,
  run = function(ctx)
    local s = ctx.s
    if s.kind == 'return' or s.kind == 'sell' then TriggerServerEvent('tacov:jobs:step', { kind = s.kind }) return end
    if s.kind == 'load' then dropLog() TriggerServerEvent('tacov:jobs:step', { kind = 'load' }) return end
    local secs = s.seconds or R.actionSeconds
    doAction(ctx.label, secs, SCENARIO[s.kind], function()
      if s.kind == 'chop' then carryLog() end
      TriggerServerEvent('tacov:jobs:step', { kind = s.kind })
    end)
  end })
-- Hinweis zur Station zeigt den Stationsnamen statt „Station“
CreateThread(function()
  while true do
    Wait(500)
    local cur = TacoV.Prompt.current
    if cur and cur.entry.id == 'jobstep' and cur.ctx and cur.ctx.label then TacoV.UI.send('hint', { key = 'E', text = cur.ctx.label }) end
  end
end)

-- ---------------------------------------------------------------- Bus: Haltestellen mit Fahrgästen

local PASSENGER_MODELS = { 'a_m_y_business_02', 'a_f_y_tourist_01', 'a_m_m_skater_01', 'a_f_m_bevhills_01', 'a_m_y_hipster_02', 'a_f_y_hipster_02' }
local function spawnPassenger(stop, bus)
  local model = GetHashKey(PASSENGER_MODELS[math.random(#PASSENGER_MODELS)])
  RequestModel(model)
  local t = GetGameTimer()
  while not HasModelLoaded(model) and GetGameTimer() - t < 3000 do Wait(10) end
  local ped = CreatePed(4, model, stop.x + math.random(-2, 2), stop.y + math.random(-2, 2), stop.z, 0.0, false, false)
  SetModelAsNoLongerNeeded(model)
  SetBlockingOfNonTemporaryEvents(ped, true)
  for seat = 0, GetVehicleMaxNumberOfPassengers(bus) - 1 do
    if IsVehicleSeatFree(bus, seat) then TaskEnterVehicle(ped, bus, 12000, seat, 1.0, 1, 0) break end
  end
  passengers[#passengers + 1] = { ped = ped, since = GetGameTimer() }
end

CreateThread(function()
  while true do
    Wait(500)
    local st = TacoV.Jobs.state
    if st and st.job == 'bus' and st.current and st.current.kind == 'stop' and not busy then
      local ped = PlayerPedId()
      local bus = GetVehiclePedIsIn(ped, false)
      local s = st.current
      if bus ~= 0 and GetPedInVehicleSeat(bus, -1) == ped and TacoV.Vehicles.plateOf(bus) == st.plate
        and #(GetEntityCoords(bus) - vector3(s.x, s.y, s.z)) < 10.0 and GetEntitySpeed(bus) < 0.5 then
        busy = true
        -- Fahrgäste aussteigen lassen (die, die schon länger drin sind), neue einsteigen lassen
        for i = #passengers, 1, -1 do
          local p = passengers[i]
          if GetGameTimer() - p.since > 60000 and DoesEntityExist(p.ped) then
            TaskLeaveVehicle(p.ped, bus, 0)
            SetPedAsNoLongerNeeded(p.ped)
            table.remove(passengers, i)
          end
        end
        for _ = 1, math.random(1, 3) do spawnPassenger(s, bus) end
        local t0 = GetGameTimer()
        while GetGameTimer() - t0 < R.busWaitSeconds * 1000 do
          TacoV.UI.send('hint', { key = '…', text = 'Fahrgäste steigen ein', progress = (GetGameTimer() - t0) / (R.busWaitSeconds * 1000) })
          Wait(100)
        end
        TacoV.UI.send('hint', nil)
        busy = false
        TriggerServerEvent('tacov:jobs:step', { kind = 'stop' })
        Wait(3000)
      end
    end
  end
end)

-- ---------------------------------------------------------------- Taxi: Taxameter für Spieler und NPC-Fahrgäste

local npcFare = nil   -- { pickup, dest, ped, inside, meters, lastPos }
local playerFares = {} -- [serverId] = { meters, lastPos }

RegisterNetEvent('tacov:jobs:taxi:npc', function(d)
  npcFare = { pickup = d.pickup, dest = d.dest, meters = 0 }
  setTarget({ x = d.pickup.x, y = d.pickup.y, z = d.pickup.z, label = 'Fahrgast abholen' })
  notify('info', 'Fahrgast wartet – Route gesetzt.')
end)
RegisterNetEvent('tacov:jobs:taxi:request', function(d)
  SetNewWaypoint(d.x + 0.0, d.y + 0.0)
  notify('info', ('Taxi gerufen von %s – Wegpunkt gesetzt.'):format(d.name))
  PlaySoundFrontend(-1, 'Text_Arrive_Tone', 'Phone_SoundSet_Default', true)
end)

CreateThread(function()
  while true do
    Wait(500)
    local st = TacoV.Jobs.state
    if st and st.job == 'taxi' then
      local ped = PlayerPedId()
      local taxi = GetVehiclePedIsIn(ped, false)
      local driving = taxi ~= 0 and GetPedInVehicleSeat(taxi, -1) == ped and TacoV.Vehicles.plateOf(taxi) == st.plate
      local pos = GetEntityCoords(ped)
      -- NPC-Fahrgast
      if npcFare and driving then
        if not npcFare.ped then
          if #(pos - vector3(npcFare.pickup.x, npcFare.pickup.y, npcFare.pickup.z)) < 20.0 and GetEntitySpeed(taxi) < 0.5 then
            local model = GetHashKey(PASSENGER_MODELS[math.random(#PASSENGER_MODELS)])
            RequestModel(model)
            local t = GetGameTimer()
            while not HasModelLoaded(model) and GetGameTimer() - t < 3000 do Wait(10) end
            npcFare.ped = CreatePed(4, model, npcFare.pickup.x, npcFare.pickup.y, npcFare.pickup.z, 0.0, false, false)
            SetBlockingOfNonTemporaryEvents(npcFare.ped, true)
            TaskEnterVehicle(npcFare.ped, taxi, 15000, 1, 1.0, 1, 0)
          end
        elseif not npcFare.inside then
          if IsPedInVehicle(npcFare.ped, taxi, false) then
            npcFare.inside, npcFare.lastPos = true, pos
            setTarget({ x = npcFare.dest.x, y = npcFare.dest.y, z = npcFare.dest.z, label = 'Fahrgast absetzen' })
            notify('info', 'Fahrgast eingestiegen – Taxameter läuft.')
          end
        else
          npcFare.meters = npcFare.meters + #(pos - npcFare.lastPos)
          npcFare.lastPos = pos
          if #(pos - vector3(npcFare.dest.x, npcFare.dest.y, npcFare.dest.z)) < 15.0 and GetEntitySpeed(taxi) < 0.5 then
            TaskLeaveVehicle(npcFare.ped, taxi, 0)
            SetPedAsNoLongerNeeded(npcFare.ped)
            TriggerServerEvent('tacov:jobs:taxi:fare', 'end', 0, math.floor(npcFare.meters))
            npcFare = nil
            setTarget(nil)
          end
        end
      end
      -- Spieler-Fahrgäste: Sitze prüfen
      if driving then
        local seen = {}
        for seat = 0, GetVehicleMaxNumberOfPassengers(taxi) - 1 do
          local p = GetPedInVehicleSeat(taxi, seat)
          if p ~= 0 and IsPedAPlayer(p) then
            local sid = GetPlayerServerId(NetworkGetPlayerIndexFromPed(p))
            seen[sid] = true
            if not playerFares[sid] then
              playerFares[sid] = { meters = 0, lastPos = pos }
              TriggerServerEvent('tacov:jobs:taxi:fare', 'start', sid)
            else
              playerFares[sid].meters = playerFares[sid].meters + #(pos - playerFares[sid].lastPos)
              playerFares[sid].lastPos = pos
            end
          end
        end
        for sid, f in pairs(playerFares) do
          if not seen[sid] then
            TriggerServerEvent('tacov:jobs:taxi:fare', 'end', sid, math.floor(f.meters))
            playerFares[sid] = nil
          end
        end
      end
    end
  end
end)

--- F4: Taxi rufen (alle) / Fahrgast suchen (Taxifahrer)
function TacoV.Jobs.callTaxi() TriggerServerEvent('tacov:jobs:taxi:call') end
function TacoV.Jobs.findFare() TriggerServerEvent('tacov:jobs:taxi:npc') end

AddEventHandler('onResourceStop', function(res)
  if res ~= GetCurrentResourceName() then return end
  dropLog()
  for _, p in ipairs(passengers) do if DoesEntityExist(p.ped) then DeleteEntity(p.ped) end end
end)
