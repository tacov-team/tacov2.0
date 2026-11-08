-- Anti-Cheat-Grundlage (Punkt 5.16): Schwellen. Eindeutige Fälle → Sicherheits-Kick/-Sperre + Meldung ans AC-Team.
TacoV = TacoV or {}
TacoV.Config = TacoV.Config or {}

TacoV.Config.AntiCheat = {
  checkSeconds = 2,            -- Takt der Positions-/Geschwindigkeitsprüfung
  footSpeedMax = 28.0,         -- m/s zu Fuß (Sprint ~7, Fall frei bis ~55 → Fall wird gesondert erkannt)
  vehicleSpeedMax = 125.0,     -- m/s (450 km/h)
  teleportGrace = 8,           -- Sekunden nach einem Server-Teleport ohne Prüfung
  strikesForKick = 3,          -- Auffälligkeiten innerhalb strikeWindow → Kick
  strikeWindow = 60,
  cashMismatchWarn = 1000,     -- Bargeld im Inventar weicht vom Journal ab (Hinweis)
  cashMismatchKick = 50000,    -- … starker Unterschied → Sicherheits-Kick
  explosionsPerWindow = 3,     -- Explosionen durch einen Spieler in 10 s → Kick
  entitiesPerWindow = 25,      -- vom Spieler erzeugte Netz-Entities in 10 s → Kick
  banHoursSecurity = 72,       -- Sicherheitssperre bei Wiederholung nach Kick (innerhalb 24 h)
  blacklistedModels = { 'prop_gascyl_02a', 'prop_ld_bomb_01', 'prop_bomb_01' },
}
