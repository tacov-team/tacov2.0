-- Handy (Phase 7, Server): Nummern, Kontakte, Anrufe (SaltyChat), Nachrichten, Bank-App, Fahrzeuge-App, Funk.
-- Nutzbar nur mit Handy in der eigenen Tasche; Flugmodus und Beschlagnahme sperren Erreichbarkeit.
TacoV = TacoV or {}
TacoV.Phone = {}

local P = TacoV.Config.Phone
local calls = {}        -- [src] = { with = src2, state = 'incoming'|'outgoing'|'active', started = os.time(), id = dbId }
local airplane = {}     -- [src] = true
local radio = {}        -- [src] = channel

local function notify(src, kind, text) TriggerClientEvent('tacov:core:notify', src, kind, text) end
local function fmtDate(ts) return ts and tostring(ts):sub(6, 16):gsub('-', '.'):gsub(' ', ' · ') or '' end
local function fmt(n)
  local out = tostring(math.floor(n or 0)):reverse():gsub('(%d%d%d)', '%1.'):reverse()
  if out:sub(1, 1) == '.' then out = out:sub(2) end
  return out .. ' $'
end

--- Vierstellige, freie Nummer vergeben
function TacoV.Phone.assignNumber(characterId)
  for _ = 1, 50 do
    local n = tostring(math.random(P.numberMin, P.numberMax))
    if not TacoV.DB.scalar('SELECT id FROM characters WHERE phone_number = ?', { n }) then
      TacoV.DB.update('UPDATE characters SET phone_number = ? WHERE id = ?', { n, characterId })
      return n
    end
  end
  return nil
end

function TacoV.Phone.numberOf(src)
  local c = TacoV.Characters.get(src)
  if not c then return nil end
  if not c.phone_number then c.phone_number = TacoV.Phone.assignNumber(c.id) end
  return c.phone_number
end

local function srcOfNumber(number)
  for src, p in pairs(TacoV.Players.all()) do
    local c = p.characterId and TacoV.Characters.get(src)
    if c and c.phone_number == number then return src, c end
  end
  return nil
end

local function hasPhone(src)
  local inv = TacoV.Inventory.ofSource(src)
  return inv and TacoV.Inventory.has(inv, P.item, 1)
end
local function reachable(src)
  return src and hasPhone(src) and not airplane[src] and not Player(src).state.downed
end
local function nameFor(src, number)
  local c = TacoV.Characters.get(src)
  local row = c and TacoV.DB.single('SELECT name FROM phone_contacts WHERE character_id = ? AND number = ? LIMIT 1', { c.id, number })
  return row and row.name or nil
end

