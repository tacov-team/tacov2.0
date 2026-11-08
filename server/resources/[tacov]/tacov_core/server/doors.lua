-- Türen (Punkt 5.4): Tür-Teile (Modell + Position) mit Zugang je Fraktion/Rang oder Schlüssel-Item; Zustand zu/offen für alle
-- synchron. Team im Dienst mit Recht `creator` darf jede Tür bedienen.
TacoV = TacoV or {}
TacoV.Doors = {}

local doors = {}      -- [id] = { id, label, parts, access, locked, autoClose }
local timers = {}

local function notify(src, kind, text) TriggerClientEvent('tacov:core:notify', src, kind, text) end
local function need(src, right)
  if TacoV.Permissions.has(src, right) then return true end
  notify(src, 'error', 'Dafür fehlt dir das Recht (oder du bist nicht im Admin-Dienst).')
  return false
end

local function publicList()
  local list = {}
  for _, d in pairs(doors) do
    list[#list + 1] = { id = d.id, label = d.label, parts = d.parts, locked = d.locked, access = d.access, autoClose = d.autoClose }
  end
  return list
end

local function load()
  doors = {}
  for _, r in ipairs(TacoV.DB.query('SELECT * FROM doors') or {}) do
    doors[r.id] = { id = r.id, label = r.label, parts = json.decode(r.parts) or {}, access = r.access and json.decode(r.access) or {},
      locked = r.locked == 1, autoClose = r.auto_close or 0 }
  end
end

function TacoV.Doors.push(target)
  TriggerClientEvent('tacov:doors:list', target or -1, publicList())
end

function TacoV.Doors.get(id) return doors[id] end

--- Darf die Quelle diese Tür bedienen?
function TacoV.Doors.canUse(src, d)
  return TacoV.Access.check(src, d.access)
end

local function setLocked(d, locked, src)
  d.locked = locked
  TacoV.DB.update('UPDATE doors SET locked = ? WHERE id = ?', { locked and 1 or 0, d.id })
  TriggerClientEvent('tacov:doors:state', -1, d.id, locked)
  if timers[d.id] then timers[d.id] = nil end
  if not locked and (d.autoClose or 0) > 0 then
    local token = {}
    timers[d.id] = token
    SetTimeout(d.autoClose * 1000, function()
      if timers[d.id] == token and doors[d.id] and not doors[d.id].locked then setLocked(doors[d.id], true, nil) end
    end)
  end
  if src then
    local c = TacoV.Characters.get(src)
    TacoV.Log.write('admin', ('Tür #%d „%s“ %s'):format(d.id, d.label, locked and 'abgeschlossen' or 'aufgeschlossen'), { characterId = c and c.id })
  end
end

RegisterNetEvent('tacov:doors:toggle', function(id)
  local src = source
  local d = doors[tonumber(id) or 0]
  if not d then return end
  if not TacoV.Doors.canUse(src, d) then notify(src, 'error', 'Du hast keinen Schlüssel für diese Tür.') return end
  setLocked(d, not d.locked, src)
end)

-- Creator
RegisterNetEvent('tacov:doors:save', function(d)
  local src = source
  if not need(src, 'creator') then return end
  if type(d) ~= 'table' or type(d.parts) ~= 'table' or #d.parts == 0 then notify(src, 'error', 'Tür ohne Teile.') return end
  local parts = {}
  for _, pt in ipairs(d.parts) do
    if tonumber(pt.model) and tonumber(pt.x) then parts[#parts + 1] = { model = math.floor(tonumber(pt.model)), x = tonumber(pt.x), y = tonumber(pt.y), z = tonumber(pt.z) } end
  end
  local access = TacoV.Access.clean(d.access)
  local label = TacoV.Util.cleanText(tostring(d.label or ''), 64)
  local autoClose = math.max(0, math.floor(tonumber(d.autoClose) or 0))
  local locked = d.locked ~= false
  local p = TacoV.Players.get(src)
  local id = tonumber(d.id)
  if id and doors[id] then
    TacoV.DB.update('UPDATE doors SET label = ?, parts = ?, access = ?, locked = ?, auto_close = ?, updated_by = ? WHERE id = ?',
      { label, json.encode(parts), json.encode(access), locked and 1 or 0, autoClose, p and p.discordId, id })
  else
    id = TacoV.DB.insert('INSERT INTO doors (label, parts, access, locked, auto_close, updated_by) VALUES (?, ?, ?, ?, ?, ?)',
      { label, json.encode(parts), json.encode(access), locked and 1 or 0, autoClose, p and p.discordId })
  end
  doors[id] = { id = id, label = label, parts = parts, access = access, locked = locked, autoClose = autoClose }
  TacoV.Log.write('admin', ('Tür gespeichert #%d „%s“ (%d Teile, %s)'):format(id, label, #parts, TacoV.Access.text(access)),
    { discordId = p and p.discordId })
  notify(src, 'success', ('Tür „%s“ gespeichert.'):format(label))
  TacoV.Doors.push(-1)
end)

RegisterNetEvent('tacov:doors:delete', function(id)
  local src = source
  if not need(src, 'creator') then return end
  id = tonumber(id)
  if not id or not doors[id] then return end
  TacoV.DB.update('DELETE FROM doors WHERE id = ?', { id })
  local p = TacoV.Players.get(src)
  TacoV.Log.write('admin', ('Tür gelöscht #%d „%s“'):format(id, doors[id].label), { discordId = p and p.discordId })
  doors[id] = nil
  notify(src, 'success', 'Tür gelöscht.')
  TacoV.Doors.push(-1)
end)

AddEventHandler('tacov:core:ready', function() load() end)
AddEventHandler('tacov:core:characterSelected', function(source) TacoV.Doors.push(source) end)
AddEventHandler('tacov:core:reloadData', function() load() TacoV.Doors.push(-1) end)
