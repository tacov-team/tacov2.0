-- Fraktionen (Punkte 9.1–9.3, Client): F6-Menü (Mitglieder, Kasse, Lager, Fahrzeuge, Umkleide, Rechte, Protokoll),
-- Stempeluhr/Lager/Garage/Umkleide als E-Punkte, Einladen über das X-Rad, Fraktionsfahrzeuge, Team-Verwaltung.
TacoV = TacoV or {}
TacoV.Factions = {}

local F = TacoV.Config.Factions
local data = nil          -- letzte Übersicht vom Server
local pending = nil       -- Untermenü, das nach dem nächsten 'data' geöffnet wird
local function notify(kind, text) TacoV.UI.send('notify', { kind = kind, text = text }) end
local function fmt(n) return (tostring(math.floor(n or 0)):reverse():gsub('(%d%d%d)', '%1.'):reverse():gsub('^%.', '')) .. ' $' end
local function has(right) return data and (data.rights[right] or data.rights.leader) or false end

-- Charakterdaten (Fraktion, Rang, Dienst) live übernehmen
RegisterNetEvent('tacov:core:characterUpdated', function(d)
  local c = TacoV.Client.character
  if not c then return end
  for k, v in pairs(d) do c[k] = v end
  for _, k in ipairs({ 'faction', 'factionRank', 'factionLabel', 'factionRankName' }) do if d[k] == nil then c[k] = nil end end
  TacoV.Hud.refresh()
end)

-- ---------------------------------------------------------------- Untermenüs

