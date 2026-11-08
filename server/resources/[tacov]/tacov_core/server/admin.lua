-- Admin-Grundgerüst (Punkt 5.1): Unsichtbar, Noclip, Teleport. Jede Aktion prüft Rechte (nur im Admin-Dienst), setzt
-- den Zustand als Statebag (damit alle Clients ihn sehen) und schreibt ins Log `admin`.
TacoV = TacoV or {}
TacoV.Admin = {}

local state = {} -- [src] = { invisible = bool, noclip = bool }

local function notify(src, kind, text) TriggerClientEvent('tacov:core:notify', src, kind, text) end
local function who(src)
  local p = TacoV.Players.get(src)
  local c = TacoV.Characters.get(src)
  return p, c, c and (c.first_name .. ' ' .. c.last_name) or ('#' .. src)
end
local function log(src, text)
  local p, c = who(src)
  TacoV.Log.write('admin', text, { discordId = p and p.discordId, characterId = c and c.id })
end
local function need(src, right)
  if TacoV.Permissions.has(src, right) then return true end
  notify(src, 'error', 'Dafür fehlt dir das Recht (oder du bist nicht im Admin-Dienst).')
  return false
end

function TacoV.Admin.state(src)
  state[src] = state[src] or { invisible = false, noclip = false }
  return state[src]
end

local function set(src, key, on)
  local s = TacoV.Admin.state(src)
  s[key] = on and true or false
  Player(src).state:set('admin_' .. key, s[key], true)
  TriggerClientEvent('tacov:admin:state', src, s)
end

--- Alles zurücksetzen (Dienstende, Verbindungsabbruch)
function TacoV.Admin.reset(src)
  if not state[src] then return end
  if state[src].invisible then set(src, 'invisible', false) end
  if state[src].noclip then set(src, 'noclip', false) end
  state[src] = nil
end

local function toggle(src, key)
  if key == 'invisible' then
    if not need(src, 'support.invisible') then return end
  elseif key == 'noclip' then
    if not need(src, 'admin.noclip') then return end
  else return end
  local s = TacoV.Admin.state(src)
  set(src, key, not s[key])
  log(src, ('%s %s'):format(key == 'invisible' and 'Unsichtbar' or 'Noclip', s[key] and 'an' or 'aus'))
end
RegisterNetEvent('tacov:admin:toggle', function(key) toggle(source, key) end)

-- Teleport: mode = 'player' (zu Spieler), 'bring' (Spieler herholen), 'waypoint' (Wegpunkt), 'coords' (x y z)
local function teleport(src, mode, a, b, c)
  if not need(src, 'support.teleport') then return end
  local _, _, me = who(src)
  if mode == 'player' or mode == 'bring' then
    local target = tonumber(a)
    if not target or not TacoV.Players.get(target) or target == src then notify(src, 'error', 'Spieler nicht gefunden.') return end
    local _, _, other = who(target)
    local fromPed, toPed = GetPlayerPed(mode == 'player' and src or target), GetPlayerPed(mode == 'player' and target or src)
    local pos = GetEntityCoords(toPed)
    TriggerClientEvent('tacov:admin:setCoords', mode == 'player' and src or target, pos.x, pos.y, pos.z, GetEntityHeading(toPed))
    if mode == 'bring' then notify(target, 'warn', ('Du wurdest von %s (Team) geholt.'):format(me)) end
    notify(src, 'info', mode == 'player' and ('Teleportiert zu %s.'):format(other) or ('%s hergeholt.'):format(other))
    log(src, ('%s %s (#%d) · von %.1f %.1f %.1f'):format(mode == 'player' and 'Teleport zu' or 'Hergeholt:', other, target,
      GetEntityCoords(fromPed).x, GetEntityCoords(fromPed).y, GetEntityCoords(fromPed).z))
  elseif mode == 'coords' then
    local x, y, z = tonumber(a), tonumber(b), tonumber(c)
    if not x or not y then notify(src, 'error', 'Nutzung: /tp <x> <y> [z]') return end
    TriggerClientEvent('tacov:admin:setCoords', src, x, y, z or -1.0, nil)
    log(src, ('Teleport zu %.1f %.1f %s'):format(x, y, z and ('%.1f'):format(z) or 'Boden'))
  elseif mode == 'waypoint' then
    TriggerClientEvent('tacov:admin:toWaypoint', src)
    log(src, 'Teleport zum Wegpunkt')
  end
end
RegisterNetEvent('tacov:admin:teleport', function(mode, a, b, c) teleport(source, mode, a, b, c) end)

