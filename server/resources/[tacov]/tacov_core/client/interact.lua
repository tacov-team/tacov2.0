-- Interaktionsrad (X halten): nur für Spieler und Fahrzeuge in Reichweite. Einträge melden sich mit
-- TacoV.Interact.register an; alles andere (Orte, Objekte) läuft über E-Aufforderungen (client/prompt.lua).
-- Der Kontext (nächster Spieler, Fahrzeug) wird beim Öffnen einmal bestimmt.
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
  return ctx
end

local current = nil
local openedAt = 0

-- Taste → GTA-Control, um das Loslassen auch bei NUI-Fokus zu erkennen (Controls sind dann „disabled“, aber lesbar)
local CONTROL_OF = { X = 73, E = 38, F = 23, G = 47, H = 74, R = 45, Q = 44, Z = 20 }

function TacoV.Interact.open()
  if TacoV.UI.current() then return end
  local ctx = context()
  if not ctx.player and not ctx.vehicle then
    TacoV.UI.send('notify', { kind = 'info', text = 'Kein Spieler und kein Fahrzeug in der Nähe.' })
    return
  end
  local list = {}
  for _, e in pairs(TacoV.Interact.entries) do
    if not e.when or e.when(ctx) then
      list[#list + 1] = { id = e.id, label = e.label, icon = e.icon or 'info', order = e.order or 50 }
    end
  end
  table.sort(list, function(a, b) return a.order < b.order end)
  local center
  if ctx.player then center = { kind = 'Spieler', title = 'Gegenüber', sub = 'ID ' .. ctx.player }
  else center = { kind = 'Fahrzeug', title = ctx.vehicleName, sub = ctx.plate } end
  current = ctx
  openedAt = GetGameTimer()
  -- Nur der Mauszeiger geht an die UI, die Tastatur bleibt beim Spiel: so kommt das echte Loslassen von X als
  -- -tacov_interact an. Zur Sicherheit wird die Taste zusätzlich abgefragt.
  TacoV.UI.open('wheel', { entries = list, center = center, key = TacoV.Config.Keys.interact }, true, true)
  local control = CONTROL_OF[tostring(TacoV.Config.Keys.interact):upper()]
  if control then
    CreateThread(function()
      Wait(300)
      while TacoV.UI.current() == 'wheel' do
        Wait(0)
        if not IsControlPressed(0, control) and not IsDisabledControlPressed(0, control) then
          TacoV.Interact.release(true)
          break
        end
      end
    end)
  end
end

--- Beim Loslassen von X: Auswahl ausführen (die UI meldet den markierten Eintrag).
--- Das Loslassen direkt nach dem Öffnen (Fokuswechsel) wird ignoriert.
function TacoV.Interact.release(force)
  if TacoV.UI.current() ~= 'wheel' then return end
  if not force and GetGameTimer() - openedAt < 300 then return end
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

-- Grundeinträge des Kerns (Spieler); Fahrzeug-Einträge kommen mit dem Fahrzeugmodul
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
