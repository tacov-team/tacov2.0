-- Jobs (Phase 8, Server): Schichten, Aufträge, Lohn mit Einkommensteuer, Obergrenze je Stunde, Firmenfahrzeuge.
-- Der Server kennt den Auftrag (Reihenfolge der Punkte) und prüft jede gemeldete Station auf Nähe und Reihenfolge;
-- der Client zeigt nur an und meldet. Lohn entsteht aus dem NPC-Topf (Konzept 3.1), Steuer geht in den Staatshaushalt.
TacoV = TacoV or {}
TacoV.Jobs = {}

local J = TacoV.Config.Jobs          -- Lohn, Obergrenze, Führerschein (config/economy.lua)
local D = TacoV.Config.JobDetails    -- Fahrzeug, Punktart, Werkzeug (config/jobs.lua)
local R = TacoV.Config.JobRules
local STATE = { type = 'state', id = 0 }

local active = {}   -- [src] = { job, sessionId, step, steps, orders, earned, plate, netId, logs, fares }

local function notify(src, kind, text) TriggerClientEvent('tacov:core:notify', src, kind, text) end
local function incomeTaxPercent() return (TacoV.Config.Economy.tax.income.default or 8) end
local function fmt(n) return (tostring(math.floor(n or 0)):reverse():gsub('(%d%d%d)', '%1.'):reverse():gsub('^%.', '')) end
local function pedPos(src) return GetEntityCoords(GetPlayerPed(src)) end
local function near(src, p, r) return #(pedPos(src) - vector3(p.x, p.y, p.z)) <= (r or R.pointRadius) end

