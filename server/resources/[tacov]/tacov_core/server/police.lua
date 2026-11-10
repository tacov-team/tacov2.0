-- LSPD (Punkte 9.4–9.6, Server): MDT (Personen, Fahrzeuge, Einträge, Fahndung, Berichte), Maßnahmen am Spieler
-- (Handschellen, Abführen, Durchsuchen, Ausweis, Atemtest, Geldstrafe, Haft), Beschlagnahme, Ausrüstungskauf, Asservatenkammer.
-- Alles nur im Dienst; jede Maßnahme steht im Log „police“ und im Fraktionsprotokoll.
TacoV = TacoV or {}
TacoV.Police = {}

local P = TacoV.Config.Police
local STATE = { type = 'state', id = 0 }
local jailed = {}     -- [src] = { cell = name }

local function notify(src, kind, text) TriggerClientEvent('tacov:core:notify', src, kind, text) end
local function fmt(n) return (tostring(math.floor(n or 0)):reverse():gsub('(%d%d%d)', '%1.'):reverse():gsub('^%.', '')) end
local function fullName(c) return c.first_name .. ' ' .. c.last_name end

--- Beamter im Dienst? Gibt Charakter zurück.
local function officer(src, minRank)
  local c = TacoV.Characters.get(src)
  if not c or c.faction ~= P.faction or not TacoV.Factions.isOnDuty(src) then return nil end
  if minRank and (c.faction_rank or 1) < minRank then
    notify(src, 'error', ('Erst ab %s.'):format(TacoV.Factions.rankName(P.faction, minRank)))
    return nil
  end
  return c
end
TacoV.Police.officer = officer

local function targetNear(src, target, range)
  target = tonumber(target)
  if not target or target == src then return nil end
  local tc = TacoV.Characters.get(target)
  if not tc then return nil end
  if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(target))) > (range or P.cuffRange) + 1.0 then return nil end
  return target, tc
end

local function plog(c, text, targetChar)
  TacoV.Log.write('police', text, { characterId = c.id, target = targetChar and targetChar.id or nil })
end

-- ---------------------------------------------------------------- Maßnahmen am Spieler

RegisterNetEvent('tacov:police:cuff', function(target)
  local src = source
  local c = officer(src)
  local t, tc = targetNear(src, target)
  if not c or not t then return end
  local on = not Player(t).state.cuffed
  Player(t).state:set('cuffed', on, true)
  if not on then Player(t).state:set('escort', false, true) end
  if on then TacoV.Weapons.clear(t) end
  notify(src, 'success', on and ('%s Handschellen angelegt.'):format(fullName(tc)) or 'Handschellen abgenommen.')
  notify(t, 'warn', on and 'Dir wurden Handschellen angelegt.' or 'Die Handschellen wurden abgenommen.')
  plog(c, ('%s %s Handschellen: %s'):format(fullName(c), on and 'legt an' or 'nimmt ab', fullName(tc)), tc)
end)

RegisterNetEvent('tacov:police:escort', function(target)
  local src = source
  local c = officer(src)
  local t = targetNear(src, target)
  if not c or not t then return end
  if not Player(t).state.cuffed then notify(src, 'error', 'Erst Handschellen anlegen.') return end
  local on = Player(t).state.escort ~= src
  Player(t).state:set('escort', on and src or false, true)
  notify(src, 'info', on and 'Du führst die Person ab.' or 'Abführen beendet.')
end)

RegisterNetEvent('tacov:police:seat', function(target, netId, out)
  local src = source
  local c = officer(src)
  local t = targetNear(src, target, 5.0)
  if not c or not t then return end
  if not Player(t).state.cuffed then notify(src, 'error', 'Erst Handschellen anlegen.') return end
  Player(t).state:set('escort', false, true)
  TriggerClientEvent('tacov:police:seat', t, tonumber(netId), out == true)
end)

