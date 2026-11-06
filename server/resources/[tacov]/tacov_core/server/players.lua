-- Spieler (Konto je Discord-ID). Ein Spieler ist online, sobald connect.lua ihn freigegeben hat.
TacoV = TacoV or {}
TacoV.Players = {}

local online = {}   -- [source] = { id, discordId, license, role, characterId, source }

--- Liest die Identifier eines verbundenen Spielers (Discord-ID, FiveM-Lizenz).
function TacoV.Players.identifiers(source)
  local out = {}
  for _, ident in ipairs(GetPlayerIdentifiers(source)) do
    local kind, value = ident:match('^(%w+):(.+)$')
    if kind then out[kind] = value end
  end
  return out
end

--- Lädt oder legt das Spielerkonto zur Discord-ID an und hängt es an die Quelle.
function TacoV.Players.load(source, discordId, license)
  local row = TacoV.DB.single('SELECT id, role FROM players WHERE discord_id = ?', { discordId })
  local id
  if row then
    id = row.id
    TacoV.DB.update('UPDATE players SET license = ?, last_seen_at = NOW() WHERE id = ?', { license, id })
  else
    id = TacoV.DB.insert('INSERT INTO players (discord_id, license, last_seen_at) VALUES (?, ?, NOW())', { discordId, license })
    TacoV.DB.update('UPDATE whitelist SET first_join_at = COALESCE(first_join_at, NOW()) WHERE discord_id = ?', { discordId })
  end
  online[source] = {
    id = id, discordId = discordId, license = license,
    role = row and row.role or 'player', characterId = nil, source = source,
  }
  return online[source]
end

function TacoV.Players.get(source)
  return online[source]
end

function TacoV.Players.all()
  return online
end

function TacoV.Players.count()
  local n = 0
  for _ in pairs(online) do n = n + 1 end
  return n
end

function TacoV.Players.unload(source)
  local p = online[source]
  if not p then return end
  if p.characterId then TacoV.Characters.unload(source) end
  TacoV.DB.update('UPDATE players SET last_seen_at = NOW() WHERE id = ?', { p.id })
  online[source] = nil
end

--- Teammitglieder im Dienst (für Einreise und Support).
function TacoV.Players.staff(minLevel)
  local list = {}
  for src, p in pairs(online) do
    local r = TacoV.Config.Roles[p.role]
    if r and r.level >= (minLevel or 1) then list[#list + 1] = src end
  end
  return list
end

--- Nächster anderer Spieler mit geladenem Charakter innerhalb maxDist (Meter), oder nil.
function TacoV.Players.nearest(source, maxDist)
  local pos = GetEntityCoords(GetPlayerPed(source))
  local best, bestD = nil, maxDist or 3.0
  for src, p in pairs(online) do
    if src ~= source and p.characterId then
      local d = #(pos - GetEntityCoords(GetPlayerPed(src)))
      if d < bestD then best, bestD = src, d end
    end
  end
  return best
end

AddEventHandler('playerDropped', function(reason)
  local src = source
  local p = online[src]
  if p then
    TacoV.Log.write('connect', ('Verbindung getrennt: %s'):format(reason or '?'),
      { discordId = p.discordId, characterId = p.characterId })
    TacoV.Players.unload(src)
  end
end)

exports('getPlayer', TacoV.Players.get)
