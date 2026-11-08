-- Tickets (Punkt 5.15): /support legt ein Ticket an, weitere /support-Texte hängen an das offene Ticket; Team bearbeitet im
-- Team-Menü (übernehmen, antworten, hingehen, schließen). Der Bot spiegelt jedes Ticket in einen Discord-Kanal und schreibt
-- Antworten von dort in ticket_messages – der Server zeigt sie dem Spieler im Spiel.
TacoV = TacoV or {}
TacoV.Tickets = {}

local function notify(src, kind, text) TriggerClientEvent('tacov:core:notify', src, kind, text) end
local function need(src)
  if TacoV.Permissions.has(src, 'support.view') then return true end
  notify(src, 'error', 'Tickets bearbeiten dürfen nur Teammitglieder im Dienst.')
  return false
end
local function nameOf(src)
  local c = TacoV.Characters.get(src)
  local p = TacoV.Players.get(src)
  return c and (c.first_name .. ' ' .. c.last_name) or (p and p.discordId) or ('#' .. src)
end
local function sourceOfDiscord(discordId)
  for src, p in pairs(TacoV.Players.all()) do if p.discordId == discordId then return src end end
  return nil
end
local function addMessage(ticketId, source, author, text, seenGame)
  TacoV.DB.insert('INSERT INTO ticket_messages (ticket_id, source, author, text, seen_game) VALUES (?, ?, ?, ?, ?)',
    { ticketId, source, author, TacoV.Util.cleanText(text, 1000), seenGame and 1 or 0 })
end
local function staffNotify(text)
  for _, staff in ipairs(TacoV.Players.staff(1)) do notify(staff, 'info', text) end
end

--- Spieler: Ticket anlegen oder ergänzen
function TacoV.Tickets.create(src, text)
  local p = TacoV.Players.get(src)
  if not p then return end
  local c = TacoV.Characters.get(src)
  local open = TacoV.DB.single('SELECT id FROM tickets WHERE discord_id = ? AND status <> \'closed\' ORDER BY id DESC LIMIT 1', { p.discordId })
  if open then
    addMessage(open.id, 'game', nameOf(src), text, true)
    notify(src, 'info', ('Ergänzung zu Ticket #%d gespeichert.'):format(open.id))
    staffNotify(('Ticket #%d (%s): %s'):format(open.id, nameOf(src), text))
    return open.id
  end
  local id = TacoV.DB.insert('INSERT INTO tickets (discord_id, character_id, player_name, subject) VALUES (?, ?, ?, ?)',
    { p.discordId, c and c.id, nameOf(src), TacoV.Util.cleanText(text, 255) })
  addMessage(id, 'game', nameOf(src), text, true)
  TacoV.Log.write('support', ('Ticket #%d: %s'):format(id, text), { discordId = p.discordId, characterId = c and c.id, data = { source = src } })
  notify(src, 'success', ('Ticket #%d ist beim Team eingegangen. Weitere Infos einfach wieder mit /support schicken.'):format(id))
  staffNotify(('Neues Ticket #%d von %s: %s'):format(id, nameOf(src), text))
  return id
end

RegisterNetEvent('tacov:tickets:list', function()
  local src = source
  if not need(src) then return end
  local rows = TacoV.DB.query('SELECT id, player_name, subject, status, claimed_by, discord_id, created_at FROM tickets WHERE status <> \'closed\' ORDER BY id DESC LIMIT 40') or {}
  for _, r in ipairs(rows) do r.online = sourceOfDiscord(r.discord_id) ~= nil end
  TriggerClientEvent('tacov:tickets:list', src, rows)
end)

RegisterNetEvent('tacov:tickets:detail', function(id)
  local src = source
  if not need(src) then return end
  local t = TacoV.DB.single('SELECT * FROM tickets WHERE id = ?', { tonumber(id) or 0 })
  if not t then return end
  local msgs = TacoV.DB.query('SELECT source, author, text, created_at FROM ticket_messages WHERE ticket_id = ? ORDER BY id DESC LIMIT 12', { t.id }) or {}
  t.online = sourceOfDiscord(t.discord_id)
  TriggerClientEvent('tacov:tickets:detail', src, t, msgs)
end)

RegisterNetEvent('tacov:tickets:action', function(id, action, text)
  local src = source
  if not need(src) then return end
  local t = TacoV.DB.single('SELECT * FROM tickets WHERE id = ?', { tonumber(id) or 0 })
  if not t or t.status == 'closed' then notify(src, 'error', 'Ticket nicht offen.') return end
  local p = TacoV.Players.get(src)
  local me = nameOf(src)
  local target = sourceOfDiscord(t.discord_id)
  if action == 'claim' then
    TacoV.DB.update('UPDATE tickets SET status = \'claimed\', claimed_by = ? WHERE id = ?', { p.discordId, t.id })
    addMessage(t.id, 'system', me, ('%s hat das Ticket übernommen.'):format(me), true)
    if target then notify(target, 'info', ('Ticket #%d: %s kümmert sich darum.'):format(t.id, me)) end
    notify(src, 'success', ('Ticket #%d übernommen.'):format(t.id))
  elseif action == 'reply' then
    text = TacoV.Util.cleanText(text or '', 1000)
    if #text < 1 then return end
    addMessage(t.id, 'game', me .. ' (Team)', text, true)
    if target then notify(target, 'info', ('Ticket #%d · %s: %s'):format(t.id, me, text)) end
    notify(src, 'success', 'Antwort gesendet.')
  elseif action == 'goto' then
    if not target then notify(src, 'error', 'Spieler ist nicht online.') return end
    local pos = GetEntityCoords(GetPlayerPed(target))
    TriggerClientEvent('tacov:admin:setCoords', src, pos.x, pos.y, pos.z, GetEntityHeading(GetPlayerPed(target)))
    addMessage(t.id, 'system', me, ('%s ist zum Spieler teleportiert.'):format(me), true)
  elseif action == 'close' then
    TacoV.DB.update('UPDATE tickets SET status = \'closed\', closed_by = ?, closed_at = NOW() WHERE id = ?', { p.discordId, t.id })
    addMessage(t.id, 'system', me, ('%s hat das Ticket geschlossen.'):format(me), true)
    if target then notify(target, 'info', ('Ticket #%d wurde geschlossen. Danke!'):format(t.id)) end
    notify(src, 'success', ('Ticket #%d geschlossen.'):format(t.id))
  else
    return
  end
  TacoV.Log.write('support', ('Ticket #%d %s durch %s%s'):format(t.id, action, me, text and (': ' .. text) or ''), { discordId = p.discordId })
end)

-- Antworten aus Discord dem Spieler im Spiel zeigen (Bot schreibt ticket_messages mit source = 'discord')
AddEventHandler('tacov:core:ready', function()
  CreateThread(function()
    while true do
      Wait(10000)
      local rows = TacoV.DB.query('SELECT m.id, m.ticket_id, m.author, m.text, m.source, t.discord_id FROM ticket_messages m JOIN tickets t ON t.id = m.ticket_id ' ..
        'WHERE m.seen_game = 0 ORDER BY m.id LIMIT 20') or {}
      for _, m in ipairs(rows) do
        local src = sourceOfDiscord(m.discord_id)
        if src then
          notify(src, 'info', ('Ticket #%d · %s: %s'):format(m.ticket_id, m.author, m.text))
          TacoV.DB.update('UPDATE ticket_messages SET seen_game = 1 WHERE id = ?', { m.id })
        end
      end
    end
  end)
end)
