-- Jobs (Phase 8, Konzept 3.2): Jobcenter, Ansprechpartner je Job, Firmenfahrzeuge, Routenpunkte.
-- Löhne, Obergrenzen und Führerschein-Pflicht stehen in config/economy.lua (TacoV.Config.Jobs); hier der Ablauf.
-- Alle Punkte sind Orte (Arten jobcenter, job, trash, busstop, address, tree, ore) und mit dem Orte-Creator verschiebbar.
-- Container, Haltestellen und Bäume werden im Spiel auf das nächste echte Objekt (Mülltonne, Haltestellenschild, Baum) gelegt.
TacoV = TacoV or {}
TacoV.Config = TacoV.Config or {}

TacoV.Config.JobRules = {
  actionSeconds = 4,          -- Dauer einer Handgriff-Aktion (Müll einladen, Paket abgeben)
  chopSeconds = 8,            -- Baum fällen / Erz abbauen
  vehicleRadius = 20.0,       -- Firmenfahrzeug muss in dieser Nähe stehen (Müll, Pakete, Haltestellen)
  pointRadius = 6.0,          -- Nähe zum Routenpunkt
  capLookbackSeconds = 3600,  -- Fenster für die Obergrenze je Stunde
  taxiBase = 25,              -- Taxameter: Grundpreis
  taxiPer100m = 1.8,          -- Taxameter: je 100 m
  taxiMaxSpeed = 45.0,        -- m/s, Plausibilitätsgrenze für gemeldete Strecke
  busWaitSeconds = 4,         -- Halt an der Haltestelle
  tools = { lumber = 'axe', mining = 'pickaxe' },
  snapRadius = 120.0,         -- so weit darf ein Punkt im Spiel auf das nächste echte Objekt springen
  snap = {                    -- Objekt-Modelle je Punktart
    trash = { 'prop_dumpster_01a', 'prop_dumpster_02a', 'prop_dumpster_02b', 'prop_dumpster_3a', 'prop_dumpster_4a', 'prop_dumpster_4b',
      'prop_bin_01a', 'prop_bin_05a', 'prop_bin_07a', 'prop_bin_08a', 'prop_bin_10a', 'prop_bin_11a', 'prop_bin_14a', 'prop_cs_bin_01' },
    stop = { 'prop_busstop_02', 'prop_busstop_04', 'prop_busstop_05', 'prop_bus_stop_sign' },
    chop = { 'prop_tree_pine_01', 'prop_tree_pine_02', 'prop_tree_cedar_02', 'prop_tree_cedar_03', 'prop_tree_cedar_04', 'prop_tree_cedar_s_01',
      'prop_tree_cedar_s_04', 'prop_tree_cedar_s_05', 'prop_tree_cedar_s_06', 'prop_s_pine_dead_01', 'prop_w_r_cedar_01', 'prop_w_r_cedar_dead',
      'prop_tree_fallen_pine_01', 'test_tree_cedar_trunk_001', 'test_tree_forest_trunk_01', 'test_tree_forest_trunk_04' },
  },
  orePerTrip = 5, logsPerTrip = 4, trashPerRoute = 8, busStops = 10, deliveryMin = 3, deliveryMax = 5,
}

TacoV.Config.JobDetails = {
  garbage  = { icon = 'box',  vehicle = 'trash',   points = 'trash',   desc = 'Route mit 8 Containern, Müllwagen vom Hof' },
  delivery = { icon = 'box',  vehicle = 'speedo',  points = 'shop',    desc = 'Pakete vom Depot an 3–5 Läden' },
  bus      = { icon = 'car',  vehicle = 'bus',     points = 'busstop', desc = 'Linie mit 10 Haltestellen' },
  taxi     = { icon = 'car',  vehicle = 'taxi',    points = 'shop',    desc = 'Fahrgäste nach Taxameter' },
  lumber   = { icon = 'leaf', vehicle = 'bison',   points = 'tree',    desc = 'Bäume fällen, Stämme zum Sägewerk', tool = 'axe' },
  mining   = { icon = 'tool', vehicle = nil,       points = 'ore',     desc = 'Erz abbauen, an den Händler verkaufen', tool = 'pickaxe' },
}

