-- Config im Spiel (Server, 5.13): Überschreibungen aus der Datenbank laden, an Clients verteilen, Änderungen prüfen/loggen.
TacoV = TacoV or {}

local overrides = {}

local function notify(src, kind, text) TriggerClientEvent('tacov:core:notify', src, kind, text) end

local function load()
  overrides = {}
  for _, r in ipairs(TacoV.DB.query('SELECT path, value FROM config_overrides') or {}) do
    local ok, v = pcall(json.decode, r.value)
    if ok and v ~= nil then overrides[r.path] = v end
  end
  TacoV.ConfigEdit.apply(overrides)
  local n = 0
  for _ in pairs(overrides) do n = n + 1 end
  if n > 0 then print(('[tacov] %d Config-Überschreibungen geladen'):format(n)) end
end

function TacoV.ConfigEdit.push(target)
  TriggerClientEvent('tacov:config:overrides', target or -1, overrides, TacoV.ConfigEdit.defaults)
end

-- Migrationen laufen vor tacov:core:ready; danach laden und verteilen
AddEventHandler('tacov:core:ready', function() load() TacoV.ConfigEdit.push(-1) end)
AddEventHandler('tacov:core:characterSelected', function(source) TacoV.ConfigEdit.push(source) end)

RegisterNetEvent('tacov:config:set', function(path, value)
  local src = source
  if not TacoV.Permissions.has(src, 'admin.config') then notify(src, 'error', 'Config ändern dürfen nur Manager und höher.') return end
  path = tostring(path or '')
  local before = TacoV.ConfigEdit.get(path)
  if value == nil then -- zurücksetzen
    local def = TacoV.ConfigEdit.defaults[path]
    if def == nil then notify(src, 'info', 'Dieser Wert ist nicht überschrieben.') return end
    TacoV.ConfigEdit.set(path, def)
    overrides[path] = nil
    TacoV.DB.update('DELETE FROM config_overrides WHERE path = ?', { path })
  else
    TacoV.ConfigEdit.remember(path)
    local okSet, err = TacoV.ConfigEdit.set(path, value)
    if not okSet then
      local msgs = { path = 'Pfad unbekannt.', root = 'Bereich nicht bearbeitbar.', leaf = 'Nur Einzelwerte sind änderbar.', type = 'Falscher Typ.' }
      notify(src, 'error', msgs[err] or 'Fehler.')
      return
    end
    overrides[path] = value
    local p = TacoV.Players.get(src)
    TacoV.DB.query('INSERT INTO config_overrides (path, value, updated_by) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE value = VALUES(value), updated_by = VALUES(updated_by)',
      { path, json.encode(value), p and p.discordId })
  end
  local p = TacoV.Players.get(src)
  TacoV.Log.write('admin', ('Config %s: %s → %s%s'):format(path, tostring(before), tostring(TacoV.ConfigEdit.get(path)),
    value == nil and ' (zurückgesetzt)' or ''), { discordId = p and p.discordId })
  notify(src, 'success', ('%s = %s'):format(path, tostring(TacoV.ConfigEdit.get(path))))
  TacoV.ConfigEdit.push(-1)
  TriggerEvent('tacov:config:changed', path)
end)
