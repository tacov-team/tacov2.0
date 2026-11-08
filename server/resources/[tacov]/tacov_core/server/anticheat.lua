-- Anti-Cheat-Grundlage (Punkt 5.16): Server prüft Plausibilität (Bewegung, Fahrzeugtempo, Bargeld vs. Journal, Explosionen,
-- erzeugte Entities). Jede Auffälligkeit wird gespeichert (ac_reports), Team im Dienst sieht sie sofort, der Bot postet sie
-- in den AC-Kanal und erwähnt das AC-Team. Eindeutige Fälle: Sicherheits-Kick, bei Wiederholung Sicherheitssperre.
TacoV = TacoV or {}
TacoV.AC = {}

local C = TacoV.Config.AntiCheat
local strikes = {}      -- [src] = { times }
local lastPos = {}      -- [src] = { pos, t, veh }
local grace = {}        -- [src] = os.time bis dahin keine Prüfung
local kicks = {}        -- [discordId] = os.time des letzten Sicherheits-Kicks
local explosions = {}   -- [src] = { times }
local created = {}      -- [src] = { times }

local function who(src)
  local p = TacoV.Players.get(src)
  local c = TacoV.Characters.get(src)
  return p, c, c and (c.first_name .. ' ' .. c.last_name) or (p and p.discordId) or ('#' .. tostring(src))
end

--- Server-Teleports melden (Admin, Portale, Aufzüge, Spawn), damit sie nicht als Sprung zählen
function TacoV.AC.allowTeleport(src) grace[src] = os.time() + C.teleportGrace end

--- Meldung: action = 'none' | 'kick' | 'ban'
function TacoV.AC.report(src, kind, details, action)
  local p, c, name = who(src)
  if not p then return end
  action = action or 'none'
  if action == 'kick' and kicks[p.discordId] and os.time() - kicks[p.discordId] < 86400 then action = 'ban' end
  TacoV.DB.insert('INSERT INTO ac_reports (discord_id, character_id, player_name, kind, details, action) VALUES (?, ?, ?, ?, ?, ?)',
    { p.discordId, c and c.id, name, kind, TacoV.Util.cleanText(details, 500), action })
  TacoV.Log.write('admin', ('AC %s: %s – %s (%s)'):format(kind, name, details, action), { discordId = p.discordId, characterId = c and c.id })
  for _, staff in ipairs(TacoV.Players.staff(1)) do
    if TacoV.Permissions.onDuty(staff) then
      TriggerClientEvent('tacov:core:notify', staff, 'warn', ('AC · %s (#%d): %s – %s%s'):format(name, src, kind, details, action ~= 'none' and (' → ' .. action) or ''))
    end
  end
  if action == 'kick' then
    kicks[p.discordId] = os.time()
    DropPlayer(src, 'Sicherheits-Kick (Anti-Cheat): ' .. kind .. '. Bei Fragen: Support im Discord.')
  elseif action == 'ban' then
    TacoV.DB.insert('INSERT INTO bans (discord_id, reason, issued_by, until_at) VALUES (?, ?, \'anticheat\', DATE_ADD(NOW(), INTERVAL ? HOUR))',
      { p.discordId, 'Anti-Cheat: ' .. kind .. ' (' .. details .. ')', C.banHoursSecurity })
    DropPlayer(src, ('Sicherheitssperre (Anti-Cheat, %d h): %s. Einspruch im Discord-Support.'):format(C.banHoursSecurity, kind))
  end
end