-- Spielerliste für das Team-Menü (nur im Dienst; Name und Server-ID, keine internen Daten)
RegisterNetEvent('tacov:admin:players', function()
  local src = source
  if not TacoV.Permissions.onDuty(src) then return end
  local list = {}
  for id in pairs(TacoV.Players.all()) do
    local _, c, name = who(id)
    list[#list + 1] = { id = id, name = name, char = c ~= nil, dist = #(GetEntityCoords(GetPlayerPed(id)) - GetEntityCoords(GetPlayerPed(src))) }
  end
  table.sort(list, function(x, y) return x.id < y.id end)
  TriggerClientEvent('tacov:admin:players', src, list)
end)

AddEventHandler('tacov:core:dutyOff', function(src) TacoV.Admin.reset(src) end)
AddEventHandler('playerDropped', function() state[source] = nil end)

-- ---------------------------------------------------------------- Team-Menü: Akte und Aktionen (Punkt 5.2)

local function fmt(n)
  local out = tostring(math.floor(n or 0)):reverse():gsub('(%d%d%d)', '%1.'):reverse()
  if out:sub(1, 1) == '.' then out = out:sub(2) end
  return out .. ' $'
end

RegisterNetEvent('tacov:admin:file', function(target)
  local src = source
  if not need(src, 'support.view') then return end
  target = tonumber(target)
  local p, c, name = who(target)
  if not p then notify(src, 'error', 'Spieler nicht gefunden.') return end
  local warns = TacoV.DB.scalar('SELECT COUNT(*) FROM warnings WHERE discord_id = ?', { p.discordId }) or 0
  local bans = TacoV.DB.scalar('SELECT COUNT(*) FROM bans WHERE discord_id = ?', { p.discordId }) or 0
  local lastWarn = TacoV.DB.single('SELECT reason, issued_at FROM warnings WHERE discord_id = ? ORDER BY id DESC LIMIT 1', { p.discordId })
  local pub = c and TacoV.Characters.publicData(target)
  TriggerClientEvent('tacov:admin:file', src, {
    id = target, name = name, discordId = p.discordId, role = (TacoV.Config.Roles[p.role] or {}).label or p.role,
    characterId = c and c.id, level = pub and pub.level, playtimeHours = pub and math.floor(pub.playtimeSeconds / 3600),
    faction = c and c.faction, factionRank = c and c.faction_rank,
    bank = pub and fmt(pub.bank), cash = c and fmt(TacoV.Inventory.cash(TacoV.Inventory.ofSource(target))),
    warns = warns, bans = bans, lastWarn = lastWarn and (lastWarn.reason .. ' · ' .. tostring(lastWarn.issued_at):sub(1, 10)),
    licenses = c and TacoV.DMV.licenses(c.id) or nil,
  })
end)

RegisterNetEvent('tacov:admin:heal', function(target)
  local src = source
  if not need(src, 'support.heal') then return end
  target = tonumber(target)
  if not TacoV.Players.get(target) then return end
  TriggerClientEvent('tacov:admin:healed', target)
  if TacoV.Characters.get(target) then
    TacoV.Needs.add(target, 'hunger', 100)
    TacoV.Needs.add(target, 'thirst', 100)
  end
  local _, _, name = who(target)
  notify(src, 'success', ('%s geheilt.'):format(name))
  notify(target, 'info', 'Du wurdest vom Team geheilt.')
  log(src, ('Geheilt: %s (#%d)'):format(name, target))
end)

--- Geld geben (Journal/Inventar), auch von /geld genutzt
function TacoV.Admin.giveMoney(src, target, amount, kind)
  local tc = TacoV.Characters.get(target)
  if not tc or not amount or amount <= 0 then return false end
  local okMove
  if kind == 'cash' then
    okMove = TacoV.Inventory.addCash(target, amount, 'teamgeld')
  else
    local actor = src ~= 0 and TacoV.Characters.get(src)
    okMove = TacoV.Journal.move('bank', nil, { type = 'character', id = tc.id }, amount, 'teamgeld', { actor = actor and actor.id or nil })
    if okMove then TacoV.Accounts.push(target) end
  end
  if okMove then
    log(src, ('Geld gegeben: %s (%s) an #%d'):format(fmt(amount), kind, tc.id))
    notify(target, 'info', ('Das Team hat dir %s (%s) gegeben.'):format(fmt(amount), kind == 'cash' and 'bar' or 'Konto'))
  end
  return okMove
end

RegisterNetEvent('tacov:admin:give', function(target, kind, a, b)
  local src = source
  target = tonumber(target)
  local _, tc, name = who(target)
  if not TacoV.Players.get(target) then notify(src, 'error', 'Spieler nicht gefunden.') return end
  if kind == 'money' then
    if not need(src, 'admin.give') then return end
    local okMove = TacoV.Admin.giveMoney(src, target, tonumber(a), b == 'cash' and 'cash' or 'bank')
    notify(src, okMove and 'success' or 'error', okMove and ('%s an %s gegeben.'):format(fmt(tonumber(a)), name) or 'Buchung fehlgeschlagen.')
  elseif kind == 'item' then
    if not need(src, 'admin.give') then return end
    local def = TacoV.Config.Items[tostring(a)]
    local amount = math.floor(tonumber(b) or 1)
    if not def or amount < 1 or not tc then notify(src, 'error', 'Item oder Spieler ungültig.') return end
    local okAdd = TacoV.Inventory.add(TacoV.Inventory.ofSource(target), def.name, amount)
    if okAdd then
      TacoV.Inventory.send(target)
      notify(target, 'info', ('Das Team hat dir %dx %s gegeben.'):format(amount, def.label))
      log(src, ('Item gegeben: %dx %s an %s (#%d)'):format(amount, def.name, name, target))
    end
    notify(src, okAdd and 'success' or 'error', okAdd and ('%dx %s an %s gegeben.'):format(amount, def.label, name) or 'Kein Platz im Inventar.')
  elseif kind == 'vehicle' then
    if not need(src, 'admin.vehicle.spawn') then return end
    local okGrant, info = TacoV.Vehicles.grant(target, tostring(a))
    if okGrant then
      notify(target, 'info', ('Das Team hat dir ein Fahrzeug gegeben: %s.'):format(info))
      log(src, ('Fahrzeug gegeben: %s an %s (#%d)'):format(info, name, target))
    end
    notify(src, okGrant and 'success' or 'error', okGrant and ('%s an %s gegeben.'):format(info, name) or tostring(info))
  end
end)

local function punish(src, action, target, reason, hours)
  target = tonumber(target)
  local p, c, name = who(target)
  if not p then notify(src, 'error', 'Spieler nicht gefunden.') return end
  reason = TacoV.Util.cleanText(reason or '', 255)
  if #reason < 2 then notify(src, 'error', 'Bitte einen Grund angeben.') return end
  local actor = TacoV.Players.get(src)
  local by = actor and actor.discordId or 'console'
  if action == 'warn' then
    if not need(src, 'admin.warn') then return end
    TacoV.DB.insert('INSERT INTO warnings (discord_id, character_id, reason, issued_by) VALUES (?, ?, ?, ?)', { p.discordId, c and c.id, reason, by })
    local count = TacoV.DB.scalar('SELECT COUNT(*) FROM warnings WHERE discord_id = ?', { p.discordId }) or 1
    TriggerClientEvent('tacov:core:notify', target, 'error', ('Verwarnung (%d.) vom Team: %s'):format(count, reason))
    notify(src, 'success', ('%s verwarnt (%d. Verwarnung).'):format(name, count))
    log(src, ('Verwarnung an %s (#%d): %s'):format(name, target, reason))
  elseif action == 'kick' then
    if not need(src, 'admin.kick') then return end
    log(src, ('Kick: %s (#%d), Grund: %s'):format(name, target, reason))
    notify(src, 'success', ('%s gekickt.'):format(name))
    DropPlayer(target, 'Vom Team entfernt: ' .. reason)
  elseif action == 'ban' then
    hours = tonumber(hours) or 0
    local right = (hours > 0 and hours <= TacoV.Config.Permissions.banTempMaxHours) and 'admin.ban.temp' or 'admin.ban'
    if not need(src, right) then return end
    if hours > 0 then
      TacoV.DB.insert('INSERT INTO bans (discord_id, reason, issued_by, until_at) VALUES (?, ?, ?, DATE_ADD(NOW(), INTERVAL ? HOUR))', { p.discordId, reason, by, hours })
    else
      TacoV.DB.insert('INSERT INTO bans (discord_id, reason, issued_by, until_at) VALUES (?, ?, ?, NULL)', { p.discordId, reason, by })
    end
    log(src, ('Sperre: %s (#%d) %s, Grund: %s'):format(name, target, hours > 0 and (hours .. ' h') or 'dauerhaft', reason))
    notify(src, 'success', ('%s gesperrt (%s).'):format(name, hours > 0 and (hours .. ' h') or 'dauerhaft'))
    DropPlayer(target, TacoV.Config.Whitelist.bannedMessage:format(reason))
  end
end
RegisterNetEvent('tacov:admin:punish', function(action, target, reason, hours) punish(source, action, target, reason, hours) end)

RegisterCommand('warn', function(src, args)
  if src == 0 then return end
  punish(src, 'warn', args[1], table.concat(args, ' ', 2))
end, false)

-- ---------------------------------------------------------------- Fahrzeuge (5.10): Rechte prüfen, protokollieren, Client führt aus

local function trimPlate(s) return (tostring(s or ''):gsub('^%s+', ''):gsub('%s+$', '')) end

RegisterNetEvent('tacov:admin:vehicle', function(action, netId, a, b)
  local src = source
  local right = action == 'spawn' and 'admin.vehicle.spawn' or 'admin.vehicle'
  if not need(src, right) then return end
  if action == 'spawn' then
    local model = TacoV.Util.cleanText(tostring(a or ''), 32):lower():gsub('[^%w_]', '')
    if #model == 0 then return end
    local plate = ('TEAM %03d'):format(math.random(0, 999))
    TriggerClientEvent('tacov:admin:vehicle:do', src, 'spawn', 0, model, plate)
    log(src, ('Team-Fahrzeug gespawnt: %s (%s)'):format(model, plate))
    return
  end
  local ent = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
  if ent == 0 or not DoesEntityExist(ent) then notify(src, 'error', 'Kein Fahrzeug.') return end
  local plate = trimPlate(GetVehicleNumberPlateText(ent))
  if action == 'plate' then
    local newPlate = TacoV.Util.cleanText(tostring(a or ''), 8):upper()
    if #newPlate < 2 then notify(src, 'error', 'Kennzeichen zu kurz.') return end
    if TacoV.DB.scalar('SELECT id FROM vehicles WHERE plate = ?', { newPlate }) then notify(src, 'error', 'Kennzeichen schon vergeben.') return end
    local row = TacoV.DB.single('SELECT id FROM vehicles WHERE plate = ? AND deleted_at IS NULL', { plate })
    if row then
      TacoV.DB.update('UPDATE vehicles SET plate = ? WHERE id = ?', { newPlate, row.id })
      TacoV.Vehicles.replate(plate, newPlate)
    end
    TriggerClientEvent('tacov:vehicles:setPlate', src, tonumber(netId), newPlate)
    log(src, ('Kennzeichen geändert: %s → %s%s'):format(plate, newPlate, row and '' or ' (kein Eigentum)'))
    notify(src, 'success', ('Kennzeichen jetzt %s.'):format(newPlate))
    return
  end
  if action == 'owner' then
    local row = TacoV.DB.single('SELECT v.owner_type, v.owner_id, v.bought_price, v.state, c.first_name, c.last_name FROM vehicles v ' ..
      'LEFT JOIN characters c ON v.owner_type = \'character\' AND c.id = v.owner_id WHERE v.plate = ? AND v.deleted_at IS NULL', { plate })
    if not row then notify(src, 'info', ('%s: kein Eigentum (Team- oder Welt-Fahrzeug).'):format(plate))
    else notify(src, 'info', ('%s gehört %s (#%d), Kaufpreis %s, Zustand %s.'):format(plate, row.first_name and (row.first_name .. ' ' .. row.last_name) or row.owner_type,
      row.owner_id or 0, fmt(row.bought_price), row.state)) end
    return
  end
  if action == 'delete' then
    local row = TacoV.DB.single('SELECT id FROM vehicles WHERE plate = ? AND deleted_at IS NULL', { plate })
    if row then TacoV.DB.update('UPDATE vehicles SET state = \'garage\', garage = COALESCE(garage, \'impound\') WHERE id = ?', { row.id }) end
    DeleteEntity(ent)
    log(src, ('Fahrzeug gelöscht: %s%s'):format(plate, row and ' (Eigentum, in Garage zurückgesetzt)' or ''))
    notify(src, 'success', ('%s entfernt.'):format(plate))
    return
  end
  -- repair, fuel, tune, color, tint: Client führt aus
  TriggerClientEvent('tacov:admin:vehicle:do', src, action, tonumber(netId), a, b)
  log(src, ('Fahrzeug %s: %s%s'):format(plate, action, a and (' ' .. tostring(a)) or ''))
  if action == 'repair' then notify(src, 'success', ('%s repariert.'):format(plate)) end
  if action == 'fuel' then notify(src, 'success', ('%s vollgetankt.'):format(plate)) end
end)

-- Befehle
RegisterCommand('tp', function(src, args)
  if src == 0 then return end
  if #args == 1 and args[1] == 'wp' then teleport(src, 'waypoint')
  elseif #args == 1 then teleport(src, 'player', args[1])
  elseif #args >= 2 then teleport(src, 'coords', args[1], args[2], args[3])
  else notify(src, 'error', 'Nutzung: /tp <ID> · /tp wp · /tp <x> <y> [z]') end
end, false)
RegisterCommand('tpm', function(src) if src ~= 0 then teleport(src, 'waypoint') end end, false)
RegisterCommand('bring', function(src, args) if src ~= 0 then teleport(src, 'bring', args[1]) end end, false)
RegisterCommand('noclip', function(src) if src ~= 0 then toggle(src, 'noclip') end end, false)
RegisterCommand('unsichtbar', function(src) if src ~= 0 then toggle(src, 'invisible') end end, false)
