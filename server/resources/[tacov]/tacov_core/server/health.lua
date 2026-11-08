-- Verletzungen (Server, 6.8): Bewusstlos-Status (Statebag `downed`), Koma-Kosten, Erste-Hilfe-Items, Hilfe durch andere.
TacoV = TacoV or {}
TacoV.Health = {}

local H = TacoV.Config.Health
local STATE = { type = 'state', id = 0 }
local function notify(src, kind, text) TriggerClientEvent('tacov:core:notify', src, kind, text) end

RegisterNetEvent('tacov:health:downed', function()
  local src = source
  local c = TacoV.Characters.get(src)
  if not c then return end
  Player(src).state:set('downed', true, true)
  TacoV.Log.write('medic', ('Bewusstlos: %s %s'):format(c.first_name, c.last_name), { characterId = c.id })
end)

RegisterNetEvent('tacov:health:coma', function()
  local src = source
  local c = TacoV.Characters.get(src)
  if not c then return end
  Player(src).state:set('downed', false, true)
  -- Softcore: Bargeld geht verloren, Krankenhausgebühr vom Konto (auch ins Minus)
  local inv = TacoV.Inventory.ofSource(src)
  local cash = TacoV.Inventory.cash(inv)
  if cash > 0 then
    TacoV.Inventory.remove(inv, 'cash', cash)
    TacoV.Journal.move('cash', { type = 'character', id = c.id }, nil, cash, 'koma_verlust', { actor = c.id })
  end
  TacoV.Journal.move('bank', { type = 'character', id = c.id }, STATE, H.hospitalFee, 'krankenhaus', { allowNegative = true })
  TriggerEvent('tacov:health:comaItems', src)
  TacoV.Accounts.push(src)
  TacoV.Inventory.send(src)
  TacoV.AC.allowTeleport(src)
  TacoV.Log.write('medic', ('Koma: %s %s – %d $ Bargeld verloren, %d $ Krankenhaus'):format(c.first_name, c.last_name, cash, H.hospitalFee), { characterId = c.id })
  notify(src, 'warn', ('Koma: %d $ Bargeld verloren, %d $ Krankenhauskosten.'):format(cash, H.hospitalFee))
end)

function TacoV.Health.revive(target)
  Player(target).state:set('downed', false, true)
  TriggerClientEvent('tacov:health:revive', target)
end

-- Items
AddEventHandler('tacov:item:first_aid', function(source, slot)
  local inv = TacoV.Inventory.ofSource(source)
  TacoV.Inventory.takeSlot(inv, slot, 1)
  TriggerClientEvent('tacov:health:heal', source, H.kitHeal, true)
end)
AddEventHandler('tacov:item:bandage', function(source, slot)
  local inv = TacoV.Inventory.ofSource(source)
  TacoV.Inventory.takeSlot(inv, slot, 1)
  TriggerClientEvent('tacov:health:heal', source, H.bandageHeal, false)
end)

-- Einem Bewusstlosen mit Kit helfen: stabilisiert (verlängert), LSMD (Phase 8) belebt wieder
RegisterNetEvent('tacov:health:helpDowned', function(target)
  local src = source
  target = tonumber(target)
  if not target or not Player(target).state.downed then return end
  if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(target))) > 3.0 then return end
  local inv = TacoV.Inventory.ofSource(src)
  if not TacoV.Inventory.has(inv, 'first_aid', 1) then notify(src, 'error', 'Du brauchst ein Erste-Hilfe-Kit.') return end
  TacoV.Inventory.remove(inv, 'first_aid', 1)
  TacoV.Inventory.send(src)
  TriggerClientEvent('tacov:health:heal', target, 0, true)
  notify(src, 'success', 'Stabilisiert – der LSMD kann jetzt übernehmen.')
  local c = TacoV.Characters.get(src)
  TacoV.Log.write('medic', 'Erste Hilfe an Bewusstlosem geleistet', { characterId = c and c.id })
end)

-- Team-Heilen belebt auch wieder
AddEventHandler('tacov:health:adminHeal', function(target) TacoV.Health.revive(target) end)
