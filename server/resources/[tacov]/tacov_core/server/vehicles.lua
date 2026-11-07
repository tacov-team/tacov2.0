-- Fahrzeuge (Konzept 3, Abschnitt 4): Besitz, Schlüssel, Garagen, Verwahrhof, Kaufhäuser, Tanken, Kofferraum.
-- Der Server entscheidet: jede Aktion prüft Charakter, Schlüssel, Ort und Geld. Der Client spawnt nur auf Anweisung.
TacoV = TacoV or {}
TacoV.Vehicles = {}

local Cfg = TacoV.Config.Vehicles
local Econ = TacoV.Config.Economy
local STATE = { type = 'state', id = 0 }

local byModel = {}
for _, v in ipairs(Cfg.list) do byModel[v.model] = v end

local keys = {}   -- [characterId] = { [plate] = vehicleId }
local live = {}   -- [plate] = { id = vehicleId, netId = n }
local lastSeen = {} -- [plate] = os.time() der letzten Speicherung

local function fail(src, text) TriggerClientEvent('tacov:core:notify', src, 'error', text) end
local function ok(src, text) TriggerClientEvent('tacov:core:notify', src, 'success', text) end
local function fmt(n)
  local s = tostring(math.floor(n))
  local out = s:reverse():gsub('(%d%d%d)', '%1.'):reverse()
  if out:sub(1, 1) == '.' then out = out:sub(2) end
  return out .. ' $'
end
local function trim(s) return (tostring(s or ''):gsub('^%s+', ''):gsub('%s+$', '')) end
local function classDef(cls) return Cfg.classes[cls] or Cfg.classes.C end
local function garageCategory(cls) return (cls == 'van' or cls == 'truck') and 'rig' or 'car' end
local function levelOf(src)
  local d = TacoV.Characters.publicData(src)
  return d and d.level or 0
end

-- ---------------------------------------------------------------- Schlüssel

local function loadKeys(characterId)
  local map = {}
  local rows = TacoV.DB.query(
    'SELECT v.id, v.plate FROM vehicle_keys k JOIN vehicles v ON v.id = k.vehicle_id ' ..
    'WHERE k.character_id = ? AND v.deleted_at IS NULL', { characterId }) or {}
  for _, r in ipairs(rows) do map[r.plate] = r.id end
  keys[characterId] = map
  return map
end

