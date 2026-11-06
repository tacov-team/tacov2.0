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
}

-- Geldautomaten werden nicht einzeln gelistet: der Client erkennt die Grundspiel-Modelle in Reichweite.
TacoV.Config.AtmModels = { 'prop_atm_01', 'prop_atm_02', 'prop_atm_03', 'prop_fleeca_atm' }

-- Blips je Art: sprite, Farbe, Größe (FiveM-Blip-IDs)
TacoV.Config.Blips = {
  bank = { sprite = 108, color = 2, scale = 0.8, label = 'Bank' },
}
