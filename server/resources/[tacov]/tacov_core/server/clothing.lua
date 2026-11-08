-- Kleiderladen und Outfits (6.2), Friseur und Chirurg (6.3), Server: Preis aus geänderten Kategorien, Bezahlung, Speichern.
TacoV = TacoV or {}
TacoV.Clothing = TacoV.Clothing or {}

local Cfg = TacoV.Config.Clothing
local STATE = { type = 'state', id = 0 }
local function fail(src, text) TriggerClientEvent('tacov:core:notify', src, 'error', text) end
local function ok(src, text) TriggerClientEvent('tacov:core:notify', src, 'success', text) end
local function fmt(n)
  local out = tostring(math.floor(n or 0)):reverse():gsub('(%d%d%d)', '%1.'):reverse()
  if out:sub(1, 1) == '.' then out = out:sub(2) end
  return out .. ' $'
end
local function pay(src, amount, method, reason)
  if amount <= 0 then return true end
  local c = TacoV.Characters.get(src)
  if method == 'cash' then
    local inv = TacoV.Inventory.ofSource(src)
    if not inv or TacoV.Inventory.cash(inv) < amount then return false end
    TacoV.Inventory.remove(inv, 'cash', amount)
    TacoV.Journal.move('cash', { type = 'character', id = c.id }, nil, amount, reason, { actor = c.id })
    return true
  end
  return TacoV.Accounts.pay(src, STATE, amount, reason)
end

-- kind = 'clothing' | 'barber' | 'surgeon'; appearance = neues Aussehen aus dem Editor
RegisterNetEvent('tacov:clothing:apply', function(kind, appearance, method)
  local src = source
  local c = TacoV.Characters.get(src)
  if not c or type(appearance) ~= 'table' then return end
  local loc = TacoV.Locations.nearest(src, kind, 8.0)
  if not loc then return fail(src, 'Hier gibt es das nicht.') end
  local old = c.appearance or {}
  local new = TacoV.Characters.cleanAppearance(appearance, c.gender)
  local price, label
  if kind == 'clothing' then
    -- nur Kleidung übernehmen, Rest bleibt
    local merged = {}
    for k, v in pairs(old) do merged[k] = v end
    merged.components, merged.props = new.components, new.props
    new = merged
    price, label = TacoV.Clothing.price(old, new), 'Kleidung'
  elseif kind == 'barber' then
    local merged = {}
    for k, v in pairs(old) do merged[k] = v end
    merged.hair = new.hair
    merged.overlays = merged.overlays or {}
    for id in pairs(Cfg.barber) do if id ~= 'hair' then merged.overlays[id] = new.overlays[id] end end
    new = merged
    price, label = TacoV.Clothing.barberPrice(old, new), 'Friseur'
  elseif kind == 'surgeon' then
    local last = c.surgery_at and tostring(c.surgery_at) or nil
    if last then
      local days = TacoV.DB.scalar('SELECT DATEDIFF(NOW(), surgery_at) FROM characters WHERE id = ?', { c.id }) or 999
      if days < Cfg.surgeonDays then return fail(src, ('Der Chirurg behandelt dich erst wieder in %d Tagen.'):format(Cfg.surgeonDays - days)) end
    end
    new.model = old.model or new.model -- Geschlecht bleibt
    new.components, new.props = old.components or {}, old.props or {}
    price, label = Cfg.surgeonPrice, 'Schönheitschirurg'
  else
    return
  end
  if not pay(src, price, method == 'cash' and 'cash' or 'card', kind) then
    return fail(src, ('Nicht genug %s (%s).'):format(method == 'cash' and 'Bargeld' or 'Guthaben', fmt(price)))
  end
  TacoV.Characters.setAppearance(src, new)
  if kind == 'clothing' and price > 0 then TriggerEvent('tacov:newbie:step', src, 'clothes') end
  if kind == 'surgeon' then TacoV.DB.update('UPDATE characters SET surgery_at = NOW() WHERE id = ?', { c.id }) c.surgery_at = os.date('%Y-%m-%d') end
  if price > 0 then TacoV.Log.write('money', ('%s: %s'):format(label, fmt(price)), { characterId = c.id }) end
  TriggerClientEvent('tacov:clothing:applied', src, c.appearance)
  ok(src, ('%s – %s.'):format(label, price > 0 and fmt(price) or 'kostenlos'))
end)

-- Outfits
local function listOutfits(cid)
  return TacoV.DB.query('SELECT id, name, components, props FROM outfits WHERE character_id = ? ORDER BY id', { cid }) or {}
end

RegisterNetEvent('tacov:outfits:list', function()
  local src = source
  local c = TacoV.Characters.get(src)
  if not c then return end
  local rows = listOutfits(c.id)
  local out = {}
  for _, r in ipairs(rows) do out[#out + 1] = { id = r.id, name = r.name } end
  TriggerClientEvent('tacov:outfits:list', src, out, Cfg.maxOutfits)
end)

RegisterNetEvent('tacov:outfits:save', function(name, components, props)
  local src = source
  local c = TacoV.Characters.get(src)
  if not c or type(components) ~= 'table' then return end
  if #listOutfits(c.id) >= Cfg.maxOutfits then return fail(src, ('Höchstens %d Outfits.'):format(Cfg.maxOutfits)) end
  local clean = TacoV.Characters.cleanAppearance({ components = components, props = props }, c.gender)
  TacoV.DB.insert('INSERT INTO outfits (character_id, name, components, props) VALUES (?, ?, ?, ?)',
    { c.id, TacoV.Util.cleanText(name or 'Outfit', 32), json.encode(clean.components), json.encode(clean.props) })
  ok(src, 'Outfit gespeichert.')
end)

RegisterNetEvent('tacov:outfits:wear', function(id)
  local src = source
  local c = TacoV.Characters.get(src)
  local row = c and TacoV.DB.single('SELECT * FROM outfits WHERE id = ? AND character_id = ?', { tonumber(id) or 0, c.id })
  if not row then return end
  local a = {}
  for k, v in pairs(c.appearance or {}) do a[k] = v end
  a.components, a.props = json.decode(row.components) or {}, json.decode(row.props) or {}
  TacoV.Characters.setAppearance(src, a)
  TriggerClientEvent('tacov:clothing:applied', src, c.appearance)
end)

RegisterNetEvent('tacov:outfits:delete', function(id)
  local src = source
  local c = TacoV.Characters.get(src)
  if not c then return end
  TacoV.DB.update('DELETE FROM outfits WHERE id = ? AND character_id = ?', { tonumber(id) or 0, c.id })
  ok(src, 'Outfit gelöscht.')
end)

RegisterNetEvent('tacov:outfits:rename', function(id, name)
  local src = source
  local c = TacoV.Characters.get(src)
  if not c then return end
  TacoV.DB.update('UPDATE outfits SET name = ? WHERE id = ? AND character_id = ?', { TacoV.Util.cleanText(name or 'Outfit', 32), tonumber(id) or 0, c.id })
end)
