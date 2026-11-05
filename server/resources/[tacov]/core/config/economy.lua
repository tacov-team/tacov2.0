-- Wirtschafts-Config (Konzept 3). Alle Beträge in Dollar, Zeiten in Minuten.
TacoV = TacoV or {}
TacoV.Config = TacoV.Config or {}

TacoV.Config.Economy = {
  accounts = { 'bank', 'cash', 'black' },     -- Girokonto, Bargeld (Item), Schwarzgeld (Item)
  bank = {
    transferDailyLimit = 50000,
    transferFeePercent = 1,
    transferFeeFrom = 10000,
    invoiceDueDays = 7,
    atmWithdrawMax = 5000,
    debtGarnishPercent = 20,
  },
  cash = { weightPer1000 = 0.1 },
  tax = {
    income = { default = 8, min = 5, max = 15 },
    propertyYearly = { default = 2, min = 1, max = 4 },
    vehicleYearly = { default = 1, min = 0.5, max = 2 },
    sales = { default = 5, min = 3, max = 10 },
  },
  fuel = { pricePerLiter = { default = 2.50, min = 1.80, max = 4.00 } },
  treasury = { salaryReserveWeeks = 2 },
  blackMoney = { enabled = true, launderLossPercent = 30, launderRight = 'launder' },
  targets = { carHours = 10, apartmentHours = 40, houseHours = 80, sportscarHours = 200, tolerancePercent = 15 },
}

-- Jobs zum Start (Konzept 3): Lohn je Auftrag und Obergrenze je Stunde
TacoV.Config.Jobs = {
  garbage  = { label = 'Müllabfuhr',   pay = 180,  hourlyCap = 400, license = nil },
  delivery = { label = 'Lieferfahrer', pay = { 150, 260 }, hourlyCap = 450, license = 'B' },
  bus      = { label = 'Busfahrer',    pay = 300,  hourlyCap = 450, license = 'C' },
  taxi     = { label = 'Taxi',         pay = 'meter', hourlyCap = 500, license = 'B' },
  lumber   = { label = 'Holzfäller',   pay = 220,  hourlyCap = 420, license = nil },
  mining   = { label = 'Bergbau',      pay = 240,  hourlyCap = 450, license = nil },
}

-- Fraktionsgehälter je Dienststunde (Konzept 2), linear von Rang 1 bis 12
TacoV.Config.Salaries = {
  lspd = { 250, 600 }, lsmd = { 250, 550 }, dmv = { 200, 400 }, government = { 300, 700 }, doj = { 300, 650 },
}
