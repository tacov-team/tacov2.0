-- Welt-Steuerung (5.12): Uhrzeit und Wetter serverseitig, Ansagen; Team ab Administrator (`admin.world`).
TacoV = TacoV or {}
TacoV.World = {}

local W = TacoV.Config.World
local state = { hour = W.startHour, minute = 0, timeFrozen = false, weather = 'CLEAR', weatherFrozen = false }
local secondsPerGameMinute = W.dayMinutes * 60 / 1440
local acc = 0

local function notify(src, kind, text) TriggerClientEvent('tacov:core:notify', src, kind, text) end
local function need(src, right)
  if TacoV.Permissions.has(src, right) then return true end
  notify(src, 'error', 'Dafür fehlt dir das Recht (oder du bist nicht im Admin-Dienst).')
  return false
end
local function log(src, text)
  local p = TacoV.Players.get(src)
  TacoV.Log.write('admin', text, { discordId = p and p.discordId })
end

function TacoV.World.sync(target)
  TriggerClientEvent('tacov:world:sync', target or -1, state)
end
function TacoV.World.get() return state end

local function pickWeather()
  local total = 0
  for _, w in ipairs(W.weights) do total = total + w end
  local r, sum = math.random() * total, 0
  for i, w in ipairs(W.weights) do
    sum = sum + w
    if r <= sum then return W.weathers[i] end
  end
  return 'CLEAR'
end

AddEventHandler('tacov:core:ready', function()
  CreateThread(function()
    local lastWeather = os.time()
    while true do
      Wait(1000)
      if not state.timeFrozen then
        acc = acc + 1
        while acc >= secondsPerGameMinute do
          acc = acc - secondsPerGameMinute
          state.minute = state.minute + 1
          if state.minute >= 60 then state.minute = 0 state.hour = (state.hour + 1) % 24 end
        end
      end
      if not state.weatherFrozen and os.time() - lastWeather >= W.weatherMinutes * 60 then
        lastWeather = os.time()
        local nw = pickWeather()
        if nw ~= state.weather then state.weather = nw TacoV.World.sync(-1) end
      end
    end
  end)
  CreateThread(function() while true do Wait(10000) TacoV.World.sync(-1) end end)
end)
AddEventHandler('tacov:core:characterSelected', function(source) TacoV.World.sync(source) end)

RegisterNetEvent('tacov:world:set', function(what, a, b)
  local src = source
  if what == 'announce' or what == 'restart' then
    if not need(src, what == 'announce' and 'admin.world' or 'admin.config') then return end
  elseif not need(src, 'admin.world') then return end
  if what == 'time' then
    state.hour, state.minute = math.max(0, math.min(23, math.floor(tonumber(a) or 12))), math.max(0, math.min(59, math.floor(tonumber(b) or 0)))
    acc = 0
    log(src, ('Uhrzeit gesetzt: %02d:%02d'):format(state.hour, state.minute))
  elseif what == 'timeFreeze' then
    state.timeFrozen = a == true
    log(src, 'Uhrzeit ' .. (state.timeFrozen and 'eingefroren' or 'läuft wieder'))
  elseif what == 'weather' then
    local w = tostring(a or ''):upper()
    if not W.labels[w] then notify(src, 'error', 'Unbekanntes Wetter.') return end
    state.weather = w
    log(src, 'Wetter gesetzt: ' .. w)
  elseif what == 'snow' then
    if a == true then state.weather = 'XMAS' state.weatherFrozen = true else state.weather = 'CLEAR' state.weatherFrozen = false end
    log(src, a == true and 'Schnee eingeschaltet (XMAS, eingefroren)' or 'Schnee beendet')
  elseif what == 'weatherFreeze' then
    state.weatherFrozen = a == true
    log(src, 'Wetter ' .. (state.weatherFrozen and 'eingefroren' or 'wechselt wieder'))
  elseif what == 'announce' then
    local text = TacoV.Util.cleanText(tostring(a or ''), 300)
    if #text < 2 then return end
    TriggerClientEvent('tacov:core:announce', -1, { title = 'Ansage', text = text, kind = 'info', seconds = 12 })
    TacoV.DB.insert('INSERT INTO announcements (kind, text) VALUES (?, ?)', { 'info', text })
    log(src, 'Ansage: ' .. text)
    return
  elseif what == 'restart' then
    ExecuteCommand(('neustart %d'):format(math.max(1, math.min(60, math.floor(tonumber(a) or 5)))))
    log(src, ('Neustart angekündigt (%s min)'):format(tostring(a)))
    return
  else
    return
  end
  TacoV.World.sync(-1)
end)
