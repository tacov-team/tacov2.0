-- NPC-Werkstatt (Client): E-Aufforderung im eigenen Fahrzeug, Menüs Reparatur / Upgrades → Teil → Stufe / Zubehör, Umbau am Fahrzeug.
TacoV = TacoV or {}
TacoV.Workshop = {}

local function fmt(n)
  local s = tostring(math.floor(n + 0.5))
  local out = s:reverse():gsub('(%d%d%d)', '%1.'):reverse()
  if out:sub(1, 1) == '.' then out = out:sub(2) end
  return out .. ' $'
end

local function myVehicle()
  local ped = PlayerPedId()
  local veh = GetVehiclePedIsIn(ped, false)
  if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then return 0 end
  return veh
end

local function health(veh)
  return { body = GetVehicleBodyHealth(veh), engine = GetVehicleEngineHealth(veh) }
end

TacoV.Prompt.register({
  id = 'workshop', label = 'Werkstatt', order = 8,
  when = function() return myVehicle() ~= 0 and TacoV.Client.nearestLocation('workshop', 12.0) ~= nil end,
  run = function()
    local veh = myVehicle()
    if veh ~= 0 then TriggerServerEvent('tacov:workshop:open', NetworkGetNetworkIdFromEntity(veh), health(veh)) end
  end,
})

local function payMenu(title, price, onPick)
  TacoV.Menu.open({
    id = 'ws_pay', title = title, icon = 'cash', info = fmt(price),
    items = { { id = 'card', label = 'Mit Karte zahlen', icon = 'card' }, { id = 'cash', label = 'Bar zahlen', icon = 'cash' } },
  }, function(method) onPick(method) end)
end

