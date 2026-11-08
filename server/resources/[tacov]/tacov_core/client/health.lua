-- Verletzungen (Client, 6.8): Stufen leicht/mittel/bewusstlos, Humpeln, Bewusstlos-Zustand mit Timer, Koma → Krankenhaus.
TacoV = TacoV or {}
TacoV.Health = { state = 'ok', downedUntil = nil }

local H = TacoV.Config.Health
local function notify(kind, text) TacoV.UI.send('notify', { kind = kind, text = text }) end

local limping = false
local function setLimp(on)
  if on == limping then return end
  limping = on
  local ped = PlayerPedId()
  if on then
    RequestAnimSet('move_m@injured')
    local t = GetGameTimer()
    while not HasAnimSetLoaded('move_m@injured') and GetGameTimer() - t < 2000 do Wait(10) end
    SetPedMovementClipset(ped, 'move_m@injured', 0.5)
  else
    ResetPedMovementClipset(ped, 0.5)
  end
end

-- ---------------------------------------------------------------- Bewusstlos

local function layDown(ped)
  RequestAnimDict('dead')
  local t = GetGameTimer()
  while not HasAnimDictLoaded('dead') and GetGameTimer() - t < 2000 do Wait(10) end
  TaskPlayAnim(ped, 'dead', 'dead_a', 8.0, -8.0, -1, 1, 0.0, false, false, false)
end

local function becomeDowned()
  local ped = PlayerPedId()
  local pos, h = GetEntityCoords(ped), GetEntityHeading(ped)
  NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, h, true, false)
  ped = PlayerPedId()
  SetEntityHealth(ped, 110)
  SetEntityInvincible(ped, true)
  ClearPedTasksImmediately(ped)
  layDown(ped)
  TacoV.Health.state = 'downed'
  TacoV.Health.downedUntil = GetGameTimer() + H.downedMinutes * 60000
  TriggerServerEvent('tacov:health:downed')
  local text = ('Du bist schwer verletzt. Warte auf Hilfe (LSMD oder Erste-Hilfe-Kit) – nach %d Minuten fällst du ins Koma.'):format(H.downedMinutes)
  TacoV.UI.send('announce', { title = 'Bewusstlos', text = text, kind = 'warn', seconds = 10 })
end

function TacoV.Health.revive(full)
  local ped = PlayerPedId()
  ClearPedTasksImmediately(ped)
  SetEntityInvincible(ped, false)
  SetEntityHealth(ped, full and GetEntityMaxHealth(ped) or 130)
  ClearPedBloodDamage(ped)
  TacoV.Health.state = 'ok'
  TacoV.Health.downedUntil = nil
  TacoV.UI.send('hud', { downed = false })
end

local function coma()
  TacoV.UI.send('hud', { downed = false })
  DoScreenFadeOut(800)
  Wait(900)
  TriggerServerEvent('tacov:health:coma')
  local b = H.respawnBed
  NetworkResurrectLocalPlayer(b.x, b.y, b.z, b.w, true, false)
  local ped = PlayerPedId()
  SetEntityHealth(ped, GetEntityMaxHealth(ped))
  ClearPedBloodDamage(ped)
  SetEntityInvincible(ped, false)
  TacoV.Health.state = 'hospital'
  TacoV.Health.downedUntil = GetGameTimer() + H.hospitalMinutes * 60000
  Wait(500)
  DoScreenFadeIn(1000)
  TacoV.UI.send('announce', { title = 'Krankenhaus', text = ('Du wachst im Pillbox Hill auf. %d Minuten Ruhe, dann kannst du gehen.'):format(H.hospitalMinutes), kind = 'info', seconds = 10 })
  RequestAnimDict('dead')
  layDown(ped)
end

-- Hauptschleife: Stufen, Tod abfangen, Bewusstlos-Steuerung
CreateThread(function()
  while true do
    Wait(250)
    if TacoV.Client.character then
      local ped = PlayerPedId()
      local hp = GetEntityHealth(ped)
      if TacoV.Health.state == 'ok' then
        if IsEntityDead(ped) or hp <= 100 then
          becomeDowned()
        else
          setLimp(hp < H.medium)
          local st = hp < H.medium and 'medium' or (hp < H.light and 'light' or 'ok')
          if st ~= (TacoV.Health.sub or 'ok') then
            TacoV.Health.sub = st
            TacoV.UI.send('hud', { injury = st ~= 'ok' and st or false })
            if st == 'medium' then notify('warn', 'Du bist verletzt – du humpelst. Erste-Hilfe-Kit oder LSMD.') end
          end
        end
      elseif TacoV.Health.state == 'downed' then
        local left = math.max(0, math.floor((TacoV.Health.downedUntil - GetGameTimer()) / 1000))
        TacoV.UI.send('hud', { downed = left })
        if not IsEntityPlayingAnim(ped, 'dead', 'dead_a', 3) then layDown(ped) end
        if left <= 0 then coma() end
      elseif TacoV.Health.state == 'hospital' then
        if GetGameTimer() >= TacoV.Health.downedUntil then TacoV.Health.revive(true) notify('success', 'Du bist entlassen.') end
      end
    end
  end
end)

-- Eingaben sperren, solange bewusstlos / im Krankenhausbett
CreateThread(function()
  while true do
    if TacoV.Health.state ~= 'ok' then
      Wait(0)
      DisableAllControlActions(0)
      EnableControlAction(0, 1, true) EnableControlAction(0, 2, true) -- Kamera
      EnableControlAction(0, 249, true) -- Sprechen
      EnableControlAction(0, 245, true) -- T (Befehlszeile für /support)
      EnableControlAction(0, 200, true)
    else
      Wait(500)
    end
  end
end)

-- Erste Hilfe am eigenen Körper (Server löst nach Item-Verbrauch aus)
RegisterNetEvent('tacov:health:heal', function(amount, stabilize)
  local ped = PlayerPedId()
  if TacoV.Health.state == 'downed' then
    if stabilize then
      TacoV.Health.downedUntil = TacoV.Health.downedUntil + H.stabilizeMinutes * 60000
      notify('info', ('Stabilisiert – %d Minuten mehr Zeit für Hilfe.'):format(H.stabilizeMinutes))
    end
    return
  end
  SetEntityHealth(ped, math.min(GetEntityMaxHealth(ped), GetEntityHealth(ped) + amount))
  if GetEntityHealth(ped) >= H.medium then ClearPedBloodDamage(ped) end
  notify('success', ('Versorgt (+%d).'):format(amount))
end)

-- Wiederbelebung durch Team (Heilen) oder später LSMD
RegisterNetEvent('tacov:health:revive', function() TacoV.Health.revive(true) notify('success', 'Du bist wieder bei Bewusstsein.') end)
AddEventHandler('tacov:admin:healedLocal', function() if TacoV.Health.state ~= 'ok' then TacoV.Health.revive(true) end end)

-- Bewusstlosen helfen (X-Rad kommt mit LSMD; hier: E am Bewusstlosen mit Kit)
TacoV.Prompt.register({ id = 'help_downed', label = 'Erste Hilfe leisten', order = 6,
  when = function()
    if TacoV.Health.state ~= 'ok' then return false end
    local me = GetEntityCoords(PlayerPedId())
    for _, pl in ipairs(GetActivePlayers()) do
      if pl ~= PlayerId() then
        local sid = GetPlayerServerId(pl)
        if Player(sid).state.downed and #(GetEntityCoords(GetPlayerPed(pl)) - me) < 2.0 then return sid end
      end
    end
    return false
  end,
  run = function(sid) TriggerServerEvent('tacov:health:helpDowned', sid) end })
