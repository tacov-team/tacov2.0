-- Handy (Phase 7, Client): F1 öffnet (nur mit Handy), Weiterleitung der App-Aktionen, Klingeln/SMS-Hinweise, Wegpunkte,
-- Funk über SaltyChat (Frequenz setzen, Funkliste im HUD live), Nummerntausch im X-Rad.
TacoV = TacoV or {}
TacoV.Phone = { open = false, ringing = false }

local function notify(kind, text) TacoV.UI.send('notify', { kind = kind, text = text }) end

function TacoV.Phone.toggle()
  if TacoV.UI.current() == 'phone' then TacoV.UI.close() TacoV.Phone.open = false return end
  if TacoV.UI.current() then return end
  TriggerServerEvent('tacov:phone:open')
end

RegisterNetEvent('tacov:phone:show', function(d)
  TacoV.Phone.open = true
  for _, a in ipairs(d.apps) do if a.id == 'messages' then a.badge = d.unread end end
  TacoV.UI.open('phone', { number = d.number, apps = d.apps, time = d.time }, true, 'walk')
  -- Handy-Animation
  local ped = PlayerPedId()
  RequestAnimDict('cellphone@')
  local t = GetGameTimer()
  while not HasAnimDictLoaded('cellphone@') and GetGameTimer() - t < 1000 do Wait(10) end
  TaskPlayAnim(ped, 'cellphone@', 'cellphone_text_in', 8.0, -8.0, -1, 50, 0.0, false, false, false)
end)

local function closePhone()
  TacoV.Phone.open = false
  local ped = PlayerPedId()
  StopAnimTask(ped, 'cellphone@', 'cellphone_text_in', 1.0)
  TacoV.UI.close()
end
AddEventHandler('tacov:ui:phone:close', function() closePhone() end)

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
RegisterNetEvent('tacov:phone:ring', function(on)
  TacoV.Phone.ringing = on
  if on then
    if not TacoV.Phone.open and not TacoV.UI.current() then TriggerServerEvent('tacov:phone:open') end
    CreateThread(function()
      while TacoV.Phone.ringing do
        PlaySoundFrontend(-1, 'Remote_Ring', 'Phone_SoundSet_Michael', true)
        Wait(2500)
      end
    end)
  end
end)

RegisterNetEvent('tacov:phone:sms', function(from, name, preview)
  PlaySoundFrontend(-1, 'Text_Arrive_Tone', 'Phone_SoundSet_Default', true)
  notify('info', ('SMS von %s: %s'):format(name or from, preview))
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