local function pushKeys(src)
  local c = TacoV.Characters.get(src)
  if not c then return end
  local list = {}
  for plate in pairs(keys[c.id] or {}) do list[#list + 1] = plate end
  TriggerClientEvent('tacov:vehicles:keys', src, list)
end

function TacoV.Vehicles.hasKey(characterId, plate)
  local map = keys[characterId]
  return map ~= nil and map[trim(plate)] ~= nil
end

local function giveKey(vehicleId, characterId, givenBy)
  TacoV.DB.insert('INSERT IGNORE INTO vehicle_keys (vehicle_id, character_id, given_by) VALUES (?, ?, ?)', { vehicleId, characterId, givenBy })
  loadKeys(characterId)
end

-- ---------------------------------------------------------------- Daten

local function vehicleByPlate(plate)
  return TacoV.DB.single('SELECT * FROM vehicles WHERE plate = ? AND deleted_at IS NULL', { trim(plate) })
end

local function vehicleById(id)
  return TacoV.DB.single('SELECT * FROM vehicles WHERE id = ? AND deleted_at IS NULL', { id })
end

local function newPlate()
  for _ = 1, 50 do
    local plate = Cfg.plateFormat:format(math.random(0, 99999))
    if not TacoV.DB.scalar('SELECT id FROM vehicles WHERE plate = ?', { plate }) then return plate end
  end
  return nil
end

--- Entity zur Netz-ID, wenn sie existiert und ein Kennzeichen hat.
local function entityOf(netId)
  local ent = netId and NetworkGetEntityFromNetworkId(tonumber(netId) or 0) or 0
  if ent == 0 or not DoesEntityExist(ent) then return nil end
  return ent, trim(GetVehicleNumberPlateText(ent))
end

--- Ist die Ausfahrt frei? (Server kennt alle Fahrzeuge)
local function spawnFree(spawn)
  local p = vector3(spawn.x, spawn.y, spawn.z)
  for _, veh in ipairs(GetAllVehicles()) do
    if #(GetEntityCoords(veh) - p) < Cfg.spawnClearRadius then return false end
  end
  return true
end

local function near(src, loc, dist)
  return #(GetEntityCoords(GetPlayerPed(src)) - vector3(loc.x, loc.y, loc.z)) <= (dist or 6.0)
end

--- Fahrzeug für den Client zum Spawnen vorbereiten (Besitz bleibt in der DB, Zustand wird beim Melden gesetzt).
local function sendSpawn(src, row, spawn, fuel)
  local cls = classDef(row.class)
  local props = row.props
  if type(props) == 'string' then props = json.decode(props) end
  TriggerClientEvent('tacov:vehicles:spawn', src, {
    id = row.id, model = row.model, plate = row.plate, class = row.class,
    fuel = fuel or row.fuel, tank = cls.tank,
    bodyHealth = row.body_health, engineHealth = row.engine_health, props = props,
    spawn = spawn,
  })
end

-- ---------------------------------------------------------------- Garagen und Verwahrhof

local function garageFee(row)
  if row.state ~= 'garage' or not row.parked_at then return 0 end
  local parked = row.parked_at
  if type(parked) ~= 'number' then
    local y, m, d, h, mi, s = tostring(parked):match('(%d+)%-(%d+)%-(%d+)[T ](%d+):(%d+):(%d+)')
    parked = y and os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = tonumber(h), min = tonumber(mi), sec = tonumber(s) }) or os.time()
  else
    parked = math.floor(parked / 1000)
  end
  local days = math.floor((os.time() - parked) / 86400)
  return math.min(days, Cfg.publicGarageMaxDays) * Cfg.publicGarageDaily
end

local function impoundFee(row)
  if row.state ~= 'impound' then return 0 end
  -- Nach einem Neustart stehen unterwegs gewesene Fahrzeuge im Verwahrhof; war der Halter kürzlich dran, ist das gratis
  local seen = row.last_seen_at
  if type(seen) == 'number' and os.time() - math.floor(seen / 1000) < Cfg.impoundAfterHours * 3600 then return 0 end
  if type(seen) == 'string' then
    local y, m, d, h, mi, s = seen:match('(%d+)%-(%d+)%-(%d+)[T ](%d+):(%d+):(%d+)')
    local t = y and os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = tonumber(h), min = tonumber(mi), sec = tonumber(s) })
    if t and os.time() - t < Cfg.impoundAfterHours * 3600 then return 0 end
  end
  return Cfg.impoundFee
end