local L = TacoV.Config.Locations
local function loc(t) L[#L + 1] = t end

-- Jobcenter (Innenstadt) und Höfe mit Ansprechpartner (E) und Fahrzeugausgabe (spawn)
loc({ name = 'jobcenter', kind = 'jobcenter', label = 'Jobcenter', x = -268.5, y = -957.0, z = 31.2, heading = 205.0 })
loc({ name = 'job_garbage', kind = 'job', job = 'garbage', label = 'Müllhof', x = -322.0, y = -1546.0, z = 31.0, heading = 270.0,
  spawn = { x = -343.5, y = -1528.5, z = 27.7, h = 270.0 } })
loc({ name = 'job_delivery', kind = 'job', job = 'delivery', label = 'Depot Cypress Flats', x = 1211.0, y = -1397.0, z = 35.4, heading = 90.0,
  spawn = { x = 1222.5, y = -1390.5, z = 35.4, h = 0.0 } })
loc({ name = 'job_bus',      kind = 'job', job = 'bus',      label = 'Busdepot',           x = 453.1,  y = -600.3,  z = 28.6, heading = 90.0,  spawn = { x = 444.6, y = -584.0, z = 28.6, h = 90.0 } })
loc({ name = 'job_taxi',     kind = 'job', job = 'taxi',     label = 'Downtown Cab Co.',   x = 895.4,  y = -179.3,  z = 74.7, heading = 240.0, spawn = { x = 907.9, y = -167.5, z = 74.2, h = 237.0 } })
loc({ name = 'job_lumber', kind = 'job', job = 'lumber', label = 'Sägewerk Paleto', x = -556.5, y = 5326.0, z = 73.6, heading = 160.0,
  spawn = { x = -545.0, y = 5311.0, z = 73.6, h = 160.0 } })
loc({ name = 'job_mining',   kind = 'job', job = 'mining',   label = 'Mine Davis Quartz',  x = 2960.4, y = 2795.8,  z = 40.7, heading = 180.0 })

-- Müllroute (El Burro / La Mesa / Cypress Flats)
local trash = { { -230.5, -1513.9, 31.3 }, { -165.4, -1490.6, 33.0 }, { -82.3, -1480.2, 32.5 }, { 16.1, -1468.2, 30.0 },
  { 80.2, -1420.3, 29.3 }, { 120.4, -1360.5, 29.1 }, { 170.6, -1300.2, 29.2 }, { 228.1, -1240.4, 29.3 } }
for i, p in ipairs(trash) do loc({ name = 'trash_' .. i, kind = 'trash', label = 'Container ' .. i, x = p[1], y = p[2], z = p[3] }) end

-- Buslinie (Flughafen → Vespucci → Little Seoul → Innenstadt → Legion → Strawberry → Davis → Cypress → Depot)
local stops = { { -1037.1, -2731.0, 20.2 }, { -872.4, -2322.5, 13.9 }, { -1185.4, -1485.0, 4.4 }, { -1035.8, -1012.8, 2.2 }, { -728.5, -829.5, 23.2 },
  { -523.4, -652.0, 33.3 }, { -210.3, -824.0, 31.0 }, { 65.4, -1010.5, 29.4 }, { 238.1, -1275.6, 29.3 }, { 408.4, -1067.5, 29.3 } }
for i, p in ipairs(stops) do loc({ name = 'busstop_' .. i, kind = 'busstop', label = 'Haltestelle ' .. i, x = p[1], y = p[2], z = p[3] }) end

-- Zusätzliche Adressen (Pool neben den Läden; auch Taxi-Ziele) – per Orte-Creator ergänzen, Art „address“
local addresses = {}
for i, p in ipairs(addresses) do loc({ name = 'address_' .. i, kind = 'address', label = 'Adresse ' .. i, x = p[1], y = p[2], z = p[3] }) end

-- Bäume (Wald hinter dem Sägewerk Paleto)
local trees = { { -612.1, 5283.5, 73.5 }, { -625.4, 5262.9, 74.0 }, { -596.8, 5255.1, 73.0 }, { -640.2, 5290.7, 75.1 }, { -583.6, 5274.3, 72.8 }, { -655.0, 5272.5, 76.0 } }
for i, p in ipairs(trees) do loc({ name = 'tree_' .. i, kind = 'tree', label = 'Baum ' .. i, x = p[1], y = p[2], z = p[3] }) end

-- Erzadern (Steinbruch Davis Quartz)
local ores = { { 2948.3, 2790.5, 40.8 }, { 2932.6, 2805.1, 42.1 }, { 2956.9, 2822.4, 45.6 }, { 2978.5, 2812.0, 43.2 }, { 2990.3, 2787.4, 41.7 }, { 2940.1, 2768.8, 39.9 } }
for i, p in ipairs(ores) do loc({ name = 'ore_' .. i, kind = 'ore', label = 'Erzader ' .. i, x = p[1], y = p[2], z = p[3] }) end

TacoV.Config.Blips.jobcenter = { sprite = 407, color = 5, scale = 0.8, label = 'Jobcenter' }
TacoV.Config.Blips.job      = { sprite = 280, color = 5, scale = 0.7, label = 'Job' }
TacoV.Config.Blips.trash    = { sprite = 1, color = 0, scale = 0.0, label = 'Container', hidden = true }
TacoV.Config.Blips.busstop  = { sprite = 1, color = 0, scale = 0.0, label = 'Haltestelle', hidden = true }
TacoV.Config.Blips.address  = { sprite = 1, color = 0, scale = 0.0, label = 'Adresse', hidden = true }
TacoV.Config.Blips.tree     = { sprite = 1, color = 0, scale = 0.0, label = 'Baum', hidden = true }
TacoV.Config.Blips.ore      = { sprite = 1, color = 0, scale = 0.0, label = 'Erzader', hidden = true }

-- NPC-Creator: Aufgabe „Job-Ansprechpartner“ (steht an einem job-/jobcenter-Ort)
local T = TacoV.Config.PedTasks
T[#T + 1] = { id = 'job', label = 'Job-Ansprechpartner' }
T[#T + 1] = { id = 'jobcenter', label = 'Jobcenter' }