local function strike(src, kind, details)
  local now = os.time()
  local list = strikes[src] or {}
  local keep = {}
  for _, t in ipairs(list) do if now - t < C.strikeWindow then keep[#keep + 1] = t end end
  keep[#keep + 1] = now
  strikes[src] = keep
  if #keep >= C.strikesForKick then
    strikes[src] = {}
    TacoV.AC.report(src, kind, details .. (' · %d Auffälligkeiten in %d s'):format(#keep, C.strikeWindow), 'kick')
  else
    TacoV.AC.report(src, kind, details .. (' (%d/%d)'):format(#keep, C.strikesForKick), 'none')
  end
end

-- Bewegung und Tempo
AddEventHandler('tacov:core:ready', function()
  CreateThread(function()
    while true do
      Wait(C.checkSeconds * 1000)
      local now = os.time()
      for src in pairs(TacoV.Players.all()) do
        if TacoV.Characters.get(src) and not TacoV.Permissions.onDuty(src) then
          local ped = GetPlayerPed(src)
          if ped and ped ~= 0 then
            local pos = GetEntityCoords(ped)
            local veh = GetVehiclePedIsIn(ped, false)
            local last = lastPos[src]
            if last and (grace[src] or 0) < now and last.veh == veh then
              local dt = math.max(1, now - last.t)
              local flat = #(vector2(pos.x, pos.y) - vector2(last.pos.x, last.pos.y)) / dt
              local falling = (last.pos.z - pos.z) > 5.0
              if veh == 0 and flat > C.footSpeedMax and not falling then
                strike(src, 'Bewegung', ('%.0f m/s zu Fuß (%.1f → %.1f)'):format(flat, last.pos.x, pos.x))
              elseif veh ~= 0 and flat > C.vehicleSpeedMax then
                strike(src, 'Fahrzeugtempo', ('%.0f km/h'):format(flat * 3.6))
              end
            end
            lastPos[src] = { pos = pos, t = now, veh = veh }
          end
        end
      end
    end
  end)
  -- Bargeld vs. Journal (alle 2 Minuten)
  CreateThread(function()
    while true do
      Wait(120000)
      for src in pairs(TacoV.Players.all()) do
        local c = TacoV.Characters.get(src)
        if c then
          local inv = TacoV.Inventory.ofSource(src)
          local have = TacoV.Inventory.cash(inv)
          local journal = (TacoV.DB.scalar('SELECT COALESCE(SUM(CASE WHEN to_type = \'character\' AND to_id = ? THEN amount ELSE 0 END),0) - ' ..
            'COALESCE(SUM(CASE WHEN from_type = \'character\' AND from_id = ? THEN amount ELSE 0 END),0) FROM journal WHERE kind = \'cash\'', { c.id, c.id })) or 0
          local diff = have - journal
          if diff >= C.cashMismatchKick then
            TacoV.AC.report(src, 'Bargeld', ('Inventar %d $, Journal %d $ (+%d)'):format(have, journal, diff), 'kick')
          elseif diff >= C.cashMismatchWarn then
            TacoV.AC.report(src, 'Bargeld', ('Inventar %d $, Journal %d $ (+%d)'):format(have, journal, diff), 'none')
          end
        end
      end
    end
  end)
end)

-- Explosionen
AddEventHandler('explosionEvent', function(sender, ev)
  local src = tonumber(sender)
  if not src or src == 0 or TacoV.Permissions.onDuty(src) then return end
  local now = os.time()
  local list = explosions[src] or {}
  local keep = {}
  for _, t in ipairs(list) do if now - t < 10 then keep[#keep + 1] = t end end
  keep[#keep + 1] = now
  explosions[src] = keep
  if #keep >= C.explosionsPerWindow then
    CancelEvent()
    explosions[src] = {}
    TacoV.AC.report(src, 'Explosionen', ('%d Explosionen in 10 s (Typ %s)'):format(#keep, tostring(ev and ev.explosionType)), 'kick')
  end
end)

-- Vom Spieler erzeugte Netz-Entities
local blacklist = {}
for _, m in ipairs(C.blacklistedModels) do blacklist[GetHashKey(m)] = m end
AddEventHandler('entityCreating', function(entity)
  local owner = NetworkGetEntityOwner(entity)
  if not owner or owner <= 0 or TacoV.Permissions.onDuty(owner) then return end
  local model = GetEntityModel(entity)
  if blacklist[model] then
    CancelEvent()
    TacoV.AC.report(owner, 'Verbotenes Objekt', blacklist[model], 'kick')
    return
  end
  local now = os.time()
  local list = created[owner] or {}
  local keep = {}
  for _, t in ipairs(list) do if now - t < 10 then keep[#keep + 1] = t end end
  keep[#keep + 1] = now
  created[owner] = keep
  if #keep >= C.entitiesPerWindow then
    CancelEvent()
    created[owner] = {}
    TacoV.AC.report(owner, 'Entity-Flut', ('%d Entities in 10 s'):format(#keep), 'kick')
  end
end)

AddEventHandler('playerDropped', function()
  strikes[source], lastPos[source], grace[source], explosions[source], created[source] = nil, nil, nil, nil, nil
end)

-- Server-Teleports als erlaubt markieren
AddEventHandler('tacov:core:characterSelected', function(src) TacoV.AC.allowTeleport(src) end)

-- Team: letzte Meldungen und Testmeldung
RegisterNetEvent('tacov:ac:list', function()
  local src = source
  if not TacoV.Permissions.has(src, 'admin.ban') then return end
  TriggerClientEvent('tacov:ac:list', src, TacoV.DB.query('SELECT id, player_name, kind, details, action, created_at FROM ac_reports ORDER BY id DESC LIMIT 25') or {})
end)

RegisterCommand('actest', function(src)
  if src == 0 or not TacoV.Permissions.has(src, 'admin.config') then return end
  TacoV.AC.report(src, 'Test', 'Testmeldung aus dem Spiel (/actest) – keine Maßnahme', 'none')
end, false)
