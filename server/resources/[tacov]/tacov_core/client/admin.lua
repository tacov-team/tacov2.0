-- Admin-Grundgerüst (Client, Punkt 5.1): Noclip-Bewegung, Unsichtbarkeit (eigene und fremde über Statebags), Teleport
-- und das Team-Menü (F9 im Admin-Dienst). Rechte prüft ausschließlich der Server.
TacoV = TacoV or {}
TacoV.Admin = { invisible = false, noclip = false }

local function notify(kind, text) TacoV.UI.send('notify', { kind = kind, text = text }) end

-- ---------------------------------------------------------------- Teleport

local function groundZ(x, y, z)
  for _, h in ipairs({ z > 0 and z or 1000.0, 800.0, 500.0, 300.0, 150.0, 80.0, 40.0, 10.0 }) do
    local ok, gz = GetGroundZFor_3dCoord(x, y, h, false)
    if ok then return gz + 0.5 end
  end
  return z > 0 and z or 100.0
end

local function teleport(x, y, z, heading)
  local ped = PlayerPedId()
  local ent = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or ped
  DoScreenFadeOut(200)
  Wait(220)
  RequestCollisionAtCoord(x, y, z)
  if not z or z <= 0 then
    SetEntityCoordsNoOffset(ent, x, y, 1000.0, false, false, false)
    FreezeEntityPosition(ent, true)
    local waited = 0
    while not HasCollisionLoadedAroundEntity(ent) and waited < 2000 do Wait(50) waited = waited + 50 end
    z = groundZ(x, y, 0.0)
    FreezeEntityPosition(ent, false)
  end
  SetEntityCoordsNoOffset(ent, x, y, z, false, false, false)
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
      SetEntityCoordsNoOffset(ent, p.x, p.y, groundZ(p.x, p.y, p.z), false, false, false)
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

-- ---------------------------------------------------------------- Team-Menü (F9 im Dienst)

local players = {}
RegisterNetEvent('tacov:admin:players', function(list) players = list end)

local function playerItems()
  local items = {}
  for _, p in ipairs(players) do
    if p.id ~= GetPlayerServerId(PlayerId()) then
      items[#items + 1] = { id = tostring(p.id), label = ('#%d  %s'):format(p.id, p.name), icon = 'user',
        sub = p.dist < 1000 and ('%.0f m entfernt'):format(p.dist) or ('%.1f km entfernt'):format(p.dist / 1000) }
    end
  end
  if #items == 0 then items[1] = { id = 'none', label = 'Keine anderen Spieler online', icon = 'info', dim = true } end
  return items
end

function TacoV.Admin.openMenu()
  if TacoV.Menu.isOpen() then TacoV.Menu.close() return end
  TriggerServerEvent('tacov:admin:players')
  local function items()
    return {
      { id = 'invisible', label = 'Unsichtbar', icon = 'search', badge = TacoV.Admin.invisible and 'An' or 'Aus', section = 'Ich' },
      { id = 'noclip',    label = 'Noclip',     icon = 'play',   badge = TacoV.Admin.noclip and 'An' or 'Aus', sub = 'WASD, Q/E, Shift' },
      { id = 'waypoint',  label = 'Zum Wegpunkt teleportieren', icon = 'pin', section = 'Teleport' },
      { id = 'goto',      label = 'Zu Spieler teleportieren', icon = 'next' },
      { id = 'bring',     label = 'Spieler herholen', icon = 'back' },
      { id = 'players',   label = 'Spielerliste und Akte', icon = 'group', dim = true, badge = 'bald', section = 'Team' },
      { id = 'offduty',   label = 'Admin-Dienst beenden', icon = 'shield' },
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
