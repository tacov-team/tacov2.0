-- Voice (Konzept 5.5, Punkt 6.7): Sprechweiten 3 / 10 / 25 m per Z mit HUD-Anzeige, Megafon in Einsatzfahrzeugen (Halten),
-- Anbindung an SaltyChat: Sprechweite über dessen Befehl +voiceRange und Ereignis SaltyChat_VoiceRangeChanged, Megafon über
-- den Statebag SaltyChat_IsUsingMegaphone (bool). Ohne SaltyChat läuft die Anzeige trotzdem.
TacoV = TacoV or {}
TacoV.Voice = { range = 'normal', megaphone = false }

local V = TacoV.Config.Voice
local labels = { whisper = 'Flüstern', normal = 'Normal', shout = 'Rufen' }

local function salty() return GetResourceState('saltychat') == 'started' end

-- Anzeige im HUD aus der tatsächlichen Sprechweite (Meter) ableiten
local function show(meters)
  local best = 'normal'
  for _, r in ipairs(V.order) do if math.abs((V[r] or 0) - meters) < 0.6 then best = r end end
  TacoV.Voice.range = best
  TacoV.UI.send('hud', { voice = best, voiceMeters = math.floor(meters + 0.5) })
end

local function apply()
  if salty() then
    local ok, m = pcall(function() return exports.saltychat:GetVoiceRange() end)
    show(ok and tonumber(m) or V.normal)
  else
    TacoV.UI.send('hud', { voice = TacoV.Voice.range, voiceMeters = V[TacoV.Voice.range] or V.normal })
  end
end

--- Z: Sprechweite weiterschalten. Mit SaltyChat setzt der Server die Stufe (Export SetPlayerVoiceRange) – der Statebag
--- SaltyChat_VoiceRange wird nie vom Client geschrieben (Zahlentyp/Echo-Probleme). Entprellt: ein Druck = ein Schritt.
local lastCycle = 0
function TacoV.Voice.cycle()
  local now = GetGameTimer()
  if now - lastCycle < 300 then return end
  lastCycle = now
  if salty() then
    TriggerServerEvent('tacov:voice:cycle')
    return
  end
  local idx = 1
  for i, r in ipairs(V.order) do if r == TacoV.Voice.range then idx = i end end
  TacoV.Voice.range = V.order[(idx % #V.order) + 1]
  apply()
  TacoV.UI.send('notify', { kind = 'info', text = ('Sprechweite: %s (%d m)'):format(labels[TacoV.Voice.range], V[TacoV.Voice.range]) })
end

-- SaltyChat meldet jede Änderung (Meter, Index, Anzahl); kurz stabil abwarten, dann anzeigen.
local settleId = 0
AddEventHandler('SaltyChat_VoiceRangeChanged', function(meters)
  meters = tonumber(meters) or V.normal
  settleId = settleId + 1
  local my = settleId
  SetTimeout(150, function()
    if my ~= settleId then return end
    show(meters)
    TacoV.UI.send('notify', { kind = 'info', text = ('Sprechweite: %s (%d m)'):format(labels[TacoV.Voice.range], math.floor(meters + 0.5)) })
  end)
end)

--- Megafon: nur in Einsatzfahrzeugen (Klasse 18) als Fahrer oder Beifahrer, solange die Taste gehalten wird
local function canMegaphone()
  local ped = PlayerPedId()
  local veh = GetVehiclePedIsIn(ped, false)
  if veh == 0 or GetVehicleClass(veh) ~= 18 then return false end
  local seat = GetPedInVehicleSeat(veh, -1) == ped or GetPedInVehicleSeat(veh, 0) == ped
  return seat
end

function TacoV.Voice.setMegaphone(on)
  if on and not canMegaphone() then return end -- still: Alt ist außerhalb des Einsatzfahrzeugs ohne Wirkung
  if TacoV.Voice.megaphone == on then return end
  TacoV.Voice.megaphone = on
  if salty() then pcall(function() LocalPlayer.state:set('SaltyChat_IsUsingMegaphone', on, true) end) end
  TacoV.UI.send('hud', { megaphone = on })
end

RegisterCommand('+tacov_voice', function() if TacoV.Client.character then TacoV.Voice.cycle() end end, false)
RegisterCommand('-tacov_voice', function() end, false) -- Loslassen: nichts (sonst doppelt)
RegisterKeyMapping('+tacov_voice', 'TacoV: Sprechweite', 'keyboard', V.key or 'Z')
-- Alt: bei offenem Handy Mauszeiger ein/aus, sonst Megafon (halten)
RegisterCommand('+tacov_megaphone', function()
  if not TacoV.Client.character then return end
  if TacoV.UI.current() == 'phone' then TacoV.Phone.toggleCursor() return end
  TacoV.Voice.setMegaphone(true)
end, false)
RegisterCommand('-tacov_megaphone', function() TacoV.Voice.setMegaphone(false) end, false)
RegisterKeyMapping('+tacov_megaphone', 'TacoV: Megafon (halten) / Handy-Zeiger', 'keyboard', V.megaphoneKey or 'LMENU')

AddEventHandler('tacov:core:characterLoaded', function() apply() end)
CreateThread(function()
  while true do
    Wait(1000)
    if TacoV.Voice.megaphone and not canMegaphone() then TacoV.Voice.setMegaphone(false) end
  end
end)

-- /voicetest: Diagnose (F8 + Hinweis) – Zustand von SaltyChat auf Client und Server
RegisterCommand('voicetest', function()
  local state = GetResourceState('saltychat')
  local okR, range = pcall(function() return exports.saltychat:GetVoiceRange() end)
  local okP, plugin = pcall(function() return exports.saltychat:GetPluginState() end)
  local bag = LocalPlayer.state.SaltyChat_VoiceRange
  local line = ('[voice] Client: Resource=%s Range=%s Plugin=%s Statebag=%s (%s)'):format(state, okR and tostring(range) or 'Fehler',
    okP and tostring(plugin) or 'Fehler', tostring(bag), type(bag))
  print(line)
  TacoV.UI.send('notify', { kind = 'info', text = line })
  TriggerServerEvent('tacov:voice:test')
end, false)
RegisterNetEvent('tacov:voice:testResult', function(text)
  print(text)
  TacoV.UI.send('notify', { kind = 'info', text = text })
end)
