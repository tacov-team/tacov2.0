-- Welt (Client, 5.12): übernimmt Uhrzeit und Wetter vom Server, zeigt Ansagen, Team-Menü „Welt“.
TacoV = TacoV or {}
TacoV.World = { state = nil }

local W = TacoV.Config.World
local currentWeather = nil

local snowOn = false
local function setSnow(on)
  if on == snowOn then return end
  snowOn = on
  ForceSnowPass(on)
  SetForceVehicleTrails(on)
  SetForcePedFootstepsTracks(on)
  UseSnowFootVfxWhenUnsheltered(on)
  UseSnowWheelVfxWhenUnsheltered(on)
end

RegisterNetEvent('tacov:world:sync', function(s)
  TacoV.World.state = s
  NetworkOverrideClockTime(s.hour, s.minute, 0)
  if s.weather ~= currentWeather then
    if currentWeather then SetWeatherTypeOvertimePersist(s.weather, 20.0) else SetWeatherTypeNowPersist(s.weather) end
    currentWeather = s.weather
  end
  setSnow(W.snowWeathers[s.weather] == true)
end)

CreateThread(function()
  while true do
    Wait(0)
    local s = TacoV.World.state
    if s then
      NetworkOverrideClockTime(s.hour, s.minute, 0)
    else
      Wait(500)
    end
  end
end)

RegisterNetEvent('tacov:core:announce', function(d) TacoV.UI.send('announce', d) end)

-- Team-Menü → Welt
function TacoV.World.openMenu()
  local s = TacoV.World.state or { hour = 12, minute = 0, weather = 'CLEAR' }
  TacoV.Menu.open({ id = 'world', title = 'Welt', icon = 'clock', info = ('%02d:%02d · %s'):format(s.hour, s.minute, W.labels[s.weather] or s.weather), items = {
    { id = 'time', label = 'Uhrzeit setzen', icon = 'clock', sub = 'Stunde:Minute', section = 'Zeit' },
    { id = 'timeFreeze', label = s.timeFrozen and 'Uhrzeit weiterlaufen lassen' or 'Uhrzeit einfrieren', icon = 'lock' },
    { id = 'weather', label = 'Wetter setzen', icon = 'drop', sub = W.labels[s.weather] or s.weather, section = 'Wetter' },
    { id = 'weatherFreeze', label = s.weatherFrozen and 'Wetterwechsel wieder erlauben' or 'Wetter einfrieren', icon = 'lock' },
    { id = 'snow', label = W.snowWeathers[s.weather] and 'Schnee beenden' or 'Schnee (Winter) einschalten', icon = 'drop', sub = 'Schneedecke, Spuren, eingefroren' },
    { id = 'announce', label = 'Ansage an alle', icon = 'mic', sub = 'Banner oben für alle Spieler', section = 'Ansagen' },
    { id = 'restart', label = 'Neustart ankündigen', icon = 'warn', sub = 'Minuten eingeben (Manager)' },
  } }, function(id)
    if id == 'time' then
      TacoV.UI.ask({ title = 'Uhrzeit (z. B. 21:30)', value = ('%02d:%02d'):format(s.hour, s.minute), maxLength = 5, icon = 'clock' }, function(v)
        local h, m = tostring(v or ''):match('^(%d%d?):?(%d?%d?)$')
        if h then TriggerServerEvent('tacov:world:set', 'time', tonumber(h), tonumber(m) or 0) end
      end)
    elseif id == 'timeFreeze' then TriggerServerEvent('tacov:world:set', 'timeFreeze', not s.timeFrozen) TacoV.Menu.close()
    elseif id == 'weather' then
      local items = {}
      local names = {}
      for k in pairs(W.labels) do names[#names + 1] = k end
      table.sort(names)
      for _, k in ipairs(names) do items[#items + 1] = { id = k, label = W.labels[k], icon = 'drop', sub = k } end
      TacoV.Menu.open({ id = 'world_weather', title = 'Wetter', icon = 'drop', items = items }, function(w)
        TriggerServerEvent('tacov:world:set', 'weather', w) TacoV.Menu.close()
      end)
    elseif id == 'snow' then
      TriggerServerEvent('tacov:world:set', 'snow', not W.snowWeathers[s.weather]) TacoV.Menu.close()
    elseif id == 'weatherFreeze' then TriggerServerEvent('tacov:world:set', 'weatherFreeze', not s.weatherFrozen) TacoV.Menu.close()
    elseif id == 'announce' then
      TacoV.UI.ask({ title = 'Ansage an alle Spieler', maxLength = 300, icon = 'mic' }, function(v)
        if v and #v > 1 then TriggerServerEvent('tacov:world:set', 'announce', v) end
      end)
    elseif id == 'restart' then
      TacoV.UI.ask({ title = 'Neustart in Minuten', value = '5', maxLength = 2, numeric = true, icon = 'warn' }, function(v)
        local n = tonumber(v or '')
        if n then TriggerServerEvent('tacov:world:set', 'restart', n) end
      end)
    end
  end)
end
