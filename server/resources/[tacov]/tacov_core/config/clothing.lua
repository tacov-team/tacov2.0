-- Kleidung, Friseur, Tattoo, Chirurg (Phase 6, Punkte 6.2/6.3). Alle Spielteile in jedem Laden, Preise je Kategorie
-- (Entscheidung 08.11.2026). Orte sind per Orte-Creator verschiebbar.
TacoV = TacoV or {}
TacoV.Config = TacoV.Config or {}

TacoV.Config.Clothing = {
  maxOutfits = 10,
  -- Preis je geänderter Kategorie (Komponenten-Index bzw. 'p'..Prop-Index)
  prices = {
    ['11'] = 60, ['8'] = 25, ['3'] = 0, ['4'] = 40, ['6'] = 35, ['9'] = 120, ['5'] = 60, ['1'] = 45, ['10'] = 15, ['7'] = 15,
    p0 = 25, p1 = 20, p2 = 15, p6 = 30, p7 = 15,
  },
  barber = { hair = 40, beard = 20, eyebrows = 15, makeup = 25, blush = 15, lipstick = 15, chesthair = 20 },
  surgeonPrice = 5000,
  surgeonDays = 30,
}

local L = TacoV.Config.Locations
local function add(t) L[#L + 1] = t end
local shops = {
  { 'Grapeseed', 1693.32, 4823.48, 41.06 }, { 'Rockford Hills', -712.22, -155.35, 37.42 }, { 'Vespucci', -1192.94, -772.69, 17.33 },
  { 'La Mesa', 425.24, -806.01, 28.49 }, { 'Burton', -162.66, -303.40, 38.73 }, { 'Strawberry', 75.95, -1392.89, 28.38 },
  { 'Vespucci Canals', -822.19, -1074.13, 10.33 }, { 'Morningwood', -1450.71, -236.83, 48.81 }, { 'Paleto Bay', 4.25, 6512.81, 30.88 },
  { 'Harmony', 615.18, 2762.93, 41.09 }, { 'Route 68', 1196.79, 2709.56, 37.22 }, { 'Chumash', -3171.45, 1043.86, 19.86 },
  { 'Great Chaparral', -1100.96, 2710.21, 18.11 }, { 'Vespucci Beach', -1207.65, -1456.88, 4.38 }, { 'Hawick', 121.76, -224.60, 53.56 },
}
for i, sh in ipairs(shops) do add({ name = ('clothing_%d'):format(i), kind = 'clothing', label = 'Kleiderladen ' .. sh[1], x = sh[2], y = sh[3], z = sh[4] }) end
local barbers = {
  { -814.30, -183.80, 36.60 }, { 136.80, -1708.40, 28.30 }, { -1282.60, -1116.80, 6.00 }, { 1931.50, 3729.70, 31.80 },
  { 1212.80, -472.90, 65.20 }, { -32.90, -152.30, 56.10 }, { -278.10, 6228.50, 30.70 },
}
for i, b in ipairs(barbers) do add({ name = ('barber_%d'):format(i), kind = 'barber', label = 'Friseur ' .. i, x = b[1], y = b[2], z = b[3] }) end
local tattoos = {
  { 1322.64, -1651.97, 52.28 }, { -1153.67, -1425.68, 4.95 }, { 322.14, 180.47, 103.59 },
  { -3170.07, 1075.06, 20.83 }, { 1864.63, 3747.74, 33.03 }, { -293.71, 6200.04, 31.49 },
}
for i, t in ipairs(tattoos) do add({ name = ('tattoo_%d'):format(i), kind = 'tattoo', label = 'Tattoo-Studio ' .. i, x = t[1], y = t[2], z = t[3] }) end
add({ name = 'surgeon_pillbox', kind = 'surgeon', label = 'Schönheitschirurg (Pillbox)', x = 309.93, y = -602.94, z = 43.29 })

TacoV.Config.Blips.clothing = { sprite = 73, color = 47, scale = 0.7, label = 'Kleiderladen' }
TacoV.Config.Blips.barber   = { sprite = 71, color = 4, scale = 0.7, label = 'Friseur' }
TacoV.Config.Blips.tattoo   = { sprite = 75, color = 1, scale = 0.7, label = 'Tattoo-Studio' }
TacoV.Config.Blips.surgeon  = { sprite = 403, color = 2, scale = 0.7, label = 'Schönheitschirurg' }
