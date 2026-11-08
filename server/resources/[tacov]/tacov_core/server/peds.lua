-- NPCs (Punkt 5.7): Ansprechpartner mit Modell, Position, Szenario und Aufgabe; Clients spawnen sie lokal.
TacoV = TacoV or {}
TacoV.Peds = {}

local peds = {}

local function notify(src, kind, text) TriggerClientEvent('tacov:core:notify', src, kind, text) end
local function need(src, right)
  if TacoV.Permissions.has(src, right) then return true end
  notify(src, 'error', 'Dafür fehlt dir das Recht (oder du bist nicht im Admin-Dienst).')
  return false
end

local function load()
  peds = {}
  for _, r in ipairs(TacoV.DB.query('SELECT * FROM peds') or {}) do
    peds[r.id] = { id = r.id, label = r.label, model = r.model, x = r.x, y = r.y, z = r.z, h = r.h, scenario = r.scenario, task = r.task }
  end
end

function TacoV.Peds.push(target)
  local list = {}
  for _, p in pairs(peds) do list[#list + 1] = p end
  TriggerClientEvent('tacov:peds:list', target or -1, list)
end

RegisterNetEvent('tacov:peds:save', function(d)
  local src = source
  if not need(src, 'creator') then return end
  if type(d) ~= 'table' or type(d.model) ~= 'string' or not tonumber(d.x) then return end
  local model = TacoV.Util.cleanText(d.model, 48):lower():gsub('[^%w_]', '')
  local label = TacoV.Util.cleanText(tostring(d.label or ''), 64)
  local scenario = type(d.scenario) == 'string' and #d.scenario > 0 and TacoV.Util.cleanText(d.scenario, 64):upper():gsub('[^%w_]', '') or nil
  local task = nil
  for _, t in ipairs(TacoV.Config.PedTasks) do if t.id ~= '' and t.id == d.task then task = t.id end end
  local x, y, z, h = tonumber(d.x), tonumber(d.y), tonumber(d.z), tonumber(d.h) or 0.0
  local p = TacoV.Players.get(src)
  local id = tonumber(d.id)
  if id and peds[id] then
    TacoV.DB.update('UPDATE peds SET label = ?, model = ?, x = ?, y = ?, z = ?, h = ?, scenario = ?, task = ?, updated_by = ? WHERE id = ?',
      { label, model, x, y, z, h, scenario, task, p and p.discordId, id })
  else
    id = TacoV.DB.insert('INSERT INTO peds (label, model, x, y, z, h, scenario, task, updated_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      { label, model, x, y, z, h, scenario, task, p and p.discordId })
  end
  peds[id] = { id = id, label = label, model = model, x = x, y = y, z = z, h = h, scenario = scenario, task = task }
  TacoV.Log.write('admin', ('NPC gespeichert #%d „%s“ (%s, %s) @ %.1f %.1f %.1f'):format(id, label, model, task or 'ohne Aufgabe', x, y, z), { discordId = p and p.discordId })
  notify(src, 'success', ('NPC „%s“ gespeichert.'):format(label))
  TacoV.Peds.push(-1)
end)

RegisterNetEvent('tacov:peds:delete', function(id)
  local src = source
  if not need(src, 'creator') then return end
  id = tonumber(id)
  if not id or not peds[id] then return end
  TacoV.DB.update('DELETE FROM peds WHERE id = ?', { id })
  local p = TacoV.Players.get(src)
  TacoV.Log.write('admin', ('NPC gelöscht #%d „%s“'):format(id, peds[id].label), { discordId = p and p.discordId })
  peds[id] = nil
  notify(src, 'success', 'NPC gelöscht.')
  TacoV.Peds.push(-1)
end)

AddEventHandler('tacov:core:ready', function() load() end)
AddEventHandler('tacov:core:characterSelected', function(source) TacoV.Peds.push(source) end)
