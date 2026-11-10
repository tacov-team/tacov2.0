-- LSPD (Punkte 9.4–9.6). Entscheidungen 10.11.2026: Handschellen jederzeit im Nahbereich, MDT überall im Dienst,
-- Haft höchstens 60 min je Festnahme (läuft nur online), Geldstrafe höchstens 10.000 $ ab Rang 3, automatische Meldungen
-- für Schüsse und Blitzer, Grundspiel-Streifenwagen, Ausrüstung über einen Kaufpunkt (wird nicht zurückgegeben).
TacoV = TacoV or {}
TacoV.Config = TacoV.Config or {}

TacoV.Config.Police = {
  faction = 'lspd',
  fineMax = 10000, fineMinRank = 3,
  jailMaxMinutes = 60, jailMinRank = 3, jailRadius = 12.0,
  cuffRange = 3.0, searchRange = 3.0,
  impoundMinRank = 3, impoundFee = 750,       -- Auslösung nach Beschlagnahme (statt der normalen Verwahrgebühr)
  warrantMinRank = 5,
  mdtMaxResults = 20,
  -- Kaufpunkt für Ausrüstung (aus der eigenen Tasche, vergünstigt; Waffen sind Dienstwaffen und im MDT nicht meldepflichtig)
  equipment = {
    { item = 'weapon_flashlight',   price = 50,   minRank = 1 },
    { item = 'weapon_nightstick',   price = 80,   minRank = 1 },
    { item = 'weapon_stungun',      price = 250,  minRank = 2 },
    { item = 'weapon_combatpistol', price = 600,  minRank = 3 },
    { item = 'ammo_pistol',         price = 2,    minRank = 3, amount = 50 },
    { item = 'weapon_carbine',      price = 2500, minRank = 6 },
    { item = 'ammo_rifle',          price = 4,    minRank = 6, amount = 60 },
    { item = 'armor',               price = 300,  minRank = 2 },
    { item = 'first_aid',           price = 60,   minRank = 1 },
    { item = 'radio',               price = 0,    minRank = 1 },
  },
  -- Startliste Fahrzeuge (wird einmalig in faction_vehicles eingetragen; die Leitung pflegt sie danach über F6)
  vehicles = {
    { model = 'police',  label = 'Streifenwagen',        minRank = 3 },
    { model = 'police2', label = 'Streifenwagen Buffalo', minRank = 3 },
    { model = 'police3', label = 'Streifenwagen Interceptor', minRank = 4 },
    { model = 'policeb', label = 'Motorrad',             minRank = 5 },
    { model = 'policet', label = 'Transporter',          minRank = 6 },
  },
}

TacoV.Config.Dispatch = {
  numbers = { ['110'] = { faction = 'lspd', label = 'Polizei' }, ['112'] = { faction = 'lsmd', label = 'Rettungsdienst' } },
  callCooldown = 30,           -- Sekunden zwischen zwei Notrufen eines Spielers
  keepMinutes = 30,            -- offene Einsätze verfallen
  shots = { enabled = true, cooldown = 90, blur = 60.0 },          -- Schussmeldung: je Spieler höchstens alle 90 s, Ort um bis zu 60 m versetzt
  speedcam = { enabled = true, overKmh = 40 },                    -- Blitzer ab 40 km/h drüber
  statuses = { free = 'Frei', busy = 'Im Einsatz', pause = 'Pause' },
}

local L = TacoV.Config.Locations
local function loc(t) L[#L + 1] = t end
-- Wache Mission Row (Startwerte, per Orte-Creator verschiebbar)
loc({ name = 'faction_duty_lspd',      kind = 'faction_duty',      label = 'LSPD Stempeluhr', x = 441.1, y = -981.9, z = 30.7 })
loc({ name = 'faction_wardrobe_lspd',  kind = 'faction_wardrobe',  label = 'LSPD Umkleide',   x = 452.6, y = -992.8, z = 30.7 })
loc({ name = 'faction_storage_lspd',   kind = 'faction_storage',   label = 'LSPD Lager',      x = 459.0, y = -979.0, z = 30.7 })
loc({ name = 'faction_equipment_lspd', kind = 'faction_equipment', label = 'LSPD Ausrüstung', x = 452.3, y = -980.0, z = 30.7 })
loc({ name = 'faction_evidence_lspd',  kind = 'faction_evidence',  label = 'Asservatenkammer', x = 472.3, y = -990.4, z = 24.9 })
loc({ name = 'faction_garage_lspd',    kind = 'faction_garage',    label = 'LSPD Garage',     x = 454.6, y = -1017.4, z = 28.4,
  spawn = { x = 438.4, y = -1018.3, z = 28.0, h = 90.0 } })
loc({ name = 'jail_cell_1', kind = 'jail_cell', label = 'Zelle 1', x = 459.8, y = -994.3, z = 24.9 })
loc({ name = 'jail_cell_2', kind = 'jail_cell', label = 'Zelle 2', x = 459.5, y = -997.9, z = 24.9 })
loc({ name = 'jail_cell_3', kind = 'jail_cell', label = 'Zelle 3', x = 459.3, y = -1001.6, z = 24.9 })
loc({ name = 'jail_release', kind = 'jail_release', label = 'Entlassung', x = 432.0, y = -981.9, z = 30.7, heading = 90.0 })

for _, k in ipairs({ 'faction_equipment', 'faction_evidence', 'jail_cell', 'jail_release' }) do
  TacoV.Config.Blips[k] = { sprite = 1, color = 0, scale = 0.0, label = k, hidden = true }
end
