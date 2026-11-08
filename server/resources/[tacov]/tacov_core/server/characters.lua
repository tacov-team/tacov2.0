-- Charaktere: Auswahl, Anlage, Laden, Speichern, Level (Konzept 1, Abschnitte 4–6).
TacoV = TacoV or {}
TacoV.Characters = {}

local loaded = {}   -- [source] = Charakter-Tabelle aus der DB plus Laufzeitfelder

local function levelFromSeconds(sec)
  local hours = sec / 3600
  return math.max(1, math.floor(hours / TacoV.Config.Level.hoursPerLevel) + 1)
end

--- Charakterliste eines Spielers für die Auswahl.
function TacoV.Characters.list(playerId)
  return TacoV.DB.query(
    'SELECT id, slot, first_name, last_name, birth_date, playtime_seconds, level_cache, faction, immigrated_at ' ..
    'FROM characters WHERE player_id = ? AND deleted_at IS NULL ORDER BY slot',
    { playerId }
  ) or {}
end

--- Höchstes Level über alle Charaktere; schaltet den zweiten Platz frei.
function TacoV.Characters.maxLevel(playerId)
  return TacoV.DB.scalar('SELECT COALESCE(MAX(level_cache), 0) FROM characters WHERE player_id = ? AND deleted_at IS NULL', { playerId }) or 0
end

local function nameBlocked(first, last)
  local full = (first .. ' ' .. last):lower()
  local rows = TacoV.DB.query('SELECT pattern FROM name_blocklist') or {}
  for _, r in ipairs(rows) do
    if full:find(r.pattern:lower(), 1, true) then return true end
  end
  return false
end

local function validName(s)
  -- Buchstaben (auch Umlaute), Bindestrich, Apostroph; 2–32 Zeichen; beginnt mit Großbuchstabe
  if #s < 2 or #s > 32 then return false end
  if not s:match("^[A-ZÄÖÜ][A-Za-zÄÖÜäöüß'%-]+$") then return false end
  return true
end

--- Aussehen aus dem Editor bereinigen (nur bekannte Felder, Zahlenbereiche)
function TacoV.Characters.cleanAppearance(a, gender)
  a = type(a) == 'table' and a or {}
  local function num(v, lo, hi, d) v = tonumber(v) if not v then return d end return math.max(lo, math.min(hi, v)) end
  local model = (tonumber(gender) == 1) and 'mp_f_freemode_01' or 'mp_m_freemode_01'
  if a.model == 'mp_f_freemode_01' or a.model == 'mp_m_freemode_01' then model = a.model end
  local p = type(a.parents) == 'table' and a.parents or {}
  local face = {}
  for i = 1, 20 do face[i] = num(type(a.face) == 'table' and a.face[i], -1.0, 1.0, 0.0) end
  local h = type(a.hair) == 'table' and a.hair or {}
  local overlays = {}
  for id, o in pairs(type(a.overlays) == 'table' and a.overlays or {}) do
    if type(o) == 'table' then overlays[tostring(id)] = { style = math.floor(num(o.style, -1, 60, -1)), opacity = num(o.opacity, 0.0, 1.0, 1.0), color = math.floor(num(o.color, 0, 80, 0)) } end
  end
  local function pairsOf(t, maxIdx)
    local out = {}
    for k, v in pairs(type(t) == 'table' and t or {}) do
      if tonumber(k) and type(v) == 'table' then out[tostring(math.floor(tonumber(k)))] = { math.floor(num(v[1], -1, maxIdx, 0)), math.floor(num(v[2], 0, 60, 0)) } end
    end
    return out
  end
  return {
    model = model,
    parents = { father = math.floor(num(p.father, 0, 45, 0)), mother = math.floor(num(p.mother, 0, 45, 21)), shapeMix = num(p.shapeMix, 0.0, 1.0, 0.5), skinMix = num(p.skinMix, 0.0, 1.0, 0.5) },
    face = face,
    hair = { style = math.floor(num(h.style, 0, 200, 0)), color = math.floor(num(h.color, 0, 80, 0)), highlight = math.floor(num(h.highlight, 0, 80, 0)) },
    eyeColor = math.floor(num(a.eyeColor, 0, 31, 0)),
    overlays = overlays,
    components = pairsOf(a.components, 500),
    props = pairsOf(a.props, 500),
  }
