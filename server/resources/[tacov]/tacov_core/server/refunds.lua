-- Erstattungen (Punkt 5.11): Geld oder Items an einen Charakter, mit Stufen (Konzept 5 / Punkt 0.11):
-- bis refundSmallMax allein ab Moderator (admin.refund.small), bis refundMax allein ab Superadmin (admin.refund),
-- darüber sowie Waffen/Schutz nur mit zweiter Person (admin.refund.large, Vier-Augen-Prinzip). Auszahlung auch offline.
TacoV = TacoV or {}
TacoV.Refunds = {}

local P = TacoV.Config.Permissions
local function notify(src, kind, text) TriggerClientEvent('tacov:core:notify', src, kind, text) end
local function fmt(n)
  local out = tostring(math.floor(n or 0)):reverse():gsub('(%d%d%d)', '%1.'):reverse()
  if out:sub(1, 1) == '.' then out = out:sub(2) end
  return out .. ' $'
end
local function describe(r)
  if r.kind == 'money' then return fmt(r.amount) end
  local def = TacoV.Config.Items[r.item]
  return ('%dx %s'):format(r.amount, def and def.label or r.item)
end
local function sourceOfCharacter(cid)
  for src, p in pairs(TacoV.Players.all()) do if p.characterId == cid then return src end end
  return nil
end

--- Auszahlen (Charakter darf offline sein). Gibt true/false, Fehlertext.
local function payout(r, byDiscord)
  if r.kind == 'money' then
    local okMove = TacoV.Journal.move('bank', nil, { type = 'character', id = r.character_id }, r.amount, 'erstattung', { note = 'Erstattung #' .. r.id })
    if not okMove then return false, 'Buchung fehlgeschlagen.' end
  else
    local src = sourceOfCharacter(r.character_id)
    local inv = src and TacoV.Inventory.ofSource(src) or TacoV.Inventory.load('character', r.character_id)
    local okAdd = TacoV.Inventory.add(inv, r.item, r.amount)
    if not src then TacoV.Inventory.unload('character', r.character_id) end
    if not okAdd then return false, 'Kein Platz im Inventar des Spielers.' end
    if src then TacoV.Inventory.send(src) end
  end
  TacoV.DB.update('UPDATE refunds SET status = \'paid\', decided_by = ?, decided_at = NOW() WHERE id = ?', { byDiscord, r.id })
  TacoV.Log.write('money', ('Erstattung #%d ausgezahlt: %s an Charakter #%d (%s)'):format(r.id, describe(r), r.character_id, r.reason), { characterId = r.character_id })
  local src = sourceOfCharacter(r.character_id)
  if src then
    TacoV.Accounts.push(src)
    notify(src, 'success', ('Erstattung erhalten: %s (%s).'):format(describe(r), r.reason))
  end
  return true
end

--- Welche Stufe braucht der Antrag? Gibt Recht und ob eine zweite Person nötig ist.
local function tier(kind, amount, item)
  if kind == 'money' then
    if amount <= P.refundSmallMax then return 'admin.refund.small', false end
    if amount <= P.refundMax then return 'admin.refund', false end
    return 'admin.refund.large', true
  end
  local def = TacoV.Config.Items[item] or {}
  if def.category == 'weapon' or def.category == 'armor' or def.category == 'ammo' then return 'admin.refund.large', true end
  return 'admin.refund', false
end

