-- Fahrzeuge (Client): Spawnen auf Anweisung des Servers, Tank und Kilometer, Schloss, Schlüssel, Garagen- und
-- Kaufhaus-Menüs, Tanken, Kofferraum, Fahrzeugmenü (F6 → Fahrzeug). Der Server prüft alles erneut.
TacoV = TacoV or {}
TacoV.Vehicles = { keys = {} }

local Cfg = TacoV.Config.Vehicles
local byModelHash = {}
for _, v in ipairs(Cfg.list) do byModelHash[GetHashKey(v.model)] = v end

local function trim(s) return (tostring(s or ''):gsub('^%s+', ''):gsub('%s+$', '')) end
local function fmt(n)
  local s = tostring(math.floor(n + 0.5))
  local out = s:reverse():gsub('(%d%d%d)', '%1.'):reverse()
  if out:sub(1, 1) == '.' then out = out:sub(2) end
  return out .. ' $'
end
local function notify(kind, text) TacoV.UI.send('notify', { kind = kind, text = text }) end

--- Kaufliste-Eintrag und Klasse eines Fahrzeugs (nil für Grundspiel-Fahrzeuge außerhalb der Liste)
function TacoV.Vehicles.defOf(veh)
  return byModelHash[GetEntityModel(veh)]
end

function TacoV.Vehicles.tankOf(veh)
  local def = TacoV.Vehicles.defOf(veh)
  local cls = def and Cfg.classes[def.class]
  return cls and cls.tank or 65
end

function TacoV.Vehicles.plateOf(veh)
  return trim(GetVehicleNumberPlateText(veh))
end

function TacoV.Vehicles.hasKey(veh)
  return veh ~= 0 and TacoV.Vehicles.keys[TacoV.Vehicles.plateOf(veh)] == true
end

--- Tankinhalt in Litern (Statebag am Fahrzeug; fremde Fahrzeuge bekommen beim ersten Einsteigen einen Zufallswert).
function TacoV.Vehicles.fuelOf(veh)
  local f = Entity(veh).state.fuel
  if f == nil then
    if NetworkHasControlOfEntity(veh) then
      local tank = TacoV.Vehicles.tankOf(veh)
      f = tank * (Cfg.fuel.npcTankMin + math.random() * (Cfg.fuel.npcTankMax - Cfg.fuel.npcTankMin))
      Entity(veh).state:set('fuel', f, true)
    else
      f = GetVehicleFuelLevel(veh) / 100 * TacoV.Vehicles.tankOf(veh)
    end
  end
  return f
end

local function setFuel(veh, liters)
  liters = math.max(0, math.min(TacoV.Vehicles.tankOf(veh), liters))
  if NetworkHasControlOfEntity(veh) then Entity(veh).state:set('fuel', liters, true) end
  SetVehicleFuelLevel(veh, liters / TacoV.Vehicles.tankOf(veh) * 100)
  return liters
end

RegisterNetEvent('tacov:vehicles:keys', function(list)
  TacoV.Vehicles.keys = {}
  for _, p in ipairs(list or {}) do TacoV.Vehicles.keys[trim(p)] = true end
end)

-- ---------------------------------------------------------------- Spawnen

local function loadModel(model)
  local hash = GetHashKey(model)
  if not IsModelInCdimage(hash) then return nil end
  RequestModel(hash)
  local t = GetGameTimer()
  while not HasModelLoaded(hash) and GetGameTimer() - t < 8000 do Wait(20) end
  if not HasModelLoaded(hash) then return nil end
  return hash
end

