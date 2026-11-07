-- NPC-Werkstatt (Konzept 3.4, Punkt 4.11): Reparatur, Upgrades mit Stufen, Zubehör. Preise in Prozent vom Kaufpreis.
TacoV = TacoV or {}
TacoV.Config = TacoV.Config or {}

TacoV.Config.Workshop = {
  repairPercent = 10,      -- volle Reparatur kostet bis zu 10 % des Kaufpreises (anteilig am Schaden)
  repairMin = 150,
  -- Upgrades: GTA-Mod-Typ, Stufen Straße/Sport/Rennen = Index 0/1/2, Preis je Stufe in % des Kaufpreises
  upgrades = {
    { id = 'engine',       label = 'Motor',    icon = 'engine', modType = 11, levels = { 'Straße', 'Sport', 'Rennen' }, pct = { 5, 10, 20 } },
    { id = 'brakes',       label = 'Bremsen',  icon = 'speed',  modType = 12, levels = { 'Straße', 'Sport', 'Rennen' }, pct = { 5, 10, 20 } },
    { id = 'transmission', label = 'Getriebe', icon = 'tool',   modType = 13, levels = { 'Straße', 'Sport', 'Rennen' }, pct = { 5, 10, 20 } },
    { id = 'suspension',   label = 'Fahrwerk', icon = 'wrench', modType = 15, levels = { 'Straße', 'Sport', 'Rennen' }, pct = { 5, 10, 20 } },
    { id = 'turbo',        label = 'Turbo',    icon = 'fitness', toggle = 18, levels = { 'Turbolader' }, pct = { 10 } },
  },
  -- Zubehör
  paintPrice = 500,        -- Lackierung (eine Farbe)
  tintPrice = 300,         -- Fensterfarbe
  wheelsPrice = 800,       -- Felgen
  colors = {               -- GTA-Farbindex
    { id = 0, label = 'Schwarz metallic' }, { id = 111, label = 'Weiß' }, { id = 4, label = 'Silber' }, { id = 11, label = 'Anthrazit' },
    { id = 27, label = 'Rot' }, { id = 35, label = 'Kirschrot' }, { id = 38, label = 'Orange' }, { id = 89, label = 'Gelb' },
    { id = 53, label = 'Grün' }, { id = 61, label = 'Blau' }, { id = 64, label = 'Dunkelblau' }, { id = 145, label = 'Violett' },
    { id = 137, label = 'Pink' }, { id = 107, label = 'Beige' }, { id = 96, label = 'Braun' }, { id = 120, label = 'Türkis' },
  },
  tints = { { id = 0, label = 'Keine' }, { id = 3, label = 'Leicht getönt' }, { id = 2, label = 'Dunkel' }, { id = 1, label = 'Schwarz' } },
  wheelTypes = {
    { id = 0, label = 'Sport' }, { id = 1, label = 'Muscle' }, { id = 2, label = 'Lowrider' }, { id = 3, label = 'SUV' },
    { id = 4, label = 'Offroad' }, { id = 5, label = 'Tuner' }, { id = 7, label = 'High End' },
  },
  wheelsPerType = 8,       -- erste 8 Felgen je Typ zur Auswahl
}

local L = TacoV.Config.Locations
local function add(t) L[#L + 1] = t end
add({ name = 'workshop_burton',  kind = 'workshop', label = 'Werkstatt Burton',     x = -337.40, y = -136.90, z = 39.00 })
add({ name = 'workshop_beach',   kind = 'workshop', label = 'Werkstatt Flughafen',  x = -1155.50, y = -2007.20, z = 13.20 })
add({ name = 'workshop_harmony', kind = 'workshop', label = 'Werkstatt Harmony',    x = 1175.00, y = 2640.10, z = 37.80 })
add({ name = 'workshop_paleto',  kind = 'workshop', label = 'Werkstatt Paleto Bay', x = 110.60, y = 6626.10, z = 31.80 })
add({ name = 'workshop_elburro', kind = 'workshop', label = 'Werkstatt El Burro',   x = 731.50, y = -1088.80, z = 22.20 })
TacoV.Config.Blips.workshop = { sprite = 446, color = 5, scale = 0.7, label = 'Werkstatt' }
