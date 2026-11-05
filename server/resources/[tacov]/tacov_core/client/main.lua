-- Client-Kern: Anmeldung beim Server, Charakterauswahl, Spawn, Herzschlag (Position/Aktivität).
TacoV = TacoV or {}
TacoV.Client = { character = nil, role = 'player', bank = 0 }

local spawned = false

local function setPedVisible(visible)
  local ped = PlayerPedId()
  SetEntityVisible(ped, visible, false)
  FreezeEntityPosition(ped, not visible)
  SetEntityInvincible(ped, not visible)
end

local function spawnAt(pos)
  local ped = PlayerPedId()
  local x, y, z, h = pos.x, pos.y, pos.z, pos.w or pos.heading or 0.0
  RequestCollisionAtCoord(x, y, z)
  NetworkResurrectLocalPlayer(x, y, z, h + 0.0, true, false)
  ClearPedTasksImmediately(ped)
  ped = PlayerPedId()
  SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
  SetEntityHeading(ped, h + 0.0)
  local t = GetGameTimer()
  while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() - t < 5000 do Wait(50) end
  setPedVisible(true)
  spawned = true
end

CreateThread(function()
  -- Automatisches Spawnen des Grundspiels aus; der Kern spawnt nach der Charakterauswahl.
  if GetResourceState('spawnmanager') == 'started' then
    exports.spawnmanager:setAutoSpawn(false)
  end
  while not NetworkIsSessionStarted() do Wait(100) end
  -- Ladebildschirm beenden („Awaiting scripts“); das macht sonst der Spawnmanager
  ShutdownLoadingScreen()
  ShutdownLoadingScreenNui()
  DoScreenFadeOut(0)
  setPedVisible(false)
  TriggerServerEvent('tacov:core:clientReady')
end)

RegisterNetEvent('tacov:core:role', function(role)
  TacoV.Client.role = role
  TacoV.UI.send('role', role)
end)

RegisterNetEvent('tacov:core:characters', function(data)
  TacoV.UI.open('characters', data)
  DoScreenFadeIn(500)
end)

RegisterNetEvent('tacov:core:characterLoaded', function(c)
  TacoV.Client.character = c
  TacoV.Client.bank = c.bank or 0
  TacoV.UI.close()
  DoScreenFadeOut(300)
  Wait(300)
  spawnAt(c.position)
  TacoV.Hud.refresh()
  DoScreenFadeIn(800)
  TriggerEvent('tacov:client:characterLoaded', c)
end)

RegisterNetEvent('tacov:core:bank', function(balance)
  TacoV.Client.bank = balance
  TacoV.UI.send('bank', balance)
end)

-- Hände hoch (H): Animation an/aus (Konzept 5)
local handsUp = false
function TacoV.Client.toggleHandsUp()
  local ped = PlayerPedId()
  if handsUp then
    ClearPedTasks(ped)
    handsUp = false
    return
  end
  if IsPedInAnyVehicle(ped, false) then return end
  RequestAnimDict('missminuteman_1ig_2')
  local t = GetGameTimer()
  while not HasAnimDictLoaded('missminuteman_1ig_2') and GetGameTimer() - t < 2000 do Wait(10) end
  TaskPlayAnim(ped, 'missminuteman_1ig_2', 'handsup_base', 8.0, 8.0, -1, 49, 0, false, false, false)
  handsUp = true
end

RegisterNetEvent('tacov:core:notify', function(kind, text)
  TacoV.UI.send('notify', { kind = kind, text = text })
end)

-- Herzschlag: alle 10 s Position und ob der Spieler aktiv war (Konzept 1: AFK zählt nicht)
CreateThread(function()
  local lastPos
  while true do
    Wait(10000)
    if spawned then
      local ped = PlayerPedId()
      local pos = GetEntityCoords(ped)
      local active = not lastPos or #(pos - lastPos) > 0.5 or IsControlPressed(0, 24) or IsControlPressed(0, 32)
      lastPos = pos
      TriggerServerEvent('tacov:core:heartbeat', vector4(pos.x, pos.y, pos.z, GetEntityHeading(ped)), active)
    end
  end
end)

exports('getCharacter', function() return TacoV.Client.character end)
exports('getRole', function() return TacoV.Client.role end)
