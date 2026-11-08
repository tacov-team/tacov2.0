-- NPC-Werkstatt (Client, Punkt 4.11): E-Aufforderung im eigenen Fahrzeug, Menüs mit Live-Vorschau: markierte Teile, Farben,
-- Felgen usw. werden sofort am Fahrzeug gezeigt und beim Verlassen ohne Kauf zurückgesetzt. Der Server prüft und bucht.
TacoV = TacoV or {}
TacoV.Workshop = {}

local Cfg = TacoV.Config.Workshop

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

-- ---------------------------------------------------------------- Vorschau

local original = nil   -- Ausstattung beim Öffnen; wird beim Schließen ohne Kauf zurückgesetzt
local bought = false

local function restore(veh)
  if original and DoesEntityExist(veh) then
    TacoV.Vehicles.applyProps(veh, original)
    FreezeEntityPosition(veh, false)
  end
end

local function modLabel(veh, modType, index)
  if index < 0 then return 'Serie' end
  local lbl = GetModTextLabel(veh, modType, index)
  if lbl and lbl ~= '' then
    local txt = GetLabelText(lbl)
    if txt and txt ~= 'NULL' and txt ~= '' then return txt end
  end
  return ('Variante %d'):format(index + 1)
end

--- Vorschau anwenden (ohne Kauf)
local function preview(veh, a)
  SetVehicleModKit(veh, 0)
  if a.kind == 'part' then SetVehicleMod(veh, a.modType, a.index, false)
  elseif a.kind == 'paint' then
    local c1, c2 = GetVehicleColours(veh)
    if a.slot == 2 then SetVehicleColours(veh, c1, a.value) else SetVehicleColours(veh, a.value, c2) end
  elseif a.kind == 'pearl' then
    local _, w = GetVehicleExtraColours(veh)
    SetVehicleExtraColours(veh, a.value, w)
  elseif a.kind == 'wheelcolor' then
    local p = GetVehicleExtraColours(veh)
    SetVehicleExtraColours(veh, p, a.value)
  elseif a.kind == 'tint' then SetVehicleWindowTint(veh, a.value)
  elseif a.kind == 'wheels' then
    SetVehicleWheelType(veh, a.wheelType)
    SetVehicleMod(veh, 23, a.value, false)
    if GetVehicleClass(veh) == 8 then SetVehicleMod(veh, 24, a.value, false) end
  elseif a.kind == 'plate' then SetVehicleNumberPlateTextIndex(veh, a.value)
  elseif a.kind == 'xenon' then ToggleVehicleMod(veh, 22, a.value == true)
  elseif a.kind == 'upgrade' then
    if a.toggle then ToggleVehicleMod(veh, a.toggle, true) else SetVehicleMod(veh, a.modType, a.index, false) end
  end
end

-- ---------------------------------------------------------------- Menüs

local function payMenu(title, price, onPick)
  TacoV.Menu.open({
    id = 'ws_pay', title = title, icon = 'cash', info = fmt(price),
    items = { { id = 'card', label = 'Mit Karte zahlen', icon = 'card' }, { id = 'cash', label = 'Bar zahlen', icon = 'cash' } },
  }, function(method) onPick(method) end)
end

--- Auswahlmenü mit Vorschau: items[i].pv = Vorschau-Aktion, items[i].buy = Kauf-Nutzlast, .price
local function choiceMenu(veh, def, onBuy)
  local snapshot = TacoV.Vehicles.propsOf(veh)
  def.onFocus = function(_, item) if item.pv then TacoV.Vehicles.applyProps(veh, snapshot) preview(veh, item.pv) end end
  def.onClose = function() if not bought then TacoV.Vehicles.applyProps(veh, snapshot) end end
  TacoV.Menu.open(def, function(_, _, item)
    if item.buy then onBuy(item.buy, item.priceValue or 0, item.label) end
  end)
end

