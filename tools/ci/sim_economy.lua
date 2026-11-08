-- Kaufzeiten-Simulation (Punkt 8.9, Konzept 3.9): rechnet aus den Config-Werten die Spielstunden bis zum ersten Auto (Klasse D),
-- zur Wohnung, zum Haus und zum Sportwagen (Klasse A) und schlägt an, wenn die Ziele um mehr als die Toleranz verfehlt werden.
-- Lauf: lua5.4 tools/ci/sim_economy.lua   (aus dem Repo-Wurzelverzeichnis)
-- Modell (bewusst einfach, alle Annahmen hier oben):
--   Kalibrierbasis = Mittel der Obergrenzen aller Jobs (Konzept: ein fleißiger Spieler erreicht die Obergrenze) minus Einkommensteuer,
--   abzüglich Lebenshaltung je Stunde; Startgeld zählt nicht (Sparzeit aus eigener Arbeit); vor dem ersten Auto: Führerschein B + Zulassung.
--   Geprüft (CI rot) werden Auto und Sportwagen (Job-Einkommen). Wohnung und Haus werden ausgegeben, aber erst mit Phase 10
--   (Immobilienpreise, Fraktions- und Firmeneinkommen) geprüft – siehe docs/entscheidungen.md 08.11.
local UTIL = 1.0           -- Auslastung der Obergrenze
local FOOD_PER_HOUR = 0    -- Lebenshaltung je Stunde (Essen/Trinken) – Kalibrierbasis ohne Nebenkosten
local FUEL_PER_HOUR = 0    -- Tanken je Stunde
local APARTMENT_PRICE = 25000  -- Konzept 3.5 (Wohnung) – bis Phase 10 fester Wert
local HOUSE_PRICE = 80000      -- Konzept 3.5 (Haus, günstigstes) – bis Phase 10 fester Wert

-- Config-Dateien ohne FiveM laden
TacoV = { Config = {} }
function vector3(x, y, z) return { x = x, y = y, z = z } end
function vector4(x, y, z, w) return { x = x, y = y, z = z, w = w } end
local base = 'server/resources/[tacov]/tacov_core/config/'
for _, f in ipairs({ 'core.lua', 'economy.lua', 'vehicles.lua', 'dmv.lua' }) do
  local chunk = assert(loadfile(base .. f))
  chunk()
end

local E, J, V, DMV = TacoV.Config.Economy, TacoV.Config.Jobs, TacoV.Config.Vehicles, TacoV.Config.DMV
local tax = (E.tax.income.default or 8) / 100

local capSum, n = 0, 0
for _, def in pairs(J) do capSum, n = capSum + def.hourlyCap, n + 1 end
local gross = capSum / n * UTIL
local net = gross * (1 - tax) - FOOD_PER_HOUR - FUEL_PER_HOUR

local function cheapest(class)
  local best
  for _, v in ipairs(V.list) do if v.class == class and (not best or v.price < best) then best = v.price end end
  return best or 0
end
local licenseB = (DMV.school and DMV.school.B and DMV.school.B.price) or 500
local registration = DMV.registrationFee or 150
local carD = cheapest('D') + licenseB + registration
local carA = cheapest('A') + registration

local T = E.targets
local rows = {
  { 'Erstes Auto (Klasse D)', carD, T.carHours, true },
  { 'Wohnung', APARTMENT_PRICE, T.apartmentHours, false },
  { 'Haus', HOUSE_PRICE, T.houseHours, false },
  { 'Sportwagen (Klasse A)', carA, T.sportscarHours, true },
}
print(('Einkommen: %.0f $/h brutto (%.0f %% Auslastung), %.0f $/h netto nach Steuer und Lebenshaltung'):format(gross, UTIL * 100, net))
print(('%-24s %10s %8s %8s %8s'):format('Ziel', 'Kosten', 'Soll h', 'Ist h', 'Abw.'))
local failed = false
for _, r in ipairs(rows) do
  local hours = r[2] / net
  local dev = (hours - r[3]) / r[3] * 100
  local bad = math.abs(dev) > T.tolerancePercent
  if bad and r[4] then failed = true end
  print(('%-24s %10.0f %8.0f %8.1f %+7.0f%% %s'):format(r[1], r[2], r[3], hours, dev,
    bad and (r[4] and '  <-- außerhalb der Toleranz' or '  (Hinweis: Prüfung ab Phase 10)') or ''))
end
if failed then
  print(('FEHLER: Kaufzeiten weichen mehr als %d %% vom Ziel ab – Löhne, Obergrenzen oder Preise in der Config anpassen.'):format(T.tolerancePercent))
  os.exit(1)
end
print('OK: Kaufzeiten innerhalb der Toleranz.')
