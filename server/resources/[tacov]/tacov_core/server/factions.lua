-- Fraktionen (Punkte 9.1–9.3, Server): f.id ist die Text-Kennung (characters.faction), f.num die Zahl für Konto und Lager
-- (accounts/inventory_items.owner_id sind Zahlen).
-- Inhalt: Stammdaten, Mitglieder (characters.faction/faction_rank), Ränge und Rechte je Rang,
-- Kasse (Konto 'faction'), Lager mit Rechten und Tageslimits, Dienst (Statebag duty), Dienstkleidung, Fraktionsfahrzeuge,
-- Protokoll, Einladungen, Team-Verwaltung. Die Inhalte je Fraktion (MDT, Notrufe, …) kommen mit 9.4–9.11.
TacoV = TacoV or {}
TacoV.Factions = {}

local F = TacoV.Config.Factions
local factions = {}        -- [id] = { id, label, type, cap, channel, ranks = { [rank] = { name, rights = { flag = true } } } }
local onDuty = {}          -- [src] = faction id
local invites = {}         -- [targetSrc] = { faction, by = src, at }

local function notify(src, kind, text) TriggerClientEvent('tacov:core:notify', src, kind, text) end
local function fmt(n) return (tostring(math.floor(n or 0)):reverse():gsub('(%d%d%d)', '%1.'):reverse():gsub('^%.', '')) end
local function fullName(c) return c.first_name .. ' ' .. c.last_name end

local function defaultRights(rank)
  local set = {}
  for _, r in ipairs(F.defaultRights[rank] or {}) do set[r] = true end
  return set
end

-- ---------------------------------------------------------------- Laden

function TacoV.Factions.load()
  factions = {}
  for _, row in ipairs(TacoV.DB.query('SELECT * FROM factions WHERE dissolved_at IS NULL') or {}) do
    local def = F.list[row.id] or {}
    local f = { id = row.id, num = row.num, label = row.label, type = row.type, cap = row.cap, channel = row.channel, teamOnly = def.teamOnly, color = def.color, ranks = {} }
    for r = 1, F.maxRank do f.ranks[r] = { name = ('Rang %d'):format(r), rights = defaultRights(r) } end
    factions[row.id] = f
  end
  for _, row in ipairs(TacoV.DB.query('SELECT * FROM faction_ranks') or {}) do
    local f = factions[row.faction_id]
    if f and f.ranks[row.rank] then
      f.ranks[row.rank].name = row.name
      if row.rights then
        local set = {}
        for _, r in ipairs(json.decode(row.rights) or {}) do set[r] = true end
        f.ranks[row.rank].rights = set
      end
    end
  end
end
CreateThread(function() Wait(1500) TacoV.Factions.load() end)
AddEventHandler('tacov:core:reloadData', function() TacoV.Factions.load() end)

function TacoV.Factions.get(id) return factions[id] end
function TacoV.Factions.all() return factions end

