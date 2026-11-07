-- Serverstatus und geplante Neustarts (Punkte 1.7 und 1.9).
-- Status: alle 30 s eine Zeile in `server_status` (Spieler, Slots, Start, nächster Neustart, Version) für das Discord-Embed.
-- Neustart: alle 6 Stunden (config/core.lua), Ansagen 15/5/1 min im Spiel und als Discord-Ansage, Autosave, dann `quit`
-- (systemd startet den Dienst neu).
TacoV = TacoV or {}
TacoV.Status = {}

local startedAt = os.time()
local version = 'dev'
do
  local raw = LoadResourceFile(GetCurrentResourceName(), 'version.json')
  local ok, data = pcall(json.decode, raw or '')
  if ok and type(data) == 'table' and data.version then version = tostring(data.version) end
end

--- Nächster Neustart als Unixzeit (Serverzeit)
function TacoV.Status.nextRestart()
  local now = os.time()
  local t = os.date('*t', now)
  local best
  for _, h in ipairs(TacoV.Config.Restart.hours) do
    local candidate = os.time({ year = t.year, month = t.month, day = t.day, hour = h, min = 0, sec = 0 })
    if candidate <= now then candidate = candidate + 86400 end
    if not best or candidate < best then best = candidate end
  end
  return best
end

local function sqlTime(ts)
  return os.date('%Y-%m-%d %H:%M:%S', ts)
end

local function writeStatus()
  TacoV.DB.update(
    'INSERT INTO server_status (id, players, slots, started_at, next_restart_at, version) VALUES (1, ?, ?, ?, ?, ?) ' ..
    'ON DUPLICATE KEY UPDATE players = VALUES(players), slots = VALUES(slots), started_at = VALUES(started_at), ' ..
    'next_restart_at = VALUES(next_restart_at), version = VALUES(version)',
    { #GetPlayers(), GetConvarInt('sv_maxclients', TacoV.Config.Server.slots), sqlTime(startedAt), sqlTime(TacoV.Status.nextRestart()), version })
end

--- Ansage im Spiel (alle) und für Discord (Tabelle announcements)
function TacoV.Status.announce(kind, text)
  TriggerClientEvent('tacov:core:notify', -1, kind == 'restart' and 'warn' or 'info', text)
  TacoV.DB.insert('INSERT INTO announcements (kind, text) VALUES (?, ?)', { kind, text })
end

AddEventHandler('tacov:core:ready', function()
  CreateThread(function()
    while true do
      writeStatus()
      Wait(TacoV.Config.Status.intervalSeconds * 1000)
    end
  end)

  -- Neustart-Planer: prüft jede Sekunde, sagt bei 15/5/1 Minuten an, speichert und beendet den Prozess
  CreateThread(function()
    local warned = {}
    local target = TacoV.Status.nextRestart()
    while true do
      Wait(1000)
      local left = target - os.time()
      for _, m in ipairs(TacoV.Config.Restart.warnMinutes) do
        if left <= m * 60 and not warned[m] then
          warned[m] = true
          TacoV.Status.announce('restart', ('Neustart in %d %s – bitte Fahrzeuge einparken und Geschäfte abschließen.'):format(m, m == 1 and 'Minute' or 'Minuten'))
        end
      end
      if left <= 0 then
        TacoV.Status.announce('restart', 'Der Server startet jetzt neu und ist in etwa zwei Minuten wieder da.')
        for _, src in ipairs(GetPlayers()) do
          TacoV.Characters.unload(tonumber(src))
        end
        Wait(1500)
        for _, src in ipairs(GetPlayers()) do
          DropPlayer(tonumber(src), TacoV.Config.Restart.kickMessage)
        end
        TacoV.Log.write('admin', 'Geplanter Neustart ausgeführt')
        Wait(2000)
        ExecuteCommand('quit')
        return
      end
    end
  end)
end)

-- /neustart <Minuten> – außerplanmäßiger Neustart mit Ansage (Manager+)
RegisterCommand('neustart', function(src, args)
  if src ~= 0 and not TacoV.Permissions.has(src, 'admin.config') then return end
  local minutes = math.max(1, math.min(60, tonumber(args[1]) or 5))
  TacoV.Status.announce('restart', ('Außerplanmäßiger Neustart in %d Minuten.'):format(minutes))
  CreateThread(function()
    Wait(minutes * 60000 - 60000)
    if minutes > 1 then TacoV.Status.announce('restart', 'Neustart in 1 Minute – bitte Fahrzeuge einparken.') Wait(60000) end
    for _, s in ipairs(GetPlayers()) do TacoV.Characters.unload(tonumber(s)) end
    Wait(1500)
    for _, s in ipairs(GetPlayers()) do DropPlayer(tonumber(s), TacoV.Config.Restart.kickMessage) end
    TacoV.Log.write('admin', 'Außerplanmäßiger Neustart ausgeführt')
    Wait(2000)
    ExecuteCommand('quit')
  end)
end, true)
