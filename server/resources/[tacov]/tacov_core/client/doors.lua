-- Türen (Client, 5.4): registriert Tür-Teile im Door-System, hält den Zustand synchron, E am Türrahmen schließt auf/ab,
-- Creator-Menü (Tür anschauen und erfassen, Zugang, Teile, löschen).
TacoV = TacoV or {}
TacoV.Doors = { list = {} }

local registered = {} -- [doorId..':'..i] = hashKey

local function doorHash(d, i) return GetHashKey(('tacov_door_%d_%d'):format(d.id, i)) end

local function apply(d)
  for i, pt in ipairs(d.parts) do
    local key = d.id .. ':' .. i
    local h = doorHash(d, i)
    if not registered[key] then
      AddDoorToSystem(h, pt.model, pt.x, pt.y, pt.z, false, false, false)
      registered[key] = h
    end
    DoorSystemSetDoorState(h, d.locked and 1 or 0, false, false)
    if d.locked then DoorSystemSetOpenRatio(h, 0.0, false, false) end
  end
end

local function remove(d)
  for i in ipairs(d.parts) do
    local key = d.id .. ':' .. i
    if registered[key] then
      DoorSystemSetDoorState(registered[key], 0, false, false)
      RemoveDoorFromSystem(registered[key])
      registered[key] = nil
    end
  end
end

RegisterNetEvent('tacov:doors:list', function(list)
  for _, d in pairs(TacoV.Doors.list) do remove(d) end
  TacoV.Doors.list = {}
  for _, d in ipairs(list or {}) do TacoV.Doors.list[d.id] = d apply(d) end
end)

RegisterNetEvent('tacov:doors:state', function(id, locked)
  local d = TacoV.Doors.list[id]
  if not d then return end
  d.locked = locked
  apply(d)
  local pos = GetEntityCoords(PlayerPedId())
  for _, pt in ipairs(d.parts) do
    if #(pos - vector3(pt.x, pt.y, pt.z)) < 12.0 then
      PlaySoundFromCoord(-1, locked and 'Door_Close' or 'Door_Open', pt.x, pt.y, pt.z, 'DLC_HEIST_HACKING_SNAKE_SOUNDS', false, 0, false)
      break
    end
  end
end)

AddEventHandler('onResourceStop', function(res)
  if res == GetCurrentResourceName() then for _, d in pairs(TacoV.Doors.list) do remove(d) end end
end)

--- Nächste Tür in Reichweite
function TacoV.Doors.nearest(maxDist)
  local pos = GetEntityCoords(PlayerPedId())
  local best, bestD = nil, maxDist or 2.0
  for _, d in pairs(TacoV.Doors.list) do
    for _, pt in ipairs(d.parts) do
      local dist = #(pos - vector3(pt.x, pt.y, pt.z))
      if dist < bestD then best, bestD = d, dist end
    end
  end
  return best, bestD
end

TacoV.Prompt.register({ id = 'door_unlock', label = 'Tür aufschließen', order = 15,
  when = function() local d = TacoV.Doors.nearest(2.0) return d and d.locked and d or false end,
  run = function(d) TriggerServerEvent('tacov:doors:toggle', d.id) end })
TacoV.Prompt.register({ id = 'door_lock', label = 'Tür abschließen', order = 16,
  when = function() local d = TacoV.Doors.nearest(2.0) return d and not d.locked and d or false end,
  run = function(d) TriggerServerEvent('tacov:doors:toggle', d.id) end })

-- ---------------------------------------------------------------- Creator

