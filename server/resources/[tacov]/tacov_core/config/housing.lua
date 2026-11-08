-- Sozialwohnung (Grundlage Immobilien) und Neulingspfad (Punkt 6.5, Konzept 1.4 / 3)
TacoV = TacoV or {}
TacoV.Config = TacoV.Config or {}

TacoV.Config.Housing = {
  social = {
    label = 'Sozialwohnung',
    rentWeekly = 300,            -- nach der freien Zeit, wöchentlich vom Konto
    freeDays = 14,
    storageKg = 20,
    -- Eingang (Haustür) und Innenraum (Grundspiel-Interior „Low End Apartment“); jeder Mieter hat seine eigene Instanz
    entry = vector4(-1150.9, -1521.2, 10.6, 35.0),   -- Vespucci, Mehrfamilienhaus
    inside = vector4(265.9, -1007.4, -101.0, 180.0),
    exit = vector3(266.1, -1007.5, -101.0),
    storage = vector3(265.0, -1003.0, -101.0),
    wardrobe = vector3(259.9, -1004.5, -99.0),
  },
}

TacoV.Config.Newbie = {
  hideFromLevel = 4,
  steps = {
    { id = 'home',     label = 'Deine Sozialwohnung betreten',           bonus = 150 },
    { id = 'license',  label = 'Führerschein beim DMV machen',           bonus = 300 },
    { id = 'job',      label = 'Ersten Job annehmen',                    bonus = 250 },
    { id = 'dealer',   label = 'Ein Fahrzeug im Kaufhaus ansehen',       bonus = 100 },
    { id = 'bank',     label = 'Bankkonto nutzen',                       bonus = 100 },
    { id = 'emergency', label = 'Den Notruf kennenlernen (Handy)',       bonus = 100 },
    { id = 'clothes',  label = 'Kleidung kaufen',                        bonus = 150 },
    { id = 'eat',      label = 'Etwas essen oder trinken',               bonus = 50 },
    { id = 'faction',  label = 'Eine Fraktion besuchen',                 bonus = 150 },
    { id = 'level3',   label = 'Level 3 erreichen',                      bonus = 500 },
  },
}

local L = TacoV.Config.Locations
L[#L + 1] = { name = 'social_housing', kind = 'housing', label = 'Sozialwohnung', x = -1150.9, y = -1521.2, z = 10.6, heading = 35.0 }
TacoV.Config.Blips.housing = { sprite = 475, color = 3, scale = 0.7, label = 'Sozialwohnung' }
