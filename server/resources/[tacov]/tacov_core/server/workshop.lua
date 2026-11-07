-- NPC-Werkstatt (Punkt 4.11): Reparatur, Upgrades, Lack, Fensterfarbe, Felgen. Preise aus dem Kaufpreis; nur eigene
-- (oder mit Schlüssel gefahrene) Fahrzeuge aus der Datenbank. Der Client setzt die Mods nach Freigabe und meldet die Ausstattung.
TacoV = TacoV or {}
TacoV.Workshop = {}

local Cfg = TacoV.Config.Workshop
local STATE = { type = 'state', id = 0 }
local function fail(src, text) TriggerClientEvent('tacov:core:notify', src, 'error', text) end
local function ok(src, text) TriggerClientEvent('tacov:core:notify', src, 'success', text) end
local function trim(s) return (tostring(s or ''):gsub('^%s+', ''):gsub('%s+$', '')) end
local function fmt(n)
  local s = tostring(math.floor(n))
  local out = s:reverse():gsub('(%d%d%d)', '%1.'):reverse()
  if out:sub(1, 1) == '.' then out = out:sub(2) end
  return out .. ' $'
end

local function vehicleFor(src, netId)
  local c = TacoV.Characters.get(src)
  if not c then return nil end
  local loc = TacoV.Locations.nearest(src, 'workshop', 14.0)
  if not loc then return nil, 'Hier ist keine Werkstatt.' end
  local ent = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
  if ent == 0 or not DoesEntityExist(ent) then return nil, 'Fahrzeug nicht gefunden.' end
  if GetVehiclePedIsIn(GetPlayerPed(src), false) ~= ent then return nil, 'Du musst im Fahrzeug sitzen.' end
  local plate = trim(GetVehicleNumberPlateText(ent))
  local row = TacoV.DB.single('SELECT * FROM vehicles WHERE plate = ? AND deleted_at IS NULL', { plate })
  if not row then return nil, 'Die Werkstatt arbeitet nur an zugelassenen Fahrzeugen mit Halter.' end
  local own = row.owner_type == 'character' and row.owner_id == c.id
  if not own and not TacoV.Vehicles.hasKey(c.id, plate) then return nil, 'Dafür hast du keinen Schlüssel.' end
  return { c = c, loc = loc, ent = ent, row = row, plate = plate }
end

local function upgradePrice(row, up, level)
  return math.max(100, math.floor((row.bought_price or 0) * (up.pct[level] or 0) / 100))
end

local function pay(src, amount, method, reason, note)
  local c = TacoV.Characters.get(src)
  if method == 'cash' then
    local inv = TacoV.Inventory.ofSource(src)
    if not inv or TacoV.Inventory.cash(inv) < amount then return false end
    TacoV.Inventory.remove(inv, 'cash', amount)
    TacoV.Journal.move('cash', { type = 'character', id = c.id }, nil, amount, reason, { actor = c.id, note = note })
    return true
  end
  return TacoV.Accounts.pay(src, STATE, amount, reason, note)
end

