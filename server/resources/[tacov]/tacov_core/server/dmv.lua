-- DMV (Punkt 4.9) und Fahrschule (Punkt 4.10): Führerscheine, Zulassung, Halterwechsel, Theorie- und Praxisprüfung.
-- Alles wird hier geprüft; der Client zeigt nur Menüs, spawnt das Prüfungsfahrzeug und meldet Kontrollpunkte.
TacoV = TacoV or {}
TacoV.DMV = {}

local Cfg = TacoV.Config.DMV
local STATE = { type = 'state', id = 0 }

local function fail(src, text) TriggerClientEvent('tacov:core:notify', src, 'error', text) end
local function ok(src, text) TriggerClientEvent('tacov:core:notify', src, 'success', text) end
local function info(src, text) TriggerClientEvent('tacov:core:notify', src, 'info', text) end
local function trim(s) return (tostring(s or ''):gsub('^%s+', ''):gsub('%s+$', '')) end
local function fmt(n)
  local s = tostring(math.floor(n))
  local out = s:reverse():gsub('(%d%d%d)', '%1.'):reverse()
  if out:sub(1, 1) == '.' then out = out:sub(2) end
  return out .. ' $'
end

-- ---------------------------------------------------------------- Führerscheine

local cache = {} -- [characterId] = { [type] = { points = n } }

local function loadLicenses(characterId)
  local map = {}
  local rows = TacoV.DB.query('SELECT type, points FROM licenses WHERE character_id = ? AND revoked_at IS NULL', { characterId }) or {}
  for _, r in ipairs(rows) do map[r.type] = { points = r.points } end
  cache[characterId] = map
  return map
end

function TacoV.DMV.licenses(characterId)
  return cache[characterId] or loadLicenses(characterId)
end

function TacoV.DMV.hasLicense(characterId, kind)
  return TacoV.DMV.licenses(characterId)[kind] ~= nil
end

function TacoV.DMV.grant(characterId, kind)
  for src, p in pairs(TacoV.Players.all()) do if p.characterId == characterId then TriggerEvent('tacov:newbie:step', src, 'license') end end
  TacoV.DB.update(
    'INSERT INTO licenses (character_id, type) VALUES (?, ?) ON DUPLICATE KEY UPDATE revoked_at = NULL, points = 0, issued_at = NOW()',
    { characterId, kind })
  loadLicenses(characterId)
end

function TacoV.DMV.revoke(characterId, kind)
  TacoV.DB.update('UPDATE licenses SET revoked_at = NOW() WHERE character_id = ? AND type = ?', { characterId, kind })
  loadLicenses(characterId)
end

--- Punkte (Blitzer, Delikte); ab Cfg.pointsRevoke Entzug aller Fahrerlaubnisse A/B/C
function TacoV.DMV.addPoints(characterId, points, reason)
  TacoV.DB.update('UPDATE licenses SET points = points + ? WHERE character_id = ? AND type IN (\'A\', \'B\', \'C\') AND revoked_at IS NULL', { points, characterId })
  local map = loadLicenses(characterId)
  for kind, l in pairs(map) do
    if (kind == 'A' or kind == 'B' or kind == 'C') and l.points >= Cfg.pointsRevoke then TacoV.DMV.revoke(characterId, kind) end
  end
  TacoV.Log.write('justice', ('%d Punkte beim DMV (%s)'):format(points, reason or ''), { characterId = characterId })
end

exports('hasLicense', TacoV.DMV.hasLicense)

-- ---------------------------------------------------------------- Schalter

local function atDesk(src)
  return TacoV.Locations.nearest(src, 'dmv', 6.0) ~= nil
end

