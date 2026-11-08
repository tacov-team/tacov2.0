-- Einreise (Punkt 6.4, Konzept 1.4): Neue Charaktere warten in der Ankunftshalle; ein Teammitglied mit Recht `immigration`
-- führt das Einreisegespräch und entscheidet. Bestanden → Ausweis, Startgeld, Handy, Sozialwohnungsschlüssel, Busticket,
-- Stadtplan. Nicht bestanden → Rückflug (Kick) und neuer Versuch nach `retryHours`.
TacoV = TacoV or {}
TacoV.Immigration = {}

local O = TacoV.Config.Onboarding
local function notify(src, kind, text) TriggerClientEvent('tacov:core:notify', src, kind, text) end
local function need(src)
  if TacoV.Permissions.has(src, 'immigration') then return true end
  notify(src, 'error', 'Einreise dürfen nur Teammitglieder im Dienst mit dem Recht „Einreise“ durchführen.')
  return false
end
local function nameOf(c) return c.first_name .. ' ' .. c.last_name end

--- Warteschlange: Online-Charaktere ohne Einreise
function TacoV.Immigration.queue()
  local list = {}
  for src, p in pairs(TacoV.Players.all()) do
    local c = TacoV.Characters.get(src)
    if c and not c.immigrated_at then
      list[#list + 1] = { id = src, name = nameOf(c), characterId = c.id, origin = c.origin, since = c.sessionStart or os.time(),
        waitMinutes = math.floor((os.time() - (c.sessionStart or os.time())) / 60), discordId = p.discordId }
    end
  end
  table.sort(list, function(a, b) return a.since < b.since end)
  return list
end

local function staffOnline()
  local n = 0
  for _, s in ipairs(TacoV.Players.staff(1)) do if TacoV.Permissions.has(s, 'immigration') then n = n + 1 end end
  return n
end

--- Einreise bestanden: Ausstattung und Freischaltung
function TacoV.Immigration.pass(target, bySrc)
  local c = TacoV.Characters.get(target)
  if not c or c.immigrated_at then return false end
  local inv = TacoV.Inventory.ofSource(target)
  TacoV.Journal.move('bank', nil, { type = 'character', id = c.id }, O.startCash, 'startgeld', { note = 'Einreise' })
  for _, s in ipairs(O.immigrationItems) do
    local meta = s.item == 'id_card' and { name = nameOf(c), birth = tostring(c.birth_date) } or nil
    TacoV.Inventory.add(inv, s.item, s.amount, meta)
  end
  TacoV.Inventory.remove(inv, 'passport', 1)
  TacoV.Housing.grantSocial(c.id)
  TacoV.Inventory.send(target)
  TacoV.Accounts.push(target)
  TacoV.DB.update('UPDATE characters SET immigrated_at = NOW(), immigration_retry_at = NULL WHERE id = ?', { c.id })
  c.immigrated_at = os.date('%Y-%m-%d %H:%M:%S')
  local by = bySrc and TacoV.Characters.get(bySrc)
  TacoV.Log.write('character', ('Einreise bestanden: %s (#%d) durch %s'):format(nameOf(c), c.id, by and nameOf(by) or 'System'), { characterId = c.id })
  TriggerClientEvent('tacov:immigration:state', target, true)
  local text = ('Einreise bestanden – %d $ auf dem Konto, Ausweis, Handy, Wohnungsschlüssel und Busticket in der Tasche.'):format(O.startCash)
  TriggerClientEvent('tacov:core:announce', target, { title = 'Willkommen in Los Santos', text = text, kind = 'info', seconds = 12 })
  return true
end

function TacoV.Immigration.fail(target, bySrc, reason)
  local c = TacoV.Characters.get(target)
  if not c or c.immigrated_at then return false end
  TacoV.DB.update('UPDATE characters SET immigration_retry_at = DATE_ADD(NOW(), INTERVAL ? HOUR) WHERE id = ?', { O.retryHours, c.id })
  local by = bySrc and TacoV.Characters.get(bySrc)
  TacoV.Log.write('character', ('Einreise abgelehnt: %s (#%d) durch %s – %s'):format(nameOf(c), c.id, by and nameOf(by) or 'System', reason), { characterId = c.id })
  TacoV.Characters.unload(target)
  Wait(500)
  DropPlayer(target, ('Einreise nicht bestanden: %s. Rückflug – neuer Versuch in %d Stunden.'):format(reason, O.retryHours))
  return true
end

-- Spieler ohne Einreise: Hinweis beim Laden, Team informieren
AddEventHandler('tacov:core:characterSelected', function(src)
  local c = TacoV.Characters.get(src)
  if not c or c.immigrated_at then return end
  TriggerClientEvent('tacov:immigration:state', src, false)
  local n = staffOnline()
  SetTimeout(3000, function()
    if n > 0 then
      notify(src, 'info', ('Bitte warte in der Ankunftshalle – %d Teammitglied(er) für die Einreise sind online.'):format(n))
    else
      notify(src, 'warn', 'Derzeit ist niemand für die Einreise online. Die nächsten Einreisezeiten stehen im Discord.')
    end
  end)
  for _, s in ipairs(TacoV.Players.staff(1)) do
    if s ~= src and TacoV.Permissions.has(s, 'immigration') then notify(s, 'info', ('Einreise: %s wartet in der Ankunftshalle (Team-Menü → Einreise).'):format(nameOf(c))) end
  end
end)

RegisterNetEvent('tacov:immigration:list', function()
  local src = source
  if not need(src) then return end
  TriggerClientEvent('tacov:immigration:list', src, TacoV.Immigration.queue())
end)

RegisterNetEvent('tacov:immigration:decide', function(target, passed, reason)
  local src = source
  if not need(src) then return end
  target = tonumber(target)
  local c = target and TacoV.Characters.get(target)
  if not c then notify(src, 'error', 'Spieler nicht gefunden.') return end
  if c.immigrated_at then notify(src, 'info', 'Dieser Charakter ist bereits eingereist.') return end
  if passed then
    TacoV.Immigration.pass(target, src)
    notify(src, 'success', ('%s ist eingereist.'):format(nameOf(c)))
  else
    reason = TacoV.Util.cleanText(reason or 'kein Grund angegeben', 120)
    notify(src, 'success', ('%s abgelehnt (%s).'):format(nameOf(c), reason))
    TacoV.Immigration.fail(target, src, reason)
  end
end)

-- Charakter darf nach Ablehnung erst nach retryHours wieder geladen werden
AddEventHandler('tacov:core:beforeSelect', function(_, row, deny)
  if row.immigration_retry_at and not row.immigrated_at then
    local left = TacoV.DB.scalar('SELECT TIMESTAMPDIFF(MINUTE, NOW(), immigration_retry_at) FROM characters WHERE id = ?', { row.id }) or 0
    if left > 0 then deny(('Einreise abgelehnt – neuer Versuch in %d h %d min.'):format(math.floor(left / 60), left % 60)) end
  end
end)
