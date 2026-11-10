-- Handy und Funk (Phase 7, Konzept 5.3). Entscheidungen 08.11.2026: 300 $, bei Koma weg, vierstellige Nummer (Wunschnummer
-- nur per Ticket), Funktaste von SaltyChat, Handy nur nutzbar, wenn es in der eigenen Tasche liegt; kein Funkloch.
TacoV = TacoV or {}
TacoV.Config = TacoV.Config or {}

TacoV.Config.Phone = {
  item = 'phone',
  radioItem = 'radio',
  price = 300,
  radioPrice = 250,
  numberMin = 1000, numberMax = 9999,
  groupMax = 8,
  factionChannels = 10,         -- Frequenzen 1–10 sind Fraktionen vorbehalten
  ringSeconds = 20,             -- Klingeln bis „nicht erreicht“
  apps = {                      -- Reihenfolge auf der Startseite; enabled = Modul vorhanden
    { id = 'bank',      label = 'Bank',        icon = 'card',      enabled = true },
    { id = 'vehicles',  label = 'Fahrzeuge',   icon = 'car',       enabled = true },
    { id = 'emergency', label = 'Notruf',      icon = 'warn',      enabled = true },
    { id = 'faction',   label = 'Fraktion',    icon = 'shield',    enabled = false },
    { id = 'business',  label = 'Firma',       icon = 'briefcase', enabled = false },
    { id = 'camera',    label = 'Kamera',      icon = 'search',    enabled = false },
    { id = 'feed',      label = 'Feed',        icon = 'doc',       enabled = false },
    { id = 'radio',     label = 'Funk',        icon = 'radio',     enabled = true },
    { id = 'settings',  label = 'Einstellungen', icon = 'settings', enabled = true },
  },
}
