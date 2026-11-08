-- DMV und Fahrschule (Konzept 3.4, Punkte 4.9/4.10). Bis die DMV-Fraktion steht (Phase 9), arbeitet das Amt als NPC-Schalter.
TacoV = TacoV or {}
TacoV.Config = TacoV.Config or {}

TacoV.Config.DMV = {
  registrationFee = 150,   -- Zulassung: Kennzeichen beim DMV
  transferFee = 100,       -- Halterwechsel, zahlt der Käufer; beide müssen am Schalter stehen
  tempPlateFormat = 'TMP %04d', -- Kennzeichen ab Kaufhaus bis zur Zulassung
  pointsRevoke = 8,        -- ab 8 Punkten Entzug (Blitzer, Delikte)

  school = {
    -- je Führerschein: Preis, Wiederholung, Prüfungsfahrzeug, Strecke (Nummer in routes)
    B = { label = 'Führerschein B (PKW)',      price = 500, retry = 100, vehicle = 'blista', route = 'city' },
    A = { label = 'Führerschein A (Motorrad)', price = 350, retry = 100, vehicle = 'pcj',    route = 'city' },
    C = { label = 'Führerschein C (LKW)',      price = 800, retry = 100, vehicle = 'mule',   route = 'truck' },
    theoryQuestions = 8,     -- Fragen je Prüfung (zufällig aus der Liste)
    theoryPass = 7,          -- richtige Antworten zum Bestehen
    speedLimit = 70,         -- km/h innerorts auf der Prüfstrecke
    speedTolerance = 5,      -- km/h Toleranz
    maxDamage = 120,         -- Karosserie-Verlust (von 1000), ab dem die Fahrt als Unfall gilt
    timeLimitSeconds = 480,  -- Zeit für die Strecke
    checkpointRadius = 6.0,
  },

  -- Theorie: Frage, Antworten, Index der richtigen Antwort
  theory = {
    { q = 'Wie schnell darfst du innerorts in Los Santos höchstens fahren?', a = { '50 km/h', '70 km/h', '90 km/h' }, r = 2 },
    { q = 'Was tust du, wenn ein Einsatzfahrzeug mit Blaulicht und Sirene hinter dir auftaucht?',
      a = { 'Beschleunigen, um Platz zu machen', 'Rechts ranfahren und anhalten', 'Weiterfahren wie bisher' }, r = 2 },
    { q = 'Du kommst an eine rote Ampel. Was gilt?', a = { 'Anhalten und warten', 'Rechts abbiegen ist immer erlaubt', 'Bei freier Sicht darfst du fahren' }, r = 1 },
    { q = 'Wer hat an einer Kreuzung ohne Schilder Vorfahrt?', a = { 'Wer schneller ist', 'Rechts vor links', 'Das größere Fahrzeug' }, r = 2 },
    { q = 'Ab wie viel Promille darfst du nicht mehr fahren?', a = { '0,5', '1,0', '1,5' }, r = 1 },
    { q = 'Was bedeutet ein durchgezogener Mittelstreifen?', a = { 'Überholen verboten', 'Parken erlaubt', 'Nur für Busse' }, r = 1 },
    { q = 'Wie verhältst du dich an einem Zebrastreifen mit wartenden Fußgängern?', a = { 'Hupen und weiterfahren', 'Anhalten und Fußgänger gehen lassen', 'Langsam durchfahren' }, r = 2 },
    { q = 'Was ist auf dem Highway verboten?', a = { 'Überholen', 'Wenden und Rückwärtsfahren', 'Fahren mit Licht' }, r = 2 },
    { q = 'Dein Fahrzeug hat kein Kennzeichen. Was droht?', a = { 'Nichts', 'Beschlagnahme durch das LSPD', 'Ein Punkt beim DMV' }, r = 2 },
    { q = 'Wann musst du das Abblendlicht einschalten?', a = { 'Nur im Tunnel', 'Bei Dunkelheit, Regen und Nebel', 'Nur auf dem Highway' }, r = 2 },
    { q = 'Ab wie vielen Punkten beim DMV wird der Führerschein entzogen?', a = { '4', '8', '12' }, r = 2 },
    { q = 'Du hast einen Unfall mit Sachschaden verursacht. Was tust du?',
      a = { 'Wegfahren', 'Anhalten, Unfallstelle sichern, LSPD rufen', 'Nur den Schaden fotografieren' }, r = 2 },
  },

  -- Prüfstrecken: Start (Fahrzeug) und Kontrollpunkte rund um Vespucci / Little Seoul
  routes = {
    city = {
      start = { x = -1162.60, y = -1522.20, z = 4.30, h = 125.0 },
      points = {
        { x = -1182.20, y = -1437.40, z = 4.40 }, { x = -1273.90, y = -1365.10, z = 4.20 }, { x = -1297.60, y = -1221.50, z = 4.60 },
        { x = -1179.50, y = -1148.90, z = 7.80 }, { x = -1034.70, y = -1097.60, z = 2.20 }, { x = -949.60, y = -1205.70, z = 5.20 },
        { x = -1038.90, y = -1327.70, z = 5.00 }, { x = -1110.30, y = -1459.60, z = 4.60 }, { x = -1162.60, y = -1522.20, z = 4.30 },
      },
    },
    truck = {
      start = { x = -1162.60, y = -1522.20, z = 4.30, h = 125.0 },
      points = {
        { x = -1182.20, y = -1437.40, z = 4.40 }, { x = -1273.90, y = -1365.10, z = 4.20 }, { x = -1297.60, y = -1221.50, z = 4.60 },
        { x = -1179.50, y = -1148.90, z = 7.80 }, { x = -1034.70, y = -1097.60, z = 2.20 }, { x = -949.60, y = -1205.70, z = 5.20 },
        { x = -1038.90, y = -1327.70, z = 5.00 }, { x = -1110.30, y = -1459.60, z = 4.60 }, { x = -1162.60, y = -1522.20, z = 4.30 },
      },
    },
  },
}

-- Ort: DMV am Vespucci-Parkplatz (verschiebbar per /ort setzen dmv_vespucci dmv)
local L = TacoV.Config.Locations
L[#L + 1] = { name = 'dmv_vespucci', kind = 'dmv', label = 'DMV Vespucci', x = -1180.60, y = -1512.20, z = 4.40 }
TacoV.Config.Blips.dmv = { sprite = 498, color = 3, scale = 0.7, label = 'DMV / Fahrschule' }