local function pointsOf(kind)
  local out = {}
  for _, l in ipairs(TacoV.Locations.all()) do
    if l.kind == kind or (kind == 'shop' and l.kind == 'address') then out[#out + 1] = l end
  end
  return out
end
local function jobLocation(job)
  for _, l in ipairs(TacoV.Locations.all()) do if l.kind == 'job' and l.job == job then return l end end
  return nil
end

--- Verdienst der letzten Stunde (Obergrenze gilt je Job)
local function earnedLastHour(characterId, job)
  return tonumber(TacoV.DB.scalar('SELECT COALESCE(SUM(amount + tax), 0) FROM job_pay WHERE character_id = ? AND job = ? AND paid_at > DATE_SUB(NOW(), INTERVAL ? SECOND)',
    { characterId, job, R.capLookbackSeconds })) or 0
end
local function capResetMinutes(characterId, job)
  local row = TacoV.DB.single('SELECT TIMESTAMPDIFF(SECOND, NOW(), DATE_ADD(MIN(paid_at), INTERVAL ? SECOND)) AS s FROM job_pay ' ..
    'WHERE character_id = ? AND job = ? AND paid_at > DATE_SUB(NOW(), INTERVAL ? SECOND)', { R.capLookbackSeconds, characterId, job, R.capLookbackSeconds })
  return row and tonumber(row.s) and math.max(1, math.ceil(tonumber(row.s) / 60)) or 1
end

--- Lohn auszahlen: brutto aus dem NPC-Topf, Steuer an den Staat, netto aufs Konto. Beendet den Job, wenn die Obergrenze erreicht ist.
local function pay(src, gross, note)
  local a = active[src]
  local c = TacoV.Characters.get(src)
  if not a or not c then return end
  gross = TacoV.Util.money(gross)
  local tax = TacoV.Util.money(gross * incomeTaxPercent() / 100)
  local net = gross - tax
  TacoV.Journal.move('bank', nil, { type = 'character', id = c.id }, net, 'lohn', { actor = c.id, note = note })
  if tax > 0 then TacoV.Journal.move('bank', nil, STATE, tax, 'steuer', { actor = c.id, note = 'Einkommensteuer ' .. note }) end
  TacoV.DB.insert('INSERT INTO job_pay (character_id, job, amount, tax, note) VALUES (?, ?, ?, ?, ?)', { c.id, a.job, net, tax, note })
  a.orders, a.earned = a.orders + 1, a.earned + net
  TacoV.DB.update('UPDATE job_sessions SET orders = ?, earned = ? WHERE id = ?', { a.orders, a.earned, a.sessionId })
  TacoV.Accounts.push(src)
  notify(src, 'success', ('%s: %s $ (netto, %d %% Steuer abgezogen).'):format(note, fmt(net), incomeTaxPercent()))
  TacoV.Log.write('money', ('Lohn %s: %s $ netto, %s $ Steuer (%s)'):format(c.first_name .. ' ' .. c.last_name, fmt(net), fmt(tax), note), { characterId = c.id })
  if earnedLastHour(c.id, a.job) >= J[a.job].hourlyCap then
    local mins = capResetMinutes(c.id, a.job)
    TacoV.Jobs.stop(src, 'cap')
    notify(src, 'warn', ('Obergrenze von %s $ je Stunde erreicht – Feierabend. In %d min geht es weiter.'):format(fmt(J[a.job].hourlyCap), mins))
  end
end

-- ---------------------------------------------------------------- Aufträge je Job

local function shuffle(list, n)
  local copy = {}
  for i, v in ipairs(list) do copy[i] = v end
  for i = #copy, 2, -1 do local k = math.random(i) copy[i], copy[k] = copy[k], copy[i] end
  local out = {}
  for i = 1, math.min(n or #copy, #copy) do out[i] = copy[i] end
  return out
end

local function stepsFor(job)
  local hof = jobLocation(job)
  local pts = pointsOf(D[job].points)
  local steps = {}
  if job == 'garbage' then
    local n = math.min(R.trashPerRoute, #pts)
    for i, p in ipairs(shuffle(pts, n)) do
      steps[#steps + 1] = { kind = 'trash', label = ('Container %d/%d: Müllsack holen'):format(i, n), x = p.x, y = p.y, z = p.z, needVehicle = true, farVehicle = true }
      steps[#steps + 1] = { kind = 'dump', label = 'Müllsack in den Müllwagen werfen', vehicle = true }
    end
    steps[#steps + 1] = { kind = 'return', label = 'Zurück zum Müllhof', x = hof.x, y = hof.y, z = hof.z, needVehicle = true, pay = J.garbage.pay, note = 'Müllroute' }
  elseif job == 'delivery' then
    local n = math.random(R.deliveryMin, R.deliveryMax)
    local nearby = {}
    for _, p in ipairs(pts) do if #(vector3(p.x, p.y, p.z) - vector3(hof.x, hof.y, hof.z)) <= 3000.0 then nearby[#nearby + 1] = p end end
    if #nearby >= n then pts = nearby end
    for i, p in ipairs(shuffle(pts, n)) do steps[#steps + 1] = { kind = 'deliver', label = ('Paket %d/%d abgeben'):format(i, n), x = p.x, y = p.y, z = p.z, needVehicle = true } end
    local lo, hi = J.delivery.pay[1], J.delivery.pay[2]
    local payAmt = lo + (hi - lo) * (n - R.deliveryMin) / math.max(1, R.deliveryMax - R.deliveryMin)
    steps[#steps + 1] = { kind = 'return', label = 'Zurück zum Depot', x = hof.x, y = hof.y, z = hof.z, needVehicle = true, pay = payAmt, note = ('Liefertour (%d Pakete)'):format(n) }
  elseif job == 'bus' then
    table.sort(pts, function(a, b) return a.name < b.name end)
    for i, p in ipairs(pts) do steps[#steps + 1] = { kind = 'stop', label = ('Haltestelle %d/%d'):format(i, #pts), x = p.x, y = p.y, z = p.z, needVehicle = true, driving = true } end
    steps[#steps + 1] = { kind = 'return', label = 'Zurück zum Depot', x = hof.x, y = hof.y, z = hof.z, needVehicle = true, pay = J.bus.pay, note = 'Buslinie' }
  elseif job == 'lumber' then
    for i, p in ipairs(shuffle(pts, R.logsPerTrip)) do
      steps[#steps + 1] = { kind = 'chop', label = ('Baum %d/%d fällen'):format(i, R.logsPerTrip), x = p.x, y = p.y, z = p.z, seconds = R.chopSeconds }
      steps[#steps + 1] = { kind = 'load', label = 'Stamm aufladen', vehicle = true }
    end
    steps[#steps + 1] = { kind = 'return', label = 'Stämme am Sägewerk abliefern', x = hof.x, y = hof.y, z = hof.z, needVehicle = true, pay = J.lumber.pay, note = 'Holzlieferung' }
  elseif job == 'mining' then
    for i, p in ipairs(shuffle(pts, R.orePerTrip)) do
      steps[#steps + 1] = { kind = 'mine', label = ('Erz %d/%d abbauen'):format(i, R.orePerTrip), x = p.x, y = p.y, z = p.z, seconds = R.chopSeconds }
    end
    steps[#steps + 1] = { kind = 'sell', label = 'Erz beim Händler verkaufen', x = hof.x, y = hof.y, z = hof.z, pay = J.mining.pay, note = 'Erzverkauf' }
  elseif job == 'taxi' then
    steps[#steps + 1] = { kind = 'taxi', label = 'Fahrgäste befördern (F4 → Fahrgast suchen)' }
  end
  return steps
end

local function publicState(a)
  if not a then return false end
  local s = a.steps[a.step]
  return { job = a.job, label = J[a.job].label, step = a.step, total = #a.steps, current = s, plate = a.plate, logs = a.logs, orders = a.orders, earned = a.earned }
end
local function push(src) TriggerClientEvent('tacov:jobs:state', src, publicState(active[src])) end

local function nextStep(src)
  local a = active[src]
  a.step = a.step + 1
  if a.step > #a.steps then
    -- neue Runde, gleicher Job
    a.steps = stepsFor(a.job)
    a.step = 1
    a.logs = 0
  end
  push(src)
end

-- ---------------------------------------------------------------- Start / Stop

function TacoV.Jobs.start(src, job)
  local c = TacoV.Characters.get(src)
  local def = J[job]
  if not c or not def then return false end
  if active[src] then notify(src, 'error', ('Du arbeitest schon als %s. Erst Feierabend machen.'):format(J[active[src].job].label)) return false end
  if def.license and not TacoV.DMV.hasLicense(c.id, def.license) then
    notify(src, 'error', ('Dafür brauchst du den Führerschein Klasse %s.'):format(def.license)) return false
  end
  local tool = D[job].tool
  if tool then
    local inv = TacoV.Inventory.ofSource(src)
    if not inv or not TacoV.Inventory.has(inv, tool, 1) then
      notify(src, 'error', ('Ohne %s geht hier nichts – gibt es im Baumarkt.'):format(TacoV.Config.Items[tool].label)) return false
    end
  end
  if earnedLastHour(c.id, job) >= def.hourlyCap then
    notify(src, 'warn', ('Für heute ist die Stunde voll (%s $). Komm in %d min wieder.'):format(fmt(def.hourlyCap), capResetMinutes(c.id, job))) return false
  end
  local id = TacoV.DB.insert('INSERT INTO job_sessions (character_id, job) VALUES (?, ?)', { c.id, job })
  active[src] = { job = job, sessionId = id, step = 1, steps = stepsFor(job), orders = 0, earned = 0, logs = 0, fares = {} }
  TacoV.Log.write('money', ('Schicht begonnen: %s (%s)'):format(def.label, c.first_name .. ' ' .. c.last_name), { characterId = c.id })
  notify(src, 'success', ('Schicht als %s begonnen.%s'):format(def.label, D[job].vehicle and ' Das Fahrzeug bekommst du am Hof.' or ''))
  push(src)
  return true
end

function TacoV.Jobs.stop(src, reason)
  local a = active[src]
  if not a then return end
  active[src] = nil
  TacoV.DB.update('UPDATE job_sessions SET ended_at = NOW(), end_reason = ? WHERE id = ?', { reason or 'manual', a.sessionId })
  if a.netId then
    local ent = NetworkGetEntityFromNetworkId(a.netId)
    if ent ~= 0 and DoesEntityExist(ent) then DeleteEntity(ent) end
  end
  TriggerClientEvent('tacov:jobs:state', src, false)
  if reason ~= 'cap' then notify(src, 'info', ('Feierabend: %d Aufträge, %s $ verdient.'):format(a.orders, fmt(a.earned))) end
end

RegisterNetEvent('tacov:jobs:start', function(job)
  local src = source
  local loc = jobLocation(job)
  local center = TacoV.Locations.get('jobcenter')
  if not loc or not ((near(src, loc, 8.0)) or (center and near(src, center, 8.0))) then return end
  TacoV.Jobs.start(src, job)
end)
RegisterNetEvent('tacov:jobs:stop', function() TacoV.Jobs.stop(source, 'manual') end)

-- Übersicht für Jobcenter und Hof: Jobs mit Lohn, Obergrenze, Voraussetzung und eigenem Stand
RegisterNetEvent('tacov:jobs:info', function(where, hofJob)
  local src = source
  local c = TacoV.Characters.get(src)
  if not c then return end
  local list = {}
  for id, def in pairs(J) do
    local payText = type(def.pay) == 'table' and ('%d–%d $'):format(def.pay[1], def.pay[2]) or (def.pay == 'meter' and 'Taxameter' or (def.pay .. ' $'))
    list[#list + 1] = { id = id, label = def.label, pay = payText, cap = def.hourlyCap, license = def.license, tool = D[id].tool,
      desc = D[id].desc, icon = D[id].icon, hasLicense = not def.license or TacoV.DMV.hasLicense(c.id, def.license),
      earned = earnedLastHour(c.id, id) }
  end
  table.sort(list, function(a, b) return a.label < b.label end)
  TriggerClientEvent('tacov:jobs:menu', src, where, list, publicState(active[src]), where == 'hof' and J[hofJob] and hofJob or nil)
end)

-- ---------------------------------------------------------------- Firmenfahrzeug

RegisterNetEvent('tacov:jobs:vehicle', function()
  local src = source
  local a = active[src]
  if not a then return end
  local model = D[a.job].vehicle
  local loc = jobLocation(a.job)
  if not model or not loc or not loc.spawn then notify(src, 'info', 'Für diesen Job gibt es kein Fahrzeug.') return end
  if not near(src, loc, 25.0) then notify(src, 'error', 'Das Fahrzeug gibt es nur am Hof.') return end
  if a.netId then
    local ent = NetworkGetEntityFromNetworkId(a.netId)
    if ent ~= 0 and DoesEntityExist(ent) then notify(src, 'info', ('Dein Fahrzeug (%s) steht schon bereit.'):format(a.plate)) return end
  end
  a.plate = ('JOB %03d'):format(math.random(0, 999))
  TriggerClientEvent('tacov:jobs:spawnVehicle', src, { model = model, plate = a.plate, spawn = loc.spawn })
end)
RegisterNetEvent('tacov:jobs:vehicleSpawned', function(netId)
  local src = source
  local a = active[src]
  if not a then return end
  local ent = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
  if ent == 0 or not DoesEntityExist(ent) then return end
  a.netId = tonumber(netId)
  push(src)
end)

local function vehicleNear(src, a, radius)
  if not a.netId then return false end
  local ent = NetworkGetEntityFromNetworkId(a.netId)
  if ent == 0 or not DoesEntityExist(ent) then return false end
  return #(GetEntityCoords(ent) - pedPos(src)) <= (radius or R.vehicleRadius), ent
end
local function drivingJobVehicle(src, a)
  if not a.netId then return false end
  local ent = NetworkGetEntityFromNetworkId(a.netId)
  if ent == 0 or not DoesEntityExist(ent) then return false end
  return GetPedInVehicleSeat(ent, -1) == GetPlayerPed(src), ent
end

-- ---------------------------------------------------------------- Stationen melden

RegisterNetEvent('tacov:jobs:step', function(d)
  local src = source
  local a = active[src]
  local c = TacoV.Characters.get(src)
  if not a or not c or type(d) ~= 'table' then return end
  local s = a.steps[a.step]
  if not s or d.kind ~= s.kind then return end
  local snapped = R.snap[s.kind] ~= nil -- Punkt darf im Spiel auf das nächste echte Objekt gesprungen sein
  if s.x and not near(src, s, snapped and (R.snapRadius + 10.0) or (R.pointRadius + 4.0)) then notify(src, 'error', 'Du bist nicht am richtigen Punkt.') return end
  if s.needVehicle and not vehicleNear(src, a, (s.kind == 'return' or s.farVehicle) and 40.0 or R.vehicleRadius) then
    notify(src, 'error', 'Dein Firmenfahrzeug muss dabei sein.') return
  end
  if s.driving and not drivingJobVehicle(src, a) then notify(src, 'error', 'Du musst den Bus fahren.') return end
  if s.kind == 'load' or s.kind == 'dump' then
    if not vehicleNear(src, a, 8.0) then notify(src, 'error', 'Der Wagen steht zu weit weg.') return end
    if s.kind == 'load' then a.logs = (a.logs or 0) + 1 end
  elseif s.kind == 'mine' or s.kind == 'chop' then
    local tool = D[a.job].tool
    local inv = TacoV.Inventory.ofSource(src)
    if tool and not (inv and TacoV.Inventory.has(inv, tool, 1)) then notify(src, 'error', 'Werkzeug fehlt.') TacoV.Jobs.stop(src, 'tool') return end
    if s.kind == 'mine' then
      local ok = TacoV.Inventory.add(inv, 'ore', 1)
      if not ok then notify(src, 'error', 'Deine Taschen sind voll.') return end
      TacoV.Inventory.send(src)
    end
  elseif s.kind == 'sell' then
    local inv = TacoV.Inventory.ofSource(src)
    local count = inv and TacoV.Inventory.count(inv, 'ore') or 0
    if count <= 0 then notify(src, 'error', 'Du hast kein Erz dabei.') return end
    TacoV.Inventory.remove(inv, 'ore', count)
    TacoV.Inventory.send(src)
    pay(src, J.mining.pay * count / R.orePerTrip, ('Erzverkauf (%d Erz)'):format(count))
    if not active[src] then return end
    nextStep(src)
    return
  elseif s.kind == 'return' and a.job == 'lumber' and (a.logs or 0) < R.logsPerTrip then
    notify(src, 'error', ('Erst %d Stämme aufladen.'):format(R.logsPerTrip)) return
  end
  if s.pay then
    pay(src, s.pay, s.note)
    if not active[src] then return end
  end
  nextStep(src)
end)

-- ---------------------------------------------------------------- Taxi

-- NPC-Fahrgast anfordern: Abholpunkt und Ziel aus dem Adresspool (Abholung mindestens 300 m entfernt)
RegisterNetEvent('tacov:jobs:taxi:npc', function()
  local src = source
  local a = active[src]
  if not a or a.job ~= 'taxi' then return end
  if a.fares.npc then notify(src, 'info', 'Du hast schon einen Fahrgast.') return end
  if not drivingJobVehicle(src, a) then notify(src, 'error', 'Setz dich erst ins Taxi.') return end
  local pts = pointsOf('shop')
  local me = pedPos(src)
  local far = {}
  for _, p in ipairs(pts) do
    local d = #(me - vector3(p.x, p.y, p.z))
    if d > 300.0 and d < 4000.0 then far[#far + 1] = p end
  end
  if #far < 2 then return end
  local pick = shuffle(far, 2)
  a.fares.npc = { pickup = pick[1], dest = pick[2], at = os.time() }
  TriggerClientEvent('tacov:jobs:taxi:npc', src, { pickup = { x = pick[1].x, y = pick[1].y, z = pick[1].z }, dest = { x = pick[2].x, y = pick[2].y, z = pick[2].z } })
end)

-- Fahrt abrechnen: passenger = Server-ID eines Spielers oder 0 für den NPC-Fahrgast; meters vom Client (plausibilisiert über die Zeit)
RegisterNetEvent('tacov:jobs:taxi:fare', function(phase, passenger, meters)
  local src = source
  local a = active[src]
  local c = TacoV.Characters.get(src)
  if not a or not c or a.job ~= 'taxi' then return end
  passenger = tonumber(passenger) or 0
  local ok, veh = drivingJobVehicle(src, a)
  if phase == 'start' then
    if passenger == 0 then return end
    if not ok then return end
    local pped = GetPlayerPed(passenger)
    if pped == 0 or GetVehiclePedIsIn(pped, false) ~= veh then return end
    a.fares[passenger] = { at = os.time() }
    notify(src, 'info', 'Fahrgast eingestiegen – Taxameter läuft.')
    notify(passenger, 'info', ('Taxameter: %d $ Grundpreis + %.2f $ je 100 m.'):format(R.taxiBase, R.taxiPer100m))
    return
  end
  if phase ~= 'end' then return end
  local fare = a.fares[passenger == 0 and 'npc' or passenger]
  if not fare then return end
  a.fares[passenger == 0 and 'npc' or passenger] = nil
  local secs = math.max(1, os.time() - fare.at)
  meters = math.max(0, math.min(tonumber(meters) or 0, secs * R.taxiMaxSpeed))
  if passenger == 0 and fare.dest and not near(src, fare.dest, 25.0) then notify(src, 'warn', 'Der Fahrgast wollte woanders hin – keine Bezahlung.') return end
  local price = TacoV.Util.money(R.taxiBase + meters / 100 * R.taxiPer100m)
  if passenger == 0 then
    pay(src, price, ('Taxifahrt (%d m)'):format(meters))
    return
  end
  local pc = TacoV.Characters.get(passenger)
  if not pc then return end
  local tax = TacoV.Util.money(price * incomeTaxPercent() / 100)
  local moved = TacoV.Journal.move('bank', { type = 'character', id = pc.id }, { type = 'character', id = c.id }, price - tax, 'taxi',
    { actor = pc.id, note = ('Taxi %d m'):format(meters), allowNegative = true })
  if not moved then return end
  if tax > 0 then TacoV.Journal.move('bank', { type = 'character', id = pc.id }, STATE, tax, 'steuer', { actor = pc.id, note = 'Einkommensteuer Taxi' }) end
  TacoV.DB.insert('INSERT INTO job_pay (character_id, job, amount, tax, note) VALUES (?, ?, ?, ?, ?)', { c.id, 'taxi', price - tax, tax, 'Taxifahrt Spieler' })
  a.orders, a.earned = a.orders + 1, a.earned + (price - tax)
  TacoV.Accounts.push(src) TacoV.Accounts.push(passenger)
  notify(src, 'success', ('Fahrpreis %s $ erhalten (%s $ netto).'):format(fmt(price), fmt(price - tax)))
  notify(passenger, 'info', ('Taxi bezahlt: %s $.'):format(fmt(price)))
  if earnedLastHour(c.id, 'taxi') >= J.taxi.hourlyCap then
    TacoV.Jobs.stop(src, 'cap')
    notify(src, 'warn', 'Obergrenze je Stunde erreicht – Feierabend.')
  end
end)

-- Taxi rufen (F4): alle Taxifahrer im Dienst bekommen Hinweis und Wegpunkt
RegisterNetEvent('tacov:jobs:taxi:call', function()
  local src = source
  local c = TacoV.Characters.get(src)
  if not c then return end
  local pos = pedPos(src)
  local n = 0
  for s, a in pairs(active) do
    if a.job == 'taxi' and s ~= src then
      n = n + 1
      TriggerClientEvent('tacov:jobs:taxi:request', s, { x = pos.x, y = pos.y, name = c.first_name .. ' ' .. c.last_name })
    end
  end
  notify(src, n > 0 and 'success' or 'info', n > 0 and ('%d Taxifahrer benachrichtigt.'):format(n) or 'Gerade ist kein Taxi im Dienst.')
end)

-- ---------------------------------------------------------------- Aufräumen

AddEventHandler('tacov:core:characterUnloaded', function(src) if active[src] then TacoV.Jobs.stop(src, 'disconnect') end end)
AddEventHandler('playerDropped', function() local src = source if active[src] then TacoV.Jobs.stop(src, 'disconnect') end end)

function TacoV.Jobs.activeJob(src) return active[src] and active[src].job or nil end
