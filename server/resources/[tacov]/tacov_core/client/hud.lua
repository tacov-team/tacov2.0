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
  if not c.faction then return 'Zivilist' end
  return ('%s · Rang %d'):format(c.faction:upper(), c.factionRank or 0)
end

--- Schickt die vollständigen HUD-Daten des Charakters (nach dem Laden und bei Änderungen).
function TacoV.Hud.refresh()
  local c = TacoV.Client.character
  if not c then return end
  local play = c.playtimeSeconds or 0
  local perLevel = TacoV.Config.Level.hoursPerLevel * 3600
  TacoV.UI.send('hud', {
    visible = true,
    name = c.firstName .. ' ' .. c.lastName,
    level = c.level, levelProgress = (play % perLevel) / perLevel, status = statusFor(c.level),
    faction = factionLabel(c),
    bank = TacoV.Client.bank, cash = 0, black = 0,
    serverId = GetPlayerServerId(PlayerId()),
    weight = 0, maxWeight = TacoV.Config.Inventory.baseWeight,
    hunger = TacoV.Hud.needs.hunger, thirst = TacoV.Hud.needs.thirst, fitness = TacoV.Hud.needs.fitness,
  })
end

RegisterNetEvent('tacov:core:needs', function(n)
  TacoV.Hud.needs = n
  TacoV.UI.send('hud', { hunger = n.hunger, thirst = n.thirst, fitness = n.fitness })
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