RegisterNetEvent('tacov:workshop:data', function(d)
  local veh = myVehicle()
  if veh == 0 then return end
  local netId = NetworkGetNetworkIdFromEntity(veh)
  original = TacoV.Vehicles.propsOf(veh)
  bought = false
  FreezeEntityPosition(veh, true)

  local function apply(payload, price, label)
    payMenu(label, price, function(method)
      bought = true
      TacoV.Menu.close()
      payload.netId, payload.method = netId, method
      local h = health(veh)
      payload.body, payload.engine = h.body, h.engine
      TriggerServerEvent('tacov:workshop:apply', payload)
    end)
  end

  local function variantMenu(title, icon, modType, price, kind)
    local n = GetNumVehicleMods(veh, modType)
    local cur = GetVehicleMod(veh, modType)
    local items = { { id = '-1', label = 'Serie', icon = icon, price = 'kostenlos', priceValue = 0, badge = cur == -1 and 'montiert' or nil,
      pv = { kind = kind, modType = modType, index = -1 }, buy = { kind = kind, modType = modType, value = -1 } } }
    for i = 0, n - 1 do
      items[#items + 1] = { id = tostring(i), label = modLabel(veh, modType, i), icon = icon, price = fmt(price), priceValue = price,
        pv = { kind = kind, modType = modType, index = i }, buy = { kind = kind, modType = modType, value = i }, badge = cur == i and 'montiert' or nil }
    end
    local info = n > 0 and ('%d Varianten · Vorschau beim Markieren'):format(n) or 'Für dieses Fahrzeug nicht verfügbar'
    choiceMenu(veh, { id = 'ws_var_' .. modType, title = title, icon = icon, info = info, items = items }, apply)
  end

  if TacoV.Menu.isOpen() then TacoV.Menu.close() end
  TacoV.Menu.open({
    id = 'ws', title = 'Werkstatt', icon = 'wrench', info = ('%s · %s · Bargeld %s · Konto %s'):format(d.label, d.plate, fmt(d.cash), fmt(d.bank)),
    note = 'Markierte Teile werden am Fahrzeug gezeigt; ohne Kauf wird alles zurückgesetzt.',
    onClose = function() restore(veh) original = nil end,
    items = {
      { id = 'repair', label = 'Reparatur', icon = 'tool', price = d.repair > 0 and fmt(d.repair) or nil,
        sub = d.repair > 0 and ('Schaden %d %%'):format(d.damagePercent) or 'kein Schaden', dim = d.repair <= 0 },
      { id = 'upgrades', label = 'Leistung', icon = 'engine', sub = 'Motor, Bremsen, Getriebe, Fahrwerk, Turbo', section = 'Tuning' },
      { id = 'parts', label = 'Karosserie', icon = 'car', sub = 'Spoiler, Stoßstangen, Schweller, Auspuff, Haube, Dach …' },
      { id = 'wheels', label = 'Felgen', icon = 'speed', price = fmt(d.wheels), sub = 'Felgenart und Modell' },
      { id = 'wheelcolor', label = 'Felgenfarbe', icon = 'star', price = fmt(d.wheelColor) },
      { id = 'paint', label = 'Lackierung', icon = 'star', price = fmt(d.paint), section = 'Optik', sub = 'Hauptfarbe, Zweitfarbe, Perlglanz' },
      { id = 'tint', label = 'Fensterfarbe', icon = 'door', price = fmt(d.tint) },
      { id = 'xenon', label = 'Xenon-Scheinwerfer', icon = 'fitness', price = fmt(d.xenon), badge = IsToggleModOn(veh, 22) and 'montiert' or nil },
      { id = 'plate', label = 'Kennzeichenstil', icon = 'doc', price = fmt(d.plateStyle) },
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
      TacoV.Menu.open({ id = 'ws_up', title = 'Leistung', icon = 'engine', info = 'Teil wählen', items = items }, function(uid)
        local up
        for _, u in ipairs(d.upgrades) do if u.id == uid then up = u end end
        if not up then return end
        local li = {}
        for i, name in ipairs(up.levels) do
          li[i] = { id = tostring(i), label = name, icon = 'next', price = fmt(up.prices[i]), priceValue = up.prices[i],
            buy = { kind = 'upgrade', id = up.id, level = i } }
        end
        choiceMenu(veh, { id = 'ws_lvl', title = up.label, icon = up.icon, info = 'Stufe wählen', items = li }, function(buy, price)
          apply(buy, price, up.label .. ' ' .. up.levels[buy.level])
        end)
      end)
    elseif id == 'parts' then
      local items = {}
      for _, pt in ipairs(d.parts) do
        local n = GetNumVehicleMods(veh, pt.modType)
        items[#items + 1] = { id = pt.id, label = pt.label, icon = 'car', price = fmt(pt.price), dim = n == 0,
          sub = n > 0 and ('%d Varianten · aktuell: %s'):format(n, modLabel(veh, pt.modType, GetVehicleMod(veh, pt.modType))) or 'nicht verfügbar' }
      end
      TacoV.Menu.open({ id = 'ws_parts', title = 'Karosserie', icon = 'car', info = 'Teil wählen', items = items }, function(pid)
        for _, pt in ipairs(d.parts) do
          if pt.id == pid then variantMenu(pt.label, 'car', pt.modType, pt.price, 'part') end
        end
      end)
    elseif id == 'paint' then
      TacoV.Menu.open({ id = 'ws_paintslot', title = 'Lackierung', icon = 'star', info = fmt(d.paint) .. ' je Farbe', items = {
        { id = '1', label = 'Hauptfarbe', icon = 'star' }, { id = '2', label = 'Zweitfarbe', icon = 'star' }, { id = 'pearl', label = 'Perlglanz', icon = 'star' },
      } }, function(slot)
        local items = {}
        for _, col in ipairs(d.colors) do
          local pv = slot == 'pearl' and { kind = 'pearl', value = col.id } or { kind = 'paint', value = col.id, slot = tonumber(slot) }
          items[#items + 1] = { id = tostring(col.id), label = col.label, icon = 'star', price = fmt(d.paint), priceValue = d.paint, pv = pv,
            buy = slot == 'pearl' and { kind = 'pearl', value = col.id } or { kind = 'paint', value = col.id, slot = tonumber(slot) } }
        end
        local title = slot == 'pearl' and 'Perlglanz' or (slot == '2' and 'Zweitfarbe' or 'Hauptfarbe')
        choiceMenu(veh, { id = 'ws_paint', title = title, icon = 'star', info = 'Vorschau beim Markieren', items = items }, apply)
      end)
    elseif id == 'wheelcolor' then
      local items = {}
      for _, col in ipairs(d.wheelColors) do
        items[#items + 1] = { id = tostring(col.id), label = col.label, icon = 'star', price = fmt(d.wheelColor), priceValue = d.wheelColor,
          pv = { kind = 'wheelcolor', value = col.id }, buy = { kind = 'wheelcolor', value = col.id } }
      end
      choiceMenu(veh, { id = 'ws_wcol', title = 'Felgenfarbe', icon = 'star', info = 'Vorschau beim Markieren', items = items }, apply)
    elseif id == 'tint' then
      local items = {}
      for _, t in ipairs(d.tints) do
        items[#items + 1] = { id = tostring(t.id), label = t.label, icon = 'door', price = fmt(d.tint), priceValue = d.tint,
          pv = { kind = 'tint', value = t.id }, buy = { kind = 'tint', value = t.id } }
      end
      choiceMenu(veh, { id = 'ws_tint', title = 'Fensterfarbe', icon = 'door', info = 'Vorschau beim Markieren', items = items }, apply)
    elseif id == 'xenon' then
      apply({ kind = 'xenon', value = not IsToggleModOn(veh, 22) }, IsToggleModOn(veh, 22) and 0 or d.xenon, IsToggleModOn(veh, 22) and 'Xenon ausbauen' or 'Xenon-Scheinwerfer')
    elseif id == 'plate' then
      local items = {}
      for _, p in ipairs(d.plateStyles) do
        items[#items + 1] = { id = tostring(p.id), label = p.label, icon = 'doc', price = fmt(d.plateStyle), priceValue = d.plateStyle,
          pv = { kind = 'plate', value = p.id }, buy = { kind = 'plate', value = p.id } }
      end
      choiceMenu(veh, { id = 'ws_plate', title = 'Kennzeichenstil', icon = 'doc', info = 'Vorschau beim Markieren', items = items }, apply)
    elseif id == 'wheels' then
      local types = {}
      for _, t in ipairs(d.wheelTypes) do types[#types + 1] = { id = tostring(t.id), label = t.label, icon = 'speed' } end
      local curType = GetVehicleWheelType(veh)
      TacoV.Menu.open({ id = 'ws_wt', title = 'Felgen', icon = 'speed', info = 'Felgenart wählen', items = types }, function(wt)
        wt = tonumber(wt)
        SetVehicleWheelType(veh, wt)
        local n = math.min(Cfg.wheelsMax, GetNumVehicleMods(veh, 23))
        SetVehicleWheelType(veh, curType)
        local li = {}
        for i = 0, n - 1 do
          li[#li + 1] = { id = tostring(i), label = modLabel(veh, 23, i), icon = 'speed', price = fmt(d.wheels), priceValue = d.wheels,
            pv = { kind = 'wheels', wheelType = wt, value = i }, buy = { kind = 'wheels', wheelType = wt, value = i } }
        end
        if #li == 0 then li[1] = { id = 'none', label = 'Keine Felgen dieser Art für das Fahrzeug', dim = true } end
        choiceMenu(veh, { id = 'ws_w', title = 'Felgen', icon = 'speed', info = ('%d Modelle · Vorschau beim Markieren'):format(n), items = li }, apply)
      end)
    end
  end)
end)

-- Umbau am Fahrzeug nach Freigabe des Servers
RegisterNetEvent('tacov:workshop:do', function(netId, a)
  local veh = NetworkGetEntityFromNetworkId(netId)
  if veh == 0 or not DoesEntityExist(veh) or type(a) ~= 'table' then return end
  if original then TacoV.Vehicles.applyProps(veh, original) end
  SetVehicleModKit(veh, 0)
  if a.kind == 'repair' then
    SetVehicleFixed(veh)
    SetVehicleEngineHealth(veh, 1000.0)
    SetVehicleBodyHealth(veh, 1000.0)
    SetVehicleDirtLevel(veh, 0.0)
  else
    preview(veh, a)
  end
  original = TacoV.Vehicles.propsOf(veh)
  TriggerServerEvent('tacov:workshop:props', netId, original)
  -- Menü mit frischen Daten neu öffnen
  TriggerServerEvent('tacov:workshop:open', netId, { body = GetVehicleBodyHealth(veh), engine = GetVehicleEngineHealth(veh) })
end)
