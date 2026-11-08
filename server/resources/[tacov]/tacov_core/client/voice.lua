-- Sprechweite (Konzept 5.5): 3 / 10 / 25 m, Umschalten per Taste, Anzeige im HUD. Die eigentliche Stimme läuft über
-- SaltyChat (Punkt 6.7); solange die Resource läuft, bekommt sie die Reichweite gemeldet.
TacoV = TacoV or {}
TacoV.Voice = { range = 'normal' }

local V = TacoV.Config.Voice

local function apply()
  local meters = V[TacoV.Voice.range] or V.normal
  TacoV.UI.send('hud', { voice = TacoV.Voice.range, voiceMeters = meters })
  if GetResourceState('saltychat') == 'started' then
    pcall(function() exports.saltychat:SetVoiceRange(meters + 0.0) end)
  end
end

function TacoV.Voice.cycle()
  local idx = 1
  for i, r in ipairs(V.order) do if r == TacoV.Voice.range then idx = i end end
  TacoV.Voice.range = V.order[(idx % #V.order) + 1]
  apply()
  local labels = { whisper = 'Flüstern', normal = 'Normal', shout = 'Rufen' }
  TacoV.UI.send('notify', { kind = 'info', text = ('Sprechweite: %s (%d m)'):format(labels[TacoV.Voice.range], V[TacoV.Voice.range]) })
end

RegisterCommand('tacov_voice', function() if TacoV.Client.character then TacoV.Voice.cycle() end end, false)
RegisterKeyMapping('tacov_voice', 'TacoV: Sprechweite', 'keyboard', V.key or 'Z')

AddEventHandler('tacov:core:characterLoaded', function() apply() end)
