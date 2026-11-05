-- Logs: in die Datenbank und als Event für den Discord-Bot (der Bot liest die Tabelle logs).
TacoV = TacoV or {}
TacoV.Log = {}

-- Kategorien = Discord-Log-Kanäle (Konzept 1, Abschnitt 3; Konzept 4)
TacoV.Log.Categories = {
  'connect', 'character', 'money', 'items', 'faction', 'police', 'medic',
  'justice', 'crime', 'admin', 'support',
}

local valid = {}
for _, c in ipairs(TacoV.Log.Categories) do valid[c] = true end

--- Schreibt einen Logeintrag. data ist optional und wird als JSON abgelegt.
function TacoV.Log.write(category, message, opts)
  opts = opts or {}
  if not valid[category] then category = 'admin' end
  message = TacoV.Util.cleanText(message, 512)
  local data = opts.data and json.encode(opts.data) or nil
  TacoV.DB.insert(
    'INSERT INTO logs (category, character_id, discord_id, message, data) VALUES (?, ?, ?, ?, ?)',
    { category, opts.characterId, opts.discordId, message, data }
  )
  if TacoV.Util.convar('tacov_log_console', 'true') == 'true' then
    print(('^5[log:%s]^7 %s'):format(category, message))
  end
end
