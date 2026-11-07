-- Blitzer und Kfz-Steuer (Konzept 3.4, Punkte 4.12/4.13)
TacoV = TacoV or {}
TacoV.Config = TacoV.Config or {}

TacoV.Config.Traffic = {
  tolerance = 5,            -- km/h über dem Limit ohne Folgen
  radius = 18.0,            -- Messbereich um den Blitzer
  cooldownSeconds = 60,     -- je Fahrzeug und Blitzer
  -- Bußgeld und Punkte nach Überschreitung (km/h über Limit, ab Toleranz)
  fines = {
    { upTo = 10,  fine = 100,  points = 0 },
    { upTo = 20,  fine = 250,  points = 0 },
    { upTo = 30,  fine = 500,  points = 1 },
    { upTo = 50,  fine = 1000, points = 2 },
    { upTo = 999, fine = 2000, points = 3 },
  },
  -- Kfz-Steuer: 1 % des Kaufpreises je Jahr, wöchentlich anteilig (Kaufpreis * 0,01 / 52); Prüfung stündlich
  taxPercentPerYear = 1.0,
  taxIntervalDays = 7,
}

-- Sechs Blitzer an großen Straßen (Vorschlag 07.11.2026, je mit Tempolimit; per /ort setzen blitzer_<n> speedcam verschiebbar)
local L = TacoV.Config.Locations
local function add(t) L[#L + 1] = t end
add({ name = 'blitzer_1', kind = 'speedcam', label = 'Blitzer Olympic Freeway',     limit = 120, x = -300.00, y = -1180.00, z = 29.00 })
add({ name = 'blitzer_2', kind = 'speedcam', label = 'Blitzer Del Perro Freeway',   limit = 120, x = -1480.00, y = -280.00, z = 44.00 })
add({ name = 'blitzer_3', kind = 'speedcam', label = 'Blitzer Vinewood Boulevard',  limit = 70,  x = 240.00, y = 230.00, z = 106.00 })
add({ name = 'blitzer_4', kind = 'speedcam', label = 'Blitzer Great Ocean Highway', limit = 120, x = -2600.00, y = 1950.00, z = 20.00 })
add({ name = 'blitzer_5', kind = 'speedcam', label = 'Blitzer Route 68 Harmony',    limit = 90,  x = 1180.00, y = 2700.00, z = 38.00 })
add({ name = 'blitzer_6', kind = 'speedcam', label = 'Blitzer Senora Freeway',      limit = 120, x = 2400.00, y = 2950.00, z = 46.00 })
TacoV.Config.Blips.speedcam = nil -- Blitzer sind nicht auf der Karte
