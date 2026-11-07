-- Befehle der Befehlszeile (Taste T). Jeder Befehl prüft Rechte serverseitig.
TacoV = TacoV or {}

local function notify(src, kind, text)
  TriggerClientEvent('tacov:core:notify', src, kind, text)
end

local function needRight(src, right)
  if TacoV.Permissions.has(src, right) then return true end
  notify(src, 'error', 'Dafür fehlt dir das Recht.')
  return false
end

-- /support <Text>  – Ticket an das Team (Konzept 1: Support)
RegisterCommand('support', function(src, args)
  if src == 0 then return end
  local text = TacoV.Util.cleanText(table.concat(args, ' '), 255)
  if #text < 5 then notify(src, 'error', 'Bitte beschreibe dein Anliegen.') return end
  local p = TacoV.Players.get(src)
  TacoV.Log.write('support', text, { discordId = p and p.discordId, characterId = p and p.characterId, data = { source = src } })
  notify(src, 'info', 'Dein Anliegen ist beim Team eingegangen.')
  for _, staff in ipairs(TacoV.Players.staff(1)) do
    notify(staff, 'info', ('Support #%d: %s'):format(src, text))
  end
end, false)

-- /ort setzen <name> <art> [Beschriftung]  – Ort an die eigene Position legen (Konzept 5)
-- /ort liste
RegisterCommand('ort', function(src, args)
  if src == 0 then return end
  if not needRight(src, 'admin.locations') then return end
  local sub = args[1]
  if sub == 'liste' then
    local rows = TacoV.DB.query('SELECT name, kind, label FROM locations ORDER BY kind, name') or {}
    for _, r in ipairs(rows) do notify(src, 'info', ('%s [%s] %s'):format(r.name, r.kind, r.label)) end
    if #rows == 0 then notify(src, 'info', 'Keine Orte gesetzt.') end
    return
  end
  if sub == 'setzen' and args[2] and args[3] then
    local ped = GetPlayerPed(src)
    local pos = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local name = TacoV.Util.cleanText(args[2], 48):lower()
    local kind = TacoV.Util.cleanText(args[3], 24):lower()
    local label = TacoV.Util.cleanText(table.concat(args, ' ', 4), 64)
    local p = TacoV.Players.get(src)
    TacoV.DB.query(
      'INSERT INTO locations (name, kind, x, y, z, heading, label, updated_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?) ' ..
      'ON DUPLICATE KEY UPDATE kind = VALUES(kind), x = VALUES(x), y = VALUES(y), z = VALUES(z), ' ..
      'heading = VALUES(heading), label = VALUES(label), updated_by = VALUES(updated_by)',
      { name, kind, pos.x, pos.y, pos.z, heading, label, p and p.discordId }
    )
    TacoV.Log.write('admin', ('Ort gesetzt: %s (%s) @ %.1f %.1f %.1f'):format(name, kind, pos.x, pos.y, pos.z), { discordId = p and p.discordId })
    notify(src, 'success', ('Ort "%s" gesetzt.'):format(name))
    TriggerEvent('tacov:core:locationChanged', name)
    return
  end
  notify(src, 'info', 'Nutzung: /ort setzen <name> <art> [Beschriftung] | /ort liste')
end, false)

-- /geld <Server-ID> <Betrag> [bank|bar]  – Testgeld geben (Team, Recht admin.give); läuft über das Journal und wird geloggt
RegisterCommand('geld', function(src, args)
  if src ~= 0 and not needRight(src, 'admin.give') then return end
  local target = tonumber(args[1])
  local amount = tonumber(args[2])
  local kind = args[3] == 'bar' and 'cash' or 'bank'
  local tc = target and TacoV.Characters.get(target)
  if not tc or not amount or amount <= 0 then
    if src ~= 0 then notify(src, 'info', 'Nutzung: /geld <Server-ID> <Betrag> [bank|bar]') else print('Nutzung: geld <ID> <Betrag> [bank|bar]') end
    return
  end
  local ok
  if kind == 'cash' then
    ok = TacoV.Inventory.addCash(target, amount, 'teamgeld')
  else
    local actor = src ~= 0 and TacoV.Characters.get(src)
    ok = TacoV.Journal.move('bank', nil, { type = 'character', id = tc.id }, amount, 'teamgeld', { actor = actor and actor.id or nil })
    if ok then TacoV.Accounts.push(target) end
  end
  local p = TacoV.Players.get(src)
  TacoV.Log.write('admin', ('Geld gegeben: %d $ (%s) an #%d'):format(amount, kind, tc.id), { discordId = p and p.discordId, characterId = tc.id })
  if src ~= 0 then notify(src, ok and 'success' or 'error', ok and ('%d $ gegeben.'):format(amount) or 'Fehler beim Buchen.') end
  notify(target, 'info', ('Das Team hat dir %d $ (%s) gegeben.'):format(amount, kind == 'cash' and 'bar' or 'Konto'))
end, true)