local function garageItems(src, loc)
  local c = TacoV.Characters.get(src)
  local rows = TacoV.DB.query(
    'SELECT v.*, (v.owner_type = \'character\' AND v.owner_id = ?) AS own FROM vehicles v ' ..
    'LEFT JOIN vehicle_keys k ON k.vehicle_id = v.id AND k.character_id = ? ' ..
    'WHERE v.deleted_at IS NULL AND (k.character_id IS NOT NULL OR (v.owner_type = \'character\' AND v.owner_id = ?)) ' ..
    'ORDER BY v.bought_at', { c.id, c.id, c.id }) or {}
  local items = {}
  for _, r in ipairs(rows) do
    local def = byModel[r.model]
    local cls = classDef(r.class)
    local label = def and def.label or r.model
    local info = ('%s · %s · Tank %d/%d L · %s km'):format(r.plate, cls.label, math.floor(r.fuel + 0.5), cls.tank,
      tostring(math.floor(r.mileage_km)))
    local item = { id = tostring(r.id), label = label, sub = info, icon = (r.class == 'moto') and 'speed' or 'car' }
    if loc.kind == 'impound' then
      if r.state == 'impound' then
        local fee = impoundFee(r)
        item.price = fee > 0 and ('Auslösung ' .. fmt(fee)) or 'kostenlos'
      else
        item.dim, item.badge = true, (r.state == 'garage' and 'in Garage' or 'unterwegs')
      end
    else
      if r.state == 'garage' and r.garage == loc.name then
        local fee = garageFee(r)
        item.price = fee > 0 and fmt(fee) or nil
      elseif r.state == 'garage' then
        item.dim, item.badge = true, 'andere Garage'
      elseif r.state == 'out' then
        item.dim, item.badge = true, 'unterwegs'
      else
        item.dim, item.badge = true, 'verwahrt'
      end
    end
    if r.own == 0 then item.sub = item.sub .. ' · Schlüssel' end
    items[#items + 1] = item
  end
  return items
end

RegisterNetEvent('tacov:vehicles:garage:open', function()
  local src = source
  if not TacoV.Characters.get(src) then return end
  local loc = TacoV.Locations.nearest(src, 'garage', 6.0) or TacoV.Locations.nearest(src, 'impound', 6.0)
  if not loc then return fail(src, 'Hier ist keine Garage.') end
  TriggerClientEvent('tacov:vehicles:garage:list', src, {
    name = loc.name, label = loc.label, kind = loc.kind, items = garageItems(src, loc),
  })
end)

RegisterNetEvent('tacov:vehicles:garage:take', function(garageName, vehicleId)
  local src = source
  local c = TacoV.Characters.get(src)
  if not c then return end
  local loc = TacoV.Locations.get(tostring(garageName))
  if not loc or (loc.kind ~= 'garage' and loc.kind ~= 'impound') or not near(src, loc, 8.0) then return fail(src, 'Du bist zu weit weg.') end
  local row = vehicleById(tonumber(vehicleId) or 0)
  if not row then return fail(src, 'Fahrzeug nicht gefunden.') end
  local own = row.owner_type == 'character' and row.owner_id == c.id
  if not own and not TacoV.Vehicles.hasKey(c.id, row.plate) then return fail(src, 'Dafür hast du keinen Schlüssel.') end
  local fee
  if loc.kind == 'impound' then
    if row.state ~= 'impound' then return fail(src, 'Das Fahrzeug steht nicht im Verwahrhof.') end
    fee = impoundFee(row)
  else
    if row.state ~= 'garage' or row.garage ~= loc.name then return fail(src, 'Das Fahrzeug steht nicht hier.') end
    if garageCategory(row.class) ~= (loc.category or 'car') then return fail(src, 'Diese Garage ist nicht für dieses Fahrzeug.') end
    fee = garageFee(row)
  end
  if live[row.plate] and entityOf(live[row.plate].netId) then return fail(src, 'Das Fahrzeug ist schon draußen.') end
  if not loc.spawn or not spawnFree(loc.spawn) then return fail(src, 'Die Ausfahrt ist belegt.') end
  if fee > 0 then
    local paid = TacoV.Accounts.pay(src, STATE, fee, loc.kind == 'impound' and 'verwahrung' or 'garage', loc.label)
    if not paid then return fail(src, ('Nicht genug Guthaben (%s).'):format(fmt(fee))) end
  end
  sendSpawn(src, row, loc.spawn)
  TriggerClientEvent('tacov:vehicles:garage:close', src)
end)

-- Client hat gespawnt: Fahrzeug ist jetzt unterwegs
RegisterNetEvent('tacov:vehicles:spawned', function(vehicleId, netId)
  local src = source
  local c = TacoV.Characters.get(src)
  local row = c and vehicleById(tonumber(vehicleId) or 0)
  if not row then return end
  local ent, plate = entityOf(netId)
  if not ent or plate ~= row.plate then return end
  live[row.plate] = { id = row.id, netId = tonumber(netId) }
  TacoV.DB.update('UPDATE vehicles SET state = \'out\', garage = NULL, last_seen_at = NOW() WHERE id = ?', { row.id })
end)

-- Fahrzeug einparken: Client meldet Netz-ID und Zustand
RegisterNetEvent('tacov:vehicles:park', function(data)
  local src = source
  local c = TacoV.Characters.get(src)
  if not c or type(data) ~= 'table' then return end
  local ent, plate = entityOf(data.netId)
  if not ent then return fail(src, 'Fahrzeug nicht gefunden.') end
  local row = vehicleByPlate(plate)
  if not row then return fail(src, 'Dieses Fahrzeug gehört niemandem – es kann nicht eingeparkt werden.') end
  local own = row.owner_type == 'character' and row.owner_id == c.id
  if not own and not TacoV.Vehicles.hasKey(c.id, plate) then return fail(src, 'Dafür hast du keinen Schlüssel.') end
  local loc = TacoV.Locations.nearest(src, 'garage', 14.0)
  if not loc then return fail(src, 'Hier ist keine Garage.') end
  if garageCategory(row.class) ~= (loc.category or 'car') then return fail(src, 'Diese Garage ist nicht für dieses Fahrzeug.') end
  if #(GetEntityCoords(ent) - vector3(loc.x, loc.y, loc.z)) > 16.0 then return fail(src, 'Fahre näher an die Garage.') end
  local fuel = tonumber(data.fuel) or row.fuel
  local body = tonumber(data.bodyHealth) or row.body_health
  local engine = tonumber(data.engineHealth) or row.engine_health
  local props = type(data.props) == 'table' and json.encode(data.props) or nil
  TacoV.DB.update(
    'UPDATE vehicles SET state = \'garage\', garage = ?, fuel = ?, body_health = ?, engine_health = ?, props = COALESCE(?, props), ' ..
    'parked_at = NOW(), last_seen_at = NOW() WHERE id = ?', { loc.name, fuel, body, engine, props, row.id })
  live[plate] = nil
  DeleteEntity(ent)
  ok(src, ('%s eingeparkt: %s.'):format(row.plate, loc.label))
end)

-- Herzschlag des Fahrers (alle 60 s): Tank, Kilometer, Zustand
RegisterNetEvent('tacov:vehicles:seen', function(data)
  local src = source
  if not TacoV.Characters.get(src) or type(data) ~= 'table' then return end
  local ent, plate = entityOf(data.netId)
  if not ent then return end
  local now = os.time()
  if lastSeen[plate] and now - lastSeen[plate] < 30 then return end
  lastSeen[plate] = now
  local row = vehicleByPlate(plate)
  if not row then return end
  live[plate] = { id = row.id, netId = tonumber(data.netId) }
  TacoV.DB.update(
    'UPDATE vehicles SET state = \'out\', garage = NULL, fuel = ?, mileage_km = mileage_km + ?, body_health = ?, engine_health = ?, last_seen_at = NOW() WHERE id = ?',
    { tonumber(data.fuel) or row.fuel, math.max(0, tonumber(data.kmDelta) or 0), tonumber(data.bodyHealth) or row.body_health,
      tonumber(data.engineHealth) or row.engine_health, row.id })
end)

-- Verwahrung: unterwegs ohne Lebenszeichen seit 24 h (und nicht mehr in der Welt)
CreateThread(function()
  while true do
    Wait(600000)
    local rows = TacoV.DB.query(
      ('SELECT id, plate FROM vehicles WHERE state = \'out\' AND deleted_at IS NULL AND (last_seen_at IS NULL OR last_seen_at < NOW() - INTERVAL %d HOUR)')
        :format(math.floor(Cfg.impoundAfterHours))) or {}
    for _, r in ipairs(rows) do
      local l = live[r.plate]
      if not (l and entityOf(l.netId)) then
        TacoV.DB.update('UPDATE vehicles SET state = \'impound\', garage = NULL WHERE id = ?', { r.id })
        TacoV.Log.write('money', ('Fahrzeug %s verwahrt (24 h nicht geparkt)'):format(r.plate))
      end
    end
  end
end)

-- Nach einem Neustart sind alle unterwegs gewesenen Fahrzeuge weg: sie stehen im Verwahrhof (Auslösung gratis, wenn kürzlich gefahren)
AddEventHandler('tacov:core:ready', function()
  TacoV.DB.update('UPDATE vehicles SET state = \'impound\', garage = NULL WHERE state = \'out\'')
end)

-- ---------------------------------------------------------------- Schloss, Schlüssel, Kofferraum

RegisterNetEvent('tacov:vehicles:lock', function(netId, wantLocked)
  local src = source
  local c = TacoV.Characters.get(src)
  if not c then return end
  local ent, plate = entityOf(netId)
  if not ent then return end
  if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(ent)) > 8.0 then return end
  local row = vehicleByPlate(plate)
  if not row then return fail(src, 'Dieses Fahrzeug hat kein Schloss, das du bedienen kannst.') end
  if not (row.owner_type == 'character' and row.owner_id == c.id) and not TacoV.Vehicles.hasKey(c.id, plate) then
    return fail(src, 'Dafür hast du keinen Schlüssel.')
  end
  TriggerClientEvent('tacov:vehicles:lockResult', src, tonumber(netId), wantLocked and true or false)
end)