RegisterNetEvent('tacov:vehicles:spawn', function(d)
  local hash = loadModel(d.model)
  if not hash then return notify('error', 'Fahrzeugmodell konnte nicht geladen werden.') end
  local s = d.spawn
  local veh = CreateVehicle(hash, s.x, s.y, s.z, s.h or 0.0, true, false)
  local t = GetGameTimer()
  while not DoesEntityExist(veh) and GetGameTimer() - t < 3000 do Wait(20) end
  if not DoesEntityExist(veh) then return notify('error', 'Fahrzeug konnte nicht erstellt werden.') end
  SetModelAsNoLongerNeeded(hash)
  SetEntityAsMissionEntity(veh, true, true)
  SetVehicleNumberPlateText(veh, d.plate)
  SetVehicleOnGroundProperly(veh)
  SetVehicleDoorsLocked(veh, 1)
  SetVehicleEngineHealth(veh, (d.engineHealth or 1000.0) + 0.0)
  SetVehicleBodyHealth(veh, (d.bodyHealth or 1000.0) + 0.0)
  TacoV.Vehicles.applyProps(veh, d.props)
  Entity(veh).state:set('fuel', d.fuel or d.tank, true)
  SetVehicleFuelLevel(veh, (d.fuel or d.tank) / (d.tank or 65) * 100)
  TriggerServerEvent('tacov:vehicles:spawned', d.id, NetworkGetNetworkIdFromEntity(veh))
end)

-- Ausstattung (Farben, Tuning) lesen/setzen – wird beim Einparken gespeichert und beim Ausparken gesetzt
local MODS = { engine = 11, brakes = 12, transmission = 13, suspension = 15, wheels = 23 }
function TacoV.Vehicles.propsOf(veh)
  local c1, c2 = GetVehicleColours(veh)
  local e1, e2 = GetVehicleExtraColours(veh)
  local mods = {}
  for k, t in pairs(MODS) do mods[k] = GetVehicleMod(veh, t) end
  mods.turbo = IsToggleModOn(veh, 18)
  mods.wheelType = GetVehicleWheelType(veh)
  mods.tint = GetVehicleWindowTint(veh)
  return { colors = { c1, c2 }, extraColors = { e1, e2 }, mods = mods }
end
local propsOf = TacoV.Vehicles.propsOf

function TacoV.Vehicles.applyProps(veh, props)
  if type(props) ~= 'table' then return end
  SetVehicleModKit(veh, 0)
  if props.colors then SetVehicleColours(veh, props.colors[1], props.colors[2]) end
  if props.extraColors then SetVehicleExtraColours(veh, props.extraColors[1], props.extraColors[2]) end
  local m = props.mods
  if type(m) == 'table' then
    if m.wheelType then SetVehicleWheelType(veh, m.wheelType) end
    for k, t in pairs(MODS) do if m[k] ~= nil then SetVehicleMod(veh, t, m[k], false) end end
    if m.turbo ~= nil then ToggleVehicleMod(veh, 18, m.turbo == true) end
    if m.tint then SetVehicleWindowTint(veh, m.tint) end
  end
end

-- ---------------------------------------------------------------- Tank, Kilometer, Herzschlag

local kmSinceSeen = 0.0

-- Punkt 4.8: Der Motor startet nicht automatisch beim Einsteigen. Zustand liegt im Statebag `engine`; beim Einsteigen
-- wird er wiederhergestellt (aus bleibt aus), beim Aussteigen läuft ein laufender Motor weiter.
local lastVeh = 0
CreateThread(function()
  while true do
    Wait(100)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= lastVeh then
      if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
        -- Unbekannter Zustand (fremdes/NPC-Fahrzeug): so lassen, wie es gerade läuft – ein laufender Motor bleibt an
        if Entity(veh).state.engine == nil and NetworkHasControlOfEntity(veh) then
          Entity(veh).state:set('engine', GetIsVehicleEngineRunning(veh), true)
        end
        local on = Entity(veh).state.engine == true
        SetVehicleEngineOn(veh, on, true, true)
      elseif veh == 0 and lastVeh ~= 0 and DoesEntityExist(lastVeh) then
        if Entity(lastVeh).state.engine == true then SetVehicleEngineOn(lastVeh, true, true, true) end
      end
      lastVeh = veh
    elseif veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped and Entity(veh).state.engine ~= true and GetIsVehicleEngineRunning(veh) then
      SetVehicleEngineOn(veh, false, true, true) -- Spiel wollte automatisch starten
    end
  end
end)