--- Menüdaten für den Schalter: Lizenzen, zulassungsfähige Fahrzeuge in der Nähe, Preise
RegisterNetEvent('tacov:dmv:open', function(nearbyNetIds)
  local src = source
  local c = TacoV.Characters.get(src)
  if not c or not atDesk(src) then return end
  local lic = {}
  for kind, l in pairs(TacoV.DMV.licenses(c.id)) do lic[#lic + 1] = { type = kind, points = l.points } end
  table.sort(lic, function(a, b) return a.type < b.type end)
  -- Fahrzeuge in der Nähe, die mir gehören
  local vehicles = {}
  for _, netId in ipairs(type(nearbyNetIds) == 'table' and nearbyNetIds or {}) do
    local ent = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if ent ~= 0 and DoesEntityExist(ent) then
      local plate = trim(GetVehicleNumberPlateText(ent))
      local row = TacoV.DB.single('SELECT id, plate, model, class, registered_at FROM vehicles WHERE plate = ? AND deleted_at IS NULL AND owner_type = \'character\' AND owner_id = ?', { plate, c.id })
      if row then vehicles[#vehicles + 1] = { netId = tonumber(netId), id = row.id, plate = row.plate, model = row.model, registered = row.registered_at ~= nil } end
    end
  end
  TriggerClientEvent('tacov:dmv:data', src, {
    licenses = lic, vehicles = vehicles, fees = { registration = Cfg.registrationFee, transfer = Cfg.transferFee },
    school = { B = Cfg.school.B.price, A = Cfg.school.A.price, C = Cfg.school.C.price, retry = Cfg.school.B.retry },
    bank = TacoV.Journal.balance('character', c.id),
  })
end)

-- Zulassung: Kennzeichen vergeben (150 $ an den Staat), Fahrzeug muss in der Nähe stehen
RegisterNetEvent('tacov:dmv:register', function(netId)
  local src = source
  local c = TacoV.Characters.get(src)
  if not c or not atDesk(src) then return end
  local ent = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
  if ent == 0 or not DoesEntityExist(ent) then return fail(src, 'Fahrzeug nicht gefunden.') end
  if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(ent)) > 30.0 then return fail(src, 'Das Fahrzeug muss vor dem DMV stehen.') end
  local plate = trim(GetVehicleNumberPlateText(ent))
  local row = TacoV.DB.single('SELECT * FROM vehicles WHERE plate = ? AND deleted_at IS NULL', { plate })
  if not row or row.owner_type ~= 'character' or row.owner_id ~= c.id then return fail(src, 'Das ist nicht dein Fahrzeug.') end
  if row.registered_at then return fail(src, 'Das Fahrzeug ist bereits zugelassen.') end
  local paid = TacoV.Accounts.pay(src, STATE, Cfg.registrationFee, 'zulassung', plate)
  if not paid then return fail(src, ('Nicht genug Guthaben (%s).'):format(fmt(Cfg.registrationFee))) end
  local newPlate = TacoV.Vehicles.newPlate()
  if not newPlate then return fail(src, 'Kein freies Kennzeichen – bitte das Team informieren.') end
  TacoV.DB.update('UPDATE vehicles SET plate = ?, registered_at = NOW() WHERE id = ?', { newPlate, row.id })
  TacoV.Vehicles.replate(plate, newPlate)
  TriggerClientEvent('tacov:vehicles:setPlate', src, tonumber(netId), newPlate)
  TacoV.Log.write('money', ('Zulassung %s -> %s für %s'):format(plate, newPlate, fmt(Cfg.registrationFee)), { characterId = c.id })
  ok(src, ('Zugelassen: neues Kennzeichen %s.'):format(newPlate))
  TriggerClientEvent('tacov:dmv:refresh', src)
end)

-- Halterwechsel: Verkäufer wählt Fahrzeug und Käufer (in der Nähe), Käufer bestätigt und zahlt 100 $
local pending = {} -- [buyerSrc] = { seller = src, vehicleId, plate, at }

RegisterNetEvent('tacov:dmv:transfer:offer', function(vehicleId, target)
  local src = source
  local c = TacoV.Characters.get(src)
  target = tonumber(target)
  local tc = target and TacoV.Characters.get(target)
  if not c or not tc or target == src or not atDesk(src) then return fail(src, 'Der Käufer muss mit dir am Schalter stehen.') end
  if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(target))) > 4.0 then return fail(src, 'Der Käufer muss mit dir am Schalter stehen.') end
  local row = TacoV.DB.single('SELECT id, plate, model FROM vehicles WHERE id = ? AND deleted_at IS NULL AND owner_type = \'character\' AND owner_id = ?', { tonumber(vehicleId) or 0, c.id })
  if not row then return fail(src, 'Das ist nicht dein Fahrzeug.') end
  pending[target] = { seller = src, vehicleId = row.id, plate = row.plate, at = os.time() }
  info(src, ('Angebot an %s %s gesendet – er muss am Schalter bestätigen.'):format(tc.firstName, tc.lastName))
  TriggerClientEvent('tacov:dmv:transfer:ask', target, { plate = row.plate, model = row.model, seller = c.firstName .. ' ' .. c.lastName, fee = Cfg.transferFee })
