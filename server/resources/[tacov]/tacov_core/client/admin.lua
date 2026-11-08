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

function TacoV.Admin.openMenu()
  if TacoV.Menu.isOpen() then TacoV.Menu.close() return end
  TriggerServerEvent('tacov:admin:players')
  local function items()
    return {
      { id = 'players',   label = 'Spieler', icon = 'group', sub = 'Akte, Geben, Heilen, Maßnahmen', section = 'Team' },
      { id = 'creator',   label = 'Creator', icon = 'tool', sub = 'Orte, Türen, Aufzüge, NPCs …' },
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