CreateThread(function()
  local lastTick, lastSent = GetGameTimer(), 0
  while true do
    Wait(1000)
    local now = GetGameTimer()
    local dt = (now - lastTick) / 1000
    lastTick = now
    local ped = PlayerPedId()
    local veh = TacoV.Client.character and GetVehiclePedIsIn(ped, false) or 0
    if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
      local tank = TacoV.Vehicles.tankOf(veh)
      local fuel = TacoV.Vehicles.fuelOf(veh)
      if GetIsVehicleEngineRunning(veh) then
        local rpm = GetVehicleCurrentRpm(veh)
        fuel = fuel - tank * Cfg.fuel.consumptionPerSecond * (0.2 + 0.8 * rpm) * dt
        fuel = setFuel(veh, fuel)
        kmSinceSeen = kmSinceSeen + GetEntitySpeed(veh) * dt / 1000
      else
        SetVehicleFuelLevel(veh, fuel / tank * 100)
      end
      if fuel <= 0.05 then
        SetVehicleEngineOn(veh, false, true, true)
      end
      if now - lastSent > 60000 then
        lastSent = now
        TriggerServerEvent('tacov:vehicles:seen', {
          netId = NetworkGetNetworkIdFromEntity(veh), fuel = fuel, kmDelta = kmSinceSeen,
          bodyHealth = GetVehicleBodyHealth(veh), engineHealth = GetVehicleEngineHealth(veh),
        })
        kmSinceSeen = 0.0
      end
    end
  end
end)

-- ---------------------------------------------------------------- Schloss, Schlüssel, Kofferraum, Motor

local function nearbyVehicle(ctxVeh)
  if ctxVeh and ctxVeh ~= 0 then return ctxVeh end
  local ped = PlayerPedId()
  local veh = GetVehiclePedIsIn(ped, false)
  if veh == 0 then
    local p = GetEntityCoords(ped)
    veh = GetClosestVehicle(p.x, p.y, p.z, 4.0, 0, 70)
  end
  return veh
end

function TacoV.Vehicles.toggleLock(veh)
  veh = nearbyVehicle(veh)
  if veh == 0 then return end
  local locked = GetVehicleDoorLockStatus(veh) >= 2
  TriggerServerEvent('tacov:vehicles:lock', NetworkGetNetworkIdFromEntity(veh), not locked)
end

RegisterNetEvent('tacov:vehicles:lockResult', function(netId, locked)
  local veh = NetworkGetEntityFromNetworkId(netId)
  if veh == 0 or not DoesEntityExist(veh) then return end
  NetworkRequestControlOfEntity(veh)
  local t = GetGameTimer()
  while not NetworkHasControlOfEntity(veh) and GetGameTimer() - t < 1000 do Wait(10) end
  SetVehicleDoorsLocked(veh, locked and 2 or 1)
  SetVehicleLights(veh, 2)
  Wait(250)
  SetVehicleLights(veh, 0)
  notify('info', locked and 'Fahrzeug abgeschlossen.' or 'Fahrzeug aufgeschlossen.')
  TacoV.UI.send('hud', { vehicle = false }) -- nächster Tick setzt den Tacho neu
end)

function TacoV.Vehicles.openTrunk(veh)
  veh = nearbyVehicle(veh)
  if veh == 0 then return end
  TriggerServerEvent('tacov:vehicles:trunk', NetworkGetNetworkIdFromEntity(veh))
end

function TacoV.Vehicles.openGlovebox()
  local veh = GetVehiclePedIsIn(PlayerPedId(), false)
  if veh == 0 then return end
  TriggerServerEvent('tacov:vehicles:glovebox', NetworkGetNetworkIdFromEntity(veh))