RegisterNetEvent('tacov:vehicles:giveKey', function(netId, target)
  local src = source
  local c = TacoV.Characters.get(src)
  target = tonumber(target)
  local tc = target and TacoV.Characters.get(target)
  if not c or not tc or target == src then return fail(src, 'Niemand in der Nähe.') end
  if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(target))) > 3.0 then return fail(src, 'Niemand in der Nähe.') end
  local ent, plate = entityOf(netId)
  if not ent then return end
  local row = vehicleByPlate(plate)
  if not row then return fail(src, 'Dieses Fahrzeug gehört niemandem.') end
  if not (row.owner_type == 'character' and row.owner_id == c.id) and not TacoV.Vehicles.hasKey(c.id, plate) then
    return fail(src, 'Dafür hast du keinen Schlüssel.')
  end
  giveKey(row.id, tc.id, c.id)
  pushKeys(target)
  TacoV.Log.write('items', ('Schlüssel %s an #%d gegeben'):format(plate, tc.id), { characterId = c.id })
  ok(src, ('Schlüssel für %s übergeben.'):format(plate))
  TriggerClientEvent('tacov:core:notify', target, 'info', ('Du hast einen Schlüssel für %s erhalten.'):format(plate))
end)

RegisterNetEvent('tacov:vehicles:trunk', function(netId)
  local src = source
  local c = TacoV.Characters.get(src)
  if not c then return end
  local ent, plate = entityOf(netId)
  if not ent then return end
  if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(ent)) > 6.0 then return fail(src, 'Du bist zu weit weg.') end
  local row = vehicleByPlate(plate)
  if not row then return fail(src, 'Der Kofferraum fremder Fahrzeuge geht nicht auf.') end
  if not (row.owner_type == 'character' and row.owner_id == c.id) and not TacoV.Vehicles.hasKey(c.id, plate) then
    return fail(src, 'Dafür hast du keinen Schlüssel.')
  end
  local cls = classDef(row.class)
  local inv = TacoV.Inventory.load('vehicle', row.id, cls.trunk)
  local def = byModel[row.model]
  TacoV.Inventory.openContainer(src, inv, {
    title = 'Kofferraum', subtitle = ('%s · %s · %d kg'):format(def and def.label or row.model, row.plate, cls.trunk),
    check = function(s)
      local e = entityOf(netId)
      return e ~= nil and #(GetEntityCoords(GetPlayerPed(s)) - GetEntityCoords(e)) <= 8.0
    end,
  })
