-- Aufzüge (5.5) und Portale (5.6), Client: E-Aufforderungen, Etagenwahl, Blende; Creator-Menüs.
TacoV = TacoV or {}
TacoV.Teleports = { elevators = {}, portals = {} }

RegisterNetEvent('tacov:teleports:list', function(elevators, portals)
  TacoV.Teleports.elevators, TacoV.Teleports.portals = elevators or {}, portals or {}
end)

RegisterNetEvent('tacov:teleports:go', function(x, y, z, h)
  PlaySoundFrontend(-1, 'Hack_Success', 'DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS', true)
  TacoV.Creator.fadeTeleport(x + 0.0, y + 0.0, z + 0.0, h)
end)

local function nearestElevator(maxDist)
  local pos = GetEntityCoords(PlayerPedId())
  local best, bestI, bestD = nil, nil, maxDist or 2.0
  for _, e in ipairs(TacoV.Teleports.elevators) do
    for i, f in ipairs(e.floors) do
      local d = #(pos - vector3(f.x, f.y, f.z))
      if d < bestD then best, bestI, bestD = e, i, d end
    end
  end
  return best, bestI
end

local function nearestPortal(maxDist)
  local pos = GetEntityCoords(PlayerPedId())
  local best, back, bestD = nil, false, maxDist or 2.0
  for _, p in ipairs(TacoV.Teleports.portals) do
    local d1 = #(pos - vector3(p.entry.x, p.entry.y, p.entry.z))
    if d1 < bestD then best, back, bestD = p, false, d1 end
    if not p.oneWay then
      local d2 = #(pos - vector3(p.target.x, p.target.y, p.target.z))
      if d2 < bestD then best, back, bestD = p, true, d2 end
    end
  end
  return best, back
end

