-- Fitness und Promille (Client, 6.9): Training an Stationen (E), Tempo-Bonus nach Fitness, Trunkenheit ab 0,5 ‰
-- (Kameraeffekt, Torkeln, Fahrzeug zieht).
TacoV = TacoV or {}
TacoV.Fitness = { training = false }

local F = TacoV.Config.Fitness
local N = TacoV.Config.Needs
local lastAt = {}

local function notify(kind, text) TacoV.UI.send('notify', { kind = kind, text = text }) end

TacoV.Prompt.register({ id = 'gym', label = 'Trainieren', order = 10,
  when = function()
    if TacoV.Fitness.training then return false end
    local loc = TacoV.Client.nearestLocation('gym', 2.0)
    return loc or false
  end,
  run = function(loc)
    local now = GetGameTimer()
    if lastAt[loc.name] and now - lastAt[loc.name] < F.cooldownSeconds * 1000 then
      notify('info', ('Kurz verschnaufen – %d s.'):format(math.ceil((F.cooldownSeconds * 1000 - (now - lastAt[loc.name])) / 1000)))
      return
    end
    TacoV.Fitness.training = true
    local ped = PlayerPedId()
    TaskStartScenarioInPlace(ped, loc.scenario or 'WORLD_HUMAN_PUSH_UPS', 0, true)
    TacoV.UI.send('hint', { key = 'E', text = ('%s · %d s'):format(loc.label, F.sessionSeconds) })
    CreateThread(function()
      local t0 = GetGameTimer()
      while GetGameTimer() - t0 < F.sessionSeconds * 1000 do
        Wait(250)
        local p = PlayerPedId()
        if IsPedWalking(p) or IsPedRunning(p) or IsPedInAnyVehicle(p, false) or GetEntityHealth(p) <= 100 then
          ClearPedTasks(p)
          TacoV.Fitness.training = false
          TacoV.UI.send('hint', nil)
          notify('warn', 'Training abgebrochen.')
          return
        end
      end
      ClearPedTasks(PlayerPedId())
      TacoV.Fitness.training = false
      lastAt[loc.name] = GetGameTimer()
      TacoV.UI.send('hint', nil)
      TriggerServerEvent('tacov:fitness:trained', loc.name)
    end)
  end })

-- Tempo-Bonus und Ausdauer nach Fitness
CreateThread(function()
  local applied = -1
  while true do
    Wait(2000)
    if TacoV.Client.character and TacoV.Hud.needs then
      local fit = TacoV.Hud.needs.fitness or 0
      local mult = 1.0 + (fit / 100) * (N.fitness.maxSpeedBonusPercent / 100)
      if math.abs(mult - applied) > 0.005 then
        SetRunSprintMultiplierForPlayer(PlayerId(), mult)
        applied = mult
      end
      if fit > 0 and IsPedSprinting(PlayerPedId()) then RestorePlayerStamina(PlayerId(), fit / 100 * 0.15) end
    end
  end
end)

-- Promille
local drunk = false
CreateThread(function()
  while true do
    Wait(1000)
    local alc = TacoV.Client.character and TacoV.Hud.needs and (TacoV.Hud.needs.alcohol or 0) or 0
    local ped = PlayerPedId()
    if alc >= N.alcohol.duiThreshold and not drunk then
      drunk = true
      RequestAnimSet('move_m@drunk@moderatedrunk')
      local t = GetGameTimer()
      while not HasAnimSetLoaded('move_m@drunk@moderatedrunk') and GetGameTimer() - t < 2000 do Wait(10) end
      SetPedMovementClipset(ped, 'move_m@drunk@moderatedrunk', 0.5)
      SetPedIsDrunk(ped, true)
      AnimpostfxPlay('DrugsMichaelAliensFight', 0, true)
      ShakeGameplayCam('DRUNK_SHAKE', 1.0)
      notify('warn', ('%.1f ‰ – du bist betrunken. Nicht fahren!'):format(alc))
    elseif alc < N.alcohol.duiThreshold and drunk then
      drunk = false
      ResetPedMovementClipset(ped, 0.5)
      SetPedIsDrunk(ped, false)
      AnimpostfxStop('DrugsMichaelAliensFight')
      StopGameplayCamShaking(true)
    end
    if drunk then
      local veh = GetVehiclePedIsIn(ped, false)
      if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped and GetEntitySpeed(veh) > 3.0 then
        local sway = (math.random() - 0.5) * math.min(1.0, alc) * 0.9
        SetVehicleSteerBias(veh, sway)
      end
    end
  end
end)

AddEventHandler('tacov:client:characterLoaded', function()
  SetTimeout(1000, function() SetRunSprintMultiplierForPlayer(PlayerId(), 1.0) end)
end)