end)

RegisterNetEvent('tacov:dmv:transfer:accept', function(accept)
  local src = source
  local c = TacoV.Characters.get(src)
  local p = pending[src]
  pending[src] = nil
  if not c or not p then return end
  local sc = TacoV.Characters.get(p.seller)
  if not accept then if sc then info(p.seller, 'Der Käufer hat abgelehnt.') end return end
  if os.time() - p.at > 120 or not sc or not atDesk(src) then return fail(src, 'Das Angebot ist abgelaufen.') end
  local paid = TacoV.Accounts.pay(src, STATE, Cfg.transferFee, 'halterwechsel', p.plate)
  if not paid then return fail(src, ('Nicht genug Guthaben (%s).'):format(fmt(Cfg.transferFee))) end
  TacoV.DB.transaction({
    { 'UPDATE vehicles SET owner_type = \'character\', owner_id = ? WHERE id = ?', { c.id, p.vehicleId } },
    { 'DELETE FROM vehicle_keys WHERE vehicle_id = ?', { p.vehicleId } },
    { 'INSERT INTO vehicle_keys (vehicle_id, character_id, given_by) VALUES (?, ?, ?)', { p.vehicleId, c.id, sc.id } },
  })
  TacoV.Vehicles.reloadKeys(p.seller)
  TacoV.Vehicles.reloadKeys(src)
  TacoV.Log.write('money', ('Halterwechsel %s: #%d -> #%d'):format(p.plate, sc.id, c.id), { characterId = c.id })
  ok(src, ('%s gehört jetzt dir. Schlüssel liegen bei dir.'):format(p.plate))
  ok(p.seller, ('%s wurde auf %s %s umgeschrieben.'):format(p.plate, c.firstName, c.lastName))
end)

-- ---------------------------------------------------------------- Fahrschule

local exams = {} -- [src] = { kind, stage = 'theory'|'practice', questions = {...}, idx, correct, route, point, startedAt }