RegisterNetEvent('tacov:refunds:request', function(targetSrc, kind, amount, item, reason)
  local src = source
  local tc = TacoV.Characters.get(tonumber(targetSrc) or 0)
  if not tc then notify(src, 'error', 'Spieler hat keinen Charakter geladen.') return end
  amount = math.floor(tonumber(amount) or 0)
  reason = TacoV.Util.cleanText(reason or '', 255)
  if amount < 1 or #reason < 3 then notify(src, 'error', 'Betrag/Anzahl und Grund angeben.') return end
  if kind ~= 'money' then kind = 'item' if not TacoV.Config.Items[item] then notify(src, 'error', 'Unbekanntes Item.') return end end
  local right, twoPersons = tier(kind, amount, item)
  if not TacoV.Permissions.has(src, right) and not TacoV.Permissions.has(src, 'admin.refund.large') then
    notify(src, 'error', 'Dafür fehlt dir das Recht – beantrage es über eine höhere Stufe.')
    return
  end
  local p = TacoV.Players.get(src)
  local id = TacoV.DB.insert('INSERT INTO refunds (character_id, kind, amount, item, reason, requested_by) VALUES (?, ?, ?, ?, ?, ?)',
    { tc.id, kind, amount, kind == 'item' and item or nil, reason, p.discordId })
  local r = { id = id, character_id = tc.id, kind = kind, amount = amount, item = item, reason = reason, requested_by = p.discordId }
  TacoV.Log.write('admin', ('Erstattung #%d beantragt: %s an %s %s (#%d), Grund: %s%s'):format(id, describe(r), tc.first_name, tc.last_name, tc.id, reason,
    twoPersons and ' – wartet auf zweite Person' or ''), { discordId = p.discordId, characterId = tc.id })
  if twoPersons then
    notify(src, 'info', ('Erstattung #%d (%s) wartet auf Bestätigung durch eine zweite Person ab Manager.'):format(id, describe(r)))
    for _, staff in ipairs(TacoV.Players.staff(5)) do
      if staff ~= src then notify(staff, 'warn', ('Erstattung #%d (%s) wartet auf deine Bestätigung – Team-Menü → Erstattungen.'):format(id, describe(r))) end
    end
    return
  end
  local okPay, err = payout(r, p.discordId)
  notify(src, okPay and 'success' or 'error', okPay and ('Erstattung #%d ausgezahlt: %s.'):format(id, describe(r)) or err)
end)

RegisterNetEvent('tacov:refunds:list', function()
  local src = source
  if not TacoV.Permissions.has(src, 'admin.refund.small') then return end
  local rows = TacoV.DB.query('SELECT r.*, c.first_name, c.last_name FROM refunds r JOIN characters c ON c.id = r.character_id ' ..
    'WHERE r.status = \'open\' ORDER BY r.id DESC LIMIT 30') or {}
  local out = {}
  for _, r in ipairs(rows) do
    out[#out + 1] = { id = r.id, text = describe(r), name = r.first_name .. ' ' .. r.last_name, reason = r.reason, requestedBy = r.requested_by, created = tostring(r.created_at) }
  end
  TriggerClientEvent('tacov:refunds:list', src, out)
end)

RegisterNetEvent('tacov:refunds:decide', function(id, approve)
  local src = source
  if not TacoV.Permissions.has(src, 'admin.refund.large') then notify(src, 'error', 'Bestätigen dürfen nur Manager und höher.') return end
  local r = TacoV.DB.single('SELECT * FROM refunds WHERE id = ? AND status = \'open\'', { tonumber(id) or 0 })
  if not r then notify(src, 'error', 'Antrag nicht (mehr) offen.') return end
  local p = TacoV.Players.get(src)
  if r.requested_by == p.discordId then notify(src, 'error', 'Vier-Augen-Prinzip: Eine andere Person muss bestätigen.') return end
  if not approve then
    TacoV.DB.update('UPDATE refunds SET status = \'rejected\', decided_by = ?, decided_at = NOW() WHERE id = ?', { p.discordId, r.id })
    TacoV.Log.write('admin', ('Erstattung #%d abgelehnt (%s)'):format(r.id, describe(r)), { discordId = p.discordId, characterId = r.character_id })
    notify(src, 'info', ('Erstattung #%d abgelehnt.'):format(r.id))
    return
  end
  local okPay, err = payout(r, p.discordId)
  notify(src, okPay and 'success' or 'error', okPay and ('Erstattung #%d bestätigt und ausgezahlt: %s.'):format(r.id, describe(r)) or err)
end)
