-- NPC-Creator (Punkt 5.7): Auswahl an Modellen, Szenarien und Aufgaben. Eigene Modelle sind per Texteingabe möglich.
TacoV = TacoV or {}
TacoV.Config = TacoV.Config or {}

TacoV.Config.PedModels = {
  { model = 'mp_m_shopkeep_01',  label = 'Verkäufer (Laden)' },
  { model = 's_f_y_shop_low',    label = 'Verkäuferin' },
  { model = 's_m_m_autoshop_01', label = 'Mechaniker' },
  { model = 's_m_y_xmech_01',    label = 'Mechaniker (Overall)' },
  { model = 'ig_bankman',        label = 'Bankangestellter' },
  { model = 'a_m_m_business_01', label = 'Geschäftsmann' },
  { model = 'a_f_y_business_01', label = 'Geschäftsfrau' },
  { model = 's_m_m_security_01', label = 'Sicherheitsdienst' },
  { model = 's_m_y_cop_01',      label = 'Polizist' },
  { model = 's_f_y_cop_01',      label = 'Polizistin' },
  { model = 's_m_m_doctor_01',   label = 'Arzt' },
  { model = 's_m_m_paramedic_01', label = 'Sanitäter' },
  { model = 's_m_m_trucker_01',  label = 'Trucker' },
  { model = 's_m_m_postal_01',   label = 'Postbote' },
  { model = 's_m_y_dealer_01',   label = 'Dealer' },
  { model = 'a_m_y_hipster_01',  label = 'Hipster' },
  { model = 'a_m_m_farmer_01',   label = 'Farmer' },
  { model = 's_m_m_dockwork_01', label = 'Hafenarbeiter' },
  { model = 'csb_bogdan',        label = 'Anzugträger' },
  { model = 'u_f_y_princess',    label = 'Dame' },
}

TacoV.Config.PedScenarios = {
  { id = '',                            label = 'Keine (steht still)' },
  { id = 'WORLD_HUMAN_CLIPBOARD',       label = 'Klemmbrett' },
  { id = 'WORLD_HUMAN_STAND_MOBILE',    label = 'Handy' },
  { id = 'WORLD_HUMAN_SMOKING',         label = 'Rauchen' },
  { id = 'WORLD_HUMAN_GUARD_STAND',     label = 'Wache' },
  { id = 'WORLD_HUMAN_LEANING',         label = 'Anlehnen' },
  { id = 'WORLD_HUMAN_AA_COFFEE',       label = 'Kaffee' },
  { id = 'WORLD_HUMAN_DRINKING',        label = 'Trinken' },
  { id = 'WORLD_HUMAN_HANG_OUT_STREET', label = 'Herumstehen' },
  { id = 'WORLD_HUMAN_STAND_IMPATIENT', label = 'Ungeduldig' },
  { id = 'WORLD_HUMAN_COP_IDLES',       label = 'Polizist (Idle)' },
  { id = 'WORLD_HUMAN_WELDING',         label = 'Schweißen' },
  { id = 'WORLD_HUMAN_HAMMERING',       label = 'Hämmern' },
  { id = 'WORLD_HUMAN_JANITOR',         label = 'Hausmeister' },
  { id = 'WORLD_HUMAN_MUSCLE_FLEX',     label = 'Posen' },
}

-- Aufgabe = Aufforderung, die der NPC statt des E-Punkts auslöst (der NPC muss am passenden Ort stehen)
TacoV.Config.PedTasks = {
  { id = '',         label = 'Keine (nur Deko)' },
  { id = 'shop',     label = 'Laden' },
  { id = 'bank',     label = 'Bank' },
  { id = 'dealer',   label = 'Kaufhaus' },
  { id = 'dmv',      label = 'DMV / Fahrschule' },
  { id = 'garage',   label = 'Garage / Verwahrhof' },
  { id = 'workshop', label = 'Werkstatt' },
  { id = 'fuel',     label = 'Tankstelle' },
}
