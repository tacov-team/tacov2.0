-- Inventar (Konzept 5): Raster, Gewicht als einzige Grenze, Bargeld/Schwarzgeld als Items, Ablagen am Boden.
-- Jede Änderung wird sofort in die DB geschrieben (Platz für Platz), damit bei einem Absturz nichts verloren geht.
TacoV = TacoV or {}
TacoV.Inventory = {}

local Items = TacoV.Config.Items
local Cfg = TacoV.Config.Inventory
local cache = {}        -- [ownerKey] = inv
local drops = {}        -- [dropId] = { id, pos, inv, expires, creator, entity }
local nextDrop = 1

local function key(ownerType, ownerId) return ownerType .. ':' .. ownerId end

local function itemDef(name)
  return Items[name]
end

local function stackMax(def)
  if def.stack == 0 then return math.huge end
  return def.stack or Cfg.stackMax
end

-- ---------------------------------------------------------------- Laden / Speichern

function TacoV.Inventory.load(ownerType, ownerId, maxWeight)
  local k = key(ownerType, ownerId)
  if cache[k] then return cache[k] end
  local inv = { ownerType = ownerType, ownerId = ownerId, key = k, items = {}, maxWeight = maxWeight or Cfg.baseWeight }
  local rows = TacoV.DB.query('SELECT slot, item, amount, meta FROM inventory_items WHERE owner_type = ? AND owner_id = ?', { ownerType, ownerId }) or {}
  for _, r in ipairs(rows) do
    if Items[r.item] then
      inv.items[r.slot] = { item = r.item, amount = r.amount, meta = r.meta and json.decode(r.meta) or nil }
    end
  end
  cache[k] = inv
  return inv
end

function TacoV.Inventory.unload(ownerType, ownerId)
  cache[key(ownerType, ownerId)] = nil
end

local function persist(inv, slot)
  if inv.volatile then return end
  local e = inv.items[slot]
  if e then
    TacoV.DB.query(
      'INSERT INTO inventory_items (owner_type, owner_id, slot, item, amount, meta) VALUES (?, ?, ?, ?, ?, ?) ' ..
      'ON DUPLICATE KEY UPDATE item = VALUES(item), amount = VALUES(amount), meta = VALUES(meta)',
      { inv.ownerType, inv.ownerId, slot, e.item, e.amount, e.meta and json.encode(e.meta) or nil }
    )
  else
    TacoV.DB.update('DELETE FROM inventory_items WHERE owner_type = ? AND owner_id = ? AND slot = ?', { inv.ownerType, inv.ownerId, slot })
  end
end

-- ---------------------------------------------------------------- Abfragen

function TacoV.Inventory.weight(inv)
  local w = 0
  for _, e in pairs(inv.items) do
    w = w + (Items[e.item].weight or 0) * e.amount
  end
  return w
end

function TacoV.Inventory.maxWeight(inv)
  if inv.ownerType == 'character' then
    for _, e in pairs(inv.items) do
      if Items[e.item].backpack then return Cfg.backpackWeight end
    end
    return Cfg.baseWeight
  end
  return inv.maxWeight
end

function TacoV.Inventory.count(inv, item)
  local n = 0
  for _, e in pairs(inv.items) do
    if e.item == item then n = n + e.amount end
  end
  return n
end

function TacoV.Inventory.has(inv, item, amount)
  return TacoV.Inventory.count(inv, item) >= (amount or 1)
end

local function freeSlot(inv)
  local s = 1
  while inv.items[s] do s = s + 1 end
  return s
end

local function sameMeta(a, b)
  if a == nil and b == nil then return true end
  if a == nil or b == nil then return false end
  return json.encode(a) == json.encode(b)
end

-- ---------------------------------------------------------------- Ändern

