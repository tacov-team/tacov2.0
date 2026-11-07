-- Bank und Geldautomat (Konzept 3, Abschnitt 3): Einzahlen, Abheben, Überweisen, Kontoauszug.
-- Alles Geld läuft über das Journal; Bargeld ist ein Item im Inventar.
TacoV = TacoV or {}
TacoV.Bank = {}

local Cfg = TacoV.Config.Economy.bank
local STATE = { type = 'state', id = 0 }

function TacoV.Bank.accountNumber(characterId)
  return ('LS-%06d'):format(characterId)
end

local function parseAccount(text)
  local n = tostring(text or ''):match('^%s*LS%-?(%d+)%s*$')
  return n and tonumber(n) or nil
end

local function findCharacter(text)
  local id = parseAccount(text)
  if id then
    return TacoV.DB.single('SELECT id, first_name, last_name FROM characters WHERE id = ? AND deleted_at IS NULL',
      { id })
  end
  local first, last = tostring(text or ''):match('^%s*(%S+)%s+(.+)%s*$')
  if not first then return nil end
  return TacoV.DB.single(
    'SELECT id, first_name, last_name FROM characters WHERE first_name = ? AND last_name = ? AND deleted_at IS NULL',
    { first, TacoV.Util.cleanText(last, 32) })
end

local function transferredToday(characterId)
  return TacoV.DB.scalar(
    "SELECT COALESCE(SUM(amount), 0) FROM journal WHERE kind = 'bank' AND from_type = 'character' AND from_id = ? " ..
    "AND reason = 'ueberweisung' AND at >= CURDATE()",
    { characterId }
  ) or 0
end

local REASONS = {
  startgeld = 'Startgeld', einzahlung = 'Einzahlung', abhebung = 'Abhebung', ueberweisung = 'Überweisung', gebuehr = 'Gebühr',
  lohn = 'Lohn', gehalt = 'Gehalt', steuer = 'Steuer', einkauf = 'Einkauf', rechnung = 'Rechnung', strafe = 'Strafe', erstattung = 'Erstattung',
}

local function nameOf(ownerType, ownerId, cache)
  if ownerType == nil then return '—' end
  if ownerType == 'state' then return 'Staat' end
  if ownerType == 'character' then
    cache[ownerId] = cache[ownerId] or (function()
      local r = TacoV.DB.single('SELECT first_name, last_name FROM characters WHERE id = ?', { ownerId })
      return r and (r.first_name .. ' ' .. r.last_name) or ('Konto ' .. TacoV.Bank.accountNumber(ownerId))
    end)()
    return cache[ownerId]
  end
  return ownerType .. ' #' .. tostring(ownerId)
end

--- Letzte Buchungen des Girokontos.
function TacoV.Bank.statement(characterId, limit)
  local rows = TacoV.DB.query(
    "SELECT at, from_type, from_id, to_type, to_id, amount, reason, note FROM journal " ..
    "WHERE kind = 'bank' AND ((from_type = 'character' AND from_id = ?) OR (to_type = 'character' AND to_id = ?)) " ..
    "ORDER BY id DESC LIMIT ?",
    { characterId, characterId, limit or 20 }
  ) or {}
  local cache = {}
  local out = {}
  for _, r in ipairs(rows) do
    local outgoing = r.from_type == 'character' and r.from_id == characterId
    out[#out + 1] = {
      at = r.at, amount = outgoing and -r.amount or r.amount,
      reason = REASONS[r.reason] or r.reason, note = r.note,
      who = outgoing and nameOf(r.to_type, r.to_id, cache) or nameOf(r.from_type, r.from_id, cache),
    }
  end
  return out
end

local session = {} -- [source] = 'bank' | 'atm'

function TacoV.Bank.send(source)
  local c = TacoV.Characters.get(source)
  local inv = TacoV.Inventory.ofSource(source)
  if not c or not inv then return end
  local kind = session[source] or 'bank'
  TriggerClientEvent('tacov:bank:data', source, {
    kind = kind,
    title = kind == 'atm' and 'Geldautomat' or 'Fleeca Bank',
    account = TacoV.Bank.accountNumber(c.id),
    balance = TacoV.Journal.balance('character', c.id),
    cash = TacoV.Inventory.cash(inv),
    transferLeft = Cfg.transferDailyLimit > 0 and math.max(0, Cfg.transferDailyLimit - transferredToday(c.id)) or 0,
    noLimits = Cfg.transferDailyLimit == 0 and Cfg.atmWithdrawMax == 0,
    atmMax = Cfg.atmWithdrawMax,
    feePercent = Cfg.transferFeePercent, feeFrom = Cfg.transferFeeFrom,
    statement = TacoV.Bank.statement(c.id, 20),
  })
end

local function fail(src, text)
  TriggerClientEvent('tacov:core:notify', src, 'error', text)
end

-- kind: 'bank' (Schalter, Server prüft Nähe zum Ort) oder 'atm' (Client meldet Automatenposition)
RegisterNetEvent('tacov:bank:open', function(kind, atmPos)
  local src = source
  if not TacoV.Characters.get(src) then return end
  if kind == 'atm' then
    if type(atmPos) ~= 'vector3' or #(GetEntityCoords(GetPlayerPed(src)) - atmPos) > 3.0 then return end
  else
    kind = 'bank'
    local loc = TacoV.Locations.nearest(src, 'bank', 4.0)
    if not loc then return fail(src, 'Du bist an keinem Bankschalter.') end
  end
  session[src] = kind
  TacoV.Bank.send(src)
end)

