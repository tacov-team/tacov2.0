-- Verletzungen und Erste Hilfe (Punkt 6.8, Konzept 5.5 / 4): Bodyshot, Softcore. Stufen nach Lebenspunkten (max. 200).
TacoV = TacoV or {}
TacoV.Config = TacoV.Config or {}

TacoV.Config.Health = {
  light = 150,                 -- darunter: leicht verletzt (Hinweis)
  medium = 90,                 -- darunter: mittel verletzt (Humpeln, kein Sprint)
  downedMinutes = 15,          -- bewusstlos bis Koma
  stabilizeMinutes = 10,       -- Erste-Hilfe-Kit am Bewusstlosen verlängert
  kitHeal = 60,                -- Erste-Hilfe-Kit: Lebenspunkte
  bandageHeal = 25,
  hospitalFee = 500,           -- Koma: Krankenhaus (vom Konto, auch ins Minus) + Bargeld geht verloren
  hospitalMinutes = 5,         -- Aufenthalt nach Koma (Bewegung gesperrt)
  hospital = vector4(298.6, -584.4, 43.3, 70.0),   -- Pillbox Hill, Empfang
  respawnBed = vector4(311.2, -592.4, 43.3, 160.0),
}
