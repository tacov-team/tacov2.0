-- Objekte (5.8) und Zonen (5.9), Client: lokale Requisiten in Reichweite, Zonen-Abfrage mit Betreten/Verlassen-Ereignis,
-- Creator-Menüs (Objekt mit Vorschau am Zeiger; Zone als Kreis oder Polygon).
TacoV = TacoV or {}
TacoV.Props, TacoV.Zones = { list = {} }, { list = {}, current = {} }

-- ---------------------------------------------------------------- Objekte

local spawned = {}

local function loadModel(name)
  local hash = GetHashKey(name)
  if not IsModelValid(hash) then return nil end
  RequestModel(hash)
  local t = GetGameTimer()
  while not HasModelLoaded(hash) and GetGameTimer() - t < 5000 do Wait(20) end
  return HasModelLoaded(hash) and hash or nil
end

local function sig(d) return table.concat({ d.model, d.x, d.y, d.z, d.rx, d.ry, d.rz, tostring(d.onGround) }, '|') end

local function despawn(id)
  local s = spawned[id]
  if s and DoesEntityExist(s.obj) then DeleteEntity(s.obj) end
  spawned[id] = nil
end

local function spawn(d)
  local hash = loadModel(d.model)
  if not hash then return end
  local obj = CreateObjectNoOffset(hash, d.x, d.y, d.z, false, false, false)
  SetModelAsNoLongerNeeded(hash)
  SetEntityRotation(obj, d.rx, d.ry, d.rz, 2, true)
  if d.onGround then PlaceObjectOnGroundProperly(obj) end
  FreezeEntityPosition(obj, true)
  spawned[d.id] = { obj = obj, sig = sig(d) }
end

RegisterNetEvent('tacov:props:list', function(list)
  TacoV.Props.list = {}
  for _, d in ipairs(list or {}) do TacoV.Props.list[d.id] = d end
  for id, s in pairs(spawned) do
    local d = TacoV.Props.list[id]
    if not d or s.sig ~= sig(d) then despawn(id) end
  end
end)

CreateThread(function()
  while true do
    Wait(1000)
    if TacoV.Client.character then
      local pos = GetEntityCoords(PlayerPedId())
      for id, d in pairs(TacoV.Props.list) do
        local dist = #(pos - vector3(d.x, d.y, d.z))
        if dist < 200.0 and not spawned[id] then spawn(d)
        elseif dist > 230.0 and spawned[id] then despawn(id) end
      end
    end
  end
end)

AddEventHandler('onResourceStop', function(res)
  if res == GetCurrentResourceName() then for id in pairs(spawned) do despawn(id) end end
end)

-- ---------------------------------------------------------------- Zonen

local function inside(z, x, y, zz)
  if z.zMin and zz < z.zMin then return false end
  if z.zMax and zz > z.zMax then return false end
  if z.shape == 'circle' then
    local c = z.points[1]
    return c and ((x - c.x) ^ 2 + (y - c.y) ^ 2) <= z.radius ^ 2
  end
  local pts, n, hit = z.points, #z.points, false
  local j = n
  for i = 1, n do
    local a, b = pts[i], pts[j]
    local dy = (b.y - a.y) ~= 0 and (b.y - a.y) or 1e-9
    if ((a.y > y) ~= (b.y > y)) and (x < (b.x - a.x) * (y - a.y) / dy + a.x) then hit = not hit end
    j = i
  end
  return hit
end

RegisterNetEvent('tacov:zones:list', function(list)
  TacoV.Zones.list = list or {}
end)

--- Zone(n), in denen der Spieler steht; kind optional
function TacoV.Zones.inside(kind)
  for _, z in ipairs(TacoV.Zones.current) do if not kind or z.kind == kind then return z end end
  return nil
end

local function kindDef(kind)
  for _, k in ipairs(TacoV.Config.ZoneKinds) do if k.id == kind then return k end end
  return { label = kind, color = { 200, 200, 200 } }
end