end)

-- ---------------------------------------------------------------- Kaufhaus

local function catalog(dealerKey, level)
  local dealer = Cfg.dealers[dealerKey]
  local classes = {}
  for _, cls in ipairs(dealer.classes) do
    local d = Cfg.classes[cls]
    local list = {}
    for _, v in ipairs(Cfg.list) do
      if v.class == cls then list[#list + 1] = { model = v.model, label = v.label, price = v.price } end
    end
    classes[#classes + 1] = {
      id = cls, label = d.label, level = d.level, license = d.license, trunk = d.trunk, tank = d.tank,
      locked = level < d.level, vehicles = list,
    }
  end
  return classes
end

RegisterNetEvent('tacov:vehicles:dealer:open', function()
  local src = source
  local c = TacoV.Characters.get(src)
  if not c then return end
  local loc = TacoV.Locations.nearest(src, 'dealer', 6.0)
  if not loc or not Cfg.dealers[loc.dealer] then return fail(src, 'Hier ist kein Kaufhaus.') end
  local inv = TacoV.Inventory.ofSource(src)
  TriggerClientEvent('tacov:vehicles:dealer:data', src, {
    name = loc.name, label = loc.label, dealer = loc.dealer, title = Cfg.dealers[loc.dealer].label,
    level = levelOf(src), fee = Cfg.registrationFee,
    cash = inv and TacoV.Inventory.cash(inv) or 0, bank = TacoV.Journal.balance('character', c.id),
    classes = catalog(loc.dealer, levelOf(src)),
  })
end)

RegisterNetEvent('tacov:vehicles:dealer:buy', function(dealerName, model, method)
  local src = source
  local c = TacoV.Characters.get(src)
  if not c then return end
  local loc = TacoV.Locations.get(tostring(dealerName))
  if not loc or loc.kind ~= 'dealer' or not near(src, loc, 8.0) then return fail(src, 'Du bist zu weit weg.') end
  local def = byModel[tostring(model)]
  local dealer = Cfg.dealers[loc.dealer]
  if not def or not dealer then return fail(src, 'Dieses Fahrzeug gibt es hier nicht.') end
  local sold = false
  for _, cls in ipairs(dealer.classes) do if cls == def.class then sold = true end end
  if not sold then return fail(src, 'Dieses Fahrzeug gibt es hier nicht.') end
  local cls = classDef(def.class)
  if levelOf(src) < cls.level then return fail(src, ('Dafür brauchst du Level %d.'):format(cls.level)) end
  if not loc.spawn or not spawnFree(loc.spawn) then return fail(src, 'Die Ausfahrt ist belegt – bitte warte kurz.') end
  local total = def.price + Cfg.registrationFee
  local me = { type = 'character', id = c.id }
  local inv = TacoV.Inventory.ofSource(src)
  method = method == 'cash' and 'cash' or 'card'
  if method == 'cash' then
    if not inv or TacoV.Inventory.cash(inv) < total then return fail(src, ('Nicht genug Bargeld (%s).'):format(fmt(total))) end
  elseif TacoV.Journal.balance('character', c.id) < total then
    return fail(src, ('Nicht genug Guthaben (%s).'):format(fmt(total)))
  end
  local plate = newPlate()
  if not plate then return fail(src, 'Kein freies Kennzeichen – bitte das Team informieren.') end

  if method == 'cash' then
    TacoV.Inventory.remove(inv, 'cash', total)
    TacoV.Journal.move('cash', me, nil, total, 'fahrzeugkauf', { actor = c.id, note = def.label })
    TacoV.Journal.move('bank', nil, STATE, Cfg.registrationFee, 'zulassung', { actor = c.id, note = plate })
  else
    TacoV.Journal.move('bank', me, nil, def.price, 'fahrzeugkauf', { actor = c.id, note = def.label })
    TacoV.Journal.move('bank', me, STATE, Cfg.registrationFee, 'zulassung', { actor = c.id, note = plate })
    TacoV.Accounts.push(src)
  end
  local id = TacoV.DB.insert(
    'INSERT INTO vehicles (plate, model, class, owner_type, owner_id, state, fuel, bought_price, last_seen_at) VALUES (?, ?, ?, \'character\', ?, \'out\', ?, ?, NOW())',
    { plate, def.model, def.class, c.id, cls.tank, def.price })
  giveKey(id, c.id, nil)
  pushKeys(src)
  TacoV.Log.write('money', ('Fahrzeugkauf %s (%s) für %s + Zulassung %s (%s)'):format(def.label, plate, fmt(def.price), fmt(Cfg.registrationFee), method),
    { characterId = c.id })
  ok(src, ('%s gekauft – Kennzeichen %s. Es steht an der Ausfahrt.'):format(def.label, plate))
  local row = vehicleById(id)
  sendSpawn(src, row, loc.spawn, cls.tank)
  TriggerClientEvent('tacov:vehicles:dealer:close', src)
end)

-- ---------------------------------------------------------------- Tanken

local function fuelPrice()
  return Econ.fuel.pricePerLiter.default
end

RegisterNetEvent('tacov:vehicles:fuel:open', function(netId, liters, tank)
  local src = source
  if not TacoV.Characters.get(src) then return end
  local loc = TacoV.Locations.nearest(src, 'fuel', Cfg.fuel.stationRadius)
  if not loc then return fail(src, 'Hier ist keine Tankstelle.') end
  local ent = entityOf(netId)
  if not ent or #(GetEntityCoords(ent) - vector3(loc.x, loc.y, loc.z)) > Cfg.fuel.stationRadius + 4.0 then return fail(src, 'Stell das Fahrzeug an die Zapfsäule.') end
  liters, tank = tonumber(liters) or 0, tonumber(tank) or 65
  local free = math.max(0, tank - liters)
  local inv = TacoV.Inventory.ofSource(src)
  local c = TacoV.Characters.get(src)
  TriggerClientEvent('tacov:vehicles:fuel:data', src, {
    station = loc.name, label = loc.label, price = fuelPrice(), free = free, tank = tank, fuel = liters,
    cash = inv and TacoV.Inventory.cash(inv) or 0, bank = TacoV.Journal.balance('character', c.id),
  })
end)

RegisterNetEvent('tacov:vehicles:fuel:buy', function(netId, liters, method)
  local src = source
  local c = TacoV.Characters.get(src)
  if not c then return end
  local loc = TacoV.Locations.nearest(src, 'fuel', Cfg.fuel.stationRadius)
  if not loc then return fail(src, 'Hier ist keine Tankstelle.') end
  local ent = entityOf(netId)
  if not ent then return end
  liters = math.floor(tonumber(liters) or 0)
  if liters <= 0 or liters > 400 then return end
  local total = TacoV.Util.money(liters * fuelPrice())
  if total <= 0 then return end
  local me = { type = 'character', id = c.id }
  local inv = TacoV.Inventory.ofSource(src)
  local tax = math.floor(total * Econ.tax.sales.default / 100)
  method = method == 'cash' and 'cash' or 'card'
  if method == 'cash' then
    if not inv or TacoV.Inventory.cash(inv) < total then return fail(src, ('Nicht genug Bargeld (%s).'):format(fmt(total))) end
    TacoV.Inventory.remove(inv, 'cash', total)
    TacoV.Journal.move('cash', me, nil, total, 'kraftstoff', { actor = c.id, note = loc.label })
    if tax > 0 then TacoV.Journal.move('bank', nil, STATE, tax, 'steuer', { actor = c.id, note = 'Umsatzsteuer ' .. loc.label }) end
  else
    if TacoV.Journal.balance('character', c.id) < total then return fail(src, ('Nicht genug Guthaben (%s).'):format(fmt(total))) end
    TacoV.Journal.move('bank', me, nil, total - tax, 'kraftstoff', { actor = c.id, note = loc.label })
    if tax > 0 then TacoV.Journal.move('bank', me, STATE, tax, 'steuer', { actor = c.id, note = 'Umsatzsteuer ' .. loc.label }) end
    TacoV.Accounts.push(src)
  end
  TacoV.Log.write('money', ('Getankt %d L für %s (%s)'):format(liters, fmt(total), method), { characterId = c.id })
  TriggerClientEvent('tacov:vehicles:fuel:add', src, tonumber(netId), liters)
  ok(src, ('%d Liter getankt für %s.'):format(liters, fmt(total)))
end)

-- ---------------------------------------------------------------- Lebenszyklus

AddEventHandler('tacov:core:characterSelected', function(source, characterId)
  loadKeys(characterId)
  pushKeys(source)
end)

AddEventHandler('tacov:core:characterUnloaded', function(_, characterId)
  keys[characterId] = nil
end)
