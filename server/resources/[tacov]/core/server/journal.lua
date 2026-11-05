-- Journal: die einzige Stelle, an der Geld entsteht, verschwindet oder den Besitzer wechselt.
-- Kein Modul schreibt Kontostände direkt (Konzept 1, Grundsatz "Der Server entscheidet"; Phase 2, Regeln für den Bau).
TacoV = TacoV or {}
TacoV.Journal = {}

local KINDS = { bank = true, cash = true, black = true }

--- Holt (oder legt an) das Konto eines Besitzers.
function TacoV.Journal.account(ownerType, ownerId)
  local row = TacoV.DB.single('SELECT id, balance, debt FROM accounts WHERE owner_type = ? AND owner_id = ?', { ownerType, ownerId })
  if row then return row end
  local id = TacoV.DB.insert('INSERT INTO accounts (owner_type, owner_id, balance) VALUES (?, ?, 0)', { ownerType, ownerId })
  return { id = id, balance = 0, debt = 0 }
end

--- Bucht einen Betrag zwischen zwei Konten (oder von/nach "Welt", wenn from/to nil ist).
--- kind: 'bank' | 'cash' | 'black'. Für cash/black werden nur Journal-Zeilen geschrieben; die Items hält das Inventar.
--- Gibt true, nil oder false, Fehlergrund zurück.
function TacoV.Journal.move(kind, from, to, amount, reason, opts)
  opts = opts or {}
  if not KINDS[kind] then return false, 'kind' end
  amount = TacoV.Util.money(amount)
  if amount <= 0 then return false, 'amount' end
  reason = TacoV.Util.cleanText(reason or 'unbekannt', 64)

  local queries = {}
  if kind == 'bank' then
    if from then
      local acc = TacoV.Journal.account(from.type, from.id)
      if acc.balance < amount and not opts.allowNegative then
        return false, 'insufficient'
      end
      queries[#queries + 1] = { 'UPDATE accounts SET balance = balance - ? WHERE id = ?', { amount, acc.id } }
    end
    if to then
      local acc = TacoV.Journal.account(to.type, to.id)
      queries[#queries + 1] = { 'UPDATE accounts SET balance = balance + ? WHERE id = ?', { amount, acc.id } }
    end
  end
  queries[#queries + 1] = {
    'INSERT INTO journal (kind, from_type, from_id, to_type, to_id, amount, reason, note, actor_character_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
    { kind, from and from.type, from and from.id, to and to.type, to and to.id, amount, reason,
      opts.note and TacoV.Util.cleanText(opts.note, 255) or nil, opts.actor },
  }
  local ok = TacoV.DB.transaction(queries)
  if not ok then return false, 'db' end
  return true
end

--- Kontostand eines Besitzers.
function TacoV.Journal.balance(ownerType, ownerId)
  return TacoV.Journal.account(ownerType, ownerId).balance
end

--- Summe aller Geldmengen (für den Geldmengen-Report, Konzept 3 Abschnitt 7).
function TacoV.Journal.totals()
  local bank = TacoV.DB.scalar("SELECT COALESCE(SUM(balance),0) FROM accounts WHERE owner_type <> 'state'") or 0
  local state = TacoV.DB.scalar("SELECT COALESCE(SUM(balance),0) FROM accounts WHERE owner_type = 'state'") or 0
  return { bank = bank, state = state }
end

exports('journalMove', TacoV.Journal.move)
exports('journalBalance', TacoV.Journal.balance)