--- Entität anvisieren: Kamera-Strahl auf Objekte; cb(entity) oder cb(nil)
local function pickEntity(label, cb)
  CreateThread(function()
    TacoV.UI.send('hint', { key = 'Enter', text = label .. ' anschauen und Enter drücken · Backspace abbrechen' })
    while true do
      Wait(0)
      DisableControlAction(0, 191, true) DisableControlAction(0, 201, true) DisableControlAction(0, 177, true) DisableControlAction(0, 202, true)
      local rot = GetGameplayCamRot(2)
      local yaw, pitch = math.rad(rot.z), math.rad(rot.x)
      local dir = vector3(-math.sin(yaw) * math.cos(pitch), math.cos(yaw) * math.cos(pitch), math.sin(pitch))
      local from = GetGameplayCamCoord()
      local to = from + dir * 15.0
      local handle = StartShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, 16, PlayerPedId(), 4)
      local _, hit, coords, _, ent = GetShapeTestResult(handle)
      if hit == 1 and ent ~= 0 and DoesEntityExist(ent) then
        local p = GetEntityCoords(ent)
        DrawMarker(28, p.x, p.y, p.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 167, 139, 250, 160, false, true, 2, nil, nil, false)
        DrawLine(coords.x, coords.y, coords.z, p.x, p.y, p.z, 255, 255, 255, 180)
        if IsDisabledControlJustPressed(0, 191) or IsDisabledControlJustPressed(0, 201) then
          TacoV.UI.send('hint', nil) cb(ent) return
        end
      end
      if IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 202) then TacoV.UI.send('hint', nil) cb(nil) return end
    end
  end)
end

local function partOf(ent)
  local p = GetEntityCoords(ent)
  return { model = GetEntityModel(ent), x = p.x, y = p.y, z = p.z }
end

local function save(d) TriggerServerEvent('tacov:doors:save', d) end

local function accessText(a)
  a = a or {}
  if a.faction then return ('Fraktion %s ab Rang %d'):format(a.faction, a.minRank or 0) end
  if a.item then return 'Schlüssel: ' .. ((TacoV.Config.Items[a.item] or {}).label or a.item) end
  return 'Frei (jeder darf)'
end

