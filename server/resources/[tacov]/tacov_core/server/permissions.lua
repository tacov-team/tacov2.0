-- Rechteprüfung: Rolle des Spielers (players.role, gespiegelt aus Discord) gegen config/permissions.lua.
-- Team-Rechte gelten nur im Admin-Dienst (Aduty). Ausnahme: das Recht 'aduty' selbst.
TacoV = TacoV or {}
TacoV.Permissions = {}

local onDuty = {} -- [source] = true

local function roleDef(role)
  return TacoV.Config.Roles[role or 'player'] or TacoV.Config.Roles.player
end

local function roleLevel(role)
  return roleDef(role).level or 0
end

--- Hat die Rolle das Recht (unabhängig vom Dienst)?
local function roleHas(role, right)
  local need = TacoV.Config.Rights[right]
  if not need then return false end
  local def = roleDef(role)
  if def.rights then
    for _, r in ipairs(def.rights) do if r == right then return true end end
    return false
  end
  return (def.level or 0) >= need
end

--- Hat die Quelle (Server-ID) das Recht? Unbekannte Rechte sind immer verweigert; Team-Rechte nur im Dienst.
function TacoV.Permissions.has(source, right)
  local p = TacoV.Players.get(source)
  if not p then return false end
  if not roleHas(p.role, right) then return false end
  if right == 'aduty' then return true end
  return onDuty[source] == true
end

function TacoV.Permissions.isTeam(source)
  local p = TacoV.Players.get(source)
  return p ~= nil and roleLevel(p.role) >= 1
end

function TacoV.Permissions.onDuty(source)
  return onDuty[source] == true
end

function TacoV.Permissions.level(source)
  local p = TacoV.Players.get(source)
  return p and roleLevel(p.role) or 0
end

--- Admin-Dienst an/aus. Liest die Rolle frisch aus der Datenbank (der Bot kann sie zwischenzeitlich geändert haben).
function TacoV.Permissions.setDuty(source, on)
  local p = TacoV.Players.get(source)
  if not p then return false, 'player' end
  local fresh = TacoV.DB.scalar('SELECT role FROM players WHERE id = ?', { p.id })
  if fresh and fresh ~= p.role then
    p.role = fresh
    TriggerClientEvent('tacov:core:role', source, fresh)
  end
  if on and not roleHas(p.role, 'aduty') then return false, 'right' end
  onDuty[source] = on and true or nil
  TriggerClientEvent('tacov:core:aduty', source, on and true or false, roleDef(p.role).label)
  TacoV.Log.write('admin', ('Admin-Dienst %s (%s)'):format(on and 'begonnen' or 'beendet', roleDef(p.role).label),
    { discordId = p.discordId, characterId = p.characterId })
  return true
end

--- Setzt die Rolle eines Spielers im Spiel (Fallback, Quelle ist Discord). Nur unterhalb der eigenen Stufe.
function TacoV.Permissions.setRole(targetPlayerId, role, actorSource)
  if not TacoV.Config.Roles[role] then return false, 'role' end
  if actorSource then
    local actor = TacoV.Players.get(actorSource)
    if not actor or roleLevel(role) >= roleLevel(actor.role) then return false, 'level' end
  end
  TacoV.DB.update('UPDATE players SET role = ? WHERE id = ?', { role, targetPlayerId })
  for src, p in pairs(TacoV.Players.all()) do
    if p.id == targetPlayerId then
      p.role = role
      TriggerClientEvent('tacov:core:role', src, role)
      if onDuty[src] and not roleHas(role, 'aduty') then TacoV.Permissions.setDuty(src, false) end
    end
  end
  local actor = actorSource and TacoV.Players.get(actorSource)
  TacoV.Log.write('admin', ('Rolle gesetzt: Spieler %d -> %s'):format(targetPlayerId, role),
    { discordId = actor and actor.discordId })
  return true
end

AddEventHandler('playerDropped', function()
  onDuty[source] = nil
end)

RegisterNetEvent('tacov:core:aduty:toggle', function()
  local src = source
  local ok, err = TacoV.Permissions.setDuty(src, not onDuty[src])
  if not ok and err == 'right' then
    TriggerClientEvent('tacov:core:notify', src, 'error', 'Du bist kein Teammitglied.')
  end
end)

exports('hasPermission', TacoV.Permissions.has)
exports('isOnDuty', TacoV.Permissions.onDuty)
