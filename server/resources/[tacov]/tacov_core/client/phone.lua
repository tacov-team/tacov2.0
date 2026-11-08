-- Handy (Phase 7, Client): F1 öffnet (nur mit Handy), Weiterleitung der App-Aktionen, Klingeln/SMS-Hinweise, Wegpunkte,
-- Funk über SaltyChat (Frequenz setzen, Funkliste im HUD live), Nummerntausch im X-Rad.
TacoV = TacoV or {}
TacoV.Phone = { open = false, ringing = false }

local function notify(kind, text) TacoV.UI.send('notify', { kind = kind, text = text }) end

local function stopAnim()
  local ped = PlayerPedId()
  if IsEntityPlayingAnim(ped, 'cellphone@', 'cellphone_text_in', 3) then StopAnimTask(ped, 'cellphone@', 'cellphone_text_in', 1.0) end
end

local function closePhone()
  TacoV.Phone.open = false
  stopAnim()
  if TacoV.UI.current() == 'phone' then TacoV.UI.close() end
end

function TacoV.Phone.toggle()
  if TacoV.UI.current() == 'phone' then closePhone() return end
  if TacoV.UI.current() then return end
  TriggerServerEvent('tacov:phone:open')
end

--- Alt: Mauszeiger ein/aus. Ohne Zeiger läuft das Spiel normal weiter (laufen, F1 weglegen, auch im Gespräch).
function TacoV.Phone.toggleCursor()
  if TacoV.UI.current() ~= 'phone' then return end
  local on = not TacoV.UI.hasCursor()
  TacoV.UI.setCursor(on)
  TacoV.UI.send('phone', { app = 'cursor', data = on })
end

RegisterNetEvent('tacov:phone:show', function(d)
  TacoV.Phone.open = true
  for _, a in ipairs(d.apps) do if a.id == 'messages' then a.badge = d.unread end end
  TacoV.UI.open('phone', { number = d.number, apps = d.apps, time = d.time, cursor = false }, false, 'free')
  -- Handy-Animation
  local ped = PlayerPedId()
  RequestAnimDict('cellphone@')
  local t = GetGameTimer()
  while not HasAnimDictLoaded('cellphone@') and GetGameTimer() - t < 1000 do Wait(10) end
  TaskPlayAnim(ped, 'cellphone@', 'cellphone_text_in', 8.0, -8.0, -1, 50, 0.0, false, false, false)
end)

AddEventHandler('tacov:ui:phone:close', function() closePhone() end)

-- Sicherheitsnetz: Handy-Animation nie ohne offenes Handy (z. B. nach Ansichtswechsel oder Tod)
CreateThread(function()
  while true do
    Wait(1000)
    if TacoV.UI.current() ~= 'phone' then
      if TacoV.Phone.open then TacoV.Phone.open = false end
      stopAnim()
    end
  end
end)

-- Alle App-Aktionen zum Server: 'contacts:add' → tacov:phone:contacts:add
for _, name in ipairs({ 'contacts:list', 'contacts:add', 'contacts:rename', 'contacts:favorite', 'contacts:delete', 'calls:start', 'calls:accept', 'calls:end',
  'messages:list', 'messages:thread', 'messages:send', 'messages:location', 'bank:load', 'bank:transfer', 'bank:invoice', 'bank:pay',
  'vehicles:list', 'vehicles:locate', 'vehicles:share', 'radio:load', 'radio:join', 'radio:leave', 'settings:set' }) do
  AddEventHandler('tacov:ui:phone:' .. name, function(d) TriggerServerEvent('tacov:phone:' .. name, d) end)
end
AddEventHandler('tacov:ui:phone:messages:waypoint', function(d) SetNewWaypoint(d.x + 0.0, d.y + 0.0) notify('info', 'Wegpunkt gesetzt.') end)
AddEventHandler('tacov:ui:phone:settings:ringtone', function() end)

RegisterNetEvent('tacov:phone:app', function(app, data, extra)
  TacoV.UI.send('phone', { app = app, data = data, thread = extra })
end)

RegisterNetEvent('tacov:phone:waypoint', function(x, y) SetNewWaypoint(x + 0.0, y + 0.0) end)

-- Klingeln: Ton + Hinweis; Handy öffnet sich mit dem Anruf
-- Klingeln: 'Remote_Ring' ist ein Dauerton – mit eigener Sound-ID starten und beim Beenden ausdrücklich stoppen
local ringId = nil
local function stopRing()
  TacoV.Phone.ringing = false
  if ringId then StopSound(ringId) ReleaseSoundId(ringId) ringId = nil end
end
RegisterNetEvent('tacov:phone:ring', function(on)
  if not on then stopRing() return end
  if ringId then return end
  TacoV.Phone.ringing = true
  ringId = GetSoundId()
  PlaySoundFrontend(ringId, 'Remote_Ring', 'Phone_SoundSet_Michael', true)
  if not TacoV.Phone.open and not TacoV.UI.current() then TriggerServerEvent('tacov:phone:open') end
  -- Sicherheitsnetz: spätestens nach der Klingeldauer verstummen, auch wenn das Stopp-Signal verloren geht
  local my = ringId
  SetTimeout((TacoV.Config.Phone.ringSeconds + 2) * 1000, function() if ringId == my then stopRing() end end)
end)
-- Anruf angenommen/beendet: Ton sicher aus
RegisterNetEvent('tacov:phone:app', function(app, data)
  if app == 'call' and (data == false or (type(data) == 'table' and data.state == 'active')) then stopRing() end
end)

RegisterNetEvent('tacov:phone:sms', function(from, name, preview)
  PlaySoundFrontend(-1, 'Text_Arrive_Tone', 'Phone_SoundSet_Default', true)
  notify('info', ('SMS von %s: %s'):format(name or from, preview))
  if TacoV.UI.current() == 'phone' then TacoV.UI.send('phone', { app = 'sms', data = { from = from } }) end
end)

-- Funk: Frequenz an SaltyChat, Funkliste im HUD
local function salty() return GetResourceState('saltychat') == 'started' end
RegisterNetEvent('tacov:radio:set', function(channel)
  if salty() then
    pcall(function() exports.saltychat:SetRadioChannel(channel and tostring(channel) or '', true) end)
  end
  TacoV.UI.send('hud', { radioOn = channel ~= nil, radioFrequency = channel and tostring(channel) or nil, radio = channel and {} or nil })
  notify('info', channel and ('Funk: Frequenz %d.'):format(channel) or 'Funk aus.')
end)
RegisterNetEvent('tacov:radio:state', function(d)
  local list = {}
  for i, name in ipairs(d.members or {}) do
    local talking = false
    for _, t in ipairs(d.talking or {}) do if t == name then talking = true end end
    list[#list + 1] = { id = i, name = name, talking = talking }
  end
  TacoV.UI.send('hud', { radio = d.channel and list or nil, radioFrequency = d.channel and tostring(d.channel) or nil, radioOn = d.channel ~= nil })
end)
-- SaltyChat meldet, wenn jemand auf dem Funk sendet
AddEventHandler('SaltyChat_RadioTrafficStateChanged', function(_, isSending)
  TriggerServerEvent('tacov:radio:talking', isSending == true)
end)

-- X-Rad: Nummern tauschen
TacoV.Interact.register({
  id = 'phone_exchange', label = 'Nummer tauschen', icon = 'phone', order = 30,
  when = function(ctx) return ctx.player ~= nil end,
  run = function(ctx) TriggerServerEvent('tacov:phone:exchange', ctx.player) end,
})
