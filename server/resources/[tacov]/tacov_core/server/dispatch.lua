-- Dispatch und Notrufe (Punkt 9.5, Server): Notruf-App (110 Polizei, 112 Rettungsdienst), automatische Meldungen
-- (Schüsse, Blitzer), Einsatzliste für Diensthabende (übernehmen, abschließen), Einheiten-Status.
TacoV = TacoV or {}
TacoV.Dispatch = {}

local D = TacoV.Config.Dispatch
local calls = {}        -- [id] = { id, kind, faction, text, x, y, caller, callerName, number, at, takenBy, takenName }
local nextId = 1
local lastCall = {}     -- [src] = os.time()
local lastShot = {}

local function notify(src, kind, text) TriggerClientEvent('tacov:core:notify', src, kind, text) end
local function fullName(c) return c.first_name .. ' ' .. c.last_name end

local function public(call)
  return { id = call.id, kind = call.kind, text = call.text, x = call.x, y = call.y, callerName = call.callerName, number = call.number,
    age = os.time() - call.at, takenName = call.takenName }
end

--- Neuen Einsatz anlegen und an alle Diensthabenden der Fraktion schicken
function TacoV.Dispatch.create(faction, kind, text, x, y, caller)
  local c = caller and TacoV.Characters.get(caller)
  local call = { id = nextId, kind = kind, faction = faction, text = text, x = x, y = y, caller = caller,
    callerName = c and fullName(c) or nil, number = c and TacoV.Phone and TacoV.Phone.numberOf and TacoV.Phone.numberOf(caller) or nil, at = os.time() }
  calls[nextId] = call
  nextId = nextId + 1
  local units = TacoV.Factions.dutyList(faction)
  for _, s in ipairs(units) do TriggerClientEvent('tacov:dispatch:new', s, public(call)) end
  return call, #units
end

-- Notruf aus der Handy-App
RegisterNetEvent('tacov:phone:emergency:call', function(d)
  local src = source
  local c = TacoV.Characters.get(src)
  if not c or type(d) ~= 'table' then return end
  local def = D.numbers[tostring(d.number)]
  if not def then return end
  local now = os.time()
  if lastCall[src] and now - lastCall[src] < D.callCooldown then notify(src, 'error', 'Du hast gerade erst einen Notruf abgesetzt.') return end
  lastCall[src] = now
  local text = TacoV.Util.cleanText(d.text or '', 200)
  if text == '' then text = 'Kein Text – Anrufer braucht Hilfe.' end
  local pos = GetEntityCoords(GetPlayerPed(src))
  local _, units = TacoV.Dispatch.create(def.faction, tostring(d.number), text, pos.x, pos.y, src)
  notify(src, 'success', units > 0 and ('Notruf an %s abgesetzt – %d Einheit(en) im Dienst.'):format(def.label, units)
    or ('Notruf abgesetzt, aber bei %s ist gerade niemand im Dienst.'):format(def.label))
  TacoV.Log.write(def.faction == 'lspd' and 'police' or 'medic', ('Notruf %s von %s: %s'):format(d.number, fullName(c), text), { characterId = c.id })
end)

-- Schussmeldung vom Client (Ort unscharf)
RegisterNetEvent('tacov:dispatch:shots', function()
  local src = source
  if not D.shots.enabled or not TacoV.Characters.get(src) then return end
  local c = TacoV.Characters.get(src)
  if c.faction == 'lspd' and TacoV.Factions.isOnDuty(src) then return end
  local now = os.time()
  if lastShot[src] and now - lastShot[src] < D.shots.cooldown then return end
  lastShot[src] = now
  local pos = GetEntityCoords(GetPlayerPed(src))
  local b = D.shots.blur
  TacoV.Dispatch.create('lspd', 'shots', 'Schüsse gemeldet', pos.x + math.random(-b, b), pos.y + math.random(-b, b), nil)
end)

-- Blitzer (aus server/traffic.lua)
AddEventHandler('tacov:dispatch:speedcam', function(camLabel, plate, speed, limit, x, y)
  if not D.speedcam.enabled or speed - limit < D.speedcam.overKmh then return end
  TacoV.Dispatch.create('lspd', 'speed', ('Blitzer %s: %s mit %d km/h bei %d'):format(camLabel, plate, speed, limit), x, y, nil)
end)

local function member(src)
  local c = TacoV.Characters.get(src)
  if not c or not c.faction or not TacoV.Factions.isOnDuty(src) then return nil end
  return c
end

RegisterNetEvent('tacov:dispatch:list', function()
  local src = source
  local c = member(src)
  if not c then return end
  local now = os.time()
  local list = {}
  for id, call in pairs(calls) do
    if now - call.at > D.keepMinutes * 60 then calls[id] = nil
    elseif call.faction == c.faction then list[#list + 1] = public(call) end
  end
  table.sort(list, function(a, b) return a.id > b.id end)
  local units = {}
  for _, s in ipairs(TacoV.Factions.dutyList(c.faction)) do
    local uc = TacoV.Characters.get(s)
    if uc then units[#units + 1] = { name = fullName(uc), rank = TacoV.Factions.rankName(uc.faction, uc.faction_rank), status = Player(s).state.unitStatus or 'free' } end
  end
  TriggerClientEvent('tacov:dispatch:list', src, list, units, Player(src).state.unitStatus or 'free')
end)

RegisterNetEvent('tacov:dispatch:take', function(id)
  local src = source
  local c = member(src)
  local call = calls[tonumber(id) or 0]
  if not c or not call or call.faction ~= c.faction then return end
  call.takenBy, call.takenName = src, fullName(c)
  Player(src).state:set('unitStatus', 'busy', true)
  TriggerClientEvent('tacov:dispatch:route', src, call.x, call.y)
  if call.caller and TacoV.Characters.get(call.caller) then notify(call.caller, 'success', 'Eine Einheit ist unterwegs zu dir.') end
  for _, s in ipairs(TacoV.Factions.dutyList(c.faction)) do
    if s ~= src then notify(s, 'info', ('Einsatz #%d übernimmt %s.'):format(call.id, fullName(c))) end
  end
end)

RegisterNetEvent('tacov:dispatch:close', function(id)
  local src = source
  local c = member(src)
  local call = calls[tonumber(id) or 0]
  if not c or not call or call.faction ~= c.faction then return end
  calls[call.id] = nil
  if Player(src).state.unitStatus == 'busy' then Player(src).state:set('unitStatus', 'free', true) end
  notify(src, 'success', ('Einsatz #%d abgeschlossen.'):format(call.id))
end)

RegisterNetEvent('tacov:dispatch:status', function(status)
  local src = source
  if not member(src) or not D.statuses[status] then return end
  Player(src).state:set('unitStatus', status, true)
  notify(src, 'info', 'Status: ' .. D.statuses[status])
end)

AddEventHandler('playerDropped', function() lastCall[source] = nil lastShot[source] = nil end)