CreateThread(function()
  local was = {}
  while true do
    Wait(500)
    if TacoV.Client.character then
      local p = GetEntityCoords(PlayerPedId())
      local now, cur = {}, {}
      for _, z in ipairs(TacoV.Zones.list) do
        if inside(z, p.x, p.y, p.z) then
          now[z.id] = true
          cur[#cur + 1] = z
          if not was[z.id] then
            TriggerEvent('tacov:zone:enter', z)
            TacoV.UI.send('notify', { kind = 'info', text = ('%s: %s'):format(kindDef(z.kind).label, z.label) })
          end
        end
      end
      for id in pairs(was) do
        if not now[id] then
          for _, z in ipairs(TacoV.Zones.list) do if z.id == id then TriggerEvent('tacov:zone:leave', z) end end
        end
      end
      was = now
      TacoV.Zones.current = cur
    end
  end
end)

-- Zonen sichtbar machen (Creator / Entwickler)
TacoV.Zones.debug = false
CreateThread(function()
  while true do
    if TacoV.Zones.debug then
      Wait(0)
      local p = GetEntityCoords(PlayerPedId())
      for _, z in ipairs(TacoV.Zones.list) do
        local c = kindDef(z.kind).color
        if z.shape == 'circle' then
          local m = z.points[1]
          if m and #(p - vector3(m.x, m.y, p.z)) < z.radius + 150.0 then
            DrawMarker(1, m.x, m.y, p.z - 2.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, z.radius * 2, z.radius * 2, 4.0, c[1], c[2], c[3], 70, false, false, 2, false, nil, nil, false)
          end
        else
          local n = #z.points
          for i = 1, n do
            local a, b = z.points[i], z.points[i % n + 1]
            if #(p - vector3(a.x, a.y, p.z)) < 250.0 then
              DrawLine(a.x, a.y, p.z - 1.0, b.x, b.y, p.z - 1.0, c[1], c[2], c[3], 220)
              DrawLine(a.x, a.y, p.z - 1.0, a.x, a.y, p.z + 3.0, c[1], c[2], c[3], 220)
              DrawLine(a.x, a.y, p.z + 3.0, b.x, b.y, p.z + 3.0, c[1], c[2], c[3], 220)
            end
          end
        end
      end
    else
      Wait(500)
    end
  end
end)

-- ---------------------------------------------------------------- Creator: Objekte

local function saveProp(d) TriggerServerEvent('tacov:props:save', d) end

local function propLabel(m)
  for _, e in ipairs(TacoV.Config.PropModels) do if e.model == m then return e.label end end
  return m
end

local function pickProp(cb)
  local items = {}
  for _, e in ipairs(TacoV.Config.PropModels) do items[#items + 1] = { id = e.model, label = e.label, icon = 'box', sub = e.model } end
  items[#items + 1] = { id = '__custom', label = 'Modell eingeben', icon = 'plus', section = 'Sonstiges' }
  TacoV.Menu.open({ id = 'prop_model', title = 'Objekt wählen', icon = 'box', items = items }, function(id)
    if id == '__custom' then
      TacoV.UI.ask({ title = 'Objekt-Modell (prop_…)', maxLength = 64, icon = 'box' }, function(v) if v and #v > 0 then cb(v:lower()) end end)
    else cb(id) end
  end)
end

local function placeProp(d, cb)
  TacoV.Menu.close()
  TacoV.Creator.place({ start = d.x and vector3(d.x, d.y, d.z) or nil, heading = d.rz, label = propLabel(d.model), previewProp = d.model, onGround = d.onGround }, function(pos, h)
    if pos then d.x, d.y, d.z, d.rz = pos.x, pos.y, pos.z, h end
    cb(pos ~= nil)
  end)
end

local function propMenu(d)
  TacoV.Menu.open({ id = 'prop_edit', title = d.label ~= '' and d.label or propLabel(d.model), icon = 'box', info = 'Objekt-Placer', items = {
    { id = 'info', label = d.model, icon = 'box', dim = true, sub = ('%.1f, %.1f, %.1f · Drehung %.0f°'):format(d.x, d.y, d.z, d.rz) },
    { id = 'move', label = 'Neu platzieren', icon = 'pin', section = 'Bearbeiten' },
    { id = 'ground', label = d.onGround and 'Auf Boden ausrichten: an' or 'Auf Boden ausrichten: aus', icon = 'check' },
    { id = 'label', label = 'Bezeichnung', icon = 'doc', sub = d.label },
    { id = 'tp', label = 'Zum Objekt teleportieren', icon = 'next' },
    { id = 'delete', label = 'Objekt löschen', icon = 'x', section = 'Gefahr' },
  } }, function(id)
    if id == 'move' then placeProp(d, function(ok) if ok then saveProp(d) end end)
    elseif id == 'ground' then d.onGround = not d.onGround saveProp(d) TacoV.Menu.back()
    elseif id == 'label' then
      TacoV.UI.ask({ title = 'Bezeichnung', value = d.label, maxLength = 64, icon = 'box' }, function(v) if v and #v > 0 then d.label = v saveProp(d) end end)
    elseif id == 'tp' then TacoV.Menu.close() TacoV.Creator.fadeTeleport(d.x + 1.0, d.y + 1.0, d.z + 1.0, nil)
    elseif id == 'delete' then TriggerServerEvent('tacov:props:delete', d.id) TacoV.Menu.close()
    end
  end)
end

local function newProp()
  pickProp(function(model)
    local d = { model = model, label = '', rx = 0.0, ry = 0.0, rz = 0.0, onGround = true }
    placeProp(d, function(ok) if ok then d.label = propLabel(model) saveProp(d) end end)
  end)
end

function TacoV.Props.openCreator()
  local pos = GetEntityCoords(PlayerPedId())
  local near = {}
  for _, d in pairs(TacoV.Props.list) do near[#near + 1] = { d = d, dist = #(pos - vector3(d.x, d.y, d.z)) } end
  table.sort(near, function(a, b) return a.dist < b.dist end)
  local items = { { id = 'new', label = 'Neues Objekt', icon = 'plus', sub = 'Modell wählen, am Zeiger platzieren, Q/E drehen', section = 'Objekte' } }
  for i, e in ipairs(near) do
    if i > 12 then break end
    items[#items + 1] = { id = tostring(e.d.id), label = e.d.label ~= '' and e.d.label or propLabel(e.d.model), icon = 'box',
      sub = ('%s · %.0f m'):format(e.d.model, e.dist), section = i == 1 and 'Vorhanden (nach Entfernung)' or nil }
  end
  TacoV.Menu.open({ id = 'props', title = 'Objekt-Placer', icon = 'box', info = ('%d Objekte'):format(#near), items = items }, function(id)
    if id == 'new' then newProp() else local d = TacoV.Props.list[tonumber(id)] if d then propMenu(d) end end
  end)
end

-- ---------------------------------------------------------------- Creator: Zonen

local function saveZone(z) TriggerServerEvent('tacov:zones:save', z) end

local function pickKind(cb)
  local items = {}
  for _, k in ipairs(TacoV.Config.ZoneKinds) do items[#items + 1] = { id = k.id, label = k.label, icon = 'pin' } end
  TacoV.Menu.open({ id = 'zone_kind', title = 'Zonenart', icon = 'pin', items = items }, function(id) cb(id) end)
end

local function zoneMenu(z)
  TacoV.Menu.open({ id = 'zone_edit', title = z.label ~= '' and z.label or ('Zone #' .. z.id), icon = 'pin', info = 'Zonen-Creator', items = {
    { id = 'info', icon = 'info', dim = true, label = ('%s · %s'):format(kindDef(z.kind).label,
      z.shape == 'circle' and ('Kreis, Radius %.0f m'):format(z.radius) or ('Polygon, %d Punkte'):format(#z.points)) },
    { id = 'label', label = 'Bezeichnung', icon = 'doc', sub = z.label, section = 'Bearbeiten' },
    { id = 'kind', label = 'Art ändern', icon = 'list', sub = kindDef(z.kind).label },
    z.shape == 'circle' and { id = 'radius', label = 'Radius ändern', icon = 'speed', sub = ('%.0f m'):format(z.radius) }
      or { id = 'repoints', label = 'Punkte neu ablaufen', icon = 'pin' },
    { id = 'height', label = 'Höhenbereich', icon = 'home', sub = (z.zMin or z.zMax) and ('%s bis %s'):format(tostring(z.zMin or '–'), tostring(z.zMax or '–')) or 'unbegrenzt' },
    { id = 'tp', label = 'Zur Zone teleportieren', icon = 'next', section = 'Sonstiges' },
    { id = 'delete', label = 'Zone löschen', icon = 'x', section = 'Gefahr' },
  } }, function(id)
    if id == 'label' then
      TacoV.UI.ask({ title = 'Bezeichnung', value = z.label, maxLength = 64, icon = 'pin' }, function(v) if v and #v > 0 then z.label = v saveZone(z) end end)
    elseif id == 'kind' then pickKind(function(k) z.kind = k saveZone(z) TacoV.Menu.back() end)
    elseif id == 'radius' then
      TacoV.UI.ask({ title = 'Radius in Metern', value = tostring(math.floor(z.radius)), maxLength = 4, numeric = true, icon = 'speed' }, function(v)
        local n = tonumber(v or '') if n then z.radius = n saveZone(z) end
      end)
    elseif id == 'repoints' then
      TacoV.Menu.close()
      z.points = {}
      TacoV.Zones.collectPoints(z, function(ok) if ok then saveZone(z) end end)
    elseif id == 'height' then
      TacoV.UI.ask({ title = 'Untere Höhe (leer = keine)', value = z.zMin and tostring(z.zMin) or '', maxLength = 7, numeric = true, icon = 'home' }, function(a)
        if a == nil then return end
        TacoV.UI.ask({ title = 'Obere Höhe (leer = keine)', value = z.zMax and tostring(z.zMax) or '', maxLength = 7, numeric = true, icon = 'home' }, function(b)
          if b == nil then return end
          z.zMin, z.zMax = tonumber(a), tonumber(b)
          saveZone(z)
        end)
      end)
    elseif id == 'tp' then
      TacoV.Menu.close()
      local c = z.points[1]
      if c then
        local ok, gz = GetGroundZFor_3dCoord(c.x, c.y, 1000.0, false)
        TacoV.Creator.fadeTeleport(c.x, c.y, ok and gz + 1.0 or GetEntityCoords(PlayerPedId()).z, nil)
      end
    elseif id == 'delete' then TriggerServerEvent('tacov:zones:delete', z.id) TacoV.Menu.close()
    end
  end)
end

--- Polygon-Punkte nacheinander platzieren; Enter setzt, Backspace beendet (ab 3 Punkten gültig)
function TacoV.Zones.collectPoints(z, cb)
  local function nextPoint()
    TacoV.Creator.place({ label = ('Zonenpunkt %d (Backspace = fertig)'):format(#z.points + 1) }, function(pos)
      if pos then
        z.points[#z.points + 1] = { x = pos.x, y = pos.y }
        nextPoint()
      else
        cb(#z.points >= 3)
        if #z.points < 3 then TacoV.UI.send('notify', { kind = 'error', text = 'Mindestens 3 Punkte nötig.' }) end
      end
    end)
  end
  nextPoint()
end

local function newZone()
  pickKind(function(kind)
    TacoV.Menu.open({ id = 'zone_shape', title = 'Form', icon = 'pin', items = {
      { id = 'circle', label = 'Kreis', icon = 'pin', sub = 'Mittelpunkt platzieren, Radius eingeben' },
      { id = 'poly', label = 'Polygon', icon = 'list', sub = 'Eckpunkte nacheinander platzieren' },
    } }, function(shape)
      TacoV.Menu.close()
      local z = { kind = kind, shape = shape, points = {}, radius = 20.0, label = '' }
      local function finish()
        TacoV.UI.ask({ title = 'Bezeichnung der Zone', placeholder = 'z. B. Legion Square', maxLength = 64, icon = 'pin' }, function(v)
          z.label = (v and #v > 0) and v or kindDef(kind).label
          saveZone(z)
        end)
      end
      if shape == 'circle' then
        TacoV.Creator.place({ label = 'Mittelpunkt' }, function(pos)
          if not pos then return end
          z.points = { { x = pos.x, y = pos.y } }
          TacoV.UI.ask({ title = 'Radius in Metern', value = '20', maxLength = 4, numeric = true, icon = 'speed' }, function(v)
            z.radius = tonumber(v or '') or 20.0
            finish()
          end)
        end)
      else
        TacoV.Zones.collectPoints(z, function(ok) if ok then finish() end end)
      end
    end)
  end)
end

function TacoV.Zones.openCreator()
  local pos = GetEntityCoords(PlayerPedId())
  local near = {}
  for _, z in ipairs(TacoV.Zones.list) do
    local c = z.points[1]
    near[#near + 1] = { z = z, dist = c and #(pos - vector3(c.x, c.y, pos.z)) or 1e9 }
  end
  table.sort(near, function(a, b) return a.dist < b.dist end)
  local items = {
    { id = 'new', label = 'Neue Zone', icon = 'plus', sub = 'Art, Kreis oder Polygon', section = 'Zonen' },
    { id = 'debug', label = TacoV.Zones.debug and 'Zonen ausblenden' or 'Zonen anzeigen', icon = 'search' },
  }
  for i, e in ipairs(near) do
    if i > 12 then break end
    items[#items + 1] = { id = tostring(e.z.id), label = e.z.label ~= '' and e.z.label or ('Zone #' .. e.z.id), icon = 'pin',
      sub = ('%s · %.0f m'):format(kindDef(e.z.kind).label, e.dist), section = i == 1 and 'Vorhanden (nach Entfernung)' or nil }
  end
  TacoV.Menu.open({ id = 'zones', title = 'Zonen-Creator', icon = 'pin', info = ('%d Zonen'):format(#TacoV.Zones.list), items = items }, function(id)
    if id == 'new' then newZone()
    elseif id == 'debug' then TacoV.Zones.debug = not TacoV.Zones.debug TacoV.Menu.close()
    else for _, z in ipairs(TacoV.Zones.list) do if z.id == tonumber(id) then zoneMenu(z) end end end
  end)
end
