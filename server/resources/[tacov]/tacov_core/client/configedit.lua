-- Config im Spiel (Client, 5.13): Überschreibungen übernehmen, Menü zum Durchblättern und Ändern (Manager).
TacoV = TacoV or {}

local overrides, defaults = {}, {}

RegisterNetEvent('tacov:config:overrides', function(o, d)
  -- vorherige Überschreibungen auf Standard zurück, dann neue anwenden
  for path in pairs(overrides) do if defaults[path] ~= nil then TacoV.ConfigEdit.set(path, defaults[path]) end end
  overrides, defaults = o or {}, d or {}
  for path, v in pairs(defaults) do TacoV.ConfigEdit.defaults[path] = v end
  TacoV.ConfigEdit.apply(overrides)
end)

local function fmtVal(v)
  if type(v) == 'boolean' then return v and 'an' or 'aus' end
  if type(v) == 'table' then
    local n = 0
    for _ in pairs(v) do n = n + 1 end
    return ('%d Einträge'):format(n)
  end
  return tostring(v)
end

local function browse(path, label)
  local node = TacoV.ConfigEdit.get(path)
  if type(node) ~= 'table' then return end
  local keys = {}
  for k in pairs(node) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  local items = {}
  for _, k in ipairs(keys) do
    local v = node[k]
    local sub = path .. '.' .. tostring(k)
    local t = type(v)
    if t == 'table' or t == 'number' or t == 'boolean' or t == 'string' then
      items[#items + 1] = { id = tostring(k), label = tostring(k), icon = t == 'table' and 'list' or (t == 'boolean' and 'check' or 'settings'),
        sub = fmtVal(v), badge = overrides[sub] ~= nil and 'geändert' or nil, dim = t == 'table' and next(v) == nil }
    end
  end
  if #items == 0 then items[1] = { id = 'none', label = 'Keine Werte', dim = true } end
  TacoV.Menu.open({ id = 'config_' .. path, title = label, icon = 'settings', info = path, note = 'Enter: Wert ändern · Zahlen/Texte per Eingabe, Schalter kippen', items = items }, function(id)
    if id == 'none' then return end
    local k = tonumber(id) or id
    local v = node[k]
    local sub = path .. '.' .. tostring(k)
    if type(v) == 'table' then browse(sub, tostring(k))
    elseif type(v) == 'boolean' then
      TacoV.Menu.open({ id = 'config_bool', title = sub, icon = 'check', items = {
        { id = 'on', label = 'An', icon = 'check', badge = v and 'aktuell' or nil }, { id = 'off', label = 'Aus', icon = 'x', badge = (not v) and 'aktuell' or nil },
        { id = 'reset', label = 'Auf Standard zurücksetzen', icon = 'back', section = 'Sonstiges', dim = overrides[sub] == nil },
      } }, function(a)
        TacoV.Menu.close()
        if a == 'reset' then TriggerServerEvent('tacov:config:set', sub, nil) else TriggerServerEvent('tacov:config:set', sub, a == 'on') end
      end)
    else
      local hint = overrides[sub] ~= nil and ('Standard: ' .. tostring(defaults[sub]) .. ' · leer = zurücksetzen') or 'Standardwert'
      TacoV.UI.ask({ title = sub, label = hint, value = tostring(v), maxLength = 64, numeric = type(v) == 'number', icon = 'settings' }, function(txt)
        if txt == nil then return end
        if txt == '' and overrides[sub] ~= nil then TacoV.Menu.close() TriggerServerEvent('tacov:config:set', sub, nil) return end
        local nv = type(v) == 'number' and tonumber(txt) or txt
        if nv == nil then TacoV.UI.send('notify', { kind = 'error', text = 'Bitte eine Zahl eingeben.' }) return end
        TacoV.Menu.close()
        TriggerServerEvent('tacov:config:set', sub, nv)
      end)
    end
  end)
end

function TacoV.ConfigEdit.openMenu()
  local items = {}
  for _, r in ipairs(TacoV.ConfigEdit.roots) do
    if type(TacoV.Config[r.key]) == 'table' then
      local n = 0
      for path in pairs(overrides) do if path:sub(1, #r.key + 1) == r.key .. '.' then n = n + 1 end end
      items[#items + 1] = { id = r.key, label = r.label, icon = 'settings', sub = r.key, badge = n > 0 and (n .. ' geändert') or nil }
    end
  end
  TacoV.Menu.open({ id = 'config', title = 'Config', icon = 'settings', info = 'Werte gelten sofort und werden protokolliert', items = items }, function(id)
    for _, r in ipairs(TacoV.ConfigEdit.roots) do if r.key == id then browse(id, r.label) end end
  end)
end
