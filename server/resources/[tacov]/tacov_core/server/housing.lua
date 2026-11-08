-- Sozialwohnung (6.5): Eintrag `homes` mit der Einreise, Instanz je Mieter (Routing-Bucket), Lager 20 kg, Kleiderschrank,
-- Miete nach 14 Tagen wöchentlich vom Konto (offen → beim Betreten fällig). Grundlage für das Immobilienmodul.
TacoV = TacoV or {}
TacoV.Housing = {}

local H = TacoV.Config.Housing.social
local STATE = { type = 'state', id = 0 }
local inside = {} -- [src] = home id

local function notify(src, kind, text) TriggerClientEvent('tacov:core:notify', src, kind, text) end
local function fmt(n)
  local out = tostring(math.floor(n or 0)):reverse():gsub('(%d%d%d)', '%1.'):reverse()
  if out:sub(1, 1) == '.' then out = out:sub(2) end
  return out .. ' $'
end

function TacoV.Housing.homeOf(characterId)
  return TacoV.DB.single('SELECT * FROM homes WHERE character_id = ? AND type = \'social\' LIMIT 1', { characterId })
end

--- Mit der Einreise: Sozialwohnung anlegen (14 Tage frei)
function TacoV.Housing.grantSocial(characterId)
  if TacoV.Housing.homeOf(characterId) then return end
  TacoV.DB.insert('INSERT INTO homes (character_id, type, label, rent, free_until, rent_paid_at) VALUES (?, \'social\', ?, ?, DATE_ADD(NOW(), INTERVAL ? DAY), NOW())',
    { characterId, H.label, H.rentWeekly, TacoV.Config.Housing.social.freeDays })
end

local function enter(src)
  local c = TacoV.Characters.get(src)
  if not c then return end
  local home = TacoV.Housing.homeOf(c.id)
  if not home then notify(src, 'error', 'Du hast keine Wohnung. Die Sozialwohnung gibt es mit der Einreise.') return end
  if not TacoV.Inventory.has(TacoV.Inventory.ofSource(src), 'housing_key', 1) then notify(src, 'error', 'Du brauchst deinen Wohnungsschlüssel.') return end
  if (home.rent_due or 0) > 0 then
    if not TacoV.Accounts.pay(src, STATE, home.rent_due, 'miete', 'Sozialwohnung offen') then
      return notify(src, 'error', ('Offene Miete %s – nicht genug Guthaben.'):format(fmt(home.rent_due)))
    end
    TacoV.DB.update('UPDATE homes SET rent_due = 0 WHERE id = ?', { home.id })
    notify(src, 'info', ('Offene Miete %s bezahlt.'):format(fmt(home.rent_due)))
  end
  inside[src] = home.id
  SetPlayerRoutingBucket(src, 10000 + c.id)
  TacoV.AC.allowTeleport(src)
  TriggerClientEvent('tacov:housing:go', src, 'inside')
  TriggerEvent('tacov:newbie:step', src, 'home')
end

local function leave(src)
  if not inside[src] then return end
  inside[src] = nil
  SetPlayerRoutingBucket(src, 0)
  TacoV.AC.allowTeleport(src)
  TriggerClientEvent('tacov:housing:go', src, 'outside')
end

RegisterNetEvent('tacov:housing:enter', function() enter(source) end)
RegisterNetEvent('tacov:housing:leave', function() leave(source) end)
RegisterNetEvent('tacov:housing:storage', function()
  local src = source
  local c = TacoV.Characters.get(src)
  if not c or not inside[src] then return end
  local inv = TacoV.Inventory.load('house', inside[src], H.storageKg)
  TacoV.Inventory.openContainer(src, inv, { title = 'Wohnung', subtitle = ('Lager · %d kg'):format(H.storageKg) })
end)

AddEventHandler('playerDropped', function() inside[source] = nil end)
AddEventHandler('tacov:core:characterUnloaded', function(src) if inside[src] then inside[src] = nil SetPlayerRoutingBucket(src, 0) end end)

-- Miete: stündliche Prüfung, wöchentlich nach der freien Zeit
AddEventHandler('tacov:core:ready', function()
  CreateThread(function()
    Wait(90000)
    while true do
      local rows = TacoV.DB.query('SELECT * FROM homes WHERE rent > 0 AND (free_until IS NULL OR free_until < NOW()) AND (rent_paid_at IS NULL OR rent_paid_at < NOW() - INTERVAL 7 DAY)') or {}
      for _, h in ipairs(rows) do
        local amount = h.rent + (h.rent_due or 0)
        local okMove = TacoV.Journal.move('bank', { type = 'character', id = h.character_id }, STATE, amount, 'miete', { note = h.label })
        if okMove then TacoV.DB.update('UPDATE homes SET rent_paid_at = NOW(), rent_due = 0 WHERE id = ?', { h.id })
        else TacoV.DB.update('UPDATE homes SET rent_paid_at = NOW(), rent_due = ? WHERE id = ?', { amount, h.id }) end
        for src, p in pairs(TacoV.Players.all()) do
          if p.characterId == h.character_id then
            TacoV.Accounts.push(src)
            local text = okMove and ('Miete %s für deine %s abgebucht.'):format(fmt(amount), h.label) or ('Miete %s offen – fällig beim nächsten Betreten.'):format(fmt(amount))
            notify(src, okMove and 'info' or 'warn', text)
          end
        end
      end
      Wait(3600000)
    end
  end)
end)
