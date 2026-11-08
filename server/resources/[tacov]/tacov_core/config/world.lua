-- Objekt-Placer (5.8) und Zonen (5.9): Vorauswahl an Requisiten und Zonenarten.
TacoV = TacoV or {}
TacoV.Config = TacoV.Config or {}

TacoV.Config.PropModels = {
  { model = 'prop_barrier_work05',   label = 'Absperrung (Polizei)' },
  { model = 'prop_mp_barrier_01',    label = 'Absperrung (Rennen)' },
  { model = 'prop_barrier_work06a',  label = 'Bauzaun' },
  { model = 'prop_roadcone02a',      label = 'Pylone' },
  { model = 'prop_barier_conc_01a',  label = 'Betonbarriere' },
  { model = 'prop_sign_road_01a',    label = 'Schild Baustelle' },
  { model = 'prop_worklight_03b',    label = 'Baustrahler' },
  { model = 'prop_container_01a',    label = 'Container' },
  { model = 'prop_dumpster_01a',     label = 'Müllcontainer' },
  { model = 'prop_boxpile_07d',      label = 'Kisten' },
  { model = 'prop_table_03',         label = 'Tisch' },
  { model = 'prop_chair_01a',        label = 'Stuhl' },
  { model = 'prop_bench_01a',        label = 'Bank' },
  { model = 'prop_gazebo_01',        label = 'Pavillon' },
  { model = 'prop_atm_01',           label = 'Geldautomat' },
  { model = 'prop_vend_soda_01',     label = 'Getränkeautomat' },
  { model = 'prop_fncwood_16a',      label = 'Holzzaun' },
  { model = 'prop_generator_03b',    label = 'Generator' },
}

TacoV.Config.ZoneKinds = {
  { id = 'safezone', label = 'Sicherheitszone', color = { 80, 200, 120 } },
  { id = 'job',      label = 'Job-Bereich',      color = { 90, 150, 250 } },
  { id = 'area',     label = 'Gebiet',           color = { 167, 139, 250 } },
  { id = 'nocars',   label = 'Fahrzeugverbot',   color = { 250, 160, 60 } },
  { id = 'custom',   label = 'Sonstiges',        color = { 200, 200, 200 } },
}

-- Welt (5.12): Uhrzeit und Wetter kommen vom Server, damit alle dasselbe sehen.
TacoV.Config.World = {
  dayMinutes = 120,          -- reale Minuten je Spieltag (24 h)
  startHour = 9,             -- Uhrzeit beim Serverstart
  weatherMinutes = 25,       -- Wetterwechsel alle x Minuten (wenn nicht eingefroren)
  snowWeathers = { XMAS = true, SNOW = true, SNOWLIGHT = true, BLIZZARD = true }, -- mit Schneedecke, Spuren und Schnee-Effekten
  weathers = { 'CLEAR', 'EXTRASUNNY', 'CLOUDS', 'OVERCAST', 'CLEARING', 'SMOG', 'FOGGY', 'RAIN', 'THUNDER' },
  weights  = {  5,       4,            3,        2,          2,          1,      1,       1,      1 },
  labels = {
    CLEAR = 'Klar', EXTRASUNNY = 'Sonnig', CLOUDS = 'Wolkig', OVERCAST = 'Bedeckt', CLEARING = 'Aufklarend', SMOG = 'Dunst',
    FOGGY = 'Nebel', RAIN = 'Regen', THUNDER = 'Gewitter', SNOW = 'Schnee', SNOWLIGHT = 'Leichter Schnee', XMAS = 'Schnee (Weihnachten, liegt)',
    BLIZZARD = 'Schneesturm', HALLOWEEN = 'Halloween',
  },
}