local function appsFor(src)
  local list = {}
  local c = TacoV.Characters.get(src)
  local unread = c and (TacoV.DB.scalar('SELECT COUNT(*) FROM phone_messages WHERE to_number = ? AND read_at IS NULL', { c.phone_number }) or 0) or 0
  for _, a in ipairs(P.apps) do
    local e = { id = a.id, label = a.label, icon = a.icon, enabled = a.enabled }
    if a.id == 'radio' then e.enabled = true end
    list[#list + 1] = e
  end
  return list, unread
end

-- Öffnen
RegisterNetEvent('tacov:phone:open', function()
  local src = source
  local c = TacoV.Characters.get(src)
  if not c then return end
  if not hasPhone(src) then notify(src, 'error', 'Du hast kein Handy dabei.') return end
  local number = TacoV.Phone.numberOf(src)
  local apps, unread = appsFor(src)
  local w = TacoV.World and TacoV.World.get and TacoV.World.get() or { hour = 12, minute = 0 }
  TriggerClientEvent('tacov:phone:show', src, { number = number, apps = apps, unread = unread, time = ('%02d:%02d'):format(w.hour, w.minute) })
  -- laufender Anruf: Zustand erneut senden (Handy wurde evtl. beim Klingeln geöffnet)
  local call = calls[src]
  if call then
    local otherNumber = TacoV.Phone.numberOf(call.with)
    TriggerClientEvent('tacov:phone:app', src, 'call', { with = otherNumber, name = nameFor(src, otherNumber), state = call.state })
  end
end)

-- ---------------------------------------------------------------- Kontakte

local function sendContacts(src)
  local c = TacoV.Characters.get(src)
  local rows = c and TacoV.DB.query('SELECT id, name, number, favorite FROM phone_contacts WHERE character_id = ? ORDER BY favorite DESC, name', { c.id }) or {}
  for _, r in ipairs(rows) do r.favorite = r.favorite == 1 end
  TriggerClientEvent('tacov:phone:app', src, 'contacts', rows)
end
RegisterNetEvent('tacov:phone:contacts:list', function() sendContacts(source) end)
RegisterNetEvent('tacov:phone:contacts:add', function(d)
  local src = source
  local c = TacoV.Characters.get(src)
  if not c or type(d) ~= 'table' then return end
  local number = tostring(d.number or ''):match('^%d%d%d%d$')
  if not number then return end
  TacoV.DB.insert('INSERT INTO phone_contacts (character_id, name, number) VALUES (?, ?, ?)', { c.id, TacoV.Util.cleanText(d.name or number, 32), number })
  sendContacts(src)
end)
RegisterNetEvent('tacov:phone:contacts:rename', function(d)
  local src = source
  local c = TacoV.Characters.get(src)
  if c and type(d) == 'table' then
    TacoV.DB.update('UPDATE phone_contacts SET name = ? WHERE id = ? AND character_id = ?', { TacoV.Util.cleanText(d.name or '', 32), tonumber(d.id) or 0, c.id })
    sendContacts(src)
  end
end)
RegisterNetEvent('tacov:phone:contacts:favorite', function(d)
  local src = source
  local c = TacoV.Characters.get(src)
  if c and type(d) == 'table' then
    TacoV.DB.update('UPDATE phone_contacts SET favorite = ? WHERE id = ? AND character_id = ?', { d.favorite and 1 or 0, tonumber(d.id) or 0, c.id })
    sendContacts(src)
  end
end)
RegisterNetEvent('tacov:phone:contacts:delete', function(d)
  local src = source
  local c = TacoV.Characters.get(src)
  if c and type(d) == 'table' then TacoV.DB.update('DELETE FROM phone_contacts WHERE id = ? AND character_id = ?', { tonumber(d.id) or 0, c.id }) sendContacts(src) end
end)

-- Nummerntausch über das X-Rad: beide bekommen den anderen als Kontakt
RegisterNetEvent('tacov:phone:exchange', function(target)
  local src = source
  target = tonumber(target)
  local c, t = TacoV.Characters.get(src), target and TacoV.Characters.get(target)
  if not c or not t or target == src then return end
  if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(target))) > 3.0 then return end
  if not hasPhone(src) or not hasPhone(target) then notify(src, 'error', 'Beide brauchen ein Handy.') return end
  local n1, n2 = TacoV.Phone.numberOf(src), TacoV.Phone.numberOf(target)
  local function add(cid, name, number)
    if not TacoV.DB.scalar('SELECT id FROM phone_contacts WHERE character_id = ? AND number = ?', { cid, number }) then
      TacoV.DB.insert('INSERT INTO phone_contacts (character_id, name, number) VALUES (?, ?, ?)', { cid, name, number })
    end
  end
  add(c.id, t.first_name .. ' ' .. t.last_name, n2)
  add(t.id, c.first_name .. ' ' .. c.last_name, n1)
  notify(src, 'success', ('Nummer getauscht: %s hat jetzt %s.'):format(t.first_name, n1))
  notify(target, 'success', ('Nummer getauscht: %s hat jetzt %s.'):format(c.first_name, n2))
end)

-- ---------------------------------------------------------------- Anrufe (SaltyChat)

local function callState(src, st)
  TriggerClientEvent('tacov:phone:app', src, 'call', st)
end

