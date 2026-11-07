-- Orte: Config-Vorgaben plus Überschreibungen aus der Tabelle locations (/ort setzen). Clients bekommen die Liste.
TacoV = TacoV or {}
TacoV.Locations = {}

local merged = nil

function TacoV.Locations.all()
  if merged then return merged end
  local byName = {}
  local order = {}
  for _, l in ipairs(TacoV.Config.Locations) do
    local e = {}
    for k, v in pairs(l) do e[k] = v end -- Zusatzfelder (shop, category, dealer, spawn) bleiben erhalten
    e.heading = l.heading or 0.0
    byName[l.name] = e
    order[#order + 1] = l.name
  end
  local rows = TacoV.DB.query('SELECT name, kind, label, x, y, z, heading FROM locations') or {}
  for _, r in ipairs(rows) do
    if not byName[r.name] then order[#order + 1] = r.name end
    local base = byName[r.name] or {}
    local e = {}
    for k, v in pairs(base) do e[k] = v end
    e.name, e.kind, e.label = r.name, r.kind, (r.label ~= '' and r.label) or base.label or r.name
    e.x, e.y, e.z, e.heading = r.x, r.y, r.z, r.heading or 0.0
    -- Ausfahrt wandert mit, wenn der Ort per Befehl verschoben wurde
    if base.spawn and (base.x ~= r.x or base.y ~= r.y) then e.spawn = { x = r.x, y = r.y, z = r.z, h = r.heading or 0.0 } end
    byName[r.name] = e
  end
  merged = {}
  for _, n in ipairs(order) do merged[#merged + 1] = byName[n] end
  return merged
end

function TacoV.Locations.get(name)
  for _, l in ipairs(TacoV.Locations.all()) do
    if l.name == name then return l end
  end
  return nil
end

--- Nächster Ort einer Art zur Quelle; gibt Ort und Entfernung zurück.
function TacoV.Locations.nearest(source, kind, maxDist)
  local pos = GetEntityCoords(GetPlayerPed(source))
  local best, bestD = nil, maxDist or 5.0
  for _, l in ipairs(TacoV.Locations.all()) do
    if l.kind == kind then
      local d = #(pos - vector3(l.x, l.y, l.z))
      if d < bestD then best, bestD = l, d end
    end
  end
  return best, bestD
end

function TacoV.Locations.push(target)
  TriggerClientEvent('tacov:core:locations', target or -1, TacoV.Locations.all())
end

AddEventHandler('tacov:core:locationChanged', function()
  merged = nil
  TacoV.Locations.push(-1)
end)

AddEventHandler('tacov:core:characterSelected', function(source)
  TacoV.Locations.push(source)
end)

exports('locationNearest', TacoV.Locations.nearest)
exports('locationGet', TacoV.Locations.get)
