-- Objekte (5.8) und Zonen (5.9), Server: Speichern/Löschen mit Recht `creator`, Verteilung an Clients, Zonenabfrage.
TacoV = TacoV or {}
TacoV.Props, TacoV.Zones = {}, {}

local props, zones = {}, {}

local function notify(src, kind, text) TriggerClientEvent('tacov:core:notify', src, kind, text) end
local function need(src, right)
  if TacoV.Permissions.has(src, right) then return true end
  notify(src, 'error', 'Dafür fehlt dir das Recht (oder du bist nicht im Admin-Dienst).')
  return false
end
local function list(t) local out = {} for _, v in pairs(t) do out[#out + 1] = v end return out end

local function load()
  props, zones = {}, {}
  for _, r in ipairs(TacoV.DB.query('SELECT * FROM props') or {}) do
    props[r.id] = { id = r.id, label = r.label, model = r.model, x = r.x, y = r.y, z = r.z, rx = r.rx, ry = r.ry, rz = r.rz, onGround = r.on_ground == 1 }
  end
  for _, r in ipairs(TacoV.DB.query('SELECT * FROM zones') or {}) do
    zones[r.id] = { id = r.id, label = r.label, kind = r.kind, shape = r.shape, points = json.decode(r.points) or {}, radius = r.radius, zMin = r.z_min, zMax = r.z_max }
  end
end

function TacoV.Props.push(target) TriggerClientEvent('tacov:props:list', target or -1, list(props)) end
function TacoV.Zones.push(target) TriggerClientEvent('tacov:zones:list', target or -1, list(zones)) end

--- Punkt-in-Zone (Server): für Regeln wie Safezone-Schaden, Fahrzeugverbot
local function inside(z, x, y, zz)
  if z.zMin and zz and zz < z.zMin then return false end
  if z.zMax and zz and zz > z.zMax then return false end
  if z.shape == 'circle' then
    local c = z.points[1]
    return c and ((x - c.x) ^ 2 + (y - c.y) ^ 2) <= z.radius ^ 2
  end
  local pts, n, hit = z.points, #z.points, false
  local j = n
  for i = 1, n do
    local a, b = pts[i], pts[j]
    if ((a.y > y) ~= (b.y > y)) and (x < (b.x - a.x) * (y - a.y) / ((b.y - a.y) ~= 0 and (b.y - a.y) or 1e-9) + a.x) then hit = not hit end
    j = i
  end
  return hit
end

function TacoV.Zones.at(x, y, z, kind)
  local out = {}
  for _, zn in pairs(zones) do
    if (not kind or zn.kind == kind) and inside(zn, x, y, z) then out[#out + 1] = zn end
  end
  return out
end

function TacoV.Zones.playerIn(src, kind)
  local p = GetEntityCoords(GetPlayerPed(src))
  return TacoV.Zones.at(p.x, p.y, p.z, kind)[1]
end

-- Objekte
RegisterNetEvent('tacov:props:save', function(d)
  local src = source
  if not need(src, 'creator') then return end
  if type(d) ~= 'table' or type(d.model) ~= 'string' or not tonumber(d.x) then return end
  local model = TacoV.Util.cleanText(d.model, 64):lower():gsub('[^%w_]', '')
  local label = TacoV.Util.cleanText(tostring(d.label or ''), 64)
  local x, y, z = tonumber(d.x), tonumber(d.y), tonumber(d.z)
  local rx, ry, rz = tonumber(d.rx) or 0.0, tonumber(d.ry) or 0.0, tonumber(d.rz) or 0.0
  local onGround = d.onGround ~= false
  local p = TacoV.Players.get(src)
  local id = tonumber(d.id)
  if id and props[id] then
    TacoV.DB.update('UPDATE props SET label = ?, model = ?, x = ?, y = ?, z = ?, rx = ?, ry = ?, rz = ?, on_ground = ?, updated_by = ? WHERE id = ?',
      { label, model, x, y, z, rx, ry, rz, onGround and 1 or 0, p and p.discordId, id })
  else
    id = TacoV.DB.insert('INSERT INTO props (label, model, x, y, z, rx, ry, rz, on_ground, updated_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      { label, model, x, y, z, rx, ry, rz, onGround and 1 or 0, p and p.discordId })
  end
  props[id] = { id = id, label = label, model = model, x = x, y = y, z = z, rx = rx, ry = ry, rz = rz, onGround = onGround }
  TacoV.Log.write('admin', ('Objekt gespeichert #%d „%s“ (%s) @ %.1f %.1f %.1f'):format(id, label, model, x, y, z), { discordId = p and p.discordId })
  notify(src, 'success', ('Objekt „%s“ gespeichert.'):format(label ~= '' and label or model))
  TacoV.Props.push(-1)
end)

RegisterNetEvent('tacov:props:delete', function(id)
  local src = source
  if not need(src, 'creator') then return end
  id = tonumber(id)
  if not id or not props[id] then return end
  TacoV.DB.update('DELETE FROM props WHERE id = ?', { id })
  local p = TacoV.Players.get(src)
  TacoV.Log.write('admin', ('Objekt gelöscht #%d (%s)'):format(id, props[id].model), { discordId = p and p.discordId })
  props[id] = nil
  notify(src, 'success', 'Objekt gelöscht.')
  TacoV.Props.push(-1)
end)

-- Zonen
RegisterNetEvent('tacov:zones:save', function(d)
  local src = source
  if not need(src, 'creator') then return end
  if type(d) ~= 'table' or type(d.points) ~= 'table' then return end
  local points = {}
  for _, pt in ipairs(d.points) do if tonumber(pt.x) and tonumber(pt.y) then points[#points + 1] = { x = tonumber(pt.x), y = tonumber(pt.y) } end end
  local shape = d.shape == 'poly' and 'poly' or 'circle'
  if (shape == 'circle' and #points < 1) or (shape == 'poly' and #points < 3) then notify(src, 'error', 'Zone braucht einen Mittelpunkt bzw. mindestens 3 Punkte.') return end
  local kind = 'area'
  for _, k in ipairs(TacoV.Config.ZoneKinds) do if k.id == d.kind then kind = k.id end end
  local label = TacoV.Util.cleanText(tostring(d.label or ''), 64)
  local radius = math.max(1.0, math.min(2000.0, tonumber(d.radius) or 20.0))
  local zMin, zMax = tonumber(d.zMin), tonumber(d.zMax)
  local p = TacoV.Players.get(src)
  local id = tonumber(d.id)
  if id and zones[id] then
    TacoV.DB.update('UPDATE zones SET label = ?, kind = ?, shape = ?, points = ?, radius = ?, z_min = ?, z_max = ?, updated_by = ? WHERE id = ?',
      { label, kind, shape, json.encode(points), radius, zMin, zMax, p and p.discordId, id })
  else
    id = TacoV.DB.insert('INSERT INTO zones (label, kind, shape, points, radius, z_min, z_max, updated_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      { label, kind, shape, json.encode(points), radius, zMin, zMax, p and p.discordId })
  end
  zones[id] = { id = id, label = label, kind = kind, shape = shape, points = points, radius = radius, zMin = zMin, zMax = zMax }
  TacoV.Log.write('admin', ('Zone gespeichert #%d „%s“ (%s, %s, %d Punkte)'):format(id, label, kind, shape, #points), { discordId = p and p.discordId })
  notify(src, 'success', ('Zone „%s“ gespeichert.'):format(label))
  TacoV.Zones.push(-1)
end)

RegisterNetEvent('tacov:zones:delete', function(id)
  local src = source
  if not need(src, 'creator') then return end
  id = tonumber(id)
  if not id or not zones[id] then return end
  TacoV.DB.update('DELETE FROM zones WHERE id = ?', { id })
  local p = TacoV.Players.get(src)
  TacoV.Log.write('admin', ('Zone gelöscht #%d „%s“'):format(id, zones[id].label), { discordId = p and p.discordId })
  zones[id] = nil
  notify(src, 'success', 'Zone gelöscht.')
  TacoV.Zones.push(-1)
end)

AddEventHandler('tacov:core:ready', function() load() end)
AddEventHandler('tacov:core:characterSelected', function(source) TacoV.Props.push(source) TacoV.Zones.push(source) end)
exports('zonesAt', TacoV.Zones.at)