end

-- Kofferraumklappe auf, solange das Inventar offen ist
RegisterNetEvent('tacov:vehicles:trunkDoor', function(netId)
  local veh = NetworkGetEntityFromNetworkId(netId)
  if veh == 0 or not DoesEntityExist(veh) then return end
  SetVehicleDoorOpen(veh, 5, false, false)
  CreateThread(function()
    Wait(500)
    while TacoV.UI.current() == 'inventory' and DoesEntityExist(veh) do Wait(250) end
    if DoesEntityExist(veh) then SetVehicleDoorShut(veh, 5, false) end
  end)
end)

local function trunkAllowed(veh)
  return TacoV.Vehicles.hasKey(veh) or GetVehicleDoorLockStatus(veh) < 2
end

function TacoV.Vehicles.toggleEngine()
  local ped = PlayerPedId()
  local veh = GetVehiclePedIsIn(ped, false)
  if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then return end
  local on = Entity(veh).state.engine == true
  if not on and TacoV.Vehicles.fuelOf(veh) <= 0.05 then return notify('error', 'Der Tank ist leer.') end
  if NetworkHasControlOfEntity(veh) then Entity(veh).state:set('engine', not on, true) end
  SetVehicleEngineOn(veh, not on, false, true)
  notify('info', on and 'Motor aus.' or 'Motor an.')
end

TacoV.Interact.register({
  id = 'veh_unlock', label = 'Aufschließen', icon = 'key', order = 40,
  when = function(ctx) return ctx.vehicle and TacoV.Vehicles.hasKey(ctx.vehicle) and GetVehicleDoorLockStatus(ctx.vehicle) >= 2 end,
  run = function(ctx) TacoV.Vehicles.toggleLock(ctx.vehicle) end,
})
TacoV.Interact.register({
  id = 'veh_lock', label = 'Abschließen', icon = 'lock', order = 40,
  when = function(ctx) return ctx.vehicle and TacoV.Vehicles.hasKey(ctx.vehicle) and GetVehicleDoorLockStatus(ctx.vehicle) < 2 end,
  run = function(ctx) TacoV.Vehicles.toggleLock(ctx.vehicle) end,
})
TacoV.Interact.register({
  id = 'veh_trunk', label = 'Kofferraum', icon = 'trunk', order = 45,
  when = function(ctx) return ctx.vehicle and not IsPedInAnyVehicle(ctx.ped, false) and trunkAllowed(ctx.vehicle) end,
  run = function(ctx) TacoV.Vehicles.openTrunk(ctx.vehicle) end,
})
TacoV.Interact.register({
  id = 'veh_glove', label = 'Handschuhfach', icon = 'box', order = 45,
  when = function(ctx) return ctx.vehicle and GetVehiclePedIsIn(ctx.ped, false) == ctx.vehicle end,
  run = function() TacoV.Vehicles.openGlovebox() end,
})
TacoV.Interact.register({
  id = 'veh_engine', label = 'Motor an/aus', icon = 'engine', order = 42,
  when = function(ctx) return ctx.vehicle and GetPedInVehicleSeat(ctx.vehicle, -1) == ctx.ped end,
  run = function() TacoV.Vehicles.toggleEngine() end,
})
TacoV.Interact.register({
  id = 'veh_key', label = 'Schlüssel geben', icon = 'gift', order = 48,
  when = function(ctx) return ctx.vehicle and ctx.player and TacoV.Vehicles.hasKey(ctx.vehicle) end,
  run = function(ctx) TriggerServerEvent('tacov:vehicles:giveKey', NetworkGetNetworkIdFromEntity(ctx.vehicle), ctx.player) end,
})