-- Einmaliges Startgeld für den nächsten Charakter, der lädt: `set tacov_grant_next <Betrag>` in server.cfg.
-- Wird nur einmal gebucht (Journal-Grund 'startbonus'), auch wenn der Eintrag in der server.cfg stehen bleibt.
AddEventHandler('tacov:core:characterSelected', function(source, characterId)
  local amount = GetConvarInt('tacov_grant_next', 0)
  if amount <= 0 then return end
  if TacoV.DB.scalar("SELECT id FROM journal WHERE reason = 'startbonus' LIMIT 1") then return end
  local ok = TacoV.Journal.move('bank', nil, { type = 'character', id = characterId }, amount, 'startbonus', { note = 'tacov_grant_next' })
  if not ok then return end
  TacoV.Accounts.push(source)
  TacoV.Log.write('admin', ('Startbonus %d $ an #%d (tacov_grant_next)'):format(amount, characterId), { characterId = characterId })
  notify(source, 'success', ('Startbonus: %d $ sind auf deinem Konto.'):format(amount))
end)

-- /rolle <Server-ID> <player|supporter|admin|management>
RegisterCommand('rolle', function(src, args)
  if src ~= 0 and not needRight(src, 'admin.roles') then return end
  local target = tonumber(args[1])
  local tp = target and TacoV.Players.get(target)
  if not tp then if src ~= 0 then notify(src, 'error', 'Spieler nicht gefunden.') else print('Spieler nicht gefunden.') end return end
  local ok, err = TacoV.Permissions.setRole(tp.id, args[2], src ~= 0 and src or nil)
  if src ~= 0 then notify(src, ok and 'success' or 'error', ok and 'Rolle gesetzt.' or ('Fehler: ' .. tostring(err))) end
end, true)

-- /sperre <Server-ID> <Stunden|0> <Grund>
RegisterCommand('sperre', function(src, args)
  if src ~= 0 and not needRight(src, 'admin.ban') then return end
  local target = tonumber(args[1])
  local hours = tonumber(args[2])
  local reason = TacoV.Util.cleanText(table.concat(args, ' ', 3), 255)
  local tp = target and TacoV.Players.get(target)
  if not tp or not hours or #reason < 3 then
    if src ~= 0 then notify(src, 'info', 'Nutzung: /sperre <Server-ID> <Stunden|0=dauerhaft> <Grund>') end
    return
  end
  local actor = src ~= 0 and TacoV.Players.get(src)
  TacoV.DB.insert(
    'INSERT INTO bans (discord_id, reason, issued_by, until_at) VALUES (?, ?, ?, ' .. (hours > 0 and 'DATE_ADD(NOW(), INTERVAL ? HOUR)' or 'NULL') .. ')',
    hours > 0 and { tp.discordId, reason, actor and actor.discordId or 'console', hours } or { tp.discordId, reason, actor and actor.discordId or 'console' }
  )
  TacoV.Log.write('admin', ('Sperre: %s (%s) %s h, Grund: %s'):format(tp.discordId, target, hours, reason), { discordId = actor and actor.discordId })
  DropPlayer(target, TacoV.Config.Whitelist.bannedMessage:format(reason))
end, true)

-- /kick <Server-ID> <Grund>
RegisterCommand('kick', function(src, args)
  if src ~= 0 and not needRight(src, 'admin.warn') then return end
  local target = tonumber(args[1])
  local reason = TacoV.Util.cleanText(table.concat(args, ' ', 2), 255)
  if not target or not TacoV.Players.get(target) then return end
  local actor = src ~= 0 and TacoV.Players.get(src)
  TacoV.Log.write('admin', ('Kick: %s, Grund: %s'):format(target, reason), { discordId = actor and actor.discordId })
  DropPlayer(target, 'Vom Team entfernt: ' .. reason)
end, true)
