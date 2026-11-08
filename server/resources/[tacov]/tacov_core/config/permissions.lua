-- Team-Rollen und Rechte (Punkt 0.11, bestätigt 07.11.2026). Die Rolle kommt aus Discord: der Bot spiegelt die
-- Discord-Rolle nach `players.role`. Rechte gelten nur im Admin-Dienst (Aduty, F9 oder /aduty); außerhalb ist ein
-- Teammitglied ein normaler Spieler. Stufen sind aufsteigend; eine Rolle mit `rights` hat genau diese Rechte.
TacoV = TacoV or {}
TacoV.Config = TacoV.Config or {}

TacoV.Config.Roles = {
  player             = { level = 0, label = 'Spieler' },
  guide              = { level = 1, label = 'Guide',
                         rights = { 'support.view', 'support.teleport', 'immigration', 'aduty' } },
  supporter          = { level = 1, label = 'Supporter' },
  moderator          = { level = 2, label = 'Moderator' },
  gamedesigner       = { level = 2, label = 'Gamedesigner',
                         rights = { 'support.view', 'support.teleport', 'support.invisible', 'dev.tools', 'config.view', 'aduty' } },
  entwickler         = { level = 3, label = 'Entwickler', dev = true },
  administrator      = { level = 3, label = 'Administrator' },
  superadmin         = { level = 4, label = 'Superadministrator' },
  manager            = { level = 5, label = 'Manager' },
  stv_projektleitung = { level = 6, label = 'Stv. Projektleitung' },
  projektleitung     = { level = 7, label = 'Projektleitung' },
}

-- Mindeststufe je Recht
TacoV.Config.Rights = {
  -- Stufe 1 · Supporter
  ['aduty']             = 1,  -- Admin-Dienst an/aus
  ['support.view']      = 1,  -- Tickets, Spieler-Akte lesen
  ['support.teleport']  = 1,  -- zu Spielern teleportieren
  ['support.invisible'] = 1,  -- unsichtbar beobachten
  ['immigration']       = 1,  -- Einreise durchführen (Konzept 1)
  ['admin.warn']        = 1,
  -- Stufe 2 · Moderator
  ['admin.kick']        = 2,
  ['admin.ban.temp']    = 2,  -- Sperren bis 7 Tage
  ['admin.vehicle']     = 2,  -- Fahrzeuge löschen/zurücksetzen
  ['admin.refund.small'] = 2, -- Erstattungen bis 10.000 $
  ['admin.noclip']      = 2,
  -- Stufe 3 · Administrator (Entwickler zusätzlich dev.tools)
  ['admin.ban']         = 3,  -- dauerhaft
  ['admin.locations']   = 3,  -- Orte-Creator, /ort setzen
  ['creator']           = 3,  -- Türen, Aufzüge, Portale, Peds, Objekte, Zonen
  ['admin.vehicle.spawn'] = 3,
  ['admin.world']       = 3,  -- Wetter, Zeit, Ansagen
  ['admin.roles']       = 3,  -- Rollen im Spiel setzen (Fallback; Quelle ist Discord), nur bis unter die eigene Stufe
  ['dev.tools']         = 3,
  -- Stufe 4 · Superadministrator
  ['admin.give']        = 4,  -- Items und Geld geben
  ['admin.refund']      = 4,  -- Erstattungen bis 50.000 $
  ['faction.manage']    = 4,  -- Fraktionsleitungen und Ränge
  -- Stufe 5 · Manager
  ['admin.config']      = 5,  -- Config im Spiel ändern
  ['config.view']       = 5,
  ['admin.refund.large'] = 5, -- über 50.000 $, Vier-Augen-Prinzip mit zweitem Manager+
  ['admin.db']          = 5,
  -- Stufe 6 · Stv. Projektleitung, 7 · Projektleitung: alles
}

TacoV.Config.Permissions = {
  banTempMaxHours = 7 * 24,
  refundSmallMax = 10000,
  refundMax = 50000,
}

-- Admin-Dienst-Uniform (Punkt 5.1): wird beim Dienstbeginn angezogen, die eigene Kleidung beim Dienstende zurückgesetzt.
-- Nur für Freemode-Modelle; Werte sind Vanilla-Komponenten (Drawable, Textur), per Config änderbar.
TacoV.Config.AdutyOutfit = {
  mp_m_freemode_01 = {
    components = { [1] = { 135, 2 }, [3] = { 3, 0 }, [4] = { 114, 2 }, [5] = { 0, 0 }, [6] = { 78, 2 }, [7] = { 0, 0 },
                   [8] = { 15, 0 }, [9] = { 0, 0 }, [10] = { 0, 0 }, [11] = { 287, 2 } },
    props = { [0] = false, [1] = false, [2] = false },
  },
  mp_f_freemode_01 = {
    components = { [1] = { 153, 2 }, [3] = { 8, 0 }, [4] = { 121, 2 }, [5] = { 0, 0 }, [6] = { 82, 2 }, [7] = { 0, 0 },
                   [8] = { 15, 0 }, [9] = { 0, 0 }, [10] = { 0, 0 }, [11] = { 300, 2 } },
    props = { [0] = false, [1] = false, [2] = false },
  },
}