RegisterNetEvent('tacov:bank:close', function()
  session[source] = nil
end)

RegisterNetEvent('tacov:bank:action', function(data)
  local src = source
  if type(data) ~= 'table' or not session[src] then return end
  local c = TacoV.Characters.get(src)
  local inv = TacoV.Inventory.ofSource(src)
  if not c or not inv then return end
  local me = { type = 'character', id = c.id }
  local amount = TacoV.Util.money(data.amount)
  if amount <= 0 then return fail(src, 'Ungültiger Betrag.') end

  if data.action == 'deposit' then
    if TacoV.Inventory.cash(inv) < amount then return fail(src, 'So viel Bargeld hast du nicht.') end
    local ok = TacoV.Inventory.remove(inv, 'cash', amount)
    if not ok then return fail(src, 'Einzahlung fehlgeschlagen.') end
    TacoV.Journal.move('cash', me, nil, amount, 'einzahlung', { actor = c.id })
    TacoV.Journal.move('bank', nil, me, amount, 'einzahlung', { actor = c.id })
    TacoV.Log.write('money', ('Einzahlung %d $'):format(amount), { characterId = c.id })
    TriggerClientEvent('tacov:core:notify', src, 'success', ('%s $ eingezahlt.'):format(amount))

  elseif data.action == 'withdraw' then
    if session[src] == 'atm' and Cfg.atmWithdrawMax > 0 and amount > Cfg.atmWithdrawMax then
      return fail(src, ('Am Automaten höchstens %d $ je Abhebung.'):format(Cfg.atmWithdrawMax))
    end
    if TacoV.Journal.balance('character', c.id) < amount then return fail(src, 'Nicht genug Guthaben.') end
    local ok, err = TacoV.Journal.move('bank', me, nil, amount, 'abhebung', { actor = c.id })
    if not ok then return fail(src, 'Abhebung fehlgeschlagen: ' .. tostring(err)) end
    local added, aerr = TacoV.Inventory.add(inv, 'cash', amount)
    if not added then
      TacoV.Journal.move('bank', nil, me, amount, 'erstattung', { actor = c.id, note = 'Abhebung zurück' })
      return fail(src, 'Bargeld passt nicht in die Tasche: ' .. tostring(aerr))
    end
    TacoV.Journal.move('cash', nil, me, amount, 'abhebung', { actor = c.id })
    TacoV.Log.write('money', ('Abhebung %d $ (%s)'):format(amount, session[src]), { characterId = c.id })
    TriggerClientEvent('tacov:core:notify', src, 'success', ('%s $ abgehoben.'):format(amount))

  elseif data.action == 'transfer' then
    if session[src] ~= 'bank' then return fail(src, 'Überweisungen nur am Schalter oder per Handy.') end
    local target = findCharacter(data.target)
    if not target then return fail(src, 'Empfänger nicht gefunden (Name oder Kontonummer LS-000000).') end
    if target.id == c.id then return fail(src, 'Du kannst dir nichts selbst überweisen.') end
    if Cfg.transferDailyLimit > 0 then
      local left = Cfg.transferDailyLimit - transferredToday(c.id)
      if amount > left then return fail(src, ('Tageslimit: heute noch %d $.'):format(math.max(0, left))) end
    end
    local fee = amount >= Cfg.transferFeeFrom and math.floor(amount * Cfg.transferFeePercent / 100) or 0
    if TacoV.Journal.balance('character', c.id) < amount + fee then return fail(src, 'Nicht genug Guthaben (inkl. Gebühr).') end
    local note = TacoV.Util.cleanText(data.note or '', 64)
    local ok, err = TacoV.Journal.move('bank', me, { type = 'character', id = target.id }, amount, 'ueberweisung', { actor = c.id, note = note })
    if not ok then return fail(src, 'Überweisung fehlgeschlagen: ' .. tostring(err)) end
    if fee > 0 then TacoV.Journal.move('bank', me, STATE, fee, 'gebuehr', { actor = c.id, note = 'Überweisung' }) end
    TacoV.Log.write('money', ('Überweisung %d $ an #%d (Gebühr %d)'):format(amount, target.id, fee), { characterId = c.id })
    TriggerClientEvent('tacov:core:notify', src, 'success', ('%s $ an %s %s überwiesen.'):format(amount, target.first_name, target.last_name))
    for tsrc, p in pairs(TacoV.Players.all()) do
      if p.characterId == target.id then
        TriggerClientEvent('tacov:core:notify', tsrc, 'info', ('%s $ von %s %s erhalten.'):format(amount, c.first_name, c.last_name))
        TacoV.Accounts.push(tsrc)
      end
    end
  else
    return
  end
  TacoV.Accounts.push(src)
  TacoV.Bank.send(src)
end)

AddEventHandler('tacov:core:characterUnloaded', function(source)
  session[source] = nil
end)