--- Fügt Items hinzu; stapelt auf vorhandene Plätze. Gibt ok, Fehler ('weight', 'item', 'amount').
function TacoV.Inventory.add(inv, item, amount, meta)
  local def = itemDef(item)
  if not def then return false, 'item' end
  amount = math.floor(tonumber(amount) or 0)
  if amount <= 0 then return false, 'amount' end
  if (def.weight or 0) * amount + TacoV.Inventory.weight(inv) > TacoV.Inventory.maxWeight(inv) + 1e-6 then
    return false, 'weight'
  end
  local max = stackMax(def)
  local left = amount
  local changed = {}
  if not def.unique then
    for slot, e in pairs(inv.items) do
      if left <= 0 then break end
      if e.item == item and sameMeta(e.meta, meta) and e.amount < max then
        local take = math.min(max - e.amount, left)
        e.amount = e.amount + take
        left = left - take
        changed[#changed + 1] = slot
      end
    end
  end
  while left > 0 do
    local take = math.min(max, left)
    local slot = freeSlot(inv)
    inv.items[slot] = { item = item, amount = take, meta = meta }
    left = left - take
    changed[#changed + 1] = slot
  end
  for _, s in ipairs(changed) do persist(inv, s) end
  TacoV.Inventory.changed(inv)
  return true
end

--- Entfernt Items beliebiger Plätze. Gibt ok, Fehler ('missing').
function TacoV.Inventory.remove(inv, item, amount)
  amount = math.floor(tonumber(amount) or 0)
  if amount <= 0 then return false, 'amount' end
  if not TacoV.Inventory.has(inv, item, amount) then return false, 'missing' end
  local left = amount
  local slots = {}
  for s in pairs(inv.items) do slots[#slots + 1] = s end
  table.sort(slots)
  for _, s in ipairs(slots) do
    if left <= 0 then break end
    local e = inv.items[s]
    if e.item == item then
      local take = math.min(e.amount, left)
      e.amount = e.amount - take
      left = left - take
      if e.amount <= 0 then inv.items[s] = nil end
      persist(inv, s)
    end
  end
  TacoV.Inventory.changed(inv)
  return true
end

--- Entfernt eine Menge aus einem Platz. Gibt das entfernte Item { item, amount, meta } oder nil.
function TacoV.Inventory.takeSlot(inv, slot, amount)
  local e = inv.items[slot]
  if not e then return nil end
  amount = math.floor(tonumber(amount) or e.amount)
  if amount <= 0 or amount > e.amount then return nil end
  local out = { item = e.item, amount = amount, meta = e.meta }
  e.amount = e.amount - amount
  if e.amount <= 0 then inv.items[slot] = nil end
  persist(inv, slot)
  TacoV.Inventory.changed(inv)
  return out
end

--- Legt ein Item auf einen bestimmten Platz (stapelt, wenn gleich; tauscht, wenn anders belegt). Prüft Gewicht.
function TacoV.Inventory.put(inv, slot, pack, fromInv, fromSlot)
  local def = itemDef(pack.item)
  if not def then return false, 'item' end
  if inv ~= fromInv and (def.weight or 0) * pack.amount + TacoV.Inventory.weight(inv) > TacoV.Inventory.maxWeight(inv) + 1e-6 then
    return false, 'weight'
  end
  local target = inv.items[slot]
  if target and target.item == pack.item and sameMeta(target.meta, pack.meta) and not def.unique then
    if target.amount + pack.amount > stackMax(def) then return false, 'stack' end
    target.amount = target.amount + pack.amount
  elseif target then
    -- Tausch: Zielinhalt wandert auf den Ursprungsplatz
    if not fromInv or not fromSlot or fromInv.items[fromSlot] then return false, 'occupied' end
    local tdef = Items[target.item]
    if fromInv ~= inv and (tdef.weight or 0) * target.amount + TacoV.Inventory.weight(fromInv) > TacoV.Inventory.maxWeight(fromInv) + 1e-6 then
      return false, 'weight'
    end
    fromInv.items[fromSlot] = target
    inv.items[slot] = { item = pack.item, amount = pack.amount, meta = pack.meta }
    persist(fromInv, fromSlot)
    TacoV.Inventory.changed(fromInv)
  else
    inv.items[slot] = { item = pack.item, amount = pack.amount, meta = pack.meta }
  end
  persist(inv, slot)
  TacoV.Inventory.changed(inv)
  return true
end

--- Verschiebt eine Menge von Platz zu Platz, auch zwischen zwei Inventaren. Bei Fehler bleibt alles, wie es war.
function TacoV.Inventory.move(fromInv, fromSlot, toInv, toSlot, amount)
  if fromInv == toInv and fromSlot == toSlot then return true end
  local src = fromInv.items[fromSlot]
  if not src then return false, 'missing' end
  amount = math.floor(tonumber(amount) or src.amount)
  if amount <= 0 or amount > src.amount then return false, 'amount' end
  local pack = TacoV.Inventory.takeSlot(fromInv, fromSlot, amount)
  if not pack then return false, 'missing' end
  local ok, err = TacoV.Inventory.put(toInv, toSlot, pack, fromInv, fromSlot)
  if not ok then
    -- zurücklegen
    local back = fromInv.items[fromSlot]
    if back and back.item == pack.item then back.amount = back.amount + pack.amount
    else fromInv.items[fromSlot] = pack end
    persist(fromInv, fromSlot)
    TacoV.Inventory.changed(fromInv)
    return false, err
  end
  return true
end

-- ---------------------------------------------------------------- Charakter-Helfer

function TacoV.Inventory.ofSource(source)
  local c = TacoV.Characters.get(source)
  if not c then return nil end
  return TacoV.Inventory.load('character', c.id)
end

function TacoV.Inventory.cash(inv) return TacoV.Inventory.count(inv, 'cash') end
function TacoV.Inventory.black(inv) return TacoV.Inventory.count(inv, 'black_cash') end

--- Bargeld geben/nehmen – immer mit Journal-Eintrag.
function TacoV.Inventory.addCash(source, amount, reason, kind)
  kind = kind or 'cash'
  local inv = TacoV.Inventory.ofSource(source)
  if not inv then return false, 'character' end
  local c = TacoV.Characters.get(source)
  local ok, err = TacoV.Inventory.add(inv, kind == 'black' and 'black_cash' or 'cash', amount)
  if not ok then return false, err end
  TacoV.Journal.move(kind, nil, { type = 'character', id = c.id }, amount, reason, { actor = c.id })
  return true
end

function TacoV.Inventory.removeCash(source, amount, reason, kind)
  kind = kind or 'cash'
  local inv = TacoV.Inventory.ofSource(source)
  if not inv then return false, 'character' end
  local c = TacoV.Characters.get(source)
  local ok, err = TacoV.Inventory.remove(inv, kind == 'black' and 'black_cash' or 'cash', amount)
  if not ok then return false, err end
  TacoV.Journal.move(kind, { type = 'character', id = c.id }, nil, amount, reason, { actor = c.id })
  return true
end

-- ---------------------------------------------------------------- Sync zum Client

local function sourceOf(inv)
  if inv.ownerType ~= 'character' then return nil end
  for src, p in pairs(TacoV.Players.all()) do
    if p.characterId == inv.ownerId then return src end
  end
  return nil
end

function TacoV.Inventory.view(inv, extra)
  local items = {}
  for slot, e in pairs(inv.items) do
    local def = Items[e.item]
    items[#items + 1] = {
      slot = slot, item = e.item, amount = e.amount, meta = e.meta,
      label = def.label, category = def.category, weight = def.weight or 0,
      usable = def.use ~= nil, money = def.money or false,
    }
  end
  local v = {
    kind = inv.ownerType, id = inv.ownerId, items = items,
    weight = TacoV.Inventory.weight(inv), maxWeight = TacoV.Inventory.maxWeight(inv),
  }
  if extra then for k, val in pairs(extra) do v[k] = val end end
  return v
end

-- Wer gerade welches Inventar offen hat: [source] = { other = inv | nil }
local open = {}

local function dropView(d)
  local minutes = math.max(1, math.ceil((d.expires - os.time()) / 60))
  return TacoV.Inventory.view(d.inv, { title = 'Boden', subtitle = ('Ablage verfällt in %d Minuten'):format(minutes), dropId = d.id })
end

--- Gegenüber-Inventar der offenen Ansicht: Ablage am Boden oder ein Behälter (Kofferraum, Lager ...).
--- Gibt Inventar und Ansicht zurück, oder nil. Behälter prüfen über o.check(source), ob der Zugriff noch gilt.
local function otherOf(source)
  local o = open[source]
  if not o then return nil end
  if o.drop then
    local d = drops[o.drop]
    if not d then open[source] = nil return nil end
    if #(GetEntityCoords(GetPlayerPed(source)) - d.pos) > 3.0 then return nil end
    return d.inv, dropView(d), d
  end
  if o.container then
    if o.check and not o.check(source) then open[source] = nil return nil end
    return o.container, TacoV.Inventory.view(o.container, { title = o.title, subtitle = o.subtitle })
  end
  return nil
end

--- Öffnet das eigene Inventar zusammen mit einem Behälter (z. B. Kofferraum). opts = { title, subtitle, check }
function TacoV.Inventory.openContainer(source, container, opts)
  opts = opts or {}
  open[source] = { container = container, title = opts.title or 'Behälter', subtitle = opts.subtitle, check = opts.check }
  TacoV.Inventory.send(source)
end

function TacoV.Inventory.send(source)
  local c = TacoV.Characters.get(source)
  local inv = TacoV.Inventory.ofSource(source)
  if not c or not inv then return end
  local _, other = otherOf(source)
  TriggerClientEvent('tacov:inventory:data', source, {
    self = TacoV.Inventory.view(inv, {
      title = 'Taschen', name = c.first_name .. ' ' .. c.last_name,
      cash = TacoV.Inventory.cash(inv), black = TacoV.Inventory.black(inv),
    }),
    other = other,
    ground = GetVehiclePedIsIn(GetPlayerPed(source), false) == 0, -- Boden nur außerhalb eines Fahrzeugs (08.11.2026)
  })
end

--- Nach jeder Änderung: HUD-Werte an den Besitzer, offene Ansichten aktualisieren.
function TacoV.Inventory.changed(inv)
  if inv.ownerType == 'character' then
    local src = sourceOf(inv)
    if src then
      TriggerClientEvent('tacov:inventory:money', src, {
        cash = TacoV.Inventory.cash(inv), black = TacoV.Inventory.black(inv),
        weight = TacoV.Inventory.weight(inv), maxWeight = TacoV.Inventory.maxWeight(inv),
      })
      if open[src] then TacoV.Inventory.send(src) end
    end
  elseif inv.ownerType == 'drop' then
    for src, o in pairs(open) do
      if o.drop == inv.ownerId then TacoV.Inventory.send(src) end
    end
  else
    for src, o in pairs(open) do
      if o.container == inv then TacoV.Inventory.send(src) end
    end
  end
end

-- ---------------------------------------------------------------- Ablagen am Boden

local DROP_MODEL = GetHashKey('prop_paper_bag_small')

local function dropsList()
  local list = {}
  for id, d in pairs(drops) do list[#list + 1] = { id = id, x = d.pos.x, y = d.pos.y, z = d.pos.z } end
  return list
end

local function broadcastDrops()
  TriggerClientEvent('tacov:inventory:drops', -1, dropsList())
end

local function createDrop(source, pos)
  local c = TacoV.Characters.get(source)
  local mine = 0
  for _, d in pairs(drops) do if d.creator == c.id then mine = mine + 1 end end
  if mine >= Cfg.dropMaxPerPlayer then return nil, 'dropMax' end
  local id = nextDrop
  nextDrop = nextDrop + 1
  local inv = { ownerType = 'drop', ownerId = id, key = key('drop', id), items = {}, maxWeight = 100.0, volatile = true }
  local entity = CreateObjectNoOffset(DROP_MODEL, pos.x, pos.y, pos.z - 0.98, true, true, false)
  drops[id] = { id = id, pos = pos, inv = inv, expires = os.time() + Cfg.dropLifetimeMinutes * 60, creator = c.id, entity = entity }
  broadcastDrops()
  return drops[id]
end

local function removeDrop(id)
  local d = drops[id]
  if not d then return end
  if d.entity and DoesEntityExist(d.entity) then DeleteEntity(d.entity) end
  drops[id] = nil
  for src, o in pairs(open) do
    if o.drop == id then open[src] = nil; TacoV.Inventory.send(src) end
  end
  broadcastDrops()
end

local function nearestDrop(source, maxDist)
  local pos = GetEntityCoords(GetPlayerPed(source))
  local best, bestD = nil, maxDist or 2.5
  for _, d in pairs(drops) do
    local dist = #(pos - d.pos)
    if dist < bestD then best, bestD = d, dist end
  end
  return best
end

-- Verfallene oder leere Ablagen entfernen
CreateThread(function()
  while true do
    Wait(30000)
    local now = os.time()
    for id, d in pairs(drops) do
      if d.expires <= now or next(d.inv.items) == nil then removeDrop(id) end
    end
  end
end)

-- ---------------------------------------------------------------- Benutzen

local function useSlot(source, slot)
  local inv = TacoV.Inventory.ofSource(source)
  local e = inv and inv.items[slot]
  if not e then return false, 'missing' end
  local def = Items[e.item]
  if not def.use then return false, 'notUsable' end
  if type(def.use) == 'table' then
    for k, v in pairs(def.use) do TacoV.Needs.add(source, k, v) end
    TacoV.Inventory.takeSlot(inv, slot, 1)
    TriggerEvent('tacov:newbie:step', source, 'eat')
    TriggerClientEvent('tacov:inventory:used', source, e.item)
    TacoV.Log.write('items', ('Benutzt: %s'):format(def.label), { characterId = inv.ownerId })
    return true
  end
  -- Ereignis für andere Module (und den Kern selbst, z. B. Ausweis)
  TriggerEvent('tacov:item:' .. e.item, source, slot, e.meta)
  return true
end

-- ---------------------------------------------------------------- Events

RegisterNetEvent('tacov:inventory:open', function()
  local src = source
  if not TacoV.Characters.get(src) then return end
  local d = nearestDrop(src)
  open[src] = { drop = d and d.id or nil }
  TacoV.Inventory.send(src)
end)

RegisterNetEvent('tacov:inventory:close', function()
  open[source] = nil
end)

-- data = { action = 'use'|'give'|'drop'|'take'|'move', slot, amount, to, from = 'self'|'other', dest = 'self'|'other' }
RegisterNetEvent('tacov:inventory:action', function(data)
  local src = source
  if type(data) ~= 'table' then return end
  local c = TacoV.Characters.get(src)
  local inv = TacoV.Inventory.ofSource(src)
  if not c or not inv then return end
  local slot = tonumber(data.slot)
  local amount = tonumber(data.amount)
  local function fail(err)
    local text = ({
      weight = 'Zu schwer.', missing = 'Das hast du nicht.', notUsable = 'Das kannst du nicht benutzen.',
      noTarget = 'Niemand in der Nähe.', dropMax = 'Du hast schon zu viele Ablagen.', stack = 'Der Platz ist voll.',
      occupied = 'Der Platz ist belegt.', vehicle = 'Im Fahrzeug kannst du nichts ablegen.',
    })[err] or ('Fehler: ' .. tostring(err))
    TriggerClientEvent('tacov:core:notify', src, 'error', text)
  end

  if data.action == 'use' and slot then
    local ok, err = useSlot(src, slot)
    if not ok then fail(err) end

  elseif data.action == 'give' and slot and amount then
    local target = tonumber(data.target)
    if not target or target == src or not TacoV.Characters.get(target) then return fail('noTarget') end
    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(target))) > 3.0 then return fail('noTarget') end
    local tinv = TacoV.Inventory.ofSource(target)
    local e = inv.items[slot]
    if not e then return fail('missing') end
    local pack = TacoV.Inventory.takeSlot(inv, slot, amount)
    if not pack then return fail('amount') end
    local ok, err = TacoV.Inventory.add(tinv, pack.item, pack.amount, pack.meta)
    if not ok then TacoV.Inventory.add(inv, pack.item, pack.amount, pack.meta); return fail(err) end
    local def = Items[pack.item]
    if def.money then
      local kind = pack.item == 'black_cash' and 'black' or 'cash'
      local tc = TacoV.Characters.get(target)
      TacoV.Journal.move(kind, { type = 'character', id = c.id }, { type = 'character', id = tc.id }, pack.amount, 'uebergabe', { actor = c.id })
    end
    TacoV.Log.write('items', ('Gegeben: %dx %s an #%d'):format(pack.amount, def.label, TacoV.Characters.get(target).id), { characterId = c.id })
    TriggerClientEvent('tacov:core:notify', target, 'info', ('Du hast %dx %s erhalten.'):format(pack.amount, def.label))
    TriggerClientEvent('tacov:core:notify', src, 'success', ('%dx %s übergeben.'):format(pack.amount, def.label))

  elseif data.action == 'drop' and slot and amount then
    if GetVehiclePedIsIn(GetPlayerPed(src), false) ~= 0 then return fail('vehicle') end
    local d = nearestDrop(src)
    if not d then
      local err
      d, err = createDrop(src, GetEntityCoords(GetPlayerPed(src)))
      if not d then return fail(err) end
    end
    local pack = TacoV.Inventory.takeSlot(inv, slot, amount)
    if not pack then return fail('amount') end
    local ok, err = TacoV.Inventory.add(d.inv, pack.item, pack.amount, pack.meta)
    if not ok then TacoV.Inventory.add(inv, pack.item, pack.amount, pack.meta); return fail(err) end
    open[src] = { drop = d.id }
    if Items[pack.item].money then
      local kind = pack.item == 'black_cash' and 'black' or 'cash'
      TacoV.Journal.move(kind, { type = 'character', id = c.id }, { type = 'drop', id = d.id }, pack.amount, 'abgelegt', { actor = c.id })
    end
    TacoV.Log.write('items', ('Abgelegt: %dx %s'):format(pack.amount, Items[pack.item].label), { characterId = c.id })
    TacoV.Inventory.send(src)

  elseif data.action == 'take' and slot and amount then
    local oinv, _, d = otherOf(src)
    if not oinv then return fail('missing') end
    local pack = TacoV.Inventory.takeSlot(oinv, slot, amount)
    if not pack then return fail('amount') end
    local ok, err = TacoV.Inventory.add(inv, pack.item, pack.amount, pack.meta)
    if not ok then TacoV.Inventory.add(oinv, pack.item, pack.amount, pack.meta); return fail(err) end
    if Items[pack.item].money then
      local kind = pack.item == 'black_cash' and 'black' or 'cash'
      TacoV.Journal.move(kind, { type = oinv.ownerType, id = oinv.ownerId }, { type = 'character', id = c.id }, pack.amount, 'aufgehoben', { actor = c.id })
    end
    TacoV.Log.write('items', ('Aufgehoben: %dx %s'):format(pack.amount, Items[pack.item].label), { characterId = c.id })
    if d and next(d.inv.items) == nil then removeDrop(d.id) else TacoV.Inventory.send(src) end

  elseif data.action == 'move' and slot and tonumber(data.to) then
    local oinv, _, d = otherOf(src)
    local fromInv = data.from == 'other' and oinv or inv
    local toInv = data.dest == 'other' and oinv or inv
    if not fromInv or not toInv then return fail('missing') end
    local moving = fromInv.items[slot]
    local movingItem, movingAmount = moving and moving.item, moving and math.floor(tonumber(amount) or moving.amount)
    local ok, err = TacoV.Inventory.move(fromInv, slot, toInv, tonumber(data.to), amount)
    if not ok then return fail(err) end
    if fromInv ~= toInv and movingItem and Items[movingItem].money then
      local kind = movingItem == 'black_cash' and 'black' or 'cash'
      TacoV.Journal.move(kind, { type = fromInv.ownerType, id = fromInv.ownerId }, { type = toInv.ownerType, id = toInv.ownerId },
        movingAmount, 'umgelagert', { actor = c.id })
    end
    if d and next(d.inv.items) == nil then removeDrop(d.id) end
  end
end)

-- Item nach Name benutzen (z. B. aus dem Interaktionsrad)
RegisterNetEvent('tacov:inventory:useItem', function(item)
  local src = source
  local inv = TacoV.Inventory.ofSource(src)
  if not inv then return end
  for slot, e in pairs(inv.items) do
    if e.item == item then
      local ok, err = useSlot(src, slot)
      if not ok then TriggerClientEvent('tacov:core:notify', src, 'error', 'Das kannst du nicht benutzen: ' .. tostring(err)) end
      return
    end
  end
  TriggerClientEvent('tacov:core:notify', src, 'error', ('Du hast kein %s.'):format(Items[item] and Items[item].label or item))
end)

-- Ausweis zeigen (Startitem): Name und Geburtsdatum an den nächsten Spieler
AddEventHandler('tacov:item:id_card', function(source)
  local c = TacoV.Characters.get(source)
  local target = TacoV.Players.nearest(source, 3.0)
  if not target then return TriggerClientEvent('tacov:core:notify', source, 'error', 'Niemand in der Nähe.') end
  if Player(source).state.masked then
    TriggerClientEvent('tacov:core:notify', target, 'info', 'Ausweis: Die Person ist maskiert – Gesicht und Ausweis passen nicht zuzuordnen.')
  else
    TriggerClientEvent('tacov:core:notify', target, 'info', ('Ausweis: %s %s, geboren %s'):format(c.first_name, c.last_name, tostring(c.birth_date)))
  end
  TriggerClientEvent('tacov:core:notify', source, 'success', 'Ausweis gezeigt.')
end)

AddEventHandler('tacov:item:city_map', function(source)
  TriggerClientEvent('tacov:core:notify', source, 'info', 'Der Stadtplan markiert später Orte auf der Karte.')
end)

-- Charakter geladen: Inventar laden, Ablagen schicken; Verbindung getrennt: Cache leeren
AddEventHandler('tacov:core:characterSelected', function(source, characterId)
  local inv = TacoV.Inventory.load('character', characterId)
  TriggerClientEvent('tacov:inventory:money', source, {
    cash = TacoV.Inventory.cash(inv), black = TacoV.Inventory.black(inv),
    weight = TacoV.Inventory.weight(inv), maxWeight = TacoV.Inventory.maxWeight(inv),
  })
  TriggerClientEvent('tacov:inventory:drops', source, dropsList())
end)

AddEventHandler('tacov:core:characterUnloaded', function(source, characterId)
  open[source] = nil
  TacoV.Inventory.unload('character', characterId)
end)

exports('inventoryAdd', function(source, item, amount, meta)
  local inv = TacoV.Inventory.ofSource(source)
  if not inv then return false, 'character' end
  return TacoV.Inventory.add(inv, item, amount, meta)
end)
exports('inventoryRemove', function(source, item, amount)
  local inv = TacoV.Inventory.ofSource(source)
  if not inv then return false, 'character' end
  return TacoV.Inventory.remove(inv, item, amount)
end)
exports('inventoryCount', function(source, item)
  local inv = TacoV.Inventory.ofSource(source)
  return inv and TacoV.Inventory.count(inv, item) or 0
end)
exports('cashAdd', TacoV.Inventory.addCash)
exports('cashRemove', TacoV.Inventory.removeCash)
