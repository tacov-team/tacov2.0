-- NPC-Läden (Konzept 3): Kauf mit Bargeld oder Karte, Umsatzsteuer an den Staat, Rest verlässt die Welt.
TacoV = TacoV or {}
TacoV.Shops = {}

local Items = TacoV.Config.Items
local Shops = TacoV.Config.Shops
local STATE = { type = 'state', id = 0 }

local session = {} -- [source] = Ort (locations-Eintrag)

local function catalog(shopType)
  local def = Shops[shopType]
  local list = {}
  for _, e in ipairs(def.items) do
    local it = Items[e.item]
    if it then
      list[#list + 1] = { item = e.item, label = it.label, category = it.category, price = e.price, weight = it.weight or 0 }
    end
  end
  return list
end

local function fail(src, text)
  TriggerClientEvent('tacov:core:notify', src, 'error', text)
end

function TacoV.Shops.send(source)
  local loc = session[source]
  local c = TacoV.Characters.get(source)
  local inv = TacoV.Inventory.ofSource(source)
  if not loc or not c or not inv then return end
  local def = Shops[loc.shop]
  TriggerClientEvent('tacov:shop:data', source, {
    shop = loc.shop, type = def.label, name = loc.label,
    cash = TacoV.Inventory.cash(inv), bank = TacoV.Journal.balance('character', c.id),
    taxPercent = TacoV.Config.Economy.tax.sales.default,
    weight = TacoV.Inventory.weight(inv), maxWeight = TacoV.Inventory.maxWeight(inv),
    items = catalog(loc.shop),
  })
end

RegisterNetEvent('tacov:shop:open', function()
  local src = source
  if not TacoV.Characters.get(src) then return end
  local loc = TacoV.Locations.nearest(src, 'shop', 4.0)
  if not loc or not Shops[loc.shop] then return fail(src, 'Hier ist kein Laden.') end
  session[src] = loc
  TacoV.Shops.send(src)
end)

RegisterNetEvent('tacov:shop:close', function()
  session[source] = nil
end)

-- data = { cart = { { item, amount }, ... }, method = 'cash' | 'card' }
RegisterNetEvent('tacov:shop:buy', function(data)
  local src = source
  local loc = session[src]
  local c = TacoV.Characters.get(src)
  local inv = TacoV.Inventory.ofSource(src)
  if not loc or not c or not inv or type(data) ~= 'table' or type(data.cart) ~= 'table' then return end
  if #(GetEntityCoords(GetPlayerPed(src)) - vector3(loc.x, loc.y, loc.z)) > 5.0 then return fail(src, 'Du bist zu weit weg.') end
  local def = Shops[loc.shop]
  local prices = {}
  for _, e in ipairs(def.items) do prices[e.item] = e.price end

  -- Warenkorb prüfen
  local lines, total, weight = {}, 0, 0
  for _, l in ipairs(data.cart) do
    local amount = math.floor(tonumber(l.amount) or 0)
    local price = prices[l.item]
    if price and amount > 0 and amount <= 100 then
      lines[#lines + 1] = { item = l.item, amount = amount, price = price }
      total = total + price * amount
      weight = weight + (Items[l.item].weight or 0) * amount
    end
  end
  if #lines == 0 then return fail(src, 'Der Warenkorb ist leer.') end
  if TacoV.Inventory.weight(inv) + weight > TacoV.Inventory.maxWeight(inv) + 1e-6 then return fail(src, 'Das passt nicht in deine Taschen.') end

  local me = { type = 'character', id = c.id }
  local method = data.method == 'card' and 'card' or 'cash'
  if method == 'cash' then
    if TacoV.Inventory.cash(inv) < total then return fail(src, 'Nicht genug Bargeld.') end
  else
    if TacoV.Journal.balance('character', c.id) < total then return fail(src, 'Nicht genug Guthaben.') end
  end

  -- Ware einlagern (bei Fehler alles zurück)
  local added = {}
  for _, l in ipairs(lines) do
    local ok, err = TacoV.Inventory.add(inv, l.item, l.amount)
    if not ok then
      for _, a in ipairs(added) do TacoV.Inventory.remove(inv, a.item, a.amount) end
      return fail(src, 'Kauf nicht möglich: ' .. tostring(err))
    end
    added[#added + 1] = l
  end

  -- Bezahlen: Umsatzsteuer an den Staat, der Rest verlässt die Welt (NPC)
  local tax = math.floor(total * TacoV.Config.Economy.tax.sales.default / 100)
  local note = loc.label
  if method == 'cash' then
    TacoV.Inventory.remove(inv, 'cash', total)
    TacoV.Journal.move('cash', me, nil, total, 'einkauf', { actor = c.id, note = note })
    if tax > 0 then TacoV.Journal.move('bank', nil, STATE, tax, 'steuer', { actor = c.id, note = 'Umsatzsteuer ' .. note }) end
  else
    TacoV.Journal.move('bank', me, nil, total - tax, 'einkauf', { actor = c.id, note = note })
    if tax > 0 then TacoV.Journal.move('bank', me, STATE, tax, 'steuer', { actor = c.id, note = 'Umsatzsteuer ' .. note }) end
    TacoV.Accounts.push(src)
  end
  local parts = {}
  for _, l in ipairs(lines) do parts[#parts + 1] = ('%dx %s'):format(l.amount, Items[l.item].label) end
  TacoV.Log.write('money', ('Einkauf %s: %s = %d $ (%s)'):format(note, table.concat(parts, ', '), total, method), { characterId = c.id })
  TriggerClientEvent('tacov:core:notify', src, 'success', ('Gekauft für %d $.'):format(total))
  TacoV.Shops.send(src)
end)

AddEventHandler('tacov:core:characterUnloaded', function(source)
  session[source] = nil
end)
