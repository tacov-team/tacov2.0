-- Waffen (Grundlage, vollständig mit Punkt 11.2): Waffen-Items in die Hand nehmen und wegstecken, Munition aus den
-- Munitions-Items, Weste. Die Waffe existiert nur, solange das Item in der Tasche liegt.
TacoV = TacoV or {}
TacoV.Weapons = {}

local Items = TacoV.Config.Items
local holding = {}   -- [src] = item

local function ammoOf(src, def)
  if not def.ammo then return 0 end
  local inv = TacoV.Inventory.ofSource(src)
  return inv and TacoV.Inventory.count(inv, def.ammo) or 0
end

for name, def in pairs(Items) do
  if def.weapon then
    AddEventHandler('tacov:item:' .. name, function(source)
      if Player(source).state.cuffed or Player(source).state.downed then return end
      if holding[source] == name then
        holding[source] = nil
        TriggerClientEvent('tacov:weapons:holster', source)
      else
        holding[source] = name
        TriggerClientEvent('tacov:weapons:draw', source, name, def.weapon, math.min(250, ammoOf(source, def)), def.ammo ~= nil)
      end
    end)
  end
end

--- Client meldet den Munitionsstand der gezogenen Waffe: verbrauchte Patronen aus dem Inventar nehmen (nur abwärts)
RegisterNetEvent('tacov:weapons:ammo', function(left)
  local src = source
  local name = holding[src]
  local def = name and Items[name]
  if not def or not def.ammo then return end
  local inv = TacoV.Inventory.ofSource(src)
  if not inv then return end
  local have = TacoV.Inventory.count(inv, def.ammo)
  local shown = math.min(250, have)
  left = math.max(0, math.floor(tonumber(left) or shown))
  if left < shown then
    TacoV.Inventory.remove(inv, def.ammo, shown - left)
    -- Nachschub aus der Tasche, wenn mehr als 250 vorhanden waren
    local rest = TacoV.Inventory.count(inv, def.ammo)
    if rest > left then TriggerClientEvent('tacov:weapons:setAmmo', src, math.min(250, rest)) end
  end
end)

--- Waffe wegnehmen (Durchsuchung, Handschellen, Koma)
function TacoV.Weapons.clear(src)
  if holding[src] then holding[src] = nil end
  TriggerClientEvent('tacov:weapons:holster', src)
end
function TacoV.Weapons.holding(src) return holding[src] end

-- Item nicht mehr in der Tasche → Waffe weg
CreateThread(function()
  while true do
    Wait(3000)
    for src, name in pairs(holding) do
      local inv = TacoV.Inventory.ofSource(src)
      if not inv or TacoV.Inventory.count(inv, name) <= 0 then TacoV.Weapons.clear(src) end
    end
  end
end)

AddEventHandler('tacov:item:armor', function(source, slot)
  local inv = TacoV.Inventory.ofSource(source)
  if not inv or not TacoV.Inventory.takeSlot(inv, slot, 1) then return end
  TriggerClientEvent('tacov:weapons:armor', source, 100)
  TriggerClientEvent('tacov:core:notify', source, 'success', 'Weste angelegt.')
end)

AddEventHandler('tacov:core:characterUnloaded', function(src) holding[src] = nil end)
AddEventHandler('playerDropped', function() holding[source] = nil end)
