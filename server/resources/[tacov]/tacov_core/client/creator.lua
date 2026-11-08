-- Creator-Grundlage (Phase 5): Platzieren am Zeiger (Kamera-Strahl) mit Tasten zum Feintunen, Texteingabe, Orte-Creator (5.3).
-- Rechte prüft der Server bei jedem Speichern.
TacoV = TacoV or {}
TacoV.Creator = {}

local placing = false

local function camRay(dist)
  local rot = GetGameplayCamRot(2)
  local yaw, pitch = math.rad(rot.z), math.rad(rot.x)
  local dir = vector3(-math.sin(yaw) * math.cos(pitch), math.cos(yaw) * math.cos(pitch), math.sin(pitch))
  local from = GetGameplayCamCoord()
  local to = from + dir * dist
  local handle = StartShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, 1 | 16, PlayerPedId(), 4)
  local _, hit, coords = GetShapeTestResult(handle)
  if hit == 1 then return vector3(coords.x, coords.y, coords.z) end
  return nil
end

local BLOCK = { 22, 24, 25, 37, 44, 38, 10, 11, 172, 173, 174, 175, 177, 191, 194, 199, 200, 201, 202, 27 }

--- Platzieren: opts = { start = vector3|nil, heading = n|nil, label = 'Ort' }; cb(pos, heading) oder cb(nil) bei Abbruch.
--- Leertaste wechselt zwischen „am Zeiger“ und „fest“; Pfeile/Bild↑↓ verschieben, Q/E drehen, Shift = fein, Enter/Backspace.
function TacoV.Creator.place(opts, cb)
  if placing then return false end
  placing = true
  opts = opts or {}
  CreateThread(function()
    local pos = opts.start or GetEntityCoords(PlayerPedId())
    local heading = opts.heading or GetEntityHeading(PlayerPedId())
    local locked = opts.start ~= nil
    TacoV.UI.send('hint', { key = 'Enter', text = (opts.label or 'Ort') ..
      ' platzieren · Leertaste: Zeiger/fest · Pfeile, Bild↑↓ verschieben · Q/E drehen · Shift fein · Backspace abbrechen' })
    while placing do
      Wait(0)
      for _, c in ipairs(BLOCK) do DisableControlAction(0, c, true) end
      local fine = IsControlPressed(0, 21)
      local step = fine and 0.05 or 0.25
      local rstep = fine and 1.0 or 5.0
      if IsDisabledControlJustPressed(0, 22) then locked = not locked end
      if not locked then
        local hit = camRay(60.0)
        if hit then pos = hit end
      end
      local rad = math.rad(heading)
      local fwd = vector3(-math.sin(rad), math.cos(rad), 0.0)
      local right = vector3(math.cos(rad), math.sin(rad), 0.0)
      if IsDisabledControlPressed(0, 172) then pos = pos + fwd * step locked = true end
      if IsDisabledControlPressed(0, 173) then pos = pos - fwd * step locked = true end
      if IsDisabledControlPressed(0, 174) then pos = pos - right * step locked = true end
      if IsDisabledControlPressed(0, 175) then pos = pos + right * step locked = true end
      if IsDisabledControlPressed(0, 10) then pos = pos + vector3(0.0, 0.0, step) locked = true end
      if IsDisabledControlPressed(0, 11) then pos = pos - vector3(0.0, 0.0, step) locked = true end
      if IsDisabledControlPressed(0, 44) then heading = (heading + rstep) % 360 end
      if IsDisabledControlPressed(0, 38) then heading = (heading - rstep) % 360 end
      DrawMarker(1, pos.x, pos.y, pos.z - 0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.5, 167, 139, 250, locked and 170 or 110, false, true, 2, nil, nil, false)
      local tip = pos + fwd * 1.2
      DrawLine(pos.x, pos.y, pos.z + 0.3, tip.x, tip.y, tip.z + 0.3, 255, 255, 255, 220)
      DrawMarker(0, tip.x, tip.y, tip.z + 0.9, 0.0, 0.0, 0.0, 180.0, 0.0, heading, 0.3, 0.3, 0.3, 255, 255, 255, 200, false, true, 2, nil, nil, false)
      if IsDisabledControlJustPressed(0, 191) or IsDisabledControlJustPressed(0, 201) then
        placing = false
        TacoV.UI.send('hint', nil)
        cb(pos, heading)
        return
      end
      if IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 202) then
        placing = false
        TacoV.UI.send('hint', nil)
        cb(nil)
        return
      end
    end
  end)
  return true
end

-- ---------------------------------------------------------------- Orte-Creator (5.3)

