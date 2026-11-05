-- Kontofunktionen für andere Module: Zahlen, Überweisen, Staat. Alles läuft über das Journal.
TacoV = TacoV or {}
TacoV.Accounts = {}

local function charOwner(source)
  local c = TacoV.Characters.get(source)
  return c and { type = 'character', id = c.id } or nil
end

--- Charakter zahlt vom Girokonto an einen Empfänger (Staat, Firma, Fraktion, Charakter).
function TacoV.Accounts.pay(source, to, amount, reason, note)
  local from = charOwner(source)
  if not from then return false, 'character' end
  local ok, err = TacoV.Journal.move('bank', from, to, amount, reason, { note = note, actor = from.id })
  if ok then TacoV.Accounts.push(source) end
  return ok, err
end

--- Empfänger erhält Geld auf das Girokonto (Lohn, Verkauf, Erstattung).
function TacoV.Accounts.receive(source, from, amount, reason, note)
  local to = charOwner(source)
  if not to then return false, 'character' end
  local ok, err = TacoV.Journal.move('bank', from, to, amount, reason, { note = note, actor = to.id })
  if ok then TacoV.Accounts.push(source) end
  return ok, err
end

--- Steuern an den Staatshaushalt (Konzept 3: Einkommenssteuer, Umsatzsteuer, Kfz-Steuer).
function TacoV.Accounts.tax(source, amount, reason)
  return TacoV.Accounts.pay(source, { type = 'state', id = 0 }, amount, reason)
end

--- Schickt dem Client den aktuellen Kontostand.
function TacoV.Accounts.push(source)
  local c = TacoV.Characters.get(source)
  if not c then return end
  TriggerClientEvent('tacov:core:bank', source, TacoV.Journal.balance('character', c.id))
end

exports('accountPay', TacoV.Accounts.pay)
exports('accountReceive', TacoV.Accounts.receive)
exports('accountTax', TacoV.Accounts.tax)