end

--- Speichert ein neues Aussehen (Friseur, Chirurg, Kleiderladen)
function TacoV.Characters.setAppearance(source, a)
  local c = loaded[source]
  if not c then return false end
  c.appearance = TacoV.Characters.cleanAppearance(a, c.gender)
  TacoV.DB.update('UPDATE characters SET appearance = ? WHERE id = ?', { json.encode(c.appearance), c.id })
  return true
end

--- Legt einen Charakter an. data = { firstName, lastName, birthDate 'YYYY-MM-DD', origin, gender, appearance }
function TacoV.Characters.create(source, data)
  local p = TacoV.Players.get(source)
  if not p then return false, 'player' end
  local chars = TacoV.Characters.list(p.id)
  local cfg = TacoV.Config.Server
  if #chars >= cfg.charactersPerPlayer then return false, 'slots' end
  if #chars >= 1 and TacoV.Characters.maxLevel(p.id) < cfg.secondCharacterLevel then return false, 'level' end

  local first = TacoV.Util.cleanText(data.firstName, 32)
  local last = TacoV.Util.cleanText(data.lastName, 32)
  if not validName(first) or not validName(last) then return false, 'name' end
  if nameBlocked(first, last) then return false, 'name_blocked' end
  if TacoV.DB.scalar('SELECT COUNT(*) FROM characters WHERE first_name = ? AND last_name = ?', { first, last }) > 0 then
    return false, 'name_taken'
  end
  if not tostring(data.birthDate or ''):match('^%d%d%d%d%-%d%d%-%d%d$') then return false, 'birth' end

  local slot = 1
  for _, c in ipairs(chars) do if c.slot == slot then slot = slot + 1 end end

  local id = TacoV.DB.insert(
    'INSERT INTO characters (player_id, slot, first_name, last_name, birth_date, origin, gender, appearance, position) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
    { p.id, slot, first, last, data.birthDate, TacoV.Util.cleanText(data.origin, 64),
      TacoV.Util.intInRange(data.gender, 0, 1) and data.gender or 0,
      json.encode(TacoV.Characters.cleanAppearance(data.appearance, data.gender)), json.encode(TacoV.Config.Onboarding.spawn) }
  )
  -- Konto anlegen; Startgeld und Ausstattung gibt es erst mit bestandener Einreise (Punkt 6.4). Bis dahin: nur Reisepass.
  TacoV.Journal.account('character', id)
  local inv = TacoV.Inventory.load('character', id)
  for _, s in ipairs(TacoV.Config.StartItems) do
    local meta = s.item == 'passport' and { name = first .. ' ' .. last, birth = data.birthDate } or nil
    TacoV.Inventory.add(inv, s.item, s.amount, meta)
  end
  TacoV.Log.write('character', ('Charakter angelegt: %s %s (#%d)'):format(first, last, id),
    { discordId = p.discordId, characterId = id })
  return true, id
end

--- Lädt einen Charakter für die Quelle und schickt ihn ins Spiel.
function TacoV.Characters.select(source, characterId)
  local p = TacoV.Players.get(source)
  if not p then return false, 'player' end
  local c = TacoV.DB.single('SELECT * FROM characters WHERE id = ? AND player_id = ? AND deleted_at IS NULL', { characterId, p.id })
  if not c then return false, 'character' end
  local denied = nil
  TriggerEvent('tacov:core:beforeSelect', source, c, function(reason) denied = reason end)
  if denied then return false, denied end
  c.appearance = c.appearance and json.decode(c.appearance) or {}
  c.position = c.position and json.decode(c.position) or TacoV.Config.Onboarding.spawn
  c.needs = c.needs and json.decode(c.needs) or { hunger = 100, thirst = 100 }
  c.sessionStart = os.time()
  c.activeSeconds = 0
  c.lastActive = os.time()
  loaded[source] = c
  p.characterId = c.id
  TacoV.Log.write('character', ('Charakter geladen: %s %s'):format(c.first_name, c.last_name),
    { discordId = p.discordId, characterId = c.id })
  TriggerEvent('tacov:core:characterSelected', source, c.id)
  TriggerClientEvent('tacov:core:characterLoaded', source, TacoV.Characters.publicData(source))
  TacoV.Needs.push(source)
  return true
