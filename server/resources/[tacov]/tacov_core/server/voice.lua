-- Voice (Punkt 6.7, Server): Sprechweite autoritativ über SaltyChats Server-Export setzen. Der Client schaltet nicht selbst
-- (SaltyChats eigener Umschalter schreibt den Statebag vom Client aus und erzeugt ein Echo neu → alt → neu); der Server
-- liest die aktuelle Stufe, wählt die nächste aus Config.Voice.order und schreibt sie – ein Druck, ein Wert.
TacoV = TacoV or {}
local V = TacoV.Config.Voice

local function salty() return GetResourceState('saltychat') == 'started' end

RegisterNetEvent('tacov:voice:cycle', function()
  local src = source
  if not TacoV.Characters.get(src) or not salty() then return end
  local ok, current = pcall(function() return exports.saltychat:GetPlayerVoiceRange(src) end)
  current = ok and tonumber(current) or V.normal
  local idx = 2 -- Standard: normal
  for i, r in ipairs(V.order) do if math.abs((V[r] or 0) - current) < 0.6 then idx = i end end
  local nextRange = V[V.order[(idx % #V.order) + 1]] + 0.0
  print(('[voice] cycle %d: aktuell %s → Stufe %d/%d → %s (Reihenfolge %s)'):format(src, tostring(current), idx, #V.order, nextRange, table.concat(V.order, ',')))
  local okSet, err = pcall(function() exports.saltychat:SetPlayerVoiceRange(src, nextRange) end)
  if not okSet then
    print(('[voice] SetPlayerVoiceRange fehlgeschlagen: %s'):format(tostring(err)))
    TriggerClientEvent('tacov:core:notify', src, 'error', 'Sprechweite konnte nicht gesetzt werden.')
  end
end)

-- /voicetest (Client) fragt den Server: Export lesbar? Setzen möglich?
RegisterNetEvent('tacov:voice:test', function()
  local src = source
  local okG, cur = pcall(function() return exports.saltychat:GetPlayerVoiceRange(src) end)
  local okS, err = pcall(function() exports.saltychat:SetPlayerVoiceRange(src, (okG and tonumber(cur) or 10.0) + 0.0) end)
  local bag = Player(src).state.SaltyChat_VoiceRange
  local text = ('[voice] Server: Resource=%s Get=%s Set=%s Statebag=%s (%s)'):format(GetResourceState('saltychat'),
    okG and tostring(cur) or ('Fehler ' .. tostring(cur)), okS and 'ok' or ('Fehler ' .. tostring(err)), tostring(bag), type(bag))
  print(text)
  TriggerClientEvent('tacov:voice:testResult', src, text)
end)