RegisterNetEvent('tacov:workshop:data', function(d)
  local veh = myVehicle()
  if veh == 0 then return end
  local netId = NetworkGetNetworkIdFromEntity(veh)
  local function apply(payload, price, label)
    payMenu(label, price, function(method)
      TacoV.Menu.close()
      payload.netId, payload.method = netId, method
      local h = health(veh)
      payload.body, payload.engine = h.body, h.engine
      TriggerServerEvent('tacov:workshop:apply', payload)
    end)
  end
  if TacoV.Menu.isOpen() then TacoV.Menu.close() end
  TacoV.Menu.open({
    id = 'ws', title = 'Werkstatt', icon = 'wrench', info = ('%s · %s · Bargeld %s · Konto %s'):format(d.label, d.plate, fmt(d.cash), fmt(d.bank)),
    items = {
      { id = 'repair', label = 'Reparatur', icon = 'tool', price = d.repair > 0 and fmt(d.repair) or nil, sub = d.repair > 0 and ('Schaden %d %%'):format(d.damagePercent) or 'kein Schaden', dim = d.repair <= 0 },
      { id = 'upgrades', label = 'Upgrades', icon = 'engine', sub = 'Motor, Bremsen, Getriebe, Fahrwerk, Turbo', section = 'Tuning' },
      { id = 'paint', label = 'Lackierung', icon = 'star', price = fmt(d.paint), section = 'Zubehör' },
      { id = 'tint', label = 'Fensterfarbe', icon = 'door', price = fmt(d.tint) },
      { id = 'wheels', label = 'Felgen', icon = 'speed', price = fmt(d.wheels) },
    },
  }, function(id)
    if id == 'repair' then
      apply({ kind = 'repair' }, d.repair, 'Reparatur')
    elseif id == 'upgrades' then
      local items = {}
      for _, up in ipairs(d.upgrades) do
        local modTypes = { engine = 11, brakes = 12, transmission = 13, suspension = 15 }
        local cur = up.toggle and (IsToggleModOn(veh, 18) and 1 or 0) or (GetVehicleMod(veh, modTypes[up.id]) + 1)
        items[#items + 1] = { id = up.id, label = up.label, icon = up.icon, sub = cur > 0 and ('eingebaut: ' .. up.levels[cur]) or 'Serie' }
      end
      TacoV.Menu.open({ id = 'ws_up', title = 'Upgrades', icon = 'engine', info = 'Teil wählen', items = items }, function(uid)
        local up
        for _, u in ipairs(d.upgrades) do if u.id == uid then up = u end end
        if not up then return end
        local li = {}
        for i, name in ipairs(up.levels) do li[i] = { id = tostring(i), label = name, icon = 'next', price = fmt(up.prices[i]) } end
        TacoV.Menu.open({ id = 'ws_lvl', title = up.label, icon = up.icon, info = 'Stufe wählen', items = li }, function(level)
          apply({ kind = 'upgrade', id = up.id, level = tonumber(level) }, up.prices[tonumber(level)], up.label .. ' ' .. up.levels[tonumber(level)])
        end)
      end)
    elseif id == 'paint' then
      local items = {}
      for _, col in ipairs(d.colors) do items[#items + 1] = { id = tostring(col.id), label = col.label, icon = 'star' } end
      TacoV.Menu.open({ id = 'ws_paint', title = 'Lackierung', icon = 'star', info = fmt(d.paint) .. ' je Farbe · Vorschau beim Markieren', items = items }, function(cid)
        apply({ kind = 'paint', value = tonumber(cid), slot = 1 }, d.paint, 'Lackierung')
      end)
    elseif id == 'tint' then
      local items = {}
      for _, t in ipairs(d.tints) do items[#items + 1] = { id = tostring(t.id), label = t.label, icon = 'door' } end
      TacoV.Menu.open({ id = 'ws_tint', title = 'Fensterfarbe', icon = 'door', info = fmt(d.tint), items = items }, function(tid)
        apply({ kind = 'tint', value = tonumber(tid) }, d.tint, 'Fensterfarbe')
      end)
    elseif id == 'wheels' then
      local types = {}
      for _, t in ipairs(d.wheelTypes) do types[#types + 1] = { id = tostring(t.id), label = t.label, icon = 'speed' } end
      TacoV.Menu.open({ id = 'ws_wt', title = 'Felgen', icon = 'speed', info = 'Felgenart wählen', items = types }, function(wt)
        local li = {}
        for i = 0, d.wheelsPerType - 1 do li[#li + 1] = { id = tostring(i), label = ('Felge %d'):format(i + 1), icon = 'speed', price = fmt(d.wheels) } end
        TacoV.Menu.open({ id = 'ws_w', title = 'Felgen', icon = 'speed', info = 'Modell wählen', items = li }, function(wi)
          apply({ kind = 'wheels', wheelType = tonumber(wt), value = tonumber(wi) }, d.wheels, 'Felgen')
        end)
      end)
    end
  end)
end)

-- Umbau am Fahrzeug nach Freigabe des Servers
RegisterNetEvent('tacov:workshop:do', function(netId, a)
  local veh = NetworkGetEntityFromNetworkId(netId)
  if veh == 0 or not DoesEntityExist(veh) or type(a) ~= 'table' then return end
  SetVehicleModKit(veh, 0)
  if a.kind == 'repair' then
    SetVehicleFixed(veh)
    SetVehicleEngineHealth(veh, 1000.0)
    SetVehicleBodyHealth(veh, 1000.0)
    SetVehicleDirtLevel(veh, 0.0)
  elseif a.kind == 'upgrade' then
    if a.toggle then ToggleVehicleMod(veh, a.toggle, true) else SetVehicleMod(veh, a.modType, a.index, false) end
  elseif a.kind == 'paint' then
    local c1, c2 = GetVehicleColours(veh)
    if a.slot == 2 then SetVehicleColours(veh, c1, a.value) else SetVehicleColours(veh, a.value, c2) end
  elseif a.kind == 'tint' then
    SetVehicleWindowTint(veh, a.value)
  elseif a.kind == 'wheels' then
    SetVehicleWheelType(veh, a.wheelType)
    SetVehicleMod(veh, 23, a.value, false)
  end
  TriggerServerEvent('tacov:workshop:props', netId, TacoV.Vehicles.propsOf(veh))
  -- Menü mit frischen Daten neu öffnen
  TriggerServerEvent('tacov:workshop:open', netId, { body = GetVehicleBodyHealth(veh), engine = GetVehicleEngineHealth(veh) })
end)
