-- Admin-Grundgerüst (Punkt 5.1): Unsichtbar, Noclip, Teleport. Jede Aktion prüft Rechte (nur im Admin-Dienst), setzt
-- den Zustand als Statebag (damit alle Clients ihn sehen) und schreibt ins Log `admin`.
TacoV = TacoV or {}
TacoV.Admin = {}

local state = {} -- [src] = { invisible = bool, noclip = bool }

local function notify(src, kind, text) TriggerClientEvent('tacov:core:notify', src, kind, text) end
local function who(src)
  local p = TacoV.Players.get(src)
  local c = TacoV.Characters.get(src)
  return p, c, c and (c.first_name .. ' ' .. c.last_name) or ('#' .. src)
end
local function log(src, text)
  local p, c = who(src)
  TacoV.Log.write('admin', text, { discordId = p and p.discordId, characterId = c and c.id })
end
local function need(src, right)
  if TacoV.Permissions.has(src, right) then return true end
  notify(src, 'error', 'Dafür fehlt dir das Recht (oder du bist nicht im Admin-Dienst).')
  return false
end

function TacoV.Admin.state(src)
  state[src] = state[src] or { invisible = false, noclip = false }
  return state[src]
end

local function set(src, key, on)
  local s = TacoV.Admin.state(src)
  s[key] = on and true or false
  Player(src).state:set('admin_' .. key, s[key], true)
  TriggerClientEvent('tacov:admin:state', src, s)
end

--- Alles zurücksetzen (Dienstende, Verbindungsabbruch)
function TacoV.Admin.reset(src)
  if not state[src] then return end
  if state[src].invisible then set(src, 'invisible', false) end
  if state[src].noclip then set(src, 'noclip', false) end
  state[src] = nil
end

local function toggle(src, key)
  if key == 'invisible' then
    if not need(src, 'support.invisible') then return end
  elseif key == 'noclip' then
    if not need(src, 'admin.noclip') then return end
  else return end
  local s = TacoV.Admin.state(src)
  set(src, key, not s[key])
  log(src, ('%s %s'):format(key == 'invisible' and 'Unsichtbar' or 'Noclip', s[key] and 'an' or 'aus'))
end
RegisterNetEvent('tacov:admin:toggle', function(key) toggle(source, key) end)

-- Teleport: mode = 'player' (zu Spieler), 'bring' (Spieler herholen), 'waypoint' (Wegpunkt), 'coords' (x y z)
local function teleport(src, mode, a, b, c)
  if not need(src, 'support.teleport') then return end
  local _, _, me = who(src)
  if mode == 'player' or mode == 'bring' then
    local target = tonumber(a)
    if not target or not TacoV.Players.get(target) or target == src then notify(src, 'error', 'Spieler nicht gefunden.') return end
    local _, _, other = who(target)
    local fromPed, toPed = GetPlayerPed(mode == 'player' and src or target), GetPlayerPed(mode == 'player' and target or src)
    local pos = GetEntityCoords(toPed)
    TriggerClientEvent('tacov:admin:setCoords', mode == 'player' and src or target, pos.x, pos.y, pos.z, GetEntityHeading(toPed))
    if mode == 'bring' then notify(target, 'warn', ('Du wurdest von %s (Team) geholt.'):format(me)) end
    notify(src, 'info', mode == 'player' and ('Teleportiert zu %s.'):format(other) or ('%s hergeholt.'):format(other))
    log(src, ('%s %s (#%d) · von %.1f %.1f %.1f'):format(mode == 'player' and 'Teleport zu' or 'Hergeholt:', other, target,
      GetEntityCoords(fromPed).x, GetEntityCoords(fromPed).y, GetEntityCoords(fromPed).z))
  elseif mode == 'coords' then
    local x, y, z = tonumber(a), tonumber(b), tonumber(c)
    if not x or not y then notify(src, 'error', 'Nutzung: /tp <x> <y> [z]') return end
    TriggerClientEvent('tacov:admin:setCoords', src, x, y, z or -1.0, nil)
    log(src, ('Teleport zu %.1f %.1f %s'):format(x, y, z and ('%.1f'):format(z) or 'Boden'))
  elseif mode == 'waypoint' then
    TriggerClientEvent('tacov:admin:toWaypoint', src)
    log(src, 'Teleport zum Wegpunkt')
  end
end
RegisterNetEvent('tacov:admin:teleport', function(mode, a, b, c) teleport(source, mode, a, b, c) end)

-- Spielerliste für das Team-Menü (nur im Dienst; Name und Server-ID, keine internen Daten)
RegisterNetEvent('tacov:admin:players', function()
  local src = source
  if not TacoV.Permissions.onDuty(src) then return end
  local list = {}
  for id in pairs(TacoV.Players.all()) do
    local _, c, name = who(id)
    list[#list + 1] = { id = id, name = name, char = c ~= nil, dist = #(GetEntityCoords(GetPlayerPed(id)) - GetEntityCoords(GetPlayerPed(src))) }
  end
  table.sort(list, function(x, y) return x.id < y.id end)
  TriggerClientEvent('tacov:admin:players', src, list)
end)

AddEventHandler('tacov:core:dutyOff', function(src) TacoV.Admin.reset(src) end)
AddEventHandler('playerDropped', function() state[source] = nil end)

-- Befehle
RegisterCommand('tp', function(src, args)
  if src == 0 then return end
  if #args == 1 and args[1] == 'wp' then teleport(src, 'waypoint')
  elseif #args == 1 then teleport(src, 'player', args[1])
  elseif #args >= 2 then teleport(src, 'coords', args[1], args[2], args[3])
  else notify(src, 'error', 'Nutzung: /tp <ID> · /tp wp · /tp <x> <y> [z]') end
end, false)
RegisterCommand('tpm', function(src) if src ~= 0 then teleport(src, 'waypoint') end end, false)
RegisterCommand('bring', function(src, args) if src ~= 0 then teleport(src, 'bring', args[1]) end end, false)
RegisterCommand('noclip', function(src) if src ~= 0 then toggle(src, 'noclip') end end, false)
RegisterCommand('unsichtbar', function(src) if src ~= 0 then toggle(src, 'invisible') end end, false)
