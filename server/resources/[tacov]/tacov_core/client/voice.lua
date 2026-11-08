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

--- Z: Sprechweite weiterschalten. Mit SaltyChat über dessen eigenen Umschalter (+voiceRange); der Statebag
--- SaltyChat_VoiceRange wird nie direkt aus Lua gesetzt (falscher Zahlentyp bricht die Sprach-Synchronisation).
--- Entprellt: ein Druck = ein Schritt, auch wenn die Taste doppelt gemeldet wird.
local lastCycle = 0
function TacoV.Voice.cycle()
  local now = GetGameTimer()
  if now - lastCycle < 300 then return end
  lastCycle = now
  if salty() then
    ExecuteCommand('+voiceRange')
    return
  end
  local idx = 1
  for i, r in ipairs(V.order) do if r == TacoV.Voice.range then idx = i end end
  TacoV.Voice.range = V.order[(idx % #V.order) + 1]
  apply()
  TacoV.UI.send('notify', { kind = 'info', text = ('Sprechweite: %s (%d m)'):format(labels[TacoV.Voice.range], V[TacoV.Voice.range]) })
end

-- SaltyChat meldet jede Änderung (Meter, Index, Anzahl)
local lastShown, lastShownAt = nil, 0
AddEventHandler('SaltyChat_VoiceRangeChanged', function(meters)
  meters = tonumber(meters) or V.normal
  if lastShown == meters and GetGameTimer() - lastShownAt < 300 then return end
  lastShown, lastShownAt = meters, GetGameTimer()
  show(meters)
  TacoV.UI.send('notify', { kind = 'info', text = ('Sprechweite: %s (%d m)'):format(labels[TacoV.Voice.range], math.floor(meters + 0.5)) })
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