end

function TacoV.Characters.get(source)
  return loaded[source]
end

--- Daten, die der Client sehen darf (kein Kontostand anderer, keine internen Felder).
function TacoV.Characters.publicData(source)
  local c = loaded[source]
  if not c then return nil end
  return {
    id = c.id, firstName = c.first_name, lastName = c.last_name,
    level = levelFromSeconds(c.playtime_seconds + (c.activeSeconds or 0)),
    playtimeSeconds = c.playtime_seconds + (c.activeSeconds or 0),
    faction = c.faction, factionRank = c.faction_rank,
    immigrated = c.immigrated_at ~= nil,
    position = c.position, needs = c.needs, appearance = c.appearance,
    bank = TacoV.Journal.balance('character', c.id),
  }
end

--- Meldet Aktivität (Bewegung, Eingabe); AFK zählt nicht als Spielzeit (Konzept 1).
function TacoV.Characters.touch(source)
  local c = loaded[source]
  if c then c.lastActive = os.time() end
end

--- Schreibt Position, Bedürfnisse und Spielzeit in die DB.
function TacoV.Characters.save(source, position)
  local c = loaded[source]
  if not c then return end
  if position then c.position = position end
  local play = c.playtime_seconds + (c.activeSeconds or 0)
  TacoV.DB.update(
    'UPDATE characters SET position = ?, needs = ?, playtime_seconds = ?, level_cache = ?, noob_protection = ? WHERE id = ?',
    { json.encode(c.position), json.encode(c.needs), play, levelFromSeconds(play),
      levelFromSeconds(play) < TacoV.Config.Level.noobProtectionUntil and 1 or 0, c.id }
  )
  c.playtime_seconds = play
  c.activeSeconds = 0
end

function TacoV.Characters.unload(source)
  TacoV.Characters.save(source)
  local c = loaded[source]
  if c then TriggerEvent('tacov:core:characterUnloaded', source, c.id) end
  loaded[source] = nil
  local p = TacoV.Players.get(source)
  if p then p.characterId = nil end
end

-- Spielzeit-Zähler: jede Sekunde für aktive (nicht AFK) Charaktere
CreateThread(function()
  while true do
    Wait(1000)
    local now = os.time()
    local afk = TacoV.Config.Level.afkMinutes * 60
    for _, c in pairs(loaded) do
      if now - (c.lastActive or now) < afk then
        c.activeSeconds = (c.activeSeconds or 0) + 1
      end
    end
  end
end)

--- Charakter vollständig löschen (Name wird frei): Charakterzeile, Inventare, Konto, Fahrzeuge, Schlüssel, Führerscheine,
--- Outfits, Wohnung, Neulingspfad, Erstattungen. Journal und Logs bleiben als Nachweis. Online → zurück zur Charakterauswahl.
function TacoV.Characters.hardDelete(characterId, actorSrc)
  local row = TacoV.DB.single('SELECT id, first_name, last_name, player_id FROM characters WHERE id = ?', { characterId })
  if not row then return false, 'Charakter nicht gefunden.' end
  local onlineSrc
  for src, c in pairs(loaded) do if c.id == characterId then onlineSrc = src end end
  if onlineSrc then
    TacoV.Characters.unload(onlineSrc)
    TriggerClientEvent('tacov:core:notify', onlineSrc, 'warn', 'Dein Charakter wurde gelöscht.')
  end
  TacoV.DB.update('DELETE FROM inventory_items WHERE owner_type = \'character\' AND owner_id = ?', { characterId })
  TacoV.DB.update('DELETE FROM accounts WHERE owner_type = \'character\' AND owner_id = ?', { characterId })
  TacoV.DB.update('DELETE FROM vehicle_keys WHERE character_id = ?', { characterId })
  TacoV.DB.update('DELETE FROM vehicles WHERE owner_type = \'character\' AND owner_id = ?', { characterId })
  for _, t in ipairs({ 'licenses', 'outfits', 'newbie_steps', 'refunds' }) do
    TacoV.DB.update(('DELETE FROM %s WHERE character_id = ?'):format(t), { characterId })
  end
  local homes = TacoV.DB.query('SELECT id FROM homes WHERE character_id = ?', { characterId }) or {}
  for _, h in ipairs(homes) do TacoV.DB.update('DELETE FROM inventory_items WHERE owner_type = \'house\' AND owner_id = ?', { h.id }) end
  TacoV.DB.update('DELETE FROM homes WHERE character_id = ?', { characterId })
  TacoV.DB.update('DELETE FROM characters WHERE id = ?', { characterId })
  local actor = actorSrc and TacoV.Players.get(actorSrc)
  TacoV.Log.write('character', ('Charakter gelöscht (vollständig): %s %s (#%d)'):format(row.first_name, row.last_name, characterId), { discordId = actor and actor.discordId })
  if onlineSrc then
    SetTimeout(1000, function() TriggerEvent('tacov:core:requestCharacters:for', onlineSrc) end)
  end
  return true