local function endCall(src, reason)
  local call = calls[src]
  if not call then return end
  local other = call.with
  calls[src], calls[other] = nil, nil
  if call.state == 'active' then
    pcall(function() exports.saltychat:EndCall(src, other) end)
    local secs = os.time() - (call.answeredAt or os.time())
    if call.id then TacoV.DB.update('UPDATE phone_calls SET seconds = ? WHERE id = ?', { secs, call.id }) end
  end
  callState(src, false)
  callState(other, false)
  if reason then notify(other, 'info', reason) end
end

RegisterNetEvent('tacov:phone:calls:start', function(d)
  local src = source
  local c = TacoV.Characters.get(src)
  if not c or type(d) ~= 'table' or not hasPhone(src) then return end
  if calls[src] then notify(src, 'error', 'Du telefonierst bereits.') return end
  local number = tostring(d.number or '')
  local target, tc = srcOfNumber(number)
  local myNumber = TacoV.Phone.numberOf(src)
  local id = TacoV.DB.insert('INSERT INTO phone_calls (from_number, to_number) VALUES (?, ?)', { myNumber, number })
  if not target or not reachable(target) or calls[target] then
    callState(src, { with = number, name = nameFor(src, number), state = 'outgoing' })
    SetTimeout(3000, function() callState(src, false) notify(src, 'info', 'Nicht erreichbar.') end)
    return
  end
  calls[src] = { with = target, state = 'outgoing', id = id }
  calls[target] = { with = src, state = 'incoming', id = id }
  callState(src, { with = number, name = nameFor(src, number) or (tc.first_name .. ' ' .. tc.last_name), state = 'outgoing' })
  callState(target, { with = myNumber, name = nameFor(target, myNumber), state = 'incoming' })
  TriggerClientEvent('tacov:phone:ring', target, true)
  SetTimeout(P.ringSeconds * 1000, function()
    if calls[src] and calls[src].state == 'outgoing' and calls[src].with == target then
      TriggerClientEvent('tacov:phone:ring', target, false)
      endCall(src, 'Verpasster Anruf von ' .. myNumber .. '.')
      notify(src, 'info', 'Keine Antwort.')
    end
  end)
end)

RegisterNetEvent('tacov:phone:calls:accept', function()
  local src = source
  local call = calls[src]
  if not call or call.state ~= 'incoming' then return end
  local other = call.with
  call.state, calls[other].state = 'active', 'active'
  call.answeredAt = os.time(); calls[other].answeredAt = call.answeredAt
  TacoV.DB.update('UPDATE phone_calls SET answered = 1 WHERE id = ?', { call.id })
  TriggerClientEvent('tacov:phone:ring', src, false)
  pcall(function() exports.saltychat:EstablishCall(src, other) end)
  callState(src, { with = TacoV.Phone.numberOf(other), name = nameFor(src, TacoV.Phone.numberOf(other)), state = 'active' })
  callState(other, { with = TacoV.Phone.numberOf(src), name = nameFor(other, TacoV.Phone.numberOf(src)), state = 'active' })
end)

RegisterNetEvent('tacov:phone:calls:end', function()
  local src = source
  local call = calls[src]
  if not call then return end
  TriggerClientEvent('tacov:phone:ring', call.with, false)
  TriggerClientEvent('tacov:phone:ring', src, false)
  endCall(src, call.state == 'incoming' and nil or 'Anruf beendet.')
end)

-- ---------------------------------------------------------------- Nachrichten

