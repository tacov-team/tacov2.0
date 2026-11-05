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
    'SELECT id, slot, first_name, last_name, birth_date, playtime_seconds, level_cache, faction, immigrated_at FROM characters WHERE player_id = ? AND deleted_at IS NULL ORDER BY slot',
    { playerId }
  ) or {}
end

--- Höchstes Level über alle Charaktere; schaltet den zweiten Platz frei.
local function maxLevel(playerId)
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

--- Legt einen Charakter an. data = { firstName, lastName, birthDate 'YYYY-MM-DD', origin, gender, appearance }
function TacoV.Characters.create(source, data)
  local p = TacoV.Players.get(source)
  if not p then return false, 'player' end
  local chars = TacoV.Characters.list(p.id)
  local cfg = TacoV.Config.Server
  if #chars >= cfg.charactersPerPlayer then return false, 'slots' end
  if #chars >= 1 and maxLevel(p.id) < cfg.secondCharacterLevel then return false, 'level' end

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
      json.encode(data.appearance or {}), json.encode(TacoV.Config.Onboarding.spawn) }
  )
  -- Girokonto mit Startgeld, über das Journal (Konzept 1: Startgeld aufs Konto)
  TacoV.Journal.account('character', id)
  TacoV.Journal.move('bank', nil, { type = 'character', id = id }, TacoV.Config.Onboarding.startCash, 'startgeld')
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
  TriggerClientEvent('tacov:core:characterLoaded', source, TacoV.Characters.publicData(source))
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

RegisterNetEvent('tacov:core:requestCharacters', function()
  local src = source
  local p = TacoV.Players.get(src)
  if not p then return end
  TriggerClientEvent('tacov:core:characters', src, {
    characters = TacoV.Characters.list(p.id),
    maxSlots = TacoV.Config.Server.charactersPerPlayer,
    secondSlotLevel = TacoV.Config.Server.secondCharacterLevel,
    maxLevel = maxLevel(p.id),
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