--- Fahrzeugmenü (F6 → Fahrzeug)
function TacoV.Vehicles.openMenu()
  local ped = PlayerPedId()
  local veh = nearbyVehicle()
  if veh == 0 then return notify('info', 'Kein Fahrzeug in der Nähe.') end
  local inside = GetVehiclePedIsIn(ped, false) == veh
  local driver = inside and GetPedInVehicleSeat(veh, -1) == ped
  local key = TacoV.Vehicles.hasKey(veh)
  local locked = GetVehicleDoorLockStatus(veh) >= 2
  local def = TacoV.Vehicles.defOf(veh)
  local items = {
    { id = 'engine', label = (Entity(veh).state.engine == true) and 'Motor aus' or 'Motor an', icon = 'engine', dim = not driver, sub = driver and nil or 'nur als Fahrer' },
    { id = 'lock', label = locked and 'Aufschließen' or 'Abschließen', icon = locked and 'key' or 'lock', dim = not key, sub = key and nil or 'kein Schlüssel' },
    inside and { id = 'glove', label = 'Handschuhfach', icon = 'box' }
      or { id = 'trunk', label = 'Kofferraum', icon = 'trunk', dim = not trunkAllowed(veh), sub = trunkAllowed(veh) and nil or 'abgeschlossen' },
  }
  TacoV.Menu.open({
    id = 'vehicle', title = 'Fahrzeug', icon = 'car',
    info = ('%s · %s'):format(def and def.label or GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(veh))), TacoV.Vehicles.plateOf(veh)),
    items = items,
  }, function(id)
    TacoV.Menu.close()
    if id == 'engine' then TacoV.Vehicles.toggleEngine()
    elseif id == 'lock' then TacoV.Vehicles.toggleLock(veh)
    elseif id == 'trunk' then TacoV.Vehicles.openTrunk(veh)
    elseif id == 'glove' then TacoV.Vehicles.openGlovebox() end
  end)
end

-- ---------------------------------------------------------------- Garage

local function inOwnVehicleNear(kind, dist)
  local ped = PlayerPedId()
  local veh = GetVehiclePedIsIn(ped, false)
  if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then return nil end
  local loc = TacoV.Client.nearestLocation(kind, dist)
  if not loc then return nil end
  return veh, loc
end

TacoV.Prompt.register({
  id = 'garage', label = 'Garage', order = 10,
  when = function()
    if IsPedInAnyVehicle(PlayerPedId(), false) then return false end
    return TacoV.Client.nearestLocation('garage', 4.0) ~= nil or TacoV.Client.nearestLocation('impound', 4.0) ~= nil
  end,
  run = function() TriggerServerEvent('tacov:vehicles:garage:open') end,
})

TacoV.Prompt.register({
  id = 'park', label = 'Fahrzeug einparken', order = 5,
  when = function()
    local veh = inOwnVehicleNear('garage', 12.0)
    return veh ~= nil and TacoV.Vehicles.hasKey(veh)
  end,
  run = function()
    local veh = inOwnVehicleNear('garage', 12.0)
    if not veh then return end
    TriggerServerEvent('tacov:vehicles:park', {
      netId = NetworkGetNetworkIdFromEntity(veh), fuel = TacoV.Vehicles.fuelOf(veh),
      bodyHealth = GetVehicleBodyHealth(veh), engineHealth = GetVehicleEngineHealth(veh), props = propsOf(veh),
    })
  end,
})

RegisterNetEvent('tacov:vehicles:garage:list', function(g)
  if TacoV.UI.current() == 'garage' then
    TacoV.UI.send('open', { view = 'garage', data = g })
  elseif not TacoV.UI.current() then
    TacoV.UI.open('garage', g)
  end
end)

AddEventHandler('tacov:ui:garage:take', function(data)
  local loc = TacoV.Client.nearestLocation('garage', 8.0) or TacoV.Client.nearestLocation('impound', 8.0)
  if loc and data and data.id then TriggerServerEvent('tacov:vehicles:garage:take', loc.name, tonumber(data.id)) end
end)