local function openMembers()
  local items = {}
  for _, m in ipairs(data.members) do
    items[#items + 1] = { id = 'm_' .. m.id, label = m.name .. (m.me and ' (du)' or ''), icon = 'user', sub = m.rankName,
      badge = m.online and 'online' or nil, section = m.rank >= 9 and 'Führung' or (m.rank >= 3 and 'Mitglieder' or 'Anwärter'), dim = not m.online }
  end
  TacoV.Menu.open({ id = 'faction_members', title = 'Mitglieder', icon = 'group', info = ('%d / %s'):format(data.memberCount, data.cap > 0 and data.cap or '∞'), items = items },
    function(id)
      local cid = tonumber(id:sub(3))
      local m
      for _, x in ipairs(data.members) do if x.id == cid then m = x end end
      if not m or m.me then return end
      local acts = {}
      if has('ranks_manage') then
        if m.rank < data.maxRank - 1 then acts[#acts + 1] = { id = 'up', label = 'Befördern', icon = 'plus', sub = TacoV.Factions.rankLabel(m.rank + 1) } end
        if m.rank > 1 then acts[#acts + 1] = { id = 'down', label = 'Degradieren', icon = 'back', sub = TacoV.Factions.rankLabel(m.rank - 1) } end
        acts[#acts + 1] = { id = 'set', label = 'Rang eingeben', icon = 'settings' }
      end
      if has('kick') then acts[#acts + 1] = { id = 'kick', label = 'Entlassen', icon = 'x', sub = '5 Tage Sperre' } end
      if has('leader') then acts[#acts + 1] = { id = 'leader', label = 'Leitung übergeben', icon = 'shield', sub = 'Du wirst Co-Leader' } end
      if #acts == 0 then notify('info', 'Keine Rechte für Mitgliederaktionen.') return end
      TacoV.Menu.open({ id = 'faction_member', title = m.name, icon = 'user', info = m.rankName, items = acts }, function(aid)
        if aid == 'up' then TriggerServerEvent('tacov:factions:member', 'rank', cid, m.rank + 1)
        elseif aid == 'down' then TriggerServerEvent('tacov:factions:member', 'rank', cid, m.rank - 1)
        elseif aid == 'set' then
          TacoV.UI.ask({ title = 'Rang', label = ('1–%d'):format(data.maxRank), numeric = true, value = tostring(m.rank) }, function(v)
            if tonumber(v) then TriggerServerEvent('tacov:factions:member', 'rank', cid, tonumber(v)) end
          end)
        elseif aid == 'kick' then TriggerServerEvent('tacov:factions:member', 'kick', cid)
        elseif aid == 'leader' then TriggerServerEvent('tacov:factions:member', 'leader', cid) end
        pending = 'members'
        TacoV.Menu.close()
      end)
    end)
end

function TacoV.Factions.rankLabel(r) return data and data.ranks[r] and data.ranks[r].name or ('Rang ' .. r) end

local function openTreasury()
  local items = {
    { id = 'balance', label = 'Kassenstand', icon = 'cash', sub = data.treasury and fmt(data.treasury) or 'nur ab Rang 9 sichtbar', dim = true },
    { id = 'deposit', label = 'Einzahlen', icon = 'plus', sub = 'Vom Konto in die Kasse' },
  }
  if has('treasury_withdraw') then
    items[#items + 1] = { id = 'withdraw', label = 'Auszahlen', icon = 'card', sub = data.dailyMoneyLeft and ('Heute noch ' .. fmt(data.dailyMoneyLeft)) or 'ohne Tageslimit' }
  end
  if has('treasury_view') then items[#items + 1] = { id = 'journal', label = 'Journal', icon = 'doc', sub = 'Letzte 30 Buchungen' } end
  TacoV.Menu.open({ id = 'faction_treasury', title = 'Kasse', icon = 'cash', info = data.label, items = items }, function(id)
    if id == 'deposit' or id == 'withdraw' then
      TacoV.UI.ask({ title = id == 'deposit' and 'Einzahlen' or 'Auszahlen', label = 'Betrag in $', numeric = true }, function(v)
        if tonumber(v) then pending = 'treasury' TriggerServerEvent('tacov:factions:treasury', id, tonumber(v)) end
      end)
    elseif id == 'journal' then TriggerServerEvent('tacov:factions:journal') end
  end)
end
RegisterNetEvent('tacov:factions:journal', function(rows)
  local items = {}
  for i, r in ipairs(rows) do
    local incoming = r.to_type == 'faction'
    items[#items + 1] = { id = 'j' .. i, label = (incoming and '+ ' or '− ') .. fmt(r.amount), icon = incoming and 'plus' or 'x',
      sub = ('%s · %s%s'):format(r.reason, r.first_name and (r.first_name .. ' ' .. r.last_name) or 'System', r.note and (' · ' .. r.note) or ''), dim = true }
  end
  if #items == 0 then items[1] = { id = 'none', label = 'Keine Buchungen', dim = true } end
  TacoV.Menu.open({ id = 'faction_journal', title = 'Kassenjournal', icon = 'doc', items = items }, function() end)
end)

local function openVehicles()
  local items = {}
  for _, v in ipairs(data.vehicles) do
    items[#items + 1] = { id = 'v_' .. v.id, label = v.label, icon = 'car', sub = ('%s · ab %s'):format(v.model, TacoV.Factions.rankLabel(v.min_rank)), dim = v.min_rank > data.rank }
  end
  if has('settings') then
    items[#items + 1] = { id = 'add', label = 'Fahrzeug hinzufügen', icon = 'plus', sub = 'Modellname, Bezeichnung, Mindestrang', section = 'Leitung' }
    if #data.vehicles > 0 then items[#items + 1] = { id = 'remove', label = 'Fahrzeug entfernen', icon = 'x' } end
  end
  if #items == 0 then items[1] = { id = 'none', label = 'Noch keine Fahrzeuge eingetragen', dim = true } end
  TacoV.Menu.open({ id = 'faction_vehicles', title = 'Fahrzeuge', icon = 'car', info = 'Abholung an der Fraktionsgarage', items = items }, function(id)
    if id:sub(1, 2) == 'v_' then TacoV.Menu.close() TriggerServerEvent('tacov:factions:vehicle', tonumber(id:sub(3)))
    elseif id == 'add' then
      TacoV.UI.ask({ title = 'Fahrzeug', label = 'Modell (z. B. police)' }, function(model)
        if not model or model == '' then return end
        TacoV.UI.ask({ title = 'Fahrzeug', label = 'Bezeichnung', value = model }, function(label)
          TacoV.UI.ask({ title = 'Fahrzeug', label = 'Mindestrang (1–12)', numeric = true, value = '3' }, function(rank)
            pending = 'vehicles'
            TriggerServerEvent('tacov:factions:vehicleAdd', model, label, tonumber(rank) or 3)
          end)
        end)
      end)
    elseif id == 'remove' then
      local list = {}
      for _, v in ipairs(data.vehicles) do list[#list + 1] = { id = 'r_' .. v.id, label = v.label, icon = 'x', sub = v.model } end
      TacoV.Menu.open({ id = 'faction_vehicle_remove', title = 'Fahrzeug entfernen', icon = 'x', items = list }, function(rid)
        pending = 'vehicles'
        TriggerServerEvent('tacov:factions:vehicleRemove', tonumber(rid:sub(3)))
        TacoV.Menu.close()
      end)
    end
  end)
end

local function openWardrobe()
  local items = {}
  for _, o in ipairs(data.outfits) do
    items[#items + 1] = { id = 'o_' .. o.id, label = o.name, icon = 'bag', sub = ('ab %s'):format(TacoV.Factions.rankLabel(o.min_rank)), dim = o.min_rank > data.rank }
  end
  items[#items + 1] = { id = 'civil', label = 'Zivilkleidung', icon = 'user', sub = 'Zurück zur gemerkten Kleidung', section = 'Wechseln' }
  if has('settings') then
    items[#items + 1] = { id = 'save', label = 'Aktuelle Kleidung als Dienstkleidung speichern', icon = 'plus', section = 'Leitung' }
    if #data.outfits > 0 then items[#items + 1] = { id = 'delete', label = 'Dienstkleidung löschen', icon = 'x' } end
  end
  TacoV.Menu.open({ id = 'faction_wardrobe', title = 'Umkleide', icon = 'bag', info = data.label, items = items }, function(id)
    if id:sub(1, 2) == 'o_' then TriggerServerEvent('tacov:factions:wardrobe', 'wear', { id = tonumber(id:sub(3)) })
    elseif id == 'civil' then TriggerServerEvent('tacov:factions:wardrobe', 'civil', {})
    elseif id == 'save' then
      TacoV.UI.ask({ title = 'Dienstkleidung', label = 'Name' }, function(name)
        if not name or name == '' then return end
        TacoV.UI.ask({ title = 'Dienstkleidung', label = 'Ab Rang (1–12)', numeric = true, value = '1' }, function(rank)
          local comps, props = TacoV.Appearance.readClothes(PlayerPedId())
          pending = 'wardrobe'
          TriggerServerEvent('tacov:factions:wardrobe', 'save', { name = name, minRank = tonumber(rank) or 1, components = comps, props = props })
        end)
      end)
    elseif id == 'delete' then
      local list = {}
      for _, o in ipairs(data.outfits) do list[#list + 1] = { id = 'd_' .. o.id, label = o.name, icon = 'x' } end
      TacoV.Menu.open({ id = 'faction_outfit_delete', title = 'Löschen', icon = 'x', items = list }, function(did)
        pending = 'wardrobe'
        TriggerServerEvent('tacov:factions:wardrobe', 'delete', { id = tonumber(did:sub(3)) })
        TacoV.Menu.close()
      end)
    end
  end)
end

local function openRanks()
  local items = {}
  for r = data.maxRank, 1, -1 do
    local rk = data.ranks[r]
    items[#items + 1] = { id = 'r_' .. r, label = ('%d · %s'):format(r, rk.name), icon = 'shield', sub = #rk.rights .. ' Rechte', dim = r >= data.rank and not has('leader') }
  end
  TacoV.Menu.open({ id = 'faction_ranks', title = 'Ränge und Rechte', icon = 'settings', info = 'Nur die Leitung', items = items }, function(id)
    local r = tonumber(id:sub(3))
    local rk = data.ranks[r]
    local set = {}
    for _, flag in ipairs(rk.rights) do set[flag] = true end
    local acts = { { id = 'name', label = 'Rangname ändern', icon = 'doc', sub = rk.name } }
    for flag, label in pairs(data.rightLabels) do
      if flag ~= 'leader' then acts[#acts + 1] = { id = 't_' .. flag, label = label, icon = set[flag] and 'check' or 'x', badge = set[flag] and 'An' or 'Aus', section = 'Rechte' } end
    end
    table.sort(acts, function(a, b) return (a.section or '') .. a.label < (b.section or '') .. b.label end)
    TacoV.Menu.open({ id = 'faction_rank', title = ('Rang %d'):format(r), icon = 'shield', info = rk.name, items = acts }, function(aid)
      if aid == 'name' then
        TacoV.UI.ask({ title = 'Rangname', label = 'Name', value = rk.name, maxLength = 32 }, function(v)
          if v and v ~= '' then pending = 'ranks' TriggerServerEvent('tacov:factions:rank', r, { name = v }) end
        end)
      elseif aid:sub(1, 2) == 't_' then
        pending = 'ranks'
        TriggerServerEvent('tacov:factions:rank', r, { toggle = aid:sub(3) })
      end
    end)
  end)
end

RegisterNetEvent('tacov:factions:log', function(rows)
  local items = {}
  for i, r in ipairs(rows) do items[#items + 1] = { id = 'l' .. i, label = r.text, icon = 'doc', sub = tostring(r.created_at), dim = true } end
  if #items == 0 then items[1] = { id = 'none', label = 'Noch keine Einträge', dim = true } end
  TacoV.Menu.open({ id = 'faction_log', title = 'Protokoll', icon = 'doc', items = items }, function() end)
end)

-- ---------------------------------------------------------------- Hauptmenü (F6)

local function openMain()
  local items = {
    { id = 'duty', label = data.duty and 'Dienst beenden' or 'Dienst beginnen', icon = 'clock', sub = 'An der Stempeluhr im Fraktionsgebäude',
      badge = data.duty and 'im Dienst' or nil, section = 'Dienst' },
    { id = 'members', label = 'Mitglieder', icon = 'group', sub = ('%d Mitglieder'):format(data.memberCount), section = 'Fraktion' },
    { id = 'treasury', label = 'Kasse', icon = 'cash', sub = data.treasury and fmt(data.treasury) or 'Einzahlen' },
    { id = 'storage', label = 'Lager', icon = 'box', sub = has('storage_view') and 'Im Fraktionsgebäude' or 'Kein Zugriff', dim = not has('storage_view') },
    { id = 'vehicles', label = 'Fahrzeuge', icon = 'car', sub = ('%d eingetragen · Garage'):format(#data.vehicles) },
    { id = 'wardrobe', label = 'Umkleide', icon = 'bag', sub = ('%d Dienstkleidungen'):format(#data.outfits) },
  }
  if has('settings') then items[#items + 1] = { id = 'ranks', label = 'Ränge und Rechte', icon = 'settings', sub = 'Rangnamen, Rechte je Rang', section = 'Leitung' } end
  if has('treasury_view') then items[#items + 1] = { id = 'log', label = 'Protokoll', icon = 'doc', sub = 'Letzte 40 Einträge' } end
  items[#items + 1] = { id = 'leave', label = 'Austreten', icon = 'x', sub = '5 Tage Sperre für andere Fraktionen', section = 'Ich' }
  TacoV.Menu.open({ id = 'faction', title = data.label, icon = 'shield', info = ('%s · Funk %s'):format(data.rankName, tostring(data.channel or '–')), items = items },
    function(id)
      if id == 'duty' then TacoV.Menu.close() TriggerServerEvent('tacov:factions:duty')
      elseif id == 'members' then openMembers()
      elseif id == 'treasury' then openTreasury()
      elseif id == 'storage' then TacoV.Menu.close() TriggerServerEvent('tacov:factions:storage')
      elseif id == 'vehicles' then openVehicles()
      elseif id == 'wardrobe' then openWardrobe()
      elseif id == 'ranks' then openRanks()
      elseif id == 'log' then TriggerServerEvent('tacov:factions:log')
      elseif id == 'leave' then
        TacoV.Menu.open({ id = 'faction_leave', title = 'Wirklich austreten?', icon = 'x', items = {
          { id = 'yes', label = 'Ja, austreten', icon = 'x' }, { id = 'no', label = 'Abbrechen', icon = 'back' } } }, function(a)
          if a == 'yes' then TriggerServerEvent('tacov:factions:leave') end
          TacoV.Menu.close()
        end)
      end
    end)
end

function TacoV.Factions.openMenu(sub)
  pending = sub or 'main'
  TriggerServerEvent('tacov:factions:open')
end

RegisterNetEvent('tacov:factions:data', function(d)
  data = d or nil
  if not data then TacoV.Menu.close() return end
  local what = pending or 'main'
  pending = nil
  if what == 'main' then openMain()
  elseif what == 'members' then openMembers()
  elseif what == 'treasury' then openTreasury()
  elseif what == 'vehicles' then openVehicles()
  elseif what == 'wardrobe' then openWardrobe()
  elseif what == 'ranks' then openRanks() end
end)

-- ---------------------------------------------------------------- E-Punkte im Fraktionsgebäude

local function myPoint(kind)
  local c = TacoV.Client.character
  if not c or not c.faction then return false end
  local loc = TacoV.Client.nearestLocation(kind, 2.5)
  if not loc or loc.name:match('([^_]+)$') ~= c.faction then return false end
  return loc
end
TacoV.Prompt.register({ id = 'faction_duty', label = 'Stempeluhr', order = 10, when = function() return myPoint('faction_duty') end,
  run = function() TriggerServerEvent('tacov:factions:duty') end })
TacoV.Prompt.register({ id = 'faction_storage', label = 'Fraktionslager', order = 10, when = function() return myPoint('faction_storage') end,
  run = function() TriggerServerEvent('tacov:factions:storage') end })
TacoV.Prompt.register({ id = 'faction_wardrobe', label = 'Umkleide', order = 10, when = function() return myPoint('faction_wardrobe') end,
  run = function() TacoV.Factions.openMenu('wardrobe') end })
TacoV.Prompt.register({ id = 'faction_garage', label = 'Fraktionsgarage', order = 10, when = function() return myPoint('faction_garage') end,
  run = function() TacoV.Factions.openMenu('vehicles') end })

-- ---------------------------------------------------------------- Einladen (X-Rad) und Antwort

TacoV.Interact.register({ id = 'faction_invite', label = 'In Fraktion einladen', icon = 'shield', order = 40,
  when = function(ctx) local c = TacoV.Client.character return ctx.player ~= nil and c and c.faction ~= nil end,
  run = function(ctx) TriggerServerEvent('tacov:factions:invite', ctx.player) end })

RegisterNetEvent('tacov:factions:invited', function(d)
  if TacoV.UI.current() then notify('info', ('Einladung von %s in %s – schließe erst die Ansicht.'):format(d.by, d.label)) end
  TacoV.Menu.open({ id = 'faction_invite', title = 'Einladung', icon = 'shield', info = d.label, note = ('%s lädt dich ein. Beitritt als Anwärter (Rang 1).'):format(d.by),
    items = { { id = 'yes', label = 'Annehmen', icon = 'check' }, { id = 'no', label = 'Ablehnen', icon = 'x' } },
    onClose = function() TriggerServerEvent('tacov:factions:inviteAnswer', false) end }, function(id)
    TriggerServerEvent('tacov:factions:inviteAnswer', id == 'yes')
    TacoV.Menu.close()
  end)
end)

-- ---------------------------------------------------------------- Fraktionsfahrzeug

RegisterNetEvent('tacov:factions:spawnVehicle', function(d)
  local hash = GetHashKey(d.model)
  if not IsModelInCdimage(hash) then notify('error', ('Modell „%s“ gibt es nicht.'):format(d.model)) return end
  RequestModel(hash)
  local t = GetGameTimer()
  while not HasModelLoaded(hash) and GetGameTimer() - t < 8000 do Wait(20) end
  if not HasModelLoaded(hash) then notify('error', 'Fahrzeugmodell konnte nicht geladen werden.') return end
  local s = d.spawn
  local veh = CreateVehicle(hash, s.x, s.y, s.z, s.h or 0.0, true, false)
  t = GetGameTimer()
  while not DoesEntityExist(veh) and GetGameTimer() - t < 3000 do Wait(20) end
  if not DoesEntityExist(veh) then return end
  SetModelAsNoLongerNeeded(hash)
  SetEntityAsMissionEntity(veh, true, true)
  SetVehicleNumberPlateText(veh, d.plate)
  SetVehicleOnGroundProperly(veh)
  SetVehicleDoorsLocked(veh, 1)
  Entity(veh).state:set('fuel', TacoV.Vehicles.tankOf(veh), true)
  Entity(veh).state:set('faction', d.faction, true)
  SetVehicleFuelLevel(veh, 100.0)
  notify('success', ('Fahrzeug %s steht bereit.'):format(d.plate))
end)

-- ---------------------------------------------------------------- Team: Fraktionen verwalten

local adminList = {}
RegisterNetEvent('tacov:factions:adminList', function(list)
  adminList = list
  local items = {}
  for _, f in ipairs(list) do
    items[#items + 1] = { id = 'f_' .. f.id, label = f.label, icon = 'shield',
      sub = ('%s · %d Mitglieder · Cap %s · Funk %s'):format(f.type == 'state' and 'Staat' or 'Kriminell', f.members, f.cap > 0 and f.cap or '∞', tostring(f.channel or '–')) }
  end
  items[#items + 1] = { id = 'create', label = 'Kriminelle Fraktion anlegen', icon = 'plus', sub = 'Kennung, Name, Cap', section = 'Neu' }
  TacoV.Menu.open({ id = 'factions_admin', title = 'Fraktionen', icon = 'shield', info = 'Team-Verwaltung', items = items }, function(id)
    if id == 'create' then
      TacoV.UI.ask({ title = 'Fraktion', label = 'Kennung (klein, ohne Leerzeichen)' }, function(fid)
        if not fid or fid == '' then return end
        TacoV.UI.ask({ title = 'Fraktion', label = 'Anzeigename', value = fid }, function(label)
          TacoV.UI.ask({ title = 'Fraktion', label = 'Cap (Mitglieder)', numeric = true, value = tostring(F.gang.cap) }, function(cap)
            TriggerServerEvent('tacov:factions:admin', 'create', { id = fid, label = label, cap = tonumber(cap) })
            TacoV.Menu.close()
          end)
        end)
      end)
      return
    end
    local fid = id:sub(3)
    local f
    for _, x in ipairs(adminList) do if x.id == fid then f = x end end
    local acts = {
      { id = 'leader', label = 'Leader einsetzen', icon = 'user', sub = 'Server-ID eines Spielers' },
      { id = 'member', label = 'Mitglied setzen', icon = 'group', sub = 'Server-ID und Rang' },
      { id = 'remove', label = 'Spieler aus Fraktion entfernen', icon = 'x', sub = 'Server-ID' },
    }
    if f and f.type ~= 'state' then acts[#acts + 1] = { id = 'dissolve', label = 'Fraktion auflösen', icon = 'warn', sub = 'Kasse an den Staat, Mitglieder gesperrt', section = 'Gefahr' } end
    TacoV.Menu.open({ id = 'faction_admin_one', title = f and f.label or fid, icon = 'shield', items = acts }, function(aid)
      if aid == 'dissolve' then
        TacoV.UI.ask({ title = 'Auflösen', label = 'Zur Bestätigung „AUFLOESEN“ eingeben' }, function(v)
          if v == 'AUFLOESEN' then TriggerServerEvent('tacov:factions:admin', 'dissolve', { faction = fid }) TacoV.Menu.close() end
        end)
        return
      end
      TacoV.UI.ask({ title = 'Spieler', label = 'Server-ID', numeric = true }, function(sid)
        if not tonumber(sid) then return end
        if aid == 'leader' then TriggerServerEvent('tacov:factions:admin', 'setLeader', { faction = fid, target = tonumber(sid) }) TacoV.Menu.close()
        elseif aid == 'remove' then TriggerServerEvent('tacov:factions:admin', 'remove', { target = tonumber(sid) }) TacoV.Menu.close()
        else
          TacoV.UI.ask({ title = 'Rang', label = '1–12', numeric = true, value = '1' }, function(rank)
            TriggerServerEvent('tacov:factions:admin', 'setMember', { faction = fid, target = tonumber(sid), rank = tonumber(rank) or 1 })
            TacoV.Menu.close()
          end)
        end
      end)
    end)
  end)
end)
function TacoV.Factions.openAdmin() TriggerServerEvent('tacov:factions:admin', 'list') end