local function licensesOf(cid)
  local rows = TacoV.DB.query('SELECT type, points, revoked_at FROM licenses WHERE character_id = ? ORDER BY type', { cid }) or {}
  local out = {}
  for _, l in ipairs(rows) do out[#out + 1] = { type = l.type, points = l.points, revoked = l.revoked_at ~= nil } end
  return out
end

RegisterNetEvent('tacov:police:identify', function(target)
  local src = source
  local c = officer(src)
  local t, tc = targetNear(src, target)
  if not c or not t then return end
  if not (Player(t).state.cuffed or Player(t).state.downed) then
    notify(t, 'info', ('%s (LSPD) verlangt deinen Ausweis – zeigen über X → Ausweis.'):format(fullName(c)))
    notify(src, 'info', 'Ausweis verlangt. Abnehmen geht nur bei gefesselten oder bewusstlosen Personen.')
    return
  end
  local lic = {}
  for _, l in ipairs(licensesOf(tc.id)) do lic[#lic + 1] = l.type .. (l.revoked and ' (entzogen)' or '') .. (l.points > 0 and (' ' .. l.points .. ' P.') or '') end
  notify(src, 'info', ('Ausweis: %s, geboren %s · Führerscheine: %s'):format(fullName(tc), tostring(tc.birth_date):sub(1, 10), #lic > 0 and table.concat(lic, ', ') or 'keine'))
  plog(c, ('%s nimmt den Ausweis von %s'):format(fullName(c), fullName(tc)), tc)
end)

RegisterNetEvent('tacov:police:breath', function(target)
  local src = source
  local c = officer(src)
  local t, tc = targetNear(src, target)
  if not c or not t then return end
  local promille = (tc.needs and tc.needs.alcohol) or 0
  local text = ('Atemtest %s: %.1f ‰'):format(fullName(tc), promille)
  notify(src, promille >= TacoV.Config.Needs.alcohol.duiThreshold and 'warn' or 'info', text)
  notify(t, 'info', ('Atemtest: %.1f ‰'):format(promille))
  plog(c, text, tc)
end)

RegisterNetEvent('tacov:police:search', function(target)
  local src = source
  local c = officer(src)
  local t, tc = targetNear(src, target, P.searchRange)
  if not c or not t then return end
  if not (Player(t).state.cuffed or Player(t).state.downed) then notify(src, 'error', 'Durchsuchen nur bei gefesselten oder bewusstlosen Personen.') return end
  local inv = TacoV.Inventory.ofSource(t)
  if not inv then return end
  notify(t, 'warn', 'Du wirst durchsucht.')
  plog(c, ('%s durchsucht %s'):format(fullName(c), fullName(tc)), tc)
  TacoV.Inventory.openContainer(src, inv, {
    title = 'Durchsuchung', subtitle = fullName(tc),
    check = function(s) return targetNear(s, t, P.searchRange + 1.0) ~= nil end,
    allow = function(s, direction, item, amount)
      if direction ~= 'take' then return false, 'Hier wird nur abgenommen.' end
      local def = TacoV.Config.Items[item]
      local oc = TacoV.Characters.get(s)
      plog(oc, ('%s nimmt %s ab: %dx %s'):format(fullName(oc), fullName(tc), amount, def and def.label or item), tc)
      if def and def.weapon then TacoV.Weapons.clear(t) end
      notify(t, 'warn', ('Abgenommen: %dx %s'):format(amount, def and def.label or item))
      return true
    end,
  })
end)

-- Geldstrafe: vom Konto an den Staat (auch ins Minus), Eintrag in der Akte
RegisterNetEvent('tacov:police:fine', function(target, amount, reason)
  local src = source
  local c = officer(src, P.fineMinRank)
  local t, tc = targetNear(src, target, 6.0)
  if not c or not t then return end
  amount = TacoV.Util.money(tonumber(amount) or 0)
  reason = TacoV.Util.cleanText(reason or '', 120)
  if amount <= 0 or amount > P.fineMax then notify(src, 'error', ('Geldstrafe 1–%s $.'):format(fmt(P.fineMax))) return end
  if reason == '' then notify(src, 'error', 'Grund fehlt.') return end
  TacoV.Journal.move('bank', { type = 'character', id = tc.id }, STATE, amount, 'geldstrafe', { actor = c.id, note = reason, allowNegative = true })
  TacoV.DB.insert('INSERT INTO mdt_records (character_id, officer_id, officer_name, offense, fine) VALUES (?, ?, ?, ?, ?)', { tc.id, c.id, fullName(c), reason, amount })
  TacoV.Accounts.push(t)
  notify(src, 'success', ('Geldstrafe %s $ für %s.'):format(fmt(amount), fullName(tc)))
  notify(t, 'warn', ('Geldstrafe: %s $ – %s'):format(fmt(amount), reason))
  plog(c, ('%s verhängt %s $ Geldstrafe gegen %s: %s'):format(fullName(c), fmt(amount), fullName(tc), reason), tc)
end)

-- ---------------------------------------------------------------- Haft

local function cells()
  local out = {}
  for _, l in ipairs(TacoV.Locations.all()) do if l.kind == 'jail_cell' then out[#out + 1] = l end end
  table.sort(out, function(a, b) return a.name < b.name end)
  return out
end
local function nearCells(src, radius)
  local pos = GetEntityCoords(GetPlayerPed(src))
  for _, l in ipairs(cells()) do if #(pos - vector3(l.x, l.y, l.z)) <= radius then return true end end
  return false
end
local function freeCell()
  local list = cells()
  local used = {}
  for _, j in pairs(jailed) do used[j.cell] = (used[j.cell] or 0) + 1 end
  table.sort(list, function(a, b) return (used[a.name] or 0) < (used[b.name] or 0) end)
  return list[1]
end

local function putInCell(src, c)
  local cell = freeCell()
  if not cell then return false end
  jailed[src] = { cell = cell.name }
  Player(src).state:set('cuffed', false, true)
  Player(src).state:set('escort', false, true)
  Player(src).state:set('jailed', true, true)
  TacoV.Weapons.clear(src)
  TacoV.AC.allowTeleport(src)
  TriggerClientEvent('tacov:police:jail', src, { x = cell.x, y = cell.y, z = cell.z, seconds = c.jail_seconds, radius = P.jailRadius })
  return true
end

local function release(src, c, byText)
  jailed[src] = nil
  c.jail_seconds = 0
  TacoV.DB.update('UPDATE characters SET jail_seconds = 0 WHERE id = ?', { c.id })
  Player(src).state:set('jailed', false, true)
  local out = TacoV.Locations.get('jail_release')
  TacoV.AC.allowTeleport(src)
  TriggerClientEvent('tacov:police:released', src, out and { x = out.x, y = out.y, z = out.z, h = out.heading or 0.0 } or nil)
  notify(src, 'success', 'Du bist entlassen.' .. (byText and (' (' .. byText .. ')') or ''))
end

RegisterNetEvent('tacov:police:jail', function(target, minutes, reason)
  local src = source
  local c = officer(src, P.jailMinRank)
  local t, tc = targetNear(src, target, 6.0)
  if not c or not t then return end
  if not nearCells(src, 40.0) then notify(src, 'error', 'Festnahme nur in der Wache bei den Zellen.') return end
  minutes = math.floor(tonumber(minutes) or 0)
  reason = TacoV.Util.cleanText(reason or '', 120)
  if minutes < 1 or minutes > P.jailMaxMinutes then notify(src, 'error', ('Haft 1–%d Minuten.'):format(P.jailMaxMinutes)) return end
  if reason == '' then notify(src, 'error', 'Grund fehlt.') return end
  tc.jail_seconds = minutes * 60
  TacoV.DB.update('UPDATE characters SET jail_seconds = ? WHERE id = ?', { tc.jail_seconds, tc.id })
  if not putInCell(t, tc) then notify(src, 'error', 'Keine Zelle gesetzt (Ort jail_cell_1).') return end
  TacoV.DB.insert('INSERT INTO mdt_records (character_id, officer_id, officer_name, offense, jail_minutes) VALUES (?, ?, ?, ?, ?)', { tc.id, c.id, fullName(c), reason, minutes })
  TacoV.DB.update("UPDATE mdt_warrants SET closed_at = NOW(), closed_by = ? WHERE kind = 'person' AND character_id = ? AND closed_at IS NULL", { fullName(c) .. ' (Festnahme)', tc.id })
  notify(src, 'success', ('%s: %d min Haft.'):format(fullName(tc), minutes))
  notify(t, 'warn', ('Haft: %d Minuten – %s'):format(minutes, reason))
  plog(c, ('%s nimmt %s fest: %d min – %s'):format(fullName(c), fullName(tc), minutes, reason), tc)
end)

RegisterNetEvent('tacov:police:release', function(target)
  local src = source
  local c = officer(src, P.jailMinRank)
  target = tonumber(target)
  local tc = target and TacoV.Characters.get(target)
  if not c or not tc or not jailed[target] then return end
  if not nearCells(src, 40.0) then notify(src, 'error', 'Nur in der Wache.') return end
  release(target, tc, 'vorzeitig durch ' .. fullName(c))
  plog(c, ('%s entlässt %s vorzeitig'):format(fullName(c), fullName(tc)), tc)
end)

RegisterNetEvent('tacov:police:inmates', function()
  local src = source
  if not officer(src) then return end
  local list = {}
  for s in pairs(jailed) do
    local jc = TacoV.Characters.get(s)
    if jc then list[#list + 1] = { id = s, name = fullName(jc), seconds = jc.jail_seconds } end
  end
  TriggerClientEvent('tacov:police:inmates', src, list)
end)

-- Haftzeit läuft nur online
CreateThread(function()
  while true do
    Wait(15000)
    for src in pairs(jailed) do
      local c = TacoV.Characters.get(src)
      if not c then
        jailed[src] = nil
      else
        c.jail_seconds = math.max(0, (c.jail_seconds or 0) - 15)
        TacoV.DB.update('UPDATE characters SET jail_seconds = ? WHERE id = ?', { c.jail_seconds, c.id })
        if c.jail_seconds <= 0 then release(src, c) else TriggerClientEvent('tacov:police:jailTime', src, c.jail_seconds) end
      end
    end
  end
end)
AddEventHandler('tacov:core:characterSelected', function(src)
  Wait(4000)
  local c = TacoV.Characters.get(src)
  if c and (tonumber(c.jail_seconds) or 0) > 0 then
    c.jail_seconds = tonumber(c.jail_seconds)
    if putInCell(src, c) then notify(src, 'warn', ('Du sitzt noch %d min in Haft.'):format(math.ceil(c.jail_seconds / 60))) end
  end
end)
AddEventHandler('tacov:core:characterUnloaded', function(src)
  jailed[src] = nil
  Player(src).state:set('cuffed', false, true)
  Player(src).state:set('escort', false, true)
  Player(src).state:set('jailed', false, true)
end)
AddEventHandler('playerDropped', function() jailed[source] = nil end)

-- ---------------------------------------------------------------- Fahrzeug beschlagnahmen

RegisterNetEvent('tacov:police:seize', function(netId)
  local src = source
  local c = officer(src, P.impoundMinRank)
  if not c then return end
  local ent = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
  if ent == 0 or not DoesEntityExist(ent) or #(GetEntityCoords(ent) - GetEntityCoords(GetPlayerPed(src))) > 8.0 then return end
  for seat = -1, 6 do if GetPedInVehicleSeat(ent, seat) ~= 0 then notify(src, 'error', 'Das Fahrzeug muss leer sein.') return end end
  local row, plate = TacoV.Vehicles.seize(netId, P.impoundFee)
  if row and row.owner_type == 'character' then
    for _, pid in ipairs(GetPlayers()) do
      local oc = TacoV.Characters.get(tonumber(pid))
      if oc and oc.id == row.owner_id then notify(tonumber(pid), 'warn', ('Dein Fahrzeug %s wurde beschlagnahmt (Verwahrhof, %s $).'):format(plate, fmt(P.impoundFee))) end
    end
  end
  notify(src, 'success', ('%s beschlagnahmt%s.'):format(plate or 'Fahrzeug', row and ' – steht im Verwahrhof' or ' (kein Halter, entfernt)'))
  plog(c, ('%s beschlagnahmt Fahrzeug %s'):format(fullName(c), plate or '?'))
end)

-- ---------------------------------------------------------------- Ausrüstung, Asservatenkammer

local function nearPoint(src, name, radius)
  local l = TacoV.Locations.get(name)
  return l and #(GetEntityCoords(GetPlayerPed(src)) - vector3(l.x, l.y, l.z)) <= (radius or 4.0)
end

RegisterNetEvent('tacov:police:equipment', function(index)
  local src = source
  local c = officer(src)
  if not c then notify(src, 'error', 'Nur im Dienst.') return end
  if not nearPoint(src, 'faction_equipment_lspd', 4.0) then return end
  if not index then
    local list = {}
    for i, e in ipairs(P.equipment) do
      local def = TacoV.Config.Items[e.item]
      list[#list + 1] = { index = i, label = def.label .. (e.amount and (' ×' .. e.amount) or ''), price = e.price * (e.amount or 1), minRank = e.minRank,
        rankName = TacoV.Factions.rankName(P.faction, e.minRank), locked = (c.faction_rank or 1) < e.minRank }
    end
    TriggerClientEvent('tacov:police:equipment', src, list)
    return
  end
  local e = P.equipment[tonumber(index) or 0]
  if not e or (c.faction_rank or 1) < e.minRank then return end
  local def = TacoV.Config.Items[e.item]
  local inv = TacoV.Inventory.ofSource(src)
  local amount = e.amount or 1
  local price = e.price * amount
  if def.unique and TacoV.Inventory.count(inv, e.item) > 0 then notify(src, 'error', 'Das hast du schon.') return end
  if price > 0 and not TacoV.Accounts.pay(src, STATE, price, 'ausruestung', def.label) then notify(src, 'error', 'Nicht genug Geld.') return end
  local ok = TacoV.Inventory.add(inv, e.item, amount)
  if not ok then
    if price > 0 then TacoV.Accounts.receive(src, STATE, price, 'ausruestung', 'Rückbuchung') end
    notify(src, 'error', 'Zu schwer.') return
  end
  TacoV.Inventory.send(src)
  notify(src, 'success', ('%s erhalten%s.'):format(def.label, price > 0 and (' (' .. fmt(price) .. ' $)') or ''))
  plog(c, ('%s kauft Ausrüstung: %dx %s'):format(fullName(c), amount, def.label))
end)

RegisterNetEvent('tacov:police:evidence', function()
  local src = source
  local c = officer(src)
  local f = TacoV.Factions.get(P.faction)
  if not c or not f or not nearPoint(src, 'faction_evidence_lspd', 4.0) then return end
  local inv = TacoV.Inventory.load('evidence', f.num, 2000)
  TacoV.Inventory.openContainer(src, inv, {
    title = 'Asservatenkammer', subtitle = 'Entnahme ab ' .. TacoV.Factions.rankName(P.faction, 9),
    check = function(s) return nearPoint(s, 'faction_evidence_lspd', 6.0) end,
    allow = function(s, direction, item, amount)
      local oc = TacoV.Characters.get(s)
      local def = TacoV.Config.Items[item]
      if direction == 'take' and (oc.faction_rank or 1) < 9 then return false, 'Entnahme nur durch die Führung.' end
      plog(oc, ('Asservatenkammer: %s %s %dx %s'):format(fullName(oc), direction == 'take' and 'entnimmt' or 'lagert ein', amount, def and def.label or item))
      return true
    end,
  })
end)

-- ---------------------------------------------------------------- MDT

local function send(src, kind, data) TriggerClientEvent('tacov:mdt:data', src, kind, data) end
local function logQuery(c, kind, q) TacoV.DB.insert('INSERT INTO mdt_queries (officer_id, kind, query) VALUES (?, ?, ?)', { c.id, kind, tostring(q):sub(1, 64) }) end

local function openWarrants()
  local rows = TacoV.DB.query(
    "SELECT w.id, w.kind, w.character_id, w.plate, w.reason, w.officer_name, w.created_at, c.first_name, c.last_name FROM mdt_warrants w " ..
    "LEFT JOIN characters c ON c.id = w.character_id WHERE w.closed_at IS NULL ORDER BY w.id DESC LIMIT 60") or {}
  local out = {}
  for _, r in ipairs(rows) do
    out[#out + 1] = { id = r.id, kind = r.kind, characterId = r.character_id, plate = r.plate, reason = r.reason, officer = r.officer_name,
      at = tostring(r.created_at), name = r.first_name and (r.first_name .. ' ' .. r.last_name) or nil }
  end
  return out
end
local function reports()
  local rows = TacoV.DB.query('SELECT id, officer_name, title, text, created_at FROM mdt_reports ORDER BY id DESC LIMIT 25') or {}
  local out = {}
  for _, r in ipairs(rows) do out[#out + 1] = { id = r.id, officer = r.officer_name, title = r.title, text = r.text, at = tostring(r.created_at) } end
  return out
end

RegisterNetEvent('tacov:mdt:open', function()
  local src = source
  local c = officer(src)
  if not c then notify(src, 'error', 'Das MDT gibt es nur im Dienst.') return end
  TriggerClientEvent('tacov:mdt:open', src, { officer = fullName(c), rank = TacoV.Factions.rankName(P.faction, c.faction_rank), rankNo = c.faction_rank,
    warrants = openWarrants(), reports = reports(), fineMax = P.fineMax, jailMax = P.jailMaxMinutes, warrantMinRank = P.warrantMinRank })
end)

RegisterNetEvent('tacov:mdt:person', function(q)
  local src = source
  local c = officer(src)
  q = TacoV.Util.cleanText(tostring(q or ''), 48)
  if not c or #q < 2 then return end
  logQuery(c, 'person', q)
  local like = '%' .. q .. '%'
  local rows = TacoV.DB.query(
    "SELECT id, first_name, last_name, birth_date, phone_number FROM characters WHERE deleted_at IS NULL AND " ..
    "(CONCAT(first_name, ' ', last_name) LIKE ? OR phone_number = ?) ORDER BY last_name LIMIT " .. P.mdtMaxResults, { like, q }) or {}
  local out = {}
  for _, r in ipairs(rows) do out[#out + 1] = { id = r.id, name = r.first_name .. ' ' .. r.last_name, birth = tostring(r.birth_date):sub(1, 10), phone = r.phone_number } end
  send(src, 'persons', out)
end)

local function personFile(cid)
  local r = TacoV.DB.single('SELECT id, first_name, last_name, birth_date, phone_number, faction, jail_seconds FROM characters WHERE id = ? AND deleted_at IS NULL', { cid })
  if not r then return nil end
  local vehicles = TacoV.DB.query("SELECT plate, model, state, registered_at FROM vehicles WHERE owner_type = 'character' AND owner_id = ? AND deleted_at IS NULL", { cid }) or {}
  local veh = {}
  for _, v in ipairs(vehicles) do veh[#veh + 1] = { plate = v.plate, model = v.model, state = v.state, registered = v.registered_at ~= nil } end
  local records = TacoV.DB.query('SELECT officer_name, offense, fine, jail_minutes, created_at FROM mdt_records WHERE character_id = ? ORDER BY id DESC LIMIT 30', { cid }) or {}
  local rec = {}
  for _, x in ipairs(records) do rec[#rec + 1] = { officer = x.officer_name, offense = x.offense, fine = x.fine, jail = x.jail_minutes, at = tostring(x.created_at) } end
  local warrants = {}
  for _, w in ipairs(openWarrants()) do if w.kind == 'person' and w.characterId == cid then warrants[#warrants + 1] = w end end
  return { id = r.id, name = r.first_name .. ' ' .. r.last_name, birth = tostring(r.birth_date):sub(1, 10), phone = r.phone_number,
    licenses = licensesOf(cid), vehicles = veh, records = rec, warrants = warrants, inJail = (tonumber(r.jail_seconds) or 0) > 0 }
end

RegisterNetEvent('tacov:mdt:file', function(cid)
  local src = source
  local c = officer(src)
  cid = tonumber(cid)
  if not c or not cid then return end
  logQuery(c, 'file', cid)
  send(src, 'file', personFile(cid) or false)
end)

RegisterNetEvent('tacov:mdt:vehicle', function(plate)
  local src = source
  local c = officer(src)
  plate = tostring(plate or ''):upper():gsub('^%s+', ''):gsub('%s+$', '')
  if not c or #plate < 2 then return end
  logQuery(c, 'vehicle', plate)
  local v = TacoV.DB.single(
    "SELECT v.plate, v.model, v.state, v.registered_at, v.owner_type, v.owner_id, c.first_name, c.last_name FROM vehicles v " ..
    "LEFT JOIN characters c ON v.owner_type = 'character' AND c.id = v.owner_id WHERE v.plate = ? AND v.deleted_at IS NULL", { plate })
  local wanted = TacoV.DB.single("SELECT reason FROM mdt_warrants WHERE kind = 'vehicle' AND plate = ? AND closed_at IS NULL LIMIT 1", { plate })
  if not v then
    send(src, 'vehicle', { plate = plate, unknown = true, wanted = wanted and wanted.reason or nil })
    return
  end
  send(src, 'vehicle', { plate = v.plate, model = v.model, state = v.state, registered = v.registered_at ~= nil,
    owner = v.first_name and (v.first_name .. ' ' .. v.last_name) or (v.owner_type == 'faction' and 'Fraktion' or 'unbekannt'),
    ownerId = v.owner_type == 'character' and v.owner_id or nil, wanted = wanted and wanted.reason or nil })
end)

RegisterNetEvent('tacov:mdt:record', function(d)
  local src = source
  local c = officer(src)
  if not c or type(d) ~= 'table' then return end
  local cid = tonumber(d.characterId)
  local offense = TacoV.Util.cleanText(d.offense or '', 200)
  if not cid or offense == '' then return end
  TacoV.DB.insert('INSERT INTO mdt_records (character_id, officer_id, officer_name, offense, fine, jail_minutes) VALUES (?, ?, ?, ?, 0, 0)', { cid, c.id, fullName(c), offense })
  plog(c, ('MDT-Eintrag durch %s für #%d: %s'):format(fullName(c), cid, offense))
  send(src, 'file', personFile(cid) or false)
end)

RegisterNetEvent('tacov:mdt:warrant', function(d)
  local src = source
  local c = officer(src, P.warrantMinRank)
  if not c or type(d) ~= 'table' then return end
  local reason = TacoV.Util.cleanText(d.reason or '', 200)
  if reason == '' then return end
  if d.kind == 'vehicle' then
    local plate = tostring(d.plate or ''):upper():gsub('^%s+', ''):gsub('%s+$', '')
    if #plate < 2 then return end
    TacoV.DB.insert("INSERT INTO mdt_warrants (kind, plate, reason, officer_name) VALUES ('vehicle', ?, ?, ?)", { plate:sub(1, 8), reason, fullName(c) })
    plog(c, ('Fahrzeugfahndung %s durch %s: %s'):format(plate, fullName(c), reason))
  else
    local cid = tonumber(d.characterId)
    if not cid then return end
    TacoV.DB.insert("INSERT INTO mdt_warrants (kind, character_id, reason, officer_name) VALUES ('person', ?, ?, ?)", { cid, reason, fullName(c) })
    plog(c, ('Haftbefehl gegen #%d durch %s: %s'):format(cid, fullName(c), reason))
    send(src, 'file', personFile(cid) or false)
  end
  send(src, 'warrants', openWarrants())
end)

RegisterNetEvent('tacov:mdt:warrantClose', function(id)
  local src = source
  local c = officer(src, P.warrantMinRank)
  if not c then return end
  TacoV.DB.update('UPDATE mdt_warrants SET closed_at = NOW(), closed_by = ? WHERE id = ? AND closed_at IS NULL', { fullName(c), tonumber(id) or 0 })
  plog(c, ('Fahndung #%s aufgehoben durch %s'):format(tostring(id), fullName(c)))
  send(src, 'warrants', openWarrants())
end)

RegisterNetEvent('tacov:mdt:report', function(d)
  local src = source
  local c = officer(src)
  if not c or type(d) ~= 'table' then return end
  local title, text = TacoV.Util.cleanText(d.title or '', 96), TacoV.Util.cleanText(d.text or '', 2000)
  if title == '' or text == '' then return end
  TacoV.DB.insert('INSERT INTO mdt_reports (officer_name, title, text) VALUES (?, ?, ?)', { fullName(c), title, text })
  send(src, 'reports', reports())
end)

-- Startliste Fahrzeuge einmalig eintragen
CreateThread(function()
  Wait(4000)
  local n = tonumber(TacoV.DB.scalar('SELECT COUNT(*) FROM faction_vehicles WHERE faction_id = ?', { P.faction })) or 0
  if n == 0 then
    for _, v in ipairs(P.vehicles) do
      TacoV.DB.insert('INSERT INTO faction_vehicles (faction_id, model, label, min_rank) VALUES (?, ?, ?, ?)', { P.faction, v.model, v.label, v.minRank })
    end
  end
end)