end

AddEventHandler('tacov:core:requestCharacters:for', function(src)
  local p = TacoV.Players.get(src)
  if not p then return end
  TriggerClientEvent('tacov:core:characters', src, {
    characters = TacoV.Characters.list(p.id),
    maxSlots = TacoV.Config.Server.charactersPerPlayer,
    secondSlotLevel = TacoV.Config.Server.secondCharacterLevel,
    maxLevel = TacoV.Characters.maxLevel(p.id),
    staffOnline = #TacoV.Players.staff(1),
  })
end)

-- /charreset bestaetigen – eigenen Charakter vollständig löschen (Testphase: Onboarding.allowSelfDelete)
RegisterCommand('charreset', function(src, args)
  if src == 0 then return end
  local c = loaded[src]
  if not c then return end
  if not TacoV.Config.Onboarding.allowSelfDelete and not TacoV.Permissions.has(src, 'admin.db') then
    TriggerClientEvent('tacov:core:notify', src, 'error', 'Das Löschen des eigenen Charakters ist nicht freigeschaltet.')
    return
  end
  if args[1] ~= 'bestaetigen' then
    TriggerClientEvent('tacov:core:notify', src, 'warn', ('Wirklich %s %s komplett löschen? Dann: /charreset bestaetigen'):format(c.first_name, c.last_name))
    return
  end
  TacoV.Characters.hardDelete(c.id, src)
end, false)

RegisterNetEvent('tacov:core:requestCharacters', function()
  local src = source
  local p = TacoV.Players.get(src)
  if not p then return end
  TriggerClientEvent('tacov:core:characters', src, {
    characters = TacoV.Characters.list(p.id),
    maxSlots = TacoV.Config.Server.charactersPerPlayer,
    secondSlotLevel = TacoV.Config.Server.secondCharacterLevel,
    maxLevel = TacoV.Characters.maxLevel(p.id),
    staffOnline = #TacoV.Players.staff(1),
  })
end)

RegisterNetEvent('tacov:core:selectCharacter', function(characterId)
  local src = source
  if not TacoV.Util.intInRange(characterId, 1) then return end
  local ok, err = TacoV.Characters.select(src, characterId)
  if not ok then TriggerClientEvent('tacov:core:notify', src, 'error', 'Charakter konnte nicht geladen werden: ' .. tostring(err)) end
end)

RegisterNetEvent('tacov:core:createCharacter', function(data)
  local src = source
  if type(data) ~= 'table' then return end
  local ok, res = TacoV.Characters.create(src, data)
  if ok then
    TacoV.Characters.select(src, res)
  else
    TriggerClientEvent('tacov:core:notify', src, 'error', 'Charakter nicht angelegt: ' .. tostring(res))
  end
end)

RegisterNetEvent('tacov:core:heartbeat', function(position, active)
  local src = source
  local c = loaded[src]
  if not c then return end
  if type(position) == 'vector3' or type(position) == 'vector4' then c.position = position end
  if active then TacoV.Characters.touch(src) end
end)

exports('getCharacter', TacoV.Characters.get)