local function openFloors(e, here)
  local items = {}
  for i, f in ipairs(e.floors) do
    items[#items + 1] = { id = tostring(i), label = f.label ~= '' and f.label or ('Etage ' .. i), icon = 'home', dim = i == here, badge = i == here and 'hier' or nil }
  end
  TacoV.Menu.open({ id = 'elevator', title = e.label ~= '' and e.label or 'Aufzug', icon = 'home', info = 'Etage wählen', items = items }, function(i)
    if tonumber(i) == here then return end
    TacoV.Menu.close()
    TriggerServerEvent('tacov:elevator:go', e.id, tonumber(i))
  end)
end

TacoV.Prompt.register({ id = 'elevator', label = 'Aufzug', order = 14,
  when = function() local e, i = nearestElevator(2.0) return e and { e = e, i = i } or false end,
  run = function(ctx) openFloors(ctx.e, ctx.i) end })
TacoV.Prompt.register({ id = 'portal', label = 'Betreten', order = 14,
  when = function() local p, back = nearestPortal(2.0) return p and { p = p, back = back } or false end,
  run = function(ctx) TriggerServerEvent('tacov:portal:use', ctx.p.id, ctx.back) end })

-- Marker an Aufzug- und Portalpunkten in der Nähe (dezent)
CreateThread(function()
  while true do
    local pos = GetEntityCoords(PlayerPedId())
    local any = false
    if TacoV.Client.character then
      for _, e in ipairs(TacoV.Teleports.elevators) do
        for _, f in ipairs(e.floors) do
          if #(pos - vector3(f.x, f.y, f.z)) < 15.0 then
            any = true
            DrawMarker(27, f.x, f.y, f.z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.9, 0.9, 0.5, 167, 139, 250, 110, false, false, 2, false, nil, nil, false)
          end
        end
      end
      for _, p in ipairs(TacoV.Teleports.portals) do
        for _, pt in ipairs({ p.entry, (not p.oneWay) and p.target or nil }) do
          if #(pos - vector3(pt.x, pt.y, pt.z)) < 15.0 then
            any = true
            DrawMarker(27, pt.x, pt.y, pt.z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.9, 0.9, 0.5, 167, 139, 250, 110, false, false, 2, false, nil, nil, false)
          end
        end
      end
    end
    Wait(any and 0 or 500)
  end
end)

-- ---------------------------------------------------------------- Creator

local function saveElevator(e) TriggerServerEvent('tacov:elevator:save', e) end
local function savePortal(p) TriggerServerEvent('tacov:portal:save', p) end

local function addFloor(e, after)
  TacoV.Menu.close()
  TacoV.Creator.place({ label = 'Etage' }, function(pos, h)
    if not pos then if after then after(false) end return end
    TacoV.UI.ask({ title = 'Name der Etage', placeholder = 'z. B. Erdgeschoss', value = 'Etage ' .. (#e.floors + 1), maxLength = 32, icon = 'home' }, function(v)
      e.floors[#e.floors + 1] = { label = (v and #v > 0) and v or ('Etage ' .. (#e.floors + 1)), x = pos.x, y = pos.y, z = pos.z, h = h }
      if after then after(true) end
    end)
  end)
end

local function elevatorMenu(e)
  local items = {
    { id = 'info', label = ('%d Etagen'):format(#e.floors), icon = 'home', dim = true, sub = TacoV.Creator.accessText(e.access) },
    { id = 'label', label = 'Bezeichnung ändern', icon = 'doc', sub = e.label, section = 'Einstellungen' },
    { id = 'access', label = 'Zugang', icon = 'lock', sub = TacoV.Creator.accessText(e.access) },
    { id = 'add', label = 'Etage hinzufügen', icon = 'plus', section = 'Etagen' },
  }
  for i, f in ipairs(e.floors) do
    items[#items + 1] = { id = 'floor:' .. i, label = f.label, icon = 'pin', sub = ('%.1f, %.1f, %.1f'):format(f.x, f.y, f.z) }
  end
  items[#items + 1] = { id = 'delete', label = 'Aufzug löschen', icon = 'x', section = 'Gefahr' }
  TacoV.Menu.open({ id = 'elevator_edit', title = e.label ~= '' and e.label or ('Aufzug #' .. e.id), icon = 'home', info = 'Elevator Creator', items = items }, function(id)
    if id == 'label' then
      TacoV.UI.ask({ title = 'Bezeichnung', value = e.label, maxLength = 64, icon = 'home' }, function(v) if v and #v > 0 then e.label = v saveElevator(e) end end)
    elseif id == 'access' then TacoV.Creator.accessMenu(e, function() saveElevator(e) end)
    elseif id == 'add' then addFloor(e, function(ok) if ok then saveElevator(e) end end)
    elseif id == 'delete' then
      TacoV.Menu.open({ id = 'elevator_del', title = 'Aufzug wirklich löschen?', icon = 'warn', items = {
        { id = 'yes', label = 'Ja, löschen', icon = 'x' }, { id = 'no', label = 'Abbrechen', icon = 'back' } } }, function(a)
        if a == 'yes' then TriggerServerEvent('tacov:elevator:delete', e.id) TacoV.Menu.close() else TacoV.Menu.back() end
      end)
    elseif id:sub(1, 6) == 'floor:' then
      local i = tonumber(id:sub(7))
      local f = e.floors[i]
      TacoV.Menu.open({ id = 'floor_edit', title = f.label, icon = 'pin', items = {
        { id = 'tp', label = 'Dorthin teleportieren', icon = 'next' },
        { id = 'move', label = 'Neu platzieren', icon = 'pin' },
        { id = 'rename', label = 'Umbenennen', icon = 'doc' },
        { id = 'remove', label = 'Etage entfernen', icon = 'x', section = 'Gefahr' },
      } }, function(a)
        if a == 'tp' then TacoV.Menu.close() TacoV.Creator.fadeTeleport(f.x, f.y, f.z, f.h)
        elseif a == 'move' then
          TacoV.Menu.close()
          TacoV.Creator.place({ start = vector3(f.x, f.y, f.z), heading = f.h, label = f.label }, function(pos, h)
            if pos then f.x, f.y, f.z, f.h = pos.x, pos.y, pos.z, h saveElevator(e) end
          end)
        elseif a == 'rename' then
          TacoV.UI.ask({ title = 'Name der Etage', value = f.label, maxLength = 32, icon = 'home' }, function(v) if v and #v > 0 then f.label = v saveElevator(e) end end)
        elseif a == 'remove' then
          table.remove(e.floors, i) saveElevator(e) TacoV.Menu.close()
        end
      end)
    end
  end)
end

local function newElevator()
  TacoV.Menu.close()
  TacoV.UI.ask({ title = 'Bezeichnung des Aufzugs', placeholder = 'z. B. LSPD Aufzug', maxLength = 64, icon = 'home' }, function(v)
    if not v or #v == 0 then return end
    local e = { label = v, floors = {}, access = {} }
    local function more()
      addFloor(e, function(ok)
        if not ok then if #e.floors > 0 then saveElevator(e) end return end
        TacoV.Menu.open({ id = 'elevator_more', title = 'Weitere Etage?', icon = 'home', info = ('%d Etage(n) gesetzt'):format(#e.floors), items = {
          { id = 'yes', label = 'Ja, nächste Etage platzieren', icon = 'plus' }, { id = 'no', label = 'Nein, speichern', icon = 'check' } } }, function(a)
          TacoV.Menu.close()
          if a == 'yes' then more() else saveElevator(e) end
        end)
      end)
    end
    more()
  end)
end

local function portalMenu(p)
  TacoV.Menu.open({ id = 'portal_edit', title = p.label ~= '' and p.label or ('Portal #' .. p.id), icon = 'next', info = 'Portal Creator', items = {
    { id = 'info', label = p.oneWay and 'Einbahn (nur Eingang → Ausgang)' or 'Beide Richtungen', icon = 'info', dim = true, sub = TacoV.Creator.accessText(p.access) },
    { id = 'label', label = 'Bezeichnung ändern', icon = 'doc', sub = p.label, section = 'Einstellungen' },
    { id = 'access', label = 'Zugang', icon = 'lock', sub = TacoV.Creator.accessText(p.access) },
    { id = 'oneway', label = p.oneWay and 'Beide Richtungen erlauben' or 'Nur Einbahn', icon = 'next' },
    { id = 'entry', label = 'Eingang neu setzen', icon = 'pin', section = 'Punkte' },
    { id = 'target', label = 'Ausgang neu setzen', icon = 'pin' },
    { id = 'tp1', label = 'Zum Eingang', icon = 'next' },
    { id = 'tp2', label = 'Zum Ausgang', icon = 'next' },
    { id = 'delete', label = 'Portal löschen', icon = 'x', section = 'Gefahr' },
  } }, function(id)
    if id == 'label' then
      TacoV.UI.ask({ title = 'Bezeichnung', value = p.label, maxLength = 64, icon = 'next' }, function(v) if v and #v > 0 then p.label = v savePortal(p) end end)
    elseif id == 'access' then TacoV.Creator.accessMenu(p, function() savePortal(p) end)
    elseif id == 'oneway' then p.oneWay = not p.oneWay savePortal(p) TacoV.Menu.back()
    elseif id == 'entry' or id == 'target' then
      TacoV.Menu.close()
      local cur = p[id]
      TacoV.Creator.place({ start = vector3(cur.x, cur.y, cur.z), heading = cur.h, label = id == 'entry' and 'Eingang' or 'Ausgang' }, function(pos, h)
        if pos then p[id] = { x = pos.x, y = pos.y, z = pos.z, h = h } savePortal(p) end
      end)
    elseif id == 'tp1' then TacoV.Menu.close() TacoV.Creator.fadeTeleport(p.entry.x, p.entry.y, p.entry.z, p.entry.h)
    elseif id == 'tp2' then TacoV.Menu.close() TacoV.Creator.fadeTeleport(p.target.x, p.target.y, p.target.z, p.target.h)
    elseif id == 'delete' then
      TacoV.Menu.open({ id = 'portal_del', title = 'Portal wirklich löschen?', icon = 'warn', items = {
        { id = 'yes', label = 'Ja, löschen', icon = 'x' }, { id = 'no', label = 'Abbrechen', icon = 'back' } } }, function(a)
        if a == 'yes' then TriggerServerEvent('tacov:portal:delete', p.id) TacoV.Menu.close() else TacoV.Menu.back() end
      end)
    end
  end)
end

local function newPortal()
  TacoV.Menu.close()
  TacoV.UI.ask({ title = 'Bezeichnung des Portals', placeholder = 'z. B. Polizeiwache Eingang', maxLength = 64, icon = 'next' }, function(v)
    if not v or #v == 0 then return end
    local p = { label = v, access = {}, oneWay = false }
    TacoV.Creator.place({ label = 'Eingang' }, function(pos, h)
      if not pos then return end
      p.entry = { x = pos.x, y = pos.y, z = pos.z, h = h }
      TacoV.UI.send('notify', { kind = 'info', text = 'Eingang gesetzt. Jetzt zum Ausgang gehen (oder Noclip) und platzieren.' })
      TacoV.Creator.place({ label = 'Ausgang' }, function(pos2, h2)
        if not pos2 then return end
        p.target = { x = pos2.x, y = pos2.y, z = pos2.z, h = h2 }
        savePortal(p)
      end)
    end)
  end)
end

local function nearList(kind)
  local pos = GetEntityCoords(PlayerPedId())
  local out = {}
  if kind == 'elevator' then
    for _, e in ipairs(TacoV.Teleports.elevators) do
      local best = 1e9
      for _, f in ipairs(e.floors) do best = math.min(best, #(pos - vector3(f.x, f.y, f.z))) end
      out[#out + 1] = { o = e, d = best }
    end
  else
    for _, p in ipairs(TacoV.Teleports.portals) do
      out[#out + 1] = { o = p, d = math.min(#(pos - vector3(p.entry.x, p.entry.y, p.entry.z)), #(pos - vector3(p.target.x, p.target.y, p.target.z))) }
    end
  end
  table.sort(out, function(a, b) return a.d < b.d end)
  return out
end

function TacoV.Teleports.openElevatorCreator()
  local items = { { id = 'new', label = 'Neuer Aufzug', icon = 'plus', sub = 'Bezeichnung, dann Etagen platzieren', section = 'Aufzüge' } }
  for i, e in ipairs(nearList('elevator')) do
    if i > 12 then break end
    items[#items + 1] = { id = tostring(e.o.id), label = e.o.label ~= '' and e.o.label or ('Aufzug #' .. e.o.id), icon = 'home',
      sub = ('%d Etagen · %.0f m'):format(#e.o.floors, e.d), section = i == 1 and 'Vorhanden (nach Entfernung)' or nil }
  end
  TacoV.Menu.open({ id = 'elevators', title = 'Elevator Creator', icon = 'home', info = ('%d Aufzüge'):format(#TacoV.Teleports.elevators), items = items }, function(id)
    if id == 'new' then newElevator() else
      for _, e in ipairs(TacoV.Teleports.elevators) do if e.id == tonumber(id) then elevatorMenu(e) end end
    end
  end)
end

function TacoV.Teleports.openPortalCreator()
  local items = { { id = 'new', label = 'Neues Portal', icon = 'plus', sub = 'Eingang und Ausgang platzieren', section = 'Portale' } }
  for i, e in ipairs(nearList('portal')) do
    if i > 12 then break end
    items[#items + 1] = { id = tostring(e.o.id), label = e.o.label ~= '' and e.o.label or ('Portal #' .. e.o.id), icon = 'next',
      sub = ('%s · %.0f m'):format(e.o.oneWay and 'Einbahn' or 'beide Richtungen', e.d), section = i == 1 and 'Vorhanden (nach Entfernung)' or nil }
  end
  TacoV.Menu.open({ id = 'portals', title = 'Portal Creator', icon = 'next', info = ('%d Portale'):format(#TacoV.Teleports.portals), items = items }, function(id)
    if id == 'new' then newPortal() else
      for _, p in ipairs(TacoV.Teleports.portals) do if p.id == tonumber(id) then portalMenu(p) end end
    end
  end)
end
