-- Aufzüge (5.5) und Portale (5.6): Punkte mit Zugang, Teleport mit Blende. Server prüft Zugang und Nähe, Client blendet.
TacoV = TacoV or {}
TacoV.Teleports = {}

local elevators, portals = {}, {}

local function notify(src, kind, text) TriggerClientEvent('tacov:core:notify', src, kind, text) end
local function need(src, right)
  if TacoV.Permissions.has(src, right) then return true end
  notify(src, 'error', 'Dafür fehlt dir das Recht (oder du bist nicht im Admin-Dienst).')
  return false
end
local function point(v)
  if type(v) ~= 'table' or not tonumber(v.x) then return nil end
  return { x = tonumber(v.x), y = tonumber(v.y), z = tonumber(v.z), h = tonumber(v.h) or 0.0 }
end
local function near(src, pt, maxDist)
  return #(GetEntityCoords(GetPlayerPed(src)) - vector3(pt.x, pt.y, pt.z)) <= (maxDist or 4.0)
end

local function load()
  elevators, portals = {}, {}
  for _, r in ipairs(TacoV.DB.query('SELECT * FROM elevators') or {}) do
    elevators[r.id] = { id = r.id, label = r.label, floors = json.decode(r.floors) or {}, access = r.access and json.decode(r.access) or {} }
  end
  for _, r in ipairs(TacoV.DB.query('SELECT * FROM portals') or {}) do
    portals[r.id] = { id = r.id, label = r.label, entry = json.decode(r.entry), target = json.decode(r.target), oneWay = r.one_way == 1,
      access = r.access and json.decode(r.access) or {} }
  end
end

local function list(t) local out = {} for _, v in pairs(t) do out[#out + 1] = v end return out end
function TacoV.Teleports.push(target)
  TriggerClientEvent('tacov:teleports:list', target or -1, list(elevators), list(portals))
end

-- Benutzen
RegisterNetEvent('tacov:elevator:go', function(id, floorIndex)
  local src = source
  local e = elevators[tonumber(id) or 0]
  local to = e and e.floors[tonumber(floorIndex) or 0]
  if not e or not to then return end
  local atFloor = false
  for _, f in ipairs(e.floors) do if near(src, f, 4.0) then atFloor = true break end end
  if not atFloor then return end
  if not TacoV.Access.check(src, e.access) then notify(src, 'error', 'Du hast keinen Zugang zu diesem Aufzug.') return end
  TriggerClientEvent('tacov:teleports:go', src, to.x, to.y, to.z, to.h)
end)

RegisterNetEvent('tacov:portal:use', function(id, back)
  local src = source
  local p = portals[tonumber(id) or 0]
  if not p then return end
  local from, to = p.entry, p.target
  if back then
    if p.oneWay then return end
    from, to = p.target, p.entry
  end
  if not near(src, from, 4.0) then return end
  if not TacoV.Access.check(src, p.access) then notify(src, 'error', 'Du hast keinen Zugang.') return end
  TriggerClientEvent('tacov:teleports:go', src, to.x, to.y, to.z, to.h)
end)

-- Creator
RegisterNetEvent('tacov:elevator:save', function(e)
  local src = source
  if not need(src, 'creator') then return end
  if type(e) ~= 'table' or type(e.floors) ~= 'table' then return end
  local floors = {}
  for _, f in ipairs(e.floors) do
    local pt = point(f)
    if pt then pt.label = TacoV.Util.cleanText(tostring(f.label or ''), 32) floors[#floors + 1] = pt end
  end
  if #floors == 0 then notify(src, 'error', 'Aufzug ohne Etagen.') return end
  local label = TacoV.Util.cleanText(tostring(e.label or ''), 64)
  local access = TacoV.Access.clean(e.access)
  local p = TacoV.Players.get(src)
  local id = tonumber(e.id)
  if id and elevators[id] then
    TacoV.DB.update('UPDATE elevators SET label = ?, floors = ?, access = ?, updated_by = ? WHERE id = ?', { label, json.encode(floors), json.encode(access), p and p.discordId, id })
  else
    id = TacoV.DB.insert('INSERT INTO elevators (label, floors, access, updated_by) VALUES (?, ?, ?, ?)', { label, json.encode(floors), json.encode(access), p and p.discordId })
  end
  elevators[id] = { id = id, label = label, floors = floors, access = access }
  TacoV.Log.write('admin', ('Aufzug gespeichert #%d „%s“ (%d Etagen, %s)'):format(id, label, #floors, TacoV.Access.text(access)), { discordId = p and p.discordId })
  notify(src, 'success', ('Aufzug „%s“ gespeichert.'):format(label))
  TacoV.Teleports.push(-1)
end)

RegisterNetEvent('tacov:elevator:delete', function(id)
  local src = source
  if not need(src, 'creator') then return end
  id = tonumber(id)
  if not id or not elevators[id] then return end
  TacoV.DB.update('DELETE FROM elevators WHERE id = ?', { id })
  local p = TacoV.Players.get(src)
  TacoV.Log.write('admin', ('Aufzug gelöscht #%d „%s“'):format(id, elevators[id].label), { discordId = p and p.discordId })
  elevators[id] = nil
  notify(src, 'success', 'Aufzug gelöscht.')
  TacoV.Teleports.push(-1)
end)

RegisterNetEvent('tacov:portal:save', function(pt)
  local src = source
  if not need(src, 'creator') then return end
  if type(pt) ~= 'table' then return end
  local entry, target = point(pt.entry), point(pt.target)
  if not entry or not target then notify(src, 'error', 'Portal braucht Eingang und Ausgang.') return end
  local label = TacoV.Util.cleanText(tostring(pt.label or ''), 64)
  local access = TacoV.Access.clean(pt.access)
  local oneWay = pt.oneWay == true
  local p = TacoV.Players.get(src)
  local id = tonumber(pt.id)
  if id and portals[id] then
    TacoV.DB.update('UPDATE portals SET label = ?, entry = ?, target = ?, one_way = ?, access = ?, updated_by = ? WHERE id = ?',
      { label, json.encode(entry), json.encode(target), oneWay and 1 or 0, json.encode(access), p and p.discordId, id })
  else
    id = TacoV.DB.insert('INSERT INTO portals (label, entry, target, one_way, access, updated_by) VALUES (?, ?, ?, ?, ?, ?)',
      { label, json.encode(entry), json.encode(target), oneWay and 1 or 0, json.encode(access), p and p.discordId })
  end
  portals[id] = { id = id, label = label, entry = entry, target = target, oneWay = oneWay, access = access }
  TacoV.Log.write('admin', ('Portal gespeichert #%d „%s“ (%s%s)'):format(id, label, TacoV.Access.text(access), oneWay and ', Einbahn' or ''), { discordId = p and p.discordId })
  notify(src, 'success', ('Portal „%s“ gespeichert.'):format(label))
  TacoV.Teleports.push(-1)
end)

RegisterNetEvent('tacov:portal:delete', function(id)
  local src = source
  if not need(src, 'creator') then return end
  id = tonumber(id)
  if not id or not portals[id] then return end
  TacoV.DB.update('DELETE FROM portals WHERE id = ?', { id })
  local p = TacoV.Players.get(src)
  TacoV.Log.write('admin', ('Portal gelöscht #%d „%s“'):format(id, portals[id].label), { discordId = p and p.discordId })
  portals[id] = nil
  notify(src, 'success', 'Portal gelöscht.')
  TacoV.Teleports.push(-1)
end)

AddEventHandler('tacov:core:ready', function() load() end)
AddEventHandler('tacov:core:characterSelected', function(source) TacoV.Teleports.push(source) end)
