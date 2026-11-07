-- Fahrzeuge (Konzept 3, Abschnitt 4): Klassen, Kaufliste, Garagen, Tankstellen, Kaufhäuser, Verwahrhof.
-- Preise liegen in den Spannen der Konzept-Tabelle. Alle Orte sind mit /ort setzen <name> <art> verschiebbar.
TacoV = TacoV or {}
TacoV.Config = TacoV.Config or {}

TacoV.Config.Vehicles = {
  -- Klassen: Level-Voraussetzung, nötiger Führerschein, Kofferraum (kg), Tank (Liter), Kaufhaus
  classes = {
    D     = { label = 'Einstieg',     level = 0,  license = 'B', trunk = 20,  tank = 45,  dealer = 'autohaus', order = 1 },
    C     = { label = 'Alltag',       level = 0,  license = 'B', trunk = 40,  tank = 55,  dealer = 'autohaus', order = 2 },
    B     = { label = 'Gehoben',      level = 6,  license = 'B', trunk = 60,  tank = 65,  dealer = 'autohaus', order = 3 },
    A     = { label = 'Sport',        level = 10, license = 'B', trunk = 25,  tank = 70,  dealer = 'autohaus', order = 4 },
    S     = { label = 'Super',        level = 15, license = 'B', trunk = 25,  tank = 80,  dealer = 'autohaus', order = 5 },
    moto  = { label = 'Motorrad',     level = 0,  license = 'A', trunk = 10,  tank = 15,  dealer = 'autohaus', order = 6 },
    van   = { label = 'Transporter',  level = 0,  license = 'C', trunk = 120, tank = 80,  dealer = 'truck',    order = 7 },
    truck = { label = 'LKW',          level = 0,  license = 'C', trunk = 300, tank = 300, dealer = 'truck',    order = 8 },
  },

  -- Kaufliste (Grundspiel-Modelle). Reihenfolge = Anzeige im Kaufhaus.
  list = {
    -- D · Einstieg 4.000–8.000 $
    { model = 'asea',        label = 'Asea',           class = 'D', price = 4500 },
    { model = 'emperor',     label = 'Emperor',        class = 'D', price = 4000 },
    { model = 'regina',      label = 'Regina',         class = 'D', price = 4200 },
    { model = 'ingot',       label = 'Ingot',          class = 'D', price = 5500 },
    { model = 'dilettante',  label = 'Dilettante',     class = 'D', price = 6000 },
    { model = 'panto',       label = 'Panto',          class = 'D', price = 6500 },
    { model = 'blista',      label = 'Blista',         class = 'D', price = 7800 },
    -- C · Alltag 9.000–20.000 $
    { model = 'issi2',       label = 'Issi',           class = 'C', price = 9500 },
    { model = 'minivan',     label = 'Minivan',        class = 'C', price = 10500 },
    { model = 'prairie',     label = 'Prairie',        class = 'C', price = 11000 },
    { model = 'stratum',     label = 'Stratum',        class = 'C', price = 11500 },
    { model = 'rebel',       label = 'Rebel',          class = 'C', price = 12000 },
    { model = 'premier',     label = 'Premier',        class = 'C', price = 12500 },
    { model = 'washington',  label = 'Washington',     class = 'C', price = 13500 },
    { model = 'bison',       label = 'Bison',          class = 'C', price = 14000 },
    -- B · Gehoben 22.000–60.000 $
    { model = 'fugitive',    label = 'Fugitive',       class = 'B', price = 24000 },
    { model = 'schafter2',   label = 'Schafter',       class = 'B', price = 30000 },
    { model = 'sultan',      label = 'Sultan',         class = 'B', price = 32000 },
    { model = 'felon',       label = 'Felon',          class = 'B', price = 36000 },
    { model = 'oracle2',     label = 'Oracle',         class = 'B', price = 38000 },
    { model = 'rocoto',      label = 'Rocoto',         class = 'B', price = 40000 },
    { model = 'granger',     label = 'Granger',        class = 'B', price = 42000 },
    { model = 'f620',        label = 'F620',           class = 'B', price = 44000 },
    { model = 'baller2',     label = 'Baller',         class = 'B', price = 45000 },
    { model = 'dubsta',      label = 'Dubsta',         class = 'B', price = 48000 },
    -- A · Sport 70.000–180.000 $
    { model = 'comet2',      label = 'Comet',          class = 'A', price = 85000 },
    { model = 'ninef',       label = '9F',             class = 'A', price = 90000 },
    { model = 'elegy2',      label = 'Elegy RH8',      class = 'A', price = 95000 },
    { model = 'banshee',     label = 'Banshee',        class = 'A', price = 110000 },
    { model = 'feltzer2',    label = 'Feltzer',        class = 'A', price = 120000 },
    { model = 'jester',      label = 'Jester',         class = 'A', price = 140000 },
    { model = 'carbonizzare', label = 'Carbonizzare',  class = 'A', price = 150000 },
    { model = 'massacro',    label = 'Massacro',       class = 'A', price = 160000 },
    -- S · Super ab 250.000 $
    { model = 'entityxf',    label = 'Entity XF',      class = 'S', price = 300000 },
    { model = 'turismor',    label = 'Turismo R',      class = 'S', price = 320000 },
    { model = 'zentorno',    label = 'Zentorno',       class = 'S', price = 380000 },
    { model = 'adder',       label = 'Adder',          class = 'S', price = 450000 },
    -- Motorrad 3.000–40.000 $
    { model = 'faggio',      label = 'Faggio',         class = 'moto', price = 3000 },
    { model = 'pcj',         label = 'PCJ 600',        class = 'moto', price = 9500 },
    { model = 'hexer',       label = 'Hexer',          class = 'moto', price = 12000 },
    { model = 'daemon',      label = 'Daemon',         class = 'moto', price = 14000 },
    { model = 'nemesis',     label = 'Nemesis',        class = 'moto', price = 16000 },
    { model = 'akuma',       label = 'Akuma',          class = 'moto', price = 22000 },
    { model = 'bati',        label = 'Bati 801',       class = 'moto', price = 28000 },
    { model = 'double',      label = 'Double-T',       class = 'moto', price = 38000 },
    -- Transporter 30.000–60.000 $ (LKW-Kaufhaus)
    { model = 'pony',        label = 'Pony',           class = 'van', price = 30000 },
    { model = 'speedo',      label = 'Speedo',         class = 'van', price = 32000 },
    { model = 'rumpo',       label = 'Rumpo',          class = 'van', price = 34000 },
    { model = 'burrito3',    label = 'Burrito',        class = 'van', price = 35000 },
    -- LKW 60.000–120.000 $
    { model = 'mule',        label = 'Mule',           class = 'truck', price = 60000 },
    { model = 'benson',      label = 'Benson',         class = 'truck', price = 85000 },
    { model = 'packer',      label = 'Packer',         class = 'truck', price = 110000 },
    { model = 'phantom',     label = 'Phantom',        class = 'truck', price = 120000 },
  },

  -- Kaufhäuser: welche Klassen, Beschriftung
  dealers = {
    autohaus = { label = 'Autohaus', classes = { 'D', 'C', 'B', 'A', 'S', 'moto' } },
    truck    = { label = 'LKW-Kaufhaus', classes = { 'van', 'truck' } },
  },

  registrationFee = 150,     -- Zulassung (bis das DMV steht, beim Kauf fällig; Konzept 3)
  requireLicense = false,    -- Führerscheine kommen mit der Fahrschule (Block Fahrzeuge Teil 2)
  publicGarageDaily = 50,    -- öffentliche Garage: 50 $ je angefangenen Tag ab 24 h Standzeit
  publicGarageMaxDays = 7,   -- Deckel für die Garagengebühr
  impoundAfterHours = 24,    -- nicht geparkte Fahrzeuge werden nach 24 h verwahrt
  impoundFee = 500,          -- Auslösung
  plateFormat = 'LS %05d',   -- Kennzeichen (8 Zeichen)

  fuel = {
    consumptionPerSecond = 0.00035, -- Anteil des Tanks je Sekunde bei Vollgas (Leerlauf 20 % davon)
    npcTankMin = 0.25, npcTankMax = 0.70, -- Füllstand fremder Fahrzeuge beim ersten Einsteigen
    stationRadius = 12.0,   -- Tanken möglich in diesem Umkreis um die Tankstelle
    hudRadius = 45.0,       -- Tankstellenkarte im HUD ab dieser Entfernung
    amounts = { 10, 20, 40 }, -- Liter-Auswahl neben „Volltanken“
    kind = 'Benzin',
  },

  spawnClearRadius = 3.0, -- Ausfahrt muss frei sein
}