local function threads(src)
  local c = TacoV.Characters.get(src)
  if not c then return {} end
  local me = c.phone_number
  local rows = TacoV.DB.query(
    'SELECT m.*, IF(m.from_number = ?, m.to_number, m.from_number) AS other FROM phone_messages m ' ..
    'WHERE m.from_number = ? OR m.to_number = ? ORDER BY m.id DESC LIMIT 200', { me, me, me }) or {}
  local seen, out = {}, {}
  for _, m in ipairs(rows) do
    if not seen[m.other] then
      seen[m.other] = true
      local unread = TacoV.DB.scalar('SELECT COUNT(*) FROM phone_messages WHERE from_number = ? AND to_number = ? AND read_at IS NULL', { m.other, me }) or 0
      out[#out + 1] = { number = m.other, name = nameFor(src, m.other), last = m.location and '📍 Standort' or m.text, at = fmtDate(m.created_at), unread = unread }
    end
  end
  return out
end
RegisterNetEvent('tacov:phone:messages:list', function() local src = source TriggerClientEvent('tacov:phone:app', src, 'messages', threads(src)) end)

local function sendThread(src, other)
  local c = TacoV.Characters.get(src)
  if not c then return end
  local me = c.phone_number
  TacoV.DB.update('UPDATE phone_messages SET read_at = NOW() WHERE from_number = ? AND to_number = ? AND read_at IS NULL', { other, me })
  local rows = TacoV.DB.query('SELECT * FROM phone_messages WHERE (from_number = ? AND to_number = ?) OR (from_number = ? AND to_number = ?) ORDER BY id DESC LIMIT 60',
    { me, other, other, me }) or {}
  local out = {}
  for i = #rows, 1, -1 do
    local m = rows[i]
    out[#out + 1] = { id = m.id, from = m.from_number, text = m.text, at = fmtDate(m.created_at), mine = m.from_number == me, location = m.location and json.decode(m.location) or nil }
  end
  TriggerClientEvent('tacov:phone:app', src, 'thread', out, other)
end
RegisterNetEvent('tacov:phone:messages:thread', function(d) if type(d) == 'table' then sendThread(source, tostring(d.number or '')) end end)

local function deliver(src, toNumber, text, location)
  local c = TacoV.Characters.get(src)
  if not c or not hasPhone(src) then return end
  local me = TacoV.Phone.numberOf(src)
  if not toNumber:match('^%d%d%d%d$') then return end
  TacoV.DB.insert('INSERT INTO phone_messages (from_number, to_number, text, location) VALUES (?, ?, ?, ?)',
    { me, toNumber, TacoV.Util.cleanText(text or '', 300), location and json.encode(location) or nil })
  sendThread(src, toNumber)
  local target = srcOfNumber(toNumber)
  if target and reachable(target) then
    TriggerClientEvent('tacov:phone:sms', target, me, nameFor(target, me), location and 'Standort geteilt' or TacoV.Util.cleanText(text or '', 60))
    sendThread(target, me)
  end
end
RegisterNetEvent('tacov:phone:messages:send', function(d) if type(d) == 'table' then deliver(source, tostring(d.number or ''), d.text) end end)
RegisterNetEvent('tacov:phone:messages:location', function(d)
  local src = source
  if type(d) ~= 'table' then return end
  local p = GetEntityCoords(GetPlayerPed(src))
  deliver(src, tostring(d.number or ''), 'Standort', { x = p.x, y = p.y })
end)

-- ---------------------------------------------------------------- Bank-App

local function sendBank(src)
  local c = TacoV.Characters.get(src)
  if not c then return end
  local rows = TacoV.DB.query(
    'SELECT at, amount, reason, note, (to_type = \'character\' AND to_id = ?) AS incoming FROM journal WHERE kind = \'bank\' AND ' ..
    '((from_type = \'character\' AND from_id = ?) OR (to_type = \'character\' AND to_id = ?)) ORDER BY id DESC LIMIT 30', { c.id, c.id, c.id }) or {}
  local out = {}
  for _, r in ipairs(rows) do out[#out + 1] = { at = fmtDate(r.at), amount = r.amount, reason = r.reason, note = r.note, dir = r.incoming == 1 and 'in' or 'out' } end
  local inv = TacoV.DB.query('SELECT i.id, i.amount, i.reason, c.first_name, c.last_name FROM invoices i JOIN characters c ON c.id = i.from_character_id '
    .. 'WHERE i.to_character_id = ? AND i.paid_at IS NULL ORDER BY i.id DESC', { c.id }) or {}
  local invoices = {}
  for _, i in ipairs(inv) do invoices[#invoices + 1] = { id = i.id, from = i.first_name .. ' ' .. i.last_name, amount = i.amount, reason = i.reason } end
  TriggerClientEvent('tacov:phone:app', src, 'bank', { balance = TacoV.Journal.balance('character', c.id), rows = out, invoices = invoices })
end
RegisterNetEvent('tacov:phone:bank:load', function() sendBank(source) end)

RegisterNetEvent('tacov:phone:bank:transfer', function(d)
  local src = source
  local c = TacoV.Characters.get(src)
  if not c or type(d) ~= 'table' then return end
  local amount = math.floor(tonumber(d.amount) or 0)
  local target = TacoV.DB.single('SELECT id, first_name, last_name FROM characters WHERE phone_number = ? AND deleted_at IS NULL', { tostring(d.number or '') })
  if not target or amount < 1 then notify(src, 'error', 'Empfänger oder Betrag ungültig.') return end
  if target.id == c.id then notify(src, 'error', 'Das ist deine eigene Nummer.') return end
  local okMove = TacoV.Journal.move('bank', { type = 'character', id = c.id }, { type = 'character', id = target.id }, amount, 'ueberweisung',
    { actor = c.id, note = TacoV.Util.cleanText(d.reason or '', 64) })
  if not okMove then notify(src, 'error', 'Nicht genug Guthaben.') return end
  TacoV.Accounts.push(src)
  local tsrc = srcOfNumber(tostring(d.number))
  if tsrc then TacoV.Accounts.push(tsrc) notify(tsrc, 'info', ('Überweisung von %s %s: %s'):format(c.first_name, c.last_name, fmt(amount))) end
  notify(src, 'success', ('%s an %s %s überwiesen.'):format(fmt(amount), target.first_name, target.last_name))
  sendBank(src)
end)

RegisterNetEvent('tacov:phone:bank:invoice', function(d)
  local src = source
  local c = TacoV.Characters.get(src)
  if not c or type(d) ~= 'table' then return end
  local amount = math.floor(tonumber(d.amount) or 0)
  local target = TacoV.DB.single('SELECT id FROM characters WHERE phone_number = ? AND deleted_at IS NULL', { tostring(d.number or '') })
  if not target or amount < 1 or target.id == c.id then notify(src, 'error', 'Empfänger oder Betrag ungültig.') return end
  TacoV.DB.insert('INSERT INTO invoices (from_character_id, to_character_id, amount, reason) VALUES (?, ?, ?, ?)', { c.id, target.id, amount, TacoV.Util.cleanText(d.reason or 'Rechnung', 64) })
  local tsrc = srcOfNumber(tostring(d.number))
  if tsrc then notify(tsrc, 'info', ('Neue Rechnung von %s %s: %s'):format(c.first_name, c.last_name, fmt(amount))) end
  notify(src, 'success', 'Rechnung gestellt.')
end)

RegisterNetEvent('tacov:phone:bank:pay', function(d)
  local src = source
  local c = TacoV.Characters.get(src)
  if not c or type(d) ~= 'table' then return end
  local inv = TacoV.DB.single('SELECT * FROM invoices WHERE id = ? AND to_character_id = ? AND paid_at IS NULL', { tonumber(d.id) or 0, c.id })
  if not inv then return end
  local okMove = TacoV.Journal.move('bank', { type = 'character', id = c.id }, { type = 'character', id = inv.from_character_id }, inv.amount, 'rechnung', { actor = c.id, note = inv.reason })
  if not okMove then notify(src, 'error', 'Nicht genug Guthaben.') return end
  TacoV.DB.update('UPDATE invoices SET paid_at = NOW() WHERE id = ?', { inv.id })
  TacoV.Accounts.push(src)
  for s2, p in pairs(TacoV.Players.all()) do if p.characterId == inv.from_character_id then TacoV.Accounts.push(s2) notify(s2, 'info', ('Rechnung bezahlt: %s'):format(fmt(inv.amount))) end end
  notify(src, 'success', ('Rechnung über %s bezahlt.'):format(fmt(inv.amount)))
  sendBank(src)
end)

-- ---------------------------------------------------------------- Fahrzeuge-App

RegisterNetEvent('tacov:phone:vehicles:list', function()
  local src = source
  local c = TacoV.Characters.get(src)
  if not c then return end
  local rows = TacoV.DB.query('SELECT v.*, (SELECT COUNT(*) FROM vehicle_keys k WHERE k.vehicle_id = v.id AND k.character_id <> v.owner_id) AS shared ' ..
    'FROM vehicles v WHERE v.owner_type = \'character\' AND v.owner_id = ? AND v.deleted_at IS NULL ORDER BY v.id', { c.id }) or {}
  local out = {}
  for _, v in ipairs(rows) do
    local def
    for _, e in ipairs(TacoV.Config.Vehicles.list) do if e.model == v.model then def = e end end
    local cls = TacoV.Config.Vehicles.classes[v.class] or {}
    out[#out + 1] = { id = v.id, label = def and def.label or v.model, plate = v.plate, state = v.state, garage = v.garage,
      fuel = v.fuel or 0, tank = cls.tank or 60, km = v.km or 0, shared = v.shared or 0 }
  end
  TriggerClientEvent('tacov:phone:app', src, 'vehicles', out)
end)

RegisterNetEvent('tacov:phone:vehicles:locate', function(d)
  local src = source
  local c = TacoV.Characters.get(src)
  if not c or type(d) ~= 'table' then return end
  local v = TacoV.DB.single('SELECT plate FROM vehicles WHERE id = ? AND owner_type = \'character\' AND owner_id = ?', { tonumber(d.id) or 0, c.id })
  if not v then return end
  local plate = v.plate
  for _, veh in ipairs(GetAllVehicles()) do
    if (GetVehicleNumberPlateText(veh) or ''):gsub('%s+$', ''):gsub('^%s+', '') == plate then
      local p = GetEntityCoords(veh)
      TriggerClientEvent('tacov:phone:waypoint', src, p.x, p.y)
      notify(src, 'success', 'Fahrzeug geortet – Wegpunkt gesetzt.')
      return
    end
  end
  notify(src, 'info', 'Fahrzeug nicht auffindbar (steht in der Garage oder ist zu weit weg).')
end)

RegisterNetEvent('tacov:phone:vehicles:share', function(d)
  local src = source
  local c = TacoV.Characters.get(src)
  if not c or type(d) ~= 'table' then return end
  local target = TacoV.Players.nearest(src, 3.0)
  local tc = target and TacoV.Characters.get(target)
  if not tc then notify(src, 'error', 'Niemand in der Nähe, dem du den Schlüssel geben kannst.') return end
  local v = TacoV.DB.single('SELECT id, plate FROM vehicles WHERE id = ? AND owner_type = \'character\' AND owner_id = ?', { tonumber(d.id) or 0, c.id })
  if not v then return end
  TacoV.DB.insert('INSERT IGNORE INTO vehicle_keys (vehicle_id, character_id, given_by) VALUES (?, ?, ?)', { v.id, tc.id, c.id })
  TacoV.Vehicles.reloadKeys(target)
  notify(src, 'success', ('Schlüssel für %s an %s %s gegeben.'):format(v.plate, tc.first_name, tc.last_name))
  notify(target, 'info', ('%s %s hat dir einen Schlüssel für %s gegeben.'):format(c.first_name, c.last_name, v.plate))
end)

-- ---------------------------------------------------------------- Funk

local function radioData(src)
  local inv = TacoV.Inventory.ofSource(src)
  local has = inv and TacoV.Inventory.has(inv, P.radioItem, 1)
  local ch = radio[src]
  local members, talking = {}, {}
  if ch then
    for s2 in pairs(radio) do
      if radio[s2] == ch then
        local c = TacoV.Characters.get(s2)
        local name = c and (c.first_name .. ' ' .. c.last_name) or ('#' .. s2)
        members[#members + 1] = name
        if Player(s2).state.radioTalking then talking[#talking + 1] = name end
      end
    end
  end
  return { hasRadio = has == true, channel = ch, members = members, talking = talking }
end
local function pushRadio(ch)
  for s2 in pairs(radio) do if radio[s2] == ch then TriggerClientEvent('tacov:phone:app', s2, 'radio', radioData(s2)) TriggerClientEvent('tacov:radio:state', s2, radioData(s2)) end end
end
RegisterNetEvent('tacov:phone:radio:load', function() local src = source TriggerClientEvent('tacov:phone:app', src, 'radio', radioData(src)) end)
RegisterNetEvent('tacov:phone:radio:join', function(d)
  local src = source
  local inv = TacoV.Inventory.ofSource(src)
  if not inv or not TacoV.Inventory.has(inv, P.radioItem, 1) or type(d) ~= 'table' then return end
  local ch = math.floor(tonumber(d.channel) or 0)
  if ch < 1 or ch > 999 then return end
  if ch <= P.factionChannels then
    local c = TacoV.Characters.get(src)
    if not c or not c.faction then notify(src, 'error', 'Frequenzen 1–10 sind Fraktionen vorbehalten.') return end
  end
  local old = radio[src]
  radio[src] = ch
  TriggerClientEvent('tacov:radio:set', src, ch)
  if old then pushRadio(old) end
  pushRadio(ch)
end)
RegisterNetEvent('tacov:phone:radio:leave', function()
  local src = source
  local old = radio[src]
  radio[src] = nil
  TriggerClientEvent('tacov:radio:set', src, nil)
  TriggerClientEvent('tacov:phone:app', src, 'radio', radioData(src))
  TriggerClientEvent('tacov:radio:state', src, radioData(src))
  if old then pushRadio(old) end
end)
RegisterNetEvent('tacov:radio:talking', function(on)
  local src = source
  Player(src).state:set('radioTalking', on == true, true)
  if radio[src] then pushRadio(radio[src]) end
end)

-- ---------------------------------------------------------------- Sonstiges

RegisterNetEvent('tacov:phone:settings:set', function(d)
  local src = source
  if type(d) ~= 'table' then return end
  airplane[src] = d.airplane == true or nil
end)

-- Handy weg bei Koma; Funk verlassen bei Trennung
AddEventHandler('tacov:health:comaItems', function(src)
  local inv = TacoV.Inventory.ofSource(src)
  if inv and TacoV.Inventory.has(inv, P.item, 1) then TacoV.Inventory.remove(inv, P.item, 1) end
end)
AddEventHandler('playerDropped', function()
  local src = source
  if calls[src] then endCall(src, 'Verbindung abgebrochen.') end
  local old = radio[src]
  radio[src], airplane[src] = nil, nil
  if old then pushRadio(old) end
end)
AddEventHandler('tacov:core:characterSelected', function(src)
  local c = TacoV.Characters.get(src)
  if c and not c.phone_number then TacoV.Phone.assignNumber(c.id) c.phone_number = TacoV.DB.scalar('SELECT phone_number FROM characters WHERE id = ?', { c.id }) end
  -- ungelesene Nachrichten melden
  SetTimeout(5000, function()
    local n = c and TacoV.DB.scalar('SELECT COUNT(*) FROM phone_messages WHERE to_number = ? AND read_at IS NULL', { c.phone_number }) or 0
    if n > 0 then notify(src, 'info', ('%d ungelesene Nachricht(en) auf dem Handy.'):format(n)) end
  end)
end)

-- Team: Wunschnummer per Ticket (/nummer <ID> <4-stellig>, Recht admin.give)
RegisterCommand('nummer', function(src, args)
  if src ~= 0 and not TacoV.Permissions.has(src, 'admin.give') then return end
  local target = tonumber(args[1])
  local n = tostring(args[2] or ''):match('^%d%d%d%d$')
  local c = target and TacoV.Characters.get(target)
  if not c or not n then if src ~= 0 then notify(src, 'info', 'Nutzung: /nummer <Server-ID> <4-stellig>') end return end
  if TacoV.DB.scalar('SELECT id FROM characters WHERE phone_number = ?', { n }) then if src ~= 0 then notify(src, 'error', 'Nummer vergeben.') end return end
  TacoV.DB.update('UPDATE characters SET phone_number = ? WHERE id = ?', { n, c.id })
  c.phone_number = n
  if src ~= 0 then notify(src, 'success', ('Nummer %s gesetzt.'):format(n)) end
  notify(target, 'info', ('Deine neue Handynummer: %s'):format(n))
end, true)
