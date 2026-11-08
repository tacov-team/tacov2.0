-- Admin-Grundgerüst (Client, Punkt 5.1): Noclip-Bewegung, Unsichtbarkeit (eigene und fremde über Statebags), Teleport
-- und das Team-Menü (F9 im Admin-Dienst). Rechte prüft ausschließlich der Server.
TacoV = TacoV or {}
TacoV.Admin = { invisible = false, noclip = false }

local function notify(kind, text) TacoV.UI.send('notify', { kind = kind, text = text }) end

-- ---------------------------------------------------------------- Teleport

--- Bodenhöhe an x/y finden: Entity schrittweise nach oben setzen, Kollision laden lassen, Boden abfragen (wie vMenu).
local function findGround(ent, x, y, hint)
  local heights = { hint }
  for h = 0, 1000, 25 do heights[#heights + 1] = h + 0.0 end
  FreezeEntityPosition(ent, true)
  for _, h in ipairs(heights) do
    if h then
      SetEntityCoordsNoOffset(ent, x, y, h, false, false, false)
      RequestCollisionAtCoord(x, y, h)
      Wait(20)
      local ok, gz = GetGroundZFor_3dCoord(x, y, h, false)
      if ok and gz > 0.0 then
        local water, wz = GetWaterHeightNoWaves(x, y, gz)
        if water and wz > gz then gz = wz end
        return gz + 0.6
      end
    end
  end
  return hint or 100.0
end

local function teleport(x, y, z, heading)
  local ped = PlayerPedId()
  local ent = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or ped
  DoScreenFadeOut(200)
  Wait(220)
  if not z or z <= 0 then
    z = findGround(ent, x, y, nil)
  else
    SetEntityCoordsNoOffset(ent, x, y, z, false, false, false)
    RequestCollisionAtCoord(x, y, z)
    local waited = 0
    while not HasCollisionLoadedAroundEntity(ent) and waited < 2000 do Wait(50) waited = waited + 50 end
  end
  SetEntityCoordsNoOffset(ent, x, y, z, false, false, false)
  FreezeEntityPosition(ent, TacoV.Admin.noclip)
  if heading then SetEntityHeading(ent, heading) end
  Wait(150)
  DoScreenFadeIn(300)
end

RegisterNetEvent('tacov:admin:setCoords', function(x, y, z, heading)
  teleport(x + 0.0, y + 0.0, z and z + 0.0 or -1.0, heading)
end)

RegisterNetEvent('tacov:admin:toWaypoint', function()
  local blip = GetFirstBlipInfoId(8)
  if not DoesBlipExist(blip) then notify('error', 'Kein Wegpunkt gesetzt.') return end
  local c = GetBlipInfoIdCoord(blip)
  teleport(c.x, c.y, -1.0, nil)
  notify('info', 'Zum Wegpunkt teleportiert.')
end)

-- ---------------------------------------------------------------- Zustand

RegisterNetEvent('tacov:admin:state', function(s)
  local ped = PlayerPedId()
  if s.invisible ~= TacoV.Admin.invisible then
    TacoV.Admin.invisible = s.invisible
    SetEntityVisible(ped, not s.invisible, false)
    notify('info', s.invisible and 'Du bist jetzt unsichtbar.' or 'Du bist wieder sichtbar.')
  end
  if s.noclip ~= TacoV.Admin.noclip then
    TacoV.Admin.noclip = s.noclip
    local ent = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or ped
    FreezeEntityPosition(ent, s.noclip)
    SetEntityCollision(ent, not s.noclip, not s.noclip)
    SetEntityInvincible(ent, s.noclip)
    if not s.noclip then
      local p = GetEntityCoords(ent)
      local gz = findGround(ent, p.x, p.y, p.z)
      SetEntityCoordsNoOffset(ent, p.x, p.y, math.min(gz, p.z), false, false, false)
      FreezeEntityPosition(ent, false)
    end
    notify('info', s.noclip and 'Noclip an · WASD, Q/E hoch/runter, Shift schnell.' or 'Noclip aus.')
  end
end)

-- Noclip-Bewegung
CreateThread(function()
  while true do
    if TacoV.Admin.noclip then
      Wait(0)
      local ped = PlayerPedId()
      local ent = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or ped
      local rot = GetGameplayCamRot(2)
      local yaw, pitch = math.rad(rot.z), math.rad(rot.x)
      local fwd = vector3(-math.sin(yaw) * math.cos(pitch), math.cos(yaw) * math.cos(pitch), math.sin(pitch))
      local right = vector3(math.cos(yaw), math.sin(yaw), 0.0)
      local speed = IsControlPressed(0, 21) and 2.5 or (IsControlPressed(0, 36) and 0.15 or 0.7)
      local move = vector3(0.0, 0.0, 0.0)
      if IsControlPressed(0, 32) then move = move + fwd end
      if IsControlPressed(0, 33) then move = move - fwd end
      if IsControlPressed(0, 34) then move = move - right end
      if IsControlPressed(0, 35) then move = move + right end
      if IsControlPressed(0, 44) then move = move - vector3(0.0, 0.0, 1.0) end  -- Q
      if IsControlPressed(0, 38) then move = move + vector3(0.0, 0.0, 1.0) end  -- E
      DisableControlAction(0, 44, true)
      DisableControlAction(0, 38, true)
      local p = GetEntityCoords(ent) + move * speed
      SetEntityCoordsNoOffset(ent, p.x, p.y, p.z, false, false, false)
      SetEntityHeading(ent, rot.z)
      FreezeEntityPosition(ent, true)
    else
      Wait(250)
    end
  end
end)

-- Fremde unsichtbare Teammitglieder auch lokal ausblenden (Statebag), falls die Sichtbarkeit nicht synchronisiert wurde
CreateThread(function()
  while true do
    Wait(1000)
    for _, pl in ipairs(GetActivePlayers()) do
      if pl ~= PlayerId() then
        local inv = Player(GetPlayerServerId(pl)).state.admin_invisible
        local ped = GetPlayerPed(pl)
        if ped ~= 0 and inv ~= nil then SetEntityVisible(ped, not inv, false) end
      end
    end
  end
end)

-- ---------------------------------------------------------------- Dienst-Uniform

local savedOutfit = nil

local function wearOutfit()
  local ped = PlayerPedId()
  local outfit = TacoV.Config.AdutyOutfit[GetEntityArchetypeName(ped)]
  if not outfit or savedOutfit then return end
  savedOutfit = { components = {}, props = {} }
  for comp = 0, 11 do
    savedOutfit.components[comp] = { GetPedDrawableVariation(ped, comp), GetPedTextureVariation(ped, comp), GetPedPaletteVariation(ped, comp) }
  end
  for prop = 0, 7 do
    savedOutfit.props[prop] = { GetPedPropIndex(ped, prop), GetPedPropTextureIndex(ped, prop) }
  end
  for comp, v in pairs(outfit.components) do SetPedComponentVariation(ped, comp, v[1], v[2], 0) end
  for prop, v in pairs(outfit.props) do
    if v then SetPedPropIndex(ped, prop, v[1], v[2], true) else ClearPedProp(ped, prop) end
  end
end

local function restoreOutfit()
  if not savedOutfit then return end
  local ped = PlayerPedId()
  for comp, v in pairs(savedOutfit.components) do SetPedComponentVariation(ped, comp, v[1], v[2], v[3]) end
  for prop, v in pairs(savedOutfit.props) do
    if v[1] >= 0 then SetPedPropIndex(ped, prop, v[1], v[2], true) else ClearPedProp(ped, prop) end
  end
  savedOutfit = nil
end

AddEventHandler('tacov:client:aduty', function(on)
  if on then wearOutfit() else restoreOutfit() end
end)

-- ---------------------------------------------------------------- Team-Menü (F9 im Dienst)

local players = {}
RegisterNetEvent('tacov:admin:players', function(list) players = list end)

RegisterNetEvent('tacov:admin:healed', function()
  local ped = PlayerPedId()
  SetEntityHealth(ped, GetEntityMaxHealth(ped))
  SetPedArmour(ped, 100)
  ClearPedBloodDamage(ped)
end)

--- Spielerliste; includeSelf = true zeigt den eigenen Eintrag (Akte), für Teleports bleibt er weg
local function playerItems(includeSelf)
  local items = {}
  local me = GetPlayerServerId(PlayerId())
  for _, p in ipairs(players) do
    if p.id ~= me then
      items[#items + 1] = { id = tostring(p.id), label = ('#%d  %s'):format(p.id, p.name), icon = 'user',
        sub = p.dist < 1000 and ('%.0f m entfernt'):format(p.dist) or ('%.1f km entfernt'):format(p.dist / 1000) }
    elseif includeSelf then
      table.insert(items, 1, { id = tostring(p.id), label = ('#%d  %s'):format(p.id, p.name), icon = 'shield', sub = 'Du', badge = 'Ich' })
    end
  end
  if #items == 0 then items[1] = { id = 'none', label = 'Keine anderen Spieler online', icon = 'info', dim = true } end
  return items
end

local Cfg = TacoV.Config
local function reasonMenu(title, onPick)
  local items = {}
  for i, r in ipairs(Cfg.AdminReasons) do items[#items + 1] = { id = tostring(i), label = r, icon = 'warn' } end
  TacoV.Menu.open({ id = 'admin_reason', title = title, icon = 'warn', info = 'Grund wählen · freier Text per Befehl',
    items = items }, function(id) onPick(Cfg.AdminReasons[tonumber(id)]) end)
end

local function sortedItems()
  local list = {}
  for name, def in pairs(Cfg.Items) do if not def.money then list[#list + 1] = { name = name, def = def } end end
  table.sort(list, function(a, b) return a.def.label < b.def.label end)
  return list
end

--- Untermenü „Geben“ für einen Spieler
local function giveMenu(target, name)
  TacoV.Menu.open({ id = 'admin_give', title = 'Geben', icon = 'gift', info = name, items = {
    { id = 'money', label = 'Geld', icon = 'cash', sub = 'Konto oder bar' },
    { id = 'item', label = 'Item', icon = 'bag', sub = 'nach Kategorie' },
    { id = 'vehicle', label = 'Fahrzeug', icon = 'car', sub = 'aus der Kaufliste, spawnt beim Spieler' },
  } }, function(kind)
    if kind == 'money' then
      local items = {}
      for _, a in ipairs(Cfg.AdminMoneyAmounts) do
        items[#items + 1] = { id = 'bank:' .. a, label = ('%s $ auf das Konto'):format(a), icon = 'card' }
      end
      for _, a in ipairs(Cfg.AdminMoneyAmounts) do
        items[#items + 1] = { id = 'cash:' .. a, label = ('%s $ bar'):format(a), icon = 'cash', section = #items == #Cfg.AdminMoneyAmounts and 'Bar' or nil }
      end
      TacoV.Menu.open({ id = 'admin_money', title = 'Geld geben', icon = 'cash', info = name, items = items }, function(id)
        local kind2, amount = id:match('^(%a+):(%d+)$')
        TriggerServerEvent('tacov:admin:give', target, 'money', tonumber(amount), kind2)
      end)
    elseif kind == 'item' then
      local cats = {}
      for id, label in pairs(Cfg.ItemCategories) do if id ~= 'money' then cats[#cats + 1] = { id = id, label = label, icon = 'box' } end end
      table.sort(cats, function(a, b) return a.label < b.label end)
      TacoV.Menu.open({ id = 'admin_itemcat', title = 'Item geben', icon = 'bag', info = name, items = cats }, function(cat)
        local items = {}
        for _, e in ipairs(sortedItems()) do
          if e.def.category == cat then items[#items + 1] = { id = e.name, label = e.def.label, icon = 'box', sub = e.name } end
        end
        if #items == 0 then items[1] = { id = 'none', label = 'Keine Items in dieser Kategorie', dim = true } end
        TacoV.Menu.open({ id = 'admin_item', title = Cfg.ItemCategories[cat], icon = 'bag', info = name, items = items }, function(item)
          if item == 'none' then return end
          local amounts = {}
          for _, n in ipairs({ 1, 5, 10, 25, 50, 100 }) do amounts[#amounts + 1] = { id = tostring(n), label = n .. 'x', icon = 'plus' } end
          TacoV.Menu.open({ id = 'admin_itemamount', title = Cfg.Items[item].label, icon = 'bag', info = 'Anzahl', items = amounts }, function(n)
            TriggerServerEvent('tacov:admin:give', target, 'item', item, tonumber(n))
            TacoV.Menu.back()
          end)
        end)
      end)
    elseif kind == 'vehicle' then
      local classes = {}
      for id, cls in pairs(Cfg.Vehicles.classes) do classes[#classes + 1] = { id = id, label = cls.label, icon = 'car', order = cls.order } end
      table.sort(classes, function(a, b) return a.order < b.order end)
      TacoV.Menu.open({ id = 'admin_vehcls', title = 'Fahrzeug geben', icon = 'car', info = name, items = classes }, function(cls)
        local items = {}
        for _, v in ipairs(Cfg.Vehicles.list) do
          if v.class == cls then items[#items + 1] = { id = v.model, label = v.label, icon = 'car', sub = v.model, price = v.price } end
        end
        TacoV.Menu.open({ id = 'admin_veh', title = Cfg.Vehicles.classes[cls].label, icon = 'car', info = name, items = items }, function(model)
          TacoV.Menu.close()
          TriggerServerEvent('tacov:admin:give', target, 'vehicle', model)
        end)
      end)
    end
  end)
end

--- Akte + Aktionen eines Spielers
RegisterNetEvent('tacov:admin:file', function(f)
  local name = ('#%d %s'):format(f.id, f.name)
  local items = {
    { id = 'i1', label = 'Rolle: ' .. tostring(f.role), icon = 'id', dim = true, section = 'Akte',
      sub = 'Discord ' .. tostring(f.discordId) },
    f.characterId and { id = 'i2', label = ('Charakter #%d · Level %s · %s h Spielzeit'):format(f.characterId, tostring(f.level), tostring(f.playtimeHours)),
      icon = 'user', dim = true, sub = f.faction and (f.faction .. ' · Rang ' .. tostring(f.factionRank)) or 'Zivilist' }
      or { id = 'i2', label = 'Kein Charakter geladen', icon = 'user', dim = true },
    { id = 'i3', label = ('Konto %s · Bar %s'):format(tostring(f.bank or '–'), tostring(f.cash or '–')), icon = 'cash', dim = true },
    { id = 'i4', label = ('%d Verwarnungen · %d Sperren'):format(f.warns or 0, f.bans or 0), icon = 'warn', dim = true,
      sub = f.lastWarn and ('Zuletzt: ' .. f.lastWarn) or nil },
    { id = 'goto', label = 'Zu Spieler teleportieren', icon = 'next', section = 'Aktionen' },
    { id = 'bring', label = 'Spieler herholen', icon = 'back' },
    { id = 'heal', label = 'Heilen', icon = 'heart', sub = 'Leben, Rüstung, Hunger, Durst' },
    { id = 'give', label = 'Geben', icon = 'gift', sub = 'Geld, Items, Fahrzeug' },
    { id = 'refund', label = 'Erstattung', icon = 'cash', sub = 'Geld oder Item mit Grund, ab 50.000 $ Vier-Augen' },
    { id = 'warn', label = 'Verwarnen', icon = 'warn', section = 'Maßnahmen' },
    { id = 'kick', label = 'Kicken', icon = 'x' },
    { id = 'ban', label = 'Sperren', icon = 'lock' },
  }
  if f.licenses then
    local l = {}
    for k in pairs(f.licenses) do l[#l + 1] = k end
    table.sort(l)
    items[4].sub = (items[4].sub and (items[4].sub .. ' · ') or '') .. 'Führerscheine: ' .. (#l > 0 and table.concat(l, ', ') or 'keine')
  end
  if f.id == GetPlayerServerId(PlayerId()) then
    for i = #items, 1, -1 do
      if items[i].id == 'goto' or items[i].id == 'bring' or items[i].id == 'kick' or items[i].id == 'ban' or items[i].id == 'warn' then table.remove(items, i) end
    end
    items[5].section = 'Aktionen'
  end
  TacoV.Menu.open({ id = 'admin_player', title = f.name, icon = 'user', info = name, items = items,
    note = 'Jede Aktion wird protokolliert.' }, function(id)
    if id == 'goto' or id == 'bring' then
      TacoV.Menu.close()
      TriggerServerEvent('tacov:admin:teleport', id == 'goto' and 'player' or 'bring', f.id)
    elseif id == 'heal' then
      TriggerServerEvent('tacov:admin:heal', f.id)
    elseif id == 'give' then
      giveMenu(f.id, name)
    elseif id == 'refund' then
      TacoV.Menu.open({ id = 'refund_kind', title = 'Erstattung', icon = 'cash', info = name, items = {
        { id = 'money', label = 'Geld', icon = 'cash', sub = 'Betrag eingeben' },
        { id = 'item', label = 'Item', icon = 'bag', sub = 'Item und Anzahl' },
      } }, function(kind)
        local function withReason(amount, item)
          TacoV.UI.ask({ title = 'Grund der Erstattung', placeholder = 'z. B. Bug beim Einparken, Ticket #12', maxLength = 255, icon = 'doc' }, function(reason)
            if reason and #reason >= 3 then TacoV.Menu.close() TriggerServerEvent('tacov:refunds:request', f.id, kind, amount, item, reason) end
          end)
        end
        if kind == 'money' then
          TacoV.UI.ask({ title = 'Betrag in $', maxLength = 9, numeric = true, icon = 'cash' }, function(v)
            local n = tonumber(v or '')
            if n and n >= 1 then withReason(math.floor(n), nil) end
          end)
        else
          local list = {}
          for _, e in ipairs(sortedItems()) do list[#list + 1] = { id = e.name, label = e.def.label, icon = 'box', sub = e.name } end
          TacoV.Menu.open({ id = 'refund_item', title = 'Item', icon = 'bag', items = list }, function(item)
            TacoV.UI.ask({ title = 'Anzahl', value = '1', maxLength = 4, numeric = true, icon = 'bag' }, function(v)
              local n = tonumber(v or '')
              if n and n >= 1 then withReason(math.floor(n), item) end
            end)
          end)
        end
      end)
    elseif id == 'warn' then
      reasonMenu('Verwarnen · ' .. name, function(r) TacoV.Menu.back() TriggerServerEvent('tacov:admin:punish', 'warn', f.id, r) end)
    elseif id == 'kick' then
      reasonMenu('Kicken · ' .. name, function(r) TacoV.Menu.close() TriggerServerEvent('tacov:admin:punish', 'kick', f.id, r) end)
    elseif id == 'ban' then
      local durations = {}
      for i, d in ipairs(Cfg.AdminBanDurations) do durations[#durations + 1] = { id = tostring(i), label = d[2], icon = 'clock' } end
      TacoV.Menu.open({ id = 'admin_bandur', title = 'Sperren · ' .. name, icon = 'lock', info = 'Dauer wählen', items = durations }, function(di)
        local hours = Cfg.AdminBanDurations[tonumber(di)][1]
        reasonMenu('Sperren · ' .. name, function(r) TacoV.Menu.close() TriggerServerEvent('tacov:admin:punish', 'ban', f.id, r, hours) end)
      end)
    end
  end)
end)

-- ---------------------------------------------------------------- Fahrzeuge (5.10)

local function loadModel(name)
  local hash = GetHashKey(name)
  if not IsModelValid(hash) or not IsModelAVehicle(hash) then return nil end
  RequestModel(hash)
  local t = GetGameTimer()
  while not HasModelLoaded(hash) and GetGameTimer() - t < 5000 do Wait(20) end
  return HasModelLoaded(hash) and hash or nil
end

local function control(veh)
  NetworkRequestControlOfEntity(veh)
  local t = GetGameTimer()
  while not NetworkHasControlOfEntity(veh) and GetGameTimer() - t < 1000 do Wait(10) end
  return NetworkHasControlOfEntity(veh)
end

local function targetVehicle()
  local ped = PlayerPedId()
  local veh = GetVehiclePedIsIn(ped, false)
  if veh ~= 0 then return veh end
  local pos = GetEntityCoords(ped)
  local best, bestD = 0, 6.0
  for _, v in ipairs(GetGamePool('CVehicle')) do
    local d = #(GetEntityCoords(v) - pos)
    if d < bestD then best, bestD = v, d end
  end
  return best
end

RegisterNetEvent('tacov:admin:vehicle:do', function(action, netId, a, b)
  if action == 'spawn' then
    local hash = loadModel(a)
    if not hash then notify('error', 'Unbekanntes Fahrzeugmodell: ' .. tostring(a)) return end
    local ped = PlayerPedId()
    local old = GetVehiclePedIsIn(ped, false)
    local pos, h = GetEntityCoords(ped), GetEntityHeading(ped)
    if old ~= 0 and control(old) then DeleteEntity(old) end
    local veh = CreateVehicle(hash, pos.x, pos.y, pos.z, h, true, false)
    local t = GetGameTimer()
    while not DoesEntityExist(veh) and GetGameTimer() - t < 3000 do Wait(20) end
    if not DoesEntityExist(veh) then notify('error', 'Fahrzeug konnte nicht erstellt werden.') return end
    SetModelAsNoLongerNeeded(hash)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleNumberPlateText(veh, b)
    SetVehicleOnGroundProperly(veh)
    TacoV.Vehicles.keys[b] = true
    local tank = TacoV.Vehicles.tankOf(veh)
    Entity(veh).state:set('fuel', tank, true)
    Entity(veh).state:set('engine', true, true)
    SetVehicleEngineOn(veh, true, true, false)
    TaskWarpPedIntoVehicle(ped, veh, -1)
    notify('success', ('Team-Fahrzeug %s (%s) steht bereit.'):format(a, b))
    return
  end
  local veh = NetworkGetEntityFromNetworkId(netId or 0)
  if veh == 0 or not DoesEntityExist(veh) or not control(veh) then return end
  if action == 'repair' then
    SetVehicleFixed(veh) SetVehicleDeformationFixed(veh) SetVehicleUndriveable(veh, false)
    SetVehicleEngineHealth(veh, 1000.0) SetVehicleBodyHealth(veh, 1000.0) SetVehiclePetrolTankHealth(veh, 1000.0) SetVehicleDirtLevel(veh, 0.0)
  elseif action == 'fuel' then
    local tank = TacoV.Vehicles.tankOf(veh)
    Entity(veh).state:set('fuel', tank, true)
    SetVehicleFuelLevel(veh, 100.0)
  elseif action == 'tune' then
    SetVehicleModKit(veh, 0)
    for _, mt in ipairs({ 11, 12, 13, 15, 16 }) do SetVehicleMod(veh, mt, GetNumVehicleMods(veh, mt) - 1, false) end
    ToggleVehicleMod(veh, 18, true)
    ToggleVehicleMod(veh, 22, true)
    notify('success', 'Voll getunt.')
  elseif action == 'color' then
    SetVehicleColours(veh, tonumber(a), tonumber(b) or tonumber(a))
  elseif action == 'tint' then
    SetVehicleWindowTint(veh, tonumber(a))
  end
end)

function TacoV.Admin.openVehicles()
  local veh = targetVehicle()
  local plate = veh ~= 0 and TacoV.Vehicles.plateOf(veh) or nil
  local items = {
    { id = 'spawn', label = 'Team-Fahrzeug spawnen', icon = 'car', sub = 'temporär, kein Eigentum', section = 'Neu' },
  }
  if veh ~= 0 then
    local sec = ('Fahrzeug %s'):format(plate)
    items[#items + 1] = { id = 'owner', label = 'Besitzer anzeigen', icon = 'id', section = sec }
    items[#items + 1] = { id = 'repair', label = 'Reparieren', icon = 'wrench' }
    items[#items + 1] = { id = 'fuel', label = 'Volltanken', icon = 'fuel' }
    items[#items + 1] = { id = 'plate', label = 'Kennzeichen ändern', icon = 'doc' }
    items[#items + 1] = { id = 'tune', label = 'Voll tunen', icon = 'engine' }
    items[#items + 1] = { id = 'color', label = 'Farbe', icon = 'star' }
    items[#items + 1] = { id = 'tint', label = 'Fensterfarbe', icon = 'search' }
    items[#items + 1] = { id = 'delete', label = 'Fahrzeug löschen', icon = 'x', section = 'Gefahr' }
  else
    items[#items + 1] = { id = 'none', label = 'Kein Fahrzeug in der Nähe', icon = 'info', dim = true, section = 'Fahrzeug' }
  end
  items[#items + 1] = { id = 'clear', label = 'Leere Fahrzeuge im Umkreis (15 m) löschen', icon = 'x', section = 'Aufräumen' }
  TacoV.Menu.open({ id = 'admin_vehicles', title = 'Fahrzeuge', icon = 'car', info = 'Team-Werkzeuge', note = 'Jede Aktion wird protokolliert.', items = items }, function(id)
    local netId = veh ~= 0 and NetworkGetNetworkIdFromEntity(veh) or 0
    if id == 'spawn' then
      local classes = {}
      for cid, cls in pairs(TacoV.Config.Vehicles.classes) do classes[#classes + 1] = { id = cid, label = cls.label, icon = 'car', order = cls.order } end
      table.sort(classes, function(x, y) return x.order < y.order end)
      classes[#classes + 1] = { id = '__custom', label = 'Modell eingeben', icon = 'plus', section = 'Sonstiges' }
      TacoV.Menu.open({ id = 'admin_vehcls', title = 'Team-Fahrzeug', icon = 'car', items = classes }, function(cls)
        if cls == '__custom' then
          TacoV.UI.ask({ title = 'Fahrzeugmodell (z. B. police)', maxLength = 32, icon = 'car' }, function(v)
            if v and #v > 0 then TacoV.Menu.close() TriggerServerEvent('tacov:admin:vehicle', 'spawn', 0, v) end
          end)
          return
        end
        local list = {}
        for _, v in ipairs(TacoV.Config.Vehicles.list) do if v.class == cls then list[#list + 1] = { id = v.model, label = v.label, icon = 'car', sub = v.model } end end
        TacoV.Menu.open({ id = 'admin_vehmodel', title = TacoV.Config.Vehicles.classes[cls].label, icon = 'car', items = list }, function(model)
          TacoV.Menu.close()
          TriggerServerEvent('tacov:admin:vehicle', 'spawn', 0, model)
        end)
      end)
    elseif id == 'owner' or id == 'repair' or id == 'fuel' or id == 'tune' then
      TriggerServerEvent('tacov:admin:vehicle', id, netId)
    elseif id == 'plate' then
      TacoV.UI.ask({ title = 'Neues Kennzeichen (max. 8 Zeichen)', value = plate, maxLength = 8, icon = 'doc' }, function(v)
        if v and #v > 1 then TriggerServerEvent('tacov:admin:vehicle', 'plate', netId, v) end
      end)
    elseif id == 'color' then
      local items2 = {}
      for _, c in ipairs(TacoV.Config.Workshop.colors) do items2[#items2 + 1] = { id = tostring(c.id), label = c.label, icon = 'star' } end
      TacoV.Menu.open({ id = 'admin_vehcolor', title = 'Farbe', icon = 'star', items = items2 }, function(c) TriggerServerEvent('tacov:admin:vehicle', 'color', netId, tonumber(c)) end)
    elseif id == 'tint' then
      local items2 = {}
      for _, t in ipairs(TacoV.Config.Workshop.tints) do items2[#items2 + 1] = { id = tostring(t.id), label = t.label, icon = 'search' } end
      TacoV.Menu.open({ id = 'admin_vehtint', title = 'Fensterfarbe', icon = 'search', items = items2 }, function(t) TriggerServerEvent('tacov:admin:vehicle', 'tint', netId, tonumber(t)) end)
    elseif id == 'delete' then
      TacoV.Menu.close()
      TriggerServerEvent('tacov:admin:vehicle', 'delete', netId)
    elseif id == 'clear' then
      TacoV.Menu.close()
      local pos = GetEntityCoords(PlayerPedId())
      local n = 0
      for _, v in ipairs(GetGamePool('CVehicle')) do
        if #(GetEntityCoords(v) - pos) < 15.0 and IsVehicleSeatFree(v, -1) and GetVehicleNumberOfPassengers(v) == 0 then
          TriggerServerEvent('tacov:admin:vehicle', 'delete', NetworkGetNetworkIdFromEntity(v))
          n = n + 1
        end
      end
      notify('info', ('%d Fahrzeuge zum Löschen gemeldet.'):format(n))
    end
  end)
end

RegisterNetEvent('tacov:refunds:list', function(list)
  local items = {}
  for _, r in ipairs(list) do
    items[#items + 1] = { id = tostring(r.id), label = ('#%d · %s für %s'):format(r.id, r.text, r.name), icon = 'cash', sub = r.reason .. ' · von ' .. r.requestedBy }
  end
  if #items == 0 then items[1] = { id = 'none', label = 'Keine offenen Anträge', icon = 'info', dim = true } end
  TacoV.Menu.open({ id = 'refunds', title = 'Offene Erstattungen', icon = 'cash', info = ('%d offen'):format(#list), items = items }, function(id)
    if id == 'none' then return end
    TacoV.Menu.open({ id = 'refund_decide', title = 'Antrag #' .. id, icon = 'cash', info = 'Vier-Augen-Prinzip', items = {
      { id = 'yes', label = 'Bestätigen und auszahlen', icon = 'check' },
      { id = 'no', label = 'Ablehnen', icon = 'x' },
    } }, function(a)
      TacoV.Menu.close()
      TriggerServerEvent('tacov:refunds:decide', tonumber(id), a == 'yes')
    end)
  end)
end)

function TacoV.Admin.openMenu()
  if TacoV.Menu.isOpen() then TacoV.Menu.close() return end
  TriggerServerEvent('tacov:admin:players')
  local function items()
    return {
      { id = 'players',   label = 'Spieler', icon = 'group', sub = 'Akte, Geben, Heilen, Maßnahmen', section = 'Team' },
      { id = 'creator',   label = 'Creator', icon = 'tool', sub = 'Orte, Türen, Aufzüge, NPCs …' },
      { id = 'vehicles',  label = 'Fahrzeuge', icon = 'car', sub = 'Spawnen, reparieren, Kennzeichen, löschen' },
      { id = 'refunds',   label = 'Offene Erstattungen', icon = 'cash', sub = 'Vier-Augen-Bestätigung (ab Manager)' },
      { id = 'world',     label = 'Welt', icon = 'clock', sub = 'Uhrzeit, Wetter, Ansage, Neustart' },
      { id = 'invisible', label = 'Unsichtbar', icon = 'search', badge = TacoV.Admin.invisible and 'An' or 'Aus', section = 'Ich' },
      { id = 'noclip',    label = 'Noclip',     icon = 'play',   badge = TacoV.Admin.noclip and 'An' or 'Aus', sub = 'WASD, Q/E, Shift' },
      { id = 'waypoint',  label = 'Zum Wegpunkt teleportieren', icon = 'pin', section = 'Teleport' },
      { id = 'goto',      label = 'Zu Spieler teleportieren', icon = 'next' },
      { id = 'bring',     label = 'Spieler herholen', icon = 'back' },
      { id = 'offduty',   label = 'Admin-Dienst beenden', icon = 'shield', section = 'Dienst' },
    }
  end
  TacoV.Menu.open({
    id = 'admin', title = 'Team-Menü', icon = 'shield',
    info = (TacoV.Client.adutyLabel or 'Team') .. ' · im Dienst',
    note = 'Jede Aktion wird protokolliert.', items = items(),
  }, function(id)
    if id == 'invisible' or id == 'noclip' then
      TriggerServerEvent('tacov:admin:toggle', id)
      SetTimeout(200, function() if TacoV.Menu.isOpen() then TacoV.Menu.update(items()) end end)
    elseif id == 'waypoint' then
      TacoV.Menu.close()
      TriggerServerEvent('tacov:admin:teleport', 'waypoint')
    elseif id == 'creator' then
      TacoV.Creator.openMenu()
    elseif id == 'vehicles' then
      TacoV.Admin.openVehicles()
    elseif id == 'refunds' then
      TriggerServerEvent('tacov:refunds:list')
    elseif id == 'world' then
      TacoV.World.openMenu()
    elseif id == 'players' then
      TacoV.Menu.open({ id = 'admin_players', title = 'Spieler', icon = 'group', info = ('%d online'):format(#players),
        items = playerItems(true) }, function(pid)
        if pid == 'none' then return end
        TriggerServerEvent('tacov:admin:file', tonumber(pid))
      end)
    elseif id == 'goto' or id == 'bring' then
      TacoV.Menu.open({ id = 'admin_' .. id, title = id == 'goto' and 'Zu Spieler teleportieren' or 'Spieler herholen', icon = 'group',
        info = 'Team-Menü · Teleport', items = playerItems() }, function(pid)
        if pid == 'none' then return end
        TacoV.Menu.close()
        TriggerServerEvent('tacov:admin:teleport', id == 'goto' and 'player' or 'bring', tonumber(pid))
      end)
    elseif id == 'offduty' then
      TacoV.Menu.close()
      TriggerServerEvent('tacov:core:aduty:toggle')
    end
  end)
end