local function pickQuestions(n)
  local pool = {}
  for i = 1, #Cfg.theory do pool[i] = i end
  for i = #pool, 2, -1 do local j = math.random(i); pool[i], pool[j] = pool[j], pool[i] end
  local out = {}
  for i = 1, math.min(n, #pool) do out[i] = pool[i] end
  return out
end

local function sendQuestion(src)
  local e = exams[src]
  local qi = e.questions[e.idx]
  if not qi then return end
  local q = Cfg.theory[qi]
  TriggerClientEvent('tacov:dmv:theory:question', src, { n = e.idx, total = #e.questions, text = q.q, answers = q.a })
end

RegisterNetEvent('tacov:dmv:school:start', function(kind)
  local src = source
  local c = TacoV.Characters.get(src)
  kind = tostring(kind)
  local def = Cfg.school[kind]
  if not c or not def or not atDesk(src) then return end
  if TacoV.DMV.hasLicense(c.id, kind) then return fail(src, 'Diesen Führerschein hast du schon.') end
  if exams[src] then return fail(src, 'Du bist schon in einer Prüfung.') end
  local tried = TacoV.DB.scalar('SELECT COUNT(*) FROM logs WHERE character_id = ? AND category = \'character\' AND message LIKE ?', { c.id, 'Fahrschule ' .. kind .. '%' }) or 0
  local price = tonumber(tried) > 0 and def.retry or def.price
  local paid = TacoV.Accounts.pay(src, STATE, price, 'fahrschule', def.label)
  if not paid then return fail(src, ('Nicht genug Guthaben (%s).'):format(fmt(price))) end
  TacoV.Log.write('character', ('Fahrschule %s begonnen (%s)'):format(kind, fmt(price)), { characterId = c.id })
  exams[src] = { kind = kind, stage = 'theory', questions = pickQuestions(Cfg.school.theoryQuestions), idx = 1, correct = 0 }
  info(src, ('Theorieprüfung: %d Fragen, %d müssen richtig sein.'):format(Cfg.school.theoryQuestions, Cfg.school.theoryPass))
  sendQuestion(src)
end)

RegisterNetEvent('tacov:dmv:theory:answer', function(answer)
  local src = source
  local e = exams[src]
  if not e or e.stage ~= 'theory' then return end
  local q = Cfg.theory[e.questions[e.idx]]
  if tonumber(answer) == q.r then e.correct = e.correct + 1 end
  e.idx = e.idx + 1
  if e.idx <= #e.questions then return sendQuestion(src) end
  if e.correct < Cfg.school.theoryPass then
    exams[src] = nil
    TriggerClientEvent('tacov:dmv:exam:end', src, false)
    return fail(src, ('Theorie nicht bestanden: %d von %d richtig. Wiederholung kostet %s.'):format(e.correct, #e.questions, fmt(Cfg.school[e.kind].retry)))
  end
  -- Praxis
  local def = Cfg.school[e.kind]
  local route = Cfg.routes[def.route]
  e.stage, e.route, e.point, e.startedAt = 'practice', route, 1, os.time()
  ok(src, ('Theorie bestanden (%d/%d). Jetzt die Praxisfahrt: Kontrollpunkte abfahren, höchstens %d km/h, kein Unfall.'):format(e.correct, #e.questions, Cfg.school.speedLimit))
  TriggerClientEvent('tacov:dmv:practice:start', src, {
    vehicle = def.vehicle, start = route.start, points = route.points,
    speedLimit = Cfg.school.speedLimit, tolerance = Cfg.school.speedTolerance, maxDamage = Cfg.school.maxDamage,
    timeLimit = Cfg.school.timeLimitSeconds, radius = Cfg.school.checkpointRadius,
  })
end)

-- Client meldet erreichten Kontrollpunkt (Server prüft die Position)
RegisterNetEvent('tacov:dmv:practice:checkpoint', function(n)
  local src = source
  local e = exams[src]
  if not e or e.stage ~= 'practice' or tonumber(n) ~= e.point then return end
  local p = e.route.points[e.point]
  if #(GetEntityCoords(GetPlayerPed(src)) - vector3(p.x, p.y, p.z)) > Cfg.school.checkpointRadius + 6.0 then return end
  e.point = e.point + 1
  if e.point > #e.route.points then
    local c = TacoV.Characters.get(src)
    exams[src] = nil
    if os.time() - e.startedAt > Cfg.school.timeLimitSeconds then
      TriggerClientEvent('tacov:dmv:exam:end', src, false)
      return fail(src, 'Zeit überschritten – Prüfung nicht bestanden.')
    end
    TacoV.DMV.grant(c.id, e.kind)
    TacoV.Log.write('character', ('Fahrschule %s bestanden'):format(e.kind), { characterId = c.id })
    TriggerClientEvent('tacov:dmv:exam:end', src, true)
    ok(src, ('Bestanden! Du hast jetzt den %s.'):format(Cfg.school[e.kind].label))
  end
end)

-- Client meldet Abbruch (Unfall, zu schnell, Fahrzeug verlassen)
RegisterNetEvent('tacov:dmv:practice:fail', function(reason)
  local src = source
  local e = exams[src]
  if not e or e.stage ~= 'practice' then return end
  exams[src] = nil
  local c = TacoV.Characters.get(src)
  if c then TacoV.Log.write('character', ('Fahrschule %s nicht bestanden: %s'):format(e.kind, tostring(reason)), { characterId = c.id }) end
  TriggerClientEvent('tacov:dmv:exam:end', src, false)
  fail(src, ('Prüfung nicht bestanden: %s. Wiederholung kostet %s.'):format(tostring(reason), fmt(Cfg.school[e.kind].retry)))
end)

AddEventHandler('playerDropped', function() exams[source] = nil; pending[source] = nil end)
AddEventHandler('tacov:core:characterUnloaded', function(_, characterId) cache[characterId] = nil end)
