-- HUD-Daten: Leben/Weste vom Ped, Straße und Gebiet, Bedürfnisse und Konto vom Server.
TacoV = TacoV or {}
TacoV.Hud = { needs = { hunger = 100, thirst = 100, fitness = 0, alcohol = 0 } }

local STATUS_LABEL = { noob = 'Neuling', probation = 'Probezeit' }

local function statusFor(level)
  if level < TacoV.Config.Level.noobProtectionUntil then return STATUS_LABEL.noob end
  if level < TacoV.Config.Level.probationUntil then return STATUS_LABEL.probation end
  return ''
end

local function factionLabel(c)
  if not c.faction then return 'Zivilist', '' end
  return c.faction:upper(), ('Rang %d'):format(c.factionRank or 0)
end

--- Tankgröße in Litern (aus der Fahrzeugklasse, sonst 65).
function TacoV.Hud.tankCapacity(vehicle)
  if TacoV.Vehicles and TacoV.Vehicles.tankOf then return TacoV.Vehicles.tankOf(vehicle) end
  return 65
end

--- Schickt die vollständigen HUD-Daten des Charakters (nach dem Laden und bei Änderungen).
function TacoV.Hud.refresh()
  local c = TacoV.Client.character
  if not c then return end
  local play = c.playtimeSeconds or 0
  local perLevel = TacoV.Config.Level.hoursPerLevel * 3600
  local faction, rank = factionLabel(c)
  TacoV.UI.send('hud', {
    visible = true,
    name = c.firstName .. ' ' .. c.lastName,
    level = c.level, levelProgress = (play % perLevel) / perLevel, status = statusFor(c.level),
    faction = faction, factionRank = rank,
    bank = TacoV.Client.bank, cash = TacoV.Inventory.money.cash, black = TacoV.Inventory.money.black,
    serverId = GetPlayerServerId(PlayerId()),
    weight = TacoV.Inventory.money.weight, maxWeight = TacoV.Inventory.money.maxWeight,
    hunger = TacoV.Hud.needs.hunger, thirst = TacoV.Hud.needs.thirst, fitness = TacoV.Hud.needs.fitness,
  })
end

--- Bildschirmbereich der GTA-Minimap in Bruchteilen (0–1), aus Auflösung, Seitenverhältnis und Safezone.
local function minimapRect()
  local safe = GetSafeZoneSize()
  local aspect = GetAspectRatio(false)
  local resX, resY = GetActiveScreenResolution()
  local w = (resX / (4 * aspect)) / resX
  local h = (resY / 5.674) / resY
  local margin = (1.0 - safe) * 0.5 -- Safezone-Rand je Seite
  local x = margin + 0.0025
  local bottom = 1.0 - margin - 0.0025
  return { x = x, y = bottom - h, w = w, h = h }
end

-- Minimap-Position an die UI melden (Auflösung/Safezone können sich ändern)
CreateThread(function()
  local last = ''
  while true do
    Wait(2000)
    if TacoV.Client.character then
      local r = minimapRect()
      local key = ('%.4f|%.4f|%.4f|%.4f'):format(r.x, r.y, r.w, r.h)
      if key ~= last then
        last = key
        TacoV.UI.send('hud', { minimap = r })
      end
    end
  end
end)

-- Vanilla-Anzeigen ausblenden, die das HUD ersetzt: Geld, Gebiet, Straße, Fahrzeugname/-klasse
CreateThread(function()
  while true do
    Wait(0)
    if TacoV.Client.character then
      HideHudComponentThisFrame(3)  -- Bargeld
      HideHudComponentThisFrame(4)  -- MP-Bargeld
      HideHudComponentThisFrame(6)  -- Fahrzeugname
      HideHudComponentThisFrame(7)  -- Gebietsname
      HideHudComponentThisFrame(8)  -- Fahrzeugklasse
      HideHudComponentThisFrame(9)  -- Straßenname
    else
      Wait(500)
    end
  end
end)

RegisterNetEvent('tacov:core:needs', function(n)
  TacoV.Hud.needs = n
  TacoV.UI.send('hud', { hunger = n.hunger, thirst = n.thirst, fitness = n.fitness, alcohol = n.alcohol })
end)

-- Leben, Weste, Straße: 4x je Sekunde Leben/Weste, 1x je Sekunde Straße
CreateThread(function()
  local lastStreet, tick = '', 0
  while true do
    Wait(250)
    if TacoV.Client.character then
      local ped = PlayerPedId()
      local health = math.max(0, GetEntityHealth(ped) - 100) / (GetEntityMaxHealth(ped) - 100) * 100
      local armor = GetPedArmour(ped)
      local data = { health = health, armor = armor }
      tick = tick + 1
      if tick % 4 == 0 then
        local pos = GetEntityCoords(ped)
        local s1, s2 = GetStreetNameAtCoord(pos.x, pos.y, pos.z)
        local street = GetStreetNameFromHashKey(s1)
        local cross = s2 ~= 0 and GetStreetNameFromHashKey(s2) or ''
        local area = GetLabelText(GetNameOfZone(pos.x, pos.y, pos.z))
        local key = street .. '|' .. cross .. '|' .. area
        if key ~= lastStreet then
          lastStreet = key
          data.street = street
          data.area = cross ~= '' and (area .. ' · ' .. cross) or area
        end
      end
      TacoV.UI.send('hud', data)
    end
  end
end)

-- Fahrzeug: Tacho, Tank, Motor, Schloss – 5x je Sekunde solange man im Fahrzeug sitzt
CreateThread(function()
  local wasIn = false
  while true do
    Wait(200)
    local ped = PlayerPedId()
    local veh = TacoV.Client.character and GetVehiclePedIsIn(ped, false) or 0
    if veh ~= 0 then
      wasIn = true
      local tank = TacoV.Hud.tankCapacity(veh)
      local liters = TacoV.Vehicles and TacoV.Vehicles.fuelOf and TacoV.Vehicles.fuelOf(veh) or (GetVehicleFuelLevel(veh) / 100 * tank)
      TacoV.UI.send('hud', { vehicle = {
        speed = math.floor(GetEntitySpeed(veh) * 3.6 + 0.5),
        fuel = math.floor(liters + 0.5),
        tank = tank,
        engine = GetIsVehicleEngineRunning(veh),
        locked = GetVehicleDoorLockStatus(veh) >= 2,
      }, station = TacoV.Vehicles and TacoV.Vehicles.hudStation and TacoV.Vehicles.hudStation() or false })
    elseif wasIn then
      wasIn = false
      TacoV.UI.send('hud', { vehicle = false, station = false })
    end
  end
end)

-- Hunger/Durst bei 0: Schaden (Konzept 5: 1 % je 30 s)
CreateThread(function()
  while true do
    Wait(30000)
    if TacoV.Client.character and (TacoV.Hud.needs.hunger <= 0 or TacoV.Hud.needs.thirst <= 0) then
      local ped = PlayerPedId()
      local dmg = math.floor((GetEntityMaxHealth(ped) - 100) * TacoV.Config.Needs.starveDamagePercentPer30s / 100)
      local hp = GetEntityHealth(ped)
      if hp - dmg > 101 then SetEntityHealth(ped, hp - dmg) end
    end
  end
end)