local function doorMenu(d)
  d.access = d.access or {}
  local items = {
    { id = 'info', label = ('%d Teil(e) · %s'):format(#d.parts, d.locked and 'abgeschlossen' or 'offen'), icon = 'door', dim = true, sub = accessText(d.access) },
    { id = 'toggle', label = d.locked and 'Aufschließen' or 'Abschließen', icon = 'key', section = 'Zustand' },
    { id = 'label', label = 'Bezeichnung ändern', icon = 'doc', sub = d.label, section = 'Einstellungen' },
    { id = 'faction', label = 'Zugang: Fraktion', icon = 'shield', sub = d.access.faction and (d.access.faction .. ' ab Rang ' .. tostring(d.access.minRank or 0)) or 'nicht gesetzt' },
    { id = 'item', label = 'Zugang: Schlüssel-Item', icon = 'key', sub = d.access.item or 'nicht gesetzt' },
    { id = 'free', label = 'Zugang: frei', icon = 'lock', sub = 'Fraktion und Schlüssel entfernen' },
    { id = 'auto', label = 'Automatisch schließen', icon = 'clock', sub = (d.autoClose or 0) > 0 and (d.autoClose .. ' s') or 'nie' },
    { id = 'addpart', label = 'Teil hinzufügen', icon = 'plus', sub = 'z. B. zweiter Flügel', section = 'Teile' },
    { id = 'clearparts', label = 'Teile neu erfassen', icon = 'search' },
    { id = 'delete', label = 'Tür löschen', icon = 'x', section = 'Gefahr' },
  }
  TacoV.Menu.open({ id = 'door', title = d.label ~= '' and d.label or ('Tür #' .. tostring(d.id)), icon = 'door', info = 'Door Creator', items = items }, function(id)
    if id == 'toggle' then TriggerServerEvent('tacov:doors:toggle', d.id) TacoV.Menu.back()
    elseif id == 'label' then
      TacoV.UI.ask({ title = 'Bezeichnung', value = d.label, maxLength = 64, icon = 'door' }, function(v) if v and #v > 0 then d.label = v save(d) end end)
    elseif id == 'faction' then
      TacoV.UI.ask({ title = 'Fraktion (Kürzel, z. B. lspd)', value = d.access.faction or '', maxLength = 32, icon = 'shield' }, function(f)
        if not f or #f == 0 then return end
        TacoV.UI.ask({ title = 'Mindestrang (0 = alle Mitglieder)', value = tostring(d.access.minRank or 0), maxLength = 2, numeric = true, icon = 'shield' }, function(r)
          d.access.faction = f:lower()
          d.access.minRank = tonumber(r or '') or 0
          d.access.item = nil
          save(d)
        end)
      end)
    elseif id == 'item' then
      local list = {}
      for name, def in pairs(TacoV.Config.Items) do
        if not def.money then list[#list + 1] = { id = name, label = def.label, icon = 'key', sub = name } end
      end
      table.sort(list, function(x, y) return x.label < y.label end)
      TacoV.Menu.open({ id = 'door_item', title = 'Schlüssel-Item', icon = 'key', items = list }, function(item)
        d.access.item = item d.access.faction = nil d.access.minRank = nil
        save(d) TacoV.Menu.back()
      end)
    elseif id == 'free' then d.access = {} save(d) TacoV.Menu.back()
    elseif id == 'auto' then
      TacoV.UI.ask({ title = 'Sekunden bis zum Abschließen (0 = nie)', value = tostring(d.autoClose or 0), maxLength = 4, numeric = true, icon = 'clock' }, function(v)
        d.autoClose = math.max(0, math.floor(tonumber(v or '') or 0)) save(d)
      end)
    elseif id == 'addpart' then
      TacoV.Menu.close()
      pickEntity('Weiteren Türflügel', function(ent) if ent then d.parts[#d.parts + 1] = partOf(ent) save(d) end end)
    elseif id == 'clearparts' then
      TacoV.Menu.close()
      pickEntity('Tür', function(ent) if ent then d.parts = { partOf(ent) } save(d) end end)
    elseif id == 'delete' then
      TacoV.Menu.open({ id = 'door_del', title = 'Tür wirklich löschen?', icon = 'warn', items = {
        { id = 'yes', label = 'Ja, löschen', icon = 'x' }, { id = 'no', label = 'Abbrechen', icon = 'back' } } }, function(a)
        if a == 'yes' then TriggerServerEvent('tacov:doors:delete', d.id) TacoV.Menu.close() else TacoV.Menu.back() end
      end)
    end
  end)
end

local function newDoor()
  TacoV.Menu.close()
  pickEntity('Tür', function(ent)
    if not ent then return end
    local d = { parts = { partOf(ent) }, access = {}, locked = true, autoClose = 0, label = '' }
    TacoV.Menu.open({ id = 'door_more', title = 'Zweiter Flügel?', icon = 'door', info = 'Doppeltür oder Tor mit zwei Teilen', items = {
      { id = 'yes', label = 'Ja, zweiten Teil anvisieren', icon = 'plus' }, { id = 'no', label = 'Nein, nur dieser Teil', icon = 'check' } } }, function(a)
      TacoV.Menu.close()
      local function finish()
        TacoV.UI.ask({ title = 'Bezeichnung der Tür', placeholder = 'z. B. LSPD Haupteingang', maxLength = 64, icon = 'door' }, function(v)
          d.label = (v and #v > 0) and v or 'Tür'
          save(d)
        end)
      end
      if a == 'yes' then
        pickEntity('Zweiten Türflügel', function(ent2) if ent2 then d.parts[#d.parts + 1] = partOf(ent2) end finish() end)
      else finish() end
    end)
  end)
end

function TacoV.Doors.openCreator()
  local pos = GetEntityCoords(PlayerPedId())
  local near = {}
  for _, d in pairs(TacoV.Doors.list) do
    local best = 1e9
    for _, pt in ipairs(d.parts) do best = math.min(best, #(pos - vector3(pt.x, pt.y, pt.z))) end
    if best < 60.0 then near[#near + 1] = { d = d, dist = best } end
  end
  table.sort(near, function(a, b) return a.dist < b.dist end)
  local items = { { id = 'new', label = 'Neue Tür erfassen', icon = 'plus', sub = 'Tür anschauen, Enter', section = 'Türen' } }
  for i, e in ipairs(near) do
    if i > 10 then break end
    items[#items + 1] = { id = tostring(e.d.id), label = e.d.label ~= '' and e.d.label or ('Tür #' .. e.d.id), icon = 'door',
      sub = ('%s · %.0f m'):format(accessText(e.d.access), e.dist), badge = e.d.locked and 'zu' or 'offen', section = i == 1 and 'In der Nähe' or nil }
  end
  local n = 0
  for _ in pairs(TacoV.Doors.list) do n = n + 1 end
  TacoV.Menu.open({ id = 'doors', title = 'Door Creator', icon = 'door', info = ('%d Türen'):format(n),
    note = 'Zustand und Zugang gelten sofort für alle.', items = items }, function(id)
    if id == 'new' then newDoor() else local d = TacoV.Doors.list[tonumber(id)] if d then doorMenu(d) end end
  end)
end
