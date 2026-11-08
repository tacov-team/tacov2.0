-- Zugangsregeln (Phase 5): gemeinsam für Türen, Aufzüge, Portale. access = { faction, minRank, item } oder leer (frei).
-- Team im Dienst mit Recht `creator` darf immer.
TacoV = TacoV or {}
TacoV.Access = {}

function TacoV.Access.check(src, access)
  if TacoV.Permissions.has(src, 'creator') then return true end
  local c = TacoV.Characters.get(src)
  if not c then return false end
  local a = access or {}
  if not a.faction and not a.item then return true end
  if a.faction and c.faction == a.faction and (c.faction_rank or 0) >= (a.minRank or 0) then return true end
  if a.item and TacoV.Inventory.has(TacoV.Inventory.ofSource(src), a.item, 1) then return true end
  return false
end

--- Eingaben aus dem Creator bereinigen
function TacoV.Access.clean(a)
  a = type(a) == 'table' and a or {}
  local access = {}
  if type(a.faction) == 'string' and #a.faction > 0 then access.faction = TacoV.Util.cleanText(a.faction, 32):lower() end
  if access.faction and tonumber(a.minRank) then access.minRank = math.floor(tonumber(a.minRank)) end
  if type(a.item) == 'string' and TacoV.Config.Items[a.item] then access.item = a.item end
  return access
end

function TacoV.Access.text(a)
  a = a or {}
  if a.faction then return ('Fraktion %s ab Rang %d'):format(a.faction, a.minRank or 0) end
  if a.item then return 'Schlüssel: ' .. ((TacoV.Config.Items[a.item] or {}).label or a.item) end
  return 'frei'
end
