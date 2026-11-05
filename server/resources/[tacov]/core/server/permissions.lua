-- Rechteprüfung: Rolle des Spielers (players.role) gegen config/permissions.lua.
TacoV = TacoV or {}
TacoV.Permissions = {}

local function roleLevel(role)
  local r = TacoV.Config.Roles[role or 'player']
  return r and r.level or 0
end

--- Hat die Quelle (Server-ID) das Recht? Unbekannte Rechte sind immer verweigert.
function TacoV.Permissions.has(source, right)
  local need = TacoV.Config.Rights[right]
  if not need then return false end
  local p = TacoV.Players.get(source)
  if not p then return false end
  return roleLevel(p.role) >= need
end

--- Setzt die Rolle eines Spielers (nur über admin.roles).
function TacoV.Permissions.setRole(targetPlayerId, role, actorSource)
  if not TacoV.Config.Roles[role] then return false, 'role' end
  TacoV.DB.update('UPDATE players SET role = ? WHERE id = ?', { role, targetPlayerId })
  for src, p in pairs(TacoV.Players.all()) do
    if p.id == targetPlayerId then
      p.role = role
      TriggerClientEvent('tacov:core:role', src, role)
    end
  end
  local actor = actorSource and TacoV.Players.get(actorSource)
  TacoV.Log.write('admin', ('Rolle gesetzt: Spieler %d -> %s'):format(targetPlayerId, role),
    { discordId = actor and actor.discordId })
  return true
end

exports('hasPermission', TacoV.Permissions.has)
