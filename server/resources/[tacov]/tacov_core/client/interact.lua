-- Interaktionsrad (X halten): Einträge melden sich mit TacoV.Interact.register an; Module erweitern es.
-- Der Kontext (nächster Spieler, Fahrzeug, Ablage) wird beim Öffnen einmal bestimmt.
TacoV = TacoV or {}
TacoV.Interact = { entries = {} }

--- entry = { id, label, icon, order, when = function(ctx) -> bool, run = function(ctx) }
function TacoV.Interact.register(entry)
  TacoV.Interact.entries[entry.id] = entry
end

exports('interactRegister', TacoV.Interact.register)

local function context()
  local ped = PlayerPedId()
  local pos = GetEntityCoords(ped)
  local ctx = { ped = ped, pos = pos }
  -- nächster Spieler
  local best = 3.0
  for _, pid in ipairs(GetActivePlayers()) do
    local other = GetPlayerPed(pid)
    if other ~= ped then
      local d = #(pos - GetEntityCoords(other))
      if d < best then best = d; ctx.player = GetPlayerServerId(pid); ctx.playerPed = other end
    end
  end
  -- Fahrzeug: drin oder davor
  local veh = GetVehiclePedIsIn(ped, false)
  if veh == 0 then
    local v = GetClosestVehicle(pos.x, pos.y, pos.z, 4.0, 0, 70)
    if v ~= 0 then veh = v end
  end
  if veh ~= 0 then
    ctx.vehicle = veh
    ctx.vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(veh)))
    ctx.plate = GetVehicleNumberPlateText(veh)
  end
  ctx.drop = TacoV.Inventory.nearestDrop(2.5)
  return ctx
end

local current = nil

function TacoV.Interact.open()
  if TacoV.UI.current() then return end
  local ctx = context()
  local list = {}
  for _, e in pairs(TacoV.Interact.entries) do
    if not e.when or e.when(ctx) then
      list[#list + 1] = { id = e.id, label = e.label, icon = e.icon or 'info', order = e.order or 50 }
    end
  end
  table.sort(list, function(a, b) return a.order < b.order end)
  local center
  if ctx.player then center = { kind = 'Spieler', title = 'Gegenüber', sub = 'ID ' .. ctx.player }
  elseif ctx.vehicle then center = { kind = 'Fahrzeug', title = ctx.vehicleName, sub = ctx.plate }
  elseif ctx.drop then center = { kind = 'Boden', title = 'Ablage', sub = 'vor dir' }
  else center = { kind = 'Umgebung', title = 'Nichts in der Nähe', sub = '' } end
  current = ctx
  TacoV.UI.open('wheel', { entries = list, center = center })
end

--- Beim Loslassen von X: Auswahl ausführen (die UI meldet den markierten Eintrag).
function TacoV.Interact.release()
  if TacoV.UI.current() ~= 'wheel' then return end
  TacoV.UI.send('wheelRelease')
end

AddEventHandler('tacov:ui:wheel:pick', function(data)
  local ctx = current
  TacoV.UI.close()
  current = nil
  local e = data and data.id and TacoV.Interact.entries[data.id]
  if e and ctx then e.run(ctx) end
end)

AddEventHandler('tacov:ui:wheel:close', function()
  TacoV.UI.close()
  current = nil
end)

-- Grundeinträge des Kerns
TacoV.Interact.register({
  id = 'inventory', label = 'Inventar', icon = 'bag', order = 10,
  run = function() TacoV.Inventory.open() end,
})
TacoV.Interact.register({
  id = 'pickup', label = 'Aufheben', icon = 'bag', order = 5,
  when = function(ctx) return ctx.drop ~= nil end,
  run = function() TacoV.Inventory.open() end,
})
TacoV.Interact.register({
  id = 'give', label = 'Geben', icon = 'gift', order = 20,
  when = function(ctx) return ctx.player ~= nil end,
  run = function() TacoV.Inventory.open() end,
})
TacoV.Interact.register({
  id = 'show_id', label = 'Ausweis', icon = 'id', order = 30,
  when = function(ctx) return ctx.player ~= nil end,
  run = function() TriggerServerEvent('tacov:inventory:useItem', 'id_card') end,
})
TacoV.Interact.register({
  id = 'handsup', label = 'Hände hoch', icon = 'hands', order = 90,
  run = function() TacoV.Client.toggleHandsUp() end,
})
