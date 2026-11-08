-- Creator (Server, Phase 5): speichert, was das Team im Spiel setzt, prüft Rechte, protokolliert, verteilt an alle Clients.
TacoV = TacoV or {}
TacoV.Creator = {}

local function notify(src, kind, text) TriggerClientEvent('tacov:core:notify', src, kind, text) end
local function need(src, right)
  if TacoV.Permissions.has(src, right) then return true end
  notify(src, 'error', 'Dafür fehlt dir das Recht (oder du bist nicht im Admin-Dienst).')
  return false
end
local function log(src, text)
  local p = TacoV.Players.get(src)
  TacoV.Log.write('admin', text, { discordId = p and p.discordId })
end

-- ---------------------------------------------------------------- Orte (5.3)

RegisterNetEvent('tacov:creator:loc:save', function(l)
  local src = source
  if not need(src, 'admin.locations') then return end
  if type(l) ~= 'table' or type(l.name) ~= 'string' then return end
  local name = TacoV.Util.cleanText(l.name, 48):lower():gsub('[^%w_]', '_')
  local kind = TacoV.Util.cleanText(tostring(l.kind or ''), 24):lower()
  local label = TacoV.Util.cleanText(tostring(l.label or ''), 64)
  local x, y, z, h = tonumber(l.x), tonumber(l.y), tonumber(l.z), tonumber(l.heading) or 0.0
  if #name == 0 or #kind == 0 or not x or not y or not z then notify(src, 'error', 'Ort unvollständig.') return end
  local extra = type(l.extra) == 'table' and l.extra or {}
  local clean = {}
  if extra.noblip then clean.noblip = true end
  for _, k in ipairs({ 'spawn', 'preview' }) do
    local v = extra[k]
    if type(v) == 'table' and tonumber(v.x) then clean[k] = { x = tonumber(v.x), y = tonumber(v.y), z = tonumber(v.z), h = tonumber(v.h) or 0.0 } end
  end
  if tonumber(extra.limit) then clean.limit = math.floor(tonumber(extra.limit)) end
  local p = TacoV.Players.get(src)
  TacoV.DB.query(
    'INSERT INTO locations (name, kind, x, y, z, heading, label, extra, disabled, updated_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?) ' ..
    'ON DUPLICATE KEY UPDATE kind = VALUES(kind), x = VALUES(x), y = VALUES(y), z = VALUES(z), heading = VALUES(heading), ' ..
    'label = VALUES(label), extra = VALUES(extra), disabled = 0, updated_by = VALUES(updated_by)',
    { name, kind, x, y, z, h, label, json.encode(clean), p and p.discordId })
  log(src, ('Ort gespeichert: %s (%s) „%s“ @ %.1f %.1f %.1f'):format(name, kind, label, x, y, z))
  notify(src, 'success', ('Ort „%s“ gespeichert.'):format(label ~= '' and label or name))
  TriggerEvent('tacov:core:locationChanged', name)
end)

RegisterNetEvent('tacov:creator:loc:delete', function(name)
  local src = source
  if not need(src, 'admin.locations') then return end
  name = TacoV.Util.cleanText(tostring(name or ''), 48)
  local inConfig = false
  for _, l in ipairs(TacoV.Config.Locations) do if l.name == name then inConfig = true break end end
  if inConfig then
    local l = TacoV.Locations.get(name) or {}
    TacoV.DB.query(
      'INSERT INTO locations (name, kind, x, y, z, heading, label, disabled) VALUES (?, ?, ?, ?, ?, ?, ?, 1) ON DUPLICATE KEY UPDATE disabled = 1',
      { name, l.kind or 'none', l.x or 0, l.y or 0, l.z or 0, l.heading or 0, l.label or '' })
  else
    TacoV.DB.update('DELETE FROM locations WHERE name = ?', { name })
  end
  log(src, ('Ort gelöscht: %s'):format(name))
  notify(src, 'success', ('Ort „%s“ gelöscht.'):format(name))
  TriggerEvent('tacov:core:locationChanged', name)
end)
