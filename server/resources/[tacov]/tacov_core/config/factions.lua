-- Fraktionen (Phase 9, Konzept 2.1): gemeinsames System für Staat und Kriminelle. Ränge 1–12, Rechte je Rang (Standard unten,
-- vom Leader änderbar), Kasse (Konto im Journal), Lager, Fahrzeuge, Protokoll. Die einzelnen Fraktionen bekommen ihre Inhalte
-- (Gebäude, Fahrzeuge, Dienstkleidung, Werkzeuge) mit den Punkten 9.4–9.11; hier steht nur die Grundlage.
TacoV = TacoV or {}
TacoV.Config = TacoV.Config or {}

TacoV.Config.Factions = {
  -- Staatsfraktionen (fest); kriminelle Fraktionen legt das Team im Spiel an (Team-Menü → Fraktionen)
  list = {
    lspd       = { label = 'LSPD',      type = 'state', cap = 20, channel = 1, color = 3 },
    lsmd       = { label = 'LSMD',      type = 'state', cap = 0,  channel = 2, color = 1 },   -- 0 = offen
    dmv        = { label = 'DMV',       type = 'state', cap = 10, channel = 3, color = 5 },
    government = { label = 'Regierung', type = 'state', cap = 0,  channel = 4, color = 0, teamOnly = true },
    doj        = { label = 'DOJ',       type = 'state', cap = 15, channel = 5, color = 4 },
  },
  emergencyChannel = 10,                  -- gemeinsamer Notrufkanal LSPD + LSMD
  emergencyFactions = { lspd = true, lsmd = true },
  gang = { cap = 15, hangaroundMax = 2, levelHangaround = 4, levelMember = 9, firstChannel = 6 },
  leaveBlockDays = 5,                     -- Austritt/Entlassung: Sperre für jede andere Fraktion
  crimeToStateDays = 3,                   -- Wechsel kriminell → Staat
  storageKg = 500,                        -- Fraktionslager
  maxRank = 12,
  -- Standardrechte je Rang (Konzept 2.1). Flags: radio_listen, radio_talk, storage_view, storage_take, storage_put,
  -- vehicles_basic, vehicles_all, invite, treasury_view, treasury_withdraw, ranks_manage, kick, settings, leader
  defaultRights = {
    [1]  = { 'radio_listen', 'storage_view' },
    [2]  = { 'radio_listen', 'storage_view' },
    [3]  = { 'radio_listen', 'radio_talk', 'storage_view', 'storage_take', 'vehicles_basic' },
    [4]  = { 'radio_listen', 'radio_talk', 'storage_view', 'storage_take', 'vehicles_basic' },
    [5]  = { 'radio_listen', 'radio_talk', 'storage_view', 'storage_take', 'vehicles_basic' },
    [6]  = { 'radio_listen', 'radio_talk', 'storage_view', 'storage_take', 'storage_put', 'vehicles_basic', 'vehicles_all', 'invite' },
    [7]  = { 'radio_listen', 'radio_talk', 'storage_view', 'storage_take', 'storage_put', 'vehicles_basic', 'vehicles_all', 'invite' },
    [8]  = { 'radio_listen', 'radio_talk', 'storage_view', 'storage_take', 'storage_put', 'vehicles_basic', 'vehicles_all', 'invite' },
    [9]  = { 'radio_listen', 'radio_talk', 'storage_view', 'storage_take', 'storage_put', 'vehicles_basic', 'vehicles_all', 'invite',
             'treasury_view', 'treasury_withdraw', 'ranks_manage', 'kick' },
    [10] = { 'radio_listen', 'radio_talk', 'storage_view', 'storage_take', 'storage_put', 'vehicles_basic', 'vehicles_all', 'invite',
             'treasury_view', 'treasury_withdraw', 'ranks_manage', 'kick' },
    [11] = { 'radio_listen', 'radio_talk', 'storage_view', 'storage_take', 'storage_put', 'vehicles_basic', 'vehicles_all', 'invite',
             'treasury_view', 'treasury_withdraw', 'ranks_manage', 'kick', 'settings' },
    [12] = { 'radio_listen', 'radio_talk', 'storage_view', 'storage_take', 'storage_put', 'vehicles_basic', 'vehicles_all', 'invite',
             'treasury_view', 'treasury_withdraw', 'ranks_manage', 'kick', 'settings', 'leader' },
  },
  rightLabels = {
    radio_listen = 'Funk hören', radio_talk = 'Funk sprechen', storage_view = 'Lager sehen', storage_take = 'Lager entnehmen',
    storage_put = 'Lager einlagern', vehicles_basic = 'Fahrzeuge Klasse 1', vehicles_all = 'Alle Fahrzeuge', invite = 'Einladen',
    treasury_view = 'Kasse und Journal sehen', treasury_withdraw = 'Kasse auszahlen', ranks_manage = 'Ränge 1–8 vergeben',
    kick = 'Entlassen', settings = 'Rangnamen und Rechte ändern', leader = 'Leader (übergeben, Rang 9–11)',
  },
  -- Tageslimits (Konzept: Entnahme und Auszahlung mit Limit; Rang 11/12 ohne Limit)
  dailyStorageKg = { [3] = 10, [4] = 15, [5] = 20, [6] = 40, [7] = 40, [8] = 40, [9] = 80, [10] = 80 },
  dailyTreasury = { [9] = 5000, [10] = 5000 },
  rankManageMax = 8,                      -- ranks_manage darf bis Rang 8 vergeben
}

-- Orte je Fraktion werden mit dem Orte-Creator gesetzt; Art + Fraktion über den Namen: faction_duty_lspd, faction_storage_lspd,
-- faction_garage_lspd, faction_wardrobe_lspd (die Fraktion ist der Teil nach dem letzten Unterstrich).
TacoV.Config.Blips.faction_duty     = { sprite = 60,  color = 3, scale = 0.7, label = 'Stempeluhr' }
TacoV.Config.Blips.faction_storage  = { sprite = 1, color = 0, scale = 0.0, label = 'Fraktionslager', hidden = true }
TacoV.Config.Blips.faction_garage   = { sprite = 1, color = 0, scale = 0.0, label = 'Fraktionsgarage', hidden = true }
TacoV.Config.Blips.faction_wardrobe = { sprite = 1, color = 0, scale = 0.0, label = 'Umkleide', hidden = true }