local function saveRank(f, rank)
  local list = {}
  for r in pairs(f.ranks[rank].rights) do list[#list + 1] = r end
  table.sort(list)
  TacoV.DB.update('INSERT INTO faction_ranks (faction_id, rank, name, rights) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE name = VALUES(name), rights = VALUES(rights)',
    { f.id, rank, f.ranks[rank].name, json.encode(list) })
end

local function log(f, c, action, text)
  TacoV.DB.insert('INSERT INTO faction_log (faction_id, character_id, faction_rank, action, text) VALUES (?, ?, ?, ?, ?)',
    { f.id, c and c.id or nil, c and c.faction_rank or nil, action, text })
  TacoV.Log.write('faction', ('[%s] %s'):format(f.label, text), { characterId = c and c.id or nil })
end

-- ---------------------------------------------------------------- Mitglieder und Rechte

function TacoV.Factions.of(src)
  local c = TacoV.Characters.get(src)
  if not c or not c.faction then return nil, nil end
  return factions[c.faction], c
end

--- Hat der Charakter das Recht (nach Rang, Leader hat alles)?
function TacoV.Factions.has(src, right)
  local f, c = TacoV.Factions.of(src)
  if not f then return false end
  local rank = f.ranks[c.faction_rank or 1]
  return rank and (rank.rights[right] == true or rank.rights.leader == true) or false
end
function TacoV.Factions.isOnDuty(src) return onDuty[src] ~= nil end
--- Alle Diensthabenden einer Fraktion (Liste von Server-IDs)
function TacoV.Factions.dutyList(factionId)
  local out = {}
  for src, id in pairs(onDuty) do if id == factionId then out[#out + 1] = src end end
  return out
end
function TacoV.Factions.rankName(id, rank)
  local f = factions[id]
  return f and f.ranks[rank] and f.ranks[rank].name or ('Rang %d'):format(rank or 0)
end

local function members(f)
  return TacoV.DB.query('SELECT id, first_name, last_name, faction_rank, faction_joined_at FROM characters WHERE faction = ? AND deleted_at IS NULL ORDER BY faction_rank DESC, last_name',
    { f.id }) or {}
end
local function memberCount(f, countHangaround)
  local rows = members(f)
  if countHangaround then return #rows end
  local n = 0
  for _, m in ipairs(rows) do if f.type ~= 'crime' or m.faction_rank >= 3 then n = n + 1 end end
  return n
end
local function srcOfCharacter(cid)
  for _, pid in ipairs(GetPlayers()) do
    local c = TacoV.Characters.get(tonumber(pid))
    if c and c.id == cid then return tonumber(pid) end
  end
  return nil
end

--- Charakterdaten an den Client schicken (HUD, F6)
local function pushCharacter(src)
  local c = TacoV.Characters.get(src)
  if not c then return end
  local f = c.faction and factions[c.faction]
  TriggerClientEvent('tacov:core:characterUpdated', src, {
    faction = c.faction, factionRank = c.faction_rank, factionLabel = f and f.label or nil,
    factionRankName = f and TacoV.Factions.rankName(f.id, c.faction_rank) or nil, duty = onDuty[src] ~= nil,
    level = TacoV.Characters.publicData(src).level,
  })
end
TacoV.Factions.pushCharacter = pushCharacter
AddEventHandler('tacov:core:characterSelected', function(src) Wait(800) pushCharacter(src) end)

local function setDuty(src, on)
  local f, c = TacoV.Factions.of(src)
  if not f then return end
  onDuty[src] = on and f.id or nil
  Player(src).state:set('duty', on and f.id or false, true)
  pushCharacter(src)
  log(f, c, on and 'duty_on' or 'duty_off', ('%s: Dienst %s'):format(fullName(c), on and 'begonnen' or 'beendet'))
  TriggerEvent('tacov:factions:duty', src, f.id, on)
end

--- Beitritt (durch Einladung oder Team). Prüft Cap, Level, Sperren.
function TacoV.Factions.join(src, factionId, rank, byText)
  local f = factions[factionId]
  local c = TacoV.Characters.get(src)
  if not f or not c then return false, 'Fraktion unbekannt.' end
  if c.faction then return false, 'Schon in einer Fraktion.' end
  rank = math.max(1, math.min(F.maxRank, tonumber(rank) or 1))
  local block = TacoV.DB.single('SELECT from_type, TIMESTAMPDIFF(HOUR, NOW(), until_at) AS h FROM faction_blocks WHERE character_id = ? AND until_at > NOW()', { c.id })
  if block then
    local hours = tonumber(block.h) or 0
    local limitDays = (block.from_type == 'crime' and f.type == 'state') and F.crimeToStateDays or F.leaveBlockDays
    local remaining = hours - (F.leaveBlockDays - limitDays) * 24
    if remaining > 0 then return false, ('Fraktionssperre: noch %d h.'):format(remaining) end
  end
  local level = TacoV.Characters.publicData(src).level or 0
  if f.type == 'crime' then
    if rank <= 2 and level < F.gang.levelHangaround then return false, ('Hangaround erst ab Level %d.'):format(F.gang.levelHangaround) end
    if rank >= 3 and level < F.gang.levelMember then return false, ('Mitglied erst ab Level %d.'):format(F.gang.levelMember) end
    if rank <= 2 then
      local hang = 0
      for _, m in ipairs(members(f)) do if m.faction_rank <= 2 then hang = hang + 1 end end
      if hang >= F.gang.hangaroundMax then return false, 'Höchstens zwei Hangarounds.' end
    end
  end
  local cap = f.cap or 0
  if cap > 0 and rank >= 3 and memberCount(f) >= cap then return false, ('%s ist voll (%d).'):format(f.label, cap) end
  c.faction, c.faction_rank = f.id, rank
  TacoV.DB.update('UPDATE characters SET faction = ?, faction_rank = ?, faction_joined_at = NOW() WHERE id = ?', { f.id, rank, c.id })
  log(f, c, 'join', ('%s ist beigetreten (%s)%s'):format(fullName(c), TacoV.Factions.rankName(f.id, rank), byText and (' – ' .. byText) or ''))
  pushCharacter(src)
  notify(src, 'success', ('Willkommen bei %s – %s.'):format(f.label, TacoV.Factions.rankName(f.id, rank)))
  return true
end

--- Austritt/Entlassung: Sperre setzen, Dienst beenden
function TacoV.Factions.leave(src, reason, byText)
  local f, c = TacoV.Factions.of(src)
  if not f then return false end
  if onDuty[src] then setDuty(src, false) end
  TacoV.DB.update('INSERT INTO faction_blocks (character_id, from_type, until_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? DAY)) ' ..
    'ON DUPLICATE KEY UPDATE from_type = VALUES(from_type), until_at = VALUES(until_at)',
    { c.id, f.type, F.leaveBlockDays })
  log(f, c, reason, ('%s hat die Fraktion verlassen (%s)%s'):format(fullName(c), reason == 'kick' and 'entlassen' or 'Austritt', byText and (' – ' .. byText) or ''))
  c.faction, c.faction_rank = nil, nil
  TacoV.DB.update('UPDATE characters SET faction = NULL, faction_rank = NULL, faction_joined_at = NULL WHERE id = ?', { c.id })
  pushCharacter(src)
  notify(src, 'info', reason == 'kick' and ('Du wurdest aus %s entlassen.'):format(f.label) or ('Du hast %s verlassen.'):format(f.label))
  return true
end

--- Offline-Variante (Team / Entlassen eines Abwesenden)
local function leaveOffline(f, cid, reason, byText)
  TacoV.DB.update('INSERT INTO faction_blocks (character_id, from_type, until_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? DAY)) ' ..
    'ON DUPLICATE KEY UPDATE from_type = VALUES(from_type), until_at = VALUES(until_at)',
    { cid, f.type, F.leaveBlockDays })
  local row = TacoV.DB.single('SELECT first_name, last_name, faction_rank FROM characters WHERE id = ?', { cid })
  TacoV.DB.update('UPDATE characters SET faction = NULL, faction_rank = NULL, faction_joined_at = NULL WHERE id = ?', { cid })
  log(f, nil, reason, ('%s wurde entlassen%s'):format(row and (row.first_name .. ' ' .. row.last_name) or ('#' .. cid), byText and (' – ' .. byText) or ''))
end

-- ---------------------------------------------------------------- Übersicht für das F6-Menü

local function daily(cid)
  local row = TacoV.DB.single('SELECT storage_grams, treasury FROM faction_daily WHERE character_id = ? AND day = CURDATE()', { cid })
  return row and (tonumber(row.storage_grams) or 0) or 0, row and (tonumber(row.treasury) or 0) or 0
end
local function addDaily(cid, grams, money)
  TacoV.DB.update('INSERT INTO faction_daily (character_id, day, storage_grams, treasury) VALUES (?, CURDATE(), ?, ?) ' ..
    'ON DUPLICATE KEY UPDATE storage_grams = storage_grams + VALUES(storage_grams), treasury = treasury + VALUES(treasury)', { cid, grams or 0, money or 0 })
end

local function overview(src)
  local f, c = TacoV.Factions.of(src)
  if not f then return nil end
  local list = {}
  for _, m in ipairs(members(f)) do
    list[#list + 1] = { id = m.id, name = m.first_name .. ' ' .. m.last_name, rank = m.faction_rank, rankName = TacoV.Factions.rankName(f.id, m.faction_rank),
      online = srcOfCharacter(m.id) ~= nil, me = m.id == c.id }
  end
  local rights = {}
  for flag in pairs(f.ranks[c.faction_rank].rights) do rights[flag] = true end
  local ranks = {}
  for r = 1, F.maxRank do
    local flags = {}
    for flag in pairs(f.ranks[r].rights) do flags[#flags + 1] = flag end
    table.sort(flags)
    ranks[r] = { name = f.ranks[r].name, rights = flags }
  end
  local usedKg, usedMoney = daily(c.id)
  local vehicles = TacoV.DB.query('SELECT id, model, label, min_rank FROM faction_vehicles WHERE faction_id = ? ORDER BY min_rank, label', { f.id }) or {}
  local outfits = TacoV.DB.query('SELECT id, name, gender, min_rank FROM faction_outfits WHERE faction_id = ? ORDER BY min_rank, name', { f.id }) or {}
  return {
    id = f.id, label = f.label, type = f.type, cap = f.cap, channel = f.channel, rank = c.faction_rank, rankName = TacoV.Factions.rankName(f.id, c.faction_rank),
    rights = rights, members = list, ranks = ranks, duty = onDuty[src] ~= nil,
    treasury = TacoV.Factions.has(src, 'treasury_view') and TacoV.Journal.balance('faction', f.num) or nil,
    dailyKgLeft = F.dailyStorageKg[c.faction_rank] and math.max(0, F.dailyStorageKg[c.faction_rank] - usedKg / 1000) or nil,
    dailyMoneyLeft = F.dailyTreasury[c.faction_rank] and math.max(0, F.dailyTreasury[c.faction_rank] - usedMoney) or nil,
    vehicles = vehicles, outfits = outfits, rankManageMax = F.rankManageMax, maxRank = F.maxRank, rightLabels = F.rightLabels,
    memberCount = memberCount(f),
  }
end

RegisterNetEvent('tacov:factions:open', function()
  local src = source
  local data = overview(src)
  if not data then notify(src, 'info', 'Du bist in keiner Fraktion.') return end
  TriggerClientEvent('tacov:factions:data', src, data)
end)

-- ---------------------------------------------------------------- Dienst (Stempeluhr), Kleidung

local function nearFactionPoint(src, kind, factionId, radius)
  local pos = GetEntityCoords(GetPlayerPed(src))
  for _, l in ipairs(TacoV.Locations.all()) do
    if l.kind == kind and l.name:match('([^_]+)$') == factionId and #(pos - vector3(l.x, l.y, l.z)) <= (radius or 4.0) then return l end
  end
  return nil
end

RegisterNetEvent('tacov:factions:duty', function()
  local src = source
  local f = TacoV.Factions.of(src)
  if not f then return end
  if not nearFactionPoint(src, 'faction_duty', f.id, 4.0) then notify(src, 'error', 'Dienst nur an der Stempeluhr der Fraktion.') return end
  setDuty(src, not onDuty[src])
  notify(src, 'success', onDuty[src] and ('Dienst begonnen – %s.'):format(f.label) or 'Dienst beendet.')
end)

-- Umkleide: Dienstkleidung anziehen (Zivilkleidung wird gemerkt), zurück in Zivil, Dienstkleidung speichern (settings)
RegisterNetEvent('tacov:factions:wardrobe', function(action, d)
  local src = source
  local f, c = TacoV.Factions.of(src)
  if not f or type(d) ~= 'table' then return end
  if not nearFactionPoint(src, 'faction_wardrobe', f.id, 4.0) then notify(src, 'error', 'Nur in der Umkleide der Fraktion.') return end
  if action == 'wear' then
    local row = TacoV.DB.single('SELECT * FROM faction_outfits WHERE id = ? AND faction_id = ?', { tonumber(d.id) or 0, f.id })
    if not row or row.min_rank > (c.faction_rank or 1) then notify(src, 'error', 'Diese Kleidung steht dir nicht zu.') return end
    if not c.civil_clothes then
      c.civil_clothes = json.encode({ components = c.appearance.components, props = c.appearance.props })
      TacoV.DB.update('UPDATE characters SET civil_clothes = ? WHERE id = ?', { c.civil_clothes, c.id })
    end
    local a = {}
    for k, v in pairs(c.appearance or {}) do a[k] = v end
    a.components, a.props = json.decode(row.components) or {}, json.decode(row.props) or {}
    TacoV.Characters.setAppearance(src, a)
    TriggerClientEvent('tacov:clothing:applied', src, c.appearance)
    notify(src, 'success', ('Dienstkleidung „%s“ angelegt.'):format(row.name))
  elseif action == 'civil' then
    if not c.civil_clothes then notify(src, 'info', 'Du trägst keine Dienstkleidung.') return end
    local civil = json.decode(c.civil_clothes) or {}
    local a = {}
    for k, v in pairs(c.appearance or {}) do a[k] = v end
    a.components, a.props = civil.components or a.components, civil.props or a.props
    c.civil_clothes = nil
    TacoV.DB.update('UPDATE characters SET civil_clothes = NULL WHERE id = ?', { c.id })
    TacoV.Characters.setAppearance(src, a)
    TriggerClientEvent('tacov:clothing:applied', src, c.appearance)
    notify(src, 'success', 'Zivilkleidung angelegt.')
  elseif action == 'save' then
    if not TacoV.Factions.has(src, 'settings') then notify(src, 'error', 'Nur die Fraktionsleitung speichert Dienstkleidung.') return end
    if type(d.components) ~= 'table' then return end
    local clean = TacoV.Characters.cleanAppearance({ components = d.components, props = d.props or {} }, c.gender)
    TacoV.DB.insert('INSERT INTO faction_outfits (faction_id, name, gender, min_rank, components, props) VALUES (?, ?, ?, ?, ?, ?)',
      { f.id, TacoV.Util.cleanText(d.name or 'Dienstkleidung', 32), c.gender or 0, math.max(1, math.min(F.maxRank, tonumber(d.minRank) or 1)),
        json.encode(clean.components), json.encode(clean.props) })
    log(f, c, 'outfit', ('%s hat Dienstkleidung „%s“ gespeichert'):format(fullName(c), d.name or 'Dienstkleidung'))
    notify(src, 'success', 'Dienstkleidung gespeichert.')
  elseif action == 'delete' then
    if not TacoV.Factions.has(src, 'settings') then return end
    TacoV.DB.update('DELETE FROM faction_outfits WHERE id = ? AND faction_id = ?', { tonumber(d.id) or 0, f.id })
    notify(src, 'success', 'Dienstkleidung gelöscht.')
  end
end)

-- ---------------------------------------------------------------- Lager

RegisterNetEvent('tacov:factions:storage', function()
  local src = source
  local f, c = TacoV.Factions.of(src)
  if not f then return end
  if not TacoV.Factions.has(src, 'storage_view') then notify(src, 'error', 'Kein Zugriff auf das Lager.') return end
  if not nearFactionPoint(src, 'faction_storage', f.id, 4.0) then notify(src, 'error', 'Das Lager ist im Fraktionsgebäude.') return end
  local inv = TacoV.Inventory.load('faction', f.num, F.storageKg)
  local limitKg = F.dailyStorageKg[c.faction_rank]
  TacoV.Inventory.openContainer(src, inv, {
    title = f.label .. ' · Lager', subtitle = ('%d kg%s'):format(F.storageKg, limitKg and (' · Entnahme heute max. ' .. limitKg .. ' kg') or ''),
    check = function(s) return nearFactionPoint(s, 'faction_storage', f.id, 6.0) ~= nil end,
    allow = function(s, direction, item, amount)
      if direction == 'put' then
        if not TacoV.Factions.has(s, 'storage_put') then return false, 'Einlagern darfst du nicht.' end
        return true
      end
      if not TacoV.Factions.has(s, 'storage_take') then return false, 'Entnehmen darfst du nicht.' end
      local cc = TacoV.Characters.get(s)
      local limit = F.dailyStorageKg[cc.faction_rank]
      if limit then
        local grams = math.floor(((TacoV.Config.Items[item] and TacoV.Config.Items[item].weight) or 0) * amount * 1000)
        local used = daily(cc.id)
        if used + grams > limit * 1000 then return false, ('Tageslimit: noch %.1f kg.'):format(math.max(0, limit - used / 1000)) end
        addDaily(cc.id, grams, 0)
      end
      local def = TacoV.Config.Items[item]
      log(f, cc, 'storage_take', ('%s entnimmt %dx %s'):format(fullName(cc), amount, def and def.label or item))
      return true
    end,
  })
end)

-- ---------------------------------------------------------------- Kasse

RegisterNetEvent('tacov:factions:treasury', function(action, amount)
  local src = source
  local f, c = TacoV.Factions.of(src)
  if not f then return end
  amount = TacoV.Util.money(tonumber(amount) or 0)
  if amount <= 0 then return end
  if action == 'deposit' then
    local ok = TacoV.Journal.move('bank', { type = 'character', id = c.id }, { type = 'faction', id = f.num }, amount, 'fraktionskasse', { actor = c.id, note = 'Einzahlung' })
    if not ok then notify(src, 'error', 'Nicht genug auf dem Konto.') return end
    log(f, c, 'deposit', ('%s zahlt %s $ in die Kasse'):format(fullName(c), fmt(amount)))
    notify(src, 'success', ('%s $ eingezahlt.'):format(fmt(amount)))
  elseif action == 'withdraw' then
    if not TacoV.Factions.has(src, 'treasury_withdraw') then notify(src, 'error', 'Auszahlen darfst du nicht.') return end
    local limit = F.dailyTreasury[c.faction_rank]
    if limit then
      local _, used = daily(c.id)
      if used + amount > limit then notify(src, 'error', ('Tageslimit: noch %s $.'):format(fmt(limit - used))) return end
    end
    local ok = TacoV.Journal.move('bank', { type = 'faction', id = f.num }, { type = 'character', id = c.id }, amount, 'fraktionskasse', { actor = c.id, note = 'Auszahlung' })
    if not ok then notify(src, 'error', 'So viel ist nicht in der Kasse.') return end
    if limit then addDaily(c.id, 0, amount) end
    log(f, c, 'withdraw', ('%s zahlt %s $ aus der Kasse aus'):format(fullName(c), fmt(amount)))
    notify(src, 'success', ('%s $ ausgezahlt.'):format(fmt(amount)))
  else
    return
  end
  TacoV.Accounts.push(src)
  TriggerClientEvent('tacov:factions:data', src, overview(src))
end)

RegisterNetEvent('tacov:factions:journal', function()
  local src = source
  local f = TacoV.Factions.of(src)
  if not f or not TacoV.Factions.has(src, 'treasury_view') then return end
  local rows = TacoV.DB.query(
    "SELECT j.amount, j.reason, j.note, j.at, j.from_type, j.to_type, c.first_name, c.last_name FROM journal j LEFT JOIN characters c ON c.id = j.actor_character_id " ..
    "WHERE (j.from_type = 'faction' AND j.from_id = ?) OR (j.to_type = 'faction' AND j.to_id = ?) ORDER BY j.id DESC LIMIT 30", { f.num, f.num }) or {}
  TriggerClientEvent('tacov:factions:journal', src, rows)
end)

RegisterNetEvent('tacov:factions:log', function()
  local src = source
  local f = TacoV.Factions.of(src)
  if not f or not TacoV.Factions.has(src, 'treasury_view') then return end
  local rows = TacoV.DB.query('SELECT action, text, created_at FROM faction_log WHERE faction_id = ? ORDER BY id DESC LIMIT 40', { f.id }) or {}
  TriggerClientEvent('tacov:factions:log', src, rows)
end)

-- ---------------------------------------------------------------- Mitglieder verwalten, Ränge, Rechte

RegisterNetEvent('tacov:factions:member', function(action, cid, value)
  local src = source
  local f, c = TacoV.Factions.of(src)
  cid = tonumber(cid)
  if not f or not cid then return end
  local target = TacoV.DB.single('SELECT id, first_name, last_name, faction, faction_rank FROM characters WHERE id = ? AND faction = ?', { cid, f.id })
  if not target then return end
  local tsrc = srcOfCharacter(cid)
  local myRank = c.faction_rank
  local isLeader = TacoV.Factions.has(src, 'leader')
  if action == 'rank' then
    local newRank = math.max(1, math.min(F.maxRank, tonumber(value) or 1))
    if not TacoV.Factions.has(src, 'ranks_manage') then notify(src, 'error', 'Ränge vergeben darfst du nicht.') return end
    local limit = isLeader and (F.maxRank - 1) or (TacoV.Factions.has(src, 'settings') and (F.maxRank - 1) or F.rankManageMax)
    if newRank > limit or target.faction_rank > limit or (not isLeader and target.faction_rank >= myRank) then
      notify(src, 'error', 'Diesen Rang darfst du nicht vergeben.') return
    end
    if f.type == 'crime' and newRank >= 3 and target.faction_rank <= 2 and f.cap > 0 and memberCount(f) >= f.cap then
      notify(src, 'error', ('Voll: höchstens %d Mitglieder.'):format(f.cap)) return
    end
    TacoV.DB.update('UPDATE characters SET faction_rank = ? WHERE id = ?', { newRank, cid })
    if tsrc then TacoV.Characters.get(tsrc).faction_rank = newRank pushCharacter(tsrc) notify(tsrc, 'info', ('Dein Rang: %s.'):format(TacoV.Factions.rankName(f.id, newRank))) end
    log(f, c, 'rank', ('%s setzt %s auf %s'):format(fullName(c), target.first_name .. ' ' .. target.last_name, TacoV.Factions.rankName(f.id, newRank)))
  elseif action == 'kick' then
    if not TacoV.Factions.has(src, 'kick') then notify(src, 'error', 'Entlassen darfst du nicht.') return end
    if cid == c.id then notify(src, 'error', 'Dich selbst entlässt du über „Austreten“.') return end
    if not isLeader and target.faction_rank >= myRank then notify(src, 'error', 'Nicht bei gleichem oder höherem Rang.') return end
    if tsrc then TacoV.Factions.leave(tsrc, 'kick', 'durch ' .. fullName(c)) else leaveOffline(f, cid, 'kick', 'durch ' .. fullName(c)) end
  elseif action == 'leader' then
    if not isLeader or cid == c.id then return end
    TacoV.DB.update('UPDATE characters SET faction_rank = ? WHERE id = ?', { F.maxRank, cid })
    TacoV.DB.update('UPDATE characters SET faction_rank = ? WHERE id = ?', { F.maxRank - 1, c.id })
    c.faction_rank = F.maxRank - 1
    if tsrc then TacoV.Characters.get(tsrc).faction_rank = F.maxRank pushCharacter(tsrc) notify(tsrc, 'success', ('Du bist jetzt Leader von %s.'):format(f.label)) end
    pushCharacter(src)
    log(f, c, 'leader', ('%s übergibt die Leitung an %s'):format(fullName(c), target.first_name .. ' ' .. target.last_name))
  else
    return
  end
  TriggerClientEvent('tacov:factions:data', src, overview(src))
end)

RegisterNetEvent('tacov:factions:leave', function()
  local src = source
  local f = TacoV.Factions.of(src)
  if not f then return end
  if TacoV.Factions.has(src, 'leader') and #members(f) > 1 then notify(src, 'error', 'Übergib erst die Leitung.') return end
  TacoV.Factions.leave(src, 'leave')
  TriggerClientEvent('tacov:factions:data', src, false)
end)

RegisterNetEvent('tacov:factions:rank', function(rank, d)
  local src = source
  local f, c = TacoV.Factions.of(src)
  rank = tonumber(rank)
  if not f or not rank or not f.ranks[rank] or type(d) ~= 'table' then return end
  if not TacoV.Factions.has(src, 'settings') then notify(src, 'error', 'Nur die Fraktionsleitung ändert Ränge.') return end
  if rank >= c.faction_rank and not TacoV.Factions.has(src, 'leader') then notify(src, 'error', 'Nur Ränge unter deinem eigenen.') return end
  if d.name then f.ranks[rank].name = TacoV.Util.cleanText(d.name, 32) end
  if d.toggle and F.rightLabels[d.toggle] and d.toggle ~= 'leader' and rank < F.maxRank then
    f.ranks[rank].rights[d.toggle] = (not f.ranks[rank].rights[d.toggle]) or nil
  end
  saveRank(f, rank)
  log(f, c, 'ranks', ('%s ändert Rang %d (%s)'):format(fullName(c), rank, f.ranks[rank].name))
  -- alle Mitglieder mit diesem Rang aktualisieren (HUD-Rangname)
  for _, pid in ipairs(GetPlayers()) do
    local oc = TacoV.Characters.get(tonumber(pid))
    if oc and oc.faction == f.id and oc.faction_rank == rank then pushCharacter(tonumber(pid)) end
  end
  TriggerClientEvent('tacov:factions:data', src, overview(src))
end)

-- ---------------------------------------------------------------- Einladen (X-Rad)

RegisterNetEvent('tacov:factions:invite', function(target)
  local src = source
  local f, c = TacoV.Factions.of(src)
  target = tonumber(target)
  if not f or not target or target == src then return end
  if not TacoV.Factions.has(src, 'invite') then notify(src, 'error', 'Einladen darfst du nicht.') return end
  local tc = TacoV.Characters.get(target)
  if not tc then return end
  if tc.faction then notify(src, 'error', 'Schon in einer Fraktion.') return end
  if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(target))) > 4.0 then return end
  invites[target] = { faction = f.id, by = src, at = os.time() }
  notify(src, 'info', ('Einladung an %s geschickt.'):format(fullName(tc)))
  TriggerClientEvent('tacov:factions:invited', target, { faction = f.id, label = f.label, by = fullName(c) })
end)
RegisterNetEvent('tacov:factions:inviteAnswer', function(accept)
  local src = source
  local inv = invites[src]
  invites[src] = nil
  if not inv or os.time() - inv.at > 60 then return end
  if not accept then if GetPlayerPed(inv.by) ~= 0 then notify(inv.by, 'info', 'Einladung abgelehnt.') end return end
  local byC = TacoV.Characters.get(inv.by)
  local ok, err = TacoV.Factions.join(src, inv.faction, 1, byC and ('eingeladen von ' .. fullName(byC)) or nil)
  if not ok then notify(src, 'error', err) end
  if ok and GetPlayerPed(inv.by) ~= 0 then notify(inv.by, 'success', 'Einladung angenommen.') end
end)

-- ---------------------------------------------------------------- Fahrzeuge (Fraktionsgarage)

RegisterNetEvent('tacov:factions:vehicle', function(id)
  local src = source
  local f, c = TacoV.Factions.of(src)
  if not f then return end
  local loc = nearFactionPoint(src, 'faction_garage', f.id, 25.0)
  if not loc or not loc.spawn then notify(src, 'error', 'Fahrzeuge gibt es nur an der Fraktionsgarage (mit Ausfahrt).') return end
  if not onDuty[src] and f.type == 'state' then notify(src, 'error', 'Nur im Dienst.') return end
  local row = TacoV.DB.single('SELECT * FROM faction_vehicles WHERE id = ? AND faction_id = ?', { tonumber(id) or 0, f.id })
  if not row then return end
  if row.min_rank > c.faction_rank then notify(src, 'error', 'Dieses Fahrzeug steht dir noch nicht zu.') return end
  if not TacoV.Factions.has(src, row.min_rank >= 6 and 'vehicles_all' or 'vehicles_basic') then notify(src, 'error', 'Keine Fahrzeugberechtigung.') return end
  local plate = ('%s %03d'):format(f.id:sub(1, 4):upper(), math.random(0, 999))
  TriggerClientEvent('tacov:factions:spawnVehicle', src, { model = row.model, plate = plate, spawn = loc.spawn, faction = f.id })
  log(f, c, 'vehicle', ('%s holt %s (%s)'):format(fullName(c), row.label, plate))
end)

RegisterNetEvent('tacov:factions:vehicleAdd', function(model, label, minRank)
  local src = source
  local f, c = TacoV.Factions.of(src)
  if not f or not TacoV.Factions.has(src, 'settings') then return end
  model = TacoV.Util.cleanText(tostring(model or ''), 32):lower()
  if model == '' then return end
  TacoV.DB.insert('INSERT INTO faction_vehicles (faction_id, model, label, min_rank) VALUES (?, ?, ?, ?)',
    { f.id, model, TacoV.Util.cleanText(label or model, 32), math.max(1, math.min(F.maxRank, tonumber(minRank) or 3)) })
  log(f, c, 'vehicles', ('%s fügt Fahrzeug %s hinzu'):format(fullName(c), model))
  TriggerClientEvent('tacov:factions:data', src, overview(src))
end)
RegisterNetEvent('tacov:factions:vehicleRemove', function(id)
  local src = source
  local f = TacoV.Factions.of(src)
  if not f or not TacoV.Factions.has(src, 'settings') then return end
  TacoV.DB.update('DELETE FROM faction_vehicles WHERE id = ? AND faction_id = ?', { tonumber(id) or 0, f.id })
  TriggerClientEvent('tacov:factions:data', src, overview(src))
end)

-- ---------------------------------------------------------------- Team-Verwaltung (faction.manage)

RegisterNetEvent('tacov:factions:admin', function(action, d)
  local src = source
  if not TacoV.Permissions.has(src, 'faction.manage') then return end
  d = type(d) == 'table' and d or {}
  local actor = TacoV.Characters.get(src)
  if action == 'list' then
    local out = {}
    for id, f in pairs(factions) do out[#out + 1] = { id = id, label = f.label, type = f.type, cap = f.cap, channel = f.channel, members = #members(f) } end
    table.sort(out, function(a, b) return a.label < b.label end)
    TriggerClientEvent('tacov:factions:adminList', src, out)
  elseif action == 'create' then
    local id = tostring(d.id or ''):lower():gsub('[^a-z0-9_]', '')
    if id == '' or factions[id] then notify(src, 'error', 'Kennung leer oder vergeben.') return end
    local channel = F.gang.firstChannel
    for _, f in pairs(factions) do if f.type == 'crime' and f.channel and f.channel >= channel then channel = f.channel + 1 end end
    if channel > TacoV.Config.Phone.factionChannels - 1 then channel = nil end
    TacoV.DB.insert('INSERT INTO factions (id, label, type, cap, channel) VALUES (?, ?, ?, ?, ?)', { id, TacoV.Util.cleanText(d.label or id, 48), 'crime', tonumber(d.cap) or F.gang.cap, channel })
    TacoV.Factions.load()
    TacoV.Log.write('admin', ('Fraktion angelegt: %s (%s)'):format(d.label or id, id), { characterId = actor and actor.id })
    notify(src, 'success', ('Fraktion %s angelegt (Funk %s).'):format(d.label or id, tostring(channel or '–')))
  elseif action == 'setLeader' then
    local f = factions[d.faction]
    local target = tonumber(d.target)
    if not f or not target or not TacoV.Characters.get(target) then return end
    local tc = TacoV.Characters.get(target)
    if tc.faction and tc.faction ~= f.id then TacoV.Factions.leave(target, 'team', 'Team-Versetzung') end
    TacoV.DB.update('DELETE FROM faction_blocks WHERE character_id = ?', { tc.id })
    if not tc.faction then
      local ok, err = TacoV.Factions.join(target, f.id, F.maxRank, 'Team')
      if not ok then notify(src, 'error', err) return end
    else
      tc.faction_rank = F.maxRank
      TacoV.DB.update('UPDATE characters SET faction_rank = ? WHERE id = ?', { F.maxRank, tc.id })
      pushCharacter(target)
    end
    log(f, actor, 'team', ('Team setzt %s als Leader ein'):format(fullName(tc)))
    notify(src, 'success', ('%s ist Leader von %s.'):format(fullName(tc), f.label))
  elseif action == 'setMember' then
    local f = factions[d.faction]
    local target = tonumber(d.target)
    local rank = math.max(1, math.min(F.maxRank, tonumber(d.rank) or 1))
    if not f or not target or not TacoV.Characters.get(target) then return end
    local tc = TacoV.Characters.get(target)
    if tc.faction and tc.faction ~= f.id then TacoV.Factions.leave(target, 'team', 'Team-Versetzung') end
    TacoV.DB.update('DELETE FROM faction_blocks WHERE character_id = ?', { tc.id })
    if not tc.faction then
      local ok, err = TacoV.Factions.join(target, f.id, rank, 'Team')
      if not ok then notify(src, 'error', err) return end
    else
      tc.faction_rank = rank
      TacoV.DB.update('UPDATE characters SET faction_rank = ? WHERE id = ?', { rank, tc.id })
      pushCharacter(target)
    end
    notify(src, 'success', ('%s: %s, %s.'):format(fullName(tc), f.label, TacoV.Factions.rankName(f.id, rank)))
  elseif action == 'remove' then
    local target = tonumber(d.target)
    if target and TacoV.Characters.get(target) and TacoV.Characters.get(target).faction then TacoV.Factions.leave(target, 'team', 'durch das Team') end
  elseif action == 'dissolve' then
    local f = factions[d.faction]
    if not f or f.type == 'state' then notify(src, 'error', 'Staatsfraktionen werden nicht aufgelöst.') return end
    -- Kasse und Lager an den Staat, Mitglieder mit Sperre raus
    local balance = TacoV.Journal.balance('faction', f.num)
    if balance > 0 then TacoV.Journal.move('bank', { type = 'faction', id = f.num }, { type = 'state', id = 0 }, balance, 'aufloesung', { note = f.label }) end
    for _, m in ipairs(members(f)) do
      local ms = srcOfCharacter(m.id)
      if ms then TacoV.Factions.leave(ms, 'dissolve', 'Auflösung') else leaveOffline(f, m.id, 'dissolve', 'Auflösung') end
    end
    TacoV.DB.update('UPDATE factions SET dissolved_at = NOW() WHERE id = ?', { f.id })
    TacoV.Log.write('admin', ('Fraktion aufgelöst: %s'):format(f.label), { characterId = actor and actor.id })
    TacoV.Factions.load()
    notify(src, 'success', ('%s aufgelöst; Kasse an den Staat.'):format(f.label))
  end
end)

-- ---------------------------------------------------------------- Aufräumen

AddEventHandler('tacov:core:characterUnloaded', function(src)
  if onDuty[src] then onDuty[src] = nil Player(src).state:set('duty', false, true) end
  invites[src] = nil
end)
AddEventHandler('playerDropped', function() onDuty[source] = nil invites[source] = nil end)