-- Orte des Fahrzeugmoduls: Garagen (category car/rig/air/sea), Tankstellen, Kaufhäuser, Verwahrhof.
-- garage: { x,y,z } = E-Punkt, spawn = Ausfahrt mit Blickrichtung
local L = TacoV.Config.Locations
local function add(t) L[#L + 1] = t end

-- Öffentliche Garagen (PKW/Motorrad)
add({ name = 'garage_alta',       kind = 'garage', category = 'car', label = 'Parkhaus Alta Street',
  x = 274.29, y = -334.15, z = 44.92, spawn = { x = 265.96, y = -332.30, z = 44.51, h = 250.68 } })
add({ name = 'garage_casino',     kind = 'garage', category = 'car', label = 'Parkplatz Casino',
  x = 883.96, y = -4.71, z = 78.76, spawn = { x = 895.39, y = -4.75, z = 78.35, h = 146.85 } })
add({ name = 'garage_sanandreas', kind = 'garage', category = 'car', label = 'Parkplatz San Andreas Avenue',
  x = -330.01, y = -780.33, z = 33.96, spawn = { x = -341.57, y = -767.45, z = 33.56, h = 92.61 } })
add({ name = 'garage_spanish',    kind = 'garage', category = 'car', label = 'Parkplatz Spanish Avenue',
  x = -1160.86, y = -741.41, z = 19.63, spawn = { x = -1145.20, y = -745.42, z = 19.26, h = 108.22 } })
add({ name = 'garage_downtown',   kind = 'garage', category = 'car', label = 'Parkplatz Downtown (Caears)',
  x = 69.84, y = 12.60, z = 68.96, spawn = { x = 60.80, y = 17.54, z = 68.82, h = 339.70 } })
add({ name = 'garage_seoul',      kind = 'garage', category = 'car', label = 'Parkplatz Little Seoul',
  x = -453.70, y = -786.78, z = 30.56, spawn = { x = -472.39, y = -787.71, z = 30.14, h = 180.52 } })
add({ name = 'garage_vinewood',   kind = 'garage', category = 'car', label = 'Parkplatz Vinewood (Laguna)',
  x = 364.37, y = 297.83, z = 103.49, spawn = { x = 375.09, y = 294.66, z = 102.86, h = 164.04 } })
add({ name = 'garage_airport',    kind = 'garage', category = 'car', label = 'Parkplatz Flughafen',
  x = -773.12, y = -2033.04, z = 8.88, spawn = { x = -779.77, y = -2040.18, z = 8.47, h = 315.34 } })
add({ name = 'garage_beach',      kind = 'garage', category = 'car', label = 'Parkplatz Vespucci Beach',
  x = -1185.32, y = -1500.64, z = 4.38, spawn = { x = -1188.14, y = -1487.95, z = 3.97, h = 124.06 } })
add({ name = 'garage_route68',    kind = 'garage', category = 'car', label = 'Parkplatz Route 68 (Motel)',
  x = 1137.77, y = 2663.54, z = 37.90, spawn = { x = 1127.70, y = 2647.84, z = 37.58, h = 1.41 } })
add({ name = 'garage_sandy_w',    kind = 'garage', category = 'car', label = 'Parkplatz Sandy Shores West',
  x = 883.99, y = 3649.67, z = 32.87, spawn = { x = 898.38, y = 3649.41, z = 32.36, h = 90.75 } })
add({ name = 'garage_sandy',      kind = 'garage', category = 'car', label = 'Parkplatz Sandy Shores',
  x = 1737.03, y = 3718.88, z = 34.05, spawn = { x = 1725.40, y = 3716.78, z = 34.15, h = 20.54 } })
add({ name = 'garage_paleto',     kind = 'garage', category = 'car', label = 'Parkplatz Paleto Bay',
  x = 76.88, y = 6397.30, z = 31.23, spawn = { x = 62.15, y = 6403.41, z = 30.81, h = 211.38 } })
add({ name = 'garage_port',       kind = 'garage', category = 'car', label = 'Parkplatz Hafen',
  x = 165.75, y = -3227.20, z = 5.89, spawn = { x = 168.34, y = -3236.10, z = 5.43, h = 272.05 } })
add({ name = 'garage_legion',     kind = 'garage', category = 'car', label = 'Parkhaus Legion Square',
  x = 213.20, y = -796.05, z = 30.86, spawn = { x = 222.02, y = -804.19, z = 30.26, h = 248.19 } })
add({ name = 'garage_grapeseed',  kind = 'garage', category = 'car', label = 'Parkplatz Grapeseed',
  x = 2552.68, y = 4671.80, z = 33.95, spawn = { x = 2550.17, y = 4681.96, z = 33.81, h = 17.05 } })
-- LKW-Parkplätze (Transporter, LKW)
add({ name = 'garage_rig_port',    kind = 'garage', category = 'rig', label = 'LKW-Parkplatz Hafen',
  x = 161.23, y = -3188.73, z = 5.97, spawn = { x = 167.00, y = -3203.89, z = 5.94, h = 271.27 } })
add({ name = 'garage_rig_paleto',  kind = 'garage', category = 'rig', label = 'LKW-Parkplatz Paleto',
  x = 137.67, y = 6632.99, z = 31.67, spawn = { x = 127.69, y = 6605.84, z = 31.93, h = 223.67 } })
add({ name = 'garage_rig_zancudo', kind = 'garage', category = 'rig', label = 'LKW-Parkplatz Zancudo',
  x = -2529.37, y = 2342.67, z = 33.06, spawn = { x = -2521.61, y = 2326.45, z = 33.13, h = 88.70 } })
add({ name = 'garage_rig_tataviam', kind = 'garage', category = 'rig', label = 'LKW-Parkplatz Tataviam',
  x = 2561.67, y = 476.68, z = 108.49, spawn = { x = 2561.67, y = 476.68, z = 108.49, h = 177.86 } })
add({ name = 'garage_rig_airport', kind = 'garage', category = 'rig', label = 'LKW-Parkplatz Flughafen',
  x = -41.24, y = -2550.63, z = 6.01, spawn = { x = -39.39, y = -2527.81, z = 6.08, h = 326.18 } })
-- Verwahrhof (Konzept: Impound, Mission Row)
add({ name = 'impound_missionrow', kind = 'impound', category = 'all', label = 'Verwahrhof Mission Row',
  x = 401.76, y = -1632.57, z = 29.29, spawn = { x = 396.55, y = -1643.93, z = 28.88, h = 321.91 } })
-- Kaufhäuser (Konzept: Premium Deluxe Motorsport, LKW am Hafen)
add({ name = 'dealer_autohaus', kind = 'dealer', dealer = 'autohaus', label = 'Premium Deluxe Motorsport',
  x = -45.47, y = -1097.70, z = 26.42, spawn = { x = -30.60, y = -1090.20, z = 26.50, h = 160.0 } })
add({ name = 'dealer_truck',    kind = 'dealer', dealer = 'truck',    label = 'LKW-Kaufhaus Hafen',
  x = 153.40, y = -3200.10, z = 5.90, spawn = { x = 167.00, y = -3203.89, z = 5.94, h = 271.27 } })
-- Tankstellen (Grundspiel)
local fuel = {
  { 'Great Chaparral', 49.4187, 2778.793, 58.043 }, { 'Route 68 West', 263.894, 2606.463, 44.983 },
  { 'Harmony', 1039.958, 2671.134, 39.550 }, { 'Harmony Ost', 1207.260, 2660.175, 37.899 },
  { 'Tataviam Nord', 2539.685, 2594.192, 37.944 }, { 'Grapeseed Süd', 2679.858, 3263.946, 55.240 },
  { 'Sandy Shores', 2005.055, 3773.887, 32.403 }, { 'Grapeseed', 1687.156, 4929.392, 42.078 },
  { 'Paleto Ost', 1701.314, 6416.028, 32.763 }, { 'Paleto Bay', 179.857, 6602.839, 31.868 },
  { 'Paleto West', -94.4619, 6419.594, 31.489 }, { 'Zancudo', -2554.996, 2334.40, 33.078 },
  { 'Richman Hills', -1800.375, 803.661, 138.651 }, { 'Morningwood', -1437.622, -276.747, 46.207 },
  { 'Pacific Bluffs', -2096.243, -320.286, 13.168 }, { 'Little Seoul', -724.619, -935.1631, 19.213 },
  { 'La Puerta', -526.019, -1211.003, 18.184 }, { 'Davis', -70.2148, -1761.792, 29.534 },
  { 'Strawberry', 265.648, -1261.309, 29.292 }, { 'El Burro', 819.653, -1028.846, 26.403 },
  { 'Cypress Flats', 1208.951, -1402.567, 35.224 }, { 'Mirror Park', 1181.381, -330.847, 69.316 },
  { 'Vinewood Hills', 620.843, 269.100, 103.089 }, { 'Tataviam', 2581.321, 362.039, 108.468 },
  { 'Grove Street', 176.631, -1562.025, 29.263 }, { 'La Puerta Süd', -319.292, -1471.715, 30.549 },
  { 'Sandy Shores Flugplatz', 1784.324, 3330.55, 41.253 },
}
for i, f in ipairs(fuel) do
  add({ name = ('fuel_%02d'):format(i), kind = 'fuel', label = 'Tankstelle ' .. f[1], x = f[2], y = f[3], z = f[4] })
end

TacoV.Config.Blips.garage  = { sprite = 357, color = 3, scale = 0.7, label = 'Parkplatz' }
TacoV.Config.Blips.impound = { sprite = 68,  color = 1, scale = 0.7, label = 'Verwahrhof' }
TacoV.Config.Blips.dealer  = { sprite = 225, color = 5, scale = 0.8, label = 'Kaufhaus' }
TacoV.Config.Blips.fuel    = { sprite = 361, color = 1, scale = 0.6, label = 'Tankstelle' }