AddEventHandler('tacov:ui:garage:close', function()
  if TacoV.UI.current() == 'garage' then TacoV.UI.close() end
end)

RegisterNetEvent('tacov:vehicles:garage:close', function()
  if TacoV.UI.current() == 'garage' then TacoV.UI.close() end
end)

-- ---------------------------------------------------------------- Kaufhaus

TacoV.Prompt.register({
  id = 'dealer', label = 'Kaufhaus', order = 10,
  when = function() return not IsPedInAnyVehicle(PlayerPedId(), false) and TacoV.Client.nearestLocation('dealer', 4.0) ~= nil end,
  run = function() TriggerServerEvent('tacov:vehicles:dealer:open') end,
})

-- Vorschau im Showroom: lokales, eingefrorenes Fahrzeug ohne Kollision, dreht sich langsam; die Kamera fährt darauf
local preview, previewCam = nil, nil

local function clearPreview()
  if preview and DoesEntityExist(preview) then DeleteEntity(preview) end
  preview = nil
  if previewCam then
    RenderScriptCams(false, true, 600, true, true)
    DestroyCam(previewCam, false)
    previewCam = nil
  end
end

local function focusCamera(veh, spot)
  local a = math.rad((spot.h or 0.0) + 140.0)
  local dist = 6.5
  local cx, cy, cz = spot.x - math.sin(a) * dist, spot.y + math.cos(a) * dist, spot.z + 1.7
  if not previewCam then
    previewCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(previewCam, cx, cy, cz)
    SetCamFov(previewCam, 45.0)
    PointCamAtEntity(previewCam, veh, 0.0, 0.0, 0.3, true)
    SetCamActive(previewCam, true)
    RenderScriptCams(true, true, 600, true, true)
  else
    PointCamAtEntity(previewCam, veh, 0.0, 0.0, 0.3, true)
  end
end

local function showPreview(model, spot)
  if preview and DoesEntityExist(preview) then DeleteEntity(preview) end
  preview = nil
  if not spot then return end
  local hash = loadModel(model)
  if not hash then return end
  local veh = CreateVehicle(hash, spot.x, spot.y, spot.z, spot.h or 0.0, false, false)
  SetModelAsNoLongerNeeded(hash)
  if not DoesEntityExist(veh) then return end
  preview = veh
  SetVehicleOnGroundProperly(veh)
  SetEntityInvincible(veh, true)
  SetVehicleDoorsLocked(veh, 2)
  SetVehicleNumberPlateText(veh, 'TACOV')
  FreezeEntityPosition(veh, true)
  SetEntityCollision(veh, false, false)
  focusCamera(veh, spot)
  CreateThread(function()
    while preview == veh and DoesEntityExist(veh) do
      Wait(0)
      SetEntityHeading(veh, (GetEntityHeading(veh) + 0.25) % 360.0)
    end
  end)
end

local dealerSpot = nil
RegisterNetEvent('tacov:vehicles:dealer:data', function(d)
  local loc = TacoV.Client.nearestLocation('dealer', 10.0)
  dealerSpot = loc and loc.preview
  if TacoV.UI.current() and TacoV.UI.current() ~= 'dealer' then return end
  TacoV.UI.open('dealer', d)
  -- erstes Modell gleich vorführen
  local first = d.classes[1] and d.classes[1].vehicles[1]
  if first then showPreview(first.model, dealerSpot) end
end)

AddEventHandler('tacov:ui:dealer:preview', function(data)
  if data and data.model then showPreview(tostring(data.model), dealerSpot) end
end)

AddEventHandler('tacov:ui:dealer:buy', function(data)
  local loc = TacoV.Client.nearestLocation('dealer', 10.0)
  if loc and data and data.model then TriggerServerEvent('tacov:vehicles:dealer:buy', loc.name, tostring(data.model), data.method) end
end)

AddEventHandler('tacov:ui:dealer:close', function()
  clearPreview()
  if TacoV.UI.current() == 'dealer' then TacoV.UI.close() end
end)