RegisterNetEvent('tacov:workshop:open', function(netId, health)
  local src = source
  local v, err = vehicleFor(src, netId)
  if not v then return err and fail(src, err) end
  local body = tonumber(type(health) == 'table' and health.body) or 1000
  local engine = tonumber(type(health) == 'table' and health.engine) or 1000
  local damage = math.max(0, (1000 - math.min(body, engine)) / 1000)
  local repair = damage > 0.01 and math.max(Cfg.repairMin, math.floor((v.row.bought_price or 0) * Cfg.repairPercent / 100 * damage)) or 0
  local ups = {}
  for _, up in ipairs(Cfg.upgrades) do
    local prices = {}
    for i = 1, #up.levels do prices[i] = upgradePrice(v.row, up, i) end
    ups[#ups + 1] = { id = up.id, label = up.label, icon = up.icon, levels = up.levels, prices = prices, toggle = up.toggle ~= nil }
  end
  local inv = TacoV.Inventory.ofSource(src)
  TriggerClientEvent('tacov:workshop:data', src, {
    label = v.loc.label, plate = v.plate, model = v.row.model, repair = repair, damagePercent = math.floor(damage * 100 + 0.5),
    upgrades = ups, paint = Cfg.paintPrice, tint = Cfg.tintPrice, wheels = Cfg.wheelsPrice,
    colors = Cfg.colors, tints = Cfg.tints, wheelTypes = Cfg.wheelTypes, wheelsPerType = Cfg.wheelsPerType,
    cash = inv and TacoV.Inventory.cash(inv) or 0, bank = TacoV.Journal.balance('character', v.c.id),
  })
end)

-- data = { netId, kind = repair|upgrade|paint|tint|wheels, id, level, value, method, props }
RegisterNetEvent('tacov:workshop:apply', function(data)
  local src = source
  if type(data) ~= 'table' then return end
  local v, err = vehicleFor(src, data.netId)
  if not v then return err and fail(src, err) end
  local method = data.method == 'cash' and 'cash' or 'card'
  local price, label, action
  if data.kind == 'repair' then
    local body = tonumber(data.body) or 1000
    local engine = tonumber(data.engine) or 1000
    local damage = math.max(0, (1000 - math.min(body, engine)) / 1000)
    if damage <= 0.01 then return fail(src, 'Das Fahrzeug ist in Ordnung.') end
    price = math.max(Cfg.repairMin, math.floor((v.row.bought_price or 0) * Cfg.repairPercent / 100 * damage))
    label, action = 'Reparatur', { kind = 'repair' }
  elseif data.kind == 'upgrade' then
    local up
    for _, u in ipairs(Cfg.upgrades) do if u.id == data.id then up = u end end
    local level = math.floor(tonumber(data.level) or 0)
    if not up or level < 1 or level > #up.levels then return end
    price = upgradePrice(v.row, up, level)
    label = up.label .. ' ' .. up.levels[level]
    action = { kind = 'upgrade', modType = up.modType, toggle = up.toggle, index = up.toggle and true or (level - 1) }
  elseif data.kind == 'paint' then
    local idx = math.floor(tonumber(data.value) or -1)
    local valid = false
    for _, col in ipairs(Cfg.colors) do if col.id == idx then valid = true; label = 'Lackierung ' .. col.label end end
    if not valid then return end
    price, action = Cfg.paintPrice, { kind = 'paint', value = idx, slot = data.slot == 2 and 2 or 1 }
  elseif data.kind == 'tint' then
    local idx = math.floor(tonumber(data.value) or -1)
    local valid = false
    for _, t in ipairs(Cfg.tints) do if t.id == idx then valid = true; label = 'Fensterfarbe ' .. t.label end end
    if not valid then return end
    price, action = Cfg.tintPrice, { kind = 'tint', value = idx }
  elseif data.kind == 'wheels' then
    local wtype = math.floor(tonumber(data.wheelType) or -1)
    local idx = math.floor(tonumber(data.value) or -1)
    local valid = false
    for _, t in ipairs(Cfg.wheelTypes) do if t.id == wtype then valid = true end end
    if not valid or idx < 0 or idx >= Cfg.wheelsPerType then return end
    price, label, action = Cfg.wheelsPrice, 'Felgen', { kind = 'wheels', wheelType = wtype, value = idx }
  else
    return
  end
  if price > 0 and not pay(src, price, method, 'werkstatt', label .. ' ' .. v.plate) then
    return fail(src, ('Nicht genug %s (%s).'):format(method == 'cash' and 'Bargeld' or 'Guthaben', fmt(price)))
  end
  TacoV.Log.write('money', ('Werkstatt %s: %s für %s'):format(v.plate, label, fmt(price)), { characterId = v.c.id })
  TriggerClientEvent('tacov:workshop:do', src, tonumber(data.netId), action)
  ok(src, ('%s – %s.'):format(label, price > 0 and fmt(price) or 'kostenlos'))
end)

-- Client meldet die Ausstattung nach dem Umbau; wird am Fahrzeug gespeichert
RegisterNetEvent('tacov:workshop:props', function(netId, props)
  local src = source
  local v = vehicleFor(src, netId)
  if not v or type(props) ~= 'table' then return end
  TacoV.DB.update('UPDATE vehicles SET props = ? WHERE id = ?', { json.encode(props), v.row.id })
end)
