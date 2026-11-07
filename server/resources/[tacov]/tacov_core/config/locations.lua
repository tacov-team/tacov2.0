-- Orte aus docs/konzept/orte.md (Grundspiel-Koordinaten). Jeder Ort ist mit /ort setzen <name> <art> verschiebbar;
-- die Datenbank (Tabelle locations) überschreibt diese Vorgaben.
TacoV = TacoV or {}
TacoV.Config = TacoV.Config or {}

TacoV.Config.Locations = {
  -- Banken (Schalter): Fleeca-Filialen, Blaine County Savings Paleto, Pacific Standard
  { name = 'bank_legion',   kind = 'bank', label = 'Fleeca Legion Square',   x = 149.92,   y = -1040.47, z = 29.37, heading = 340.0 },
  { name = 'bank_burton',   kind = 'bank', label = 'Fleeca Burton',          x = -351.53,  y = -49.52,   z = 49.04, heading = 340.0 },
  { name = 'bank_hawick',   kind = 'bank', label = 'Fleeca Hawick',          x = 314.22,   y = -278.83,  z = 54.17, heading = 340.0 },
  { name = 'bank_rockford', kind = 'bank', label = 'Fleeca Rockford Hills',  x = -1212.98, y = -330.84,  z = 37.79, heading = 25.0 },
  { name = 'bank_banham',   kind = 'bank', label = 'Fleeca Great Ocean Hwy', x = -2962.58, y = 482.63,   z = 15.70, heading = 88.0 },
  { name = 'bank_harmony',  kind = 'bank', label = 'Fleeca Route 68',        x = 1175.07,  y = 2706.64,  z = 38.09, heading = 180.0 },
  { name = 'bank_paleto',   kind = 'bank', label = 'Blaine County Savings',  x = -112.20,  y = 6469.30,  z = 31.63, heading = 134.0 },
  { name = 'bank_pacific',  kind = 'bank', label = 'Pacific Standard',       x = 241.46,   y = 226.36,   z = 106.29, heading = 160.0 },
  -- Läden: 24/7, LTD, Rob's Liquor (Typ supermarket) und Baumarkt (Typ hardware); Sortiment in config/shops.lua
  { name = 'shop_247_strawberry', kind = 'shop', shop = 'supermarket', label = "24/7 Strawberry", x = 24.47, y = -1346.62, z = 29.5 },
  { name = 'shop_247_chumash', kind = 'shop', shop = 'supermarket', label = "24/7 Chumash", x = -3039.54, y = 584.38, z = 7.91 },
  { name = 'shop_247_banham', kind = 'shop', shop = 'supermarket', label = "24/7 Banham Canyon", x = -3242.97, y = 1000.01, z = 12.83 },
  { name = 'shop_247_paleto', kind = 'shop', shop = 'supermarket', label = "24/7 Paleto Bay", x = 1728.07, y = 6415.63, z = 35.04 },
  { name = 'shop_247_sandy', kind = 'shop', shop = 'supermarket', label = "24/7 Sandy Shores", x = 1959.82, y = 3740.48, z = 32.34 },
  { name = 'shop_247_harmony', kind = 'shop', shop = 'supermarket', label = "24/7 Harmony", x = 549.13, y = 2670.85, z = 42.16 },
  { name = 'shop_247_grapeseed', kind = 'shop', shop = 'supermarket', label = "24/7 Grapeseed", x = 2677.47, y = 3279.76, z = 55.24 },
  { name = 'shop_247_tataviam', kind = 'shop', shop = 'supermarket', label = "24/7 Tataviam", x = 2556.66, y = 380.84, z = 108.62 },
  { name = 'shop_247_vinewood', kind = 'shop', shop = 'supermarket', label = "24/7 Vinewood Hills", x = 372.66, y = 326.98, z = 103.57 },
  { name = 'shop_ltd_davis', kind = 'shop', shop = 'supermarket', label = "LTD Davis", x = -47.02, y = -1758.23, z = 29.42 },
  { name = 'shop_ltd_seoul', kind = 'shop', shop = 'supermarket', label = "LTD Little Seoul", x = -706.06, y = -913.97, z = 19.22 },
  { name = 'shop_ltd_richman', kind = 'shop', shop = 'supermarket', label = "LTD Richman", x = -1820.02, y = 794.03, z = 138.09 },
  { name = 'shop_ltd_mirror', kind = 'shop', shop = 'supermarket', label = "LTD Mirror Park", x = 1164.71, y = -322.94, z = 69.21 },
  { name = 'shop_ltd_grapeseed', kind = 'shop', shop = 'supermarket', label = "LTD Grapeseed", x = 1697.87, y = 4922.96, z = 42.06 },
  { name = 'shop_robs_vespucci', kind = 'shop', shop = 'supermarket', label = "Rob's Liquor Vespucci", x = -1221.58, y = -908.15, z = 12.33 },
  { name = 'shop_robs_morningwood', kind = 'shop', shop = 'supermarket', label = "Rob's Liquor Morningwood", x = -1486.59, y = -377.68, z = 40.16 },
  { name = 'shop_robs_chumash', kind = 'shop', shop = 'supermarket', label = "Rob's Liquor Chumash", x = -2966.39, y = 391.42, z = 15.04 },
  { name = 'shop_robs_route68', kind = 'shop', shop = 'supermarket', label = "Rob's Liquor Route 68", x = 1165.17, y = 2710.88, z = 38.16 },
  { name = 'shop_robs_elburro', kind = 'shop', shop = 'supermarket', label = "Rob's Liquor El Burro", x = 1134.2, y = -982.91, z = 46.42 },
  { name = 'shop_hw_davis', kind = 'shop', shop = 'hardware', label = 'Baumarkt Davis', x = 45.68, y = -1749.04, z = 29.61 },
  { name = 'shop_hw_grapeseed', kind = 'shop', shop = 'hardware', label = 'Baumarkt Grapeseed', x = 2747.71, y = 3472.85, z = 55.67 },
  { name = 'shop_hw_paleto', kind = 'shop', shop = 'hardware', label = 'Baumarkt Paleto', x = -421.83, y = 6136.13, z = 31.88 },
  { name = 'shop_gun_seoul', kind = 'shop', shop = 'gunshop', label = 'Waffenladen Little Seoul', x = -661.96, y = -933.53, z = 21.83 },
  { name = 'shop_gun_cypress', kind = 'shop', shop = 'gunshop', label = 'Waffenladen Cypress Flats', x = 809.68, y = -2159.13, z = 29.62 },
  { name = 'shop_gun_sandy', kind = 'shop', shop = 'gunshop', label = 'Waffenladen Sandy Shores', x = 1692.67, y = 3761.38, z = 34.71 },
  { name = 'shop_gun_paleto', kind = 'shop', shop = 'gunshop', label = 'Waffenladen Paleto Bay', x = -331.23, y = 6085.37, z = 31.45 },
  { name = 'shop_gun_pillbox', kind = 'shop', shop = 'gunshop', label = 'Waffenladen Pillbox Hill', x = 253.63, y = -51.02, z = 69.94 },
  { name = 'shop_gun_pillbox_s', kind = 'shop', shop = 'gunshop', label = 'Waffenladen Pillbox South', x = 23.00, y = -1105.67, z = 29.80 },
  { name = 'shop_gun_tataviam', kind = 'shop', shop = 'gunshop', label = 'Waffenladen Tataviam', x = 2567.48, y = 292.59, z = 108.73 },
  { name = 'shop_gun_chaparral', kind = 'shop', shop = 'gunshop', label = 'Waffenladen Great Chaparral', x = -1118.59, y = 2700.05, z = 18.55 },
}

-- Geldautomaten werden nicht einzeln gelistet: der Client erkennt die Grundspiel-Modelle in Reichweite.
TacoV.Config.AtmModels = { 'prop_atm_01', 'prop_atm_02', 'prop_atm_03', 'prop_fleeca_atm' }

-- Blips je Art: sprite, Farbe, Größe (FiveM-Blip-IDs)
TacoV.Config.Blips = {
  bank = { sprite = 108, color = 2, scale = 0.8, label = 'Bank' },
  -- shop: Blip je Ladentyp aus config/shops.lua
}