local function kinds()
  local seen, list = {}, {}
  for _, l in ipairs(TacoV.Client.locations) do
    if not seen[l.kind] then seen[l.kind] = true list[#list + 1] = l.kind end
  end
  for k in pairs(TacoV.Config.Blips) do if not seen[k] then seen[k] = true list[#list + 1] = k end end
  table.sort(list)
  return list
end
local function kindLabel(k)
  local b = TacoV.Config.Blips[k]
  return b and b.label or k
end

local function saveLocation(l)
  TriggerServerEvent('tacov:creator:loc:save', l)
end

local function askLabel(l, after)
  TacoV.UI.ask({ title = 'Beschriftung', label = l.name, value = l.label or '', maxLength = 64, icon = 'pin' }, function(v)
    if v and #v > 0 then l.label = v saveLocation(l) end
    if after then after() end
  end)
end

local function locationMenu(l)
  local extra = l.extra or {}
  local items = {
    { id = 'info', label = ('%s · %.1f, %.1f, %.1f'):format(kindLabel(l.kind), l.x, l.y, l.z), icon = 'info', dim = true, sub = 'Name ' .. l.name },
    { id = 'move', label = 'Verschieben', icon = 'pin', sub = 'Enter übernimmt, Backspace bricht ab', section = 'Bearbeiten' },
    { id = 'label', label = 'Beschriftung ändern', icon = 'doc', sub = l.label or '' },
    { id = 'kind', label = 'Art ändern', icon = 'list', sub = kindLabel(l.kind) },
    { id = 'blip', label = extra.noblip and 'Blip einblenden' or 'Blip ausblenden', icon = 'search' },
  }
  if l.kind == 'garage' or l.kind == 'impound' or l.kind == 'dealer' then
    items[#items + 1] = { id = 'spawn', label = 'Ausfahrt setzen', icon = 'car', sub = 'Fahrzeuge erscheinen hier', section = 'Fahrzeuge' }
  end
  if l.kind == 'dealer' then items[#items + 1] = { id = 'preview', label = 'Vorschauplatz setzen', icon = 'car', sub = 'Showroom-Fahrzeug' } end
  if l.kind == 'speedcam' then items[#items + 1] = { id = 'limit', label = 'Tempolimit ändern', icon = 'speed', sub = tostring(l.limit or 70) .. ' km/h', section = 'Blitzer' } end
  items[#items + 1] = { id = 'delete', label = 'Löschen', icon = 'x', section = 'Gefahr' }
  TacoV.Menu.open({ id = 'creator_loc', title = l.label or l.name, icon = 'pin', info = 'Orte-Creator', items = items }, function(id)
    if id == 'move' then
      TacoV.Menu.close()
      TacoV.Creator.place({ start = vector3(l.x, l.y, l.z), heading = l.heading, label = l.label or l.name }, function(pos, h)
        if pos then l.x, l.y, l.z, l.heading = pos.x, pos.y, pos.z, h saveLocation(l) end
      end)
    elseif id == 'label' then askLabel(l)
    elseif id == 'kind' then
      local ks = {}
      for _, k in ipairs(kinds()) do ks[#ks + 1] = { id = k, label = kindLabel(k), icon = 'pin', sub = k } end
      TacoV.Menu.open({ id = 'creator_kind', title = 'Art wählen', icon = 'list', info = l.name, items = ks }, function(k)
        l.kind = k saveLocation(l) TacoV.Menu.back()
      end)
    elseif id == 'blip' then
      l.extra = extra
      extra.noblip = not extra.noblip or nil
      saveLocation(l)
      TacoV.Menu.back()
    elseif id == 'spawn' or id == 'preview' then
      TacoV.Menu.close()
      local cur = (id == 'spawn' and l.spawn) or (id == 'preview' and l.preview)
      TacoV.Creator.place({ start = cur and vector3(cur.x, cur.y, cur.z) or nil, heading = cur and cur.h or nil, label = id == 'spawn' and 'Ausfahrt' or 'Vorschauplatz' }, function(pos, h)
        if pos then
          l.extra = extra
          extra[id] = { x = pos.x, y = pos.y, z = pos.z, h = h }
          saveLocation(l)
        end
      end)
    elseif id == 'limit' then
      TacoV.UI.ask({ title = 'Tempolimit (km/h)', label = l.label or l.name, value = tostring(l.limit or 70), maxLength = 3, numeric = true, icon = 'speed' }, function(v)
        local n = tonumber(v or '')
        if n and n >= 10 and n <= 300 then l.extra = extra extra.limit = math.floor(n) saveLocation(l) end
      end)
    elseif id == 'delete' then
      TacoV.Menu.open({ id = 'creator_del', title = 'Wirklich löschen?', icon = 'warn', info = l.label or l.name,
        items = { { id = 'yes', label = 'Ja, löschen', icon = 'x' }, { id = 'no', label = 'Abbrechen', icon = 'back' } } }, function(a)
        if a == 'yes' then TriggerServerEvent('tacov:creator:loc:delete', l.name) TacoV.Menu.close() else TacoV.Menu.back() end
      end)
    end
  end)
end

local function newLocation()
  local ks = {}
  for _, k in ipairs(kinds()) do ks[#ks + 1] = { id = k, label = kindLabel(k), icon = 'pin', sub = k } end
  ks[#ks + 1] = { id = '__new', label = 'Neue Art eingeben', icon = 'plus', section = 'Sonstiges' }
  TacoV.Menu.open({ id = 'creator_newkind', title = 'Neuer Ort · Art', icon = 'plus', info = 'Orte-Creator', items = ks }, function(k)
    local function go(kind)
      TacoV.Menu.close()
      TacoV.Creator.place({ label = kindLabel(kind) }, function(pos, h)
        if not pos then return end
        local n = 1
        for _, l in ipairs(TacoV.Client.locations) do if l.kind == kind then n = n + 1 end end
        local l = { name = ('%s_%d'):format(kind, n), kind = kind, label = ('%s %d'):format(kindLabel(kind), n), x = pos.x, y = pos.y, z = pos.z, heading = h, extra = {} }
        TacoV.UI.ask({ title = 'Name (eindeutig, klein, ohne Leerzeichen)', label = kindLabel(kind), value = l.name, maxLength = 48, icon = 'pin' }, function(v)
          if not v or #v == 0 then return end
          l.name = v:lower():gsub('[^%w_]', '_')
          askLabel(l)
        end)
      end)
    end
    if k == '__new' then
      TacoV.UI.ask({ title = 'Neue Art (z. B. job_point)', maxLength = 24, icon = 'plus' }, function(v)
        if v and #v > 0 then go(v:lower():gsub('[^%w_]', '_')) end
      end)
    else
      go(k)
    end
  end)
end

function TacoV.Creator.openLocations()
  local pos = GetEntityCoords(PlayerPedId())
  local near = {}
  for _, l in ipairs(TacoV.Client.locations) do
    local d = #(pos - vector3(l.x, l.y, l.z))
    if d < 60.0 then near[#near + 1] = { l = l, d = d } end
  end
  table.sort(near, function(a, b) return a.d < b.d end)
  local items = { { id = 'new', label = 'Neuer Ort', icon = 'plus', sub = 'Art wählen, am Zeiger platzieren', section = 'Orte' } }
  for i, e in ipairs(near) do
    if i > 8 then break end
    items[#items + 1] = { id = 'near:' .. e.l.name, label = e.l.label or e.l.name, icon = 'pin', sub = ('%s · %.0f m'):format(kindLabel(e.l.kind), e.d), section = i == 1 and 'In der Nähe' or nil }
  end
  items[#items + 1] = { id = 'all', label = 'Alle Orte nach Art', icon = 'list', section = 'Übersicht' }
  TacoV.Menu.open({ id = 'creator_locs', title = 'Orte-Creator', icon = 'pin', info = ('%d Orte'):format(#TacoV.Client.locations),
    note = 'Änderungen gelten sofort für alle Spieler und werden protokolliert.', items = items }, function(id)
    if id == 'new' then newLocation()
    elseif id == 'all' then
      local ks = {}
      for _, k in ipairs(kinds()) do
        local n = 0
        for _, l in ipairs(TacoV.Client.locations) do if l.kind == k then n = n + 1 end end
        ks[#ks + 1] = { id = k, label = kindLabel(k), icon = 'pin', badge = tostring(n) }
      end
      TacoV.Menu.open({ id = 'creator_kinds', title = 'Orte nach Art', icon = 'list', items = ks }, function(k)
        local ls = {}
        for _, l in ipairs(TacoV.Client.locations) do
          if l.kind == k then ls[#ls + 1] = { id = l.name, label = l.label or l.name, icon = 'pin', sub = ('%.0f m'):format(#(pos - vector3(l.x, l.y, l.z))) } end
        end
        TacoV.Menu.open({ id = 'creator_kindlist', title = kindLabel(k), icon = 'pin', items = ls }, function(name)
          for _, l in ipairs(TacoV.Client.locations) do if l.name == name then locationMenu(l) end end
        end)
      end)
    else
      local name = id:sub(6)
      for _, l in ipairs(TacoV.Client.locations) do if l.name == name then locationMenu(l) end end
    end
  end)
end

--- Creator-Übersicht aus dem Team-Menü
function TacoV.Creator.openMenu()
  TacoV.Menu.open({ id = 'creator', title = 'Creator', icon = 'tool', info = 'Inhalte ohne Code setzen', items = {
    { id = 'locations', label = 'Orte', icon = 'pin', sub = 'Blips, E-Punkte, Ausfahrten' },
    { id = 'doors', label = 'Türen', icon = 'door', sub = 'Erfassen, Zugang, zu/offen' },
    { id = 'elevators', label = 'Aufzüge', icon = 'home', dim = true, badge = 'bald' },
    { id = 'portals', label = 'Portale', icon = 'next', dim = true, badge = 'bald' },
    { id = 'peds', label = 'NPCs', icon = 'user', dim = true, badge = 'bald' },
    { id = 'props', label = 'Objekte', icon = 'box', dim = true, badge = 'bald' },
    { id = 'zones', label = 'Zonen', icon = 'pin', dim = true, badge = 'bald' },
  } }, function(id)
    if id == 'locations' then TacoV.Creator.openLocations()
    elseif id == 'doors' then TacoV.Doors.openCreator() end
  end)
end
