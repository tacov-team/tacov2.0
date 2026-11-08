-- Entwickler-Werkzeuge (5.14), Server: Freigabe (`dev.tools`), Entity-Besitzer, Überschreibungen neu laden, Resource-Neustart.
TacoV = TacoV or {}

local function notify(src, kind, text) TriggerClientEvent('tacov:core:notify', src, kind, text) end
local function need(src)
  if TacoV.Permissions.has(src, 'dev.tools') then return true end
  notify(src, 'error', 'Entwickler-Werkzeuge: Recht dev.tools fehlt (oder nicht im Dienst).')
  return false
end

RegisterNetEvent('tacov:dev:toggle', function(what, on)
  local src = source
  if not need(src) then return end
  TriggerClientEvent('tacov:dev:set', src, what, on == true)
end)

RegisterNetEvent('tacov:dev:entity', function(netId)
  local src = source
  if not need(src) then return end
  local ent = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
  if ent == 0 or not DoesEntityExist(ent) then notify(src, 'info', 'Entity ist dem Server nicht bekannt (lokal).') return end
  local owner = NetworkGetEntityOwner(ent)
  local p = owner and TacoV.Players.get(owner)
  local c = owner and TacoV.Characters.get(owner)
  local name = c and (c.first_name .. ' ' .. c.last_name) or (p and p.discordId or '–')
  notify(src, 'info', ('Netz-ID %d · Besitzer #%s %s · Typ %d'):format(tonumber(netId), tostring(owner), name, GetEntityType(ent)))
end)

RegisterNetEvent('tacov:dev:reload', function(what)
  local src = source
  if not need(src) then return end
  local p = TacoV.Players.get(src)
  if what == 'overrides' then
    TriggerEvent('tacov:core:reloadData') -- Orte, Creator-Daten und Config-Überschreibungen neu aus der Datenbank
    TacoV.Log.write('admin', 'Entwickler: Daten und Überschreibungen neu geladen', { discordId = p and p.discordId })
    notify(src, 'success', 'Datenbank-Daten und Config-Überschreibungen neu geladen.')
  elseif what == 'resource' then
    TacoV.Log.write('admin', 'Entwickler: Resource tacov_core wird neu gestartet', { discordId = p and p.discordId })
    TriggerClientEvent('tacov:core:notify', -1, 'warn', 'Der Kern wird neu geladen – bitte kurz warten.')
    for _, s in ipairs(GetPlayers()) do TacoV.Characters.save(tonumber(s)) end
    SetTimeout(500, function() ExecuteCommand('restart ' .. GetCurrentResourceName()) end)
  end
end)