RegisterNetEvent('tacov:vehicles:dealer:close', function()
  clearPreview()
  if TacoV.UI.current() == 'dealer' then TacoV.UI.close() end
end)

-- ---------------------------------------------------------------- Tanken

local function stationVehicle()
  local loc = TacoV.Client.nearestLocation('fuel', Cfg.fuel.stationRadius)
  if not loc then return nil end
  local veh = nearbyVehicle()
  if veh == 0 then return nil end
  return veh, loc
end

TacoV.Prompt.register({
  id = 'fuel', label = 'Tanken', order = 8,
  when = function() return stationVehicle() ~= nil end,
  run = function()
    local veh = stationVehicle()
    if not veh then return end
    TriggerServerEvent('tacov:vehicles:fuel:open', NetworkGetNetworkIdFromEntity(veh), TacoV.Vehicles.fuelOf(veh), TacoV.Vehicles.tankOf(veh))
  end,
})

RegisterNetEvent('tacov:vehicles:fuel:data', function(f)
  local veh = stationVehicle()
  if not veh then return end
  local netId = NetworkGetNetworkIdFromEntity(veh)
  local full = math.floor(f.free)
  local items = {}
  if full > 0 then items[#items + 1] = { id = tostring(full), label = 'Volltanken', icon = 'fuel', price = fmt(full * f.price), sub = ('%d Liter'):format(full) } end
  for _, l in ipairs(Cfg.fuel.amounts) do
    if l < full then items[#items + 1] = { id = tostring(l), label = ('%d Liter'):format(l), icon = 'fuel', price = fmt(l * f.price) } end
  end
  if #items == 0 then items = { { id = 'none', label = 'Der Tank ist voll', dim = true, icon = 'check' } } end
  TacoV.Menu.open({
    id = 'fuel', title = 'Tanken', icon = 'fuel',
    info = ('%s · %s %.2f $/L · Tank %d/%d L'):format(f.label, Cfg.fuel.kind, f.price, math.floor(f.fuel + 0.5), f.tank),
    note = ('Bargeld %s · Konto %s'):format(fmt(f.cash), fmt(f.bank)), items = items,
  }, function(id)
    local liters = tonumber(id)
    if not liters then return end
    TacoV.Menu.open({
      id = 'fuel_pay', title = ('%d Liter'):format(liters), icon = 'fuel', info = fmt(liters * f.price),
      items = {
        { id = 'card', label = 'Mit Karte zahlen', icon = 'card', dim = f.bank < liters * f.price },
        { id = 'cash', label = 'Bar zahlen', icon = 'cash', dim = f.cash < liters * f.price },
      },
    }, function(method)
      TacoV.Menu.close()
      TriggerServerEvent('tacov:vehicles:fuel:buy', netId, liters, method)
    end)
  end)
end)

RegisterNetEvent('tacov:vehicles:fuel:add', function(netId, liters)
  local veh = NetworkGetEntityFromNetworkId(netId)
  if veh == 0 or not DoesEntityExist(veh) then return end
  NetworkRequestControlOfEntity(veh)
  local t = GetGameTimer()
  while not NetworkHasControlOfEntity(veh) and GetGameTimer() - t < 1000 do Wait(10) end
  setFuel(veh, TacoV.Vehicles.fuelOf(veh) + liters)
end)

--- Tankstellenkarte fürs HUD: nächste Tankstelle in Reichweite
function TacoV.Vehicles.hudStation()
  local loc = TacoV.Client.nearestLocation('fuel', Cfg.fuel.hudRadius)
  if not loc then return false end
  return { name = loc.label, sub = ('%s · %.2f $/l'):format(Cfg.fuel.kind, TacoV.Config.Economy.fuel.pricePerLiter.default),
    price = TacoV.Config.Economy.fuel.pricePerLiter.default }
end
