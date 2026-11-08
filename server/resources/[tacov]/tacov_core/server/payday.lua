-- Payday und Staatshaushalt (Punkt 8.8, Konzept 3.7): Fraktionsgehälter je volle Dienststunde aus dem Staatshaushalt,
-- Einkommensteuer darauf, Kürzung wenn die Reserve unter zwei Wochen Gehälter fällt; Übersicht für das Team (Welt → Staatshaushalt).
-- Dienst/Ränge kommen vollständig mit Phase 9 – bis dahin zählt die Spielzeit eines Fraktionsmitglieds als Dienstzeit.
TacoV = TacoV or {}
TacoV.Payday = {}

local STATE = { type = 'state', id = 0 }
local E = TacoV.Config.Economy
local seconds = {}   -- [src] = gezählte Sekunden seit der letzten Auszahlung

local function notify(src, kind, text) TriggerClientEvent('tacov:core:notify', src, kind, text) end
local function fmt(n) return (tostring(math.floor(n or 0)):reverse():gsub('(%d%d%d)', '%1.'):reverse():gsub('^%.', '')) end

--- Stundengehalt: linear von Rang 1 bis 12 zwischen den beiden Config-Werten
function TacoV.Payday.salary(faction, rank)
  local s = TacoV.Config.Salaries[faction]
  if not s then return 0 end
  rank = math.max(1, math.min(12, tonumber(rank) or 1))
  return TacoV.Util.money(s[1] + (s[2] - s[1]) * (rank - 1) / 11)
end

--- Wochenbedarf an Gehältern (alle Fraktionsmitglieder, angenommen 10 Dienststunden je Woche)
local function weeklySalaryNeed()
  local rows = TacoV.DB.query('SELECT faction, faction_rank FROM characters WHERE faction IS NOT NULL AND deleted_at IS NULL') or {}
  local sum = 0
  for _, r in ipairs(rows) do sum = sum + TacoV.Payday.salary(r.faction, r.faction_rank) * 10 end
  return sum
end

--- Kürzungssatz in Prozent: unter der Reserve (Wochen × Wochenbedarf) wird anteilig gekürzt, nie nachgedruckt
function TacoV.Payday.cutPercent()
  local need = weeklySalaryNeed() * (E.treasury.salaryReserveWeeks or 2)
  if need <= 0 then return 0 end
  local balance = TacoV.Journal.balance('state', 0)
  if balance >= need then return 0 end
  return math.min(100, math.floor((1 - math.max(0, balance) / need) * 100))
end

local function payout(src, c)
  local gross = TacoV.Payday.salary(c.faction, c.faction_rank)
  if gross <= 0 then return end
  local cut = TacoV.Payday.cutPercent()
  gross = TacoV.Util.money(gross * (100 - cut) / 100)
  if gross <= 0 then notify(src, 'warn', 'Payday: Der Staatshaushalt ist leer – kein Gehalt.') return end
  local tax = TacoV.Util.money(gross * (E.tax.income.default or 8) / 100)
  local ok = TacoV.Journal.move('bank', STATE, { type = 'character', id = c.id }, gross - tax, 'gehalt', { actor = c.id, note = c.faction, allowNegative = false })
  if not ok then notify(src, 'warn', 'Payday: Der Staatshaushalt ist leer – kein Gehalt.') return end
  -- Steuer bleibt beim Staat (Gehalt kam von dort): nur als Journalzeile ausweisen
  TacoV.DB.insert('INSERT INTO payday_log (character_id, faction, faction_rank, gross, tax, cut_percent) VALUES (?, ?, ?, ?, ?, ?)',
    { c.id, c.faction, c.faction_rank or 1, gross, tax, cut })
  TacoV.Accounts.push(src)
  notify(src, 'success', ('Payday: %s $ Gehalt (%s, %d %% Steuer%s).'):format(fmt(gross - tax), c.faction, E.tax.income.default or 8,
    cut > 0 and (', gekürzt um ' .. cut .. ' %') or ''))
  TacoV.Log.write('money', ('Payday %s: %s $ (%s Rang %d%s)'):format(c.first_name .. ' ' .. c.last_name, fmt(gross - tax), c.faction, c.faction_rank or 1,
    cut > 0 and (', Kürzung ' .. cut .. ' %') or ''), { characterId = c.id })
end

CreateThread(function()
  while true do
    Wait(60000)
    for _, pid in ipairs(GetPlayers()) do
      local src = tonumber(pid)
      local c = TacoV.Characters.get(src)
      if c and c.faction and TacoV.Config.Salaries[c.faction] then
        seconds[src] = (seconds[src] or 0) + 60
        if seconds[src] >= 3600 then
          seconds[src] = seconds[src] - 3600
          payout(src, c)
        end
      else
        seconds[src] = nil
      end
    end
  end
end)
AddEventHandler('tacov:core:characterUnloaded', function(src) seconds[src] = nil end)
AddEventHandler('playerDropped', function() seconds[source] = nil end)

-- ---------------------------------------------------------------- Staatshaushalt (Team-Menü → Welt)

RegisterNetEvent('tacov:treasury:show', function()
  local src = source
  if not TacoV.Permissions.has(src, 'admin.config') and not TacoV.Permissions.has(src, 'admin.locations') then return end
  local balance = TacoV.Journal.balance('state', 0)
  local rows = TacoV.DB.query(
    "SELECT reason, SUM(CASE WHEN to_type = 'state' THEN amount ELSE 0 END) AS income, SUM(CASE WHEN from_type = 'state' THEN amount ELSE 0 END) AS expense " ..
    "FROM journal WHERE (to_type = 'state' OR from_type = 'state') AND at > DATE_SUB(NOW(), INTERVAL 7 DAY) GROUP BY reason ORDER BY reason") or {}
  local totals = TacoV.Journal.totals()
  local paidJobs = tonumber(TacoV.DB.scalar('SELECT COALESCE(SUM(amount), 0) FROM job_pay WHERE paid_at > DATE_SUB(NOW(), INTERVAL 7 DAY)')) or 0
  for _, r in ipairs(rows) do r.income, r.expense = tonumber(r.income) or 0, tonumber(r.expense) or 0 end
  TriggerClientEvent('tacov:treasury:data', src, { balance = tonumber(balance) or 0, rows = rows, bank = tonumber(totals.bank) or 0, cut = TacoV.Payday.cutPercent(),
    reserveWeeks = E.treasury.salaryReserveWeeks or 2, weeklyNeed = weeklySalaryNeed(), jobsWeek = paidJobs })
end)
