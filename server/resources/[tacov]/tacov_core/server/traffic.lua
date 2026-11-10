-- Blitzer (Punkt 4.12) und Kfz-Steuer (Punkt 4.13). Der Server misst die Geschwindigkeit selbst (Entity-Velocity),
-- bucht Bußgelder an den Staat, vergibt Punkte über das DMV und zieht wöchentlich Steuern je Fahrzeug ein.
TacoV = TacoV or {}
TacoV.Traffic = {}

local Cfg = TacoV.Config.Traffic
local STATE = { type = 'state', id = 0 }
local function trim(s) return (tostring(s or ''):gsub('^%s+', ''):gsub('%s+$', '')) end
local function fmt(n)
  local s = tostring(math.floor(n))
  local out = s:reverse():gsub('(%d%d%d)', '%1.'):reverse()
  if out:sub(1, 1) == '.' then out = out:sub(2) end
  return out .. ' $'
end

-- ---------------------------------------------------------------- Blitzer

local lastFlash = {} -- [plate .. cam] = os.time()

RegisterNetEvent('tacov:traffic:flash', function(camName, netId)
  local src = source
  local c = TacoV.Characters.get(src)
  if not c then return end
  local cam = TacoV.Locations.get(tostring(camName))
  if not cam or cam.kind ~= 'speedcam' then return end
  local ent = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
  if ent == 0 or not DoesEntityExist(ent) then return end
  if GetPedInVehicleSeat(ent, -1) ~= GetPlayerPed(src) then return end
  if #(GetEntityCoords(ent) - vector3(cam.x, cam.y, cam.z)) > Cfg.radius + 10.0 then return end
  local v = GetEntityVelocity(ent)
  local speed = math.floor(#(v) * 3.6 + 0.5)
  local limit = tonumber(cam.limit) or 70
  local over = speed - limit
  if over <= Cfg.tolerance then return end
  local plate = trim(GetVehicleNumberPlateText(ent))
  local key = plate .. '|' .. cam.name
  if lastFlash[key] and os.time() - lastFlash[key] < Cfg.cooldownSeconds then return end
  lastFlash[key] = os.time()
  local fine, points = 0, 0
  for _, f in ipairs(Cfg.fines) do
    if over <= f.upTo then fine, points = f.fine, f.points break end
  end
  local paid = TacoV.Accounts.pay(src, STATE, fine, 'bussgeld', ('%s · %d km/h bei %d'):format(cam.label, speed, limit))
  if points > 0 and TacoV.DMV then TacoV.DMV.addPoints(c.id, points, ('Blitzer %s: %d km/h bei %d'):format(cam.label, speed, limit)) end
  TacoV.Log.write('justice', ('Geblitzt %s: %d km/h bei %d, Bußgeld %s%s, %d Punkte'):format(cam.label, speed, limit, fmt(fine),
    paid and '' or ' (offen)', points), { characterId = c.id })
  TriggerClientEvent('tacov:traffic:flashed', src)
  TriggerEvent('tacov:dispatch:speedcam', cam.label, plate, speed, limit, cam.x, cam.y)
  TriggerClientEvent('tacov:core:notify', src, 'warn',
    ('Geblitzt: %d km/h bei erlaubten %d. Bußgeld %s%s%s.'):format(speed, limit, fmt(fine), paid and '' or ' (Konto gedeckt? offen)',
      points > 0 and (' · %d Punkte'):format(points) or ''))
end)

-- ---------------------------------------------------------------- Kfz-Steuer

local function weeklyTax(price)
  return math.floor((price or 0) * Cfg.taxPercentPerYear / 100 / 52 + 0.5)
end

function TacoV.Traffic.collectTaxes()
  local rows = TacoV.DB.query(
    ('SELECT id, plate, model, owner_type, owner_id, bought_price, tax_due FROM vehicles WHERE deleted_at IS NULL AND owner_type = \'character\' ' ..
     'AND (tax_paid_at IS NULL OR tax_paid_at < NOW() - INTERVAL %d DAY)'):format(Cfg.taxIntervalDays)) or {}
  local charged, open = 0, 0
  for _, r in ipairs(rows) do
    local amount = weeklyTax(r.bought_price) + (r.tax_due or 0)
    if amount > 0 then
      local okMove = TacoV.Journal.move('bank', { type = 'character', id = r.owner_id }, STATE, amount, 'kfz_steuer', { note = r.plate })
      if okMove then
        TacoV.DB.update('UPDATE vehicles SET tax_paid_at = NOW(), tax_due = 0 WHERE id = ?', { r.id })
        charged = charged + 1
      else
        TacoV.DB.update('UPDATE vehicles SET tax_paid_at = NOW(), tax_due = ? WHERE id = ?', { amount, r.id })
        open = open + 1
      end
      for src, p in pairs(TacoV.Players.all()) do
        if p.characterId == r.owner_id then
          TacoV.Accounts.push(src)
          TriggerClientEvent('tacov:core:notify', src, okMove and 'info' or 'warn',
            okMove and ('Kfz-Steuer %s für %s abgebucht.'):format(fmt(amount), r.plate)
              or ('Kfz-Steuer %s für %s offen – wird beim Ausparken fällig.'):format(fmt(amount), r.plate))
        end
      end
    else
      TacoV.DB.update('UPDATE vehicles SET tax_paid_at = NOW() WHERE id = ?', { r.id })
    end
  end
  if charged + open > 0 then TacoV.Log.write('money', ('Kfz-Steuer: %d abgebucht, %d offen'):format(charged, open)) end
end

AddEventHandler('tacov:core:ready', function()
  CreateThread(function()
    Wait(60000)
    while true do
      TacoV.Traffic.collectTaxes()
      Wait(3600000)
    end
  end)
end)
